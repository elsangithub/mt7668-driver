#!/usr/bin/env bash
# ==============================================================================
# Single Source of Truth (SSOT) Version Synchronization Script
# MediaTek MT7668 Linux Wi-Fi Driver Package
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 2.0.2"
    exit 1
fi

NEW_VERSION="$1"

# Validate semver format (X.Y.Z)
if [[ ! "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must follow semantic versioning (X.Y.Z), got '$NEW_VERSION'"
    exit 1
fi

echo "=== Synchronizing package metadata to version v${NEW_VERSION} ==="

in_place_sed() {
    local expr="$1"
    local file="$2"
    local tmp
    tmp=$(mktemp)
    sed -E "$expr" "$file" > "$tmp"
    cat "$tmp" > "$file"
    rm -f "$tmp"
}

# 1. dkms.conf
if [ -f "dkms.conf" ]; then
    in_place_sed "s/PACKAGE_VERSION=\"[0-9]+\.[0-9]+\.[0-9]+\"/PACKAGE_VERSION=\"${NEW_VERSION}\"/" dkms.conf
    echo "  [OK] dkms.conf"
fi

# 2. debian/control
if [ -f "debian/control" ]; then
    in_place_sed "s/Version: [0-9]+\.[0-9]+\.[0-9]+/Version: ${NEW_VERSION}/" debian/control
    echo "  [OK] debian/control"
fi

# 3. debian/postinst
if [ -f "debian/postinst" ]; then
    in_place_sed "s/VERSION=\"[0-9]+\.[0-9]+\.[0-9]+\"/VERSION=\"${NEW_VERSION}\"/" debian/postinst
    echo "  [OK] debian/postinst"
fi

# 4. debian/prerm
if [ -f "debian/prerm" ]; then
    in_place_sed "s/VERSION=\"[0-9]+\.[0-9]+\.[0-9]+\"/VERSION=\"${NEW_VERSION}\"/" debian/prerm
    echo "  [OK] debian/prerm"
fi

# 5. build-deb.sh
if [ -f "build-deb.sh" ]; then
    in_place_sed "s/DEFAULT_VERSION:-[0-9]+\.[0-9]+\.[0-9]+/DEFAULT_VERSION:-${NEW_VERSION}/" build-deb.sh
    echo "  [OK] build-deb.sh"
fi

# 6. system/etc/modprobe.d/mt7668.conf
if [ -f "system/etc/modprobe.d/mt7668.conf" ]; then
    in_place_sed "s/\(v[0-9]+\.[0-9]+\.[0-9]+/(v${NEW_VERSION}/" system/etc/modprobe.d/mt7668.conf
    echo "  [OK] system/etc/modprobe.d/mt7668.conf"
fi

# 7. README.md & README.id.md
for readme in README.md README.id.md; do
    if [ -f "$readme" ]; then
        # Update badge
        in_place_sed "s/release-v[0-9]+\.[0-9]+\.[0-9]+-blue\.svg/release-v${NEW_VERSION}-blue.svg/g" "$readme"
        # Update download links
        in_place_sed "s/download\/v[0-9]+\.[0-9]+\.[0-9]+\/mt7668-dkms_[0-9]+\.[0-9]+\.[0-9]+_all\.deb/download\/v${NEW_VERSION}\/mt7668-dkms_${NEW_VERSION}_all.deb/g" "$readme"
        in_place_sed "s/mt7668-dkms_[0-9]+\.[0-9]+\.[0-9]+_all\.deb/mt7668-dkms_${NEW_VERSION}_all.deb/g" "$readme"
        in_place_sed "s/\(v[0-9]+\.[0-9]+\.[0-9]+\)/(v${NEW_VERSION})/g" "$readme"
        echo "  [OK] $readme"
    fi
done

echo "=== Version synchronization to v${NEW_VERSION} complete! ==="
