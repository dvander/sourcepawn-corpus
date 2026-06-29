#include <sourcemod>

public Plugin:myinfo =
{
	name = "cvars for zombies",
	author = "youfake",
	description = "on spawn set some cvars",
	version = "1.0",
	url = "http://sourcemod.net",
}

new Handle:H_turbo;
new Handle:H_phys;

public OnPluginStart()
{
	CreateConVar("sm_setcvars", "1.0", "version of this plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	H_turbo = FindConVar("sv_turbophysics");
	H_phys = FindConVar("phys_pushscale");
}

public OnMapStart()
{
	SetConVarBool(H_turbo, 1);
	SetConVarBool(H_phys, 2);
}