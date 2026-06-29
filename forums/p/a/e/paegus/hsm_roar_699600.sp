/*
 * Hidden:SourceMod - Roar
 *
 * Description:
 *  Hidden will cry out when hit.
 *
 * Cvars
 *  hsm_hitcry_303 [0/1]: Only for 303 hits? Default 0.
 *
 * Changelog:
 *  v1.0.1
 *   Adjusted output volume for for more realism. The sound carries slightly farther now.
 *   Removed HSM/HSM.sp dependancy. It annoyed me.
 *  v1.0.0
 *   Initial release
 *
 */

#define PLUGIN_VERSION		"1.0.1"

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

// Just to screw with people?
#define ROAR_MAX_DELAY 9.5
#define ROAR_MIN_DELAY 4.5

new Handle:cvar303;	// 303 hits only

new bool:g_bCanRoar = true;	// Are we spamming?

public Plugin:myinfo =
{
	name		= "H:SM - Roar",
	author		= "Paegus",
	description	= "Hidden will roar out when hit.",
	version		= PLUGIN_VERSION,
	url			= "http://forum.hidden-source.com/forumdisplay.php?f=13"
}

public OnPluginStart()
{
	CreateConVar(
		"hsm_roar_version",
		PLUGIN_VERSION,
		"H:SM - Roar version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);

	cvar303 = CreateConVar(
		"hsm_roar_303",
		"0.0",
		"Does the hidden only cry out on 303 hits? 0: All hits, 1: Only initial 303 hit",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY,
		true, 0.0,
		true, 1.0
	);

	HookEvent("player_hurt", event_PlayerHurt);

}

public event_PlayerHurt( Handle:event, const String:name[], bool:dontBroadcast)
{
	new iVictim = GetClientOfUserId(GetEventInt(event, "userid")); // get victim, ignore attacker

	if (GetClientTeam(iVictim) == 3 && GetClientHealth(iVictim) > 0 && g_bCanRoar) // hidden was attacked, is still alive and we're not spamming
	{
		new bool:bValidRoar = false; // allowed to cry?
		new Float:fDamage = GetEventFloat(event, "damage"); // Get damage done.
		new String:sSound[64] = "NULL_SOUND";

		if (fDamage == 3.000000) // 303 pellet
		{
			Format(
				sSound,
				sizeof(sSound),
				"player/hidden/voice/617-303pain%02i.mp3",
				GetRandomInt(1,8)
			);
			bValidRoar = true;
		}
		else if (!GetConVarInt(cvar303)) // 303 only disabled
		{
			if (fDamage == 0.300000) // residual 303 hit
			{
				Format(
					sSound,
					sizeof(sSound),
					"player/hidden/voice/617-303pain%02i.mp3",
					GetRandomInt(1,8)
				);
			}
			else // normal hit
			{
				Format(
					sSound,
					sizeof(sSound),
					"player/hidden/voice/617-pain%02i.mp3",
					GetRandomInt(1,6)
				);
			}
			bValidRoar = true;
		}
		// else 303 only was enabled.

		if (bValidRoar) // a valid roar
		{
			new Float:vEyePos[3];
			GetClientEyePosition(iVictim, vEyePos); // Get attacker's facial position.

			new Float:vEyeDir[3];
			GetClientEyeAngles(iVictim, vEyeDir); // Get attacker's facial direction.

			PrecacheSound(sSound, true); // Make damn sure the sound is precached. But why oh why must we precache late? silly sourcemod :D

			EmitSoundToAll(
				sSound,
				iVictim,
				SNDCHAN_AUTO,
				SNDLEVEL_SCREAMING,
				SND_NOFLAGS,
				SNDVOL_NORMAL,
				SNDPITCH_NORMAL,
				iVictim,
				vEyePos,
				vEyeDir,
				true,
				0.0
			); // Emit sound to Victim/hidden

			Roared();
		}
		// else Cannot roar
	}
	// else were spamming or the victim wasn't the hidden.
}

Roared()
{
	g_bCanRoar = false;
	CreateTimer(GetRandomFloat(ROAR_MAX_DELAY,ROAR_MIN_DELAY), tRoarAgain);
}

public Action:tRoarAgain(Handle:timer)
{
	g_bCanRoar = true;
}