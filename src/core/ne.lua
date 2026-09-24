-- Global namespace and constants for New Era.

NE = NE or {}

NE.ID = 'NewEra'
NE.PREFIX = 'ne'
NE.VERSION = (NE.mod and NE.mod.version) or '0.0.0'

-- Rarity keys (full keys, including the mod prefix).
NE.RARITY = {
    UNRANKED = 'ne_unranked',
    DEMONIC = 'ne_demonic',
    HEAVENLY = 'ne_heavenly',
}

-- Returns the config table, tolerating early calls before main.lua assigned it.
function NE.cfg()
    return NE.config or (NE.mod and NE.mod.config) or {}
end

-- True when debug tools are enabled in the config.
function NE.debug_enabled()
    local debug = NE.cfg().debug
    return debug ~= nil and debug.enabled == true
end

-- True when the Phase 2 test jokers may appear in pools.
function NE.test_jokers_enabled()
    local debug = NE.cfg().debug
    return debug ~= nil and debug.test_jokers == true
end
