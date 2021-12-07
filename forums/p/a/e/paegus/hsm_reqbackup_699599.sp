/*
 * Hidden:SourceMod - Request backup.
 *
 * Description:
 *  Causes the IRIS to call for backup when their health drops below a certain point.
 *
 * Cvars
 *  hsm_reqbackup_threshold : Hitpoint transition point that triggers a backup request. Default is 37
 *
 * Changelog
 *  v1.0.2
 *   Remove dependancy of HSM/HSM.SP.
 *   Added hidden include.
 *   Added support for multiple hiddens in Overrun maps.
 *  v1.0.1
 *   Attempt to fix the calling for backup both when the player has already died and when a health deferred attack has occured.
 *  v1.0.0
 *   Initial release.
 */

#define PLUGIN_VERSION		"1.0.2"

#pragma semicolon 1

#include <sourcemod>
#include <hidden>
#include <sdktools>
#include <toteam>

#define RADIO_MESSAGE		24381	// Arbitrary radio id to prevent adverse interaction with other plugins

new Handle:cvarThreshold;		// Point at which the IRIS will request backup
new g_bCalled[HDN_MAXPLAYERS+1] = { false, ... }; // Has this IRIS called for backup yet?

public Plugin:myinfo =
{
	name		= "H:SM - Request Backup",
	author		= "Paegus",
	description	= "IRIS requests backup when conditions are ripe.",
	version		= PLUGIN_VERSION,
	url			= "http://forum.hidden-source.com/forumdisplay.php?f=13"
}

public OnPluginStart()
{
	CreateConVar(
		"hsm_reqbackup_version",
		PLUGIN_VERSION,
		"H:SM - Request backup version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);

	cvarThreshold = CreateConVar(
		"hsm_reqbackup_threshold",
		"37",
		"Hitpoint threshold for IRIS to call for backup. 1~99",
		_,
		true, 1.0,
		true, 99.0
	);

	HookEvent("player_hurt", event_PlayerHurt);
	HookEvent("game_round_start", event_RoundStart); // to reset backup requests called.
	HookEvent("iris_radio", event_Radio); // can we get that nifty radar icon?
}

public event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iMaxClients = GetMaxClients();
	for (new iClient=1; iClient <= iMaxClients; iClient++) // reset all backup calls to false.
		g_bCalled[iClient] = false;
}

public event_Radio(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventInt(event, "message") != RADIO_MESSAGE) // Message isn't Backup request
		return;

	new iCaller = GetClientOfUserId(GetEventInt(event, "userid")); // Get the person who called the radio.

	if (GetClientTeam(iCaller) != HDN_TEAM_HIDDEN) // Caller wasn't IRIS.
		return;

	// Play to other IRIS as over radio.
	new iMaxClients = GetMaxClients();
	for (new iClient = 1; iClient <= iMaxClients; iClient++)
		if (IsClientConnected(iClient) && IsClientInGame(iClient)) // Connected and in-game.
			if (IsPlayerAlive(iClient) && GetClientTeam(iClient) == 2) // Alive & IRIS
				ClientCommand(iClient, "playgamesound IRIS.RequestBackup");

	FakeClientCommand(iCaller, "say_team Backup! I need Backup!");

	// Play to hidden as voice.

	new Float:vEyePos[3];
	GetClientEyePosition(iCaller, vEyePos); // Get attacker's facial position.

	new Float:vEyeDir[3];
	GetClientEyeAngles(iCaller, vEyeDir); // Get attacker's facial direction.

	new String:sSound[64];
	Format(
		sSound,
		sizeof(sSound),
		"player/IRIS/IRIS-backup%02i.wav",
		GetRandomInt(1, 4)
	);
	PrecacheSound(sSound, true); // Make damn sure the sound is precached.

	EmitSoundToTeam(
		HDN_TEAM_HIDDEN,
		ANYONE,
		sSound,
		iCaller,
		SNDCHAN_AUTO,
		SNDLEVEL_NORMAL,
		SND_NOFLAGS,
		SNDVOL_NORMAL,
		SNDPITCH_NORMAL,
		iCaller,
		vEyePos,
		vEyeDir,
		true,
		0.0
	); // Emit sound to Victim from Attacker.
}

public event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iAttacker = GetClientOfUserId(GetEventInt(event, "attacker")); // Get attacker.

	if (!iAttacker) // was world attack
		return;

	if (GetClientTeam(iAttacker) == 2) // The irony in requesting backup from a team-attack is amusing...
		return;

	new iVictim = GetClientOfUserId(GetEventInt(event, "userid"));

	new iHealth = GetClientHealth(iVictim);

	if (iHealth < 0 || iHealth >= GetConVarInt(cvarThreshold) || g_bCalled[iVictim] || LoneWolf(iVictim)) // If the health is below the threshold, higher than 0 and this iris has not called for backup yet
		return;

	if (IsFakeClient(iVictim))
		FakeClientCommand(
			iVictim,
			"radio %i",
			RADIO_MESSAGE
		);
	else
		ClientCommand(
			iVictim,
			"radio %i",
			RADIO_MESSAGE
		);

	g_bCalled[iVictim] = true;
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

