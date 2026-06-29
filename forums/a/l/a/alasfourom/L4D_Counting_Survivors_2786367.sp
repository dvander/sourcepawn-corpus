#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "L4D Survivors Counter",
	author = "alasfourom",
	description = "Counting Survivors",
	version = "1.0",
	url = "https://forums.alliedmods.net/"
}

public void OnPluginStart() 
{
	HookEvent("defibrillator_used", EVENT_PlayerDefib);
	HookEvent("player_death", EVENT_PlayerDeath);
}

public void EVENT_PlayerDefib(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("subject"));
	if (!victim || !IsClientInGame(victim) || GetClientTeam(victim) != 2) return;
	
	int savior = GetClientOfUserId(event.GetInt("userid"));
	if (!savior || !IsClientInGame(savior) || GetClientTeam(savior) != 2) return;
	
	int number = GetSurvivorsCount(savior);
	if (number > 0) 
	{
		PrintHintTextToAll("%N Defibrillated %N\nSurvivors Alive: %d", savior, victim, number);
		PrintToChatAll("\x04[Announcement] \x03%N \x01Defibrillated \x03% \x01| Survivors Alive: \x05%d", savior, victim, number);
	}
}

public void EVENT_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || !IsClientInGame(victim)) return;
	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!attacker || !IsClientInGame(attacker)) return;
	
	int number = GetSurvivorsCount(victim);
	if (number > 0 && GetClientTeam(victim) == 2)
	{
		if (victim == attacker)
		{
			PrintHintTextToAll("%N Has Died\nSurvivors Alive: %d", victim, number);
			PrintToChatAll("\x04[Announcement] \x03%N \x01Has Died | Survivors Alive: \x05%d", victim, number);
		}
		
		else 
		{
			PrintHintTextToAll("%N Killed %N\nSurvivors Alive: %d", attacker, victim, number);
			PrintToChatAll("\x04[Announcement] \x03%N \x01Killed \x03%N \x01| Survivors Alive: \x05%d", attacker, victim, number);
		}
	}
}

stock int GetSurvivorsCount(int client)
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
			number++;
	}
	return number;
}