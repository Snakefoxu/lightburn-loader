# LightBurn Patcher (Stealth Edition)

**Target:** LightBurn 2.0.05
**Version:** v2.1
**Status:** ✅ Undetected / Working

## Descarga
Ve a la sección de **[Releases](../../releases)** y descarga **`LightBurn_Patcher_v2.1_Stealth.zip`**.

---

## Instrucciones de Uso

El paquete incluye dos métodos. Elige el que prefieras:

### Opción A: Rápida (Reemplazar)
1. Extrae el archivo **`LightBurn_Patched.exe`**.
2. Ve a la carpeta de instalación (ej: `C:\Program Files\LightBurn\`).
3. Renombra tu `LightBurn.exe` original a `LightBurn.bak`.
4. Mueve `LightBurn_Patched.exe` a esa carpeta y renómbralo a **`LightBurn.exe`**.
5. ¡Listo!

### Opción B: Patcher (Automático)
Si prefieres modificar tu propio archivo:
1. Extrae todo el contenido del zip en la carpeta de LightBurn.
2. Ejecuta **`Run_Patcher.cmd`** (Click derecho -> Ejecutar como Admin).
3. El script hará un backup y aplicará el parche por ti.

---

## Detalles Técnicos
Este método modifica directamente el byte code del ejecutable en disco (Disk Patching).
- **Indetectable:** No utiliza inyección de memoria (que alertaría al antivirus).
- **Seguro:** Utiliza APIs nativas de Windows/PowerShell.
- **Transparente:** Puedes revisar el código en `patcher.ps1`.

## Disclaimer
Solo para propósitos educativos. Si te gusta el software, cómpralo para apoyar a los desarrolladores.
