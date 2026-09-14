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

## Direcciones clave (todas con evidencia)

| Elemento | Valor | Evidencia |
|---|---|---|
| DTB load | `0x85ff0000` | post-build.sh:125,147,169 |
| Reg DTB→AVP | `0xb8800004` | apps-bootloader main.c:620; avp dts Kconfig:19 |
| AVP load/entry (stock R36SX) | `0x8BDA4000` | dump uImage usuario |
| Linux load (stock R36SX) | `0x80000000` / Entry `0x803EC710` | dump uImage usuario |
| Linux load (SDK, derivado) | `CONFIG_LINUX_MEMORY_OFFSET` (=0) + `CONFIG_PHYSICAL_START` parcheado desde DTS | linux-ext-fixup-load-addr.mk |

## Zona prohibida (AGENTS.md §5, ADR-005)

DDR-init, bootloader, AVP: **intocables en baseline**. Clase D requiere autorización explícita.
