/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define CS_TEAM_CT 3

public Plugin:myinfo = 
{
	name = "Get C4",
	author = "Enkore",
	description = "Give User C4",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	RegConsoleCmd("sm_c4", Command_C4, "Box Match");
}

public Action:Command_C4(client, args)
{
	if(GetClientTeam(client) != CS_TEAM_CT && !IsPlayerAlive(client)) {
		PrintToChat(client, "\x04[SM]\x01 You Don't Have Access To This Command");
	} else {
		GivePlayerItem(client, "Weapon_C4");
		PrintToChat(client, "\x04[SM]\x01 You Successfully Gained C4");
	}
	return Plugin_Handled;
}