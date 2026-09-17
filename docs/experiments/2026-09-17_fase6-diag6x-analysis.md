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

# Estado

PENDIENTE: usuario ejecuta `sh /mnt/sdcard/diag7.sh` en la consola, prueba video + salida de FrogShell con el bind activo, y trae la SD con el log. Si el bind manual confirma la causa → investigar por qué el mismo comando falla en el contexto S99app bajo nuestro kernel (y fix). Si el bind manual falla → errno guiará la causa kernel. Control alternativo si síntomas persisten con bind activo: boot con stock.bak + misma SD para atribuir kernel vs sync TreeFrogUI v1.5.0_j.
