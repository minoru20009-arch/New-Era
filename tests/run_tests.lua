-- New Era test runner (no game required).
-- Usage from the repo root:  NE_ROOT=$PWD luajit tests/run_tests.lua

package.path = (os.getenv('NE_ROOT') or '.') .. '/tests/?.lua;' .. package.path

local M = require('mocks')
M.install()
M.loc = M.load_loc('en-us')
M.load_mod()

local passed, failed = 0, 0
local current = ''

local function check(cond, msg)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        print(('  FAIL [%s] %s'):format(current, msg))
    end
end

local function eq(a, b, msg)
    check(a == b, ('%s (expected %s, got %s)'):format(msg, tostring(b), tostring(a)))
end

local function test(name, fn)
    current = name
    local ok, err = pcall(fn)
    if not ok then
        failed = failed + 1
        print(('  ERROR [%s] %s'):format(name, tostring(err)))
    end
end

local function dispatch(ctx) return NE.mod.calculate(NE.mod, ctx) end

-- ------------------------------------------------------------------------------------------
test('load', function()
    check(NE ~= nil, 'NE namespace exists')
    eq(NE.VERSION, M.version, 'version comes from mod metadata')
    eq(type(NE.mod.calculate), 'function', 'mod.calculate installed')
    eq(type(NE.mod.config_tab), 'function', 'config_tab installed')
    local info = false
    for _, l in ipairs(M.logs) do
        if l.level == 'info' and l.msg:find('New Era ' .. M.version .. ' loaded', 1, true) then info = true end
        check(l.level ~= 'error', 'no error logged during load: ' .. tostring(l.msg))
    end
    check(info, 'load message logged')
end)

test('rarities', function()
    eq(#SMODS.Rarity.list, 3, 'three rarities registered')
    local keys = {}
    for _, r in ipairs(SMODS.Rarity.list) do keys[r.key] = r end
    check(keys.unranked and keys.demonic and keys.heavenly, 'unranked/demonic/heavenly registered')
    eq(keys.unranked.pools.Joker, true, 'unranked in Joker pool')
    eq(keys.unranked.disable_if_empty, nil, 'unranked never disabled (last fallback)')
    eq(keys.heavenly.disable_if_empty, true, 'heavenly disabled when empty')
    M.start_run()
    G.GAME.round_resets.ante = 3
    eq(keys.heavenly:get_weight(0.03, SMODS.ObjectTypes.Joker), 0, 'heavenly weight 0 before ante 4')
    G.GAME.round_resets.ante = 4
    eq(keys.heavenly:get_weight(0.03, SMODS.ObjectTypes.Joker), 0.03, 'heavenly weight from ante 4')
end)

test('vanilla rarity weights', function()
    NE.config.hide_vanilla.jokers = true
    eq(SMODS.Rarities.Common:get_weight(0.7, SMODS.ObjectTypes.Joker), 0, 'Common weight 0 while hidden')
    eq(SMODS.Rarities.Rare:get_weight(0.05, { key = 'Other' }), 0.05, 'other object types untouched')
    NE.config.hide_vanilla.jokers = false
    eq(SMODS.Rarities.Common:get_weight(0.7, SMODS.ObjectTypes.Joker), 0.7, 'Common weight restored')
    NE.config.hide_vanilla.jokers = true
end)

test('pool hiding', function()
    local vanilla_joker = { key = 'j_joker', set = 'Joker' }
    local ne_joker = { key = 'j_ne_x', set = 'Joker', mod = { id = 'NewEra' } }
    local smods_owned = { key = 'j_y', set = 'Joker', mod = { id = 'Steamodded' } }
    local planet = { key = 'c_pluto', set = 'Planet' }
    local blind = { key = 'bl_ox', name = 'The Ox' }
    G.P_BLINDS.bl_ox = blind
    eq(SMODS.add_to_pool(vanilla_joker), false, 'vanilla joker hidden')
    eq(SMODS.add_to_pool(ne_joker), true, 'New Era joker kept')
    eq(SMODS.add_to_pool(smods_owned), false, 'Steamodded-owned vanilla joker hidden')
    eq(SMODS.add_to_pool(planet), true, 'planets visible by default')
    eq(SMODS.add_to_pool(blind), true, 'blinds visible by default')
    NE.config.hide_vanilla.planets = true
    NE.config.hide_vanilla.blinds = true
    eq(SMODS.add_to_pool(planet), true, 'planet still shown until replacements are ready')
    eq(SMODS.add_to_pool(blind), true, 'blind still shown until replacements are ready')
    NE.Pool.READY.planets = true
    NE.Pool.READY.blinds = true
    eq(SMODS.add_to_pool(planet), false, 'planet hidden when enabled and ready')
    eq(SMODS.add_to_pool(blind), false, 'blind hidden when enabled and ready')
    NE.Pool.READY.planets = false
    NE.Pool.READY.blinds = false
    NE.config.hide_vanilla.planets = false
    NE.config.hide_vanilla.blinds = false
    local custom = { key = 'j_z', set = 'Joker', mod = { id = 'NewEra' }, in_pool = function() return false end }
    eq(SMODS.add_to_pool(custom), false, 'original in_pool still respected')
end)

test('rarity mapping', function()
    local map = NE.Pool.map_joker_rarity
    eq(map(true, nil), 'ne_heavenly', 'legendary -> heavenly')
    eq(map(nil, 0.99), 'ne_demonic', 'wraith roll -> demonic')
    eq(map(nil, 0), 'ne_unranked', 'riff-raff roll -> unranked')
    eq(map(nil, 'Uncommon'), 'ne_unranked', 'Uncommon -> unranked')
    eq(map(nil, 'Rare'), 'ne_demonic', 'Rare -> demonic')
    eq(map(nil, 'ne_demonic'), 'ne_demonic', 'New Era key passes through')
    eq(map(nil, nil), nil, 'normal roll untouched')
end)

test('create_card wrapper', function()
    M.pool_results = {}
    local c = create_card('Joker', nil, true, nil, nil, nil, nil, 'sou')
    eq(c.rarity, 'ne_heavenly', 'Soul creates heavenly')
    eq(c.legendary, nil, 'legendary flag cleared')

    M.pool_results = { ne_heavenly = { 'empty_rarity' } }
    c = create_card('Joker', nil, true, nil)
    eq(c.rarity, 'ne_demonic', 'empty heavenly falls back to demonic')

    M.pool_results = { ne_heavenly = { 'empty_rarity' }, ne_demonic = { 'empty_rarity' } }
    c = create_card('Joker', nil, true, nil)
    eq(c.rarity, 'ne_unranked', 'falls back to unranked')

    M.pool_results = {}
    c = create_card('Joker', nil, nil, nil, nil, nil, 'j_joker')
    eq(c.forced_key, 'j_joker', 'forced keys untouched')
    eq(c.rarity, nil, 'forced key keeps nil rarity')

    c = create_card('Tarot', nil, nil, 0.99)
    eq(c.rarity, 0.99, 'other card types untouched')

    NE.config.hide_vanilla.jokers = false
    c = create_card('Joker', nil, true, nil)
    eq(c.legendary, true, 'no remap when vanilla jokers are shown')
    NE.config.hide_vanilla.jokers = true
end)

test('state', function()
    M.start_run()
    local s = G.GAME.newera
    check(type(s) == 'table', 'newera created on new run')
    eq(s.schema, 1, 'schema version')
    eq(s.next_uid, 1, 'uid counter starts at 1')

    -- A run saved before New Era existed.
    M.start_run({ GAME = { round_resets = { ante = 2 } } })
    check(type(G.GAME.newera) == 'table', 'newera added to old save')
    -- A partial table from an older schema keeps its values and gains new fields.
    M.start_run({ GAME = { round_resets = { ante = 2 }, newera = { next_uid = 42 } } })
    eq(G.GAME.newera.next_uid, 42, 'existing value kept')
    check(G.GAME.newera.rules and G.GAME.newera.rules.temp.hand, 'missing fields filled')

    -- Only plain data (saveable by STR_PACK).
    local function plain(t, depth)
        if depth > 8 then return false end
        if getmetatable(t) then return false end
        for k, v in pairs(t) do
            local tv = type(v)
            if tv == 'function' or tv == 'userdata' or tv == 'cdata' then return false end
            if tv == 'number' and (v ~= v or v == math.huge or v == -math.huge) then return false end
            if tv == 'table' and not plain(v, depth + 1) then return false end
        end
        return true
    end
    check(plain(G.GAME.newera, 0), 'newera contains only plain saveable data')
end)

test('uid', function()
    M.start_run()
    local card = { ability = {} }
    local id = NE.UID.of(card)
    eq(id, 1, 'first uid')
    eq(NE.UID.of(card), 1, 'uid is stable')
    eq(NE.UID.of({ ability = {} }), 2, 'next uid increments')
    G.jokers.cards = { card }
    eq(NE.UID.find(1), card, 'find in jokers')
    local extra = { cards = { { ability = { ne_uid = 99 } } } }
    NE.UID.register_area(function() return extra end)
    eq(NE.UID.find(99), extra.cards[1], 'find in registered area')
    eq(NE.UID.find(12345), nil, 'unknown uid')
end)

test('rules', function()
    M.start_run()
    NE.Rules.define('play_limit_bonus', 0)
    eq(NE.Rules.get('play_limit_bonus'), 0, 'default')
    NE.Rules.push_permanent('play_limit_bonus', 1)
    eq(NE.Rules.get('play_limit_bonus'), 1, 'permanent overrides default')
    NE.Rules.push_temp('play_limit_bonus', 2, 'ante')
    NE.Rules.push_temp('play_limit_bonus', 3, 'round')
    NE.Rules.push_temp('play_limit_bonus', 4, 'hand')
    eq(NE.Rules.get('play_limit_bonus'), 4, 'hand scope wins')
    dispatch({ after = true })
    eq(NE.Rules.get('play_limit_bonus'), 3, 'hand scope cleared after hand')
    dispatch({ end_of_round = true, individual = true })
    eq(NE.Rules.get('play_limit_bonus'), 3, 'per-card end_of_round ignored')
    dispatch({ end_of_round = true })
    eq(NE.Rules.get('play_limit_bonus'), 2, 'round scope cleared at end of round')
    dispatch({ ante_change = true })
    eq(NE.Rules.get('play_limit_bonus'), 1, 'ante scope cleared on ante change')
    NE.Rules.push_temp('x', 1, 'bogus')
    local logged = false
    for _, l in ipairs(M.logs) do if l.level == 'error' and l.msg:find('invalid scope') then logged = true end end
    check(logged, 'invalid scope rejected with an error log')
end)

test('hooks', function()
    local calls = 0
    NE.Hooks.on_context('ne_test_flag', 'a', function() calls = calls + 1; return { mult = 1 } end)
    NE.Hooks.on_context('ne_test_flag', 'b', function() error('boom') end)
    NE.Hooks.on_context('ne_test_flag', 'c', function() return { chips = 5 } end)
    local ret = dispatch({ ne_test_flag = true })
    eq(calls, 1, 'handler ran once')
    check(ret and ret.mult == 1 and ret.extra and ret.extra.chips == 5, 'effects merged, failing handler skipped')
    dispatch({ ne_test_flag = true })
    local warns = 0
    for _, l in ipairs(M.logs) do if l.level == 'warn' and l.msg:find('boom') then warns = warns + 1 end end
    eq(warns, 1, 'failing handler warned only once')
    NE.Hooks.on_context('ne_test_flag', 'a', function() return nil end)
    eq(dispatch({ unrelated = true }), nil, 'no handlers for unrelated context')
end)

test('cond', function()
    eq(NE.cond(nil, 'last_hand', false), false, 'unchanged without overrides')
    NE.register_cond_override('aizen', function(card, key, value) return true end)
    eq(NE.cond(nil, 'last_hand', false), true, 'override forces true')
    NE.unregister_cond_override('aizen')
    eq(NE.cond(nil, 'last_hand', nil), false, 'nil coerced to false')
end)

test('test jokers', function()
    eq(#SMODS.Joker.list, 9, 'nine test jokers')
    -- jokers that act in a scoring phase instead of joker_main
    local trigger = { test_aura = { ne_ascension = true }, test_phases = { ne_judgment = true } }
    for _, j in ipairs(SMODS.Joker.list) do
        check(j.rarity:match('^ne_'), j.key .. ' uses a New Era rarity')
        eq(j.atlas, 'frames', j.key .. ' uses the frames atlas')
        local card = { ability = { extra = j.config.extra } }
        local ret = j:calculate(card, trigger[j.key] or { joker_main = true })
        check(type(ret) == 'table' and next(ret), j.key .. ' returns an effect when triggered')
        eq(j:calculate(card, { before = true }), nil, j.key .. ' ignores other contexts')
        local vars = j:loc_vars({}, card).vars
        check(#vars >= 1, j.key .. ' has loc vars')
    end
    NE.config.debug.test_jokers = false
    eq(SMODS.Joker.list[1]:in_pool(), false, 'hidden when test jokers are off')
    NE.config.debug.test_jokers = true
    eq(SMODS.Joker.list[1]:in_pool(), true, 'shown when test jokers are on')
    for _, j in ipairs(SMODS.Joker.list) do
        if j.key == 'test_overflow' then eq(j:in_pool(), false, 'overflow joker never in pools') end
    end
end)

test('debug tools', function()
    local keys = {}
    for _, k in ipairs(SMODS.Keybind.list) do keys[k.key_pressed] = k end
    check(keys.f9 and keys.f10, 'F9 and F10 keybinds registered')

    NE.config.debug.enabled = true
    keys.f9:action()
    eq(NE.Debug.overlay.visible, true, 'F9 shows overlay')
    love.update(0.3)
    check(NE.Debug.overlay.text:find('New Era ' .. M.version, 1, true), 'overlay text refreshed')
    check(NE.Debug.overlay.text:find('Ante'), 'overlay shows run info')
    love.draw()
    check(M.update_calls >= 1 and M.draw_calls >= 1, 'original love.update/draw still called')
    keys.f9:action()
    eq(NE.Debug.overlay.visible, false, 'F9 hides overlay')

    NE.config.debug.enabled = false
    keys.f9:action()
    eq(NE.Debug.overlay.visible, false, 'F9 ignored when debug disabled')
    NE.config.debug.enabled = true

    M.last_overlay = nil
    keys.f10:action()
    check(M.last_overlay and M.last_overlay.definition, 'F10 opens the cheat menu')

    M.start_run()
    G.FUNCS.ne_cheat_money()
    eq(M.last_ease[1], 'dollars', 'money cheat')
    G.FUNCS.ne_cheat_give_demonic()
    eq(M.added_cards[#M.added_cards].key, 'j_ne_test_demonic', 'give joker cheat')
    G.jokers.cards = { {}, {}, {}, {}, {} }
    local before = #M.added_cards
    G.FUNCS.ne_cheat_give_demonic()
    eq(#M.added_cards, before, 'no joker added when slots are full')
    G.GAME.blind = { chips = 300 }
    G.GAME.chips = 0
    G.FUNCS.ne_cheat_meet_target()
    eq(G.GAME.chips, 300, 'score set to blind target')
    G.STATE = G.STATES.SHOP
    G.GAME.chips = 0
    G.FUNCS.ne_cheat_meet_target()
    eq(G.GAME.chips, 0, 'target cheat only works while selecting a hand')
end)

test('config tab', function()
    local ui = NE.mod.config_tab()
    eq(ui.n, 'ROOT', 'config tab returns a ROOT node')
    local toggles = 0
    for _, row in ipairs(ui.nodes) do
        if row.nodes and row.nodes[1] and row.nodes[1].n == 'toggle' then toggles = toggles + 1 end
    end
    eq(toggles, 5, 'five toggles')
end)

test('localization', function()
    local en, id = M.load_loc('en-us'), M.load_loc('id')
    local function keys(t, prefix, out)
        out = out or {}
        for k, v in pairs(t) do
            local path = prefix .. '.' .. tostring(k)
            if type(v) == 'table' and not (#v > 0) and next(v) then keys(v, path, out) else out[path] = true end
        end
        return out
    end
    local ke, ki = keys(en, ''), keys(id, '')
    for k in pairs(ke) do check(ki[k], 'id.lua has ' .. k) end
    for k in pairs(ki) do check(ke[k], 'en-us.lua has ' .. k) end

    -- Every localize('...') key used in src exists in the dictionary.
    local used = {}
    local p = io.popen('grep -rhoE "localize\\(\'[a-z0-9_]+\'\\)" ' .. M.root .. '/src')
    for line in p:lines() do used[line:match("'(.-)'")] = true end
    p:close()
    for k in pairs(used) do check(en.misc.dictionary[k], 'dictionary has ' .. k) end
    for _, j in ipairs(SMODS.Joker.list) do
        check(en.descriptions.Joker['j_ne_' .. j.key], 'joker text for ' .. j.key)
    end
end)

-- Phase 3: NE.Big
local big_spec = assert(loadfile(M.root .. '/tests/big_spec.lua'))()
big_spec({ test = test, check = check, eq = eq, M = M })

-- Phase 4: scoring operators, Aura, phases, currencies
local scoring_spec = assert(loadfile(M.root .. '/tests/scoring_spec.lua'))()
scoring_spec({ test = test, check = check, eq = eq, M = M })

print(('\n%d passed, %d failed'):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
