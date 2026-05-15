#Requires -Version 5.1
<#
.SYNOPSIS
    GraveGain Mod - Windows Uninstaller
.DESCRIPTION
    Removes the GraveGain plugin and VScripts from your L4D2 installation.
    Optionally removes SourceMod and Metamod:Source entirely.
.PARAMETER L4D2Path
    Path to your Left 4 Dead 2 installation folder (parent of left4dead2/).
    Auto-detected via Steam registry if omitted.
.PARAMETER RemoveSourceMod
    If specified, also removes SourceMod and all its plugins/data.
.PARAMETER RemoveMetamod
    If specified, also removes Metamod:Source. Implies -RemoveSourceMod.
#>

param(
    [string]$L4D2Path       = "",
    [switch]$RemoveSourceMod,
    [switch]$RemoveMetamod
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step { param([string]$msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-OK   { param([string]$msg) Write-Host "  [OK] $msg"    -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "  [!!] $msg"    -ForegroundColor Yellow }
function Write-Fail { param([string]$msg) Write-Host "  [ERROR] $msg" -ForegroundColor Red; $script:_failed = $true }
function Assert-OK  { if ($script:_failed) { exit 1 } }
$script:_failed = $false

function Remove-IfExists {
    param([string]$Path, [string]$Label)
    if (Test-Path $Path) {
        Remove-Item $Path -Recurse -Force
        Write-OK "Removed: $Label"
    } else {
        Write-Warn "Not found (skipping): $Label"
    }
}

# ─────────────────────────────────────────────────────────────────────────────
#  Banner
# ─────────────────────────────────────────────────────────────────────────────
Clear-Host
Write-Host @"
 _____ _____ _____ __ __ _____  _____ _____ _____ _____
|   __|  _  |  _  |  |  |   __|/ __  |  _  |     |   | |
|  |  |     |     |  |  |   __|    __|     |-   -|    |  |
|_____|__|__|__|__|\___/|_____|\_____| |___|_____|__|____|

        GraveGain Melee Overhaul - Windows Uninstaller
"@ -ForegroundColor Magenta

# ─────────────────────────────────────────────────────────────────────────────
#  Find L4D2
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Locating Left 4 Dead 2..."

if ($L4D2Path -eq "") {
    $steamPaths = @(
        "HKCU:\SOFTWARE\Valve\Steam",
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
        "HKLM:\SOFTWARE\Valve\Steam"
    )
    foreach ($key in $steamPaths) {
        if (Test-Path $key) {
            $val = (Get-ItemProperty -Path $key -ErrorAction SilentlyContinue).SteamPath
            if ($val -and (Test-Path $val)) {
                $candidate = Join-Path $val "steamapps\common\Left 4 Dead 2"
                if (Test-Path $candidate) { $L4D2Path = $candidate; break }
            }
        }
    }
}

if ($L4D2Path -eq "" -or -not (Test-Path $L4D2Path)) {
    Write-Warn "Could not auto-detect L4D2."
    $L4D2Path = Read-Host "Enter full path to Left 4 Dead 2 folder (contains left4dead2/)"
    $L4D2Path = $L4D2Path.Trim('"').Trim("'")
}

$L4D2Game = Join-Path $L4D2Path "left4dead2"
if (-not (Test-Path $L4D2Game)) {
    Write-Fail "Could not find 'left4dead2' subfolder inside: $L4D2Path"
}
Write-OK "Found: $L4D2Path"; Assert-OK

# ─────────────────────────────────────────────────────────────────────────────
#  Confirm scope with user
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "What would you like to remove?" -ForegroundColor Yellow
Write-Host "  [1] GraveGain mod files only (plugin + VScripts)"
Write-Host "  [2] GraveGain + SourceMod (removes ALL SourceMod plugins/data)"
Write-Host "  [3] GraveGain + SourceMod + Metamod (full uninstall)"
Write-Host "  [Q] Quit"
Write-Host ""
$choice = Read-Host "Enter choice"

# Use plain bool variables - [switch] params cannot be re-assigned after binding
[bool]$doRemoveSM = $false
[bool]$doRemoveMM = $false

switch ($choice.ToUpper()) {
    "1" { }
    "2" { $doRemoveSM = $true }
    "3" { $doRemoveSM = $true; $doRemoveMM = $true }
    "Q" { Write-Host "Cancelled."; exit 0 }
    default { Write-Fail "Invalid choice."; Assert-OK }
}

Write-Host ""
$confirmMsg = "This will remove GraveGain"
if ($doRemoveMM)         { $confirmMsg += " + Metamod:Source + SourceMod" }
elseif ($doRemoveSM)     { $confirmMsg += " + SourceMod" }
$confirmMsg += " from: $L4D2Game"
Write-Host $confirmMsg -ForegroundColor Yellow
$confirm = Read-Host "`nContinue? (y/N)"
if ($confirm.ToUpper() -ne "Y") { Write-Host "Cancelled."; exit 0 }

# ─────────────────────────────────────────────────────────────────────────────
#  Remove GraveGain plugin
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Removing GraveGain plugin..."

$pluginSmx  = Join-Path $L4D2Game "addons\sourcemod\plugins\gravegain_melee_pro.smx"
$pluginSp   = Join-Path $L4D2Game "addons\sourcemod\scripting\gravegain_melee_pro.sp"
$pluginSmxD = Join-Path $L4D2Game "addons\sourcemod\scripting\gravegain_melee_pro.smx"

Remove-IfExists $pluginSmx  "gravegain_melee_pro.smx (plugins/)"
Remove-IfExists $pluginSp   "gravegain_melee_pro.sp (scripting/)"
Remove-IfExists $pluginSmxD "gravegain_melee_pro.smx (scripting/)"

# ─────────────────────────────────────────────────────────────────────────────
#  Remove VScripts
# ─────────────────────────────────────────────────────────────────────────────
Write-Step "Removing GraveGain VScripts..."

$vscriptFiles = @(
    "scripts\vscripts\coop.nut",
    "scripts\vscripts\director_base_addon.nut",
    "scripts\vscripts\gravegain_melee_core.nut",
    "scripts\vscripts\lore_system.nut"
)
foreach ($rel in $vscriptFiles) {
    Remove-IfExists (Join-Path $L4D2Game $rel) $rel
}

# Remove scripts\vscripts\ dir if now empty
$vsDir = Join-Path $L4D2Game "scripts\vscripts"
if ((Test-Path $vsDir) -and -not (Get-ChildItem $vsDir)) {
    Remove-Item $vsDir -Force
    Write-OK "Removed empty: scripts\vscripts\"
}
$scriptsDir = Join-Path $L4D2Game "scripts"
if ((Test-Path $scriptsDir) -and -not (Get-ChildItem $scriptsDir)) {
    Remove-Item $scriptsDir -Force
    Write-OK "Removed empty: scripts\"
}

# ─────────────────────────────────────────────────────────────────────────────
#  Optionally remove SourceMod
# ─────────────────────────────────────────────────────────────────────────────
if ($doRemoveSM) {
    Write-Step "Removing SourceMod..."
    Remove-IfExists (Join-Path $L4D2Game "addons\sourcemod") "addons\sourcemod\"
    Remove-IfExists (Join-Path $L4D2Game "cfg\sourcemod")    "cfg\sourcemod\"
}

# ─────────────────────────────────────────────────────────────────────────────
#  Optionally remove Metamod
# ─────────────────────────────────────────────────────────────────────────────
if ($doRemoveMM) {
    Write-Step "Removing Metamod:Source..."
    Remove-IfExists (Join-Path $L4D2Game "addons\metamod")     "addons\metamod\"
    Remove-IfExists (Join-Path $L4D2Game "addons\metamod.vdf") "addons\metamod.vdf"

    $addonsDir = Join-Path $L4D2Game "addons"
    if ((Test-Path $addonsDir) -and -not (Get-ChildItem $addonsDir)) {
        Remove-Item $addonsDir -Force
        Write-OK "Removed empty: addons\"
    }
}

# ─────────────────────────────────────────────────────────────────────────────
#  Done
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  GraveGain uninstall complete." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

pause
