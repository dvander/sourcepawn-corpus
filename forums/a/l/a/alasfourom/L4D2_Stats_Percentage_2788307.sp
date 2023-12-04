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

int iCommonsKills [MAXPLAYERS+1];
int iSpecialKills [MAXPLAYERS+1];
int iTanksDamages [MAXPLAYERS+1];

int iTotalCommonsKills;
int iTotalSpecialKills;
int iTotalTanksDamages;

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
	HookEvent("infected_death", EVENT_OnCommonInfectedDeath); //For Commons
	HookEvent("player_death", EVENT_OnSpecialDeath); //For Special Infected
	HookEvent("player_hurt", EVENT_OnPlayerHurt); //For Tank Damage
	
	RegConsoleCmd("sm_stats", Command_Stats, "Display Survivors Stats");
}

/* =============================================================================================================== *
 *                                 			   		Round Start													   *
 *================================================================================================================ */

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		iCommonsKills [i] = 0;
		iSpecialKills [i] = 0;
		iTanksDamages [i] = 0;
	}
	
	iTotalCommonsKills = 0;
	iTotalSpecialKills = 0;
	iTotalTanksDamages = 0;
	
	g_bRoundEnd = false;
}

/* =============================================================================================================== *
 *                                 			   		Round End													   *
 *================================================================================================================ */

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_bRoundEnd) 
	{
		DisplaySurvivorsStats();
		g_bRoundEnd = true;
	}
}

/* =============================================================================================================== *
 *                     		 					 Command Stats													   *
 *================================================================================================================ */

public Action Command_Stats(int client, int args)
{
	DisplaySurvivorsStats();
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *                     		 					 	CI Kills													   *
 *================================================================================================================ */

void EVENT_OnCommonInfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!attacker || !IsClientInGame(attacker) || GetClientTeam(attacker) != 2) return;
	
	iCommonsKills[attacker]++;
	iTotalCommonsKills++;
}

/* =============================================================================================================== *
 *                     		 						SI Kills													   *
 *================================================================================================================ */

void EVENT_OnSpecialDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || !IsClientInGame(victim) || GetClientTeam(victim) != 3 || GetEntProp(victim, Prop_Send, "m_zombieClass") == 8) return;
	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!attacker || !IsClientInGame(attacker) || GetClientTeam(attacker) != 2) return;
	
	if(attacker != victim)
	{
		iSpecialKills[attacker]++;
		iTotalSpecialKills++;
		if (iSpecialKills[attacker] > 0) PrintHintText(attacker, "Special Kills: %d", iSpecialKills[attacker]);
	}
}

/* =============================================================================================================== *
 *                     		 			 			Tank Damage													   *
 *================================================================================================================ */

void EVENT_OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int damage = event.GetInt("dmg_health");
	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!attacker || !IsClientInGame(attacker) || GetClientTeam(attacker) != 2) return;
	
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || !IsClientInGame(victim) || GetClientTeam(victim) != 3 || GetEntProp(victim, Prop_Send, "m_zombieClass") != 8) return;
	
	if (damage > 0)
	{
		iTanksDamages [attacker]++;
		iTotalTanksDamages++;
	}
}

/* =============================================================================================================== *
 *                     		 					Display Stats Method											   *
 *================================================================================================================ */

void DisplaySurvivorsStats()
{
	int client;
	int players = 0;
	int[] players_clients = new int[MaxClients+1];
	int iCommonsKillsPercent, iSpecialKillsPercent, iTanksDamagesPercent;
	
	for (client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || GetClientTeam(client) == 3) continue;
		players_clients[players] = client;
		players++;
	}
	
	for (int i = 0; i < players; i++)
	{
		client = players_clients[i];
		
		//Common Kills Percent
		if(iTotalCommonsKills == 0) iCommonsKillsPercent = 0;
		else iCommonsKillsPercent = iCommonsKills[client] * 100 / iTotalCommonsKills;
		
		//Special Infected Kills Percent
		if(iTotalSpecialKills == 0) iSpecialKillsPercent = 0;
		else iSpecialKillsPercent = iSpecialKills[client] * 100 / iTotalSpecialKills;
		
		//Tank Damage Percent
		if (iTotalTanksDamages == 0) iTanksDamagesPercent = 0;
		else iTanksDamagesPercent = iTanksDamages[client] * 100 / iTotalTanksDamages;
		
		PrintToChatAll("\x03%N: \x04Common \x01(%d%%) | \x04SI \x01(%d%%) | \x04Tanks Damage \x01(%d%%)", client, iCommonsKillsPercent, iSpecialKillsPercent, iTanksDamagesPercent);
	}
}