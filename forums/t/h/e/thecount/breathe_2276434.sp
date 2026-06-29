#include <sourcemod>
#include <sdktools>

#define SOUND_BREATHE		"player/breathe1.wav"

new Float:BREATHE_VOLUME = 1.0;

public OnPluginStart(){
	HookConVarChange((CreateConVar("sm_breathe_vol", "1.0", "Breathe Volume(1.0 is default)")), ConVarChanged);
}

public ConVarChanged(Handle:convar, const String:oldVal[], const String:newVal[]){
	BREATHE_VOLUME = StringToFloat(newVal);
	if(BREATHE_VOLUME > 1.0){ BREATHE_VOLUME = 1.0;}
	if(BREATHE_VOLUME < 0.0){ BREATHE_VOLUME = 0.0;}
}

public OnMapStart(){
	PrecacheSound(SOUND_BREATHE, true);
}

public OnClientPutInServer(client){
	CreateTimer(7.4, Timer_Breathe, client, TIMER_REPEAT);
}

public Action:Timer_Breathe(Handle:timer, any:client){
	if(!IsClientInGame(client)){ return Plugin_Stop; }
	if(IsPlayerAlive(client) && GetClientTeam(client) == 2){
		for(new i=1;i<=MaxClients;i++){
			if(IsClientInGame(i) && i != client){
				EmitSoundToClient(client, SOUND_BREATHE, client, SNDCHAN_AUTO, SNDLEVEL_WHISPER, SND_CHANGEVOL, BREATHE_VOLUME);
			}
		}
	}
	return Plugin_Continue;
}