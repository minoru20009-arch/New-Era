-- The three New Era ranks (01-gdd-systems §8).
-- Names come from localization (misc.labels / misc.dictionary: k_ne_*).

-- Heavenly jokers only appear in shops from this ante on (other sources ignore it).
NE.HEAVENLY_SHOP_MIN_ANTE = 4

local function current_ante()
    return G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante or 1
end

SMODS.Rarity {
    key = 'unranked',
    badge_colour = HEX('7D8BA1'),
    default_weight = 0.75,
    pools = { ['Joker'] = true },
    get_weight = function(self, weight, object_type)
        return weight
    end,
}

SMODS.Rarity {
    key = 'demonic',
    badge_colour = HEX('B3122E'),
    default_weight = 0.22,
    disable_if_empty = true,
    pools = { ['Joker'] = true },
    get_weight = function(self, weight, object_type)
        return weight
    end,
}

SMODS.Rarity {
    key = 'heavenly',
    badge_colour = HEX('D4AF37'),
    text_colour = HEX('1B1B1B'),
    default_weight = 0.03,
    disable_if_empty = true,
    pools = { ['Joker'] = true },
    get_weight = function(self, weight, object_type)
        if current_ante() < NE.HEAVENLY_SHOP_MIN_ANTE then return 0 end
        return weight
    end,
}
