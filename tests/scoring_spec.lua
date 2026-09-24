-- Phase 4 tests: score operators, Aura, the ne_ascend calculation, scoring phases, currencies.
-- Hands are played with M.play_hand, which follows evaluate_play's context order.

return function(T)
    local test, check, eq, M = T.test, T.check, T.eq, T.M
    local B = NE.Big

    local function close(a, b, rel)
        rel = rel or 1e-12
        a, b = B.to_number(a), B.to_number(b)
        if a == b then return true end
        return math.abs(a - b) <= rel * math.max(math.abs(a), math.abs(b))
    end

    local function fresh_run()
        M.start_run()
        G.jokers.cards = {}
        G.GAME.blind = { chips = 300, chip_text = '300' }
        M.messages = {}
    end

    local function last_message()
        local m = M.messages[#M.messages]
        return m and m.extra and m.extra.message
    end

    ----------------------------------------------------------------------------------------------
    test('scoring: setup', function()
        fresh_run()
        local calc = G.GAME.current_scoring_calculation
        eq(calc and calc.key, 'ne_ascend', 'ne_ascend is the calculation of a new run')
        local p = SMODS.Scoring_Parameters.ne_aura
        check(p ~= nil, 'Aura parameter registered as ne_aura')
        eq(p.default_value, 1, 'Aura starts at 1')
        eq(SMODS.Calculation_Controls.ne_aura, true, 'Aura enabled by ne_ascend')
        for _, k in ipairs(NE.Score.KEYS) do
            eq(SMODS.Scoring_Parameter_Calculation[k], 'ne_aura', 'key ' .. k .. ' routed to Aura')
        end
        local pos = {}
        for i, k in ipairs(SMODS.calculation_keys) do pos[k] = i end
        check(pos.emult > pos.xmult and pos.echips > pos.xchips, 'New Era keys apply after x_mult/x_chips')

        -- a loaded run keeps its calculation; an old save on "multiply" is switched
        G.GAME.current_scoring_calculation = SMODS.Scoring_Calculations.multiply:new()
        NE.Score.ensure_calculation()
        eq(G.GAME.current_scoring_calculation.key, 'ne_ascend', 'multiply replaced by ne_ascend')
        local kept = G.GAME.current_scoring_calculation
        NE.Score.ensure_calculation()
        check(rawequal(G.GAME.current_scoring_calculation, kept), 'ne_ascend is not recreated')
    end)

    test('scoring: plain hands unchanged', function()
        fresh_run()
        local score = M.play_hand(10, 4)
        eq(score, 40, '10 x 4 with Aura 1')
        eq(type(score), 'number', 'small score stays a plain number')
        eq(G.GAME.chips, 40, 'added to the round score')
        eq(type(hand_chips), 'number', 'small chips stay a plain number (vanilla code paths)')
        eq(type(mult), 'number', 'small mult stays a plain number')

        -- promotion threshold
        mult = mod_mult(1e150)
        check(B.is(mult) and B.eq(SMODS.Scoring_Parameters.mult.current, 1e150), 'mult >= 1e100 becomes Big')
        mult = mod_mult(B.new(5))
        eq(mult, 5, 'small Big demoted to a number')
        hand_chips = mod_chips(-1e120)
        check(B.is(hand_chips), 'negative values promote by magnitude')
    end)

    test('scoring: operators', function()
        fresh_run()
        M.add_joker('test_emult')
        eq(B.to_number(M.play_hand(10, 4)), 160, '^2 Mult: 10 x 4^2')
        eq(last_message(), '^2 Mult', '^Mult message')

        fresh_run()
        M.add_joker('test_eemult')
        eq(B.to_number(M.play_hand(10, 4)), 2560, '^^2 Mult: 10 x 4^^2 (=256)')

        fresh_run()
        M.add_joker('test_hypermult')
        local expected = B.mul(10, B.arrow(4, 3, 1.1))
        check(close(M.play_hand(10, 4), expected), '{3}1.1 Mult matches NE.Big.arrow(4, 3, 1.1)')
        eq(last_message(), '{3}1.1 Mult', 'hyper message uses {n} for n >= 3')

        -- order: x_mult (Steamodded) is applied before ^ (New Era) inside one effect
        fresh_run()
        G.jokers.cards[1] = { config = { center = { calculate = function(_, card, context)
            if context.joker_main then return { xmult = 3, emult = 2 } end
        end } }, ability = {} }
        eq(B.to_number(M.play_hand(1, 2)), 36, '(2 x 3) ^ 2 = 36')

        -- echips and hypermult with named args
        fresh_run()
        G.jokers.cards[1] = { config = { center = { calculate = function(_, card, context)
            if context.joker_main then return { echips = 3, hypermult = { arrows = 2, amount = 2 } } end
        end } }, ability = {} }
        eq(B.to_number(M.play_hand(10, 3)), 1000 * 27, '10^3 x 3^^2')
    end)

    test('scoring: Aura in the Ascension phase', function()
        fresh_run()
        M.add_joker('test_aura')
        local score = M.play_hand(10, 4)
        check(close(score, 40 ^ 1.5), '(10 x 4) ^ 1.5')
        eq(last_message(), '+0.5 Aura', 'Aura message')
        eq(SMODS.Scoring_Parameters.ne_aura.current, 1, 'Aura back to 1 after the hand')

        fresh_run()
        G.jokers.cards[1] = { config = { center = { calculate = function(_, card, context)
            if context.ne_ascension then return { xaura = 3 } end
        end } }, ability = {} }
        eq(B.to_number(M.play_hand(2, 5)), 1000, 'xaura 3: (2 x 5) ^ 3')

        fresh_run()
        G.jokers.cards[1] = { config = { center = { calculate = function(_, card, context)
            if context.ne_ascension then return { aura = -0.5 } end
        end } }, ability = {} }
        check(close(M.play_hand(10, 10), 10), 'negative Aura: 100 ^ 0.5')
        eq(last_message(), '-0.5 Aura', 'negative Aura message')
    end)

    test('scoring: Big values and precision', function()
        fresh_run()
        M.add_joker('test_overflow')
        M.add_joker('test_emult')
        local score = M.play_hand(10, 4)
        -- chips 10 * 1e155, mult (4 * 1e155) ^ 2
        local expected = B.mul(1e156, B.pow(4e155, 2))
        check(B.is(score) and close(B.log10_num(score), B.log10_num(expected)), 'overflowing hand scored as Big')
        check(B.is(G.GAME.chips) and G.GAME.chips > 1e308, 'round score above 1e308')

        -- a drop of many orders of magnitude must not cancel to 0 (Steamodded syncs by difference)
        fresh_run()
        mult = mod_mult(B.new('1e500'))
        NE.Score.set_mult(B.pow(mult, 0.5))
        check(close(B.log10_num(mult), 250), 'mult 1e500 ^ 0.5 = 1e250')
        check(B.eq(SMODS.Scoring_Parameters.mult.current, mult), 'parameter current equals the global exactly')

        -- mod_mult always syncs the parameter to the returned value
        mult = mod_mult(7)
        check(mult == 7 and SMODS.Scoring_Parameters.mult.current == 7, 'mod_mult syncs the parameter')
        hand_chips = mod_chips(math.huge)
        check(B.flags(hand_chips) == 0 and close(hand_chips, B.MAXD), 'overflowed chips clamped, not saturated')

        -- hand_score helper
        eq(NE.Score.hand_score(3, 4, 1), 12, 'hand_score plain')
        check(close(NE.Score.hand_score(3, 4, 2), 144), 'hand_score with Aura 2')
        eq(NE.Score.hand_score(3, 4, '?'), 12, 'non-numeric Aura ignored')
        eq(NE.Score.hand_score('x', 4, 1), 0, 'non-numeric chips -> 0')
    end)

    test('scoring: phases in order', function()
        fresh_run()
        M.add_joker('test_phases')
        M.contexts = {}
        M.play_hand(10, 4)
        eq(NE.Phases.trace.last, 'omen > chain(0) > ascension > judgment', 'phase order')
        local seen = {}
        for i, c in ipairs(M.contexts) do
            if c.ne_phase and not seen[c.ne_phase] then seen[c.ne_phase] = i end
        end
        check(seen.omen and seen.ascension and seen.judgment, 'phase contexts dispatched')
        check(seen.omen < seen.ascension and seen.ascension < seen.judgment, 'omen < ascension < judgment')
        local msgs = {}
        for _, m in ipairs(M.messages) do if m.extra and m.extra.message then msgs[#msgs + 1] = m.extra.message end end
        local text = table.concat(msgs, ',')
        check(text:find('Omen!', 1, true) and text:find('Ascension!', 1, true), 'phase messages shown: ' .. text)
        eq(NE.Currency.get('divinity'), 1, 'Judgment gave +1 Divinity')
        check(text:find('+1 Divinity', 1, true), 'currency message')

        -- chain fires once per secondary formation (Phase 6 provides them)
        local old = NE.Phases.secondaries
        NE.Phases.secondaries = function() return { 'a', 'b' } end
        M.play_hand(10, 4)
        eq(NE.Phases.trace.last, 'omen > chain(2) > ascension > judgment', 'chain reached with 2 formations')
        local chains = 0
        for _, c in ipairs(M.contexts) do if c.ne_chain then chains = chains + 1 end end
        eq(chains, 2, 'ne_chain dispatched once per secondary formation')
        NE.Phases.secondaries = old
    end)

    test('scoring: judgment context', function()
        fresh_run()
        G.GAME.chips = 250
        local got
        G.jokers.cards[1] = { config = { center = { calculate = function(_, card, context)
            if context.ne_judgment then
                got = { score = context.score, total = context.total, overkill = context.overkill,
                    rule = NE.Rules.get('test_rule') }
            end
            if context.joker_main then NE.Rules.push_temp('test_rule', true, 'hand') end
        end } }, ability = {} }
        M.play_hand(10, 10)
        eq(B.to_number(got.score), 100, 'context.score')
        eq(B.to_number(got.total), 350, 'context.total = round score after the hand')
        eq(B.to_number(got.overkill), 50, 'context.overkill above the 300 target')
        eq(got.rule, true, 'hand rules still active during Judgment')
        eq(NE.Rules.get('test_rule'), nil, 'hand rules cleared after Judgment')
    end)

    test('scoring: currencies', function()
        fresh_run()
        local C = NE.Currency
        eq(C.add('divinity', 2.9), 2, 'whole units only')
        eq(C.add('divinity', -5), -2, 'never below 0')
        eq(C.add('corruption', 150), 100, 'corruption meter capped at 100')
        eq(C.add('time', 25), 10, 'time capped at time_cap')
        eq(C.max('time'), 10, 'time cap')
        check(not C.spend('divinity', 1), 'cannot spend what is missing')
        C.add('divinity', 3)
        check(C.spend('divinity', 2) and C.get('divinity') == 1, 'spend')
        eq(C.add('nothing', 3), 0, 'unknown currency ignored')
        eq(C.add('divinity', B.new('1e500')), C.CAP - 1, 'Big amounts clamp to the cap')

        local changed = {}
        G.jokers.cards[1] = { config = { center = { calculate = function(_, card, context)
            if context.ne_currency_changed then changed[#changed + 1] = context.currency .. context.amount end
        end } }, ability = {} }
        C.add('time', -3)
        eq(changed[1], 'time-3', 'ne_currency_changed context')

        -- saved with the run
        local saved = STR_UNPACK(STR_PACK(recursive_table_cull({ GAME = G.GAME })))
        eq(saved.GAME.newera.currency.time, 7, 'currency saved with the run')
    end)

    test('scoring: Aura UI', function()
        fresh_run()
        local ui = NE.Score.hand_ui(0.4)
        local ids = {}
        local function walk(n)
            if type(n) ~= 'table' then return end
            if n.config and n.config.id then ids[n.config.id] = n end
            for _, c in ipairs(n.nodes or {}) do walk(c) end
        end
        walk(ui)
        check(ids.hand_chips_container and ids.hand_operator_container and ids.hand_mult_container, 'Steamodded container ids kept')
        check(ids.hand_ne_aura and ids.hand_ne_aura_area, 'Aura box present')
        eq(G.GAME.current_round.current_hand.ne_aura_text, '', 'Aura text starts empty')

        local e = { config = { object = { scale = 1, update_text = function() end } } }
        local box = { config = {} }
        G.GAME.current_round.current_hand.ne_aura = 1.5
        G.FUNCS.ne_aura_UI_set(e)
        G.FUNCS.ne_aura_box_UI_set(box)
        eq(G.GAME.current_round.current_hand.ne_aura_text, '^1.5', 'Aura text when not 1')
        check(rawequal(box.config.colour, NE.C.AURA_BOX), 'Aura box coloured')
        G.GAME.current_round.current_hand.ne_aura = 1
        G.FUNCS.ne_aura_UI_set(e)
        G.FUNCS.ne_aura_box_UI_set(box)
        eq(G.GAME.current_round.current_hand.ne_aura_text, '', 'Aura text hidden at 1')
        check(rawequal(box.config.colour, G.C.CLEAR), 'Aura box hidden at 1')
        G.GAME.current_round.current_hand.ne_aura = B.new('1e500')
        G.FUNCS.ne_aura_UI_set(e)
        eq(G.GAME.current_round.current_hand.ne_aura_text, '^1.00e500', 'Big Aura text')
    end)

    test('scoring: cheats and overlay', function()
        fresh_run()
        G.jokers.config.card_limit = 20
        for _, id in ipairs({ 'emult', 'eemult', 'hypermult', 'aura', 'phases' }) do
            G.FUNCS['ne_cheat_give_' .. id]()
            eq(M.added_cards[#M.added_cards].key, 'j_ne_test_' .. id, 'give ' .. id)
        end
        G.FUNCS.ne_cheat_currency()
        eq(NE.Currency.get('corruption'), 5, 'currency cheat')
        NE.config.debug.enabled = true
        NE.Debug.overlay.visible = true
        NE.Debug.overlay.since_refresh = 1
        M.play_hand(10, 4)
        love.update(0.3)
        check(NE.Debug.overlay.text:find('Calc ne_ascend', 1, true), 'overlay shows the calculation')
        check(NE.Debug.overlay.text:find('Phases (last hand): omen', 1, true), 'overlay shows the phase trace')
        NE.Debug.overlay.visible = false
    end)
end
