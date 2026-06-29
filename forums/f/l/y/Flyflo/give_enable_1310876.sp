#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Enable give command",
	author = "Flyflo",
	description = "Enable give command without sv_cheats 1",
	version = "0.1",
}

public OnPluginStart()
{
	SetCommandFlags("give", GetCommandFlags("give") & ~FCVAR_CHEAT);
}