# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-18 (iter 7a-RESULT: 7a DESPLEGADO en SD + contrato formal Fase 6 + plan 8e aprobado; Fase 8 COMPLETE; Fase 7 en curso)
**Regla:** snapshot pequeño, sin historia. No changelog.

## PROJECT

r36sx-hclinux — plataforma Linux/HCLinux reproducible para R36SX V2.6 (HC16xx/MIPS), TreeFrogUI estable, control total de kernel/DTB/rootfs/build.

## CURRENT PHASE

**FASE 7 (optimizaciones) EN CURSO.** 7a (diagnóstico opt-in ADR-013) **DESPLEGADO en SD** (`2546d199`, read-back OK) — pendiente su test físico (boot normal = cero escrituras de diagnóstico). **8e (relocación stack TreeFrogUI fuera de cubegm/) APROBADA por el usuario** — plan de 4 fases listo; siguiente paso = 8e-1 en el repo fork TreeFrogUI. Fase 8 COMPLETE (9m PHYSICAL PASS TOTAL).

## CURRENT OBJECTIVE

1. **8e-1**: en `D:\GitHub\TreeFrogUI` (fork ozkaoz) parametrizar `TF_INSTALL_DIR` en `hijack/zhijack.tpl.sh` + regenerar zhijack para install dir `treefrog` (ese repo necesita su AGENTS.md al primer cambio — regla del mapa maestro).
2. Luego 8e-2 (S99app v2, este repo) → 8e-3 (mv en SD, autorizado por directiva del usuario) → 8e-4 (deploy+test).
3. Paralelo 7b: medir timeline boot-to-menu con flag `diag.enabled` activo → siguiente optimización con datos.

## CURRENT HEAD

`(ver git log -1 — caché)`

## KNOWN-GOOD STATE

- **9m (`1b095ac8`) — PHYSICAL PASS TOTAL** (audio+video+salida-cores, test del usuario). Evidencia en `docs/experiments/evidence-9m-*` (log.prev = sesión VIDEO_PLAYER del test).
- **7a (`2546d199`) — DESPLEGADO EN SD, test físico pendiente** (producción silenciosa; `G:\cubegm\diag.enabled` habilita trazas v4 completas).
- Stack SD: kernel propio 7a + rootfs propio (10,4 MiB) + TreeFrogUI v1.5.0 en `cubegm/` (hasta 8e) + AVP fábrica + dtb propio.
- Goldens intactos: `vmlinux.uImage.stock.bak` (53b3e0b3), `avp.uImage.factory.bak` (a9788995).
- Staging: `D:\R36SX\staging\` (…-fase9m, -fase7a). Parches kernel: `patches/kernel/0001..0004`.

## BUILD STATUS

**R36SX-V26 KERNEL+ROOTFS OWN: BUILD PASS** (+ gates TOOLCHAIN/PATCH/DTB PASS). bootloader.bin ausente = esperado (ADR-008). 7a: uImage 7,128,430 B (0x80000000/0x803db980).

## PHYSICAL STATUS

**PHYSICAL PASS TOTAL (9m)** — verificado por el usuario: videos (imagen+sonido), audio juegos/música, salida de emuladores OK. **7a en SD: test físico pendiente** (sin cambios funcionales esperados — solo diagnósticos opt-in).

## SOURCE SDK SHA256

`e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` — /mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz

## ACTIVE BLOCKERS

Ninguno técnico. **8e-1 requiere trabajo en el repo fork TreeFrogUI** (cross-repo; su primera iteración debe crear AGENTS.md allí).

## NEXT EXACT ACTION

1. **8e-1**: branch en `D:\GitHub\TreeFrogUI`, parametrizar `TF_INSTALL_DIR` en zhijack.tpl.sh + build_release.sh, regenerar zhijack.sh, build del release con dir `treefrog`.
2. 8e-2: S99app v2 (este repo) + rebuild + stage fase8e.
3. 8e-3: mv del stack en SD (según inventario con hashes del contrato §5) — con backup de lista en el repo.
4. 8e-4: deploy + test físico (boot propio al menú desde dir nuevo; stock.bak → menú fábrica).
5. Test 7a: boot de producción (sin flag) → cero logs de diagnóstico en SD; con flag → trazas completas.

## REFERENCIA RÁPIDA

| Subsistema | Ver |
|------------|-----|
| Reglas (§13 sync, §14 provenance) | `AGENTS.md` |
| Contrato formal TreeFrogUI (inventario+hashes) | `docs/TREEFROG_UI_CONTRACT.md` |
| Plan 8e (relocación stack) | `docs/experiments/2026-09-18_8e-stack-relocation-plan.md` |
| ADR-012 (ABI) / ADR-013 (diag opt-in) / ADR-011 (superseded) | `DECISIONS.md` |
| Ownership verificado de la cadena | `docs/BOOT_CHAIN.md` |
| Evidencia 9m/9l on-device | `docs/experiments/evidence-9*` |
| Artefactos/staging | `~/work/r36sx-hclinux/artifacts/r36sx-v26/` · `D:\R36SX\staging\` |
