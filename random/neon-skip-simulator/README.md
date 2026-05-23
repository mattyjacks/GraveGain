# 🏃‍♂️ Neon Skip Simulator

A hyper-casual Roblox clicker/simulator game where players click to jump rope in a synthwave neon paradise. Built for rapid development and maximum dopamine hits.

## 🎮 Core Gameplay

**Simple, Addictive Loop:**
1. **Click or Tap** to make your character jump rope
2. Earn **Momentum** (currency) with each skip
3. Buy cooler, faster, more obnoxious glowing ropes
4. Unlock new zones and prestige through rebirths
5. Show off your max-level teleport jumps to friends

## ✨ Features

### 10 Rope Upgrades
- **Basic Cord** → **Godlike Velocity** 
- Each rope increases speed, jump height, and visual effects
- Top-tier ropes include:
  - Particle bursts
  - Neon trails
  - Shockwave effects
  - Screen shake
  - Rainbow effects

### 6 Unlockable Zones
- **Neon Plaza** (starter)
- **Cyber District** (500 momentum)
- **Plasma Core** (3,000 momentum)
- **Void Sector** (15,000 momentum)
- **Sunfire Heights** (60,000 momentum)
- **Quantum Realm** (200,000 momentum)

### 5 Holographic Pets
- Floating orbs that orbit your character
- Multipliers from 1.1x to 3.0x
- Rarities: Common → Legendary

### Rebirth System
- Sacrifice all momentum for permanent multipliers
- 5 rebirth tiers with escalating requirements
- Visual explosion effect on rebirth

### AFK Zone
- Stand in the green zone for passive momentum
- Scales with rebirth multipliers

## 🎵 Gamepasses

| Gamepass | Price | Effect |
|----------|-------|--------|
| **Auto-Skip** | 299 Robux | Automatically skips while held |
| **x2 Momentum** | 399 Robux | Permanent 2x momentum gain |

## ⚠️ TOS Compliance Notice

**IMPORTANT - Read Before Publishing:**

### Audio Guidelines
- **DO NOT** use random audio IDs found online
- **DO NOT** allow players to input arbitrary audio IDs (copyright violation)
- **ONLY** use:
  - Audio you upload yourself (recommended)
  - Roblox's free Sound Effects library (in Toolbox)
  - Leave audio as `nil` to disable sounds

### Asset Guidelines
- **DO NOT** use random asset IDs for skyboxes/textures
- **ONLY** use:
  - Roblox default textures (safe)
  - Assets you upload yourself
  - Creator Marketplace assets with proper licensing

### Monetization
- Gamepass prices comply with Roblox standards
- No gambling mechanics
- No deceptive practices

## 🛡️ Safety Features

This game includes multiple safety systems to ensure TOS compliance and fair play:

### AFK Protection
- **60-minute AFK reward cap** - Rewards stop after 1 hour to prevent playtime inflation
- Clear messaging to players about AFK limits
- Automatic cleanup when players leave

### Data Safety
- **Maximum momentum cap**: 2 billion (prevents integer overflow)
- **Maximum rebirths**: 100 (prevents data bloat)
- **Maximum pet multiplier**: 10x (prevents exploit stacking)
- Real-time value clamping on all stats

### Rate Limiting
- **Shop purchases**: 0.5 second cooldown between buys
- **Skip actions**: 0.1 second minimum cooldown
- **Rebirth requests**: Rate limited to prevent spam
- **Remote events**: All validated and rate-limited

### Accessibility
- **No screen shake effects** - Removed for photosensitive players
- **Auto-Skip penalty**: Slightly slower than manual (encourages active play)
- Visual effects only (no seizure-inducing flashes)

### Exploit Prevention
- Server-side validation on all purchases
- Sanity checks on momentum gains
- DataStore protected calls with error handling
- No client-authoritative value changes

## 🎨 Synthwave Aesthetic

- Dark baseplate with neon blue grid
- Glowing pillars and floating rings
- Gold rebirth pad with particle effects
- Cyan pillars around spawn
- Bloom and color correction effects

## 🕹️ Controls

| Key | Action |
|-----|--------|
| **Click/Tap** | Skip rope |
| **E** | Open shop |

## 🏗️ Project Structure

```
neon-skip-simulator/
├── src/
│   ├── client/
│   │   ├── skip_controller.lua    # Core jump rope mechanics (with safety caps)
│   │   ├── shop_ui.lua            # Shop interface (with rate limiting)
│   │   └── music_system_safe.lua  # TOS-compliant BGM system
│   ├── server/
│   │   ├── leaderstats.lua        # Data saving (with overflow protection)
│   │   ├── zone_manager.lua       # Zone unlocks
│   │   ├── afk_zone.lua           # AFK rewards (with 60min cap)
│   │   ├── rebirth_system.lua     # Prestige system (with rate limiting)
│   │   └── gamepass_handler.lua   # Monetization (with rate limiting)
│   ├── shared/
│   │   ├── game_config.lua        # All game data
│   │   └── safety_config.lua      # Safety limits and accessibility settings
│   ├── gui/
│   │   ├── SkipSimulatorUI.rbxmx  # Main UI
│   │   └── ShopUI.rbxmx           # Shop interface
│   └── workspace/
│       └── map_setup.lua          # World generation
├── default.project.json           # Rojo config
└── rojo.toml                     # Rojo settings
```

## 🚀 Quick Start

1. Install [Rojo](https://rojo.space/)
2. Run `rojo build -o NeonSkipSimulator.rbxl` to create place file
3. Open in Roblox Studio
4. Publish and configure gamepass IDs in `game_config.lua`

## 📝 Setup Checklist

- [ ] Update gamepass IDs in `game_config.lua`
- [ ] Configure DataStore names if needed
- [ ] Upload your own audio or use Roblox Sound Effects library
- [ ] Set spawn location
- [ ] Publish to Roblox
- [ ] Create gamepasses and update IDs
- [ ] Configure developer products (optional)

## 🔧 Key Systems

### Skip Controller
- Handles click/tap input
- Manages jump animations
- Spawns particle effects
- Calculates momentum gain with multipliers
- Equips and updates rope visuals

### Shop System
- Two tabs: Ropes and Pets
- Dynamic button states (affordable/owned)
- Purchase confirmation with visual feedback
- Auto-equip on purchase

### Zone Manager
- Gates block zones until momentum threshold
- Gates become transparent when unlocked
- Billboard labels show requirements

### AFK Zone
- Passive momentum every second
- Scales with rebirth multipliers
- Green particle effect

### Rebirth System
- Gold pad at spawn
- Stand for 3 seconds to rebirth
- Explosion visual effect
- Resets momentum, keeps rebirth tier

## 🎯 Design Philosophy

This game is intentionally minimal to ensure:
- **Fast iteration**: Change values without breaking systems
- **Low maintenance**: Simple data structures, no complex AI
- **High polish**: Focus on VFX, SFX, and UI responsiveness
- **Viral potential**: Visual escalation creates shareable moments

## 🍕 Enjoy!

Built for speed, shipped for fun. The simplest ideas often perform best on Roblox.
