#!/usr/bin/env bash
# build_kernel.sh <board> — Fase 4B+: build kernel con board propia del repo.
# Flujo reproducible: repo (fuente de verdad) -> workspace SDK -> Buildroot.
# Uso: ./scripts/build_kernel.sh r36sx-v26
set -euo pipefail
BOARD="${1:?uso: build_kernel.sh r36sx-v26}"
W="$HOME/work/r36sx-hclinux"
S="$W/sdk/hclinux-2024.02.y.2/hclinux"
R="$(cd "$(dirname "$BASH_SOURCE")/.." && pwd)"
O="$W/build/$BOARD"
LOG="$W/logs/${BOARD}-build_$(date +%Y%m%d_%H%M%S).log"

# 1. validar insumos del repo
DTS_REPO="$R/boards/$BOARD/dts/$BOARD.dts"
DEF_REPO="$R/configs/buildroot/hichip_hc16xx_${BOARD//-/_}_defconfig"
[ -f "$DTS_REPO" ] || { echo "ERROR: falta $DTS_REPO"; exit 1; }
[ -f "$DEF_REPO" ] || { echo "ERROR: falta $DEF_REPO"; exit 1; }
[ -d "$S" ] || { echo "ERROR: SDK no extraído — scripts/prepare_sdk.sh"; exit 1; }

# 2. regenerar DTS desde la referencia auditada (no confiar en copias)
"$R/scripts/make_board_dts.sh"

# 3. sincronizar board files repo -> workspace SDK (board propia; vendor intacto)
BD="$S/board/hichip/hc16xx/${BOARD//-/_}"
mkdir -p "$BD/dts" "$BD/kernel"
cp "$DTS_REPO" "$BD/dts/$BOARD.dts"
cp "$DEF_REPO" "$S/configs/$(basename "$DEF_REPO")"
# fragmento de kernel config (board-specific deltas, p.ej. CONFIG_CHECK_ADC) -> workspace
KFRAG="$R/boards/$BOARD/kernel/$BOARD.config.fragment"
[ -f "$KFRAG" ] && cp "$KFRAG" "$BD/kernel/$BOARD.config.fragment"
# rootfs-overlay de la board (p.ej. etc/init.d/S99app para lanzar la UI) -> workspace
OVERLAY_SRC="$R/boards/$BOARD/rootfs-overlay"
if [ -d "$OVERLAY_SRC" ]; then
  mkdir -p "$BD/rootfs-overlay"
  cp -r "$OVERLAY_SRC"/. "$BD/rootfs-overlay/"
fi
# generar initramfs del desarrollador (rootfs-dev.cpio) desde el overlay, si el fragmento lo referencia
KDEV="$W/artifacts/$BOARD/rootfs-dev.cpio"
if [ -d "$OVERLAY_SRC" ] && grep -q "rootfs-dev.cpio" "$KFRAG" 2>/dev/null; then
  mkdir -p "$(dirname "$KDEV")"
  ( cd "$OVERLAY_SRC" && find . | cpio -o -H newc -R 0:0 2>/dev/null > "$KDEV" )
  echo "initramfs dev: $KDEV ($(stat -c%s "$KDEV") bytes)"
fi

# 4. entorno validado (docs/BUILD.md + TOOLCHAIN_PROVENANCE)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export BR2_DL_DIR="$W/cache/dl"
export HOST_EXTRACFLAGS="-fcommon"

mkdir -p "$O" ; cd "$S/buildroot"
make O="$O" BR2_EXTERNAL="$S" "$(basename "$DEF_REPO")" > "$LOG" 2>&1
make O="$O" -j16 >> "$LOG" 2>&1 || { echo "BUILD FAIL — tail:"; tail -25 "$LOG"; exit 1; }
# nota: 'bootloader.bin not found' en target-post-image = esperado (ADR-008)

echo "=== BUILD OK — artefactos $O/images/ ==="
ls -la "$O/images/" | head -12
echo "log: $LOG"
echo "=== gates: ejecutar audit_toolchain.sh + audit_kernel_patches.sh + compare_dtb_semantics.sh ==="
