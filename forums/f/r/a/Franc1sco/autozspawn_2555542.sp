#include <sourcemod>

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