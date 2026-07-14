# Pester 5 tests for SweepShield.ps1's pure functions
# Run: Invoke-Pester -Path tests\
# Mechanism: set SWEEPSHIELD_TEST=1 then dot-source the script -> loads functions only, main does not run.

BeforeAll {
    $env:SWEEPSHIELD_TEST = '1'
    . (Join-Path $PSScriptRoot '..\SweepShield.ps1')
}

AfterAll {
    Remove-Item Env:\SWEEPSHIELD_TEST -ErrorAction SilentlyContinue
}

Describe 'Remove-Diacritics' {
    It 'strips Vietnamese diacritics: Cốc Cốc -> Coc Coc' {
        Remove-Diacritics -Text 'Cốc Cốc' | Should -Be 'Coc Coc'
    }
    It 'handles the đ/Đ letters' {
        Remove-Diacritics -Text 'Đường dẫn' | Should -Be 'Duong dan'
    }
    It 'leaves ASCII strings untouched' {
        Remove-Diacritics -Text 'Hello World 123' | Should -Be 'Hello World 123'
    }
}

Describe 'Get-NameTokens' {
    It 'tokenizes and lowercases' {
        Get-NameTokens -Text 'Adobe Photoshop 2025' | Should -Contain 'adobe'
        Get-NameTokens -Text 'Adobe Photoshop 2025' | Should -Contain 'photoshop'
    }
    It 'removes stop-words' {
        Get-NameTokens -Text 'The Software Company Inc' | Should -Not -Contain 'the'
        Get-NameTokens -Text 'The Software Company Inc' | Should -Not -Contain 'software'
    }
    It 'strips diacritics before tokenizing: Cốc Cốc -> coc' {
        Get-NameTokens -Text 'Cốc Cốc' | Should -Contain 'coc'
    }
    It 'empty string returns an empty array' {
        @(Get-NameTokens -Text '') | Should -HaveCount 0
    }
}

Describe 'Resolve-CommandPath' {
    It 'quoted path + arguments' {
        Resolve-CommandPath -CommandLine '"C:\Program Files\App\app.exe" --flag' |
            Should -Be 'C:\Program Files\App\app.exe'
    }
    It 'real unquoted path (cmd.exe exists)' {
        $result = Resolve-CommandPath -CommandLine "$env:SystemRoot\System32\cmd.exe /c echo hi"
        $result | Should -Be "$env:SystemRoot\System32\cmd.exe"
    }
    It 'does not crash on quotes mid-command (cmd /c "rmdir" bug)' {
        { Resolve-CommandPath -CommandLine 'C:\App\run.exe \c "rmdir \S \Q C:\x"' } | Should -Not -Throw
    }
    It 'unquoted path with spaces, exe gone -> caught by the .exe suffix' {
        Resolve-CommandPath -CommandLine 'C:\Program Files\Gone App\gone.exe %1' |
            Should -Be 'C:\Program Files\Gone App\gone.exe'
    }
    It 'empty string returns null' {
        Resolve-CommandPath -CommandLine '' | Should -BeNullOrEmpty
    }
}

Describe 'Test-ExeMissing' {
    It 'existing file -> false' {
        Test-ExeMissing -ExePath "$env:SystemRoot\System32\cmd.exe" | Should -BeFalse
    }
    It 'non-existent file -> true' {
        Test-ExeMissing -ExePath 'C:\definitely\not\here\ghost.exe' | Should -BeTrue
    }
    It 'path with invalid characters -> false (no false positive)' {
        Test-ExeMissing -ExePath 'C:\App\x.exe \c "rm"' | Should -BeFalse
    }
    It 'empty string -> false' {
        Test-ExeMissing -ExePath '' | Should -BeFalse
    }
}

Describe 'ConvertTo-RegExePath' {
    It 'HKLM: -> HKEY_LOCAL_MACHINE' {
        ConvertTo-RegExePath -PSPath 'HKLM:\SOFTWARE\Test' | Should -Be 'HKEY_LOCAL_MACHINE\SOFTWARE\Test'
    }
    It 'HKCU: -> HKEY_CURRENT_USER' {
        ConvertTo-RegExePath -PSPath 'HKCU:\Environment' | Should -Be 'HKEY_CURRENT_USER\Environment'
    }
    It 'strips the Registry:: prefix' {
        ConvertTo-RegExePath -PSPath 'Registry::HKEY_CLASSES_ROOT\zax' | Should -Be 'HKEY_CLASSES_ROOT\zax'
    }
    It 'strips the Microsoft.PowerShell.Core prefix' {
        ConvertTo-RegExePath -PSPath 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\X' |
            Should -Be 'HKEY_LOCAL_MACHINE\X'
    }
}

Describe 'Get-FindingId' {
    It 'produces a stable Category|Name|Target ID' {
        $f = [PSCustomObject]@{ Category = 'Path'; Name = 'User #3'; Target = 'C:\x' }
        Get-FindingId $f | Should -Be 'Path|User #3|C:\x'
    }
}

Describe 'Get-SeverityColor' {
    It 'High -> Red'      { Get-SeverityColor -Severity 'High'   | Should -Be ([ConsoleColor]::Red) }
    It 'Medium -> Yellow' { Get-SeverityColor -Severity 'Medium' | Should -Be ([ConsoleColor]::Yellow) }
    It 'Info -> Blue'     { Get-SeverityColor -Severity 'Info'   | Should -Be ([ConsoleColor]::Blue) }
}

Describe 'Get-ChangelogForUpdate' {
    BeforeAll {
        $sampleMd = @"
# Changelog

## [1.3.0] - 2026-07-09

### Added
- **Docker scan**: detects Docker Desktop leftovers.

## [1.2.2] - 2026-07-07

### Fixed
- **Bug X**: now fixed.

## [1.0.0] - 2026-07-06

First release.
"@
    }
    It 'only includes releases within (Current, Remote]' {
        $r = @(Get-ChangelogForUpdate -Markdown $sampleMd -Current ([version]'1.2.2') -Remote ([version]'1.3.0'))
        ($r -join "`n") | Should -Match '\[1\.3\.0\]'
        ($r -join "`n") | Should -Not -Match '\[1\.2\.2\]'
        ($r -join "`n") | Should -Not -Match '\[1\.0\.0\]'
    }
    It 'aggregates all releases when the user skips several versions' {
        $r = @(Get-ChangelogForUpdate -Markdown $sampleMd -Current ([version]'1.0.0') -Remote ([version]'1.3.0'))
        ($r -join "`n") | Should -Match '\[1\.3\.0\]'
        ($r -join "`n") | Should -Match '\[1\.2\.2\]'
        ($r -join "`n") | Should -Not -Match '\[1\.0\.0\]'
    }
    It 'strips ** bold markdown but keeps the content' {
        $r = @(Get-ChangelogForUpdate -Markdown $sampleMd -Current ([version]'1.2.2') -Remote ([version]'1.3.0'))
        ($r -join "`n") | Should -Not -Match '\*\*'
        ($r -join "`n") | Should -Match 'Docker scan'
        ($r -join "`n") | Should -Match 'Added:'
    }
    It 'empty/null markdown -> empty list, no throw' {
        @(Get-ChangelogForUpdate -Markdown '' -Current ([version]'1.0') -Remote ([version]'2.0')) | Should -HaveCount 0
        @(Get-ChangelogForUpdate -Markdown $null -Current ([version]'1.0') -Remote ([version]'2.0')) | Should -HaveCount 0
    }
    It 'invalid version headers are skipped without crashing' {
        $bad = "## [abc] - broken`n- junk line`n## [2.0.0]`n- real line"
        $r = @(Get-ChangelogForUpdate -Markdown $bad -Current ([version]'1.0') -Remote ([version]'2.0.0'))
        ($r -join "`n") | Should -Match 'real line'
        ($r -join "`n") | Should -Not -Match 'junk line'
    }
    It 'non-version ## sections AFTER a selected release do not leak into the notes' {
        $md2 = "## [1.5.0]`n- new item`n## [Unreleased]`n- not released`n## Notes`n- misc"
        $r = @(Get-ChangelogForUpdate -Markdown $md2 -Current ([version]'1.0') -Remote ([version]'2.0'))
        ($r -join "`n") | Should -Match 'new item'
        ($r -join "`n") | Should -Not -Match 'not released'
        ($r -join "`n") | Should -Not -Match 'misc'
    }
    It 'keep-a-changelog style link-reference lines are dropped' {
        $md3 = "## [1.5.0]`n- new item`n[1.5.0]: https://example.com/diff"
        $r = @(Get-ChangelogForUpdate -Markdown $md3 -Current ([version]'1.0') -Remote ([version]'2.0'))
        ($r -join "`n") | Should -Not -Match 'example.com'
    }
    It '2-component VERSION still matches a 3-component header (1.4 vs [1.4.0])' {
        $md4 = "## [1.4.0]`n- new release content"
        $r = @(Get-ChangelogForUpdate -Markdown $md4 -Current ([version]'1.3.0') -Remote ([version]'1.4'))
        ($r -join "`n") | Should -Match 'new release content'
    }
}

Describe 'ConvertTo-PaddedVersion' {
    It 'pads to 4 components, missing ones become 0' {
        ConvertTo-PaddedVersion ([version]'1.4') | Should -Be ([version]'1.4.0.0')
        ConvertTo-PaddedVersion ([version]'1.4.0') | Should -Be ([version]'1.4.0.0')
        ConvertTo-PaddedVersion ([version]'2.0.1.7') | Should -Be ([version]'2.0.1.7')
    }
    It '1.4 and 1.4.0 compare equal after normalization' {
        (ConvertTo-PaddedVersion ([version]'1.4')) -eq (ConvertTo-PaddedVersion ([version]'1.4.0')) | Should -BeTrue
    }
}

Describe 'Scan module list' {
    It 'has exactly 18 modules, including Docker and WSL' {
        @($scanModules).Count | Should -Be 18
        @($scanModules | ForEach-Object { $_.Name }) | Should -Contain 'Docker'
        @($scanModules | ForEach-Object { $_.Name }) | Should -Contain 'WSL'
    }
}

Describe 'Regression issue #1: GetNewClosure is banned' {
    It 'SweepShield.ps1 contains no .GetNewClosure() calls' {
        # GetNewClosure binds a scriptblock to a dynamic module; command lookup inside a
        # module only walks module -> global, SKIPPING script scope. Running the script as
        # `.\SweepShield.ps1` (functions live in script scope, unlike -File which puts them
        # in global) makes every script function "disappear" inside the closure ->
        # "Write-StatusLine is not recognized" mid-cleanup (issue #1). Plain blocks keep
        # the original session state, which is all we need.
        $tokens = $null; $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $PSScriptRoot '..\SweepShield.ps1'), [ref]$tokens, [ref]$errors)
        $calls = $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.InvokeMemberExpressionAst] -and
            $node.Member -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
            $node.Member.Value -eq 'GetNewClosure'
        }, $true)
        $calls | Should -HaveCount 0
    }
}
