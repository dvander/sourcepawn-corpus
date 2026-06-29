/* Autobalance -Admin
 *  By Antithasys
 *  http://www.mytf2.com
 *
 * Description:
 *			Ignores the built-in autobalancer in TF2 for admins with the CUSTOM1 tag.
 *
 * 1.0.1
 * Fixed Error:	Added error checking for connected clients and non admins
 *
 * 1.0.0
 * Initial Release
 *
 * Future Updates:
 *			None
 *
 * License
 * 			GNUv2
 */
 
#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0.1"
#define MAX_STRING_LEN 255
#define TEAM_RED 2
#define TEAM_BLUE 3

public Plugin:myinfo =
{
	name = "Autobalance -Admin",
	author = "Antithasys",
	description = "Ignores the built-in autobalancer in TF2 for admins with the CUSTOM1 tag.",
	version = PLUGIN_VERSION,
	url = "http://www.mytf2.com"
}

public OnPluginStart()
{
	CreateConVar("ab_minusadmin_version", PLUGIN_VERSION, "Autobalance -Admin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	if (!HookEventEx("teamplay_teambalanced_player", HookPlayerBalance, EventHookMode_Pre)) {
		SetFailState("Could not hook an event.");
		return;
	}
}

public HookPlayerBalance(Handle:Event, const String:Name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Event, "player"));
	if (IsClientConnected(client)) {
		if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1) {
			new Team = GetEventInt(Event, "team");
			if (Team == TEAM_RED)
				SetEventInt(Event, "team", TEAM_BLUE);
			if (Team == TEAM_BLUE)
				SetEventInt(Event, "team", TEAM_RED);
			return _:Plugin_Handled;
		}
	}
	return _:Plugin_Continue;
}