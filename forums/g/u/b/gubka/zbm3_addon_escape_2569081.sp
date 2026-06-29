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
public Plugin EscapeMod =
{
	name        	= "[ZP] Addon: Escape",
	author      	= "qubka (Nikita Ushakov)", 	
	description 	= "Addon for respawning zombies on respawn point",
	version     	= "1.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=272546"
}

/**
 * Index of infection by server.
 **/
#define SERVER	0

// Map name char
char mapName[SMALL_LINE_LENGTH];

// Array to store spawn origin
float gOrigin[MAXPLAYERS+1][3];

/**
 * Plugin is loading.
 **/
public void OnPluginStart(/*void*/)
{
	// Hook spawn event
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
}

/**
 * Map is loaded.
 **/
public void OnMapStart(/*void*/)
{
	// Get current map name
	GetCurrentMap(mapName, sizeof(mapName));
}

/**
 * Event callback (player_spawn)
 * The player is spawning.
 * 
 * @param gEventHook      	The event handle.
 * @param gEventName        The name of the event.
 * @dontBroadcast   	    If true, event is broadcasted to all clients, false if not.
 **/
public Action EventPlayerSpawn(Event gEventHook, const char[] gEventName, bool dontBroadcast)
{
	// Get real player index from event key
	int clientIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid")); 

	#pragma unused clientIndex
	
	// Validate client
	if(!IsPlayerExist(clientIndex))
	{
		return;
	}
	
	// Get client's position
	GetClientAbsOrigin(clientIndex, gOrigin[clientIndex]);
}

/**
 * Called when a client became a zombie.
 * 
 * @param clientIndex       The client to infect.
 * @param attackerIndex	  	The attacker index.
 */
public void ZP_OnClientInfected(int clientIndex, int attackerIndex)
{
	#pragma unused clientIndex, attackerIndex
	
	/*
	 * If infector index is zero, so infection was made by server
	 */
	
	// Get map name and compare, for escape map supporting
	if(StrContains(mapName, "ze_") != -1)
	{
		// Validate client
		if(!IsPlayerExist(clientIndex))
		{
			return;
		}
		
		// Teleport player back on the previus spawn point
		if(attackerIndex == SERVER) TeleportEntity(clientIndex, gOrigin[clientIndex], NULL_VECTOR, NULL_VECTOR);
	}
}