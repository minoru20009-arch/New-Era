# 02 — Joker Unranked (#1–#31)

Format tiap joker:
- **Key** memakai prefix mod (`j_ne_*`). **Tag** dipakai generator boss untuk counter (lihat 01 §7.3).
- **Kemampuan** adalah teks final yang akan masuk lokalisasi (angka = nilai awal balance).
- **Hook** = context SMODS / context New Era / API internal yang dibutuhkan (didefinisikan di 05-architecture).
- **Shader** = parameter uber-shader `ne_card`: `motif`, `glyph`, palet `primer / sekunder / aksen`, `speed`, `intensity` (lihat 05 §5).
- **Animasi** = animasi saat kemampuan memicu (overlay dari 05 §6).

Kerangka power Unranked: `+Mult`, `+Chips`, `xMult` (≈ x1.25–x4), retrigger, dan manipulasi aturan kecil. Tidak ada `^`.

---

### #1 Mr. Satan — `j_ne_mr_satan`
Dragon Ball · Tag: `copy` · $4
- **Lore:** Juara dunia yang selalu muncul tepat saat orang lain selesai bekerja.
- **Kemampuan:** Di akhir fase Joker, memicu ulang efek skor terakhir dari joker lain dengan kekuatan 30% (+Mult/+Chips: 30% nilainya; xMult X: x(1 + 0.3·(X−1))). Tidak menyalin `^`/`^^`. Juara Dunia: +$2 setiap Boss dikalahkan.
- **Hook:** optional feature `post_trigger`; `context.post_trigger` (catat `other_ret` terakhir); terapkan di `context.final_scoring_step`; `context.ne_encounter_cleared` (boss).
- **Shader:** motif `radiance` · glyph `fist` · `#F4C542 / #7A4B2A / #FFFFFF` · speed 0.5 · intensity 0.35
- **Animasi:** kilat kamera putih cepat + teks "JUARA!" + kartu bergoyang pamer.

### #2 Yamcha — `j_ne_yamcha`
Dragon Ball · Tag: `revive`, `scaling` · $4
- **Lore:** Kalah berkali-kali, tapi selalu kembali sedikit lebih kuat.
- **Kemampuan:** +4 Mult. Saat dihancurkan (bukan dijual), Yamcha kembali di akhir ronde ke slot joker kosong dengan +6 Mult permanen tambahan. Maks 3 kali per run.
- **Hook:** `remove_from_deck` + flag jual dari `context.selling_self`; data di `G.GAME.newera.graveyard`; kebangkitan di `mod.calculate` saat `context.end_of_round` via `SMODS.add_card` + pulihkan `ability`.
- **Shader:** motif `aura` · glyph `flame` · `#F28C28 / #2E5AAC / #FFFFFF` · speed 0.7 · intensity 0.4
- **Animasi:** kartu rebah dengan riak kawah (distorsi cincin); saat bangkit, kartu naik dengan cahaya oranye.

### #3 Krillin — `j_ne_krillin`
Dragon Ball · Tag: `destroy`, `board`, `create` · $4
- **Lore:** Manusia terkuat di Bumi dengan cakram yang memotong apa saja.
- **Kemampuan:** Destructo Disc (1x per ronde): kartu pertama yang ditempatkan di Baris Depan terbelah. Kartu asli dihancurkan dan diganti dua kartu bersuit sama dengan rank ⌊r/2⌋ dan ⌈r/2⌉ (min 2; J=11, Q=12, K=13, As=14). Kartu kedua mengisi petak kosong terdekat. Keduanya +15 Chips saat dicetak ronde ini.
- **Hook:** `context.ne_omen`; `NE.Board.first_placed(row='front')`; `SMODS.destroy_cards`; `SMODS.add_card{set='Base'}`; `NE.Board.place`.
- **Shader:** motif `slash` · glyph `disc` · `#F5E663 / #E08A1E / #FFFFFF` · speed 1.0 · intensity 0.45
- **Animasi:** cakram energi kuning (cincin SDF) melintas dan membelah kartu jadi dua.

### #4 Usopp — `j_ne_usopp`
One Piece · Tag: `create`, `scaling` · $4
- **Lore:** Kebohongan yang diulang cukup sering akhirnya menjadi kenyataan.
- **Kemampuan:** Saat blind dimulai, tambahkan 2 Kartu Palsu (rank & suit acak) ke Tangan Utama. +1 Mult permanen setiap Kartu Palsu dicetak.
- **Hook:** `context.setting_blind` → kartu dengan enhancement `m_ne_fake`; `context.individual` untuk menghitung.
- **Shader:** motif `smoke` · glyph `mask` · `#6B4F2A / #F2D7A0 / #3AA655` · speed 0.6 · intensity 0.35
- **Animasi:** kepulan asap kartun + teks "BOHONG!", Kartu Palsu memudar setelah dicetak.

### #5 Mumen Rider — `j_ne_mumen_rider`
One Punch Man · Tag: `scaling` · $4
- **Lore:** Tidak punya kekuatan, tidak pernah menyerah.
- **Kemampuan:** Justice Crash: setiap tangan yang skornya kurang dari 25% target blind memberi +3 Mult permanen. Tidak pernah reset.
- **Hook:** `context.ne_judgment` (`score` vs target aktif); `SMODS.scale_card`.
- **Shader:** motif `aura` · glyph `wheel` · `#2B2B2B / #D7263D / #FFFFFF` · speed 0.5 · intensity 0.3
- **Animasi:** roda sepeda berputar di kartu + teks "JUSTICE CRASH!".

### #6 Zenitsu Agatsuma — `j_ne_zenitsu`
Demon Slayer · Tag: `retrigger` · $5
- **Lore:** Hanya menguasai satu jurus, tapi jurus itu secepat kilat.
- **Kemampuan:** Thunderclap and Flash: kartu skor pertama dipicu ulang 2 kali dan memberi x1.5 Mult setiap pemicuan. Kartu skor lain tidak memberi Chips dasar.
- **Hook:** `context.repetition` (kartu pertama `scoring_hand`); `context.individual`; `context.main_scoring` (kartu lain: kembalikan chips negatif senilai chips dasar).
- **Shader:** motif `lightning` · glyph `bolt` · `#FFD400 / #FF8C00 / #FFFFFF` · speed 1.4 · intensity 0.5
- **Animasi:** garis kilat kuning melesat ke kartu pertama; kedip kuning singkat (dimatikan saat reduced motion).

### #7 Tanjiro Kamado — `j_ne_tanjiro`
Demon Slayer · Tag: `board` · $5
- **Lore:** Setiap gerakan mengalir ke gerakan berikutnya seperti air.
- **Kemampuan:** Water Breathing: tiap kartu skor yang bersebelahan (ortogonal) dengan kartu skor sebelumnya memberi Mult yang terus naik (+2, +4, +6, …). Aliran reset jika kartu berikutnya tidak bersebelahan.
- **Hook:** `context.individual`; `NE.Board.adjacent(a, b)`; state per tangan di `card.ability.extra`.
- **Shader:** motif `water` · glyph `wave` · `#1F7AE0 / #0B2545 / #E8F1FF` · speed 0.8 · intensity 0.45
- **Animasi:** gelombang air mengalir dari kartu ke kartu mengikuti rantai.

### #8 Nobara Kugisaki — `j_ne_nobara`
Jujutsu Kaisen · Tag: `board` · $5
- **Lore:** Satu paku pada boneka jerami, dan semua yang terhubung ikut merasakannya.
- **Kemampuan:** Resonance: kartu skor pertama menjadi boneka jerami. Setiap kartu lain ber-rank sama (di papan atau di Tangan Utama) beresonansi: +4 Mult dan +10 Chips.
- **Hook:** `context.individual` (kartu pertama); iterasi `G.play.cards` + `G.hand.cards`; return `extra` per kartu dengan `message_card`.
- **Shader:** motif `sigil` · glyph `hammer` · `#B5172E / #2A1B1B / #E7C8A0` · speed 0.6 · intensity 0.4
- **Animasi:** palu mengetuk paku; cincin merah memancar dari tiap kartu yang beresonansi.

### #9 Rock Lee — `j_ne_rock_lee`
Naruto · Tag: `scaling` · $5
- **Lore:** Kerja keras membuka gerbang yang tidak bisa dibuka bakat.
- **Kemampuan:** +1 Gerbang setiap blind dimulai. Aktif (gratis, 1x per ronde): buka 1 Gerbang tambahan. Gerbang 1–7: x(1 + 0.3·Gerbang) Mult. Saat Gerbang ke-8 terbuka: tangan berikutnya x15 Mult, lalu Rock Lee hancur.
- **Hook:** `context.setting_blind`; `ne_active` (frekuensi `round`); `context.joker_main`; `SMODS.destroy_cards` setelah tangan Gerbang 8.
- **Shader:** motif `aura` · glyph `flame` · `#2E8B57 / #F4E04D / #FFFFFF` · speed 0.9 · intensity 0.3→0.9 (state = Gerbang/8)
- **Animasi:** aura hijau makin besar tiap gerbang; Gerbang 8: aura merah meledak (shockwave).

### #10 Shikamaru Nara — `j_ne_shikamaru`
Naruto · Tag: `rule` · $5
- **Lore:** Terlalu malas untuk bertarung, terlalu cerdas untuk kalah.
- **Kemampuan:** Shadow Possession: di awal ronde, 2 kartu di Tangan Utama terikat bayangan. Selama masih di tangan, kartu terikat wajib ikut dimainkan. Kartu terikat memberi x1.5 Mult saat dicetak dan kebal debuff boss.
- **Hook:** `context.setting_blind` → stiker `ne_bound`; `NE.PlayRules` (validasi tombol Play); `context.individual`; `mod.set_debuff` → `"prevent_debuff"`.
- **Shader:** motif `void` · glyph `hand` · `#1B1B1B / #3C3C3C / #9BC53D` · speed 0.4 · intensity 0.4
- **Animasi:** sulur bayangan memanjang dari joker ke kartu terikat.

### #11 Kazuma Satou — `j_ne_kazuma`
Konosuba · Tag: `steal`, `luck` · $5
- **Lore:** Statistik payah, keberuntungan tak masuk akal.
- **Kemampuan:** Steal (aktif, 1x per kunjungan Toko): 1 in 2 peluang mengambil 1 kartu toko acak gratis; gagal → semua harga toko +$1. Steal (aktif, 1x per Boss): 1 in 3 peluang menonaktifkan 1 trait acak boss selama blind itu.
- **Hook:** `ne_active` (konteks toko & blind); `SMODS.pseudorandom_probability`; `NE.Blind.disable_trait`.
- **Shader:** motif `radiance` · glyph `hand` · `#3A7D44 / #E6D5B8 / #F4D35E` · speed 0.6 · intensity 0.35
- **Animasi:** tangan meraih + kilau; teks "STEAL!".

### #12 Senku Ishigami — `j_ne_senku`
Dr. Stone · Tag: `create` · $5
- **Lore:** Sepuluh miliar persen yakin sains bisa menggabungkan apa saja.
- **Kemampuan:** Sains (aktif, 1x per ronde): gabungkan 2 consumable yang dipegang. Tarot+Tarot → 1 Spectral acak. Planet+Planet → planet formasi yang paling sering dimainkan dan formasi itu langsung +1 level. Tarot+Planet → 2 Planet acak. Spectral+apa pun → 1 Spectral Negative acak (maks 1 per ante).
- **Hook:** `ne_active` (target 2 consumable); `SMODS.add_card`; `level_up_hand`.
- **Shader:** motif `sigil` · glyph `orb` · `#5CB85C / #2E2E2E / #D9F99D` · speed 0.7 · intensity 0.4
- **Animasi:** labu kimia menggelegak di atas kartu; teks "10 miliar persen!".

### #13 Edward Elric — `j_ne_edward_elric`
Fullmetal Alchemist · Tag: `destroy`, `transmute` · $5
- **Lore:** Untuk mendapatkan sesuatu, sesuatu yang setara harus dikorbankan.
- **Kemampuan:** Equivalent Exchange (aktif, 1x per ronde): pilih 2 kartu di tangan. Kartu pertama dihancurkan. Kartu kedua mendapat Chips permanen setara chips kartu pertama, serta salinan enhancement dan seal-nya.
- **Hook:** `ne_active` (target 2 kartu); `SMODS.destroy_cards`; perma bonus SMODS (`card.ability.perma_bonus`); `Card:set_ability`, `Card:set_seal`.
- **Shader:** motif `sigil` · glyph `circle` · `#C1121F / #FDF0D5 / #FFD700` · speed 0.6 · intensity 0.45
- **Animasi:** lingkaran transmutasi menyala di bawah kedua kartu + kilat biru alkimia.

### #14 Denji — `j_ne_denji`
Chainsaw Man · Tag: `destroy`, `revive`, `board` · $5
- **Lore:** Gergaji mesin, mimpi sederhana, dan satu kesempatan hidup lagi.
- **Kemampuan:** Chainsaw: setelah tiap tangan, 1 residu acak di papan dipotong (dihancurkan) dan Denji +12 Chips permanen. Pochita: saat Denji dihancurkan pertama kali dalam run, ia langsung kembali.
- **Hook:** `context.after`; `NE.Board.residues()`; `SMODS.destroy_cards`; `NE.Revive` (flag sekali per run).
- **Shader:** motif `slash` · glyph `saw` · `#F77F00 / #1D1D1D / #D62828` · speed 1.3 · intensity 0.5
- **Animasi:** gergaji berputar dengan percikan; guncangan kecil via `G.ROOM.jiggle`.

### #15 Power — `j_ne_power`
Chainsaw Man · Tag: `destroy` · $5
- **Lore:** Iblis darah yang menabung darah demi satu hantaman besar.
- **Kemampuan:** +1 Darah setiap kartu atau joker dihancurkan (maks 12). Aktif (gratis): habiskan semua Darah → tangan berikutnya x(1 + 0.4·Darah) Mult.
- **Hook:** `context.remove_playing_cards`, `context.joker_type_destroyed`; `ne_active`; `context.joker_main`.
- **Shader:** motif `aura` · glyph `hammer` · `#9D0208 / #F48C06 / #FFBA08` · speed 0.8 · intensity 0.3→0.8 (state = Darah/12)
- **Animasi:** palu darah menghantam; tint merah layar singkat.

### #16 Roronoa Zoro — `j_ne_zoro`
One Piece · Tag: `retrigger`, `board` · $6
- **Lore:** Tiga pedang, satu jalan.
- **Kemampuan:** Santoryu: kartu skor ketiga dipicu ulang 3 kali. Jika formasi utama berada di garis vertikal atau diagonal, semua kartu formasi utama dipicu ulang 1 kali.
- **Hook:** `context.repetition`; `NE.Formation.primary()` (orientasi garis).
- **Shader:** motif `slash` · glyph `katana3` · `#2D6A4F / #081C15 / #D8F3DC` · speed 1.0 · intensity 0.45
- **Animasi:** tiga tebasan hijau menyilang kartu.

### #17 Sanji — `j_ne_sanji`
One Piece · Tag: `scaling`, `board` · $6
- **Lore:** Kaki yang makin panas setiap tendangan beruntun.
- **Kemampuan:** Diable Jambe: +1 Panas setiap tangan yang menempatkan minimal 1 kartu di Baris Depan; reset ke 0 jika tidak. +3 Mult per Panas. Panas ≥ 4: kartu Baris Depan juga x1.25 Mult saat dicetak.
- **Hook:** `context.ne_omen` (cek penempatan); `context.joker_main`; `context.individual`.
- **Shader:** motif `fire` · glyph `flame` · `#FF6B35 / #2E2E2E / #FFD166` · speed 1.0 · intensity 0.3→0.8 (state = Panas)
- **Animasi:** jejak api kaki melengkung di Baris Depan.

### #18 Mikasa Ackerman — `j_ne_mikasa`
Attack on Titan · Tag: `protect` · $6
- **Lore:** Melindungi satu orang dengan segalanya.
- **Kemampuan:** Joker di kanan Mikasa tidak bisa dihancurkan, dicuri, atau di-debuff oleh boss. Setiap kali perlindungan ini mencegah sesuatu, Mikasa +x0.2 Mult permanen (mulai x1).
- **Hook:** `context.ne_boss_trait` (batalkan jika target = tetangga kanan); `context.check_eternal`; `mod.set_debuff`.
- **Shader:** motif `slash` · glyph `wing` · `#B23A48 / #2F3E46 / #CAD2C5` · speed 0.7 · intensity 0.4
- **Animasi:** syal merah melilit joker yang dilindungi + kilat perisai.

### #19 Levi Ackerman — `j_ne_levi`
Attack on Titan · Tag: `board`, `retrigger` · $6
- **Lore:** Satu putaran, satu baris, tanpa sisa.
- **Kemampuan:** Spinning Slash: jika sebuah baris papan penuh (5 kartu) saat dicetak, semua kartu di baris itu dipicu ulang 1 kali dan masing-masing +3 Mult.
- **Hook:** `context.repetition`; `NE.Board.row_full(row)`; `context.individual`.
- **Shader:** motif `slash` · glyph `sword` · `#3A506B / #0B132B / #5BC0BE` · speed 1.5 · intensity 0.45
- **Animasi:** pusaran bilah menyapu sepanjang baris.

### #20 Katsuki Bakugo — `j_ne_bakugo`
My Hero Academia · Tag: `scaling` · $6
- **Lore:** Makin lama bertarung, makin besar ledakannya.
- **Kemampuan:** +3 Mult per tangan yang sudah dimainkan di ronde ini. Howitzer Impact: tangan terakhir ronde (tidak ada sisa tangan setelahnya) x3 Mult.
- **Hook:** `context.joker_main` (`G.GAME.current_round.hands_played`, `hands_left`).
- **Shader:** motif `fire` · glyph `burst` · `#FF7F11 / #2B2D42 / #FFE066` · speed 1.2 · intensity 0.5
- **Animasi:** ledakan beruntun (shockwave kecil); Howitzer: ledakan spiral besar.

### #21 Shoto Todoroki — `j_ne_todoroki`
My Hero Academia · Tag: `board`, `protect` · $6
- **Lore:** Setengah api, setengah es, bergantian sesuai kebutuhan.
- **Kemampuan:** Bergantian tiap tangan. Panas: x2 Mult. Dingin: +80 Chips dan semua residu Beku (tidak bisa dimakan atau dihancurkan boss sampai tangan berikutnya).
- **Hook:** `context.joker_main`; `context.ne_judgment` → stiker `ne_frozen`; toggle state di `ability.extra`.
- **Shader:** motif `frost` (split api/es) · glyph `flame` · `#E63946 / #A8DADC / #F1FAEE` · speed 0.6 · intensity 0.45
- **Animasi:** kartu terbelah dua warna; semburan api atau es sesuai mode.

### #22 Killua Zoldyck — `j_ne_killua`
Hunter x Hunter · Tag: `rule` · $6
- **Lore:** Bergerak sebelum lawan sempat berpikir.
- **Kemampuan:** Godspeed: bertindak di fase Pertanda, sebelum semua joker lain: +6 Mult per joker lain yang Anda miliki (masuk paling awal sehingga ikut dikalikan xMult joker lain).
- **Hook:** `context.ne_omen` → efek skor diantrikan lalu diterapkan tepat setelah nilai dasar formasi dipasang (awal `initial_scoring_step`).
- **Shader:** motif `lightning` · glyph `bolt` · `#6EC1E4 / #FFFFFF / #1B4965` · speed 1.8 · intensity 0.45
- **Animasi:** bayangan-bayangan biru (afterimage) + kilat biru.

### #23 Kurapika — `j_ne_kurapika`
Hunter x Hunter · Tag: `retrigger`, `time` · $6
- **Lore:** Mata merah yang memberi segalanya, dengan harga yang terus berjalan.
- **Kemampuan:** Emperor Time (aktif, toggle): selama aktif, semua joker Unranked Anda dipicu ulang 1 kali, dan setiap tangan menghabiskan 1 ⧗. Jika ⧗ habis, Emperor Time mati dan Kurapika di-debuff 1 ronde.
- **Hook:** optional feature `retrigger_joker`; `context.retrigger_joker_check`; `ne_active` (toggle); `NE.Currency.spend('time', 1)`.
- **Shader:** motif `eye` · glyph `chain` · `#C1121F / #1D3557 / #F1FAEE` · speed 0.8 · intensity 0.5
- **Animasi:** mata merah menyala + rantai melingkari joker yang dipicu ulang.

### #24 Hisoka — `j_ne_hisoka`
Hunter x Hunter · Tag: `board`, `retrigger` · $6
- **Lore:** Elastis seperti karet, lengket seperti permen karet.
- **Kemampuan:** Bungee Gum: di awal ronde, 2 kartu acak di Tangan Utama terikat karet. Jika salah satunya ditempatkan di papan, yang lain ikut tertarik ke petak kosong terdekat (tidak dihitung batas main). Keduanya dipicu ulang 1 kali saat dicetak.
- **Hook:** `context.setting_blind` → stiker `ne_bound` (varian karet); `context.ne_board_changed` (auto-place); `context.repetition`.
- **Shader:** motif `aura` · glyph `star` · `#FF4D8D / #6A0572 / #FDE2F3` · speed 0.7 · intensity 0.4
- **Animasi:** pita karet merah muda merentang lalu menarik kartu.

### #25 Spike Spiegel — `j_ne_spike`
Cowboy Bebop · Tag: `luck` · $6
- **Lore:** Semuanya taruhan. Yang penting tetap santai.
- **Kemampuan:** Setiap tangan: 1 in 3 → x4 Mult; 1 in 6 → x0.5 Mult; selain itu +10 Mult. Akhir ronde: 1 in 4 → +$8.
- **Hook:** `context.joker_main`; `SMODS.pseudorandom_probability`; `context.end_of_round`.
- **Shader:** motif `smoke` · glyph `bullet` · `#1D3557 / #E9C46A / #F4A261` · speed 0.5 · intensity 0.35
- **Animasi:** kilatan moncong + asap rokok + teks "Bang."

### #26 Link — `j_ne_link`
The Legend of Zelda · Tag: `revive` · $7
- **Lore:** Selama masih ada hati, petualangan belum berakhir.
- **Kemampuan:** Heart Containers: mulai dengan 3 hati (maks 5). Saat Anda akan kalah (game over), habiskan 1 hati untuk bertahan; ronde berakhir tanpa hadiah blind. +1 hati setiap Boss dikalahkan.
- **Hook:** `context.end_of_round` + `game_over` → return `saved`; `context.ne_encounter_cleared` (boss).
- **Shader:** motif `radiance` · glyph `tri` · `#2A9D8F / #E9C46A / #FFFFFF` · speed 0.5 · intensity 0.4
- **Animasi:** wadah hati retak + peri berkilau terbang di sekitar kartu.

### #27 Kirby — `j_ne_kirby`
Kirby · Tag: `copy`, `destroy` · $7
- **Lore:** Apa pun yang ditelan, jadi kemampuannya.
- **Kemampuan:** Copy Ability (aktif, 1x per ante): hirup joker di kiri Kirby (joker itu dihancurkan). Kirby menyalin kemampuannya secara permanen: Unranked penuh, Demonic dengan angka 50%. Tidak bisa menghirup Heavenly. Hanya 1 kemampuan tersimpan; menghirup lagi menggantinya.
- **Hook:** `ne_active` (target: joker kiri); `NE.AbilityProxy` (simpan key center + snapshot `ability`, delegasikan `calculate`).
- **Shader:** motif `void` · glyph `star` · `#FF8FAB / #FFC2D1 / #FB6F92` · speed 0.9 · intensity 0.45
- **Animasi:** pusaran isapan (distorsi menuju Kirby), joker target tersedot.

### #28 Sonic — `j_ne_sonic`
Sonic the Hedgehog · Tag: `time` · $7
- **Lore:** Terlalu cepat untuk menunggu.
- **Kemampuan:** x(1 + 0.4·sisa tangan) Mult. Jika blind dikalahkan dengan tangan pertama: +$4 dan ⧗+1.
- **Hook:** `context.joker_main` (`hands_left`); `context.ne_encounter_cleared`.
- **Shader:** motif `lightning` · glyph `ring` · `#1F4E9C / #F5C518 / #FFFFFF` · speed 2.0 · intensity 0.45
- **Animasi:** garis kecepatan biru melintasi layar + bunyi cincin.

### #29 Pac-Man — `j_ne_pacman`
Pac-Man · Tag: `destroy`, `board`, `shadow` · $7
- **Lore:** Lapar tanpa akhir, dan hantu adalah hidangan penutup.
- **Kemampuan:** Setelah tiap tangan, Pac-Man memakan hingga 3 residu di Baris Tengah (kiri→kanan). Tiap kartu dimakan: dihancurkan, +2 Mult permanen (Kartu Iblis: +6 Mult).
- **Hook:** `context.after`; `NE.Board.residues{row='middle'}`; `SMODS.destroy_cards`; `SMODS.scale_card`.
- **Shader:** motif `glitch` (retro) · glyph `chomp` · `#FFE600 / #000000 / #2121DE` · speed 1.0 · intensity 0.35
- **Animasi:** bentuk bulat bermulut bergerak di sepanjang baris memakan kartu.

### #30 Mario — `j_ne_mario`
Super Mario · Tag: `consumable` · $7
- **Lore:** Satu jamur, satu bunga, satu bintang, dan semuanya jadi lebih mudah.
- **Kemampuan:** Saat memakai consumable, Mario mendapat power-up untuk ronde ini: Tarot → Super (+12 Mult), Planet → Fire Flower (x1.5 Mult), Spectral → Super Star (kartu Anda kebal debuff, x2 Mult). Maks 3 power-up bertumpuk.
- **Hook:** `context.using_consumeable`; `context.joker_main`; `mod.set_debuff`; reset di `context.end_of_round`.
- **Shader:** motif `radiance` · glyph `star` · `#E52521 / #049CD8 / #FBD000` · speed 0.8 · intensity 0.4
- **Animasi:** kartu membesar sesaat (efek grow) + bunyi koin.

### #31 Icarus — `j_ne_icarus`
Mitologi Yunani · Tag: `scaling`, `luck` · $7
- **Lore:** Terbang makin tinggi sampai matahari mengambil sayapnya.
- **Kemampuan:** x2 Mult, +x0.5 per Ketinggian (+1 Ketinggian setiap akhir ronde). Di akhir tiap ronde, peluang 1 in (10 − Ketinggian) (min 1 in 2) Icarus terbakar dan hancur. Aktif (gratis): turun, Ketinggian kembali ke 0.
- **Hook:** `context.end_of_round`; `context.joker_main`; `ne_active`; `SMODS.pseudorandom_probability`.
- **Shader:** motif `radiance` · glyph `wing` · `#F9C74F / #F94144 / #FFFFFF` · speed 0.7 · intensity 0.3→0.9 (state = Ketinggian/8)
- **Animasi:** sayap bulu makin menyala; saat hancur, bulu terbakar berjatuhan dan silau matahari.
