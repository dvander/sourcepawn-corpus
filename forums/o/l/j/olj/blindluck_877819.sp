/*
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/* Blind Luck - A modification for the game Left4Dead */
/* Copyright 2009 James Richardson */

/*
* Version 1.0
* 		- Initial release.
* Version 1.0.1
* 		- Now works with sv_cheats off (thanks TESLA-X4 for the idea).
* Version 1.0.2
* 		- Fixed the two ConVars so they no longer cause error messages in client consoles when connecting.
* 		- Corrected some spelling mistakes in the comments that were bugging me.
* Version 1.0.3
* 		- Fixed ArrayOutOfBounds error.
*			- Seperated Blind Luck configuation into cfg/sourcemod/plugin.blindluck
*/

/* Define constants */
#define PLUGIN_VERSION    "1.0.3"
#define PLUGIN_NAME       "Blind Luck"
#define PLUGIN_TAG  	  	"[BL] "
//#define MAX_PLAYERS 			MAXPLAYERS
		

/* Include necessary files */
#include <sourcemod>
#pragma semicolon 1
/* ConVars */
new Handle:BlindTime		= INVALID_HANDLE;
new Handle:HideUntilDry = INVALID_HANDLE;

/* Timer array */
new Handle:TimeToDry[MAXPLAYERS+1];

/* Metadata for the mod */
public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = "James Richardson (grandwazir)",
	description = "Hides the majority of a survivors HUD when he is vomitted on",
	version = PLUGIN_VERSION,
	url = "www.grandwazir.com"
};

public OnPluginStart() {
	CreateConVar("bl_version", PLUGIN_VERSION, "The version of All4Dead plugin.", FCVAR_PLUGIN);
	BlindTime = CreateConVar("bl_time", "15.0", "The time to hide the hud when a player has been vomitted on.", FCVAR_PLUGIN);
	HideUntilDry = CreateConVar("bl_hide_until_dry", "1", "Whether or not we hide the hud until a player is completely dry.", FCVAR_PLUGIN);	
	HookEvent("player_now_it", Event_PlayerWet);
	HookEvent("player_no_longer_it", Event_PlayerDry);
	AutoExecConfig(true)	;
}

public OnConfigsExecuted() {
	new String:version[16];
	GetConVarString(FindConVar("bl_version"), version, sizeof(version));
	if (!StrEqual(version, PLUGIN_VERSION)) {
		LogAction(0, -1, "WARNING: Your plugin.blindluck.cfg is out of date. Please delete it and restart your server.");
	}
	LogAction(0, -1, "plugin.blindluck.cfg has been loaded.");
}


/* When a player is vomitted on hide their HUD */
public Action:Event_PlayerWet(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	/* Make sure the user is not a bot. */
	if (!IsFakeClient(client)) {
		SetEntProp(client, Prop_Send, "m_iHideHUD", 64);
		if (!GetConVarBool(HideUntilDry)) {
			TimeToDry[client] = CreateTimer(GetConVarFloat(BlindTime), RestoreHud, client);
		}
	}
	return Plugin_Continue;
}

/* When a player is completely dry restore their hud */
public Action:Event_PlayerDry(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetConVarBool(HideUntilDry) && IsValidClient(client)) {
		RestoreHud(INVALID_HANDLE, client);
	}
	return Plugin_Continue;
}

/* Reset the HUD back to normal */
public Action:RestoreHud(Handle:timer, any:client) 
{
	if (IsValidClient(client))
	{
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
		TimeToDry[client] = INVALID_HANDLE;
	}
}

public IsValidClient (client)
{
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
		
	return true;
}
	
