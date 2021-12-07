/**
 * vim: set ai et ts=4 sw=4 :
 * File: SlapTheStackers.sp
 * Description: Periodically slaps class stackers
 * Author(s): [poni] Shutterfly
 * Versions:
 * 		1.0 : Initial Release
 * 
**/
 
#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "SlapTheStackers",
	author = "[poni] Shutterfly",
	description = "Periodically slaps class stackers",
	version = PLUGIN_VERSION,
	url = ""
}

// cvars
new Handle:cv_SlapTheStackers_MinPlayers=INVALID_HANDLE;
new Handle:cv_SlapTheStackers_PercentageScale=INVALID_HANDLE;
new Handle:cv_SlapTheStackers_Interval=INVALID_HANDLE;
new Handle:cv_SlapTheStackers_Damage=INVALID_HANDLE;

new Handle:Slapper=INVALID_HANDLE;

public OnPluginStart()
{
	new flags = FCVAR_PLUGIN | FCVAR_ARCHIVE;
	
	cv_SlapTheStackers_MinPlayers = CreateConVar("sm_SlapTheStackers_MinPlayers", "4", 
		"Min number of players per team in order to slap them (Min:0, Max:32, Default:4, NB:zero disables slapping)", flags, 
		true, 0.0, true, 32.0);
		
	/**
	 * 0.1 * (4/9=0.4~) = 0.04 [0.16: >1 players = slap]
	 * 0.1 * (16/9=1.7~) = 0.17 [2.72:>3 players = slap]
	 * 
	 * 0.15 * (4/9=0.4~) = 0.6 [0.24:>1]
	 * 0.15 * (16/9=1.7~) = 0.255 [4.08:>4]
	 * 
	 * 0.2 * (4/9=0.4~) = 0.08 [0.32:>1]
	 * 0.2 * (16/9=1.7)=0.34 [5.44:>6]
	 * 
	 * 0.3 * (4/9=0.4~) = 0.12 [0.48: > 1]
	 * 0.3 * (16/9=1.7~) = 0.51 [8.16: > 9]
	**/ 
	cv_SlapTheStackers_PercentageScale = CreateConVar("sm_SlapTheStackers_PercentageScale", "0.15",
		"TeamClassCountLimit = RoundUp( (NumTeamPlayers / 9Classes) * ThisValue ); (Min:0.1, Max:0.9, Default:0.15)", flags,
		true, 0.1, true, 0.9);
		
	cv_SlapTheStackers_Interval = CreateConVar("sm_SlapTheStackers_Interval", "0.5",
		"How often (in seconds) to slap the class stackers. (Min:0.1, Max:300, Default:0.5)", flags,
		true, 0.1, true, 300.0);
	
	cv_SlapTheStackers_Damage = CreateConVar("sm_SlapTheStackers_Damage", "1",
		"How much slap damage players recieve. (Min:0, Max:300, Default:1)", flags,
		true, 0.0, true, 300.0);
	
	HookConVarChange(cv_SlapTheStackers_Interval, ChangeTimer);
}

public OnPluginEnd() {
	OnMapEnd();
}

public OnMapStart() {
	new Float:Interval = GetConVarFloat(cv_SlapTheStackers_Interval);
	Slapper = CreateTimer(Interval, SlapTheStackers, 0, TIMER_REPEAT);
}

public OnMapEnd() {
	if(Slapper != INVALID_HANDLE) { 
		KillTimer(Slapper);
	}
}

public ChangeTimer(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	OnMapEnd();
	OnMapStart();
}

public Action:SlapTheStackers(Handle:timer, any:client) {
	
	// zero disables slapping
	new MinPlayers = GetConVarInt(cv_SlapTheStackers_MinPlayers);
	if( MinPlayers <= 0 ) { return Plugin_Handled; }
	
	new Float:PercentageScale = GetConVarFloat(cv_SlapTheStackers_PercentageScale);
	new Damage = GetConVarInt(cv_SlapTheStackers_Damage);
	
	new i=0;
	new TeamCount[TFTeam + TFTeam:1];
	new ClassCount[TFTeam + TFTeam:1][TFClassType + TFClassType:1];
	new delta=0;
	new TFTeam:team;
	new TFClassType:class;
	
	// initalize
	TeamCount[TFTeam_Red] = 0;
	TeamCount[TFTeam_Blue] = 0;
	for (class=TFClassType:0; class<=TFClassType; class++)
	{
		ClassCount[TFTeam_Red][class] = 0;
		ClassCount[TFTeam_Blue][class] = 0;
	}
	
	// get a head count
	for(i=1; i<=MaxClients; i++) {
		if( IsClientConnected(i) && IsClientInGame(i) ) { // && !IsFakeClient(i) ) {
			team = TFTeam:GetClientTeam(i);
			if( team >= TFTeam_Red ) {
				class = TF2_GetPlayerClass(i);
				TeamCount[team]++;
				ClassCount[team][class]++;
			}
		}			
	}
	
	// find people to slap
	for(i=1; i<=MaxClients; i++) {
		if( IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i) ) {
			team = TFTeam:GetClientTeam(i);
			if( team >= TFTeam_Red ) {
				if( TeamCount[team] >= MinPlayers ) {
					class = TF2_GetPlayerClass(i);
					delta = RoundToCeil( PercentageScale * (Float:TeamCount[team] / Float:TFClassType) );					
					if(delta < 1.0) { delta = 1; }					
					
					if( ClassCount[team][class] > delta) {
						SlapPlayer(i, Damage, true);
						PrintCenterText(i, "[SM] You were slapped for class stacking. You lost %d health.", Damage);
					}
				}
			}
		}			
	}
	
	return Plugin_Handled;
}
