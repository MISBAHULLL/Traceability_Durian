# DurianTrace

Aplikasi mobile traceability rantai pasok durian berbasis QR Code dan blockchain
sederhana (hash-chain ledger).

DurianTrace mencatat perjalanan produk durian dari petani sampai konsumen.
Setiap batch atau produk olahan diberi identitas digital berupa kode unik dan
QR Code. Setiap perpindahan atau proses penting dicatat sebagai event
traceability. Hash-chain digunakan sebagai trust layer untuk membuktikan riwayat
produk tidak mudah dimanipulasi tanpa jejak.

## Aktor Utama

- Admin / Dinas / Peneliti
- Petani
- Pengelola / Koperasi / Pengepul
- Distributor
- UMKM
- Konsumen

## Stack

- Flutter (mobile)
- NestJS (backend, terpisah)
- PostgreSQL
- Hash-chain ledger (MVP), opsi upgrade ke smart contract atau permissioned
  blockchain

## Menjalankan Aplikasi

Jalankan dengan backend lokal:

```bash
flutter pub get
flutter run
```

Untuk mengarahkan aplikasi ke backend online, berikan URL API saat menjalankan
atau membangun aplikasi:

```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com/api
flutter build apk --dart-define=API_BASE_URL=https://api.example.com/api
```

`https://api.example.com/api` adalah URL contoh, bukan backend yang sudah
di-hosting. Ganti dengan URL server Laravel setelah backend dideploy. Tanpa
`API_BASE_URL`, aplikasi tetap menggunakan backend lokal sesuai platform.

Untuk preview multi-device saat development, aplikasi sudah dibungkus
`device_preview`.
