# docs/DTS_STOCK_MODEL.md — Modelo de hardware stock R36SX V2.6 (Fase 4A)

**Estado:** FASE 4A COMPLETADA 2026-09-14 · Roundtrip SEMANTIC PASS
**Fuente autoritativa:** DTB stock de la consola (SD G:, sha256 `1258f1eb...`, read-only — nunca modificado).

## Procedencia y reproducibilidad

- `dtc --version`: **1.7.0** (WSL Ubuntu 24.04).
- Decompile sorted: `dtc -I dtb -O dts -s` → 1818 líneas (35 warnings benignos de dtc sobre formatos reg/unit-address — vendor tree, no errores).
- Roundtrip: `dts → dtb → dts` **SEMANTIC PASS** (sorted dts idéntico). Binario difiere (`04fb8383...` vs original — esperable: layout/string-table de dtc; la semántica es el gate).
- Script reproducible: `scripts/extract_stock_dts.sh` (DTB externo → DTS normalizado; el DTB propietario NO se versiona, solo sus hashes).

## MAPA DE MEMORIA (resuelve la contradicción §0 — valores exactos del DTB stock)

| Región | Inicio | Tamaño | Fin | MiB | Consumidor |
|---|---|---|---|---|---|
| **Linux (memory node)** | `0x00000000` | `0x0AF91E50` | `0x0AF91E50` | **175.57** | Linux core-main |
| FB static (fb0 buffer) | `0x0AF91E50` | `0x00E11000` | `0x0BDA2E50` | 14.07 | framebuffer estático fb0 |
| HCRTOS sysmem | `0x0BDA2E50` | `0x00B53600` | `0x0C8F6450` | 11.33 | AVP sistema |
| mmz1 "kshm" | `0x0C8F6450` | `0x004ACA00` | `0x0CDA2E50` | 4.67 | memoria compartida Linux↔AVP (kshm) |
| gap alignment | `0x0CDA0E50` | `0x00002000` | `0x0CDA2E50` | 0.01 | alineación |
| mmz0 (media) | `0x0CDA2E50` | `0x0325D1B0` | `0x10000000` | 50.36 | AVP media MMZ |
| bootmem hcrtos | `0x09DA0000` | `0x02000000` | `0x0BDA0000` | 32.00 | bootmem hcrtos (transitorio, solapa cola de Linux — solo durante boot AVP) |

**TOTAL RAM: 256 MiB (`0x10000000`** — mmz0 termina exactamente ahí**)**.
**LINUX: 175.57 MiB · No-Linux (lado AVP, suma FBstatic+sysmem+mmz1+mmz0+gap): 80.43 MiB.**

### Resolución de la contradicción (corrección de documentos previos)

- ✅ "Linux stock ≈ 176 MiB" — correcto (175.57).
- ❌ "AVP reserva 176 MiB" (frase de Fase 2.5 BOARD_IDENTITY) — **ERROR de redacción**: el AVP reserva **80.43 MiB**; 176 era el tamaño de Linux. Corregido.
- ❌ "SDK d3100_v20 = Linux 254 MiB" (Fases 2/2.5, tomado de las macros del avp.dtsi **v10**) — **ERROR**: el defconfig v20 real compila con `CONFIG_MEMORY_SIZE 0x08000000` (**128 MiB total**, Linux = `0x4F32E40` = 79.20 MiB, bootmem 0x2F30000, sysmem 0x4F32E40+0xB53600, mmz0 0x5F32E40+0x20CD1C0, mmz1 0x5A86440+0x4ACA00). El DTB SDK v20 compilado (sha `254522d5...`) lo confirma. Corregido en HARDWARE/BOARD_IDENTITY/ARCHITECTURE.

**Diferencia crítica confirmada:** si se flashease un DTB d3100_v20 en la consola, Linux creería tener 79 MiB (no pisaría AVP por defecto), pero el AVP intentaría usar mmz0 hasta `0x7FFFFF00`+ = dentro de RAM real; PERO el memory-mapping AVP del SDK (sysmem 0x4F32E40) **coincide con el final del Linux del SDK** — en la consola real con kernel stock (Linux 175 MiB) el AVP del SDK pisaría memoria Linux. En cualquier caso, memory maps incompatibles = brick funcional. **El DTS propio es obligatorio (Fase 4B).**

## Nodos clave del stock (evidencia exacta, decompilado)

### chosen / aliases / bootargs
```
bootargs = "root=/dev/ram0 rootfstype=ramfs rw init=/linuxrc console=tty1 earlycon= no_console_suspend noirqdebug";
stdout-path = "serial0:115200n8";  serial0 = &hc_uart@18818600   ← UART1, no UART0
```
Serial **desactivado** de fábrica (`console=tty1`, `earlycon=` vacío).

### board identity
`board.label = "hc1600a@dbE3100v20"` (nodo hcrtos) · `model = "Hichip hc16xx"` · `compatible = "Hichip,1600"`.

### Panel (DISPLAY — evidencia §3 Fase 4A)

| Propiedad | STOCK | D3100 SDK v20 | Evidencia |
|---|---|---|---|
| Interface | **MIPI-DSI** (`dsi0`, reg `0x1884a000`, 4 lanes, format 5, cfg 0x1c, flags 0x3fd, LP-CLK-DIV 2, drive-strength 2) | **LVDS** (`lcd_lvds_1024_600_vesa.dtsi` incluido por el dts v20) | DTB stock nodo dsi0 + SDK dts:288 |
| Panel driver | **`lcd-dsi0-r63311`** (status okay) — **NO existe en el SDK** (grep r63311 = 0) | ninguno equivalente | DTB stock:1721; grep SDK = 0 |
| panel-init-sequence | presente (4524 bytes, secuencia DSI completa) | n/a | DTB stock dsi0 |
| reset GPIO | `lcd-reset-gpios-rtos = <6 1>` + `lcd-reset-pin = <6>` | n/a | dsi0 + /panel |
| lcd-type | `0x04` | n/a | /panel |
| Timings | `clock-frequency/h-sync/v-sync = 0` (derivados por driver) | n/a | dsi0 |
| rgb-cfg | lcd-width `0x280` (640) | `0x400` (1024) | rgb-cfg |

**NO se inventa nombre del panel**: el nodo se llama `lcd-dsi0-r63311` (driver IC R63311, fabricante no declarado en DTB). El `panel-init-sequence` del stock ES la definición del panel.

### /panel — nodo de identidad de la consola (INEXISTENTE en SDK — 0 matches de todas sus props)

```
key-do=9, key-clk=8, key-tl1=11, key-tr1=7, key-shoulder-left=11, key-shoulder-right=7,
key-volume-down=12, key-volume-up=13, key-fn=2, headphone-detect=15, speaker-output=19,
lcd-reset-pin=6, power-button=14, power-pin=1, sdio-det=109, backlight-delay=200ms,
lcd-type=4, adc-bat-level="/dev/check_adc1", adc-bat-charging="/dev/check_adc5",
boot-adc-bat-level="/dev/queryadc1", boot-adc-charging="/dev/queryadc5"
```

### Input (keys/ADC)
- `key_adc3@18818400` **activo** (status disabled en DTB pero con key-map completo de 10 teclas de consola: thresholds `0xc8 0x1f4 0x259 0x352 0x353 0x44c 0x44d 0x514 0x515 0x5dc 0x5dd 0x686 0x687 0x6fe 0xae`, códigos `0x67 0x6c 0x69 0x6a 0x160 0x8b 0x6fe`) — SDK usa key_adc0 demo (9 teclas genéricas).
- `check_adc1` y `check_adc5` **activos** (batería); `queryadc1/queryadc5` para boot.
- `irc` (infrarrojos): **disabled** (SDK: okay).

### Flash NOR + particiones (DIFERENCIA ESTRUCTURAL MAYOR)

| | STOCK (consola) | SDK d3100_v20 |
|---|---|---|
| part-num | **3** | **7** |
| boot | `0x0–0x6C000` (432 KiB) | `0x0–0x80000` (512 KiB) |
| dtb/avp/linux/rootfs | **AUSENTES en NOR** | dtb@0x80000/avp@0x90000(1.6M)/linux@0x230000(3M)/rootfs@0x530000(10.5M) |
| eromfs | `0x6C000+0x4000` | `0xFB0000+0x30000` |
| persistentmem | **reg `0x70000`, size `0x8000`** (32 KiB) | `0xFE0000+0x20000`, size `0x1000` |
| pinmux sfspi | 7 pines `0x6e–0x73` | 6 pines `0x6f–0x72` |

**Interpretación (evidencia secundaria: contenido de la SD G:): la consola stock NO guarda kernel/rootfs en NOR** — el bootloader NOR carga `vmlinux.uImage`/`avp.uImage`/`dtb.bin` desde la **partición FAT de la SD** (`/mnt/g/cubegm/`). El devkit D3100 sí flashea todo en NOR. **Esto cambia la estrategia de deploy de Fase 5: reemplazo de kernel = copiar archivo en SD, sin tocar NOR.**

### Otros nodos verificados (iguales al SDK salvo phandles)
musb ×2 (`0x18844000`/`0x18850000`), dw-mshc sdio (`0x1884c000`), nfc (`0x18832000`), amprpc/avp-proxy/kshm/virtuart/mmz, gpio (`0x18800000`), pwm, watchdog, ge, fb1 (disabled), persistentmem, spidev, i2c ×4 (disabled), hc_uart ×5 (uart0 `0x18818300` base, uart1 `0x18818600` = serial0), strappin (`0x18800094 0x12`), hcrtos strappin_avp (`0xb8800094 0x12`).

## Gate Fase 4A

```
STOCK DTB IDENTIFIED:   PASS (SD G: dtb.bin — read-only)
STOCK DTB HASHED:       PASS (1258f1eb... — manifests/r36sx-v26-stock.sha256)
STOCK DTS DECOMPILED:   PASS (dtc 1.7.0, 1818 líneas)
ROUNDTRIP:              PASS (SEMANTIC — sorted dts idéntico tras dtb)
SEMANTIC COMPARISON:    PASS (plain vs sorted coherentes)
MEMORY MAP:             PASS (tabla arriba; contradicción resuelta)
LINUX/AVP/MMZ SPLIT:    PASS (175.57 / 80.43 MiB de 256 total)
PANEL/DISPLAY:          PASS (MIPI-DSI r63311 — demostrado, no asumido)
8+ DIFFERENCES:         EXPLICIT (docs/R36SX_D3100_DELTA.md — 15 formales)
E3100 SEARCH:           COMPLETE (BOARD_IDENTITY.md + §5 fase 4A: 0 hits r63311/panel-props en SDK)
DOCUMENTATION:          PASS
```
