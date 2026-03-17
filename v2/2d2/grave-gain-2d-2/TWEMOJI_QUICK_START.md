# Twemoji Quick Start Guide

## Overview
GraveGain now has full Twemoji emoji support integrated. This guide will help you get started quickly.

## What's Included

### Autoload Scripts
- **EmojiManager** (`scripts/autoload/emoji_manager.gd`) - Manages all emoji sets including Twemoji
- **TwemojiLoader** (`scripts/autoload/twemoji_loader.gd`) - Automatically detects Twemoji fonts
- **TwemojiSetupHelper** (`scripts/autoload/twemoji_setup_helper.gd`) - Helps download and install Twemoji
- **TwemojiDownloader** (`scripts/autoload/twemoji_downloader.gd`) - Legacy downloader utility

### UI Integration
- Graphics Settings panel in main menu includes emoji set selector
- Shows available emoji sets with install status
- One-click switching between emoji sets
- Rescan button to detect newly added fonts

## Installation Methods

### Method 1: Automatic Download (Easiest)
1. Start the game
2. Go to **Graphics Settings** (gear icon on main menu)
3. Find **Twemoji** in the emoji list (marked as "Not Installed")
4. Click the **Download** button (if available in your UI)
5. Wait for download to complete
6. Select **Twemoji** to activate it

### Method 2: Manual Installation
1. Download the font from: https://github.com/mozilla/twemoji-colr/releases
2. Download `Twemoji.Mozilla.ttf` (v0.7.0 or later)
3. Place it in one of these directories:
   - `fonts/emoji/Twemoji.Mozilla.ttf` (project folder)
   - `user://fonts/emoji/Twemoji.Mozilla.ttf` (user data folder)
4. Restart the game or click "Rescan for Fonts" in Graphics Settings
5. Select **Twemoji** from the emoji dropdown

### Method 3: Programmatic Setup
```gdscript
# In any script with access to TwemojiSetupHelper:
TwemojiSetupHelper.download_and_install_twemoji()

# Or check status:
var status = TwemojiSetupHelper.get_setup_status()
print("Twemoji installed: ", status["installed"])
print("Twemoji active: ", status["active"])

# Print detailed status:
TwemojiSetupHelper.print_status()
```

## Using Twemoji in Game

### Selecting Twemoji
1. Start GraveGain
2. Click **Graphics Settings** (gear icon)
3. Scroll to **Emoji Sets** section
4. Click **Use** next to "Twemoji"
5. All emoji in the game will render using Twemoji style

### Supported Font Names
The system automatically detects Twemoji fonts with these names:
- `Twemoji.Mozilla.ttf` (recommended)
- `TwemojiMozilla.ttf`
- `Twemoji Mozilla.ttf`
- `twemoji.ttf`
- `TwitterColorEmoji-SVGinOT.ttf`

## Font Search Paths
The system searches for emoji fonts in this order:
1. `res://fonts/emoji/` (project folder)
2. `res://fonts/` (project folder)
3. `user://fonts/emoji/` (user data folder)
4. `user://fonts/` (user data folder)

## Troubleshooting

### Twemoji Not Showing as Available
1. Check that the font file is in one of the search paths
2. Verify the filename matches one of the supported names
3. Click "Rescan for Fonts" in Graphics Settings
4. Check the console for error messages

### Font Not Loading
1. Verify the font file is not corrupted
2. Download the font again from the official source
3. Ensure the file is a valid TTF/OTF file
4. Check file permissions

### Performance Issues
- Twemoji fonts are optimized for performance
- If experiencing lag, try switching to system fonts temporarily
- Ensure your GPU drivers are up to date
- Try a lower graphics quality preset

## Available Emoji Sets
GraveGain supports multiple emoji sets:
- **System Default** - Uses OS built-in emoji (always available)
- **Twemoji** - Twitter/X open-source emoji (flat, colorful)
- **Noto Color Emoji** - Google's emoji font (clean, modern)
- **OpenMoji** - Open-source hand-crafted emoji (outlined style)
- **Blobmoji** - Google's classic blob-style emoji (round, friendly)
- **Fluent Emoji** - Microsoft's 3D-style emoji (vibrant, detailed)
- **JoyPixels** - Professional polished emoji (free version)
- **Samsung Emoji** - Samsung's distinctive style

## File Structure
```
GraveGain/
├── fonts/
│   └── emoji/
│       ├── README.md
│       └── [place Twemoji.Mozilla.ttf here]
├── scripts/
│   └── autoload/
│       ├── emoji_manager.gd
│       ├── twemoji_loader.gd
│       ├── twemoji_downloader.gd
│       └── twemoji_setup_helper.gd
├── TWEMOJI_INTEGRATION.md (detailed technical docs)
├── TWEMOJI_SETUP.md (setup instructions)
└── TWEMOJI_QUICK_START.md (this file)
```

## License
- **Twemoji**: CC BY 4.0 / Apache 2.0
- **GraveGain Integration**: Same as GraveGain project
- See: https://github.com/twitter/twemoji/blob/master/LICENSE.txt

## Resources
- **Twemoji Repository**: https://github.com/twitter/twemoji
- **Mozilla Twemoji COLR**: https://github.com/mozilla/twemoji-colr
- **Twemoji License**: https://github.com/twitter/twemoji/blob/master/LICENSE.txt

## Support
For issues with Twemoji integration:
1. Check console output for error messages
2. Verify font file location and naming
3. Try re-downloading the font
4. Ensure Godot version 4.6+ compatibility
5. Check the detailed TWEMOJI_INTEGRATION.md for technical details
