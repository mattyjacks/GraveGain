#!/usr/bin/env python3
"""
Convert SVG emoji to PNG at 256x256 resolution
Uses ImageMagick or Inkscape
"""

import os
import subprocess
import sys
from pathlib import Path

# All emoji needed for the game
EMOJI_LIST = [
    # Races
    ("\U0001F469\u200D\U0001F680", "human"),  # Human
    ("\U0001F9DD\u200D\u2640\uFE0F", "elf"),  # Elf
    ("\u26CF\uFE0F", "dwarf"),  # Dwarf
    ("\U0001F479", "orc"),  # Orc
    
    # Classes
    ("\u2694\uFE0F", "dps"),  # Sword (DPS)
    ("\U0001F6E1\uFE0F", "tank"),  # Shield (Tank)
    ("\U0001F49A", "support"),  # Green Heart (Support)
    ("\U0001F52E", "mage"),  # Crystal Ball (Mage)
    
    # Enemies
    ("\U0001F480", "skeleton"),  # Skeleton
    ("\U0001F9DF", "zombie"),  # Zombie
    ("\U0001F47B", "ghost"),  # Ghost
    ("\U0001F47A", "ogre"),  # Ogre
    ("\U0001F916", "robot"),  # Robot
    ("\U0001F9D9", "wizard"),  # Wizard
    
    # Food (sample)
    ("\U0001F347", "grapes"),
    ("\U0001F348", "melon"),
    ("\U0001F349", "watermelon"),
    ("\U0001F34A", "tangerine"),
    ("\U0001F34B", "lemon"),
    ("\U0001F34C", "banana"),
    ("\U0001F34D", "pineapple"),
    ("\U0001F96D", "mango"),
    ("\U0001F34E", "apple"),
    ("\U0001F34F", "green_apple"),
    ("\U0001F350", "pear"),
    ("\U0001F351", "peach"),
    ("\U0001F352", "cherries"),
    ("\U0001F353", "strawberry"),
    ("\U0001FAD0", "blueberries"),
    ("\U0001F95D", "kiwi"),
    ("\U0001F345", "tomato"),
    ("\U0001FAD2", "olive"),
    ("\U0001F965", "coconut"),
    ("\U0001F951", "avocado"),
    ("\U0001F346", "eggplant"),
    ("\U0001F954", "potato"),
    ("\U0001F955", "carrot"),
    ("\U0001F33D", "corn"),
    ("\U0001F336\uFE0F", "hot_pepper"),
    ("\U0001FAD1", "bell_pepper"),
    ("\U0001F952", "cucumber"),
    ("\U0001F96C", "leafy_green"),
    ("\U0001F966", "broccoli"),
    ("\U0001F9C4", "garlic"),
    ("\U0001F9C5", "onion"),
    ("\U0001F344", "mushroom"),
    ("\U0001F95C", "peanuts"),
    ("\U0001FAD8", "beans"),
    ("\U0001F330", "chestnut"),
    ("\U0001F35E", "bread"),
    ("\U0001F950", "croissant"),
    ("\U0001F956", "baguette"),
    ("\U0001FAD3", "flatbread"),
    ("\U0001F968", "pretzel"),
    ("\U0001F96F", "bagel"),
    ("\U0001F95E", "pancakes"),
    ("\U0001F9C7", "waffle"),
    ("\U0001F359", "rice_ball"),
    ("\U0001F358", "rice_cracker"),
    ("\U0001F35A", "cooked_rice"),
    ("\U0001F356", "meat_leg"),
    ("\U0001F357", "poultry_leg"),
    ("\U0001F969", "steak"),
    ("\U0001F953", "bacon"),
    ("\U0001F32D", "hot_dog"),
    ("\U0001F354", "hamburger"),
    ("\U0001F96A", "sandwich"),
    ("\U0001F32E", "taco"),
    ("\U0001F32F", "burrito"),
    ("\U0001FAD4", "tamale"),
    ("\U0001F959", "stuffed_flatbread"),
    ("\U0001F9C6", "falafel"),
    ("\U0001F95A", "egg"),
    ("\U0001F373", "fried_egg"),
    ("\U0001F41F", "fish"),
    ("\U0001F990", "shrimp"),
    ("\U0001F991", "squid"),
    ("\U0001F99E", "lobster"),
    ("\U0001F980", "crab"),
    ("\U0001F9AA", "oyster"),
    ("\U0001F363", "sushi"),
    ("\U0001F364", "fried_shrimp"),
    ("\U0001F372", "stew"),
    ("\U0001F35B", "curry"),
    ("\U0001F35D", "spaghetti"),
    ("\U0001F35C", "ramen"),
    ("\U0001FAD5", "fondue"),
    ("\U0001F957", "green_salad"),
    ("\U0001F958", "shallow_pan_food"),
    ("\U0001F96B", "canned_food"),
    ("\U0001F371", "bento_box"),
    ("\U0001F95F", "dumpling"),
    ("\U0001F960", "fortune_cookie"),
    ("\U0001F961", "takeout_box"),
    ("\U0001F362", "oden"),
    ("\U0001F361", "dango"),
    ("\U0001F96E", "moon_cake"),
    ("\U0001F355", "pizza"),
    ("\U0001F35F", "fries"),
    ("\U0001F37F", "popcorn"),
    ("\U0001F9C0", "cheese"),
    ("\U0001F9C8", "butter"),
    ("\U0001F36B", "chocolate"),
    ("\U0001F36C", "candy"),
    ("\U0001F36D", "lollipop"),
    ("\U0001F36E", "custard"),
    ("\U0001F36F", "honey"),
    ("\U0001F36A", "cookie"),
    ("\U0001F370", "cake"),
    ("\U0001F382", "birthday_cake"),
    ("\U0001F9C1", "cupcake"),
    ("\U0001F967", "pie"),
    ("\U0001F368", "ice_cream"),
    ("\U0001F367", "shaved_ice"),
    ("\U0001F366", "soft_ice_cream"),
    ("\U0001F369", "doughnut"),
    ("\U0001F37C", "baby_bottle"),
    ("\U0001F95B", "glass_milk"),
    ("\u2615", "coffee"),
    ("\U0001FAD6", "tea"),
    ("\U0001F375", "teacup"),
    ("\U0001F376", "sake"),
    ("\U0001F377", "wine"),
    ("\U0001F37A", "beer"),
    ("\U0001F37B", "beers"),
    ("\U0001F378", "cocktail"),
    ("\U0001F379", "tropical_drink"),
    ("\U0001F943", "tumbler_glass"),
    ("\U0001F964", "cup_with_straw"),
    ("\U0001F9CB", "bubble_tea"),
    ("\U0001F9C3", "juice_box"),
    ("\U0001F9C9", "mate"),
    ("\U0001F9CA", "ice_cube"),
    ("\U0001F9C2", "salt"),
    ("\U0001FAD9", "jar"),
    
    # Items
    ("\U0001FA99", "gold_coin"),
    ("\U0001F947", "gold_bar"),
    ("\U0001F48E", "gold_cube"),
    ("\U0001F48D", "ring"),
    ("\U0001F3FA", "vase"),
    ("\U0001F531", "trident"),
    ("\U0001F4E6", "ammo_box"),
    
    # UI
    ("\U0001F525", "torch"),
    ("\U0001F48C", "envelope"),
    ("\u26A1", "lightning"),
    ("\u2694\uFE0F", "crossed_swords"),
    ("\U0001F6E1\uFE0F", "shield"),
    ("\U0001F4A2", "anger"),
    ("\u2764\uFE0F", "heart"),
    ("\U0001FA99", "money_bag"),
    ("\u2B50", "star"),
]

def emoji_to_hex(emoji: str) -> str:
    """Convert emoji to hex codepoint string"""
    hex_parts = []
    for char in emoji:
        cp = ord(char)
        if cp > 0:
            hex_parts.append(f"{cp:x}")
    return "-".join(hex_parts)

def convert_svg_to_png(svg_path: str, png_path: str, size: int = 256) -> bool:
    """Convert SVG to PNG using available tools"""
    try:
        # Try ImageMagick first
        result = subprocess.run(
            ["convert", "-density", "96", "-resize", f"{size}x{size}", 
             "-background", "none", svg_path, png_path],
            capture_output=True,
            timeout=10
        )
        if result.returncode == 0:
            return True
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    
    try:
        # Try Inkscape
        result = subprocess.run(
            ["inkscape", "-w", str(size), "-h", str(size), 
             svg_path, "-o", png_path],
            capture_output=True,
            timeout=10
        )
        if result.returncode == 0:
            return True
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    
    return False

def main():
    svg_dir = Path("fonts/emoji/svg")
    png_dir = Path("fonts/emoji/png")
    
    # Create PNG directory
    png_dir.mkdir(parents=True, exist_ok=True)
    
    print("\n=== Converting Emoji to PNG ===\n")
    print(f"Total emoji to convert: {len(EMOJI_LIST)}\n")
    
    converted = 0
    failed = 0
    
    for emoji, name in EMOJI_LIST:
        hex_code = emoji_to_hex(emoji)
        svg_file = svg_dir / f"{hex_code}.svg"
        png_file = png_dir / f"{hex_code}.png"
        
        # Skip if PNG already exists
        if png_file.exists():
            print(f"✓ {emoji} ({name}) - already exists")
            converted += 1
            continue
        
        # Skip if SVG doesn't exist
        if not svg_file.exists():
            print(f"✗ {emoji} ({name}) - SVG not found: {svg_file}")
            failed += 1
            continue
        
        # Convert
        if convert_svg_to_png(str(svg_file), str(png_file), 256):
            print(f"✓ {emoji} ({name}) -> {hex_code}.png")
            converted += 1
        else:
            print(f"✗ {emoji} ({name}) - conversion failed")
            failed += 1
    
    print(f"\n=== Conversion Complete ===")
    print(f"Converted: {converted}")
    print(f"Failed: {failed}")
    print(f"Total: {converted + failed}\n")

if __name__ == "__main__":
    main()
