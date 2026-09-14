# Makefile r36sx-hclinux — fachada de los scripts (todo via scripts/*.sh, WSL-only)
.PHONY: preflight verify prepare baseline clean help

help:
	@echo "Objetivos:"
	@echo "  preflight  — chequeo de entorno/agente (read-only)"
	@echo "  verify     — verificar SHA256 de fuentes vendor"
	@echo "  prepare    — extraer SDK a ~/work/r36sx-hclinux/sdk"
	@echo "  baseline   — (Fase 2) reproducir build vendor"

preflight:
	./scripts/agent_preflight.sh

verify:
	./scripts/verify_sources.sh

prepare:
	./scripts/prepare_sdk.sh

baseline:
	./scripts/build_baseline.sh

clean:
	@echo "NO hay clean destructivo — ver AGENTS.md §5 (prohibido rm -rf no verificado)"
