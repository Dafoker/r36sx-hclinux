# docs/TREEFROGUI_COMPATIBILITY.md — Contrato TreeFrogUI

**Estado:** EN CURSO (Fase 6, iteración 7a). Upstream: https://github.com/tzubertowski/TreeFrogUI
**Validación física base:** Fase 5 PHYSICAL PASS (2026-09-16, kernel propio `017adf3b` — menú TreeFrogUI navegable y funcional).

## Matriz de dependencias

Fuentes de evidencia: **6m** = ingeniería inversa cubegm (`docs/experiments/2026-09-15_cubegm-reverse-engineering.md`); **6l** = DIAG2 fábrica (`evidence-factory-diag2.log`); **6x** = validación física diferencial (6w sin drivers vs 6x con drivers); **DIAG6X** = captura on-device pendiente (`scripts/diagnose_console_6x.sh`, log `diag6x_*.log`).

| Dependencia | Requerida por | Evidencia | Status |
|---|---|---|---|
| `/dev/fb0` (fbdev hcfb) | render UI (TF_PRESENT=fbwrite) | 6m + 6x: el menú se dibuja | **VALIDADO (6x PHYSICAL)** |
| `/dev/ge` (HC_GE 2D engine) | render capa MENÚ (picoarch/frogui) | **6x diferencial**: 6w (GE off) = logo+batería SIN menú; 6x (GE on) = menú completo | **VALIDADO (6x diferencial)** |
| `check_adc1/check_adc5` (HC_CHECK_ADC) | batería/carga (driver_r36sx.so) | 6m ABI + 6x: icono batería visible (6w ya lo mostraba con CHECK_ADC=y) | **VALIDADO (6x PHYSICAL)** |
| `input/event0` (HC input) | navegación/botones | 6x: menú "navegable y funcional" | **VALIDADO (6x PHYSICAL)** |
| `/dev/dis` (display ioctl vendor) | ¿rotación/modo pantalla? | 6m ABI | PROBABLE — confirmar con DIAG6X (fds vivos) |
| `sndC0i2so/auddec` (audio HC→AVP) | sonido UI/cores | 6m ABI | PROBABLE — confirmar con DIAG6X |
| `mmz` (memoria multimedia compartida) | buffers AVP/AMPRPC | 6m ABI | PROBABLE — confirmar con DIAG6X |
| `persistentmem` (persistentmem-fs) | saves/settings UI | 6m ABI + SDK persistentmem.bin | PROBABLE — confirmar con DIAG6X |
| `standby` (power/sleep) | power management UI | 6m ABI | PROBABLE — confirmar con DIAG6X |
| `backlight` | brillo (setting light=75) | 6m ABI + setting.xml | PROBABLE — confirmar con DIAG6X |
| hwspinlock (HC_HWSPINLOCK) | AMPRPC AVP↔Linux | 6x diferencial (mismo test que GE) | **VALIDADO (6x diferencial)** |
| mounts: `/dev/mmcblk0p1` → `/media/mmc` + bind `/mnt/sdcard` + bind `/lib` | toda la UI (binarios/libs viven en SD) | 6l DIAG2 fábrica + 6x: la UI arranca desde la SD | **VALIDADO (6x PHYSICAL)** |
| initramfs: S41hcdaemon (`hcdaemon&`) + S99app (wait icube → bind → swap → icube.sh) | cadena de arranque del menú | 6w/6x: sin S41/S99 reales no hay menú; con ellos sí | **VALIDADO (6x diferencial)** |
| picoarch + cores/frogui_libretro.so | el MENÚ (frontend libretro) | 6m flujo: icube→rkgame→zhijack→picoarch | VALIDADO implícito (6x: menú) — confirmar proceso con DIAG6X |

## ABI /dev de driver_r36sx.so (6m, verificación con DIAG6X en curso)

`auddec backlight check_adc1 dis fb0 ge input/event0 mmz persistentmem sndC0i2so standby`

## Notas de arranque (evidencia 6x)

- El menú requiere el set COMPLETO de drivers vendor en el kernel: la capa icube (logo+batería) arrancó sin GE/hwspinlock, pero la capa picoarch (menú) NO.
- Config del kernel validado físicamente: **vendor baseline + CHECK_ADC + initramfs stock-parity CPIO CRUDO** (fragment `r36sx-v26.config.fragment`).
- La SD se monta en `/media/mmc` (mdev) y se bind-mounta a `/mnt/sdcard` Y `/lib` (los .so de la UI se cargan desde la SD — 6l).

## Pendiente Fase 6

1. DIAG6X on-device (fds vivos por proceso) → confirmar PROBABLEs + documentar el proceso exacto del menú.
2. Formalizar el contrato (qué debe garantizar todo kernel futuro de r36sx-v26 para que TreeFrogUI funcione).
3. Integra con docs/BOARD_PORT.md + HARDWARE_R36SX_V26.md.
