# Twemoji Integration Guide

## Overview
This document describes how to integrate Twemoji SVG assets into GraveGain.

## Option 1: Use Pre-Built Twemoji COLR Font (Recommended)
The easiest approach is to use the Mozilla Twemoji COLR font, which is a single TTF file containing all Twemoji emoji.

### Steps:
1. Download from: https://github.com/mozilla/twemoji-colr/releases
2. Download the latest `Twemoji.Mozilla.ttf` file
3. Place it in `fonts/emoji/` directory
4. The EmojiManager will automatically detect and use it

## Option 2: Build from SVG Assets
If you want to build from the original SVG files:

1. Clone the Twemoji repository:
   ```bash
   git clone https://github.com/twitter/twemoji.git
   ```

2. Install FontTools and other dependencies:
   ```bash
   pip install fonttools
   ```

3. Use the build scripts in the Twemoji repo to generate the font file

## Integration Status
- EmojiManager already supports Twemoji as a selectable emoji set
- Font file location: `res://fonts/emoji/Twemoji.Mozilla.ttf`
- Alternative names supported: `TwemojiMozilla.ttf`, `Twemoji Mozilla.ttf`, `twemoji.ttf`

## Usage in Game
1. Start the game
2. Go to Graphics Settings
3. Select "Twemoji" from the emoji set dropdown
4. All emoji will render using Twemoji style

## License
Twemoji is licensed under CC BY 4.0 and Apache 2.0
See: https://github.com/twitter/twemoji/blob/master/LICENSE.txt
