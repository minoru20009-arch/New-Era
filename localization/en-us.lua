return {
    descriptions = {
        Mod = {
            NewEra = {
                name = 'New Era',
                text = {
                    'Extreme expansion for Balatro.',
                    'Board & formations, hyper scoring, branching map,',
                    'and 121 crossover jokers in three ranks:',
                    '{C:inactive}Unranked{}, {C:red}Demonic{} and {C:gold}Heavenly{}.',
                    ' ',
                    '{C:inactive}Development build (Phase 3: big numbers).{}',
                },
            },
        },
        Joker = {
            j_ne_test_unranked = {
                name = 'Test: Unranked',
                text = {
                    '{C:mult}+#1#{} Mult',
                    '{C:inactive}(New Era debug joker){}',
                },
            },
            j_ne_test_demonic = {
                name = 'Test: Demonic',
                text = {
                    '{X:mult,C:white} X#1# {} Mult',
                    '{C:inactive}(New Era debug joker){}',
                },
            },
            j_ne_test_heavenly = {
                name = 'Test: Heavenly',
                text = {
                    '{C:chips}+#1#{} Chips',
                    '{X:mult,C:white} X#2# {} Mult',
                    '{C:inactive}(New Era debug joker){}',
                },
            },
            j_ne_test_overflow = {
                name = 'Test: Overflow',
                text = {
                    '{X:chips,C:white} X#1# {} Chips',
                    '{X:mult,C:white} X#2# {} Mult',
                    'Score passes {C:attention}1e308{}',
                    '{C:inactive}(New Era debug joker){}',
                },
            },
        },
    },
    misc = {
        labels = {
            ne_unranked = 'Unranked',
            ne_demonic = 'Demonic',
            ne_heavenly = 'Heavenly',
            k_ne_unranked = 'Unranked',
            k_ne_demonic = 'Demonic',
            k_ne_heavenly = 'Heavenly',
        },
        dictionary = {
            k_ne_unranked = 'Unranked',
            k_ne_demonic = 'Demonic',
            k_ne_heavenly = 'Heavenly',

            ne_badge_debug = 'DEBUG',

            ne_cfg_title = 'New Era settings',
            ne_cfg_hide_jokers = 'Hide vanilla jokers',
            ne_cfg_hide_planets = 'Hide vanilla planets',
            ne_cfg_hide_blinds = 'Hide vanilla blinds',
            ne_cfg_debug = 'Debug tools (F9 / F10)',
            ne_cfg_test_jokers = 'Test jokers in pools',
            ne_cfg_note = 'Planets/blinds take effect from Phase 6/10',

            ne_cheat_title = 'New Era cheats',
            ne_cheat_not_in_run = 'Start a run to use cheats',
            ne_cheat_money = '+$50',
            ne_cheat_hand = '+1 Hand',
            ne_cheat_discard = '+1 Discard',
            ne_cheat_ante = 'Ante +1',
            ne_cheat_meet_target = 'Score = blind target',
            ne_cheat_give_unranked = 'Give Test: Unranked',
            ne_cheat_give_demonic = 'Give Test: Demonic',
            ne_cheat_give_heavenly = 'Give Test: Heavenly',
            ne_cheat_no_room = 'No joker slot free',
            ne_cheat_score_1e500 = 'Score = 1e500',
            ne_cheat_score_mul = 'Score x1e150',
            ne_cheat_target_ee10 = 'Target = ee10',
            ne_cheat_target_tet5 = 'Target = 10^^5',
            ne_cheat_hand_display = 'Hand: big chips/mult',
            ne_cheat_give_overflow = 'Give Test: Overflow',
        },
    },
}
