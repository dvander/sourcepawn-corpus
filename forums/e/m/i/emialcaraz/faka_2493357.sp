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
//bool to check if zombie kill the human in the 3 seconds

bool g_ZombieExplode[MAXPLAYERS+1] = false;
/**
 * Record plugin info.
 **/
 
public Plugin FreezeKnife =
{
	name        	= "[ZP] Addon: Knife explote",
	author      	= "emialcaraz", 	
	description 	= "Make that humans can kill zombies with knife.",
	version     	= "1.0",
	url         	= "www.alcarazweb.com"
}

 enum ConVarList
{
    ConVar:CVAR_FAKA,
};
 
 //Time that the zombie need to kill the human.
 
#define FREEZE_TIME		3.0

ConVar gCvarList[ConVarList];
// Initialize timer handle

Handle Task_ZombieFreezed[MAXPLAYERS+1] = INVALID_HANDLE;

 public void OnPluginStart(/*void*/)
 {
 	
	gCvarList[CVAR_FAKA] 		= CreateConVar("zp_faka", 		 "15000.0", 		"The damage to deal to a zombie");
}
public void OnClientDisconnect_Post(int clientIndex)
{
	#pragma unused clientIndex
	
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

/**
 * Called when a client take a fake damage.
 * 
 * @param victimIndex		The client index.
 * @param attackerIndex		The attacker index.
 **/
 
public void ZP_OnClientDamaged(int victimIndex, int attackerIndex)
{
	// Validate attacker
	if(!IsPlayerExist(attackerIndex))
	{
		return;
	}
	
	// Verify that the attacker is a survivor
	if(!ZP_IsPlayerHuman(attackerIndex))
	{
		return;
	}
	
	// Get weapon name
	char weaponName[SMALL_LINE_LENGTH];
	GetClientWeapon(attackerIndex, weaponName, sizeof(weaponName));
	
	// set kill knife victim, if attacker has a knife
	if(StrEqual(weaponName, "weapon_knife"))
	{
		if(IsPlayerExist(victimIndex))
		{
			//start the game
		if(!ZP_IsPlayerZombie(victimIndex) || ZP_IsPlayerNemesis(victimIndex))
			{
		return;
			}	
			//start the human infection to zombie
			SetEntityRenderMode(victimIndex, RENDER_TRANSCOLOR);
			SetEntityRenderColor(victimIndex, 255, 120, 120, 120);
			PrintToChat(victimIndex, "\x04[ZOMBIE PLAGUE FORDWARD]\x03 Tienes 3 segundos para infectar a alguien o moriras!");
			g_ZombieExplode[victimIndex] = true;
			// Create timer for removing.
			EndTimer(Task_ZombieFreezed[victimIndex]);
			Task_ZombieFreezed[victimIndex] = CreateTimer(FREEZE_TIME, FreezeRemove, victimIndex);
			PrintToChat(attackerIndex, "\x04[ZOMBIE PLAGUE FORDWARD]\x03has fakeado un zombie y morira!");
			}
			//finish
		} 
			
	}
	
public void ZP_OnClientInfected(int clientIndex, int attackerIndex)
{
	#pragma unused clientIndex, attackerIndex
	
	// Delete timer
	EndTimer(Task_ZombieFreezed[attackerIndex]);
	
	if(g_ZombieExplode[attackerIndex])
	{
                        g_ZombieExplode[attackerIndex] = false;
                        PrintToChat(attackerIndex, "\x04[ZOMBIE PLAGUE FORDWARD]\x03 has infectado un humano y te salvaste!");
                        SetEntityRenderMode(attackerIndex, RENDER_TRANSCOLOR);
						SetEntityRenderColor(attackerIndex, 255, 255, 255, 255);
	}
	
}

public Action FreezeRemove(Handle hTimer, any clientIndex)
{
	#pragma unused clientIndex
	int attackerIndex
	
	// Clear timer 
	Task_ZombieFreezed[clientIndex] = INVALID_HANDLE;
	// Validate client
	
	if(!IsPlayerExist(clientIndex))
	{
		return Plugin_Stop;
	}
	// check if the victim infect the human.
	if(g_ZombieExplode[attackerIndex] = true)
	{
	SDKHooks_TakeDamage(clientIndex, attackerIndex, attackerIndex, GetConVarFloat(gCvarList[CVAR_FAKA]), DMG_BURN);
	PrintToChat(clientIndex, "\x04[ZOMBIE PLAGUE FORDWARD]\x03 has muerto por que un humano te ha fakeado");
	}
	
	// Set standart render color
	SetEntityRenderMode(clientIndex, RENDER_TRANSCOLOR);
	SetEntityRenderColor(clientIndex, 255, 255, 255, 255);
	
	// Destroy timer
	return Plugin_Stop;
}