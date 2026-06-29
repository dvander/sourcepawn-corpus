#pragma semicolon 1

#include <sourcemod>
#include <smac>

/* Plugin Info */
public Plugin:myinfo =
{
	name = "SMAC Immunity",
	author = "GoD-Tony",
	description = "Grants immunity from SMAC to players",
	version = "1.0.0",
	url = "http://forums.alliedmods.net/showthread.php?t=179365"
};

public Action:SMAC_OnCheatDetected(client, const String:module[])
{
	if (CheckCommandAccess(client, "smac_immunity", ADMFLAG_CUSTOM1, true))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
