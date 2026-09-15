# docs/SDK_AUDIT.md — Auditoría del SDK HCLinux 2024.02.y.2

**Estado:** FASE 1 COMPLETADA (Iteración 2, 2026-09-14) — **STATIC PASS** (sin compilar; toda afirmación con ruta de evidencia).
**Fuente:** `/mnt/d/GitHub/KERNEL/hclinux-2024.02.y.2.tar.gz` (SHA256 `e3211b41...45fbf8d5d`, 2,116,519,773 bytes), extraído a `~/work/r36sx-hclinux/sdk/` (3.9 GiB, 60,755 entradas).
**Ruta base de evidencia:** `~/work/r36sx-hclinux/sdk/hclinux-2024.02.y.2/hclinux/` (=`$H` abajo).

## Resumen ejecutivo

El SDK es el árbol Buildroot externo (`BR2_EXTERNAL`, `external.desc` → `name: HCLINUX`) privado de HiChip: **Buildroot 2021.05-rc2** + 41+ defconfigs de board + patches kernel + `SOURCE/linux-drivers` (BSP overlay) + `SOURCE/avp` (HCRTOS/AVP) + `boot/hcboot` + toolchains externas + ~37 submodules GitLab. Es un **SDK COMPLETO** capaz de generar el firmware completo (hcboot+AVP+kernel+rootfs+empaquetado). El único elemento mayor **no incluido** es el árbol Linux vanilla (se descarga de kernel.org).

## Hipótesis H1–H11 (requisito §15) — VEREDICTOS

| # | Hipótesis | Status | Evidence |
|---|---|---|---|
| H1 | Arquitectura HC16xx/MIPS (MIPS32r2, 74Kc, little-endian) | **CONFIRMED** | `$H/configs/hichip_hc16xx_db_d3100_v10_defconfig` (`BR2_TOOLCHAIN_EXTERNAL_PREFIX="mips-mti-linux-gnu"`); `SOURCE/linux-drivers/arch/mips/hc16xx/` (9 archivos: board.c, irq.c, time.c, serial.c, prom.c...); patch `0001-add-hichip-hc16xx-arch-support.patch` |
| H2 | Buildroot como sistema de build | **CONFIRMED** | `$H/buildroot/Makefile` → `BR2_VERSION := 2021.05-rc2`; estructura BR2_EXTERNAL completa (`external.desc`, `external.mk`, `Config.in`, `local.mk`) |
| H3 | Linux en core-main, HCRTOS/AVP en segundo núcleo | **CONFIRMED** | Manual §6.1 (diagrama dual-CPU Linux@Core-main / RTOS@Core-AVP); `SOURCE/avp` = HCRTOS (basado en FreeRTOS, repo submodule `hcrtos.git`); defconfig: `BR2_PACKAGE_AVP=y` |
| H4 | AMPRPC puente Linux↔AVP | **CONFIRMED** | `SOURCE/linux-drivers/drivers/hcdrivers/amprpc/` (amprpc.c 19.6KB, smbox/mmbox reg headers); `hcdrivers/avp-proxy/avp-proxy.c`; DTS stock R36SX: nodos `amprpc`+`avp-proxy`×18 (report 10 del usuario); API avp_open/ioctl/poll documentada en manual |
| H5 | BSP en SOURCE/linux-drivers | **CONFIRMED** | `$H/linux/linux-ext-patch-hichip-driver.mk` — hook `LINUX_PATCH_HICHIP_DRIVERS` rsync-iza `SOURCE/linux-drivers/` sobre el árbol kernel ANTES de patches (PRE_PATCH_HOOKS) y también PRE_BUILD; crea `arch/mips/hc16xx`, `drivers/hcdrivers/**` (33 componentes), staging de `include/uapi/hcuapi` |
| H6 | Kernel 4.4.186 = baseline principal | **CONFIRMED** | 41 defconfigs fijan `BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE="4.4.186"`; manual tabla soporte: "4.4.186 soportado (usb/sdio con problemas de compilación en 5.12.4)"; `patches/linux-4.4.186/` = 45 patches + yaffs2 |
| H7 | Soporte/experimentos 5.12.4 presentes | **CONFIRMED** | `patches/linux-5.12.4/` (21 patches), `board/hichip/hc16xx/common/kernel-configs/5.12.4/`; PERO manual: NO es default y USB/SDIO con problemas → 5.12.4 = línea secundaria/experimental (ADR-004) |
| H8 | DTS externo al kernel | **CONFIRMED** | defconfig: `BR2_LINUX_KERNEL_CUSTOM_DTS_PATH` apunta a `$H/board/hichip/hc16xx/{common,projector,...}/dts/*.dts` (+ `hc16xx-common.dtsi` + `*-avp.dtsi`); DTSI AVP separado (`hc16xx-db-d3100-v10-avp.dtsi`); además `SOURCE/avp` tiene su propio árbol dts |
| H9 | U-Boot/hcboot bootloader | **CONFIRMED** | `$H/boot/hcboot/hcboot.mk` (paquete Buildroot que compila apps-bootloader desde SOURCE/avp); manual: bootloader.bin = DDR-init block + u-boot.bin (post-build.sh:216 `cat ddrinit u-boot.bin > bootloader.bin`); nota: U-Boot no usa DTS para su adaptación (manual §DTS) |
| H10 | Generación vmlinux.uImage | **CONFIRMED** | `$H/board/hichip/hc16xx/common/post-build.sh`:89-245 — extrae entry/load de vmlinux con readelf/nm, `mkimage -A mips -O linux -C gzip/lzma/lzo ... vmlinux.uImage`; AVP → `mkimage -T standalone ... avp.uImage`; genera hcprogrammer.ini/download-*.ini |
| H11 | Memoria compartida Linux/AVP/MMZ | **CONFIRMED** | `board/.../dts/hc16xx-db-d3100-v10.dts`:13-16 — `memory { reg = <CONFIG_LINUX_MEMORY_OFFSET CONFIG_LINUX_MEMORY_SIZE> }`; macros en `-avp.dtsi`: `CONFIG_MEMORY_SIZE 0x10000000` (256MiB), `HCRTOS_SYSMEM_SIZE = 0x200000 - MMZ1`, `HCRTOS_MMZ0/1_SIZE/OFFSET`; `linux-ext-fixup-load-addr.mk` calcula `CONFIG_PHYSICAL_START` desde DTS (linux@0x0..., avp@0x8BDA4000 en segmento kseg1) |

## Estructura del SDK (evidencia)

### Top-level (verificada físicamente)

```
hclinux-2024.02.y.2/hclinux/   ← raíz BR2_EXTERNAL (git vendor, branch hclinux-2024.02.y.2, commit 8a08de5, remote gitlab.hichiptech.com)
├── SOURCE/        (31 módulos: avp=HCRTOS, linux-drivers=BSP, ffmpeg, liblvgl, wpa_supplicant, rtl*/aic8800d wifi, hccast, hcfota, prebuilts...)
├── board/hichip/hc16xx/  (common/ + projector/ + fastboot/ + c6/ + c3100_emmc/ + a3300_spinand/ + d3100_p1/ + a3100_sdcard/ + hdmi_display/)
├── boot/hcboot/   (hcboot.mk + Config.in)
├── buildroot/     (Buildroot 2021.05-rc2, submodule)
├── configs/       (41+ defconfigs de board)
├── document/      (16 PDFs vendor chinos: ADC, PWM, GPIO, UART, flash, net upgrade, projector app...)
├── linux/         (linux-ext-*.mk — hooks BSP del kernel)
├── package/       (43 paquetes: avp, ddrinit, applications/, display, hcdaemon, hcfota, mtp...)
├── patches/       (busybox, exfat, ffmpeg, libusb, linux-4.4.186, linux-5.12.4)
├── support/       (scripts/envsetup.sh + tools/ [HCProgram, HCBootLogo, dtc, fdt, mkimage...])
├── toolchain/     (toolchain-external-codescape-mti-mips)
├── external.desc/external.mk/Config.in/local.mk/hcbuild.env/hrepo
```

### Board common (`board/hichip/hc16xx/common/`)

`avp-configs/` (hichip_hc16xx_linux_avp_defconfig etc.) · `busybox-configs/` · `ddrinit/` (~20 variantes .abs: DDR2/DDR3 128M 400–1066MHz) · `dts/` (+ lcd/*.dtsi) · `hcboot-configs/` (6 bl_defconfigs) · `kernel-configs/{4.4.186,5.12.4,custom}/` · `rootfs_overlay/` (5 variantes) · `post-build.sh` (empaquetado firmware completo) · `post-image-jffs2.sh` · `gen_upgrade_pkt.sh` · `logo.m2v`

### Boot chain (evidencia cross-checkeada)

```
BootROM HC16xx → lee DDR-init de NOR (hc16xx_ddr3_128M_1066MHz.abs, 12,288 B) → inicializa DDR
→ carga u-boot (bootloader.bin = DDR-init + u-boot.bin, post-build.sh:216)
→ u-boot inicia AVP (avp.uImage, mkimage -T standalone, Load=Entry=0x8BDA4000) ANTES de Linux
→ u-boot guarda dirección DTB para AVP: REG32_WRITE(0xb8800004, dtb) [apps-bootloader/source/main.c:620]
→ u-boot bootm Linux (vmlinux.uImage, DTB load 0x85ff0000 — post-build.sh AutoRun0="wm 0xb8800004 0x85ff0000")
→ Linux 4.4.186 core-main + AVP HCRTOS core-AVP ↔ AMPRPC (amprpc + avp-proxy + kshm)
```

### Pipeline de kernel (evidencia `$H/linux/linux-ext-*.mk` + verificación 01 del usuario)

1. Buildroot descarga **Linux vanilla 4.4.186** de kernel.org (`BR2_LINUX_KERNEL_CUSTOM_VERSION`).
2. `LINUX_PREPARE_PATCHES_FOR_VERSION` (post-extract): `ln -sf linux-4.4.186 patches/linux`.
3. **rsync `SOURCE/linux-drivers/` sobre el árbol kernel** (`LINUX_PATCH_HICHIP_DRIVERS`, PRE_PATCH_HOOKS) → crea arch/mips/hc16xx, drivers/clk/hc16xx, timer-hc16xx.c, drivers/hcdrivers/**.
4. Buildroot aplica `patches/linux-4.4.186/*.patch` (45, en orden) + yaffs2 (`patch-ker.sh c m`).
5. `LINUX_PHYSICAL_START_FROM_DTS` (PRE_BUILD): preprocesa el DTS con gcc, extrae `linux_load_addr` y `avp_load_addr`, parchea `CONFIG_PHYSICAL_START` + `spaces.h` + `kernel-entry-init.h`.
6. Compila con toolchain **Linux** externa: Codescape `mips-mti-linux-gnu` gcc 6.3.0 (2018.09-02).
7. post-build.sh: readelf/nm → entry/load → `mkimage` → **vmlinux.uImage** + dtb.bin + AVP standalone uImage + hcprogrammer.ini + upgrade pkt.

### Toolchains (evidencia)

| Target | Toolchain | Estado |
|---|---|---|
| Linux kernel + rootfs | Codescape GNU `mips-mti-linux-gnu` gcc 6.3.0 (2018.09-02) | En SDK: `toolchain/toolchain-external-codescape-mti-mips/` (Buildroot la descarga de GitLab Dl o mirror) |
| AVP/hcboot (bare-metal) | `mips32-mti-elf` Codescape 2019.09-03-2 (Bare.Metal.Ubuntu-18.04.5) | **NO incluida en el tar** — repo GitLab `Dl` (manual §2.2.3); requerida para compilar AVP/hcboot propios |

### Comparación de fuentes por hash (evidencia: diff sha256 SDK vs /mnt/d)

- `patches/linux-4.4.186/` SDK vs `D:\GitHub\KERNEL\linux-4.4.186\` → **IDÉNTICOS** (41/41).
- `patches/linux-5.12.4/` SDK vs `D:\GitHub\KERNEL\linux-5.12.4\` → **IDÉNTICOS** (21/21).
- `hcdrivers/7z` vs `hcdrivers/` extraído → pendiente de diff fino (report 05 del usuario: MATCH).
- `SOURCE/linux-drivers/drivers/hcdrivers/` SDK vs `hcdrivers/` de /mnt/d → mismo contenido (rsync fuente).

### Invocación vendor exacta (manual §16.1 — evidencia)

```bash
cd hclinux
source support/scripts/setup/setup_tools.sh   # (sudo apt install ...; requiere interacción)
source support/scripts/envsetup.sh
cd buildroot
make O=output/d3100 BR2_EXTERNAL=$PWD/../ hichip_hc16xx_db_d3100_v20_defconfig
make O=output/d3100 all
# helpers: mkhclinux / mkboot / mkkernel / mkavp / mkall
# menuconfigs: menuconfig / linux-menuconfig / avp-menuconfig / hcboot-menuconfig / busybox-menuconfig
```

**Requisitos host:** Ubuntu 18.04.5+ (usamos 24.04 — validar), inglés locale, >100 GB disco (~20 GB/build), >4 GB RAM. Toolchain bare-metal AVP extraer en `/opt` desde `buildroot/dl/Codescape...Bare.Metal...tar.gz`.

## Cross-checks manual↔SDK (addendum 2026-09-14)

| Claim del manual/guía | Veredicto | Evidence |
|---|---|---|
| DTB load `0x85ff0000` | **CONFIRMED** | `$H/board/.../common/post-build.sh:125,147,169` (`AutoRun0=wm 0xb8800004 0x85ff0000`) |
| AVP recibe DTB via reg `0xb8800004` | **CONFIRMED** | `SOURCE/avp/components/applications/apps-bootloader/source/main.c:620` (`REG32_WRITE(0xb8800004,(uint32_t)dtb)`); `SOURCE/avp/components/kernel/source/dts/Kconfig:19-20` |
| bootloader.bin = DDR-init + u-boot.bin | **CONFIRMED** | post-build.sh:176-216 (`cat ${fddrinit} ${BOOTBIN} > bootloader.bin`) |
| DDR-init block = 4 KiB | **PARTIAL** | Archivo real `.abs` = 12,288 B (12 KiB) — el manual describe un esquema concreto; usar tamaño físico por board |
| AVP = uImage standalone iniciado antes de Linux | **CONFIRMED** | post-build.sh:239-245 (`mkimage -T standalone -n avp -a ${avp_load} ... avp.uImage`) |
| 4.4.186 soportado/default; 5.12.4 con problemas USB/SDIO | **CONFIRMED** | 41 defconfigs =4.4.186; manual L746: "usb/sdio驱动在5.12.4上仍存在编译问题" |
| Toolchain bare-metal AVP: Codescape 2019.09-03-2 | **CONFIRMED** | manual §2.2.3 + `.gitmodules` (no incluida en tar; repo Dl) |
| U-Boot no usa DTS para sí mismo | **CONFIRMED** | manual §DTS (nota: adaptación de hardware hcboot requiere código) |

## Correspondencia R36SX V2.6 (evidencia física del usuario, reports en /mnt/d/GitHub/KERNEL/work/)

> Fuente: `work/reports/10_R36SX_MATCHING.md` (evidencia de dispositivo real, DTB stock decompilado). Esta sección registra datos FÍSICOS verificados por el usuario — base para Fases 3–4.

| Claim | Status | Evidence |
|---|---|---|
| SoC R36SX V2.6 = HC1600A (familia HC16xx), CPU MIPS 74Kc | **CONFIRMED** (físico) | DTB stock: `compatible="Hichip,1600"`, CPU "MIPS 74Kc" |
| Board label stock = `hc1600a@dbD3100v20` | **CONFIRMED** (físico) | DTS stock decompilado → familia **D3100 v20** |
| Kernel stock = 4.4.186, vermagic gcc 6.3.0 Codescape | **CONFIRMED** (físico) | vermagic `4.4.186-release`, toolchain `mips-mti-linux-gnu` |
| DTS stock R36SX ≈ familia D3100 (matching HIGH en todos los nodos) | **CONFIRMED** (físico) | report 10: fb/musb/amprpc/avp-proxy/kshm/mmz/lvds/dw-mshc/key-adc/persistentmem... todos idénticos |
| vmlinux.uImage stock: Load 0x80000000 Entry 0x803EC710; avp.uImage: 0x8BDA4000 | **CONFIRMED** (físico) | dumps uImage del usuario (solo lectura) |
| Board SDK más cercana | **d3100_v20** (HIGH) | familia D3100 + label stock dbD3100v20; **peros**: DDR/panel/pinmux/particiones finos NO asumibles — requieren DTB stock (Fase 3/4) |

## Faltantes identificados (para Fase 2+)

1. **Árbol Linux vanilla 4.4.186** — descarga de kernel.org (el usuario ya tiene cache en `/mnt/d/Toolchains/R36SX/kernel-linux-4.4.186/cache/linux-4.4.186.tar.xz` — report 00; **pendiente re-verificar hash con kernel.org**).
2. **Toolchain bare-metal `mips32-mti-elf` 2019.09-03-2** — no en el tar; requerida para compilar AVP/hcboot propios (Fase 4+); preservar AVP stock mientras tanto (ADR-005).
3. **`dl/` de Buildroot** — no incluido en el tar (descarga de terceros on-line al primer build; repo GitLab `Dl` como mirror offline).
4. **.config kernel exacto de consola stock** — no existe en SDK; base = `kernel-configs/4.4.186/kernel-squashfs.config` + DTB stock (Fase 3).

## Claims PENDIENTES / fuera de alcance de esta auditoría

- Validación física de cualquier build (PHYSICAL PASS) — Fase 5+.
- Layout de particiones flash de la consola stock — Fase 3 (requiere dumps o SD stock).
- `/dev/dis`, ioctl vendor, deps exactas de TreeFrogUI — Fase 6.

## Addendum Fase 2 (2026-09-14) — validación física contra SD stock (G:)

| Claim | Veredicto | Evidence |
|---|---|---|
| Toolchain del firmware stock = Codescape 2018.09-02 gcc 6.3.0 (igual que SDK) | **CONFIRMED (físico, evidencia complementaria)** | cadena de compilador embebida en vermagic stock (`linsen.chen@hichip01 ... Codescape 2018.09-02`) == cadena embebida en nuestro vmlinux. NOTA: `user@host` del vermagic describe el entorno de build original, NO prueba toolchain (AGENTS.md §14); la prueba primaria de NUESTRO build: docs/TOOLCHAIN_PROVENANCE.md (.cmd files) |
| Board stock = D3100 v20 (reporte previo del usuario) | **DISPROVED — es `hc1600a@dbE3100v20` (E3100)** | DTB stock decompilado nodo board (SD `/mnt/g/cubegm/dtb.bin`, sha `1258f1eb...`) |
| Board E3100 existe en el SDK | **DISPROVED (no existe)** | `grep -ri e3100` en SDK = 0 → board propia obligatoria (Fase 4) |
| Memoria Linux stock = 254 MiB (como SDK d3100_v20) | **DISPROVED — stock: Linux `0xAF91E50` = 175.57 MiB de 256 total (AVP 80.43); SDK v20 real: total 128 MiB, Linux 79.20** (valores exactos y correcciones en docs/DTS_STOCK_MODEL.md — Fase 4A) | DTB stock memory node + memory-mapping |
| Bootargs stock usan serial ttyS0 | **DISPROVED — `console=tty1`, serial OFF de fábrica** | DTB stock chosen |
| fb stock = DE4K 0x1883a000 static (como SDK v20) | **DISPROVED — 0x18808000, buffer system +12MiB extra, 1280x720** | DTB stock fb0 |
| Reproducibilidad DTB del pipeline | **CONFIRMED** | `dtb.bin` build nuevo == baseline previo usuario (sha `254522d5...` byte-idéntico) |

Detalle completo: `docs/experiments/2026-09-14_vendor-baseline-d3100-v20.md` + `docs/HARDWARE_R36SX_V26.md`.
