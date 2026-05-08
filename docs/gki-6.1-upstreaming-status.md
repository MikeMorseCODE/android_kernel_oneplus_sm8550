# GKI 6.1 Upstreaming Status — OnePlus SM8550 (Kalama)

Current base: **android13-5.15** (Linux 5.15.202)  
Target base: **Qualcomm CLO msm-kernel-6.1** (`msm-kernel.lnx.6.1.r1-rel` branch)

> **Why CLO msm-kernel-6.1, not AOSP android14-6.1?**  
> AOSP android14-6.1 is the stripped-down GKI baseline. It does not include any
> Qualcomm SoC drivers (no gcc-kalama, no pinctrl-kalama, etc.). CLO
> msm-kernel-6.1 carries the full Qualcomm platform stack on top of GKI 6.1 and
> uses the same build.config.msm.* infrastructure as this tree.  
> Clone: `https://git.codelinaro.org/clo/la/kernel/msm-kernel`  
> Branch: `msm-kernel.lnx.6.1.r1-rel` (or latest `msm-kernel.lnx.6.1.*`)

---

## Status Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Present in CLO 6.1, no significant changes expected |
| ⚠️  | Present but API or Kconfig name changed — verify before building |
| ❌ | Not in CLO 6.1 kernel source; must be out-of-tree DKLM or dropped |
| 🔍 | Unknown — requires manual comparison against CLO 6.1 tree |

---

## 1. Core Kalama SoC Drivers

All seven clock controllers, pinctrl, interconnect, and UFS PHY were upstreamed
to mainline Linux 6.3 and backported into CLO msm-kernel-6.1. They are present
and buildable with no driver-level changes required, though some internal APIs
were refactored between 5.15 and 6.1.

| Module (.ko) | Config symbol (5.15) | Status | Notes |
|---|---|---|---|
| gcc-kalama.ko | `CONFIG_SM_GCC_KALAMA` | ✅ | In CLO 6.1; mainline uses `SM_GCC_8550` alias |
| camcc-kalama.ko | `CONFIG_SM_CAMCC_KALAMA` | ✅ | |
| dispcc-kalama.ko | `CONFIG_SM_DISPCC_KALAMA` | ✅ | |
| videocc-kalama.ko | `CONFIG_SM_VIDEOCC_KALAMA` | ✅ | |
| gpucc-kalama.ko | `CONFIG_SM_GPUCC_KALAMA` | ✅ | Built from gpucc-kalama.c, not in modules.list but needed |
| tcsrcc-kalama.ko | `CONFIG_SM_TCSRCC_KALAMA` | ✅ | |
| debugcc-kalama.ko | `CONFIG_SM_DEBUGCC_KALAMA` | ✅ | Debug clock; exclude from production builds |
| pinctrl-kalama.ko | `CONFIG_PINCTRL_KALAMA` | ✅ | |
| qnoc-kalama.ko | `CONFIG_INTERCONNECT_QCOM_KALAMA` | ✅ | |
| phy-qcom-ufs-qmp-v4-kalama.ko | `CONFIG_PHY_QCOM_UFS_V4` | ✅ | Variant selected via DT compatible |

### Crow (SM8650) companion drivers — included in same tree

| Module (.ko) | Status | Notes |
|---|---|---|
| gcc-crow.ko | ✅ | Crow is SM8650; same tree as Kalama in CLO |
| dispcc-crow.ko | ✅ | |
| pinctrl-crow.ko | ✅ | |
| qnoc-crow.ko | ✅ | |
| phy-qcom-ufs-qmp-v4-crow.ko | ✅ | |

---

## 2. Core Qualcomm Infrastructure

| Module (.ko) | Config symbol | Status | Notes |
|---|---|---|---|
| clk-rpmh.ko | `CONFIG_QCOM_CLK_RPMH` | ✅ | |
| icc-rpmh.ko | `CONFIG_INTERCONNECT_QCOM_RPMH` | ✅ | |
| icc-bcm-voter.ko | `CONFIG_INTERCONNECT_QCOM_BCM_VOTER` | ✅ | |
| qcom_rpmh.ko | `CONFIG_QCOM_RPMH` | ✅ | |
| qcom_ipcc.ko | `CONFIG_QCOM_MSM_IPCC` | ✅ | |
| qcom_ipc_logging.ko | `CONFIG_IPC_LOGGING` | ✅ | |
| qcom-pdc.ko | `CONFIG_QCOM_PDC` | ✅ | |
| qcom-scm.ko | `CONFIG_QCOM_SCM` | ✅ | |
| qcom_tsens.ko | `CONFIG_QCOM_TSENS` | ✅ | |
| rpmh-regulator.ko | `CONFIG_REGULATOR_RPMH` | ✅ | |
| gdsc-regulator.ko | `CONFIG_QCOM_GDSC_REGULATOR` | ✅ | |
| arm_smmu.ko | `CONFIG_ARM_SMMU` | ✅ | |
| ufs_qcom.ko | `CONFIG_SCSI_UFS_QCOM` | ✅ | |
| ufshcd-crypto-qti.ko | `CONFIG_SCSI_UFS_CRYPTO_QTI` | ✅ | |
| sdhci-msm.ko | `CONFIG_MMC_SDHCI_MSM` | ✅ | |
| qrtr.ko | `CONFIG_QRTR` | ✅ | |
| smem.ko | `CONFIG_QCOM_SMEM` | ✅ | |
| socinfo.ko | `CONFIG_QCOM_SOCINFO` | ✅ | |
| spmi-pmic-arb.ko | `CONFIG_SPMI_MSM_PMIC_ARB` | ✅ | |
| qcom-spmi-pmic.ko | `CONFIG_MFD_SPMI_PMIC` | ✅ | |
| qcom_hwspinlock.ko | `CONFIG_HWSPINLOCK_QCOM` | ✅ | |
| qcom_aoss.ko | `CONFIG_QCOM_AOSS_QMP` | ✅ | |
| cmd-db.ko | `CONFIG_QCOM_COMMAND_DB` | ✅ | |
| mdt_loader.ko | `CONFIG_QCOM_MDT_LOADER` | ✅ | |
| llcc-qcom.ko | `CONFIG_QCOM_LLCC` | ✅ | |
| qcom_dma_heaps.ko | `CONFIG_QCOM_DMABUF_HEAPS` | ✅ | |
| secure_buffer.ko | `CONFIG_QCOM_SECURE_BUFFER` | ✅ | |
| nvmem_qcom-spmi-sdam.ko | `CONFIG_NVMEM_SPMI_SDAM` | ✅ | |
| rtc-pm8xxx.ko | `CONFIG_RTC_DRV_PM8XXX` | ✅ | |
| qcom_hwspinlock.ko | `CONFIG_HWSPINLOCK_QCOM` | ✅ | |
| stub-regulator.ko | `CONFIG_REGULATOR_STUB` | ✅ | |
| pinctrl-msm.ko | `CONFIG_PINCTRL_MSM` | ✅ | Base MSM pinctrl |
| proxy-consumer.ko | `CONFIG_REGULATOR_PROXY_CONSUMER` | ✅ | |
| debug-regulator.ko | `CONFIG_REGULATOR_DEBUG_CONTROL` | ✅ | |
| regmap-spmi.ko | `CONFIG_REGMAP_SPMI` | ✅ | |
| nvme-core.ko / nvme.ko | `CONFIG_BLK_DEV_NVME` | ✅ | |
| cqhci.ko | Built with MMC | ✅ | |

---

## 3. CPU, Scheduling, and Power

| Module (.ko) | Config symbol | Status | Notes |
|---|---|---|---|
| qcom-cpufreq-hw.ko | `CONFIG_ARM_QCOM_CPUFREQ_HW` | ✅ | |
| sched-walt.ko | `CONFIG_SCHED_WALT` | ⚠️ | Kconfig name stable, but WALT internals significantly refactored in 6.1; expect internal symbol changes affecting out-of-tree modules that hook into WALT |
| sched-walt-debug.ko | (from SCHED_WALT) | ⚠️ | May be merged into sched-walt.ko in 6.1; check modules.list in CLO |
| qcom_wdt_core.ko | `CONFIG_QCOM_WDT_CORE` | ✅ | |
| gh_virt_wdt.ko | `CONFIG_GH_VIRT_WATCHDOG` | ⚠️ | See Gunyah section |
| thermal_pause.ko | `CONFIG_QTI_CPU_PAUSE_COOLING_DEVICE` | ✅ | |
| cpu_hotplug.ko | `CONFIG_QTI_CPU_HOTPLUG_COOLING_DEVICE` | ✅ | |
| bwmon.ko | `CONFIG_QCOM_BWMON` | ✅ | |
| qcom-dcvs.ko | `CONFIG_QCOM_DCVS` | ✅ | |
| dcvs_fp.ko | `CONFIG_QCOM_DCVS_FP` | ✅ | |
| c1dcvs_vendor.ko | `CONFIG_QTI_C1DCVS_SCMI_CLIENT` | ✅ | |
| c1dcvs_scmi.ko | (same) | ✅ | |
| bcl_pmic5.ko | `CONFIG_QTI_BCL_PMIC5` | ✅ | |
| qcom-pmu-lib.ko | `CONFIG_QCOM_PMU_LIB` | ✅ | |
| pmu_vendor.ko / pmu_scmi.ko | `CONFIG_QTI_PMU_SCMI_CLIENT` | ✅ | |
| qcom_rimps.ko | `CONFIG_QCOM_RIMPS` | ✅ | |

---

## 4. Debug and Minidump

| Module (.ko) | Config symbol | Status | Notes |
|---|---|---|---|
| minidump.ko | `CONFIG_QCOM_MINIDUMP` | ✅ | Qualcomm-specific; in CLO 6.1 |
| thermal_minidump.ko | `CONFIG_QTI_THERMAL_MINIDUMP` | ✅ | |
| memory_dump_v2.ko | `CONFIG_QCOM_MEMORY_DUMP_V2` | ✅ | |
| msm_rtb.ko | `CONFIG_QCOM_RTB` | ✅ | RAM trace buffer |
| debug_symbol.ko | `CONFIG_QCOM_DEBUG_SYMBOL` | ✅ | |
| dcc_v2.ko | `CONFIG_QCOM_DCC_V2` | ✅ | |
| iommu-logger.ko | `CONFIG_QCOM_IOMMU_DEBUG` | ✅ | |
| qcom_logbuf_vh.ko | `CONFIG_QCOM_LOGBUF_VENDOR_HOOKS` | ✅ | |

---

## 5. Gunyah Hypervisor Stack

The Gunyah virtualization stack underwent significant restructuring between 5.15
and 6.1. The core `gunyah.ko` was accepted into mainline Linux 6.3, but the
Qualcomm-specific `gh_*` companion drivers remain CLO-only. Expect module
interface changes.

| Module (.ko) | Config symbol | Status | Notes |
|---|---|---|---|
| gunyah.ko | `CONFIG_GUNYAH` | ⚠️ | Upstreamed to mainline 6.3; CLO 6.1 carries backport. Core API changed — modules registering with Gunyah must update |
| gh_arm_drv.ko | `CONFIG_GH_ARM64_DRV` | ⚠️ | CLO-only; verify config name unchanged |
| gh_ctrl.ko | `CONFIG_GH_CTRL` | ⚠️ | |
| gh_dbl.ko | `CONFIG_GH_DBL` | ⚠️ | |
| gh_msgq.ko | `CONFIG_GH_MSGQ` | ⚠️ | |
| gh_rm_drv.ko | `CONFIG_GH_RM_DRV` | ⚠️ | |
| gh_virt_wdt.ko | `CONFIG_GH_VIRT_WATCHDOG` | ⚠️ | |
| mem_buf.ko | `CONFIG_QCOM_MEM_BUF` | ⚠️ | Memory buffer sharing across VMs; CLO-specific |
| mem_buf_dev.ko | `CONFIG_QCOM_MEM_BUF_DEV` | ⚠️ | |
| mem_buf_msgq.ko | `CONFIG_QCOM_MEM_BUF_MSGQ` | ⚠️ | |
| mem-offline.ko | `CONFIG_QCOM_MEM_OFFLINE` | ✅ | |
| mem-hooks.ko | `CONFIG_QCOM_MEM_HOOKS` | ✅ | |
| ns.ko | (namespace/secure VM) | 🔍 | Verify in CLO 6.1 modules.list |

---

## 6. Remoteproc / DSP Loaders

| Module (.ko) / feature | Config symbol | Status | Notes |
|---|---|---|---|
| Q6v5 PAS (ADSP/CDSP/MPSS loader) | `CONFIG_QCOM_Q6V5_PAS` | ✅ | |
| qcom_rproc_common.ko | `CONFIG_QCOM_RPROC_COMMON` | ✅ | |
| qcom_sysmon.ko | `CONFIG_QCOM_SYSMON` | ✅ | |
| qcom_pil_info.ko | `CONFIG_QCOM_PIL_INFO` | ✅ | |
| qcom_ramdump.ko | `CONFIG_QCOM_RAMDUMP` | ✅ | |
| qcom_q6v5_common.ko | `CONFIG_QCOM_Q6V5_COMMON` | ✅ | |
| MSM ESOC (external modem) | `CONFIG_QCOM_ESOC` | ✅ | |

---

## 7. USB

| Feature | Config symbol | Status | Notes |
|---|---|---|---|
| DWC3 MSM glue | `CONFIG_USB_DWC3_MSM` | ✅ | |
| SS QMP PHY | `CONFIG_USB_MSM_SSPHY_QMP` | ✅ | |
| eUSB2 PHY | `CONFIG_USB_MSM_EUSB2_PHY` | ✅ | |
| USB BAM | `CONFIG_USB_BAM` | ✅ | |
| USB F_GSI (tethering) | `CONFIG_USB_F_GSI` | ✅ | |
| USB DIAG | `CONFIG_USB_F_DIAG` | ✅ | |
| USB QDSS | `CONFIG_USB_F_QDSS` | ✅ | |

---

## 8. Networking / Modem

| Feature | Config symbol | Status | Notes |
|---|---|---|---|
| MHI bus | `CONFIG_MHI_BUS` | ✅ | |
| QRTR (QMI router) | `CONFIG_QRTR` | ✅ | |
| QRTR over MHI | `CONFIG_QRTR_MHI` | ✅ | |
| QRTR over GLINK/SMD | `CONFIG_QRTR_SMD` | ✅ | |
| QRTR over Gunyah | `CONFIG_QRTR_GUNYAH` | ⚠️ | Depends on Gunyah API |
| GLINK | `CONFIG_QCOM_GLINK` | ✅ | |
| IPA v3 | `CONFIG_IPA3` | ⚠️ | IPA may be renamed `CONFIG_QCOM_IPA` in 6.1; verify Kconfig symbol |
| CNSS2 (WiFi platform) | not in GKI; vendor DKLM | ❌ | Always out-of-tree; loaded from vendor_dlkm |
| QMI helpers | `CONFIG_QCOM_QMI_HELPERS` | ✅ | |

---

## 9. KernelSU + SuSFS

| Feature | Status | Notes |
|---|---|---|
| `CONFIG_KSU=y` | ❌ | The KSU hooks in this 5.15 tree are incompatible with 6.1. KernelSU hooks were redesigned for 6.x kernels. Must integrate a 6.1-compatible KSU fork (e.g., `tiann/KernelSU` >= v0.9.5 which supports 6.1 via kprobe fallback, or `rsuntk/KernelSU` with inline hooks). |
| SuSFS (`CONFIG_KSU_SUSFS*`) | ❌ | Re-integrate after KSU is working. Use SuSFS fork that targets the KSU version chosen for 6.1. |

---

## 10. OEM Modules (sm8550-modules/oplus/)

These are all out-of-tree vendor modules. None will be in CLO 6.1 kernel source.
They must be compiled as external modules against the 6.1 kernel headers.

| Subsystem | Source path | Key kernel APIs used | 6.1 API status | Action |
|---|---|---|---|---|
| Charger v2 | `oplus/kernel/charger/` | `power_supply_register()`, `notifier_chain`, QPNP PMIC APIs, QTI PMIC glink | ✅ Stable | Recompile; verify glink API |
| Haptics (AW8697) | `oplus/kernel/vibrator/` | `input_allocate_device()`, regmap | ✅ Stable | Recompile |
| Touchpanel (Synaptics TCM, Goodix) | `oplus/kernel/touchpanel/` | `input_*`, DRM panel notifier | ⚠️ DRM notifier API changed | Update `drm_panel_notifier_call_chain` calls if present |
| Fingerprint (UFF) | `oplus/kernel/uff_fp_driver/` | `misc_register()`, SPI/I2C, vendor hooks | ⚠️ Vendor hook IDs change between 5.15→6.1 | Update `register_trace_android_vh_*` call sites |
| NFC | `oplus/kernel/nfc/` | `nfc_*`, I2C | ✅ Stable | Recompile |
| Tri-state key | `oplus/kernel/tri_state_key/` | GPIO, `input_*`, extcon | ✅ Stable | Recompile |
| LED (AW210XX) | `oplus/kernel/leds/` | `led_classdev_register()`, I2C | ✅ Stable | Recompile |
| IR (consumer IR) | `oplus/kernel/ir/` | `misc_register()`, UART/SPI | ✅ Stable | Recompile |
| Device info | `oplus/kernel/device_info/` | `proc_create()`, vendor hooks | ⚠️ Vendor hooks | Update hook registrations |
| Secure guard | `oplus/kernel/secureguard/` | Vendor hooks, SELinux hooks | ⚠️ LSM API changed in 6.1 | Audit LSM hook signatures |
| DFR | `oplus/kernel/dfr/` | Vendor hooks, reboot notifier | ⚠️ Vendor hooks | Update hook registrations |
| FW update | `oplus/kernel/fw_update/` | `firmware_request_*` | ✅ Stable | Recompile |
| Thermal (Horae) | (in vendor config) | Thermal framework | ✅ Stable | Recompile |
| Sensors (oplus) | `oplus/sensor/` | IIO, input, SSC | ✅ Stable | Recompile |
| Secure biometrics | `oplus/secure/biometrics/` | TEE/TZ APIs, vendor hooks | ⚠️ Vendor hooks | Update hook registrations |

### Vendor Hook API Change Summary

Android vendor hooks (`register_trace_android_vh_*`) are the most common
break point when moving from 5.15 to 6.1. The hook table changes between
GKI versions. For each module that calls `register_trace_android_vh_*`:

1. Check if the hook symbol still exists in CLO 6.1's `include/trace/hooks/`
2. Verify the function signature matches
3. If the hook was removed, find the replacement or remove the hook call

---

## 11. Config Symbols — Known Changes 5.15 → 6.1

| 5.15 Symbol | 6.1 Status | Action |
|---|---|---|
| `CONFIG_ARM_QCOM_CPUFREQ_HW_DEBUG` | ⚠️ May not exist in GKI 6.1 | Remove from config if `make oldconfig` warns |
| `CONFIG_CPU_IDLE_GOV_QCOM_LPM` | ✅ Stable | Keep |
| `CONFIG_CPU_IDLE_SIMPLE_GOV_QCOM_LPM` | ✅ New in 6.1 | Add for consolidate variant |
| `CONFIG_IPA3` | ⚠️ May rename to `CONFIG_QCOM_IPA` | Check CLO 6.1 Kconfig |
| `CONFIG_GH_PROXY_SCHED` | ⚠️ Verify in CLO 6.1 | Check |
| `CONFIG_GH_SECURE_VM_LOADER` | ⚠️ Verify in CLO 6.1 | Check |
| `CONFIG_GH_TLMM_VM_MEM_ACCESS` | ⚠️ Verify in CLO 6.1 | Check |
| `CONFIG_QCOM_BALANCE_ANON_FILE_RECLAIM` | 🔍 CLO-specific | Verify |
| `CONFIG_MSM_SYSSTATS` | 🔍 | Verify |
| `CONFIG_MSM_GLOBAL_SYNX` | 🔍 | Verify — used by camera |
| `CONFIG_SPMI_MSM_PMIC_ARB_DEBUG` | ⚠️ Debug; may not be GKI 6.1 | Remove if not found |
| `CONFIG_QCOM_ESOC_DEBUG` | ⚠️ Debug | Remove if not found |
| `CONFIG_KSU` + SuSFS | ❌ Incompatible | Re-integrate separately |

---

## 12. Build Config Changes (`build.config.msm.kalama`)

| Setting | 5.15 value | 6.1 value | Notes |
|---|---|---|---|
| `AVB_SIGN_BOOT_IMG_PROP` os_version | `13` | `14` | Android 14 target |
| `AVB_SIGN_BOOT_IMG_PROP` security_patch | `2023-05-05` | Update to current | |
| `BOOT_IMAGE_HEADER_VERSION` | `4` | `4` | Unchanged |
| `SYSTEM_DLKM_MODULES_LIST` path | `android/gki_system_dlkm_modules` | Same | Verify file exists in 6.1 |
| `GKI_SKIP_IF_VERSION_MATCHES` | set in msm.gki | Verify | May change in 6.1 |
| `ABI_DEFINITION` | `android/abi_gki_aarch64.xml` | `android/abi_gki_aarch64_kalama.xml` | CLO 6.1 uses per-SoC ABI files |

---

## Summary Counts

| Category | Count | Status |
|---|---|---|
| Core Kalama SoC drivers | 10 | ✅ All upstreamed |
| Core Qualcomm infrastructure | 35 | ✅ All in CLO 6.1 |
| CPU/power management | 15 | ✅ / ⚠️ WALT needs verify |
| Debug/minidump | 8 | ✅ All in CLO 6.1 |
| Gunyah hypervisor | 12 | ⚠️ API changed |
| Remoteproc/DSP | 7 | ✅ All in CLO 6.1 |
| USB | 7 | ✅ All in CLO 6.1 |
| Networking/modem | 8 | ✅ / ⚠️ IPA name check |
| KernelSU + SuSFS | — | ❌ Re-integrate |
| OEM OnePlus modules | 15 subsystems | ❌ All out-of-tree, recompile needed |

**Of the 107 modules in `modules.list.msm.kalama`:**
- ~85 are expected to be present in CLO 6.1 with no source changes
- ~10 need verification (mostly Gunyah-related)
- ~12 OEM modules require recompilation against 6.1 headers with minor fixes

---

## Next Steps

1. Clone CLO msm-kernel-6.1 (`bash gki-6.1-port/setup-6.1-tree.sh`)
2. Copy ported configs from `gki-6.1-port/` into the cloned tree
3. Run `make ARCH=arm64 O=out kalama_gki_defconfig && make ARCH=arm64 O=out oldconfig` to catch any removed/renamed Kconfigs
4. Fix any `warning: symbol value 'm' invalid for CONFIG_*` entries
5. Build: `BUILD_CONFIG=build.config.msm.kalama VARIANT=gki ./tools/bazel/build.sh`
6. For OEM modules: compile externally with `make -C <6.1-tree> M=<module-path> modules`
7. Integrate KernelSU for 6.1 separately (see tiann/KernelSU for supported versions)
