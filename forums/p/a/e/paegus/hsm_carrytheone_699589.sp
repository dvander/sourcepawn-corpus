/*
 * Hidden:SourceMod - Carry the one
 *
 * Description:
 *  Carries IRIS's unused weighting points over to the next round if they are no choosen as hidden.
 *
 * Associated Cvars:
 *  hdn_selectmethod [0/1/2] : The way the game chooses the next player. 0: Weighted, 1: Classing (Kill=Become), 2: Random. Default: 0
 *  hsm_ct1_keep [0~2] : existing weight to carry forward. 0: None (0%) Disables plugin, 1: Full (100%), 2 Doubles (200%). Default 1.
 *  hsm_ct1_purge [0/1] : purge weighting on map change? 0: Disabled, 1: Enabled. Default: 0
 *
 * Changelog:
 *  v1.0.2
 *   Removed weight report print out and put it into separate plugin so servers can have it without the carry mechanism
 *  v1.0.1
 *   Removed outside possibility for a new player to inherit the most recently disconnected player's weighting.
 *   Exchanged atrophy for keep rate. While less cool sounding, I think it's more intuitive and the math is simpler.
 *   Allowed for doubling of existing chances. FEED BACK PLEASE!
 *  v1.0.0
 *   Initial Release.
 *
 */

#define PLUGIN_VERSION		"1.0.2"

#pragma semicolon 1

#include <sourcemod>

new Handle:cvarChattime;
new Handle:cvarSelect;
new Handle:cvarPurge;
new Handle:cvarKeep;
new g_osWeight;
new g_osForfeit;
new g_iWeights[MAXPLAYERS+1] = { 0, ... };

public Plugin:myinfo =
{
	name		= "H:SM - Carry The One",
	author		= "Paegus",
	description	= "Carries IRIS's unused weighting points over to the next round if they are no choosen as hidden.",
	version		= PLUGIN_VERSION,
	url			= "http://forum.hidden-source.com/forumdisplay.php?f=13"
}

public OnPluginStart()
{
	CreateConVar(
		"hsm_ct1_version",
		PLUGIN_VERSION,
		"H:SM - Carry the one version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);

	cvarPurge = CreateConVar(
		"hsm_ct1_purge",
		"0.0",
		"purge weighting on map change? 0: Disabled, 1: Enabled.",
		FCVAR_PLUGIN,
		true, 0.0,
		true, 1.0
	);

	cvarKeep = CreateConVar(
		"hsm_ct1_keep",
		"1.0",
		"existing weight to carry forward. 0: None (0%) Disables plugin, 1: Full (100%).",
		FCVAR_PLUGIN,
		true, 0.0,
		true, 2.0
	);

	cvarChattime = FindConVar("mp_chattime");
	cvarSelect = FindConVar("hdn_selectmethod");

	HookEvent("game_round_end", event_RoundEnd);
	HookEvent("game_round_start", event_RoundStart);

	g_osWeight = FindSendPropOffs("CSDKPlayer","m_iWeighting");
	g_osForfeit = FindSendPropOffs("CSDKPlayer","m_bNoHidden");
}

public OnMapStart() // Fire on plugin load?
{
	if (GetConVarInt(cvarSelect) > 0 || GetConVarFloat(cvarKeep) < 0.000001 || GetConVarInt(cvarPurge) != 1) // Not weighted mode, hsm_ct1_keep is 0% or Purge isn't 1 so we're done here.
		return;

	new iMaxClients = GetMaxClients();
	for (new iClient = 1; iClient <= iMaxClients; iClient++)
	{
		if (IsClientConnected(iClient) && IsClientInGame(iClient)) // Connected and in-game.
		{
			g_iWeights[iClient] = 0;
		}
		// wasn't in game or connected
	}
}

public OnClientDisconnect(iClient)
{
	g_iWeights[iClient] = 0; // Clear their weighting
}

public event_RoundEnd( Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvarSelect) > 0 || GetConVarFloat(cvarKeep) < 0.000001) // Not weighted mode or hsm_ct1_keep is 0%
		return;

	// Wait until the new round is about to start and and save their then weighting.
	new Float:fTemp = GetConVarFloat(cvarChattime) - 0.1;
	CreateTimer(fTemp, tSaveWeight);
}

public Action:tSaveWeight(Handle:timer)
{
	// Save their current weighting
	new iMaxClients = GetMaxClients();
	for (new iClient = 1; iClient <= iMaxClients; iClient++)
	{
		if (IsClientConnected(iClient) && IsClientInGame(iClient)) // Connected and in-game.
		{
			if (GetClientTeam(iClient) == 2 && GetEntData(iClient, g_osForfeit, 4) == 0) // is IRIS and not Forfeiting
			{
				g_iWeights[iClient] = GetEntData(iClient, g_osWeight, 4);

				if (g_iWeights[iClient] < 0) // Negative weighting
					g_iWeights[iClient] = 0;
				// else they had a postive weighting
			}
			else // isn't IRIS or is forfeiting
			{
				g_iWeights[iClient] = 0; // Zero out stored weight points for this guy.
				SetEntData(iClient, g_osWeight, 0, 4, true); // Zero out hidden's weight points. I hope you're not play OVR ^.^
			}
		}
		// else client wasn't connect or in-game
	}
}

public event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvarSelect) > 0 || GetConVarFloat(cvarKeep) < 0.000001) // Not weighted mode or hsm_ct1_keep is 0%
		return;

	new Float:fKeep = GetConVarFloat(cvarKeep);

	new iMaxClients = GetMaxClients();
	for (new iClient = 1; iClient <= iMaxClients; iClient++)
	{
		if (IsClientConnected(iClient) && IsClientInGame(iClient)) // Connected and in-game.
		{
			if (GetClientTeam(iClient) == 2 && GetEntData(iClient, g_osForfeit, 4) == 0 && g_iWeights[iClient] > 0) // is IRIS, not Forfeiting and has positive weighting
			{
				SetEntData(iClient, g_osWeight, RoundToNearest(fKeep * g_iWeights[iClient]), 4, true); // Zero out hidden's weight points. I hope you're not play OVR ^.^
			}
			// else they were not IRIS, were forfeiting or had less than 1wp.
		}
		// else client wasn't connect or in-game
	}
}

