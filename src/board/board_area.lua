-- The board (GDD §1.1, architecture §4.1): the game's play area G.play reshaped into a
-- cols x rows grid (5 x 3 by default). Every Steamodded context that uses G.play keeps working.
--
-- Card data (saved with the card, since Card:save stores `ability`):
--   ability.ne_slot     slot of the card on the board (grid.lua numbering)
--   ability.ne_residue  the card stayed on the board after an earlier hand (Residue)
--   ability.ne_since    hands_played when the card entered the board (oldest Residue leaves first)
-- Board data (saved with the area config): G.play.config.ne_board = { cols, rows }.
--
-- Hand flow: cards placed on the board before Play stay in G.hand as highlighted cards with
-- a reserved slot (placement.lua), so every vanilla rule for played cards still applies. On
-- Play they move into G.play and take their slot (CardArea:emplace wrap); highlighted cards
-- without a slot are placed automatically (quick play). After scoring, scored cards leave the
-- board and the rest stay as Residue (Board.keeps, used by patch L14). The whole board is
-- discarded at the end of the round.
--
-- Residue limit: at most (slots - play limit) Residue cards stay after a hand, so the board
-- always has room for a full hand; the oldest Residue leaves first. Without this, a full
-- board with no discards left would lock the round.

local Board = NE.Board
local Grid = Board.Grid

Board.version = Board.version or 0 -- bumped whenever the board changes
Board.stage = Board.stage or {}   -- staged hand card -> reserved slot (placement.lua)
Board.stage_origin = Board.stage_origin or {} -- staged hand card -> its hand position
Board.marked = Board.marked or {} -- Residue cards selected for Discard
Board.slots = Board.slots or {}   -- slot nodes (controller.lua)
Board.occ = Board.occ or {}       -- slot -> card on the board or staged there (Board.refresh)
Board.layout = Board.layout or { slots = {} }

Board.LIFT = 0.12 -- how far a highlighted board card is raised, as a fraction of its height

local function bump()
    Board.version = Board.version + 1
end
Board.bump = bump

-- Area & size ---------------------------------------------------------------------------------------

function Board.is_board(area)
    return area ~= nil and G.play ~= nil and area == G.play and type(area.config) == 'table'
        and type(area.config.ne_board) == 'table'
end

-- G.play when it is a board, else nil.
function Board.area()
    local area = G and G.play
    if area and Board.is_board(area) then return area end
    return nil
end

function Board.dims()
    local area = Board.area()
    if not area then return Grid.DEFAULT_COLS, Grid.DEFAULT_ROWS end
    local nb = area.config.ne_board
    return nb.cols, nb.rows
end

function Board.size()
    local cols, rows = Board.dims()
    return cols * rows
end

function Board.index(c, r)
    local cols = Board.dims()
    return Grid.index(cols, c, r)
end

function Board.coords(slot)
    local cols = Board.dims()
    return Grid.coords(cols, slot)
end

function Board.row_kind(slot)
    local cols, rows = Board.dims()
    local _, r = Grid.coords(cols, slot)
    return Grid.row_kind(rows, r)
end

function Board.valid_slot(slot)
    return type(slot) == 'number' and slot >= 1 and slot <= Board.size() and slot == math.floor(slot)
end

function Board.play_limit()
    local sp = G.GAME and G.GAME.starting_params
    local n = sp and tonumber(sp.play_limit) or 5
    return math.max(1, n)
end

function Board.discard_limit()
    local sp = G.GAME and G.GAME.starting_params
    local n = sp and tonumber(sp.discard_limit) or 5
    return math.max(0, n)
end

-- Most Residue cards that stay after a hand.
function Board.residue_cap()
    return math.max(0, Board.size() - Board.play_limit())
end

-- A blind is being played (the board and its slots are shown).
function Board.in_round()
    return Board.area() ~= nil and G.GAME ~= nil and G.GAME.facing_blind and true or false
end

-- Card state -----------------------------------------------------------------------------------------

function Board.slot_of(card)
    if card and card.area == G.play and card.ability then return card.ability.ne_slot end
    return nil
end

function Board.is_residue(card)
    return card ~= nil and card.ability ~= nil and card.ability.ne_residue == true
end

-- True while a hand is on the board (cards that are not Residue). Replaces the game's
-- "G.play has cards" checks (patches L13a-d): Residue alone never blocks Play, consumables,
-- selling or the out-of-cards check.
function Board.busy()
    local area = G and G.play
    if not area or not area.cards then return false end
    if not Board.is_board(area) then return area.cards[1] ~= nil end
    for _, card in ipairs(area.cards) do
        if not Board.is_residue(card) then return true end
    end
    return false
end

-- Placing cards, marking Residue and the board buttons are available.
function Board.can_place()
    return Board.in_round() and G.STATE == G.STATES.SELECTING_HAND and not Board.busy()
end

-- Staged hand card (placement.lua) that is still valid, or nil.
function Board.staged_slot(card)
    local slot = Board.stage[card]
    if slot == nil then return nil end
    if card.area ~= G.hand or not card.highlighted or not Board.valid_slot(slot) then
        Board.stage[card] = nil
        Board.stage_origin[card] = nil
        return nil
    end
    return slot
end

-- Rebuilds Board.occ (slot -> card) from the cards on the board and the staged cards.
-- Cards being dragged do not occupy their slot.
function Board.refresh()
    local occ = Board.occ
    for k in pairs(occ) do occ[k] = nil end
    local area = Board.area()
    if not area then return occ end
    for _, card in ipairs(area.cards) do
        local s = card.ability and card.ability.ne_slot
        if s and occ[s] == nil then occ[s] = card end
    end
    for card in pairs(Board.stage) do
        local s = Board.staged_slot(card)
        if s and occ[s] == nil and not (card.states and card.states.drag.is) then occ[s] = card end
    end
    return occ
end

-- First free slot in quick play order (after Board.refresh), or nil.
function Board.first_free()
    for _, s in ipairs(Board.fill_order()) do
        if Board.occ[s] == nil then return s end
    end
    return nil
end

local fill_cache = { key = nil, order = nil }
function Board.fill_order()
    local cols, rows = Board.dims()
    local key = cols * 100 + rows
    if fill_cache.key ~= key then
        fill_cache.key = key
        fill_cache.order = Grid.fill_order(cols, rows)
    end
    return fill_cache.order
end

-- Slots with no card on the board (staged cards still count as free: they are the new hand).
function Board.free_slots()
    local area = Board.area()
    if not area then return 0 end
    return math.max(0, Board.size() - #area.cards)
end

function Board.card_at(c, r)
    local area = Board.area()
    if not area then return nil end
    local s = Board.index(c, r)
    for _, card in ipairs(area.cards) do
        if card.ability and card.ability.ne_slot == s then return card end
    end
    return nil
end

local function slot_order(a, b)
    return a.ability.ne_slot < b.ability.ne_slot
end

-- Residue cards (optionally only those of row r), in slot order.
function Board.residues(r)
    local out = {}
    local area = Board.area()
    if not area then return out end
    local cols = Board.dims()
    for _, card in ipairs(area.cards) do
        if Board.is_residue(card) and card.ability.ne_slot then
            local _, cr = Grid.coords(cols, card.ability.ne_slot)
            if not r or cr == r then out[#out + 1] = card end
        end
    end
    table.sort(out, slot_order)
    return out
end

function Board.row_full(r)
    local cols = Board.dims()
    for c = 1, cols do
        if not Board.card_at(c, r) then return false end
    end
    return true
end

function Board.neighbors(slot)
    local cols, rows = Board.dims()
    return Grid.neighbors(cols, rows, slot)
end

function Board.adjacent(a, b)
    local cols = Board.dims()
    return Grid.adjacent(cols, a, b)
end

-- Removes every board field from a card that left the board.
function Board.forget(card)
    if not card then return end
    if card.ability then
        card.ability.ne_slot = nil
        card.ability.ne_residue = nil
        card.ability.ne_since = nil
    end
    if card.ne_board_scale then
        card.ne_board_scale = nil
        if card.T then card.T.scale = (card.original_T and card.original_T.scale) or Grid.CARD_SCALE end
    end
    Board.unmark(card)
end

-- Layout ----------------------------------------------------------------------------------------------

Board.SMALL_SCALE = 0.85 -- config board.small_cards
local last = {} -- inputs of the cached layout

function Board.scale_setting()
    local cfg = NE.cfg().board
    return (cfg and cfg.small_cards) and Board.SMALL_SCALE or 1
end

-- Screen box the board fits in: between the joker row and the highlighted cards in hand.
function Board.layout_box(box)
    box = box or {}
    local hand, jokers = G.hand, G.jokers
    local tile_h = G.TILE_H or 11.5
    local card_w, card_h = G.CARD_W, G.CARD_H
    box.card_w = card_w * Grid.CARD_SCALE
    box.card_h = card_h * Grid.CARD_SCALE
    box.top = (jokers and (jokers.T.y + jokers.T.h) or 2.6) + 0.1
    local hand_h = hand and hand.T.h or 0.95 * card_h
    -- top of a highlighted card in the middle of the hand while selecting (CardArea:move and
    -- align_cards: the hand rises 1.9 above the screen bottom, cards sit 0.2 above its centre)
    local hand_y = tile_h - hand_h - 1.9
    local card_top = hand_y + hand_h / 2 - card_h / 2 - (G.HIGHLIGHT_H or 0.2 * card_h) - 0.2
    box.bottom = card_top + card_h * (1 - Grid.CARD_SCALE) / 2 - 0.05
    box.cx = hand and (hand.T.x + hand.T.w / 2) or (G.TILE_W or 20) / 2
    box.max_w = hand and hand.T.w or 12
    box.scale = Board.scale_setting()
    return box
end

-- Called for every card every frame: recomputes only when an input changed (no garbage).
local box_buf = {}
function Board.get_layout()
    local cols, rows = Board.dims()
    local box = Board.layout_box(box_buf)
    if last.cols ~= cols or last.rows ~= rows or last.top ~= box.top or last.bottom ~= box.bottom
        or last.cx ~= box.cx or last.max_w ~= box.max_w or last.scale ~= box.scale then
        last.cols, last.rows, last.top, last.bottom = cols, rows, box.top, box.bottom
        last.cx, last.max_w, last.scale = box.cx, box.max_w, box.scale
        Grid.layout(cols, rows, box, Board.layout)
        for _, node in ipairs(Board.slots) do
            if node.ne_place then node:ne_place() end
        end
    end
    return Board.layout
end

function Board.invalidate_layout()
    last.cols = nil
end

-- Puts a card over slot s (visual size of that row); highlighted cards are raised a little.
function Board.put(card, s)
    local L = Board.get_layout().slots[s]
    if not L then return end
    local T = card.T
    local cy = L.y + L.h / 2
    if card.highlighted then cy = cy - Board.LIFT * L.h end
    T.r = 0
    T.x = L.x + L.w / 2 - T.w / 2
    T.y = cy - T.h / 2
    T.scale = L.scale
    card.ne_board_scale = L.scale
end

-- Cards without a slot (board full): stacked at the right edge until the hand ends.
local function put_overflow(card, i)
    local layout = Board.get_layout()
    local front = layout.slots[#layout.slots]
    local T = card.T
    T.r = 0
    T.x = layout.x + layout.w + 0.3 + (i - 1) * 0.25 - T.w * 0.5 + (front and front.w / 2 or 0)
    T.y = layout.y + layout.h - (front and front.h or T.h) / 2 - T.h / 2
    T.scale = front and front.scale or Grid.CARD_SCALE
    card.ne_board_scale = T.scale
end

-- Setup -------------------------------------------------------------------------------------------------

function Board.set_limit(area, n)
    area.config.card_limit = n
    local cl = rawget(area.config, 'card_limits')
    if type(cl) == 'table' then
        cl.total_slots = (cl.base or 0) + (cl.mod or 0)
        cl.display_slots = math.max(0, cl.total_slots)
    end
end

-- Turns an area (G.play) into a board, keeping a saved size.
function Board.setup_area(area)
    if not (area and area.config) then return end
    local nb = area.config.ne_board
    if type(nb) ~= 'table' then
        nb = {}
        area.config.ne_board = nb
    end
    nb.cols = Grid.clamp_dim(nb.cols, Grid.MAX_COLS, Grid.DEFAULT_COLS)
    nb.rows = Grid.clamp_dim(nb.rows, Grid.MAX_ROWS, Grid.DEFAULT_ROWS)
    Board.set_limit(area, nb.cols * nb.rows)
    Board.invalidate_layout()
    if Board.build_slots then Board.build_slots(area) end
    bump()
end

-- Gives every card on the board its own valid slot (loaded saves, resize, direct inserts).
function Board.normalize_slots(area)
    area = area or Board.area()
    if not area then return end
    local occ = Board.occ
    for k in pairs(occ) do occ[k] = nil end
    local homeless = {}
    for _, card in ipairs(area.cards) do
        local s = card.ability and card.ability.ne_slot
        if Board.valid_slot(s) and occ[s] == nil then
            occ[s] = card
        elseif card.ability then
            card.ability.ne_slot = nil
            homeless[#homeless + 1] = card
        end
    end
    for _, card in ipairs(homeless) do
        local s = Board.first_free()
        card.ability.ne_slot = s
        if s then occ[s] = card end
    end
    bump()
end

function Board.clear_stage()
    for card in pairs(Board.stage) do Board.stage[card] = nil end
    for card in pairs(Board.stage_origin) do Board.stage_origin[card] = nil end
end

function Board.unmark(card)
    local list = Board.marked
    for i = #list, 1, -1 do
        if list[i] == card then table.remove(list, i) end
    end
end

-- Unselects every marked Residue card.
function Board.clear_marks()
    local list = Board.marked
    for i = #list, 1, -1 do
        local card = list[i]
        list[i] = nil
        if card.area == G.play and card.highlighted then card:highlight(false) end
    end
end

-- After a run starts or loads: board config for old saves, slot nodes, and the cards on it.
-- Runs are saved between hands, so every loaded board card is Residue.
function Board.after_start_run()
    local area = G.play
    if not area or not area.config then return end
    Board.setup_area(area)
    Board.clear_stage()
    Board.reset_hand_end()
    Board.round_ended = false
    for i = #Board.marked, 1, -1 do Board.marked[i] = nil end
    for _, card in ipairs(area.cards or {}) do
        if card.ability then
            card.ability.ne_residue = true
            card.ability.ne_since = card.ability.ne_since or 0
        end
        card.highlighted = false
    end
    Board.normalize_slots(area)
    area:align_cards()
    if area.hard_set_cards then area:hard_set_cards() end
end

-- Hand end: Residue & limit (patch L14) -------------------------------------------------------------------

-- Which cards leave the board after a hand: the scored cards, which are the cards of every
-- formation counted in the chain (formation/formations.lua makes them the scoring_hand).
Board.consumed_provider = Board.consumed_provider or function(context)
    return context and context.scoring_hand or {}
end

-- Extra rule for cards that stay even though they scored (Phase 7 stickers). Default: none.
Board.extra_keep = Board.extra_keep or function(card) return false end

-- Every hand gets a serial number when it is evaluated (context.after); the Residue decision
-- is made once per serial.
local hand_end = { serial = 0, consumed = {} }
local keep = { serial = nil, set = {} }

local function hand_token()
    return G.GAME and G.GAME.hands_played or 0
end

NE.Hooks.on_context('after', 'board_consumed', function(context)
    if not Board.area() then return end
    local set = hand_end.consumed
    for k in pairs(set) do set[k] = nil end
    local ok, list = pcall(Board.consumed_provider, context)
    if not ok or type(list) ~= 'table' then
        NE.log.warn_once('board_consumed', 'Board consumed provider failed: %s', tostring(list))
        list = context.scoring_hand or {}
    end
    for _, card in ipairs(list) do set[card] = true end
    hand_end.serial = hand_end.serial + 1
end)

function Board.reset_hand_end()
    hand_end.serial = hand_end.serial + 1
    for k in pairs(hand_end.consumed) do hand_end.consumed[k] = nil end
    keep.serial = nil
    for k in pairs(keep.set) do keep.set[k] = nil end
end

local function by_age(a, b)
    local sa, sb = a.ability.ne_since or 0, b.ability.ne_since or 0
    if sa ~= sb then return sa < sb end
    return (a.ability.ne_slot or 0) < (b.ability.ne_slot or 0)
end

-- Decides the Residue of the hand that just ended (once per hand).
function Board.settle_hand()
    local area = Board.area()
    if not area then return end
    if keep.serial == hand_end.serial then return end
    keep.serial = hand_end.serial
    local set = keep.set
    for k in pairs(set) do set[k] = nil end
    local consumed = hand_end.consumed

    local kept = {}
    for _, card in ipairs(area.cards) do
        local stays = not card.shattered and not card.destroyed
            and card.ability and card.ability.ne_slot ~= nil
            and not card.ability.return_to_hand
            and (not consumed[card] or Board.extra_keep(card))
        if stays then kept[#kept + 1] = card end
    end
    local cap = Board.residue_cap()
    if #kept > cap then
        table.sort(kept, by_age)
        for i = #kept - cap, 1, -1 do table.remove(kept, i) end
    end
    for _, card in ipairs(kept) do
        set[card] = true
        card.ability.ne_residue = true
        if card.highlighted then card:highlight(false) end
    end
    bump()
    Board.queue_changed('hand_end')
end

-- Patch L14 (draw_from_play_to_discard): true for cards that stay on the board.
function Board.keeps(card)
    if not Board.area() then return false end
    Board.settle_hand()
    return keep.set[card] == true
end

-- End of round: the whole board goes to the discard pile (GDD §1.1).
function Board.clear_to_discard()
    local area = Board.area()
    if not area then return end
    Board.clear_stage()
    Board.clear_marks()
    local n = #area.cards
    for i, card in ipairs(area.cards) do
        if not card.shattered and not card.destroyed then
            draw_card(area, G.discard, i * 100 / math.max(n, 1), 'down', false, card)
        end
    end
end

-- Context ne_board_changed { ne_reason = 'hand_end' | 'place' | 'swap' | 'shuffle' | 'resize' },
-- sent from the event queue so it never runs inside another calculation.
function Board.queue_changed(reason)
    if not (G.E_MANAGER and Event) then return end
    G.E_MANAGER:add_event(Event({
        trigger = 'immediate',
        func = function()
            if Board.area() then
                SMODS.calculate_context({ ne_board_changed = true, ne_reason = reason })
            end
            return true
        end,
    }))
end

-- Effects API (jokers, bosses) ---------------------------------------------------------------------------

-- Moves a board card to an empty slot.
function Board.place(card, slot)
    if not (Board.area() and card and card.area == G.play and Board.valid_slot(slot)) then return false end
    Board.refresh()
    local other = Board.occ[slot]
    if other and other ~= card then return false end
    card.ability.ne_slot = slot
    bump()
    Board.queue_changed('place')
    return true
end

-- Swaps the contents of two slots (either may be empty).
function Board.swap(a, b)
    if not (Board.area() and Board.valid_slot(a) and Board.valid_slot(b)) or a == b then return false end
    local ca, cb = nil, nil
    for _, card in ipairs(G.play.cards) do
        if card.ability.ne_slot == a then ca = card elseif card.ability.ne_slot == b then cb = card end
    end
    if not ca and not cb then return false end
    if ca then ca.ability.ne_slot = b end
    if cb then cb.ability.ne_slot = a end
    bump()
    Board.queue_changed('swap')
    return true
end

-- Randomly rearranges the Residue among the slots it occupies (seeded).
function Board.shuffle_residues(seed_key)
    local cards = Board.residues()
    if #cards < 2 then return false end
    local slots = {}
    for i, card in ipairs(cards) do slots[i] = card.ability.ne_slot end
    -- the game's pseudoshuffle only takes a list of cards (it sorts them by sort_id first),
    -- so the cards are shuffled and then given the slots in order
    pseudoshuffle(cards, pseudoseed(seed_key or 'ne_board_shuffle'))
    for i, card in ipairs(cards) do card.ability.ne_slot = slots[i] end
    bump()
    Board.queue_changed('shuffle')
    return true
end

-- Changes the board size. Cards keep their column and their distance from the Front row;
-- cards outside the new board move to free slots, or to the discard pile if none is left.
function Board.resize(cols, rows)
    local area = Board.area()
    if not area then return false end
    cols = Grid.clamp_dim(cols, Grid.MAX_COLS, Grid.DEFAULT_COLS)
    rows = Grid.clamp_dim(rows, Grid.MAX_ROWS, Grid.DEFAULT_ROWS)
    local nb = area.config.ne_board
    local oc, orows = nb.cols, nb.rows
    if oc == cols and orows == rows then return true end
    Board.clear_stage()

    local moved = {}
    for _, card in ipairs(area.cards) do
        local s = card.ability.ne_slot
        if s then
            local c, r = Grid.coords(oc, s)
            local nr = r + (rows - orows)
            if c <= cols and nr >= 1 and nr <= rows then
                card.ability.ne_slot = Grid.index(cols, c, nr)
            else
                card.ability.ne_slot = nil
                moved[#moved + 1] = card
            end
        else
            moved[#moved + 1] = card
        end
    end
    nb.cols, nb.rows = cols, rows
    Board.set_limit(area, cols * rows)
    Board.invalidate_layout()
    if Board.build_slots then Board.build_slots(area) end

    Board.refresh()
    local n = #moved
    for i, card in ipairs(moved) do
        local s = Board.first_free()
        if s then
            card.ability.ne_slot = s
            Board.occ[s] = card
        else
            draw_card(area, G.discard, i * 100 / n, 'down', false, card)
        end
    end
    bump()
    Board.queue_changed('resize')
    return true
end

-- CardArea wraps ------------------------------------------------------------------------------------------

local emplace_ref = CardArea.emplace
function CardArea:emplace(card, location, stay_flipped)
    if card and Board.is_board(self) then
        -- read the reservation first: the card has already left G.hand, so Board.refresh
        -- would drop it as stale
        local slot = Board.stage[card]
        Board.stage[card] = nil
        Board.stage_origin[card] = nil
        Board.refresh()
        if not (Board.valid_slot(slot) and Board.occ[slot] == nil) then
            slot = Board.first_free()
        end
        if card.ability then
            card.ability.ne_slot = slot
            card.ability.ne_residue = nil
            card.ability.ne_since = hand_token()
        end
        bump()
    elseif card and card.ability and card.ability.ne_slot and Board.area() then
        -- leaving the board
        Board.forget(card)
    end
    return emplace_ref(self, card, location, stay_flipped)
end

-- A card on the board can be passed to another area's remove_card (Residue in a Discard goes
-- through G.hand's discard code): remove it from the board instead.
local remove_card_ref = CardArea.remove_card
function CardArea:remove_card(card, discarded_only)
    if card and self ~= G.play and card.area == G.play and G.play and Board.is_board(G.play) then
        return G.play:remove_card(card, discarded_only)
    end
    local ret = remove_card_ref(self, card, discarded_only)
    if Board.is_board(self) then
        if ret then Board.unmark(ret) end
        bump()
    end
    return ret
end

local function by_slot(a, b)
    local sa = a.ability and a.ability.ne_slot or 1e9
    local sb = b.ability and b.ability.ne_slot or 1e9
    if sa ~= sb then return sa < sb end
    return (a.sort_id or 0) < (b.sort_id or 0)
end

function Board.align_area(area)
    if (G.view_deck and G.view_deck[1] and G.view_deck[1].cards) then return end
    table.sort(area.cards, by_slot)
    local overflow = 0
    for k, card in ipairs(area.cards) do
        card.rank = k
        if not card.states.drag.is then
            local s = card.ability and card.ability.ne_slot
            if s and Board.valid_slot(s) then
                Board.put(card, s)
            else
                overflow = overflow + 1
                put_overflow(card, overflow)
            end
        end
    end
    if Board.update_slots then Board.update_slots() end
end

local align_ref = CardArea.align_cards
function CardArea:align_cards()
    if Board.is_board(self) then return Board.align_area(self) end
    if self == G.hand and Board.align_hand then return Board.align_hand(self, align_ref) end
    return align_ref(self)
end

-- Draw: slots, then the board cards and the staged cards back to front; the hovered card last
-- so it is never hidden by the row in front of it.
local draw_list = {}
local function by_draw(a, b)
    local sa = a.ability.ne_slot or Board.stage[a] or 1e9
    local sb = b.ability.ne_slot or Board.stage[b] or 1e9
    if sa ~= sb then return sa < sb end
    return (a.sort_id or 0) < (b.sort_id or 0)
end
local DRAW_LAYERS = { 'shadow', 'card' }

function Board.draw_area(area)
    if not area.states.visible then return end
    if G.VIEWING_DECK then return end
    area:draw_boundingrect()
    add_to_drawhash(area)

    if Board.in_round() then
        for _, node in ipairs(Board.slots) do node:draw() end
    end

    local n = 0
    for _, card in ipairs(area.cards) do
        n = n + 1
        draw_list[n] = card
    end
    for card in pairs(Board.stage) do
        if Board.staged_slot(card) then
            n = n + 1
            draw_list[n] = card
        end
    end
    for i = n + 1, #draw_list do draw_list[i] = nil end
    table.sort(draw_list, by_draw)
    local C = G.CONTROLLER
    local hovered = C.hovering and C.hovering.target
    for i = 1, n do
        if draw_list[i] == hovered and i < n then
            table.remove(draw_list, i)
            draw_list[n] = hovered
            break
        end
    end

    local dragging = C.dragging and C.dragging.target
    local focused = C.focused and C.focused.target
    local layers = (area.ARGS and area.ARGS.draw_layers) or area.config.draw_layers or DRAW_LAYERS
    for _, layer in ipairs(layers) do
        for i = 1, n do
            local card = draw_list[i]
            if card ~= dragging and (card ~= focused or card.area == G.hand) then
                card:draw(layer)
            end
        end
    end
    for i = 1, n do draw_list[i] = nil end
end

local draw_ref = CardArea.draw
function CardArea:draw()
    if Board.is_board(self) then return Board.draw_area(self) end
    if self == G.hand and Board.hide_staged then
        local hidden = Board.hide_staged(true)
        draw_ref(self)
        if hidden then Board.hide_staged(false) end
        return
    end
    return draw_ref(self)
end

-- Cards drawn smaller than their box (board cards, staged cards): collide with the drawn size,
-- so a card never catches the cursor above its picture or over the card in front of it.
-- Cards collide with their collision transform CT, which Card:init sets to the visual
-- transform VT (not T): that box is shrunk around its centre for the duration of the check.
local collides_ref = Card.collides_with_point
function Card:collides_with_point(point)
    local k = self.ne_board_scale
    if not k then return collides_ref(self, point) end
    local T = self.CT or self.T
    local x, y, w, h = T.x, T.y, T.w, T.h
    T.x, T.y, T.w, T.h = x + w * (1 - k) / 2, y + h * (1 - k) / 2, w * k, h * k
    local ok, res = pcall(collides_ref, self, point)
    T.x, T.y, T.w, T.h = x, y, w, h
    if not ok then error(res) end
    return res
end

-- Game wraps -----------------------------------------------------------------------------------------------

-- Before a saved run is loaded into it (Steamodded calls this for every mod in Game:start_run).
function NE.mod.custom_card_areas(game)
    if game and game.play then Board.setup_area(game.play) end
end

local start_run_ref = Game.start_run
function Game:start_run(args)
    local ret = start_run_ref(self, args)
    local ok, err = pcall(Board.after_start_run)
    if not ok then NE.log.error('Board setup after start_run failed: %s', tostring(err)) end
    return ret
end

-- End of round: vanilla sends the hand to the discard pile here; the board goes with it.
local draw_hand_to_discard_ref = G.FUNCS.draw_from_hand_to_discard
G.FUNCS.draw_from_hand_to_discard = function(e)
    local ret = draw_hand_to_discard_ref(e)
    Board.clear_to_discard()
    return ret
end

-- Out of cards: the game ends the round when hand, deck and G.play are all empty. Residue
-- alone cannot be played, so a round with only Residue left must end too (else it could lock
-- when the last hand cards are destroyed and no discard is left). end_round() is called at most
-- once per round: the game's own check runs every frame and would queue it again and again.
Board.round_ended = false

local end_round_ref = end_round
function end_round(...)
    Board.round_ended = true
    return end_round_ref(...)
end

NE.Hooks.on_context('setting_blind', 'board_round_start', function()
    Board.round_ended = false
end)

local update_selecting_hand_ref = Game.update_selecting_hand
function Game:update_selecting_hand(dt)
    local ret = update_selecting_hand_ref(self, dt)
    if G.STATE_COMPLETE and not Board.round_ended and G.STATE == G.STATES.SELECTING_HAND
        and G.hand and G.deck and #G.hand.cards < 1 and #G.deck.cards < 1
        and Board.area() and G.play.cards[1] and not Board.busy() then
        end_round()
    end
    return ret
end
