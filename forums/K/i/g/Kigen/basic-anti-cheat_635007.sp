/**
* VBAC - Very Basic Anti Cheat
*
* Description:
*	This pluging does two thinsg currently: 
*	1. Checks to see if a client has sv_cheats enabled and bans them
*	2. Checks to see if a client has mat_wireframe enabled and bans them
*	3. Checks to see if a client has the name of unconnected (/0) and bans them
*
*
* Usage:
*	 Install and go!
*	
* Thanks to:
* 	Everyone in http://forums.alliedmods.net/showthread.php?t=72097
*	and in http://forums.alliedmods.net/showthread.php?t=72170
*	  
* Version 1.0
* 	- After a few attempts :-P
*
* Version 2.0
*	- Added wireframe check, added bot check, altered  version var & tidied code
*
*/
//////////////////////////////////////////////////////////////////
// Defines
//////////////////////////////////////////////////////////////////
#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "2.1"

//////////////////////////////////////////////////////////////////
// Delcare Handles
//////////////////////////////////////////////////////////////////
new Handle:g_CheckCvar;
new Handle:g_cvarToCheck;

//////////////////////////////////////////////////////////////////
// Plugin Info
//////////////////////////////////////////////////////////////////
public Plugin:myinfo = 
{
	name = "VBAC",
	author = "MoggieX",
	description = "Very Basic Anti Cheat",
	version = PLUGIN_VERSION,
	url = "http://www.UKManDown.co.uk"
};

//////////////////////////////////////////////////////////////////
// Normal CVars + Hooking
//////////////////////////////////////////////////////////////////
public OnPluginStart()
{
	CreateConVar("sm_vbac_version", PLUGIN_VERSION, "VBAC Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvarToCheck = CreateConVar("sm_vbac_value", "sv_cheats", "sv_cheats to check against",FCVAR_PRINTABLEONLY);	//|FCVAR_REPLICATED|FCVAR_NOTIFY
	HookEvent("player_spawn", Event_player_spawn);
}

//////////////////////////////////////////////////////////////////
// Player checking on spawn event
//////////////////////////////////////////////////////////////////
public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
 {

	// Added check to make sure sv_cheats is not enabled and this will save everyone for getting banned if some nubcake enables the checked server var

	// Declarations
	decl String:check[65];

	// Stuff the value in a handle
	GetConVarString(g_cvarToCheck, check, 65);
	g_CheckCvar = FindConVar(check);

	// now check against it and if its OFF do *stuff*
	if (GetConVarInt(g_CheckCvar) == 0)
	{

		// Get Client
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		// Check to see if client is valid.
		if ( client && IsClientConnected(client) && !IsFakeClient(client) )
		{

			// Query the client for sv_cheats - ClientConVar
			QueryClientConVar(client, "sv_cheats", ConVarQueryFinished:ClientConVar, client);

			// Query the client for mat_wireframe - ClientConVar2
			QueryClientConVar(client, "mat_wireframe", ConVarQueryFinished:ClientConVar2, client);
		}

	}

	// Close Handles as its polite & saves memory
	CloseHandle(g_CheckCvar);
	CloseHandle(g_cvarToCheck);

	return Plugin_Continue;
}

//////////////////////////////////////////////////////////////////
// SV_CHEATS + Name Check - Note: returning value does nothing
//////////////////////////////////////////////////////////////////
public ClientConVar(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
 {

	// Check if client is connected - Kigen
	if ( !IsClientConnected(client) )
		return;

	// Declarations
	decl String:player_name[65];
	decl String:steam_id[32];

	// why is this like this? I have no idea!
	steam_id[0] = '\0';

	// Get Steam ID
	GetClientAuthString(client, steam_id, sizeof(steam_id));

	// Get client Details
	GetClientName(client, player_name, sizeof(player_name));

	// For Interger values
	new cvarValueNew = StringToInt(cvarValue);

	//if sv_cheats is not equalto 0 then we ban the player
	if (cvarValueNew != 0)
	{
		// Notify in chatas i'd want to wet my panties when we get one
		PrintToChatAll("\x04======== \x03CHEATER FOUND! \x04========");
		PrintToChatAll("\x03[VBAC CHEATER FOUND!] \x04Name: \x03%s \x04SteamID: \x03%s \x04CVar: \x03%s \x04CVar Value: \x03%s", player_name, steam_id, cvarName, cvarValue);
		PrintToChatAll("\x04======== \x03CHEATER FOUND! \x04========");

		// Log the event
		LogAction(client, -1, "[VBAC SV_CHEATS BAN] Name: %s SteamID: %s was BANNED for CVar: %s CVar Value: %s", player_name, steam_id, cvarName, cvarValue);

		// Ban the *
		BanClient(client, 
				0, 
				BANFLAG_AUTO, 
				"sv_cheats_bypass", 
				"VAC Ban Detected #ATC561411", 
				"VBAC",
				client);		
	}


	/***** START: Name Checking ******/

	//this checks to see if the player is unconneted or not the player is unconnected or not
	if (strcmp(player_name, "\0") == 0) 
	{ 
		// Notify in chatas i'd want to wet my panties when we get one
		PrintToChatAll("\x04======== \x03Unconnected Found! \x04========");
		PrintToChatAll("\x03[VBAC] \x04Name: \x03%s \x04SteamID: \x03%s \x04 was found to have an invalid name", player_name, steam_id);
		PrintToChatAll("\x04======== \x03Unconnected Found! \x04========");

		// Log the event
		LogAction(client, -1, "[VBAC NAME BAN] Name: %s SteamID: %s was BANNED for having a name of unconnected", player_name, steam_id);

		// Ban the *
		BanClient(client, 
				0, 
				BANFLAG_AUTO, 
				"unconnected_player", 
				"VAC Ban Detected #ATC561412", 
				"VBAC",
				client);
	}

	/***** END: Name Checking ******/

	return;
}  

//////////////////////////////////////////////////////////////////
// MAT_WIREFRAME
//////////////////////////////////////////////////////////////////
public ClientConVar2(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName2[], const String:cvarValue2[])
 {

	// Check if client is connected - Kigen
	if ( !IsClientConnected(client) )
		return;

	// Declarations
	decl String:player_name[65];
	decl String:steam_id[32];

	// Get Steam ID
	GetClientAuthString(client, steam_id, sizeof(steam_id));

	// Get client Details
	GetClientName(client, player_name, sizeof(player_name));

	// For Interger values
	new cvarValueNew = StringToInt(cvarValue2);

	//if sv_cheats is not equalto 0 then we ban the player
	if (cvarValueNew != 0)
	{
		// Notify in chatas i'd want to wet my panties when we get one
		PrintToChatAll("\x04======== \x03CHEATER FOUND! \x04========");
		PrintToChatAll("\x03[VBAC CHEATER FOUND!] \x04Name: \x03%s \x04SteamID: \x03%s \x04CVar: \x03%s \x04CVar Value: \x03%s", player_name, steam_id, cvarName2, cvarValue2);
		PrintToChatAll("\x04======== \x03CHEATER FOUND! \x04========");

		// Log the event
		LogAction(client, -1, "[VBAC WIREFRAME BAN] Name: %s SteamID: %s was BANNED for CVar: %s CVar Value: %s", player_name, steam_id, cvarName2, cvarValue2);

		// Ban the *
		BanClient(client, 
				0, 
				BANFLAG_AUTO, 
				"mat_wireframe_bypass", 
				"VAC Ban Detected #ATC561410", 
				"VBAC",
				client);
		
	}

	return;
} 