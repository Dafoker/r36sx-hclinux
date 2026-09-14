#!/usr/bin/env bash
# build_baseline.sh — Fase 2: reproducir el build VENDOR sin modificaciones.
# Estado: ESQUELETO — la invocación exacta (defconfig/toolchain/Buildroot) se fija
# por EVIDENCIA en Fase 1 (docs/SDK_AUDIT.md). Este script se completa entonces.
set -euo pipefail
W="$HOME/work/r36sx-hclinux"
SDK="$W/sdk"
OUT="$(cd "$(dirname "$BASH_SOURCE")/.." && pwd)/out/baseline-vendor"
SCRIPT_DIR="$(cd "$(dirname "$BASH_SOURCE")" && pwd)"

echo "=== build_baseline (Fase 2) ==="
"$SCRIPT_DIR/agent_preflight.sh"
"$SCRIPT_DIR/verify_sources.sh"

if [ ! -d "$SDK" ]; then
  echo "FALTA SDK extraído — ejecutar scripts/prepare_sdk.sh primero"; exit 1
fi
echo "  [TODO] Invocación vendor exacta pendiente de Fase 1:"
echo "         - defconfig vendor a identificar en docs/SDK_AUDIT.md"
echo "         - toolchain del SDK a identificar"
echo "         - comando Buildroot vendor a documentar en docs/BUILD.md"
echo "  Este script queda como placeholder honesto: NO compilar con suposiciones."
exit 1
