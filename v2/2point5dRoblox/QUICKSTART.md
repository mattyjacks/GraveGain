# GraveGain 2.5D - Quick Start Guide

## 30-Second Setup

```powershell
cd c:\GitHub5\GraveGain\v2\2point5dRoblox
rojo serve
```

Then in Roblox Studio:
1. Create new blank place
2. Install Rojo plugin (Creator Marketplace)
3. Click "Connect"
4. Press Play!

## Controls

- **WASD** - Move
- **Mouse** - Aim
- **Left Click** - Attack
- **1-4** - Abilities
- **Space** - Dodge
- **Shift** - Sprint
- **I** - Inventory
- **K** - Skills
- **C** - Stats
- **Q** - Quests

## What's Included

✅ **4 Races** - Human, Dwarf, Elf, Orc
✅ **Procedural Dungeons** - Unique layout each run
✅ **8 Abilities** - Slash, Fireball, Ice Shards, Lightning, Poison Cloud, Holy Strike, Dark Bolt, Dodge
✅ **Combat System** - Damage, crits, status effects
✅ **Loot System** - 6 rarity tiers with random affixes
✅ **Enemy AI** - 6 enemy types with state machine
✅ **HUD** - Health, mana, abilities, minimap, XP
✅ **Networking** - Server-authoritative, co-op ready

## Game Loop

1. Spawn in dungeon
2. Fight enemies (left-click or 1-4)
3. Collect loot
4. Level up (gain stat/skill points)
5. Progress to next floor
6. Repeat!

## File Structure

```
src/
├── shared/     - Game data, systems, balance
├── server/     - Game manager, enemy AI
└── client/     - Camera, movement, HUD, input
```

## Key Files

| File | Purpose |
|------|---------|
| `game_data.lua` | All constants and balance |
| `character_system.lua` | Player stats and leveling |
| `dungeon_generator.lua` | Procedural generation |
| `combat_system.lua` | Damage and effects |
| `loot_system.lua` | Item generation |
| `enemy_ai.lua` | Enemy behavior |
| `hud_system.lua` | UI and HUD |
| `main.client.lua` | Client entry point |
| `main.server.lua` | Server entry point |

## Gameplay Tips

- **Dodge Roll** (Space) has i-frames - use to avoid damage
- **Sprint** (Shift) for faster movement
- **Abilities 1-4** are hotkeyed - use them!
- **Collect Loot** - better gear = more damage
- **Level Up** - allocate stat points to STR for damage
- **Status Effects** - some abilities apply debuffs

## Difficulty

- **Normal** - 1.0x multiplier
- **Nightmare** - 1.5x multiplier
- **Hell** - 2.5x multiplier

## Stats

- **STR** - Increases damage
- **DEX** - Increases crit chance and dodge
- **INT** - Increases mana and spell power
- **VIT** - Increases health
- **LCK** - Increases loot rarity

## Races

| Race | Bonus | Penalty |
|------|-------|---------|
| Human | +10% XP | None |
| Dwarf | +40% Health | -5% Speed |
| Elf | +20% Mana, +40% Speed | -40% Health |
| Orc | +50% Damage, +20% Lifesteal | -30% Mana |

## Abilities

| Ability | Cost | Cooldown | Effect |
|---------|------|----------|--------|
| Slash | 0 | 0.5s | Basic melee attack |
| Fireball | 30 | 2s | AoE fire damage |
| Ice Shards | 25 | 1.5s | Ranged ice damage |
| Lightning | 28 | 1.8s | AoE lightning damage |
| Poison Cloud | 35 | 2.5s | AoE poison damage |
| Holy Strike | 20 | 1.2s | Melee holy damage |
| Dark Bolt | 25 | 1.5s | Ranged dark damage |
| Dodge Roll | 0 | 0.8s | Dodge with i-frames |

## Enemies

| Type | Health | Damage | XP |
|------|--------|--------|-----|
| Skeleton | 10 | 2 | 25 |
| Zombie | 15 | 3 | 35 |
| Spider | 8 | 2.5 | 30 |
| Goblin | 12 | 3.5 | 40 |
| Demon | 25 | 5 | 75 |
| Boss | 100 | 10 | 500 |

## Loot Rates

- Common: 50%
- Uncommon: 25%
- Rare: 15%
- Epic: 8%
- Legendary: 2%

## Troubleshooting

**Game won't start?**
- Make sure `rojo serve` is running
- Check Rojo is connected in Studio
- Create a blank place (not template)

**Can't move?**
- Make sure character spawned
- Check WASD keys work
- Look at console for errors

**No enemies?**
- Dungeons generate on spawn
- Walk around to find them
- Check floor is loaded

**Loot not dropping?**
- Kill more enemies
- Check inventory space
- Loot rates are random

## Next Steps

- Explore all 5 biomes
- Try different races
- Collect rare items
- Level up and allocate stats
- Experiment with abilities
- Find the boss!

---

**Ready to play?** Start Rojo and connect in Studio!
