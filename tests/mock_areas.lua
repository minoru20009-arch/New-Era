-- Stand-ins for the game's object classes (Object, Node, Moveable, CardArea, Card, Controller),
-- draw_card and the hand functions the board wraps. Behaviour follows Balatro 1.0.1o with
-- Steamodded's patches (checked against a simulated Lovely dump), reduced to what the board
-- relies on: area card lists, highlighting, emplace/remove, event-driven card moves, and the
-- play / discard / end-of-round flow around the patched lines.

local A = {}

function A.install(M)
    -- Class model of the game's engine/object.lua ------------------------------------------------
    Object = {}
    Object.__index = Object
    function Object:init() end
    function Object:extend()
        local cls = {}
        for k, v in pairs(self) do
            if type(k) == 'string' and k:find('__') == 1 then cls[k] = v end
        end
        cls.__index = cls
        cls.super = self
        setmetatable(cls, self)
        return cls
    end
    function Object:is(T)
        local mt = getmetatable(self)
        while mt do
            if mt == T then return true end
            mt = getmetatable(mt)
        end
        return false
    end
    function Object:__call(...)
        local obj = setmetatable({}, self)
        obj:init(...)
        return obj
    end
    M.new_object = function()
        local Plain = Object:extend()
        return Plain()
    end

    -- Node / Moveable ---------------------------------------------------------------------------
    Node = Object:extend()
    function Node:init(args)
        args = args or {}
        local T = args.T or {}
        self.T = {
            x = T.x or T[1] or 0, y = T.y or T[2] or 0, w = T.w or T[3] or 1, h = T.h or T[4] or 1,
            r = T.r or T[5] or 0, scale = T.scale or T[6] or 1,
        }
        self.config = self.config or {}
        self.children = self.children or {}
        self.states = {
            visible = true,
            collide = { can = false, is = false },
            focus = { can = false, is = false },
            hover = { can = true, is = false },
            click = { can = true, is = false },
            drag = { can = true, is = false },
            release_on = { can = true, is = false },
        }
        self.container = args.container or G.ROOM
    end
    function Node:draw_boundingrect() end
    function Node:collides_with_point(p)
        local T = self.T
        return p.x >= T.x and p.y >= T.y and p.x <= T.x + T.w and p.y <= T.y + T.h
    end
    function Node:stop_drag() end
    function Node:click() end
    function Node:release() end
    function Node:remove() self.REMOVED = true end

    A.moveables = {}
    Moveable = Node:extend()
    function Moveable:init(X, Y, W, H)
        local args = (type(X) == 'table') and X or { T = { X or 0, Y or 0, W or 0, H or 0 } }
        Node.init(self, args)
        self.VT = { x = self.T.x, y = self.T.y, w = self.T.w, h = self.T.h, r = self.T.r, scale = self.T.scale }
        self.velocity = { x = 0, y = 0, r = 0, scale = 0 }
        A.moveables[#A.moveables + 1] = self
    end
    function Moveable:hard_set_T(X, Y, W, H)
        self.T.x, self.T.y, self.T.w, self.T.h = X, Y, W, H
        self.VT.x, self.VT.y, self.VT.w, self.VT.h = X, Y, W, H
        self.VT.r, self.VT.scale = self.T.r, self.T.scale
    end
    function Moveable:juice_up() self.juiced = (self.juiced or 0) + 1 end
    function Moveable:remove() self.REMOVED = true end

    -- CardArea (vanilla + Steamodded's remove_card change) ------------------------------------
    -- (hoisted so the mocks themselves do not allocate in the garbage test)
    A.by_x = function(a, b) return a.T.x + a.T.w / 2 < b.T.x + b.T.w / 2 end
    A.LAYERS = { 'shadow', 'card' }
    CardArea = Moveable:extend()
    function CardArea:init(X, Y, W, H, config)
        Moveable.init(self, X, Y, W, H)
        self.states.drag.can = false
        self.states.hover.can = false
        self.states.click.can = false
        self.config = config or {}
        self.card_w = G.CARD_W
        self.cards = {}
        self.highlighted = {}
        self.config.highlighted_limit = self.config.highlight_limit or 5
        self.config.card_limit = self.config.card_limit or 52
        self.config.type = self.config.type or 'deck'
    end
    function CardArea:emplace(card, location, stay_flipped)
        if location == 'front' or self.config.type == 'deck' then
            table.insert(self.cards, 1, card)
        else
            self.cards[#self.cards + 1] = card
        end
        if card.facing == 'back' and self.config.type ~= 'discard' and self.config.type ~= 'deck' and not stay_flipped then
            card.facing = 'front'
        end
        card:set_card_area(self)
        self:set_ranks()
        self:align_cards()
    end
    function CardArea:remove_card(card, discarded_only)
        if not self.cards then return end
        if self.config.type == 'discard' or self.config.type == 'deck' then
            card = card or self.cards[#self.cards]
        else
            card = card or self.cards[1]
        end
        for i = #self.cards, 1, -1 do
            if self.cards[i] == card then
                card:remove_from_area()
                table.remove(self.cards, i)
                if card.highlighted then self:remove_from_highlighted(card, true) end
                break
            end
        end
        self:set_ranks()
        return card
    end
    function CardArea:draw_card_from(area)
        local card = area:remove_card(nil)
        if card then self:emplace(card) end
        return card
    end
    function CardArea:can_highlight(card)
        local t = self.config.type
        return t == 'hand' or t == 'joker' or t == 'consumeable'
    end
    function CardArea:add_to_highlighted(card, silent)
        if #self.highlighted >= self.config.highlighted_limit then
            card:highlight(false)
        else
            self.highlighted[#self.highlighted + 1] = card
            card:highlight(true)
        end
        if self == G.hand and G.STATE == G.STATES.SELECTING_HAND then self:parse_highlighted() end
    end
    function CardArea:remove_from_highlighted(card, force)
        if (not force) and card and card.ability.forced_selection and self == G.hand then return end
        for i = #self.highlighted, 1, -1 do
            if self.highlighted[i] == card then
                table.remove(self.highlighted, i)
                break
            end
        end
        card:highlight(false)
        if self == G.hand and G.STATE == G.STATES.SELECTING_HAND then self:parse_highlighted() end
    end
    function CardArea:unhighlight_all()
        for i = #self.highlighted, 1, -1 do
            if not (self.highlighted[i].ability.forced_selection and self == G.hand) then
                self.highlighted[i]:highlight(false)
                table.remove(self.highlighted, i)
            end
        end
        if self == G.hand and G.STATE == G.STATES.SELECTING_HAND then self:parse_highlighted() end
    end
    function CardArea:parse_highlighted()
        M.parsed = {}
        for i, c in ipairs(self.highlighted) do M.parsed[i] = c end
        G.FUNCS.get_poker_hand_info(self.highlighted)
    end
    function CardArea:set_ranks()
        for k, card in ipairs(self.cards) do
            card.rank = k
            card.states.collide.can = true
            card.states.drag.can = not (self.config.type == 'play' or self.config.type == 'deck')
        end
    end
    -- hand: fan by position then sort by x (a dragged card keeps its x and moves in the order)
    function CardArea:align_cards()
        local n = #self.cards
        if self.config.type == 'hand' or self.config.type == 'play' then
            for k, card in ipairs(self.cards) do
                if not card.states.drag.is then
                    card.T.r = 0
                    card.T.x = self.T.x + (self.T.w - self.card_w) * ((k - 1) / math.max(n - 1, 1))
                    card.T.y = self.T.y + self.T.h / 2 - card.T.h / 2 - (card.highlighted and G.HIGHLIGHT_H or 0)
                end
            end
            table.sort(self.cards, A.by_x)
        end
        for k, card in ipairs(self.cards) do card.rank = k end
    end
    function CardArea:draw()
        if not self.states.visible then return end
        for _, layer in ipairs(A.LAYERS) do
            for i = 1, #self.cards do
                local card = self.cards[i]
                if card ~= G.CONTROLLER.focused.target or self == G.hand then
                    if G.CONTROLLER.dragging.target ~= card then card:draw(layer) end
                end
            end
        end
    end
    function CardArea:hard_set_cards()
        for _, card in ipairs(self.cards) do card:hard_set_T(card.T.x, card.T.y, card.T.w, card.T.h) end
    end
    function CardArea:save()
        local t = { cards = {}, config = self.config }
        for i, card in ipairs(self.cards) do t.cards[i] = card:save() end
        return t
    end
    function CardArea:load(t)
        self.cards = {}
        self.children = {}
        self.config = t.config
        for i, ct in ipairs(t.cards) do
            local card = Card(0, 0, G.CARD_W, G.CARD_H)
            card:load(ct)
            self.cards[i] = card
            card:set_card_area(self)
        end
        self:set_ranks()
        self:align_cards()
        self:hard_set_cards()
    end

    -- Card --------------------------------------------------------------------------------------
    A.sort_id = 0
    Card = Moveable:extend()
    function Card:init(X, Y, W, H, proto)
        Moveable.init(self, X, Y, W or G.CARD_W, H or G.CARD_H)
        A.sort_id = A.sort_id + 1
        self.sort_id = A.sort_id
        self.T.scale = 0.95
        self.VT.scale = 0.95
        self.original_T = { scale = 0.95 }
        self.facing = 'front'
        self.playing_card = true
        proto = proto or {}
        self.base = { id = proto.id or 2, nominal = proto.nominal or 2, suit = proto.suit or 'Spades' }
        self.ability = { bonus = proto.bonus or 0, perma_bonus = 0, mult = proto.mult or 0, effect = proto.effect }
    end
    function Card:highlight(is_highlighted) self.highlighted = is_highlighted end
    function Card:click()
        if self.area and self.area:can_highlight(self) then
            if self.area == G.hand and G.STATE == G.STATES.HAND_PLAYED then return end
            if self.highlighted ~= true then
                self.area:add_to_highlighted(self)
            else
                self.area:remove_from_highlighted(self)
            end
        end
    end
    function Card:set_card_area(area)
        self.area = area
        self.parent = area
    end
    function Card:remove_from_area()
        self.area = nil
        self.parent = nil
    end
    -- M.count_draws: count only (no allocation, for the garbage test)
    function Card:draw(layer)
        if not self.states.visible then return end
        if M.count_draws then
            M.draw_count = (M.draw_count or 0) + 1
        else
            M.draw_log[#M.draw_log + 1] = { card = self, layer = layer }
        end
        add_to_drawhash(self)
    end
    -- Stone cards replace the rank's chips (Steamodded replace_base_card)
    function Card:get_chip_bonus()
        if self.ability.effect == 'Stone Card' then return self.ability.bonus + (self.ability.perma_bonus or 0) end
        return self.base.nominal + self.ability.bonus + (self.ability.perma_bonus or 0)
    end
    function Card:get_chip_mult() return self.ability.mult end
    function Card:start_dissolve() self.destroyed = true end
    function Card:save()
        return { base = self.base, ability = self.ability, sort_id = self.sort_id, facing = self.facing }
    end
    function Card:load(t)
        self.base = t.base
        self.ability = t.ability
        self.sort_id = t.sort_id
        self.facing = t.facing
    end

    -- Controller ----------------------------------------------------------------------------------
    Controller = Object:extend()
    function Controller:init()
        self.dragging = {}
        self.focused = {}
        self.hovering = {}
        self.cursor_hover = {}
        self.cursor_down = { T = { x = 0, y = 0 } }
        self.cursor_up = { T = { x = 0, y = 0 } }
        self.locks = {}
        self.button_registry = {}
        self.interrupt = {}
    end
    function Controller:button_press_update(button, dt)
        M.vanilla_buttons[#M.vanilla_buttons + 1] = button
    end
    function Controller:snap_to(args) self.snapped = args.node end

    -- Helpers used by the board --------------------------------------------------------------------
    M.draw_log = {}
    M.drawhash = {}
    M.vanilla_buttons = {}
    add_to_drawhash = function(obj) M.drawhash[#M.drawhash + 1] = obj end
    prep_draw = function() end
    pseudoseed = function(key) return 0.5 end
    pseudoshuffle = function(list, seed) -- deterministic stand-in: reverse
        local n = #list
        for i = 1, math.floor(n / 2) do list[i], list[n - i + 1] = list[n - i + 1], list[i] end
    end

    draw_card = function(from, to, percent, dir, sort, card, delay, mute, stay_flipped)
        G.E_MANAGER:add_event(Event({
            func = function()
                if card then
                    if from then card = from:remove_card(card) end
                    if card.ability.return_to_hand and from == G.play then
                        to = G.hand
                        card.ability.return_to_hand = nil
                    end
                    to:emplace(card, nil, stay_flipped)
                else
                    to:draw_card_from(from)
                end
                return true
            end,
        }))
    end

    -- Vanilla button checks (functions/button_callbacks.lua, dump)
    G.FUNCS.can_play = function(e)
        if #G.hand.highlighted <= 0 or (G.GAME.blind and G.GAME.blind.block_play) or #G.hand.highlighted > math.max(G.GAME.starting_params.play_limit, 1) then
            e.config.colour = G.C.UI.BACKGROUND_INACTIVE
            e.config.button = nil
        else
            e.config.colour = G.C.BLUE
            e.config.button = 'play_cards_from_highlighted'
        end
    end
    G.FUNCS.can_discard = function(e)
        if G.GAME.current_round.discards_left <= 0 or #G.hand.highlighted <= 0 or #G.hand.highlighted > math.max(G.GAME.starting_params.discard_limit, 0) then
            e.config.colour = G.C.UI.BACKGROUND_INACTIVE
            e.config.button = nil
        else
            e.config.colour = G.C.RED
            e.config.button = 'discard_cards_from_highlighted'
        end
    end
    -- Poker hand evaluation: records what was evaluated; the scored cards come from
    -- M.score_cards(cards) (default: none).
    G.FUNCS.get_poker_hand_info = function(cards)
        M.poker_eval = {}
        for i, c in ipairs(cards) do M.poker_eval[i] = c end
        return 'High Card', 'High Card', {}, {}, 'High Card'
    end
    -- end_round (functions/state_events.lua): counts calls
    end_round = function() M.end_round_calls = (M.end_round_calls or 0) + 1 end
    -- Game:update_selecting_hand (game.lua): the out-of-cards checks around the hand selection
    function Game:update_selecting_hand(dt)
        if #G.hand.cards < 1 and #G.deck.cards < 1 and #G.play.cards < 1 then
            end_round()
        end
        if not G.STATE_COMPLETE then
            G.STATE_COMPLETE = true
            if #G.hand.cards < 1 and #G.deck.cards < 1 then end_round() end
        end
    end
    G.FUNCS.evaluate_play = function()
        M.evaluated = {}
        for i, c in ipairs(G.play.cards) do M.evaluated[i] = c end
        local scoring = M.score_cards and M.score_cards(G.play.cards) or {}
        SMODS.calculate_context({ full_hand = G.play.cards, scoring_hand = scoring, after = true })
    end
end

-- Test sources for the lines patched by lovely/30_board.toml (the functions around them are
-- reduced to the steps the board depends on).
A.patch_sources = {
    ['functions/state_events.lua'] = [[
G.FUNCS.play_cards_from_highlighted = function(e)
    if G.play and G.play.cards[1] then return end
    G.E_MANAGER:add_event(Event({ func = function() G.STATE = G.STATES.HAND_PLAYED; return true end }))
    table.sort(G.hand.highlighted, function(a, b) return a.T.x < b.T.x end)
    for i = 1, #G.hand.highlighted do
        draw_card(G.hand, G.play, i * 100 / #G.hand.highlighted, 'up', nil, G.hand.highlighted[i])
    end
    G.E_MANAGER:add_event(Event({ func = function() G.FUNCS.evaluate_play(); return true end }))
    G.E_MANAGER:add_event(Event({ func = function()
        G.FUNCS.draw_from_play_to_discard()
        G.GAME.hands_played = G.GAME.hands_played + 1
        return true
    end }))
    G.E_MANAGER:add_event(Event({ func = function() G.STATE = G.STATES.SELECTING_HAND; return true end }))
end

G.FUNCS.draw_from_play_to_discard = function(e)
    local play_count = #G.play.cards
    local it = 1
    for k, v in ipairs(G.play.cards) do
        if (not v.shattered) and (not v.destroyed) then
            draw_card(G.play, G.discard, it * 100 / play_count, 'down', false, v)
            it = it + 1
        end
    end
end

G.FUNCS.discard_cards_from_highlighted = function(e, hook)
    local highlighted_count = math.min(#G.hand.highlighted, G.discard.config.card_limit - #G.play.cards)
    if highlighted_count > 0 then
        table.sort(G.hand.highlighted, function(a, b) return a.T.x < b.T.x end)
        SMODS.calculate_context({ pre_discard = true, full_hand = G.hand.highlighted, hook = hook })
        for i = 1, highlighted_count do
            SMODS.calculate_context({ discard = true, other_card = G.hand.highlighted[i], full_hand = G.hand.highlighted })
            G.hand.highlighted[i].ability.discarded = true
            draw_card(G.hand, G.discard, i * 100 / highlighted_count, 'down', false, G.hand.highlighted[i])
        end
        if not hook then
            ease_discard(-1)
            G.GAME.current_round.discards_used = G.GAME.current_round.discards_used + 1
            G.STATE = G.STATES.DRAW_TO_HAND
        end
    end
end

G.FUNCS.draw_from_hand_to_discard = function(e)
    local hand_count = #G.hand.cards
    for i = 1, hand_count do
        draw_card(G.hand, G.discard, i * 100 / hand_count, 'down', nil, nil, 0.07)
    end
end
]],
    ['card.lua'] = [[
function Card:can_use_consumeable(any_state, skip_check)
    if not skip_check and ((G.play and #G.play.cards > 0) or
        (G.CONTROLLER.locked) or
        (G.GAME.STOP_USE and G.GAME.STOP_USE > 0))
        then  return false end
    return true
end

function Card:can_sell_card(context)
    if (G.play and #G.play.cards > 0) or
        (G.CONTROLLER.locked) or
        (G.GAME.STOP_USE and G.GAME.STOP_USE > 0)
        then return false end
    return true
end
]],
    ['engine/controller.lua'] = [[
function Controller:queue_R_cursor_press(x, y)
    if not G.SETTINGS.paused and G.hand and G.hand.highlighted[1] then
        if (G.play and #G.play.cards > 0) or
        (self.locked) or
        (G.GAME.STOP_USE and G.GAME.STOP_USE > 0) then return end
        G.hand:unhighlight_all()
    end
end
]],
}

-- Creates the run's card areas at the positions set_screen_positions gives them.
function A.create_areas()
    local CW, CH = G.CARD_W, G.CARD_H
    local hand_w, hand_h = 6 * CW, 0.95 * CH
    local hx, hy = G.TILE_W - hand_w - 2.85, G.TILE_H - hand_h
    G.hand = CardArea(hx, hy, hand_w, hand_h, { card_limit = 8, type = 'hand' })
    G.play = CardArea(hx + (hand_w - 5.3 * CW) / 2, hy - 3.6, 5.3 * CW, hand_h, { card_limit = 5, type = 'play' })
    G.jokers = CardArea(hx - 0.1, 0, 4.9 * CW, hand_h, { card_limit = 5, type = 'joker' })
    G.deck = CardArea(G.TILE_W - 1.1 * CW - 0.5, G.TILE_H - hand_h, 1.1 * CW, hand_h, { card_limit = 52, type = 'deck' })
    G.discard = CardArea(15, 4.2, CW, CH, { card_limit = 500, type = 'discard' })
end

return A
