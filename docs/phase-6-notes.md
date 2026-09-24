# Fase 6 — Formasi

## Yang berubah

- **17 formasi menggantikan poker hand** (GDD §1.3–1.4)
  - Formasi dibaca dari **posisi** kartu di papan: pasangan bersebelahan, garis 3 (baris, kolom, diagonal), baris penuh, persegi 2×2, kompas (+), dan papan penuh.
  - Urutan prioritas dari atas: Gerbang Surga, Garis Lima, Barisan Agung, Kotak Empat, Pakta Neraka, Garis Halo, Kompas, Tautan Penuh, Barisan Senada, Barisan Berurut, Benteng, Triad, Tangga, Tautan Ganda, Trio Sekerabat, Tautan Kembar, Percikan.
  - Nilai dasar dan per level sesuai tabel GDD (mis. Triad 35 × 3, +25/+2 per level).
  - Poker hand vanilla tetap terdaftar di Steamodded, tetapi tidak pernah cocok dan tidak tampil di Run Info maupun koleksi.
- **Aturan aktivasi**
  - Pola hanya dihitung jika memuat **minimal satu kartu yang baru ditempatkan** di tangan ini. Residu saja tidak membentuk formasi lagi (known issue Fase 5 selesai).
  - Residu boleh menjadi bagian formasi bersama kartu baru. Jika formasi itu mencetak skor, Residunya ikut keluar dari papan.
  - Gerbang Surga memeriksa papan penuh (cukup satu kartu baru di mana saja).
- **Rantai formasi** (GDD §1.5)
  - Semua formasi yang aktif disusun menurut prioritas: **Utama** + maksimal 2 **Sekunder** (Formation Cap 3).
  - **Satu formasi per jenis**, dan tiap Sekunder harus **menambah minimal satu kartu** yang belum dihitung. Tautan Kembar di dalam Triad tidak dihitung dua kali, tetapi Tangga yang menyambung Triad dihitung.
  - Semua kartu dalam rantai mencetak skor lalu keluar dari papan; kartu lain tetap sebagai Residu.
  - Nama tangan menampilkan rantainya, mis. `Triad + Tangga`.
  - **Fase Rantai**: tiap Sekunder menambah **50%** chips dan mult formasi itu (sesuai levelnya). Nama formasi dan `+chips`/`+Mult` muncul di kartu pertamanya.
  - Tanpa formasi: **Percikan**. Hanya kartu baru dengan rank tertinggi yang mencetak skor; kartu baru lain menjadi Residu.
  - Aturan run baru untuk joker nanti: `ne_formation_cap` (3) dan `ne_chain_pct` (50).
  - Pakta Neraka dan Garis Halo memberi +3 Corruption / +2 Divinity saat masuk rantai. Keduanya butuh kartu Iblis/Berkah dari Fase 7.
  - Hanya formasi Utama yang tercatat "dimainkan" (angka `#` di Run Info, The Ox).
- **Detail aturan**
  - Suit memakai aturan flush game: kartu Wild cocok dengan semua suit, Stone tidak punya rank maupun suit.
  - Formasi berurut dibaca sesuai arah garis (naik atau turun). As boleh tinggi atau rendah, tetapi K-A-2 tidak sah.
  - Rincian aturan ditambahkan ke GDD §1.3–1.6.
- **Pratinjau** (GDD §1.2)
  - Nama rantai, chips, dan mult tampil sebelum Play.
  - Pratinjau memakai posisi sebenarnya: kartu yang ditempatkan di petaknya, kartu terpilih lain di petak yang akan diberikan main cepat.
  - Pratinjau dihitung ulang saat kartu ditempatkan, ditarik keluar papan, atau urutan tangan diubah.
- **17 planet** (Empyrea … Proxima), satu per formasi.
  - Sprite planet baru menampilkan diagram formasinya.
  - Planet vanilla disembunyikan dari pool. Opsi config ini sekarang menyala default; config lama dinyalakan sekali otomatis.
  - Blue Seal, Telescope, Observatory, Black Hole, dan Celestial Pack memakai mekanisme vanilla.
- **Run Info → Poker Hands**: tiap formasi punya diagram mini 5×3. Hover menampilkan deskripsi dan contoh kartu.
- **Patch L12** (`lovely/35_formations.toml`, 2 patch): most played hand (The Ox) default Percikan dan hanya menghitung formasi. Kedua patch sudah dicek cocok tepat sekali pada simulasi dump.
- **Save lama** (Fase 5) tetap bisa dilanjutkan: data formasi ditambahkan saat load, hand vanilla disembunyikan.
- **Debug**
  - F9: baris `Formation` berisi rantai evaluasi terakhir, cap, persen rantai, serta jumlah evaluasi dan cache hit.
  - Cheat baru:
    - **Tangan: preset formasi**: kartu pertama di tangan diubah; tiap klik ganti preset: Triad+Tangga → Tautan Penuh → Barisan Berurut → Barisan Senada → Barisan Agung → Kotak Empat → Kompas.
    - **Formasi: +1 level**.
    - **Beri 2 planet**.
- **Tes**
  - 1613 pemeriksaan lulus, termasuk ±500 pemeriksaan formasi: pola, 17 formasi, aktivasi, rantai, cap, Percikan, papan 6×4/4×2, cache, pratinjau, alur Play, save lama, L12, planet, diagram, cheat, dan lokalisasi.
  - `get_poker_hand_info` dan `evaluate_poker_hand` di mock adalah salinan persis dari Steamodded.
  - Uji kode game asli dari Fase 5 tetap 52/52.
  - Kecepatan: satu evaluasi papan 5×3 penuh jauh di bawah 0,5 ms. Evaluasi hanya berjalan saat pilihan/papan berubah, tidak per frame.

## Cara uji di game

1. **Boot**
   - Log berisi `New Era 0.6.0~dev loaded` tanpa error.
   - Log Lovely tidak berisi peringatan "no matches" untuk `35_formations.toml`.
2. **Run Info** (tombol Run Info → Poker Hands)
   - Ada 17 formasi, masing-masing dengan diagram kecil di kiri. Tidak ada poker hand vanilla.
   - Hover satu baris: deskripsi dan contoh kartu tampil.
3. **Rantai** (F10 → *Tangan: preset formasi*, preset pertama)
   - Lima kartu pertama di tangan menjadi 7♣ 7♦ 7♥ 8♠ 9♥.
   - Pilih kelimanya (tanpa menyeret). Pratinjau: `Triad + Tangga`.
   - Play. Kelimanya masuk baris Tengah. Sebelum kartu dihitung, di kartu ke-3 muncul `Tangga`, `+15`, dan `+1.5 Mult`. Nilai awal menjadi 50 × 4.5.
   - Kelima kartu keluar dari papan.
4. **Posisi menentukan formasi**
   - Preset *Barisan Berurut*: pilih 5 kartu, pratinjau `Barisan Berurut`.
   - Seret kartu tengah (7) ke baris Depan. Pratinjau berubah, karena baris Tengah tidak lagi berurut (mis. menjadi `Percikan`).
   - Seret kembali ke tangan. Pratinjau kembali seperti awal.
5. **Residu + aktivasi**
   - Mainkan 5 kartu tanpa formasi (Percikan). Hanya kartu tertinggi yang keluar; 4 lainnya jadi Residu.
   - Tempatkan kartu baru yang membentuk Tautan Kembar/Triad dengan Residu. Pratinjau menunjukkan formasinya. Setelah Play, Residu yang ikut formasi keluar.
   - Dua Residu yang sudah berpasangan tidak dihitung lagi jika kartu baru tidak menyentuhnya.
6. **Formasi bentuk** (tempatkan manual dengan seret)
   - Preset *Kotak Empat*: 4 Queen dalam persegi 2×2.
   - Preset *Kompas*: 5 Diamond berbentuk + dengan pusat di baris Tengah.
7. **Planet**
   - F10 → *Beri 2 planet*. Hover: `lvl.1`, nama formasi, `+Mult`/`+chips`. Pakai: level formasi naik (cek Run Info).
   - Toko dan Celestial Pack hanya berisi planet New Era.
   - *Formasi: +1 level* menaikkan semua formasi.
8. **Save/load**
   - Di tengah ronde → menu utama → Continue. Run Info dan pratinjau tetap normal.
   - Jika masih ada save dari Fase 5, lanjutkan: tidak crash, formasi muncul, hand vanilla hilang.
9. **F9**: baris `Formation` berubah saat pilihan berubah, dan `cache hits` naik.
10. **Opsional**: jika bertemu boss The Ox, teksnya menyebut sebuah formasi.

Tolong kirim hasil tiap langkah, terutama screenshot langkah 2, 3, dan 7 (tooltip planet).

## Known issues

- **Pakta Neraka dan Garis Halo belum bisa dibentuk.** Kartu Iblis/Berkah baru ada di Fase 7, tetapi planetnya sudah bisa muncul.
- **Garis Lima** butuh 5 kartu rank sama dalam satu baris, jadi dengan dek standar perlu kartu duplikat (seperti Five of a Kind vanilla).
- **Nama rantai panjang** mengecil di kotak nama tangan. Ini skala teks vanilla (mis. `Gerbang Surga + …`).
- **Diagram Run Info selalu 5×3**, termasuk setelah papan di-resize. Diagram hanya contoh pola.
- **Contoh kartu** di tooltip Pakta Neraka/Garis Halo masih kartu biasa sampai enhancement Fase 7 ada.
- **Boss vanilla** yang menghitung kartu di area main tetap menghitung Residu (The Psychic, The Tooth), sampai boss prosedural di Fase 10.
- **Keseimbangan** (nilai formasi, bonus rantai 50%, cap 3) belum diuji dalam run panjang. Nilainya dari GDD dan mudah diubah.
- **Kontroler dan layar sentuh** belum diuji untuk alur formasi.
