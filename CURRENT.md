# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-14 (bootstrap, Fase 0)
**Regla:** snapshot pequeño, sin historia. No changelog.

## PROJECT

r36sx-hclinux — plataforma Linux/HCLinux reproducible para R36SX V2.6 (HC16xx/MIPS), TreeFrogUI estable, control total de kernel/DTB/rootfs/build.

## CURRENT PHASE

**FASE 0 — Bootstrap** (completándose). Siguiente: **FASE 1 — Auditoría SDK** (Iteración 2).

## CURRENT OBJECTIVE

Cerrar Fase 0: repo GitHub creado, estructura completa, preflight PASS, primer push verificado.

## CURRENT HEAD

`(ver git log -1 — no duplicar aquí; este archivo es caché)`

## KNOWN-GOOD STATE

- Bootstrap repo creado desde CERO (2026-09-14). Sin predecesor técnico — un repo previo homónimo fue archivado a bundle y eliminado por decisión del usuario; no es antecedente de nada.
- SDK fuente localizado e inventariado, hashes capturados (manifests/SOURCES.sha256).

## BUILD STATUS

Sin builds aún (Fase 1 = auditoría; Fase 2 = primer build vendor). Etiqueta: **N/A**.

## PHYSICAL STATUS

Sin actividad física. Etiqueta: **N/A**. R36SX V2.6 no tocada.

## SOURCE SDK SHA256

`e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` — `/mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz` (2,116,519,773 bytes)

## ACTIVE BLOCKERS

Ninguno. (STOP previsto en Fase 3 si se requieren datos físicos del dispositivo.)

## LAST VALIDATED ACTION

Preflight WSL PASS (Ubuntu 24.04, toolchain completo, gh auth ozkaoz OK, acceso /mnt/d/GitHub/KERNEL OK). Inventario de fuentes STATIC PASS.

## NEXT EXACT ACTION

1. Verificar push inicial en GitHub (HEAD remoto == local).
2. Iniciar **Iteración 2 — FASE 1**: extraer SDK a `~/work/r36sx-hclinux/sdk/`, auditoría top-level, kernel 4.4.186, Buildroot, toolchains, DTS, AVP → `docs/SDK_AUDIT.md`.

## REFERENCIA RÁPIDA

| Subsistema | Ver |
|------------|------|
| Reglas permanentes | `AGENTS.md` |
| Qué doc por tema | `CONTEXT_MAP.md` |
| Decisiones | `DECISIONS.md` |
| Fuentes + hashes | `manifests/SOURCES.sha256` |
| Contratos validación/build/release | `docs/ai/` |
