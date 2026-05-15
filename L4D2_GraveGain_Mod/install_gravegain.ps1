#Requires -Version 5.1
<#
.SYNOPSIS
    GraveGain Mod - One-Click Windows Installer
.DESCRIPTION
    Downloads and installs Metamod:Source and SourceMod into your L4D2
    installation, then copies the GraveGain mod files into place.
    Run this script from the folder containing the mod files, OR pass
    -ModPath and -L4D2Path manually.
.PARAMETER L4D2Path
    Path to your Left 4 Dead 2 installation folder (the one containing left4dead2/).
    If omitted the script tries to auto-detect via Steam registry.
.PARAMETER ModPath
    Path to the GraveGain mod folder (contains sourcemod/ and scripts/).
    Defaults to the directory this script lives in.
.EXAMPLE
    .\install_gravegain.ps1
.EXAMPLE
    .\install_gravegain.ps1 -L4D2Path "D:\SteamLibrary\steamapps\common\Left 4 Dead 2"
#>

param(
    [string]$L4D2Path = "",
    [string]$ModPath  = $PSScriptRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$HOST_COLOR_INFO    = "Cyan"
$HOST_COLOR_OK      = "Green"
$HOST_COLOR_WARN    = "Yellow"
$HOST_COLOR_ERR     = "Red"
$HOST_COLOR_TITLE   = "Magenta"

function Write-Step   { param([string]$msg) Write-Host "`n==> $msg" -ForegroundColor $HOST_COLOR_INFO }
function Write-OK     { param([string]$msg) Write-Host "  [OK] $msg"    -ForegroundColor $HOST_COLOR_OK }
function Write-Warn   { param([string]$msg) Write-Host "  [!!] $msg"    -ForegroundColor $HOST_COLOR_WARN }
function Write-Fail   { param([string]$msg) Write-Host "  [ERROR] $msg" -ForegroundColor $HOST_COLOR_ERR; $script:_failed = $true }
function Assert-OK    { if ($script:_failed) { exit 1 } }
$script:_failed = $false

# ─────────────────────────────────────────────────────────────────────────────
#  BANNER
# ─────────────────────────────────────────────────────────────────────────────
Clear-Host
Write-Host @"
 _____ _____ _____ __ __ _____  _____ _____ _____ _____
|   __|  _  |  _  |  |  |   __|/ __  |  _  |     |   | |
|  |  |     |     |  |  |   __|    __|     |-   -|    |  |
|_____|__|__|__|__|\___/|_____|\_____| |___|_____|__|____|

        GraveGain Melee Overhaul - Windows Installer
        https://mattyjacks.com
"@ -ForegroundColor $HOST_COLOR_TITLE

Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
#  FIND L4D2
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Locating Left 4 Dead 2..."

if ($L4D2Path -eq "") {
    # Try Steam registry key (64-bit then 32-bit)
    $steamPaths = @(
        "HKCU:\SOFTWARE\Valve\Steam",
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
        "HKLM:\SOFTWARE\Valve\Steam"
    )
    $steamInstall = ""
    foreach ($key in $steamPaths) {
        if (Test-Path $key) {
            $val = (Get-ItemProperty -Path $key -ErrorAction SilentlyContinue).SteamPath
            if ($val -and (Test-Path $val)) { $steamInstall = $val; break }
        }
    }

    if ($steamInstall -ne "") {
        $candidate = Join-Path $steamInstall "steamapps\common\Left 4 Dead 2"
        if (Test-Path $candidate) { $L4D2Path = $candidate }
    }
}

if ($L4D2Path -eq "" -or -not (Test-Path $L4D2Path)) {
    Write-Warn "Could not auto-detect L4D2. Please enter the path manually."
    $L4D2Path = Read-Host "Full path to Left 4 Dead 2 folder (contains left4dead2/)"
    $L4D2Path = $L4D2Path.Trim('"').Trim("'")
}

$L4D2Game = Join-Path $L4D2Path "left4dead2"
if (-not (Test-Path $L4D2Game)) {
    Write-Fail "Could not find 'left4dead2' subfolder inside: $L4D2Path`nMake sure you point to the game root (not left4dead2 itself)."
}

Write-OK "Found: $L4D2Path"; Assert-OK

# ─────────────────────────────────────────────────────────────────────────────
#  VERIFY MOD FILES
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Verifying mod files in: $ModPath"

# .smx lives in sourcemod/plugins/ (compiled output), not scripting/
$smxFile     = Join-Path $ModPath "sourcemod\plugins\gravegain_melee_pro.smx"
# Fallback: some repos store it alongside the .sp
if (-not (Test-Path $smxFile)) {
    $smxFile = Join-Path $ModPath "sourcemod\scripting\gravegain_melee_pro.smx"
}
$scriptsDir  = Join-Path $ModPath "scripts"

if (-not (Test-Path $smxFile))    { Write-Fail "Missing compiled plugin (.smx) in sourcemod/plugins/ or sourcemod/scripting/" }
if (-not (Test-Path $scriptsDir)) { Write-Fail "Missing scripts folder: $scriptsDir" }
Assert-OK

Write-OK "Mod files present."

# ─────────────────────────────────────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────────────────────────────────────
function Download-File {
    param([string]$Url, [string]$Dest)
    Write-Host "  Downloading: $([System.IO.Path]::GetFileName($Dest)) ..." -NoNewline
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "GraveGainInstaller/1.0")
        $wc.DownloadFile($Url, $Dest)
        Write-Host " done." -ForegroundColor $HOST_COLOR_OK
    } catch {
        Write-Host ""
        Write-Fail "Download failed: $_"
    }
}

function Expand-Zip {
    param([string]$Archive, [string]$DestDir)
    # Expand-Archive is built into PowerShell 5+ (Windows 10 / Server 2016+)
    # Fall back to Shell.Application COM object for older systems
    New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
    if (Get-Command "Expand-Archive" -ErrorAction SilentlyContinue) {
        Expand-Archive -LiteralPath $Archive -DestinationPath $DestDir -Force
    } else {
        $shell = New-Object -ComObject Shell.Application
        $zip   = $shell.NameSpace($Archive)
        $dest  = $shell.NameSpace($DestDir)
        if (-not $zip)  { Write-Fail "Could not open zip: $Archive"; return }
        if (-not $dest) { Write-Fail "Could not open dest: $DestDir"; return }
        $dest.CopyHere($zip.Items(), 0x14)  # 0x14 = no UI + overwrite
    }
}

function Copy-MergingDir {
    param([string]$Src, [string]$Dst)
    New-Item -ItemType Directory -Force -Path $Dst | Out-Null
    Get-ChildItem -Path $Src -Recurse | ForEach-Object {
        $rel     = $_.FullName.Substring($Src.Length).TrimStart('\','/')
        $target  = Join-Path $Dst $rel
        if ($_.PSIsContainer) {
            New-Item -ItemType Directory -Force -Path $target | Out-Null
        } else {
            Copy-Item -Path $_.FullName -Destination $target -Force
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
#  DOWNLOAD METAMOD + SOURCEMOD (latest stable for L4D2 / Windows)
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Downloading Metamod:Source and SourceMod..."

$tmpDir = Join-Path $env:TEMP "GraveGainInstall"
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

# Cleanup temp dir on any exit
try {

# GitHub release URLs for latest stable builds (Windows .zip)
# Metamod:Source 1.12 stable
$mmUrl  = "https://github.com/alliedmodders/metamod-source/releases/download/1.12.0.1224/mmsource-1.12.0-git1224-windows.zip"
# SourceMod 1.12 stable
$smUrl  = "https://github.com/alliedmodders/sourcemod/releases/download/1.12.0.7230/sourcemod-1.12.0-git7230-windows.zip"

$mmArchive = Join-Path $tmpDir "metamod.zip"
$smArchive = Join-Path $tmpDir "sourcemod.zip"
$mmExtDir  = Join-Path $tmpDir "metamod"
$smExtDir  = Join-Path $tmpDir "sourcemod"

Download-File $mmUrl $mmArchive
Download-File $smUrl $smArchive

# ─────────────────────────────────────────────────────────────────────────────
#  EXTRACT
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Extracting archives..."

Expand-Zip $mmArchive $mmExtDir
Write-OK "Metamod extracted."

Expand-Zip $smArchive $smExtDir
Write-OK "SourceMod extracted."

# ─────────────────────────────────────────────────────────────────────────────
#  INSTALL METAMOD + SOURCEMOD
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Installing Metamod:Source into: $L4D2Game"

# Find the addons/ directory inside the Metamod extract tree
# NOTE: Copy-MergingDir copies the *contents* of $mmAddons into the dest addons/
# so we must find the addons/ folder itself, not its parent
$mmAddons = Join-Path $mmExtDir "addons"
if (-not (Test-Path $mmAddons)) {
    $mmAddons = Get-ChildItem $mmExtDir -Directory -Recurse -Filter "addons" |
                Select-Object -First 1 -ExpandProperty FullName
}
if ([string]::IsNullOrEmpty($mmAddons) -or -not (Test-Path $mmAddons)) {
    Write-Fail "Could not locate addons/ inside Metamod archive."; Assert-OK
}

# Merge contents of extracted addons/ into game addons/
Copy-MergingDir $mmAddons (Join-Path $L4D2Game "addons")
Write-OK "Metamod installed."

Write-Step "Installing SourceMod..."

foreach ($sub in @("addons", "cfg")) {
    $src = Join-Path $smExtDir $sub
    if (-not (Test-Path $src)) {
        $found = Get-ChildItem $smExtDir -Directory -Recurse -Filter $sub |
                 Select-Object -First 1 -ExpandProperty FullName
        $src = if (-not [string]::IsNullOrEmpty($found)) { $found } else { "" }
    }
    if (-not [string]::IsNullOrEmpty($src) -and (Test-Path $src)) {
        Copy-MergingDir $src (Join-Path $L4D2Game $sub)
        Write-OK "SourceMod $sub/ installed."
    }
}

# ─────────────────────────────────────────────────────────────────────────────
#  INSTALL GRAVEGAIN PLUGIN
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Installing GraveGain plugin..."

$pluginsDir = Join-Path $L4D2Game "addons\sourcemod\plugins"
New-Item -ItemType Directory -Force -Path $pluginsDir | Out-Null
Copy-Item $smxFile -Destination $pluginsDir -Force
Write-OK "gravegain_melee_pro.smx installed."

# ─────────────────────────────────────────────────────────────────────────────
#  INSTALL VSCRIPTS
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Installing VScripts..."

$l4d2Scripts = Join-Path $L4D2Game "scripts"
Copy-MergingDir $scriptsDir $l4d2Scripts
Write-OK "VScripts installed."

# ─────────────────────────────────────────────────────────────────────────────
#  CLEANUP
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Cleaning up temp files..."
Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
Write-OK "Done."

} finally {
    # Always remove temp dir even on failure
    if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue }
}

# ─────────────────────────────────────────────────────────────────────────────
#  SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor $HOST_COLOR_OK
Write-Host "  GraveGain Mod installed successfully!" -ForegroundColor $HOST_COLOR_OK
Write-Host ""
Write-Host "  Installed to: $L4D2Game" -ForegroundColor White
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    1. Start L4D2" -ForegroundColor White
Write-Host "    2. Open console (~) and type: sm version" -ForegroundColor White
Write-Host "    3. You should see SourceMod loaded." -ForegroundColor White
Write-Host "    4. In-game: Block (RClick), Shove (LClick+Block)," -ForegroundColor White
Write-Host "       hold F when Ultimate is READY to arm + fire." -ForegroundColor White
Write-Host "============================================================" -ForegroundColor $HOST_COLOR_OK
Write-Host ""

pause
