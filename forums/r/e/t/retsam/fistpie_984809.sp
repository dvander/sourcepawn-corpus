#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PL_VERSION "0.3"

#define DISGUISED 8

new String:logFile[256];

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
	
  BuildPath(Path_SM, logFile, sizeof(logFile), "logs/fistpie.log");
}

public Action:Timer_Spycheck(Handle:timer, any:hurr){	
	for(new i=1; i<=MaxClients; i++) {
		if(IsClientInGame(i) && IsPlayerAlive(i)){
			if((GetEntProp(i, Prop_Send, "m_nPlayerCond") & DISGUISED) && GetClientTeam(i) == GetEntProp(i, Prop_Send, "m_nDisguiseTeam") && TFClassType:GetEntProp(i, Prop_Send, "m_nDisguiseClass") == TFClass_Heavy){
				decl String:sSteamID[64];
        GetClientAuthString(i, sSteamID, sizeof(sSteamID));
        
        PrintToChat(i, "[FistPie] Disguising as a friendly heavy is not permitted. Your [%s] has been logged.", sSteamID);
        LogToFile(logFile, "%N [%s] attempted FistPie crash exploit.", i, sSteamID);
        //LogAction(i, -1, "%N [%s] attempted SpyHeavyFist crash Exploit.", i, sSteamID);
        TF2_RemovePlayerDisguise(i);
			}
		} 
	}
	return Plugin_Continue;
}