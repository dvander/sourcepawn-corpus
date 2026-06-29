#pragma semicolon 1

#include <sourcemod>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Advert Armor", 
	author = "Kolapsicle", 
	description = "Gives players bonus armor for server advertisements.", 
	version = "1.0.0"
};

ConVar g_cvAdvert, g_cvMatchCase, g_cvArmorReward;

public void OnPluginStart()
{
	g_cvAdvert = CreateConVar("sm_aa_advert", "alliedmods.net", "Advertisement to search for in players' names.");
	g_cvMatchCase = CreateConVar("sm_aa_match_case", "0", "Determines if the advertisement should be case-sensitive.");
	g_cvArmorReward = CreateConVar("sm_aa_armor_reward", "10", "Amount of armor to reward players.");
	AutoExecConfig(true, "advert_armor");
}

public Action CS_OnBuyCommand(int client, const char[] weapon)
{
	if (!IsValidClient(client))
	{
		return Plugin_Continue;
	}
	
	if (!StrEqual("kevlar", weapon) && !StrEqual("assaultsuit", weapon))
	{
		return Plugin_Continue;
	}
	
	if (StrEqual("assaultsuit", weapon) && GetEntProp(client, Prop_Send, "m_bHasHelmet"))
	{
		return Plugin_Continue;
	}
	else if (StrEqual("kevlar", weapon) && GetClientArmor(client) >= 100)
	{
		return Plugin_Continue;
	}
	
	if (!IsClientAdvertising(client))
	{
		return Plugin_Continue;
	}
	
	// Delay addition until client has armor.
	RequestFrame(AddArmorFrame, GetClientUserId(client));
	return Plugin_Continue;
}

void AddArmorFrame(int userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client))
	{
		return;
	}
	
	SetEntProp(client, Prop_Send, "m_ArmorValue", GetClientArmor(client) + GetConVarInt(g_cvArmorReward));
	PrintToChat(client, "[SM] You've been awarded +%d armor for supporting the server!", GetConVarInt(g_cvArmorReward));
}

bool IsClientAdvertising(int client)
{
	char name[MAX_NAME_LENGTH], advert[MAX_NAME_LENGTH];
	
	GetClientName(client, name, sizeof(name));
	g_cvAdvert.GetString(advert, MAX_NAME_LENGTH);
	
	if (StrContains(name, advert, GetConVarBool(g_cvMatchCase)) == -1)
	{
		return false;
	}
	
	return true;
}

bool IsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client);
} 