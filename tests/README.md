# tests/ — Tests host (nivel HOST PASS)

Estado: vacío por diseño en bootstrap. Primeros tests previstos:
- test_verify_sources.bats (o bash simple): manifest correcto, detección de mismatch.
- test_preflight: agent_preflight.sh read-only y exit codes.
Reglas: docs/ai/VALIDATION.md. Los tests NO tocan /mnt/d ni dispositivos.
