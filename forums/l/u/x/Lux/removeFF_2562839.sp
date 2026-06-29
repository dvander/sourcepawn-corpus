#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "RemoveFF",
	author = "Lux",
	description = "",
	version = "",
	url = ""
};

public OnPluginStart()
{
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundStart);
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	SetConVarString(FindConVar("survivor_friendly_fire_factor_easy"), "0");
	SetConVarString(FindConVar("survivor_friendly_fire_factor_expert"), "0");
	SetConVarString(FindConVar("survivor_friendly_fire_factor_hard"), "0");
	SetConVarString(FindConVar("survivor_friendly_fire_factor_normal"), "0");
	SetConVarString(FindConVar("grenadelauncher_ff_scale"), "0");
	SetConVarString(FindConVar("survivor_burn_factor_easy"), "0");
	SetConVarString(FindConVar("survivor_burn_factor_normal"), "0");
	SetConVarString(FindConVar("survivor_burn_factor_hard"), "0");
	SetConVarString(FindConVar("survivor_burn_factor_expert"), "0");
}