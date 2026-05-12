# GraveGain 2.5D - Top-Down ARPG

A complete top-down action RPG dungeon crawler built with Rojo and Roblox. Play as one of 4 races (Human, Dwarf, Elf, Orc) as the Adventurer class, explore procedurally generated dungeons, fight enemies, collect loot, and level up.

## Complete Game Features

### Core Systems
- **Camera**: Fixed 45-60 degree top-down isometric view
- **Movement**: WASD movement with mouse aim, dodge roll with Space
- **Combat**: Left-click attacks, right-click abilities, number keys 1-4 hotbar
- **Character**: 4 races with unique stat bonuses, leveling system, skill trees

### World Generation
- **Procedural Dungeons**: BSP-based room generation with corridors
- **5 Biomes**: Crypt, Forest, Cave, Hellscape, Ruins
- **4 Acts**: Each with 3-5 floors + boss
- **Environmental Hazards**: Lava, poison, spikes, breakable objects

### Combat & Abilities
- **8 Abilities**: Slash, Fireball, Ice Shards, Lightning Bolt, Poison Cloud, Holy Strike, Dark Bolt, Dodge Roll
- **7 Damage Types**: Physical, Fire, Ice, Lightning, Poison, Holy, Dark
- **6 Status Effects**: Burn, Freeze, Stun, Bleed, Slow, Poison
- **Cooldown System**: Per-ability cooldowns and mana costs

### Enemies & AI
- **4 Normal Types**: Skeleton, Zombie, Spider, Goblin
- **2 Special Types**: Demon, Boss
- **AI States**: Idle, Patrol, Chase, Attack, Flee
- **Elite Affixes**: Extra Fast, Teleporter, Fire Chains, Molten, Arcane

### Loot & Economy
- **6 Rarity Tiers**: Common, Uncommon, Rare, Epic, Legendary, Unique
- **10 Equipment Slots**: Head, Chest, Legs, Feet, Gloves, 2 Rings, Amulet, Weapon, Offhand
- **8 Weapon Types**: Sword, Axe, Mace, Bow, Staff, Dagger, Crossbow, Wand
- **Random Affixes**: Prefix + Suffix system for unique items
- **Potions**: Health, Mana, Speed, Damage
- **Gold Currency**: Drop from enemies, sell items

### Character Progression
- **5 Core Stats**: Strength, Dexterity, Intelligence, Vitality, Luck
- **Leveling**: Gain XP from kills, level up to gain stat and skill points
- **3 Skill Branches**: Melee/Physical, Magic/Elemental, Survival/Utility
- **Stat Points**: 5 per level to distribute
- **Skill Points**: 1 per level to invest in branches

### UI & HUD
- **Health/Mana Bars**: Bottom left with current/max values
- **Ability Hotbar**: Bottom center showing 4 abilities
- **Minimap**: Top right with fog of war
- **XP Bar**: Bottom center showing level progress
- **Damage Numbers**: Floating text with critical highlighting
- **Buff/Debuff Panel**: Status effect icons
- **Inventory**: Press I to open (20 slots)
- **Skill Tree**: Press K to open
- **Character Stats**: Press C to open
- **Quest Log**: Press Q to open

### Networking
- **Server-Authoritative**: All damage and loot calculations on server
- **Co-op Support**: 1-4 players per dungeon
- **Individual Loot**: Each player gets their own drops
- **RemoteEvents**: For ability usage, damage, loot drops
- **RemoteFunctions**: For stat and dungeon data queries

### Audio & VFX
- **Ambient Sounds**: Per-biome background music
- **Hit Effects**: Colored particles based on damage type
- **Spell VFX**: Elemental-themed visual effects
- **Loot Glow**: Rarity-based color coding
- **Screen Shake**: On big hits and explosions
- **Damage Numbers**: Floating text with animations

## File Structure

```
src/
├── shared/
│   ├── game_data.lua           # All game constants and balance
│   ├── character_system.lua    # Character stats, leveling, abilities
│   ├── dungeon_generator.lua   # Procedural dungeon generation
│   ├── combat_system.lua       # Damage calculation, effects
│   ├── loot_system.lua         # Loot generation, rarity, affixes
│   └── networking.lua          # RemoteEvent/Function setup
├── server/
│   ├── main.server.lua         # Server entry point
│   ├── game_manager.server.lua # Player/dungeon management
│   └── enemy_ai.lua            # Enemy AI and behavior
└── client/
    ├── main.client.lua         # Client entry point
    ├── camera_controller.lua   # Isometric camera system
    ├── movement_controller.lua # WASD + dodge roll
    ├── input_handler.lua       # Keyboard/mouse input
    ├── hud_system.lua          # UI elements and updates
    └── audio_vfx_manager.lua   # Sound effects and particles
```

## Setup Instructions

### Prerequisites
- Roblox Studio installed
- Rojo installed (v7.6.1 via cargo)

### Quick Start

1. **Start Rojo Server**
   ```powershell
   cd c:\GitHub5\GraveGain\v2\2point5dRoblox
   rojo serve
   ```

2. **Connect in Roblox Studio**
   - Open Roblox Studio
   - Create a new blank place
   - Install Rojo plugin from Creator Marketplace
   - Click "Connect" to sync with local server

3. **Play the Game**
   - Press Play in Studio
   - Use WASD to move, mouse to aim
   - Left-click to attack, 1-4 for abilities
   - Space to dodge roll
   - I for inventory, K for skills, C for stats

## Game Balance

### Difficulty Multipliers
- Normal: 1.0x
- Nightmare: 1.5x
- Hell: 2.5x

### Player Progression
- Base Health: 100 + (Vitality × 10)
- Base Mana: 50 + (Intelligence × 5)
- Damage: 5 + (Strength × 1.5)
- Crit Chance: Dexterity × 1%
- Crit Damage: 1.5x multiplier

### Enemy Scaling
- Health: +20% per floor
- Damage: +10% per floor
- XP: +10% per floor

### Loot Rates
- Common: 50%
- Uncommon: 25%
- Rare: 15%
- Epic: 8%
- Legendary: 2%

## Controls

| Key | Action |
|-----|--------|
| W/A/S/D | Move |
| Mouse | Aim |
| Left Click | Attack |
| Right Click | Secondary ability |
| 1-4 | Ability hotbar |
| Space | Dodge roll |
| Shift | Sprint |
| I | Inventory |
| K | Skill tree |
| C | Character stats |
| Q | Quest log |

## Development

All systems are fully modular and integrated:
- Character system handles stats, leveling, abilities
- Combat system calculates damage, crits, effects
- Dungeon generator creates unique layouts each run
- Enemy AI handles pathfinding and combat
- Loot system generates random items with affixes
- HUD updates in real-time with character data
- Networking syncs all actions between client/server

## Next Steps

- Add character selection UI
- Implement town hub with NPCs
- Add quest system
- Create boss encounters with unique mechanics
- Implement multiplayer lobby
- Add achievements and leaderboards
- Polish animations and VFX
