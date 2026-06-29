#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION 	"1.00"

#define SURVIVOR	2
#define ZOMBIE		3
#define READY		4

/* ChangeLog
1.00	Created
*/

public Plugin:myinfo =
{
	name = "ZPS Target Groups",
	author = "Will2Tango",
	description = "Allows Admins to Target ZPS Teams.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("zps_target_version", PLUGIN_VERSION, "Version of ZPS Target Groups", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	AddMultiTargetFilter("@st", FilterSurvivor, "All Survivors", false);
	AddMultiTargetFilter("@zt", FilterZombie, "All Zombies", false);
	AddMultiTargetFilter("@ready", FilterReady, "All Ready Room", false);
}

public bool:FilterSurvivor(const String:pattern[], Handle:clients)
{
	for (new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == SURVIVOR)
		{
			PushArrayCell(clients, i);
		}
	}
	
	return true;
}

public bool:FilterZombie(const String:pattern[], Handle:clients)
{
	for (new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == ZOMBIE)
		{
			PushArrayCell(clients, i);
		}
	}
	
	return true;
}

public bool:FilterReady(const String:pattern[], Handle:clients)
{
	for (new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == READY)
		{
			PushArrayCell(clients, i);
		}
	}
	
	return true;
}