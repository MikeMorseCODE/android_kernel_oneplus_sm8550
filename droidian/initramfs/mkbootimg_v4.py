#!/usr/bin/env python3
"""
Create an Android boot image v4 init_boot.img (ramdisk only, no kernel).
Usage: mkbootimg_v4.py <ramdisk.cpio.gz> <output.img>
"""
import struct, sys

BOOT_MAGIC      = b'ANDROID!'
PAGE_SIZE       = 4096
BOOT_ARGS_SIZE  = 512
BOOT_EXTRA_SIZE = 1024

def page_pad(data):
    r = len(data) % PAGE_SIZE
    return data + b'\x00' * (PAGE_SIZE - r) if r else data

def os_version(major, minor, patch, year, month):
    ver   = ((major & 0x7f) << 25) | ((minor & 0x7f) << 18) | ((patch & 0x7f) << 11)
    patch_level = (((year - 2000) & 0x7f) << 4) | (month & 0xf)
    return ver | patch_level

def create(ramdisk_path, output_path):
    ramdisk = open(ramdisk_path, 'rb').read()

    # boot_img_hdr_v4 (packed, 1580 bytes without signature_size)
    hdr  = BOOT_MAGIC
    hdr += struct.pack('<I', 0)                     # kernel_size  (0 = no kernel)
    hdr += struct.pack('<I', len(ramdisk))           # ramdisk_size
    hdr += struct.pack('<I', os_version(13,0,0,2024,4))  # os_version
    hdr += struct.pack('<I', 1580)                  # header_size
    hdr += struct.pack('<4I', 0, 0, 0, 0)           # reserved[4]
    hdr += struct.pack('<I', 4)                     # header_version
    hdr += b'\x00' * (BOOT_ARGS_SIZE + BOOT_EXTRA_SIZE)  # cmdline
    hdr += struct.pack('<I', 0)                     # signature_size

    assert len(hdr) == 1580 + 4, f"header size mismatch: {len(hdr)}"

    img = page_pad(hdr) + page_pad(ramdisk)

    with open(output_path, 'wb') as f:
        f.write(img)

    print(f"Created {output_path}: {len(img)} bytes "
          f"(ramdisk={len(ramdisk)} bytes)")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <ramdisk.cpio.gz> <output.img>")
        sys.exit(1)
    create(sys.argv[1], sys.argv[2])
