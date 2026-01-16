/**
 * LightBurn Loader - Standard Edition (Win32 API)
 * =========================================================
 * Replaces direct syscalls with standard APIs for stability.
 * Matches logic of working loader_debug.ps1
 */

#define _WIN32_WINNT 0x0600
#include <windows.h>
#include <winternl.h>

// --- Configuration ---
unsigned char ENC_TARGET[] = {0x19, 0x3C, 0x32, 0x3D, 0x21, 0x17, 0x20,
                              0x27, 0x39, 0x7B, 0x30, 0x2D, 0x30, 0x00};

// Hashing function
DWORD GetHash(const char *str) {
  DWORD hash = 5381;
  int c;
  while ((c = *str++))
    hash = ((hash << 5) + hash) + c;
  return hash;
}

// Manual Kernel32 resolution
HMODULE GetKernel32() {
#ifdef _WIN64
  PPEB pPeb = (PPEB)__readgsqword(0x60);
  PPEB_LDR_DATA pLdr = pPeb->Ldr;
  PLIST_ENTRY pHead = (PLIST_ENTRY)((BYTE *)pLdr + 0x20);
  PLIST_ENTRY pEnt = pHead->Flink->Flink->Flink;
  return *(HMODULE *)((BYTE *)pEnt + 0x20);
#else
  return NULL;
#endif
}

FARPROC GetProcAddrByHash(HMODULE hMod, DWORD reqHash) {
  PIMAGE_DOS_HEADER pDos = (PIMAGE_DOS_HEADER)hMod;
  PIMAGE_NT_HEADERS pNt = (PIMAGE_NT_HEADERS)((BYTE *)hMod + pDos->e_lfanew);
  PIMAGE_EXPORT_DIRECTORY pExp =
      (PIMAGE_EXPORT_DIRECTORY)((BYTE *)hMod +
                                pNt->OptionalHeader.DataDirectory[0]
                                    .VirtualAddress);
  DWORD *pNames = (DWORD *)((BYTE *)hMod + pExp->AddressOfNames);
  WORD *pOrdinals = (WORD *)((BYTE *)hMod + pExp->AddressOfNameOrdinals);
  DWORD *pFuncs = (DWORD *)((BYTE *)hMod + pExp->AddressOfFunctions);
  for (DWORD i = 0; i < pExp->NumberOfNames; i++) {
    char *szName = (char *)((BYTE *)hMod + pNames[i]);
    if (GetHash(szName) == reqHash) {
      WORD ordinal = pOrdinals[i];
      return (FARPROC)((BYTE *)hMod + pFuncs[ordinal]);
    }
  }
  return NULL;
}

// Function Pointers
typedef HMODULE(WINAPI *pLoadLibraryA)(LPCSTR);
typedef FARPROC(WINAPI *pGetProcAddress)(HMODULE, LPCSTR);
typedef BOOL(WINAPI *pCreateProcessW)(LPCWSTR, LPWSTR, LPSECURITY_ATTRIBUTES,
                                      LPSECURITY_ATTRIBUTES, BOOL, DWORD,
                                      LPVOID, LPCWSTR, LPSTARTUPINFOW,
                                      LPPROCESS_INFORMATION);
typedef DWORD(WINAPI *pResumeThread)(HANDLE);
typedef BOOL(WINAPI *pCloseHandle)(HANDLE);
typedef DWORD(WINAPI *pGetModuleFileNameW)(HMODULE, LPWSTR, DWORD);
typedef BOOL(WINAPI *pTerminateProcess)(HANDLE, UINT);
typedef BOOL(WINAPI *pVirtualProtectEx)(HANDLE, LPVOID, SIZE_T, DWORD, PDWORD);
typedef BOOL(WINAPI *pWriteProcessMemory)(HANDLE, LPVOID, LPCVOID, SIZE_T,
                                          SIZE_T *);
typedef BOOL(WINAPI *pReadProcessMemory)(HANDLE, LPCVOID, LPVOID, SIZE_T,
                                         SIZE_T *);
typedef NTSTATUS(NTAPI *pNtQueryInformationProcess)(HANDLE, PROCESSINFOCLASS,
                                                    PVOID, ULONG, PULONG);

// Hashes
#define HASH_LoadLibraryA 0x5FBFF0FB
#define HASH_GetProcAddress 0xCF31BB1F
#define HASH_CreateProcessW 0x16B3FE88
#define HASH_ResumeThread 0x5C8009A0
#define HASH_CloseHandle 0x5B53D325
#define HASH_GetModuleFileNameW 0x49673C1F
#define HASH_TerminateProcess 0x76872589
#define HASH_VirtualProtectEx 0x14D5684C
#define HASH_WriteProcessMemory 0xC5931818
#define HASH_ReadProcessMemory 0xD839C630

DWORD64 TARGET_RVAS[] = {0x6522D5, 0x6522E1, 0x6522DB, 0x6522B7};
const unsigned char PATCH_BYTES[] = {0x31, 0xC0, 0xC3};

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
                   LPSTR lpCmdLine, int nCmdShow) {
  HMODULE hK32 = GetKernel32();

  // Resolve Kernel32 APIs
  pGetProcAddress myGetProcAddress =
      (pGetProcAddress)GetProcAddrByHash(hK32, HASH_GetProcAddress);
  pCreateProcessW myCreateProcessW =
      (pCreateProcessW)GetProcAddrByHash(hK32, HASH_CreateProcessW);
  pResumeThread myResumeThread =
      (pResumeThread)GetProcAddrByHash(hK32, HASH_ResumeThread);
  pCloseHandle myCloseHandle =
      (pCloseHandle)GetProcAddrByHash(hK32, HASH_CloseHandle);
  pGetModuleFileNameW myGetModuleFileNameW =
      (pGetModuleFileNameW)GetProcAddrByHash(hK32, HASH_GetModuleFileNameW);
  pTerminateProcess myTerminateProcess =
      (pTerminateProcess)GetProcAddrByHash(hK32, HASH_TerminateProcess);
  pVirtualProtectEx myVirtualProtectEx =
      (pVirtualProtectEx)GetProcAddrByHash(hK32, HASH_VirtualProtectEx);
  pWriteProcessMemory myWriteProcessMemory =
      (pWriteProcessMemory)GetProcAddrByHash(hK32, HASH_WriteProcessMemory);
  pReadProcessMemory myReadProcessMemory =
      (pReadProcessMemory)GetProcAddrByHash(hK32, HASH_ReadProcessMemory);

  // Resolve Ntdll APIs
  HMODULE hNtdll = NULL;
#ifdef _WIN64
  PPEB pPeb = (PPEB)__readgsqword(0x60);
  PPEB_LDR_DATA pLdr = pPeb->Ldr;
  PLIST_ENTRY pHead = (PLIST_ENTRY)((BYTE *)pLdr + 0x20);
  PLIST_ENTRY pEnt = pHead->Flink->Flink; // ntdll is usually second
  hNtdll = *(HMODULE *)((BYTE *)pEnt + 0x20);
#endif

  pNtQueryInformationProcess myNtQuery =
      (pNtQueryInformationProcess)myGetProcAddress(hNtdll,
                                                   "NtQueryInformationProcess");

  // Decrypt Target Name
  wchar_t szTarget[14];
  for (int i = 0; i < 14; i++)
    szTarget[i] = (wchar_t)(ENC_TARGET[i] ^ 0x55);

  // Build Path
  wchar_t exePath[MAX_PATH];
  myGetModuleFileNameW(NULL, exePath, MAX_PATH);
  wchar_t *lastSlash = NULL;
  for (int i = 0; i < MAX_PATH && exePath[i]; i++)
    if (exePath[i] == L'\\')
      lastSlash = &exePath[i];
  if (lastSlash) {
    wchar_t *pDest = lastSlash + 1;
    wchar_t *pSrc = szTarget;
    while (*pSrc)
      *pDest++ = *pSrc++;
    *pDest = 0;
  }

  // Create Process
  STARTUPINFOW si;
  PROCESS_INFORMATION pi;
  for (int i = 0; i < sizeof(si); i++)
    ((BYTE *)&si)[i] = 0;
  for (int i = 0; i < sizeof(pi); i++)
    ((BYTE *)&pi)[i] = 0;
  si.cb = sizeof(si);

  if (!myCreateProcessW(exePath, NULL, NULL, NULL, FALSE, CREATE_SUSPENDED,
                        NULL, NULL, &si, &pi)) {
    // Fail silently (or with message box if debug wanted)
    return 0;
  }

  // Get Image Base
  DWORD64 baseAddr = 0;
  PROCESS_BASIC_INFORMATION pbi;
  if (myNtQuery && myNtQuery(pi.hProcess, ProcessBasicInformation, &pbi,
                             sizeof(pbi), NULL) == 0) {
    DWORD64 pebAddr = (DWORD64)pbi.PebBaseAddress;
    DWORD64 imgBaseOff = pebAddr + 0x10;
    SIZE_T br;
    myReadProcessMemory(pi.hProcess, (LPCVOID)imgBaseOff, &baseAddr,
                        sizeof(baseAddr), &br);
  }

  if (baseAddr == 0)
    baseAddr = 0x140000000;

  // Apply Patches
  for (int i = 0; i < 4; i++) {
    LPVOID targetAddr = (LPVOID)(baseAddr + TARGET_RVAS[i]);
    DWORD oldProtect;
    if (myVirtualProtectEx(pi.hProcess, targetAddr, 3, PAGE_EXECUTE_READWRITE,
                           &oldProtect)) {
      SIZE_T written;
      myWriteProcessMemory(pi.hProcess, targetAddr, PATCH_BYTES, 3, &written);
      myVirtualProtectEx(pi.hProcess, targetAddr, 3, oldProtect, &oldProtect);
    }
  }

  myResumeThread(pi.hThread);
  myCloseHandle(pi.hProcess);
  myCloseHandle(pi.hThread);
  myTerminateProcess((HANDLE)-1, 0);
  return 0;
}
