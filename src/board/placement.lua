-- Placing cards on the board (GDD §1.2) and the board rules that change hand scoring.
--
-- Staging: a card placed on an empty slot before Play stays in G.hand, highlighted, with the
-- slot reserved for it (Board.stage). It is drawn on the slot (align/draw wraps), so the
-- vanilla play and discard code, jokers and consumables all see an ordinary highlighted card.
--   * drag a hand card onto an empty slot, or highlight cards and click an empty slot
--   * click a staged card (unhighlights it) or drag it off the board to return it to the hand
--   * Play: staged cards take their slot, other highlighted cards are placed automatically
--     (Middle row left to right, then Front, then Back)
-- Residue: click a Residue card to select it for Discard (same Discard action and limit as
-- hand cards).
-- Row effects (GDD §1.1), for scored board cards: Front row doubles the card's base chips,
-- Back row gives +2 Mult.

local Board = NE.Board
local Grid = Board.Grid

Board.FRONT_CHIP_FACTOR = 2 -- Front row: base chips x2
Board.BACK_MULT = 2         -- Back row: +2 Mult

local function hand_index(card)
    local cards = G.hand and G.hand.cards
    if not cards then return nil end
    for i = 1, #cards do
        if cards[i] == card then return i end
    end
    return nil
end

-- Staging ---------------------------------------------------------------------------------------------

function Board.is_staged(card)
    return Board.staged_slot(card) ~= nil
end

-- Reserves `slot` for a hand card (highlighting it if needed). A staged card can be moved to
-- another free slot.
function Board.stage_card(card, slot)
    if not Board.can_place() then return false end
    if not (card and card.area == G.hand and Board.valid_slot(slot)) then return false end
    Board.refresh()
    local other = Board.occ[slot]
    if other and other ~= card then return false end
    if not card.highlighted then
        G.hand:add_to_highlighted(card)
        if not card.highlighted then return false end -- selection limit reached
    end
    if Board.stage[card] == nil then Board.stage_origin[card] = hand_index(card) end
    Board.stage[card] = slot
    Board.bump()
    play_sound('cardSlide1')
    Board.refresh_preview()
    return true
end

-- Re-evaluates the hand preview (formation name, chips, mult) after the placement changed
-- without a change of the selection: positions matter for formations.
function Board.refresh_preview()
    if G.hand and G.STATE == G.STATES.SELECTING_HAND and G.hand.highlighted[1] then
        G.hand:parse_highlighted()
    end
end

-- Returns a staged card to the hand at `index` (default: where it came from). The card stays
-- highlighted; the Card:highlight wrap unstages cards that get unhighlighted.
function Board.unstage(card, index)
    if Board.stage[card] == nil then return end
    local origin = Board.stage_origin[card]
    Board.stage[card] = nil
    Board.stage_origin[card] = nil
    local cards = G.hand and G.hand.cards
    local cur = cards and card.area == G.hand and hand_index(card)
    local target = index or origin
    if cur and target then
        table.remove(cards, cur)
        if target > #cards + 1 then target = #cards + 1 end
        if target < 1 then target = 1 end
        table.insert(cards, target, card)
    end
    Board.bump()
end

-- Hand position for a card dropped at x (among the cards that are not staged).
function Board.hand_index_at(x, except)
    local n = 1
    for _, card in ipairs(G.hand.cards) do
        if card ~= except and not Board.stage[card] and card.T.x + card.T.w / 2 < x then n = n + 1 end
    end
    return n
end

-- Click on an empty slot: stages the leftmost highlighted card that has no slot yet.
function Board.click_slot(slot)
    if not Board.can_place() then return false end
    Board.refresh()
    if Board.occ[slot] then return false end
    for _, card in ipairs(G.hand.cards) do
        if card.highlighted and not Board.staged_slot(card) then
            return Board.stage_card(card, slot)
        end
    end
    play_sound('cancel', 0.8, 0.4)
    return false
end

-- Slot under the cursor at the end of a drag, and whether something else is on it.
function Board.drop_slot(card)
    local C = G.CONTROLLER
    local target = C and C.cursor_hover and C.cursor_hover.target
    if not target or target == card then return nil end
    if target.ne_board_slot then return target.ne_board_slot, false end
    if target.area == G.play and Board.is_board(G.play) and target.ability then
        return target.ability.ne_slot, true
    end
    local s = Board.stage[target]
    if s then return s, true end
    return nil
end

local function was_click()
    local C = G.CONTROLLER
    local d = C and C.cursor_down and C.cursor_down.T
    local u = C and C.cursor_up and C.cursor_up.T
    if not (d and u and d.x and u.x) then return true end
    local dx, dy = d.x - u.x, d.y - u.y
    local min = G.MIN_CLICK_DIST or 0.9
    return dx * dx + dy * dy < min * min
end

-- Drag & drop from the hand: onto an empty slot stages the card; a staged card dragged off
-- the board goes back into the hand where it is dropped.
local stop_drag_ref = Card.stop_drag
function Card:stop_drag()
    local ret = stop_drag_ref(self)
    if self.area == G.hand and Board.can_place() and not was_click() then
        local slot, occupied = Board.drop_slot(self)
        if slot and not occupied then
            Board.stage_card(self, slot)
        else
            if not slot and Board.stage[self] then
                Board.unstage(self, Board.hand_index_at(self.T.x + self.T.w / 2, self))
            end
            -- the hand order decides where quick play puts the other selected cards
            Board.refresh_preview()
        end
    end
    return ret
end

local highlight_ref = Card.highlight
function Card:highlight(is_highlighted)
    local ret = highlight_ref(self, is_highlighted)
    -- a card leaving the hand (Play) has no area here, so its reservation is kept for emplace
    if not is_highlighted and Board.stage[self] ~= nil and self.area == G.hand then
        Board.unstage(self)
    end
    return ret
end

-- Hand layout: staged cards leave the fan and sit on their slot.
local staged_buf = {}
function Board.align_hand(area, ref)
    if not Board.area() then return ref(area) end
    local cards = area.cards
    local n, k, w = #cards, 0, 0
    for i = 1, n do
        local card = cards[i]
        if Board.staged_slot(card) then
            k = k + 1
            staged_buf[k] = card
        else
            if card.ne_board_scale then -- back from the board
                card.ne_board_scale = nil
                card.T.scale = (card.original_T and card.original_T.scale) or Grid.CARD_SCALE
            end
            w = w + 1
            cards[w] = card
        end
    end
    if k == 0 then return ref(area) end
    for i = w + 1, n do cards[i] = nil end
    local ok, err = pcall(ref, area)
    for i = 1, k do
        cards[w + i] = staged_buf[i]
        staged_buf[i] = nil
    end
    if not ok then error(err, 0) end
    for i = w + 1, n do
        local card = cards[i]
        card.rank = i
        if not card.states.drag.is then Board.put(card, Board.stage[card]) end
    end
end

-- The hand does not draw its staged cards; the board draws them in row order.
local hidden = {}
function Board.hide_staged(hide)
    if hide then
        local k = 0
        for card in pairs(Board.stage) do
            if Board.staged_slot(card) and card.states.visible then
                k = k + 1
                hidden[k] = card
                card.states.visible = false
            end
        end
        return k > 0
    end
    for i = #hidden, 1, -1 do
        hidden[i].states.visible = true
        hidden[i] = nil
    end
end

-- Residue selection for Discard -------------------------------------------------------------------------

-- Drops marks that are no longer valid; returns the list.
function Board.valid_marks()
    local list = Board.marked
    for i = #list, 1, -1 do
        local card = list[i]
        if not (card.area == G.play and card.highlighted and Board.is_residue(card)) then
            table.remove(list, i)
        end
    end
    return list
end

function Board.toggle_mark(card)
    if not (Board.can_place() and card and card.area == G.play and Board.is_residue(card)) then
        return false
    end
    Board.valid_marks()
    if card.highlighted then
        card:highlight(false)
        Board.unmark(card)
        play_sound('cardSlide2', nil, 0.3)
    else
        if #Board.marked + #G.hand.highlighted >= Board.discard_limit() then
            card:juice_up(0.1, 0.1)
            play_sound('cancel', 0.8, 0.4)
            return false
        end
        card:highlight(true)
        Board.marked[#Board.marked + 1] = card
        play_sound('cardSlide1')
    end
    Board.bump()
    return true
end

local click_ref = Card.click
function Card:click()
    if self.area and self.area == G.play and Board.is_board(G.play) then
        if Board.can_place() then Board.toggle_mark(self) end
        return
    end
    return click_ref(self)
end

-- Marked Residue joins the hand's selected cards while the vanilla Discard code runs (so every
-- discard effect, seal and limit applies); the board card is removed from G.play by the
-- CardArea:remove_card wrap.
local discard_ref = G.FUNCS.discard_cards_from_highlighted
G.FUNCS.discard_cards_from_highlighted = function(e, hook)
    local marks = (not hook and Board.area()) and Board.valid_marks() or nil
    if not (marks and marks[1]) then return discard_ref(e, hook) end
    local hl = G.hand.highlighted
    local base = #hl
    for i, card in ipairs(marks) do hl[base + i] = card end
    local ok, err = pcall(discard_ref, e, hook)
    for i = #hl, 1, -1 do
        if hl[i].area == G.play then table.remove(hl, i) end
    end
    for i = #marks, 1, -1 do marks[i] = nil end
    Board.bump()
    if not ok then error(err, 0) end
end

local can_discard_ref = G.FUNCS.can_discard
G.FUNCS.can_discard = function(e)
    local marks = Board.marked
    local n = #marks
    if n == 0 or not Board.area() then return can_discard_ref(e) end
    local hl = G.hand.highlighted
    local base = #hl
    for i = 1, n do hl[base + i] = marks[i] end
    local ok, err = pcall(can_discard_ref, e)
    for i = base + n, base + 1, -1 do hl[i] = nil end
    if not ok then error(err, 0) end
end

-- Play needs a free slot for every selected card.
local can_play_ref = G.FUNCS.can_play
G.FUNCS.can_play = function(e)
    can_play_ref(e)
    if e.config.button and Board.area() and #G.hand.highlighted > Board.free_slots() then
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    end
end

local play_ref = G.FUNCS.play_cards_from_highlighted
G.FUNCS.play_cards_from_highlighted = function(e)
    if Board.area() and not Board.busy() then Board.clear_marks() end
    return play_ref(e)
end

-- Hand preview: the hand that Play would evaluate (Residue + selected cards).
local parse_ref = CardArea.parse_highlighted
function CardArea:parse_highlighted()
    if self ~= G.hand or not self.highlighted[1] or not Board.area() then return parse_ref(self) end
    local combined = Board.residues()
    if not combined[1] then return parse_ref(self) end
    local saved = self.highlighted
    for _, card in ipairs(saved) do combined[#combined + 1] = card end
    self.highlighted = combined
    local ok, err = pcall(parse_ref, self)
    self.highlighted = saved
    if not ok then error(err, 0) end
end

-- Row effects ------------------------------------------------------------------------------------------------

local function row_of(card)
    if card.area ~= G.play or not card.ability or card.ability.extra_enhancement then return nil end
    local s = card.ability.ne_slot
    if not (s and Board.is_board(G.play) and Board.valid_slot(s)) then return nil end
    return Board.row_kind(s)
end

local chip_bonus_ref = Card.get_chip_bonus
function Card:get_chip_bonus()
    local ret = chip_bonus_ref(self)
    if type(ret) == 'number' and row_of(self) == 'front' then
        local extra = (tonumber(self.ability.bonus) or 0) + (tonumber(self.ability.perma_bonus) or 0)
        local base = ret - extra -- the rank's chips (0 for cards without a rank)
        if base > 0 then ret = ret + base * (Board.FRONT_CHIP_FACTOR - 1) end
    end
    return ret
end

local chip_mult_ref = Card.get_chip_mult
function Card:get_chip_mult()
    local ret = chip_mult_ref(self)
    if type(ret) == 'number' and row_of(self) == 'back' then
        ret = ret + Board.BACK_MULT
    end
    return ret
end
