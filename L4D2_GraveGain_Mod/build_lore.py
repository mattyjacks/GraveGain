import re
import os

lua_files = [
    r"c:\GitHub5\GraveGain\v2\3dRoblox\src\shared\lore_entries_1.lua",
    r"c:\GitHub5\GraveGain\v2\3dRoblox\src\shared\lore_entries_2.lua"
]

out_file = r"c:\GitHub5\GraveGain\L4D2_GraveGain_Mod\scripts\vscripts\lore_system.nut"

entries = []

for fpath in lua_files:
    if os.path.exists(fpath):
        with open(fpath, "r", encoding="utf-8") as f:
            content = f.read()
            
            # Find all e["key"] = { ... } blocks
            # We can use regex or simple string matching
            matches = re.finditer(r'e\["([^"]+)"\]\s*=\s*\{([^}]+)\}', content)
            for m in matches:
                key = m.group(1)
                data = m.group(2)
                
                # Extract title
                title_match = re.search(r'title\s*=\s*"([^"]+)"', data)
                title = title_match.group(1) if title_match else key
                
                # Extract rarity
                rarity_match = re.search(r'rarity\s*=\s*"([^"]+)"', data)
                rarity = rarity_match.group(1) if rarity_match else "common"
                
                # Extract content
                content_match = re.search(r'content\s*=\s*"([^"]+)"', data)
                if not content_match:
                     content_match = re.search(r'content\s*=\s*\[\[(.*?)\]\]', data, re.DOTALL)
                
                if content_match:
                    text = content_match.group(1)
                    # Escape quotes and newlines for squirrel
                    text = text.replace('"', '\\"').replace('\n', '\\n')
                    entries.append((title, text, rarity))

vscript = """// Lore System for GraveGain Overhaul
printl("Loading GraveGain Lore System...");

if (!("GraveGainLore" in getroottable())) {
    ::GraveGainLore <- {
        Entries = [],
        DropChance = 5, // 5% chance on infected death
        Models = {
            common = "models/props_lab/scroll.mdl",
            uncommon = "models/props_interiors/book01.mdl",
            rare = "models/props_interiors/book02.mdl",
            epic = "models/props_collectables/toy_gnome.mdl",
            legendary = "models/props_collectables/toy_gnome.mdl"
        },
        GlowColors = {
            common = "255 255 255",
            uncommon = "0 255 0",
            rare = "0 0 255",
            epic = "128 0 128",
            legendary = "255 215 0"
        }
    }
}

"""

for idx, (title, text, rarity) in enumerate(entries):
    vscript += f'GraveGainLore.Entries.append({{ title = "{title}", text = "{text}", rarity = "{rarity}" }});\n'

vscript += """
function GraveGainLore::OnInfectedDeath(params) {
    if (params == null) return;
    if (!("entityid" in params)) return;
    
    if (RandomInt(1, 100) <= DropChance) {
        local infectedId = params["entityid"];
        if (infectedId == null || infectedId <= 0) return;
        
        local ent = EntIndexToHScript(infectedId);
        if (ent && ent.IsValid()) {
            local pos = ent.GetOrigin();
            pos.z += 20;
            
            local loreIdx = RandomInt(0, Entries.len() - 1);
            local lore = Entries[loreIdx];
            local model = Models[lore.rarity];
            local glow = GlowColors[lore.rarity];
            
            local prop = SpawnEntityFromTable("prop_physics_override", {
                model = model,
                origin = pos.x + " " + pos.y + " " + pos.z,
                glowstate = 3,
                glowcolor = glow
            });
            
            // trigger_multiple: spawnflags 1=Clients, mins/maxs set pickup radius
            local trigger = SpawnEntityFromTable("trigger_multiple", {
                targetname = "lore_pickup_" + prop.GetEntityIndex(),
                origin = pos.x + " " + pos.y + " " + pos.z,
                spawnflags = 1,
                wait = 0
            });
            
            trigger.SetSize(Vector(-32,-32,-32), Vector(32,32,32));
            trigger.ValidateScriptScope();
            local scope = trigger.GetScriptScope();
            scope.LoreIndex <- loreIdx;
            scope.PropEnt <- prop;
            
            trigger.ConnectOutput("OnStartTouch", "OnTouchLore");
            
            scope.OnTouchLore <- function() {
                local player = activator;
                if (player && player.IsPlayer() && player.IsSurvivor()) {
                    local lore = ::GraveGainLore.Entries[LoreIndex];
                    
                    // Chat print (type 2) - persists, not a transient center message
                    local prefix = "\\x04[" + lore.rarity.toupper() + "] \\x01";
                    ClientPrint(player, 2, prefix + lore.title);
                    ClientPrint(player, 2, "\\x01" + lore.text.slice(0, 200));
                    
                    local snd = "ui/helpful_event_1.wav";
                    if (lore.rarity == "legendary") snd = "ui/stinger_l4d1_survivor_idled.wav";
                    EmitSoundOn(snd, player);
                    
                    PropEnt.Kill();
                    self.Kill();
                }
            }
        }
    }
}

function GraveGainLore::Precache() {
    foreach (rarity, mdl in Models) {
        PrecacheModel(mdl);
    }
    PrecacheSound("ui/helpful_event_1.wav");
    PrecacheSound("ui/stinger_l4d1_survivor_idled.wav");
}

__CollectEventCallbacks(GraveGainLore, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);

// Register hook
function GraveGainLore::OnGameEvent_infected_death(params) {
    ::GraveGainLore.OnInfectedDeath(params);
}
"""

with open(out_file, "w", encoding="utf-8") as f:
    f.write(vscript)

print(f"Generated {out_file} with {len(entries)} lore entries.")
