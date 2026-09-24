-- Run rules that jokers and bosses can override for a scope (hand, round, ante) or permanently.
-- Values must be plain data because they are saved with G.GAME.newera.

NE.Rules = NE.Rules or {}
local Rules = NE.Rules

Rules.SCOPES = { 'hand', 'round', 'ante' } -- lookup order: narrowest scope wins
Rules.defaults = Rules.defaults or {}

local VALID_SCOPE = { hand = true, round = true, ante = true }

function Rules.define(key, default)
    Rules.defaults[key] = default
end

function Rules.push_temp(key, value, scope)
    if not VALID_SCOPE[scope] then
        NE.log.error('Rules.push_temp: invalid scope %s for rule %s', tostring(scope), tostring(key))
        return
    end
    local s = NE.State.get()
    if not s then return end
    s.rules.temp[scope][key] = value
end

function Rules.push_permanent(key, value)
    local s = NE.State.get()
    if not s then return end
    s.rules.permanent[key] = value
end

function Rules.get(key)
    local s = NE.State.get()
    if s then
        local temp = s.rules.temp
        for i = 1, #Rules.SCOPES do
            local v = temp[Rules.SCOPES[i]][key]
            if v ~= nil then return v end
        end
        local v = s.rules.permanent[key]
        if v ~= nil then return v end
    end
    return Rules.defaults[key]
end

function Rules.clear_scope(scope)
    local s = NE.State.get()
    if not (s and VALID_SCOPE[scope]) then return end
    NE.util.clear(s.rules.temp[scope])
end

-- Counts temporary rules per scope (used by the debug overlay).
function Rules.count(scope)
    local s = NE.State.get()
    if not (s and VALID_SCOPE[scope]) then return 0 end
    local n = 0
    for _ in pairs(s.rules.temp[scope]) do n = n + 1 end
    return n
end

-- Scope lifetimes. `after` is the last context of a played hand.
NE.Hooks.on_context('after', 'rules_hand', function()
    Rules.clear_scope('hand')
end, NE.Hooks.ORDER_CLEANUP)

NE.Hooks.on_context('end_of_round', 'rules_round', function(context)
    -- end_of_round is also sent per playing card (individual/repetition); react once.
    if context.individual or context.repetition then return end
    Rules.clear_scope('hand')
    Rules.clear_scope('round')
end, NE.Hooks.ORDER_CLEANUP)

NE.Hooks.on_context('ante_change', 'rules_ante', function()
    Rules.clear_scope('ante')
end, NE.Hooks.ORDER_CLEANUP)
