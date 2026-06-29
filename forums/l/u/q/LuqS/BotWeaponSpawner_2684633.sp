#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required
#pragma semicolon 1

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
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("weapon_spawner");
	
	CreateNative("BWS_SpawnWeaponForBots", Native_SpawnWeaponForBots);
	
	return APLRes_Success;
}

public int Native_SpawnWeaponForBots(Handle plugin, int numParams)
{
	char weapon[32];
	
	if(GetNativeString(1, weapon, sizeof(weapon)) != SP_ERROR_NONE)
		ThrowNativeError(SP_ERROR_NATIVE, "[BWS] Native ERROR");
	
	for (int client = 1; client < MaxClients; client++)
		if(IsClientInGame(client) && IsPlayerAlive(client) && IsFakeClient(client))
			GivePlayerItem(client, weapon);
}