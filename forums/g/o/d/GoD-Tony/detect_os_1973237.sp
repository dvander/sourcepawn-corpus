#pragma semicolon 1

#include <sourcemod>

enum OperatingSystem {
	OS_Unknown = -1,
	OS_Windows = 0,
	OS_Linux = 1,
	OS_Mac = 2,
	OS_Total = 3
};

new String:g_sCvarCheck[OS_Total][32];
new bool:g_bShouldCheck[OS_Total];

new OperatingSystem:g_ClientOS[MAXPLAYERS+1] = { OS_Unknown, ... };
new bool:g_bLateLoad = false;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	RegConsoleCmd("sm_printos", Command_PrintOS);
	
	// Load cvars to check from gamedata.
	new Handle:hConfig = LoadGameConfigFile("detect_os.games");
	
	if (hConfig == INVALID_HANDLE)
	{
		SetFailState("Failed to find gamedata file: detect_os.games.txt");
	}
	
	g_bShouldCheck[OS_Windows] = GameConfGetKeyValue(hConfig, "Convar_Windows", g_sCvarCheck[OS_Windows], sizeof(g_sCvarCheck[]));
	g_bShouldCheck[OS_Linux] = GameConfGetKeyValue(hConfig, "Convar_Linux", g_sCvarCheck[OS_Linux], sizeof(g_sCvarCheck[]));
	g_bShouldCheck[OS_Mac] = GameConfGetKeyValue(hConfig, "Convar_Mac", g_sCvarCheck[OS_Mac], sizeof(g_sCvarCheck[]));
	
	CloseHandle(hConfig);
	
	// Late-load handling.
	if (g_bLateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
}

public OnClientPutInServer(client)
{
	if (IsFakeClient(client))
		return;
	
	new serial = GetClientSerial(client);
	
	if (g_bShouldCheck[OS_Windows])
		QueryClientConVar(client, g_sCvarCheck[OS_Windows], OnCvarCheck, serial);
	if (g_bShouldCheck[OS_Linux])
		QueryClientConVar(client, g_sCvarCheck[OS_Linux], OnCvarCheck, serial);
	if (g_bShouldCheck[OS_Mac])
		QueryClientConVar(client, g_sCvarCheck[OS_Mac], OnCvarCheck, serial);
}

public OnClientDisconnect_Post(client)
{
	g_ClientOS[client] = OS_Unknown;
}

public OnCvarCheck(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[], any:serial)
{
	if (result == ConVarQuery_NotFound || GetClientFromSerial(serial) != client || !IsClientInGame(client))
		return;
	
	if (StrEqual(cvarName, g_sCvarCheck[OS_Windows]))
		g_ClientOS[client] = OS_Windows;
	else if (StrEqual(cvarName, g_sCvarCheck[OS_Linux]))
		g_ClientOS[client] = OS_Linux;
	else if (StrEqual(cvarName, g_sCvarCheck[OS_Mac]))
		g_ClientOS[client] = OS_Mac;
}

public Action:Command_PrintOS(client, args)
{
	// Prints all clients names and their OS in console.
	PrintToConsole(client, "%32s OS", "Client");

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		switch (g_ClientOS[i])
		{
			case OS_Windows:
			{
				PrintToConsole(client, "%32N Windows", i);
			}
			case OS_Linux:
			{
				PrintToConsole(client, "%32N Linux", i);
			}
			case OS_Mac:
			{
				PrintToConsole(client, "%32N Mac", i);
			}
			default:
			{
				PrintToConsole(client, "%32N Unknown", i);
			}
		}
	}

	return Plugin_Handled;
}
