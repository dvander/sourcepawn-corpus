#pragma semicolon 1
#include <sourcemod>
#include <sdktools>


public Plugin:myinfo =
{
	name = "SM Grenade Giver",
	author = "Franc1sco franug",
	description = "",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(1.0, Pasado, client);
}

public Action:Pasado(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		new arma;
		while((arma = GetPlayerWeaponSlot(client, 3)) != -1)
		{
			RemovePlayerItem(client, arma);
			AcceptEntityInput(arma, "Kill");
		}
		
		GivePlayerItem(client, "weapon_hegrenade");
		GivePlayerItem(client, "weapon_smokegrenade");
	
	}
}


