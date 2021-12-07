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
public Plugin Freeze =
{
	name        	= "[ZP] ExtraItem: Freeze deagle",
	author      	= "Emialcaraz", 	
	description 	= "Addon of extra items",
	version     	= "0.1",
	url         	= ""
}

/**
 * @section Information about extra items.
 **/
#define EXTRA_ITEM_NAME				"Deagle freeze" // If string has @, phrase will be taken from translation file		
#define EXTRA_ITEM_COST				500
#define EXTRA_ITEM_LEVEL			0
#define EXTRA_ITEM_ONLINE			0
#define EXTRA_ITEM_LIMIT			3

#define FREEZE_TIME	0.5

// Initialize timer handle
Handle Task_ZombieFreezed[MAXPLAYERS+1] = INVALID_HANDLE;

// Item index
int iItem;
#pragma unused iItem

/**
 * Plugin is loading.
 **/
 
public void OnPluginStart(/*void*/)
{
	// Initilizate extra item
	iItem = ZP_RegisterExtraItem(EXTRA_ITEM_NAME, EXTRA_ITEM_COST, ZP_TEAM_HUMAN, EXTRA_ITEM_LEVEL, EXTRA_ITEM_ONLINE, EXTRA_ITEM_LIMIT);
	
	// Load cvars

	// Hook player events
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
	
	// Hook entity events
	
	// Create config

}

/**
 * The map is starting.
 **/
 
public void OnMapStart(/*void*/)
{
	// Sounds
	FakePrecacheSound("zbm3/impalehit.mp3");
}

/**
 * Called when a client is disconnected from the server.
 *
 * @param clientIndex		The client index.
 **/
 
public void OnClientDisconnect_Post(int clientIndex)
{
	#pragma unused clientIndex
	
	// Delete timer
	EndTimer(Task_ZombieFreezed[clientIndex]);
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
	EndTimer(Task_ZombieFreezed[clientIndex]);
}


 
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
	EndTimer(Task_ZombieFreezed[clientIndex]);
}


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
	EndTimer(Task_ZombieFreezed[clientIndex]);
}


public Action ZP_OnExtraBuyCommand(int clientIndex, int extraitemIndex)
{
	#pragma unused clientIndex, extraitemIndex
	
	// Validate client
	if(!IsPlayerExist(clientIndex))
	{
		return Plugin_Handled;
	}
	
	// Check the item's index
	if(extraitemIndex == iItem)
	{
		// If you don't allowed to buy, then return ammopacks
		if(IsPlayerHasWeapon(clientIndex, "weapon_deagle") || ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerSurvivor(clientIndex))
		{
			return Plugin_Handled;
		}
			
		// Give item and select it
		GivePlayerItem(clientIndex, "weapon_deagle");
		FakeClientCommandEx(clientIndex, "use weapon_deagle");
	}
	
	// Allow buying
	return Plugin_Continue;
}

public void ZP_OnClientDamaged(int victimIndex, int attackerIndex)
{
	char weaponName[64];
	GetClientWeapon(attackerIndex, weaponName, sizeof(weaponName));
	
	// Freeze victim, if attacker has a knife
	
	if(StrEqual(weaponName, "weapon_deagle"))
	{
	if(IsPlayerExist(victimIndex)) FreezeSet(victimIndex);
	}
}


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
	EndTimer(Task_ZombieFreezed[clientIndex]);
	Task_ZombieFreezed[clientIndex] = CreateTimer(FREEZE_TIME, FreezeRemove, clientIndex);
}


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


void SetupSparksFunction(float flOrigin[3], int magniTude, int trailLength)
{
	TE_SetupSparks(flOrigin, NULL_VECTOR, magniTude, trailLength);
	TE_SendToAll();
}