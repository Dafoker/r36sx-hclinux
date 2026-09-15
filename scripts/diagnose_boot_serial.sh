#!/usr/bin/env bash
# diagnose_boot_serial.sh — Genera DTB de DIAGNÓSTICO serial-only para capturar dmesg del boot parcial.
# ADR-011: NO es baseline; SOLO herramienta de diagnóstico. Requiere cable USB-TTL al UART de la consola.
# Despliegue: copiar vmlinux.uImage (Fase 4B) + este dtb.bin a la SD SOLO para el test, luego rollback.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$BASH_SOURCE")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
REF="$REPO/boards/r36sx-v26/reference/stock-normalized.dts"
OUT_DIR="$REPO/boards/r36sx-v26/dts/diagnostic-serial"
OUT="$OUT_DIR/r36sx-v26-diagnostic-serial.dts"
UART_REG="18818600"     # serial0 (stdout-path stock). Alternativas: 18818300/18818800/18818900
UART_IRQ="17"           # hc_uart@18818600 interrupts = <0x11> = 17
CONSOLE="ttyS0,115200n8"

[ -f "$REF" ] || { echo "ERROR: falta $REF"; exit 1; }
mkdir -p "$OUT_DIR"

# Copiamos la referencia y aplicamos las 2 desviaciones de diagnóstico sobre el DTS preprocesado.
# NOTA: trabajamos sobre el DTS crudo (gcc -E lo expande luego); aquí editamos texto.
{
  echo "/* r36sx-v26-diagnostic-serial.dts — DIAGNÓSTICO SOLO (ADR-011). NO-BASELINE."
  echo " * Derivado de reference/stock-normalized.dts con UN hc_uart habilitado + console=ttyS0."
  echo " * NO desplegar como baseline; solo captura de dmesg vía USB-TTL. Generado por diagnose_boot_serial.sh."
  echo " */"
  head -1 "$REF"
  echo "#define CONFIG_MEMORY_SIZE 0x10000000"
  echo "#define CONFIG_LINUX_MEMORY_SIZE 0xAF91E50"
  echo "#define CONFIG_LINUX_MEMORY_OFFSET 0x0"
  echo "#define CONFIG_FRAMEBUFFER_STATIC_PHYS (CONFIG_LINUX_MEMORY_OFFSET + CONFIG_LINUX_MEMORY_SIZE)"
  echo "#define HCRTOS_SYSMEM_SIZE 0xB53600"
  echo "#define HCRTOS_SYSMEM_OFFSET 0xBDA2E50"
  echo ""
  tail -n +2 "$REF"
} > "$OUT"

# Aplicar desviaciones de diagnóstico (con python para evitar sed multilinea)
python3 - "$OUT" "$UART_REG" "$UART_IRQ" "$CONSOLE" <<'PY'
import sys, re
out, reg, irq, console = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
s = open(out).read()
# 1) habilitar el hc_uart elegido (quitar status = "disabled"; el nodo puede no tener status)
s = re.sub(r'(hc_uart@%s \{[^}]*?)status = "disabled";' % reg, r'\1', s, flags=re.S)
# 2) forzar bootargs a console serial
s = re.sub(r'(bootargs = ")[^"]*(")', r'\1root=/dev/ram0 rootfstype=ramfs rw init=/linuxrc console=%s earlycon= no_console_suspend noirqdebug\2' % console, s)
open(out,'w').write(s)
print("Aplicadas desviaciones de diagnóstico en %s (uart %s, console %s)" % (out, reg, console))
PY

# Validación con el MISMO pipeline que Buildroot (gcc -E -> dtc)
TMPD=$(mktemp -d)
if gcc -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp -o "$TMPD/pp.dts" "$OUT" 2>/dev/null; then
  if dtc -I dts -O dtb -o "$TMPD/diag.dtb" "$TMPD/pp.dts" 2>"$TMPD/dtc.err"; then
    echo "DTC OK: $(stat -c%s "$TMPD/diag.dtb") bytes"
    cp "$TMPD/diag.dtb" "$OUT_DIR/r36sx-v26-diagnostic-serial.dtb"
    sha256sum "$OUT_DIR/r36sx-v26-diagnostic-serial.dtb"
    echo ""
    echo "=== DESPLIEGUE DE DIAGNÓSTICO (solo test, luego rollback) ==="
    echo "1) Copia en la SD (Windows):"
    echo "   Copy-Item \"D:\\R36SX\\staging\\vmlinux.uImage-r36sx-v26-fase4b\" G:\\cubegm\\vmlinux.uImage -Force"
    echo "   Copy-Item \"<ruta>/r36sx-v26-diagnostic-serial.dtb\" G:\\cubegm\\dtb.bin -Force"
    echo "2) Conecta USB-TTL al UART (hc_uart@0x${UART_REG}, 115200 8N1) y captura dmesg."
    echo "3) Tras el test, RESTAURAR: vmlinux stock (53b3e0b3) + dtb.bin stock (1258f1eb)."
  else
    echo "DTC FAIL:"; head -5 "$TMPD/dtc.err"; exit 1
  fi
else
  echo "gcc -E FAIL (el DTS de diagnóstico debe preprocesarse igual que el baseline)"; exit 1
fi
echo "=== diagnose_boot_serial DONE ==="