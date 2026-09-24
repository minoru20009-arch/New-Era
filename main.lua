-- New Era entry point. Loaded by Steamodded with SMODS.current_mod set to this mod.
-- Modules are loaded in dependency order; content (jokers, etc.) always loads last.

NE = NE or {}
NE.mod = SMODS.current_mod
NE.config = NE.mod.config

local MODULES = {
    -- core
    'src/core/ne.lua',
    'src/core/log.lua',
    'src/core/util.lua',
    'src/core/state.lua',
    'src/core/hooks.lua',
    'src/core/uid.lua',
    'src/core/rules.lua',
    'src/core/cond.lua',
    -- big numbers
    'src/bignum/big.lua',
    'src/bignum/ops_hyper.lua',
    'src/bignum/notation.lua',
    'src/bignum/serialize.lua',
    'src/bignum/hooks.lua',
    -- content registries
    'src/content/atlases.lua',
    'src/content/rarities.lua',
    'src/content/colours.lua',
    -- run currencies
    'src/economy/currency.lua',
    -- board (G.play as a 5 x 3 grid)
    'src/board/grid.lua',
    'src/board/board_area.lua',
    'src/board/placement.lua',
    'src/board/controller.lua',
    -- formations (the board's poker hands)
    'src/formation/patterns.lua',
    'src/formation/evaluator.lua',
    'src/formation/formations.lua',
    'src/formation/planets.lua',
    'src/formation/ui_diagram.lua',
    -- scoring
    'src/scoring/operators.lua',
    'src/scoring/aura.lua',
    'src/scoring/calc.lua',
    'src/scoring/phases.lua',
    -- compatibility with vanilla content
    'src/compat/vanilla_pool.lua',
    -- ui
    'src/ui/config_tab.lua',
    -- debug tools
    'src/debug/perf_overlay.lua',
    'src/debug/cheats.lua',
    'src/debug/keybinds.lua',
    -- content
    'src/jokers/test/test_jokers.lua',
}

for _, path in ipairs(MODULES) do
    local chunk, err = SMODS.load_file(path)
    if not chunk then
        error('[NewEra] Failed to load ' .. path .. ': ' .. tostring(err))
    end
    chunk()
end

NE.log.info('New Era %s loaded (%d modules).', NE.VERSION, #MODULES)
