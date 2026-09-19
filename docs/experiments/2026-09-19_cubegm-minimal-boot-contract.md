# Experimento 2026-09-19 — cubegm/ al mínimo: investigación de la cadena pre-Linux y el contrato NOR de boot

# Objective

Determinar si `cubegm/` puede eliminarse por completo de la SD (decisión del usuario) y ejecutar el mínimo alcanzable.

# Evidence (investigación completa — SDK, código del bootloader, DTS stock, binario AVP)

**1. El path `cubegm/` NO está hardcodeado en el bootloader** — es una propiedad del DTB:
- `SOURCE/avp/components/applications/apps-bootloader/source/main.c`: `get_block_devpath()` → `fdt_get_node_offset_by_path("/hcrtos/external_files")` → lee `path-prefix` + `part%d-filename`/`part%d-label` del DTB ACTIVO del HCRTOS (`fdt_api.c:261` — puntero global `fdtp`).
- DTS stock (`reference/stock-normalized.dts:178-189`): `external_files { part-num=<4>; part1=dtb.bin/dtb; part2=avp.uImage/avp; part3=vmlinux.uImage/linux; part4=xgame-logo.bmp/logo; path-prefix="cubegm"; }` — **única referencia a cubegm en todo el DTS**.

**2. Secuencia de boot (`bootup_hclinux_dualcore`, main.c:600-655):** registro 0xb8800004 → buffer DTB; carga `cubegm/dtb.bin` (mtdloadraw) → `sysdata_update_dt()`; carga `avp.uImage` → bootm AVP; carga `vmlinux.uImage` → `bootm(loadaddr, "-", dtbaddr)` Linux.

**3. El pinning:** el `fdtp` que usa el bootloader para buscar los archivos es el DTB de SU HCRTOS — **embebido en NOR** (hornero de fábrica con `path-prefix="cubegm"`). El `dtb.bin` de la SD se pasa al AVP y al kernel, pero NO re-polariza las búsquedas del bootloader. → **Los 4 archivos {dtb.bin, avp.uImage, vmlinux.uImage, xgame-logo.bmp} están anclados a `cubegm/` por NOR** — inamovibles desde la SD.

**4. El AVP de fábrica NO hardcodea cubegm** (strings del binario: 0 matches setting.xml/cubegm/xgame/allfiles/root.dat). `setting.xml`/`allfiles.lst`/`root.dat` eran configs del MENÚ DE FÁBRICA (rkgame/MyExecutable — fuera de nuestro boot desde 8d). El culpable del fail de la primera instalación limpia era casi con certeza **`xgame-logo.bmp` (part4 del bootloader)** — el único de los 4 sospechosos que el bootloader carga.

# Result (análisis)

| Objetivo | Veredicto |
|---|---|
| **cubegm 100% eliminado** | Solo posible reemplazando el bootloader de NOR (fuente + toolchain disponibles desde 9a — ADR-008 cayó), horneando un NOR-DTB con otro `path-prefix`. **Zona prohibida (§5): flashear NOR = riesgo de brick sin dump de NOR para rollback.** No recomendado; requiere autorización explícita + plan de recuperación BootROM/HCPROGRAMMER validado. |
| **cubegm mínimo sin tocar NOR** | **4 archivos (3,9 MB): dtb.bin, avp.uImage, vmlinux.uImage, xgame-logo.bmp** — el "contrato NOR de boot" (análogo al DDR-init: hardware, no software eliminable). Todo lo demás fuera. |

# Files changed (iteración)

- SD: eliminados `cubegm/{setting.xml, allfiles.lst, root.dat}` (solo-fábrica-menú). cubegm = 4 boot + 2 goldens + flag diag (+ logs regenerables).
- Sin cambios de kernel/build — test puro de layout.

# Tests

- **PHYSICAL: PENDIENTE (usuario)** — boot con cubegm = contrato de 4. PASS → confirma: el culpable del fail original era `xgame-logo.bmp` (bootloader part4) y cubegm llegó a su mínimo NOR. FAIL → restaurar (desde backup tar) el archivo necesario — cubegm sería de 5.

# Decision (pendiente del test)

- Con PASS: cubegm/ queda definido como **contrato de boot de NOR** — documentado en TREEFROG_UI_CONTRACT + BOOT_CHAIN como pieza de hardware (junto a DDR-init/bootloader). La eliminación 100% queda archivada como opción Class D (bootloader propio + reflash NOR) — no activa.
- Tras el cierre: Fase 7 (directiva del usuario).

# Next action

Usuario: boot de la consola. PASS → cerrar caso cubegm + Fase 7. FAIL → traer SD, restaurar el archivo culpable del tar, cerrar en 5.
