/*
 * Hidden:SourceMod - Team-Say fix
 *
 * Description:
 *  Fixes team-only messages.
 *
 * Changelog
 *  v1.1.0
 *   Message now appear to team only.
 *   Message also appear in client's console since the grey text doesn't get sent there.
 *  v1.0.0
 *   Initial release
 *
 */

#define PLUGIN_VERSION "1.1.0"

#include <sourcemod>

#pragma semicolon 1

new String:g_sLocation[MAXPLAYERS][64];

public Plugin:myinfo =
{
	name		= "H:SM - Say_team Fix",
	author		= "Paegus",
	description	= "Fixes Team-only chat problem in Hidden:Source",
	version		= PLUGIN_VERSION,
	url			= "http://forum.hidden-source.com/forumdisplay.php?f=13"
}

public OnPluginStart()
{
	CreateConVar(
		"hsm_sayfix_version",
		PLUGIN_VERSION,
		"H:SM - SayFix version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);

	HookEvent("player_location", event_PlayerLocation);

	RegConsoleCmd("say_team", command_Say);

}

public OnMapStart()
{
	new iMaxClients = GetMaxClients();
	for (new iClient = 1; iClient < iMaxClients; iClient++)
	{
		g_sLocation[iClient] = "Somewhere";
	}
}

// Store the player's new location in global.
public event_PlayerLocation(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "location", g_sLocation[iClient], 64);
}

public Action:command_Say(iClient, argc)
{
	new String:sName[32];
	GetClientName(iClient, sName, sizeof(sName));

	new String:sText[1024];
	GetCmdArgString(sText, sizeof(sText));

	StripQuotes(sText);

	new iTeam = GetClientTeam(iClient);

	new iMaxClients = GetMaxClients();
	for (new iTarget = 1; iTarget <= iMaxClients; iTarget++ )
	{
		if (IsClientConnected(iTarget) && IsClientInGame(iTarget)) // Connected and in-game.
		{
			if (GetClientTeam(iTarget) == iTeam && iTarget != iClient)
			{
				PrintToConsole(
					iTarget,
					"(Team) %s : (%s) %s",
					sName,
					g_sLocation[iClient],
					sText
				);

				PrintToChat(
					iTarget,
					"(Team) %s : (%s) %s",
					sName,
					g_sLocation[iClient],
					sText
				);
			}
		}
	}

	/*********************************************************
	 * I Honestly cannot believe how stupid some people are. *
	 * They keep trying to talk other teams with team-chat.  *
	 *********************************************************/

	return Plugin_Continue;
}
