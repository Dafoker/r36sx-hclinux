# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-18/19 (8e-BISECT-CLOSE: CLEAN-INSTALL PHYSICAL PASS DEFINITIVO — Fase 8 cerrada por completo; Fase 7 continúa)
**Regla:** snapshot pequeño, sin historia. No changelog.

## PROJECT

r36sx-hclinux — plataforma Linux/HCLinux reproducible para R36SX V2.6 (HC16xx/MIPS), TreeFrogUI estable, control total de kernel/DTB/rootfs/build.

## CURRENT PHASE

**FASE 8 DONE DEFINITIVO** (bisect completo, una variable por boot): kernel 8e absuelto → mudanza treefrog absuelta → eliminaciones absueltas menos 4 sospechosos → **CLEAN-INSTALL PHYSICAL PASS**. La causa raíz del primer fail: uno de los 4 archivos pre-Linux (`setting.xml`, `xgame-logo.bmp`, `allfiles.lst`, `root.dat`) es requerido por AVP/bootloader — se conservan por diseño (1,5 MB). **FASE 7 (optimizaciones) continúa** — 7a deployado y validado (opt-in diag físicamente probado en ambos sentidos).

## CURRENT OBJECTIVE

Fase 7 con datos (7b): timeline extraído del boot limpio — kernel@1,08s → SD+zhijack@3,4s → picoarch@~7s (floor = init de frogui, lado upstream TreeFrogUI — fuera de este repo). Opciones dentro de nuestro alcance: (1) refinamiento opcional del culpable exacto entre los 4 archivos pre-Linux (2 boots más), (2) dieta config kernel / rootfs squashfs / otras optimizaciones, (3) decisiones del usuario sobre la siguiente fase.

## CURRENT HEAD

`(ver git log -1 — caché)`

## KNOWN-GOOD STATE

- **SD = instalación limpia definitiva, PHYSICAL PASS**: kernel 8e `f8fb6768` + `treefrog/` (stack completo) + `cubegm/` 10 archivos (boot 5 + 4 pre-Linux-required + `diag.enabled`) + `rootfs/` + roms/frogui/picoarch.
- Kernel 8e físico: BUILD `f8fb6768` (7,129,224 B, Entry 0x803db980) — S99app v2 (treefrog-alias + fallback legacy) + S09trace v5.1 (opt-in) + ABI fixes 9l/9m + snd_xfer budget 500.
- Backup completo: `D:\R36SX\sd-clean-install-backup-20260918\sd-full.tar` (`963dfd23…`).
- Goldens SD: `vmlinux.uImage.stock.bak` (53b3e0b3), `avp.uImage.factory.bak` (a9788995).
- Staging por iteración: `D:\R36SX\staging\` (fase9m/7a/8e). Parches: `patches/kernel/0001..0004`.

## BUILD STATUS

**R36SX-V26 KERNEL+ROOTFS OWN: BUILD PASS** (gates TOOLCHAIN/PATCH/DTB PASS). bootloader.bin ausente = esperado (ADR-008).

## PHYSICAL STATUS

**TODO PHYSICAL PASS**: audio (juegos/música), video (imagen+sonido), salida de emuladores, instalación limpia desde FAT32 recién formateado. Bisect (a)/(b)/(c) PASS con evidencia en `docs/experiments/evidence-8e-*`.

## SOURCE SDK SHA256

`e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` — /mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz

## ACTIVE BLOCKERS

Ninguno. Nota: `diag.enabled` está ACTIVO en la SD (logs en cada boot) — borrar el flag para boots de producción silenciosos.

## NEXT EXACT ACTION

1. Usuario decide: (a) refinamiento del culpable exacto entre los 4 archivos pre-Linux (opcional, 2 boots), o (b) continuar Fase 7 (optimización siguiente), o (c) siguiente fase del ROADMAP.
2. Mantener regla de la lección 8e: UNA variable por boot físico en deploys.

## REFERENCIA RÁPIDA

| Subsistema | Ver |
|------------|-----|
| Contrato TreeFrogUI (boot/ABI/inventario/layout limpio) | `docs/TREEFROG_UI_CONTRACT.md` |
| Caso 8e completo (bisect + plan + manifiestos) | `docs/experiments/2026-09-18_8e-stack-relocation-plan.md` |
| ADR-012 (ABI) / ADR-013 (diag opt-in) | `DECISIONS.md` |
| Ownership de la cadena | `docs/BOOT_CHAIN.md` |
| Reglas (§13 sync, §14 provenance) | `AGENTS.md` |
| Backup completo pre-formato | `D:\R36SX\sd-clean-install-backup-20260918\` |
