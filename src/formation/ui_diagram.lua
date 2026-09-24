-- Run Info > Poker Hands (and the collection): every formation row starts with a small 5 x 3
-- diagram of its pattern (GDD §1.6), drawn with plain UI boxes (no texture).
-- The same diagrams are painted on the planet sprites (tools/gen_assets.py).

local Formation = NE.Formation

Formation.DIAGRAM_COLS, Formation.DIAGRAM_ROWS = 5, 3

-- Example pattern of each formation on a 5 x 3 board, as {col, row} (row 1 = Back, 3 = Front).
Formation.DIAGRAMS = {
    heavens_gate = 'all',
    five_line = { { 1, 2 }, { 2, 2 }, { 3, 2 }, { 4, 2 }, { 5, 2 } },
    royal_row = { { 1, 1 }, { 2, 1 }, { 3, 1 }, { 4, 1 }, { 5, 1 } },
    quad_square = { { 2, 1 }, { 3, 1 }, { 2, 2 }, { 3, 2 } },
    hell_pact = { { 1, 1 }, { 2, 2 }, { 3, 3 } },
    halo_line = { { 5, 1 }, { 4, 2 }, { 3, 3 } },
    compass = { { 3, 2 }, { 3, 1 }, { 2, 2 }, { 4, 2 }, { 3, 3 } },
    full_link = { { 1, 1 }, { 2, 1 }, { 3, 1 }, { 5, 2 }, { 5, 3 } },
    row_flush = { { 1, 3 }, { 2, 3 }, { 3, 3 }, { 4, 3 }, { 5, 3 } },
    row_straight = { { 1, 2 }, { 2, 2 }, { 3, 2 }, { 4, 2 }, { 5, 2 } },
    bastion = { { 3, 2 }, { 4, 2 }, { 3, 3 }, { 4, 3 } },
    triad = { { 2, 2 }, { 3, 2 }, { 4, 2 } },
    ascent = { { 2, 3 }, { 3, 2 }, { 4, 1 } },
    double_link = { { 1, 1 }, { 2, 1 }, { 4, 2 }, { 4, 3 } },
    kin_trio = { { 3, 1 }, { 3, 2 }, { 3, 3 } },
    twin_link = { { 2, 2 }, { 3, 2 } },
    spark = { { 3, 2 } },
}

local CELL = 0.1

local lit_cache = {}
-- Set of lit cells (index (row - 1) * cols + col) of a formation's diagram.
function Formation.diagram_cells(name)
    local set = lit_cache[name]
    if set then return set end
    set = {}
    local cols, rows = Formation.DIAGRAM_COLS, Formation.DIAGRAM_ROWS
    local d = Formation.DIAGRAMS[name]
    if d == 'all' then
        for i = 1, cols * rows do set[i] = true end
    elseif type(d) == 'table' then
        for _, cell in ipairs(d) do set[(cell[2] - 1) * cols + cell[1]] = true end
    end
    lit_cache[name] = set
    return set
end

function Formation.diagram_node(key)
    local def = Formation.DEF[key]
    if not def then return nil end
    local lit = Formation.diagram_cells(def.name)
    local on = G.C.SECONDARY_SET and G.C.SECONDARY_SET.Planet or G.C.BLUE
    local off = G.C.L_BLACK or G.C.BLACK
    local cols, rows = Formation.DIAGRAM_COLS, Formation.DIAGRAM_ROWS
    local row_nodes = {}
    for r = 1, rows do
        local cells = {}
        for c = 1, cols do
            cells[c] = { n = G.UIT.B, config = { w = CELL, h = CELL, r = 0.02,
                colour = lit[(r - 1) * cols + c] and on or off } }
        end
        row_nodes[r] = { n = G.UIT.R, config = { align = 'cm', padding = 0.012 }, nodes = cells }
    end
    return { n = G.UIT.C, config = { align = 'cm', padding = 0.03, r = 0.06, colour = G.C.BLACK }, nodes = row_nodes }
end

local row_ref = create_UIBox_current_hand_row
function create_UIBox_current_hand_row(handname, simple, in_collection)
    local node = row_ref(handname, simple, in_collection)
    if node and not simple and type(node.nodes) == 'table' and Formation.DEF[handname] then
        local ok, diagram = pcall(Formation.diagram_node, handname)
        if ok and diagram then
            table.insert(node.nodes, 1, diagram)
        elseif not ok then
            NE.log.warn_once('formation_diagram', 'Formation diagram failed: %s', tostring(diagram))
        end
    end
    return node
end
