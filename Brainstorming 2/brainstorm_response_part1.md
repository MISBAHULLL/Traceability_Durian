# 🧠 Brainstorming Response — Part 1: Keputusan Strategis & Arsitektur

---

## 1. Pendekatan: Role-by-Role Synchronous ✅

Setuju 100%. Kita akan brainstorm **satu role sampai fix**, baru lanjut role berikutnya:

```
Petani → Pengepul → Distributor → UMKM → Konsumen → Admin
```

Setiap role akan kita bahas: **fitur, field, flow, QR, koneksi ke role berikutnya**.

---

## 2. Blueprint — Tidak Dijadikan Acuan

Dipahami. Mulai sekarang saya **tidak akan mengacu** ke folder `DurianTrace_AI_Development_Blueprint/`. Semua keputusan berdasarkan diskusi kita dan kode yang sudah ada.

---

## 3. Mock Data — Solusi untuk Fase FE

**Solusi: SharedPreferences + JSON serialization.**

Saat ini data hilang saat restart karena semua disimpan di variabel Dart biasa. Solusinya:

- Tambah `shared_preferences` atau `hive` (NoSQL ringan) sebagai local storage
- Setiap kali `notifyListeners()`, data otomatis di-persist ke local storage
- Saat app dibuka, data di-load dari local storage

**Ini tidak mengubah arsitektur sama sekali** — hanya menambah lapisan persist di bawah repository yang sudah ada. Kita bisa implementasi ini kapan saja tanpa refactor besar.

---

## 4. Singleton Pattern — Rekomendasi

**Masalah**: `FarmerRepository.instance` adalah singleton global. Artinya:
- Unit testing sulit (tidak bisa inject mock)
- Kalau ada 2 user login bersamaan (edge case), data bisa bocor

**Rekomendasi**: Untuk fase FE-only ini, **biarkan dulu**. Singleton bekerja fine untuk single-user app. Nanti saat integrasi backend, kita refactor ke dependency injection (misalnya pakai `Provider` atau `Riverpod`).

**Prioritas: RENDAH** — tidak perlu diubah sekarang.

---

## 5. State Management — ChangeNotifier

**Saat ini**: Pakai `ChangeNotifier` + `ListenableBuilder` manual.

**Sebab**: Ini cukup untuk skala kecil (2 role, 15 screen). 

**Akibat jika dibiarkan**: Saat semua 7 role diimplementasi (~40+ screen), kode akan jadi:
- Banyak `addListener`/`removeListener` manual yang rawan lupa dispose
- Sulit track dependency antar repository
- Rebuild UI tidak granular (seluruh screen rebuild walau hanya 1 field berubah)

**Rekomendasi**: Nanti setelah semua role fix, migrate ke **Riverpod** atau **Provider**. Untuk sekarang, **ChangeNotifier masih oke**. Jangan refactor prematur.

---

## 6. Duplikasi Kode — TopNotificationBanner

**Masalah**: `_TopNotificationBanner` di-copy paste di `home_screen.dart`, `register_role_screen.dart`, dan screen lain.

**Solusi**: Sudah ada `shared/widgets/top_notification_banner.dart`! Tapi beberapa screen masih pakai versi private (`_TopNotificationBanner`) internal. 

**Action**: Hapus semua `_TopNotificationBanner` private di tiap screen, ganti dengan import dari `shared/widgets/`. Ini saya bisa langsung kerjakan saat kita mulai implementasi.

---

## 7. Navigasi — Manual ke GoRouter

**Saat ini**: `Navigator.push()` manual + `FarmerRoutes`/`CollectorRoutes` helper.

**Masalah**:
- Tidak ada named routes → sulit deep-link dari QR scan
- Tiap feature buat route helper sendiri → tidak terpusat
- Back button behavior harus di-handle manual

**Rekomendasi**: Migrate ke **GoRouter**:
- Named routes terpusat di 1 file
- Deep-linking otomatis (penting untuk QR → trace screen)
- Guard/redirect untuk auth check
- Shell routes untuk bottom nav per role

**Kapan**: Setelah semua role fix, sebelum polish akhir. Atau bisa juga diimplementasi per-role saat kita kerjakan.

---

## 8. Error Boundary Global

**Action**: Ya, tambahkan. Implementasi:
```dart
// Di main.dart
FlutterError.onError = (details) {
  // Log error, tampilkan fallback UI
};
runZonedGuarded(() => runApp(...), (error, stack) {
  // Catch async errors
});
```
Ini saya bisa langsung tambahkan kapan saja.

---

## 9. File Structure — Apakah Sudah Clean?

**Jawaban: YA, sudah cukup clean** untuk skala sekarang. Feature-based structure (`features/farmer/`, `features/collector/`) adalah best practice Flutter.

**Yang perlu diperbaiki nanti saat scale up**:
1. Tambah folder `features/distributor/`, `features/umkm/`, `features/consumer/`, `features/admin/` — mengikuti pola yang sudah ada
2. Pindahkan `models/harvest_batch.dart` yang berisi `FarmerProfile` ke file terpisah `models/farmer_profile.dart` — satu file satu concern
3. Buat `shared/utils/` untuk helper functions yang dipakai lintas feature (misal formatter tanggal)

---

## 10. Grade — TIDAK Boleh Diubah ✅

**Setuju tegas**. Grade yang diinput petani **tidak boleh diubah** oleh siapapun di rantai pasok. Ini inti dari traceability — **data asli harus tetap utuh**.

Pengepul/distributor/UMKM **hanya bisa menambahkan catatan** (misal: "Kondisi saat diterima: Grade A sesuai"), bukan mengubah data asal.

**Implementasi**: Field `grade` di `HarvestBatch` sudah immutable (final). Yang perlu ditambah: setiap aktor punya field `notes` sendiri yang terpisah dari data batch asli petani.

---

## 11. Distributor vs Pengepul — Pembeda

Berdasarkan prototype dan logika rantai pasok durian:

| Aspek | Pengepul | Distributor |
|-------|----------|-------------|
| **Posisi** | Langsung dari petani | Setelah pengepul |
| **Aksi utama** | Verifikasi kualitas + sortir | Logistik pengiriman |
| **Data yang dicatat** | Grade verifikasi, jumlah diterima | Tujuan kirim, kondisi pengiriman, estimasi tiba |
| **Tanggung jawab** | Pastikan kualitas batch | Pastikan batch sampai tujuan utuh |
| **Analogi** | Quality Control | Shipping/Logistics |

**Kesimpulan: Perlu dipisah.** Pengepul fokus kualitas, Distributor fokus logistik. Ini juga sesuai prototype Anda.

---

## 12. Verifikasi & Penolakan Batch

**Apakah perlu fitur tolak? YA**, tapi sederhana:

**Flow penolakan**:
```
Petani buat batch (CREATED)
    → Pengepul cek → Terima (VERIFIED) atau Tolak (REJECTED)
    → Jika REJECTED: Batch ditandai "Ditolak" + alasan
    → Petani bisa lihat alasan penolakan di Detail Batch
    → Petani BUAT BATCH BARU (bukan re-submit batch lama)
```

**Kenapa buat baru, bukan re-submit?** Karena prinsip traceability: data lama tidak boleh diubah. Batch yang ditolak tetap tercatat di history sebagai bukti audit. Petani membuat batch baru dengan data yang sudah diperbaiki.

**Siapa yang bisa menolak?** Hanya **Pengepul** (aktor langsung setelah petani). Aktor lain (Distributor, UMKM) hanya bisa menolak di level mereka masing-masing — misalnya UMKM menolak kiriman dari distributor.

---

## 13. Produk Olahan — Rekomendasi Relasi

**Pilihan saya: Many-to-Many dengan pivot**

Realita di lapangan:
- 1 batch durian segar → bisa jadi **beberapa** produk olahan (dodol, pancake, selai)
- 1 produk olahan → bisa dari **beberapa** batch (UMKM campur batch untuk produksi besar)

**Implementasi yang saya rekomendasikan**:
```
HarvestBatch (1) ──→ (N) ProcessedProduct
    "DRN-2026-000128"     "PCK-2026-000001" (Pancake)
                          "DDL-2026-000001" (Dodol)
```

Setiap `ProcessedProduct` punya field `sourceBatchCodes: List<String>` yang merujuk ke batch asalnya. Konsumen scan QR produk olahan → bisa lihat batch sumber + petani asal.

**Untuk MVP, cukup relasi 1-to-Many dulu** (1 batch → banyak produk olahan). Many-to-many bisa ditambah belakangan.

---

## 14. QR Code — Siapa Generate, Siapa Scan?

| Role | Generate QR | Scan QR |
|------|------------|---------|
| **Petani** | ✅ Generate QR batch setelah buat batch | ❌ |
| **Pengepul** | ❌ | ✅ Scan QR batch untuk verifikasi |
| **Distributor** | ❌ | ✅ Scan QR batch untuk konfirmasi kirim/terima |
| **UMKM** | ✅ Generate QR produk olahan | ✅ Scan QR batch untuk konfirmasi terima bahan baku |
| **Konsumen** | ❌ | ✅ Scan QR batch/produk untuk lihat trace |
| **Admin** | ❌ | ✅ Scan QR untuk audit/monitoring |

**Ringkasan**: 
- **Generate**: Petani (batch segar) + UMKM (produk olahan)
- **Scan**: Semua role kecuali petani

---

## 15. Fitur Tambahan — Jawaban Tegas

### Harga Durian
**YA, tambahkan.** Tapi hanya sebagai **informasi opsional**, bukan fitur transaksi:
- Petani input harga per kg saat buat batch (opsional)
- Pengepul bisa lihat harga yang ditawarkan petani
- Ini relevan karena membantu transparansi rantai pasok

### Cuaca/Musim
**TIDAK perlu.** Ini di luar scope traceability. Menambah kompleksitas tanpa value langsung ke tujuan utama (track asal durian). Kalau mau, ini bisa jadi Phase 3+.

### Marketplace (Pesan Langsung)
**TIDAK untuk MVP.** Alasan:
- Mengubah nature app dari "traceability" menjadi "e-commerce"
- Perlu sistem pembayaran, escrow, chat — scope membengkak drastis
- Setiap role jadi harus punya fitur jual/beli, bukan hanya track
- **Rekomendasi**: Cukup tampilkan info kontak petani/pengepul di trace screen. Konsumen bisa kontak langsung di luar app.

### Analytics/Dashboard
**YA, tapi HANYA untuk Admin/Dinas.** Data yang ditampilkan:
- Total batch per wilayah
- Varietas terpopuler
- Jumlah aktor terdaftar per role
- Batch yang pending verifikasi
- Ini adalah fitur monitoring, bukan fitur user biasa.

---

> [!IMPORTANT]
> **Langkah Selanjutnya**: Mari kita deep-dive ke **Role Petani** secara detail — fitur, field, flow, dan validasi — di Part 2. Setelah petani benar-benar fix, baru kita lanjut ke Pengepul.

Silakan review dulu jawaban-jawaban di atas. Ada yang ingin dikoreksi sebelum kita masuk ke detail Petani?
