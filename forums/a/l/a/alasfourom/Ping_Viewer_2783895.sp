#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo = {
	name = "Ping_Viewer",
	author = "alasfourom, modified by PC Gamer",
	description = "Print Your Ping Into Chat",
	version = "1.2",
	url = "https://forums.alliedmods.net/"
};

public void OnPluginStart() 
{
	RegConsoleCmd("sm_ping", Command_MyPing, "Print Ping To Chat");
	RegConsoleCmd("sm_pings", Command_Ping, "Print Ping To Chat");
	RegConsoleCmd("sm_pingall", Command_Ping, "Print Ping To Chat");
	RegConsoleCmd("sm_pinglist", Command_Ping, "Print Ping To Chat");
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

public Action Command_Ping(int client, int args)
{
	PrintToChatAll("\x03Players Ping Status:");
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i)) 
			{
				char sBuffer[64];
				FormatEx(sBuffer, sizeof(sBuffer), "%.3f ms", GetClientAvgLatency(i, NetFlow_Both));
				ReplaceString(sBuffer, sizeof(sBuffer), "0.00", "", false);
				ReplaceString(sBuffer, sizeof(sBuffer), "0.0", "", false);
				ReplaceString(sBuffer, sizeof(sBuffer), "0.", "", false);
				PrintToChatAll("\x03♦ \x04%N: \x05%s", i, sBuffer);
			}
		}
	}
	return Plugin_Handled;
}