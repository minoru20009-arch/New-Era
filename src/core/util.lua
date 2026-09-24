-- Small shared helpers. Keep this file free of game-state side effects.

NE.util = NE.util or {}
local util = NE.util

-- True for values that behave like numbers in New Era: Lua numbers and NE.Big values.
function util.is_numeric(x)
    return type(x) == 'number' or (NE.Big ~= nil and NE.Big.is ~= nil and NE.Big.is(x))
end
NE.is_numeric = util.is_numeric

function util.clamp(x, lo, hi)
    if x < lo then return lo end
    if x > hi then return hi end
    return x
end

-- Fills missing keys of `target` from `defaults`, recursing into nested plain tables.
-- Existing values are never overwritten. Returns `target`.
function util.fill_defaults(target, defaults)
    for k, v in pairs(defaults) do
        local current = target[k]
        if current == nil then
            if type(v) == 'table' then
                target[k] = util.fill_defaults({}, v)
            else
                target[k] = v
            end
        elseif type(current) == 'table' and type(v) == 'table' then
            util.fill_defaults(current, v)
        end
    end
    return target
end

-- Removes every key from `t` without replacing the table (keeps references valid).
function util.clear(t)
    for k in pairs(t) do t[k] = nil end
    return t
end

-- True if a center/prototype belongs to the base game (not added by any mod).
-- Objects Steamodded took ownership of internally still count as vanilla.
function util.is_vanilla_object(obj)
    if type(obj) ~= 'table' then return false end
    local mod = obj.mod
    if mod == nil then return true end
    return mod.id == 'Steamodded'
end
