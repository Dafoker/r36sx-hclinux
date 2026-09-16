# Experimento: 2026-09-16 — Comparación initramfs STOCK vs NUESTRO (montaje de la SD)

# Objective

Responder a la hipótesis del usuario: "comparar el backup de treefrogui stock con lo que tenemos
y encontrar dónde se monta la SD". Verificar si nuestro initramfs embebido (`rootfs-dev.cpio`)
difiere del initramfs del kernel STOCK (`vmlinux.uImage.stock.bak`, 53b3e0b3) en el mecanismo de
montaje de la SD, y si `cubegm` contiene scripts que monten el sistema.

# Método

1. Extraer el initramfs del vmlinux STOCK: uImage header(64) -> gzip -> `vmlinux.bin` (8,709,472 B)
   -> buscar magic cpio `070701` (el initramfs STOCK es cpio CRUDO, NO gzip) -> `stock.initramfs.raw`
   (4,460,028 B desde offset 4249444).
2. Extraer ambos cpio y comparar árbol + scripts de montaje.
3. Analizar scripts de cubegm y la carpeta rootfs/ de la SD.

# Resultado (comparación initramfs)

- **Stock: 50 archivos** · **Nuestro rootfs-dev.cpio: 53** (3.85 MB c/u).
- **Faltan en el nuestro: 0** (tenemos TODOS los del stock).
- **Extras (3):** `etc/init.d/S11diag`, `S41hcdaemon.orig`, `S99app.orig` (diagnóstico).
- Scripts de montaje IDÉNTICOS: `S10mdev`, `S99app`, `mdev.conf`, `etc/mdev/mount-helper.sh`,
  `inittab`, `linuxrc`, `rcS`. `busybox`/`libc`/`hcdaemon` presentes en ambos.

# Resultado (¿monta cubegm?)

- **cubegm NO monta el sistema.** Todos los scripts (`icube.sh`, `icube_start.sh`, `zhijack.sh`,
  `rockbox.sh`, `usb_mode.sh`) asumen `/mnt/sdcard` ya montado; solo configuran LD_LIBRARY_PATH y
  lanzan binarios. `usb_mode.sh` hace unmount/remount SOLO para USB gadget (no es boot).
- **La SD tiene `rootfs/`** (313 MB, 603 archivos, `linuxrc` 867KB) = rootfs REAL, bind-montado por
  el initramfs `S99app` (NO por cubegm).

# Conclusión — DÓNDE se monta la SD

El montaje ocurre en el **initramfs** (`S99app`):
1. `S10mdev`: tmpfs en /media + `/proc/sys/kernel/hotplug=/sbin/mdev` + `mdev -s`.
2. `mdev.conf` dispara `mount-helper.sh` cuando aparece `mmcblk[0-9]p[0-9]` -> monta en /media.
3. `S99app.wait_for_media_ready()` espera `/media/<subdir>/cubegm/icube`.
4. `mount --bind /media/<MNTDIR> /mnt/sdcard` (+ bind de `rootfs/` si existe).
5. swap (`pagefile.sys`) + lanza `icube.sh` -> icube -> rkgame -> UI.

**Nuestro initramfs es IDÉNTICO al stock en el montaje. La SD se montaría si el kernel detectara
`mmcblk0p1`. El problema es 100% del kernel (mmc runtime).** Se descartan: initramfs incompleto,
y cubegm-montaje.

# Implicación

- El bloqueador es exclusivamente el kernel: (a) hang en init de dispositivos antes de userspace,
  o (b) el controlador mmc (`hichip,dw-mshc`) no detecta la tarjeta. Requiere dmesg (serial ADR-011)
  o variantes de config del kernel con señal = "aparece dmesg_boot.log en la SD".
