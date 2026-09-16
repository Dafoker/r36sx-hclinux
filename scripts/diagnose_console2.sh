#!/bin/sh
# diagnose_console2.sh — Diagnóstico de FÁBRICA para ejecutar EN la consola R36SX (FrogShell, kernel stock).
# Objetivo Fase 5: extraer del sistema de fábrica (que funciona) lo que necesitamos para
# reconstruir nuestro kernel y hacer el reemplazo total:
#   A. EL CONFIG EXACTO DE FÁBRICA via /proc/config.gz (si CONFIG_IKCONFIG_PROC)
#   B. El driver/controlador mmc que la fábrica usa (binding + modalias)  <-- clave para el SD
#   C. El DTB runtime real (/proc/device-tree) y cómo monta la SD
#   D. Estado runtime completo (mmc/clock/pinctrl/mounts)
#
# EJECUCIÓN (con kernel stock que funciona):
#   1. Restaurar SD a stock; copiar este script a G:\diag2.sh desde el PC.
#   2. Bootear -> entrar a FrogShell (file manager/terminal de TreeFrogUI).
#   3. Ejecutar:  sh /mnt/sdcard/diag2.sh
#   4. Genera /mnt/sdcard/cubegm/diag2_*.log y, si existe, copia /proc/config.gz a /mnt/sdcard/cubegm/config.gz
#   5. Traer la SD al PC -> analizar. NO modifica vmlinux.uImage ni dtb.bin. Reversible.
#
# Compatible con busybox ash (sin bash/arrays).

LOG=/mnt/sdcard/cubegm/diag2_$(date +%Y%m%d_%H%M%S).log
[ -d /mnt/sdcard/cubegm ] || LOG=/mnt/sdcard/diag2_$(date +%Y%m%d_%H%M%S).log

sec() { echo "" >> "$LOG"; echo "===== $* =====" >> "$LOG"; }
w() { echo "$*" >> "$LOG"; }

: > "$LOG"
w "=== DIAG2 FÁBRICA — $(date) ==="
w "host: $(uname -a)"
w "cmdline: $(cat /proc/cmdline 2>/dev/null)"

# ---------- A. CONFIG DE FÁBRICA (el premio) ----------
sec "A. /proc/config.gz (CONFIG_IKCONFIG_PROC) — el config EXACTO de fábrica"
if [ -e /proc/config.gz ]; then
  w "EXISTE /proc/config.gz — copiando a SD..."
  cp /proc/config.gz /mnt/sdcard/cubegm/config.gz 2>/dev/null && w "COPIADO -> /mnt/sdcard/cubegm/config.gz"
  ls -la /mnt/sdcard/cubegm/config.gz 2>/dev/null >> "$LOG"
  w "--- (opcional) volcado de marcadores IKCFG ---"
  strings /proc/config.gz 2>/dev/null | grep -E "CONFIG_MMC_DW|CONFIG_HC_SDIO|CONFIG_CLK|CONFIG_HC_PINCTRL|CONFIG_IKCONFIG|CONFIG_INITRAMFS|CONFIG_BLK_DEV_INITRD|CONFIG_CHECK_ADC" >> "$LOG"
else
  w "NO existe /proc/config.gz — la fábrica NO tiene IKCONFIG_PROC. Imposible extraer config por esta vía."
fi

# ---------- B. DRIVER MMC QUE USA LA FÁBRICA (clave para el SD) ----------
sec "B. Controlador mmc / binding del driver (qué maneja la SD)"
w "-- /sys/class/mmc_host/ --"
ls -la /sys/class/mmc_host/ 2>/dev/null >> "$LOG"
for h in /sys/class/mmc_host/*; do
  [ -e "$h" ] || continue
  w "== $h =="
  cat "$h/name" 2>/dev/null >> "$LOG"
  w "   modalias: $(cat $h/../device/modalias 2>/dev/null)"
  w "   driver:  $(readlink -f $h/../device/driver 2>/dev/null)"
  w "   driver_name: $(basename $(readlink -f $h/../device/driver 2>/dev/null))"
done
w "-- plataform drivers mmc/dw --"
ls -la /sys/bus/platform/drivers/ 2>/dev/null | grep -iE "mmc|dw|sdio|mshc" >> "$LOG"
w "-- binding dw_mmc_hc (driver hichip) --"
ls -la /sys/bus/platform/drivers/dw_mmc_hc/ 2>/dev/null >> "$LOG"
w "-- binding dwmmc / dw_mmc (estándar) --"
ls -la /sys/bus/platform/drivers/dwmmc*/ /sys/bus/platform/drivers/dw_mmc/ 2>/dev/null >> "$LOG"
w "-- dispositivos de plataforma con mmc en modalias --"
for d in /sys/bus/platform/devices/*; do
  m=$(cat "$d/modalias" 2>/dev/null)
  case "$m" in *mmc*|*dw*) w "$(basename $d): $m";; esac
done

# ---------- C. DTB RUNTIME REAL + mmc node ----------
sec "C. /proc/device-tree runtime (como lo ve el kernel de fábrica)"
w "-- árbol de device-tree (nombres de nodos) --"
find /proc/device-tree -maxdepth 3 -type f -name name 2>/dev/null | while read f; do echo "$(dirname ${f#/proc/device-tree}): $(cat $f)" >> "$LOG"; done
w "-- nodo mmc (search) --"
for n in $(find /proc/device-tree -iname '*mmc*' 2>/dev/null); do
  w "== $n =="
  w "   compatible: $(cat $n/compatible 2>/dev/null)"
  w "   status:     $(cat $n/status 2>/dev/null)"
  w "   clocks:     $(hexdump -C $n/clocks 2>/dev/null | head -3)"
done

# ---------- C2. CÓMO MONTA LA SD ----------
sec "C2. Cómo monta la SD la fábrica"
w "-- /proc/mounts (solo sd/media/fat) --"
grep -iE "mmcblk|sdcard|/media|vfat|sd" /proc/mounts 2>/dev/null >> "$LOG"
w "-- /etc/mdev.conf --"
cat /etc/mdev.conf 2>/dev/null >> "$LOG"
w "-- /etc/fstab --"
cat /etc/fstab 2>/dev/null >> "$LOG"
w "-- /etc/mdev/mount-helper.sh (head) --"
head -30 /etc/mdev/mount-helper.sh 2>/dev/null >> "$LOG"
w "-- blkid --"
blkid 2>/dev/null >> "$LOG"
w "-- /sys/block/mmcblk0 --"
ls -la /sys/block/ 2>/dev/null | grep mmc >> "$LOG"
cat /sys/block/mmcblk0/size /sys/block/mmcblk0/device/type /sys/block/mmcblk0/device/name 2>/dev/null >> "$LOG"

# ---------- D. ESTADO RUNTIME COMPLETO ----------
sec "D. dmesg (completo)"
dmesg 2>/dev/null >> "$LOG"
sec "D2. dmesg filtrado mmc/clock/sdio/pinctrl/error"
dmesg 2>/dev/null | grep -iE "mmc|dw|mshc|sdio|clk|clock|pinctrl|gpio|error|fail|hichip" >> "$LOG"
sec "D3. /dev"
ls -la /dev/ 2>/dev/null >> "$LOG"
sec "D4. /proc/modules"
cat /proc/modules 2>/dev/null >> "$LOG"
sec "D5. /proc/mtd"
cat /proc/mtd 2>/dev/null >> "$LOG"
sec "D6. procesos"
ps w 2>/dev/null >> "$LOG"

w ""
w "=== FIN DIAG2 ==="
echo "LOG=$LOG"
exit 0