#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
    name        = "Witch One Shot in Realism mode",
    description = "Witch One Shot in Realism mode",
    author      = "nah",
    version     = PLUGIN_VERSION,
    url         = ""
};

bool   g_bMapRunning;
bool   g_bCvarEnable;
float  g_fCvarShotgunRange;

ConVar g_hCvarEnable;
ConVar g_hCvarShotgunRange;

bool g_bLateLoad;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_bLateLoad = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_hCvarEnable       = CreateConVar("sm_witch_oneshot_enable", "1", "0 = off, 1 = on", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvarShotgunRange = FindConVar("z_shotgun_bonus_damage_range");

    g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarShotgunRange.AddChangeHook(ConVarChanged_Cvars);

    if (g_bLateLoad)
    {
        int entity = -1;
        while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
        {
            if (IsValidEntity(entity))
                HookWitch(entity);
        }
    }
}

public void OnConfigsExecuted()
{
    GetCvars();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

void GetCvars()
{
    g_bCvarEnable       = g_hCvarEnable.BoolValue;
    g_fCvarShotgunRange = g_hCvarShotgunRange.FloatValue;
}

public void OnMapStart()
{
    g_bMapRunning = true;
}

public void OnMapEnd()
{
    g_bMapRunning = false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (classname[0] == 'w' && strcmp(classname, "witch") == 0)
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage_Witch);
}

void HookWitch(int entity)
{
    SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage_Witch);
    SDKHook(entity,   SDKHook_OnTakeDamage, OnTakeDamage_Witch);
}

Action OnTakeDamage_Witch(int victim, int &attacker, int &inflictor,
    float &damage, int &damagetype, int &weapon,
    float damageForce[3], float damagePosition[3], int damagecustom)
{
    if (!g_bMapRunning || !g_bCvarEnable)
        return Plugin_Continue;

    if (damage <= 0.0)
        return Plugin_Continue;

    if (attacker < 1 || attacker > MaxClients)
        return Plugin_Continue;

    if (!IsClientInGame(attacker) || GetClientTeam(attacker) != 2)
        return Plugin_Continue;

    if (!(damagetype & DMG_BULLET))
        return Plugin_Continue;

    static char gameMode[32];
    FindConVar("mp_gamemode").GetString(gameMode, sizeof(gameMode));
    if (gameMode[0] != 'r' || strcmp(gameMode, "realism") != 0)
        return Plugin_Continue;

    int hWeapon = GetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon");
    if (hWeapon <= 0 || !IsValidEdict(hWeapon))
        return Plugin_Continue;

    static char weaponClass[32];
    GetEdictClassname(hWeapon, weaponClass, sizeof(weaponClass));

    if (weaponClass[7] != 's' && weaponClass[7] != 'a' && weaponClass[7] != 'p')
        return Plugin_Continue;

    if (strcmp(weaponClass, "weapon_autoshotgun")    != 0 &&
        strcmp(weaponClass, "weapon_shotgun_spas")   != 0 &&
        strcmp(weaponClass, "weapon_pumpshotgun")    != 0 &&
        strcmp(weaponClass, "weapon_shotgun_chrome") != 0)
        return Plugin_Continue;

    static float witchPos[3], playerPos[3];
    GetEntPropVector(victim,   Prop_Data, "m_vecOrigin", witchPos);
    GetEntPropVector(attacker, Prop_Data, "m_vecOrigin", playerPos);

    if (GetVectorDistance(playerPos, witchPos) > g_fCvarShotgunRange)
        return Plugin_Continue;

    damage = 1000.0;
    return Plugin_Changed;
}