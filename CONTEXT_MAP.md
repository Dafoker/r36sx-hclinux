# CONTEXT_MAP.md — Router de documentación

**Qué consultar por subsistema.** Git es la verdad de estado; esto es solo navegación.

| Tema / Subsistema | Documento(s) | Notas |
|---|---|---|
| Reglas permanentes, protocolo de sesión | `AGENTS.md` | Leer SIEMPRE primero |
| Estado actual, fase, next action | `CURRENT.md` | Caché — validar contra git |
| Decisiones durables | `DECISIONS.md` | ADR-001..N |
| Fuentes externas, hashes, inventario | `manifests/SOURCES.sha256`, `docs/SOURCE_INVENTORY.md` | SDK inmutable |
| Auditoría del SDK (kernel, toolchains, DTS, AVP, Buildroot) | `docs/SDK_AUDIT.md` | Fase 1 — fuente de evidencia vendor |
| Arquitectura del sistema | `docs/ARCHITECTURE.md` | Visión general |
| Cadena de boot | `docs/BOOT_CHAIN.md` | BootROM → bootloader → AVP → kernel |
| Hardware R36SX V2.6 | `docs/HARDWARE_R36SX_V26.md` | Fase 3 |
| Port de board propia | `docs/BOARD_PORT.md` | Fase 4 |
| Compilar / reproducir | `docs/BUILD.md`, `docs/ai/BUILD_CONTRACT.md` | Entradas por script |
| Contrato TreeFrogUI | `docs/TREEFROGUI_COMPATIBILITY.md` | Fase 6 |
| Testing / etiquetas de validación | `docs/TESTING.md`, `docs/ai/VALIDATION.md` | |
| Recuperación / rollback | `docs/RECOVERY.md` | Golden SD protegida |
| Roadmap / fases / gates | `docs/ROADMAP.md` | |
| Seguridad de hardware | `docs/ai/HARDWARE_SAFETY.md` | Lectura previa a cualquier deploy |
| Releases | `docs/ai/RELEASE_CONTRACT.md` | G-only con autorización |
| Experimentos | `docs/experiments/YYYY-MM-DD_<nombre>.md` | Un archivo por experimento |
| Historial de cambios | `CHANGELOG.md` | Resumen por iteración |

## Reglas de consulta

1. **Pregunta sobre el SDK →** reabrir `/mnt/d/GitHub/KERNEL` (tar/manuales/patches). Los docs de auditoría son caché.
2. **Pregunta sobre hardware físico →** `docs/HARDWARE_R36SX_V26.md` primero; si falta dato: STOP + pedir al usuario (no inventar).
3. **"¿Por qué se hizo X?" →** `DECISIONS.md`.
4. **"¿Qué toco ahora?" →** `CURRENT.md` NEXT EXACT ACTION → validar contra git.
5. **Contradicción doc vs evidencia →** evidencia manda; actualizar doc afectado primero (AGENTS.md §2).
