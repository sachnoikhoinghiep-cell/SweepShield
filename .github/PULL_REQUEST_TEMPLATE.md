# Description

<!-- What changed and why? If this fixes an issue, write: Fixes #number -->

## Type of change

- [ ] Bugfix
- [ ] New feature
- [ ] Documentation / translation
- [ ] Refactor (no behavior change)

## Checklist

- [ ] Tested on **Windows PowerShell 5.1** and **PowerShell 7**
- [ ] Tested **both launch modes**: typing `.\WinTrash.ps1` in a console AND `powershell -File WinTrash.ps1` (they place functions in different scopes — see CONTRIBUTING.md)
- [ ] `.ps1` files keep their **UTF-8 BOM**
- [ ] `Invoke-Pester -Path tests\` is green on both engines
- [ ] New UI strings (if any) cover all 4 languages vi/en/zh/ru
- [ ] Behavior change: `CHANGELOG.md` updated + version bumped in the script and the `VERSION` file
- [ ] Safety principles intact: no automatic deletion; deletions go through checkbox + confirmation + backup
