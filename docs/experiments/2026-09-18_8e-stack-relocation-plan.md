# Experimento 2026-09-18 — 8e: relocar el stack TreeFrogUI fuera de `cubegm/` — EJECUTADO (bind-alias)

# Objective

Mover el stack TreeFrogUI (y el ecosistema de apps del usuario) fuera del directorio de fábrica `cubegm/`. **Decisión del usuario: DEBE HACERSE** (2026-09-18). **EJECUTADO mismo día** — pendiente solo el test físico (8e-4).

# Evidence — el hallazgo que cambió el diseño

El plan original suponía regenerar `zhijack.sh` con paths nuevos (parametrización en el fork TreeFrogUI). La investigación con `strings` sobre los binarios del stack reveló **paths `/mnt/sdcard/cubegm/…` COMPILADOS DENTRO**:

- `cores/frogui_libretro.so`: **100 refs** (cores, skin, version.txt, rockbox.sh, video_player, sndgain.txt, drivers, ebook/lgpt/pcsx4all/pico286/dsperate…)
- `picoarch`: **14 refs** (bios, fonts, picoarch_hi, cores/frogui_libretro, spk_gate, drivers, driver.so)
- `video_player`/`image_viewer`: 1 ref cada uno; los OTROS cores (`.so` en `cores/`): +17 paths, incl. `zhijack.sh`
- Favoritos/recentes: en `/mnt/sdcard/frogui/` (raíz — no afectados)

**Conclusión: una mudanza física con paths nuevos requeriría recompilar frogui+picoarch+cores (forks de 2 repos más) para satisfacer la petición.** Se pivotó a **bind-alias**: el stack VIVE en `/treefrog/` y nuestro `S99app` lo monta sobre `/mnt/sdcard/cubegm` en cada boot — los binarios siguen encontrando sus paths compilados, cero rebuilds, cero cambios en el fork TreeFrogUI.

# Files changed

1. `boards/r36sx-v26/rootfs-overlay-own/etc/init.d/S99app` **v2 (8e)**: espera `treefrog/zhijack.sh` (con fallback legacy `cubegm/zhijack.sh` — compatible con SDs antiguas) + `mount --bind /mnt/sdcard/treefrog /mnt/sdcard/cubegm` si el layout nuevo existe.
2. `boards/r36sx-v26/rootfs-overlay-own/etc/init.d/S09trace` **v5.1 (8e)**: `diag_on()`/`sd_copy()` iteran `cubegm/` y `treefrog/` (flag `diag.enabled` en cualquiera de los dos).
3. SD: **39 ítems movidos** `cubegm/ → /treefrog/` (29 archivos + 10 dirs) — manifiesto con sha256 PREVIO por ítem en `manifest-8e-move-20260918.txt` (copia en `D:\R36SX\staging\`). Re-hash POST == 100% OK.
4. Fork TreeFrogUI: SIN CAMBIOS (la rama de trabajo se eliminó — no se necesita; el diseño bind-alias no toca upstream).

# Commands (exactas)

```bash
# strings-evidencia del hardcodeo
for b in cores/frogui_libretro.so picoarch picoarch_hi video_player image_viewer; do strings -a "$b"; done | grep -o '/mnt/sdcard/cubegm/[A-Za-z0-9_.%-]*' | sort -u
# build + deploy + mudanza
./scripts/build_kernel.sh r36sx-v26   # fase8e f8fb6768
cp staging/vmlinux.uImage-r36sx-v26-fase8e /mnt/g/cubegm/vmlinux.uImage   # ANTES de mudar: S99app v2 es backward-compatible
mv <39 items> /mnt/g/treefrog/        # mismo volumen FAT32: renames
```

# Build result

**BUILD PASS** — uImage **`f8fb6768` 7,129,224 B** (0x80000000/0x803db980). S99app v2 verificado embebido (cpio sha == repo `fdbf3c44`), S09trace v5.1 embebido. Deploy a SD verificado read-back; goldens intactos (stock `53b3e0b3`, avp `a9788995`).

# Tests

- STATIC: S99app v2 fallback (legacy cubegm/zhijack.sh presente → funciona igual) — probado por diseño (deploy 8e se hizo ANTES de la mudanza con layout legacy en SD).
- DOWNLOAD-BACK PASS: kernel 8e en SD == staging.
- INTEGRIDAD: 29/29 archivos re-hash == manifiesto; dirs verificados presentes en treefrog/ y ausentes en cubegm/.
- **PHYSICAL: PENDIENTE (8e-4)** — boot esperado: kernel 8e → S99app detecta treefrog/ → bind alias → menú TreeFrogUI normal. Regresión: juego con audio + video + salida.

# Result

**EJECUTADO** (físico pendiente): `cubegm/` = SOLO fábrica (80 entradas: assets .cpd/.wav/.ttf, icube/rkgame/MyExecutable, driver.so, setting.xml, dtb.bin, avp.uImage + goldens, vmlinux 8e, logs de diagnóstico). `/treefrog/` = stack TreeFrogUI completo (39 ítems: picoarch, cores, drivers, apps del ecosistema, lib/, usr/, bios/, saves/, skin/…).

# Interpretation / Tradeoffs documentados

1. **Rollback stock queda 100% INTACTO a nivel de archivos** (nuestro kernel no es necesario para ver el cubegm/ real); PERO el boot de fábrica ya NO hijackea TreeFrogUI (setting.xml→libemu_tfhijack→`cubegm/zhijack.sh` ya no existe) → el boot stock muestra el MENÚ DE FÁBRICA. Consola usable siempre; el stack vuelve con un `mv` inverso si se desea.
2. El alias cubre TODO lo que los binarios leen de cubegm/ (lista strings completa ⇒ lista de mudanza). `driver.so` (fábrica, hash == driver_r36sx.so que sí se mudó) queda solo en cubegm/ — el check que lo lee es exclusivo de TF_DEVICE=SF3000 (nunca en R36SX).
3. `menu.log`/`allfiles.lst`/`root.dat` (sin refs en binarios) quedaron en cubegm/ — artifacts estáticos.
4. El "true path relocation" (recompilar binarios sin cubegm/) queda documentado como posible contribución upstream futura (parametrizar base-path en FrogUI/picoarch).

# Decision

ADR-013 (diag opt-in) extendido de facto a ambos layouts. La decisión de diseño "stack en /treefrog/ + alias por bind" es la implementación 8e aprobada por el usuario.

# Artifact hashes

kernel fase8e `f8fb6768784126d5…` (7,129,224 B) · S99app v2 `fdbf3c44…` · manifiesto de mudanza: `manifest-8e-move-20260918.txt` (este dir).

# Next action

**Usuario: boot físico de la consola (8e-4)** — menú TreeFrogUI debe aparecer normal (via treefrog-alias); probar un juego (audio), un video y la salida. La evidencia se captura con `diag.enabled` si se quiere (en treefrog/ o cubegm/).

---

## Addendum 8e-CLEAN-INSTALL (2026-09-18, tarde) — formateo + instalación 100% propia

El usuario elevó el test 8e-4 a **CLEAN-INSTALL PHYSICAL TEST**: formatear la SD y reinstalar solo nuestro desarrollo. Decisión adicional del usuario: **"100% nuestro sistema"** (sin núcleo del menú de fábrica en cubegm/).

**Secuencia ejecutada:**

1. **Backup pre-formato completo y verificado** (gate de seguridad §5): `D:\R36SX\sd-clean-install-backup-20260918\sd-full.tar` — 1,77 GB, sha256 `963dfd23…`, 4.742 archivos + `critical.sha256` + prueba de restauración 5/5 (hashes idénticos). NADA se pierde.
2. **Formato**: FAT32 etiqueta "R36SX" — ejecutado por el usuario (interrumpió el comando agente para hacerlo manualmente).
3. **Restauración selectiva** del tar (nota drvfs: tar directo sobre el mountpoint requiere `--no-overwrite-dir --no-same-owner --no-same-permissions`).
4. **Poda "100% nuestro"**: `cubegm/` → solo 5 archivos de boot (kernel 8e, dtb fábrica `1258f1eb` [semánticamente == nuestro build, ADR-010], avp fábrica, goldens). Eliminados 98 ítems: núcleo fábrica de cubegm (icube/rkgame/MyExecutable/setting.xml/driver.so/assets), 14 dirs de sistema placeholder (ATARI…WSC: solo `filelist.csv` de 3 B + `images/` vacío — **los juegos reales viven en `roms/`, conservados**), MD/ (dummy del hijack stock), media dirs vacíos, chkdsk, logs de diagnóstico. Manifiesto: `manifest-8e-cleaninstall-20260918.txt`.
5. **Verificación**: hashes boot/stack TODOS OK (kernel `f8fb6768`, dtb `1258f1eb`, avp `a9788995`, golden `53b3e0b3`, zhijack `14b55648`, picoarch `02642931`); conteos == esperados (treefrog 2.304, rootfs 602, roms 400, frogui 1.280). (Un FAIL visual en el script era typo del string esperado del golden — verificado correcto por hash directo.)

**Estado**: CLEAN-INSTALL en SD, verificada estáticamente. **PHYSICAL TEST PENDIENTE (usuario)** — criterio PASS: boot → menú TreeFrogUI → juego con audio → video → salida de core. Nota operativa: el rollback a menú fábrica ya no es posible on-card (fábrica completa recuperable del backup tar en ~15 min).
