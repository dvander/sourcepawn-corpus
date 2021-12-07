/**
 * 
 * Forked by Recon to lastteam.
 * 
* lastx.sp by HomicidalApe
* Gives admins a list of the last players to disconnect, with their steam IDs.
*
* Credits go to whoever made a very similar plugin for SourceForts. This is based off that.
*
* Thanks to teame06, since he tore apart so much of this code showing me how to do things.
*
*/


#include <sourcemod>
#include<sdktools_functions>

public Plugin:myinfo = {
	name = "Lastteam",
	author = "Recon (based on lastx by HomicidalApe)",
	description = "Shows the last x users that joined teams and their steam IDs.",
	version = "1.2",
	url = "No website yet..."
};

new Handle:PlayerName;
new Handle:PlayerAuthid;
new Handle:PlayerTeam;
new count;
new lastteamhistory = 10; // default history length
new bool:logbots = false;

public OnPluginStart()
{
	PlayerName = CreateArray(64, lastteamhistory);
	PlayerAuthid = CreateArray(64, lastteamhistory);
	PlayerTeam = CreateArray(64, lastteamhistory);

	RegAdminCmd("lastteam", List, ADMFLAG_GENERIC, "Lists the last x players to join a team.");
	RegAdminCmd("sm_lastteamhistory", SetHistory, ADMFLAG_RCON, "sm_lastteamhistory <#> : Sets how many player names+IDs to remember for lastteam command.");
	RegAdminCmd("sm_lastteambots", SetBots, ADMFLAG_RCON, "sm_lastteambots <#> : Determines if lastteam will log bots.");
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);

}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client > 0 && IsClientConnected(client))
	{	
		decl String:playername[64], String:playerid[64];
		GetClientName(client, playername, sizeof(playername));
		GetClientAuthString(client, playerid, sizeof(playerid));
		
		// Get the team
		new team = GetEventInt(event, "team");	
		decl String:teamName[64];
		GetTeamName(team, teamName, sizeof(teamName));
		
		
		if (!strcmp(playerid, "BOT"))
		{
			if (!logbots)
			{
				return;
			}
		}

		if (++count >= lastteamhistory)
		{
			count = lastteamhistory;
			RemoveFromArray(PlayerName, lastteamhistory - 1);
			RemoveFromArray(PlayerAuthid, lastteamhistory - 1);
			RemoveFromArray(PlayerTeam, lastteamhistory - 1);
		}

		if (count)
		{
			ShiftArrayUp(PlayerAuthid, 0);
			ShiftArrayUp(PlayerName, 0);
			ShiftArrayUp(PlayerTeam, 0);
		}

		SetArrayString(PlayerName, 0, playername);
		SetArrayString(PlayerAuthid, 0, playerid);
		SetArrayString(PlayerTeam, 0, teamName);	
	}
	
}


public Action:List(client, args)
{
	PrintToConsole(client, "Last %i players to join a team:", count);
	PrintToConsole(client, "Name - SteamID - Team");

	decl String:Auth[64], String:Name[64], String:Team[64];
	for (new i = 0; i < count; i++)
	{
		GetArrayString(PlayerName, i, Name, sizeof(Name));
		GetArrayString(PlayerAuthid, i, Auth, sizeof(Auth));
		GetArrayString(PlayerTeam, i, Team, sizeof(Team));

		PrintToConsole(client, "%d. %s - %s - %s", i+1, Name, Auth, Team);
	}

	return Plugin_Handled;
}

public Action:SetHistory(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Current Value: %i \n[SM] Usage: sm_lastteamhistory <#> : min 1.0 max 64.0", lastteamhistory);
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

		lastteamhistory = value;

		ResizeArray(PlayerName, lastteamhistory);
		ResizeArray(PlayerAuthid, lastteamhistory);
		ResizeArray(PlayerTeam, lastteamhistory);
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(client, "Current Value: %i \n[SM] Usage: sm_lastteamhistory <#> : min 1 max 64", lastteamhistory);
		return Plugin_Handled;
	}
}

public Action:SetBots(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Current Value: %i \n[SM] Usage: sm_lastteambots <0 or 1>", logbots);
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
		ReplyToCommand(client, "Current Value: %i \n[SM] Usage: sm_lastteambots <#> : min 1.0 max 64.0", lastteamhistory);
		return Plugin_Handled;
	}
}