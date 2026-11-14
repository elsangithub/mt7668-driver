# Changelog

All notable changes to the **MediaTek MT7668 Linux DKMS Driver** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.0.2] - 2026-11-10

### 🚀 Amlogic Warm Reboot Fix, Systemd Shutdown Script & ZTE B860H V5 Support
This release introduces critical fixes for warm reboot deadlocks on Amlogic TV boxes with Always-On power rails (specifically ZTE ZXV10 B860H V5), resolves a silent failure in `mt7668-shutdown.service`, and includes an officially tested DTB.

### Added
- **Official ZTE ZXV10 B860H V5 DTB Suite (`meson-g12a-b860h-v5.dtb` & `meson-g12a-b860h-v5-v1.dtb`)**:
  - Added standard pre-compiled binary DTB, source DTS, and patch (`no-1-8-v;`) resolving the hardware Always-On power rail warm reboot lockup on ZTE B860H V5.
  - Added specialized eMMC DTB (`meson-g12a-b860h-v5-v1.dtb`) with 48 MB TrustZone Memory Shield (`secmon@5300000` `no-map`) preventing kernel panic (`Synchronous External Abort 0x96000010`) on direct internal eMMC boot under Linux 6.12+, while maintaining full SDR104 100 MHz SDIO performance.
  - Added bilingual installation guides (`dtb/README.md` and `dtb/README.id.md`) for Armbian users.
- **Dedicated Shutdown Helper Script (`/usr/sbin/mt7668-shutdown.sh`)**:
  - Implemented standalone POSIX shell script installed with `755` permissions to cleanly unload `wlan_mt7668` and unbind the SDIO host controller (`ffe03000*`) before reboot or shutdown targets.
- **Single Source of Truth (SSOT) Version Synchronization (`sync-version.sh`)**:
  - Added automation script to ensure atomic, verified synchronization of version numbers and release asset links across all package metadata and documentation.

### Fixed
- **Systemd Inline Syntax Silent Failure in `mt7668-shutdown.service`**:
  - Fixed a syntax bug where systemd interpreted `${d##*/}` as an internal variable evaluating to an empty string `""`, causing unbind commands to be rejected by the kernel. Now cleanly invokes `/usr/sbin/mt7668-shutdown.sh`.
- **Amlogic Always-On Power Rail Warm Reboot Deadlock (`error -22`)**:
  - Identified root cause of `meson-gx-mmc: no support for card's volts` and `Card stuck being busy!`: Always-On rails keep MT7668 locked in 1.8V mode while SoC reboots at 3.3V. Enforcing 3.3V signaling via `no-1-8-v;` in the B860H V5 DTB eliminates voltage mismatch and guarantees 100% stable warm reboots.

---

## [2.0.1] - 2026-11-07

### 🛠️ Multi-Kernel Stability & UsrMerge Compliance Release
This maintenance and stability release ports critical data-plane and multi-kernel fixes from the upstream MT7663 ecosystem, resolving kernel oops on station association across LTS kernels and enforcing modern UsrMerge filesystem compliance.

### Added
- **Full Co-existence & Driver Isolation with MT7663**:
  - Renamed SDIO driver instance in `os/linux/hif/sdio/sdio.c` from generic `"wlan"` to `"wlan_mt7668"` to prevent kernel `driver_register` `-EBUSY` collision when both MT7663 and MT7668 modules are loaded.
  - Isolated kernel `/proc/net/` debug and MET trace directories to `wlan_mt7668` (`os/linux/gl_proc.c`) and `wlan_mt7668_met` (`os/linux/gl_kal.c`), eliminating kernel `proc_register` "already registered" warnings and call traces during multi-driver boot.
  - Blacklisted obsolete distro-provided MT7668 driver (`wlan_mt76x8_sdio`) in `blacklist-mt7668-bluetooth.conf` and `debian/postinst` to prevent `udev-worker` from binding competing legacy drivers on Ophub Armbian kernels.
  - Namespaced system integration files to `99-mt7668-throughput.conf`, `99-mt7668-performance.rules`, and `mt7668-irq-tune.sh` to allow seamless parallel installation with `mt7663-dkms` on universal OS images.
  - Added module active guard (`if lsmod | grep -q "^wlan_mt7668"; then ... fi`) to `mt7668-shutdown.service` so unbind operations only execute when MT7668 hardware is active.
- **Global Station Record Lookup Fallback (`cnmGetAnyStaRecByAddress`)**:
  - Implemented `cnmGetAnyStaRecByAddress()` in `mgmt/cnm_mem.c` and declared in `include/mgmt/cnm_mem.h` to look up active station records across all BSS indices.
  - Added fallback in `nicEventAddPkeyDone` (`nic/nic_cmd_event.c` and `nic/nic_rx.c`) preventing BSS index mismatches on virtual interface `ap0` from dropping pairwise key completion notifications.
- **WPA2/WPA3 Data-Plane Queue Unlocking (`fgIsTxKeyReady`)**:
  - Explicitly unlocked the transmission queue (`fgIsTxKeyReady = TRUE`) and updated station queues (`qmUpdateStaRec`) immediately upon pairwise key installation in `os/linux/gl_p2p_cfg80211.c` (`mtk_p2p_cfg80211_add_key`).
  - Resolves connection loops where client stations authenticate successfully but experience zero data throughput ("connected without internet").
- **Universal SDIO Controller Device Matching (`ffe03000*`)**:
  - Updated `mt7668-shutdown.service` to discover and unbind `/sys/bus/platform/drivers/meson-gx-mmc/ffe03000*` dynamically using wildcard matching, with `TimeoutStartSec=2`.
  - Ensures clean SDIO reset and reliable warm reboots on FiberHome HG680-FJ regardless of whether the device label is `.sd` or `.mmc`.

### Fixed
- **Multi-Kernel Station Update Compatibility (`kalP2PGOStationUpdate`)**:
  - Added preprocessor guard `#if (CFG80211_VERSION_CODE >= KERNEL_VERSION(6, 14, 0))` in `os/linux/gl_p2p_kal.c`.
  - Passes `struct net_device *` (`aprRoleHandler`) on Linux kernels < 6.14 (including Linux 5.10 LTS and 6.12 LTS Ophub), and `struct wireless_dev *` (`ieee80211_ptr`) on Linux 6.14+.
  - Fixes fatal kernel oops and `main_thread` crash when stations associate or disconnect.
- **Accurate Linux Mainline 6.12+ `cfg80211_cac_event` Boundary**:
  - Corrected macro guard in `os/linux/gl_p2p_kal.c` to `#if KERNEL_VERSION(6, 12, 0) <= CFG80211_VERSION_CODE`.
  - Resolves compilation error (`too many arguments to function ‘cfg80211_cac_event’`) on intermediate Linux kernels (such as Ubuntu 6.8 LTS).
- **Key Index Bitmask Authenticator Check (`wlanoidSetAddKey`)**:
  - Explicitly permitted `IS_AUTHENTICATOR` (`BIT(28)`) in `common/wlan_oid.c` key index exception validation.
- **UsrMerge Packaging Compliance (`build-deb.sh`)**:
  - Relocated firmware installation destination from `./lib/firmware/` to `./usr/lib/firmware/` in Debian package build process.
  - Prevents `dpkg -x` manual extractions from breaking the modern Debian/Armbian `/lib -> usr/lib` symlink and causing boot panics.

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
