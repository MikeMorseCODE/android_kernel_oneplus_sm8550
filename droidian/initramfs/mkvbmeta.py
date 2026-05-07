#!/usr/bin/env python3
"""
Create a minimal AVB vbmeta.img with verification and hashtree disabled.
No descriptors, no signatures — just tells the bootloader to skip all checks.

Usage: mkvbmeta.py <output.img>
"""
import struct, sys

AVB_MAGIC            = b'AVB0'
AVB_RELEASE_STRING   = b'avbtool 1.1.0\x00'  # padded to 48 bytes
AVB_RELEASE_STR_SIZE = 48
AVB_RESERVED_SIZE    = 80

# Flags
HASHTREE_DISABLED       = 1
VERIFICATION_DISABLED   = 2

def create_vbmeta(output_path):
    release = AVB_RELEASE_STRING.ljust(AVB_RELEASE_STR_SIZE, b'\x00')

    hdr  = AVB_MAGIC
    hdr += struct.pack('>II', 1, 0)      # required_libavb_version major.minor
    hdr += struct.pack('>QQ', 0, 0)      # authentication_data_block_size, auxiliary_data_block_size
    hdr += struct.pack('>I', 0)          # algorithm_type  (NONE)
    hdr += struct.pack('>QQ', 0, 0)      # hash_offset, hash_size
    hdr += struct.pack('>QQ', 0, 0)      # signature_offset, signature_size
    hdr += struct.pack('>QQ', 0, 0)      # public_key_offset, public_key_size
    hdr += struct.pack('>QQ', 0, 0)      # public_key_metadata_offset, public_key_metadata_size
    hdr += struct.pack('>QQ', 0, 0)      # descriptors_offset, descriptors_size
    hdr += struct.pack('>Q', 0)          # rollback_index
    hdr += struct.pack('>I', HASHTREE_DISABLED | VERIFICATION_DISABLED)  # flags
    hdr += struct.pack('>I', 0)          # rollback_index_location
    hdr += release                       # release_string [48]
    hdr += b'\x00' * AVB_RESERVED_SIZE  # reserved [80]

    assert len(hdr) == 256, f"vbmeta header size mismatch: {len(hdr)}"

    with open(output_path, 'wb') as f:
        f.write(hdr)

    print(f"Created {output_path}: {len(hdr)} bytes (AVB verification disabled)")

if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) == 2 else 'vbmeta.img'
    create_vbmeta(out)
