#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <geoip>

#define PLUGIN_VERSION "1.4"

#define ADMIN_LOG_PATH "logs/connections/admin"
#define PLAYER_LOG_PATH "logs/connections/player"

char admin_filepath[PLATFORM_MAX_PATH];
char player_filepath[PLATFORM_MAX_PATH];

bool clientIsAdmin[MAXPLAYERS+1] = { false, ... };
bool clientConnected[MAXPLAYERS+1] = { false, ... };

public Plugin myinfo =
{
	name = "Log Connections",
	author = "Xander, IT-KiLLER, Dosergen",
	description = "This plugin logs players' connect and disconnect times, capturing their Name, SteamID, IP Address and Country.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=201967"
}

public void OnPluginStart()
{
	CreateConVar("sm_log_connections_version", PLUGIN_VERSION, "Log Connections version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	// Initialize paths
	InitializeLogPath(admin_filepath, sizeof(admin_filepath), ADMIN_LOG_PATH);
	InitializeLogPath(player_filepath, sizeof(player_filepath), PLAYER_LOG_PATH);
	
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	
	// Initialize clients
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			clientConnected[client] = true;
			clientIsAdmin[client] = IsPlayerAdmin(client);
		}
	}
}

void InitializeLogPath(char[] filepath, int maxlen, const char[] path)
{
	BuildPath(Path_SM, filepath, maxlen, path);
	if (!DirExists(filepath))
	{
		CreateDirectory(filepath, 511, true);
		if (!DirExists(filepath))
			LogMessage("Failed to create directory at %s - Please manually create that path and reload this plugin.", path);
	}
}

public void OnMapStart()
{
	char formatedDate[100];
	char mapName[100];
	int currentTime = GetTime();
	GetCurrentMap(mapName, sizeof(mapName));
	FormatTime(formatedDate, sizeof(formatedDate), "%d_%b_%Y", currentTime); 
	// Update log paths
	FormatLogPath(admin_filepath, sizeof(admin_filepath), ADMIN_LOG_PATH, formatedDate, "admin");
	FormatLogPath(player_filepath, sizeof(player_filepath), PLAYER_LOG_PATH, formatedDate, "player");
	LogMapChange(admin_filepath, mapName);
	LogMapChange(player_filepath, mapName);
}

void FormatLogPath(char[] filepath, int maxlen, const char[] logPath, const char[] date, const char[] type)
{
	BuildPath(Path_SM, filepath, maxlen, "%s/%s_%s.log", logPath, date, type);
}

void LogMapChange(const char[] filepath, const char[] mapName)
{
	char formatedTime[64];
	FormatTime(formatedTime, sizeof(formatedTime), "%H:%M:%S", GetTime());
	File logFile = OpenFile(filepath, "a+");
	if (logFile == null)
	{
		LogError("Could not open log file: %s", filepath);
		return;
	}
	logFile.WriteLine("");
	logFile.WriteLine("%s - ===== Map change to %s =====", formatedTime, mapName);
	logFile.WriteLine("");
	delete logFile;
}

public void OnRebuildAdminCache(AdminCachePart part)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
			clientIsAdmin[client] = IsPlayerAdmin(client);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (!client || IsFakeClient(client))
		return;
	if (clientConnected[client])
		return;
	clientConnected[client] = true;
	clientIsAdmin[client] = IsPlayerAdmin(client);
	LogClientAction(client, true);
}

public void Event_PlayerDisconnect(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || IsFakeClient(client))
		return;
	if (!clientConnected[client])
		return;
	clientConnected[client] = false;
	LogClientAction(client, false, event);
	clientIsAdmin[client] = false;
}

void LogClientAction(int client, bool isConnecting, Event event = null)
{
	char playerName[64], authId[64], ipAddress[64], country[64] = "Unknown", formatedTime[64];
	GetClientName(client, playerName, sizeof(playerName));
	if (!GetClientAuthId(client, AuthId_Steam2, authId, sizeof(authId), false))
		strcopy(authId, sizeof(authId), "Unknown");
	if (!GetClientIP(client, ipAddress, sizeof(ipAddress)))
		strcopy(ipAddress, sizeof(ipAddress), "Unknown");
	if (!GeoipCountry(ipAddress, country, sizeof(country)))
		strcopy(country, sizeof(country), "Unknown");
	FormatTime(formatedTime, sizeof(formatedTime), "%H:%M:%S", GetTime());
	char logFilePath[PLATFORM_MAX_PATH];
	strcopy(logFilePath, sizeof(logFilePath), clientIsAdmin[client] ? admin_filepath : player_filepath);
	File logFile = OpenFile(logFilePath, "a+");
	if (logFile == null)
	{
		LogError("Could not open log file: %s", logFilePath);
		return;
	}
	if (isConnecting)
		logFile.WriteLine("%s - <%s> <%s> <%s> CONNECTED from <%s>", formatedTime, playerName, authId, ipAddress, country);
	else
	{
		int connectionTime = RoundToCeil(GetClientTime(client) / 60);
		char reason[128] = "Unknown";
		if (event != null)
			event.GetString("reason", reason, sizeof(reason));
		logFile.WriteLine("%s - <%s> <%s> <%s> DISCONNECTED after %d minutes. <%s>", formatedTime, playerName, authId, ipAddress, connectionTime, reason);
	}
	delete logFile;
}

stock bool IsPlayerAdmin(int client)
{
	return CheckCommandAccess(client, "Generic_admin", ADMFLAG_GENERIC, false);
}