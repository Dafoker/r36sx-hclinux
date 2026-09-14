# docs/TESTING.md — Estrategia de testing

**Estado:** BOSQUEJO. Etiquetas y gates: `docs/ai/VALIDATION.md`.

## Niveles

1. **STATIC** — análisis de archivos/configs (shellcheck, dtc round-trip, kconfig checks).
2. **HOST** — tests unitarios de scripts host (tests/).
3. **BUILD** — compilación completa con hashes (Fase 2+).
4. **EMULATED** — QEMU si existe soporte HC16xx (no asumir; investigar en Fase 1).
5. **PHYSICAL** — en R36SX V2.6 real (requiere usuario, AGENTS.md §10).
6. **CLEAN-INSTALL / DOWNLOAD-BACK** — installs limpios y verificación de releases.

## Matriz de regresión (crece con las fases)

- Baseline vendor reproducible (Fase 2).
- Boot stock vs boot kernel-own (Fase 5).
- TreeFrogUI: arranque/navegación/launch core (Fase 6).
