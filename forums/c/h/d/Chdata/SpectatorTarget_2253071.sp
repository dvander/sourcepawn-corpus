#define PLUGIN_VERSION "0x02"

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
		if (IsClientInGame(i) && GetEntityTeamNum(i) == TEAM_UNASSIGNED && !IsClientSourceTV(i) && !IsClientReplay(i))
			PushArrayCell(clients, i)
	}
	return true
}

public bool:ProcessSpecs(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetEntityTeamNum(i) == TEAM_SPECTATOR && !IsClientSourceTV(i) && !IsClientReplay(i))
			PushArrayCell(clients, i)
	}
	return true
}

public bool:ProcessBoth(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (GetEntityTeamNum(i) <= TEAM_SPECTATOR) && !IsClientSourceTV(i) && !IsClientReplay(i))
			PushArrayCell(clients, i)
	}
	return true
}

/*
    Returns the the TeamNum of an entity.
    Works for both clients and things like healthpacks.
    Returns -1 if the entity doesn't have the m_iTeamNum prop.

    GetClientTeam() doesn't always return properly when tf_arena_use_queue is set to 0
*/
stock GetEntityTeamNum(iEnt)
{
    // if (GetEntSendPropOffs(iEnt, "m_iTeamNum") <= 0)
    // {
    //     return -1;
    // }
    return GetEntProp(iEnt, Prop_Send, "m_iTeamNum");
}