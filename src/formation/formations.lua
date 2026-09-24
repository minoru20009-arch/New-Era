-- Formations in Steamodded (GDD §1.4-1.6, architecture §4.3).
--
-- Each formation is an SMODS.PokerHand (levels, planets, Run Info and saving come for free).
-- Its evaluate() reads the evaluator result for the evaluated cards, so Steamodded's own
-- get_poker_hand_info picks the Primary formation (G.handlist is sorted by the same priority).
-- The vanilla poker hands stay registered but never match and are hidden.
--
-- Hand flow (wraps, no patch):
--   get_poker_hand_info  evaluates the cards once; scoring_hand = the cards of every counted
--                        formation (the whole chain), so all of them score and then leave
--                        the board (Board.consumed_provider reads context.scoring_hand)
--   evaluate_poker_hand  context: the display name becomes the chain, "Triad + Twin Link"
--   initial_scoring_step Chain phase: each Secondary adds ne_chain_pct % (50) of its chips and
--                        mult at its level; Hell Pact / Halo Line give Corruption / Divinity
-- Patch L12 (lovely/35_formations.toml): the most played hand (The Ox) is a formation.

local Formation = NE.Formation
local Board = NE.Board
local Phases = NE.Phases or {}
NE.Phases = Phases

Formation.VANILLA_HANDS = {
    'Flush Five', 'Flush House', 'Five of a Kind', 'Straight Flush', 'Four of a Kind', 'Full House',
    'Flush', 'Straight', 'Three of a Kind', 'Two Pair', 'Pair', 'High Card',
}
local VANILLA = {}
for _, k in ipairs(Formation.VANILLA_HANDS) do VANILLA[k] = true end
Formation.VANILLA = VANILLA

-- Example cards of the hand tooltip ({card key, scores}).
local EXAMPLES = {
    heavens_gate = { { 'S_A', true }, { 'S_K', true }, { 'S_Q', true }, { 'S_J', true }, { 'S_T', true } },
    five_line = { { 'S_7', true }, { 'H_7', true }, { 'C_7', true }, { 'D_7', true }, { 'S_7', true } },
    royal_row = { { 'H_9', true }, { 'H_T', true }, { 'H_J', true }, { 'H_Q', true }, { 'H_K', true } },
    quad_square = { { 'S_Q', true }, { 'H_Q', true }, { 'C_Q', true }, { 'D_Q', true } },
    hell_pact = { { 'S_6', true }, { 'C_6', true }, { 'D_2', true } },
    halo_line = { { 'H_A', true }, { 'D_K', true }, { 'H_3', true } },
    compass = { { 'S_2', true }, { 'S_5', true }, { 'S_9', true }, { 'S_J', true }, { 'S_K', true } },
    full_link = { { 'S_8', true }, { 'H_8', true }, { 'D_8', true }, { 'C_4', true }, { 'H_4', true } },
    row_flush = { { 'D_2', true }, { 'D_6', true }, { 'D_8', true }, { 'D_J', true }, { 'D_A', true } },
    row_straight = { { 'S_4', true }, { 'H_5', true }, { 'D_6', true }, { 'C_7', true }, { 'S_8', true } },
    bastion = { { 'C_3', true }, { 'C_7', true }, { 'C_T', true }, { 'C_K', true } },
    triad = { { 'S_K', true }, { 'D_K', true }, { 'C_K', true } },
    ascent = { { 'H_5', true }, { 'S_6', true }, { 'D_7', true } },
    double_link = { { 'S_9', true }, { 'H_9', true }, { 'C_3', true }, { 'D_3', true } },
    kin_trio = { { 'H_4', true }, { 'H_T', true }, { 'H_Q', true } },
    twin_link = { { 'S_J', true }, { 'D_J', true }, { 'C_5', false } },
    spark = { { 'S_A', true }, { 'D_8', false }, { 'C_4', false } },
}

-- Vanilla poker hands: never match, hidden in Run Info and the collection.
local function never() return {} end
for _, key in ipairs(Formation.VANILLA_HANDS) do
    if SMODS.PokerHands and SMODS.PokerHands[key] then
        SMODS.PokerHand:take_ownership(key, { visible = false, no_collection = true, evaluate = never }, true)
    end
end

-- Evaluation ------------------------------------------------------------------------------------------------

Formation.current = nil -- view of the latest evaluation
Formation.pinned = nil  -- view evaluate_poker_hand reuses inside get_poker_hand_info
Formation.played = nil  -- view of the played hand (captured once after Play)
Formation.capture = false
Formation.depth = 0     -- > 0 while get_poker_hand_info / evaluate_poker_hand run

local function safe_eval(cards)
    local ok, view = pcall(Formation.evaluate_cards, cards)
    if ok then return view end
    NE.log.warn_once('formation_eval', 'Formation evaluation failed: %s', tostring(view))
    -- fallback so a hand always has a type: Spark on the first card
    local fallback = { input = cards, chain = {}, scoring = {}, poker_hands = {}, slot_of = {} }
    if cards[1] then
        fallback.primary = Formation.DEFAULT_HAND
        fallback.poker_hands[Formation.DEFAULT_HAND] = { { cards[1] } }
        fallback.scoring[1] = cards[1]
        fallback.chain[1] = { key = Formation.DEFAULT_HAND, cards = { cards[1] }, slots = {} }
    end
    return fallback
end
Formation.safe_eval = safe_eval

-- View for a card list: inside an evaluation the one made for that list, else a new
-- evaluation (a cache hit when nothing changed). A list such as G.play.cards keeps its
-- identity while its cards change, so an older view is never trusted outside an evaluation.
function Formation.view_for(cards)
    local cur = Formation.current
    if not (Formation.depth > 0 and cur and cur.input == cards) then
        cur = safe_eval(cards)
        Formation.current = cur
    end
    return cur
end

function Formation.hands_for(key, cards)
    return Formation.view_for(cards).poker_hands[key]
end

for _, def in ipairs(Formation.DEFS) do
    SMODS.PokerHand {
        key = def.name,
        chips = def.chips,
        mult = def.mult,
        l_chips = def.l_chips,
        l_mult = def.l_mult,
        example = EXAMPLES[def.name],
        order_offset = def.order_offset,
        visible = true,
        evaluate = function(parts, hand)
            return Formation.hands_for(def.key, hand)
        end,
    }
end

local evaluate_ref = evaluate_poker_hand
function evaluate_poker_hand(hand)
    local pinned = Formation.pinned
    if pinned and pinned.input == hand then
        Formation.current = pinned
    else
        Formation.current = safe_eval(hand)
    end
    -- no pcall: an error here crashes the game anyway, and keeps its full traceback that way
    -- (start_run resets the depth)
    Formation.depth = Formation.depth + 1
    local results = evaluate_ref(hand)
    Formation.depth = Formation.depth - 1
    return results
end

local info_ref = G.FUNCS.get_poker_hand_info
G.FUNCS.get_poker_hand_info = function(cards)
    local view = safe_eval(cards)
    Formation.current = view
    local outer = Formation.pinned
    Formation.pinned = view
    Formation.depth = Formation.depth + 1
    local text, loc_disp, poker_hands, scoring_hand, disp = info_ref(cards)
    Formation.depth = Formation.depth - 1
    Formation.pinned = outer
    if text == view.primary and view.scoring[1] then
        scoring_hand = {}
        for i, card in ipairs(view.scoring) do scoring_hand[i] = card end
    end
    if Formation.capture and G.play and cards == G.play.cards then
        Formation.played = view
        Formation.capture = false
    end
    return text, loc_disp, poker_hands, scoring_hand, disp
end

NE.Hooks.on_context('press_play', 'formation_capture', function()
    Formation.played = nil
    Formation.capture = true
end)

-- Chain name, unless a joker already renamed the hand.
NE.Hooks.on_context('evaluate_poker_hand', 'formation_chain_name', function(context)
    local cards = context.full_hand
    if not cards then return end
    local view = Formation.view_for(cards)
    if not (view.chain[2] and view.primary) then return end
    if context.scoring_name ~= view.primary or context.display_name ~= view.primary then return end
    return { replace_display_name = Formation.chain_text(view) }
end)

-- The played hand's view (for the scoring phases).
function Formation.played_view(context)
    local cards = context and context.full_hand
    local view = Formation.played
    if cards and not (view and view.input == cards) then view = safe_eval(cards) end
    return view
end

-- Chain phase ------------------------------------------------------------------------------------------

-- Secondary formations of the played hand (none when a joker changed the hand type).
Phases.secondaries = function(context)
    local view = Formation.played_view(context)
    local out = {}
    if not view or (context.scoring_name and context.scoring_name ~= view.primary) then return out end
    for i = 2, #view.chain do out[#out + 1] = view.chain[i] end
    return out
end

-- Bonus of one Secondary: ne_chain_pct % of its chips and mult (at its level).
function Formation.chain_bonus(key)
    local h = G.GAME and G.GAME.hands and G.GAME.hands[key]
    if not h then return 0, 0 end
    local pct = Formation.chain_pct() / 100
    local function part(v)
        if not NE.is_numeric(v) then return 0 end
        return NE.Score.promote(NE.Big.mul(v, pct))
    end
    return part(h.chips), part(h.mult)
end

Phases.chain_step = function(formation, index, context)
    local card = formation.cards and formation.cards[1]
    if not card then return end
    card_eval_status_text(card, 'extra', nil, nil, nil, {
        message = localize(formation.key, 'poker_hands'),
        colour = G.C.SECONDARY_SET.Planet,
    })
    local chips, mult = Formation.chain_bonus(formation.key)
    local effect = {}
    if not NE.Big.is_zero(chips) then effect.chips = chips end
    if not NE.Big.is_zero(mult) then effect.mult = mult end
    if next(effect) then SMODS.calculate_effect(effect, card) end
end

-- Hell Pact / Halo Line: currency whenever they are part of the played chain.
NE.Hooks.on_context('initial_scoring_step', 'formation_currency', function(context)
    local view = Formation.played_view(context)
    if not view or (context.scoring_name and context.scoring_name ~= view.primary) then return end
    for _, link in ipairs(view.chain) do
        local def = Formation.DEF[link.key]
        local cur = def and def.currency
        if cur and link.cards[1] then
            SMODS.calculate_effect({ [cur.kind] = cur.amount }, link.cards[1])
        end
    end
end)

-- Runs & saves ---------------------------------------------------------------------------------------------

-- Run data for the formations: saves from before Phase 6 get the formation hands, vanilla
-- hands are hidden, and the most played hand is a formation.
function Formation.ensure_hands(game)
    if not (game and game.hands) then return end
    for _, key in ipairs(SMODS.PokerHand.obj_buffer or {}) do
        local proto = SMODS.PokerHands[key]
        if proto and game.hands[key] == nil then
            local h = {}
            for k, v in pairs(proto) do
                if type(v) == 'number' or type(v) == 'boolean' or k == 'example' or k == 'key' then h[k] = v end
            end
            game.hands[key] = h
        end
    end
    for key in pairs(VANILLA) do
        if game.hands[key] then game.hands[key].visible = false end
    end
    local cr = game.current_round
    if cr and not Formation.is_formation(cr.most_played_poker_hand) then
        cr.most_played_poker_hand = Formation.DEFAULT_HAND
    end
end

local igo_ref = Game.init_game_object
function Game:init_game_object()
    local t = igo_ref(self)
    Formation.ensure_hands(t)
    return t
end

local start_run_ref = Game.start_run
function Game:start_run(args)
    -- a loaded save becomes G.GAME inside start_run: complete it before anything reads it
    local saved = args and type(args.savetext) == 'table' and args.savetext.GAME
    if type(saved) == 'table' then Formation.ensure_hands(saved) end
    local ret = start_run_ref(self, args)
    Formation.ensure_hands(self.GAME)
    Formation.played, Formation.current, Formation.pinned, Formation.capture = nil, nil, nil, false
    Formation.depth = 0
    Formation.invalidate()
    return ret
end

-- Patch L12: hands that can be the most played hand.
function Formation.counts_as_most_played(key)
    return Formation.is_formation(key)
end

-- Preview: the placement changed (Residue moved by an effect).
NE.Hooks.on_context('ne_board_changed', 'formation_preview', function()
    if Board.refresh_preview then Board.refresh_preview() end
end)
