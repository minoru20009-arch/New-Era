# 01 — GDD Sistem Inti

Notasi yang dipakai di seluruh dokumen:

| Simbol | Arti |
|---|---|
| `+X Mult`, `xX Mult`, `+X Chips`, `xX Chips` | Seperti vanilla |
| `^X Mult` | Mult dipangkatkan X (`mult = mult^X`) |
| `^^X Mult` | Tetrasi (`mult = mult↑↑X`) |
| `{n}X Mult` | Operator panah ke-n (`mult = mult↑ⁿX`); `{3}` = pentasi |
| `+X Aura` | Menambah eksponen skor akhir (§3.3) |
| ✦ | Divinity (Keilahian) |
| ☠ | Corruption (Korupsi) |
| ⧗ | Time (Waktu) |

---

## 1. Papan (Board) & Formasi — pengganti poker hand

### 1.1 Papan

- **Ukuran dasar 5 kolom × 3 baris = 15 petak.** Baris: **Depan**, **Tengah**, **Belakang** (Depan paling dekat ke tangan pemain).
- Papan **adalah** area `G.play` yang diubah bentuknya (lihat arsitektur). Dengan begitu semua context SMODS yang memakai `G.play` / `context.cardarea == G.play` tetap berlaku.
- **Efek baris** (posisi memengaruhi hasil):

| Baris | Efek saat kartu di baris itu dicetak |
|---|---|
| Depan | Chips dasar kartu **x2** |
| Tengah | Netral |
| Belakang | **+2 Mult** per kartu |

- **Persistensi:** kartu yang sudah di papan **tetap tinggal** antar tangan dalam satu ronde. Kartu yang menjadi bagian formasi yang mencetak skor akan **terpakai** (dibuang) setelah tangan selesai. Kartu lain tetap di tempat sebagai **Residu** dan bisa membentuk formasi dengan kartu baru. Saat ronde berakhir, seluruh papan dibuang.
- **Residu terkunci:** kartu residu tidak bisa dipindah kecuali oleh efek (mis. Tatsumaki, Sasuke). Aksi **Discard** boleh memilih kartu residu di papan (memakai jatah discard seperti biasa).

### 1.2 Menempatkan kartu (alur satu tangan)

1. **Tempatkan:** seret kartu dari Tangan Utama atau Tangan Bayangan ke petak kosong. Kartu itu berstatus *staged*. Klik kartu staged untuk mengembalikannya ke tangan.
2. **Main cepat:** jika pemain hanya meng-highlight kartu (tanpa menyeret) lalu menekan Play, kartu ditempatkan otomatis: Baris Tengah kiri→kanan, lalu Depan, lalu Belakang. Dengan cara ini gaya bermain vanilla tetap bisa dipakai.
3. **Batas main:** maksimal **5 kartu baru** per tangan (dapat diubah efek; memakai `SMODS.change_play_limit`).
4. **Pratinjau:** setiap kali penempatan berubah, evaluator dijalankan dan nama formasi ditampilkan di area teks tangan (mis. `Triad + Tautan Kembar`). Evaluasi dipicu event, **bukan per frame**.
5. **Play:** fase skor berjalan (§3.2). Kartu formasi dibuang, residu tetap tinggal.
6. **Kontroler:** tombol khusus memindahkan fokus ke papan; D-pad memilih petak; A menempatkan kartu yang di-highlight; B kembali ke tangan.

### 1.3 Garis dan bentuk yang dikenali

Semua pola dihitung sekali saat load (tabel indeks statis):

| Pola | Definisi | Jumlah di papan 5×3 |
|---|---|---|
| Pasangan bersebelahan | 2 petak bersebelahan ortogonal | 22 |
| Garis-3 | 3 petak berurutan dalam satu garis lurus (horizontal, vertikal, diagonal) | 20 |
| Baris penuh | 5 petak satu baris | 3 |
| Blok 2×2 | 4 petak membentuk persegi | 8 |
| Kompas | petak tengah + 4 tetangga ortogonal (pusat hanya di Baris Tengah kolom 2–4) | 3 |
| Papan penuh | 15 petak | 1 |

**Aktivasi:** sebuah pola hanya diperiksa jika memuat **minimal satu kartu yang baru ditempatkan** di tangan ini. Pengecualian: *Gerbang Surga* selalu memeriksa papan penuh. Jadi residu tidak memicu formasi yang sama berulang-ulang.

### 1.4 Daftar formasi (17)

Semua formasi didaftarkan sebagai `SMODS.PokerHand` dengan key `ne_*`. Kolom "Level" = tambahan per level (chips/mult). Urutan prioritas = urutan tabel (atas = tertinggi).

| # | Key | Nama (ID / EN) | Syarat | Chips × Mult | Level | Planet |
|---|---|---|---|---|---|---|
| 1 | `ne_heavens_gate` | Gerbang Surga / Heaven's Gate | Ketiga baris masing-masing membentuk formasi baris (Barisan Senada, Berurut, Agung, atau Garis Lima) | 250 × 20 | +60 / +6 | Empyrea |
| 2 | `ne_five_line` | Garis Lima / Five Line | Baris penuh, 5 kartu rank sama | 130 × 12 | +45 / +4 | Polaris |
| 3 | `ne_royal_row` | Barisan Agung / Royal Row | Baris penuh, suit sama **dan** rank berurutan sesuai urutan kiri→kanan (naik/turun) | 110 × 8 | +40 / +4 | Andromeda |
| 4 | `ne_quad_square` | Kotak Empat / Quad Square | Blok 2×2 rank sama | 70 × 7 | +35 / +3 | Pegasus |
| 5 | `ne_hell_pact` | Pakta Neraka / Hell Pact | Garis-3 yang seluruhnya kartu **Iblis** (§2) | 60 × 6 | +30 / +3 | Nibiru |
| 6 | `ne_halo_line` | Garis Halo / Halo Line | Garis-3 yang seluruhnya kartu **Berkah** (§2) | 60 × 6 | +30 / +3 | Sirius |
| 7 | `ne_compass` | Kompas / Compass | Pola Kompas, 5 kartu suit sama | 60 × 5 | +35 / +3 | Crux |
| 8 | `ne_full_link` | Tautan Penuh / Full Link | Triad + Tautan Kembar yang tidak berbagi kartu | 50 × 4 | +30 / +2 | Perseus |
| 9 | `ne_row_flush` | Barisan Senada / Row Flush | Baris penuh, suit sama | 45 × 4 | +30 / +2 | Cygnus |
| 10 | `ne_row_straight` | Barisan Berurut / Row Straight | Baris penuh, rank berurutan sesuai urutan kiri→kanan (naik/turun; As boleh tinggi/rendah) | 40 × 4 | +30 / +2 | Sagitta |
| 11 | `ne_bastion` | Benteng / Bastion | Blok 2×2 suit sama | 40 × 4 | +25 / +2 | Draco |
| 12 | `ne_triad` | Triad | Garis-3 rank sama | 35 × 3 | +25 / +2 | Orion |
| 13 | `ne_ascent` | Tangga / Ascent | Garis-3 rank berurutan sesuai arah garis | 30 × 3 | +25 / +2 | Aquila |
| 14 | `ne_double_link` | Tautan Ganda / Double Link | Dua Tautan Kembar yang tidak berbagi kartu | 25 × 2 | +20 / +1 | Pollux |
| 15 | `ne_kin_trio` | Trio Sekerabat / Kin Trio | Garis-3 suit sama | 20 × 2 | +15 / +1 | Lyra |
| 16 | `ne_twin_link` | Tautan Kembar / Twin Link | Pasangan bersebelahan rank sama | 10 × 2 | +15 / +1 | Gemini |
| 17 | `ne_spark` | Percikan / Spark | Tidak ada formasi; yang dicetak hanya kartu baru dengan rank tertinggi | 5 × 1 | +10 / +1 | Proxima |

Catatan:
- Kartu **Wild**/"semua suit" dan efek seperti Four Fingers vanilla tetap berlaku lewat primitif `get_flush`/`get_straight` yang dipakai ulang di dalam evaluator.
- Formasi ber-tema (Pakta Neraka, Garis Halo) memberi ☠+3 / ✦+2 setiap kali dimainkan.

### 1.5 Rantai formasi (banyak formasi dalam satu tangan)

- Evaluator mengumpulkan **semua** formasi yang aktif, lalu mengurutkannya berdasarkan prioritas.
- **Formasi Utama** = formasi prioritas tertinggi. Chips/Mult dasarnya dipakai seperti poker hand vanilla (`scoring_name`).
- **Formasi Sekunder**: hingga batas **Formation Cap** (dasar 3 formasi total). Masing-masing menambah **50%** chips dan mult dasarnya (sesuai level) pada fase Rantai. Joker dapat menaikkan persentase ini atau batasnya.
- Satu kartu boleh menjadi anggota beberapa formasi. Kartu itu tetap dicetak **sekali** (joker tertentu mengubahnya).
- `scoring_hand` = gabungan semua kartu formasi yang dihitung. Kartu papan lain = `unscored`.
- Teks tampilan: `Utama + Sekunder1 + Sekunder2`.

### 1.6 Level, planet, dan UI

- Level per formasi disimpan di `G.GAME.hands[key]` (mekanisme SMODS, ikut save otomatis).
- 17 planet baru (set `Planet`) dengan `config.hand_type = key formasi`. Blue Seal, Telescope, Observatory, Black Hole, dan Celestial Pack otomatis bekerja karena memakai `config.hand_type` (terverifikasi di Fase 0).
- Menu Run Info → tab Hands: tiap baris formasi mendapat **diagram mini 5×3** yang menyorot pola (digambar prosedural).
- `most_played_poker_hand` default diubah dari `'High Card'` ke `ne_spark`.

---

## 2. Twin Hands (Dua Tangan) & Dua Dek

| Zona | Isi | Ukuran dasar |
|---|---|---|
| Dek Utama (`G.deck`) → **Tangan Utama** (`G.hand`) | Kartu biasa | 8 |
| Dek Bayangan (`G.ne_shadow_deck`) → **Tangan Bayangan** (`G.ne_shadow_hand`) | Kartu **Iblis** | 2 (hanya muncul jika Dek Bayangan berisi kartu) |
| Papan (`G.play`) | §1 | 15 petak |

- **Kartu Iblis** (enhancement `m_ne_demon`): x1.5 Mult saat dicetak, memberi ☠+2. Kartu Iblis selalu kembali ke Dek Bayangan, bukan ke Dek Utama.
- **Masuk Dek Bayangan:** kartu yang dikorupsi oleh joker Demonic, trait boss, atau event.
- **Kartu Berkah** (enhancement `m_ne_blessed`): +20 Chips dan ✦+1 saat dicetak. Tetap di Dek Utama.
- **Kartu Palsu** (enhancement `m_ne_fake`): dicetak normal lalu hilang tanpa memicu efek "dihancurkan".
- Kedua tangan diisi ulang bersamaan (awal ronde dan setelah tiap tangan/discard).
- Kartu dari kedua tangan boleh ditempatkan di papan pada tangan yang sama. Batas main dihitung gabungan.
- Tangan Bayangan +1 ukuran saat ☠ ≥ 50 (§4).

Stiker status sementara (dipakai joker/boss): `ne_bound` (terikat), `ne_phased` (difase), `ne_decay` (membusuk), `ne_bomb` (bom), `ne_frozen` (beku, tidak terbuang setelah dicetak).

---

## 3. Skor

### 3.1 Parameter & rumus

- Parameter per tangan: **Chips**, **Mult** (SMODS), dan **Aura** (`SMODS.Scoring_Parameter` baru, nilai awal 1.00).
- Rumus (`SMODS.Scoring_Calculation` `ne_ascend`):

  **Skor tangan = (Chips × Mult) ^ Aura**

- UI: kotak ketiga kecil setelah Mult bertuliskan `^1.00` (tersembunyi saat Aura = 1).
- Aura hanya disentuh oleh joker **Heavenly** dan trait boss (mis. *Segel Aura* mengunci Aura = 1).

### 3.2 Fase skor (urutan satu tangan)

| # | Fase | Context | Isi |
|---|---|---|---|
| 0 | **Pertanda** (Omen) | `ne_omen` | Setelah Play ditekan, **sebelum evaluasi**. Joker "pertama bertindak" (Killua), pemindahan papan (Tatsumaki, Whitebeard), time stop, snapshot untuk rewind. Trait boss tipe *Omen* juga di sini. |
| 1 | Formasi | `evaluate_poker_hand`, `modify_scoring_hand` (SMODS) | Evaluator menghitung formasi dan `scoring_hand`. |
| 2 | **Rantai** (Chain) | `ne_chain` (sekali per formasi sekunder) | Menambah nilai formasi sekunder; joker bisa bereaksi per formasi. |
| 3 | Skor kartu & joker | `before` → `initial_scoring_step` → `main_scoring`/`individual`/`repetition` → `joker_main` → `final_scoring_step` (SMODS) | Pipeline SMODS apa adanya. Efek baris (§1.1) diterapkan di `individual`. |
| 4 | **Kenaikan** (Ascension) | `ne_ascension` | Setelah semua joker, sebelum skor dihitung. Aura diterapkan; joker Heavenly boleh **menulis ulang hasil fase** (mengganti chips/mult/aura akhir). |
| 5 | **Penghakiman** (Judgment) | `ne_judgment` (membawa `score`, `overkill`) | Setelah skor ditambahkan ke blind. Trait boss tipe *Judgment* (damage cap, regenerasi), perpindahan fase boss, limpahan (spill) ke blind lain, penyelesaian mata uang. |
| 6 | Setelah | `destroy_card`, `after` (SMODS) | Kartu formasi dibuang, residu tetap di papan. |

Context tambahan untuk joker: `ne_boss_trait` (sebelum trait boss memicu; return `{ne_cancel = true}` untuk membatalkan), `ne_time_stop`, `ne_rewind`, `ne_phase_cleared`, `ne_encounter_cleared`, `ne_card_corrupted`, `ne_currency_changed`, `ne_map_node`, `ne_board_changed`, `ne_pre_game_over`.

### 3.3 Operator & key return baru

| Key return | Efek |
|---|---|
| `emult`, `echips` | `^X` pada Mult / Chips |
| `eemult` | `^^X` pada Mult |
| `hypermult = {n, x}` | `{n}X` pada Mult (n ≥ 2 = panah Knuth) |
| `aura`, `xaura` | `+X` / `xX` pada Aura |
| `divinity`, `corruption`, `time` | Mengubah mata uang (§4) |
| `ne_cancel` | Membatalkan trait/aksi (di context yang mendukung) |

Tetrasi dengan tinggi pecahan memakai aproksimasi linear standar OmegaNum: untuk `0 ≤ f < 1`, `x↑↑f = 1 + f·(x−1)`, lalu `x↑↑(n+f) = x^(x↑↑(n−1+f))`.

### 3.4 Aturan keamanan skor

- Tidak pernah ada `inf`/`nan`. Semua operasi saturasi pada `NE.Big.MAX`. Operasi tidak valid (mis. pangkat negatif untuk tetrasi) menghasilkan nilai aman dan mencatat log sekali.
- Uang (`$`), ante, level formasi, dan mata uang tetap Lua number, dengan batas atas `1e300`.

---

## 4. Mata Uang Run

| Mata uang | Sifat | Sumber | Pemakaian / efek |
|---|---|---|---|
| **✦ Divinity** | Bilangan bulat ≥ 0, tersimpan sepanjang run | Kartu Berkah, Garis Halo, joker Heavenly, boss dikalahkan (+2), node Kuil, event | Kemampuan aktif Heavenly; layanan Kuil; reroll jalur peta (3 ✦); memurnikan ☠ kapan saja lewat tombol HUD (1 ✦ = −2 ☠) |
| **☠ Corruption** | Meter 0–100 | Kontrak Demonic, Kartu Iblis, Pakta Neraka, trait boss *Lapar* | Ambang: **25** → joker Demonic x1.25 Mult; **50** → x1.5 dan Tangan Bayangan +1; **75** → budget trait boss +1. **100 → Penghakiman Neraka**: ☠ kembali ke 50 dan satu hukuman terjadi (hancurkan 1 joker non-eternal acak, prioritas Demonic / −1 tangan selama ante / −$20). Jenis hukuman ditentukan seed dan **ditampilkan lebih dulu** di HUD. Berkurang 5 setiap kunjungan Toko. |
| **⧗ Time** | Bilangan bulat 0–10 (batas dapat naik) | +1 per tangan tidak terpakai di akhir ronde (maks +2 per ronde), event, joker waktu | Kemampuan waktu (time stop, rewind, lompat fase). Boss *Chrono-Immune* menolak efek waktu. |

HUD: panel kecil di bawah uang: `✦ 12   ☠ ▮▮▮▯▯ 43   ⧗ 4/10`. Setiap perubahan memakai animasi angka (tanpa alokasi per frame).

---

## 5. Kemampuan Aktif

- Joker dengan kemampuan aktif menampilkan tombol **AKTIFKAN** saat di-highlight (di samping tombol Jual).
- Definisi per joker: biaya (✦/☠/⧗/$), frekuensi (`round`, `ante`, `run`), kondisi (`can_use`), dan target (tanpa target / kartu / joker / blind / trait).
- Pemilihan target memakai mode pilih sementara (klik target, atau D-pad + A).
- Kemampuan aktif bisa dipakai saat `SELECTING_HAND`, dan beberapa juga di Toko/Peta sesuai definisi.

---

## 6. Struktur Run

### 6.1 Peta per ante

- State baru **`NE_MAP`**. Setiap ante punya peta bercabang ala Slay the Spire:
  - 4 jalur (lane), 7 lantai: Lantai 0 = mulai, 1–5 = pilihan, 6 = **Boss**.
  - Generator: 4 jalur acak (seeded `pseudoseed('ne_map'..ante)`) berjalan dari lantai 1 ke 5, tiap langkah ke lane yang sama atau tetangga. Node yang bertumpuk digabung.
- Aturan penempatan jenis node:

| Lantai | Pilihan yang mungkin | Aturan |
|---|---|---|
| 1 | Pertarungan | Wajib |
| 2 | Pertarungan, Peristiwa, Harta | — |
| 3 | Toko, Elit, Kuil, Pertarungan | Minimal satu Toko di lantai ini |
| 4 | Pertarungan, Celah, Peristiwa, Elit | Celah mulai Ante 3 |
| 5 | Toko, Kuil, Harta | Minimal satu Toko |
| 6 | Boss | — |

- Tidak ada dua Toko berturut-turut pada satu jalur. Rata-rata 2–4 pertempuran per ante.
- Pratinjau node saat di-hover: target chips, trait, imunitas, hadiah.
- Reroll jalur (3 ✦): acak ulang lantai berikutnya pada jalur saat ini.

### 6.2 Jenis node

| Node | Isi | Hadiah |
|---|---|---|
| **Pertarungan** | 1 blind normal | $3 (lantai 1) / $4 (lantai 2+) |
| **Elit** | 1 blind dengan 1–2 trait (dari generator boss, budget lebih kecil) | $6 + pilih 1 dari 2 joker (bobot Demonic dinaikkan) |
| **Celah (Rift)** | Multi-blind: 2 blind (3 blind mulai Ante 12) | Jumlah hadiah semua blind + ✦2 + 1 tag |
| **Toko** | Toko vanilla (dengan joker New Era) | — |
| **Harta** | Pilih 1: paket joker New Era, $10, ✦3, ⧗2, atau 1 tag | — |
| **Kuil** | Layanan berbayar ✦: +1 tangan selama ante (5 ✦), murnikan 10 ☠ (3 ✦; harga dasar di luar Kuil 5 ✦), naik level 1 formasi (4 ✦), beri Berkah ke 1 kartu (2 ✦) | — |
| **Peristiwa** | Kejadian naratif crossover dengan pilihan (§6.5) | Bervariasi |
| **Boss** | Boss prosedural multi-fase | $8 + ✦2 + peluang joker Heavenly (lihat §8) |

- Skip blind vanilla (untuk tag) diganti oleh node non-tempur; tag sekarang berasal dari Harta, Celah, dan Peristiwa.
- Setelah cash out → kembali ke peta (bukan ke Toko). Keluar dari Toko → kembali ke peta.
- Setelah Boss: ante +1, peta baru dibuat.
- **Kemenangan:** mengalahkan Boss **Ante 10** menampilkan layar menang ("Era Baru"), lalu run berlanjut tanpa batas (endless).

### 6.3 Multi-blind (Celah)

- 2–3 blind aktif bersamaan. Masing-masing punya target chips dan trait sendiri. Semua trait aktif sampai blind pemiliknya kalah.
- **Target:** klik blind di HUD untuk memilihnya (default: blind hidup paling kiri).
- **Limpahan:** kelebihan skor (overkill) melimpah **50%** ke blind hidup berikutnya (joker bisa menaikkan).
- Menang jika semua blind kalah. Kalah jika tangan habis (sama seperti vanilla, game over kecuali diselamatkan efek).

### 6.4 Boss multi-fase

- Boss punya 1–4 fase. Setiap fase punya target chips dan trait sendiri.
- Saat target fase tercapai (di fase Penghakiman): animasi transisi, skor ronde **di-reset ke limpahan** (overkill × 50%), fase berikutnya aktif dengan trait barunya.
- HUD boss: bar HP dengan pip fase, daftar trait aktif, badge imunitas.

| Ante | Jumlah fase boss |
|---|---|
| 1–3 | 1 |
| 4–7 | 2 |
| 8–15 | 2–3 |
| 16–31 | 3 |
| 32+ | 4 |

### 6.5 Peristiwa (contoh katalog awal, ±20 akan ditulis di fase konten)

| Key | Judul | Pilihan (ringkas) |
|---|---|---|
| `ev_time_chamber` | Ruang Waktu Hiperbolik | Habiskan 1 tangan ante ini → ⧗+4 / pergi |
| `ev_dragon_balls` | Tujuh Bola Naga | Kumpulkan 1 bola (dilacak run); saat 7: kabulkan 1 permintaan (joker Heavenly acak / +3 level semua formasi / hapus ☠) |
| `ev_death_note` | Buku Hitam di Tanah | Ambil (☠+15, dapat 1 penggunaan "tulis nama" untuk Elit) / tinggalkan |
| `ev_tournament` | Turnamen Kekuatan | Lawan Elit tambahan sekarang dengan hadiah ganda / tolak |
| `ev_contract` | Kontrak Iblis | Pilih 1 dari 3 kontrak: kuat + biaya permanen |
| `ev_shrine_kami` | Kuil Terlupakan | Sumbang $ → ✦ (kurs naik tiap ante) |
| `ev_mirror` | Cermin Kyoka | Salin 1 joker (Unranked) / hancurkan cermin (+$) |
| `ev_rift_tear` | Robekan Dimensi | Masuk: node berikutnya menjadi Celah dengan hadiah x2 |
| `ev_forge` | Tempa Pedang | Korbankan 1 kartu → kartu lain jadi Berkah |
| `ev_gamble` | Meja Kasino Bebop | Taruh $: 1 dari 3 menang x3 |

---

## 7. Generator Boss Prosedural

### 7.1 Komposisi

**Boss = Arketipe + Fase + Trait + Imunitas.** Nama dibuat prosedural (`Arketipe` + gelar), mis. "Tyrant of the Seventh Gate".

| Arketipe | Gaya | Trait favorit |
|---|---|---|
| Warden | Bertahan | Plating, Regenerasi |
| Devourer | Memakan kartu/joker | Makan Residu, Pemakan Joker |
| Tyrant | Memaksa aturan | Tirani Formasi, Kunci Baris |
| Trickster | Menyembunyikan info | Terbalik, Tukar Posisi |
| Chronarch | Waktu | Pajak Waktu, Chrono-Immune |
| Seraph | Ilahi | Segel Aura, Pemurnian |
| Archfiend | Neraka | Lapar, Ledakan Korupsi |
| Colossus | Skala murni | Fase tambahan, target besar |

### 7.2 Trait (contoh; katalog lengkap ±48 di fase konten)

| Trait | Fase pemicu | Efek | Berlawanan dengan tag |
|---|---|---|---|
| Plating (Lapisan Baja) | Penghakiman | Skor per tangan maksimal 40% target fase | one-shot |
| Regenerasi | Penghakiman | Target naik 10% setiap tangan yang tidak menyelesaikan fase | — |
| Tirani Formasi | Pertanda | Formasi utama harus formasi X (diumumkan) | — |
| Kunci Baris | Pertanda | Satu baris papan tidak bisa dipakai | `board` |
| Gerhana | Skor | Kartu Iblis di-debuff | `shadow` |
| Pemurnian | Skor | Kartu Berkah di-debuff | `divine` |
| Pemutus Rantai | Rantai | Formasi sekunder tidak dihitung | — |
| Lapar | Setelah | ☠+3 per tangan | — |
| Pajak Waktu | Pertanda | Setiap tangan −1 ⧗ (jika 0: −$3) | `time_stop` |
| Terbalik | Draw | 3 kartu pertama tertutup | — |
| Makan Residu | Setelah | Hancurkan 1 residu acak di papan | `board` |
| Segel Aura | Kenaikan | Aura = 1 | `aura` |
| Peredam (Dampening) | Kenaikan | Semua operator hiper turun 1 tingkat (^^ → ^, ^ → x) | `hyper` |

### 7.3 Imunitas (counter terhadap tag joker)

| Imunitas | Menolak |
|---|---|
| Chrono-Immune | `time_stop`, `rewind` |
| Mirrorless | `copy` |
| Unstealable | `steal` |
| Indestructible | `destroy` (efek hancurkan/hapus terhadap blind, fase, trait) |
| Absolute | `nullify` (pembatalan efek boss) |
| Grounded | `board` (pemindahan kartu papan oleh joker) |
| Law-Bound | `rule` (penulisan ulang aturan) |
| Nameless | Death Note (#77) dan efek "sebut nama" |
| Inevitable | Membalikkan `nullify` level Heavenly (GER, Anos) — ante ≥ 40 |
| Beyond Erasure | Zeno (#104) — ante ≥ 40 |

**Glosarium tag joker.** Bisa di-counter imunitas: `time_stop`, `rewind`, `copy`, `steal`, `destroy`, `nullify`, `board`, `rule`. Hanya ditekan lewat trait (bukan imunitas): `hyper` (Peredam), `aura` (Segel Aura), `shadow` (Gerhana), `divine` (Pemurnian), `corrupt`, `scaling`, `retrigger`, `luck`, `time`. Tag deskriptif tanpa counter: `revive`, `protect`, `create`, `transmute`, `consumable`, `adapt`, `counter`, `blind`, `map`, `meta`.

### 7.4 Budget & counter-picking

- **Budget trait** per fase: `B = 2 + floor(ante / 3)` poin (+1 jika ☠ ≥ 75). Trait berharga 1–3 poin; imunitas 3 poin.
- **Maks imunitas per boss:** ante 1–7: 0 · 8–15: 1 · 16–31: 2 · 32+: 3.
- **Counter-picking:** bobot tiap imunitas = `1 + 2 × (jumlah joker pemain dengan tag terkait)`. Jadi boss cenderung melawan strategi dominan pemain.

### 7.5 Aturan "broken but fair"

1. Semua trait dan imunitas boss **terlihat sebelum** memilih node Boss (pratinjau peta).
2. Imunitas hanya berlaku **untuk blind itu**; tidak pernah menonaktifkan joker secara permanen.
3. **Pity:** jika dua boss berturut-turut meng-counter tag yang sama, boss berikutnya tidak boleh meng-counter tag itu.
4. Tidak ada imunitas terhadap efek skor dasar (+/x Mult/Chips). Yang di-counter adalah manipulasi aturan, bukan angka.
5. **#121 Kami Tenchi** mengabaikan semua imunitas (capstone), tetapi target chips tetap berlaku.

---

## 8. Rarity & Kemunculan Joker

| Rank (SMODS.Rarity) | Key | Bobot toko | Syarat | Harga |
|---|---|---|---|---|
| Unranked | `ne_unranked` | 0.75 | — | $4–7 |
| Demonic | `ne_demonic` | 0.22 | — | $8–14 |
| Heavenly | `ne_heavenly` | 0.03 | Muncul di toko mulai Ante 4 | $20–30 |

Sumber Heavenly lain: hadiah Boss (peluang 10% + 2% per ante, maks 40%), event tertentu, Kuil (ritual 15 ✦ setelah Ante 6).
Joker vanilla dikeluarkan dari pool (D1). Slot joker dasar tetap 5.

---

## 9. Model Balance

### 9.1 Kurva target chips

`B(a)` = target dasar ante `a`. Target node = `B(a) ×` faktor node (Pertarungan lantai 1: 1.0, lantai 2+: 1.5, Elit: 2.5, tiap blind Celah: 1.5, fase boss ke-i: `2 × 1.5^(i−1)`).

Kurva dirancang **kontinu** jika diukur dengan super-logaritma `s(a) = slog10(B(a))` (`B = 10↑↑s`). Tidak ada ante yang tiba-tiba melompat jauh lebih berat dari laju sebelumnya.

| Rentang ante | Rumus `B(a)` | Contoh | `s(a)` |
|---|---|---|---|
| 1–8 | Tabel: 300, 1.000, 3.000, 9.000, 27.000, 80.000, 240.000, 720.000 | — | 1.16 → 1.54 |
| 9–20 | `log10 B = 5.86 + 0.53·(1.9^(a−8) − 1)` | a=9 ≈ 2.2e6 · a=12 ≈ 1.7e12 · a=16 ≈ 2e95 · a=20 ≈ 4e1178 | 1.59 → 2.26 |
| 21–40 | `log10 log10 B = 3.07 + 0.36·(a−20)` | a=21 ≈ 1e2692 · a=30 ≈ e(4.7e6) · a=40 ≈ ee10.27 | 2.3 → 3.00 |
| 41–200 | `s = 3 + 0.002·(a−40) + 0.0004·(a−40)²` | a=50 ≈ eee1.54 · a=60 ≈ 10^10^631 · a=100 ≈ 10↑↑4.56 · a=200 ≈ 10↑↑13.6 | 3.00 → 13.6 |
| 201+ | `B = 10↑↑↑p`, `p = 2.015 + 0.0005·(a−200) + 0.00001·(a−200)²` | a=300 ≈ 10↑↑305 · a=500 ≈ 10↑↑↑3.07 | 13.6 → ∞ |

Stake menaikkan kurva: tiap tingkat stake memundurkan kurva 0.5 ante (dihitung dengan interpolasi pada `s(a)`).

### 9.2 Kurva kekuatan per rank (tujuan desain)

| Rank | Operator khas | Perkiraan ante yang bisa dicapai (build fokus tanpa rank lebih tinggi) |
|---|---|---|
| Unranked | `+Mult`, `xMult`, retrigger, sedikit manipulasi aturan | 8–12 |
| Demonic | `^Mult` 1.05–2, kontrak, manipulasi aturan kuat | 20–40 |
| Heavenly | `^^Mult` 1.1–3, Aura, penulisan ulang fase | 40–200 |
| #121 Kami Tenchi | `{3}` (pentasi) | 200+ |

Segmen kurva sengaja dicocokkan dengan operator: segmen eksponensial (9–20) butuh `^`, segmen dobel-eksponensial (21–40) butuh tumpukan `^` atau `^^` awal, segmen tetrasi (41–200) butuh Heavenly, segmen pentasi (201+) hanya terjangkau capstone.

### 9.3 Penyeimbang

- **Imunitas & trait** (§7) memotong manipulasi aturan, bukan angka.
- **Peredam** memaksa build hiper menumpuk operator cadangan.
- **Plating/Regenerasi** menghukum strategi one-shot dan strategi terlalu lambat.
- **☠ Corruption** membatasi spam kontrak Demonic.
- **Biaya ⧗/✦** membatasi frekuensi kemampuan waktu dan ilahi.
- Semua angka di dokumen joker adalah **nilai awal** yang akan disetel lewat playtest (Fase konten + balance pass).
