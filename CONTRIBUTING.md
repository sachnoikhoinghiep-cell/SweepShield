# Contributing to WinTrash

Thanks for your interest in the project. Every kind of contribution is welcome: bug reports, feature requests, documentation fixes, translations, or code.

## Reporting bugs

Use the **Bug report** template when opening an issue. The three most important pieces of information (don't skip them):

1. **Engine**: Windows PowerShell 5.1 or PowerShell 7.x (`$PSVersionTable.PSVersion`)
2. **How you ran the script**: typing `.\WinTrash.ps1` in a console, `powershell -File ...`, or right-click Run with PowerShell — the same bug may only appear in ONE launch mode (see issue #1)
3. **The verbatim error message** (copy the whole red block)

## Development environment

- Windows 10/11 with both **Windows PowerShell 5.1** (built in) and **PowerShell 7** installed — every change must work on both.
- Tests: `Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser`, then run `Invoke-Pester -Path tests\` on **both engines**.
- CI (GitHub Actions) automatically runs: parse checks on both engines, PSScriptAnalyzer (Error level), Pester.

## Hard rules when editing `WinTrash.ps1`

These are real traps the project has hit — CI and tests catch some of them, the rest is up to you:

- **Keep the UTF-8 BOM.** A file without the BOM breaks with syntax errors on PS 5.1 (read as CP1252, non-ASCII characters turn into smart-quotes). Set your editor to "UTF-8 with BOM".
- **One single file.** No splitting into modules, no runtime file dependencies.
- **Never use `.GetNewClosure()`.** The closure gets bound to a dynamic module and loses access to script-scope functions — the bug only shows when running `.\WinTrash.ps1` directly (issue #1). An AST test guards against it.
- **Test both launch modes**: `powershell -File WinTrash.ps1` AND typing `.\WinTrash.ps1` in a console. They place functions in different scopes (global vs script).
- **Console output while the background spinner is running must go through `Invoke-WithSpinnerPaused`**, not a bare `Write-Host` — otherwise spinner frames will draw over your line.
- **New UI strings must cover all 4 languages** (vi/en/zh/ru) in the `$i18n` table.
- **Never delete automatically.** Every deletion must go through the checkbox list + final y/N confirmation + backup (.reg/.xml/Recycle Bin) — this is the tool's core design principle.
- Calling native exes with quote-containing arguments (schtasks...) needs care with `PSNativeCommandArgumentPassing` on pwsh 7.3+ (see the existing code for reference).
- Self-reference the script file via `$PSCommandPath`, never hardcode the filename.

## Pull Request workflow

1. Fork / create a branch off `main` (e.g. `fix/bug-name`, `feat/feature-name`).
2. Make your changes + run Pester on both engines.
3. If behavior changes: add a `CHANGELOG.md` entry and bump `$script:WinTrashVersion` in the script + the `VERSION` file (both must match — the self-update mechanism reads `VERSION`).
4. Open a PR against `main` using the provided template. CI must be green.
5. PRs are merged via **rebase** to keep a linear history.

## Translations

The UI currently ships Vietnamese, English, 中文, and Русский. To add a new language: add a key to the `$i18n` table with the full set of strings (use the `en` key as the source) and update the language selection menu.
