-- Test jokers. Phase 2: one per rank, so pools, badges and rarity weights can be checked in
-- game; they only enter pools while config.debug.test_jokers is on.
-- Phase 3: test_overflow pushes chips x mult past 1e308 (cheat menu only, never in pools).
-- Phase 4: one joker per new score operator and one reacting to every scoring phase
-- (cheat menu only, never in pools).

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

-- Chips and mult each stay below 1e308 (plain numbers); only their product overflows, which
-- exercises the Big score path of Phase 3.
SMODS.Joker {
    key = 'test_overflow',
    rarity = NE.RARITY.HEAVENLY,
    atlas = 'frames',
    pos = frame(NE.RARITY.HEAVENLY),
    cost = 20,
    discovered = true,
    blueprint_compat = true,
    config = { extra = { xchips = 1e155, xmult = 1e155 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { number_format(card.ability.extra.xchips), number_format(card.ability.extra.xmult) } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { xchips = card.ability.extra.xchips, xmult = card.ability.extra.xmult }
        end
    end,
    in_pool = function() return false end,
    set_badges = debug_badge,
}

local function never() return false end

-- Phase 4 operators ------------------------------------------------------------------------------------

SMODS.Joker {
    key = 'test_emult',
    rarity = NE.RARITY.HEAVENLY,
    atlas = 'frames',
    pos = frame(NE.RARITY.HEAVENLY),
    cost = 20,
    discovered = true,
    blueprint_compat = true,
    config = { extra = { emult = 2 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.emult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then return { emult = card.ability.extra.emult } end
    end,
    in_pool = never,
    set_badges = debug_badge,
}

SMODS.Joker {
    key = 'test_eemult',
    rarity = NE.RARITY.HEAVENLY,
    atlas = 'frames',
    pos = frame(NE.RARITY.HEAVENLY),
    cost = 20,
    discovered = true,
    blueprint_compat = true,
    config = { extra = { eemult = 2 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.eemult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then return { eemult = card.ability.extra.eemult } end
    end,
    in_pool = never,
    set_badges = debug_badge,
}

SMODS.Joker {
    key = 'test_hypermult',
    rarity = NE.RARITY.HEAVENLY,
    atlas = 'frames',
    pos = frame(NE.RARITY.HEAVENLY),
    cost = 20,
    discovered = true,
    blueprint_compat = true,
    config = { extra = { arrows = 3, amount = 1.1 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { NE.Score.arrow_text(card.ability.extra.arrows), card.ability.extra.amount } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { hypermult = { card.ability.extra.arrows, card.ability.extra.amount } }
        end
    end,
    in_pool = never,
    set_badges = debug_badge,
}

-- Adds Aura in the Ascension phase: hand score becomes (Chips x Mult) ^ 1.5.
SMODS.Joker {
    key = 'test_aura',
    rarity = NE.RARITY.HEAVENLY,
    atlas = 'frames',
    pos = frame(NE.RARITY.HEAVENLY),
    cost = 20,
    discovered = true,
    blueprint_compat = true,
    config = { extra = { aura = 0.5 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.aura } }
    end,
    calculate = function(self, card, context)
        if context.ne_ascension then return { aura = card.ability.extra.aura } end
    end,
    in_pool = never,
    set_badges = debug_badge,
}

-- Shows a message in every phase and gives +1 Divinity at Judgment.
SMODS.Joker {
    key = 'test_phases',
    rarity = NE.RARITY.DEMONIC,
    atlas = 'frames',
    pos = frame(NE.RARITY.DEMONIC),
    cost = 8,
    discovered = true,
    blueprint_compat = false,
    config = { extra = { divinity = 1 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.divinity } }
    end,
    calculate = function(self, card, context)
        if context.ne_omen then return { message = localize('ne_msg_omen'), colour = G.C.PURPLE } end
        if context.ne_chain then return { message = localize('ne_msg_chain'), colour = G.C.PURPLE } end
        if context.ne_ascension then return { message = localize('ne_msg_ascension'), colour = NE.C.AURA } end
        if context.ne_judgment then return { divinity = card.ability.extra.divinity } end
    end,
    in_pool = never,
    set_badges = debug_badge,
}
