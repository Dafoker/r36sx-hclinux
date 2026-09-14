#!/usr/bin/env bash
# build_baseline.sh — Fase 2: reproducir el build VENDOR d3100_v20 sin modificaciones.
# Basado en evidencia: manual §16.1 + reporte FINAL_BASELINE_REPORT previo del usuario (lecciones aplicadas).
# Reglas: SDK inmutable (copia de trabajo ya extraída), PATH sanitizado (sin rutas Windows),
#         cache dl reutilizada del usuario (1.3G, ~/KERNEL_BUILD/hclinux/buildroot/dl),
#         output separado, log completo, artefactos hasheados.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$BASH_SOURCE")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
W="$HOME/work/r36sx-hclinux"
SDK="$W/sdk/hclinux-2024.02.y.2/hclinux"
OUT="$W/build/d3100-v20-baseline"
LOGDIR="$W/logs"
DL="$W/cache/dl"                      # cache persistente del proyecto (se rellena desde KERNEL_BUILD)
LOG="$LOGDIR/build_baseline_d3100v20_$(date +%Y%m%d_%H%M%S).log"
DEFCONFIG="hichip_hc16xx_db_d3100_v20_defconfig"

mkdir -p "$OUT" "$LOGDIR" "$DL"
exec > >(tee -a "$LOG") 2>&1

echo "=== build_baseline d3100_v20 — $(date) ==="
echo "log: $LOG"

# 0. Prerequisitos
"$SCRIPT_DIR/agent_preflight.sh" | tail -3
"$SCRIPT_DIR/verify_sources.sh" | tail -2
if [ ! -d "$SDK" ]; then echo "FALTA SDK extraído — ejecutar scripts/prepare_sdk.sh"; exit 1; fi

# 1. PATH sanitizado (evidencia: error 2 del reporte previo — WSL hereda rutas Windows con espacios)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
echo "--- PATH sanitizado: $PATH"

# 2. Cache dl: reutilizar la del usuario (1.3G) vía symlink por paquete (no copia)
echo "--- preparando cache dl (reutilización ~/KERNEL_BUILD/hclinux/buildroot/dl) ---"
SRC_DL="$HOME/KERNEL_BUILD/hclinux/buildroot/dl"
if [ -d "$SRC_DL" ]; then
  for d in "$SRC_DL"/*; do
    n="$(basename "$d")"
    [ -e "$DL/$n" ] || ln -s "$d" "$DL/$n"
  done
  echo "  cache enlazada: $(ls "$DL" | wc -l) entradas -> $DL"
else
  echo "  [WARN] sin cache previa — Buildroot descargará on-line"
fi
export BR2_DL_DIR="$DL"

# 3. Toolchain Codescape Linux: el SDK lo descarga de dl/ (tarball presente en cache 2018.09-02)
echo "--- toolchain: Codescape mips-mti-linux-gnu 2018.09-02 (gcc 6.3.0), desde dl/ ---"

# 4. Config del build (defconfig vendor SIN modificaciones)
cd "$SDK/buildroot"
echo "--- make defconfig: $DEFCONFIG ---"
make O="$OUT" BR2_EXTERNAL="$SDK" "$DEFCONFIG"
echo "--- .config generado: $OUT/.config ---"
grep -E "BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE|BR2_TOOLCHAIN_EXTERNAL_PREFIX|BR2_PACKAGE_AVP=|BR2_TARGET_HCBOOT" "$OUT/.config" | head -8

# 5. BUILD (kernel-only por defecto? NO: defconfig vendor completo. -j según nproc)
JOBS=$(nproc)
echo "=== make -j$JOBS (comenzando $(date +%H:%M:%S)) ==="
time make O="$OUT" -j"$JOBS" 2>&1 | tee -a "$LOG" | tail -40
echo "=== BUILD TERMINADO $(date) ==="

# 6. Inventario de artefactos + hashes
IM="$OUT/images"
echo "=== ARTEFACTOS: $IM ==="
ls -la "$IM" 2>/dev/null
echo "--- SHA256 ---"
(cd "$IM" 2>/dev/null && sha256sum * 2>/dev/null) | tee "$LOGDIR/artifacts_d3100v20_baseline.sha256"
echo "=== build_baseline DONE — verificar artefactos con scripts/verify_artifacts.sh ==="
