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
#include <zombieplague>

#pragma newdecls required

public Plugin JetPack = 
{
	name		= "JetPack",
	author		= "FrozDark | qubka (Nikita Ushakov)",
	description	= "Addon of extra items",
	version		= "4.0",
	url			= "https://forums.alliedmods.net/showthread.php?t=290657"
};

/**
 * @section Information about extra items.
 **/
#define ZP_ITEM_NAME		"JetPack"		
#define ZP_ITEM_COST		20			
#define ZP_ITEM_LEVEL		0
#define ZP_ITEM_ONLINE		0
#define ZP_ITEM_LIMIT		0
/**
 * @endsection
 **/

// Player arrays
int gJumps[MAXPLAYERS+1];
bool gJetPack[MAXPLAYERS+1];

// Initialize timer handle
Handle Task_JetPackReload[MAXPLAYERS+1] = INVALID_HANDLE; 

// Convars
ConVar ReloadDelay;
ConVar JetPackBoost;
ConVar JetPackMax;

// Item index
int iItem;
#pragma unused iItem

/**
 * Plugin is loading.
 **/
public void OnPluginStart(/*void*/)
{
	// Initilizate extra item
	iItem = ZP_RegisterExtraItem(ZP_ITEM_NAME, ZP_ITEM_COST, TEAM_HUMAN, ZP_ITEM_LEVEL, ZP_ITEM_ONLINE, ZP_ITEM_LIMIT);

	// Hook server events
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
	
	// Initialize cvars
	ReloadDelay = CreateConVar("zp_jetpack_reloadtime", "60", "Time in seconds to reload JetPack.", 0, true, 1.0);
	JetPackBoost = CreateConVar("zp_jetpack_boost", "500.0", "The amount of boost to apply to JetPack.", 0, true, 100.0);
	JetPackMax = CreateConVar("zp_jetpack_max", "10", "Time in seconds of using JetPacks.", 0, true, 0.0);
	
	// Add translation for buying phrase
	LoadTranslations("jetpack.phrases");
	
	// Create config
	AutoExecConfig(true, "jetpack");
}

/**
 * The map is starting.
 **/
public void OnMapStart(/*void*/)
{
	// Sounds
	FakePrecacheSound("zbm3/jetpack/fly.mp3");
}

/**
 * Called once a client successfully connects.
 * 
 * @param clientIndex		The client index.
 **/
public void OnClientConnected(int clientIndex)
{
	#pragma unused clientIndex
	
	// Reset jetpack variables
	JetPackRemove(clientIndex);
}

/**
 * Called when a client is disconnecting from the server.
 * 
 * @param clientIndex		The client index.
 **/
public void OnClientDisconnect(int clientIndex)
{
	#pragma unused clientIndex
	
	// Reset jetpack variables
	JetPackRemove(clientIndex);
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
	
	// Reset jetpack variables
	JetPackRemove(clientIndex);
}

/**
 * Event callback (player_death)
 * The player is about to die.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast    If true, event is broadcasted to all clients, false if not.
 **/
public Action EventPlayerDeath(Event gEventHook, const char[] gEventName, bool dontBroadcast)
{
	// Get all required event info
	int clientIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid"));
	
	// Validate client
	if(!IsPlayerExist(clientIndex, false))
	{
		// If the client isn't a player, a player really didn't die now. Some
		// other mods might sent this event with bad data.
		return;
	}
	
	// Reset jetpack variables
	JetPackRemove(clientIndex);
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
	#pragma unused clientIndex
	
	// Validate client
	if(!IsPlayerExist(clientIndex))
	{
		return Plugin_Handled;
	}
	
	// Check the item's index
	if(extraitemIndex == iItem)
	{
		// If you don't allowed to buy, then return ammopacks
		if(ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerSurvivor(clientIndex) || gJetPack[clientIndex])
		{
			return Plugin_Handled;
		}
		
		// Set jetpack variables
		gJetPack[clientIndex] = true;
		gJumps[clientIndex] = 0;
	
		// Set translation target
		SetGlobalTransTarget(clientIndex);
	}
	
	// Allow buying
	return Plugin_Continue;
}

/**
 * Called when a clients movement buttons are being processed.
 *  
 * @param clientIndex		The client index.
 * @param bitFlags          Copyback buffer containing the current commands (as bitflags - see entity_prop_stocks.inc).
 * @param iImpulse          Copyback buffer containing the current impulse command.
 * @param flVelocity        Players desired velocity.
 * @param flAngles 			Players desired view angles.	
 * @param weaponIndex		Entity index of the new weapon if player switches weapon, 0 otherwise.
 * @param iSubType			Weapon subtype when selected from a menu.
 * @param iCmdNum			Command number. Increments from the first command sent.
 * @param iTickCount		Tick count. A client's prediction based on the server's GetGameTickCount value.
 * @param iSeed				Random seed. Used to determine weapon recoil, spread, and other predicted elements.
 * @param iMouse			Mouse direction (x, y).
 **/ 
public Action OnPlayerRunCmd(int clientIndex, int &bitFlags, int &iImpulse, float flVelocity[3], float flAngles[3], int &weaponIndex, int &iSubType, int &iCmdNum, int &iTickCount, int &iSeed, int iMouse[2])
{
	#pragma unused clientIndex

	// Hook pressed buttons
	if(bitFlags & IN_JUMP && bitFlags & IN_DUCK)
	{
		// Validate client
		if(!IsPlayerExist(clientIndex))
		{
			return Plugin_Continue;
		}
		
		// Verify that the client is human
		if(ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerSurvivor(clientIndex))
		{
			return Plugin_Continue;
		}
		
		// Verify that the client isn't freeze
		if(GetEntityMoveType(clientIndex) == MOVETYPE_NONE)
		{
			return Plugin_Continue;
		}
		
		// If the client has a jetpack
		if(gJetPack[clientIndex]) JetPackActivate(clientIndex);
	}
	
	// Allow usage
	return Plugin_Continue;
}


/*
 * JetPack Effects
 */
 

/**
 *	Create jetpack steam effect.
 *
 * @param clientIndex	 	The client index.
 * @param flOrigin			The vector for origin of entity.
 * @param flAngle			The vector for angle of entity.
 **/
void JetPackCreateEffect(int clientIndex, float flOrigin[3], float flAngle[3])
{
	#pragma unused clientIndex
	
	// Create an effect entities
	int nEntity1 = CreateEntityByName("env_steam");
	int nEntity2 = CreateEntityByName("env_steam");
	
	// If entity aren't valid, then skip
	if(nEntity1 && nEntity2)
	{
		// Initialize chars
		static char sName[SMALL_LINE_LENGTH];
		static char sFireName[SMALL_LINE_LENGTH];
		static char sSteamName[SMALL_LINE_LENGTH];
		
		
		//*********************************************************************
		//* 		   					STEAM          						  *
		//*********************************************************************
		
		// Select a point behind a player
		flOrigin[2] += 25.0;
		flAngle[0] = 110.0;
		
		// Set modified flags on beam
		Format(sName, sizeof(sName), "target%i", clientIndex);
		DispatchKeyValue(clientIndex, "targetname", sName);
		
		// Set name of the object
		Format(sFireName, sizeof(sFireName), "fire%i", clientIndex);
		
		// Set other values
		DispatchKeyValue(nEntity1,"targetname", sFireName);
		DispatchKeyValue(nEntity1, "parentname", sName);
		DispatchKeyValue(nEntity1,"SpawnFlags", "1");
		DispatchKeyValue(nEntity1,"Type", "0");
		DispatchKeyValue(nEntity1,"InitialState", "1");
		DispatchKeyValue(nEntity1,"Spreadspeed", "10");
		DispatchKeyValue(nEntity1,"Speed", "400");
		DispatchKeyValue(nEntity1,"Startsize", "20");
		DispatchKeyValue(nEntity1,"EndSize", "600");
		DispatchKeyValue(nEntity1,"Rate", "30");
		DispatchKeyValue(nEntity1,"JetLength", "200");
		DispatchKeyValue(nEntity1,"RenderColor", "255 100 30");
		DispatchKeyValue(nEntity1,"RenderAmt", "180");
		
		// Spawn the entity into the world
		DispatchSpawn(nEntity1);
		
		// Teleport to the origin
		TeleportEntity(nEntity1, flOrigin, flAngle, NULL_VECTOR);

		// Turn on the entity
		AcceptEntityInput(nEntity1, "TurnOn");
		
		
		//*********************************************************************
		//* 		   					FIRE          						  *
		//*********************************************************************
		
		// Set name of the object
		Format(sSteamName, sizeof(sSteamName), "fire2%i", clientIndex);
		
		// Set other values
		DispatchKeyValue(nEntity2,"targetname", sSteamName);
		DispatchKeyValue(nEntity2, "parentname", sName);
		DispatchKeyValue(nEntity2,"SpawnFlags", "1");
		DispatchKeyValue(nEntity2,"Type", "1");
		DispatchKeyValue(nEntity2,"InitialState", "1");
		DispatchKeyValue(nEntity2,"Spreadspeed", "10");
		DispatchKeyValue(nEntity2,"Speed", "400");
		DispatchKeyValue(nEntity2,"Startsize", "20");
		DispatchKeyValue(nEntity2,"EndSize", "600");
		DispatchKeyValue(nEntity2,"Rate", "10");
		DispatchKeyValue(nEntity2,"JetLength", "200");
		
		// Spawn the entity into the world
		DispatchSpawn(nEntity2);
		
		// Teleport to the origin
		TeleportEntity(nEntity2, flOrigin, flAngle, NULL_VECTOR);

		// Turn on the entity
		AcceptEntityInput(nEntity2, "TurnOn");
		
		//*********************************************************************
		//* 		   				   OTHER          					  	  *
		//*********************************************************************
		
		// Send data to the timer
		DataPack hPack = CreateDataPack();
		WritePackCell(hPack, nEntity1);
		WritePackCell(hPack, nEntity2);
		
		// Create a timer for deleting effect
		CreateTimer(0.5, JetPackKillEffect, hPack, TIMER_FLAG_NO_MAPCHANGE | TIMER_HNDL_CLOSE);
	}
}

/**
 * Timer for killing jetpack's effects.
 *
 * @param hTimer			The timer handle.
 * @param hPack				The data pack.
 **/
public Action JetPackKillEffect(Handle hTimer, any hPack)
{
	// Resets the position in a data pack
	ResetPack(hPack);
	
	// Get values from datapack
	int nEntity1 = ReadPackCell(hPack);
	int nEntity2 = ReadPackCell(hPack);
	
	// Initialize char
	static char sClassname[SMALL_LINE_LENGTH];
	
	// If entity is valid, then delete it
	if(IsValidEdict(nEntity1))
    {
		// Set modified flags on beam
		AcceptEntityInput(nEntity1, "TurnOff");
		
		// Get classname of the object
		GetEdictClassname(nEntity1, sClassname, sizeof(sClassname));
		
		// If it valid, then delete
		if(!strcmp(sClassname, "env_steam", false))
        {
			AcceptEntityInput(nEntity1, "kill");
		}
    }
	
	// If entity is valid, then delete it
	if(IsValidEdict(nEntity2))
    {
		// Set modified flags on beam
		AcceptEntityInput(nEntity2, "TurnOff");
		
		// Get classname of the object
		GetEdictClassname(nEntity2, sClassname, sizeof(sClassname));
		
		// If it valid, then delete
		if(StrEqual(sClassname, "env_steam", false))
        {
			AcceptEntityInput(nEntity2, "kill");
		}
    }
}


/*
 * Other functions
 */

 
/**
 * Called when client press 'CTRL' + 'SPACE' buttons.
 * 
 * @param clientIndex		The client index.
 **/
void JetPackActivate(int clientIndex)
{
	// Validate that client don't spam this command
	if(IsDelay(clientIndex, 0.1))
	{
		return;
	}

	// Get amount of max jumps per all time
	int jumpsMax = GetConVarInt(JetPackMax) * 10;
	
	// If jetpack didn't crossed the limit
	if(gJumps[clientIndex] < jumpsMax)
	{
		// Initialize vectors
		static float flOrigin[3];
		static float flVector[3];
		static float flAngle[3];
		
		// Get client's location and view direction
		GetClientAbsOrigin(clientIndex, flOrigin);
		GetClientEyeAngles(clientIndex, flAngle);
		
		// Get location's angles
		flAngle[0] = -40.0;
		GetAngleVectors(flAngle, flVector, NULL_VECTOR, NULL_VECTOR);
		
		// Scale vector for the boost
		ScaleVector(flVector, GetConVarFloat(JetPackBoost));
		
		// Push the player
		TeleportEntity(clientIndex, NULL_VECTOR, NULL_VECTOR, flVector);
		
		// Create an effect
		JetPackCreateEffect(clientIndex, flOrigin, flAngle);
		
		// Emit flying sound
		EmitSoundToAll("*/zbm3/jetpack/fly.mp3", clientIndex, SNDCHAN_STATIC, SNDLEVEL_LIBRARY);
	}
	else
	{
		// Jetpack need to be reload
		if(gJumps[clientIndex] == jumpsMax)
		{
			// Create a reloading timer
			delete Task_JetPackReload[clientIndex];
			Task_JetPackReload[clientIndex] = CreateTimer(GetConVarFloat(ReloadDelay), JetPackReload, clientIndex, TIMER_FLAG_NO_MAPCHANGE);
		}
		// If it in process of reloading, show the message
		else
		{
			// Set translation target
			SetGlobalTransTarget(clientIndex);
			
			// Show message
			PrintHintText(clientIndex, "%t", "Jetpack Empty");
			
			// Block usage
			return;
		}
	}
	
	// Update flight counter
	gJumps[clientIndex]++;
}
 
/**
 * Timer for reload jetpack.
 *
 * @param hTimer			The timer handle.
 * @param clientIndex		The client index.
 **/
public Action JetPackReload(Handle hTimer, any clientIndex)
{
	// Clear timer 
	Task_JetPackReload[clientIndex] = INVALID_HANDLE;

	// Validate client
	if(!IsPlayerExist(clientIndex))
	{
		return Plugin_Stop;
	}
	
	// Update variables
	gJumps[clientIndex] = 0;

	// Set translation target
	SetGlobalTransTarget(clientIndex);

	// Show message
	PrintHintText(clientIndex, "%t", "Jetpack Reloaded");

	// Destroy timer
	return Plugin_Stop;
}

/**
 * Reset all vars for jetpack.
 * 
 * @param clientIndex		The client index.
 **/
void JetPackRemove(int clientIndex)
{
	#pragma unused clientIndex
	
	// Reset jetpack variables
	gJetPack[clientIndex] = false;
	gJumps[clientIndex] = 0;
	
	// Delete timer
	delete Task_JetPackReload[clientIndex];
}

/**
 * Delay function.
 * 
 * @param clientIndex		The client index.
 * @param flDelay			The delay of updating.
 **/
stock bool IsDelay(int clientIndex, float flDelay)
{
	// Initialize time array
	static float flTime[MAXPLAYERS+1];
	
	// Returns the game time based on the game tick
	float flCurrentTime = GetEngineTime();
	
	// Cooldown don't over yet
	if((flCurrentTime - flTime[clientIndex]) < flDelay)
	{
		// Block usage
		return true;
	}
	
	// Update countdown time
	flTime[clientIndex] = flCurrentTime;
	
	// Allow usage
	return false;
}