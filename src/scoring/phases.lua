-- Scoring phases (GDD §3.2), dispatched as calculate contexts so jokers react with
-- `if context.ne_omen then ... end` and return normal effects:
--
--   ne_omen       after Play is pressed, played cards already in G.play, before evaluation
--   ne_chain      once per secondary formation, at the start of scoring (Phase 6 supplies
--                 the formations; until then the phase is reached with 0 secondaries)
--   ne_ascension  after every joker (end of final_scoring_step), before the score is taken
--   ne_judgment   after the hand score is known: context.score, context.total (round score
--                 after this hand), context.overkill (amount above the blind target, >= 0)
--
-- No Lovely patch is needed: New Era's mod.calculate runs after all jokers for each
-- Steamodded context (jokers -> playing cards -> deck/blind/stake/mods), so each phase is
-- started from the matching Steamodded context:
--   press_play -> queued event -> ne_omen;  initial_scoring_step -> ne_chain;
--   final_scoring_step -> ne_ascension;     after -> ne_judgment (before hand rules clear).

NE.Phases = NE.Phases or {}
local Phases = NE.Phases
local Big = NE.Big

Phases.ORDER = { 'omen', 'chain', 'ascension', 'judgment' }

-- Phase trace of the current and the previous hand (shown in the F9 overlay).
Phases.trace = Phases.trace or { current = {}, last = '' }

-- Phase 6 replaces this with the formation evaluator's secondary formations.
Phases.secondaries = Phases.secondaries or function(context) return {} end

local function trace(entry)
    local cur = Phases.trace.current
    cur[#cur + 1] = entry
end

local function hand_fields(context, out)
    out.full_hand = context and context.full_hand or (G.play and G.play.cards)
    out.scoring_hand = context and context.scoring_hand
    out.scoring_name = context and context.scoring_name
    out.poker_hands = context and context.poker_hands
    return out
end

-- Fires context ne_<name> (plus ne_phase = name) for every card area and mod.
function Phases.dispatch(name, fields)
    fields = fields or {}
    fields['ne_' .. name] = true
    fields.ne_phase = name
    SMODS.calculate_context(fields)
end

function Phases.begin_hand()
    Phases.trace.current = {}
end

function Phases.end_hand()
    Phases.trace.last = table.concat(Phases.trace.current, ' > ')
end

-- Omen -------------------------------------------------------------------------------------------------
NE.Hooks.on_context('press_play', 'phase_omen', function()
    Phases.begin_hand()
    -- queued after the cards' draw events, before evaluate_play (queued after press_play)
    G.E_MANAGER:add_event(Event({
        trigger = 'immediate',
        func = function()
            trace('omen')
            Phases.dispatch('omen', hand_fields(nil, {}))
            return true
        end,
    }))
end)

-- Chain ------------------------------------------------------------------------------------------------
NE.Hooks.on_context('initial_scoring_step', 'phase_chain', function(context)
    local ok, list = pcall(Phases.secondaries, context)
    if not ok or type(list) ~= 'table' then
        NE.log.warn_once('phase_chain', 'Secondary formation provider failed: %s', tostring(list))
        list = {}
    end
    trace('chain(' .. #list .. ')')
    for i, formation in ipairs(list) do
        local fields = hand_fields(context, {})
        fields.ne_formation = formation
        fields.ne_chain_index = i
        fields.ne_chain_count = #list
        Phases.dispatch('chain', fields)
    end
end)

-- Ascension ----------------------------------------------------------------------------------------------
NE.Hooks.on_context('final_scoring_step', 'phase_ascension', function(context)
    trace('ascension')
    Phases.dispatch('ascension', hand_fields(context, {}))
end)

-- Judgment ------------------------------------------------------------------------------------------------
NE.Hooks.on_context('after', 'phase_judgment', function(context)
    local score = SMODS.last_hand_score or 0
    local chips = G.GAME.chips or 0
    local target = G.GAME.blind and G.GAME.blind.chips or 0
    local total = Big.add(chips, math.floor(score))
    local overkill = Big.sub(total, target)
    if Big.lt(overkill, 0) then overkill = Big.new(0) end

    local fields = hand_fields(context, {})
    fields.score = score
    fields.total = total
    fields.overkill = overkill
    trace('judgment')
    Phases.dispatch('judgment', fields)
    Phases.last_score = score
    Phases.end_hand()
end)
