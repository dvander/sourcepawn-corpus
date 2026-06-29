#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "Remove C4",
	author = "DoPe^",
	description = "Removes bomb from the map.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2165975#post2165975"
};

public OnPluginStart()
{
	//Create Public Var for Server Tracking
	CreateConVar("removec4_version", PLUGIN_VERSION, "Version of Remove C4", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//Hook Events
	HookEvent("round_start", OnRoundStart);
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	RemoveC4();
}

RemoveC4()
{
	new ent;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
		{
			ent = GetC4Ent(i);
			
			if (ent != INVALID_ENT_REFERENCE)
			{
				RemovePlayerItem(i, ent);
				PrintToChatAll("C4 was removed on %N", i)
			}
		}
	}
}

GetC4Ent(client)
{
	return GetPlayerWeaponSlot(client, CS_SLOT_C4);
}