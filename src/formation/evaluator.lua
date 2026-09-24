-- Formation evaluator (GDD §1.3-1.5): finds the formations on the board and builds the chain.
--
-- 1. read: the evaluated cards are put on a board state (flat per-slot arrays, reused):
--      card on the board        its slot; new unless it is Residue
--      staged hand card         its reserved slot; new
--      other card (selection)   the slot quick play would give it; new
--    Per slot: rank id (0 = none), suit bitmask (flush rules: Wild cards match every suit),
--    and flags for Demon / Blessed cards (Phase 7 enhancements).
-- 2. run: pure logic on that state (tested without the game). A pattern only counts when it
--    holds at least one new card, so Residue never re-forms the same formation; Heaven's Gate
--    checks the whole board. Every formation found is listed (poker_hands for jokers).
-- 3. chain: formations by priority, at most one per formation type; each one after the first
--    must add at least one card not already counted, so a Twin Link inside a Triad does not
--    count twice. The Formation Cap (rule ne_formation_cap, 3) limits the chain. Without any
--    formation the chain is Spark: the highest-ranked new card.
-- 4. The result is cached: if the next evaluation reads the same state it is reused.

local Formation = NE.Formation
local Patterns = Formation.Patterns
local Board = NE.Board
local band, bor, lshift = bit.band, bit.bor, bit.lshift

Formation.ACE = 14
Formation.FLAG_DEMON = 1
Formation.FLAG_BLESSED = 2
Formation.DEMON_KEY = 'm_ne_demon'
Formation.BLESSED_KEY = 'm_ne_blessed'
Formation.MAX_COMBOS = 64 -- composite instances listed per formation (large boards)
Formation.DEFAULT_HAND = 'ne_spark'

NE.Rules.define('ne_formation_cap', 3) -- formations counted per hand (Primary + Secondaries)
NE.Rules.define('ne_chain_pct', 50)    -- % of a Secondary's chips and mult added in the Chain phase

-- The 17 formations, highest priority first (GDD §1.4). `name` is the key without the prefix.
-- order_offset keeps equal chips x mult values in this order (Steamodded sorts by it).
Formation.DEFS = {
    { name = 'heavens_gate', chips = 250, mult = 20, l_chips = 60, l_mult = 6, planet = 'empyrea' },
    { name = 'five_line', chips = 130, mult = 12, l_chips = 45, l_mult = 4, planet = 'polaris' },
    { name = 'royal_row', chips = 110, mult = 8, l_chips = 40, l_mult = 4, planet = 'andromeda' },
    { name = 'quad_square', chips = 70, mult = 7, l_chips = 35, l_mult = 3, planet = 'pegasus' },
    { name = 'hell_pact', chips = 60, mult = 6, l_chips = 30, l_mult = 3, planet = 'nibiru', order_offset = 0.02,
      currency = { kind = 'corruption', amount = 3 } },
    { name = 'halo_line', chips = 60, mult = 6, l_chips = 30, l_mult = 3, planet = 'sirius', order_offset = 0.01,
      currency = { kind = 'divinity', amount = 2 } },
    { name = 'compass', chips = 60, mult = 5, l_chips = 35, l_mult = 3, planet = 'crux' },
    { name = 'full_link', chips = 50, mult = 4, l_chips = 30, l_mult = 2, planet = 'perseus' },
    { name = 'row_flush', chips = 45, mult = 4, l_chips = 30, l_mult = 2, planet = 'cygnus' },
    { name = 'row_straight', chips = 40, mult = 4, l_chips = 30, l_mult = 2, planet = 'sagitta', order_offset = 0.02 },
    { name = 'bastion', chips = 40, mult = 4, l_chips = 25, l_mult = 2, planet = 'draco', order_offset = 0.01 },
    { name = 'triad', chips = 35, mult = 3, l_chips = 25, l_mult = 2, planet = 'orion' },
    { name = 'ascent', chips = 30, mult = 3, l_chips = 25, l_mult = 2, planet = 'aquila' },
    { name = 'double_link', chips = 25, mult = 2, l_chips = 20, l_mult = 1, planet = 'pollux' },
    { name = 'kin_trio', chips = 20, mult = 2, l_chips = 15, l_mult = 1, planet = 'lyra' },
    { name = 'twin_link', chips = 10, mult = 2, l_chips = 15, l_mult = 1, planet = 'gemini' },
    { name = 'spark', chips = 5, mult = 1, l_chips = 10, l_mult = 1, planet = 'proxima' },
}
Formation.ORDER = {} -- keys, highest priority first
Formation.DEF = {}   -- key -> def
for i, def in ipairs(Formation.DEFS) do
    def.key = NE.PREFIX .. '_' .. def.name
    def.priority = i
    Formation.ORDER[i] = def.key
    Formation.DEF[def.key] = def
end

local K = {}
for _, def in ipairs(Formation.DEFS) do K[def.name] = def.key end
Formation.K = K

function Formation.is_formation(key)
    return Formation.DEF[key] ~= nil
end

function Formation.cap()
    local n = tonumber(NE.Rules.get('ne_formation_cap')) or 3
    n = math.floor(n)
    if n ~= n or n < 1 then return 1 end
    if n > #Formation.DEFS then return #Formation.DEFS end
    return n
end

function Formation.chain_pct()
    local n = tonumber(NE.Rules.get('ne_chain_pct')) or 50
    if n ~= n or n < 0 then return 0 end
    return n
end

-- Checks on a list of slots ---------------------------------------------------------------------------

local function filled(st, slots)
    for i = 1, #slots do
        if not st.card[slots[i]] then return false end
    end
    return true
end

local function has_new(st, slots)
    for i = 1, #slots do
        if st.new[slots[i]] then return true end
    end
    return false
end

local function same_rank(st, slots)
    local r = st.rank[slots[1]]
    if r <= 0 then return false end
    for i = 2, #slots do
        if st.rank[slots[i]] ~= r then return false end
    end
    return true
end

local function same_suit(st, slots)
    local m = st.suit[slots[1]]
    for i = 2, #slots do
        if m == 0 then return false end
        m = band(m, st.suit[slots[i]])
    end
    return m ~= 0
end

-- Consecutive ranks in slot order, all rising or all falling by one. An Ace is high or low,
-- not both (no wrapping around K-A-2).
local function sequence_with(st, slots, ace_low)
    local prev, dir
    for i = 1, #slots do
        local r = st.rank[slots[i]]
        if r <= 0 then return false end
        if ace_low and r == Formation.ACE then r = 1 end
        if prev then
            local d = r - prev
            if d ~= 1 and d ~= -1 then return false end
            if dir and d ~= dir then return false end
            dir = d
        end
        prev = r
    end
    return true
end

local function sequence(st, slots)
    return sequence_with(st, slots, false) or sequence_with(st, slots, true)
end

local function all_flag(st, slots, flag)
    for i = 1, #slots do
        if band(st.flag[slots[i]], flag) == 0 then return false end
    end
    return true
end

local function row_formation(st, row)
    return filled(st, row) and (same_rank(st, row) or same_suit(st, row) or sequence(st, row))
end

local function disjoint(a, b)
    for i = 1, #a do
        for j = 1, #b do
            if a[i] == b[j] then return false end
        end
    end
    return true
end

Formation.check = {
    filled = filled, has_new = has_new, same_rank = same_rank, same_suit = same_suit,
    sequence = sequence, all_flag = all_flag, row_formation = row_formation,
}

-- Finding formations -------------------------------------------------------------------------------------

local function add(found, key, slots)
    local list = found[key]
    if not list then
        list = {}
        found[key] = list
    end
    list[#list + 1] = slots
    return #list
end

local function any_new(st)
    for s = 1, st.n do
        if st.card[s] and st.new[s] then return true end
    end
    return false
end

-- Every formation on the board (pattern instances are shared read-only slot lists).
function Formation.find(st)
    local P = Patterns.get(st.cols, st.rows)
    local found = {}

    -- Heaven's Gate: full board, every row a row formation (activation: the whole board)
    local rows = P.rows
    if rows[1] and filled(st, P.full) and any_new(st) then
        local ok = true
        for r = 1, #rows do
            if not row_formation(st, rows[r]) then
                ok = false
                break
            end
        end
        if ok then add(found, K.heavens_gate, P.full) end
    end

    for r = 1, #rows do
        local row = rows[r]
        if filled(st, row) and has_new(st, row) then
            local rank, suit, seq = same_rank(st, row), same_suit(st, row), sequence(st, row)
            if rank then add(found, K.five_line, row) end
            if suit and seq then add(found, K.royal_row, row) end
            if suit then add(found, K.row_flush, row) end
            if seq then add(found, K.row_straight, row) end
        end
    end

    for _, block in ipairs(P.blocks) do
        if filled(st, block) and has_new(st, block) then
            if same_rank(st, block) then add(found, K.quad_square, block) end
            if same_suit(st, block) then add(found, K.bastion, block) end
        end
    end

    for _, c in ipairs(P.compass) do
        if filled(st, c) and has_new(st, c) and same_suit(st, c) then add(found, K.compass, c) end
    end

    for _, line in ipairs(P.lines) do
        if filled(st, line) and has_new(st, line) then
            if all_flag(st, line, Formation.FLAG_DEMON) then add(found, K.hell_pact, line) end
            if all_flag(st, line, Formation.FLAG_BLESSED) then add(found, K.halo_line, line) end
            if same_rank(st, line) then add(found, K.triad, line) end
            if sequence(st, line) then add(found, K.ascent, line) end
            if same_suit(st, line) then add(found, K.kin_trio, line) end
        end
    end

    for _, pair in ipairs(P.pairs) do
        if filled(st, pair) and has_new(st, pair) and same_rank(st, pair) then
            add(found, K.twin_link, pair)
        end
    end

    -- composites: two Twin Links / a Triad and a Twin Link that share no card
    local twins, triads = found[K.twin_link], found[K.triad]
    if twins then
        local n = 0
        for i = 1, #twins - 1 do
            for j = i + 1, #twins do
                if n < Formation.MAX_COMBOS and disjoint(twins[i], twins[j]) then
                    local a, b = twins[i], twins[j]
                    n = add(found, K.double_link, { a[1], a[2], b[1], b[2] })
                end
            end
        end
        if triads then
            n = 0
            for i = 1, #triads do
                for j = 1, #twins do
                    if n < Formation.MAX_COMBOS and disjoint(triads[i], twins[j]) then
                        local t, w = triads[i], twins[j]
                        n = add(found, K.full_link, { t[1], t[2], t[3], w[1], w[2] })
                    end
                end
            end
        end
    end

    return found
end

-- Spark: the highest-ranked new card (the first one in slot order on ties); any card if no card
-- is new (never happens for a played hand).
function Formation.spark_slot(st)
    local best, br
    for pass = 1, 2 do
        for s = 1, st.n do
            if st.card[s] and (pass == 2 or st.new[s]) then
                local r = st.rank[s]
                if not best or r > br then best, br = s, r end
            end
        end
        if best then return best end
    end
    return nil
end

-- Chain ------------------------------------------------------------------------------------------------------

-- Instance value against the cards already counted: cards it adds, new cards, rank total, and
-- its first slot (lower is better on a full tie).
local function measure(st, slots, covered)
    local add_n, new_n, rank_sum, first = 0, 0, 0, math.huge
    for i = 1, #slots do
        local s = slots[i]
        if not covered[s] then add_n = add_n + 1 end
        if st.new[s] then new_n = new_n + 1 end
        rank_sum = rank_sum + st.rank[s]
        if s < first then first = s end
    end
    return add_n, new_n, rank_sum, first
end

local function pick(st, list, covered)
    local best, ba, bn, br, bf
    for i = 1, #list do
        local a, n, r, f = measure(st, list[i], covered)
        if a > 0 and (not best or a > ba or (a == ba and (n > bn or (n == bn and (r > br or (r == br and f < bf)))))) then
            best, ba, bn, br, bf = list[i], a, n, r, f
        end
    end
    return best
end

-- Evaluates a board state: { found, chain = { {key, slots} }, primary, scoring = slot list }.
function Formation.run(st, cap)
    cap = cap or Formation.cap()
    local found = Formation.find(st)
    local chain, covered = {}, {}
    for _, key in ipairs(Formation.ORDER) do
        if #chain >= cap then break end
        local list = found[key]
        if list and key ~= K.spark then
            local slots = pick(st, list, covered)
            if slots then
                chain[#chain + 1] = { key = key, slots = slots }
                for i = 1, #slots do covered[slots[i]] = true end
            end
        end
    end

    local spark = Formation.spark_slot(st)
    if spark then
        found[K.spark] = { { spark } }
        if not chain[1] then
            chain[1] = { key = K.spark, slots = found[K.spark][1] }
            covered[spark] = true
        end
    end

    local scoring = {}
    for s = 1, st.n do
        if covered[s] then scoring[#scoring + 1] = s end
    end
    return { found = found, chain = chain, primary = chain[1] and chain[1].key or nil, scoring = scoring }
end

-- Reading the cards --------------------------------------------------------------------------------------

Formation.stats = Formation.stats or { reads = 0, evaluations = 0, cache_hits = 0 }

local function new_state()
    return { cols = 0, rows = 0, n = 0, cap = 0, card = {}, new = {}, rank = {}, suit = {}, flag = {} }
end
local state = new_state()    -- last read
local snapshot = new_state() -- state of the cached result
local cached_result = nil
Formation.state = state

local DEFAULT_SUITS = { 'Spades', 'Hearts', 'Clubs', 'Diamonds' }
local MAX_SUITS = 30

function Formation.rank_of(card)
    local ok, id = pcall(card.get_id, card)
    if not ok or type(id) ~= 'number' or id ~= id or id <= 0 then return 0 end
    return id
end

function Formation.suit_mask(card)
    local keys = SMODS.Suit and SMODS.Suit.obj_buffer or DEFAULT_SUITS
    local m = 0
    for i = 1, math.min(#keys, MAX_SUITS) do
        if card:is_suit(keys[i], nil, true) then m = bor(m, lshift(1, i - 1)) end
    end
    return m
end

function Formation.flags_of(card)
    local f = 0
    if SMODS.has_enhancement then
        if SMODS.has_enhancement(card, Formation.DEMON_KEY) then f = bor(f, Formation.FLAG_DEMON) end
        if SMODS.has_enhancement(card, Formation.BLESSED_KEY) then f = bor(f, Formation.FLAG_BLESSED) end
    end
    return f
end

local pending, hand_pos = {}, {}
local function by_hand_pos(a, b)
    local pa, pb = hand_pos[a] or 1e9, hand_pos[b] or 1e9
    if pa ~= pb then return pa < pb end
    return (a.sort_id or 0) < (b.sort_id or 0)
end

local function place(st, s, card, is_new)
    st.card[s] = card
    st.new[s] = is_new
    st.rank[s] = Formation.rank_of(card)
    st.suit[s] = Formation.suit_mask(card)
    st.flag[s] = Formation.flags_of(card)
end

-- Puts `cards` on the board state (see the header). Cards that find no slot are left out.
function Formation.read(cards, st)
    st = st or state
    local cols, rows = Board.dims()
    local n = cols * rows
    for s = 1, math.max(n, st.n) do
        st.card[s], st.new[s], st.rank[s], st.suit[s], st.flag[s] = false, false, 0, 0, 0
    end
    st.cols, st.rows, st.n = cols, rows, n
    Formation.stats.reads = Formation.stats.reads + 1

    local board = Board.area()
    local np = 0
    for i = 1, #cards do
        local card = cards[i]
        local s, is_new
        if board and card.area == board then
            s = card.ability and card.ability.ne_slot
            is_new = not Board.is_residue(card)
            if not Board.valid_slot(s) then s = nil end -- no slot (board full): not on the board
        else
            s = board and Board.staged_slot(card) or nil
            is_new = true
            if not s then
                np = np + 1
                pending[np] = card
            end
        end
        if s and s <= n and not st.card[s] then place(st, s, card, is_new) end
    end

    if np > 0 then
        -- same slots as quick play: selection order in hand, first free slot in fill order,
        -- skipping board cards and staged reservations that are not part of `cards`
        local hand = G.hand and G.hand.cards or {}
        for k in pairs(hand_pos) do hand_pos[k] = nil end
        for i = 1, #hand do hand_pos[hand[i]] = i end
        for i = np + 1, #pending do pending[i] = nil end
        table.sort(pending, by_hand_pos)
        local occ = board and Board.refresh() or {}
        local order = board and Board.fill_order() or NE.Board.Grid.fill_order(cols, rows)
        local k = 1
        for i = 1, np do
            while k <= #order and (st.card[order[k]] or occ[order[k]]) do k = k + 1 end
            if k > #order then break end
            place(st, order[k], pending[i], true)
            k = k + 1
        end
        for i = 1, np do pending[i] = nil end
        for kc in pairs(hand_pos) do hand_pos[kc] = nil end
    end
    return st
end

local function same_state(a, b)
    if a.cols ~= b.cols or a.rows ~= b.rows or a.cap ~= b.cap then return false end
    for s = 1, a.n do
        if a.card[s] ~= b.card[s] or a.new[s] ~= b.new[s] or a.rank[s] ~= b.rank[s]
            or a.suit[s] ~= b.suit[s] or a.flag[s] ~= b.flag[s] then
            return false
        end
    end
    return true
end

local function save_snapshot(st)
    snapshot.cols, snapshot.rows, snapshot.n, snapshot.cap = st.cols, st.rows, st.n, st.cap
    for s = 1, st.n do
        snapshot.card[s], snapshot.new[s], snapshot.rank[s] = st.card[s], st.new[s], st.rank[s]
        snapshot.suit[s], snapshot.flag[s] = st.suit[s], st.flag[s]
    end
end

function Formation.invalidate()
    cached_result = nil
end

-- Result of the current state (cached).
function Formation.evaluate_state(st)
    st.cap = Formation.cap()
    if cached_result and same_state(st, snapshot) then
        Formation.stats.cache_hits = Formation.stats.cache_hits + 1
        return cached_result
    end
    Formation.stats.evaluations = Formation.stats.evaluations + 1
    cached_result = Formation.run(st, st.cap)
    save_snapshot(st)
    return cached_result
end

-- Card view of a result -----------------------------------------------------------------------------------

local function cards_of(st, slots)
    local out = {}
    for i = 1, #slots do out[i] = st.card[slots[i]] end
    return out
end

-- Evaluates a list of cards. Returns a view with fresh tables:
--   input        the list that was evaluated
--   primary      formation key (nil without cards)
--   chain        { {key, cards, slots} } Primary first
--   scoring      cards of every counted formation, in slot order
--   poker_hands  key -> list of card lists, for every formation found
--   slot_of      card -> slot it was evaluated on
function Formation.evaluate_cards(cards)
    local st = Formation.read(cards)
    local res = Formation.evaluate_state(st)
    local view = { input = cards, primary = res.primary, chain = {}, scoring = cards_of(st, res.scoring),
        poker_hands = {}, slot_of = {} }
    for i, link in ipairs(res.chain) do
        view.chain[i] = { key = link.key, cards = cards_of(st, link.slots), slots = link.slots }
    end
    for key, list in pairs(res.found) do
        local out = {}
        for i = 1, #list do out[i] = cards_of(st, list[i]) end
        view.poker_hands[key] = out
    end
    for s = 1, st.n do
        if st.card[s] then view.slot_of[st.card[s]] = s end
    end
    return view
end

-- Chain of the latest evaluation for the F9 overlay ("triad+ascent", '-' if none).
function Formation.debug_chain()
    local view = Formation.current
    if not (view and view.chain and view.chain[1]) then return '-' end
    local parts = {}
    for i, link in ipairs(view.chain) do
        local def = Formation.DEF[link.key]
        parts[i] = def and def.name or tostring(link.key)
    end
    return table.concat(parts, '+')
end

-- Display text of a chain: "Triad + Twin Link".
function Formation.chain_text(view)
    local parts = {}
    for i, link in ipairs(view.chain) do parts[i] = localize(link.key, 'poker_hands') end
    return table.concat(parts, ' + ')
end
