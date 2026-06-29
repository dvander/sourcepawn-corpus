#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required
#pragma semicolon 1

ConVar g_cvEnabled;
ConVar g_cvWeapon;

public Plugin myinfo = 
{
	name = "Bot Weapon spawner",
	author = "LuqS",
	description = "Gives a specific item to all bots",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	// Not gonna waste time :D //
	if(GetEngineVersion() != Engine_CSGO) 
		SetFailState("This plugin is for CSGO only.");
		
	g_cvEnabled = CreateConVar("bws_enabled", "1", "Whether the 'Bot Weapon Spawner' Plugin is enabled");
	g_cvWeapon = CreateConVar("bws_weapon", "ak47", "Weapon to give");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(g_cvEnabled.BoolValue && IsClientInGame(client) && IsPlayerAlive(client) && IsFakeClient(client))
	{
		char weapon[32];
		g_cvWeapon.GetString(weapon, sizeof(weapon));
		Format(weapon, sizeof(weapon), "weapon_%s", weapon);
		
		if(GivePlayerItem(client, weapon) == -1)
			PrintToServer("Failed to give %N weapon - %s", client, weapon);
	}
}