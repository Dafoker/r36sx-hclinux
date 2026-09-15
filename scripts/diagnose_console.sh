#!/bin/sh
# diagnose_console.sh — Diagnóstico de arranque para ejecutar EN la consola R36SX.
# Fase 5: la UI se queda en splash sin llegar al menú. Este script recopila
# evidencia para localizar dónde se cuelga el boot, escribiéndola a un log
# accesible desde el PC (en la partición de datos de la SD).
#
# EJECUCIÓN (desde FrogShell, con kernel stock que funciona):
#   1. Copia este script a la SD (p.ej. /mnt/sdcard/diag.sh) desde el PC.
#   2. En FrogShell (file manager/terminal de TreeFrogUI), navega y ejecuta:
#        sh /mnt/sdcard/diag.sh
#      (o por terminal:  cd /mnt/sdcard && sh diag.sh)
#   3. Genera /mnt/sdcard/cubegm/diag_*.log — recoge ese archivo desde el PC.
#   NO modifica vmlinux.uImage ni dtb.bin. Reversible.
#
# Compatible con busybox ash (la consola usa busybox; sin bash ni arrays).

LOG=/mnt/sdcard/cubegm/diag_$(date +%Y%m%d_%H%M%S).log
[ -d /mnt/sdcard/cubegm ] || LOG=/mnt/sdcard/diag_$(date +%Y%m%d_%H%M%S).log

log() { echo "[diag] $*" >> "$LOG"; }
sec()  { echo ""; echo "===== $* =====" >> "$LOG"; }

: > "$LOG"
log "=== DIAGNÓSTICO R36SX boot — $(date) ==="
log "host: $(uname -a)"

sec "cmdline"
cat /proc/cmdline 2>/dev/null >> "$LOG"

sec "bootargs (dmesg early)"
dmesg 2>/dev/null | grep -iE "command line|cmdline|bootargs|Kernel command" >> "$LOG"

sec "DMESG COMPLETO (clave: dónde se cuelga)"
dmesg 2>/dev/null >> "$LOG"

sec "dmesg últimas 80 líneas"
dmesg 2>/dev/null | tail -80 >> "$LOG"

sec "/dev/ disponibles (qué nodos creó el kernel)"
ls -la /dev/ 2>/dev/null >> "$LOG"
ls -la /dev/input/ 2>/dev/null >> "$LOG"

sec "módulos cargados"
cat /proc/modules 2>/dev/null >> "$LOG"

sec "particiones MTD (NOR)"
cat /proc/mtd 2>/dev/null >> "$LOG"

sec "drivers en /sys/class"
ls /sys/class/ 2>/dev/null >> "$LOG"
echo "-- backlight --" >> "$LOG"
ls -la /sys/class/backlight/ 2>/dev/null >> "$LOG"
echo "-- input --" >> "$LOG"
ls -la /sys/class/input/ 2>/dev/null >> "$LOG"
echo "-- fb --" >> "$LOG"
ls -la /sys/class/graphics/ 2>/dev/null >> "$LOG"

sec "AVP / amprpc / kshm"
ls -la /dev/kshm* /sys/class/*amprpc* /proc/amprpc* 2>/dev/null >> "$LOG"

sec "batería / check_adc (vía sysfs)"
ls -la /sys/class/hwmon/ 2>/dev/null >> "$LOG"
find /sys -name "*check_adc*" -o -name "*adc*" 2>/dev/null | head -30 >> "$LOG"

sec "DTS que el kernel cargó (/proc/device-tree) — status de nodos clave"
for n in /proc/device-tree/soc/backlight@0 /proc/device-tree/soc/check_adc1@18818400 /proc/device-tree/soc/pwm@18818410 /proc/device-tree/soc/hc_uart@18818600; do
  if [ -e "$n" ]; then
    echo "== $n ==" >> "$LOG"
    cat "$n/name" 2>/dev/null >> "$LOG"
    echo -n "status=" >> "$LOG"
    cat "$n/status" 2>/dev/null >> "$LOG"
    echo "" >> "$LOG"
  else
    echo "$n: NO EXISTE" >> "$LOG"
  fi
done

sec "/proc/iomem (memoria)"
cat /proc/iomem 2>/dev/null >> "$LOG"

sec "procesos en ejecución"
ps w 2>/dev/null >> "$LOG"

sec "estado fb (fbset/fbdev)"
ls -la /sys/class/graphics/fb0/ 2>/dev/null >> "$LOG"
cat /sys/class/graphics/fb0/name 2>/dev/null >> "$LOG"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null >> "$LOG"

log ""
log "=== FIN DIAGNÓSTICO ==="
echo "[diag] Diagnóstico escrito en: $LOG" >> /dev/console 2>&1
echo "LOG=$LOG"
exit 0