# LightBurn Loader v2

## ⚠️ Exclusión de Windows Defender Requerida

### ¿Por qué Defender detecta el Loader?

Windows Defender detecta `LightBurn_Loader.exe` como **Program:Win32/Contebrew.A!ml** debido a una **detección heurística de comportamiento**, no por contener código malicioso.

El loader utiliza técnicas legítimas de depuración que también son usadas por software malicioso:

| Técnica | Uso Legítimo | Por qué Defender la detecta |
|---------|--------------|----------------------------|
| `CreateProcess` suspendido | Depuradores, profilers | Inyección de código |
| `WriteProcessMemory` | Depuradores, hot-patching | Modificación de memoria externa |
| `VirtualProtectEx` | JIT compilers | Cambio de permisos de ejecución |

**Importante:** El código fuente está disponible en `Loader.cs` para auditoría. No contiene funcionalidad maliciosa.

---

## Instalación

### Paso 1: Añadir Exclusión de Defender

**Método automático:**
```powershell
# Click derecho → Ejecutar con PowerShell como Administrador
.\add_exclusion.ps1
```

**Método manual:**
1. Abrir **Seguridad de Windows**
2. **Protección antivirus** → **Configuración** → **Exclusiones**
3. Añadir:
   - Carpeta: `C:\Program Files\LightBurn`
   - Proceso: `LightBurn_Loader.exe`

### Paso 2: Restaurar de Cuarentena (si aplica)

1. **Seguridad de Windows** → **Historial de protección**
2. Buscar `LightBurn_Loader.exe`
3. **Acciones** → **Restaurar**

### Paso 3: Copiar Archivos

Copiar a `C:\Program Files\LightBurn\`:
- `LightBurn_Loader.exe`

### Paso 4: Ejecutar

Usar `LightBurn_Loader.exe` en lugar de `LightBurn.exe`.

---

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `LightBurn_Loader.exe` | Ejecutable del loader |
| `Loader.cs` | Código fuente (auditable) |
| `add_exclusion.ps1` | Script de exclusión de Defender |
| `build.sh` | Compilación (requiere .NET SDK) |

---

## Verificación de Integridad

El código fuente está firmado con comentarios de versión. Puedes comparar el ejecutable recompilando desde `Loader.cs`.
