# GraveGain Melee Overhaul - Installation Guide

## Quick Install - Windows .exe (Easiest)

1. Double-click **`build_installer.bat`** once to compile `GraveGainInstaller.exe`
   - Requires .NET Framework 4.x (installed on every Windows 7+ machine by default)
   - Compilation takes under 2 seconds
2. Double-click **`GraveGainInstaller.exe`**
   - Accepts the UAC prompt (admin rights needed to write into the L4D2 folder)
   - The PowerShell installer opens and runs automatically

> `GraveGainInstaller.exe` is just a launcher - it finds `install_gravegain.ps1` next to itself and runs it elevated. Keep all files in the same folder.

---

## Quick Install - Scripts

1. Right-click `install_gravegain.ps1` -> **Run with PowerShell**
   - If blocked by Execution Policy, open PowerShell as Administrator and run:
     ```powershell
     Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
     ```
   - Then double-click again, or run: `powershell -ExecutionPolicy Bypass -File install_gravegain.ps1`
2. The script auto-detects your Steam/L4D2 path. If it can't find it, it will ask.
3. Done. Launch L4D2 and type `sm version` in console to verify.

### macOS / Linux

1. Open Terminal in the mod folder and run:
   ```bash
   chmod +x install_gravegain.command
   ./install_gravegain.command
   ```
   On macOS you can also **double-click** `install_gravegain.command` in Finder.
2. The script auto-detects your Steam library paths.
3. Done.

> Both scripts require an internet connection to download Metamod and SourceMod (~10 MB total).

---

## Uninstall

### Windows
Right-click `uninstall_gravegain.ps1` -> **Run with PowerShell**
(or `powershell -ExecutionPolicy Bypass -File uninstall_gravegain.ps1`)

### macOS / Linux
```bash
chmod +x uninstall_gravegain.command
./uninstall_gravegain.command
```
Or double-click `uninstall_gravegain.command` in Finder.

Both uninstallers offer three removal levels:

| Option | What is removed |
|---|---|
| **1 - GraveGain only** | Plugin `.smx` + VScript `.nut` files only. Leaves SourceMod/Metamod intact. |
| **2 - GraveGain + SourceMod** | Above + entire `addons/sourcemod/` and `cfg/sourcemod/` (removes all SM plugins). |
| **3 - Full uninstall** | Above + `addons/metamod/` and `metamod.vdf` (complete removal). |

---

## Manual Install (Advanced)

---

## What This Mod Does

- **Block / Parry / Shove** - Hold Right Click to block. Left Click while blocking to shove.
- **Inferno Blast Ultimate** - Charge by killing enemies (2s per kill) or wait 2 minutes passively.
  Hold **F** when READY, then release to fire: fireball + 3s flamethrower + AoE ignite.
- **Forced Loadout** - Every spawn gives you 1 pistol + 1 melee weapon. You may pick up other pistols or melee weapons freely.
- **Stamina System** - 5-pip HUD stamina. Blocking and shoving cost stamina.
- **GraveGain Lore** - Lore items drop from infected and can be read in chat.

---

## Manual Requirements

| Dependency | Where to Get |
|---|---|
| Left 4 Dead 2 (dedicated server or local) | Steam |
| **Metamod:Source** (build 1.11+) | https://www.sourcemm.net/downloads.php?branch=stable |
| **SourceMod** (1.11+) | https://www.sourcemod.net/downloads.php?branch=stable |

---

## Step 1 - Install Metamod:Source

1. Download the latest **Metamod:Source** for L4D2 (Windows or Linux).
2. Extract the archive. You will get an `addons/` folder.
3. Copy the `addons/` folder into your L4D2 server's `left4dead2/` directory.
   - Example path: `C:\L4D2Server\left4dead2\addons\`
4. Verify: `left4dead2/addons/metamod/` should exist.

---

## Step 2 - Install SourceMod

1. Download the latest **SourceMod** for L4D2 (Windows or Linux).
2. Extract the archive. You will get `addons/` and `cfg/` folders.
3. Copy **both** folders into your `left4dead2/` directory (merge, do not overwrite Metamod).
4. Verify: `left4dead2/addons/sourcemod/` should exist.

---

## Step 3 - Compile the Plugin (if needed)

> Skip this step if `gravegain_melee_pro.smx` already exists in `sourcemod/scripting/`.
> The `.smx` file is the compiled plugin and is what the game actually loads.

**Option A - Compile locally (Windows):**
1. Copy `sourcemod/scripting/gravegain_melee_pro.sp` into your SourceMod `addons/sourcemod/scripting/` folder.
2. Run `addons/sourcemod/scripting/compile.exe`.
3. The compiled `.smx` will appear in `addons/sourcemod/scripting/compiled/`.

**Option B - Online compiler:**
1. Go to https://www.sourcemod.net/compiler.php
2. Upload `gravegain_melee_pro.sp`.
3. Download the resulting `.smx`.

---

## Step 4 - Install the Plugin

1. Copy `gravegain_melee_pro.smx` into:
   ```
   left4dead2/addons/sourcemod/plugins/
   ```

---

## Step 5 - Install the VScript Mod (Lore + Script Hooks)

This mod uses both SourceMod AND L4D2's VScript system.

1. Copy the entire `scripts/` folder from this mod into your `left4dead2/` directory:
   ```
   left4dead2/scripts/vscripts/coop.nut
   left4dead2/scripts/vscripts/director_base_addon.nut
   left4dead2/scripts/vscripts/gravegain_melee_core.nut
   left4dead2/scripts/vscripts/lore_system.nut
   ```

---

## Step 6 - Install as a VPK Addon (Optional but Recommended)

For local play or listen servers, package the mod as a VPK:

1. Download the **Valve VPK tool** (included with L4D2 SDK via Steam Tools).
2. Place the `scripts/` folder inside a folder named `gravegain_mod/`.
3. Run: `vpk.exe gravegain_mod`
4. Copy the resulting `gravegain_mod.vpk` into:
   ```
   Left 4 Dead 2/left4dead2/addons/
   ```

Or simply drop the `L4D2_GraveGain_Mod/` folder directly into `left4dead2/addons/` - L4D2 loads loose addon folders automatically.

---

## Step 7 - Verify Installation

Start your server or local game. In console you should see:

```
[GraveGain Pro] Plugin STARTED. Version 3.0 GraveGain
```

And in chat when you spawn:
```
[GraveGain] Loadout: Pistol + Bat | Hold F when Ultimate is READY
```

---

## Directory Structure Reference

```
left4dead2/
  addons/
    metamod/                    <- Metamod:Source
    sourcemod/
      plugins/
        gravegain_melee_pro.smx <- COMPILED PLUGIN (goes here)
      scripting/
        gravegain_melee_pro.sp  <- Source (for recompiling)
    L4D2_GraveGain_Mod/         <- Optional: loose addon folder
  scripts/
    vscripts/
      coop.nut
      director_base_addon.nut
      gravegain_melee_core.nut
      lore_system.nut
```

---

## HUD Layout

All information is displayed on-screen. No chat messages are used.

```
+----------------------------------------------------------+
|                                                          |
|  -- EVENT FLASH (yellow, fades out) --                   |  <- y=0.08  upper-center
|     e.g. ">> BLOCKING <<" / "** ULTIMATE READY **"       |
|                                                          |
|                                                          |
|                                                          |
|                                                          |
|                                                          |
| STAMINA [||||||||||||........]         <- y=0.80  left   |
| 3.6 / 5.0  [BLOCKING]                                    |
|                                                          |
|         INFERNO BLAST [########----] 74s  <- y=0.87 ctr  |
+----------------------------------------------------------+
```

**Channel 1 - Stamina** (bottom-left, green/yellow/red based on level)
- Visual 20-char bar: `|` = filled, `.` = empty
- Shows blocking/parry state inline
- Color: Green >60%, Yellow >30%, Red <=30%

**Channel 2 - Ultimate** (bottom-center)
- `[---------- ]` filling left-to-right as charge builds, shows seconds remaining
- `READY - Hold F` when charge hits zero (gold)
- `!! RELEASE F !!` while armed (bright orange-red)

**Channel 3 - Event Flash** (upper-center, yellow, fades over 0.5s)
- Block start / Block release
- Ultimate ready / Ultimate armed
- Inferno Blast fired (shown to all players)
- Loadout given on spawn

---

## Enemy Size Tiers

Common infected spawn with randomised sizes and proportionally scaled HP:

| Tier | Scale | HP Multiplier | Spawn Chance |
|---|---|---|---|
| **Tiny** | 0.80x | 0.85x HP | 15% |
| **Small** | 0.90x | 0.92x HP | 15% |
| **Normal** | 1.00x | 1.0x HP | 35% |
| **Big** | 1.10x | 1.10x HP | 20% |
| **Giant** | 1.20x | 1.20x HP | 15% |

---

## Controls

| Key | Action |
|---|---|
| **Right Click** | Block (melee weapon active) |
| **Left Click** (while blocking) | Shove - pushes nearby infected |
| **F (tap)** | Flashlight toggle (normal) |
| **F (hold 0.5s, when READY)** | Arm Inferno Blast |
| **F (release after arming)** | FIRE Inferno Blast |

---

## Ultimate: Inferno Blast

**Charging:**
- Starts at 120 seconds (2 minutes)
- Each infected kill: -2 seconds
- Each Witch kill: -10 seconds
- Tank kill (shared): -20 seconds for all survivors
- Charge also passively ticks down over time

**Effect on fire:**
1. **Fireball** - Launches a flaming projectile along your aim vector. Explodes on contact with infected or after 2 seconds.
2. **AoE Ignite** - Instantly damages + ignites all infected within 10 feet. Max 120 damage at point-blank, 20 at edge.
3. **Flamethrower** - 3-second cone spray in front of you. 12 damage per tick, every 0.15s.

> Does NOT damage teammates.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Plugin not loading | Check `addons/sourcemod/plugins/` contains the `.smx`, not `.sp` |
| `unknown command sm_gravegain` | SourceMod is not installed or Metamod is missing |
| Lore not dropping | Check `scripts/vscripts/lore_system.nut` is in the correct path |
| Block not working | Make sure you have a melee weapon active |
| VScript errors in console | Verify `coop.nut` and `director_base_addon.nut` are in `scripts/vscripts/` |

---

## Regenerating Lore (Advanced)

If you want to rebuild `lore_system.nut` from the Python source:

```powershell
cd C:\GitHub5\GraveGain\L4D2_GraveGain_Mod
python build_lore.py
```

This regenerates `scripts/vscripts/lore_system.nut` from `build_lore.py`.
