/* =============================================================================================================== *
 *											Includes, Pragmas and Defines			   							   *
 *================================================================================================================ */

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.0"

/* =============================================================================================================== *
 *									Plugin Variables - Float, Int, Bool, ConVars			   					   *
 *================================================================================================================ */

bool g_bRoundEnd;

int SI_KillCount 	[MAXPLAYERS+1];
int CI_KillCount	[MAXPLAYERS+1];
int Boss_KillCount	[MAXPLAYERS+1];
int TH_SaveCount 	[MAXPLAYERS+1];

/* =============================================================================================================== *
 *                                		 		 	Plugin Info													   *
 *================================================================================================================ */

public Plugin myinfo =
{
	name = "L4D Simple MVP",
	author = "alasfourom",
	description = "Simple MVP Statistics",
	version = "1.0",
	url = "https://forums.alliedmods.net/"
}

/* =============================================================================================================== *
 *                     		 		 			 Plugin Start													   *
 *================================================================================================================ */

public void OnPluginStart() 
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", EVENT_OnSpecialDeath);
	HookEvent("infected_death", EVENT_OnCommonInfectedDeath);
	HookEvent("tank_killed", EVENT_OnTankDeath);
	HookEvent("witch_killed", EVENT_OnWitchDeath);
	HookEvent("revive_success", EVENT_PlayerHelp);
	HookEvent("heal_success", EVENT_PlayerHelp);
	
	RegConsoleCmd("sm_stats", Command_Stats, "Display Survivors Stats");
}

/* =============================================================================================================== *
 *                                 			   		Round Start													   *
 *================================================================================================================ */

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundEnd = false;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		CI_KillCount	[i] = 0;
		SI_KillCount 	[i] = 0;
		Boss_KillCount	[i] = 0;
		TH_SaveCount 	[i] = 0;
	}
}

/* =============================================================================================================== *
 *                     		 						 Round End													   *
 *================================================================================================================ */
 
void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_bRoundEnd) 
	{
		MVP_Display(); //Display Players With MVP
		g_bRoundEnd = true;
	}
}

/* =============================================================================================================== *
 *                     		 					 Command Stats													   *
 *================================================================================================================ */

public Action Command_Stats(int client, int args)
{
	MVP_Display();
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *                     		 					 MVP: CI Kills													   *
 *================================================================================================================ */

public void EVENT_OnCommonInfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!attacker || !IsClientInGame(attacker)) return;
	
	if(GetClientTeam(attacker) == 2)
	{
		CI_KillCount[attacker]++;
		if (CI_KillCount[attacker] > 0) PrintHintText(attacker, "Common Kills: %d", CI_KillCount[attacker]);
	}
}

/* =============================================================================================================== *
 *                     		 					 MVP: SI Kills													   *
 *================================================================================================================ */

public void EVENT_OnSpecialDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || !IsClientInGame(victim) || IsTank(victim)) return;
	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!attacker || !IsClientInGame(attacker)) return;
	
	if(attacker != victim && GetClientTeam(attacker) == 2)
	{
		SI_KillCount[attacker]++;
		if (SI_KillCount[attacker] > 0) PrintHintText(attacker, "Special Kills: %d", SI_KillCount[attacker]);
	}
}

/* =============================================================================================================== *
 *                     		 					 MVP: Boss Kills												   *
 *================================================================================================================ */

void EVENT_OnWitchDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (!attacker || !IsClientInGame(attacker)) return;
	
	if(GetClientTeam(attacker) == 2)
	{
		Boss_KillCount[attacker]++;
		if (Boss_KillCount[attacker] > 0) PrintHintText(attacker, "Boss Kills: %d", Boss_KillCount[attacker]);
	}
}

void EVENT_OnTankDeath(Event event, const char[] name, bool dontBroadcast)
{
	int tank = GetClientOfUserId(event.GetInt("userid"));
	if (!tank || !IsClientInGame(tank)) return;
	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!attacker || !IsClientInGame(attacker)) return;
	
	if(attacker != tank && GetClientTeam(attacker) == 2)
	{
		Boss_KillCount[attacker]++;
		if (Boss_KillCount[attacker] > 0) PrintHintText(attacker, "Boss Kills: %d", Boss_KillCount[attacker]);
	}
}

/* =============================================================================================================== *
 *                     		 					 MVP: Team Helps												   *
 *================================================================================================================ */

void EVENT_PlayerHelp(Event event, const char[] name, bool dontBroadcast)
{
	int savior = GetClientOfUserId(event.GetInt("userid"));
	if (!savior || !IsClientInGame(savior)) return;
	
	int victim = GetClientOfUserId(event.GetInt("subject"));
	if (!victim || !IsClientInGame(victim)) return;
	
	if(savior != victim && GetClientTeam(savior) == 2)
	{
		TH_SaveCount[savior]++;
		if (SI_KillCount[savior] > 0) PrintHintText(savior, "Team Helps: %d", TH_SaveCount[savior]);
	}
}

/* =============================================================================================================== *
 *                     		 		 MVP Display Method > Credits HarryPotter									   *
 *================================================================================================================ */

void MVP_Display()
{
	int client;
	int players = 0;
	int[] players_clients = new int[MaxClients+1];
	int CI_KillCount_MVP, SI_KillCount_MVP, Boss_KillCount_MVP, TH_SaveCount_MVP;
	
	for (client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || GetClientTeam(client) == 3) continue;
		players_clients[players] = client;
		players++;
	}
	
	SortCustom1D(players_clients, players, SortDescending);
	for (int i = 0; i < players; i++)
	{
		client				= players_clients	[i];
		CI_KillCount_MVP	= CI_KillCount		[client];
		SI_KillCount_MVP	= SI_KillCount		[client];
		Boss_KillCount_MVP	= Boss_KillCount	[client];
		TH_SaveCount_MVP	= TH_SaveCount		[client];
		
		PrintToChatAll("\x03%N: \x04CI Kills \x01%d | \x04SI Kills \x01%d | \x04Boss Kills \x01%d | \x04Team Helps \x01%d", client, CI_KillCount_MVP, SI_KillCount_MVP, Boss_KillCount_MVP, TH_SaveCount_MVP);
	}
}

int SortDescending(int elem1, int elem2, const int[] array, Handle hndl)
{
	if (SI_KillCount[elem1] > SI_KillCount[elem2]) return -1;
	else if (SI_KillCount[elem2] > SI_KillCount[elem1]) return 1;
	else if (elem1 > elem2) return -1;
	else if (elem2 > elem1) return 1;
	return 0;
}

/* =============================================================================================================== *
 *                     		 						 Check Tank													   *
 *================================================================================================================ */

bool IsTank(int client)
{
    return (client > 0 
        && client <= MaxClients 
        && IsClientInGame(client) 
        && GetClientTeam(client) == 3 
        && GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}