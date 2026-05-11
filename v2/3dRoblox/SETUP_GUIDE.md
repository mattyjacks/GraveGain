# GraveGain 3D - Setup Guide

## Quick Start

### Step 1: Clean Up Roblox Studio
1. **Delete the default content**:
   - In the Explorer panel (right side), delete:
     - `Workspace` → `Baseplate`
     - `Workspace` → `Spawn Location`
     - `StarterPlayer` → `StarterCharacterScripts` (entire folder)
     - `StarterPlayer` → `StarterPlayerScripts` (entire folder)
     - `StarterGui` → `ScreenGui` (if it exists)

2. **Create a Folder in Workspace**:
   - Right-click `Workspace` → Insert Object → Folder
   - Name it `Map` (this is where our dungeon will render)

### Step 2: Start Rojo Server
```powershell
cd c:\GitHub5\GraveGain\v2\3dRoblox
npx rojo serve
```

You should see:
```
Rojo server listening on http://localhost:34872
```

### Step 3: Connect Rojo Plugin
1. In Roblox Studio, go to **Plugins** tab
2. Click the **Rojo** plugin button (looks like a folder icon)
3. Click **Connect** to connect to `localhost:34872`
4. Wait for the sync to complete (you'll see files appear in Explorer)

### Step 4: Run the Game
1. In Roblox Studio, click the **Play** button (or press F5)
2. You should see:
   - Lobby UI with race/class selection
   - Player list
   - Ready button

### Step 5: Test the Game
1. **In Lobby**:
   - Select a race and class
   - Click READY
   - Wait for other players or click start

2. **In Game**:
   - Use WASD to move
   - Mouse to look around
   - Left Click to attack
   - I to open inventory
   - ESC for settings

## Troubleshooting

### Game Not Displaying
**Problem**: Blank workspace, no UI
**Solution**:
1. Check that Rojo is connected (green checkmark in plugin)
2. Delete all default Roblox starter content
3. Reconnect Rojo plugin
4. Restart the game (press F5)

### Scripts Not Running
**Problem**: No console output, game doesn't respond
**Solution**:
1. Check Output window (View → Output)
2. Look for errors in red text
3. Verify Rojo sync completed (check Explorer for Server/Shared folders)
4. Make sure `init.server.lua` and `init.client.lua` exist

### Rojo Connection Failed
**Problem**: "Cannot connect to localhost:34872"
**Solution**:
1. Verify `npx rojo serve` is running in terminal
2. Check that port 34872 is not blocked by firewall
3. Try restarting Rojo server
4. Try restarting Roblox Studio

### No Lobby UI
**Problem**: Game starts but no UI appears
**Solution**:
1. Check that `src/client/lobby_ui.lua` exists
2. Verify `src/client/init.client.lua` is loading it
3. Check Output window for errors
4. Try reconnecting Rojo plugin

## File Structure

```
3dRoblox/
├── src/
│   ├── shared/          ← Shared modules (both server & client)
│   │   ├── constants.lua
│   │   ├── player_data.lua
│   │   ├── weapon_data.lua
│   │   ├── enemy_data.lua
│   │   ├── item_data.lua
│   │   ├── dungeon_generator.lua
│   │   └── stats_tracker.lua
│   ├── server/          ← Server-only scripts
│   │   ├── init.server.lua (entry point)
│   │   ├── lobby_manager.lua
│   │   ├── game_manager.lua
│   │   ├── mission_manager.lua
│   │   ├── character_spawner.lua
│   │   ├── dungeon_renderer.lua
│   │   ├── enemy_ai.lua
│   │   ├── horde_spawner.lua
│   │   └── loot_manager.lua
│   └── client/          ← Client-only scripts
│       ├── init.client.lua (entry point)
│       ├── lobby_ui.lua
│       ├── fps_controller.lua
│       ├── melee_weapon.lua
│       ├── ranged_weapon.lua
│       ├── game_state_manager.lua
│       ├── mission_hud.lua
│       ├── advanced_hud.lua
│       ├── inventory.lua
│       ├── vfx_manager.lua
│       ├── audio_manager.lua
│       ├── settings_manager.lua
│       └── results_screen.lua
├── default.project.json (Rojo config)
├── package.json
└── README.md
```

## Game Controls

| Key | Action |
|-----|--------|
| WASD | Move |
| Mouse | Look around |
| Shift | Sprint |
| Space | Jump |
| LClick | Attack/Fire |
| RClick | Aim |
| R | Reload |
| I | Inventory |
| ESC | Settings |

## Game Flow

1. **Lobby Phase**
   - Select race and class
   - Click READY
   - Wait for other players

2. **Loading Phase**
   - Dungeon generates
   - Characters spawn
   - Loading screen displays

3. **Gameplay Phase**
   - Fight enemy waves
   - Collect loot
   - Survive 10 minutes

4. **Results Phase**
   - Mission complete/failed
   - View statistics
   - Return to lobby

## Common Issues

### "Roblox automatically translated unsupported languages in chat"
- This is a warning, not an error
- Game will still work normally

### Character not visible
- Make sure character spawned (check Output for spawn message)
- Try moving with WASD
- Check that camera is positioned correctly

### No enemies spawning
- Wait 30 seconds for first wave
- Check mission is in IN_GAME state
- Verify horde_spawner initialized

### Inventory not opening
- Make sure you're in-game (not in lobby)
- Press I to toggle inventory
- Check Output for inventory errors

## Next Steps

Once the game is running:
1. Test the lobby system
2. Test FPS movement and combat
3. Test enemy spawning and waves
4. Test loot collection
5. Test inventory system
6. Test settings menu

## Support

If you encounter issues:
1. Check the Output window (View → Output)
2. Look for red error messages
3. Check that all files exist in `src/` folder
4. Verify Rojo is syncing (green checkmark)
5. Try restarting Rojo and Roblox Studio
