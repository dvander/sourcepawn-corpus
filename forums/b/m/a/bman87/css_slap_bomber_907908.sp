#include <sourcemod>
#include <sdktools>

#define VERSION "1.0"

public Plugin:myinfo =
{
	name = "Bomb planter slap",
	author = "B-man",
	description = "Slaps anyone who starts to plant the bomb",
	version = VERSION,
	url = "http://www.tchalo.com"
}

public OnPluginStart()
{
	HookEvent("bomb_beginplant", hookBombPlant, EventHookMode_Pre);
}

public hookBombPlant(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iUserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(iUserId);
	
	SlapPlayer(client, 0, false);
}