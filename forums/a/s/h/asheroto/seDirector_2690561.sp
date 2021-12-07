#include <sourcemod>
#define PLUGIN_VERSION "4.0"
#pragma semicolon 1
new Handle:g_sedirector;
new Handle:shutdownTimer;
new shutdownTime;
new String:g_latestMap[128];
new String:g_currentMap[128];
new g_latestPlayerCount;
new g_currentPlayerCount;

// Plugin Info
public Plugin:myinfo =
{
    name = "seDirector",
    author = "seDirector",
    description = "seDirector's SourceMod plugin to assist in updating servers automatically.",
    version = PLUGIN_VERSION,
    url = "http://sedirector.net"
};


public OnPluginStart()
{
	ServerCommand("sm_cvar sv_hibernate_when_empty 0");
	CreateConVar("sedirector_version", PLUGIN_VERSION, "seDirector version",FCVAR_NOTIFY);
	g_sedirector = CreateConVar("sedirector", "1", "0 = Disabled \n1 = Enabled");
	
	RegAdminCmd("sedirector_forcecheck", Command_seDirectorForceCheck, ADMFLAG_RCON, "Forces a check for an update.");
	RegAdminCmd("sedirector_cancel", Command_seDirectorCancel, ADMFLAG_RCON, "Cancels the server shutdown. Server will start the countdown at the next map change.");
}

public OnMapStart()
{
	UpdateMap();
	CreateTimer(30.0, UpdatePlayerCount, _, TIMER_REPEAT);
	CreateTimer(30.0, CheckForUpdate, _, TIMER_REPEAT);
}

// Updates the seDirector.map file with the current map
public UpdateMap() {
	GetCurrentMap(g_currentMap, sizeof(g_currentMap));
	if (!StrEqual(g_latestMap,g_currentMap)) {
		g_latestMap = g_currentMap;
		new Handle:sed_MapFile = OpenFile("seDirector.map","w");
		WriteFileLine(sed_MapFile, g_currentMap);
		if(sed_MapFile != INVALID_HANDLE) 
		{
			CloseHandle(sed_MapFile);
		}
	}
}

// Updates the seDirector.players file with the current number of players
public Action:UpdatePlayerCount(Handle:timer) {
	new value = GetConVarInt(g_sedirector);
	if (value == 0) {
		return Plugin_Continue;
	} else {		
		g_currentPlayerCount = GetClientCount();
		if (g_latestPlayerCount != g_currentPlayerCount) {
			g_latestPlayerCount = g_currentPlayerCount;
			new Handle:sed_PlayersFile = OpenFile("seDirector.players","w");
			WriteFileLine(sed_PlayersFile, "%d", g_currentPlayerCount);
			if(sed_PlayersFile != INVALID_HANDLE)
			{
				CloseHandle(sed_PlayersFile);
			}
		}
	
	}
	return Plugin_Continue;
}

public Action:CheckForUpdate(Handle:timer) {
	new value = GetConVarInt(g_sedirector);
	if (value == 0) {
		return Plugin_Continue;
	} else {		
		
		if(FileExists("seDirector.update") == true) {
		
			LogMessage("Update detected.");
			shutdownTime = 60;
			shutdownTimer = CreateTimer(1.0, ShutItDown, _, TIMER_REPEAT);
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action:Command_seDirectorForceCheck(client, args) {
	new value = GetConVarInt(g_sedirector);
	if (value == 0) {
		return Plugin_Continue;
	} else {
		if(FileExists("seDirector.update") == true) {
			ReplyToCommand(client, "%s", "Force update: detected.");
			LogMessage("Force update: detected.");
		} else {
			ReplyToCommand(client, "%s", "Force update: not detected.");
			LogMessage("Force update: not detected.");	
		}
	}
	return Plugin_Continue;
}

public Action:Command_seDirectorCancel(client, args) {
	if(shutdownTimer == INVALID_HANDLE) {
		ReplyToCommand(client, "%s","An update has not been detected. A countdown will commence when an update is detected.");
		return Plugin_Handled;
	}
	if(shutdownTimer != INVALID_HANDLE) {
		KillTimer(shutdownTimer);
		PrintHintTextToAll("Shutdown cancelled");
		PrintCenterTextAll("The shutdown has been cancelled.");
	}
	ReplyToCommand(client, "%s", "The shutdown has been cancelled.");
	shutdownTime = 0;
	shutdownTimer = INVALID_HANDLE;
	LogAction(client, -1, "%L cancelled a server shutdown.",client);
	return Plugin_Handled;
}

public ShutDownPrint() {
	PrintHintTextToAll("Shutting down in %i seconds",shutdownTime);
}

public ShutDownFullPrint() {
	PrintToChatAll("Server shutting down for maintenance in %i seconds, please rejoin in 10 minutes.",shutdownTime);
	PrintCenterTextAll("Server shutting down for maintenance in %i seconds, please rejoin in 10 minutes.",shutdownTime);	
	LogMessage("%i second shutdown reminder",shutdownTime);
}

public Action:ShutItDown(Handle:timer) {
	if(shutdownTime == 60) {
		ShutDownFullPrint();
		ShutDownPrint();
	} else if (shutdownTime == 50) {
		ShutDownPrint();
	} else if (shutdownTime == 40) {
		ShutDownPrint();
	} else if (shutdownTime == 30) {
		ShutDownFullPrint();
		ShutDownPrint();
	} else if (shutdownTime == 20) {
		ShutDownPrint();
	} else if (shutdownTime <= 10) {
		if(shutdownTime == 10) {
			ShutDownFullPrint();
		}
		ShutDownPrint();
	}
	
	shutdownTime--;
	if(shutdownTime <= -1) 
	{
		if (shutdownTimer != INVALID_HANDLE)
		{
			KillTimer(shutdownTimer);
			shutdownTimer = INVALID_HANDLE;
		}
		DeleteFile("seDirector.update");
		LogMessage("Server shutdown.");
		ServerCommand("quit");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}