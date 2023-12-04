/**
 * HLstatsX Community Edition - SourceMod plugin to generate advanced weapon logging
 * http://www.hlxcommunity.com
 * Copyright (C) 2009 Nicholas Hastings (psychonic)
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

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define NAME "SuperLogs: L4D+L4D2"
#define VERSION "1.3.4h"

#define MAX_LOG_WEAPONS 27
#define MAX_WEAPON_LEN 16

int g_weapon_stats[MAXPLAYERS + 1][MAX_LOG_WEAPONS][15];
char g_weapon_list[MAX_LOG_WEAPONS][MAX_WEAPON_LEN] = {
									"autoshotgun",
									"rifle",
									"pumpshotgun",
									"smg",
									"dual_pistols",
									"pipe_bomb",
									"hunting_rifle",
									"pistol",
									"prop_minigun",
									"tank_claw",
									"hunter_claw",
									"smoker_claw",
									"boomer_claw",
									"smg_silenced",		//l4d2 start 14 [13]
									"pistol_magnum",
									"rifle_ak47",
									"rifle_desert",
									"shotgun_chrome",
									"shotgun_spas",
									"sniper_military",
									"rifle_sg552",
									"smg_mp5",
									"sniper_awp",
									"sniper_scout",
									"jockey_claw",
									"splitter_claw",
									"charger_claw"
									};

ConVar 	g_cvar_wstats, 
		g_cvar_actions, 
		g_cvar_headshots, 
		g_cvar_meleeoverride;

bool	g_logwstats = true, 
		g_logactions = true, 
		g_logheadshots = true, 
		g_logmeleeoverride = true, 
		g_bIsL4D2;

int g_iActiveWeaponOffset;

#include <loghelper>
#include <wstatshelper>

public Plugin myinfo =
{
	name = NAME,
	author = "psychonic modded by Huck",
	description = "Advanced logging for Left 4 Dead. Generates auxilary logging for use with log parsers such as HLstatsX and Psychostats",
	version = VERSION,
	url = "https://bitbucket.org/Maverick_of_UC/hlstatsx-community-edition/wiki/Home"
};

#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
#else
public bool AskPluginLoad(Handle myself, bool late, char[] error, int err_max)
#endif
{
	char szGameDesc[64];
	GetGameDescription(szGameDesc, sizeof(szGameDesc), true);
	if (strncmp(szGameDesc, "L4D", 3, false) != 0 && StrContains(szGameDesc, "Left 4 D", false) == -1)
	{
		char szGameDir[64];
		GetGameFolderName(szGameDir, sizeof(szGameDir));
		if (StrContains(szGameDir, "left4dead", false) == -1)
		{
			strcopy(error, err_max, "This plugin is only supported on L4D & L4D2");
			#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
				return APLRes_Failure;
			#else
				return false;
			#endif
		}
	}
#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
	return APLRes_Success;
#else
	return true;
#endif
}

public void OnPluginStart()
{
	CreatePopulateWeaponTrie();

	g_cvar_wstats = CreateConVar("superlogs_wstats", "1", "Enable logging of weapon stats (default on)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvar_actions = CreateConVar("superlogs_actions", "1", "Enable logging of player actions, such as \"Got_The_Bomb\" (default on)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvar_headshots = CreateConVar("superlogs_headshots", "1", "Enable logging of headshot player action (default off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvar_meleeoverride = CreateConVar("superlogs_meleeoverride", "1", "Enable changing \"melee\" weapon in server logs to specific weapon (L4D2-only) (default on)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(g_cvar_wstats, OnCvarWstatsChange);
	HookConVarChange(g_cvar_actions, OnCvarActionsChange);
	HookConVarChange(g_cvar_headshots, OnCvarHeadshotsChange);
	HookConVarChange(g_cvar_meleeoverride, OnCvarMeleeOverrideChange);
	CreateConVar("superlogs_l4d_version", VERSION, NAME, FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);

	EngineVersion version = GetEngineVersion();
	if(version == Engine_Left4Dead2)
	{
	    g_bIsL4D2 = true;
	}
	else
	{
		g_bIsL4D2 = false;
	}

	hook_actions();
	hook_wstats();
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	CreateTimer(120.0, FlushWeaponLogs, 0, TIMER_REPEAT);

	CreateTimer(1.0, LogMap);

	GetTeams();

	g_iActiveWeaponOffset = FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon");
	AutoExecConfig(true, "superlogs-l4d");
}

public void OnMapStart()
{
	GetTeams();
}

void hook_actions()
{
	HookEvent("survivor_rescued", Event_RescueSurvivor);
	HookEvent("heal_success", Event_Heal);
	HookEvent("revive_success", Event_Revive);
	HookEvent("witch_harasser_set", Event_StartleWitch);
	HookEvent("lunge_pounce", Event_Pounce);
	HookEvent("player_now_it", Event_Boomered);
	HookEvent("friendly_fire", Event_FF);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("award_earned", Event_Award);
	if (g_bIsL4D2)
	{
		HookEvent("defibrillator_used", Event_Defib);
		HookEvent("adrenaline_used", Event_Adrenaline);
		HookEvent("jockey_ride", Event_JockeyRide);
		HookEvent("charger_pummel_start", Event_ChargerPummelStart);
		HookEvent("vomit_bomb_tank", Event_VomitBombTank);
		HookEvent("scavenge_match_finished", Event_ScavengeEnd);
		HookEvent("versus_match_finished", Event_VersusEnd);
	}
}

void unhook_actions()
{
	UnhookEvent("survivor_rescued", Event_RescueSurvivor);
	UnhookEvent("heal_success", Event_Heal);
	UnhookEvent("revive_success", Event_Revive);
	UnhookEvent("witch_harasser_set", Event_StartleWitch);
	UnhookEvent("lunge_pounce", Event_Pounce);
	UnhookEvent("player_now_it", Event_Boomered);
	UnhookEvent("friendly_fire", Event_FF);
	UnhookEvent("witch_killed", Event_WitchKilled);
	UnhookEvent("award_earned", Event_Award);

	if (g_bIsL4D2)
	{
		UnhookEvent("defibrillator_used", Event_Defib);
		UnhookEvent("adrenaline_used", Event_Adrenaline);
		UnhookEvent("jockey_ride", Event_JockeyRide);
		UnhookEvent("charger_pummel_start", Event_ChargerPummelStart);
		UnhookEvent("vomit_bomb_tank", Event_VomitBombTank);
		UnhookEvent("scavenge_match_finished", Event_ScavengeEnd);
		UnhookEvent("versus_match_finished", Event_VersusEnd);
	}
}

void hook_wstats()
{
	HookEvent("weapon_fire", Event_PlayerShoot);
	HookEvent("weapon_fire_on_empty", Event_PlayerShoot);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("infected_hurt", Event_InfectedHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_end_message", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

void unhook_wstats()
{
	UnhookEvent("weapon_fire", Event_PlayerShoot);
	UnhookEvent("weapon_fire_on_empty", Event_PlayerShoot);
	UnhookEvent("player_hurt", Event_PlayerHurt);
	UnhookEvent("infected_hurt", Event_InfectedHurt);
	UnhookEvent("player_death", Event_PlayerDeath);
	UnhookEvent("player_spawn", Event_PlayerSpawn);
	UnhookEvent("round_end_message", Event_RoundEnd, EventHookMode_PostNoCopy);
	UnhookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

public void OnClientPutInServer(int client)
{
	reset_player_stats(client);
}

public Action FlushWeaponLogs(Handle timer, any index) 
{
	if (g_logwstats)
	{
		WstatsDumpAll();
	}
	return Plugin_Continue;
}

public void Event_PlayerShoot(Event event, const char[] name, bool dontBroadcast)
{
	// "local"         "1"             // don't network this, its way too spammy
	// "userid"        "short"
	// "weapon"        "string"        // used weapon name  
	// "weaponid"      "short"         // used weapon ID
	// "count"         "short"         // number of bullets

	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (attacker > 0)
	{
		char weapon[MAX_WEAPON_LEN];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		int weapon_index = get_weapon_index(weapon);
		if (weapon_index > -1)
		{
			g_weapon_stats[attacker][weapon_index][LOG_HIT_SHOTS]++;
		}
	}
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	// "local"         "1"             // Not networked
	// "userid"        "short"         // user ID who was hurt
	// "attacker"      "short"         // user id who attacked
	// "attackerentid" "long"          // entity id who attacked, if attacker not a player, and userid therefore invalid
	// "health"        "short"         // remaining health points
	// "armor"         "byte"          // remaining armor points
	// "weapon"        "string"        // weapon name attacker used, if not the world
	// "dmg_health"    "short"         // damage done to health
	// "dmg_armor"     "byte"          // damage done to armor
	// "hitgroup"      "byte"          // hitgroup that was damaged
	// "type"          "long"          // damage type

	int attacker  = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker > 0)
	{
		char weapon[MAX_WEAPON_LEN];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		int weapon_index = get_weapon_index(weapon);
		if (weapon_index > -1)
		{
			g_weapon_stats[attacker][weapon_index][LOG_HIT_HITS]++;
			g_weapon_stats[attacker][weapon_index][LOG_HIT_DAMAGE] += GetEventInt(event, "dmg_health");
			int hitgroup  = GetEventInt(event, "hitgroup");
			if (hitgroup < 8)
			{
				g_weapon_stats[attacker][weapon_index][hitgroup + LOG_HIT_OFFSET]++;
			}
		}
		else if (g_logactions && !strcmp(weapon, "insect_swarm"))
		{
			int victim = GetClientOfUserId(GetEventInt(event, "userid"));
			if (victim > 0 && IsClientInGame(victim) && GetClientTeam(victim) == 2 &&  !GetEntProp(victim, Prop_Send, "m_isIncapacitated"))
			{
				LogPlyrPlyrEvent(attacker, victim, "triggered", "spit_hurt", true);
			}
		}
	}
}

public void Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	// "local"         "1"             // don't network this, its way too spammy
	// "attacker"      "short"         // player userid who attacked
	// "entityid"      "long"          // entity id of infected
	// "hitgroup"      "byte"          // hitgroup that was damaged
	// "amount"        "short"         // how much damage was done                  
	// "type"          "long"          // damage type     

	int attacker  = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker > 0)
	{
		char weapon[MAX_WEAPON_LEN];
		GetClientWeapon(attacker, weapon, sizeof(weapon));

		int weapon_index = get_weapon_index(weapon[7]);
		if (weapon_index > -1)
		{
			g_weapon_stats[attacker][weapon_index][LOG_HIT_HITS]++;
			g_weapon_stats[attacker][weapon_index][LOG_HIT_DAMAGE] += GetEventInt(event, "amount");
			int hitgroup  = GetEventInt(event, "hitgroup");
			if (hitgroup < 8)
			{
				g_weapon_stats[attacker][weapon_index][hitgroup + LOG_HIT_OFFSET]++;
			}
		}
	}
}

public void Event_PlayerDeathPre(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (g_logheadshots && GetEventBool(event, "headshot"))
	{
		LogPlayerEvent(attacker, "triggered", "headshot");
	}
	if (g_logmeleeoverride && g_bIsL4D2 && attacker > 0 && IsClientInGame(attacker))
	{
		char szWeapon[64];
		GetEventString(event, "weapon", szWeapon, sizeof(szWeapon));
		if (strncmp(szWeapon, "melee", 5) == 0)
		{
			int iWeapon = GetEntDataEnt2(attacker, g_iActiveWeaponOffset);
			if (IsValidEdict(iWeapon))
			{
				// They have time to switch weapons after the kill before the death event
				GetEdictClassname(iWeapon, szWeapon, sizeof(szWeapon));
				if (strncmp(szWeapon[7], "melee", 5) == 0)
				{
					GetEntPropString(iWeapon, Prop_Data, "m_strMapSetScriptName", szWeapon, sizeof(szWeapon));
					SetEventString(event, "weapon", szWeapon);
				}
			}
		}
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	// "userid"        "short"         // user ID who died
	// "entityid"      "long"          // entity ID who died, userid should be used first, to get the dead Player.  Otherwise, it is not a player, so use this.         $
	// "attacker"      "short"         // user ID who killed   
	// "attackername"  "string"        // What type of zombie, so we don't have zombie names
	// "attackerentid" "long"          // if killer not a player, the entindex of who killed.  Again, use attacker first
	// "weapon"        "string"        // weapon name killer used
	// "headshot"      "bool"          // signals a headshot
	// "attackerisbot" "bool"          // is the attacker a bot
	// "victimname"    "string"        // What type of zombie, so we don't have zombie names
	// "victimisbot"   "bool"          // is the victim a bot     
	// "abort"         "bool"          // did the victim abort        
	// "type"          "long"          // damage type      
	// "victim_x"      "float"
	// "victim_y"      "float"
	// "victim_z"      "float"

	int victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (g_logwstats && victim > 0 && attacker > 0)
	{
		char weapon[MAX_WEAPON_LEN];
		GetEventString(event, "weapon", weapon, sizeof(weapon));

		int weapon_index = get_weapon_index(weapon);
		if (weapon_index > -1)
		{
			g_weapon_stats[attacker][weapon_index][LOG_HIT_KILLS]++;
			if (GetEventBool(event, "headshot"))
			{
				g_weapon_stats[attacker][weapon_index][LOG_HIT_HEADSHOTS]++;
			}
			g_weapon_stats[victim][weapon_index][LOG_HIT_DEATHS]++;
			if (GetClientTeam(attacker) == GetClientTeam(victim))
			{
				g_weapon_stats[attacker][weapon_index][LOG_HIT_TEAMKILLS]++;
			}
			dump_player_stats(victim);
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	WstatsDumpAll();
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	// "userid"        "short"         // user ID on server
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0)
	{
		reset_player_stats(client);
	}
}

public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	OnPlayerDisconnect(client);
	return Plugin_Continue;
}

public Action LogMap(Handle timer)
{
	// Called 1 second after OnPluginStart since srcds does not log the first map loaded. Idea from Stormtrooper's "mapfix.sp" for psychostats
	LogMapLoad();

	return Plugin_Continue;
}

public void Event_RescueSurvivor(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "rescuer"));

	if (player > 0)
	{
		LogPlayerEvent(player, "triggered", "rescued_survivor", true);
	}
}

public void Event_Heal(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "userid"));

	if (player > 0 && player != GetClientOfUserId(GetEventInt(event, "subject")))
	{
		LogPlayerEvent(player, "triggered", "healed_teammate", true);
	}
}

public void Event_Revive(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "userid"));

	if (player > 0)
	{
		LogPlayerEvent(player, "triggered", "revived_teammate", true);
	}
}

public void Event_StartleWitch(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "userid"));

	if (player > 0 && (!g_bIsL4D2 || GetEventBool(event, "first")))
	{
		LogPlayerEvent(player, "triggered", "startled_witch", true);
	}
}

public void Event_Pounce(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "userid"));
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (victim > 0)
	{
		LogPlyrPlyrEvent(player, victim, "triggered", "pounce", true);
	}
	else
	{
		LogPlayerEvent(player, "triggered", "pounce", true);
	}
}

public void Event_Boomered(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (player > 0 && (!g_bIsL4D2 || GetEventBool(event, "by_boomer")))
	{
		if (victim > 0)
		{
			LogPlyrPlyrEvent(player, victim, "triggered", "vomit", true);
		}
		else
		{
			LogPlayerEvent(player, "triggered", "vomit", true);
		}
	}
}

public void Event_FF(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (player > 0 && player == GetClientOfUserId(GetEventInt(event, "guilty")))
	{
		if (victim > 0)
		{
			LogPlyrPlyrEvent(player, victim, "triggered", "friendly_fire", true);
		}
		else
		{
			LogPlayerEvent(player, "triggered", "friendly_fire", true);
		}
	}
}

public void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (GetEventBool(event, "oneshot"))
	{
		LogPlayerEvent(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "cr0wned", true);
	}
}

public void Event_Defib(Event event, const char[] name, bool dontBroadcast)
{
	LogPlayerEvent(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "defibrillated_teammate", true);
}

public void Event_Adrenaline(Event event, const char[] name, bool dontBroadcast)
{
	LogPlayerEvent(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "used_adrenaline", true);
}

public void Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "userid"));
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (player > 0)
	{
		if (victim > 0)
		{
			LogPlyrPlyrEvent(player, victim, "triggered", "jockey_ride", true);
		}
		else
		{
			LogPlayerEvent(player, "triggered", "jockey_ride", true);
		}
	}
}

public void Event_ChargerPummelStart(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "userid"));
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (victim > 0)
	{
		LogPlyrPlyrEvent(player, victim, "triggered", "charger_pummel", true);
	}
	else
	{
		LogPlayerEvent(player, "triggered", "charger_pummel", true);
	}
}

public void Event_VomitBombTank(Event event, const char[] name, bool dontBroadcast)
{
	LogPlayerEvent(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "bilebomb_tank", true);
}

public void Event_ScavengeEnd(Event event, const char[] name, bool dontBroadcast)
{
	LogTeamEvent(GetEventInt(event, "winners"), "triggered", "Scavenge_Win");
}

public void Event_VersusEnd(Event event, const char[] name, bool dontBroadcast)
{
	LogTeamEvent(GetEventInt(event, "winners"), "triggered", "Versus_Win");
}

public Action Event_Award(Event event, const char[] name, bool dontBroadcast)
{
	// "userid"	"short"			// player who earned the award
	// "entityid"	"long"			// client likes ent id
	// "subjectentid"	"long"			// entity id of other party in the award, if any
	// "award"		"short"			// id of award earned
	
	switch(GetEventInt(event, "award"))
	{
		case 21:
			LogPlayerEvent(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "hunter_punter", true);
		case 27:
			LogPlayerEvent(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "tounge_twister", true);
		case 67:
			LogPlayerEvent(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "protect_teammate", true);
		case 80:
			LogPlayerEvent(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "no_death_on_tank", true);
		case 136:
			LogPlayerEvent(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "killed_all_survivors", true);
	}
	return Plugin_Continue;
}

public void OnCvarWstatsChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	bool old_value = g_logwstats;
	g_logwstats = GetConVarBool(g_cvar_wstats);

	if (old_value != g_logwstats)
	{
		if (g_logwstats)
		{
			hook_wstats();
		}
		else
		{
			unhook_wstats();
		}
	}
}

public void OnCvarActionsChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	bool old_value = g_logactions;
	g_logactions = GetConVarBool(g_cvar_actions);

	if (old_value != g_logactions)
	{
		if (g_logactions)
		{
			hook_actions();
		}
		else
		{
			unhook_actions();
		}
	}
}

public void OnCvarHeadshotsChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	bool old_value = g_logheadshots;
	g_logheadshots = GetConVarBool(g_cvar_headshots);

	if (old_value != g_logheadshots)
	{
		if (g_logheadshots && !g_logmeleeoverride)
		{
			HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
		}
		else if (!g_logmeleeoverride)
		{
			UnhookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
		}
	}
}

public void OnCvarMeleeOverrideChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	bool old_value = g_logmeleeoverride;
	g_logmeleeoverride = GetConVarBool(g_cvar_meleeoverride);

	if (old_value != g_logmeleeoverride)
	{
		if (g_logmeleeoverride && !g_logheadshots)
		{
			HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
		}
		else if (!g_logheadshots)
		{
			UnhookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
		}
	}
}
