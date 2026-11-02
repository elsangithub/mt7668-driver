# Changelog

All notable changes to the **MediaTek MT7668 Linux DKMS Driver** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.0.0] - 2026-11-02

### 🚀 Major Architectural Leap (Elsangithub Production Release)
This release represents a major evolutionary jump for the MediaTek MT7668 SDIO Wi-Fi driver, bringing it to full functional, throughput, and packaging parity with the acclaimed `mt7663-driver` ecosystem. The headline capability is the porting and introduction of **Dedicated AP Mode (`ap_mode` / `ap0`)**, turning FiberHome HG680-FJ (Amlogic S905X2 / Meson G12A) TV boxes into enterprise-grade 5 GHz 802.11ac Hotspot Routers and Wi-Fi Repeaters.

### Added
- **Dedicated AP Mode & Modular Kernel Parameter (`ap_mode`)**:
  - Implemented dynamic runtime module parameter `ap_mode` in `os/linux/gl_init.c`:
    - `ap_mode=0` (Default): Pure client station mode (`wlan0` only). Zero overhead, maximum stability for general desktop/server deployments.
    - `ap_mode=1`: Dedicated SoftAP mode. Automatically registers and instantiates the virtual interface `ap0` alongside `wlan0` at driver probe time. Ideal for companion routing packages like `mt7663-router-webui` and standalone `hostapd`.
    - `ap_mode=2`: Dual AP mode (dual AP virtual interfaces).
    - `ap_mode=3`: P2P + AP concurrent mode.
  - Added configuration template file `/etc/modprobe.d/mt7668.conf`.
- **Native SMP Multi-Core CPU Affinity in Kernel C (`gl_kal.c`)**:
  - Implemented `set_cpus_allowed_ptr` on `hif_thread`, `rx_thread`, and `main_thread` directly inside kernel thread entry points.
  - Automatically isolates all network traffic processing from CPU0 (`cpumask_clear_cpu(0, &mask)`), balancing worker threads dynamically across CPU 1, 2, and 3 to prevent CPU0 bottlenecks.
- **FIFO Underflow & Overflow Fast-Path (`nic/nic.c`)**:
  - Implemented instant hardware interrupt acknowledgement and fast-path clearing for `WASR_RX0_UNDER_FLOW`, `WASR_RX1_UNDER_FLOW`, and `WASR_TX1_OVER_FLOW`.
  - Prevents SDIO bus stalls and chip panic resets (`glResetTrigger`) during heavy bidirectional traffic floods.
- **Dynamic Hardware IRQ Balancing & RPS Rules**:
  - Bundled `/usr/lib/udev/wlan-irq-tune.sh` and `/etc/udev/rules.d/99-wlan-performance.rules`.
  - Automatically migrates SDIO hardware interrupts (`ffe03000.mmc`) to CPU 2 and 3 (`smp_affinity_list: 2,3`).
  - Activates Receive Packet Steering (RPS mask `e` / `0b1110`) on `wlan0` to offload TCP/IP network stack processing to CPU 1, 2, and 3.
- **Hard Dummy Bluetooth Driver Blacklist**:
  - Enforced `install btmtksdio /bin/true`, `install btmtk /bin/true`, and in-tree `mt76` driver blacklists in `/etc/modprobe.d/blacklist-mt7668-bluetooth.conf` to completely prevent SDIO bus collision on boot.
- **Automatic Firmware Backup & Clean Firmware Bundle**:
  - Bundled clean, verified firmware files in `system/lib/firmware/` (`EEPROM_MT7668.bin`, `TxPwrLimit_MT76x8.dat`, `WIFI_RAM_CODE_MT7668.bin`, `WIFI_RAM_CODE2_SDIO_MT7668.bin`, `mt7668_patch_e2_hdr.bin`, `wifi.cfg`).
  - Added automated preinst safety routine creating `/lib/firmware/backup_stock_mt7668/` before package extraction.
- **Modern Debian Packaging Architecture (`debian/`)**:
  - Standardized versioned `debian/` directory structure (`control`, `preinst`, `postinst`, `prerm`).
  - Automated DKMS self-healing in `postinst` (detects and cleans legacy versions, auto-rebuilds `modpost` if host glibc toolchain mismatches).
  - Automated CI/CD release workflow via GitHub Actions (`.github/workflows/release.yml`).

### Changed
- **Balanced Thermal Profile (`wifi.cfg`)**:
  - Fine-tuned queue loops (`HifTxLoop 16`, `OsTxLoop 8`) and disabled unnecessary VHT beamforming/STBC calculation for cooler daily operation (~53 °C).
- **DKMS Configuration (`dkms.conf`)**:
  - Upgraded `PACKAGE_VERSION` to `"2.0.0"`.
- **Kernel 6.8+ & Modern Upstream Compatibility**:
  - Updated `cfg80211_cac_event` signature handling in `os/linux/gl_p2p_kal.c` across Linux kernels (distinguishing 4-arg in 6.8+, 5-arg in 6.1..6.7, and 4-arg in 3.14..6.0).
  - Updated `cfg80211_ch_switch_notify` signature handling in `mgmt/p2p_func.c` to support puncturing bitmap parameters in Linux 6.8+ and 6.12+.
  - Safely guarded unexported `kallsyms_on_each_symbol` in `os/linux/gl_kal.c` on Linux 5.7+ when kernel `CONFIG_LIVEPATCH` is active.

### Removed
- Pruned obsolete and unused `.bak` files from source tree (`gl_init.c.bak`, `sdio.c.bak`).

---

## [1.0.3] - Upstream Baseline
- Fixed `mtk_cfg80211_get_station` signature and NULL pointer dereference.
- Clamped `CFG_TX_MAX_PKT_SIZE` to 1408 bytes to avoid SDIO DMA FIFO overflows on `meson-gx-mmc`.
- Suppressed `[wlan]` trace log spam (`DBG_DISABLE_ALL_LOG 1`).
- Added SDIO quiesce unbind service `mt7668-shutdown.service` for reliable warm reboots on FiberHome HG680-FJ.
- Added upstream Bluetooth module blacklist (`blacklist-mt7668-bluetooth.conf`).
