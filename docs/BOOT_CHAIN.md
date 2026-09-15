# docs/BOOT_CHAIN.md — Cadena de boot R36SX V2.6 (CONFIRMADA)

**Evidencia completa:** `docs/SDK_AUDIT.md` §boot-chain · `docs/ARCHITECTURE.md`. Toda dirección citada abajo tiene ruta de evidencia allí.

## Secuencia (evidencia SDK + manual cross-checkeado)

1. **BootROM** HC16xx → lee bloque **DDR-init** desde NOR (`hc16xx_ddr3_128M_1066MHz.abs`, 12,288 B físicos) e inicializa DDR.
2. BootROM carga **bootloader.bin** = `cat ddrinit u-boot.bin` (post-build.sh:216).
3. **u-boot/hcboot** (compilado desde `SOURCE/avp/components/applications/apps-bootloader`):
   - Inicia **AVP primero**: `avp.uImage` (uImage tipo standalone, Load=Entry=`0x8BDA4000`, gzip/lzma/lzo).
   - Entrega el DTB del AVP vía registro **`0xb8800004`** (main.c:620).
   - Luego `bootm` **Linux**: `vmlinux.uImage` (stock R36SX: Load `0x80000000`, Entry `0x803EC710`), DTB en **`0x85ff0000`** (AutoRun0=`wm 0xb8800004 0x85ff0000`, post-build.sh:125+).
4. **Linux 4.4.186** en core-main; **HCRTOS/AVP** en core-AVP; comunicación **AMPRPC** (amprpc/avp-proxy/kshm), memoria media **MMZ**.

## Direcciones clave (todas con evidencia — tabla comparativa Fase 4)

| Elemento | STOCK (fábrica) | D3100 baseline | R36SX-V26 build (Fase 4B) | Evidencia |
|---|---|---|---|---|
| Linux load | `0x80000000` | `0x80000000` | `0x80000000` | uImage headers ×3 |
| Linux entry | `0x803337c0` (config fábrica, no en SDK) | `0x803e3200` | **`0x803e3200`** (== baseline; config vendor SDK) | uImage headers + readelf |
| DTB address | `0x85ff0000` | idem (pipeline) | idem (DTB idéntico al stock) | post-build.sh:125+ |
| Linux memory | `0x0 + 0xAF91E50` (175.57 MiB) | `0x0 + 0x4F32E40` (79.20) | **`0x0 + 0xAF91E50` (== stock)** | DTB memory node + compare gate |
| AVP load/entry | `0x8BDA4000` | n/a (AVP off) | n/a (AVP stock preservado) | uImage stock SD + ADR-008 |
| AVP sysmem | `0xBDA2E50 + 0xB53600` | `0x4F32E40 + 0xB53600` | **`0xBDA2E50 + 0xB53600` (== stock)** | DTB hcrtos + compare gate |
| AVP entry verificado | sysmem stock +0x1000 → `0x8BDA4000` = entry real avp.uImage stock ✓ | — | — | DTS_STOCK_MODEL §verificación macros |
| FB static | `0xAF91E50 + 0xE11000` | n/a (system) | **== stock** | DTB fb0 |
| mmz0/mmz1 | `0xCDA2E50+0x325D1B0` / `0xC8F6450+0x4ACA00` | otros | **== stock** | DTB hcrtos |

**Diferencia residual documentada (no del DTS):** entry/data-size del kernel stock provienen del config interno del fabricante (no incluido en SDK); nuestro build replica el config vendor SDK. DTB entregado al bootloader = idéntico al stock.

## Zona prohibida (AGENTS.md §5, ADR-005)

DDR-init, bootloader, AVP: **intocables en baseline**. Clase D requiere autorización explícita. Deploy físico (Fase 5): solo reemplazo de `vmlinux.uImage` (+`dtb.bin`) en SD — la consola bootea desde SD (NOR 3 particiones: boot/eromfs/persistentmem — docs/DTS_STOCK_MODEL.md).
