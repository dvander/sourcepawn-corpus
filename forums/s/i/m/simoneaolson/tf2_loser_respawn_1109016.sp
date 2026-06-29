/*
 *
 * =============================================================================
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY without even the implied warranty of MERCHANTABILITY or FITNESS
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
#include <tf2_stocks>
#define PLUGIN_VERSION "1.0"
new Handle:Cvar_TF2_LR_ENABLED
new bool:LoserRespawn


public Plugin:myinfo = 
{

	name = "Team Fortress 2 Loser Respawn",
	author = "simoneaolson",
	description = "fun plugin for the losing team to respawn until the next round",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
	
}


public OnPluginStart()
{

	CreateConVar("tf2_lr_version", PLUGIN_VERSION, "Current plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
	Cvar_TF2_LR_ENABLED = CreateConVar("tf2_lr_enabled", "1", "Enabled/Disable TF2 Loser respawn (bool)", _, true, 0.0, true, 1.0)
	if (GetConVarBool(Cvar_TF2_LR_ENABLED))
	{
		HookEventEx("teamplay_overtime_end", RoundEnd, EventHookMode_Post)
		HookEventEx("teamplay_suddendeath_begin", RoundEnd, EventHookMode_Post)
		HookEventEx("teamplay_round_start", RoundStart, EventHookMode_Post)
		HookEventEx("player_death", PlayerDeath, EventHookMode_Post)
	}
	LoserRespawn = false
	
}


public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	LoserRespawn = false
	
}


public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	LoserRespawn = true
	
}


public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{

	if (LoserRespawn) CreateTimer(0.8, RespawnClient, GetClientOfUserId(GetEventInt(event, "userid")))

}

public Action:RespawnClient(Handle:timer, any:client)
{
	
	TF2_RespawnPlayer(client)
	
}