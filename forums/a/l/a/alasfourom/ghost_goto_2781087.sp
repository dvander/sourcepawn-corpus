#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "Ghost Goto Command",
	author = "alasfourom",
	description = "Ghost Infected Can Use Goto Command",
	version = "1.0",
	url = "https://www.sourcemod.net/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_goto", Command_Goto, "Allow Ghost Infected To Use Goto Command");
		
	LoadTranslations("common.phrases");
}

bool IsPlayerGhost (int client)
{
    return (GetEntProp(client, Prop_Send, "m_isGhost") == 1);
}

public Action Command_Goto(int client, int args)
{
	
	if (args == 0)
	{
		ReplyToCommand(client, "\x04[Ghost] \x01Usage: sm_goto \x03<#userid|name>");
		return Plugin_Handled;
	}
	
	if (IsPlayerAlive(client) && !IsPlayerGhost(client))
	{
		ReplyToCommand(client, "\x04[Ghost] \x01Only \x03ghost infected \x01can teleport to players.");
		return Plugin_Handled;
	}
	
	if (IsPlayerGhost(client))
	{
		float fTeleportOrigin[3];
		float fPlayerOrigin[3];

		char sArg1[MAX_NAME_LENGTH];
		GetCmdArg(1, sArg1, sizeof(sArg1));
		int destination = FindTarget(client, sArg1);
		
		if (!IsPlayerAlive(destination))
		{
			ReplyToCommand(client, "\x04[Ghost] \x01Player \x03%N \x01is currently dead.", destination);
			return Plugin_Stop;
		}
		
		GetClientAbsOrigin(destination, fPlayerOrigin);

		fTeleportOrigin[0] = fPlayerOrigin[0];
		fTeleportOrigin[1] = fPlayerOrigin[1];
		fTeleportOrigin[2] = (fPlayerOrigin[2] + 5);
	
		TeleportEntity(client, fTeleportOrigin, NULL_VECTOR, NULL_VECTOR);
		ReplyToCommand(client, "\x04[Ghost] \x01You have been successfully brought to \x03%N\x01.", destination);
		return Plugin_Handled;
		
	}
	return Plugin_Handled;
}