# Experimento: 2026-09-14 — Vendor baseline kernel-only d3100_v20

# Objective

Reproducir el build vendor del SDK HCLinux 2024.02.y.2 sin modificaciones propias (Fase 2), obteniendo baseline reproducible del pipeline completo: kernel 4.4.186 + DTB + uImage + rootfs squashfs.

# Hypothesis

El pipeline vendor (Buildroot 2021.05-rc2 + defconfig `hichip_hc16xx_db_d3100_v20_defconfig` + toolchain Codescape 2018.09-02) compila en WSL Ubuntu 24.04 con desviaciones host mínimas documentadas, produciendo artefactos equivalentes a los del firmware stock (mismo toolchain, mismas direcciones).

# Evidence

- SDK: `/mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz` sha256 `e3211b41...45fbf8d5d` (verify_sources PASS)
- Defconfig: `hclinux-2024.02.y.2/hclinux/configs/hichip_hc16xx_db_d3100_v20_defconfig` (elección por evidencia: manual §16.1 L639/2460 lo usa como ejemplo; diff vs `_p1` documenta variante con partición datos — no aplica)
- Baseline previo del usuario como referencia: `D:\GitHub\KERNEL\work\build\d3100-baseline\FINAL_BASELINE_REPORT.md`
- Validación física: SD G: (`/mnt/g/cubegm/`) read-only — ver §Tests

# Files changed

Ninguno del SDK (inmutable). Output propio: `~/work/r36sx-hclinux/build/d3100-v20-baseline/`. Artefactos: `~/work/r36sx-hclinux/artifacts/d3100-v20-baseline-kernelonly/` + copia D: `D:\R36SX\hclinux-builds\d3100-v20-baseline-kernelonly-20260914\`.

# Commands

```bash
# entorno
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"   # PATH sanitizado (WSL hereda rutas Windows con espacios)
export BR2_DL_DIR="$HOME/work/r36sx-hclinux/cache/dl"                          # cache dl reutilizada (symlinks a ~/KERNEL_BUILD/hclinux/buildroot/dl, 1.3G)
export HOST_EXTRACFLAGS="-fcommon"                                            # GCC13 vs dtc kernel 4.4

# build
cd ~/work/r36sx-hclinux/sdk/hclinux-2024.02.y.2/hclinux/buildroot
make O=$HOME/work/r36sx-hclinux/build/d3100-v20-baseline BR2_EXTERNAL=$PWD/.. hichip_hc16xx_db_d3100_v20_defconfig
make O=$HOME/work/r36sx-hclinux/build/d3100-v20-b20-baseline -j16   # (3 intentos con fixes intermedios)
```

Desviaciones mínimas documentadas (ver #Interpretation):
1. `BR2_PACKAGE_HCCAST*` = off en .config del output (backup `.config.official-d3100v20.bak`) — bug kconfig vendor: `package/libcast/` sin Config.in
2. `BR2_TARGET_HCBOOT` + `BR2_PACKAGE_AVP` = off — toolchain bare-metal `mips32-mti-elf 2019.09-03-2` NO disponible (GitLab HiChip privado; `/opt/mips32-mti-elf` symlink roto). En el dispositivo el AVP/bootloader stock se preservan (ADR-005).

# Build result

**VENDOR BASELINE KERNEL-ONLY: BUILD PASS** (3 intentos, ~54 min total):

| Intento | Error | Clasificación | Fix mínimo |
|---|---|---|---|
| 1 | `libcast is in the dependency chain of hccast...` (Makefile:587, aborta parseo) | KCONFIG bug vendor | HCCAST* off en .config output |
| 2 | `multiple definition of 'yylloc'` (scripts/dtc, GCC 13 -fno-common) | HOST_COMPAT GCC13 | `HOST_EXTRACFLAGS=-fcommon` (solo host tools) |
| 3 | hcboot requiere `/opt/mips32-mti-elf/2019.09-03-2/bin/mips-mti-elf-gcc` | TOOLCHAIN_MISSING (privado) | HCBOOT/AVP off (kernel-only) |
| final | `target-post-image: bootloader.bin not found` (esperado: hcboot off) + `post-build.sh:184 unary operator` (warning benigno vendor) | POST_IMAGE esperado | N/A — artefactos kernel completos antes de este paso |

# Tests

- **dumpimage -l vmlinux.uImage**: MIPS Linux Kernel gzip, Load `0x80000000`, Entry `0x803e3200` — == baseline previo — PASS
- **readelf vmlinux**: ELF32, EXEC, MIPS R3000 (MIPS32r2), Entry `0x803e3200` — PASS
- **vermagic**: `Linux version 4.4.186-release (dafunknoise@DFNK) gcc 6.3.0 (Codescape 2018.09-02 for MIPS MTI Linux) #1 PREEMPT` — PASS
- **dtc round-trip dtb.bin**: OK (1702 líneas, 66 nodos clave presentes: avp-proxy/amprpc/mmz/fb/key-adc/uart/musb) — PASS
- **REPRODUCIBILIDAD DTB**: `dtb.bin` **byte-idéntico** al baseline previo del usuario (sha `254522d5...`) — PASS
- **vmlinux.bin**: mismo tamaño exacto que previo (5,804,684 B); sha difiere (vermagic embebe host/usuario/timestamp — no-reproducibilidad esperada y documentada)
- **SD física (G:, read-only)** — validación contra dispositivo real:
  - `vmlinux.uImage` SD = **KERNEL STOCK de fábrica**: vermagic `linsen.chen@hichip01`, gcc 6.3.0 **Codescape 2018.09-02** (== nuestro toolchain), #7 PREEMPT Dec 2025 → pipeline vendor confirmado idéntico al del fabricante
  - `dtb.bin` SD (sha `1258f1eb...`) = DTB stock golden; decompilado → evidencia board real (ver #Interpretation)
  - `avp.uImage` SD (sha `a9788995...`) = AVP stock preservado (Load=Entry `0x8bda4000`)

# Result

```
KERNEL:      BUILD PASS (4.4.186, MIPS32r2 LE, PREEMPT)
DTB:         BUILD PASS + dtc round-trip + byte-idéntico a baseline previo
UIMAGE:      BUILD PASS (gzip, 0x80000000/0x803e3200)
ROOTFS:      BUILD PASS (rootfs.squashfs 8.3M generado por el pipeline)
AVP:         N/A (preservado stock en dispositivo — ADR-005; toolchain bare-metal privado no disponible)
BOOTLOADER:  N/A (ídem)
PHYSICAL:    N/A — sin flashear (requiere autorización)
```

# Interpretation

1. **Pipeline vendor validado de extremo a extremo** (salvo hcboot/AVP): el SDK + nuestro entorno produce kernel con el MISMO toolchain que el ingeniero de HiChip usó en fábrica (evidencia vermagic stock). 
2. **Descubrimiento físico crítico (corrige reporte previo):** el DTB stock de la consola dice `board label = "hc1600a@dbE3100v20"` — **E3100, NO D3100**. El SDK NO contiene board E3100 (`grep E3100` = 0). La familia D3100 v20 es la base arquitectural más cercana, pero **la board R36SX V2.6 propia (Fase 4) es obligatoria**, derivada del DTB stock.
3. **Memory layout stock real:** DTB stock `memory reg = <0x00 0xaf91e50>` → **Linux = ~184 MB** de los 256 MB (AVP/MMZ se lleva ~72 MB). El DTS SDK d3100_v20 da 254 MB a Linux → **usar DTB SDK en la consola real pisaría memoria del AVP (riesgo brick/brick funcional)**. Este valor DEBE modelarse en la board propia.
4. Otras diferencias stock vs SDK d3100_v20: bootargs `console=tty1` (serial OFF de fábrica — el SDK usa `console=ttyS0`), fb0 @`0x18808000` buffer system + extra 12MB (SDK: `0x1883a000` DE4K buffer static), fb resolución stock 1280x720 horizontal, GPIO key `reg_bit` distinto (0x18800094 0x14/0x18 vs 0x12), 4 UARTs extra disabled, nodo `backlight` avp-proxy extra.
5. vmlinux.bin no es byte-reproducible (vermagic con host/usuario/fecha) — reproducibilidad estructural sí (DTB byte-idéntico, tamaño binario idéntico).

# Decision

- ADR-007: d3100_v20 = VENDOR BASELINE CANDIDATE (CONFIDENCE HIGH para pipeline; FINAL BOARD IDENTITY: NOT YET PROVEN — evidencia física apunta a E3100 v20).
- ADR-008: baseline kernel-only (HCBOOT/AVP off) mientras el bare-metal 2019.09-03-2 no esté disponible; el AVP stock se preserva en todo deploy (consistente ADR-005).
- Fase 2 CERRADA como BUILD PASS. Fase 3 (hardware) queda mayormente resuelta por evidencia física de la SD — pendiente consolidar en docs/HARDWARE_R36SX_V26.md (hecho en esta iteración).

# Artifact hashes (~/work/r36sx-hclinux/artifacts/d3100-v20-baseline-kernelonly/)

```
21d5cf501e9906ffaef18725e8bf7b35f5b4a083806560fc4f6beb0bb7008117  System.map
254522d546852107ce076b6ee3729f7f11a41cd8c4ce9c24cb4fe399c2438e7a  dtb.bin (== hc16xx-db-d3100-v20.dtb)
3e941a2777f6af2e14326b3c5a5c6b1efc9c5bb8f5cbfaa12b9be13662631289  kernel.config
366f90e058055099b5cc56f697e1a82ad33ea57c427373693daa4e89f60ed137  vmlinux (ELF, 66.7M)
ae47cd4857994e88352497a2ee9f583514b1540e7e8c954a3caf7a841efe54e4  vmlinux.bin (5,804,684 B)
c50d56f1153be032914caa88e0691ce73cf39982ee9e58522cd45b607f52d8bc  vmlinux.uImage (2,700,823 B)
```
Copia Windows: `D:\R36SX\hclinux-builds\d3100-v20-baseline-kernelonly-20260914\` (+ rootfs.squashfs, hcprog.ini, romfs.img, persistentmem.bin, SHA256SUMS-all.txt)

# Next action

Fase 4 (board propia `r36sx-v26`): partir del DTS stock decompilado (evidencia física) + estructura d3100_v20 del SDK, modelar: memory 184MB/console=tty1/fb0 system-buffer/GPIO keys/pinmux E3100 → `boards/r36sx-v26/dts/` + defconfig propio. Gate C: build kernel + DTB con DTS propio.
