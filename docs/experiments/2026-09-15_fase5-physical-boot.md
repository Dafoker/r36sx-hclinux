# Experimento: 2026-09-15 — Fase 5: SAFE PHYSICAL BOOT TEST (parcial — boot incompleto)

# Objective

Demostrar que el vmlinux.uImage compilado en Fase 4B (board r36sx-v26 stock-equivalent) arranca en la R36SX V2.6 real, evaluando los 6 criterios PASS del protocolo.

# Hypothesis (Fase 5)

Kernel stock-equivalent (DTB idéntico al stock, config delta 0) bootea la consola hasta el menú TreeFrogUI con los 6 criterios PASS.

# Evidence — ejecución

## Swap (usuario, Windows)
- Backup local: `G:\cubegm\vmlinux.uImage.stock.bak` (stock `53b3e0b3...`)
- Copia: `D:\R36SX\staging\vmlinux.uImage-r36sx-v26-fase4b` → `G:\cubegm\vmlinux.uImage` (-Force)
- Verificación: `Get-FileHash` = `9821559DCEF0855CC9733618A0A35691187ED84200E5EA30B17FD67B7179F728` ✓ (== artefacto Fase 4B)
- `dtb.bin` SD NO se tocó (stock `1258f1eb...`). `avp.uImage`/rootfs/NOR INTACTOS.

## Boot físico (usuario, consola)
- Consola ENCIENDE.
- Muestra la imagen/splash de TreeFrogUI (fb0 inicializa — criterio b PASS).
- **NO llega al menú TreeFrogUI. NO navegable** — se queda tras el splash.

# Analysis

| Criterio | Estado | Fuente |
|---|---|---|
| a) kernel arranca sin panic/oops | PARCIAL (bootea, muestra splash) | consola |
| b) fb0 inicializa / algo en pantalla | PASS | splash TreeFrogUI visible |
| c) llega a init o prompt | **FAIL** | no llega al menú, no navegable |
| d) input responde | NO PROBADO | sin UI navegable |
| e) batería plausible | SIN DATOS | — |
| f) audio inicializa | SIN DATOS | — |

Fallo del criterio c) → el protocolo manda PASO 5 (rollback). Pendiente de diagnóstico (dmesg/serial) para identificar la causa raíz antes o después de restaurar.

# Hypothesis revision (pendiente de confirmar)

Candidatos a causa (hipótesis, NO confirmadas):
1. Entry del kernel: nuestro uImage Entry `0x803e3200` (config vendor SDK) vs stock fábrica `0x803337c0` (config no incluido en SDK) — el bootloader bootm usa el entry del header; podría diferir en init secuencia.
2. La UI TreeFrogUI requiere un driver/feature del kernel stock de fábrica no activado en el config vendor SDK (delta config 0 vs vendor, pero vendor ≠ fábrica).
3. Rootfs/AVP espera algo del kernel stock que nuestro build no entrega en runtime.
Requiere dmesg/serial para discriminar.

# Files changed (repo)

- docs/experiments/2026-09-15_fase5-physical-boot.md (este archivo)
- CHANGELOG.md, CURRENT.md (estado)

# Resultado (2026-09-15, tras boot parcial)

**ROLLBACK EJECUTADO Y VERIFICADO (PASO 5):**
- Restaurado `G:\cubegm\vmlinux.uImage` ← `vmlinux.uImage.stock.bak` (stock `53b3e0b3...`).
- `Get-FileHash` = `53B3E0B3D57FCDBEF40D448AE2D3A00159BC84F2FD5BE4C10A826827C7F2E01E` ✓.
- Consola vuelve a arrancar TreeFrogUI normal → **ROLLBACK OK**. Consola recuperada usable.

**Diagnóstico (opción B parcial, límite alcanzado):**
- El `vmlinux.bin` stock NO es ELF ni tiene `CONFIG_IKCONFIG` (0 matches IKCFG_ST) → **imposible extraer el `.config` de fábrica** desde el uImage stock. Comparación config-stock vs vendor NO viable por esta vía.
- Confirmado en SDK (post-build.sh + main.c): el bootloader `bootm` usa el entry del header uImage → nuestro `0x803e3200` es respetado (no es la causa; el kernel arrancó).
- El kernel SÍ arrancó (fb0 + splash TreeFrogUI) → fallo en la inicialización de UI/userspace tras el splash. Causa probable: config vendor SDK ≠ config fábrica (delta 0 vs vendor, pero vendor ≠ fábrica) → algún driver/feature de runtime que la UI requiere falta. No identificable sin dmesg/serial.

# Investigación C (2026-09-15) — driver faltante hipótesis fuerte

**Drivers /dev que la UI (driver_r36sx.so, icube, MyExecutable) abre:**
`/dev/fb0`, `/dev/fb1`, `/dev/dis`, `/dev/ge`, `/dev/backlight`, `/dev/input/event0`, `/dev/check_adc1`, `/dev/check_adc5`, `/dev/sndC0i2so`, `/dev/mmz`, `/dev/auddec`, `/dev/persistentmem`, `/dev/mipi`, `/dev/hdmi_tx`, `/dev/standby`.

**Config vendor (kernel.config r36sx-v26):** casi todos los drivers HC están `=y` (HC_DIS, HC_GE, HC_FB, HC_MMZ, HC_ADC, KEY_ADC, HC_I2SO, HC_AUDDEC, HC_AVPPROXY, HC_AMPRPC, HC_PERSISTENTMEM, HC_INPUT, GPIO_KEY, INPUT_EVDEV). **PERO `CONFIG_CHECK_ADC is not set`** (igual en baseline d3100 — default vendor).

**Hallazgo crítico — `CONFIG_CHECK_ADC`:**
- DTS stock declara nodos `check_adc0..5@18818400` y `adc-bat-level="/dev/check_adc1"`, `adc-bat-charging="/dev/check_adc5"`.
- `drivers/hcdrivers/adc/hc_check_adc.c:273` crea `check_adc%d` vía `device_create(MKDEV...)`; se enlaza por `of_match_table "hc16xx-check-adc"`.
- Con `CONFIG_CHECK_ADC is not set`, el driver NO se compila → `/dev/check_adc1` y `/dev/check_adc5` NO se crean.
- La UI (`driver_r36sx.so`) abre `/dev/check_adc1` (batería) y `/dev/check_adc5` (charging). Si el open falla, la UI puede quedarse en splash o abortar → **explicaría el boot parcial** (splash sí, menú no).
- El kernel de fábrica probablemente tenía `CONFIG_CHECK_ADC=y` (el DTS stock declara los nodos y la UI los usa).

**HIPÓTESIS PRINCIPAL (accionable, bajo riesgo):** habilitar `CONFIG_CHECK_ADC=y` en el defconfig kernel r36sx-v26, recompilar, y re-probar. El driver es del SDK (hcdrivers), ya presente en el árbol; solo falta activarlo. NO toca DTB/bootloader/AVP/NOR.

# Re-build CONFIG_CHECK_ADC=y (2026-09-15, después del hallazgo C)

**KERNEL RECOMPILADO con `CONFIG_CHECK_ADC=y`:**
- Mecanismo reproducible: fragmento `boards/r36sx-v26/kernel/r36sx-v26.config.fragment` (`CONFIG_CHECK_ADC=y`) referenciado en `BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES` del defconfig Buildroot. `build_kernel.sh` copia el fragmento al workspace SDK. **NO modifica el vendor config base** (`kernel-squashfs.config` intacto).
- Build PASS (~12 min; error final `bootloader.bin not found` = esperado ADR-008).
- Gates: **TOOLCHAIN PASS, PATCH PASS, DTB SEMANTIC PASS (0 diff)**.
- `.config` build: `CONFIG_HC_ADC=y`, `CONFIG_KEY_ADC=y`, **`CONFIG_CHECK_ADC=y`** (antes `not set`).
- **vmlinux.uImage NUEVO:** `08cced35fc3b90ba1e1ce3a4387c536bbfe0b500a6e31d5f665d4624f78d5673`, Load `0x80000000`, Entry `0x803E3AA0` (gzip, 2,700,962 B). dtb.bin `04fb8383...` (== stock, sin cambios).
- Artefactos: `~/work/r36sx-hclinux/artifacts/r36sx-v26/` (SHA256SUMS 7/7 OK). Staging: `D:\R36SX\staging\vmlinux.uImage-r36sx-v26-fase4b-checkadc`.

# RE-TEST FÍSICO (2026-09-15) — FALLÓ igual

**Despliegue del kernel CONFIG_CHECK_ADC=y (`08cced35...`) y boot:**
- La consola sigue quedándose en la **pantalla de inicio/splash** sin llegar al menú TreeFrogUI. Mismo síntoma que el boot parcial original.
- **CONCLUSIÓN: `CONFIG_CHECK_ADC=y` SOLO NO era la causa raíz** (o no es la única). Hipótesis C REFUTADA como causa única.
- **ROLLBACK EJECUTADO y verificado:** `G:\cubegm\vmlinux.uImage` restaurado a stock `53b3e0b3...` (desde `.stock.bak`), verificado por WSL y Windows. Consola usable.

**Nuevo hallazgo (no concluyente, requiere evidencia):** la UI abre `/dev/backlight`, pero el config vendor tiene `CONFIG_FB_BACKLIGHT is not set` y `CONFIG_BACKLIGHT_LCD_SUPPORT is not set`. Podría ser otra causa, PERO sin la config de fábrica ni dmesg no se puede confirmar sin conjeturar. **NO actuar a ciegas: se requiere dmesg via serial (ADR-011) para diagnóstico definitivo.**

**Dato clave de diagnóstico:** no hay logs de boot en la SD (menu.log es binario de 1980, no se reescribe; no hay dmesg guardado). La única evidencia de causa raíz es **dmesg por serial** (DTB serial-only + cable USB-TTL, ADR-011).

# Diagnóstico vía FrogShell (2026-09-15) — NUEVA VÍA NO-CIEGA

**El usuario puede entrar a FrogShell (file manager/terminal) con TreeFrogUI STOCK (que funciona).** Esto permite capturar el **dmesg del kernel de fábrica** y la lista real de `/dev`/drivers que crea — la comparación definitiva contra nuestro vendor-config, sin cable serial.

**`scripts/diagnose_console.sh`** — script de diagnóstico para ejecutar EN la consola (busybox ash):
- Recopila: cmdline, **dmesg completo**, `/dev/` y `/dev/input/`, `/proc/modules`, `/proc/mtd`, `/sys/class` (backlight/input/graphics), `/dev/kshm`, check_adc, **DTS cargado (`/proc/device-tree` status de backlight/check_adc/pwm/uart)**, `/proc/iomem`, procesos.
- Escribe a `/mnt/sdcard/cubegm/diag_*.log` (accesible desde el PC).
- Copiado a la SD como `G:\diag.sh` (`/mnt/sdcard/diag.sh`), sha256 `f3493241...`.

**USO:**
1. Con TreeFrogUI stock, entrar a FrogShell.
2. Ejecutar: `sh /mnt/sdcard/diag.sh`
3. Recoger `G:\cubegm\diag_*.log` del PC.
4. El dmesg stock revela: qué drivers crean los `/dev` de la UI, el config efectivo, y si algún driver requerido (backlight PWM, check_adc, dis, ge, amprpc) está activo en fábrica.

**IMPORTANTE:** ejecutar con STOCK captura el estado de referencia (funciona). La comparación contra nuestro kernel identifica el driver/config faltante de forma no-ciega.

# RESULTADO diag.sh en STOCK (2026-09-15) — dmesg de fábrica capturado

**`scripts/diagnose_console.sh` ejecutado en FrogShell con TreeFrogUI stock (funciona).** Evidencia completa en `docs/experiments/evidence-stock-dmesg.md`.

**Hallazgos del dmesg stock:**
1. **`/dev/backlight` y `/dev/standby` se crean vía `avp-proxy`** leyendo `devname` del DTS (avp-proxy.c:691-704: `of_property_read_string("devname")` + `alloc_chrdev_region`). Nuestro DTS es idéntico al stock (DTB SEMANTIC PASS) → **estos devices también se crean en nuestro kernel. NO son la causa.**
2. **Kernel de fábrica tiene drivers custom NO en SDK:** `decrypt_sector_data` (×2 en dmesg) y `ZZd2C`. Evidencia de divergencia fábrica vs SDK.
3. Config vendor crea los /dev críticos (dis/fb/ge/mmz/kshm/amprpc/i2so/auddec/check_adc) — todos =y.
4. `/dev/input/` VACÍO en stock (input no via event0).
5. Stock corre UI completa: icube, rkgame, cubevol, nosleep, picoarch frogshell, hcdaemon.

**CONCLUSIÓN:** el boot parcial (splash sí, menú no) con nuestro kernel NO se explica por un `/dev` faltante a nivel de config (todos los críticos están, backlight/standby via avp-proxy DTS idéntico). Causa probable: drivers de fábrica ausentes del SDK, o un driver que exige algo del config de fábrica no reproducido.

# Intento de diagnóstico por inyección (S50diag) — REVERTIDO (2026-09-15)

**Se intentó inyectar `S50diag` en `G:\rootfs\etc\init.d\` para capturar el dmesg del kernel r36sx-v26 automáticamente.** Resultado del test #3: **pantalla negra** (ni splash ni menú) y **NO se generó diag log** → `rcS` no llegó a ejecutar S50diag, o S50diag interfirió.

**REVERSIÓN COMPLETA:** `S50diag` borrado del rootfs + kernel restaurado a stock `53b3e0b3...` (verificado WSL + Windows `Test-Path False`). SD limpia y usable.

**Inconsistencia observada:** tests #1/#2 (kernel r36sx-v26 sin S50diag) mostraron SPLASH (kernel llega a userspace) pero test #3 (con S50diag) dio PANTALLA NEGRA. Esto sugiere boot inestable o que S50diag (busybox `$()`/date) interfirió. La inyección de scripts en rcS NO es una vía fiable aquí — descartada.

# Exploración de cubegm (SO del desarrollador) — punto de bifurcación

**El usuario propuso que el punto de bifurcación R36SX v2.6 está en `cubegm/`.** Hallazgos:
- **`modules/4.4.186-release/`** contiene solo `usb_f_mass_storage.ko` y `usb_f_mtp.ko` (gadget USB). El resto del kernel de fábrica es **monolithic** (drivers en vmlinux, no .ko).
- **`driver.so` == `driver_r36sx.so`** (hash idéntico `58b180a2`). La UI usa `driver.so` genérico; `driver_r36sx.so` NO difiere. Los `/dev` que abre son los estándar HiChip (auddec, backlight, check_adc1, dis, fb0, ge, input/event0, mem, mmz, persistentmem, sndC0i2so, standby). `setting.xml` `<autorun driver="" />` (vacío → usa driver.so).
- **Conclusión:** la bifurcación R36SX NO está en un driver .so de la UI ni en módulos. La UI depende de los `/dev` estándar HiChip. El kernel de fábrica es monolithic; la bifurcación R36SX v2.6 está en la **config del kernel + DTB**, no en drivers userland.
- **Comparación de compatibles:** nuestro kernel compila MÁS drivers que el stock (spi, nfc, i2c, watchdog, lvds, irc, hwspinlock) porque el config vendor es genérico de todas las boards. El stock es más específico. NO es un driver faltante.

**Estado del diagnóstico de inyección:** S50diag (kernel r36sx-v26) NO generó `diag_boot_*.log` → el kernel r36sx-v26 no llegó a rcS en el test #3 (pantalla negra). Pero tests #1/#2 (sin S50diag) SÍ mostraron splash → el kernel SÍ llega a userspace cuando S50diag no interfiere. El `diag_19700101_000030.log` en cubegm es del STOCK (FrogShell), no del kernel propio.

# CAUSA RAÍZ ENCONTRADA — el kernel de fábrica embebe su rootfs (initramfs) (2026-09-15)

**Hallazgo definitivo (análisis del vmlinux.uImage stock):**

| | Kernel STOCK | Kernel r36sx-v26 (nuestro) |
|---|---|---|
| initramfs embebido (cpio `070701`) | **SÍ** (382 hits) | **NO** (0) |
| `etc/init.d/rcS` en vmlinux | **SÍ** (offset 5097761) | **NO** |
| `linuxrc`/`inittab` embebidos | **SÍ** | **NO** |
| `CONFIG_BLK_DEV_INITRD` | habilitado (evidencia initramfs) | `# not set` |
| Boot result | OK (root embebido) | falla (sin root) |

**Interpretación:** el kernel de fábrica usa initramfs embebido (`CONFIG_INITRAMFS_SOURCE` → rootfs). El rootfs de la SD (`G:\rootfs\`) coincide con el initramfs embebido (mismos `S41hcdaemon`, `rcS`, `inittab`, `usr/bin/hcdaemon`). Nuestro build vendor-config NO embebe rootfs (`CONFIG_BLK_DEV_INITRD not set`, igual en el config base vendor) → `root=/dev/ram0 rootfstype=ramfs` no encuentra root → el kernel no arranca userspace → boot parcial/pantalla negra.

**Explica por qué S50diag/S01diag en `G:\rootfs\etc\init.d\` NO se ejecutaron:** el sistema corre el initramfs embebido en el vmlinux, no los scripts de la SD. La SD solo provee datos/UI (`cubegm`).

**La bifurcación R36SX v2.6 está aquí:** el config del kernel de fábrica habilita el initramfs embebido. El SDK vendor-config no.

**Solución propuesta (reemplazo total):** reconstruir kernel r36sx-v26 **embebiendo el initramfs** (CONFIG_INITRAMFS_SOURCE apuntando al rootfs, p.ej. el de la SD o uno propio) para replicar el arranque de fábrica.

# RE-BUILD CON INITRAMFS EMBEBIDO (2026-09-15) — solución a la causa raíz

**Kernel r36sx-v26 recompilado con initramfs embebido** (replica el arranque de fábrica):

**Cambios:**
1. **Defconfig:** `BR2_TARGET_ROOTFS_INITRAMFS=y` (selecciona CPIO automáticamente); `BR2_TARGET_ROOTFS_SQUASHFS` deshabilitado (no combinar initramfs + squashfs, nota del Config.in).
2. **Kernel fragment** (`boards/r36sx-v26/kernel/r36sx-v26.config.fragment`): `CONFIG_BLK_DEV_INITRD=y` + `CONFIG_RD_GZIP/BZIP2/LZMA/XZ/LZO=y` (mantiene `CONFIG_CHECK_ADC=y`).

**Resultado del build (BUILD PASS, gates PASS):**
- `.config`: `CONFIG_BLK_DEV_INITRD=y`, `CONFIG_INITRAMFS_SOURCE="${BR_BINARIES_DIR}/rootfs.cpio"`.
- `rootfs.cpio` generado (27,602,432 B) con `linuxrc`, `etc/init.d/rcS`, `S41hcdaemon`, `usr/bin/hcdaemon`, `etc/inittab`.
- `vmlinux` 78,091,628 B (antes 66.7MB) — contiene el initramfs (cpio `070701`, `linuxrc`).
- **Nuevo uImage `004b2d50...`**: Load `0x80000000`, Entry `0x803E4050`, gzip **13,671,987 B** (antes 2.7MB).
- Gates: **DTB SEMANTIC PASS (0 diff), TOOLCHAIN PASS, PATCH PASS**.
- Artefactos `~/work/r36sx-hclinux/artifacts/r36sx-v26/` 7/7 OK. Staging: `D:\R36SX\staging\vmlinux.uImage-r36sx-v26-initramfs`.

**Por qué esto resuelve el boot:** el kernel de fábrica embebe su rootfs como initramfs (evidencia: cpio + rcS + hcdaemon en el uImage stock). Nuestro build ahora lo replica → el kernel con `root=/dev/ram0` encuentra su root → arranca userspace → monta la SD → lanza la UI.

# RE-TEST #4 (initramfs sin S99app) — llegó al splash, NO al menú (2026-09-15)

**Test del kernel con initramfs `004b2d50...`:** la consola muestra la imagen TreeFrogUI pero **no llega al menú** (se queda estancada). AVANCE vs pantalla negra anterior (el initramfs permitió llegar a userspace), pero la UI no arranca.

**Causa identificada:** el initramfs embebido del build (Buildroot estándar) NO tenía el script **`etc/init.d/S99app`** que está en el initramfs stock del desarrollador. `S99app` es el que: espera la SD en `/media`, hace `mount --bind /media/<MNTDIR> /mnt/sdcard`, activa swap con `pagefile.sys`, y **lanza `/mnt/sdcard/cubegm/icube.sh`** (la UI). Sin él, nadie monta `/mnt/sdcard` ni lanza la UI → splash sin menú.

# RE-BUILD CON INITRAMFS DEL DESARROLLADOR (2026-09-15) — boot fiel de fábrica

**RE-TEST del kernel con S99app (`0ddcd33a...`) → SIGUIÓ en splash sin menú.** Análisis: el rootfs Buildroot embebido (27MB) usaba un `hcdaemon` **stub** (6,212 B) en vez del daemon real del desarrollador (610,404 B). El kernel de fábrica embebe un initramfs **minimal del desarrollador** (3.9MB) con su propia libc/busybox/hcdaemon.

**Solución aplicada — usar el initramfs DEL DESARROLLADOR como rootfs embebido:**
- Extraído el initramfs stock completo (cpio 3,852,472 B → 380 archivos) al rootfs-overlay de la board.
- `CONFIG_INITRAMFS_SOURCE` apunta a `rootfs-dev.cpio` (3,849,216 B, hcdaemon real 610KB, S99app, libc/busybox del desarrollador).
- `BR2_TARGET_ROOTFS_INITRAMFS` desactivado (Buildroot no sobreescribe CONFIG_INITRAMFS_SOURCE).
- `build_kernel.sh` genera rootfs-dev.cpio desde el overlay.

**Resultado (BUILD PASS, gates PASS):**
- **uImage `707fcec8...`**: Load `0x80000000`, Entry `0x803E4050`, gzip **4,352,104 B** (initramfs minimal del desarrollador, vs 13.7MB del Buildroot).
- Gates: **DTB SEMANTIC PASS (0 diff), TOOLCHAIN PASS, PATCH PASS**.
- Artefactos 7/7 OK. Staging: `D:\R36SX\staging\vmlinux.uImage-r36sx-v26-devrootfs`.

**Por qué debería funcionar:** ahora el kernel embebe el MISMO rootfs que el stock (initramfs del desarrollador con hcdaemon real), con NUESTRO kernel (config + DTB + compilación). El arranque replica el de fábrica.

# Next action

- **RE-TEST FÍSICO:** desplegar `vmlinux.uImage-r36sx-v26-devrootfs` (`707fcec8...`) en SD (dtb NO se toca), bootear. Con el initramfs del desarrollador + nuestro kernel, la UI debería llegar al menú.
- Si llega al menú → Fase 5 boot RESUELTO (kernel propio + rootfs del desarrollador). Avanzar a reemplazo total (rootfs propio).
- Si aún falla → dmesg via serial (ADR-011) o comparar config del kernel de fábrica.
- (B) Script serial listo (ADR-011) como respaldo.

# Decision

- ADR pendiente: el config de fábrica no está en el SDK ni es extraíble → la única evidencia de causa raíz del boot parcial es dmesg/serial físico (a documentar en DECISIONS.md si se confirma hallazgo de hardware/config).
---

# S11diag FIX + RE-BUILD (2026-09-15, Iteración 6i) — re-test diagnóstico listo

## Bug en S11diag (bloqueante) detectado al preparar el re-test físico

El plan era desplegar `f5319159...` (initramfs dev + S11diag) y leer `G:\cubegm\dmesg_boot.log`. Al auditar la secuencia de arranque del initramfs se detectó un **bug que habría desperdiciado el test físico**:

- **S10mdev** solo monta tmpfs en `/media` y prepara devtmpfs; **NO monta la SD**.
- La SD se monta **asíncronamente** vía mdev hotplug en `/media/<subdir>`; **S99app** la espera con `wait_for_media_ready()` (bucle buscando `/media/$subdir/cubegm/icube`) y luego hace `mount --bind /media/$MNTDIR /mnt/sdcard`.
- Por tanto en **S11diag** (que corre justo después de S10, antes de S99app) NI `/mnt/sdcard` NI `/media/*/cubegm` existen todavía.

El S11diag original hacía:
```
LOG=/media/*/cubegm/dmesg_boot.log
```
Ese glob está **entre comillas → no se expande** → el `> "$LOG"` intenta crear el path literal `/media/*/cubegm/dmesg_boot.log`, que no existe como directorio → **el redirect falla → no se escribe dmesg**. Test físico desperdiciado.

## Fix aplicado (boards/r36sx-v26/rootfs-overlay/etc/init.d/S11diag)

Reescrito con wait-loop que espera a que mdev monte la SD en `/media/*/cubegm` (hasta 40×0.5s = 20s), espejo de la lógica de S99app:

```
LOG=""
n=0
while [ $n -lt 40 ]; do
    for subdir in /media/*/cubegm; do
        if [ -d "$subdir" ]; then LOG="$subdir/dmesg_boot.log"; break 2; fi
    done
    n=$((n + 1)); sleep 0.5
done
[ -z "$LOG" ] && LOG=/tmp/dmesg_boot.log
{ ... dmesg ... } > "$LOG" 2>&1
```

## Re-build (BUILD PASS, gates PASS)

- `./scripts/build_kernel.sh r36sx-v26` → regenera `rootfs-dev.cpio` desde el overlay (incluye S11diag fix).
- **uImage `0fef5fd1...`** 4,354,188 B — Load `0x80000000`, Entry `0x803E4050` (gzip).
- Verificado: extraído el initramfs interior del uImage → `etc/init.d/S11diag` embebido == fuente fija (diff MATCH, wait-loop presente); `usr/bin/hcdaemon` real (610,404 B); `S99app` presente.
- Gates: **TOOLCHAIN PASS, PATCH PASS (41/41), DTB SEMANTIC PASS (0 diff)**. kernel.config `793a3ab7` (BLK_DEV_INITRD/CHECK_ADC/INITRAMFS_SOURCE=rootfs-dev.cpio).
- dtb.bin build `04fb8383...` (stock-equivalente, no se despliega — el de SD `1258f1eb...` se mantiene).

## Deploy (autorizado) + verificación

- `G:\cubegm\vmlinux.uImage` ← **`0fef5fd1...`** (sobreescribe el `f5319159...` previo, también no-stock).
- `vmlinux.uImage.stock.bak` = `53b3e0b3...` **intacto** (golden).
- `dtb.bin` = `1258f1eb...` **sin tocar**. `avp.uImage` = `a9788995...` **sin tocar**. NOR/bootloader/AVP INTACTOS.
- Backup SD: `~/backups/r36sx-sd-files-20260915.tar.gz` (`97086531ea...`).
- Staging: `D:\R36SX\staging\vmlinux.uImage-r36sx-v26-devrootfs-s11diag-fixed`.

## RE-TEST FÍSICO (pendiente — próximo paso)

1. Expulsar SD de forma segura; insertar en la consola; bootear. S11diag escribirá `G:\cubegm\dmesg_boot.log`.
2. Traer la SD al PC; leer `G:\cubegm\dmesg_boot.log` y entregarlo.
3. Comparar dmesg del kernel propio vs stock (`evidence-stock-dmesg.md`) → identificar driver/config faltante.
4. Si `dmesg_boot.log` NO se genera → el kernel no llegó a rcS/initramfs (serial ADR-011, o revisar CONFIG_INITRAMFS_SOURCE).

# Decision

- **S11diag corregido y desplegado como herramienta de diagnóstico no-ciega.** El próximo boot físico capturará el dmesg del kernel propio para discriminar la causa raíz del boot parcial sin serial.
- Re-test físico pendiente de ejecución por el usuario (STOP CONDITION §5/§10: boot físico + lectura de SD).


---

# RE-TEST FÍSICO #1 (2026-09-15, Iteración 6j) — sin dmesg; hipótesis kernel-mmc; S11diag v2

## Resultado del boot del kernel 0fef5fd1 (S11diag v1)

- Usuario: 1ª vez **pantalla negra**; tras esperar, **reboot** → **splash TreeFrogUI sin menú**.
- **NO se generó `G:\cubegm\dmesg_boot.log`** (verificado por WSL: el archivo no existe).
- `G:\cubegm\vmlinux.uImage` seguía = `0fef5fd1` (nuestro kernel seguía desplegado).

## Análisis del mecanismo de montaje (initramfs dev)

- `etc/mdev.conf`:
  - `mmcblk[0-9]p[0-9]  0:0 664 */etc/mdev/mount-helper.sh`
- `etc/mdev/mount-helper.sh`: blkid del device + `mount ... /media/<tipo>`.
- `S99app.wait_for_media_ready()`: bucle infinito hasta que existe `/media/<subdir>/cubegm/icube`; luego `mount --bind /media/$MNTDIR /mnt/sdcard` y lanza `icube.sh`.
- S10mdev: monta tmpfs en /media + `mdev -s` + uevent_helper=/sbin/mdev.

**Conclusión:** tanto S11diag v1 (espera `/media/*/cubegm` 20s) como S99app (espera `/media/*/cubegm/icube` para siempre) dependen de que **la SD se monte en `/media`** vía mdev→mount-helper. Como ni el log ni el menú aparecieron, **la SD no se montó**. Dado que el config del kernel SÍ tiene MMC_DW/VFAT/HC_SDIO y el DTB es semánticamente idéntico al stock, la hipótesis más fuerte es que **el kernel mmc de nuestro build no detecta/inicializa la SD en runtime** (driver/config del controlador difiere del de fábrica).

## S11diag v2 (montaje manual + diagnóstico mmc)

Para (a) confirmar la hipótesis y (b) obtener el dmesg aunque mdev falle, S11diag v2:
1. Captura dmesg + estado (mmc/sysfs/input/fb/dtb/mtd/iomem/modules) a `/tmp/dmesg_boot.log` SIEMPRE.
2. Espera `/media/*/cubegm` hasta 30s.
3. Si no aparece, **monta manualmente** `/dev/mmcblk0p1` (y variantes) a `/tmp/sd` y copia ahí.
4. Escribe progreso a `/dev/console`.

## Re-build + deploy

- **uImage `6d44c1b7...`** 4,354,009 B. S11diag v2 verificado embebido (diff MATCH vs fuente).
- Desplegado en `G:\cubegm\vmlinux.uImage = 6d44c1b7...`. `stock.bak 53b3e0b3` intacto; `dtb.bin 1258f1eb` y `avp.uImage a9788995` sin tocar. Backup SD presente.
- Staging: `D:\R36SX\staging\vmlinux.uImage-r36sx-v26-devrootfs-s11diag-v2`.

## RE-TEST FÍSICO #2 (pendiente)

Bootear la consola con `6d44c1b7`; S11diag v2 escribirá `G:\cubegm\dmesg_boot.log`. Al leerlo: verificar si aparece `mmcblk0`/`mmcblk0p1` y si hay errores del controlador MMC/SDIO → confirmar o refutar la hipótesis kernel-mmc.
