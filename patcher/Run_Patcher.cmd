@echo off
TITLE LightBurn Patcher v2.0 (Stealth Edition)
CLS

:: Check for Administrator Privileges
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo [!] Requesting Admin Permissions...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"

    echo [*] Starting Stealth Patcher...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "patcher.ps1"
    
    echo.
    echo [OK] Execution Finished.
    pause
