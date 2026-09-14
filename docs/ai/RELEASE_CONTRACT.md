# docs/ai/RELEASE_CONTRACT.md — Contrato de releases

**NO publicar ninguna release sin autorización explícita del usuario.** (Clase G)

## Qué es una release aquí

Firmware/installer/SD-image para R36SX V2.6 derivado de este proyecto, versionado y reproducible.

## Prerequisitos (todos obligatorios)

1. Artefacto con etiqueta PHYSICAL PASS (o mejor) registrada en `docs/experiments/`.
2. Procedencia completa: commit exacto, toolchain, config, SDK hash, script de build.
3. `manifests/` actualizado con SHA256 de todos los assets.
4. Rollback documentado (`docs/RECOVERY.md`): cómo volver a stock desde la release.
5. Revisión de seguridad: la release NO debe escribir bootloader/AVP sin autorización específica.
6. Autorización explícita del usuario para publicar.

## Proceso (cuando esté autorizado)

1. Tag anotado `vX.Y.Z` en el commit validado.
2. Assets subidos a GitHub Release (no a git): firmware images, SHA256SUMS, notas.
3. **DOWNLOAD-BACK PASS obligatorio**: re-descargar cada asset, verificar SHA256 == publicado, dejar registro.
4. Notas de release: qué incluye, qué NO (limitaciones), cómo instalar, cómo revertir, riesgos.

## Versionado

- `0.x` = fase experimental (nunca para uso general).
- `1.0` = primera CLEAN-INSTALL PHYSICAL PASS completa con TreeFrogUI funcional.
- SemVer a partir de 1.0.

## Contenido prohibido en releases

- Binarios vendor redistribuidos sin analizar licencia (SDK HiChip propietario).
- Secretos, tokens, datos del dispositivo del usuario.
