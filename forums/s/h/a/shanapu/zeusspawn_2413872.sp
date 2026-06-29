//includes
#include <sourcemod>
#include <sdktools>

//Compiler Options
#pragma semicolon 1
#pragma newdecls required

//ConVars
ConVar gc_bPlugin;

public Plugin myinfo = {
	name = "VIP Zeus on Spawn",
	author = "shanapu",
	description = "give zeus on spawn for vip",
	version = "0.1",
	url = "shanapu.de"
};

public void OnPluginStart()
{
	CreateConVar("sm_spawnzeus_version", "0.1", "The version of this plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	gc_bPlugin = CreateConVar("sm_spawnzeus_enable", "1", "0 - disabled, 1 - enable plugin");
	
	//Hooks
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action Event_PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{
	if(gc_bPlugin.BoolValue)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (CheckCommandAccess(client, "sm_map", ADMFLAG_RESERVATION, true)) 
		{
			GivePlayerItem(client, "weapon_taser");
		}
	}
}