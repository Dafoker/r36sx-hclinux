#!/usr/bin/env bash
# inventory_sources.sh — Inventario completo (read-only) de /mnt/d/GitHub/KERNEL
# Regenera el listado con hashes. NO modifica las fuentes. Salida: stdout + manifests opcional.
set -euo pipefail
K=/mnt/d/GitHub/KERNEL
echo "=== inventory_sources: $K ==="
echo "-- archivos top-level --"
find "$K" -maxdepth 1 -type f -printf '%s\t%p\n' | sort -k2
echo "-- árboles (conteo) --"
for d in "$K"/*/; do echo "  $(basename "$d"): $(find "$d" -type f | wc -l) archivos"; done
echo "-- SHA256 top-level --"
find "$K" -maxdepth 1 -type f -exec sha256sum {} \; | sort -k2
echo "=== inventory done ==="
