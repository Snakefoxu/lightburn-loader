#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Añade exclusiones de Windows Defender para LightBurn Loader
.DESCRIPTION  
    Exclusiones necesarias debido a detección heurística de comportamiento
.NOTES
    Ejecutar como Administrador
#>

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  LightBurn - Exclusion Manager" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: Ejecutar como Administrador!" -ForegroundColor Red
    Read-Host "Enter para salir"
    exit 1
}

# Rutas a excluir
$paths = @(
    "C:\Program Files\LightBurn",
    "$env:LOCALAPPDATA\LightBurn",
    (Get-Location).Path
)

$procs = @("LightBurn.exe", "LightBurn_Loader.exe")

Write-Host "Añadiendo exclusiones de carpetas..." -ForegroundColor Yellow
foreach ($p in $paths) {
    try {
        Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue
        Write-Host "  [OK] $p" -ForegroundColor Green
    }
    catch {
        Write-Host "  [SKIP] $p" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Añadiendo exclusiones de procesos..." -ForegroundColor Yellow
foreach ($proc in $procs) {
    try {
        Add-MpPreference -ExclusionProcess $proc
        Write-Host "  [OK] $proc" -ForegroundColor Green
    }
    catch {
        Write-Host "  [FAIL] $proc" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Exclusiones aplicadas!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Read-Host "Enter para salir"
