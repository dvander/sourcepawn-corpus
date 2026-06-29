#pragma semicolon 1
#include <PTaH>
#include <regex>
int g_iFloodAttempts[MAXPLAYERS+1] = 0;
public Plugin myinfo =
{
	name = "noBrain's Server Security Handler",
	author = "noBrain",
	version = "1.4.8",
};

public void OnPluginStart()
{
	PTaH(PTaH_ServerConsolePrint, Hook, ServerConsolePrint);
}

public void OnMapStart()
{
	CreateTimer(5.0, Timer_ResetFloodStat, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ResetFloodStat(Handle iTimer)
{
	for(int i = 1;i<= MaxClients; i++)
	{
		g_iFloodAttempts[i] = 0;
	}
}
public Action ServerConsolePrint(const char[] sMessage, LoggingSeverity severity)
{
	if(StrContains(sMessage, "clc_VoiceData", false) != -1)
	{
		char AttackerIP[32];
		getAttackerIP(sMessage, AttackerIP, sizeof(AttackerIP));
		int gClient = FindClientByIP(AttackerIP);
		if(gClient != -1)
		{
			g_iFloodAttempts[gClient]++;
			PrintToConsole(gClient, "[noBrain's Anti-Flood] Warning! server flood detected by your ip address, if you continue you'll get banned.");
			
			if(g_iFloodAttempts[gClient] == 5)
			{
				ServerCommand("banid 0 %d", gClient);
				PrintToChatAll("[noBrain's Anti-Flood] User %N Has Banned Permanently Due to Server Attack.", gClient);
			}
		}
	}
    return Plugin_Continue;
}

stock void getAttackerIP(const char[] message, char[] ip, int maxlen)
{
	char szIP[32];
	StrCopy(szIP, sizeof(szIP), message);
	Regex regex = CompileRegex("(\\d+\\.\\d+\\.\\d+\\.\\d+)");
	int numMatched = regex.Match(szIP);
	PrintToServer("numMatch : %d", numMatched);
	regex.GetSubString(0, ip, maxlen);
}

stock int FindClientByIP(char[] IP)
{
	for(int i = 1; i <= MaxClients ; i++)
	{
		if(IsClientConnected(i) && !IsFakeClient(i))
		{
			char UserIPAddress[32];
			GetClientIP(i, UserIPAddress, sizeof(UserIPAddress));
			if(StrEqual(UserIPAddress, IP, false))
			{
				return i;
			}
		}
	}
	return -1;
}