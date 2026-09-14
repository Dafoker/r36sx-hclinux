# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-14 (Iteración 3 — Fase 2 build baseline PASS + evidencia física SD)
**Regla:** snapshot pequeño, sin historia. No changelog.

## PROJECT

r36sx-hclinux — plataforma Linux/HCLinux reproducible para R36SX V2.6 (HC16xx/MIPS), TreeFrogUI estable, control total de kernel/DTB/rootfs/build.

## CURRENT PHASE

**FASE 2 COMPLETADA — VENDOR BASELINE KERNEL-ONLY: BUILD PASS**. Siguiente: **FASE 4 — board propia r36sx-v26** (Fase 3 hardware resuelta por evidencia física SD, consolidada en docs/HARDWARE_R36SX_V26.md).

## CURRENT OBJECTIVE

Fase 4: crear board propia `r36sx-v26` (DTS derivado del DTB stock E3100v20 + defconfig propio) → build kernel+DTB propios (gate clase C).

## CURRENT HEAD

`(ver git log -1 — caché)`

## KNOWN-GOOD STATE

- Fase 0/1: repo+agentes+GitHub; SDK auditado H1-H11 CONFIRMED.
- Fase 2: **d3100_v20 kernel-only BUILD PASS** — kernel 4.4.186 mismo toolchain que fábrica (vermagic stock Codescape 2018.09-02). DTB byte-idéntico a baseline previo. Artefactos: `~/work/r36sx-hclinux/artifacts/d3100-v20-baseline-kernelonly/` + `D:\R36SX\hclinux-builds\d3100-v20-baseline-kernelonly-20260914\`.
- Fase 3: hardware físico documentado desde SD stock (read-only): board `hc1600a@dbE3100v20`, Linux 176 MiB, console=tty1, fb0 0x18808000 1280x720.

## BUILD STATUS

**VENDOR BASELINE KERNEL-ONLY: BUILD PASS** (kernel+DTB+uImage+rootfs.squashfs). AVP/bootloader: N/A (preservados stock, ADR-008; bare-metal privado no disponible).

## PHYSICAL STATUS

**N/A — sin flashear.** SD G: validada read-only (hashes artefactos stock registrados). Diferencias stock vs SDK documentadas — DTB SDK NO debe flashearse en la consola (memoria AVP).

## SOURCE SDK SHA256

`e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` — /mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz (2,116,519,773 bytes)

## CURRENT BOARD CANDIDATE

**VENDOR BASELINE CANDIDATE: d3100_v20 (pipeline) · CONFIDENCE: HIGH · FINAL BOARD IDENTITY: NOT YET PROVEN — física = familia E3100 v20 → board propia r36sx-v26 obligatoria (Fase 4).** (ADR-007)

## ACTIVE BLOCKERS

1. Toolchain bare-metal `mips32-mti-elf` 2019.09-03-2 (AVP/hcboot propios): GitLab HiChip privado (login), `/opt/` local roto → ADR-008 kernel-only. Reevaluar si el usuario obtiene el tarball.
2. `target-post-image` falla al final (bootloader.bin ausente) — esperado, documentado.

## LAST VALIDATED ACTION

Fase 2 BUILD PASS completo + validación read-only SD stock (uImage/DTB/AVP hashes + vermagic fábrica == nuestro toolchain) + diff DTB stock↔SDK (718 líneas, 8 diferencias clave documentadas). EXPERIMENTO: docs/experiments/2026-09-14_vendor-baseline-d3100-v20.md.

## NEXT EXACT ACTION

1. Commit+push iteración 3 (Fase 2+3).
2. Fase 4: `boards/r36sx-v26/dts/r36sx-v26.dts` — partir de `hc16xx-db-d3100-v20.dts`+dtsi del SDK, aplicar las 8 diferencias del DTB stock (E3100 label, memory 0xaf91e50, console=tty1, fb0 0x18808000 system 12MiB 1280x720, GPIO keys 0x14/0x18, backlight avp-proxy, clock 0x05, 4 UARTs disabled) → dtc validar → defconfig `configs/buildroot/r36sx_v26_defconfig` → build kernel (gate C).

## REFERENCIA RÁPIDA

| Subsistema | Ver |
|------------|------|
| Reglas + DOCUMENTATION SYNC | `AGENTS.md` (§13) |
| Router docs | `CONTEXT_MAP.md` |
| Decisiones (ADR-001..008) | `DECISIONS.md` |
| Hardware físico R36SX | `docs/HARDWARE_R36SX_V26.md` |
| Cómo compilar (validado) | `docs/BUILD.md` |
| Experimento baseline | `docs/experiments/2026-09-14_vendor-baseline-d3100-v20.md` |
