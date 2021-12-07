/**
 * ==========================================================================
 * SourceMod Terrible Enable Full Alltalk
 *
 * by Sheepdude
 *
 * SourceMod Forums Plugin Thread URL:
 * https://forums.alliedmods.net/showthread.php?t=155895&page=2
 *
 * This plugin changes sv_full_alltalk to 30 seconds after map start.
 * If you know a better way, go for it.
 *
 * CHANGELOG
 *
 * Version 0.01 (25 September 2012)
 * -Initial Version
 *
 * Version 0.02 (28 September 2012)
 * Current Version
 * -Cvar is now set every round instead of just at map start.
 * 
 */

#include <sourcemod>
#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Terrible Enable Full Alltalk",
	author = "Sheepdude",
	description = "Sets sv_full_alltalk 1 on map start",
	version = "0.02",
	url = "https://forums.alliedmods.net/showthread.php?t=155895&page=2"
};

new Handle:FULL_ALLTALK = INVALID_HANDLE;

public OnPluginStart()
{
	FULL_ALLTALK = FindConVar("sv_full_alltalk");
	HookEvent("round_freeze_end", OnNewRound, EventHookMode_Pre);
}

public OnNewRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(FULL_ALLTALK != INVALID_HANDLE)
		SetConVarInt(FULL_ALLTALK, 1);
}