#include <sourcemod>

new Handle:g_cvarDifficulty

public OnPluginStart()
{
	RegAdminCmd("sm_forcediff", CmdForce, ADMFLAG_ROOT, "Forces the impossible difficulty");
}

public OnMapStart()
{
	g_cvarDifficulty = FindConVar("z_difficulty");
	if(g_cvarDifficulty == INVALID_HANDLE)
	{
		SetFailState("The convar \"z_difficulty\" does not exist");
	}
	new flags = GetConVarFlags(g_cvarDifficulty);
	SetConVarFlags(g_cvarDifficulty, flags & ~FCVAR_CHEAT)
	SetConVarString(g_cvarDifficulty, "impossible", false, false);
	SetConVarFlags(g_cvarDifficulty, flags);
}

public Action:CmdForce(client, args)
{
	g_cvarDifficulty = FindConVar("z_difficulty");
	if(g_cvarDifficulty == INVALID_HANDLE)
	{
		SetFailState("The convar \"z_difficulty\" does not exist");
	}
	new flags = GetConVarFlags(g_cvarDifficulty);
	SetConVarFlags(g_cvarDifficulty, flags & ~FCVAR_CHEAT)
	SetConVarString(g_cvarDifficulty, "impossible", false, false);
	SetConVarFlags(g_cvarDifficulty, flags);
}