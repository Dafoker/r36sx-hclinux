# Experimento: 2026-09-17 — Análisis DIAG6X + defectos funcionales post-PHYSICAL-PASS (iteración 7b)

# Contexto

Tras el PHYSICAL PASS 6x (menú TreeFrogUI navegable), el usuario reporta dos defectos funcionales con el kernel propio: (1) volver de FrogShell al menú "no funciona correctamente"; (2) los videos "no se reproducen correctamente". Nota: la SD había recibido un sync de TreeFrogUI v1.5.0_j a las 12:24 del 16-sep (reemplazó zhijack.sh, video_player, picoarch, drivers) — los tests 6w/6x fueron los primeros boots con ese contenido.

# Evidencia DIAG6X (on-device, kernel propio, `evidence-diag6x.log`)

## Identidad del kernel — EVIDENCIA DEFINITIVA Fase 5

```
Linux version 4.4.186-release (dafunknoise@DFNK) (gcc 6.3.0 Codescape 2018.09-02) #18 PREEMPT Wed Sep 16 23:48:13 -05 2026
```
uptime 32s al capturar. MIPS 74Kc, HC16xx, cmdline idéntica a fábrica.

## ABI viva (fds /dev abiertos por proceso) — la matriz real del contrato

| Proceso | /dev abiertos |
|---|---|
| `picoarch` (EL MENÚ, core frogshell_libretro.so) | auddec check_adc1 check_adc5 fb0 ge mem |
| `hcdaemon` | **ZZd2C** console null |
| `cubevol` | check_adc1 check_adc5 console dis fb1 **hdmi** mem |
| `zhijack.sh` (rama RAM) | auddec check_adc1 console fb0 ge mem |
| `nosleep` | auddec check_adc1 fb0 ge mem |

- **/dev/ZZd2C existe y funciona bajo nuestro kernel** (hcdaemon lo tiene abierto) — la afirmación 6l ("no está en el SDK, binario propietario") era INCORRECTA: el driver viene del SDK.
- picoarch carga (maps): libSDL-1.2, libpng16, libstdc++, libgcc_s, libpthread, libdl, libm, driver_r36sx.so, frogshell_libretro.so — todos desde la SD (binds).
- **Mecanismo de input resuelto** (zhijack.sh): *"rkgame stays alive, keeping the **cubevol gpio -> /tmp/joy_key input pipeline** up"* — NO hay evdev ni input/event0 (en fábrica tampoco; consistente). cubevol lee GPIO vía /dev/mem y alimenta /tmp/joy_key.

## /dev: nuestro ⊇ fábrica

Solo extras nuestros: banco legacy ptys (CONFIG_LEGACY_PTYS), ubi_ctrl (HC_NAND→UBI), watchdog/watchdog0 (HC_WDT), dumpstack, ptmx. Fábrica (listing truncado en tty13 en el log original) contiene todos los nodos funcionales que tenemos (dis, ge, fb0/1, auddec, audsink, avsync0, kshmdev, mmz, pq, sndC0i2si, sndC0i2so, sndC0spo, spidev32766.1, standby, persistentmem, hdmi, hdmi_rx, mipi, viddec*, ZZd2C). Nuestro /dev también los tiene todos (sndC0i2si/sndC0spo/spidev verificados en el log).

## dmesg del kernel propio (primera vez visible)

mmc idéntico a fábrica (`dw_mmc_hc 1884c000.mmc: host clk=198000000, Version 270a, irq 10`), **detección de tarjeta** (`mmc0: new high speed SDXC` → `mmcblk0 SD64G` → `p1`), `hcge Init GE success`, check_adc1/5, fb0/fb1 enable, `virtuart init ok`, FAT utf8 warning (igual que fábrica). "Initrd not found" = normal (initramfs es built-in, no initrd externo).

# HALLAZGO CRÍTICO — el bind de /etc no ocurre bajo nuestro kernel

- Fábrica (DIAG2, /proc/mounts): **7 binds** de mmcblk0p1: /media/mmc, /mnt/sdcard, /lib, /usr, /bin, /sbin, **/etc**.
- Nuestro (DIAG6X, /proc/mounts): **6 binds** — **SIN /etc**.
- S99app es byte-idéntico al stock (verificado 6w). La rama rootfs se tomó (lib/usr/bin/sbin bind OK ⇒ `[ -d rootfs ]` cierto). `G:\rootfs\etc` EXISTE y está lleno (passwd, inittab, init.d/S21dsc, profile.d, mdev.conf, hosts, services...).
- `rootfs/bin` tiene busybox + mount/umount (igual que fábrica).
- ⇒ El `mount --bind /media/mmc/rootfs/etc /etc` de S99app **falla o se salta solo con nuestro kernel** — correlación directa kernel.
- Sin el bind, los procesos ven el `/etc` mínimo del initramfs en lugar del userland completo de la SD (passwd/hosts/profile.d/services/...). Candidato a causa de: video_player con config ausente, contexto de FrogShell, etc.

# Test causal desplegado (diag7)

`G:\diag7.sh` + `scripts/diag7.sh` (sha256 ee57975c...): intenta el bind MANUAL desde FrogShell, captura errno, y si tiene éxito lo DEJA MONTADO para probar inmediatamente video + volver-de-FrogShell. Resultado pendiente del usuario.

# Resultado diag7 (noche 16/17-sep) — hipótesis /etc REFUTADA

- diag7 ×2 (evidence-diag7-1/2.log): **el bind /etc FUNCIONÓ en boot** (montado nativamente en los arranques de hoy; la ausencia en la captura DIAG6X fue una anomalía one-off). Bind manual rc=0 (doble montado inofensivo).
- **Los síntomas persisten CON el bind activo** → el /etc NO es la causa.

# Matriz de síntomas refinada (tests físicos del usuario con 6x)

| Función | Estado | Vía |
|---|---|---|
| Menú TreeFrogUI (navegar/lanzar) | ✅ | Linux puro: fb0 + GE |
| Juegos (emulación) | ✅ funcionan, **sin sonido** | core Linux + audio vía AVP ❌ |
| Música (canción) | ❌ "reproduce" pero silencio | decode AVP ❌ |
| Video | ❌ "reproduce" sin imagen NI sonido | decode AVP ❌ |
| Salir de FrogShell / emulador → menú | ❌ cuelga, **pantalla crema** | descarga de core / retorno al menú |
| ROMs recién instaladas | ✅ funcionan (FB/GB/etc.) | mmc/SD ✅ |

⇒ **Todo lo puramente Linux funciona; todo lo mediado por el AVP (audio en cualquier forma, decode de video) está muerto; y la salida de cores cuelga** (posible espera infinita en un servicio AVP).

# Diff dmesg fábrica ↔ nuestro (evidencia hard)

SOLO fábrica: `[decrypt_sector_data][1487] 0x0 0x0` ×3 (hook propietario ausente del SDK; 6l correcta), `NET: Registered protocol family 15`.
SOLO nuestro (extras vendor-baseline): **`i2c /dev entries driver`** (HC_I2C), **`IR NEC protocol handler`** (HC_IRC), ubi/watchdog (HC_NAND→UBI, HC_WDT), `squashfs`, bridge/TCP (HC_TOE), **`Warning: unable to open an initial console.`** (devtmpfs montado sobre /dev esconde el /dev/console del initramfs — factory usa /dev estático), `devpts: called with bogus options` (ptmxmode sin DEVPTS_MULTIPLE_INSTANCES en vendor baseline).

# Hipótesis 7c y build

**Hipótesis principal: HC_I2C (driver extra) claima el controlador I2C que el AVP usa para configurar el códec de audio** → audio muerto en todo; video_player cuelga esperando la pista de audio → sin imagen; descarga de cores puede colgarse en drain de audio → pantalla crema.

**BUILD 7c = lean-fábrica**: quitar `HC_I2C, HC_IRC, HC_WDT, HC_NAND, HC_TOE, HC_LVDS` (nadie los abre — fds diag6x; panel MIPI-DSI no LVDS; NOR es SPI-m25p80 no NAND); MANTENER `HC_GE` + `HC_HWSPINLOCK` (probados requeridos por el menú: 6w-vs-6x). uImage `15ad1cb72161900ce626b15693a976c28d08a5462949e508b8bb4fbad106f558`, 4,338,380 B, Load 0x80000000 / Entry 0x803DF5C0, initramfs CPIO CRUDO == stock (diff -r vacío), hcrc+dcrc VALIDOS. **STAGED en `D:\R36SX\staging\vmlinux.uImage-r36sx-v26-menu-7c` — NO desplegado** (la SD sigue con 6x `017adf3b`; stock.bak golden intacto).

`diag8.sh` desplegado a G:\ (interrupts/iomem/mmz/fds por proceso — correr con un video activo; también sirve de baseline bajo stock si 7c no cura).

# Próximos pasos (sesión siguiente)

1. Deploy 7c (protocolo verificado) → boot → test: ¿audio en juegos? ¿video con imagen+sonido? ¿salida de FrogShell/emuladores al menú?
2. Si 7c cura → documentar config lean-fábrica como baseline board; bisect opcional (confirmar I2C como causa).
3. Si 7c NO cura → diag8 con reproducción activa + boot stock.bak + diag8 baseline + comparar /proc/interrupts → serial ADR-011 como vía definitiva.
