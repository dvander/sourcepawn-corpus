#include <sourcemod>

#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "[L4D & L4D2] Target Filters",
	author = "SilverShot",
	description = "Adds target filters for Left 4 Dead games.",
	version = "1.1",
	url = "http://forums.alliedmods.net/showthread.php?t=181733"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if( strcmp(sGameName, "left4dead", false) && strcmp(sGameName, "left4dead2", false) )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	AddMultiTargetFilter("@su",			FilterSurvivor, "", false);
	AddMultiTargetFilter("@surv",		FilterSurvivor, "", false);
	AddMultiTargetFilter("@survivors",	FilterSurvivor, "", false);
	AddMultiTargetFilter("@in",			FilterInfected, "", false);
	AddMultiTargetFilter("@infe",		FilterInfected, "", false);
	AddMultiTargetFilter("@infected",	FilterInfected,	"", false);
}

public OnPluginEnd()
{
	RemoveMultiTargetFilter("@su",			FilterSurvivor);
	RemoveMultiTargetFilter("@surv",		FilterSurvivor);
	RemoveMultiTargetFilter("@survivors",	FilterSurvivor);
	RemoveMultiTargetFilter("@in",			FilterInfected);
	RemoveMultiTargetFilter("@infe",		FilterInfected);
	RemoveMultiTargetFilter("@infected",	FilterInfected);
}

public bool:FilterSurvivor(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		{
			PushArrayCell(clients, i);
		}
	}

	return true;
}

public bool:FilterInfected(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 3 )
		{
			PushArrayCell(clients, i);
		}
	}

	return true;
}