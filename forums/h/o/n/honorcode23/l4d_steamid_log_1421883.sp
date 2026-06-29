#include <sourcemod>

new Handle:g_cvarLog;
new Handle:g_cvarName;

public OnPluginLoad()
{
	g_cvarLog = CreateConVar("l4d_steamid_log_enabled", "1", "Log all players names, steam id and ip");
	g_cvarName = CreateConVar("l4d_steamid_log_filename", "steamlog", "Name of the file where the info is logged to");
}

public OnClientPostAdminCheck(client)
{
	decl String:SteamID[256], String:IP[16];
	GetClientIP(client, IP, sizeof(IP));
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	LogInfo("Player Connected: [Name: %N], [STEAMID: %s], [IP: %s]", client, SteamID, IP);
}

stock LogInfo(const String:format[], any:...)
{	
	if(GetConVarBool(g_cvarLog))
	{
		decl String:buffer[512];
		VFormat(buffer, sizeof(buffer), format, 2);

		new Handle:file;
		decl String:FileName[256], String:sTime[256], String:sName[64];
		GetConVarString(g_cvarName, sName, sizeof(sName));
		FormatTime(sTime, sizeof(sTime), "%Y%m%d");
		BuildPath(Path_SM, FileName, sizeof(FileName), "logs/%s_%s.log", sName, sTime);
		file = OpenFile(FileName, "a+");
		FormatTime(sTime, sizeof(sTime), "%b %d |%H:%M:%S| %Y");
		WriteFileLine(file, "%s: %s", sTime, buffer);
		FlushFile(file);
		CloseHandle(file);
	}
}