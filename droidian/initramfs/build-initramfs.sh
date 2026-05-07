#!/bin/bash
# Build a minimal ARM64 initramfs and package as init_boot.img
# Run inside debian:bookworm Docker container.
set -euo pipefail

OUTPUT=/output
WORK=/tmp/initramfs

echo "==> Installing build tools..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  cpio gzip \
  android-sdk-libsparse-utils \
  mkbootimg \
  dpkg \
  qemu-user-static

# Get static ARM64 busybox
echo "==> Fetching static ARM64 busybox..."
dpkg --add-architecture arm64
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq busybox-static:arm64

# Build initramfs tree
echo "==> Building initramfs tree..."
rm -rf "$WORK"
mkdir -p "$WORK"/{bin,dev,proc,sys,newroot}

cp /usr/bin/busybox "$WORK/bin/busybox"
chmod +x "$WORK/bin/busybox"

# Symlinks for commands the init script needs
for cmd in sh mount umount switch_root mkdir sleep; do
    ln -s busybox "$WORK/bin/$cmd"
done

cp /scripts/init "$WORK/init"
chmod +x "$WORK/init"

# Pack as cpio.gz
echo "==> Packing initramfs.cpio.gz..."
cd "$WORK"
find . | cpio -H newc -o 2>/dev/null | gzip -9 > "$OUTPUT/initramfs.cpio.gz"

# Package as init_boot.img (Android boot header v4)
echo "==> Building init_boot.img..."
mkbootimg \
  --ramdisk "$OUTPUT/initramfs.cpio.gz" \
  --header_version 4 \
  --os_version 13.0.0 \
  --os_patch_level 2024-04 \
  -o "$OUTPUT/init_boot.img"

ls -lh "$OUTPUT/init_boot.img" "$OUTPUT/initramfs.cpio.gz"
echo "==> Done."
