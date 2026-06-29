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
public Plugin FreezeKnife =
{
	name        	= "[ZP] Addon: Freeze Knife",
	author      	= "qubka (Nikita Ushakov)", 	
	description 	= "Addon for freeze zombie by survivor's knife",
	version     	= "2.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * Time of freezing per slash.
 **/
#define FREEZE_TIME		3.0

// Initialize timer handle
Handle Task_ZombieFreezed[MAXPLAYERS+1] = INVALID_HANDLE;

/**
 * Called when a client is disconnected from the server.
 *
 * @param clientIndex		The client index.
 **/
public void OnClientDisconnect_Post(int clientIndex)
{
	#pragma unused clientIndex
	
	// Delete timer
	delete Task_ZombieFreezed[clientIndex];
}

/**
 * Called when a client became a zombie.
 * 
 * @param clientIndex		The client index.
 * @param attackerIndex		The attacker index.
 **/
public void ZP_OnClientInfected(int clientIndex, int attackerIndex)
{
	#pragma unused clientIndex, attackerIndex
	
	// Delete timer
	delete Task_ZombieFreezed[clientIndex];
}

/**
 * Event callback (player_spawn)
 * Client is spawning into the game.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast    	If true, event is broadcasted to all clients, false if not.
 **/
public Action EventPlayerSpawn(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
{
	// Get all required event info
	int clientIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid"));

	#pragma unused clientIndex
	
	// Validate client
	if (!IsPlayerExist(clientIndex))
	{
		return;
	}
	
	// Delete timer
	delete Task_ZombieFreezed[clientIndex];
}

/**
 * Event callback (player_death)
 * Client has been killed.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast    	If true, event is broadcasted to all clients, false if not.
 **/
public Action EventPlayerDeath(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
{
	// Get all required event info
	int clientIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid"));
	
	#pragma unused clientIndex
	
	// Validate client
	if (!IsPlayerExist(clientIndex, false))
	{
		// If the client isn't a player, a player really didn't die now. Some
		// other mods might sent this event with bad data.
		return;
	}

	// Delete timer
	delete Task_ZombieFreezed[clientIndex];
}

/**
 * Called when a client take a fake damage.
 * 
 * @param clientIndex		The client index.
 * @param attackerIndex		The attacker index.
 * @param damageAmount		The amount of damage inflicted.
 **/
public void ZP_OnClientDamaged(int clientIndex, int attackerIndex, float &damageAmount)
{
	// Validate attacker
	if(!IsPlayerExist(attackerIndex))
	{
		return;
	}
	
	// Verify that the attacker is a survivor
	if(!ZP_IsPlayerSurvivor(attackerIndex))
	{
		return;
	}
	
	// Get weapon name
	char weaponName[SMALL_LINE_LENGTH];
	GetClientWeapon(attackerIndex, weaponName, sizeof(weaponName));
	
	// Freeze victim, if attacker has a knife
	if(StrEqual(weaponName, "weapon_knife"))
	{
		if(IsPlayerExist(clientIndex)) FreezeSet(clientIndex);
	}
}

/**
 * Player is about to freeze.
 *
 * @param clientIndex		The client index.
 **/
void FreezeSet(int clientIndex)
{
	#pragma unused clientIndex
	
	// Verify that the client is a zombie
	if(!ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerNemesis(clientIndex))
	{
		return;
	}

	// Freeze client
	SetEntityMoveType(clientIndex, MOVETYPE_NONE);

	// Set blue render color
	SetEntityRenderMode(clientIndex, RENDER_TRANSCOLOR);
	SetEntityRenderColor(clientIndex, 120, 120, 255, 255);

	// Create timer for removing freezing
	delete Task_ZombieFreezed[clientIndex];
	Task_ZombieFreezed[clientIndex] = CreateTimer(FREEZE_TIME, FreezeRemove, clientIndex);
}

/**
 * Timer for remove freeze.
 *
 * @param hTimer			The timer handle.
 * @param clientIndex		The client index.
 **/
public Action FreezeRemove(Handle hTimer, any clientIndex)
{
	#pragma unused clientIndex
	
	// Clear timer 
	Task_ZombieFreezed[clientIndex] = INVALID_HANDLE;

	// Validate client
	if(!IsPlayerExist(clientIndex))
	{
		return Plugin_Stop;
	}

	// Unfreeze client
	SetEntityMoveType(clientIndex, MOVETYPE_WALK);

	// Set standart render color
	SetEntityRenderMode(clientIndex, RENDER_TRANSCOLOR);
	SetEntityRenderColor(clientIndex, 255, 255, 255, 255);
	
	// Destroy timer
	return Plugin_Stop;
}