#include <sourcemod>
#include <cstrike>

new g_Red = 0;
new g_Blue = 0;

public Plugin:myinfo =
{
	name = "MG Score",
	author = "Sidezz",
	description = "Dank memes",
	version = "1.0",
	url = "http://www.coldcommunity.com"
}

public OnPluginStart()
{
	g_Red = 0;
	g_Blue = 0;

	RegAdminCmd("sm_redscore", command_addRedScore, ADMFLAG_GENERIC, "Add a score to red and print scoreboard");
	RegAdminCmd("sm_bluescore", command_addBlueScore, ADMFLAG_GENERIC, "Add a score to blue and print scoreboard");
	RegAdminCmd("sm_clearscore", command_resetScore, ADMFLAG_GENERIC, "Reset scores");
}

public Action:command_addRedScore(client, args)
{
	g_Red++;
	PrintCenterTextAll("RED %i - BLUE %i", g_Red, g_Blue);
	return Plugin_Handled;
}

public Action:command_addBlueScore(client, args)
{
	g_Red++;
	PrintCenterTextAll("RED %i - BLUE %i", g_Red, g_Blue);
	return Plugin_Handled;
}

public Action:command_resetScore(client, args)
{
	g_Red = 0;
	g_Blue = 0;
	return Plugin_Handled;
}