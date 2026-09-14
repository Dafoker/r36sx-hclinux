# docs/ARCHITECTURE.md — Arquitectura del sistema (prevista)

**Estado:** BOSQUEJO — toda afirmación aquí es hipótesis hasta Fase 1 (SDK_AUDIT) con evidencia.

## Cadena de boot (hipótesis H9/H3, a confirmar)

```
BootROM (HC16xx)
  └─ bootloader (hcboot/U-Boot vendor — evidencia pendiente)
       ├─ núcleo 0 (core-main): Linux 4.4.186 + DTB + rootfs
       └─ núcleo 1: HCRTOS/AVP (firmware vendor, preservado — ADR-005)
            └─ AMPRPC (hcdrivers/amprpc) ←→ Linux (avp-proxy)
```

## Partición de responsabilidades (prevista, sujeta a auditoría)

| Capa | Responsable | Origen |
|---|---|---|
| BootROM / DDR init | Vendor (intocable en baseline) | SDK |
| Bootloader | Vendor (preservado) | SDK |
| AVP/HCRTOS (audio, decoder HW, DDR timing?) | Vendor (preservado) | SDK |
| Kernel Linux 4.4.186 | **NUESTRO** (compilado del SDK patched) | SDK + repo propio |
| DTB | **NUESTRO** (Fase 4) | derivado vendor |
| Rootfs | **NUESTRO** (Fase 8, Buildroot) | controlado |
| picoarch + TreeFrogUI | Upstream + integración nuestra | tzubertowski |

## Drivers vendor clave (hcdrivers/, evidencia física en /mnt/d)

- `amprpc` + `avp-proxy`: puente Linux↔AVP.
- `fbdev/hcfb.c`: framebuffer TreeFrogUI.
- `mmz`: zona de memoria media (video) compartida.
- `musb`: USB host/gadget (_mass storage, OTG).
- `nand`: 4.x/5.x — flash.
- `persistentmem(-fs)`: almacenamiento persistente de settings.

## Principios

1. Una variable por experimento; AVP/boot intocables hasta baseline known-good.
2. Todo cambio documentado con evidencia; reconstruible desde SDK + este repo.
3. TreeFrogUI = criterio de compatibilidad de referencia (Fase 6).
