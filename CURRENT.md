# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-16 (Iteración 6r — FASE 5: variante NO-GE REFUTADA; SD en stock golden; bloqueador sin resolver, requiere serial ADR-011)
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

**BLOQUEADOR SIN RESOLVER — el kernel propio no llega a montar la SD en runtime.** SD en estado golden (stock `53b3e0b3`).
- **Evidencia acumulada:** (1) todos los S11diag (v1-v5) jamás escribieron `dmesg_boot.log` ni mostraron beacon; (2) 'please insert tf card' (AVP esperando SD) aparece desde el inicio; (3) la pantalla parece estar controlada por el AVP (los writes de Linux a fb0 son invisibles).
- **Config/driver ESTÁTICAMENTE correctos** (verificado exhaustivamente): driver `hichip,dw-mshc` (HC_SDIO) presente/linkado, clocks (fixed-clocks vía of_clk_init) OK, pinctrl OK, VFAT OK, ABI /dev de driver_r36sx.so cubierta. El fallo es **runtime**.
- **Variante NO-GE (`cd37a60f`, CONFIG_HC_GE=n) REFUTADA:** sigue 'insert tf card', sin log. GE no era la causa.
- **Causas runtime posibles:** (a) hang en init de dispositivos antes de userspace (mmc 0.26s, musb 0.35s, check_adc, etc.) — requiere dmesg para localizar; (b) mmc no detecta la tarjeta; (c) drivers propietarios de fábrica ausentes (`decrypt_sector_data`, `ZZd2C`).
- **VÍA DEFINITIVA: serial (ADR-011)** — DTB serial-only + cable USB-TTL. Sin cable, el diagnóstico es ciego.
- Rollback a stock `53b3e0b3` verificado; dtb `1258f1eb`/avp `a9788995` intactos. Backup golden `97086531ea...`. NOR/bootloader/AVP INTACTOS.
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

1. **VÍA A (recomendada, definitiva):** conseguir un cable USB-TTL (115200 8N1) y desplegar el DTB de diagnóstico serial-only (`scripts/diagnose_boot_serial.sh`, ADR-011) para capturar el dmesg de NUESTRO kernel y localizar el hang exacto.
2. **VÍA B (sin cable):** continuar variantes de init de dispositivos a ciegas (musb/check_adc/nand/etc.), usando como señal si aparece `dmesg_boot.log` en la SD (implica kernel llega a userspace + mmc funciona).
3. Restaurar en el overlay: S41hcdaemon/S99app desde `.orig` (actualmente son no-op para diagnóstico).
4. Documentar y actualizar GitHub al cierre de cada iteración.
## REFERENCIA RÁPIDA

| Subsistema | Ver |
|------------|------|
| Reglas (§13 sync, §14 provenance) | `AGENTS.md` |
| Modelo stock / memoria / panel | `docs/DTS_STOCK_MODEL.md` |
| Deltas stock↔D3100 (15) | `docs/R36SX_D3100_DELTA.md` |
| Defconfig delta (8 cambios) | `docs/R36SX_DEFCONFIG_DELTA.md` |
| Direcciones (stock/baseline/r36sx) | `docs/BOOT_CHAIN.md` |
| Experimento Fase 4 | `docs/experiments/2026-09-14_r36sx-v26-board.md` |
