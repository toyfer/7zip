$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$c = Join-Path $root 'C/Util/7zipInstall/7zipInstall.c'
$mf = Join-Path $root 'C/Util/7zipInstall/7zipInstall.manifest'

function Replace-Once {
  param([string]$Path, [string]$From, [string]$To)
  $text = [IO.File]::ReadAllText($Path)
  $n = ([regex]::Matches($text, [regex]::Escape($From))).Count
  if ($n -ne 1) { throw "expected exactly 1 occurrence of '$From' in $Path, found $n" }
  [IO.File]::WriteAllText($Path, $text.Replace($From, $To))
}

function Replace-All {
  param([string]$Path, [string]$From, [string]$To, [int]$AtLeast)
  $text = [IO.File]::ReadAllText($Path)
  $n = ([regex]::Matches($text, [regex]::Escape($From))).Count
  if ($n -lt $AtLeast) { throw "expected at least $AtLeast occurrences of '$From' in $Path, found $n" }
  $text = $text.Replace($From, $To)
  if (([regex]::Matches($text, [regex]::Escape($From))).Count -ne 0) { throw "'$From' is still present in $Path" }
  [IO.File]::WriteAllText($Path, $text)
}

Replace-Once $c '#define g_AllUsers True' '#define g_AllUsers False'
Replace-Once $c 'static LPCWSTR const k_Reg_CLSID_7zip = L"CLSID\\" k_7zip_CLSID;' 'static LPCWSTR const k_Reg_CLSID_7zip = L"Software\\Classes\\CLSID\\" k_7zip_CLSID;'
Replace-Once $c 'static LPCWSTR const k_Reg_CLSID_7zip_Inproc = L"CLSID\\" k_7zip_CLSID L"\\InprocServer32";' 'static LPCWSTR const k_Reg_CLSID_7zip_Inproc = L"Software\\Classes\\CLSID\\" k_7zip_CLSID L"\\InprocServer32";'
Replace-Once $c '    #define USE_7ZIP_32_DLL' '    // #define USE_7ZIP_32_DLL'
Replace-Once $c 'SetRegKey_Path2(HKEY_LOCAL_MACHINE);' '/* SetRegKey_Path2(HKEY_LOCAL_MACHINE); */'
Replace-Once $c 'MyRegistry_QueryString2(HKEY_LOCAL_MACHINE, L"Software\\Microsoft\\Windows\\CurrentVersion", L"ProgramFilesDir", path)' '(SHGetFolderPathW(0, CSIDL_LOCAL_APPDATA, NULL, SHGFP_TYPE_CURRENT, path) != S_OK)'
Replace-All $c 'HKEY_LOCAL_MACHINE' 'HKEY_CURRENT_USER' 3
Replace-All $c 'HKEY_CLASSES_ROOT' 'HKEY_CURRENT_USER' 3
Replace-Once $mf 'level="requireAdministrator"' 'level="asInvoker"'

Write-Host 'per-user installer patch applied'
