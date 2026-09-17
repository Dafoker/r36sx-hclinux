#!/bin/sh
# diagnose_console_6x.sh — Captura ON-DEVICE con NUESTRO kernel corriendo (iteración 6x, 017adf3b).
# Evidencia definitiva de Fase 5: /proc/version (dafunknoise@DFNK) + matriz de dependencias
# TreeFrogUI VIVA (fds /dev abiertos por proceso) para el contrato de Fase 6.
#
# EJECUCIÓN (con NUESTRO kernel 6x que bootea al menú):
#   1. Copiar como G:\diag6x.sh (raíz de la SD) desde el PC.
#   2. Bootear la consola -> entrar a FrogShell (file manager/terminal de TreeFrogUI).
#   3. Ejecutar:  sh /mnt/sdcard/diag6x.sh
#   4. Genera /mnt/sdcard/cubegm/diag6x_*.log
#   5. Traer la SD al PC -> analizar. NO toca vmlinux.uImage/dtb.bin/avp.uImage. Reversible.
#
# Compatible con busybox ash (sin bash/arrays).

LOG=/mnt/sdcard/cubegm/diag6x_$(date +%Y%m%d_%H%M%S).log
[ -d /mnt/sdcard/cubegm ] || LOG=/mnt/sdcard/diag6x_$(date +%Y%m%d_%H%M%S).log

sec() { echo "" >> "$LOG"; echo "===== $* =====" >> "$LOG"; }
w() { echo "$*" >> "$LOG"; }

: > "$LOG"
w "=== DIAG6X KERNEL PROPIO — $(date) ==="

# ---------- A. IDENTIDAD DEL KERNEL (evidencia definitiva Fase 5) ----------
sec "A. IDENTIDAD KERNEL (esperado: dafunknoise@DFNK, #14 o similar)"
w "uname -a: $(uname -a)"
w "-- /proc/version --"
cat /proc/version >> "$LOG" 2>/dev/null
w "-- /proc/cmdline --"
cat /proc/cmdline >> "$LOG" 2>/dev/null
w "-- /proc/cpuinfo (head) --"
head -12 /proc/cpuinfo >> "$LOG" 2>/dev/null
w "-- uptime --"
cat /proc/uptime >> "$LOG" 2>/dev/null

# ---------- B. ABI /dev TreeFrogUI (matriz de 6m) ----------
sec "B. ABI /dev TreeFrogUI — existencia por nodo"
for n in auddec backlight check_adc0 check_adc1 check_adc2 check_adc3 check_adc4 check_adc5 dis fb0 fb1 ge input/event0 input/event1 mmz persistentmem sndC0i2so sndC0i2so_left sndC0i2so_right standby watchdog misc zap zero tty1 ttyS0; do
  if [ -e "/dev/$n" ]; then
    w "OK      /dev/$n"
  else
    w "FALTA   /dev/$n"
  fi
done
w "-- /dev completo --"
ls -la /dev >> "$LOG" 2>/dev/null

# ---------- C. DEPENDENCIAS VIVAS: /dev abiertos por proceso ----------
sec "C. fds /dev ABIERTOS por proceso (dependencias reales del contrato)"
for pid in /proc/[0-9]*; do
  [ -d "$pid" ] || continue
  cmd=$(tr '\0' ' ' < "$pid/cmdline" 2>/dev/null)
  [ -z "$cmd" ] && continue
  devs=""
  for fd in "$pid"/fd/*; do
    [ -e "$fd" ] || continue
    t=$(readlink "$fd" 2>/dev/null)
    case "$t" in /dev/*) devs="$devs ${t#/dev/}";; esac
  done
  [ -n "$devs" ] && w "pid ${pid#/proc/} [$cmd] ->$(echo $devs | tr ' ' '\n' | sort -u | tr '\n' ' ')"
done

# ---------- D. Librerías cargadas por los procesos UI ----------
sec "D. maps: librerías de icube/rkgame/picoarch/hcdaemon (libs desde SD/bind)"
for pid in /proc/[0-9]*; do
  [ -d "$pid" ] || continue
  cmd=$(tr '\0' ' ' < "$pid/cmdline" 2>/dev/null)
  case "$cmd" in
    *icube*|*rkgame*|*picoarch*|*hcdaemon*|*MyExecutable*|*zhijack*)
      w "== pid ${pid#/proc/} [$cmd] =="
      grep -E "/lib/|sdcard" "$pid/maps" 2>/dev/null | awk '{print $6}' | sort -u >> "$LOG"
      ;;
  esac
done

# ---------- E. Mounts / input / fb / procesos ----------
sec "E. /proc/mounts"
cat /proc/mounts >> "$LOG" 2>/dev/null
sec "E2. input"
cat /proc/bus/input/devices >> "$LOG" 2>/dev/null
ls -la /dev/input >> "$LOG" 2>/dev/null
sec "E3. graphics/fb"
ls -la /sys/class/graphics/ >> "$LOG" 2>/dev/null
cat /sys/class/graphics/fb0/mode 2>/dev/null >> "$LOG"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null >> "$LOG"
sec "E4. procesos"
ps w >> "$LOG" 2>/dev/null

# ---------- F. dmesg del KERNEL PROPIO (primera vez visible) ----------
sec "F. dmesg COMPLETO (kernel propio 6x)"
dmesg >> "$LOG" 2>/dev/null
sec "F2. dmesg filtrado (mmc/ge/adc/fb/hichip/avp/amprpc)"
dmesg 2>/dev/null | grep -iE "mmc| ge |adc|fb|hichip|avp|amprpc|audio|snd" >> "$LOG"

w ""
w "=== FIN DIAG6X ==="
echo "LOG=$LOG"
exit 0
