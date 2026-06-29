/*
L4D GameMode Enforcer

Soft enforce director_no_human_zombies variable
sourcemode 1.2 plugin

CREDITS
- DDRKhat
*/

#include <sourcemod>

#define PLUGIN_VERSION "1.5.2"
#define CVAR_FLAGS FCVAR_PLUGIN

new Handle:versus_sv_mode = INVALID_HANDLE;
new Handle:versus_force_mode = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "L4D GameMode Enforcer",
	author = "Dionys",
	description = "Soft enforce director_no_human_zombies variable",
	version = PLUGIN_VERSION,
	url = "skiner@inbox.ru"
};

public OnPluginStart()
{
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));

	if(!StrEqual(ModName, "left4dead", false))
	{
		SetFailState("Use this Left 4 Dead only.");
	}

	CreateConVar("sm_versus_enforcer_version", PLUGIN_VERSION, "L4D Gamemode enforcer", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	versus_force_mode = CreateConVar("sm_l4d_coop", "1", "Force the coop-versus gamemode (0 - versus / 1 - coop / 2 - dont change)", CVAR_FLAGS);
	versus_sv_mode = FindConVar("director_no_human_zombies");

	HookConVarChange(versus_sv_mode, ConVarChange_FORCE);
}

public OnMapStart()
{
	AutoExecConfig(true, "sm_versus_enforcer");
}

public OnClientPutInServer(client)
{
	new CheckFirstClient = GetClientCount(true);

	if (CheckFirstClient <= 1 && GetConVarInt(versus_sv_mode) != GetConVarInt(versus_force_mode) && GetConVarInt(versus_force_mode) != 2)
	{
		if(GetConVarInt(versus_force_mode) == 0)
			SetConVarInt(versus_sv_mode, 0);
		if(GetConVarInt(versus_force_mode) == 1)
			SetConVarInt(versus_sv_mode, 1);
	}

   	return true;
}

public ConVarChange_FORCE(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (newValue[0] != GetConVarInt(versus_force_mode) && GetConVarInt(versus_force_mode) != 2 && IsServerProcessing())
	{
		if(GetConVarInt(versus_force_mode) == 0)
			SetConVarInt(versus_sv_mode, 0);
		if(GetConVarInt(versus_force_mode) == 1)
			SetConVarInt(versus_sv_mode, 1);
	}
}

public OnMapEnd()
{
	SetConVarInt(versus_force_mode, 2);
}
