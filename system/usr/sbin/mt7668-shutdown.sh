#!/bin/sh
# Unload wlan_mt7668 and unbind SDIO controller before shutdown/reboot
if lsmod | grep -q "^wlan_mt7668"; then
    logger -t mt7668-shutdown "Unloading wlan_mt7668 module..."
    modprobe -r wlan_mt7668 2>/dev/null || true
fi

for d in /sys/bus/platform/drivers/*mmc*/ffe03000* /sys/bus/platform/drivers/*sd*/ffe03000*; do
    if [ -e "$d" ]; then
        dev="${d##*/}"
        driver_dir="$(dirname "$d")"
        logger -t mt7668-shutdown "Unbinding $dev from $driver_dir..."
        echo "$dev" > "$driver_dir/unbind" 2>/dev/null || true
    fi
done
exit 0
