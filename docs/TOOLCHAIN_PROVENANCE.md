# docs/TOOLCHAIN_PROVENANCE.md — Auditoría de cross-compilación (Fase 2.5)

**Estado:** COMPLETADA 2026-09-14 · **TOOLCHAIN PROVENANCE: PASS**
**Build auditado:** d3100_v20 kernel-only baseline (`~/work/r36sx-hclinux/build/d3100-v20-baseline/`).
**Regla (AGENTS.md §14):** "Presence of a toolchain does not prove it was used" — la prueba es la invocación registrada.

## A. Cross-compilation: ¿el kernel se compiló realmente de x86_64 a MIPS? — **SÍ, DEMOSTRADO**

### Host (§2.1 — salida real)

```
Linux DFNK 6.18.33.2-microsoft-standard-WSL2 ... x86_64 x86_64 x86_64 GNU/Linux
uname -m: x86_64 | dpkg arch: amd64 | Ubuntu 24.04.4 LTS
```

### Target (§2.2 — Buildroot .config efectivo del output)

`BR2_ARCH="mipsel"` · `BR2_ENDIAN="LITTLE"` · `BR2_mips_32r2=y` · `BR2_GCC_TARGET_ARCH="mips32r2"`, ABI 32, FP32, legacy NaN · `BR2_TOOLCHAIN_EXTERNAL_CODESCAPE_MTI_MIPS=y` · `BR2_TOOLCHAIN_EXTERNAL_PREFIX="mips-mti-linux-gnu"` · `BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE="4.4.186"`.

### Cross compiler REALMENTE invocado (§2.4 — .cmd files de kbuild; 1515 archivos .cmd existentes)

Muestras de 5 subsistemas distintos (literal de los archivos `.cmd`):

| Subsistema | Archivo .cmd | Comando registrado |
|---|---|---|
| init | `init/.main.o.cmd` | `cmd_init/main.o := .../host/bin/mips-mti-linux-gnu-gcc -Wp,-MD,... -isystem .../ext-toolchain/lib/gcc/mips-mti-linux-gnu/6.3.0/include -I./arch/mips/include ...` |
| mm | `mm/.memory.o.cmd` | `.../host/bin/mips-mti-linux-gnu-gcc` (+ isystem 6.3.0) |
| drivers/spi | `.spidev.o.cmd` `.spi.o.cmd` | `.../host/bin/mips-mti-linux-gnu-gcc` |
| drivers/of | `.address.o.cmd` | `.../host/bin/mips-mti-linux-gnu-gcc` |
| link | `drivers/spi/.built-in.o.cmd` | `.../host/bin/mips-mti-linux-gnu-ld -m elf32ltsmip -r ...` (linker MIPS `elf32ltsmip` = little-endian) |

**CROSS_COMPILE efectivo:** `mips-mti-linux-gnu-` (vía wrapper) · **ARCH:** `mips` (`UTS_MACHINE "mips"`).

### Cadena real del compilador (§2.3)

- `host/bin/mips-mti-linux-gnu-gcc` → symlink → `toolchain-wrapper` (sha256 `ee9dc1c7...`) → invoca `host/opt/ext-toolchain/bin/mips-mti-linux-gnu-gcc`
- Toolchain real: **Codescape GNU Tools 2018.09-02 for MIPS MTI Linux, gcc 6.3.0** (descargada por Buildroot desde tarball del dl/ cache — origen vendor `Codescape...CentOS-6.x86_64.tar.gz`)
- `-dumpmachine`: **`mips-mti-linux-gnu`** · `-print-sysroot`: `.../host/mipsel-buildroot-linux-gnu/sysroot/mipsel-r2-hard`
- Toolchains documentadas:
  - **Linux kernel/rootfs toolchain: mips-mti-linux-gnu gcc 6.3.0 (Codescape 2018.09-02) — IDENTIFICADA Y USADA (probada por .cmd)**
  - **AVP/hcboot bare-metal toolchain: mips32-mti-elf (2019.09-03-2) — NO DISPONIBLE** (GitLab HiChip privado; `/opt/mips32-mti-elf` symlink roto). Solo requerida por AVP/hcboot → **NO es bloqueo del kernel** (ADR-008).

## B. ELF resultantes (§2.5) — target MIPS confirmado

| Artefacto | file | Machine | Detalles |
|---|---|---|---|
| `vmlinux` (kernel) | ELF 32-bit LSB executable, **MIPS, MIPS32 rel2** | MIPS R3000 | Entry `0x803e3200`, Flags `0x70001001, noreorder, o32, mips32r2`, statically linked, BuildID `be7dbb4c...` |
| busybox 1.33.0 (userspace) | ELF 32-bit LSB executable, **MIPS MIPS32r2**, dynamically linked `/lib/ld.so.1` | MIPS R3000 | Hard float double, interpreter MIPS glibc; `.comment`: `GCC: (Codescape GNU Tools 2018.09-02 for MIPS MTI Linux) 6.3.0` |
| `8188fu.ko` (módulo rtl8188fu) | ELF 32-bit LSB **relocatable, MIPS MIPS32r2** | MIPS R3000 | BuildID `8efac9b6...` |

`readelf -A` kernel: `Tag_GNU_MIPS_ABI_FP: Soft float` (kernel sin FPU). `readelf -p .comment` vmlinux: **`GCC: (Codescape GNU Tools 2018.09-02 for MIPS MTI Linux) 6.3.0`** — el compilador quedó embebido en el binario.

**ROOTFS TARGET: MIPS CONFIRMED** (busybox + intérprete MIPS glibc).

## C. Información de compilador embebida (§2.6) — con corrección terminológica

```
include/generated/compile.h: UTS_MACHINE "mips"; LINUX_COMPILER "gcc version 6.3.0 (Codescape GNU Tools 2018.09-02 for MIPS MTI Linux)"
utsrelease.h: UTS_RELEASE "4.4.186-release"
```

**Corrección obligatoria (AGENTS.md §14):** en iteraciones previas este proyecto escribió "vermagic stock == nuestro toolchain" usando `linsen.chen@hichip01`. **`user@host` del vermagic NO demuestra identidad de toolchain** — solo describe el entorno de build original. La evidencia COMPLEMENTARIA correcta es: (a) el kernel stock de la SD embebe en su vermagic la MISMA CADENA de compilador `gcc version 6.3.0 (Codescape GNU Tools 2018.09-02 for MIPS MTI Linux)`; (b) nuestro kernel usa idéntica versión y cadena. Documentos corregidos en esta iteración (README/HARDWARE/SDK_AUDIT/experimento: "vermagic" restringido a su significado real).

## Veredicto

```
CROSS_COMPILE_REQUIRED:    CONFIRMED (mipsel target vs host x86_64)
CROSS_COMPILE_ACTUALLY_USED: PASS — 1515 .cmd files invocan mips-mti-linux-gnu-gcc; ld -m elf32ltsmip
LINUX TOOLCHAIN:          IDENTIFIED — Codescape 2018.09-02 gcc 6.3.0 (host/opt/ext-toolchain)
TARGET TRIPLET:           mips-mti-linux-gnu
SYSROOT:                  .../mipsel-buildroot-linux-gnu/sysroot/mipsel-r2-hard
TARGET ELF (KERNEL):      MIPS CONFIRMED (ELF32 LE MIPS32r2 EXEC)
TARGET ELF (BUSYBOX):     MIPS CONFIRMED (ELF32 LE MIPS32r2 hard-float)
TARGET ELF (MODULE .ko):  MIPS CONFIRMED (ELF32 LE relocatable)
AVP/HCBOOT TOOLCHAIN:     DOCUMENTED — NO DISPONIBLE (privada), no bloquea kernel (ADR-008)

TOOLCHAIN PROVENANCE: PASS
```
