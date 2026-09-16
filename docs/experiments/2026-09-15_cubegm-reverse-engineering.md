# Experimento: 2026-09-15 — Ingeniería inversa de cubegm (TreeFrogUI) para el reemplazo total

# Objective

Documentar la capa `cubegm/` de la SD (el "SO" TreeFrogUI que corre la consola) y su contrato
con el kernel, para (a) entender qué debe proporcionar NUESTRO kernel/DTB/rootfs y (b) avanzar
hacia el reemplazo total. Evidencia leída de la SD stock (G:) — solo lectura.

# Resumen de la arquitectura (2 capas)

```
CAPA 1 — KERNEL + INITRAMFS (lo que construimos en r36sx-hclinux)
  vmlinux.uImage (embebe initramfs rootfs del desarrollador)
  -> S99app: monta la SD en /mnt/sdcard, activa swap, lanza icube.sh

CAPA 2 — cubegm/ (UI TreeFrogUI, en la SD)
  icube.sh -> icube -> rkgame -> setting.xml autorun -> libemu_tfhijack.so
  -> zhijack.sh -> picoarch + cores/frogui_libretro.so  (EL MENÚ)
       + driver_r36sx.so (driver de dispositivo: display/audio/input)
       + lib/ (glibc, SDL...) y usr/lib/ (DirectFB, SDL2)
```

La capa 2 (la UI) corre íntegramente sobre la capa 1. **Sin la SD montada en /mnt/sdcard,
la capa 2 jamás arranca** (S99app es el punto de entrada). Por tanto el montaje de la SD
es PREREQUISITO duro para cualquier UI (la de fábrica o una reemplazada).

# Flujo de arranque del SO (cubegm)

1. `icube.sh`: `export LD_LIBRARY_PATH=...cubegm/lib:...cubegm/usr/lib; /mnt/sdcard/cubegm/icube & init -q`
2. `icube` (launcher MIPS32 ELF, dinámico): stock R36SX/SF3000 respawnea `rkgame`.
3. `rkgame` -> `setting.xml autorun driver=""` -> `libemu_tfhijack.so` hace fork de `zhijack.sh`.
4. `zhijack.sh` (bucle principal TreeFrogUI):
   - `kill -STOP icube; killall rkgame` (congela el launcher stock, mata rkgame).
   - Escribe `/tmp/tfdevice.env` (parámetros de dispositivo).
   - Bucle: `picoarch cores/frogui_libretro.so` (el menú); relanza juegos según `/tmp/frogui_launch.txt`.

# Parámetros de dispositivo (tfdevice.env, R36SX)

```
TF_DEVICE=R36SX
TF_PANEL_W=640      TF_PANEL_H=480
TF_UI_SCALE=150
TF_ASPECT_NUM=4     TF_ASPECT_DEN=3
TF_ROTATE=0
TF_PRESENT=fbwrite
TF_DRIVER=/mnt/sdcard/cubegm/driver_r36sx.so
```

# ABI de dispositivo que la UI exige del kernel

`driver_r36sx.so` (y la variante safe `driver_r36sx27.so`) abren estos `/dev`:

```
/dev/auddec  /dev/backlight  /dev/check_adc1  /dev/dis  /dev/fb0
/dev/ge  /dev/input/event0  /dev/mmz  /dev/persistentmem  /dev/sndC0i2so  /dev/standby
```

Lecturas adicionales: `/proc/device-tree/hcrtos/hdmi/status`, `/proc/device-tree/hcrtos/i2so/volume`,
`/tmp/joy_key` (shared-memory de input escrita por `cubevol` leyendo GPIO; el input NO va por
`/dev/input/event0` aunque el driver lo abre). Ioctls clave: `FBIOBLANK` (fb0), `DIS_GET_SCREEN_INFO` (dis),
operaciones `hcge` (motor 2D /dev/ge), `cube_ioctl`.

Todos estos `/dev` los crea el config de nuestro kernel (HC_FB, HC_GE, HC_DIS, HC_MMZ, HC_AUDDEC,
HC_I2SO, HC_AVPPROXY, CHECK_ADC, HC_PERSISTENTMEM =y) + avp-proxy vía DTS (backlight/standby).
La ABI está cubierta a nivel de config.

# Hallazgos clave

1. `driver.so` == `driver_r36sx.so` (hash idéntico `58b180a2...`). R36SX usa el driver genérico.
2. `driver_r36sx27.so` (safe) usa la MISMA ABI de /dev pero hace stub del motor 2D (GE) que
   provoca SIGBUS en algunos kernels (v2.7-class). zhijack detecta SIGBUS 2× y cambia permanentemente.
3. `modules/4.4.186-release/` solo tiene `usb_f_mass_storage.ko` y `usb_f_mtp.ko` (gadget USB).
   El resto del kernel de fábrica es monolítico (drivers en vmlinux).
4. `cores/`: `frogui_libretro.so` (menú), `frogshell_libretro.so` (file manager), cientos de cores
   libretro + los `libemu_*.so` propios de fábrica. `.pcsx4all/` configuración PS1.
5. Binarios MIPS32 rel2, dinámicos, intérprete `/lib/ld.so.1` — coinciden con la libc del
   initramfs del desarrollador (que extrajimos del stock y embebimos). ABI de usuario compatible.
6. USB mode: `usb_mode.sh` expone la SD al PC vía gadget configfs (mass-storage o MTP con
   `mtp-server` + `usb_f_mtp.ko`). Confirmación de que el puerto USB-C puede exportar la SD.
7. Update offline: `tfupdate.sh` (update.zip + SHA256SUMS + manifest, formato treefrog-update).

# Implicaciones para el reemplazo total

- El "SO" es en realidad picoarch+frogui+driver sobre el kernel. Para reemplazarlo bastaría
  sustituir la capa 2 (cubegm) por la nuestra, SI el kernel+rootfs arrancan y montan la SD.
- **BLOQUEADOR ACTUAL SIN RESOLVER:** nuestro kernel (config correcto, driver mmc correcto)
  no logra montar la SD en runtime (3 tests sin dmesg a la SD; fábrica sí la monta con el
  mismo driver). Sin SD montada, ninguna UI (de fábrica o reemplazada) arranca.
  La causa es de runtime del kernel y requiere el dmesg de NUESTRO kernel (serial ADR-011) o
  el análisis de los drivers propietarios de fábrica ausentes del SDK (`decrypt_sector_data`,
  `/dev/ZZd2C`).

# Decision

- cubegm queda documentado como contrato de usuario (ABI /dev + libs + boot flow).
- El montaje de la SD sigue siendo el bloqueador crítico previo a cualquier reemplazo de UI.
