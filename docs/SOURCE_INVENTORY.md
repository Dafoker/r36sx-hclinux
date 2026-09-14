# docs/SOURCE_INVENTORY.md — Inventario de fuentes externas

**Fecha:** 2026-09-14 · **Método:** `find` + `sha256sum` desde WSL · **Estado:** STATIC PASS (inventario físico, no asumido)
Hashes de verificación: `manifests/SOURCES.sha256` · Regla: TODO en `/mnt/d/GitHub/KERNEL` es **evidencia inmutable** (ADR-002).

## Top-level `/mnt/d/GitHub/KERNEL`

| Archivo | Tamaño | SHA256 |
|---|---|---|
| `hclinux-2024.02.y.2.tar.gz` | 2,116,519,773 (2.0 GiB) | `e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d` |
| `hclinux_user_manual.pdf` | 4,225,431 | `18e505ea1ba0fcb739e4ae276ed6c0a6f33ffc8db38781d8e7a7e269649435f7` |
| `hclinux_user_manual_es.pdf` | 201,428 | `8286144d686127896d8430e2c4ac9cc077b998e4eb2bdb3809e0ad88ae63c112` |
| `HCLINUX_OPENCODE_GUIDE.md` | — | `ee5cff0d7b6463541dfafa962685dd4800444e5e050ec37a5aaa67cd0e3f6b2c` |
| `HCLINUX_MANUAL_MACHINE_READABLE.md` | — | `5002c10216aa8cca24a84b032191002c27073925280aff99c2f7fa91c318247a` |
| `hcdrivers.7z` | 507,596 | `da146baf0fbd2e6a2d6e114d7ca71ecafbb0f8d1cdbf6e92bede20debccc5f77` |
| `patches.7z` | 312,832 | `fa154f64584768429facc27d0894c97ad59e39b3ac87e2343aa992fbc01d0414` |

**Nota:** el requisito original citaba `hclinux-2024.02.y.2.tar`; el archivo físico real es **`.tar.gz`** — evidencia corrige al plan (AGENTS.md §2).

### Referencias derivadas del manual (añadidas 2026-09-14, post-bootstrap)

- `HCLINUX_OPENCODE_GUIDE.md` — referencia técnica orientada a agentes, derivada del manual vendor (107 págs). Incluye regla de autoridad: si el guía y el árbol SDK discrepan, **el árbol SDK manda**.
- `HCLINUX_MANUAL_MACHINE_READABLE.md` — manual vendor original (chino) en Markdown navegable con marcadores de página PDF.

Ambas han sido **cross-checkeadas contra el SDK real** (ver `docs/SDK_AUDIT.md` §cross-checks): direcciones, boot chain, toolchains y tabla de soporte kernel **CONFIRMADAS**; único PARTIAL: tamaño del bloque DDR-init (manual dice 4 KiB; archivo real `.abs` = 12,288 B = 12 KiB).

## Directorios

| Directorio | Contenido | Volumen |
|---|---|---|
| `linux-4.4.186/` | Patches vendor 0001–0055 para kernel 4.4.186 + árbol `yaffs2/` | 41 .patch + yaffs2 |
| `linux-5.12.4/` | Patches vendor 0001–0039 para kernel 5.12.4 | 21 .patch |
| `hcdrivers/` | Drivers HiChip: amprpc, avp-proxy, fbdev, gpio, i2c, lvds, mmz, musb, nand (4.x/5.x), persistentmem, pinctrl, pwm, sdio, spi, watchdog, virtuart, kshm, kumsgq, ge, hwspinlock, rc, stk8baxx... | 174 archivos |
| `work/` | **Trabajo previo del usuario** (no vendor): verification/, finalized/, legacy-treefrog-linux/ | docs + sandbox — clasificar en Fase 1, no mezclar con vendor |

## Archivos vendor relevantes destacados (hash completo en manifests/)

- `linux-4.4.186/0001-add-hichip-hc16xx-arch-support.patch` — soporte arch HC16xx (confirma línea 4.4).
- `hcdrivers/amprpc/*`, `hcdrivers/avp-proxy/*` — mecanismo AMPRPC/AVP (base ADR-005).
- `hcdrivers/nand/nand-hc-4.x.c` + `nand-hc-5.x.c` — soporte NAND por versión de kernel (evidencia de doble línea).
- `hcdrivers/fbdev/hcfb.c` (40 KiB) — framebuffer vendor (relevante TreeFrogUI).
- `hcdrivers/mmz/mmz.c` — memoria MMZ (hipótesis §15 Linux/AVP/MMZ).

## Clasificación provisional (a confirmar en Fase 1 con el tar)

- **VENDOR SDK:** `hclinux-2024.02.y.2.tar.gz` (el archivo central), `hcdrivers.7z`, `patches.7z`, ambos PDF, `linux-*/` y `hcdrivers/` extraídos.
- **TRABAJO PREVIO DEL USUARIO (no vendor):** `work/` — tratar como referencia separada, no como fuente vendor. Su contenido no es inmutable-contracto pero tampoco se modifica sin clasificar.
- Los `.7z` y los directorios ya extraídos pueden solapar contenido → comparar por hash en Fase 1 (pendiente).

## Pendientes Fase 1

1. Contenido del tar SDK (top-level, versiones Buildroot/kernel, toolchains incluidos).
2. Diferencias `hcdrivers.7z` vs `hcdrivers/` y `patches.7z` vs `linux-*/` (hash por archivo).
3. Extraer texto de manuales PDF (herramientas: `pdftotext` si disponible).
4. Clasificar `work/` en vendor vs previo.
