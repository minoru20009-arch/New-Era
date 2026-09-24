-- Scoring calculation `ne_ascend` (GDD §3.1): hand score = (Chips x Mult) ^ Aura.
-- It is the active calculation of every run (new runs, and saves that still use Steamodded's
-- plain `multiply`, which gives the same result while Aura is 1).
-- UI: Steamodded's chips and mult boxes plus a small "^Aura" box that is blank at Aura 1.

local Big = NE.Big
local Score = NE.Score

local AURA = Score.AURA_KEY
local UI_SCALE = 0.4

-- Scores below 1e308 are returned as plain numbers, so the round score stays a number (and
-- every vanilla code path sees what it always did) until a hand really passes 1e308.
local function plain_if_small(v)
    if Big.is(v) and v.len == 1 then return Big.to_number(v) end
    return v
end

-- (chips * mult) ^ aura for numbers/Bigs.
function Score.hand_score(chips, mult, aura)
    local base = Big.safe_mul(chips, mult)
    if base == nil then return 0 end
    if aura == nil or not NE.is_numeric(aura) or Big.eq(aura, 1) then return plain_if_small(base) end
    return plain_if_small(Big.pow(base, aura))
end

-- UI -------------------------------------------------------------------------------------------------

local function aura_box(scale)
    return {
        n = G.UIT.C, config = { align = 'cm', id = 'hand_ne_aura_container' }, nodes = {
            { n = G.UIT.R, config = { align = 'cm', minw = 0.6, minh = 0.6, r = 0.1, colour = G.C.CLEAR, emboss = 0.05, id = 'hand_ne_aura_area', func = 'ne_aura_box_UI_set' }, nodes = {
                { n = G.UIT.O, config = { id = 'hand_' .. AURA, func = 'ne_aura_UI_set', type = AURA, text = 'ne_aura_text', scale = scale * 1.3, object = DynaText({
                    string = { { ref_table = G.GAME.current_round.current_hand, ref_value = 'ne_aura_text' } },
                    colours = { G.C.UI.TEXT_LIGHT }, font = G.LANGUAGES['en-us'].font, shadow = true, float = true, scale = scale * 1.3,
                }) } },
            } },
        },
    }
end

-- Same containers as Steamodded's default layout (ids kept, so its update code finds them),
-- with slightly narrower chips/mult boxes to make room for the Aura box.
function Score.hand_ui(scale)
    scale = scale or UI_SCALE
    local hand = G.GAME.current_round.current_hand
    hand.ne_aura_text = hand.ne_aura_text or ''
    return {
        n = G.UIT.R, config = { align = 'cm', minh = 1, padding = 0.1 }, nodes = {
            { n = G.UIT.C, config = { align = 'cm', id = 'hand_chips_container' }, nodes = {
                SMODS.GUI.score_container({ type = 'chips', text = 'chip_text', align = 'cr', w = 1.75 }),
            } },
            SMODS.GUI.operator(scale),
            { n = G.UIT.C, config = { align = 'cm', id = 'hand_mult_container' }, nodes = {
                SMODS.GUI.score_container({ type = 'mult', w = 1.75 }),
            } },
            aura_box(scale),
        },
    }
end

-- Hidden at 1 and while unknown ('?' for face-down hands).
local function aura_visible(v)
    return NE.is_numeric(v) and not Big.eq(v, 1)
end

-- Text of the Aura box; rebuilt only when the value changes (runs every frame).
local last_aura = 1
G.FUNCS.ne_aura_UI_set = function(e)
    local hand = G.GAME.current_round.current_hand
    local v = hand[AURA]
    if v == last_aura or (NE.is_numeric(v) and NE.is_numeric(last_aura) and Big.eq(v, last_aura)) then return end
    last_aura = v
    local text = ''
    if aura_visible(v) then
        text = '^' .. number_format(v)
        e.config.object.scale = scale_number(v, UI_SCALE * 1.3, 100)
    end
    hand.ne_aura_text = text
    e.config.object:update_text()
end

G.FUNCS.ne_aura_box_UI_set = function(e)
    e.config.colour = aura_visible(G.GAME.current_round.current_hand[AURA]) and NE.C.AURA_BOX or G.C.CLEAR
end

-- Calculation -----------------------------------------------------------------------------------------

SMODS.Scoring_Calculation {
    key = 'ascend',
    parameters = { 'chips', 'mult', AURA },
    text = 'X',
    func = function(self, chips, mult, flames)
        return Score.hand_score(chips, mult, SMODS.get_scoring_parameter(AURA, flames))
    end,
    replace_ui = function(self)
        -- The hand text elements are rebuilt: refresh Steamodded's cached references once the
        -- new layout is in place (G.hand_text_area is used for juice and popups).
        G.E_MANAGER:add_event(Event({
            trigger = 'immediate',
            blocking = false,
            func = function()
                if G.HUD and SMODS.refresh_score_UI_list then SMODS.refresh_score_UI_list() end
                return true
            end,
        }))
        return Score.hand_ui(UI_SCALE)
    end,
}

Score.CALC_KEY = 'ne_ascend'

-- Makes ne_ascend the active calculation after a run starts or loads.
function Score.ensure_calculation()
    if not (G and G.GAME) then return end
    -- saves from before Phase 4 have no Aura display value yet (the sound code needs one)
    local hand = G.GAME.current_round and G.GAME.current_round.current_hand
    if hand and hand[AURA] == nil then hand[AURA] = 1 end
    local calc = G.GAME.current_scoring_calculation
    if calc and calc.key ~= 'multiply' then return end
    local proto = SMODS.Scoring_Calculations and SMODS.Scoring_Calculations[Score.CALC_KEY]
    if not proto then
        NE.log.error('Scoring calculation %s is not registered.', Score.CALC_KEY)
        return
    end
    G.GAME.current_scoring_calculation = proto:new()
    last_aura = 1
end

local start_run_ref = Game.start_run
function Game:start_run(args)
    local ret = start_run_ref(self, args)
    Score.ensure_calculation()
    return ret
end
