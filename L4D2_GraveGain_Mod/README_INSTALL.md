# GraveGain Melee Overhaul - Installation Guide

## What This Mod Does

- **Block / Parry / Shove** - Hold Right Click to block. Left Click while blocking to shove.
- **Inferno Blast Ultimate** - Charge by killing enemies (2s per kill) or wait 2 minutes passively.
  Hold **F** when READY, then release to fire: fireball + 3s flamethrower + AoE ignite.
- **Forced Loadout** - Every spawn gives you 1 pistol + 1 melee weapon. You may pick up other pistols or melee weapons freely.
- **Stamina System** - 5-pip HUD stamina. Blocking and shoving cost stamina.
- **GraveGain Lore** - Lore items drop from infected and can be read in chat.

---

## Requirements

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
| **Tiny** | 0.60x | 0.5x HP | 15% |
| **Small** | 0.80x | 0.75x HP | 15% |
| **Normal** | 1.00x | 1.0x HP | 35% |
| **Big** | 1.40x | 1.6x HP | 20% |
| **Giant** | 1.80x | 2.5x HP | 15% |

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
