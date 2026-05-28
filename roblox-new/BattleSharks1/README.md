# BattleSharks 🦈

A free-to-play cross-platform Roblox game combining Hungry Shark Evolution gameplay with AQ3D-inspired progression systems and tamagotchi aquarium management.

## 🎮 Game Overview

BattleSharks is a 3D underwater adventure where players control customizable sharks in a vast ocean environment. The game features:

- **Free-roam ocean exploration** with swimming physics and boost mechanics
- **Combat system** with bite attacks and special abilities
- **3 playable classes**: Fighter, Ranger, Healer - each with unique abilities
- **Aquarium/tamagotchi mode** where you care for your shark
- **Temporary mutation system** with daily randomized effects
- **Inventory and potion systems** with loot collection
- **Cosmetics and customization** for sharks and aquariums
- **Cross-platform support** for PC and mobile

## 🏗️ Architecture

Built with modern Roblox development practices:

- **Rojo** for project management and hot-reloading
- **Modular Lua architecture** with clean separation of concerns
- **Server-authoritative networking** with RemoteEvents
- **Component-based systems** for scalability
- **OOP design patterns** for maintainability

### Folder Structure

```
BattleSharks1/
├── src/
│   ├── shared/           # Shared code between client/server
│   │   ├── Constants/    # Game configuration
│   │   ├── Enums/        # Type definitions
│   │   ├── Data/         # Game data (items, enemies, etc.)
│   │   ├── Networking/   # RemoteEvent names
│   │   └── Utilities/    # Helper functions
│   ├── server/           # Server-side code
│   │   └── Services/     # Core game services
│   └── client/           # Client-side code
│       └── Controllers/  # Player controllers
├── default.project.json  # Rojo configuration
└── README.md
```

## 🚀 Getting Started

### Prerequisites

- **Roblox Studio** - Latest version
- **Rojo** - Version 7.6.1 or later
- **Git** - For version control

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/BattleSharks.git
   cd BattleSharks
   ```

2. **Build the project**
   ```bash
   rojo build -o BattleSharks.rbxlx
   ```

3. **Open in Roblox Studio**
   - Launch `BattleSharks.rbxlx`
   - Start the Rojo server:
   ```bash
   rojo serve
   ```

4. **Start development**
   - Make changes to source files
   - Rojo will automatically sync changes to Studio

## 🎯 Core Systems

### 1. Shark Movement & Physics
- Underwater swimming with realistic buoyancy
- Boost mechanic with cooldown system
- Leap ability for surface jumping
- Smooth camera controls with zoom/rotation

### 2. Combat System
- Bite attacks with damage calculation
- Class-specific abilities and ultimate moves
- Enemy AI with different behavior patterns
- Visual effects and feedback systems

### 3. Progression System
- XP and leveling mechanics
- 3 distinct classes with unique playstyles
- Ability unlocking and cooldown management
- Stat progression and customization

### 4. Aquarium Mode
- Tamagotchi-style shark care
- Feeding, cleaning, and emotion systems
- Decoration placement and customization
- Background themes and visual effects

### 5. Mutation System
- Daily randomized mutations
- Visual transformations (extra eyes, size changes, etc.)
- Temporary stat modifications
- Cosmetic variations without pay-to-win

### 6. Economy & Items
- Gold and Crystal currencies
- Inventory management with 20 slots
- Potion system with various effects
- Loot drops from enemies

## 🎮 Controls

### Movement
- **WASD** - Move shark
- **Shift** - Boost (faster swimming)
- **Space** - Leap out of water
- **Mouse Wheel** - Zoom camera
- **Middle Mouse** - Rotate camera

### Actions
- **E** - Basic attack
- **Left Click** - Primary attack
- **Right Click** - Secondary action/Block
- **1-4** - Ability hotkeys
- **I** - Open inventory
- **Tab** - Toggle aquarium mode

## 🏆 Game Features

### Core Gameplay
✅ Free-roam ocean environment  
✅ Shark swimming physics  
✅ Combat and enemy AI  
✅ 3 playable classes  
✅ XP and progression system  
✅ Hunger and survival mechanics  

### Aquarium System
✅ Shark care and feeding  
✅ Decoration placement  
✅ Emotion system  
✅ Background customization  
✅ Visual effects and bubbles  

### Mutation System
✅ Daily random mutations  
✅ Visual transformations  
✅ Temporary stat effects  
✅ Cosmetic variations  

### Economy & Items
✅ Gold and Crystal currencies  
✅ Inventory management  
✅ Potion system  
✅ Loot collection  

### Technical Features
✅ Server-authoritative architecture  
✅ Modular code structure  
✅ Optimized networking  
✅ Mobile-friendly controls  
✅ Cross-platform support  

## 📋 MVP Implementation Plan

### Phase 1 ✅ (Core Framework)
- Project setup with Rojo
- Basic shark controller
- Ocean environment
- Hunger system
- Basic networking

### Phase 2 🔄 (Combat & Enemies)
- Enemy AI system
- Combat mechanics
- Health/damage system
- XP and leveling
- Item drops

### Phase 3 ⏳ (Aquarium Mode)
- Aquarium environment
- Shark care mechanics
- Decoration system
- Emotion states
- Feeding/cleanup

### Phase 4 ⏳ (Classes & Abilities)
- Class selection system
- Ability implementation
- Skill progression
- Ultimate abilities
- Balance tuning

### Phase 5 ⏳ (Mutation & Cosmetics)
- Mutation system
- Visual effects
- Cosmetic items
- Daily reset system
- Customization options

### Phase 6 ⏳ (Polish & Optimization)
- UI/UX improvements
- Performance optimization
- Mobile controls
- Save system
- Monetization hooks

## 🔧 Development

### Building
```bash
# Build for development
rojo build

# Build for production
rojo build -o BattleSharks.rbxlx
```

### Syncing
```bash
# Start sync server
rojo serve

# Sync specific project
rojo sync
```

### Testing
- Test in Studio with `rojo serve`
- Use debug console for monitoring
- Check performance stats regularly
- Test on both PC and mobile

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Use **Luau** type hints where appropriate
- Follow **Roblox Lua** best practices
- Keep functions modular and reusable
- Add comments for complex logic
- Use meaningful variable names

## 📊 Performance

### Target Specifications
- **FPS**: 60+ on PC, 30+ on mobile
- **Memory**: <200MB client-side
- **Network**: <10KB/s per player
- **Load Time**: <5 seconds

### Optimization Features
- Object pooling for effects
- Efficient enemy spawning/despawning
- Optimized networking with throttling
- LOD system for distant objects
- Memory management with cleanup

## 🔒 Security

- Server-authoritative data validation
- Anti-cheat movement checks
- Secure transaction handling
- Input sanitization
- Rate limiting on actions

## 📱 Mobile Support

- Touch-friendly UI elements
- Optimized controls for mobile
- Adjustable graphics settings
- Performance scaling
- Cross-platform compatibility

## 🌐 Future Features

### Multiplayer
- Co-op ocean exploration
- PvP arenas
- Guild systems
- Social features

### Content
- More enemy types and bosses
- Additional shark species
- New abilities and classes
- Expanded aquarium options
- Seasonal events

### Technical
- Advanced graphics options
- Achievement system
- Leaderboards
- Trading system
- Marketplace integration

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Roblox Corporation** for the platform
- **Rojo** for excellent build tools
- **AQ3D** for inspiration on progression systems
- **Hungry Shark Evolution** for gameplay mechanics
- **Mutate the Lab Rat 2** for tamagotchi inspiration

## 📞 Contact

- **Developer**: Your Name
- **Discord**: Your Discord
- **Twitter**: Your Twitter
- **GitHub**: Your GitHub

---

**BattleSharks** - Rule the ocean! 🦈🌊