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

# Next action

STOP: decidir con el usuario entre (A) rollback inmediato (PASO 5) o (B) intentar capturar dmesg/serial con el kernel nuevo antes de restaurar. Recomendado: capturar diagnóstico si es posible, luego rollback para recuperar la consola.