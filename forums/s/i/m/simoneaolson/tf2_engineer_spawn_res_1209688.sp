/*
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
 */

#include <sourcemod>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.0"

new Handle:Cv_PluginEnabled, Handle:Cv_Time
new bool:alreadySpawned[40], enable
new Float:setupTime

public Plugin:myinfo = 
{

	name = "TF2 Blue Engineer Spawn Restrictions",
	author = "simoneaolson",
	description = "Restricts players on the blue team from spawning as engineer during the first X minutes after setup time",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
	
}


public OnPluginStart()
{

	CreateConVar("tf_engineer_sr_version", PLUGIN_VERSION, "Current plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
	Cv_PluginEnabled = CreateConVar("tf_engineer_sr_enabled", "1", "Enabled/Disable TF2 Engineer restrictions (bool)", _, true, 0.0, true, 1.0)
	Cv_Time = CreateConVar("tf_engineer_sr_time", "1.2", "Minutes after Setup to restrict players on blue from spawning as engineer (float)", _, true, 0.5, true, 5.0)
	
	if (GetConVarBool(Cv_PluginEnabled))
	{
		HookEventEx("player_spawn", PlayerSpawn, EventHookMode_Pre)
		HookEventEx("player_changeclass", PlayerChangeClass, EventHookMode_Pre)
		HookEventEx("teamplay_setup_finished", SetupFinished)
	}
	
}


public OnMapStart()
{

	decl String:map[4]
	GetCurrentMap(map, 4)
	if (StrEqual(map, "plr", false) || StrEqual(map, "pl_", false)) enable = true
	else enable = false
	
	setupTime = 0.0
	
	for (new i = 0; i < 40; ++i)
	{
		alreadySpawned[i] = false
	}

}


public Action:SetupFinished(Handle:event, const String:name[], bool:dontBroadcast)
{

	setupTime = GetEngineTime()

}


public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{

	if (enable)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		
		if (!alreadySpawned[client]) alreadySpawned[client] = true
		
		if (GetClientTeam(client) == 3 && TF2_GetPlayerClass(client) == TFClass_Engineer)
		{
			new Float:time = GetConVarFloat(Cv_Time) * 60.0
			
			if (setupTime == 0.0)
			{
				PrintCenterText(client, "You may not yet play as an Engineer. Please wait...")
				TF2_SetPlayerClass(client, TFClass_Soldier, false, true)
				TF2_RespawnPlayer(client)
			}
			else if (setupTime + time > GetEngineTime())
			{
				PrintCenterText(client, "You may not yet play as an Engineer. Please wait (%.0f) seconds.", time - (GetEngineTime() - setupTime))
				TF2_SetPlayerClass(client, TFClass_Soldier, false, true)
				TF2_RespawnPlayer(client)
			}
		}
	}

}


public Action:PlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{

	if (enable)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		
		if (alreadySpawned[client])
		{
			new TFClassType:preClass = TF2_GetPlayerClass(client)
			new class = GetEventInt(event, "class")
			
			if (GetClientTeam(client) == 3 && class == 9)
			{
				new Float:time = GetConVarFloat(Cv_Time) * 60.0
				
				if (setupTime == 0.0)
				{
					PrintCenterText(client, "You may not yet play as an Engineer. Please wait...")
					TF2_SetPlayerClass(client, preClass, false, true)
					TF2_RespawnPlayer(client)
				}
				else if (setupTime + time > GetEngineTime())
				{
					PrintCenterText(client, "You may not yet play as an Engineer. Please wait (%.0f) seconds.", time - (GetEngineTime() - setupTime))
					TF2_SetPlayerClass(client, preClass, false, true)
					TF2_RespawnPlayer(client)
				}
			}
		}
	}
	
}


public OnClientDisconnect(client)
{

	alreadySpawned[client] = false

}