-- Hides vanilla content from pools while keeping it in the collection (decision D1).
-- Uses two wrappers instead of editing vanilla centers, so it survives
-- Game:init_item_prototypes() rebuilding G.P_CENTERS (e.g. on language change):
--   * SMODS.add_to_pool  - every pool check for centers and blinds goes through it
--   * create_card        - remaps explicit vanilla joker rarities (The Soul, Wraith, tags)

NE.Pool = NE.Pool or {}
local Pool = NE.Pool

-- Vanilla joker rarity -> New Era rank when a caller asks for a specific rarity.
Pool.RARITY_MAP = {
    Common = NE.RARITY.UNRANKED,
    Uncommon = NE.RARITY.UNRANKED,
    Rare = NE.RARITY.DEMONIC,
    Legendary = NE.RARITY.HEAVENLY,
}

NE.RARITY_SET = {
    [NE.RARITY.UNRANKED] = true,
    [NE.RARITY.DEMONIC] = true,
    [NE.RARITY.HEAVENLY] = true,
}

-- Order used when a requested rank has no eligible joker.
Pool.FALLBACK = {
    [NE.RARITY.HEAVENLY] = NE.RARITY.DEMONIC,
    [NE.RARITY.DEMONIC] = NE.RARITY.UNRANKED,
}

-- A category is only hidden once New Era has replacements for it; otherwise empty pools
-- would make the game fall back to (or crash on) missing content. Blinds are flipped in
-- Phase 10 (procedural bosses).
Pool.READY = Pool.READY or { jokers = true, planets = true, blinds = false }

-- Phase 6: the planets option now has an effect and defaults to on. Configs saved earlier
-- (when it did nothing, default off) are switched on once.
do
    local cfg = NE.cfg()
    if type(cfg.hide_vanilla) == 'table' and not cfg.ne_planets_migrated then
        cfg.hide_vanilla.planets = true
        cfg.ne_planets_migrated = true
    end
end

function Pool.hidden(category)
    if not Pool.READY[category] then return false end
    local hide = NE.cfg().hide_vanilla
    return hide ~= nil and hide[category] == true
end

-- Returns 'jokers', 'planets', 'blinds' or nil for a prototype object.
function Pool.category(obj)
    if type(obj) ~= 'table' then return nil end
    if obj.set == 'Joker' then return 'jokers' end
    if obj.set == 'Planet' then return 'planets' end
    if obj.key and G.P_BLINDS and G.P_BLINDS[obj.key] == obj then return 'blinds' end
    return nil
end

function Pool.should_hide(obj)
    local category = Pool.category(obj)
    if not category or not Pool.hidden(category) then return false end
    return NE.util.is_vanilla_object(obj)
end

-- Maps the (legendary, _rarity) arguments of create_card for a Joker to a New Era rank.
-- Returns nil when the call does not request a specific rarity (normal shop roll).
function Pool.map_joker_rarity(legendary, rarity)
    if legendary then return NE.RARITY.HEAVENLY end
    if rarity == nil then return nil end
    if type(rarity) == 'number' then
        -- Same thresholds the game uses to turn a roll into Common/Uncommon/Rare.
        if rarity > 0.95 then return NE.RARITY.DEMONIC end
        return NE.RARITY.UNRANKED
    end
    if type(rarity) == 'string' then
        return Pool.RARITY_MAP[rarity] or rarity
    end
    return nil
end

-- True if at least one joker of `rarity` can currently be created.
function Pool.rarity_available(rarity, key_append)
    local pool = get_current_pool('Joker', rarity, nil, key_append)
    return not (#pool == 1 and pool[1] == 'empty_rarity')
end

-- Picks `rarity` or the nearest lower rank that has an eligible joker.
function Pool.resolve_rarity(rarity, key_append)
    local r = rarity
    while r do
        if Pool.rarity_available(r, key_append) then return r end
        r = Pool.FALLBACK[r]
    end
    return NE.RARITY.UNRANKED
end

local add_to_pool_ref = SMODS.add_to_pool
function SMODS.add_to_pool(prototype_obj, args)
    if Pool.should_hide(prototype_obj) then return false end
    return add_to_pool_ref(prototype_obj, args)
end

local create_card_ref = create_card
function create_card(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
    if _type == 'Joker' and not forced_key and Pool.hidden('jokers') then
        local mapped = Pool.map_joker_rarity(legendary, _rarity)
        if mapped and NE.RARITY_SET[mapped] then
            legendary, _rarity = nil, Pool.resolve_rarity(mapped, key_append)
        end
    end
    return create_card_ref(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
end

-- Vanilla rarities get zero weight in the Joker pool while vanilla jokers are hidden,
-- so shop rolls only pick New Era ranks.
for _, key in ipairs({ 'Common', 'Uncommon', 'Rare', 'Legendary' }) do
    local rarity = SMODS.Rarities[key]
    if rarity then
        local get_weight_ref = rarity.get_weight
        rarity.get_weight = function(self, weight, object_type)
            if object_type and object_type.key == 'Joker' and Pool.hidden('jokers') then
                return 0
            end
            if get_weight_ref then return get_weight_ref(self, weight, object_type) end
            return weight
        end
    else
        NE.log.warn('Vanilla rarity %s not found; shop weights unchanged for it.', key)
    end
end
