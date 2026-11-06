<p align="right">
  <b>English</b> | <a href="README.id.md">Bahasa Indonesia</a>
</p>

# MediaTek MT7668 SDIO Wi-Fi Driver for Amlogic TV Boxes (Armbian Ophub)

[![Release](https://img.shields.io/badge/release-v2.0.1-blue.svg)](https://github.com/elsangithub/mt7668-driver/releases)
[![Build & Release](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://github.com/elsangithub/mt7668-driver/actions)
[![DKMS Ready](https://img.shields.io/badge/DKMS-Automated_Build-brightgreen.svg)](https://github.com/elsangithub/mt7668-driver)
[![License: Dual BSD/GPL](https://img.shields.io/badge/License-Dual_BSD%2FGPL-blue.svg)](LICENSE)

A high-performance out-of-tree Linux kernel driver with DKMS automation, specifically patched for the **MediaTek MT7668** combo module (SDIO IDs `037A:7608` / `037A:6602`) dual-band 802.11a/b/g/n/ac 2x2 MIMO.

Specially engineered to overcome Amlogic G12A (S905X2) SDIO host controller architectural quirks, and physically tested & validated directly on **FiberHome HG680-FJ** TV boxes.

This project builds upon and evolves the foundational implementation from [**junglon/mt7668-driver**](https://github.com/junglon/mt7668-driver) (originally targeted for ZTE B860H V5), extending it with enterprise-grade multi-core SMP affinity, Dedicated AP Mode (`ap0`), UsrMerge filesystem compliance, strict multi-driver co-existence with MT7663, and modern Linux LTS kernel compatibility.

> [!NOTE]
> **Tested & Validated Environment:**
> This driver has been thoroughly tested and verified on official **Armbian by Ophub** releases:
> - **Debian 13 (Trixie)** with kernel **`6.12.112-ophub`**
> - Target Board: **FiberHome HG680-FJ (Amlogic S905X2 / Meson G12A)**
>
> Ophub releases include specific Device Tree (DTB) and power/clock tuning for Amlogic TV boxes.

> [!WARNING]
> **Compatibility Statement for Other Kernel Versions:**
> While DKMS architecture provides automated dynamic compilation across Linux kernels, **100% out-of-the-box compatibility is not guaranteed** for untested kernel releases (such as mainline vanilla kernels, non-LTS releases, or future kernel trees that introduce breaking internal netdev/cfg80211 API changes). If you encounter compilation failures or driver issues on other kernels, please open a GitHub Issue attaching your `uname -a` and `dmesg` logs.

---

## 🔍 Hardware Compatibility & FiberHome HG680-FJ Variants

The **FiberHome HG680-FJ** (Amlogic S905X2 / G12A) TV box was manufactured across production batches with **two different internal Wi-Fi chipset variants**:

| Hardware Variant | Physical Module | Internal Core Chipset | Recommended Linux Driver |
| :--- | :--- | :--- | :--- |
| **Variant A** | MediaTek MT7668 | **MediaTek MT7668** (`037A:7608` / `037A:6602`) | **This DKMS Driver (`mt7668-dkms`)** |
| **Variant B** | AMPAK MT7661RSN | MediaTek MT7663 (`037A:7663`) | [elsangithub/mt7663-driver](https://github.com/elsangithub/mt7663-driver) |

- **MT7668 Units (Variant A)**: Requires this DKMS package (**`mt7668-dkms`**) for complete dual-band initialization and full throughput operation.
- **AMPAK MT7661RSN / MT7663 Units (Variant B)**: Requires our companion `mt7663-dkms` package.
- **Clean Coexistence**: Isolates firmware configuration to `/lib/firmware/wifi.cfg` alongside strict module blacklisting, ensuring system images remain conflict-free.

### How to Check the Wi-Fi Chipset on Your STB:
Execute the following in your STB terminal:
```bash
cat /sys/bus/sdio/devices/*/device 2>/dev/null || cat /sys/bus/sdio/devices/*/vendor 2>/dev/null
```
* If the output reports `0x7608` or `0x6602` (with vendor `0x037a`), your device is powered by the **MediaTek MT7668** module and requires this driver!
* If it reports `0x7663` or `0x7603`, your device has the **MediaTek MT7663** module.

---

## 🚀 Key Features in Version 2.0.0 (Proven Benchmark Results)

- **Pure Standalone Wi-Fi**: 100% stable operation without needing Ethernet cables connected (`eth0` down).
- **Dual-Band 2.4 GHz & 5 GHz VHT80**: Full 802.11ac 2x2 MIMO support with physical link speeds up to **867 Mbps PHY**, delivering **95.66 Mbps real-world download throughput** with ultra-low latency (3 ms ping, 0.0% packet loss).
- **Dedicated SoftAP / Hotspot Mode (`ap_mode=1`)**: Modular dynamic creation of a standalone virtual interface (**`ap0`**) alongside `wlan0` for 5 GHz Hotspot Routers and Wi-Fi Repeaters.
- **Native SMP Multi-Core CPU Affinity**: Kernel worker threads (`hif_thread`, `rx_thread`, and `main_thread`) are pinned at the kernel C level (`set_cpus_allowed_ptr`) to CPU 1, 2, and 3, permanently protecting **CPU0** from starvation.
- **Dynamic Hardware IRQ Routing**: SDIO bus hardware interrupts (`ffe03000.mmc`) are dynamically routed to CPU 2 and 3 via udev rules, eliminating system lag and latency jitter.
- **RPS Network Packet Steering**: SoftIRQ network stack processing is balanced across CPU 1, 2, and 3 (`rps_cpus: e`), maximizing throughput under continuous load.
- **FIFO Underflow & Overflow Fast-Path**: Instant hardware interrupt clearing for `WASR_RX0/1_UNDER_FLOW` and `WASR_TX1_OVER_FLOW` in `nic.c`, eliminating chip panic resets during traffic floods.
- **Hard Dummy Bluetooth Driver Blacklist**: Employs `install ... /bin/true` rules in `/etc/modprobe.d/blacklist-mt7668-bluetooth.conf` to completely avoid SDIO bus lockups caused by incompatible in-tree Bluetooth modules (`btmtksdio`).
- **Zero-Hang Warm Reboot**: Built-in `mt7668-shutdown.service` quiesces the MMC SDIO controller before shutdown, guaranteeing 100% hardware redetection upon warm reboot (`sudo reboot`).
- **Balanced Thermal Profile**: Radio parameters are calibrated for a cool, stable SoC operating temperature at **~53 °C**.

---

## 📦 Installation Guide (Armbian Ophub)

> [!IMPORTANT]
> **DO NOT run `apt install linux-headers-$(uname -r)` on Armbian Ophub!**  
> Debian/Ubuntu upstream repositories do not provide custom Ophub kernels. On Armbian Ophub, matching kernel headers are **already pre-installed** in `/usr/src/linux-headers-$(uname -r)`.

### Step 1: Install Build & DKMS Prerequisites
```bash
sudo apt update
sudo apt install -y dkms build-essential wget
```

### Step 2: Verify Kernel Headers
```bash
ls -d /usr/src/linux-headers-$(uname -r)
```
*(If the directory exists, your system is 100% ready for DKMS).*

### Step 3: Download & Install the Debian Package (.deb)
```bash
# Download the latest official v2.0.1 release
wget https://github.com/elsangithub/mt7668-driver/releases/download/v2.0.1/mt7668-dkms_2.0.1_all.deb

# Install package (DKMS will compile the module for your active kernel in ~15-20 seconds)
sudo dpkg -i mt7668-dkms_2.0.1_all.deb
```

### Step 4: Load Driver or Reboot
The driver loads automatically after installation. To ensure all udev performance rules and services synchronize cleanly:
```bash
sudo reboot
```

---

## 📶 Connecting & Verifying Wi-Fi

### Step 1: Scan for Available Wi-Fi Networks:
```bash
nmcli device wifi list
```

### Step 2: Connect to Wi-Fi via Terminal:
```bash
# Connect to your Wi-Fi SSID
sudo nmcli dev wifi connect "YOUR_SSID" password "YOUR_PASSWORD"

# Commit changes to persistent storage
sync
```

### Step 3: Check Connection Status & PHY Link Speed:
```bash
iw dev wlan0 link
```
*Example output (5 GHz band)*:
```text
Connected to e8:43:68:3e:27:3e (on wlan0)
	SSID: YOUR_SSID
	freq: 5785.0
	signal: -47 dBm
	tx bitrate: 173.0 MBit/s (scales dynamically up to 867 Mbps under load)
```

### Verify Multi-Core Hardware IRQ Distribution:
```bash
grep -E "CPU|mmc" /proc/interrupts
```
*SDIO interrupts (`ffe03000.mmc`) are distributed to **CPU2 / CPU3**, keeping **CPU0** completely unburdened.*

---

## 📡 SoftAP / Hotspot Mode & Modular Parameter `ap_mode`

Starting with **v2.0.0**, the `wlan_mt7668` kernel driver introduces modular **Dedicated AP Mode** support featuring an independent virtual interface **`ap0`**.

### Kernel Parameter `ap_mode`:
Configurable via `/etc/modprobe.d/mt7668.conf`:

| Value | Mode Description | Use Case Scenario |
| :---: | :--- | :--- |
| **`ap_mode=0`** *(Default)* | **Pure Client Mode (STA)** (`wlan0` only) | Standard desktop, server, or client TV box use. Zero overhead, lightweight. |
| **`ap_mode=1`** | **Dedicated AP Mode** (`ap0` + `wlan0`) | Hotspot router, Wi-Fi repeater, or paired with router web interfaces & `hostapd`. |
| **`ap_mode=2`** | **Dual AP Mode** | Spawns two independent virtual AP interfaces. |
| **`ap_mode=3`** | **P2P + AP Concurrent Mode** | Concurrent Wi-Fi Direct and access point operation. |

### How to Enable Dedicated AP Mode (`ap0`):
Execute the following to persist AP mode across boots:
```bash
echo "options wlan_mt7668 ap_mode=1" | sudo tee /etc/modprobe.d/mt7668.conf
sudo reboot
```
Upon boot, `ap0` will be created automatically alongside `wlan0`.

---

## 🌐 Official Companion Web GUI: Router & Hotspot Dashboard (`mt7663-router-webui`)

To keep this kernel driver repository lightweight, clean, and purely focused on kernel-level DKMS hardware support, all Web UI management interfaces, DHCP/DNS orchestration, and dynamic routing automation have been separated into our official companion repository:

👉 [**`mt7663-router-webui` (Official GitHub Repository)**](https://github.com/elsangithub/mt7663-router-webui)

<div align="center">
  <img src="https://raw.githubusercontent.com/elsangithub/mt7663-router-webui/main/docs/screenshots/01-overview.png" alt="MT7668 Router Web UI Dashboard" width="850">
</div>

### Key Capabilities Powered by `mt7663-router-webui` on MT7668:
* **Zero-Dependency WSGI Web Dashboard**: Built-in lightweight Python 3 Web UI running on port `8080` (ultra-low footprint: `< 25 MB` RAM usage).
* **Live Hardware & Network Telemetry**: Real-time monitoring of Amlogic SoC temperature, CPU load, RAM usage, and per-device real-time upload/download bandwidth.
* **Turnkey Hotspot & Client Management**: One-click Wi-Fi station scanner, interactive SoftAP configurator (`ap0` with WPA2/WPA3 Personal, 20/40/80 MHz channel widths, and custom upstream DNS presets).
* **Dual-Band Wireless Repeater Mode (DBDC Concurrent)**: Seamless orchestration of simultaneous client uplink (`wlan0`) and broadcast hotspot (`ap0`) with automated `iptables` NAT masquerading.
* **Full Bilingual Support**: Instant on-the-fly switching between English and Bahasa Indonesia.

```bash
# To install the companion Web UI & Hotspot Manager alongside this driver:
sudo apt install ./mt7663-router-webui_1.0.1_all.deb
```

---

## 🗑️ Clean Uninstallation (Purge)

If you ever wish to remove this driver and revert your system to clean factory state:
```bash
sudo apt purge -y mt7668-dkms
```

#### What is Automatically Cleaned Up:
1. Shuts down Wi-Fi interfaces (`ip link set dev wlan0 down`).
2. Unloads kernel modules from RAM (`rmmod wlan_mt7668`).
3. Unregisters DKMS module and cleans build artifacts from `/var/lib/dkms/mt7668/`.
4. Removes module autoload configurations from `/etc/modules-load.d/wlan_mt7668.conf`.
5. Disables and deletes the shutdown service `/etc/systemd/system/mt7668-shutdown.service`.
6. Removes performance tuning rules and scripts (`/etc/udev/rules.d/99-mt7668-performance.rules`, `/etc/sysctl.d/99-mt7668-throughput.conf`, `/usr/lib/udev/mt7668-irq-tune.sh`).
7. Restores pre-existing stock firmware backup from `/usr/lib/firmware/backup_stock_mt7668/` if present.

---

## 🤝 Credits & Acknowledgments
- **MediaTek Inc.**: Original chipset architecture and driver baseline.
- [**junglon/mt7668-driver**](https://github.com/junglon/mt7668-driver): Invaluable reference implementation and insights on MediaTek wireless drivers for Amlogic platforms (specifically ZTE B860H V5).
- **Ophub & Armbian Community**: Custom Linux kernels and build tooling for Amlogic TV boxes.
- **Van der Decken**: Maintainer and developer.

---

## 📄 License
This driver is licensed under **Dual BSD / GPL-2.0**.
See [LICENSE](LICENSE) for full details.
