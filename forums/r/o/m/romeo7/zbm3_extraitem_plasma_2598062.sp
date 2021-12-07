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
#include <cstrike>
#include <zombieplague>

#pragma newdecls required

// Don't touch this line, lol.
#define _FRAME_UPDATE

/**
 * Record plugin info.
 **/
public Plugin CBaseWeapon =
{
	name        	= "[ZP] ExtraItem: CBaseWeapon",
	author      	= "qubka (Nikita Ushakov)", 	
	description 	= "Add new weapon to human",
	version     	= "5.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about extra items.
 **/
#define EXTRA_ITEM_NAME				"Custom weapon" 
#define EXTRA_ITEM_COST				12
#define EXTRA_ITEM_LEVEL			0
#define EXTRA_ITEM_ONLINE			0
#define EXTRA_ITEM_LIMIT			0

#define WEAPON_NAME					"weapon_plasma"
#define WEAPON_REFERANCE			"weapon_scar20"
#define WEAPON_SLOT					WEAPON_SLOT_PRIMARY		

#define MODEL_WORLD					"models/weapons/plasma/w_snip_plasma.mdl"
#define MODEL_VIEW					"models/weapons/plasma/v_snip_plasma.mdl"

#define SOUND_FIRE					"weapons/RequestsStudio/UT3/AvrilFire.mp3"

#define WEAPON_MULTIPLIER_DAMAGE	1.23

#define WEAPON_TIME_NEXT_ATTACK		0.3
/**
 * @endsection
 **/

//*********************************************************************
//*           Don't modify the code below this line unless            *
//*          	 you know _exactly_ what you are doing!!!             *
//*********************************************************************
 
/**
 * Number of valid player slots.
 **/
enum
{ 
	WEAPON_SLOT_INVALID = -1, 		/** Used as return value when an weapon doens't exist. */
	
	WEAPON_SLOT_PRIMARY, 			/** Primary slot */
	WEAPON_SLOT_SECONDARY, 			/** Secondary slot */
	WEAPON_SLOT_MELEE, 				/** Melee slot */
	WEAPON_SLOT_EQUEPMENT			/** Equepment slot */
};
 
// Item index
int iItem;

// Weapon model indexes
int iViewModel;
int iWorldModel;

/**
 * Plugin is loading.
 **/
public void OnPluginStart(/*void*/)
{
	// Initilizate extra item
	iItem = ZP_RegisterExtraItem(EXTRA_ITEM_NAME, EXTRA_ITEM_COST, TEAM_HUMAN, EXTRA_ITEM_LEVEL, EXTRA_ITEM_ONLINE, EXTRA_ITEM_LIMIT);
	
	// Hook temp entity
	AddTempEntHook("Shotgun Shot", WeaponFireBullets);
	
	// Hook weapon events
	HookEvent("weapon_fire", WeaponFire, EventHookMode_Post);
}

/**
 * The map is starting.
 **/
public void OnMapStart(/*void*/)
{
	// Precache models and their parts
	iWorldModel = FakePrecacheModel(MODEL_WORLD);
	iViewModel  = FakePrecacheModel(MODEL_VIEW);
	
	// Precache sound
	FakePrecacheSound(SOUND_FIRE);
}

/**
 * Called after select an extraitem in the equipment menu.
 * 
 * @param clientIndex		The client index.
 * @param extraitemIndex	The index of extraitem from ZP_RegisterExtraItem() native.
 *
 * @return					Plugin_Handled or Plugin_Stop to block purhase. Anything else
 *                          	(like Plugin_Continue) to allow purhase and taking ammopacks.
 **/
public Action ZP_OnClientBuyExtraItem(int clientIndex, int extraitemIndex)
{
	// Validate client
	if(!IsPlayerExist(clientIndex))
	{
		return Plugin_Handled;
	}
	
	// Check the item's index
	if(extraitemIndex == iItem)
	{
		// Return ammopacks
		if(ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerSurvivor(clientIndex))
		{
			return Plugin_Handled;
		}

		//**********************************************
		//* GIVE WEAPON                                *
		//**********************************************
		
		// Drop the current weapon, if it exist
		WeaponDrop(clientIndex, GetPlayerWeaponSlot(clientIndex, WEAPON_SLOT));
		
		// Give the weapon
		int weaponIndex = GivePlayerItem(clientIndex, WEAPON_REFERANCE);
		
		// Verify that the weapon is valid
		if(IsValidEdict(weaponIndex))
		{
			// Set custom name
			DispatchKeyValue(weaponIndex, "globalname", WEAPON_NAME);

			#if defined _FRAME_UPDATE
				// Select the weapon on the next frame ### METHOD_1
				FakeClientCommandEx(clientIndex, "use weapon_knife");
				RequestFrame(view_as<RequestFrameCallback>(WeaponSelectedModel), clientIndex);
			#else
				// Another method of selecting which work but can be not so stronly reliable ### METHOD_2
				FakeClientCommandEx(clientIndex, "use %s", WEAPON_REFERANCE);
			#endif
		}
	}
	
	// Allow buying
	return Plugin_Continue;
}

/**
 * Event callback (Shotgun Shot)
 * The weapon is about to shoot.
 * 
 * @param sTEName       Temp name.
 * @param iPlayers      Array containing target player indexes.
 * @param numClients    Number of players in the array.
 * @param flDelay   	Delay in seconds to send the TE.
 **/
public Action WeaponFireBullets(const char[] sTEName, const int[] iPlayers, int numClients, float flDelay)
{
	// Initialize weapon index
	int weaponIndex;
	
    // Get all required event info
	int clientIndex = TE_ReadNum("m_iPlayer") + 1;

	// Validate weapon
	if(!IsCustomItem(clientIndex, weaponIndex))
	{
		return;
	}
	
	// Initialize sound
	char sSound[BIG_LINE_LENGTH];
	Format(sSound, sizeof(sSound), "*/%s", SOUND_FIRE);
	
	// Play sound
	//EmitSoundToAll(sSound, clientIndex, SNDCHAN_WEAPON, SNDLEVEL_ROCKET);
	EmitSoundToAll(sSound, clientIndex, SNDCHAN_STATIC, SNDLEVEL_NORMAL);
}

/**
 * Event callback (weapon_fire)
 * The player is shot.
 * 
 * @param gEventHook       	The event handle.
 * @param gEventName       	The name of the event.
 * @param dontBroadcast   	If true, event is broadcasted to all clients, false if not.
 **/
public Action WeaponFire(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
{
	// Initialize weapon index
	int weaponIndex;
	
	// Get all required event info
	int clientIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid"));

	// Validate weapon
	if(!IsCustomItem(clientIndex, weaponIndex))
	{
		return;
	}
	
	// Set next attack time
	float gameTime = GetGameTime() + WEAPON_TIME_NEXT_ATTACK; 
	SetEntPropFloat(clientIndex, Prop_Send, "m_flNextAttack", gameTime);
	
	/**
		enum // NEGEV
		{	
			ANIM_IDLE,
			ANIM_SHOOT1,
			ANIM_SHOOT2,
			ANIM_SHOOT_MODE,
			ANIM_RELOAD,
			ANIM_DRAW,
			ANIM_EMPTY_IDLE,
			ANIM_EMPTY_DRAW,
			ANIM_EMPTY_RELOAD
		};
	
		int iSequence = GetEntProp(ZP_GetClientViewModel(clientIndex), Prop_Send, "m_nSequence");
		float flCycle = GetEntPropFloat(ZP_GetClientViewModel(clientIndex), Prop_Data, "m_flCycle");
		
		PrintToChatAll("%f.1 %i", flCycle, iSequence);
		
		int iAnim = GetRandomInt(ANIM_SHOOT1, ANIM_SHOOT2);

		if (FloatCompare(flCycle, 0.0) == 0)
		{
			SetEntPropFloat(ZP_GetClientViewModel(clientIndex), Prop_Data, "m_flPlaybackRate", 0.5);
			SetEntPropFloat(ZP_GetClientViewModel(clientIndex), Prop_Data, "m_flNextPrimaryAttack", gameTime);
			//SetEntPropFloat(ZP_GetClientViewModel(clientIndex), Prop_Data, "m_flNextSecondaryAttack", gameTime);
			SetEntProp(ZP_GetClientViewModel(clientIndex), Prop_Send, "m_nSequence", iAnim);
		}
		
		SetEntPropFloat(weaponIndex, Prop_Data, "m_flPlaybackRate", 0.5);
		SetEntPropFloat(weaponIndex, Prop_Data, "m_flTimeWeaponIdle", gameTime);
		SetEntPropFloat(weaponIndex, Prop_Data, "m_flNextPrimaryAttack", gameTime);
		//SetEntPropFloat(weaponIndex, Prop_Data, "m_flNextSecondaryAttack", gameTime);
		SetEntProp(weaponIndex, Prop_Send, "m_nSequence", iAnim);
	**/
}

//**********************************************
//* DAMAGE FUNCTIONS                           *
//**********************************************

/**
 * Called when a client take a fake damage.
 * 
 * @param clientIndex		The client index.
 * @param attackerIndex		The attacker index.
 * @param damageAmount		The amount of damage inflicted.
 **/
public void ZP_OnClientDamaged(int clientIndex, int attackerIndex, float &damageAmount)
{
	// Initialize weapon index
	int weaponIndex;

	// Validate weapon
	if(!IsCustomItem(attackerIndex, weaponIndex))
	{
		return;
	}
	
	// Change damage
	damageAmount *= WEAPON_MULTIPLIER_DAMAGE; 
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
 * @param clientIndex		The client index. 
 **/
public void OnClientPutInServer(int clientIndex)
{
	SDKHook(clientIndex, SDKHook_WeaponDropPost, 	WeaponDropPost)
	SDKHook(clientIndex, SDKHook_WeaponSwitchPost,  WeaponDeployPost);
}

/**
 * Called after dropping weapon.
 * 
 * @param clientIndex		The client index. 
 * @param weaponIndex		The weapon index.
 **/
public Action WeaponDropPost(int clientIndex, int weaponIndex)
{
	// Set dropped model on next frame
	RequestFrame(view_as<RequestFrameCallback>(WeaponDroppedModel), weaponIndex);
}

/**
 * Hook: WeaponSwitchPost
 * Called, when player deploy any weapon.
 *
 * @param clientIndex	 	The client index.
 * @param weaponIndex    	The weapon index.
 **/
public void WeaponDeployPost(int clientIndex, int weaponIndex) 
{
	// Set weapon models on next frame
	RequestFrame(view_as<RequestFrameCallback>(WeaponViewModel), clientIndex);
}

//**********************************************
//* VALIDATIONS                                *
//**********************************************

/**
 * Validate custom weapon and player.
 * 
 * @param clientIndex		The client index. 
 * @param weaponIndex		The weapon index.
 * @return 					True if valid, false if not.
 **/
stock bool IsCustomItem(int clientIndex, int &weaponIndex)
{
	// Validate client
	if (!IsPlayerExist(clientIndex))
	{
		return false;
	}
	
	// Get weapon index
	weaponIndex = GetEntPropEnt(clientIndex, Prop_Data, "m_hActiveWeapon");
	
	// Verify that the weapon is valid
	if(!IsValidEdict(weaponIndex))
	{
		return false;
	}
	
	// Get weapon classname
	char sClassname[SMALL_LINE_LENGTH];
	GetEntityClassname(weaponIndex, sClassname, sizeof(sClassname));
	
	// If weapon classname isn't equal, then stop
	if(!StrEqual(sClassname, WEAPON_REFERANCE))
	{
		return false;
	}
	
	// Get weapon global name
	GetEntPropString(weaponIndex, Prop_Data, "m_iGlobalname", sClassname, sizeof(sClassname));

	// If weapon key isn't equal, then stop
	if(!StrEqual(sClassname, WEAPON_NAME))
	{
		return false;
	}
	
	// If it is custom weapon
	return true;
}

/**
 * Validate custom weapon.
 * 
 * @param weaponIndex		The weapon index.
 * @return 					True if valid, false if not.
 **/
stock bool IsCustomItemEntity(int weaponIndex)
{
	// Verify that the weapon is valid
	if(!IsValidEdict(weaponIndex))
	{
		return false;
	}
	
	// Get weapon classname
	char sClassname[SMALL_LINE_LENGTH];
	GetEntityClassname(weaponIndex, sClassname, sizeof(sClassname));
	
	// If weapon classname isn't equal, then stop
	if(!StrEqual(sClassname, WEAPON_REFERANCE))
	{
		return false;
	}
	
	// Get weapon global name
	GetEntPropString(weaponIndex, Prop_Data, "m_iGlobalname", sClassname, sizeof(sClassname));

	// If weapon key isn't equal, then stop
	if(!StrEqual(sClassname, WEAPON_NAME))
	{
		return false;
	}
	
	// If it is custom weapon
	return true;
}

//**********************************************
//* WEAPON FUNCTIONS                		   *
//**********************************************

/**
 * Set the dropped model on the next frame.
 *
 * @param weaponIndex		The weapon index.
 **/
public void WeaponDroppedModel(int weaponIndex) { RequestFrame(view_as<RequestFrameCallback>(WeaponWorldModel), weaponIndex); }

/**
 * Set the world model.
 *
 * @param weaponIndex		The weapon index.
 **/
public void WeaponWorldModel(int weaponIndex)
{
	// Validate weapon
	if(!IsCustomItemEntity(weaponIndex))
	{
		return;
	}
	
	// Set dropped model
	SetEntityModel(weaponIndex, MODEL_WORLD);
}

/**
 * Set the view model.
 *
 * @param clientIndex		The client index.
 **/
public void WeaponViewModel(int clientIndex)
{
	// Initialize weapon index
	int weaponIndex;

	// Validate weapon
	if(!IsCustomItem(clientIndex, weaponIndex))
	{
		return;
	}

	// Set weapon models
	SetViewModel(clientIndex, weaponIndex, iViewModel);
	SetWorldModel(weaponIndex, iWorldModel);
}

/**
 * Set the selected weapon.
 *
 * @param clientIndex		The client index.
 **/
#if defined _FRAME_UPDATE
public void WeaponSelectedModel(int clientIndex)
{
	// Validate client
	if (!IsPlayerExist(clientIndex))
	{
		return;
	}
	
	// Set selected weapon
	FakeClientCommandEx(clientIndex, "use %s", WEAPON_REFERANCE);
}
#endif

/**
 * Drop weapon function.
 *
 * @param clientIndex		The client index.
 * @param weaponIndex		The weapon index.
 **/
stock void WeaponDrop(int clientIndex, int weaponIndex)
{
	// If entity isn't valid, then stop
	if (!IsValidEdict(weaponIndex)) 
	{
		return;
	}
	
	// Get the owner of the weapon
	int ownerIndex = GetEntPropEnt(weaponIndex, Prop_Send, "m_hOwnerEntity");

	// If owner index is different, so set it again
	if (ownerIndex != clientIndex) 
	{
		SetEntPropEnt(weaponIndex, Prop_Send, "m_hOwnerEntity", clientIndex);
	}

	// Forces a player to drop weapon
	CS_DropWeapon(clientIndex, weaponIndex, false);
}