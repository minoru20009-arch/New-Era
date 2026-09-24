-- F10 cheat menu for testing. Every entry is a G.FUNCS button callback named ne_cheat_<id>.

NE.Debug = NE.Debug or {}
local Debug = NE.Debug

local function in_run()
    return G and G.STAGE == G.STAGES.RUN and G.GAME ~= nil and G.jokers ~= nil
end

local function in_blind()
    return in_run() and G.STATE == G.STATES.SELECTING_HAND and G.GAME.blind ~= nil
end

local function board_ready()
    return in_blind() and NE.Board.can_place()
end

-- Moves up to n cards from the deck onto the board as Residue (within the Residue limit).
-- One event does the whole move, so repeated clicks never pick the same deck card twice.
function Debug.board_fill(n)
    local Board = NE.Board
    if Board.residue_cap() - #Board.residues() <= 0 or not G.deck.cards[1] then
        play_sound('cancel')
        return false
    end
    G.E_MANAGER:add_event(Event({
        func = function()
            local room = Board.residue_cap() - #Board.residues()
            for _ = 1, math.min(n, room) do
                if not G.deck.cards[1] then break end
                G.play:draw_card_from(G.deck)
            end
            for _, card in ipairs(G.play.cards) do card.ability.ne_residue = true end
            Board.bump()
            return true
        end,
    }))
    return true
end

Debug.BOARD_SIZES = { { 5, 3 }, { 6, 4 }, { 4, 2 } }

-- Cycles the board through 5x3 -> 6x4 -> 4x2 -> 5x3.
function Debug.board_next_size()
    local cols, rows = NE.Board.dims()
    local sizes = Debug.BOARD_SIZES
    local next_i = 1
    for i, size in ipairs(sizes) do
        if size[1] == cols and size[2] == rows then next_i = i % #sizes + 1 end
    end
    NE.Board.resize(sizes[next_i][1], sizes[next_i][2])
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
    -- Phase 4: score operators and phases
    { id = 'give_emult', label = 'ne_cheat_give_emult', run = function() give_joker('j_ne_test_emult') end },
    { id = 'give_eemult', label = 'ne_cheat_give_eemult', run = function() give_joker('j_ne_test_eemult') end },
    { id = 'give_hypermult', label = 'ne_cheat_give_hypermult', run = function() give_joker('j_ne_test_hypermult') end },
    { id = 'give_aura', label = 'ne_cheat_give_aura', run = function() give_joker('j_ne_test_aura') end },
    { id = 'give_phases', label = 'ne_cheat_give_phases', run = function() give_joker('j_ne_test_phases') end },
    {
        id = 'currency',
        label = 'ne_cheat_currency',
        run = function()
            for _, kind in ipairs(NE.Currency.ORDER) do NE.Currency.add(kind, 5, 'cheat') end
        end,
    },
    -- Phase 5: board
    { id = 'board_fill', label = 'ne_cheat_board_fill', available = board_ready, run = function() Debug.board_fill(4) end },
    { id = 'board_size', label = 'ne_cheat_board_size', available = board_ready, run = function() Debug.board_next_size() end },
    { id = 'board_shuffle', label = 'ne_cheat_board_shuffle', available = board_ready, run = function() NE.Board.shuffle_residues('ne_cheat') end },
    { id = 'board_clear', label = 'ne_cheat_board_clear', available = board_ready, run = function() NE.Board.clear_to_discard() end },
}

Debug.CHEAT_COLUMNS = 3

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

-- Buttons in Debug.CHEAT_COLUMNS columns, filled row by row.
local function cheat_rows()
    local columns = {}
    for c = 1, Debug.CHEAT_COLUMNS do columns[c] = {} end
    for i, cheat in ipairs(Debug.CHEATS) do
        local column = columns[(i - 1) % Debug.CHEAT_COLUMNS + 1]
        column[#column + 1] = UIBox_button({
            button = 'ne_cheat_' .. cheat.id,
            label = { localize(cheat.label) },
            minw = 3.4,
            minh = 0.55,
            scale = 0.38,
            colour = G.C.BLUE,
        })
    end
    local nodes = {}
    for c = 1, Debug.CHEAT_COLUMNS do
        nodes[c] = { n = G.UIT.C, config = { align = 'tm', padding = 0.05 }, nodes = columns[c] }
    end
    return {
        n = G.UIT.R,
        config = { align = 'cm', padding = 0.1 },
        nodes = nodes,
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
