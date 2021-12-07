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
public Plugin Flare =
{
	name        	= "[ZP] ExtraItem: AWP",
	author      	= "Emk1 alias emialcaraz", 	
	description 	= "awp for zombiesb. If somebody can help with a nice model will be nice.",
	version     	= "1.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about extra items.
 **/
#define EXTRA_ITEM_NAME				"Awp one bullet" // If string has @, phrase will be taken from translation file		 
#define EXTRA_ITEM_COST				100
#define EXTRA_ITEM_LEVEL			0
#define EXTRA_ITEM_ONLINE			0
#define EXTRA_ITEM_LIMIT			1
/**
 * @endsection
 **/
 


int iItem;
#pragma unused iItem
 
public void OnPluginStart(/*void*/)
{
	// Initilizate extra item
	iItem = ZP_RegisterExtraItem(EXTRA_ITEM_NAME, EXTRA_ITEM_COST, TEAM_ZOMBIE, EXTRA_ITEM_LEVEL, EXTRA_ITEM_ONLINE, EXTRA_ITEM_LIMIT);
}


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
		if(IsPlayerHasWeapon(clientIndex, "weapon_awp") || ZP_IsPlayerHuman(clientIndex) || ZP_IsPlayerSurvivor(clientIndex))
		{
			return Plugin_Handled;
		}
		
		// Give item and select it
		ClientCommand(clientIndex,"sm_awp");
	}
	
	// Allow buying
	return Plugin_Continue;
}


stock void SetupDustFunction(float flOrigin[3])
{
	TE_SetupDust(flOrigin, NULL_VECTOR, 10.0, 1.0);
	TE_SendToAll();
}