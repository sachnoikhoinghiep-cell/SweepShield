# Security Policy

## Supported versions

Only the latest version on the `main` branch receives security fixes. The script has a self-update mechanism: run `WinTrash.ps1`, and after language selection the tool compares versions and offers an update when a new one exists.

| Version | Supported |
| --------- | ------ |
| Latest (main) | Yes |
| Older | No — please update |

## Reporting a vulnerability

**Do not open a public issue for security vulnerabilities.** Instead:

- Use the repo's **Security → Report a vulnerability** tab (private report), or
- Email: **hoanganhuet@hotmail.com** with a subject starting with `[SECURITY]`

Please describe: reproduction conditions, impact scope (which files/registry keys are touched), and the WinTrash + PowerShell versions you used. You will get a response within 7 days; confirmed vulnerabilities are patched as soon as possible with reporter credit (if desired) in the CHANGELOG.

## The tool's safety design

Principles every code change must preserve — if you observe behavior violating any of these, it is a security bug, please report it:

- **Read-only scanning.** The scan step never modifies or deletes anything on the system.
- **No automatic deletion.** Every deleted item must be manually ticked by the user and confirmed with a final y/N.
- **Always back up before deleting**: registry exports as `.reg`, scheduled task exports as `.xml`, the original PATH saved to a file, files/folders to the Recycle Bin — all under `WinTrashBackups\<timestamp>\`, restorable via `-Action restore`.
- **No data collection.** The tool sends nothing anywhere. Its only network activity is reading the `VERSION` file and downloading updates from this very GitHub repo when you accept an update.
- **Certificates are never deleted automatically** — reported only, for you to handle via `certmgr.msc`.
- The source is **a single, non-obfuscated PowerShell file** — you can (and should) read it before running.
