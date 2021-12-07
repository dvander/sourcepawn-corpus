#include <sourcemod>
#include <sdktools>

#define MaxClients 32
#define PLUGIN_VERSION "1.0"

#define CVARS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY

#pragma semicolon 1

//plugin info
public Plugin:myinfo = 
{
	name		= "ispirto's Realism Versus Mod",
	author		= "ispirto",
	description	= "ispirto's Realism Versus Mod",
	version		= PLUGIN_VERSION,
	url			= "http://ispirto.us"
}

new Handle:realismVersusEnabled;

//plugin setup
public OnPluginStart()
{
	//require Left 4 Dead 2
	decl String:Game[64];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "left4dead2", false))
	{
		SetFailState("This plugin only supports Left 4 Dead 2.");
	}
	
	realismVersusEnabled = CreateConVar("l4d2_realism_enabled", "1", "Enable Plugin.", FCVAR_PLUGIN);
	
	if(GetConVarInt(realismVersusEnabled) == 1)
	{
		SetConVarFloat(FindConVar("sv_disable_glow_survivors"), 1, true);
		SetConVarFloat(FindConVar("sv_disable_glow_faritems"), 1, true);
		SetConVarFloat(FindConVar("z_non_head_damage_factor_multiplier"), 0.5, true);
		SetConVarFloat(FindConVar("z_head_damage_causes_wounds"), 1, true);
		SetConVarFloat(FindConVar("z_use_next_difficulty_damage_factor"), 1, true);
		SetConVarFloat(FindConVar("z_witch_always_kills"), 1, true);
	}
}