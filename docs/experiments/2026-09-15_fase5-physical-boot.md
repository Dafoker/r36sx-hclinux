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

# Next action

- **EJECUTAR `diag.sh` en la consola (stock) y traer el log** → comparar dmesg/drivers stock vs nuestro vendor-config → identificar el driver/config faltante.
- Si el log stock muestra drivers que el vendor-config no tiene, recompilar con los fragmentos correctos (sin conjetura, guiado por el dmesg).
- Alternativa: serial (ADR-011) para el kernel r36sx-v26 si se requiere capturar el boot del kernel propio.
- NO recompilar más configs por conjetura sin dmesg/evidencia.
- (B) Script serial listo (ADR-011).

# Decision

- ADR pendiente: el config de fábrica no está en el SDK ni es extraíble → la única evidencia de causa raíz del boot parcial es dmesg/serial físico (a documentar en DECISIONS.md si se confirma hallazgo de hardware/config).