# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-17 (Fase 8d PHYSICAL PASS ✅ — icube-direct: launcher de fábrica ELIMINADO del boot; menú ~8,1s; boot path 100% nuestro salvo hcdaemon+zhijack/TreeFrogUI de la SD)
**Regla:** snapshot pequeño, sin historia. No changelog.

## PROJECT

r36sx-hclinux — plataforma Linux/HCLinux reproducible para R36SX V2.6 (HC16xx/MIPS), TreeFrogUI estable, control total de kernel/DTB/rootfs/build.

## CURRENT PHASE

**FASE 5 COMPLETA — PHYSICAL PASS ✅** (2026-09-16/17). El kernel propio (`017adf3b`, iteración 6x) bootea la consola real hasta el MENÚ TreeFrogUI navegable y funcional. Siguiente fase: **6 — contrato TreeFrogUI sobre kernel propio** (y opcional: evidencia on-device /proc/version).

## CURRENT OBJECTIVE

Fase 8a/8c/8d LOGRADAS. Opciones siguientes: (a) **boot-opt 8f**: fase de montaje SD 1,1→5,5s (mdev+mount-helper sleeps del vendor) — objetivo menú ~4-5s; (b) **8e clean-install**: relocar stack TreeFrogUI fuera de cubegm/ (decisión de diseño con el ecosistema del usuario); (c) media fix con USB-TTL.

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

**PHYSICAL PASS (6x):** menú TreeFrogUI navegable y funcional con kernel propio. El 6x está DESPLEGADO en G: (uso diario). stock.bak (53b3e0b3) disponible como rollback. SD verificada post-boot: kernel íntegro (017adf3b), dtb/avp stock intactos, sin escrituras anómalas.

Contexto de los fallos previos (resuelto): (stock `53b3e0b3` desplegado, verificado con 3 lecturas idénticas; sin stock.bak en G: — el rollback de 6r fue por rename). **Hallazgo clave 6w: desde 6h, S41hcdaemon/S99app en el initramfs eran no-ops de diagnóstico → NINGÚN test físico previo pudo llegar al menú aunque kernel+mmc funcionaran. TEST 6w (2026-09-16 noche): splash + ICONO DE BATERÍA (capa UI visible por primera vez) SIN menú — cadena Linux→SD→icube parcialmente viva; hang en la capa menú (picoarch). La refutación NO-GE de 6r INVALIDADA (S41/S99 eran no-op). 6x sospecha: /dev/ge + hwspinlock faltantes por NOEXTRA.** También eliminada como variable: compresión del initramfs embebido (antes gzip/LZ4 vía RD_*; fábrica y 6w = cpio CRUDO).
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

## CURRENT ITERATION (7c) — estado al cierre de sesión 16/17-sep

- **7c STAGED** (`D:\R36SX\staging\vmlinux.uImage-r36sx-v26-menu-7c`, sha256 `15ad1cb7...`): 6x MINUS {HC_I2C, HC_IRC, HC_WDT, HC_NAND, HC_TOE, HC_LVDS}, KEEP {HC_GE, HC_HWSPINLOCK}. Initramfs CRUDO == stock, hcrc+dcrc VALIDOS, DTB SEMANTIC PASS.
- **SD actual**: 6x `017adf3b` desplegado; `stock.bak` golden `53b3e0b3` intacto; scripts en raíz: diag6x.sh, diag7.sh, diag8.sh.
- Evidencia en repo: evidence-diag6x.log, evidence-diag7-1/2.log, evidence-factory-diag2.log, docs/experiments/2026-09-17_fase6-diag6x-analysis.md (matriz de síntomas + diff dmesg + hipótesis).

## LAST VALIDATED ACTION

Test físico 6w (splash+batería, sin menú, kernel íntegro post-boot) + build 6x verificado (vendor baseline + CHECK_ADC + initramfs stock-parity, hcrc+dcrc OK). Experimento: docs/experiments/2026-09-16_menu-goal-stock-parity.md (addendum 6x).

## NEXT EXACT ACTION

1. **8d icube-direct:** S99app-direct (espera zhijack.sh + LD_LIBRARY_PATH + lanza zhijack) → deploy → renombrar icube en SD → test: menú + boot más rápido (~2,9s menos) + boottrace.
2. **Comprar cable USB-TTL** (paralelo) — desbloquea el diagnóstico de media (ADR-011) y todo debugging futuro.
3. Testing kernel propio: usar staging (`7e da76d6ea` / `6x 017adf3b`) en SD de pruebas; consola diaria queda en STOCK.

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
