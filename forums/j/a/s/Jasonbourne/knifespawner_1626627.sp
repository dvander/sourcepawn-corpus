#pragma semicolon 1
#include <sdktools>


#define PLUGIN_NAME "knifespawner"
#define PLUGIN_AUTHOR "Jason Bourne"
#define PLUGIN_DESC "Gives player a knife"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_SITE "www.immersion-networks.com"

new Handle:sm_knifegiver_enable = INVALID_HANDLE;
new bool:allow[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_SITE
}

public OnPluginStart()
{
	RegConsoleCmd("sm_knife", Command_knife, "Spawns you a knife");
	RegConsoleCmd("sm_kn", Command_knife, "Spawns a knife for a fat lazy man");
	sm_knifegiver_enable = CreateConVar("sm_knifegiver_enable", "1", "Enable Knife Giver. [0 = FALSE, 1 = TRUE]");
	
}
public OnMapStart()
{
	for(new i = 0; i <= MAXPLAYERS; i++){
		allow[i]=true;
	}
	
}
	

public Action:Command_knife(client,args)
{
	if(GetConVarBool(sm_knifegiver_enable)) // if plugin is enabled 
	{
		if(allow[client]==true)
		{
		GivePlayerItem(client,"weapon_knife");
		allow[client]=false;
		CreateTimer(30.0, Action_allowknife, client);
		}
		else
		{
		PrintToChat(client,"You must wait 30 seconds between spawning knifes");
		}
		
	}
	else
	{
	PrintToChat(client,"Knife Spawner is not enabled");
	}
	
}

public Action:Action_allowknife(Handle:timer, any:client)
{
	allow[client]=true;
}
