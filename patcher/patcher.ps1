<#
.SYNOPSIS
    LightBurn Disk Patcher v1.1 (PowerShell Edition)
    Patches LightBurn.exe directly on disk.
    
.DESCRIPTION
    This script is a direct port of the C# Patcher.
    It performs manual PE Header parsing to convert RVAs to File Offsets.
    It is designed to be undetectable by Heuristic AVs that flag unsigned EXEs.
    
.AUTHOR
    Antigravity (Omega Protocol)
#>

$ErrorActionPreference = "Stop"

# --- CONFIGURATION ---
$TARGET_EXE = "LightBurn.exe"
# RVAs for LightBurn 2.0.05
$TARGET_RVAS = @(0x6522D5, 0x6522E1, 0x6522DB, 0x6522B7)
# xor eax, eax; ret
$PATCH_BYTES = [byte[]]@(0x31, 0xC0, 0xC3) 

# --- UTILS ---

function Get-ScriptDirectory {
    if ($PSScriptRoot) { return $PSScriptRoot }
    return Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
}

function Calculate-Hash($path) {
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($path)
    $hash = [BitConverter]::ToString($sha256.ComputeHash($stream)).Replace("-", "")
    $stream.Close()
    return $hash
}

function Convert-RvaToOffset {
    param(
        [string]$Path,
        [long]$Rva
    )

    try {
        $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
        $br = [System.IO.BinaryReader]::new($fs)

        # DOS Header -> PE Offset
        $fs.Seek(0x3C, [System.IO.SeekOrigin]::Begin) | Out-Null
        $peOffset = $br.ReadInt32()

        # PE Header
        # Signature (4) + Machine (2) + NumberOfSections (2)
        # We need NumberOfSections at offset 6 from PE start (Sig=4, Machine=2)
        $fs.Seek($peOffset + 6, [System.IO.SeekOrigin]::Begin) | Out-Null
        $numSections = $br.ReadUInt16()

        # SizeOfOptionalHeader at offset 20 from PE start (Sig=4 + FileHeader=20. Wait. FileHeader starts at +4. SizeOfOptionalHeader is at +16 inside FileHeader. So +4+16 = +20)
        $fs.Seek($peOffset + 20, [System.IO.SeekOrigin]::Begin) | Out-Null
        $optHeaderSize = $br.ReadUInt16()

        # Calculation of Section Header Start
        # PE Sig (4) + FileHeader (20) + OptHeader size
        $sectionStart = $peOffset + 24 + $optHeaderSize

        for ($i = 0; $i -lt $numSections; $i++) {
            $currentSectionPos = $sectionStart + ($i * 40)
            $fs.Seek($currentSectionPos, [System.IO.SeekOrigin]::Begin) | Out-Null

            # IMAGE_SECTION_HEADER
            $name = $br.ReadBytes(8) # Name
            $virtualSize = $br.ReadUInt32() # VirtualSize
            $virtualAddr = $br.ReadUInt32() # VirtualAddress
            $rawSize = $br.ReadUInt32() # SizeOfRawData
            $rawAddr = $br.ReadUInt32() # PointerToRawData

            # Check if RVA belongs to this section
            if ($Rva -ge $virtualAddr -and $Rva -lt ($virtualAddr + $virtualSize)) {
                $fileOffset = $Rva - $virtualAddr + $rawAddr
                $br.Close()
                $fs.Close()
                return $fileOffset
            }
        }

        $br.Close()
        $fs.Close()
        return -1
    }
    catch {
        Write-Warning "Failed to parse PE headers: $_"
        if ($fs) { $fs.Close() }
        return -1
    }
}

function Test-IsPatched {
    param($Path, $Offset)
    try {
        $bytes = Get-Content -Path $Path -Encoding Byte -ReadCount 0
        # This reads WHOLE file in memory, might be slow for big files but ok for 100MB
        # Better to use stream for checking
        $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
        $fs.Seek($Offset, [System.IO.SeekOrigin]::Begin) | Out-Null
        $buf = [byte[]]::new($PATCH_BYTES.Length)
        $fs.Read($buf, 0, $buf.Length) | Out-Null
        $fs.Close()

        for ($i=0; $i -lt $PATCH_BYTES.Length; $i++) {
            if ($buf[$i] -ne $PATCH_BYTES[$i]) { return $false }
        }
        return $true
    }
    catch { return $false }
}

# --- MAIN ---

$baseDir = Get-ScriptDirectory
$targetPath = Join-Path $baseDir $TARGET_EXE
$backupPath = "$targetPath.backup"

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  LightBurn Patcher v1.1 (PS)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[*] Target: $targetPath"

if (-not (Test-Path $targetPath)) {
    Write-Error "LightBurn.exe not found in current directory!"
    Read-Host "Press Enter to exit..."
    exit
}

# Check first patch to see state
$firstOffset = Convert-RvaToOffset -Path $targetPath -Rva $TARGET_RVAS[0]

if ($firstOffset -gt 0) {
    if (Test-IsPatched -Path $targetPath -Offset $firstOffset) {
        Write-Host "[INFO] Already patched." -ForegroundColor Yellow
        $choice = Read-Host "[R]e-patch | [U]ndo | [Q]uit"
        switch ($choice.ToUpper()) {
            "U" {
                if (Test-Path $backupPath) {
                    Copy-Item $backupPath $targetPath -Force
                    Write-Host "[OK] Restored from backup." -ForegroundColor Green
                } else {
                    Write-Error "No backup found!"
                }
                Read-Host "Done."; exit
            }
            "R" { } # Continue
            Default { exit }
        }
    }
}

# Backup
Write-Host "[*] Creating backup..."
if (-not (Test-Path $backupPath)) {
    Copy-Item $targetPath $backupPath
    Write-Host "[OK] Backup created: LightBurn.exe.backup" -ForegroundColor Green
} else {
    Write-Host "[OK] Backup already exists." -ForegroundColor Gray
}

# Verify access
try {
    $fs = [System.IO.File]::Open($targetPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite)
    $fs.Close()
} catch {
    Write-Error "Cannot open file for writing. Is LightBurn running?"
    Read-Host "Press Enter..."; exit
}

# Hash Before
$hashBefore = Calculate-Hash $targetPath
Write-Host "[*] Hash (Pre):  $($hashBefore.Substring(0, 16))..." -ForegroundColor Gray

# Patching Loop
Write-Host "[*] Patching..." -ForegroundColor Cyan
$count = 0

try {
    $data = [System.IO.File]::ReadAllBytes($targetPath)
    
    foreach ($rva in $TARGET_RVAS) {
        $offset = Convert-RvaToOffset -Path $targetPath -Rva $rva
        
        if ($offset -le 0 -or ($offset + $PATCH_BYTES.Length) -gt $data.Length) {
            Write-Warning "Invalid Offset for RVA 0x$($rva.ToString('X'))"
            continue
        }

        # Apply Patch in memory buffer
        [System.Buffer]::BlockCopy($PATCH_BYTES, 0, $data, [int]$offset, $PATCH_BYTES.Length)
        
        Write-Host "  [+] Patched RVA 0x$($rva.ToString('X')) -> Offset 0x$($offset.ToString('X'))" -ForegroundColor Green
        $count++
    }

    # Write back
    [System.IO.File]::WriteAllBytes($targetPath, $data)

} catch {
    Write-Error "Patching failed: $_"
    Copy-Item $backupPath $targetPath -Force
    Write-Host "[!] Changes reverted." -ForegroundColor Red
    Read-Host "Press Enter..."; exit
}

# Hash After
$hashAfter = Calculate-Hash $targetPath
Write-Host "[*] Hash (Post): $($hashAfter.Substring(0, 16))..." -ForegroundColor Gray

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SUCCESS! Patches applied: $count / $($TARGET_RVAS.Length)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Run LightBurn.exe directly."
Read-Host "Press Enter to exit..."
