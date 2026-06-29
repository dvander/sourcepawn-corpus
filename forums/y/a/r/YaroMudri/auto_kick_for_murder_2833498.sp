#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

ConVar g_cvAutoKickEnabled;
bool g_bAutoKickEnabled = false;

public Plugin myinfo =
{
    name = "Auto-Kick For Murder",
    author = "Your Name",
    description = "Automatically Kick a player for committing a murder.",
    version = "1.0",
    url = "https://example.com"
};

public void OnPluginStart()
{
    g_cvAutoKickEnabled = CreateConVar("sm_auto_kick_for_murder", "0", "Enable (1) or Disable (0) Automatically Kick a player for committing a murder. (Default: 0)", FCVAR_NONE, true, 0.0, true, 1.0);
    g_cvAutoKickEnabled.AddChangeHook(OnConVarChanged);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    RegAdminCmd("sm_auto_kick_for_murder", Command_AutoKickPlayers, ADMFLAG_GENERIC, "Enable (1) or Disable (0) Automatically Kick a player for committing a murder.");
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_bAutoKickEnabled = g_cvAutoKickEnabled.BoolValue;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bAutoKickEnabled)
    {
        return Plugin_Continue;
    }

    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int victim = GetClientOfUserId(event.GetInt("userid"));

    if (attacker > 0 && attacker != victim && IsClientInGame(attacker))
    {
        KickClient(attacker, "You have been kicked for committing murder");
    }
    return Plugin_Continue;
}

public Action Command_AutoKickPlayers(int client, int args)
{
    if (client == 0 || !CheckCommandAccess(client, "sm_auto_kick_for_murder", ADMFLAG_GENERIC))
    {
        ReplyToCommand(client, "You do not have permission to use this command.");
        return Plugin_Handled;
    }

    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_auto_kick_for_murder <1|0>");
        return Plugin_Handled;
    }

    char arg[4];
    GetCmdArg(1, arg, sizeof(arg));

    int value = StringToInt(arg);
    if (value != 0 && value != 1)
    {
        ReplyToCommand(client, "Invalid argument. Use 1 to enable or 0 to disable.");
        return Plugin_Handled;
    }

    g_cvAutoKickEnabled.SetInt(value);
    ReplyToCommand(client, "Auto-Kick For Murder has been %s.", value ? "enabled" : "disabled");
    return Plugin_Handled;
}