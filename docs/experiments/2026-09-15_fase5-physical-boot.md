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

# Next action

- (C) Investigar en SDK qué drivers/features requiere TreeFrogUI (input key_adc3, audio, amprpc/AVP, fb) que nuestro vendor-config pueda no proveer. Comparar símbolos de nuestro kernel vs requeridos.
- (B) Crear script de captura serial/dmesg para ejecutar con kernel nuevo vía cable USB OTG/C USB-C, para obtener evidencia decisiva en un futuro test.

# Decision

- ADR pendiente: el config de fábrica no está en el SDK ni es extraíble → la única evidencia de causa raíz del boot parcial es dmesg/serial físico (a documentar en DECISIONS.md si se confirma hallazgo de hardware/config).