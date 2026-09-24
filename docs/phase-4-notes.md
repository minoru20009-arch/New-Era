# Fase 4 — Skor & Fase

## Yang berubah

- **Aura** (parameter skor ketiga, key `ne_aura`, awal 1)
  - Rumus skor tangan: **(Chips × Mult) ^ Aura**, lewat kalkulasi Steamodded `ne_ascend`.
  - `ne_ascend` otomatis aktif di run baru. Save lama yang masih memakai `multiply` dipindah ke `ne_ascend`; hasilnya sama selama Aura = 1.
  - UI: kotak kecil `^Aura` di kanan kotak Mult. Kotak ini kosong saat Aura = 1 atau tidak diketahui (tangan tertutup). Kotak Chips dan Mult sedikit dipersempit untuk memberi ruang.
- **Key return baru untuk joker** (diproses setelah key bawaan `chips/mult/xchips/xmult`):

  | Key | Efek |
  |---|---|
  | `echips = x` | Chips ^ x |
  | `emult = x` | Mult ^ x |
  | `eemult = x` | Mult ^^ x |
  | `hypermult = {n, x}` (atau `{arrows = n, amount = x}`) | Mult {n} x |
  | `aura = x`, `xaura = x` | Aura + x / Aura × x |
  | `divinity`, `corruption`, `time` | mata uang run |

  Semua key didaftarkan lewat parameter Aura, jadi tidak ada fungsi inti SMODS yang di-wrap untuk ini.
- **Chips/Mult tanpa overflow**
  - `mod_chips`/`mod_mult` (dua titik yang selalu dilewati setiap perubahan chips/mult) di-wrap. Nilai mulai 1e100 menjadi Big, sehingga seluruh aritmetika SMODS (x_mult, balance, swap, …) tidak pernah menghasilkan `inf`. Di bawah 1e100 tetap angka biasa, jadi tangan normal berjalan persis seperti vanilla (api, getar teks, popup "+X").
  - Nilai parameter disinkronkan tepat. Sinkronisasi SMODS lewat selisih bisa hilang jadi 0 saat nilai turun drastis, misalnya `1e500 ^ 0.5`.
  - Skor di bawah 1e308 tetap angka biasa di `G.GAME.chips`.
- **Fase skor** (context untuk joker: `context.ne_omen`, `ne_chain`, `ne_ascension`, `ne_judgment`)
  - **Pertanda**: setelah Play ditekan; kartu sudah di area main, sebelum evaluasi.
  - **Rantai**: di awal skor, sekali per formasi sekunder. Formasi baru ada di Fase 6, jadi sekarang fase ini tercapai dengan 0 formasi (`chain(0)`).
  - **Kenaikan**: setelah semua joker, sebelum skor diambil. Tempat Aura dan penulisan ulang hasil.
  - **Penghakiman**: setelah skor tangan diketahui. Membawa `context.score`, `context.total` (skor ronde setelah tangan ini), dan `context.overkill` (kelebihan di atas target, ≥ 0). Aturan per-tangan (`NE.Rules`) masih aktif saat fase ini.
  - Tanpa patch Lovely: `mod.calculate` New Era selalu dipanggil setelah semua joker di setiap context SMODS. Rencana patch L15–L17 dibatalkan; L18 hanya disisakan untuk encounter di Fase 9.
- **Mata uang dasar** (`NE.Currency`: Divinity, Corruption 0–100, Time 0–10)
  - Nilai tersimpan bersama run, dengan context `ne_currency_changed`.
  - HUD, ambang Corruption, dan Penghakiman Neraka masuk Fase 7. Untuk sekarang nilainya dilihat di overlay F9.
- **Joker uji** (hanya lewat cheat, tidak pernah di toko):
  - **Uji: ^Mult** (^2), **Uji: ^^Mult** (^^2), **Uji: Hyper Mult** ({3}1.1)
  - **Uji: Aura** (+0.5 Aura di fase Kenaikan)
  - **Uji: Fase** (pesan di Pertanda/Rantai/Kenaikan, +1 Divinity di Penghakiman)
- **Debug**
  - Cheat: beri kelima joker di atas, dan **+5 tiap mata uang**. Menu cheat sekarang 3 kolom.
  - Overlay F9: kalkulasi aktif, Aura, mata uang, dan urutan fase tangan terakhir beserta skornya.
- **Hook**: `NE.Hooks.on_context` punya parameter urutan; pembersihan aturan per-tangan/ronde/ante berjalan paling akhir.
- **Koreksi GDD §3.3**: rumus tinggi pecahan disamakan dengan implementasi `NE.Big` (`x↑↑0.5 = x^0.5`, sama dengan OmegaNum). Rumus lama di GDD (`1 + f·(x−1)`) tidak pernah dipakai di kode.
- **Tes**
  - 580 pemeriksaan lulus. Mock kini meniru mesin skor SMODS (parameter chips/mult, `mod_mult` + sinkronisasi, routing key, urutan context, antrean event). Satu tangan dimainkan dengan urutan context yang sama seperti `evaluate_play` di dump SMODS.
  - Uji acak terpisah: 3.000 tangan dengan operator acak (termasuk nilai ekstrem), 0 error, 0 NaN/inf.

## Cara uji di game

1. **Boot**: log berisi `New Era 0.4.0~dev loaded` tanpa error. F9 (dalam run) menampilkan `Calc ne_ascend   Aura 1`.
2. **Tangan normal**
   - Mainkan beberapa tangan tanpa joker uji. Skor, api, suara, getar teks, dan popup "+X" harus sama seperti biasa.
   - Kotak `^Aura` di kanan Mult kosong.
   - Mohon cek juga tata letak panel skor (Chips, X, Mult, kotak Aura) tidak terpotong atau bertabrakan.
3. **Operator**: F10 → beri satu joker, mainkan tangan, lalu jual/ganti joker dan ulangi.
   - **Uji: ^Mult** → popup `^2 Mult`, Mult menjadi kuadratnya.
   - **Uji: ^^Mult** → `^^2 Mult` (Mult ^ Mult).
   - **Uji: Hyper Mult** → `{3}1.1 Mult`.
4. **Aura**: beri **Uji: Aura** → di akhir skor muncul `+0.5 Aura`, kotak Aura menampilkan `^1.5`, dan skor = (Chips × Mult)^1.5. Setelah tangan selesai, kotak Aura kosong lagi.
5. **Fase**
   - Beri **Uji: Fase**, mainkan tangan. Pesan muncul berurutan: `Omen!` (saat kartu masuk area main), `Ascension!` (di akhir skor), lalu `+1 Divinity`.
   - F9 menampilkan `Phases (last hand): omen > chain(0) > ascension > judgment` dan `Divinity 1`.
6. **Kombinasi Big**: **Uji: Overflow** (di kiri) + **Uji: ^Mult** (di kanan).
   - Mult menjadi sekitar `1e310`, dan skor tangan sekitar `e466`–`e470` (tergantung tangan).
   - Blind menang, tanpa `nan`/`inf` di mana pun.
7. **Save/load**: di tengah ronde dengan beberapa joker uji → menu utama → Continue. Kotak Aura, mata uang (F9), dan skor tetap benar. Mainkan tangan lagi.
8. **Mata uang**: F10 → **+5 tiap mata uang** → F9 menampilkan Divinity/Corruption/Time naik 5 (Time maksimal 10, Corruption maksimal 100).

Tolong kirimkan hasil tiap langkah, terutama tampilan panel skor di langkah 2 dan 4 (screenshot sangat membantu).

## Known issues

- **Tata letak kotak Aura belum pernah dilihat di game.** Lebar kotak dihitung dari layout SMODS (Chips 1,75 + X + Mult 1,75 + Aura 0,6). Jika bertabrakan, beri tahu saya; ukurannya mudah diubah.
- **Chips/Mult di atas 1e100 bergantung pada patch L8a/L8c** untuk api skor dan getar teks (dari Fase 3). Jika patch itu tidak menempel di versi SMODS Anda, efek tersebut hilang hanya untuk nilai sebesar itu.
- **Batas atas overflow tersisa**: joker lain (bukan New Era) yang mengembalikan pengali > ~1e208 sebagai angka biasa bisa membuat satu langkah overflow ke `inf`. Nilai itu langsung dijepit ke 1.8e308 lalu menjadi Big, jadi tidak pernah `inf`/`nan`, tapi presisinya hilang. Joker New Era memakai Big untuk nilai sebesar itu.
- **Rantai** belum punya isi sampai formasi ada (Fase 6).
- **Mata uang** belum punya HUD dan aturan ambang (Fase 7).
- **Layar New Run (Steamodded)** memakai pemilih bertahap: pilih deck → **Select Stake >** → pilih stake → **Play**. Tombol **Last Run** memakai pilihan terakhir. Ini perilaku Steamodded, bukan bug New Era (lihat README).
