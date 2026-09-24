-- Per-run New Era state, stored at G.GAME.newera so it is saved with the run.
-- Rule: only plain data here (numbers, strings, booleans, tables without metatables).

NE.State = NE.State or {}
local State = NE.State

State.SCHEMA = 1

local function defaults()
    return {
        schema = State.SCHEMA,
        next_uid = 1,
        rules = {
            permanent = {},
            temp = { hand = {}, round = {}, ante = {} },
        },
        stats = {
            cards_destroyed = 0,
            jokers_destroyed = 0,
        },
    }
end

function State.new()
    return defaults()
end

-- Makes sure `game.newera` exists and has every field of the current schema.
-- Safe to call on runs saved before New Era was installed.
function State.ensure(game)
    if not game then return nil end
    local s = game.newera
    if type(s) ~= 'table' then
        s = defaults()
        game.newera = s
        return s
    end
    NE.util.fill_defaults(s, defaults())
    return s
end

-- Returns the state of the current run, or nil outside a run.
function State.get()
    if not (G and G.GAME) then return nil end
    return State.ensure(G.GAME)
end

local init_game_object_ref = Game.init_game_object
function Game:init_game_object()
    local t = init_game_object_ref(self)
    t.newera = defaults()
    return t
end

local start_run_ref = Game.start_run
function Game:start_run(args)
    local ret = start_run_ref(self, args)
    State.ensure(self.GAME)
    return ret
end
