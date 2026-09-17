#!/bin/sh
# diag9.sh — SONDA DEL AVP (Estrategia B): consola del RTOS via /dev/virtuart
# + estado de nodos media + dmesg fresco. Corre desde FrogShell:
#   sh /mnt/sdcard/diag9.sh
# Log a /media/*/cubegm/diag9_*.log. NO destructivo. Reversible.
LOG=/media/*/cubegm/diag9_$(date +%Y%m%d_%H%M%S).log
for d in /media/*/cubegm; do [ -d "$d" ] && LOG="$d/diag9_avp_$(date +%Y%m%d_%H%M%S).log"; done
TMP=/tmp/avp_read.bin

w(){ echo "$*" >> "$LOG"; }
: > "$LOG"
w "=== DIAG9 — SONDA AVP — $(date) ==="
w "kernel: $(cat /proc/version 2>/dev/null)"
w "uptime: $(cut -d' ' -f1 /proc/uptime 2>/dev/null)"
w ""

# ---------- 1. CONSONA DEL AVP (virtuart) ----------
w "--- 1. lectura pasiva de /dev/virtuart (3s) ---"
: > "$TMP"
cat /dev/virtuart > "$TMP" 2>&1 &
RPID=$!
sleep 1
printf "\r\n" > /dev/virtuart 2>/dev/null
sleep 1
echo "help" > /dev/virtuart 2>/dev/null
echo "?" > /dev/virtuart 2>/dev/null
sleep 2
kill $RPID 2>/dev/null
S=$(stat -c%s "$TMP" 2>/dev/null || echo 0)
w "bytes leidos del virtuart: $S"
if [ "$S" -gt 0 ]; then
  w "--- contenido bruto (strings visibles):"
  strings "$TMP" 2>/dev/null >> "$LOG" || cat "$TMP" >> "$LOG"
  w "--- hexdump primeras 256B:"
  od -A x -t x1z "$TMP" 2>/dev/null | head -16 >> "$LOG"
else
  w "(el AVP no escribio nada en el virtuart)"
fi
w ""

# ---------- 2. NODOS MEDIA: open() probe ----------
w "--- 2. open() probe de nodos media (errno revela el estado del driver) ---"
for n in auddec audsink viddec vidsink avsync0 sndC0i2so sndC0spo sndC0i2si vindvp pq kshmdev mmz virtuart ZZd2C; do
  if [ -c "/dev/$n" ]; then
    R=$( (exec 3<>"/dev/$n") 2>&1 )
    RC=$?
    w "  /dev/$n: open rc=$RC $R"
  else
    w "  /dev/$n: AUSENTE"
  fi
done
w ""

# ---------- 3. dmesg fresco (busca errores del proxy post-boot) ----------
w "--- 3. dmesg completo ---"
dmesg >> "$LOG" 2>&1
w ""
w "--- 3b. dmesg filtrado proxy/rpc/avp/audio ---"
dmesg 2>/dev/null | grep -iE "proxy|amprpc|rpc|avp|aud|snd|vid|kshm|fail|error|timeout" >> "$LOG"
w ""
w "--- 4. procesos ---"
ps w >> "$LOG" 2>&1
w ""
w "=== FIN DIAG9 ==="
echo "LOG=$LOG"