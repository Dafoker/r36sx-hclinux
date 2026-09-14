# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-14 (Iteración 2 — Fase 1 SDK audit completada)
**Regla:** snapshot pequeño, sin historia. No changelog.

## PROJECT

r36sx-hclinux — plataforma Linux/HCLinux reproducible para R36SX V2.6 (HC16xx/MIPS), TreeFrogUI estable, control total de kernel/DTB/rootfs/build.

## CURRENT PHASE

**FASE 1 — Auditoría SDK: COMPLETADA (STATIC PASS)**. Siguiente: **FASE 2 — Reproducir build vendor baseline** (Iteración 3).

## CURRENT OBJECTIVE

Fase 2: ejecutar el build vendor D3100 v20 (o el más cercano por evidencia) sin modificaciones → BUILD PASS reproducible + hashes.

## CURRENT HEAD

`(ver git log -1 — no duplicar aquí; este archivo es caché)`

## KNOWN-GOOD STATE

- Fase 0: repo + agentes + contratos + GitHub operativo (commit 5940f79).
- Fase 1: SDK extraído (3.9 GiB en ~/work/r36sx-hclinux/sdk), H1–H11 CONFIRMED con evidencia (docs/SDK_AUDIT.md), cross-checks manual↔SDK OK, matching físico R36SX→familia D3100 v20.
- Fuentes inmutables verificadas: 7/7 hashes PASS (manifests/SOURCES.sha256, incluye 2 .md derivados del manual añadidos 2026-09-14).

## BUILD STATUS

**N/A** — sin builds aún. Fase 2 ejecutará: `make O=output/d3100 BR2_EXTERNAL=$PWD/../ hichip_hc16xx_db_d3100_v20_defconfig && make O=output/d3100 all`.

## PHYSICAL STATUS

**N/A** — R36SX no tocada. (Evidencia física previa del usuario integrada en SDK_AUDIT: DTB stock, board label hc1600a@dbD3100v20, uImage dumps.)

## SOURCE SDK SHA256

`e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` — /mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz (2,116,519,773 bytes)

## ACTIVE BLOCKERS

1. **Fase 2 requiere dependencias host** (setup_tools.sh usa `sudo apt install` — puede requerir interacción) y ~20 GB + descargas on-line de terceros (dl/). Toolchain bare-metal AVP NO está en el tar (repo GitLab Dl; si el build la necesita para AVP, hay que localizarla — revisar /mnt/d/Toolchains/R36SX y backups del usuario).
2. Locale inglés y Ubuntu 18.04+ recomendado por vendor (WSL es 24.04 — validar).

## LAST VALIDATED ACTION

Fase 1 STATIC PASS: 6 pasadas de auditoría (P1–P6) + addendum cross-checks manual↔SDK + integración evidencia física R36SX (reports del usuario en work/) → docs/SDK_AUDIT.md completo.

## NEXT EXACT ACTION

1. Commit + push Iteración 2 (Fase 1).
2. Iteración 3 (Fase 2): inventariar toolchains locales disponibles (~/sf3000-work, /mnt/d/Toolchains/R36SX) → decidir estrategia de dependencias (dl/, bare-metal) → build vendor d3100_v20 sin modificaciones → BUILD_REPORT + hashes.

## REFERENCIA RÁPIDA

| Subsistema | Ver |
|------------|------|
| Reglas permanentes | `AGENTS.md` |
| Qué doc por tema | `CONTEXT_MAP.md` |
| Decisiones | `DECISIONS.md` |
| Fuentes + hashes | `manifests/SOURCES.sha256` |
| Auditoría SDK (H1–H11, boot, toolchains) | `docs/SDK_AUDIT.md` |
| Arquitectura confirmada | `docs/ARCHITECTURE.md` |
| Contratos validación/build/release | `docs/ai/` |
