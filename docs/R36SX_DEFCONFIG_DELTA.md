# docs/R36SX_DEFCONFIG_DELTA.md — Delta defconfig: vendor d3100_v20 → r36sx_v26 (Fase 4B)

**Generado por diff formal** (`hichip_hc16xx_db_d3100_v20_defconfig` vs `hichip_hc16xx_r36sx_v26_defconfig`). **8 cambios, todos REQUIRED, 0 optimizaciones** (regla Fase 4: stock equivalence primero).

| # | Símbolo | D3100_v20 | r36sx_v26 | Clase | Razón |
|---|---|---|---|---|---|
| 1 | `BR2_DEFCONFIG` | `..._db_d3100_v20_defconfig` | `..._r36sx_v26_defconfig` | identidad | board propia |
| 2 | `BR2_LINUX_KERNEL_CUSTOM_DTS_PATH` | 4 archivos (dts+dtsi+avp.dtsi+lcd/*.dtsi glob) | **1 archivo: board/hichip/hc16xx/r36sx_v26/dts/r36sx-v26.dts** (self-contained, stock-verbatim) | REQUIRED | DTS stock-equivalent (allowlist 0) |
| 3-4 | `BR2_TARGET_HCBOOT` (+DEFCONFIG line) | `y` | `not set` (+línea DEFCONFIG eliminada) | ADR-008 | bare-metal privado; bootloader stock preservado |
| 5-6 | `BR2_PACKAGE_AVP` (+DEFCONFIG line) | `y` | `not set` (+línea eliminada) | ADR-008 | idem; AVP stock preservado (avp.uImage de la SD) |
| 7 | `BR2_PACKAGE_HCCAST{,_NET,_WIRELESS,_AIRCAST,_MIRACAST,_DLNA}` | `y` ×6 | `not set` ×6 | REQUIRED (bug vendor) | libcast sin Config.in (kconfig bug SDK — Fase 2) |

## Kernel .config delta (r36sx vs vendor baseline): **0 líneas**

El kernel config resultante es **IDÉNTICO** al del baseline d3100_v20 (ambos usan `kernel-configs/4.4.186/kernel-squashfs.config` compartido). **EXPECTED PASS**: en este pipeline el hardware se define en el DTS, no en el kernel config. Ningún cambio de drivers/scheduler/memoria — stock equivalence pura.

## Diferencias vs STOCK esperadas (documentadas, no optimizaciones)

- Entry point del kernel: nuestro `0x803e3200` (== vendor baseline) vs stock `0x803337c0` — la fábrica compiló con un config propio no incluido en el SDK; el nuestro replica el vendor SDK. La diferencia es de layout de link (config), NO del DTS; el DTB entregado al bootloader es idéntico al stock.
- Data size uImage: 2.58 MiB (nuestro, == baseline) vs stock 3.72 MiB (config fábrica con más drivers builtin).
- `bootloader.bin` ausente en empaquetado final (ADR-008) — el stock sigue en NOR/SD.
