-- Saving and loading NE.Big values, plus parsing of human-written numbers.
--
-- Balatro's save path (recursive_table_cull -> STR_PACK -> save thread) only accepts plain
-- data, and STR_PACK writes numbers with about 14 digits. Big values are therefore stored as
-- strings "neb:<sign>:<len>:<a0>,<a1>,..." with %.17g (full double precision):
--   save: lovely/10_bignum.toml patches recursive_table_cull to call NE.Big.pack_value
--   load: bignum/hooks.lua rehydrates every table returned by STR_UNPACK and every
--         Game:start_run savetext, turning those strings back into Big values.

local Big = NE.Big

local PREFIX = 'neb:'
local sformat, tonumber = string.format, tonumber

function Big.pack(x)
    x = Big.of(x)
    local s = PREFIX .. x.sign .. ':' .. x.len .. ':' .. sformat('%.17g', x.a[0])
    for i = 1, x.len - 1 do s = s .. ',' .. sformat('%.17g', x.a[i]) end
    return s
end

function Big.is_packed(s)
    return type(s) == 'string' and s:sub(1, 4) == PREFIX
end

-- Returns a Big, or nil (and a warning) for malformed input.
function Big.unpack(s)
    if not Big.is_packed(s) then return nil end
    local sign, len, body = s:match('^neb:(%-?%d+):(%d+):([^:]+)$')
    sign, len = tonumber(sign), tonumber(len)
    if not sign or not len or len < 1 or len > Big.CAP then
        NE.log.warn_once('bad_pack', 'Ignoring malformed big number in save data: %s', s)
        return nil
    end
    local array = {}
    for field in body:gmatch('[^,]+') do
        local v = tonumber(field)
        if not v then
            NE.log.warn_once('bad_pack', 'Ignoring malformed big number in save data: %s', s)
            return nil
        end
        array[#array + 1] = v
    end
    if #array ~= len then
        NE.log.warn_once('bad_pack', 'Ignoring malformed big number in save data: %s', s)
        return nil
    end
    return Big.from_array(array, sign)
end

-- Save hook: Big -> packed string; any other value unchanged.
function Big.pack_value(v)
    if Big.is(v) then return Big.pack(v) end
    return v
end

-- Replaces packed strings inside `t` (recursively) with Big values. Returns `t`.
-- Only plain tables are visited (save data never contains objects).
local MAX_DEPTH = 64

local function rehydrate(t, depth)
    if depth > MAX_DEPTH then return end
    for k, v in pairs(t) do
        local tv = type(v)
        if tv == 'string' then
            if v:byte(1) == 110 and v:sub(1, 4) == PREFIX then -- 110 = 'n'
                local b = Big.unpack(v)
                if b then t[k] = b end
            end
        elseif tv == 'table' and getmetatable(v) == nil then
            rehydrate(v, depth + 1)
        end
    end
end

function Big.rehydrate(t)
    if type(t) == 'table' then rehydrate(t, 0) end
    return t
end

-- Parsing ------------------------------------------------------------------------------------
-- Accepts: plain numbers ("123", "1.5e20"), overflowing exponents ("1e500", "2.5e1e9" is not
-- supported), leading-e towers ("ee10", "e1.23e456"), "A^^B", "A{n}B" and packed "neb:" text.
-- Returns a Big or nil.

local parse

local function parse_plain(s)
    local n = tonumber(s)
    if n and n == n and n ~= math.huge and n ~= -math.huge then return Big.new(n) end
    local m, e = s:match('^([%d%.]+)[eE]([%+%-]?[%d%.]+)$')
    m, e = tonumber(m), tonumber(e)
    if not m or not e or m <= 0 then return nil end
    return Big.pow10(e + math.log10(m))
end

function parse(s)
    if type(s) ~= 'string' then return nil end
    s = s:match('^%s*(.-)%s*$')
    if s == '' then return nil end
    if Big.is_packed(s) then return Big.unpack(s) end

    if s:sub(1, 1) == '-' then
        local r = parse(s:sub(2))
        return r and Big.neg(r) or nil
    end

    local a, n, b = s:match('^(.-){(%d+)}(.+)$')
    if a then
        local A, B = parse(a), parse(b)
        if not A or not B then return nil end
        return Big.arrow(A, tonumber(n), B)
    end
    a, b = s:match('^(.-)%^%^(.+)$')
    if a then
        local A, B = parse(a), parse(b)
        if not A or not B then return nil end
        return Big.arrow(A, 2, B)
    end

    local es, rest = s:match('^(e+)(.+)$')
    if es then
        local r = parse(rest)
        if not r then return nil end
        for _ = 1, #es do r = Big.pow10(r) end
        return r
    end
    return parse_plain(s)
end

Big.parse = parse
