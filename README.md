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

## Dokumentasi Lengkap

Lihat folder `DurianTrace_AI_Development_Blueprint/`:

- `01_PROJECT_OVERVIEW.md`
- `02_PRD_MASTER.md`
- `03_TECHNICAL_SPEC.md`
- `04_DATABASE_SCHEMA.md`
- `13_IMPLEMENTATION_TASKS.md`
- dan lainnya.

## Menjalankan Aplikasi

```bash
flutter pub get
flutter run
```

Untuk preview multi-device saat development, aplikasi sudah dibungkus
`device_preview`.
