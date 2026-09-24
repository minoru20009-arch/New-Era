-- Default configuration for New Era.
-- Saved values from config/NewEra.jkr are merged over this table by Steamodded.
return {
    -- Hide vanilla content from all pools while New Era is installed.
    -- Planets and blinds stay visible until their New Era replacements exist
    -- (formations in Phase 6, procedural bosses in Phase 10).
    hide_vanilla = {
        jokers = true,
        planets = false,
        blinds = false,
    },

    debug = {
        -- Enables F9 (performance overlay) and F10 (cheat menu).
        enabled = true,
        -- Adds the three Phase 2 test jokers to the joker pools.
        test_jokers = true,
    },
}
