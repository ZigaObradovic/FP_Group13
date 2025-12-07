import random
from funkcije2 import subpath_number

def random_cubic_neighbor(G, max_tries=500):
    """
    Iz povezanega kubičnega grafa G naredi sosednji POVEZAN kubični graf
    z eno 2-edge zamenjavo (double-edge swap).

    Če v max_tries poskusih ne najde primernega switcha,
    vrne kopijo G (brez spremembe).
    """

    # Preverimo veljavnost vhodnega grafa
    assert G.is_regular(3), "Graf ni kubičen (3-regularen)."
    assert G.is_connected(), "Graf ni povezan."

    # Ustvarimo seznam robov
    H = G.copy()
    edges = H.edges(labels=False)
    m = len(edges)
    if m < 2:
        return H

    for _ in range(max_tries):

        # #zberemo dva različna roba
        i = random.randrange(m)
        j = random.randrange(m)
        if i == j:
            continue
        (u, v) = edges[i]
        (x, y) = edges[j]

        # potrebujemo 4 različna vozlišča (disjunktna roba)
        if len({u, v, x, y}) < 4:
            continue

        # izberemo eno od dveh možnih zamenjav
        if random.random() < 0.5:
            a, b = u, x
            c, d = v, y
        else:
            a, b = u, y
            c, d = v, x

        # brez zank
        if a == b or c == d:
            continue

        # brez paralelnih robov
        if H.has_edge(a, b) or H.has_edge(c, d):
            continue

        # izvedemo zamenjavo
        H.delete_edge(u, v)
        H.delete_edge(x, y)
        H.add_edge(a, b)
        H.add_edge(c, d)

        # preverimo poveznost
        if H.is_connected() and H.is_regular(3):
            # Vse je ok, vrnemo nov graf
            return H
        else:
            # razveljavi in poskusi z drugim switchom
            H.delete_edge(a, b)
            H.delete_edge(c, d)
            H.add_edge(u, v)
            H.add_edge(x, y)

    # če ne uspe, vrnemo kopijo brez spremembe
    return H


import math

def estimate_positive_dE(Ln, neighbor_fun, samples=1000, max_tries=500):
    """
    Oceni povprečno pozitivno dE = subpath_number(G_new) - subpath_number(G)
    preko kratkega naključnega sprehoda po prostoru sosedov.

    Če ne najde nobene pozitivne dE, vrne 0.0.
    """
    G = Ln.copy()
    E = subpath_number(G)

    dEs = []
    for _ in range(int(samples)):
        G_new = neighbor_fun(G, max_tries)
        E_new = subpath_number(G_new)
        dE = E_new - E
        if dE > 0:
            dEs.append(float(dE))

        # premaknemo se naprej (da ne merimo vedno okoli istega grafa)
        G = G_new
        E = E_new

    if dEs:
        return sum(dEs) / len(dEs)
    else:
        return 0.0


def simulated_annealing_subpath(
    Ln,
    steps=20000,
    T0=1000,        # uporabi se samo, če auto-kalibracija ne uspe
    alpha=0.9995,    # isto
    neighbor_fun=random_cubic_neighbor,
    max_tries=1000,
    T_end_target = 50.0,
    verbose=False
):
    """
    Simulated annealing za minimizacijo subpath_number(G) na prostoru
    povezanih kubičnih grafov.

    Sprejemna verjetnost:
        p = exp(-dE / T)  (Metropolis)
    z numerično stabilno zaščito pred overflowom.

    Parametri:
        Ln         - začetni graf (povezan, 3-regularen)
        steps      - število korakov
        T0, alpha  - uporabljena le, če auto-kalibracija ne uspe (mean_dE <= 0)
        neighbor_fun - funkcija za generiranje soseda
        max_tries  - največ poskusov za iskanje veljavnega soseda
        verbose    - diagnostični izpis

    Vrne:
        best_G, best_E, history
    """

    assert Ln.is_regular(3)
    assert Ln.is_connected()

    # Pretvorba SageMath tipov → Python
    steps     = int(steps)
    max_tries = int(max_tries)

    # 1) Ocena povprečne pozitivne dE
    # vzorčimo največ 'steps' ali 1000, kar je manj
    sample_count = min(200, steps)
    mean_dE = estimate_positive_dE(Ln, neighbor_fun, samples=sample_count, max_tries=max_tries)

    # 2) Samodejna nastavitev T0 in alpha iz mean_dE in steps
    #    Cilj: p0 ~ 0.4 na začetku, pend ~ 1e-4 na koncu
    if mean_dE > 0:
        p0   = 0.5     # želena začetna verjetnost sprejema tipične pozitivne dE
        pend = 1e-7    # želena končna verjetnost sprejema tipične pozitivne dE

        T0_auto   = -mean_dE / math.log(p0)

        T_end_target = 50.0      # točno 100
        alpha_auto = (T_end_target / T0_auto)**(1.0 / steps)

        T     = float(T0_auto)
        alpha = float(alpha_auto)

        if verbose:
            print(f"[AUTO] mean_dE={mean_dE:.2f}, T0={T0_auto:.2f}, T_end={T_end_target:.2f}, alpha={alpha_auto:.6f}")
    else:
        # fallback: uporabimo ročno podana T0 in alpha
        T     = float(T0)
        alpha = float(alpha)
        if verbose:
            print(f"[AUTO] mean_dE<=0, uporabljam podane parametre T0={T0}, alpha={alpha}")

    # 3) Začetno stanje
    G = Ln.copy()
    E = subpath_number(G)

    best_G = G.copy()
    best_E = E

    history = [E]

    worse_total = 0
    worse_accepted = 0

    for step in range(1, steps+1):

        # generiraj sosednji kubični graf
        G_new = neighbor_fun(G, max_tries)
        E_new = subpath_number(G_new)
        dE = E_new - E

        if dE <= 0:
            # izboljšava → vedno sprejmi
            accept = True
        else:
            worse_total += 1

            # Metropolis sprejemna verjetnost p = exp(-dE/T)
            x = dE / T

            # numerična zaščita pred overflowom
            if x >= 700:       # exp(-700) ≈ 5e-305 (meja double)
                p = 0.0
            else:
                p = math.exp(-x)

            accept = (random.random() < p)
                

        if accept:
            G = G_new
            E = E_new
            worse_accepted += 1

            if E < best_E:
                best_E = E
                best_G = G.copy()

        # ohlajanje
        T *= alpha
        history.append(E)

        # diagnostični izpis (10× v teku)
        if verbose and step % max(1, steps // 10) == 0:
            ratio = 100.0 * worse_accepted / worse_total if worse_total else 0.0
            print(
                f"Korak {int(step)}, "
                f"T={float(T):.4f}, "
                f"E={int(E)}, best_E={int(best_E)}, "
                f"sprejetih slabših = {int(worse_accepted)}/{int(worse_total)} "
                f"({ratio:.2f} %)"
            )
            # reset lokalne statistike za naslednji interval
            worse_total = 0
            worse_accepted = 0

    return best_G, best_E, history