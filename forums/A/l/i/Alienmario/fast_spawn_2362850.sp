#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "fastspawn",
	author = "Alienmario",
	description ="fastspawn for players",
	version = "1.0"
};

new Handle:sm_fastspawn = INVALID_HANDLE;
new Handle:sm_fastspawn_time = INVALID_HANDLE;

float nextSpawn[MAXPLAYERS+1];


public OnPluginStart(){
	sm_fastspawn = CreateConVar("sm_fastspawn","1","Enables player respawn [sm_fastspawn_time] seconds after death",FCVAR_PLUGIN,true,0.0,true,1.0);
	sm_fastspawn_time = CreateConVar("sm_fastspawn_time","0.5","Sets how long to wait until player can respawn",FCVAR_PLUGIN,true,0.0,true,5.0)

	AutoExecConfig(true);
	HookEvent("player_death", Event_Death);	
}

public OnClientPutInServer(client){
	nextSpawn[client] = 0.0;
}

public Action:OnPlayerRunCmd(client, &Buttons, &impulse, Float:vel[3], Float:angles[3], &weapon){
	if(GetConVarBool(sm_fastspawn)){
		if(!IsPlayerAlive(client) && GetGameTime()>=nextSpawn[client]){
			if(Buttons & IN_ATTACK||Buttons & IN_JUMP||Buttons & IN_DUCK||Buttons & IN_FORWARD||Buttons & IN_BACK||Buttons & IN_ATTACK2)
			{
				DispatchSpawn(client);
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_Death (Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsPlayerAlive(client)){ //dying, (take only first death)
		nextSpawn[client] = GetGameTime() + GetConVarFloat(sm_fastspawn_time);
	}
	return Plugin_Continue;
}