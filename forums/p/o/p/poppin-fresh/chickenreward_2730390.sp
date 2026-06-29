#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Poppin-Fresh"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required


public Plugin myinfo = 
{
	name = "Chicken Money Reward", 
	author = PLUGIN_AUTHOR, 
	description = "Receive x amounnt of dolars for killing a chicken", 
	version = PLUGIN_VERSION, 
	url = "alliedmods.net"
};

ConVar RewardAmount;

public void OnPluginStart()
{
	HookEvent("other_death", Event_OtherDeath);
	RewardAmount = CreateConVar("sm_chickenreward", "100", "Amount of money to receive for killing a chicken");
	
	
}

public Action Event_OtherDeath(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsClientInGame(player))
	{
		return Plugin_Continue;
	}
	
	char chicken[32];
	event.GetString("othertype", chicken, 32);
	
	if (strcmp(chicken, "chicken", false) == 0)
	{
		PrintToChat(player, "[SM] You've been rewarded with $%d for killing a chicken", RewardAmount.IntValue);
		int currentCash = GetEntProp(player, Prop_Send, "m_iAccount");
		SetEntProp(player, Prop_Send, "m_iAccount", currentCash + RewardAmount.IntValue);
		int score = CS_GetClientContributionScore(player);
		CS_SetClientContributionScore(player, score + 1);
	}
	
	return Plugin_Continue;
} 