-- Aura (GDD §3.1): third scoring parameter. Hand score = (Chips x Mult) ^ Aura, default 1.
-- Registered as a Steamodded Scoring_Parameter (key ne_aura). Its calculation_keys carry every
-- New Era return key (see operators.lua), so Steamodded routes them to Score.calc_effect and
-- applies them after its own chips/mult keys.

local Big = NE.Big

local param = SMODS.Scoring_Parameter {
    key = 'aura',
    default_value = 1,
    colour = NE.C.AURA,
    calculation_keys = NE.Score.KEYS,
    calc_effect = function(self, effect, scored_card, key, amount, from_edition)
        return NE.Score.calc_effect(self, effect, scored_card, key, amount, from_edition)
    end,
    -- Big-safe version of the default modify (current + amount, then refresh the display).
    modify = function(self, amount, skip)
        if not skip then
            local cur = self.current
            if not NE.is_numeric(cur) then cur = self.default_value end
            local r = Big.add(cur, amount)
            if r.len == 1 then r = Big.to_number(r) end -- keep small values plain
            self.current = r
        end
        update_hand_text({ delay = 0 }, { [self.key] = self.current })
    end,
}

-- Steamodded adds the mod prefix; read the final key from the registered object.
NE.Score.AURA_KEY = (type(param) == 'table' and param.key) or 'ne_aura'
