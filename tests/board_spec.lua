-- Phase 5 tests: the board (grid, layout, placement, Residue, discard, save/load, resize,
-- row effects, controller, Lovely patches L13a-d / L14).

return function(T)
    local test, check, eq, M = T.test, T.check, T.eq, T.M
    local Board = NE.Board
    local Grid = Board.Grid
    local function dispatch_ctx(ctx) return NE.mod.calculate(NE.mod, ctx) end

    local NOMINAL = { [11] = 10, [12] = 10, [13] = 10, [14] = 11 }
    local function new_card(id, suit, extra)
        local proto = { id = id, nominal = NOMINAL[id] or id, suit = suit or 'Spades' }
        for k, v in pairs(extra or {}) do proto[k] = v end
        return Card(0, 0, G.CARD_W, G.CARD_H, proto)
    end

    -- Puts n new cards in hand (ranks 2, 3, ...); returns them in hand order.
    local function deal(n, first)
        local out = {}
        for i = 1, n do
            local card = new_card((first or 2) + i - 1)
            G.hand:emplace(card)
            out[i] = card
        end
        G.hand:align_cards()
        return out
    end

    local function select(cards)
        for _, c in ipairs(cards) do G.hand:add_to_highlighted(c) end
    end

    local function play()
        G.FUNCS.play_cards_from_highlighted()
        M.flush_events()
    end

    local function in_area(area, card)
        for _, c in ipairs(area.cards) do if c == card then return true end end
        return false
    end

    local function copy(t)
        if type(t) ~= 'table' then return t end
        local out = {}
        for k, v in pairs(t) do out[k] = copy(v) end
        return out
    end

    local function patched(file)
        local n, ok = 0, true
        for _, r in ipairs(M.patch_results) do
            if r.file:match(file .. '$') then
                n = n + 1
                if r.matches ~= 1 then ok = false end
            end
        end
        return n, ok
    end

    -- Grid & layout ----------------------------------------------------------------------------------
    test('board: grid numbering', function()
        for cols = 1, Grid.MAX_COLS do
            for rows = 1, Grid.MAX_ROWS do
                local okc = true
                for s = 1, cols * rows do
                    local c, r = Grid.coords(cols, s)
                    if Grid.index(cols, c, r) ~= s or c < 1 or c > cols or r < 1 or r > rows then okc = false end
                end
                check(okc, ('index/coords round trip %dx%d'):format(cols, rows))
                local order = Grid.fill_order(cols, rows)
                local seen, all = {}, true
                for _, s in ipairs(order) do
                    if seen[s] then all = false end
                    seen[s] = true
                end
                check(all and #order == cols * rows, ('fill order is a permutation %dx%d'):format(cols, rows))
            end
        end
        local order = Grid.fill_order(5, 3)
        eq(table.concat(order, ','), '6,7,8,9,10,11,12,13,14,15,1,2,3,4,5', 'quick play: middle, front, back')
        eq(Grid.row_kind(3, 1), 'back', 'row 1 is Back')
        eq(Grid.row_kind(3, 2), 'middle', 'row 2 is Middle')
        eq(Grid.row_kind(3, 3), 'front', 'row 3 is Front')
        eq(Grid.row_kind(1, 1), 'middle', 'one row: Middle')
        eq(Grid.row_scale(3, 1), 0.84, 'Back row scale')
        check(math.abs(Grid.row_scale(3, 2) - 0.92) < 1e-12, 'Middle row scale')
        eq(Grid.row_scale(3, 3), 1, 'Front row scale')
        -- adjacent pairs on 5x3: 22 (GDD §1.3)
        local pairs_n = 0
        for s = 1, 15 do pairs_n = pairs_n + #Grid.neighbors(5, 3, s) end
        eq(pairs_n / 2, 22, '22 orthogonal pairs on 5x3')
        check(Grid.adjacent(5, 7, 8) and Grid.adjacent(5, 7, 12) and not Grid.adjacent(5, 5, 6), 'adjacency')
        eq(Grid.clamp_dim(0, 8, 5), 1, 'clamp low')
        eq(Grid.clamp_dim(99, 8, 5), 8, 'clamp high')
        eq(Grid.clamp_dim('x', 8, 5), 5, 'clamp default')
    end)

    test('board: layout fits between jokers and hand (1280x720 room)', function()
        M.start_board_run()
        local box = Board.layout_box({})
        check(box.top > 2.6 and box.bottom < 6.3 and box.bottom > box.top + 3, 'box between joker row and hand: ' .. box.top .. '..' .. box.bottom)
        for cols = 1, Grid.MAX_COLS do
            for rows = 1, Grid.MAX_ROWS do
                local L = Grid.layout(cols, rows, box, {})
                local ok = L.k > 0 and L.k == L.k
                for s = 1, cols * rows do
                    local r = L.slots[s]
                    if not (r.y >= box.top - 1e-9 and r.y + r.h <= box.bottom + 1e-9) then ok = false end
                    if not (r.x >= box.cx - box.max_w / 2 - 1e-9 and r.x + r.w <= box.cx + box.max_w / 2 + 1e-9) then ok = false end
                    if r.w ~= r.w or r.h ~= r.h then ok = false end
                end
                check(ok, ('%dx%d fits the board box'):format(cols, rows))
            end
        end
        local L = Grid.layout(5, 3, box, {})
        check(L.slots[1].y < L.slots[6].y and L.slots[6].y < L.slots[11].y, 'rows go down from Back to Front')
        check(L.slots[1].w < L.slots[6].w and L.slots[6].w < L.slots[11].w, 'Back row drawn smaller')
        check(L.slots[11].y < L.slots[6].y + L.slots[6].h, 'rows overlap (depth)')
        check(L.slots[11].w > 1.2, '5x3 front cards stay readable: ' .. L.slots[11].w)
        check(L.slots[2].x >= L.slots[1].x + L.slots[1].w, 'cards of a row do not overlap')
    end)

    -- Setup & save/load ----------------------------------------------------------------------------------
    test('board: G.play becomes a 5x3 board', function()
        local area = M.start_board_run()
        check(Board.is_board(area), 'G.play is a board')
        eq(area.config.ne_board.cols, 5, 'cols')
        eq(area.config.ne_board.rows, 3, 'rows')
        eq(area.config.card_limit, 15, 'card limit = slots')
        eq(area.config.type, 'play', 'area type stays play')
        eq(#Board.slots, 15, 'one slot node per slot')
        eq(Board.residue_cap(), 10, 'Residue limit = 15 - play limit')
        eq(Board.busy(), false, 'empty board is not busy')
        local layout = Board.get_layout()
        eq(Board.slots[7].T.x, layout.slots[7].x, 'slot node placed on its rectangle')
    end)

    test('board: quick play fills the Middle row, scored cards leave, the rest stays', function()
        M.start_board_run()
        local cards = deal(6)
        select({ cards[1], cards[2], cards[3], cards[4], cards[5] })
        M.score_cards = function(list) return { list[1], list[2] } end
        local after_evaluate
        local eval_ref = G.FUNCS.evaluate_play
        G.FUNCS.evaluate_play = function()
            after_evaluate = { busy = Board.busy(), n = #G.play.cards }
            return eval_ref()
        end
        play()
        G.FUNCS.evaluate_play = eval_ref
        eq(after_evaluate.busy, true, 'board busy while the hand is scored')
        eq(after_evaluate.n, 5, 'five cards on the board when scoring')
        eq(M.evaluated[1], cards[1], 'scoring order = slot order')
        eq(#G.play.cards, 3, 'three unscored cards stay')
        eq(#G.discard.cards, 2, 'two scored cards discarded')
        for i = 3, 5 do
            eq(cards[i].ability.ne_slot, 5 + i, 'Middle row slot for card ' .. i)
            eq(cards[i].ability.ne_residue, true, 'card ' .. i .. ' is Residue')
        end
        eq(cards[1].ability.ne_slot, nil, 'scored card forgot its slot')
        eq(cards[1].T.scale, 0.95, 'scored card back to full size')
        eq(Board.busy(), false, 'Residue alone is not busy')
        eq(G.STATE, G.STATES.SELECTING_HAND, 'back to selecting')
        eq(G.GAME.hands_played, 1, 'hand counted')
        M.score_cards = nil
    end)

    test('board: play guard (L13a) and G.play checks (L13b-d)', function()
        local n, ok = patched('30_board.toml')
        eq(n, 5, 'five board patches found their test source')
        check(ok, 'each board patch matched exactly once')

        M.start_board_run()
        local cards = deal(3)
        select({ cards[1] })
        play()
        eq(#G.play.cards, 1, 'one Residue card')
        local probe = new_card(5)
        check(probe:can_use_consumeable(), 'consumables usable with Residue only (L13b)')
        check(probe:can_sell_card(), 'selling allowed with Residue only (L13b)')
        select({ cards[2] })
        G.CONTROLLER:queue_R_cursor_press()
        eq(#G.hand.highlighted, 0, 'right click deselects with Residue only (L13c)')

        -- a hand in progress (card that is not Residue)
        G.play:emplace(new_card(9))
        eq(Board.busy(), true, 'new card on the board: busy')
        check(not probe:can_use_consumeable(), 'consumables blocked during a hand')
        check(not probe:can_sell_card(), 'selling blocked during a hand')
        local before = #M.events
        select({ cards[3] })
        G.FUNCS.play_cards_from_highlighted()
        eq(#M.events, before, 'Play refused while a hand is on the board (L13a)')
        M.events = {}
    end)

    test('board: a round with only Residue left ends once', function()
        M.start_board_run()
        local cards = deal(2)
        select({ cards[1] })
        M.score_cards = function() return {} end
        play()
        M.score_cards = nil
        eq(#G.play.cards, 1, 'one Residue card')
        M.end_round_calls = 0
        G.STATE_COMPLETE = false
        G:update_selecting_hand(0)
        eq(M.end_round_calls, 0, 'cards left in hand: round goes on')
        G.hand:remove_card(cards[2]) -- last hand card destroyed (deck already empty)
        G:update_selecting_hand(0)
        eq(M.end_round_calls, 1, 'only Residue left: round ends')
        G:update_selecting_hand(0)
        G:update_selecting_hand(0)
        eq(M.end_round_calls, 1, 'end_round called once, not every frame')
        dispatch_ctx({ setting_blind = true })
        eq(Board.round_ended, false, 'next blind resets the guard')
        -- hand and deck already empty when selecting starts: the game's own call is enough
        M.end_round_calls = 0
        G.STATE_COMPLETE = false
        G:update_selecting_hand(0)
        G:update_selecting_hand(0)
        eq(M.end_round_calls, 1, 'no second call after the game ends the round')
    end)

    test('board: busy() without a board keeps the vanilla meaning', function()
        local saved = G.play
        G.play = CardArea(0, 0, 1, 1, { type = 'play', card_limit = 5 })
        eq(Board.busy(), false, 'empty play area')
        G.play.cards[1] = new_card(3)
        eq(Board.busy(), true, 'any card in a vanilla play area')
        G.play = saved
    end)

    -- Staging ------------------------------------------------------------------------------------------------
    test('board: staged cards stay in hand and take their slot on Play', function()
        M.start_board_run()
        local cards = deal(6)
        check(Board.stage_card(cards[3], 11), 'stage card 3 on the Front-left slot')
        check(cards[3].highlighted, 'staging highlights the card')
        eq(cards[3].area, G.hand, 'staged card stays in the hand')
        eq(Board.staged_slot(cards[3]), 11, 'slot reserved')
        check(not Board.stage_card(cards[4], 11), 'reserved slot refused')

        G.hand:align_cards()
        local L = Board.get_layout().slots[11]
        check(math.abs(cards[3].T.x + cards[3].T.w / 2 - (L.x + L.w / 2)) < 1e-9, 'staged card drawn over its slot')
        eq(cards[3].T.scale, L.scale, 'staged card at the Front row size')
        eq(G.hand.cards[6], cards[3], 'staged card moved out of the fan')
        eq(G.hand.cards[1].T.x, G.hand.T.x, 'fan starts at the hand edge')
        check(math.abs(G.hand.cards[5].T.x - (G.hand.T.x + G.hand.T.w - G.hand.card_w)) < 1e-9, 'fan spread over 5 cards (no gap)')

        M.draw_log = {}
        G.hand:draw()
        local drawn = false
        for _, d in ipairs(M.draw_log) do if d.card == cards[3] then drawn = true end end
        check(not drawn, 'hand does not draw the staged card')
        eq(cards[3].states.visible, true, 'staged card visible again after the hand draw')
        M.draw_log = {}
        G.play:draw()
        drawn = false
        for _, d in ipairs(M.draw_log) do if d.card == cards[3] then drawn = true end end
        check(drawn, 'board draws the staged card')

        select({ cards[1], cards[2] })
        M.score_cards = function() return {} end
        play()
        eq(cards[3].ability.ne_slot, 11, 'staged card played into its slot')
        eq(cards[1].ability.ne_slot, 6, 'other selected cards: quick play')
        eq(cards[2].ability.ne_slot, 7, 'quick play continues left to right')
        eq(next(Board.stage), nil, 'no reservation left')
        M.score_cards = nil
    end)

    test('board: unstage by click, drag & drop, click on a slot', function()
        M.start_board_run()
        local cards = deal(6)
        check(Board.stage_card(cards[2], 1), 'staged')
        G.hand:align_cards()
        cards[2]:click()
        eq(Board.staged_slot(cards[2]), nil, 'click unstages')
        eq(cards[2].highlighted, false, 'click unhighlights')
        eq(G.hand.cards[2], cards[2], 'card back at its hand position')
        G.hand:align_cards()
        eq(cards[2].T.scale, 0.95, 'full size again in hand')
        eq(cards[2].ne_board_scale, nil, 'board size flag cleared')

        -- drag onto an empty slot
        local C = G.CONTROLLER
        C.cursor_down.T = { x = 10, y = 9 }
        C.cursor_up.T = { x = 10, y = 4 }
        C.cursor_hover.target = Board.slots[13]
        cards[4]:stop_drag()
        eq(Board.staged_slot(cards[4]), 13, 'drag & drop stages the card')
        check(cards[4].highlighted, 'dropped card highlighted')
        -- drag the staged card to another slot
        C.cursor_hover.target = Board.slots[14]
        cards[4]:stop_drag()
        eq(Board.staged_slot(cards[4]), 14, 'staged card moved to another slot')
        -- a click (no movement) does not move it
        C.cursor_up.T = { x = 10, y = 9 }
        C.cursor_hover.target = Board.slots[1]
        cards[4]:stop_drag()
        eq(Board.staged_slot(cards[4]), 14, 'click is not a drop')
        -- drag off the board
        C.cursor_up.T = { x = 10, y = 4 }
        C.cursor_hover.target = nil
        cards[4].T.x = G.hand.T.x - 5
        cards[4]:stop_drag()
        eq(Board.staged_slot(cards[4]), nil, 'dragged off the board: unstaged')
        check(cards[4].highlighted, 'still selected after dragging it back')
        eq(G.hand.cards[1], cards[4], 'dropped at the left of the hand')

        -- click an empty slot: stages the leftmost selected card without a slot
        G.hand:unhighlight_all()
        select({ cards[5], cards[6] })
        check(Board.slots[15]:click() ~= false, 'slot click')
        eq(Board.staged_slot(cards[5]), 15, 'leftmost selected card staged')
        Board.slots[5]:click()
        eq(Board.staged_slot(cards[6]), 5, 'next selected card staged')
        M.sounds = {}
        Board.slots[4]:click()
        eq(M.sounds[#M.sounds], 'cancel', 'nothing left to place: cancel sound')

        -- selection limit
        G.hand:unhighlight_all()
        select({ cards[1], cards[2], cards[3], cards[4], cards[5] })
        C.cursor_up.T = { x = 10, y = 4 }
        C.cursor_hover.target = Board.slots[8]
        cards[6]:stop_drag()
        eq(Board.staged_slot(cards[6]), nil, 'not staged past the selection limit')
        check(not cards[6].highlighted, 'not selected past the limit')
        C.cursor_hover.target = nil
    end)

    test('board: can_play needs a free slot per card, preview includes Residue', function()
        M.start_board_run()
        local cards = deal(8)
        select({ cards[1], cards[2] })
        M.score_cards = function() return {} end
        play()
        M.score_cards = nil
        eq(#G.play.cards, 2, 'two Residue cards')

        select({ cards[3] })
        eq(M.poker_eval[1], cards[1], 'preview: Residue first (slot order)')
        eq(M.poker_eval[2], cards[2], 'preview: second Residue')
        eq(M.poker_eval[3], cards[3], 'preview: then the selected card')
        eq(#G.hand.highlighted, 1, 'selection unchanged by the preview')

        local e = { config = {} }
        G.FUNCS.can_play(e)
        eq(e.config.button, 'play_cards_from_highlighted', 'Play available')
        Board.resize(2, 1)
        eq(Board.free_slots(), 0, 'no free slot on a 2x1 board with 2 cards')
        G.FUNCS.can_play(e)
        eq(e.config.button, nil, 'Play disabled without room')
        Board.resize(5, 3)
        G.FUNCS.can_play(e)
        eq(e.config.button, 'play_cards_from_highlighted', 'Play available again')
    end)

    -- Residue limit, marks, discard ------------------------------------------------------------------------
    test('board: Residue limit keeps room for a full hand (oldest leaves first)', function()
        M.start_board_run()
        M.score_cards = function() return {} end
        local first
        for h = 1, 3 do
            local cards = deal(5, 2 + (h - 1) * 5)
            if h == 1 then first = cards end
            select(cards)
            play()
            check(Board.free_slots() >= Board.play_limit(), 'room for a full hand after hand ' .. h)
        end
        eq(#G.play.cards, 10, 'Residue capped at 10')
        for _, c in ipairs(first) do check(in_area(G.discard, c), 'oldest hand left the board') end
        M.score_cards = nil
    end)

    test('board: Residue selected for Discard uses the normal Discard', function()
        M.start_board_run()
        local cards = deal(7)
        select({ cards[1], cards[2], cards[3] })
        M.score_cards = function() return {} end
        play()
        M.score_cards = nil
        local r1, r2 = cards[1], cards[2]

        r1:click()
        eq(r1.highlighted, true, 'Residue selected')
        eq(Board.marked[1], r1, 'marked for discard')
        local e = { config = {} }
        G.FUNCS.can_discard(e)
        eq(e.config.button, 'discard_cards_from_highlighted', 'Discard available for Residue only')
        eq(#G.hand.highlighted, 0, 'hand selection untouched by can_discard')
        r1:click()
        eq(r1.highlighted, false, 'click again unselects')
        eq(#Board.marked, 0, 'mark removed')

        -- limit: hand + Residue <= discard limit
        select({ cards[4], cards[5], cards[6], cards[7] })
        r1:click()
        eq(#Board.marked, 1, 'fifth selected card (Residue)')
        r2:click()
        eq(#Board.marked, 1, 'sixth refused')
        G.hand:unhighlight_all()

        M.contexts = {}
        G.FUNCS.discard_cards_from_highlighted()
        M.flush_events()
        check(in_area(G.discard, r1), 'Residue discarded')
        check(not in_area(G.play, r1), 'removed from the board')
        eq(r1.ability.ne_slot, nil, 'slot forgotten')
        eq(#G.hand.highlighted, 0, 'no board card left in the hand selection')
        eq(M.last_ease[1], 'discard', 'one discard used')
        local ctx = false
        for _, c in ipairs(M.contexts) do if c.discard and c.other_card == r1 then ctx = true end end
        check(ctx, 'discard context sent for the Residue card')
        eq(#Board.marked, 0, 'marks cleared')

        -- The Hook (hook discard) ignores marks; Play clears them
        G.STATE = G.STATES.SELECTING_HAND
        r2:click()
        G.hand:add_to_highlighted(cards[4])
        G.FUNCS.discard_cards_from_highlighted(nil, true)
        M.flush_events()
        check(in_area(G.play, r2), 'hook discard leaves marked Residue')
        G.STATE = G.STATES.SELECTING_HAND
        select({ cards[5] })
        M.score_cards = function() return {} end
        play()
        M.score_cards = nil
        eq(r2.highlighted, false, 'Play clears the Residue selection')
        check(in_area(G.play, r2), 'unscored Residue stays')
    end)

    test('board: hand end details (return to hand, destroyed, overflow)', function()
        M.start_board_run()
        local cards = deal(3)
        cards[1].ability.return_to_hand = true
        select(cards)
        M.score_cards = function(list) cards[2].destroyed = true; return {} end
        play()
        M.score_cards = nil
        check(in_area(G.hand, cards[1]), 'return_to_hand card goes back to the hand')
        eq(cards[1].ability.ne_slot, nil, 'and leaves the board')
        check(in_area(G.play, cards[2]) and not Board.keeps(cards[2]), 'destroyed card is not Residue')
        check(in_area(G.play, cards[3]) and cards[3].ability.ne_residue, 'third card is Residue')
        G.play:remove_card(cards[2])

        -- more cards than slots: the extra card has no slot and leaves after the hand
        local board = {}
        for i = 1, 16 do
            local c = new_card(2)
            G.play:emplace(c)
            board[i] = c
        end
        eq(board[16].ability.ne_slot, nil, 'overflow card without slot')
        G.play:align_cards()
        check(board[16].T.x > Board.get_layout().x + Board.get_layout().w, 'overflow card beside the board')
        G.FUNCS.draw_from_play_to_discard()
        M.flush_events()
        check(in_area(G.discard, board[16]), 'overflow card discarded at hand end')
    end)

    test('board: end of round clears the board', function()
        M.start_board_run()
        local cards = deal(4)
        select({ cards[1], cards[2] })
        M.score_cards = function() return {} end
        play()
        M.score_cards = nil
        cards[1]:click()
        G.FUNCS.draw_from_hand_to_discard()
        M.flush_events()
        eq(#G.play.cards, 0, 'board empty')
        eq(#G.hand.cards, 0, 'hand empty')
        check(in_area(G.discard, cards[1]) and in_area(G.discard, cards[2]), 'board cards in the discard pile')
        eq(cards[1].ability.ne_residue, nil, 'Residue flag cleared')
        eq(cards[1].T.scale, 0.95, 'scale restored')
        eq(#Board.marked, 0, 'marks cleared')
    end)

    test('board: save and load keep positions', function()
        M.start_board_run()
        local cards = deal(6)
        Board.stage_card(cards[4], 1)
        select({ cards[1], cards[2] })
        M.score_cards = function() return {} end
        play()
        M.score_cards = nil
        local saved = {
            GAME = copy(G.GAME),
            cardAreas = { play = copy(G.play:save()), hand = copy(G.hand:save()) },
        }
        local slots = {}
        for _, c in ipairs(G.play.cards) do slots[#slots + 1] = c.ability.ne_slot end
        table.sort(slots)

        M.start_board_run(saved)
        eq(#G.play.cards, 3, 'board cards loaded')
        local got = {}
        for _, c in ipairs(G.play.cards) do
            got[#got + 1] = c.ability.ne_slot
            check(c.ability.ne_residue, 'loaded board card is Residue')
            local L = Board.get_layout().slots[c.ability.ne_slot]
            check(math.abs(c.T.x + c.T.w / 2 - (L.x + L.w / 2)) < 1e-9 and c.T.scale == L.scale, 'position restored for slot ' .. c.ability.ne_slot)
            eq(c.VT.x, c.T.x, 'snapped to the slot (no fly-in)')
        end
        table.sort(got)
        eq(table.concat(got, ','), table.concat(slots, ','), 'same slots after load')
        eq(Board.busy(), false, 'loaded board is not busy')

        -- run saved before Phase 5: vanilla play area config, cards without slots, duplicates
        local old = copy(saved)
        old.cardAreas.play.config = { card_limit = 5, type = 'play' }
        old.cardAreas.play.cards[1].ability.ne_slot = nil
        old.cardAreas.play.cards[2].ability.ne_slot = 7
        old.cardAreas.play.cards[3].ability.ne_slot = 7
        M.start_board_run(old)
        check(Board.is_board(G.play), 'old save gets a board')
        eq(G.play.config.card_limit, 15, 'card limit updated')
        local seen, ok = {}, true
        for _, c in ipairs(G.play.cards) do
            local s = c.ability.ne_slot
            if not Board.valid_slot(s) or seen[s] then ok = false end
            seen[s] = true
        end
        check(ok, 'every loaded card has its own slot')

        -- a resized board is saved with the area
        Board.resize(6, 4)
        local s2 = { GAME = copy(G.GAME), cardAreas = { play = copy(G.play:save()) } }
        M.start_board_run(s2)
        eq(G.play.config.ne_board.cols, 6, 'saved board width')
        eq(G.play.config.ne_board.rows, 4, 'saved board height')
        eq(#Board.slots, 24, 'slot nodes for 6x4')
        Board.resize(5, 3)
    end)

    test('board: resize keeps columns and distance from the Front row', function()
        M.start_board_run()
        local at = {}
        for _, s in ipairs({ 6, 12, 3, 5 }) do
            local c = new_card(4)
            c.ability.ne_slot = s
            G.play:emplace(c)
            c.ability.ne_slot = s
            c.ability.ne_residue = true
            at[s] = c
        end
        Board.normalize_slots()
        check(Board.resize(4, 2), 'resize to 4x2')
        eq(at[6].ability.ne_slot, 1, 'Middle-left -> Back-left of 4x2')
        eq(at[12].ability.ne_slot, 6, 'Front col 2 stays Front col 2')
        eq(at[3].ability.ne_slot, 5, 'Back row card moved to the first free slot')
        eq(at[5].ability.ne_slot, 7, 'column 5 card moved to the next free slot')
        eq(#Board.slots, 8, 'slot nodes rebuilt')
        eq(G.play.config.card_limit, 8, 'card limit follows the size')
        check(Board.resize(1, 1), 'shrink to 1x1')
        M.flush_events()
        eq(#G.play.cards, 1, 'one card fits, the rest is discarded')
        eq(#G.discard.cards, 3, 'three cards discarded')
        Board.resize(5, 3)
        eq(G.play.cards[1].ability.ne_slot, 11, 'Front row card stays in the Front row')
    end)

    -- Row effects -----------------------------------------------------------------------------------------------
    test('board: row effects (Front base chips x2, Back +2 Mult)', function()
        M.start_board_run()
        local front, back, mid = new_card(7), new_card(9), new_card(5)
        local bonus = new_card(7, nil, { bonus = 30 })
        local stone = new_card(7, nil, { bonus = 50, effect = 'Stone Card' })
        for c, s in pairs({ [front] = 11, [back] = 1, [mid] = 6, [bonus] = 12, [stone] = 13 }) do
            G.play:emplace(c)
            c.ability.ne_slot = s
        end
        eq(front:get_chip_bonus(), 14, 'Front row doubles the rank chips')
        eq(bonus:get_chip_bonus(), 44, 'enhancement chips not doubled')
        eq(stone:get_chip_bonus(), 50, 'card without rank chips unchanged')
        eq(back:get_chip_mult(), 2, 'Back row +2 Mult')
        eq(mid:get_chip_bonus(), 5, 'Middle row neutral (chips)')
        eq(mid:get_chip_mult(), 0, 'Middle row neutral (mult)')
        eq(front:get_chip_mult(), 0, 'Front row gives no mult')
        eq(back:get_chip_bonus(), 9, 'Back row gives no chips')
        local held = new_card(7)
        G.hand:emplace(held)
        eq(held:get_chip_bonus(), 7, 'cards in hand unchanged')
        front.ability.extra_enhancement = 'm_bonus'
        eq(front:get_chip_bonus(), 14 - 7, 'quantum enhancement evaluation unchanged')
    end)

    -- Drawing, collision, controller -------------------------------------------------------------------------------
    test('board: draw order, hover on top, collision uses the drawn size', function()
        M.start_board_run()
        local a, b, c = new_card(2), new_card(3), new_card(4)
        for card, s in pairs({ [a] = 12, [b] = 2, [c] = 7 }) do
            G.play:emplace(card)
            card.ability.ne_slot = s
        end
        G.play:align_cards()
        eq(G.play.cards[1], b, 'area cards sorted by slot')
        M.draw_log = {}
        M.drawhash = {}
        G.play:draw()
        local order = {}
        for _, d in ipairs(M.draw_log) do if d.layer == 'card' then order[#order + 1] = d.card end end
        check(order[1] == b and order[2] == c and order[3] == a, 'drawn back to front')
        local slots_drawn = 0
        for _, n in ipairs(M.drawhash) do if n.ne_board_slot then slots_drawn = slots_drawn + 1 end end
        eq(slots_drawn, 15, 'slots drawn during a blind')
        G.CONTROLLER.hovering.target = b
        M.draw_log = {}
        G.play:draw()
        order = {}
        for _, d in ipairs(M.draw_log) do if d.layer == 'card' then order[#order + 1] = d.card end end
        eq(order[3], b, 'hovered card drawn last')
        G.CONTROLLER.hovering.target = nil

        local L = Board.get_layout().slots[12]
        check(a:collides_with_point({ x = L.x + L.w / 2, y = L.y + L.h / 2 }), 'hit inside the drawn card')
        check(not a:collides_with_point({ x = a.T.x + 0.02, y = a.T.y + 0.02 }), 'no hit in the unscaled box corner')
        eq(a.T.w, G.CARD_W, 'box restored after the test')

        G.GAME.facing_blind = nil
        M.drawhash = {}
        G.play:draw()
        slots_drawn = 0
        for _, n in ipairs(M.drawhash) do if n.ne_board_slot then slots_drawn = slots_drawn + 1 end end
        eq(slots_drawn, 0, 'no slots outside a blind')
    end)

    test('board: slot state and controller focus', function()
        M.start_board_run()
        local cards = deal(4)
        local r = new_card(8)
        G.play:emplace(r)
        r.ability.ne_residue = true
        G.play:align_cards()
        local s_r = r.ability.ne_slot
        eq(Board.slots[s_r].states.hover.can, false, 'occupied slot not hoverable')
        eq(Board.slots[1].states.hover.can, true, 'empty slot hoverable')
        eq(Board.slots[1].config.force_focus, true, 'empty slot focusable')

        local C = G.CONTROLLER
        C.focused.target = cards[1]
        M.vanilla_buttons = {}
        C:button_press_update('leftshoulder', 0)
        eq(C.snapped, Board.slots[7], 'LB: focus the first empty slot (quick play order)')
        eq(#M.vanilla_buttons, 0, 'LB used by the board')
        C.focused.target = Board.slots[7]
        C:button_press_update('leftshoulder', 0)
        eq(C.snapped, cards[1], 'LB again: back to the hand')
        C.focused.target = r
        C:button_press_update('b', 0)
        eq(C.snapped, cards[1], 'B on a board card: back to the hand')
        C.focused.target = cards[2]
        C:button_press_update('b', 0)
        eq(M.vanilla_buttons[1], 'b', 'B in the hand keeps its vanilla use')
        C:button_press_update('x', 0)
        eq(M.vanilla_buttons[2], 'x', 'other buttons untouched')
        C.button_registry.leftshoulder = { { node = {} } }
        C:button_press_update('leftshoulder', 0)
        eq(M.vanilla_buttons[3], 'leftshoulder', 'LB left to a focused card button')
        C.button_registry.leftshoulder = nil
        G.STATE = G.STATES.HAND_PLAYED
        C:button_press_update('leftshoulder', 0)
        eq(M.vanilla_buttons[4], 'leftshoulder', 'board ignores LB while a hand is played')
        G.STATE = G.STATES.SELECTING_HAND
        C.focused.target = nil

        -- A on a focused slot clicks it: stages the selected card
        select({ cards[3] })
        Board.slots[2]:click()
        eq(Board.staged_slot(cards[3]), 2, 'slot click stages')
        G.play:align_cards()
        eq(Board.slots[2].states.hover.can, false, 'reserved slot not hoverable')
        G.STATE = G.STATES.HAND_PLAYED
        G.play:align_cards()
        eq(Board.slots[1].states.hover.can, false, 'slots inactive during a hand')
        G.STATE = G.STATES.SELECTING_HAND
    end)

    -- Effects API ----------------------------------------------------------------------------------------------------
    test('board: place, swap, shuffle and ne_board_changed', function()
        M.start_board_run()
        local a, b, c = new_card(2), new_card(3), new_card(4)
        for card, s in pairs({ [a] = 1, [b] = 2, [c] = 3 }) do
            G.play:emplace(card)
            card.ability.ne_slot = s
            card.ability.ne_residue = true
        end
        local v0 = Board.version
        check(Board.place(a, 15), 'place into an empty slot')
        eq(a.ability.ne_slot, 15, 'moved')
        check(not Board.place(a, 2), 'occupied slot refused')
        check(Board.version > v0, 'board version bumped')
        check(Board.swap(15, 2), 'swap')
        check(a.ability.ne_slot == 2 and b.ability.ne_slot == 15, 'swapped')
        check(Board.swap(3, 9), 'swap with an empty slot')
        eq(c.ability.ne_slot, 9, 'moved by swap')
        eq(Board.card_at(5, 3), b, 'card_at(col, row)')
        eq(#Board.residues(), 3, 'three Residue cards')
        eq(#Board.residues(3), 1, 'one in the Front row')
        -- slots in order 2, 9, 15; the mock shuffle sorts the cards by sort_id (a, b, c) and
        -- reverses them (c, b, a)
        check(Board.shuffle_residues('x'), 'shuffle')
        eq(c.ability.ne_slot, 2, 'shuffled (deterministic mock) c')
        eq(b.ability.ne_slot, 9, 'shuffled (deterministic mock) b')
        eq(a.ability.ne_slot, 15, 'shuffled (deterministic mock) a')
        M.contexts = {}
        M.flush_events()
        local reasons = {}
        for _, ctx in ipairs(M.contexts) do if ctx.ne_board_changed then reasons[#reasons + 1] = ctx.ne_reason end end
        eq(table.concat(reasons, ','), 'place,swap,swap,shuffle', 'ne_board_changed sent from the event queue')
        check(not Board.row_full(1), 'Back row not full')
        eq(#Board.neighbors(8), 4, 'centre slot has 4 neighbours')
    end)

    test('board: debug cheats, overlay line, small cards setting', function()
        M.start_board_run()
        G.GAME.blind = { chips = 300 }
        for i = 1, 20 do G.deck:emplace(new_card(2 + i % 13)) end
        G.FUNCS.ne_cheat_board_fill()
        M.flush_events()
        eq(#G.play.cards, 4, 'fill: 4 cards on the board')
        eq(#Board.residues(), 4, 'fill: all Residue')
        eq(Board.busy(), false, 'filled board not busy')
        G.FUNCS.ne_cheat_board_fill()
        G.FUNCS.ne_cheat_board_fill()
        M.flush_events()
        eq(#Board.residues(), Board.residue_cap(), 'fill stops at the Residue limit')
        M.sounds = {}
        G.FUNCS.ne_cheat_board_fill()
        eq(M.sounds[#M.sounds], 'cancel', 'no room: cancel')

        G.FUNCS.ne_cheat_board_size()
        eq(G.play.config.ne_board.cols, 6, 'size cycle: 6x4')
        G.FUNCS.ne_cheat_board_size()
        eq(G.play.config.ne_board.cols, 4, 'size cycle: 4x2')
        G.FUNCS.ne_cheat_board_size()
        eq(G.play.config.ne_board.cols .. 'x' .. G.play.config.ne_board.rows, '5x3', 'size cycle: back to 5x3')
        M.flush_events()
        check(G.FUNCS.ne_cheat_board_shuffle() == nil, 'shuffle runs')

        NE.config.debug.enabled = true
        NE.Debug.toggle_overlay()
        love.update(0.3)
        check(NE.Debug.overlay.text:find('Board 5x3', 1, true), 'overlay shows the board line')
        NE.Debug.toggle_overlay()

        G.FUNCS.ne_cheat_board_clear()
        M.flush_events()
        eq(#G.play.cards, 0, 'clear: board empty')

        local k1 = Board.get_layout().k
        NE.config.board.small_cards = true
        local k2 = Board.get_layout().k
        check(math.abs(k2 - k1 * Board.SMALL_SCALE) < 1e-9, 'small cards setting shrinks the board')
        eq(Board.slots[1].T.w, Board.layout.slots[1].w, 'slot nodes follow the new layout')
        NE.config.board.small_cards = false
        G.GAME.blind = nil
    end)

    test('board: no garbage while idle', function()
        M.start_board_run()
        local cards = deal(8)
        for i = 1, 10 do
            local c = new_card(3)
            G.play:emplace(c)
            c.ability.ne_residue = true
        end
        Board.stage_card(cards[1], 12)
        M.count_draws = true
        local hash = {}
        local add_ref = add_to_drawhash
        add_to_drawhash = function(obj) hash[1] = obj end
        -- warm up (first-call allocations: layout, JIT traces)
        for _ = 1, 50 do
            G.play:align_cards(); G.hand:align_cards(); G.play:draw(); G.hand:draw()
        end
        -- interpreter only: JIT trace recording allocates on its own and would blur the count
        if jit then jit.off() end
        collectgarbage('collect')
        collectgarbage('stop')
        local before = collectgarbage('count')
        for _ = 1, 500 do
            G.play:align_cards()
            G.hand:align_cards()
            G.play:draw()
            G.hand:draw()
        end
        local grown = collectgarbage('count') - before
        collectgarbage('restart')
        if jit then jit.on() end
        M.count_draws = nil
        add_to_drawhash = add_ref
        check(grown < 1, ('500 frames of align + draw allocate %.2f KB'):format(grown))
    end)
end
