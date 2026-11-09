# Device Tree Blobs (DTB) untuk TV Box Amlogic

Direktori ini menyediakan berkas Device Tree Blob biner (`.dtb`) dan berkas sumber (`.dts`) yang telah dikompilasi serta teruji secara fisik untuk mengatasi *hardware quirks* pada TV Box berbasis Amlogic yang menjalankan Linux / Armbian.

---

## 1. ZTE ZXV10 B860H V5 (`meson-g12a-b860h-v5.dtb`)

### Akar Masalah
Pada ZTE ZXV10 B860H V5 (Amlogic S905X2 / Meson G12A), jalur listrik modul nirkabel MediaTek MT7668 (`VDDAO_3V3` dan `VDDAO_1V8`) bertipe **Always-On** fisik (tegangan tetap mengalir saat software reboot).
Pada DTB bawaan Armbian, kontroler SDIO mencoba menegosiasikan penurunan voltase pensinyalan ke 1.8V UHS (`sd-uhs-sdr104`). Begitu MT7668 beralih ke 1.8V, saat STB di-reboot secara software (`reboot`), prosesor Amlogic menyala pada default 3.3V sementara chip masih terkunci di 1.8V. Hal ini memicu deadlock:
```text
meson-gx-mmc ffe03000.mmc: no support for card's volts
mmc2: error -22 whilst initialising SDIO card
```
sehingga antarmuka Wi-Fi (`wlan0`) selalu hilang setiap kali di-reboot, kecuali adaptor listrik dicabut-colok (Cold Boot).

### Solusi Permanen
Menambahkan properti resmi kernel `no-1-8-v;` pada node kontroler SDIO (`mmc@ffe03000`) menginstruksikan MMC core untuk strictly bertahan pada pensinyalan **3.3V High-Speed (50 MHz)**. Karena chip tidak pernah beralih ke 1.8V:
- Tidak ada mismatch voltase saat software reboot.
- Wi-Fi bertahan hidup dan stabil 100% setelah perintah `reboot`.
- Bandwidth bus SDIO tetap stabil hingga 200 Mbps (25 MB/s).

### Petunjuk Pemasangan (Armbian)
1. Cadangkan DTB lama Anda:
   ```bash
   sudo cp /boot/dtb/amlogic/meson-g12a-b860h-v5.dtb /boot/dtb/amlogic/meson-g12a-b860h-v5.dtb.bak
   ```
2. Salin DTB yang telah diperbaiki:
   ```bash
   sudo cp dtb/amlogic/meson-g12a-b860h-v5.dtb /boot/dtb/amlogic/meson-g12a-b860h-v5.dtb
   sudo sync
   ```
3. Lakukan **1 kali Cold Boot** (cabut kabel adaptor daya selama 10 detik lalu colokkan kembali) untuk membersihkan sisa penguncian voltase lama.
4. Mulai sekarang, reboot software biasa (`sudo reboot`) akan mempertahankan koneksi Wi-Fi secara otomatis dan stabil!
