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
    name            = "[ZP] ExtraItem: infinity Ammo",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Give infinity ammo for any weapons!",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=272546"
}

// Item index
int gItem;
#pragma unused gItem

// Boolean
bool InfinityAmmo[MAXPLAYERS+1];

/**
 * Plugin is loading.
 **/
public void OnPluginStart()
{
    // Hook spawn event
    HookEvent("weapon_fire", OnWeaponFire, EventHookMode_Post);
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Initilizate extra item
    gItem = ZP_GetExtraItemNameID("infammo");
    if(gItem == -1) SetFailState("[ZP] Custom extraitem ID from name : \"infammo\" wasn't find");
}

/**
 * Event callback (weapon_fire)
 * The player is spawning.
 * 
 * @param gEventHook      The event handle.
 * @param gEventName      Name of the event.
 * @dontBroadcast         If true, event is broadcasted to all clients, false if not.
 **/
public Action OnWeaponFire(Event gEventHook, const char[] gEventName, bool iDontBroadcast)
{
    // Gets real player index from event key
    int clientIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid")); 

    // Verify that the client is exist
    if(IsPlayerExist(clientIndex))
    {
        // If the client have infinity ammo
        if(InfinityAmmo[clientIndex])
        {
            // Gets active weapon
            int weaponIndex = GetEntPropEnt(clientIndex, Prop_Send, "m_hActiveWeapon");
    
            // Validate weapon
            if(weaponIndex != INVALID_ENT_REFERENCE)
            {
                // Set new amount of ammo
                int iClip = GetEntProp(weaponIndex, Prop_Send, "m_iClip1")
                if(iClip > -1) SetEntProp(weaponIndex, Prop_Send, "m_iClip1", iClip + 1);
            }
        }
    }
}

/**
 * @brief Called after select an extraitem in the equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param extraitemIndex    The item index.
 **/
public void ZP_OnClientBuyExtraItem(int clientIndex, int extraitemIndex)
{
    // Check the item index
    if(extraitemIndex == gItem)
    { 
        // Set infammo
        InfinityAmmo[clientIndex] = true;
    }
}

//**********************************************
//* OTHER FUNCTIONS                            *
//**********************************************

/**
 * @brief Called once a client is authorized and fully in-game, and 
 *        after all post-connection authorizations have been performed.  
 *
 *        This callback is gauranteed to occur on all clients, and always 
 *        after each OnClientPutInServer() call.
 * 
 * @param clientIndex        The client index. 
 */
public void OnClientPutInServer(int clientIndex)
{
    // Reset ammo
    InfinityAmmo[clientIndex] = false;
}


/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 **/
public void ZP_OnClientUpdated(int clientIndex, int attackerIndex)
{
    // Reset ammo
    InfinityAmmo[clientIndex] = false;
}  