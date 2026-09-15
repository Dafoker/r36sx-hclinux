# Evidencia: dmesg del kernel STOCK de fábrica (R36SX V2.6) — capturado vía FrogShell

**Fecha:** 2026-09-15 · **Método:** `scripts/diagnose_console.sh` ejecutado en FrogShell con TreeFrogUI stock (funciona).
**Kernel:** `Linux version 4.4.186-release (linsen.chen@hichip01) (gcc 6.3.0 Codescape 2018.09-02) #7 PREEMPT Thu Dec 18 16:55:03 CST 2025` — entry 0x803337c0.
**Uso:** referencia de lo que el kernel de fábrica crea/inicializa; comparar contra nuestro build vendor-config.

## Datos clave del dmesg stock

- **cmdline:** `root=/dev/ram0 rootfstype=ramfs rw init=/linuxrc console=tty1 earlycon= no_console_suspend noirqdebug` (== DTS stock).
- **RAM:** `0x0-0xaf91e4f` usable (175.57 MiB) — coincide con mapa stock.
- **CPU:** MIPS 74Kc, 1188MHz.
- **MTD (NOR):** 4 particiones: `nor`(0-0x80000) `boot`(0x0-0x6c000) `eromfs`(0x6c000-0x70000) `persistentmem`(0x70000-0x80000).
- **SD:** `mmcblk0` 59.5 GiB, p1 FAT.
- **fb0/fb1 enable**, hcge Init GE success, virtuart/kshmdev ok.
- **`[decrypt_sector_data][1487] 0x0 0x0`** (×2) — driver custom de fábrica de descifrado de sectores de SD. **NO está en SDK vendor** ni en nuestro kernel.
- **check_adc1, check_adc5** creados (name:check_adc1/5).
- **Procesos al final:** init, hcdaemon, `/mnt/sdcard/cubegm/icube`, rkgame, treefrog-zhijack.sh, cubevol, nosleep, picoarch frogshell_libretro.so — **UI TreeFrogUI completa arrancando**.

## /dev creados por el kernel stock (completos)

`ZZd2C, auddec, audsink, avsync0, backlight, check_adc1, check_adc5, console, dis, fb0, fb1, ge, hdmi, hdmi_rx, kshmdev, mem, mipi, mmcblk0/p1, mmz, mtd0-3, persistentmem, pq, sndC0i2si, sndC0i2so, sndC0spo, spidev32766.1, standby, ttyS0-3, tv_decoder, viddec, vidsink, vindvp, virtuart`

**Nota:** `/dev/input/` está VACÍO (no hay event0) — el input de esta consola NO pasa por /dev/input/event0.

## Análisis de devices vs config vendor

| Device stock | Config vendor r36sx-v26 | ¿driver activo? |
|---|---|---|
| backlight | avp-proxy vía DTS devname | SÍ (DTS idéntico) |
| standby | avp-proxy vía DTS devname | SÍ (DTS idéntico) |
| check_adc1/5 | CONFIG_CHECK_ADC=y | SÍ (re-build 08cced35) |
| dis/fb/ge/mmz/kshm/amprpc/i2so/auddec | =y | SÍ |
| ZZd2C | sin config | **NO — driver fábrica no en SDK** |
| decrypt_sector_data | sin config | **NO — driver fábrica no en SDK** |

## Interpretación

1. `/dev/backlight` y `/dev/standby` se crean vía **avp-proxy** leyendo `devname` del DTS (avp-proxy.c:691-704). Nuestro DTS es byte/semánticamente idéntico al stock → estos devices también se crean en nuestro kernel. **NO son la causa del menú que no carga.**
2. El kernel de fábrica contiene drivers custom (`decrypt_sector_data`, `ZZd2C`) **ausentes del SDK vendor**. Evidencia de divergencia fábrica vs SDK.
3. La causa del boot parcial (splash sí, menú no) con nuestro kernel NO es un device `/dev` faltante a nivel de config (todos los críticos están). Apunta a drivers de fábrica ausentes del SDK, o a un driver que requiere algo que el config vendor no provee.

## Próximo paso diagnóstico (no-ciego)

- **Capturar el dmesg del kernel r36sx-v26 PROPIO** (no stock) para comparar dónde se cuelga vs stock. Métodos: (a) serial USB-TTL + DTB de diagnóstico (ADR-011), o (b) si la consola con nuestro kernel llega a algún shell, ejecutar diag.sh.
- Verificar drivers de fábrica no-SDK (`decrypt_sector_data`, `ZZd2C`): buscar su función/efecto en el boot de la UI.