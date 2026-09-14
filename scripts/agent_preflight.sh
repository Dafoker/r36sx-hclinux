#!/usr/bin/env bash
# agent_preflight.sh — Preflight read-only del agente (AGENTS.md §1)
# Verifica: WSL, repo, git, gh, SDK, herramientas. NO modifica nada.
set -euo pipefail

PASS=0; FAIL=0
ok()  { echo "  [PASS] $1"; PASS=$((PASS+1)); }
bad() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }

echo "=== PREFLIGHT r36sx-hclinux ==="

echo "-- entorno --"
if grep -qi microsoft /proc/version 2>/dev/null; then ok "WSL detectado ($(uname -r))"
else bad "NO estamos en WSL — AGENTS.md §0 exige WSL"; fi
ok "Host: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"

echo "-- repo / git --"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ok "repo git: $REPO_ROOT"
  ok "branch: $(git branch --show-current 2>/dev/null || echo '(sin commits aún)')"
  ok "HEAD: $(git rev-parse HEAD 2>/dev/null || echo '(vacío)')"
  DIRTY=$(git status --porcelain 2>/dev/null | wc -l)
  if [ "$DIRTY" -eq 0 ]; then ok "worktree limpio"
  else echo "  [WARN] worktree con $DIRTY cambios — revisar antes de tocar (AGENTS.md §1)"; fi
  if git remote get-url origin >/dev/null 2>&1; then ok "origin: $(git remote get-url origin)"
  else echo "  [WARN] sin remote origin (bootstrap: normal)"; fi
else bad "no es repo git"; fi

echo "-- herramientas --"
for t in git gh make gcc python3 tar patch sha256sum file readelf objdump dtc 7z curl; do
  if command -v "$t" >/dev/null 2>&1; then ok "$t: $(command -v $t)"
  else bad "$t MISSING"; fi
done

echo "-- github cli --"
if gh auth status >/dev/null 2>&1; then
  ok "gh auth: $(gh api user --jq .login 2>/dev/null || echo 'authed')"
else bad "gh sin autenticar — requerido para push (AGENTS.md §0)"; fi

echo "-- SDK fuente (inmutable, ADR-002) --"
K=/mnt/d/GitHub/KERNEL
SDK="$K/hclinux-2024.02.y.2.tar.gz"
if [ -r "$SDK" ]; then ok "SDK presente: $SDK ($(stat -c%s "$SDK") bytes)"
else bad "SDK ausente/inaccesible: $SDK"; fi
if [ -f "$REPO_ROOT/manifests/SOURCES.sha256" ]; then
  ok "manifest existe — ejecutar scripts/verify_sources.sh para validar hash"
else echo "  [WARN] manifest SOURCES.sha256 ausente (bootstrap)"; fi

echo "-- workspace --"
W="$HOME/work/r36sx-hclinux"
if [ -d "$W/sdk" ]; then echo "  [INFO] SDK ya extraído en $W/sdk (caché — validar con verify_sources.sh)"
else echo "  [INFO] workspace $W aún no creado — scripts/prepare_sdk.sh lo creará"; fi

echo "=== RESULT: PASS=$PASS FAIL=$FAIL ==="
[ "$FAIL" -eq 0 ] && echo "PREFLIGHT: OK — continuar con CURRENT.md NEXT EXACT ACTION" || { echo "PREFLIGHT: FALLOS — resolver antes de trabajar"; exit 1; }
