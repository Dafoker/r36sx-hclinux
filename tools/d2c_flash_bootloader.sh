#!/bin/sh
# d2c_flash_bootloader.sh (Fase D-2c) — flash de NUESTRO bootloader sobre /dev/mtd1.
# RED COMPLETA: imagen sha-verificada + erase+write+readback byte-a-byte (mtdnor)
# + fallback dual-path compilado en el bootloader (/boot/ -> cubegm/).
# cubegm/ NO se toca en este paso: si algo falla, el bootloader cae a cubegm/.
IMG=/mnt/sdcard/bootloader-r36sx-v26-faseD2b.bin
EXPECTED=1734c340728fad9a10adbd19ee83714be73be63da7f5bb16323c13bb648f6e96
echo "1) sha256 de la imagen:"
echo "$EXPECTED  $IMG" | sha256sum -c - || { echo "IMAGEN NO COINCIDE — ABORT"; exit 1; }
echo "2) /boot/ preparado?:"
[ -f /mnt/sdcard/boot/dtb.bin ] && [ -f /mnt/sdcard/boot/avp.uImage ] && [ -f /mnt/sdcard/boot/vmlinux.uImage ] && [ -f /mnt/sdcard/boot/xgame-logo.bmp ] && echo "   /boot/ OK (4 archivos)" || { echo "   /boot/ INCOMPLETO — ABORT (ejecutar primero el boot dir)"; exit 1; }
echo "3) cubegm/ fisico (fallback del bootloader) intacto?:"
# ojo: en runtime /mnt/sdcard/cubegm puede ser un bind-alias del stack (layout treefrog);
# el cubegm FISICO que el bootloader usaria como fallback vive en /media/*/cubegm.
CUBEGM_OK=""
for d in /media/*/cubegm; do
  [ -f "$d/dtb.bin" ] && [ -f "$d/avp.uImage" ] && [ -f "$d/vmlinux.uImage" ] && CUBEGM_OK="$d"
done
[ -n "$CUBEGM_OK" ] && echo "   cubegm/ fisico OK ($CUBEGM_OK)" || { echo "   cubegm/ fisico INCOMPLETO — ABORT"; exit 1; }
echo "4) FLASH erase+write+verify (~2 min — NO apagar la consola):"
/mnt/sdcard/mtdnor /dev/mtd1 "$IMG" || { echo "FALLO DE ESCRITURA — NO REBOOT — revisar"; exit 1; }
echo
echo "D-2c COMPLETO: reboot — el bootloader nuevo prefiere /boot/;"
echo "si /boot/ fallara, cae automaticamente a cubegm/ (dual-path)."
