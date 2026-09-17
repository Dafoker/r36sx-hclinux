# Experimento: 2026-09-16 — BUILD MENU-GOAL stock-parity (iteración 6w)

# Objective

Recompilar el kernel r36sx-v26 para que la consola llegue al MENÚ TreeFrogUI, basado en el SO stock (último backup), eliminando toda divergencia diagnosticable entre nuestro binario y el de fábrica. Cierra la orientación "kernel deliberadamente inválido" (descartada por el usuario).

# Antecedentes forenses (2026-09-16)

1. **CORRUPT-header** (`D:\R36SX\staging\vmlinux.uImage-CORRUPT-header`, 12:59): bit-idéntico a NOEXTRA salvo 1 byte (offset 8, timestamp, `0x6a→0x95` = inversión de 8 bits). hcrc INVÁLIDO para su contenido (calculado `0xBC7B8106` ≠ almacenado `0x1FD91C84`; NOEXTRA y stock SÍ válidos). Era un kernel inválido fabricado para test; orientación descartada — NO es corrupción de SD (verificado: stock en G: lee estable, 3 hashes idénticos).

2. **Auditoría de paridad binaria stock (`53b3e0b3`) vs nuestro NOEXTRA (`ce78745a`):**
   - Cmdline: idéntica, provista por el DTB (`/chosen/bootargs = root=/dev/ram0 rootfstype=ramfs rw init=/linuxrc console=tty1 earlycon= no_console_suspend noirqdebug`); `CONFIG_CMDLINE_BOOL` off en ambos.
   - Banner: mismo toolchain (gcc 6.3.0, Codescape 2018.09-02, PREEMPT).
   - **Initramfs STOCK localizado y validado**: cpio CRUDO de **380 archivos / 3,849,052 B en offset 4,857,000** del vmlinux.bin de fábrica (8,709,472 B); extraído a `~/audit6w/stock_initramfs.cpio`. Corrige el claim de 6s: el offset 4,249,444 era el string de `.rodata` "070701…no cpio magic", no el initramfs.
   - **Nuestro initramfs embebido salía COMPRIMIDO**: en este árbol `usr/Makefile` deriva `suffix_y` de `CONFIG_RD_*` — con `RD_GZIP=y` embebe gzip; al quitar solo GZIP, el `RD_LZ4=y` del config base vendor dejó el blob en LZ4 legacy (magic `02 21 4C 18`). La FÁBRICA embebe CPIO CRUDO ⇒ fábrica = todos los RD_* off.
   - **S41hcdaemon y S99app eran no-ops (`true`) desde 6h** (reales en `.orig`, verificados idénticos al stock) ⇒ **NINGÚN test físico 6h–6v pudo llegar al menú** por diseño; la señal "insert tf card" no discriminaba.
   - rootfs-dev.cpio == stock en todo lo demás (diff -r solo S41/S99/S11diag).

# Método (cambios)

1. Overlay `boards/r36sx-v26/rootfs-overlay/etc/init.d/`: restaurar `S41hcdaemon` y `S99app` desde `.orig`, eliminar `S11diag`. Overlay == stock byte-content (diff -r vacío).
2. Fragment `r36sx-v26.config.fragment`: `# CONFIG_RD_{GZIP,BZIP2,LZMA,XZ,LZO,LZ4} is not set` — embebe cpio CRUDO como fábrica y elimina la clase de fallo "unpack de initramfs comprimido falla silenciosamente → rootfs vacío → No init found → 'insert tf card'".
3. `scripts/build_kernel.sh`: `cpio -o -H newc -R 0:0` (dueño root:0 — antes uid=1000; fábrica 0:0).
4. Rebuild: `./scripts/build_kernel.sh r36sx-v26` (2 pasadas: la primera dejó RD_LZ4=y del base vendor → LZ4; corregido).

# Resultado — BUILD PASS

- `.config`: RD_* todos off ✓
- **Initramfs embebido: CPIO CRUDO** (magic `070701` @5,777,452 del vmlinux.bin, 3,849,216 B, dueño 0:0) ✓
- **Contenido embebido == STOCK** (diff -r VACÍO; `S41hcdaemon` = `hcdaemon&`; `S99app` = preinit real wait_for_media_ready) ✓
- uImage `fc501a839d7f645a2ce17dd3d2f53d815e3585aeb6f4861916b6712078e11673`, 4,334,171 B (gzip, Load 0x80000000 / Entry 0x803DE0F0), hcrc VÁLIDO ✓
- Gates: TOOLCHAIN PROVENANCE PASS · PATCH PROVENANCE PASS (41/41) · DTB SEMANTIC PASS (0-diff) ✓
- `bootloader.bin not found` en target-post-image = esperado (ADR-008).
- Staging: `D:\R36SX\staging\vmlinux.uImage-r36sx-v26-menu-6w`.

# Qué cambia respecto a TODOS los tests previos

Primer build con la cadena completa hasta el menú INTACTA: S41hcdaemon real → hcdaemon; S99app real → wait_for_media_ready → bind SD → swap → icube.sh → icube → UI. Si kernel+mmc funcionan, ESTE build llega al menú. Si no llega, el fallo es kernel-runtime (mmc / hang en init) y la vía definitiva es serial (ADR-011).

# Estado

DEPLOY+TEST FÍSICO PENDIENTE (autorización requerida — protocolo Fase 5): backup stock.bak → swap → read-back ×2 → boot → ¿MENÚ TreeFrogUI? Rollback probado (6r/6v) si falla.
