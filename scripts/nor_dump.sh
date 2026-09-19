#!/bin/sh
# nor-dump.sh (Fase D-1) — dump COMPLETO del NOR flash (rollback bit-a-bit)
# Ejecutar en la consola: sh /mnt/sdcard/nor-dump.sh  (desde FrogShell)
# Lee SOLO de los dispositivos ro (read-only) — cero riesgo de escritura.
OUT=/mnt/sdcard/nor-dump
mkdir -p "$OUT"
echo "=== NOR DUMP — $(date) ===" > "$OUT/nor-table.txt"
cat /proc/mtd >> "$OUT/nor-table.txt" 2>/dev/null
echo >> "$OUT/nor-table.txt"
for m in /dev/mtd*ro; do
  n=$(basename "$m")
  echo "dumping $m ..."
  dd if="$m" of="$OUT/$n.bin" bs=64k 2>> "$OUT/nor-table.txt"
done
sync
echo "=== hashes ===" > "$OUT/SHA256SUMS.txt"
cd "$OUT" && sha256sum *.bin >> SHA256SUMS.txt 2>/dev/null
sync
echo "LISTO: $OUT — traer la SD al PC"
