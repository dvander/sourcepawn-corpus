/**
 * HLstatsX - SourceMod plugin to generate advanced weapon logging
 * http://www.hlstatsx.com/
 * Copyright (C) 2007-2008 TTS Oetzel & Goerz GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include <sourcemod>
#include <sdktools>


#define HITGROUP_GENERIC   0
#define HITGROUP_HEAD      1
#define HITGROUP_CHEST     2
#define HITGROUP_STOMACH   3
#define HITGROUP_LEFTARM   4
#define HITGROUP_RIGHTARM  5
#define HITGROUP_LEFTLEG   6
#define HITGROUP_RIGHTLEG  7

#define MAX_LOG_PLAYERS    64
#define MAX_LOG_WEAPONS    32

#define LOG_HIT_OFFSET     7 

#define LOG_HIT_SHOTS      0
#define LOG_HIT_HITS       1
#define LOG_HIT_KILLS      2
#define LOG_HIT_HEADSHOTS  3
#define LOG_HIT_TEAMKILLS  4
#define LOG_HIT_DAMAGE     5
#define LOG_HIT_DEATHS     6
#define LOG_HIT_GENERIC    7
#define LOG_HIT_HEAD       8
#define LOG_HIT_CHEST      9
#define LOG_HIT_STOMACH    10
#define LOG_HIT_LEFTARM    11
#define LOG_HIT_RIGHTARM   12
#define LOG_HIT_LEFTLEG    13
#define LOG_HIT_RIGHTLEG   14

new String: game_mod[32];
new String: team_list[16][64];

new weapon_stats[MAX_LOG_PLAYERS + 1][MAX_LOG_WEAPONS][15];
new String: css_weapon_list[][] = {
									"ak47", 
									"m4a1",
									"awp", 
									"deagle",
									"mp5navy",
									"aug", 
									"p90",
									"famas",
									"galil",
									"scout",
									"g3sg1",
									"hegrenade",
									"usp",
									"glock",
									"m249",
									"m3",
									"elite",
									"fiveseven",
									"mac10",
									"p228",
									"sg550",
									"sg552",
									"tmp",
									"ump45",
									"xm1014",
									"knife",
									"smokegrenade",
									"flashbang"
								};

new String: dods_weapon_list[][] = {
									 "thompson",		// 11
									 "m1carbine",		// 7
									 "k98",				// 8
									 "k98_scoped",		// 10	// 34
									 "mp40",			// 12
									 "mg42",			// 16	// 36
									 "mp44",			// 13	// 38
									 "colt",			// 3
									 "garand",			// 31	// 6
									 "spring",			// 9	// 33
									 "c96",				// 5
									 "bar",				// 14
									 "30cal",			// 15	// 35
									 "bazooka",			// 17
									 "pschreck",		// 18
									 "p38",				// 4
									 "spade",			// 2
									 "frag_ger",		// 20
									 "punch",			// 30	// 29
									 "frag_us",			// 19
									 "amerknife",		// 1
									 "riflegren_ger",	// 26
									 "riflegren_us",	// 25
									 "smoke_ger",		// 24
									 "smoke_us",		// 23
									 "dod_bomb_target"
								};

public Plugin:myinfo = {
	name = "Weapon Logging",
	author = "TTS Oetzel & Goerz GmbH. Modified by Guardia Republicano.",
	description = "Advanced weapon logging for HLstatsX",
	version = "2.6",
	url = "http://www.hlstatsx.com"
};


public OnPluginStart()
{
	for (new i = 0; (i < (MAX_LOG_PLAYERS + 1)); i++) {
		reset_player_stats(i);
	}

	get_server_mod();
}


public OnMapStart()
{
	if ((strcmp(game_mod, "CSS") == 0) || (strcmp(game_mod, "TF") == 0) || (strcmp(game_mod, "DODS") == 0)) {
		new max_teams_count = GetTeamCount();
		for (new team_index = 0; (team_index < max_teams_count); team_index++) {
			decl String: team_name[64];
			GetTeamName(team_index, team_name, 64);
			if (strcmp(team_name, "") != 0) {
				team_list[team_index] = team_name;
			}
		}
	}
}


get_server_mod()
{
	if (strcmp(game_mod, "") == 0) {
		new String: game_description[64];
		GetGameDescription(game_description, 64, true);
	
		if (StrContains(game_description, "Counter-Strike", false) != -1) {
			game_mod = "CSS";
		}
		if (StrContains(game_description, "Day of Defeat", false) != -1) {
			game_mod = "DODS";
		}
		if (StrContains(game_description, "Half-Life 2 Deathmatch", false) != -1) {
			game_mod = "HL2MP";
		}
		if (StrContains(game_description, "Team Fortress", false) != -1) {
			game_mod = "TF";
		}
		if (StrContains(game_description, "Insurgency", false) != -1) {
			game_mod = "INSMOD";
		}
		
		// game mod could not detected, try further
		if (strcmp(game_mod, "") == 0) {
			new String: game_folder[64];
			GetGameFolderName(game_folder, 64);

			if (StrContains(game_folder, "cstrike", false) != -1) {
				game_mod = "CSS";
			}
			if (StrContains(game_folder, "dod", false) != -1) {
				game_mod = "DODS";
			}
			if (StrContains(game_folder, "hl2mp", false) != -1) {
				game_mod = "HL2MP";
			}
			if (StrContains(game_folder, "tf", false) != -1) {
				game_mod = "TF";
			}
			if (StrContains(game_folder, "insurgency", false) != -1) {
				game_mod = "INSMOD";
			}
			if (strcmp(game_mod, "") == 0) {
				LogToGame("Mod Detection (Weapon Logging): Failed (%s, %s)", game_description, game_folder);
			}
		}

		if (strcmp(game_mod, "CSS") == 0) {
			HookEvent("weapon_fire",  Event_CSSPlayerFire);
			HookEvent("player_death", Event_CSSPlayerDeath);
			HookEvent("player_hurt",  Event_CSSPlayerHurt);
			HookEvent("player_spawn", Event_CSSPlayerSpawn);
			HookEvent("round_end",    Event_CSSRoundEnd);
		}

		if (strcmp(game_mod, "DODS") == 0) {
			HookEvent("dod_stats_weapon_attack",  Event_DODSWeaponAttack);
			HookEvent("player_death", Event_DODSPlayerDeath);
			HookEvent("player_hurt",  Event_DODSPlayerHurt);
			HookEvent("player_spawn", Event_DODSRoundEnd);
		}

		LogToGame("Mod Detection (Weapon Logging): %s [%s]", game_description, game_mod);
	}
}


get_weapon_index(const String: weapon_name[])
{
	new loop_break = 0;
	new index = 0;
	
	if (strcmp(game_mod, "CSS") == 0) {
		while ((loop_break == 0) && (index < sizeof(css_weapon_list))) {
    	    if (strcmp(weapon_name, css_weapon_list[index], true) == 0) {
        		loop_break++;
	        }
    	    index++;
		}
	} else if (strcmp(game_mod, "DODS") == 0) {
		while ((loop_break == 0) && (index < sizeof(dods_weapon_list))) {
    	    if (strcmp(weapon_name, dods_weapon_list[index], true) == 0) {
        		loop_break++;
	        }
    	    index++;
		}
	}

	if (loop_break == 0) {
		return -1;
	} else {
		return index - 1;
	}
}


reset_player_stats(player_index) 
{
	for (new i = 0; (i < MAX_LOG_WEAPONS); i++) {
		weapon_stats[player_index][i][LOG_HIT_SHOTS]     = 0;
		weapon_stats[player_index][i][LOG_HIT_HITS]      = 0;
		weapon_stats[player_index][i][LOG_HIT_KILLS]     = 0;
		weapon_stats[player_index][i][LOG_HIT_HEADSHOTS] = 0;
		weapon_stats[player_index][i][LOG_HIT_TEAMKILLS] = 0;
		weapon_stats[player_index][i][LOG_HIT_DAMAGE]    = 0;
		weapon_stats[player_index][i][LOG_HIT_DEATHS]    = 0;
		weapon_stats[player_index][i][LOG_HIT_GENERIC]   = 0;
		weapon_stats[player_index][i][LOG_HIT_HEAD]      = 0;
		weapon_stats[player_index][i][LOG_HIT_CHEST]     = 0;
		weapon_stats[player_index][i][LOG_HIT_STOMACH]   = 0;
		weapon_stats[player_index][i][LOG_HIT_LEFTARM]   = 0;
		weapon_stats[player_index][i][LOG_HIT_RIGHTARM]  = 0;
		weapon_stats[player_index][i][LOG_HIT_LEFTLEG]   = 0;
		weapon_stats[player_index][i][LOG_HIT_RIGHTLEG]  = 0;
	}
}


dump_player_stats(player_index)
{
	if ((IsClientConnected(player_index)) && (IsClientInGame(player_index)))  {

		decl String: player_name[64];
		if (!GetClientName(player_index, player_name, 64))	{
			strcopy(player_name, 64, "UNKNOWN");
		}
		decl String: player_authid[64];
		if (!GetClientAuthString(player_index, player_authid, 64)){
			strcopy(player_authid, 64, "UNKNOWN");
		}
		new player_team_index = GetClientTeam(player_index);
		decl String: player_team[64];
		player_team = team_list[player_team_index];

		new player_userid = GetClientUserId(player_index);

		new is_logged = 0;
		for (new i = 0; (i < MAX_LOG_WEAPONS); i++) {
			if (weapon_stats[player_index][i][LOG_HIT_SHOTS] > 0) {
				if (strcmp(game_mod, "CSS") == 0) {
					LogToGame("\"%s<%d><%s><%s>\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", player_name, player_userid, player_authid, player_team, css_weapon_list[i], weapon_stats[player_index][i][LOG_HIT_SHOTS], weapon_stats[player_index][i][LOG_HIT_HITS], weapon_stats[player_index][i][LOG_HIT_KILLS], weapon_stats[player_index][i][LOG_HIT_HEADSHOTS], weapon_stats[player_index][i][LOG_HIT_TEAMKILLS], weapon_stats[player_index][i][LOG_HIT_DAMAGE], weapon_stats[player_index][i][LOG_HIT_DEATHS]); 
					LogToGame("\"%s<%d><%s><%s>\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", player_name, player_userid, player_authid, player_team, css_weapon_list[i], weapon_stats[player_index][i][LOG_HIT_HEAD], weapon_stats[player_index][i][LOG_HIT_CHEST], weapon_stats[player_index][i][LOG_HIT_STOMACH], weapon_stats[player_index][i][LOG_HIT_LEFTARM], weapon_stats[player_index][i][LOG_HIT_RIGHTARM], weapon_stats[player_index][i][LOG_HIT_LEFTLEG], weapon_stats[player_index][i][LOG_HIT_RIGHTLEG]); 
				} else if (strcmp(game_mod, "DODS") == 0) {
					LogToGame("\"%s<%d><%s><%s>\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", player_name, player_userid, player_authid, player_team, dods_weapon_list[i], weapon_stats[player_index][i][LOG_HIT_SHOTS], weapon_stats[player_index][i][LOG_HIT_HITS], weapon_stats[player_index][i][LOG_HIT_KILLS], weapon_stats[player_index][i][LOG_HIT_HEADSHOTS], weapon_stats[player_index][i][LOG_HIT_TEAMKILLS], weapon_stats[player_index][i][LOG_HIT_DAMAGE], weapon_stats[player_index][i][LOG_HIT_DEATHS]); 
					LogToGame("\"%s<%d><%s><%s>\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", player_name, player_userid, player_authid, player_team, dods_weapon_list[i], weapon_stats[player_index][i][LOG_HIT_HEAD], weapon_stats[player_index][i][LOG_HIT_CHEST], weapon_stats[player_index][i][LOG_HIT_STOMACH], weapon_stats[player_index][i][LOG_HIT_LEFTARM], weapon_stats[player_index][i][LOG_HIT_RIGHTARM], weapon_stats[player_index][i][LOG_HIT_LEFTLEG], weapon_stats[player_index][i][LOG_HIT_RIGHTLEG]);
					if(weapon_stats[player_index][i][LOG_HIT_HEADSHOTS] > 0) {
						LogToGame("\"%s<%d><%s><%s>\" triggered \"headshot\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", player_name, player_userid, player_authid, player_team, dods_weapon_list[i], weapon_stats[player_index][i][LOG_HIT_SHOTS], weapon_stats[player_index][i][LOG_HIT_HITS], weapon_stats[player_index][i][LOG_HIT_KILLS], weapon_stats[player_index][i][LOG_HIT_HEADSHOTS], weapon_stats[player_index][i][LOG_HIT_TEAMKILLS], weapon_stats[player_index][i][LOG_HIT_DAMAGE], weapon_stats[player_index][i][LOG_HIT_DEATHS]); 
					}
				}
				is_logged++;
			}
		}
		if (is_logged > 0) {
			reset_player_stats(player_index);
		}
	}
	
}


public Action:Event_DODSWeaponAttack(Handle:event, const String:name[], bool:dontBroadcast)
{
    // "attacker"      "short"
    // "weapon"        "byte"

	new userid   = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (userid > 0) {

		new String: weapon[64];
		new log_weapon_index  = GetEventInt(event, "weapon");
		switch (log_weapon_index) {
			case 1 :
				weapon = "amerknife";
			case 2 :
				weapon = "spade";
			case 3 :
				weapon = "colt";
			case 4 :
				weapon = "p38";
			case 5 :
				weapon = "c96";
			case 6 :
				weapon = "garand";
			case 7 :
				weapon = "m1carbine";
			case 8 :
				weapon = "k98";
			case 9 :
				weapon = "spring";
			case 10 :
				weapon = "k98_scoped";
			case 11 :
				weapon = "thompson";
			case 12 :
				weapon = "mp40";
			case 13 :
				weapon = "mp44";
			case 14 :
				weapon = "bar";
			case 15 :
				weapon = "30cal";
			case 16 :
				weapon = "mg42";
			case 17 :
				weapon = "bazooka";
			case 18 :
				weapon = "pschreck";
			case 19 :
				weapon = "frag_us";
			case 20 :
				weapon = "frag_ger";
			case 23 :
				weapon = "smoke_us";
			case 24 :
				weapon = "smoke_ger";
			case 25 :
				weapon = "riflegren_us";
			case 26 :
				weapon = "riflegren_ger";
			case 31 :
				weapon = "garand";
			case 33 :
				weapon = "spring";
			case 34 :
				weapon = "k98_scoped";
			case 35 :
				weapon = "30cal";
			case 36 :
				weapon = "mg42";
			case 38 :
				weapon = "mp44";
		}
		
		new weapon_index = get_weapon_index(weapon);
		if (weapon_index > -1) {
			if ((strcmp(weapon, "dod_bomb_target") != 0) && (strcmp(weapon, "riflegren_ger") != 0) && (strcmp(weapon, "riflegren_us") != 0) && (strcmp(weapon, "smoke_ger") != 0) && (strcmp(weapon, "smoke_us") != 0)) {
				weapon_stats[userid][weapon_index][LOG_HIT_SHOTS]++;
			}
		}
	}

}


public Action:Event_CSSPlayerFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	// "userid"        "short"
	// "weapon"        "string"        // weapon name used

	new userid   = GetClientOfUserId(GetEventInt(event, "userid"));
	if (userid > 0) {
		decl String: weapon[64];
		GetEventString(event, "weapon", weapon, 64)
		new weapon_index = get_weapon_index(weapon);
		if (weapon_index > -1) {
		    if ((strcmp(weapon, "flashbang") != 0) && (strcmp(weapon, "hegrenade") != 0) && (strcmp(weapon, "smokegrenade") != 0)) {
				weapon_stats[userid][weapon_index][LOG_HIT_SHOTS]++;
			}
		}
	}
}


public Action:Event_CSSPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	//	"userid"        "short"         // player index who was hurt
	//	"attacker"      "short"         // player index who attacked
	//	"health"        "byte"          // remaining health points
	//	"armor"         "byte"          // remaining armor points
	//	"weapon"        "string"        // weapon name attacker used, if not the world
	//	"dmg_health"    "byte"  		// damage done to health
	//	"dmg_armor"     "byte"          // damage done to armor
	//	"hitgroup"      "byte"          // hitgroup that was damaged

	new attacker  = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage    = GetEventInt(event, "dmg_health");
	new hitgroup  = GetEventInt(event, "hitgroup");
	
	if (attacker > 0) {
		decl String: weapon[64];
		GetEventString(event, "weapon", weapon, 64)
		new weapon_index = get_weapon_index(weapon);
		if (weapon_index > -1) {
			if ((strcmp(weapon, "flashbang") != 0) && (strcmp(weapon, "hegrenade") != 0) && (strcmp(weapon, "smokegrenade") != 0)) {
				weapon_stats[attacker][weapon_index][LOG_HIT_SHOTS]++;
			}
			weapon_stats[attacker][weapon_index][LOG_HIT_HITS]++;
			weapon_stats[attacker][weapon_index][LOG_HIT_DAMAGE]  += damage;
			if (hitgroup < 8) {
				weapon_stats[attacker][weapon_index][hitgroup + LOG_HIT_OFFSET]++;
			}
		}
	}

	return Plugin_Continue
}


public Action:Event_DODSPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	// "userid"        "short"         // user ID who was hurt
	// "attacker"      "short"         // user ID who attacked
	// "weapon"        "string"        // weapon name attacker used
	// "health"        "byte"          // health remaining
	// "damage"        "byte"          // how much damage in this attack
	// "hitgroup"      "byte"          // what hitgroup was hit

	// BEGIN - 24/08/2008 - Guardia Republicano	
	// Set damage to damage var instead of health. Get health and create a headshot var for HS detection.
	new attacker  = GetClientOfUserId(GetEventInt(event, "attacker"));
	//new damage    = GetEventInt(event, "health");
	new damage    = GetEventInt(event, "damage");
	new hitgroup  = GetEventInt(event, "hitgroup");
	new health    = GetEventInt(event, "health");
	new headshot   = (health == 0 && GetEventInt(event, "hitgroup") == HITGROUP_HEAD);
	// END - 24/08/2008 - Guardia Republicano
	
	if (attacker > 0) {
		decl String: weapon[64];
		GetEventString(event, "weapon", weapon, 64)
		new weapon_index = get_weapon_index(weapon);
		if (weapon_index > -1) {
			weapon_stats[attacker][weapon_index][LOG_HIT_HITS]++;
			weapon_stats[attacker][weapon_index][LOG_HIT_DAMAGE]  += damage;
			if (hitgroup < 8) {
				weapon_stats[attacker][weapon_index][hitgroup + LOG_HIT_OFFSET]++;
			}
			
			// BEGIN - 24/08/2008 - Guardia Republicano	
			// if headshot increment HS counter
			if (headshot) {
				weapon_stats[attacker][weapon_index][LOG_HIT_HEADSHOTS]++;
			}	
			// END - 24/08/2008 - Guardia Republicano
		}
	}

	return Plugin_Continue
}

 
public Action:Event_CSSPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// this extents the original player_death by a new fields
	// "userid"        "short"         // user ID who died                             
	// "attacker"      "short"         // user ID who killed
	// "weapon"        "string"        // weapon name killer used 
	// "headshot"      "bool"          // singals a headshot

	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new headshot = GetEventBool(event, "headshot");

	if ((victim > 0) && (attacker > 0)) {
		decl String: weapon[64];
		GetEventString(event, "weapon", weapon, 64)
		new weapon_index = get_weapon_index(weapon);
		if (weapon_index > -1) {
			weapon_stats[attacker][weapon_index][LOG_HIT_KILLS]++;
			if (headshot == 1) {
				weapon_stats[attacker][weapon_index][LOG_HIT_HEADSHOTS]++;
			}
			weapon_stats[victim][weapon_index][LOG_HIT_DEATHS]++;
			if (GetClientTeam(attacker) == GetClientTeam(victim)) {
				weapon_stats[attacker][weapon_index][LOG_HIT_TEAMKILLS]++;
			}
			dump_player_stats(victim);
		}
	}

	return Plugin_Continue
}


public Action:Event_DODSPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// this extents the original player_death
	// "userid"        "short"         // user ID who died
	// "attacker"      "short"         // user ID who killed
	// "weapon"        "string"        // weapon name killed used

	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if ((victim > 0) && (attacker > 0)) {
		decl String: weapon[64];
		GetEventString(event, "weapon", weapon, 64)
		new weapon_index = get_weapon_index(weapon);
		if (weapon_index > -1) {
			weapon_stats[attacker][weapon_index][LOG_HIT_KILLS]++;
			weapon_stats[victim][weapon_index][LOG_HIT_DEATHS]++;
			if (GetClientTeam(attacker) == GetClientTeam(victim)) {
				weapon_stats[attacker][weapon_index][LOG_HIT_TEAMKILLS]++;
			}
			dump_player_stats(victim);
		}
	}

	return Plugin_Continue
}


public Action:Event_CSSPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid   = GetClientOfUserId(GetEventInt(event, "userid"));
	if (userid > 0) {
		reset_player_stats(userid);
	}
	return Plugin_Continue
}


public Action:Event_CSSRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new max_clients = GetMaxClients();
	for (new i = 1; (i <= max_clients); i++) {
		dump_player_stats(i);
	}
	return Plugin_Continue
}


public Action:Event_DODSRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new max_clients = GetMaxClients();
	for (new i = 1; (i <= max_clients); i++) {
		dump_player_stats(i);
	}
	return Plugin_Continue
}


public OnClientDisconnect(client)
{
	if (client > 0) {
		reset_player_stats(client);
	}
}



