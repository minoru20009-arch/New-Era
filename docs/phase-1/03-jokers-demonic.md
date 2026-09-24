# 03 — Joker Demonic (#32–#91)

Format sama dengan 02. Kerangka power Demonic: `xMult` besar (x2–x8), `^Mult` (dari ^1.02 per tumpukan sampai ^2), manipulasi aturan kuat, dan **kontrak**: biaya ☠ Corruption, penghancuran, atau kehilangan kekuatan. Joker Demonic mendapat bonus dari ambang ☠ (01 §4).

---

### #32 Tatsumaki — `j_ne_tatsumaki`
One Punch Man · Tag: `board` · $8
- **Lore:** Seluruh medan perang tunduk pada kehendak psikisnya.
- **Kemampuan:** Telekinesis: residu tidak terkunci; semua kartu papan bebas dipindah sebelum menekan Play. Formasi yang memakai kartu yang dipindah di tangan ini x2 Mult. Tarikan Psikis (aktif, 1x per ronde): lihat 5 kartu teratas Dek Utama dan ambil 1 ke tangan.
- **Hook:** `NE.Board.set_residue_locked(false)`; `context.ne_chain`/`joker_main` (cek `card.ne_moved_this_hand`); `ne_active`.
- **Shader:** motif `aura` · glyph `spiral` · `#3BB273 / #0B3D2E / #B7F5C9` · speed 0.8 · intensity 0.5
- **Animasi:** kartu papan melayang dengan aura hijau saat dipindah.

### #33 Silver Fang — `j_ne_silver_fang`
One Punch Man · Tag: `nullify`, `protect` · $8
- **Lore:** Arus air yang mengalirkan serangan menjauh dari sasarannya.
- **Kemampuan:** Water Stream Rock Smashing Fist: hingga 3 kali per ronde, trait boss yang menargetkan kartu atau joker Anda dialihkan ke Silver Fang dan dibatalkan. Setiap pengalihan: x1.5 Mult untuk sisa ante (bertumpuk).
- **Hook:** `context.ne_boss_trait` → `ne_cancel`; counter per ronde.
- **Shader:** motif `water` · glyph `fist` · `#D9D9D9 / #4A90A4 / #FFFFFF` · speed 1.0 · intensity 0.5
- **Animasi:** kepalan tangan berputar mengalir seperti arus air.

### #34 Garou — `j_ne_garou`
One Punch Man · Tag: `scaling`, `hyper` · $8
- **Lore:** Setiap pahlawan yang ia kalahkan membuatnya makin mengerikan.
- **Kemampuan:** Hero Hunter: ^1.02 Mult per Boss dikalahkan dan ^1.01 per Elit dikalahkan (dikalikan, permanen; mulai ^1).
- **Hook:** `context.ne_encounter_cleared` (jenis node); `context.joker_main` → `emult`.
- **Shader:** motif `aura` · glyph `mask` · `#6D597A / #1B1B1E / #E56B6F` · speed 0.9 · intensity 0.3→0.9 (state = jumlah boss)
- **Animasi:** aura monster ungu + tinju menghantam.

### #35 Boros — `j_ne_boros`
One Punch Man · Tag: `hyper` · $8
- **Lore:** Membakar seluruh dirinya demi satu serangan terakhir.
- **Kemampuan:** x3 Mult. Meteoric Burst (aktif, gratis): tangan berikutnya ^1.5 Mult dan x10 Chips; setelah tangan itu Boros hancur.
- **Hook:** `ne_active`; `context.joker_main`; `SMODS.destroy_cards` di `context.after`.
- **Shader:** motif `fire` · glyph `eye` · `#4CC9F0 / #3A0CA3 / #F72585` · speed 1.2 · intensity 0.55
- **Animasi:** aura api biru meledak + sinar besar melintasi layar (overlay `beam`).

### #36 Kakashi Hatake — `j_ne_kakashi`
Naruto · Tag: `copy` · $8
- **Lore:** Ninja seribu jurus, semuanya pinjaman.
- **Kemampuan:** Sharingan: menyalin kemampuan joker Unranked atau Demonic di kanannya dengan kekuatan 75% (angka x0.75; untuk `^X`: bagian di atas 1 dikali 0.75). Kamui (aktif, 2 ⧗, 1x per ronde): kirim 1 kartu papan atau 1 joker ke Dimensi Kamui (slot simpan, tidak dihitung). Bisa ditarik kembali kapan saja.
- **Hook:** `SMODS.blueprint_effect` + skala angka; `ne_active`; area tersembunyi `G.ne_kamui` (CardArea, ikut save).
- **Shader:** motif `eye` · glyph `tomoe` · `#B00020 / #111111 / #CCCCCC` · speed 0.8 · intensity 0.5
- **Animasi:** tomoe berputar; Kamui: pusaran distorsi menelan target.

### #37 Pain — `j_ne_pain`
Naruto · Tag: `nullify`, `blind` · $9
- **Lore:** Dewa yang mendorong dunia menjauh, lalu menariknya menjadi satu.
- **Kemampuan:** Shinra Tensei: trait boss pertama yang memicu di tiap ronde dibatalkan. Chibaku Tensei (aktif, ☠+15, 1x per boss): fase boss berikutnya dilewati (dianggap kalah; hadiahnya tetap).
- **Hook:** `context.ne_boss_trait` → `ne_cancel`; `NE.Blind.skip_phase()`.
- **Shader:** motif `shockwave` · glyph `spiral` · `#8E7DBE / #2D2A32 / #F0E6EF` · speed 0.7 · intensity 0.55
- **Animasi:** gelombang tolak radial (distorsi keluar); Chibaku: bola batu memadat di tengah layar.

### #38 Itachi Uchiha — `j_ne_itachi`
Naruto · Tag: `nullify`, `blind` · $9
- **Lore:** Menjebak lawan dalam lingkaran takdir yang sama.
- **Kemampuan:** Izanami (aktif, ☠+15, 1x per boss): selama blind ini setiap trait boss hanya bisa memicu 1 kali; tiap kali sebuah trait terhalang, tangan itu x2 Mult. Tsukuyomi (pasif): pada 2 tangan pertama tiap boss, kartu Anda kebal debuff boss.
- **Hook:** `ne_active`; `context.ne_boss_trait` (hitung pemicuan); `mod.set_debuff`.
- **Shader:** motif `eye` · glyph `tomoe` · `#7B0D1E / #000000 / #E0E0E0` · speed 0.6 · intensity 0.55
- **Animasi:** gagak beterbangan + overlay mata Mangekyo.

### #39 Obito Uchiha — `j_ne_obito`
Naruto · Tag: `board`, `protect` · $9
- **Lore:** Ada di sana, tapi tidak bisa disentuh.
- **Kemampuan:** Kamui (aktif, gratis): fase-kan 1 kartu papan (maks 3 kartu terfase). Kartu terfase tidak bisa di-debuff, dihancurkan, atau dimakan, tetap tinggal di papan walau menjadi bagian formasi, dan memberi x1.5 Mult saat dicetak.
- **Hook:** `ne_active` (target kartu papan) → stiker `ne_phased`; `NE.Board.spend_rules`; `context.individual`.
- **Shader:** motif `void` · glyph `spiral` · `#F28F3B / #2B2D42 / #8D99AE` · speed 0.9 · intensity 0.5
- **Animasi:** pusaran distorsi di sekitar kartu yang difase; kartu jadi semi-transparan.

### #40 Madara Uchiha — `j_ne_madara`
Naruto · Tag: `nullify`, `blind` · $9
- **Lore:** Mimpi tanpa akhir untuk seluruh dunia.
- **Kemampuan:** x3 Mult. Infinite Tsukuyomi (aktif, ☠+25, 1x per ante): selama sisa ronde, semua trait blind nonaktif dan kartu di Tangan Utama ikut dicetak seolah berada di Baris Tengah.
- **Hook:** `ne_active`; `NE.Blind.suspend_traits(scope='round')`; `SMODS.get_card_areas` (tambahkan `G.hand` sebagai area skor sementara).
- **Shader:** motif `eye` · glyph `moon` · `#8B0000 / #1A1A2E / #FF6B6B` · speed 0.5 · intensity 0.6
- **Animasi:** bulan merah besar muncul di latar; layar bernuansa merah.

### #41 Naruto Uzumaki (Baryon Mode) — `j_ne_naruto_baryon`
Naruto · Tag: `hyper`, `blind` · $9
- **Lore:** Membakar sisa umurnya dan umur musuh sekaligus.
- **Kemampuan:** Mode Baryon (aktif, toggle): ^1.2 Mult; setiap tangan membakar 1 Umur (mulai 12, tidak pulih) dan menurunkan target blind 5%. Umur 0 → Naruto dihancurkan.
- **Hook:** `ne_active` (toggle); `context.joker_main` → `emult`; `NE.Blind.scale_target(0.95)`; `context.after`.
- **Shader:** motif `aura` · glyph `flame` · `#FF6D00 / #FF1744 / #FFD180` · speed 1.1 · intensity 0.6
- **Animasi:** gelembung energi merah-oranye; jumlah gelembung = sisa Umur.

### #42 Sasuke Uchiha — `j_ne_sasuke`
Naruto · Tag: `board`, `rule` · $9
- **Lore:** Posisi apa pun bisa ditukar dalam sekejap mata.
- **Kemampuan:** x2.5 Mult. Amenotejikara (aktif, gratis, 2x per ronde): tukar posisi dua objek secara instan (kartu papan ↔ kartu papan, kartu papan ↔ kartu tangan, atau joker ↔ joker). Joker yang ditukar dipicu ulang 1 kali di tangan berikutnya.
- **Hook:** `ne_active` (target 2 objek); `NE.Board.swap`, `CardArea` swap untuk joker; `context.retrigger_joker_check`.
- **Shader:** motif `eye` · glyph `bolt` · `#5E3C99 / #1B1B3A / #B39DDB` · speed 1.0 · intensity 0.5
- **Animasi:** denyut ungu; kedua objek berkedip lalu bertukar tempat.

### #43 Ichigo Kurosaki — `j_ne_ichigo`
Bleach · Tag: `hyper` · $9
- **Lore:** Satu tebasan terakhir dengan menukar seluruh kekuatannya.
- **Kemampuan:** Getsuga Tensho: x3 Mult; kartu Baris Depan memberi x1.2 Mult saat dicetak. Final Getsuga Tensho (aktif, 1x per run): tangan ini ^2 Mult, lalu Ichigo kehilangan kekuatan (x1, tanpa efek) selama 2 ante.
- **Hook:** `context.joker_main`; `context.individual`; `ne_active`; state `powerless_until_ante`.
- **Shader:** motif `slash` · glyph `crescent` · `#111111 / #C1121F / #F8F9FA` · speed 1.0 · intensity 0.55
- **Animasi:** gelombang bulan sabit hitam-merah menyapu seluruh layar.

### #44 Kenpachi Zaraki — `j_ne_kenpachi`
Bleach · Tag: `hyper` · $10
- **Lore:** Sengaja menahan diri, sampai pertarungan menjadi menyenangkan.
- **Kemampuan:** +15 Mult. Jika skor ronde < 50% target setelah setengah tangan terpakai: lepas penutup mata → ^1.25 Mult sampai akhir ronde. Melawan Boss dengan ≥ 2 fase: ^1.4 Mult sejak awal.
- **Hook:** `context.joker_main`; `NE.Blind.phase_count()`; progres skor dari `G.GAME.chips`.
- **Shader:** motif `aura` · glyph `bell` · `#F2E94E / #2D2D2D / #FFFFFF` · speed 0.9 · intensity 0.4→0.9
- **Animasi:** reiatsu kuning berbentuk tengkorak meledak; penutup mata terlepas.

### #45 Byakuya Kuchiki — `j_ne_byakuya`
Bleach · Tag: `board` · $10
- **Lore:** Seribu kelopak bunga yang masing-masing adalah bilah.
- **Kemampuan:** Senbonzakura Kageyoshi: setiap kartu di papan, termasuk residu yang tidak dicetak, memberi x1.12 Mult.
- **Hook:** `context.joker_main` (iterasi `G.play.cards`, masing-masing `message_card`).
- **Shader:** motif `petals` · glyph `petal` · `#FF9EBB / #FFFFFF / #8E3B46` · speed 1.0 · intensity 0.5
- **Animasi:** badai kelopak merah muda menyapu papan.

### #46 Genryusai Yamamoto — `j_ne_yamamoto`
Bleach · Tag: `destroy`, `hyper` · $10
- **Lore:** Api tertua yang mengubah segalanya menjadi abu.
- **Kemampuan:** +4 Mult per kartu yang pernah dihancurkan dalam run. Zanka no Tachi (aktif, 1x per ante): bakar semua kartu di papan dan di Tangan Utama (dihancurkan permanen). Untuk tiap kartu terbakar: ^1.03 Mult selama sisa ante.
- **Hook:** penghitung `G.GAME.newera.stats.cards_destroyed`; `ne_active`; `SMODS.destroy_cards`; `context.joker_main` → `emult`.
- **Shader:** motif `fire` · glyph `flame` · `#FF4800 / #370617 / #FFBA08` · speed 1.1 · intensity 0.6
- **Animasi:** api melahap layar (distorsi panas + tint oranye).

### #47 Yuji Itadori — `j_ne_yuji`
Jujutsu Kaisen · Tag: `luck`, `hyper` · $10
- **Lore:** Pukulan hitam yang datang saat ia paling fokus.
- **Kemampuan:** x2 Mult. Black Flash: tiap kartu skor punya peluang 1 in 8 memicu ^1.1 Mult. Setelah Black Flash pertama di ronde ini, peluangnya 1 in 4 sampai akhir ronde.
- **Hook:** `context.individual` → `emult`; `SMODS.pseudorandom_probability`; flag ronde.
- **Shader:** motif `lightning` · glyph `burst` · `#0D0D0D / #D00000 / #FFFFFF` · speed 1.3 · intensity 0.55
- **Animasi:** kilat hitam + inversi warna layar sesaat.

### #48 Megumi / Mahoraga — `j_ne_mahoraga`
Jujutsu Kaisen · Tag: `adapt`, `nullify` · $10
- **Lore:** Setiap serangan hanya berhasil sekali.
- **Kemampuan:** Adaptasi: setelah sebuah trait boss memicu sekali, trait itu tidak berlaku lagi selama sisa run. Maks 1 adaptasi per blind. x1 Mult, +x0.5 per adaptasi.
- **Hook:** `context.ne_boss_trait` (setelah pemicuan pertama); daftar di `G.GAME.newera.adapted_traits`; generator boss mengecualikan trait yang sudah diadaptasi.
- **Shader:** motif `sigil` · glyph `wheel` · `#E0E0E0 / #3D3D3D / #FFD700` · speed 0.4 · intensity 0.5
- **Animasi:** roda dharma di atas kartu berputar 1/8 putaran setiap adaptasi.

### #49 Toji Fushiguro — `j_ne_toji`
Jujutsu Kaisen · Tag: `rule` · $10
- **Lore:** Tanpa energi kutukan sama sekali, sehingga aturan dunia tidak menyentuhnya.
- **Kemampuan:** Heavenly Restriction: x5 Mult yang tidak pernah bisa dikurangi atau dinonaktifkan (mengabaikan semua trait dan imunitas, termasuk Peredam). Tidak bisa disalin atau dipicu ulang. Tidak punya kemampuan aktif.
- **Hook:** flag `ne_unaffected`; dikecualikan dari `blueprint_effect` dan `retrigger_joker_check`; `NE.Blind` melewati Toji saat menerapkan trait.
- **Shader:** motif `slash` · glyph `sword` · `#2B2D42 / #8D99AE / #EDF2F4` · speed 0.3 · intensity 0.15
- **Animasi:** hampir tanpa efek: satu garis tebasan tipis dan hening (penanda tanpa energi kutukan).

### #50 Yuta Okkotsu — `j_ne_yuta`
Jujutsu Kaisen · Tag: `copy`, `corrupt` · $10
- **Lore:** Kutukan Rika menyalin segalanya, dengan harga yang ikut menempel.
- **Kemampuan:** Rika: menyalin kemampuan joker Demonic di kiri Yuta dengan kekuatan penuh; setiap tangan ☠+2. Jika tidak ada joker Demonic di kiri: x3 Mult.
- **Hook:** `SMODS.blueprint_effect` (kiri); `context.after` → `corruption`.
- **Shader:** motif `eldritch` · glyph `ring` · `#1B263B / #E0E1DD / #6F1D1B` · speed 0.6 · intensity 0.55
- **Animasi:** bayangan tangan raksasa Rika muncul di belakang kartu.

### #51 Muzan Kibutsuji — `j_ne_muzan`
Demon Slayer · Tag: `corrupt`, `shadow` · $11
- **Lore:** Darahnya mengubah manusia menjadi iblis.
- **Kemampuan:** Di akhir tiap ronde, 2 kartu acak di Dek Utama menjadi Kartu Iblis dan pindah ke Dek Bayangan. x1 Mult, +x0.2 per Kartu Iblis di Dek Bayangan.
- **Hook:** `context.end_of_round`; `NE.Shadow.corrupt(card)`; `context.joker_main`.
- **Shader:** motif `decay` · glyph `petal` · `#7A0019 / #0B0B0B / #3F88C5` · speed 0.6 · intensity 0.55
- **Animasi:** urat darah menjalar di kartu yang diubah.

### #52 Kokushibo — `j_ne_kokushibo`
Demon Slayer · Tag: `board`, `retrigger` · $11
- **Lore:** Setiap tebasan melahirkan bilah bulan yang lebih kecil.
- **Kemampuan:** Moon Breathing: tiap kartu skor memicu ulang 1 kali kartu skor yang bersebelahan diagonal dengannya (maks 1 ulang tambahan per kartu). Formasi pada garis diagonal: x2.5 Mult.
- **Hook:** `context.repetition`; `NE.Board.diagonal_neighbors`; `NE.Formation.primary()`.
- **Shader:** motif `slash` · glyph `crescent` · `#5A189A / #10002B / #E0AAFF` · speed 1.1 · intensity 0.55
- **Animasi:** bilah bulan sabit ungu berhamburan di papan.

### #53 Yoriichi Tsugikuni — `j_ne_yoriichi`
Demon Slayer · Tag: `divine` · $11
- **Lore:** Nafas matahari yang lahir untuk mengakhiri iblis.
- **Kemampuan:** x5 Mult. Setiap Kartu Iblis di papan dimurnikan (kembali ke Dek Utama sebagai kartu biasa) dan memberi ✦+1. Melawan boss arketipe Archfiend, atau jika Muzan ada di joker Anda: ^1.2 Mult, dan efek Muzan dibelah dua.
- **Hook:** `context.after`; `NE.Shadow.purify(card)`; `NE.Blind.archetype()`; `SMODS.find_card('j_ne_muzan')`.
- **Shader:** motif `fire` · glyph `sun` · `#FF7B00 / #9D0208 / #FFEA00` · speed 0.9 · intensity 0.6
- **Animasi:** tarian api matahari melingkar di sekitar kartu.

### #54 All Might — `j_ne_all_might`
My Hero Academia · Tag: `hyper` · $11
- **Lore:** Simbol perdamaian yang mempertaruhkan segalanya dalam satu pukulan.
- **Kemampuan:** x3 Mult. United States of Smash (aktif, 1x per ante): tangan ini ^1.3 Mult; setelah itu All Might kehabisan tenaga (x1) sampai ante berikutnya.
- **Hook:** `ne_active`; `context.joker_main`; state `drained_until_ante`.
- **Shader:** motif `aura` · glyph `fist` · `#1D4ED8 / #DC2626 / #FACC15` · speed 0.8 · intensity 0.6
- **Animasi:** pukulan raksasa → gelombang kejut + distorsi angin se-layar.

### #55 Izuku Midoriya — `j_ne_izuku`
My Hero Academia · Tag: `scaling` · $11
- **Lore:** Mewarisi kekuatan setiap pendahulunya.
- **Kemampuan:** One For All: setiap kali joker lain dijual atau dihancurkan, Izuku mewarisi 1 Quirk: +x0.6 Mult permanen (maks 9). Dengan 9 Quirk: tambahan ^1.15 Mult.
- **Hook:** `context.selling_card`, `context.joker_type_destroyed`; `context.joker_main`.
- **Shader:** motif `lightning` · glyph `bolt` · `#16A34A / #0F172A / #A7F3D0` · speed 1.2 · intensity 0.3→0.8 (state = Quirk/9)
- **Animasi:** percikan kilat hijau di sekeliling kartu (Full Cowl).

### #56 All For One — `j_ne_all_for_one`
My Hero Academia · Tag: `steal` · $11
- **Lore:** Mengambil kekuatan orang lain dan menyimpannya untuk dirinya.
- **Kemampuan:** All For One (aktif, ☠+10, 1x per ante): curi kemampuan joker Unranked/Demonic lain. Joker itu menjadi "Tanpa Quirk" (tidak punya efek, permanen). AFO menyimpan hingga 3 kemampuan curian dan memicu semuanya dengan kekuatan penuh.
- **Hook:** `ne_active` (target joker); `NE.AbilityProxy` (multi-slot); flag `ne_quirkless` pada target.
- **Shader:** motif `eldritch` · glyph `mask` · `#0B0B0B / #5B0E2D / #C9ADA7` · speed 0.6 · intensity 0.6
- **Animasi:** sulur hitam menjulur dan mencabut orb cahaya dari joker target.

### #57 Tomura Shigaraki — `j_ne_shigaraki`
My Hero Academia · Tag: `destroy`, `board`, `blind` · $12
- **Lore:** Sentuhannya membusukkan, lalu busuknya menyebar.
- **Kemampuan:** Decay: kartu skor pertama tiap tangan mulai membusuk. Setiap tangan, pembusukan menyebar ke semua kartu yang bersebelahan dengan kartu busuk di papan. Kartu busuk memberi x1.4 Mult saat dicetak dan hancur di akhir ronde. Tiap kartu busuk yang hancur menurunkan target blind 3%.
- **Hook:** stiker `ne_decay`; `context.after` (sebar via `NE.Board.neighbors`); `context.end_of_round`; `NE.Blind.scale_target`.
- **Shader:** motif `decay` · glyph `hand` · `#7D8491 / #2B2D42 / #B8C0C8` · speed 0.5 · intensity 0.55
- **Animasi:** partikel abu dan retakan menjalar dari kartu ke kartu.

### #58 Whitebeard — `j_ne_whitebeard`
One Piece · Tag: `board`, `blind` · $12
- **Lore:** Orang yang bisa mengguncang dunia.
- **Kemampuan:** Gura Gura: di fase Pertanda, posisi semua residu diacak (seeded). Formasi yang terbentuk berkat guncangan x2.5 Mult. Aktif (1x per ronde): retakkan langit, target blind −12%.
- **Hook:** `context.ne_omen`; `NE.Board.shuffle_residues(seed)`; `NE.Formation` menandai formasi yang memakai kartu terguncang; `ne_active`; `NE.Blind.scale_target(0.88)`.
- **Shader:** motif `shockwave` · glyph `crack` · `#F1F1F1 / #2F2F2F / #7FB3D5` · speed 0.7 · intensity 0.6
- **Animasi:** retakan layar (overlay `crack`) + guncangan kuat via `G.ROOM.jiggle` (patuh screenshake).

### #59 Kaido — `j_ne_kaido`
One Piece · Tag: `protect` · $12
- **Lore:** Makhluk terkuat yang tidak bisa mati.
- **Kemampuan:** Tidak bisa dihancurkan, dicuri, di-debuff, atau dijual paksa. x4 Mult, +x1 permanen setiap kali sebuah efek gagal menghancurkan, mencuri, atau men-debuff Kaido.
- **Hook:** `context.check_eternal`; `mod.set_debuff`; `context.ne_boss_trait`; hook `SMODS.destroy_cards` untuk mendeteksi percobaan.
- **Shader:** motif `fire` · glyph `horn` · `#4361EE / #3A0CA3 / #F72585` · speed 0.6 · intensity 0.6
- **Animasi:** siluet naga melingkar + kilau sisik.

### #60 Blackbeard — `j_ne_blackbeard`
One Piece · Tag: `nullify`, `steal` · $12
- **Lore:** Kegelapan yang menelan kekuatan lain, lalu menyimpannya.
- **Kemampuan:** Yami Yami: pada tangan pertama tiap blind, semua trait blind nonaktif. Menyerap kemampuan hingga 2 joker Unranked/Demonic yang dihancurkan dan memicunya. x2 Mult per kemampuan terserap.
- **Hook:** `NE.Blind.suspend_traits(scope='hand')`; `context.joker_type_destroyed`; `NE.AbilityProxy`.
- **Shader:** motif `void` · glyph `void` · `#1B1B1B / #4A4E69 / #9A8C98` · speed 0.6 · intensity 0.6
- **Animasi:** lubang hitam kecil menghisap cahaya di atas kartu.

### #61 Luffy (Gear 5) — `j_ne_luffy_gear5`
One Piece · Tag: `rule` · $12
- **Lore:** Kekuatan yang membengkokkan dunia hanya demi kesenangan.
- **Kemampuan:** x5 Mult. Toon Force: tiap tangan, satu aturan dibengkokkan secara acak untuk tangan itu dan diumumkan di awal tangan: semua kartu dihitung semua suit / papan melingkar (kolom 1 dan 5 tersambung) / residu ikut dicetak / batas main +3 / Formation Cap +2.
- **Hook:** `context.ne_omen` (pilih aturan, seeded); `NE.Rules.push_temp(rule, 'hand')`.
- **Shader:** motif `radiance` · glyph `sun` · `#FFFFFF / #F4F1DE / #E07A5F` · speed 1.0 · intensity 0.55
- **Animasi:** asap putih kartun; semua kartu bergoyang lentur (wobble); bunyi drum.

### #62 Chrollo Lucilfer — `j_ne_chrollo`
Hunter x Hunter · Tag: `steal`, `copy` · $12
- **Lore:** Buku yang berisi kekuatan-kekuatan curian.
- **Kemampuan:** Skill Hunter: setiap kali Anda menjual joker Unranked/Demonic, kemampuannya tersimpan di Buku (maks 4 halaman). Aktif (gratis, 1x per ronde): pilih 1 halaman aktif; Chrollo memicu kemampuan itu. x1.5 Mult per halaman terisi.
- **Hook:** `context.selling_card`; `NE.AbilityProxy`; `ne_active`.
- **Shader:** motif `sigil` · glyph `book` · `#2B2D42 / #EDF2F4 / #EF233C` · speed 0.6 · intensity 0.55
- **Animasi:** buku terbuka, halaman aktif berpendar.

### #63 Isaac Netero — `j_ne_netero`
Hunter x Hunter · Tag: `scaling` · $13
- **Lore:** Seratus bentuk doa yang lebih cepat dari suara.
- **Kemampuan:** Hundred-Type Guanyin: tiap tangan memicu Tipe berikutnya (1→99, tersimpan). Tipe n memberi x(1 + n/15) Mult. Tipe 99 = Zero Hand: tangan itu ^1.5 Mult, lalu kembali ke Tipe 1.
- **Hook:** `context.joker_main`; counter di `ability.extra`.
- **Shader:** motif `radiance` · glyph `hand` · `#F9D949 / #C0392B / #FFFFFF` · speed 0.9 · intensity 0.5
- **Animasi:** puluhan siluet telapak tangan emas menghantam; Zero Hand: cahaya putih menyilaukan.

### #64 Gon Freecss (dewasa) — `j_ne_gon_adult`
Hunter x Hunter · Tag: `destroy`, `hyper` · $13
- **Lore:** Menyerahkan seluruh masa depan demi satu momen.
- **Kemampuan:** Janji (aktif, sekali per run): korbankan semua joker lain (dihancurkan). Tangan berikutnya ^(1 + 0.25 × jumlah joker dikorbankan) Mult dan x10 Chips per joker. Setelah itu Gon menjadi hampa (x1, tanpa kemampuan).
- **Hook:** `ne_active`; `SMODS.destroy_cards`; `context.joker_main`.
- **Shader:** motif `aura` · glyph `fist` · `#F77F00 / #003049 / #FCBF49` · speed 1.0 · intensity 0.7
- **Animasi:** rambut memanjang (siluet), ledakan energi oranye.

### #65 Meruem — `j_ne_meruem`
Hunter x Hunter · Tag: `scaling`, `hyper` · $13
- **Lore:** Raja yang berevolusi dari semua yang ia makan.
- **Kemampuan:** x2 Mult. Setiap kali kartu atau joker dihancurkan (oleh apa pun), Meruem ^1.005 Mult permanen (joker Heavenly: ^1.05).
- **Hook:** `context.remove_playing_cards`, `context.joker_type_destroyed`; `context.joker_main` → `emult`.
- **Shader:** motif `eldritch` · glyph `crown` · `#2A9D8F / #264653 / #E9C46A` · speed 0.6 · intensity 0.4→0.9
- **Animasi:** ekor berduri bergerak + cahaya evolusi.

### #66 Frieza — `j_ne_frieza`
Dragon Ball · Tag: `scaling`, `hyper` · $13
- **Lore:** Setiap kekalahan melahirkan bentuk yang lebih kuat.
- **Kemampuan:** Transformasi: naik satu bentuk setiap Elit atau Boss dikalahkan. Bentuk 1: x2 → 2: x4 → 3: x8 → Final: ^1.1 → Golden: ^1.25. Golden menghabiskan 1 ⧗ per tangan; jika ⧗ 0, kembali ke Final.
- **Hook:** `context.ne_encounter_cleared`; `context.joker_main`; `NE.Currency.spend('time')`.
- **Shader:** motif `aura` · glyph `horn` · `#7209B7 / #FFD60A / #FFFFFF` · speed 0.8 · intensity 0.6 (palet emas saat Golden)
- **Animasi:** kilat transformasi; aura ungu berubah emas.

### #67 Broly — `j_ne_broly`
Dragon Ball · Tag: `scaling`, `destroy` · $13
- **Lore:** Kekuatan yang terus tumbuh sampai tak terkendali.
- **Kemampuan:** +x1 Mult setiap tangan dimainkan (permanen, tanpa batas). Setiap 5 tangan, Broly mengamuk: hancurkan 1 joker non-eternal acak lain (jika tidak ada: kartu rank tertinggi di tangan).
- **Hook:** `context.after`; counter; `SMODS.destroy_cards`.
- **Shader:** motif `aura` · glyph `fist` · `#38B000 / #004B23 / #CCFF33` · speed 1.0 · intensity 0.3→1.0 (state = tumpukan)
- **Animasi:** aura hijau membesar tiap tangan; amukan: ledakan hijau.

### #68 Jiren — `j_ne_jiren`
Dragon Ball · Tag: `hyper` · $13
- **Lore:** Kekuatan murni tanpa trik.
- **Kemampuan:** ^1.2 Mult tetap. Tidak bisa disalin, dipicu ulang, atau dikurangi Peredam. +10% Chips per trait blind yang aktif.
- **Hook:** `context.joker_main`; flag `ne_unaffected{dampening=true}`; `NE.Blind.active_traits()`.
- **Shader:** motif `aura` · glyph `circle` · `#D90429 / #2B2D42 / #EDF2F4` · speed 0.4 · intensity 0.6
- **Animasi:** aura merah berdenyut tanpa gerakan lain.

### #69 Vegeta (Ultra Ego) — `j_ne_vegeta_ue`
Dragon Ball · Tag: `scaling`, `hyper` · $13
- **Lore:** Makin terluka, makin kuat.
- **Kemampuan:** x3 Mult. Setiap kali Anda terkena kerugian (trait boss memicu pada Anda, kartu/joker dihancurkan oleh boss, atau tangan gagal), +^0.03 Mult. Reset tiap ante.
- **Hook:** `context.ne_boss_trait` (setelah berhasil), `context.ne_judgment` (gagal); `context.joker_main` → `emult`.
- **Shader:** motif `aura` · glyph `crown` · `#7B2CBF / #3C096C / #E0AAFF` · speed 0.9 · intensity 0.4→0.9
- **Animasi:** aura ungu kehancuran berkobar lebih tinggi setiap tumpukan.

### #70 Goku (Ultra Instinct) — `j_ne_goku_ui`
Dragon Ball · Tag: `nullify`, `luck` · $14
- **Lore:** Tubuh bergerak sendiri sebelum pikiran sempat bereaksi.
- **Kemampuan:** x3 Mult. Setiap trait boss yang akan memicu punya peluang 1 in 2 dihindari (dibatalkan). Setelah 10 hindaran dalam run: Mastered, selalu menghindar. Tangan yang berisi hindaran: ^1.1 Mult.
- **Hook:** `context.ne_boss_trait` → `ne_cancel` via `SMODS.pseudorandom_probability`; counter run.
- **Shader:** motif `aura` · glyph `flame` · `#C0C0C0 / #1E3A8A / #FFFFFF` · speed 1.2 · intensity 0.6
- **Animasi:** aura perak; jejak bayangan (motion blur) saat menghindar.

### #71 Beerus — `j_ne_beerus`
Dragon Ball · Tag: `destroy`, `blind` · $14
- **Lore:** Dewa penghancur. Satu kata, dan sesuatu lenyap.
- **Kemampuan:** x3 Mult. Hakai (aktif, ☠+20, 1x per ante): hapus 1 target: 1 trait boss, 1 fase boss (dianggap kalah), 1 blind di Celah (dianggap kalah), 1 kartu, atau 1 joker.
- **Hook:** `ne_active` (multi-target); `NE.Blind.remove_trait/skip_phase/defeat_blind`; `SMODS.destroy_cards`.
- **Shader:** motif `void` · glyph `hand` · `#8338EC / #3A0CA3 / #FF006E` · speed 0.7 · intensity 0.6
- **Animasi:** target melebur menjadi partikel ungu-magenta.

### #72 Jotaro Kujo — `j_ne_jotaro`
JoJo · Tag: `time_stop`, `retrigger` · $14
- **Lore:** Star Platinum: presisi sempurna dan detik-detik yang dicuri.
- **Kemampuan:** Star Platinum: kartu skor pertama dipicu ulang 4 kali. The World (aktif, 3 ⧗): waktu berhenti selama 2 tangan; tangan tidak berkurang dan trait blind tidak memicu.
- **Hook:** `context.repetition`; `ne_active`; `NE.Chrono.stop{hands=2}`.
- **Shader:** motif `gears` · glyph `star` · `#1D3557 / #A8DADC / #E63946` · speed 0.8 · intensity 0.55
- **Animasi:** time stop (layar abu-abu + roda gigi di kartu + roda gigi besar di tengah layar) + rentetan tinju "ORA ORA".

### #73 Dio Brando — `j_ne_dio`
JoJo · Tag: `time_stop` · $14
- **Lore:** The World menghentikan waktu, dan hanya Dio yang bergerak.
- **Kemampuan:** +⧗1 setiap Boss dimulai. The World (aktif, 2 ⧗): ZA WARUDO, waktu berhenti selama 1 tangan: tangan tidak berkurang, trait blind tidak memicu, residu tidak bisa dimakan. Selama waktu berhenti, setiap xMult X dari joker menjadi x(X^1.1). Road Roller: jika The World dipakai 3 kali dalam satu ante, tangan berikutnya ^1.3 Mult.
- **Hook:** `ne_active`; `NE.Chrono.stop{hands=1}`; hook `SMODS.calculate_individual_effect` untuk `xmult` saat `NE.Chrono.stopped()`; counter per ante.
- **Shader:** motif `gears` · glyph `clock` · `#FFD000 / #1B1B1B / #7A00FF` · speed 0.9 · intensity 0.6
- **Animasi (wajib, contoh dari brief):** roda gigi berputar di kartu **dan** roda gigi besar berputar di tengah layar selama efek berlangsung; gelombang inversi warna menyebar dari kartu lalu layar menjadi abu-abu; teks "ZA WARUDO!". Road Roller: bayangan besar jatuh dari atas.

### #74 Yoshikage Kira — `j_ne_kira`
JoJo · Tag: `rewind`, `time` · $14
- **Lore:** Bom yang meledak, dan waktu yang sudah terjadi terulang.
- **Kemampuan:** Killer Queen: kartu skor pertama tiap tangan menjadi bom; saat bom terpakai/dibuang, tangan berikutnya +25 Mult. Bites the Dust (aktif, 4 ⧗, 1x per ronde): jika tangan berikutnya gagal menyelesaikan blind/fase, waktu diulang ke awal tangan itu dan tangan diulang dengan x3 Mult.
- **Hook:** stiker `ne_bomb`; `context.discard`/`context.after`; `ne_active`; `NE.Chrono.arm_rewind{condition='fail'}` + `NE.Snapshot`.
- **Shader:** motif `gears` · glyph `bomb` · `#C77DFF / #240046 / #FF9E00` · speed 0.8 · intensity 0.55
- **Animasi:** jam berputar mundur (roda gigi berlawanan arah) + ledakan.

### #75 Diavolo — `j_ne_diavolo`
JoJo · Tag: `time`, `rule` · $14
- **Lore:** Waktu dihapus. Hanya hasilnya yang tersisa.
- **Kemampuan:** King Crimson (aktif, 3 ⧗): hapus waktu untuk tangan ini; fase Pertanda dan Penghakiman blind dilewati (trait tidak bisa bereaksi) dan tangan tidak berkurang. Epitaph (pasif): lihat 3 kartu berikutnya di tiap dek dan trait fase boss berikutnya.
- **Hook:** `ne_active`; `NE.Phases.skip{'omen_blind','judgment_blind'}`; UI pratinjau dek.
- **Shader:** motif `glitch` · glyph `mask` · `#B5179E / #480CA8 / #F72585` · speed 1.2 · intensity 0.6
- **Animasi:** efek frame-skip (glitch) dan fragmentasi merah.

### #76 Eren Yeager (Founding Titan) — `j_ne_eren`
Attack on Titan · Tag: `blind`, `destroy` · $14
- **Lore:** Titan pendiri yang menggerakkan ribuan raksasa.
- **Kemampuan:** Koordinat: semua joker lain +x0.5 Mult. The Rumbling (aktif, ☠+40, 1x per run): selama 1 ante, semua target blind −50%, tetapi tiap tangan menghancurkan 1 kartu acak dari Dek Utama.
- **Hook:** `context.other_joker`; `ne_active`; `NE.Blind.scale_target` untuk ante; `context.after`.
- **Shader:** motif `eldritch` · glyph `key` · `#6B705C / #3F4238 / #FFE8D6` · speed 0.5 · intensity 0.6
- **Animasi:** siluet titan kolosal berbaris di bawah layar; guncangan tanah (patuh screenshake).

### #77 Light Yagami — `j_ne_light`
Death Note · Tag: `blind`, `destroy` · $14
- **Lore:** Cukup tulis namanya.
- **Kemampuan:** x2 Mult. Death Note (aktif, ☠+30, 1x per ante): tulis nama boss yang sedang dihadapi. Setelah 3 tangan dimainkan, boss mati (blind kalah, semua fase selesai), asalkan Anda masih punya tangan. Tidak berlaku pada boss berimunitas Nameless.
- **Hook:** `ne_active` (hanya saat boss); counter tangan; `NE.Blind.defeat_encounter()` di `context.ne_judgment`.
- **Shader:** motif `ink` · glyph `book` · `#111111 / #F5F5F5 / #B22222` · speed 0.4 · intensity 0.5
- **Animasi:** buku menulis nama; ikon jantung berdenyut di chip boss, melambat, lalu berhenti.

### #78 Subaru Natsuki — `j_ne_subaru`
Re:Zero · Tag: `rewind`, `revive` · $14
- **Lore:** Setiap kematian mengembalikannya ke titik awal, dengan ingatan yang tetap utuh.
- **Kemampuan:** Return by Death: jika Anda kalah (game over), kembali ke awal blind itu (checkpoint otomatis saat blind dimulai) dengan semua joker, kartu, dan mata uang seperti saat itu. Setiap kembali: ☠+10 dan Subaru +x1 Mult permanen (bonus ini tetap ada setelah waktu diulang).
- **Hook:** `NE.Snapshot.checkpoint()` di `context.setting_blind`; `context.ne_pre_game_over` → `NE.Snapshot.restore()`; bonus disimpan di luar snapshot (`G.GAME.newera.persistent`).
- **Shader:** motif `gears` · glyph `hand` · `#3A0CA3 / #000000 / #9D4EDD` · speed 0.6 · intensity 0.6
- **Animasi:** tangan-tangan hitam penyihir, layar memudar ke hitam, jam berputar mundur.

### #79 Homura Akemi — `j_ne_homura`
Madoka Magica · Tag: `time_stop`, `rewind` · $14
- **Lore:** Mengulang waktu berkali-kali demi satu orang.
- **Kemampuan:** Setiap kali waktu diulang (oleh efek apa pun), Homura +^0.05 Mult permanen. Time Stop (aktif, 2 ⧗): waktu berhenti 1 tangan (tangan tidak berkurang, trait tidak memicu), dan Anda boleh mengambil 1 kartu mana pun dari Dek Utama ke tangan.
- **Hook:** `context.ne_rewind`; `ne_active`; `NE.Chrono.stop{hands=1}`; UI pilih kartu dari dek.
- **Shader:** motif `gears` · glyph `clock` · `#6A4C93 / #1D1A31 / #C8B6FF` · speed 0.8 · intensity 0.6
- **Animasi:** perisai jam berputar, roda gigi ungu, layar abu-abu.

### #80 Alucard — `j_ne_alucard`
Hellsing · Tag: `hyper`, `corrupt` · $14
- **Lore:** Setiap segel yang dilepas membangunkan sesuatu yang lebih tua.
- **Kemampuan:** Restriksi Level 3: x3 Mult. Setiap Boss dikalahkan membuka 1 level: Level 2: x6, Level 1: ^1.1. Level Zero (aktif, ☠+50, 1x per run): selama 1 ante, ^1.5 Mult dan setiap kartu yang dihancurkan kembali sebagai Kartu Iblis di Dek Bayangan.
- **Hook:** `context.ne_encounter_cleared`; `ne_active`; `context.remove_playing_cards` → `NE.Shadow.add`.
- **Shader:** motif `eye` · glyph `eye` · `#8B0000 / #0B0B0B / #FF4D4D` · speed 0.7 · intensity 0.6
- **Animasi:** mata-mata bermunculan di layar; bayangan merah membanjir.

### #81 Dante — `j_ne_dante`
Devil May Cry · Tag: `scaling` · $14
- **Lore:** Gaya adalah segalanya.
- **Kemampuan:** Style Rank naik 1 tingkat setiap tangan dengan formasi utama yang berbeda dari tangan sebelumnya; kembali ke D jika sama. D x1 · C x2 · B x3 · A x5 · S x8 · SS x8 ^1.1 · SSS x8 ^1.2. Devil Trigger (aktif, ☠+10, 1x per ronde): naik 2 tingkat seketika.
- **Hook:** `context.joker_main`; `SMODS.last_hand`; `ne_active`.
- **Shader:** motif `fire` · glyph `sword` · `#C1121F / #000000 / #FFFFFF` · speed 1.0 · intensity 0.3→0.9 (state = rank)
- **Animasi:** huruf rank style muncul besar (DynaText) + kilat merah.

### #82 Kratos — `j_ne_kratos`
God of War · Tag: `counter` · $14
- **Lore:** Pembunuh para dewa.
- **Kemampuan:** Blades of Chaos: 2 kartu skor pertama dipicu ulang 1 kali. Godslayer: melawan boss arketipe Seraph atau blind dengan trait Ilahi: ^1.3 Mult. +x0.5 Mult permanen setiap joker Heavenly dihancurkan (oleh apa pun).
- **Hook:** `context.repetition`; `NE.Blind.archetype()`; `context.joker_type_destroyed`.
- **Shader:** motif `fire` · glyph `chain` · `#9B2226 / #EE9B00 / #E9D8A6` · speed 1.0 · intensity 0.6
- **Animasi:** bilah berantai berayun membentuk busur api.

### #83 Sephiroth — `j_ne_sephiroth`
Final Fantasy VII · Tag: `hyper` · $14
- **Lore:** Malaikat bersayap satu yang membawa bencana kosmik.
- **Kemampuan:** x4 Mult. Supernova (aktif, ☠+20, 1x per boss): tangan ini ^1.4 Mult, lalu semua kartu di papan dan Tangan Utama kehilangan enhancement dan edisinya.
- **Hook:** `ne_active`; `context.after` → `Card:set_ability(G.P_CENTERS.c_base)`, `Card:set_edition(nil)`.
- **Shader:** motif `cosmos` · glyph `wing` · `#1B263B / #E0E1DD / #6D597A` · speed 0.6 · intensity 0.65
- **Animasi:** kilatan putih kosmik, ledakan bintang (distorsi radial besar).

### #84 Sans — `j_ne_sans`
Undertale · Tag: `nullify`, `blind` · $14
- **Lore:** Musuh termudah. Hanya bisa memberi 1 damage… per frame.
- **Kemampuan:** +1 Mult. Dodge: trait boss pertama yang memicu di tiap tangan dihindari. KARMA: tiap tangan melawan boss menurunkan target fase boss secara kumulatif (2%, 4%, 6%, …).
- **Hook:** `context.ne_boss_trait` → `ne_cancel`; `context.ne_judgment` → `NE.Blind.scale_target`.
- **Shader:** motif `eye` · glyph `skull` · `#1E90FF / #F5F5F5 / #000000` · speed 0.8 · intensity 0.55
- **Animasi:** mata biru menyala + sinar tengkorak raksasa (overlay `beam`).

### #85 Loki — `j_ne_loki`
Mitologi Nordik · Tag: `copy`, `blind` · $14
- **Lore:** Tidak ada yang tahu wajah aslinya.
- **Kemampuan:** Trickster: di awal tiap ronde, Loki menyamar menjadi salinan joker Unranked/Demonic acak lain milik Anda dan memakai kemampuannya. Tipu Daya (aktif, 1x per ronde): tukar 1 trait blind dengan 1 trait acak lain yang budget-nya sama atau lebih rendah.
- **Hook:** `context.setting_blind`; `NE.AbilityProxy`; `ne_active`; `NE.Blind.replace_trait`.
- **Shader:** motif `glitch` · glyph `horn` · `#2D6A4F / #FFD700 / #081C15` · speed 0.9 · intensity 0.55 (palet ikut joker yang disamar)
- **Animasi:** kilau hijau lalu kartu berubah bentuk (morph palet).

### #86 Hades — `j_ne_hades`
Mitologi Yunani · Tag: `revive`, `shadow` · $14
- **Lore:** Yang mati tidak pernah benar-benar pergi dari kerajaannya.
- **Kemampuan:** x3 Mult. Kartu dan joker yang dihancurkan masuk Dunia Bawah (maks 20 kartu). Awal tiap ronde, bangkitkan 2 kartu dari Dunia Bawah ke Dek Bayangan sebagai Kartu Iblis. Joker yang dihancurkan: 1 in 3 bangkit di akhir ante (ke slot kosong).
- **Hook:** `context.remove_playing_cards`, `context.joker_type_destroyed`; `G.GAME.newera.underworld` (serialisasi `Card:save`); `context.setting_blind`.
- **Shader:** motif `fire` · glyph `skull` · `#0077B6 / #03045E / #90E0EF` · speed 0.6 · intensity 0.6
- **Animasi:** api biru naik, jiwa-jiwa melayang ke atas.

### #87 Anubis — `j_ne_anubis`
Mitologi Mesir · Tag: `destroy`, `divine` · $14
- **Lore:** Hati ditimbang melawan bulu kebenaran.
- **Kemampuan:** Timbangan Hati: di fase Penghakiman, tiap kartu skor dibandingkan dengan rata-rata chips kartu skor. Di atas rata-rata: diberkati (+10 Chips permanen, ✦+1). Di bawah rata-rata: dihancurkan. x1 Mult, +x0.5 per kartu yang dihancurkan Anubis di ronde ini.
- **Hook:** `context.ne_judgment`; `SMODS.destroy_cards`; perma bonus.
- **Shader:** motif `sigil` · glyph `scale` · `#CA9A2A / #1A1A1A / #3BB273` · speed 0.5 · intensity 0.55
- **Animasi:** timbangan emas besar di tengah layar; bulu Ma'at melayang.

### #88 Sun Wukong — `j_ne_sun_wukong`
Mitologi Tiongkok · Tag: `copy`, `transmute` · $14
- **Lore:** Seratus klon dari sehelai rambut, dan tujuh puluh dua wujud.
- **Kemampuan:** x2 Mult. Klon: di awal tiap ronde, buat 2 klon sementara (salinan joker Unranked/Demonic acak milik Anda) yang tidak memakai slot dan hilang di akhir ronde. 72 Transformasi (aktif, 1x per ronde): ubah 1 kartu di tangan menjadi rank dan suit apa pun.
- **Hook:** `context.setting_blind`; area sementara `G.ne_clones` (tidak disimpan; dibuat ulang saat load dari seed); `ne_active` → `SMODS.change_base`.
- **Shader:** motif `radiance` · glyph `staff` · `#E9C46A / #E76F51 / #264653` · speed 0.8 · intensity 0.55
- **Animasi:** kepulan klon dari helaian rambut; tongkat emas berputar.

### #89 Susanoo — `j_ne_susanoo`
Mitologi Shinto · Tag: `luck`, `board`, `blind` · $14
- **Lore:** Dewa badai yang membawa kekacauan ke mana pun.
- **Kemampuan:** Badai: tiap tangan, 3 kartu acak di papan disambar petir: dipicu ulang 1 kali, dan masing-masing 1 in 4 mendapat edisi acak (Foil/Holo/Polychrome) permanen. Kusanagi (aktif, ☠+10, 1x per ronde): hapus 1 trait blind.
- **Hook:** `context.repetition`; `SMODS.pseudorandom_probability`; `Card:set_edition`; `ne_active`.
- **Shader:** motif `lightning` · glyph `bolt` · `#4361EE / #14213D / #E5E5E5` · speed 1.3 · intensity 0.6
- **Animasi:** awan badai di atas papan + sambaran petir ke kartu terpilih.

### #90 Lucifer — `j_ne_lucifer`
Mitologi Abrahamik · Tag: `divine`, `corrupt` · $14
- **Lore:** Malaikat paling terang yang jatuh paling dalam.
- **Kemampuan:** Dihitung sebagai Demonic **dan** Heavenly. +^0.04 Mult per joker Heavenly lain; +x2 Mult per joker Demonic lain. Morning Star: jika ✦ ≥ 30 dan ☠ ≥ 50 sekaligus: ^1.5 Mult. Aktif (gratis, 1x per ronde): tukar mata uang, 1 ✦ → ☠+3 atau 3 ☠ → ✦+1.
- **Hook:** `Card:is_rarity` di-hook agar Lucifer lolos cek kedua rank; `context.joker_main`; `ne_active`.
- **Shader:** motif `radiance` (setengah `void`) · glyph `wing` · `#FFFFFF / #111111 / #C9A227` · speed 0.6 · intensity 0.7 · tier style: gabungan Demonic + Heavenly
- **Animasi:** enam sayap (setengah putih, setengah hitam), bulu berjatuhan.

### #91 Surtr — `j_ne_surtr`
Mitologi Nordik · Tag: `destroy`, `hyper`, `corrupt` · $14
- **Lore:** Api Ragnarok yang membakar sembilan dunia.
- **Kemampuan:** Muspelheim: +x0.05 Mult per ☠. Ragnarok (aktif, sekali per run): hancurkan semua joker lain dan semua kartu di tangan; selama sisa ante: ^2 Mult.
- **Hook:** `context.joker_main` (baca ☠); `ne_active`; `SMODS.destroy_cards`.
- **Shader:** motif `fire` · glyph `sword` · `#FF5400 / #390099 / #FFBD00` · speed 1.2 · intensity 0.7
- **Animasi:** dinding api naik dari bawah layar; pedang api terangkat.
