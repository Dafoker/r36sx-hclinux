#!/usr/bin/env bash
# make_board_dts.sh — Ensambla r36sx-v26.dts stock-equivalent CON macros del hook SDK.
# dtc del kernel se invoca tras cpp (Buildroot), por eso los vendor DTS usan #define.
# Para validación standalone usamos gcc -E || dtc (mismo pipeline que Buildroot).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$BASH_SOURCE")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
REF="$REPO/boards/r36sx-v26/reference/stock-normalized.dts"
OUT="$REPO/boards/r36sx-v26/dts/r36sx-v26.dts"

[ -f "$REF" ] || { echo "ERROR: falta $REF — ejecutar scripts/extract_stock_dts.sh"; exit 1; }
mkdir -p "$(dirname "$OUT")"

LINUX_SIZE=0xAF91E50     # memory reg size stock
SYSMEM_SIZE=0xB53600     # hcrtos sysmem size stock

{
  echo "/* r36sx-v26.dts — R36SX V2.6 stock-equivalent board DTS (generado por scripts/make_board_dts.sh — NO editar a mano)"
  echo " * Cuerpo: reference/stock-normalized.dts (DTB stock sha 1258f1eb..., roundtrip SEMANTIC PASS)."
  echo " * Macros: sistema del SDK (hc16xx-*.dts vendor usa #define + valores; hook fixup-load-addr"
  echo " * requiere CONFIG_LINUX_MEMORY_OFFSET/HCRTOS_SYSMEM_OFFSET resolubles vía gcc -E)."
  echo " * Valores = mapa stock exacto (docs/DTS_STOCK_MODEL.md): Linux 175.57 MiB @0, sysmem @0xBDA2E50."
  echo " */"
  head -1 "$REF"
  echo ""
  echo "#define CONFIG_MEMORY_SIZE 0x10000000"
  echo "#define CONFIG_LINUX_MEMORY_SIZE ${LINUX_SIZE}"
  echo "#define CONFIG_LINUX_MEMORY_OFFSET 0x0"
  echo "#define CONFIG_FRAMEBUFFER_STATIC_PHYS (CONFIG_LINUX_MEMORY_OFFSET + CONFIG_LINUX_MEMORY_SIZE)"
  echo "#define HCRTOS_SYSMEM_SIZE ${SYSMEM_SIZE}"
  echo "#define HCRTOS_SYSMEM_OFFSET 0xBDA2E50"
  echo ""
  echo "/* Fase D-2b: macros del bootloader (hook fixup-load-addr de apps-bootloader"
  echo " * requiere HCRTOS_BOOTMEM_OFFSET resoluble via gcc -E; formula identica a la"
  echo " * del vendor en hc16xx-*-avp.dtsi; con SYSMEM 0xBDA2E50 resuelve 0x9DA0000"
  echo " * == bootmem reg del DTB stock exacto). */"
  echo "#define HCRTOS_BOOTMEM_SIZE 0x2000000"
  echo "#define HCRTOS_BOOTMEM_OFFSET (((HCRTOS_SYSMEM_OFFSET < 0xc000000 ? HCRTOS_SYSMEM_OFFSET : 0xc000000) - HCRTOS_BOOTMEM_SIZE) & 0xffff0000)"
  echo ""
  tail -n +2 "$REF"
} > "$OUT"

# Fase D-2b: DELTA DELIBERADO — path-prefix "boot" (nuevo layout propio; el
# bootloader lleva fallback dual-path a cubegm/). Documentado + allowlist en el gate.
sed -i 's/path-prefix = "cubegm";/path-prefix = "boot";/' "$OUT"

echo "=== make_board_dts ==="
echo "salida: $OUT ($(wc -l < "$OUT") líneas)"
# validación con el MISMO pipeline que usará Buildroot: cpp (gcc -E) → dtc
TMPD=$(mktemp -d)
gcc -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp -o "$TMPD/pp.dts" "$OUT" 2>/dev/null
dtc -I dts -O dtb -o "$TMPD/test.dtb" "$TMPD/pp.dts" 2>"$TMPD/dtc.err" || { echo "DTC FAIL:"; head -5 "$TMPD/dtc.err"; exit 1; }
echo "gcc -E + dtc: OK ($(stat -c%s "$TMPD/test.dtb") bytes)"
# verificación de equivalencia semántica inmediata contra la referencia
dtc -I dtb -O dts -s -o "$TMPD/test.dts" "$TMPD/test.dtb" 2>/dev/null
if diff -q "$REF" "$TMPD/test.dts" >/dev/null; then
  echo "SEMANTIC vs stock: PASS (idéntico)"
else
  echo "SEMANTIC vs stock: DIFF —"
  { diff "$REF" "$TMPD/test.dts" | head -20 || true; }
fi
echo "=== make_board_dts DONE ==="
