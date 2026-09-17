# r36sx-hclinux

**Reproducible Linux/HCLinux platform for the R36SX V2.6 handheld console (HiChip HC1600A, MIPS32r2 little-endian) — with TreeFrogUI as the target frontend.**

[![Status](https://img.shields.io/badge/Fase%202-VENDOR%20BASELINE%20BUILD%20PASS-brightgreen)]() [![Kernel](https://img.shields.io/badge/kernel-4.4.186-blue)]() [![Validation](https://img.shields.io/badge/physical-PASS-brightgreen)]()

## What this is

Engineering project building our own kernel/DTB/rootfs for the R36SX V2.6 from the official HiChip **HCLinux SDK 2024.02.y.2** (Buildroot 2021.05-rc2), preserving the vendor AVP/HCRTOS coprocessor firmware, aiming at TreeFrogUI as main shell and progressively removing stock firmware limitations.

**Hardware target (physical evidence):** SoC HC1600A · board `hc1600a@dbE3100v20` · 256 MiB RAM (176 MiB visible to stock Linux) · Linux 4.4.186 stock · display 1280x720 (fb0 @0x18808000) · console=tty1.

## Current state (2026-09-17)

**Vendor pipeline build: PASS · R36SX custom board build: PASS · Fase 5 PHYSICAL PASS — our own kernel boots the console to the TreeFrogUI menu (navegable y funcional, iteración 6x)**

What works: full vendor kernel pipeline reproduced end-to-end with proven provenance; stock hardware model fully reconstructed from the real console DTB; custom board `r36sx-v26` builds a kernel whose DTB is **semantically identical to stock**; **Fase 5 complete: the console boots OUR kernel (uImage `017adf3b`) to a fully functional TreeFrogUI menu** — achieved via stock-parity initramfs (real S41hcdaemon/S99app, raw cpio like factory) + vendor-baseline config + CHECK_ADC. What doesn't yet: TreeFrogUI contract formalization (Fase 6), own rootfs via Buildroot (Fase 8), AVP/hcboot compilation (bare-metal toolchain unavailable — GitLab HiChip private).

| Subsystem | Status | Evidence |
|---|---|---|
| SDK audit (H1–H11) | **STATIC PASS** — full pipeline mapped with evidence | `docs/SDK_AUDIT.md` |
| Vendor baseline build (d3100_v20) | **BUILD PASS** + provenance PROVEN (.cmd files + patch log V=1) | `docs/TOOLCHAIN_PROVENANCE.md` · `docs/PATCH_PROVENANCE.md` |
| Stock hardware model (4A) | **PASS** — DTB decompiled (roundtrip SEMANTIC), memory map exact, panel MIPI-DSI r63311 demonstrated, 15 formal deltas | `docs/DTS_STOCK_MODEL.md` · `docs/R36SX_D3100_DELTA.md` |
| **Custom board r36sx-v26 (4B)** | **BUILD PASS — DTB semantically IDENTICAL to stock (allowlist 0); kernel .config == vendor; provenance gates PASS** | `docs/experiments/2026-09-14_r36sx-v26-board.md` |
| TreeFrogUI contract | PENDING (Fase 6) | — |
| Physical validation | **PASS (Fase 5, 2026-09-16)** — own kernel `017adf3b` boots the console to a functional, navigable TreeFrogUI menu; post-boot SD verification complete (kernel intact, stock dtb/avp untouched) | `docs/experiments/2026-09-16_menu-goal-stock-parity.md` |

What works: full vendor kernel pipeline reproduced end-to-end (kernel+DTB+uImage+rootfs), physical hardware documented from stock SD (read-only). What doesn't yet: custom board DTS, own kernel on device, AVP/hcboot compilation (bare-metal toolchain unavailable — GitLab HiChip is private), TreeFrogUI integration.

## Architecture (confirmed)

```
BootROM → DDR-init(12KiB .abs) → bootloader.bin(DDR-init+u-boot) → AVP HCRTOS uImage @0x8bda4000 (PRESERVED stock)
  → Linux 4.4.186 @core-main (uImage @0x80000000, DTB @0x85ff0000, reg 0xb8800004) ↔ AMPRPC ↔ AVP @core-AVP
```

Kernel pipeline: vanilla 4.4.186 (kernel.org) → rsync `SOURCE/linux-drivers` (arch/mips/hc16xx + hcdrivers) → 45 vendor patches + yaffs2 → load-addr fixup from DTS → Codescape mips-mti-linux-gnu gcc 6.3.0 (2018.09-02) → mkimage.

## Requirements & quick start

- **WSL2 Ubuntu 24.04 only** (all dev/builds/git from WSL — invariant). Host packages: see `docs/BUILD.md`.
- Vendor SDK (immutable, not in this repo) at `D:\GitHub\KERNEL\hclinux-2024.02.y.2.tar.gz` (sha256 `e3211b41...f8d5d`).

```bash
git clone https://github.com/ozkaoz/r36sx-hclinux.git && cd r36sx-hclinux
./scripts/agent_preflight.sh        # environment + git + gh + SDK checks (read-only)
./scripts/verify_sources.sh         # SHA256 vendor sources vs manifests/
./scripts/prepare_sdk.sh            # extract SDK → ~/work/r36sx-hclinux/sdk
# build vendor baseline (docs/BUILD.md for env vars + known issues):
./scripts/build_baseline.sh         # d3100_v20 kernel-only — BUILD PASS validated
```

Expected artifacts: `vmlinux.uImage` (gzip, Load 0x80000000 / Entry 0x803e3200), `dtb.bin`, `vmlinux(.bin)`, `System.map`, `rootfs.squashfs`, `kernel.config` — hashed in `out/`/workspace, never in git.

## Validation labels

STATIC / HOST / BUILD / PACKAGING / EMULATED / PHYSICAL / CLEAN-INSTALL / DOWNLOAD-BACK **PASS** (`docs/ai/VALIDATION.md`). Nothing has been physically tested yet — **BUILD PASS ≠ runs on console**.

## Roadmap

0 Bootstrap ✅ · 1 SDK audit ✅ · 2 Vendor baseline BUILD PASS ✅ · 3 Hardware (physical) ✅ · **4 Custom board r36sx-v26 (current)** · 5 Own kernel on device (requires explicit authorization) · 6 TreeFrogUI contract · 7 Optimizations · 8 Own rootfs (Buildroot) · 9 Kernel 5.12.4 experimental (deferred; vendor manual: USB/SDIO broken there)

Full plan + gates: `docs/ROADMAP.md`.

## Safety & license

- **Never flash** NOR/NAND/bootloader/DDR/SD without explicit user authorization; stock SD is golden recovery (`docs/ai/HARDWARE_SAFETY.md`).
- SDK is proprietary HiChip — not redistributed; this repo holds only our own scripts/configs/patches/docs. License TBD (ADR pending) before any release.

## Documentation

Start: `AGENTS.md` (constitution, WSL-only + doc-sync rules) → `CURRENT.md` (operational snapshot) → `CONTEXT_MAP.md` (router). Key: `docs/ARCHITECTURE.md` · `docs/BOOT_CHAIN.md` · `docs/HARDWARE_R36SX_V26.md` · `docs/SDK_AUDIT.md` · `docs/BUILD.md` · `DECISIONS.md` (ADR-001..008) · `docs/experiments/` (technical log).
