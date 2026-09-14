#!/usr/bin/env bash
# verify_artifacts.sh <build-name> — valida artefactos de out/<name>/ contra el contrato.
set -euo pipefail
NAME="${1:?uso: verify_artifacts.sh <nombre-build>}"
OUT="$(cd "$(dirname "$BASH_SOURCE")/.." && pwd)/out/$NAME"
echo "=== verify_artifacts: $NAME ==="
if [ ! -d "$OUT" ]; then echo "  no existe $OUT — nada que verificar"; exit 1; fi
echo "  [TODO] Fases 2+: lista de artefactos obligatorios + hashes + readelf sanity."
exit 1
