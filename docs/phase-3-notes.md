# Fase 3 — Big Number (`NE.Big`)

## Yang berubah

- **`NE.Big` (FFI, `src/bignum/`)**
  - Satu nilai adalah satu cdata `ne_big` (72 byte). Array OmegaNum disimpan inline, tanpa tabel samping.
  - Nilai di bawah 1e308 memakai aritmetika double biasa (jalur cepat, hasilnya persis sama dengan double).
  - Operator `+ - * / ^ %`, unary `-`, `< <= > >=`, `==`, `..` dan `tostring` bekerja untuk campuran number/Big.
  - Hyper-operator `NE.Big.arrow(a, n, b)` sampai `10{7}`, ditambah `tetrate`, `slog`, `log10`, `pow10`.
  - Varian mutasi (`add_into`, `mul_into`, …) untuk loop panas.
  - Tidak pernah menghasilkan NaN/Inf. Input rusak tersaturasi dan diberi flag diagnosis (`NE.Big.flags`).
- **Notasi** (ASCII): `1.00e500`, `e1.23e456`, `ee1.23e45`, `10^^5`, `10^^10^^10`, `10{3}10`. Hasil format di-cache per nilai, jadi callback UI per frame tidak mengalokasikan apa pun untuk nilai yang sama.
- **Save/load**
  - Simpan: patch Lovely **L6** di `recursive_table_cull` mengubah Big menjadi string `neb:<sign>:<len>:<a0>,…` (presisi penuh `%.17g`). Jika patch gagal menempel, fallback Lua otomatis terpasang dan log mencatatnya.
  - Muat: setiap tabel hasil `STR_UNPACK` (save run, pratinjau "Continue", profil) dan setiap `savetext` di `Game:start_run` dipulihkan menjadi Big. Ini menggantikan rencana patch L4 (lebih sedikit patch Lovely).
- **Integrasi game (wrap Lua)**
  - `number_format`, `score_number_scale`, `scale_number` (teks panjang diperkecil).
  - `math.floor/ceil/abs/max/min/log/log10/sqrt/exp/pow`: angka biasa tetap lewat fungsi asli; `log` dari Big menghasilkan number.
  - High score dan career stat: rekor run menyimpan Big penuh, sedangkan profil hanya menyimpan number terbatas (maks. 1.798e308). Profil/settings disanitasi sebelum dikirim ke thread save.
  - Skor tangan: `chips × mult` di atas 1e308 menjadi Big, bukan `inf`.
  - Juice teks dibatasi agar skor astronomis tidak membuat teks bergetar liar.
- **Patch Lovely** `lovely/10_bignum.toml`
  - **L6**: save.
  - **L7**: `modulate_sound` memakai number biasa, tanpa alokasi per frame.
  - **L8a/b/c**: cek `type(x) == 'number'` di kode SMODS untuk suara, delta "+X" di tampilan tangan, dan juice teks.
  - Kelima anchor sudah dicek cocok tepat satu baris terhadap Balatro 1.0.1o dan SMODS 26.924.0~dev.
- **Debug**
  - Cheat baru (F10): **Skor = 1e500**, **Skor x1e150**, **Target = ee10**, **Target = 10^^5**, **Tangan: chips/mult besar**, **Beri Uji: Overflow**.
  - Overlay F9 menampilkan skor/target, jumlah Big dibuat per detik, dan mode save (`lovely`/`fallback`).
- **Joker uji `Uji: Overflow`**: X1e155 Chips dan X1e155 Mult. Hanya lewat cheat, tidak pernah muncul di toko. Chips dan mult masing-masing tetap di bawah 1e308; hanya hasil kalinya yang melewati 1e308.
- **Tes**: 397 pemeriksaan lulus.
  - Termasuk emulator mini Lovely yang menerapkan `lovely/*.toml` ke potongan kode ber-anchor, lalu menguji hasilnya.
  - Fuzz terpisah: 200.000 operasi acak dalam 1,3 detik, 0 error, 0 nilai invalid.
- **Hasil `__eq` runtime** (target roadmap):
  - LuaJIT memanggil `__eq` untuk cdata vs number/nil/string (diuji di LuaJIT 2.1).
  - Saat game start, log mencatat `NE.Big runtime check passed (... save: lovely)`.
  - Kode New Era tetap memakai `NE.Big.eq`.

## Cara uji di game

1. **Boot**
   - Di `Mods/lovely/log`, cari `New Era 0.3.0~dev loaded` dan `NE.Big runtime check passed (… save: lovely)`.
   - Jika tertulis `save: fallback` atau `runtime check FAILED`, kirimkan lognya.
   - Cari juga peringatan Lovely `resulted in no matches` yang menyebut `10_bignum.toml`.
2. **Tampilan**
   - Mulai run dan pilih Small Blind.
   - F10 → **Target = 10^^5**: target blind tampil `10^^5`.
   - F10 → **Skor = 1e500**: skor ronde tampil `1.00e500`.
   - F9: baris `Score 1.00e500 / target 10^^5`.
3. **Main tangan**: mainkan 1 tangan. Skor bertambah tanpa crash, api/suara normal, dan blind belum menang (1e500 < 10^^5).
4. **Save/load**
   - Kembali ke menu utama → **Continue**.
   - Skor tetap `1.00e500` dan target tetap `10^^5`.
5. **Menang**
   - F10 → **Target = ee10** (tampil `e1.00e10`) → **Skor = target blind** → mainkan tangan: blind menang.
   - Layar cash-out menampilkan target dengan notasi baru.
   - Di blind berikutnya, skor turun ke 0 dengan mulus.
6. **Overflow nyata**
   - F10 → **Beri Uji: Overflow** → mainkan tangan: muncul popup `X1.0e155` Chips dan Mult.
   - Total tangan tampil sekitar `1.xxe31x`, lalu blind menang.
   - Di Run Info atau layar akhir run, "Best hand" tampil dengan notasi yang sama.
   - Keluar → pratinjau **Continue** juga menampilkan best hand itu.
7. **Tampilan tangan**: F10 → **Tangan: chips/mult besar**. Chips `1.00e400` dan mult `e1.00e12` tampil tanpa crash. Pilih kartu → kembali normal.
8. **Performa**
   - Di toko (idle), overlay F9 harus menunjukkan `Big 0/s`.
   - Bandingkan FPS dan `update ms` dengan Fase 2; seharusnya tidak berubah terasa.

Tolong kirimkan hasil tiap langkah (dan isi `Mods/lovely/log` jika ada error).

## Known issues

- **Chips/mult sendiri masih number.** Satu nilai chips atau mult di atas 1e308 tetap menjadi `inf` sebelum dikalikan (dijepit ke 1.798e308 saat dikalikan). Konversi chips/mult ke Big masuk Fase 4 (operator skor). Joker uji sengaja menjaga keduanya di bawah 1e308.
- **High score profil tersaturasi di 1.798e308.** Ini disengaja: profil tetap kompatibel dengan vanilla. Rekor per-run tetap menyimpan nilai penuh.
- **Konvensi tinggi pecahan linear** (`10^^0.5 = 10^0.5`). Untuk basis selain 10 dengan tinggi > 2^53, pengaruh basis di bawah presisi double, jadi hasilnya dianggap sama dengan basis 10.
- **L8c menempel ke `src/ui.lua` milik SMODS.** Jika SMODS mengubah baris itu, Lovely hanya mencatat peringatan "no matches"; efeknya kosmetik (juice teks).
- **Biaya wrap `math.*`.**
  - Dengan JIT: tidak terukur (30 juta panggilan: 39,6 → 40,0 ms).
  - Di mode interpreter: ±20–40 ns per panggilan.
  - Mohon cek `update ms` di F9.
- **Kode diuji tanpa game**: LuaJIT + mock + emulator patch. Langkah uji di atas adalah validasi pertama di game.
- **Deviasi dari arsitektur (05 §7)**
  - L4 tidak dipakai (diganti wrap `STR_UNPACK` + `Game:start_run`).
  - L8 hanya mencakup 3 cek milik SMODS. Cek vanilla lainnya sudah ditangani lewat wrap Lua atau sudah digantikan SMODS.
  - Dokumen 05 sudah diperbarui.
