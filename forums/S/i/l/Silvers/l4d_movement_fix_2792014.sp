/*
*	Movement Speed Fix
*	Copyright (C) 2022 Silvers
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



#define PLUGIN_VERSION		"1.1"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Movement Speed Fix
*	Author	:	SilverShot
*	Descrp	:	Fix slowed movement or bad jumping height when the m_flLaggedMovementValue netprop is changed.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=334240
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.1 (06-Nov-2022)
	- Added falling detection to fix fall speed. Thanks to "Eärendil" for reporting.

1.1 (02-Nov-2022)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>


float g_fSpeed[MAXPLAYERS+1];
bool g_bWorking[MAXPLAYERS+1];



// ====================================================================================================
//					PLUGIN START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Movement Speed Fix",
	author = "SilverShot",
	description = "Fix slowed movement or bad jumping height when the m_flLaggedMovementValue netprop is changed.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=334240"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	RegPluginLibrary("movement_fix");

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_movement_fix_version", PLUGIN_VERSION, "Movement Speed Fix plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	HookEvent("player_jump_apex", Event_PlayerJump);
	HookEvent("player_jump", Event_PlayerJump);
	HookEvent("round_end", Event_RoundEnd);
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
void ResetVars()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( g_bWorking[i] )
		{
			if( IsClientInGame(i) )
			{
				SDKUnhook(i, SDKHook_PostThink, OnThink);
			}

			g_bWorking[i] = false;
		}
	}
}

public void OnClientDisconnect(int client)
{
	g_bWorking[client] = false;
}

public void OnMapEnd()
{
	ResetVars();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetVars();
}

void Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	FixStuff(client);
}

public void L4D2_OnStagger_Post(int target, int source)
{
	FixStuff(target);
}

public void L4D2_OnPlayerFling_Post(int client, int attacker, const float vecDir[3])
{
	FixStuff(client);
}



// ====================================================================================================
//					FIX
// ====================================================================================================
void FixStuff(int client)
{
	if( !g_bWorking[client] )
	{
		g_bWorking[client] = true;
		g_fSpeed[client] = GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");

		SDKHook(client, SDKHook_PostThink, OnThink);
		SDKHook(client, SDKHook_PreThinkPost, OnThink);
		SDKHook(client, SDKHook_PostThinkPost, OnThink);
	}
}

void OnThink(int client)
{
	if( GetEntProp(client, Prop_Send, "m_hGroundEntity") == -1 || GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1) > -1.0 )
	{
		float vVec[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVec);
		float speed = GetVectorLength(vVec);

		SetEntPropFloat(client, Prop_Send, "m_fMaxSpeed", speed);
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
	}
	else
	{
		g_bWorking[client] = false;
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_fSpeed[client]);

		SDKUnhook(client, SDKHook_PostThink, OnThink);
		SDKUnhook(client, SDKHook_PreThinkPost, OnThink);
		SDKUnhook(client, SDKHook_PostThinkPost, OnThink);
	}
}