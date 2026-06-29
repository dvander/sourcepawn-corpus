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
#pragma semicolon 1
#include <sourcemod>
#include <autoexecconfig>

new String:logFile[256],
	bool:Mapsonly, bool:Nosounds, bool:Immun, Logging;

#define PLUGIN_VERSION "1.5"

public Plugin:myinfo = 
{
	name = "Custom Files Filter Checker",
	author = "Zuko; rewritten by electronic_m",
	description = "Check if player can download custom files.",
	version = PLUGIN_VERSION,
}

public OnPluginStart()
{
	// Create CVars
	CreateMyCVars();
	
	if(Logging == 2)
		BuildPath(Path_SM, logFile, sizeof(logFile), "logs/customfilesfilterchecker.log");
	
	LoadTranslations("customfilesfilterchecker.phrases");
}

public OnClientPostAdminCheck(client)
{	
	if (IsClientConnected(client) && !(Immun && GetUserAdmin(client) != INVALID_ADMIN_ID))
		QueryClientConVar(client, "cl_allowdownload", ConVarQueryFinished:CvarChecking_AllowDownload, client);
}

public CvarChecking_AllowDownload(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (!StringToInt(cvarValue))
	{
		KickPlayer(client, cvarName, cvarValue, "1");
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
	new String:Values[30] = "all", bool:mustKick = true;
	
	if (strcmp(cvarValue, "all", false) == 0)
	{
		mustKick = false;
	}
	
	if (Nosounds)
	{
		Format(Values, sizeof(Values),"%s, %s",Values, "nosounds");
		
		if (strcmp(cvarValue, "NoSounds", false) == 0)
		{
			mustKick = false;
		}
	}
	
	if (Mapsonly)
	{
		Format(Values, sizeof(Values),"%s, %s",Values, "mapsonly");
		
		if (strcmp(cvarValue, "mapsonly", false) == 0)
		{
			mustKick = false;
		}
	}
	
	if (mustKick)
	{
		KickPlayer(client, cvarName, cvarValue, Values);
	}
}

stock KickPlayer(client, const String:cvarName[], const String:cvarValue[], const String:Values[])
{
	new	String:name[MAX_NAME_LENGTH], String:steamid[64];
	GetClientName(client, name, sizeof(name));
	GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
	
	switch (Logging)
	{
		case 1: LogMessage("LogMessage %s %s %s %s", name, steamid, cvarName, cvarValue);
		case 2: LogToFile(logFile, "LogMessage %s %s %s %s", name, steamid, cvarName, cvarValue);
	}
		
	KickClient(client, "%t", "KickMessage", cvarName, Values);
}

stock CreateMyCVars()
{
	new bool:appended;

	// Set the file for the include
	AutoExecConfig_SetFile("plugin.customfilesfilterchecker");

	HookConVarChange((CreateConVar("customchecker_version", PLUGIN_VERSION,
	"Custom Files Filter Checker Version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD)), z_CvarVersionChanged);

	new Handle:hRandom;	
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_cffc_mapsonly", "0",
	"If 1, cl_downloadfilter mapsonly is allowed.", _, true, 0.0, true, 1.0)), z_CvarMapsonlyChanged);
	Mapsonly = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_cffc_nosounds", "1",
	"If 1, cl_downloadfilter nosounds is allowed.", _, true, 0.0, true, 1.0)), z_CvarNosoundsChanged);
	Nosounds = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_cffc_immun", "0",
	"No check for admins.", _, true, 0.0, true, 1.0)), z_CvarImmunChanged);
	Immun = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_cffc_logging", "1",
	"If and how kicks will be logged.\n  0 - Off\n  1 - SourceMod-Logfile\n  2 - Own Logfile (only one file all the time!)", _, true, 0.0, true, 2.0)), z_CvarLoggingChanged);
	Logging = GetConVarInt(hRandom);
	SetAppend(appended);
	
	CloseHandle(hRandom);
	
	AutoExecConfig(true, "plugin.customfilesfilterchecker");

	// Cleaning is an expensive operation and should be done at the end
	if (appended)
		AutoExecConfig_CleanFile();
}

stock SetAppend(&appended)
{
	if (AutoExecConfig_GetAppendResult() == AUTOEXEC_APPEND_SUCCESS)
		appended = true;
}

public z_CvarVersionChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(newValue, PLUGIN_VERSION))
		SetConVarString(cvar, PLUGIN_VERSION);
}

public z_CvarMapsonlyChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
	Mapsonly = GetConVarBool(cvar);

public z_CvarNosoundsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
	Nosounds = GetConVarBool(cvar);

public z_CvarImmunChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
	Immun = GetConVarBool(cvar);

public z_CvarLoggingChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Logging = GetConVarInt(cvar);
	
	if (Logging == 2)
		BuildPath(Path_SM, logFile, sizeof(logFile), "logs/customfilesfilterchecker.log");
}