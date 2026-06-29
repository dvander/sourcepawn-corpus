/**
// ====================================================================================================
Change Log:

1.0.3 (24-May-2022)
    - Added config to display or not the particle on self.

1.0.2 (24-April-2022)
    - Added client preferences.

1.0.1 (21-April-2022)
    - Added particle cvar to apply on summons.

1.0.0 (17-April-2022)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[PVK2] Team Particle"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Adds a particle around clients with team-based colors"
#define PLUGIN_VERSION                "1.0.3"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=337381"

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
#include <clientprefs>

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
#define CONFIG_FILENAME               "pvk2_team_particle"

// ====================================================================================================
// Defines
// ====================================================================================================
#define MAXENTITIES                   2048

#define VISIBILITY_ALL                1
#define VISIBILITY_ENEMIES            2
#define VISIBILITY_TEAMMATES          3

#define TEAM_SPECTATORS               1
#define TEAM_PIRATES                  2
#define TEAM_VIKINGS                  3
#define TEAM_KNIGHTS                  4

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_Visibility;
ConVar g_hCvar_SpecSeeAll;
ConVar g_hCvar_Self;
ConVar g_hCvar_Summons;
ConVar g_hCvar_Cookies;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bEventsHooked;
bool g_bCvar_Enabled;
bool g_bCvar_SpecSeeAll;
bool g_bCvar_Self;
bool g_bCvar_Summons;
bool g_bCvar_Cookies;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_Visibility;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
bool gc_bDisableAll[MAXPLAYERS+1];
bool gc_bDisableEnemies[MAXPLAYERS+1];
bool gc_bDisableTeammates[MAXPLAYERS+1];
bool gc_bDisableSelf[MAXPLAYERS+1];
bool gc_bDisableSummons[MAXPLAYERS+1];

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
bool ge_bParticleSummon[MAXENTITIES+1];
int ge_iParticleEntRef[MAXENTITIES+1] = { INVALID_ENT_REFERENCE, ... };
int ge_iParticleOwner[MAXENTITIES+1] = { INVALID_ENT_REFERENCE, ... };
int ge_iParticleTeam[MAXENTITIES+1];

// ====================================================================================================
// Cookie - Plugin Variables
// ====================================================================================================
Cookie g_cbDisableAll;
Cookie g_cbDisableEnemies;
Cookie g_cbDisableTeammates;
Cookie g_cbDisableSelf;
Cookie g_cbDisableSummons;

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    char game[8];
    GetGameFolderName(game, sizeof(game));

    if (!StrEqual(game, "pvkii"))
    {
        strcopy(error, err_max, "This plugin only runs in \"Pirates, Vikings, and Knights II\" game");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    CreateConVar("pvk2_team_particle_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled    = CreateConVar("pvk2_team_particle_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Visibility = CreateConVar("pvk2_team_particle_visibility", "1", "To whom the particle should be visible.\n1 = Everyone, 2 = Only enemies, 3 = Only teammates.", CVAR_FLAGS, true, 1.0, true, 3.0);
    g_hCvar_SpecSeeAll = CreateConVar("pvk2_team_particle_spec_see_all", "1", "Should spectators see all teams particles?\n0 = No, 1 = Yes.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Self       = CreateConVar("pvk2_team_particle_self", "1", "Should display particle on self?\n0 = No, 1 = Yes.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Summons    = CreateConVar("pvk2_team_particle_summons", "1", "Should summons (parrot/vulture) have particles?\n0 = No, 1 = Yes.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Cookies    = CreateConVar("pvk2_team_particle_cookies", "1", "Allow cookies for storing client preferences.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Visibility.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpecSeeAll.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Self.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Summons.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Cookies.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Cookies
    g_cbDisableAll       = new Cookie("pvk2_337381_disable_all", "Particle Team - Disable all particles", CookieAccess_Protected);
    g_cbDisableEnemies   = new Cookie("pvk2_337381_disable_enemies", "Particle Team - Disable particle for enemies", CookieAccess_Protected);
    g_cbDisableTeammates = new Cookie("pvk2_337381_disable_teammates", "Particle Team - Disable particle for teammates", CookieAccess_Protected);
    g_cbDisableSelf      = new Cookie("pvk2_337381_disable_self", "Particle Team - Disable particle on self", CookieAccess_Protected);
    g_cbDisableSummons   = new Cookie("pvk2_337381_disable_summons", "Particle Team - Disable particle for summons", CookieAccess_Protected);

    // Commands
    RegConsoleCmd("sm_teamparticle", CmdTeamParticleMenu, "Open a menu to toogle the team particle for the client.");

    // Admin Commands
    RegAdminCmd("sm_print_cvars_pvk2_team_particle", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnPluginEnd()
{
    KillAllParticles();
}

/****************************************************************************************************/

public void OnMapStart()
{
    // Fix for when OnConfigsExecuted is not executed by SM in some games
    RequestFrame(OnConfigsExecuted);
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    KillAllParticles();

    LateLoad();

    HookEvents();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    KillAllParticles();

    LateLoad();

    HookEvents();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_iCvar_Visibility = g_hCvar_Visibility.IntValue;
    g_bCvar_SpecSeeAll = g_hCvar_SpecSeeAll.BoolValue;
    g_bCvar_Self = g_hCvar_Self.BoolValue;
    g_bCvar_Summons = g_hCvar_Summons.BoolValue;
    g_bCvar_Cookies = g_hCvar_Cookies.BoolValue;
}

/****************************************************************************************************/

void LateLoad()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        OnClientDisconnect(client);

        if (AreClientCookiesCached(client))
            OnClientCookiesCached(client);

        CreateAura(client, client);
    }

    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "npc_parrot")) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(Frame_LateLoad, EntIndexToEntRef(entity));
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "npc_vulture")) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(Frame_LateLoad, EntIndexToEntRef(entity));
    }
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("player_spawn", Event_PlayerSpawn);
        HookEvent("player_death", Event_PlayerDeath);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("player_spawn", Event_PlayerSpawn);
        UnhookEvent("player_death", Event_PlayerDeath);

        return;
    }
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_bDisableAll[client] = false;
    gc_bDisableEnemies[client] = false;
    gc_bDisableTeammates[client] = false;
    gc_bDisableSelf[client] = false;
    gc_bDisableSummons[client] = false;

    KillParticle(client);
}

/****************************************************************************************************/

public void OnClientCookiesCached(int client)
{
    if (IsFakeClient(client))
        return;

    if (!g_bCvar_Cookies)
        return;

    char cookieDisableAll[2];
    g_cbDisableAll.Get(client, cookieDisableAll, sizeof(cookieDisableAll));
    if (cookieDisableAll[0] != 0)
        gc_bDisableAll[client] = (StringToInt(cookieDisableAll) == 1 ? true : false);

    char cookieDisableEnemies[2];
    g_cbDisableEnemies.Get(client, cookieDisableEnemies, sizeof(cookieDisableEnemies));
    if (cookieDisableEnemies[0] != 0)
        gc_bDisableEnemies[client] = (StringToInt(cookieDisableEnemies) == 1 ? true : false);

    char cookieDisableTeammates[2];
    g_cbDisableTeammates.Get(client, cookieDisableTeammates, sizeof(cookieDisableTeammates));
    if (cookieDisableTeammates[0] != 0)
        gc_bDisableTeammates[client] = (StringToInt(cookieDisableTeammates) == 1 ? true : false);

    char cookieDisableSelf[2];
    g_cbDisableSelf.Get(client, cookieDisableSelf, sizeof(cookieDisableSelf));
    if (cookieDisableSelf[0] != 0)
        gc_bDisableSelf[client] = (StringToInt(cookieDisableSelf) == 1 ? true : false);

    char cookieDisableSummons[2];
    g_cbDisableSummons.Get(client, cookieDisableSummons, sizeof(cookieDisableSummons));
    if (cookieDisableSummons[0] != 0)
        gc_bDisableSummons[client] = (StringToInt(cookieDisableSummons) == 1 ? true : false);
}

/****************************************************************************************************/

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        return;

    CreateAura(client, client);
}

/****************************************************************************************************/

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        return;

    KillParticle(client);
}

/****************************************************************************************************/

void Frame_LateLoad(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    OnSpawnPost(entity);
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (classname[0] != 'n')
        return;

    if (!StrEqual(classname, "npc_parrot") && !StrEqual(classname, "npc_vulture"))
        return;

    SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    ge_bParticleSummon[entity] = false;
    ge_iParticleOwner[entity] = INVALID_ENT_REFERENCE;
    ge_iParticleTeam[entity] = 0;

    KillParticle(entity);
}

/****************************************************************************************************/

void OnSpawnPost(int entity)
{
    RequestFrame(Frame_OnSpawnPost, EntIndexToEntRef(entity)); // Wait until the next frame to get the updated value from m_hOwnerEntity
}

/****************************************************************************************************/

void Frame_OnSpawnPost(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    if (!g_bCvar_Enabled)
        return;

    if (!g_bCvar_Summons)
        return;

    int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

    if (!IsValidClientIndex(owner))
        return;

    CreateAura(entity, owner);
}

/****************************************************************************************************/

void CreateAura(int target, int owner)
{
    if (IsValidClientIndex(target))
    {
        if (!IsPlayerAlive(target))
            return;
    }

    int entity = EntRefToEntIndex(ge_iParticleEntRef[target]);

    if (entity == INVALID_ENT_REFERENCE)
    {
        int team = GetClientTeam(owner);

        switch (team)
        {
            case TEAM_PIRATES: CreateParticle(target, owner, team, "armor_pirate_base");
            case TEAM_VIKINGS: CreateParticle(target, owner, team, "armor_viking_base");
            case TEAM_KNIGHTS: CreateParticle(target, owner, team, "armor_knight_base");
            default: return;
        }
    }
}

/****************************************************************************************************/

void CreateParticle(int target, int owner, int team, char[] particle)
{
    float origin[3];
    GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", origin);

    char teamNum[2];
    IntToString(team, teamNum, sizeof(teamNum));

    int entity = CreateEntityByName("info_particle_system");
    ge_iParticleEntRef[target] = EntIndexToEntRef(entity);
    ge_iParticleOwner[entity] = EntIndexToEntRef(target);
    ge_bParticleSummon[entity] = (target != owner);
    ge_iParticleTeam[entity] = team;
    DispatchKeyValue(entity, "targetname", "pvk2_team_particle");
    DispatchKeyValue(entity, "start_active", "1");
    DispatchKeyValue(entity, "effect_name", particle);
    DispatchKeyValue(entity, "TeamNum", teamNum);
    DispatchKeyValueVector(entity, "origin", origin);
    DispatchSpawn(entity);
    ActivateEntity(entity); // Don't work without it

    SetVariantString("!activator");
    AcceptEntityInput(entity, "SetParent", target);

    SetEdictAlways(entity);
    SDKHook(entity, SDKHook_SetTransmit, OnSetTransmit);
}

/****************************************************************************************************/

Action OnSetTransmit(int entity, int client)
{
    SetEdictAlways(entity);

    if (IsFakeClient(client))
        return Plugin_Handled;

    if (ge_iParticleOwner[entity] == EntIndexToEntRef(client))
    {
        if (!g_bCvar_Self)
            return Plugin_Handled;

        if (gc_bDisableSelf[client])
            return Plugin_Handled;
    }

    if (gc_bDisableAll[client])
        return Plugin_Handled;

    if (ge_bParticleSummon[entity])
    {
        if (gc_bDisableSummons[client])
            return Plugin_Handled;
    }

    int team = GetClientTeam(client);

    if (team == TEAM_SPECTATORS)
    {
        if (g_bCvar_SpecSeeAll)
            return Plugin_Continue;

        return Plugin_Handled;
    }

    switch (g_iCvar_Visibility)
    {
        case VISIBILITY_ALL:
        {
            if (team != ge_iParticleTeam[entity])
            {
                if (gc_bDisableEnemies[client])
                {
                    return Plugin_Handled;
                }
                else
                    return Plugin_Continue;
            }
            else
            {
                if (gc_bDisableTeammates[client])
                    return Plugin_Handled;
                else
                    return Plugin_Continue;
            }
        }
        case VISIBILITY_ENEMIES:
        {
            if (team != ge_iParticleTeam[entity])
            {
                if (gc_bDisableEnemies[client])
                    return Plugin_Handled;
                else
                    return Plugin_Continue;
            }

            return Plugin_Handled;
        }
        case VISIBILITY_TEAMMATES:
        {
            if (team == ge_iParticleTeam[entity])
            {
                if (gc_bDisableTeammates[client])
                    return Plugin_Handled;
                else
                    return Plugin_Continue;
            }

            return Plugin_Handled;
        }
    }

    return Plugin_Continue;
}

/****************************************************************************************************/

void SetEdictAlways(int edict)
{
    if (GetEdictFlags(edict) & FL_EDICT_ALWAYS)
        SetEdictFlags(edict, (GetEdictFlags(edict) ^ FL_EDICT_ALWAYS));
}

/****************************************************************************************************/

void KillParticle(int entity)
{
    int particle;

    if (ge_iParticleEntRef[entity] != INVALID_ENT_REFERENCE)
    {
        particle = EntRefToEntIndex(ge_iParticleEntRef[entity]);

        if (particle != INVALID_ENT_REFERENCE)
            AcceptEntityInput(particle, "Kill");

        ge_iParticleEntRef[entity] = INVALID_ENT_REFERENCE;
    }
}

/****************************************************************************************************/

void KillAllParticles()
{
    for (int entity = 0; entity <= GetMaxEntities(); entity++)
    {
        KillParticle(entity);
    }
}

// ====================================================================================================
// Menus
// ====================================================================================================
void CreateToggleMenu(int client)
{
    Menu menu = new Menu(HandleToggleMenu);
    menu.SetTitle("Team Particle Config");

    if (gc_bDisableAll[client])
        menu.AddItem("0", "☐ All OFF");
    else
        menu.AddItem("1", "☑ All ON");

    if (gc_bDisableEnemies[client])
        menu.AddItem("2", "☐ Enemies OFF");
    else
        menu.AddItem("3", "☑ Enemies ON");

    if (gc_bDisableTeammates[client])
        menu.AddItem("4", "☐ Teammates OFF");
    else
        menu.AddItem("5", "☑ Teammates ON");

    if (gc_bDisableSelf[client])
        menu.AddItem("6", "☐ Self OFF");
    else
        menu.AddItem("7", "☑ Self ON");

    if (gc_bDisableSummons[client])
        menu.AddItem("8", "☐ Summons OFF");
    else
        menu.AddItem("9", "☑ Summons ON");

    menu.Display(client, MENU_TIME_FOREVER);
}

/****************************************************************************************************/

int HandleToggleMenu(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            int client = param1;

            char sArg[2];
            menu.GetItem(param2, sArg, sizeof(sArg));

            int arg = StringToInt(sArg);

            switch (arg)
            {
                case 0, 1:
                {
                    bool disable = (StringToInt(sArg) == 1 ? true : false);
                    gc_bDisableAll[client] = disable;
                    if (g_bCvar_Cookies)
                        g_cbDisableAll.Set(client, disable ? "1" : "0");
                }
                case 2, 3:
                {
                    bool disable = (StringToInt(sArg) == 3 ? true : false);
                    gc_bDisableEnemies[client] = disable;
                    if (g_bCvar_Cookies)
                        g_cbDisableEnemies.Set(client, disable ? "1" : "0");
                }
                case 4, 5:
                {
                    bool disable = (StringToInt(sArg) == 5 ? true : false);
                    gc_bDisableTeammates[client] = disable;
                    if (g_bCvar_Cookies)
                        g_cbDisableTeammates.Set(client, disable ? "1" : "0");
                }
                case 6, 7:
                {
                    bool disable = (StringToInt(sArg) == 7 ? true : false);
                    gc_bDisableSelf[client] = disable;
                    if (g_bCvar_Cookies)
                        g_cbDisableSelf.Set(client, disable ? "1" : "0");
                }
                case 8, 9:
                {
                    bool disable = (StringToInt(sArg) == 9 ? true : false);
                    gc_bDisableSummons[client] = disable;
                    if (g_bCvar_Cookies)
                        g_cbDisableSummons.Set(client, disable ? "1" : "0");
                }
            }

            CreateToggleMenu(client);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }

    return 0;
}

// ====================================================================================================
// Commands
// ====================================================================================================
Action CmdTeamParticleMenu(int client, int args)
{
    if (!g_bCvar_Enabled)
        return Plugin_Handled;

    if (!IsValidClient(client))
        return Plugin_Handled;

    CreateToggleMenu(client);

    return Plugin_Handled;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------- Plugin Cvars (pvk2_team_particle) ------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "pvk2_team_particle_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "pvk2_team_particle_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "pvk2_team_particle_visibility : %i (%s)", g_iCvar_Visibility, g_iCvar_Visibility == VISIBILITY_ALL ? "ALL" : g_iCvar_Visibility == VISIBILITY_ENEMIES ? "ENEMIES" : g_iCvar_Visibility == VISIBILITY_TEAMMATES ? "TEAMMATES" : "");
    PrintToConsole(client, "pvk2_team_particle_spec_see_all : %b (%s)", g_bCvar_SpecSeeAll, g_bCvar_SpecSeeAll ? "true" : "false");
    PrintToConsole(client, "pvk2_team_particle_self : %b (%s)", g_bCvar_Self, g_bCvar_Self ? "true" : "false");
    PrintToConsole(client, "pvk2_team_particle_summons : %b (%s)", g_bCvar_Summons, g_bCvar_Summons ? "true" : "false");
    PrintToConsole(client, "pvk2_team_particle_cookies : %b (%s)", g_bCvar_Cookies, g_bCvar_Cookies ? "true" : "false");
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
 * @param client        Client index.
 * @return              True if client index is valid, false otherwise.
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