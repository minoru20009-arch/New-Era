# Fase 5 — Papan

## Yang berubah

- **Papan 5×3** (GDD §1.1)
  - Area main `G.play` dibentuk ulang menjadi grid 15 petak di antara baris joker dan tangan.
  - Baris atas = **Belakang**, baris tengah = **Tengah**, baris bawah = **Depan** (paling dekat ke tangan).
  - Kartu digambar mengecil ke belakang (Depan 100%, Tengah 92%, Belakang 84%). Baris saling menumpuk sedikit untuk kesan kedalaman.
  - Kartu yang disorot kursor selalu digambar paling atas, jadi tidak pernah tertutup baris di depannya.
  - Petak kosong berwarna: **biru** = Depan, **merah** = Belakang, netral = Tengah. Petak hanya tampil selama blind.
- **Efek baris** (untuk kartu yang mencetak skor)
  - **Depan**: chips dasar kartu ×2. Contoh: 7 memberi +14. Hanya chips rank yang digandakan; bonus enhancement tidak ikut, dan Stone Card tetap 50.
  - **Belakang**: +2 Mult.
  - **Tengah**: netral.
- **Menempatkan kartu** (GDD §1.2)
  - **Seret** kartu dari tangan ke petak kosong. Kartu duduk di petak itu dan terhitung sebagai kartu terpilih.
  - Atau **pilih kartu lalu klik petak kosong**: kartu terpilih paling kiri yang belum punya petak akan ditempatkan.
  - **Klik** kartu yang sudah ditempatkan, atau **seret keluar** dari papan, untuk mengembalikannya ke tangan.
  - **Main cepat**: pilih kartu seperti biasa lalu tekan Play. Kartu tanpa petak ditempatkan otomatis: baris Tengah kiri→kanan, lalu Depan, lalu Belakang. Gaya main vanilla tetap berjalan.
  - Batas main dan batas pilihan tetap seperti vanilla (5 kartu). Play nonaktif jika jumlah kartu terpilih melebihi petak kosong.
  - Teknis: kartu yang ditempatkan sebelum Play tetap berada di tangan sebagai kartu terpilih, dengan petak yang dipesan. Karena itu semua aturan vanilla (tarot, discard, efek "kartu dimainkan", statistik) melihat kartu biasa. Ini mengubah rancangan awal di dokumen arsitektur, yang sudah diperbarui.
- **Residu**
  - Setelah skor dihitung, kartu yang **mencetak skor** meninggalkan papan. Sisanya tetap di tempat sebagai **Residu** dan ikut dievaluasi pada tangan berikutnya.
  - Sampai Fase 6, "kartu yang mencetak skor" = kartu poker hand vanilla.
  - **Batas Residu** (aturan baru, ditambahkan ke GDD): paling banyak *petak − batas main* = 10 kartu. Residu tertua keluar lebih dulu. Dengan begitu papan selalu muat satu tangan penuh dan ronde tidak bisa terkunci.
  - **Discard Residu**: klik kartu Residu (terangkat sedikit), lalu tekan Discard. Aturan discard vanilla berlaku (jatah discard, batas 5 kartu termasuk kartu tangan, efek discard joker/seal).
  - Akhir ronde: seluruh papan dibuang lalu kembali ke dek bersama kartu lain.
  - Residu tidak menghalangi apa pun: tarot/planet tetap bisa dipakai, joker bisa dijual, klik kanan tetap membatalkan pilihan.
  - Ronde yang hanya menyisakan Residu (tangan dan dek kosong) langsung berakhir.
- **Kontroler**
  - Petak kosong bisa difokus dengan D-pad.
  - **A** di petak kosong menempatkan kartu terpilih; A di Residu memilihnya untuk discard.
  - **LB** memindah fokus antara tangan dan papan; **B** di papan kembali ke tangan.
- **Save/load**
  - Posisi petak, status Residu, dan ukuran papan tersimpan bersama run.
  - Save lama (Fase 4) otomatis mendapat papan 5×3.
- **API untuk efek berikutnya** (`NE.Board`): `slot_of`, `card_at`, `neighbors`, `adjacent`, `row_full`, `residues`, `place`, `swap`, `shuffle_residues`, `resize`, `keeps`, `busy`, dan context `ne_board_changed`.
- **Patch Lovely** (`lovely/30_board.toml`, 5 patch):
  - **L13a–c**: pemeriksaan "G.play berisi kartu" (guard Play, pakai consumable, jual joker, klik kanan) sekarang hanya aktif selama tangan berjalan.
  - **L14**: Residu tidak ikut dibuang di akhir tangan.
  - Pemeriksaan "kartu habis" memakai wrap Lua, bukan patch. Patch baris itu akan memanggil `end_round()` di setiap frame.
  - Kelima patch sudah dicek cocok tepat sekali pada simulasi dump (vanilla + SMODS).
- **Debug**
  - Cheat baru: **Papan: +4 Residu** (dari dek), **Papan: ukuran 5x3/6x4/4x2**, **Papan: acak Residu**, **Papan: kosongkan**.
  - Overlay F9 menambah baris `Board`: ukuran, jumlah kartu/Residu, kartu yang ditempatkan, pilihan discard, petak kosong.
- **Config**: opsi **Kartu papan lebih kecil** (skala 85%) di Mods → New Era → Config.
- **Tes**
  - 950 pemeriksaan lulus. Mock kini punya kelas `Object/Node/Moveable/CardArea/Card/Controller` dan alur main/discard dengan baris yang dipatch.
  - Uji terpisah memakai kode game asli (CardArea hasil patch SMODS, `draw_card`, fungsi main/discard/akhir ronde dengan patch New Era): 37/37 lulus.
  - Diukur dengan interpreter: menata dan menggambar papan per frame tidak mengalokasikan memori.

## Cara uji di game

1. **Boot**
   - Log berisi `New Era 0.5.0~dev loaded` tanpa error.
   - Di log Lovely, tidak ada peringatan "no matches" untuk `30_board.toml`.
2. **Tampilan**: mulai run, pilih blind.
   - 15 petak tampil di antara joker dan tangan.
   - Tidak bertabrakan dengan joker, tangan (termasuk kartu yang terangkat saat dipilih), maupun tombol Play/Discard.
   - Mohon kirim screenshot di 1280×720, dan di resolusi 4:3 jika bisa.
3. **Main cepat**: pilih 5 kartu yang berisi satu Pair, lalu Play.
   - Kelima kartu masuk baris Tengah.
   - Pair mencetak skor lalu keluar; 3 kartu lain tetap sebagai Residu.
4. **Penempatan**
   - Seret kartu ke petak biru (Depan) dan ke petak merah (Belakang).
   - Pilih kartu lalu klik petak kosong.
   - Klik kartu yang sudah ditempatkan (kembali ke tangan), dan seret satu kartu keluar dari papan.
   - Play: kartu mendarat di petak pilihan. Popup chips kartu di baris Depan dua kali lipat, kartu di baris Belakang memberi `+2 Mult`.
5. **Residu + tangan baru**
   - Mainkan kartu yang membentuk Pair bersama Residu. Pratinjau nama tangan harus sudah menghitung Residu sebelum Play.
   - F9: baris `Board` tidak pernah lebih dari `Residue 10 / max 10`.
6. **Discard Residu**
   - Klik satu Residu (terangkat), tekan Discard. Kartu pindah ke tumpukan discard dan jatah discard berkurang satu.
   - Coba juga Residu + kartu tangan sekaligus.
7. **Tidak terkunci**
   - Dengan Residu di papan: pakai tarot/planet, jual joker, klik kanan untuk batal pilih.
   - Mainkan sampai dek habis: ronde harus berakhir normal.
8. **Akhir ronde**: papan kosong setelah blind selesai. Di toko, jumlah kartu dek (F9 `Deck`) kembali penuh.
9. **Save/load**: di tengah ronde dengan Residu → menu utama → Continue. Residu ada di petak yang sama; lanjut main.
10. **Cheat F10**
    - **Papan: +4 Residu**, lalu **Papan: ukuran** tiga kali (6x4 → 4x2 → 5x3). Cek tata letak 6x4 masih muat, dan tidak ada kartu hilang saat mengecil (kelebihan pindah ke discard).
    - **Papan: acak Residu** dan **Papan: kosongkan**.
11. **Config**: nyalakan **Kartu papan lebih kecil**, lalu kembali ke run. Papan mengecil.
12. **Kontroler** (jika ada)
    - Pilih kartu dengan A, tekan LB (fokus ke petak kosong pertama), lalu A untuk menempatkan.
    - D-pad antar petak; B kembali ke tangan.

Tolong kirim hasil tiap langkah, terutama screenshot langkah 2, 4, dan 10.

## Known issues

- **Formasi belum ada (Fase 6).** Skor masih memakai poker hand vanilla atas seluruh isi papan (Residu + kartu baru). Akibatnya:
  - Flush/Straight bisa memuat lebih dari 5 kartu.
  - Residu saja bisa membentuk tangan tanpa kartu baru. Aturan "pola harus memuat kartu baru" baru berlaku di Fase 6.
- **Boss vanilla** yang menghitung kartu di area main juga menghitung Residu (sampai boss prosedural di Fase 10):
  - The Tooth menagih $1 per kartu di papan.
  - The Psychic ("harus 5 kartu") lebih mudah dipenuhi.
- **Kartu yang ditempatkan tetap terhitung terpilih**, jadi tombol Discard ikut membuangnya. Ini perilaku pilihan vanilla.
- **Tampilan petak masih sederhana** (persegi membulat). Shader papan, garis formasi, dan pseudo-3D ada di Fase 12–13.
- **Tata letak dan kontroler belum pernah dilihat/diuji di game.** Geometri dihitung dari posisi area vanilla. Jika ada tabrakan, beri tahu saya; ukuran mudah diubah (atau pakai opsi kartu kecil).
- **Layar sentuh** belum diuji.
