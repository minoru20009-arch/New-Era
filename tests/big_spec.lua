-- NE.Big tests (Phase 3). Loaded by run_tests.lua after the mod is loaded on the mocks.

return function(T)
    local test, check, eq, M = T.test, T.check, T.eq, T.M
    local B = NE.Big

    local function close(a, b, rel)
        rel = rel or 1e-12
        if a == b then return true end
        local d = math.abs(a - b)
        return d <= rel * math.max(math.abs(a), math.abs(b))
    end

    local function fields(x)
        local t = {}
        for i = 0, x.len - 1 do t[#t + 1] = x.a[i] end
        return t
    end

    local function same_fields(x, y)
        if x.len ~= y.len or x.sign ~= y.sign then return false end
        for i = 0, x.len - 1 do if x.a[i] ~= y.a[i] then return false end end
        return true
    end

    -- Normal-form invariants (see src/bignum/big.lua header).
    local function valid(x)
        if not B.is(x) then return false, 'not a Big' end
        if x.len < 1 or x.len > B.CAP then return false, 'len' end
        if x.sign ~= 1 and x.sign ~= -1 then return false, 'sign' end
        for i = 0, B.CAP - 1 do
            local v = x.a[i]
            if v ~= v or v == math.huge or v == -math.huge then return false, 'nan/inf field' end
            if i >= x.len and v ~= 0 then return false, 'garbage past len' end
            if i > 0 and i < x.len and (v ~= math.floor(v) or v < 0 or v > B.M) then return false, 'count' end
        end
        if x.a[0] < 0 then return false, 'negative a0' end
        if x.len > 1 and x.a[x.len - 1] == 0 then return false, 'trailing zero' end
        if x.len == 1 and x.a[0] >= B.T then return false, 'a0 >= T' end
        if x.len >= 2 and x.a[1] >= 1 and (x.a[0] < B.LT or x.a[0] >= B.T) then return false, 'a0 range' end
        if x.len >= 3 and x.a[1] == 0 and x.a[0] <= B.M then return false, 'unexpanded height' end
        if x.len == 1 and x.a[0] == 0 and x.sign ~= 1 then return false, 'negative zero' end
        return true
    end

    -- deterministic pseudo-random numbers (tests must not depend on math.random state)
    local seed = 12345
    local function rnd()
        seed = (seed * 1103515245 + 12345) % 2147483648
        return seed / 2147483648
    end

    ----------------------------------------------------------------------------------------------
    test('big: fast path matches doubles', function()
        local bad = 0
        for _ = 1, 2000 do
            local a = (rnd() - 0.5) * 10 ^ (rnd() * 300 - 150)
            local b = (rnd() - 0.5) * 10 ^ (rnd() * 300 - 150)
            local A, Bb = B.new(a), B.new(b)
            if not close(B.to_number(A + Bb), a + b, 1e-12) then bad = bad + 1 end
            if not close(B.to_number(A - b), a - b, 1e-12) then bad = bad + 1 end
            if not close(B.to_number(a * Bb), a * b, 1e-12) then bad = bad + 1 end
            if b ~= 0 and not close(B.to_number(A / Bb), a / b, 1e-12) then bad = bad + 1 end
        end
        eq(bad, 0, 'add/sub/mul/div agree with doubles below 1e308')
        eq(B.to_number(B.new(2) ^ 10), 1024, '2^10')
        check(close(B.to_number(B.new(2) ^ 0.5), math.sqrt(2)), '2^0.5')
        eq(B.to_number(B.new(7) % 3), 1, '7 % 3')
        eq(B.to_number(B.new(-7) % 3), 2, '-7 % 3 follows Lua')
        eq(B.to_number(B.new(7) % -3), -2, '7 % -3 follows Lua')
        local m = B.mod(1e300, 1e-300) -- regression (fuzz): a/b overflowed to inf
        check(valid(m) and B.to_number(m) >= 0 and B.to_number(m) < 1e-300, 'mod with a huge ratio stays finite')
        eq(B.to_number(-B.new(5)), -5, 'unary minus')
        eq(B.to_number(B.floor(-2.5)), -3, 'floor')
        eq(B.to_number(B.ceil(2.1)), 3, 'ceil')
        eq(B.new(-0.0).sign, 1, '-0 becomes +0')
    end)

    test('big: past 1e308', function()
        local x = B.new(1e200) * 1e200
        eq(B.level(x), 1, '1e400 is a level-1 value')
        check(close(B.log10_num(x), 400), 'log10(1e200*1e200) = 400')
        check(close(B.to_number(x / 1e200), 1e200, 1e-12), '(1e400)/1e200 back to a double')
        check(close(B.log10_num(x + x), 400 + math.log10(2), 1e-14), '1e400 + 1e400')
        check(B.is_zero(x - x), 'x - x = 0')
        check(B.eq(x - 1, x), 'x - 1 = x at stored precision')
        check(close(B.log10_num(x * x * x), 1200), '(1e400)^3')
        check(close(B.log10_num(B.pow(10, 1000)), 1000), '10^1000')
        check(close(B.log10_num(B.sqrt and B.sqrt(x) or B.pow(x, 0.5)), 200), 'sqrt(1e400)')
        local y = B.pow(B.pow(10, 1e10), 1e10) -- 10^(1e20)
        check(close(B.log10_num(y), 1e20), '(10^1e10)^1e10 = 10^1e20')
        local z = B.pow(10, y) -- 10^10^1e20
        eq(B.level(z), 1, '10^10^1e20 stays level 1 (tower count 2)')
        eq(z.a[1], 2, 'tower count 2')
        check(close(z.a[0], 1e20), 'innermost 1e20 (10^10^1e20)')
        check(B.eq(z * 1e300, z), 'multiplying a tower by a double changes nothing stored')
        check(B.is_zero(B.pow(0.5, x)), '0.5^1e400 underflows to 0')
        check(B.is_zero(B.new(1) / x), '1/1e400 underflows to 0')
        eq(B.to_number(B.pow(1, x)), 1, '1^1e400 = 1')
        eq(B.to_number(x), B.MAXD, 'to_number saturates to the largest finite double')
        eq(B.to_number(-x), -B.MAXD, 'to_number saturates negatives')
    end)

    test('big: invalid input never gives nan/inf', function()
        local n = B.new(0 / 0)
        check(B.is_zero(n) and B.flags(n) == B.FLAG_NAN, 'nan -> 0 with FLAG_NAN')
        local i = B.new(math.huge)
        check(valid(i) and B.flags(i) == B.FLAG_INF, 'inf -> saturated with FLAG_INF')
        local d = B.div(5, 0)
        check(valid(d) and d.sign == 1, '5/0 saturates')
        local z = B.div(0, 0)
        check(B.is_zero(z) and B.flags(z) == B.FLAG_NAN, '0/0 -> 0')
        local r = B.pow(-2, 0.5)
        check(B.is_zero(r) and B.flags(r) == B.FLAG_NAN, '(-2)^0.5 -> 0')
        eq(B.to_number(B.pow(-2, 3)), -8, '(-2)^3')
        local bad = B.new('not a number')
        check(B.is_zero(bad) and B.flags(bad) == B.FLAG_NAN, 'bad string -> 0 with FLAG_NAN')
        check(not pcall(function() return B.new(1) + {} end), 'arithmetic with a table errors like Lua')
        check(not pcall(B.mul_into, B.ZERO, 2), 'constants cannot be mutated')
    end)

    test('big: comparisons and __eq', function()
        local five, big = B.new(5), B.new('1e500')
        check(five == 5 and 5 == five, '__eq with numbers (both orders)')
        check(five ~= 6, '~= with numbers')
        check(five ~= nil and not (five == nil), 'compare with nil')
        check(not (five == '5'), 'never equal to a string (like Lua)')
        check(five < 6 and 4 < five and five <= 5 and 5 >= five, 'mixed < <= > >=')
        check(big > 1e308 and 1e308 < big, 'Big above any double')
        check(-big < -1e308, 'negative ordering')
        check(not pcall(function() return five < 'x' end), '< with a string errors like Lua')
        check(B.eq('1e500', big), 'Big.eq accepts strings')
        eq(B.cmp(3, 4), -1, 'cmp numbers')
        check(rawequal(B.max(3, big), big) and rawequal(B.min(3, big), 3), 'max/min return arguments')

        -- strictly increasing across every level
        local ladder = {
            B.new(-1e400), B.new(-1), B.new(0), B.new(1e-300), B.new(1), B.new(1e307), B.new(9.99e307),
            B.new(1e308), B.new('1e500'), B.new('ee10'), B.new('e1e300'), B.new('eee1e300'),
            B.arrow(10, 2, 1e20), B.arrow(10, 2, 1e30), B.arrow(10, 3, 3), B.arrow(10, 3, 1e20),
            B.arrow(10, 4, 3), B.arrow(10, 7, 3), B.MAX,
        }
        local ok = true
        for i = 1, #ladder - 1 do
            if not (ladder[i] < ladder[i + 1]) or B.cmp(ladder[i + 1], ladder[i]) ~= 1 then
                ok = false
                print('    ladder break at ' .. i .. ': ' .. B.format(ladder[i]) .. ' vs ' .. B.format(ladder[i + 1]))
            end
        end
        check(ok, 'ordering is strict across levels')
    end)

    test('big: hyper-operators', function()
        eq(B.to_number(B.arrow(2, 2, 4)), 65536, '2^^4')
        eq(B.to_number(B.arrow(3, 2, 3)), 7625597484987, '3^^3')
        check(close(B.log10_num(B.arrow(2, 2, 5)), 65536 * math.log10(2), 1e-12), '2^^5 = 2^65536')
        local t5 = B.arrow(10, 2, 5)
        check(same_fields(t5, B.from_array({ 1e10, 3 })), '10^^5 = [1e10, 3]')
        check(B.eq(B.tetrate(10, 5), t5), 'tetrate alias')
        check(same_fields(B.arrow(10, 3, 3), B.from_array({ 1e10, 8, 1 })), '10^^^3 = 10^^(10^^10)')
        check(same_fields(B.arrow(10, 3, 2), B.from_array({ 1e10, 8 })), '10^^^2 = 10^^10')
        eq(B.to_number(B.arrow(2, 3, 3)), 65536, '2^^^3 = 2^^4')
        check(close(B.to_number(B.arrow(10, 2, 0.5)), math.sqrt(10)), '10^^0.5 = 10^0.5 (linear convention)')
        check(close(B.to_number(B.arrow(10, 2, -0.5)), 0.5), '10^^-0.5 = 0.5')
        check(B.is_zero(B.arrow(10, 2, -2)), '10^^-2 -> 0')
        check(close(B.to_number(B.arrow(7, 2, 2.5)), 7 ^ (7 ^ (7 ^ 0.5)), 1e-9), '7^^2.5')
        eq(B.to_number(B.arrow(1, 5, 1e9)), 1, '1{5}x = 1')
        check(B.to_number(B.arrow(1.2, 2, 1e6)) < 1.3, 'convergent tower (1.2^^1e6)')
        eq(B.to_number(B.arrow(3, 1, 4)), 81, 'n = 1 is a power')
        eq(B.to_number(B.arrow(3, 0, 4)), 12, 'n = 0 is a product')
        local sat = B.arrow(10, 8, 3)
        check(B.flags(sat) == B.FLAG_SAT and B.eq(sat, B.MAX), '10{8}3 saturates')
        check(B.arrow(2, 2, 1e20) > B.arrow(2, 2, 1e19), 'huge heights keep ordering')
        check(B.eq(B.slog(t5), 5), 'slog(10^^5) = 5')
        check(same_fields(B.slog(B.arrow(10, 3, 3)), B.from_array({ 1e10, 8 })), 'slog(10^^^3) = 10^^10')
        local t0 = os.clock()
        B.arrow(2, 4, 3)
        B.arrow(3, 3, 3)
        B.arrow(1.5, 2, 1e15)
        check(os.clock() - t0 < 0.5, 'hyper-operators on huge heights finish quickly')
        -- regression (fuzz): bases below 2 converge at high arrow counts; must stop at the
        -- fixed point instead of running to the step cap
        t0 = os.clock()
        local fp = B.arrow(1.8595, 7, 1.6e5)
        check(os.clock() - t0 < 0.05, 'fixed point detected quickly (1.8595{7}1.6e5)')
        check(B.level(fp) == 0 and math.abs(B.to_number(fp) - 2.25351113987) < 1e-9, 'converges to its fixed point')
        check(B.eq(B.arrow(1.8595, 7, 100), fp), 'same fixed point from a lower height')
    end)

    test('big: normal form survives random operations', function()
        local ops = {
            function(a, b) return a + b end,
            function(a, b) return a - b end,
            function(a, b) return a * b end,
            function(a, b) return a / b end,
            function(a, b) return B.pow(B.abs(a), B.log10_num(B.abs(b) + 2) / 10) end,
            function(a, b) return B.arrow(2 + rnd() * 8, 2, rnd() * 6) end,
            function(a, b) return B.arrow(10, 2 + math.floor(rnd() * 4), rnd() * 5) end,
            function(a) return B.pow10(B.log10(B.abs(a) + 1)) end,
            function(a, b) return B.floor(a) end,
        }
        local pool = { B.new(0), B.new(1), B.new(-3.5), B.new(1e300), B.new('1e500'), B.new('ee10'), B.arrow(10, 2, 7) }
        local failures = 0
        for _ = 1, 3000 do
            local a = pool[1 + math.floor(rnd() * #pool)]
            local b = pool[1 + math.floor(rnd() * #pool)]
            local op = ops[1 + math.floor(rnd() * #ops)]
            local ok, r = pcall(op, a, b)
            if not ok then
                failures = failures + 1
                if failures < 4 then print('    op error: ' .. tostring(r)) end
            else
                local good, why = valid(r)
                if not good then
                    failures = failures + 1
                    if failures < 4 then print('    invalid result (' .. why .. '): ' .. B.pack(r)) end
                end
                pool[1 + math.floor(rnd() * #pool)] = r
            end
        end
        eq(failures, 0, 'no errors and every result in normal form')
    end)

    test('big: notation', function()
        eq(B.format(B.new('1e500')), '1.00e500', '1e500')
        eq(B.format(B.new('-1e500')), '-1.00e500', 'negative')
        eq(B.format(B.new('ee10')), 'e1.00e10', 'ee10')
        eq(B.format(B.pow10(B.new('1.23e456'))), 'e1.23e456', 'e1.23e456')
        eq(B.format(B.new('ee1.23e45')), 'ee1.23e45', 'ee1.23e45')
        eq(B.format(B.arrow(10, 2, 5)), '10^^5', '10^^5')
        eq(B.format(B.arrow(10, 2, 5.5)), '10^^5.5', '10^^5.5')
        eq(B.format(B.arrow(10, 2, 1e20)), '10^^1.00e20', '10^^1e20')
        eq(B.format(B.arrow(10, 3, 3)), '10^^10^^10', '10^^^3')
        eq(B.format(B.arrow(10, 3, 10)), '10{3}10', '10^^^10')
        eq(B.format(B.new(12345)), number_format(12345), 'small values use the game format')
        eq(B.format(B.new(1e200)), number_format(1e200), 'below 1e308 uses the game format')
        eq(tostring(B.new('1e500')), '1.00e500', '__tostring')
        eq('x' .. B.new('1e500') .. 'y', 'x1.00e500y', '__concat')
        eq(B.format(B.MAX), '10{8}9.01e15', 'MAX (2^53 applications of 10{7})')
        local longest = 0
        for _, v in ipairs({ '1e500', '1e99999999', 'e1e20', 'ee1e300', '10^^1e300', '10{3}5', '10{7}1e15' }) do
            local s = B.format(B.new(v))
            if #s > longest then longest = #s end
        end
        check(longest <= 14, 'notation stays short (longest ' .. longest .. ' chars)')

        local x = B.new('1e777')
        local s1 = B.format(x)
        local allocs = B.stats.allocs
        local s2 = B.format(B.new('1e777'))
        check(rawequal(s1, s2), 'cached string reused for an equal value')
        for _ = 1, 100 do B.format(x) end
        eq(B.stats.allocs, allocs + 1, 'formatting a cached value allocates no Big')
    end)

    test('big: pack, unpack, parse', function()
        local values = {
            B.new(0), B.new(-1.5), B.new(1 / 3), B.new(1.7976931348623157e308), B.new('1e500'),
            B.new('-ee10'), B.arrow(10, 2, 7.25), B.arrow(3, 3, 3), B.arrow(10, 5, 2), B.MAX,
        }
        for _ = 1, 200 do values[#values + 1] = B.pow(10, rnd() * 1e6) * rnd() end
        local exact = true
        for _, v in ipairs(values) do
            local p = B.pack(v)
            local u = B.unpack(p)
            if not (u and same_fields(u, v)) then
                exact = false
                print('    roundtrip failed: ' .. p)
            end
        end
        check(exact, 'pack/unpack keeps every field exactly')
        check(B.is_packed(B.pack(5)), 'pack of a number')
        eq(B.pack_value(5), 5, 'pack_value leaves plain values')
        eq(B.unpack('neb:1:2:1,2,3'), nil, 'length mismatch rejected')
        eq(B.unpack('neb:x'), nil, 'malformed rejected')

        check(B.eq(B.parse('1e500'), B.pow(10, 500)), 'parse 1e500')
        check(B.eq(B.parse('ee10'), B.pow(10, B.pow(10, 10))), 'parse ee10')
        check(B.eq(B.parse('10^^5'), B.arrow(10, 2, 5)), 'parse 10^^5')
        check(B.eq(B.parse('10{3}3'), B.arrow(10, 3, 3)), 'parse 10{3}3')
        check(B.eq(B.parse(' -2.5e400 '), -B.parse('2.5e400')), 'parse negative with spaces')
        eq(B.parse('abc'), nil, 'parse rejects text')
        eq(B.to_number(B.new('123')), 123, 'plain numeric string')

        local t = { a = B.pack(B.new('1e500')), b = { c = B.pack(B.new(7)), d = 'neb-not', e = 3 } }
        B.rehydrate(t)
        check(B.is(t.a) and B.eq(t.a, '1e500'), 'rehydrate top level')
        check(B.is(t.b.c) and B.eq(t.b.c, 7), 'rehydrate nested')
        eq(t.b.d, 'neb-not', 'other strings untouched')
    end)

    test('big: Lovely patches apply to the anchors', function()
        eq(#M.patch_results, 5, 'five pattern patches found for the test sources')
        for _, r in ipairs(M.patch_results) do
            eq(r.matches, 1, 'one match: ' .. r.pattern:sub(1, 50))
        end
    end)

    test('big: save and load keep values (L6 + STR_UNPACK)', function()
        eq(NE.Big.hooks.cull, 'lovely', 'patched recursive_table_cull detected at load')
        M.start_run()
        G.GAME.chips = B.new('1e500')
        G.GAME.round_scores.hand.amt = B.new('ee10')
        G.GAME.newera.test_value = B.arrow(10, 2, 5)
        local blind = { chips = B.arrow(10, 3, 3), chip_text = number_format(B.arrow(10, 3, 3)) }
        local culled = recursive_table_cull({ GAME = G.GAME, BLIND = blind, obj = M.new_object() })
        eq(type(culled.GAME.chips), 'string', 'Big packed by the patched cull')
        eq(culled.obj, '"MANUAL_REPLACE"', 'objects still replaced')
        local text = STR_PACK(culled)
        check(not text:find('cdata'), 'serialized text has no cdata')
        local loaded = STR_UNPACK(text)
        check(B.is(loaded.GAME.chips) and B.eq(loaded.GAME.chips, '1e500'), 'chips restored as Big')
        check(same_fields(loaded.BLIND.chips, B.arrow(10, 3, 3)), 'blind target restored exactly')
        check(B.eq(loaded.GAME.newera.test_value, B.arrow(10, 2, 5)), 'NE state value restored')
        -- "Continue" preview reads the unpacked save before the run starts
        eq(number_format(loaded.GAME.round_scores.hand.amt), 'e1.00e10', 'continue screen formats the best hand')
        G:start_run({ savetext = loaded })
        check(B.eq(G.GAME.chips, '1e500'), 'start_run gets the Big score')

        -- a checkpoint (culled table, never unpacked) is rehydrated by start_run
        local culled2 = recursive_table_cull({ GAME = { chips = B.new('1e600'), newera = {} } })
        G:start_run({ savetext = culled2 })
        check(B.is(G.GAME.chips) and B.eq(G.GAME.chips, '1e600'), 'start_run rehydrates culled tables')

        -- fallback when the Lovely patch is missing
        M.load_patch_sources(true)
        eq(B.ensure_cull(), 'fallback', 'unpatched cull detected')
        local c = recursive_table_cull({ x = B.new(5), o = M.new_object(), n = { y = B.new('1e400') } })
        check(type(c.x) == 'string' and type(c.n.y) == 'string', 'fallback packs Big values')
        eq(c.o, '"MANUAL_REPLACE"', 'fallback replaces objects')
        M.load_patch_sources()
        eq(B.ensure_cull(), 'lovely', 'patched cull detected again')
    end)

    test('big: number helpers and math.*', function()
        eq(number_format(B.new('1e500')), '1.00e500', 'number_format(Big)')
        eq(number_format(12345), '12,345', 'number_format(number) unchanged')
        eq(number_format(B.new(12345)), '12,345', 'number_format(small Big) like a number')
        check(score_number_scale(1, B.new('1e500')) <= 0.7, 'score_number_scale(Big)')
        check(scale_number(B.arrow(10, 3, 3), 1, 10000) <= scale_number(1e20, 1, 10000), 'scale_number shrinks long text')
        local big = B.new('1e500')
        check(B.is(math.floor(big)) and B.eq(math.floor(big), big), 'math.floor(Big) is a Big')
        eq(math.floor(2.5), 2, 'math.floor(number)')
        check(rawequal(math.max(1, big), big), 'math.max returns the Big argument')
        eq(math.max(1, 5, 3), 5, 'math.max numbers')
        eq(math.max(1, 2, big, 4) == big, true, 'math.max vararg with Big')
        eq(math.min(big, 5), 5, 'math.min returns the number')
        eq(math.max(7), 7, 'math.max with one argument')
        check(rawequal(math.min(big), big), 'math.min with one Big argument')
        check(not pcall(math.max), 'math.max() still errors like vanilla')
        eq(math.log10(big), 500, 'math.log10(Big) is a number')
        check(close(math.log(big), 500 * math.log(10), 1e-12), 'math.log(Big)')
        check(close(math.log(big, 10), 500, 1e-12), 'math.log(Big, 10)')
        eq(type(math.log(8, 2)), 'number', 'math.log(number, base)')
        check(B.eq(math.abs(-big), big), 'math.abs(Big)')
        check(close(B.log10_num(math.sqrt(B.new('1e400'))), 200), 'math.sqrt(Big)')
        check(close(B.to_number(math.exp(B.new(1))), math.exp(1), 1e-12), 'math.exp(Big)')
        eq(math.log10(100), 2, 'math.log10(number)')
    end)

    test('big: scores, profile, sound', function()
        M.start_run()
        G.PROFILES[1].high_scores.hand.amt = 0
        check_and_set_high_score('hand', B.new('1e500'))
        check(B.is(G.GAME.round_scores.hand.amt) and B.eq(G.GAME.round_scores.hand.amt, '1e500'), 'run best hand keeps the Big')
        eq(G.PROFILES[1].high_scores.hand.amt, B.MAXD, 'profile high score is a finite number')
        -- regression (Phase 3 in-game test): the Stats screen showed "nane-922..." for it
        eq(number_format(G.PROFILES[1].high_scores.hand.amt), '1.80e308', 'profile high score displays')
        eq(number_format(1.7976931348622999e308), '1.80e308', 'near-max double displays')
        eq(number_format(-1.5e308), '-1.50e308', 'negative near-max double displays')
        eq(number_format(9.9e307), '9.9e307', 'below 1e308 keeps the game format')
        -- same value after a save/load round trip of the profile (numbers keep ~14 digits)
        local reloaded = STR_UNPACK(STR_PACK({ amt = G.PROFILES[1].high_scores.hand.amt }))
        eq(number_format(reloaded.amt), '1.80e308', 'reloaded profile high score displays')
        check_and_set_high_score('hand', 100)
        check(B.eq(G.GAME.round_scores.hand.amt, '1e500'), 'smaller score does not replace it')

        inc_career_stat('c_test', B.new('1e500'))
        inc_career_stat('c_test', B.new('1e500'))
        eq(G.PROFILES[1].career_stats.c_test, B.MAXD, 'career stat clamped, never inf')

        G.PROFILES[1].career_stats.sneaky = B.new(42)
        G.SETTINGS.sneaky = B.new('1e500')
        G:save_settings()
        eq(G.PROFILES[1].career_stats.sneaky, 42, 'profile sanitised before saving')
        eq(G.SETTINGS.sneaky, B.MAXD, 'settings sanitised before saving')
        G.SETTINGS.sneaky = nil

        local mul = SMODS.Scoring_Calculations.multiply
        eq(mul:func(10, 20), 200, 'multiply stays a number below 1e308')
        local r = mul:func(1e200, 1e200)
        check(B.is(r) and close(B.log10_num(r), 400), 'overflowing product becomes a Big')
        local ri = mul:func(math.huge, 2)
        check(B.is(ri) and B.flags(ri) == 0 and close(B.log10_num(ri), math.log10(B.MAXD * 2)), 'inf chips clamped, not saturated')
        check(B.is(mul:func(B.new('1e500'), 2)), 'Big x number')
        eq(mul:func(0 / 0, 2), 0, 'nan chips -> 0')
        -- the scoring end of a hand: G.GAME.chips + math.floor(score)
        local total = 0 + math.floor(SMODS.Scoring_Calculations.multiply:func(1e155 * 30, 1e155 * 4))
        check(B.is(total) and total > 1e308, 'hand score above 1e308 reaches G.GAME.chips')
        check(total - B.new(300) >= 0, 'win check expression works')

        -- modulate_sound with the L7/L8a patches
        G.GAME.blind = { chips = B.new('1e500') }
        G.GAME.current_round.current_hand.chips = 10
        G.GAME.current_round.current_hand.mult = 20
        test_modulate_sound()
        local si = G.ARGS.score_intensity
        check(type(si.earned_score) == 'number' and type(si.required_score) == 'number', 'sound gets plain numbers')
        check(si.earned_score < si.required_score, 'ordering kept (200 < 1e500)')
        G.GAME.current_round.current_hand.chips = B.new('1e600')
        eq(test_modulate_sound(), true, 'Big hand values count as numbers (L8a)')
        check(type(si.earned_score) == 'number' and si.earned_score >= si.required_score, 'earned >= required')
        G.GAME.current_round.current_hand.chips = B.arrow(10, 2, 7)
        G.GAME.blind.chips = B.arrow(10, 2, 6)
        test_modulate_sound()
        check(si.earned_score >= si.required_score and si.earned_score <= 1e300, 'towers: ordering only')
        G.GAME.current_round.current_hand.chips = 10
        test_modulate_sound()
        check(si.earned_score < si.required_score, 'towers: smaller earned stays smaller')
        local allocs = B.stats.allocs
        G.GAME.current_round.current_hand.chips = 10
        for _ = 1, 50 do test_modulate_sound() end
        eq(B.stats.allocs, allocs, 'sound path allocates nothing for a Big target')

        -- update_hand_text delta (L8b) and juice (L8c)
        G.GAME.current_round.current_hand.chips = 5
        local delta = test_hand_delta({ chips = B.new('1e500') }, 'chips')
        check(B.is(delta) and delta > 0, 'delta computed for Big values')
        eq('+' .. delta, '+1.00e500', 'delta text')
        G.GAME.current_round.current_hand.chips = B.new('1e500')
        test_hand_type_UI_set({ config = { type = 'chips' } })
        eq(M.last_juice, 30, 'juice for Big hand values, clamped')
        G.FUNCS.text_super_juice({}, 0 / 0)
        eq(M.last_juice, 0, 'nan juice -> 0')
        G.FUNCS.text_super_juice({}, 5)
        eq(M.last_juice, 5, 'small juice unchanged')
        G.GAME.blind = nil
    end)

    test('big: cheats and test joker', function()
        M.start_run()
        G.GAME.blind = { chips = 300, chip_text = '300' }
        G.STATE = G.STATES.SELECTING_HAND
        G.FUNCS.ne_cheat_score_1e500()
        check(B.eq(G.GAME.chips, '1e500'), 'score = 1e500')
        G.GAME.chips = 0
        for _ = 1, 3 do G.FUNCS.ne_cheat_score_mul() end
        check(B.is(G.GAME.chips) and close(B.log10_num(G.GAME.chips), 450), 'score x1e150 three times = 1e450')
        G.FUNCS.ne_cheat_target_ee10()
        eq(G.GAME.blind.chip_text, 'e1.00e10', 'target ee10 text')
        G.FUNCS.ne_cheat_target_tet5()
        eq(G.GAME.blind.chip_text, '10^^5', 'target 10^^5 text')
        check(G.GAME.chips - G.GAME.blind.chips < 0, '1e450 does not beat 10^^5')
        G.FUNCS.ne_cheat_hand_display()
        check(B.is(M.last_hand_text.chips) and B.is(M.last_hand_text.mult), 'hand display cheat sends Big values')
        G.FUNCS.ne_cheat_give_overflow()
        eq(M.added_cards[#M.added_cards].key, 'j_ne_test_overflow', 'give overflow joker')

        local joker
        for _, j in ipairs(SMODS.Joker.list) do if j.key == 'test_overflow' then joker = j end end
        local card = { ability = { extra = joker.config.extra } }
        local ret = joker:calculate(card, { joker_main = true })
        eq(ret.xchips, 1e155, 'overflow joker xchips')
        eq(joker:loc_vars({}, card).vars[1], number_format(1e155), 'overflow joker text')
        G.GAME.blind = nil
    end)

    test('big: runtime check and performance', function()
        for k, v in pairs(B.runtime) do eq(v, true, 'runtime check ' .. k) end
        local found = false
        for _, l in ipairs(M.logs) do
            if l.msg:find('NE.Big runtime check passed', 1, true) then found = true end
        end
        check(found, 'runtime check logged at load')

        local x, y = B.new('1e500'), B.new(12345)
        local allocs = B.stats.allocs
        local c = 0
        for i = 1, 10000 do
            if x > i then c = c + 1 end
            if y == i then c = c + 1 end
            if B.lt(y, x) then c = c + 1 end
        end
        eq(B.stats.allocs, allocs, 'comparisons allocate nothing')

        local acc = B.new(1)
        local t0 = os.clock()
        for i = 1, 20000 do
            B.mul_into(acc, 1.001)
            B.add_into(acc, i)
        end
        local dt = os.clock() - t0
        check(dt < 0.5, ('20k mutating mul+add in %.1f ms'):format(dt * 1000))
        t0 = os.clock()
        local s = B.new('1e500')
        for i = 1, 20000 do s = s * 1.5 + i end
        dt = os.clock() - t0
        check(dt < 1.0, ('20k allocating mul+add past 1e308 in %.1f ms'):format(dt * 1000))
    end)
end
