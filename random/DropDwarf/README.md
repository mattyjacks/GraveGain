# DropDwarf

A first-person Roblox drop game. Fall 1,000 meters through procedurally generated biomes, collect gold, survive hazards, and post your best time and depth to the leaderboard.

---

## Gameplay

You spawn in the hub, set a seed, pick a run modifier, and jump into the shaft. The goal is to fall as deep as possible as fast as possible — landing on platforms, grabbing ropes, bouncing on springs, and dodging slimes — without dying. Gold collected during the run persists and is spent on permanent upgrades between runs.

On death you are shown a 2x2 choice screen: respawn at the basket (top of the shaft), reset the run, or return to the hub — with or without keeping your timer.

---

## Controls

| Input | Action |
|-------|--------|
| `W / A / S / D` | Move |
| `Left Shift` | Sprint |
| `Space` | Jump / Air jump (if upgraded) |
| `Q` | Use active item |
| `F` | Place active item |
| `E` | Mine wall (pickaxe) |
| `Mouse` | Look (FPS camera) |

---

## Biomes

The 1,000 m shaft is divided into 10 segments of 100 m each. Each run gets a seeded randomized sequence of biomes — the same seed always produces the same shaft layout.

| Biome | Atmosphere |
|-------|-----------|
| **Volcano** | Dark basalt platforms, lava orange glow, heavy fog |
| **Fortress** | Stone brick walls, torchlit, enclosed tunnel sections |
| **Cave** | Blue-grey limestone, crystal accents, water sources |
| **Mine** | Iron-veined rock, ore walls, dense tunnel layouts |

---

## Items

Items are carried in your backpack. Total carried weight reduces walk speed (up to -70%) and multiplies fall damage (+4% per kg).

### Utility
| Item | Type | Effect |
|------|------|--------|
| **Healing Potion** | Instant | +10 HP/s for 10 seconds |
| **Climbing Rope** | Place | 50 m rope from a platform edge; grab to slow fall |
| **Spring Thing** | Place | Bouncy cushion; time jumps to build launch height |
| **Parachute** | Toggle | Caps fall speed at 8 u/s; 3 terrain-hit durability |
| **Balloon** | Toggle | Reduces gravity to 45% |
| **Steam Jetpack** | Hold | Burns water for upward thrust (0.5 L/s) |
| **Steam Thrower** | Hold | Blasts steam for horizontal knockback (0.8 L/s) |
| **Piton Spikes** | Place | Hammer into vertical walls; stand or hang on them |

> Water tanks start half-full (2.5 L). Refill at water sources in Cave, Mine, and Fortress biomes.

### Competitive (Multiplayer)
| Item | Type | Damage |
|------|------|--------|
| **Javelin** | Throw | 40 HP direct hit; sticks into surfaces (can be stood on) |
| **Small Rock** | Throw | 25 HP; fast arc, travels far |
| **Big Rock** | Throw | 80 HP; slow/short arc, very heavy (-speed, +fall damage) |

---

## Upgrades

Spent between runs in the hub shop. All upgrades persist across sessions (saved to DataStore).

| Upgrade | Effect per Tier | Max Tiers |
|---------|----------------|-----------|
| **Max Health** | +25 HP | 10 (350 HP max) |
| **Regen Rate** | +1 HP/s passive regen | 10 |
| **Move Speed** | +2 u/s walk & sprint | 10 |
| **Fall Resist** | -5% fall damage taken | 10 (50% reduction max) |
| **Coin Magnet** | +3 stud pickup radius | 10 (32 stud radius max) |
| **Double Jump** | +1 air jump per fall | 10 (capped at 3 in-run) |

---

## Run Modifiers

Selected in the hub before starting a run.

| Modifier | Effect |
|----------|--------|
| **Normal** | No changes |
| **SPEEDY** | +35% movement speed, ×1.25 gold |
| **FRAGILE** | ×2 gold, but ×3 fall damage |
| **GOLDEN** | ×3 gold everywhere, no health regen |
| **SLIME RAIN** | All terrain is slimed from the start, ×1.5 gold |

---

## Multiplayer

Supports cooperative and competitive sessions via the lobby system.

- **Cooperative** — teammates share the shaft. Downed players can be rescued by teammates within range. If not rescued in time, they are fully eliminated.
- **Competitive** — PvP pickaxe swings and throwable items enabled. Hitting opponents deals damage and knockback.

---

## Development

Built with [Rojo](https://rojo.space/). Sync the project into Roblox Studio before playtesting.

```
rojo serve default.project.json
```

### Project Layout

```
src/
  client/
    main.client.lua       -- entry point, event wiring
    fps_camera.lua        -- first-person mouse-look camera
    movement.lua          -- walk, sprint, jump, air jump, coyote time
    active_item.lua       -- item use/place/throw input & physics effects
    pickaxe_model.lua     -- procedural pickaxe viewmodel & mining
    hud.lua               -- all in-run HUD elements
    hub_ui.lua            -- hub shop, upgrades, lobby, leaderboard panels
    backpack_ui.lua       -- in-run item backpack display
    visuals.lua           -- biome lighting & atmosphere transitions
    slime_enemy.lua       -- client-side slime hazard behaviour
    moving_platforms.lua  -- client-side moving platform sync
  server/
    main.server.lua       -- game loop, death/win handling, fall damage
    level_generator.lua   -- procedural shaft + biome generation
    hub_generator.lua     -- hub arena geometry
    item_handler.lua      -- server-side item state & effect application
    player_data.lua       -- DataStore persistence (gold, upgrades, records)
    session.lua           -- multiplayer session grouping & coop/pvp state
    leaderboard.lua       -- ordered time/depth records
  shared/
    networking.lua        -- RemoteEvent & RemoteFunction definitions
    game_data.lua         -- core constants (depth, fall damage, biomes, modifiers)
    item_data.lua         -- item definitions & weight system constants
    upgrade_data.lua      -- upgrade tiers, costs, stat computation
    biome_data.lua        -- biome visual configs & procedural generation params
    seed_system.lua       -- deterministic seeded RNG
    game_mode.lua         -- cooperative / competitive mode configs
```

---

## Leaderboard

Two global leaderboards (top 100 entries each):
- **Fastest Time** — time to reach the bottom (1,000 m)
- **Greatest Depth** — deepest point reached before death or reset
