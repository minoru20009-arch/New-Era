-- NE.Big: numbers of any magnitude for New Era (scores, targets, multipliers).
--
-- Representation (semantics of OmegaNum.js by Naruyoko, MIT):
--   value = sign * H7^a[7]( ... H2^a[2]( H1^a[1]( a[0] ) ) ),   Hk(x) = 10 {k arrows} x
-- a[0] is a non-negative double, a[k] (k >= 1) are integer repeat counts. The array is stored
-- inline in the cdata, so every value is a single allocation with no side tables.
--
-- Normal form (enforced by normalize):
--   * len == 1           -> plain double, 0 <= a[0] < 1e308 (fast path: exact double math)
--   * a[1] >= 1          -> 308 <= a[0] < 1e308
--   * len >= 3, a[1] = 0 -> a[0] > 2^53 (smaller heights are expanded into lower levels)
--   * counts a[k] <= 2^53, trailing zero counts trimmed, zero is +0 with len == 1
-- With this form, ordering is lexicographic on (len, a[len-1], ..., a[0]).
--
-- Fractional hyper heights use the linear convention 10{k}x = 10^x for 0 <= x <= 1.
-- Public functions never return NaN or Inf: bad inputs saturate and set a diagnostic flag.
-- Values are treated as immutable. The *_into functions mutate their first argument and must
-- only be used on values the caller owns (never on game state that other code may reference).
--
-- Comparing with `==` works for Big vs Big/number (LuaJIT calls __eq for cdata), but New Era
-- code uses NE.Big.eq for clarity. Big values must never be used as table keys.

local ffi = require('ffi')

if NE.Big and NE.Big.ctype then return end -- already initialised in this Lua state

NE.Big = NE.Big or {}
local Big = NE.Big

local floor, log10, fmod, huge = math.floor, math.log10, math.fmod, math.huge
local type, tonumber = type, tonumber

-- Constants ---------------------------------------------------------------------------------
local CAP = 8                       -- array capacity (up to 10{7})
local T = 1e308                     -- a[0] bound for len == 1 and for levels >= 1
local LT = 308                      -- log10(T)
local M = 9007199254740992          -- 2^53: largest repeat count / smallest stored height
local MAXD = 1.7976931348623157e308 -- largest finite double (clamp for to_number)

Big.CAP, Big.T, Big.LT, Big.M, Big.MAXD = CAP, T, LT, M, MAXD

local FLAG_NAN, FLAG_INF, FLAG_SAT = 1, 2, 4
Big.FLAG_NAN, Big.FLAG_INF, Big.FLAG_SAT = FLAG_NAN, FLAG_INF, FLAG_SAT

if not pcall(ffi.typeof, 'ne_big') then
    ffi.cdef [[ typedef struct { double a[8]; int32_t len; int8_t sign; uint8_t flags; } ne_big; ]]
end

local CT            -- ctype, set by ffi.metatype below
local SIZE = ffi.sizeof('ne_big')
local istype = ffi.istype

Big.stats = { allocs = 0, flagged = 0 }
local stats = Big.stats

-- Low-level helpers (operate on cdata, never allocate unless named alloc) -------------------

local function alloc()
    stats.allocs = stats.allocs + 1
    local p = CT()
    p.len = 1
    p.sign = 1
    return p
end

local function is_big(x)
    return type(x) == 'cdata' and istype(CT, x)
end

local function clear_high(p, from)
    for i = from, CAP - 1 do p.a[i] = 0 end
end

local function set_zero(p)
    p.a[0] = 0
    clear_high(p, 1)
    p.len = 1
    p.sign = 1
    return p
end

local function set_max(p, sign)
    p.a[0] = 1e300
    clear_high(p, 1)
    p.a[CAP - 1] = M
    p.len = CAP
    p.sign = sign or 1
    p.flags = FLAG_SAT
    return p
end

-- Writes a finite double. |x| must be < T (callers guarantee this).
local function set_small(p, x)
    clear_high(p, 1)
    p.len = 1
    if x < 0 then
        p.a[0] = -x
        p.sign = -1
    else
        p.a[0] = x + 0 -- turns -0 into +0
        p.sign = 1
    end
    p.flags = 0
    return p
end

-- Writes sign * 10^L for a finite L (any size up to MAXD).
local function set_pow10_num(p, L, sign)
    p.flags = 0
    if L < LT then
        clear_high(p, 1)
        p.len = 1
        p.a[0] = 10 ^ L
        p.sign = (p.a[0] == 0) and 1 or sign
        return p
    end
    clear_high(p, 2)
    if L < T then
        p.a[0] = L
        p.a[1] = 1
    else
        p.a[0] = log10(L)
        p.a[1] = 2
    end
    p.len = 2
    p.sign = sign
    return p
end

-- Writes any Lua number (handles NaN, Inf and values >= T).
local function set_number(p, x)
    p.flags = 0
    if x ~= x then
        set_zero(p)
        p.flags = FLAG_NAN
        stats.flagged = stats.flagged + 1
        return p
    end
    local s = 1
    if x < 0 then
        s = -1
        x = -x
    end
    if x == huge then
        set_max(p, s)
        p.flags = FLAG_INF
        stats.flagged = stats.flagged + 1
        return p
    end
    clear_high(p, 1)
    if x >= T then
        p.a[0] = log10(x)
        p.a[1] = 1
        p.len = 2
    else
        p.a[0] = x + 0 -- turns -0 into +0
        p.len = 1
    end
    p.sign = (x == 0) and 1 or s
    return p
end

local function copy(dst, src)
    if dst ~= src then ffi.copy(dst, src, SIZE) end
    return dst
end

local function is_zero(p)
    return p.len == 1 and p.a[0] == 0
end

-- Restores the normal form in place. Also sanitises NaN/Inf and out-of-range fields.
local function normalize(p)
    local len = p.len
    if len < 1 then len = 1 elseif len > CAP then len = CAP end
    for i = len, CAP - 1 do p.a[i] = 0 end
    if p.sign ~= -1 then p.sign = 1 end

    for i = 0, len - 1 do
        local v = p.a[i]
        if v ~= v then
            set_zero(p)
            p.flags = FLAG_NAN
            stats.flagged = stats.flagged + 1
            return p
        end
        if v == huge or v == -huge then
            set_max(p, p.sign)
            p.flags = FLAG_INF
            stats.flagged = stats.flagged + 1
            return p
        end
        if i > 0 then
            v = floor(v)
            if v < 0 then v = 0 end
            p.a[i] = v
        end
    end
    if p.a[0] < 0 then
        p.a[0] = -p.a[0]
        p.sign = -p.sign
    end

    local changed = true
    while changed do
        changed = false
        while len > 1 and p.a[len - 1] == 0 do len = len - 1 end

        -- A repeat count past 2^53 becomes one application of the next operator.
        for i = 1, len - 1 do
            if p.a[i] > M then
                if i == CAP - 1 then
                    set_max(p, p.sign)
                    stats.flagged = stats.flagged + 1
                    return p
                end
                p.a[i + 1] = p.a[i + 1] + 1
                p.a[0] = p.a[i] + 1
                for j = 1, i do p.a[j] = 0 end
                if len < i + 2 then len = i + 2 end
                changed = true
            end
        end

        if p.a[0] >= T then
            p.a[0] = log10(p.a[0])
            p.a[1] = p.a[1] + 1
            if len < 2 then len = 2 end
            changed = true
        end

        while len >= 2 and p.a[1] > 0 and p.a[0] < LT do
            p.a[0] = 10 ^ p.a[0]
            p.a[1] = p.a[1] - 1
            changed = true
        end

        -- 10{i}h with a small height h expands to (10{i-1})^floor(h) (10^frac(h)).
        if len >= 3 and p.a[1] == 0 and p.a[0] <= M then
            local i = 2
            while p.a[i] == 0 do i = i + 1 end
            local h = p.a[0]
            local n = floor(h)
            p.a[i] = p.a[i] - 1
            p.a[i - 1] = n
            p.a[0] = 10 ^ (h - n)
            changed = true
        end
    end

    p.len = len
    if len == 1 and p.a[0] == 0 then
        p.a[0] = 0
        p.sign = 1
    end
    return p
end

-- Magnitude comparison of two normalized values: -1, 0 or 1.
local function cmp_abs(x, y)
    local lx, ly = x.len, y.len
    if lx ~= ly then return lx < ly and -1 or 1 end
    for i = lx - 1, 0, -1 do
        local a, b = x.a[i], y.a[i]
        if a ~= b then return a < b and -1 or 1 end
    end
    return 0
end

local function cmp(x, y)
    local sx, sy = x.sign, y.sign
    if sx ~= sy then return sx < sy and -1 or 1 end
    local c = cmp_abs(x, y)
    return sx == 1 and c or -c
end

-- log10|x| as a double when it fits, or nil when |x| >= 10^1e308.
local function log10_double(p)
    if p.len == 1 then return log10(p.a[0]) end
    if p.len == 2 and p.a[1] == 1 then return p.a[0] end
    return nil
end

-- Core arithmetic (out may alias any input; inputs are normalized cdata) ---------------------

-- out = x + flip * y   (flip is 1 or -1)
local function add_core(out, x, y, flip)
    local sy = y.sign * flip
    if is_zero(y) then return copy(out, x) end
    if is_zero(x) then
        copy(out, y)
        out.sign = is_zero(out) and 1 or sy
        return out
    end
    local sx = x.sign

    if x.len == 1 and y.len == 1 then
        local a, b = x.a[0], y.a[0]
        local r = sx * a + sy * b
        if r < T and r > -T then return set_small(out, r) end
        if a < b then a, b = b, a end
        return set_pow10_num(out, log10(a) + log10(1 + b / a), sx)
    end

    local c = cmp_abs(x, y)
    local hi, lo, s
    if c >= 0 then hi, lo, s = x, y, sx else hi, lo, s = y, x, sy end
    local same = (sx == sy)
    if not same and c == 0 then return set_zero(out) end

    if hi.len == 2 and hi.a[1] == 1 then
        local Lh = hi.a[0]
        local Ll = log10_double(lo) -- lo <= hi, so it fits
        local d = Ll - Lh
        if d < -17 then
            copy(out, hi)
            out.sign = s
            return out
        end
        local L
        if same then
            L = Lh + log10(1 + 10 ^ d)
        else
            local r = 1 - 10 ^ d
            if r <= 0 then return set_zero(out) end
            L = Lh + log10(r)
        end
        return set_pow10_num(out, L, s)
    end

    -- Beyond 10^1e308 the smaller operand cannot change the stored digits.
    copy(out, hi)
    out.sign = s
    return out
end

-- out = log10|x|  (x ~= 0)
local function log10_core(out, x)
    if x.len == 1 then return set_small(out, log10(x.a[0])) end
    copy(out, x)
    out.sign = 1
    out.flags = 0
    if x.len == 2 then
        out.a[1] = out.a[1] - 1
        return normalize(out)
    end
    return out -- 10{k}-level values: log10 changes nothing at double precision
end

-- out = 10^e
local function pow10_core(out, e)
    if is_zero(e) then return set_small(out, 1) end
    if e.sign == -1 then
        if e.len == 1 then return set_small(out, 10 ^ (-e.a[0])) end
        return set_zero(out)
    end
    if e.len == 1 then return set_pow10_num(out, e.a[0], 1) end
    copy(out, e)
    out.flags = 0
    if e.len == 2 then
        out.a[1] = out.a[1] + 1
        return normalize(out)
    end
    return out
end

local S_MUL1, S_MUL2 -- scratch, allocated after the metatype is set

local function mul_core(out, x, y)
    if is_zero(x) or is_zero(y) then return set_zero(out) end
    local s = x.sign * y.sign
    if x.len == 1 and y.len == 1 then
        local a, b = x.a[0], y.a[0]
        local p = a * b
        if p < T then return set_small(out, s * p) end
        return set_pow10_num(out, log10(a) + log10(b), s)
    end
    log10_core(S_MUL1, x)
    log10_core(S_MUL2, y)
    add_core(S_MUL1, S_MUL1, S_MUL2, 1)
    pow10_core(out, S_MUL1)
    if not is_zero(out) then out.sign = s end
    return out
end

local S_DIV1, S_DIV2

local function div_core(out, x, y)
    if is_zero(y) then
        stats.flagged = stats.flagged + 1
        if is_zero(x) then
            set_zero(out)
            out.flags = FLAG_NAN
            return out
        end
        local s = x.sign
        set_max(out, s)
        out.flags = FLAG_INF
        return out
    end
    if is_zero(x) then return set_zero(out) end
    local s = x.sign * y.sign
    if x.len == 1 and y.len == 1 then
        local a, b = x.a[0], y.a[0]
        local q = a / b
        if q < T then return set_small(out, s * q) end
        return set_pow10_num(out, log10(a) - log10(b), s)
    end
    log10_core(S_DIV1, x)
    log10_core(S_DIV2, y)
    add_core(S_DIV1, S_DIV1, S_DIV2, -1)
    pow10_core(out, S_DIV1)
    if not is_zero(out) then out.sign = s end
    return out
end

-- Integer test for exponents (values >= 1e308 count as even integers).
local function exponent_parity(y)
    if y.len > 1 then return 0 end
    local v = y.a[0]
    if v ~= floor(v) then return nil end
    return v % 2
end

local S_POW1

local function pow_core(out, x, y)
    if is_zero(y) then return set_small(out, 1) end
    local s = 1
    if x.sign == -1 and not is_zero(x) then
        local parity = exponent_parity(y)
        if parity == nil then
            stats.flagged = stats.flagged + 1
            set_zero(out)
            out.flags = FLAG_NAN
            return out
        end
        if parity == 1 then s = -1 end
    end
    if is_zero(x) then
        if y.sign == 1 then return set_zero(out) end
        stats.flagged = stats.flagged + 1
        set_max(out, 1)
        out.flags = FLAG_INF
        return out
    end
    if x.len == 1 and y.len == 1 then
        local p = x.a[0] ^ (y.sign * y.a[0])
        if p < T then return set_small(out, s * p) end
    end
    if x.len == 1 and x.a[0] == 1 then return set_small(out, s) end
    log10_core(S_POW1, x)
    mul_core(S_POW1, S_POW1, y)
    pow10_core(out, S_POW1)
    if not is_zero(out) then out.sign = s end
    return out
end

local function mod_core(out, x, y)
    if is_zero(y) then
        stats.flagged = stats.flagged + 1
        set_zero(out)
        out.flags = FLAG_NAN
        return out
    end
    if x.len == 1 and y.len == 1 then
        -- Lua semantics (result has the sign of b) via fmod, which is exact and cannot
        -- overflow the way a - floor(a/b)*b does for huge a/b
        local a, b = x.sign * x.a[0], y.sign * y.a[0]
        local r = fmod(a, b)
        if r ~= 0 and (r < 0) ~= (b < 0) then r = r + b end
        return set_small(out, r)
    end
    if cmp_abs(x, y) < 0 then
        if x.sign == y.sign or is_zero(x) then return copy(out, x) end
        return add_core(out, x, y, 1)
    end
    return set_zero(out) -- remainder of an astronomically large value is not representable
end

local function floor_core(out, x)
    if x.len == 1 then return set_small(out, floor(x.sign * x.a[0])) end
    return copy(out, x)
end

local function ceil_core(out, x)
    if x.len == 1 then return set_small(out, -floor(-(x.sign * x.a[0]))) end
    return copy(out, x)
end

-- Argument conversion ------------------------------------------------------------------------

-- Returns x as normalized cdata, writing numbers into `scratch`, or nil when x is not a number
-- or Big. Strings must be converted with `coerce` first: parsing may use the public API and
-- therefore the scratch buffers.
local function arg(x, scratch)
    local tx = type(x)
    if tx == 'number' then return set_number(scratch, x) end
    if tx == 'cdata' and istype(CT, x) then return x end
    return nil
end

-- tonumber for strings, but only finite results ("1e500" gives inf and must be parsed).
local function finite_tonumber(s)
    local n = tonumber(s)
    if n and n == n and n ~= huge and n ~= -huge then return n end
    return nil
end

-- Arithmetic coerces numeric strings like Lua does ("10" + 1); "1e500"/"ee10" are parsed too.
local function coerce(x)
    if type(x) ~= 'string' then return x end
    local n = finite_tonumber(x)
    if n then return n end
    return Big.parse and Big.parse(x) or x
end

local function arith_error(a, b)
    local bad = (type(a) == 'number' or is_big(a)) and b or a
    error('NE.Big: attempt to perform arithmetic on a ' .. type(bad) .. ' value', 3)
end

local function compare_error(a, b)
    error('NE.Big: attempt to compare ' .. type(a) .. ' with ' .. type(b), 3)
end

local SA1, SA2 -- operand scratch for the public API

local function binary(core, flip)
    if flip then
        return function(a, b)
            a, b = coerce(a), coerce(b)
            local A, B = arg(a, SA1), arg(b, SA2)
            if not A or not B then arith_error(a, b) end
            return core(alloc(), A, B, flip)
        end
    end
    return function(a, b)
        a, b = coerce(a), coerce(b)
        local A, B = arg(a, SA1), arg(b, SA2)
        if not A or not B then arith_error(a, b) end
        return core(alloc(), A, B)
    end
end

local function check_owned(dst)
    if not is_big(dst) then error('NE.Big: *_into needs a Big as first argument', 3) end
    if Big.CONSTANTS[dst] then error('NE.Big: cannot mutate a shared constant', 3) end
end

local function mutating(core, flip)
    return function(dst, x)
        check_owned(dst)
        x = coerce(x)
        local X = arg(x, SA2)
        if not X then arith_error(dst, x) end
        if flip then return core(dst, dst, X, flip) end
        return core(dst, dst, X)
    end
end

-- Unary public helper: converts x (number, Big or string) and applies fn(X).
local function unary(fn)
    return function(x)
        x = coerce(x)
        local X = arg(x, SA1)
        if not X then arith_error(x, 0) end
        return fn(X)
    end
end

-- Metatype -----------------------------------------------------------------------------------

local function concat_piece(v)
    if is_big(v) then return Big.format(v) end
    local tv = type(v)
    if tv == 'string' or tv == 'number' then return v end
    error('NE.Big: attempt to concatenate a ' .. tv .. ' value', 3)
end

local methods = {}
local mt = {
    __index = function(_, k) return methods[k] end,
    __add = binary(add_core, 1),
    __sub = binary(add_core, -1),
    __mul = binary(mul_core),
    __div = binary(div_core),
    __pow = binary(pow_core),
    __mod = binary(mod_core),
    __unm = function(a)
        local r = copy(alloc(), a)
        if not is_zero(r) then r.sign = -r.sign end
        return r
    end,
    -- Like plain Lua: == never errors (false for non-numbers), < and <= error on non-numbers.
    __eq = function(a, b)
        local A, B = arg(a, SA1), arg(b, SA2)
        if not A or not B then return false end
        return cmp(A, B) == 0
    end,
    __lt = function(a, b)
        local A, B = arg(a, SA1), arg(b, SA2)
        if not A or not B then compare_error(a, b) end
        return cmp(A, B) < 0
    end,
    __le = function(a, b)
        local A, B = arg(a, SA1), arg(b, SA2)
        if not A or not B then compare_error(a, b) end
        return cmp(A, B) <= 0
    end,
    __tostring = function(a) return Big.format(a) end,
    __concat = function(a, b) return concat_piece(a) .. concat_piece(b) end,
}

CT = ffi.metatype('ne_big', mt)
Big.ctype = CT

SA1, SA2 = CT(), CT()
S_MUL1, S_MUL2, S_DIV1, S_DIV2, S_POW1 = CT(), CT(), CT(), CT(), CT()

-- Public API -----------------------------------------------------------------------------------

Big.is = is_big
Big.normalize = normalize

-- Creates a Big from a number, a Big (copy) or a string ("1e500", "ee10", "10^^5", "neb:...").
-- Invalid input gives 0 with FLAG_NAN.
function Big.new(x)
    local tx = type(x)
    if tx == 'number' then return set_number(alloc(), x) end
    if is_big(x) then return copy(alloc(), x) end
    if tx == 'string' then
        local n = finite_tonumber(x)
        if n then return set_number(alloc(), n) end
        local b = Big.parse and Big.parse(x)
        if b then return b end
    end
    local r = set_zero(alloc())
    r.flags = FLAG_NAN
    stats.flagged = stats.flagged + 1
    return r
end

-- Builds a Big from raw fields (used by pack/unpack and tests). Always normalized.
function Big.from_array(array, sign)
    local p = alloc()
    local n = #array
    if n > CAP then n = CAP end
    for i = 1, n do
        local v = tonumber(array[i]) or 0
        p.a[i - 1] = v
    end
    p.len = n > 0 and n or 1
    p.sign = (sign == -1) and -1 or 1
    return normalize(p)
end

-- Returns x unchanged if it is already a Big, otherwise a new Big.
function Big.of(x)
    if is_big(x) then return x end
    return Big.new(x)
end

function Big.copy(x) return Big.new(x) end

Big.add = binary(add_core, 1)
Big.sub = binary(add_core, -1)
Big.mul = binary(mul_core)
Big.div = binary(div_core)
Big.pow = binary(pow_core)
Big.mod = binary(mod_core)

Big.add_into = mutating(add_core, 1)
Big.sub_into = mutating(add_core, -1)
Big.mul_into = mutating(mul_core)
Big.div_into = mutating(div_core)
Big.pow_into = mutating(pow_core)

-- dst = src (src may be a number). Returns dst.
function Big.set(dst, src)
    check_owned(dst)
    src = coerce(src)
    local S = arg(src, SA2)
    if not S then arith_error(dst, src) end
    return copy(dst, S)
end

Big.neg = unary(function(X)
    local r = copy(alloc(), X)
    if not is_zero(r) then r.sign = -r.sign end
    return r
end)

Big.abs = unary(function(X)
    local r = copy(alloc(), X)
    r.sign = 1
    return r
end)

Big.floor = unary(function(X) return floor_core(alloc(), X) end)
Big.ceil = unary(function(X) return ceil_core(alloc(), X) end)

-- log10|x| as a Big (x == 0 gives 0 with FLAG_INF; log of a negative value uses |x|).
Big.log10 = unary(function(X)
    if is_zero(X) then
        local r = set_zero(alloc())
        r.flags = FLAG_INF
        stats.flagged = stats.flagged + 1
        return r
    end
    return log10_core(alloc(), X)
end)

Big.pow10 = unary(function(X) return pow10_core(alloc(), X) end)

-- log10(x) as a Lua number, clamped to MAXD for values beyond 10^1e308.
-- Non-positive values follow math.log10 (-inf for 0, nan for negatives) like vanilla.
local log10_num_big = unary(function(X)
    if X.sign == -1 or is_zero(X) then return log10(X.sign * X.a[0]) end
    return log10_double(X) or MAXD
end)

function Big.log10_num(x)
    if type(x) == 'number' then return log10(x) end
    return log10_num_big(x)
end

-- Lua number, saturated to +-MAXD (never inf).
function Big.to_number(x)
    if type(x) == 'number' then
        if x ~= x then return 0 end
        if x > MAXD then return MAXD end
        if x < -MAXD then return -MAXD end
        return x
    end
    if not is_big(x) then return tonumber(x) or 0 end
    if x.len == 1 then return x.sign * x.a[0] end
    return x.sign * MAXD
end

-- Comparisons (accept numbers and Bigs in any combination) ------------------------------------

local SC1, SC2 = CT(), CT()

-- Strings are accepted here (unlike the < operator) so data from saves and cheats compares.
function Big.cmp(a, b)
    if type(a) == 'number' and type(b) == 'number' then
        return a < b and -1 or (a > b and 1 or 0)
    end
    a, b = coerce(a), coerce(b)
    local A, B = arg(a, SC1), arg(b, SC2)
    if not A or not B then compare_error(a, b) end
    return cmp(A, B)
end

function Big.eq(a, b)
    if type(a) == 'number' and type(b) == 'number' then return a == b end
    a, b = coerce(a), coerce(b)
    local A, B = arg(a, SC1), arg(b, SC2)
    if not A or not B then return false end
    return cmp(A, B) == 0
end

function Big.lt(a, b) return Big.cmp(a, b) < 0 end
function Big.le(a, b) return Big.cmp(a, b) <= 0 end
function Big.gt(a, b) return Big.cmp(a, b) > 0 end
function Big.ge(a, b) return Big.cmp(a, b) >= 0 end

-- Return one of the arguments (no allocation).
function Big.max(a, b) return Big.cmp(a, b) >= 0 and a or b end
function Big.min(a, b) return Big.cmp(a, b) <= 0 and a or b end

function Big.is_zero(x)
    if type(x) == 'number' then return x == 0 end
    return is_big(x) and is_zero(x)
end

function Big.sign(x)
    if type(x) == 'number' then return x < 0 and -1 or (x > 0 and 1 or 0) end
    if is_zero(x) then return 0 end
    return x.sign
end

-- Diagnostic flags (FLAG_NAN / FLAG_INF / FLAG_SAT) recorded when the value was produced.
function Big.flags(x)
    if is_big(x) then return x.flags end
    return 0
end

-- Number of hyper levels in use (0 = plain double, 1 = exponent tower, 2 = tetration...).
function Big.level(x)
    if not is_big(x) then return 0 end
    return x.len - 1
end

-- Internal access for the other bignum modules.
Big._internal = {
    alloc = alloc,
    copy = copy,
    set_zero = set_zero,
    set_max = set_max,
    set_small = set_small,
    set_number = set_number,
    set_pow10_num = set_pow10_num,
    cmp = cmp,
    cmp_abs = cmp_abs,
    is_zero = is_zero,
    arg = arg,
    coerce = coerce,
    normalize = normalize,
    add_core = add_core,
    mul_core = mul_core,
    div_core = div_core,
    pow_core = pow_core,
    log10_core = log10_core,
    pow10_core = pow10_core,
    log10_double = log10_double,
    methods = methods,
    metatable = mt,
}

-- Methods callable as x:method() -------------------------------------------------------------
methods.to_number = Big.to_number
methods.tonumber = Big.to_number
methods.format = function(x) return Big.format(x) end
methods.copy = Big.new
methods.log10 = Big.log10
methods.floor = Big.floor
methods.abs = Big.abs

-- Immutable shared constants.
Big.ZERO = Big.new(0)
Big.ONE = Big.new(1)
Big.TEN = Big.new(10)
Big.MAX = set_max(alloc(), 1)
Big.MAX.flags = 0
Big.CONSTANTS = setmetatable({}, { __mode = 'k' })
Big.CONSTANTS[Big.ZERO] = true
Big.CONSTANTS[Big.ONE] = true
Big.CONSTANTS[Big.TEN] = true
Big.CONSTANTS[Big.MAX] = true
