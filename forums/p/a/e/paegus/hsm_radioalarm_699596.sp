/*
 * Hidden:SourceMod - Radio Alarm
 *
 * Description:
 *  Converts Sonic Trip Alarms to Radio ones that only IRIS can hear directly.
 *  The hidden hears the alarm from local IRIS's headsets
 *  Alarm becomes non-collidable when triggered.
 *  An indicator sprite shows on the IRIS's HUD at the alarm's location.
 *
 * Cvars:
 *  hsm_rta_hud [0/1]    : Radio Trip Alarm HUD indicator. 0: Disable. 1: Enable
 *
 * Changelog:
 *  v1.1.1
 *   Alarm sound and sprite broadcast to all non-hidden players in the game.
 *  v1.1.0
 *   Added the IRIS HUD alarm sprite to visually indicate what alarm was triggered. Cvar to control it.
 *  v1.0.1
 *   Fixed Alarm sound not playing sometimes of map-change or server crash.
 *   Removed alarm_sub.mp3 sound requirement.
 *  v1.0.0
 *   Initial release.
 *
 * Known Issues:
 *  v1.1.0
 *   Visual indicator sprite is upside-down because I'm using an existing one. Hopefully I'll find another one.
 *   Indicator Sprite will not show up if it is outside of the client's render block. Similar effect to the Hidden aura not rendering all IRIS all the time.
 *   The sprites dont always render some reason depending on alarm placement.
 *
 */

#define PLUGIN_VERSION		"1.1.1"
#define TEAM_IRIS 2
#define TEAM_HIDDEN 3

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

stock g_iHidden; 		// Who is the hidden?

new g_Sprite;
new Float:g_fSpriteLife = 6.0;	// Sprite lifetime
new Handle:cvarHUD = INVALID_HANDLE;

public Plugin:myinfo =
{
	name		= "H:SM - Radio Alarm",
	author		= "Paegus",
	description	= "Converts the Sonic Trip Alarm into a radio based one.",
	version		= PLUGIN_VERSION,
	url			= "http://forum.hidden-source.com/forumdisplay.php?f=13"
}

public OnPluginStart()
{
	CreateConVar(
		"hsm_rta_version",
		PLUGIN_VERSION,
		"H:SM - Radio Alarm version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);

	cvarHUD = CreateConVar(
		"hsm_rta_hud",
		"1",
		"Radio Trip Alarm HUD indicator. 0: Disable. 1: Enable",
		_,
		true, 0.0,
		true, 1.0
	);

	AddNormalSoundHook(NormalSHook:RadioAlarm); // A sound is played.
	HookEvent("game_round_start", event_RoundStart); // to reset backup requests called.

	SetHidden();
}

// Set the new hidden
public event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetHidden(); // Find the hidden
}

public OnMapStart()
{
	PrecacheSound("weapons/sonic/alarm.wav", true);
	g_Sprite = PrecacheModel("materials/vgui/hud/hdn_retrieve_icon.vmt");
}

public Action:RadioAlarm(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!StrEqual(sample,")weapons/sonic/alarm.wav") || volume < 0.000001)
		return Plugin_Continue;
	// else it's the alarm and it's loud enough to play

	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1); // Set alarm transparent. Yeah, totally snuck that in there didn't i? :)

	new Float:vAlarmPos[3];
	GetEntPropVector(
		entity,
		Prop_Send,
		"m_vecOrigin",
		vAlarmPos
	);	// the alarm's Position.

	new iMaxClients = GetMaxClients();
	for (new iClient=1; iClient <= iMaxClients; iClient++)
	{
		if (IsClientConnected(iClient) && IsClientInGame(iClient)) // Connected and in-game.
		{
			if (GetClientTeam(iClient) != TEAM_HIDDEN) // Alive & NOT hidden
			{
				EmitSoundToClient(
					iClient,
					"weapons/sonic/alarm.wav",
					entity,
					SNDCHAN_AUTO,
					SNDLEVEL_MINIBIKE,
					SND_NOFLAGS,
					SNDVOL_NORMAL,
					SNDPITCH_NORMAL,
					entity,
					vAlarmPos,
					NULL_VECTOR,
					true,
					0.0
				); // Emit sound from alarm's origin.

				if (GetConVarInt(cvarHUD))
				{
					TE_SetupGlowSprite(
						vAlarmPos,
						g_Sprite,
						g_fSpriteLife,
						0.5,
						255
					); // Pulse at the alarm

					TE_SendToClient(iClient);
				}

				/*
				new Float:vClientPos[3];
				GetClientEyePosition(iClient, vClientPos); // Get attacker's facial position.

				new Float:vClientDir[3];
				GetClientEyeAngles(iClient, vClientDir); // Get attacker's facial direction.
				vAlarmDir[1] +=90; // Rotate 90º

				EmitSoundToClient(
					g_iHidden,
					"weapons/sonic/alarm.wav",
					iClient,
					SNDCHAN_AUTO,
					SNDLEVEL_CONVO,
					SND_CHANGEVOL,
					0.5,
					SNDPITCH_NORMAL,
					iClient,
					vClientPos,
					vClientDir,
					true,
					0.0
				); // Emit sound from alarm's origin.

				CreateTimer(2.5, tSilence, iClient); // Kill the sound, if any.
				*/

			}
			// else client was not a living IRIS
		}
		// else client wasn't connect or in-game
	}

	CreateTimer(2.5, tSilence, entity); // Kill the sound, if any.

	return Plugin_Handled;
}

public Action:tSilence(Handle:timer, any:entity)
{
	EmitSoundToAll(
		"weapons/sonic/alarm.wav",
		entity,
		SNDCHAN_AUTO,
		SNDLEVEL_NORMAL,
		SND_STOPLOOPING,
		SNDVOL_NORMAL,
		SNDPITCH_NORMAL,
		entity,
		NULL_VECTOR,
		NULL_VECTOR,
		true,
		0.0
	); // Emit sound from alarm's origin.
}

// Sets the hidden.
stock SetHidden()
{
	new iMaxClients = GetMaxClients();
	for (new iClient = 1; iClient <= iMaxClients; iClient++)
		if (IsClientConnected(iClient) && IsClientInGame(iClient)) // Connected and in-game.
			if (IsPlayerAlive(iClient) && GetClientTeam(iClient) == TEAM_HIDDEN) // Alive & Hidden
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
