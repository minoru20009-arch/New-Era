# 05 — Arsitektur Teknis

Target: Balatro 1.0.1o-FULL, Steamodded ≥ 26.829.0, Lovely ≥ 0.9.0. Semua anchor Lovely di dokumen ini sudah dicek terhadap source vanilla 1.0.1o. Anchor bertanda **(dump)** berada di baris yang juga dimodifikasi SMODS, jadi harus dicocokkan ulang dengan `Mods/lovely/dump` sebelum ditulis.

## 1. Struktur folder mod

```
Mods/NewEra/
├─ NewEra.json                  # metadata SMODS
├─ main.lua                     # entry: memuat modul sesuai urutan (§2)
├─ config.lua                   # default config (kualitas grafis, notasi, efek meta)
├─ lovely/
│  ├─ 00_bootstrap.toml         # modul NE dimuat lebih awal (patches.module)
│  ├─ 10_bignum.toml            # serialisasi, cek tipe, modulate_sound
│  ├─ 20_states.toml            # state NE_MAP, dispatch update, rute toko/cashout
│  ├─ 30_board.toml             # G.play → papan, guard play, buang residu
│  ├─ 40_phases.toml            # sisipan fase Omen/Chain/Ascension/Judgment
│  ├─ 50_blinds.toml            # cek menang/kalah → NE.Encounter
│  └─ 60_render.toml            # shader background
├─ src/
│  ├─ core/        ne.lua, util.lua, log.lua, uid.lua, rules.lua, cond.lua, prof.lua
│  ├─ bignum/      big.lua (FFI), ops_hyper.lua, notation.lua, serialize.lua, hooks.lua
│  ├─ board/       grid.lua, board_area.lua, placement.lua, controller.lua
│  ├─ formation/   patterns.lua, evaluator.lua, formations.lua, planets.lua, ui_diagram.lua
│  ├─ scoring/     phases.lua, operators.lua, aura.lua, calc.lua
│  ├─ economy/     currency.lua, contracts.lua, hud.lua
│  ├─ zones/       shadow.lua (dek & tangan bayangan), stickers.lua, enhancements.lua
│  ├─ active/      active.lua (framework kemampuan aktif), targeting.lua
│  ├─ chrono/      chrono.lua (time stop), snapshot.lua (rewind/checkpoint)
│  ├─ blinds/      encounter.lua, phases.lua, traits/*.lua, archetypes.lua, bossgen.lua, hud_blind.lua
│  ├─ run/         map_gen.lua, map_state.lua, map_ui.lua, nodes/*.lua, events/*.lua, shrine.lua
│  ├─ jokers/      api.lua, proxy.lua, unranked/*.lua, demonic/*.lua, heavenly/*.lua
│  ├─ render/      shaders.lua, drawstep.lua, post.lua, background.lua, anim.lua, overlays.lua
│  ├─ compat/      vanilla_pool.lua (sembunyikan konten vanilla), settings.lua
│  └─ debug/       keybinds.lua, cheats.lua, perf_overlay.lua
├─ assets/
│  ├─ shaders/     ne_card.fs, ne_post.fs, ne_background.fs, ne_board.fs, ne_ui.fs
│  ├─ 1x/ 2x/      ne_frames.png (3 bingkai tier + slot papan), icon.png
│  └─ sounds/      (minimal; memakai suara vanilla sebisa mungkin)
├─ localization/   en-us.lua, id.lua
└─ tests/          run_tests.lua (LuaJIT CLI), big_spec.lua, evaluator_spec.lua, mapgen_spec.lua
```

`NewEra.json`:

```json
{
  "id": "NewEra",
  "name": "New Era",
  "author": ["minoru20009"],
  "description": "Extreme expansion: board & formations, hyper scoring, branching map, 121 jokers.",
  "prefix": "ne",
  "main_file": "main.lua",
  "priority": 0,
  "version": "0.1.0~dev",
  "badge_colour": "C9A227",
  "dependencies": ["Steamodded (>=26.829.0)", "Lovely (>=0.9)"],
  "conflicts": ["Talisman", "Amulet", "Cryptid"]
}
```

## 2. Modul & batas tanggung jawab

Satu tabel global `NE`. Modul tidak saling membaca state internal; hanya lewat API publik di bawah.

| Modul | API publik utama | Bergantung pada |
|---|---|---|
| `NE.Big` | `new`, `is`, `add/sub/mul/div/pow`, `arrow(a,n,b)`, `*_into` (mutasi), `eq/lt/le`, `tonumber`, `format`, `pack/unpack` | LuaJIT FFI |
| `NE.Board` | `place(card, slot)`, `slot_of(card)`, `card_at(c,r)`, `neighbors`, `adjacent`, `row_full`, `residues{row}`, `swap`, `shuffle_residues`, `resize(cols,rows)`, `keeps(card)` | `NE.Big` (tidak), `G.play` |
| `NE.Formation` | `evaluate(board_state) → result`, `primary()`, `secondaries()`, `preview()` | `NE.Board` |
| `NE.Phases` | `omen()`, `chain(result)`, `ascension()`, `judgment(score)`, `skip{...}` | SMODS calc, `NE.Formation` |
| `NE.Currency` | `get/add/spend(kind, n, source)`, `cost_modifier`, `on_change` | — |
| `NE.Active` | registrasi `ne_active` di definisi joker, tombol UI, targeting | `NE.Currency` |
| `NE.Chrono` | `stop{hands}`, `stopped()`, `arm_rewind{...}` | `NE.Snapshot` |
| `NE.Snapshot` | `checkpoint()`, `restore()`, `hand_snapshot()` | save/load vanilla |
| `NE.Encounter` / `NE.Blind` | `start(node)`, `target()`, `apply_score(score)`, `cleared()`, `skip_phase`, `defeat_blind`, `remove_trait`, `scale_target`, `pow_target`, `cap_target`, `active_traits()` | `NE.Big`, `NE.BossGen` |
| `NE.BossGen` | `generate(ante, seed, player_tags) → boss_def` | tabel trait/arketipe |
| `NE.Map` | `generate(ante)`, `enter(node)`, `restart_ante`, `pregenerate` | `NE.Encounter` |
| `NE.Rules` | `push_temp(rule, scope)`, `push_permanent(rule)`, `get(key)` | — |
| `NE.cond` | `NE.cond(card, key, value)` (semua kondisi joker lewat sini) | `NE.Rules` |
| `NE.AbilityProxy` | salin/curi/serap kemampuan joker (Kirby, AFO, Chrollo, Rimuru, Loki) | SMODS center |
| `NE.Render` / `NE.Anim` | `play(anim_key, args)`, `post.set(param, value, tween)`, `background.state` | shader |

**Urutan load** (`main.lua`): `core` → `bignum` → `economy` → `board` → `formation` → `scoring` → `zones` → `chrono` → `blinds` → `run` → `active` → `render` → `jokers` → `compat` → `debug`. Konten (joker, trait, event) didaftarkan terakhir karena bergantung pada semua framework.

## 3. Big number (`NE.Big`)

### 3.1 Representasi

```lua
ffi.cdef[[
typedef struct { double a[8]; int32_t len; int8_t sign; uint8_t flags; } ne_big;
]]
```

- Semantik **array OmegaNum** (OmegaNum.js): `a[0]` = nilai dasar, `a[k]` = jumlah operasi panah ke-k dengan basis 10. Kapasitas 8 → mencakup hingga operator `{7}` (heptasi). Di luar kapasitas → saturasi ke `NE.Big.MAX`. Implementasi New Era ditulis sendiri (bentuk normal & perbandingan leksikografis, lihat header `src/bignum/big.lua`).
- **Array disimpan inline di cdata** (tanpa tabel samping seperti Amulet) → satu alokasi per nilai, tidak ada tabel weak.
- **Jalur cepat:** jika `len == 1` (nilai < 1e308), operasi memakai double langsung; naik ke representasi panjang hanya saat overflow.
- **Terverifikasi di Fase 3:** LuaJIT memanggil `__eq` untuk cdata vs number/nil/string; field yang tidak ada pada struct hanya aman jika `__index` berupa **fungsi** (tabel → error), jadi `NE.Big` memakai fungsi.
- `flags`: bit NaN/Inf **hanya untuk diagnosis**; semua API publik mengembalikan nilai tersaturasi, tidak pernah NaN/Inf.

### 3.2 Operasi

- Metamethod: `__add __sub __mul __div __pow __unm __lt __le __concat __tostring`. Operasi campuran number/cdata **terverifikasi berfungsi** (dokumentasi LuaJIT FFI, Fase 0).
- `__eq` **tidak diandalkan** untuk campuran number/cdata → selalu `NE.Big.eq(a, b)`.
- Hiper: `NE.Big.arrow(a, n, b)`: `n=1` pangkat, `n=2` tetrasi, `n≥3` panah Knuth. Tinggi pecahan memakai aproksimasi linear OmegaNum (01 §3.3).
- **Varian mutasi** untuk loop panas: `NE.Big.add_into(dst, x)`, `mul_into`, `pow_into`, `set(dst, src)`. Dipakai di pipeline skor dan HUD agar tidak membuat objek baru tiap operasi.
- Konstanta (`ZERO`, `ONE`, `TEN`, `MAX`) dibuat sekali dan diperlakukan immutable.

### 3.3 Titik integrasi dengan vanilla/SMODS

| Titik | Cara | Catatan |
|---|---|---|
| `number_format`, `score_number_scale`, `scale_number` | wrap Lua | Big → notasi New Era; number → fungsi asli |
| `math.floor/ceil/abs/max/min/log/log10/sqrt/exp` | wrap Lua | Mengembalikan big hanya jika input big; `max/min` tidak mengubah tipe number murni |
| `check_and_set_high_score`, `inc_career_stat` | wrap Lua | Di-clamp ke Lua number → profil tetap kompatibel vanilla |
| Cek `type(x) == 'number'` | patch per lokasi (L8) | Hasil audit Fase 3: `misc_functions.lua:958,969,1018` dan `button_callbacks.lua:1907` ditangani wrap Lua; `misc_functions.lua:739` dan `common_events.lua:503,525` sudah digantikan SMODS → patch L8a/L8b menarget payload SMODS; juice teks → L8c di `src/ui.lua` SMODS. `UI_definitions.lua:230` (leaderboard HTTP) dan `button_callbacks.lua:1923,1933` (UI vanilla yang digantikan SMODS) tidak relevan |
| `modulate_sound` (per frame) | patch (L7) | `NE.Big.sound_intensity` mengubah skor/target Big menjadi number dengan rasio & urutan sama (tanpa alokasi) |
| Skor tangan `chips × mult` | wrap `SMODS.Scoring_Calculations.multiply.func` | Produk > 1e308 menjadi Big (Fase 3); chips/mult sendiri menjadi Big di Fase 4 |
| Event `ease` pada `G.GAME.chips` | tanpa patch | Interpolasi `percent*start + (1−percent)*end` bekerja lewat metamethod; `math.floor` sudah di-wrap. Untuk nilai `len > 1`, NE mengganti event ini dengan ease di ruang log (lebih murah dan halus) |
| Perbandingan menang/kalah | patch (§7) | Diganti `NE.Encounter.cleared()` |
| `G.GAME.hands[*].chips/mult/s_*/l_*` | setelah `init_game_object` | Dikonversi ke big (pola Amulet `igo`) |
| Kode SMODS (`amount > 0`, `math.abs(amount)`, `hand_chips * (amount - 1)`) | tanpa patch | Bekerja lewat metamethod + wrap `math.*` |

### 3.4 Notasi

| Rentang | Contoh |
|---|---|
| < 1e11 | format vanilla dengan koma: `123,456,789` |
| `len = 1` | `1.234e56` |
| menara eksponen tinggi 2–3 | `e1.23e456`, `ee1.23e45` |
| tetrasi | `10^^5.21` |
| panah ≥ 3 | `10{3}2.10` |

Hanya ASCII (font pixel Balatro tidak dijamin punya `↑`). Hasil format di-cache per elemen UI; format ulang hanya jika nilai berubah.

### 3.5 Serialisasi

- `NE.Big.pack(x)` → string `"neb:<sign>:<len>:<a0>,<a1>,…"` dengan `%.17g` (presisi penuh double).
- Save: patch `recursive_table_cull` (`misc_functions.lua`, anchor `else ret_t[k] = v end`) → jika `type(v) == 'cdata'`, simpan `NE.Big.pack(v)`. Semua jalur save (`cardAreas`, `GAME`, `BLIND`, `tags`) melewati fungsi ini, jadi `STR_PACK` dan thread save hanya menerima data polos.
- Load (implementasi Fase 3, menggantikan L4): wrap Lua pada `STR_UNPACK` memulihkan string `neb:` di setiap tabel yang dibaca (save run, pratinjau "Continue", profil), dan wrap `Game:start_run` melakukan hal yang sama untuk `savetext` yang tidak lewat `STR_UNPACK` (checkpoint Fase 8). `Card:load` menerima `ability` yang sudah dipulihkan.
- Jika patch L6 tidak menempel, `NE.Big.ensure_cull()` memasang `recursive_table_cull` versi Lua yang setara (terdeteksi saat start, dicatat di log).
- Profil: tidak pernah menyimpan big (di-clamp).

## 4. Papan, formasi, dan dua tangan

### 4.1 `G.play` sebagai papan

- Area `G.play` vanilla (`card_limit = 5`, `type = 'play'`) diubah di `mod.custom_card_areas`: `card_limit = cols × rows`, `config.ne_board = {cols, rows}`, ukuran `T` diperbesar.
- `CardArea:align_cards` di-wrap: jika `config.ne_board`, kartu diposisikan dari slot (`card.ability.ne_slot`), dengan skala per baris untuk ilusi kedalaman (Belakang 0.84, Tengah 0.92, Depan 1.0). Tipe area lain → fungsi asli.
- Slot disimpan di `card.ability.ne_slot` → ikut `Card:save` otomatis.
- `CardArea:emplace` pada papan di-wrap untuk menetapkan slot otomatis bila kartu masuk tanpa slot (jalur "main cepat").
- `NE.Board.resize` mengubah `config.ne_board` dan memindah kartu yang keluar batas ke slot kosong (atau ke discard jika penuh).

### 4.2 Alur main

- Patch guard `if G.play and G.play.cards[1] then return end` (`state_events.lua`, `play_cards_from_highlighted`) → `if NE.Board.busy() then return end`.
- `G.FUNCS.can_play` di-wrap: tombol aktif jika ada kartu staged atau highlighted, dan jumlah ≤ batas main.
- Kartu staged sudah berada di `G.play` sebelum Play ditekan; kartu highlighted yang tersisa ditarik ke papan oleh kode vanilla lalu diberi slot oleh wrapper `emplace`.
- `G.FUNCS.draw_from_play_to_discard`: patch baris `if (not v.shattered) and (not v.destroyed) then` → tambah `and not NE.Board.keeps(v)` (residu, kartu terfase, kartu beku).
- Pratinjau: `CardArea:parse_highlighted` untuk `G.hand` di-wrap agar mengevaluasi papan + penempatan sementara.

### 4.3 Evaluator

- Tabel pola statis dibangun saat load dan saat `resize` (pasangan, garis-3, baris, blok 2×2, kompas).
- `evaluate(state)`: satu pass membaca rank/suit/flag per slot ke array datar (tanpa alokasi per panggilan; buffer dipakai ulang), lalu memeriksa hanya pola yang memuat slot baru. Kompleksitas ≈ jumlah pola (< 100) per evaluasi.
- Hasil di-cache per `board_version` (bertambah setiap papan berubah).
- Integrasi SMODS: setiap formasi = `SMODS.PokerHand` dengan `evaluate = function(parts, hand) return NE.Formation.cached(key) end`. `get_poker_hand_info` (override SMODS) tetap dipakai apa adanya; hasil rantai dimasukkan lewat context `evaluate_poker_hand` (`replace_display_name`).
- Hand vanilla: `take_ownership` → `visible = false`, `evaluate` → `{}`.

### 4.4 Tangan & Dek Bayangan

- `G.ne_shadow_deck` (type `deck`) dan `G.ne_shadow_hand` (type `hand`) dibuat di `custom_card_areas` → ikut save otomatis.
- `G.FUNCS.draw_from_deck_to_hand` di-wrap: setelah tangan utama, isi Tangan Bayangan.
- `G.FUNCS.draw_from_discard_to_deck` di-wrap: kartu dengan `ability.ne_home == 'shadow'` dikembalikan ke Dek Bayangan.
- Tipe `hand` pada Tangan Bayangan membuat cabang vanilla (`align_cards`, highlight) langsung bekerja; 7 cek `config.type == 'hand'` di SMODS diaudit satu per satu di Fase 7.

## 5. Library shader

### 5.1 Uber-shader kartu `ne_card.fs`

Satu shader untuk semua 121 joker, dengan parameter per joker:

| Uniform | Isi |
|---|---|
| `vec4 ne_a` | x = motif id, y = glyph id, z = tier (0 Unranked, 1 Demonic, 2 Heavenly, 3 hybrid), w = seed |
| `vec4 ne_c1` | warna primer (rgb) + intensity |
| `vec4 ne_c2` | warna sekunder (rgb) + speed |
| `vec4 ne_c3` | warna aksen (rgb) + pulse (0–1, naik saat memicu) |
| `vec2 ne_state` | x = state skala 0–1 (tumpukan, gerbang, dll.), y = khusus per joker |
| extern vanilla | `time`, `dissolve`, `texture_details`, `image_details`, `burn_colour_1/2`, `shadow`, `mouse_screen_pos`, `screen_scale`, `hovering` (dikirim `Sprite:draw_shader`) |

- **Motif (20):** `aura, lightning, water, slash, gears, eye, petals, void, sigil, cosmos, glitch, fire, frost, decay, eldritch, radiance, spiral, ink, smoke, shockwave`. Masing-masing fungsi GLSL berbasis noise/SDF yang digambar di dalam bingkai kartu.
- **Glyph (SDF, 50):** `fist, sword, katana3, disc, gear, clock, eye, tomoe, crescent, sun, moon, star, heart, skull, flame, wave, bolt, spiral, drill, wing, halo, crown, book, feather, scale, chain, hand, mask, wheel, orb, key, infinity, hammer, saw, burst, ring, tri, chomp, bell, petal, crack, horn, bomb, staff, arrow, brush, wire, void, circle, bullet`. Emblem karakter digambar prosedural; tidak ada sprite per joker.
- **Tier style:** Unranked = bingkai pixel datar, motif intensitas rendah. Demonic = vignette merah-hitam, retakan pada bingkai, bara, rim light merah. Heavenly = bingkai halo emas, kilau iridesen berputar pelan, piksel terang ikut ke glow post-process.
- **Tilt 3D:** blok `#ifdef VERTEX` menyalin rumus `position()` vanilla (`foil.fs`), sehingga tilt tetap konsisten dan otomatis mati saat reduced motion (vanilla mengirim `hovering = 0`).
- **Waktu animasi:** memakai `G.TIMERS.REAL_SHADER` (dibekukan vanilla saat reduced motion), dikirim via `_send` seperti `send_to_shader` vanilla.
- **Pemanggilan:** `SMODS.DrawStep` `ne_joker_art` (order 5, setelah `center`) → kirim `ne_*` ke `G.SHADERS['ne_card']`, lalu `card.children.center:draw_shader('ne_card', nil, card.ARGS.send_to_shader)`. Sprite dasar = bingkai tier dari atlas `ne_frames`.
- Parameter per joker ada di definisi joker (`ne_art = {motif, glyph, palette, speed, intensity}`) dan dikonversi sekali ke array float saat load (tanpa alokasi saat draw).

### 5.2 Post-process `ne_post.fs`

- Satu `SMODS.ScreenShader` (`order = -1`, sebelum CRT vanilla yang `order = 0`) yang menggabungkan: chromatic aberration, distorsi radial (maks 4 gelombang kejut), glitch, desaturasi (time stop), tint warna, vignette, glow murah (beberapa tap), dan **overlay prosedural** (§6).
- `should_apply` → `false` jika semua intensitas ≈ 0, sehingga biaya saat idle = nol pass tambahan.
- Kualitas bisa diturunkan di config (matikan glow/chromatic).

### 5.3 Background reaktif `ne_background.fs`

- Patch `game.lua` di `Game:start_run`: `shader = 'background',` → `shader = 'ne_background',` + extern tambahan (`ne_heaven`, `ne_hell`, `ne_intensity`, `ne_timestop`, `ne_parallax`).
- Sumber nilai: intensitas skor (log10 skor ronde / target), proporsi joker Heavenly vs Demonic, fase run (peta = tenang; Boss = warna boss), time stop (abu-abu). Diperbarui saat event, di-tween per frame (tanpa alokasi).
- Parallax: lapisan background bergeser mengikuti kursor dengan kecepatan berbeda (dimatikan saat reduced motion).

### 5.4 Papan

- `ne_board.fs` menggambar slot dan garis formasi yang menyala (pola aktif di-highlight saat pratinjau).
- Pseudo-3D papan: skala dan offset per baris + parallax kecil terhadap kursor; kartu yang memicu melakukan flip Y (skala x = cos θ) untuk kesan rotasi 3D.

## 6. Sistem animasi

- `NE.Anim.play(key, {card=..., duration=..., blocking=bool, intensity=...})` membuat event di `G.E_MANAGER`: `blocking = true` untuk animasi yang harus selesai sebelum skor berlanjut (ZA WARUDO), queue terpisah `ne_fx` untuk yang tidak memblokir.
- Satu animasi mengatur: juice kartu, `ne_c3.a` (pulse), parameter post-process (tween), overlay, teks callout (DynaText), suara, dan `G.ROOM.jiggle`.
- **Overlay prosedural di `ne_post.fs`** (satu overlay aktif + antrean): `gears` (roda gigi besar berputar; dipakai semua joker waktu), `clock_reverse`, `eye`, `slash`, `shockwave`, `vortex`, `pillar`, `sigil`, `flames`, `lightning`, `petals`, `crack`, `ink`, `fracture` (cermin pecah), `static`, `beam`, `wings`, `starfield`.
- **Reduced motion** (`G.SETTINGS.reduced_motion`): overlay tidak berputar/bergerak (frame statis singkat), tanpa kedip layar, tanpa guncangan, durasi dipersingkat.
- **Screenshake:** guncangan hanya lewat `G.ROOM.jiggle` → otomatis mengikuti slider `G.SETTINGS.screenshake` di `update_canvas_juice`.
- **Kecepatan game:** durasi dibagi `G.SETTINGS.GAMESPEED`.

## 7. Daftar patch Lovely

Prioritas file patch New Era: `0` (diterapkan setelah SMODS yang memakai −10/−5). Hasil cek: dari anchor L1–L15 dan L19–L20, tidak ada yang diubah oleh patch SMODS saat ini (hanya L2 berbagi titik sisip). L8 dan L16–L18 berada di area yang diubah SMODS dan wajib dicocokkan dengan dump.

| # | Target | Anchor | Tujuan |
|---|---|---|---|
| L1 | `globals.lua` | regex `self\.STATES = \{` | Tambah `NE_MAP = 1000`, `NE_EVENT = 1001` |
| L2 | `game.lua` | `if self.STATE == self.STATES.TAROT_PACK then` (before) | Dispatch `NE.Map.update(dt)` / `NE.Event.update(dt)`. SMODS (`booster.toml`) juga menyisipkan sebelum baris ini; barisnya tetap ada, jadi kedua sisipan aman. |
| L3 | `game.lua` | `self:prep_stage(G.STAGES.RUN, saveTable and saveTable.STATE or G.STATES.BLIND_SELECT)` | Run baru dimulai di `NE_MAP` |
| ~~L4~~ | `game.lua` | — | **Tidak dipakai.** Init `G.GAME.newera` lewat wrap `init_game_object`/`start_run` (Fase 2), rehydrate big lewat wrap `STR_UNPACK`/`start_run` (Fase 3) |
| L5 | `game.lua` | `shader = 'background',` | Ganti ke `ne_background` + extern tambahan |
| L6 | `functions/misc_functions.lua` | `else ret_t[k] = v end` (di `recursive_table_cull`) | Pack cdata → string `neb:` |
| L7 | `functions/misc_functions.lua` | `G.ARGS.score_intensity.required_score = G.GAME.blind and G.GAME.blind.chips or 0` | `modulate_sound` memakai log10 ter-cache |
| L8a | `functions/misc_functions.lua` | payload SMODS `if type(G.GAME.current_round.current_hand[name]) ~= 'number' then all_numbers = false end` | `NE.is_numeric` (suara) |
| L8b | `functions/common_events.lua` | payload SMODS `local delta = (type(vals[name]) == 'number' and …` | `NE.is_numeric` (delta "+X") |
| L8c | `=[SMODS _ "src/ui.lua"]` | baris juice di `G.FUNCS.hand_type_UI_set` | `NE.is_numeric` (juice teks) |
| L9 | `game.lua` | `if G.GAME.chips - G.GAME.blind.chips >= 0 or G.GAME.current_round.hands_left < 1 then` | `NE.Encounter.cleared()` |
| L10 | `functions/state_events.lua` | `if G.GAME.chips - G.GAME.blind.chips >= 0 then` (2 lokasi: `end_round`, `evaluate_round`) | `NE.Encounter.cleared()` |
| L11 | `blind.lua` | `if self.boss and G.GAME.chips - G.GAME.blind.chips >= 0 then` | `NE.Encounter.cleared()` |
| L12 | `functions/state_events.lua` | `local _handname, _played, _order = 'High Card', -1, 100` | Default `ne_spark` |
| L13 | `functions/state_events.lua` | `if G.play and G.play.cards[1] then return end` | `NE.Board.busy()` |
| L14 | `functions/state_events.lua` | `if (not v.shattered) and (not v.destroyed) then` (di `draw_from_play_to_discard`) | Residu tetap di papan |
| L15 | `functions/state_events.lua` | `check_for_unlock({type = 'hand_contents', cards = G.play.cards})` (before) | Fase **Pertanda** (`NE.Phases.omen()`) + snapshot tangan |
| L16 | `functions/state_events.lua` | baris `SMODS.calculate_context({initial_scoring_step = true, …})` **(dump)** | Fase **Rantai** (sebelum) |
| L17 | `functions/state_events.lua` | baris context `final_scoring_step` sisipan SMODS **(dump)** | Fase **Kenaikan** (sesudah) |
| L18 | `functions/state_events.lua` | event `ease_to = G.GAME.chips + …` **(dump, diubah regex SMODS)** | Fase **Penghakiman** + `NE.Encounter.apply_score` |
| L19 | `functions/button_callbacks.lua` | `G.STATE = G.STATES.SHOP` (di `cash_out`) | Kembali ke `NE_MAP` |
| L20 | `functions/button_callbacks.lua` | `G.STATE = G.STATES.BLIND_SELECT` (di `toggle_shop`) | Kembali ke `NE_MAP` |

Tanpa patch (override/wrap Lua): `number_format`, `score_number_scale`, `scale_number`, `math.*`, `check_and_set_high_score`, `inc_career_stat`, `CardArea:align_cards`, `CardArea:emplace`, `CardArea:parse_highlighted`, `G.FUNCS.can_play`, `G.FUNCS.draw_from_deck_to_hand`, `G.FUNCS.draw_from_discard_to_deck`, `create_UIBox_HUD` (panel mata uang), `create_UIBox_HUD_blind` (encounter), `SMODS.get_card_areas` (blind tambahan & area sementara), `SMODS.calculate_individual_effect` (key return baru).

Area vanilla yang **tidak** disentuh: `G.FUNCS.select_blind` (NE memakai jalurnya sendiri yang meniru `select_blind`: `new_round()` + `G.GAME.blind:set_blind(...)`), `engine/string_packer.lua`, `engine/save_manager.lua`.

## 8. Encounter & blind

- `G.GAME.blind` selalu berisi **cangkang** `SMODS.Blind`: `bl_ne_encounter` (non-boss) atau `bl_ne_boss` (`boss = {min=1,max=1e9}`, `in_pool = false`). Dengan begitu logika vanilla `end_round` (naik ante jika tipe `Boss`) dan pembukuan `blind_states` tetap bekerja.
- Node peta dipetakan ke slot vanilla: Pertarungan → `blind_on_deck = 'Small'`, Elit/Celah → `'Big'`, Boss → `'Boss'`.
- Data encounter di `G.GAME.newera.encounter`: `{blinds = {{name, target(big), phases = {{target, traits}}, phase_i, defeated}}, active_i, spill = 0.5}`. Cangkang membaca data ini di `calculate` dan mendispatch ke trait aktif.
- Trait = tabel data + fungsi berkunci (`traits/*.lua`), dipicu lewat context `ne_boss_trait` sehingga joker bisa membatalkannya.
- `Blind:save()` vanilla hanya menyimpan field tertentu; SMODS menambah `effect`. Semua state encounter ada di `G.GAME.newera` → ikut save `GAME`.

## 9. Save/load

| Data | Lokasi | Mekanisme |
|---|---|---|
| Papan, Tangan/Dek Bayangan, Kamui, dll. | CardArea di `G.*` | `save_run` vanilla mengiterasi semua CardArea; dibuat di `custom_card_areas` sebelum load |
| Slot kartu, stiker, UID kartu | `card.ability.ne_*` | `Card:save` menyimpan `ability` utuh |
| Peta, encounter, mata uang, aturan, statistik, graveyard, underworld | `G.GAME.newera` (data polos) | Ikut `GAME` |
| Big number | di mana saja | Pack `neb:` di `recursive_table_cull`, rehydrate di L4 |
| State `NE_MAP` | `saveTable.STATE` | Dipulihkan vanilla; `NE.Map.update` membangun UI dari data |
| Checkpoint rewind (Subaru) | memori + `G.GAME.newera.checkpoint` | Salinan `G.culled_table` saat blind dimulai; restore memanggil `G:start_run{savetext = checkpoint}` |
| Referensi antar-kartu | UID `card.ability.ne_uid` + counter `G.GAME.newera.next_uid` | Bukan `sort_id` (tidak aman setelah load) |

Aturan: **tidak ada inf/nan dan tidak ada objek ber-metatable di `G.GAME.newera`** (divalidasi oleh `NE.debug` sebelum setiap save pada build dev).

## 10. Anggaran performa (60 FPS = 16.7 ms/frame)

| Pos | Anggaran | Catatan |
|---|---|---|
| Update NE per frame | ≤ 1.5 ms | Tanpa operasi big per frame; evaluator hanya saat papan berubah |
| Draw kartu NE | ≤ 2 ms CPU | 1 DrawStep + 1 `draw_shader` per joker; parameter dari array yang sudah dikonversi |
| Post-process | ≤ 1 pass tambahan, 0 saat idle | Digabung dalam satu shader |
| **Garbage per frame** | ≈ 0 KB saat idle, < 2 KB saat animasi | Vanilla hanya memberi GC ~0.3 ms/frame dan full-GC paksa di 300 MB |
| Resolusi satu tangan | ≤ 50 ms komputasi | Jika perkiraan jumlah efek > ambang (mis. 5.000), eksekusi dipecah ke coroutine dengan jatah 4 ms/frame (pola Amulet) |
| Save | di thread vanilla | Pack big terjadi di `recursive_table_cull` (thread utama, hanya saat save) |

Profiling: `NE.Prof` (wrapper `love.timer.getTime`) di titik-titik utama + overlay debug (`SMODS.Keybind`, default F9) yang menampilkan ms per modul, `collectgarbage('count')`, jumlah big dibuat per detik. Uji stres: skrip debug yang mengisi 15 kartu papan, 10 joker dengan retrigger, dan target `10↑↑50`.

## 11. Pengujian

- **Unit (di luar game, LuaJIT CLI):** `NE.Big` (aritmetika, perbandingan campuran, hiper, format, pack/unpack, saturasi), evaluator formasi (semua 17 formasi + tepi papan + resize), generator peta dan boss (determinisme seed).
- **Dalam game:** keybind debug untuk memberi joker/mata uang, mengatur skor/target, melompat ante, memaksa trait; skenario uji tertulis di akhir setiap fase roadmap.

## 12. Risiko utama

| Risiko | Mitigasi |
|---|---|
| Update Balatro 1.1 mengubah baris anchor | Anchor pendek & stabil; daftar L1–L20 diuji ulang saat rilis |
| Update SMODS mengubah baris (dump) | Pin versi; uji ulang L8, L16–L18 setiap upgrade |
| Layout papan 5×3 terlalu sempit di layar 16:9 | Skala kartu papan dapat dikonfigurasi; prototipe layout paling awal di Fase 5 |
| Rewind/checkpoint memuat ulang run | Memakai jalur load vanilla; diuji dengan save/load bolak-balik |
| `__eq` cdata vs number | Tes runtime di Fase 3; semua kode NE memakai `NE.Big.eq` |
| Performa ante akhir (angka hiper + banyak trigger) | Mutasi in-place, coroutine slicing, cache format |
