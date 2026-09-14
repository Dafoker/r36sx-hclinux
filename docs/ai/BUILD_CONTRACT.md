# docs/ai/BUILD_CONTRACT.md — Contrato de build

**Toda compilación es desde WSL, desde fuentes verificadas, con hashes registrados.**

## Entorno (ADR-001)

- WSL2 Ubuntu 24.04 (`/proc/version` contiene microsoft).
- Workspace: `~/work/r36sx-hclinux/` — `sdk/` (extracción del tar), `build/` (builds), `cache/` (descargas).
- Repo: `~/projects/r36sx-hclinux`. Artefactos: `out/` (ignorado por git).
- Prohibido compilar bajo `/mnt/d` salvo justificación de rendimiento documentada (y entonces: solo lectura de fuentes).

## Cadena de scripts (contrato de reproducibilidad §37 del requisito)

```bash
./scripts/agent_preflight.sh     # read-only: entorno, git, gh, SDK, hash
./scripts/verify_sources.sh      # SHA256 fuentes vs manifests/SOURCES.sha256
./scripts/prepare_sdk.sh         # extrae tar SDK verificado → ~/work/r36sx-hclinux/sdk
./scripts/build_baseline.sh      # Fase 2: reproducir build vendor sin modificaciones
./scripts/build_kernel.sh <board># Fase 5: kernel propio (board r36sx-v26)
./scripts/build_dtb.sh <board>   # DTB propio
./scripts/collect_artifacts.sh    # copia + hash de artefactos → out/<name>/
./scripts/verify_artifacts.sh     # valida artefactos esperados + hashes + reporte
```

## Invariantes de todo build

1. **Fuente verificada antes de extraer**: `verify_sources.sh` PASS es prerequisito de `prepare_sdk.sh`.
2. **Sin modificaciones vendor**: en Fase 2 el build usa defconfig/scripts vendor tal cual; cualquier desviación se documenta.
3. **Un experimento = una variable** (AGENTS.md §7).
4. **Procedencia capturada**: toolchain real usado (path + versión), kernel version, config, fecha, host — todo al BUILD_REPORT.
5. **Artefactos hasheados**: vmlinux, vmlinux.bin, vmlinux.uImage, DTB, System.map, .config, rootfs — SHA256 al reporte.
6. **Logs resumidos en git; binarios en out/**: el repo guarda manifests y conclusiones, no blobs.
7. **Resultado inesperado → volver al SDK** (AGENTS.md §3), no "arreglar" a ciegas.

## Reporte mínimo por build (out/<name>/BUILD_REPORT.md)

```
DATE / HOST (uname -a) / TOOLCHAIN (path, gcc --version)
SOURCE (qué se compiló, de dónde, hash)
COMMANDS (exactas ejecutadas)
RESULT (PASS/FAIL + etiqueta de VALIDATION.md)
ARTIFACTS (path, tamaño, SHA256)
DEVIATIONS (desviaciones vs vendor, si las hay)
```
