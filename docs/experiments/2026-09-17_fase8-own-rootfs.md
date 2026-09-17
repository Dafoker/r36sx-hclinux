# Experimento: 2026-09-17 — Fase 8a: ROOTFS 100% PROPIO (Buildroot) — PHYSICAL PASS

# Objective

Reemplazar el initramfs extraído-de-fábrica por un rootfs **100% nuestro** (Buildroot userland), manteniendo el contrato de arranque validado (Fase 5/6), hasta el menú TreeFrogUI.

# Método

1. **Overlay mínimo propio** (`boards/r36sx-v26/rootfs-overlay-own/`): linuxrc→busybox, inittab, fstab, rcS/rcK, S10mdev, S41hcdaemon, S99app, mdev.conf + mount-helper.sh (contrato validado Fase 5/6), `usr/bin/hcdaemon` (única pieza userland propietaria, extraída del stock initramfs — documentada). Todo lo demás lo pone Buildroot (busybox SDK-config + glibc Codescape + esqueleto).
2. **Defconfig**: `BR2_ROOTFS_OVERLAY` → overlay-own; `BR2_TARGET_ROOTFS_CPIO=y` (cpio CRUDO — paridad de embebido con fábrica, RD_* off).
3. **Fragment**: `CONFIG_INITRAMFS_SOURCE` → `rootfs-own.cpio` (el cpio de Buildroot, no el árbol de fábrica).
4. **build_kernel.sh flujo 8a**: defconfig → (bootstrap placeholder cpio) → `make rootfs-cpio` → copy → `make linux-rebuild` (re-embed con FORCE de usr/Makefile) → `make all`. Limpieza del target contaminado de overlays anteriores (rm target + .stamp_target_installed).

# Iteraciones

- **8a (uImage 72c50ceb, cpio 28,207,104 B)**: primer build del rootfs propio. **FALLO físico**: logo eterno — causa raíz: `/mnt/sdcard` y `/hcdemo_files` NO existían en el esqueleto buildroot → el bind de S99app fallaba → `/mnt/sdcard/cubegm/icube.sh` inexistente → la UI jamás arrancaba. (La fábrica tenía ambos dirs; el esqueleto de buildroot no.) Además `free`/`awk` viven en `/usr/bin` (verificados presentes).
- **8b (uImage 38c9749d)**: fix dirs (`mnt/sdcard`, `hcdemo_files` en overlay-own) + **S09trace** (trazador de boot: snapshot ps+mounts cada 2s a /tmp, copia viva a la SD en cuanto /media/*/cubegm aparece — debugging ciego resuelto para siempre).

# RESULTADO — PHYSICAL PASS (2026-09-17)

> La consola bootea al MENÚ TreeFrogUI navegable con kernel propio + userland 100% propio.

Evidencia `evidence-fase8-boottrace.log` (vivo, desde la SD):
- Cadena completa corriendo: init(busybox nuestro) → syslogd/klogd (buildroot) → S09trace → hcdaemon → icube → rkgame → zhijack.sh (rama RAM) → cubevol → nosleep → **picoarch+frogui_libretro.so (menú)**.
- Los 7 binds de la SD completos: /media/mmc, /mnt/sdcard, /lib, /usr, /bin, /sbin, /etc.
- Kernel: `Linux version 4.4.186-release (dafunknoise@DFNK) #18`.

# Verificación de "sin resabios de fábrica" (petición explícita del usuario)

- busybox embebido = **NUESTRO build** (sha `691d9b24...` ≠ fábrica `45de390...`) — receta SDK (mismo config+toolchain → mismo tamaño 867,948 B) pero binario distinto/propio.
- Árbol embebido = 498 archivos (fábrica: 380) — buildroot + overlay, **sin el árbol de fábrica**.
- Scripts del contrato (S10/S41/S99/mdev/mount-helper) = byte-iguales al stock **por diseño** (son el contrato validado; ya eran "nuestros" desde 6w).
- Pieza propietaria única: `hcdaemon` (610,404 B) — documentada como dependencia del contrato.
- Por diseño (no "resabios"): DTB de la SD = stock (≡ al nuestro, semantic 0-diff); AVP firmware = stock (ADR-008); TreeFrogUI cubegm/ = v1.5.0_j del usuario.

# Limitaciones conocidas (heredadas, diferidas)

- Media AVP (audio/video) + salida de cores colgadas — hipótesis mismatch media-proxy SDK-2024 vs AVP-fábrica-2025 (ver 2026-09-17_fase6-diag6x-analysis.md).
- Rootfs de 26.9 MiB (uImage 13.35 MiB) — **dieta pendiente** (defconfig del vendor arrastra todos sus apps: 28 MB target).
- S09trace escribe boottrace.log a la SD continuamente (crece con el uso) — **hacer self-limiting en el próximo build** (parar tras detectar picoarch o N minutos).

# Próximos pasos

1. **8c-dieta**: defconfig slim (quitar apps vendor: hccast/hcprojector/ffmpeg...) + S09trace self-limiting → uImage ~5-7 MiB.
2. Media fix (diferido): cable USB-TTL.
3. Fase 8 CLEAN-INSTALL final: requiere media + dieta.

# Iteración 8c — DIETA + tracer auto-limitante (2026-09-17, PHYSICAL PASS)

- **Dieta del defconfig**: 26 paquetes vendor fuera (FFMPEG ~4.5MB, OpenSSL ~2.8MB, WiFi RTL8188FU/8811CU/SSV6X5X ~6MB en .kos, wpa_supplicant/hostapd/libnl ~3MB, hccast/prebuilts/avpconsole/hc-examples, ntfs/exfat) + **HUDI** (trampa: `default y` del vendor en su Config.in — no estaba explícito; su .mk exige prebuilts → el dependency-check lo reveló) + LIBLVGL + HCFOTA.
- Rootfs: **26,9 → 10,4 MiB** | uImage: **13,35 → 6,80 MiB** (`2081f406`).
- **S09trace auto-limitante**: muere tras detectar picoarch (verificado: 4 snapshots, log 7,995 B final).
- **PHYSICAL PASS 8c**: menú navegable. `evidence-fase8c-boottrace.log`.

## Timeline del boot 8c (del trace, uptime kernel)

| Hito | Uptime | Delta |
|---|---|---|
| init (fin unpack 10,4 MiB cpio) | 1,08 s | — |
| SD montada + icube | 5,53 s | ~4,4 s (mdev + mount-helper [sleeps vendor] + binds + icube) |
| zhijack + picoarch (MENÚ) | 8,38 s | ~2,9 s (icube→rkgame→libemu_tfhijack→zhijack→picoarch) |

**Optimización de arranque (Fase 7 / 8d)**: la cadena icube→rkgame→hijack consume ~2,9 s — **el 8d (lanzamiento directo de zhijack.sh) la elimina por diseño**. Otras vías: sleeps del mount-helper (vendor), trim de glibc (busybox solo necesita libc+libcrypt; hcdaemon es ESTATICO — verificado).

## Siguiente: 8d — icube-direct (lanzar zhijack.sh desde nuestro S99app)

zhijack.sh: congela icube + mata rkgame al arrancar (solo son vehículo), auto-lanza cubevol (input), soporta dispositivos sin icube (SF3500). Nuestro S99app-direct: espera `/cubegm/zhijack.sh` + `LD_LIBRARY_PATH` (lo que ponía icube.sh) + lanza zhijack. Prueba definitiva: renombrar `icube` en la SD.

# Iteración 8d — ICUBE-DIRECT (2026-09-17, PHYSICAL PASS) — cadena de fábrica ELIMINADA

- S99app-direct: espera `/cubegm/zhijack.sh` (no icube) + `LD_LIBRARY_PATH` (lo que ponía icube.sh) + lanza `zhijack.sh` directamente. uImage `03807054` (payload 7,124,711 B).
- **Prueba definitiva**: `icube` RENOMBRADO a `icube.disabled` en la SD — y la consola **bootea al menú navegable igual**.
- **Evidencia** `evidence-fase8d-boottrace.log`: ps SIN icube NI rkgame — cadena limpia: `zhijack(RAM) → cubevol → nosleep → picoarch+frogui_libretro.so`.
- Timeline 8d: init@1,07s → **menú@~8,1s** (8c era 8,38s). El launcher-chain solo costaba ~0,3s.
- **Descubrimiento de optimización**: el pozo real de boot es la **fase de montaje SD (1,1→5,5s)**: mdev hotplug + `mount-helper.sh` (sleeps del vendor) + binds; luego ~2,5s de arranque zhijack→picoarch→frogui (lado TreeFrogUI).

## Arquitectura del boot tras 8d (estado actual)

```
[bootloader+AVP stock] → KERNEL NUESTRO (userland propio embebido)
  → linuxrc→busybox(nuestro) → rcS(nuestro)
  → S10mdev(nuestro) → mdev → mount-helper(nuestro, copia del contrato)
  → S41hcdaemon → hcdaemon (única pieza fábrica, estática)
  → S99app(NUESTRO, 8d-direct) → zhijack.sh (TreeFrogUI del usuario)
  → cubevol + nosleep + picoarch + frogui_libretro.so = MENÚ
  [icube/rkgame/libemu_tfhijack: ELIMINADOS del boot path]
```

# Iteración 8f — boot-opt (2026-09-17) — sin ganancia visible; cambios conservados

- S99app: montaje DIRECTO de /dev/mmcblk0p1 (sin esperar mdev -s) + poll 0.5→0.1s. mount-helper: sleep vendor 1→0.2s (camino coldplug). uImage `d104f4d7`.
- **Test físico: boot sigue ~8s** — sin ganancia perceptible. El timeline percibido: kernel+unpack ~1s, montaje ~1-2s (el directo puede haber fallado silenciosamente o no era el cuello), **init TreeFrogUI (zhijack→cubevol→picoarch→frogui, recursos ui_*.cpd) ~4-5s = el floor dominante** (lado TreeFrogUI, no nuestro kernel).
- Decisión del usuario: ~8s aceptado; el floor de TreeFrogUI se optimiza en SU repo (frogui init/parse), no aquí. Cambios 8f conservados (beneficiosos/inofensivos).
- PRIORIDAD PIVOT (usuario): **fix de raíz del problema AVP-media** (audio/video/salida de cores) como requisito de Fase 8 completa.

# Iteración 8g — PIVOT: fix AVP-media (análisis + estrategias, 2026-09-17)

## Diagnóstico consolidado del problema AVP

- Transporte AMPRPC SANO bajo nuestro kernel (IRQ 66 ~300/s igual que fábrica; kshmdev ok; rpcwork activos; ZZd2C funciona — hcdaemon lo usa).
- El AVP ACKa las llamadas: **dmesg sin UN solo pr_err del avp-proxy** — sin timeouts kernel-side visibles.
- Muerto: SOLO la familia media (audio en todo, decode video) + salida de cores (cuelga en drain de audio).
- Refutado con builds limpios: drivers extra (7c), UART probe (7e), /etc bind (7b), contenido SD/TreeFrogUI (funciona en stock).
- **Evidencia nueva (avp.uImage decompilado strings)**: el AVP de fábrica = build `avp-custom` desde `buildroot/output/E3100_R36/` — MISMA línea hclinux que nuestro SDK (FreeRTOS/MIPS32_HC16xx, estructura idéntica) → **drift de versión dentro de la misma familia** (ABI con IDs/structs evolucionados, Dic-2025 vs Jul-2024). Parcheable por RE.

## Estrategias (ranked)

| # | Estrategia | Costo | Estado |
|---|---|---|---|
| A | Cable USB-TTL (ttyS1@18818600 115200) — dmesg en vivo durante reproducción | ~$5-10 | USUARIO: pedirlo |
| B | **diag9**: consola del AVP (avpconsole//dev/virtuart) + open-probe de nodos + dmesg fresco — comparativa stock-vs-nuestro | $0 | **DESPLEGADO (G:\diag9.sh)** |
| C | Diff binario avp-proxy fábrica (stock.bin) vs nuestro avp-proxy.c → parchear ABI | 1-3 días RE | EN ARRANQUE |
| D | SDK más nuevo vía ecosistema (tzubertowski/comunidades HC16xx: SF3500/GB350/R36SX) | un mensaje | USUARIO: opcional |
| E | Driver I2S propio sin AVP (último recurso) | semanas | No recomendado |

## Checklist Fase 8 COMPLETA (acordado con usuario: todo debe funcionar)

✅ boot propios · ✅ menú · ✅ launcher eliminado · ✅ dieta
❌ audio juegos · ❌ música · ❌ video · ❌ salida de cores (= 1 causa raíz AVP)
⏳ 8e clean-install (TreeFrogUI fuera de cubegm)
# Ronda diag9-1 (kernel 8f) + incidente stock-boot (2026-09-17)

- **diag9 ronda-1** (evidence-diag9-ownkernel.log): opens media OK (auddec/audsink/viddec/vidsink/avsync0/sndC0i2so/kshmdev/mmz/virtuart/ZZd2C rc=0 — el AVP ACEPTA los opens de media); 4 rechazados con error proxy (sndC0spo/sndC0i2si/vindvp/pq — probablemente servicios ausentes en este build del AVP en AMBOS kernels — confirmar en ronda 2); ioctls de picoarch: cero errores kernel-side (el fallo queda acotado a la capa ioctl post-open); virtuart mudo a los 18s.
- **BLANCO DEL RE AFINADO**: el protocolo open funciona (nombres/servicios reconocidos por el AVP) → el drift ABI está en los OPCODES/STRUCTS de los ioctls post-open — superficie chica para el diff binario (tabla de dispatch del proxy).
- **INCIDENTE**: boot stock sin menú tras el swap — causa: icube seguía renombrado (icube.disabled) de la prueba 8d. **El kernel de FÁBRICA necesita cubegm/icube (su S99app lo espera); los kernels 8d/8f NO**. PROTOCOLO: todo swap a stock requiere icube presente. Restaurado y verificado.
