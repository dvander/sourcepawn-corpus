#define PLUGIN_VERSION "1.0.1"

#define TEAM_UNASSIGNED 0	//Player has not joined a team
#define TEAM_SPECTATOR 1	//Player is a spectator

public Plugin:myinfo =
{
	name = "[Any] Spectator Group Targeting",
	author = "DarthNinja",
	description = "Allows admins to group-target spectators.",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};

public OnPluginStart()
{
	CreateConVar("sm_spec_target_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AddMultiTargetFilter("@spec", ProcessSpecs, "Spectators", false)
	AddMultiTargetFilter("@unassigned", ProcessUnassigned, "Unassigned Players", false)
	AddMultiTargetFilter("@notonteams", ProcessBoth, "Spectators and Unassigned Players", false)
	//AddMultiTargetFilter("@afk", ProcessAFKs, "AFK Players", false)
}

public bool:ProcessUnassigned(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_UNASSIGNED && !IsClientSourceTV(i) && !IsClientReplay(i))
			PushArrayCell(clients, i)
	}
	return true
}

public bool:ProcessSpecs(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SPECTATOR && !IsClientSourceTV(i) && !IsClientReplay(i))
			PushArrayCell(clients, i)
	}
	return true
}

public bool:ProcessBoth(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (GetClientTeam(i) == TEAM_UNASSIGNED || GetClientTeam(i) == TEAM_SPECTATOR) && !IsClientSourceTV(i) && !IsClientReplay(i))
			PushArrayCell(clients, i)
	}
	return true
}
