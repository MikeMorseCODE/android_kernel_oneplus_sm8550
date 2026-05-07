# Building the Droidian rootfs for OnePlus 11 (salami)

## Overview

This builds a **native Linux rootfs** (Debian Bookworm + Phosh) for the OnePlus 11.
No Halium/Android container — hardware is accessed via native kernel drivers.

## PC Requirements

- Linux x86_64 host (Ubuntu 22.04+ or Debian Bookworm recommended)
- ~20 GB free disk space
- Internet access (downloads ~2 GB of Debian packages)
- Either **debos** installed natively, or **Docker**

## Install Build Dependencies

### Option A — debos natively (Ubuntu/Debian)

```bash
sudo apt install debos qemu-user-static binfmt-support \
                 dpkg-dev debhelper
```

### Option B — Docker (any Linux)

```bash
docker pull godebos/debos
# no other deps needed
```

## Build Steps

```bash
# 1. Clone the kernel repo (the adaptation lives inside it)
git clone https://github.com/MikeMorseCODE/android_kernel_oneplus_sm8550.git
cd android_kernel_oneplus_sm8550
git checkout claude/droidian-salami

# 2. Build
cd droidian/image

# Native debos:
make

# OR Docker:
make image-docker
```

Output: `droidian/image/droidian-salami-arm64-YYYYMMDD.img.gz`
Build time: ~15–30 min depending on internet speed and CPU.

## Flash to Device

### Prerequisites
- OnePlus 11 with unlocked bootloader
- `fastboot` installed on your PC
- Kernel already flashed via AnyKernel3 zip (`kernel-droidian-salami.zip`)
  from the `releases` branch of this repo

### Step 1 — Flash the kernel

1. Boot to recovery (hold Vol Down + Power)
2. `adb sideload kernel-droidian-salami.zip`

### Step 2 — Flash the rootfs to userdata

```bash
# Decompress
gunzip droidian-salami-arm64-YYYYMMDD.img.gz

# Boot device to fastboot mode (hold Vol Up + Power from off)
# Flash userdata
fastboot flash userdata droidian-salami-arm64-YYYYMMDD.img
fastboot reboot
```

> **Warning:** This erases all data on the device.

### Step 3 — First boot

1. Device reboots into Droidian (takes ~2 min first time)
2. Phosh lock screen should appear
3. PIN: `1234`

### SSH access

```bash
ssh droidian@<device-ip>   # password: 1234
```

Find the device IP via: Settings → Wi-Fi → tap connected network → IP address

## Hardware Status (SM8550 native Linux)

| Feature      | Status           | Notes                                      |
|--------------|------------------|--------------------------------------------|
| Boot         | Expected OK      | systemd boots via our kernel               |
| Display      | Likely OK        | Qualcomm DRM driver in vendor kernel       |
| Touch        | Likely OK        | Vendor driver in kernel                    |
| WiFi         | Likely OK        | QCA6490 via ath11k (in vendor kernel)      |
| Bluetooth    | Partial          | May need vendor firmware                   |
| Audio        | Partial          | ALSA likely; PulseAudio bring-up needed    |
| Modem / SMS  | No               | Needs QRTR + ModemManager bring-up         |
| Camera       | No               | Requires libcamera + V4L2 bring-up         |
| GPS          | No               | Needs bring-up                             |
| Fingerprint  | Unknown          | In-display optical, bring-up needed        |

## Partition Map (SM8550 / UFS)

```
/dev/block/platform/soc/1da0000.ufshc/by-name/
├── boot        ← kernel Image (AnyKernel3 flashes here)
├── init_boot   ← first-stage ramdisk (leave Android's)
├── system      ← Android system (mounted read-only at /android/system)
├── vendor      ← Android vendor blobs (mounted read-only at /android/vendor)
└── userdata    ← Droidian rootfs (flash here)
```

## Troubleshooting

**Black screen after flash:**
- Check kernel was flashed correctly (re-flash via AnyKernel3)
- Try `adb shell` — if you get a shell, display bring-up is the issue

**No adb/SSH access:**
- Enable USB debugging: Settings → About → tap build 7x → Developer Options
- Or connect via USB-C serial console if available

**First boot hangs:**
- systemd journal via: `adb shell journalctl -b` or serial console
