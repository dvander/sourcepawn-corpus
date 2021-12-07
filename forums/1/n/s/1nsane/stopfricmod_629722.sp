#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0" 
#define FCVAR_DEVELOPMENTONLY	(1<<1)
#define FCVAR_HIDDEN			(1<<4)
public Plugin:myinfo =
{
	name        = "Friction/Stop Speed Modifier",
	description = "Allows modification of sv_friction and sv_stopspeed",
	version     = PLUGIN_VERSION
};

public OnPluginStart()
{
	new Handle:convar;
	new flags;
	convar = FindConVar("sv_friction");
	flags  = GetConVarFlags(convar);
	flags &= ~FCVAR_NOTIFY;
        flags &= ~FCVAR_CHEAT;
        flags &= ~FCVAR_DEVELOPMENTONLY;
        flags &= ~FCVAR_HIDDEN;
	SetConVarFlags(convar, flags);
	convar = FindConVar("sv_stopspeed");
	flags  = GetConVarFlags(convar);
	flags &= ~FCVAR_NOTIFY;
        flags &= ~FCVAR_CHEAT;
        flags &= ~FCVAR_DEVELOPMENTONLY;
        flags &= ~FCVAR_HIDDEN;
	SetConVarFlags(convar, flags);
}