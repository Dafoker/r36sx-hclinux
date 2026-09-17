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

DEPLOY ejecutado y verificado (2026-09-16 20:48): backup `stock.bak` (53b3e0b3) + swap 6w + read-back ×2 OK.

# Resultado del test físico 6w (2026-09-16 noche)

- Consola enciende → **logo TreeFrogUI** → **icono de batería arriba a la derecha (NOVO: primera vez en todos los tests que aparece un elemento de la capa UI)** → se queda ahí; **NO llega al menú**.
- Kernel desplegado **íntegro post-boot** (hash re-verificado en la SD tras el test) — descarta corrupción de SD en el boot.
- Cero escrituras nuevas en la SD (inconcluso: el stock tampoco escribe en boot normal — menu.log/favorites.lst fechan de 1/1/1980).
- Interpretación: el logo lo dibuja el AVP (ya salía en 6b con kernel sin rootfs); el **icono de batería apunta a la capa UI (icube/rkgame) ejecutándose desde la SD** → cadena Linux→initramfs→SD→UI parcialmente viva; hang en la capa del MENÚ (rkgame→zhijack→picoarch).
- **La refutación NO-GE de 6r queda INVALIDADA**: se testeó con S41hcdaemon/S99app no-op — el menú no podía arrancar por diseño; el observable "insert tf card" no discriminaba nada del menú.

# Iteración 6x — drivers NOEXTRA reactivados

Hipótesis: el menú requiere `/dev/ge` (ABI de driver_r36sx.so, iteración 6m) y hwspinlock (AMPRPC AVP) — ambos desactivados por el fragmento NOEXTRA heredado. Acción: retirar TODAS las desactivaciones NOEXTRA (GE/WDT/IRC/HWSPINLOCK/LVDS/NAND/TOE/I2C) → config = **vendor baseline + CHECK_ADC** (delta mínimo).

**BUILD PASS (2026-09-16 22:0x):** uImage `017adf3b07832643a38f2d784be52d522f2e1f300b17fa974e0c38820011cf19`, 4,348,576 B, gzip, Load 0x80000000 / Entry 0x803E3AC0, **hcrc y dcrc VERIFICADOS**. Initramfs embebido CPIO CRUDO 3,849,216 B == stock (diff -r vacío; S41=`hcdaemon&` real). Gates: DTB SEMANTIC PASS (en build) + TOOLCHAIN/PATCH (sin cambios desde 6w). `.config`: HC_GE=y, HC_WDT=y, HC_HWSPINLOCK=y, HC_I2C=y, RD_*=n. Staging: `D:\R36SX\staging\vmlinux.uImage-r36sx-v26-menu-6x`.

# RESULTADO DEL TEST FÍSICO 6x — PHYSICAL PASS (2026-09-16/17 noche)

> "La consola booteó correctamente, llegó al menú principal de TreeFrogUI y fue navegable y funcional." (usuario, evidencia física)

**FASE 5 COMPLETA: el kernel propio bootea la consola real hasta el MENÚ TreeFrogUI funcional.**

## Verificación post-boot (SD en PC)

- `G:\cubegm\vmlinux.uImage` == `017adf3b...` (build 6x, ÍNTegro tras el boot — el dispositivo leyó NUESTRO kernel)
- `stock.bak` == `53b3e0b3` intacto · `dtb.bin` == `1258f1eb` stock intacto · `avp.uImage` == `a9788995` stock intacto
- Cadena de procedencia: build `images/` == staging == SD == `017adf3b` · ep `0x803E3AC0` (distintivo del build propio; stock `0x803337C0`)
- Sin escrituras nuevas en la SD post-boot (normal: la consola solo escribe en cambios de estado)

## Causa raíz de TODOS los fallos previos (confirmación triple)

1. Hasta 6f: kernel sin initramfs embebido → sin rootfs.
2. 6h–6v: S41hcdaemon/S99app no-ops → la cadena de arranque del menú estaba amputada por diseño (diagnóstico).
3. 6w: drivers NOEXTRA desactivados (GE/WDT/IRC/HWSPINLOCK/LVDS/NAND/TOE/I2C off) → la capa del menú (que requiere /dev/ge y hwspinlock) no arrancaba; con initramfs real aparecía la capa UI (batería) pero no el menú.

La solución 6x: **vendor baseline + CHECK_ADC + initramfs stock-parity CPIO CRUDO + S41/S99 reales.**

## Qué es NUESTRO y qué es stock (estado del sistema que bootea)

- **Kernel (vmlinux): 100% NUESTRO** — pipeline propio (4.4.186 vanilla + BSP vendor rsync + 41 patches + board r36sx-v26 + Codescape 6.3.0 + initramfs embebido por nuestro build_kernel.sh). Provenance gates PASS.
- Initramfs embebido: contenido byte-fiel del stock (deliberado — SO del desarrollador, con S41/S99 reales).
- DTB en SD: stock, intocado (≡ nuestro DTB semantic 0-diff). AVP/bootloader: stock, intocados (ADR-008).
- cubegm/UI: stock TreeFrogUI de la SD.

## Pendiente opcional (evidencia definitiva on-device)

Capturar `/proc/version` del kernel corriendo (esperado: `Linux version 4.4.186-release (dafunknoise@DFNK) ...`) via FrogShell/diagnose_console — para el expediente PHYSICAL del repo.
