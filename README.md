# <img src="assets/icon.png" width="28" alt=""> SweepShield

**A single PowerShell file** that scans 18 kinds of application leftovers on Windows and cleans them **selectively, item by item** — you tick each entry with the Space key; nothing is ever deleted in bulk automatically.

![Scanning 18 leftover types](assets/scan.png)

> **Safety philosophy:** read-only scan -> you pick each item via checkboxes -> confirm -> only then delete (always backed up to .reg/.xml/Recycle Bin first).

## Install & first run

> **Important when downloading from the internet:** Windows marks downloaded files and blocks script execution. Open PowerShell in the file's folder and unblock it first:
>
> ```powershell
> Unblock-File .\SweepShield.ps1
> ```
>
> If you hit *"running scripts is disabled on this system"*, allow signed/local scripts to run (one-time setup):
>
> ```powershell
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

```powershell
.\SweepShield.ps1
```

1. Pick a **language**: Tiếng Việt / English / 中文 / Русский
2. Pick a **role**:
   - **User** — scan & clean leftovers, organize Downloads
   - **Developer** — adds: toolchain cache scan (npm/NuGet/Gradle/pip...), installs [DevRadar](https://github.com/hasoftware/DevRadar) and [Claudefy](https://github.com/hasoftware/Claudefy) (with progress spinner)

Run without the menu:
```powershell
.\SweepShield.ps1 -Language en -Role Developer -Action scan     # scan only + HTML report
.\SweepShield.ps1 -Language en -Role User -Action clean         # scan + pick + clean
```

## Interactive cleanup (the main feature)

After scanning, every cleanable item appears in a **checkbox list**:

![Interactive picker](assets/picker.png)

| Key | Action |
|---|---|
| Arrow keys / PgUp / PgDn | Move |
| **Space** | Toggle an item |
| A / N | Select all / none |
| **F** | Filter by severity (All -> High -> Medium -> Info) |
| **I** | Hide this item forever (written to `sweepshield.ignore.json` — never reported again) |
| **Enter** | Confirm (final y/N prompt) |
| Esc | Cancel, do nothing |

The severity column is color-coded: **High** red | **Medium** yellow | **Info** blue.

**Nothing is deleted until you press Enter and type `y`.** Every cleanup creates a `SweepShieldBackups\<timestamp>\` folder containing: `.reg` exports of every deleted key/value, task `.xml` files, the original PATH, and a full log. Folders/files go to the Recycle Bin.

## The 18 leftover types scanned

| Group | Modules |
|---|---|
| Environment | Dead PATH entries, dead environment variables (JAVA_HOME...) |
| Disk | Orphaned AppData/LocalLow/ProgramData folders |
| Autostart | Services, Run keys + Startup folder, Scheduled Tasks |
| Registry | Ghost Add/Remove entries, App Paths, URL Protocols, vendor keys |
| UI | Dead shortcuts (Start Menu/Desktop) |
| **Security** | Orphaned Defender exclusions, proxy-tool root CAs (Burp/Fiddler), IFEO debugger hijacks, broken Native Messaging Hosts |
| Network | Orphaned firewall rules |
| Containers / WSL | Uninstalled Docker Desktop leftovers (data stores, `docker-desktop*` distros); orphaned WSL distros in Lxss, unregistered `ext4.vhdx` data, legacy WSL1 folders |

Severity: **High** = objectively broken (target no longer exists) | **Medium** = heuristic, needs your review | **Info** = informational. Certificates are never deleted automatically — reported only, remove manually via `certmgr.msc`.

An HTML report is exported after every scan:

![HTML report](assets/report.png)

## Bundled utilities

- **Restore** (`-Action restore` or menu): pick a backup from `SweepShieldBackups\` -> automatically re-imports `.reg` files, re-registers scheduled tasks, restores PATH.
- **Scan history diff**: every scan saves a snapshot to `ScanHistory\` (keeps 12) and reports *"+N new items, M items gone since the last scan"* — turning the tool into a system health monitor.
- **Safe temp cleanup** (`-Action temp`): deletes only files older than 24 hours in User Temp / Windows Temp / CrashDumps; locked files are skipped automatically.
- **Monthly scan schedule** (`-Action schedule`): create/remove a Scheduled Task that scans on the 1st of every month.

## Downloads organizer

Touches only **loose files at the root** of Downloads (never subfolders), groups them into Documents/Images/Videos/Installers..., you **pick which groups to apply** via checkboxes, unknown file types are left alone, and an `Undo-Downloads_*.ps1` script is always generated for rollback.

## Developer mode

- Detects 15+ toolchains; caches of **uninstalled** toolchains (orphaned Gradle, Cargo...) go into the checkbox list for cleanup; caches of toolchains **still in use** only show the official cleanup command (`npm cache clean --force`, `dotnet nuget locals all --clear`...) — never auto-deleted.
- Installs DevRadar / Claudefy via npm with a spinner, checks for Node.js >= 18, logs everything.

## Requirements & notes

- Windows PowerShell 5.1 or PowerShell 7+ (file saved as UTF-8 with BOM).
- No Administrator needed to scan; some items (services, HKLM, Machine PATH, Defender) require elevation to **clean** — failed items are reported so you can re-run elevated.
- Heuristics aren't perfect: the Medium group may contain portable apps — always read carefully before ticking.
- The `legacy\` folder holds the old standalone scripts (now merged into `SweepShield.ps1`).

## License

MIT — use, modify, and share freely.
