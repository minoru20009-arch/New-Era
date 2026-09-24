-- Board geometry (GDD §1.1): slot numbering and the on-screen layout of the board.
-- Pure functions of the board size and a few screen measures, so they can be tested without
-- the game.
--
-- Rows are numbered top to bottom. Row 1 is the Back row (farthest from the hand), row `rows`
-- is the Front row (next to the hand), every row in between is a Middle row; a one-row board
-- only has a Middle row. Slots are numbered row by row, left to right:
--   slot = (row - 1) * cols + col
-- which is also the order cards are scored and drawn in (back rows first).

NE.Board = NE.Board or {}
local Grid = {}
NE.Board.Grid = Grid

Grid.DEFAULT_COLS = 5
Grid.DEFAULT_ROWS = 3
Grid.MAX_COLS = 8
Grid.MAX_ROWS = 5

-- Layout constants.
Grid.BACK_SCALE = 0.84 -- Back row card size relative to the Front row (0.84 / 0.92 / 1.0 on 3 rows)
Grid.VISIBLE = 0.5     -- part of a card left visible by the row in front of it
Grid.GAP = 0.1         -- gap between two cards of a row, as a fraction of the card width
Grid.MAX_SCALE = 0.8   -- largest Front row card, relative to a card in hand
Grid.CARD_SCALE = 0.95 -- Card.T.scale of a card at full size (the game's default)

local floor = math.floor

function Grid.clamp_dim(v, max, default)
    v = tonumber(v)
    if not v or v ~= v then return default end
    v = floor(v)
    if v < 1 then return 1 end
    if v > max then return max end
    return v
end

function Grid.index(cols, c, r)
    return (r - 1) * cols + c
end

function Grid.coords(cols, slot)
    local r = floor((slot - 1) / cols) + 1
    return slot - (r - 1) * cols, r
end

-- 'back', 'middle' or 'front'.
function Grid.row_kind(rows, r)
    if rows <= 1 then return 'middle' end
    if r == rows then return 'front' end
    if r == 1 then return 'back' end
    return 'middle'
end

-- Card size of row r relative to the Front row.
function Grid.row_scale(rows, r)
    if rows <= 1 then return 1 end
    return Grid.BACK_SCALE + (1 - Grid.BACK_SCALE) * (r - 1) / (rows - 1)
end

-- Quick play order (GDD §1.2): Middle rows left to right, then the Front row, then the Back row.
function Grid.fill_order(cols, rows)
    local order = {}
    local function add_row(r)
        for c = 1, cols do order[#order + 1] = Grid.index(cols, c, r) end
    end
    for r = 2, rows - 1 do add_row(r) end
    if rows == 1 then
        add_row(1)
    else
        add_row(rows)
        add_row(1)
    end
    return order
end

-- Orthogonal neighbours of a slot (up to 4), as a new list.
function Grid.neighbors(cols, rows, slot)
    local c, r = Grid.coords(cols, slot)
    local out = {}
    if r > 1 then out[#out + 1] = Grid.index(cols, c, r - 1) end
    if c > 1 then out[#out + 1] = Grid.index(cols, c - 1, r) end
    if c < cols then out[#out + 1] = Grid.index(cols, c + 1, r) end
    if r < rows then out[#out + 1] = Grid.index(cols, c, r + 1) end
    return out
end

function Grid.adjacent(cols, a, b)
    local ca, ra = Grid.coords(cols, a)
    local cb, rb = Grid.coords(cols, b)
    return math.abs(ca - cb) + math.abs(ra - rb) == 1
end

-- Computes the layout of a cols x rows board inside `box` into `out` (reused between calls):
--   box = { cx, top, bottom, max_w, card_w, card_h, scale }
--     cx        horizontal centre of the board
--     top       highest y the Back row may use; bottom = lowest y the Front row may use
--     max_w     widest row allowed
--     card_w/h  size of a card as drawn in hand (T.w, T.h times the default T.scale)
--     scale     user multiplier (1 = largest size that fits)
--   out.k                Front row card size relative to a card in hand
--   out.x, y, w, h       bounding rectangle of the board
--   out.slots[i]         { x, y, w, h, scale, col, row } visual rectangle of slot i; `scale`
--                        is the Card.T.scale that draws a card exactly over the rectangle
function Grid.layout(cols, rows, box, out)
    out = out or {}
    out.slots = out.slots or {}
    local vis = Grid.VISIBLE

    -- height and width of the board at k = 1
    local h1 = box.card_h
    for r = 1, rows - 1 do h1 = h1 + vis * box.card_h * Grid.row_scale(rows, r) end
    local w1 = box.card_w * (cols + Grid.GAP * (cols - 1))

    local avail_h = math.max(0.1, box.bottom - box.top)
    local k = math.min(avail_h / h1, box.max_w / w1, Grid.MAX_SCALE) * (box.scale or 1)
    if k <= 0 or k ~= k then k = 0.1 end

    local height = h1 * k
    local y = box.top + (avail_h - height) / 2
    out.k = k
    out.y = y
    out.h = height
    out.w = w1 * k
    out.x = box.cx - out.w / 2

    for r = 1, rows do
        local s = k * Grid.row_scale(rows, r)
        local cw, ch = box.card_w * s, box.card_h * s
        local gap = Grid.GAP * cw
        local row_w = cols * cw + (cols - 1) * gap
        local x0 = box.cx - row_w / 2
        for c = 1, cols do
            local i = Grid.index(cols, c, r)
            local slot = out.slots[i] or {}
            out.slots[i] = slot
            slot.x = x0 + (c - 1) * (cw + gap)
            slot.y = y
            slot.w = cw
            slot.h = ch
            slot.scale = Grid.CARD_SCALE * s
            slot.col = c
            slot.row = r
        end
        y = y + vis * ch
    end
    for i = cols * rows + 1, #out.slots do out.slots[i] = nil end
    out.cols, out.rows = cols, rows
    return out
end
