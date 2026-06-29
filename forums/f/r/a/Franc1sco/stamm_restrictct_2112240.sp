#pragma semicolon 1
#include <sourcemod>
#include <stamm>

public Plugin:myinfo =
{
	name = "SM Stamm CT Restrict",
	author = "Franc1sco Steam: franug",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/franug"
};

new Handle:g_points = INVALID_HANDLE;

public OnPluginStart()
{
	g_points = CreateConVar("sm_restrictct_points", "5", "points needed for can join in CT team");
	RegConsoleCmd("jointeam", Join);
}

public Action:Join(client, args)
{
	decl String:team[2]; GetCmdArg(1, team, sizeof(team));

	new teamnumber = StringToInt(team);
	new points = GetConVarInt(g_points);

	if (GetClientStammPoints(client) < points && teamnumber == 3 && GetUserAdmin(client) == INVALID_ADMIN_ID)
	{
		PrintToChat(client, "[SM] You need %i stamm points for join in CT team!", points);
		return Plugin_Handled;
	}
	return Plugin_Continue;

} 