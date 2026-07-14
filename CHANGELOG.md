# Changelog

## [1.4.0] - 2026-07-14

### Added
- **Microsoft Store packaging kit** (`store/`): MSIX manifest template (full-trust, neutral arch), a tiny C# console launcher as the required exe entry point, and `build-msix.ps1` that compiles the launcher with the built-in csc.exe, generates placeholder logos, stages the layout, packs with makeappx and optionally signs for sideload testing. `STORE.md` documents the full submission checklist and policy risks; `PRIVACY.md` provides the privacy policy the listing requires.
- **Writable data root**: backups, scan history, HTML reports, Downloads logs and the ignore list now live in the script folder only when it is writable (portable mode, unchanged behavior); otherwise they fall back to `%LOCALAPPDATA%\WinTrash` (Program Files, MSIX WindowsApps). Override with the `WINTRASH_DATA_DIR` environment variable.

### Changed
- **Packaged (Store) mode** — detected via the WindowsApps install path or `WINTRASH_PACKAGED=1` — skips the self-update check entirely: updates ship through the Store and the build makes no network calls at all.

## [1.3.1] - 2026-07-12

### Fixed
- **Backup .reg/.xml overwritten when one finding deletes multiple same-named hives/views/tasks**: three backup-export sites used filenames that did not distinguish the source, so a later export overwrote the earlier one (`/y`) and restore lost data. `ProtocolKey` (key present in both HKCU and HKLM `Software\Classes`) now embeds a hive tag in the filename; `RegKeyMulti` (key alive in both the 64-bit and WOW6432Node views) embeds a view tag (`wow64`/`v<n>`); `Task` (two same-named tasks at different TaskPaths) embeds the finding index in the `task_*.xml` name, with the manifest still pointing at the right file. Verified experimentally: 2 keys in one finding produce 2 separate backup files, and `reg import` restores both.

### Other
- Updated copyright information in `LICENSE`.
- Standardized the whole project to English: code comments, finding details, error messages, README, CHANGELOG, community docs, and test descriptions. The 4-language UI (vi/en/zh/ru) is unchanged; the default language for `-Action` runs is now `en`.

## [1.3.0] - 2026-07-09

### Added
- **Docker leftovers scan** (module 17): reports what an uninstalled Docker Desktop left behind — data folders (`%LOCALAPPDATA%\Docker` holding multi-GB vhdx files, `%APPDATA%\Docker`, `%PROGRAMDATA%\Docker`, stray install folder in Program Files) and orphaned `docker-desktop`/`docker-desktop-data` WSL distro registrations (these Lxss keys are created only by Desktop, so they are scanned even with a standalone docker CLI present). `~\.docker` is reported separately as Medium because it holds registry login credentials/TLS certs/contexts. If Docker is present in any form (Desktop, Engine via the `docker`/`com.docker.service` service with a live binary, CLI on PATH), only data stores >= 1 GB are reported with the official cleanup command (`docker system prune`) as Info — never deletable.
- **WSL leftovers scan** (module 18): distro registrations in `HKCU\...\Lxss` pointing to a vanished folder on an accessible drive (High, key deleted with a .reg backup); distros on a MISSING drive (USB unplugged, BitLocker locked) are reported as Info only — no conclusion, no deletion. Unregistered `ext4.vhdx` data — both in `%LOCALAPPDATA%\wsl` and in uninstalled Store packages (Medium), the legacy WSL1 `lxss` folder, and a `DefaultDistribution` pointer referencing a dead GUID (Info, suggests `wsl --set-default`). Valid distros and installed Store packages are NOT touched; if Get-AppxPackage fails, the package group is skipped for safety with a clear Info notice.
- **"WHAT'S NEW" shown before updating**: the self-update prompt now downloads `CHANGELOG.md` from GitHub and lists the changes of ALL releases between the running and the new version (max 30 lines, long lines truncated to 160 chars) before asking y/N — you know what you are about to receive. Download/parse errors are skipped quietly and the update prompt still appears; version comparison is normalized to 4 components so a `VERSION` of `1.4` still matches a `[1.4.0]` header.

### Fixed
- **Folders > 4 GB are moved into `WinTrashBackups` instead of the Recycle Bin during cleanup**: folders over the Recycle Bin quota are PERMANENTLY deleted by the shell, silently, with no exception (`FOF_NOCONFIRMATION`) — reproduced experimentally; for tens-of-GB Docker/WSL vhdx files this broke the "every deletion is backed up" promise. Same volume is an instant rename; cross-volume copies+deletes (slower but undoable). The fallback branch for Recycle API failures also switched to `MoveDirectory` (Move-Item can't move directories across volumes on PS 5.1).
- **Docker folders removed from the Folders module** (added to the skip-list) — prevents the same path being reported by two modules and MB double-counted in the summary/HTML.

## [1.2.2] - 2026-07-07

### Fixed
- **"Write-StatusLine is not recognized" during cleanup (issue #1)**: the two scriptblocks printing √/× result lines in `Remove-SelectedFindings` used `.GetNewClosure()` - the closure gets bound to a dynamic module, and command lookup inside a module only walks *module -> global*, skipping script scope. Running the script as `.\WinTrash.ps1` in a console (functions live in script scope) hit the error on EVERY deleted item, the OK/fail counters read 0 and `cleanup.log` was empty (although deletion + backup did run); running via `-File`/right-click was fine (functions land in global scope), which is why it never surfaced. Fix: drop `GetNewClosure` - plain blocks keep the original session state, so functions and variables resolve correctly in every launch mode, on both PS 5.1 and PS 7.
- **Test suite broke with syntax errors on PS 5.1**: `tests\WinTrash.Tests.ps1` was missing its UTF-8 BOM - PS 5.1 read the file as CP1252, a few bytes of Vietnamese text turned into smart-quotes and confused the parser's string handling. Added the BOM (matching `WinTrash.ps1`); added an AST test banning `GetNewClosure` from returning.
- **Monthly schedule created from PowerShell 7 never ran**: PS 7.3+ defaults `PSNativeCommandArgumentPassing='Windows'`, which RE-escapes the hand-written `\"` inside schtasks' `/TR` -> the task stored literal `\"` around the path and silently failed every month despite reporting success at creation. Forced `Legacy` in a child scope around `schtasks /Create` (harmless on PS 5.1) - verified clean task XML on both engines.
- **Schedule pointed at the wrong file when the script was renamed**: `Invoke-FlowSchedule` hardcoded the name `WinTrash.ps1` instead of using `$PSCommandPath` like the elevation path - users keeping a file like `WinTrash (1).ps1` got a task pointing at a non-existent file, failing silently. Now uses `$PSCommandPath`.
- **Background spinner drew over the DevTrash report**: the final report block of `Invoke-ScanDevTrash` ran while the background spinner was still spinning (skipping the handshake used elsewhere) -> occasional spinner frames spliced into/misaligned the report lines. Now prints via `Invoke-WithSpinnerPaused`.
- **Esc / Enter-without-selection in the picker misreported "Console is not interactive"**: the empty array returned by `Show-CheckboxMenu` was pipeline-unwrapped into `$null` - identical to the sentinel reserved for non-interactive consoles. Comma-wrapped the return (now correctly reports "Nothing selected").

## [1.2.1] - 2026-07-06

### Added
- **OFFLINE user registry scan** (multi-user, requires admin): for users not logged in, the script temporarily loads `NTUSER.DAT` via `reg load` into a dedicated mount point (`HKU\WinTrash_Offline`), reads Run/RunOnce, then **unloads immediately** (wrapped in try/finally + GC to reliably release handles). Cleanup follows the same cycle: load -> .reg backup -> delete value -> unload (RemoveKind `OfflineRegValue`). Locked hives (user just logged in) are skipped quietly with a clear message during cleanup.

## [1.2.0] - 2026-07-06

### Added
- **Multi-user scan**: when running as Administrator on a machine with several users, the script asks whether to scan their profiles too. If accepted, coverage extends to: orphaned folders in each user's AppData (Roaming/Local/LocalLow/Programs), Start Menu + Desktop shortcuts, Startup folders, and Run/RunOnce keys via HKEY_USERS for logged-in users. Other users' items are labeled [user-name] in the picker and automatically detected as requiring Administrator to clean.

## [1.1.4] - 2026-07-06

### Fixed
- **Smooth spinner during REMOVAL too**: the removal loop uses the same background spinner as scanning; √/× result lines print via the "suspend handshake" (the spinner briefly yields the console then resumes) - slow deletions no longer freeze the UI.
- **WOW64 "twin" App Paths**: many App Paths keys are reflections between the 64-bit and WOW6432Node views - deleting the original makes the reflection vanish too, causing a phantom "does not exist" error on the second delete. Each pair is now merged into ONE item (RemoveKind RegKeyMulti) that deletes every view still present.
- **"Already gone" = success**: RegKey/RegValue check existence before deleting; keys/values that no longer exist (cleaned earlier, reflections...) count as OK instead of erroring.

## [1.1.3] - 2026-07-06

### Fixed
- **Garbled screen after pressing Enter**: 3 new defense layers - (1) `Clear-Screen` fully clears both viewport and scrollback (ESC[2J + ESC[3J) instead of Clear-Host which clears only the viewport, (2) the background spinner is wrapped in try/finally with a `Stop-LeakedSpinner` net killing stray spinners before each new screen (previously a module failing mid-way left the spinner alive, drawing over menus), (3) `Clear-PendingInput` swallows stray Enter presses in the buffer so they don't auto-answer the next prompt.

## [1.1.2] - 2026-07-06

### Added
- **Automatic Administrator elevation**: when confirming a cleanup that includes admin-only items, the script asks "open an Admin window?" - if accepted it saves the selected items, opens an Administrator window (UAC), quickly re-scans and cleans exactly those items (`-Action clean-resume`). Answering n cleans only what's possible unelevated — no more walls of "Access is denied".

### Fixed
- **Protocols deleted in the correct hives**: HKCR is a merged view of HKCU+HKLM Classes - deleting via HKCR failed mid-way with "subkey does not exist"; now deletes directly in both real hives (individual .reg backups).
- **Recycle Bin fallback**: when VisualBasic's Recycle API reports "not supported" (common for files in ProgramData), automatically switches to copy-into-backup then delete - still undoable.
- **System progress bars disabled** (`$ProgressPreference = SilentlyContinue`): cmdlets like Remove-NetFirewallRule no longer draw a blue progress block over the UI.

## [1.1.1] - 2026-07-06

### Fixed
- **Continuously smooth scan spinner**: animation moved to a background runspace (80ms/frame) - no more freezing on slow modules (Firewall ~16s). The background thread is the sole writer of the status line; modules only update text via a synchronized hashtable.
- **DevRadar/Claudefy installs display directly**: dropped the hidden-window + spinner mode; npm/npx output streams straight to the console and interactive installers (Claudefy has selection menus) work normally - previously they ran in a hidden window, waiting for keypresses while the user thought they hung.

## [1.1.0] - 2026-07-06

### Added
- **Automatic update check**: after language selection, the script compares its version with the `VERSION` file on GitHub; if newer, asks update/skip, and on accept downloads a replacement (`.bak` backup) and restarts itself. Network errors are skipped quietly.
- **Multi-screen wizard**: one clean screen per step (language -> role -> menu), banner kept on top; Back buttons at the role step (0) and the main menu (B = change language/role).

### Fixed
- **Picker no longer scrolls the screen**: fixed drawing area + hidden cursor + minimal redraws (Space redraws 1 row, movement redraws 2) - smooth like modern TUIs.

## [1.0.0] - 2026-07-06

First release — the whole toolkit merged into a single `WinTrash.ps1` file.

### Features
- **16 leftover scan modules**: PATH, EnvVars, Folders (orphaned AppData/ProgramData), Services, Startup, Tasks, Uninstall ghosts, App Paths, Shortcuts, Firewall, Defender exclusions, proxy-tool root CAs, IFEO, Native Messaging Hosts, URL Protocols, vendor registry keys.
- **Interactive cleanup**: checkbox list (↑↓/Space/A/N), severity filter (F), permanent hiding via `wintrash.ignore.json` (I). Nothing is deleted until confirmed.
- **Everything backed up before deletion**: `.reg` exports, task `.xml` files (with manifest), original PATH, Recycle Bin for files/folders → `WinTrashBackups\`.
- **Restore** (`-Action restore`): re-imports .reg files, re-registers tasks, restores PATH from a chosen backup.
- **Scan history diff**: every scan saves a snapshot to `ScanHistory\`, reporting new/gone items vs the previous run (keeps 12).
- **Safe temp cleanup**: only files older than 24h in User Temp / Windows Temp / CrashDumps.
- **Monthly scan schedule**: create/remove a Scheduled Task running `-Action scan`.
- **Developer mode**: scans 15+ toolchain caches, detects orphaned caches of uninstalled toolchains; installs DevRadar + Claudefy (spinner).
- **Downloads organizer**: loose root files only, group selection via checkboxes, undo script.
- **Multi-language UI**: Tiếng Việt / English / 中文 / Русский.
- **Terminal UI**: braille spinner, npm/cargo-style logs, true-color ANSI (immune to theme remapping), HASOFTWARE banner.
- HTML/CSV/JSON report export.

### Technical
- Single file, compatible with Windows PowerShell 5.1 + PowerShell 7, UTF-8 BOM.
- Scanning requires no Administrator; cleanup operations that need elevation are clearly reported.
- App-matching heuristics: Vietnamese diacritics removal, paths from UninstallString/DisplayIcon, running processes, LastAccessTime.
