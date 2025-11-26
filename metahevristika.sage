import random

def subpath_number(G):
    # ============================================================
    # Funkcija subpath_number(G)
    # ------------------------------------------------------------
    # Namen:
    #   Izračuna število vseh poti v danem grafu G (vključno s
    #   trivialnimi potmi dolžine 0).
    #
    # Definicija poti:
    #   Pot je zaporedje vozlišč (v_0, v_1, ..., v_k) brez ponavljanj,
    #   kjer sta vsaki zaporedni vozlišči povezni z robom grafa.
    #   Graf je neorientiran, zato se obrnjene poti štejejo ločeno.
    #
    # Postopek:
    #   1. Graf pretvorimo v numerično obliko (vozlišča 0..n-1).
    #   2. Zgradimo seznam sosedov (adjacency list).
    #   3. Iz vsakega vozlišča sprožimo rekurzivni DFS, ki šteje vse
    #      možne poti brez ponavljanja vozlišč.
    #   4. Uporabimo bitmasko (int) za označevanje že obiskanih vozlišč,
    #      da je algoritem hiter in porabi malo pomnilnika.
    #   5. Števec `total` poveča vsakič, ko najde veljavno pot
    #      (tudi trivialno z enim samim vozliščem).
    #
    # Časovna zahtevnost:
    #   Eksponentna v številu vozlišč, ker štejemo vse poti.
    #   Uporabno za grafe velikosti do približno n ≤ 22.
    #
    # Rezultat:
    #   Vrne celo število (int) — število vseh poti v G.
    # ============================================================

    # Pretvori vozlišča v indekse 0..n-1 za učinkovitejši dostop
    verts = list(G.vertices())
    idx = {v: i for i, v in enumerate(verts)}

    # Zgradi seznam sosedov (adjacency list)
    adj = [[] for _ in verts]
    for v in verts:
        i = idx[v]
        for w in G.neighbors(v):
            adj[i].append(idx[w])

    n = len(verts)
    total = 0  # števec vseh poti

    # Rekurzivna funkcija za globinsko iskanje (DFS)
    def dfs(u, mask):
        # Povečamo števec ob vsakem obisku — vsaka kombinacija
        # obiskanih vozlišč predstavlja eno pot
        nonlocal total
        total += 1

        # Premaknemo se na vsakega soseda, ki še ni bil obiskan
        for w in adj[u]:
            bit = 1 << w
            if not (mask & bit):  # če w še ni bil obiskan
                dfs(w, mask | bit)

    # Za vsako vozlišče zaženemo DFS kot začetno točko
    for i in range(n):
        dfs(i, 1 << i)

    # Vrni skupno število poti
    return total

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

def simulated_annealing_subpath(Graf, steps=10000, T0=1.0, alpha=0.9999, verbose=False):
    """
    Simulated annealing za minimizacijo subpath_number(G) po
    POVEZANIH kubičnih grafih z isto množico vozlišč kot Ln.

    Graf      : začetni POVEZAN kubični graf
    steps   : število korakov
    T0      : začetna temperatura
    alpha   : faktor ohlajanja (T <- alpha * T)
    verbose : če True, občasno izpisuje napredek

    Vrne:
      best_G  : najboljši najdeni graf
      best_E  : subpath_number(best_G)
      history : seznam energij skozi korake
    """
    assert Graf.is_regular(3), "Začetni graf ni kubičen."
    assert Graf.is_connected(), "Začetni graf ni povezan."

    # začetno stanje
    G = Graf.copy()
    E = subpath_number(G)

    best_G = G.copy()
    best_E = E

    T = T0
    history = [E]

    for step in range(steps):
        # generiramo povezan kubični sosed
        G_new = random_cubic_neighbor(G)
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
            G.show()

    return best_G, best_E, history
