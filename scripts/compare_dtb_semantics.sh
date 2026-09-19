#!/usr/bin/env bash
# compare_dtb_semantics.sh — Gate Fase 4B: DTB SEMANTIC MODEL PASS/FAIL
# Compara el DTB generado por nuestro DTS (r36sx-v26) contra la referencia stock
# normalizada, mediante decompile -s de ambos. Las diferencias intencionales
# permitidas viven en la ALLOWLIST de abajo (objetivo: 0).
# Uso: ./scripts/compare_dtb_semantics.sh [nuestro-dtb] [referencia-dts]
set -euo pipefail

MINE="${1:-$HOME/work/r36sx-hclinux/build/r36sx-v26/images/dtb.bin}"
REF="${2:-$(cd "$(dirname "$BASH_SOURCE")/.." && pwd)/boards/r36sx-v26/reference/stock-normalized.dts}"
TMP=$(mktemp -d)

# ALLOWLIST (regex; una por línea; "#" = comentario). Objetivo: VACÍA.
ALLOWLIST=(
  "# (vacía — stock-equivalence estricta; añadir SOLO con evidencia y ADR)"
  "# Fase D-2b (ADR-014 implícito del caso cubegm): path-prefix cubegm->boot —"
  "# delta DELIBERADO: nuevo layout /boot/ con fallback dual-path en el bootloader"
  "# propio. Docs: docs/experiments/2026-09-19_cubegm-minimal-boot-contract.md"
  '^[<>][[:space:]]*path-prefix = .(cubegm|boot).;$'
)

[ -f "$MINE" ] || { echo "ERROR: no existe $MINE (compilar primero)"; exit 1; }
[ -f "$REF" ]  || { echo "ERROR: no existe $REF"; exit 1; }

dtc -I dtb -O dts -s -o "$TMP/mine.dts" "$MINE" 2>/dev/null
cp "$REF" "$TMP/ref.dts"

echo "=== compare_dtb_semantics ==="
echo "mine: $MINE ($(wc -l < "$TMP/mine.dts") líneas decompiladas)"
echo "ref : $REF ($(wc -l < "$TMP/ref.dts") líneas)"

diff "$TMP/ref.dts" "$TMP/mine.dts" > "$TMP/all.diff" || true
TOTAL=$(grep -cE "^[<>]" "$TMP/all.diff" || true)
echo "líneas de diferencia brutas: $TOTAL"

if [ "$TOTAL" -eq 0 ]; then
  echo "DTB SEMANTIC MODEL: PASS (idéntico al stock — allowlist no necesitada)"
  exit 0
fi

# filtrar allowlist
grep -E "^[<>]" "$TMP/all.diff" > "$TMP/lines.txt" || true
BLOCKED=0
while IFS= read -r line; do
  case "$line" in \#*|"") continue;; esac
  if ! grep -qE "$line" "$TMP/lines.txt"; then continue; fi
done < <(printf '%s\n' "${ALLOWLIST[@]}")

# cada línea de diff debe matchear alguna regex de la allowlist para PASS
UNLISTED=0
while IFS= read -r dl; do
  ok=0
  for a in "${ALLOWLIST[@]}"; do
    case "$a" in \#*|"") continue;; esac
    echo "$dl" | grep -qE "$a" && ok=1 && break
  done
  [ "$ok" -eq 0 ] && { echo "  [UNLISTED] $dl"; UNLISTED=$((UNLISTED+1)); }
done < "$TMP/lines.txt"

echo "diferencias fuera de allowlist: $UNLISTED"
if [ "$UNLISTED" -eq 0 ]; then
  echo "DTB SEMANTIC MODEL: PASS (todas las diferencias en allowlist documentada)"
else
  echo "--- primeras 20 diferencias ---"
  head -40 "$TMP/all.diff"
  echo "DTB SEMANTIC MODEL: FAIL — $UNLISTED diferencias fuera de allowlist"
  exit 1
fi
