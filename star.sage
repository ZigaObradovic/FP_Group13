def which_gadget(n):

    if n % 2 != 0 or n < 10:
        raise ValueError("n mora biti sodo in n >= 10")
    mod = n % 6
    m = (n - 10) // 6
    if mod == 0:
        return (True, False, m)
    elif mod == 2:
        return (False, False, m)
    elif mod == 4:
        return (True, True, m)
    else:
        # ne bi smelo nastopiti, ker n je sodo
        raise ValueError("Nepričakovan vzorec za n = {}".format(n))

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

def build_star(n):
    # ============================================================
    # Zgradi graf iz treh parametrov:
    #   l : bool  -> začetni gradnik (True = left, False = right)
    #   r : bool  -> končni gradnik (True = left, False = right)
    #   m : int   -> število vmesnih vozlišč (m >= 0)
    #
    # Pravila:
    #   1) začni z left/right glede na l
    #   2) če m > 0, dodaj m vmesnih vozlišč v verigo med začetnim
    #      in končnim gradnikom:
    #         start -- v1 -- v2 -- ... -- vm -- end
    #   3) na vsako vmesno vozlišče vik priklopi NOV left gradnik
    #      (preko njegovega terminala)
    #   4) končaj z left/right glede na r
    #
    # Lastnosti:
    #   - terminali v gradnikih so stopnje 2; po priklopu postanejo 3
    #   - vmesno vozlišče ima tri soseda: veriga (levo, desno) + priklopljen left
    #   - rezultat je kubičen (3-regularen), če so gradniki pravilno definirani
    # ============================================================
    l, r, m = which_gadget(n)

    if m < 0:
        raise ValueError("m mora biti celo število >= 0")

    G = Graph(multiedges=False, loops=False)
    next_id = 0

    # 1) Začetni gradnik (l)
    if l:
        G0, t_start = _gadget_left()
    else:
        G0, t_start = _gadget_right()
    map0 = _add_with_offset(G, G0, next_id)
    start_term = map0[t_start]
    next_id += G0.num_verts()

    # 2) Če m == 0: neposredna povezava na končni gradnik in konec
    if m == 0:
        if r:
            G1, t_end = _gadget_left()
        else:
            G1, t_end = _gadget_right()
        map1 = _add_with_offset(G, G1, next_id)
        end_term = map1[t_end]
        G.add_edge(start_term, end_term)
        G.name(f"LRM(l={l}, r={r}, m={m})")
        return G

    # 3) Sicer: naredi m vmesnih vozlišč v verigo
    mids = list(range(next_id, next_id + m))
    G.add_vertices(mids)
    next_id += m

    # povezave verige: start -- mids[0] -- mids[1] -- ... -- mids[-1]
    G.add_edge(start_term, mids[0])
    for i in range(len(mids) - 1):
        G.add_edge(mids[i], mids[i + 1])

    # 4) Na vsako vmesno vozlišče priklopi NOV left gradnik preko njegovega terminala
    for v in mids:
        Lg, tL = _gadget_left()
        mapL = _add_with_offset(G, Lg, next_id)
        term = mapL[tL]
        G.add_edge(v, term)
        next_id += Lg.num_verts()

    # 5) Končni gradnik (r) in priklop na zadnje vmesno vozlišče
    if r:
        Gend, t_end = _gadget_left()
    else:
        Gend, t_end = _gadget_right()
    mapE = _add_with_offset(G, Gend, next_id)
    end_term = mapE[t_end]
    G.add_edge(mids[-1], end_term)

    G.name(f"LRM(l={l}, r={r}, m={m})")
    return G
