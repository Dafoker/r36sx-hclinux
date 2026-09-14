#!/usr/bin/env bash
# collect_artifacts.sh <build-name> — copia artefactos de ~/work a out/<name>/ + hashes.
set -euo pipefail
NAME="${1:?uso: collect_artifacts.sh <nombre-build>}"
W="$HOME/work/r36sx-hclinux"
OUT="$(cd "$(dirname "$BASH_SOURCE")/.." && pwd)/out/$NAME"
mkdir -p "$OUT"
echo "=== collect_artifacts: $NAME → $OUT ==="
echo "  [TODO] Fases 2+: definir artefactos esperados (vmlinux, uImage, DTB, System.map...)"
echo "  Reglas: SHA256 de todo + BUILD_REPORT.md (docs/ai/BUILD_CONTRACT.md). out/ NO va a git."
exit 1
