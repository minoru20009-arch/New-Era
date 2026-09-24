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

    Game = {}
    function Game:init_game_object()
        return { round_resets = { ante = 1 }, dollars = 4 }
    end
    function Game:start_run(args)
        self.GAME = (args and args.savetext and args.savetext.GAME) or self:init_game_object()
    end

    G = {
        STATES = { SELECTING_HAND = 1, HAND_PLAYED = 2, SHOP = 5, BLIND_SELECT = 7 },
        STAGES = { MAIN_MENU = 1, RUN = 2, SANDBOX = 3 },
        FUNCS = {
            overlay_menu = function(args) M.last_overlay = args end,
        },
        P_BLINDS = {},
        C = {
            RED = {}, WHITE = {}, BLUE = {}, BLACK = {},
            UI = { TEXT_LIGHT = {}, TEXT_INACTIVE = {} },
        },
        UIT = { ROOT = 'ROOT', R = 'R', C = 'C', T = 'T' },
    }
    setmetatable(G, { __index = Game })

    -- Steamodded --------------------------------------------------------------------------
    local mod = { id = 'NewEra', version = '0.2.0~dev', config = nil, path = M.root .. '/' }
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

    SMODS.Atlas = registry('Atlas')
    SMODS.Rarity = registry('Rarity', function(def)
        SMODS.Rarities['ne_' .. def.key] = def
    end)
    SMODS.Joker = registry('Joker')
    SMODS.Keybind = registry('Keybind')
    SMODS.add_card = function(t) M.added_cards[#M.added_cards + 1] = t; return t end

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
