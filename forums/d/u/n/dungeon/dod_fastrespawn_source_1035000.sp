#include <sourcemod>

public Plugin:myinfo =
{
	name = "DoD FastRespawn Source",
	author = "FeuerSturm",
	description = "Quick respawn for DoD:Source",
	version = "1.0",
	url = "http://community.dodsourceplugins.net"
}

new Handle:RespawnFactor = INVALID_HANDLE

public OnMapStart()
{
	RespawnFactor = FindConVar("dod_waverespawnfactor")
	new flags = GetConVarFlags(RespawnFactor) 
	flags &= ~FCVAR_CHEAT
	SetConVarFlags(RespawnFactor, flags)
	SetConVarFloat(RespawnFactor, 0.0, true, false)
	flags &= FCVAR_CHEAT
	SetConVarFlags(RespawnFactor, flags)
}