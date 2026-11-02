#!/bin/bash
set -e

PACKAGE=mt7668-dkms
DEFAULT_VERSION=$(grep -E "^[[:space:]]*PACKAGE_VERSION=" dkms.conf 2>/dev/null | cut -d'"' -f2)
VERSION=${1:-${DEFAULT_VERSION:-2.0.0}}
TARGET_DEB="${PACKAGE}_${VERSION}_all.deb"

BUILD_DIR=/tmp/${PACKAGE}_build
SRC_DIR=${BUILD_DIR}/usr/src/mt7668-${VERSION}

echo "Building Debian package for Release v${VERSION} (${TARGET_DEB})..."

rm -rf ${BUILD_DIR}
mkdir -p ${SRC_DIR}
mkdir -p ${BUILD_DIR}/DEBIAN

# 1. Copy pure driver source code directly
cp -a chips common include mgmt nic os prealloc Makefile Kconfig dkms.conf ${SRC_DIR}/
[ -f CHANGELOG.md ] && cp -a CHANGELOG.md ${SRC_DIR}/
[ -f README.md ] && cp -a README.md ${SRC_DIR}/
sed -i "s/PACKAGE_VERSION=\".*\"/PACKAGE_VERSION=\"${VERSION}\"/" ${SRC_DIR}/dkms.conf
find ${SRC_DIR} -type f \( -name "*.o" -o -name "*.o.d" -o -name "*.cmd" -o -name "*.ko" -o -name "*.mod*" \) -delete

# 2. Copy system integration files (bluetooth blacklist, shutdown service, modprobe template)
cp -a system/* ${BUILD_DIR}/

# 3. Copy Debian package control scripts
cp -a debian/* ${BUILD_DIR}/DEBIAN/
sed -i "s/^Version:.*/Version: ${VERSION}/" ${BUILD_DIR}/DEBIAN/control
sed -i "s/VERSION=\".*\"/VERSION=\"${VERSION}\"/" ${BUILD_DIR}/DEBIAN/postinst ${BUILD_DIR}/DEBIAN/prerm
chmod 755 ${BUILD_DIR}/DEBIAN
chmod 755 ${BUILD_DIR}/DEBIAN/preinst ${BUILD_DIR}/DEBIAN/postinst ${BUILD_DIR}/DEBIAN/prerm

dpkg-deb --build ${BUILD_DIR} ${TARGET_DEB}
rm -rf ${BUILD_DIR}

echo "Package created successfully: ${TARGET_DEB}"
