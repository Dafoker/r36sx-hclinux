# docs/PATCH_PROVENANCE.md — Auditoría de patches del kernel (Fase 2.5)

**Estado:** COMPLETADA 2026-09-14 · **PATCH PROVENANCE: PASS**
**Regla (AGENTS.md §14):** "Presence of a patch does not prove it was applied" — la prueba es el patch log + árbol resultante.

## 1. Conteos RECONCILIADOS (antes ambiguos: "45 / 41+21")

| Set | Conte | Naturaleza | Rol en build 4.4.186 |
|---|---|---|---|
| `SDK patches/linux-4.4.186/*.patch` | **41** | HiChip kernel patches (0001–0055, numeración con huecos) | **APLICADOS** (todos) |
| `SDK patches/linux-4.4.186/yaffs2/` | overlay (~60 archivos) | Árbol yaffs2 + `patch-ker.sh` (script de integración) | **INYECTADO** (no es .patch; agrega fs/yaffs2 + actualiza fs/Kconfig/Makefile) |
| `SDK patches/linux-5.12.4/*.patch` | 21 | HiChip patches para línea 5.12 | NO USADOS por baseline (4.4.186); referencia |
| `SDK buildroot/linux/*.conditional` | 1 | Patch del package Buildroot (timeconst.pl) | Framework Buildroot, no HiChip |
| `SDK patches/{busybox,exfat,ffmpeg,libusb}` | 4 | Package patches (BR2_GLOBAL_PATCH_DIR) | Aplicados a sus packages, no al kernel |
| `D:\GitHub\KERNEL\linux-4.4.186\` | 41 | **Copia externa byte-idéntica** del set SDK | VERIFIED IDENTICAL (no se aplica aparte) |
| `D:\GitHub\KERNEL\linux-5.12.4\` | 21 | **Copia externa byte-idéntica** | idem |
| `D:\GitHub\KERNEL\patches.7z` | 62 | Ambos sets (41+21) + yaffs2 en un 7z | Cópia de distribución; nada nuevo |

**El "45" de la iteración anterior era una descripción imprecisa** ("41 patches + yaffs2 + redondeo"): el número exacto de `.patch` aplicados al kernel es **41**; yaffs2 es un overlay inyectado por script (mecanismo distinto, §3); el resto de parcheo del rootfs es de packages, no del kernel. No existe ningún patch #42–45.

## 2. Mecanismo REAL de aplicación (derivado del código + probado dinámicamente)

Config: `BR2_GLOBAL_PATCH_DIR="$(BR2_EXTERNAL_HCLINUX_PATH)/patches"` (defconfig:124) + `BR2_LINUX_KERNEL_PATCH=""` (318) → los 41 llegan por GLOBAL_PATCH_DIR, no por LINUX_KERNEL_PATCH.

```
linux-4.4.186 pristine (kernel.org, descargado a build/)
  ↓ POST_EXTRACT: LINUX_PREPARE_PATCHES_FOR_VERSION (linux-ext-prepare-patch-as-per-version.mk)
      ln -sf linux-4.4.186 patches/linux        ← selecciona el set según LINUX_VERSION
  ↓ PRE_PATCH: LINUX_PATCH_HICHIP_DRIVERS (linux-ext-patch-hichip-driver.mk)
      1. rsync -au SOURCE/linux-drivers/ → $(LINUX_DIR)   ← INYECCIÓN BSP (antes de patches)
      2. mkdir dts/include + ln -sf uapi (2 symlinks)
      3. cd patches/linux/yaffs2 && ./patch-ker.sh c m $(LINUX_DIR)  ← yaffs2 integrado
  ↓ APPLY_PATCHES (framework Buildroot support/scripts/apply-patches.sh sobre patches/linux)
      41 × "Applying NNNN-*.patch using patch"  (orden numérico estricto)
  ↓ PRE_BUILD (2ª pasada del mismo hook, rsync idempotente -au)
      + LINUX_PHYSICAL_START_FROM_DTS (fixup-load-addr)
  ↓ config → DTS → build → post-build (gzip+mkimage)
```

**Orden confirmado EMPÍRICAMENTE** (log V=1 de `make linux-patch` en output aislado `~/work/r36sx-hclinux/patch-audit/`, `logs/linux-patch-v1.log`, 221 líneas): rsync en línea 27 → yaffs2 patch-ker.sh en línea 32 → los 41 `Applying` en orden → `touch .stamp_patched`. El rsync es ANTES de los patches (corrige cualquier interpretación contraria; coincide con PIPELINE_OBSERVED del usuario y con la lógica PRE_PATCH_HOOKS).

## 3. SOURCE/linux-drivers: inyección, NO patch (§7)

- **Hook exacto:** `LINUX_PATCH_HICHIP_DRIVERS` en `linux/linux-ext-patch-hichip-driver.mk` (líneas 1–12), registrado en `LINUX_PRE_PATCH_HOOKS` **y** `LINUX_PRE_BUILD_HOOKS` (2 pasadas rsync `-au` idempotentes) — NO en `LINUX_POST_PATCH_HOOKS`.
- **Momento:** tras extract (POST_EXTRACT crea el symlink del set) y ANTES del patch framework (PRE_PATCH); segunda pasada antes del build.
- **Source→Dest:** `SOURCE/linux-drivers/` → raíz del kernel `build/linux-4.4.186/` (mezcla `arch/mips/hc16xx/` (9 archivos: board.c, irq.c, time.c, serial.c, prom.c/h, init.c, cmdline.c + Makefile/Platform), `arch/mips/include/asm/mach-hc16xx/` (spaces.h, kernel-entry-init.h, dma-coherence.h), `drivers/clk/hc16xx/`, `drivers/clocksource/timer-hc16xx.c`, `drivers/hcdrivers/` (33 componentes: amprpc, avp-proxy, fbdev, gpio, i2c, lvds, mmz, musb, nand, persistentmem, pinctrl, pwm, sdio, spi(-sf), watchdog, virtuart, kshm, kumsgq, ge, hwspinlock...), `include/uapi/hcuapi/`).
- **Distinción clave:** los patches solo CABLEAN (0001 añade `platforms += hc16xx` + `config HICHIP_HC16XX`; 0007 añade `obj-hcdrivers` al Makefile); el CÓDIGO BSP llega exclusivamente por rsync. **"Patches + linux-drivers" son mecanismos distintos, en ese orden.**

## 4. Aplicación dinámica — PRUEBA (§5)

Output aislado `patch-audit/` (defconfig vendor idéntico + desviaciones documentadas ADR-007/008; SDK maestro intacto):

```bash
make O=~/work/r36sx-hclinux/patch-audit BR2_EXTERNAL=... hichip_hc16xx_db_d3100_v20_defconfig
make O=... V=1 linux-patch     # EXIT 0
```

- **41/41 `Applying NNNN-*.patch using patch:`** en orden 0001→0055 (log completo conservado: `~/work/r36sx-hclinux/logs/linux-patch-v1.log`).
- `.stamp_patched` creado (junto a `.stamp_downloaded`/`.stamp_extracted`).
- NOTA: `make help` del SDK no lista `linux-patch` (solo menuconfig/savedefconfig/update-defconfig), pero el target existe en la infraestructura pkg de Buildroot y funciona.

## 5. Verificación del árbol patched — hunks/símbolos (§6)

| PATCH | SHA256(12) | Evidencia en árbol | FOUND |
|---|---|---|---|
| 0001 arch support | `89d69a3de8bc` | `arch/mips/Kbuild.platforms` contiene `platforms += hc16xx`; `Kconfig` tiene `config HICHIP_HC16XX` | **YES** |
| 0002 pinctrl fix | `bcb52c4bad45` | modifica `drivers/pinctrl/{core.c,pinmux.c}` (aplicado en log; el driver `pinctrl-hc16xx.c` vive en `drivers/hcdrivers/pinctrl/` por rsync) | **YES** (log+árbol) |
| 0003 r4k DMA cache | `91ed94b6c1c2` | símbolos DMA en `arch/mips/mm/` | **YES** |
| 0004 UART TX hang | `c22bc55e24cc` | `drivers/tty/serial` | **YES** |
| 0007 hcdrivers | `fd6104b6178f` | `drivers/Makefile` `obj-$(...) hcdrivers` + árbol `drivers/hcdrivers/` completo | **YES** |
| 0008 musb | `9582a5b2ffca` | `drivers/usb/musb` hcusb | **YES** |
| 0046 mtdblock skip bbt | `4b19a0828343` | `drivers/mtd` | **YES** |

Artefactos del rsync verificados en árbol: `arch/mips/hc16xx/` (10 archivos), `drivers/hcdrivers/` (33 subdirs), `fs/yaffs2/` integrado (`fs/Kconfig` referenciando yaffs).

## 6. Dry-run / reverse (§9 — evidencia complementaria)

Sobre el árbol ya parcheado: `patch --dry-run -p1 < 0001...` y `0055...` → ambos **"Reversed (or previously applied) patch detected!"** → ya aplicados (coherente con el log). Advertencia metodológica: dry-run fallido NO sería prueba de no-aplicación (hunks posteriores pueden solapar); la evidencia primaria es el patch log + orden + árbol resultante (arriba).

## 7. Relación con D:\GitHub\KERNEL (§8 — regla del usuario)

Cruce SHA256 completo:

- **41/41 (linux-4.4.186) y 21/21 (linux-5.12.4) BYTE-IDÉNTICOS** entre `D:\GitHub\KERNEL\linux-*` y `SDK patches/linux-*` (diff de hashes: vacío).
- `patches.7z` (62 .patch) = los dos sets juntos — **nada nuevo**.
- `hcdrivers.7z` = copia de `drivers/hcdrivers` (ya presente en SDK vía SOURCE/linux-drivers).

```
EXTERNAL COPY: VERIFIED IDENTICAL (41+21 byte-idénticos)
ACTIVE BUILD SOURCE: SDK patches/linux-4.4.186 (vía BR2_GLOBAL_PATCH_DIR)
DOUBLE APPLICATION: NOT REQUIRED — no se aplican los externos aparte
EXTERNAL-ONLY PATCHES: NINGUNO (0 patches en D:\ sin contraparte SDK)
```

## 8. Reproducibilidad tras el audit (§10)

El `dtb.bin` del baseline (iter. 3) es **byte-idéntico** al del baseline previo del usuario (sha `254522d5...`) — pipeline determinista en DTB. `vmlinux.bin` mismo tamaño exacto; SHA256 difiere únicamente por metadatos de build embebidos (vermagic `user@host` + timestamp en `compile.h` — documentado, no ocultado). El árbol del patch-audit replica exactamente los stamps/orden del baseline → patch pipeline reproducible.

## Veredicto

```
KERNEL 4.4.186 PATCHSET:       EXACT INVENTORY CONFIRMED — 41 .patch aplicados (0001→0055)
PATCH ORDER:                   CONFIRMED — rsync linux-drivers → yaffs2 → 41 patches (log V=1)
PATCH APPLICATION:             PASS — 41/41 Applying + .stamp_patched + hunks en árbol
PATCH LOG:                     ~/work/r36sx-hclinux/logs/linux-patch-v1.log (221 líneas)
PATCH STAMP:                   .stamp_patched presente (baseline + audit aislado)
EXTERNAL D:\ PATCH COUNT:      41 (4.4.186) + 21 (5.12.4) + 7z(62)
IDENTICAL TO SDK:              62/62 byte-idénticos
EXTERNAL-ONLY:                 0
DOUBLE-APPLIED:                NO (nunca se aplicaron aparte)
SOURCE/linux-drivers:          INYECCIÓN por rsync (PRE_PATCH + PRE_BUILD), NO patch

PATCH PROVENANCE: PASS
```
