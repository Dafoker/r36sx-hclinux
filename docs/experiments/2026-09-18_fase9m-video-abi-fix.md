# Experimento 2026-09-18 — Fase 8/media (iteración 9m): fix del video por drift ABI (padding 20 B en `struct video_config`)

# Objective

Reproducir para VIDEO el mismo fix que hizo funcionar el AUDIO en 9l (padding ABI en el struct UAPI del kernel para que el `switch(cmd)` del avp-proxy matchee el ioctl exacto que emiten los binarios userspace de fábrica), y desplegarlo a la SD para test físico.

# Hypothesis

**H1 (confirmada para audio en 9l, misma patología asumida aquí):** el userspace de fábrica (Dic-2025) y los headers UAPI del SDK (Jul-2024) tienen el mismo struct con sizeof DISTINTO; como `_IOW/_IOR` codifica el sizeof en el número de ioctl, el `case VIDDEC_INIT` compilado del kernel no matchea el cmd de fábrica → el case nunca dispara → `KSHM_WRITE_HDL_ACCESS` no se envía al AVP → sin handle kshm no hay buffers de frames → **el decoder H264 del AVP corre (virtuart: `VER:H264`, `allocsz=0x321b000`, `vdec sync stc`) pero no se muestra imagen**.

Predicción concreta: fábrica envía `VIDDEC_INIT=0x82980400` (sizeof 664); el SDK compila `0x82840400` (sizeof 644); delta = 20 bytes. Con `_pad_abi_2025[20]` al final del struct, el kernel compila `0x82980400`, matchea, y el video muestra imagen.

# Evidence

- **Método (validado):** reconstrucción de constantes ioctl 32-bit a partir de pares codificados `lui $r,0xNNNN` (word `0x3C??NNNN`) + `ori/addiu $r,$r,0xXXXX` en ≤8 words, sobre los binarios MIPS de fábrica. Validación: extrae de `driver_r36sx.so`/`driver.so`/`libffplayer.so`/`libhudi.so` exactamente `AUDDEC_INIT=0x82780301` (sz 632) — el MISMO cmd observado on-device en el boottrace 9l (`amprpc: IOCTL cmd=0x82780301 -> ret=0`, evidencia `docs/experiments/evidence-9l-boottrace.log`).
- **Hallazgo ABI video:** `libffplayer.so` y `libhudi.so` (ambas en `/mnt/g/rootfs/usr/lib/`) contienen la construcción `lui v0,0x8298` + `ori v0,v0,0x400` → **`VIDDEC_INIT=0x82980400` (sz 664)**. Son los ÚNICOS dos ioctls con struct grande del path de media en esas libs (no hay drift en VIDSINK/DIS: los ioctls `/dev/dis` de fábrica ya retornaban `ret=0` en la traza 9l: `0xC00C0E0C`, `0x800C0E04`, `0x80140E09`).
- **Lado SDK:** probe mips32r2 (mips-mti-linux-gnu-gcc, mismo include path del build) → `sizeof(struct video_config)=644` → `VIDDEC_INIT=0x82840400`. `sizeof(struct audio_config)=632` (post-fix 9l) → `AUDDEC_INIT=0x82780301` ✓.
- **Mecanismo del proxy (rutas citadas):** `drivers/hcdrivers/avp-proxy/avp-proxy.c` — primer switch: `case AUDDEC_INIT:` (l.334) / `case VIDDEC_INIT:` (l.345) (fixups extradata); segundo switch: `case AUDDEC_INIT: case VIDDEC_INIT:` (l.368-371) → `avp_ioctl(fpriv->avp_fd, KSHM_WRITE_HDL_ACCESS, ...)` — **exactamente el mensaje que "nunca se envía" cuando el case no matchea** (comentario del fix 9l en auddec.h). El default del switch NO bloquea la RPC (por eso el AVP responde y hasta decodifica), solo se pierde el handle kshm.
- **9l (audio, antecedente):** fix `_pad_abi_2025[24]` en `include/uapi/hcuapi/auddec.h` → AUDIO PHYSICAL PASS (ver CHANGELOG 2026-09-18 y evidence-9l-*).

# Files changed

- `build/linux-4.4.186/include/uapi/hcuapi/vidmp.h` — `struct video_config` + `uint8_t _pad_abi_2025[20];` al final (sizeof 644→664). [capturado como `patches/kernel/0002-vidmp-abi-2025-padding-20B-fase9m.patch`]
- `patches/kernel/0001..0004` — captura en el repo de TODO el delta kernel-side vs SDK pristino (auddec.h 24 B 9l, vidmp.h 20 B 9m, amprpc.c debug 9f-9j, avp-proxy.c snd_xfer debug 9g) — hasta ahora vivía solo en el build tree.
- `docs/experiments/evidence-9l-*.log|txt` — evidencia del boot 9l traída de la SD.
- Docs: CHANGELOG (9i-9l + 9m), DECISIONS (ADR-012), CURRENT, ROADMAP, README.

# Commands (exactas)

```bash
# scan ABI fábrica (validado contra boottrace)
python3 scan_lui_ori.py   # sobre /mnt/g/rootfs/usr/lib/libffplayer.so libhudi.so (see logs)
# probe sizeof SDK
mips-mti-linux-gnu-gcc -mips32r2 -EL -static -I$BLD/include/uapi -I$BLD/arch/mips/include -o /tmp/szp /tmp/szp.c && qemu-mipsel-static /tmp/szp
# build + stage + deploy
./scripts/build_kernel.sh r36sx-v26
cp $W/build/r36sx-v26/images/vmlinux.uImage /mnt/d/R36SX/staging/vmlinux.uImage-r36sx-v26-fase9m
cp /mnt/d/R36SX/staging/vmlinux.uImage-r36sx-v26-fase9m /mnt/g/cubegm/vmlinux.uImage && sync   # autorizado por usuario
sha256sum ... # read-back == staging
```

# Build result

**BUILD PASS** — uImage **`1b095ac8`** 7,127,573 B (Load 0x80000000 / Entry 0x803db8a0, gzip). `bootloader.bin not found` al final = esperado (ADR-008). Provenance gates TOOLCHAIN/PATCH/DTB PASS (scripts/audit_*).

# Tests

- STATIC: probe sizeof post-fix → `video_config=664`, `VIDDEC_INIT=0x82980400` (**STATIC PASS**).
- STATIC: objdump avp-proxy.o → `lui v0,0x8298` compilado junto a `lui v0,0x8278` (audio) (**STATIC PASS**).
- DEPLOY: SD read-back sha256 == staging `1b095ac8…` (**DOWNLOAD-BACK PASS**; goldens intactos).
- **PHYSICAL: PENDIENTE** — boot consola + reproducir video → ¿imagen visible? (+ regresión audio/juegos).

# Result

Fix desplegado y verificado en SD. **Test físico pendiente** (requiere hardware en manos del usuario).

# Interpretation

Si aparece imagen: ADR-012 queda doblemente validado (audio + video) y la familia AVP-media se cierra — la "limitación conocida" de Fase 6/7 era íntegramente este drift ABI. Si NO aparece imagen: buscar (a) otro ioctl con drift no cubierto (repetir scan sobre otras libs del path: libglist/libavcodec), (b) fields en medio (no al final) del struct de fábrica — se detectaría por valores corruptos de campos clave en el AVP, (c) descriptor/GE de la capa de video (pero los ioctls dis ya funcionaban).

# Decision

ADR-012 (ACTIVE): política de padding ABI contra fábrica, tamaño SIEMPRE de evidencia (scan lui+ori y/o amprpc debug on-device), nunca por adivinanza.

# Artifact hashes

- uImage 9m: `1b095ac87b3d3e90ea30daf66bba7a76a794fbdb35bf07fecd50da79b175dcde` (7,127,573 B; staging `vmlinux.uImage-r36sx-v26-fase9m`; SD `cubegm/vmlinux.uImage`)
- uImage 9l (audio PASS, anterior): `f1e8e3eb…` (7,127,844 B; staging fase9l)
- kernel.config: `daee22e7…` (sin cambios 8f→9m) · dtb.bin: `04fb8383…` · rootfs-own.cpio: `e305dfc2…`
- SD goldens: stock `53b3e0b3…` · avp `a9788995…` (intocados)

# Next action

**Usuario: test físico del 9m** — boot + reproducir un VIDEO (TreeFrogUI media player). La evidencia se autocaptura (S09trace → boottrace/virtuart/treefrog_ui.log; zhijack → log.txt). Con PASS → cerrar Fase 8 (ROADMAP) y commit final; con FAIL → iteración 9n con el scan extendido.
