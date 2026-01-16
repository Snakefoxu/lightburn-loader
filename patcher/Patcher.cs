/**
 * LightBurn Disk Patcher v1.1
 * Patches LightBurn.exe directly on disk
 * Proper PE RVA to File Offset conversion
 */
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.Cryptography;

namespace LightBurnPatcher
{
    class Program
    {
        // RVAs for LightBurn 2.0.05
        static readonly long[] TARGET_RVAS = { 0x6522D5, 0x6522E1, 0x6522DB, 0x6522B7 };
        static readonly byte[] PATCH_BYTES = { 0x31, 0xC0, 0xC3 }; // xor eax, eax; ret

        [STAThread]
        static void Main(string[] args)
        {
            Console.WriteLine("========================================");
            Console.WriteLine("  LightBurn Disk Patcher v1.1");
            Console.WriteLine("========================================");
            Console.WriteLine();

            string targetExe = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "LightBurn.exe");
            string backupExe = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "LightBurn.exe.backup");
            
            if (!File.Exists(targetExe))
            {
                Console.WriteLine("[ERROR] LightBurn.exe not found.");
                Pause();
                return;
            }

            // Check if patched
            long firstOffset = RvaToOffset(targetExe, TARGET_RVAS[0]);
            if (firstOffset > 0 && IsPatched(targetExe, firstOffset))
            {
                Console.WriteLine("[INFO] Already patched.");
                Console.Write("[R]e-patch | [U]ndo | [Q]uit: ");
                var key = Console.ReadKey().KeyChar;
                Console.WriteLine();
                
                if (char.ToUpper(key) == 'U')
                {
                    Restore(targetExe, backupExe);
                    return;
                }
                else if (char.ToUpper(key) != 'R') return;
            }

            // Backup
            Console.WriteLine("[*] Creating backup...");
            if (!File.Exists(backupExe))
            {
                File.Copy(targetExe, backupExe, false);
                Console.WriteLine("[OK] Backup: LightBurn.exe.backup");
            }
            else Console.WriteLine("[OK] Backup exists");

            // Hash before
            Console.WriteLine("[*] Hash before: " + Hash(targetExe).Substring(0, 16) + "...");

            // Patch
            Console.WriteLine("[*] Patching...");
            int count = 0;
            
            try
            {
                byte[] data = File.ReadAllBytes(targetExe);
                
                foreach (long rva in TARGET_RVAS)
                {
                    long offset = RvaToOffset(targetExe, rva);
                    if (offset <= 0 || offset + PATCH_BYTES.Length > data.Length)
                    {
                        Console.WriteLine("  [WARN] RVA 0x{0:X} -> invalid offset", rva);
                        continue;
                    }

                    Buffer.BlockCopy(PATCH_BYTES, 0, data, (int)offset, PATCH_BYTES.Length);
                    Console.WriteLine("  [+] RVA 0x{0:X} -> Offset 0x{1:X}", rva, offset);
                    count++;
                }

                File.WriteAllBytes(targetExe, data);
            }
            catch (Exception ex)
            {
                Console.WriteLine("[ERROR] " + ex.Message);
                Restore(targetExe, backupExe);
                return;
            }

            Console.WriteLine("[*] Hash after:  " + Hash(targetExe).Substring(0, 16) + "...");
            Console.WriteLine();
            Console.WriteLine("========================================");
            Console.WriteLine("  Done! Patches: {0}/{1}", count, TARGET_RVAS.Length);
            Console.WriteLine("========================================");
            Console.WriteLine("Run LightBurn.exe directly now.");
            
            Pause();
        }

        /// <summary>
        /// Convert RVA to file offset by parsing PE section headers
        /// </summary>
        static long RvaToOffset(string path, long rva)
        {
            try
            {
                using (var fs = new FileStream(path, FileMode.Open, FileAccess.Read))
                using (var br = new BinaryReader(fs))
                {
                    // DOS Header
                    fs.Seek(0x3C, SeekOrigin.Begin);
                    int peOffset = br.ReadInt32();

                    // PE Signature + COFF Header
                    fs.Seek(peOffset + 4, SeekOrigin.Begin);
                    ushort numSections = br.ReadUInt16();
                    fs.Seek(peOffset + 20, SeekOrigin.Begin);
                    ushort optHeaderSize = br.ReadUInt16();

                    // Section headers start after optional header
                    long sectionStart = peOffset + 24 + optHeaderSize;
                    
                    for (int i = 0; i < numSections; i++)
                    {
                        fs.Seek(sectionStart + (i * 40), SeekOrigin.Begin);
                        
                        // Read section header
                        byte[] nameBytes = br.ReadBytes(8);
                        uint virtualSize = br.ReadUInt32();
                        uint virtualAddr = br.ReadUInt32();
                        uint rawSize = br.ReadUInt32();
                        uint rawAddr = br.ReadUInt32();

                        // Check if RVA is in this section
                        if (rva >= virtualAddr && rva < virtualAddr + virtualSize)
                        {
                            return rva - virtualAddr + rawAddr;
                        }
                    }
                }
            }
            catch { }
            return -1;
        }

        static bool IsPatched(string path, long offset)
        {
            try
            {
                using (var fs = new FileStream(path, FileMode.Open, FileAccess.Read))
                {
                    byte[] buf = new byte[PATCH_BYTES.Length];
                    fs.Seek(offset, SeekOrigin.Begin);
                    fs.Read(buf, 0, buf.Length);
                    for (int i = 0; i < PATCH_BYTES.Length; i++)
                        if (buf[i] != PATCH_BYTES[i]) return false;
                    return true;
                }
            }
            catch { return false; }
        }

        static void Restore(string target, string backup)
        {
            if (!File.Exists(backup)) { Console.WriteLine("[ERROR] No backup"); Pause(); return; }
            try { File.Copy(backup, target, true); Console.WriteLine("[OK] Restored"); }
            catch (Exception ex) { Console.WriteLine("[ERROR] " + ex.Message); }
            Pause();
        }

        static string Hash(string path)
        {
            using (var sha = SHA256.Create())
            using (var fs = File.OpenRead(path))
                return BitConverter.ToString(sha.ComputeHash(fs)).Replace("-", "");
        }

        static void Pause()
        {
            Console.WriteLine();
            Console.Write("Press any key...");
            Console.ReadKey();
        }
    }
}
