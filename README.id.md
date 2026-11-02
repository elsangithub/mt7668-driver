# Driver Linux DKMS MediaTek MT7668 SDIO Wi-Fi (v2.0.0)

[![Release](https://img.shields.io/badge/release-v2.0.0-blue.svg)](https://github.com/elsangithub/mt7668-driver/releases)
[![DKMS](https://img.shields.io/badge/DKMS-aktif-brightgreen.svg)](https://github.com/elsangithub/mt7668-driver)
[![Kernel](https://img.shields.io/badge/kernel-6.1--6.18+-orange.svg)](https://github.com/elsangithub/mt7668-driver)
[![Hardware](https://img.shields.io/badge/perangkat-FiberHome%20HG680--FJ%20(S905X2)-purple.svg)](https://github.com/elsangithub/mt7668-driver)
[![Lisensi](https://img.shields.io/badge/lisensi-Dual%20BSD%2FGPL-green.svg)](LICENSE)
[![English Guide](https://img.shields.io/badge/read-English-blue.svg)](README.md)

Driver kernel Linux out-of-tree berbasis DKMS siap pakai untuk modul Wi-Fi combo **MediaTek MT7668** (SDIO `037a:7608` / `037a:6602`) 802.11ac 2x2. Dirancang khusus untuk kernel Linux ARM64 modern (Linux 6.1 LTS, 6.6 LTS, 6.12 LTS, hingga 6.18+) pada STB Android TV Amlogic (seperti **FiberHome HG680-FJ**, Amlogic S905X2 / Meson G12A), Debian 12 Bookworm, dan Ubuntu 24.04 Noble.

---

## 🌟 Apa yang Baru di Versi 2.0.0 (Rilis Major Elsangithub)

Versi **2.0.0** membawa driver MT7668 ke standar keandalan dan kelengkapan fitur yang setara dengan ekosistem driver **`mt7663-driver`**:

1. **📡 Dukungan Dedicated Mode SoftAP / Hotspot (`ap_mode` & `ap0`)**:
   Menghadirkan parameter kernel modular `ap_mode`. Driver kini dapat secara dinamis mengaktifkan interface virtual khusus (**`ap0`**) berdampingan dengan `wlan0` saat proses probe, memungkinkan STB FiberHome HG680-FJ difungsikan sebagai Router Hotspot Wi-Fi 5 GHz berkecepatan tinggi atau Repeater Wi-Fi. Kompatibel penuh dengan `hostapd` dan dashboard router seperti [`mt7663-router-webui`](https://github.com/elsangithub/mt7663-router-webui).
2. **🐧 Kompatibilitas Kernel Linux Modern (Linux 6.8+)**:
   Menyelaraskan API `cfg80211` modern (`cfg80211_cac_event`, `cfg80211_ch_switch_notify`, dan isolasi livepatch symbol) sehingga kompilasi DKMS berjalan mulus tanpa error modpost.
3. **📦 Sistem Paket Debian DKMS Standar (`debian/`)**:
   Struktur paket Debian terstandarisasi dengan mekanisme *self-healing* otomatis, deteksi header kernel cerdas, dan proses upgrade bebas konflik.

---

## 📡 Mode Hotspot / SoftAP & Parameter Modular `ap_mode`

Driver dilengkapi dengan parameter modul `ap_mode` yang dapat dikonfigurasi melalui berkas `/etc/modprobe.d/mt7668.conf`:

| Nilai | Deskripsi Mode | Skenario Penggunaan |
| :---: | :--- | :--- |
| **`ap_mode=0`** *(Bawaan)* | **Mode Klien Murni (STA)** (`wlan0` saja) | Penggunaan standar desktop, server, atau TV box klien. Sangat ringan tanpa overhead. |
| **`ap_mode=1`** | **Dedicated AP Mode** (`ap0` + `wlan0`) | Hotspot router, repeater Wi-Fi, atau dipasangkan dengan `mt7663-router-webui` / `hostapd`. |
| **`ap_mode=2`** | **Dual AP Mode** | Menjalankan dua interface AP virtual sekaligus. |
| **`ap_mode=3`** | **Mode Konkuren P2P + AP** | Wi-Fi Direct berjalan bersamaan dengan access point. |

### Cara Mengaktifkan Mode AP (`ap0`):
Jalankan perintah berikut agar interface `ap0` otomatis aktif saat boot:
```bash
echo "options wlan_mt7668 ap_mode=1" | sudo tee /etc/modprobe.d/mt7668.conf
sudo modprobe -r wlan_mt7668 2>/dev/null || true
sudo modprobe wlan_mt7668
ip link show
```

Untuk mengembalikan ke mode klien standar (`wlan0` saja):
```bash
echo "options wlan_mt7668 ap_mode=0" | sudo tee /etc/modprobe.d/mt7668.conf
sudo modprobe -r wlan_mt7668 2>/dev/null || true
sudo modprobe wlan_mt7668
```

---

## 🚀 Performa Teruji (FiberHome HG680-FJ)

Diuji langsung pada perangkat **FiberHome HG680-FJ (Amlogic S905X2 / Meson G12A)** menjalankan **Armbian (Ubuntu 24.04 Noble / Debian 12 Bookworm)** kernel `Linux 6.12.x-ophub` dan `6.18.x-ophub`:

- **Dmesg Bersih**: Nol spam log `[wlan]` (`DBG_DISABLE_ALL_LOG 1`).
- **Kestabilan Daya**: Penonaktifan sleep otomatis (`CFG_ENABLE_FULL_PM 0`) untuk menjaga sinkronisasi clock SDIO.
- **Dukungan DKMS**: Modul otomatis dikompilasi ulang secara otomatis saat update kernel.
- **Kecepatan Terverifikasi (iperf3 ke server lokal)**:
  - **Band 5 GHz (Kanal 157, link rate 405–780 Mbps)**:
    - **Upload (TX)**: **94.2 Mbps** (0 retransmit)
    - **Download (RX)**: **50.2 Mbps**
  - **Band 2.4 GHz (Kanal 6)**:
    - **Upload (TX)**: **81.2 Mbps** (0 retransmit)
    - **Download (RX)**: **26.9 Mbps**

```text
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec   112 MBytes  94.2 Mbits/sec    0   sender
[  5]   0.00-10.00  sec   110 MBytes  92.5 Mbits/sec        receiver
```

---

## 📦 Cara Pemasangan / Instalasi

### Pilihan A: Pasang via Paket Debian (.deb) — Sangat Disarankan
```bash
sudo apt update
sudo apt install -y dkms build-essential linux-headers-$(uname -r) wget
wget https://github.com/elsangithub/mt7668-driver/releases/download/v2.0.0/mt7668-dkms_2.0.0_all.deb
sudo dpkg -i mt7668-dkms_2.0.0_all.deb
sudo reboot
```

### Pilihan B: Kompilasi & Bangun Paket Debian dari Source Code
```bash
git clone https://github.com/elsangithub/mt7668-driver.git
cd mt7668-driver
chmod +x build-deb.sh
./build-deb.sh
sudo dpkg -i mt7668-dkms_2.0.0_all.deb
sudo reboot
```

---

## 🔧 Konfigurasi Kritis untuk STB FiberHome HG680-FJ

Pada STB Amlogic seperti FiberHome HG680-FJ, terdapat dua karakteristik perangkat keras yang memerlukan penanganan khusus di tingkat OS. Keduanya telah dibundel di dalam direktori `system/` dan otomatis diterapkan oleh paket `.deb`:

### 1. Blacklist Bluetooth (`system/etc/modprobe.d/blacklist-mt7668-bluetooth.conf`)
- **Penyebab**: MT7668 merupakan chip combo Wi-Fi + Bluetooth. Di kernel Linux, modul bawaan `btmtksdio` mencoba mendeteksi Bluetooth pada SDIO Function 2. Pada board STB tanpa jalur firmware MTK BT khusus, `btmtksdio` mengalami timeout (`error -110`) yang mengunci bus SDIO.
- **Solusi**: Memasukkan `btmtksdio` dan `btmtk` ke dalam blacklist sehingga bus SDIO dialokasikan 100% secara bersih hanya untuk Wi-Fi (`wlan_mt7668`).

### 2. Service SDIO Quiesce Shutdown (`system/etc/systemd/system/mt7668-shutdown.service`)
- **Penyebab**: Modul MT7668 pada FiberHome HG680-FJ terhubung ke jalur tegangan selalu-aktif (*always-on rails*: `VDDAO_3V3` dan `VDDAO_1V8`). Saat reboot melalui software (`reboot`), SoC Amlogic me-reset sementara chip MT7668 tetap menyala. Jika koneksi SDIO tidak diputus secara bersih sebelum SoC mati, *state machine* MT7668 akan terkunci dan gagal merespons perintah probe CMD5 saat menyala kembali (`error -110`).
- **Solusi**: Service `mt7668-shutdown.service` berjalan saat proses shutdown dan reboot:
  ```bash
  if [ -d /sys/bus/platform/drivers/meson-gx-mmc/ffe03000.sd ]; then
      echo ffe03000.sd > /sys/bus/platform/drivers/meson-gx-mmc/unbind
  fi
  ```
  Perintah ini melepas (*unbind*) host controller SDIO (`ffe03000.sd`) tepat sebelum sistem reset, menjamin MT7668 terdeteksi 100% normal pada warm reboot tanpa perlu cabut adaptor daya.

---

## 🛠 Rangkuman Patch & Optimasi Driver

1. **Auto-Spawn Interface AP (`gl_init.c`)**: Menambahkan parameter `ap_mode` dan probe hook untuk memunculkan `ap0` (`RUNNING_AP_MODE`).
2. **Harmonisasi Kernel Linux 6.8+ (`gl_p2p_kal.c` & `p2p_func.c`)**: Menyesuaikan deklarasi argumen `cfg80211_cac_event` dan `cfg80211_ch_switch_notify`.
3. **Keamanan Livepatch Symbol (`gl_kal.c`)**: Menghindari kegagalan modpost akibat `kallsyms_on_each_symbol` non-ekspor pada Linux $\ge$ 5.7.
4. **Pembatasan Ukuran Paket DMA (`config.h`)**: Membatasi `CFG_TX_MAX_PKT_SIZE` ke 1408 byte guna mencegah buffer overflow pada DMA controller `meson-gx-mmc`.
5. **Peredaman Log Spam (`debug.h`)**: Mengaktifkan `DBG_DISABLE_ALL_LOG 1` untuk menjamin `dmesg` bebas spam frame.
6. **Kompatibilitas Kompiler Universal (`Makefile` & `dkms.conf`)**: Injeksi flag `CONFIG_CC_HAS_MIN_FUNCTION_ALIGNMENT=` agar GCC 12/13/14 dapat mengompilasi pada header kernel modern.

---

## 📜 Lisensi
GPL-2.0 / MediaTek Proprietary Base.

---

## 🤝 Kredit & Penghargaan
- **MediaTek Inc.**: Basis kode driver asli MT6632/MT7668.
- **junglon**: Patch rilis baseline v1.0.3 dan inisiasi adaptasi Amlogic.
- **Komunitas Ophub & Armbian**: Header kernel dan infrastruktur pengujian Amlogic G12A.
- **Elsangithub**: Rekayasa Rilis Major v2.0.0, implementasi Dedicated AP Mode, standarisasi paket DKMS, dan dokumentasi.
