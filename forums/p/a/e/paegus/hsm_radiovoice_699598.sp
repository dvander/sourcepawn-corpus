/*
 * Hidden:SourceMod - Radio to voice.
 *
 * Description:
 *  Allows the hidden to hear all IRIS radio message as he would taunts
 *
 * Changelog:
 *  v1.0.2
 *   Added hidden include.
 *   Added support for multiple hiddens on Overrun maps.
 *  v1.0.1
 *   Removed depenancy on hsm/hsm.sp
 *   Allowed Hidden to hear ALL radio chatter from teammates through other IRIS headsets.
 *   Adjusted output level to match IRIS's Taunts
 *  v1.0.0
 *   Initial release
 *
 * Contact:
 *  Paegus: paegus@gmail.com
 *  SourceMod: http://www.sourcemod.net > Community > Forums > SourceMod
 *  Hidden:Source: http://www.hidden-source.com > Forums > Server Admins
 */

#define PLUGIN_VERSION		"1.0.2"

#pragma semicolon 1

#define HDN_TEAM_IRIS		2
#define HDN_TEAM_HIDDEN		3

#define DEAD_ONLY			-1
#define ANYONE				0
#define ALIVE_ONLY			1
#define TEAM_ALL			-1

#include <sdktools>

public Plugin:myinfo = {
	name		= "H:SM - Radio to Voice",
	author		= "Paegus",
	description	= "Hidden hears IRIS radio comms like taunts.",
	version		= PLUGIN_VERSION,
	url			= "http://forums.alliedmods.net/showthread.php?p=699598"
}

stock g_iMaxClients;

public OnPluginStart() {
	CreateConVar(
		"hsm_radiovoice_version",
		PLUGIN_VERSION,
		"H:SM - Radio to Voice version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);

	HookEvent("iris_radio", event_Radio);
}

public OnMapStart() {
	g_iMaxClients = GetMaxClients();
}

public Action:event_Radio(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid")); // Get the person who called the radio.

	if (GetClientTeam(iClient) != HDN_TEAM_HIDDEN) // Caller wasn't IRIS so we're done here.
		return Plugin_Continue;

	new bValid = false; // was the radio a valid one for hidden to hear?

	// Build the sound source.
	new String:sSound[64];
	switch (GetEventInt(event, "message")) {
		case 0: {	// Agent down
			Format(
				sSound,
				sizeof(sSound),
				"player/IRIS/IRIS-agentdown%02i.wav",
				GetRandomInt(1,4)
			);

			bValid = true;
		}
		case 1: {	// Subject Sighted
			Format(
				sSound,
				sizeof(sSound),
				"player/IRIS/IRIS-sighted%02i.wav",
				GetRandomInt(1,10)
			);

			bValid = true;
		}
		case 2: {	// Affirmative
			Format(
				sSound,
				sizeof(sSound),
				"player/IRIS/IRIS-affirmative%02i.wav",
				GetRandomInt(1,6)
			);

			bValid = true;
		}
		case 3: { // Requesting Ammo
			Format(
				sSound,
				sizeof(sSound),
				"player/IRIS/IRIS-requestingammo%02i.wav",
				GetRandomInt(1,7)
			);

			bValid = true;
		}
		case 4: { // Report In!
			Format(
				sSound,
				sizeof(sSound),
				"player/IRIS/IRIS-reportin%02i.wav",
				GetRandomInt(1,5)
			);

			bValid = true;
		}
		case 10: {	// Checking in
			Format(
				sSound,
				sizeof(sSound),
				"player/IRIS/IRIS-reportingin%02i.wav",
				GetRandomInt(1,10)
			);

			bValid = true;
		}
	}

	if (!bValid) {	// Radio message wasn't valid so we're done here.
		return Plugin_Continue;
	}

	new Float:vEyePos[3];
	GetClientEyePosition(iClient, vEyePos); // Get attacker's facial position.

	new Float:vEyeDir[3];
	GetClientEyeAngles(iClient, vEyeDir); // Get attacker's facial direction.

	PrecacheSound(sSound, true); // Precache the sound now. Can't be arsed to list them all.

	EmitSoundToTeam(
		HDN_TEAM_HIDDEN,
		ANYONE,
		sSound,
		iClient,
		SNDCHAN_AUTO,
		SNDLEVEL_MINIBIKE,
		SND_NOFLAGS,
		SNDVOL_NORMAL,
		SNDPITCH_NORMAL,
		iClient,
		vEyePos,
		vEyeDir,
		true,
		0.0
	); // Emit sound to Victim from Attacker.

	return Plugin_Continue;
}

/**
 * Wrapper to emit sound to all members of the team.
 *
 * @param team			Team index.
 * @param alive			Life state
 * @param sample			Sound file name relative to the "sounds" folder.
 * @param entity			Entity to emit from.
 * @param channel		Channel to emit with.
 * @param level			Sound level.
 * @param flags			Sound flags.
 * @param volume			Sound volume.
 * @param pitch			Sound pitch.
 * @param speakerentity	Unknown.
 * @param origin			Sound origin.
 * @param dir			Sound direction.
 * @param updatePos		Unknown (updates positions?)
 * @param soundtime		Alternate time to play sound for.
 * @noreturn
 * @error				Invalid client index.
 */
stock EmitSoundToTeam(
	team=TEAM_ALL,
	alive=ANYONE,
	const String:sample[],
	entity = SOUND_FROM_PLAYER,
	channel = SNDCHAN_AUTO,
	level = SNDLEVEL_NORMAL,
	flags = SND_NOFLAGS,
	Float:volume = SNDVOL_NORMAL,
	pitch = SNDPITCH_NORMAL,
	speakerentity = -1,
	const Float:origin[3] = NULL_VECTOR,
	const Float:dir[3] = NULL_VECTOR,
	bool:updatePos = true,
	Float:soundtime = 0.0
)
{
	decl clients[g_iMaxClients];
	new total = 0;

	for (new i=1; i<=g_iMaxClients; i++) {
		if (IsClientInGame(i)) {
			if (
				team == TEAM_ALL ||
				GetClientTeam(i) == team
			) {
				if (
					alive == ANYONE ||
					(
						alive == ALIVE_ONLY &&
						IsPlayerAlive(i)
					) ||
					(
						alive == DEAD_ONLY &&
						!IsPlayerAlive(i)
					)
				) {
					clients[total++] = i;
				}
			}
		}
	}

	if (!total) {
		return;
	}

	EmitSound(
		clients,
		total,
		sample,
		entity,
		channel,
		level,
		flags,
		volume,
		pitch,
		speakerentity,
		origin,
		dir,
		updatePos,
		soundtime
	);
}

