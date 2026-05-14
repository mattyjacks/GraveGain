// GraveGain Addon - director_base_addon.nut
// This loads alongside coop.nut. Its job is just to ensure scripts are included.
// The heavy lifting (AllowTakeDamage, HUD) is done via coop.nut (Scripted Mode).

printl("[GraveGain] director_base_addon.nut loaded.");

IncludeScript("gravegain_melee_core");
IncludeScript("lore_system");

// director_base_addon doesn't get OnPostSpawn - that's handled by coop.nut.
// But if coop.nut isn't loaded (non-coop mode), we bootstrap here:
function OnPostSpawn() {
    if ("GraveGainLore" in getroottable()) ::GraveGainLore.Precache();
    if ("GraveGainMelee" in getroottable()) ::GraveGainMelee.Init();
}

function OnGameEvent_round_start(params) {
    if ("GraveGainMelee" in getroottable()) ::GraveGainMelee.Init();
}

__CollectEventCallbacks(getroottable(), "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
