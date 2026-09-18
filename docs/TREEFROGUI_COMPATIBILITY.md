# docs/TREEFROGUI_COMPATIBILITY.md — Contrato TreeFrogUI

**Estado:** CERRADO (Fase 6 DONE, 2026-09-17) — contrato validado físicamente. Upstream: https://github.com/tzubertowski/TreeFrogUI
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
| `sndC0i2so/auddec` (audio HC→AVP) | sonido UI/cores | 6m ABI | **VALIDADO — AUDIO PHYSICAL PASS (9l, ADR-012)** |
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

## PROBABLEs confirmados con evidencia viva (diag8 7c-vs-fábrica)

- Los fds abiertos por proceso son IDÉNTICOS bajo stock y bajo kernel propio — la app-layer no distingue kernels.
- Input: pipeline `cubevol gpio → /tmp/joy_key` (sin evdev en ningún kernel — 6m/7b).
- Media (auddec/viddec/sndC0*): proxies AMPRPC → AVP. **CAUSA RAÍZ CONFIRMADA 2026-09-18 (ADR-012): drift ABI de sizeof entre binarios userspace de fábrica (Dic-2025) y headers UAPI del SDK (Jul-2024)** — el sizeof queda codificado en el número de ioctl y el switch del avp-proxy no matcheaba → `KSHM_WRITE_HDL_ACCESS` nunca se enviaba. AUDIO: FIXED + PHYSICAL PASS (9l, padding 24 B `audio_config`). VIDEO: fix desplegado (9m, padding 20 B `video_config`), test físico pendiente. Ver docs/experiments/2026-09-18_fase9m-video-abi-fix.md.

## CONTRATO (lo que todo kernel futuro r36sx-v26 debe garantizar)

1. Drivers Linux-puro: HC_GE, HC_HWSPINLOCK, HC_CHECK_ADC, fb (fb0/fb1), dw-mmc, input-poll (userspace cubevol), GPIO/mem.
2. Initramfs con la cadena S41hcdaemon (`hcdaemon&`) + S99app (wait media → binds /mnt/sdcard,/lib,/usr,/bin,/sbin → swap → icube.sh) — o equivalentes propios (Fase 8).
3. NO hardware-init de periféricos compartidos con el AVP sin entender el ownership (lección 6w→7e).
4. Para MEDIA completa: ABI proxy↔fábrica alineado por padding UAPI (ADR-012) — audio HECHO (9l), video en test (9m). Cualquier ioctl futuro que no matchee se diagnostica igual: amprpc debug on-device + scan `lui+ori` de los binarios de fábrica.

## Limitación conocida → RESUELTA (en verificación final)

Audio (9l PHYSICAL PASS) + video decode (9m desplegado, test pendiente) bajo kernel propio — la "limitación diferida" de Fase 6/7 era íntegramente el drift ABI (ADR-012).
