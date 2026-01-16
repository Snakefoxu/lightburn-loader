<#
.SYNOPSIS
    LightBurn Loader Debugger (PowerShell Edition) - Fixed
    Replicates the logic of loader.c to debug failures.
#>

$ErrorActionPreference = "Stop"

# --- P/Invoke Definitions ---
$TypeDefinition = @'
using System;
using System.Runtime.InteropServices;

namespace Win32 {
    public static class Native {
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool CreateProcess(string lpApplicationName, string lpCommandLine, IntPtr lpProcessAttributes, IntPtr lpThreadAttributes, bool bInheritHandles, uint dwCreationFlags, IntPtr lpEnvironment, string lpCurrentDirectory, ref STARTUPINFO lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool VirtualProtectEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flNewProtect, out uint lpflOldProtect);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpAddress, byte[] lpBuffer, uint nSize, out IntPtr lpNumberOfBytesWritten);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpAddress, [Out] byte[] lpBuffer, int dwSize, out IntPtr lpNumberOfBytesRead);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern uint ResumeThread(IntPtr hThread);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool CloseHandle(IntPtr hObject);

        [DllImport("ntdll.dll", SetLastError = true)]
        public static extern int NtQueryInformationProcess(IntPtr processHandle, int processInformationClass, IntPtr processInformation, int processInformationLength, out int returnLength);
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct PROCESS_INFORMATION {
        public IntPtr hProcess;
        public IntPtr hThread;
        public int dwProcessId;
        public int dwThreadId;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct STARTUPINFO {
        public int cb;
        public string lpReserved;
        public string lpDesktop;
        public string lpTitle;
        public int dwX;
        public int dwY;
        public int dwXSize;
        public int dwYSize;
        public int dwXCountChars;
        public int dwYCountChars;
        public int dwFillAttribute;
        public int dwFlags;
        public short wShowWindow;
        public short cbReserved2;
        public IntPtr lpReserved2;
        public IntPtr hStdInput;
        public IntPtr hStdOutput;
        public IntPtr hStdError;
    }
}
'@

Add-Type -TypeDefinition $TypeDefinition -Language CSharp

# --- Constants ---
$CREATE_SUSPENDED = 0x00000004
$PAGE_EXECUTE_READWRITE = 0x40
$ProcessBasicInformation = 0

# --- Configuration (from loader.c) ---
$TARGET_RVAS = @(0x6522D5, 0x6522E1, 0x6522DB, 0x6522B7)
$PATCH_BYTES = [byte[]]@(0x31, 0xC0, 0xC3) # xor eax, eax; ret

# --- Main Logic ---
$TargetExe = Join-Path $PSScriptRoot "LightBurn.exe"

Write-Host "[*] Target Executable: $TargetExe" -ForegroundColor Cyan

if (-not (Test-Path $TargetExe)) {
    Write-Host "[!] Error: LightBurn.exe not found in script directory." -ForegroundColor Red
    exit 1
}

$si = New-Object Win32.STARTUPINFO
$si.cb = [System.Runtime.InteropServices.Marshal]::SizeOf($si)
$pi = New-Object Win32.PROCESS_INFORMATION
$nullPtr = [IntPtr]::Zero

Write-Host "[*] Launching process suspended..."
$ret = [Win32.Native]::CreateProcess($TargetExe, $null, $nullPtr, $nullPtr, $false, $CREATE_SUSPENDED, $nullPtr, $PSScriptRoot, [ref]$si, [ref]$pi)

if (-not $ret) {
    Write-Host "[!] CreateProcess failed. Error code: $([System.Runtime.InteropServices.Marshal]::GetLastWin32Error())" -ForegroundColor Red
    exit 1
}

Write-Host "[+] Process created! PID: $($pi.dwProcessId)" -ForegroundColor Green

try {
    # Get Base Address (PEB method)
    $ptrSize = [IntPtr]::Size
    $pbiSize = if ($ptrSize -eq 8) { 48 } else { 24 } # Approx
    $pbi = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($pbiSize)
    $returnLen = 0

    Write-Host "[*] Querying Process Information (PEB)..."
    $status = [Win32.Native]::NtQueryInformationProcess($pi.hProcess, $ProcessBasicInformation, $pbi, $pbiSize, [ref]$returnLen)
    
    if ($status -eq 0) {
        $pebBaseAddress = [System.Runtime.InteropServices.Marshal]::ReadIntPtr($pbi, 8) # Offset 8 for x64
        Write-Host "[+] PEB Address: 0x$($pebBaseAddress.ToString("X"))"
        
        $imageBaseAddressOffset = 0x10 # Offset 0x10 in PEB for ImageBaseAddress
        $addrToRead = [IntPtr]::Add($pebBaseAddress, $imageBaseAddressOffset)
        
        $buffer = New-Object byte[] 8
        $bytesRead = [IntPtr]::Zero
        
        $ret = [Win32.Native]::ReadProcessMemory($pi.hProcess, $addrToRead, $buffer, 8, [ref]$bytesRead)
        if ($ret) {
            $baseAddr = [BitConverter]::ToInt64($buffer, 0)
            Write-Host "[+] Image Base Address: 0x$($baseAddr.ToString("X"))" -ForegroundColor Green
        }
        else {
            Write-Host "[!] Failed to read ImageBaseAddress. Assuming default." -ForegroundColor Yellow
            $baseAddr = 0x140000000
        }
    }
    else {
        Write-Host "[!] NtQueryInformationProcess failed. Status: $status" -ForegroundColor Red
        $baseAddr = 0x140000000
    }
    [System.Runtime.InteropServices.Marshal]::FreeHGlobal($pbi)


    # Apply Patches
    foreach ($rva in $TARGET_RVAS) {
        $targetAddr = [IntPtr]::Add([IntPtr]$baseAddr, $rva)
        Write-Host "[*] Patching at 0x$($targetAddr.ToString("X"))..."
        
        $oldProtect = 0
        $ret = [Win32.Native]::VirtualProtectEx($pi.hProcess, $targetAddr, [uint32]$PATCH_BYTES.Length, $PAGE_EXECUTE_READWRITE, [ref]$oldProtect)
        
        if ($ret) {
            $written = [IntPtr]::Zero
            $ret = [Win32.Native]::WriteProcessMemory($pi.hProcess, $targetAddr, $PATCH_BYTES, [uint32]$PATCH_BYTES.Length, [ref]$written)
            if ($ret) {
                Write-Host "    [+] Success!" -ForegroundColor Green
            }
            else {
                Write-Host "    [!] WriteProcessMemory failed: $([System.Runtime.InteropServices.Marshal]::GetLastWin32Error())" -ForegroundColor Red
            }
            $temp = 0
            [Win32.Native]::VirtualProtectEx($pi.hProcess, $targetAddr, [uint32]$PATCH_BYTES.Length, $oldProtect, [ref]$temp) | Out-Null
        }
        else {
            Write-Host "    [!] VirtualProtectEx failed: $([System.Runtime.InteropServices.Marshal]::GetLastWin32Error())" -ForegroundColor Red
        }
    }

}
finally {
    Write-Host "[*] Resuming thread..."
    [Win32.Native]::ResumeThread($pi.hThread) | Out-Null
    [Win32.Native]::CloseHandle($pi.hProcess) | Out-Null
    [Win32.Native]::CloseHandle($pi.hThread) | Out-Null
}

Write-Host "[*] Done."
