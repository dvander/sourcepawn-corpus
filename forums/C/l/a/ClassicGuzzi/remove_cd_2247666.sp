// ---- Preprocessor -----------------------------------------------------------
#pragma semicolon 1 

// ---- Includes ---------------------------------------------------------------
#include <sourcemod>
#include <tf2_stocks>

// ---- Defines ----------------------------------------------------------------
#define VERSION "1.0"
#define PLAYERCOND_SPYCLOAK (1<<4)

// ---- Variables --------------------------------------------------------------
new bool:isSuddenDeath=false;

public Plugin:myinfo =
{
	name = "Remove C&D",
	author = "Classic",
	description = "Removes last player last player's C&D on sudden death.",
	version = VERSION,
	url = "http://www.clangs.com.ar"
}


public OnPluginStart()
{
	HookEvent("teamplay_round_stalemate", EventSuddenDeathStart);
	HookEvent("teamplay_round_start", EventRoundStart);
	HookEvent("player_death", OnPlayerDeath);
}

public Action:EventSuddenDeathStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	isSuddenDeath=true;
	return Plugin_Continue;
}

public Action:EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	isSuddenDeath=false;
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(isSuddenDeath)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new client_team = GetClientTeam(client);
		
		if(GetAlivePlayersCount(client_team,client) == 1)
			for(new i=1 ; i<=MaxClients ; i++)
				if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(client) == client_team)
				{
					//SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1);
					new TFClassType:iClass = TF2_GetPlayerClass(i);
					if(iClass == TFClass_Spy)
					{
						new wepEnt = GetPlayerWeaponSlot(i, TFWeaponSlot_PDA);
						new wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex"); 
						if(wepIndex == 60) //The Cloak And Dagger
						{
							new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
			
							if (cond & PLAYERCOND_SPYCLOAK)
							{
								SetEntProp(client, Prop_Send, "m_nPlayerCond", cond | ~PLAYERCOND_SPYCLOAK);
							}
							TF2_RemoveWeaponSlot(i, TFWeaponSlot_PDA);
							PrintToChat(i,"[SM] You can't use the Cloak And Dagger in Sudden Death");
						}
					}
					
				}
	}
	
}

stock GetAlivePlayersCount(team,ignore=-1) 
{ 
	new count = 0;

	for(new i = 1; i <= MaxClients; i++ ) 
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == team && i != ignore) 
			count++; 

	return count; 
}  