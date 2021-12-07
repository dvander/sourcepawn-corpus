#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

ConVar g_hCvarCmdSpam, g_hCvarShowStatus, g_hCvarShowPing;
int g_iCmdCount[66], g_iCmdSpam = 4, g_iShowStatus;
bool g_bShowPing;
Handle g_hCmds;

public Plugin myinfo =
{
	name = "Status Protect",
	description = "Status Protect",
	author = "GoDtm666",
	version = "1.1.0",
	url = "http://www.myarena.ru/"
};

public void OnPluginStart()
{
	g_hCvarCmdSpam = CreateConVar("sm_antispam_statusping", "3", "How many times to allow players to enter status and ping in 1 second.", 262144, true, 2.0, true, 10.0);
	g_iCmdSpam = GetConVarInt(g_hCvarCmdSpam);
	HookConVarChange(g_hCvarCmdSpam, CmdSpam_OnSettingsChanged);
	g_hCvarShowStatus = CreateConVar("sm_show_status", "2", "Show Status: (0 to all, 1 Admins, 2 Only your Status).", 262144, true, 0.0, true, 2.0);
	g_iShowStatus = GetConVarInt(g_hCvarShowStatus);
	HookConVarChange(g_hCvarShowStatus, ShowStatus_OnSettingsChanged);
	g_hCvarShowPing = CreateConVar("sm_show_ping", "1", "Ping: (0 Don't show, 1 Show).", 262144, true, 0.0, true, 1.0);
	g_bShowPing = GetConVarBool(g_hCvarShowPing);
	HookConVarChange(g_hCvarShowPing, ShowPing_OnSettingsChanged);
	RegConsoleCmd("status", StatusCmd);
	RegConsoleCmd("ping", PingCmd);
	g_hCmds = CreateTrie();
	SetTrieValue(g_hCmds, "status", 1, true);
	SetTrieValue(g_hCmds, "ping", 1, true);
	AddCommandListener(Commands_CommandListener);
	CreateTimer(1.0, Timer_CountReset, _, 1);
	LoadTranslations("common.phrases");
}

public void CmdSpam_OnSettingsChanged(ConVar convar, char[] oldValue, char[] newValue)
{
	g_iCmdSpam = GetConVarInt(convar);
}

public void ShowStatus_OnSettingsChanged(ConVar convar, char[] oldValue, char[] newValue)
{
	g_iShowStatus = GetConVarInt(convar);
}

public void ShowPing_OnSettingsChanged(ConVar convar, char[] oldValue, char[] newValue)
{
	g_bShowPing = GetConVarBool(convar);
}

public void OnAllPluginsLoaded()
{
	AutoExecConfig(true, "status_protect", "sourcemod");
	PrintToServer("%s %s has been loaded successfully.", "Status Protect", "1.1.0");
}

public Action StatusCmd(int client, int args)
{
	switch (g_iShowStatus)
	{
		case 0:
		{
			DisplayStatus(client);
			ForStatusCmd(client);
		}
		case 1:
		{
			if (CheckCommandAccess(client, "admin_notices", 2, false))
			{
				
				if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
				{
					ReplyToCommand(client, "[SM] %t", "See console for output");
				}
				
				DisplayStatus(client);
				ForStatusCmd(client);
			}
		}
		case 2:
		{
			if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
			{
				ReplyToCommand(client, "[SM] %t", "See console for output");
			}
			
			DisplayStatus(client);
			if (CheckCommandAccess(client, "admin_notices", 2, false))
			{
				ForStatusCmd(client);
			}
			else
			{
				PrintToConsole(client, "# userid name                             uniqueid               ip-address                   ping");
				DisplayStatusInfo(client, client);
			}
		}
	}

	return Plugin_Handled;
}

void ForStatusCmd(int client)
{
	PrintToConsole(client, "# userid name                             uniqueid               ip-address                   ping");
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			DisplayStatusInfo(client, i);
		}
	}
}

public void DisplayStatus(int client)
{
	int g_iClientInServer;
	char g_sHostName[512];
	Handle g_hHostIp;
	Handle g_hHostPort;
	int g_iHostIp;
	char g_sServerIpHost[32];
	char g_sServerPort[128];
	char g_sCurrentMap[256];
	Handle g_hHostName;
	char g_ServerTime[64];
	Handle g_hNextMap;
	char g_sNextmap[256];
	g_hHostIp = FindConVar("hostip");
	g_hHostPort = FindConVar("hostport");
	g_iHostIp = GetConVarInt(g_hHostIp);
	GetConVarString(g_hHostPort, g_sServerPort, 128);
	FormatEx(g_sServerIpHost, 32, "%u.%u.%u.%u:%s", g_iHostIp >> 24 & 255, g_iHostIp >> 16 & 255, g_iHostIp >> 8 & 255, g_iHostIp & 255, g_sServerPort);
	GetCurrentMap(g_sCurrentMap, 256);
	g_hNextMap = FindConVar("sm_nextmap");
	GetConVarString(g_hNextMap, g_sNextmap, 256);
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			g_iClientInServer++;
		}
	}

	g_hHostName = FindConVar("hostname");
	GetConVarString(g_hHostName, g_sHostName, 512);
	FormatTime(g_ServerTime, 64, NULL_STRING, -1);
	PrintToConsole(client, "hostname: %s", g_sHostName);
	PrintToConsole(client, "udp/ip  : %s", g_sServerIpHost);
	PrintToConsole(client, "map     : %s", g_sCurrentMap);
	if (!StrEqual(g_sNextmap, "", false))
	{
		PrintToConsole(client, "next map: %s", g_sNextmap);
	}
	PrintToConsole(client, "players : %d (%d max)", g_iClientInServer, MaxClients);
	PrintToConsole(client, "time    : %s\n", g_ServerTime);
}

public void DisplayStatusInfo(int client, int i)
{
	char g_sName[32];
	char g_sAuthID[32];
	char g_sIP[28];
	int g_iLatency;
	int g_iUserID;
	if (!GetClientName(i, g_sName, 32))
	{
		strcopy(g_sName, 32, "Unknown");
	}
	if (!GetClientAuthId(i, AuthId_Steam2, g_sAuthID, 32, true))
	{
		strcopy(g_sAuthID, 32, "Unknown");
	}
	if (!GetClientIP(i, g_sIP, 28, false))
	{
		strcopy(g_sIP, 28, "Unknown");
	}
	g_iLatency = RoundToNearest(GetClientAvgLatency(i, view_as<NetFlow>(0)) * 1000.0);
	g_iUserID = GetClientUserId(i);
	PrintToConsole(client, "# %-6.6i %-32.31s %-22.29s %-28.29s %-4.5i", g_iUserID, g_sName, g_sAuthID, g_sIP, g_iLatency);
}

public Action Commands_CommandListener(int client, char[] command, int argc)
{
	if (!(0 < client <= MaxClients))
	{
		return Plugin_Continue;
	}
	if (IsClientConnected(client) && IsFakeClient(client))
	{
		return Plugin_Continue;
	}
	if (!IsClientInGame(client))
	{
		return Plugin_Stop;
	}
	bool f_bBan;
	char f_sCmd[64];
	strcopy(f_sCmd, 64, command);
	StringToLower(f_sCmd);
	if (g_iCmdSpam && GetTrieValue(g_hCmds, f_sCmd, f_bBan) && ++g_iCmdCount[client] > g_iCmdSpam)
	{
		if (!IsClientInKickQueue(client))
		{
			KickClient(client, "Spam by status/ping commands is prohibited!");
		}
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public Action PingCmd(int client, int args)
{
	if (g_bShowPing)
	{
		if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
		{
			ReplyToCommand(client, "[SM] %t", "See console for output");
		}
		PrintToConsole(client, "Client ping times:");
		for(int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				char g_sName[32];
				int g_iLatency;
				GetClientName(i, g_sName, 32);
				g_iLatency = RoundToNearest(GetClientAvgLatency(i, view_as<NetFlow>(0)) * 1000.0);
				PrintToConsole(client, "%i ms : %s", g_iLatency, g_sName);
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Timer_CountReset(Handle timer, any args)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		g_iCmdCount[i] = 0;
	}

	return Plugin_Continue;
}

void StringToLower(char[] f_sInput)
{
	int f_iSize = strlen(f_sInput);
	int i;
	while (i < f_iSize)
	{
		f_sInput[i] = CharToLower(f_sInput[i]);
		i++;
	}
}