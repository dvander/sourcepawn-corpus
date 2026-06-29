#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "kgbproject(Tetragromaton)"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
//#include <sdkhooks>

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
HookEvent("player_spawn", Fix_Function, EventHookMode_Post);
}

public Action Fix_Function(Event eEvent, const char[] sName, bool bDontBroadcast)
{
	new client = GetClientOfUserId(eEvent.GetInt("userid"));
	TF2_RemoveAllWeapons(client);
	CreateTimer(0.1, BackWeapons, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:BackWeapons(Handle:timer, any:client)
{
	if(IsClientInGame(client) == true)
	{	
	TF2_RegeneratePlayer(client);
   	}
   	return Plugin_Stop;
}