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
#define CVAR_FLAGS FCVAR_NOTIFY
	
// Include necessary files
#include <sourcemod>
#include <sdktools>

// Create ConVar handles
ConVar blindluck_on, blind_time, hide_until_dry, hud_to_apply;
bool bPluginOn = false, bHooked = false, bHideUntilDry = false, EventDryHooked = false;
float fBlindTime = 0.0;
int iHudToApply = 0;
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
	CreateConVar("bl_version", PLUGIN_VERSION, "The version of Blind luck plugin.", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	blindluck_on = CreateConVar("bl_plugin_on", "1", "Enable/Disable plugin.", CVAR_FLAGS, true, 0.0, true, 1.0);
	blind_time = CreateConVar("bl_blind_time", "15.0", "The time to hide the hud when a player has been vomitted on.", CVAR_FLAGS, true, 5.0, true, 25.0);
	hide_until_dry = CreateConVar("bl_hide_until_dry", "1", "Whether or not we hide the hud until a player is completely dry.", CVAR_FLAGS, true, 0.0, true, 1.0);
  	hud_to_apply = CreateConVar("bl_hud_to_apply", "64", "What bitmask to apply to the HUD. For more infomation on the masks available type 'help hide_hud' in your console'", CVAR_FLAGS, true, 0.0, true, 256.0);

  	blindluck_on.AddChangeHook(ConVarPluginOnChanged);
	blind_time.AddChangeHook(ConVarsChanged);
	hide_until_dry.AddChangeHook(ConVarsChanged);
	hud_to_apply.AddChangeHook(ConVarsChanged);
	// Execute configuation file if it exists
  	AutoExecConfig(true);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarPluginOnChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
	IsAllowed();
}

void ConVarsChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
	fBlindTime = blind_time.FloatValue;
	bHideUntilDry = hide_until_dry.BoolValue;
	if(!bHideUntilDry && EventDryHooked)
	{
		UnhookEvent("player_no_longer_it", Event_PlayerDry);
		EventDryHooked = false;
	}
	iHudToApply = hud_to_apply.IntValue;
}

void IsAllowed()
{
	bPluginOn = blindluck_on.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		ConVarsChanged(null, "", "");
		HookEvent("player_now_it", Event_PlayerWet);
		if(bHideUntilDry && !EventDryHooked)
		{
			HookEvent("player_no_longer_it", Event_PlayerDry);
			EventDryHooked = true;
		}
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("player_now_it", Event_PlayerWet);
		if(bHideUntilDry && EventDryHooked)
		{
			UnhookEvent("player_no_longer_it", Event_PlayerDry);
			EventDryHooked = false;
		}
	}
}

// When a player is vomitted on hide their HUD
Action Event_PlayerWet(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	// Make sure the user is not a bot.
	if (IsValidRealClient(client))
	{
		SetEntProp(client, Prop_Send, "m_iHideHUD", iHudToApply);
		if (!bHideUntilDry)
		{
      		time_to_dry[client] = CreateTimer(fBlindTime, RestoreHud, client);
		}
	}
	return Plugin_Continue;
}

// When a player is completely dry restore their hud
Action Event_PlayerDry(Event event, const char[] name, bool dontBroadcast)
{
	if (bHideUntilDry)
	{	
    	int client = GetClientOfUserId(event.GetInt("userid"));
    	if (IsValidRealClient(client))
		{
      		RestoreHud(INVALID_HANDLE, client);
		}
	}
	return Plugin_Continue;
}

// Reset the HUD back to normal
Action RestoreHud(Handle timer, any client)
{
	if (IsValidRealClient(client))
	{
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
	}
	return Plugin_Stop;
}

bool IsValidRealClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}
