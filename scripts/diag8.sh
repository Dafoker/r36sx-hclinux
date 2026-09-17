#!/bin/sh
# diag8.sh — evidencia AVP-media/IRQ bajo el kernel propio (iteración 7c/7d).
# FrogShell: sh /mnt/sdcard/diag8.sh
# Idealmente reproducir un video/canción ANTES de correrlo (captura fds del reproductor).
# También sirve como baseline si se corre con stock.bak.
LOG=/mnt/sdcard/cubegm/diag8_$(date +%Y%m%d_%H%M%S).log
w(){ echo "$*" >> "$LOG"; }
: > "$LOG"
w "=== DIAG8 $(date) ==="
w "kernel: $(cat /proc/version 2>/dev/null)"
w ""
w "-- /proc/interrupts COMPLETO --"
cat /proc/interrupts >> "$LOG" 2>&1
w ""
w "-- /proc/iomem --"
cat /proc/iomem >> "$LOG" 2>&1
w ""
w "-- mmz: /proc/mmz + sysfs --"
cat /proc/mmz 2>/dev/null >> "$LOG"
ls -la /sys/class/mmz/ 2>/dev/null >> "$LOG"
w ""
w "-- nodos media presentes --"
ls -la /dev/auddec /dev/audsink /dev/avsync0 /dev/pq /dev/viddec /dev/vidsink /dev/vindvp /dev/kshmdev /dev/mmz /dev/ZZd2C 2>&1 >> "$LOG"
w ""
w "-- fds /dev abiertos por proceso (con reproductor activo si aplica) --"
for pid in /proc/[0-9]*; do
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
w ""
w "-- procesos completos --"
ps w >> "$LOG" 2>&1
w ""
w "=== FIN DIAG8 ==="
echo "LOG=$LOG"
