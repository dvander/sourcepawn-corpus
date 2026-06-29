/**
 * =============================================================================
 * SourceMod PsychoStats Plugin
 * Implements support for PsychoStats and enhances game logging to provide more
 * statistics. 
 *
 * This plugin will add "Spatial" stats to mods (just like TF). This allows
 * Heatmaps and trajectories to be created and viewed in the player stats.
 * This plugin will also 'fix' the game logging so the first map to run on 
 * server restart will log properly (HLDS doesn't log the first map). This
 * will prevent any 'unknown' maps from appearing in your player stats.
 *
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Version: $Id: ps_heatmaps.sp 411 2008-04-23 18:07:12Z lifo $
 * Author:  Stormtrooper <http://www.psychostats.com/>
 */

#pragma semicolon 1

#include <sourcemod>
#include <logging>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "PsychoStats Spatial Plugin",
	author = "Stormtrooper, K1ller",
	description = "Logs spatial statstics on kill events so Heatmaps can be created.",
	version = "1.0",
	url = "http://www.psychostats.com/"
};

public OnPluginStart()
{
	// do not enable on TF2 servers. TF2 natively supports spatial stats
	new String:gameFolder[64];
	GetGameFolderName(gameFolder, sizeof(gameFolder));
	new bool:logSpatial = !(StrEqual(gameFolder, "tf"));

	if (logSpatial) {
		HookEvent("player_death", Event_PlayerDeath);
	}
}


public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{

	/* Get player IDs */
        new victimId = GetEventInt(event, "userid");
        new attackerId = GetEventInt(event, "attacker");
	new bool:suicide = false;

	suicide = (victimId == attackerId);

	/* Get both players' location coordinates */
        new Float:victimLocation[3];
        new Float:attackerLocation[3];
        new victim = GetClientOfUserId(victimId);
        new attacker = GetClientOfUserId(attackerId);
        GetClientAbsOrigin(victim, victimLocation);
        GetClientAbsOrigin(attacker, attackerLocation);

	/* Get weapon */
        decl String:weapon[64];
        GetEventString(event, "weapon", weapon, sizeof(weapon));

	/* Is headshot? */
        new bool:headshot = GetEventBool(event, "headshot");

	/* Get both players' name */
	decl String:attackerName[64];
	decl String:victimName[64];
	GetClientName(attacker, attackerName, sizeof(attackerName));
	GetClientName(victim, victimName, sizeof(victimName));

	/* Get both players' SteamIDs */
	decl String:attackerSteamId[64];
	decl String:victimSteamId[64];
	GetClientAuthString(attacker, attackerSteamId, sizeof(attackerSteamId));
	GetClientAuthString(victim, victimSteamId, sizeof(victimSteamId));

	/* Get both players' teams */
	decl String:attackerTeam[64];
	decl String:victimTeam[64];
	GetTeamName(GetClientTeam(attacker), attackerTeam, sizeof(attackerTeam));
	GetTeamName(GetClientTeam(victim), victimTeam, sizeof(victimTeam));

	if (suicide) {
			LogToGame("[KTRAJ] \"%s<%d><%s><%s>\" committed suicide with \"%s\" (attacker_position \"%d %d %d\")",
	 		victimName,
	 		victimId,
	 		victimSteamId,
	 		victimTeam,
	 		weapon,
	       		RoundFloat(attackerLocation[0]),
	       		RoundFloat(attackerLocation[1]),
	       		RoundFloat(attackerLocation[2])
		);
	} else {
	       	LogToGame("[KTRAJ] \"%s<%d><%s><%s>\" killed \"%s<%d><%s><%s>\" with \"%s\" %s(attacker_position \"%d %d %d\") (victim_position \"%d %d %d\")", 
			attackerName,
			attackerId,
	 		attackerSteamId,
	 		attackerTeam,
	 		victimName,
	 		victimId,
	 		victimSteamId,
	 		victimTeam,
	 		weapon,
			((headshot) ? "(headshot) " : ""),
	 		RoundFloat(attackerLocation[0]),
	       		RoundFloat(attackerLocation[1]),
	       		RoundFloat(attackerLocation[2]),
	       		RoundFloat(victimLocation[0]),
	       		RoundFloat(victimLocation[1]),
	       		RoundFloat(victimLocation[2])
		);
	}
	return Plugin_Continue;
}
