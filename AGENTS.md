# AGENTS.md — Constitución permanente de r36sx-hclinux

**Versión:** 1.0 (bootstrap)
**Repo:** https://github.com/ozkaoz/r36sx-hclinux
**Objetivo:** plataforma Linux/HCLinux reproducible para R36SX V2.6 (HiChip HC16xx, MIPS) con TreeFrogUI estable.

---

## 0. INVARIANTE FUNDAMENTAL (literal)

**All development, builds, Git operations and GitHub operations MUST be executed from WSL. Windows paths are data sources only unless explicitly documented otherwise.**

Prohibido compilar/desarrollar desde cmd.exe, PowerShell o Git Bash de Windows, salvo razón de hardware documentada explícitamente. Acceso a datos Windows solo vía `/mnt/`.

## 1. PROTOCOLO DE INICIO (toda sesión)

1. Confirmar que se está dentro de WSL (Linux).
2. Leer en orden: `AGENTS.md` → `CURRENT.md` → `CONTEXT_MAP.md`.
3. Ejecutar `./scripts/agent_preflight.sh` (read-only, seguro).
4. `git status --short --branch` — si hay cambios locales no explicados: **STOP**, mostrar antes de tocar nada.
5. Resolver desde Git: `REPO_ROOT`, `ACTIVE_BRANCH`, `HEAD`, `UPSTREAM`, `AHEAD_BEHIND`, `WORKTREE_STATE`.
6. Identificar objetivo exacto de la iteración y clasificar el cambio (ver §7).
7. Comenzar trabajo.

## 2. FUENTES DE VERDAD (jerarquía, mayor → menor)

1. Requisito explícito actual del usuario.
2. Evidencia física/directa actual.
3. Este `AGENTS.md`.
4. Decisiones ACTIVE de `DECISIONS.md`.
5. **SDK vendor real en `/mnt/d/GitHub/KERNEL`** (el archivo manda, no los resúmenes).
6. Git y filesystem actuales.
7. Builds y artefactos actuales.
8. `CURRENT.md` (ES CACHÉ).
9. Documentación estructural.
10. Historial/changelog.
11. Inferencias anteriores.

**EVIDENCE > MEMORY > PLAN.** Si una fuente de mayor nivel contradice una inferior: actualizar el contexto/documentación afectada primero. Los resúmenes generados son CACHÉ; el SDK real tiene prioridad siempre.

## 3. REGLA DE CONSULTA DEL SDK

Ante ambigüedad, duda de drivers/DTS/memoria/AVP/bootloader/kernel/Buildroot/hardware, información contradictoria u obsoleta, pérdida de contexto por compactación, nueva sesión, o resultado inesperado de build: **NO inventar la respuesta. VOLVER A CONSULTAR** `/mnt/d/GitHub/KERNEL` (tar SDK, manuales, ZIP/7Z, patches, hcdrivers, DTS, configs, scripts, toolchains). Consultables sin límite de veces.

## 4. SDK MAESTRO INMUTABLE

`/mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz` — SHA256 `e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` (2,116,519,773 bytes).

- PROHIBIDO modificar/reemplazar/sobrescribir el SDK y las fuentes de `/mnt/d/GitHub/KERNEL`.
- PROHIBIDO desarrollar dentro de `/mnt/d/GitHub/KERNEL` o `/mnt/d`.
- Workspace derivado en WSL nativo: `~/work/r36sx-hclinux/{sdk,build,cache}`.
- Todo cambio propio vive en ESTE repo: patches, board, configs, scripts, overlays.
- Reconstrucción garantizada desde: SDK ORIGINAL + ESTE REPO + dependencias documentadas.

## 5. HARDWARE SAFETY (NO NEGOCIABLE)

PROHIBIDO escribir sin autorización explícita del usuario: NOR/NAND flash, bootloader, DDR init, particiones críticas, SD física, `/dev/sdX`, firmware interno.

Prohibido usar `rm -rf`, `git reset --hard`, `git clean -fd`, `dd`, `mkfs`, flash tools sobre objetivos no verificados.

Antes de escribir una SD: identificar dispositivo → mostrar info → confirmar tamaño/modelo/mounts → **pedir autorización explícita** → solo entonces proceder. Una SD stock/original se protege siempre como golden recovery.

## 6. ITERACIÓN OBLIGATORIA

```
RESEARCH → PLAN → IMPLEMENT → VERIFY → DOCUMENT → COMMIT → PUSH → VERIFY REMOTE → NEXT
```

GitHub es el journal técnico autoritativo. No trabajar horas localmente para subir al final. Nunca finalizar una iteración local sin actualizar GitHub. No depender del historial del chat.

## 7. CLASES DE CAMBIO Y GATES

| Clase | Alcance | Gate |
|-------|---------|------|
| A | Contexto/docs/agentes | Static review + context checks |
| B | Herramientas host/scripts/tests | shellcheck/tests relevantes |
| C | Kernel/BSP/DTS | Config validation + kernel build + DTB validation |
| D | Boot/AVP/bootloader | Build validation + **autorización hardware** |
| E | Rootfs/Buildroot | Rootfs/build validation |
| F | Deploy físico/SD | **Autorización explícita antes de escribir** |
| G | Release pública | Artefacto validado + **autorización explícita** |

Una variable principal por experimento. Prohibido modificar simultáneamente kernel+bootloader+AVP+rootfs+DDR.

## 8. ETIQUETAS DE VALIDACIÓN

Usar exactamente: `STATIC PASS` · `HOST PASS` · `BUILD PASS` · `PACKAGING PASS` · `EMULATED PASS` · `PHYSICAL PASS` · `CLEAN-INSTALL PHYSICAL PASS` · `DOWNLOAD-BACK PASS`.

Prohibido: DONE, VERIFIED, WORKING. "Compila" ≠ "funciona en R36SX". HOST PASS ≠ PHYSICAL PASS. No inventar pruebas físicas.

## 9. PROTECCIÓN CONTRA ALUCINACIONES

No sabes → BUSCA. Prioridad: filesystem local → SDK → docs adjuntas → Git → repos ozkaoz → upstream → Internet → inferencia. Etiquetar inferencias como inferencias. Prohibido inventar direcciones de memoria, GPIO, offsets, tamaños, DTB, bootargs, modelo de flash, RAM, toolchain, flags, boot sequence — obtener de evidencia con ruta citada.

## 10. STOP CONDITIONS

Detener y pedir intervención humana (con estado exacto + razón + comandos exactos + resultado esperado + datos a devolver) cuando: prueba física requerida, escritura de SD/flash, riesgo de brick, info hardware contradictoria, build roto por dependencia no comprendida, falta fuente crítica, evidencia contradice hipótesis, cambio fuera de scope, contraseña/sudo interactivo, o decisión funcional del usuario.

## 11. ESTRUCTURA DEL REPO

`AGENTS.md` (constitución) · `CURRENT.md` (snapshot, caché) · `CONTEXT_MAP.md` (router) · `DECISIONS.md` (ADRs) · `boards/` · `configs/` · `patches/` · `scripts/` · `manifests/` · `docs/` (+ `docs/ai/` contratos, `docs/experiments/`) · `tests/` · `tools/` · `out/` (ignorado, artefactos locales). Modificar estructura solo con razón técnica documentada.

## 12. HANDOFF

Toda iteración resume: `CHANGE_CLASS · OBJECTIVE · FILES_CHANGED · HEAD · CHECKS_RUN · BUILD_EVIDENCE · PHYSICAL_EVIDENCE · BLOCKER · NEXT_EXACT_ACTION · STOP_CONDITION`. El proyecto continúa desde GitHub sin este chat.
