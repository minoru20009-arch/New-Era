-- Phase 6 tests: formations (patterns, evaluator, chain, cache), the Steamodded integration
-- (poker hands, get_poker_hand_info, preview, Chain phase, planets, Run Info diagram), patch L12,
-- saves from before Phase 6, cheats and localization.

return function(T)
    local test, check, eq, M = T.test, T.check, T.eq, T.M
    local Formation = NE.Formation
    local Patterns = Formation.Patterns
    local Board = NE.Board
    local F = M.formations
    local K = Formation.K

    -- Synthetic board states ----------------------------------------------------------------------------
    -- Rows of tokens: '.' empty, 'H7' = 7 of Hearts (T J Q K A), 'W5' = Wild 5 (every suit),
    -- 'X' = Stone (no rank, no suit). Suffixes: r = Residue, d = Demon, b = Blessed.
    local RANK = { ['2'] = 2, ['3'] = 3, ['4'] = 4, ['5'] = 5, ['6'] = 6, ['7'] = 7, ['8'] = 8, ['9'] = 9,
        T = 10, J = 11, Q = 12, K = 13, A = 14 }
    local SUIT_BIT = { S = 1, H = 2, C = 4, D = 8, W = 15 }

    local function blank(cols, rows)
        local st = { cols = cols, rows = rows, n = cols * rows, cap = 3, card = {}, new = {}, rank = {}, suit = {}, flag = {} }
        for s = 1, st.n do st.card[s], st.new[s], st.rank[s], st.suit[s], st.flag[s] = false, false, 0, 0, 0 end
        return st
    end

    local function put(st, s, tok)
        local base, mods = tok:match('^(X)(%a*)$')
        if not base then base, mods = tok:match('^(%a[%dTJQKA])(%a*)$') end
        assert(base, 'bad token ' .. tok)
        st.card[s] = tok
        st.new[s] = not mods:find('r')
        if base == 'X' then
            st.rank[s], st.suit[s] = 0, 0
        else
            st.rank[s] = RANK[base:sub(2)]
            st.suit[s] = SUIT_BIT[base:sub(1, 1)]
        end
        local f = 0
        if mods:find('d') then f = f + Formation.FLAG_DEMON end
        if mods:find('b') then f = f + Formation.FLAG_BLESSED end
        st.flag[s] = f
    end

    local function grid(rows_spec)
        local rows = #rows_spec
        local cols
        local toks = {}
        for r, line in ipairs(rows_spec) do
            local n = 0
            for tok in line:gmatch('%S+') do
                n = n + 1
                toks[#toks + 1] = tok
            end
            cols = cols or n
            assert(n == cols, 'row ' .. r .. ' has ' .. n .. ' cells')
        end
        local st = blank(cols, rows)
        for s, tok in ipairs(toks) do
            if tok ~= '.' then put(st, s, tok) end
        end
        return st
    end

    local function run(rows_spec, cap)
        local st = grid(rows_spec)
        return Formation.run(st, cap or 3), st
    end

    local function count(res, name)
        local list = res.found[K[name]]
        return list and #list or 0
    end

    local function chain(res)
        local out = {}
        for i, link in ipairs(res.chain) do out[i] = Formation.DEF[link.key].name end
        return table.concat(out, '+')
    end

    local function slots(list)
        return table.concat(list, ',')
    end

    -- Patterns -----------------------------------------------------------------------------------------------

    test('formation patterns 5x3', function()
        local P = Patterns.get(5, 3)
        eq(#P.pairs, 22, 'adjacent pairs')
        eq(#P.lines, 20, 'lines of 3')
        eq(#P.rows, 3, 'rows')
        eq(#P.blocks, 8, '2x2 blocks')
        eq(#P.compass, 3, 'compass')
        eq(#P.full, 15, 'full board')
        eq(Patterns.get(5, 3), P, 'cached per size')
        eq(slots(P.rows[1]), '1,2,3,4,5', 'row 1 left to right')
        eq(slots(P.compass[1]), '7,2,6,8,12', 'compass: centre, up, left, right, down')
        local seen = {}
        for _, l in ipairs(P.lines) do seen[slots(l)] = true end
        check(seen['1,2,3'] and seen['11,12,13'], 'horizontal lines')
        check(seen['1,6,11'] and seen['5,10,15'], 'vertical lines (top to bottom)')
        check(seen['1,7,13'] and seen['3,9,15'], 'diagonal lines down-right')
        check(seen['3,7,11'] and seen['5,9,13'], 'diagonal lines down-left from the top end')
        check(not seen['1,7,14'], 'no bent lines')
        local pairs_seen = {}
        for _, p in ipairs(P.pairs) do pairs_seen[slots(p)] = true end
        check(pairs_seen['1,2'] and pairs_seen['1,6'] and not pairs_seen['1,7'], 'pairs are orthogonal only')
        check(not pairs_seen['5,6'], 'no pair across the row end')
    end)

    test('formation patterns other sizes', function()
        local P = Patterns.get(6, 4)
        eq(#P.pairs, 5 * 4 + 6 * 3, '6x4 pairs')
        eq(#P.lines, 4 * 4 + 6 * 2 + 4 * 2 * 2, '6x4 lines')
        eq(#P.rows, 4, '6x4 rows')
        eq(#P.blocks, 15, '6x4 blocks')
        eq(#P.compass, 8, '6x4 compass')
        local Q = Patterns.get(4, 2)
        eq(#Q.compass, 0, '4x2: no compass (needs a middle row)')
        eq(#Q.lines, 2 * 2, '4x2: only horizontal lines')
        eq(#Q.rows, 2, '4x2 rows')
        local R = Patterns.get(2, 5)
        eq(#R.rows, 0, 'rows narrower than 3 do not count')
        eq(#R.lines, 2 * 3, '2x5 vertical lines')
        local S = Patterns.get(1, 1)
        eq(#S.pairs + #S.lines + #S.blocks + #S.compass, 0, '1x1 has no patterns')
        eq(#S.full, 1, '1x1 full board')
    end)

    -- Detection --------------------------------------------------------------------------------------------------

    test('formation twin link, triad, double and full link', function()
        local res = run({
            '.  .  .  .  .',
            'S7 H7 .  .  .',
            '.  .  .  .  .',
        })
        eq(count(res, 'twin_link'), 1, 'horizontal Twin Link')
        eq(chain(res), 'twin_link', 'chain = Twin Link')
        eq(slots(res.scoring), '6,7', 'scoring = the pair')

        res = run({ '.  S7 .  .  .', '.  H7 .  .  .', '.  .  .  .  .' })
        eq(count(res, 'twin_link'), 1, 'vertical Twin Link')
        res = run({ 'S7 .  .  .  .', '.  H7 .  .  .', '.  .  .  .  .' })
        eq(count(res, 'twin_link'), 0, 'diagonal cards are not a Twin Link')
        eq(chain(res), 'spark', 'no formation = Spark')

        res = run({ '.  .  .  .  .', 'S7 H7 D7 .  .', '.  .  .  .  .' })
        eq(count(res, 'triad'), 1, 'horizontal Triad')
        eq(count(res, 'twin_link'), 2, 'two overlapping Twin Links')
        eq(count(res, 'double_link'), 0, 'overlapping Twin Links are no Double Link')
        eq(chain(res), 'triad', 'Twin Links inside the Triad add nothing to the chain')

        res = run({ 'S7 .  .  .  .', '.  H7 .  .  .', '.  .  D7 .  .' })
        eq(count(res, 'triad'), 1, 'diagonal Triad')
        res = run({ '.  .  S7 .  .', '.  H7 .  .  .', 'D7 .  .  .  .' })
        eq(count(res, 'triad'), 1, 'anti-diagonal Triad')
        res = run({ '.  .  S7 .  .', '.  .  H7 .  .', '.  .  D7 .  .' })
        eq(count(res, 'triad'), 1, 'vertical Triad')

        res = run({ 'S9 H9 .  .  .', '.  .  .  .  .', '.  .  .  C3 D3' })
        eq(count(res, 'double_link'), 1, 'Double Link')
        eq(chain(res), 'double_link', 'Double Link is primary (Twin Links covered)')

        res = run({ '.  .  .  .  .', 'S4 H4 D4 CK HK', '.  .  .  .  .' })
        eq(count(res, 'full_link'), 1, 'Full Link')
        eq(chain(res), 'full_link', 'Full Link alone (its parts are covered)')
        eq(#res.scoring, 5, 'Full Link scores 5 cards')
    end)

    test('formation ascent and rows', function()
        local res = run({ '.  .  .  .  .', 'S5 H6 D7 .  .', '.  .  .  .  .' })
        eq(count(res, 'ascent'), 1, 'rising Ascent')
        res = run({ '.  .  .  .  .', 'S9 H8 D7 .  .', '.  .  .  .  .' })
        eq(count(res, 'ascent'), 1, 'falling Ascent')
        res = run({ '.  .  .  .  .', 'SA H2 D3 .  .', '.  .  .  .  .' })
        eq(count(res, 'ascent'), 1, 'Ace low (A-2-3)')
        res = run({ '.  .  .  .  .', 'SQ HK DA .  .', '.  .  .  .  .' })
        eq(count(res, 'ascent'), 1, 'Ace high (Q-K-A)')
        res = run({ '.  .  .  .  .', 'SK HA D2 .  .', '.  .  .  .  .' })
        eq(count(res, 'ascent'), 0, 'no wrap around (K-A-2)')
        res = run({ '.  .  .  .  .', 'S3 H4 D3 .  .', '.  .  .  .  .' })
        eq(count(res, 'ascent'), 0, 'up then down is no Ascent')
        res = run({ '.  .  .  .  .', 'S2 H3 D5 .  .', '.  .  .  .  .' })
        eq(count(res, 'ascent'), 0, 'gap is no Ascent')

        res = run({ '.  .  .  .  .', 'S5 H6 D7 C8 S9', '.  .  .  .  .' })
        eq(count(res, 'row_straight'), 1, 'Row Straight')
        eq(chain(res), 'row_straight', 'Ascents inside the row add nothing')
        res = run({ '.  .  .  .  .', 'S9 H8 D7 C6 S5', '.  .  .  .  .' })
        eq(count(res, 'row_straight'), 1, 'falling Row Straight')
        res = run({ '.  .  .  .  .', 'SA H2 D3 C4 S5', '.  .  .  .  .' })
        eq(count(res, 'row_straight'), 1, 'Row Straight with a low Ace')
        res = run({ '.  .  .  .  .', 'S5 H6 D8 C7 S9', '.  .  .  .  .' })
        eq(count(res, 'row_straight'), 0, 'order matters (left to right)')

        res = run({ '.  .  .  .  .', 'H2 H5 H9 HJ HK', '.  .  .  .  .' })
        eq(count(res, 'row_flush'), 1, 'Row Flush')
        eq(count(res, 'kin_trio'), 3, 'Kin Trios inside it')
        eq(chain(res), 'row_flush', 'Row Flush alone')

        res = run({ '.  .  .  .  .', 'S9 ST SJ SQ SK', '.  .  .  .  .' })
        eq(count(res, 'royal_row'), 1, 'Royal Row')
        eq(count(res, 'row_flush') + count(res, 'row_straight'), 2, 'also a Row Flush and a Row Straight')
        eq(chain(res), 'royal_row', 'Royal Row primary')

        res = run({ '.  .  .  .  .', 'S7 H7 C7 D7 S7', '.  .  .  .  .' })
        eq(count(res, 'five_line'), 1, 'Five Line')
        eq(chain(res), 'five_line', 'Five Line primary')

        res = run({ '.  .  .  .  .', 'S5 H6 .  C8 S9', '.  .  .  .  .' })
        eq(count(res, 'row_straight') + count(res, 'row_flush'), 0, 'rows need every slot')
    end)

    test('formation squares, compass, Wild and Stone', function()
        local res = run({ 'SQ HQ .  .  .', 'CQ DQ .  .  .', '.  .  .  .  .' })
        eq(count(res, 'quad_square'), 1, 'Quad Square')
        eq(chain(res), 'quad_square', 'Quad Square primary')

        res = run({ '.  .  .  .  .', '.  .  C3 C7 .', '.  .  CT CK .' })
        eq(count(res, 'bastion'), 1, 'Bastion')

        res = run({ '.  .  D5 .  .', '.  D2 D8 DJ .', '.  .  DK .  .' })
        eq(count(res, 'compass'), 1, 'Compass')
        eq(chain(res), 'compass', 'Compass primary')
        res = run({ '.  D2 D5 D8 .', '.  .  DJ .  .', '.  .  .  .  .' })
        eq(count(res, 'compass'), 0, 'a T shape is no Compass')

        res = run({ '.  .  .  .  .', 'S7 W4 D2 .  .', '.  .  .  .  .' })
        eq(count(res, 'kin_trio'), 0, 'Spades, Wild, Diamonds: no common suit')
        res = run({ '.  .  .  .  .', 'S7 W4 S2 .  .', '.  .  .  .  .' })
        eq(count(res, 'kin_trio'), 1, 'a Wild card matches the suit')
        res = run({ '.  .  .  .  .', 'S7 X  S7 .  .', '.  .  .  .  .' })
        eq(count(res, 'kin_trio') + count(res, 'triad'), 0, 'a Stone card has no rank or suit')
    end)

    test('formation hell pact, halo line, heavens gate', function()
        local res = run({ 'S2d .  .  .  .', '.  H9d .  .  .', '.  .  C5d .  .' })
        eq(count(res, 'hell_pact'), 1, 'Hell Pact (3 Demon cards)')
        eq(chain(res), 'hell_pact', 'Hell Pact primary')
        res = run({ '.  .  .  .  .', 'HAb DKb H3b .  .', '.  .  .  .  .' })
        eq(count(res, 'halo_line'), 1, 'Halo Line (3 Blessed cards)')
        res = run({ '.  .  .  .  .', 'HAb DKd H3b .  .', '.  .  .  .  .' })
        eq(count(res, 'halo_line') + count(res, 'hell_pact'), 0, 'mixed flags: neither')

        res = run({
            'H2r H5r H9r HJr HKr',
            'S5r H6r D7r C8r S9r',
            'C7  D7  H7  S7  C7',
        })
        eq(count(res, 'heavens_gate'), 1, "Heaven's Gate (flush, straight, five line)")
        eq(chain(res), 'heavens_gate', "Heaven's Gate covers the board: nothing else counts")
        eq(#res.scoring, 15, 'all 15 cards score')
        eq(count(res, 'row_flush'), 0, 'Residue rows are not activated on their own')
        eq(count(res, 'five_line'), 1, 'the new row is')

        res = run({
            'H2r H5r H9r HJr HKr',
            'S5r H6r D7r C8r S9r',
            'C7  D7  H7  S7  C8',
        })
        eq(count(res, 'heavens_gate'), 0, 'one row that is no row formation breaks the gate')
        res = run({
            'H2r H5r H9r HJr HKr',
            'S5r H6r D7r C8r S9r',
            'C7r D7r H7r S7r C7r',
        })
        eq(count(res, 'heavens_gate'), 0, 'no new card: no Heaven\'s Gate')
    end)

    -- Activation, chain, Spark ------------------------------------------------------------------------------

    test('formation activation needs a new card', function()
        local res = run({ '.  .  .  .  .', 'S7r H7r D7r .  .', '.  .  .  .  C2' })
        eq(count(res, 'triad'), 0, 'Residue-only Triad does not count')
        eq(chain(res), 'spark', 'Spark instead')
        eq(slots(res.scoring), '15', 'only the new card scores')

        res = run({ '.  .  .  .  .', 'S7r H7r D7  .  .', '.  .  .  .  .' })
        eq(count(res, 'triad'), 1, 'one new card activates the Triad')
        eq(slots(res.scoring), '6,7,8', 'Residue in the formation scores too')
        eq(count(res, 'twin_link'), 1, 'the Residue-only Twin Link is not listed')
    end)

    test('formation chain order, cap and instance choice', function()
        -- Triad (6,7,8) + Ascent (8,9,10): the Ascent adds two cards
        local res = run({ '.  .  .  .  .', 'C7 D7 H7 S8 H9', '.  .  .  .  .' })
        eq(chain(res), 'triad+ascent', 'Triad + Ascent')
        eq(slots(res.scoring), '6,7,8,9,10', 'scoring = union of the chain')
        eq(res.primary, K.triad, 'primary key')

        -- diagonal Triad (1,7,13) + Kin Trio (4,9,14) + Twin Link (1,2); a Twin Link apart
        -- from the Triad would make a Full Link instead
        local rows = {
            'H7 C7 .  H3 .',
            '.  S7 .  H2 .',
            '.  .  D7 H5 .',
        }
        res = run(rows)
        eq(chain(res), 'triad+kin_trio+twin_link', 'three formations (cap 3)')
        res = run(rows, 2)
        eq(chain(res), 'triad+kin_trio', 'cap 2')
        res = run(rows, 1)
        eq(chain(res), 'triad', 'cap 1')
        eq(slots(res.scoring), '1,7,13', 'cap 1 scores only the Primary')

        -- instance choice between two diagonal Triads: more new cards, then higher ranks
        res = run({ 'S4r .  SK .  .', '.  H4r .  HK .', '.  .  D4 .  DK' })
        eq(slots(res.chain[1].slots), '3,9,15', 'Triad with more new cards (Kings, all new)')
        res = run({ 'SK .  S4 .  .', '.  HK .  H4 .', '.  .  DK .  D4' })
        eq(slots(res.chain[1].slots), '1,7,13', 'tie on new cards: higher ranks')
        eq(chain(res), 'triad', 'a second Triad does not count (one per formation)')

        -- two Triads side by side are a Full Link (a Twin Link of one is apart from the other)
        res = run({ 'S4 H4 D4 .  .', '.  .  .  .  .', 'SK HK DK .  .' })
        eq(chain(res), 'full_link+triad', 'Full Link, then the other Triad adds a card')
    end)

    test('formation spark', function()
        local res = run({ '.  .  .  .  .', 'S2 H9 D5 CJ S3', '.  .  .  .  .' })
        eq(chain(res), 'spark', 'Spark')
        eq(slots(res.scoring), '9', 'highest card (J)')
        res = run({ '.  .  .  .  .', 'SAr H9 D5 CJ S3', '.  .  .  .  .' })
        eq(slots(res.scoring), '9', 'Residue is ignored (the new J beats the Residue A)')
        res = run({ '.  .  .  .  .', 'SJ H9 D5 CJ S3', '.  .  .  .  .' })
        eq(slots(res.scoring), '6', 'tie: first slot')
        res = run({ '.  .  .  .  .', 'X  .  .  .  .', '.  .  .  .  .' })
        eq(slots(res.scoring), '6', 'a Stone card alone is the Spark')
        res = run({ '.  .  .  .  .', 'S5r .  .  .  .', '.  .  .  .  .' })
        eq(slots(res.scoring), '6', 'no new card: any card (never for a played hand)')
        res = run({ '.  .  .  .  .', '.  .  .  .  .', '.  .  .  .  .' })
        eq(res.primary, nil, 'empty board: no hand')
        check(res.found[K.spark] == nil, 'no Spark without cards')
        res = run({ '.  .  .  .  .', 'S7 H7 .  .  .', '.  .  .  .  .' })
        eq(count(res, 'spark'), 1, 'Spark is always listed (like High Card)')
    end)

    test('formation larger and smaller boards', function()
        local res = run({
            '.  .  .  .  .  .',
            '.  .  .  .  .  .',
            'S9 ST SJ SQ SK SA',
            '.  .  .  .  .  .',
        })
        eq(count(res, 'royal_row'), 1, '6x4: Royal Row of 6')
        res = run({ 'S7 H7 D7 C7', '.  .  .  .' })
        eq(count(res, 'five_line'), 1, '4x2: a full row of 4 is a Five Line')
        res = run({ 'S7 H7', 'D7 .', '.  .', '.  .', '.  .' })
        eq(count(res, 'five_line'), 0, '2 columns: no row formations')
        eq(count(res, 'twin_link'), 2, '2 columns: Twin Links')
    end)

    test('formation evaluator speed', function()
        local st = grid({ 'H2 H5 H9 HJ HK', 'S5 H6 D7 C8 S9', 'C7 D7 H7 S7 C7' })
        local t0 = os.clock()
        for _ = 1, 2000 do Formation.run(st, 3) end
        local ms = (os.clock() - t0) * 1000 / 2000
        check(ms < 0.5, ('full 5x3 board evaluates in %.3f ms (< 0.5)'):format(ms))
        local big = blank(8, 5)
        for s = 1, big.n do put(big, s, 'H7') end
        t0 = os.clock()
        for _ = 1, 50 do Formation.run(big, 3) end
        ms = (os.clock() - t0) * 1000 / 50
        check(ms < 20, ('worst case 8x5 board of one card evaluates in %.2f ms (< 20)'):format(ms))
        check(#Formation.find(big)[K.double_link] <= Formation.MAX_COMBOS, 'composite instances capped')
    end)

    -- Cards on the board --------------------------------------------------------------------------------------

    local function fresh()
        local area = M.start_board_run()
        G.jokers.cards = {}
        M.messages = {}
        M.preview = nil
        return area
    end

    local function to_hand(keys)
        local out = {}
        for i, key in ipairs(keys) do
            out[i] = F.card(key)
            G.hand:emplace(out[i])
        end
        G.hand:align_cards()
        return out
    end

    -- Puts cards on the board as Residue at the given slots.
    local function residue(list)
        local out = {}
        for i, item in ipairs(list) do
            local card = F.card(item[1])
            G.play:emplace(card)
            card.ability.ne_slot = item[2]
            card.ability.ne_residue = true
            out[i] = card
        end
        Board.bump()
        return out
    end

    local function select(cards)
        for _, c in ipairs(cards) do G.hand:add_to_highlighted(c) end
    end

    local function play()
        local ref = G.FUNCS.evaluate_play
        G.FUNCS.evaluate_play = function() F.evaluate_play(M) end
        G.FUNCS.play_cards_from_highlighted()
        SMODS.calculate_context({ press_play = true }) -- Blind:press_play, right after the draws are queued
        M.flush_events()
        G.FUNCS.evaluate_play = ref
    end

    local function in_area(area, card)
        for _, c in ipairs(area.cards) do if c == card then return true end end
        return false
    end

    test('formation read: slots, staging, quick play prediction', function()
        fresh()
        local res = residue({ { 'S7', 6 } })
        local hand = to_hand({ 'H2', 'D7', 'C7', 'S9' })
        select({ hand[2], hand[3] })
        Board.stage_card(hand[3], 8)
        local list = { res[1], hand[2], hand[3] }
        local st = Formation.read(list)
        eq(st.card[6], res[1], 'Residue on its slot')
        eq(st.new[6], false, 'Residue is not new')
        eq(st.card[8], hand[3], 'staged card on its reserved slot')
        eq(st.card[7], hand[2], 'unstaged card: first free slot in quick play order')
        eq(st.new[7], true, 'selected cards are new')
        eq(st.rank[7], 7, 'rank id')
        eq(st.suit[7], 8, 'suit bit (Diamonds = 4th suit)')
        local view = Formation.evaluate_cards(list)
        eq(view.primary, K.triad, 'Residue + selection form a Triad')
        eq(view.slot_of[hand[2]], 7, 'slot_of')
        eq(#view.poker_hands[K.triad][1], 3, 'poker_hands lists cards')
        eq(view.scoring[1], res[1], 'scoring cards in slot order')
    end)

    test('formation read: prediction follows the hand order', function()
        fresh()
        residue({ { 'SK', 6 } })
        local hand = to_hand({ 'H5', 'D6', 'C7' })
        select(hand)
        local st = Formation.read(hand)
        eq(st.card[7], hand[1], 'first card of the hand after the Residue')
        eq(st.card[9], hand[3], 'then left to right')
        -- move the 7 to the front of the hand: quick play order changes
        table.remove(G.hand.cards, 3)
        table.insert(G.hand.cards, 1, hand[3])
        st = Formation.read(hand)
        eq(st.card[7], hand[3], 'order of G.hand.cards')
    end)

    test('formation cache', function()
        fresh()
        local hand = to_hand({ 'H5', 'D5', 'C9' })
        local s0 = Formation.stats.evaluations
        local h0 = Formation.stats.cache_hits
        Formation.evaluate_cards(hand)
        Formation.evaluate_cards(hand)
        eq(Formation.stats.evaluations - s0, 1, 'second evaluation of the same board is cached')
        eq(Formation.stats.cache_hits - h0, 1, 'cache hit counted')
        hand[3]:set_base(G.P_CARDS.C_5)
        local view = Formation.evaluate_cards(hand)
        eq(Formation.stats.evaluations - s0, 2, 'a changed card re-evaluates')
        eq(view.primary, K.triad, 'new result')
        NE.Rules.push_temp('ne_formation_cap', 1, 'hand')
        Formation.evaluate_cards(hand)
        eq(Formation.stats.evaluations - s0, 3, 'a changed cap re-evaluates')
        NE.Rules.clear_scope('hand')
    end)

    -- Steamodded integration ------------------------------------------------------------------------------------

    test('formation poker hands registered', function()
        local ours = {}
        for _, key in ipairs(G.handlist) do
            if Formation.is_formation(key) then ours[#ours + 1] = key end
        end
        eq(#ours, 17, '17 formation hands')
        eq(table.concat(ours, ' '), table.concat(Formation.ORDER, ' '), 'handlist order = priority order')
        local t = SMODS.PokerHands.ne_triad
        eq(t.chips, 35, 'Triad chips')
        eq(t.mult, 3, 'Triad mult')
        eq(t.l_chips, 25, 'Triad level chips')
        eq(t.l_mult, 2, 'Triad level mult')
        eq(SMODS.PokerHands.ne_heavens_gate.chips * SMODS.PokerHands.ne_heavens_gate.mult, 5000, "Heaven's Gate 250 x 20")
        for _, def in ipairs(Formation.DEFS) do
            local h = SMODS.PokerHands[def.key]
            check(h and h.visible == true and type(h.example) == 'table' and h.example[1], def.key .. ' visible with an example')
        end
        for _, key in ipairs(Formation.VANILLA_HANDS) do
            local h = SMODS.PokerHands[key]
            check(h.visible == false and h.no_collection == true, key .. ' hidden')
            check(next(h.evaluate({}, { F.card('S_A') })) == nil, key .. ' never matches')
        end
    end)

    test('formation get_poker_hand_info and chain name', function()
        fresh()
        local hand = to_hand({ 'C7', 'D7', 'H7', 'S8', 'H9' })
        local text, disp, poker_hands, scoring, raw = G.FUNCS.get_poker_hand_info(hand)
        eq(text, K.triad, 'scoring name = Primary')
        eq(disp, 'Triad + Ascent', 'display name = chain')
        eq(raw, 'Triad + Ascent', 'unlocalized display text too')
        eq(#scoring, 5, 'scoring hand = every chain card')
        check(next(poker_hands[K.ascent]) ~= nil and next(poker_hands[K.twin_link]) ~= nil, 'poker_hands lists every formation found')
        eq(next(poker_hands['Pair']), nil, 'vanilla Pair never matches')

        -- a joker that renames the hand wins
        G.jokers.cards[1] = { ability = {}, config = { center = { calculate = function(self, card, ctx)
            if ctx.evaluate_poker_hand then return { replace_display_name = 'Custom' } end
        end } } }
        text, disp = G.FUNCS.get_poker_hand_info(hand)
        eq(disp, 'Custom', 'joker display name kept')
        G.jokers.cards = {}

        local single = to_hand({ 'SK' })
        text, disp = G.FUNCS.get_poker_hand_info({ single[1] })
        eq(text, K.spark, 'one card = Spark')
        eq(disp, 'Spark', 'no chain: formation name')
        text = G.FUNCS.get_poker_hand_info({})
        eq(text, 'NULL', 'no cards = NULL (like vanilla)')
    end)

    test('formation preview follows placement', function()
        fresh()
        residue({ { 'S7', 6 }, { 'H7', 7 } })
        local hand = to_hand({ 'D2', 'D7', 'C9' })
        select({ hand[1] })
        check(M.preview ~= nil, 'preview parsed')
        eq(M.preview.text, K.spark, 'D2 predicted at slot 8: no formation (Residue pair not active)')
        G.hand:remove_from_highlighted(hand[1])
        select({ hand[2] })
        eq(M.preview.text, K.triad, 'D7 predicted at slot 8: Triad with the Residue')
        M.preview = nil
        Board.stage_card(hand[2], 15)
        check(M.preview ~= nil, 'staging refreshes the preview')
        eq(M.preview.text, K.spark, 'D7 staged away from the Residue: Spark')
        -- dragging a card off the board (unstage) refreshes it too
        M.preview = nil
        G.CONTROLLER.cursor_down.T = { x = 0, y = 0 }
        G.CONTROLLER.cursor_up.T = { x = 5, y = 5 }
        G.CONTROLLER.cursor_hover.target = nil
        hand[2]:stop_drag()
        check(M.preview ~= nil, 'drag off the board refreshes the preview')
        eq(M.preview.text, K.triad, 'back to the predicted slot: Triad')
    end)

    test('formation views are not reused once the list changed', function()
        fresh()
        local hand = to_hand({ 'C7', 'D7', 'H7' })
        for _, c in ipairs(hand) do G.play:emplace(c) end
        local text = G.FUNCS.get_poker_hand_info(G.play.cards)
        eq(text, K.triad, 'Triad on the board')
        eq(Formation.depth, 0, 'evaluation depth back to 0')
        G.play:remove_card(hand[3])
        local view = Formation.view_for(G.play.cards)
        eq(view.primary, K.twin_link, 'same list, fewer cards: evaluated again (Twin Link)')
    end)

    test('formation preview: moving a card out of a Row Straight', function()
        fresh()
        local hand = to_hand({ 'S5', 'H6', 'D7', 'C8', 'S9' })
        select(hand)
        eq(M.preview.text, K.row_straight, 'quick play: Row Straight in the Middle row')
        Board.stage_card(hand[3], 13)
        eq(M.preview.text, K.spark, 'the 7 on the Front row: Spark')
        eq(M.preview.scoring[1], hand[5], 'Spark = the 9')
        hand[3]:highlight(false)
        G.hand:remove_from_highlighted(hand[3])
        G.hand:add_to_highlighted(hand[3])
        eq(M.preview.text, K.row_straight, 'back in the selection: Row Straight again')
    end)

    test('formation play: chain bonus, scoring, Residue', function()
        fresh()
        local hand = to_hand({ 'C7', 'D7', 'H7', 'S8', 'H9', 'S2' })
        select({ hand[1], hand[2], hand[3], hand[4], hand[5] })
        play()
        local info = M.played_info
        eq(info.text, K.triad, 'played Triad')
        eq(info.disp, 'Triad + Ascent', 'chain name')
        eq(#info.final_scoring, 5, 'all five cards score')
        eq(info.after_chain.chips, 35 + 15, 'chips: Triad 35 + 50% of Ascent 30')
        eq(info.after_chain.mult, 3 + 1.5, 'mult: Triad 3 + 50% of Ascent 3')
        eq(G.GAME.hands[K.triad].played, 1, 'Primary counts as played')
        eq(G.GAME.hands[K.ascent].played, 0, 'Secondaries do not')
        local msg
        for _, m in ipairs(M.messages) do
            if m.extra and m.extra.message == 'Ascent' then msg = m end
        end
        check(msg ~= nil and msg.card == hand[3], 'Chain message on the Secondary\'s first card')
        eq(#G.play.cards, 0, 'every scored card left the board')
        check(in_area(G.discard, hand[1]), 'scored cards discarded')
        check(NE.Phases.trace.last:find('chain%(1%)') ~= nil, 'Chain phase ran with 1 Secondary')
    end)

    test('formation play: Spark leaves Residue, Residue joins a formation', function()
        fresh()
        local hand = to_hand({ 'S2', 'H9', 'D5', 'CJ', 'S3' })
        select(hand)
        play()
        eq(M.played_info.text, K.spark, 'Spark')
        eq(#M.played_info.final_scoring, 1, 'only the highest card scores')
        check(in_area(G.discard, hand[4]), 'the J left the board')
        eq(#Board.residues(), 4, 'the other 4 stay as Residue')

        -- the Residue 9 at slot 7 plus two new 9s make a Triad
        G.STATE = G.STATES.SELECTING_HAND
        local more = to_hand({ 'D9', 'C9' })
        select(more)
        Board.stage_card(more[1], 2)
        Board.stage_card(more[2], 12)
        play()
        eq(M.played_info.text, K.triad, 'vertical Triad through the Residue')
        check(in_area(G.discard, hand[2]), 'the Residue 9 scored and left')
        eq(#Board.residues(), 3, 'the rest stays')
    end)

    test('formation rules: chain percent and cap', function()
        fresh()
        NE.Rules.push_permanent('ne_chain_pct', 100)
        local hand = to_hand({ 'C7', 'D7', 'H7', 'S8', 'H9' })
        select(hand)
        play()
        eq(M.played_info.after_chain.chips, 35 + 30, 'chain 100%: full Ascent chips')
        NE.Rules.push_permanent('ne_chain_pct', nil)
        fresh()
        NE.Rules.push_permanent('ne_formation_cap', 1)
        hand = to_hand({ 'C7', 'D7', 'H7', 'S8', 'H9' })
        select(hand)
        play()
        eq(M.played_info.disp, 'Triad', 'cap 1: no chain')
        eq(#M.played_info.final_scoring, 3, 'cap 1: only the Triad scores')
        eq(#Board.residues(), 2, 'the Ascent cards stay')
        NE.Rules.push_permanent('ne_formation_cap', nil)
    end)

    test('formation currency: Hell Pact and Halo Line', function()
        fresh()
        local before = NE.Currency.get('corruption')
        local cards = {}
        for i, key in ipairs({ 'S2', 'H9', 'C5' }) do
            cards[i] = F.card(key, { enhancement = Formation.DEMON_KEY })
            G.hand:emplace(cards[i])
        end
        G.hand:align_cards()
        select(cards)
        play()
        eq(M.played_info.text, K.hell_pact, 'Hell Pact played')
        eq(NE.Currency.get('corruption') - before, 3, '+3 Corruption')
        fresh()
        before = NE.Currency.get('divinity')
        cards = {}
        for i, key in ipairs({ 'HA', 'DK', 'H3' }) do
            cards[i] = F.card(key, { enhancement = Formation.BLESSED_KEY })
            G.hand:emplace(cards[i])
        end
        G.hand:align_cards()
        select(cards)
        play()
        eq(NE.Currency.get('divinity') - before, 2, 'Halo Line: +2 Divinity')
    end)

    test('formation secondaries without a capture', function()
        fresh()
        local hand = to_hand({ 'C7', 'D7', 'H7', 'S8', 'H9' })
        for _, c in ipairs(hand) do G.play:emplace(c) end
        Formation.played = nil
        local list = NE.Phases.secondaries({ full_hand = G.play.cards, scoring_name = K.triad })
        eq(#list, 1, 'evaluates the hand when nothing was captured')
        eq(list[1].key, K.ascent, 'the Secondary')
        list = NE.Phases.secondaries({ full_hand = G.play.cards, scoring_name = 'Custom' })
        eq(#list, 0, 'no chain when a joker changed the hand type')
    end)

    -- Runs, saves, L12 -----------------------------------------------------------------------------------------

    test('formation run data', function()
        fresh()
        local g = G.GAME
        check(g.hands[K.triad] ~= nil and g.hands[K.triad].level == 1, 'formation hands in a new run')
        eq(g.hands.Pair.visible, false, 'vanilla hands hidden')
        eq(g.current_round.most_played_poker_hand, K.spark, 'most played defaults to Spark')

        -- a save from before Phase 6
        local old = { hands = { Pair = { visible = true, played = 3, level = 2 } },
            current_round = { most_played_poker_hand = 'Pair' } }
        Formation.ensure_hands(old)
        check(old.hands[K.twin_link] ~= nil and old.hands[K.twin_link].chips == 10, 'formations added to an old save')
        eq(old.hands.Pair.visible, false, 'vanilla hand hidden in an old save')
        eq(old.hands.Pair.level, 2, 'vanilla data otherwise kept')
        eq(old.current_round.most_played_poker_hand, K.spark, 'most played reset to a formation')
        check(old.hands[K.triad].example ~= nil, 'example copied')
        Formation.ensure_hands(nil)
        check(true, 'nil game is ignored')

        -- loading such a save: completed before the game uses it
        local game = G:init_game_object()
        for _, key in ipairs(Formation.ORDER) do game.hands[key] = nil end
        game.hands.Pair.visible = true
        game.current_round.most_played_poker_hand = 'Pair'
        M.start_board_run({ GAME = game })
        check(G.GAME == game and G.GAME.hands[K.ascent] ~= nil, 'old save loaded with formation hands')
        eq(G.GAME.hands.Pair.visible, false, 'old save: vanilla hidden')
        local text = G.FUNCS.get_poker_hand_info(to_hand({ 'S5', 'H6', 'D7' }))
        eq(text, K.ascent, 'old save: formations play')
    end)

    test('formation chain bonus with big hand values', function()
        fresh()
        G.GAME.hands[K.ascent].chips = NE.Big.new('1e200')
        local chips, mult = Formation.chain_bonus(K.ascent)
        check(NE.Big.is(chips) and NE.Big.eq(chips, NE.Big.new('5e199')), 'Big chips halved')
        eq(mult, 1.5, 'number mult halved')
        eq((Formation.chain_bonus('ne_missing')), 0, 'unknown hand: no bonus')
    end)

    test('formation patch L12', function()
        local n, all_once = 0, true
        for _, r in ipairs(M.patch_results) do
            if r.file:match('35_formations%.toml$') then
                n = n + 1
                if r.matches ~= 1 then all_once = false end
            end
        end
        eq(n, 2, 'two L12 patches')
        check(all_once, 'each matches exactly once')
        fresh()
        G.GAME.hands.Pair.played = 10
        G.GAME.hands[K.triad].played = 2
        test_most_played()
        eq(G.GAME.current_round.most_played_poker_hand, K.triad, 'vanilla hands never count')
        for _, h in pairs(G.GAME.hands) do h.played = 0 end
        test_most_played()
        check(Formation.is_formation(G.GAME.current_round.most_played_poker_hand), 'ties still give a formation')
    end)

    -- Planets, diagram ---------------------------------------------------------------------------------------------

    test('formation planets', function()
        local list = SMODS.Planet.list
        eq(#list, 17, '17 planets')
        for i, def in ipairs(Formation.DEFS) do
            local p = list[i]
            eq(p.key, 'c_ne_' .. def.planet, 'planet key ' .. def.planet)
            eq(p.config.hand_type, def.key, def.planet .. ' levels ' .. def.key)
            eq(p.atlas, 'planets', def.planet .. ' atlas')
            eq(p.pos.x, i - 1, def.planet .. ' sprite')
        end
        fresh()
        local v = list[12]:loc_vars({}, nil).vars
        eq(v[1], 1, 'level')
        eq(v[2], 'Triad', 'formation name')
        eq(v[3], 2, '+mult per level')
        eq(v[4], 25, '+chips per level')
        eq(v.colours[1], G.C.UI.TEXT_DARK, 'level 1 colour')
        level_up_hand(nil, K.triad, true, 2)
        v = list[12]:loc_vars({}, nil).vars
        eq(v[1], 3, 'level after levelling')
        eq(v.colours[1], G.C.HAND_LEVELS[3], 'level colour')
        eq(G.GAME.hands[K.triad].chips, 35 + 2 * 25, 'level up raises chips')
    end)

    test('formation run info diagram', function()
        fresh()
        local row = create_UIBox_current_hand_row(K.triad)
        local d = row.nodes[1]
        eq(d.n, G.UIT.C, 'diagram first in the row')
        eq(#d.nodes, 3, '3 rows')
        local lit, cells = 0, 0
        for _, r in ipairs(d.nodes) do
            for _, c in ipairs(r.nodes) do
                cells = cells + 1
                if c.config.colour == G.C.SECONDARY_SET.Planet then lit = lit + 1 end
            end
        end
        eq(cells, 15, '15 cells')
        eq(lit, 3, 'Triad lights 3')
        eq(#row.nodes, 3, 'original columns kept')
        eq(create_UIBox_current_hand_row('Pair'), nil, 'hidden vanilla hand: no row')
        local simple = create_UIBox_current_hand_row(K.triad, true)
        eq(#simple.nodes, 2, 'simple rows unchanged')
    end)

    test('formation diagrams show their formation', function()
        -- cards for the lit cells of each diagram (in diagram order)
        local CARDS = {
            heavens_gate = { 'H2', 'H3', 'H4', 'H5', 'H7', 'S2', 'S3', 'S4', 'S5', 'S7', 'D2', 'D3', 'D4', 'D5', 'D7' },
            five_line = { 'S7', 'H7', 'C7', 'D7', 'S7' },
            royal_row = { 'S9', 'ST', 'SJ', 'SQ', 'SK' },
            quad_square = { 'SQ', 'HQ', 'CQ', 'DQ' },
            hell_pact = { 'S2d', 'H9d', 'C5d' },
            halo_line = { 'S2b', 'H9b', 'C5b' },
            compass = { 'D2', 'D5', 'D8', 'DJ', 'DK' },
            full_link = { 'S4', 'H4', 'D4', 'CK', 'HK' },
            row_flush = { 'H2', 'H5', 'H9', 'HJ', 'HK' },
            row_straight = { 'S5', 'H6', 'D7', 'C8', 'S9' },
            bastion = { 'C3', 'C7', 'CT', 'CK' },
            triad = { 'SK', 'DK', 'CK' },
            ascent = { 'H5', 'S6', 'D7' },
            double_link = { 'S9', 'H9', 'C3', 'D3' },
            kin_trio = { 'H4', 'HT', 'HQ' },
            twin_link = { 'SJ', 'DJ' },
            spark = { 'SA' },
        }
        for _, def in ipairs(Formation.DEFS) do
            local st = blank(5, 3)
            local d = Formation.DIAGRAMS[def.name]
            local cells = {}
            if d == 'all' then
                for s = 1, 15 do cells[s] = { ((s - 1) % 5) + 1, math.floor((s - 1) / 5) + 1 } end
            else
                cells = d
            end
            for i, cell in ipairs(cells) do put(st, (cell[2] - 1) * 5 + cell[1], CARDS[def.name][i]) end
            local res = Formation.run(st, 3)
            eq(res.primary, def.key, 'diagram of ' .. def.name .. ' forms it')
        end
    end)

    -- Cheats, overlay, localization -----------------------------------------------------------------------------

    test('formation cheats', function()
        fresh()
        G.GAME.blind = { chips = 300 }
        local hand = to_hand({ 'S2', 'S3', 'S4', 'S5', 'S6', 'S8' })
        G.FUNCS.ne_cheat_hand_preset()
        eq(hand[1].base.id, 7, 'preset 1: first card becomes a 7')
        eq(hand[4].base.id, 8, 'preset 1: fourth card an 8')
        eq(hand[6].base.id, 8, 'sixth card untouched')
        local text = G.FUNCS.get_poker_hand_info({ hand[1], hand[2], hand[3], hand[4], hand[5] })
        eq(text, K.triad, 'preset forms its formation')
        G.FUNCS.ne_cheat_hand_preset()
        eq(hand[5].base.id, 13, 'preset 2 (Full Link): fifth card a K')
        for _, p in ipairs(NE.Debug.HAND_PRESETS) do
            for _, key in ipairs(p.cards) do check(G.P_CARDS[key] ~= nil, p.name .. ' card ' .. key) end
        end

        M.levelled = {}
        G.FUNCS.ne_cheat_level_formations()
        eq(#M.levelled, 17, 'every formation levelled')
        eq(G.GAME.hands[K.spark].level, 2, 'Spark level 2')

        G.consumeables = CardArea(0, 0, 1, 1, { card_limit = 2, type = 'joker' })
        M.added_cards = {}
        G.FUNCS.ne_cheat_give_planets()
        eq(#M.added_cards, 2, 'two planets')
        eq(M.added_cards[1].set, 'Planet', 'from the Planet pool')
        G.consumeables = nil
    end)

    test('formation overlay line', function()
        fresh()
        local hand = to_hand({ 'C7', 'D7', 'H7', 'S8', 'H9' })
        G.FUNCS.get_poker_hand_info(hand)
        eq(Formation.debug_chain(), 'triad+ascent', 'chain of the latest evaluation')
        NE.config.debug.enabled = true
        NE.Debug.toggle_overlay()
        love.update(0.3)
        check(NE.Debug.overlay.text:find('Formation triad+ascent   cap 3   chain +50%', 1, true), 'overlay shows the chain')
        NE.Debug.toggle_overlay()
    end)

    test('formation localization', function()
        for _, lang in ipairs({ 'en-us', 'id' }) do
            local loc = M.load_loc(lang)
            for _, def in ipairs(Formation.DEFS) do
                check(type(loc.misc.poker_hands[def.key]) == 'string', lang .. ' name ' .. def.key)
                local d = loc.misc.poker_hand_descriptions[def.key]
                check(type(d) == 'table' and d[1] ~= nil, lang .. ' description ' .. def.key)
                local p = loc.descriptions.Planet['c_ne_' .. def.planet]
                check(p and p.name and #p.text == 4, lang .. ' planet ' .. def.planet)
            end
            for _, id in ipairs({ 'hand_preset', 'level_formations', 'give_planets' }) do
                check(loc.misc.dictionary['ne_cheat_' .. id] ~= nil, lang .. ' cheat ' .. id)
            end
        end
        local id = M.load_loc('id')
        eq(id.misc.poker_hands[K.heavens_gate], 'Gerbang Surga', 'Indonesian name')
    end)
end
