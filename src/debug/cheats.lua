-- F10 cheat menu for testing. Every entry is a G.FUNCS button callback named ne_cheat_<id>.

NE.Debug = NE.Debug or {}
local Debug = NE.Debug

local function in_run()
    return G and G.STAGE == G.STAGES.RUN and G.GAME ~= nil and G.jokers ~= nil
end

local function in_blind()
    return in_run() and G.STATE == G.STATES.SELECTING_HAND and G.GAME.blind ~= nil
end

local function give_joker(key)
    if #G.jokers.cards >= G.jokers.config.card_limit then
        play_sound('cancel')
        NE.log.info(localize('ne_cheat_no_room'))
        return
    end
    SMODS.add_card({ set = 'Joker', key = key })
end

local function set_target(value)
    local blind = G.GAME.blind
    blind.chips = NE.Big.new(value)
    blind.chip_text = number_format(blind.chips)
end

Debug.CHEATS = {
    { id = 'money', label = 'ne_cheat_money', run = function() ease_dollars(50) end },
    { id = 'hand', label = 'ne_cheat_hand', run = function() ease_hands_played(1) end },
    { id = 'discard', label = 'ne_cheat_discard', run = function() ease_discard(1) end },
    { id = 'ante', label = 'ne_cheat_ante', run = function() ease_ante(1) end },
    {
        id = 'meet_target',
        label = 'ne_cheat_meet_target',
        available = in_blind,
        run = function() G.GAME.chips = G.GAME.blind.chips end,
    },
    { id = 'give_unranked', label = 'ne_cheat_give_unranked', run = function() give_joker('j_ne_test_unranked') end },
    { id = 'give_demonic', label = 'ne_cheat_give_demonic', run = function() give_joker('j_ne_test_demonic') end },
    { id = 'give_heavenly', label = 'ne_cheat_give_heavenly', run = function() give_joker('j_ne_test_heavenly') end },
    -- Phase 3: big numbers
    {
        id = 'score_1e500',
        label = 'ne_cheat_score_1e500',
        available = in_blind,
        run = function() G.GAME.chips = NE.Big.new('1e500') end,
    },
    {
        id = 'score_mul',
        label = 'ne_cheat_score_mul',
        available = in_blind,
        run = function() G.GAME.chips = NE.Big.mul(math.max(G.GAME.chips, 1), 1e150) end,
    },
    { id = 'target_ee10', label = 'ne_cheat_target_ee10', available = in_blind, run = function() set_target('ee10') end },
    { id = 'target_tet5', label = 'ne_cheat_target_tet5', available = in_blind, run = function() set_target('10^^5') end },
    {
        id = 'hand_display',
        label = 'ne_cheat_hand_display',
        available = in_blind,
        run = function()
            update_hand_text({ immediate = true, nopulse = true, delay = 0 },
                { chips = NE.Big.new('1e400'), mult = NE.Big.new('ee12') })
        end,
    },
    { id = 'give_overflow', label = 'ne_cheat_give_overflow', run = function() give_joker('j_ne_test_overflow') end },
}

for _, cheat in ipairs(Debug.CHEATS) do
    G.FUNCS['ne_cheat_' .. cheat.id] = function(e)
        if not in_run() then return end
        if cheat.available and not cheat.available() then
            play_sound('cancel')
            return
        end
        play_sound('button')
        cheat.run()
    end
end

local function title_row(key)
    return {
        n = G.UIT.R,
        config = { align = 'cm', padding = 0.1 },
        nodes = { { n = G.UIT.T, config = { text = localize(key), scale = 0.55, colour = G.C.UI.TEXT_LIGHT } } },
    }
end

-- Two columns of buttons.
local function cheat_rows()
    local left, right = {}, {}
    for i, cheat in ipairs(Debug.CHEATS) do
        local column = (i % 2 == 1) and left or right
        column[#column + 1] = UIBox_button({
            button = 'ne_cheat_' .. cheat.id,
            label = { localize(cheat.label) },
            minw = 3.6,
            minh = 0.6,
            scale = 0.4,
            colour = G.C.BLUE,
        })
    end
    return {
        n = G.UIT.R,
        config = { align = 'cm', padding = 0.1 },
        nodes = {
            { n = G.UIT.C, config = { align = 'cm', padding = 0.05 }, nodes = left },
            { n = G.UIT.C, config = { align = 'cm', padding = 0.05 }, nodes = right },
        },
    }
end

function Debug.open_cheats()
    local contents
    if in_run() then
        contents = { title_row('ne_cheat_title'), cheat_rows() }
    else
        contents = { title_row('ne_cheat_title'), title_row('ne_cheat_not_in_run') }
    end
    G.FUNCS.overlay_menu({
        definition = create_UIBox_generic_options({ contents = contents }),
    })
end
