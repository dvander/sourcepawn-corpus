#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define SOUND_VICTORY "vo/announcer_victory.mp3"
#define SOUND_FAILURE "vo/announcer_you_failed.mp3"

#define TEAM_RED 0
#define TEAM_BLU 1

ConVar cvFlags;


new iTeams[] = {0, 0};

public Plugin:myinfo = {
	name			= "Custom Win",
	author			= "Phil25",
	description	= "Custom round end on CTF without reloading anything.",
};


public OnPluginStart()
	cvFlags = FindConVar("tf_flag_caps_per_round");

public OnMapStart(){

	PrecacheSound(SOUND_VICTORY);
	PrecacheSound(SOUND_FAILURE);

	new ent = -1, String:sTeamName[32];
	while((ent = FindEntityByClassname(ent, "tf_team")) != INVALID_ENT_REFERENCE){
	
		GetEntPropString(ent, Prop_Send, "m_szTeamname", sTeamName, sizeof(sTeamName));
		if(StrEqual(sTeamName, "Red")) iTeams[TEAM_RED] = ent;
		if(StrEqual(sTeamName, "Blue")) iTeams[TEAM_BLU] = ent;
	
	}

	HookEvent("ctf_flag_captured", Event_OnFlagCap, EventHookMode_Pre);

}

public OnMapEnd()
	UnhookEvent("ctf_flag_captured", Event_OnFlagCap, EventHookMode_Pre);

public OnPluginEnd()
	UnhookEvent("ctf_flag_captured", Event_OnFlagCap, EventHookMode_Pre);

public Action:Event_OnFlagCap(Handle:hEvent, const String:sName[], bool:bDontBroadcast){
	
	if(GetEventInt(hEvent, "capping_team_score") == cvFlags.IntValue){
		ResetScore();
		RoundWon(GetEventInt(hEvent, "capping_team"));
	}
	
	return Plugin_Continue;

}

ResetScore(){

	SetEntProp(iTeams[TEAM_RED], Prop_Send, "m_nFlagCaptures", 0);
	SetEntProp(iTeams[TEAM_BLU], Prop_Send, "m_nFlagCaptures", 0);

}

RoundWon(iWinningTeam){

	for(new i = 1; i <= MaxClients; i++){
	
		if(!IsValidClient(i)) continue;
		
		EmitSoundToClient(i, GetClientTeam(i) == iWinningTeam ? SOUND_VICTORY : SOUND_FAILURE);
	
	}

}

stock bool:IsValidClient(client){

	if(client > 4096){
		client = EntRefToEntIndex(client);
	}

	if(client < 1 || client > MaxClients)				return false;

	if(!IsClientInGame(client))						return false;

	if(IsFakeClient(client))							return false;
	
	if(IsClientObserver(client))						return false;
	
	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))	return false;
	
	return true;

}