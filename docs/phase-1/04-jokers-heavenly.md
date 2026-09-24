# 04 — Joker Heavenly (#92–#121)

Format sama dengan 02. Kerangka power Heavenly: `^^Mult` (tetrasi 1.1 → 3), **Aura**, penulisan ulang fase dan aturan, serta sebagian mengabaikan imunitas. #121 Kami Tenchi satu-satunya yang memakai pentasi `{3}`. Semua joker Heavenly memakai tier style Heavenly (bingkai halo emas, kilau iridesen, bloom).

Catatan implementasi yang berlaku untuk seluruh file ini:
- Semua kondisi joker New Era ("jika formasi X", "jika tangan terakhir", dll.) wajib melewati helper `NE.cond(card, key, value)` agar #94 Aizen bisa membuatnya selalu benar.
- Joker yang mengubah ukuran papan (#118, #120) memakai `NE.Board.resize(cols, rows)`; papan harus mendukung dimensi variabel sejak awal.

---

### #92 Cosmic Garou — `j_ne_cosmic_garou`
One Punch Man · Tag: `copy`, `aura` · $20
- **Lore:** Melihat sebuah teknik sekali, dan menirunya dengan skala kosmik.
- **Kemampuan:** Setiap kali joker lain memicu efek skor, Cosmic Garou memicu salinan efek itu 1 kali (termasuk `^` dan `^^`; tidak menyalin efek salinan). +0.03 Aura per Boss dikalahkan (permanen).
- **Hook:** optional feature `post_trigger`; `context.post_trigger` → ulangi `other_ret` (tandai `ne_is_copy`); `context.ne_encounter_cleared`; `context.ne_ascension` → `aura`.
- **Shader:** motif `cosmos` · glyph `fist` · `#0B0C10 / #66FCF1 / #C5C6C7` · speed 0.7 · intensity 0.7
- **Animasi:** tubuh berisi bintang; bayangan cermin muncul setiap kali efek disalin.

### #93 Saitama — `j_ne_saitama`
One Punch Man · Tag: `hyper`, `blind` · $20
- **Lore:** Satu pukulan. Selalu satu pukulan.
- **Kemampuan:** Serious Punch: tangan terakhir di tiap ronde ^^2 Mult. Tangan lain: x1 (bosan). Serious Series (aktif, 1x per ante): kalahkan fase blind saat ini seketika.
- **Hook:** `context.joker_main` + `NE.cond(card,'last_hand')` → `eemult`; `ne_active` → `NE.Blind.clear_phase()`.
- **Shader:** motif `radiance` · glyph `fist` · `#FFD60A / #D00000 / #FFFFFF` · speed 0.3 · intensity 0.3 (sengaja polos)
- **Animasi:** jeda hening (semua overlay berhenti), lalu satu pukulan: gelombang kejut membelah layar.

### #94 Sosuke Aizen (Hogyoku) — `j_ne_aizen`
Bleach · Tag: `rule`, `aura`, `nullify` · $21
- **Lore:** Sejak awal, semuanya sudah berjalan sesuai rencananya.
- **Kemampuan:** Kyoka Suigetsu: semua syarat kondisional pada joker Anda dianggap terpenuhi (mis. "jika formasi X", "jika di baris Y", "jika tangan terakhir"). Trait boss yang bereaksi terhadap pilihan Anda (Tirani Formasi, Kunci Baris, dsb.) hanya melihat ilusi dan tidak memicu. +0.1 Aura.
- **Hook:** override `NE.cond` → selalu `true`; `context.ne_boss_trait` (trait bertipe `choice_reactive`) → `ne_cancel`; `context.ne_ascension`.
- **Shader:** motif `glitch` (cermin) · glyph `orb` · `#4B3F72 / #E6E6FA / #FFD700` · speed 0.6 · intensity 0.7
- **Animasi:** layar pecah seperti cermin lalu menyatu kembali.

### #95 Ichibe Hyosube — `j_ne_ichibe`
Bleach · Tag: `rule` · $21
- **Lore:** Yang memberi nama pada segala sesuatu, juga bisa mencabutnya.
- **Kemampuan:** Kuasa Nama (aktif, 1x per ronde): beri nama baru pada formasi yang akan dimainkan; tangan ini dihitung sebagai formasi lain pilihan Anda (dengan level dan nilai dasar formasi itu). Futen Taisatsuryō (pasif): semua angka trait boss dibelah dua. ^^1.1 Mult.
- **Hook:** `ne_active` → `context.evaluate_poker_hand` dengan `replace_scoring_name`; `NE.Blind.trait_scale(0.5)`; `context.joker_main` → `eemult`.
- **Shader:** motif `ink` · glyph `brush` · `#000000 / #F5F5DC / #8B0000` · speed 0.5 · intensity 0.7
- **Animasi:** sapuan kuas tinta hitam menulis kaligrafi melintasi layar.

### #96 Yhwach — `j_ne_yhwach`
Bleach · Tag: `rule`, `map` · $21
- **Lore:** Melihat masa depan, lalu menulisnya ulang.
- **Kemampuan:** The Almighty: lihat 5 kartu berikutnya di tiap dek dan peta 2 ante ke depan (termasuk trait boss). Tulis Ulang Masa Depan (aktif, 2 ✦, 1x per ronde): susun ulang 5 kartu teratas Dek Utama, atau reroll trait boss berikutnya. ^^1.2 Mult.
- **Hook:** UI pratinjau dek; `NE.Map.pregenerate(ante+2)`; `ne_active`; `NE.BossGen.reroll(next_boss)`.
- **Shader:** motif `eye` · glyph `eye` · `#0D0D0D / #B30000 / #F2F2F2` · speed 0.6 · intensity 0.75
- **Animasi:** banyak mata terbuka di seluruh layar; kilasan masa depan (flash cepat).

### #97 Giorno Giovanna (GER) — `j_ne_giorno_ger`
JoJo · Tag: `nullify` · $22
- **Lore:** Setiap aksi dikembalikan ke nol. Tidak ada yang pernah sampai.
- **Kemampuan:** Return to Zero: setiap aksi yang merugikan Anda dibatalkan: trait boss, penghancuran kartu/joker oleh boss, pengurangan tangan/discard oleh boss, serta rewind/time stop milik boss. Tidak berlaku terhadap imunitas Inevitable. ^^1.1 Mult.
- **Hook:** `context.ne_boss_trait` → `ne_cancel` (kecuali `Inevitable`); `context.joker_main`.
- **Shader:** motif `radiance` · glyph `arrow` · `#FFD700 / #6A0DAD / #FFFFFF` · speed 0.7 · intensity 0.75
- **Animasi:** cahaya emas; garis-garis bergerak mundur menuju titik nol.

### #98 Enrico Pucci — `j_ne_pucci`
JoJo · Tag: `time`, `rule` · $22
- **Lore:** Waktu dipercepat sampai alam semesta berputar ulang.
- **Kemampuan:** Made in Heaven: tangan ke-n dalam ronde ^^(1 + 0.1·n) Mult. ⧗ didapat dari semua tangan tidak terpakai (tanpa batas +2 per ronde). Universe Reset (aktif, sekali per run): ulangi ante saat ini dari awal peta dengan semua sumber daya utuh; boss ante ini dibuat ulang tanpa imunitas.
- **Hook:** `context.joker_main` (`hands_played`); hook penghitung ⧗ akhir ronde; `ne_active` → `NE.Map.restart_ante{strip_immunities=true}`.
- **Shader:** motif `gears` · glyph `clock` · `#F8F9FA / #6C757D / #9D4EDD` · speed 2.0 · intensity 0.75
- **Animasi:** matahari dan bulan berputar cepat di latar; jarum jam berputar gila.

### #99 Rimuru Tempest — `j_ne_rimuru`
Tensura · Tag: `steal`, `copy` · $22
- **Lore:** Slime yang menelan apa saja dan menjadi apa saja.
- **Kemampuan:** Predator (aktif, 1x per ronde): mangsa 1 target. Kartu → Rimuru +Chips permanen sebesar chips kartu. Consumable → efeknya tersimpan dan bisa dipakai ulang 1x per ante. Joker Unranked/Demonic → kemampuannya ditambahkan ke Rimuru permanen (tanpa batas). Beelzebuth: setelah memangsa 5 joker, ^^1.2 Mult.
- **Hook:** `ne_active` (multi-jenis target); `NE.AbilityProxy` (tak terbatas); penyimpanan consumable di `ability.extra.stored`.
- **Shader:** motif `water` · glyph `wave` · `#4CC9F0 / #4361EE / #F1FAEE` · speed 0.8 · intensity 0.7
- **Animasi:** lendir biru menelan target (distorsi seperti gel).

### #100 Ainz Ooal Gown — `j_ne_ainz`
Overlord · Tag: `create`, `rule` · $23
- **Lore:** Sihir super-tier yang mengabulkan permintaan dengan harga level.
- **Kemampuan:** Supreme Being: +0.01 Aura per Level (mulai Level 100). Wish Upon a Star (aktif, 1x per ante): Ainz kehilangan 5 Level dan mengabulkan 1 dari 3 permintaan: buat joker Heavenly acak (kecuali Ainz dan Kami Tenchi) / semua formasi +5 level / hapus semua trait boss selama ante ini.
- **Hook:** `context.ne_ascension` → `aura`; `ne_active` (pilihan UI 3 opsi); `SMODS.add_card`; `SMODS.upgrade_poker_hands`.
- **Shader:** motif `sigil` · glyph `skull` · `#5A189A / #FFD700 / #10002B` · speed 0.5 · intensity 0.75
- **Animasi:** lingkaran sihir raksasa dengan cincin bintang jatuh.

### #101 Anos Voldigoad — `j_ne_anos`
Misfit of Demon King Academy · Tag: `protect`, `rule` · $23
- **Lore:** Menghancurkan bahkan konsep kehancuran itu sendiri.
- **Kemampuan:** Kartu dan joker Anda tidak bisa dihancurkan oleh apa pun. Efek "hancurkan" milik Anda sendiri menjadi "nonaktifkan 1 ronde" tetapi hadiahnya tetap diberikan. Biaya ☠ kontrak joker Demonic tidak berlaku. Venuzdonoa: ^^1.3 Mult; melawan boss berimunitas Indestructible: ^^1.5.
- **Hook:** hook `SMODS.destroy_cards` → konversi ke debuff sementara; `NE.Currency` mengabaikan sumber `contract`; `context.joker_main`.
- **Shader:** motif `sigil` · glyph `sword` · `#0B0B0B / #D4AF37 / #6A040F` · speed 0.6 · intensity 0.75
- **Animasi:** lingkaran sihir hitam-emas berlapis; pedang Venuzdonoa muncul di tengah.

### #102 Whis — `j_ne_whis`
Dragon Ball · Tag: `rewind` · $24
- **Lore:** Tiga menit ke belakang, seolah tidak pernah terjadi.
- **Kemampuan:** Temporal Do-Over: sekali per ronde, ulangi tangan terakhir secara gratis (tanpa ⧗); semua kartu kembali ke posisi semula dan skor tangan itu dibatalkan. Pelatih: semua joker Demonic dari Dragon Ball (#66–#71) +^0.1 Mult. ^^1.3 Mult.
- **Hook:** `NE.Snapshot` per tangan; `ne_active`; `context.other_joker` (cek `ne_source == 'Dragon Ball'`).
- **Shader:** motif `radiance` · glyph `halo` · `#A5B4FC / #312E81 / #FFFFFF` · speed 0.6 · intensity 0.75
- **Animasi:** ketukan tongkat; riak waktu bergerak mundur; cincin halo.

### #103 Grand Priest — `j_ne_grand_priest`
Dragon Ball · Tag: `rule`, `blind` · $24
- **Lore:** Wasit tertinggi yang menentukan aturan pertandingan.
- **Kemampuan:** Aturan Turnamen: di awal tiap ante, pilih 1 dari 3 aturan untuk ante itu (mis. "semua blind 1 fase", "semua trait boss nonaktif tetapi target x2", "formasi sekunder dihitung 100%", "Celah memberi hadiah x3"). ^^1.4 Mult.
- **Hook:** `context.ante_change`; UI pilihan; `NE.Rules.push_temp(rule, 'ante')`.
- **Shader:** motif `radiance` · glyph `halo` · `#E0E7FF / #1E1B4B / #F59E0B` · speed 0.5 · intensity 0.75
- **Animasi:** arena turnamen melingkar muncul + halo suci.

### #104 Zeno — `j_ne_zeno`
Dragon Ball · Tag: `destroy`, `blind` · $25
- **Lore:** Raja segala sesuatu, yang bisa menghapus apa pun tanpa sisa.
- **Kemampuan:** Hapus (aktif, 1x per ante): hapus 1 target: satu blind (seketika kalah, termasuk semua fase boss), satu trait, satu biaya kontrak yang sedang aktif, atau satu aturan boss. Hanya bisa dihentikan imunitas Beyond Erasure. ^^1.5 Mult.
- **Hook:** `ne_active` (multi-target); `NE.Blind.defeat_encounter/remove_trait`; `NE.Contracts.clear`.
- **Shader:** motif `radiance` · glyph `orb` · `#E0FBFC / #00B4D8 / #FFFFFF` · speed 0.4 · intensity 0.75
- **Animasi:** target luruh menjadi piksel cahaya lalu lenyap tanpa suara.

### #105 Simon (TTGL) — `j_ne_simon`
Gurren Lagann · Tag: `scaling`, `hyper` · $25
- **Lore:** Bor yang menembus langit, dengan tekad yang terus bertambah.
- **Kemampuan:** Spiral Power: +^^0.04 Mult setiap tangan dimainkan (permanen, tanpa batas; mulai ^^1). Giga Drill Breaker: tangan terakhir melawan boss mendapat tambahan +^^1.
- **Hook:** `context.after` (tumpuk); `context.joker_main` → `eemult`.
- **Shader:** motif `spiral` · glyph `drill` · `#39FF14 / #0B3D0B / #F72585` · speed 1.2 · intensity 0.5→1.0
- **Animasi:** pusaran bor spiral hijau menembus layar.

### #106 Anti-Spiral — `j_ne_anti_spiral`
Gurren Lagann · Tag: `blind`, `rule` · $26
- **Lore:** Penjaga yang menekan pertumbuhan tanpa batas.
- **Kemampuan:** Segel Spiral: target setiap blind dibatasi maksimal (skor tangan terbaik Anda dalam run)^0.95. Rival: jika Simon ada, keduanya +^^0.3 Mult. ^^1.6 Mult.
- **Hook:** `NE.Blind.cap_target(best_hand^0.95)` di `context.setting_blind` dan tiap fase; `G.GAME.newera.stats.best_hand`; `SMODS.find_card('j_ne_simon')`.
- **Shader:** motif `sigil` · glyph `star` · `#0A1128 / #1282A2 / #FEFCFB` · speed 0.4 · intensity 0.75
- **Animasi:** kisi geometris biru gelap menutup layar; kristal bintang.

### #107 Lain Iwakura — `j_ne_lain`
Serial Experiments Lain · Tag: `rule` · $26
- **Lore:** Semua orang terhubung. Dan Lain bisa menyunting koneksinya.
- **Kemampuan:** The Wired (aktif, 1x per ante): sunting satu nilai run: level satu formasi = level formasi tertinggi Anda / ☠ = 0 / $ = uang tertinggi yang pernah Anda miliki di run / ⧗ = maksimum. Present Day, Present Time: ^^1.7 Mult.
- **Hook:** `ne_active` (UI pilihan); statistik `G.GAME.newera.stats.max_dollars`.
- **Shader:** motif `glitch` · glyph `wire` · `#1B1B1B / #E5E5E5 / #FF4D6D` · speed 1.0 · intensity 0.75
- **Animasi:** statik CRT, kabel-kabel melintas, teks glitch "PRESENT DAY, PRESENT TIME".

### #108 Haruhi Suzumiya — `j_ne_haruhi`
Haruhi Suzumiya · Tag: `rule`, `luck` · $27
- **Lore:** Dunia berubah setiap kali ia bosan, dan ia tidak menyadarinya.
- **Kemampuan:** Selama formasi utama tidak berulang di 3 tangan terakhir (senang): ^^1.8 Mult. Jika 3 tangan berturut-turut memakai formasi utama yang sama (bosan), realitas berubah acak: buat 1 joker Heavenly sementara (1 ronde) / ubah semua kartu tangan menjadi satu suit / tambahkan 1 fase boss dengan hadiah x3 (Closed Space).
- **Hook:** riwayat `SMODS.last_hand`; `context.ne_judgment`; `SMODS.add_card` (flag `ne_temporary`); `NE.Blind.add_phase`.
- **Shader:** motif `cosmos` · glyph `star` · `#FFB703 / #219EBC / #023047` · speed 0.8 · intensity 0.75
- **Animasi:** ruang tertutup biru dengan siluet raksasa; riak realitas.

### #109 Ultimate Madoka — `j_ne_ultimate_madoka`
Madoka Magica · Tag: `divine`, `rule` · $27
- **Lore:** Hukum yang memurnikan setiap keputusasaan sebelum menjadi kutukan.
- **Kemampuan:** Law of Cycles: ☠ tidak pernah memicu Penghakiman Neraka; setiap ☠ yang didapat juga memberi ✦ sebanyak itu; trait boss berbasis korupsi dihapus. Tulis Ulang Konsep (aktif, sekali per run): tetapkan 1 aturan permanen: Tangan +1 / Formation Cap +2 / boss maksimal 2 fase / limpahan 100%. ^^1.9 Mult.
- **Hook:** `NE.Currency` (hook Penghakiman Neraka); `context.ne_currency_changed`; `NE.Rules.push_permanent`.
- **Shader:** motif `radiance` · glyph `arrow` · `#FFC8DD / #FFFFFF / #BDE0FE` · speed 0.5 · intensity 0.8
- **Animasi:** sayap cahaya merah muda terbentang; panah cahaya berjatuhan lembut.

### #110 Arceus — `j_ne_arceus`
Pokémon · Tag: `create` · $28
- **Lore:** Yang membentuk alam semesta dengan seribu lengannya.
- **Kemampuan:** Di awal tiap ronde, ciptakan 1 consumable pilihan Anda (3 opsi: Tarot/Planet/Spectral). Judgment (aktif, 1x per ante): ciptakan 1 joker Demonic acak beredisi Negative. Plates: +^^0.02 Mult per suit dan per enhancement berbeda di Dek Utama. ^^2 Mult.
- **Hook:** `context.setting_blind` (UI pilih); `ne_active`; hitung `G.playing_cards`.
- **Shader:** motif `radiance` · glyph `wheel` · `#F5F3F4 / #D4AF37 / #2B2D42` · speed 0.5 · intensity 0.8
- **Animasi:** roda emas bersilang dengan lempeng-lempeng warna berputar mengelilinginya.

### #111 Chara — `j_ne_chara`
Undertale · Tag: `destroy`, `meta` · $28
- **Lore:** Tahu bahwa semua ini hanyalah sebuah permainan.
- **Kemampuan:** LOVE: +^^0.1 Mult per Boss dikalahkan (EXP). ERASE (aktif, sekali per run): hapus dunia; pilih: boss saat ini dihapus dari run (seketika kalah dan tidak muncul lagi), atau semua trait boss dihapus selama sisa ante. Setelah ERASE, ☠ tidak bisa turun di bawah 20 selama sisa run. ^^2.05 Mult.
- **Efek meta (ilusi):** saat Chara dijual, layar menampilkan pesan palsu "File save akan dihapus…" dengan hitung mundur, lalu berubah menjadi lelucon. **Tidak ada operasi file sama sekali.** Bisa dimatikan di config (`meta_effects = false`).
- **Hook:** `context.ne_encounter_cleared`; `ne_active`; `NE.Blind.defeat_encounter{banish=true}`; `context.selling_self` → overlay UI murni.
- **Shader:** motif `glitch` · glyph `heart` · `#FF0000 / #000000 / #FFFFFF` · speed 0.6 · intensity 0.8
- **Animasi:** layar retak lalu jatuh ke hitam; teks merah "=)" ber-glitch.

### #112 Zeus — `j_ne_zeus`
Mitologi Yunani · Tag: `blind`, `divine` · $28
- **Lore:** Raja Olympus, dan petirnya tidak pernah meleset.
- **Kemampuan:** Petir Olympus: tiap tangan, target blind saat ini dipangkatkan 0.95. Raja Para Dewa: semua joker Heavenly lain +^^0.05 Mult. ^^2.1 Mult.
- **Hook:** `context.ne_omen` → `NE.Blind.pow_target(0.95)`; `context.other_joker`.
- **Shader:** motif `lightning` · glyph `bolt` · `#FFD700 / #1E3A8A / #FFFFFF` · speed 1.2 · intensity 0.8
- **Animasi:** petir raksasa dari atas layar menyambar chip blind.

### #113 Odin — `j_ne_odin`
Mitologi Nordik · Tag: `map`, `rule` · $29
- **Lore:** Menukar satu mata dengan melihat segalanya.
- **Kemampuan:** Mata Odin: semua yang tersembunyi terungkap (kartu tertutup, trait/boss/node "?", peta 3 ante ke depan). Hugin & Munin: di awal ronde, lihat 3 kartu teratas tiap dek, buang atau pertahankan masing-masing. Gungnir: kartu skor pertama selalu dipicu ulang 1 kali dan memberi ^^1.05 di tiap pemicuan. ^^2.2 Mult.
- **Hook:** `NE.Reveal.all()`; `NE.Map.pregenerate(ante+3)`; `context.setting_blind` (UI); `context.repetition`; `context.individual`.
- **Shader:** motif `eye` · glyph `eye` · `#34495E / #BDC3C7 / #F1C40F` · speed 0.5 · intensity 0.8
- **Animasi:** satu mata bersinar; dua gagak terbang melintasi layar.

### #114 Amaterasu — `j_ne_amaterasu`
Mitologi Shinto · Tag: `divine`, `aura` · $29
- **Lore:** Matahari yang mengembalikan cahaya ke dunia.
- **Kemampuan:** +0.2 Aura. x(1 + ✦/10) Mult. Fajar (aktif, 1x per ronde): hapus semua debuff dari kartu dan joker, dan pulihkan 1 tangan. ^^2.3 Mult.
- **Hook:** `context.ne_ascension`; `context.joker_main`; `ne_active` → `SMODS.debuff_card(card, false)`, `ease_hands_played(1)`.
- **Shader:** motif `radiance` · glyph `sun` · `#FFB703 / #FB8500 / #FFFFFF` · speed 0.4 · intensity 0.85
- **Animasi:** cakram matahari terbit di latar (background reaktif), bloom hangat.

### #115 Chronos — `j_ne_chronos`
Mitologi Yunani · Tag: `time_stop`, `rewind` · $29
- **Lore:** Bukan penguasa waktu. Ia adalah waktu.
- **Kemampuan:** Semua biaya ⧗ menjadi 0 untuk semua joker Anda. Efek waktu Anda mengabaikan imunitas Chrono-Immune. Trait waktu boss tidak berlaku. ^^2.4 Mult.
- **Hook:** `NE.Currency.cost_modifier('time', 0)`; `NE.Chrono` mengecek `SMODS.find_card('j_ne_chronos')`; filter trait bertag `time`.
- **Shader:** motif `gears` · glyph `clock` · `#C9A227 / #1B263B / #E0E1DD` · speed 0.5 · intensity 0.85
- **Animasi:** mesin jam raksasa dengan cincin zodiak berputar di tengah layar.

### #116 Vishnu — `j_ne_vishnu`
Mitologi Hindu · Tag: `protect` · $30
- **Lore:** Sang pemelihara yang tidak membiarkan apa pun hilang.
- **Kemampuan:** Pemelihara: tidak ada yang bisa dihancurkan oleh blind, trait, atau Penghakiman Neraka; uang tidak bisa dikurangi oleh boss; level formasi tidak bisa turun. Avatar: tiap ante, Vishnu mengambil 1 dari 10 Avatar secara bergilir (mis. Matsya: +2 ukuran Tangan Utama; Narasimha: +^^0.1 melawan boss; Rama: kartu skor pertama x5 Mult; …). ^^2.5 Mult.
- **Hook:** hook `SMODS.destroy_cards` (sumber = blind/trait/reckoning → batal); hook `ease_dollars` (sumber boss); hook `level_up_hand` (amount < 0); `context.ante_change`.
- **Shader:** motif `radiance` · glyph `petal` · `#1E40AF / #FACC15 / #F0F9FF` · speed 0.4 · intensity 0.85
- **Animasi:** siluet biru bertangan empat; kelopak teratai mekar di sekeliling kartu.

### #117 Shiva — `j_ne_shiva`
Mitologi Hindu · Tag: `destroy` · $30
- **Lore:** Tarian kosmik yang menghancurkan agar dunia bisa lahir kembali.
- **Kemampuan:** Tandava: setiap kartu atau joker yang dihancurkan (oleh apa pun) memberi +^^0.01 Mult permanen. Mata Ketiga (aktif, sekali per run): hancurkan boss saat ini (semua fase), dan boss-boss berikutnya muncul tanpa imunitas selama sisa run. ^^2.6 Mult.
- **Hook:** `context.remove_playing_cards`, `context.joker_type_destroyed`; `ne_active`; flag `G.GAME.newera.rules.no_immunities`.
- **Shader:** motif `fire` · glyph `eye` · `#1D3557 / #E63946 / #F1FAEE` · speed 0.8 · intensity 0.85
- **Animasi:** mata ketiga terbuka memancarkan api; cincin api tarian kosmik mengelilingi layar.

### #118 Azathoth — `j_ne_azathoth`
Mitos Lovecraft · Tag: `rule`, `luck` · $30
- **Lore:** Seluruh realitas hanyalah mimpinya. Jangan bangunkan dia.
- **Kemampuan:** Sang Pemimpi: di awal tiap ronde, satu hukum dunia diacak (Mimpi), mis. rumus skor menjadi `Chips^Mult`, papan menjadi 6×4, semua blind 1 fase, atau trait boss berganti acak tiap tangan. Nilai rata-rata tiap Mimpi menguntungkan Anda. Eternal: tidak bisa dijual. Jika dihancurkan, run berakhir (game over). +0.3 Aura. ^^2.7 Mult.
- **Hook:** `context.setting_blind` → `NE.Rules.push_temp(dream, 'round')`; `NE.Board.resize`; `SMODS.set_scoring_calculation`; `context.joker_type_destroyed` (self) → game over.
- **Shader:** motif `eldritch` · glyph `void` · `#240046 / #FF006E / #3A86FF` · speed 0.9 · intensity 0.9
- **Animasi:** nebula kosmik kacau dengan tentakel di latar; tint warna berdenyut mengikuti "musik seruling".

### #119 Featherine Augustus Aurora — `j_ne_featherine`
Umineko · Tag: `rule` · $30
- **Lore:** Sang penulis cerita. Para karakter hanya bidak di papannya.
- **Kemampuan:** Sang Penulis (aktif, 10 ✦, 1x per ante): tulis hasil fase Penghakiman: skor tangan ini ditetapkan tepat sama dengan target fase/blind saat ini, atau tulis ulang 1 trait boss menjadi trait pilihan Anda dengan budget yang sama. Bidak: semua joker Unranked dan Demonic Anda mendapat efek ganda (angka x2; untuk `^X`: bagian di atas 1 dikali 2). +0.4 Aura. ^^2.8 Mult.
- **Hook:** `ne_active`; `context.ne_ascension` (override skor akhir); hook skala efek untuk rank ≤ Demonic.
- **Shader:** motif `ink` · glyph `feather` · `#6F2DBD / #F4D35E / #FFFFFF` · speed 0.5 · intensity 0.9
- **Animasi:** pena bulu emas menulis teks emas melintasi layar; halaman buku berbalik.

### #120 Tokimi — `j_ne_tokimi`
Tenchi Muyo · Tag: `rule`, `board` · $30
- **Lore:** Salah satu dari tiga dewi tertinggi, penguasa dimensi.
- **Kemampuan:** Dewi Dimensi: papan bertambah menjadi 5×4; baris ke-4 (Dimensi) memberi ^1.1 Mult per kartu yang dicetak di sana. Semua batas +2: slot joker, ukuran Tangan Utama, batas main, dan Formation Cap. ^^2.9 Mult.
- **Hook:** `add_to_deck`/`remove_from_deck` → `NE.Board.resize(5,4)`, `G.jokers:change_size(2)`, `G.hand:change_size(2)`, `SMODS.change_play_limit(2)`; `context.individual`.
- **Shader:** motif `cosmos` · glyph `wing` · `#E0FBFC / #98C1D9 / #3D5A80` · speed 0.5 · intensity 0.9
- **Animasi:** tiga sayap cahaya (Light Hawk Wings) terbentang; ruang terlipat seperti lipatan dimensi.

### #121 Kami Tenchi — `j_ne_kami_tenchi`
Tenchi Muyo · Tag: semua · $30
- **Lore:** Melampaui ketiga dewi. Joker terkuat di New Era.
- **Kemampuan:** Melampaui Para Dewi: `{3}1.2` Mult (pentasi), dihitung paling akhir setelah semua efek lain. Mengabaikan semua trait dan imunitas; kehadirannya membuat semua joker Heavenly Anda juga mengabaikan imunitas. Tidak memakai slot joker. Light Hawk Wings (masing-masing aktif 1x per ronde): Perisai: batalkan 1 aksi apa pun. Pedang: kalahkan fase blind saat ini. Penciptaan: ciptakan 1 kartu, consumable, atau joker apa pun (kecuali Heavenly).
- **Hook:** `context.ne_ascension` (urutan terakhir) → `hypermult = {3, 1.2}`; flag global `NE.Blind.immunities_ignored_for('heavenly')`; `ne_active` ×3; `config.extra_slots_used = -1` (didukung SMODS) agar tidak memakai slot.
- **Shader:** motif `radiance` · glyph `infinity` · `#FFFFFF / #FFD700 / #7DF9FF` · speed 0.4 · intensity 1.0
- **Animasi:** tiga Light Hawk Wings raksasa terbentang; layar putih keemasan; semua overlay lain berhenti sesaat.
