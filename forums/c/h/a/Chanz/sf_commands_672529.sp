//******************************************************************
// sf_commands.sp
// 19.08.2008 Chanz
// You can use the "sf_" commands as admin (no need of rcon level anymore for this)
//******************************************************************

#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

public Plugin:myinfo =
{
    name = "sf_commands",
    author = "Chanz",
    description = "You can use the sf_ commands as admin (no need of rcon level anymore for this)",
    version = "1.0.0.0",
    url = ""
}

public OnPluginStart()
{
    RegAdminCmd("sm_team_blocklimit", Set_sf_team_blocklimit, ADMFLAG_KICK, "sf_team_blocklimit");
	RegAdminCmd("sm_player_limits_enabled", Set_sf_player_limits_enabled, ADMFLAG_KICK, "sf_player_limits_enabled");

}

public Action:Set_sf_team_blocklimit(client, args){
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_team_blocklimit <number> - sets the sf_team_blocklimit");
		return Plugin_Handled;
	}
	new String:limit[8];
	GetCmdArg(1, limit, sizeof(limit));
	ServerCommand("sf_team_blocklimit %s", limit);
	ReplyToCommand(client, "[SM] sf_team_blocklimit got changed to %s", limit);
	return Plugin_Handled;
}

public Action:Set_sf_player_limits_enabled(client, args){
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_player_limits_enabled <number> - sets the sf_player_limits_enabled");
		return Plugin_Handled;
	}
	new String:limit[8];
	GetCmdArg(1, limit, sizeof(limit));
	ServerCommand("sf_player_limits_enabled %s", limit);
	ReplyToCommand(client, "[SM] sf_player_limits_enabled got changed to %s", limit);
	return Plugin_Handled;
}