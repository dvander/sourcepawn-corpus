/*=======================================================================================

	Plugin Info:

*	Name	:	[Any] Ping Viewer
*	Author	:	alasfourom
*	Descp	:	Disable common, special, tank and witch sounds.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=137397
*	Thanks	:	`666, Bacardi , PC Gamer

=========================================================================================

Version 1.5 (30-Aug-2022) - Added a new command to target any player.

Version 1.4 (05-June-2022) - added more commands.

Version 1.3 (10-May-2022) - Thanks To PC Gamer, for adding a new command.

Version 1.2 (08-May-2022) - Thanks To Bacardi, for color codes.

Version 1.1 (08-May-2022) - Thanks To `666, for rewriting it and converting it to milliseconds.

Version 1.0 (08-May-2022) - Initial release.

*************************************************************************************/

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

public Plugin myinfo = 
{
	name = "[Any] Ping Viewer",
	author = "alasfourom",
	description = "Display Players Ping",
	version = "1.5",
	url = "https://forums.alliedmods.net/showthread.php?t=137397"
};

public void OnPluginStart() 
{
	RegConsoleCmd("sm_ping", Command_Ping, "Display Any Player Ping Using Their Names");
	RegConsoleCmd("sm_myping", Command_MyPing, "Display Your Current Ping To Chat");
	RegConsoleCmd("sm_allping", Command_AllPing, "Display All Players Ping To Chat");
	
	LoadTranslations("common.phrases.txt");
}

public Action Command_Ping(int client, int args)
{
	if (args == 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_ping <#userid|name>");
		return Plugin_Handled;
	}
	
	static char arg[65]; 
	GetCmdArg(1, arg, sizeof(arg));
	
	static char target_name [MAX_TARGET_LENGTH];
	int  target_list [MAXPLAYERS + 1], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(arg, client,target_list, MAXPLAYERS,COMMAND_FILTER_NO_IMMUNITY,
		target_name,sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++) DisplayPing(target_list[i], client);
	
	return Plugin_Handled;
}

void DisplayPing(int client, int target)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		char sBuffer[64];
		FormatEx(sBuffer, sizeof(sBuffer), "%.3f", GetClientAvgLatency(target, NetFlow_Both));
		ReplaceString(sBuffer, sizeof(sBuffer), "0.00", "", false);
		ReplaceString(sBuffer, sizeof(sBuffer), "0.0", "", false);
		ReplaceString(sBuffer, sizeof(sBuffer), "0.", "", false);
		ReplyToCommand(client, "\x03♦ \x04%N: \x05%s ms", target, sBuffer);
	}
}

public Action Command_MyPing(int client, int args)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		char sBuffer[64];
		FormatEx(sBuffer, sizeof(sBuffer), "\x04Your Current Ping:\x03 %.3f ms", GetClientAvgLatency(client, NetFlow_Both));
		ReplaceString(sBuffer, sizeof(sBuffer), "0.00", "", false);
		ReplaceString(sBuffer, sizeof(sBuffer), "0.0", "", false);
		ReplaceString(sBuffer, sizeof(sBuffer), "0.", "", false);
		ReplyToCommand(client, sBuffer);
	}
	return Plugin_Handled;
}

public Action Command_AllPing(int client, int args)
{
	ReplyToCommand(client, "\x03Players Ping Status:");
	{
		for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i)) 
		{
			char sBuffer[64];
			FormatEx(sBuffer, sizeof(sBuffer), "%.3f ms", GetClientAvgLatency(i, NetFlow_Both));
			ReplaceString(sBuffer, sizeof(sBuffer), "0.00", "", false);
			ReplaceString(sBuffer, sizeof(sBuffer), "0.0", "", false);
			ReplaceString(sBuffer, sizeof(sBuffer), "0.", "", false);
			ReplyToCommand(client, "\x03♦ \x04%N: \x05%s", i, sBuffer);
		}
	}
	return Plugin_Handled;
}