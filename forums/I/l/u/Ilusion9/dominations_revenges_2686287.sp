#include <sourcemod>
#include <sdktools>
#include <colorlib_sample>
#pragma newdecls required

public Plugin myinfo =
{
	name = "Dominations and Revenges",
	author = "Ilusion9",
	description = "Print to chat if a player is dominating or it took revenge.",
	version = "1.0",
	url = "https://github.com/Ilusion9/"
};


int g_ConsecutiveKills[MAXPLAYERS + 1][MAXPLAYERS + 1];
ConVar g_Cvar_DominationKills;

public void OnPluginStart()
{
	LoadTranslations("dominations_revenges.phrases");
	g_Cvar_DominationKills = CreateConVar("sm_dominations_kills", "4", "After how many consecutive kills players are dominating?", FCVAR_NONE, true, 0.0);
	HookEvent("player_death", Event_PlayerDeath);
}

public void OnClientConnected(int client)
{
	for (int i = 1; i < MAXPLAYERS + 1; i++)
	{
		g_ConsecutiveKills[client][i] = 0;
		g_ConsecutiveKills[i][client] = 0;
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));	
	if (!victim)
	{
		return;
	}
	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!attacker || attacker == victim)
	{
		return;
	}

	bool tookRevenge = g_ConsecutiveKills[victim][attacker] >= g_Cvar_DominationKills.IntValue;
	g_ConsecutiveKills[attacker][victim]++
	g_ConsecutiveKills[victim][attacker] = 0;
	
	if (tookRevenge)
	{
		char victimName[MAX_NAME_LENGTH], attackerName[MAX_NAME_LENGTH];
		GetClientName(victim, victimName, sizeof(victimName));
		GetClientName(attacker, attackerName, sizeof(attackerName));
		
		PrintToChat(attacker, "%t", "You Took Revenge", victimName);
		PrintToChat(victim, "%t", "Player Took Revenge on You", attackerName);
		return;
	}
	
	int consKills = g_ConsecutiveKills[attacker][victim];
	if (consKills < g_Cvar_DominationKills.IntValue)
	{
		return;
	}
	
	char victimName[MAX_NAME_LENGTH], attackerName[MAX_NAME_LENGTH];
	GetClientName(victim, victimName, sizeof(victimName));
	GetClientName(attacker, attackerName, sizeof(attackerName));
	
	if (consKills == g_Cvar_DominationKills.IntValue)
	{
		PrintToChat(victim, "%t", "Is Dominating You", attackerName);
		PrintToChat(attacker, "%t", "You Are Dominating", victimName);
		return;
	}
	
	PrintToChat(victim, "%t", "Is Still Dominating You", attackerName);
	PrintToChat(attacker, "%t", "You Are Still Dominating", victimName);
}