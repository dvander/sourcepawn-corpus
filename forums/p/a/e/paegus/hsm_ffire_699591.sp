/*
 * Hidden:SourceMod - Friendly Radio
 *
 * Description:
 *  IRIS call out when attacked by teammates.
 *  The victim names their attacker.
 *
 * Cvar:
 *  sm_flood_time [seconds] : time between text messages. Default: 0.75
 *  hsm_ffire_named [0|1] : Does the victim name their attacker? 0: No, 1: Yes. Default: 1
 *
 * Changelog:
 *  v1.0.3
 *   Removed dependancy of hsm/hsm.sp
 *   Removed link to hdn_radio_limit since the audio message already goes out via radio and that is already linked.
 *  v1.0.2
 *   Moved audio output to radio message so incidator appears on IRIS's HUD.
 *   There is no text reply with this radio call however. That is still handled elsewhere to preserve attacker naming.
 *  v1.0.1
 *   Fixed bug where attacker would say the text message instead of the vicitm. - thx -SM-Sucker (The Dark Prince)
 *  v1.0.0
 *   Initial Release.
 *
 */

#define PLUGIN_VERSION		"1.0.2"

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

stock g_iHidden; 		// Who is the hidden?

#define RADIO_MESSAGE		15328	// Arbitrary radio id to prevent adverse interaction with other plugins

new bool:g_bCanTextReply = true;	// Are we spamming Text?

new Handle:cvarText;	// Text spam limiter
new Handle:cvarNamed;	// Naming the attacker?

public Plugin:myinfo =
{
	name = "H:SM - Friendly Radio",
	author = "Paegus",
	description = "IRIS calls when team-attacked",
	version = PLUGIN_VERSION,
	url = "http://forum.hidden-source.com/forumdisplay.php?f=13"
}

public OnPluginStart()
{
	CreateConVar(
		"hsm_ffire_version",
		PLUGIN_VERSION,
		"H:SM - Friendly Radio version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	); // Version

	cvarNamed = CreateConVar(
		"hsm_ffire_named",
		"1.0",
		"Does the victim name their attacker? 0: No, 1: Yes.",
		_,
		true, 0.0,
		true, 1.0
	); // Are we naming the attacker

	cvarText = CreateConVar(
		"sm_flood_time",
		"0.75",
		"Amount of time allowed between chat messages"
	); // If it doesn't already exist... load order? eek!

	HookEvent("player_hurt", event_PlayerHurt);
	HookEvent("game_round_start", event_RoundStart);
	HookEvent("iris_radio", event_Radio); // can we get that nifty radar icon?

	SetHidden(); // Late loads.
}

public event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetHidden(); // Find the hidden
}

public event_Radio(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventInt(event, "message") != RADIO_MESSAGE) // Message is not Backup request
		return;

	new iCaller = GetClientOfUserId(GetEventInt(event, "userid")); // Get the person who called the radio.

	if (GetClientTeam(iCaller) != 2) // Caller was IRIS.
		return;

	if (GetConVarInt(cvarNamed) == 0) // We're not naming the attacker so the message goes out via radio
		FakeClientCommand(iCaller, "say_team Watch your fire!");

	// Announce to all surviving IRIS on radio
	new iMaxClients = GetMaxClients();
	for (new iClient = 1; iClient <= iMaxClients; iClient++)
		if (IsClientConnected(iClient) && IsClientInGame(iClient)) // Connected and in-game.
			if (IsPlayerAlive(iClient) && GetClientTeam(iClient) == 2) // Alive & IRIS
				ClientCommand(iClient, "playgamesound IRIS.FriendlyFireWarning");

	// Announce to Hidden as voice
	new Float:vEyePos[3];
	GetClientEyePosition(iCaller, vEyePos); // Get attacker's facial position.

	new Float:vEyeDir[3];
	GetClientEyeAngles(iCaller, vEyeDir); // Get attacker's facial direction.

	new String:sSound[64];
	Format(
		sSound,
		sizeof(sSound),
		"player/IRIS/IRIS-ff%02i.wav",
		GetRandomInt(1,5)
	); // generate audio feedback

	PrecacheSound(sSound, true); // Precache sound

	EmitSoundToClient(
		g_iHidden,
		sSound,
		iCaller,
		SNDCHAN_AUTO,
		SNDLEVEL_CONVO,
		SND_NOFLAGS,
		SNDVOL_NORMAL,
		SNDPITCH_NORMAL,
		iCaller,
		vEyePos,
		vEyeDir,
		true,
		0.0
	); // Emit sound from Victim to hidden
}

public event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iAttacker = GetClientOfUserId(GetEventInt(event, "attacker")); // Get Attacker.

	new iVictim = GetClientOfUserId(GetEventInt(event, "userid")); // Get Victim

	if (!iAttacker || !g_bCanTextReply || iAttacker == iVictim) // spamming or world/self-attack
		return;

	new iAttackerTeam = GetClientTeam(iAttacker); // Get attacker's team.
	if (iAttackerTeam != 2) // wasn't IRIS
		return;

	if (iAttackerTeam != GetClientTeam(iVictim)) // was not same team as victim.
		return;

	if (GetConVarInt(cvarNamed) == 1) // We're naming the attacker.
	{
		new String:sAttackerName[32];

		GetClientName(
			iAttacker,
			sAttackerName,
			sizeof(sAttackerName)
		);

		FakeClientCommand(
			iVictim,
			"say_team Watch your fire, %s!",
			sAttackerName
		);

		TextSpam(); // Toggle text spam
	}

	if (IsFakeClient (iVictim))
	{
		FakeClientCommand(
			iVictim,
			"radio %i",
			RADIO_MESSAGE
		);
	}
	else
	{
		ClientCommand(
			iVictim,
			"radio %i",
			RADIO_MESSAGE
		);
	}

}

TextSpam()
{
	g_bCanTextReply = false; // stop text from spamming

	CreateTimer(GetConVarFloat(cvarText), tTextMoar);
}

public Action:tTextMoar(Handle:timer)
{
	g_bCanTextReply = true; // release text spam
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
