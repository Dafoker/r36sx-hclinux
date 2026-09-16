# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-15 (Iteración 6j — FASE 5 EN CURSO: re-test #1 sin dmesg (inferencia kernel mmc), S11diag v2 montaje manual, uImage 6d44c1b7 desplegado, re-test #2 pendiente)
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

**RE-TEST #1 (0fef5fd1) — NO dmesg. Hipótesis kernel-mmc. S11diag v2 desplegado, RE-TEST #2 pendiente.**
- **Resultado RE-TEST #1:** boot `0fef5fd1` (S11diag v1) → 1ª vez pantalla negra, reboot → splash TreeFrogUI sin menú. **NO se generó `dmesg_boot.log`** (confirmado en G:).
- **Inferencia (no conjetura):** S11diag v1 esperaba `/media/*/cubegm` 20s; S99app espera `/media/*/cubegm/icube` para siempre. Ambos dependen de que la SD se monte en `/media` vía mdev→mount-helper.sh. Como ni el log ni el menú aparecen, **la SD no se monta** → candidato: kernel mmc (MMC_DW/HC_SDIO) no detecta la tarjeta en runtime (config SÍ tiene MMC/VFAT). DTB es semánticamente idéntico al stock.
- **S11diag v2:** captura dmesg a `/tmp` siempre + **monta manualmente la SD** (mmcblk0p1/p2) si mdev no la monta + vuelca mmc/sysfs/input/fb/dtb/mtd/iomem. Embebido verificado (MATCH).
- **uImage `6d44c1b7...`** 4,354,009 B (initramfs dev + S11diag v2). Desplegado en G: `6d44c1b7...` (stock.bak `53b3e0b3` intacto, dtb `1258f1eb`/avp `a9788995` sin tocar).
- **RE-TEST FÍSICO #2 PENDIENTE:** bootear → S11diag v2 escribirá `G:\cubegm\dmesg_boot.log` (montaje manual incluido). Traer la SD al PC y leerlo.
- Si `dmesg_boot.log` sigue sin aparecer → confirmar kernel mmc roto → serial ADR-011, o buscar quirk/config mmc del kernel de fábrica.
- Backup golden: `~/backups/r36sx-sd-files-20260915.tar.gz` (`97086531ea...`). NOR/bootloader/AVP INTACTOS.
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

1. **BOOT FÍSICO #2:** con la SD (kernel `6d44c1b7` + S11diag v2) insertada, bootear la consola. S11diag v2 monta la SD manualmente si hace falta y escribe `G:\cubegm\dmesg_boot.log` con el estado mmc/input/fb/dtb y el dmesg completo.
2. **Traer la SD al PC**, leer `G:\cubegm\dmesg_boot.log` y entregarlo.
3. Verificar en el log: ¿`mmcblk0`/`mmcblk0p1` aparece? ¿errores del controlador MMC/SDIO? → confirmar/refutar la hipótesis kernel-mmc.
4. Comparar con el dmesg stock (`docs/experiments/evidence-stock-dmesg.md`) → identificar el driver/config mmc que falta → re-build → re-test.
5. Si `dmesg_boot.log` NO se genera aun con montaje manual → kernel no llega a rcS, o mmc roto definitivo → serial ADR-011.
6. Documentar y actualizar GitHub al cierre.
## REFERENCIA RÁPIDA

| Subsistema | Ver |
|------------|------|
| Reglas (§13 sync, §14 provenance) | `AGENTS.md` |
| Modelo stock / memoria / panel | `docs/DTS_STOCK_MODEL.md` |
| Deltas stock↔D3100 (15) | `docs/R36SX_D3100_DELTA.md` |
| Defconfig delta (8 cambios) | `docs/R36SX_DEFCONFIG_DELTA.md` |
| Direcciones (stock/baseline/r36sx) | `docs/BOOT_CHAIN.md` |
| Experimento Fase 4 | `docs/experiments/2026-09-14_r36sx-v26-board.md` |
