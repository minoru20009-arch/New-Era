-- Display notation for NE.Big (ASCII only: Balatro's pixel fonts have no arrow glyphs).
--
--   below 1e308 : the game's own number_format        123,456  /  1.235e56
--   10^x        : mantissa + exponent                  1.23e456
--   towers      : up to two leading 'e'                e1.23e456, ee1.23e45
--   tetration   : 10^^height                           10^^5, 10^^1.23e20, 10^^10^^10
--   higher      : 10{n}height                          10{3}4.32
--
-- Results are cached by value, so per-frame UI callbacks do not allocate on repeated values.

local ffi = require('ffi')
local Big = NE.Big
local I = Big._internal

local floor, log10 = math.floor, math.log10
local sformat, srep = string.format, string.rep

local MANT_MAX_EXP = 1e9 -- exponents from here on are written as "e1.23e9"
local MAX_E_PREFIX = 2   -- towers with more leading 'e' switch to 10^^ notation
local HEIGHT_SCI = 1e6   -- heights from here on are written in scientific form

-- Formats a plain double. The game's number_format is installed by bignum/hooks.lua; the
-- fallback keeps this module usable on its own (tests, early load).
local function scalar(v)
    local ref = Big.scalar_format
    if ref then return ref(v) end
    if v ~= floor(v) then return sformat('%.2f', v) end
    if v >= 1e11 or v <= -1e11 then return sformat('%.3e', v) end
    return sformat('%.0f', v)
end

-- "1.23e20" for a double x >= 1.
local function sci(x)
    local e = floor(log10(x))
    local s = sformat('%.2f', x / 10 ^ e)
    if s == '10.00' then
        e = e + 1
        s = '1.00'
    end
    return s .. 'e' .. sformat('%d', e)
end

-- Heights and counts: "5", "5.21", "1.23e20".
local function height(h)
    if h >= HEIGHT_SCI then return sci(h) end
    local s = sformat('%.2f', h)
    s = s:gsub('0+$', ''):gsub('%.$', '')
    return s
end

-- 10^L for 308 <= L < 1e308. Returns the text and 1 if the exponent itself needed an 'e'.
local function mant_exp(L)
    if L < MANT_MAX_EXP then
        local e = floor(L)
        local s = sformat('%.2f', 10 ^ (L - e))
        if s == '10.00' then
            e = e + 1
            s = '1.00'
        end
        return s .. 'e' .. sformat('%d', e), 0
    end
    return 'e' .. sci(L), 1
end

-- (10^)^k (v) with k >= 1 and v in [308, 1e308).
local function tower(v, k)
    local s, extra = mant_exp(v)
    if k - 1 + extra <= MAX_E_PREFIX then return srep('e', k - 1) .. s end
    return '10^^' .. height(k + Big.slog_double(v))
end

local function op(level)
    if level == 2 then return '^^' end
    return '{' .. level .. '}'
end

-- Height h with 10^^^h == y (pentation super-log), for a positive Big y at level <= 2.
local function pent_height(y)
    local count = 0
    while Big.gt(y, 10) and count < 16 do
        y = Big.slog(y)
        count = count + 1
    end
    return count + log10(Big.to_number(y))
end

local format_abs

-- len >= 3: value = H_top^c(inner)
local function hyper(x)
    local top = x.len - 1
    local c = x.a[top]
    local inner = I.copy(I.alloc(), x)
    inner.sign = 1
    inner.a[top] = 0
    I.normalize(inner)
    if c == 1 then
        if inner.len == 1 then return '10' .. op(top) .. height(inner.a[0]) end
        return '10' .. op(top) .. format_abs(inner)
    end
    local extra = 1
    if top == 2 and inner.len <= 3 then extra = pent_height(inner) end
    return '10' .. op(top + 1) .. height(c + extra)
end

function format_abs(x)
    local len = x.len
    if len == 1 then return scalar(x.a[0]) end
    if len == 2 then return tower(x.a[0], x.a[1]) end
    return hyper(x)
end

-- Cache ----------------------------------------------------------------------------------------
local CACHE_N = 8
local cache_a = ffi.new('double[?]', CACHE_N * Big.CAP)
local cache_len, cache_sign, cache_str = {}, {}, {}
local cache_next = 0

local function cache_get(x)
    local len, sign = x.len, x.sign
    for i = 0, CACHE_N - 1 do
        if cache_len[i] == len and cache_sign[i] == sign then
            local base = i * Big.CAP
            local same = true
            for j = 0, len - 1 do
                if cache_a[base + j] ~= x.a[j] then
                    same = false
                    break
                end
            end
            if same then return cache_str[i] end
        end
    end
    return nil
end

local function cache_put(x, s)
    local i = cache_next
    cache_next = (cache_next + 1) % CACHE_N
    local base = i * Big.CAP
    for j = 0, x.len - 1 do cache_a[base + j] = x.a[j] end
    cache_len[i], cache_sign[i], cache_str[i] = x.len, x.sign, s
end

-- Clears cached strings (the plain-number formatter changed, e.g. language switch).
function Big.clear_format_cache()
    for i = 0, CACHE_N - 1 do cache_len[i] = nil end
end

-- Public -----------------------------------------------------------------------------------------

-- Text for a Big or a number. Other values go through tostring.
function Big.format(x)
    if type(x) == 'number' then return scalar(x) end
    if not Big.is(x) then return tostring(x) end
    if x.len == 1 then return scalar(x.sign * x.a[0]) end
    local s = cache_get(x)
    if s then return s end
    s = format_abs(x)
    if x.sign == -1 then s = '-' .. s end
    cache_put(x, s)
    return s
end

Big.notation = {
    sci = sci,
    height = height,
    mant_exp = mant_exp,
    MAX_E_PREFIX = MAX_E_PREFIX,
}
