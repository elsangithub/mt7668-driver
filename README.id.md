<p align="right">
  <a href="README.md">English</a> | <b>Bahasa Indonesia</b>
</p>

# Driver Wi-Fi MediaTek MT7668 SDIO untuk TV Box Amlogic (Armbian Ophub)

[![Release](https://img.shields.io/badge/release-v2.0.2-blue.svg)](https://github.com/elsangithub/mt7668-driver/releases)
[![Build & Release](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://github.com/elsangithub/mt7668-driver/actions)
[![DKMS Ready](https://img.shields.io/badge/DKMS-Automated_Build-brightgreen.svg)](https://github.com/elsangithub/mt7668-driver)
[![License: Dual BSD/GPL](https://img.shields.io/badge/License-Dual_BSD%2FGPL-blue.svg)](LICENSE)

Driver kernel Linux *out-of-tree* berkinerja tinggi berbasis DKMS yang telah di-*patch* khusus untuk modul **MediaTek MT7668** (SDIO ID `037A:7608` / `037A:6602`) dual-band 802.11a/b/g/n/ac 2x2 MIMO.

Dioptimalkan secara khusus untuk mengatasi batasan arsitektur pengontrol SDIO Amlogic G12A (S905X2), dan telah diuji serta divalidasi langsung secara fisik pada perangkat **FiberHome HG680-FJ**.

Proyek ini merupakan pengembangan dan penyempurnaan lanjutan dari implementasi dasar repositori [**junglon/mt7668-driver**](https://github.com/junglon/mt7668-driver) (yang awalnya ditargetkan untuk ZTE B860H V5), dengan penambahan optimasi multi-core SMP CPU affinity, Dedicated AP Mode (`ap0`), kepatuhan filesystem modern UsrMerge, isolasi koeksistensi bersama MT7663, serta kompatibilitas multi-kernel Linux LTS.

> [!NOTE]
> **Lingkungan yang Telah Teruji & Tervalidasi:**
> Driver ini telah diuji dan diverifikasi secara langsung pada rilis **Armbian by Ophub**:
> - **Debian 13 (Trixie)** dengan kernel **`6.12.112-ophub`**
> - Target Board: **FiberHome HG680-FJ (Amlogic S905X2 / Meson G12A)**
>
> Rilis Ophub memuat penyesuaian khusus pada Device Tree (DTB) dan subsistem clock/daya untuk TV box Amlogic.

> [!WARNING]
> **Pernyataan Kompatibilitas untuk Versi Kernel Lain:**
> Meskipun arsitektur DKMS memungkinkan kompilasi otomatis pada versi Linux lainnya, **tetap ada kemungkinan driver belum cocok 100%** dengan rilis kernel yang belum pernah kami uji (misalnya kernel *mainline vanilla*, kernel non-LTS, atau rilis kernel masa depan yang mengubah struktur API jaringan internal Linux). Jika Anda menemukan kegagalan kompilasi atau masalah saat dijalankan di versi kernel lain, silakan buat laporan kendala di menu *GitHub Issues* dengan melampirkan log `uname -a` dan `dmesg`.

---

## 🔍 Kompatibilitas Hardware: FiberHome HG680-FJ & ZTE B860H V5

| Model / Varian Perangkat | Modul Fisik | Core Chipset Internal | Status | Catatan |
| :--- | :--- | :--- | :--- | :--- |
| **FiberHome HG680-FJ (Varian A)** | MediaTek MT7668 | **MediaTek MT7668** (`037A:7608` / `037A:6602`) | ✅ Didukung | Langsung bekerja dengan DTB bawaan |
| **FiberHome HG680-FJ (Varian B)** | AMPAK MT7661RSN | MediaTek MT7663 (`037A:7663`) | ➡️ Driver Pendamping | Gunakan [elsangithub/mt7663-driver](https://github.com/elsangithub/mt7663-driver) |
| **ZTE ZXV10 B860H V5** | MediaTek MT7668 | **MediaTek MT7668** (`037A:7608` / `037A:6602`) | ✅ Didukung | Wajib pasang DTB perbaikan (`no-1-8-v;`) dari [dtb/](dtb/README.id.md) agar tahan warm reboot |

- **Unit MT7668**: Membutuhkan paket DKMS ini (**`mt7668-dkms`**) agar Wi-Fi Dual-Band 2.4 GHz & 5 GHz dapat diinisialisasi secara penuh dan stabil.
- **TV Box ZTE B860H V5**: Karena jalur regulator daya *Always-On*, gunakan berkas DTB teruji kami (`dtb/amlogic/meson-g12a-b860h-v5.dtb`) yang dijelaskan di [dtb/README.id.md](dtb/README.id.md) agar STB dapat di-reboot secara software tanpa perlu cabut-colok adaptor listrik.
- **Unit AMPAK MT7661RSN / MT7663**: Membutuhkan paket terpisah `mt7663-dkms`.
- **Koeksistensi Bersih**: Paket ini mengisolasi konfigurasi firmware ke `/lib/firmware/wifi.cfg` dan blacklist modul yang bersih, sehingga aman jika Anda membangun image sistem bersama.

### Cara Memeriksa Varian Chipset di STB Anda:
Jalankan perintah berikut di terminal STB:
```bash
cat /sys/bus/sdio/devices/*/device 2>/dev/null || cat /sys/bus/sdio/devices/*/vendor 2>/dev/null
```
* Jika terminal menampilkan `0x7608` atau `0x6602` (dengan vendor `0x037a`), maka unit Anda menggunakan modul **MediaTek MT7668** dan membutuhkan driver ini!
* Jika menampilkan `0x7663` atau `0x7603`, maka unit Anda menggunakan modul **MediaTek MT7663**.

---

## 🚀 Fitur Unggulan Versi 2.0.0 (Hasil Pengujian Nyata)

- **Pure Standalone Wi-Fi**: 100% stabil beroperasi mandiri tanpa perlu kabel LAN terhubung (`eth0` down).
- **Dual-Band 2.4 GHz & 5 GHz VHT80**: Mendukung 802.11ac 2x2 MIMO dengan kecepatan fisik link (PHY Rate) hingga **867 Mbps**, tembus **95.66 Mbps throughput nyata** dengan latensi ultra-rendah (Ping 3 ms, 0.0% packet loss).
- **Dedicated SoftAP / Hotspot Mode (`ap_mode=1`)**: Mendukung pembuatan antarmuka virtual **`ap0`** secara simultan berdampingan dengan `wlan0` untuk mode Router Hotspot 5 GHz atau Wi-Fi Repeater.
- **Native SMP Multi-Core CPU Affinity**: Tiga kthread utama driver (`hif_thread`, `rx_thread`, dan `main_thread`) dipatok langsung dari tingkat kernel C (`set_cpus_allowed_ptr`) ke CPU 1, 2, dan 3, membebaskan **CPU0** secara permanen.
- **Dynamic Hardware IRQ Routing**: Interupsi bus SDIO (`ffe03000.mmc`) dialihkan otomatis ke CPU 2 dan 3 melalui udev script, menjaga timer sistem di CPU0 tetap responsif tanpa lag.
- **RPS Network Packet Steering**: Pemrosesan antrean paket jaringan dioper ke CPU 1, 2, 3 (`rps_cpus: e`), melipatgandakan throughput tanpa bottleneck.
- **FIFO Underflow & Overflow Fast-Path**: Penanganan instan register interrupt `WASR_RX0/1_UNDER_FLOW` dan `WASR_TX1_OVER_FLOW` di `nic.c`, mencegah chip panik reset saat lalu lintas data padat (*traffic flood*).
- **Hard Dummy Bluetooth Driver Blacklist**: Mencegah konflik driver SDIO Bluetooth bawaan kernel Linux (`btmtksdio` / `btmtk`) menggunakan teknik `install ... /bin/true` agar inisialisasi boot tidak macet.
- **Zero-Hang Warm Reboot**: Integrasi `mt7668-shutdown.service` memutus controller MMC SDIO sebelum sistem shutdown, menjamin deteksi hardware tetap 100% mulus saat restart (`sudo reboot`).
- **Profil Termal Seimbang**: Parameter radio disetel optimal sehingga suhu SoC STB tetap adem dan stabil di kisaran **~53 °C**.

---

## 📦 Panduan Instalasi (Armbian Ophub)

> [!IMPORTANT]
> **JANGAN menjalankan `apt install linux-headers-$(uname -r)` di Armbian Ophub!**  
> Repositori standar Debian/Ubuntu tidak menyediakan kernel custom Ophub. Di Armbian Ophub, header kernel **sudah terpasang otomatis** di direktori `/usr/src/linux-headers-$(uname -r)`.

### Langkah 1: Pasang Paket Pendukung Build & DKMS
```bash
sudo apt update
sudo apt install -y dkms build-essential wget
```

### Langkah 2: Verifikasi Keberadaan Kernel Headers
```bash
ls -d /usr/src/linux-headers-$(uname -r)
```
*(Jika direktori muncul, sistem Anda siap 100% untuk kompilasi DKMS).*

### Langkah 3: Unduh & Pasang Paket Debian (.deb)
```bash
# Unduh paket rilis resmi terbaru (v2.0.2)
wget https://github.com/elsangithub/mt7668-driver/releases/download/v2.0.2/mt7668-dkms_2.0.2_all.deb

# Pasang paket (DKMS akan otomatis mengompilasi modul untuk kernel aktif dalam ~15-20 detik)
sudo dpkg -i mt7668-dkms_2.0.2_all.deb
```

### Langkah 4: Muat Driver atau Reboot
Driver langsung aktif setelah instalasi. Untuk memastikan semua konfigurasi udev dan layanan tersinkronisasi sempurna:
```bash
sudo reboot
```

---

## 📶 Menghubungkan & Memverifikasi Wi-Fi

### Langkah 1: Pindai Jaringan Wi-Fi yang Tersedia:
```bash
nmcli device wifi list
```

### Langkah 2: Hubungkan ke Jaringan Wi-Fi via Terminal:
```bash
# Hubungkan ke SSID Wi-Fi
sudo nmcli dev wifi connect "NAMA_SSID_ANDA" password "PASSWORD_WIFI"

# Simpan profil permanen ke penyimpanan
sync
```

### Langkah 3: Periksa Status Koneksi & Kecepatan Link Fisik:
```bash
iw dev wlan0 link
```
*Contoh output (Frekuensi 5 GHz)*:
```text
Connected to e8:43:68:3e:27:3e (on wlan0)
	SSID: Elsan_5G
	freq: 5785.0
	signal: -47 dBm
	tx bitrate: 173.0 MBit/s (naik otomatis saat traffic padat hingga 867 Mbps)
```

### Verifikasi Distribusi IRQ Multi-Core:
```bash
grep -E "CPU|mmc" /proc/interrupts
```
*Interupsi SDIO (`ffe03000.mmc`) akan terdistribusi ke **CPU2 / CPU3**, menjaga **CPU0** tetap bebas beban.*

---

## 📡 Mode Hotspot / SoftAP & Parameter Modular `ap_mode`

Mulai dari **v2.0.0**, driver kernel `wlan_mt7668` memperkenalkan dukungan modular **Dedicated AP Mode** dengan antarmuka virtual independen **`ap0`**.

### Parameter Modul Kernel `ap_mode`:
Driver menyediakan parameter kernel yang dapat dikonfigurasi melalui berkas `/etc/modprobe.d/mt7668.conf`:

| Nilai | Deskripsi Mode | Skenario Penggunaan |
| :---: | :--- | :--- |
| **`ap_mode=0`** *(Bawaan)* | **Mode Klien Murni (STA)** (`wlan0` saja) | Penggunaan standar desktop, server, atau TV box klien. Sangat ringan tanpa overhead. |
| **`ap_mode=1`** | **Dedicated AP Mode** (`ap0` + `wlan0`) | Hotspot router, repeater Wi-Fi, atau dipasangkan dengan Web UI Hotspot / `hostapd`. |
| **`ap_mode=2`** | **Dual AP Mode** | Menjalankan dua interface AP virtual sekaligus. |
| **`ap_mode=3`** | **Mode Konkuren P2P + AP** | Wi-Fi Direct berjalan bersamaan dengan access point. |

### Cara Mengaktifkan Mode AP (`ap0`):
Jalankan perintah berikut agar interface `ap0` otomatis aktif saat boot:
```bash
echo "options wlan_mt7668 ap_mode=1" | sudo tee /etc/modprobe.d/mt7668.conf
sudo reboot
```
Setelah reboot, antarmuka `ap0` akan muncul mandiri berdampingan dengan `wlan0`.

---

## 🌐 Paket Pelengkap Resmi: Web UI Router & Hotspot Manager (`mt7663-router-webui`)

Agar repositori driver kernel ini tetap ramping, ringan, dan murni berfokus pada dukungan perangkat keras DKMS tingkat kernel, seluruh antarmuka web manajemen, orkestrasi DHCP/DNS, dan otomasi routing telah dipisahkan ke repositori pendamping resmi:

👉 [**`mt7663-router-webui` (Repositori GitHub Resmi)**](https://github.com/elsangithub/mt7663-router-webui)

<div align="center">
  <img src="https://raw.githubusercontent.com/elsangithub/mt7663-router-webui/main/docs/screenshots/01-overview.png" alt="MT7668 Router Web UI Dashboard" width="850">
</div>

### Fitur Utama yang Disediakan oleh `mt7663-router-webui` untuk MT7668:
* **Dashboard Web WSGI Zero-Dependency**: Web UI Python 3 bawaan pada port `8080` (sangat ringan, konsumsi RAM `< 25 MB`).
* **Telemetri Perangkat Keras Live**: Pemantauan langsung suhu SoC Amlogic, beban CPU, rincian RAM, dan lalu lintas bandwidth unduh/unggah per klien.
* **Pengelola Hotspot & Wi-Fi Klien Turnkey**: Pemindai Wi-Fi satu klik, konfigurator hotspot interaktif (`ap0` dengan SSID, WPA2/WPA3, lebar kanal 20/40/80 MHz, dan preset DNS upstream).
* **Mode Wireless Repeater DBDC Ganda**: Integrasi otomatis antara koneksi uplink (`wlan0`) dan pemancar hotspot (`ap0`) dilengkapi `iptables` NAT masquerade untuk internet tanpa jeda.
* **Bilingual Penuh**: Beralih instan antara Bahasa Indonesia dan Bahasa Inggris.

```bash
# Untuk memasang paket Web UI & Pengelola Hotspot di atas driver ini:
sudo apt install ./mt7663-router-webui_1.0.1_all.deb
```

---

## 🗑️ Cara Hapus Bersih (Clean Uninstallation)

Jika Anda ingin mencopot pemasangan driver ini dan mengembalikan sistem ke kondisi semula, paket ini dilengkapi dengan script pembersih otomatis (`prerm` dan `postrm`):

### Hapus Bersih Total Termasuk Seluruh Konfigurasi (Purge):
```bash
sudo apt purge -y mt7668-dkms
```

#### Apa yang Dibersihkan Secara Otomatis Saat Penghapusan?
1. Menghentikan antarmuka Wi-Fi (`ip link set dev wlan0 down`).
2. Meng-*unload* modul kernel dari memori RAM (`rmmod wlan_mt7668`).
3. Menghapus pendaftaran DKMS dan binari modul yang terkompilasi dari `/var/lib/dkms/mt7668/`.
4. Menghapus konfigurasi autoload di `/etc/modules-load.d/wlan_mt7668.conf`.
5. Menonaktifkan dan menghapus layanan `/etc/systemd/system/mt7668-shutdown.service`.
6. Menghapus konfigurasi tuning dan skrip udev (`/etc/udev/rules.d/99-mt7668-performance.rules`, `/etc/sysctl.d/99-mt7668-throughput.conf`, `/usr/lib/udev/mt7668-irq-tune.sh`).
7. Mengembalikan backup firmware bawaan dari `/usr/lib/firmware/backup_stock_mt7668/` jika tersedia.

---

## 🤝 Penghargaan & Kredit (Credits & Acknowledgments)
- **MediaTek Inc.**: Arsitektur chipset asli dan baseline driver.
- [**junglon/mt7668-driver**](https://github.com/junglon/mt7668-driver): Implementasi referensi yang sangat berharga dan wawasan mendalam mengenai driver nirkabel MediaTek untuk platform Amlogic (khususnya ZTE B860H V5).
- **Komunitas Ophub & Armbian**: Custom kernel Linux dan perkakas build untuk TV box Amlogic.
- **Van der Decken**: Pengembang dan pemelihara (maintainer).

---

## 📄 Lisensi
Driver ini dirilis di bawah lisensi **Dual BSD / GPL-2.0**.
Lihat berkas [LICENSE](LICENSE) untuk ketentuan lengkap.
