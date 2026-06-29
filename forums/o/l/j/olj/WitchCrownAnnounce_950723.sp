#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 

{
    name = "Distance Meter",
    author = "Olj",
    description = "Displays who crowned witch message",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=102612"
}

public OnPluginStart()
{
    CreateConVar("l4d_crownmsg_version", PLUGIN_VERSION, "Version of Crown Message", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    HookEvent("witch_killed", EventWitchDeath);
}

public Action:EventWitchDeath(Handle:event, const String:name[], bool:dontBroadcast)
	{
		new killer = GetClientOfUserId(GetEventInt(event, "userid"));
		if (!IsValidClient(killer)) return;
		if (GetEventBool(event, "oneshot"))
			{
				decl String:killername[MAX_NAME_LENGTH];
				GetClientName(killer, killername, MAX_NAME_LENGTH);
				PrintToChatAll("\x04Player \x03%s \x04CROWNED the witch!", killername);
			}
	}
	
public IsValidClient(client)
{
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
		
	if (IsFakeClient(client))
		return false;
	
	if (!IsPlayerAlive(client))
		return false;
		
	if (GetClientTeam(client)!=2)
		return false;
	return true;
}				