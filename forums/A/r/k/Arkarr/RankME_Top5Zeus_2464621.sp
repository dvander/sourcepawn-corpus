#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <rankme>

#define PLUGIN_AUTHOR "Arkarr"
#define PLUGIN_VERSION "1.00"

public Plugin myinfo = 
{
	name = "[CSGO] Rank me Zeus",
	author = PLUGIN_AUTHOR,
	description = "Give a zeus if the player is in the top 5 player",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is only for CS:GO !");
		
	HookEvent("player_spawn", OnPlayerSpawn);
}

public void OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int userID = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userID);
	
	if(!IsValidClient(client))
		return;
		
	RankMe_GetRank(client, RankME_GetRank, userID);
}

public int RankME_GetRank(int client, int rank, any data) 
{  
	if(rank > 5)		
		CreateTimer(0.5, TMR_GiveZeus, data);
}

public Action TMR_GiveZeus(Handle tmr, any userID)
{
	int client = GetClientOfUserId(userID);
	int wepIndex = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	
	if(IsValidClient(client) && wepIndex != -1)
	{
		CS_DropWeapon(client, wepIndex, true, true);
		GivePlayerItem(client, "weapon_taser");
	}
}

stock bool IsValidClient(iClient, bool bReplay = true)
{
	if (iClient <= 0 || iClient > MaxClients)
		return false;
	if (!IsClientInGame(iClient))
		return false;
	if (bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
		
	return true;
}
