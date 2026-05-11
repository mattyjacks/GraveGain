# GraveGain 3D - Troubleshooting Guide

## The Game Isn't Displaying - Quick Fix

### Issue: Blank Workspace with Default Baseplate

**Root Cause**: Roblox Studio's default starter content is interfering with our game code.

### Solution (Step by Step)

#### 1. **Clean Up Roblox Studio**
   
   In the **Explorer** panel on the right:
   
   a) Expand `Workspace` and delete:
      - Baseplate
      - Spawn Location
      - Any other default objects
   
   b) Expand `StarterPlayer` and delete:
      - StarterCharacterScripts (folder)
      - StarterPlayerScripts (folder)
   
   c) Expand `StarterGui` and delete:
      - ScreenGui (if present)
      - Any other default UI

#### 2. **Verify Rojo Sync**
   
   a) Open **Plugins** tab in Roblox Studio
   
   b) Click the **Rojo** plugin button
   
   c) You should see a green checkmark next to "Connected"
   
   d) In the **Explorer**, you should see:
      - ReplicatedStorage → Shared (with our modules)
      - ServerScriptService → Server (with our server scripts)
      - StarterPlayer → StarterPlayerScripts (with our client scripts)

#### 3. **Check the Output Window**
   
   a) Go to **View** → **Output**
   
   b) Look for messages like:
      ```
      [Server] GraveGain 3D Server Started
      [Server] Version: 5.0.0
      [Server] All systems initialized and ready for players
      ```
   
   c) If you see errors in red, note them down

#### 4. **Restart Everything**
   
   a) Stop the game (press Stop or F5 again)
   
   b) In terminal, stop Rojo (Ctrl+C)
   
   c) Restart Rojo:
      ```powershell
      cd c:\GitHub5\GraveGain\v2\3dRoblox
      npx rojo serve
      ```
   
   d) Reconnect Rojo plugin in Roblox Studio
   
   e) Press Play (F5) to start the game

#### 5. **Look for the Lobby UI**
   
   When the game starts, you should see:
   - A title "GraveGain 3D" at the top
   - Race selection grid (2x2)
   - Class selection grid (2x2)
   - A READY button
   - Player list on the right

## Common Error Messages

### Error: "ReplicatedStorage.Shared is not a valid member of ReplicatedStorage"
**Cause**: Rojo hasn't synced yet
**Fix**: Wait 5 seconds and reconnect Rojo plugin

### Error: "ServerScriptService.Server is not a valid member of ServerScriptService"
**Cause**: Server scripts folder not synced
**Fix**: Reconnect Rojo and wait for sync to complete

### Error: "Cannot find init.server.lua"
**Cause**: Server entry point missing
**Fix**: Verify file exists at `src/server/init.server.lua`

### Error: "Cannot find init.client.lua"
**Cause**: Client entry point missing
**Fix**: Verify file exists at `src/client/init.client.lua`

## Verification Checklist

- [ ] Rojo server is running (`npx rojo serve`)
- [ ] Rojo plugin is connected (green checkmark)
- [ ] Default Roblox content is deleted
- [ ] Output window shows server startup messages
- [ ] Explorer shows Shared, Server, and Client folders
- [ ] Lobby UI appears when game starts
- [ ] Can select race and class
- [ ] Can click READY button

## If Still Not Working

### Step 1: Check File Permissions
```powershell
# In PowerShell, verify files exist:
ls c:\GitHub5\GraveGain\v2\3dRoblox\src\server\
ls c:\GitHub5\GraveGain\v2\3dRoblox\src\client\
ls c:\GitHub5\GraveGain\v2\3dRoblox\src\shared\
```

### Step 2: Verify Rojo Config
Check that `default.project.json` has correct paths:
```json
{
  "tree": {
    "ReplicatedStorage": {
      "Shared": {
        "$path": "src/shared"
      }
    },
    "ServerScriptService": {
      "Server": {
        "$path": "src/server"
      }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "$path": "src/client"
      }
    }
  }
}
```

### Step 3: Check Rojo Output
Look for messages like:
```
Rojo server listening on http://localhost:34872
Syncing project...
✓ Sync complete
```

### Step 4: Manually Test Scripts
In Roblox Studio Output, run:
```lua
print(game:GetService("ReplicatedStorage"):FindFirstChild("Shared"))
print(game:GetService("ServerScriptService"):FindFirstChild("Server"))
```

Should print the folders, not nil.

## Nuclear Option: Full Reset

If nothing works:

1. **Close Roblox Studio**
2. **Stop Rojo** (Ctrl+C in terminal)
3. **Delete Roblox cache**:
   ```powershell
   Remove-Item -Recurse "$env:LOCALAPPDATA\Roblox\*"
   ```
4. **Restart Roblox Studio**
5. **Create new blank game**
6. **Reconnect Rojo**
7. **Verify sync in Explorer**
8. **Press Play**

## Success Indicators

You'll know it's working when you see:

✅ Lobby UI with race/class selection
✅ Player list showing your character
✅ READY button is clickable
✅ Output shows server startup messages
✅ No red errors in Output window

## Next: Test Gameplay

Once lobby appears:
1. Select a race (click a race button)
2. Select a class (click a class button)
3. Click READY
4. Wait for game to load
5. You should spawn in a dungeon
6. Try moving with WASD
7. Try attacking with left click

Good luck! 🎮
