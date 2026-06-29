#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "[TF2] No No Spread",
	author = "Pelipoika",
	description = "Breaks No-Spread",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	CreateConVar("sm_nonospread_version", PLUGIN_VERSION, "No No Spread version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_PLUGIN);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(IsPlayerAlive(client))
	{
		seed = GetRandomInt(0, 2000000000);

		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}