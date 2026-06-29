/*
 * Hidden:SourceMod - Dynamic Round Time
 *
 * Description:
 *  Alters the round time based on the number of IRIS.
 *
 * Associated CVars:
 *  hsm_dtr_basetime [seconds] : Base time for round. Default 150
 *  hsm_dtr_inctime [seconds]  : Additional time for each IRIS player. Default 30
 *  hsm_dtr_randtime [seconds] : Additional random time added per round. Default 30
 *
 * Changelog:
 *  v1.0.0
 *   Initial release
 *
 * Contact:
 *  Phaedrus: (http://forum.hidden-source.com/member.php?u=4634)
 *  Paegus: paegus@gmail.com (http://forum.hidden-source.com/member.php?u=2439)
 *  SourceMod: http://www.sourcemod.net > Community > Forums > SourceMod
 *  Hidden:Source: http://www.hidden-source.com > Forums > Server Admins
 */
 
#pragma semicolon 1

#define PLUGIN_VERSION		"1.0.0"

#define HDN_TEAM_SPECTATOR		1

#include <sdktools>

new Handle:cvarBaseTime   = INVALID_HANDLE;
new Handle:cvarIncTime    = INVALID_HANDLE;
new Handle:cvarRandomTime = INVALID_HANDLE;
new Handle:cvarRoundTime  = INVALID_HANDLE;

public Plugin:myinfo = {
	name		= "H:SM - Dynamic Round Time",
	author		= "Phaedrus, Paegus",
	description	= "Alters the round time based on the number of IRIS.",
	version		= PLUGIN_VERSION,
	url			= "http://forum.hidden-source.com/forumdisplay.php?f=13"
}

public OnPluginStart() {
	CreateConVar(
		"hsm_drt_version",
		PLUGIN_VERSION,
		"H:SM - Dynamic Round Time version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);
	
	cvarBaseTime = CreateConVar(
		"hsm_drt_basetime",
		"150",
		"Base time for round.",
		FCVAR_PLUGIN,
		true, 0.0
	);
	
	cvarIncTime = CreateConVar(
		"hsm_drt_inctime",
		"30",
		"Additional time for each IRIS player.",
		FCVAR_PLUGIN,
		true, 0.0
	);
	
	cvarRandomTime = CreateConVar(
		"hsm_drt_randtime",
		"30",
		"Additional random time added per round. 0: None",
		FCVAR_PLUGIN,
		true,
		0.0
	);
	
	cvarRoundTime = FindConVar("mp_roundtime");
	
	HookEvent("player_team", event_Generic);
}

public Action:event_Generic(Handle:event, const String:name[], bool:dontBroadcast) {
	new iPlayers = 0;
	new iMaxClients = GetMaxClients();
	for (new i = 1; i <= iMaxClients; i++) {
		if (IsClientInGame(i)) {
			if (
				GetClientTeam(i) > HDN_TEAM_SPECTATOR &&
				i != GetClientOfUserId(GetEventInt(event, "userid"))
			) {
				iPlayers++;
			}
		}
	}
	
	SetConVarInt(
		cvarRoundTime,
		GetConVarInt(cvarBaseTime) + GetRandomInt(0, GetConVarInt(cvarRandomTime)) + (iPlayers * GetConVarInt(cvarIncTime))
	);
}
