#pragma semicolon 1
#include <sourcemod>
#define NUM_CVARS "4"

new String:cvars[NUM_CVARS][32] = {"mp_friendlyfire", "mp_timelimit", "mp_fraglimit", "sv_cheats");

public Plugin:myinfo =
{
	name = "Cvar changed silencer",
	author = "Lebson506th",
	description = "Silences the cvar changed messages on the array of cvars.",
	version = 1.0,
	url = "http://www.506th-pir.org"
};
public OnPluginStart() 
{
	for(new i = 0; i < NUM_CVARS; i++)
	SilenceCvar(cvars[i]);
}

public SilenceCvar(String:cvar[32]) 
{
	new flags, Handle:cvarH = FindConVar(cvar);
	flags = GetConVarFlags(cvarH);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(cvarH, flags);

	CloseHandle(cvarH);
}

