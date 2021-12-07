#include <sourcemod>
#include <basecomm>

public Plugin:myinfo = 
{
	name = "[CS:GO] Jailbreak Mute Prisoners",
	author = "Vaggelis",
	description = "Simple plugin that mutes prisoners, except admins.",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn)
	HookEvent("player_death", Event_PlayerDeath)
}

public OnClientPostAdminCheck(client)
{
	if(GetUserAdmin(client) == INVALID_ADMIN_ID)
	{
		BaseComm_SetClientMute(client, true)
	}
	else
	{
		BaseComm_SetClientMute(client, false)
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if(GetClientTeam(client) == 3)
	{
		BaseComm_SetClientMute(client, false)
	}
	
	else if(GetClientTeam(client) == 2)
	{
		if(GetUserAdmin(client) == INVALID_ADMIN_ID)
		{
			BaseComm_SetClientMute(client, true)
		}
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if(GetUserAdmin(client) == INVALID_ADMIN_ID)
	{
		BaseComm_SetClientMute(client, true)
	}
}