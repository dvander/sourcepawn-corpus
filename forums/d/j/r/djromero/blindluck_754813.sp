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
*/

/* Define constants */
#define PLUGIN_VERSION    "1.0.0"
#define PLUGIN_NAME       "Blind Luck"
#define PLUGIN_TAG  	  	"[BL] "
#define MAX_PLAYERS 			8


/* Include necessary files */
#include <sourcemod>

/* ConVars */
new Handle:BlindTime		= INVALID_HANDLE
new Handle:HideUntilDry = INVALID_HANDLE

/* Timer array */
new Handle:TimeToDry[MAX_PLAYERS+1]

/* Metadata for the mod */
public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = "James Richardson (grandwazir)",
	description = "Hides the majority of a survivors HUD when he is vomitted on",
	version = PLUGIN_VERSION,
	url = "www.grandwazir.com"
};

public OnPluginStart() {
	CreateConVar("bl_version", PLUGIN_VERSION, "The version of All4Dead plugin.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	BlindTime = CreateConVar("bl_time", "10.0", "The time to hide the hud when a player has been vomitted on.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HideUntilDry = CreateConVar("bl_hide_until_dry", "1", "Whether or not we hide the hud until a player is completely dry.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);	
	HookEvent("player_now_it", Event_PlayerWet)
	HookEvent("player_no_longer_it", Event_PlayerDry)
}

/* When a player is vomitted on hide their HUD */
public Action:Event_PlayerWet(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	/* Make sure the user is not a bot. */
	if (!IsFakeClient(client)) {
		/* Hide everything except weapon selection and crosshairs */
		StripAndExecuteClientCommand(client, "hidehud", 64)
		if (!GetConVarBool(HideUntilDry)) {
			TimeToDry[client] = CreateTimer(GetConVarFloat(BlindTime), RestoreHud, client)
		}
	}
	return Plugin_Continue
}

/* When a player is completely dry restore their hud */
public Action:Event_PlayerDry(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"))	
	if (GetConVarBool(HideUntilDry) && !IsFakeClient(client)) {
		RestoreHud(INVALID_HANDLE, client)
	}
	return Plugin_Continue
}

/* Reset the HUD back to normal */
public Action:RestoreHud(Handle:timer, any:client) {
	StripAndExecuteClientCommand(client, "hidehud", 0)	
	TimeToDry[client] = INVALID_HANDLE
}

/* Helper Functions */
/* This function strips the cheat flags from a command, executes it and then restores it to its former glory. */
/* Does the same as the above but for client commands */
StripAndExecuteClientCommand(client, const String:command[], param) {
	
	// Removes sv_cheat flag from command
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	
	ClientCommand(client, "%s %d", command, param)
	
	// Restore sv_cheat flag on command
	SetCommandFlags(command, flags);

}
