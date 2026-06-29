/**
* lastx.sp by HomicidalApe
* Gives admins a list of the last players to disconnect, with their steam IDs.
*
* Credits go to whoever made a very similar plugin for SourceForts. This is based off that.
*
* Thanks to teame06, since he tore apart so much of this code showing me how to do things.
*
*/


#include <sourcemod>

public Plugin:myinfo = {
	name = "LastX",
	author = "HomicidalApe",
	description = "Shows the last x users that disconnected and their steam IDs.",
	version = "1.2",
	url = "http://www.homicidalape.mybigspoon.com/mapsite/"
};

new Handle:PlayerName;
new Handle:PlayerAuthid;
new count;
new lastxhistory = 10; // default history length
new bool:logbots = false;

public OnPluginStart()
{
	PlayerName = CreateArray(64, lastxhistory);
	PlayerAuthid = CreateArray(64, lastxhistory);

	RegAdminCmd("lastx", List, ADMFLAG_GENERIC, "Lists the last x players to disconnect.");
	RegAdminCmd("sm_lastxhistory", SetHistory, ADMFLAG_GENERIC, "sm_lastxhistory <#> : Sets how many player names+IDs to remember for lastx command.");
	RegAdminCmd("sm_lastxbots", SetBots, ADMFLAG_GENERIC, "sm_lastxhistory <#> : Determines if lastx will log bots.");

}

public OnClientDisconnect(client)
{
	decl String:playername[64], String:playerid[64];
	GetClientName(client, playername, sizeof(playername));
	GetClientAuthString(client, playerid, sizeof(playerid));
	
	if (!strcmp(playerid, "BOT"))
	{
		if (!logbots)
		{
			return;
		}
	}

	if (++count >= lastxhistory)
	{
		count = lastxhistory;
		RemoveFromArray(PlayerName, lastxhistory - 1);
		RemoveFromArray(PlayerAuthid, lastxhistory - 1);
	}

	if (count)
	{
		ShiftArrayUp(PlayerAuthid, 0);
		ShiftArrayUp(PlayerName, 0);
	}

	SetArrayString(PlayerName, 0, playername);
	SetArrayString(PlayerAuthid, 0, playerid);

	return;
}

public Action:List(client, args)
{
	PrintToConsole(client, "Last %i players to disconnect:", count);

	decl String:Auth[64], String:Name[64];
	for (new i = 0; i < count; i++)
	{
		GetArrayString(PlayerName, i, Name, sizeof(Name));
		GetArrayString(PlayerAuthid, i, Auth, sizeof(Auth));

		PrintToConsole(client, "%d. %s - %s", i+1, Name, Auth);
	}

	return Plugin_Handled;
}

public Action:SetHistory(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Current Value: %i \n[SM] Usage: sm_lastxhistory <#> : min 1.0 max 64.0", lastxhistory);
		return Plugin_Handled;
	}

	decl String:history[64];
	GetCmdArg(1, history, sizeof(history));

	new value = StringToInt(history)

	if (0 < value < 65)
	{
		if(value < count)
		{
			count = value;
		}

		lastxhistory = value;

		ResizeArray(PlayerName, lastxhistory);
		ResizeArray(PlayerAuthid, lastxhistory);
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(client, "Current Value: %i \n[SM] Usage: sm_lastxhistory <#> : min 1 max 64", lastxhistory);
		return Plugin_Handled;
	}
}

public Action:SetBots(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Current Value: %i \n[SM] Usage: sm_lastxbots <0 or 1>", logbots);
		return Plugin_Handled;
	}

	decl String:bots[64];
	GetCmdArg(1, bots, sizeof(bots));

	new value = StringToInt(bots)

	if (value == 1)
	{
		logbots = true;
		return Plugin_Handled;
	}

	if (value == 0)
	{
		logbots = false;
		return Plugin_Handled;
	}

	else
	{
		ReplyToCommand(client, "Current Value: %i \n[SM] Usage: sm_lastxhistory <#> : min 1.0 max 64.0", lastxhistory);
		return Plugin_Handled;
	}
}