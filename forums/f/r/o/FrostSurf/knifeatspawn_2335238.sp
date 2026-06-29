#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Auto Knife at Spawn",
	author = "Easy987",
	description = "Automatically give knife at spawn.",
	version = "0.3",
	url = "http://www.nincswebem.com"
}

public void OnPluginStart()
{
	HookEvent("player_spawn", SpawnEvent);
}

public Action SpawnEvent(Handle event,const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetPlayerWeaponSlot(client, 2) == -1)
	{
		GivePlayerItem(client, "weapon_knife");
	}
}