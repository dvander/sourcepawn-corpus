#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

new Handle:convar;

public Plugin:myinfo =
{
	name        = "svtags",
	author      = "bl4nk",
	description = "Removes all information stored in 'sv_tags'",
	version     = PLUGIN_VERSION,
	url         = "http://forums.joe.to"
};

public OnPluginStart()
{
	CreateConVar("sm_svtags_version", PLUGIN_VERSION, "svtags Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	new flags;
	convar = FindConVar("sv_tags");
	flags  = GetConVarFlags(convar);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(convar, flags);
}

public OnGameFrame()
	SetConVarString(convar, "\0");