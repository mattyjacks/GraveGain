# Rojo Setup Guide for GraveGain 2.5D

## What is Rojo?

Rojo is a tool that syncs your local Lua files with Roblox Studio in real-time. Instead of writing code directly in Studio, you can use your favorite code editor and have changes automatically appear in the game.

## Installation Status ✅

Rojo has been installed via Cargo. You can verify it's working:

```powershell
rojo --version
```

## Starting the Development Server

1. Open PowerShell or Command Prompt
2. Navigate to the project directory:
   ```powershell
   cd c:\GitHub5\GraveGain\v2\2point5dRoblox
   ```

3. Start the Rojo server:
   ```powershell
   rojo serve
   ```

   You should see output like:
   ```
   Rojo 7.6.1 running at http://localhost:34872
   ```

## Connecting Roblox Studio

### Option 1: Using Rojo Plugin (Recommended)

1. Install the Rojo plugin from the Roblox Creator Marketplace
2. Open Roblox Studio
3. Create a new blank place
4. In the Home tab, click the Rojo plugin button
5. Click "Connect" - it should automatically find your local server

### Option 2: Manual Connection

1. Open Roblox Studio
2. In the Command Bar (View > Command Bar), paste:
   ```lua
   game:GetService("HttpService"):RequestAsync({Url="http://localhost:34872/api/rojo/connect"})
   ```
3. Press Enter

## Project Structure

```
2point5dRoblox/
├── default.project.json    # Rojo configuration
├── README.md              # Project overview
├── SETUP_GUIDE.md         # This file
└── src/
    ├── shared/            # Shared modules (both client & server)
    │   └── game_data.lua
    ├── server/            # Server-side scripts
    │   └── main.server.lua
    └── client/            # Client-side scripts
        └── main.client.lua
```

## How It Works

1. **Edit files** in your IDE (VS Code, Sublime, etc.)
2. **Save the file** - Rojo detects the change
3. **Studio updates** automatically with your changes
4. **Test in Play mode** - see your changes live

## Common Workflow

```powershell
# Terminal 1: Start Rojo server
cd c:\GitHub5\GraveGain\v2\2point5dRoblox
rojo serve

# Terminal 2: Open your code editor
code .

# Roblox Studio: Connect to Rojo and start developing
```

## Troubleshooting

### Rojo won't connect
- Make sure `rojo serve` is running
- Check that Roblox Studio can access localhost:34872
- Try restarting both Rojo and Studio

### Changes not syncing
- Save the file (Ctrl+S)
- Check the Rojo console for errors
- Verify the file is in the correct `src/` subdirectory

### Port already in use
- Change the port: `rojo serve --port 34873`
- Or kill the process using port 34872

## Building for Release

When you're ready to publish:

```powershell
# Build a standalone .rbxl file
rojo build -o game.rbxl

# This creates a file you can upload to Roblox
```

## Next Steps

1. Start the Rojo server
2. Connect Roblox Studio
3. Begin developing the 2.5D Diablo-like game!
4. Check `src/shared/game_data.lua` for game constants
5. Modify `src/client/main.client.lua` for client logic
6. Modify `src/server/main.server.lua` for server logic
