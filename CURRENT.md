# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-18 (iter 8e-CLEAN-INSTALL: SD formateada + instalación 100% nuestra reinstalada y verificada — pendiente SOLO el test físico del usuario; backup completo pre-formato verificado)
**Regla:** snapshot pequeño, sin historia. No changelog.

## PROJECT

r36sx-hclinux — plataforma Linux/HCLinux reproducible para R36SX V2.6 (HC16xx/MIPS), TreeFrogUI estable, control total de kernel/DTB/rootfs/build.

## CURRENT PHASE

**8e CLEAN-INSTALL EJECUTADA en SD** (formateo FAT32 por el usuario + restauración selectiva del tar verificado + poda "100% nuestro sistema"). El SD layout es ahora la instalación limpia definitiva: sin cadena de fábrica, sin cruft. **Fase 7: 7a (diag opt-in) incluido en el kernel desplegado.** Único pendiente para cerrar 8e: **test físico CLEAN-INSTALL del usuario**.

## CURRENT OBJECTIVE

1. **Usuario: boot físico** → debe llegar al menú TreeFrogUI (kernel 8e + S99app v2 → treefrog-alias) → juego con audio + video + salida. Con PASS = **CLEAN-INSTALL PHYSICAL PASS** (cierra 8e y prueba la instalación desde cero).
2. Después: medir timeline boot con `diag.enabled` → 7b (siguiente optimización con datos).

## CURRENT HEAD

`(ver git log -1 — caché)`

## KNOWN-GOOD STATE

- **SD = instalación limpia verificada** (2026-09-18): `cubegm/` SOLO boot (kernel 8e `f8fb6768`, dtb `1258f1eb`, avp `a9788995`, goldens `53b3e0b3`); `treefrog/` stack completo (2.304 archivos); `rootfs/` runtime de fábrica (602); `roms/` juegos del usuario (621 MB); `frogui/`+`picoarch/` datos.
- **Backup pre-formato**: `D:\R36SX\sd-clean-install-backup-20260918\sd-full.tar` (1.77 GB, `963dfd23…`, 4.742 archivos) — recuperación completa siempre posible.
- Manifiestos en repo: mudanza 8e + eliminación clean-install (todo recuperable).
- Staging D:\R36SX\staging\: fase9m, fase7a, fase8e. Parches kernel: `patches/kernel/0001..0004`.

## BUILD STATUS

**R36SX-V26 KERNEL+ROOTFS OWN: BUILD PASS** (gates TOOLCHAIN/PATCH/DTB PASS). bootloader.bin ausente = esperado (ADR-008). Deployed: fase8e `f8fb6768` (7,129,224 B, 0x80000000/0x803db980) con S99app v2 (treefrog-alias + fallback) + S09trace v5.1.

## PHYSICAL STATUS

- **9m: PHYSICAL PASS TOTAL** (audio+video+salida-cores — test del usuario, pre-limpieza).
- **8e + CLEAN-INSTALL: test físico PENDIENTE** — boot desde FAT32 recién formateado, layout 100% propio, sin cadena de fábrica. Esperado: menú normal (alias treefrog), todo funcional.

## SOURCE SDK SHA256

`e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` — /mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz

## ACTIVE BLOCKERS

Ninguno técnico. Nota operativa: rollback a menú de fábrica ya NO es posible on-card (decisión "100% nuestro"); la recuperación total = restaurar el backup tar (o stock.bak + files del tar si hiciera falta).

## NEXT EXACT ACTION

1. **Usuario: boot de la consola con la SD limpia** → menú TreeFrogUI → probar juego (audio), video y salida de core. Reportar resultado.
2. Con PASS: ROADMAP 8e→DONE + commit de cierre. Con FAIL: crear `G:\treefrog\diag.enabled` (o cubegm), reboot, traer la SD → diagnóstico con trazas.

## REFERENCIA RÁPIDA

| Subsistema | Ver |
|------------|-----|
| Contrato TreeFrogUI (boot/ABI/inventario) | `docs/TREEFROG_UI_CONTRACT.md` |
| Plan 8e + clean install | `docs/experiments/2026-09-18_8e-stack-relocation-plan.md` + manifiestos |
| ADR-012 (ABI) / ADR-013 (diag opt-in) | `DECISIONS.md` |
| Ownership de la cadena | `docs/BOOT_CHAIN.md` |
| Reglas (§13 sync, §14 provenance) | `AGENTS.md` |
| Backup pre-formato | `D:\R36SX\sd-clean-install-backup-20260918\` |
