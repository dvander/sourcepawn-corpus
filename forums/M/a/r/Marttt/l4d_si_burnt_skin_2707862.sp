/**
// ====================================================================================================
Change Log:

1.0.5 (17-March-2021)
    - Plugin renamed.
    - Added support to all special infecteds (L4D2 only).

1.0.4 (13-July-2020)
    - Added cvar to control the "z_burn_max" hidden cvar.
    - Added colorful messages.
    - Fixed the menus pagination.

1.0.3 (06-July-2020)
    - Added cvar to restore the Tank's burn percent when it gets frustrated (pass the control).

1.0.2 (05-July-2020)
    - Added menu to select a client to get/set burn percent.

1.0.1 (30-June-2020)
    - Added cvar for damage bonus.
    - Removed OnPreThink hook, replaced logic by default "z_burn_max" hidden cvar. (Thanks Lux for reporting)

1.0.0 (29-June-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] SI Burnt Skin"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Allow special infected to spawn with burnt skin"
#define PLUGIN_VERSION                "1.0.5"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=325618"

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
#define CONFIG_FILENAME               "l4d_si_burnt_skin"

// ====================================================================================================
// Defines
// ====================================================================================================
#define TEAM_INFECTED                 3

#define L4D2_ZOMBIECLASS_SMOKER       1
#define L4D2_ZOMBIECLASS_BOOMER       2
#define L4D2_ZOMBIECLASS_HUNTER       3
#define L4D2_ZOMBIECLASS_SPITTER      4
#define L4D2_ZOMBIECLASS_JOCKEY       5
#define L4D2_ZOMBIECLASS_CHARGER      6
#define L4D2_ZOMBIECLASS_TANK         8

#define L4D1_ZOMBIECLASS_SMOKER       1
#define L4D1_ZOMBIECLASS_BOOMER       2
#define L4D1_ZOMBIECLASS_HUNTER       3
#define L4D1_ZOMBIECLASS_TANK         5

#define L4D2_FLAG_ZOMBIECLASS_NONE    0
#define L4D2_FLAG_ZOMBIECLASS_SMOKER  1
#define L4D2_FLAG_ZOMBIECLASS_BOOMER  2
#define L4D2_FLAG_ZOMBIECLASS_HUNTER  4
#define L4D2_FLAG_ZOMBIECLASS_SPITTER 8
#define L4D2_FLAG_ZOMBIECLASS_JOCKEY  16
#define L4D2_FLAG_ZOMBIECLASS_CHARGER 32
#define L4D2_FLAG_ZOMBIECLASS_TANK    64

#define L4D1_FLAG_ZOMBIECLASS_NONE    0
#define L4D1_FLAG_ZOMBIECLASS_SMOKER  1
#define L4D1_FLAG_ZOMBIECLASS_BOOMER  2
#define L4D1_FLAG_ZOMBIECLASS_HUNTER  4
#define L4D1_FLAG_ZOMBIECLASS_TANK    8

#define MIN_BURN_PERCENT              0.00
#define MAX_BURN_PERCENT_SMOKER       0.30
#define MAX_BURN_PERCENT_BOOMER       0.12
#define MAX_BURN_PERCENT_HUNTER       0.35
#define MAX_BURN_PERCENT_SPITTER      0.15
#define MAX_BURN_PERCENT_JOCKEY       0.40
#define MAX_BURN_PERCENT_CHARGER      0.40
#define MAX_BURN_PERCENT_TANK         1.00

// ====================================================================================================
// Native Cvars
// ====================================================================================================
static ConVar g_hCvar_z_burn_max;
static ConVar g_hCvar_z_burn_rate;

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_BurnMax;
static ConVar g_hCvar_BurnRate;
static ConVar g_hCvar_RestoreBurn;
static ConVar g_hCvar_Chance;
static ConVar g_hCvar_MinPercent;
static ConVar g_hCvar_MaxPercent;
static ConVar g_hCvar_DmgMultiplier;
static ConVar g_hCvar_SI;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bL4D2;
static bool   g_bConfigLoaded;
static bool   g_bTankFrustrated;
static bool   g_bEventsHooked;
static bool   g_bCvar_z_burn_max;
static bool   g_bCvar_z_burn_rate;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_BurnMax;
static bool   g_bCvar_RestoreBurn;
static bool   g_bCvar_Chance;
static bool   g_bCvar_DmgMultiplier;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iTankClass;
static int    g_iCvar_SI;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_burnPercent_TankFrustrated;
static float  g_fCvar_z_burn_max;
static float  g_fCvar_z_burn_rate;
static float  g_fCvar_BurnRate;
static float  g_fCvar_Chance;
static float  g_fCvar_MinPercent;
static float  g_fCvar_MaxPercent;
static float  g_fCvar_DmgMultiplier;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
static int    gc_iMenu[MAXPLAYERS+1];
static int    gc_iMenuUserId[MAXPLAYERS+1];
static int    gc_iMenuPageIndex[MAXPLAYERS+1][2];

// ====================================================================================================
// Menu - Plugin Variables
// ====================================================================================================
static Menu   g_mMenuBurnPercent;

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
    g_iTankClass = (g_bL4D2 ? L4D2_ZOMBIECLASS_TANK : L4D1_ZOMBIECLASS_TANK);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    g_hCvar_z_burn_max      = FindConVar("z_burn_max");
    g_hCvar_z_burn_rate     = FindConVar("z_burn_rate");

    CreateConVar("l4d_si_burnt_skin_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled       = CreateConVar("l4d_si_burnt_skin_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_BurnMax       = CreateConVar("l4d_si_burnt_skin_burn_max", "1", "Increases the hidden cvar \"z_burn_max\" to its maximum value (from default: 0.85, to: 1.00).\n0 = Enable, 1 = Disable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_BurnRate      = CreateConVar("l4d_si_burnt_skin_burn_rate", "0.01", "How fast the burn effect grows on burning special infected (changes the hidden cvar \"z_burn_rate\" value).", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_RestoreBurn   = CreateConVar("l4d_si_burnt_skin_restore_burn", "1", "Restores the Tank's burn percent when it gets frustrated (pass the control).\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Chance        = CreateConVar("l4d_si_burnt_skin_chance", "100.0", "Chance of a special infected spawn with burnt skin.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_MinPercent    = CreateConVar("l4d_si_burnt_skin_min_percent", "0.0", "Minimal random % of skin burn on special infecteds.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_MaxPercent    = CreateConVar("l4d_si_burnt_skin_max_percent", "100.0", "Maximum random % of skin burn on special infecteds.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_DmgMultiplier = CreateConVar("l4d_si_burnt_skin_dmg_multiplier", "10.0", "Damage bonus % multiplied by the percentage of the special infected burnt skin.\nFormula: Damage + (Damage * Bonus / 100 * Burn Percentage).\n0 = OFF.", CVAR_FLAGS, true, -100.0);

    if (g_bL4D2)
        g_hCvar_SI        = CreateConVar("l4d_si_burnt_skin_si", "127", "Which special infected should have burnt skin.\n1 = SMOKER, 2 = BOOMER, 4 = HUNTER, 8 = SPITTER, 16 = JOCKEY, 32 = CHARGER, 64 = TANK.\nAdd numbers greater than 0 for multiple options.\nExample: \"127\", enables command chase for all SI.", CVAR_FLAGS, true, 0.0, true, 127.0);
    else
        g_hCvar_SI        = CreateConVar("l4d_si_burnt_skin_si", "8", "Which special infected should have burnt skin.\n1 = SMOKER, 2  = BOOMER, 4 = HUNTER, 8 = TANK.\nAdd numbers greater than 0 for multiple options.\nExample: \"15\", enables command chase for all SI.", CVAR_FLAGS, true, 0.0, true, 15.0);

    // Hook plugin ConVars change
    g_hCvar_z_burn_max.AddChangeHook(Event_ConVarChanged);
    g_hCvar_z_burn_rate.AddChangeHook(Event_ConVarChanged);

    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_BurnMax.AddChangeHook(Event_ConVarChanged);
    g_hCvar_BurnRate.AddChangeHook(Event_ConVarChanged);
    g_hCvar_RestoreBurn.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Chance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MinPercent.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MaxPercent.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DmgMultiplier.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SI.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Create plugin menu
    CreateMenuSetBurnPercent();

    // Admin Commands
    RegAdminCmd("sm_getburnpercent", CmdGetBurnPercent, ADMFLAG_ROOT, "Prints the burnt skin percentage from special infected at crosshair, if none is found, then opens a menu to select an alive special infected and get its the burnt skin percentage.");
    RegAdminCmd("sm_setburnpercent", CmdSetBurnPercent, ADMFLAG_ROOT, "Sets the burnt skin percentage from special infected at crosshair, if none is found, then opens a menu to select an alive special infected and set its burnt skin percentage.");
    RegAdminCmd("sm_print_cvars_l4d_si_burnt_skin", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    g_bConfigLoaded = true;

    LateLoad();

    HookEvents(g_bCvar_Enabled);
}

/****************************************************************************************************/

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    HookEvents(g_bCvar_Enabled);
}

/****************************************************************************************************/

void GetCvars()
{
    g_fCvar_z_burn_max = g_hCvar_z_burn_max.FloatValue;
    g_bCvar_z_burn_max = g_fCvar_z_burn_max > 0.0;
    g_fCvar_z_burn_rate = g_hCvar_z_burn_rate.FloatValue;
    g_bCvar_z_burn_rate = g_fCvar_z_burn_rate > 0.0;

    if (g_bCvar_BurnMax)
        SetConVarFloat(g_hCvar_z_burn_max, 1.0);

    SetConVarFloat(g_hCvar_z_burn_rate, g_fCvar_BurnRate);

    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_BurnMax = g_hCvar_BurnMax.BoolValue;
    g_fCvar_BurnRate = g_hCvar_BurnRate.FloatValue;
    g_bCvar_RestoreBurn = g_hCvar_RestoreBurn.BoolValue;
    g_fCvar_Chance = g_hCvar_Chance.FloatValue;
    g_bCvar_Chance = g_fCvar_Chance > 0.0;
    g_fCvar_MinPercent = g_hCvar_MinPercent.FloatValue;
    g_fCvar_MaxPercent = g_hCvar_MaxPercent.FloatValue;
    g_fCvar_DmgMultiplier = g_hCvar_DmgMultiplier.FloatValue;
    g_bCvar_DmgMultiplier = g_fCvar_DmgMultiplier != 0.0;
    g_iCvar_SI = g_hCvar_SI.IntValue;

    HookEvents(g_bCvar_Enabled);
}

/****************************************************************************************************/

public void LateLoad()
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
    if (!g_bConfigLoaded)
        return;

    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_iMenu[client] = 0;
    gc_iMenuUserId[client] = 0;
    gc_iMenuPageIndex[client][0] = 0;
    gc_iMenuPageIndex[client][1] = 0;
}

// ====================================================================================================
// Events
// ====================================================================================================
void HookEvents(bool hook)
{
    if (hook && !g_bEventsHooked)
    {
        g_bEventsHooked = true;
        HookEvent("player_spawn", Event_PlayerSpawn);
        HookEvent("tank_spawn", Event_TankSpawn);
        HookEvent("tank_frustrated", Event_TankFrustrated);
        return;
    }

    if (!hook && g_bEventsHooked)
    {
        g_bEventsHooked = false;
        UnhookEvent("player_spawn", Event_PlayerSpawn);
        UnhookEvent("tank_spawn", Event_TankSpawn);
        UnhookEvent("tank_frustrated", Event_TankFrustrated);
        return;
    }
}

/****************************************************************************************************/

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bCvar_Chance)
        return;

    if (g_fCvar_Chance < GetRandomFloat(0.0, 100.0))
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidClient(client))
        return;

    if (GetClientTeam(client) != TEAM_INFECTED)
        return;

    int zombieClass = GetZombieClass(client);

    if (zombieClass == g_iTankClass)
        return;

    int zombieClassFlag = GetZombieClassFlag(client);

    if (!(zombieClassFlag & g_iCvar_SI))
        return;

    float maxBurnPercent = GetMaxBurnPercent(client, zombieClassFlag);
    float burnPercent = GetRandomFloat(g_fCvar_MinPercent, g_fCvar_MaxPercent) / 100.0 * maxBurnPercent;

    SetBurnPercent(client, burnPercent);
}

/****************************************************************************************************/

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
    bool bTankFrustrated = g_bTankFrustrated;
    g_bTankFrustrated = false;

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidClient(client))
        return;

    if (GetClientTeam(client) != TEAM_INFECTED)
        return;

    int zombieClass = GetZombieClass(client);

    if (zombieClass != g_iTankClass)
        return;

    if (bTankFrustrated && g_bCvar_RestoreBurn)
    {
        SetBurnPercent(client, g_burnPercent_TankFrustrated);
    }
    else
    {
        float maxBurnPercent = GetMaxBurnPercent(client, g_bL4D2 ? L4D2_FLAG_ZOMBIECLASS_TANK : L4D1_FLAG_ZOMBIECLASS_TANK);
        float burnPercent = GetRandomFloat(g_fCvar_MinPercent, g_fCvar_MaxPercent) / 100.0 * maxBurnPercent;

        SetBurnPercent(client, burnPercent);
    }
}

/****************************************************************************************************/

public void Event_TankFrustrated(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bCvar_RestoreBurn)
        return;

    g_bTankFrustrated = true;

    int client = GetClientOfUserId(event.GetInt("userid"));

    g_burnPercent_TankFrustrated = GetBurnPercent(client);
}

/****************************************************************************************************/

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    if (!g_bCvar_DmgMultiplier)
        return Plugin_Continue;

    if (!IsValidClient(victim))
        return Plugin_Continue;

    if (GetClientTeam(victim) != TEAM_INFECTED)
        return Plugin_Continue;

    int zombieClassFlag = GetZombieClassFlag(victim);

    if (!(zombieClassFlag & g_iCvar_SI))
        return Plugin_Continue;

    float maxBurnPercent = GetMaxBurnPercent(victim, zombieClassFlag);
    float burnPercent = GetBurnPercent(victim) / maxBurnPercent;

    if (burnPercent > 0.0)
    {
        damage += (damage * g_fCvar_DmgMultiplier / 100.0 * burnPercent);
        return Plugin_Changed;
    }

    return Plugin_Continue;
}

/****************************************************************************************************/

float GetMaxBurnPercent(int client, int zombieClassFlag)
{
    float maxBurnPercent;

    if (g_bL4D2)
    {
        switch (zombieClassFlag)
        {
            case L4D2_FLAG_ZOMBIECLASS_SMOKER:
            {
                maxBurnPercent = MAX_BURN_PERCENT_SMOKER;
            }
            case L4D2_FLAG_ZOMBIECLASS_BOOMER:
            {
                maxBurnPercent = MAX_BURN_PERCENT_BOOMER;
            }
            case L4D2_FLAG_ZOMBIECLASS_HUNTER:
            {
                maxBurnPercent = MAX_BURN_PERCENT_HUNTER;
                SetEntProp(client, Prop_Send, "m_nSkin", 1);
            }
            case L4D2_FLAG_ZOMBIECLASS_SPITTER:
            {
                maxBurnPercent = MAX_BURN_PERCENT_SPITTER;
            }
            case L4D2_FLAG_ZOMBIECLASS_JOCKEY:
            {
                maxBurnPercent = MAX_BURN_PERCENT_JOCKEY;
            }
            case L4D2_FLAG_ZOMBIECLASS_CHARGER:
            {
                maxBurnPercent = MAX_BURN_PERCENT_CHARGER;
            }
            case L4D2_FLAG_ZOMBIECLASS_TANK:
            {
                maxBurnPercent = MAX_BURN_PERCENT_TANK;
            }
        }
    }
    else
    {
        switch (zombieClassFlag)
        {
            case L4D1_FLAG_ZOMBIECLASS_SMOKER:
            {
                maxBurnPercent = MAX_BURN_PERCENT_SMOKER;
            }
            case L4D1_FLAG_ZOMBIECLASS_BOOMER:
            {
                maxBurnPercent = MAX_BURN_PERCENT_BOOMER;
            }
            case L4D1_FLAG_ZOMBIECLASS_HUNTER:
            {
                maxBurnPercent = MAX_BURN_PERCENT_HUNTER;
                SetEntProp(client, Prop_Send, "m_nSkin", 1);
            }
            case L4D1_FLAG_ZOMBIECLASS_TANK:
            {
                maxBurnPercent = MAX_BURN_PERCENT_TANK;
            }
        }
    }

    return maxBurnPercent;
}

// ====================================================================================================
// Menus
// ====================================================================================================
void CreateMenuSetBurnPercent()
{
    // Menu
    g_mMenuBurnPercent = new Menu(MenuHandleSetBurnPercent);
    g_mMenuBurnPercent.SetTitle("Set Burn Skin Percent:");
    g_mMenuBurnPercent.AddItem("+", "+0.1");
    g_mMenuBurnPercent.AddItem("-", "-0.1");
    g_mMenuBurnPercent.AddItem("1.0", "100%");
    g_mMenuBurnPercent.AddItem("0.9", "90%");
    g_mMenuBurnPercent.AddItem("0.8", "80%");
    g_mMenuBurnPercent.AddItem("0.7", "70%");
    g_mMenuBurnPercent.AddItem("0.6", "60%");
    g_mMenuBurnPercent.AddItem("0.5", "50%");
    g_mMenuBurnPercent.AddItem("0.4", "40%");
    g_mMenuBurnPercent.AddItem("0.3", "30%");
    g_mMenuBurnPercent.AddItem("0.2", "20%");
    g_mMenuBurnPercent.AddItem("0.1", "10%");
    g_mMenuBurnPercent.AddItem("0.0", "0%");
    g_mMenuBurnPercent.ExitBackButton = true;
}

/****************************************************************************************************/

public int MenuHandleSetBurnPercent(Menu menu, MenuAction action, int activator, int args)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            gc_iMenuPageIndex[activator][gc_iMenu[activator]] = GetMenuSelectionPosition();

            int client = GetClientOfUserId(gc_iMenuUserId[activator]);

            if (!IsValidClient(client))
                return 0;

            if (GetClientTeam(client) != TEAM_INFECTED)
                return 0;

            int zombieClassFlag = GetZombieClassFlag(client);

            if (!(zombieClassFlag & g_iCvar_SI))
                return 0;

            char sBurnPercent[4];
            menu.GetItem(args, sBurnPercent, sizeof(sBurnPercent));

            float burnPercentOld = GetBurnPercent(client);
            float maxBurnPercent = GetMaxBurnPercent(client, zombieClassFlag);
            float burnPercent;

            if (StrEqual(sBurnPercent, "+"))
                burnPercent = burnPercentOld + (0.1 * maxBurnPercent);
            else if (StrEqual(sBurnPercent, "-"))
                burnPercent = burnPercentOld - (0.1 * maxBurnPercent);
            else
                burnPercent = StringToFloat(sBurnPercent) * maxBurnPercent;

            if (burnPercent > maxBurnPercent)
                burnPercent = maxBurnPercent;

            if (burnPercent < MIN_BURN_PERCENT)
                burnPercent = MIN_BURN_PERCENT;

            SetBurnPercent(client, burnPercent);
            PrintToChat(activator, "\x04%N\x01 had \x05m_burnPercent\x01 changed:\nfrom \x03%.3f\x01 (\x03%.1f%%\x01) to \x03%.3f\x01 (\x03%.1f%%\x01)", client, burnPercentOld, burnPercentOld / maxBurnPercent * 100, burnPercent, burnPercent / maxBurnPercent * 100);

            DisplayMenuAtItem(g_mMenuBurnPercent, activator, gc_iMenuPageIndex[activator][gc_iMenu[activator]], MENU_TIME_FOREVER);
        }
        case MenuAction_Cancel:
        {
            if (args == MenuCancel_ExitBack)
                CreateBurnPercentClientMenu(activator);
        }
    }

    return 0;
}

/****************************************************************************************************/

void CreateBurnPercentClientMenu(int activator)
{
    Menu menu = new Menu(MenuHandleBurnPercentClient);

    switch (gc_iMenu[activator])
    {
        case 0: menu.SetTitle("Get Burn Percent:");
        case 1: menu.SetTitle("Set Burn Percent:");
    }

    char clientName[MAX_NAME_LENGTH];
    char userid[10];

    int count;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (GetClientTeam(client) != TEAM_INFECTED)
            continue;

        int zombieClassFlag = GetZombieClassFlag(client);

        if (!(zombieClassFlag & g_iCvar_SI))
            continue;

        GetClientName(client, clientName, sizeof(clientName));
        FormatEx(userid, sizeof(userid), "%i", GetClientUserId(client));
        menu.AddItem(userid, clientName);

        count++;
    }

    if (count == 0)
    {
        PrintToChat(activator, "\x04Menu unavailable. \x05No special infecteds alive.");
        return;
    }

    DisplayMenuAtItem(menu, activator, gc_iMenuPageIndex[activator][gc_iMenu[activator]], MENU_TIME_FOREVER);
}

/****************************************************************************************************/

public int MenuHandleBurnPercentClient(Menu menu, MenuAction action, int activator, int args)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            gc_iMenuPageIndex[activator][gc_iMenu[activator]] = GetMenuSelectionPosition();

            char sArg[10];
            menu.GetItem(args, sArg, sizeof(sArg));

            int userid = StringToInt(sArg);
            int client = GetClientOfUserId(userid);

            gc_iMenuUserId[activator] = userid;

            switch (gc_iMenu[activator])
            {
                case 0:
                {
                    if (IsValidClient(client) && GetClientTeam(client) == TEAM_INFECTED)
                    {
                        int zombieClassFlag = GetZombieClassFlag(client);

                        float burnPercentOld = GetBurnPercent(client);
                        float maxBurnPercent = GetMaxBurnPercent(client, zombieClassFlag);

                        PrintToChat(activator, "\x04%N\x01: \x05m_burnPercent\x01 = \x03%.3f\x01 (\x03%.1f%%\x01)", client, burnPercentOld, burnPercentOld / maxBurnPercent * 100);
                    }

                    CreateBurnPercentClientMenu(activator);
                }
                case 1:
                {
                    g_mMenuBurnPercent.Display(activator, MENU_TIME_FOREVER);
                }
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }

    return 0;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdGetBurnPercent(int activator, int args)
{
    if (!activator)
        return Plugin_Handled;

    gc_iMenu[activator] = 0;
    gc_iMenuPageIndex[activator][0] = 0;

    int client = GetClientAimTarget(activator, false);

    if (IsValidClient(client) && GetClientTeam(client) == TEAM_INFECTED)
    {
        int zombieClassFlag = GetZombieClassFlag(client);

        float burnPercentOld = GetBurnPercent(client);
        float maxBurnPercent = GetMaxBurnPercent(client, zombieClassFlag);

        PrintToChat(activator, "\x04%N\x01: \x05m_burnPercent\x01 = \x03%.3f\x01 (\x03%.1f%%\x01)", client, burnPercentOld, burnPercentOld / maxBurnPercent * 100);
    }

    CreateBurnPercentClientMenu(activator);

    return Plugin_Handled;
}

/****************************************************************************************************/

public Action CmdSetBurnPercent(int activator, int args)
{
    if (!activator)
        return Plugin_Handled;

    gc_iMenu[activator] = 1;
    gc_iMenuPageIndex[activator][1] = 0;

    if (args == 0)
    {
        CreateBurnPercentClientMenu(activator);
        return Plugin_Handled;
    }

    int client = GetClientAimTarget(activator, false);

    if (!IsValidClient(client))
        return Plugin_Handled;

    if (GetClientTeam(client) != TEAM_INFECTED)
        return Plugin_Handled;

    char sBurnPercent[10];
    GetCmdArg(1, sBurnPercent, sizeof(sBurnPercent));

    int zombieClassFlag = GetZombieClassFlag(client);

    float burnPercentOld = GetBurnPercent(client);
    float maxBurnPercent = GetMaxBurnPercent(client, zombieClassFlag);
    float burnPercent = StringToFloat(sBurnPercent);

    SetBurnPercent(client, burnPercent);
    PrintToChat(activator, "\x04%N\x01 had \x05m_burnPercent\x01 changed:\nfrom \x03%.3f\x01 (\x03%.1f%%\x01) to \x03%.3f\x01 (\x03%.1f%%\x01)", client, burnPercentOld, burnPercentOld / maxBurnPercent * 100, burnPercent, burnPercent/maxBurnPercent * 100);

    return Plugin_Handled;
}

/****************************************************************************************************/

public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d_si_burnt_skin) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_si_burnt_skin_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_si_burnt_skin_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_si_burnt_skin_burn_max  : %b (%s)", g_bCvar_BurnMax, g_bCvar_BurnMax ? "true" : "false");
    PrintToConsole(client, "l4d_si_burnt_skin_burn_rate : %.3f (%s)", g_fCvar_BurnRate, g_bCvar_DmgMultiplier ? "true" : "false");
    PrintToConsole(client, "l4d_si_burnt_skin_restore_burn  : %b (%s)", g_bCvar_RestoreBurn, g_bCvar_RestoreBurn ? "true" : "false");
    PrintToConsole(client, "l4d_si_burnt_skin_chance : %.2f%% (%s)", g_fCvar_Chance, g_bCvar_Chance ? "true" : "false");
    PrintToConsole(client, "l4d_si_burnt_skin_min_percent : %.2f%%", g_fCvar_MinPercent);
    PrintToConsole(client, "l4d_si_burnt_skin_max_percent : %.2f%%", g_fCvar_MaxPercent);
    PrintToConsole(client, "l4d_si_burnt_skin_dmg_multiplier : %.2f%% (%s)", g_fCvar_DmgMultiplier, g_bCvar_DmgMultiplier ? "true" : "false");
    PrintToConsole(client, "l4d_si_burnt_skin_si : %i", g_iCvar_SI);
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Game Cvars  -----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "z_burn_max : %.2f (%s)", g_fCvar_z_burn_max, g_bCvar_z_burn_max ? "true" : "false");
    PrintToConsole(client, "z_burn_rate : %.3f (%s)", g_fCvar_z_burn_rate, g_bCvar_z_burn_rate ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
}

// ====================================================================================================
// Helpers
// ====================================================================================================
/**
 * Validates if is a valid client index.
 *
 * @param client     Client index.
 * @return           True if client index is valid, false otherwise.
 */
bool IsValidClientIndex(int client)
{
    return (1 <= client <= MaxClients);
}

/****************************************************************************************************/

/**
 * Validates if is a valid client.
 *
 * @param client     Client index.
 * @return           True if client index is valid and client is in game, false otherwise.
 */
bool IsValidClient(int client)
{
    return (IsValidClientIndex(client) && IsClientInGame(client));
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

/****************************************************************************************************/

/**
 * Returns the zombie class flag from a zombie class.
 *
 * @param client        Client index.
 * @return              Client zombie class flag.
 */
int GetZombieClassFlag(int client)
{
    int zombieClass = GetZombieClass(client);

    if (g_bL4D2)
    {
        switch (zombieClass)
        {
            case L4D2_ZOMBIECLASS_SMOKER:
                return L4D2_FLAG_ZOMBIECLASS_SMOKER;
            case L4D2_ZOMBIECLASS_BOOMER:
                return L4D2_FLAG_ZOMBIECLASS_BOOMER;
            case L4D2_ZOMBIECLASS_HUNTER:
                return L4D2_FLAG_ZOMBIECLASS_HUNTER;
            case L4D2_ZOMBIECLASS_SPITTER:
                return L4D2_FLAG_ZOMBIECLASS_SPITTER;
            case L4D2_ZOMBIECLASS_JOCKEY:
                return L4D2_FLAG_ZOMBIECLASS_JOCKEY;
            case L4D2_ZOMBIECLASS_CHARGER:
                return L4D2_FLAG_ZOMBIECLASS_CHARGER;
            case L4D2_ZOMBIECLASS_TANK:
                return L4D2_FLAG_ZOMBIECLASS_TANK;
            default:
                return L4D2_FLAG_ZOMBIECLASS_NONE;
        }
    }
    else
    {
        switch (zombieClass)
        {
            case L4D1_ZOMBIECLASS_SMOKER:
                return L4D1_FLAG_ZOMBIECLASS_SMOKER;
            case L4D1_ZOMBIECLASS_BOOMER:
                return L4D1_FLAG_ZOMBIECLASS_BOOMER;
            case L4D1_ZOMBIECLASS_HUNTER:
                return L4D1_FLAG_ZOMBIECLASS_HUNTER;
            case L4D1_ZOMBIECLASS_TANK:
                return L4D1_FLAG_ZOMBIECLASS_TANK;
            default:
                return L4D1_FLAG_ZOMBIECLASS_NONE;
        }
    }
}

/****************************************************************************************************/

/**
 * Gets the client burn percentage.
 *
 * @param client     Client index.
 * @return           Float value of client burn percentage.
 */
float GetBurnPercent(int client)
{
    return GetEntPropFloat(client, Prop_Send, "m_burnPercent");
}

/****************************************************************************************************/

/**
 * Sets the client burn percentage.
 *
 * @param client     Client index.
 * @param value      Burn percent amount.
 */
void SetBurnPercent(int client, float value)
{
    SetEntPropFloat(client, Prop_Send, "m_burnPercent", value);
}

