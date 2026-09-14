# docs/BUILD.md — Cómo compilar

**Estado:** VALIDADO (Fase 2 BUILD PASS 2026-09-14). Contrato: `docs/ai/BUILD_CONTRACT.md`.

## Prerequisitos (host)

- WSL2 Ubuntu 24.04 (ADR-001). Espacio: ~10 GB build + SDK extraído 3.9 GB.
- Paquetes (instalados 2026-09-14 vía apt, sin tocar sources.list — **desviación del setup vendor** que NO ejecutamos porque rompe Ubuntu 24.04):
  `gperf swig genromfs libtool texinfo mtd-utils autoconf-archive` (+ ya presentes: git gcc flex bison make python3 unzip dos2unix ninja-build pkg-config cmake automake lzop libncurses-dev libssl-dev tree unrar lzma bc rsync perl cpio)
- SDK verificado: `./scripts/verify_sources.sh` PASS → `./scripts/prepare_sdk.sh`.

## Desviaciones documentadas vs setup vendor (setup_tools.sh)

| Punto | Vendor (Ubuntu 18.04) | Nosotros (24.04) | Razón |
|---|---|---|---|
| sources.list | Reemplaza por mirror huaweicloud | **INTACTO** | rompería 24.04 |
| Paquetes | ~40 ciegas | 7 mínimas reales | ADR-002 minimal host |
| `sudo pip3 install fdt` | global | pendiente solo si un script lo pide | pylibfdt opcional (build lo salta) |
| rar | apt | unrar ya presente | solo extracción necesaria |

## Variables de entorno OBLIGATORIAS del build

```bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"  # PATH sanitizado: WSL hereda rutas Windows con espacios → Buildroot aborta
export BR2_DL_DIR="$HOME/work/r36sx-hclinux/cache/dl"                       # cache dl (symlinks a ~/KERNEL_BUILD/hclinux/buildroot/dl — 1.3G reutilizados)
export HOST_EXTRACFLAGS="-fcommon"                                          # GCC 13 host vs dtc kernel 4.4 (yylloc) — SOLO host tools
```

## Build baseline kernel-only d3100_v20 (validado)

```bash
cd ~/work/r36sx-hclinux/sdk/hclinux-2024.02.y.2/hclinux/buildroot
O=$HOME/work/r36sx-hclinux/build/d3100-v20-baseline
make O=$O BR2_EXTERNAL=$PWD/.. hichip_hc16xx_db_d3100_v20_defconfig
# desviaciones mínimas (bug kconfig vendor + bare-metal ausente, ADR-007/008):
sed -i 's/^BR2_PACKAGE_HCCAST=y/# BR2_PACKAGE_HCCAST is not set/; s/^BR2_PACKAGE_HCCAST_NET=y/# BR2_PACKAGE_HCCAST_NET is not set/; s/^BR2_PACKAGE_HCCAST_WIRELESS=y/# BR2_PACKAGE_HCCAST_WIRELESS is not set/; s/^BR2_PACKAGE_HCCAST_AIRCAST=y/# BR2_PACKAGE_HCCAST_AIRCAST is not set/; s/^BR2_PACKAGE_HCCAST_MIRACAST=y/# BR2_PACKAGE_HCCAST_MIRACAST is not set/; s/^BR2_PACKAGE_HCCAST_DLNA=y/# BR2_PACKAGE_HCCAST_DLNA is not set/; s/^BR2_TARGET_HCBOOT=y/# BR2_TARGET_HCBOOT is not set/; s/^BR2_PACKAGE_AVP=y/# BR2_PACKAGE_AVP is not set/' $O/.config
make O=$O -j16
# ESPERADO al final: "bootloader.bin not found" en target-post-image (hcboot off, ADR-008) — kernel completo antes
```

Errores conocidos y clasificación (detalle en `docs/experiments/2026-09-14_vendor-baseline-d3100-v20.md`): kconfig libcast (bug vendor), GCC13 dtc (-fcommon), bare-metal ausente (privado), post-image bootloader.bin (esperado).

## Artefactos esperados

`images/`: vmlinux, vmlinux.bin, vmlinux.bin.gz, **vmlinux.uImage** (gzip, Load 0x80000000, Entry 0x803e3200), **dtb.bin** + `<board>.dtb`, rootfs.squashfs, hcprog.ini, romfs.img, persistentmem.bin, download-vmlinux.ini, for-{factory,upgrade,upgrade-withboot,debug}/ (vacíos sin hcboot).
Persistidos: `~/work/r36sx-hclinux/artifacts/` + copia Windows `D:\R36SX\hclinux-builds\<fecha>\`.

## Toolchains

| Target | Toolchain | Origen | Estado |
|---|---|---|---|
| Kernel/rootfs Linux | Codescape `mips-mti-linux-gnu` gcc 6.3.0 (2018.09-02) | descargada por Buildroot desde dl/ cache (tarball CentOS-6 en cache del usuario) | **VALIDADA**: mismo toolchain que la fábrica HiChip (vermagic stock) |
| AVP/hcboot bare-metal | `mips32-mti-elf` (2019.09-03-2) | GitLab HiChip privado (login) | **NO DISPONIBLE** — ADR-008; `/opt/mips32-mti-elf` local es symlink roto |

## Próximos builds (Fase 4-5)

Board propia `r36sx-v26`: defconfig propio en `configs/buildroot/` + DTS en `boards/r36sx-v26/dts/` derivado del DTB stock (E3100v20, memoria 176MiB, console=tty1, fb 0x18808000...). Script `scripts/build_kernel.sh` se completará entonces.
