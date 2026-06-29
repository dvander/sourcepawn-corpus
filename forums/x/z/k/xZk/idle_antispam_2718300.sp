#include <sourcemod>
#include <sdktools>

ConVar cvarOn;
ConVar cvarWait;

//float g_fInterval = 3.0;
float g_fTimeAFK[MAXPLAYERS+1];

public void OnPluginStart()
{
	
	cvarOn = CreateConVar("idle_antispam", "1", "Enable plugin?");
	cvarWait = CreateConVar("idle_antispam_wait", "1.0", "Set wait time for again to idle");
	AddCommandListener(CmdListenIdle, "go_away_from_keyboard");
	AddCommandListener(CmdListenIdle, "sm_idle");
	//AddCommandListener(CmdListenIdle, "sm_afk");
}

public Action CmdListenIdle(int client, const char[] command, int argc)
{
	if(!cvarOn.BoolValue)
		return Plugin_Continue;
		
	if(!IsValidSurvivor(client))
		return Plugin_Continue;
		
	float time = GetEngineTime();
	if(!g_fTimeAFK[client]){
		g_fTimeAFK[client] = time;//get 1st time to idle
		return Plugin_Continue;
	}
	
	if((time - g_fTimeAFK[client]) < cvarWait.FloatValue){
		g_fTimeAFK[client] = time;//reset time if spam?
		return Plugin_Stop;
	}
	g_fTimeAFK[client] = time;
	return Plugin_Continue;
}

public OnClientPutInServer(int client){
	g_fTimeAFK[client] = 0.0;
}

stock bool IsValidSurvivor(int client){
	return (IsValidClient(client) && GetClientTeam(client) == 2 );
}

stock bool IsValidClient(int client){
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock bool IsValidEnt(int entity){
	return (entity != INVALID_ENT_REFERENCE && entity > MaxClients && IsValidEntity(entity));
}

