# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-19 (D-2b DONE: bootloader propio BUILD PASS + validación 9a completa; paquete D-2c desplegado en SD; PENDIENTE GO explícito del usuario para el flash del bootloader)
**Regla:** snapshot pequeño, sin historia. No changelog.

## PROJECT

r36sx-hclinux — plataforma Linux/HCLinux reproducible para R36SX V2.6 (HC16xx/MIPS), TreeFrogUI estable, control total de kernel/DTB/rootfs/boot.

## CURRENT PHASE

**FASE D — D-2b COMPLETO.** Bootloader propio construido y validado (método 9a): DDR-init de fábrica byte-exacto, NOR-DTB embebido path-prefix="boot", fallback dual-path compilado, módulo HCFOTA upgrade (SD) incluido. Paquete de flash desplegado en la SD: `/boot/` (copias idénticas de los 4 archivos) + imagen `bootloader-r36sx-v26-faseD2b.bin` (`1734c340…`) + `d2c_flash_bootloader.sh`. **ESPERA: GO explícito del usuario para D-2c (flash de /dev/mtd1).**

## CURRENT OBJECTIVE

1. **GO del usuario** → ejecuta `sh /mnt/sdcard/d2c_flash_bootloader.sh` en FrogShell → reboot → boot-1 (esperado: idéntico, ahora cargando desde /boot/ con fallback cubegm/).
2. Boot-2: swap `/boot/{dtb.bin, vmlinux.uImage}` por los builds nuevos (dtb "boot" + kernel eb0360ca) → reboot.
3. **D-3**: borrar `cubegm/` al 100% → boot-3 → caso cerrado.

## CURRENT HEAD

`(ver git log -1 — caché)`

## KNOWN-GOOD STATE

- **SD = instalación limpia + cubegm mínimo NOR — PHYSICAL PASS** (kernel 8e `f8fb6768`).
- **D-2a' PHYSICAL PASS**: mecanismo MTD probado (re-escritura bytes idénticos de fábrica + reboot OK).
- **bootloader.bin propio** (BUILD PASS + validado): DDR-init fábrica (d944d9af, campo tamaño dinámico), hcboot 413.216 B, NOR-DTB "boot", dual-path, upgrade SD. Imagen flash: staging + SD (`1734c340…`, 442.368 B pad 0xFF).
- Dump NOR (rollback): `D:\R36SX\nor-dump-20260919\` + nuestro build descomprimido + ambos NOR-DTB.
- Backup SD: `sd-full.tar` (`963dfd23…`).

## BUILD STATUS

**KERNEL+ROOTFS+BOOTLOADER OWN: BUILD PASS.** bootloader.bin 425.504 B < partición ✓. (Nota: el paso final "flash binary" falla por romfs/logo > eromfs — irrelevante: no flasheamos eromfs; bootloader.bin se genera antes.)

## PHYSICAL STATUS

**TODO PHYSICAL PASS previo.** D-2a' mecanismo MTD PASS. D-2c flash pendiente de GO.

## SOURCE SDK SHA256

`e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` — /mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz

## ACTIVE BLOCKERS

Ninguno técnico. **D-2c requiere GO explícito del usuario** (zona prohibida §5 — mitigado por: mecanismo probado D-2a' + dual-path + dump de rollback + DDR-init fábrica).

## NEXT EXACT ACTION

1. Usuario da GO → ejecuta `sh /mnt/sdcard/d2c_flash_bootloader.sh` en FrogShell (consola encendida, SD insertada) → ~2 min → reboot → reportar.
2. Con boot-1 PASS → boot-2 (swap dtb/kernel nuevos en /boot/) → boot-3 (D-3: borrar cubegm/).

## REFERENCIA RÁPIDA

| Subsistema | Ver |
|------------|-----|
| Caso cubegm + Fase D (4 addendums) | `docs/experiments/2026-09-19_cubegm-minimal-boot-contract.md` |
| bl defconfig + parche dual-path | `boards/r36sx-v26/bootloader/` + `patches/bootloader/0001` |
| Dump NOR + builds descomprimidos + NOR-DTBs | `D:\R36SX\nor-dump-20260919\` |
| Herramientas flash | `tools/mtdnor` + `tools/d2c_flash_bootloader.sh` |
| Reglas (§5 hardware, §13 sync, §14 provenance) | `AGENTS.md` |
