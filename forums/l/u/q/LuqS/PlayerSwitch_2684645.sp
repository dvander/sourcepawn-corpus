#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "Team Switcher",
	author = "LuqS",
	description = "Switching player teams every round.",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is for CSGO/CSS only.");
		
	HookEvent("round_prestart", Event_RoundStart, EventHookMode_Pre);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int client = 1; client < MaxClients; client++)
		if(IsClientInGame(client))
		{
			int playerTeam = GetClientTeam(client);
			ChangeClientTeam(client, CS_TEAM_SPECTATOR); // Changing to spectator to avoid suicide. (so it wont kick the player after too many suicides or change the score). 
			ChangeClientTeam(client, (playerTeam == CS_TEAM_T) ? CS_TEAM_CT : CS_TEAM_T); // (IF) Player-Team is T (THEN) CHANGE TO CT (ELSE) CHANGE TO T.
		}
}