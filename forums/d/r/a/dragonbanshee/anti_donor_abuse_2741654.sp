#include <sdkhooks>
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define SOUND_SAPPER_NOISE "weapons/sapper_timer.wav"
#define SOUND_SAPPER_PLANT "weapons/sapper_plant.wav"

//#define DEBUG
//#define DEBUG_CVAR

/*
 * Convars
 */
Handle g_hCvarHealing;
Handle g_hCvarDamage;
Handle g_hCvarSapper;
Handle g_hCvarAirblast;

int g_CvarHealing;
int g_CvarDamage;
int g_CvarSapper;
int g_CvarAirblast;

#define DISABLED 0

#define HEALING_GMODE  1
#define HEALING_RESIZE 2
#define HEALING_MAX    HEALING_GMODE + HEALING_RESIZE

#define DMG_RESIZE 1
#define DMG_KART   2
#define DMG_GMODE  4
#define DMG_PLAYER 8
#define DMG_BLD    16
#define DMG_MAX    DMG_RESIZE + DMG_KART + DMG_GMODE + DMG_PLAYER + DMG_BLD

#define SAPPER_RESIZE 1
#define SAPPER_GMODE  2
#define SAPPER_MAX    SAPPER_RESIZE + SAPPER_GMODE

#define AIRBLAST_RESIZE 1
#define AIRBLAST_GMODE  2
#define AIRBLAST_MAX    AIRBLAST_RESIZE + AIRBLAST_GMODE

public Plugin myinfo =
{
    name        = "[TF2] Anti Donor Abuse",
    description = "Prevents donors from abusing their powers",
    author      = "Banshee, Sreaper, Malifox",
    version     = "2.0.0",
    url         = "https://FirePowered.org"
};

public void OnPluginStart() {
    if (!HookEventEx("player_sapped_object", Event_PlayerSappedObject)) {
        SetFailState("Unable to hook player_sapped_object");
    }

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) {
            SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
        }
    }

    g_hCvarHealing  = CreateConVar("ada_healing", "3", "Bitstring to prevent healing\n0=Disabled\n1=No healing while in god mode\n2=No healing while resized", _, true, 0.0, true, 3.0);
    g_hCvarDamage   = CreateConVar("ada_damage", "31", "Bitstring to prevent players from damaging other things\n0=Disabled\n1=No damage while resized\n2=No damage while in a kart\n4=No damage in god mode (some God mode plugins may handle this already)\n8=Apply to players\n16=Apply to buildings", _, true, 0.0, true, 31.0);
    g_hCvarSapper   = CreateConVar("ada_sapper", "3", "Bitstring to prevent players from using the sapper\n0=Disabled\n1=No sapper while resized\n2=No sapper while god mode", _, true, 0.0, true, 3.0);
    g_hCvarAirblast = CreateConVar("ada_airblast", "3", "Bitstring to prevent players from airblasting other players\n0=Disabled\n1=No airblast while resized\n2=No airblast in god mode", _, true, 0.0, true, 3.0);

    HookConVarChange(g_hCvarHealing, OnConVarChanged);
    HookConVarChange(g_hCvarDamage, OnConVarChanged);
    HookConVarChange(g_hCvarSapper, OnConVarChanged);
    HookConVarChange(g_hCvarAirblast, OnConVarChanged);
    AutoExecConfig();
}

public void OnConVarChanged(Handle cvar, const char[] oldValue, const char[] newValue) {
    int oldInt = StringToInt(oldValue);
    int newInt = StringToInt(newValue);
    if (cvar == g_hCvarHealing && CheckCvar(oldInt, newInt, HEALING_MAX, "ada_healing")) {
        g_CvarHealing = newInt;
    } else if (cvar == g_hCvarDamage && CheckCvar(oldInt, newInt, DMG_MAX, "ada_damage")) {
        g_CvarDamage = newInt;
        ValidateDamageCvar(oldInt);
    } else if (cvar == g_hCvarSapper && CheckCvar(oldInt, newInt, SAPPER_MAX, "ada_sapper")) {
        g_CvarSapper = newInt;
    } else if (cvar == g_hCvarAirblast && CheckCvar(oldInt, newInt, AIRBLAST_MAX, "ada_airblast")) {
        g_CvarAirblast = newInt;
    }
}

void ValidateDamageCvar(int def) {
    if (g_CvarDamage != DISABLED && ((g_CvarDamage & DMG_PLAYER) == 0 && (g_CvarDamage & DMG_BLD) == 0)) {
        LogError("One of %d or %d (damage against players/buildings) must be specified if ada_damage is not disabled, setting to the old/default of %d", DMG_PLAYER, DMG_BLD, def);
        SetConVarInt(g_hCvarDamage, def);
    }
}

public void OnConfigsExecuted() {
    g_CvarHealing = GetConVarInt(g_hCvarHealing);

    g_CvarDamage = GetConVarInt(g_hCvarDamage);
    ValidateDamageCvar(DMG_MAX);

    g_CvarSapper   = GetConVarInt(g_hCvarSapper);
    g_CvarAirblast = GetConVarInt(g_hCvarAirblast);
}

/**
 * Check if a cvar is valid, logging an error if not.
 *
 * @param old Old value
 * @param new New value
 * @param max Maximum allowed value
 * @param name Cvar name
 * @return True if the new cvar value is valid, false otherwise
 */
bool CheckCvar(int old, int newInt, int max, const char[] name) {
    if (newInt > max || newInt < DISABLED) {
        LogError("Invalid value %d for %s (must be between %d and %d), keeping the old value %d instead", newInt, name, DISABLED, max, old);
        return false;
    }
    LogCvar("Cvar %s changed from %d to %d", name, old, newInt);
    return true;
}

/**
 * Check if a given client is allowed to place a sapper based on their player state and the cvar values.
 *
 * @param client The client
 * @return True if the client is allowed to place a sapper, false otherwise
 */
bool CheckAllowSapper(int client) {
    LogCvar("Value of ada_sapper: %d", g_CvarSapper);
    return BasicResizeGodCheck(client, g_CvarSapper, SAPPER_GMODE, SAPPER_RESIZE, "sapping a building");
}

/**
 * Check if a given client is allowed to deal damage based on their player state and the cvar values.
 *
 * @param client The client
 * @param building If the receiver of the damage is a building, defaults to false
 * @return True if the client is allowed to deal damage, false otherwise
 */
bool CheckAllowDamage(int client, bool building = false) {
    // Allow damage if the setting is disabled
    LogCvar("Value of ada_damage: %d", g_CvarDamage);
    if (g_CvarDamage == DISABLED || IsAdmin(client)) {
        return true;
    }

    // Check damage to buildings
    if (building && g_CvarDamage & DMG_BLD == 0) {
        return true;
    }

    if (!building && (g_CvarDamage & DMG_PLAYER) == 0) {
        return true;
    }

    // Clients in a kart
    if ((g_CvarDamage & DMG_KART) == DMG_KART && TF2_IsPlayerInCondition(client, TFCond_HalloweenKart)) {
        LogDebug("%L was prevented from doing damage in kart", client);
        return true;
    }

    return BasicResizeGodCheck(client, g_CvarDamage, DMG_GMODE, DMG_RESIZE, "doing damage");
}

/**
 * Check if a client is allowed to heal someone else.
 *
 * @param client The client
 * @return True if the client is allowed to heal, false otherwise
 */
bool CheckAllowHealing(int client) {
    LogCvar("Value of ada_healing: %d", g_CvarHealing);
    return BasicResizeGodCheck(client, g_CvarHealing, HEALING_GMODE, HEALING_RESIZE, "healing");
}

bool CheckAllowAirblast(int client) {
    LogCvar("Value of ada_airblast: %d", g_CvarAirblast);
    return BasicResizeGodCheck(client, g_CvarAirblast, AIRBLAST_GMODE, AIRBLAST_RESIZE, "airblasting");
}

bool BasicResizeGodCheck(int client, int cvar, int gmode, int resize, const char[] what) {
    if (cvar == DISABLED || IsAdmin(client)) {
        return true;
    }

    if ((cvar & gmode) == gmode && IsClientGodMode(client)) {
        LogDebug("%L was prevented from %s in god mode", client, what);
        return false;
    }
    if ((cvar & resize) == resize && IsClientResized(client)) {
        LogDebug("%L was prevented from %s while resized", client, what);
        return false;
    }
    return true;
}

public void OnClientPutInServer(int client) {
    SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2]) {
    if (client < 1 || client > MaxClients) {
        return Plugin_Continue;
    }
    if ((buttons & IN_ATTACK2) == IN_ATTACK2 && TF2_GetPlayerClass(client) == TFClass_Pyro && !CheckAllowAirblast(client)) {
        // The player is a pyro and used a secondary attack, and is in a condition where airblast isn't allowed
        // Check if it is the flamethrower as some secondary weapons have an attack2 also (e.g., detonator)
        int w = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        if (w != -1 && w == GetPlayerWeaponSlot(client, TFWeaponSlot_Primary)) {
            buttons ^= IN_ATTACK2;
        }
    } else if ((buttons & IN_ATTACK) == IN_ATTACK && TF2_GetPlayerClass(client) == TFClass_Medic && !CheckAllowHealing(client)) {
        // The player is a medic who is using a primary attack, and is in a condition where healing isn't allowed
        // Check if it is a secondary weapon (medigun)
        int w = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        if (w != -1 && w == GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary)) {
            buttons ^= IN_ATTACK;
        }
    }
    return Plugin_Continue;
}

public void OnEntityCreated(int building, const char[] classname) {
    if (StrEqual(classname, "obj_sentrygun", false) || StrEqual(classname, "obj_dispenser", false) || StrEqual(classname, "obj_teleporter", false)) {
        SDKHook(building, SDKHook_Spawn, OnEntitySpawned);
    }
}

public void OnEntitySpawned(int building) {
    SDKHook(building, SDKHook_OnTakeDamage, BuildingTakeDamage);
}

bool IsAdmin(int client) {
    return CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC);
}

public void Event_PlayerSappedObject(Handle event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (!CheckAllowSapper(client)) {
        RequestFrame(OnFrame, GetEventInt(event, "sapperid"));
    }
}

void OnFrame(any sapper) {
    StopSound(sapper, 1, SOUND_SAPPER_NOISE);
    StopSound(sapper, 1, SOUND_SAPPER_PLANT);
    RemoveEntity(sapper);
}

public Action BuildingTakeDamage(int building, int& attacker, int& inflictor, float& damage, int& damagetype) {
    if (attacker >= 1 && attacker <= MaxClients && !CheckAllowDamage(attacker, true)) {
        damage = 0.0;
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

public Action Hook_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype) {
    if (victim == attacker) {
        return Plugin_Continue;
    }
    if (attacker > 0 && attacker <= MaxClients && !CheckAllowDamage(attacker, false)) {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

/**
 * Checks whether the given client is in god mode (invuln). Note that this includes clients who are invuln from other things, such as ubercharge.
 *
 * @param client The client to check
 * @return True if the client is invulnerable, false otherwise
 */
bool IsClientGodMode(int client) {
    int takedamage = GetEntProp(client, Prop_Data, "m_takedamage");
    return takedamage == 1 || takedamage == 0;
}

/**
 * Checks whether a client is resized (model scale not equal to 1).
 *
 * @param client The client to check
 * @return True if the client is resized, false if they are normal size
 */
bool IsClientResized(int client) {
    float scale = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
    return scale != 1.0;
}

/**
 * Prints a logging message to the server. If DEBUG is defined, this will be logged to the file configs/debug.anti_donor_abuse.log.
 *
 * @param format Formatting rules
 * @param ... Variable number of format parameters
 */
void LogDebug(const char[] format, any...) {
    char buffer[512];
    VFormat(buffer, sizeof(buffer), format, 2);
    PrintToServer("[ANTI DONOR ABUSE] - %s", buffer);
#if defined DEBUG
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "logs/debug.anti_donor_abuse.log");
    LogToFile(path, buffer);
#endif
}

/**
 * Prints a logging message to the server. If DEBUG_CVAR is defined, this will be logged to the file configs/debug.anti_donor_abuse.log.
 *
 * @param format Formatting rules
 * @param ... Variable number of format parameters
 */
void LogCvar(const char[] format, any...) {
    char buffer[512];
    VFormat(buffer, sizeof(buffer), format, 2);
    PrintToServer("[ANTI DONOR ABUSE] - %s", buffer);
#if defined DEBUG_CVAR
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "logs/debug.anti_donor_abuse.log");
    LogToFile(path, buffer);
#endif
}
