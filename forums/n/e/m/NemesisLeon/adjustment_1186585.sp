#include <sourcemod>
#include <sdktools>

#define MaxClients 32
#define PLUGIN_VERSION "1.0"

#define CVARS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY

#pragma semicolon 1

//plugin info
public Plugin:myinfo = 
{
	name		= "NemesisLeon's adjustment  Mod",
	author		= "NemesisLeon",
	description	= "NemesisLeon's adjustment  Mod",
	version		= PLUGIN_VERSION,
	url			= "http://NemesisLeon.us"
}

new Handle:adjustmentMode;

//plugin setup
public OnPluginStart()
{
	//requires Left 4 Dead 1 or 2
	decl String:Game[64];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "left4dead2", false) && !StrEqual(Game, "left4dead", false))
	{
		SetFailState("This plugin only supports Left 4 Dead 1 or 2.");
	}
	
	adjustmentMode = CreateConVar("l4d_adjustment_enable", "1", "Enable Plugin.", FCVAR_PLUGIN);
	
	if(GetConVarInt(adjustmentMode) == 1)
	{
		SetConVarFloat(FindConVar("intensity_averaged_following_decay"), 5, true);
		SetConVarFloat(FindConVar("intensity_decay_time"), 7.5, true);
		SetConVarFloat(FindConVar("intensity_factor"), 0.75, true);
		SetConVarFloat(FindConVar("z_wandering_density"), 0.06, true);
		SetConVarFloat(FindConVar("survivor_max_incapacitated_count"), 0, true);
		SetConVarFloat(FindConVar("rescue_min_dead_time"), 10, true);
	}
}