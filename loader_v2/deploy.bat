@echo off
set "DIST_DIR=dist"
set "ORIGINAL_DIR=..\original"

if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"

echo [INFO] Copying Loader...
copy /Y "LightBurn_Loader.exe" "%DIST_DIR%\" >nul

echo [INFO] Copying LightBurn original files...
if exist "%ORIGINAL_DIR%\LightBurn.exe" (
    copy /Y "%ORIGINAL_DIR%\LightBurn.exe" "%DIST_DIR%\" >nul
) else (
    echo [ERROR] LightBurn.exe not found in %ORIGINAL_DIR%
)

if exist "%ORIGINAL_DIR%\LexActivator.dll" (
    copy /Y "%ORIGINAL_DIR%\LexActivator.dll" "%DIST_DIR%\" >nul
) else (
    echo [WARNING] LexActivator.dll not found in %ORIGINAL_DIR%
)

echo [SUCCESS] Deployment complete in %DIST_DIR%
pause
