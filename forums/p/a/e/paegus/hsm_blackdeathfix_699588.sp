/*
 * Hidden:SourceMod - Black-Death Fix
 *
 * Description:
 *   Prevents the black-screen of death from occuring when you fall to your DOOM!
 *
 * Changelog:
 *  v1.0.0
 *   Initial release.
 *
 */

#define PLUGIN_VERSION		"1.0.0"

#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo =
{
	name		= "H:SM - BSOD-Fix",
	author		= "Paegus",
	description	= "Prevents the black-screen of death from occuring when you fall to your DOOM!",
	version		= PLUGIN_VERSION,
	url			= "http://forum.hidden-source.com/forumdisplay.php?f=13"
}

public OnPluginStart()
{
	CreateConVar(
		"hsm_bsodfix_version",
		PLUGIN_VERSION,
		"H:SM - BSOD Fix version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);

	HookEvent("player_hurt", event_PlayerHurt, EventHookMode_Pre);
}

public event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iAttacker = GetClientOfUserId(GetEventInt(event, "attacker")); // Get attacker.

	if (iAttacker) // not world
		return;

	new iVictim = GetClientOfUserId(GetEventInt(event, "userid")); // Get attacker.
	new iHealth = GetClientHealth(iVictim);

	if (iHealth < 0) // They'll die
	{
		SetEntData(iVictim, FindDataMapOffs(iVictim, "m_iHealth"), iHealth + 666,	4, true);
		if (IsFakeClient(iVictim))
			FakeClientCommand(iVictim, "kill");
		else
			ClientCommand(iVictim, "kill");
	}
}
