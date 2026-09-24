-- F9 performance overlay: frame timings, Lua heap, game state and New Era state.
-- Text is rebuilt 4 times per second; drawing itself allocates nothing.

NE.Debug = NE.Debug or {}
local Debug = NE.Debug

local getTime = love.timer.getTime
local format = string.format
local EMA = 0.1              -- smoothing factor for timings
local REFRESH_INTERVAL = 0.25 -- seconds between text rebuilds
local PADDING = 8

local overlay = {
    visible = false,
    update_ms = 0,
    draw_ms = 0,
    since_refresh = 0,
    text = '',
    w = 0,
    h = 0,
    font = nil,
    state_names = nil,
}
Debug.overlay = overlay

local function state_name(id)
    if not (G and G.STATES) then return '?' end
    local names = overlay.state_names
    if not names or names[id] == nil then
        names = {}
        for name, value in pairs(G.STATES) do names[value] = name end
        overlay.state_names = names
    end
    return names[id] or tostring(id)
end

local function card_count(area)
    return (area and area.cards) and #area.cards or 0
end

-- NE.Big values created per second (0 while idle means no per-frame allocation).
local big_rate = { last_allocs = 0, last_time = nil, per_sec = 0 }

local function update_big_rate()
    local stats = NE.Big and NE.Big.stats
    if not stats then return end
    local now = getTime()
    if big_rate.last_time then
        local dt = now - big_rate.last_time
        if dt > 0 then big_rate.per_sec = (stats.allocs - big_rate.last_allocs) / dt end
    end
    big_rate.last_time = now
    big_rate.last_allocs = stats.allocs
end

local function fmt_value(v)
    if v == nil then return '-' end
    return tostring(number_format(v))
end

local function build_lines()
    local lines = {
        format('New Era %s   [F9 hide | F10 cheats]', NE.VERSION),
        format('FPS %d   update %.2f ms   draw %.2f ms',
            love.timer.getFPS(), overlay.update_ms * 1000, overlay.draw_ms * 1000),
        format('Lua heap %.1f MB', collectgarbage('count') / 1024),
    }
    if G and G.STATE then
        lines[#lines + 1] = format('State %s   Stage %s', state_name(G.STATE), tostring(G.STAGE))
    end
    if G and G.STAGE == G.STAGES.RUN and G.GAME and G.jokers then
        local limit = G.jokers.config and G.jokers.config.card_limit or 0
        lines[#lines + 1] = format('Ante %s   $%s   Jokers %d/%s   Hand %d   Deck %d',
            tostring(G.GAME.round_resets and G.GAME.round_resets.ante), tostring(G.GAME.dollars),
            card_count(G.jokers), tostring(limit), card_count(G.hand), card_count(G.deck))
        local s = NE.State.get()
        if s then
            lines[#lines + 1] = format('NE next uid %d   rules hand/round/ante %d/%d/%d',
                s.next_uid, NE.Rules.count('hand'), NE.Rules.count('round'), NE.Rules.count('ante'))
        end
        lines[#lines + 1] = format('Score %s / target %s',
            fmt_value(G.GAME.chips), fmt_value(G.GAME.blind and G.GAME.blind.chips))
        local calc = G.GAME.current_scoring_calculation
        local aura = SMODS.Scoring_Parameters and SMODS.Scoring_Parameters.ne_aura
        lines[#lines + 1] = format('Calc %s   Aura %s   Divinity %d   Corruption %d   Time %d/%d',
            tostring(calc and calc.key), fmt_value(aura and aura.current),
            NE.Currency.get('divinity'), NE.Currency.get('corruption'),
            NE.Currency.get('time'), NE.Currency.max('time'))
        if NE.Phases and NE.Phases.trace.last ~= '' then
            lines[#lines + 1] = format('Phases (last hand): %s   score %s',
                NE.Phases.trace.last, fmt_value(NE.Phases.last_score))
        end
    end
    if NE.Big and NE.Big.stats then
        update_big_rate()
        lines[#lines + 1] = format('Big %.0f/s   total %d   flagged %d   save %s',
            big_rate.per_sec, NE.Big.stats.allocs, NE.Big.stats.flagged,
            tostring(NE.Big.hooks and NE.Big.hooks.cull))
    end
    return lines
end

local function refresh()
    if not overlay.font then overlay.font = love.graphics.newFont(13) end
    local lines = build_lines()
    local w = 0
    for i = 1, #lines do
        local lw = overlay.font:getWidth(lines[i])
        if lw > w then w = lw end
    end
    overlay.text = table.concat(lines, '\n')
    overlay.w = w
    overlay.h = #lines * overlay.font:getHeight()
end

local function draw_overlay()
    if not overlay.font then return end
    love.graphics.push('all')
    love.graphics.origin()
    love.graphics.setShader()
    love.graphics.setFont(overlay.font)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', PADDING, PADDING, overlay.w + PADDING * 2, overlay.h + PADDING * 2, 6, 6)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(overlay.text, PADDING * 2, PADDING * 2)
    love.graphics.pop()
end

function Debug.toggle_overlay()
    overlay.visible = not overlay.visible
    if overlay.visible then
        overlay.since_refresh = REFRESH_INTERVAL
    end
end

local update_ref = love.update
function love.update(dt)
    local t0 = getTime()
    update_ref(dt)
    overlay.update_ms = overlay.update_ms + ((getTime() - t0) - overlay.update_ms) * EMA
    if overlay.visible then
        overlay.since_refresh = overlay.since_refresh + dt
        if overlay.since_refresh >= REFRESH_INTERVAL then
            overlay.since_refresh = 0
            refresh()
        end
    end
end

local draw_ref = love.draw
function love.draw()
    local t0 = getTime()
    draw_ref()
    overlay.draw_ms = overlay.draw_ms + ((getTime() - t0) - overlay.draw_ms) * EMA
    if overlay.visible then draw_overlay() end
end
