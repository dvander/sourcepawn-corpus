#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "surv",
	author = "ivailosp",
	description = "huh",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	new Handle:surv_l = FindConVar("survivor_limit");
	SetConVarBounds(surv_l , ConVarBound_Upper, true, 8.0);
	ServerCommand("sm_cvar survivor_limit 8");
	//new Handle:z_l = FindConVar("z_max_player_zombies");
	//SetConVarBounds(z_l , ConVarBound_Upper, true, 8.0);
	//ServerCommand("sm_cvar z_max_player_zombies 8");
}
 
