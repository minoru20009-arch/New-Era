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
function M.load_patch_sources(raw)
    M.patch_results = {}
    for target, src in pairs(M.patch_sources) do
        local patched = src
        if not raw then
            local results
            patched, results = M.apply_patches(target, src)
            for _, r in ipairs(results) do r.target = target; M.patch_results[#M.patch_results + 1] = r end
        end
        assert(loadstring(patched, '=' .. target))()
    end
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
        }, { __index = function() return function() end end }),
    }
    love.update = function(dt) M.update_calls = (M.update_calls or 0) + 1 end
    love.draw = function() M.draw_calls = (M.draw_calls or 0) + 1 end

    -- game globals --------------------------------------------------------------------------
    HEX = function(h) return { h } end
    localize = function(key)
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
    number_format = function(num, e_switch_point)
        if type(num) ~= 'number' then return num end
        local sign = num < 0 and '-' or ''
        num = math.abs(num)
        if num >= (e_switch_point or 1e11) then
            local fac = math.floor(math.log10(num))
            local mant = num / 10 ^ fac
            return sign .. string.format(fac >= 100 and '%.1fe%i' or fac >= 10 and '%.2fe%i' or '%.3fe%i', mant, fac)
        end
        local s = string.format('%.0f', num):reverse():gsub('(%d%d%d)', '%1,'):gsub(',$', ''):reverse()
        return sign .. s
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

    Object = {}
    function Object:is(cls) return getmetatable(self) and getmetatable(self).__class == cls end
    M.new_object = function() return setmetatable({}, { __index = Object, __class = Object }) end

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
    function Game:start_run(args)
        self.GAME = (args and args.savetext and args.savetext.GAME) or self:init_game_object()
    end
    function Game:save_settings() M.saved_settings = (M.saved_settings or 0) + 1 end
    function Game:save_progress() M.saved_progress = (M.saved_progress or 0) + 1 end

    G = {
        STATES = { SELECTING_HAND = 1, HAND_PLAYED = 2, SHOP = 5, BLIND_SELECT = 7 },
        STAGES = { MAIN_MENU = 1, RUN = 2, SANDBOX = 3 },
        FUNCS = {
            overlay_menu = function(args) M.last_overlay = args end,
            text_super_juice = function(e, amount) M.last_juice = amount end,
        },
        P_BLINDS = {},
        C = {
            RED = {}, WHITE = {}, BLUE = {}, BLACK = {},
            UI = { TEXT_LIGHT = {}, TEXT_INACTIVE = {} },
        },
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

    SMODS.Scoring_Parameters = { chips = {}, mult = {} }
    SMODS.Scoring_Calculations = {
        multiply = { key = 'multiply', func = function(self, chips, mult, flames) return chips * mult end },
    }
    SMODS.calculate_round_score = function(flames)
        local h = G.GAME.current_round.current_hand
        return SMODS.Scoring_Calculations.multiply:func(h.chips, h.mult, flames)
    end

    SMODS.Atlas = registry('Atlas')
    SMODS.Rarity = registry('Rarity', function(def)
        SMODS.Rarities['ne_' .. def.key] = def
    end)
    SMODS.Joker = registry('Joker')
    SMODS.Keybind = registry('Keybind')
    SMODS.add_card = function(t) M.added_cards[#M.added_cards + 1] = t; return t end

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
