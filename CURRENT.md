# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-19 (8f-RESULT: cubegm al mínimo NOR PHYSICAL PASS; FASE D "eliminar cubegm 100%" lanzada por decisión del usuario — D-1 dump NOR pendiente de ejecutar en consola)
**Regla:** snapshot pequeño, sin historia. No changelog.

## PROJECT

r36sx-hclinux — plataforma Linux/HCLinux reproducible para R36SX V2.6 (HC16xx/MIPS), TreeFrogUI estable, control total de kernel/DTB/rootfs/boot.

## CURRENT PHASE

**FASE D (bootloader propio → eliminar cubegm/ al 100%) — autorizada explícitamente por el usuario ("Intentémoslo") tras cerrar 8f (cubegm mínimo NOR = 4 archivos, PHYSICAL PASS).** Evidencia habilitante: NOR accesible desde nuestro Linux (MTD+M25P80, /dev/mtd0..3 vivos); HCFOTA = mecanismo oficial de reflash (flag persistentmem → hcboot se actualiza desde USB). Estadio: **D-1 (dump NOR) — script desplegado, espera ejecución del usuario.**

## CURRENT OBJECTIVE

1. **Usuario: ejecutar `sh /mnt/sdcard/nor-dump.sh` en FrogShell** (consola encendida, kernel 8e) → dump bit-a-bit de las 4 particiones NOR (16 MB) a la SD → traer la SD al PC.
2. Análisis del dump: partición del bootloader, DDR-init de fábrica (12.288 B), NOR-DTB real (confirmar external_files/path-prefix="cubegm").
3. D-2: build de nuestro hcboot (mkboot, defconfig bl) con path-prefix="boot" + DDR-init byte-exacto del dump.
4. D-3 (flash): SOLO tras verificar recuperación BootROM/USB + GO explícito. PROHIBIDO flashear sin red completa.

## CURRENT HEAD

`(ver git log -1 — caché)`

## KNOWN-GOOD STATE

- **SD física = instalación limpia definitiva + cubegm mínimo NOR**: kernel 8e `f8fb6768` + `treefrog/` stack + `cubegm/` {dtb.bin, avp.uImage, vmlinux.uImage, xgame-logo.bmp} + goldens + `diag.enabled` + `G:\nor-dump.sh`.
- Kernel físico: 8e (BUILD PASS, ABI fixes 9l/9m, S99app v2, S09trace v5.1, budget snd_xfer).
- Backup completo: `D:\R36SX\sd-clean-install-backup-20260918\sd-full.tar` (`963dfd23…`).
- cubegm: contrato NOR documentado (experimento 2026-09-19). La eliminación 100% = Fase D.

## BUILD STATUS

**R36SX-V26 KERNEL+ROOTFS OWN: BUILD PASS** (gates PASS). bootloader.bin propio = pendiente D-2 (ADR-086-caído: toolchain bare-metal disponible desde 9a).

## PHYSICAL STATUS

**TODO PHYSICAL PASS** (audio, video, salida, instalación limpia, cubegm mínimo). Bisect 8e + 8f completos con evidencia.

## SOURCE SDK SHA256

`e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` — /mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz

## ACTIVE BLOCKERS

Ninguno técnico. D-3 (flash NOR) = zona prohibida: requiere dump verificado + build validado + recuperación BootROM/USB probada + GO explícito del usuario en ese punto.

## NEXT EXACT ACTION

1. **Usuario: `sh /mnt/sdcard/nor-dump.sh` en la consola (FrogShell)** → traer la SD.
2. Yo: análisis del dump (particiones/DDR-init/NOR-DTB) + inicio D-2 (build hcboot).

## REFERENCIA RÁPIDA

| Subsistema | Ver |
|------------|-----|
| Caso cubegm + plan D | `docs/experiments/2026-09-19_cubegm-minimal-boot-contract.md` |
| Contrato TreeFrogUI (boot/ABI/layout) | `docs/TREEFROG_UI_CONTRACT.md` |
| Manuales vendor (flasheo/HCFOTA/bootchain) | `/mnt/d/GitHub/KERNEL/HCLINUX_OPENCODE_GUIDE.md` + `HCLINUX_MANUAL_MACHINE_READABLE.md` |
| ADR-012/013 | `DECISIONS.md` |
| Reglas (§5 hardware, §13 sync, §14 provenance) | `AGENTS.md` |
