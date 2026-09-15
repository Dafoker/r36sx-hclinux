# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-15 (Iteración 6e — FASE 5 EN CURSO: hipótesis CHECK_ADC REFUTADA, requiere dmesg serial, rollback OK)
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

**RE-TEST FALLÓ — HIPÓTESIS CHECK_ADC REFUTADA. Consola en stock (usable). DIAGNÓSTICO SERIAL REQUERIDO.**
- RE-TEST con `CONFIG_CHECK_ADC=y` (`08cced35...`): sigue en splash, sin menú. **`CONFIG_CHECK_ADC` NO era la causa única.** Hipótesis C REFUTADA.
- Hallazgo adicional no concluyente: `/dev/backlight` requerido por UI pero `CONFIG_FB_BACKLIGHT is not set` en vendor.
- **NO hay logs de boot en SD** (menu.log binario no se reescribe; no hay dmesg guardado). NO se puede diagnosticar por filesystem de la SD.
- **DECISIÓN:** no recompilar más configs por conjetura. Se requiere **dmesg via serial (ADR-011)** para diagnóstico no-ciego.
- **ROLLBACK EJECUTADO y verificado:** `G:\cubegm\vmlinux.uImage` = stock `53b3e0b3...` (desde `.stock.bak`), confirmado WSL+Windows. Consola usable.
- **ADR-011:** DTB serial-only NO-baseline (`scripts/diagnose_boot_serial.sh`, hc_uart@18818600 115200n8). Cable USB-C OTG NO sirve (solo MTP/PTP).
- Backup golden: `~/backups/r36sx-sd-files-20260915.tar.gz` (sha256 `97086531ea...`).
- NOR/bootloader/AVP/rootfs INTACTOS.

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

1. **DIAGNÓSTICO NO-CIEGO (obligatorio):** capturar dmesg del boot con kernel r36sx-v26 vía `scripts/diagnose_boot_serial.sh` (DTB serial-only, hc_uart@18818600 115200n8) + cable USB-TTL. Localizar dónde se cuelga la UI tras el splash (qué driver/init falla).
2. En paralelo sin hardware: comparar exhaustivamente los `/dev` requeridos por la UI (fb0/fb1/dis/ge/backlight/input/check_adc/sndC0i2so/mmz/auddec/persistentmem/mipi/standby) contra el kernel vendor para listar TODOS los posibles faltantes (backlight pendiente de confirmar). Solo como apoyo al dmesg, no como conjetura ciega.
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
