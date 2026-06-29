#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "sexy",
	author = "ivailosp",
	description = "huh",
	version = PLUGIN_VERSION,
	url = ""
};

public OnMapEnd()
{
	for(new i = 1; i <= MaxClients; ++i)
	{
		if(IsClientConnected(i) && IsFakeClient(i) && !IsClientInKickQueue(i)){
			KickClient(i);
		}
	}
}