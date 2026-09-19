# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-18 (9m PHYSICAL PASS TOTAL: audio+video+salida-cores → **FASE 8 COMPLETA**; Fase 7 EN CURSO — 7a "diagnóstico opt-in" STAGED, deploy pendiente de SD en lector)
**Regla:** snapshot pequeño, sin historia. No changelog.

## PROJECT

r36sx-hclinux — plataforma Linux/HCLinux reproducible para R36SX V2.6 (HC16xx/MIPS), TreeFrogUI estable, control total de kernel/DTB/rootfs/build.

## CURRENT PHASE

**FASE 8 COMPLETA ✅ (2026-09-18, test del usuario con 9m):** audio (juegos+música) + video (imagen+sonido) + salida de emuladores = TODO OK bajo kernel propio. Causa raíz única ADR-012 (drift ABI; fixes gemelos auddec.h +24 B / vidmp.h +20 B). **FASE 7 (optimizaciones) EN CURSO**: 7a diagnóstico opt-in (S09trace v5 + snd_xfer budget 500) — BUILD PASS, staged.

## CURRENT OBJECTIVE

Deploy del 7a (`2546d199`) cuando la SD vuelva al lector → test físico (menos escritura SD, sin cambios funcionales esperados). Después: medir boot-to-menu con evidencia fresca (boottrace con flag) y decidir la siguiente optimización sobre datos, no conjetura. Candidatos: descomposición del ~8s (floor = init frogui ~4-5s, lado TreeFrogUI — fuera de este repo), dieta config kernel, rootfs desde SD (squashfs).

## CURRENT HEAD

`(ver git log -1 — caché)`

## KNOWN-GOOD STATE

- **9m (`1b095ac8`) — DESPLEGADO EN LA SD DE LA CONSOLA (uso diario): TODO funciona** (audio, video, juegos, salida, menú). Kernel + DTB + rootfs 100% nuestros; AVP/bootloader fábrica por diseño (ownership verificado → docs/BOOT_CHAIN.md).
- **7a (`2546d199`) — STAGED** (S09trace v5 opt-in + snd_xfer budget). Sin cambios funcionales — solo menos escrituras de diagnóstico.
- Staging por iteración en `D:\R36SX\staging\` (…-fase9m, -fase7a). Parches kernel-side en `patches/kernel/0001..0004`.
- Goldens SD: `vmlinux.uImage.stock.bak` (53b3e0b3), `avp.uImage.factory.bak` (a9788995) — intactos.

## BUILD STATUS

**R36SX-V26 KERNEL+ROOTFS OWN: BUILD PASS** (+ gates TOOLCHAIN/PATCH/DTB). bootloader.bin ausente = esperado (ADR-008). 7a: uImage 7,128,430 B (0x80000000/0x803db980).

## PHYSICAL STATUS

**PHYSICAL PASS TOTAL (9m)** — testimonio directo del usuario: videos con imagen y sonido, audio en juegos y música, salida de emuladores OK. Evidencia on-device del test en la SD (boottrace/log.txt) — cosechar al volver la SD al lector.

## SOURCE SDK SHA256

`e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` — /mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz

## ACTIVE BLOCKERS

Ninguno técnico. Pendiente operativo: SD en la consola — para deploy 7a + cosecha de evidencia 9m, llevar la SD al lector (G:).

## NEXT EXACT ACTION

1. **Usuario: SD al lector** → cosechar evidence-9m-* (boottrace/log del test PASS) → deploy 7a (autorizado implícito por la directiva de optimizar; read-back + goldens) → consola con 7a.
2. Test 7a: boot normal = CERO archivos de diagnóstico nuevos en SD; con `G:\cubegm\diag.enabled` = trazas v4 completas.
3. Con flag activo: medir timeline boot-to-menu exacto del 7a → elegir siguiente optimización (7b) con datos.

## REFERENCIA RÁPIDA

| Subsistema | Ver |
|------------|-----|
| Reglas (§13 sync, §14 provenance) | `AGENTS.md` |
| ADR-012 (drift ABI) / ADR-013 (diag opt-in) | `DECISIONS.md` |
| Ownership verificado de la cadena | `docs/BOOT_CHAIN.md` |
| Experimentos 9l/9m/7a | `docs/experiments/` |
| Parches kernel ABI+debug | `patches/kernel/` |
| Artefactos/staging | `~/work/r36sx-hclinux/artifacts/r36sx-v26/` · `D:\R36SX\staging\` |
