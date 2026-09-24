-- Stand-ins for Steamodded's poker hand system (Phase 6): SMODS.PokerHand registry with
-- take_ownership and the handlist sort of post_inject_class, the vanilla hands, SMODS.Planet,
-- Game:init_game_object filling G.GAME.hands, and exact copies of Steamodded's
-- evaluate_poker_hand and G.FUNCS.get_poker_hand_info (src/overrides.lua, 26.924.0~dev).
-- Also: playing card rank/suit rules (get_id, is_suit with flush rules), level_up_hand, and a
-- reduced evaluate_play that follows the dumped state_events.lua order.

local F = {}

-- vanilla hands with their base values (game.lua init_game_object)
F.VANILLA = {
    { 'Flush Five', 160, 16 }, { 'Flush House', 140, 14 }, { 'Five of a Kind', 120, 12 },
    { 'Straight Flush', 100, 8 }, { 'Four of a Kind', 60, 7 }, { 'Full House', 40, 4 },
    { 'Flush', 35, 4 }, { 'Straight', 30, 4 }, { 'Three of a Kind', 30, 3 }, { 'Two Pair', 20, 2 },
    { 'Pair', 10, 2 }, { 'High Card', 5, 1 },
}

function F.install(M)
    G.handlist = {}
    SMODS.PokerHands = {}
    SMODS.PokerHandParts = {}
    SMODS.PokerHandPart = { obj_buffer = {} }

    local PokerHand = { obj_buffer = G.handlist, obj_table = SMODS.PokerHands }
    local function register(def)
        def.s_mult, def.s_chips = def.mult, def.chips
        if def.visible == nil then def.visible = true end
        def.level = def.level or 1
        def.played, def.played_this_round, def.played_this_ante = 0, 0, 0
        SMODS.PokerHands[def.key] = def
        G.handlist[#G.handlist + 1] = def.key
        return def
    end
    setmetatable(PokerHand, {
        __call = function(self, def)
            for _, k in ipairs({ 'key', 'mult', 'chips', 'l_mult', 'l_chips', 'example', 'evaluate' }) do
                assert(def[k] ~= nil, 'PokerHand missing ' .. k)
            end
            def.key = 'ne_' .. def.key
            return register(def)
        end,
    })
    function PokerHand:take_ownership(key, obj, silent)
        local o = SMODS.PokerHands[key]
        if not o then return nil end
        for k, v in pairs(obj) do o[k] = v end
        o.taken_ownership = true
        return o
    end
    SMODS.PokerHand = PokerHand

    -- vanilla hands; their evaluate always matches, so a hand that was not disabled shows up
    for _, v in ipairs(F.VANILLA) do
        register({ key = v[1], chips = v[2], mult = v[3], l_chips = 10, l_mult = 1, example = {},
            evaluate = function(parts, hand) return hand[1] and { { hand[1] } } or {} end })
    end

    SMODS.Suit = { obj_buffer = { 'Spades', 'Hearts', 'Clubs', 'Diamonds' } }
    SMODS.has_enhancement = function(card, key) return card.ne_enhancement == key end

    SMODS.Planet = setmetatable({ list = {} }, {
        __call = function(self, def)
            def.key = 'c_ne_' .. def.key
            def.set = 'Planet'
            self.list[#self.list + 1] = def
            return def
        end,
    })

    -- Steamodded's Game:init_game_object override (src/overrides.lua)
    local igo_ref = Game.init_game_object
    function Game:init_game_object()
        local t = igo_ref(self)
        t.current_round.most_played_poker_hand = 'High Card'
        t.hands = {}
        for _, key in ipairs(G.handlist) do
            t.hands[key] = {}
            for k, v in pairs(SMODS.PokerHands[key]) do
                if type(v) == 'number' or type(v) == 'boolean' or k == 'example' or k == 'key' then
                    t.hands[key][k] = v
                end
            end
        end
        return t
    end

    -- Copied from Steamodded src/overrides.lua
    function evaluate_poker_hand(hand)
        local results = {}
        local parts = {}
        for _, v in ipairs(SMODS.PokerHandPart.obj_buffer) do
            parts[v] = SMODS.PokerHandParts[v].func(hand) or {}
        end
        for k, _hand in pairs(SMODS.PokerHands) do
            results[k] = _hand.evaluate(parts, hand) or {}
        end
        for _, v in ipairs(G.handlist) do
            if not results.top and results[v] then
                results.top = results[v]
                break
            end
        end
        return results
    end

    -- Copied from Steamodded src/overrides.lua (+ M.poker_eval, the cards it was given)
    function G.FUNCS.get_poker_hand_info(_cards)
        M.poker_eval = {}
        for i, c in ipairs(_cards) do M.poker_eval[i] = c end
        local poker_hands = evaluate_poker_hand(_cards)
        local scoring_hand = {}
        local text, disp_text, loc_disp_text = 'NULL', 'NULL', 'NULL'
        for _, v in ipairs(G.handlist) do
            if next(poker_hands[v]) then
                text = v
                scoring_hand = poker_hands[v][1]
                break
            end
        end
        disp_text = text
        local _hand = SMODS.PokerHands[text]
        if _hand and _hand.modify_display_text and type(_hand.modify_display_text) == 'function' then
            disp_text = _hand:modify_display_text(_cards, scoring_hand) or disp_text
        end
        local flags = SMODS.calculate_context({ evaluate_poker_hand = true, full_hand = _cards, scoring_hand = scoring_hand, scoring_name =
        text, poker_hands = poker_hands, display_name = disp_text })
        text = flags.replace_scoring_name or text
        disp_text = flags.replace_display_name or flags.replace_scoring_name or disp_text
        poker_hands = flags.replace_poker_hands or poker_hands
        loc_disp_text = localize(disp_text, 'poker_hands')
        loc_disp_text = loc_disp_text == 'ERROR' and disp_text or loc_disp_text
        return text, loc_disp_text, poker_hands, scoring_hand, disp_text
    end

    -- vanilla (patched) UI row, reduced: a row node, or nil for hidden hands
    function create_UIBox_current_hand_row(handname, simple, in_collection)
        local visible = in_collection or (G.GAME.hands[handname] and G.GAME.hands[handname].visible)
        if not visible then return nil end
        return { n = G.UIT.R, config = { id = 'row_' .. handname }, nodes = {
            { n = G.UIT.C, config = { id = 'level' } },
            { n = G.UIT.C, config = { id = 'values' } },
        } }
    end

    -- level_up_hand (functions/common_events.lua), without the UI
    function level_up_hand(card, hand, instant, amount)
        amount = amount or 1
        local h = G.GAME.hands[hand]
        h.level = math.max(0, h.level + amount)
        h.mult = math.max(h.s_mult + h.l_mult * (h.level - 1), 1)
        h.chips = math.max(h.s_chips + h.l_chips * (h.level - 1), 0)
        M.levelled = M.levelled or {}
        M.levelled[#M.levelled + 1] = hand
    end

    -- playing card rules: rank ids 2-14, flush rules (Stone: no rank/suit, Wild: every suit)
    function Card:get_id()
        if self.ability.effect == 'Stone Card' then return -math.random(100, 1000000) end
        return self.base.id
    end
    function Card:is_suit(suit, bypass_debuff, flush_calc)
        if self.ability.effect == 'Stone Card' then return false end
        if self.ability.effect == 'Wild Card' then return true end
        if not flush_calc and self.debuff and not bypass_debuff then return nil end
        return self.base.suit == suit
    end
    function Card:set_base(proto)
        self.base.id = proto.id
        self.base.suit = proto.suit
        self.base.nominal = math.min(proto.id, 10) + (proto.id == 14 and 1 or 0)
    end

    G.P_CARDS = {}
    local SUITS = { S = 'Spades', H = 'Hearts', C = 'Clubs', D = 'Diamonds' }
    local RANKS = { ['2'] = 2, ['3'] = 3, ['4'] = 4, ['5'] = 5, ['6'] = 6, ['7'] = 7, ['8'] = 8, ['9'] = 9,
        T = 10, J = 11, Q = 12, K = 13, A = 14 }
    for s, suit in pairs(SUITS) do
        for r, id in pairs(RANKS) do G.P_CARDS[s .. '_' .. r] = { suit = suit, id = id } end
    end

    G.C.SECONDARY_SET = { Planet = { 0.2, 0.5, 0.8, 1 } }
    G.C.L_BLACK = { 0.3, 0.3, 0.3, 1 }
    G.C.HAND_LEVELS = { {}, {}, {}, {}, {}, {}, {} }
    G.C.UI.TEXT_DARK = { 0, 0, 0, 1 }
    G.UIT.B = 'B'
    G.UIT.O = 'O'
end

-- post_inject_class of SMODS.PokerHand (src/game_object.lua): sorts G.handlist, sets order
function F.inject()
    local obj_table = SMODS.PokerHands
    local function eval(h)
        local own_amt = h.mult * h.chips
        if h.above_hand and obj_table[h.above_hand] then
            return eval(obj_table[h.above_hand]) + (own_amt * 1e-6) + (h.order_offset or 0)
        end
        return own_amt + (h.order_offset or 0)
    end
    table.sort(G.handlist, function(a, b) return eval(obj_table[a]) > eval(obj_table[b]) end)
    for i, v in ipairs(G.handlist) do obj_table[v].order = i end
end

-- Makes a playing card: F.card('H7') or F.card('H_7'), F.card('SA', { effect = 'Wild Card' })
function F.card(key, opts)
    if not key:find('_') then key = key:sub(1, 1) .. '_' .. key:sub(2) end
    local p = G.P_CARDS[key]
    assert(p, 'no card ' .. key)
    local card = Card(0, 0, G.CARD_W, G.CARD_H, { id = p.id, suit = p.suit, nominal = math.min(p.id, 10) })
    if opts and opts.effect then card.ability.effect = opts.effect end
    if opts and opts.enhancement then card.ne_enhancement = opts.enhancement end
    return card
end

-- evaluate_play reduced to the steps formations take part in (Steamodded dump order):
-- hand info -> played counters -> scoring hand -> before -> base chips/mult ->
-- initial_scoring_step -> scored cards' chips -> joker_main -> final_scoring_step -> after
function F.evaluate_play(M)
    local text, disp_text, poker_hands, scoring_hand = G.FUNCS.get_poker_hand_info(G.play.cards)
    M.played_info = { text = text, disp = disp_text, poker_hands = poker_hands, scoring = scoring_hand }
    local h = G.GAME.hands[text]
    h.played = h.played + 1
    h.played_this_round = h.played_this_round + 1
    G.GAME.last_hand_played = text
    local final = {}
    for _, card in ipairs(G.play.cards) do
        for _, c in ipairs(scoring_hand) do
            if c == card then final[#final + 1] = card end
        end
    end
    scoring_hand = final
    M.played_info.final_scoring = final
    local ctx = function(t)
        t.full_hand, t.scoring_hand, t.scoring_name, t.poker_hands = G.play.cards, scoring_hand, text, poker_hands
        return t
    end
    SMODS.calculate_context(ctx({ before = true }))
    mult = mod_mult(h.mult)
    hand_chips = mod_chips(h.chips)
    SMODS.calculate_context(ctx({ initial_scoring_step = true }))
    M.played_info.after_chain = { chips = hand_chips, mult = mult }
    for _, card in ipairs(scoring_hand) do
        hand_chips = mod_chips(hand_chips + card:get_chip_bonus())
        local m = card:get_chip_mult()
        if m ~= 0 then mult = mod_mult(mult + m) end
    end
    SMODS.calculate_context(ctx({ joker_main = true }))
    SMODS.calculate_context(ctx({ final_scoring_step = true }))
    SMODS.last_hand_score = SMODS.calculate_round_score()
    M.played_info.score = SMODS.last_hand_score
    SMODS.calculate_context(ctx({ after = true }))
    for _, p in pairs(SMODS.Scoring_Parameters) do p.current = p.default_value end
end

return F
