# 🔍 Analisis Mendalam: DurianTrace — Brainstorming Session

## 1. Pemahaman Project Saat Ini

### Apa Itu DurianTrace?
**DurianTrace** adalah aplikasi mobile (Flutter) untuk **traceability rantai pasok durian** di Jawa Timur. Sistem ini mencatat perjalanan durian dari **petani → pengepul → distributor → UMKM → konsumen**, dengan identitas digital (QR Code) dan trust layer (hash-chain/blockchain).

### Prototype UI Reference
![Prototype UI DurianTrace](d:\Jokian\Traceability_durian\assets\images\durian_prototype.png)

Dari prototype, terlihat 8 screen utama yang menjadi acuan visual:
1. **Splash/Welcome** — branding "System Traceability Durian Jawa Timur"
2. **Pendaftaran (Pilih Peran)** — 5 role: Petani, Pengepul, Distributor, UMKM, Konsumen
3. **Beranda Pengepul** — Tambah Transaksi, filter produk (Segar/Olahan/Bibit), kartu produk
4. **Tambah Transaksi** — Form pilih peran & kriteria (lokasi, varietas, pupuk, metode, grade, tanggal, jumlah)
5. **Detail Transaksi** — Profil petani, peta lokasi, info produk + CONFIRM
6. **Beranda Konsumen** — Search by kode, scan QR, menu produk olahan (Frozen, Pancake, Dodol, Selai)
7. **Hasil Penelusuran** — List aktor (petani, pengepul, UMKM, konsumen) dengan alamat
8. **Closing/Branding** — "Supported by" logo pemerintah

---

## 2. Status Implementasi Kode Saat Ini

### ✅ Yang Sudah Ada (Implementasi Nyata)

| Komponen | Status | Detail |
|----------|--------|--------|
| **Splash Screen** | ✅ Selesai | Animasi fade-in/scale/fade-out, transisi ke HomeScreen |
| **Login Screen** | ✅ Selesai | Email/Username + Password, validasi lengkap, cek koneksi |
| **Register: Pilih Peran** | ✅ Selesai | 5 role card (Petani, Pengepul, Distributor, UMKM, Konsumen) |
| **Register: Form** | ✅ Selesai | Form registrasi detail per role |
| **Beranda Petani** | ✅ Selesai | Greeting, statistik, filter chip, daftar batch, search |
| **Tambah Batch Panen** | ✅ Selesai | Form lengkap: lokasi, varietas, pupuk, metode, grade, tanggal, jumlah, foto, kematangan, masa simpan, catatan |
| **Detail Batch** | ✅ Selesai | Info lengkap, timeline event, edit window 15 menit |
| **QR Code Batch** | ✅ Selesai | Generate QR dari kode batch |
| **Manajemen Kebun** | ✅ Selesai | CRUD kebun petani (nama, lokasi, provinsi, kota, kecamatan, desa) |
| **Profil Petani** | ✅ Selesai | View + edit profil, upload avatar, logout |
| **Beranda Pengepul** | ✅ Selesai | Filter kategori (Segar/Olahan/Bibit), kartu produk, search, link ke verifikasi batch |
| **Profil Pengepul** | ✅ Selesai | View profil, avatar |
| **Tambah Transaksi Pengepul** | ✅ Selesai | Form verifikasi batch petani |
| **Public Trace Screen** | ✅ Selesai | Halaman trace publik dari QR: info durian, catatan kualitas, timeline perjalanan batch |
| **Theme/Design System** | ✅ Selesai | AppColors, AppTheme, konsisten hijau brand |
| **Shared Widgets** | ✅ Selesai | AppTopBar, BatchPhoto, LabeledDropdownField, PrimaryPillButton, TopNotificationBanner |

### State Machine Batch (Sudah Terimplementasi)
```
DRAFT → CREATED → VERIFIED_BY_COLLECTOR → IN_DISTRIBUTION → 
RECEIVED_BY_UMKM → PROCESSED → SOLD
                                   ↘ REJECTED
```

### Data Model (Sudah Terimplementasi)
- **HarvestBatch** — unit utama tracking (kode, petani, kebun, varietas, grade, jumlah, status, metadata kualitas)
- **Farm** — kebun durian (lokasi detail sampai desa)
- **FarmerProfile** — profil petani (nama, kontak, email, alamat, avatar)
- **CollectorProduct** — view read-only batch petani untuk pengepul
- **CollectorProfile** — profil pengepul
- **BatchEvent** — timeline event per batch
- **MasterData** — varietas, pupuk, metode panen, grade, satuan, kematangan, masa simpan

---

## 3. Yang BELUM Ada / Gap Analysis

### 🔴 Fitur Belum Diimplementasi

| Fitur | Prioritas | Catatan |
|-------|-----------|---------|
| **Backend (NestJS + PostgreSQL)** | 🔴 Kritis | Semua data masih mock/in-memory. Tidak ada persistence |
| **Autentikasi Nyata** | 🔴 Kritis | Login hanya validasi form, belum API call |
| **Role Distributor** | 🟡 Tinggi | Ada di registrasi tapi belum ada screen/flow |
| **Role UMKM** | 🟡 Tinggi | Ada di registrasi tapi belum ada screen/flow |
| **Role Konsumen (dedicated)** | 🟡 Tinggi | Hanya ada public trace, belum ada beranda/flow khusus konsumen |
| **Role Admin/Dinas** | 🟡 Tinggi | Belum ada dashboard admin |
| **Scan QR Code** | 🟡 Tinggi | QR hanya generate, belum ada scanner |
| **Hash-chain/Blockchain** | 🟡 Tinggi | Belum ada trust layer apapun |
| **Produk Olahan UMKM** | 🟡 Medium | Batch → produk olahan (pancake, dodol, selai, frozen) belum ada |
| **Peta/Maps Integrasi** | 🟡 Medium | Farm punya lat/long tapi belum ada map widget |
| **Notifikasi** | 🟢 Low | Belum ada push notification antar aktor |
| **Offline Mode** | 🟢 Low | Belum ada local storage/cache |
| **Multi-Language** | 🟢 Low | Sudah setup intl tapi belum digunakan penuh |
| **Laporan/Export** | 🟢 Low | Belum ada fitur export data |

---

## 4. Poin Penting dari Arsitektur Saat Ini

### Kekuatan ✅
1. **Arsitektur bersih** — separation of concerns: `models/`, `data/`, `screens/`, `widgets/`
2. **Repository pattern** — singleton `ChangeNotifier` sebagai single source of truth
3. **State machine jelas** — BatchStatus enum dengan extension method lengkap
4. **Data isolation** — semua getter dibatasi `currentFarmerId` (Req 7.2)
5. **Validasi komprehensif** — `FarmerValidator` sebagai pure function terpisah
6. **Edit guard** — jendela koreksi 15 menit setelah batch dibuat
7. **Interkoneksi antar role** — CollectorRepository listen ke FarmerRepository
8. **UI polish tinggi** — animasi konsisten, notification banner, transisi halus
9. **Cross-role data flow** — batch petani otomatis muncul sebagai produk pengepul

### Kelemahan / Risiko ⚠️
1. **100% Mock Data** — semua data hilang saat app di-restart
2. **Singleton pattern** — sulit untuk testing dan multiple session
3. **Tidak ada error boundary global** — crash handler belum ada
4. **Belum ada state management library** — murni ChangeNotifier, bisa kompleks
5. **Duplikasi kode** — `_TopNotificationBanner` diduplikasi di beberapa screen
6. **Navigasi manual** — belum pakai named routes / GoRouter

---

## 5. Pertanyaan Brainstorming untuk Didiskusikan

### 🎯 Arah Produk
1. **Scope MVP** — Apakah target MVP hanya Petani + Pengepul, atau semua 6 role harus ada?
2. **Backend priority** — Mau build backend (NestJS) dulu, atau polish FE semua role dulu?
3. **Hash-chain vs Blockchain** — Blueprint punya 3 opsi (hash-chain, permissioned, smart contract). Mau mulai dari mana?

### 👥 Alur Bisnis per Aktor
4. **Petani** → Alur sudah matang. Ada yang perlu ditambah?
5. **Pengepul** → Setelah verifikasi, apa aksi berikutnya? Bagaimana distribusi ke UMKM?
6. **Distributor** → Apa bedanya dengan pengepul? Apakah perlu role terpisah?
7. **UMKM** → Bagaimana alur terima batch → proses olahan → generate QR produk olahan?
8. **Konsumen** → Selain scan QR, fitur apa lagi yang berguna? Rating? Feedback?
9. **Admin/Dinas** → Dashboard monitoring apa saja yang dibutuhkan?

### 🔄 Alur Bisnis Kritis
10. **Verifikasi bertingkat** — Siapa yang boleh menolak batch? Hanya pengepul atau semua aktor?
11. **Produk olahan** — Satu batch bisa jadi berapa produk olahan? Relasi 1-to-many?
12. **Re-tracking** — Kalau batch ditolak, petani bisa re-submit atau buat batch baru?
13. **Grade revision** — Pengepul bisa mengubah grade petani? Atau hanya verifikasi?

### 💡 Fitur Tambahan Potensial
14. **Harga durian** — Apakah perlu tracking harga per batch/kg?
15. **Cuaca/musim** — Integrasi data cuaca ke kualitas panen?
16. **Sertifikasi** — Apakah petani/kebun bisa mendapat sertifikasi organik dll?
17. **Marketplace** — Apakah konsumen bisa pesan langsung dari app?
18. **Analytics** — Dashboard data: tren panen, varietas populer, distribusi per wilayah?

---

## 6. Ringkasan File Structure

```
lib/
├── main.dart                              # Entry point + MaterialApp
├── core/
│   └── theme/
│       ├── app_colors.dart                # 8 color tokens (hijau brand)
│       └── app_theme.dart                 # Material3 ThemeData
├── features/
│   ├── auth/
│   │   └── screens/
│   │       ├── splash_screen.dart         # Animated splash (2.8s)
│   │       ├── home_screen.dart           # Login screen
│   │       ├── register_role_screen.dart  # Pilih 5 role
│   │       └── register_form_screen.dart  # Form registrasi
│   ├── farmer/
│   │   ├── farmer_routes.dart             # Navigasi helper (fade)
│   │   ├── models/
│   │   │   ├── harvest_batch.dart         # HarvestBatch + BatchStatus + FarmerProfile
│   │   │   ├── farm.dart                  # Farm (kebun durian)
│   │   │   ├── batch_event.dart           # BatchEvent (timeline)
│   │   │   └── master_data.dart           # Dropdown options
│   │   ├── data/
│   │   │   ├── farmer_repository.dart     # SSoT: CRUD + validasi + statistik
│   │   │   └── farmer_mock_data.dart      # (deprecated, migrated to repo)
│   │   ├── screens/
│   │   │   ├── farmer_home_screen.dart    # Beranda petani
│   │   │   ├── add_batch_screen.dart      # Form tambah batch panen
│   │   │   ├── batch_detail_screen.dart   # Detail + timeline
│   │   │   ├── batch_qr_screen.dart       # QR Code display
│   │   │   ├── farmer_profile_screen.dart # Profil petani
│   │   │   ├── edit_profile_screen.dart   # Edit profil
│   │   │   ├── farm_management_screen.dart# Kelola kebun
│   │   │   ├── create_farm_screen.dart    # Form buat kebun
│   │   │   ├── about_screen.dart          # Tentang app
│   │   │   └── help_screen.dart           # Bantuan
│   │   └── widgets/
│   │       ├── farmer_avatar.dart         # Avatar foto/inisial
│   │       └── farmer_drawer.dart         # Side drawer
│   ├── collector/
│   │   ├── collector_routes.dart          # Navigasi helper
│   │   ├── models/
│   │   │   └── collector_product.dart     # CollectorProduct + CollectorProfile
│   │   ├── data/
│   │   │   └── collector_repository.dart  # SSoT + verifikasi batch
│   │   ├── screens/
│   │   │   ├── collector_home_screen.dart # Beranda pengepul
│   │   │   ├── add_transaction_screen.dart# Form verifikasi/transaksi
│   │   │   └── collector_profile_screen.dart
│   │   └── widgets/
│   │       ├── collector_avatar.dart
│   │       └── collector_drawer.dart
│   └── trace/
│       └── screens/
│           └── public_trace_screen.dart   # Trace publik dari QR
└── shared/
    └── widgets/
        ├── app_top_bar.dart               # Reusable top bar
        ├── batch_photo.dart               # Image display widget
        ├── labeled_dropdown_field.dart     # Custom dropdown
        ├── primary_pill_button.dart        # Pill-shaped button
        └── top_notification_banner.dart    # Toast/snackbar overlay
```

---

> [!IMPORTANT]
> **Catatan tentang Blueprint**: Folder `DurianTrace_AI_Development_Blueprint/` berisi 22 dokumen perencanaan (PRD, tech spec, database schema, API contract, blockchain options, dll). Seperti yang Anda minta, saya **tidak terpaku** pada blueprint tersebut karena bisa bias. Saya menganalisis langsung dari **kode yang sudah berjalan** untuk memahami realita project.

---

**Siap untuk brainstorming!** 🚀  
Silakan mulai dari aspek mana yang ingin didiskusikan terlebih dahulu.
