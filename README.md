# New Era

Mod ekspansi ekstrem untuk Balatro (Steamodded + Lovely). Desain lengkap ada di [`docs/phase-1/`](docs/phase-1/README.md).

Status: **Fase 5 — papan** (papan 5×3 di area main, penempatan seret/klik/main cepat, Residu, efek baris, kontroler) di atas skor & fase (Fase 4) dan `NE.Big` (Fase 3). Formasi menyusul di Fase 6; sampai saat itu skor memakai poker hand vanilla. Catatan per fase ada di `docs/phase-*-notes.md`.

## Kebutuhan

| Komponen | Versi |
|---|---|
| Balatro (Steam) | 1.0.1o |
| Lovely | ≥ 0.9.0 (diuji dengan 0.10.0) |
| Steamodded | ≥ 26.829.0 |

Tidak kompatibel dengan Talisman, Amulet, atau Cryptid (ditandai `conflicts`).

## Instalasi

1. Pasang Lovely dan Steamodded (lihat [docs.smods.dev](https://docs.smods.dev)).
2. Salin seluruh isi repo ini ke `%AppData%\Balatro\Mods\NewEra\` (nama folder bebas). File `NewEra.json` harus berada langsung di folder itu.
3. Jalankan game. New Era muncul di menu **Mods**.

### Catatan: layar New Run (Steamodded)

Steamodded versi baru mengganti layar New Run dengan pemilih bertahap. Ini bukan bagian dari New Era.

1. Pilih deck (klik kartunya; preview di kanan berganti).
2. Tekan tombol biru **Select Stake >** (bar bawah, di kiri tombol oranye **Last Run**) untuk ke halaman stake. Di halaman stake, tombol yang sama berubah menjadi **Play** (hijau).
3. Pilih stake, lalu tekan **Play**.

Tombol oranye **Last Run** langsung memulai run dengan deck dan stake **terakhir** yang dipakai, jadi pilihan deck di layar saat itu diabaikan.

## Struktur

```
NewEra.json         metadata Steamodded
main.lua            loader modul (urutan dependensi)
config.lua          konfigurasi default
src/core/           namespace NE, logger, util, state run, hook context, UID, aturan, NE.cond
src/bignum/         NE.Big (FFI), hyper-operator, notasi, save/load, integrasi ke game
src/economy/        mata uang run (Divinity, Corruption, Time)
src/board/          papan: grid & tata letak, area papan & Residu, penempatan, slot & kontroler
src/scoring/        operator skor, Aura, kalkulasi ne_ascend, fase skor
src/content/        atlas, rarity
src/compat/         penyembunyian konten vanilla dari pool
src/ui/             tab config
src/debug/          overlay F9, menu cheat F10, keybind
src/jokers/test/    joker uji
lovely/             patch Lovely (hanya titik yang tidak bisa di-wrap dari Lua)
localization/       en-us, id
assets/             aset sementara (bingkai tier, ikon); dibuat oleh tools/gen_assets.py
tests/              tes tanpa game (LuaJIT + mock)
docs/               riset (Fase 0) dan desain (Fase 1)
```

## Menjalankan tes

Butuh LuaJIT 2.1 (runtime yang sama dengan Balatro):

```sh
NE_ROOT=$PWD luajit tests/run_tests.lua
```

Tes memuat mod sungguhan di atas mock SMODS/game/LÖVE (`tests/mocks.lua`; kelas `CardArea`/`Card` dan alur main/discard di `tests/mock_areas.lua`). Patch di `lovely/*.toml` diterapkan ke potongan kode ber-anchor oleh emulator mini Lovely, lalu diuji perilakunya.

## Alat debug

Aktif jika `debug.enabled` menyala (default: menyala di build pengembangan).

| Tombol | Fungsi |
|---|---|
| F9 | Overlay performa: FPS, waktu update/draw, heap Lua, state game, ringkasan state New Era, skor/target, kalkulasi & Aura, mata uang, papan (ukuran, Residu, petak kosong), urutan fase tangan terakhir, Big per detik |
| F10 | Menu cheat: uang, tangan, discard, ante, skor = target, beri joker uji (termasuk operator `^`/`^^`/`{3}`, Aura, fase), skor/target big number (`1e500`, `x1e150`, `ee10`, `10^^5`), tampilan tangan big, +5 mata uang, papan (+4 Residu, ganti ukuran, acak Residu, kosongkan) |
