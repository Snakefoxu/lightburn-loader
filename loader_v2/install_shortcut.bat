@echo off
set "LOADER_EXE=LightBurn_Loader.exe"
set "SHORTCUT_NAME=LightBurn Patched"
set "TARGET_DIR=%CD%"

echo [INFO] Verifying location...

if not exist "%TARGET_DIR%\LightBurn.exe" (
    color 0C
    echo [ERROR] "LightBurn.exe" not found in this directory.
    echo.
    echo =================================================================
    echo  INSTALLATION ERROR
    echo =================================================================
    echo.
    echo  This patch must be installed INSIDE the LightBurn folder.
    echo.
    echo  STEPS TO FIX:
    echo  1. Move/Copy "LightBurn_Loader.exe" and this script to the
    echo     installation folder (e.g.: C:\Program Files\LightBurn^).
    echo  2. Run this script ("install_shortcut.bat"^) from there.
    echo.
    pause
    exit /b 1
)

echo [INFO] Correct directory detected.
echo [INFO] Creating desktop shortcut...

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut([System.IO.Path]::Combine([Environment]::GetFolderPath('Desktop'), '%SHORTCUT_NAME%.lnk')); $s.TargetPath = '%TARGET_DIR%\%LOADER_EXE%'; $s.WorkingDirectory = '%TARGET_DIR%'; $s.IconLocation = '%TARGET_DIR%\%LOADER_EXE%'; $s.Save()"

if exist "%USERPROFILE%\Desktop\%SHORTCUT_NAME%.lnk" (
    echo [SUCCESS] Shortcut created successfully.
) else (
    color 0C
    echo [ERROR] Failed to create shortcut.
)
pause
