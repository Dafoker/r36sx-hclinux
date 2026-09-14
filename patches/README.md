# patches/ — Patches propios del proyecto

| Dir | Uso |
|---|---|
| `kernel/` | Patches propios sobre kernel (4.4.186 baseline) |
| `buildroot/` | Patches sobre Buildroot |
| `vendor/` | Copias analizadas/citadas de patches vendor (por hash), si se necesitan in-tree |

## Reglas

- Los patches vendor ORIGINALES viven en `/mnt/d/GitHub/KERNEL/linux-4.4.186/`, `linux-5.12.4/`, `patches.7z` — inmutables (ADR-002).
- Cada patch propio: un propósito, mensaje claro, evidencia de por qué (experimento o ADR).
- Aplicación verificada (build PASS) antes de commit.
