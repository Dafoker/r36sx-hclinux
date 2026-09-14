# docs/SDK_AUDIT.md — Auditoría del SDK HCLinux 2024.02.y.2

**Estado:** NO INICIADO — se completa en Fase 1 (Iteración 2).
**Fuente:** `/mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz` (SHA256 `e3211b41...45fbf8d5d`).

## Hipótesis a verificar (requisito §15) — plantilla

Cada claim debe quedar con: Claim / Evidence (ruta exacta dentro del SDK extraído) / Status (CONFIRMED | PARTIAL | DISPROVED).

| # | Hipótesis | Status |
|---|---|---|
| H1 | Arquitectura HC16xx/MIPS | PENDIENTE |
| H2 | Buildroot como sistema de build | PENDIENTE |
| H3 | Linux en core-main, HCRTOS/AVP en segundo núcleo | PENDIENTE |
| H4 | AMPRPC como puente Linux↔AVP | PENDIENTE |
| H5 | BSP en SOURCE/linux-drivers | PENDIENTE |
| H6 | Kernel 4.4.186 = baseline principal | PENDIENTE |
| H7 | Soporte/experimentos 5.12.4 presentes | PENDIENTE |
| H8 | DTS externo al kernel | PENDIENTE |
| H9 | U-Boot/hcboot bootloader | PENDIENTE |
| H10 | Generación de vmlinux.uImage | PENDIENTE |
| H11 | Memoria compartida Linux/AVP/MMZ | PENDIENTE |

## Estructura del SDK (a completar)

- Top-level tree: PENDIENTE
- Versión Buildroot: PENDIENTE
- Toolchains incluidos: PENDIENTE
- Defconfigs / board definitions: PENDIENTE
- DTS/DTSI: PENDIENTE
- Patches aplicados en build: PENDIENTE
- Rootfs/packaging/firmware layout: PENDIENTE
- Scripts de build: PENDIENTE

## Claims con evidencia

(vacío — se llena en Fase 1)
