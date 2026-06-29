/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *
 *  Copyright (C) 2015 Nikita Ushakov (Ireland, Dublin)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin myinfo =
{
	name        	= "[ZP] Addon: Escape",
	author      	= "qubka (Nikita Ushakov)", 	
	description 	= "",
	version     	= "1.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=272546"
}

// MapName
char sMapName[32];

// Array to store spawn origin
float SpawnOrigin[MAXPLAYERS+1][3];

/**
 * Plugin is loading.
 **/
public void OnPluginStart()
{
	// Hook spawn event
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}

/**
 * Map is loaded.
 **/
public void OnMapStart()
{
	// Get current map name
	GetCurrentMap(sMapName, sizeof(sMapName));
}

/**
 * Event callback (player_spawn)
 * The player is spawning.
 * 
 * @param gEventHook      The event handle.
 * @param gEventName      Name of the event.
 * @dontBroadcast   	  If true, event is broadcasted to all clients, false if not.
 **/
public Action OnPlayerSpawn(Event gEventHook, const char[] gEventName, bool iDontBroadcast)
{
	// Get real player index from event key
	int clientIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid")); 

	// Verify that the client is exist
	if(IsPlayerExist(clientIndex))
	{
		// Get player origin
		GetClientAbsOrigin(clientIndex, SpawnOrigin[clientIndex]);
	}
}

/**
 * Called when a client became a zombie.
 * 
 * @param clientIndex       The client to infect.
 * @param infectorIndex     The attacker who did the infect.
 *
 */
public void ZP_OnClientInfected(int clientIndex, int infectorIndex)
{
	// Get map name and compare, for escape map supporting
	if(StrContains(sMapName, "ze_") != -1 && !infectorIndex)
	{
		TeleportEntity(clientIndex, SpawnOrigin[clientIndex], NULL_VECTOR, NULL_VECTOR);
	}
}