# Twemoji Integration for GraveGain

## Overview
GraveGain now includes full support for Twitter's Twemoji emoji set. This document explains how to set up and use Twemoji in the game.

## What is Twemoji?
Twemoji is Twitter's open-source emoji library featuring:
- Flat, colorful design style
- Comprehensive emoji coverage (3000+ emoji)
- Licensed under CC BY 4.0 and Apache 2.0
- Used by millions of users worldwide

## Installation

### Option 1: Download Pre-Built Font (Recommended)
1. Download the Twemoji COLR font from Mozilla:
   - **URL**: https://github.com/mozilla/twemoji-colr/releases
   - **File**: `Twemoji.Mozilla.ttf` (latest version)

2. Place the font file in one of these directories:
   - `fonts/emoji/Twemoji.Mozilla.ttf` (in project folder)
   - `user://fonts/emoji/Twemoji.Mozilla.ttf` (in user data folder)

3. Restart the game - Twemoji will be automatically detected

### Option 2: Build from Source
If you want to build from the original SVG assets:

1. Clone the Twemoji repository:
   ```bash
   git clone https://github.com/twitter/twemoji.git
   cd twemoji
   ```

2. Follow the build instructions in the Twemoji repository to generate a TTF font file

3. Place the generated font in the `fonts/emoji/` directory

## Usage in Game

### Selecting Twemoji
1. Start GraveGain
2. Go to **Graphics Settings** (gear icon on main menu)
3. Select **"Twemoji"** from the emoji set dropdown
4. All emoji in the game will render using Twemoji style

### Supported Font Names
The game will automatically detect Twemoji fonts with these names:
- `Twemoji.Mozilla.ttf`
- `TwemojiMozilla.ttf`
- `Twemoji Mozilla.ttf`
- `twemoji.ttf`
- `TwitterColorEmoji-SVGinOT.ttf`

## System Architecture

### TwemojiLoader
- **File**: `scripts/autoload/twemoji_loader.gd`
- **Purpose**: Automatically detects and loads Twemoji fonts
- **Checks**: Both `res://fonts/emoji/` and `user://fonts/emoji/` directories
- **Status**: Prints console messages indicating font loading status

### EmojiManager Integration
- **File**: `scripts/autoload/emoji_manager.gd`
- **Purpose**: Manages all emoji sets including Twemoji
- **Features**:
  - Automatic font detection
  - Fallback to system fonts if Twemoji unavailable
  - Live emoji set switching in graphics settings

## Troubleshooting

### Twemoji Not Loading
1. Check the console output for error messages
2. Verify the font file is in the correct directory
3. Ensure the font filename matches one of the supported names
4. Try restarting the game

### Emoji Rendering Issues
1. Verify the font file is not corrupted
2. Try downloading the font again from the official source
3. Check that the font is a valid TTF/OTF file

### Performance Issues
- Twemoji fonts are optimized for performance
- If experiencing lag, try switching to system fonts temporarily
- Ensure your GPU drivers are up to date

## File Structure
```
GraveGain/
├── fonts/
│   └── emoji/
│       ├── Twemoji.Mozilla.ttf (place here)
│       └── README.md
├── scripts/
│   └── autoload/
│       ├── emoji_manager.gd
│       └── twemoji_loader.gd
└── TWEMOJI_INTEGRATION.md (this file)
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
For issues with Twemoji integration in GraveGain, check:
1. Console output for error messages
2. Font file location and naming
3. Font file integrity (try re-downloading)
4. Godot version compatibility (tested on Godot 4.6+)
