/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *
 *  Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin)
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
public Plugin InfGrenade =
{
	name        	= "[ZP] ExtraItem: InfGrenade",
	author      	= "qubka (Nikita Ushakov)", 	
	description 	= "Addon of extra items",
	version     	= "2.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about extra items.
 **/
#define EXTRA_ITEM_NAME				"InfGrenade" // If string has @, phrase will be taken from translation file		
#define EXTRA_ITEM_COST				16
#define EXTRA_ITEM_LEVEL			0
#define EXTRA_ITEM_ONLINE			0
#define EXTRA_ITEM_LIMIT			0
/**
 * @endsection
 **/

// Item index
int iItem;


/**
 * Plugin is loading.
 **/
public void OnPluginStart(/*void*/)
{
	// Initilizate extra item
	iItem = ZP_RegisterExtraItem(EXTRA_ITEM_NAME, EXTRA_ITEM_COST, TEAM_ZOMBIE, EXTRA_ITEM_LEVEL, EXTRA_ITEM_ONLINE, EXTRA_ITEM_LIMIT);

	// Hook entity events
	HookEvent("decoy_firing", EventEntityDecoy, EventHookMode_Post);
}

/**
 * Called after select an extraitem in equipment menu.
 * 
 * @param clientIndex		The client index.
 * @param extraitemIndex	The index of extraitem from ZP_RegisterExtraItem() native.
 *
 * @return					Plugin_Handled or Plugin_Stop to block purhase. Anything else
 *                          	(like Plugin_Continue) to allow purhase and taking ammopacks.
 **/
public Action ZP_OnClientBuyExtraItem(int clientIndex, int extraitemIndex)
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
		if(IsPlayerHasWeapon(clientIndex, "weapon_decoy") || ZP_IsPlayerHuman(clientIndex) || ZP_IsPlayerSurvivor(clientIndex) || ZP_IsPlayerNemesis(clientIndex))
		{
			return Plugin_Handled;
		}
			
		// Give item and select it
		GivePlayerItem(clientIndex, "weapon_decoy");
		FakeClientCommandEx(clientIndex, "use weapon_decoy");
	}
	
	// Allow buying
	return Plugin_Continue;
}

/**
 * Event callback (decoy_firing)
 * The decoy nade is fired.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast    	If true, event is broadcasted to all clients, false if not.
 **/
public Action EventEntityDecoy(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
{
	// Initialize vector variables
	float flOrigin[3];

	// Get all required event info
	int nEntity = GetEventInt(gEventHook, "entityid");
	flOrigin[0] = GetEventFloat(gEventHook, "x"); 
	flOrigin[1] = GetEventFloat(gEventHook, "y"); 
	flOrigin[2] = GetEventFloat(gEventHook, "z");

	#pragma unused nEntity
	
	// If entity isn't valid, then stop
	if(!IsValidEdict(nEntity))
	{
		return;
	}

	// Get owner
	int clientIndex = GetEntPropEnt(nEntity, Prop_Data, "m_hOwnerEntity");  
	
	// Forward event to modules
	if(ZP_IsPlayerZombie(clientIndex)) GrenadeOnDecoyDetonate(nEntity, flOrigin);
}

/**
 * The decoy nade is fired.
 * 
 * @param nEntity			The entity index.  
 * @param flOrigin			The explosion origin.
 **/
void GrenadeOnDecoyDetonate(int nEntity, float flOrigin[3])
{
	#pragma unused nEntity
	
	// Initialize vector variables
	float flVictimOrigin[3];
	
	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Validate client
		if (IsPlayerExist(i))
		{
			// Get victim's position
			GetClientAbsOrigin(i, flVictimOrigin);
			
			// Initialize distance variable
			float flDistance = GetVectorDistance(flOrigin, flVictimOrigin);
			
			// If distance to the entity is less than the radius of explosion
			if (flDistance <= 200.0)
			{				
				// Infect entity
				if(ZP_IsPlayerHuman(i)) ZP_SwitchClientClass(i, TYPE_ZOMBIE);
			}
		}
	}

	// Create sparks splash effect
	SetupSparksFunction(flOrigin, 5000, 1000);

	// Remove grenade
	RemoveEdict(nEntity);
}

/**
 * Create sparks splash effect.
 *
 * @param flOrigin			The position of the effect.
 * @param magniTude			The sparks's size.
 * @param trailLength		The trail length of the sparks.
 **/
void SetupSparksFunction(float flOrigin[3], int magniTude, int trailLength)
{
	TE_SetupSparks(flOrigin, NULL_VECTOR, magniTude, trailLength);
	TE_SendToAll();
}