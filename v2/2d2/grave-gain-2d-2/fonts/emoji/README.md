# Emoji Font Sets for GraveGain 2D

## Complete Guide to Emoji Graphics in GraveGain

GraveGain 2D uses emoji characters as its primary visual language for all game entities
including players, enemies, items, decorations, and environmental features. This document
provides comprehensive information about the emoji font system, supported sets, installation
procedures, compatibility notes, and technical implementation details.

**For general game information, features, and systems, see the main [GraveGain README](../../../../README.md).**

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Supported Emoji Sets](#supported-emoji-sets)
4. [Detailed Set Descriptions](#detailed-set-descriptions)
5. [Installation Guide](#installation-guide)
6. [Platform-Specific Instructions](#platform-specific-instructions)
7. [In-Game Configuration](#in-game-configuration)
8. [Emoji Usage in GraveGain](#emoji-usage-in-gravegain)
9. [Technical Implementation](#technical-implementation)
10. [Compatibility Matrix](#compatibility-matrix)
11. [Troubleshooting](#troubleshooting)
12. [Font Formats and Standards](#font-formats-and-standards)
13. [Creating Custom Emoji Sets](#creating-custom-emoji-sets)
14. [Performance Considerations](#performance-considerations)
15. [Accessibility](#accessibility)
16. [License Information](#license-information)
17. [FAQ](#faq)
18. [Changelog](#changelog)

---

## Overview

GraveGain 2D renders all game graphics using emoji Unicode characters drawn through
Godot's font rendering system. By default, the game uses your operating system's built-in
emoji font. However, you can install alternative emoji font sets to completely change the
visual style of the game.

### Why Emoji Graphics?

Emoji provide several advantages for game development:

- **Universal Recognition**: Players immediately understand what objects represent
- **Rich Detail**: Modern color emoji fonts contain detailed, professional artwork
- **Cross-Platform**: Emoji work on every operating system and device
- **Easy Modding**: Swapping font files changes the entire game's visual style
- **Lightweight**: A single font file replaces hundreds of individual sprite assets
- **Unicode Standard**: Consistent codepoints across all implementations

### How It Works

The EmojiManager autoload singleton (registered in `project.godot`) manages font
loading and swapping at runtime. When you select an emoji set in the settings menu:

1. EmojiManager checks if the requested font file exists
2. If found, it loads the `.ttf` file as a Godot `FontFile` resource
3. It creates two font variants: normal (32px) and large (48px)
4. It overrides `GameData.emoji_font` and `GameData.emoji_font_large`
5. All game entities that render emoji text automatically use the new fonts

The swap is instant and requires no restart.

---

## Quick Start

The fastest way to get custom emoji in GraveGain:

1. Download **Twemoji.Mozilla.ttf** from the releases page:
   https://github.com/nicedoc/twemoji-colr/releases

2. Place the file in this folder:
   ```
   fonts/emoji/Twemoji.Mozilla.ttf
   ```

3. Launch GraveGain and open the main menu

4. Go to **Settings** (gear icon)

5. Under **Graphics**, find the **Emoji Set** dropdown

6. Select **Twemoji**

7. The game visuals update immediately

That is all. For detailed instructions for each set, read on.

---

## Supported Emoji Sets

GraveGain supports 8 emoji rendering modes:

| # | Set Name | Font File | Format | License | Size |
|---|----------|-----------|--------|---------|------|
| 1 | System | (OS default) | Varies | N/A | 0 KB |
| 2 | Twemoji | `Twemoji.Mozilla.ttf` | COLR/CPAL | CC BY 4.0 / Apache 2.0 | ~10 MB |
| 3 | Noto Color Emoji | `NotoColorEmoji.ttf` | CBDT/CBLC | Apache 2.0 | ~24 MB |
| 4 | OpenMoji | `OpenMoji-Color.ttf` | COLR/CPAL | CC BY-SA 4.0 | ~6 MB |
| 5 | Blobmoji | `Blobmoji.ttf` | CBDT/CBLC | Apache 2.0 | ~16 MB |
| 6 | Fluent Emoji | `FluentSystemEmoji.ttf` | COLR/CPAL | MIT | ~42 MB |
| 7 | JoyPixels | `joypixels-android.ttf` | CBDT/CBLC | Free License | ~18 MB |
| 8 | Samsung | `SamsungColorEmoji.ttf` | CBDT/CBLC | Proprietary | ~20 MB |

### Download Links

| Set | Primary Download | Mirror |
|-----|-----------------|--------|
| Twemoji | [twemoji-colr releases](https://github.com/nicedoc/twemoji-colr/releases) | [Mozilla CDN](https://cdn.jsdelivr.net/npm/@aspect-build/rules_js/) |
| Noto | [noto-emoji releases](https://github.com/googlefonts/noto-emoji/releases) | [Google Fonts](https://fonts.google.com/noto/specimen/Noto+Color+Emoji) |
| OpenMoji | [openmoji releases](https://github.com/hfg-gmuend/openmoji/releases) | [openmoji.org](https://openmoji.org/) |
| Blobmoji | [blobmoji releases](https://github.com/C1710/blobmoji/releases) | N/A |
| Fluent | [fluent-emoji-font](https://github.com/AcmeSoftwareLLC/fluent-emoji-font/releases) | N/A |
| JoyPixels | [joypixels.com](https://www.joypixels.com/download) | N/A |
| Samsung | Extract from Samsung device | N/A |

---

## Detailed Set Descriptions

### 1. System (Default)

The system emoji set uses whatever emoji font is built into your operating system.

**Windows 10/11**: Segoe UI Emoji - Microsoft's flat-design emoji with bold outlines
and bright colors. Good visibility at small sizes. Updated regularly with new Unicode
versions.

**macOS / iOS**: Apple Color Emoji - Apple's signature emoji style with glossy, detailed
artwork. Considered by many to be the most recognizable emoji design. Excellent quality
at all sizes.

**Linux**: Varies by distribution. Many use Noto Color Emoji by default. Some may have
no color emoji support, in which case you should install one of the supported sets.

**Android**: Google's Noto Color Emoji or manufacturer-specific variant.

**Pros**: No installation required. Always available. Matches OS visual style.
**Cons**: Varies by platform. Linux may have limited support. Cannot be shared.

### 2. Twemoji (Twitter/X Emoji)

Originally created by Twitter, Twemoji features a clean, flat design with consistent
line weights and a friendly aesthetic. The Mozilla COLR build provides excellent
rendering quality in Godot.

**Visual Style**: Flat design with consistent proportions. Rounded features. Bright,
saturated colors. Good readability at small sizes due to clean outlines.

**Coverage**: Full Unicode 15.0 emoji set. Includes all standard emoji plus many
ZWJ sequences.

**Best For**: Players who want clean, consistent visuals across all platforms. The
flat design works particularly well for game graphics since there are no gradients
or complex shading to get lost at small render sizes.

**File**: `Twemoji.Mozilla.ttf`
**Format**: COLR/CPAL (vector-based color layers)
**Size**: ~10 MB
**License**: CC BY 4.0 (graphics) / Apache 2.0 (font build)

**Recommended**: Yes - Best overall choice for GraveGain due to clean rendering,
small file size, and open license.

### 3. Noto Color Emoji (Google)

Google's Noto Color Emoji is one of the most complete and widely-used emoji fonts.
It features a soft, rounded design with gentle gradients and warm colors.

**Visual Style**: Rounded shapes with soft gradients. Warm color palette. Friendly
and approachable. Slightly larger rendering footprint than Twemoji.

**Coverage**: Full Unicode 15.0+ emoji set. Google actively maintains and updates
this font with every new Unicode release, often being among the first to add new emoji.

**Best For**: Players on Linux who want a reliable default. Also good for players
who prefer slightly softer, more detailed visuals compared to Twemoji's flat style.

**File**: `NotoColorEmoji.ttf`
**Format**: CBDT/CBLC (bitmap-based color)
**Size**: ~24 MB
**License**: Apache 2.0

**Note**: The bitmap format means the font is larger and may render slightly differently
at non-native sizes compared to vector-based formats like COLR.

### 4. OpenMoji

Created by the HfG Schwaebisch Gmuend design school, OpenMoji is an open-source emoji
set with a distinctive hand-drawn aesthetic. Every emoji follows strict design guidelines
ensuring visual consistency.

**Visual Style**: Hand-drawn appearance with consistent black outlines. Flat fills with
no gradients. Very distinctive look that stands apart from mainstream emoji. Uses a
limited, harmonious color palette.

**Coverage**: Full Unicode emoji set plus many custom additions for various domains
including accessibility, activism, and technology.

**Best For**: Players who want a unique, artistic visual style. OpenMoji gives the
game a distinctly different feel compared to mainstream emoji sets. The consistent
outline style ensures all emoji are equally readable.

**File**: `OpenMoji-Color.ttf`
**Format**: COLR/CPAL (vector-based)
**Size**: ~6 MB
**License**: CC BY-SA 4.0

**Note**: The ShareAlike clause means derivative works must use the same license.
Using OpenMoji emoji in screenshots or videos of GraveGain is fine under CC BY-SA.

### 5. Blobmoji

A community continuation of Google's beloved blob emoji design from Android 4.4-7.1.
The blob design features soft, rounded shapes - particularly the iconic blob-shaped
faces that many users prefer over the circular redesign.

**Visual Style**: Soft, blob-shaped faces with expressive features. Rounded objects.
Warm colors with gentle gradients. Has a nostalgic, friendly feel that many users
find more charming than modern flat emoji.

**Coverage**: Full Unicode emoji set, maintained by community volunteers. May lag
slightly behind the latest Unicode releases.

**Best For**: Players who miss Google's old blob emoji. Also good for anyone who
prefers a softer, more organic visual style. The blob faces give enemies a more
characterful appearance.

**File**: `Blobmoji.ttf`
**Format**: CBDT/CBLC (bitmap-based)
**Size**: ~16 MB
**License**: Apache 2.0

### 6. Fluent Emoji (Microsoft)

Microsoft's Fluent Emoji set features a modern 3D-inspired design with depth, shadows,
and rich detail. This is the newest mainstream emoji design and represents Microsoft's
current design language.

**Visual Style**: 3D-inspired with depth and shadows. Rich textures and materials.
Modern, polished look. Some emoji have animated variants (not used in fonts). Bold
colors with realistic shading.

**Coverage**: Full Unicode emoji set. Actively maintained by Microsoft.

**Best For**: Players who want the most detailed, modern-looking emoji. The 3D style
gives game entities a premium, polished appearance. However, the high detail level
means the font file is significantly larger.

**File**: `FluentSystemEmoji.ttf`
**Format**: COLR/CPAL (vector-based with gradients)
**Size**: ~42 MB
**License**: MIT

**Note**: This is the largest emoji font at ~42 MB. Players with limited storage
should consider smaller alternatives.

### 7. JoyPixels

JoyPixels (formerly EmojiOne) is a commercial emoji set with a free tier. The
design features clean, detailed artwork with a professional finish.

**Visual Style**: Clean, professional design. Good color saturation. Consistent
proportions. Falls between Twemoji's flat style and Fluent's 3D look. Well-balanced
for readability and detail.

**Coverage**: Full Unicode emoji set. Commercial development ensures regular updates.

**Best For**: Players who want high-quality emoji without the extreme detail of Fluent
or the flat simplicity of Twemoji. A solid middle-ground choice.

**File**: `joypixels-android.ttf`
**Format**: CBDT/CBLC (bitmap-based)
**Size**: ~18 MB
**License**: Free License (check JoyPixels terms for commercial use)

**Note**: The free license has some restrictions on commercial use. For personal
gameplay, the free version is fully functional.

### 8. Samsung Emoji

Samsung's proprietary emoji design used on Samsung Galaxy devices. Features a
distinctive style with saturated colors and unique interpretations of many emoji.

**Visual Style**: Saturated, vibrant colors. Some emoji differ significantly from
other vendors in interpretation. Distinctive Samsung aesthetic. Good detail level.

**Coverage**: Full Unicode emoji set as of the device firmware version.

**Best For**: Samsung device users who want consistency with their phone's emoji,
or anyone who likes Samsung's distinctive style.

**File**: `SamsungColorEmoji.ttf`
**Format**: CBDT/CBLC (bitmap-based)
**Size**: ~20 MB
**License**: Proprietary - Samsung Electronics Co., Ltd.

**Note**: This font must be extracted from a Samsung device. It is not available for
public download. The font is proprietary and redistribution is not permitted. GraveGain
supports it for personal use only.

**Extraction Instructions**:
1. On a rooted Samsung device, navigate to `/system/fonts/`
2. Copy `SamsungColorEmoji.ttf` to your computer
3. Place it in the GraveGain emoji fonts folder

---

## Installation Guide

### Method 1: Project Directory (Recommended for Development)

Place emoji font files directly in the project's font directory:

```
v2/2d2/grave-gain-2d-2/fonts/emoji/
```

This is the folder containing this README. Simply drop the `.ttf` file here and it
will be available in-game.

**Advantages**:
- Included in version control (if desired)
- Available immediately after cloning the project
- Works in the Godot editor and exported builds

**Disadvantages**:
- Increases repository size
- May conflict with font licenses for redistribution

### Method 2: User Directory (Recommended for End Users)

Place emoji font files in the Godot user data directory:

```
user://fonts/emoji/
```

This resolves to different paths per operating system:

**Windows**:
```
%APPDATA%/Godot/app_userdata/GraveGain 2D/fonts/emoji/
```
Full path example:
```
C:/Users/YourName/AppData/Roaming/Godot/app_userdata/GraveGain 2D/fonts/emoji/
```

**macOS**:
```
~/Library/Application Support/Godot/app_userdata/GraveGain 2D/fonts/emoji/
```
Full path example:
```
/Users/YourName/Library/Application Support/Godot/app_userdata/GraveGain 2D/fonts/emoji/
```

**Linux**:
```
~/.local/share/godot/app_userdata/GraveGain 2D/fonts/emoji/
```
Full path example:
```
/home/yourname/.local/share/godot/app_userdata/GraveGain 2D/fonts/emoji/
```

**Advantages**:
- Does not affect the project repository
- User-specific customization
- Safe from project updates overwriting fonts
- Respects font licensing (no redistribution)

**Disadvantages**:
- Must be set up per user
- Path varies by OS

### Method 3: System Font Installation

Install the emoji font system-wide on your operating system. The "System" emoji set
option will then use whatever is installed as the system default.

**Windows**: Right-click the `.ttf` file and select "Install for all users"
**macOS**: Double-click the `.ttf` file and click "Install Font" in Font Book
**Linux**: Copy to `~/.local/share/fonts/` and run `fc-cache -fv`

**Note**: This replaces your system-wide emoji rendering. Only do this if you want
the same emoji everywhere, not just in GraveGain.

---

## Platform-Specific Instructions

### Windows

**Downloading Twemoji (recommended)**:
1. Open your web browser
2. Go to https://github.com/nicedoc/twemoji-colr/releases
3. Download the latest `Twemoji.Mozilla.ttf` file
4. Open File Explorer
5. Navigate to your GraveGain project folder
6. Go to `v2/2d2/grave-gain-2d-2/fonts/emoji/`
7. Drop the `.ttf` file here
8. Launch GraveGain and select Twemoji in settings

**Alternative using PowerShell**:
```powershell
# Navigate to the emoji fonts folder
cd "C:\path\to\GraveGain\v2\2d2\grave-gain-2d-2\fonts\emoji"

# Download Twemoji (update URL to latest release)
Invoke-WebRequest -Uri "https://github.com/nicedoc/twemoji-colr/releases/download/v0.7.0/Twemoji.Mozilla.ttf" -OutFile "Twemoji.Mozilla.ttf"
```

**Using User Directory**:
```powershell
# Create the directory if it doesn't exist
$emojiDir = "$env:APPDATA\Godot\app_userdata\GraveGain 2D\fonts\emoji"
New-Item -ItemType Directory -Force -Path $emojiDir

# Copy font file
Copy-Item "Twemoji.Mozilla.ttf" -Destination $emojiDir
```

### macOS

**Downloading Noto Color Emoji**:
1. Open Safari or your preferred browser
2. Go to https://github.com/googlefonts/noto-emoji/releases
3. Download `NotoColorEmoji.ttf`
4. Open Finder
5. Navigate to your GraveGain project
6. Go to `v2/2d2/grave-gain-2d-2/fonts/emoji/`
7. Move the `.ttf` file into this folder

**Using Terminal**:
```bash
# Navigate to emoji fonts folder
cd /path/to/GraveGain/v2/2d2/grave-gain-2d-2/fonts/emoji/

# Download Noto Color Emoji
curl -L -o NotoColorEmoji.ttf \
  "https://github.com/googlefonts/noto-emoji/raw/main/fonts/NotoColorEmoji.ttf"
```

**Using User Directory**:
```bash
# Create directory
mkdir -p ~/Library/Application\ Support/Godot/app_userdata/GraveGain\ 2D/fonts/emoji/

# Copy font
cp NotoColorEmoji.ttf ~/Library/Application\ Support/Godot/app_userdata/GraveGain\ 2D/fonts/emoji/
```

### Linux

**Installing Noto Color Emoji system-wide (Debian/Ubuntu)**:
```bash
sudo apt install fonts-noto-color-emoji
```

**Installing Noto Color Emoji system-wide (Fedora)**:
```bash
sudo dnf install google-noto-emoji-color-fonts
```

**Installing Noto Color Emoji system-wide (Arch)**:
```bash
sudo pacman -S noto-fonts-emoji
```

**Manual Installation for GraveGain**:
```bash
# Navigate to emoji fonts folder
cd /path/to/GraveGain/v2/2d2/grave-gain-2d-2/fonts/emoji/

# Download OpenMoji (small, open source)
wget https://github.com/hfg-gmuend/openmoji/releases/download/15.0.0/OpenMoji-Color.ttf
```

**Using User Directory**:
```bash
# Create directory
mkdir -p ~/.local/share/godot/app_userdata/GraveGain\ 2D/fonts/emoji/

# Copy font
cp OpenMoji-Color.ttf ~/.local/share/godot/app_userdata/GraveGain\ 2D/fonts/emoji/
```

---

## In-Game Configuration

### Accessing Emoji Settings

1. Launch GraveGain 2D
2. From the main menu, click the **Settings** button (gear icon)
3. Navigate to the **Graphics** section
4. Scroll to the **Emoji** subsection
5. The **Emoji Set** dropdown shows all available options

### Available Options

The dropdown shows:
- **System** (always available)
- All installed font sets detected in `fonts/emoji/` or `user://fonts/emoji/`
- Unavailable sets are grayed out with "(not installed)" text

### Rescan for Fonts

If you add font files while the game is running:
1. Go to Settings > Graphics > Emoji
2. Click the **Rescan for Fonts** button
3. The dropdown will update with newly detected fonts

### Live Preview

When you select a new emoji set, the change takes effect immediately:
- All player characters update to the new style
- All enemies redraw with the new font
- Items, decorations, and HUD elements refresh
- No restart or scene reload required

### Saving Preferences

Your emoji set preference is saved automatically to `user://settings.cfg` under the
key `"emoji_set"`. It persists between game sessions.

---

## Emoji Usage in GraveGain

### Player Characters

Each race is represented by specific emoji that change based on the current font set:

| Race | Emoji | Codepoint | Description |
|------|-------|-----------|-------------|
| Human | Person | U+1F9D1 | Standing person |
| Elf | Elf | U+1F9DD | Mythical elf character |
| Dwarf | Bearded Person | U+1F9D4 | Person with beard |
| Orc | Ogre | U+1F479 | Japanese ogre (oni) |

### Enemy Characters

| Enemy Type | Emoji | Codepoint | Description |
|------------|-------|-----------|-------------|
| Zombie | Zombie | U+1F9DF | Walking dead |
| Skeleton | Skull | U+1F480 | Human skull |
| Goblin | Goblin | U+1F47A | Japanese tengu |
| Ghost | Ghost | U+1F47B | Cartoon ghost |
| Demon | Angry Devil | U+1F47F | Imp with horns |
| Vampire | Vampire | U+1F9DB | Vampire character |
| Spider | Spider | U+1F577 | Spider |
| Necromancer | Mage | U+1F9D9 | Person with hat |
| Knight | Crossed Swords | U+2694 | Sword pair |
| Dragon | Dragon Face | U+1F432 | Dragon head |

### Items and Pickups

| Item | Emoji | Codepoint | Description |
|------|-------|-----------|-------------|
| Gold Coin | Coin | U+1FA99 | Round coin |
| Gold Bar | Gold | U+1F4B0 | Money bag |
| Health Potion | Red Heart | U+2764 | Heart symbol |
| Mana Potion | Blue Diamond | U+1F537 | Blue diamond |
| Ammo | Bow and Arrow | U+1F3F9 | Bow weapon |
| Food - Apple | Apple | U+1F34E | Red apple |
| Food - Meat | Meat | U+1F356 | Meat on bone |
| Food - Bread | Bread | U+1F35E | Bread loaf |
| Speed Boost | Lightning | U+26A1 | Lightning bolt |
| Damage Boost | Sword | U+1F5E1 | Dagger |
| Shield Orb | Shield | U+1F6E1 | Shield |
| Chest | Package | U+1F4E6 | Wrapped box |
| Key | Key | U+1F511 | Old key |

### Map Decorations

| Feature | Emoji | Codepoint | Description |
|---------|-------|-----------|-------------|
| Torch | Fire | U+1F525 | Flame |
| Pillar | Classical Building | U+1F3DB | Roman columns |
| Statue | Moai | U+1F5FF | Easter Island head |
| Candle | Candle | U+1F56F | Lit candle |
| Skull Deco | Skull & Crossbones | U+2620 | Pirate skull |
| Web | Spider Web | U+1F578 | Cobweb |
| Fountain | Fountain | U+26F2 | Water fountain |
| Altar | Place of Worship | U+1F6D0 | Religious altar |
| Gravestone | Headstone | U+1FAA6 | Tombstone |
| Tree | Deciduous Tree | U+1F333 | Green tree |
| Crystal | Gem Stone | U+1F48E | Cut diamond |

### Buildings (Sidescroller Entries)

| Building | Emoji | Codepoint | Description |
|----------|-------|-----------|-------------|
| House | House | U+1F3E0 | Home building |
| Cave | Mountain | U+1F5FB | Mount Fuji |
| Fortress | Castle | U+1F3F0 | European castle |
| Castle | Crown | U+1F451 | Royal crown |

### Lore Items

| Type | Emoji | Codepoint | Description |
|------|-------|-----------|-------------|
| Book | Open Book | U+1F4D6 | Open pages |
| Scroll | Scroll | U+1F4DC | Rolled paper |
| Sign | Placard | U+1FAA7 | Posted sign |
| Gravestone | Headstone | U+1FAA6 | Tombstone |
| Note | Memo | U+1F4DD | Written note |
| Tablet | Stone Tablet | U+1F4CB | Clipboard |
| Journal | Notebook | U+1F4D3 | Bound book |
| Letter | Envelope | U+2709 | Mail envelope |
| Crystal | Crystal Ball | U+1F52E | Fortune ball |

### Status Effects and Buffs

| Effect | Emoji | Codepoint | Description |
|--------|-------|-----------|-------------|
| Poison | Green Circle | U+1F7E2 | Green dot |
| Fire | Fire | U+1F525 | Flame |
| Ice | Snowflake | U+2744 | Ice crystal |
| Lightning | High Voltage | U+26A1 | Electric bolt |
| Heal | Sparkles | U+2728 | Glitter |
| Shield | Shield | U+1F6E1 | Protection |
| Speed | Wind | U+1F4A8 | Dash cloud |
| Strength | Flexed Bicep | U+1F4AA | Muscle |
| Level Up | Star | U+2B50 | Gold star |

---

## Technical Implementation

### EmojiManager Architecture

The EmojiManager is registered as the 4th autoload singleton in `project.godot`,
loading after GameSystems. It exposes the following API:

```gdscript
# Properties
var current_set: String = "system"
var available_sets: Array[String] = []

# Methods
func scan_for_fonts() -> void
func set_emoji_set(set_name: String) -> bool
func get_available_sets() -> Array[String]
func is_set_available(set_name: String) -> bool
```

### Font Loading Pipeline

```
1. EmojiManager._ready()
   |
   2. scan_for_fonts()
   |   - Check res://fonts/emoji/ for .ttf files
   |   - Check user://fonts/emoji/ for .ttf files
   |   - Match filenames to known set definitions
   |   - Populate available_sets array
   |
   3. Load saved preference from GameSystems settings
   |
   4. set_emoji_set(saved_preference)
       |
       5. Load FontFile from disk
       |
       6. Create normal variant (32px size)
       |
       7. Create large variant (48px size)
       |
       8. Override GameData.emoji_font
       |
       9. Override GameData.emoji_font_large
```

### Font File Detection

The EmojiManager maps set names to expected filenames:

```gdscript
var font_files: Dictionary = {
    "twemoji": "Twemoji.Mozilla.ttf",
    "noto": "NotoColorEmoji.ttf",
    "openmoji": "OpenMoji-Color.ttf",
    "blobmoji": "Blobmoji.ttf",
    "fluent": "FluentSystemEmoji.ttf",
    "joypixels": "joypixels-android.ttf",
    "samsung": "SamsungColorEmoji.ttf",
}
```

Both `res://fonts/emoji/` and `user://fonts/emoji/` are scanned. The `user://`
directory takes priority if the same font exists in both locations.

### Rendering Pipeline

Emoji are rendered using Godot's `draw_string()` and `draw_string_outline()` methods
on CanvasItem nodes. The rendering chain:

```
1. Entity (player/enemy/item) calls queue_redraw()
   |
   2. _draw() function is triggered
   |
   3. draw_string(GameData.emoji_font, position, emoji_char, ...)
   |
   4. Godot's text server rasterizes the emoji glyph
   |
   5. The color bitmap or vector layers are composited
   |
   6. Final pixel output to the viewport
```

### Font Size Configuration

GraveGain uses two emoji font sizes:

| Variant | Size | Usage |
|---------|------|-------|
| Normal | 32px | Standard entities, items, decorations |
| Large | 48px | Boss enemies, HUD elements, special displays |

The sizes are configured when loading the font:

```gdscript
var font := FontFile.new()
font.load_dynamic_font(font_path)
# Normal variant
GameData.emoji_font = font
GameData.emoji_font.fixed_size = 32
# Large variant
GameData.emoji_font_large = font.duplicate()
GameData.emoji_font_large.fixed_size = 48
```

### Color Font Format Support

Godot 4.6 supports the following color font table formats through its text server
(HarfBuzz + FreeType):

| Format | Type | Quality | Support |
|--------|------|---------|---------|
| COLR/CPAL v0 | Vector layers | Excellent | Full |
| COLR/CPAL v1 | Vector with gradients | Excellent | Full |
| CBDT/CBLC | Bitmap strikes | Good | Full |
| sbix | Apple bitmap | Good | Partial |
| SVG | SVG outlines | Variable | Partial |

**Recommended format**: COLR/CPAL provides the best quality since it uses vector
graphics that scale cleanly to any size. Twemoji, OpenMoji, and Fluent use this format.

**Bitmap formats** (CBDT/CBLC) embed pre-rendered images at specific sizes. Quality
may degrade when rendered at sizes different from the embedded strikes. Noto, Blobmoji,
JoyPixels, and Samsung use this format.

---

## Compatibility Matrix

### Emoji Set vs Game Entity Compatibility

All supported emoji sets include the codepoints used by GraveGain. However, visual
quality and distinctiveness vary:

| Entity | Twemoji | Noto | OpenMoji | Blobmoji | Fluent | JoyPixels | Samsung |
|--------|---------|------|----------|----------|--------|-----------|---------|
| Player | Great | Great | Good | Good | Great | Great | Great |
| Enemies | Great | Great | Good | Good | Great | Great | Great |
| Items | Great | Great | Great | Great | Great | Great | Great |
| Decorations | Great | Great | Good | Great | Great | Great | Great |
| Buildings | Great | Great | Good | Good | Great | Great | Good |
| Lore | Great | Great | Great | Great | Great | Great | Great |
| Status FX | Great | Great | Great | Good | Great | Great | Great |

**Legend**: Great = Distinct, readable. Good = Functional, may be less distinct.

### OS Compatibility

| Emoji Set | Windows | macOS | Linux | Web | Android | iOS |
|-----------|---------|-------|-------|-----|---------|-----|
| System | Yes | Yes | Varies | Yes | Yes | Yes |
| Twemoji | Yes | Yes | Yes | Yes | Yes | Yes |
| Noto | Yes | Yes | Yes | Yes | Yes | Yes |
| OpenMoji | Yes | Yes | Yes | Yes | Yes | Yes |
| Blobmoji | Yes | Yes | Yes | Yes | Yes | Yes |
| Fluent | Yes | Yes | Yes | Yes | Yes | Yes |
| JoyPixels | Yes | Yes | Yes | Yes | Yes | Yes |
| Samsung | Yes | Yes | Yes | Yes | Yes | Yes |

### Godot Version Compatibility

| Godot Version | COLR/CPAL | CBDT/CBLC | Notes |
|---------------|-----------|-----------|-------|
| 4.0 - 4.1 | Partial | Yes | COLR v0 only |
| 4.2 - 4.3 | Yes | Yes | Full COLR v1 support |
| 4.4+ | Yes | Yes | Improved rendering quality |
| 4.6 | Yes | Yes | Current target version |

---

## Troubleshooting

### Font Not Appearing in Dropdown

**Symptom**: You placed a font file but it doesn't show in the emoji set selector.

**Solutions**:
1. Verify the filename matches exactly (case-sensitive on Linux):
   - `Twemoji.Mozilla.ttf` (not `twemoji.mozilla.ttf`)
   - `NotoColorEmoji.ttf` (not `NotoColorEmoji.TTF`)
2. Click "Rescan for Fonts" in the settings panel
3. Check both directories: `fonts/emoji/` and `user://fonts/emoji/`
4. Verify the file is a valid `.ttf` font (not corrupted or partial download)
5. Restart the game if Rescan doesn't work

### Emoji Rendering as Squares or Boxes

**Symptom**: Characters appear as empty rectangles or question marks.

**Causes and Solutions**:
1. **Missing glyphs**: The font doesn't contain the requested emoji codepoint.
   Try a different, more complete font set.
2. **Corrupt font file**: Re-download the font file.
3. **Wrong file format**: Ensure the file is a TrueType font (.ttf), not OpenType
   (.otf) or Web font (.woff/.woff2).
4. **System font issue**: If using "System", install a color emoji font for your OS.

### Emoji Appear Black and White

**Symptom**: Emoji render but without color.

**Causes and Solutions**:
1. **Monochrome font**: Some .ttf files contain only monochrome glyphs. Ensure you
   downloaded the "Color" variant (e.g., `NotoColorEmoji.ttf` not `NotoEmoji.ttf`).
2. **Text server limitation**: On some Linux configurations, the text server may not
   support color fonts. Update Godot to the latest version.
3. **Rendering mode**: Check that the game's font rendering mode supports color.

### Emoji Look Blurry or Pixelated

**Symptom**: Emoji appear fuzzy, especially at larger sizes.

**Causes and Solutions**:
1. **Bitmap font scaling**: CBDT/CBLC fonts (Noto, Blobmoji, JoyPixels, Samsung)
   embed bitmaps at fixed sizes. Rendering at different sizes causes interpolation.
   Switch to a COLR/CPAL font (Twemoji, OpenMoji, Fluent) for crisp scaling.
2. **Display scaling**: High-DPI displays may cause font rendering artifacts. Adjust
   Godot's viewport stretch settings.
3. **Font size mismatch**: The game renders at 32px and 48px. Bitmap fonts optimized
   for other sizes will look suboptimal.

### Performance Issues After Changing Font

**Symptom**: FPS drops or stuttering after selecting a new emoji set.

**Causes and Solutions**:
1. **Large font file**: Fluent Emoji at ~42 MB takes longer to load. This is a one-time
   cost at startup.
2. **Glyph cache building**: First time rendering each emoji requires glyph rasterization.
   After initial rendering, glyphs are cached.
3. **VRAM usage**: Large bitmap fonts consume more VRAM. If you have limited GPU memory,
   prefer smaller COLR/CPAL fonts.

### Font Change Doesn't Persist

**Symptom**: Emoji set resets to System after restarting the game.

**Causes and Solutions**:
1. **Save permission**: Ensure the game can write to `user://settings.cfg`. Check
   file permissions on the user data directory.
2. **Font moved/deleted**: If the font file is removed after saving the preference,
   the game falls back to System. Ensure the font file stays in place.

---

## Font Formats and Standards

### Unicode Emoji Standard

Emoji are defined by the Unicode Consortium in the Unicode Standard. Each emoji has
a unique codepoint (or sequence of codepoints for complex emoji like families or
skin-tone variants).

Key Unicode emoji specifications:
- **Unicode 15.0** (September 2022): 3,664 emoji
- **Unicode 15.1** (September 2023): 3,782 emoji
- **Emoji 15.1**: Includes new additions like shaking head, phoenix, lime

GraveGain uses emoji from Unicode 13.0 and earlier, ensuring compatibility with all
modern emoji fonts.

### TrueType Font Format

All supported emoji fonts use the TrueType font format (`.ttf`). The font file
contains standard TrueType tables plus additional color-specific tables:

**Standard Tables**:
- `cmap`: Character-to-glyph mapping
- `glyf`: Glyph outlines (may be empty for color-only fonts)
- `head`: Font header
- `hhea`: Horizontal header
- `hmtx`: Horizontal metrics
- `maxp`: Maximum profile
- `name`: Naming table
- `post`: PostScript information

**Color Font Tables** (one of the following sets):

| Method | Tables | Type | Used By |
|--------|--------|------|---------|
| COLR/CPAL | `COLR`, `CPAL` | Vector layers | Twemoji, OpenMoji, Fluent |
| CBDT/CBLC | `CBDT`, `CBLC` | Bitmap strikes | Noto, Blobmoji, JoyPixels, Samsung |
| sbix | `sbix` | Apple bitmap | Apple Color Emoji |
| SVG | `SVG ` | SVG documents | Some web fonts |

### COLR/CPAL Format Details

The COLR (Color) table defines colored glyphs as layers of standard glyphs, each
painted with a color from the CPAL (Color Palette) table.

**Version 0**: Simple color layers. Each glyph is composed of overlapping monochrome
shapes, each filled with a solid color. Clean, efficient, well-supported.

**Version 1**: Extends v0 with gradients (linear, radial, sweep), transformations,
compositing modes, and variable color support. Enables more complex visual effects
while remaining resolution-independent.

### CBDT/CBLC Format Details

The CBDT (Color Bitmap Data) table stores pre-rendered bitmap images of each glyph.
The CBLC (Color Bitmap Location) table indexes these bitmaps by glyph ID and size.

Bitmaps are typically stored as PNG images embedded within the font file. Multiple
bitmap sizes (strikes) can be included for different rendering sizes, though most
emoji fonts include bitmaps at 128x128 or 136x136 pixels.

**Advantages**: Exact pixel control, consistent rendering across all platforms.
**Disadvantages**: Large file size, quality loss when scaled, fixed resolution.

---

## Creating Custom Emoji Sets

### Overview

Advanced users can create custom emoji sets for GraveGain by building their own
color font files. This section provides a high-level guide.

### Requirements

- Image editing software (Inkscape, Illustrator, Photoshop, GIMP)
- Font building tools (fonttools, nanoemoji, picosvg)
- Python 3.8+ (for build tools)
- SVG or PNG artwork for each emoji codepoint

### Step 1: Prepare Artwork

Create images for each emoji used in GraveGain. Minimum set includes approximately
50 unique codepoints (see Emoji Usage section above).

**For COLR/CPAL (vector)**:
- Create SVG files, one per emoji
- Use simple shapes and flat colors where possible
- Keep paths clean and optimized
- Name files by Unicode codepoint: `emoji_u1f480.svg`

**For CBDT/CBLC (bitmap)**:
- Create PNG files at 128x128 pixels
- Use transparent backgrounds
- Name files by Unicode codepoint: `emoji_u1f480.png`

### Step 2: Build the Font

Using `nanoemoji` (Google's emoji font builder):

```bash
# Install nanoemoji
pip install nanoemoji

# Build a COLR font from SVG files
nanoemoji --color_format glyf_colr_1 \
  --output MyEmojiFont.ttf \
  svg_files/*.svg
```

Using `fonttools`:

```bash
# Install fonttools
pip install fonttools

# Use scripts to assemble a CBDT font from PNGs
# (Requires custom build script - see Google's noto-emoji repository)
```

### Step 3: Test the Font

1. Place your built `.ttf` file in `fonts/emoji/`
2. Add a mapping entry to EmojiManager's `font_files` dictionary
3. Rescan for fonts in the game
4. Select your custom set and verify all emoji render correctly

### Step 4: Distribution

If you want to share your custom emoji set:
- Ensure you have rights to all artwork used
- Choose an appropriate open-source license
- Include attribution for any derived work
- Provide the `.ttf` file and a README with installation instructions

---

## Performance Considerations

### Memory Usage by Font Set

| Font Set | File Size | Estimated VRAM | Load Time |
|----------|-----------|----------------|-----------|
| System | 0 KB | ~2 MB | <1ms |
| Twemoji | ~10 MB | ~4 MB | ~50ms |
| Noto | ~24 MB | ~8 MB | ~100ms |
| OpenMoji | ~6 MB | ~3 MB | ~30ms |
| Blobmoji | ~16 MB | ~6 MB | ~80ms |
| Fluent | ~42 MB | ~15 MB | ~200ms |
| JoyPixels | ~18 MB | ~7 MB | ~90ms |
| Samsung | ~20 MB | ~8 MB | ~100ms |

### Glyph Cache

Godot caches rasterized glyphs in a texture atlas. The first time each unique emoji
is rendered at a specific size, there is a small overhead for rasterization. After
caching, subsequent renders are fast texture blits.

**Cache behavior**:
- Each unique (glyph, size, outline) combination is cached separately
- Cache is per-font, reset when switching emoji sets
- Typical GraveGain session uses ~60-80 unique glyphs
- Total cache size is usually under 2 MB

### Rendering Performance

Vector fonts (COLR/CPAL) are rasterized once and cached, so runtime performance is
identical to bitmap fonts after the initial render. The difference is only in:
- Initial load time (vector fonts are smaller files, faster to load)
- First-render rasterization (vector fonts need rasterization, bitmap fonts don't)
- Scaling quality (vector fonts scale perfectly, bitmap fonts may blur)

### Recommendations by System

| System | Recommended Set | Reason |
|--------|----------------|--------|
| Low-end PC | Twemoji or OpenMoji | Small file size, fast loading |
| Mid-range PC | Any | All sets perform well |
| High-end PC | Fluent | Best visual quality, can afford memory |
| Mobile | Twemoji | Smallest footprint, clean rendering |
| Web Export | System or Twemoji | Minimize download size |

---

## Accessibility

### Colorblind Considerations

Different emoji sets have different color palettes that may affect visibility for
colorblind players:

- **Twemoji**: High-contrast colors, generally good for colorblind users
- **Noto**: Softer colors, may be harder to distinguish in some cases
- **OpenMoji**: Strong black outlines help distinguish shapes regardless of color
- **Blobmoji**: Soft gradients may reduce contrast
- **Fluent**: 3D shading provides depth cues beyond color
- **JoyPixels**: Good color contrast
- **Samsung**: Saturated colors, generally high contrast

**Recommendation for colorblind players**: OpenMoji, due to its consistent black
outlines that provide shape distinction independent of color perception.

### Size and Readability

Emoji readability at the game's default render sizes:

| Emoji Set | 32px Readability | 48px Readability | Best For |
|-----------|------------------|------------------|----------|
| Twemoji | Excellent | Excellent | All situations |
| Noto | Good | Excellent | Larger displays |
| OpenMoji | Good | Excellent | High contrast needs |
| Blobmoji | Good | Excellent | Casual play |
| Fluent | Excellent | Excellent | Detail appreciation |
| JoyPixels | Good | Excellent | General use |
| Samsung | Good | Good | Samsung fans |

### Screen Reader Support

GraveGain's emoji system stores the semantic meaning of each emoji separately from
its visual representation. This means:
- Entity types are tracked by enum, not by emoji codepoint
- HUD text uses standard text, not emoji descriptions
- Lore entries are plain text
- The game does not rely solely on emoji for conveying critical information

---

## License Information

### Font License Summary

| Font Set | License | Commercial Use | Modification | Attribution |
|----------|---------|----------------|--------------|-------------|
| System | OS License | N/A | N/A | N/A |
| Twemoji | CC BY 4.0 + Apache 2.0 | Yes | Yes | Required |
| Noto | Apache 2.0 | Yes | Yes | Recommended |
| OpenMoji | CC BY-SA 4.0 | Yes | Yes (ShareAlike) | Required |
| Blobmoji | Apache 2.0 | Yes | Yes | Recommended |
| Fluent | MIT | Yes | Yes | Required |
| JoyPixels | Free License | Limited | No | Required |
| Samsung | Proprietary | No | No | N/A |

### Detailed License Information

**CC BY 4.0 (Twemoji graphics)**:
You are free to share and adapt the material for any purpose, including commercial,
as long as you give appropriate credit and indicate changes. No ShareAlike requirement.

**Apache 2.0 (Noto, Blobmoji, Twemoji font build)**:
Permissive license allowing use, modification, and distribution. Must include the
license text and copyright notice. Patent grant included.

**CC BY-SA 4.0 (OpenMoji)**:
Similar to CC BY 4.0 but with a ShareAlike clause: derivative works must be
distributed under the same or compatible license.

**MIT (Fluent Emoji)**:
Very permissive. Use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies. Must include copyright notice and permission notice.

**JoyPixels Free License**:
Free for personal use. Commercial use requires a premium license. Check
https://www.joypixels.com/licenses for current terms.

**Samsung Proprietary**:
Samsung emoji artwork is proprietary. Redistribution is not permitted. Personal use
only. Do not include Samsung emoji fonts in distributed builds of GraveGain.

### Attribution

If you distribute GraveGain with bundled emoji fonts, include appropriate attribution:

```
Twemoji graphics by Twitter/X, licensed under CC BY 4.0.
https://github.com/twitter/twemoji

Noto Color Emoji by Google, licensed under Apache 2.0.
https://github.com/googlefonts/noto-emoji

OpenMoji by HfG Schwaebisch Gmuend, licensed under CC BY-SA 4.0.
https://openmoji.org

Blobmoji by C1710, based on Google's blob emoji, licensed under Apache 2.0.
https://github.com/C1710/blobmoji

Fluent Emoji by Microsoft, licensed under MIT.
https://github.com/microsoft/fluentui-emoji
```

---

## FAQ

### General Questions

**Q: Do I need to install any emoji font to play GraveGain?**
A: No. The game works with your operating system's built-in emoji font by default.
Custom fonts are entirely optional.

**Q: Which emoji set do you recommend?**
A: Twemoji for the best balance of quality, file size, and compatibility. It renders
cleanly at all sizes and has a friendly, recognizable style.

**Q: Can I use multiple emoji sets and switch between them?**
A: Yes. Install as many sets as you want and switch between them instantly in the
game's settings menu.

**Q: Will changing emoji sets affect my save data?**
A: No. Save data, achievements, lore progress, and settings (other than emoji
preference) are completely independent of the emoji set.

**Q: Do emoji sets affect gameplay?**
A: No. Emoji sets are purely cosmetic. Hit boxes, damage, movement, and all other
gameplay mechanics are identical regardless of which emoji set is active.

### Technical Questions

**Q: Why does Fluent Emoji take longer to load?**
A: At ~42 MB, it is the largest font file. The extra size comes from the detailed
3D-style vector graphics. Loading is a one-time cost per game session.

**Q: Can I use .otf or .woff2 font files?**
A: No. GraveGain only supports TrueType (.ttf) font files. Convert other formats
to .ttf using tools like fonttools or online converters.

**Q: Why do some emoji look different between sets?**
A: Each vendor interprets the Unicode emoji specification differently. The Unicode
Standard defines what an emoji represents (e.g., "pile of poo") but not exactly how
it should look. This is why the same codepoint can look quite different across sets.

**Q: Can I mix emoji from different sets?**
A: Not through the standard EmojiManager. The game uses one font for all emoji at
a time. Advanced users could modify EmojiManager to support per-entity font overrides.

**Q: Does the emoji set affect exported builds?**
A: If you export with a bundled font in `fonts/emoji/`, that font will be available
in the exported build. System fonts depend on the end user's OS.

### Compatibility Questions

**Q: I am on Linux and see no colored emoji. What should I do?**
A: Install `fonts-noto-color-emoji` (Debian/Ubuntu) or equivalent for your distro.
Or place any supported font file in the GraveGain emoji folder and select it.

**Q: Can I use Apple Color Emoji on Windows?**
A: Apple Color Emoji uses the sbix format which has limited support in Godot. It may
work partially but is not officially supported by GraveGain. Use one of the 7
supported sets instead.

**Q: Will future Unicode emoji be supported?**
A: GraveGain uses a fixed set of emoji codepoints. New Unicode releases won't affect
gameplay unless new entities are added that use new codepoints.

---

## Creating Custom Emoji Sets

To create a custom emoji set for GraveGain:

1. **Design or source emoji artwork** in a consistent style
2. **Build a TrueType font** using FontForge, Glyphs, or similar tools
3. **Implement COLR/CPAL tables** for color support (recommended)
4. **Test rendering** at 32px and 48px sizes
5. **Place the .ttf file** in `fonts/emoji/` or `user://fonts/emoji/`
6. **Add mapping** to EmojiManager's `font_files` dictionary
7. **Rescan** in-game to make it available

For detailed font creation guides, see:
- [FontForge Documentation](https://fontforge.org/)
- [Glyphs App](https://glyphsapp.com/)
- [COLR/CPAL Specification](https://docs.microsoft.com/en-us/typography/opentype/spec/colr)

---

## Performance Considerations

### File Size Impact

Emoji font files range from 6 MB to 42 MB. Larger fonts may:
- Take longer to load on first startup
- Consume more disk space
- Use more VRAM for glyph caching
- Cause brief stuttering during initial glyph rendering

**Optimization Tips**:
- Use COLR/CPAL fonts (Twemoji, OpenMoji) for better performance
- Avoid Fluent Emoji on low-end systems
- Clear the glyph cache if performance degrades: delete `user://glyph_cache/`

### Rendering Performance

Once loaded, emoji rendering performance is equivalent across all font sets. The initial
load time is the primary performance consideration.

### Memory Usage

Glyph caching uses approximately 1-2 MB per 100 unique emoji rendered. GraveGain uses
roughly 50-100 unique emoji, so expect 1-2 MB additional VRAM per font set.

---

## Accessibility

### Colorblind Support

Some emoji sets are more colorblind-friendly than others:

- **Twemoji**: Good - uses distinct shapes and colors
- **OpenMoji**: Excellent - consistent black outlines aid distinction
- **Noto**: Good - warm color palette
- **Fluent**: Good - detailed shapes help identification

For players with color blindness, OpenMoji is recommended as the consistent outline
style makes emoji distinguishable even without color.

### Text Alternatives

All emoji in GraveGain have text descriptions in the UI. Hover over items or enemies
to see their names and descriptions.

### Zoom and Scaling

The game supports text scaling in Settings > Accessibility > Text Scale. This affects
all UI text but not emoji rendering. Emoji size is fixed at 32px or 48px.

---

## License Information

### Emoji Font Licenses

| Font | License | Commercial Use | Redistribution |
|------|---------|-----------------|-----------------|
| Twemoji | CC BY 4.0 / Apache 2.0 | Yes | Yes (with attribution) |
| Noto Color Emoji | Apache 2.0 | Yes | Yes |
| OpenMoji | CC BY-SA 4.0 | Yes | Yes (same license) |
| Blobmoji | Apache 2.0 | Yes | Yes |
| Fluent Emoji | MIT | Yes | Yes |
| JoyPixels | Free License | Limited | Limited |
| Samsung | Proprietary | No | No |

### GraveGain License

GraveGain is licensed under the MIT License. Using emoji fonts with compatible licenses
(Apache 2.0, MIT, CC BY 4.0) is fully compatible with GraveGain's license.

---

## FAQ

### Q: Can I use Samsung emoji if I don't have a Samsung device?

**A**: Samsung emoji are proprietary and cannot be legally obtained without a Samsung device.
If you have a Samsung device, you can extract the font and use it personally, but redistribution
is not permitted.

### Q: Will changing emoji fonts affect my save data?

**A**: No. Save data is completely independent of emoji rendering. You can switch between
emoji sets at any time without affecting game progress.

### Q: Which emoji set should I choose?

**A**: 
- **Best overall**: Twemoji - clean, small, open source
- **Most detailed**: Fluent Emoji - modern 3D style (large file)
- **Most artistic**: OpenMoji - hand-drawn, unique look
- **Most nostalgic**: Blobmoji - classic Google blob style
- **Most complete**: Noto Color Emoji - actively maintained by Google

### Q: Can I use emoji fonts from other sources?

**A**: Yes, if they are TrueType fonts (.ttf) containing the required emoji codepoints.
Place them in `fonts/emoji/` or `user://fonts/emoji/` and they will be detected automatically.

### Q: Why do some emoji look different than on my phone?

**A**: Different emoji fonts have different artistic interpretations of the same emoji.
This is intentional - each font set has a unique visual style. Your phone uses its OS's
default emoji font, while GraveGain uses whichever font you select.

### Q: Can I contribute a new emoji set?

**A**: Yes! If you create or find a high-quality emoji font that works well in GraveGain,
submit it as a pull request or issue on GitHub. Include:
- The font file (.ttf)
- License information
- Visual comparison screenshots
- Performance metrics

### Q: What if I want emoji to look like my phone's emoji?

**A**: 
- **iPhone users**: Apple's emoji are proprietary. Use Twemoji or Noto as close alternatives.
- **Samsung users**: Extract `SamsungColorEmoji.ttf` from your device.
- **Google Pixel users**: Use Noto Color Emoji (Google's official font).
- **Other Android**: Use Noto Color Emoji (the Android default).

### Q: Can I disable emoji and use text instead?

**A**: No, emoji are integral to GraveGain's visual design. However, you can choose
any emoji set that you find most readable.

### Q: How do I report emoji rendering issues?

**A**: If an emoji doesn't render correctly:
1. Note the emoji name and codepoint
2. Try a different emoji set to isolate the issue
3. Report on GitHub with:
   - Emoji name and codepoint
   - Font set and version
   - Godot version
   - Operating system
   - Screenshot

---

## Changelog

### Version 2.0 (Current)

- Added support for 8 emoji font sets
- Implemented live emoji font swapping without restart
- Added emoji set detection and scanning
- Created comprehensive emoji usage documentation
- Integrated EmojiManager autoload singleton
- Added emoji settings panel to main menu
- Support for both project and user directory font loading

### Version 1.0 (Initial)

- System emoji font support only
- Static emoji rendering

---

## Additional Resources

### Official Emoji Specifications

- [Unicode Emoji Standard](https://unicode.org/reports/tr51/)
- [Emoji Sequences](https://www.unicode.org/Public/emoji/15.0/)
- [OpenType Color Font Spec](https://docs.microsoft.com/en-us/typography/opentype/spec/colr)

### Font Development

- [FontForge](https://fontforge.org/) - Open source font editor
- [Glyphs](https://glyphsapp.com/) - Professional font design
- [Nanoemoji](https://github.com/googlei18n/nanoemoji) - Google's emoji font builder

### Emoji Resources

- [Emojipedia](https://emojipedia.org/) - Comprehensive emoji reference
- [Unicode.org](https://unicode.org/) - Official Unicode standard
- [OpenMoji](https://openmoji.org/) - Open source emoji project

---

## Support

For issues or questions about emoji fonts in GraveGain:

1. Check the [Troubleshooting](#troubleshooting) section above
2. Review the [FAQ](#faq) section
3. Check the [GitHub Issues](https://github.com/your-username/GraveGain/issues)
4. Create a new issue with detailed information about your problem

---

**Last Updated**: March 2026
**Emoji Standard**: Unicode 15.0
**Godot Version**: 4.6+

### Version 2.0 (Current)
- Added EmojiManager autoload singleton
- Support for 8 emoji sets (system + 7 custom)
- Live font swapping without restart
- Dual directory scanning (project + user)
- Rescan button in settings UI
- Font preference persistence
- Large and normal font size variants

### Version 1.0
- System emoji only
- Hard-coded font references
- No customization options

---

## Visual Comparison Guide

### How Emoji Sets Differ

Each emoji set interprets the Unicode specification with its own design language.
Here is how key game entities look across different sets:

### Face Emoji (Used for Enemies)

The face-based emoji show the most variation between sets:

- **Skull (U+1F480)**: Twemoji shows a clean white skull with dark eye sockets.
  Noto uses a slightly yellow-tinted skull with softer shadows. OpenMoji has bold
  black outlines with a flat white fill. Blobmoji uses a rounder, softer skull shape.
  Fluent renders a detailed 3D skull with realistic bone texture. JoyPixels shows a
  clean skull similar to Twemoji. Samsung uses a more stylized skull with blue shadows.

- **Ghost (U+1F47B)**: Twemoji shows a simple white ghost with a playful expression.
  Noto renders a rounder ghost with gentle shading. OpenMoji uses the characteristic
  black outline style. Blobmoji makes the ghost softer and blob-like. Fluent adds 3D
  depth and translucency. JoyPixels shows a classic cartoon ghost. Samsung renders a
  more detailed ghost with distinct facial features.

- **Ogre (U+1F479)**: This is particularly interesting as it represents the Orc player.
  Twemoji shows a red oni mask with horns. Noto uses similar iconography with softer
  colors. OpenMoji simplifies the design with bold outlines. Blobmoji adds a playful
  twist. Fluent renders detailed 3D horns and facial features. JoyPixels and Samsung
  each have their own distinct interpretations of the Japanese oni.

### Object Emoji (Used for Items)

Object emoji tend to be more consistent across sets but still show style differences:

- **Sword (U+1F5E1)**: Used for damage boost pickups. Most sets show a dagger or
  short sword. The angle, detail level, and handle design vary. Fluent adds the most
  detail with 3D metallic rendering.

- **Shield (U+1F6E1)**: Used for shield orbs. Design ranges from simple circular
  shields (Twemoji, OpenMoji) to detailed medieval shields (Fluent, Samsung) to
  fantasy-styled shields (Noto, JoyPixels).

- **Fire (U+1F525)**: Used for torches and fire effects. Twemoji shows clean flame
  shapes. Noto adds warm gradients. OpenMoji uses flat colors with bold outlines.
  Fluent renders realistic 3D flames with glowing edges.

### Building Emoji (Used for Sidescroller Entries)

- **House (U+1F3E0)**: Ranges from simple (Twemoji) to detailed with windows,
  chimney, and garden (Fluent). OpenMoji uses a minimalist approach. Samsung adds
  unique architectural details.

- **Castle (U+1F3F0)**: All sets show a castle but vary significantly in style.
  Twemoji and OpenMoji use simplified flat designs. Noto and Blobmoji add soft
  details. Fluent renders a fully 3D fantasy castle. Samsung shows a Disney-inspired
  castle design.

### Choosing Based on Visual Preference

| If You Prefer... | Choose |
|-------------------|--------|
| Clean and minimal | Twemoji or OpenMoji |
| Soft and friendly | Noto or Blobmoji |
| Detailed and modern | Fluent |
| Professional polish | JoyPixels |
| Vibrant and bold | Samsung |
| Unique artistic style | OpenMoji |
| Nostalgic feel | Blobmoji |
| Consistent with your OS | System |

---

## File Listing

This directory should contain:

```
fonts/emoji/
|-- README.md              # This documentation file
|-- Twemoji.Mozilla.ttf    # (optional) Twemoji font
|-- NotoColorEmoji.ttf     # (optional) Noto Color Emoji font
|-- OpenMoji-Color.ttf     # (optional) OpenMoji font
|-- Blobmoji.ttf           # (optional) Blobmoji font
|-- FluentSystemEmoji.ttf  # (optional) Fluent Emoji font
|-- joypixels-android.ttf  # (optional) JoyPixels font
|-- SamsungColorEmoji.ttf  # (optional) Samsung Emoji font
```

No font files are included by default due to file size and licensing considerations.
Download and place the fonts you want according to the installation guide above.

---

## Contact and Support

For issues with emoji rendering in GraveGain:
1. Check the Troubleshooting section above
2. Try a different emoji set to isolate the problem
3. Check the Godot console for font-related error messages
4. Report issues on the project's GitHub Issues page

For issues with specific emoji fonts:
- Twemoji: https://github.com/twitter/twemoji/issues
- Noto: https://github.com/googlefonts/noto-emoji/issues
- OpenMoji: https://github.com/hfg-gmuend/openmoji/issues
- Blobmoji: https://github.com/C1710/blobmoji/issues
- Fluent: https://github.com/microsoft/fluentui-emoji/issues

---

*Emoji make the dead look friendlier.*

---

## Advanced Configuration

### Custom Font Variants

For advanced users, you can create custom font variants with different sizes:

```gdscript
# In EmojiManager or custom script
var custom_font := FontFile.new()
custom_font.load_dynamic_font(font_path)

# Create multiple size variants
var font_tiny = custom_font.duplicate()
font_tiny.fixed_size = 16

var font_normal = custom_font.duplicate()
font_normal.fixed_size = 32

var font_large = custom_font.duplicate()
font_large.fixed_size = 48

var font_huge = custom_font.duplicate()
font_huge.fixed_size = 64
```

### Font Fallback Chains

Godot supports font fallback chains where if a glyph is missing in the primary font, it falls back to a secondary font. This allows mixing emoji sets:

```gdscript
var primary_font := FontFile.new()
primary_font.load_dynamic_font("res://fonts/emoji/Twemoji.Mozilla.ttf")

var fallback_font := FontFile.new()
fallback_font.load_dynamic_font("res://fonts/emoji/NotoColorEmoji.ttf")

# Set fallback (Godot 4.6+)
primary_font.fallback_fonts = [fallback_font]
```

### Font Outline and Shadow Effects

Emoji can be rendered with outlines and shadows for better visibility:

```gdscript
# Draw emoji with outline
draw_string_outline(emoji_font, position, emoji_char, HORIZONTAL_ALIGNMENT_CENTER, -1, 32, Color.BLACK)
# Draw emoji on top
draw_string(emoji_font, position, emoji_char, HORIZONTAL_ALIGNMENT_CENTER, -1, 32, Color.WHITE)
```

### Dynamic Font Size Scaling

Adjust emoji size based on game zoom or screen resolution:

```gdscript
func get_scaled_emoji_size(base_size: int, scale_factor: float) -> int:
	return int(base_size * scale_factor)

# Usage
var zoom_level = 1.5
var scaled_size = get_scaled_emoji_size(32, zoom_level)
```

---

## Extended Emoji Usage Guide

### Complete Emoji Codepoint Reference

GraveGain uses the following Unicode codepoints. This reference helps when creating custom emoji sets:

**Player Races**:
- Human: U+1F9D1 (Person)
- Elf: U+1F9DD (Elf)
- Dwarf: U+1F9D4 (Bearded Person)
- Orc: U+1F479 (Ogre)

**Enemy Types**:
- Zombie: U+1F9DF (Zombie)
- Skeleton: U+1F480 (Skull)
- Goblin: U+1F47A (Goblin)
- Ghost: U+1F47B (Ghost)
- Demon: U+1F47F (Imp)
- Vampire: U+1F9DB (Vampire)
- Spider: U+1F577 (Spider)
- Necromancer: U+1F9D9 (Mage)
- Knight: U+2694 (Crossed Swords)
- Dragon: U+1F432 (Dragon Face)

**Weapons**:
- Sword: U+1F5E1 (Dagger)
- Bow: U+1F3F9 (Bow and Arrow)
- Staff: U+1FA84 (Magic Wand)
- Axe: U+1FA80 (Axe)
- Hammer: U+1F528 (Hammer)
- Spear: U+1F3F3 (Spear)

**Armor and Protection**:
- Shield: U+1F6E1 (Shield)
- Helmet: U+1FA96 (Helmet)
- Breastplate: U+1F455 (Shirt)
- Boots: U+1F462 (Boots)

**Items and Loot**:
- Gold Coin: U+1FA99 (Coin)
- Gold Bar: U+1F4B0 (Money Bag)
- Health Potion: U+2764 (Red Heart)
- Mana Potion: U+1F537 (Blue Diamond)
- Stamina Potion: U+1F7E2 (Green Circle)
- Antidote: U+1F9EA (Bottle with Popping Cork)
- Elixir: U+1F9FF (Nazar Amulet)

**Food**:
- Apple: U+1F34E (Red Apple)
- Meat: U+1F356 (Meat on Bone)
- Bread: U+1F35E (Bread)
- Cheese: U+1F9C0 (Cheese Wedge)
- Mushroom: U+1F344 (Mushroom)
- Berries: U+1F347 (Grapes)

**Consumables**:
- Speed Boost: U+26A1 (Lightning Bolt)
- Damage Boost: U+1F4A5 (Explosion)
- Defense Boost: U+1F6E1 (Shield)
- Healing: U+2728 (Sparkles)

**Map Features**:
- Torch: U+1F525 (Fire)
- Pillar: U+1F3DB (Classical Building)
- Statue: U+1F5FF (Moai)
- Candle: U+1F56F (Candle)
- Skull Decoration: U+2620 (Skull and Crossbones)
- Spider Web: U+1F578 (Spider Web)
- Fountain: U+26F2 (Fountain)
- Altar: U+1F6D0 (Place of Worship)
- Gravestone: U+1FAA6 (Headstone)
- Tree: U+1F333 (Deciduous Tree)
- Crystal: U+1F48E (Gem Stone)
- Chest: U+1F4E6 (Package)
- Door: U+1F6AA (Door)
- Gate: U+1F6A7 (Construction)

**Buildings**:
- House: U+1F3E0 (House)
- Cave: U+1F5FB (Mountain)
- Fortress: U+1F3F0 (Castle)
- Tower: U+1F5FC (Tokyo Tower)
- Temple: U+1F54B (Kaaba)

**Lore Items**:
- Book: U+1F4D6 (Open Book)
- Scroll: U+1F4DC (Scroll)
- Sign: U+1FAA7 (Placard)
- Note: U+1F4DD (Memo)
- Tablet: U+1F4CB (Clipboard)
- Journal: U+1F4D3 (Notebook)
- Letter: U+2709 (Envelope)
- Crystal Ball: U+1F52E (Crystal Ball)

**Status Effects**:
- Poison: U+1F7E2 (Green Circle)
- Fire: U+1F525 (Fire)
- Ice: U+2744 (Snowflake)
- Lightning: U+26A1 (High Voltage)
- Healing: U+2728 (Sparkles)
- Blessing: U+1F4AA (Flexed Bicep)
- Curse: U+1F47F (Imp)
- Weakness: U+1F4A8 (Dashing Away)

**UI Elements**:
- Health: U+2665 (Heart Suit)
- Mana: U+1F52E (Crystal Ball)
- Stamina: U+1F4A8 (Dashing Away)
- Experience: U+2B50 (Star)
- Level: U+1F3C6 (Trophy)
- Achievement: U+1F3AF (Direct Hit)
- Quest: U+1F4A1 (Light Bulb)
- Inventory: U+1F392 (Backpack)
- Settings: U+2699 (Gear)
- Map: U+1F5FA (World Map)

### Emoji Sequences and Modifiers

Some emoji use sequences (multiple codepoints combined):

**Skin Tone Modifiers** (U+1F3FB-U+1F3FF):
- Light Skin Tone: U+1F3FB
- Medium-Light Skin Tone: U+1F3FC
- Medium Skin Tone: U+1F3FD
- Medium-Dark Skin Tone: U+1F3FE
- Dark Skin Tone: U+1F3FF

**Gender Modifiers**:
- Zero-Width Joiner (ZWJ): U+200D
- Female Sign: U+2640
- Male Sign: U+2642

**Variation Selectors**:
- Variation Selector-15 (emoji): U+FE0E
- Variation Selector-16 (text): U+FE0F

GraveGain uses base emoji without modifiers for consistency across all emoji sets.

---

## Emoji Set Comparison Matrix

### Visual Quality Comparison

| Aspect | Twemoji | Noto | OpenMoji | Blobmoji | Fluent | JoyPixels | Samsung |
|--------|---------|------|----------|----------|--------|-----------|---------|
| Clarity at 32px | 9/10 | 8/10 | 8/10 | 7/10 | 9/10 | 8/10 | 8/10 |
| Clarity at 48px | 10/10 | 9/10 | 9/10 | 9/10 | 10/10 | 9/10 | 9/10 |
| Detail Level | Medium | Medium | Low | Low | High | Medium | Medium |
| Color Saturation | High | Medium | Medium | Low | High | High | Very High |
| Consistency | Excellent | Good | Excellent | Good | Excellent | Good | Good |
| Distinctiveness | High | Medium | High | Medium | High | Medium | High |
| File Size | Small | Large | Small | Medium | Very Large | Medium | Large |
| Load Time | Fast | Slow | Fast | Medium | Very Slow | Medium | Slow |

### Feature Support Comparison

| Feature | Twemoji | Noto | OpenMoji | Blobmoji | Fluent | JoyPixels | Samsung |
|---------|---------|------|----------|----------|--------|-----------|---------|
| All Game Emoji | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Skin Tones | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| ZWJ Sequences | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Variation Selectors | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Regional Indicators | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Keycap Sequences | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Flag Emoji | Yes | Yes | Yes | Yes | Yes | Yes | Yes |

---

## Performance Optimization Guide

### Reducing Font Load Times

1. **Use Twemoji or OpenMoji**: These are the smallest fonts (~6-10 MB) and load fastest.

2. **Lazy Load Fonts**: Load fonts only when selected:
```gdscript
var loaded_fonts: Dictionary = {}

func get_font(set_name: String) -> Font:
	if set_name not in loaded_fonts:
		loaded_fonts[set_name] = load_font_from_disk(set_name)
	return loaded_fonts[set_name]
```

3. **Cache Glyphs Aggressively**: Pre-render common emoji at startup:
```gdscript
func preload_common_glyphs(font: Font) -> void:
	var common_emoji = [
		"\U0001F9D1",  # Player
		"\U0001F480",  # Skeleton
		"\U0001F525",  # Fire
		# ... more emoji
	]
	for emoji in common_emoji:
		draw_string(font, Vector2.ZERO, emoji)  # Trigger caching
```

4. **Reduce Glyph Variants**: Avoid rendering the same emoji at many different sizes.

### Memory Optimization

1. **Use Smaller Fonts**: OpenMoji at ~6 MB uses 50% less memory than Noto at ~24 MB.

2. **Unload Unused Fonts**: Clear the glyph cache when switching fonts:
```gdscript
func clear_glyph_cache() -> void:
	get_tree().call_group("canvas_item", "queue_redraw")
```

3. **Monitor VRAM**: Use Godot's profiler to track font memory usage.

### Rendering Optimization

1. **Batch Emoji Rendering**: Group emoji draws together for better GPU utilization.

2. **Use Atlasing**: Godot automatically atlases rendered glyphs. Ensure consistent sizes.

3. **Avoid Frequent Font Switches**: Switching fonts clears the glyph cache. Minimize switches during gameplay.

---

## Troubleshooting Extended

### Font File Corruption

**Symptom**: Font file is present but causes crashes or doesn't load.

**Solutions**:
1. Re-download the font file from the official source
2. Verify file integrity: Check file size against official release
3. Try a different font set to isolate the issue
4. Check Godot console for specific error messages

### Emoji Rendering Artifacts

**Symptom**: Emoji have visual glitches, artifacts, or rendering errors.

**Causes**:
1. **Glyph Cache Corruption**: Clear cache by restarting the game
2. **Godot Version Issue**: Update to Godot 4.6 or later
3. **Graphics Driver**: Update GPU drivers
4. **Font Format Mismatch**: Ensure font is valid TrueType

### Emoji Appearing Tiny or Huge

**Symptom**: Emoji render at incorrect sizes.

**Solutions**:
1. Check that `fixed_size` is set correctly (32 or 48)
2. Verify DPI scaling settings in Godot project
3. Check that font variant is being used correctly
4. Ensure no conflicting font size settings elsewhere

### Font Not Persisting After Restart

**Symptom**: Selected emoji set reverts to System after restarting.

**Causes**:
1. **Save Permission Issue**: Check write permissions on user data directory
2. **Font File Moved**: Ensure font file stays in original location
3. **Settings File Corruption**: Delete `user://settings.cfg` and restart

### Emoji Rendering Slowly

**Symptom**: Game stutters when rendering emoji.

**Causes**:
1. **Large Font File**: Fluent Emoji takes time to load. This is normal.
2. **Glyph Cache Thrashing**: Rendering too many unique emoji variants
3. **GPU Memory Pressure**: Reduce other graphics quality settings
4. **CPU Bottleneck**: Profile with Godot's profiler to identify bottleneck

---

## Advanced Customization

### Creating a Custom Emoji Set

**Step 1: Prepare Artwork**

Create SVG files for each emoji. Example structure:
```
custom_emoji/
├── emoji_u1f9d1.svg  (Player - Person)
├── emoji_u1f480.svg  (Skeleton)
├── emoji_u1f525.svg  (Fire)
└── ... (more emoji)
```

**Step 2: Build Font with nanoemoji**

```bash
# Install nanoemoji
pip install nanoemoji

# Build COLR font
nanoemoji --color_format glyf_colr_1 \
  --output CustomEmoji.ttf \
  custom_emoji/*.svg
```

**Step 3: Register in EmojiManager**

```gdscript
# Add to EMOJI_SETS dictionary
"custom": {
    "name": "Custom Emoji",
    "desc": "Your custom emoji set",
    "font_file": "CustomEmoji.ttf",
    "license": "Your License",
    "url": "",
    "icon": "\U0001F3A8",
    "builtin": false,
}
```

**Step 4: Test**

1. Place `CustomEmoji.ttf` in `fonts/emoji/`
2. Restart game
3. Select "Custom Emoji" from settings
4. Verify all emoji render correctly

### Modifying EmojiManager

For advanced customization, extend EmojiManager:

```gdscript
extends "res://scripts/autoload/emoji_manager.gd"

# Override font loading
func _load_font_from_path(path: String) -> Font:
	var font = super._load_font_from_path(path)
	# Apply custom modifications
	font.fixed_size = 32
	return font

# Add custom fonts
func get_custom_fonts() -> Dictionary:
	return {
		"my_set": "res://fonts/emoji/MyCustomFont.ttf"
	}
```

---

## Integration with Game Systems

### Using Emoji in HUD

```gdscript
# Display emoji in labels
var health_label = Label.new()
health_label.text = "\U00002764 100/100"  # ❤ 100/100
health_label.add_theme_font_override("font", GameData.emoji_font)
health_label.add_theme_font_size_override("font_size", 32)
```

### Using Emoji in Lore

```gdscript
# Emoji in lore entries
var lore_entry = {
    "title": "The Skeleton King \U0001F480",
    "text": "A powerful undead ruler...",
    "emoji": "\U0001F480"
}
```

### Using Emoji in Dialogue

```gdscript
# Emoji in NPC dialogue
var dialogue = "Greetings, brave \U0001F9D1! \U0001F44B"
```

---

## Accessibility Deep Dive

### Colorblind-Friendly Emoji Selection

For colorblind players, OpenMoji is recommended due to its consistent black outlines:

```gdscript
# Detect colorblind mode and auto-select OpenMoji
if GameSystems.colorblind_mode:
    EmojiManager.apply_emoji_set("openmoji")
```

### Screen Reader Integration

Emoji should have semantic meaning separate from visual representation:

```gdscript
# Store semantic meaning
var entity_types = {
    "player": {
        "emoji": "\U0001F9D1",
        "name": "Player Character",
        "description": "The player-controlled character"
    },
    "skeleton": {
        "emoji": "\U0001F480",
        "name": "Skeleton Enemy",
        "description": "An undead skeletal warrior"
    }
}
```

### Large Text Mode

Support larger emoji for accessibility:

```gdscript
# Large emoji variant
var large_emoji_size = 48
var large_emoji_font = GameData.emoji_font_large
```

---

## Distribution and Licensing

### Bundling Fonts with GraveGain

If distributing GraveGain with bundled fonts:

1. **Check Licenses**: Ensure all fonts have appropriate licenses
2. **Include Attribution**: Add license files and credits
3. **Avoid Proprietary Fonts**: Don't bundle Samsung emoji
4. **Document Licenses**: Include `FONTS_LICENSE.txt`

### Example Attribution File

```
EMOJI FONTS ATTRIBUTION
=======================

This build of GraveGain includes the following emoji fonts:

Twemoji
-------
Copyright (c) 2014-2024 Twitter, Inc and other contributors
Licensed under CC BY 4.0 (graphics) and Apache 2.0 (font)
https://github.com/twitter/twemoji

Noto Color Emoji
----------------
Copyright (c) 2014-2024 Google and contributors
Licensed under Apache 2.0
https://github.com/googlefonts/noto-emoji

[Additional fonts...]
```

---

## FAQ Extended

### Installation Questions

**Q: Where exactly should I put the font files?**
A: Either `v2/2d2/grave-gain-2d-2/fonts/emoji/` (in the project) or `user://fonts/emoji/` (in user data). The user directory is recommended for end users.

**Q: Do I need to restart the game after adding a font?**
A: No. Click "Rescan for Fonts" in settings to detect newly added fonts without restarting.

**Q: Can I have fonts in both directories?**
A: Yes. The user directory takes priority if the same font exists in both locations.

### Compatibility Questions

**Q: Will emoji work on mobile devices?**
A: Yes. All supported emoji fonts work on iOS and Android. System emoji is recommended for mobile.

**Q: Can I use emoji fonts in exported builds?**
A: Yes. If you include fonts in `fonts/emoji/`, they'll be available in exported builds.

**Q: What about web exports?**
A: Web exports can use System emoji or bundled fonts. Keep file sizes small for web.

### Customization Questions

**Q: Can I create my own emoji set?**
A: Yes. See the "Creating Custom Emoji Sets" section. You'll need SVG artwork and nanoemoji.

**Q: Can I use emoji from different sets simultaneously?**
A: Not through the standard UI. Advanced users can modify EmojiManager to support per-entity fonts.

**Q: Can I modify existing emoji sets?**
A: You can create derivatives under the appropriate license (CC BY-SA for OpenMoji, etc.).

### Performance Questions

**Q: Why is Fluent Emoji so large?**
A: At ~42 MB, Fluent includes detailed 3D-style vector graphics. Smaller fonts like Twemoji (~10 MB) are faster.

**Q: Does emoji quality affect game performance?**
A: No. All emoji sets render at the same speed after initial loading. The difference is file size and load time.

**Q: Can I reduce memory usage?**
A: Use smaller fonts (Twemoji, OpenMoji) or unload unused fonts. Monitor VRAM with Godot's profiler.

---

## Technical Reference

### Font File Specifications

**Minimum Requirements**:
- Format: TrueType (.ttf)
- Color Tables: COLR/CPAL or CBDT/CBLC
- Minimum Glyphs: 50+ (for GraveGain's emoji set)
- File Size: Up to ~50 MB (practical limit)

**Recommended Specifications**:
- Format: TrueType (.ttf) with COLR/CPAL v1
- Glyphs: 3000+ (full Unicode emoji set)
- File Size: Under 20 MB
- Hinting: Optimized for screen rendering

### Godot Font API

Key methods for emoji font handling:

```gdscript
# Load font
var font = FontFile.new()
font.load_dynamic_font(path)

# Set size
font.fixed_size = 32

# Create variant
var large_font = font.duplicate()
large_font.fixed_size = 48

# Use in drawing
draw_string(font, position, emoji_char, alignment, width, size, color)

# Use in labels
label.add_theme_font_override("font", font)
label.add_theme_font_size_override("font_size", 32)
```

### Text Server Integration

Godot 4.6 uses HarfBuzz for text shaping and FreeType for font rasterization:

```
Font File (.ttf)
    ↓
FreeType (loads font tables)
    ↓
HarfBuzz (shapes text, handles ligatures/features)
    ↓
Text Server (rasterizes glyphs)
    ↓
Glyph Cache (stores rasterized glyphs)
    ↓
GPU Rendering (draws cached glyphs)
```

---

## Conclusion

The emoji font system in GraveGain provides a flexible, extensible way to customize the game's visual style. Whether you use the default system emoji, one of the 7 supported sets, or create your own custom emoji font, the system handles font loading, caching, and rendering efficiently.

For questions or issues, refer to the Troubleshooting section or check the official repositories of the emoji font projects.

*Happy emoji gaming!*
