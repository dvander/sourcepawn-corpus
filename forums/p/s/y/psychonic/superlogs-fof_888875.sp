/**
 * HLstatsX Community Edition - SourceMod plugin to generate advanced weapon logging
 * http://www.hlxcommunity.com
 * Copyright (C) 2008 Nicholas Hastings
 * Copyright (C) 2007-2008 TTS Oetzel & Goerz GmbH
 *
 * Code to support Fistful of Frags taken from FuraX49's wsl_fof plugin
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
 
#include <sourcemod>
#include <sdktools>

#define NAME "SuperLogs: FOF"
#define VERSION "3.1"

#define MAX_LOG_WEAPONS 17
#define MAX_WEAPON_LEN 15


new g_weapon_stats[MAXPLAYERS+1][MAX_LOG_WEAPONS][15];
new const String:g_weapon_list[MAX_LOG_WEAPONS][MAX_WEAPON_LEN] = {
									"peacemaker", 
									"carbine",
									"coltnavy",
									"henryrifle",
									"coachgun",
									"winchester",
									"henryrifle",
									"dualnavy",
									"dualpeacemaker", 
									"arrow",
									"bow",
									"sharps",
									"deringer",
									"arrow_fiery",
									"coltnavy2",
									"deringer2",
									"peacemaker2"
								};

#include <loghelper>
#include <wstatshelper>


public Plugin:myinfo = {
	name = NAME,
	author = "psychonic",
	description = "Advanced logging for Fistful of Frags. Generates auxilary logging for use with log parsers such as HLstatsX and Psychostats",
	version = VERSION,
	url = "http://www.hlxcommunity.com"
};


public OnPluginStart()
{
	CreatePopulateWeaponTrie();
				
	CreateConVar("superlogs_fof_version", VERSION, NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		
	CreateTimer(1.0, LogMap);
	
	GetTeams();
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt",  Event_PlayerHurt);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_shoot",  Event_PlayerShoot);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}


public OnMapStart()
{
	GetTeams();
}


public OnClientPutInServer(client)
{
	reset_player_stats(client);
}


public Event_PlayerShoot(Handle:event, const String:name[], bool:dontBroadcast)
{
	//	"userid" "local" // user ID on server
	//	"weapon" "local" // weapon name
	//	"mode" "local" // weapon mode 0 normal 1 ironsighted 2 fanning

	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (attacker > 0 && attacker <= MaxClients)
	{
		decl String: weapon[MAX_WEAPON_LEN];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		
		new weapon_index = get_weapon_index(weapon[7]);
		if (weapon_index == -1)
		{
			return;
		}
		
		new shots = GetEventInt(event, "pellets");
		if (shots == 0)
		{
			shots = 1;
		}
		
		g_weapon_stats[attacker][weapon_index][LOG_HIT_SHOTS] += shots;
	}
}


public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	//	"userid" "short" // user ID who was hurt
	//	"attacker" "short" // user ID who attacked
	//	"weapon" "string" // weapon name attacker used
	//	"health" "byte" // health remaining
	//	"damage" "byte" // how much damage in this attack
	//	"hitgroup" "byte" // what hitgroup was hit

	
	new attacker  = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (attacker > 0 && attacker <= MaxClients)
	{
		decl String: weapon[MAX_WEAPON_LEN];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		
		new weapon_index = get_weapon_index(weapon[7]);
		if (weapon_index == -1)
		{
			return;
		}
		
		g_weapon_stats[attacker][weapon_index][LOG_HIT_HITS]++;
		g_weapon_stats[attacker][weapon_index][LOG_HIT_DAMAGE]  += GetEventInt(event, "damage");
		new hitgroup  = GetEventInt(event, "hitgroup");
		if (hitgroup < 8)
		{
			g_weapon_stats[attacker][weapon_index][hitgroup + LOG_HIT_OFFSET]++;
		}
		else
		{
			g_weapon_stats[attacker][weapon_index][hitgroup]++;
		}
	}
}


public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	//	"userid"	"short"   	// user ID who died				
	//	"attacker"	"short"	 	// user ID who killed
	//	"weapon"	"string" 	// weapon name killed used 
	//	"headshot"      "bool" // player dies from a headshot?

	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (victim > 0 && attacker > 0 && attacker <= MaxClients)
	{
		decl String: weapon[MAX_WEAPON_LEN];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		
		new weapon_index = get_weapon_index(weapon[7]);
		if (weapon_index == -1)
		{
			return;
		}
		
		if ( GetClientTeam(attacker) == GetClientTeam(victim))
		{
			g_weapon_stats[attacker][weapon_index][LOG_HIT_TEAMKILLS]++;
			return;
		}
		
		g_weapon_stats[attacker][weapon_index][LOG_HIT_KILLS]++;
		g_weapon_stats[victim][weapon_index][LOG_HIT_DEATHS]++;
		
		if (GetEventBool(event, "headshot"))
		{
			g_weapon_stats[attacker][weapon_index][LOG_HIT_HEADSHOTS]++;
		}
		
		dump_player_stats(victim);
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// "userid"        "short"         // user ID on server          

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0)
	{
		reset_player_stats(client);
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	WstatsDumpAll();
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	OnPlayerDisconnect(client);
	return Plugin_Continue;
}

public Action:LogMap(Handle:timer)
{
	// Called 1 second after OnPluginStart since srcds does not log the first map loaded. Idea from Stormtrooper's "mapfix.sp" for psychostats
	LogMapLoad();
}
