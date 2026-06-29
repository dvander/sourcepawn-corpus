/**
 * ============================================================================
 *
 *  L4D2 Melee Damage Resistance
 *
 *  Description:
 *      Survivors (players and/or bots) who carry or equip a melee weapon
 *      receive a configurable percentage of damage resistance against ALL
 *      damage sources.
 *
 *  ConVars (auto-saved to cfg/sourcemod/l4d2_melee_resistance.cfg):
 *      l4d2_melee_resist_enabled       - Master on/off switch
 *      l4d2_melee_resist_amount        - Resistance percentage (0.0–1.0)
 *      l4d2_melee_resist_equipped_only - Only apply while melee is active
 *      l4d2_melee_resist_bots          - Apply to survivor bots
 *      l4d2_melee_resist_announce      - Chat hint when resistance activates
 *      l4d2_melee_resist_exclude_ff    - Exclude friendly-fire from reduction
 *
 *  Author  : BatoSaiX
 *  Version : 1.1.0
 *  Game    : Left 4 Dead 2
 *
 * ============================================================================
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// ---------------------------------------------------------------------------
// Plugin metadata
// ---------------------------------------------------------------------------
#define PLUGIN_VERSION  "1.1.0"
#define PLUGIN_NAME     "L4D2 Melee Damage Resistance"

public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = "BatoSaiX",
    description = "Survivors carrying a melee weapon gain damage resistance",
    version     = PLUGIN_VERSION,
    url         = ""
};

// ---------------------------------------------------------------------------
// ConVar handles
// ---------------------------------------------------------------------------
ConVar g_cvEnabled;           // Plugin master switch
ConVar g_cvResistAmount;      // Damage reduction factor  (0.0 – 1.0)
ConVar g_cvEquippedOnly;      // Require melee to be the active weapon
ConVar g_cvAffectBots;        // Apply to survivor bots
ConVar g_cvAnnounce;          // Notify player in chat when buff applies
ConVar g_cvExcludeFF;         // Skip friendly-fire damage

// ---------------------------------------------------------------------------
// Tracking: which clients have already received the "buff active" hint
// ---------------------------------------------------------------------------
bool g_bAnnounced[MAXPLAYERS + 1];

// ---------------------------------------------------------------------------
// OnPluginStart
// ---------------------------------------------------------------------------
public void OnPluginStart()
{
    // ---- Create ConVars ----
    g_cvEnabled = CreateConVar(
        "l4d2_melee_resist_enabled", "1",
        "Enable or disable the Melee Damage Resistance plugin.\n"
        ... "(1 = On, 0 = Off)",
        FCVAR_NOTIFY
    );

    g_cvResistAmount = CreateConVar(
        "l4d2_melee_resist_amount", "0.30",
        "Fraction of incoming damage to negate when a survivor holds/carries\n"
        ... "a melee weapon.  Range: 0.0 (no reduction) – 1.0 (immune).\n"
        ... "Default: 0.30 (30%% damage resistance)",
        FCVAR_NOTIFY,
        true, 0.0,
        true, 1.0
    );

    g_cvEquippedOnly = CreateConVar(
        "l4d2_melee_resist_equipped_only", "1",
        "0 = Resistance applies whenever a melee is in the survivor's\n"
        ... "    inventory (slot 1), even if not currently drawn.\n"
        ... "1 = Resistance only applies while the melee weapon is the\n"
        ... "    active (drawn) weapon.",
        FCVAR_NOTIFY
    );

    g_cvAffectBots = CreateConVar(
        "l4d2_melee_resist_bots", "1",
        "Apply damage resistance to AI survivor bots as well.\n"
        ... "(1 = Yes, 0 = No)",
        FCVAR_NOTIFY
    );

    g_cvAnnounce = CreateConVar(
        "l4d2_melee_resist_announce", "1",
        "Print a one-time chat hint to the survivor the first time their\n"
        ... "melee resistance activates each life.\n"
        ... "(1 = Yes, 0 = No)",
        FCVAR_NOTIFY
    );

    g_cvExcludeFF = CreateConVar(
        "l4d2_melee_resist_exclude_ff", "0",
        "Exclude friendly-fire damage from the resistance reduction.\n"
        ... "(1 = FF bypasses resistance, 0 = FF is also reduced)",
        FCVAR_NOTIFY
    );

    // ---- Auto-save config ----
    AutoExecConfig(true, "l4d2_melee_resistance");

    // ---- Version ConVar ----
    CreateConVar(
        "l4d2_melee_resist_version", PLUGIN_VERSION,
        PLUGIN_NAME ... " version",
        FCVAR_NOTIFY | FCVAR_DONTRECORD
    );

    // ---- Hook player_spawn once here, not per-client ----
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);

    // ---- Hook already-connected clients (late load support) ----
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
            HookClient(i);
    }
}

// ---------------------------------------------------------------------------
// Client hooks
// ---------------------------------------------------------------------------
public void OnClientPutInServer(int client)
{
    HookClient(client);
}

public void OnClientDisconnect(int client)
{
    // SDKHooks cleans up automatically on disconnect — no manual unhook needed.
    g_bAnnounced[client] = false;
}

// Called each time a survivor spawns (resets the chat hint flag)
public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && client <= MaxClients)
        g_bAnnounced[client] = false;
}

// ---------------------------------------------------------------------------
// Damage hook
// ---------------------------------------------------------------------------
public Action Hook_OnTakeDamage(
    int     victim,
    int    &attacker,
    int    &inflictor,
    float  &damage,
    int    &damagetype)
{
    // ---- Master switch ----
    if (!g_cvEnabled.BoolValue)
        return Plugin_Continue;

    // ---- Survivors only ----
    if (!IsValidSurvivor(victim))
        return Plugin_Continue;

    // ---- Bot filter ----
    if (IsFakeClient(victim) && !g_cvAffectBots.BoolValue)
        return Plugin_Continue;

    // ---- Friendly-fire exclusion ----
    if (g_cvExcludeFF.BoolValue && IsValidClient(attacker) && GetClientTeam(attacker) == 2)
        return Plugin_Continue;

    // ---- Melee check ----
    if (!SurvivorHasMelee(victim))
        return Plugin_Continue;

    // ---- Apply resistance ----
    float resist = g_cvResistAmount.FloatValue;
    damage *= (1.0 - resist);

    // ---- One-time chat announcement (human players only) ----
    if (!IsFakeClient(victim) && g_cvAnnounce.BoolValue && !g_bAnnounced[victim])
    {
        g_bAnnounced[victim] = true;
        PrintToChat(victim,
            "\x04[Melee Resist]\x01 Your melee weapon grants you \x05%.0f%%\x01 damage resistance!",
            resist * 100.0
        );
    }

    return Plugin_Changed;
}

// ---------------------------------------------------------------------------
// Helper – check if the survivor has (or is holding) a melee weapon
// ---------------------------------------------------------------------------
bool SurvivorHasMelee(int client)
{
    if (g_cvEquippedOnly.BoolValue)
    {
        // Must be holding the melee right now
        int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        return IsValidMeleeEntity(active);
    }
    else
    {
        // Melee is secondary slot (slot 1); pistols are also slot 1 but
        // have different classnames, so we just check the classname.
        int secondary = GetPlayerWeaponSlot(client, 1);
        return IsValidMeleeEntity(secondary);
    }
}

// ---------------------------------------------------------------------------
// Helper – verify an entity is a melee weapon
// ---------------------------------------------------------------------------
bool IsValidMeleeEntity(int entity)
{
    if (entity == -1 || !IsValidEntity(entity))
        return false;

    char classname[64];
    GetEntityClassname(entity, classname, sizeof(classname));

    // Regular melee weapons use "weapon_melee".
    // The chainsaw is a special case — it uses its own classname "weapon_chainsaw".
    return (
        StrContains(classname, "weapon_melee",    false) != -1 ||
        StrContains(classname, "weapon_chainsaw", false) != -1
    );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
void HookClient(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

bool IsValidSurvivor(int client)
{
    return (
        IsValidClient(client)
        && IsPlayerAlive(client)
        && GetClientTeam(client) == 2   // 2 = Survivors
    );
}
