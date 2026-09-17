#!/bin/sh
# diag8.sh (v2) — evidencia AVP-media/IRQ bajo el kernel propio (iteración 7d).
# FrogShell: sh /mnt/sdcard/diag8.sh — corre ~15s (snapshot doble de interrupts).
# Sirve también como baseline si se corre bajo stock.bak.
LOG=/mnt/sdcard/cubegm/diag8_$(date +%Y%m%d_%H%M%S).log
w(){ echo "$*" >> "$LOG"; }
: > "$LOG"
w "=== DIAG8 $(date) ==="
w "kernel: $(cat /proc/version 2>/dev/null)"
w ""
w "-- /proc/interrupts SNAPSHOT 1 --"
cat /proc/interrupts >> "$LOG" 2>&1
w ""
w "-- /proc/devices (drivers char/block registrados) --"
cat /proc/devices >> "$LOG" 2>&1
w ""
w "-- /proc/misc --"
cat /proc/misc >> "$LOG" 2>&1
w ""
w "-- /proc/iomem --"
cat /proc/iomem >> "$LOG" 2>&1
w ""
w "-- mmz --"
cat /proc/mmz 2>/dev/null >> "$LOG"
ls -la /sys/class/mmz/ 2>/dev/null >> "$LOG"
w ""
w "-- nodos media presentes --"
ls -la /dev/auddec /dev/audsink /dev/avsync0 /dev/pq /dev/viddec /dev/vidsink /dev/vindvp /dev/kshmdev /dev/mmz /dev/ZZd2C 2>&1 >> "$LOG"
w ""
w "-- sysfs: kernel y class (top) --"
ls /sys/kernel/ >> "$LOG" 2>&1
ls /sys/class/ >> "$LOG" 2>&1
w ""
w "-- fds /dev abiertos por proceso --"
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
w "-- delta: esperando 10s --"
sleep 10
w "-- /proc/interrupts SNAPSHOT 2 (tras 10s) --"
cat /proc/interrupts >> "$LOG" 2>&1
w ""
w "-- procesos --"
ps w >> "$LOG" 2>&1
w ""
w "=== FIN DIAG8 ==="
echo "LOG=$LOG"
