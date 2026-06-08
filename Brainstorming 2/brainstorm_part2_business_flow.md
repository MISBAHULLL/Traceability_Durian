# 🧠 Brainstorming Part 2 — Alur Bisnis Aplikasi & Pertanyaan Kritis

---

## 1. PERTANYAAN UTAMA: Bagaimana Alur Antar Role?

Ini pertanyaan paling penting. Ada **3 kemungkinan model**:

### Model A: "Papan Iklan" (Marketplace-like)
```
Petani upload batch → Muncul di "etalase" → Pengepul browse & pilih → Klaim batch
```
- Petani tidak tahu siapa pengepulnya sampai ada yang klaim
- Pengepul browsing seperti belanja online
- **Masalah**: Ini bukan traceability, ini e-commerce

### Model B: "Hubungan Langsung" (Pre-arranged)
```
Petani sudah kenal pengepul → Petani assign batch ke pengepul tertentu → Pengepul verifikasi
```
- Petani pilih pengepul dari daftar saat buat batch
- Hanya pengepul yang ditunjuk yang bisa lihat batch tersebut
- **Masalah**: Petani harus tahu siapa pengepulnya di app, ribet untuk petani

### Model C: "Pencatatan Rantai Pasok" ⭐ **REKOMENDASI SAYA**
```
Petani catat batch di app → Durian SUDAH dikirim/dijual fisik di dunia nyata →
Pengepul buka app → Scan QR / cari kode batch → Verifikasi penerimaan
```

**Ini yang paling cocok. Alasannya:**

> [!IMPORTANT]
> DurianTrace **bukan marketplace**. App ini **MENCATAT** apa yang sudah terjadi di dunia nyata, bukan **MEMFASILITASI** transaksi.

Di dunia nyata, petani dan pengepul **sudah saling kenal**. Mereka bertransaksi lewat telepon, datang langsung ke kebun, atau lewat koperasi. **App ini hanya mencatat jejak digital** dari transaksi yang sudah terjadi.

---

## 2. ALUR LENGKAP APLIKASI (Model C)

Berikut alur end-to-end yang saya rekomendasikan:

### Step 1: PETANI — Catat Panen
```
Petani panen durian di kebun
    ↓
Buka app → "Tambah Batch Panen"
    ↓
Isi: kebun, varietas, jumlah, grade, tanggal panen, foto, dll
    ↓
App generate KODE BATCH unik (DRN-2026-000128) + QR Code
    ↓
Petani TEMPEL QR di karung/boks durian fisik
    ↓
Status batch: CREATED (Menunggu Verifikasi)
```

**Di dunia nyata**: Petani sudah janjian dengan pengepul langganannya. Pengepul datang ke kebun atau petani antar durian ke pengepul.

### Step 2: PENGEPUL — Verifikasi Penerimaan
```
Pengepul TERIMA durian fisik dari petani
    ↓
Buka app → Scan QR di karung/boks ATAU cari kode batch
    ↓
App tampilkan detail batch dari petani
    ↓
Pengepul cek: jumlah cocok? kualitas cocok?
    ↓
Pilih: ✅ TERIMA (Verified) atau ❌ TOLAK (Rejected + alasan)
    ↓
Status batch: VERIFIED_BY_COLLECTOR
```

**Pengepul TIDAK browsing petani.** Pengepul scan QR dari barang yang sudah diterima fisik.

### Step 3: DISTRIBUTOR — Catat Pengiriman
```
Pengepul serahkan durian ke distributor/jasa kirim
    ↓
Distributor buka app → Scan QR batch
    ↓
Isi: tujuan kirim, estimasi sampai, kondisi pengiriman
    ↓
Konfirmasi: "Batch sedang dikirim"
    ↓
Status batch: IN_DISTRIBUTION
```

### Step 4: UMKM — Terima & Olah
```
UMKM terima durian dari distributor
    ↓
Buka app → Scan QR batch → Konfirmasi penerimaan
    ↓
Status batch: RECEIVED_BY_UMKM
    ↓
UMKM proses durian → buat Pancake/Dodol/Selai
    ↓
Buka app → "Buat Produk Olahan"
    ↓
Isi: nama produk, jenis olahan, batch sumber
    ↓
App generate KODE PRODUK (PCK-2026-000001) + QR Code baru
    ↓
UMKM tempel QR di kemasan produk olahan
```

### Step 5: KONSUMEN — Telusuri Asal
```
Konsumen beli durian/produk olahan di pasar/toko
    ↓
Lihat ada QR Code di kemasan
    ↓
Buka app → Scan QR
    ↓
App tampilkan: asal petani, kebun, tanggal panen, grade,
perjalanan batch (siapa verifikasi, siapa kirim, siapa olah)
    ↓
Konsumen TAHU asal-usul durian yang dibeli
```

### Step 6: ADMIN — Monitoring
```
Admin buka dashboard
    ↓
Lihat: semua batch, semua aktor, statistik wilayah,
batch pending, batch bermasalah
```

---

## 3. DIAGRAM ALUR

```
┌─────────┐     QR tempel      ┌──────────┐     QR scan       ┌─────────────┐
│  PETANI  │ ──── di boks ────→ │ PENGEPUL │ ──── kirim ────→ │ DISTRIBUTOR │
│ (Catat)  │    fisik durian    │(Verifikasi)│   via jasa      │  (Logistik)  │
└─────────┘                     └──────────┘                   └─────────────┘
                                                                      │
                                                                QR scan │
                                                                      ↓
┌──────────┐     QR scan       ┌──────┐       QR scan          ┌──────────┐
│ KONSUMEN │ ←── di kemasan ── │ UMKM │ ←── terima boks ────── │          │
│ (Telusur)│    produk olahan  │(Olah)│                        └──────────┘
└──────────┘                   └──────┘
```

**Benang merah: QR Code adalah PENGHUBUNG antar role.** Setiap perpindahan fisik durian dicatat digital lewat scan QR.

---

## 4. HARGA — Rekomendasi Detail

### Masalah yang Anda Angkat (Valid!)
Jika semua harga transparan antar role:
- Petani jual Rp 50.000/kg → Pengepul jual Rp 70.000/kg → Distributor tahu margin pengepul
- Ini bisa menimbulkan konflik bisnis

### Solusi: **Harga PRIVAT per Role**

| Role | Bisa Input Harga | Bisa Lihat Harga Siapa |
|------|-------------------|----------------------|
| Petani | ✅ Harga jual ke pengepul | Hanya harga sendiri |
| Pengepul | ✅ Harga jual ke distributor | Hanya harga sendiri |
| Distributor | ✅ Harga jual ke UMKM | Hanya harga sendiri |
| UMKM | ✅ Harga jual ke konsumen | Hanya harga sendiri |
| Konsumen | ❌ | Hanya harga beli (dari UMKM/retailer) |
| **Admin** | ❌ | ✅ **Semua harga semua role** (untuk monitoring) |

**Setiap role hanya tahu harga yang mereka bayar dan harga yang mereka jual.** Tidak ada role yang bisa lihat margin role lain. **Hanya Admin** yang punya visibility penuh untuk monitoring dan regulasi.

### Field Harga di Petani
**Cukup 1 field**: `hargaPerUnit` (Rp/kg atau Rp/buah, tergantung satuan yang dipilih).

Tidak perlu harga per grade/varietas terpisah karena:
- Petani sudah pilih grade dan varietas di batch
- Harga per batch sudah spesifik ke grade+varietas itu
- Contoh: Batch Montong Grade A → Rp 80.000/kg. Selesai.

---

## 5. NOTIFICATION BANNER — Pop-up vs Banner

**Saat ini**: Banner yang slide dari atas (mirip iOS notification).

**Rekomendasi saya: Tetap banner, BUKAN popup.**

Alasan:
- **Pop-up (dialog)** memaksa user klik "OK" → mengganggu flow, apalagi untuk notifikasi sukses
- **Banner** tampil sebentar → auto-hilang → tidak mengganggu
- Untuk **error kritis** (misal gagal simpan), baru pakai dialog konfirmasi

**Yang perlu diperbaiki dari banner saat ini:**
1. Pindahkan ke `shared/widgets/` (sudah ada, tinggal konsistenkan penggunaan)
2. Tambah variasi: `success`, `error`, `warning`, `info`
3. Posisi selalu di atas (konsisten)

---

## 6. RINGKASAN KEPUTUSAN BARU

| Keputusan | Jawaban |
|-----------|---------|
| Model alur | **Pencatatan rantai pasok** — app mencatat, bukan memfasilitasi transaksi |
| Koneksi antar role | **Via QR Code** — scan saat perpindahan fisik |
| Pengepul cari petani? | **TIDAK** — pengepul scan QR dari barang yang sudah diterima |
| Harga | **Privat per role**, hanya admin lihat semua |
| Field harga petani | **1 field**: harga per unit (Rp/kg atau Rp/buah) |
| Notification | **Tetap banner** (bukan popup), pindah ke shared widget |
| Mock data persistence | **Implementasi** SharedPreferences/Hive |
| GoRouter | **Implementasi** |
| Error boundary | **Implementasi** |
| File structure cleanup | **Implementasi** |

---

> [!IMPORTANT]
> **Langkah Selanjutnya**: Sekarang alur besar sudah jelas, mari kita deep-dive ke **Role Petani** secara detail:
> - Fitur-fitur petani apa saja yang final?
> - Field "Tambah Batch" apakah sudah lengkap?
> - Apakah tracking per batch atau per buah?
> - Apa yang perlu ditambah/hapus/perbaiki?
>
> Apakah Anda sudah clear dengan alur di atas dan siap masuk ke detail Petani?
