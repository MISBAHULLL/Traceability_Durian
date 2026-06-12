# Data Wilayah Indonesia

Sumber data:

- https://github.com/cahyadsn/wilayah
- `cahyadsn_wilayah.sql` untuk hierarki provinsi sampai desa/kelurahan.
- `cahyadsn_wilayah_level_1_2.sql` untuk koordinat provinsi dan kabupaten/kota.

`cahyadsn_wilayah_map.txt` adalah hasil ekstraksi koordinat yang dipakai aplikasi
agar tidak memuat SQL peta berukuran besar saat form dibuka. Regenerasi file:

```powershell
.\tool\generate_wilayah_assets.ps1
```

Data sumber tersedia dengan lisensi MIT dari pemilik repository.
