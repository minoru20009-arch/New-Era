-- Score operators (GDD §3.3) and Big-safe Chips/Mult.
--
-- Chips and Mult become NE.Big once they reach 1e100. Every change of the `hand_chips` and
-- `mult` globals goes through mod_chips / mod_mult (vanilla functions that Steamodded also uses
-- to sync its Scoring_Parameters), so wrapping those two makes all of Steamodded's own
-- arithmetic (x_mult, balance, swap, ...) continue in Big instead of overflowing to inf.
-- Below 1e100 they stay plain numbers, so ordinary hands run exactly the vanilla code paths
-- (flames, text juice, "+X" popups); from 1e100 up there is ~1e208 of headroom before a plain
-- multiplication could overflow, and Big values below 1e308 are exact doubles anyway.
--
-- New calculate return keys (registered through the Aura Scoring_Parameter, see aura.lua, so
-- they are applied after Steamodded's chips/mult/xchips/xmult keys):
--   echips = x        Chips ^ x
--   emult = x         Mult ^ x
--   eemult = x        Mult ^^ x
--   hypermult = {n, x} (or {arrows = n, amount = x})   Mult {n} x
--   aura = x          Aura + x
--   xaura = x         Aura * x
--   divinity / corruption / time = n   run currencies (NE.Currency)

NE.Score = NE.Score or {}
local Score = NE.Score
local Big = NE.Big

-- Promotion ----------------------------------------------------------------------------------------

Score.PROMOTE_AT = 1e100

-- Plain number below PROMOTE_AT, Big from there on. Overflowed numbers (inf/nan) are clamped.
local function promote(v)
    if type(v) == 'number' then
        v = Big.sanitize_number(v)
        if v >= Score.PROMOTE_AT or v <= -Score.PROMOTE_AT then return Big.new(v) end
        return v
    end
    if Big.is(v) then
        if v.len == 1 and v.a[0] < Score.PROMOTE_AT then return Big.to_number(v) end
        return v
    end
    return v -- non-numeric values ('?' for face-down hands) pass through
end
Score.promote = promote

local function wrap_mod(name, param_key)
    local ref = _G[name]
    if type(ref) ~= 'function' then
        NE.log.warn('%s not found; %s will not be promoted to Big.', name, param_key)
        return
    end
    _G[name] = function(v)
        local r = promote(ref(v))
        -- Steamodded syncs the parameter through a difference (current + (new - old)), which
        -- cancels out when the value drops by many orders of magnitude; set it exactly.
        local params = SMODS.Scoring_Parameters
        local p = params and params[param_key]
        if p and NE.is_numeric(r) then p.current = r end
        return r
    end
end

wrap_mod('mod_chips', 'chips')
wrap_mod('mod_mult', 'mult')

-- Sets the value of chips or mult exactly. The global is written first so Steamodded's sync
-- inside mod_chips/mod_mult sees a zero difference, then updates the display.
local function set_chips(v)
    hand_chips = promote(v)
    hand_chips = mod_chips(hand_chips)
end

local function set_mult(v)
    mult = promote(v)
    mult = mod_mult(mult)
end

Score.set_chips = set_chips
Score.set_mult = set_mult

-- Operators ------------------------------------------------------------------------------------------

-- Reads {n, x} or {arrows = n, amount = x}.
local function hyper_args(amount)
    if type(amount) ~= 'table' then return nil end
    local n = amount.arrows or amount.n or amount[1]
    local x = amount.amount or amount.x or amount[2]
    if n == nil or x == nil then return nil end
    return math.floor(Big.to_number(n)), x
end
Score.hyper_args = hyper_args

local function fmt(v)
    return number_format(v)
end

-- Text of a hyper operator for messages: 2 -> '^^', 3 -> '{3}'.
local function arrow_text(n)
    if n == 1 then return '^' end
    if n == 2 then return '^^' end
    return '{' .. n .. '}'
end
Score.arrow_text = arrow_text

local function message(effect, scored_card, text, colour)
    if effect.remove_default_message then return end
    card_eval_status_text(effect.message_card or effect.juice_card or scored_card or effect.card or effect.focus,
        'extra', nil, percent, nil, { message = text, colour = colour })
end

local function juice_source(effect, scored_card)
    if effect.card and effect.card ~= scored_card then juice_card(effect.card) end
end

local function controls(key)
    local c = SMODS.Calculation_Controls
    return c == nil or c[key] ~= false
end

-- key -> handler(self, effect, scored_card, amount) returning true when applied
Score.HANDLERS = {
    echips = function(aura_param, effect, scored_card, amount)
        if not controls('chips') or Big.eq(amount, 1) then return end
        juice_source(effect, scored_card)
        set_chips(Big.pow(hand_chips, amount))
        message(effect, scored_card, localize({ type = 'variable', key = 'ne_a_echips', vars = { fmt(amount) } }), NE.C.EXP_CHIPS)
        return true
    end,
    emult = function(aura_param, effect, scored_card, amount)
        if not controls('mult') or Big.eq(amount, 1) then return end
        juice_source(effect, scored_card)
        set_mult(Big.pow(mult, amount))
        message(effect, scored_card, localize({ type = 'variable', key = 'ne_a_emult', vars = { fmt(amount) } }), NE.C.EXP_MULT)
        return true
    end,
    eemult = function(aura_param, effect, scored_card, amount)
        if not controls('mult') or Big.eq(amount, 1) then return end
        juice_source(effect, scored_card)
        set_mult(Big.arrow(mult, 2, amount))
        message(effect, scored_card, localize({ type = 'variable', key = 'ne_a_eemult', vars = { fmt(amount) } }), NE.C.EXP_MULT)
        return true
    end,
    hypermult = function(aura_param, effect, scored_card, amount)
        if not controls('mult') then return end
        local n, x = hyper_args(amount)
        if not n then
            NE.log.warn_once('hypermult_args', 'hypermult needs {n, x}; got %s', tostring(amount))
            return
        end
        if n < 0 then return end
        juice_source(effect, scored_card)
        set_mult(Big.arrow(mult, n, x))
        message(effect, scored_card,
            localize({ type = 'variable', key = 'ne_a_hypermult', vars = { arrow_text(n), fmt(x) } }), NE.C.EXP_MULT)
        return true
    end,
    aura = function(aura_param, effect, scored_card, amount)
        if not controls(aura_param.key) or Big.is_zero(amount) then return end
        juice_source(effect, scored_card)
        aura_param:modify(amount)
        local negative = Big.lt(amount, 0)
        message(effect, scored_card, localize({
            type = 'variable',
            key = negative and 'ne_a_aura_minus' or 'ne_a_aura',
            vars = { fmt(negative and Big.neg(amount) or amount) },
        }), NE.C.AURA)
        return true
    end,
    xaura = function(aura_param, effect, scored_card, amount)
        if not controls(aura_param.key) or Big.eq(amount, 1) then return end
        juice_source(effect, scored_card)
        aura_param:modify(Big.mul(aura_param.current, Big.sub(amount, 1)))
        message(effect, scored_card, localize({ type = 'variable', key = 'ne_a_xaura', vars = { fmt(amount) } }), NE.C.AURA)
        return true
    end,
}

local CURRENCY_COLOURS = { divinity = 'DIVINITY', corruption = 'CORRUPTION', time = 'TIME' }

for kind, colour_key in pairs(CURRENCY_COLOURS) do
    Score.HANDLERS[kind] = function(aura_param, effect, scored_card, amount)
        local applied = NE.Currency.add(kind, amount, scored_card)
        if applied == 0 then return end
        juice_source(effect, scored_card)
        message(effect, scored_card, localize({
            type = 'variable',
            key = 'ne_a_' .. kind,
            vars = { (applied > 0 and '+' or '') .. applied },
        }), NE.C[colour_key])
        return true
    end
end

-- Order matters: Steamodded applies keys in list order (all after its own chips/mult keys).
Score.KEYS = { 'echips', 'emult', 'eemult', 'hypermult', 'aura', 'xaura', 'divinity', 'corruption', 'time' }

-- calc_effect of the Aura parameter: every New Era key is routed here.
function Score.calc_effect(aura_param, effect, scored_card, key, amount, from_edition)
    local handler = Score.HANDLERS[key]
    if not handler or amount == nil then return end
    if key ~= 'hypermult' and not NE.is_numeric(amount) then
        NE.log.warn_once('score_key_' .. key, 'Ignoring non-numeric %s = %s', key, tostring(amount))
        return
    end
    return handler(aura_param, effect, scored_card, amount)
end
