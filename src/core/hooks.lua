-- Dispatches Steamodded calculate contexts to New Era systems through mod.calculate.
-- mod.calculate runs for every context, so dispatch only looks at registered flags.

NE.Hooks = NE.Hooks or {}
local Hooks = NE.Hooks

Hooks.flags = Hooks.flags or {}      -- ordered list of context flags with handlers
Hooks.handlers = Hooks.handlers or {} -- flag -> ordered list of { id, fn }

Hooks.ORDER_DEFAULT = 0
Hooks.ORDER_CLEANUP = 100 -- state cleanup (e.g. hand rules) after every other handler

-- Registers `fn(context)` for contexts where `context[flag]` is truthy.
-- Handlers run by `order` (lower first, default 0), then by registration.
-- Re-registering the same id replaces the previous handler.
-- A handler may return a calculate effect table; multiple effects are merged.
function Hooks.on_context(flag, id, fn, order)
    order = order or Hooks.ORDER_DEFAULT
    local list = Hooks.handlers[flag]
    if not list then
        list = {}
        Hooks.handlers[flag] = list
        Hooks.flags[#Hooks.flags + 1] = flag
    end
    for i = 1, #list do
        if list[i].id == id then
            table.remove(list, i)
            break
        end
    end
    local pos = #list + 1
    for i = 1, #list do
        if list[i].order > order then
            pos = i
            break
        end
    end
    table.insert(list, pos, { id = id, fn = fn, order = order })
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
