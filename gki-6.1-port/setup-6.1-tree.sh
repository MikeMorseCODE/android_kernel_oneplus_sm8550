#!/usr/bin/env bash
# setup-6.1-tree.sh
#
# Clones Qualcomm CLO msm-kernel-6.1 and applies the ported Kalama configs
# from this directory into the cloned tree.
#
# Usage:
#   bash gki-6.1-port/setup-6.1-tree.sh [--dest <path>]
#
# Default destination: ../msm-kernel-6.1  (sibling of this repo)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DEST="${1:-}"
if [[ -z "${DEST}" ]]; then
    DEST="${REPO_ROOT}/../msm-kernel-6.1"
fi

CLO_REMOTE="https://git.codelinaro.org/clo/la/kernel/msm-kernel"
# Use the latest 6.1 release tag; update this when a newer tag is available.
# Check available branches/tags: git ls-remote --tags ${CLO_REMOTE} | grep "6.1"
CLO_BRANCH="msm-kernel.lnx.6.1.r1-rel"

echo "=== CLO msm-kernel-6.1 setup ==="
echo "Remote : ${CLO_REMOTE}"
echo "Branch : ${CLO_BRANCH}"
echo "Dest   : ${DEST}"
echo ""

# --- Clone ---
if [[ -d "${DEST}/.git" ]]; then
    echo "[skip] Destination already a git repo: ${DEST}"
    echo "       If you want a fresh clone, remove it first."
else
    echo "[1/3] Cloning (shallow, depth=1 for speed)..."
    git clone --depth=1 -b "${CLO_BRANCH}" "${CLO_REMOTE}" "${DEST}"
fi

# --- Copy ported configs ---
echo "[2/3] Copying ported configs into ${DEST}..."

install -Dv "${SCRIPT_DIR}/arch/arm64/configs/vendor/kalama_GKI.config" \
    "${DEST}/arch/arm64/configs/vendor/kalama_GKI.config"

install -Dv "${SCRIPT_DIR}/arch/arm64/configs/vendor/kalama_consolidate.config" \
    "${DEST}/arch/arm64/configs/vendor/kalama_consolidate.config"

install -Dv "${SCRIPT_DIR}/arch/arm64/configs/vendor/oplus/kalama_GKI.config" \
    "${DEST}/arch/arm64/configs/vendor/oplus/kalama_GKI.config"

install -Dv "${SCRIPT_DIR}/arch/arm64/configs/kalama_lu_gki.fragment" \
    "${DEST}/arch/arm64/configs/kalama_lu_gki.fragment"

install -Dv "${SCRIPT_DIR}/arch/arm64/configs/kalama_le_gki.fragment" \
    "${DEST}/arch/arm64/configs/kalama_le_gki.fragment"

install -Dv "${SCRIPT_DIR}/build.config.msm.kalama" \
    "${DEST}/build.config.msm.kalama"

echo "[3/3] Verifying configs against 6.1 Kconfig..."
cd "${DEST}"

# Create a merged defconfig and run oldconfig to catch removed/renamed symbols.
# This requires the kernel build tools (make, cross-compiler) to be on PATH.
if command -v make &>/dev/null && [[ -n "${CROSS_COMPILE:-}" || -n "${CLANG_TRIPLE:-}" ]]; then
    echo "      Running make oldconfig to check for unknown symbols..."
    make ARCH=arm64 O=out kalama_gki_defconfig 2>&1 | grep -E "WARNING|ERROR|warning|error" || true
    make ARCH=arm64 O=out oldconfig 2>&1 | grep -E "WARNING|ERROR|warning|error" || true
    echo "      Done. Review any warnings above — those are symbols to fix."
else
    echo "      Skipping oldconfig check (CROSS_COMPILE not set or make not found)."
    echo "      Run manually: make ARCH=arm64 O=out kalama_gki_defconfig && make ARCH=arm64 O=out oldconfig"
fi

echo ""
echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "  1. cd ${DEST}"
echo "  2. Set up toolchain (clang from AOSP prebuilts or llvm-project):"
echo "       export PATH=\$AOSP/prebuilts/clang/host/linux-x86/clang-r487747c/bin:\$PATH"
echo "       export CROSS_COMPILE=aarch64-linux-gnu-"
echo "  3. Build GKI variant:"
echo "       BUILD_CONFIG=build.config.msm.kalama VARIANT=gki ./tools/bazel/build.sh"
echo "     Or with the shell build script:"
echo "       BUILD_CONFIG=build.config.msm.kalama VARIANT=gki build/build.sh"
echo "  4. Build OEM out-of-tree modules against the built 6.1 tree:"
echo "       make -C ${DEST} M=\$OPLUS_MODULES_PATH modules"
echo "  5. For KernelSU on 6.1, integrate tiann/KernelSU >= v0.9.5 into the tree"
echo "     before building, then restore CONFIG_KSU=y in vendor/kalama_GKI.config"
echo ""
echo "See docs/gki-6.1-upstreaming-status.md for full driver status."
