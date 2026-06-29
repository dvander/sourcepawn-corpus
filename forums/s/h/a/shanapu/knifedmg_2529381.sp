/*
 * Knife dmg.
 * by: shanapu
 * https://github.com/shanapu/
 *
 * This file is part of the MyJailbreak SourceMod Plugin.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */

/******************************************************************************
                   STARTUP
******************************************************************************/

// Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <mystocks>

// Compiler Options
#pragma semicolon 1
#pragma newdecls required

// Console Variables
ConVar gc_bPlugin;
ConVar gc_fMultiply;
ConVar gc_iTeam;


public Plugin myinfo =
{
	name = "KnifeDMG",
	author = "shanapu",
	description = "Multiply knife dmg for a team",
	version = "1.0",
	url = "https://github.com/shanapu"
};

// Start
public void OnPluginStart()
{
	// AutoExecConfig
	gc_bPlugin = CreateConVar("sm_knifedmg", "1", "0 - disabled, 1 - enable knife damage plugin", _, true, 0.0, true, 1.0);
	gc_fMultiply = CreateConVar("sm_knifedmg_multi", "2", "Knife damage multiplyer", _, true, 0.1);
	gc_iTeam = CreateConVar("sm_knifedmg_team", "1", "Which team should get the extra dmg? 1 - CT only / 2- T only / 3 - both", _, true, 1.0, true, 3.0);
	
	AutoExecConfig(true, "KnifeDMG");
}

/******************************************************************************
                   EVENTS
******************************************************************************/


public Action OnTakedamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!gc_bPlugin.BoolValue)
		return Plugin_Continue;

	if (!IsValidClient(victim, true, false) || attacker == victim || !IsValidClient(attacker, true, false)) 
		return Plugin_Continue;

	char sWeapon[32];
	if (IsValidEntity(weapon)) GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));

	if ((GetClientTeam(attacker) == CS_TEAM_CT && gc_iTeam.IntValue == 1) || (GetClientTeam(attacker) == CS_TEAM_T && gc_iTeam.IntValue == 2) || gc_iTeam.IntValue == 3)
	{
		if ((StrEqual(sWeapon, "weapon_knife", false)))
		{
			damage = damage*gc_fMultiply.FloatValue;
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

/******************************************************************************
                   FORWARDS LISTEN
******************************************************************************/

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakedamage);
}