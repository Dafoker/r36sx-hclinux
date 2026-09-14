# docs/BUILD.md — Cómo compilar

**Estado:** BOSQUEJO — comandos definitivos tras Fase 1 (auditoría SDK). Contrato: `docs/ai/BUILD_CONTRACT.md`.

## Prerequisitos

- WSL2 Ubuntu 24.04 (ADR-001) — git, gh, make, gcc, tar, patch, sha256sum, dtc, 7z.
- Acceso lectura: `/mnt/d/GitHub/KERNEL` (SDK inmutable, ADR-002).
- Espacio: el SDK extraído + builds puede requerir >10 GiB en `~/work`.

## Flujo

```bash
./scripts/agent_preflight.sh    # 1. entorno + git + SDK presentes
./scripts/verify_sources.sh     # 2. hashes OK vs manifests/SOURCES.sha256
./scripts/prepare_sdk.sh        # 3. extrae SDK → ~/work/r36sx-hclinux/sdk
./scripts/build_baseline.sh     # 4. (Fase 2) build vendor reproducible
```

Los comandos exactos del build vendor (defconfig, toolchain, invocación Buildroot) se determinan por evidencia en Fase 1 y se fijan aquí.

## Artefactos esperados (Fase 2)

vmlinux, vmlinux.bin, vmlinux.uImage, DTB, System.map, .config, rootfs image — con SHA256 en `out/<build>/BUILD_REPORT.md`.
