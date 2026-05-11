# GraveGain 3D - Roblox Edition

A 3D first-person co-op horde shooter inspired by Vermintide 2, recreating the core features of the 2D GraveGain game.

## Project Structure

```
3dRoblox/
├── src/
│   ├── shared/           # Shared modules (client + server)
│   │   ├── constants.lua # Game constants, races, classes, enemies
│   │   └── player_data.lua # Player character data and stats
│   ├── server/           # Server-side scripts
│   │   ├── init.server.lua # Server entry point
│   │   ├── game_manager.lua # Game state and mission management
│   │   └── lobby_manager.lua # Lobby and player assignment
│   └── client/           # Client-side scripts
│       ├── init.client.lua # Client entry point
│       └── lobby_ui.lua # Lobby UI and character selection
├── default.project.json  # Rojo configuration
├── package.json          # Node.js dependencies
└── README.md            # This file
```

## Features (Phase 1-3 - Core Framework, FPS Controller, & Dungeons)

### Phase 1 - Implemented ✅
- **4 Races**: Human, Elf, Dwarf, Orc with unique stats
- **4 Classes**: DPS, Tank, Support, Mage (16 race-class combinations)
- **Player Data System**: Character stats, resources (HP, Stamina, Shields, Mana, Rage)
- **Lobby System**: Player joining, race/class selection, ready state
- **Team Assignment**: Automatic team balancing (up to 5 players per team)
- **Game State Management**: Lobby → Loading → In-Game → Mission Complete/Failed
- **Networking**: RemoteEvents for client-server communication

### Phase 2 - Implemented ✅
- **FPS Controller**: First-person camera with mouse look
- **Player Movement**: WASD movement with sprint (Shift)
- **Jumping**: Space to jump with gravity
- **Stamina System**: Drain on sprint, regenerate when idle
- **Melee Weapons**: Sword, Axe, Hammer, Dagger with attack animations
- **Ranged Weapons**: Crossbow, Musket, Pistol, Bow with ammo system
- **Weapon Switching**: Equip different weapons
- **Combat**: Damage calculation, critical hits, knockback
- **Character Spawning**: Server-side character creation with proper joints
- **Game State Transitions**: Loading screens, mission complete/failed screens

### Phase 3 - Implemented ✅
- **Procedural Dungeon Generation**: Room-based with corridors and features
- **Dungeon Rendering**: 3D floor tiles and walls with collision
- **10 Enemy Types**: Skeletons, Zeds, Skulls, Necromancers with unique stats
- **Enemy AI**: Idle → Patrol → Chase → Attack state machine
- **Horde Spawner**: Wave-based enemy spawning with difficulty scaling
- **Director AI**: Dynamic difficulty adjustment based on player health
- **Mission Manager**: Orchestrates dungeon, spawning, and mission flow
- **Mission HUD**: Displays player stats, mission info, crosshair, weapon info
- **Wave System**: Progressive difficulty with increasing enemy count

### Planned (Phases 4-8)
- Item and loot system
- Advanced HUD (minimap, radar, objectives)
- VFX, audio, and lighting
- Ability system per class
- Melee/ranged balance tuning
- Boss encounters

## Development Setup

### Prerequisites
- Roblox Studio (latest version)
- Node.js 14+ (for Rojo)
- Rojo plugin installed in Roblox Studio

### Running the Project

1. **Start Rojo server**:
   ```powershell
   cd c:\GitHub5\GraveGain\v2\3dRoblox
   npx rojo serve
   ```

2. **In Roblox Studio**:
   - Create a new game
   - Install Rojo plugin from Creator Marketplace
   - Click the Rojo plugin button
   - Connect to `localhost:34872`

3. **Code sync**: Changes to `.lua` files in `src/` automatically sync to Roblox Studio

## Game Systems

### Constants (`src/shared/constants.lua`)
Defines all game enums and configurations:
- Races and their names
- Classes and their names
- Enemy types
- Game states
- Difficulty levels

### PlayerData (`src/shared/player_data.lua`)
Manages individual player character data:
- Race/class selection
- Health, stamina, shields, mana, rage
- Combat stats (kills, deaths, gold, XP)
- Status (alive, down, reviving)
- Methods for damage, healing, resource management

### GameManager (`src/server/game_manager.lua`)
Server-side game state management:
- Game state transitions
- Team assignments
- Mission timing
- Difficulty multipliers
- RemoteEvent creation

### LobbyManager (`src/server/lobby_manager.lua`)
Handles lobby functionality:
- Player joining/leaving
- Race/class selection
- Ready state tracking
- Team assignment
- Game start logic

### LobbyUI (`src/client/lobby_ui.lua`)
Client-side lobby interface:
- Race selection grid
- Class selection grid
- Ready button
- Player list display
- Event listeners for state updates

## Race Stats

| Race | HP | Speed | Special | Damage |
|------|----|----|---------|--------|
| Human | 100 | 250 | Shields | 12/10 |
| Elf | 75 | 275 | Mana | 14/12 |
| Dwarf | 150 | 200 | Armor | 18/8 |
| Orc | 200 | 225 | Rage | 20/6 |

*Melee/Ranged damage values*

## Networking Architecture

### Server → Client
- `GameStateChanged`: Broadcasts game state changes
- `PlayerJoined`: Broadcasts lobby state to all clients

### Client → Server
- Player data folder with IntValues/BoolValues for selections
- Changes trigger server-side event handlers

## New Files (Phase 2-3)

**Phase 2 - Client Scripts:**
- `fps_controller.lua` - First-person camera, movement, input handling
- `melee_weapon.lua` - Melee combat with attacks and animations
- `ranged_weapon.lua` - Ranged combat with ammo and reload
- `game_state_manager.lua` - Game state transitions and initialization

**Phase 2 - Server Scripts:**
- `character_spawner.lua` - Character creation with humanoid and joints

**Phase 2 - Shared Scripts:**
- `weapon_data.lua` - Weapon definitions and stats

**Phase 3 - Client Scripts:**
- `mission_hud.lua` - HUD display with player stats, mission info, crosshair

**Phase 3 - Server Scripts:**
- `dungeon_generator.lua` - Procedural dungeon generation with rooms/corridors
- `dungeon_renderer.lua` - Renders dungeon tiles and walls in workspace
- `enemy_ai.lua` - Enemy state machine (Idle/Patrol/Chase/Attack)
- `horde_spawner.lua` - Wave spawning with director AI
- `mission_manager.lua` - Orchestrates entire mission flow

**Phase 3 - Shared Scripts:**
- `enemy_data.lua` - 10 enemy types with stats and categories

## Weapon Stats

### Melee Weapons
| Weapon | Damage | Speed | Range | Knockback |
|--------|--------|-------|-------|-----------|
| Sword | 25 | 1.0 | 3 | 10 |
| Axe | 35 | 0.8 | 3.5 | 15 |
| Hammer | 40 | 0.6 | 3 | 20 |
| Dagger | 15 | 1.5 | 2 | 5 |

### Ranged Weapons
| Weapon | Damage | Fire Rate | Range | Ammo |
|--------|--------|-----------|-------|------|
| Crossbow | 30 | 1.2 | 100 | 30 |
| Musket | 50 | 2.0 | 150 | 30 |
| Pistol | 20 | 0.5 | 80 | 30 |
| Bow | 25 | 0.8 | 120 | 30 |

## Controls

- **WASD** - Move
- **Mouse** - Look around
- **Left Shift** - Sprint (drains stamina)
- **Space** - Jump
- **Left Click** - Attack/Fire weapon
- **Right Click** - Aim (ranged weapons)
- **R** - Reload (ranged weapons)

## Enemy Types (Phase 3)

| Enemy | HP | Damage | Speed | Category |
|-------|----|----|-------|----------|
| Goblin Skeleton | 15 | 3 | 120 | Standard |
| Elven Skeleton | 25 | 5 | 100 | Standard |
| Goblin Zed | 40 | 8 | 90 | Standard |
| Small Orc Zed | 60 | 12 | 80 | Standard |
| Flying Elf Skull | 10 | 30 | 150 | Special |
| Medium Orc Zed | 150 | 20 | 70 | Elite |
| Dwarven Zed | 200 | 15 | 60 | Elite |
| Human Zed | 500 | 25 | 80 | Boss |
| Huge Orc Zed | 800 | 40 | 50 | Boss |
| Elven Necromancer | 400 | 15 | 60 | Boss |

## Director AI System

The director AI dynamically adjusts difficulty based on player health:
- **High HP (>70%)**: Increase intensity, spawn more enemies
- **Medium HP (30-70%)**: Maintain current intensity
- **Low HP (<30%)**: Decrease intensity, reduce enemy count
- **Max active enemies**: 15-30 depending on intensity
- **Wave duration**: 30 seconds between waves
- **Difficulty multiplier**: Applied to all enemy stats

## Mission Flow

1. **Lobby**: Players select race/class and ready up
2. **Loading**: Dungeon generates, characters spawn
3. **In-Game**: Waves spawn every 30 seconds, director adjusts difficulty
4. **Mission End**: 10 minutes elapsed OR all players dead
5. **Results**: Mission complete/failed screen

## Next Steps (Phase 4)

1. Item and loot system
2. Advanced HUD (minimap, radar, objectives)
3. VFX and particle effects
4. Audio system
5. Ability system per class

## Notes

- Uses Rojo for file-based development workflow
- All code is Lua 5.1 compatible with Roblox extensions
- Server-authoritative architecture for security
- Modular design for easy feature addition
- Stamina system prevents infinite sprinting
- Weapons have attack cooldowns and ammo limits
- Enemy AI uses simple state machine for performance
- Procedural dungeons are 100x100 tiles with 15 rooms
- Director AI prevents difficulty spikes and valleys

## Phase 4 - Items, Loot & Advanced HUD

### New Features
- **Item System**: 20+ items with rarity tiers (Common to Legendary)
- **Loot Drops**: Enemies drop gold, potions, ammo, artifacts
- **Loot Manager**: Handles item spawning and collection
- **Advanced HUD**: Minimap, radar, objectives, detailed stats
- **Health Bar**: Dynamic color-changing health bar
- **Inventory System**: 20-slot inventory with item management
- **Item Types**: Gold, Health Potions, Ammo Boxes, Artifacts, Food
- **Rarity Colors**: Visual feedback for item rarity
- **Gold System**: Collect gold from enemies and items
- **Inventory UI**: Press I to open/close inventory

## Phase 5 - VFX, Audio & Polish

### New Features
- **VFX System**: Hit effects, blood splatters, heal effects, critical hits
- **Particle Effects**: Muzzle flashes, loot pickups, damage numbers
- **Audio Manager**: Sound effects, music, volume controls
- **Sound Effects**: Weapon sounds, hit sounds, enemy death, item pickup
- **Music System**: Lobby, gameplay, boss, victory, defeat tracks
- **Settings Menu**: Graphics, audio, gameplay, UI settings (Press ESC)
- **Stats Tracker**: Tracks kills, deaths, damage, gold, achievements
- **Achievements**: 10 achievements with unlock tracking
- **Results Screen**: Mission complete/failed with detailed statistics
- **Damage Numbers**: Floating damage indicators with critical hit highlighting
- **Wave Indicators**: Visual feedback when new waves start
- **Polish**: Smooth animations, color feedback, visual polish

### VFX Effects
- **Hit Effect**: Expanding neon sphere on impact
- **Blood Splatter**: Particle spray with gravity
- **Heal Effect**: Green expanding sphere
- **Critical Hit**: Gold burst with surrounding particles
- **Loot Pickup**: Color-coded pickup effect
- **Muzzle Flash**: Orange flash at weapon muzzle
- **Damage Numbers**: Floating text with color coding

### Audio Features
- **Master Volume**: Control all audio
- **Music Volume**: Control background music
- **SFX Volume**: Control sound effects
- **Voice Volume**: Control voice chat
- **Footsteps**: Randomized footstep sounds
- **Weapon Sounds**: Different sounds for melee/ranged
- **Enemy Sounds**: Death and hit sounds
- **UI Sounds**: Menu and interaction sounds

### Achievements
- **First Blood**: Kill your first enemy
- **Centurion**: Reach 100 kills
- **Legendary Warrior**: Reach 1000 kills
- **Critical Moment**: Land first critical hit
- **Precision Master**: Land 10 crits in one mission
- **Wave Survivor**: Survive wave 10
- **Treasure Hunter**: Collect first artifact
- **Lifesaver**: Revive a teammate
- **Nightmare Conqueror**: Complete Nightmare difficulty
- **Flawless**: Complete mission without taking damage

### Settings Options
- **Graphics**: Quality, motion blur, bloom, shadows
- **Audio**: Master, music, SFX, voice volumes
- **Gameplay**: Mouse sensitivity, invert mouse, FOV, motion sickness mode
- **UI**: HUD scale, show FPS, colorblind mode, sprint/crouch toggle

## Version
5.0.0 - Phase 5: VFX, Audio & Polish Complete
