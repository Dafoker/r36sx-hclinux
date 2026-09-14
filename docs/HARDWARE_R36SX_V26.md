# docs/HARDWARE_R36SX_V26.md — Hardware R36SX V2.6 (evidencia física)

**Estado:** FASE 3 — evidencia física consolidada 2026-09-14 (fuentes: SD G: read-only `+/mnt/g/cubegm/`, DTB stock decompilado, uImage stock, reportes del usuario).
**Regla:** todo dato de esta tabla tiene fuente citada. Nada inventado.

## Identidad

| Dato | Valor | Fuente |
|---|---|---|
| SoC | HiChip **HC1600A** (familia HC16xx) | DTB stock: `compatible = "Hichip,1600"`, `model = "Hichip hc16xx"` |
| CPU | MIPS 74Kc, MIPS32r2, **little-endian** | DTB stock nodo cpu; `CONFIG_CPU_MIPS32_R2=y` + `CONFIG_CPU_LITTLE_ENDIAN=y` (kernel stock vermagic config) |
| **Board label stock** | **`hc1600a@dbE3100v20`** | DTB stock nodo board (sha `1258f1eb...`) — **E3100, NO D3100** (corrige reporte previo del usuario) |
| Board SDK más cercana | d3100_v20 (mismatch de familia exacta: el SDK NO contiene E3100) | `grep E3100` en SDK = 0 |

## Boot / kernel stock (físico)

| Dato | Valor | Fuente |
|---|---|---|
| Kernel stock | **4.4.186-release**, `#7 PREEMPT` | vermagic del `vmlinux.uImage` de la SD: `linsen.chen@hichip01` (ingeniero HiChip) |
| Toolchain fábrica | **gcc 6.3.0, Codescape GNU Tools 2018.09-02 for MIPS MTI Linux** — **IDÉNTICO al que usa el SDK y nuestro build** | vermagic stock == nuestro vermagic (solo cambia host/usuario/fecha) |
| uImage stock | gzip, Load `0x80000000`, Entry `0x803337c0`, 3,905,970 B, sha `53b3e0b3...` | mkimage -l SD |
| AVP stock | `avp.uImage`, standalone, Load=Entry `0x8bda4000`, 1,381,540 B payload, gzip, sha `a9788995...` | mkimage -l SD |
| DTB stock | v17, 33,137 B, sha `1258f1eb...` (golden) | SD `/mnt/g/cubegm/dtb.bin` |
| Bootargs stock | `root=/dev/ram0 rootfstype=ramfs rw init=/linuxrc console=tty1 earlycon= no_console_suspend noirqdebug` — **consola serial OFF de fábrica** (`console=tty1`, no `ttyS0`) | DTB stock chosen |
| Rootfs stock | initramfs (/dev/ram0), init=/linuxrc | bootargs stock |

## Memoria (físico — CRÍTICO)

| Dato | Valor | Fuente |
|---|---|---|
| RAM total | 256 MiB (`CONFIG_MEMORY_SIZE 0x10000000` en familia; confirmado por DTB dims) | DTB stock |
| **Linux visible stock** | **`reg = <0x00 0xaf91e50>` = 184,451,920 B ≈ 176 MiB** (offset 0x0) | DTB stock memory node |
| Reservado AVP/MMZ | ~256-176 = **~80 MiB** | cálculo sobre DTB stock |
| ⚠️ SDK d3100_v20 | Linux = 254 MiB (SYSMEM 2MB + MMZ 0) | `hc16xx-db-d3100-v20-avp.dtsi` — **NO USAR en la consola real: pisaría memoria del AVP** |

## Display (físico)

| Dato | Valor | Fuente |
|---|---|---|
| fb0 | `reg = <0x18808000 0x1000>` (NO DE4K `0x1883a000`), 32bpp, **1280x720** (xres 0x500), `buffer-source = "system"`, `extra-buffer-size = 0xc00000` (12 MiB), scale `<1280 720 1920 1080>` | DTB stock fb0 |
| fb1 | `reg = <0x18808080 0x1000>`, 8bpp, 1280x720, status disabled | DTB stock fb1 |
| Backlight | nodo `backlight` via `avp-proxy` presente en stock, ausente en SDK v20 | DTB stock |

## Input (físico)

| Dato | Valor | Fuente |
|---|---|---|
| GPIO key | `reg_bit = <0x18800094 0x14 0x01 0x18800094 0x18 0x01>` (bits 0x14/0x18 — SDK usa 0x12) | DTB stock vs SDK diff |
| ADC keys | `hc16xx-key-adc` + `check-adc` presentes | DTB stock |
| Clocks | `clock = <0x05>` en pinctrl stock (SDK 0x04) | DTB stock diff |

## Otros periféricos (físico)

- 4 UARTs extra `hc_uart@18818300/18818600/18818800/18818900` presentes (todos `status="disabled"` en stock; UART0 base sigue `0x18818300` según bootargs earlycon de variants con serial).
- `persistentmem` size 11240 B (matches SDK).
- WiFi/BT: sin evidencia de chip específico en DTB stock (sin nodos wifi) — consola no tiene WiFi; los drivers RTL/AIC del SDK son para otros boards.

## Diferencias clave stock vs SDK d3100_v20 (resumen para Fase 4)

1. Board label: **E3100v20** vs D3100v20.
2. Memoria Linux: **~176 MiB** vs 254 MiB (CRÍTICO — riesgo de pisar AVP).
3. Bootargs: `console=tty1` (sin serial) vs `console=ttyS0,115200`.
4. fb0: `0x18808000` + buffer system 12MiB extra vs `0x1883a000` + static.
5. GPIO key bits 0x14/0x18 vs 0x12.
6. fb0 stock 1280x720 (xres 0x500) horizontal; SDK v20 720x1280 vertical.
7. Nodo `backlight` avp-proxy extra en stock.
8. Clock pinctrl 0x05 vs 0x04.

**Conclusión:** board propia `r36sx-v26` (Fase 4) **obligatoria** — derivar del DTB stock decompilado + estructura SDK. No flashear nada con DTB/defconfig SDK d3100_v20 en la consola.

## Fuentes de evidencia física

- SD G: read-only: `/mnt/g/cubegm/{vmlinux.uImage,avp.uImage,dtb.bin}` (hashes arriba)
- DTB stock decompilado: `~/work/r36sx-hclinux/cache/dtb_compare/r36sx-stock.dts` (WSL)
- Diff completo: `~/work/r36sx-hclinux/cache/dtb_compare/stock_vs_d3100v20.diff` (718 líneas)
- Reportes del usuario: `D:\GitHub\KERNEL\work\reports\` + `work\verification\` + `work\build\`
