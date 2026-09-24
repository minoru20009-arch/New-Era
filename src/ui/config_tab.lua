-- Mod menu -> New Era -> Config. Values are saved by Steamodded when the mods menu closes.

local function toggle(label_key, ref_table, ref_value)
    return {
        n = G.UIT.R,
        config = { align = 'cl', padding = 0.02 },
        nodes = {
            create_toggle({
                label = localize(label_key),
                ref_table = ref_table,
                ref_value = ref_value,
                w = 4.5,
            }),
        },
    }
end

local function text_row(key, scale, colour)
    return {
        n = G.UIT.R,
        config = { align = 'cm', padding = 0.05 },
        nodes = {
            { n = G.UIT.T, config = { text = localize(key), scale = scale, colour = colour } },
        },
    }
end

NE.mod.config_tab = function()
    local cfg = NE.cfg()
    cfg.board = cfg.board or { small_cards = false }
    return {
        n = G.UIT.ROOT,
        config = { align = 'cm', padding = 0.2, colour = G.C.BLACK, r = 0.1, minw = 8 },
        nodes = {
            text_row('ne_cfg_title', 0.5, G.C.UI.TEXT_LIGHT),
            toggle('ne_cfg_hide_jokers', cfg.hide_vanilla, 'jokers'),
            toggle('ne_cfg_hide_planets', cfg.hide_vanilla, 'planets'),
            toggle('ne_cfg_hide_blinds', cfg.hide_vanilla, 'blinds'),
            text_row('ne_cfg_note', 0.3, G.C.UI.TEXT_INACTIVE),
            toggle('ne_cfg_board_small', cfg.board, 'small_cards'),
            toggle('ne_cfg_debug', cfg.debug, 'enabled'),
            toggle('ne_cfg_test_jokers', cfg.debug, 'test_jokers'),
        },
    }
end
