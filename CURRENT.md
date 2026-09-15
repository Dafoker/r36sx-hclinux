# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-15 (Iteración 6f — FASE 5 EN CURSO: causa raíz initramfs, kernel recompilado con rootfs embebido, re-test pendiente)
**Regla:** snapshot pequeño, sin historia. No changelog.

## PROJECT

r36sx-hclinux — plataforma Linux/HCLinux reproducible para R36SX V2.6 (HC16xx/MIPS), TreeFrogUI estable, control total de kernel/DTB/rootfs/build.

## CURRENT PHASE

**FASE 5 — SAFE PHYSICAL BOOT TEST EN CURSO** (autorizada por el usuario). PASO 0-3 completados y verificados. **BOOT FÍSICO PARCIAL** (criterio b PASS, c FAIL) documentado. **ROLLBACK (PASO 5) EJECUTADO Y VERIFICADO** — consola recuperada usable con stock. Pendiente: (C) investigar driver faltante en SDK, (B) preparar captura dmesg/serial para un futuro test.

## CURRENT OBJECTIVE

Completar Fase 5: backup SD hecho (PASO 1 Vía B) → verificar artefactos a desplegar (PASO 2) → preparar swap del kernel nuevo (PASO 3) → boot físico (PASO 4) → rollback si falla (PASO 5) → documentar y actualizar GitHub.

## CURRENT HEAD

`(ver git log -1 — caché)`

## KNOWN-GOOD STATE

- Fases 0–3 + 2.5 DONE (repo, SDK audit, baseline BUILD+PROVENANCE PASS, hardware físico).
- **Fase 4 DONE**: stock-normalized.dts versionado (roundtrip PASS); mapa memoria exacto (256=175.57 Linux+80.43 AVP); panel MIPI-DSI r63311 demostrado; 15 deltas formales (7 CRITICAL); board r36sx-v26: defconfig propio (8 cambios), DTS generado por script (verbatim stock + macros), **kernel BUILD PASS con DTB SEMÁNTICAMENTE IDÉNTICO al stock (allowlist 0)** y kernel config == vendor baseline (delta 0). Gates: DTB SEMANTIC + TOOLCHAIN + PATCH PROVENANCE = PASS.
- Artefactos r36sx-v26: `~/work/.../artifacts/r36sx-v26/` + `D:\R36SX\hclinux-builds\r36sx-v26-fase4b-20260914\` (vmlinux.uImage 2.58MiB 0x80000000/0x803e3200, dtb.bin == stock roundtrip 04fb8383...).

## BUILD STATUS

**R36SX-V26 STOCK-EQUIVALENT KERNEL: BUILD PASS** (+ provenance PASS). bootloader.bin ausente = esperado (ADR-008).

## PHYSICAL STATUS

**CAUSA RAÍZ ENCONTRADA + KERNEL RECOMPILADO CON INITRAMFS EMBEBIDO — RE-TEST PENDIENTE.**
- **CAUSA RAÍZ:** el kernel de fábrica de la R36SX **embebe su rootfs como initramfs dentro del vmlinux** (cpio `070701` + `etc/init.d/rcS` + `usr/bin/hcdaemon` verificados en el uImage stock). Nuestro build NO lo hacía (`BR2_TARGET_ROOTFS_INITRAMFS not set`, `CONFIG_BLK_DEV_INITRD not set`) → sin root, boot parcial/pantalla negra.
- **RE-BUILD HECHO:** `BR2_TARGET_ROOTFS_INITRAMFS=y` + `CONFIG_BLK_DEV_INITRD=y` + `CONFIG_INITRAMFS_SOURCE=rootfs.cpio`. vmlinux 78MB con initramfs. **uImage `004b2d50...` 13.7MB** (antes 2.7MB). Gates PASS (TOOLCHAIN/PATCH/DTB 0 diff).
- **RE-TEST FÍSICO PENDIENTE:** desplegar `D:\R36SX\staging\vmlinux.uImage-r36sx-v26-initramfs` (`004b2d50...`) en SD (dtb NO se toca), bootear. Debería arrancar como el stock y llegar al menú.
- **ADR-011:** diagnóstico serial requiere DTB serial-only NO-baseline (`scripts/diagnose_boot_serial.sh`). Cable USB-C OTG NO sirve (solo MTP/PTP).
- Backup golden: `~/backups/r36sx-sd-files-20260915.tar.gz` (sha256 `97086531ea...`).
- NOR/bootloader/AVP INTACTOS. Solo `vmlinux.uImage` en SD.

## SOURCE SDK SHA256

`e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` — /mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz

## CURRENT BOARD CANDIDATE

**r36sx-v26 = board propia CONFIRMADA** (stock-equivalent, ADR-010). D3100_v20 = pipeline baseline (upstream intacto).

## ACTIVE BLOCKERS

1. Ninguno en Fase 5 hasta PASO 3 (swap requiere autorización explícita para escribir en la SD /mnt/g).
2. Bare-metal mips32-mti-elf (AVP/hcboot propios) — privado (ADR-008; no bloquea nada actual).
3. Kernel config de fábrica (entry 0x803337c0) no incluido en SDK — usamos vendor SDK config (documentado).

## LAST VALIDATED ACTION

Fase 4 completa: DTB SEMANTIC PASS (0 diff) + TOOLCHAIN/PATCH PROVENANCE PASS + config delta 0 + artefactos hasheados en D:\. Experimento: docs/experiments/2026-09-14_r36sx-v26-board.md.

## NEXT EXACT ACTION

1. **RE-TEST FÍSICO del kernel con initramfs:** el usuario despliega `D:\R36SX\staging\vmlinux.uImage-r36sx-v26-initramfs` (`004b2d50...`) en `G:\cubegm\vmlinux.uImage` (backup `.stock.bak` ya existe; dtb.bin NO se toca), expulsa, bootea, y reporta si llega al menú (criterio c). Si PASS → Fase 5 boot resuelto; iterar hacia reemplazo total.
2. Si sigue fallando: ajustar el rootfs embebido (overlay del board, binarios de la SD) o capturar dmesg via serial (ADR-011).
3. Documentar y actualizar GitHub al cierre.

## REFERENCIA RÁPIDA

| Subsistema | Ver |
|------------|------|
| Reglas (§13 sync, §14 provenance) | `AGENTS.md` |
| Modelo stock / memoria / panel | `docs/DTS_STOCK_MODEL.md` |
| Deltas stock↔D3100 (15) | `docs/R36SX_D3100_DELTA.md` |
| Defconfig delta (8 cambios) | `docs/R36SX_DEFCONFIG_DELTA.md` |
| Direcciones (stock/baseline/r36sx) | `docs/BOOT_CHAIN.md` |
| Experimento Fase 4 | `docs/experiments/2026-09-14_r36sx-v26-board.md` |
