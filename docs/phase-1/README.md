# New Era — Fase 1: GDD, Arsitektur, Roadmap

Status: **draf untuk dikonfirmasi**. Belum ada kode. Semua angka balance adalah titik awal yang akan disetel saat playtest.

| File | Isi |
|---|---|
| [01-gdd-systems.md](01-gdd-systems.md) | Sistem inti: papan & formasi (hand system baru), twin hands, skor & fase, hiperoperator, mata uang, peta, multi-blind, boss prosedural, balance model |
| [02-jokers-unranked.md](02-jokers-unranked.md) | Joker #1–#31 (Unranked) |
| [03-jokers-demonic.md](03-jokers-demonic.md) | Joker #32–#91 (Demonic) |
| [04-jokers-heavenly.md](04-jokers-heavenly.md) | Joker #92–#121 (Heavenly) |
| [05-architecture.md](05-architecture.md) | Struktur mod, modul, big number, daftar patch Lovely, shader, animasi, save/load, anggaran performa |
| [06-roadmap.md](06-roadmap.md) | Fase implementasi kecil yang bisa diuji |

## Keputusan yang dikunci (dari Fase 0)

| # | Keputusan | Alasan singkat |
|---|---|---|
| D1 | Konten vanilla yang bergantung pada poker hand (joker, planet, boss, 12 poker hand) **dikeluarkan dari pool** saat New Era aktif. Deck, stake, voucher, tarot, spectral, dan tag vanilla dipertahankan kecuali yang rusak oleh sistem baru. | Hand system diganti total; 13 joker dan 6 boss vanilla terikat nama poker hand (lihat Fase 0 §4.1). |
| D2 | Big number: **LuaJIT FFI cdata**, namespace `NE.Big`, tanpa global gaya Talisman (`Big`, `to_big`, dll.). | Mendukung operator campuran number/big; tidak bentrok dengan mod lain. |
| D3 | `conflicts`: Talisman, Amulet, Cryptid. | Keduanya menimpa `number_format`/`math.*` dan tipe skor. |
| D4 | Target: Balatro **1.0.1o-FULL**, Steamodded **≥ 26.829.0** (diuji di versi itu), Lovely **≥ 0.9.0** (diuji di 0.10.0). | Patch ditulis terhadap source yang sudah diverifikasi. |
| D5 | Prefix mod: `ne`. ID mod: `NewEra`. | Key menjadi `j_ne_*`, `bl_ne_*`, dst. |
| D6 | Bahasa: kode & identifier Inggris; lokalisasi awal `en-us` dan `id` (Balatro punya `localization/id.lua`). | — |

## Perubahan roster

Tidak ada karakter, urutan, atau rank yang diubah. Satu batasan teknis:
- **#111 Chara**: efek "mengancam file save" sepenuhnya **ilusi visual**. Tidak ada operasi file. Ada opsi config untuk mematikan efek meta.
