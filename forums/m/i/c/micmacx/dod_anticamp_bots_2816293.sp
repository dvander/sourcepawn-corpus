#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "Anticamp bots",
	author = "Micmacx",
	description = "Detects if bots camping and put them in spectator",
	version = PLUGIN_VERSION,
	url = "https://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=micmacx&description=&search=1"
};

new Float:mx_last_pos[MAXPLAYERS + 1][3];

public OnPluginStart()
{
	CreateConVar("dod_anticamp_bots", PLUGIN_VERSION, "Anticamp bots", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
}

public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client) && IsFakeClient(client))
	{
		new Float:mx_pos[3];
		GetClientAbsOrigin(client, mx_pos);
		mx_last_pos[client] = mx_pos;
		CreateTimer(15.0, TimerCheckCamping, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}


public Action TimerCheckCamping(Handle timer, int client)
{
	if(IsValidClient(client))
	{
		new clientteam = GetClientTeam(client);
		if (clientteam == 2 || clientteam == 3)
		{
			new Float:buffer_pos[3];
			new Float:buffer_Distance;
			GetClientAbsOrigin(client, buffer_pos);
			buffer_Distance = GetVectorDistance(buffer_pos, mx_last_pos[client]);
			if (buffer_Distance < 10) KickClient(client, "AFK");
		}
	}
}


bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client)) 
	{
		return true;
	} 
	else 
	{
		return false;
	}
}
