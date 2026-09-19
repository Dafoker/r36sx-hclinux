# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-19/20 (D-2a-RESEARCH: HCFOTA descartado como primera vía — bootloader de fábrica SIN módulo upgrade; PIVOTE a escritura MTD directa; herramientas D-2a' construidas y pendientes de desplegar)
**Regla:** snapshot pequeño, sin historia. No changelog.

## PROJECT

r36sx-hclinux — plataforma Linux/HCLinux reproducible para R36SX V2.6 (HC16xx/MIPS), TreeFrogUI estable, control total de kernel/DTB/rootfs/boot.

## CURRENT PHASE

**FASE D (eliminar cubegm/ 100%) — mecanismo de primera escritura RESUELTO: escritura MTD directa desde nuestro Linux.** El bootloader de fábrica (descomprimido del dump: "hcboot-custom" de `e3100_cube`) NO tiene módulo upgrade → HCFOTA solo servirá DESPUÉS de tener nuestro bootloader. NOR-DTB de fábrica extraído (path-prefix="cubegm" confirmado en el binario real). Herramientas listas: `tools/mtdnor` + `tools/d2a_flash_factory.sh`.

## CURRENT OBJECTIVE

1. **Desplegar mtdnor + d2a_flash_factory.sh a la SD** (pendiente: SD no estaba montada al cierre) → **usuario ejecuta D-2a'**: re-escritura de los bytes EXACTOS de fábrica sobre /dev/mtd1 con doble verificación → reboot → consola idéntica = mecanismo MTD PROBADO.
2. **D-2b**: habilitar BR2_TARGET_HCBOOT + bl defconfig dualcore + **patch fallback dual-path (/boot/ → cubegm/)** en apps-bootloader + DDR-init de fábrica (`d944d9af`) + DTB path-prefix="boot" → build → validación strings vs fábrica (método 9a).
3. **D-2c (GO explícito)**: crear /boot/ con los 4 archivos (cubegm intacto) → flash MTD + readback → reboot.
4. **D-3**: borrar cubegm/ al 100% → boot final.

## CURRENT HEAD

`(ver git log -1 — caché)`

## KNOWN-GOOD STATE

- **SD física = instalación limpia + cubegm mínimo NOR (4 archivos) — PHYSICAL PASS.** Kernel 8e `f8fb6768`.
- **Dump NOR verificado** `D:\R36SX\nor-dump-20260919\` (mtd0-3 + ddrinit-factory-12288.abs `d944d9af` + factory-hcboot-decompressed.bin + factory-nordtb-0.dtb + hashes; mtd1ro.bin sha `9fc95d7e`).
- Backup SD: `D:\R36SX\sd-clean-install-backup-20260918\sd-full.tar` (`963dfd23…`).
- Bootloader de fábrica descomprimido: LZMA @0x5e48 → 1.101.500 B (hcboot-custom e3100_cube, SIN upgrade).

## BUILD STATUS

**R36SX-V26 KERNEL+ROOTFS OWN: BUILD PASS.** `tools/mtdnor` MIPS32r2 estático BUILD PASS (610 KB). Pendiente D-2b: bootloader propio (BR2_TARGET_HCBOOT hoy `not set` en nuestro defconfig).

## PHYSICAL STATUS

**TODO PHYSICAL PASS** previo. D-1 dump ejecutado sin incidentes. D-2a' pendiente de ejecutar en consola.

## SOURCE SDK SHA256

`e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` — /mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz

## ACTIVE BLOCKERS

Ninguno técnico. Riesgo residual D-2c acotado por: D-2a' (mecanismo probado con bytes idénticos) + dual-path fallback + dump exacto + DDR-init byte-exacto.

## NEXT EXACT ACTION

1. Montar SD (`wsl --shutdown` si "No such device") → desplegar `tools/mtdnor` + `tools/d2a_flash_factory.sh` a la raíz.
2. Usuario: en FrogShell ejecutar `sh /mnt/sdcard/d2a_flash_factory.sh` → reboot → reportar (esperado: consola idéntica).
3. Con PASS: empezar D-2b (habilitar HCBOOT en el defconfig + patch dual-path + build).

## REFERENCIA RÁPIDA

| Subsistema | Ver |
|------------|-----|
| Caso cubegm + Fase D completa (addendum 3 = pivote MTD) | `docs/experiments/2026-09-19_cubegm-minimal-boot-contract.md` |
| Dump NOR + bootloader fábrica descomprimido + NOR-DTB | `D:\R36SX\nor-dump-20260919\` |
| Herramienta MTD | `tools/mtdnor.c` / `tools/mtdnor` / `tools/d2a_flash_factory.sh` |
| Manuales vendor | `/mnt/d/GitHub/KERNEL/HCLINUX_MANUAL_MACHINE_READABLE.md` |
| Reglas (§5 hardware, §13 sync, §14 provenance) | `AGENTS.md` |
