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
                    '{C:inactive}Build pengembangan (Fase 3: angka besar).{}',
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

            ne_cfg_title = 'Pengaturan New Era',
            ne_cfg_hide_jokers = 'Sembunyikan joker vanilla',
            ne_cfg_hide_planets = 'Sembunyikan planet vanilla',
            ne_cfg_hide_blinds = 'Sembunyikan blind vanilla',
            ne_cfg_debug = 'Alat debug (F9 / F10)',
            ne_cfg_test_jokers = 'Joker uji di pool',
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
        },
    },
}
