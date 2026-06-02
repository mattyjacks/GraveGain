# JetSkies 🌊☁️

**Open World Sky Exploration Game for Roblox**

Pilot your customizable JetSky through a world of floating islands scattered across the sky. Collect golden rings, discover hidden secrets, and upgrade your vehicle to soar to new heights.

## Gameplay

Explore a procedural world of floating sky islands, each with unique challenges and rewards. Collect rings to unlock powerful upgrades for your JetSky and push the limits of how high you can fly.

### Controls
| Key | Action |
|-----|--------|
| **W/S** | Pitch forward/back (controls speed) |
| **A/D** | Turn left/right |
| **Space** | Ascend / Activate Boost (with Shift) |
| **Ctrl** | Descend |
| **Shift** | Speed Boost (consumes boost fuel) |
| **Esc** | Pause Menu |

## Features

### Core Systems
- ✅ **6-DOF Flight Physics** - Momentum-based movement with realistic tilt
- ✅ **Boost System** - Limited fuel that recharges, with visual feedback
- ✅ **Procedural World** - 6 unique islands (Starter/Explorer/Summit types)
- ✅ **Ring Collection** - Golden rings + hidden collectibles
- ✅ **Upgrade Shop** - 3 upgrade tracks (Speed, Boost, Handling) with 5 tiers each
- ✅ **Persistent Saves** - DataStore integration for progress
- ✅ **Dynamic Camera** - Third-person follow with speed-based zoom
- ✅ **Visual HUD** - Speedometer, altitude meter, ring counter, boost bar

### Island Types
| Type | Height Range | Rings | Difficulty |
|------|--------------|-------|------------|
| Starter | 0-100 studs | 5-8 + 1 hidden | Easy |
| Explorer | 100-400 studs | 10-15 + 1 hidden | Medium |
| Summit | 400-800 studs | 15-25 + 1 hidden | Hard |

### Upgrades
- **Engine Power** - Increase base flight speed (+10% per tier)
- **Boost Capacity** - Extend boost duration (+0.5s per tier)
- **Agility** - Improve turn responsiveness (+15% per tier)

## Project Structure

```
/roblox-new/jetskies/
├── default.project.json     # Rojo configuration
├── README.md
└── src/
    ├── shared/
    │   ├── game_data.lua         # Constants & configs
    │   ├── upgrade_data.lua      # Upgrade calculations
    │   ├── jetsky_models.lua     # Model templates
    │   └── collectibles.lua      # Island/ring spawning
    ├── client/
    │   ├── main.client.lua       # Client bootstrap
    │   ├── flight_controller.lua # Movement physics
    │   ├── camera_controller.lua # Third-person camera
    │   ├── collection_tracker.lua# Ring detection
    │   ├── hud.lua               # UI rendering
    │   └── pause_menu.lua        # Settings menu
    └── server/
        ├── main.server.lua       # Server entry point
        ├── world_generator.lua   # Island spawning
        ├── upgrade_manager.lua   # Shop logic
        └── save_manager.lua      # DataStore wrapper
```

## Development

### Prerequisites
- [Rojo](https://rojo.space/) installed
- Roblox Studio

### Setup
```bash
# Install rojo (if not already installed)
cargo install rojo

# Serve the project
rojo serve
```

Then open Roblox Studio, install the Rojo plugin, and connect to `localhost:34872`.

### Build for Roblox
```bash
rojo build -o jetskies.rbxlx
```

## Technical Details

- **Physics**: Custom 6-DOF flight system with momentum decay
- **Networking**: Server-authoritative with RemoteEvents/Functions
- **Storage**: Roblox DataStore for persistent player data
- **Performance**: Optimized island culling, efficient collision checks

## Future Features
- Multiplayer racing mode
- Trick system (barrel rolls, flips)
- Weather effects (wind currents, storms)
- Custom island editor
- Achievement system
- Leaderboards

---

Made with 💙 for sky explorers everywhere.
