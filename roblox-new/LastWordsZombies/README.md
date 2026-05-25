# Dead-Letter Drop

A relentless, corridor-style typing survival game built in Roblox with Rojo compatibility.

## Game Concept

Type the words hovering over zombie heads to detonate them before they reach you. Features physics-based knockback, neon-green viscera explosions, and a dark synth soundtrack.

## Features

### Core Gameplay
- **Auto-targeting system**: Start typing any letter to lock onto the closest zombie whose word starts with that letter
- **Physics-based knockback**: Explosions send zombies flying backward into the horde
- **Progressive difficulty**: Words get harder as waves increase
- **Satisfying combat**: Neon-green blood, ragdoll physics, and heavy bass thumps

### Visual Effects
- **Corridor environment**: Dimly lit concrete tunnel with industrial atmosphere
- **Particle effects**: Green blood splatter, explosion effects, and dynamic lighting
- **Ragdoll physics**: Unanchored zombie bodies with realistic physics
- **Atmospheric lighting**: Emergency lights and fog effects

### Audio System
- **Dark synth soundtrack**: Industrial basslines reminiscent of DeathbyRomy
- **Dynamic sound effects**: Typing sounds, explosions, zombie growls
- **Distance-based audio**: Heartbeat effects when zombies get close
- **Reverb effects**: Corridor acoustics for immersive sound

### Premium Content (Monetization)
- **Blood effects**: Neon green (default), electric blue, fire red, cosmic purple, golden
- **Font styles**: Default, retro pixel, cyberpunk, terminal
- **Music tracks**: Dark synth, industrial bass, techno horror, ambient dread

## Installation & Setup

### Prerequisites
- Roblox Studio
- Rojo (for development)
- Node.js (optional, for build tools)

### Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd roblox-new/LastWordsZombies
   ```

2. **Install Rojo** (if not already installed)
   ```bash
   npm install -g @rojo-rbx/rojo
   ```

3. **Open in Roblox Studio**
   - Create a new Baseplate place
   - Install the Rojo plugin from the Roblox Creator Marketplace
   - Click "Connect" in the Rojo plugin
   - Run `rojo serve` in the project directory

4. **Start the game**
   - The game will automatically sync with Roblox Studio
   - Press Play to test

### Development Commands

```bash
# Start development server
rojo serve

# Build for production
rojo build

# Sync with existing place
rojo serve --place <place-id>
```

## Project Structure

```
src/
├── shared/
│   ├── game_data.lua          # Game constants and configuration
│   └── word_dictionary.lua    # Word pools with difficulty scaling
├── server/
│   ├── main.server.lua        # Main server controller
│   └── zombie_spawner.lua     # Zombie spawning and AI
└── client/
    ├── main.client.lua        # Main client controller
    ├── typing_handler.lua     # Input handling and auto-targeting
    ├── audio_manager.lua      # Sound system and music
    └── premium_store.lua      # Monetization and visual upgrades
```

## Game Mechanics

### Typing System
- No clicking required - just start typing
- Auto-targets closest zombie matching first letter
- Visual feedback shows typed letters in green
- Wrong letters reset current target

### Physics Formula
The knockback force is calculated using:
```
F_knockback = P * (1 - d/R) * û
```
Where:
- P = base blast pressure
- d = distance to target  
- R = maximum blast radius
- û = unit direction vector

### Wave Progression
- **Wave 1-3**: Easy words (3-5 letters)
- **Wave 4-7**: Medium words (6-8 letters) 
- **Wave 8-14**: Hard words (9-12 letters)
- **Wave 15+**: Extreme words (13+ letters)

### Scoring System
- Word completion: 100 points
- Knockback hits: 25 points
- Wave completion: 1000 points
- Survival time: 10 points/second
- Combo multiplier: 1.5x for consecutive hits

## Controls

- **Any letter**: Start typing/auto-target
- **Complete word**: Destroy zombie with explosion
- **ESC**: Open settings menu
- **I**: Open premium store
- **Enter**: Start game from menu

## Configuration

### Game Balance
Edit `src/shared/game_data.lua` to adjust:
- Zombie speed and spawn rates
- Explosion radius and damage
- Scoring multipliers
- Wave progression

### Word Lists
Edit `src/shared/word_dictionary.lua` to:
- Add custom words
- Adjust difficulty categories
- Modify complexity calculations

### Audio Assets
Replace placeholder audio IDs in `src/client/audio_manager.lua`:
- Set actual Roblox audio asset IDs
- Adjust volume levels
- Configure reverb settings

## Monetization Integration

### Premium Store System
The game includes a complete monetization system:

1. **Virtual Currency**: Coins earned through gameplay
2. **Visual Upgrades**: Blood effects, fonts, music tracks
3. **Data Persistence**: Player purchases saved to DataStore
4. **UI Integration**: Full store interface with categories

### Implementation Notes
- Uses Roblox's built-in developer products
- Client-side validation with server-side verification
- GDPR-compliant data handling
- Parental controls support

## Performance Optimizations

### Rendering
- LOD system for distant zombies
- Particle pooling for effects
- Occlusion culling for corridor
- Surface optimization for physics

### Network
- RemoteEvents for efficient communication
- Client-side prediction for typing
- Server-authoritative game state
- Optimized replication

### Memory Management
- Automatic cleanup of destroyed zombies
- Sound pooling and reuse
- Texture compression
- Garbage collection optimization

## Troubleshooting

### Common Issues

**Rojo sync not working**
- Ensure Rojo plugin is installed
- Check that port 34872 is available
- Verify project structure

**Zombies not spawning**
- Check server scripts are running
- Verify ReplicatedStorage structure
- Ensure word dictionary is loaded

**Audio not playing**
- Replace placeholder audio IDs
- Check SoundService settings
- Verify audio permissions

**Performance issues**
- Reduce particle counts in game_data.lua
- Lower maximum zombie count
- Optimize corridor geometry

### Debug Mode
Enable debug output by setting:
```lua
GameData.DEBUG = true
```

This adds console logging for:
- Zombie spawn events
- Typing input tracking
- Network communication
- Performance metrics

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Code Style
- Use descriptive variable names
- Add comments for complex logic
- Follow Roblox Lua best practices
- Maintain Rojo compatibility

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

- **Game Design**: Based on the "Dead-Letter Drop" concept
- **Physics Engine**: Roblox's built-in physics system
- **Audio Inspiration**: DeathbyRomy and dark synth artists
- **Development Tools**: Rojo for Roblox development

---

**Enjoy the game! Type fast, survive longer! 🧟‍♂️⌨️**
