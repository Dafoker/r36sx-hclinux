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

# Next action

- **Recompilar kernel r36sx-v26 con `CONFIG_CHECK_ADC=y`** (y verificar si hay más drivers requeridos deshabilitados en vendor-config: p.ej. revisar los demás `/dev` de la UI contra config) y re-probar el boot físico.
- (B) `scripts/diagnose_boot_serial.sh` generó DTB de diagnóstico serial-only (ADR-011) para capturar dmesg vía USB-TTL (hc_uart@18818600, 115200 8N1) si se requiere confirmación directa.

# Decision

- ADR pendiente: el config de fábrica no está en el SDK ni es extraíble → la única evidencia de causa raíz del boot parcial es dmesg/serial físico (a documentar en DECISIONS.md si se confirma hallazgo de hardware/config).