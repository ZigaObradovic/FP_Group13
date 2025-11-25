def left_gadget():
    """Konstruira levi gradnik"""

    G = graphs.CompleteGraph(4)  # K4
    G.delete_edge(0, 1)          # K4 - e; 0 in 1 sta zdaj stopnje 2

    t = 4
    G.add_vertex(t) # Dodamo zgornje vozlišče
    G.add_edge(t, 0)
    G.add_edge(t, 1) # Povežemo zgornje vozlišče

    return G, t # Vrnemo graf in vozlišče na katerega bomo vezali naprej

def middle_gadget():
    """konstruira srednji gradnik"""

    G = graphs.CompleteGraph(4) # K4
    G.delete_edge(0, 1)  # zdaj sta 0 in 1 stopnje 2

    L, R = 0, 1 # Vozlišči na kateri bomo naprej vezali

    return G, L, R

def right_gadget():
    """Konstruira desni gradnik"""

    G = graphs.CompleteGraph(4)  # K4
    G.delete_edge(0, 1)          # K4 - e; 0 in 1 sta zdaj stopnje 2

    # Dodamo povezani vozlišči
    x = 4
    y = 5
    G.add_vertices([x, y])
    G.add_edge(x, y)

    # Povežemo vozlišča
    G.add_edge(0, x)
    G.add_edge(1, y)

    t = 6
    G.add_vertex(t) # Dodamo zgornje vozlišče
    G.add_edge(t, x)
    G.add_edge(t, y) # Povežemo zgornje vozlišče

    return G, t # Vrnemo graf in vozlišče na katerega bomo vezali naprej


def add_gadget(G, t1, H, t2, t3 = ""):
    """Podanemu grafu G doda graf H z zamaknjenim številčenjem vozlišč za k"""

    k = G.num_verts()
    mapping = {v: v + k for v in H.vertices()} # Slovar: staro številčenje -> novo številčenje
    H2 = H.relabel(mapping, inplace=False) # Graf H z zamaknjenim številčenjem

    # Graf H2 dodamo zraven grafa G in jih ne povežemo
    G.add_vertices(H2.vertices())
    G.add_edges(H2.edges(labels=False))

    # Povežemo in označimo zadnje vozlišče
    # Odvisno je od tega ali dodajamo srednje gradnike, ali leve oz. desne
    if t3 != "":
        G.add_edge(t1, mapping[t2])
        t = mapping[t3]

        return G, t
    else:
        G.add_edge(t1, mapping[t2])

        return G
   

def Ln_graph(n):
    """Naredi Ln graf z n vozlišči."""

    # Varovalka za sode n > 10
    if n % 2 != 0 or n < 10:
        raise ValueError("Za L_n mora biti n sodo in n >= 10.")

    desni_konec = (n % 4 == 0) # Ali končamo z desnim grednikom
    m = (n - 12) // 4 if desni_konec else (n - 10) // 4 # Število srednjih gradnikov

    # Začnemo z levim gradnikom
    G, t = left_gadget()

    # Dodamo m srednjih gradnikov
    if m > 0:
        M, x, y = middle_gadget()
        for _ in range(m):
            G, t = add_gadget(G, t, M, x, y)

    # Zaključimo z levim oz. desnim gradnikom
    if desni_konec:
        D, x = right_gadget()
        G = add_gadget(G, t, D, x)
    else:
        L, x = left_gadget()
        G = add_gadget(G, t, L, x)
    
    return G

def build_star(n):
    """Naredi boljši graf kot Ln"""

    # Varovalka za sode n > 10
    if n % 2 != 0 or n < 10:
        raise ValueError("Za L_n mora biti n sodo in n >= 10.")

    # določanje začetnih in končnih gradnikov
    mod = n % 6
    m = (n - 10) // 6 # Število vmesnih gradnikov
    if mod == 0:
        levi_zacetek, levi_konec = True, False
    elif mod == 2:
        levi_zacetek, levi_konec = False, False
    elif mod == 4:
        levi_zacetek, levi_konec = True, True

    # Začnemo s prvim gradnikom
    if levi_zacetek:
        G, t = left_gadget()
    else: 
        G, t = right_gadget()

    # Dodamo m vmesnih (levih) gradnikov
    if m > 0:
        H, y = left_gadget()
        for _ in range(m):
            x = G.num_verts()
            G.add_vertex(x) # Dodamo vozlišče za povezavo
            G.add_edge(t, x) # povežemo ga z osnovo
            G = add_gadget(G, x, H, y)
            t = x

    # Zadnji gradnik
    if levi_konec:
        H, y = left_gadget()
        G = add_gadget(G, t, H, y)
    else: 
        H, y = right_gadget()
        G = add_gadget(G, t, H, y)

    return G

from sage.all import graphs

def cubic_graphs(n):
    """Vrne generator vseh (neizomorfnih) 3-regularnih povezanih grafov na n vozliščih."""

    # varovalka za sodi n >= 4
    if n % 2 or n < 4:
        raise ValueError("n mora biti sodo in ≥ 4.")

    # povemo, da želimo grafe z n vozlišči in stopnjo vozlišč točno 3 (najmanjša in največja stopnja je 3)
    flags = f"-d3 -D3 -c {n}"

    # vrnemo generator vseh takih grafov
    return graphs.nauty_geng(flags) 





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





