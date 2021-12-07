#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
	HookEvent("player_spawn", playerSpawn, EventHookMode_Post);
}

public Action:playerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	CreateTimer(0.5, giveItems, client);
	CloseHandle(event);
	return Plugin_Continue;
}

public Action:giveItems(Handle:timer, any:client)
{
	decl String:sID[32];
	GetClientAuthId(client, AuthId_Steam2, sID, sizeof(sID));
	new AdminId:aFlags = FindAdminByIdentity(AUTHMETHOD_STEAM, sID);
	if(GetAdminFlag(aFlags, Admin_Custom1))
	{
		GivePlayerItem(client, "weapon_ak47");
		GivePlayerItem(client, "weapon_deagle");
		GivePlayerItem(client, "weapon_hegrenade");
		GivePlayerItem(client, "weapon_flashbang");
		GivePlayerItem(client, "weapon_smokegrenade");
	}
}