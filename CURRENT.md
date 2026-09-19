# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-18 (iter 8e-CLEAN-TEST-FAIL: recuperación a estado known-good completada — kernel 9m probado + layout pre-mudanza + archivos completos; boot del usuario pendiente; bisect de 3 deltas en cola)
**Regla:** snapshot pequeño, sin historia. No changelog.

## PROJECT

r36sx-hclinux — plataforma Linux/HCLinux reproducible para R36SX V2.6 (HC16xx/MIPS), TreeFrogUI estable, control total de kernel/DTB/rootfs/build.

## CURRENT PHASE

**RECUPERACIÓN:** el test de instalación limpia falló ("please insert TF Card" — pantalla del AVP cuando Linux/userspace no toma el framebuffer). Estado known-good de Fase 8 restaurado en SD (sobre el FAT32 nuevo del usuario): kernel 9m PROBADO `1b095ac8` + stack en `cubegm/` + archivos de fábrica completos. **Único pendiente inmediato: boot del usuario (recovery test).** Después: bisect de los 3 deltas nunca probados, UNO POR BOOT (ver NEXT).

## CURRENT OBJECTIVE

1. Usuario bootea la consola → esperado: menú TreeFrogUI + todo funcional (es el estado del último PASS). El kernel 9m registra boottrace SIEMPRE (S09trace v4, sin flag).
2. Bisect (una variable por boot): (a) kernel 8e con layout cubegm → (b) mudanza treefrog con 8e → (c) limpieza de archivos. La instalación limpia = fase posterior con esa secuencia.

## CURRENT HEAD

`(ver git log -1 — caché)`

## KNOWN-GOOD STATE

- **SD AHORA = estado del último PHYSICAL PASS**: kernel 9m `1b095ac8` (audio+video+salida PASS), stack en cubegm/ (120 entradas), factory completo, roms 400 archivos. Sobre FAT32 nuevo (offset 1 MiB, 32 KB clusters) — el boot valida el formato.
- Staging: fase9m `1b095ac8` (PROBADO), fase7a `2546d199` (SIN probar), fase8e `f8fb6768` (SIN probar — sospechoso principal del fail: S99app v2/S09trace v5/snd_xfer budget).
- Backup completo pre-formato: `D:\R36SX\sd-clean-install-backup-20260918\sd-full.tar` (`963dfd23…`, 4.742 archivos, restore-test 5/5 OK).
- Parches kernel: `patches/kernel/0001..0004`. Lección 8e: NO acumular deltas sin boot físico entre ellos (AGENTS §7 "una variable por experimento" aplica también a deploys).

## BUILD STATUS

**R36SX-V26 KERNEL+ROOTFS OWN: BUILD PASS** (gates PASS). Deployed en SD: **9m** (probado). bootloader.bin ausente = esperado (ADR-008).

## PHYSICAL STATUS

- **9m: PHYSICAL PASS TOTAL** (audio+video+salida-cores).
- **7a/8e: NUNCA probados físicamente** — sospechosos del fail del test limpio. Bisect pendiente.
- **Instalación limpia: FALLIDA en su primera prueba** — causa por determinar (hipótesis: kernel 8e/S99app v2, no el formato).

## SOURCE SDK SHA256

`e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` — /mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz

## ACTIVE BLOCKERS

Ninguno técnico. Nota forense: el flag de diagnóstico debe llamarse EXACTAMENTE `diag.enabled` (Windows añade `.txt` si se crea desde el explorador/notepad — usar `cmd: echo. > diag.enabled`).

## NEXT EXACT ACTION

1. **Usuario: boot de la consola (recovery test)** → menú + juego con audio + video. Reportar.
2. Con PASS: bisect (a): deploy fase8e kernel sobre el layout cubegm actual → boot test → diagnostica si el kernel 8e (S99app v2/S09trace v5/budget) es el culpable.
3. Luego (b) mudanza, (c) limpieza — un boot por paso. Instalación limpia solo al final, con base probada.

## REFERENCIA RÁPIDA

| Subsistema | Ver |
|------------|-----|
| Post-mortem 8e + plan bisect | `CHANGELOG.md` 2026-09-18 + `docs/experiments/2026-09-18_8e-stack-relocation-plan.md` |
| Contrato TreeFrogUI (boot/ABI/inventario) | `docs/TREEFROG_UI_CONTRACT.md` |
| ADR-012 (ABI) / ADR-013 (diag opt-in) | `DECISIONS.md` |
| Backup pre-formato | `D:\R36SX\sd-clean-install-backup-20260918\` |
