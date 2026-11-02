# MediaTek MT7668 SDIO Wi-Fi Linux DKMS Driver (v2.0.0)

[![Release](https://img.shields.io/badge/release-v2.0.0-blue.svg)](https://github.com/elsangithub/mt7668-driver/releases)
[![DKMS](https://img.shields.io/badge/DKMS-enabled-brightgreen.svg)](https://github.com/elsangithub/mt7668-driver)
[![Kernel](https://img.shields.io/badge/kernel-6.1--6.18+-orange.svg)](https://github.com/elsangithub/mt7668-driver)
[![Hardware](https://img.shields.io/badge/hardware-FiberHome%20HG680--FJ%20(S905X2)-purple.svg)](https://github.com/elsangithub/mt7668-driver)
[![License](https://img.shields.io/badge/license-Dual%20BSD%2FGPL-green.svg)](LICENSE)
[![Indonesian Guide](https://img.shields.io/badge/baca-Bahasa%20Indonesia-red.svg)](README.id.md)

Production-grade, turnkey out-of-tree Linux kernel DKMS driver for the **MediaTek MT7668** (SDIO `037a:7608` / `037a:6602`) 802.11ac 2x2 Wi-Fi combo chipset. Tailored specifically for ARM64 Linux kernels (6.1 LTS, 6.6 LTS, 6.12 LTS, and 6.18+) on Amlogic TV boxes (such as **FiberHome HG680-FJ**, Amlogic S905X2 / Meson G12A), Debian 12 Bookworm, and Ubuntu 24.04 Noble.

---

## 🌟 What's New in Version 2.0.0 (Major Release by Elsangithub)

Version **2.0.0** elevates the MT7668 driver to full feature parity with our production-proven `mt7663-driver` ecosystem:

1. **📡 Dedicated SoftAP / Hotspot Mode (`ap_mode` & `ap0`)**:
   Introduces the modular kernel parameter `ap_mode`. The driver can now dynamically instantiate a dedicated virtual interface (`ap0`) alongside `wlan0` at probe time, allowing the FiberHome HG680-FJ to function as a high-speed Dual-Band 5 GHz Hotspot Router or Wi-Fi Repeater. Compatible with `hostapd` and companion router dashboards such as [`mt7663-router-webui`](https://github.com/elsangithub/mt7663-router-webui).
2. **🐧 Kernel 6.8+ & Modern Upstream Compatibility**:
   Seamlessly integrates updated `cfg80211` APIs (`cfg80211_cac_event`, `cfg80211_ch_switch_notify`, and livepatch safety protections) without modpost compilation failures.
3. **📦 Standardized Debian DKMS Packaging (`debian/`)**:
   Standardized Debian packaging structure with intelligent self-healing, automatic kernel header detection, and conflict-free upgrades.

---

## 📡 SoftAP / Hotspot Support & Modular `ap_mode` Parameter

The driver features a runtime module parameter `ap_mode` configured in `/etc/modprobe.d/mt7668.conf`:

| Value | Mode Description | Primary Use Case |
| :---: | :--- | :--- |
| **`ap_mode=0`** *(Default)* | **Pure Client (STA) Mode** (`wlan0` only) | Standard desktop, headless server, or TV box client operations. Zero overhead. |
| **`ap_mode=1`** | **Dedicated AP Mode** (`ap0` + `wlan0`) | Hotspot router, Wi-Fi repeater, or pairing with `mt7663-router-webui` / `hostapd`. |
| **`ap_mode=2`** | **Dual AP Mode** | Multiple distinct SSID access points. |
| **`ap_mode=3`** | **P2P + AP Concurrent Mode** | Wi-Fi Direct alongside access point. |

### Enabling Dedicated AP Mode (`ap0`):
To enable AP mode so that `ap0` appears on boot:
```bash
echo "options wlan_mt7668 ap_mode=1" | sudo tee /etc/modprobe.d/mt7668.conf
sudo modprobe -r wlan_mt7668 2>/dev/null || true
sudo modprobe wlan_mt7668
ip link show
```

To revert back to standard client mode:
```bash
echo "options wlan_mt7668 ap_mode=0" | sudo tee /etc/modprobe.d/mt7668.conf
sudo modprobe -r wlan_mt7668 2>/dev/null || true
sudo modprobe wlan_mt7668
```

---

## 🚀 Verified Performance (FiberHome HG680-FJ)

Tested on **FiberHome HG680-FJ (Amlogic S905X2 / Meson G12A)** running **Armbian (Ubuntu 24.04 Noble / Debian 12 Bookworm)** with kernels `Linux 6.12.x-ophub` and `6.18.x-ophub`:

- **Clean dmesg**: Zero `[wlan]` trace log spam (`DBG_DISABLE_ALL_LOG 1`).
- **Power Stability**: Low-power auto-sleep disabled (`CFG_ENABLE_FULL_PM 0`) to maintain SDIO clock synchronization.
- **DKMS Support**: Automatically compiles and updates across kernel upgrades.
- **Verified Throughput (iperf3)**:
  - **5 GHz Band (Channel 157, 405–780 Mbps link rate)**:
    - **Upload (TX)**: **94.2 Mbps** (0 retransmits)
    - **Download (RX)**: **50.2 Mbps**
  - **2.4 GHz Band (Channel 6)**:
    - **Upload (TX)**: **81.2 Mbps** (0 retransmits)
    - **Download (RX)**: **26.9 Mbps**

```text
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec   112 MBytes  94.2 Mbits/sec    0   sender
[  5]   0.00-10.00  sec   110 MBytes  92.5 Mbits/sec        receiver
```

---

## 📦 Installation Methods

### Option A: Install via Pre-built Debian Package (.deb) — Recommended
```bash
sudo apt update
sudo apt install -y dkms build-essential linux-headers-$(uname -r) wget
wget https://github.com/elsangithub/mt7668-driver/releases/download/v2.0.0/mt7668-dkms_2.0.0_all.deb
sudo dpkg -i mt7668-dkms_2.0.0_all.deb
sudo reboot
```

### Option B: Build Debian Package from Source
```bash
git clone https://github.com/elsangithub/mt7668-driver.git
cd mt7668-driver
chmod +x build-deb.sh
./build-deb.sh
sudo dpkg -i mt7668-dkms_2.0.0_all.deb
sudo reboot
```

---

## 🔧 Essential System Configurations for FiberHome HG680-FJ

On Amlogic TV boxes such as the FiberHome HG680-FJ, two hardware design traits require specific OS configurations, both of which are bundled in `system/` and automatically applied by the `.deb` package:

### 1. Bluetooth Blacklist (`system/etc/modprobe.d/blacklist-mt7668-bluetooth.conf`)
- **Why it is needed**: The MT7668 is a combo chip. Under Linux, upstream `btmtksdio` attempts to probe Bluetooth on SDIO Function 2. On TV box boards without dedicated MTK BT firmware loading lines, `btmtksdio` times out (`error -110`), stalling the SDIO bus.
- **Solution**: Blacklisting `btmtksdio` and `btmtk` prevents the upstream driver from binding to Function 2, leaving the SDIO bus dedicated entirely and cleanly to Wi-Fi (`wlan_mt7668`).

### 2. SDIO Quiesce Shutdown Service (`system/etc/systemd/system/mt7668-shutdown.service`)
- **Why it is needed**: The MT7668 module on the FiberHome HG680-FJ is powered by always-on power rails (`VDDAO_3V3` and `VDDAO_1V8`). On a soft reboot (`reboot`), the SoC resets while the MT7668 stays energized. If the SDIO interface is not cleanly disconnected prior to reset, the MT7668 internal state machine locks up (`CMD5 timeout -110`).
- **Solution**: The `mt7668-shutdown.service` executes during shutdown and reboot targets:
  ```bash
  if [ -d /sys/bus/platform/drivers/meson-gx-mmc/ffe03000.sd ]; then
      echo ffe03000.sd > /sys/bus/platform/drivers/meson-gx-mmc/unbind
  fi
  ```
  This cleanly disconnects the SDIO bus, guaranteeing 100% reliable detection on warm reboot.

---

## 🛠 Key Driver Patches & Fixes

1. **Dedicated AP Interface Spawning (`gl_init.c`)**: Added `ap_mode` parameter and probe hooks to spawn `ap0` (`RUNNING_AP_MODE`).
2. **Modern Kernel 6.8+ Adaptations (`gl_p2p_kal.c` & `p2p_func.c`)**: Fixed `cfg80211_cac_event` and `cfg80211_ch_switch_notify` function signatures.
3. **Livepatch Symbol Safety (`gl_kal.c`)**: Prevented modpost failure from unexported `kallsyms_on_each_symbol` on Linux $\ge$ 5.7.
4. **DMA Bounce Buffer Clamping (`config.h`)**: Clamped `CFG_TX_MAX_PKT_SIZE` to 1408 bytes to avoid SDIO DMA FIFO overflows on `meson-gx-mmc`.
5. **Log Spam Suppression (`debug.h`)**: Set `DBG_DISABLE_ALL_LOG 1` for clean `dmesg` output.
6. **Universal Compiler Compatibility (`Makefile` & `dkms.conf`)**: Injected `CONFIG_CC_HAS_MIN_FUNCTION_ALIGNMENT=` to bridge GCC 12/13/14 hosts with GCC 15 builds.

---

## 📜 License
GPL-2.0 / MediaTek Proprietary Base.

---

## 🤝 Credits & Acknowledgments
- **MediaTek Inc.**: Original MT6632/MT7668 combo driver codebase.
- **junglon**: Baseline v1.0.3 patches and initial Amlogic adaptation.
- **Ophub & Armbian Community**: Kernel headers and Amlogic G12A testing infrastructure.
- **Elsangithub**: Major Release v2.0.0 engineering, dedicated AP mode implementation, modern packaging, and documentation.
