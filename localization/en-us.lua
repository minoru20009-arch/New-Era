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
                    '{C:inactive}Development build (Phase 5: board).{}',
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
            j_ne_test_emult = {
                name = 'Test: ^Mult',
                text = {
                    '{X:dark_edition,C:white} ^#1# {} Mult',
                    '{C:inactive}(New Era debug joker){}',
                },
            },
            j_ne_test_eemult = {
                name = 'Test: ^^Mult',
                text = {
                    '{X:dark_edition,C:white} ^^#1# {} Mult',
                    '{C:inactive}(New Era debug joker){}',
                },
            },
            j_ne_test_hypermult = {
                name = 'Test: Hyper Mult',
                text = {
                    '{X:dark_edition,C:white} #1##2# {} Mult',
                    '{C:inactive}(New Era debug joker){}',
                },
            },
            j_ne_test_aura = {
                name = 'Test: Aura',
                text = {
                    '{C:attention}Ascension{} phase:',
                    '{C:gold}+#1#{} Aura',
                    '{C:inactive}Score = (Chips x Mult) ^ Aura{}',
                    '{C:inactive}(New Era debug joker){}',
                },
            },
            j_ne_test_phases = {
                name = 'Test: Phases',
                text = {
                    'Shows a message in the',
                    '{C:attention}Omen{}, {C:attention}Chain{} and {C:attention}Ascension{} phases',
                    '{C:attention}Judgment{}: {C:money}+#1#{} Divinity',
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
        v_dictionary = {
            ne_a_echips = '^#1# Chips',
            ne_a_emult = '^#1# Mult',
            ne_a_eemult = '^^#1# Mult',
            ne_a_hypermult = '#1##2# Mult',
            ne_a_aura = '+#1# Aura',
            ne_a_aura_minus = '-#1# Aura',
            ne_a_xaura = 'X#1# Aura',
            ne_a_divinity = '#1# Divinity',
            ne_a_corruption = '#1# Corruption',
            ne_a_time = '#1# Time',
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
            ne_cfg_board_small = 'Smaller board cards',
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
            ne_cheat_give_emult = 'Give Test: ^Mult',
            ne_cheat_give_eemult = 'Give Test: ^^Mult',
            ne_cheat_give_hypermult = 'Give Test: Hyper',
            ne_cheat_give_aura = 'Give Test: Aura',
            ne_cheat_give_phases = 'Give Test: Phases',
            ne_cheat_currency = '+5 each currency',
            ne_cheat_board_fill = 'Board: +4 Residue',
            ne_cheat_board_size = 'Board: size 5x3/6x4/4x2',
            ne_cheat_board_shuffle = 'Board: shuffle Residue',
            ne_cheat_board_clear = 'Board: clear',

            ne_msg_omen = 'Omen!',
            ne_msg_chain = 'Chain!',
            ne_msg_ascension = 'Ascension!',
        },
    },
}
