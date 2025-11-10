def _gadget_left():
    """
    LEVI gradnik (5 vozlišč).
    Konstrukcija: vzamemo K4 - e in dodamo novo vozlišče t, ki ga povežemo
    z obema vozliščema stopnje 2. V tem gradniku je t edini terminal (stopnje 2),
    namenjen za povezavo naprej v verigo.
    """
    H = graphs.CompleteGraph(4)  # K4
    H.delete_edge(0, 1)          # K4 - e; 0 in 1 sta zdaj stopnje 2
    G = H.copy()
    t = 4
    G.add_vertex(t)
    G.add_edge(t, 0)
    G.add_edge(t, 1)
    return G, t

def _gadget_middle():
    """
    SREDNJI gradnik (4 vozlišča) = K4 - e, z dvema terminaloma stopnje 2.
    """
    G = graphs.CompleteGraph(4)
    G.delete_edge(0, 1)  # zdaj sta 0 in 1 stopnje 2
    L, R = 0, 1
    return G, L, R


def _gadget_right():
    """
    DESNI gradnik (7 vozlišč)
    """
    # 1) diamant K4 - e
    D = graphs.CompleteGraph(4)

    # 2) odstrani 'zgornji' rob med vozliščema stopnje 3
    D.delete_edge(2, 3)

    # 3) dodaj x in y, ki sta med seboj povezana
    x = 4
    y = 5
    D.add_vertices([x, y])
    D.add_edge(x, y)

    # 4) povezavi iz 'zgornjih' vrhov diamanta na x in y
    D.add_edge(2, x)
    D.add_edge(3, y)

    # 5) dodaj terminal t stopnje 2, ki se povezuje na x in y
    t = 6
    D.add_vertex(t)
    D.add_edge(x, t)
    D.add_edge(y, t)

    return D, t



def _add_with_offset(dst, H, offset):
    """
    Kopira graf H v dst z zamikom oznak 'offset'. Vrne 'mapping' star->nov.
    """
    mapping = {v: v + offset for v in H.vertices()}
    H2 = H.relabel(mapping, inplace=False)
    dst.add_vertices(H2.vertices())
    dst.add_edges(H2.edges(labels=False))
    return mapping


# ====== SESTAVLJANJE L_n ====================================================

def Ln_graph(n):
    """
    Sestavi L_n iz 3 gradnikov po pravilu:
      - začni z LEVIM gradnikom,
      - dodaj m SREDNJIH gradnikov,
      - končaj z DESNIM, če je n = 4k; ali spet z LEVIM, če je n = 4k - 2.

    Velja:
      n = 5 + 4m + 7  (če n ≡ 0 mod 4)  ->  m = (n-12)/4
      n = 5 + 4m + 5  (če n ≡ 2 mod 4)  ->  m = (n-10)/4

    Pogoji: n sodo, n ≥ 10.
    Vrne: kubičen povezan graf z n vozlišči.
    """
    if n % 2 != 0 or n < 10:
        raise ValueError("Za L_n mora biti n sodo in n >= 10.")

    end_is_right = (n % 4 == 0)
    m = (n - 12) // 4 if end_is_right else (n - 10) // 4

    G = Graph(multiedges=False, loops=False)
    next_id = 0

    # 1) dodaj LEVI gradnik
    Lg, tL = _gadget_left()
    mapL = _add_with_offset(G, Lg, next_id)
    prev = mapL[tL]            # 'desni' terminal levega gradnika
    next_id += Lg.num_verts()

    # 2) dodaj m SREDNJIH gradnikov v verigo
    for _ in range(m):
        Mg, Lterm, Rterm = _gadget_middle()
        mapM = _add_with_offset(G, Mg, next_id)
        # poveži prejšnji terminal na 'levi' terminal novega srednjega gradnika
        G.add_edge(prev, mapM[Lterm])
        prev = mapM[Rterm]     # novi 'desni' terminal verige
        next_id += Mg.num_verts()

    # 3) zaključi z DESNIM ali LEVIM gradnikom
    if end_is_right:
        Rg, tR = _gadget_right()
        mapR = _add_with_offset(G, Rg, next_id)
        G.add_edge(prev, mapR[tR])
        next_id += Rg.num_verts()
    else:
        Lg2, tL2 = _gadget_left()
        mapL2 = _add_with_offset(G, Lg2, next_id)
        G.add_edge(prev, mapL2[tL2])
        next_id += Lg2.num_verts()

    # ime in hitri check
    G.name(f"L_{n}")
    if G.num_verts() != n:
        raise RuntimeError(f"Napačno št. vozlišč v L_{n}: {G.num_verts()} != {n}")

    return G


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



from sage.all import graphs

def cubic_graphs(n):
    """
    Vrne generator vseh (neizomorfnih) 3-regularnih grafov na n vozliščih.
    Če connected=True: samo povezani.
    OPOMBA: n mora biti sodo in ≥ 4.
    """
    if n % 2 or n < 4:
        raise ValueError("n mora biti sodo in ≥ 4.")
    flags = f"-d3 -D3 -c {n}"
    return graphs.nauty_geng(flags)



def three_right_gadgets_star():
    # ============================================================
    # Zgradi nov graf H, v katerem je en sredinski vozel c
    # povezan s TREMI desnimi gradniki (_gadget_right()).
    # - vsak desni gradnik da terminal t (stopnje 2),
    #   ki ga tukaj povežemo na c → postane stopnje 3
    # - c ima tri povezave → stopnja 3
    #
    # Vrne:
    #   H : Graph (nov graf)
    #   c : oznaka sredinskega vozlišča
    #   terms : seznam terminalov treh desnih gradnikov (po vgradnji)
    # ============================================================
    H = Graph(multiedges=False, loops=False)
    next_id = 0
    terminals = []

    # dodaj 3× desni gradnik in shrani njihove terminale
    for _ in range(3):
        Rg, tR = _gadget_right()
        mapping = _add_with_offset(H, Rg, next_id)
        terminals.append(mapping[tR])
        next_id += Rg.num_verts()

    # sredinski vozel c in povezave nanj
    c = next_id
    H.add_vertex(c)
    for t in terminals:
        H.add_edge(c, t)

    # hiter sanity-check
    # assert all(d == 3 for d in H.degree()), "Ni kubičen!"
    return H

def left_gadgets_bridge():
    # ============================================================
    # Zgradi nov graf H:
    #   m1 ---- m2   (vmesni vozlišči, povezana z robom)
    #   |       |
    #  L_a     L_b   (na m1 in m2 priključen po en levi gradnik)
    #   |       |
    #  L_c     L_d   (na m1 in m2 priključen še EN levi gradnik)
    #
    # Skupaj: 4 × levi gradnik (4×5 = 20 vozlišč) + 2 vmesna = 22.
    # Vrnemo:
    #   H  : Graph
    #   m1 : int (prvo vmesno vozlišče)
    #   m2 : int (drugo vmesno vozlišče)
    # ============================================================
    H = Graph(multiedges=False, loops=False)
    next_id = 0

    # vgradi 4 leve gradnike in zabeleži njihove terminale
    terminals = []
    for _ in range(4):
        Lg, t = _gadget_left()
        mapping = _add_with_offset(H, Lg, next_id)
        terminals.append(mapping[t])
        next_id += Lg.num_verts()

    # ustvarimo vmesni vozlišči m1, m2 in ju povežemo
    m1, m2 = next_id, next_id + 1
    H.add_vertices([m1, m2])
    H.add_edge(m1, m2)

    # priklopi po dve levi gradniki na vsakega od m1, m2
    # (prva dva terminala na m1, druga dva na m2)
    H.add_edge(m1, terminals[0])
    H.add_edge(m1, terminals[2])
    H.add_edge(m2, terminals[1])
    H.add_edge(m2, terminals[3])

    # sanity-check: kubičnost
    # assert all(d == 3 for d in H.degree()), "Ni kubičen!"

    return H