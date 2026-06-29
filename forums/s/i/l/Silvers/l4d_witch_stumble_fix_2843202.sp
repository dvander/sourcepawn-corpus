/*
*	Witch Stumble Bug Fix
*	Copyright (C) 2026 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION		"1.0"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Witch Stumble Bug Fix
*	Author	:	SilverShot
*	Descrp	:	Prevents the Witch from sometimes infinite stumbling when hit by an explosion.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=352393
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.0 (14-Mar-2026)
	- Initial release.

======================================================================================*/

/*
Testing:
1. Commands: 
sm_cvar z_common_limit 0; sm_cvar director_no_specials 1; sm_timescale 0.5; sm_slaycommon; sm_slaywitches; sm_godmode @me; give grenade_launcher

2. Spawn witch next to a Survivor bot: z_spawn witch
3. Wait for Witch to attack and incap bot
4. Just before the Witch attack, shoot Grenade Launcher at Witch feet, or explode Propane Tank to stumble her
5. Watch infinite stumble, unless this plugin is running!
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define SEQ_STUMBLE_L4D1_A	36
#define SEQ_STUMBLE_L4D1_B	43
#define SEQ_STUMBLE_L4D2_A	44
#define SEQ_STUMBLE_L4D2_B	51

bool g_bLeft4Dead2;
int g_iWitches[2048 + 1];
float g_fTiming[2048 + 1];



// ====================================================================================================
//					PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Witch Stumble Bug Fix",
	author = "SilverShot",
	description = "Prevents the Witch from sometimes infinite stumbling when hit by an explosion.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=352393"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_witch_stumble_fix_version", PLUGIN_VERSION, "Witch Stumble Bug Fix plugin version.",	FCVAR_NOTIFY|FCVAR_DONTRECORD);
}



// ====================================================================================================
//					PLUGIN LOGIC
// ====================================================================================================
// Reset vars
public void OnMapStart()
{
	for( int i = 0; i <= 2048; i++ )
	{
		g_iWitches[i] = 0;
		g_fTiming[i] = 0.0;
	}
}

// Monitor for Witch spawn
public void OnEntityCreated(int entity, const char[] classname)
{
	if( strcmp(classname, "witch") == 0 )
	{
		SDKHook(entity, SDKHook_OnTakeDamageAlive, OnTakeDamageWitch);
	}
}

// Monitor for explosion damage
Action OnTakeDamageWitch(int witch, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( damagetype & DMG_BLAST && g_fTiming[witch] < GetGameTime() )
	{
		// Only trigger once per bug, can happen simultaneously in multiple subsequent frames
		g_fTiming[witch] = GetGameTime() + 1.0;

		// Wait until stumble animation has finished
		CreateTimer(2.5, TimerStopWitchStumble, EntIndexToEntRef(witch), TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

Action TimerStopWitchStumble(Handle timer, int witch)
{
	witch = EntRefToEntIndex(witch);

	if( witch != INVALID_ENT_REFERENCE )
	{
		// Validate and verify stumble animation
		int sequence = GetEntProp(witch, Prop_Send, "m_nSequence");
		if(
			(g_bLeft4Dead2 ?
			sequence >= SEQ_STUMBLE_L4D2_A && sequence <= SEQ_STUMBLE_L4D2_B :
			sequence >= SEQ_STUMBLE_L4D1_A && sequence <= SEQ_STUMBLE_L4D1_B) &&
			GetEntProp(witch, Prop_Data, "m_iHealth") > 0 )
		{
			// Get nearest target, probably not required, Witch seems to go for anyone nearest anyway
			int target;
			int victim;
			float dist = 9999.9;
			float range;
			float vPos[3];
			float vEnd[3];

			GetEntPropVector(witch, Prop_Send, "m_vecOrigin", vPos);

			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
				{
					GetClientAbsOrigin(i, vEnd);

					range = GetVectorDistance(vPos, vEnd);

					if( range < dist )
					{
						dist = range;
						victim = i;
					}
				}
			}

			target = victim;

			// Stop stumble and re-assign target
			SDKHooks_TakeDamage(witch, target, target, 1.0, DMG_BURN);

			// Remove flames
			int flame = GetEntPropEnt(witch, Prop_Send, "m_hEffectEntity");
			if( flame != -1 )
				RemoveEntity(flame);

			ExtinguishEntity(witch);

			// Reset vars else she burns after killing
			SetEntPropEnt(witch, Prop_Send, "m_hEffectEntity", -1);
			SetEntProp(witch, Prop_Send, "m_bIsBurning", 0);
		}
	}

	return Plugin_Continue;
}