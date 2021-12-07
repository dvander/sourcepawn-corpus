#pragma semicolon 1

#define VERSION "1.0.2"

#include <sourcemod>

public Plugin:myinfo = 
{
    name = "Auto !zspawn",
    author = "Darkthrone, Otstrel Team, TigerOx, TechKnow, AlliedModders LLC",
    description = "Automatically exec !zspawn command on dead players",
    version = VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=117601"
};

public OnPluginStart()
{	
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);	
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!client || !IsClientInGame(client))
        return Plugin_Continue;

    if(!IsPlayerAlive(client))
        CreateTimer(0.1, Timer_ZSpawn, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
        
    return Plugin_Continue;
}

public Action:Timer_ZSpawn(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if(!client)
        return Plugin_Continue;

    new iTeam = GetClientTeam(client);
    if(iTeam <= 1)
        return Plugin_Continue;

    if(IsPlayerAlive(client))
        return Plugin_Continue;

    ClientCommand(client, "zspawn");

    return Plugin_Continue;
}