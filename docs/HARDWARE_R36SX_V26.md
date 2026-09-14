# docs/HARDWARE_R36SX_V26.md — Hardware R36SX V2.6

**Estado:** NO INICIADO — Fase 3. **Regla:** prohibido inventar datos físicos. Referencias públicas: LiamJ74/R36S-V2.6_Wiki.

## Datos a recopilar (con fuente)

| Dato | Valor | Fuente |
|---|---|---|
| SoC | (evidencia HC16xx — pendiente) | SDK/Wiki |
| RAM total | PENDIENTE | |
| Partición Linux/AVP/MMZ | PENDIENTE | SDK |
| Flash (NOR/NAND, modelo) | PENDIENTE | |
| Display (panel, resolución, interface) | PENDIENTE | |
| Input (GPIO keys, ADC keys) | PENDIENTE | |
| SD/MMC | PENDIENTE | |
| USB (musb OTG) | PENDIENTE | |
| Audio (vía AVP) | PENDIENTE | |

## Si el usuario puede aportar dumps físicos

Comandos en el dispositivo (firmware stock, shell si existe):

```
cat /proc/cpuinfo /proc/meminfo /proc/cmdline /proc/mtd /proc/partitions /proc/modules /proc/mounts
dmesg > /tmp/dmesg.txt
ls -l /dev > /tmp/devs.txt
cp -r /proc/device-tree /tmp/ 2>/dev/null
```

→ STOP condition: pedir al usuario estos archivos antes de proseguir con datos físicos (AGENTS.md §10).
