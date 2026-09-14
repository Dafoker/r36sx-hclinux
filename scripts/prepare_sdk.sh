#!/usr/bin/env bash
# prepare_sdk.sh — Extrae el SDK HCLinux verificado a ~/work/r36sx-hclinux/sdk (workspace WSL)
# El SDK fuente NUNCA se modifica (ADR-002). Prerequisito: verify_sources.sh PASS.
set -euo pipefail
K=/mnt/d/GitHub/KERNEL
SDK="$K/hclinux-2024.02.y.2.tar.gz"
W="$HOME/work/r36sx-hclinux"
DEST="$W/sdk"
LOGDIR="$W/logs"
mkdir -p "$LOGDIR"
LOG="$LOGDIR/prepare_sdk_$(date +%Y%m%d_%H%M%S).log"

SCRIPT_DIR="$(cd "$(dirname "$BASH_SOURCE")" && pwd)"
exec > >(tee -a "$LOG") 2>&1

echo "=== prepare_sdk ($(date)) log=$LOG ==="
# 1. verificar fuentes primero
"$SCRIPT_DIR/verify_sources.sh"

# 2. workspace
mkdir -p "$W/sdk" "$W/build" "$W/cache" "$LOGDIR"

if [ -n "$(ls -A "$DEST" 2>/dev/null)" ]; then
  echo "  [INFO] $DEST ya contiene contenido — no sobrescribir (ADR-002)."
  echo "  Para re-extraer: borrar SOLO $DEST (workspace, nunca el SDK fuente)."
  exit 0
fi

# 3. inspección del tar SIN pipes propensos a SIGPIPE: listar completo a archivo
echo "-- listando tar completo a $W/cache/tar-listing.txt (1-2 min) --"
tar -tzf "$SDK" > "$W/cache/tar-listing.txt"
ENTRIES=$(wc -l < "$W/cache/tar-listing.txt")
echo "  entradas totales: $ENTRIES"
echo "-- primeras 20 entradas --"
head -20 "$W/cache/tar-listing.txt"

# 4. extraer (al directorio de destino — el tar contiene hclinux-2024.02.y.2/)
echo "-- extrayendo a $DEST ($(date +%H:%M:%S); puede tardar varios minutos) --"
tar -xzf "$SDK" -C "$DEST"
echo "  extracción OK ($(date +%H:%M:%S))"

# 5. resumen
echo "-- top-level extraído --"
ls -la "$DEST/"
du -sh "$DEST"
echo "=== prepare_sdk: DONE — continuar Fase 1 (docs/SDK_AUDIT.md) ==="
