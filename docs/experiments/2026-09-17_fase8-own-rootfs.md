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
