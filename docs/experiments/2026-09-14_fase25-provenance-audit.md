# Experimento: 2026-09-14 — Fase 2.5 provenance audit (toolchain + patches + board identity)

# Objective

Antes de la board propia (Fase 4), demostrar con evidencia reproducible: (A) que el kernel/userspace target se compiló realmente por cross-compilation x86_64→MIPS y con qué toolchain exacta; (B) que el conjunto correcto de patches HC16xx/Linux 4.4.186 fue realmente aplicado, con orden y relación exacta con `D:\GitHub\KERNEL`.

# Hypothesis

El baseline d3100_v20 fue cross-compilado con Codescape mips-mti-linux-gnu gcc 6.3.0 (2018.09-02) y recibió los 41 patches HiChip + inyección rsync de SOURCE/linux-drivers + yaffs2, en ese orden; los patches de D:\GitHub\KERNEL son copias idénticas ya cubiertas por el SDK.

# Evidence

- Host: `uname -m` = x86_64, Ubuntu 24.04.4 WSL2.
- Output auditado: `~/work/r36sx-hclinux/build/d3100-v20-baseline` (config: BR2_ARCH=mipsel, LITTLE, prefix mips-mti-linux-gnu, kernel 4.4.186).
- Cross-compiler REAL: 1515 archivos `.cmd` de kbuild; `cmd_init/main.o := .../host/bin/mips-mti-linux-gnu-gcc ... -isystem .../ext-toolchain/lib/gcc/mips-mti-linux-gnu/6.3.0/include`; invocado en 117 directorios/subsistemas distintos; linker `mips-mti-linux-gnu-ld -m elf32ltsmip`.
- Toolchain identidad: `host/opt/ext-toolchain/bin/mips-mti-linux-gnu-gcc` → Codescape 2018.09-02, `-dumpmachine mips-mti-linux-gnu`, sysroot `mipsel-r2-hard`.
- ELF: vmlinux ELF32 LSB MIPS MIPS32r2 (Entry 0x803e3200, flags noreorder/o32/mips32r2); busybox ELF32 MIPS MIPS32r2 hard-float dyn `/lib/ld.so.1`; 8188fu.ko ELF32 MIPS relocatable. `.comment` de vmlinux y busybox: `GCC: (Codescape GNU Tools 2018.09-02 for MIPS MTI Linux) 6.3.0`.
- Parcheo: log `~/work/r36sx-hclinux/logs/linux-patch-v1.log` (221 líneas) de `make O=patch-audit V=1 linux-patch` en output AISLADO `~/work/r36sx-hclinux/patch-audit/`: rsync `SOURCE/linux-drivers/` (línea 27) → yaffs2 `patch-ker.sh c m` (línea 32) → 41× `Applying NNNN-*.patch using patch` (0001→0055, orden) → `.stamp_patched`.
- Hunks en árbol: `platforms += hc16xx` (Kbuild.platforms), `config HICHIP_HC16XX` (Kconfig), `obj-* hcdrivers` (drivers/Makefile), `arch/mips/hc16xx/` (20 archivos), `drivers/hcdrivers/` (37 componentes), `fs/yaffs2` + Kconfig — todos presentes.
- Dry-run: 0001 y 0055 sobre el árbol → "Reversed (or previously applied) patch detected" (complementario).
- Externos: 41/41 (4.4.186) + 21/21 (5.12.4) byte-idénticos SDK↔D:\GitHub\KERNEL (diff sha256 vacío); `patches.7z` = 62 = ambos sets, nada nuevo; `hcdrivers.7z` ⊂ SDK.
- E3100: `grep -RliE 'e3100'` SDK → solo `chipid.h` (`HICHIP_E3000=400, HICHIP_E3100`), efuse y falsos positivos ffmpeg; 0 boards/defconfigs/DTS E3100. DTB stock: label `hc1600a@dbE3100v20`, panel MIPI-DSI con init-sequence propia (líneas 1736–1744).
- Remoto: `gh api repos/.../commits/main` = `git rev-parse HEAD` = `git ls-remote` = `51ec19f...`.

# Files changed

- Gobernanza: AGENTS.md §14 (KERNEL PROVENANCE GATE) + orchestrator/kernel-engineer/validation-engineer/sdk-researcher (commit 51ec19f).
- Nuevos: docs/{TOOLCHAIN_PROVENANCE, PATCH_PROVENANCE, BOARD_IDENTITY}.md, scripts/{audit_toolchain,audit_kernel_patches}.sh.
- Corregidos: uso de "vermagic" en README/HARDWARE/SDK_AUDIT (user@host no prueba toolchain).

# Commands

```bash
./scripts/audit_toolchain.sh       # → TOOLCHAIN PROVENANCE: PASS
./scripts/audit_kernel_patches.sh  # → PATCH PROVENANCE: PASS
# (dinámica de parcheo reproducida en output aislado)
make O=~/work/r36sx-hclinux/patch-audit BR2_EXTERNAL=<SDK> hichip_hc16xx_db_d3100_v20_defconfig
make O=... V=1 linux-patch 2>&1 | tee logs/linux-patch-v1.log
```

# Build result

Sin nuevo build de kernel (fase de auditoría). Reproducibilidad re-confirmada: DTB byte-idéntico a baseline previo; vmlinux.bin tamaño idéntico (diferencias solo metadatos de build — documentadas).

# Tests

- TOOLCHAIN PROVENANCE: **PASS** (script gate: 0 FAIL — host, config, .cmd, triplet, sysroot, ELF×3).
- PATCH PROVENANCE: **PASS** (script gate: 0 FAIL — stamp, GLOBAL_PATCH_DIR, hunks, 41 set, log 41 Applying, rsync, yaffs2, 41/41 externos idénticos).
- BOARD IDENTITY: **DOCUMENTED** (E3100 = chipid sin board; 8 diferencias; base Fase 4 definida).
- Remoto GitHub: **VERIFIED** (3 vías coinciden).

# Result

Todos los criterios de salida de Fase 2.5 cumplidos (checklist §15 del requisito: CONFIRMED/PASS/IDENTIFIED×4/MIPS CONFIRMED×2/DOCUMENTED/CONFIRMED×4/NOT DOUBLE-APPLIED/DOCUMENTED/PASS/VERIFIED).

# Interpretation

1. La cross-compilación está probada por invocación (.cmd), no por presencia — el gate queda automatizado para futuros builds.
2. El pipeline de parcheo es 100% reproducible y auditado en output aislado sin tocar el baseline ni el SDK.
3. Los patches de D:\GitHub\KERNEL están correctamente "considerados": copias verificadas, sin doble aplicación, sin patches externos huérfanos (0).
4. "vermagic == toolchain" era una sobreafirmación — corregido en toda la documentación; la cadena de compilador embebida sí coincide (complementaria).
5. E3100 existe como chipid en el SDK pero sin board: la board propia r36sx-v26 debe nacer del híbrido D3100-estructura + stock-valores.

# Decision

- Fase 2.5 CERRADA. **Autorización interna para iniciar Fase 4** (gates superados).
- ADR-009 (a registrar en DECISIONS.md en el commit): los scripts audit_toolchain.sh/audit_kernel_patches.sh pasan a formar parte del gate C obligatorio.

# Artifact hashes

- Log parcheo: `~/work/r36sx-hclinux/logs/linux-patch-v1.log` (221 líneas).
- Evidencias audit: `~/work/r36sx-hclinux/audit/fase25/*.txt` (host, target_config, cmd_samples, elf_kernel/busybox/module, compile_info).
- (sin artefactos binarios nuevos — fase de auditoría).

# Next action

Fase 4 — board propia r36sx-v26 (CURRENT.md NEXT EXACT ACTION).
