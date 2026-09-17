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
# Fase 8a: overlay propio minimo -> workspace (el defconfig lo referencia)
OVERLAY_OWN="$R/boards/$BOARD/rootfs-overlay-own"
if [ -d "$OVERLAY_OWN" ]; then
  mkdir -p "$BD/rootfs-overlay-own"
  cp -r "$OVERLAY_OWN"/. "$BD/rootfs-overlay-own/"
fi

# 4. entorno validado (docs/BUILD.md + TOOLCHAIN_PROVENANCE)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export BR2_DL_DIR="$W/cache/dl"
export HOST_EXTRACFLAGS="-fcommon"

mkdir -p "$O" ; cd "$S/buildroot"
make O="$O" BR2_EXTERNAL="$S" "$(basename "$DEF_REPO")" > "$LOG" 2>&1

# Fase 8a: generar ROOTFS PROPIO (Buildroot cpio) si el fragmento lo referencia
if grep -q "rootfs-own.cpio" "$KFRAG" 2>/dev/null; then
  # limpiar target contaminado de overlays anteriores (una sola vez)
  if [ ! -f "$O/.fase8-target-cleaned" ]; then
    rm -rf "$O/target"; find "$O/build" -name .stamp_target_installed -delete 2>/dev/null
    touch "$O/.fase8-target-cleaned"; echo "fase8: target limpio (re-finalize forzado)"
  fi
  # bootstrap: el kernel puede rebuildarse durante rootfs-cpio y necesita que el
  # cpio EXISTA (primera corrida). Placeholder = overlay-own empaquetado; luego
  # se sobreescribe con el cpio real y linux-rebuild re-embebe.
  KOWN="$W/artifacts/$BOARD/rootfs-own.cpio"
  mkdir -p "$(dirname "$KOWN")"
  if [ ! -s "$KOWN" ]; then
    ( cd "$R/boards/$BOARD/rootfs-overlay-own" && find . | cpio -o -H newc -R 0:0 2>/dev/null > "$KOWN" )
    echo "fase8: bootstrap placeholder cpio ($(stat -c%s "$KOWN") B)"
  fi
  make O="$O" BR2_EXTERNAL="$S" rootfs-cpio >> "$LOG" 2>&1 || { echo "ROOTFS-CPIO FAIL — tail:"; tail -15 "$LOG"; exit 1; }
  cp "$O/images/rootfs.cpio" "$KOWN"
  echo "rootfs-own: $KOWN ($(stat -c%s "$KOWN") bytes)"
  export KOWN_FRESH=1
fi
# Fase 8a: forzar re-link del kernel para embeber el cpio recien generado
if [ -n "${KOWN_FRESH:-}" ]; then
  make O="$O" linux-rebuild >> "$LOG" 2>&1 || { echo "LINUX-REBUILD FAIL — tail:"; tail -15 "$LOG"; exit 1; }
fi
make O="$O" -j16 >> "$LOG" 2>&1 || { echo "BUILD FAIL — tail:"; tail -25 "$LOG"; exit 1; }
# nota: 'bootloader.bin not found' en target-post-image = esperado (ADR-008)

echo "=== BUILD OK — artefactos $O/images/ ==="
ls -la "$O/images/" | head -12
echo "log: $LOG"
echo "=== gates: ejecutar audit_toolchain.sh + audit_kernel_patches.sh + compare_dtb_semantics.sh ==="
