/*
 * Custom Files Filter Checker 
 *
 * Simple plugin for kicking players who have disabled downloading custom files
 * cl_allowdownload and cl_downloadfilter "none" - players with cl_downloadfilter "nosounds"
 * can join to server.
 * I made this plugin to avoid situations when some players playing with BIG RED ERRORS on screen (eg. missing hat models).
 *
 * Version 1.0
 * - Initial release 
 * Version 1.1
 * - Added immunity for complaining admins^^... (for ROOT Admin)
 * Version 1.2
 * - Fixed logging
 * Version 1.3
 * - Redone immunity
 * Version 1.4
 * - Minor Fixes
 *
 * Zuko / #hlds.pl @ Qnet / zuko.isports.pl /
 *
 */

#include <sourcemod>

new String:logFile[256];

#define PLUGIN_VERSION "1.4"

public Plugin:myinfo = 
{
	name = "Custom Files Filter Checker",
	author = "Zuko",
	description = "Check if player can download custom files.",
	version = PLUGIN_VERSION,
	url = "http://zuko.isports.pl/"
}

public OnPluginStart()
{
	CreateConVar("customchecker_version", PLUGIN_VERSION, "Custom Files Filter Checker Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/customfilesfilterchecker.log");
	
	LoadTranslations("customfilesfilterchecker.phrases");
}

public OnClientPostAdminCheck(client)
{	
	if (IsClientConnected(client))
	{
		QueryClientConVar(client, "cl_allowdownload", ConVarQueryFinished:CvarChecking_AllowDownload, client);
	}
}

public CvarChecking_AllowDownload(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	new icvarValue = StringToInt(cvarValue)
	new String:name[20], String:steamid[100];
	if (((icvarValue) == 0) && (GetUserFlagBits(client) & ADMFLAG_ROOT != ADMFLAG_ROOT))
	{
		GetClientName(client, name, 19);
		GetClientAuthString(client, steamid, 99);
		LogToFile(logFile, "%T", "EnableDownloading_Log", LANG_SERVER, name, steamid);
		KickClient(client, "%t", "EnableDownloading", LANG_SERVER);
	}
	else
	{
		if (IsClientConnected(client))
		{
			QueryClientConVar(client, "cl_downloadfilter", ConVarQueryFinished:CvarChecking_DownloadFilter, client);
		}
	}
}

public CvarChecking_DownloadFilter(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	new String:name[20], String:steamid[100];
	if ((strcmp(cvarValue,"none",false) == 0) && (GetUserFlagBits(client) & ADMFLAG_ROOT != ADMFLAG_ROOT))
	{
		GetClientName(client, name, 19);
		GetClientAuthString(client, steamid, 99);
		LogToFile(logFile, "%T", "DownloadFilter_Log", LANG_SERVER, name, steamid);
		KickClient(client, "%t", "DownloadFilter", LANG_SERVER);
	}
}