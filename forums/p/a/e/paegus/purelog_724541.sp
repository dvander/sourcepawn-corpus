/*
 * Pure kick log
 *
 * Description:
 *  Logs client disconnection due to file inconsistencies.
 *
 * Changelog:
 *  v1.0.0
 *   Initial release.
 *
 * Contact:
 *  Paegus: paegus@gmail.com
 *  SourceMod: http://www.sourcemod.net
 */

#define PLUGIN_VERSION		"1.0.0"

public Plugin:myinfo =
{
	name		= "Pure Log",
	author		= "Paegus",
	description	= "Logs client disconnection due to file inconsistencies.",
	version		= PLUGIN_VERSION,
	url			= "http://forum.hidden-source.com/showthread.php?t=9853"
}

static const String:g_CRCLogFileName[] = "CRCDiscos.log";

public OnPluginStart()
{
	CreateConVar(
		"hsm_pure_version",
		PLUGIN_VERSION,
		"H:SM Pure logger version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);

	HookEvent("player_disconnect", event_Generic, EventHookMode_Pre);
}

/*
Server event "player_disconnect", Tick Int:
- "userid" = Int
- "reason" = String
- "name" = String
- "networkid" = String
L 12/06/2008 - 14:33:15: "NAME<UID><STEAMID><TEAM>" disconnected (reason "REASON.")

Pure server: client has loaded extra file [GAME]\path/to\file\filename.ext. File must be removed to play on this server.
Pure server: file [GAME]\path/to\file\filename.ext does not match the server's file."
*/
public Action:event_Generic(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:szReason[256];
	GetEventString(event, "reason", szReason, sizeof(szReason));	// Why where they kicked?
	
	if (StrContains(szReason, "Pure server:", false) != -1)	// File consistency kick
	{
		decl String:szFilePath[256];
		BuildPath(Path_SM, szFilePath, sizeof(szFilePath), "logs/%s", g_CRCLogFileName);	// Build log-file's path
		
		new Handle:CRCLogFile = OpenFile(szFilePath, "a+");	// Open log-fire
		
		if (CRCLogFile != INVALID_HANDLE)
		{
			// Build the log-line
			decl String:szDate[32];
			decl String:szAuth[32];
			decl String:szName[32];
			decl String:szIP[24];
			
			FormatTime(szDate, sizeof(szDate), "%m/%d/%Y - %H:%M:%S");
			GetEventString(event, "networkid", szAuth, sizeof(szAuth));
			GetEventString(event, "name", szName, sizeof(szName));
			GetClientIP(GetClientOfUserId(GetEventInt(event, "userid")), szIP, sizeof(szIP), false)

			WriteFileLine(CRCLogFile, "L %s: %s (%s) (%s) - %s", szDate, szAuth, szName, szIP, szReason);	// Write the log-line

			ServerCommand("sm_chat [PureLog] %s (%s) Kicked for file consistency error.", szAuth, szName);	// Inform any admins present
		}
		else
		{
			LogToGame("[PureLog] Error opening %s for appending", szFilePath);	// Oh no!
		}
		
		CloseHandle(CRCLogFile);	// Close the log-fire
	}
}

