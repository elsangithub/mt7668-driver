# Device Tree Blobs (DTB) for Amlogic TV Boxes

This directory provides pre-compiled and tested Device Tree Blobs (`.dtb`) and sources (`.dts`) specifically modified to resolve hardware quirks on certain Amlogic TV box platforms running Linux / Armbian.

---

## 1. ZTE ZXV10 B860H V5 DTB Variants

| DTB Variant | Target Kernel / Environment | SDIO Wi-Fi & Unbind Script Fix | TrustZone Memory Shield (48 MB) | Recommended Use Case |
| :--- | :--- | :---: | :---: | :--- |
| **`meson-g12a-b860h-v5.dtb`** | Linux 6.x (MicroSD / USB Boot) | Yes (`no-1-8-v` + SDR104) | 32 MB (Standard) | Standard Armbian booting from external MicroSD or USB drive. Resolves Wi-Fi warm reboot disappearing bug with shutdown unbind script. |
| **`meson-g12a-b860h-v5-v1.dtb`** | Linux 6.12+ (Internal eMMC / Direct Boot) | Yes (`no-1-8-v` + SDR104 100 MHz) | **48 MB (`no-map`)** | **Recommended for Internal eMMC Booting & Linux 6.12+.** Retains full SDR104 100 MHz performance while preventing TrustZone memory collision (`Synchronous External Abort 0x96000010` / `SError 0xbf000000`). |

---

## 2. Hardware Quirks & Solutions

### A. Wi-Fi Warm Reboot Mismatch (Fixed in All Variants)
On the ZTE ZXV10 B860H V5 (Amlogic S905X2 / Meson G12A), the power supplies to the MediaTek MT7668 wireless module (`VDDAO_3V3` and `VDDAO_1V8`) are fixed **Always-On** hardware rails. 
In the stock Armbian DTB, the SDIO host controller attempts a 1.8V UHS voltage switch (`sd-uhs-sdr104`). Once the MT7668 switches to 1.8V, subsequent software warm reboots (`reboot`) cause the host to boot back up at 3.3V while the chip remains locked in 1.8V mode. This triggers:
```text
meson-gx-mmc ffe03000.mmc: no support for card's volts
mmc2: error -22 whilst initialising SDIO card
```
and Wi-Fi (`wlan0`) completely disappears on every reboot unless the power cable is physically disconnected (Cold Boot).

Adding `no-1-8-v;` to the SDIO host controller node (`mmc@ffe03000`) tells the Linux MMC core to strictly maintain standard **3.3V High-Speed (50 MHz)** signaling:
- Zero voltage mismatch occurs across reboots.
- Wi-Fi survives software reboots (`reboot`) 100% reliably.
- SDIO bus speed remains rock-solid at up to 200 Mbps (25 MB/s).

### B. TrustZone Collision on Internal eMMC Boot (Fixed in `meson-g12a-b860h-v5-v1.dtb`)
ZTE factory firmware reserves TrustZone DRM memory (`tee.img`) up to `0x08000000` (128 MB). Stock DTBs only declare 32 MB (`secmon@5300000` up to `0x072FFFFF` / 115 MB), causing Linux 6.12+ kernel to allocate initramfs or slab objects in reserved physical RAM (`0x075ee000` - `0x07677000`), triggering hardware AXI bus security aborts:
```text
Internal error: synchronous external abort: 0000000096000010 [#1] SMP
Kernel panic - not syncing: Asynchronous SError Interrupt
```
Expanding `secmon@5300000` to **48 MB (`0x03000000`)** with `no-map` shields physical RAM from `0x05300000` to `0x08300000`, guaranteeing 100% stable booting directly from internal eMMC.

---

## 3. Installation Instructions (Armbian)

### For MicroSD / USB Boot:
```bash
# Backup existing DTB
sudo cp /boot/dtb/amlogic/meson-g12a-b860h-v5.dtb /boot/dtb/amlogic/meson-g12a-b860h-v5.dtb.bak

# Copy standard DTB
sudo cp dtb/amlogic/meson-g12a-b860h-v5.dtb /boot/dtb/amlogic/meson-g12a-b860h-v5.dtb
sudo sync
```

### For Internal eMMC Booting (or Linux 6.12+):
```bash
# Copy V1 DTB with TrustZone Memory Shield
sudo cp dtb/amlogic/meson-g12a-b860h-v5-v1.dtb /boot/dtb/amlogic/meson-g12a-b860h-v5.dtb
sudo sync
```

Perform **one Cold Boot** (unplug DC power cable for 10 seconds, then plug back in) to reset any residual 1.8V chip state. Normal software reboots (`sudo reboot`) will keep Wi-Fi working seamlessly!
