#!/bin/bash
# Droidian rootfs builder for OnePlus 11 (salami)
# Runs inside debian:bookworm Docker container — no debos/fakemachine needed.
set -euo pipefail

DEVICE=salami
DATE=${DATE:-$(date +%Y%m%d)}
IMAGE="droidian-${DEVICE}-arm64-${DATE}.img"
SIZE_MB=7680   # 7.5 GiB
ROOTFS=/tmp/rootfs
OUTPUT=/output

echo "==> Installing build tools..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  debootstrap qemu-user-static rsync e2fsprogs \
  systemd-container binfmt-support

# Register arm64 binfmt handler so we can chroot into arm64 rootfs
update-binfmts --enable qemu-aarch64 2>/dev/null || true

echo "==> Stage 1 debootstrap (arm64 Bookworm)..."
debootstrap --arch=arm64 --foreign \
  --components=main,contrib,non-free,non-free-firmware \
  bookworm "$ROOTFS" https://deb.debian.org/debian

echo "==> Copying qemu-aarch64-static for chroot..."
cp /usr/bin/qemu-aarch64-static "$ROOTFS/usr/bin/"

echo "==> Stage 2 debootstrap (inside chroot)..."
chroot "$ROOTFS" /debootstrap/debootstrap --second-stage

echo "==> Configuring apt..."
cat > "$ROOTFS/etc/apt/sources.list" <<'EOF'
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
EOF

echo "==> Installing packages..."
mount -t proc  proc    "$ROOTFS/proc"
mount -t sysfs sysfs   "$ROOTFS/sys"
mount --bind   /dev    "$ROOTFS/dev"
mount --bind   /dev/pts "$ROOTFS/dev/pts"

chroot "$ROOTFS" apt-get update -qq
DEBIAN_FRONTEND=noninteractive chroot "$ROOTFS" apt-get install -y -q \
  systemd systemd-sysv dbus udev \
  bash vim-tiny wget curl iproute2 iputils-ping net-tools \
  network-manager wpasupplicant \
  openssh-server \
  bluez bluez-tools \
  alsa-utils \
  modemmanager libqmi-utils libmbim-utils \
  sudo locales tzdata kmod \
  phosh phoc 2>/dev/null || \
DEBIAN_FRONTEND=noninteractive chroot "$ROOTFS" apt-get install -y -q \
  systemd systemd-sysv dbus udev \
  bash vim-tiny wget curl iproute2 iputils-ping net-tools \
  network-manager wpasupplicant \
  openssh-server \
  bluez bluez-tools \
  alsa-utils \
  modemmanager libqmi-utils libmbim-utils \
  sudo locales tzdata kmod

echo "==> Configuring system..."
echo "salami" > "$ROOTFS/etc/hostname"
printf '127.0.0.1\tlocalhost\n127.0.1.1\tsalami\n' > "$ROOTFS/etc/hosts"
ln -sf /usr/share/zoneinfo/America/New_York "$ROOTFS/etc/localtime"
echo "en_US.UTF-8 UTF-8" >> "$ROOTFS/etc/locale.gen"
chroot "$ROOTFS" locale-gen

echo "==> Creating user 'droidian' (password: 1234)..."
chroot "$ROOTFS" useradd -m -s /bin/bash -u 1000 -U droidian 2>/dev/null || true
echo "droidian:1234" | chroot "$ROOTFS" chpasswd
chroot "$ROOTFS" usermod -aG sudo,audio,video,input,bluetooth,netdev droidian 2>/dev/null || true
echo "droidian ALL=(ALL) NOPASSWD: ALL" > "$ROOTFS/etc/sudoers.d/droidian"

echo "==> Configuring SSH..."
sed -i 's|#PermitRootLogin.*|PermitRootLogin yes|' "$ROOTFS/etc/ssh/sshd_config"
sed -i 's|#PasswordAuthentication.*|PasswordAuthentication yes|' "$ROOTFS/etc/ssh/sshd_config"

echo "==> Copying device adaptation files..."
rsync -a /adaptation/ "$ROOTFS/"
chmod +x "$ROOTFS/usr/sbin/usb-gadget-setup" \
         "$ROOTFS/usr/sbin/usb-gadget-teardown" 2>/dev/null || true
mkdir -p "$ROOTFS/android/system" "$ROOTFS/android/vendor"

echo "==> Configuring WiFi (if credentials provided)..."
if [ -n "${WIFI_SSID:-}" ] && [ -n "${WIFI_PSK:-}" ]; then
    mkdir -p "$ROOTFS/etc/NetworkManager/system-connections"
    cat > "$ROOTFS/etc/NetworkManager/system-connections/wifi.nmconnection" <<EOF
[connection]
id=${WIFI_SSID}
uuid=$(cat /proc/sys/kernel/random/uuid)
type=wifi
autoconnect=true
autoconnect-priority=100

[wifi]
mode=infrastructure
ssid=${WIFI_SSID}

[wifi-security]
auth-alg=open
key-mgmt=wpa-psk
psk=${WIFI_PSK}

[ipv4]
method=auto

[ipv6]
addr-gen-mode=default
method=auto
EOF
    chmod 600 "$ROOTFS/etc/NetworkManager/system-connections/wifi.nmconnection"
    echo "    WiFi profile written for SSID: ${WIFI_SSID}"
fi

echo "==> Enabling services..."
for svc in NetworkManager ssh bluetooth ModemManager usb-gadget-rndis; do
  chroot "$ROOTFS" systemctl enable "$svc" 2>/dev/null || true
done

echo "==> Cleaning up..."
DEBIAN_FRONTEND=noninteractive chroot "$ROOTFS" apt-get clean
rm -f "$ROOTFS/usr/bin/qemu-aarch64-static"
umount "$ROOTFS/dev/pts" "$ROOTFS/dev" "$ROOTFS/sys" "$ROOTFS/proc" 2>/dev/null || true

echo "==> Creating and populating ${SIZE_MB}M ext4 image (no loop device needed)..."
fallocate -l "${SIZE_MB}M" "$OUTPUT/$IMAGE"
mkfs.ext4 -L droidian -m 0 -d "$ROOTFS" "$OUTPUT/$IMAGE"

echo "==> Compressing..."
gzip -9 "$OUTPUT/$IMAGE"

echo ""
echo "Done: $OUTPUT/${IMAGE}.gz"
