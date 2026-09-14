# configs/ — Configs propias

| Dir | Uso |
|---|---|
| `buildroot/` | defconfigs Buildroot propios (Fase 2 deriva del vendor, Fase 8 propios) |
| `kernel/` | configs kernel propias (r36sx_v26_defconfig en Fase 5) |

Reglas: derivar del vendor más cercano SOLO tras evidencia (Fase 1); documentar toda diferencia; .config de builds va a out/ (ignorado), las configs versionadas aquí son fuente.
