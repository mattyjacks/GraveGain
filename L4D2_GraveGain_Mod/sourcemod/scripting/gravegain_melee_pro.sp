// =============================================================================
//  GraveGain Melee Pro - Complete Combat Overhaul
//  Version 3.0 | GraveGain Team | https://mattyjacks.com
//
//  FEATURES:
//   - Block / Parry / Shove stamina system
//   - Inferno Blast ultimate (charged by kills, 2s per kill, 120s passive)
//   - Hold F to fire when ultimate is ready
//   - Players spawn with one pistol + one melee weapon
//   - Hit-stop physics, brutal gore, HUD display
// =============================================================================

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION        "3.0 GraveGain"
#define WEBSITE_URL           "https://mattyjacks.com"

// === Stamina ===
#define STAMINA_MAX           5.0
#define STAMINA_REGEN         0.1    // Per 0.1s tick
#define COST_BLOCK            1.0
#define COST_SHOVE            1.5
#define PARRY_WINDOW          0.3

// === Ultimate: Inferno Blast ===
#define ULT_CHARGE_BASE       120.0  // Seconds to charge passively (2 minutes)
#define ULT_KILL_REDUCTION    2.0    // Seconds removed per kill
#define ULT_HOLD_TIME         0.5    // Seconds F must be held to fire
#define INFERNO_FIREBALL_DMG  80.0
#define INFERNO_AOE_RADIUS    304.0  // 10 feet in Hammer units
#define INFERNO_AOE_DMG_MAX   120.0
#define INFERNO_AOE_DMG_MIN   20.0
#define INFERNO_FLAME_DURATION 3.0
#define INFERNO_FLAME_INTERVAL 0.15
#define INFERNO_FLAME_RANGE   300.0
#define INFERNO_FLAME_DMG     12.0
#define INFERNO_FLAME_ANGLE   0.6    // ~53-degree forward cone (dot product)

// === Pistol weapon classnames (all count as "pistol slot") ===
// weapon_pistol, weapon_pistol_magnum, weapon_dual_pistol are all valid.
// We give weapon_pistol on spawn; player may swap freely.

// === Enemy Size Tiers ===
// Weights must sum to 100
#define SIZE_TINY_SCALE    0.60
#define SIZE_SMALL_SCALE   0.80
#define SIZE_NORMAL_SCALE  1.00
#define SIZE_BIG_SCALE     1.40
#define SIZE_GIANT_SCALE   1.80
// Weight table (cumulative): tiny=15, small=30, normal=65, big=85, giant=100
#define SIZE_W_TINY   15
#define SIZE_W_SMALL  30
#define SIZE_W_NORMAL 65
#define SIZE_W_BIG    85
// (giant is remainder)

// === HUD Layout ===
// g_hHudStamina  - bottom-left  : stamina pips
// g_hHudUltimate - bottom-center: ultimate charge bar
// g_hHudEvent    - upper-center : short flash event messages

// === Global State ===
float g_fStamina[MAXPLAYERS + 1];
bool  g_bIsBlocking[MAXPLAYERS + 1];
float g_fBlockStart[MAXPLAYERS + 1];
float g_fLastShove[MAXPLAYERS + 1];
bool  g_bAnimFrozen[MAXPLAYERS + 1];
float g_fAnimFreezeAt[MAXPLAYERS + 1];

// === Ultimate State ===
float g_fUltCharge[MAXPLAYERS + 1];    // Seconds remaining until ultimate ready (0 = READY)
bool  g_bFlashlightHeld[MAXPLAYERS + 1];
float g_fFlashlightHoldStart[MAXPLAYERS + 1];
bool  g_bUltArmed[MAXPLAYERS + 1];     // F held long enough - fire on release

// === HUD Event Flash ===
char  g_szEventMsg[MAXPLAYERS + 1][128]; // Current flash message
float g_fEventExpiry[MAXPLAYERS + 1];   // Engine time when flash clears

// === HUD Handles ===
Handle g_hHudStamina;   // Bottom-left: stamina (channel 1)
Handle g_hHudUltimate;  // Bottom-center: ultimate (channel 2)
Handle g_hHudEvent;     // Upper-center: event flash (channel 3)

public Plugin myinfo = 
{
    name = "GraveGain Melee Pro (Overhaul)",
    author = "GraveGain Team",
    description = "Complete AAA Combat Architecture in SourceMod",
    version = PLUGIN_VERSION,
    url = WEBSITE_URL
};

public void OnPluginStart()
{
    // Three independent HUD sync channels
    g_hHudStamina  = CreateHudSynchronizer();
    g_hHudUltimate = CreateHudSynchronizer();
    g_hHudEvent    = CreateHudSynchronizer();

    RegConsoleCmd("sm_gravegain", Command_Website, "Visit the GraveGain website");
    RegConsoleCmd("sm_lore",     Command_Website, "Read the GraveGain lore on our website");

    // Game events
    HookEvent("player_spawn",    Event_PlayerSpawn,   EventHookMode_Post);
    HookEvent("infected_death",  Event_InfectedDeath, EventHookMode_Post);
    HookEvent("witch_killed",    Event_WitchKilled,   EventHookMode_Post);
    HookEvent("tank_killed",     Event_TankKilled,    EventHookMode_Post);
    HookEvent("infected_spawn",  Event_InfectedSpawn, EventHookMode_Post);

    // Global 0.1s tick for Stamina, Ultimate charge, and HUD
    CreateTimer(0.1, Timer_UpdateLoop, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

    // Late load: hook already-connected clients
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
            OnClientPutInServer(i);
    }

    // Brutal Gore ConVars
    ConVar hCvar;
    if ((hCvar = FindConVar("z_dismemberment_limit"))         != null) hCvar.SetInt(100);
    if ((hCvar = FindConVar("z_wound_client_limit"))          != null) hCvar.SetInt(100);
    if ((hCvar = FindConVar("z_common_minimal_wound_force"))  != null) hCvar.SetFloat(1.0);

    PrecacheSound("ambient/gas/steam_loop_1.wav");
    PrecacheSound("physics/metal/metal_solid_impact_hard1.wav");
    PrecacheSound("physics/metal/metal_solid_impact_bullet1.wav");
    PrecacheSound("physics/glass/glass_sheet_break1.wav");
    PrecacheSound("ambient/fire/fire_small_02.wav");
    PrecacheSound("ambient/fire/gas_burst1.wav");
    PrecacheModel("models/props_junk/gascan001a.mdl");

    LogMessage("[GraveGain Pro] Plugin STARTED. Version %s", PLUGIN_VERSION);
}

// ─────────────────────────────────────────────────────────────────────────────
//  CLIENT INIT
// ─────────────────────────────────────────────────────────────────────────────

public void OnClientPutInServer(int client)
{
    g_fStamina[client]            = STAMINA_MAX;
    g_bIsBlocking[client]         = false;
    g_bAnimFrozen[client]         = false;
    g_fLastShove[client]          = 0.0;
    g_fUltCharge[client]          = ULT_CHARGE_BASE;
    g_bFlashlightHeld[client]     = false;
    g_fFlashlightHoldStart[client]= 0.0;
    g_bUltArmed[client]           = false;
    g_szEventMsg[client][0]       = '\0';
    g_fEventExpiry[client]        = 0.0;
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

// ─────────────────────────────────────────────────────────────────────────────
//  WEAPON LOADOUT ON SPAWN
// ─────────────────────────────────────────────────────────────────────────────

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
        return;

    // Delay one frame so the game has finished its own spawn setup
    DataPack dp = new DataPack();
    dp.WriteCell(GetClientUserId(client));
    CreateTimer(0.1, Timer_GiveLoadout, dp, TIMER_DATA_HNDL_CLOSE | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_GiveLoadout(Handle timer, DataPack dp)
{
    dp.Reset();
    int client = GetClientOfUserId(dp.ReadCell());
    if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Stop;

    // Reset ultimate charge on each respawn
    g_fUltCharge[client] = ULT_CHARGE_BASE;

    // Strip any existing primary weapons (rifles, shotguns, etc.)
    // Leave pistol slot and melee slot alone - we fill them below.
    for (int slot = 0; slot <= 4; slot++)
    {
        int wep = GetPlayerWeaponSlot(client, slot);
        if (wep != -1 && IsValidEntity(wep))
        {
            char cls[64];
            GetEntityClassname(wep, cls, sizeof(cls));
            // Only strip primary (slot 0) non-melee weapons
            if (slot == 0 && !StrEqual(cls, "weapon_melee"))
                RemovePlayerItem(client, wep);
        }
    }

    // Give pistol if player has no sidearm
    if (GetPlayerWeaponSlot(client, 1) == -1)
        GivePlayerItem(client, "weapon_pistol");

    // Give melee if player has no melee weapon
    if (GetPlayerWeaponSlot(client, 1) == -1 || GetPlayerWeaponSlot(client, 2) == -1)
    {
        // Check slot 1 for melee (L4D2 melee lives in slot 1 alongside pistol)
        bool hasMelee = false;
        for (int slot = 0; slot <= 4; slot++)
        {
            int wep = GetPlayerWeaponSlot(client, slot);
            if (wep == -1) continue;
            char cls[64];
            GetEntityClassname(wep, cls, sizeof(cls));
            if (StrEqual(cls, "weapon_melee"))
            {
                hasMelee = true;
                break;
            }
        }
        if (!hasMelee)
            GivePlayerItem(client, "weapon_bat");
    }

    FlashEvent(client, 4.0, "LOADOUT: Pistol + Bat | Hold F when ULTIMATE is READY");
    return Plugin_Stop;
}

// ─────────────────────────────────────────────────────────────────────────────
//  KILL EVENTS - Reduce ultimate charge
// ─────────────────────────────────────────────────────────────────────────────

public void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if (attacker <= 0 || !IsClientInGame(attacker) || GetClientTeam(attacker) != 2)
        return;
    ReduceUltCharge(attacker, ULT_KILL_REDUCTION);
}

public void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    if (attacker <= 0 || !IsClientInGame(attacker) || GetClientTeam(attacker) != 2)
        return;
    ReduceUltCharge(attacker, ULT_KILL_REDUCTION * 5.0); // Witch worth 5 kills
}

public void Event_TankKilled(Event event, const char[] name, bool dontBroadcast)
{
    // Tank kill credited to all survivors
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
            ReduceUltCharge(i, ULT_KILL_REDUCTION * 10.0); // Tank worth 10 kills each
    }
}

void ReduceUltCharge(int client, float amount)
{
    g_fUltCharge[client] -= amount;
    if (g_fUltCharge[client] < 0.0)
        g_fUltCharge[client] = 0.0;
}

// ─────────────────────────────────────────────────────────────────────────────
//  ENEMY SIZE VARIATION
// ─────────────────────────────────────────────────────────────────────────────

public void Event_InfectedSpawn(Event event, const char[] name, bool dontBroadcast)
{
    // Defer 1 tick so the entity is fully initialised before we read/write properties
    CreateTimer(0.05, Timer_ScaleInfected, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ScaleInfected(Handle timer)
{
    // Scan all infected entities that still have the default scale (1.0)
    // This correctly handles common infected which are not "clients"
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "infected")) != -1)
    {
        if (!IsValidEntity(ent)) continue;
        float curScale = GetEntPropFloat(ent, Prop_Send, "m_flModelScale");
        if (curScale != 1.0) continue; // already sized by us
        ApplyInfectedSize(ent);
    }
    return Plugin_Stop;
}

void ApplyInfectedSize(int ent)
{
    int roll = GetRandomInt(1, 100);
    float scale;
    float hpMult;

    if (roll <= SIZE_W_TINY)
    {
        scale  = SIZE_TINY_SCALE;
        hpMult = 0.5;
    }
    else if (roll <= SIZE_W_SMALL)
    {
        scale  = SIZE_SMALL_SCALE;
        hpMult = 0.75;
    }
    else if (roll <= SIZE_W_NORMAL)
    {
        scale  = SIZE_NORMAL_SCALE;
        hpMult = 1.0;
    }
    else if (roll <= SIZE_W_BIG)
    {
        scale  = SIZE_BIG_SCALE;
        hpMult = 1.6;
    }
    else
    {
        scale  = SIZE_GIANT_SCALE;
        hpMult = 2.5;
    }

    SetEntPropFloat(ent, Prop_Send, "m_flModelScale", scale);

    // Scale health proportionally
    int baseHp = GetEntProp(ent, Prop_Data, "m_iHealth");
    if (baseHp <= 0) baseHp = 50; // fallback default
    int newHp = RoundToNearest(float(baseHp) * hpMult);
    if (newHp < 1) newHp = 1;
    SetEntProp(ent, Prop_Data, "m_iHealth", newHp);
    SetEntProp(ent, Prop_Data, "m_iMaxHealth", newHp);
}

// ─────────────────────────────────────────────────────────────────────────────
//  HUD EVENT FLASH HELPER
// ─────────────────────────────────────────────────────────────────────────────

void FlashEvent(int client, float duration, const char[] msg)
{
    if (client <= 0 || client > MaxClients || !IsClientInGame(client)) return;
    Format(g_szEventMsg[client], sizeof(g_szEventMsg[]), "%s", msg);
    g_fEventExpiry[client] = GetEngineTime() + duration;
}

// ─────────────────────────────────────────────────────────────────────────────
//  THE FUNNEL
// ─────────────────────────────────────────────────────────────────────────────

public Action Command_Website(int client, int args)
{
    if (client == 0) return Plugin_Handled;
    ShowMOTDPanel(client, "GraveGain Lore & Updates", WEBSITE_URL, MOTDPANEL_TYPE_URL);
    return Plugin_Handled;
}

// ─────────────────────────────────────────────────────────────────────────────
//  INPUT INTERCEPTION
// ─────────────────────────────────────────────────────────────────────────────

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if (!IsPlayerAlive(client) || GetClientTeam(client) != 2)
        return Plugin_Continue;

    int activeWep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (activeWep <= 0 || !IsValidEntity(activeWep))
    {
        g_bIsBlocking[client] = false;
        return Plugin_Continue;
    }

    bool changed = false;

    // =========================================================================
    //  RIGHT CLICK = BLOCK
    // =========================================================================
    if (buttons & IN_ATTACK2)
    {
        if (!g_bIsBlocking[client])
        {
            // BLOCK START: pass IN_ATTACK2 this tick so animation starts naturally
            g_bIsBlocking[client]      = true;
            g_fBlockStart[client]      = GetEngineTime();
            g_bAnimFrozen[client]      = false;
            g_fAnimFreezeAt[client]    = GetEngineTime() + 0.12;
            FlashEvent(client, 1.5, ">> BLOCKING <<");
        }
        else
        {
            // BLOCK HOLD: suppress input so no fake shots occur
            buttons &= ~IN_ATTACK2;
            changed = true;

            SetEntPropFloat(activeWep, Prop_Send, "m_flNextPrimaryAttack",   GetGameTime() + 0.5);
            SetEntPropFloat(activeWep, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 0.5);

            // Freeze viewmodel at animation midpoint
            if (!g_bAnimFrozen[client] && GetEngineTime() >= g_fAnimFreezeAt[client])
            {
                int vm = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
                if (vm > 0 && IsValidEntity(vm))
                    SetEntPropFloat(vm, Prop_Send, "m_flPlaybackRate", 0.0);
                g_bAnimFrozen[client] = true;
            }

            // Left Click while blocking = SHOVE
            if (buttons & IN_ATTACK)
            {
                buttons &= ~IN_ATTACK;
                int vm = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
                if (vm > 0 && IsValidEntity(vm))
                    SetEntPropFloat(vm, Prop_Send, "m_flPlaybackRate", 1.0);
                g_bAnimFrozen[client] = false;
                DoCustomShove(client);
                g_fAnimFreezeAt[client] = GetEngineTime() + 0.3;
            }
        }
    }
    else
    {
        if (g_bIsBlocking[client])
        {
            // BLOCK END: restore animation
            int vm = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
            if (vm > 0 && IsValidEntity(vm))
                SetEntPropFloat(vm, Prop_Send, "m_flPlaybackRate", 1.0);
            g_bAnimFrozen[client] = false;
            FlashEvent(client, 0.8, "Block released");
        }
        g_bIsBlocking[client] = false;
    }

    // =========================================================================
    //  F KEY = ULTIMATE (Hold F when READY to fire Inferno Blast)
    // =========================================================================
    if (buttons & IN_FLASHLIGHT)
    {
        bool ultReady = (g_fUltCharge[client] <= 0.0);

        if (!g_bFlashlightHeld[client])
        {
            // F just pressed
            g_bFlashlightHeld[client]      = true;
            g_fFlashlightHoldStart[client] = GetEngineTime();
            g_bUltArmed[client]            = false;
        }

        float holdTime = GetEngineTime() - g_fFlashlightHoldStart[client];

        if (ultReady && holdTime >= ULT_HOLD_TIME)
        {
            // Suppress flashlight toggle while arming
            buttons &= ~IN_FLASHLIGHT;
            changed = true;

            if (!g_bUltArmed[client])
            {
                g_bUltArmed[client] = true;
                FlashEvent(client, 3.0, "!! RELEASE F !! - INFERNO BLAST ARMED");
            }
        }
        // If not ready or hold too short: IN_FLASHLIGHT passes = normal flashlight tap
    }
    else
    {
        if (g_bFlashlightHeld[client])
        {
            // F released
            if (g_bUltArmed[client])
                DoInfernoBlast(client);

            g_bFlashlightHeld[client] = false;
            g_bUltArmed[client]       = false;
        }
    }

    return changed ? Plugin_Changed : Plugin_Continue;
}

// ─────────────────────────────────────────────────────────────────────────────
//  CUSTOM SHOVE & PHYSICS
// ─────────────────────────────────────────────────────────────────────────────

void DoCustomShove(int client)
{
    if (GetEngineTime() - g_fLastShove[client] < 0.8) return;
    if (g_fStamina[client] < COST_SHOVE) return;
    
    g_fStamina[client] -= COST_SHOVE;
    g_fLastShove[client] = GetEngineTime();
    
    EmitSoundToAll("physics/metal/metal_solid_impact_hard1.wav", client);
    
    // Camera Punch
    float punch[3] = {-4.0, 0.0, 0.0};
    SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", punch);

    // Physical Push Sweep
    float eyePos[3], fwd[3];
    GetClientEyePosition(client, eyePos);
    GetClientEyeAngles(client, fwd);
    GetAngleVectors(fwd, fwd, NULL_VECTOR, NULL_VECTOR);

    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "infected")) != -1)
    {
        PushEntity(ent, eyePos, fwd, 600.0); // Medium-Heavy shove push
    }
    
    for (int i = 1; i <= MaxClients; i++) 
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i)) 
        {
            PushEntity(i, eyePos, fwd, 400.0);
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//  INFERNO BLAST ULTIMATE
// ─────────────────────────────────────────────────────────────────────────────

void DoInfernoBlast(int client)
{
    // Guard: should only be called when charge is ready, but double-check
    if (g_fUltCharge[client] > 0.0)
    {
        FlashEvent(client, 2.0, "ULTIMATE NOT READY");
        return;
    }

    // Reset charge to full - player must earn it again
    g_fUltCharge[client] = ULT_CHARGE_BASE;

    float eyePos[3], eyeAngles[3], fwd[3];
    GetClientEyePosition(client, eyePos);
    GetClientEyeAngles(client, eyeAngles);
    GetAngleVectors(eyeAngles, fwd, NULL_VECTOR, NULL_VECTOR);

    char blastMsg[128];
    Format(blastMsg, sizeof(blastMsg), "!! INFERNO BLAST !! - %N", client);
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
            FlashEvent(i, 3.5, blastMsg);
    }
    EmitSoundToAll("ambient/fire/fire_small_02.wav", client);

    // --- Phase 1: Fireball launch ---
    float fireballPos[3];
    fireballPos[0] = eyePos[0] + fwd[0] * 32.0;
    fireballPos[1] = eyePos[1] + fwd[1] * 32.0;
    fireballPos[2] = eyePos[2] + fwd[2] * 32.0;

    int fireball = CreateEntityByName("prop_physics_override");
    if (fireball != -1)
    {
        DispatchKeyValue(fireball, "model", "models/props_junk/gascan001a.mdl");
        DispatchKeyValue(fireball, "rendermode", "5");
        DispatchKeyValue(fireball, "rendercolor", "255 80 0");
        DispatchKeyValue(fireball, "renderamt", "220");
        DispatchSpawn(fireball);
        TeleportEntity(fireball, fireballPos, eyeAngles, NULL_VECTOR);

        // Launch it forward
        float launchVel[3];
        launchVel[0] = fwd[0] * 1800.0;
        launchVel[1] = fwd[1] * 1800.0;
        launchVel[2] = fwd[2] * 1800.0;
        TeleportEntity(fireball, NULL_VECTOR, NULL_VECTOR, launchVel);

        // Ignite the prop visually
        int fire = CreateEntityByName("env_fire");
        if (fire != -1)
        {
            char sPropName[32];
            Format(sPropName, sizeof(sPropName), "gg_fireball_%d", fireball);
            DispatchKeyValue(fireball, "targetname", sPropName);
            DispatchKeyValue(fire, "target", sPropName);
            DispatchKeyValue(fire, "firesize", "3");
            DispatchKeyValue(fire, "firetype", "0");
            DispatchKeyValue(fire, "ignitionpoint", "32.0");
            DispatchSpawn(fire);
            AcceptEntityInput(fire, "StartFire");
        }

        // Schedule fireball impact check and explosion
        // NOTE: With CreateDataTimer + TIMER_REPEAT, write pack BEFORE creating timer.
        // The pack is auto-reset to position 0 before each callback invocation.
        DataPack fbPack = new DataPack();
        fbPack.WriteCell(GetClientUserId(client));
        fbPack.WriteCell(EntIndexToEntRef(fireball));
        fbPack.WriteFloat(GetEngineTime() + 2.0); // Max travel time
        CreateTimer(0.05, Timer_FireballTravel, fbPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
    }

    // --- Phase 2: AoE ignite within 10 feet ---
    InfernoAoE(client, eyePos);

    // --- Phase 3: Flamethrower spray for 3 seconds ---
    DataPack flamePack = new DataPack();
    flamePack.WriteCell(GetClientUserId(client));
    flamePack.WriteFloat(GetEngineTime() + INFERNO_FLAME_DURATION);
    CreateTimer(INFERNO_FLAME_INTERVAL, Timer_FlamethrowerTick, flamePack,
        TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
}

void InfernoAoE(int client, float origin[3])
{
    // Ignite and damage all infected/special within INFERNO_AOE_RADIUS
    // Does NOT harm team 2 (survivors)
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "infected")) != -1)
    {
        if (!IsValidEntity(ent)) continue;
        float tPos[3];
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", tPos);
        float dist = GetVectorDistance(origin, tPos);
        if (dist <= INFERNO_AOE_RADIUS)
        {
            // Inverse distance damage falloff
            float t = 1.0 - (dist / INFERNO_AOE_RADIUS);
            float dmg = INFERNO_AOE_DMG_MIN + (INFERNO_AOE_DMG_MAX - INFERNO_AOE_DMG_MIN) * t;
            SDKHooks_TakeDamage(ent, client, client, dmg, DMG_BURN);

            // Ignite the entity
            int fire = CreateEntityByName("env_fire");
            if (fire != -1)
            {
                DispatchKeyValue(fire, "firesize", "2");
                DispatchKeyValue(fire, "firetype", "0");
                DispatchKeyValue(fire, "ignitionpoint", "32.0");
                DispatchSpawn(fire);
                TeleportEntity(fire, tPos, NULL_VECTOR, NULL_VECTOR);
                AcceptEntityInput(fire, "StartFire");
                // Auto-kill fire after 4 seconds
                DataPack killPack = new DataPack();
                killPack.WriteCell(EntIndexToEntRef(fire));
                CreateTimer(4.0, Timer_KillEntity, killPack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
            }
        }
    }
    // Also affect special infected (witch, tank, etc.)
    int special = -1;
    while ((special = FindEntityByClassname(special, "witch")) != -1)
    {
        if (!IsValidEntity(special)) continue;
        float tPos[3];
        GetEntPropVector(special, Prop_Data, "m_vecOrigin", tPos);
        float dist = GetVectorDistance(origin, tPos);
        if (dist <= INFERNO_AOE_RADIUS)
        {
            float t = 1.0 - (dist / INFERNO_AOE_RADIUS);
            float dmg = INFERNO_AOE_DMG_MIN + (INFERNO_AOE_DMG_MAX - INFERNO_AOE_DMG_MIN) * t;
            SDKHooks_TakeDamage(special, client, client, dmg, DMG_BURN);
        }
    }
}

public Action Timer_FlamethrowerTick(Handle timer, DataPack pack)
{
    pack.Reset();
    int userId = pack.ReadCell();
    float endTime = pack.ReadFloat();
    int client = GetClientOfUserId(userId);

    if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Stop;
    if (GetEngineTime() >= endTime)
        return Plugin_Stop;

    float eyePos[3], eyeAngles[3], fwd[3];
    GetClientEyePosition(client, eyePos);
    GetClientEyeAngles(client, eyeAngles);
    GetAngleVectors(eyeAngles, fwd, NULL_VECTOR, NULL_VECTOR);

    EmitSoundToClient(client, "ambient/fire/fire_small_02.wav", client, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);

    // Spawn a small fire particle at muzzle for visual feedback
    int fx = CreateEntityByName("env_fire");
    if (fx != -1)
    {
        float muzzle[3];
        muzzle[0] = eyePos[0] + fwd[0] * 48.0;
        muzzle[1] = eyePos[1] + fwd[1] * 48.0;
        muzzle[2] = eyePos[2] + fwd[2] * 48.0;
        DispatchKeyValue(fx, "firesize", "1");
        DispatchKeyValue(fx, "firetype", "0");
        DispatchKeyValue(fx, "ignitionpoint", "1.0");
        DispatchSpawn(fx);
        TeleportEntity(fx, muzzle, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(fx, "StartFire");
        DataPack killPack = new DataPack();
        killPack.WriteCell(EntIndexToEntRef(fx));
        CreateTimer(0.3, Timer_KillEntity, killPack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
    }

    // Damage all infected in flamethrower cone - NO team 2 damage
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "infected")) != -1)
    {
        if (!IsValidEntity(ent)) continue;
        float tPos[3];
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", tPos);
        tPos[2] += 30.0;
        float dir[3];
        MakeVectorFromPoints(eyePos, tPos, dir);
        float dist = GetVectorLength(dir);
        if (dist > INFERNO_FLAME_RANGE) continue;
        NormalizeVector(dir, dir);
        if (GetVectorDotProduct(dir, fwd) < INFERNO_FLAME_ANGLE) continue;
        SDKHooks_TakeDamage(ent, client, client, INFERNO_FLAME_DMG, DMG_BURN);
    }

    // Also hit witch in cone
    int w = -1;
    while ((w = FindEntityByClassname(w, "witch")) != -1)
    {
        if (!IsValidEntity(w)) continue;
        float tPos[3];
        GetEntPropVector(w, Prop_Data, "m_vecOrigin", tPos);
        float dir[3];
        MakeVectorFromPoints(eyePos, tPos, dir);
        float dist = GetVectorLength(dir);
        if (dist > INFERNO_FLAME_RANGE) continue;
        NormalizeVector(dir, dir);
        if (GetVectorDotProduct(dir, fwd) < INFERNO_FLAME_ANGLE) continue;
        SDKHooks_TakeDamage(w, client, client, INFERNO_FLAME_DMG, DMG_BURN);
    }

    return Plugin_Continue;
}

public Action Timer_FireballTravel(Handle timer, DataPack pack)
{
    pack.Reset();
    int client    = GetClientOfUserId(pack.ReadCell());
    int fbRef     = pack.ReadCell();
    float maxTime = pack.ReadFloat();

    int fireball = EntRefToEntIndex(fbRef);

    // Fireball gone or timed out - explode
    if (fireball == -1 || !IsValidEntity(fireball) || GetEngineTime() >= maxTime)
    {
        if (fireball != -1 && IsValidEntity(fireball))
        {
            float pos[3];
            GetEntPropVector(fireball, Prop_Data, "m_vecOrigin", pos);
            AcceptEntityInput(fireball, "Kill");
            if (client > 0 && IsClientInGame(client))
                FireballExplode(client, pos);
        }
        return Plugin_Stop;
    }

    // Check if fireball is near an enemy
    float fbPos[3];
    GetEntPropVector(fireball, Prop_Data, "m_vecOrigin", fbPos);

    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "infected")) != -1)
    {
        if (!IsValidEntity(ent)) continue;
        float tPos[3];
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", tPos);
        if (GetVectorDistance(fbPos, tPos) < 80.0)
        {
            // Hit! Explode here
            AcceptEntityInput(fireball, "Kill");
            if (client > 0 && IsClientInGame(client))
            {
                SDKHooks_TakeDamage(ent, client, client, INFERNO_FIREBALL_DMG, DMG_BURN | DMG_BLAST);
                FireballExplode(client, fbPos);
            }
            return Plugin_Stop;
        }
    }

    return Plugin_Continue;
}

void FireballExplode(int client, float pos[3])
{
    EmitSoundToAll("ambient/fire/gas_burst1.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO,
        SNDLEVEL_GUNFIRE, SND_NOFLAGS, 1.0, PITCHCON_NORMAL, _, pos);

    // Blast visual: spawn several env_fires in a burst pattern
    float offsets[5][3] = { {0.0,0.0,0.0}, {40.0,0.0,0.0}, {-40.0,0.0,0.0}, {0.0,40.0,0.0}, {0.0,-40.0,0.0} };
    for (int i = 0; i < 5; i++)
    {
        int fire = CreateEntityByName("env_fire");
        if (fire == -1) continue;
        float fpos[3];
        fpos[0] = pos[0] + offsets[i][0];
        fpos[1] = pos[1] + offsets[i][1];
        fpos[2] = pos[2] + offsets[i][2];
        DispatchKeyValue(fire, "firesize", "4");
        DispatchKeyValue(fire, "firetype", "0");
        DispatchKeyValue(fire, "ignitionpoint", "1.0");
        DispatchSpawn(fire);
        TeleportEntity(fire, fpos, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(fire, "StartFire");
        DataPack killPack = new DataPack();
        killPack.WriteCell(EntIndexToEntRef(fire));
        CreateTimer(3.0, Timer_KillEntity, killPack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
    }

    // Damage + ignite all infected near explosion
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "infected")) != -1)
    {
        if (!IsValidEntity(ent)) continue;
        float tPos[3];
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", tPos);
        float dist = GetVectorDistance(pos, tPos);
        if (dist <= 200.0)
        {
            float t = 1.0 - (dist / 200.0);
            float dmg = 20.0 + 60.0 * t;
            SDKHooks_TakeDamage(ent, client, client, dmg, DMG_BURN | DMG_BLAST);
        }
    }
}

public Action Timer_KillEntity(Handle timer, DataPack pack)
{
    pack.Reset();
    int ref = pack.ReadCell();
    int ent = EntRefToEntIndex(ref);
    if (ent != -1 && IsValidEntity(ent))
        AcceptEntityInput(ent, "Kill");
    return Plugin_Stop;
}

void PushEntity(int target, float eyePos[3], float fwd[3], float pushForce)
{
    float tPos[3], dir[3];
    GetEntPropVector(target, Prop_Data, "m_vecOrigin", tPos);
    tPos[2] += 30.0; // center mass

    MakeVectorFromPoints(eyePos, tPos, dir);
    NormalizeVector(dir, dir);
    
    if (GetVectorDotProduct(dir, fwd) > 0.4 && GetVectorDistance(eyePos, tPos) < 160.0)
    {
        ScaleVector(dir, pushForce);
        dir[2] += 120.0; // lift them off their feet
        TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, dir); // Forceful physics launch
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//  COMBAT LOGIC: Damage Negation, Parry, and Hit-Stop Physics
// ─────────────────────────────────────────────────────────────────────────────

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    // === DEFENSE (Blocking/Parrying) ===
    if (victim > 0 && victim <= MaxClients && g_bIsBlocking[victim])
    {
        if (GetEngineTime() - g_fBlockStart[victim] <= PARRY_WINDOW)
        {
            // PARRY
            EmitSoundToAll("physics/metal/metal_solid_impact_bullet1.wav", victim);
            if (attacker > 0 && attacker <= MaxClients)
            {
                float dir[3] = {0.0, 0.0, 300.0};
                TeleportEntity(attacker, NULL_VECTOR, NULL_VECTOR, dir); // Stagger
            }
            damage = 0.0;
            return Plugin_Changed;
        }
        else if (g_fStamina[victim] >= COST_BLOCK)
        {
            // NORMAL BLOCK
            g_fStamina[victim] -= COST_BLOCK;
            EmitSoundToAll("physics/metal/metal_solid_impact_hard1.wav", victim);
            damage = 0.0;
            return Plugin_Changed;
        }
        else
        {
            // GUARD BREAK
            g_bIsBlocking[victim] = false;
            EmitSoundToAll("physics/glass/glass_sheet_break1.wav", victim);
            return Plugin_Continue;
        }
    }

    // === OFFENSE (Hit-Stop and Medium Physics Push) ===
    if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
    {
        char weapon[64];
        GetClientWeapon(attacker, weapon, sizeof(weapon));
        
        if (StrEqual(weapon, "weapon_melee"))
        {
            // HIT-STOP CRUNCH
            SetEntPropFloat(victim, Prop_Send, "m_flPlaybackRate", 0.0);
            SetEntPropFloat(attacker, Prop_Send, "m_flPlaybackRate", 0.0);
            
            DataPack pack = new DataPack();
            pack.WriteCell(GetClientUserId(victim));
            pack.WriteCell(GetClientUserId(attacker));
            CreateTimer(0.05, Timer_Unfreeze, pack, TIMER_DATA_HNDL_CLOSE);
            
            // MEDIUM PHYSICS SWING PUSH
            float pushDir[3];
            float aPos[3], vPos[3];
            GetClientAbsOrigin(attacker, aPos);
            GetEntPropVector(victim, Prop_Data, "m_vecOrigin", vPos);
            MakeVectorFromPoints(aPos, vPos, pushDir);
            NormalizeVector(pushDir, pushDir);
            ScaleVector(pushDir, 350.0); // Medium Physics force
            pushDir[2] = 100.0;
            
            TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, pushDir); // Forceful physics
        }

        // === BRUTAL GORE ===
        damagetype |= DMG_BLAST;
        damagetype |= DMG_CRUSH;
        damage *= 1.5; 

        // Visual Carnage: Spawn blood particles manually
        float vPos[3];
        GetEntPropVector(victim, Prop_Data, "m_vecOrigin", vPos);
        vPos[2] += 45.0; // Chest height
        
        TE_Start("Blood Sprite");
        TE_WriteVector("m_vecOrigin", vPos);
        TE_WriteVector("m_vecDirection", view_as<float>({0.0, 0.0, 1.0}));
        TE_WriteNum("m_nRGBA[0]", 180);
        TE_WriteNum("m_nRGBA[1]", 0);
        TE_WriteNum("m_nRGBA[2]", 0);
        TE_WriteNum("m_nRGBA[3]", 255);
        TE_WriteNum("m_nDoffset", 5);
        TE_WriteNum("m_nSize", 10);
        TE_SendToAll();
    }
    
    return Plugin_Continue;
}

public Action Timer_Unfreeze(Handle timer, DataPack pack)
{
    pack.Reset();
    int victim = GetClientOfUserId(pack.ReadCell());
    int attacker = GetClientOfUserId(pack.ReadCell());
    
    if (victim > 0 && IsClientInGame(victim)) SetEntPropFloat(victim, Prop_Send, "m_flPlaybackRate", 1.0);
    if (attacker > 0 && IsClientInGame(attacker)) SetEntPropFloat(attacker, Prop_Send, "m_flPlaybackRate", 1.0);
    
    return Plugin_Stop;
}

// ─────────────────────────────────────────────────────────────────────────────
//  STAMINA TICK, ULTIMATE PASSIVE CHARGE & ADVANCED HUD RENDER
//
//  Layout (approximate screen positions):
//   [0.02, 0.80]  STAMINA channel  - bottom-left
//   [0.35, 0.90]  ULTIMATE channel - bottom-center
//   [0.20, 0.10]  EVENT channel    - upper-center (flash messages)
// ─────────────────────────────────────────────────────────────────────────────

public Action Timer_UpdateLoop(Handle timer)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2)
            continue;

        // ── Stamina regen ──────────────────────────────────────────────────
        if (!g_bIsBlocking[i] && g_fStamina[i] < STAMINA_MAX)
        {
            g_fStamina[i] += STAMINA_REGEN;
            if (g_fStamina[i] > STAMINA_MAX)
                g_fStamina[i] = STAMINA_MAX;
        }

        // ── Passive ultimate charge decay ──────────────────────────────────
        if (g_fUltCharge[i] > 0.0)
        {
            g_fUltCharge[i] -= 0.1;
            if (g_fUltCharge[i] < 0.0)
                g_fUltCharge[i] = 0.0;

            if (g_fUltCharge[i] <= 0.0)
                FlashEvent(i, 3.0, "** ULTIMATE READY ** Hold F to arm!");
        }

        float now = GetEngineTime();

        // ══════════════════════════════════════════════════════════════════
        //  HUD CHANNEL 1 - STAMINA  (bottom-left, x=0.02 y=0.80)
        //  White text, held for 0.2s (refreshed every 0.1s tick)
        // ══════════════════════════════════════════════════════════════════
        {
            // Build visual pip bar:  [|||  ] style, 20 chars wide
            int filled = RoundToFloor(g_fStamina[i] / STAMINA_MAX * 20.0);
            char bar[32];
            bar[0] = '\0';
            for (int p = 0; p < 20; p++)
                StrCat(bar, sizeof(bar), (p < filled) ? "|" : ".");

            char stateStr[24];
            if (g_bIsBlocking[i])
            {
                if (GetEngineTime() - g_fBlockStart[i] <= PARRY_WINDOW)
                    Format(stateStr, sizeof(stateStr), " [PARRY!]");
                else
                    Format(stateStr, sizeof(stateStr), " [BLOCKING]");
            }
            else
                stateStr[0] = '\0';

            // Colour: green when full, yellow mid, red low
            int r, g_col, b;
            float ratio = g_fStamina[i] / STAMINA_MAX;
            if (ratio > 0.6)      { r = 80;  g_col = 220; b = 80;  }
            else if (ratio > 0.3) { r = 220; g_col = 180; b = 30;  }
            else                  { r = 240; g_col = 40;  b = 40;  }

            SetHudTextParams(0.02, 0.80, 0.2, r, g_col, b, 255, 0, 0.0, 0.0, 0.0);
            ShowSyncHudText(i, g_hHudStamina,
                "STAMINA [%s]%s\n%.1f / %.1f",
                bar, stateStr, g_fStamina[i], STAMINA_MAX);
        }

        // ══════════════════════════════════════════════════════════════════
        //  HUD CHANNEL 2 - ULTIMATE  (bottom-center, x=0.30 y=0.87)
        //  Colour-coded by state
        // ══════════════════════════════════════════════════════════════════
        {
            char ultBar[32];
            ultBar[0] = '\0';

            int r, g_col, b;
            char ultLabel[64];

            if (g_fUltCharge[i] > 0.0)
            {
                // Charging - show fill bar (inverted: 0s = full, BASE = empty)
                float pct = 1.0 - (g_fUltCharge[i] / ULT_CHARGE_BASE);
                int filled = RoundToFloor(pct * 20.0);
                for (int p = 0; p < 20; p++)
                    StrCat(ultBar, sizeof(ultBar), (p < filled) ? "#" : "-");

                r = 180; g_col = 100; b = 30;
                Format(ultLabel, sizeof(ultLabel),
                    "INFERNO BLAST [%s] %.0fs",
                    ultBar, g_fUltCharge[i]);
            }
            else if (g_bUltArmed[i])
            {
                for (int p = 0; p < 20; p++) StrCat(ultBar, sizeof(ultBar), "!");
                r = 255; g_col = 50; b = 0;
                Format(ultLabel, sizeof(ultLabel),
                    "!! RELEASE F !! [%s]", ultBar);
            }
            else
            {
                for (int p = 0; p < 20; p++) StrCat(ultBar, sizeof(ultBar), "#");
                r = 255; g_col = 200; b = 0;
                Format(ultLabel, sizeof(ultLabel),
                    "INFERNO BLAST [%s] READY - Hold F", ultBar);
            }

            SetHudTextParams(0.30, 0.87, 0.2, r, g_col, b, 255, 0, 0.0, 0.0, 0.0);
            ShowSyncHudText(i, g_hHudUltimate, "%s", ultLabel);
        }

        // ══════════════════════════════════════════════════════════════════
        //  HUD CHANNEL 3 - EVENT FLASH  (upper-center, x=0.25 y=0.08)
        //  Short-lived messages for blocking, arming, blasting, etc.
        // ══════════════════════════════════════════════════════════════════
        if (g_szEventMsg[i][0] != '\0')
        {
            if (now < g_fEventExpiry[i])
            {
                // Fade alpha based on remaining time (last 0.5s fades out)
                float remaining = g_fEventExpiry[i] - now;
                int alpha = (remaining < 0.5) ? RoundToFloor(remaining / 0.5 * 255.0) : 255;

                SetHudTextParams(0.25, 0.08, 0.15, 255, 220, 60, alpha, 0, 0.0, 0.0, 0.0);
                ShowSyncHudText(i, g_hHudEvent, "-- %s --", g_szEventMsg[i]);
            }
            else
            {
                // Expired - clear
                g_szEventMsg[i][0] = '\0';
                ClearSyncHud(i, g_hHudEvent);
            }
        }

        (void)now;
    }
    return Plugin_Continue;
}
