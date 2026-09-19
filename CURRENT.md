# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-19 (D-1 DONE: dump NOR verificado + layout mapeado + DDR-init de fábrica extraído + mecánica HCFOTA completa — camino a cubegm 0%)
**Regla:** snapshot pequeño, sin historia. No changelog.

## PROJECT

r36sx-hclinux — plataforma Linux/HCLinux reproducible para R36SX V2.6 (HC16xx/MIPS), TreeFrogUI estable, control total de kernel/DTB/rootfs/boot.

## CURRENT PHASE

**FASE D (eliminar cubegm/ 100% vía bootloader propio) — D-1 COMPLETO.** Dump NOR bit-a-bit verificado (`D:\R36SX\nor-dump-20260919\`), layout mapeado (boot 0x0-0x6C000 / eromfs 0x6C000 / persistentmem 0x70000), DDR-init de fábrica extraído byte-exacto (`d944d9af…` — no coincide con ningún SDK), HCFOTA soporta modo `sd` (flash desde la SD), empaquetado = `HCFota_Generator`. **Siguiente: D-2** (build + validación en escalera).

## CURRENT OBJECTIVE

1. **D-2a (probar el MECANISMO sin riesgo funcional)**: empaquetar el bootloader de FÁBRICA exacto (bytes del dump) como HCFOTA.bin → flash vía hcfota reboot sd → la consola debe re-arrancar idéntica → mecanismo PROBADO.
2. **D-2b**: cambiar DTS `path-prefix="cubegm"`→`"boot"` + rebuild (mkboot/mkall + HCFota_Generator withboot, DDR-init de fábrica) + validar strings vs fábrica (método 9a) → flash → boot desde /boot/ → mover archivos → **borrar cubegm/ al 100%**.
3. Requisito pendiente: herramienta `hcfota` userspace MIPS (SOURCE/hcfota, meson) para nuestro rootfs (o trigger manual del flag OTA).

## CURRENT HEAD

`(ver git log -1 — caché)`

## KNOWN-GOOD STATE

- **SD = instalación limpia + cubegm mínimo NOR (4 archivos) — PHYSICAL PASS.** Kernel 8e `f8fb6768`.
- **Dump NOR (rollback exacto de fábrica)**: `D:\R36SX\nor-dump-20260919\` — mtd0-3 + `ddrinit-factory-12288.abs` + hashes.
- Backup SD completo: `D:\R36SX\sd-clean-install-backup-20260918\sd-full.tar` (`963dfd23…`).
- Goldens: stock.bak `53b3e0b3`, avp `a9788995` (en SD), NOR dump (en D:).

## BUILD STATUS

**R36SX-V26 KERNEL+ROOTFS OWN: BUILD PASS.** Pendiente D-2: bootloader.bin propio (hcboot + path-prefix="boot" + DDR-init de fábrica) + HCFOTA.bin (withboot).

## PHYSICAL STATUS

**TODO PHYSICAL PASS** (audio/video/salida/clean-install/cubegm-mínimo). D-1 dump ejecutado en consola sin incidentes.

## SOURCE SDK SHA256

`e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` — /mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz

## ACTIVE BLOCKERS

Ninguno técnico. D-3 (flash) pendiente de: D-2a (mecanismo probado) + build validado + GO explícito del usuario. El riesgo de brick queda mitigado por: DDR-init byte-exacto + mecanismo oficial HCFOTA + dump NOR de rollback (restaurable por JTAG/HCPROGRAMMER usbdevice si hiciera falta).

## NEXT EXACT ACTION

1. Estudiar `HCFota_Generator` + `hcprog.ini` (formato de empaquetado HCFOTA.bin).
2. D-2a: empaquetar bootloader de fábrica (del dump) → flash prueba-mecanismo → boot esperado idéntico (con el usuario).
3. D-2b: DTS path-prefix→"boot" + rebuild completo + validación + flash → cubegm/ 100% fuera.

## REFERENCIA RÁPIDA

| Subsistema | Ver |
|------------|-----|
| Caso cubegm + Fase D (plan completo) | `docs/experiments/2026-09-19_cubegm-minimal-boot-contract.md` |
| Dump NOR + DDR-init | `D:\R36SX\nor-dump-20260919\` |
| Manuales vendor (HCFOTA/bootchain) | `/mnt/d/GitHub/KERNEL/HCLINUX_MANUAL_MACHINE_READABLE.md` §16.17 |
| Contrato TreeFrogUI | `docs/TREEFROG_UI_CONTRACT.md` |
| Reglas (§5 hardware, §13 sync, §14 provenance) | `AGENTS.md` |
