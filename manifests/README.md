# manifests — Manifiestos de fuentes y artefactos

## SOURCES.sha256

Hashes de las fuentes vendor inmutables (`/mnt/d/GitHub/KERNEL`, ADR-002). Verificar con `./scripts/verify_sources.sh` antes de cualquier build. El SDK nunca se modifica.

## Reglas

- Artefactos de build NO van a git: viven en `out/` (ignorado) con su `BUILD_REPORT.md` + hashes.
- Los manifests de artefactos (hashes resumidos + procedencia) SÍ van a git cuando existan builds.
- Toda fuente nueva que entre al proyecto se inventaría y hashea aquí antes de usarse.
