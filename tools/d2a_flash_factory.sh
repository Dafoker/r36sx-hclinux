#!/bin/sh
# D-2a' — prueba del mecanismo MTD: re-escribir los BYTES EXACTOS de fabrica
# (del dump) sobre /dev/mtd1. CERO cambio de contenido: la consola debe
# rebootear identica. Verifica ANTES de tocar nada.
IMG=/mnt/sdcard/nor-dump/mtd1ro.bin
EXPECTED=9fc95d7e60716e73e5b0e442ea6b4930643244dd852415c68833a7562bcf2b1b
echo "1) sha256 de la imagen:"
echo "$EXPECTED  $IMG" | sha256sum -c - || { echo "IMAGEN NO COINCIDE — ABORT"; exit 1; }
echo "2) verify-only: el mtd actual debe ser YA el de fabrica (= imagen):"
/mnt/sdcard/mtdnor /dev/mtd1 "$IMG" verify || { echo "mtd DIFFIERE del dump — revisar — ABORT"; exit 1; }
echo "3) erase+write+verify (bytes identicos de fabrica):"
/mnt/sdcard/mtdnor /dev/mtd1 "$IMG" || { echo "FALLO DE ESCRITURA — NO reboot aun, revisar"; exit 1; }
echo
echo "D-2a' COMPLETO: reboot ahora — la consola debe arrancar IDENTICA."
