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

def simulated_annealing_subpath(
    Ln,
    steps=10000,
    T0=1.0,
    alpha=0.999,
    neighbor_fun=random_cubic_neighbor,
    max_tries = 500,
    verbose=False):
    """
    Simulated annealing za minimizacijo subpath_number(G) po
    POVEZANIH kubičnih grafih z isto množico vozlišč kot Ln.

    Parametri:
      Ln         : začetni povezan kubični graf
      steps      : število korakov algoritma
      T0         : začetna temperatura
      alpha      : faktor ohlajanja (T <- alpha * T)
      neighbor_fun : funkcija za generiranje soseda (privzeto random_cubic_neighbor)
      verbose    : če True, občasno izpisuje napredek

    Vrne:
      best_G  : najboljši najdeni graf
      best_E  : subpath_number(best_G)
      history : seznam energij (subpath_number) skozi korake
    """
    assert Ln.is_regular(3), "Začetni graf Ln ni kubičen."
    assert Ln.is_connected(), "Začetni graf Ln ni povezan."

    # začetno stanje
    G = Ln.copy()
    E = subpath_number(G)

    best_G = G.copy()
    best_E = E

    T = T0
    history = [E]

    for step in range(steps):
        # generiramo povezan kubični sosed
        G_new = neighbor_fun(G, max_tries)
        E_new = subpath_number(G_new)
        dE = E_new - E

        # odločitev o sprejemu
        if dE <= 0:
            accept = True
        else:
            accept = random.random() < math.exp(-dE / T)

        if accept:
            G = G_new
            E = E_new

            if E < best_E:
                best_E = E
                best_G = G.copy()

        # ohlajanje
        T *= alpha
        history.append(E)

        if verbose and step % max(1, steps // 10) == 0:
            print(f"Korak {step}, T={T:.4f}, E={E}, best_E={best_E}")

    return best_G, best_E, history
