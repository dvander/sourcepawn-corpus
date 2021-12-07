// Blind Luck - A modification for the game Left4Dead */
// Copyright 2009 James Richardson */

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
*			- Seperated Blind Luck configuation into cfg/sourcemod/plugin.blindluck.
* Version 1.1.0
*     - No longer requires the spoofing of sv_cheats. This gets rid of the client messages.
*     - Added ConVar 'bl_hud_to_apply' to allow administrators to decide which parts of the HUD to hide.
*     - Event 'player_no_longer_it' is now unhooked when it is not needed. 
*     - Added minimum and maximum values to 'bl_blind_time'. The maximum time is 25 seconds with the minimum being 5 seconds.
*     - Now compiles without indentation warnings.
* Version 1.1.1
*     - Fixes error when restoring the HUD on some entities.
* Version 1.1.2
*     - Transferred to the new syntax.
*/

#pragma semicolon 1
#pragma newdecls required

// Define constants
#define PLUGIN_VERSION    "1.1.2"
#define PLUGIN_NAME       "Blind Luck"
	
// Include necessary files
#include <sourcemod>
#include <sdktools>

// Create ConVar handles
Handle blind_time		= INVALID_HANDLE;
Handle hide_until_dry 	= INVALID_HANDLE;
Handle hud_to_apply   	= INVALID_HANDLE;

// Create timer array that keeps track of the time the HUD has been hidden for each player
Handle time_to_dry[64];

// Metadata for the mod
public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "James Richardson (grandwazir)",
	description = "Hides the majority of a survivors HUD when he is vomitted on",
	version = PLUGIN_VERSION,
	url = "http://code.james.richardson.name"
}

public void OnPluginStart()
{
  // Create ConVars	
	CreateConVar("bl_version", PLUGIN_VERSION, "The version of Blind luck plugin.", FCVAR_NONE|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	blind_time = CreateConVar("bl_blind_time", "15.0", "The time to hide the hud when a player has been vomitted on.", FCVAR_NONE, true, 5.0, true, 25.0);
	hide_until_dry = CreateConVar("bl_hide_until_dry", "1", "Whether or not we hide the hud until a player is completely dry.", FCVAR_NONE);	
  	hud_to_apply = CreateConVar("bl_hud_to_apply", "64", "What bitmask to apply to the HUD. For more infomation on the masks available type 'help hide_hud' in your console'", FCVAR_NONE, true, 0.0, true, 256.0);
  	// Hook events
  	HookEvent("player_now_it", Event_PlayerWet);
	HookEvent("player_no_longer_it", Event_PlayerDry);
  	HookConVarChange(hide_until_dry, ConVarChanged);
	// Execute configuation file if it exists
  	AutoExecConfig(true);
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
  if (StrEqual(newValue, "0")) 
    UnhookEvent("player_no_longer_it", Event_PlayerDry); 
  else
    HookEvent("player_no_longer_it", Event_PlayerDry); 
}

// When a player is vomitted on hide their HUD
public Action Event_PlayerWet(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	// Make sure the user is not a bot.
	if (!IsFakeClient(client))
	{
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetConVarInt(hud_to_apply));
		if (!GetConVarBool(hide_until_dry))
      		time_to_dry[client] = CreateTimer(GetConVarFloat(blind_time), RestoreHud, client);
	}
	return Plugin_Continue;
}

// When a player is completely dry restore their hud
public Action Event_PlayerDry(Handle event, const char[] name, bool dontBroadcast)
{
	if (GetConVarBool(hide_until_dry))
	{	
    	int client = GetClientOfUserId(GetEventInt(event, "userid"));
    	if (!IsFakeClient(client))
      		RestoreHud(INVALID_HANDLE, client);
	}
	return Plugin_Continue;
}

// Reset the HUD back to normal
public Action RestoreHud(Handle timer, any client)
{
	if ( IsValidEntity(client) )
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
}