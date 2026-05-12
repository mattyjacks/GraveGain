# Rojo Configuration Fix

## Issue
Rojo was failing with: "Cannot add an instance from a patch that has no parent" error when trying to sync client scripts.

## Root Cause
The `default.project.json` had incorrect configuration:
- `StarterPlayerScripts` was set to `$className: "StarterPlayer"` (wrong class)
- Should be `$className: "Folder"` instead

## Solution Applied

### 1. Fixed default.project.json
Changed:
```json
"StarterPlayerScripts": {
  "$className": "StarterPlayer",  // WRONG
  "Client": {
    "$path": "src/client"
  }
}
```

To:
```json
"StarterPlayerScripts": {
  "$className": "Folder",  // CORRECT
  "Client": {
    "$path": "src/client"
  }
}
```

### 2. Fixed Server Script Structure
- Renamed `game_manager.server.lua` to `game_manager.lua` (modules shouldn't use .server suffix)
- Updated `main.server.lua` to properly require the game_manager module
- Moved gameManager initialization before event handlers

### 3. File Structure Now Correct
```
src/
├── shared/
│   ├── game_data.lua
│   ├── character_system.lua
│   ├── dungeon_generator.lua
│   ├── combat_system.lua
│   ├── loot_system.lua
│   └── networking.lua
├── server/
│   ├── main.server.lua (entry point)
│   ├── game_manager.lua (module)
│   └── enemy_ai.lua (module)
└── client/
    ├── main.client.lua (entry point)
    ├── camera_controller.lua
    ├── movement_controller.lua
    ├── input_handler.lua
    ├── hud_system.lua
    └── audio_vfx_manager.lua
```

## How to Reconnect

1. **Stop Rojo Server** (Ctrl+C in PowerShell)

2. **Restart Rojo**
   ```powershell
   cd c:\GitHub5\GraveGain\v2\2point5dRoblox
   rojo serve
   ```

3. **In Roblox Studio**
   - Close the current place (don't save)
   - Create a NEW blank place
   - Install Rojo plugin (if not already installed)
   - Click "Connect" in Rojo plugin
   - Wait for sync to complete

4. **Verify Connection**
   - Check Output console for "GraveGain 2.5D Server Started"
   - Check ReplicatedStorage has Shared folder with all modules
   - Check ServerScriptService has Server folder with scripts
   - Check StarterPlayer > StarterPlayerScripts has Client folder

5. **Test the Game**
   - Press Play
   - You should see character spawn
   - Check console for initialization messages

## Common Issues

### Still getting parent errors?
- Make sure you created a BLANK place (not a template)
- Delete the place and create a new one
- Rojo plugin may need reinstalling

### Scripts not showing up?
- Check Rojo server is running (should see "Listening on..." message)
- Check connection status in Rojo plugin
- Try clicking "Disconnect" then "Connect" again

### Modules not loading?
- Make sure all .lua files are in correct folders
- Check file names match exactly (case-sensitive)
- Look for red errors in Output console

## Files Modified

1. `default.project.json` - Fixed StarterPlayerScripts className
2. `src/server/main.server.lua` - Fixed GameManager require
3. `src/server/game_manager.lua` - Renamed from game_manager.server.lua

## Status
✅ Configuration fixed
✅ File structure corrected
✅ Ready to reconnect and play!
