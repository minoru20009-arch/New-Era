# Fase 2 — Kerangka Mod

## Yang berubah

- **Metadata & loader:** `NewEra.json` (id `NewEra`, prefix `ne`, konflik Talisman/Amulet/Cryptid), `main.lua` memuat 16 modul sesuai urutan dependensi dan berhenti dengan pesan jelas jika satu file gagal dimuat.
- **Core (`src/core/`):**
  - `NE` namespace + konstanta rarity.
  - Logger (`NE.log.*`, logger name `NewEra`, termasuk `warn_once`).
  - State run di `G.GAME.newera` (hanya data polos, ikut save; run lama tanpa state otomatis dilengkapi).
  - Hub `mod.calculate` (`NE.Hooks.on_context`) dengan isolasi error per handler.
  - UID kartu (`ability.ne_uid`, karena `sort_id` vanilla tidak aman setelah load).
  - `NE.Rules` (aturan sementara per tangan/ronde/ante dan permanen, dibersihkan otomatis lewat context `after`, `end_of_round`, `ante_change`).
  - `NE.cond` (semua kondisi joker lewat sini; dipakai Aizen #94 nanti).
- **Rarity:** `ne_unranked` (bobot 0.75), `ne_demonic` (0.22), `ne_heavenly` (0.03, di toko mulai Ante 4).
- **Konten vanilla disembunyikan dari pool** (tetap ada di koleksi):
  - Wrapper `SMODS.add_to_pool` untuk joker (dan nanti planet/blind).
  - Bobot rarity vanilla menjadi 0 di pool Joker.
  - Wrapper `create_card` memetakan permintaan rarity vanilla: The Soul → Heavenly, Wraith → Demonic, Riff-raff/tag → Unranked, dengan fallback bertingkat jika rank kosong.
  - Planet & blind: toggle sudah ada tetapi baru berlaku setelah penggantinya ada (Fase 6 / Fase 10), agar pool tidak kosong.
- **Joker uji:** `Uji: Unranked` (+8 Mult), `Uji: Demonic` (X3 Mult), `Uji: Heavenly` (+100 Chips, X5 Mult), dengan badge DEBUG.
- **Aset sementara:** atlas bingkai 4 tier (Unranked, Demonic, Heavenly, hibrida) dan ikon mod, pixel art prosedural (`tools/gen_assets.py`).
- **Alat debug:** overlay F9 (teks diperbarui 4x per detik; menggambar tanpa alokasi), menu cheat F10, tab Config di menu Mods.
- **Tes:** `tests/run_tests.lua` memuat mod sungguhan di atas mock SMODS/G/LÖVE: 179 pemeriksaan lulus di LuaJIT 2.1.

## Cara uji di game

1. **Boot:** jalankan game. Di menu **Mods**, New Era tampil dengan ikon dan versi `0.2.0~dev`. Di `Mods/lovely/log`, cari baris `New Era 0.2.0~dev loaded (16 modules).` dan pastikan tidak ada error bertag `NewEra`.
2. **Koleksi:** Collection → Jokers → halaman terakhir: 3 joker uji dengan badge rank dan DEBUG. Joker vanilla tetap ada di koleksi.
3. **Toko:** mulai run baru. Joker di toko dan Buffoon Pack hanya joker uji (Unranked/Demonic; Heavenly baru muncul mulai Ante 4).
4. **F9:** overlay muncul di kiri atas, angka FPS/ms/heap berubah, baris Ante/$/Jokers sesuai run.
5. **F10:** menu cheat terbuka. Coba **+$50**, **Beri Uji: Heavenly**, lalu mainkan tangan: skor harus memakai +100 Chips dan X5 Mult. Coba **Skor = target blind** saat memilih kartu, lalu mainkan satu tangan: blind menang.
6. **Save/load:** di tengah ronde, kembali ke menu utama → Continue. Tidak crash; joker uji masih ada.
7. **Config:** Mods → New Era → Config: matikan "Sembunyikan joker vanilla" → reroll toko → joker vanilla muncul lagi. Nyalakan kembali.

Tolong kirimkan hasil tiap langkah (dan isi `Mods/lovely/log` jika ada error).

## Known issues

- Kode belum pernah dijalankan di dalam game: lingkungan pengembangan tidak punya Balatro, jadi verifikasi memakai tes LuaJIT + mock dan pembacaan source SMODS/vanilla. Langkah uji di atas adalah validasi pertama di game.
- Jika joker uji dimatikan sementara joker vanilla disembunyikan, toko jatuh ke joker fallback vanilla ("Joker"), karena belum ada joker New Era sungguhan (mulai Fase 14).
- Gambar joker masih bingkai tier sementara; art shader datang di Fase 12.
- Di beberapa sistem, F10 bisa ditangkap OS/window manager. Jika menu cheat tidak terbuka, beri tahu saya dan tombolnya akan dipindah.
