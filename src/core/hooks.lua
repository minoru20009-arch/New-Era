-- Dispatches Steamodded calculate contexts to New Era systems through mod.calculate.
-- mod.calculate runs for every context, so dispatch only looks at registered flags.

NE.Hooks = NE.Hooks or {}
local Hooks = NE.Hooks

Hooks.flags = Hooks.flags or {}      -- ordered list of context flags with handlers
Hooks.handlers = Hooks.handlers or {} -- flag -> ordered list of { id, fn }

-- Registers `fn(context)` for contexts where `context[flag]` is truthy.
-- Re-registering the same id replaces the previous handler.
-- A handler may return a calculate effect table; multiple effects are merged.
function Hooks.on_context(flag, id, fn)
    local list = Hooks.handlers[flag]
    if not list then
        list = {}
        Hooks.handlers[flag] = list
        Hooks.flags[#Hooks.flags + 1] = flag
    end
    for i = 1, #list do
        if list[i].id == id then
            list[i].fn = fn
            return
        end
    end
    list[#list + 1] = { id = id, fn = fn }
end

function Hooks.dispatch(context)
    local ret
    local flags = Hooks.flags
    for i = 1, #flags do
        local flag = flags[i]
        if context[flag] then
            local list = Hooks.handlers[flag]
            for j = 1, #list do
                local ok, eff = pcall(list[j].fn, context)
                if not ok then
                    NE.log.warn_once('hook:' .. flag .. ':' .. list[j].id,
                        'Handler %s for context %s failed: %s', list[j].id, flag, tostring(eff))
                elseif type(eff) == 'table' and next(eff) then
                    ret = ret and SMODS.merge_effects({ ret, eff }) or eff
                end
            end
        end
    end
    return ret
end

NE.mod.calculate = function(self, context)
    return Hooks.dispatch(context)
end
