# Experimento/Plan 2026-09-18 — 8e: relocar el stack TreeFrogUI fuera de `cubegm/`

# Objective

Mover el stack TreeFrogUI (y el ecosistema de apps del usuario) fuera del directorio de fábrica `cubegm/`, dejando en `cubegm/` SOLO las piezas de fábrica — de forma que (a) el boot propio no dependa de nada en `cubegm/`, (b) el rollback stock siga siendo posible, (c) quede documentado qué es de quién. **Decisión del usuario: DEBE HACERSE** (2026-09-18).

# Evidence (inventario clasificado)

Ver `docs/TREEFROG_UI_CONTRACT.md` §5 — clasificación completa de `cubegm/` con hashes y mtimes: fábrica (icube/rkgame/driver.so/assets .cpd/.hc/fonts/wavs/skin…), stack TreeFrogUI (picoarch/cores/zhijack/driver_r36sx*/video_player/usb tools/lib/…), ecosistema usuario (lgpt/rockbox/pcsx4all/pico286/ebook), diagnóstico.

**Referencias al path `/mnt/sdcard/cubegm/…` que romperían una mudanza ingenua** (mapeadas):

| Referencia | Vive en | Dueño del cambio |
|---|---|---|
| ~20 rutas en `zhijack.sh` (PICOARCH, FROGUI_CORE, TF_DRIVER, DRV_SAFE, tfupdate, settings, log.txt) | SD `cubegm/zhijack.sh` — **GENERADO** por `hijack/zhijack.tpl.sh` de build_release.sh | **repo TreeFrogUI (fork ozkaoz)** |
| `S99app`: espera `/media/*/cubegm/zhijack.sh`, `LD_LIBRARY_PATH=cubegm/{lib,usr/lib}` | NUESTRO rootfs (`boards/r36sx-v26/rootfs-overlay-own/etc/init.d/S99app`) | **este repo** |
| `picoarch`/frogui config paths (`/mnt/sdcard/cubegm/skin/…`, `cores/…` relativos al binario) | binarios/libretro — usan mayormente paths relativos al exe | upstream (riesgo bajo) |
| stock chain (setting.xml→libemu_tfhijack→zhijack) | SOLO boot stock | fábrica — quedará sin hijack (aceptado, ver tradeoffs) |

# Hypothesis

La mudanza puede hacerse SIN tocar binarios: (1) el fork TreeFrogUI parametriza el install-dir en `zhijack.tpl.sh` (variable `TF_INSTALL_DIR`, default `cubegm` para compatibilidad upstream) y regenera zhijack para `treefrog`; (2) nuestro `S99app` apunta al nuevo dir (variable `TFDIR`); (3) los archivos se MUEVEN en la SD (mismo volumen FAT32 = rename rápido); (4) `rootfs/` de fábrica (libffplayer/libhudi) NO se toca.

# Plan (fases ejecutables — una variable por iteración)

- **8e-1 (repo TreeFrogUI fork):** rama `relocate-treefrog-dir` en `D:\GitHub\TreeFrogUI` — parametrizar `TF_INSTALL_DIR` en `hijack/zhijack.tpl.sh` + `build_release.sh` (regenerar zhijack.sh del release con install dir `treefrog`). Probar build del release. *(ese repo requiere crear su AGENTS.md al primer cambio — regla del mapa maestro)*
- **8e-2 (este repo):** S99app v2: busca el stack en `/media/*/treefrog/zhijack.sh` (con fallback a `cubegm/` para SDs antiguas) + `LD_LIBRARY_PATH` apuntando al nuevo dir. Rebuild + stage `fase8e`.
- **8e-3 (SD, con autorización):** mover SOLO los archivos del stack/ecosistema (inventario §5 del contrato) `cubegm/ → /treefrog/` en la SD (mismo volumen: `mv` instantáneo). Backup previo de la lista+hashes en el repo. `cubegm/` queda con solo fábrica (rollback stock intacto) + setting.xml (pantalón del stock-hijack).
- **8e-4:** deploy `fase8e` + test físico: boot directo al menú (nuevo dir), juego+audio+video+salida; boot stock.bak → menú fábrica (hijack degradado aceptado).

# Tradeoffs documentados

1. **Rollback stock pierde el hijack de TreeFrogUI** (setting.xml no encontrará zhijack en cubegm) → el rollback arranca el MENÚ DE FÁBRICA (consola usable, sin TreeFrogUI). Aceptable: el golden recovery es "consola funcional", y el stack se puede mover de vuelta con un `mv` inverso.
2. `driver.so` (fábrica, 58b180a2) queda en cubegm; `driver_r36sx.so` (hash idéntico, copia TreeFrogUI) se muda — sin pérdida.
3. `setting.xml` es híbrido (fábrica + hotkeys TreeFrogUI): QUEDA en cubegm (el stock lo necesita); el boot propio no lo lee.
4. Duplicados cero: es un `mv`, no una copia.

# Result

PLAN APROBADO POR EL USUARIO (pendiente ejecución 8e-1..8e-4). La clasificación y hashes ya quedan registrados en TREEFROG_UI_CONTRACT.md §5.

# Next action

**8e-1** en el repo del fork TreeFrogUI (parametrización + regeneración). Requiere acceso a `D:\GitHub\TreeFrogUI` — primera iteración de la próxima sesión (o de esta, si el usuario da paso a seguir).

# Artifact hashes

Stack a mudar (sha256-16): zhijack.sh 14b55648 · picoarch 02642931 · picoarch_hi b92e0fef · frogui_libretro.so a3dad067 · driver_r36sx 58b180a2 · driver_r36sx27 e46d5bf3 · driver_sf3000 90727162 · driver_sf3500 a3024878 · driver_gb350 4d7e8bb5 · video_player 0347e4bf · image_viewer 68a310de · mtp-server 6a26099f · nosleep 1e4f3cc3 · powergpio 2148befa · tfupdate 95f689f0 · shutdown d93bc1d0 · usb_mode 20ab52ff · version 2bef00c8 · pcsx4all 94036292 (+ lgpt/lgpt.elf/rockbox/pico286/ebook + dirs cores|lib|usr|language|bios|saves|modules|dsperate|skin†).
† skin/ es de fábrica (mtime 1980, usado por menú stock) — NO se muda.
