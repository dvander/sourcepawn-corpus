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
 * @section Information about extra items.
 **/
#define EXTRA_ITEM_NAME               	"Infinity Ammo" 
#define EXTRA_ITEM_COST              	15
#define EXTRA_ITEM_LEVEL           	 	0
#define EXTRA_ITEM_ONLINE            	0
#define EXTRA_ITEM_LIMIT            	0
/**
 * @endsection
 **/
 
/**
 * Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] ExtraItem: infinity Ammo",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Give unlimited ammo",
    version         = "1.2",
    url             = "https://forums.alliedmods.net/showthread.php?t=272546"
}

// Item index
int iItem;

// Boolean
bool InfinityAmmo[MAXPLAYERS+1] = false;

/**
 * Array to store cvar data in.
 **/
ConVar gAmmoType;
ConVar gAmmoTime;

/**
 * Plugin is loading.
 **/
public void OnPluginStart()
{
	// Initilizate extra item
	iItem = ZP_RegisterExtraItem(EXTRA_ITEM_NAME, EXTRA_ITEM_COST, TEAM_HUMAN, EXTRA_ITEM_LEVEL, EXTRA_ITEM_ONLINE, EXTRA_ITEM_LIMIT);

	// Hook spawn event
	HookEvent("weapon_fire",  EventWeaponFire,  EventHookMode_Pre);
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);

	// Load cvars
	gAmmoType 		= CreateConVar("zp_ammo_type", 		 	"0", 		"The type of buying ['0' = one round] ['1' = until become zombie] ['2' = timer]");
	gAmmoTime 		= CreateConVar("zp_ammo_time",  		"20.0", 	"Time of having infinity ammo, if type is timer");

	// Create config
	AutoExecConfig(true, "zp_infammo");
}

/**
 * Event callback (player_spawn)
 * Client is spawning into the game.
 * 
 * @param gEventHook       The event handle.
 * @param gEventName       Name of the event.
 * @param iDontBroadcast   If true, event is broadcasted to all clients, false if not.
 **/
public Action EventPlayerSpawn(Event gEventHook, const char[] gEventName, bool iDontBroadcast) 
{
	// Get all required event info
	int clientIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid"));
	
	// Verify that the client is connected and alive
	if(IsPlayerExist(clientIndex))
	{
		// Reset ammo
		if(!GetConVarInt(gAmmoType)) InfinityAmmo[clientIndex] = false;
	}
}

/**
 * Event callback (weapon_fire)
 * The player is spawning.
 * 
 * @param gEventHook      The event handle.
 * @param gEventName      Name of the event.
 * @dontBroadcast         If true, event is broadcasted to all clients, false if not.
 **/
public Action EventWeaponFire(Event gEventHook, const char[] gEventName, bool iDontBroadcast)
{
    // Get real player index from event key
    int clientIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid")); 

    // Verify that the client is exist
    if(IsPlayerExist(clientIndex))
    {
        // If the client have infinity ammo
        if(InfinityAmmo[clientIndex])
        {
            // Get active weapon
            int weaponIndex = GetEntPropEnt(clientIndex, Prop_Data, "m_hActiveWeapon");
    
            // If weapon exist
            if(IsValidEdict(weaponIndex))
            {
                // Set new amount of ammo
				SetEntProp(weaponIndex, Prop_Data, "m_iClip1", GetEntProp(weaponIndex, Prop_Data, "m_iClip1") + 1);
            }
        }
    }
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
	// Verify that the client is connected and alive
	if(!IsPlayerExist(clientIndex))
	{
		return Plugin_Handled;
	}

	// Check our item index
	if(extraitemIndex == iItem)
	{
		// Return ammopacks
		if(ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerSurvivor(clientIndex))
		{
			return Plugin_Handled;
		}

		// Set ammo
		InfinityAmmo[clientIndex] = true;

		// Reset ammo
		if(GetConVarInt(gAmmoType) == 2)
		{
			CreateTimer(GetConVarFloat(gAmmoTime), EventRemoveAmmo, clientIndex, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	// Allow buying
	return Plugin_Continue;
}

/**
 * Timer which remove dropped weapon, from a ground.
 *
 * @param hTimer     	 The timer handle.
 * @param clientIndex	 The index of the client.
 **/
public Action EventRemoveAmmo(Handle hTimer, any clientIndex)
{
	// Verify that the client is exist
	if(!IsPlayerExist(clientIndex))
	{
		return Plugin_Stop;
	}

	// If player have it, reset ammo
	InfinityAmmo[clientIndex] = false;

	// Destroy timer
	return Plugin_Stop;
}


//**********************************************
//* OTHER FUNCTIONS                            *
//**********************************************

/**
 * Called once a client is authorized and fully in-game, and 
 * after all post-connection authorizations have been performed.  
 *
 * This callback is gauranteed to occur on all clients, and always 
 * after each OnClientPutInServer() call.
 * 
 * @param clientIndex        The client index. 
 */
public void OnClientPutInServer(int clientIndex)
{
    // Reset ammo
    InfinityAmmo[clientIndex] = false;
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
    // Reset ammo
    InfinityAmmo[clientIndex] = false;
}  