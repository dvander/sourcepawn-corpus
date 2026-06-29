#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

int leader;
int killer;

public Plugin myinfo =
{
	name = "[CS:GO] Chicken Leader",
	author = "Kento",
	version = "1.0",
	description = "Make all chicken follow random player",
	url = "http://steamcommunity.com/id/kentomatoryoshika/"
};

public void OnPluginStart() 
{
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(killer != -1 && IsValidClient(killer))	PrintToChatAll("%N win the round", killer);
	killer = -1;
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	leader = GetRandomPlayer();
	
	// PrintToChatAll("Leader is %N", leader);
	
	int ent = -1;
	while((ent = FindEntityByClassname(ent, "chicken")) != -1)
	{
		SetEntPropEnt(ent, Prop_Send, "m_leader", leader);
	}
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(victim == leader)	killer = attacker;
}

// Edit from
// https://forums.alliedmods.net/showpost.php?p=2448824&postcount=2
stock int GetRandomPlayer()
{
	int clients[MAXPLAYERS  + 1];
	int clientCount;
	
	for (int i = 1; i <= MAXPLAYERS ; i++)
	{
		if(IsValidClient(i))	clients[clientCount++] = i;
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)];
}  

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}