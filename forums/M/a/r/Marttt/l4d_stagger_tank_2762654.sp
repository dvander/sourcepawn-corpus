/**
// ====================================================================================================
Change Log:

1.0.5 (23-January-2022)
    - Added explosive ammo check for grenade launcher projectiles. (thanks "Shao" for requesting)

1.0.4 (20-November-2021)
    - Added stagger limit and wait interval cvars. (thanks "Maur0" for requesting)

1.0.3 (14-November-2021)
    - Added shove chance.
    - Fixed some melee logic config. (thanks "Maur0" for reporting)

1.0.2 (13-November-2021)
    - Added cvar to not stagger the Tank while using his throw ability. (thanks "Maur0" for requesting)

1.0.1 (09-November-2021)
    - Fixed grenade launcher projectile. (thanks "Tonblader" for reporting)
    - Added support to infected hits. (thanks "Tonblader" for requesting)

1.0.0 (06-November-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Stagger Tank on Hit"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Stagger the Tank on hit"
#define PLUGIN_VERSION                "1.0.5"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=335069"

// ====================================================================================================
// Plugin Info
// ====================================================================================================
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Includes
// ====================================================================================================
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#tryinclude <left4dhooks> // Download here: https://forums.alliedmods.net/showthread.php?t=321696

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Cvar Flags
// ====================================================================================================
#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

// ====================================================================================================
// Filenames
// ====================================================================================================
#define CONFIG_FILENAME               "l4d_stagger_tank"
#define DATA_FILENAME                 "l4d_stagger_tank"

// ====================================================================================================
// Defines
// ====================================================================================================
#define TEAM_SURVIVOR                 2
#define TEAM_INFECTED                 3
#define TEAM_HOLDOUT                  4

#define L4D1_ZOMBIECLASS_TANK         5
#define L4D2_ZOMBIECLASS_TANK         8

#define L4D2_WEPID_GRENADE_LAUNCHER   21

#define L4D2_UPGRADE_EXPLOSIVE        2

#define DMG_EXPLOSIVE                 (DMG_BLAST|DMG_PHYSGUN)

#define CONFIG_ENABLE                 0
#define CONFIG_NORMAL                 1
#define CONFIG_EXPLOSIVE              2
#define CONFIG_INCENDIARY             3
#define CONFIG_SHOVE                  4
#define CONFIG_ARRAYSIZE              5

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_AbilityThrow;
ConVar g_hCvar_Limit;
ConVar g_hCvar_Wait;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bL4D2;
bool g_bEventsHooked;
bool g_bCvar_Enabled;
bool g_bCvar_AbilityThrow;
bool g_bCvar_Limit;
bool g_bCvar_Wait;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iTankClass;
int g_iCvar_Limit;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
float g_fCvar_Wait;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
bool gc_bTakeDamageAlivePostHooked[MAXPLAYERS+1];
bool gc_bGLExplosiveAmmo[MAXPLAYERS+1];
int gc_iStaggerCount[MAXPLAYERS+1];
float gc_fLastStagger[MAXPLAYERS+1];

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
bool ge_bGLExplosiveAmmo[MAXENTITIES+1];

// ====================================================================================================
// StringMap - Plugin Variables
// ====================================================================================================
StringMap g_smClassnameConfig;
StringMap g_smMeleeConfig;

// ====================================================================================================
// left4dhooks - Plugin Dependencies
// ====================================================================================================
#if !defined _l4dh_included
native void L4D_StaggerPlayer(int target, int source_ent, float vecSource[3]);
#endif

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" and \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }

    g_bL4D2 = (engine == Engine_Left4Dead2);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    g_iTankClass = (g_bL4D2 ? L4D2_ZOMBIECLASS_TANK : L4D1_ZOMBIECLASS_TANK);

    g_smClassnameConfig = new StringMap();
    g_smMeleeConfig = new StringMap();

    LoadConfigs();

    CreateConVar("l4d_stagger_tank_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("l4d_stagger_tank_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_AbilityThrow = CreateConVar("l4d_stagger_tank_ability_throw", "0", "Allow to stagger the Tank while using his throw ability.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Limit = CreateConVar("l4d_stagger_tank_limit", "0", "How many times the Tank can be staggered by the plugin.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_Wait = CreateConVar("l4d_stagger_tank_wait", "0.0", "How long (seconds) should wait to be able to stagger the Tank again.\n0 = OFF.", CVAR_FLAGS, true, 0.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_AbilityThrow.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Limit.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Wait.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_staggerreload", CmdReload, ADMFLAG_ROOT, "Reload the stagger configs.");
    RegAdminCmd("sm_print_cvars_l4d_stagger_tank", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    LateLoad();

    HookEvents();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    LateLoad();

    HookEvents();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_AbilityThrow = g_hCvar_AbilityThrow.BoolValue;
    g_iCvar_Limit = g_hCvar_Limit.IntValue;
    g_bCvar_Limit = (g_iCvar_Limit > 0);
    g_fCvar_Wait = g_hCvar_Wait.FloatValue;
    g_bCvar_Wait = (g_fCvar_Wait > 0.0);
}

/****************************************************************************************************/

void LoadConfigs()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/%s.cfg", DATA_FILENAME);

    if (!FileExists(path))
    {
        SetFailState("Missing required data file on \"data/%s.cfg\", please re-download.", DATA_FILENAME);
        return;
    }

    KeyValues kv = new KeyValues(DATA_FILENAME);
    kv.ImportFromFile(path);

    g_smClassnameConfig.Clear();
    g_smMeleeConfig.Clear();

    int default_enable;
    int default_normal;
    int default_explosive;
    int default_incendiary;
    int default_shove;

    if (kv.JumpToKey("default"))
    {
        default_enable = kv.GetNum("enable", 0);
        default_normal = kv.GetNum("normal", 0);
        default_explosive = kv.GetNum("explosive", 0);
        default_incendiary = kv.GetNum("incendiary", 0);
        default_shove = kv.GetNum("shove", 0);
    }

    kv.Rewind();

    char section[64];
    int config[CONFIG_ARRAYSIZE];

    if (kv.JumpToKey("classnames"))
    {
        if (kv.GotoFirstSubKey())
        {
            do
            {
                kv.GetSectionName(section, sizeof(section));
                TrimString(section);
                StringToLowerCase(section);

                config[CONFIG_ENABLE] = kv.GetNum("enable", default_enable);
                config[CONFIG_NORMAL] = kv.GetNum("normal", default_normal);
                config[CONFIG_EXPLOSIVE] = kv.GetNum("explosive", default_explosive);
                config[CONFIG_INCENDIARY] = kv.GetNum("incendiary", default_incendiary);
                config[CONFIG_SHOVE] = kv.GetNum("shove", default_shove);

                if (config[CONFIG_ENABLE] == 0)
                    continue;

                g_smClassnameConfig.SetArray(section, config, sizeof(config));
            } while (kv.GotoNextKey());
        }
    }

    kv.Rewind();

    if (g_bL4D2)
    {
        int config_melee[CONFIG_ARRAYSIZE];
        g_smClassnameConfig.GetArray("weapon_melee", config_melee, sizeof(config_melee));

        if (config_melee[CONFIG_ENABLE] != 0)
        {
            if (kv.JumpToKey("melees"))
            {
                if (kv.GotoFirstSubKey())
                {
                    do
                    {
                        kv.GetSectionName(section, sizeof(section));
                        TrimString(section);
                        StringToLowerCase(section);

                        config[CONFIG_ENABLE] = kv.GetNum("enable", config_melee[CONFIG_ENABLE]);
                        config[CONFIG_NORMAL] = kv.GetNum("normal", config_melee[CONFIG_NORMAL]);
                        config[CONFIG_EXPLOSIVE] = kv.GetNum("explosive", config_melee[CONFIG_EXPLOSIVE]);
                        config[CONFIG_INCENDIARY] = kv.GetNum("incendiary", config_melee[CONFIG_INCENDIARY]);
                        config[CONFIG_SHOVE] = kv.GetNum("shove", config_melee[CONFIG_SHOVE]);

                        if (config[CONFIG_ENABLE] == 0)
                            continue;

                        g_smMeleeConfig.SetArray(section, config, sizeof(config));
                    } while (kv.GotoNextKey());
                }
            }
        }

        kv.Rewind();
    }

    delete kv;
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("player_spawn", Event_PlayerSpawn);
        HookEvent("player_shoved", Event_PlayerShoved);

        if (g_bL4D2)
            HookEvent("weapon_fire", Event_WeaponFire);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("player_spawn", Event_PlayerSpawn);
        UnhookEvent("player_shoved", Event_PlayerShoved);

        if (g_bL4D2)
            UnhookEvent("weapon_fire", Event_WeaponFire);

        return;
    }
}

/****************************************************************************************************/

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        return;

    gc_iStaggerCount[client] = 0;
    gc_fLastStagger[client] = 0.0;
}

/****************************************************************************************************/

void Event_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (victim == 0 || attacker == 0)
        return;

    if (GetClientTeam(victim) != TEAM_INFECTED)
        return;

    int zombieClass = GetZombieClass(victim);

    if (zombieClass != g_iTankClass)
        return;

    if (!g_bCvar_AbilityThrow && GetEntPropFloat(victim, Prop_Send, "m_flStamina") > 0)
        return;

    int activeWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");

    if (activeWeapon == -1)
        return;

    char classname[36];
    int config[CONFIG_ARRAYSIZE];

    GetEntityClassname(activeWeapon, classname, sizeof(classname));
    g_smClassnameConfig.GetArray(classname, config, sizeof(config));

    if (StrEqual(classname, "weapon_melee"))
    {
        if (config[CONFIG_ENABLE] == 0)
            return;

        int configEmpty[CONFIG_ARRAYSIZE];
        config = configEmpty;

        char melee[16];
        GetEntPropString(activeWeapon, Prop_Data, "m_strMapSetScriptName", melee, sizeof(melee));
        g_smMeleeConfig.GetArray(melee, config, sizeof(config));
    }

    if (config[CONFIG_ENABLE] == 0)
        return;

    float damagePos[3];
    GetClientAbsOrigin(attacker, damagePos);

    if (config[CONFIG_SHOVE] > 0)
    {
        if (config[CONFIG_SHOVE] >= GetRandomInt(0, 100))
        {
            StaggerClient(victim, attacker, damagePos);
            return;
        }
    }
}

/****************************************************************************************************/

void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int weaponid = event.GetInt("weaponid");

    if (client == 0)
        return;

    switch (weaponid)
    {
        case L4D2_WEPID_GRENADE_LAUNCHER:
        {
            int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

            if (activeWeapon == -1)
                return;

            if (GetEntProp(activeWeapon, Prop_Send, "m_upgradeBitVec") & L4D2_UPGRADE_EXPLOSIVE)
                gc_bGLExplosiveAmmo[client] = true;
        }
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "grenade_launcher_projectile"))
        RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    ge_bGLExplosiveAmmo[entity] = false;
}

/****************************************************************************************************/

void OnNextFrame(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    int client = GetEntPropEnt(entity, Prop_Send, "m_hThrower");

    if (!IsValidClientIndex(client))
        return;

    if (gc_bGLExplosiveAmmo[client])
    {
        gc_bGLExplosiveAmmo[client] = false;
        ge_bGLExplosiveAmmo[entity] = true;
    }
}

/****************************************************************************************************/

void LateLoad()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        OnClientPutInServer(client);
    }
}

/****************************************************************************************************/

public void OnClientPutInServer(int client)
{
    if (gc_bTakeDamageAlivePostHooked[client])
        return;

    gc_bTakeDamageAlivePostHooked[client] = true;
    SDKHook(client, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_bTakeDamageAlivePostHooked[client] = false;
    gc_bGLExplosiveAmmo[client] = false;
    gc_iStaggerCount[client] = 0;
    gc_fLastStagger[client] = 0.0;
}

/****************************************************************************************************/

void OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3])
{
    if (!g_bCvar_Enabled)
        return;

    if (!IsValidClient(victim))
        return;

    if (GetClientTeam(victim) != TEAM_INFECTED)
        return;

    int zombieClass = GetZombieClass(victim);

    if (zombieClass != g_iTankClass)
        return;

    if (!g_bCvar_AbilityThrow && GetEntPropFloat(victim, Prop_Send, "m_flStamina") > 0)
        return;

    char classname[36];
    int config[CONFIG_ARRAYSIZE];

    if (IsValidClient(inflictor))
    {
        int activeWeapon = GetEntPropEnt(inflictor, Prop_Send, "m_hActiveWeapon");

        if (activeWeapon == -1)
            return;

        GetEntityClassname(activeWeapon, classname, sizeof(classname));
        g_smClassnameConfig.GetArray(classname, config, sizeof(config));
    }
    else
    {
        if (IsValidEntity(inflictor))
        {
            GetEntityClassname(inflictor, classname, sizeof(classname));
            g_smClassnameConfig.GetArray(classname, config, sizeof(config));

            switch (classname[0])
            {
                case 'g':
                {
                    if (StrEqual(classname, "grenade_launcher_projectile"))
                    {
                        if (!ge_bGLExplosiveAmmo[inflictor])
                            damagetype &= ~DMG_EXPLOSIVE;
                    }
                }
                case 'w':
                {
                    if (StrEqual(classname, "weapon_melee"))
                    {
                        if (config[CONFIG_ENABLE] == 0)
                            return;

                        int configEmpty[CONFIG_ARRAYSIZE];
                        config = configEmpty;

                        char melee[16];
                        GetEntPropString(inflictor, Prop_Data, "m_strMapSetScriptName", melee, sizeof(melee));
                        g_smMeleeConfig.GetArray(melee, config, sizeof(config));
                    }
                }
            }
        }
    }

    if (config[CONFIG_ENABLE] == 0)
        return;

    float damagePos[3];
    damagePos = damagePosition;

    if (config[CONFIG_NORMAL] > 0)
    {
        if (config[CONFIG_NORMAL] >= GetRandomInt(0, 100))
        {
            StaggerClient(victim, attacker, damagePos);
            return;
        }
    }

    if (config[CONFIG_EXPLOSIVE] > 0 && (damagetype & DMG_EXPLOSIVE))
    {
        if (config[CONFIG_EXPLOSIVE] >= GetRandomInt(0, 100))
        {
            StaggerClient(victim, attacker, damagePos);
            return;
        }
    }

    if (config[CONFIG_INCENDIARY] > 0 && (damagetype & DMG_BURN))
    {
        if (config[CONFIG_INCENDIARY] >= GetRandomInt(0, 100))
        {
            StaggerClient(victim, attacker, damagePos);
            return;
        }
    }
}

/****************************************************************************************************/

void StaggerClient(int victim, int attacker, float damagePosition[3])
{
    if (g_bCvar_Limit && gc_iStaggerCount[victim] >= g_iCvar_Limit)
        return;

    if (g_bCvar_Wait && gc_fLastStagger[victim] != 0.0 && GetGameTime() - gc_fLastStagger[victim] < g_fCvar_Wait)
        return;

    gc_iStaggerCount[victim]++;
    if (gc_iStaggerCount[victim] < 0) // int.MaxValue fix
        gc_iStaggerCount[victim] = 0;

    gc_fLastStagger[victim] = GetGameTime();

    SetEntPropFloat(victim, Prop_Send, "m_flCycle", 1.0); // Fix animation
    L4D_StaggerPlayer(victim, attacker, damagePosition);
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdReload(int client, int args)
{
    LoadConfigs();

    if (IsValidClient(client))
        PrintToChat(client, "\x04Stagger configs reloaded.");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "------------------- Plugin Cvars (l4d_stagger_tank) ------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_stagger_tank_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_stagger_tank_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_stagger_tank_ability_throw : %b (%s)", g_bCvar_AbilityThrow, g_bCvar_AbilityThrow ? "true" : "false");
    PrintToConsole(client, "l4d_stagger_tank_limit : %i", g_iCvar_Limit);
    PrintToConsole(client, "l4d_stagger_tank_wait : %.1f", g_fCvar_Wait);
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
/**
 * Validates if is a valid client index.
 *
 * @param client          Client index.
 * @return                True if client index is valid, false otherwise.
 */
bool IsValidClientIndex(int client)
{
    return (1 <= client <= MaxClients);
}

/****************************************************************************************************/

/**
 * Validates if is a valid client.
 *
 * @param client          Client index.
 * @return                True if client index is valid and client is in game, false otherwise.
 */
bool IsValidClient(int client)
{
    return (IsValidClientIndex(client) && IsClientInGame(client));
}

/****************************************************************************************************/

/**
 * Converts the string to lower case.
 *
 * @param input         Input string.
 */
void StringToLowerCase(char[] input)
{
    for (int i = 0; i < strlen(input); i++)
    {
        input[i] = CharToLower(input[i]);
    }
}

/****************************************************************************************************/

/**
 * Gets the client L4D1/L4D2 zombie class id.
 *
 * @param client     Client index.
 * @return L4D1      1=SMOKER, 2=BOOMER, 3=HUNTER, 4=WITCH, 5=TANK, 6=NOT INFECTED
 * @return L4D2      1=SMOKER, 2=BOOMER, 3=HUNTER, 4=SPITTER, 5=JOCKEY, 6=CHARGER, 7=WITCH, 8=TANK, 9=NOT INFECTED
 */
int GetZombieClass(int client)
{
    return (GetEntProp(client, Prop_Send, "m_zombieClass"));
}