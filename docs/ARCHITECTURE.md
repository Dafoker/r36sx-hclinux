# docs/ARCHITECTURE.md — Arquitectura del sistema (CONFIRMADA por evidencia)

**Estado:** Fase 1 COMPLETADA — este documento resume hallazgos con evidencia en `docs/SDK_AUDIT.md`.

## Cadena de boot (CONFIRMED)

```
BootROM HC16xx
  └─ lee DDR-init de NOR (hc16xx_ddr3_128M_1066MHz.abs, 12 KiB) → inicializa DDR
      └─ carga u-boot (bootloader.bin = DDR-init + u-boot.bin — post-build.sh:216)
          ├─ 1º inicia AVP: avp.uImage (mkimage -T standalone, Load=Entry=0x8BDA4000)
          │    └─ AVP obtiene su DTB vía REG32_WRITE(0xb8800004, dtb) [apps-bootloader main.c:620]
          └─ 2º bootm Linux: vmlinux.uImage (Load 0x80000000 stock) + DTB @ 0x85ff0000
               └─ Linux 4.4.186 @ core-main (MIPS 74Kc, MIPS32r2, LE)
                    └─ AMPRPC ↔ AVP/HCRTOS @ core-AVP (amprpc + avp-proxy + kshm + mmz)
```

## Partición de responsabilidades (CONFIRMED)

| Capa | Estado baseline | Evidencia |
|---|---|---|
| BootROM + DDR-init | Vendor, intocable | ddrinit/*.abs |
| u-boot/hcboot | Vendor (apps-bootloader desde SOURCE/avp, toolchain bare-metal) | boot/hcboot/hcboot.mk |
| AVP/HCRTOS (audio/video/display/HDMI) | Vendor, **preservado** (ADR-005) | SOURCE/avp (submodule hcrtos.git) |
| Kernel Linux 4.4.186 | **NUESTRO** (vanilla + rsync linux-drivers + 45 patches + fixup load-addr) | linux/linux-ext-*.mk |
| DTB | **NUESTRO** (board/.../dts, macros CONFIG_MEMORY/SYSMEM/MMZ) | defconfig BR2_LINUX_KERNEL_CUSTOM_DTS_PATH |
| Rootfs | Vendor squashfs (Fase 8 → propio) | kernel-configs/4.4.186/kernel-squashfs.config |
| TreeFrogUI/picoarch | Upstream + integración (Fase 6/8) | — |

## Drivers vendor clave (SOURCE/linux-drivers/drivers/hcdrivers/, 33 componentes)

amprpc, avp-proxy, kshm, kumsgq, mmz, fbdev (hcfb.c 40KB), ge, gpio(+key), i2c, lvds, musb (hcusb.c 39KB), nand (4.x/5.x), persistentmem(-fs), pinctrl, pwm, sdio, spi(-sf), watchdog, virtuart, rc, stk8baxx, clock, dumpstack, hwspinlock...

## Pipeline kernel (CONFIRMED — detalle en SDK_AUDIT.md)

```
Linux vanilla 4.4.186 (kernel.org)
  → rsync SOURCE/linux-drivers/ (PRE_PATCH_HOOKS)   [crea arch/mips/hc16xx, drivers/hcdrivers/**]
  → patches/linux-4.4.186/*.patch (45) + yaffs2
  → fixup CONFIG_PHYSICAL_START desde DTS (linux-ext-fixup-load-addr.mk)
  → cross-compile mips-mti-linux-gnu gcc 6.3.0 (Codescape 2018.09-02)
  → post-build.sh: mkimage → vmlinux.uImage + avp.uImage + bootloader.bin + firmware pkgs
```

## R36SX V2.6 (evidencia física, Fase 3 pendiente fino)

- SoC HC1600A, board label stock `hc1600a@dbD3100v20` → familia SDK **D3100 v20** (matching HIGH).
- Memoria total 256 MiB (CONFIG_MEMORY_SIZE 0x10000000 en d3100 v10; validar v20 stock).
- vmlinux.uImage stock: Load 0x80000000 / Entry 0x803EC710; avp.uImage 0x8BDA4000.
- Diferencias finas (DDR, panel LCD, pinmux botones, particiones) — **NO asumibles** del D3100: modelarlas desde DTB stock (Fases 3–4).
