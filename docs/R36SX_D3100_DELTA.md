# docs/R36SX_D3100_DELTA.md — Delta formal stock ↔ SDK d3100_v20 (Fase 4A §4)

**Base:** DTB stock decompilado (sha `1258f1eb...`) vs DTB SDK d3100_v20 compilado (sha `254522d5...`, generado por nuestro baseline). Diff: 718 líneas, 88 hunks. Orientación: **D3100 = columna vendor; STOCK = columna consola real**.

> Corrige las "8 diferencias" informales de Fases 2.5/3: el análisis completo arroja **15 diferencias formales** (algunas agrupaban 2+ cambios, otras se habían invertido en orientación).

## Tabla formal

| ID | Nodo/Propiedad | D3100 (vendor) | R36SX STOCK | Categoría | Impacto funcional | Confidencia | Fuente | Acción 4B |
|---|---|---|---|---|---|---|---|---|
| D01 | `/memory` reg | `<0x0 0x4F32E40>` (79.20 MiB de 128 total) | `<0x0 0xAF91E50>` (175.57 MiB de 256) | MEMORY | **CRITICAL** — memory map define CONFIG_PHYSICAL_START y layout AVP | HIGH | DTB memory node | DTS propio: memory 0xAF91E50 |
| D02 | hcrtos `bootmem` | `0x2F30000 +0x2000000` (32 MiB) | `0x9DA0000 +0x2000000` | MEMORY/AVP | **CRITICAL** — dirección bootmem AVP dependiente del layout | HIGH | DTB hcrtos/memory-mapping | valor stock |
| D03 | hcrtos `sysmem` | `0x4F32E40 +0xB53600` | `0xBDA2E50 +0xB53600` | MEMORY/AVP | **CRITICAL** | HIGH | idem | valor stock |
| D04 | hcrtos `mmz0` (media) | `0x5F32E40 +0x20CD1C0` (32.8 MiB) | `0xCDA2E50 +0x325D1B0` (50.4 MiB) | MEMORY/MMZ | **CRITICAL** — media memory zone | HIGH | idem | valor stock |
| D05 | hcrtos `mmz1` (kshm) | `0x5A86440 +0x4ACA00` | `0xC8F6450 +0x4ACA00` | MEMORY/MMZ | **CRITICAL** — kshm Linux↔AVP | HIGH | idem | valor stock |
| D06 | `fb0` reg/DE4K | `0x18808000` (no-DE4K) | **`0x1883a000` (DE4K)** | DISPLAY | **FUNCTIONAL** — fb0 del stock usa el pipeline DE4K | HIGH | DTB fb0 | 0x1883a000 |
| D07 | `fb0` buffer | system + extra 12 MiB | **static `0xAF91E50 +0xE11000`**, header 0x1000, use-static-header, default-on | DISPLAY/MEMORY | **FUNCTIONAL-** — buffer estático pegado al final de Linux | HIGH | DTB fb0 | static stock |
| D08 | `fb0` resolución | 1280x720 (`0x500/0x2d0`), scale 1280→1920x1080 | **720x1280 portrait** (`0x2d0/0x500`), yvirt 0x1400 (4 buffers), scale 720x1280→1920x1080 | DISPLAY | **FUNCTIONAL** — panel portrait | HIGH | DTB fb0 | valores stock |
| D09 | Panel/LCD | LVDS `lcd_lvds_1024_600_vesa.dtsi` (include dts:288) | **MIPI-DSI** `lcd-dsi0-r63311` + `dsi0` (4 lanes, reg 0x1884a000) + panel-init-sequence | PANEL | **CRITICAL** — interfaz de display distinta; panel r63311 ausente en SDK | HIGH | DTB dsi0/lcd-dsi0/panel-init | nuevo dtsi propio (dtsi DSI stock) |
| D10 | `/panel` (identidad consola) | **AUSENTE** | botones/HP/speaker/SD-det/batería ADC/lcd-reset/backlight-delay | INPUT/BOARD | **CRITICAL** — sin este nodo el AVP no mapea controles ni batería | HIGH | DTB /panel | nodo nuevo copiado del stock |
| D11 | keys ADC | key_adc0 activo, key-map demo 9 teclas | **key_adc3** con key-map consola 10 teclas; check_adc1/5 + queryadc1/5 activos; irc disabled | INPUT | **FUNCTIONAL** — controles de la consola | HIGH | DTB key_adc*/check_adc* | valores stock |
| D12 | NOR particiones | 7 (boot/dtb/avp/linux/rootfs/eromfs/persistentmem), boot 0x80000, pmem 0x1000 | **3** (boot 0x6C000/eromfs/persistentmem reg 0x70000 size 0x8000), sfspi 7 pines | PARTITION | **CRITICAL** — consola bootea kernel/AVP/rootfs desde **SD**, no NOR | HIGH | DTB sfspi/spi_nor_flash/partitions + SD G: contenido | tabla stock exacta |
| D13 | `chosen` bootargs | `console=ttyS0,115200N8 earlycon=uart8250,mmio,0x18818300` | **`console=tty1 earlycon=`** (serial OFF); aliases serial0 = uart@**18818600** | BOOTARGS | FUNCTIONAL (debug) — stock sin log serial | HIGH | DTB chosen/aliases | valores stock (serial OFF por defecto) |
| D14 | `strappin` reg_bit | `0x18800094 0x14 0x18` | `0x18800094 0x12` (y strappin_avp 0xb8800094 0x12) | PINMUX/BOARD | FUNCTIONAL — strap pins de boot config | HIGH | DTB strappin | valor stock |
| D15 | pinctrl groups/phandles | pctl_uart1 GPIO_T_14/19, pctl_irc, pctl_sdio T_00–05, clock 0x04, 4 hc_uart extra disabled | grupos y phandles distintos (clock pinctrl **0x05**, +groups extra en stock, phandles renumerados) | PINMUX | FUNCTIONAL (phandles deben cuadrar con referencias del propio DTS) | HIGH | diff hunks 616–718 | derivar del roundtrip del DTS propio |

## Resumen

- **CRITICAL: 7** (D01–D05 memoria/AVP/MMZ, D09 panel, D10 /panel, D12 particiones)
- **FUNCTIONAL: 8** (fb reg/buffer/resolución, keys, bootargs, strappin, pinctrl)
- **COSMETIC: 0** · **UNKNOWN: 0**
- Diferencias adicionales no funcionales (phandles renumerados, nodos i2c disabled idénticos) — derivan automáticamente al compilar el DTS propio.

## Nota de método

Las "8 diferencias" previas eran un recuento informal con 2 errores de orientación (fb0 reg y strappin se habían atribuido al revés) y 1 dato erróneo (SDK v20 "254 MiB" venía de macros del v10). Este delta formal lo corrige y es la referencia única para Fase 4B.
