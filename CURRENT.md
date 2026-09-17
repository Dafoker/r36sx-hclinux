# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-16 (Iteración 6x — test 6w: splash+batería SIN menú; drivers NOEXTRA reactivados; BUILD 6x verificado, DEPLOY+TEST PENDIENTE)
**Regla:** snapshot pequeño, sin historia. No changelog.

## PROJECT

r36sx-hclinux — plataforma Linux/HCLinux reproducible para R36SX V2.6 (HC16xx/MIPS), TreeFrogUI estable, control total de kernel/DTB/rootfs/build.

## CURRENT PHASE

**FASE 5 — SAFE PHYSICAL BOOT TEST EN CURSO** (autorizada por el usuario). **Iteración 6w: build MENU-GOAL stock-parity COMPLETO y verificado en host.** Pendiente: deploy autorizado a G: + boot físico con objetivo MENÚ TreeFrogUI.

## CURRENT OBJECTIVE

Deploy del uImage 6x (`017adf3b...`, staging `vmlinux.uImage-r36sx-v26-menu-6x` — vendor baseline + CHECK_ADC + initramfs stock-parity crudo) a G:\cubegm\vmlinux.uImage con read-back ×2, boot físico y validar si la consola llega al MENÚ TreeFrogUI (navegable). Rollback a stock.bak si falla.

## CURRENT HEAD

`(ver git log -1 — caché)`

## KNOWN-GOOD STATE

- Fases 0–4 DONE (repo, SDK audit, baseline BUILD+PROVENANCE PASS, hardware físico, board r36sx-v26 BUILD PASS DTB SEMANTIC 0-diff).
- **Iteración 6w (2026-09-16):** primer build con la cadena hasta el menú INTACTA — initramfs stock-parity TOTAL: overlay == stock (S41hcdaemon real `hcdaemon&`, S99app real, sin S11diag), cpio embebido CRUDO (RD_* off, como fábrica), dueño 0:0. Contenido embebido verificado == stock (diff -r vacío). uImage `fc501a83...` 4,334,171 B, Load 0x80000000/Entry 0x803DE0F0, hcrc VÁLIDO. Gates TOOLCHAIN+PATCH+DTB PASS.
- **Iteración 6x:** build 6w + drivers NOEXTRA reactivados (GE/WDT/IRC/HWSPINLOCK/LVDS/NAND/TOE/I2C = vendor baseline). uImage `017adf3b...` 4,348,576 B (0x80000000/0x803E3AC0), hcrc+dcrc VERIFICADOS, initramfs CRUDO == stock. Staging `vmlinux.uImage-r36sx-v26-menu-6x`.
- Artefactos: `~/work/r36sx-hclinux/artifacts/r36sx-v26/`.

## BUILD STATUS

**R36SX-V26 KERNEL + INITRAMFS STOCK-PARITY: BUILD PASS** (+ provenance PASS). bootloader.bin ausente = esperado (ADR-008).

## PHYSICAL STATUS

SD en estado golden (stock `53b3e0b3` desplegado, verificado con 3 lecturas idénticas; sin stock.bak en G: — el rollback de 6r fue por rename). **Hallazgo clave 6w: desde 6h, S41hcdaemon/S99app en el initramfs eran no-ops de diagnóstico → NINGÚN test físico previo pudo llegar al menú aunque kernel+mmc funcionaran. TEST 6w (2026-09-16 noche): splash + ICONO DE BATERÍA (capa UI visible por primera vez) SIN menú — cadena Linux→SD→icube parcialmente viva; hang en la capa menú (picoarch). La refutación NO-GE de 6r INVALIDADA (S41/S99 eran no-op). 6x sospecha: /dev/ge + hwspinlock faltantes por NOEXTRA.** También eliminada como variable: compresión del initramfs embebido (antes gzip/LZ4 vía RD_*; fábrica y 6w = cpio CRUDO).
- Evidencia previa en pie: S11diag v1-v5 jamás escribieron dmesg_boot.log; 'please insert tf card' (AVP) en todos los tests. Causas restantes si 6w no llega al menú: hang runtime en init de dispositivos / mmc no detecta tarjeta / kernel no llega a userspace.
- Forense CORRUPT-header (12:59): NOEXTRA con 1 byte invertido (timestamp; hcrc INVÁLIDO) — fabricado para test de kernel inválido, orientación descartada. NO es corrupción de SD.

## SOURCE SDK SHA256

`e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` — /mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz

## CURRENT BOARD CANDIDATE

**r36sx-v26 = board propia CONFIRMADA** (stock-equivalent, ADR-010). D3100_v20 = pipeline baseline (upstream intacto).

## ACTIVE BLOCKERS

1. Deploy a G: requiere autorización explícita del usuario (protocolo Fase 5 / HARDWARE_SAFETY).
2. Bare-metal mips32-mti-elf (AVP/hcboot propios) — privado (ADR-008; no bloquea lo actual).
3. Kernel config de fábrica exacto no extraíble (sin IKCONFIG) — 6w logra paridad estructural vía forense binaria.

## LAST VALIDATED ACTION

Test físico 6w (splash+batería, sin menú, kernel íntegro post-boot) + build 6x verificado (vendor baseline + CHECK_ADC + initramfs stock-parity, hcrc+dcrc OK). Experimento: docs/experiments/2026-09-16_menu-goal-stock-parity.md (addendum 6x).

## NEXT EXACT ACTION

1. **DEPLOY 6x (autorización requerida):** copiar staging `vmlinux.uImage-r36sx-v26-menu-6x` (`017adf3b...`) → `G:\cubegm\vmlinux.uImage` (sobre el 6w); read-back ×2. stock.bak YA existe en G: (53b3e0b3).
2. **TEST FÍSICO:** boot → ¿llega al MENÚ TreeFrogUI? (splash ≠ menú; menú = navegable con botones).
3. Si FAIL → rollback stock.bak → siguiente vía: serial (ADR-011, cable USB-TTL); el síntoma del fail (dónde se congela) discrimina: batería-sin-menú = capa picoarch; splash-solo = capa icube; insert-tf-card = AVP solo.
4. Documentar y actualizar GitHub al cierre.

## REFERENCIA RÁPIDA

| Subsistema | Ver |
|------------|-----|
| Reglas (§13 sync, §14 provenance) | `AGENTS.md` |
| Modelo stock / memoria / panel | `docs/DTS_STOCK_MODEL.md` |
| Deltas stock↔D3100 (15) | `docs/R36SX_D3100_DELTA.md` |
| Defconfig delta (8 cambios) | `docs/R36SX_DEFCONFIG_DELTA.md` |
| Direcciones (stock/baseline/r36sx) | `docs/BOOT_CHAIN.md` |
| Experimento Fase 4 | `docs/experiments/2026-09-14_r36sx-v26-board.md` |
| Experimento 6w (este build) | `docs/experiments/2026-09-16_menu-goal-stock-parity.md` |
