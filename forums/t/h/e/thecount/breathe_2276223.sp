#include <sourcemod>
#include <sdktools>

#define SOUND_BREATHE		"player/breathe1.wav"

public OnMapStart(){
	PrecacheSound(SOUND_BREATHE, true);
}

public OnClientPutInServer(client){
	CreateTimer(7.4, Timer_Breathe, client, TIMER_REPEAT);
}

public Action:Timer_Breathe(Handle:timer, any:client){
	if(!IsClientInGame(client)){ return Plugin_Stop; }
	if(IsPlayerAlive(client) && GetClientTeam(client) > 1){
		EmitSoundToAll(SOUND_BREATHE, client, SNDCHAN_AUTO, SNDLEVEL_CONVO);
	}
	return Plugin_Continue;
}