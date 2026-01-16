# LightBurn Disk Patcher v1.1

Patcher de disco que modifica `LightBurn.exe` directamente. Sin detección de antivirus.

## ¿Por qué usar Patcher en lugar de Loader?

| Aspecto | Loader | Patcher |
|---------|--------|---------|
| Detección AV | ⬆️ Alta | ✅ Ninguna |
| Técnica | Inyección en memoria | Modificación de archivo |
| Requiere exclusión | Sí, permanente | No |
| Uso | Ejecutar loader cada vez | Parchear una vez |

## Uso

1. Copiar `LightBurn_Patcher.exe` a la carpeta de LightBurn
2. Ejecutar como Administrador
3. Seleccionar opción de parcheo
4. Usar `LightBurn.exe` directamente

## Opciones

- **Patch** - Aplica parches (crea backup automático)
- **[R]e-patch** - Volver a aplicar parches
- **[U]ndo** - Restaurar desde backup

## Archivos Generados

- `LightBurn.exe.backup` - Backup del original

## Compilación

```cmd
build.bat
```

## Versión

- LightBurn **2.0.05**
