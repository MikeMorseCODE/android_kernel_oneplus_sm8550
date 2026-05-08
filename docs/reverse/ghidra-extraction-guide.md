# Ghidra Reverse Engineering Guide — OnePlus 11 Kernel Modules

This guide covers extracting proprietary kernel modules from a running OnePlus 11
and using Ghidra to understand the driver protocols well enough to write GPL
reimplementations.

## Prerequisites

- OnePlus 11 with USB debugging enabled
- ADB root access (via `adb root` or Magisk/KSU)
- Ghidra >= 10.3 with the GhidraKernelHeaders script installed
- `aarch64-linux-gnu-objdump` for quick symbol inspection

---

## Step 1 — Extract Modules from Device

```bash
mkdir -p extracted/{vendor,dlkm}_modules

# Pull all vendor DLKM modules
adb root
adb shell find /vendor/lib/modules /vendor_dlkm/lib/modules \
    -name "*.ko" 2>/dev/null | sort | tee extracted/module_list.txt

# Bulk pull
adb pull /vendor/lib/modules/     extracted/vendor_modules/
adb pull /vendor_dlkm/lib/modules/ extracted/dlkm_modules/

# Key targets for reverse engineering
TARGET_MODULES=(
    oplus_chg.ko          # or oplus_charger.ko
    oplus_chg_v2.ko
    aw8697_haptic.ko
    aw210xx.ko
    uff_fingerprint.ko
    oplus_bsp_*.ko
)
```

Quick symbol check before Ghidra:
```bash
for ko in extracted/dlkm_modules/*.ko; do
    echo "=== $(basename $ko) ==="
    aarch64-linux-gnu-objdump -t "$ko" 2>/dev/null | \
        grep -E "\.text.*[0-9a-f]{8} [A-Z]" | head -20
done
```

---

## Step 2 — Ghidra Import

1. Start Ghidra, create project `oneplus11-modules`
2. **File → Import File** → select `.ko` file
3. Format: **ELF** (auto-detected), Language: **AARCH64:LE:64:v8A**
4. **Yes** to analyze immediately
5. Analyzer settings — enable:
   - Demangler GNU
   - Stack Analysis
   - Function Start Search
   - (do NOT enable "Non-Returning Functions" — causes false positives in drivers)

---

## Step 3 — VOOCPHY / SC8517 Fast Charge Analysis (`oplus_chg_v2.ko`)

### Goal
Document the I2C register map and charging state machine so we can write a
GPL SC8517 driver compatible with the standard `power_supply` framework.

### Methodology

```
Ghidra CodeBrowser → Symbol Tree → Functions
```

1. Search for `voocphy_init` or `sc8517_probe`:
   - Press `S` → type `voocphy` or `sc8517`
   - Or: **Search → Program Text** → search `sc8517`

2. In `probe()`: look for `i2c_smbus_read_byte_data` / `i2c_smbus_write_byte_data`
   calls with constant register address arguments — those are your register map.

3. Build register map table:
   ```
   Reg 0x00 — Chip ID (read: expect 0x09 for SC8517)
   Reg 0x01 — Status
   Reg 0x02 — Control
   ... (fill from Ghidra decompiler)
   ```

4. Find the main FSM loop — look for a work_struct or kthread that polls status
   registers and transitions between states:
   ```
   IDLE → HANDSHAKE → NEGOTIATE → CHARGING → DONE/ERROR
   ```

5. Document each state's entry/exit condition and the I2C writes performed.

### Output
`docs/reverse/voocphy-protocol.md` — see template below.

---

## Step 4 — UFF Fingerprint Analysis (`uff_fingerprint.ko`)

### Goal
Identify how the kernel driver communicates with the TrustZone fingerprint TA
so we know whether a GPL reimplementation is feasible or if the TA blob is the
hard blocker.

### Methodology

1. Search for `qseecom` or `tee_client`:
   ```
   Search → Program Text → "qseecom"
   ```
   - If `qseecom_start_app` appears: driver uses legacy QSEECOM API
   - If `tee_client_open_session` appears: driver uses standard OP-TEE client API
   - If only SMC calls: fully custom TEE interface

2. For QSEECOM path:
   - Find `qseecom_start_app(handle, "qfp_daemon", buf_size)` → note the TA name string
   - Find `qseecom_send_cmd` calls → note the command buffer format:
     ```c
     struct uff_send_cmd {
         u32 cmd_id;
         /* ... */
     };
     ```
   - List all `cmd_id` values used → these are the fingerprint commands
     (enroll_start, enroll_capture, auth_start, auth_match, delete, etc.)

3. For OP-TEE path:
   - Find the UUID used in `tee_client_open_session`
   - Document the `TEEC_InvokeCommand` command IDs

### Key question to answer
> "Is the TrustZone TA blob shipped with the stock ROM, or loaded from a
> separate partition?"

Check on device:
```bash
adb shell find /vendor/firmware /odm/firmware /system/etc/firmware \
    -name "*.mdt" -o -name "*.b00" | grep -i "fprint\|biometric\|uff"
```

If the TA firmware (`.mdt`/`.b00` files) is present → driver reimplementation
is feasible, the TA blob just needs to be copied to the correct path.

If absent → the TA is baked into TrustZone and not replaceable without JTAG.

---

## Step 5 — AW8697 Register Map (fallback if Awinic source is incomplete)

The AW8697 datasheet is available from Awinic's website. The driver is
straightforward I2C with a firmware waveform upload. Ghidra analysis here
is mostly to verify the waveform file format used on OnePlus 11 specifically
(different devices use different `.bin` files).

```bash
# Pull haptics firmware from device
adb shell find /vendor/firmware -name "*aw8697*" -o -name "*haptic*"
adb pull /vendor/firmware/aw8697_haptic.bin extracted/
```

Inspect the binary header to understand waveform format:
```bash
xxd extracted/aw8697_haptic.bin | head -20
```

---

## Protocol Document Template

Create `docs/reverse/<module>-protocol.md` with this structure:

```markdown
# <Module> Protocol — Reverse Engineered

## Environment
- Device: OnePlus 11 (CPH2449)
- Module: <name>.ko (5.15.202, from stock OxygenOS <version>)
- Tool: Ghidra <version>

## Hardware Interface
- Bus: I2C / SPI / SMC
- Address: 0x<XX>
- Compatible string: "<vendor>,<chip>"

## Register Map (I2C)
| Register | Name | R/W | Description |
|---|---|---|---|
| 0x00 | CHIP_ID | R | Expected: 0xXX |

## State Machine
[ diagram or description ]

## Commands / Protocol
[ for TEE: command IDs and buffer formats ]

## Open Questions
[ things that couldn't be determined from static analysis ]

## GPL Reimplementation Notes
[ what can be cleanly reimplemented vs what requires the proprietary TA ]
```
