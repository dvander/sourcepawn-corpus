#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PL_VERSION "0.4"

#define DISGUISED 8
//#define BAMPERSAND 

#if defined BAMPERSAND
	new g_Pies[MAXPLAYERS+1];
#endif

public Plugin:myinfo = 
{
	name = "FistPie",
	author = "Darkimmortal",
	description = "Fixes server crashes caused by spies disguised as friendly heavies with fists.",
	version = PL_VERSION,
	url = "http://www.gamingmasters.co.uk/"
}

public OnPluginStart(){
	CreateConVar("sm_fistpie_version", PL_VERSION, "FistPie Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);	
	CreateTimer(1.0, Timer_Spycheck, _, TIMER_REPEAT);
}

#if defined BAMPERSAND
	public OnClientConnected(client){
		g_Pies[client] = 0;
	}
#endif

public Action:Timer_Spycheck(Handle:timer, any:hurr){	
	decl String:steamid[30];
	for(new i=1; i<=MaxClients; i++) {
		if(IsClientInGame(i) && IsPlayerAlive(i)){
			if((GetEntProp(i, Prop_Send, "m_nPlayerCond") & DISGUISED) && GetClientTeam(i) == GetEntProp(i, Prop_Send, "m_nDisguiseTeam") && TFClassType:GetEntProp(i, Prop_Send, "m_nDisguiseClass") == TFClass_Heavy){
				#if defined BAMPERSAND
					g_Pies[i] ++;
					if(g_Pies[i] > 2){
						BanClient(i, 30, BANFLAG_AUTO, "[FistPie] Attempting to crash the server by disguising as a friendly heavy.", "30 minute ban for attempting to crash the server by disguising as a friendly heavy", "sm_ban");
					} else {
				#endif
						PrintToChat(i, "[FistPie] You are not permitted to disguise as a friendly heavy on this server. You will be banned if you continue trying.");
						TF2_RemovePlayerDisguise(i);
						GetClientAuthString(i, steamid, sizeof(steamid));
						LogAction(i, -1, "%N (%s) attempted FistPie Exploit.", i, steamid);
				#if defined BAMPERSAND
					}
				#endif
			}
		} 
	}
	return Plugin_Continue;
}