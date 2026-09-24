return {
    descriptions = {
        Mod = {
            NewEra = {
                name = 'New Era',
                text = {
                    'Ekspansi ekstrem untuk Balatro.',
                    'Papan & formasi, skor hiper, peta bercabang,',
                    'dan 121 joker crossover dalam tiga rank:',
                    '{C:inactive}Unranked{}, {C:red}Demonic{}, dan {C:gold}Heavenly{}.',
                    ' ',
                    '{C:inactive}Build pengembangan (Fase 5: papan).{}',
                },
            },
        },
        Joker = {
            j_ne_test_unranked = {
                name = 'Uji: Unranked',
                text = {
                    '{C:mult}+#1#{} Mult',
                    '{C:inactive}(Joker debug New Era){}',
                },
            },
            j_ne_test_demonic = {
                name = 'Uji: Demonic',
                text = {
                    '{X:mult,C:white} X#1# {} Mult',
                    '{C:inactive}(Joker debug New Era){}',
                },
            },
            j_ne_test_heavenly = {
                name = 'Uji: Heavenly',
                text = {
                    '{C:chips}+#1#{} Chips',
                    '{X:mult,C:white} X#2# {} Mult',
                    '{C:inactive}(Joker debug New Era){}',
                },
            },
            j_ne_test_overflow = {
                name = 'Uji: Overflow',
                text = {
                    '{X:chips,C:white} X#1# {} Chips',
                    '{X:mult,C:white} X#2# {} Mult',
                    'Skor melewati {C:attention}1e308{}',
                    '{C:inactive}(Joker debug New Era){}',
                },
            },
            j_ne_test_emult = {
                name = 'Uji: ^Mult',
                text = {
                    '{X:dark_edition,C:white} ^#1# {} Mult',
                    '{C:inactive}(Joker debug New Era){}',
                },
            },
            j_ne_test_eemult = {
                name = 'Uji: ^^Mult',
                text = {
                    '{X:dark_edition,C:white} ^^#1# {} Mult',
                    '{C:inactive}(Joker debug New Era){}',
                },
            },
            j_ne_test_hypermult = {
                name = 'Uji: Hyper Mult',
                text = {
                    '{X:dark_edition,C:white} #1##2# {} Mult',
                    '{C:inactive}(Joker debug New Era){}',
                },
            },
            j_ne_test_aura = {
                name = 'Uji: Aura',
                text = {
                    'Fase {C:attention}Kenaikan{}:',
                    '{C:gold}+#1#{} Aura',
                    '{C:inactive}Skor = (Chips x Mult) ^ Aura{}',
                    '{C:inactive}(Joker debug New Era){}',
                },
            },
            j_ne_test_phases = {
                name = 'Uji: Fase',
                text = {
                    'Menampilkan pesan di fase',
                    '{C:attention}Pertanda{}, {C:attention}Rantai{}, dan {C:attention}Kenaikan{}',
                    '{C:attention}Penghakiman{}: {C:money}+#1#{} Divinity',
                    '{C:inactive}(Joker debug New Era){}',
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

            ne_cfg_title = 'Pengaturan New Era',
            ne_cfg_hide_jokers = 'Sembunyikan joker vanilla',
            ne_cfg_hide_planets = 'Sembunyikan planet vanilla',
            ne_cfg_hide_blinds = 'Sembunyikan blind vanilla',
            ne_cfg_debug = 'Alat debug (F9 / F10)',
            ne_cfg_test_jokers = 'Joker uji di pool',
            ne_cfg_board_small = 'Kartu papan lebih kecil',
            ne_cfg_note = 'Planet/blind baru berlaku mulai Fase 6/10',

            ne_cheat_title = 'Cheat New Era',
            ne_cheat_not_in_run = 'Mulai run untuk memakai cheat',
            ne_cheat_money = '+$50',
            ne_cheat_hand = '+1 Tangan',
            ne_cheat_discard = '+1 Discard',
            ne_cheat_ante = 'Ante +1',
            ne_cheat_meet_target = 'Skor = target blind',
            ne_cheat_give_unranked = 'Beri Uji: Unranked',
            ne_cheat_give_demonic = 'Beri Uji: Demonic',
            ne_cheat_give_heavenly = 'Beri Uji: Heavenly',
            ne_cheat_no_room = 'Slot joker penuh',
            ne_cheat_score_1e500 = 'Skor = 1e500',
            ne_cheat_score_mul = 'Skor x1e150',
            ne_cheat_target_ee10 = 'Target = ee10',
            ne_cheat_target_tet5 = 'Target = 10^^5',
            ne_cheat_hand_display = 'Tangan: chips/mult besar',
            ne_cheat_give_overflow = 'Beri Uji: Overflow',
            ne_cheat_give_emult = 'Beri Uji: ^Mult',
            ne_cheat_give_eemult = 'Beri Uji: ^^Mult',
            ne_cheat_give_hypermult = 'Beri Uji: Hyper',
            ne_cheat_give_aura = 'Beri Uji: Aura',
            ne_cheat_give_phases = 'Beri Uji: Fase',
            ne_cheat_currency = '+5 tiap mata uang',
            ne_cheat_board_fill = 'Papan: +4 Residu',
            ne_cheat_board_size = 'Papan: ukuran 5x3/6x4/4x2',
            ne_cheat_board_shuffle = 'Papan: acak Residu',
            ne_cheat_board_clear = 'Papan: kosongkan',

            ne_msg_omen = 'Pertanda!',
            ne_msg_chain = 'Rantai!',
            ne_msg_ascension = 'Kenaikan!',
        },
    },
}
