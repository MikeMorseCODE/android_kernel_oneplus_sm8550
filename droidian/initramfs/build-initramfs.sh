#!/bin/bash
# Build a minimal ARM64 initramfs and package as init_boot.img
# Run inside debian:bookworm Docker container.
set -euo pipefail

OUTPUT=/output
WORK=/tmp/initramfs

echo "==> Installing build tools..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  cpio gzip python3 \
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
for cmd in sh mount umount switch_root mkdir sleep ifconfig telnetd ln blkid grep sed; do
    ln -s busybox "$WORK/bin/$cmd"
done

cp /scripts/init "$WORK/init"
chmod +x "$WORK/init"

# Minimal device nodes
mknod -m 600 "$WORK/dev/console" c 5 1
mknod -m 666 "$WORK/dev/null"    c 1 3
mknod -m 666 "$WORK/dev/zero"    c 1 5

# Pack as cpio.gz
echo "==> Packing initramfs.cpio.gz..."
cd "$WORK"
find . | cpio -H newc -o 2>/dev/null | gzip -9 > "$OUTPUT/initramfs.cpio.gz"

# Package as init_boot.img (Android boot header v4, ramdisk-only)
echo "==> Building init_boot.img..."
python3 /scripts/mkbootimg_v4.py \
  "$OUTPUT/initramfs.cpio.gz" \
  "$OUTPUT/init_boot.img"

ls -lh "$OUTPUT/init_boot.img" "$OUTPUT/initramfs.cpio.gz"
echo "==> Done."
