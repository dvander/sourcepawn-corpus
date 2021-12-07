#include <sourcemod>

#pragma semicolon 1

new Handle:team = INVALID_HANDLE; // Handle for control the cvar.

public Plugin myinfo = {
	name        = "[TF2] Team Locker",
	author      = "Kotori17",
	description = "Team locker for Team Fortress 2.",
	version     = "1.0",
	url         = "http://steamcommunity.com/id/kotori17/"
};

public void OnPluginStart()
{	
	// Commands
	RegAdminCmd("sm_lock", Command_Lock, ADMFLAG_GENERIC);
	RegAdminCmd("sm_unlock", Command_Unlock, ADMFLAG_GENERIC);
	// "team" Handle find convar mp_humans_must_join_team
	team = FindConVar("mp_humans_must_join_team");
}


// Lock
public Action:Command_Lock(client, args)
{	
	// Player didn't fill the argument correctly.
	if (args != 1)
	{
		ReplyToCommand(client, "[Team Locker] Usage: sm_lock <team>");
	}
	
	new String:arg[64]; // Making our first argument, in this moment it's our team.
	GetCmdArg(1, arg, sizeof(arg)); // Getting our first argument(Team).
	if (StrEqual(arg, "red")) // Check if our argument is red.
	{
		SetConVarString(team, "blue"); // If argument is red, set convar string to mp_humans_must_join_team blue
		PrintToChatAll("[Team Locker] %N: Locked red team!", client); // Says it to all players.
	}
	if (StrEqual(arg, "blue")) // Check if out argument is blue.
	{
		SetConVarString(team, "red"); // If argument is red, set convar string to mp_humans_must_join_team red
		PrintToChatAll("[Team Locker] %N: Locked blue team!", client); // Says it to all players.
	}
	if (!StrEqual(arg, "blue") && !StrEqual(arg, "red")) // Check if argument isn't red/blue.
	{
		PrintToChat(client, "[Team Locker] Invalid team (Teams: red,blue)"); // Says to client that the team is invalid!
	}
}

// Unlock
public Action:Command_Unlock(client, args)
{
	SetConVarString(team, "any"); // set convar string to mp_humans_must_join_team any
	PrintToChatAll("[Team Locker] %N: Unlocked teams!", client); // Says it to all players.
}