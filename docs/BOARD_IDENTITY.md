# docs/BOARD_IDENTITY.md — Identidad de board R36SX V2.6: E3100 vs D3100 (Fase 2.5 §11)

**Estado:** COMPLETADA 2026-09-14 · **BOARD IDENTITY: DOCUMENTED**
**Pregunta:** ¿qué relación hay entre el board label stock `hc1600a@dbE3100v20` y la board SDK `d3100_v20` usada como pipeline baseline?

## 1. ¿Existe soporte E3100 en el SDK?

**NO como board/defconfig.** Búsqueda exhaustiva (`grep -RliE 'e3100'` en todo el SDK, excluyendo .git):
- 0 matches en `configs/` (ningún defconfig E3100), `board/`, `linux/`, `buildroot/configs/`.
- Matches existentes son código genérico no-board: `SOURCE/linux-drivers/include/uapi/hcuapi/chipid.h` (enum `hc_chipid_e`: `HICHIP_E3000 = 400, HICHIP_E3100`), `efuse_rw.c` (usa chipid), `libefuse.a`/`hc_efuse.ko` (binarios), y falsos positivos de ffmpeg (referencias de tests).

**Conclusión: `HICHIP_E3100` es un CHIPID reconocido por el código SDK (enum), pero NO existe board E3100, DTS E3100 ni defconfig E3100 en el SDK.** La familia "E" existe en el chipid enum (E3000=400, E3100=401) junto a D3201, pero el SDK 2024.02.y.2 solo trae boards A/B/C/D.

## 2. ¿Existe con otro nombre?

Hipótesis razonable: "E3100" podría ser el marketing-name de una variante D3100/other para consolas portátiles (los fabricantes de estas consolas suelen recibir SDK con labels custom `dbE3100`). **Sin evidencia SDK para afirmarlo — queda como INFERENCIA etiquetada.** El DTB stock decompilado no incluye `#include` (es DTB compilado), por lo que el include-graph no es directamente observable; el matching se hace por nodos (§3).

## 3. ¿D3100 y E3100 comparten estructura DTS?

**Matching por nodos (report 10 del usuario + diff 718 líneas propio):** todos los nodos funcionales del stock existen en el DTS SDK d3100_v20 con los mismos compatibles (`hichip,hc16xx-*`: amprpc, avp-proxy ×18, kshm, mmz, fb, ge, musb, dw-mshc, key-adc, gpio, pwm, persistentmem, uart, i2c, lvds, spi-sf...). La topología es la misma; **difieren los valores** (§4). Es decir: misma familia arquitectural HC16xx, revisión de board distinta.

## 4. Las 8 diferencias stock ↔ SDK d3100_v20 (evidencia: diff DTB decompilado, `~/work/r36sx-hclinux/cache/dtb_compare/stock_vs_d3100v20.diff`, 718 líneas)

| # | Subsistema | Stock (R36SX real) | SDK d3100_v20 | Impacto |
|---|---|---|---|---|
| 1 | board label | `hc1600a@dbE3100v20` | `hc1600a@dbD3100v20` | identidad/cosmético + tooling vendor |
| 2 | **memoria** (D01–D05) | total 256 MiB: **Linux 175.57** (`0xAF91E50`) + **AVP 80.43** (FBstatic 14.07 + sysmem 11.33 + mmz1 4.67 + mmz0 50.36) | total 128 MiB: Linux 79.20 (`0x4F32E40`) | **CRÍTICO — memory maps incompatibles → DTS propio obligatorio** (docs/DTS_STOCK_MODEL.md) |
| 3 | bootargs | `console=tty1 earlycon= ` (serial OFF) | `console=ttyS0,115200N8 earlycon=uart8250,mmio,0x18818300` | debug portuario; stock sin UART log |
| 4 | fb0 | **`0x1883a000` (DE4K), buffer static `0xAF91E50+0xE11000`, 720x1280 portrait** | `0x18808000`, buffer system +12MiB, 1280x720 | display pipeline (nota: docs Fase 2.5 tenían la orientación INVERTIDA — corregido Fase 4A) |
| 5 | strappin GPIO | `0x18800094 0x12` (y strappin_avp `0xb8800094 0x12`) | `0x18800094 0x14/0x18` | straps de boot config (docs Fase 2.5 lo tenían invertido — corregido) |
| 6 | UARTs | 4 nodos `hc_uart@18818300/8600/8800/900` extra (disabled) | ausentes | pinmux/pad availability |
| 7 | backlight | nodo `backlight` (avp-proxy) presente | ausente | control de retroiluminación |
| 8 | clock pinctrl | `clock = <0x05>` | `<0x04>` | clock de pinctrl/input |

Más: **panel MIPI-DSI `lcd-dsi0-r63311`** con `panel-init-sequence` propia (ausente en SDK, grep=0) · **nodo `/panel` de identidad de consola** (botones/HP/speaker/sdio-det/batería) inexistente en SDK · **particiones NOR 3 vs 7** (la consola bootea kernel/AVP/rootfs desde la SD, no desde NOR — ver docs/R36SX_D3100_DELTA.md D12 y docs/DTS_STOCK_MODEL.md).

**CORRECCIÓN Fase 4A (supera la tabla de 8 filas de Fase 2.5):** el análisis formal completo (718 líneas diff, 88 hunks) arroja **15 diferencias formales** documentadas en `docs/R36SX_D3100_DELTA.md` (7 CRITICAL + 8 FUNCTIONAL), con 2 errores de orientación corregidos (fb0, strappin) y el dato "SDK 254 MiB" desmentido (real: 128 MiB total v20).

## 5. ¿Afectan a...?

memoria (SÍ, crítico #2) · display (SÍ #4 + panel DSI) · GPIO (SÍ #5) · input (SÍ, key bits) · SD (no — dw-mshc igual) · USB (no — musb igual) · partitions (DTB no contiene tabla de particiones; layout flash aún sin evidencia física — pendiente si se requiere) · AVP (indirecto: memoria #2 define el budget AVP; el avp.dtsi stock difiere del SDK en sysmem/mmz) · clocks (SÍ #8) · pinmux (SÍ #5/#6/#8).

## 6. ¿Cuál debe ser la base de r36sx-v26?

**Base estructural:** `board/hichip/hc16xx/common/dts/hc16xx-db-d3100-v20.dts` + `hc16xx-common.dtsi` + `-avp.dtsi` del SDK (mismos include-graph y plumbing del pipeline).
**Valores de hardware:** **DTB stock decompilado de la consola** (fuente de verdad física): las 8 diferencias + panel DSI + memory map E3100 aplicadas encima.
**Estado de D3100:** VENDOR PIPELINE BASELINE (ADR-007) — NO es hardware baseline. `r36sx-v26` = DTS/defconfig propios derivados por evidencia, verificados por: dtc round-trip, comparación nodo-a-nodo vs stock, y gate C (kernel build con DTS propio).

## Veredicto

```
E3100 SEARCH:         DONE — chipid enum HICHIP_E3100 existe; NO board/DTS/defconfig E3100 en SDK
D3100 RELATION:       misma familia HC16xx (matching nodos HIGH); board distinta (revisión E)
8 STOCK DIFFERENCES:  DOCUMENTED (tabla §4 — 1 crítica: memoria AVP)
HARDWARE BASELINE:    r36sx-v26 propio (Fase 4) — D3100 queda SOLO pipeline baseline
BOARD IDENTITY:       DOCUMENTED
```
