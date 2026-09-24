-- The 17 formation planets (GDD §1.6): each one levels up one formation, like the vanilla planets
-- level up a poker hand. They use config.hand_type, so Blue Seal, Telescope, Observatory,
-- Black Hole and Celestial Packs work with them unchanged. The vanilla planets are hidden from
-- the pools (compat/vanilla_pool.lua, config hide_vanilla.planets).
-- Sprites: assets/*/ne_planets.png (tools/gen_assets.py), one per formation in priority order,
-- each showing the formation's diagram.

local Formation = NE.Formation

SMODS.Atlas {
    key = 'planets',
    path = 'ne_planets.png',
    px = 71,
    py = 95,
}

-- Description variables in the vanilla planet format: level, formation, +mult, +chips.
function Formation.planet_vars(hand_key)
    local def = Formation.DEF[hand_key]
    local h = G.GAME and G.GAME.hands and G.GAME.hands[hand_key]
    local level = (h and tonumber(h.level)) or 1
    local colour = G.C.UI.TEXT_DARK
    if level ~= 1 and G.C.HAND_LEVELS then
        colour = G.C.HAND_LEVELS[math.max(1, math.min(7, math.floor(level)))] or colour
    end
    return {
        level,
        localize(hand_key, 'poker_hands'),
        (h and h.l_mult) or (def and def.l_mult) or 0,
        (h and h.l_chips) or (def and def.l_chips) or 0,
        colours = { colour },
    }
end

for i, def in ipairs(Formation.DEFS) do
    SMODS.Planet {
        key = def.planet,
        atlas = 'planets',
        pos = { x = i - 1, y = 0 },
        cost = 3,
        config = { hand_type = def.key },
        loc_vars = function(self, info_queue, card)
            return { vars = Formation.planet_vars(self.config.hand_type) }
        end,
    }
end
