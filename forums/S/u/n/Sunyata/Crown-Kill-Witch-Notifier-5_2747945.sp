#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

public Plugin:myinfo = 

{
    name = "Kill or crown witch notifier",
    author = "Kevin_b_er + Olj + sunyata",
    description = "Display message of who crowned or killed witch",
	version = "5.0",
    url = "https://forums.alliedmods.net/showthread.php?p=950716#post950716"
}

public OnPluginStart()
{
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
		PrintToChatAll("Witch crowned by %s", killername);
		PrintHintTextToAll("Witch crowned by %s", killername);	
	}
	else
	{		
		decl String:killername[MAX_NAME_LENGTH];
		GetClientName(killer, killername, MAX_NAME_LENGTH);
		PrintToChatAll("Witch killed by %s", killername);
		PrintHintTextToAll("Witch killed by %s", killername);
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