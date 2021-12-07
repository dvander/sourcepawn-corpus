#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

enum OperatingSystem {
	OS_Unknown = -1,
	OS_Windows = 0,
	OS_Linux = 1,
	OS_Mac = 2,
	OS_Total = 3
};

char g_sCvarCheck[OS_Total][32];
bool g_bShouldCheck[OS_Total];

OperatingSystem g_ClientOS[MAXPLAYERS + 1] = { OS_Unknown, ... };
bool g_bLateLoad;

Handle g_Forward_OnParseOS;

public Plugin myinfo = 
{
	name = "[ANY] Detect OS", 
	author = "GoD-Tony, Drixevel", 
	description = "Determines the OS of a player.", 
	version = "1.0.0", 
	url = "https://forums.alliedmods.net/showthread.php?t=218691"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;
	g_Forward_OnParseOS = CreateGlobalForward("OnParseOS", ET_Ignore, Param_Cell, Param_Cell);
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_printos", Command_PrintOS);
	
	Handle hConfig = LoadGameConfigFile("detect_os.games");
	
	if (hConfig == null)
		SetFailState("Failed to find gamedata file: detect_os.games.txt");
	
	g_bShouldCheck[OS_Windows] = GameConfGetKeyValue(hConfig, "Convar_Windows", g_sCvarCheck[OS_Windows], sizeof(g_sCvarCheck[]));
	g_bShouldCheck[OS_Linux] = GameConfGetKeyValue(hConfig, "Convar_Linux", g_sCvarCheck[OS_Linux], sizeof(g_sCvarCheck[]));
	g_bShouldCheck[OS_Mac] = GameConfGetKeyValue(hConfig, "Convar_Mac", g_sCvarCheck[OS_Mac], sizeof(g_sCvarCheck[]));
	
	delete hConfig;
	
	if (g_bLateLoad)
		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i))
				OnClientPutInServer(i);
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
		return;
	
	int serial = GetClientSerial(client);
	
	if (g_bShouldCheck[OS_Windows])
		QueryClientConVar(client, g_sCvarCheck[OS_Windows], OnCvarCheck, serial);
	
	if (g_bShouldCheck[OS_Linux])
		QueryClientConVar(client, g_sCvarCheck[OS_Linux], OnCvarCheck, serial);
	
	if (g_bShouldCheck[OS_Mac])
		QueryClientConVar(client, g_sCvarCheck[OS_Mac], OnCvarCheck, serial);
}

public void OnClientDisconnect_Post(int client)
{
	g_ClientOS[client] = OS_Unknown;
}

public void OnCvarCheck(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any serial)
{
	if (result == ConVarQuery_NotFound || GetClientFromSerial(serial) != client || !IsClientInGame(client))
		return;
	
	if (StrEqual(cvarName, g_sCvarCheck[OS_Windows]))
		g_ClientOS[client] = OS_Windows;
	else if (StrEqual(cvarName, g_sCvarCheck[OS_Linux]))
		g_ClientOS[client] = OS_Linux;
	else if (StrEqual(cvarName, g_sCvarCheck[OS_Mac]))
		g_ClientOS[client] = OS_Mac;
	
	Call_StartForward(g_Forward_OnParseOS);
	Call_PushCell(client);
	Call_PushCell(g_ClientOS[client]);
	Call_Finish();
}

public Action Command_PrintOS(int client, int args)
{
	PrintToConsole(client, "%32s OS", "Client");

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		switch (g_ClientOS[i])
		{
			case OS_Windows:
				PrintToConsole(client, "%32N Windows", i);
			case OS_Linux:
				PrintToConsole(client, "%32N Linux", i);
			case OS_Mac:
				PrintToConsole(client, "%32N Mac", i);
			default:
				PrintToConsole(client, "%32N Unknown", i);
		}
	}

	return Plugin_Handled;
}
