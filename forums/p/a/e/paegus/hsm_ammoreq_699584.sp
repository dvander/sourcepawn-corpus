/*
 * Hidden:SourceMod - Automatic ammo request
 *
 * Description:
 *  Causes the IRIS to automatically request more ammunition when they have no spare primary or secondary magazines.
 *
 * Changelog
 *  v1.0.1
 *   Stopped plugin error for checking world's ammo on world damage
 *  v1.0.0
 *   Initial release.
 */

#define PLUGIN_VERSION		"1.0.1"

#pragma semicolon 1

#include <sourcemod>

new g_osSupplier;				// player class
new g_osRequesting;				// are they already requesting
new g_osPrimary;				// primary weapon
new g_osSecondary;				// secondary weapon
new g_osPrimaryAmmo[4];			// list of primary ammo slots
new g_osSecondaryAmmo[2];		// list of secondary ammo slots
new bool:g_bLocSpam = false;	// avoid player_location spam
new Float:fTimeout = 2.0;		// second for player_location spam
stock g_iHidden;				// Who is the hidden?

public Plugin:myinfo =
{
	name		= "H:SM - Ammo",
	author		= "Paegus",
	description	= "IRIS requests ammo when they run low.",
	version		= PLUGIN_VERSION,
	url			= "http://forum.hidden-source.com/forumdisplay.php?f=13"
}

public OnPluginStart()
{
	CreateConVar(
		"hsm_ammo_version",
		PLUGIN_VERSION,
		"H:SM - Automatic ammo request version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);

	HookEvent("player_location", event_PlayerLocation); // Player changes location
	HookEvent("player_hurt", event_PlayerHurt); // Player gets hurt

	g_osSupplier         = FindSendPropOffs("CSDKPlayer","m_iNewClass");	// Supply class : 0,1
	g_osRequesting       = FindSendPropOffs("CSDKPlayer","m_bRequestAmmo");	// Are they requesting ammo : 0,1
	g_osPrimary          = FindSendPropOffs("CSDKPlayer","m_iPrimary");		// Primary weapon type : 0,1,2,3
	g_osSecondary        = FindSendPropOffs("CSDKPlayer","m_iSecondary");	// Secondary weapon type : 0,1
	new osAmmo           = FindSendPropOffs("CSDKPlayer","m_iAmmo");		// base Ammo offset
	g_osPrimaryAmmo[0]   = osAmmo + 4 * 3;									// FN2000  @ m_iAmmo.003
	g_osPrimaryAmmo[1]   = osAmmo + 4 * 2;									// P90     @ m_iAmmo.002
	g_osPrimaryAmmo[2]   = osAmmo + 4 * 6;									// Shotgun @ m_iAmmo.006
	g_osPrimaryAmmo[3]   = osAmmo + 4 * 7;									// FN303   @ m_iAmmo.007
	g_osSecondaryAmmo[0] = osAmmo + 4 * 4;									// FN57    @ m_iAmmo.004
	g_osSecondaryAmmo[1] = osAmmo + 4 * 5;									// FN-P9   @ m_iAmmo.005
}

public event_PlayerLocation(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bLocSpam) // we're spamming
		return;

	LocSpam();

	AutomaticAmmoRequester(GetClientOfUserId(GetEventInt(event, "userid")));
}

public event_PlayerHurt( Handle:event, const String:name[], bool:dontBroadcast)
{
	AutomaticAmmoRequester(GetClientOfUserId(GetEventInt(event, "userid")));
	AutomaticAmmoRequester(GetClientOfUserId(GetEventInt(event, "attacker")));
}

AutomaticAmmoRequester(iClient)
{
	if (!iClient) // World
		return;

	if (GetClientTeam(iClient) != 2) // Not IRIS
		return;

	if (GetEntData(iClient, g_osRequesting, 4) == 1) // Already requesting
		return;

	if (
		GetEntData(iClient,g_osPrimaryAmmo[GetEntData(iClient,g_osPrimary,4)],4) > 0
		&&
		GetEntData(iClient,g_osSecondaryAmmo[GetEntData(iClient,g_osSecondary,4)],4) > 0
	) // They have spare magazines for both weapons
		return;

	if (LoneDonkey(iClient)) // There is no one to request ammo from
		return;

	// Conditions are ripe for ammo request.
	if (IsFakeClient(iClient)) // Bot
	{
		FakeClientCommand(
			iClient,
			"radio %i",
			3
		);
	}
	else // Human
	{
		ClientCommand(
			iClient,
			"radio %i",
			3
		);
	}
}

LocSpam()
{
	g_bLocSpam = true;
	CreateTimer(fTimeout,tLocSpam);
}

public Action:tLocSpam(Handle:timer)
{
	g_bLocSpam = false;
}

stock bool:LoneDonkey(iLonelyHeart)
{
	new iMaxClients = GetMaxClients();
	for (new iClient = 1; iClient <= iMaxClients; iClient++)
		if (IsClientConnected(iClient) && IsClientInGame(iClient)) // Connected and in-game.
			if (IsPlayerAlive(iClient) && GetClientTeam(iClient) == 2 && iClient != iLonelyHeart) // Alive & IRIS & not client
				if (GetEntData(iClient,g_osSupplier,4) == 1) // there exists a supplier who isn't the client.
					return false; // The request can be answered

	return true; // He's alone. poor bastard!
}

// Sets the hidden.
stock SetHidden()
{
	new iMaxClients = GetMaxClients();
	for (new iClient = 1; iClient <= iMaxClients; iClient++)
		if (IsClientConnected(iClient) && IsClientInGame(iClient)) // Connected and in-game.
			if (IsPlayerAlive(iClient) && GetClientTeam(iClient) == 3) // Alive & Hidden
				g_iHidden = iClient;
}

stock bool:LoneWolf(iLonelyHeart)
{
	new iMaxClients = GetMaxClients();
	for (new iClient = 1; iClient <= iMaxClients; iClient++)
		if (IsClientConnected(iClient) && IsClientInGame(iClient)) // Connected and in-game.
			if (IsPlayerAlive(iClient) && GetClientTeam(iClient) == 2 && iClient != iLonelyHeart) // Alive & IRIS & not client
				return false; // He's not all alone... yet.

	return true; // He's alone. poor bastard!
}
