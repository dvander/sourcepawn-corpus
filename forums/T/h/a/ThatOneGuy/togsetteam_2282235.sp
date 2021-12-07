#pragma semicolon 1
#define PLUGIN_VERSION "1.0"
#define TAG "[TOG Set Team] "

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "TOG Set Team",
	author = "That One Guy",
	description = "Simple plugin to set players team as admin",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=188078"
}

public OnPluginStart()
{
	CreateConVar("togsetteam_version", PLUGIN_VERSION, "TOG Set Team: Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	RegAdminCmd("sm_setteam", Command_SetTeam, ADMFLAG_GENERIC);
}

public Action:Command_SetTeam(client, iArgs)
{
	if(iArgs != 2)
	{
		ReplyToCommand(client, "\x01%s\x04Usage: !setteam <target> <team (1-3)>", TAG);
		return Plugin_Handled;
	}
	
	decl String:sTeam[65];
	GetCmdArg(2, sTeam, sizeof(sTeam));
	new iTeam = StringToInt(sTeam);
	if(!(1 <= iTeam <= 3))
	{
		ReplyToCommand(client, "\x01%s\x04Usage: !setteam <target> <team (1-3)>", TAG);
		return Plugin_Handled;
	}
	
	decl String:sTarget[65];
	GetCmdArg(1, sTarget, sizeof(sTarget));

	decl String:sName[MAX_TARGET_LENGTH];
	decl aTargetList[MAXPLAYERS], iTargetCount, bool:bML;

	if ((iTargetCount = ProcessTargetString(sTarget, client, aTargetList, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY, sName, sizeof(sName), bML)) <= 0)
	{
		ReplyToCommand(client, "\x01%s\x04Not found or invalid parameter.", TAG);
		return Plugin_Handled;
	}
	
	GetTeamName(iTeam, sTeam, sizeof(sTeam));
	
	for (new i = 0; i < iTargetCount; i++)
	{
		new target = aTargetList[i];
		if(IsValidClient(target, true))
		{
			if(GetClientTeam(target) != iTeam)
			{
				ChangeClientTeam(target, iTeam);
				PrintToChatAll("\x01%s\x04Player %N has been moved to %s", TAG, target, sTeam);
			}
			else
			{
				ReplyToCommand(client, "\x01%s\x04Player %N is already on %s!", TAG, target, sTeam);
			}
		}
	}

	return Plugin_Handled;
}

bool:IsValidClient(client, bool:bAllowBots = false)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots))
	{
		return false;
	}
	return true;
}