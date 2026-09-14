#!/usr/bin/env bash
# prepare_sdk.sh — Extrae el SDK HCLinux verificado a ~/work/r36sx-hclinux/sdk (workspace WSL)
# El SDK fuente NUNCA se modifica (ADR-002). Prerequisito: verify_sources.sh PASS.
set -euo pipefail
K=/mnt/d/GitHub/KERNEL
SDK="$K/hclinux-2024.02.y.2.tar.gz"
W="$HOME/work/r36sx-hclinux"
DEST="$W/sdk"

SCRIPT_DIR="$(cd "$(dirname "$BASH_SOURCE")" && pwd)"
echo "=== prepare_sdk ==="
# 1. verificar fuentes primero
"$SCRIPT_DIR/verify_sources.sh"

# 2. workspace
mkdir -p "$W/sdk" "$W/build" "$W/cache"

if [ -e "$DEST/hclinux" ] || [ -n "$(ls -A "$DEST" 2>/dev/null)" ]; then
  echo "  [INFO] $DEST ya contiene contenido — no sobrescribir."
  echo "  Para re-extraer: rm -rf $DEST (borra solo el workspace, NO el SDK fuente)"
  exit 0
fi

# 3. inspección ligera del tar antes de extraer (top-level, sanity)
echo "-- inspección top-level del tar --"
tar -tzf "$SDK" | head -20
echo "  total entradas: $(tar -tzf "$SDK" | wc -l)"

# 4. extraer
echo "-- extrayendo a $DEST (puede tardar; 2.0 GiB comprimidos) --"
tar -xzf "$SDK" -C "$DEST"
echo "  extraído OK"

# 5. resumen
echo "-- top-level extraído --"
ls -la "$DEST" | head -25
du -sh "$DEST"
echo "=== prepare_sdk: DONE — continuar Fase 1 (docs/SDK_AUDIT.md) ==="
