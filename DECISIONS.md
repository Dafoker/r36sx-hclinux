# DECISIONS.md — Decisiones arquitectónicas durables

Formato ADR. STATUS: ACTIVE | SUPERSEDED | DEPRECATED. No registrar aquí nada mutable (eso va a CURRENT.md).

---

## ADR-001 — Desarrollo WSL-only

- **DATE:** 2026-09-14
- **STATUS:** ACTIVE
- **SCOPE:** todo el proyecto
- **CONTEXT:** toolchains MIPS/Buildroot requieren Linux nativo; WSL2 Ubuntu 24.04 disponible con gh, gcc, make, dtc, 7z verificados; Windows solo aporta datos en `/mnt/d`.
- **DECISION:** todo desarrollo, builds, Git/GitHub y generación de artefactos se ejecuta desde WSL. Rutas Windows son solo fuentes de datos. Literal en AGENTS.md §0.
- **RATIONALE:** permisos Unix, symlinks, velocidad de filesystem, compatibilidad Buildroot/toolchain, cuenta `gh` ya configurada.
- **CONSEQUENCES:** todo script es bash; el repo vive en filesystem nativo WSL (`~/projects/r36sx-hclinux`), nunca en `/mnt/d`.
- **EVIDENCE:** preflight 2026-09-14 (WSL2 kernel 6.18.33.2, Ubuntu 24.04.4, git 2.43, gh 2.96, gcc 13.3, make 4.3, dtc, 7z presentes).
- **RELATED:** AGENTS.md §0, docs/ai/BUILD_CONTRACT.md

## ADR-002 — SDK vendor inmutable como fuente de verdad

- **DATE:** 2026-09-14
- **STATUS:** ACTIVE
- **SCOPE:** gestión de fuentes
- **CONTEXT:** `/mnt/d/GitHub/KERNEL` contiene el SDK HCLinux completo (2.0 GiB) + manuales + patches + hcdrivers; es evidencia vendor irrepetible.
- **DECISION:** el SDK y todos los archivos de `/mnt/d/GitHub/KERNEL` se tratan como evidencia inmutable: nunca se modifican ni se desarrolla dentro. Workspace derivado en `~/work/r36sx-hclinux/{sdk,build,cache}`. Los cambios propios viven en este repo como patches/configs/boards/overlays.
- **RATIONALE:** reconstrucción garantizada desde SDK ORIGINAL + este repo; trazabilidad de evidencia; el repo previo homónimo murió por contaminar workspace y fuentes.
- **CONSEQUENCES:** `prepare_sdk.sh` siempre extrae desde el tar original verificado por SHA256; artefactos grandes viven en `out/` (ignorado).
- **EVIDENCE:** SHA256 SDK `e3211b41...45fbf8d5d` (manifests/SOURCES.sha256); inventario completo docs/SOURCE_INVENTORY.md.
- **RELATED:** AGENTS.md §4, scripts/prepare_sdk.sh, scripts/verify_sources.sh

## ADR-003 — Reinicio limpio sin herencia técnica

- **DATE:** 2026-09-14
- **STATUS:** ACTIVE
- **SCOPE:** historia del proyecto
- **CONTEXT:** existió un repo `r36sx-hclinux` previo (WSL local + remoto GitHub) eliminado el 2026-09-14; su historial completo quedó preservado en bundles.
- **DECISION:** este proyecto arranca desde CERO sin reutilizar código, docs, configs ni historia del repo previo. El bundle preservado es solo red de seguridad, no antecedente técnico. Decisión explícita del usuario: "no partas de ningún repo previo", "todo el trabajo debe ser nuevo".
- **RATIONALE:** partir de cero evita arrastrar decisiones y errores no re-evidenciados; todo lo que se necesite debe re-derivarse del SDK con evidencia propia.
- **CONSEQUENCES:** cualquier afirmación técnica de este repo cita evidencia nueva de `/mnt/d/GitHub/KERNEL` o del SDK extraído. Bundles legacy: `Temp\opencode\bundles-20260914\` (solo recuperación).
- **EVIDENCE:** bundles `r36sx-hclinux.bundle` + `r36sx-hclinux-legacy-unpushed-255f7cd-20260914.bundle` (historial completo verificado); repos remotos ozkaoz listados (sin r36sx-hclinux).
- **RELATED:** CURRENT.md KNOWN-GOOD STATE

## ADR-004 — Linux 4.4.186 como baseline; 5.12.4 experimental diferido

- **DATE:** 2026-09-14
- **STATUS:** ACTIVE (pendiente de confirmación por auditoría SDK — Fase 1)
- **SCOPE:** kernel
- **CONTEXT:** `/mnt/d/GitHub/KERNEL` contiene sets de patches vendor para linux-4.4.186 (41 patches) y linux-5.12.4 (21 patches); el requisito del proyecto fija 4.4.186 como baseline si el SDK lo confirma.
- **DECISION:** baseline = Linux 4.4.186. La línea 5.12.4 se abre solo cuando 4.4.186 sea known-good físico. 4.4.186 = GOLDEN; 5.12.4 = EXPERIMENTAL.
- **RATIONALE:** minimizar variables; el firmware stock del R36SX V2.6 debe ser el punto de compatibilidad inicial.
- **CONSEQUENCES:** Fase 9 diferida; cada regresión 5.12 se compara contra 4.4.
- **EVIDENCE:** directorios `linux-4.4.186/` (41 .patch) y `linux-5.12.4/` (21 .patch) en /mnt/d/GitHub/KERNEL — verificación del contenido del SDK tar pendiente en Fase 1.
- **RELATED:** docs/SDK_AUDIT.md (pendiente), docs/ROADMAP.md

## ADR-005 — AVP/HCRTOS preservado durante baseline

- **DATE:** 2026-09-14
- **STATUS:** ACTIVE
- **SCOPE:** boot/AVP
- **CONTEXT:** el firmware stock ejecuta HCRTOS/AVP en un segundo núcleo con AMPRPC como puente; audio/DDR/display dependen de él (hipótesis a confirmar en Fase 1).
- **DECISION:** durante Fases 0–6 el AVP se preserva intacto: no se modifica bootloader, DDR init, ni AVP. Un solo cambio principal por experimento.
- **RATIONALE:** riesgo de brick y pérdida de funciones críticas; "una variable por experimento".
- **CONSEQUENCES:** clase de cambio D (boot/AVP) requiere autorización hardware explícita.
- **EVIDENCE:** hcdrivers/amprpc/, hcdrivers/avp-proxy/ presentes en /mnt/d/GitHub/KERNEL (confirmación del mecanismo completo: Fase 1).
- **RELATED:** AGENTS.md §5, §7; docs/ai/HARDWARE_SAFETY.md

## ADR-006 — Repositorio GitHub público

- **DATE:** 2026-09-14
- **STATUS:** ACTIVE
- **SCOPE:** repositorio
- **CONTEXT:** proyecto open-source de ingeniería reproducible; nombre `r36sx-hclinux` libre en GitHub (verificado via gh).
- **DECISION:** repo público `ozkaoz/r36sx-hclinux`, rama `main`, español como lengua de trabajo, inglés en README público.
- **RATIONALE:** visibilidad, journal técnico autoritativo, referencia a referencias públicas (ArkOS, TreeFrogUI, R36S V2.6 Wiki).
- **CONSEQUENCES:** sin binarios vendor gigantes en git; artefactos vía manifests + releases futuros.
- **EVIDENCE:** `gh repo view ozkaoz/r36sx-hclinux` → not found (2026-09-14); lista de repos ozkaoz sin conflicto.
- **RELATED:** docs/ai/RELEASE_CONTRACT.md

## ADR-007 — d3100_v20 como vendor baseline provisional (NO identidad final de board)

- **DATE:** 2026-09-14
- **STATUS:** ACTIVE
- **SCOPE:** build vendor de referencia
- **CONTEXT:** Fase 2 requería reproducir un build vendor conocido. El manual §16.1 usa `hichip_hc16xx_db_d3100_v20_defconfig` como ejemplo canónico; la evidencia física del DTB stock de la consola revela `board label = "hc1600a@dbE3100v20"` (E3100 — board inexistente en el SDK).
- **DECISION:** `d3100_v20` es el **VENDOR BASELINE CANDIDATE (CONFIDENCE: HIGH)** para reproducir el pipeline del fabricante. **FINAL BOARD IDENTITY: NOT YET PROVEN** — la board real es familia E3100 v20; los artefactos d3100_v20 NO se consideran compatibles con la consola real (memoria/display divergen) y **jamás se flashean** en la R36SX.
- **RATIONALE:** el pipeline (toolchain, patches, DTS plumbing, post-build) es común a la familia; solo la board difiere. El vermagic stock del fabricante usa el mismo toolchain Codescape 2018.09-02 que nuestro build → validación fuerte del pipeline.
- **CONSEQUENCES:** Fase 4 (board propia `r36sx-v26`) es obligatoria y deriva del DTB stock decompilado; todo build d3100_v20 queda etiquetado solo como referencia de pipeline.
- **EVIDENCE:** docs/experiments/2026-09-14_vendor-baseline-d3100-v20.md; docs/HARDWARE_R36SX_V26.md; DTB stock sha `1258f1eb...`.
- **RELATED:** ADR-003, ADR-004, docs/SDK_AUDIT.md

## ADR-008 — Baseline kernel-only (HCBOOT/AVP deshabilitados en build)

- **DATE:** 2026-09-14
- **STATUS:** ACTIVE
- **SCOPE:** alcance del build baseline
- **CONTEXT:** compilar hcboot/AVP requiere toolchain bare-metal `mips32-mti-elf` (Codescape 2019.09-03-2) distribuido solo vía GitLab privado de HiChip (requiere login; `/opt/mips32-mti-elf` local es symlink roto a directorio inexistente). En la consola real, AVP/bootloader stock se preservan siempre (ADR-005): no los reemplazamos.
- **DECISION:** el baseline (y builds de Fases 4-5) compilan **kernel + DTB + rootfs** con `BR2_TARGET_HCBOOT` y `BR2_PACKAGE_AVP` off en el .config del output (defconfig vendor intacto). Los artefactos de flasheo que requieren bootloader.bin quedan fuera de alcance hasta obtener el bare-metal o decisión explícita del usuario.
- **RATIONALE:** una variable por experimento; el AVP stock ya funciona en el dispositivo; sin bare-metal no hay alternativa honesta.
- **CONSEQUENCES:** `target-post-image` fallará al final (bootloader.bin ausente) — error esperado y documentado; los artefactos del kernel se generan antes. Si en el futuro se obtiene el bare-metal, reevaluar.
- **EVIDENCE:** error build literal: `Toolchain /opt/mips32-mti-elf/2019.09-03-2/bin/mips-mti-elf-gcc not exist`; GitLab HiChip pide login (HTML 8331B); experimento 2026-09-14.
- **RELATED:** ADR-005, docs/BUILD.md
