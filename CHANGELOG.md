# CHANGELOG.md

Formato: una línea por iteración; detalle técnico en `docs/experiments/` y commits.

## 2026-09-14

- **Iteración 1 (Fase 0):** bootstrap desde cero. Preflight WSL PASS; inventario STATIC PASS (5 fuentes top-level + hashes → manifests); repo local + estructura completa; AGENTS/CURRENT/CONTEXT_MAP/DECISIONS (ADR-001..006); contratos docs/ai/*; agentes .opencode; scripts core; repo GitHub creado + push inicial. Repo previo homónimo archivado a bundle y eliminado por decisión del usuario (ADR-003).
- **Iteración 2 (Fase 1):** SDK extraído y auditado (6 pasadas + addendum). H1–H11 CONFIRMED con evidencia (Buildroot 2021.05-rc2, arch HC16xx vía rsync linux-drivers, 4.4.186 default/5.12.4 secundario, AMPRPC/AVP, boot chain con direcciones 0x85ff0000/0xb8800004/0x8BDA4000, toolchains Codescape). Patches /mnt/d ≡ SDK (hash idéntico). Cross-check manual↔SDK: 7 CONFIRMED + 1 PARTIAL (DDR-init 12 KiB ≠ 4 KiB). Matching físico R36SX→D3100 v20 integrado (evidence del usuario). 2 refs .md del manual añadidas al manifest (7/7 PASS). docs/SDK_AUDIT.md + ARCHITECTURE.md + BOOT_CHAIN.md completados. STATIC PASS.
