-- Default configuration for New Era.
-- Saved values from config/NewEra.jkr are merged over this table by Steamodded.
return {
    -- Hide vanilla content from all pools while New Era is installed.
    -- Blinds stay visible until the procedural bosses exist (Phase 10).
    hide_vanilla = {
        jokers = true,
        planets = true,
        blinds = false,
    },

    board = {
        -- Draws the board cards smaller (for small windows or if the board feels crowded).
        small_cards = false,
    },

    debug = {
        -- Enables F9 (performance overlay) and F10 (cheat menu).
        enabled = true,
        -- Adds the three Phase 2 test jokers to the joker pools.
        test_jokers = true,
    },
}
