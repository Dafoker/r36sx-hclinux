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
| 2 | **memoria Linux** | `reg = <0x0 0xaf91e50>` ≈ **176 MiB** | 254 MiB (CONFIG_MEMORY_SIZE-MINIMAL AVP) | **CRÍTICO — DTB SDK en consola real pisaría la memoria del AVP → brick funcional** |
| 3 | bootargs | `console=tty1 earlycon= ` (serial OFF) | `console=ttyS0,115200N8 earlycon=uart8250,mmio,0x18818300` | debug portuario; stock sin UART log |
| 4 | fb0 | reg `0x18808000`, buffer **system** + extra 12 MiB, 1280x720, scale→1920x1080 | reg `0x1883a000` (DE4K), buffer **static** `0x4f32e40`, 720x1280 | display pipeline/rendering |
| 5 | GPIO key | `reg_bit <0x18800094 0x14 0x01 ... 0x18 0x01>` (bits 0x14/0x18) | `0x18800094 0x12 0x01` | mapeo de botones físicos |
| 6 | UARTs | 4 nodos `hc_uart@18818300/8600/8800/900` extra (disabled) | ausentes | pinmux/pad availability |
| 7 | backlight | nodo `backlight` (avp-proxy) presente | ausente | control de retroiluminación |
| 8 | clock pinctrl | `clock = <0x05>` | `<0x04>` | clock de pinctrl/input |

Más: **panel MIPI-DSI propio** con `panel-init-sequence` completa (líneas 1736–1744 del stock .dts) — el stock define un panel DSI concreto que el SDK no trae (los lcd/*.dtsi del SDK son otros paneles).

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
