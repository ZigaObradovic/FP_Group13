def left_gadget():
    """Konstruira levi gradnik"""

    G = graphs.CompleteGraph(4)  # K4
    G.delete_edge(0, 1)          # K4 - e; 0 in 1 sta zdaj stopnje 2

    t = 4
    G.add_vertex(t) # Dodamo zgornje vozlišče
    G.add_edge(t, 0)
    G.add_edge(t, 1) # Povežemo zgornje vozlišče

    return G, t # Vrnemo graf in vozlišče na katerega bomo vezali naprej

def left_gadget2():
    """Konstruira levi gradnik"""

    G = graphs.CompleteGraph(4)  # K4
    G.delete_edge(0, 1)          # K4 - e; 0 in 1 sta zdaj stopnje 2

    return G, 0, 1 # Vrnemo graf in vozlišče na katerega bomo vezali naprej

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

def right_gadget2():
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

    return G, x, y # Vrnemo graf in vozlišče na katerega bomo vezali naprej


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

def add_gadget2(G, t1, H, t2, t3):
    """Podanemu grafu G doda graf H z zamaknjenim številčenjem vozlišč za k"""

    k = G.num_verts()
    mapping = {v: v + k for v in H.vertices()} # Slovar: staro številčenje -> novo številčenje
    H2 = H.relabel(mapping, inplace=False) # Graf H z zamaknjenim številčenjem

    # Graf H2 dodamo zraven grafa G in jih ne povežemo
    G.add_vertices(H2.vertices())
    G.add_edges(H2.edges(labels=False))

    # Povežemo in označimo zadnje vozlišče
    # Odvisno je od tega ali dodajamo srednje gradnike, ali leve oz. desne
    G.add_edge(t1, mapping[t2])
    G.add_edge(t1, mapping[t3])

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

def build_star2(n):
    """Naredi boljši graf kot Ln"""

    # Varovalka za sode n > 10
    if n % 2 != 0 or n < 10:
        raise ValueError("Za L_n mora biti n sodo in n >= 10.")

    # določanje začetnih in končnih gradnikov
    mod = n % 6
    m = (n - 10) // 6 # Število vmesnih gradnikov
    if mod == 0:
        srednji, levi_konec = False, False
    elif mod == 2:
        srednji, levi_konec = True, True
    elif mod == 4:
        srednji, levi_konec = False, True

    # Začnemo z levim gradnikom
    G, t = left_gadget()

    # Dodamo m vmesnih (levih) gradnikov
    if m > 0:
        H, y = left_gadget()
        for _ in range(m):
            x = G.num_verts()
            G.add_vertex(x) # Dodamo vozlišče za povezavo
            G.add_edge(t, x) # povežemo ga z osnovo
            G = add_gadget(G, x, H, y)
            t = x

    # Po potrebi dodamo srednji gradnik
    if srednji:
        H, x, y = middle_gadget()
        G, t = add_gadget(G, t, H, x, y)

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




#--------------------------------------------------------------------------------
#--------------------------------------------------------------------------------
#--------------------------------------------------------------------------------
#--------------------------------------------------------------------------------

def encode_time_hms(elapsed):
    """
    Pretvori elapsed (v sekundah) v hh:mm:ss.sss
    """
    h  = int(elapsed // 3600)
    m  = int((elapsed % 3600) // 60)
    s  = int(elapsed % 60)
    ms = int((elapsed - int(elapsed)) * 1000)
    return f"{h:02d}:{m:02d}:{s:02d}.{ms:03d}"


from sage.all import Graph

def tree(k):
    """
    Zgradi drevo na k vozliščih (k sodo, k >= 4).

    Vrne:
        G      ... drevo kot Sage Graph
        leaves ... seznam končnih vozlišč (listov), v vrstnem redu nastanka
    """

    if k % 2 != 0 or k < 4:
        raise ValueError("k mora biti sodo in k >= 4.")

    G = Graph()

    # Dodamo koren
    root = 0
    G.add_vertex(root)

    # Prva razvejitev: koren -> trije otroci
    leaves = []
    for i in range(1, 4):
        G.add_vertex(i)
        G.add_edge(root, i)
        leaves.append(i)

    current_n = 4

    # Nadaljnje razvejitve
    while current_n < k:
        v = leaves.pop(0)  # vzamemo najstarejši list

        a = current_n
        b = current_n + 1
        G.add_vertices([a, b])
        G.add_edge(v, a)
        G.add_edge(v, b)

        # v ni več list; nova lista:
        leaves.append(a)
        leaves.append(b)

        current_n += 2

    return G, leaves
def build_tree(n):
    """Naredi boljši graf kot Ln"""

    # Varovalka za sode n > 10
    if n % 2 != 0 or n < 10:
        raise ValueError("Za L_n mora biti n sodo in n >= 10.")

    # določanje začetnih in končnih gradnikov
    mod = n % 6
    if mod == 0:
        levi_prvi, levi_drugi = True, False
    elif mod == 2:
        levi_prvi, levi_drugi = False, False
    elif mod == 4:
        levi_prvi, levi_drugi = True, True

    k = 4 + 2 * ((n - 16) // 6)

    # Začnemo z drevesom
    G, leaves = tree(k)
    H1, t11, t12 = left_gadget2()
    H2, t21, t22 = right_gadget2()

    for i, t in enumerate(leaves):
        if i == 0:
            if levi_prvi:
                G = add_gadget2(G, t, H1, t11, t12)
            else:
                G = add_gadget2(G, t, H2, t21, t22)
        elif i == 1:
            if levi_drugi:
                G = add_gadget2(G, t, H1, t11, t12)
            else:
                G = add_gadget2(G, t, H2, t21, t22)
        else:
            G = add_gadget2(G, t, H1, t11, t12)

    return G

from collections import deque

def tree_layout_positions_from_tree(T, root=0):
    """
    Za dani graf T, za katerega VEMO, da je drevo, vrne slovar
        pos[v] = (x, y)
    za lep drevesni layout (root zgoraj, listi spodaj).
    """

    V = list(T.vertices())
    parent = {root: None}
    depth = {root: 0}
    children = {v: [] for v in V}

    # BFS: zgradimo usmerjeno drevo (parent, children, depth)
    Q = deque([root])
    while Q:
        v = Q.popleft()
        for u in T.neighbors(v):
            if u not in parent:
                parent[u] = v
                depth[u] = depth[v] + 1
                children[v].append(u)
                Q.append(u)

    # DFS: dodelimo x-koordinate; listi so enakomerno razporejeni,
    # notranja vozlišča dobijo povprečje x-koordinat svojih otrok.
    x = {}
    counter = [0]

    def dfs(v):
        if not children[v]:   # list
            x[v] = counter[0]
            counter[0] += 1
        else:
            for u in children[v]:
                dfs(u)
            x[v] = sum(x[u] for u in children[v]) / len(children[v])

    dfs(root)

    # Končni slovar pozicij
    vertical_scale = 3   # poljubno: 1.5 .. 5
    pos = {v: (x[v], -depth[v] * vertical_scale) for v in V}

    return pos

def spanning_tree(G, root=0):
    """
    Vrne razpenjalno drevo grafa G kot nov Graph objekt.
    Deluje v vseh SageMath verzijah.
    """

    T = Graph()
    T.add_vertices(G.vertices())

    visited = set([root])
    queue = [root]

    while queue:
        v = queue.pop(0)
        for u in G.neighbors(v):
            if u not in visited:
                visited.add(u)
                queue.append(u)
                T.add_edge(v, u)

    return T


def show_build_tree_tree_layout(n, root=0, **show_kwds):
    """
    Zgradi graf G = build_tree(n) in ga nariše v drevesni postavitvi.

    - Najprej iz G vzamemo razpenjalno drevo T (spanning tree) z danim korenom.
    - Na T naredimo lep drevesni layout.
    - Te koordinate uporabimo za G.show(pos=...).
    """

    # 1) Kubični graf z gadgeti
    G = build_tree(n)

    # 2) Razpenjalno drevo (spanning tree) – to je dejansko drevo
    T = spanning_tree(G, root = root)

    # 3) Lep drevesni layout na T
    pos = tree_layout_positions_from_tree(T, root=root)

    # 4) Narišemo G z istimi koordinatami
    default_kwds = dict(
        vertex_size=10,
        vertex_color="black",
        vertex_labels=False,
        edge_thickness=1,
        figsize=[5, 5],
    )
    # dopustimo, da s **show_kwds prepišeš default nastavitve
    default_kwds.update(show_kwds)

    G.show(pos=pos, **default_kwds)



