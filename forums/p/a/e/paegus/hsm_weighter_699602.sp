/*
 * Hidden:SourceMod - Weight-Reporter
 *
 * Description:
 *  Prints a player's chances based on existing weight points when the round ends.
 *
 * Associated Cvars:
 *  hdn_selectmethod [0/1/2]     : The way the game chooses the next player. 0: Weighted, 1: Classing (Kill=Become), 2: Random. Default: 0
 *  hdn_hiddenrounds [rounds]    : The number of rounds a successful hidden can be hidden. Default: 5
 *  hsm_weighter_delay [seconds] : Seconds to wait after round ends before print out report. Should not exceed mp_chattime. Default: 0.25
 *  mp_chattime [seconds]        : Seconds between old round ending and new round starting.
 *
 * Changelog:
 *  v1.0.3
 *   Removed hidden.inv dependency.
 *  v1.0.2
 *   Unloads automatically on Overrun maps.
 *  v1.0.1
 *   Added Language localization.
 *   Fixed bug where the chances would still be printed out even if hdn_hiddenrounds wasn't 1, and the hidden won but hadn't reach the limit. - thanks -SM-Sucker/The Dark Prince
 *   Changed myinfo:name to H:SM - WeighteR. It was copied from Carry the one.
 *  v1.0.0
 *   Initial Release.
 *
 * Known Issues:
 *  A player's chances at round end are not final. They can still suicide or give ammo, thus altering their weighting.
 *  Does not support Overrun map mode as I've never taken the time to understand how the selection method works for those maps.
 *
 * Contact:
 *  Paegus: paegus@gmail.com
 *  SourceMod: http://www.sourcemod.net > Community > Forums > SourceMod
 *  Hidden:Source: http://www.hidden-source.com > Forums > Server Admins
 */

#pragma semicolon 1
#define PLUGIN_VERSION		"1.0.3"

#define HDN_TEAM_IRIS		2
#define HDN_TEAM_HIDDEN		3

public Plugin:myinfo = {
	name		= "H:SM - WeighteR",
	author		= "Paegus",
	description	= "Prints a player's chances based on existing weight points when the round ends.",
	version		= PLUGIN_VERSION,
	url			= "http://forums.alliedmods.net/showthread.php?p=699602"
}

new Handle:cvarSelect = INVALID_HANDLE;
new Handle:cvarRounds = INVALID_HANDLE;
new Handle:cvarDelay = INVALID_HANDLE;
new g_iMaxClients;
new g_osWeight;
new g_osForfeit;
new g_iHiddenRoundCounter = 1;
stock g_iHidden = -1;

public OnPluginStart() {
	LoadTranslations("weighter.phrases");

	new Handle:cvarChattime = FindConVar("mp_chattime");

	CreateConVar(
		"hsm_weighter_version",
		PLUGIN_VERSION,
		"H:SM - Weight Reporter version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);

	cvarDelay = CreateConVar(
		"hsm_weighter_delay",
		"0.25",
		"Seconds to wait after round ends before print out report. Cannot exceed mp_chattime.",
		FCVAR_PLUGIN,
		true, 0.0,
		true, GetConVarFloat(cvarChattime)
	);

	cvarSelect = FindConVar("hdn_selectmethod");
	cvarRounds = FindConVar("hdn_hiddenrounds");

	HookEvent("game_round_end", event_RoundEnd);
	HookEvent("game_round_start", event_RoundStart);

	g_osWeight = FindSendPropOffs("CSDKPlayer","m_iWeighting");
	g_osForfeit = FindSendPropOffs("CSDKPlayer","m_bNoHidden");

	SetHidden();
}

public OnMapStart() {
	g_iMaxClients = GetMaxClients();
	new String:szMapName[8];
	GetCurrentMap(szMapName, sizeof(szMapName));

	if (StrContains(szMapName, "ovr_", false) == 0) {	// Overrun Map.
		ServerCommand("sm plugins unload %s", "hsm_weighter");
	}
}

public Action:event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast) {
	SetHidden();
	return Plugin_Continue;
}

public Action:event_RoundEnd( Handle:event, const String:name[], bool:dontBroadcast) {
	if (GetConVarInt(cvarSelect) > 0) {	// Not weighted mode
		return Plugin_Continue;
	}

	new bool:bCanPrint = true;
	new iHiddenRounds = GetConVarInt(cvarRounds);
	if (iHiddenRounds == 0) {	// Hidden Rounds is Unlimited
		if (IsClientInGame(g_iHidden)) {	// Hidden is still connected
			if (IsPlayerAlive(g_iHidden)) {	// Hidden died
				bCanPrint = false;
			} // else the hidden is still alive
		} // else the hidden is no longer connected
	} else if (iHiddenRounds > 1 && g_iHiddenRoundCounter < iHiddenRounds) {	// More than 1 round as hidden & that limit has not been reached.
		if (IsClientInGame(g_iHidden)) {	// Hidden is still connected
			if (IsPlayerAlive(g_iHidden)) {	// Hidden is still alive so he won the round.
				g_iHiddenRoundCounter++;
				bCanPrint = false;
			}	// else the hidden died
		}	// else the hidden is no longer connected
	}	// else hdn_hiddenrounds is 1

	if (bCanPrint) {
		g_iHiddenRoundCounter = 1;
		CreateTimer(GetConVarFloat(cvarDelay), tReportWeight);
	}

	return Plugin_Continue;
}

public Action:tReportWeight(Handle:timer) {
	// Print their current chances
	new iTempWeight[MAXPLAYERS+1] = { 0, ... };
	new iTotalWeight = 0;
	for (new iClient = 1; iClient <= g_iMaxClients; iClient++) {
		if (IsClientInGame(iClient)) {	// Connected and in-game.
			if (
				GetClientTeam(iClient) == HDN_TEAM_IRIS &&
				GetEntData(iClient, g_osForfeit, 4) == 0
			) {	// is IRIS and not Forfeiting
				iTempWeight[iClient] = GetEntData(iClient, g_osWeight, 4);

				if (iTempWeight[iClient] < 0) {	// Negative weighting
					iTempWeight[iClient] = 0;
				}	// else they had a postive weighting

				iTotalWeight += iTempWeight[iClient];
			}	// else isn't IRIS or is forfeiting
		}	// else client wasn't connect or in-game
	}

	for (new iClient = 1; iClient <= g_iMaxClients; iClient++) {
		if (IsClientInGame(iClient)) {	// Connected and in-game.
			if (
				GetClientTeam(iClient) == HDN_TEAM_IRIS &&
				GetEntData(iClient, g_osForfeit, 4) == 0 &&
				iTempWeight[iClient] > 0
			) {	// is IRIS, not Forfeiting and has positive weighting
				new String:sClientName[32];

				GetClientName(iClient, sClientName, sizeof(sClientName));

				new iChances = RoundToNearest(100.0 * Float:iTempWeight[iClient] / Float:iTotalWeight);

				LogToGame(
					"[WeighteR] %03i:%03iwp (%02i%%) for %s",
					iTempWeight[iClient],
					iTotalWeight,
					iChances,
					sClientName
				);

				if (iChances < 100) {	// Not 100% chance
					PrintToChat(
						iClient,
						"[WeighteR] %t, %s.",
						"Chance",
						iTempWeight[iClient],
						iTotalWeight,
						iChances,
						sClientName
					);
					PrintToConsole(
						iClient,
						"[WeighteR] %t, %s.",
						"Chance",
						iTempWeight[iClient],
						iTotalWeight,
						iChances,
						sClientName
					);
				} else {	// 100% chance
					PrintToChat(
						iClient,
						"[WeighteR] %t, %s.",
						"WillBe",
						sClientName
					);
					PrintToConsole(
						iClient,
						"[WeighteR] %t, %s.",
						"WillBe",
						sClientName
					);
				}
			}	// else isn't IRIS or is forfeiting
		}	// else client wasn't connect or in-game
	}
}

stock SetHidden() {
	for (new iClient = 1; iClient <= g_iMaxClients; iClient++) {
		if (IsClientInGame(iClient)) {	// Connected and in-game.
			if (
				IsPlayerAlive(iClient) &&
				GetClientTeam(iClient) == HDN_TEAM_HIDDEN
			) {	// Alive & Hidden
				g_iHidden = iClient;
			}
		}
	}
}
