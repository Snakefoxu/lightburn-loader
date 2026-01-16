# Protocolo Omega: Guía de Parcheo LightBurn (Versión C#)

> **NIVEL DE ACCESO: CLASIFICADO**
> Esta documentación detalla el proceso técnico para mantener el bypass de LightBurn operativo en futuras versiones usando la nueva infraestructura .NET.

## 1. Arquitectura
El loader actual (`Loader.cs`) es una aplicación .NET nativa (C#) compilada con `csc.exe` para máxima compatibilidad y soporte de iconos.
Replica la lógica de inyección de memoria probada en PowerShell.

## 2. Configuración de Offsets (RVAs)
Cuando salga una nueva versión de LightBurn, abre `Loader.cs` y busca esta sección:

```csharp
// --- Configuration ---
// RVAs for LightBurn [VERSION]
static readonly long[] TARGET_RVAS = { 0x6522D5, 0x6522E1, 0x6522DB, 0x6522B7 };
static readonly byte[] PATCH_BYTES = { 0x31, 0xC0, 0xC3 }; // xor eax, eax; ret
```

Debes actualizar `TARGET_RVAS` con las nuevas direcciones relativas.

## 3. Procedimiento de Actualización
1. **Identificar nuevos RVAs:** Usa x64dbg y el método de diferencias de patrones explicado anteriormente.
2. **Editar `Loader.cs`:** Pega los nuevos offsets.
3. **Recompilar:** Ejecuta el siguiente comando en la carpeta `loader_v2`:

```cmd
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /target:winexe /out:LightBurn_Loader.exe /win32icon:LightBurn.ico Loader.cs
```

## 4. Notas Técnicas
- **Requisitos:** .NET Framework 4.0 o superior (viene preinstalado en Win10/11).
- **Stealth:** El flag `/target:winexe` oculta la consola. Si necesitas ver errores para depurar, recompila sin ese flag o cambialo a `/target:exe`.

---
*Protocolo Omega - Fin de Documento*
