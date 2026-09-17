# docs/ROADMAP.md — Fases, gates y formato de iteración

## Visión

BootROM → bootloader (stock) → AVP/HCRTOS (stock, preservado) → **kernel propio (4.4.186)** → **DTB propio** → **rootfs propio (Buildroot)** → picoarch → **TreeFrogUI como shell principal**.

## Fases

| Fase | Objetivo | Gate de salida | Estado |
|---|---|---|---|
| **0. Bootstrap** | Repo + contexto + agentes + GitHub operativo | Preflight PASS + push verificado + docs core | ✅ DONE |
| **1. Auditoría SDK** | Extraer y auditar SDK completo; confirmar/refutar hipótesis §15 | `docs/SDK_AUDIT.md` con claims+evidencia+ruta | ✅ DONE (STATIC PASS, H1–H11 CONFIRMED) |
| **2. Baseline vendor** | Reproducir build vendor sin modificaciones | BUILD PASS reproducible + hashes | ✅ DONE (kernel-only, ADR-007/008; BUILD PASS 2026-09-14) |
| **2.5 Provenance audit** | Demostrar cross-compile real + patch set aplicado + identidad board | TOOLCHAIN/PATCH PROVENANCE PASS + BOARD_IDENTITY | ✅ DONE (2026-09-14 — gates scripts/audit_*.sh PASS) |
| **3. Hardware R36SX V2.6** | Documentar hardware real (DTS stock, logs físicos si el usuario aporta) | `docs/HARDWARE_R36SX_V26.md` con fuentes | ✅ DONE (evidencia física SD stock G: read-only; board E3100v20, 176MiB) |
| **4. Board propia** | `boards/r36sx-v26/` derivada por evidencia, no copia ciega | Diferencias vs vendor documentadas + BUILD PASS | ✅ DONE (4A stock model + 4B build: DTB SEMANTIC PASS 0-diff, config delta 0, provenance PASS — ADR-010) |
| **5. Primer kernel propio** | Reemplazar SOLO kernel/DTB; resto stock | PHYSICAL PASS (boot + TreeFrogUI stock) | ⏸ PENDIENTE AUTORIZACIÓN (Fase 5 = SAFE PHYSICAL BOOT TEST, protocolo rollback) | ✅ PHYSICAL PASS 2026-09-16 (iteración 6x)
| **6. Contrato TreeFrogUI** | Matriz de dependencias reales (fb, input, audio, ioctl, /dev/dis...) | `docs/TREEFROGUI_COMPATIBILITY.md` | PENDIENTE |
| **7. Optimizaciones** | Una hipótesis por experimento, contra baseline | Cada una: resultado + decisión ADR si durable | PENDIENTE |
| **8. Rootfs propio** | Buildroot controlado + picoarch + TreeFrogUI | CLEAN-INSTALL PHYSICAL PASS | PENDIENTE |
| **9. Kernel 5.12.4** | Solo con 4.4.186 known-good físico | Comparación regresión vs golden | DIFERIDO |

## Formato de experimento (docs/experiments/YYYY-MM-DD_<nombre>.md)

```markdown
# Objective
# Hypothesis
# Evidence (rutas + citaciones del SDK)
# Files changed
# Commands (exactas)
# Build result (etiqueta VALIDATION.md)
# Tests (con etiqueta)
# Result
# Interpretation
# Decision
# Artifact hashes
# Next action
```

## Reglas de iteración

- RESEARCH → PLAN → IMPLEMENT → VERIFY → DOCUMENT → COMMIT → PUSH → VERIFY REMOTE → NEXT.
- Un commit = un checkpoint coherente; mensajes tipo `docs:`, `build:`, `board:`, `kernel:`, `dts:`, `research:`, `scripts:`.
- Experimentos fallidos se documentan igual (evidencia negativa).
- CHANGELOG.md: una línea por iteración; detalle en experimentos.
