#!/usr/bin/env bash
# verify_sources.sh — Verifica SHA256 de las fuentes vendor contra manifests/SOURCES.sha256
# Read-only. No modifica /mnt/d/GitHub/KERNEL (ADR-002).
set -euo pipefail
K=/mnt/d/GitHub/KERNEL
MANIFEST="$(cd "$(dirname "$BASH_SOURCE")/.." && pwd)/manifests/SOURCES.sha256"
[ -f "$MANIFEST" ] || { echo "FALTA $MANIFEST"; exit 1; }
cd "$K"
echo "=== verify_sources: contraste SHA256 vs manifest ==="
FAIL=0
while read -r sha file; do
  [ -z "${sha:-}" ] && continue
  case "$file" in \#*) continue;; esac
  if [ ! -f "$file" ]; then echo "  [FAIL] ausente: $file"; FAIL=$((FAIL+1)); continue; fi
  if echo "$sha  $file" | sha256sum -c --quiet 2>/dev/null; then
    echo "  [PASS] $file"
  else
    echo "  [FAIL] hash mismatch: $file (esperado $sha) — fuente alterada o corrupta"
    FAIL=$((FAIL+1))
  fi
done < <(grep -E '^[0-9a-f]{64}  ' "$MANIFEST")
echo "=== RESULT: FAIL=$FAIL ==="
[ "$FAIL" -eq 0 ] && echo "verify_sources: PASS" || { echo "verify_sources: FAIL — NO continuar (fuentes no confiables)"; exit 1; }
