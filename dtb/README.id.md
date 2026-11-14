# Device Tree Blobs (DTB) untuk TV Box Amlogic

Direktori ini menyediakan berkas Device Tree Blob biner (`.dtb`) dan berkas sumber (`.dts`) yang telah dikompilasi serta teruji secara fisik untuk mengatasi *hardware quirks* pada TV Box berbasis Amlogic yang menjalankan Linux / Armbian.

---

## 1. Varian DTB ZTE ZXV10 B860H V5

| Varian DTB | Target Kernel / Lingkungan | Patch SDIO Wi-Fi & Unbind Script | TrustZone Memory Shield (48 MB) | Kasus Penggunaan yang Direkomendasikan |
| :--- | :--- | :---: | :---: | :--- |
| **`meson-g12a-b860h-v5.dtb`** | Linux 6.x (Boot MicroSD / USB) | Ya (`no-1-8-v` + SDR104) | 32 MB (Standar) | Booting standar Armbian dari media eksternal (MicroSD atau USB flashdisk). Menyelesaikan bug Wi-Fi hilang saat warm reboot bersama helper script unbind. |
| **`meson-g12a-b860h-v5-v1.dtb`** | Linux 6.12+ (Internal eMMC / Direct Boot) | Ya (`no-1-8-v` + SDR104 100 MHz) | **48 MB (`no-map`)** | **Sangat direkomendasikan untuk instalasi internal eMMC & Linux 6.12+.** Mempertahankan performa SDR104 100 MHz serta mencegah tabrakan memori TrustZone (`Synchronous External Abort 0x96000010` / `SError 0xbf000000`). |

---

## 2. Analisis Hardware & Solusi Teknis

### A. Mismatch Voltase SDIO Wi-Fi Saat Warm Reboot (Tersedia di Seluruh Varian)
Pada ZTE ZXV10 B860H V5 (Amlogic S905X2 / Meson G12A), jalur listrik modul nirkabel MediaTek MT7668 (`VDDAO_3V3` dan `VDDAO_1V8`) bertipe **Always-On** fisik (tegangan tetap mengalir saat software reboot).
Pada DTB bawaan Armbian, kontroler SDIO mencoba menegosiasikan penurunan voltase pensinyalan ke 1.8V UHS (`sd-uhs-sdr104`). Begitu MT7668 beralih ke 1.8V, saat STB di-reboot secara software (`reboot`), prosesor Amlogic menyala pada default 3.3V sementara chip masih terkunci di 1.8V. Hal ini memicu deadlock:
```text
meson-gx-mmc ffe03000.mmc: no support for card's volts
mmc2: error -22 whilst initialising SDIO card
```
sehingga antarmuka Wi-Fi (`wlan0`) selalu hilang setiap kali di-reboot, kecuali adaptor listrik dicabut-colok (Cold Boot).

Menambahkan properti resmi kernel `no-1-8-v;` pada node kontroler SDIO (`mmc@ffe03000`) menginstruksikan MMC core untuk strictly bertahan pada pensinyalan **3.3V High-Speed (50 MHz)**:
- Tidak ada mismatch voltase saat software reboot.
- Wi-Fi bertahan hidup dan stabil 100% setelah perintah `reboot`.
- Bandwidth bus SDIO tetap stabil hingga 200 Mbps (25 MB/s).

### B. Tabrakan Memori TrustZone pada Booting Internal eMMC (Hanya pada `meson-g12a-b860h-v5-v1.dtb`)
Firmware bawaan ZTE mengunci memori DRM TrustZone (`tee.img`) hingga batas fisik `0x08000000` (128 MB). DTB bawaan hanya mendeklarasikan 32 MB (`secmon@5300000` hingga `0x072FFFFF` / 115 MB). Akibatnya, kernel Linux 6.12+ mengalokasikan initramfs atau slab object di RAM fisik `0x075ee000` - `0x07677000`, memicu proteksi hardware bus AXI Amlogic:
```text
Internal error: synchronous external abort: 0000000096000010 [#1] SMP
Kernel panic - not syncing: Asynchronous SError Interrupt
```
Memperluas kavling `secmon@5300000` menjadi **48 MB (`0x03000000`)** berstatus `no-map` mengunci memori fisik dari `0x05300000` s.d. `0x08300000`, menjamin booting dari internal eMMC berjalan 100% mulus tanpa kernel panic.

---

## 3. Petunjuk Pemasangan (Armbian)

### Untuk Booting MicroSD / USB:
```bash
# Cadangkan DTB lama
sudo cp /boot/dtb/amlogic/meson-g12a-b860h-v5.dtb /boot/dtb/amlogic/meson-g12a-b860h-v5.dtb.bak

# Salin DTB Standar
sudo cp dtb/amlogic/meson-g12a-b860h-v5.dtb /boot/dtb/amlogic/meson-g12a-b860h-v5.dtb
sudo sync
```

### Untuk Booting Internal eMMC (atau Linux 6.12+):
```bash
# Salin DTB Varian V1 dengan TrustZone Memory Shield
sudo cp dtb/amlogic/meson-g12a-b860h-v5-v1.dtb /boot/dtb/amlogic/meson-g12a-b860h-v5.dtb
sudo sync
```

Lakukan **1 kali Cold Boot** (cabut kabel adaptor daya selama 10 detik lalu colokkan kembali) untuk membersihkan sisa penguncian voltase lama. Mulai sekarang, reboot software biasa (`sudo reboot`) akan mempertahankan koneksi Wi-Fi secara otomatis dan stabil!
