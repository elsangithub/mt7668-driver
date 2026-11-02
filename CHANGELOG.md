# Changelog

All notable changes to the **MediaTek MT7668 Linux DKMS Driver** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.0.0] - 2026-11-02

### 🚀 Major Architectural Leap (Elsangithub Production Release)
This release represents a major evolutionary jump for the MediaTek MT7668 SDIO Wi-Fi driver, bringing it to full functional and packaging parity with the acclaimed `mt7663-driver` ecosystem. The headline capability is the porting and introduction of **Dedicated AP Mode (`ap_mode` / `ap0`)**, turning ZTE ZXV10 B860H V5 (Amlogic S905X2 / Meson G12A) TV boxes into enterprise-grade 5 GHz 802.11ac Hotspot Routers and Wi-Fi Repeaters.

### Added
- **Dedicated AP Mode & Modular Kernel Parameter (`ap_mode`)**:
  - Implemented dynamic runtime module parameter `ap_mode` in `os/linux/gl_init.c`:
    - `ap_mode=0` (Default): Pure client station mode (`wlan0` only). Zero overhead, maximum stability for general desktop/server deployments.
    - `ap_mode=1`: Dedicated SoftAP mode. Automatically registers and instantiates the virtual interface `ap0` alongside `wlan0` at driver probe time. Ideal for companion routing packages like `mt7663-router-webui` and standalone `hostapd`.
    - `ap_mode=2`: Dual AP mode (dual AP virtual interfaces).
    - `ap_mode=3`: P2P + AP concurrent mode.
  - Added build-time override `CFG_DRIVER_INITIAL_RUNNING_MODE` in `Makefile`.
  - Added configuration template file `/etc/modprobe.d/mt7668.conf`.
- **Modern Debian Packaging Architecture (`debian/`)**:
  - Transitioned from temporary inline packaging to standard, versioned `debian/` directory structure (`control`, `preinst`, `postinst`, `prerm`).
  - Added intelligent DKMS self-healing in `postinst` (detects and cleans legacy versions, rebuilds `modpost` if host glibc toolchain mismatches).
  - Included kernel header availability checks in `preinst`.
  - Upgraded build automation in `build-deb.sh` to package `mt7668-dkms_2.0.0_all.deb`.
- **Bilingual Documentation**:
  - Created Indonesian documentation (`README.id.md`) for Indonesian STB and OpenWrt/Armbian communities.
  - Rewrote English documentation (`README.md`) with comprehensive AP mode guides, architecture diagrams, and hardware notes.

### Changed
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
- Added SDIO quiesce unbind service `mt7668-shutdown.service` for reliable warm reboots on ZTE B860H V5.
- Added upstream Bluetooth module blacklist (`blacklist-mt7668-bluetooth.conf`).
