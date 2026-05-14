// GraveGain Melee Overhaul - coop.nut
// This file enables Scripted Mode in coop, unlocking AllowTakeDamage and HUD APIs.

printl("[GraveGain] coop.nut loaded - Scripted Mode active.");

IncludeScript("gravegain_melee_core");
IncludeScript("lore_system");

// Called by engine when map entities have spawned
function OnPostSpawn() {
    printl("[GraveGain] OnPostSpawn triggered.");
    if ("GraveGainLore" in getroottable()) ::GraveGainLore.Precache();
    if ("GraveGainMelee" in getroottable()) ::GraveGainMelee.Init();
}

function OnGameEvent_round_start(params) {
    if ("GraveGainMelee" in getroottable()) ::GraveGainMelee.Init();
}

// === DAMAGE HOOK - only works in Scripted Mode ===
function AllowTakeDamage(params) {
    if ("GraveGainMelee" in getroottable()) {
        return ::GraveGainMelee.OnTakeDamage(params);
    }
    return true;
}

__CollectEventCallbacks(getroottable(), "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
