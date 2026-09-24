-- Hyper-operators for NE.Big: tetration, Knuth arrows, super-logarithm.
--
-- arrow(a, n, b) = a {n arrows} b:  n = 0 multiplication, n = 1 power, n = 2 tetration, ...
-- Real heights use the linear convention a{n}x = a^x for 0 <= x <= 1 (and 1 + x for -1 < x <= 0).
-- Base 10 is exact by construction. Other bases are iterated exactly until the tower passes
-- what a double can resolve; from then on each step only adds one level, so the remaining
-- steps are added in one go (the base no longer changes any stored digit).

local Big = NE.Big
local I = Big._internal
local alloc, copy, normalize = I.alloc, I.copy, I.normalize
local cmp, is_zero = I.cmp, I.is_zero
local floor = math.floor

local CAP, M = Big.CAP, Big.M
-- Hard cap on exact steps. Towers of bases below 2 can converge to a fixed point (tetration up
-- to e^(1/e), higher arrows up to 2); a fixed point ends the loop early, and the cap bounds
-- the rare near-critical bases where the tower moves very slowly.
local MAX_EXACT_STEPS = 100000
local E_ROOT = 1.444667861009766 -- e^(1/e): tetration converges at or below this base

-- True when the step r -> nxt no longer changes a double-sized value (fixed point).
local function settled(nxt, r)
    if nxt.len ~= 1 or r.len ~= 1 or nxt.sign ~= r.sign then return false end
    local x, y = nxt.a[0], r.a[0]
    return x == y or math.abs(x - y) <= 1e-15 * x
end

-- Highest level in use (0 for plain doubles).
local function top_level(p) return p.len - 1 end

-- 10{n}b for a Big height b (n >= 1). Exact when b's top level is below or at n; otherwise
-- b already dominates and 10{n}b equals b at stored precision.
local function arrow10(n, b)
    local r = copy(alloc(), b)
    r.flags = 0
    if r.sign == -1 or is_zero(r) then
        -- 10{n}x for -1 < x <= 0 is 1 + x; lower heights are undefined -> 0
        local v = r.sign * r.a[0]
        if r.len > 1 or v <= -1 then return I.set_zero(r) end
        return I.set_small(r, 1 + v)
    end
    if n == 1 then return I.pow10_core(r, r) end
    if top_level(r) > n then return r end
    if r.len < n + 1 then r.len = n + 1 end
    r.a[n] = r.a[n] + 1
    return normalize(r)
end

-- True when |r| is past 10^1e308, i.e. a^r == 10^r at stored precision for any sane base.
local function beyond_double_tower(r)
    return r.len >= 3 or (r.len == 2 and r.a[1] >= 2)
end

local BIG_M = Big.new(M)
Big.CONSTANTS[BIG_M] = true

local function height_huge(r)
    return cmp(r, BIG_M) > 0
end

local arrow

-- Tetration steps done in doubles while the tower still fits: r <- av^r, at most `steps` times.
-- Returns the value, the number of steps done, and whether it converged (fixed point).
local function tetrate_double(av, rv, steps)
    local i = 0
    while i < steps do
        local nx = av ^ rv
        if nx >= Big.T or nx ~= nx then break end
        i = i + 1
        if nx == rv or math.abs(nx - rv) <= 1e-15 * nx then return nx, i, true end
        rv = nx
        if i >= MAX_EXACT_STEPS * 10 then break end
    end
    return rv, i, false
end

-- a {n} b for n >= 2, a > 1 (Big), b a positive Big no larger than 2^53.
local function arrow_iter(a, n, b)
    local steps = floor(Big.to_number(b))
    local frac = Big.to_number(b) - steps
    local base_small = (a.len == 1 and a.a[0] <= E_ROOT)
    local r
    local i = 1
    if n == 2 and a.len == 1 then
        local av = a.a[0]
        local rv, done, converged = tetrate_double(av, frac > 0 and av ^ frac or 1, steps)
        r = Big.new(rv)
        if converged or done >= steps or base_small then return r end
        i = done + 1
    else
        r = frac > 0 and Big.pow(a, frac) or Big.new(1)
    end
    while i <= steps do
        local remaining = steps - i + 1
        if n == 2 and beyond_double_tower(r) then
            -- each further a^r is 10^r: one more level-1 step per iteration
            r = copy(alloc(), r)
            if r.len < 2 then r.len = 2 end
            r.a[1] = r.a[1] + remaining
            return normalize(r)
        end
        if n >= 3 and height_huge(r) then
            -- a {n-1} r with a huge height r is 10{n-1}r: one level-(n-1) step per iteration
            r = copy(alloc(), r)
            if top_level(r) > n - 1 then return r end
            if r.len < n then r.len = n end
            r.a[n - 1] = r.a[n - 1] + remaining
            return normalize(r)
        end
        local nxt = arrow(a, n - 1, r)
        if settled(nxt, r) then return nxt end -- fixed point: further steps change nothing
        r = nxt
        if i >= MAX_EXACT_STEPS then return r end -- still near a fixed point after the cap
        i = i + 1
    end
    return r
end

-- a {n} b. a, b: numbers or Bigs. n: integer >= 0 (n > 7 saturates).
function arrow(a, n, b)
    a, b = Big.of(a), Big.of(b)
    n = floor(Big.to_number(n))
    if n <= 0 then return Big.mul(a, b) end
    if n == 1 then return Big.pow(a, b) end
    if n >= CAP then
        local r = I.set_max(alloc(), 1)
        Big.stats.flagged = Big.stats.flagged + 1
        return r
    end

    -- heights: b <= -1 undefined (0), -1 < b <= 0 -> 1 + b
    if b.sign == -1 or is_zero(b) then return arrow10(n, b) end
    -- bases: a <= 0 has no real tower; 1{n}b = 1
    if a.sign == -1 or is_zero(a) then
        local r = I.set_zero(alloc())
        r.flags = Big.FLAG_NAN
        Big.stats.flagged = Big.stats.flagged + 1
        return r
    end
    if a.len == 1 and a.a[0] == 1 then return Big.new(1) end
    if a.len == 1 and a.a[0] < 1 then
        -- towers of bases in (0, 1) oscillate towards a limit; iterate with doubles
        local av, bv = a.a[0], Big.to_number(b)
        local steps = floor(bv)
        local r = av ^ (bv - steps)
        for _ = 1, math.min(steps, 1000) do r = av ^ r end
        return Big.new(r)
    end

    if a.len == 1 and a.a[0] == 10 then return arrow10(n, b) end
    if height_huge(b) then
        -- the base only shifts the height by a bounded amount; at heights past 2^53 that
        -- shift is below double precision, so 10{n}b is the stored result
        local r = arrow10(n, b)
        if cmp(a, r) > 0 then return copy(alloc(), a) end
        return r
    end
    return arrow_iter(a, n, b)
end

Big.arrow = arrow

function Big.tetrate(a, b) return arrow(a, 2, b) end
function Big.pentate(a, b) return arrow(a, 3, b) end

-- Super-logarithm base 10 of a double (inverse of 10^^x, linear convention). x > 0.
local function slog_double(x)
    if x <= 0 then return -1 end
    local s = 0
    while x > 1 do
        x = math.log10(x)
        s = s + 1
    end
    return s + x - 1
end
Big.slog_double = slog_double

-- slog10(x): the height h with 10^^h == x. Returns a Big (heights can be astronomically large).
-- Negative values and zero give -1 (10^^-1 = 0).
function Big.slog(x)
    x = Big.of(x)
    if x.sign == -1 or is_zero(x) then return Big.new(-1) end
    if x.len == 1 then return Big.new(slog_double(x.a[0])) end
    if x.len == 2 then return Big.new(x.a[1] + slog_double(x.a[0])) end
    if x.len == 3 then
        -- x = 10^^y with y = the same array minus one 10^^ application (exact)
        local r = copy(alloc(), x)
        r.a[2] = r.a[2] - 1
        return normalize(r)
    end
    return copy(alloc(), x) -- 10{3} and above: slog changes nothing at stored precision
end
