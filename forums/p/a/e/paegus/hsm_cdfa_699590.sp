/*
 * Hidden:SourceMod - DownloadFilter fix
 *
 * Description:
 *  Automatically set's connecting player's cl_downloadfilter to all.
 *  Can various things with the comma separated string.
 *
 * Changelog:
 *  v1.0.1
 *   Removed dependancy on hsm/hsm.sp
 *   Shifted to server console variable to store comma separated command string.
 *  v1.0.0
 *   Initial release
 *
 */

#define PLUGIN_VERSION		"1.0.1"

#pragma semicolon 1

#include <sourcemod>

new Handle:cvarString = INVALID_HANDLE;
new String:szString[] = "cl_downloadfilter all, cl_allowdownload 1";

public Plugin:myinfo =
{
	name		= "H:SM - DownloadFilter Fix",
	author		= "Paegus",
	description	= "Automatically sets cl_downloadfilter to all on connecting clients",
	version		= PLUGIN_VERSION,
	url			= "http://forum.hidden-source.com/forumdisplay.php?f=13"
}

public OnPluginStart()
{
	CreateConVar(
		"hsm_cdfa_version",
		PLUGIN_VERSION,
		"H:SM CDFA version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);

	cvarString = CreateConVar(
		"hsm_cdfa_string",
		szString,
		"String to execute on connected client.",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);
}

public OnClientPostAdminCheck(client)
{
	decl String:buffer[256];
	GetConVarString(cvarString, buffer, sizeof(buffer));

	PrintToConsole(client, "[H:SM CDFA] Server is enforcing: %s", buffer); // Inform client.

	ReplaceString(buffer, sizeof(buffer), ",", ";"); // replace commas with semi-colons

	ClientCommand(client, "%s;host_writeconfig", buffer); // Execute on client and update their config.cfg
}
