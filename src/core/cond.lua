-- Every conditional check made by New Era jokers goes through NE.cond, so effects such as
-- Aizen's Kyoka Suigetsu (#94) can force conditions to be true.
--
-- Usage: if NE.cond(card, 'last_hand', hands_left == 0) then ... end

NE.cond_overrides = NE.cond_overrides or {}

-- Registers an override. `fn(card, key, value)` returns true/false to force a result,
-- or nil to leave the condition unchanged. Re-registering an id replaces it.
function NE.register_cond_override(id, fn)
    local list = NE.cond_overrides
    for i = 1, #list do
        if list[i].id == id then
            list[i].fn = fn
            return
        end
    end
    list[#list + 1] = { id = id, fn = fn }
end

function NE.unregister_cond_override(id)
    local list = NE.cond_overrides
    for i = #list, 1, -1 do
        if list[i].id == id then table.remove(list, i) end
    end
end

function NE.cond(card, key, value)
    local list = NE.cond_overrides
    for i = 1, #list do
        local forced = list[i].fn(card, key, value)
        if forced ~= nil then return forced and true or false end
    end
    return value and true or false
end
