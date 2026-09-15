#!/usr/bin/env bash
# extract_stock_dts.sh — DTB stock externo → DTS normalizado reproducible (Fase 4A)
# El DTB propietario NO se versiona; este script lo decompila desde su ubicación externa.
# Read-only sobre la fuente. WSL-only. Idempotente.
# Uso: ./scripts/extract_stock_dts.sh [ruta-dtb-stock] [destino-dts]
#   default dtb: /mnt/g/cubegm/dtb.bin  (SD G: — read-only)
#   default destino: boards/r36sx-v26/reference/stock-normalized.dts
set -euo pipefail

DTB="${1:-/mnt/g/cubegm/dtb.bin}"
SCRIPT_DIR="$(cd "$(dirname "$BASH_SOURCE")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST="${2:-$REPO/boards/r36sx-v26/reference/stock-normalized.dts}"
EXPECT_SHA="1258f1eba809e43540c581b815c87815540a9e5897a4e8584363ab7de5cc27bb"

[ -r "$DTB" ] || { echo "ERROR: DTB stock no accesible: $DTB"; exit 1; }

echo "=== extract_stock_dts ==="
echo "fuente: $DTB"
SHA=$(sha256sum "$DTB" | cut -d' ' -f1)
echo "sha256: $SHA"
if [ "$SHA" != "$EXPECT_SHA" ]; then
  echo "ERROR: hash no coincide con el manifest ($EXPECT_SHA)."
  echo "Si el DTB cambió intencionalmente, actualizar manifests/r36sx-v26-stock.sha256 y el hash aquí."
  exit 1
fi
echo "hash VERIFIED contra manifests/r36sx-v26-stock.sha256"

command -v dtc >/dev/null || { echo "ERROR: dtc no instalado"; exit 1; }
echo "dtc: $(dtc --version)"

mkdir -p "$(dirname "$DEST")"
# decompile sorted (normalización) — warnings de dtc sobre el árbol vendor son esperados
dtc -I dtb -O dts -s -o "$DEST" "$DTB" 2>/dev/null
echo "DTS normalizado: $DEST ($(wc -l < "$DEST") líneas)"

# roundtrip semántico (gate)
RT_DT="$DEST.roundtrip.dtb"; RT_DTS="$DEST.roundtrip.dts"
dtc -I dts -O dtb -o "$RT_DT" "$DEST" 2>/dev/null
dtc -I dtb -O dts -s -o "$RT_DTS" "$RT_DT" 2>/dev/null
if diff -q "$DEST" "$RT_DTS" >/dev/null; then
  echo "ROUNDTRIP: SEMANTIC PASS"
  rm -f "$RT_DT" "$RT_DTS"
else
  echo "ROUNDTRIP: FAIL — revisar"; diff "$DEST" "$RT_DTS" | head -5; exit 1
fi
echo "=== extract_stock_dts DONE ==="
