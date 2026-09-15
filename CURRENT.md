# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-15 (Iteración 6i — FASE 5 EN CURSO: S11diag FIX + uImage 0fef5fd1 desplegado, re-test físico pendiente)
**Regla:** snapshot pequeño, sin historia. No changelog.

## PROJECT

r36sx-hclinux — plataforma Linux/HCLinux reproducible para R36SX V2.6 (HC16xx/MIPS), TreeFrogUI estable, control total de kernel/DTB/rootfs/build.

## CURRENT PHASE

**FASE 5 — SAFE PHYSICAL BOOT TEST EN CURSO** (autorizada por el usuario). PASO 0-3 completados y verificados. **BOOT FÍSICO PARCIAL** (criterio b PASS, c FAIL) documentado. **ROLLBACK (PASO 5) EJECUTADO Y VERIFICADO** — consola recuperada usable con stock. Pendiente: (C) investigar driver faltante en SDK, (B) preparar captura dmesg/serial para un futuro test.

## CURRENT OBJECTIVE

Completar Fase 5: backup SD (PASO 1 OK) → artefactos verificados (PASO 2 OK) → swap del kernel (PASO 3 OK, desplegado `0fef5fd1`) → **boot físico con S11diag** (PASO 4) para capturar dmesg del kernel propio → diagnosticar causa raíz del boot parcial → rollback si falla (PASO 5) → documentar y actualizar GitHub.

## CURRENT HEAD

`(ver git log -1 — caché)`

## KNOWN-GOOD STATE

- Fases 0–3 + 2.5 DONE (repo, SDK audit, baseline BUILD+PROVENANCE PASS, hardware físico).
- **Fase 4 DONE**: stock-normalized.dts versionado (roundtrip PASS); mapa memoria exacto (256=175.57 Linux+80.43 AVP); panel MIPI-DSI r63311 demostrado; 15 deltas formales (7 CRITICAL); board r36sx-v26: defconfig propio (8 cambios), DTS generado por script (verbatim stock + macros), **kernel BUILD PASS con DTB SEMÁNTICAMENTE IDÉNTICO al stock (allowlist 0)** y kernel config == vendor baseline (delta 0). Gates: DTB SEMANTIC + TOOLCHAIN + PATCH PROVENANCE = PASS.
- Artefactos r36sx-v26: `~/work/.../artifacts/r36sx-v26/` + `D:\R36SX\hclinux-builds\r36sx-v26-fase4b-20260914\` (vmlinux.uImage 2.58MiB 0x80000000/0x803e3200, dtb.bin == stock roundtrip 04fb8383...).

## BUILD STATUS

**R36SX-V26 STOCK-EQUIVALENT KERNEL: BUILD PASS** (+ provenance PASS). bootloader.bin ausente = esperado (ADR-008).

## PHYSICAL STATUS

**S11diag FIX + RE-TEST FÍSICO PENDIENTE (boot para capturar dmesg).**
- **CAUSA RAÍZ (confirmada):** el kernel de fábrica embebe su rootfs como initramfs en el vmlinux. Resuelto con initramfs del desarrollador embebido.
- **Bug encontrado y arreglado (6i):** S11diag corría en S11 (antes de S99app), cuando la SD aún no está montada. `LOG=/media/*/cubegm/dmesg_boot.log` (glob literal, sin expandir) fallaba → no capturaba dmesg. Reescrito con wait-loop (hasta 20s) esperando `/media/*/cubegm`.
- **uImage `0fef5fd1...`** 4,354,188 B (initramfs del desarrollador + S11diag fix, hcdaemon real 610KB). Gates TOOLCHAIN/PATCH/DTB SEMANTIC PASS. kernel.config `793a3ab7`. **Desplegado en G: `0fef5fd1...`** (stock.bak `53b3e0b3` intacto; dtb.bin/avp.uImage sin tocar).
- **RE-TEST FÍSICO PENDIENTE:** bootear la consola. Al arrancar, S11diag escribirá `G:\cubegm\dmesg_boot.log` con el dmesg del kernel propio. Traer la SD al PC y leerlo → comparar contra stock (`docs/experiments/evidence-stock-dmesg.md`) → identificar el driver/config que falta.
- Si NO se genera `dmesg_boot.log`: el kernel no llegó a rcS/initramfs (más grave; capturar via serial ADR-011, o revisar CONFIG_INITRAMFS_SOURCE).
- **ADR-011:** diagnóstico serial requiere DTB serial-only NO-baseline (`scripts/diagnose_boot_serial.sh`). Cable USB-C OTG NO sirve (solo MTP/PTP).
- Backup golden: `~/backups/r36sx-sd-files-20260915.tar.gz` (sha256 `97086531ea...`).
- NOR/bootloader/AVP INTACTOS. Solo `vmlinux.uImage` en SD (ahora `0fef5fd1`).
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

1. **BOOT FÍSICO DIAGNÓSTICO:** con la SD (kernel `0fef5fd1` + S11diag) insertada y expulsada limpiamente, bootear la consola R36SX. S11diag escribirá el dmesg a `G:\cubegm\dmesg_boot.log` (espera hasta 20s a que la SD se monte en `/media`). No hace falta que la UI llegue al menú: solo el boot hasta rcS.
2. **Traer la SD al PC** (G:), leer `G:\cubegm\dmesg_boot.log` y entregarlo al agente.
3. Comparar el dmesg del kernel propio contra el stock (`docs/experiments/evidence-stock-dmesg.md`) → identificar el driver/config que falta → re-build → re-test.
4. Si `dmesg_boot.log` NO se genera: el kernel no llegó a rcS/initramfs → serial ADR-011, o verificar que el initramfs se embebió (CONFIG_INITRAMFS_SOURCE → rootfs-dev.cpio).
5. Documentar y actualizar GitHub al cierre.
## REFERENCIA RÁPIDA

| Subsistema | Ver |
|------------|------|
| Reglas (§13 sync, §14 provenance) | `AGENTS.md` |
| Modelo stock / memoria / panel | `docs/DTS_STOCK_MODEL.md` |
| Deltas stock↔D3100 (15) | `docs/R36SX_D3100_DELTA.md` |
| Defconfig delta (8 cambios) | `docs/R36SX_DEFCONFIG_DELTA.md` |
| Direcciones (stock/baseline/r36sx) | `docs/BOOT_CHAIN.md` |
| Experimento Fase 4 | `docs/experiments/2026-09-14_r36sx-v26-board.md` |
