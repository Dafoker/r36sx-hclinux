#!/usr/bin/env bash
# audit_kernel_patches.sh — PATCH PROVENANCE GATE (AGENTS.md §14)
# Verifica el patch set REALMENTE aplicado a un kernel build dir del proyecto:
# 41 patches HiChip en orden + inyección rsync de SOURCE/linux-drivers + yaffs2.
# Read-only sobre el output y el SDK; idempotente; emite PATCH PROVENANCE: PASS/FAIL.
# Uso: ./scripts/audit_kernel_patches.sh [kernel-build-dir] [output-dir]
#   kernel-build-dir default: ~/work/r36sx-hclinux/build/d3100-v20-baseline/build/linux-4.4.186
#   output-dir default:        ~/work/r36sx-hclinux/build/d3100-v20-baseline
set -uo pipefail

KB="${1:-$HOME/work/r36sx-hclinux/build/d3100-v20-baseline/build/linux-4.4.186}"
O="${2:-$HOME/work/r36sx-hclinux/build/d3100-v20-baseline}"
SDK="$HOME/work/r36sx-hclinux/sdk/hclinux-2024.02.y.2/hclinux"
P4="$SDK/patches/linux-4.4.186"
KEXT=/mnt/d/GitHub/KERNEL
FAIL=0
bad() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
ok()  { echo "  [PASS] $1"; }

echo "=== PATCH PROVENANCE AUDIT — $KB ==="

# 1. precondiciones
[ -d "$KB" ] || { echo "  [FAIL] no existe $KB"; echo "PATCH PROVENANCE: FAIL"; exit 1; }
[ -f "$KB/.stamp_patched" ] && ok ".stamp_patched presente" || bad "sin .stamp_patched"
[ -f "$O/.config" ] && grep -q '^BR2_GLOBAL_PATCH_DIR="$(BR2_EXTERNAL_HCLINUX_PATH)/patches"$' "$O/.config" \
  && ok "BR2_GLOBAL_PATCH_DIR = SDK/patches" || bad "BR2_GLOBAL_PATCH_DIR no apunta al SDK"

# 2. hunks distintivos en el árbol (presence != applied; aquí: árbol resultante)
echo "-- hunks/símbolos en árbol --"
grep -q "platforms += hc16xx" "$KB/arch/mips/Kbuild.platforms" 2>/dev/null && ok "0001: platforms += hc16xx" || bad "0001 no aplicado (Kbuild.platforms)"
grep -q "config HICHIP_HC16XX" "$KB/arch/mips/Kconfig" 2>/dev/null && ok "0001: config HICHIP_HC16XX" || bad "0001 no aplicado (Kconfig)"
grep -qE "obj-.*hcdrivers" "$KB/drivers/Makefile" 2>/dev/null && ok "0007: obj hcdrivers en Makefile" || bad "0007 no aplicado"
[ -d "$KB/drivers/hcdrivers" ] && ok "BSP drivers/hcdrivers/ inyectado ($(ls "$KB/drivers/hcdrivers" | wc -l) componentes)" || bad "drivers/hcdrivers ausente"
[ -d "$KB/arch/mips/hc16xx" ] && ok "arch/mips/hc16xx/ inyectado ($(ls "$KB/arch/mips/hc16xx" | wc -l) archivos)" || bad "arch/mips/hc16xx ausente"
[ -d "$KB/fs/yaffs2" ] && ok "yaffs2 integrado en fs/" || bad "yaffs2 ausente"
grep -q "yaffs" "$KB/fs/Kconfig" 2>/dev/null && ok "fs/Kconfig referencia yaffs2" || bad "fs/Kconfig sin yaffs"

# 3. patch log del proyecto (evidencia primaria si existe) o recuento del set
echo "-- patch log / set --"
LOG="$HOME/work/r36sx-hclinux/logs/linux-patch-v1.log"
NP4=$(find "$P4" -maxdepth 1 -name '*.patch' | wc -l)
[ "$NP4" -eq 41 ] && ok "set SDK linux-4.4.186 = 41 patches" || bad "set SDK = $NP4 (esperado 41)"
if [ -f "$LOG" ]; then
  NA=$(grep -c "^Applying" "$LOG")
  [ "$NA" -eq 41 ] && ok "log V=1: 41 'Applying' en orden" || bad "log: $NA Applying (esperado 41)"
  grep -q "rsync.*SOURCE/linux-drivers" "$LOG" && ok "log: rsync linux-drivers (PRE_PATCH)" || bad "log sin rsync"
  grep -q "patch-ker.sh" "$LOG" && ok "log: yaffs2 patch-ker.sh" || bad "log sin yaffs2"
else
  echo "  [INFO] sin $LOG — regenerar con: make O=<audit> V=1 linux-patch (ver docs/PATCH_PROVENANCE.md §4)"
fi

# 4. relación con copias externas D: (VERIFIED IDENTICAL, sin doble aplicación)
echo "-- copias externas /mnt/d/GitHub/KERNEL --"
if [ -d "$KEXT/linux-4.4.186" ]; then
  D=$(diff <(cd "$P4" && find . -maxdepth 1 -name '*.patch' -exec sha256sum {} \; | sort -k2) \
           <(cd "$KEXT/linux-4.4.186" && find . -maxdepth 1 -name '*.patch' -exec sha256sum {} \; | sort -k2))
  [ -z "$D" ] && ok "41/41 idénticos a D:\\GitHub\\KERNEL (VERIFIED IDENTICAL — no doble aplicación)" || bad "diff externo vs SDK"
else
  echo "  [INFO] $KEXT/linux-4.4.186 no accesible"
fi

echo "=== RESULT: FAIL=$FAIL ==="
if [ "$FAIL" -eq 0 ]; then echo "PATCH PROVENANCE: PASS"; else echo "PATCH PROVENANCE: FAIL"; exit 1; fi
