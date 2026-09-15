# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-14 (Iteración 4 — Fase 2.5 provenance audit COMPLETADA, todos los gates PASS)
**Regla:** snapshot pequeño, sin historia. No changelog.

## PROJECT

r36sx-hclinux — plataforma Linux/HCLinux reproducible para R36SX V2.6 (HC16xx/MIPS), TreeFrogUI estable, control total de kernel/DTB/rootfs/build.

## CURRENT PHASE

**FASE 2.5 COMPLETADA — TOOLCHAIN + PATCH PROVENANCE + BOARD IDENTITY: ALL PASS**. Siguiente: **FASE 4 — board propia r36sx-v26** (autorizada: gates 2.5 superados).

## CURRENT OBJECTIVE

Fase 4: crear `boards/r36sx-v26/dts/r36sx-v26.dts` (base estructural d3100_v20 SDK + las 8 diferencias del DTB stock E3100v20 + panel DSI) + defconfig propio → build kernel+DTB (gate C: con audit_* PASS).

## CURRENT HEAD

`(ver git log -1 — caché)`

## KNOWN-GOOD STATE

- Fases 0–3 DONE (repo, SDK audit, baseline kernel-only BUILD PASS, hardware físico).
- Fase 2.5 DONE: cross-compilation PROBADA (.cmd: mips-mti-linux-gnu-gcc invocado en 117 subsistemas; ELF kernel/busybox/.ko = MIPS32r2 LE); patches PROBADOS (41 Applying en orden, log V=1, rsync BSP + yaffs2 antes de patches, .stamp_patched; 62/62 externos D:\ idénticos, no doble aplicación); E3100 = chipid del enum SDK sin board files → board propia obligatoria.
- Gates reproducibles: `./scripts/audit_toolchain.sh` → **TOOLCHAIN PROVENANCE: PASS** · `./scripts/audit_kernel_patches.sh` → **PATCH PROVENANCE: PASS**.

## BUILD STATUS

VENDOR BASELINE KERNEL-ONLY d3100_v20: **BUILD PASS + PROVENANCE PASS**. AVP/bootloader: N/A (ADR-008).

## PHYSICAL STATUS

**N/A — sin flashear.** SD G: solo lecturas.

## SOURCE SDK SHA256

`e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` — /mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz

## CURRENT BOARD CANDIDATE

Base estructural: d3100_v20 (pipeline). Hardware baseline: **DTB stock E3100v20** (docs/BOARD_IDENTITY.md §6). r36sx-v26 = DTS propio híbrido.

## ACTIVE BLOCKERS

1. Bare-metal `mips32-mti-elf` (AVP/hcboot propios) — privado GitLab HiChip (ADR-008; no bloquea Fase 4).
2. Layout de particiones flash físico — sin evidencia aún (solo relevante al flashear).

## LAST VALIDATED ACTION

Fase 2.5 completa: gates PASS + remoto verificado ×3 (API/local/ls-remote). Experimento: docs/experiments/2026-09-14_fase25-provenance-audit.md.

## NEXT EXACT ACTION

1. Commit+push iteración 4 (Fase 2.5).
2. Fase 4 iter. 5: copiar `hc16xx-db-d3100-v20.dts`+`-avp.dtsi` a `boards/r36sx-v26/dts/` → aplicar 8 diferencias stock (E3100 label, memory `0xaf91e50`, console=tty1, fb0 `0x18808000` system 12MiB 1280x720, GPIO keys 0x14/0x18, +backlight, clock 0x05, 4 UARTs disabled) + panel DSI stock → `dtc` validar → defconfig `configs/buildroot/r36sx_v26_defconfig` → `build_kernel.sh r36sx-v26` (gate C).

## REFERENCIA RÁPIDA

| Subsistema | Ver |
|------------|------|
| Reglas + PROVENANCE + DOC SYNC | `AGENTS.md` (§13, §14) |
| Router docs | `CONTEXT_MAP.md` |
| Toolchain probado | `docs/TOOLCHAIN_PROVENANCE.md` |
| Patches probados | `docs/PATCH_PROVENANCE.md` |
| E3100 vs D3100 | `docs/BOARD_IDENTITY.md` |
| Hardware físico | `docs/HARDWARE_R36SX_V26.md` |
