#!/bin/sh
# diag7.sh — Test causal del bind /etc (hipótesis 7b: S99app no logra montar
# rootfs/etc bajo el kernel propio, y eso rompe video/salida-de-FrogShell).
# CORRE EN LA CONSOLA (FrogShell): sh /mnt/sdcard/diag7.sh
# Si el bind manual tiene éxito, lo DEJA MONTADO para que pruebes video y
# volver-de-FrogShell inmediatamente. Reversible con reboot.
LOG=/mnt/sdcard/cubegm/diag7_$(date +%Y%m%d_%H%M%S).log

w(){ echo "$*" >> "$LOG"; }
: > "$LOG"
w "=== DIAG7 $(date) ==="
w "kernel: $(cat /proc/version 2>/dev/null)"
w ""
w "-- binds actuales (lib/usr/bin/sbin/etc) --"
grep -E " /(etc|lib|bin|sbin|usr) " /proc/mounts >> "$LOG"
w ""
w "-- rootfs/etc en SD: $([ -d /media/mmc/rootfs/etc ] && echo PRESENTE || echo AUSENTE)"
w ""
w "-- INTENTO MANUAL: mount --bind /media/mmc/rootfs/etc /etc --"
mount --bind /media/mmc/rootfs/etc /etc >> "$LOG" 2>&1
RC=$?
w "rc=$RC  (0 = exito)"
w ""
w "-- /proc/mounts tras el intento (/etc) --"
grep " /etc " /proc/mounts >> "$LOG"
w ""
w "-- contenido de /etc ahora --"
ls /etc >> "$LOG" 2>&1
w ""
w "-- (extra) rootfs/bin: mount/busybox --"
ls -la /media/mmc/rootfs/bin/mount /media/mmc/rootfs/bin/busybox 2>&1 >> "$LOG"
w ""
if [ "$RC" = "0" ]; then
  w ">>> BIND EXITOSO — /etc de la SD AHORA MONTADO. PROBAR AHORA MISMO:"
  w ">>>   1. reproducir un video del menu"
  w ">>>   2. entrar a FrogShell y volver al menu"
  w ">>> Si funcionan con el bind montado = causa raiz confirmada."
else
  w ">>> BIND FALLO — capturar el errno arriba."
fi
w ""
w "=== FIN DIAG7 ==="
echo "LOG=$LOG"