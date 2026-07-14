<#
.SYNOPSIS
    Builds the Microsoft Store (MSIX) package for SweepShield.

.DESCRIPTION
    Steps:
      1. Compiles SweepShieldLauncher.exe from SweepShieldLauncher.cs (csc.exe ships with
         the .NET Framework on every Windows box - no SDK install needed).
      2. Generates placeholder logo PNGs with System.Drawing if store\Assets is empty
         (replace them with real artwork before submitting!).
      3. Stages the package layout (launcher + SweepShield.ps1 + manifest + assets)
         and stamps the Identity/Publisher/Version placeholders in AppxManifest.xml.
      4. Packs with makeappx.exe (Windows 10/11 SDK) if available.
      5. Signs with signtool.exe if -PfxPath is given (only needed for local
         sideload testing - Store submissions are signed by Microsoft).

.EXAMPLE
    .\build-msix.ps1 -IdentityName '12345Publisher.SweepShield' -Publisher 'CN=xxxx-...' -PublisherDisplay 'My Studio'
    # values come from Partner Center > Product management > Product identity
#>
[CmdletBinding()]
param(
    # Defaults = the reserved product identity from Partner Center
    [string]$IdentityName     = 'TomAI.SweepShield',
    [string]$Publisher        = 'CN=431D41F0-2AFB-438F-AABB-C5BB925847C9',
    [string]$PublisherDisplay = 'Tom AI',
    [string]$PfxPath,
    [securestring]$PfxPassword
)

$ErrorActionPreference = 'Stop'
$storeDir = $PSScriptRoot
$repoRoot = Split-Path $storeDir -Parent
$stage    = Join-Path $storeDir 'layout'
$outDir   = Join-Path $storeDir 'out'

$version4 = ((Get-Content (Join-Path $repoRoot 'VERSION') -Raw).Trim() + '.0')

# ---- 1. Compile the launcher --------------------------------------------------
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path $csc)) { $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }
if (-not (Test-Path $csc)) { throw 'csc.exe not found - .NET Framework 4.x is required.' }
$launcher = Join-Path $storeDir 'SweepShieldLauncher.exe'
$icoArg = @()
$ico = Join-Path $storeDir 'icon.ico'
if (Test-Path $ico) { $icoArg = @("/win32icon:$ico") }
& $csc /nologo /target:exe /platform:anycpu /out:$launcher @icoArg (Join-Path $storeDir 'SweepShieldLauncher.cs')
Write-Host "√ Launcher compiled: $launcher" -ForegroundColor Green

# ---- 2. Generate placeholder assets if missing --------------------------------
$assets = Join-Path $storeDir 'Assets'
if (-not (Test-Path $assets)) { New-Item -ItemType Directory -Path $assets | Out-Null }
Add-Type -AssemblyName System.Drawing
function New-Logo {
    param([int]$W, [int]$H, [string]$Path)
    if (Test-Path $Path) { return }
    $bmp = New-Object System.Drawing.Bitmap($W, $H)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.Clear([System.Drawing.Color]::FromArgb(255, 16, 48, 43))
    $fontSize = [Math]::Max(8, [int]($H * 0.34))
    $font = New-Object System.Drawing.Font('Segoe UI', $fontSize, [System.Drawing.FontStyle]::Bold)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 0, 200, 83))
    $fmt = New-Object System.Drawing.StringFormat
    $fmt.Alignment = 'Center'; $fmt.LineAlignment = 'Center'
    $g.DrawString('WT', $font, $brush, (New-Object System.Drawing.RectangleF(0, 0, $W, $H)), $fmt)
    $g.Dispose()
    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "  generated placeholder $([System.IO.Path]::GetFileName($Path)) - replace with real artwork before submitting" -ForegroundColor Yellow
}
New-Logo -W 150 -H 150 -Path (Join-Path $assets 'Square150x150Logo.png')
New-Logo -W 44  -H 44  -Path (Join-Path $assets 'Square44x44Logo.png')
New-Logo -W 50  -H 50  -Path (Join-Path $assets 'StoreLogo.png')

# ---- 3. Stage the package layout ----------------------------------------------
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage, (Join-Path $stage 'Assets') | Out-Null
Copy-Item (Join-Path $repoRoot 'SweepShield.ps1') $stage
Copy-Item (Join-Path $repoRoot 'LICENSE') $stage
Copy-Item $launcher $stage
Copy-Item (Join-Path $assets '*.png') (Join-Path $stage 'Assets')
$manifest = Get-Content (Join-Path $storeDir 'AppxManifest.xml') -Raw
$manifest = $manifest.Replace('__IDENTITY_NAME__', $IdentityName).
                      Replace('__PUBLISHER__', $Publisher).
                      Replace('__PUBLISHER_DISPLAY__', $PublisherDisplay).
                      Replace('__VERSION__', $version4)
Set-Content -LiteralPath (Join-Path $stage 'AppxManifest.xml') -Value $manifest -Encoding UTF8
Write-Host "√ Layout staged: $stage (version $version4)" -ForegroundColor Green

# ---- 4. Pack -------------------------------------------------------------------
$makeappx = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\makeappx.exe" -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending | Select-Object -First 1
if (-not $makeappx) {
    Write-Warning 'makeappx.exe not found (install the Windows 10/11 SDK). Layout is staged - pack later with:'
    Write-Host "  makeappx pack /d `"$stage`" /p `"$outDir\SweepShield_$version4.msix`"" -ForegroundColor Cyan
    return
}
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$msix = Join-Path $outDir "SweepShield_$version4.msix"
& $makeappx.FullName pack /o /d $stage /p $msix | Out-Null
Write-Host "√ Packed: $msix" -ForegroundColor Green

# ---- 5. Sign (sideload testing only; the Store signs submissions itself) -------
if ($PfxPath) {
    $signtool = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\signtool.exe" -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1
    if (-not $signtool) { Write-Warning 'signtool.exe not found - skipping signing.'; return }
    $plain = if ($PfxPassword) { [System.Runtime.InteropServices.Marshal]::PtrToStringUni([System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($PfxPassword)) } else { '' }
    & $signtool.FullName sign /fd SHA256 /f $PfxPath /p $plain $msix
    Write-Host '√ Signed for sideload testing.' -ForegroundColor Green
} else {
    Write-Host 'Note: unsigned package - fine for Store submission (Microsoft signs it), required to sign only for local sideload testing.' -ForegroundColor DarkGray
}
