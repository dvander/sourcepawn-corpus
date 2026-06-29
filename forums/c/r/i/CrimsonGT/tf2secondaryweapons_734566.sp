#include <sourcemod>
#include <tf2_stocks>

new Handle:cEnabled = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "TF2 Secondary Weapons",
	author = "Crimson",
	description = "Strips all weapons on Spawn except Secondary",
	version = "1.0.0",
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	cEnabled = CreateConVar("sm_secondaryweapons_enabled", "1", "Enable/Disable Secondary Weapons Only", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(cEnabled)
	{
		CreateTimer(0.1, Timer_RemoveWeapons, client);
	}
}

public Action:Timer_RemoveWeapons(Handle:timer, any:client)
{
	for(new i=0;i<=5;i++)
	{
		new iSlot = GetPlayerWeaponSlot(client, i);
		
		/* If there is a weapon and its not the secondary */
		if(iSlot != -1)
		{
			if(i != 1)
				TF2_RemoveWeaponSlot(client, i);
		}
	}
}