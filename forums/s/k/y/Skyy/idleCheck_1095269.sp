// Idle Player Removal Tool

#pragma semicolon 1
#include <sourcemod>
#define SURVIVORTEAM 2
#define INFECTEDTEAM 3

const FIRSTCLIENT = 1;
new Float:g_vOldOrigin[MAXPLAYERS+1][3];
new Float:g_vOldAngles[MAXPLAYERS+1][3];

public Plugin:myinfo =
{
	name = "Idle Player Removal Tool",
	author = "Sky & Mr. Zero",
	description = "Checks to see if a player is idle.",
	version = "1.0",
	url = "http://steamcommunity.com/groups/skyservers"
};

public OnPluginStart()
{
	CreateTimer(60.0,AfkCheck, _, TIMER_REPEAT);
}

public Action:AfkCheck(Handle:timer)
{
	decl Float:vCurOrigin[3], Float:vCurAngles[3];
	for (new client = FIRSTCLIENT; client < MaxClients;client++)
	{
		if(!IsValidSurvivor(client)){continue;}
		
		GetClientAbsOrigin(client,vCurOrigin);
		GetClientAbsAngles(client,vCurAngles);
		
		if(GetVectorDistance(vCurOrigin,g_vOldOrigin[client]) == 0.0 && GetVectorDistance(vCurAngles,g_vOldAngles[client]) == 0.0)
		{
			KickClient(client,"Kicked From Server For Idling");
			PrintToChatAll("%N was kicked for idling.", client);
			continue;
		}
		
		g_vOldAngles[client] = vCurAngles;
		g_vOldOrigin[client] = vCurOrigin;
	}
}

bool:IsValidSurvivor(client)
{
	if(!IsClientInGame(client))
	{
		return false;
	}
	
	if(GetClientTeam(client) != SURVIVORTEAM)
	{
		return false;
	}
	
	if(!IsPlayerAlive(client))
	{
		return false;
	}
	
	return true;
}