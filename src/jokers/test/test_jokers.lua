-- Phase 2 test jokers: one per rank, so pools, badges and rarity weights can be checked in game.
-- They only enter pools while config.debug.test_jokers is on.

local function debug_badge(self, card, badges)
    badges[#badges + 1] = create_badge(localize('ne_badge_debug'), G.C.RED, G.C.WHITE, 0.8)
end

local function frame(rarity)
    local pos = NE.FRAME_POS[rarity]
    return { x = pos.x, y = pos.y }
end

local function in_pool()
    return NE.test_jokers_enabled()
end

SMODS.Joker {
    key = 'test_unranked',
    rarity = NE.RARITY.UNRANKED,
    atlas = 'frames',
    pos = frame(NE.RARITY.UNRANKED),
    cost = 4,
    discovered = true,
    blueprint_compat = true,
    config = { extra = { mult = 8 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { mult = card.ability.extra.mult }
        end
    end,
    in_pool = in_pool,
    set_badges = debug_badge,
}

SMODS.Joker {
    key = 'test_demonic',
    rarity = NE.RARITY.DEMONIC,
    atlas = 'frames',
    pos = frame(NE.RARITY.DEMONIC),
    cost = 8,
    discovered = true,
    blueprint_compat = true,
    config = { extra = { xmult = 3 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { xmult = card.ability.extra.xmult }
        end
    end,
    in_pool = in_pool,
    set_badges = debug_badge,
}

SMODS.Joker {
    key = 'test_heavenly',
    rarity = NE.RARITY.HEAVENLY,
    atlas = 'frames',
    pos = frame(NE.RARITY.HEAVENLY),
    cost = 20,
    discovered = true,
    blueprint_compat = true,
    config = { extra = { chips = 100, xmult = 5 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { chips = card.ability.extra.chips, xmult = card.ability.extra.xmult }
        end
    end,
    in_pool = in_pool,
    set_badges = debug_badge,
}
