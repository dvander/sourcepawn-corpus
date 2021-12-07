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
public Plugin LaserMine =
{
	name        	= "[ZP] Addon: Lasermines",
	author      	= "FrozDark | qubka (Nikita Ushakov)", 	
	description 	= "Addon of extra items",
	version     	= "3.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about extra items.
 **/
#define ZP_ITEM_NAME		"Lasermines"		
#define ZP_ITEM_COST		10			
#define ZP_ITEM_LEVEL		0
#define ZP_ITEM_ONLINE		0
#define ZP_ITEM_LIMIT		0

#define MODEL_BEAM 			"materials/sprites/purplelaser1.vmt"
#define MODEL_MINE 			"models/lasermine/lasermine.mdl"
/**
 * @endsection
 **/

/**
 * List of cvars.
 **/
enum ConVarList
{
    ConVar:CVAR_LASERMINE_DAMAGE,
	ConVar:CVAR_LASERMINE_HEALTH,
	ConVar:CVAR_LASERMINE_COLOR,
	ConVar:CVAR_LASERMINE_ACTIVE_TIME
};

/**
 * Array to store cvar data in.
 **/
ConVar gCvarList[ConVarList];

// Player arrays
int   gLaserMine[MAXPLAYERS+1];

// Color array
int iColor[3];

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
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Pre);

	// Hooks entity env_beam ouput events
	HookEntityOutput("env_beam", "OnTouchedByEntity", EventBeamTouched);
	
	// Load cvars
	gCvarList[CVAR_LASERMINE_DAMAGE] 		= CreateConVar("zp_lasermines_damage", 		 "1.0", 		"The damage to deal to a zombie by the laser in the each frame");
	gCvarList[CVAR_LASERMINE_HEALTH]		= CreateConVar("zp_lasermines_health", 		 "1200", 		"The laser mines health. ['0' = never breaked]");
	gCvarList[CVAR_LASERMINE_COLOR]			= CreateConVar("zp_lasermines_color", 		 "0 0 255", 	"Beam color. Set by RGB");
	gCvarList[CVAR_LASERMINE_ACTIVE_TIME] 	= CreateConVar("zp_lasermines_time", 		 "2.0", 		"The delay of laser mines' activation");
	
	// Create config
	AutoExecConfig(true, "sm_lasermines");
	
	// Add translation for buying phrase
	LoadTranslations("zombieplagueitems.pharses");
}

/**
 * The map is starting.
 **/
public void OnMapStart(/*void*/)
{
	// Precache models
	PrecacheModel(MODEL_BEAM);
	PrecacheModel(MODEL_MINE);

	// Add textures and models to download list
	AddFileToDownloadsTable("models/lasermine/lasermine.dx80.vtx");
	AddFileToDownloadsTable("models/lasermine/lasermine.dx90.vtx");
	AddFileToDownloadsTable("models/lasermine/lasermine.mdl");
	AddFileToDownloadsTable("models/lasermine/lasermine.phy");
	AddFileToDownloadsTable("models/lasermine/lasermine.vvd");
	AddFileToDownloadsTable("materials/models/lasermine/lasermine.vmt");
	AddFileToDownloadsTable("materials/models/lasermine/lasermine.vtf");
	
	// Sounds
	FakePrecacheSound("zbm3/mine/mine_deploy.mp3"); 
	FakePrecacheSound("zbm3/mine/mine_charge.mp3");
	FakePrecacheSound("zbm3/mine/mine_activate.mp3");
	FakePrecacheSound("zbm3/mine/suitchargeok1.mp3");
	FakePrecacheSound("items/itempickup.wav");
}

/**
 * Map has loaded, all configs has been executed.
 **/
public void OnConfigsExecuted(/*void*/)
{
	// Get string with RGB color
	char sColor[SMALL_LINE_LENGTH];
	GetConVarString(gCvarList[CVAR_LASERMINE_COLOR], sColor, sizeof(sColor));
	
	// Convert color string to RGB value
	char sRGB[3][SMALL_LINE_LENGTH];
	int  nPieces = ExplodeString(sColor, " ", sRGB, sizeof(sRGB), sizeof(sRGB[]));
	
	// Breaks a string into pieces and stores each piece into an array of buffers
	for(int i = 0; i < nPieces; i++)
	{
		iColor[i] = StringToInt(sRGB[i]);
	}
}
	
/**
 * Called once a client successfully connects.
 * 
 * @param clientIndex		The client index.
 **/
public void OnClientConnected(int clientIndex)
{
	#pragma unused clientIndex
	
	// Reset amount of lasermines
	gLaserMine[clientIndex] = 0;
}

/**
 * Called when a client is disconnecting from the server.
 * 
 * @param clientIndex		The client index.
 **/
public void OnClientDisconnect(int clientIndex)
{
	#pragma unused clientIndex
	
	// Reset amount of lasermines
	gLaserMine[clientIndex] = 0;
	
	// Delete lasermines
	RemoveLasermine(clientIndex);
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
	
	// Delete lasermines
	RemoveLasermine(clientIndex);
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
	// Get the weapon name
	char sClassname[SMALL_LINE_LENGTH];
	GetEventString(gEventHook, "weapon", sClassname, sizeof(sClassname));
	
	// If it is beam entity, change icon
	if (StrEqual(sClassname, "env_beam"))
	{
		SetEventString(gEventHook, "weapon", "taser");
		SetEventBool(gEventHook, "headshot", true);
	}
}

/**
 * Hook: OnTakeDamage
 * Called right before damage is done.
 * 
 * @param victimIndex		The victim index.
 * @param attackerIndex		The attacker index.
 * @param inflicterIndex	The inflictor index.
 * @param damageAmount		The amount of damage inflicted.
 * @param damageBits		The type of damage inflicted.
 **/
public Action OnTakeDamage(int victimIndex, int &attackerIndex, int &inflicterIndex, float &damageAmount, int &damageBits)
{
	#pragma unused victimIndex, attackerIndex

	// Returns whether or not an edict index is valid
	if (IsEntityLasermine(victimIndex))
	{
		// Verify that the attacker is exist
		if (IsPlayerExist(attackerIndex))
		{
			// If the attacker is human, then stop
			if (ZP_IsPlayerHuman(attackerIndex))
			{
				// Block breaking
				return Plugin_Handled;
			}
			
			// Allow breaking
			return Plugin_Continue;
		}
		
		// Verify that the attacker is another lasermine
		else if (!IsEntityLasermine(inflicterIndex))
		{
			// Block breaking
			return Plugin_Handled;
		}
	}
	
	// Allow breaking
	return Plugin_Continue;
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
		if(ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerSurvivor(clientIndex))
		{
			return Plugin_Handled;
		}
		
		// If round start, then stop
		if (ZP_GetRoundState(SERVER_ROUND_NEW))
		{
			return Plugin_Handled;
		}
		
		// Give lasermine
		GiveLasermine(clientIndex);
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
	if (bitFlags & IN_SPEED || bitFlags & IN_RELOAD)
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
		
		// Validate that client don't spam this command
		if(IsDelay(clientIndex, 0.8))
		{
			return Plugin_Continue;
		}
		
		// Planting lasermine
		if(bitFlags & IN_SPEED)
		{
			if(gLaserMine[clientIndex]) PlantLaserMine(clientIndex);
		}
		// Pickup lasermine
		else
		{
			PickUpLasermine(clientIndex);
		}
	}

	// Allow commands
	return Plugin_Continue;
}


/*
 * Plant and pickup functions
 */

 
/**
 * Called when a clients press 'SHIFT' button.
 * 
 * @param clientIndex		The client index.
 **/
void PlantLaserMine(int clientIndex)
{
	#pragma unused clientIndex
	
	// Do the trace
	Handle hTrace = TraceRay(clientIndex);

	// If trace hit the wall
	if (TR_DidHit(hTrace) && TR_GetEntityIndex(hTrace) < 1)
	{
		// Create an lasermine entities
		int nMine = CreateEntityByName("prop_physics_override");
		int nBeam = CreateEntityByName("env_beam");

		// If entity aren't valid, then skip
		if(nMine && nBeam)
		{

		
			//*********************************************************************
			//* 		   					TRACE          						  *
			//*********************************************************************
			
			// Initialize variables
			float flOrigin[3]; 
			float flNormal[3]; 
			float flBeamEnd[3];
			
			// Initialize chars
			char  sClassname[SMALL_LINE_LENGTH];
			char  sDispatch[SMALL_LINE_LENGTH];

			// Calculate end-vector of the trace
			TR_GetEndPosition(flOrigin, hTrace);
			TR_GetPlaneNormal(hTrace, flNormal);
			
			// Get angles of the trace vectors
			GetVectorAngles(flNormal, flNormal);
			
			// Calculate end-vector
			TR_TraceRayFilter(flOrigin, flNormal, CONTENTS_SOLID, RayType_Infinite, FilterAll);
			TR_GetEndPosition(flBeamEnd, INVALID_HANDLE);

			
			//*********************************************************************
			//* 		   					LASERMINE          					  *
			//*********************************************************************
			
			// Set model for the lasermine
			SetEntityModel(nMine, MODEL_MINE);
			
			// Set explosion fake damage for the lasermine
			DispatchKeyValue(nMine, "ExplodeDamage", "1");
			DispatchKeyValue(nMine, "ExplodeRadius", "1");
			
			// Spawn the lasermine into the world
			DispatchKeyValue(nMine, "spawnflags", "3");
			DispatchSpawn(nMine);
			
			// Disable any physics
			AcceptEntityInput(nMine, "DisableMotion");
			SetEntityMoveType(nMine, MOVETYPE_NONE);
			
			// Teleport the lasermine
			TeleportEntity(nMine, flOrigin, flNormal, NULL_VECTOR);

			// Set modified flags on lasermine
			SetEntProp(nMine, Prop_Data, "m_nSolidType", 6);
			SetEntProp(nMine, Prop_Data, "m_CollisionGroup", 11);
			
			// Set health for the lasermine
			if(GetConVarInt(gCvarList[CVAR_LASERMINE_HEALTH]) > 0)
			{
				SetEntProp(nMine, Prop_Data, "m_takedamage", 2);
				SetEntProp(nMine, Prop_Data, "m_iHealth", GetConVarInt(gCvarList[CVAR_LASERMINE_HEALTH]));
			}
			
			
			//*********************************************************************
			//* 		   					BEAM          						  *
			//*********************************************************************
			
			// Set modified flags on the beam
			Format(sClassname, sizeof(sClassname), "Beam%i", nBeam);
			Format(sDispatch, sizeof(sDispatch), "%s,Kill,,0,-1", sClassname);
			DispatchKeyValue(nMine, "OnBreak", sDispatch);
			
			// Set other values on the beam
			DispatchKeyValue(nBeam, "targetname", sClassname);
			DispatchKeyValue(nBeam, "damage", "0");
			DispatchKeyValue(nBeam, "framestart", "0");
			DispatchKeyValue(nBeam, "BoltWidth", "4.0");
			DispatchKeyValue(nBeam, "renderfx", "0");
			DispatchKeyValue(nBeam, "TouchType", "3");
			DispatchKeyValue(nBeam, "framerate", "0");
			DispatchKeyValue(nBeam, "decalname", "Bigshot");
			DispatchKeyValue(nBeam, "TextureScroll", "35");
			DispatchKeyValue(nBeam, "HDRColorScale", "1.0");
			DispatchKeyValue(nBeam, "texture", MODEL_BEAM);
			DispatchKeyValue(nBeam, "life", "0"); 
			DispatchKeyValue(nBeam, "StrikeTime", "1"); 
			DispatchKeyValue(nBeam, "LightningStart", sClassname);
			DispatchKeyValue(nBeam, "spawnflags", "0"); 
			DispatchKeyValue(nBeam, "NoiseAmplitude", "0"); 
			DispatchKeyValue(nBeam, "Radius", "256");
			DispatchKeyValue(nBeam, "renderamt", "100");
			DispatchKeyValue(nBeam, "rendercolor", "0 0 0");
			
			// Turn off the beam
			AcceptEntityInput(nBeam, "TurnOff");
			
			// Set model for the beam
			SetEntityModel(nBeam, MODEL_BEAM);
			
			// Teleport the beam
			TeleportEntity(nBeam, flBeamEnd, NULL_VECTOR, NULL_VECTOR); 
			
			// Set size of the model
			SetEntPropVector(nBeam, Prop_Data, "m_vecEndPos", flOrigin);
			SetEntPropFloat(nBeam, Prop_Data, "m_fWidth", 3.0);
			SetEntPropFloat(nBeam, Prop_Data, "m_fEndWidth", 3.0);
			
			// Sets the owner of the beam
			SetEntPropEnt(nBeam, Prop_Data, "m_hOwnerEntity", clientIndex); 
			SetEntPropEnt(nMine, Prop_Data, "m_hMoveChild", nBeam);
			SetEntPropEnt(nBeam, Prop_Data, "m_hEffectEntity", nMine);
			
			
			//*********************************************************************
			//* 		   				   OTHER          					  	  *
			//*********************************************************************
			
			// Send data to the timer
			DataPack hPack = CreateDataPack();
			WritePackCell(hPack, nMine);
			WritePackCell(hPack, nBeam);
			WritePackString(hPack, sClassname);
			
			// Create activation time
			CreateTimer(GetConVarFloat(gCvarList[CVAR_LASERMINE_ACTIVE_TIME]), OnActivateLaser, hPack, TIMER_FLAG_NO_MAPCHANGE | TIMER_HNDL_CLOSE);
			
			// Hook damage of the lasermine
			SDKHook(nMine, SDKHook_OnTakeDamage, OnTakeDamage);
			
			// Emit sound
			EmitSoundToAll("*/zbm3/mine/mine_deploy.mp3", clientIndex, SNDCHAN_STATIC);
			EmitSoundToAll("*/zbm3/mine/mine_charge.mp3", nMine, SNDCHAN_STATIC);
			
			// Remove lasermine
			gLaserMine[clientIndex]--;
		}
	}

	// Close trace handle
	CloseHandle(hTrace);
}

/**
 * Called when a clients press 'R' button.
 * 
 * @param clientIndex		The client index.
 **/
void PickUpLasermine(int clientIndex)
{
	#pragma unused clientIndex
	
	// Do the trace
	Handle hTrace = TraceRay(clientIndex);

	// Initialize entity index
	int nEntity = -1;
	
	// If trace hit the lasermine
	if (TR_DidHit(hTrace) && (nEntity = TR_GetEntityIndex(hTrace)) > MaxClients)
	{	
		// Validate client index and owner index, then pickup lasermine
		if (GetClientByLasermine(nEntity) == clientIndex)
		{
			// Give lasermine
			GiveLasermine(clientIndex);
			
			// Emit sound
			EmitSoundToAll("items/itempickup.wav", nEntity, SNDCHAN_STATIC);
			
			// Kill entity
			AcceptEntityInput(nEntity, "Kill");
		}
	}

	// Close trace handle
	CloseHandle(hTrace);
}


/*
 * Some important functions
 */


/**
 * Called, when lasermine is activated.
 *
 * @param hTimer		The timer handle.
 * @param hPack			The data pack.
 **/
public Action OnActivateLaser(Handle hTimer, any hPack)
{
	// Resets the position in a data pack
	ResetPack(hPack);

	// Get values from datapack
	int nMine = ReadPackCell(hPack);
	int nBeam = ReadPackCell(hPack);
	
	// Iniliaze char
	char sClassname[SMALL_LINE_LENGTH];
	
	// Convert string from datapack
	ReadPackString(hPack, sClassname, sizeof(sClassname));
	
	// If entity is valid, then emit activation sound
	if (IsValidEdict(nMine))
	{
		EmitSoundToAll("*/zbm3/mine/mine_activate.mp3", nMine, SNDCHAN_STATIC);
	}
	
	// If entity is valid, then activate it
	if(IsValidEdict(nBeam))
	{
		// Iniliaze char
		char sDispatch[SMALL_LINE_LENGTH];

		// Turn on the beam
		AcceptEntityInput(nBeam, "TurnOn");

		// Set color for the beam model
		SetEntityRenderColor(nBeam, iColor[0], iColor[1], iColor[2]);

		// Set modified flags on the beam
		Format(sDispatch, sizeof(sDispatch), "%s,TurnOff,,0.001,-1", sClassname);
		DispatchKeyValue(nBeam, "OnTouchedByEntity", sDispatch);
		Format(sDispatch, sizeof(sDispatch), "%s,TurnOn,,0.002,-1", sClassname);
		DispatchKeyValue(nBeam, "OnTouchedByEntity", sDispatch);
	}
	
	// Destroy timer
	return Plugin_Stop;
}

/**
 * Called when a clients touch env_beam entity.
 *
 * @param sOutput			The output char. 
 * @param nEntity			The entity index.
 * @param activatorIndex	The activator index.
 * @param flDelay			The delay of updating.
 **/ 
public void EventBeamTouched(const char[] sOutput, int nEntity, int activatorIndex, float flDelay)
{
	#pragma unused activatorIndex
	
	// If round end, then stop
	if (ZP_GetRoundState(SERVER_ROUND_END))
	{
		return;
	}
	
	// If entity isn't valid, then stop
	if(!IsValidEdict(nEntity))
	{
		return;
	}
	
	// Verify that the activator is exist
	if (!IsPlayerExist(activatorIndex))
	{
		return;
	}
	
	// Verify that the activator is zombie
	if(!ZP_IsPlayerZombie(activatorIndex))
	{
		return;
	}

	// Get the owner of the lasermine
	int ownerIndex = GetEntPropEnt(nEntity, Prop_Data, "m_hOwnerEntity");
	
	// Verify that the owner is connected
	if (!IsPlayerExist(ownerIndex, false))
	{
		return;
	}
	
	// Apply damage
	SDKHooks_TakeDamage(activatorIndex, nEntity, ownerIndex, GetConVarFloat(gCvarList[CVAR_LASERMINE_DAMAGE]), DMG_BURN);
	
	// Emit hurt sound
	EmitSoundToAll("*/zbm3/mine/suitchargeok1.mp3", activatorIndex, SNDCHAN_VOICE, SNDLEVEL_NORMAL);
}


/*
 * Useful stocks functions
 */


/**
 * Return owner index from beam entity.
 *
 * @param nEntity			The entity index.
 * @return 					The client index.
 **/
stock int GetClientByLasermine(int nEntity)
{
	// Get beam index from lasermine
	int nBeam = GetBeamByLasermine(nEntity)
	
	// If valid
	if (nBeam != -1)
	{
		return GetEntPropEnt(nBeam, Prop_Data, "m_hOwnerEntity");
	}
	
	// If didn't find, then stop
	return -1;
}

/**
 * Return beam index from lasermine entity.
 *
 * @param nEntity			The entity index.
 * @return 					The beam index.
 **/
stock int GetBeamByLasermine(int nEntity)
{
	// If valid
	if (IsEntityLasermine(nEntity))
	{
		return GetEntPropEnt(nEntity, Prop_Data, "m_hMoveChild");
	}
	
	// If didn't find, then stop
	return -1;
}

/**
 *	Check lasermine entity valid or not.
 *
 * @param nEntity			The entity index.
 * @return 					True or false.
 **/
stock bool IsEntityLasermine(int nEntity)
{
	// If entity isn't valid, then stop
	if (nEntity <= MaxClients || !IsValidEdict(nEntity))
	{
		return false;
	}
	
	// Initialize model char
	char sModel[BIG_LINE_LENGTH];
	GetEntPropString(nEntity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	
	// Return true, if found
	return (StrEqual(sModel, MODEL_MINE, false) && GetEntPropEnt(nEntity, Prop_Data, "m_hMoveChild") != -1) ? true : false;
}

/**
 * Give lasermine to the player and send the info message.
 * 
 * @param clientIndex		The client index.
 **/
stock void GiveLasermine(int clientIndex)
{
	// Give lasermine
	gLaserMine[clientIndex]++;
	
	// Set translation target
	SetGlobalTransTarget(clientIndex);
	
	// Show message
	PrintHintText(clientIndex, "Press SHIFT to plant a mine\nPress R to pick up it\nYou have %i lasermine(s)", gLaserMine[clientIndex]);
}

/**
 * Check all entities and remove lasermines.
 * 
 * @param clientIndex		The client index.
 **/
stock void RemoveLasermine(int clientIndex)
{
	#pragma unused clientIndex
	
	// Get max amount of entities
	int nGetMaxEnt = GetMaxEntities();
	
	// nEntity = entity index
	for (int nEntity = 0; nEntity <= nGetMaxEnt; nEntity++)
	{
		// Validate client index and owner index, then delete entity
		if (GetClientByLasermine(nEntity) == clientIndex)
		{
			AcceptEntityInput(nEntity, "Kill");
		}
	}
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
	
	// Cooldown don't over yet, then stop
	if ((flCurrentTime - flTime[clientIndex]) < flDelay)
	{
		// Block usage
		return true;
	}
	
	// Update countdown time
	flTime[clientIndex] = flCurrentTime;
	
	// Allow usage
	return false;
}


/*
 * Trace filtering functions
 */

 
/**
 * Starts up a new trace ray using a new trace result and a customized trace ray filter.
 * Calling TR_Trace*Filter or TR_TraceRay*Ex from inside a filter function is currently not allowed and may not work.
 * 
 * @param clientIndex		The client index.
 **/
Handle TraceRay(int clientIndex)
{
	#pragma unused clientIndex
	
	// Iniliaze vectors
	float flStartEnt[3];
	float flAngle[3]; 
	float flEnd[3];
	
	// Get owner's eye position
	GetClientEyePosition(clientIndex, flStartEnt);
	
	// Get owner's eye angles
	GetClientEyeAngles(clientIndex, flAngle);
	
	// Get owner's head position
	GetAngleVectors(flAngle, flEnd, NULL_VECTOR, NULL_VECTOR);
	
	// Normalize the vector (equal magnitude at varying distances)
	NormalizeVector(flEnd, flEnd);

	// Counting the vectors start origin
	flStartEnt[0] = flStartEnt[0] + flEnd[0] * 10.0;
	flStartEnt[1] = flStartEnt[1] + flEnd[1] * 10.0;
	flStartEnt[2] = flStartEnt[2] + flEnd[2] * 10.0;

	// Counting the vectors end origin
	flEnd[0] = flStartEnt[0] + flEnd[0] * 80.0;
	flEnd[1] = flStartEnt[1] + flEnd[1] * 80.0;
	flEnd[2] = flStartEnt[2] + flEnd[2] * 80.0;
	
	// Return result of the trace
	return TR_TraceRayFilterEx(flStartEnt, flEnd, CONTENTS_SOLID, RayType_EndPoint, FilterPlayers);
}

/**
 * Trace filter.
 *
 * @param entityIndex		The entity index.  
 * @param contentsMask		The contents mask.
 **/
public bool FilterAll(int nEntity, int contentsMask)
{
	return false;
}

/**
 * Trace filter.
 *
 * @param entityIndex		The entity index.  
 * @param contentsMask		The contents mask.
 **/
public bool FilterPlayers(int nEntity, int contentsMask)
{
	return !(1 <= nEntity <= MaxClients);
}