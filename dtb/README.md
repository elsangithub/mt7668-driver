# Device Tree Blobs (DTB) for Amlogic TV Boxes

This directory provides pre-compiled and tested Device Tree Blobs (`.dtb`) and sources (`.dts`) specifically modified to resolve hardware quirks on certain Amlogic TV box platforms running Linux / Armbian.

---

## 1. ZTE ZXV10 B860H V5 (`meson-g12a-b860h-v5.dtb`)

### The Problem
On the ZTE ZXV10 B860H V5 (Amlogic S905X2 / Meson G12A), the power supplies to the MediaTek MT7668 wireless module (`VDDAO_3V3` and `VDDAO_1V8`) are fixed **Always-On** hardware rails. 
In the stock Armbian DTB, the SDIO host controller attempts a 1.8V UHS voltage switch (`sd-uhs-sdr104`). Once the MT7668 switches to 1.8V, subsequent software warm reboots (`reboot`) cause the host to boot back up at 3.3V while the chip remains locked in 1.8V mode. This triggers:
```text
meson-gx-mmc ffe03000.mmc: no support for card's volts
mmc2: error -22 whilst initialising SDIO card
```
and Wi-Fi (`wlan0`) completely disappears on every reboot unless the power cable is physically disconnected (Cold Boot).

### The Solution
Adding `no-1-8-v;` to the SDIO host controller node (`mmc@ffe03000`) tells the Linux MMC core to strictly maintain standard **3.3V High-Speed (50 MHz)** signaling. Because the chip never transitions to 1.8V:
- Zero voltage mismatch occurs across reboots.
- Wi-Fi survives software reboots (`reboot`) 100% reliably.
- SDIO bus speed remains rock-solid at up to 200 Mbps (25 MB/s).

### Installation Instructions (Armbian)
1. Backup your existing DTB:
   ```bash
   sudo cp /boot/dtb/amlogic/meson-g12a-b860h-v5.dtb /boot/dtb/amlogic/meson-g12a-b860h-v5.dtb.bak
   ```
2. Copy the patched DTB:
   ```bash
   sudo cp dtb/amlogic/meson-g12a-b860h-v5.dtb /boot/dtb/amlogic/meson-g12a-b860h-v5.dtb
   sudo sync
   ```
3. Perform **one Cold Boot** (unplug DC power cable for 10 seconds, then plug back in) to reset any residual 1.8V chip state.
4. From now on, normal software reboots (`sudo reboot`) will keep Wi-Fi working seamlessly!
