#include <cstrike>
#include <csgocolors>
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <updater>

ConVar g_hCvar_Trail_Enable = null,
g_hCvar_Trail_AdminOnly = null,
g_hCvar_Trail_Duration = null,
g_hCvar_Trail_Fade_Duration = null,
g_hCvar_Trail_Width = null,
g_hCvar_Trail_End_Width = null,
g_hCvar_Trail_Per_Round = null;

float g_fCvar_Trail_Duration,
g_fCvar_Trail_Width,
g_fCvar_Trail_End_Width;

bool g_bCvar_Trail_Enable,
g_bCvar_Trail_AdminOnly,
b_Trail[MAXPLAYERS+1] = { false, ... };

int SpamCMD = 0,
i_TrailIndex,
trailcolor[4],
g_iCvar_Trail_Fade_Duration,
g_iCvar_Trail_Per_Round;

#define PLUGIN_VERSION                  "1.0.1"
#define PLUGIN_NAME                     "[CS:GO] Player Trails"
#define PLUGIN_DESCRIPTION              "Gives clients a colored trail when moving."
#define UPDATE_URL                      "http://www.maxximou5.com/sourcemod/playertrails/update.txt"
#define MODEL_TRAIL                     "materials/sprites/laserbeam.vmt"

public Plugin myinfo =
{
    name            = PLUGIN_NAME,
    author          = "Maxximou5",
    description     = PLUGIN_DESCRIPTION,
    version         = PLUGIN_VERSION,
    url             = "http://maxximou5.com/"
}

public void OnPluginStart()
{
    LoadTranslations("common.phrases");

    CreateConVar( "sm_playertrails_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD );

    g_hCvar_Trail_Enable = CreateConVar("sm_trail_enable", "1", "Enable or Disable all features of the plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvar_Trail_AdminOnly = CreateConVar("sm_trail_adminonly", "0", "Enable trails only for Admins (VOTE Flag).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvar_Trail_Duration = CreateConVar("sm_trail_duration", "5.0", "Duration of the trail.", FCVAR_PLUGIN, true, 1.0, true, 100.0);
    g_hCvar_Trail_Fade_Duration = CreateConVar("sm_trail_fade_duration", "3", "Duration of the trail.", FCVAR_PLUGIN, true, 1.0, true, 100.0);
    g_hCvar_Trail_Width = CreateConVar("sm_trail_width", "5.0", "Width of the trail.", FCVAR_PLUGIN, true, 1.0, true, 100.0);
    g_hCvar_Trail_End_Width = CreateConVar("sm_trail_end_width", "1.0", "Width of the trail.", FCVAR_PLUGIN, true, 1.0, true, 100.0);
    g_hCvar_Trail_Per_Round = CreateConVar("sm_trail_per_round", "5", "How many times per round a client can use the command.", FCVAR_PLUGIN, true, 1.0, true, 100.0);

    HookConVarChange(g_hCvar_Trail_Enable, OnSettingsChange);
    HookConVarChange(g_hCvar_Trail_AdminOnly, OnSettingsChange);
    HookConVarChange(g_hCvar_Trail_Duration, OnSettingsChange);
    HookConVarChange(g_hCvar_Trail_Fade_Duration, OnSettingsChange);
    HookConVarChange(g_hCvar_Trail_Width, OnSettingsChange);
    HookConVarChange(g_hCvar_Trail_End_Width, OnSettingsChange);
    HookConVarChange(g_hCvar_Trail_Per_Round, OnSettingsChange);

    UpdateConVars();

    AutoExecConfig(true, "playertrails");

    RegConsoleCmd("sm_trail", Command_Trail);
    RegConsoleCmd("sm_trails", Command_Trail);

    HookEvent("player_spawn", Event_OnPlayerSpawn);

    if(GetEngineVersion() != Engine_CSGO)
    {
        SetFailState("ERROR: This plugin is designed only for CS:GO.");
    }

    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public void OnConfigsExecuted()
{
    UpdateConVars();
}

public void OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public void OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_RemovePlugin();
    }
}

public void OnMapStart()
{
    i_TrailIndex = PrecacheModel(MODEL_TRAIL, true);
}

public Action Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (g_bCvar_Trail_Enable && b_Trail[client] && IsValidClient(client))
    {
        if (g_bCvar_Trail_AdminOnly)
        {
            if (!(GetAdminFlag(GetUserAdmin(client), Admin_Custom1)) && !(GetUserFlagBits(client) & ADMFLAG_ROOT))
            {
                return Plugin_Handled;
            }
        }
        SpamCMD = 0;
        CreateTimer(1.0, Timer_CreateTrail, client);
    }
    return Plugin_Handled;
}

public Action Command_Trail(int client, int args)
{
    if (!g_bCvar_Trail_Enable)
        return Plugin_Handled;

    if (!IsValidClient(client))
    {
        CPrintToChat(client, "[\x07T\x0FR\x10A\x04I\x0CL\x0ES\x01] {red}ERROR{default}: You must be alive and not a spectator!");
        return Plugin_Handled;
    }

    if (g_bCvar_Trail_AdminOnly)
    {
        if (!(GetAdminFlag(GetUserAdmin(client), Admin_Custom1)) && !(GetUserFlagBits(client) & ADMFLAG_ROOT))
        {
            CPrintToChat(client, "[\x07T\x0FR\x10A\x04I\x0CL\x0ES\x01] {red}ERROR{default}: Only admins may use this command.");
            return Plugin_Handled;
        }
    }

    SpamCMD += 1;
    if(SpamCMD >= g_iCvar_Trail_Per_Round)
    {
        CPrintToChat(client, "[\x07T\x0FR\x10A\x04I\x0CL\x0ES\x01] {red}ERROR{default}: You must wait till next round!");
        return Plugin_Handled;
    }

    if (args < 1)
    {
        CReplyToCommand(client, "{green}Usage{default}: sm_trail <color> [{red}red, {darkorange}orange, {orange}yellow, {green}green, {blue}blue, {purple}purple, {pink}pink, {lightblue}cyan, {default}white, none]");
        return Plugin_Handled;
    }

    int ent = GetPlayerWeaponSlot(client, 2);
    if (!IsValidEntity(ent))
    {
        ent = client;
    }

    char arg[32];
    GetCmdArg(1, arg, sizeof(arg));
    trailcolor[3] = 255;

    if (StrEqual(arg, "red"))
    {
        trailcolor[0] = 255;
        trailcolor[1] = 0;
        trailcolor[2] = 0;
        b_Trail[client] = true;
        CreateTimer(1.0, Timer_CreateTrail, client);
        CPrintToChat(client, "[\x07T\x0FR\x10A\x04I\x0CL\x0ES\x01] You have selected the trail color {%s}%s.", arg, arg);
    }
    else if (StrEqual(arg, "orange"))
    {
        trailcolor[0] = 255;
        trailcolor[1] = 128;
        trailcolor[2] = 0;
        b_Trail[client] = true;
        CreateTimer(1.0, Timer_CreateTrail, client);
        CPrintToChat(client, "[\x07T\x0FR\x10A\x04I\x0CL\x0ES\x01] You have selected the trail color {%s}%s.", arg, arg);
    }
    else if (StrEqual(arg, "yellow"))
    {
        trailcolor[0] = 255;
        trailcolor[1] = 255;
        trailcolor[2] = 0;
        b_Trail[client] = true;
        CreateTimer(1.0, Timer_CreateTrail, client);
        CPrintToChat(client, "[\x07T\x0FR\x10A\x04I\x0CL\x0ES\x01] You have selected the trail color {%s}%s.", arg, arg);
    }
    else if (StrEqual(arg, "green"))
    {
        trailcolor[0] = 0;
        trailcolor[1] = 255;
        trailcolor[2] = 0;
        b_Trail[client] = true;
        CreateTimer(1.0, Timer_CreateTrail, client);
        CPrintToChat(client, "[\x07T\x0FR\x10A\x04I\x0CL\x0ES\x01] You have selected the trail color {%s}%s.", arg, arg);
    }
    else if (StrEqual(arg, "blue"))
    {
        trailcolor[0] = 0;
        trailcolor[1] = 0;
        trailcolor[2] = 255;
        b_Trail[client] = true;
        CreateTimer(1.0, Timer_CreateTrail, client);
        CPrintToChat(client, "[\x07T\x0FR\x10A\x04I\x0CL\x0ES\x01] You have selected the trail color {%s}%s.", arg, arg);
    }
    else if (StrEqual(arg, "purple"))
    {
        trailcolor[0] = 127;
        trailcolor[1] = 0;
        trailcolor[2] = 127;
        b_Trail[client] = true;
        CreateTimer(1.0, Timer_CreateTrail, client);
        CPrintToChat(client, "[\x07T\x0FR\x10A\x04I\x0CL\x0ES\x01] You have selected the trail color {%s}%s.", arg, arg);
    }
    else if (StrEqual(arg, "pink"))
    {
        trailcolor[0] = 255;
        trailcolor[1] = 0;
        trailcolor[2] = 127;
        b_Trail[client] = true;
        CreateTimer(1.0, Timer_CreateTrail, client);
        CPrintToChat(client, "[\x07T\x0FR\x10A\x04I\x0CL\x0ES\x01] You have selected the trail color {%s}%s.", arg, arg);
    }
    else if (StrEqual(arg, "cyan"))
    {
        trailcolor[0] = 0;
        trailcolor[1] = 255;
        trailcolor[2] = 255;
        b_Trail[client] = true;
        CreateTimer(1.0, Timer_CreateTrail, client);
        CPrintToChat(client, "[\x07T\x0FR\x10A\x04I\x0CL\x0ES\x01] You have selected the trail color {lightblue}%s.", arg);
    }
    else if (StrEqual(arg, "gray"))
    {
        trailcolor[0] = 128;
        trailcolor[1] = 128;
        trailcolor[2] = 128;
        b_Trail[client] = true;
        CreateTimer(1.0, Timer_CreateTrail, client);
        CPrintToChat(client, "[\x07T\x0FR\x10A\x04I\x0CL\x0ES\x01] You have selected the trail color {%s}%s.", arg, arg);
    }
    else if (StrEqual(arg, "white"))
    {
        trailcolor[0] = 255;
        trailcolor[1] = 255;
        trailcolor[2] = 255;
        b_Trail[client] = true;
        CreateTimer(1.0, Timer_CreateTrail, client);
        CPrintToChat(client, "[\x07T\x0FR\x10A\x04I\x0CL\x0ES\x01] You have selected the trail color {%s}%s.", arg, arg);
    }
    else if (StrEqual(arg, "none")) {
        b_Trail[client] = false;
    }

    return Plugin_Handled;
}

public Action Timer_CreateTrail(Handle timer, any client)
{
    if (!g_bCvar_Trail_Enable)
        return Plugin_Stop;

    if (!IsValidClient(client))
        return Plugin_Stop;

    int ent = GetPlayerWeaponSlot(client, 2);
    if(ent == -1) {
        ent = client;
    }

    TE_SetupBeamFollow(ent, i_TrailIndex, 0, g_fCvar_Trail_Duration, g_fCvar_Trail_Width, g_fCvar_Trail_End_Width, g_iCvar_Trail_Fade_Duration, trailcolor);
    TE_SendToAll();

    return Plugin_Handled;
}

public OnSettingsChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if(convar == g_hCvar_Trail_Enable)
        g_bCvar_Trail_Enable = StringToInt(newValue) ? true : false;
    else if(convar == g_hCvar_Trail_AdminOnly)
        g_bCvar_Trail_AdminOnly = StringToInt(newValue) ? true : false;
    else if(convar == g_hCvar_Trail_Duration)
        g_fCvar_Trail_Duration = StringToFloat(newValue);
    else if(convar == g_hCvar_Trail_Fade_Duration)
        g_iCvar_Trail_Fade_Duration = StringToInt(newValue);
    else if(convar == g_hCvar_Trail_Width)
        g_fCvar_Trail_Width = StringToFloat(newValue);
    else if(convar == g_hCvar_Trail_End_Width)
        g_fCvar_Trail_End_Width = StringToFloat(newValue);
    else if(convar == g_hCvar_Trail_Per_Round)
        g_iCvar_Trail_Per_Round = StringToInt(newValue);
}

stock bool IsValidClient(int client)
{
    if (!(0 < client <= MaxClients)) return false;
    if (!IsClientInGame(client)) return false;
    if (IsFakeClient(client)) return false;
    return true;
}

UpdateConVars()
{
    g_bCvar_Trail_Enable = GetConVarBool(g_hCvar_Trail_Enable);
    g_bCvar_Trail_AdminOnly = GetConVarBool(g_hCvar_Trail_AdminOnly);
    g_fCvar_Trail_Duration = GetConVarFloat(g_hCvar_Trail_Duration);
    g_iCvar_Trail_Fade_Duration = GetConVarInt(g_hCvar_Trail_Fade_Duration);
    g_fCvar_Trail_Width = GetConVarFloat(g_hCvar_Trail_Width);
    g_fCvar_Trail_End_Width = GetConVarFloat(g_hCvar_Trail_End_Width);
    g_iCvar_Trail_Per_Round = GetConVarInt(g_hCvar_Trail_Per_Round);
}