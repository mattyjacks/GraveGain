# SVG Emoji System Guide

## Overview
GraveGain now supports rendering emoji directly from SVG files. This provides a lightweight, scalable alternative to font-based emoji rendering.

## What You Have

You've uploaded a comprehensive collection of Twemoji SVG files to `fonts/emoji/svg/`. These files use Unicode codepoint naming (e.g., `1f426.svg` for 🐦).

## How It Works

### SVG Emoji Renderer
The `SvgEmojiRenderer` autoload script:
- Automatically detects SVG emoji files in `res://fonts/emoji/svg/`
- Maps Unicode characters to their corresponding SVG files
- Caches loaded textures for performance
- Provides methods to load emoji as textures

### File Naming Convention
SVG files are named using their Unicode codepoint in hexadecimal:
- `1f426.svg` = 🐦 (Bird emoji, U+1F426)
- `1f4bb.svg` = 💻 (Laptop emoji, U+1F4BB)
- `1f600.svg` = 😀 (Grinning face, U+1F600)

Multi-codepoint emoji use hyphens:
- `1f468-200d-1f373.svg` = 👨‍🍳 (Man cooking, U+1F468 + ZWJ + U+1F373)

## Usage

### In GDScript
```gdscript
# Get a texture for an emoji
var emoji_texture = SvgEmojiRenderer.load_emoji_texture("🐦", 32)

# Check if SVG emoji is available
if SvgEmojiRenderer.is_svg_emoji_available():
    print("SVG emoji ready!")

# Get count of available emoji
var count = SvgEmojiRenderer.get_available_emoji_count()
print("Available emoji: " + str(count))

# Clear the texture cache
SvgEmojiRenderer.clear_cache()

# Print status
SvgEmojiRenderer.print_status()
```

### In UI (TextureRect)
```gdscript
var emoji_texture = SvgEmojiRenderer.load_emoji_texture("😀", 64)
if emoji_texture:
    $TextureRect.texture = emoji_texture
```

## Performance Considerations

### Caching
- Loaded textures are cached (max 256 entries by default)
- Cache is automatically cleared when full
- Use `clear_cache()` to manually clear if needed

### Rendering
- SVG files are vector-based and scale without quality loss
- Specify desired size when loading: `load_emoji_texture(emoji, size)`
- Smaller sizes = better performance

### Memory
- SVG rendering is more memory-efficient than large font files
- Only loaded emoji are kept in memory
- Cache prevents redundant loading

## File Structure
```
GraveGain/
├── fonts/
│   └── emoji/
│       └── svg/
│           ├── 1f426.svg (🐦)
│           ├── 1f4bb.svg (💻)
│           ├── 1f600.svg (😀)
│           └── ... (3000+ more emoji)
├── scripts/
│   └── autoload/
│       ├── svg_emoji_renderer.gd
│       ├── emoji_manager.gd
│       └── ...
└── SVG_EMOJI_GUIDE.md (this file)
```

## Available Emoji Count
Your uploaded SVG collection contains **3000+ emoji**, including:
- Basic emoji (faces, objects, nature)
- People with skin tone variations
- Flags and regional indicators
- Symbols and special characters
- Multi-codepoint sequences (ZWJ sequences)

## Integration with EmojiManager

The `EmojiManager` autoload now:
1. Detects SVG emoji availability on startup
2. Logs the number of available emoji
3. Can switch between font-based and SVG-based emoji rendering
4. Maintains compatibility with existing emoji set system

## Troubleshooting

### SVG Emoji Not Loading
1. Verify files are in `res://fonts/emoji/svg/`
2. Check file naming (should be hex codepoint + `.svg`)
3. Ensure SVG files are valid
4. Check console for error messages

### Performance Issues
1. Reduce cache size if memory is limited
2. Use smaller emoji sizes when possible
3. Clear cache periodically: `SvgEmojiRenderer.clear_cache()`

### Missing Emoji
1. Check if the emoji's SVG file exists
2. Verify the Unicode codepoint is correct
3. Some complex emoji may require multi-codepoint sequences

## Advantages Over Font-Based Emoji

| Feature | SVG | Font |
|---------|-----|------|
| Scalability | Perfect (vector) | Good (rasterized) |
| Memory | Low (on-demand) | High (entire font) |
| Performance | Good (cached) | Good (native) |
| Customization | Easy (SVG editing) | Limited |
| File Size | Small per emoji | Large (whole font) |

## License
Twemoji SVG files are licensed under:
- CC BY 4.0 (Creative Commons Attribution 4.0)
- Apache 2.0

See: https://github.com/twitter/twemoji/blob/master/LICENSE.txt

## Resources
- **Twemoji Repository**: https://github.com/twitter/twemoji
- **Unicode Emoji List**: https://unicode.org/emoji/charts/full-emoji-list.html
- **Godot SVG Support**: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images/index.html

## Next Steps

1. **Test SVG Emoji Loading**: Use `SvgEmojiRenderer.print_status()` to verify setup
2. **Integrate into UI**: Update your UI elements to use `load_emoji_texture()`
3. **Customize**: Edit SVG files directly to customize emoji appearance
4. **Optimize**: Adjust cache size based on your needs

## Support

For issues with SVG emoji rendering:
1. Check console output for error messages
2. Verify SVG file integrity
3. Ensure Unicode codepoint is correct
4. Check Godot version compatibility (4.6+)
