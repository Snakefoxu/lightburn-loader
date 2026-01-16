# LightBurn Patcher (Stealth Edition)

**Target:** LightBurn 2.0.05
**Version:** v2.1
**Status:** ✅ Undetected / Working

## Download
Go to the **[Releases](../../releases)** section and download **`LightBurn_Patcher_v2.1_Stealth.zip`**.

---

## Usage Instructions

This package includes two methods. Choose the one you prefer:

### Option A: Quick (Replace)
1. Extract the **`LightBurn_Patched.exe`** file.
2. Go to your installation folder (e.g., `C:\Program Files\LightBurn\`).
3. Rename your original `LightBurn.exe` to `LightBurn.bak`.
4. Move `LightBurn_Patched.exe` to that folder and rename it to **`LightBurn.exe`**.
5. Done!

### Option B: Patcher (Automatic)
If you prefer to patch your own file:
1. Extract all zip contents into the LightBurn folder.
2. Run **`Run_Patcher.cmd`** (Right Click -> Run as Administrator).
3. The script will automatically backup and patch the file for you.

---

## Technical Details
This method directly modifies the executable's byte code on disk (Disk Patching).
- **Stealth:** Does not use memory injection (which triggers antivirus alerts).
- **Safe:** Uses native Windows/PowerShell APIs.
- **Transparent:** You can review the source code in `patcher.ps1`.

## Disclaimer
For educational purposes only. If you like the software, please buy it to support the developers.
