#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

ConVar gc_bPlugin;

public Plugin myinfo = {
	name = "VIP Grenades on Spawn",
	author = "shanapu",
	description = "give grenades on spawn for vip",
	version = "0.2",
	url = "https://forums.alliedmods.net/showthread.php?t=300699"
};

public void OnPluginStart()
{
	gc_bPlugin = CreateConVar("sm_spawn_he_enable", "1", "0 - disabled, 1 - enable plugin");
	HookEvent("player_spawn", Event_PlayerSpawn); 
}

public Action Event_PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{
	if(gc_bPlugin.BoolValue)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if (CheckCommandAccess(client, "grenade_flag", ADMFLAG_CUSTOM6, true))
		{
			GivePlayerItem(client, "weapon_hegrenade");
			GivePlayerItem(client, "weapon_smokegrenade");
			GivePlayerItem(client, "weapon_flashbang");
			
			if(GetClientTeam(client) == 3)
			{
				GivePlayerItem(client, "weapon_incgrenade");
			}
			else if(GetClientTeam(client) == 2)
			{
				GivePlayerItem(client, "weapon_molotov");
			}
		}
	}
}