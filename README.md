# LightBurn Patcher

## Métodos Disponibles

| Método | Archivo | Detección AV | Uso |
|--------|---------|-------------|-----|
| **Patcher** ⭐ | `patcher/` | ✅ Ninguna | Parchar una vez, usar LightBurn directo |
| Loader | `loader_v2/` | ⚠️ Alta | Requiere exclusión de Defender |

## Uso Recomendado: Patcher de Disco

1. Copiar `patcher/LightBurn_Patcher.exe` a `C:\Program Files\LightBurn\`
2. Ejecutar como Administrador
3. El patcher crea backup y aplica parches
4. Usar `LightBurn.exe` directamente

## Estructura

```
├── patcher/                    # ⭐ Recomendado
│   ├── LightBurn_Patcher.exe   # Patcher de disco
│   ├── Patcher.cs              # Código fuente
│   └── README.md
│
├── loader_v2/                  # Alternativa (detectado por AV)
│   ├── LightBurn_Loader.exe    # Loader en memoria
│   ├── Loader.cs
│   └── add_exclusion.ps1       # Exclusión de Defender
│
└── LightBurn_Loader_Complete/  # Herramientas de desarrollo
    └── Tools/                  # x64dbg, tcc, etc.
```

## Versión Soportada

- LightBurn **2.0.05**
- Para otras versiones, actualizar RVAs en `Patcher.cs` o `Loader.cs`
