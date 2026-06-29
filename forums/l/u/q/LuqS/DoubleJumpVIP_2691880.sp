#include <sourcemod>
#include <cstrike>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "[VIP] Exo-Jump", 
	author = "LuqS",
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/LuqSGood"
};

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is for CSGO only.");
	
	HookEvent("player_death", Event_PlayerDeath);
}

public Action Command_ExoJump(int client, int args)
{
	if(IsValidClient(client) && CheckCommandAccess(client, "ExoJumpAccess", ADMFLAG_CUSTOM1))
		SetEntProp(client, Prop_Send, "m_passiveItems", 1, 1, 1);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client))
		SetEntProp(client, Prop_Send, "m_passiveItems", 0, 1, 1);
}

stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client) || (IsFakeClient(client) && !bAllowBots) || (!bAllowDead && !IsPlayerAlive(client)))
		return false;
	return true;
}