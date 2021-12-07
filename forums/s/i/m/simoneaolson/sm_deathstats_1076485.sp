/**
 * =============================================================================
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
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
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.06"
new Handle:Cvar_DEATHSTATS_ENABLE, Handle:Cvar_DEATHSTATS_TIME, Handle:Cvar_DEATHSTATS_KS, Handle:Cvar_DEATHSTATS_DISPLAYED, Handle:DeathStatsMenu
new user, attacker, Secs, inc, kills, damage
new Hits[40], HitsTaken[40], RoundsFired[40], KillsMap[40], KillsRound[40], Deaths[40], DamageGiven[40], DamageTaken[40], Objectives[40], Defenses[40], wait[40]
new Float:SpawnTime[40], Float:DeathTime[40]
new String:temp[64], String:cappers[16], String:GameFolder[10]

public Plugin:myinfo = 
{
	name = "Death Stats Source",
	author = "simoneaolson",
	description = "Stats logging system, displays round information after death",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	CreateConVar("sm_deathstats_version", PLUGIN_VERSION, "Current plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	Cvar_DEATHSTATS_ENABLE = CreateConVar("sm_deathstats_enabled", "1", "Display stats on death 0/1", FCVAR_PLUGIN)
	Cvar_DEATHSTATS_DISPLAYED = CreateConVar("sm_deathstats_displayed", "1", "Display stats every X deaths (requires server restart)", FCVAR_PLUGIN)
	Cvar_DEATHSTATS_KS = CreateConVar("sm_deathstats_killstreaks", "1", "Display kill streak in hint text 0/1", FCVAR_PLUGIN)
	Cvar_DEATHSTATS_TIME = CreateConVar("sm_deathstats_time", "15", "Time to hold DeathStats menu for (seconds)", FCVAR_PLUGIN)

	HookEventEx("player_death", PlayerDeath)
	if (GetConVarBool(Cvar_DEATHSTATS_ENABLE) == false) return
	HookEventEx("player_spawn", PlayerSpawn)
	HookEventEx("player_hurt", DamageEvent)
	
	GetGameFolderName(GameFolder, 10)
	if (StrEqual(GameFolder, "dod", false))
	{
		HookEventEx("dod_stats_weapon_attack", FireWeapon1)
		HookEventEx("dod_point_captured", Objective1)
		HookEventEx("dod_capture_blocked", Defense1)
		HookEventEx("dod_bomb_planted", Objective2)
		HookEventEx("dod_bomb_defused", Defense2)
	}
	if (StrEqual(GameFolder, "cstrike", false))
	{
		HookEventEx("weapon_fire", FireWeapon2)
		HookEventEx("bomb_planted", Objective2)
		HookEventEx("bomb_defused", Defense2)
		HookEventEx("hostage_rescued", Objective2)
	}
	if (StrEqual(GameFolder, "tf", false))
	{
		HookEventEx("teamplay_point_captured", Objective1)
		HookEventEx("teamplay_capture_blocked", Defense1)
	}
}

public OnMapStart()
{
	for (new i=0; inc < 40; ++inc)
	{
		InitializeVars(i)
	}
}

public Action:Objective1(Handle:event, const String:name[], bool:dontBroadcast)
{
	GetEventString(event, "cappers", cappers, 16)
	for (new i=0; cappers[i] > 0; ++i)
	{
		++Objectives[cappers[i]-1]
		cappers[i] = 0
	}
}

public Action:Defense1(Handle:event, const String:name[], bool:dontBroadcast)
{
	user = GetClientOfUserId(GetEventInt(event, "blocker"))-1
	if (user > 0) ++Defenses[user]
}

public Action:Defense2(Handle:event, const String:name[], bool:dontBroadcast)
{
	++Defenses[GetClientOfUserId(GetEventInt(event, "userid"))-1]
}

public Action:Objective2(Handle:event, const String:name[], bool:dontBroadcast)
{
	++Objectives[GetClientOfUserId(GetEventInt(event, "userid"))-1]
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	SpawnTime[GetClientOfUserId(GetEventInt(event, "userid"))-1] = GetEngineTime()
}

public Action:FireWeapon1(Handle:event, const String:name[], bool:dontBroadcast)
{
	++RoundsFired[GetClientOfUserId(GetEventInt(event, "attacker"))-1]
}

public Action:FireWeapon2(Handle:event, const String:name[], bool:dontBroadcast)
{
	++RoundsFired[GetClientOfUserId(GetEventInt(event, "userid"))-1]
}

public Action:DamageEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	attacker = GetEventInt(event, "attacker")
	user = GetClientOfUserId(GetEventInt(event, "userid"))-1
	if (StrEqual(GameFolder, "cstrike", false)) damage = GetEventInt(event, "dmg_health") + GetEventInt(event, "dmg_armor")
	else if (StrEqual(GameFolder, "tf", false)) damage = GetEventInt(event, "damageamount")
	else if (StrEqual(GameFolder, "dod", false)) damage = GetEventInt(event, "damage")
	if (attacker > 0)
	{
		attacker = GetClientOfUserId(attacker)-1
		if (attacker != user)
		{
			DamageGiven[attacker] += damage
			DamageTaken[user] += damage
			++Hits[attacker]
			++HitsTaken[user]
		}
	}
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	user = GetClientOfUserId(GetEventInt(event, "userid"))-1
	attacker = GetEventInt(event, "attacker")
	kills = KillsRound[user]
	if (user != attacker)
	{
		if (attacker > 0)
		{
			attacker = GetClientOfUserId(attacker)-1
			if (GetConVarBool(Cvar_DEATHSTATS_KS) && KillsRound[attacker] > 1) PrintHintText(attacker+1, "Kill-Streak: %i", KillsRound[attacker])
			++KillsMap[attacker]
			++KillsRound[attacker]
		}
	}
	++Deaths[user]
	++wait[user]
	if (wait[user] == GetConVarInt(Cvar_DEATHSTATS_DISPLAYED))
	{
		DeathTime[user] = GetEngineTime()
		wait[user] = 0
		
		//Display Stats
		DeathStatsMenu = INVALID_HANDLE
		DeathStatsMenu = CreatePanel()
		SetPanelTitle(DeathStatsMenu, "Death Stats")
		DrawPanelItem(DeathStatsMenu, "", ITEMDRAW_SPACER)
		Format(temp, sizeof(temp), "Round Kills: %i", kills)
		DrawPanelText(DeathStatsMenu, temp)
		Format(temp, sizeof(temp), "Dealt %i damage in %i hits", DamageGiven[user], Hits[user])
		DrawPanelText(DeathStatsMenu, temp)
		Format(temp, sizeof(temp), "Took %i damage in %i hits", DamageTaken[user], HitsTaken[user])
		DrawPanelText(DeathStatsMenu, temp)
		if (RoundsFired[user] > 0)
		{
			Format(temp, sizeof(temp), "Hit Ratio: %i/%i = %.3f", Hits[user], RoundsFired[user], float(Hits[user])/RoundsFired[user])
			DrawPanelText(DeathStatsMenu, temp)
		}
		Format(temp, sizeof(temp), "Kill:Death Ratio: %i/%i = %.3f", KillsMap[user], Deaths[user], float(KillsMap[user])/float(Deaths[user]))
		DrawPanelText(DeathStatsMenu, temp)
		Format(temp, sizeof(temp), "Objectives: %i", Objectives[user])
		DrawPanelText(DeathStatsMenu, temp)
		Format(temp, sizeof(temp), "Defenses: %i", Defenses[user])
		DrawPanelText(DeathStatsMenu, temp)
		Secs = RoundToFloor((DeathTime[user]-SpawnTime[user]))%60
		inc = RoundToFloor((DeathTime[user]-SpawnTime[user])/60.0)
		if (inc == 0)
		{
			Format(temp, sizeof(temp), "Lifetime: %i Seconds", Secs)
		} else {
			if (Secs < 10) Format(temp, sizeof(temp), "Lifetime: %i:0%i Mins", inc, Secs)
			else Format(temp, sizeof(temp), "Lifetime: %i:%i Mins", inc, Secs)
		}
		DrawPanelText(DeathStatsMenu, temp)
		DrawPanelItem(DeathStatsMenu, "", ITEMDRAW_SPACER)
		SetPanelCurrentKey(DeathStatsMenu, 10)
		DrawPanelItem(DeathStatsMenu, "Close", ITEMDRAW_CONTROL)
		SendPanelToClient(DeathStatsMenu, user+1, Handle_DeathStats, GetConVarInt(Cvar_DEATHSTATS_TIME))
		
		//Initialize round-specific variables
		KillsRound[user] = 0
		DamageGiven[user] = 0
		DamageTaken[user] = 0
		Hits[user] = 0
		HitsTaken[user] = 0
		RoundsFired[user] = 0
	}
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		InitializeVars(client-1)
	}
}

public Action:InitializeVars(i)
{
	Hits[i]= 0
	HitsTaken[i] = 0
	RoundsFired[i] = 0
	KillsMap[i] = 0
	KillsRound[i] = 0
	Deaths[i] = 0
	DamageGiven[i] = 0
	DamageTaken[i] = 0
	Objectives[i] = 0
	KillsRound[i] = 0
	DamageGiven[i] = 0
	Hits[i] = 0
	wait[i] = 0
}

public Handle_DeathStats(Handle:TeamStatsMenu, MenuAction:action, client, itemNum)
{
}