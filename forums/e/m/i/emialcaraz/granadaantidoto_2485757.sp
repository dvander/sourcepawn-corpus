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
public Plugin HeGrenade =
{
    name            = "[ZP] ExtraItem: Hegrenade",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Addon of extra items",
    version         = "2.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about extra items.
 **/
#define EXTRA_ITEM_NAME                "Antidote Grenade" // If string has @, phrase will be taken from translation file         
#define EXTRA_ITEM_COST                30
#define EXTRA_ITEM_LEVEL            0
#define EXTRA_ITEM_ONLINE            0
#define EXTRA_ITEM_LIMIT            0
/**
 * @endsection
 **/

/**
 * List of cvars.
 **/
enum ConVarList
{
    ConVar:CVAR_GRENADE_EXP_RADIUS,
    ConVar:CVAR_GRENADE_EXP_KNOCKBACK
};

/**
 * Array to store cvar data in.
 **/
ConVar gCvarList[ConVarList];
 
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
    gCvarList[CVAR_GRENADE_EXP_RADIUS]          = CreateConVar("zp_grenade_exp_radius",       "300.0",            "Explosion knockback radius"); 
    gCvarList[CVAR_GRENADE_EXP_KNOCKBACK]       = CreateConVar("zp_grenade_exp_knockback",   "500.0",             "Explosion knockback forse"); 
    
    // Hook entity events
    HookEvent("tagrenade_detonate", EventEntityExplosion, EventHookMode_Post);
    
    // Create config
    AutoExecConfig(true, "zombieplague_napalm");
}

/**
 * Called after select an extraitem in the equipment menu.
 * 
 * @param clientIndex        The client index.
 * @param extraitemIndex    The index of extraitem from ZP_RegisterExtraItem() native.
 *
 * @return                    Plugin_Handled or Plugin_Stop to block purhase. Anything else
 *                              (like Plugin_Continue) to allow purhase and taking ammopacks.
 **/
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
        if(fnGetZombies() <= 1 || IsPlayerHasWeapon(clientIndex, "weapon_tagrenade") || ZP_GetRoundState(STATE_ROUND_MODE) == MODE_NEMESIS || ZP_GetRoundState(STATE_ROUND_MODE) == MODE_SURVIVOR || ZP_GetRoundState(STATE_ROUND_MODE) == MODE_ARMAGEDDON || ZP_IsPlayerZombie(clientIndex))
        {
            return Plugin_Handled;
        }
            
        // Give item and select it
        GivePlayerItem(clientIndex, "weapon_tagrenade");
        FakeClientCommandEx(clientIndex, "use weapon_tagrenade");
    }
    
    // Allow buying
    return Plugin_Continue;
    
}


/**
 * Event callback (hegrenade_detonate)
 * The hegrenade is exployed.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast        If true, event is broadcasted to all clients, false if not.
 **/
public Action EventEntityExplosion(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
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

    // Forward event to modules
    GrenadeOnTaDetonate(nEntity, flOrigin);
}

/**
 * The hegrenade nade is exployed.
 * 
 * @param nEntity            The entity index.  
 * @param flOrigin            The explosion origin.
 **/
 
void GrenadeOnTaDetonate(int nEntity, float flOrigin[3])
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
            flVictimOrigin[2] += 2.0;
            
            // Initialize distance variable
            float flDistance = GetVectorDistance(flOrigin, flVictimOrigin);
            
            // If distance to the entity is less than the radius of explosion
            if (flDistance <= GetConVarFloat(gCvarList[CVAR_GRENADE_EXP_RADIUS]))
            {
                if(fnGetZombies() <= 1 || ZP_IsPlayerHuman(i))
                    {
                    }
                    else
                    {
                    // Push entity
                    GrenadeOnEntityExploade(i, flOrigin, flVictimOrigin, flDistance);
                    ZP_SwitchClass(TYPE_HUMAN, i);
                    }
            }
        }
    }
}

/**
 * Player is about to push back.
 *
 * @param clientIndex        The client index.
 * @param flOrigin            The explosion origin.
 * @param flVictimOrigin    The client origin.
 * @param flDistance        The distance bettween points.
 **/
void GrenadeOnEntityExploade(int clientIndex, float flOrigin[3], float flVictimOrigin[3], float flDistance)
{
    #pragma unused clientIndex
    
    // Verify that the client is a zombie
    if(!ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerNemesis(clientIndex))
    {
        return;
    }

    // Initialize velocity vector
    float flVelocity[3];
    
    // Get knockpback power
    float flKnockBack = GetConVarFloat(gCvarList[CVAR_GRENADE_EXP_KNOCKBACK]) * (1.0 - (flDistance / GetConVarFloat(gCvarList[CVAR_GRENADE_EXP_RADIUS])));

    // Calculate velocity
    flVelocity[0] = flVictimOrigin[0] - flOrigin[0];
    flVelocity[1] = flVictimOrigin[1] - flOrigin[1];
    flVelocity[2] = flVictimOrigin[2] - flOrigin[2];
    
    // Calculate push power
    float flPower = SquareRoot(flKnockBack * flKnockBack / (flVelocity[0] * flVelocity[0] + flVelocity[1] * flVelocity[1] + flVelocity[2] * flVelocity[2]));
    flVelocity[0] *= flPower;
    flVelocity[1] *= flPower;
    flVelocity[2] *= flPower * 10.0;

    // Push away
    TeleportEntity(clientIndex, NULL_VECTOR, NULL_VECTOR, flVelocity);
}

int fnGetZombies(/*void*/)
{
    // Initialize vars
    int iZombies, MaxPlayer = MaxClients;
    
    // i = index of the client
    for (int i = 1; i <= MaxPlayer; i++)
    {
        if (IsPlayerExist(i) && ZP_IsPlayerZombie(i))
        {
            iZombies++;
        }
    }
    
    return iZombies;
}  
