# New Era — Fase 0: Laporan Riset API & Source

Tanggal riset: 2026-09-24. Semua keputusan desain final ditunda ke Fase 1. Laporan ini hanya memetakan apa yang ada, apa yang disentuh, dan di mana risikonya.

## 0. Legenda verifikasi

| Tag | Arti |
|---|---|
| **[V]** | Terverifikasi langsung: saya baca di source vanilla 1.0.1o-FULL atau di source/dokumen yang di-clone (SMODS, Lovely, docs.smods.dev, Amulet, LuaJIT). Rujukan `file:baris` mengacu ke source vanilla. |
| **[T]** | Terverifikasi tidak langsung: baris/fungsi vanilla muncul sebagai `pattern` di patch Lovely SMODS/Amulet (pattern harus cocok persis dengan source vanilla), atau fungsi global vanilla itu di-wrap/didefinisikan ulang oleh mod referensi (SMODS/Amulet/Cryptid). Bukti kuat bahwa ia ada di 1.0.1o, tapi isi persisnya belum saya lihat. |
| **[B]** | **Belum terverifikasi**: dari pengetahuan umum tentang source Balatro. Wajib dicek terhadap source asli sebelum menulis patch. |

**Status source vanilla (revisi 2):** source Balatro dari salinan Anda sudah diterima dan dicek (`globals.lua`: `VERSION = '1.0.1o'..'-FULL'`). Source hanya diekstrak ke scratchpad lokal dan **tidak di-commit** ke repo ini. Hampir semua item yang sebelumnya [B] kini [V]. Temuan baru dari source ada di §4.6. Sisa yang belum terverifikasi ada di §9.

## 1. Versi target & sumber yang diperiksa

| Komponen | Versi / commit | Catatan |
|---|---|---|
| Balatro (Steam) | **1.0.1o-FULL** (live, terkonfirmasi dari source Anda) | Update **1.1** sedang dikembangkan (Joker baru, voucher Lunker, perubahan Blue Stake), belum ada tanggal rilis. Semua patch Lovely berisiko pecah saat 1.1 rilis. |
| Steamodded (SMODS) | rilis stabil **26.829.0**; `main` = `26.924.0~dev-a` (commit `eb98676`) | Skema versi baru berbasis tanggal. Docs pindah ke **docs.smods.dev** (repo `Steamodded/Wiki`, commit `3c44ed4`). Wiki GitHub lama sudah jadi stub "Moved". |
| Lovely | **0.10.0** (commit `073060e`) | Loader Windows sekarang `winmm.dll` (bukan `version.dll`). Manifest SMODS menuntut Lovely ≥ 0.9.0. |
| Talisman | commit `6bfa4b9` | **Deprecated**; README menyuruh pakai Amulet. |
| Amulet (fork Talisman) | 3.6.2 (commit `ab52577`) | OmegaNum berbasis **LuaJIT FFI cdata**. Referensi utama untuk big number. |
| Cryptid | 0.5.17~dev (commit `bf6723c`) | Sekarang bergantung pada **Amulet**, bukan Talisman. |
| LuaJIT docs | commit `c6ffc14` | Dipakai untuk memverifikasi semantik FFI (§5). |

## 2. Lovely: fakta yang relevan [V]

- **Jenis patch:** `pattern`, `regex`, `copy`, `module`. Field penting:
  - `pattern`: `target`, `pattern`, `position` (`before`/`after`/`at`), `payload`, `match_indent`, `times`, `overwrite`, `name`. Wildcard `*` dan `?`. Multi-baris didukung.
  - `regex`: `root_capture`, `line_prepend` (mis. `'$indent'`), `times`, `verbose`. README Lovely: regex lambat, pakai hanya jika pattern tidak cukup.
  - `copy`: `position` (append/prepend), `sources`, `payload`.
  - `module`: `source`, `name`, `before`, `load_now`. Hanya modul satu file.
- **Urutan penerapan per file target** (`patch/table.rs`): modul `load_now` → semua `copy` (urut prioritas) → semua `pattern`+`regex` (urut prioritas, stabil). **Prioritas kecil diterapkan lebih dulu.** SMODS memakai `priority = -10` dan `-5`.
  - **Implikasi:** patch New Era (prioritas ≥ 0) diterapkan **setelah** SMODS, jadi pattern kita harus cocok dengan teks **yang sudah dimodifikasi SMODS**. Ini justru menguntungkan: SMODS menyisipkan baris jangkar yang stabil, mis. `-- TARGET: add your own CardAreas for joker evaluation`.
- **Target file SMODS:** file Lua SMODS bisa dipatch dengan target buffer `=[SMODS _ "src/utils.lua"]` (contoh resmi di docs Calculate Functions). Shader SMODS juga melewati `lovely.apply_patches` dengan buffer `=[SMODS <mod_id> "<path>"]`.
- **Lokasi file:** `Mods/<Mod>/lovely.toml` dan/atau `Mods/<Mod>/lovely/*.toml` (diurut per nama file). Mod ZIP didukung. `.lovelyignore` di folder mod menonaktifkan patch-nya.
- **Debug:** hasil patch di-dump ke `Mods/lovely/dump`, log di `Mods/lovely/log`. Ini sumber kebenaran untuk melihat kode final setelah semua patch.
- **Stabilitas:** README: "patch format is unstable and prone to change". `manifest.version` belum diimplementasikan.

## 3. Steamodded: API yang relevan (ringkasan)

| API | Menutup kebutuhan | Catatan [V] |
|---|---|---|
| `SMODS.Rarity` | 3 rank kustom (Unranked/Demonic/Heavenly) | `key`, `pools`, `default_weight`, `get_weight(self, weight, object_type)`, `badge_colour` (bisa `SMODS.Gradient`), `disable_if_empty`. Bobot vanilla 0.7/0.25/0.05; rarity baru mengecilkan peluang rarity lain. Nama wajib di `misc.labels[key]` **dan** `misc.dictionary['k_'..key]`. Fungsi `gradient` di rarity **deprecated**. |
| `SMODS.ObjectType` / `ConsumableType` | Pool kustom (mis. per franchise, per rank) | Key ObjectType **tidak** diberi prefix otomatis. |
| `SMODS.Joker` | 121 joker | `calculate`, `loc_vars`, `set_ability`, `add_to_deck`, `remove_from_deck`, `in_pool`, `update(dt)`, `set_sprites`, `load`, `can_sell`, `draw(self, card, layer)`, `set_card_type_badge`, `attributes`, `blueprint_compat`, `eternal_compat`, dll. |
| `SMODS.PokerHand` / `SMODS.PokerHandPart` | Registry tipe hand baru (level, planet, UI) | Wajib `key, mult, chips, l_mult, l_chips, example, evaluate`. Urutan prioritas lewat `mult*chips`, `above_hand`, `order_offset`. `visible`, `modify_display_text`. **Tidak ada API untuk menghapus hand** (tidak ada `delete`). |
| `SMODS.Scoring_Parameter` | Mata uang per-hand (sejajar chips/mult) | `default_value`, `calculation_keys`, `hands` (nilai per hand + level), `modify`, `calc_effect`, `level_up_hand`. `SMODS.get_scoring_parameter(key, flames)`. |
| `SMODS.Scoring_Calculation` | Rumus skor (chips ∘ mult ∘ …) | `func(self, chips, mult, flames)`, `text`, `colour`, `config` (tersimpan), `parameters`, `replace_ui`, `update_ui`. Bawaan: `multiply`, `add`, `exponent`. `SMODS.set_scoring_calculation(key)`, `SMODS.calculate_round_score(flames)`. Disimpan lewat `SCORING_CALC = G.GAME.current_scoring_calculation:save()` di `save_run`. |
| `calculate` + contexts | Fase skor, reaksi joker, boss | Lihat §4.2. `SMODS.calculate_context(context, return_table, no_resolve)` untuk konteks buatan sendiri. `mod.calculate` = objek global yang ikut dihitung. |
| `SMODS.get_card_areas(_type, _context)` | Zona baru & blind tambahan ikut kalkulasi | Punya jangkar `-- TARGET:` untuk `playing_cards`, `jokers`, dan `individual`. Bisa juga di-wrap dari Lua tanpa Lovely. |
| `mod.custom_card_areas(game)` | Membuat CardArea baru pada titik yang benar | Dipanggil di `Game:start_run` sebelum load, jadi save/load area bekerja. |
| `mod.optional_features` | `retrigger_joker`, `post_trigger`, `quantum_enhancements`, `cardareas.deck/discard`, `object_weights` | `object_weights` merusak konsistensi seed vanilla. |
| `SMODS.Blind` | Boss/Big/Small kustom, boss multi-fase | `boss={min,max,showdown}`, `big`/`small` (baru di 26.829.0), `in_pool`, `set_blind`, `calculate`, `disable`, `defeat`, `press_play`, `recalc_debuff`, `debuff_hand`, `stay_flipped`, `modify_hand`, `drawn_to_hand`, `calc_dollar_bonus`. `config` disimpan di `G.GAME.blind.effect`. `SMODS.get_new_blind(type)`, `Blind:is_type/get_type`. |
| `SMODS.Shader` | Shader per kartu | File `assets/shaders/<key>.fs`; **key = nama file = nama shader di GLSL**. `send_vars(sprite, card)`. Divalidasi untuk OpenGL ES. |
| `SMODS.ScreenShader` | Post-processing layar penuh | `order`, `should_apply`, `send_vars` (dukung array), `draw(self, shader, canvas)`. **CRT vanilla sudah dipindah SMODS menjadi ScreenShader `order = 0`.** Pass memakai ping-pong `G.SHADER_CANVAS_A/B`. |
| `SMODS.DrawStep` | Menggambar kartu tanpa patch `Card:draw` | Urutan bawaan: shadow −1000, tilt −50, center −10, front 0, card_type_shader 10, edition 20, seal 30, stickers 40, canvas_text 45, soul 50, floating_sprite 60, debuff 70, greyed 80, others 90, sprite_particles 95, focused_ui 100. |
| `SMODS.CanvasSprite` | Cache render ke canvas | Sprite yang merender `love.Canvas`; bisa dipakai untuk cache layer statis. |
| `SMODS.SpriteParticle`, `AnimatedSprite`, `StateSprite`, `SMODS.Gradient`, `SMODS.DynaTextEffect`, `SMODS.Font` | Efek, teks, badge | Baru di 26.829.0: `StateSprite`, `SpriteParticle`, text outline, `SMODS.card_to_image`. |
| `SMODS.Keybind` | Hotkey debug | `key_pressed`, `action`, `event` (`pressed`/`released`/`held`), `held_keys`. |
| Config & UI mod | Opsi grafis New Era | `config.lua`, `mod.config_tab`, `SMODS.save_mod_config`, `mod.extra_tabs`, `mod.custom_collection_tabs`. |
| Util lain | — | `SMODS.change_play_limit(mod)`, `SMODS.change_discard_limit(mod)`, `SMODS.draw_cards(n)`, `SMODS.scale_card`, `SMODS.reset_card`, `SMODS.destroy_cards`, `SMODS.pseudorandom_probability`, `SMODS.mod_score`, `SMODS.mod_blind_size`, `SMODS.upgrade_poker_hands`, `SMODS.is_active_blind`. |

Metadata mod: file `<id>.json` dengan `id`, `name`, `author`, `description`, `prefix`, `main_file`, `priority`, `version`, `dependencies`, `conflicts`, `provides`, `badge_colour`, `badge_shader` (baru), `icon_path`. Contoh dependensi versi game: `"Balatro (==1.0.1m)"`.

## 4. Pemetaan per sistem

### 4.1 `hand_system` — evaluator baru

**Temuan kunci [V]:** SMODS sudah **meng-override penuh** `evaluate_poker_hand`, `G.FUNCS.get_poker_hand_info`, `create_UIBox_current_hands`, dan `G.FUNCS.your_hands_page` (`src/overrides.lua`). Hand vanilla sendiri didaftarkan ulang sebagai `SMODS.PokerHand`. Jadi titik ganti evaluator ada di **SMODS**, bukan di vanilla.

Tabel keputusan awal (final di Fase 1):

| Fungsi / data | Lokasi | Usulan | Alasan |
|---|---|---|---|
| `evaluate_poker_hand(hand)` | override SMODS (asal: `functions/misc_functions.lua`) | **WRAP/REPLACE** oleh evaluator New Era. Keluaran tetap berbentuk `results[hand_key] = { {cards...}, ... }` plus `top`. | Banyak konsumen (joker, blind, context SMODS) mengindeks `poker_hands[key]`. Bentuk data dipertahankan agar semua hook tetap jalan. |
| `G.FUNCS.get_poker_hand_info(_cards)` | override SMODS | **WRAP**. Mengembalikan `text, loc_disp_text, poker_hands, scoring_hand, disp_text`. | Sudah punya context `evaluate_poker_hand` dengan flag `replace_scoring_name`, `replace_display_name`, `replace_poker_hands`. |
| Registry hand | `SMODS.PokerHand` | **KEEP** sebagai registry tipe hand New Era. Setiap hand New Era = satu `SMODS.PokerHand`; `evaluate` membaca hasil evaluator yang di-cache per evaluasi. | Level, `G.GAME.hands`, planet, UI, save sudah gratis. |
| `G.handlist` (urutan prioritas) | buffer SMODS | **KEEP**, atur via `order_offset`/`above_hand`. | Hand pertama yang cocok = hand yang dimainkan. |
| `G.GAME.hands[...]` | `Game:init_game_object` (di-wrap SMODS, menyalin field number/boolean) | **KEEP**, tambah konversi big number setelah init (Amulet melakukan hal serupa). | Disimpan otomatis bersama `G.GAME`. |
| Hand vanilla (Pair … Flush Five) | `SMODS.PokerHand` | **Sembunyikan** (`visible=false`, `evaluate` → `{}`) lewat `take_ownership`, atau jadikan subset. | Tidak ada API hapus. Perlu keputusan Anda (§10). |
| `level_up_hand(card, hand, instant, amount)` [V] | `functions/common_events.lua:464` | **WRAP** (big number + mata uang). | SMODS sudah menambah param `statustext` dan level-up per Scoring_Parameter. |
| `update_hand_text(config, vals)` [V] | `functions/common_events.lua:495` | **WRAP** (format big number, mata uang, delta). | Memuat `type(...) == 'number'` yang harus dipatch untuk tipe big (Amulet `typefix.toml`). |
| Planet: `Card:use_consumeable` → `self.ability.consumeable.hand_type` → `level_up_hand` [V] | `card.lua` | **KEEP mekanisme**; planet New Era = consumable dengan `config.hand_type` = key hand baru. Planet vanilla disembunyikan via `in_pool`. | [V] Blue Seal (`card.lua:1040`) dan Telescope (`card.lua:1737`) mencari planet lewat `G.P_CENTER_POOLS.Planet` dengan `config.hand_type` yang sama, jadi otomatis bekerja dengan hand baru. Telescope hanya memilih hand dengan `G.GAME.hands[v].visible`. Black Hole menaikkan level semua hand (`card.lua:1153`). |
| Debuff blind berdasar hand | `Blind:debuff_hand` (`blind.lua:519`), `Blind:modify_hand` (`blind.lua:510`), keduanya di-override SMODS; `config.debuff.hand/h_size_ge/h_size_le`; context `debuff_hand`/`modify_hand` | **WRAP**; boss New Era memakai context. | [V] Boss vanilla yang bergantung pada hand: **The Eye** (`self.hands[handname]`), **The Mouth** (`only_hand`), **The Ox** (`most_played_poker_hand` → uang jadi 0), **The Arm** (level −1), **The Psychic** (`debuff.h_size_ge = 5`), **The Flint** (`modify_hand`: chips & mult dibagi 2). Perlu dinonaktifkan atau diadaptasi. |
| "Most played hand" | `G.GAME.current_round.most_played_poker_hand` [V] dihitung di `end_round` (`state_events.lua:87`) hanya setelah Boss, dari `v.played` lalu `v.order` | **KEEP**; bekerja otomatis selama hand baru ada di `G.GAME.hands`. Nilai awal `'High Card'` di-hardcode → harus di-wrap jika High Card disembunyikan. | |
| Joker vanilla yang bergantung nama hand | `Card:calculate_joker` (card.lua) | **Keputusan Anda**: default usulan = keluarkan dari pool. | [V] `config.type` = nama hand: Jolly/Zany/Mad/Crazy/Droll, Sly/Wily/Clever/Devious/Crafty, The Duo/Trio/Family/Order/Tribe (`game.lua:373-510`). Kode khusus: Spare Trousers, Runner, To Do List, Obelisk, Supernova, Superposition, Seance, Card Sharp, Space Joker (`level_up`), Burnt Joker (memanggil `get_poker_hand_info` pada kartu yang dibuang lalu `level_up_hand`). |
| Primitif `get_flush` (`misc_functions.lua:522`), `get_straight` (`:548`, di-override SMODS), `get_X_same` (`:592`), `get_highest` (`:613`) [V] | `misc_functions.lua` | **KEEP** sebagai primitif di dalam evaluator. | Sudah menghormati Four Fingers/Shortcut/wrap via `SMODS.four_fingers` dll. |
| Batas kartu dimainkan (5) | `SMODS.change_play_limit`, `SMODS.change_discard_limit` [V] | **KEEP/pakai**. | Board & multi-hand butuh batas berbeda. |
| `G.FUNCS.evaluate_play` [V] | `functions/state_events.lua:571` (~560 baris) | **WRAP**, jangan ganti total. | Dipatch berat oleh SMODS (`better_calc.toml`, `scoring_calculation.toml`, `poker_hand.toml`, `enhancement.toml`). Mengganti total merusak semua patch SMODS di atasnya. |

**Posisi di board:** evaluator butuh akses ke posisi kartu. `evaluate_poker_hand(hand)` hanya menerima list kartu, jadi evaluator New Era membaca slot dari `card.ability` (atau dari area board) di dalam wrapper; tidak perlu mengubah signature.

### 4.2 `scoring` — skor tanpa batas, hiperoperator, fase baru

**Pipeline SMODS [V/T]:** di `G.FUNCS.evaluate_play` urutannya: `modify_scoring_hand` → `before` → `initial_scoring_step` → per area kartu `SMODS.calculate_main_scoring` (`main_scoring`, `individual`, `repetition`) → edisi `pre_joker` → `joker_main` + `other_joker` → edisi `post_joker` → `final_scoring_step` → `destroy_card` → `remove_playing_cards` → `after`. Skor akhir: `SMODS.calculate_round_score()` menggantikan setiap `hand_chips * mult` di `state_events.lua` (regex SMODS).

Return key bawaan [V]: `chips`, `mult`, `xmult`, `xchips`, `dollars`, `score`, `xscore`, `blindsize`, `xblindsize`, `swap`, `balance`, `level_up`, `saved`, `message`, `func`, `pre_func`, `extra`, `effect`, `no_juice`, `remove_default_message`.

Titik ekstensi:
- **Operator baru (^Mult, ^^Mult, {n}Mult):** `SMODS.calculate_individual_effect` (utils.lua:1299) diberi komentar "Can easily be hooked to add more calculation effects ala Talisman" [V]. Key baru didaftarkan lewat `calculation_keys` pada `Scoring_Parameter` (mis. `take_ownership` param `mult`/`chips`, atau param baru).
- **Rumus skor:** `SMODS.Scoring_Calculation` baru (mis. `ne_hyper`) yang mengembalikan big number.
- **Fase skor baru:** `SMODS.calculate_context({ne_<phase> = true, ...})` disisipkan via patch Lovely berjangkar pada baris sisipan SMODS (mis. setelah `SMODS.calculate_context({initial_scoring_step = true, ...})`). Prioritas patch ≥ 0 agar jalan setelah SMODS.
- **Mata uang (divinity, corruption, time):** dua jenis. (a) Per-hand → `SMODS.Scoring_Parameter`, dapat UI & `level_up` gratis. (b) Per-run (seperti dollar) → state di `G.GAME.newera`, UI HUD sendiri, dan context seperti `money_altered` versi New Era.

Titik vanilla yang menyentuh angka skor (wajib aman big number):

| Fungsi / baris | File | Bukti |
|---|---|---|
| `number_format(num)` | `functions/misc_functions.lua:956` | [V]. Vanilla hanya 1 parameter; `G.E_SWITCH_POINT = 100000000000` (1e11). Di atasnya pakai `string.format("%.4g")` → notasi `x.xxxeN`. Mengembalikan `num` apa adanya jika bukan `'number'`. |
| `scale_number(number, scale, max)` | `functions/button_callbacks.lua:1905` | [V] (bukan misc_functions) |
| `score_number_scale(scale, amt)` | `misc_functions.lua:967` | [V] memakai `type(amt) ~= 'number'` dan `math.log(amt)` |
| `get_blind_amount(ante)` | `misc_functions.lua:919` | [V]. Tabel 300…50000 (scaling 1), 300…100000 (scaling 2), dan scaling 3; ante > 8: `floor(a*(1.6+(0.75*c)^d)^c)` dengan `d = 1+0.2c`, lalu dibulatkan. Tumbuh super-eksponensial → melewati batas double (~1,8e308) tepat di **Ante 39** untuk ketiga scaling (dihitung dari rumus). |
| `Blind:set_blind` → `self.chips = get_blind_amount(ante)*self.mult*G.GAME.starting_params.ante_scaling` | `blind.lua:78,107` | [V] |
| `check_and_set_high_score` (`misc_functions.lua:1017`), `inc_career_stat` (`:1427`) | misc_functions | [V]; menulis ke profil |
| `mod_chips` (`:684`), `mod_mult` (`:691`) | misc_functions | [V]; dipatch SMODS |
| `ease_chips(mod)` | `common_events.lua:41` | [V] |
| `update_hand_text` delta (`type(vals.chips) == 'number'`) | `common_events.lua:495` | [V] |
| `G.ARGS.score_intensity.earned_score = ...chips*...mult` dan `math.log(earned/(required+1), 5)` | `modulate_sound` (`misc_functions.lua:719`), **dipanggil setiap frame** dari `Game:update`; hasilnya dipakai efek api (`button_callbacks.lua:2021`) | [V]. Dengan tipe big, ini operasi big + alokasi **per frame** → harus di-cache atau dihitung sebagai log10 biasa. |
| `card_eval_status_text(card, eval_type, amt, percent, dir, extra)` | `common_events.lua:779` | [V] |
| Skor ditambahkan lewat Event `trigger = 'ease'` pada `G.GAME.chips` dengan `ease_to = G.GAME.chips + math.floor(hand_chips*mult)` | `state_events.lua:1049` | [V]. Interpolasi di `engine/event.lua:58-81` memakai aritmetika biasa (`percent*start + (1-percent)*end`) → harus aman untuk tipe big. |
| Teks skor: `number_format(G.GAME.chips)` + `scale_number` hanya saat teks berubah (`G.GAME.chips_text`) | `button_callbacks.lua:1892` | [V] |
| Perbandingan menang/kalah `G.GAME.chips - G.GAME.blind.chips >= 0` | `game.lua:3196` (`Game:update_hand_played`), `state_events.lua:96` (`end_round`), `state_events.lua:1139` (`G.FUNCS.evaluate_round`), `blind.lua:400` | [V]. Empat lokasi, semuanya pengurangan lalu `>= 0` → tipe big wajib mendukung `-` dan `>=` campuran. |
| Kode SMODS sendiri: `amount > 0`, `math.abs(amount)`, `amount ~= 1`, `hand_chips * (amount - 1)` | `src/game_object.lua` (Scoring_Parameter) | [V]. Berfungsi dengan tipe big **hanya jika** perbandingan campuran number/big didukung (lihat §5). |

### 4.3 `run_structure` — map, multi-blind, ante tak terbatas

Vanilla yang terlibat:
- **State machine [V]:** `self.STATES = {` di `globals.lua:284` berisi `SELECTING_HAND=1, HAND_PLAYED=2, DRAW_TO_HAND=3, GAME_OVER=4, SHOP=5, PLAY_TAROT=6, BLIND_SELECT=7, ROUND_EVAL=8, TAROT_PACK=9, PLANET_PACK=10, MENU=11, TUTORIAL=12, SPLASH=13, SANDBOX=14, SPECTRAL_PACK=15, DEMO_CTA=16, STANDARD_PACK=17, BUFFOON_PACK=18, NEW_ROUND=19`. Komentar vanilla: `SPLASH = 13 --DO NOT CHANGE` (dipakai sound manager). `Game:update` (`game.lua:2449`) memakai rantai `if self.STATE == self.STATES.X then self:update_x(dt) end`. Setiap `update_*` memakai flag `G.STATE_COMPLETE` agar logika masuk-state hanya jalan sekali. SMODS menambah `SMODS_BOOSTER_OPENED = 999`, `SMODS_REDEEM_VOUCHER = 998` dengan regex ke `self.STATES = {` — templat untuk state `NE_MAP` (pakai angka unik, mis. 1000+).
- **Blind [V]:** `G.GAME.round_resets.blind_states` (`Small/Big/Boss` → `'Select'/'Upcoming'/'Current'/'Defeated'/'Skipped'`), `G.GAME.blind_on_deck`, `G.GAME.round_resets.blind_choices`, `get_new_boss()` (`common_events.lua:2338`), `reset_blinds()` (`:2326`), `create_UIBox_blind_select()` (`UI_definitions.lua:1417`), `G.FUNCS.select_blind` (`button_callbacks.lua:2513`), `G.FUNCS.skip_blind` (`:2740`), `Game:update_blind_select` (`game.lua:3258`, memanggil `save_run()` saat masuk state), `end_round()` (`state_events.lua:87`), `new_round()` (`:290`), `ease_ante(mod)` (`common_events.lua:191`). Kemenangan run: `G.GAME.round_resets.ante == G.GAME.win_ante and G.GAME.blind:get_type() == 'Boss'` di `end_round`.
- **Blind tunggal [V]:** `G.GAME.blind = Blind(0,0,2,1)` dibuat sekali di `Game:start_run` (`game.lua:2392`) lalu dipakai ulang lewat `Blind:set_blind(blind, reset, silent)`. Dirujuk di HUD (`create_UIBox_HUD_blind`, `UI_definitions.lua:1210`), `Game:update` (peringatan boss), `SMODS.get_card_areas('individual')`, dan `save_run` (`BLIND = G.GAME.blind:save()`).

SMODS yang membantu: `SMODS.Blind` (boss/big/small kustom, `in_pool`), `SMODS.get_new_blind`, context `setting_blind`, `blind_disabled`, `blind_defeated`, `modify_ante`, `ante_change`, `round_eval`, `end_of_round` (+`saved`), `skip_blind`, return `blindsize`/`xblindsize`, `SMODS.mod_blind_size`.

Butuh Lovely:
1. State `NE_MAP` + dispatch update + layar map (UIBox). Semua **whitelist state** vanilla/SMODS (mis. `can_use_consumeable`, `CardArea:align_cards`, `G.FUNCS.use_card`, titik `save_run`) harus diaudit. Untuk menambah satu state booster saja, SMODS butuh 17 rujukan `SMODS_BOOSTER_OPENED` di patch-nya [V].
2. **Multi-blind:** jangan memecah `G.GAME.blind`. Pendekatan aman: `G.GAME.blind` tetap jadi **facade** (blind "utama" untuk HUD & kompatibilitas SMODS), blind tambahan disimpan di `G.GAME.newera.blinds` dan ikut kalkulasi via jangkar `-- TARGET: add your own individual scoring targets` di `SMODS.get_card_areas`. Syarat menang/kalah, HUD, dan hadiah uang dipatch.
3. **Boss prosedural:** objek `SMODS.Blind` didaftarkan statis saat load, jadi generator = beberapa `SMODS.Blind` "cangkang" + parameter per-instans di `G.GAME.blind.effect` **dan** seed/parameter di `G.GAME.newera` untuk rekonstruksi. [V] `Blind:save()` vanilla (`blind.lua:684`) hanya menyimpan `name, dollars, debuff, pos, mult, disabled, discards_sub, hands_sub, boss, config_blind, chips, chip_text, hands, only_hand, triggered`. SMODS menambahkan `effect` ke save/load (`lovely/blind.toml`). Field kustom lain di objek Blind **hilang** saat load.
4. **Ante tak terbatas:** README Talisman: vanilla mentok di sekitar Ante 39 ("naneinf", batas ~1e308) [V]. `get_blind_amount` harus mengembalikan big number. Nilai ante sendiri cukup Lua number.

### 4.4 `card_zones` — board/grid & multi-hand

- `CardArea(X, Y, W, H, config)` dengan `config.type` ∈ `hand`, `joker`, `deck`, `discard`, `play`, `shop`, `title`, `voucher`, `consumeable` [V, `cardarea.lua`], `card_limit`, `highlight_limit`. Catatan: `G.consumeables` vanilla bertipe `'joker'`, bukan `'consumeable'` (`game.lua`).
- **Layout [V]:** `CardArea:align_cards()` (`cardarea.lua:410`) punya cabang per `config.type`. Setelah drag, urutan kartu disusun ulang dengan `table.sort(self.cards, by T.x)` (1D). **Tipe baru tanpa cabang tidak akan menata kartunya sama sekali**, jadi board wajib punya `align_cards` sendiri.
- **Pembuatan & save/load [V]:** `mod.custom_card_areas(game)` dipanggil SMODS setelah area vanilla dibuat. `save_run()` (`misc_functions.lua:1452`) mengiterasi **semua** field `G` yang `is(CardArea)` dan memanggil `:save()` (menyimpan `cards` + `config`). `Game:start_run` memanggil `G[k]:load(v)` untuk tiap area. Jika `G[k]` belum ada, data dibuang ke `G['load_'..k]` dan dicetak `ERROR LOADING GAME`. Karena `config` ikut disimpan, data layout board bisa ditaruh di `config`.
- **Ikut kalkulasi:** jangkar `-- TARGET` di `SMODS.get_card_areas('playing_cards'/'jokers')` [V].
- **Grid:** `CardArea` pada dasarnya list 1D dengan `align_cards` yang menata satu baris. Dua opsi (diputuskan di Fase 1): (a) N CardArea per baris (paling kompatibel dengan drag/save/controller); (b) subclass `CardArea` dengan slot tetap (`align_cards` & drop logic sendiri, posisi di `card.ability.ne_slot`).
- **Multi-hand:** `G.hand` adalah singleton yang dirujuk langsung di banyak tempat (`G.hand.highlighted`, `draw_card(G.deck, G.hand, …)`, `G.FUNCS.draw_from_deck_to_hand` (`state_events.lua:355`) [V], `G.hand.config.card_limit`, `SMODS.draw_cards`). SMODS saja punya 7 cek `config.type == 'hand'` [V]. Usulan: satu `G.hand` "aktif" + hand lain sebagai area `type='hand'` yang di-swap, bukan menduplikasi logika.
- **Drag, seleksi, controller:** ditangani `engine/controller.lua` + `card.states.drag` + `CardArea:can_highlight` (`cardarea.lua:113`) [V]. Vanilla hanya mengenal urutan 1D, jadi drop ke slot grid butuh logika sendiri. Navigasi controller antar-baris grid juga belum diperiksa rinci (§9).

### 4.5 `rendering` — shader, post-process, pseudo-3D, animasi

Vanilla [V]:
- 19 shader di `resources/shaders`: `CRT`, `background`, `booster`, `debuff`, `dissolve`, `flame`, `flash`, `foil`, `gold_seal`, `holo`, `hologram`, `negative`, `negative_shine`, `played`, `polychrome`, `skew`, `splash`, `vortex`, `voucher`. Semua dimuat saat start-up ke `G.SHADERS[name]` (`game.lua:133`).
- `Sprite:draw_shader(_shader, _shadow_height, _send, _no_tilt, other_obj, ms, mr, mx, my, custom_shader, tilt_shadow)` (`engine/sprite.lua:73`). Setiap panggilan mengirim **10 uniform**: `mouse_screen_pos`, `screen_scale`, `hovering`, `dissolve`, `time`, `texture_details`, `image_details`, `burn_colour_1`, `burn_colour_2`, `shadow`. `_send` dikirim ke extern yang **namanya sama dengan nama shader** (mis. `extern vec2 foil`). Dengan `custom_shader = true`, hanya `_send` (list `{name, val|func|ref_table/ref_value}`) yang dikirim.
- Extern `time` di shader kartu **bukan waktu nyata**, melainkan konstanta per kartu (`123.33412*(ID/1.14212)%3000`). Animasi edisi memakai `self.ARGS.send_to_shader = {rotasi + G.TIMERS.REAL/28 + juice + tilt, G.TIMERS.REAL}` (`card.lua:4348`) yang dikirim lewat `_send`.
- **Pseudo-3D bawaan:** bagian `#ifdef VERTEX` tiap shader kartu menggeser komponen `w` posisi verteks berdasarkan jarak ke `mouse_screen_pos` × `hovering` (lihat `foil.fs`). Uber-shader kita wajib menyertakan fungsi `position()` yang sama agar tilt tetap konsisten.
- `Game:draw` (`game.lua:2732`): semua node digambar ke `G.CANVAS` (skala `G.CANV_SCALE`), lalu dipindah ke layar/`G.AA_CANVAS` dengan shader `CRT` (di SMODS diganti pipeline ScreenShader). Background run = `G.SPLASH_BACK` dengan shader `background` (extern `time`, `spin_time`, `colour_1..3`, `contrast`, `spin_amount`) → titik kait yang pas untuk **background reaktif**.

SMODS [V]: pipeline post-process sudah ada. CRT = ScreenShader `order 0`; efek kita memakai `order < 0` (sebelum CRT) atau `> 0` (sesudah CRT). **Setiap ScreenShader = satu pass penuh layar di canvas readable seukuran `G.CANVAS`.** Karena itu bloom/chromatic/distortion/glitch sebaiknya **digabung jadi satu uber-pass**, bukan empat pass.

Joker prosedural:
- `SMODS.Joker` tetap butuh atlas/pos → pakai atlas 1-sprite kosong/dasar.
- Gambar via `SMODS.DrawStep` (mis. order 15, setelah `card_type_shader`) yang memanggil `draw_shader` dengan satu **uber-shader** (`SMODS.Shader`) + parameter per joker lewat `send_vars(sprite, card)`.
- `Card:should_draw_base_shader()` di-override SMODS [V] dan bisa dipakai untuk mematikan shader dasar.

Animasi kemampuan: `G.E_MANAGER:add_event(Event{trigger, delay, blocking, blockable, func, timer, no_delete})`, queue kustom `G.E_MANAGER.queues.<nama>` untuk overlay yang tidak memblokir skor [V].

Pengaturan yang wajib dihormati [V]:
- `G.SETTINGS.reduced_motion`. Efek bawaannya: `G.TIMERS.REAL_SHADER` dibekukan di 300 (`game.lua` di `Game:update`), tilt kartu dimatikan di `Sprite:draw_shader`, goyangan idle kartu dinolkan di `align_cards`, dan spin background di-nol-kan. Shader New Era sebaiknya memakai `G.TIMERS.REAL_SHADER`, bukan `G.TIMERS.REAL`, agar ikut aturan ini.
- `G.SETTINGS.screenshake`: slider 0–100 (`UI_definitions.lua:2305`), default 50 (0 bila reduced motion). Diterapkan di `update_canvas_juice` (`common_events.lua:1127`): guncangan = `G.ROOM.jiggle` × `screenshake/100*3`, nol jika reduced motion. **Tambahkan guncangan hanya lewat `G.ROOM.jiggle`** agar otomatis patuh.
- `G.SETTINGS.GRAPHICS.crt`, `G.SETTINGS.GRAPHICS.bloom`, `G.SETTINGS.GRAPHICS.shadows`, `G.SETTINGS.GAMESPEED`.

### 4.6 Temuan baru dari source vanilla (revisi 2) [V]

1. **GC dimatikan, diganti anggaran per frame.** `Game:update` memanggil `nuGC(nil, nil, true)` tiap frame (`misc_functions.lua:645`): GC inkremental maksimal **0,3 ms** atau 1000 step per frame, lalu `collectgarbage("stop")`. Jika heap > **300 MB**, dipaksa `collectgarbage("collect")` (full GC → stutter). Artinya setiap alokasi per frame (tabel, closure, string, objek big number) langsung menggerus anggaran ini. Ini alasan teknis utama untuk aturan "tanpa alokasi per frame".
2. **Serializer save tidak aman untuk inf/nan dan presisi.** `STR_PACK` (`engine/string_packer.lua`) menulis angka lewat konkatenasi `i.."="..v`. `math.huge` menjadi teks `inf`, NaN menjadi `nan`/`-nan`; saat dimuat (`loadstring`) keduanya dibaca sebagai variabel global yang tidak ada → nilai jadi `nil`. Konversi angka ke string di Lua/LuaJIT memakai `%.14g` [B untuk format persisnya], jadi presisi di atas 14 digit hilang. Kesimpulan: big number harus diserialisasi sebagai data eksplisit (mis. string `%.17g` atau array), dan **tidak boleh ada inf/nan di `G.GAME`**.
3. **Alur save [V]:** `save_run()` → `recursive_table_cull` (objek `Object` diganti string `"MANUAL_REPLACE"`, metatable hilang) → `G.ARGS.save_run`. `Game:update` mengirim ke thread `G.SAVE_MANAGER.channel` saat dipaksa, saat stage/pause berubah, atau tiap `G.F_SAVE_TIMER` (30 dtk). Thread menjalankan `STR_PACK`, deflate, lalu menulis `<profile>/save.jkr`. `save_run` dipanggil saat masuk `SELECTING_HAND`, `SHOP`, `BLIND_SELECT`, `ROUND_EVAL`, dan di beberapa tombol (`select_blind`, `skip_blind`, dll.).
4. **Load mengembalikan state apa adanya:** `Game:start_run` → `self:prep_stage(G.STAGES.RUN, saveTable.STATE)`. State `NE_MAP` yang tersimpan akan langsung aktif setelah load dengan `G.STATE_COMPLETE = false`, jadi `update_ne_map` harus mampu membangun ulang UI murni dari `G.GAME.newera`.
5. **`Card:save` [V]** menyimpan `ability` utuh (state joker aman selama data polos), `base`, `edition`, `seal`, `params`, dan `sort_id`. Dua jebakan:
   - Ada typo vanilla `highlighted = self.highligted`, jadi status highlight **tidak pernah tersimpan**.
   - `sort_id` berasal dari counter global `G.sort_id` yang **tidak disimpan**, sehingga bisa bentrok setelah load. Untuk referensi antar-kartu (Hisoka, Mikasa, Bungee Gum, dll.) pakai UID sendiri di `card.ability`, dengan counter di `G.GAME.newera`.
6. **JIT:** `jit.off()` hanya di thread save/sound/http pada macOS ARM. Thread utama tetap memakai JIT. FFI dipakai Amulet di produksi, jadi tersedia di runtime Balatro [T].
7. **Titik skor & menang:** lihat tabel §4.2 (empat lokasi `G.GAME.chips - G.GAME.blind.chips >= 0`, dan skor ditambahkan lewat Event `ease`).

## 5. Big number: riset desain (tanpa dependensi)

**Talisman (deprecated)** memakai tabel ber-metatable (`BigNum` dan port `OmegaNum.js`). README-nya mengakui: "comparison operations with numbers used by scoring will not work by default". Penyebabnya: di Lua 5.1, `__lt`/`__le` hanya dipanggil bila kedua operand bertipe sama. `5 < big_table` → error [B: semantik standar Lua 5.1].

**Amulet (penerus)** memindahkan OmegaNum ke **LuaJIT FFI cdata** [V]:
- `struct TalismanOmega { double asize; double number; int8_t sign; bool _nan; bool _inf; }` + array hiper-eksponen disimpan di tabel weak-key `bigs[obj]`.
- Cache per-frame untuk mengurangi alokasi.
- Metatype `__lt/__le/__eq/__tostring/__concat` + aritmetika.

**Semantik LuaJIT terverifikasi [V, `ext_ffi_semantics.html`]:** "All standard Lua operators can be applied to cdata objects or a mix of a cdata object and another Lua object… The predefined operations are always tried first before deferring to a metamethod". Untuk struct tidak ada operasi bawaan, jadi `big < 5`, `5 < big`, `big + 1` memanggil metamethod. Ini alasan utama memilih cdata.

Peringatan dari dokumen yang sama:
- cdata **tidak cocok sebagai key tabel** (identitas alamat, bukan nilai).
- `==` antara cdata dan non-cdata "treats the two sides as unequal" untuk perbandingan yang tak kompatibel. Apakah `__eq` metatype dipanggil saat `big == 0` **belum terverifikasi** [B] → harus diuji di runtime. Kode kita wajib memakai `NE.Big.eq(a, b)` eksplisit untuk kesamaan.

Titik yang disentuh Amulet (checklist minimal untuk lib kita) [V]:
- `number_format`, `score_number_scale`, `get_blind_amount`, `check_and_set_high_score`, `inc_career_stat`, `scale_number`.
- `math.floor/ceil/log/log10/exp/sqrt/abs/max/min/sin/cos` di-wrap.
- Patch `typefix` untuk cek `type(x) == 'number'`.
- Konversi `G.GAME.hands[*]` setelah `init_game_object`.
- Serialisasi di `engine/string_packer.lua` (`STR_PACK`) dan di baris `MANUAL_REPLACE` (`misc_functions.lua`).
- Sanitasi sebelum data dikirim ke **thread save** (`G.FILE_HANDLER`, `G.SAVE_MANAGER.channel:push` di `Game:update` [V]). Thread save (`engine/save_manager.lua`) hanya me-`require` `engine/object` dan `engine/string_packer`, jadi library big number **tidak ada** di sana; data wajib sudah polos sebelum dikirim [V]. Amulet juga menyalin & mensanitasi data khusus untuk thread (`copy_for_thread`) [V]. Apakah channel LÖVE bisa membawa cdata sama sekali [B] tidak penting lagi karena datanya tetap harus polos.
- Profil disimpan sebagai Lua number (di-clamp) agar profil tetap kompatibel dengan vanilla.

**Konflik:** Amulet mendaftarkan global `Big`, `to_big`, `is_big`, `OmegaMeta`, `B`, `Talisman` dan `provides: Talisman`. New Era harus memakai namespace sendiri (`NE.Big`) dan mendeklarasikan `conflicts` terhadap Talisman/Amulet/Cryptid, karena dua lib big number akan saling menimpa `number_format`/`math.*`.

## 6. Save/load

- `G.GAME` disimpan utuh lewat `recursive_table_cull` + `STR_PACK` [V]. Semua data New Era (map, mata uang, blind tambahan, seed boss) sebaiknya berada di `G.GAME.newera` sebagai **data polos** (number/string/boolean/tabel tanpa metatable). Objek `Object` di dalam `G.GAME` akan berubah menjadi string `"MANUAL_REPLACE"`. Nilai inf/nan akan menjadi `nil` saat load (§4.6).
- Big number: diubah ke bentuk polos (mis. `{__ne_big = true, sign, array}`) sebelum save, lalu di-rehydrate setelah load di `Game:start_run` (`saveTable`).
- State joker: `card.ability.extra` tersimpan otomatis bila berisi data polos [V: pola `config`/`ability` SMODS]. Referensi ke objek (kartu lain, area) harus disimpan sebagai ID, lalu di-resolve ulang saat load. SMODS memakai pola yang sama untuk `SMODS.last_hand` (`card.ability['SMODS_'..v]` → rekonstruksi) [V].
- CardArea baru: dibuat di `mod.custom_card_areas` agar ada sebelum load [V].
- State `NE_MAP`: `save_run` menyimpan `STATE = G.STATE` dan `start_run` mengembalikannya langsung [V]. Kita perlu memanggil `save_run()` sendiri saat masuk `NE_MAP` (seperti `update_blind_select`).
- Referensi antar-kartu: pakai UID sendiri, bukan `sort_id` (§4.6).
- Scoring Calculation aktif tersimpan otomatis (`SCORING_CALC`) [V].

## 7. Performa (60 FPS)

- **Anggaran GC vanilla = 0,3 ms/frame, full GC paksa di 300 MB** (§4.6). Semua sistem New Era harus nyaris nol alokasi per frame di jalur panas (update, draw, loop skor).
- `Sprite:draw_shader` mengirim 10 uniform + `setShader` dua kali per sprite. Dengan puluhan kartu ber-shader kustom, jumlah panggilan ini yang harus dijaga, bukan kompleksitas GLSL-nya saja.

- Tiap `SMODS.ScreenShader` = satu full-screen pass dengan canvas readable → gabungkan efek menjadi satu uber-pass post-process; nonaktifkan pass saat tidak perlu via `should_apply`.
- Uber-shader kartu: satu `G.SHADERS` untuk semua joker, parameter via `send`. `setShader` dan pengiriman uniform tetap terjadi per kartu (draw tree Balatro menggambar kartu satu per satu), jadi batasi animasi berat pada kartu yang di-hover atau sedang trigger; sisanya parameter statis.
- Layer statis → cache ke canvas (`SMODS.CanvasSprite`), render ulang hanya saat berubah.
- Big number: operasi cdata tetap mengalokasi objek GC. Gunakan akumulator yang bisa dipakai ulang di loop skor. Format string hanya saat nilai berubah (SMODS sudah memakai pola `G.GAME.chips_text`/`G.SCORE_DISPLAY_QUEUE`).
- Jangan panggil `UIBox:recalculate()` per frame.
- Untuk ribuan trigger, Amulet memecah `evaluate_play` menjadi coroutine agar frame tidak membeku (`talisman/coroutine.lua`) [V]. Kita kemungkinan butuh mekanisme serupa untuk ante akhir.

## 8. Pitfall yang sudah diketahui

1. Patch New Era berjalan setelah SMODS: pattern harus cocok dengan kode hasil patch SMODS. **Pin versi SMODS** (rilis 26.829.0 atau rilis berikutnya yang kita uji) dan cek `Mods/lovely/dump` setiap upgrade.
2. Update Balatro 1.1 akan mengubah source; semua patch harus dicek ulang saat rilis (pattern ditulis terhadap 1.0.1o-FULL).
3. Menambah state baru menyentuh banyak whitelist `G.STATE == …`; yang terlewat = soft-lock.
4. `G.GAME.blind` dan `G.hand` adalah singleton; memecahnya merusak SMODS dan HUD → gunakan facade/swap.
5. `SMODS.PokerHand` tidak bisa dihapus; hand vanilla hanya bisa disembunyikan/dinonaktifkan.
6. Menambah rarity mengubah distribusi rarity lain; bobot shop harus dirancang ulang secara keseluruhan.
7. Big number: cek `type(x) == 'number'`, cdata sebagai key tabel, `==` campuran, `math.*`, `string.format('%d')`, `tostring`, pengiriman ke thread save, dan profil.
8. inf/nan: vanilla menampilkan "naneinf". Setiap pembagian/log harus dijaga, dan lib wajib punya normalisasi NaN/Inf.
9. `object_weights` SMODS dan RNG kustom merusak konsistensi seed vanilla (masih bisa diterima karena New Era standalone, tapi seed antar-versi mod bisa berubah).
10. Shader harus lolos validasi OpenGL ES (SMODS memberi peringatan) dan tidak memakai fitur GLSL di luar dukungan LÖVE 11.
11. Joker #111 Chara ("mengancam save file"): **wajib ilusi**. Tidak boleh pernah menulis/menghapus file save nyata. Ini batasan teknis dan keamanan, bukan perubahan roster.
12. **inf/nan di data save** berubah menjadi `nil` saat load (`STR_PACK`), dan angka biasa hanya disimpan ±14 digit (§4.6).
13. **GC dimatikan vanilla**; alokasi per frame berujung full GC paksa di 300 MB (§4.6).
14. `sort_id` kartu bukan ID permanen; status highlight kartu tidak tersimpan (typo vanilla) (§4.6).
15. `CardArea` dengan `config.type` baru tidak ditata sama sekali oleh `align_cards` vanilla (§4.4).
16. `most_played_poker_hand` default di-hardcode `'High Card'` di `end_round`; jika hand vanilla disembunyikan, fungsi ini harus di-wrap (§4.1).

## 9. Daftar hal yang BELUM terverifikasi

- Apakah `__eq` metatype cdata dipanggil untuk `cdata == number` di LuaJIT yang dibundel Balatro. Wajib diuji di runtime (tes kecil saat Fase 2, langkah pertama big number).
- Versi persis LÖVE/LuaJIT yang dibundel. Source tidak menyebutkannya (`conf.lua` tanpa `t.version`); diasumsikan LÖVE 11.x + LuaJIT 2.1. Bisa dicek di game lewat `love.getVersion()` dan `jit.version`.
- Format persis konversi number→string di LuaJIT (`%.14g`) — mempengaruhi desain serialisasi, tapi desain kita tidak akan bergantung pada presisi itu.
- Navigasi controller (`engine/controller.lua`) untuk area berbentuk grid: belum dianalisis rinci; dikerjakan saat merancang zona board.
- Kapan update 1.1 rilis dan apa dampaknya pada patch.

## 10. Yang saya butuhkan dari Anda sebelum Fase 1

> **Status:** semua poin di bawah sudah diputuskan (lihat `docs/phase-1/README.md`, tabel "Keputusan yang dikunci").

1. ~~Source vanilla~~ — **sudah diterima dan dicek (1.0.1o-FULL).** Source tetap hanya di lokal, tidak masuk repo.
2. **Nasib konten vanilla** (joker, planet, boss, poker hand): usul saya, dinonaktifkan dari pool dan diganti total oleh konten New Era. Hand vanilla boleh bertahan sebagai subset tersembunyi.
3. **Representasi big number:** usul saya, LuaJIT FFI cdata (gaya Amulet) dengan namespace `NE.Big`.
4. **Konflik:** deklarasikan `conflicts` terhadap Talisman, Amulet, dan Cryptid?
5. **Pin versi:** target SMODS rilis stabil 26.829.0 (atau rilis terbaru saat Fase 2) + Lovely ≥ 0.10.0.
