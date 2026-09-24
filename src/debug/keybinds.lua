-- Debug keybinds. Both do nothing unless config.debug.enabled is on.

SMODS.Keybind {
    key = 'perf_overlay',
    key_pressed = 'f9',
    action = function(self)
        if NE.debug_enabled() then NE.Debug.toggle_overlay() end
    end,
}

SMODS.Keybind {
    key = 'cheat_menu',
    key_pressed = 'f10',
    action = function(self)
        if NE.debug_enabled() then NE.Debug.open_cheats() end
    end,
}
