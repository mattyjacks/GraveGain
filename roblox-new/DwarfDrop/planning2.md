# DwarfDrop - Clean Rebuild Plan
**Derived from full analysis of DropDwarf-old**
**Author: Cascade | Date: 2026-05-24**

---

## BRAID Diagram

```
flowchart TD;
    A[SOURCE: DropDwarf-old - Full Codebase Analyzed] --> B[SHARED LAYER - 8 files]
    A --> C[SERVER LAYER - 9 files]
    A --> D[CLIENT LAYER - 13 files]

    B --> B1[game_data.lua - Core constants\n1000m shaft, fall damage, coins,\nmodifiers, biomes, combo, magnet\ncoyote time, chunk constants]
    B --> B2[upgrade_data.lua - 6 upgrades\nmax_health heal_rate move_speed\nfall_resist coin_magnet double_jump\nComputeStats returns derived stats]
    B --> B3[biome_data.lua - 4 biomes\nVolcano Fortress Cave Mine\nColors fog ambient platforms\nGenerateSequence from seed]
    B --> B4[item_data.lua - 11 items\n8 utility + 3 competitive\nWeight system constants\nWater system constants]
    B --> B5[networking.lua - All RemoteEvents\n99+ events/functions\nServer/Client helpers]
    B --> B6[seed_system.lua - Deterministic RNG\nStringToSeed djb2 hash\nNewRNG ChildRNG Shuffle WeightedPick]
    B --> B7[game_mode.lua - 3 modes\nSingleplayer Cooperative Competitive\nDown/rescue/pvp rules]
    B --> B8[timed_seeds.lua - Hourly/Daily/Weekly\nEST timezone seeds\nCountdown timers]

    C --> C1[main.server.lua - Entry point\nRemotes init, hub gen, gravity=100\nFuture lighting, player lifecycle\nTick loop: depth/regen/timer\nFall damage, coins, upgrades\nModifier, leaderboard handlers]
    C --> C2[player_data.lua - DataStore\nDataStore v1, in-memory cache\nGold/upgrades/runs/seeds/camera]
    C --> C3[session.lua - MP session mgmt\nHost lobby, join, leave\nCoop downed bleed timers\nPvP cooldowns per-pair]
    C --> C4[leaderboard.lua - OrderedDataStore\nInverted time score\nDepth score direct\nTop-N queries]
    C --> C5[hub_generator.lua - Hub geometry\nFloor slab + tiles, walls\nUpgrade shop posts x4\nPortal, seed kiosk, leaderboard wall]
    C --> C6[item_handler.lua - Server item state\n4-slot backpack per player\nWater system, heal ticks\nPlaced items cleanup]
    C --> C7[level_generator/init.lua - Main gen\nCreateSessionFolder\nGenerateSlot per 100m chunk\nGenerate: slots 1+2 eager\nDynamic chunk load on demand\nPlatforms coins slimes ores\nDwarven basket bootstrap]
    C --> C8[handlers/death_handler.lua\nHandleDeath, RespawnInBasket\nSendToHub, DeathChoice handler\nCoop downed+rescue system\n30s timeout safety]
    C --> C9[handlers/session_handler.lua\nStartLevel for host+teammates\nRequestChunkLoad dynamic gen\nUnload N-2 behind player\nGameMode lobby events]
    C --> C10[handlers/mining_handler.lua\nMineWall auth validation\n0.3s anti-macro cooldown\nHP tags, coin drop, nugget]
    C --> C11[handlers/pvp_handler.lua\nAttackPlayer auth validation\nPickaxe range check\nGiveItemRequest coop trade]

    D --> D1[main.client.lua - Client wiring\nAll systems instantiated\nHub proximity detection\nLevel state machine\nEvent handlers]
    D --> D2[fps_camera.lua - FPS/TPS camera\nMouse lock, sensitivity\nFirst/third person toggle]
    D --> D3[movement.lua - Physics movement\nWASD sprint, coyote time\nAir jumps with impulse\nLanding squash animation\nCoin magnet pull\nCombo streak tracking\nModifier speed mult]
    D --> D4[hud.lua - In-run HUD\nHealth bar, depth progress bar\nCombo counter, air jump pips\nSpeedometer, modifier badge\nSpeed lines overlay\nTimer display]
    D --> D5[hub_ui.lua - Hub menus\nUpgrade shop panels\nModifier selector panel\nSeed input, lobby UI\nLeaderboard display\nTimed seeds UI]
    D --> D6[active_item/init.lua - Item use\nQ=use F=place/throw\nPhysics for ropes springs\nParachute balloon toggle\nJetpack thrower hold]
    D --> D7[pickaxe_model.lua - Viewmodel\nPickaxe swing animation\nE key mining\nWall hit detection]
    D --> D8[slime_enemy.lua - Client slimes\nPatrol Chase Attack FSM\nProjectile spit\nSlimeRain all-terrain apply]
    D --> D9[moving_platforms.lua - Platform sync]
    D --> D10[visuals.lua - Biome atmosphere\nFog color/density transitions\nLighting ambient transitions]
    D --> D11[backpack_ui.lua - 4 slot display]

    E[KNOWN BUGS in old codebase] --> E1[applyStats duplicated in 3 files\nmain.server + death_handler\n+ session_handler - not DRY]
    E --> E2[SlimeKilled uses PartBuilders\nbut PartBuilders not imported\nin main.server.lua - reference error]
    E --> E3[basket respawn teleports to\nhardcoded y=LEVEL_Y_OFFSET-10\nignores biome sequence slotIndex]
    E --> E4[HubGenerator returns spawn=nil\nspawn is global not local\ncausing silent nil in return table]
    E --> E5[Coop teammate spawning uses\nmath.random not SeedSystem RNG\nnon-deterministic positioning]
    E --> E6[Leaderboard DataStore pcall\nwithout studio API access guard\ncrashes on DataStore ops]
    E --> E7[rescueTick uses player.UserId key\nbut cleanup uses player key - mismatch\nmemory leak on disconnect]
    E --> E8[RequestChunkLoad double-fires\nboth session_handler.Init AND\nmain already bind it]
    E --> E9[BackpackUI built onto hud.screenGui\nbefore hud:Build completes\nrace condition on init]
    E --> E10[movement.lua coin magnet fires\nCollectCoinCombo but server expects\nCollectCoin - event name mismatch]

    F[NEW ARCHITECTURE GOALS] --> F1[Single source of truth for applyStats\nin a player_state_manager module]
    F --> F2[All bug fixes applied by design\nbefore any line of code written]
    F --> F3[Clean module boundaries\nNo cross-handler require loops]
    F --> F4[Consistent event naming\ncollect_coin vs CollectCoinCombo\nresolved into single flow]
    F --> F5[Strict server authority\nall damage/gold/item ops server-only\nclient purely cosmetic]
    F --> F6[Dynamic chunk stream\nClean slot load/unload\nno duplicate listeners]
    F --> F7[Complete rojo project.json\nfor DwarfDrop]
```

---

## Overview

**DwarfDrop** is a clean, bug-free rebuild of DropDwarf. Same game, same features, same content - but properly architected. Every bug found in the old codebase is fixed by design before a single line is written.

**Genre:** First-person vertical drop game  
**Engine:** Roblox (Lua, Rojo)  
**Multiplayer:** 1-4 players, Singleplayer / Cooperative / Competitive modes  
**Depth:** 1000m procedural shaft with 4 biomes  
**Goal:** Fall as deep (and fast) as possible, collect gold, buy upgrades between runs

---

## What Was Wrong in DropDwarf-old - Complete Bug Catalog

### BUG 1: `applyStats` duplicated in 3 places
**Files:** `main.server.lua`, `death_handler.lua`, `session_handler.lua`  
**Problem:** Three separate identical functions. Any fix to one is not applied to the others. Stats-apply behavior drifts between death, respawn, and level start.  
**Fix:** Extract into `player_state_manager.lua` as a single `ApplyStats(player, stats)` function. All three handlers call it.

### BUG 2: `PartBuilders` used but not required in `main.server.lua`
**File:** `main.server.lua` line ~450 in `SlimeKilled` handler  
**Problem:** `PartBuilders.SpawnCoin(...)` called but `PartBuilders` is never `require`d at the top. This throws a runtime error every time a slime dies, breaking the coin reward.  
**Fix:** Either require `PartBuilders` in the server main, or move slime coin spawning into a dedicated `SlimeCoinDropper` function within `level_generator` that is already imported.

### BUG 3: Basket respawn hardcodes `LEVEL_Y_OFFSET - 10`
**File:** `death_handler.lua` line ~142  
**Problem:** The respawn position is always the top of slot 1, regardless of how many slots have been loaded. If a player dies deep and respawns, they reappear at depth=0 which is correct - but the basket trapdoor detection logic depends on a `DwarvenEntryBasket` that may not exist in the player's sessionFolder if it was not generated.  
**Fix:** Add a guard: only attempt basket trapdoor logic if `sessionFolder` and `DwarvenEntryBasket` both exist. Teleport is still to `LEVEL_Y_OFFSET - 10` but the trapdoor manipulation is safely skipped when missing.

### BUG 4: `HubGenerator.Generate` returns `spawn = spawn` (global nil)
**File:** `hub_generator.lua` line ~268  
**Problem:** `return { folder = hubFolder, portal = portalGlow, seedKiosk = kioskBase, spawnPad = spawn }` - `spawn` is a Roblox global for `game:GetService("Players").LocalPlayer` (deprecated). In a server script this resolves to nil silently. The consumer never uses `spawnPad` but the nil is unexpected.  
**Fix:** Remove `spawnPad` from the return table since nothing uses it, or replace with the actual `spawnLabel` Part.

### BUG 5: Coop teammate spawn uses `math.random` (non-seeded)
**File:** `session_handler.lua` lines ~147-148  
**Problem:** `math.random(-0.5, 0.5)` is used for teammate spawn offsets. `math.random` with floats is not valid Lua (only integers). `math.random(-0.5, 0.5)` always returns 0 in Roblox because it truncates to `math.random(0, 0)`. All teammates spawn at identical positions, causing physics collision-fling on level start.  
**Fix:** Use `math.random() - 0.5` (no args = uniform 0-1) or use `SeedSystem.NewRNG` for proper determinism.

### BUG 6: Leaderboard DataStore not guarded in all code paths
**File:** `leaderboard.lua` lines ~11-12  
**Problem:** `DataStoreService:GetOrderedDataStore(...)` is called at module-load time without a `pcall`. In Roblox Studio without API access enabled, this throws on load, crashing the entire server script.  
**Fix:** Wrap both `GetOrderedDataStore` calls in `pcall` and set a `datastoreAvailable` flag, same pattern as `player_data.lua`.

### BUG 7: `rescueTick` key mismatch causes memory leak
**File:** `death_handler.lua` lines ~16, ~239, ~272, ~278  
**Problem:** `rescueTick[player.UserId] = now` stores by UserId (number), but `DeathHandler.CleanupPlayer(player)` does `rescueTick[player.UserId] = nil` - this is actually consistent. However, the timeout cleanup at line ~272 does `rescueTick[player.UserId] = nil` while line ~278 `rescueTick[player] = nil` - the `CleanupPlayer` uses `player` object (not `.UserId`). This is inconsistent and leaks on player disconnect.  
**Fix:** Standardize all `rescueTick` keys to `player.UserId` everywhere including `CleanupPlayer`.

### BUG 8: `RequestChunkLoad` event handler registered twice
**Files:** `session_handler.lua` line ~198 inside `Init()`, and `main.server.lua` line ~334 calls `SessionHandler.Init(getState)` which fires that handler.  
**Problem:** If `RequestStartLevel` is bound in both `session_handler.Init` AND separately in `main.server.lua`, the event fires twice per client request causing double chunk generation.  
**Fix:** All event bindings for the session/level lifecycle live exclusively in `session_handler.Init`. `main.server.lua` never duplicates them.

### BUG 9: `BackpackUI:Build` race condition
**File:** `main.client.lua` lines ~77-79  
**Problem:** `hud:Build()` is called, then immediately `backpackUI:Build(hud.screenGui)`. If `hud:Build()` creates the ScreenGui asynchronously (via `Instance.new`), `hud.screenGui` may not be set yet. In the old code it works only by lucky ordering. A future refactor could break it.  
**Fix:** `hud:Build()` must return `self` (or the screenGui), and `backpackUI:Build` takes the direct reference. Or: `BackpackUI` creates its own ScreenGui rather than sharing.

### BUG 10: Coin event name mismatch
**Files:** `movement.lua` fires `CollectCoinCombo`, server `main.server.lua` listens on `CollectCoin`  
**Problem:** The coin magnet collects coins and fires `CollectCoinCombo` (with combo data). The server only listens on `CollectCoin`. The combo path never awards gold when using the magnet.  
**Fix:** Consolidate into a single `CollectCoin` event that carries optional combo data `{ coinId, comboStreak }`. Server handles both cases from one listener.

---

## Architecture Design

### Core Principle: Clear Ownership

Every piece of data has exactly one owner:
- **Gold, Health, Upgrades** - Server owns, client reads via events
- **Input** - Client captures, fires events, server validates
- **Cosmetics (VFX, sounds, particles)** - Client owns entirely, no server involvement
- **Level Geometry** - Server generates and owns, clients read from Workspace

### Module Dependency Map

```
Shared (no dependencies on server/client)
  game_data  <-- upgrade_data, biome_data, item_data, networking, seed_system, game_mode, timed_seeds

Server
  main.server  <-- player_state_manager (NEW)
                <-- player_data
                <-- leaderboard
                <-- hub_generator
                <-- item_handler
                <-- session
                <-- handlers/death_handler
                <-- handlers/session_handler  (owns ALL level lifecycle events)
                <-- handlers/mining_handler
                <-- handlers/pvp_handler
                <-- level_generator/init
                    <-- level_generator/part_builders
                    <-- level_generator/biome_decorators
                    <-- level_generator/dwarven_basket
                    <-- level_generator/ore_spawner

Client
  main.client  <-- fps_camera
               <-- movement
               <-- hud  (owns its own ScreenGui)
               <-- hub_ui
               <-- visuals
               <-- slime_enemy
               <-- moving_platforms
               <-- active_item (init + physics_items + rope_climb + throw_preview)
               <-- backpack_ui (owns its own ScreenGui layer)
               <-- pickaxe (viewmodel + animations + hit_detector)
```

### New File: `player_state_manager.lua`

Extracted from the three duplicate locations. Single responsibility: compute and apply stats to a character.

```lua
-- player_state_manager.lua
-- Single source of truth for deriving and applying player stats.
local PlayerStateManager = {}

function PlayerStateManager.ApplyStats(player, stats)
    -- Sets MaxHealth, WalkSpeed, JumpHeight=0, BreakJointsOnDeath=false
    -- Called from: main.server CharacterAdded, death_handler respawn, session_handler level start
end

function PlayerStateManager.MakeDefaultState(data, stats)
    -- Returns a clean playerState table with all required fields initialized
    -- Prevents nil-access errors from missing fields
end

return PlayerStateManager
```

---

## Complete File List

### Project Root
```
DwarfDrop/
  default.project.json
  rojo.toml
  planning2.md  (this file)
  src/
    shared/
      game_data.lua
      upgrade_data.lua
      biome_data.lua
      item_data.lua
      networking.lua
      seed_system.lua
      game_mode.lua
      timed_seeds.lua
    server/
      main.server.lua
      player_state_manager.lua        -- NEW: extracted applyStats + MakeDefaultState
      player_data.lua
      session.lua
      leaderboard.lua
      hub_generator.lua
      item_handler.lua
      level_generator/
        init.lua
        part_builders.lua
        biome_decorators.lua
        dwarven_basket.lua
        ore_spawner.lua
      handlers/
        death_handler.lua
        session_handler.lua
        mining_handler.lua
        pvp_handler.lua
    client/
      main.client.lua
      fps_camera.lua
      movement.lua
      hud.lua
      hub_ui.lua
      visuals.lua
      slime_enemy.lua
      moving_platforms.lua
      backpack_ui.lua
      pickaxe_model.lua
      active_item/
        init.lua
        physics_items.lua
        rope_climb.lua
        throw_preview.lua
      pickaxe/
        animations.lua
        hit_detector.lua
        viewmodel.lua
    character/
      (empty - StarterCharacterScripts)
```

**Total: 30 files** (same as old + 1 new `player_state_manager.lua`)

---

## Shared Layer - Spec

### `game_data.lua`
Identical to old. No bugs found. Keep as-is.

Key constants:
- `STUDS_PER_METER = 3.2`
- `TOTAL_DEPTH_METERS = 1000`
- `TOTAL_DEPTH_STUDS = 3200`
- `LEVEL_WIDTH = 60`
- `LEVEL_Y_OFFSET = 0` (surface Y)
- `HUB_Y = 600`
- `FALL_DAMAGE_THRESHOLD_METERS = 5`
- `FALL_DAMAGE_PER_METER = 8`
- `FALL_DAMAGE_MAX = 100`
- `DEFAULT_MAX_HEALTH = 100`
- `DEFAULT_WALK_SPEED = 18`
- `DEFAULT_SPRINT_SPEED = 28`
- `COIN_VALUE = 5`
- `COMBO_RESET_TIME = 3.0`
- `COMBO_THRESHOLDS = {1, 5, 10, 20}`
- `COMBO_MULTIPLIERS = {1, 2, 3, 5}`
- `MAGNET_PULL_SPEED = 28`
- `COYOTE_TIME = 0.15`
- `SLOT_DEPTH_METERS = 100`
- `MAX_LOADED_SLOTS = 3`
- `BASKET_STEAM_TIME = 2.5`
- `BASKET_DOOR_TIME = 1.2`
- 5 RunModifiers: Normal, Speedy, Fragile, Golden, SlimeRain
- 4 biome ranges (fixed order, not seeded - for display only)

### `upgrade_data.lua`
Identical to old. 6 upgrades, 10 tiers each.

### `biome_data.lua`
Identical to old. 4 biomes with full visual params.  
**Note:** `require(seed_system)` path must match new Rojo tree.

### `item_data.lua`
Identical to old. 11 items, weight constants.

### `networking.lua`
Same events, but with one change:  
- **Remove `CollectCoinCombo`** - merged into `CollectCoin`
- `CollectCoin` payload: `{ coinId: string, comboStreak: number }` (streak is 0 if not applicable)

All other events unchanged.

### `seed_system.lua`
Identical to old.

### `game_mode.lua`
Identical to old.

### `timed_seeds.lua`
Identical to old.

---

## Server Layer - Spec

### `player_state_manager.lua` (NEW)
```
Functions:
  ApplyStats(player, stats)
    - character nil-guard
    - humanoid nil-guard
    - sets MaxHealth, Health (clamped), WalkSpeed
    - sets JumpHeight=0, JumpPower=0, AutoJumpEnabled=false
    - sets BreakJointsOnDeath=false
    - disables Jumping humanoid state

  MakeDefaultState(data, stats) -> table
    - returns fully-initialized playerState
    - all fields present with correct types/defaults
    - no nil-access possible downstream
    Fields: inLevel, levelFolder, seed, startTime, bestDepth, currentDepth,
            goldThisRun, health, maxHealth, stats, isFalling, fallStartY,
            modifier, comboStreak, comboTimer, isDowned, blockHubRoute,
            biomeSequence, currentBiome, timerSyncAcc, isDying
```

### `main.server.lua`
```
Startup sequence:
  1. Networking.CreateRemotes()
  2. ItemHandler.Init()
  3. HubGenerator.Generate(workspace) -> hubParts
  4. Disable collision on SpawnPad/SpawnLocation parts
  5. workspace.Gravity = 100
  6. Set Lighting (Future tech, GlobalShadows, Atmosphere)
  7. MiningHandler.Init(getState)
  8. DeathHandler.Init(getState)
  9. PvpHandler.Init(getState)
  10. SessionHandler.Init(getState)  -- owns ALL level lifecycle events

Event bindings IN main.server (not session_handler):
  - CollectCoin: rate-limit 0.12s, goldMult, GoldUpdate
  - ApplyFallDamage: physics-sanity clamp, resist+modifier+weight mult
  - PurchaseUpgrade: PlayerData, ApplyStats, GoldUpdate, StatsUpdate
  - SetModifier: state.modifier = RunModifiers[id], ModifierSet
  - RequestLeaderboard: LeaderboardUpdate fire
  - SaveCameraPreference: PlayerData.SetDefaultCamera
  - PlayerReachedBottom: handleWin guard check
  - CollectItem: crate distance-check, ItemHandler.GiveItem, destroy crate
  - SlimeHit: 0.3s cooldown, damage, PlayerHit with knockback
  - SlimeKilled: distance-check 50 studs, SpawnCoins via LevelGenerator.SpawnCoins (NOT PartBuilders direct)
  - GetPlayerData: RemoteFunction
  - ValidateSeed: RemoteFunction

Tick loop (0.1s):
  - For each inLevel player:
    - depth track -> DepthUpdate
    - biome change -> BiomeChanged
    - passive heal (if !noRegen)
    - healTick from potions
    - HealthUpdate every tick
    - TimerSync every 0.5s
    - Out-of-bounds kill (below 1000m + 50 studs)

PlayerAdded:
  - PlayerData.OnPlayerAdded
  - ItemHandler.InitPlayer
  - playerStates[player] = PlayerStateManager.MakeDefaultState(data, stats)
  - CharacterAdded:
      - setupCharacterPhysics (HipHeight=2.0, zero elasticity)
      - teleport to hub Y=HUB_FLOOR_Y+8 if not inLevel
      - PlayerStateManager.ApplyStats
  - task.delay(2): LeaderboardUpdate + GoldUpdate fire

PlayerRemoving:
  - All handler cleanups
  - PlayerData.OnPlayerRemoving
  - playerStates[player] = nil
```

### `player_data.lua`
Identical to old except:
- DataStore wrapped in pcall at module load (already done, keep it)
- No changes needed

### `session.lua`
Identical to old except:
- **Fix Bug 7**: All `rescueTick` references use `player.UserId` consistently

### `leaderboard.lua`
Identical to old except:
- **Fix Bug 6**: Both `GetOrderedDataStore` calls wrapped in `pcall` at top of file
- Add `datastoreAvailable` guard flag

### `hub_generator.lua`
Identical to old except:
- **Fix Bug 4**: Return table uses `spawnLabel` instead of `spawn`
- All shop upgrade slots (6 total including coin_magnet and double_jump, not just 4)

### `item_handler.lua`
Identical to old. No bugs found.

### `level_generator/init.lua`
Identical to old with:
- Add public function `LevelGenerator.SpawnCoins(levelFolder, position, count)` so that `main.server.lua` SlimeKilled handler can call it cleanly without needing PartBuilders directly.

### `handlers/death_handler.lua`
Identical to old except:
- **Fix Bug 7**: `rescueTick` keys standardized to `player.UserId`
- **Fix Bug 3**: Add nil-guard before basket trapdoor manipulation
- Replace inline `applyStats` with `PlayerStateManager.ApplyStats`

### `handlers/session_handler.lua`
Identical to old except:
- **Fix Bug 5**: Replace `math.random(-0.5, 0.5)` with `(math.random() - 0.5)`
- Replace inline `applyStats` with `PlayerStateManager.ApplyStats`
- **Fix Bug 8**: `RequestStartLevel` binding only here, not also in `main.server`

### `handlers/mining_handler.lua`
Identical to old. No bugs found.

### `handlers/pvp_handler.lua`
Identical to old. No bugs found.

---

## Client Layer - Spec

### `main.client.lua`
Identical to old except:
- **Fix Bug 9**: `hud:Build()` is called and returns the screenGui reference directly. `backpackUI:Build(screenGuiRef)` uses that reference. No race condition.
- **Fix Bug 10**: Client fires `CollectCoin` (not `CollectCoinCombo`) with combo data attached

### `fps_camera.lua`
Identical to old. No bugs found.

### `movement.lua`
Identical to old except:
- **Fix Bug 10**: Fire `Networking.Events.CollectCoin` with `{ comboStreak = self.comboStreak }` instead of `CollectCoinCombo`
- All other movement logic unchanged

### `hud.lua`
Identical to old. No bugs found.

### `hub_ui.lua`
Identical to old. No bugs found.

### `visuals.lua`
Identical to old. No bugs found.

### `slime_enemy.lua`
Identical to old. No bugs found.

### `moving_platforms.lua`
Identical to old. No bugs found.

### `backpack_ui.lua`
Identical to old. No bugs found.

### `pickaxe_model.lua`, `pickaxe/`
Identical to old. No bugs found.

### `active_item/`
Identical to old. No bugs found.

---

## Rojo Project Configuration

### `default.project.json`
```json
{
  "name": "DwarfDrop",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "Shared": {
        "$path": "src/shared"
      }
    },
    "ServerScriptService": {
      "$className": "ServerScriptService",
      "$path": "src/server"
    },
    "StarterPlayer": {
      "$className": "StarterPlayer",
      "StarterPlayerScripts": {
        "$className": "StarterPlayerScripts",
        "$path": "src/client"
      },
      "StarterCharacterScripts": {
        "$className": "StarterCharacterScripts",
        "$path": "src/character"
      }
    },
    "Workspace": {
      "$className": "Workspace",
      "$ignoreUnknownInstances": true,
      "SpawnLocation": {
        "$className": "SpawnLocation",
        "$properties": {
          "Position": { "Vector3": [0, 608, 0] },
          "Size": { "Vector3": [12, 2, 12] },
          "Anchored": true,
          "CanCollide": false,
          "Neutral": true,
          "Duration": 0,
          "Transparency": 1
        }
      }
    },
    "Lighting": {
      "$className": "Lighting",
      "$ignoreUnknownInstances": true
    },
    "SoundService": {
      "$className": "SoundService",
      "$ignoreUnknownInstances": true
    },
    "Players": {
      "$className": "Players",
      "$ignoreUnknownInstances": true
    }
  }
}
```

### `rojo.toml`
```toml
name = "DwarfDrop"
```

---

## Implementation Phases

### Phase 1: Scaffold + Shared Layer
- [ ] Create folder structure
- [ ] `default.project.json` + `rojo.toml`
- [ ] All 8 shared files (game_data, upgrade_data, biome_data, item_data, networking, seed_system, game_mode, timed_seeds)
- [ ] Verify: `rojo serve` runs without errors

### Phase 2: Server Core
- [ ] `player_state_manager.lua` (new - extracted logic)
- [ ] `player_data.lua` (DataStore fixed)
- [ ] `leaderboard.lua` (DataStore pcall fixed)
- [ ] `session.lua` (rescueTick key fix)
- [ ] `main.server.lua` (startup, tick loop, event bindings)

### Phase 3: Level Generation
- [ ] `level_generator/part_builders.lua`
- [ ] `level_generator/ore_spawner.lua`
- [ ] `level_generator/dwarven_basket.lua`
- [ ] `level_generator/biome_decorators.lua`
- [ ] `level_generator/init.lua` (+ SpawnCoins helper)
- [ ] `hub_generator.lua` (spawnPad nil fix, 6 upgrades)

### Phase 4: Server Handlers + Items
- [ ] `item_handler.lua`
- [ ] `handlers/mining_handler.lua`
- [ ] `handlers/pvp_handler.lua`
- [ ] `handlers/death_handler.lua` (rescueTick + basket nil-guard + PlayerStateManager)
- [ ] `handlers/session_handler.lua` (math.random fix + PlayerStateManager + no duplicate bindings)

### Phase 5: Client Systems
- [ ] `fps_camera.lua`
- [ ] `movement.lua` (coin event name fix)
- [ ] `hud.lua` (returns screenGui ref)
- [ ] `backpack_ui.lua`
- [ ] `hub_ui.lua`
- [ ] `visuals.lua`
- [ ] `slime_enemy.lua`
- [ ] `moving_platforms.lua`

### Phase 6: Client Pickaxe + Items
- [ ] `pickaxe/viewmodel.lua`
- [ ] `pickaxe/animations.lua`
- [ ] `pickaxe/hit_detector.lua`
- [ ] `pickaxe_model.lua`
- [ ] `active_item/physics_items.lua`
- [ ] `active_item/rope_climb.lua`
- [ ] `active_item/throw_preview.lua`
- [ ] `active_item/init.lua`

### Phase 7: Client Entry Point + Integration
- [ ] `main.client.lua` (hud build fix, CollectCoin event fix)
- [ ] End-to-end test: spawn in hub, enter level, collect coins, die, respawn
- [ ] Multiplayer test: cooperative 2-player run
- [ ] Competitive test: pvp pickaxe swing

---

## Networking Event Reference (Clean Version)

### Server -> Client
| Event | Payload | When |
|-------|---------|------|
| `LevelGenerated` | `{ seed, biomeSequence[] }` | Level geometry ready |
| `DepthUpdate` | `depthMeters: number` | Every 0.1s when deeper than last |
| `BiomeChanged` | `biomeName: string` | Biome transition |
| `PlayerDied` | `{ depthReached, goldEarned }` | HP hits 0 or falls out of bounds |
| `PlayerWon` | `{ timeSeconds, timeStr, absoluteRank, goldEarned }` | Reached 1000m |
| `LeaderboardUpdate` | `topTimes[], topDepths[]` | On request or join |
| `GoldUpdate` | `gold: number` | Any gold change |
| `HealthUpdate` | `health, maxHealth` | Every tick in-level |
| `TimerSync` | `seconds: number` | Every 0.5s in-level |
| `StatsUpdate` | `stats: table` | On level start or upgrade |
| `ModifierSet` | `modifierId: string` | On level start or modifier change |
| `ComboUpdate` | `{ streak, multiplier }` | When streak changes |
| `BackpackUpdate` | `slots[], activeSlot` | Any item change |
| `ItemUsed` | `{ itemId, remaining }` | Item consumed |
| `ItemPickup` | `{ itemId, slot }` | Item added to backpack |
| `WaterUpdate` | `level: number (0-5)` | Water used or refilled |
| `ItemPlaced` | `{ itemId, position, rotation }` | Item placed in world |
| `ItemGiven` | `{ fromId, toId, itemId, count }` | Item transferred |
| `WallMined` | `pos, oreType, goldEarned, [hpLeft, maxHp]` | Ore hit or depleted |
| `SpawnMiningNugget` | `position, goldValue` | Ore depleted, visual nugget |
| `CameraShakeSignal` | `{ magnitude, duration }` | Explosion/impact |
| `TriggerBasketLaunch` | (none) | Level start, steam cinematic |
| `ChunkLoaded` | `slotIndex, slimeSpawns[]` | Dynamic chunk ready |
| `UnloadChunk` | `slotIndex` | Chunk N-2 removed |
| `RespawnInBasket` | `{ timerSeconds, isReset }` | Basket respawn confirmed |
| `RespawnInHub` | `{ isReset }` | Hub respawn confirmed |
| `PlayerHit` | `{ damage, knockbackDir, knockbackForce, attackerName }` | Took damage (slime or pvp) |
| `PlayerDowned` | `{ userId, name, pos }` | Coop teammate went down |
| `PlayerRescued` | `{ userId, rescuerId, name }` | Coop teammate revived |
| `RescueProgress` | `{ targetId, progress }` | Rescue 0-1 progress |
| `TeamHealthUpdate` | `{ [userId] = {name, health, max, downed} }` | Coop team panel |
| `WeightUpdate` | `{ totalKg, speedMult, fallMult }` | Backpack weight changed |
| `LobbyUpdate` | `{ hostUserId, modeId, members[], [error] }` | Lobby state |
| `GameModeChanged` | `modeId: string` | Mode finalized at run start |
| `PlayerEliminated` | `{ userId }` | Competitive player out |
| `ProjectileLanded` | `{ itemId, pos, hitPlayerId }` | Throw landed |

### Client -> Server
| Event | Payload | Purpose |
|-------|---------|---------|
| `RequestStartLevel` | `seed: string` | Portal enter |
| `CollectCoin` | `{ coinId, comboStreak }` | Coin pickup (merged event) |
| `ApplyFallDamage` | `fallMeters: number` | Fall impact report |
| `PurchaseUpgrade` | `upgradeId: string` | Shop buy |
| `RequestLeaderboard` | (none) | Fetch leaderboard |
| `PlayerReachedBottom` | (none) | 1000m confirm |
| `SlimeKilled` | `slimeId, slimeSize, pos` | Slime death report |
| `TerrainSlimed` | `partId, pos` | Slime hit terrain |
| `PickaxeTerrainHit` | `pos, terrainType` | Pickaxe hit |
| `MineWall` | `orePart: Instance` | Mining hit |
| `UseActiveItem` | `itemId` | Item use |
| `PlaceItem` | `{ itemId, position, normal }` | Item placement |
| `GrabRope` | `ropeId` | Rope grab |
| `ReleaseRope` | (none) | Rope release |
| `EquipSlot` | `slotIndex` | Backpack slot change |
| `DeathChoice` | `"respawnBasket"` or `"respawnHub"` or `"resetBasket"` or `"resetHub"` | Post-death choice |
| `AirJumpUsed` | (none) | Air jump consumed |
| `SetModifier` | `modifierId: string` | Hub modifier select |
| `SetGameMode` | `modeId: string` | Hub lobby mode |
| `RequestJoinSession` | `hostUserId: number` | Join lobby |
| `LeaveSession` | (none) | Leave lobby |
| `RequestRescue` | `targetUserId: number` | Hold E near downed |
| `GiveItemRequest` | (none) | G key item trade |
| `AttackPlayer` | `{ targetUserId, pos }` | PvP pickaxe |
| `ThrowItem` | `{ itemId, origin, direction }` | Throw javelin/rock |
| `SaveCameraPreference` | `"fps"` or `"tps"` | Persist camera |
| `RequestChunkLoad` | `slotIndex: number` | Dynamic chunk request |
| `CollectItem` | `crateId: string` | Item crate pickup |
| `SlimeHit` | `{ damage, knockbackDir, knockbackForce }` | Slime contact |

### Remote Functions (Client -> Server, with return)
| Function | Returns | Purpose |
|----------|---------|---------|
| `GetPlayerData` | `{ gold, upgrades, bestTime, bestDepth, totalRuns, wins, lastSeed, defaultCamera }` | Initial data load |
| `ValidateSeed` | `valid: bool, message: string` | Seed validation |

---

## Gameplay Reference

### Controls
| Input | Action |
|-------|--------|
| `W/A/S/D` | Move |
| `Left Shift` | Sprint |
| `Space` | Jump / Air jump |
| `Q` | Use active item |
| `F` | Place active item |
| `E` | Mine wall (pickaxe) / Rescue downed teammate |
| `G` | Give active item to nearest teammate (Coop) |
| `Mouse` | Look (FPS camera) |
| `R` | Toggle FPS/TPS camera |

### Biomes (seeded randomized sequence, 10 slots x 100m each)
| Biome | Key Traits |
|-------|------------|
| **Volcano** | Dark basalt, lava pools, obsidian spikes, lava cascades, high hazard damage (15) |
| **Fortress** | Stone brick, torch posts, crumble blocks, tunnel sections, pillars |
| **Cave** | Limestone, crystal clusters, stalactites, water sources, spire spirals |
| **Mine** | Coal seams, timber support beams, gold veins, ore walls, lanterns |

### Items (11 total)
| Item | Type | Key Mechanic |
|------|------|--------------|
| Healing Potion | Instant | +10 HP/s for 10s, stackable x3 |
| Climbing Rope | Place | 50m rope, grab to slow fall |
| Spring Thing | Place | Timed jumps build bounce height |
| Parachute | Toggle | Cap fall speed at 8 u/s, 3 durability |
| Balloon | Toggle | 45% gravity reduction |
| Steam Jetpack | Hold | Upward thrust, burns water 0.5 L/s |
| Steam Thrower | Hold | Horizontal knockback, burns water 0.8 L/s |
| Piton Spikes | Place | Wall anchors, stackable x5 |
| Javelin | Throw | 40 damage, sticks in surfaces |
| Small Rock | Throw | 25 damage, fast arc |
| Big Rock | Throw | 80 damage, heavy penalty |

### Upgrades (6, 10 tiers each)
| Upgrade | Effect | Max Value |
|---------|--------|-----------|
| Max Health | +25 HP/tier | 350 HP |
| Regen Rate | +1 HP/s/tier | 10 HP/s |
| Move Speed | +2 u/s/tier | 38 u/s walk |
| Fall Resist | -5%/tier | 50% reduction |
| Coin Magnet | +3 stud radius/tier | 32 studs |
| Double Jump | +1 air jump/tier (capped at 3 in-run) | 3 air jumps |

### Run Modifiers
| Modifier | Speed | Gold | Damage | Special |
|----------|-------|------|--------|---------|
| Normal | 1.0x | 1.0x | 1.0x | - |
| SPEEDY | 1.35x | 1.25x | 1.0x | - |
| FRAGILE | 1.0x | 2.0x | 3.0x | - |
| GOLDEN | 1.0x | 3.0x | 1.0x | No regen |
| SLIME RAIN | 1.0x | 1.5x | 1.0x | All terrain pre-slimed |

### Multiplayer Modes
| Mode | Max Players | Win Condition | Special Rules |
|------|-------------|---------------|---------------|
| Singleplayer | 1 | Reach 1000m or best depth | - |
| Cooperative | 4 | All reach 1000m | Downed system (30s bleed), rescue (3s hold E, 8 stud range), item trading (G key, 6 studs) |
| Competitive | 4 | First to reach 1000m | PvP pickaxe (15 dmg, 6 stud range, 0.5s cooldown), throwable items, individual gold |

---

## Known Technical Pitfalls (Lessons from Old Code)

1. **HipHeight must be set once in CharacterAdded, not in applyStats** - Setting it repeatedly causes pogo-stick physics behavior
2. **Zero elasticity (`Elasticity=0`) on all character parts** prevents the infamous "bounce on landing" bug
3. **`humanoid:SetStateEnabled(Jumping, false)`** must be set because Roblox's default PlayerModule overrides JumpHeight=0
4. **Never anchor HRP for more than the minimum time** - anchor for basket sequence, then unanchor with zeroed velocity
5. **`workspace.Gravity = 100`** (not default 196) gives the floaty drop feel
6. **Session folders under `workspace.Levels`** keep all session geometry isolated; destroy on session end
7. **Slots are 100m = 320 studs** - Generate slots 1 and 2 eagerly at run start, then stream on demand
8. **Slot N-2 is safe to unload** after the player passes into slot N (1 slot buffer ahead, 0 behind)
9. **DataStore must be pcall-guarded at module load** - not just at read/write time
10. **`math.random(a, b)` only works for integers in Lua** - use `math.random() * (b-a) + a` for floats
11. **PartBuilders reference in main.server** must go through LevelGenerator, not be required separately
12. **Event handler registration must be done exactly once** - never in both Init() and the calling script

---

## Quality Checklist (Before Shipping)

- [ ] All 10 bugs listed above are fixed and confirmed
- [ ] No `require` cycles (A requires B requires A)
- [ ] Every server event handler has: nil-guard on player, nil-guard on state, inLevel-guard where applicable
- [ ] Every fall damage calc has physics sanity clamp
- [ ] Gold operations are rate-limited server-side
- [ ] DataStore operations are in pcall with warn on failure
- [ ] Character added handler sets HipHeight exactly once
- [ ] All character parts have zero elasticity
- [ ] Level session folders are cleaned up on PlayerRemoving
- [ ] Chunk unload happens after slot is confirmed out of range
- [ ] Basket trapdoor logic guarded against missing DwarvenEntryBasket
- [ ] Death choice has 30s server-side safety timeout
- [ ] Cooperative bleed timers cleaned up on PlayerRemoving
- [ ] PvP cooldowns cleaned up on PlayerRemoving
- [ ] Leaderboard guards against DataStore unavailability
- [ ] All RemoteEvent fires have data type validation on server
- [ ] No `wait()` calls (use `task.wait()` everywhere)
- [ ] No `math.random(float, float)` calls
- [ ] ComboStreak correctly resets on biome transition (timer-based, not position-based)
- [ ] Coin magnet uses throttled 0.08s check interval, not per-frame
