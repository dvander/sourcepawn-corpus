#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "Auto Knife at Spawn",
	author = "Easy987",
	description = "Automatically give knife at spawn.",
	version = "0.3",
	url = "http://www.nincswebem.com"
}

public OnPluginStart()
{
	HookEvent("player_spawn",SpawnEvent);
}

public Action:SpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GivePlayerItem(client, "weapon_knife");
}