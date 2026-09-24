-- Run currencies (GDD §4): Divinity, Corruption and Time.
-- Phase 4 stores the values and handles the calculate return keys (`divinity`, `corruption`,
-- `time`). HUD, Corruption thresholds, Hell's Judgment and spending UI arrive in Phase 7.
-- Values are plain Lua numbers kept in G.GAME.newera.currency (saved with the run).

NE.Currency = NE.Currency or {}
local Currency = NE.Currency

Currency.CAP = 1e300 -- GDD §3.4: currencies stay Lua numbers below 1e300

Currency.KINDS = {
    divinity = { max = Currency.CAP },
    corruption = { max = 100 },
    time = { max_field = 'time_cap' },
}
Currency.ORDER = { 'divinity', 'corruption', 'time' }

local MAX_EVENT_DEPTH = 3 -- a joker reacting to a change may change a currency again

local depth = 0

local function state()
    local s = NE.State.get()
    return s and s.currency
end

function Currency.is_kind(kind)
    return Currency.KINDS[kind] ~= nil
end

function Currency.get(kind)
    local c = state()
    return c and c[kind] or 0
end

function Currency.max(kind)
    local def = Currency.KINDS[kind]
    if not def then return 0 end
    if def.max_field then
        local c = state()
        return c and c[def.max_field] or 0
    end
    return def.max
end

-- Whole units only; rounds toward zero so +0.9 never creates a unit.
local function whole(n)
    n = NE.Big.to_number(n)
    if n ~= n then return 0 end
    if n >= 0 then return math.floor(n) end
    return -math.floor(-n)
end

-- Adds `amount` (negative to remove) and clamps to [0, max].
-- Returns the change actually applied. Fires context ne_currency_changed when it changed.
function Currency.add(kind, amount, source)
    local c = state()
    if not (c and Currency.KINDS[kind]) then return 0 end
    local old = c[kind] or 0
    local new = NE.util.clamp(old + whole(amount), 0, Currency.max(kind))
    c[kind] = new
    local applied = new - old
    if applied ~= 0 and depth < MAX_EVENT_DEPTH and SMODS.calculate_context then
        depth = depth + 1
        local ok, err = pcall(SMODS.calculate_context,
            { ne_currency_changed = true, currency = kind, amount = applied, source = source })
        depth = depth - 1
        if not ok then NE.log.warn_once('currency_ctx', 'ne_currency_changed failed: %s', tostring(err)) end
    end
    return applied
end

function Currency.can_spend(kind, amount)
    return Currency.get(kind) >= whole(amount)
end

-- Removes `amount` only if all of it is available. Returns true when spent.
function Currency.spend(kind, amount, source)
    amount = whole(amount)
    if amount <= 0 or not Currency.can_spend(kind, amount) then return false end
    Currency.add(kind, -amount, source)
    return true
end
