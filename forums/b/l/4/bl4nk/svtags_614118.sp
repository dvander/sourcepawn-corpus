#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.1"

new Handle:Convar;

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
	Convar = FindConVar("sv_tags");
	flags  = GetConVarFlags(Convar);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(Convar, flags);

	HookConVarChange(Convar, cvarChange);
	CreateTimer(0.1, changeSvTags);
}

public cvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (newValue[0] != '\0')
		SetConVarString(Convar, "\0");
}

public Action:changeSvTags(Handle:timer)
{
	SetConVarString(Convar, "\0");
}