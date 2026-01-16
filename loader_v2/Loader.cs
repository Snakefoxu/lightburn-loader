using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace LightBurnLoader
{
    class Program
    {
        // --- Configuration ---
        // RVAs for LightBurn 2.0.05
        static readonly long[] TARGET_RVAS = { 0x6522D5, 0x6522E1, 0x6522DB, 0x6522B7 };
        static readonly byte[] PATCH_BYTES = { 0x31, 0xC0, 0xC3 }; // xor eax, eax; ret

        // --- P/Invoke definitions ---
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool CreateProcess(string lpApplicationName, string lpCommandLine, IntPtr lpProcessAttributes, IntPtr lpThreadAttributes, bool bInheritHandles, uint dwCreationFlags, IntPtr lpEnvironment, string lpCurrentDirectory, ref STARTUPINFO lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool VirtualProtectEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flNewProtect, out uint lpflOldProtect);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpAddress, byte[] lpBuffer, uint nSize, out IntPtr lpNumberOfBytesWritten);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpAddress, [Out] byte[] lpBuffer, int dwSize, out IntPtr lpNumberOfBytesRead);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern uint ResumeThread(IntPtr hThread);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool CloseHandle(IntPtr hObject);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool TerminateProcess(IntPtr hProcess, uint uExitCode);

        [DllImport("ntdll.dll", SetLastError = true)]
        static extern int NtQueryInformationProcess(IntPtr processHandle, int processInformationClass, IntPtr processInformation, int processInformationLength, out int returnLength);

        [StructLayout(LayoutKind.Sequential)]
        struct PROCESS_INFORMATION
        {
            public IntPtr hProcess;
            public IntPtr hThread;
            public int dwProcessId;
            public int dwThreadId;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct STARTUPINFO
        {
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

        const uint CREATE_SUSPENDED = 0x00000004;
        const uint PAGE_EXECUTE_READWRITE = 0x40;
        const int ProcessBasicInformation = 0;

        [STAThread]
        static void Main()
        {
            string targetExe = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "LightBurn.exe");

            if (!File.Exists(targetExe))
            {
                MessageBox.Show("LightBurn.exe not found in current directory.", "Loader Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            STARTUPINFO si = new STARTUPINFO();
            si.cb = Marshal.SizeOf(si);
            PROCESS_INFORMATION pi = new PROCESS_INFORMATION();

            bool ret = CreateProcess(targetExe, null, IntPtr.Zero, IntPtr.Zero, false, CREATE_SUSPENDED, IntPtr.Zero, AppDomain.CurrentDomain.BaseDirectory, ref si, out pi);

            if (!ret)
            {
                MessageBox.Show("Failed to create process.", "Loader Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            try
            {
                long baseAddr = 0;

                // 1. Try to get PEB
                int pbiSize = IntPtr.Size == 8 ? 48 : 24;
                IntPtr pbi = Marshal.AllocHGlobal(pbiSize);
                int returnLen = 0;

                int status = NtQueryInformationProcess(pi.hProcess, ProcessBasicInformation, pbi, pbiSize, out returnLen);

                if (status == 0) // STATUS_SUCCESS
                {
                    IntPtr pebBaseAddress = Marshal.ReadIntPtr(pbi, 8); // Offset 8 for x64
                    IntPtr imageBaseAddressOffset = (IntPtr)(pebBaseAddress.ToInt64() + 0x10);
                    
                    byte[] buffer = new byte[8];
                    IntPtr bytesRead;
                    if (ReadProcessMemory(pi.hProcess, imageBaseAddressOffset, buffer, 8, out bytesRead))
                    {
                        baseAddr = BitConverter.ToInt64(buffer, 0);
                    }
                }
                Marshal.FreeHGlobal(pbi);

                if (baseAddr == 0) baseAddr = 0x140000000; // Fallback

                // 2. Apply Patches
                foreach (long rva in TARGET_RVAS)
                {
                    IntPtr targetAddr = (IntPtr)(baseAddr + rva);
                    uint oldProtect;
                    
                    if (VirtualProtectEx(pi.hProcess, targetAddr, (uint)PATCH_BYTES.Length, PAGE_EXECUTE_READWRITE, out oldProtect))
                    {
                        IntPtr written;
                        WriteProcessMemory(pi.hProcess, targetAddr, PATCH_BYTES, (uint)PATCH_BYTES.Length, out written);
                        uint temp;
                        VirtualProtectEx(pi.hProcess, targetAddr, (uint)PATCH_BYTES.Length, oldProtect, out temp);
                    }
                }
            }
            catch (Exception ex)
            {
               MessageBox.Show("Error applying patches: " + ex.Message, "Loader", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
            finally
            {
                ResumeThread(pi.hThread);
                CloseHandle(pi.hProcess);
                CloseHandle(pi.hThread);
            }
        }
    }
}
