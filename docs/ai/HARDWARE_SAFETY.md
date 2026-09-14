# docs/ai/HARDWARE_SAFETY.md — Contrato de seguridad de hardware

**Lectura OBLIGATORIA antes de cualquier clase de cambio D o F.**

## Principio

El R36SX V2.6 contiene NOR/NAND flash con bootloader y firmware irrepetibles del fabricante. Un write incorrecto = brick. **No existe unbrick garantizado.**

## Prohibido sin autorización explícita del usuario (por escrito, en el chat)

- `dd` a cualquier dispositivo de bloque.
- `mkfs` a cualquier dispositivo.
- Flash tools vendor (cualquier cosa que escriba NOR/NAND/eMMC).
- Escribir el área de bootloader / DDR init / particiones críticas.
- `rm -rf` / `git reset --hard` / `git clean -fd` sobre objetivos no verificados (también en host).

## Protocolo de escritura de SD (checklist completo)

1. Identificar el dispositivo: `lsblk -o NAME,SIZE,MODEL,MOUNTPOINTS` y `sudo fdisk -l` (pedir al usuario si hace falta sudo).
2. Mostrar la información al usuario: tamaño, modelo, particiones, mounts.
3. Confirmar que NO es el disco del sistema ni la SD golden.
4. Pedir autorización explícita → esperar confirmación.
5. Solo entonces: desmontar particiones del dispositivo, verificar de nuevo el nodo (`/dev/sdX` NO cambia de letra), escribir, `sync`, verificar hash del bloque escrito si aplica.

## SD golden recovery

- Toda SD stock/backup original se clasifica **golden** — solo lectura, jamás escribirle.
- Los backups de SD del usuario están en `D:\R36S\PORT LPTRACKER\BACKUPS\` y `D:\R36SX\` — **irrepetibles, no eliminar** (contrato del mapa maestro del disco).

## Clasificación de riesgo por operación

| Operación | Riesgo | Gate |
|---|---|---|
| Compilar en host | Ninguno | BUILD PASS |
| Extraer SDK, leer archivos | Ninguno | — |
| Escribir archivo a SD de datos (reemplazo kernel en partición de datos) | Medio | Autorización + checklist |
| Flashear bootloader / DDR / AVP | **ALTO — brick** | Prohibido hasta Fase avanzada + autorización explícita |
| Desmontaje / hardware físico | Alto | Solo el usuario |

## Ante cualquier duda

STOP (AGENTS.md §10): reportar estado, razón, comandos exactos, resultado esperado, datos que debe devolver el usuario.
