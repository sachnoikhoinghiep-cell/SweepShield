# SweepShield — Privacy Policy

_Last updated: 2026-07-14_

SweepShield ("the app") is a local system utility. This policy describes what data the app touches and what — if anything — leaves your machine.

## What the app does NOT do

- The app does **not collect, store, or transmit any personal data**.
- There is **no telemetry, no analytics, no advertising ID, no account**.
- Scan results, HTML reports, backups, and logs are written **only to your own disk** (the app's folder in portable mode, or `%LOCALAPPDATA%\SweepShield` in the Store build) and are never uploaded anywhere.

## What the app reads locally

To find application leftovers, the app reads (read-only during scans): the Windows registry, the file system (AppData, ProgramData, Downloads, Temp), installed services and scheduled tasks, firewall rules, Windows Defender exclusion lists, and certificate stores. Nothing it reads is sent off the device.

## Network access

- **Microsoft Store build:** makes **no network connections at all**. Updates are delivered by the Microsoft Store.
- **GitHub (portable) build:** the only network activity is an optional update check against this project's GitHub repository (`raw.githubusercontent.com`) — it downloads the `VERSION`/`CHANGELOG.md` files and, only if you accept, the new script. No data about you or your system is sent; it is a plain file download.

## Deletions and backups

Nothing is deleted without your explicit per-item selection and a final confirmation. Every deletion is backed up locally first (registry `.reg` exports, task `.xml` exports, Recycle Bin, or the app's backup folder). Backups stay on your machine under your control.

## Contact

Questions about this policy: **hoanganhuet@hotmail.com** or open an issue at the project repository.
