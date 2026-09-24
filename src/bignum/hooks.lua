-- Connects NE.Big to the game. Everything here is a Lua wrap; the three spots that cannot be
-- wrapped are patched in lovely/10_bignum.toml:
--   recursive_table_cull  (save: Big -> packed string)       [L6, with a Lua fallback below]
--   modulate_sound        (sound: Big scores -> plain numbers) [L7]
--   type(x) == 'number'   (SMODS hand display checks)          [L8]
--
-- Rules kept by these wraps:
--   * plain numbers take the original code path unchanged (same results, same types);
--   * a Big never reaches the profile, the settings or the sound/save threads;
--   * functions return Big only when a Big came in (math.floor(big) is a Big, math.log is not).

local Big = NE.Big
local is_big = Big.is
local T, MAXD = Big.T, Big.MAXD
local huge = math.huge

Big.hooks = Big.hooks or {}
local hooks = Big.hooks

local function wrap_global(name, make)
    local ref = _G[name]
    if type(ref) ~= 'function' then
        NE.log.warn('Global %s not found; Big support for it is disabled.', name)
        return false
    end
    _G[name] = make(ref)
    hooks[name] = true
    return true
end

-- Shrinks UI text that is longer than the game's own scientific notation ("1.235e11").
local function length_factor(x)
    local n = #Big.format(x)
    if n <= 8 then return 1 end
    return 8 / n
end

-- Number formatting ------------------------------------------------------------------------------

wrap_global('number_format', function(ref)
    Big.scalar_format = function(v) return ref(v) end
    Big.clear_format_cache()
    return function(num, e_switch_point)
        if is_big(num) then
            if num.len == 1 then return ref(num.sign * num.a[0], e_switch_point) end
            return Big.format(num)
        end
        return ref(num, e_switch_point)
    end
end)

wrap_global('score_number_scale', function(ref)
    return function(scale, amt)
        if is_big(amt) then
            if amt.len == 1 then return ref(scale, amt.sign * amt.a[0]) end
            return 0.7 * (scale or 1) * length_factor(amt)
        end
        return ref(scale, amt)
    end
end)

wrap_global('scale_number', function(ref)
    return function(number, scale, max, e_switch_point)
        if is_big(number) then
            if number.len == 1 then return ref(number.sign * number.a[0], scale, max, e_switch_point) end
            return ref(MAXD, scale, max, e_switch_point) * length_factor(number)
        end
        return ref(number, scale, max, e_switch_point)
    end
end)

-- math.* -------------------------------------------------------------------------------------------

local m = math
local floor_ref, ceil_ref, abs_ref = m.floor, m.ceil, m.abs
local max_ref, min_ref = m.max, m.min
local log_ref, log10_ref, sqrt_ref, exp_ref, pow_ref = m.log, m.log10, m.sqrt, m.exp, m.pow
local LN10 = log_ref(10)
local E = exp_ref(1)

local function any_cdata(...)
    for i = 1, select('#', ...) do
        if type((select(i, ...))) == 'cdata' then return true end
    end
    return false
end

-- Picks the largest (keep = 1) or smallest (keep = -1) argument, returning it unchanged.
local function pick(keep, ...)
    local best = ...
    for i = 2, select('#', ...) do
        local v = select(i, ...)
        if Big.cmp(v, best) * keep > 0 then best = v end
    end
    return best
end

m.floor = function(x)
    if type(x) == 'cdata' and is_big(x) then return Big.floor(x) end
    return floor_ref(x)
end

m.ceil = function(x)
    if type(x) == 'cdata' and is_big(x) then return Big.ceil(x) end
    return ceil_ref(x)
end

m.abs = function(x)
    if type(x) == 'cdata' and is_big(x) then return Big.abs(x) end
    return abs_ref(x)
end

-- The UI calls max/min thousands of times per frame, mostly with two numbers: that case is
-- checked first and costs one extra call (nothing measurable once the JIT compiles it).
m.max = function(a, b, ...)
    if ... == nil then
        if b == nil then -- math.max(x)
            if type(a) == 'cdata' then return a end
            return max_ref(a)
        end
        if type(a) ~= 'cdata' and type(b) ~= 'cdata' then return max_ref(a, b) end
        return pick(1, a, b)
    end
    if type(a) == 'cdata' or type(b) == 'cdata' or any_cdata(...) then return pick(1, a, b, ...) end
    return max_ref(a, b, ...)
end

m.min = function(a, b, ...)
    if ... == nil then
        if b == nil then -- math.min(x)
            if type(a) == 'cdata' then return a end
            return min_ref(a)
        end
        if type(a) ~= 'cdata' and type(b) ~= 'cdata' then return min_ref(a, b) end
        return pick(-1, a, b)
    end
    if type(a) == 'cdata' or type(b) == 'cdata' or any_cdata(...) then return pick(-1, a, b, ...) end
    return min_ref(a, b, ...)
end

-- Logarithms of Big values are plain numbers (clamped to MAXD past 10^1e308).
m.log = function(x, base)
    if type(x) == 'cdata' or type(base) == 'cdata' then
        local lx = Big.log10_num(x)
        if base == nil then return lx * LN10 end
        return lx / Big.log10_num(base)
    end
    if base == nil then return log_ref(x) end
    return log_ref(x, base)
end

m.log10 = function(x)
    if type(x) == 'cdata' and is_big(x) then return Big.log10_num(x) end
    return log10_ref(x)
end

m.sqrt = function(x)
    if type(x) == 'cdata' and is_big(x) then return Big.pow(x, 0.5) end
    return sqrt_ref(x)
end

m.exp = function(x)
    if type(x) == 'cdata' and is_big(x) then return Big.pow(E, x) end
    return exp_ref(x)
end

if pow_ref then
    m.pow = function(x, y)
        if type(x) == 'cdata' or type(y) == 'cdata' then return Big.pow(x, y) end
        return pow_ref(x, y)
    end
end
hooks.math = true

-- High scores and career stats: the profile only ever stores plain, finite numbers --------

local function profile()
    return G and G.PROFILES and G.SETTINGS and G.PROFILES[G.SETTINGS.profile]
end

wrap_global('check_and_set_high_score', function(ref)
    return function(score, amt)
        if not is_big(amt) then return ref(score, amt) end
        -- the run record keeps the full value (saved with the run as a packed string)
        local rs = G.GAME and G.GAME.round_scores and G.GAME.round_scores[score]
        if rs and Big.gt(amt, rs.amt or 0) then rs.amt = Big.floor(amt) end
        return ref(score, Big.to_number(amt))
    end
end)

wrap_global('inc_career_stat', function(ref)
    return function(stat, mod)
        if is_big(mod) then mod = Big.to_number(mod) end
        local r = ref(stat, mod)
        local p = profile()
        local v = p and p.career_stats and p.career_stats[stat]
        if type(v) == 'number' and (v ~= v or v > MAXD or v < -MAXD) then
            p.career_stats[stat] = (v ~= v) and 0 or (v > 0 and MAXD or -MAXD)
        end
        return r
    end
end)

-- Removes any cdata left in profile/settings tables before they go to the save thread.
local SANITIZE_DEPTH = 16
local function sanitize(t, depth)
    for k, v in pairs(t) do
        local tv = type(v)
        if tv == 'cdata' then
            t[k] = Big.to_number(v)
        elseif tv == 'table' and depth < SANITIZE_DEPTH and getmetatable(v) == nil then
            sanitize(v, depth + 1)
        end
    end
end

local function sanitize_profile_and_settings()
    local p = profile()
    if type(p) == 'table' then sanitize(p, 0) end
    if G and type(G.SETTINGS) == 'table' then sanitize(G.SETTINGS, 0) end
end
Big.sanitize_plain = function(t) if type(t) == 'table' then sanitize(t, 0) end return t end

for _, name in ipairs({ 'save_settings', 'save_progress' }) do
    local ref = Game and Game[name]
    if type(ref) == 'function' then
        Game[name] = function(self, ...)
            sanitize_profile_and_settings()
            return ref(self, ...)
        end
        hooks['Game:' .. name] = true
    end
end

-- Saving (L6 fallback) and loading -------------------------------------------------------------------

-- The Lovely patch makes recursive_table_cull pack Big values. If that patch did not apply
-- (changed game file), install an equivalent Lua version so saving can never hit a cdata.
local function cull_packs_big()
    local ok, res = pcall(recursive_table_cull, { v = Big.ONE })
    return ok and type(res) == 'table' and type(res.v) == 'string'
end

-- Same behaviour as the game's function plus the L6 change (Object -> "MANUAL_REPLACE").
local function fallback_cull(t)
    local ret = {}
    for k, v in pairs(t) do
        local tv = type(v)
        if tv == 'table' then
            if v.is and v:is(Object) then
                ret[k] = '"MANUAL_REPLACE"'
            else
                ret[k] = recursive_table_cull(v)
            end
        elseif tv == 'cdata' then
            ret[k] = Big.pack_value(v)
        else
            ret[k] = v
        end
    end
    return ret
end

-- Returns 'lovely', 'fallback' or 'missing'. Called once at load; tests call it again.
function Big.ensure_cull()
    if type(recursive_table_cull) ~= 'function' then
        NE.log.error('recursive_table_cull not found; runs with big numbers cannot be saved.')
        hooks.cull = 'missing'
    elseif cull_packs_big() then
        hooks.cull = 'lovely'
    else
        NE.log.warn('Lovely patch for recursive_table_cull is missing; using the Lua fallback.')
        recursive_table_cull = fallback_cull
        hooks.cull = 'fallback'
    end
    return hooks.cull
end
Big.ensure_cull()

-- Every unpacked save table (run save, profile, settings) gets its packed Bigs restored,
-- including G.SAVED_GAME that the main menu reads for the "Continue" preview.
wrap_global('STR_UNPACK', function(ref)
    return function(str)
        local r = ref(str)
        if type(r) == 'table' then Big.rehydrate(r) end
        return r
    end
end)

-- Run checkpoints (Phase 8) pass culled tables straight to start_run, so rehydrate here too.
if Game and type(Game.start_run) == 'function' then
    local start_run_ref = Game.start_run
    function Game:start_run(args)
        if type(args) == 'table' and type(args.savetext) == 'table' then
            Big.rehydrate(args.savetext)
        end
        return start_run_ref(self, args)
    end
    hooks['Game:start_run'] = true
end

-- Scoring ---------------------------------------------------------------------------------------------

-- chips * mult becomes a Big instead of inf when the product passes 1e308.
local function finite_or_clamped(v)
    if v ~= v then return 0 end
    if v == huge then return MAXD end
    if v == -huge then return -MAXD end
    return v
end

local calcs = SMODS.Scoring_Calculations
local multiply = calcs and calcs.multiply
if multiply and type(multiply.func) == 'function' then
    local func_ref = multiply.func
    multiply.func = function(self, chips, mult, flames)
        local tc, tm = type(chips), type(mult)
        if tc == 'number' and tm == 'number' then
            local r = chips * mult
            if r < T and r > -T then return r end
            return Big.mul(finite_or_clamped(chips), finite_or_clamped(mult))
        end
        if (tc == 'number' or is_big(chips)) and (tm == 'number' or is_big(mult)) then
            if tc == 'number' then chips = finite_or_clamped(chips) end
            if tm == 'number' then mult = finite_or_clamped(mult) end
            return Big.mul(chips, mult)
        end
        return func_ref(self, chips, mult, flames)
    end
    hooks.multiply = true
else
    NE.log.warn('SMODS multiply scoring calculation not found; scores can still overflow to inf.')
end

-- Text juice grows with log10 of the value; keep it sane for astronomically large scores.
local JUICE_MAX = 30
if G and G.FUNCS and type(G.FUNCS.text_super_juice) == 'function' then
    local juice_ref = G.FUNCS.text_super_juice
    G.FUNCS.text_super_juice = function(e, amount)
        if type(amount) ~= 'number' then amount = Big.to_number(amount) end
        if amount ~= amount then
            amount = 0
        elseif amount > JUICE_MAX then
            amount = JUICE_MAX
        end
        return juice_ref(e, amount)
    end
    hooks.text_super_juice = true
end

-- Sound (called from the L7 patch in modulate_sound, every frame) ---------------------------------

-- Turns Big earned/required scores into plain numbers with the same ratio and ordering, so
-- the ambient sound and flame code (vanilla, number-only) keeps working without allocating.
function Big.sound_intensity(si)
    local e, r = si.earned_score, si.required_score
    if not (is_big(e) or is_big(r)) then return end
    local e_pos, r_pos = Big.cmp(e, 0) > 0, Big.cmp(r, 0) > 0
    local le = e_pos and Big.log10_num(e) or -huge
    local lr = r_pos and Big.log10_num(r) or -huge
    if le >= MAXD or lr >= MAXD then
        -- both beyond 10^1e308: only the ordering is meaningful
        si.required_score = r_pos and 1e300 or 0
        si.earned_score = e_pos and (Big.cmp(e, r) >= 0 and 1e300 or 1e299) or 0
        return
    end
    local top = le > lr and le or lr
    local shift = top > 300 and top - 300 or 0
    si.earned_score = e_pos and 10 ^ (le - shift) or 0
    si.required_score = r_pos and 10 ^ (lr - shift) or 0
end

-- Self-test ---------------------------------------------------------------------------------------------
-- Records how the running LuaJIT treats Big values in plain Lua operators (roadmap Phase 3:
-- the __eq behaviour is logged at every start).
do
    local five = Big.new(5)
    local results = {
        eq_number = (five == 5) and not (five == 6),
        eq_nil = (five ~= nil) and not (five == nil),
        lt_mixed = (five < 6) and (4 < five) and (five >= 5),
        concat = ('x' .. five) == 'x5',
        arith_mixed = Big.eq(2 + five * 3, 17),
    }
    Big.runtime = results
    local all = true
    for _, ok in pairs(results) do all = all and ok end
    if all then
        NE.log.info('NE.Big runtime check passed (__eq/__lt/__concat with plain numbers; save: %s).',
            tostring(hooks.cull))
    else
        local bad = {}
        for k, ok in pairs(results) do if not ok then bad[#bad + 1] = k end end
        table.sort(bad)
        NE.log.error('NE.Big runtime check FAILED: %s', table.concat(bad, ', '))
    end
end
