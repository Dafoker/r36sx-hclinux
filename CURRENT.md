# CURRENT.md — Snapshot operacional (CACHÉ — Git es la verdad)

**Actualizado:** 2026-09-18 (Fase 8/media — FIX VIDEO 9m DESPLEGADO en SD, test físico pendiente; AUDIO PHYSICAL PASS 9l por fix ABI 24 B en auddec.h)
**Regla:** snapshot pequeño, sin historia. No changelog.

## PROJECT

r36sx-hclinux — plataforma Linux/HCLinux reproducible para R36SX V2.6 (HC16xx/MIPS), TreeFrogUI estable, control total de kernel/DTB/rootfs/build.

## CURRENT PHASE

**FASE 8/media — causa raíz ENCONTRADA y en cierre.** ADR-012: drift ABI headers SDK Jul-2024 ↔ binarios userspace fábrica Dic-2025 (sizeof codificado en el ioctl). **AUDIO: PHYSICAL PASS (9l)** — fix `_pad_abi_2025[24]` en `struct audio_config`. **VIDEO: fix 9m desplegado, test físico PENDIENTE** — `_pad_abi_2025[20]` en `struct video_config` (VIDDEC_INIT ahora 0x82980400 == fábrica).

## CURRENT OBJECTIVE

Test físico del 9m: reproducir un VIDEO → **imagen visible** (criterio PASS). Regresión: audio (juego + música) sigue OK y menú navegable. Con PASS: familia AVP-media cerrada → Fase 8 COMPLETA → siguiente: optimizaciones/limpieza (7) y decisiones de siguiente fase.

## CURRENT HEAD

`(ver git log -1 — caché)`

## KNOWN-GOOD STATE

- **9l (`f1e8e3eb`) — AUDIO FUNCIONA** (player MP3 + juegos). Último good físico verificado.
- **9m (`1b095ac8`) — DESPLEGADO en G: (read-back verificado), test físico pendiente.** Video fix: vidmp.h +20 B.
- Stack en SD: kernel propio 9m + rootfs propio (Buildroot, 8a-8f) + TreeFrogUI v1.5.0 (cubegm) + **AVP de FÁBRICA** (`a9788995`, tras refutar avp-own 9b/9e — incidente stock-icube) + dtb propio (`04fb8383`, semántico 0-diff).
- Goldens intactos: `vmlinux.uImage.stock.bak` (53b3e0b3), `avp.uImage.factory.bak`.
- Staging completo por iteración en `D:\R36SX\staging\` (8a..9l + 9m). Parches kernel-side vs SDK en `patches/kernel/0001..0004`.

## BUILD STATUS

**R36SX-V26 KERNEL+ROOTFS OWN: BUILD PASS** (+ provenance gates TOOLCHAIN/PATCH/DTB). bootloader.bin ausente = esperado (ADR-008). uImage 9m 7,127,573 B (0x80000000/0x803db8a0).

## PHYSICAL STATUS

- **AUDIO: PHYSICAL PASS (9l)** — sound_driver vivo durante juegos; AVP abre sndC0i2so CFG 48K; GET_CUR_TIME ×1442 en playback (MP3).
- **VIDEO: FIX DESPLEGADO (9m) — PHYSICAL TEST PENDIENTE** (hipótesis fuerte: imagen aparecerá; el AVP ya decodificaba H264 — `VER:H264 allocsz=0x321b000 vdec sync stc` — solo le faltaba el handle kshm).
- Menú/juegos/entrada: OK desde 6x/8-series (sin cambios en 9m).

## SOURCE SDK SHA256

`e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` — /mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz

## ACTIVE BLOCKERS

1. **Test físico 9m** — requiere el usuario (boot consola + reproducir video). Evidencia caerá en SD (S09trace + zhijack log.txt).
2. Bare-metal mips32-mti-elf para AVP/hcboot propios — RESUELTO de facto (toolchain público Codescape 2019.09, avp.bin propio construido en 9a) aunque el plan A es el ABI-fix del proxy (ADR-012), no el AVP propio.

## NEXT EXACT ACTION

1. **Usuario: boot con 9m + reproducir un VIDEO** (TreeFrogUI → media player). PASS = imagen visible; FAIL = traer SD/logs (boottrace + virtuart + log.txt ya se copian solos).
2. Regresión rápida: un juego con audio + un MP3.
3. Con PASS: cerrar Fase 8 en ROADMAP; siguiente fase (7 optimizaciones / próximo objetivo del usuario).

## REFERENCIA RÁPIDA

| Subsistema | Ver |
|------------|-----|
| Reglas (§13 sync, §14 provenance) | `AGENTS.md` |
| ADR-012 (drift ABI, política) | `DECISIONS.md` |
| Experimento 9m (fix video) | `docs/experiments/2026-09-18_fase9m-video-abi-fix.md` |
| Evidencia 9l (audio PASS) | `docs/experiments/evidence-9l-*.log` |
| Parches kernel ABI+debug | `patches/kernel/` |
| Modelo stock / memoria / panel | `docs/DTS_STOCK_MODEL.md` |
| Direcciones boot | `docs/BOOT_CHAIN.md` |
| Artefactos/staging | `~/work/r36sx-hclinux/artifacts/r36sx-v26/` · `D:\R36SX\staging\` |
