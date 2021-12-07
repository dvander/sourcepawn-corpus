/*
	This was a requested plugin by Kumlaserver
	http://forums.alliedmods.net/showthread.php?t=162692
*/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new Health = 150;

public Plugin:myinfo = 
{
	name = "ViP Health and Nade Gift",
	author = "TnTSCS aKa ClarKKent",
	description = "Gives 150 health and an hegrenade to ViP Players with CUSTOM1 flag",
	version = "1.0",
	url = "http://forums.alliedmods.net/showthread.php?t=162692"
}

public OnPluginStart()
{
	CreateConVar("sm_vipgift_build",SOURCEMOD_VERSION, "The version of SourceMod that 'ViP Gift' was compiled with.", FCVAR_PLUGIN);
	CreateConVar("sm_vipgift_version", PLUGIN_VERSION, "The version of 'ViP Gift'", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN);
	
	HookEvent("player_spawn", OnPlayerSpawn);
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
	{
		CreateTimer(0.1, VipGift, client);
	}
	return;
}

public Action:VipGift(Handle:timer, any:client)
{
	SetEntProp(client, Prop_Send, "m_iHealth", Health, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", Health, 1);
	GivePlayerItem(client, "weapon_hegrenade");
}