# Shipping SweepShield to the Microsoft Store

Status assessment + step-by-step checklist. Items marked **[done]** are already in this repo; items marked **[you]** require the publisher's account/decisions and cannot be automated from here.

## Verdict (as of v1.4.0)

The codebase is now **technically Store-ready**: the two hard blockers (read-only install folder, self-update) are fixed, a full MSIX packaging kit lives in `store/`, and a privacy policy exists. What remains is **account work and listing content** — Partner Center registration, real icons, screenshots, age rating, and certification review. A system-cleaning utility is an allowed category, but expect extra scrutiny during certification (see "Policy risk" below).

## Blockers fixed in code **[done]**

| Problem | Fix |
|---|---|
| App wrote backups/reports/history next to the script — the MSIX install folder (`WindowsApps`) is read-only, so every cleanup would crash | Data root now falls back to `%LOCALAPPDATA%\SweepShield` when the script folder isn't writable (`Get-WritableDataRoot`); portable behavior unchanged. Override with `SWEEPSHIELD_DATA_DIR`. |
| Self-update downloads and replaces the script — Store policy 10.8.4 requires updates to ship through the Store, and the install dir is read-only anyway | Packaged mode (`WindowsApps` path or `SWEEPSHIELD_PACKAGED=1`) skips the update check entirely — the Store build makes zero network calls. |
| MSIX needs an `.exe` entry point — a `.ps1` can't be one | `store/SweepShieldLauncher.cs`: 50-line console launcher compiled with the built-in `csc.exe`, starts PowerShell against the bundled script in the same window. |
| No manifest/packaging pipeline | `store/AppxManifest.xml` (full-trust, neutral arch, 4 languages) + `store/build-msix.ps1` (compile → assets → stage → `makeappx` → optional sideload signing). |
| Store listing requires a privacy policy URL | `PRIVACY.md` (host it — the GitHub blob URL works). |

## What YOU still need to do **[you]**

1. **Partner Center developer account** — one-time US$19 (individual) / US$99 (company): https://partner.microsoft.com/dashboard. Company accounts need business verification (days to weeks).
2. ~~Reserve the app name~~ **Done** — reserved in Partner Center.
3. ~~Copy the product identity~~ **Done** — the identity is baked into `store/build-msix.ps1` as defaults (Name `TomAI.SweepShield`, Publisher `CN=431D41F0-2AFB-438F-AABB-C5BB925847C9`, display "Tom AI"). Just run:
   ```powershell
   .\store\build-msix.ps1
   ```
   Requires the Windows 10/11 SDK for `makeappx.exe` (`winget install Microsoft.WindowsSDK.10.0.26100`).
4. **Icons are done** — `store/Assets/` holds the real app icon (44×44, 150×150, 50×50, generated from `assets/icon.png`), and the launcher exe embeds `store/icon.ico`. Still needed from you: **1080p screenshots** for the listing.
5. **Test the package locally**: sign with a self-signed cert (`-PfxPath`), install the cert into Trusted People, double-click the `.msix`, and verify: scan works, cleanup writes to `%LOCALAPPDATA%\SweepShield`, elevation (UAC re-launch) works, no update prompt appears.
6. **Submission**: upload the `.msix`, fill in the listing (all 4 languages helps ranking), set the **age rating** questionnaire (utility → typically 3+), link the **privacy policy URL**, declare the `runFullTrust` capability justification ("reads/repairs registry, services, scheduled tasks and firewall rules — impossible inside the AppContainer sandbox").
7. **Pricing** — decide free vs paid (see below).

## Policy risk (read before submitting)

- **10.1 (functionality claims)**: Microsoft actively removes "PC cleaner" apps that exaggerate problems or pressure users into paying to "fix" issues. SweepShield is fine as long as the listing stays factual: it *reports* leftovers and lets the user decide — do not use fear-based marketing ("your PC is at risk!").
- **runFullTrust + registry/service modification** will trigger a manual review. The safety design (read-only scan, per-item confirmation, automatic backups, restore) is your best argument — put it in the certification notes field.
- **Elevation**: the app requests UAC elevation on demand (relaunch). That's allowed for full-trust desktop apps; do not set `allowElevation` tricks or auto-elevate at startup.
- **10.8.4 self-update ban**: already handled — the packaged build never contacts the network.

## Selling it: pricing reality check

- The Store supports paid apps (min US$0.99); Microsoft's cut for non-game apps is **15%**.
- **The code is MIT-licensed and public.** Anyone can legally take it, rebrand it, and publish it free — you cannot stop that with MIT. If the paid Store listing matters commercially, consider: keeping MIT for the GitHub version but selling the Store build for *convenience + auto-updates + support* (a common, honest model), or re-licensing future versions (you can — you hold the copyright, but contributors' PRs would need CLA/consent).
- Alternative that avoids Store friction entirely: keep it free on the Store and monetize support/pro features elsewhere.

## Store listing copy (Description, 4 languages)

Ready to paste into Partner Center → Store listings. One listing per language; the short summary line doubles as the "short description" field where offered. Kept deliberately factual — no fear-based cleaner marketing (policy 10.1).

### English (en-us)

> **Find what uninstalled apps left behind — and remove only what you choose.**
>
> SweepShield scans 18 kinds of Windows leftovers: dead PATH entries, orphaned AppData/ProgramData folders, broken services and scheduled tasks, ghost Add/Remove entries, dead shortcuts, orphaned firewall rules, stale Defender exclusions, Docker and WSL remnants, and more.
>
> Nothing is ever deleted automatically. You review every finding in a checkbox list, confirm, and only then does SweepShield act — after backing everything up first (.reg exports, task XML, Recycle Bin) with one-click restore.
>
> - Read-only scan with an HTML report
> - Pick items one by one — severity-coded High / Medium / Info
> - Every deletion backed up, fully restorable
> - Scan history: see what's new since last time
> - Safe temp cleanup, Downloads organizer, monthly scan schedule
> - Developer mode: find caches of uninstalled toolchains (npm, NuGet, Gradle...)
> - No data collection. This app makes no network connections.

### Tiếng Việt (vi)

> **Tìm những gì ứng dụng đã gỡ còn để lại — và chỉ xóa thứ bạn chọn.**
>
> SweepShield quét 18 loại tàn dư trên Windows: PATH chết, thư mục AppData/ProgramData mồ côi, service và scheduled task hỏng, mục "ma" trong Add/Remove, shortcut chết, firewall rule mồ côi, Defender exclusion lỗi thời, tàn dư Docker và WSL...
>
> Không có gì bị xóa tự động. Bạn duyệt từng mục trong danh sách checkbox, xác nhận, rồi SweepShield mới thực hiện — và luôn backup trước (.reg, XML của task, Recycle Bin) kèm khôi phục một chạm.
>
> - Quét chỉ đọc, xuất báo cáo HTML
> - Chọn từng mục — phân mức High / Đỏ, Medium / Vàng, Info / Xanh
> - Mọi thao tác xóa đều có backup, khôi phục được
> - Lịch sử quét: biết máy phát sinh gì so với lần trước
> - Dọn Temp an toàn, sắp xếp Downloads, lịch quét hàng tháng
> - Chế độ Developer: tìm cache của toolchain đã gỡ (npm, NuGet, Gradle...)
> - Không thu thập dữ liệu. Ứng dụng không kết nối mạng.

### 中文 (zh-cn)

> **找出已卸载应用的残留 — 只删除你选中的内容。**
>
> SweepShield 扫描 Windows 上 18 类残留：失效的 PATH 条目、孤立的 AppData/ProgramData 文件夹、损坏的服务和计划任务、"幽灵"卸载条目、失效快捷方式、孤立防火墙规则、过期的 Defender 排除项、Docker 和 WSL 残留等。
>
> 绝不自动删除任何内容。你在复选框列表中逐项审阅并确认后，SweepShield 才会执行 — 且始终先备份（.reg 导出、任务 XML、回收站），支持一键还原。
>
> - 只读扫描，生成 HTML 报告
> - 逐项选择 — 按 High / Medium / Info 级别着色
> - 每次删除都有备份，可完整还原
> - 扫描历史：对比上次，看新增了什么
> - 安全清理临时文件、整理下载文件夹、每月定时扫描
> - 开发者模式：发现已卸载工具链的缓存（npm、NuGet、Gradle 等）
> - 不收集任何数据。本应用不进行任何网络连接。

### Русский (ru)

> **Найдите то, что оставили удалённые программы, — и удалите только то, что выберете сами.**
>
> SweepShield сканирует 18 типов остатков в Windows: мёртвые записи PATH, осиротевшие папки AppData/ProgramData, сломанные службы и задания планировщика, «призрачные» записи в списке программ, битые ярлыки, осиротевшие правила брандмауэра, устаревшие исключения Defender, остатки Docker и WSL и другое.
>
> Ничего не удаляется автоматически. Вы просматриваете каждую находку в списке с флажками, подтверждаете — и только тогда SweepShield действует, предварительно создав резервную копию (.reg, XML заданий, Корзина) с восстановлением в один шаг.
>
> - Сканирование только для чтения + HTML-отчёт
> - Выбор по одному пункту — уровни High / Medium / Info
> - Каждое удаление с резервной копией, всё восстановимо
> - История сканирований: что изменилось с прошлого раза
> - Безопасная очистка Temp, организация «Загрузок», ежемесячное сканирование
> - Режим разработчика: кэши удалённых тулчейнов (npm, NuGet, Gradle...)
> - Никакого сбора данных. Приложение не выходит в сеть.

## Files in this repo

```
store/
  AppxManifest.xml      MSIX manifest template (placeholders stamped by the build script)
  SweepShieldLauncher.cs   console launcher (exe entry point) source
  build-msix.ps1        end-to-end package build: compile, assets, stage, pack, sign
  Assets/               app logo PNGs (rendered from assets/icon.png)
  icon.ico              multi-size icon embedded into the launcher exe
assets/icon.png         master app icon (source for all of the above)
PRIVACY.md              privacy policy for the Store listing
```
