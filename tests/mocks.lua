-- Minimal stand-ins for Steamodded, the game globals and LÖVE, so New Era modules can be
-- loaded and tested with a plain LuaJIT interpreter (no game required).
-- Only the functions New Era actually calls are mocked; behaviour mirrors the real
-- implementations that were checked against Steamodded 26.924.0~dev and Balatro 1.0.1o.

local M = {}

M.root = assert(os.getenv('NE_ROOT'), 'set NE_ROOT to the repository root')
M.logs = {}
M.sounds = {}
M.created_cards = {}
M.added_cards = {}
M.pool_results = {} -- rarity -> list returned by get_current_pool

local function read_file(path)
    local f = io.open(path, 'rb')
    if not f then return nil, 'cannot open ' .. path end
    local s = f:read('*a')
    f:close()
    return s
end
M.read_file = read_file

local function mod_version()
    local json = assert(read_file(M.root .. '/NewEra.json'))
    return assert(json:match('"version"%s*:%s*"(.-)"'), 'version in NewEra.json')
end
M.version = mod_version()

-- Mini Lovely: applies the pattern patches from lovely/*.toml to test sources -------------------
-- Only what New Era's patch files use: [[patches]] + [patches.pattern] with target, pattern,
-- position (at/before/after), payload ('''...''' or "..."), match_indent, times.

local function parse_patch_file(src)
    local patches, cur = {}, nil
    local lines = {}
    for line in (src .. '\n'):gmatch('(.-)\r?\n') do lines[#lines + 1] = line end
    local li = 1
    while li <= #lines do
        local line = lines[li]
        local trimmed = line:match('^%s*(.-)%s*$')
        if trimmed == '[[patches]]' then
            cur = {}
            patches[#patches + 1] = cur
        elseif cur and trimmed:match('^[%w_]+%s*=') then
            local key, rest = trimmed:match('^([%w_]+)%s*=%s*(.*)$')
            local value
            if rest:sub(1, 3) == "'''" then
                local body = rest:sub(4)
                local parts = {}
                if body:find("'''", 1, true) then
                    value = body:sub(1, body:find("'''", 1, true) - 1)
                else
                    if body ~= '' then parts[#parts + 1] = body end
                    li = li + 1
                    while li <= #lines and not lines[li]:find("'''", 1, true) do
                        parts[#parts + 1] = lines[li]
                        li = li + 1
                    end
                    local last = lines[li] or ''
                    local tail = last:sub(1, last:find("'''", 1, true) - 1)
                    if tail ~= '' then parts[#parts + 1] = tail end
                    value = table.concat(parts, '\n')
                end
            elseif rest:sub(1, 1) == '"' then
                value = rest:match('^"(.*)"$'):gsub('\\"', '"')
            elseif rest:sub(1, 1) == "'" then
                value = rest:match("^'(.*)'$")
            elseif rest == 'true' or rest == 'false' then
                value = rest == 'true'
            else
                value = tonumber(rest)
            end
            cur[key] = value
        end
        li = li + 1
    end
    return patches
end

local function trim(s) return s:match('^%s*(.-)%s*$') end

-- Applies every patch whose target equals `target` to `src`. Returns the new source and a list
-- of {pattern, matches} for patches that targeted it.
function M.apply_patches(target, src)
    local results = {}
    local dir = M.root .. '/lovely'
    local p = io.popen('ls "' .. dir .. '"/*.toml 2>/dev/null')
    local files = {}
    for f in p:lines() do files[#files + 1] = f end
    p:close()
    for _, file in ipairs(files) do
        for _, patch in ipairs(parse_patch_file(assert(read_file(file)))) do
            if patch.target == target and patch.pattern then
                local lines = {}
                for line in (src .. '\n'):gmatch('(.-)\n') do lines[#lines + 1] = line end
                local out, matches = {}, 0
                local want = trim(patch.pattern)
                for _, line in ipairs(lines) do
                    if trim(line) == want and (not patch.times or matches < patch.times) then
                        matches = matches + 1
                        local indent = patch.match_indent and line:match('^(%s*)') or ''
                        local payload = {}
                        for pl in (patch.payload .. '\n'):gmatch('(.-)\n') do payload[#payload + 1] = indent .. pl end
                        if patch.position == 'before' then
                            for _, pl in ipairs(payload) do out[#out + 1] = pl end
                            out[#out + 1] = line
                        elseif patch.position == 'after' then
                            out[#out + 1] = line
                            for _, pl in ipairs(payload) do out[#out + 1] = pl end
                        else
                            for _, pl in ipairs(payload) do out[#out + 1] = pl end
                        end
                    else
                        out[#out + 1] = line
                    end
                end
                src = table.concat(out, '\n')
                results[#results + 1] = { pattern = want, matches = matches, file = file }
            end
        end
    end
    return src, results
end

-- Test sources containing the exact anchor lines of the game / Steamodded code that New Era
-- patches (written for these tests; they only mirror the behaviour around the anchors).
M.patch_sources = {
    ['functions/misc_functions.lua'] = [[
function recursive_table_cull(t)
  local ret_t = {}
  for k, v in pairs(t) do
      if type(v) == 'table' then
          if v.is and v:is(Object) then ret_t[k] = '"MANUAL_REPLACE"'
          else ret_t[k] = recursive_table_cull(v)
          end
      else ret_t[k] = v end
  end
  return ret_t
end

function test_modulate_sound()
  G.ARGS.score_intensity = G.ARGS.score_intensity or {}
  local all_numbers = true
  for name, parameter in pairs(SMODS.Scoring_Parameters) do
    if type(G.GAME.current_round.current_hand[name]) ~= 'number' then all_numbers = false end
  end
  G.ARGS.score_intensity.earned_score = all_numbers and SMODS.calculate_round_score(true) or 0
  G.ARGS.score_intensity.required_score = G.GAME.blind and G.GAME.blind.chips or 0
  return all_numbers
end
]],
    ['functions/common_events.lua'] = [[
function test_hand_delta(vals, name)
        local delta = (type(vals[name]) == 'number' and type(G.GAME.current_round.current_hand[name]) == 'number') and (vals[name] - G.GAME.current_round.current_hand[name]) or 0
        return delta
end
]],
    ['=[SMODS _ "src/ui.lua"]'] = [[
function test_hand_type_UI_set(e)
    if not G.TAROT_INTERRUPT_PULSE then G.FUNCS.text_super_juice(e, math.max(0,math.floor(math.log10(type(G.GAME.current_round.current_hand[e.config.type]) == 'number' and math.abs(G.GAME.current_round.current_hand[e.config.type]) or 1)))) end
end
]],
}

-- Loads the patch sources, patched like Lovely would (or unpatched when raw is true).
-- `only`: reload a single target (reloading all would drop New Era's Lua wraps of them).
function M.load_patch_sources(raw, only)
    local kept = {}
    for _, r in ipairs(M.patch_results or {}) do
        if only and r.target ~= only then kept[#kept + 1] = r end
    end
    M.patch_results = kept
    for target, src in pairs(M.patch_sources) do
        if only and target ~= only then goto continue end
        local patched = src
        if not raw then
            local results
            patched, results = M.apply_patches(target, src)
            for _, r in ipairs(results) do r.target = target; M.patch_results[#M.patch_results + 1] = r end
        end
        assert(loadstring(patched, '=' .. target))()
        ::continue::
    end
end

-- Scoring engine stand-in ---------------------------------------------------------------------------
-- Mirrors Steamodded's scoring objects as they run in game (checked against the Steamodded
-- 26.924.0~dev source and a simulated Lovely dump of functions/state_events.lua):
-- Scoring_Parameter (modify / calc_effect for chips & mult keys, key routing), mod_chips /
-- mod_mult with the parameter sync, Scoring_Calculation new/load, calculate_context order
-- (jokers first, then mods) and an event queue.
function M.install_scoring()
    M.messages = {}
    M.events = {}
    percent, percent_delta = 0.3, 0.08

    -- event manager: events run when M.flush_events() is called (like the game's queue)
    Event = function(args) return args end
    G.E_MANAGER = {
        queues = {},
        add_event = function(self, ev, queue) M.events[#M.events + 1] = ev end,
        clear_queue = function(self) end,
    }
    function M.flush_events()
        local i = 1
        while i <= #M.events do
            local ev = M.events[i]
            if ev.func then ev.func() end
            i = i + 1
        end
        M.events = {}
    end

    card_eval_status_text = function(card, eval_type, amt, pct, dir, extra)
        M.messages[#M.messages + 1] = { card = card, type = eval_type, amt = amt, extra = extra }
    end
    juice_card = function() end
    update_hand_text = function(config, vals)
        M.last_hand_text = vals
        local hand = G.GAME and G.GAME.current_round and G.GAME.current_round.current_hand
        if hand then for k, v in pairs(vals) do hand[k] = v end end
    end

    SMODS.Calculation_Controls = { chips = true, mult = true }
    SMODS.Scoring_Parameters = {}
    SMODS.Scoring_Parameter_Calculation = {}
    SMODS.scoring_parameter_keys = {
        'chips', 'h_chips', 'chip_mod', 'mult', 'h_mult', 'mult_mod',
        'x_chips', 'xchips', 'Xchip_mod', 'x_mult', 'Xmult', 'xmult', 'x_mult_mod', 'Xmult_mod',
    }
    SMODS.other_calculation_keys = { 'message', 'func' }
    local function rebuild_keys()
        SMODS.calculation_keys = {}
        for _, k in ipairs(SMODS.scoring_parameter_keys) do SMODS.calculation_keys[#SMODS.calculation_keys + 1] = k end
        for _, k in ipairs(SMODS.other_calculation_keys) do SMODS.calculation_keys[#SMODS.calculation_keys + 1] = k end
    end
    rebuild_keys()

    local ParamBase = {}
    ParamBase.__index = ParamBase
    function ParamBase:modify(amount)
        self.current = self.current + amount
        update_hand_text({ delay = 0 }, { [self.key] = self.current })
    end
    SMODS.Scoring_Parameter = function(def)
        if not def.prefix_config and SMODS.current_mod and def.key ~= 'chips' and def.key ~= 'mult' then
            def.key = 'ne_' .. def.key
        end
        setmetatable(def, ParamBase)
        def.current = def.default_value
        SMODS.Scoring_Parameters[def.key] = def
        for _, k in ipairs(def.calculation_keys or {}) do
            SMODS.scoring_parameter_keys[#SMODS.scoring_parameter_keys + 1] = k
            SMODS.Scoring_Parameter_Calculation[k] = def.key
        end
        rebuild_keys()
        if SMODS.Calculation_Controls[def.key] == nil then SMODS.Calculation_Controls[def.key] = false end
        return def
    end

    -- chips and mult as defined by Steamodded (modify/calc_effect arithmetic kept identical)
    SMODS.Scoring_Parameter({
        key = 'chips', default_value = 0,
        calculation_keys = {},
        modify = function(self, amount, skip)
            if not skip then hand_chips = mod_chips(self.current + amount) end
            self.current = (hand_chips or 0) + (skip or 0)
            update_hand_text({ delay = 0 }, { chips = self.current })
        end,
        calc_effect = function(self, effect, scored_card, key, amount)
            if (key == 'chips' or key == 'h_chips' or key == 'chip_mod') and amount then
                self:modify(amount); return true
            end
            if (key == 'x_chips' or key == 'xchips' or key == 'Xchip_mod') and amount ~= 1 then
                self:modify(hand_chips * (amount - 1)); return true
            end
        end,
    })
    SMODS.Scoring_Parameter({
        key = 'mult', default_value = 0,
        calculation_keys = {},
        modify = function(self, amount, skip)
            if not skip then mult = mod_mult(self.current + amount) end
            self.current = (mult or 0) + (skip or 0)
            update_hand_text({ delay = 0 }, { mult = self.current })
        end,
        calc_effect = function(self, effect, scored_card, key, amount)
            if (key == 'mult' or key == 'h_mult' or key == 'mult_mod') and amount then
                self:modify(amount); return true
            end
            if (key == 'x_mult' or key == 'xmult' or key == 'Xmult' or key == 'x_mult_mod' or key == 'Xmult_mod') and amount ~= 1 then
                self:modify(mult * (amount - 1)); return true
            end
        end,
    })
    for _, k in ipairs({ 'chips', 'h_chips', 'chip_mod', 'x_chips', 'xchips', 'Xchip_mod' }) do
        SMODS.Scoring_Parameter_Calculation[k] = 'chips'
    end
    for _, k in ipairs({ 'mult', 'h_mult', 'mult_mod', 'x_mult', 'Xmult', 'xmult', 'x_mult_mod', 'Xmult_mod' }) do
        SMODS.Scoring_Parameter_Calculation[k] = 'mult'
    end

    -- vanilla mod_chips/mod_mult with Steamodded's sync (functions/misc_functions.lua, dump)
    mod_chips = function(_chips)
        if G.GAME.modifiers and G.GAME.modifiers.chips_dollar_cap then
            _chips = math.min(_chips, math.max(G.GAME.dollars, 0))
        end
        if _chips ~= hand_chips or _chips ~= SMODS.Scoring_Parameters.chips.current then
            SMODS.Scoring_Parameters.chips:modify(nil, _chips - (hand_chips or 0))
        end
        return _chips
    end
    mod_mult = function(_mult)
        if _mult ~= mult or _mult ~= SMODS.Scoring_Parameters.mult.current then
            SMODS.Scoring_Parameters.mult:modify(nil, _mult - (mult or 0))
        end
        return _mult
    end

    SMODS.calculate_individual_effect = function(effect, scored_card, key, amount, from_edition)
        if SMODS.Scoring_Parameter_Calculation[key] then
            return SMODS.Scoring_Parameters[SMODS.Scoring_Parameter_Calculation[key]]:calc_effect(effect, scored_card, key, amount, from_edition)
        end
        if key == 'message' then
            card_eval_status_text(scored_card, 'extra', nil, nil, nil, effect)
            return true
        end
        if key == 'func' then effect.func(); return true end
    end
    SMODS.calculate_effect = function(effect, scored_card)
        for _, key in ipairs(SMODS.calculation_keys) do
            if effect[key] then SMODS.calculate_individual_effect(effect, scored_card, key, effect[key]) end
        end
    end

    -- jokers (G.jokers.cards, each { config = { center = def }, ability = ... }) then mods
    -- returns the flags of the effects (Steamodded's amount_return_flags that New Era uses),
    -- updating the context like SMODS.update_context_flags
    M.contexts = {}
    local FLAG_KEYS = { 'replace_scoring_name', 'replace_display_name', 'replace_poker_hands' }
    local function apply(eff, card, context, flags)
        SMODS.calculate_effect(eff, card)
        for _, k in ipairs(FLAG_KEYS) do
            if eff[k] ~= nil then flags[k] = eff[k] end
        end
        if context.evaluate_poker_hand then
            if eff.replace_scoring_name then
                context.scoring_name = eff.replace_scoring_name
                context.display_name = eff.replace_scoring_name
            end
            if eff.replace_display_name then context.display_name = eff.replace_display_name end
        end
    end
    SMODS.calculate_context = function(context)
        M.contexts[#M.contexts + 1] = context
        local flags = {}
        for _, card in ipairs(G.jokers and G.jokers.cards or {}) do
            local center = card.config and card.config.center
            if center and center.calculate then
                local eff = center:calculate(card, context)
                if type(eff) == 'table' then apply(eff, card, context, flags) end
            end
        end
        if NE and NE.mod and NE.mod.calculate then
            local eff = NE.mod.calculate(NE.mod, context)
            if type(eff) == 'table' then apply(eff, nil, context, flags) end
        end
        return flags
    end

    local CalcBase = {}
    CalcBase.__index = CalcBase
    function CalcBase:new(def)
        def = def or {}
        for key in pairs(SMODS.Calculation_Controls) do SMODS.Calculation_Controls[key] = false end
        for _, key in ipairs(self.parameters) do
            SMODS.Calculation_Controls[key] = true
            if G.GAME and G.GAME.current_round then
                G.GAME.current_round.current_hand[key] = SMODS.Scoring_Parameters[key].default_value
            end
        end
        return setmetatable(def, { __index = self })
    end
    SMODS.Scoring_Calculations = {}
    SMODS.Scoring_Calculation = function(def)
        def.key = (def.key == 'multiply') and def.key or ('ne_' .. def.key)
        def.parameters = def.parameters or { 'chips', 'mult' }
        setmetatable(def, CalcBase)
        SMODS.Scoring_Calculations[def.key] = def
        return def
    end
    SMODS.Scoring_Calculation({ key = 'multiply', func = function(self, chips, mult, flames) return chips * mult end })

    SMODS.get_scoring_parameter = function(key, flames)
        if flames then return G.GAME.current_round.current_hand[key] end
        return SMODS.Scoring_Parameters[key].current or SMODS.Scoring_Parameters[key].default_value
    end
    SMODS.calculate_round_score = function(flames)
        local calc = G.GAME.current_scoring_calculation or SMODS.Scoring_Calculations.multiply
        return calc:func(SMODS.get_scoring_parameter('chips', flames), SMODS.get_scoring_parameter('mult', flames), flames)
    end

    -- UI builders used by the ne_ascend layout
    DynaText = function(args) return { args = args, update_text = function() end } end
    SMODS.GUI = {
        score_container = function(args) return { n = 'R', config = { id = 'hand_' .. args.type .. '_area', w = args.w }, args = args } end,
        operator = function(scale) return { n = 'C', config = { id = 'hand_operator_container' } } end,
    }
    G.LANGUAGES = { ['en-us'] = { font = {} } }
end

-- Plays one hand through the same context sequence as evaluate_play (Steamodded dump):
-- press_play (+ queued Omen) -> base chips/mult -> initial_scoring_step -> joker_main ->
-- final_scoring_step -> score -> ease_to -> after -> parameter reset.
function M.play_hand(base_chips, base_mult)
    G.play = G.play or { cards = {} }
    SMODS.calculate_context({ press_play = true })
    M.flush_events()
    mult = mod_mult(base_mult)
    hand_chips = mod_chips(base_chips)
    SMODS.calculate_context({ initial_scoring_step = true, full_hand = G.play.cards, scoring_hand = {} })
    SMODS.calculate_context({ joker_main = true, full_hand = G.play.cards, scoring_hand = {} })
    SMODS.calculate_context({ final_scoring_step = true, full_hand = G.play.cards, scoring_hand = {} })
    local score = SMODS.calculate_round_score()
    local ease_to = G.GAME.chips + math.floor(score)
    SMODS.last_hand_score = SMODS.calculate_round_score()
    SMODS.calculate_context({ after = true, full_hand = G.play.cards, scoring_hand = {} })
    G.GAME.chips = ease_to
    for _, p in pairs(SMODS.Scoring_Parameters) do p.current = p.default_value end
    return score
end

-- Adds a joker card for a registered SMODS.Joker definition (key without prefix).
function M.add_joker(key)
    for _, def in ipairs(SMODS.Joker.list) do
        if def.key == key then
            local extra = {}
            for k, v in pairs(def.config.extra or {}) do extra[k] = v end
            local card = { config = { center = def }, ability = { extra = extra } }
            G.jokers.cards[#G.jokers.cards + 1] = card
            return card
        end
    end
    error('no joker ' .. key)
end

-- A callable "class": calling it records the definition and returns it.
local function registry(name, on_register)
    local obj_table = {}
    local cls = setmetatable({ obj_table = obj_table, list = {} }, {
        __call = function(self, def)
            self.list[#self.list + 1] = def
            if on_register then on_register(def, obj_table) end
            return def
        end,
    })
    return cls
end

function M.install()
    -- logging -----------------------------------------------------------------------------
    local function logger(level)
        return function(msg, name) M.logs[#M.logs + 1] = { level = level, msg = msg, name = name } end
    end
    sendDebugMessage = logger('debug')
    sendInfoMessage = logger('info')
    sendWarnMessage = logger('warn')
    sendErrorMessage = logger('error')

    -- LÖVE --------------------------------------------------------------------------------
    local clock = 0
    local font = {
        getWidth = function(_, s) return #s * 7 end,
        getHeight = function() return 15 end,
    }
    love = {
        timer = {
            getTime = function() clock = clock + 0.001; return clock end,
            getFPS = function() return 60 end,
        },
        graphics = setmetatable({
            newFont = function() return font end,
        }, { __index = function(t, k)
            local f = function() end
            rawset(t, k, f)
            return f
        end }),
    }
    love.update = function(dt) M.update_calls = (M.update_calls or 0) + 1 end
    love.draw = function() M.draw_calls = (M.draw_calls or 0) + 1 end

    -- game globals --------------------------------------------------------------------------
    HEX = function(h) return { h } end
    localize = function(key, set)
        if type(key) == 'string' and (set == 'poker_hands' or set == 'poker_hand_descriptions') then
            local t = M.loc and M.loc.misc and M.loc.misc[set]
            return (t and t[key]) or 'ERROR'
        end
        if type(key) == 'table' and key.type == 'variable' then
            local v = M.loc and M.loc.misc and M.loc.misc.v_dictionary and M.loc.misc.v_dictionary[key.key]
            if not v then return 'ERROR' end
            return (v:gsub('#(%d+)#', function(i)
                local x = key.vars and key.vars[tonumber(i)]
                if type(x) == 'number' then return number_format(x, 1000000) end
                return tostring(x)
            end))
        end
        local d = M.loc and M.loc.misc and M.loc.misc.dictionary
        return (d and d[key]) or 'ERROR'
    end
    create_badge = function(text, col, tcol, scale) return { text = text } end
    create_toggle = function(args) return { n = 'toggle', args = args } end
    UIBox_button = function(args) return { n = 'R', args = args } end
    create_UIBox_generic_options = function(args) return { n = 'ROOT', args = args } end
    play_sound = function(name) M.sounds[#M.sounds + 1] = name end
    ease_dollars = function(n) M.last_ease = { 'dollars', n } end
    ease_hands_played = function(n) M.last_ease = { 'hands', n } end
    ease_discard = function(n) M.last_ease = { 'discard', n } end
    ease_ante = function(n) M.last_ease = { 'ante', n } end

    get_current_pool = function(_type, rarity, legendary, append)
        return M.pool_results[rarity] or { 'j_some_joker' }
    end
    create_card = function(_type, area, legendary, _rarity, skip, soulable, forced_key, key_append)
        local c = { _type = _type, legendary = legendary, rarity = _rarity, forced_key = forced_key }
        M.created_cards[#M.created_cards + 1] = c
        return c
    end

    -- Number helpers with the behaviour of the game's versions (as patched by Steamodded).
    -- number_format follows the same steps, including the "%.4g" round trip that breaks for
    -- values near the largest double.
    round_number = function(num, precision)
        precision = 10 ^ (precision or 0)
        return math.floor(num * precision + 0.4999999999999994) / precision
    end
    number_format = function(num, e_switch_point)
        if type(num) ~= 'number' then return num end
        local sign = num < 0 and '-' or ''
        num = math.abs(num)
        if num >= (e_switch_point or 1e11) then
            local x = string.format('%.4g', num)
            local fac = math.floor(math.log(tonumber(x), 10))
            if num == math.huge then return sign .. 'naneinf' end
            local mant = round_number(x / (10 ^ fac), 3)
            if mant >= 10 then
                mant = mant / 10
                fac = fac + 1
            end
            return sign .. string.format(fac >= 100 and '%.1fe%i' or fac >= 10 and '%.2fe%i' or '%.3fe%i', mant, fac)
        end
        local formatted
        if num ~= math.floor(num) and num < 100 then
            formatted = string.format(num >= 10 and '%.1f' or '%.2f', num)
            if formatted:sub(-1) == '0' then formatted = formatted:gsub('%.?0+$', '') end
            if num < 0.01 then return tostring(num) end
        else
            formatted = string.format('%.0f', num)
        end
        return sign .. formatted:reverse():gsub('(%d%d%d)', '%1,'):gsub(',$', ''):reverse()
    end
    score_number_scale = function(scale, amt)
        if type(amt) ~= 'number' then return 0.7 * (scale or 1) end
        if amt >= 1e11 then return 0.7 * (scale or 1) end
        return 0.75 * (scale or 1)
    end
    scale_number = function(number, scale, max, e_switch_point)
        if not number or type(number) ~= 'number' then return scale end
        max = max or 10000
        if math.abs(number) >= 1e11 then
            return scale * math.floor(math.log(max * 10, 10)) / math.floor(math.log(1000000 * 10, 10))
        elseif math.abs(number) >= max then
            return scale * math.floor(math.log(max * 10, 10)) / math.floor(math.log(math.abs(number) * 10, 10))
        end
        return scale
    end
    check_and_set_high_score = function(score, amt)
        if not amt or type(amt) ~= 'number' then return end
        if G.GAME.round_scores[score] and math.floor(amt) > G.GAME.round_scores[score].amt then
            G.GAME.round_scores[score].amt = math.floor(amt)
        end
        local hs = G.PROFILES[G.SETTINGS.profile].high_scores[score]
        if hs and math.floor(amt) > hs.amt then
            hs.amt = math.floor(amt)
            G:save_settings()
        end
    end
    inc_career_stat = function(stat, mod)
        local cs = G.PROFILES[G.SETTINGS.profile].career_stats
        cs[stat] = (cs[stat] or 0) + (mod or 0)
        G:save_settings()
    end
    update_hand_text = function(config, vals) M.last_hand_text = vals end

    -- Serializer with the semantics of the game's STR_PACK: numbers are written by string
    -- concatenation (about 14 significant digits), strings with %q, objects replaced.
    STR_PACK = function(data, recursive)
        local out = (recursive and '' or 'return ') .. '{'
        for k, v in pairs(data) do
            local key = type(k) == 'string' and ('[' .. string.format('%q', k) .. ']') or ('[' .. k .. ']')
            local tv = type(v)
            if tv == 'table' then
                v = STR_PACK(v, true)
            elseif tv == 'string' then
                v = string.format('%q', v)
            elseif tv == 'boolean' then
                v = v and 'true' or 'false'
            end
            out = out .. key .. '=' .. v .. ','
        end
        return out .. '}'
    end
    STR_UNPACK = function(str)
        local chunk = loadstring(str)
        if not chunk then return nil end
        setfenv(chunk, {})
        local ok, res = pcall(chunk)
        return ok and res or nil
    end

    Game = {}
    function Game:init_game_object()
        return {
            round_resets = { ante = 1 },
            dollars = 4,
            chips = 0,
            round_scores = { hand = { amt = 0 } },
            current_round = { current_hand = { chips = 0, mult = 0 } },
        }
    end
    -- args.areas: create the card areas like the game does (custom_card_areas, then the
    -- saved areas are loaded into them)
    function Game:start_run(args)
        self.GAME = (args and args.savetext and args.savetext.GAME) or self:init_game_object()
        if args and args.areas then
            M.areas.create_areas()
            if SMODS.current_mod.custom_card_areas then SMODS.current_mod.custom_card_areas(self) end
            local saved = args.savetext and args.savetext.cardAreas
            if saved then
                for k, v in pairs(saved) do
                    if G[k] then G[k]:load(v) end
                end
            end
        end
    end
    function Game:save_settings() M.saved_settings = (M.saved_settings or 0) + 1 end
    function Game:save_progress() M.saved_progress = (M.saved_progress or 0) + 1 end

    G = {
        STATES = { SELECTING_HAND = 1, HAND_PLAYED = 2, DRAW_TO_HAND = 3, NEW_ROUND = 4, SHOP = 5, PLAY_TAROT = 6, BLIND_SELECT = 7 },
        STAGES = { MAIN_MENU = 1, RUN = 2, SANDBOX = 3 },
        FUNCS = {
            overlay_menu = function(args) M.last_overlay = args end,
            text_super_juice = function(e, amount) M.last_juice = amount end,
        },
        P_BLINDS = {},
        C = {
            RED = { 1, 0, 0, 1 }, WHITE = { 1, 1, 1, 1 }, BLUE = { 0, 0, 1, 1 }, BLACK = { 0, 0, 0, 1 },
            CHIPS = { 0, 0.6, 1, 1 }, MULT = { 1, 0.37, 0.33, 1 },
            UI = { TEXT_LIGHT = {}, TEXT_INACTIVE = {}, BACKGROUND_INACTIVE = { 0.3, 0.3, 0.3, 1 } },
        },
        -- screen measures from the game's globals.lua
        TILE_W = 20, TILE_H = 11.5, TILESIZE = 20, TILESCALE = 1,
        CARD_W = 2.4 * 35 / 41, CARD_H = 2.4 * 47 / 41, HIGHLIGHT_H = 0.2 * 2.4 * 47 / 41,
        MIN_CLICK_DIST = 0.9,
        UIT = { ROOT = 'ROOT', R = 'R', C = 'C', T = 'T' },
        ARGS = {},
        SETTINGS = { profile = 1 },
        PROFILES = { [1] = { high_scores = { hand = { amt = 0 } }, career_stats = {} } },
    }
    setmetatable(G, { __index = Game })

    -- Steamodded --------------------------------------------------------------------------
    local mod = { id = 'NewEra', version = M.version, config = nil, path = M.root .. '/' }
    local config_src = assert(read_file(M.root .. '/config.lua'))
    mod.config = assert(loadstring(config_src))()

    SMODS = {
        current_mod = mod,
        Mods = { NewEra = mod },
        load_file = function(path)
            local src, err = read_file(M.root .. '/' .. path)
            if not src then return nil, err end
            return loadstring(src, '=' .. path)
        end,
        add_to_pool = function(obj, args)
            if type(obj.in_pool) == 'function' then return obj:in_pool(args) end
            return true
        end,
        Rarities = {},
        ObjectTypes = { Joker = { key = 'Joker' } },
    }
    -- Real implementation copied from Steamodded src/utils.lua (SMODS.merge_effects).
    function SMODS.merge_effects(...)
        local t = {}
        for _, v in ipairs({ ... }) do
            for _, vv in ipairs(v) do
                if vv == true or (type(vv) == 'table' and next(vv)) then table.insert(t, vv) end
            end
        end
        local ret = table.remove(t, 1)
        ret = ret == true and { remove = true } or ret
        local current = ret
        for _, eff in ipairs(t) do
            while current.extra ~= nil do current = current.extra end
            current.extra = eff == true and { remove = true } or eff
        end
        return ret
    end

    for _, key in ipairs({ 'Common', 'Uncommon', 'Rare', 'Legendary' }) do
        SMODS.Rarities[key] = {
            key = key,
            get_weight = function(self, weight, object_type) return weight end,
        }
    end

    M.install_scoring()

    SMODS.Atlas = registry('Atlas')
    SMODS.Rarity = registry('Rarity', function(def)
        SMODS.Rarities['ne_' .. def.key] = def
    end)
    SMODS.Joker = registry('Joker')
    SMODS.Keybind = registry('Keybind')
    SMODS.add_card = function(t) M.added_cards[#M.added_cards + 1] = t; return t end

    -- object classes, card areas and the hand flow (board, Phase 5)
    M.areas = require('mock_areas')
    M.areas.install(M)
    G.CONTROLLER = Controller()
    for target, src in pairs(M.areas.patch_sources) do M.patch_sources[target] = src end

    -- poker hands, planets and card rules (formations, Phase 6)
    M.formations = require('mock_formations')
    M.formations.install(M)

    -- game code that New Era patches, with lovely/*.toml applied (as Lovely does at start-up)
    M.load_patch_sources()

    M.mod = mod
    return M
end

-- Loads localization/<lang>.lua as a table.
function M.load_loc(lang)
    local src = assert(read_file(M.root .. '/localization/' .. lang .. '.lua'))
    return assert(loadstring(src, '=' .. lang))()
end

-- Loads the mod exactly like Steamodded does: runs main.lua with SMODS.current_mod set.
function M.load_mod()
    local src = assert(read_file(M.root .. '/main.lua'))
    assert(loadstring(src, '=main.lua'))()
    M.formations.inject()
end

-- Starts a run with real (mock) card areas and a board, selecting a hand in a blind.
function M.start_board_run(savetext)
    G:start_run({ savetext = savetext, areas = true })
    G.STAGE = G.STAGES.RUN
    G.STATE = G.STATES.SELECTING_HAND
    local g = G.GAME
    g.starting_params = g.starting_params or { play_limit = 5, discard_limit = 5 }
    g.hands_played = g.hands_played or 0
    g.current_round.discards_left = g.current_round.discards_left or 3
    g.current_round.discards_used = g.current_round.discards_used or 0
    g.facing_blind = true
    M.draw_log = {}
    M.drawhash = {}
    M.events = {}
    M.contexts = {}
    return G.play
end

-- Starts a fresh fake run.
function M.start_run(savetext)
    G:start_run(savetext and { savetext = savetext } or nil)
    G.STAGE = G.STAGES.RUN
    G.STATE = G.STATES.SELECTING_HAND
    G.jokers = { cards = {}, config = { card_limit = 5 } }
    G.hand = { cards = {} }
    G.deck = { cards = {} }
end

return M
