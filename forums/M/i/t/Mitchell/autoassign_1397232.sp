#include <sourcemod>
#include <sdktools>
#include <cstrike>
#pragma semicolon 1
#define PLUGIN_VERSION "2.0"
new Float:RecentChange[MAXPLAYERS+1];
new Handle:auto_team = INVALID_HANDLE;
public Plugin:myinfo =
{
	name = "Auto Assign",
	author = "Mitchell",
	description = "Makes it so you cant choose your team.",
	version = PLUGIN_VERSION,
	url = ""
}
public OnPluginStart( )
{
	CreateConVar("sm_auto_assign", PLUGIN_VERSION, "Autoassign", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	auto_team =	CreateConVar( "sm_autoassign_team", "1", "0 - Disables, 1 - Any Team, 2 - T, 3 - CT" );
	RegConsoleCmd("joingame", JOINgAME);
	RegConsoleCmd("jointeam", JOINgAME);
}
public Action:JOINgAME(client, args)
{
	if(!IsFakeClient(client) && ((GetGameTime() - RecentChange[client]) >= 120.0))
	{
		new cTeam = GetConVarInt(auto_team);
		switch (cTeam)
		{
			case 0:
				return Plugin_Continue;
			case 1:
			{
				if (GetTeamClientCount(CS_TEAM_T) > GetTeamClientCount(CS_TEAM_CT)) {
					CS_SwitchTeam(client, CS_TEAM_CT);
					CS_RespawnPlayer(client);
					RecentChange[client] = GetGameTime();
					return Plugin_Handled;
				}
				if (GetTeamClientCount(CS_TEAM_CT) > GetTeamClientCount(CS_TEAM_T)) {
					CS_SwitchTeam(client, CS_TEAM_T);
					CS_RespawnPlayer(client);
					RecentChange[client] = GetGameTime();
					return Plugin_Handled;
				}
				if (GetTeamClientCount(CS_TEAM_CT) == GetTeamClientCount(CS_TEAM_T)) {
					CS_SwitchTeam(client, GetRandomInt(2, 3));
					CS_RespawnPlayer(client);
					RecentChange[client] = GetGameTime();
					return Plugin_Handled;
				}
			}
			case 2,3:
			{
				CS_SwitchTeam(client, cTeam);
				CS_RespawnPlayer(client);
				RecentChange[client] = GetGameTime();
				return Plugin_Handled;
			}
		}
	}
	else {
		PrintToChat(client, "\x03[\x05Auto-Assign\x03] \x01You must wait 2 minutes before changing teams.");
		return Plugin_Handled;
	}
	return Plugin_Continued;
}
public OnClientPutInServer(client)
{
	RecentChange[client] = GetGameTime();
}