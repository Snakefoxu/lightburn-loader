@echo off
echo ============================================
echo   LightBurn Patcher - Build Script
echo ============================================
echo.

set CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe

if not exist "%CSC%" (
    echo ERROR: C# compiler not found!
    pause
    exit /b 1
)

echo Compiling Patcher.cs...
"%CSC%" /nologo /optimize+ /target:exe /platform:x64 /out:LightBurn_Patcher.exe Patcher.cs

if %ERRORLEVEL% neq 0 (
    echo COMPILATION FAILED!
    pause
    exit /b 1
)

echo.
echo Build successful: LightBurn_Patcher.exe
echo.
pause
