#!/usr/bin/env python3
"""Create Android boot header v4 boot.img with kernel only (ramdisk in init_boot)."""
import struct, sys

BOOT_MAGIC      = b'ANDROID!'
PAGE_SIZE       = 4096
BOOT_ARGS_SIZE  = 512
BOOT_EXTRA_SIZE = 1024

def page_pad(data):
    r = len(data) % PAGE_SIZE
    return data + b'\x00' * (PAGE_SIZE - r) if r else data

def os_version(major, minor, patch, year, month):
    ver = ((major & 0x7f) << 25) | ((minor & 0x7f) << 18) | ((patch & 0x7f) << 11)
    return ver | (((year - 2000) & 0x7f) << 4) | (month & 0xf)

kernel = open(sys.argv[1], 'rb').read()
output = sys.argv[2]

hdr  = BOOT_MAGIC
hdr += struct.pack('<I', len(kernel))
hdr += struct.pack('<I', 0)                          # ramdisk_size (in init_boot)
hdr += struct.pack('<I', os_version(13,0,0,2024,4))
hdr += struct.pack('<I', 1584)                       # header_size
hdr += struct.pack('<4I', 0, 0, 0, 0)               # reserved[4]
hdr += struct.pack('<I', 4)                          # header_version
hdr += b'\x00' * (BOOT_ARGS_SIZE + BOOT_EXTRA_SIZE)
hdr += struct.pack('<I', 0)                          # signature_size

assert len(hdr) == 1584, f"header size mismatch: {len(hdr)}"

img = page_pad(hdr) + page_pad(kernel)
open(output, 'wb').write(img)
print(f"Created {output}: {len(img)} bytes (kernel={len(kernel)} bytes)")
