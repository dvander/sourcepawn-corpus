#pragma semicolon 1
#include <sourcemod>
#include <sdktools>




new Handle:g_Cvar_limit = INVALID_HANDLE;
new Handle:g_Cvar_Enable = INVALID_HANDLE;

public OnPluginStart()
{
CreateTimer(10.0, Timer_CheckPlayers, _, TIMER_REPEAT);
g_Cvar_limit = CreateConVar("sm_afklimit", "20", "Amount of players needed for the afk kicker to be enabled.", ADMFLAG_RCON);
g_Cvar_Enable = CreateConVar("sm_afklimit_enable", "1", "Enable afk player limit plugin?", ADMFLAG_RCON);
}
public Action:Timer_CheckPlayers(Handle:Timer)
{
    if(GetConVarInt(g_Cvar_Enable) == 0)
    return Plugin_Handled;

    if((GetConVarInt(g_Cvar_limit) == GetClientCount( )))
    ServerCommand("sm_afkenable 1");

    else if((GetConVarInt(g_Cvar_limit) >= GetClientCount( )))
    ServerCommand("sm_afkenable 0");
    return Plugin_Continue;
}
