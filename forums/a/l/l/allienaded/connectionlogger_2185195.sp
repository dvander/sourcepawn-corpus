#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Connection Logger",
	author = "STAV3",
	description = "Logs client Name, SteamID and IP.",
	version = "1.1",
	url = ""
}

public OnMapStart()
{
	new String:map[64];
	GetCurrentMap(map, sizeof(map));
	
	decl String:filepath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filepath, sizeof(filepath), "logs/Connections.log");
	LogToFileEx(filepath, "-------- Mapchange to %s --------", map);
	return;
}

public OnClientAuthorized(client, const String:steamid[])
{
	if (IsFakeClient(client))
		return;
	
	new String:ip[64];
	GetClientIP(client, ip, sizeof(ip));
	
	decl String:filepath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filepath, sizeof(filepath), "logs/Connections.log");
	LogToFileEx(filepath, "%L<%s> connected.", client, ip);
	return;
}

public OnClientDisconnect(client)
{
	if (IsFakeClient(client))
		return;
	
	new String:ip[64];
	GetClientIP(client, ip, sizeof(ip));
	
	decl String:filepath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filepath, sizeof(filepath), "logs/Connections.log");
	LogToFileEx(filepath, "%L<%s> disconnected.", client, ip);
	return;
}
