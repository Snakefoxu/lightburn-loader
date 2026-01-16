# LightBurn Patcher (Disk Method)

**Current Version:** v2.0 (Stealth Edition)
**Target:** LightBurn 2.0.05
**Status:** ✅ Undetected

## Methods

### v2.0 - Stealth (Recommended)
- **Type:** PowerShell Script (`patcher.ps1`)
- **Launcher:** `Run_Patcher.cmd` (Auto-Elevate)
- **Detection:** 0/70 (Uses native Windows tools, no unsigned binaries)
- **Mechanism:** Direct disk patching (Offset calculation from PE Headers).

### v1.1 - Legacy
- **Type:** C# Binary (`LightBurn_Patcher.exe`)
- **Status:** Detected by heuristics (False Positive) but functional.

## Usage (v2.0)
1. Download `LightBurn_Patcher_v2.0_Stealth.zip` from Releases.
2. Extract to `C:\Program Files\LightBurn\`.
3. Run **`Run_Patcher.cmd`** as Admin.
4. Enjoy.

## Dev Info
- `patcher/patcher.ps1`: Core logic (PE Parsing + Patching).
- `patcher/Run_Patcher.cmd`: Elevates privileges and calls PS1.

## Disclaimer
For educational purposes only. Buying the software supports the developers.
