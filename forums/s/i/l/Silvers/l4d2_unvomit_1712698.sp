#define PLUGIN_VERSION 		"1.0"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Unvomit
*	Author	:	SilverShot
*	Descrp	:	Removes the vomit effect from a survivor.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=185653

========================================================================================
	Change Log:

1.0 (20-May-2012)
	- Initial release.

======================================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS				FCVAR_PLUGIN|FCVAR_NOTIFY

new Handle:g_hVomit;

public Plugin:myinfo =
{
	name = "[L4D2] Unvomit",
	author = "SilverShot",
	description = "Removes the vomit effect from a survivor .",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=185653"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if( strcmp(sGameName, "left4dead2", false) )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	new Handle:hGameConf = LoadGameConfigFile("l4d2_unvomit");
	if( hGameConf == INVALID_HANDLE )
	{
		SetFailState("Failed to load gamedata: l4d2_unvomit.txt");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTerrorPlayer::OnITExpired") == false )
		SetFailState("Failed to find signature: CTerrorPlayer::OnITExpired");
	g_hVomit = EndPrepSDKCall();
	if( g_hVomit == INVALID_HANDLE )
		SetFailState("Failed to create SDKCall: CTerrorPlayer::OnITExpired");

	RegAdminCmd("sm_unvomit", sm_unvomit, ADMFLAG_ROOT);
}

public Action:sm_unvomit(client, args)
{
	if( client && GetClientTeam(client) == 2 && IsPlayerAlive(client) )
	{
		SDKCall(g_hVomit, client);
	}
	return Plugin_Handled;
}