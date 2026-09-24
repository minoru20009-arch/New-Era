-- Board slots and controller support (GDD §1.2 step 6).
--
-- Every slot is a small node on the board. An empty slot can be hovered, clicked and focused
-- with the D-pad like any button, so mouse, touch and controller share one path:
--   * click / A on an empty slot   stages the leftmost highlighted hand card there
--   * click / A on a Residue card  selects it for Discard
--   * LB                           moves the focus between the hand and the board
--   * B on the board               moves the focus back to the hand
-- Slots are tinted by row effect: Front blue (chips), Back red (mult), Middle neutral.

local Board = NE.Board

local Slot = Moveable:extend()
Board.Slot = Slot

function Slot:init(index)
    Moveable.init(self, 0, 0, 1, 1)
    self.ne_board_slot = index
    self.states.collide.can = true
    self.states.drag.can = false
    self.states.hover.can = false
    self.states.click.can = true
    self.states.release_on.can = true
    self.config = self.config or {}
    self:ne_place()
end

-- Moves the node onto its slot rectangle (after a layout change).
function Slot:ne_place()
    local L = Board.layout.slots[self.ne_board_slot]
    if not L then return end
    self:hard_set_T(L.x, L.y, L.w, L.h)
end

function Slot:click()
    Board.click_slot(self.ne_board_slot)
end

function Slot:draw()
    if not self.states.visible then return end
    self:draw_boundingrect()
    add_to_drawhash(self)
    local kind = Board.row_kind(self.ne_board_slot)
    local col = (kind == 'front' and G.C.CHIPS) or (kind == 'back' and G.C.MULT) or G.C.WHITE
    local hot = self.states.hover.is or self.states.focus.is
    local ts = G.TILESIZE
    prep_draw(self, 1)
    love.graphics.scale(1 / ts)
    local w, h = self.VT.w * ts, self.VT.h * ts
    local r = 0.1 * math.min(w, h)
    love.graphics.setColor(col[1], col[2], col[3], hot and 0.32 or 0.12)
    love.graphics.rectangle('fill', 0, 0, w, h, r, r)
    love.graphics.setLineWidth(hot and 2 or 1)
    love.graphics.setColor(col[1], col[2], col[3], hot and 0.9 or 0.3)
    love.graphics.rectangle('line', 0, 0, w, h, r, r)
    love.graphics.pop()
end

-- Recreates the slot nodes for the current board size.
function Board.build_slots(area)
    for i = #Board.slots, 1, -1 do
        local node = Board.slots[i]
        Board.slots[i] = nil
        if node and not node.REMOVED then node:remove() end
    end
    if not Board.is_board(area) then return end
    Board.get_layout()
    for i = 1, Board.size() do Board.slots[i] = Slot(i) end
end

-- Runs every frame from the board's align: empty slots accept the cursor while placing.
function Board.update_slots()
    local visible = Board.in_round()
    local active = visible and Board.can_place()
    Board.refresh()
    for i, node in ipairs(Board.slots) do
        local free = active and Board.occ[i] == nil
        node.states.visible = visible
        node.states.collide.can = visible
        node.states.hover.can = free
        node.config.force_focus = free or nil
    end
end

-- Controller ------------------------------------------------------------------------------------------------

function Board.is_board_node(node)
    if not node then return false end
    if node.ne_board_slot then return true end
    if node.area and node.area == G.play and Board.area() then return true end
    return node.area == G.hand and Board.staged_slot(node) ~= nil
end

-- Focus the first empty slot (quick play order), or the first board card.
function Board.focus_board(C)
    Board.refresh()
    for _, s in ipairs(Board.fill_order()) do
        if Board.occ[s] == nil and Board.slots[s] then
            C:snap_to({ node = Board.slots[s] })
            return true
        end
    end
    local area = Board.area()
    if area and area.cards[1] then
        C:snap_to({ node = area.cards[1] })
        return true
    end
    return false
end

function Board.focus_hand(C)
    local fallback
    for _, card in ipairs(G.hand.cards) do
        fallback = fallback or card
        if not Board.staged_slot(card) then
            C:snap_to({ node = card })
            return true
        end
    end
    if fallback then
        C:snap_to({ node = fallback })
        return true
    end
    return false
end

-- Returns true when the button was used by the board.
function Board.controller_button(C, button)
    if not Board.can_place() or G.OVERLAY_MENU or G.SETTINGS.paused then return false end
    if C.locks.frame or C.locked then return false end
    local focused = C.focused and C.focused.target
    if button == 'leftshoulder' then
        local reg = C.button_registry and C.button_registry.leftshoulder
        if reg and reg[1] then return false end -- a focused card's own button (sell, use)
        if Board.is_board_node(focused) then return Board.focus_hand(C) end
        return Board.focus_board(C)
    elseif button == 'b' then
        if focused and focused.area ~= G.hand and Board.is_board_node(focused) then
            return Board.focus_hand(C)
        end
    end
    return false
end

local button_press_ref = Controller.button_press_update
function Controller:button_press_update(button, dt)
    if (button == 'leftshoulder' or button == 'b') and Board.controller_button(self, button) then
        return
    end
    return button_press_ref(self, button, dt)
end
