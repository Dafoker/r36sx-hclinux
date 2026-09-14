# r36sx-hclinux

**Construcción reproducible de una plataforma Linux/HCLinux para la consola R36SX V2.6 (HiChip HC16xx, MIPS).**

Objetivo: kernel propio, compatibilidad con AVP/HCRTOS del fabricante, TreeFrogUI estable, y eliminación progresiva de las limitaciones del firmware stock.

## Estado

| Fase | Descripción | Estado |
|------|-------------|--------|
| 0 | Bootstrap del repositorio | EN CURSO |
| 1 | Auditoría completa del SDK | PENDIENTE |
| 2 | Reproducir build vendor (baseline) | PENDIENTE |
| 3 | Identificar hardware R36SX V2.6 | PENDIENTE |
| 4 | Board propia r36sx_v26 | PENDIENTE |
| 5 | Primer kernel propio (4.4.186) | PENDIENTE |
| 6 | Contrato TreeFrogUI | PENDIENTE |
| 7 | Optimizaciones | PENDIENTE |
| 8 | Rootfs propio | PENDIENTE |
| 9 | Kernel 5.12.4 experimental | PENDIENTE |

## Fuente primaria (inmutable)

El SDK vendor vive en Windows y **NUNCA se modifica**:

- `D:\GitHub\KERNEL\hclinux-2024.02.y.2.tar.gz` (2.0 GiB)
- SHA256: `e3211b41f8d649c7d7838f7f19b8cca5cf30ba6cb1ff9545be6943845fbf8d5d`

Inventario completo: `manifests/SOURCES.sha256` · Documentación: `docs/SOURCE_INVENTORY.md`

## Reconstrucción desde cero

Requisitos: WSL2 (Ubuntu 24.04), git, gh autenticado como `ozkaoz`, acceso lectura a `D:\GitHub\KERNEL` vía `/mnt/d`.

```bash
git clone https://github.com/ozkaoz/r36sx-hclinux.git
cd r36sx-hclinux
./scripts/agent_preflight.sh
./scripts/verify_sources.sh
./scripts/prepare_sdk.sh          # extrae SDK a ~/work/r36sx-hclinux/sdk
./scripts/build_baseline.sh       # Fase 2: build vendor reproducible
./scripts/build_kernel.sh r36sx-v26
./scripts/verify_artifacts.sh
```

## Reglas operativas

- **WSL-only**: todo el desarrollo, builds, Git y GitHub desde WSL (`/mnt/d` = solo datos).
- **SDK inmutable**: los cambios viven aquí como patches/configs/boards, nunca en el SDK.
- **Evidencia > memoria > plan**: ver `AGENTS.md`.
- **Etiquetas de validación**: STATIC/HOST/BUILD/PACKAGING/EMULATED/PHYSICAL/CLEAN-INSTALL/DOWNLOAD-BACK PASS — nunca "DONE/WORKING".

## Documentación clave

| Documento | Contenido |
|-----------|-----------|
| [AGENTS.md](AGENTS.md) | Constitución permanente del proyecto |
| [CURRENT.md](CURRENT.md) | Snapshot operacional (caché, no historia) |
| [CONTEXT_MAP.md](CONTEXT_MAP.md) | Router: qué consultar por subsistema |
| [DECISIONS.md](DECISIONS.md) | Decisiones arquitectónicas durables (ADRs) |
| [docs/SOURCE_INVENTORY.md](docs/SOURCE_INVENTORY.md) | Inventario de fuentes + hashes |
| [docs/SDK_AUDIT.md](docs/SDK_AUDIT.md) | Auditoría del SDK (Fase 1) |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Fases y gates |

## Licencia

TBD en ADR — el SDK vendor es propietario (HiChip); este repo contiene únicamente patches/configs/scripts/documentación propios.
