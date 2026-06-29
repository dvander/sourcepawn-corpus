#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.0.0"



public Plugin:myinfo =
{
	name = "Silent Disconnect",
	author = "Puppetmaster",
	description = "Suppresses disconnect message because chat spam is annoying AF.",
	version = PLUGIN_VERSION,
	url = "https://www.gamingzoneservers.com"
};

public OnPluginStart()
{
	//Basically this thread without the bloat: https://forums.alliedmods.net/showthread.php?t=237008
	HookEvent("player_disconnect", stfu, EventHookMode_Pre);
}

public Action:stfu(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Because chat spam is annoying	
	SetEventBroadcast(event, true);
	return Plugin_Continue;
}
