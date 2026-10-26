# 7-Zip x64 ユーザー権限インストーラ（per-user）

管理者権限のない端末でも AES-256 の .7z を作成・展開できるようにするための 7-Zip ビルドです。
上流 [ip7z/7zip](https://github.com/ip7z/7zip) のソースに最小限のパッチを当て、GitHub Actions で `7z<version>-x64-peruser.exe` を生成してリリースに添付します。

## インストーラの挙動

| 項目 | 上流の既定 | 本ビルド |
| --- | --- | --- |
| インストール先 | `C:\Program Files\7-Zip` | `%LOCALAPPDATA%\7-Zip` |
| 書き込むレジストリ | HKLM / HKCR | HKCU のみ |
| 実行レベル | requireAdministrator | asInvoker |
| 32bit シェル拡張 | 7-zip32.dll を登録 | 登録しない |
| スタートメニュー | 共有プログラム | ユーザーのプログラム |

## パッチ内容

`patch/per-user-installer.ps1` が `C/Util/7zipInstall/7zipInstall.c` と `7zipInstall.manifest` に対して、一致件数を検証しながら次の置換を行います。想定した文字列が見つからない場合はビルドを失敗させるので、上流が変わったときに黙って壊れたインストーラが出ることはありません。

1. `#define g_AllUsers True` を `False` に変更（HKLM 書き込みと共有スタートメニューを無効化）
2. `k_Reg_CLSID_7zip` と `k_Reg_CLSID_7zip_Inproc` に `Software\Classes\` を付与（HKCR 相当を HKCU 配下に作る）
3. `USE_7ZIP_32_DLL` を無効化（32bit 版 DLL を同梱しないため）
4. `SetRegKey_Path2(HKEY_LOCAL_MACHINE);` をコメントアウト
5. 既定インストール先を `ProgramFilesDir` から `SHGetFolderPathW(CSIDL_LOCAL_APPDATA)` に変更
6. `HKEY_LOCAL_MACHINE` と `HKEY_CLASSES_ROOT` を `HKEY_CURRENT_USER` に置換
7. マニフェストの `requireAdministrator` を `asInvoker` に変更

## ビルド

`.github/workflows/peruser-installer.yml` が windows-2022 上で x64 のみをビルドします。

- バージョンは `C/7zVersion.h` の `MY_VERSION_NUMBERS` から読み取り、同じ名前のタグでリリースを作成します（例: `26.05`）
- 成果物は `7z<version>-x64-peruser.exe`（`7zipInstall.exe` に 7z アーカイブを連結した SFX）
- `7-zip.chm`、`Uninstall.exe`、`Lang`、`descript.ion` は公式インストーラから取り出して同梱します

## 既知の制約

- 32bit アプリの右クリックメニュー（`7-zip32.dll`）は登録されません。エクスプローラ（64bit）のシェル拡張は `7-zip.dll` で動作します。
- 同梱の `Uninstall.exe` は HKLM 前提のため、アンインストール時に HKCU 側の項目が残る場合があります。
