# 🧠 Brainstorming Part 3 — QR Anti-Manipulasi & Deep-Dive Role PETANI

---

## 1. QR Code — Bisa Dimanipulasi?

**Pertanyaan Anda sangat valid.** Secara fisik, ya — label QR bisa dilepas dan ditempel ke boks lain. Tapi inilah cara sistem mencegahnya:

### Lapisan Keamanan Anti-Manipulasi

| Lapisan | Mekanisme | Penjelasan |
|---------|-----------|------------|
| **1. Identitas Aktor** | Setiap scan tercatat SIAPA yang scan | Pengepul A scan batch X → tercatat. Kalau beda orang yang scan, ketahuan |
| **2. Jumlah Cocokkan** | Petani catat 50 kg → Pengepul harus konfirmasi berapa kg diterima | Kalau petani catat 50 kg tapi pengepul terima 30 kg, ada selisih yang tercatat |
| **3. Timestamp** | Setiap aksi punya waktu | Kalau batch "diterima" sebelum "dikirim", urutan tidak masuk akal |
| **4. Foto Bukti** | Setiap role bisa lampirkan foto | Foto durian saat panen vs saat diterima → bisa dicocokkan visual |
| **5. Lokasi (opsional)** | GPS saat scan | Petani di Jember, tapi scan dari Jakarta? Anomali terdeteksi |
| **6. One-time Verify** | Satu batch hanya bisa diverifikasi 1x per role | Batch yang sudah verified tidak bisa di-verify ulang oleh pengepul lain |

### Analogi Sederhana
> QR Code itu seperti **nomor seri di uang kertas**. Uang bisa dipalsukan, tapi nomor seri yang tercatat di bank membuat pemalsu bisa dilacak. **QR bukan kunci gembok, tapi saksi digital.**

### Yang Ditambahkan ke Sistem
Setiap perpindahan batch menciptakan **catatan permanen**:
```
Batch DRN-2026-000128:
├── 24 Mei 2026 08:30 — Dibuat oleh Petani Risqi (50 kg, Grade A, Montong)
├── 25 Mei 2026 10:15 — Diverifikasi Pengepul Ahmad (terima 48 kg, foto ✓)
├── 26 Mei 2026 14:00 — Dikirim Distributor Budi (tujuan: Surabaya)
├── 27 Mei 2026 09:30 — Diterima UMKM Sari (48 kg, foto ✓)
└── 28 Mei 2026 16:00 — Diolah jadi Pancake Durian (PCK-2026-000001)
```

Kalau ada yang curang di tengah, **timeline tidak akan nyambung** — dan admin bisa lihat anomali.

---

## 2. Notification Banner — Android

Benar, ini bukan fitur iOS-specific. Banner yang ada sekarang menggunakan **Flutter Overlay** — bekerja di semua platform termasuk Android versi lama. Tidak ada dependency ke iOS notification system.

---

## 3. Flow Sudah Confirmed ✅

Pemahaman Anda sudah benar:
```
Petani buat batch + QR → tempel di boks fisik
    → Pengepul scan QR saat terima → verifikasi (batch ini milik petani A)
    → Distributor scan QR saat ambil dari pengepul → catat kirim
    → UMKM scan QR saat terima → konfirmasi + proses olahan
    → Konsumen scan QR di kemasan → lihat seluruh perjalanan
```

Setiap role **scan QR = konfirmasi bahwa barang fisik sudah berpindah tangan**.

---

## 4. DEEP-DIVE: ROLE PETANI 🌿

Sekarang kita bedah tuntas role Petani. Mari evaluasi apa yang sudah ada dan apa yang perlu diubah.

### 4.1 Fitur Petani yang Sudah Ada

| # | Fitur | Screen | Status |
|---|-------|--------|--------|
| 1 | **Beranda** | `farmer_home_screen.dart` | ✅ Statistik, filter, daftar batch, search |
| 2 | **Tambah Batch Panen** | `add_batch_screen.dart` | ✅ Form lengkap |
| 3 | **Detail Batch** | `batch_detail_screen.dart` | ✅ Info + timeline + edit window |
| 4 | **QR Code Batch** | `batch_qr_screen.dart` | ✅ Generate QR |
| 5 | **Manajemen Kebun** | `farm_management_screen.dart` | ✅ CRUD kebun |
| 6 | **Buat Kebun** | `create_farm_screen.dart` | ✅ Form lokasi detail |
| 7 | **Profil** | `farmer_profile_screen.dart` | ✅ View profil |
| 8 | **Edit Profil** | `edit_profile_screen.dart` | ✅ Edit data diri |
| 9 | **Tentang** | `about_screen.dart` | ✅ Info app |
| 10 | **Bantuan** | `help_screen.dart` | ✅ FAQ/help |

### 4.2 Apakah Tracking Per BATCH atau Per BUAH?

**Jawaban tegas: Tetap PER BATCH.** Alasan:

| Aspek | Per Batch ✅ | Per Buah ❌ |
|-------|-------------|------------|
| Realistis | Petani panen puluhan-ratusan kg sekaligus | Petani tidak mungkin label tiap buah |
| Efisien | 1 QR = 1 boks/karung | 50 buah = 50 QR? Tidak praktis |
| Industri | Standar agribisnis internasional = per lot/batch | Hanya berlaku untuk produk premium individual |
| Traceability | Cukup akurat sampai level batch | Over-engineering tanpa value tambah signifikan |

**Satuan yang tepat**: `kg` (default) dan `buah` (opsional untuk kasus khusus). Sudah benar di kode saat ini.

### 4.3 Field "Tambah Batch Panen" — Evaluasi

Field saat ini vs rekomendasi:

| # | Field | Saat Ini | Status | Catatan |
|---|-------|----------|--------|---------|
| 1 | Lokasi Kebun | ✅ Dropdown dari Farm | ✅ TETAP | Wajib, sudah benar |
| 2 | Varietas Durian | ✅ Dropdown | ✅ TETAP | Montong, Bawor, Petruk, Musang King, Bido, Pelangi — sudah cukup |
| 3 | Pupuk | ✅ Dropdown | ✅ TETAP | Organik Kompos, NPK, Kandang, Hayati, Tanpa Pupuk |
| 4 | Metode Panen | ✅ Dropdown | ✅ TETAP | Jatuh Alami, Petik Matang, Petik Selektif |
| 5 | Grade/Mutu | ✅ Dropdown (A/B/C) | ✅ TETAP | Grade awal dari petani, immutable |
| 6 | Tanggal Panen | ✅ DatePicker | ✅ TETAP | |
| 7 | Jumlah | ✅ Text input | ✅ TETAP | Angka + satuan |
| 8 | Satuan | ✅ Dropdown (kg/buah) | ✅ TETAP | |
| 9 | Kematangan | ✅ Dropdown | ✅ TETAP | Mentah, Setengah Matang, Matang, Matang Pohon |
| 10 | Masa Simpan | ✅ Dropdown | ✅ TETAP | 1 hari, 2-3 hari, 4-5 hari, Lebih dari 5 hari |
| 11 | Saran Penyimpanan | ✅ Text (opsional) | ⚠️ UBAH | Ganti jadi dropdown opsi umum + teks custom |
| 12 | Catatan | ✅ Text (opsional) | ✅ TETAP | Free text untuk info tambahan |
| 13 | Foto | ✅ Image picker | ✅ TETAP | Bukti visual |
| 14 | **Harga per Satuan** | ❌ Belum ada | 🆕 TAMBAH | Rp/kg atau Rp/buah — opsional, privat |
| 15 | **Jumlah Pohon** | ❌ Belum ada | 🆕 TAMBAH | Dari berapa pohon batch ini dipanen — opsional |

**Field yang TIDAK perlu ditambah:**
- ❌ Berat per buah — terlalu detail, sudah ada jumlah total
- ❌ Warna daging — ini data subjektif, sudah diwakili grade+varietas
- ❌ Sertifikasi organik — ini level kebun, bukan level batch

### 4.4 Saran Penyimpanan — Perbaikan

Saat ini field ini free-text, tapi sebenarnya jawabannya terbatas. Rekomendasi:

**Ganti jadi dropdown dengan opsi:**
- Simpan di tempat sejuk dan kering
- Hindari sinar matahari langsung
- Segera distribusikan (tidak tahan lama)
- Simpan di suhu ruang berventilasi
- Masukkan ke cold storage
- Lainnya (free text)

### 4.5 Fitur Petani — Evaluasi Final

| Fitur | Status | Perlu Diubah? |
|-------|--------|---------------|
| Beranda + Statistik | ✅ | TIDAK — sudah lengkap (total batch, pending, aktif, verified) |
| Search + Filter | ✅ | TIDAK — filter chip (Semua/Menunggu/Terverifikasi/Ditolak) sudah cukup |
| Tambah Batch | ✅ | YA — tambah field harga + jumlah pohon |
| Detail Batch | ✅ | TIDAK — info lengkap + timeline sudah baik |
| Edit Batch (15 min window) | ✅ | TIDAK — konsep edit window sudah benar untuk integritas data |
| QR Generate | ✅ | TIDAK — sudah generate + tampilkan |
| Kelola Kebun | ✅ | TIDAK — CRUD kebun sudah lengkap |
| Profil + Edit | ✅ | TIDAK — data diri lengkap |
| Drawer + Avatar | ✅ | TIDAK — navigasi sudah clean |
| Notifikasi batch ditolak | ❌ | YA — petani harus tahu kalau batch ditolak pengepul |
| Riwayat batch selesai | ✅ | TIDAK — sudah ada di filter "Semua" |

### 4.6 Yang Perlu Ditambah untuk Petani

| # | Fitur Baru | Prioritas | Detail |
|---|-----------|-----------|--------|
| 1 | **Field Harga** di Tambah Batch | 🟡 Tinggi | Input Rp/unit, opsional, privat |
| 2 | **Field Jumlah Pohon** di Tambah Batch | 🟢 Rendah | Opsional, info tambahan |
| 3 | **Notifikasi status batch** | 🟡 Tinggi | Petani tahu saat batch diverifikasi/ditolak |
| 4 | **Alasan penolakan** di Detail Batch | 🟡 Tinggi | Tampilkan kenapa pengepul tolak |
| 5 | **Dropdown Saran Penyimpanan** | 🟢 Rendah | Ganti free-text jadi dropdown + custom |

---

## 5. KESIMPULAN ROLE PETANI

> [!IMPORTANT]
> **Role Petani sudah 90% matang.** Yang perlu ditambah hanya:
> 1. Field harga (opsional) di form Tambah Batch
> 2. Notifikasi saat batch diverifikasi/ditolak
> 3. Tampilan alasan penolakan di Detail Batch
> 4. Minor: perbaikan dropdown saran penyimpanan
>
> **Tidak ada perubahan fundamental yang diperlukan.** Flow, field, dan arsitektur sudah benar.

Apakah Anda setuju dengan evaluasi ini? Setelah fix, kita lanjut ke **Role Pengepul** 🚀
