-- Board patterns (GDD §1.3): every group of slots a formation can be made of. Built once per
-- board size and cached; pure functions of (cols, rows), so they are tested without the game.
--
--   pairs    2 orthogonally adjacent slots                            5x3: 22
--   lines    3 consecutive slots in a straight line (horizontal,
--            vertical, both diagonals)                                5x3: 20
--   rows     a whole row (only on boards at least MIN_ROW_COLS wide)  5x3: 3
--   blocks   2x2 squares                                              5x3: 8
--   compass  a slot and its 4 orthogonal neighbours                   5x3: 3
--   full     every slot                                               5x3: 1
--
-- Slots are listed in line order: left to right, top to bottom, diagonals from their top end.
-- "Consecutive ranks" formations read the cards in this order (either direction counts).
-- A compass lists its centre first, then up, left, right, down.

NE.Formation = NE.Formation or {}
local Patterns = {}
NE.Formation.Patterns = Patterns

Patterns.MIN_ROW_COLS = 3 -- narrower rows are too short for row formations

local function build(cols, rows)
    local function idx(c, r) return (r - 1) * cols + c end
    local p = {
        cols = cols, nrows = rows, size = cols * rows,
        pairs = {}, lines = {}, rows = {}, blocks = {}, compass = {}, full = {},
    }

    for r = 1, rows do
        for c = 1, cols do
            if c < cols then p.pairs[#p.pairs + 1] = { idx(c, r), idx(c + 1, r) } end
            if r < rows then p.pairs[#p.pairs + 1] = { idx(c, r), idx(c, r + 1) } end
        end
    end

    -- lines: horizontal, vertical, diagonal down-right, diagonal down-left
    local dirs = { { 1, 0 }, { 0, 1 }, { 1, 1 }, { -1, 1 } }
    for _, d in ipairs(dirs) do
        local dc, dr = d[1], d[2]
        for r = 1, rows do
            for c = 1, cols do
                local c3, r3 = c + 2 * dc, r + 2 * dr
                if c3 >= 1 and c3 <= cols and r3 <= rows then
                    p.lines[#p.lines + 1] = { idx(c, r), idx(c + dc, r + dr), idx(c3, r3) }
                end
            end
        end
    end

    if cols >= Patterns.MIN_ROW_COLS then
        for r = 1, rows do
            local row = {}
            for c = 1, cols do row[c] = idx(c, r) end
            p.rows[r] = row
        end
    end

    for r = 1, rows - 1 do
        for c = 1, cols - 1 do
            p.blocks[#p.blocks + 1] = { idx(c, r), idx(c + 1, r), idx(c, r + 1), idx(c + 1, r + 1) }
        end
    end

    for r = 2, rows - 1 do
        for c = 2, cols - 1 do
            p.compass[#p.compass + 1] = { idx(c, r), idx(c, r - 1), idx(c - 1, r), idx(c + 1, r), idx(c, r + 1) }
        end
    end

    for s = 1, cols * rows do p.full[s] = s end
    return p
end

local cache = {}

-- Pattern tables of a cols x rows board (shared; never modify them).
function Patterns.get(cols, rows)
    local key = cols * 100 + rows
    local p = cache[key]
    if not p then
        p = build(cols, rows)
        cache[key] = p
    end
    return p
end
