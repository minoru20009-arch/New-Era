# 06 — Roadmap Implementasi

Prinsip: fondasi dulu (big number, state, evaluator, zona), konten terakhir. Setiap fase:
- menghasilkan file lengkap yang bisa dijalankan (tanpa potongan `...`);
- diakhiri dengan ringkasan perubahan, cara uji di game, dan known issues;
- **menunggu konfirmasi dan hasil uji Anda** sebelum fase berikutnya.

Setiap fase bisa dimainkan: fitur yang belum ada memakai perilaku vanilla atau placeholder.

| Fase | Isi | Cara uji di game | Selesai jika |
|---|---|---|---|
| **2** Kerangka | `NewEra.json`, `main.lua`, loader modul, `config.lua`, namespace `NE`, logger, UID, `NE.Rules`, `NE.cond`, 3 rarity (`ne_unranked/demonic/heavenly`), penyembunyian konten vanilla (joker, planet, boss, poker hand), keybind debug (F9 overlay, F10 menu cheat), 3 joker uji sederhana | Game boot; badge New Era; toko hanya berisi joker uji; overlay F9 tampil | Tidak ada error di log Lovely; run vanilla lain tetap bisa dimulai |
| **3** Big number | `NE.Big` (FFI, OmegaNum inline, jalur cepat, mutasi), notasi, pack/unpack, wrap `number_format`/`math.*`/high score, patch L6–L8, rehydrate L4; tes CLI | Cheat: set skor `1e500`, target `ee10`, `10^^5`; lihat tampilan, save & load, lanjutkan | Semua tes CLI lulus; save/load bolak-balik tanpa kehilangan nilai; tidak ada `inf`/`nan`; tes runtime `__eq` dicatat |
| **4** Skor & fase | Parameter `Aura`, `Scoring_Calculation` `ne_ascend`, key return baru (`emult`, `eemult`, `hypermult`, `aura`, mata uang), fase Omen/Chain/Ascension/Judgment (L15–L18), joker uji untuk tiap operator | Joker uji ^2, ^^2, {3}1.1, +Aura; log urutan fase di overlay | Urutan fase benar; nilai hiper benar vs tes CLI; UI `^Aura` tampil |
| **5** Papan | `G.play` → papan 5×3, slot di `ability`, wrap `align_cards`/`emplace`, penempatan drag & klik, main cepat otomatis, residu & L13–L14, discard kartu papan, navigasi kontroler, `NE.Board.resize`, prototipe layout 16:9 dan 4:3 | Main beberapa tangan; residu tetap; save di tengah ronde lalu load; coba dengan kontroler | Tidak ada soft-lock; posisi pulih setelah load; layout muat di 1280×720 |
| **6** Formasi | Tabel pola, evaluator + cache, 17 formasi (`SMODS.PokerHand`), rantai sekunder, pratinjau, 17 planet, diagram mini di Run Info, L12 | Bentuk tiap formasi; lihat nama rantai; pakai planet; buka Run Info | Tes CLI evaluator lulus; semua formasi terdeteksi benar di game |
| **7** Twin hands & ekonomi | Dek/Tangan Bayangan, enhancement (`Berkah`, `Iblis`, `Palsu`), stiker (`bound`, `phased`, `decay`, `bomb`, `frozen`), ✦/☠/⧗ + HUD, ambang ☠ & Penghakiman Neraka, pemurnian | Cheat ubah kartu jadi Iblis; tangan bayangan muncul; isi ☠ ke 100 | Kartu kembali ke dek asalnya; HUD tanpa alokasi per frame; hukuman tampil sebelum terjadi |
| **8** Aktif & waktu | Framework `ne_active` (tombol, biaya, frekuensi, targeting, kontroler), `NE.Chrono` (time stop), `NE.Snapshot` (rewind tangan, checkpoint blind, restore via start_run) | Joker uji time stop, rewind tangan, checkpoint game over | Rewind mengembalikan papan/tangan/skor dengan tepat; checkpoint tahan save/load |
| **9** Encounter | Cangkang `bl_ne_encounter`/`bl_ne_boss`, data encounter, multi-fase, Celah (2–3 blind, target, limpahan), HUD encounter, L9–L11, context `ne_boss_trait` | Cheat mulai boss 3 fase dan Celah 3 blind | Transisi fase & limpahan benar; ante naik setelah boss; save di tengah fase |
| **10** Generator boss | Arketipe, ~20 trait awal, imunitas, budget, counter-picking, pity, kurva target `B(a)` + stake | Cheat lompat ke ante 5/15/45/120; lihat pratinjau boss | Deterministik per seed; target mengikuti tabel 01 §9.1 |
| **11** Peta | State `NE_MAP` (L1–L3), generator peta, UI peta, node Pertarungan/Elit/Celah/Boss/Toko/Harta/Kuil, rute cashout/toko (L19–L20), reroll jalur, kemenangan Ante 10 | Mainkan 2 ante penuh lewat peta | Save/load di peta; tidak ada jalan buntu; semua node bisa dimasuki |
| **12** Shader kartu | `ne_card.fs` (20 motif, set glyph awal, 3 tier style, tilt vanilla), DrawStep, konversi parameter | Galeri debug menampilkan semua kombinasi motif/tier | ≤ 2 ms draw untuk 10 joker; tilt & reduced motion benar |
| **13** Post-process & animasi | `ne_post.fs` (efek gabungan + overlay prosedural), `ne_background.fs` (L5), pseudo-3D papan, `NE.Anim`, reduced motion & screenshake | Cheat picu tiap overlay; animasi ZA WARUDO lengkap | 0 pass tambahan saat idle; animasi patuh reduced motion |
| **14** Joker #1–#16 | Konten + lokalisasi en/id + art params | Cheat beri tiap joker; skenario uji per joker | Semua kemampuan sesuai teks |
| **15** Joker #17–#31 | idem | idem | idem |
| **16** Joker #32–#61 | idem (Demonic, kontrak ☠) | idem | idem |
| **17** Joker #62–#91 | idem | idem | idem |
| **18** Joker #92–#106 | idem (Heavenly, Aura, penulisan ulang) | idem | idem |
| **19** Joker #107–#121 | idem (termasuk papan variabel, pentasi) | idem | idem |
| **20** Konten dunia | ±20 peristiwa, sisa trait (total ±48), nama boss prosedural, hadiah Harta/Kuil lengkap | Mainkan run penuh sampai Ante 10 | Tidak ada event/trait yang crash |
| **21** Balance & polish | Balance pass (simulasi kurva skor vs target), stress test ante 100/200/300, profiling, lokalisasi lengkap, config grafis | Run endless panjang | 60 FPS stabil; tidak ada `inf`/`nan`; save tahan semua skenario |

Urutan 12–13 (rendering) sengaja setelah sistem inti. Sebelum itu, joker memakai bingkai tier polos agar gameplay bisa diuji lebih dulu.
