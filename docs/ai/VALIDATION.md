# docs/ai/VALIDATION.md — Contrato de validación

**Regla:** una afirmación sin evidencia es una hipótesis. Toda etiqueta requiere evidencia registrada.

## Etiquetas (uso exclusivo)

| Etiqueta | Significado | Evidencia mínima |
|---|---|---|
| STATIC PASS | Revisión estática / análisis de archivos | Ruta de archivo + criterio |
| HOST PASS | Tests o verificación en host WSL | Output de comando + fecha |
| BUILD PASS | Compilación completa limpia | Log + hashes de artefactos |
| PACKAGING PASS | Empaquetado correcto (SD image, uImage, DTB) | Hash + estructura verificada |
| EMULATED PASS | Validado en emulación (QEMU si existe para HC16xx) | Log + config emulador |
| PHYSICAL PASS | Probado en R36SX V2.6 real | Log/foto/vídeo del dispositivo + fecha |
| CLEAN-INSTALL PHYSICAL PASS | Instalación limpia desde SD formateada | Procedimiento completo documentado |
| DOWNLOAD-BACK PASS | Asset de release re-descargado y verificado | SHA256 local == publicado |

**Prohibido:** DONE, VERIFIED, WORKING, "funciona". HOST PASS ≠ PHYSICAL PASS. "Compila" ≠ "arranca en R36SX".

## Gates por clase de cambio (AGENTS.md §7)

- **A** (contexto/docs): STATIC PASS — consistencia AGENTS/CURRENT/CONTEXT_MAP + git limpio.
- **B** (scripts/tools host): HOST PASS — shellcheck limpio (o justificado) + ejecución exitosa read-only.
- **C** (kernel/BSP/DTS): BUILD PASS — kernel build + DTB build + `dtc -I dtb -O dts` round-trip donde aplique + hashes registrados.
- **D** (boot/AVP): BUILD PASS + **autorización hardware explícita del usuario** antes de cualquier flasheo.
- **E** (rootfs/Buildroot): BUILD PASS del rootfs + verificación de overlays + hashes.
- **F** (deploy SD): **autorización explícita del usuario** + checklist HARDWARE_SAFETY + PACKAGING PASS.
- **G** (release): artefacto validado + DOWNLOAD-BACK PASS + autorización explícita.

## Registro de evidencia

- Builds: `out/<nombre-build>/BUILD_REPORT.md` (fuera de git) + resumen y hashes en `docs/experiments/` (en git).
- Experimentos: plantilla obligatoria de `docs/ROADMAP.md` §formato.
- Nunca borrar un experimento fallido — se documenta igual (resultado negativo = evidencia).

## Matriz mínima de regresión (se construye en Fase 2)

1. Build vendor reproducible byte-a-byte (o determinado por qué no).
2. Boot stock SD → boot con kernel propio (Fase 5): comparación de particiones/archivos.
3. TreeFrogUI: arranque + navegación + lanzamiento de core (Fase 6).
