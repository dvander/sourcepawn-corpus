/*
 * Hidden:SourceMod - Beta 5 Pigshove
 *
 * Description:
 *   Converts hidden's pigstick into a shove until hidden's health drops below 20.
 *
 * Cvars:
 *  sv_pigstick 0/1: globally enabled or disable hidden's alternate knife attack (pigstick AND shove)
 *  hsm_pigstick 0/1: enable or disable pigsticking when hidden is enraged
 *
 * Changelog:
 *  v1.1.5
 *   Removed hidden.inc include dependency.
 *  v1.1.4
 *   Added language translation file
 *   Increased vertical boost to 20º
 *   Added hidden include
 *   Added support for multiple hiddens in Overrun maps.
 *   Log outputs correctly is Shove is always active but the hidden's health is below the threshold
 *  v1.1.3
 *   Attempted to fix Shove not registering for some reason? Well it seems to work now at least.
 *  v1.1.2
 *   Added punt specific log output.
 *   Fixed deathnotice bug caused by Log fix plugin.
 *  v1.1.1
 *   Fixed server console error when the hidden has disconnected.
 *   Fixed log output for compatibility with Phaedrus' Log fix.
 *  v1.1.0
 *   Renamed plugin from hsm_b5shove to hsm_pigshove.
 *   Added a variations to the initial shove/punt/push action.
 *   Fixed version cvar to report correct information. It was copied from B5 Physics plugin. :/
 *   Removed log output for shove actions since no damage is done.
 *   Fixed multiple feedbacks for when Hidden drops below 20hp.
 *  v1.0.2
 *   Added feedback for Pigstick/Shove modes on hit and when the hidden's health and hsm_pigstick allow for normal Pigstick function.
 *  v1.0.1
 *   Added a 15º boost the the angle so that head-on shoves give a bit of altitude and crouch-up shoves give a higher angle
 *   Increased the vertical shove scaling slightly so up-shoving a player from and to flat ground will do minor fall damage.
 *  v1.0.0
 *   Initial release.
 *
 * Contact:
 *  Paegus: paegus@gmail.com
 *  SourceMod: http://www.sourcemod.net > Community > Forums > SourceMod
 *  Hidden:Source: http://www.hidden-source.com > Forums > Server Admins
 */

#pragma semicolon 1

#define PLUGIN_VERSION		"1.1.5"

#include <sdktools>
#include <logging>

#define HDN_TEAM_IRIS			2
#define HDN_TEAM_HIDDEN			3

#define SHOVE_HEALTH_BARRIER	20
#define SHOVE_SCALE_LATERAL		0.4
#define SHOVE_SCALE_VERTICAL	0.7
#define SHOVE_BOOST_VERTICAL	20.0

public Plugin:myinfo = {
	name		= "H:SM - B5 Pigshove",
	author		= "Paegus",
	description	= "Converts normal pigstick to shove/punt/push as in Beta 5",
	version		= PLUGIN_VERSION,
	url			= "http://forums.alliedmods.net/showthread.php?p=699595"
}

new String:g_sShove[] = "shoved";		// the name of the attack for logging purposes

new Handle:cvarPigstick;				// link to sv_pigstick
new Handle:cvarShove2PS;				// hsm_pigstick
new bool:g_bRageAnnounced = false;		// Have the IRIS announced rage-mode?
new bool:g_bRageEnableBuffer = false;	// Don't spam the rage-enabled message
new bool:g_bShoved = false;				// Has the shoved message been played?
new g_iMaxClients;

public OnPluginStart() {

	LoadTranslations("pigshove.phrases");

	CreateConVar(
		"hsm_pigshove_version",
		PLUGIN_VERSION,
		"H:SM - Beta 5 Pigshove version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);

	cvarShove2PS = CreateConVar(
		"hsm_pigstick",
		"1",
		"Does normal pigstick kick in when hidden is enraged? 0: Disable, 1: Enable",
		_,
		true, 0.0,
		true, 1.0
	);

	cvarPigstick = FindConVar("sv_pigstick"); // Get global pigstick mode.

	HookEvent("player_hurt", event_PlayerHurt, EventHookMode_Pre);
	HookEvent("game_round_start", event_RoundStart);
	AddGameLogHook(LogShove);
}

public OnMapStart() {
	g_iMaxClients = GetMaxClients();
}

public event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast) {
	g_bRageAnnounced = false; // Reset rage alert call.
	g_bShoved = false;
}

public Action:event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!GetConVarInt(cvarPigstick)) {	// Pigstick disabled so we're done here.
		return Plugin_Continue;
	}

	new iAttacker = GetClientOfUserId(GetEventInt(event, "attacker")); // Get attacker.

	if (!iAttacker) {	// World attacked so we're done here.
		return Plugin_Continue;
	}

	new iVictim = GetClientOfUserId(GetEventInt(event, "userid")); // Get victim.

	if (
		GetClientTeam(iVictim) == HDN_TEAM_HIDDEN &&
		GetClientHealth(iVictim) <= SHOVE_HEALTH_BARRIER &&
		GetConVarInt(cvarShove2PS) == 1 &&
		!g_bRageEnableBuffer
	) {	// Hidden was attacked, Hidden HP now > threshold, hsm_pigstick 1 AND the attack buffer hasn't expired so we're sorta done here.
		CreateTimer(0.5, tStayinAlive, iVictim);
		return Plugin_Continue;
	}

	if (GetClientTeam(iAttacker) != HDN_TEAM_HIDDEN) {	// Attacker wasn't hidden so we're done here.
		return Plugin_Continue;
	}

	new iDamage = GetEventInt(event, "damage"); // Get damage done.

	if (iDamage != 925) {	// wasn't Pigstruck so we're done here.
		return Plugin_Continue;
	}

	new iHdnHealth = GetClientHealth(iAttacker); // Get the hidden's health.
	if (
		iHdnHealth < SHOVE_HEALTH_BARRIER &&
		GetConVarInt(cvarShove2PS) != 0
	) {	// Hidden is below threshold AND hsm_pigstick is 1 so report and bug out, allowing normal PS operations co commence.
		if (!g_bRageAnnounced) {	// Rage has not yet been called...
			// Rage call
			switch (GetRandomInt(1,2)) {
				case 1: {
					PrintCenterText(iAttacker, "< PS:%t >", "Rage");
				}
				case 2: {
					PrintCenterText(iAttacker, "< PS:%t >", "Pigstick");
				}
			}
			
			g_bRageAnnounced = true;

			CreateTimer(1.0,tRageAnnounceToIRIS);
		}

		return Plugin_Continue;
	}

	//LogToGame("[Shove] %i %s %i!", GetClientUserId(iAttacker), g_sShove, GetClientUserId(iVictim));

	// Inform the attacker.
	if (!g_bShoved) {
		switch (GetRandomInt(1,3)) {
			case 1: {
				PrintCenterText(iAttacker, "< PS:%t >", "Shove");
			}
			case 2: {
				PrintCenterText(iAttacker, "< PS:%t >", "Punt");
			}
			case 3: {
				PrintCenterText(iAttacker, "< PS:%t >", "Push");
			}
		}
		g_bShoved = true;
	}

	// Compensate player's health.
	SetEventInt(event, "damage", 0); // Remove the damage.

	new iHealth = GetClientHealth(iVictim) + iDamage; // Get their adjusted health.
	SetEntData(iVictim, FindDataMapOffs(iVictim, "m_iHealth"), iHealth,	4, true);

	// Impart correct shove on target.
	new Float:vAttackerAngle[3];
	GetClientAbsAngles(iAttacker, vAttackerAngle); // Direction the hidden is looking.

	vAttackerAngle[0] *= -1.0; // Invert the angle.

	// IF THIS CRASHES USE THE LATEST DEV BUILD!
	if (vAttackerAngle[0] <= 90.0 - SHOVE_BOOST_VERTICAL) {	// will not over-boost
		vAttackerAngle[0] += SHOVE_BOOST_VERTICAL; // Boosts the angle a bit
	}

	vAttackerAngle[0] = DegToRad(vAttackerAngle[0]); // Convert to radians
	vAttackerAngle[1] = DegToRad(vAttackerAngle[1]); // Convert to radians

	// Calculate appropriate vectors and scale them.
	// There are 3 separate assignments because segfaults are great!
	// X = cos(pitch) * cos(yaw)
	// Y = cos(pitch) * sin(yaw)
	// Z = sin(pitch)
	new Float:vShoved[3];
	vShoved[0] = Cosine(vAttackerAngle[0]) * Cosine(vAttackerAngle[1]);
	vShoved[1] = Cosine(vAttackerAngle[0]) * Sine(vAttackerAngle[1]);
	vShoved[2] = Sine(vAttackerAngle[0]);

	// Multiple by pigstick damage
	vShoved[0] *= 925.0;
	vShoved[1] *= 925.0;
	vShoved[2] *= 925.0;

	// Scale as desired
	vShoved[0] *= SHOVE_SCALE_LATERAL;
	vShoved[1] *= SHOVE_SCALE_LATERAL;
	vShoved[2] *= SHOVE_SCALE_VERTICAL;
		
	TeleportEntity(
		iVictim,
		NULL_VECTOR,
		NULL_VECTOR,
		vShoved
	); // Boosts the player the given direction direction.

	new String:sAttackerName[32];
	GetClientName(iAttacker, sAttackerName, sizeof(sAttackerName));

	new String:sAttackerSteamId[32];
	GetClientAuthString(iAttacker, sAttackerSteamId, sizeof(sAttackerSteamId));

	new String:sVictimName[32];
	GetClientName(iVictim, sVictimName, sizeof(sVictimName));

	new String:sVictimSteamId[32];
	GetClientAuthString(iVictim, sVictimSteamId, sizeof(sVictimSteamId));

	new String:sTeam[4][16] = {
		"unconnected",
		"Spectator",
		"IRIS",
		"Hidden"
	};

	// Need to detect phaedrus' log fix
	// if LogFix is active use this layout otherwise use the old style output
	/*
	LogToGame(
		"\"%s<%i><%s><%s>\" %s \"%s<%i><%s><%s>\" with \"knife\" (damage \"0\")",
		sAttackerName,
		GetEventInt(event, "attacker"),
		sAttackerSteamId,
		sTeam[GetClientTeam(iAttacker)],
		g_sShove,
		sVictimName,
		GetEventInt(event, "userid"),
		sVictimSteamId,
		sTeam[GetClientTeam(iVictim)]
	);
	*/

	LogToGame(
		"\"%s<%i><%s><%s>\" %s \"%s<%i><%s><%s>\"",
		sAttackerName,
		GetEventInt(event, "attacker"),
		sAttackerSteamId,
		sTeam[GetClientTeam(iAttacker)],
		g_sShove,
		sVictimName,
		GetEventInt(event, "userid"),
		sVictimSteamId,
		sTeam[GetClientTeam(iVictim)]
	);

	return Plugin_Handled;
}

public Action:tRageAnnounceToIRIS(Handle:timer) {
	
	for (new iClient = 1; iClient <= g_iMaxClients; iClient++) {
		if (IsClientInGame(iClient)) {	// Connected and in-game.
			if (
				IsPlayerAlive(iClient) &&
				GetClientTeam(iClient) == HDN_TEAM_IRIS
			) {	// Alive and IRIS
				ClientCommand(iClient, "playgamesound IRIS.RageAlert");
			}
		}
	}
}

public Action:tStayinAlive(Handle:timer, any:hidden) {
	if (GetClientHealth(hidden) > 0 && !g_bRageEnableBuffer) {	// oh, oh, oh he's still alive!
		PrintCenterText(hidden, "< %t >", "Rage Mode Center");
		PrintToChat(hidden,"[PigShove] %t", "Rage Mode");
		PrintToConsole(hidden,"[PigShove] %t", "Rage Mode");
		RageEnabled();
	}
}

RageEnabled() {
	g_bRageEnableBuffer = true;
	CreateTimer(20.0,tRageCheck);
}

public Action:tRageCheck(Handle:timer) {
	g_bRageEnableBuffer = false;
}

public Action:LogShove(const String:message[]) {
	if (
		StrContains(message, "><Hidden>\" hurt \"", false) > 0 ||
		StrContains(message, "><Hidden>\" attacked \"", false) > 0
	) {	// Check default or Phaedrus' log fix output.
		if (
			StrContains(message, "(damage \"0\")") > 0 ||
			StrContains(message, "for \"<925>\"") > 0
		) {	// Shoving.
			// Extract hidden's identity.
			decl iPos;
			decl String:szTmp1[1][32];
			decl String:szTmp2[64][32];

			// "!<BaBcIa_KlEoFaSa>!<41><STEAM_0:1:12410921><Hidden>" hurt "Skin-E<47><STEAM_0:1:14537242><IRIS>" for "<37>" with "" //

			ExplodeString(message, "><STEAM_", szTmp1, 1, 32); // Get the 1st token.

			iPos = ExplodeString(szTmp1[0], "<", szTmp2, 64, 32); // Get all the tokens
			if (
				GetClientHealth(GetClientOfUserId(StringToInt(szTmp2[iPos-1]))) > SHOVE_HEALTH_BARRIER ||
				GetConVarInt(cvarShove2PS) != 1
			) {	// Hidden's health is above cutoff or Shove is always active.
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}
