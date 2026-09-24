# New Era

Mod ekspansi ekstrem untuk Balatro (Steamodded + Lovely). Desain lengkap ada di [`docs/phase-1/`](docs/phase-1/README.md).

Status: **Fase 2 — kerangka mod** (belum ada konten gameplay New Era; hanya fondasi, rarity, dan joker uji).

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

## Struktur

```
NewEra.json         metadata Steamodded
main.lua            loader modul (urutan dependensi)
config.lua          konfigurasi default
src/core/           namespace NE, logger, util, state run, hook context, UID, aturan, NE.cond
src/content/        atlas, rarity
src/compat/         penyembunyian konten vanilla dari pool
src/ui/             tab config
src/debug/          overlay F9, menu cheat F10, keybind
src/jokers/test/    joker uji Fase 2
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

## Alat debug

Aktif jika `debug.enabled` menyala (default: menyala di build pengembangan).

| Tombol | Fungsi |
|---|---|
| F9 | Overlay performa: FPS, waktu update/draw, heap Lua, state game, ringkasan state New Era |
| F10 | Menu cheat: uang, tangan, discard, ante, skor = target, beri joker uji |
