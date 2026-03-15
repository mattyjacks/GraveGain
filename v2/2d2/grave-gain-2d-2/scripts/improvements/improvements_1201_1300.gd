extends Node

# Improvements #1201-1300 - Quality of Life, Visual Polish, AI, and Performance

class_name Improvements1201_1300

static func get_improvements() -> Dictionary:
	return {
		1201: {
			"name": "Tooltip System",
			"desc": "Hover over UI elements to see helpful tooltips with descriptions",
			"category": "ui",
		},
		1202: {
			"name": "Floating Damage Numbers",
			"desc": "See damage values float up from enemies when you hit them",
			"category": "ui",
		},
		1203: {
			"name": "Floating Healing Numbers",
			"desc": "See healing values float up when you restore health",
			"category": "ui",
		},
		1204: {
			"name": "Floating XP Numbers",
			"desc": "See XP gains displayed as floating numbers",
			"category": "ui",
		},
		1205: {
			"name": "Floating Gold Numbers",
			"desc": "See gold pickup amounts as floating numbers",
			"category": "ui",
		},
		1206: {
			"name": "Enemy Health Bars",
			"desc": "Display health bars above enemies during combat",
			"category": "ui",
		},
		1207: {
			"name": "Status Effect Indicators",
			"desc": "Show visual indicators for active status effects on player",
			"category": "ui",
		},
		1208: {
			"name": "UI Sound Effects",
			"desc": "Play subtle sound effects for UI interactions",
			"category": "audio",
		},
		1209: {
			"name": "Combat Sound Effects",
			"desc": "Enhanced audio feedback for combat actions",
			"category": "audio",
		},
		1210: {
			"name": "Ambient Sound System",
			"desc": "Background music and ambient sounds for different areas",
			"category": "audio",
		},
		1211: {
			"name": "Screen Flash Effects",
			"desc": "Screen flashes on critical hits and major events",
			"category": "graphics",
		},
		1212: {
			"name": "Particle Effects",
			"desc": "Enhanced particle effects for spells and abilities",
			"category": "graphics",
		},
		1213: {
			"name": "Screen Shake",
			"desc": "Camera shake on impacts and explosions",
			"category": "graphics",
		},
		1214: {
			"name": "Chromatic Aberration",
			"desc": "Color separation effect on major hits",
			"category": "graphics",
		},
		1215: {
			"name": "Combo Indicators",
			"desc": "Display combo counter with visual feedback",
			"category": "ui",
		},
		1216: {
			"name": "Damage Direction Indicator",
			"desc": "Arrow showing direction of incoming damage",
			"category": "ui",
		},
		1217: {
			"name": "Enemy Formation AI",
			"desc": "Enemies form tactical formations (line, wedge, circle)",
			"category": "ai",
		},
		1218: {
			"name": "Flanking Tactics",
			"desc": "Enemies attempt to flank the player",
			"category": "ai",
		},
		1219: {
			"name": "Coordinated Attacks",
			"desc": "Multiple enemies coordinate their attacks",
			"category": "ai",
		},
		1220: {
			"name": "Tactical Retreat",
			"desc": "Enemies retreat when heavily outnumbered or low health",
			"category": "ai",
		},
		1221: {
			"name": "Defensive Positioning",
			"desc": "Enemies position themselves defensively",
			"category": "ai",
		},
		1222: {
			"name": "Target Priority AI",
			"desc": "Enemies prioritize targets based on threat level",
			"category": "ai",
		},
		1223: {
			"name": "Object Pooling",
			"desc": "Reuse objects instead of creating/destroying for performance",
			"category": "performance",
		},
		1224: {
			"name": "Frustum Culling",
			"desc": "Hide objects outside camera view for performance",
			"category": "performance",
		},
		1225: {
			"name": "Level of Detail System",
			"desc": "Reduce detail on distant objects",
			"category": "performance",
		},
		1226: {
			"name": "Physics Optimization",
			"desc": "Optimize physics calculations for better performance",
			"category": "performance",
		},
		1227: {
			"name": "Render Batching",
			"desc": "Batch render calls for improved GPU efficiency",
			"category": "performance",
		},
		1228: {
			"name": "Calculation Caching",
			"desc": "Cache expensive calculations to reduce CPU usage",
			"category": "performance",
		},
		1229: {
			"name": "Colorblind Mode",
			"desc": "Adjust colors for colorblind players (Deuteranopia, Protanopia, Tritanopia)",
			"category": "accessibility",
		},
		1230: {
			"name": "Text Scaling",
			"desc": "Adjust UI text size for readability",
			"category": "accessibility",
		},
		1231: {
			"name": "UI Opacity Control",
			"desc": "Adjust transparency of UI elements",
			"category": "accessibility",
		},
		1232: {
			"name": "Animation Speed Control",
			"desc": "Adjust speed of all animations",
			"category": "accessibility",
		},
		1233: {
			"name": "Reduced Motion Mode",
			"desc": "Minimize animations and screen effects",
			"category": "accessibility",
		},
		1234: {
			"name": "High Contrast Mode",
			"desc": "Increase contrast for better visibility",
			"category": "accessibility",
		},
		1235: {
			"name": "Quick Save System",
			"desc": "Quick save and load game state",
			"category": "quality_of_life",
		},
		1236: {
			"name": "Auto-Save System",
			"desc": "Automatically save progress at intervals",
			"category": "quality_of_life",
		},
		1237: {
			"name": "Inventory Search",
			"desc": "Search and filter inventory items",
			"category": "quality_of_life",
		},
		1238: {
			"name": "Item Comparison",
			"desc": "Compare equipment stats side-by-side",
			"category": "quality_of_life",
		},
		1239: {
			"name": "Quick Equip",
			"desc": "Quickly equip items from inventory",
			"category": "quality_of_life",
		},
		1240: {
			"name": "Hotkey System",
			"desc": "Assign items and abilities to hotkeys",
			"category": "quality_of_life",
		},
		1241: {
			"name": "Minimap Zoom",
			"desc": "Zoom in/out on the minimap",
			"category": "ui",
		},
		1242: {
			"name": "Minimap Markers",
			"desc": "Place custom markers on minimap",
			"category": "ui",
		},
		1243: {
			"name": "Quest Tracker",
			"desc": "Track active quests and objectives",
			"category": "ui",
		},
		1244: {
			"name": "Achievement System",
			"desc": "Unlock achievements for various accomplishments",
			"category": "progression",
		},
		1245: {
			"name": "Statistics Tracking",
			"desc": "Track detailed game statistics",
			"category": "progression",
		},
		1246: {
			"name": "Leaderboard System",
			"desc": "Compare scores with other players",
			"category": "progression",
		},
		1247: {
			"name": "Daily Challenges",
			"desc": "Complete daily challenges for rewards",
			"category": "progression",
		},
		1248: {
			"name": "Weekly Events",
			"desc": "Special events that occur weekly",
			"category": "progression",
		},
		1249: {
			"name": "Seasonal Content",
			"desc": "Limited-time seasonal content and rewards",
			"category": "progression",
		},
		1250: {
			"name": "Performance Monitor",
			"desc": "Display FPS and performance metrics",
			"category": "debug",
		},
	}
