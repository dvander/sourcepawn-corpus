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
#include <cstrike>
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin myinfo =
{
	name        	= "[ZP] ExtraItem: M200",
	author      	= "Draakoor & gubka", 	
	description 	= "",
	version     	= "1.0",
	url         	= "www.thegermanfortress.de"
}

/**
 * @section Information about extra items.
 **/
#define EXTRA_ITEM_NAME				"M200" 
#define EXTRA_ITEM_COST				5
#define EXTRA_ITEM_LEVEL			0
#define EXTRA_ITEM_ONLINE			0
#define EXTRA_ITEM_LIMIT			0

#define WEAPON_NAME					"weapon_m200"
#define WEAPON_REFERANCE			"weapon_awp"

#define MODEL_WORLD 				"models/weapons/m200/w_snip_m200.mdl"
#define MODEL_VIEW					"models/weapons/m200/v_snip_m200.mdl"

#define SOUND_FIRE					"weapons/m200/fire.mp3"

#define WEAPON_MULTIPLIER_DAMAGE 	1.5
/**
 * @endsection
 **/

//*********************************************************************
//*           Don't modify the code below this line unless            *
//*          	 you know _exactly_ what you are doing!!!             *
//*********************************************************************
 
// Item index
int iItem;
bool bHasCustomWeapon[MAXPLAYERS+1];

// Weapon model indexes
int iViewModel;
int iWorldModel;

/**
 * Plugin is loading.
 **/
public void OnPluginStart()
{
	// Initilizate extra item
	iItem = ZP_RegisterExtraItem(EXTRA_ITEM_NAME, EXTRA_ITEM_COST, ZP_TEAM_HUMAN, EXTRA_ITEM_LEVEL, EXTRA_ITEM_ONLINE, EXTRA_ITEM_LIMIT);
	
	// Hook temp entity
	AddTempEntHook("Shotgun Shot", WeaponFireBullets);
}

/**
 * The map is starting.
 **/
public void OnMapStart(/*void*/)
{
	// Precache models
	iWorldModel = PrecacheModel(MODEL_WORLD);
	iViewModel  = PrecacheModel(MODEL_VIEW);
	
	// Precache sound
	char sSound[128];
	Format(sSound, sizeof(sSound), "*/%s", SOUND_FIRE);
	AddToStringTable(FindStringTable("soundprecache"), sSound);
	Format(sSound, sizeof(sSound), "sound/%s", SOUND_FIRE);
	AddFileToDownloadsTable(sSound); 
	
	// Add models to download list
	AddFileToDownloadsTable("models/weapons/m200/v_snip_m200mdl");
	AddFileToDownloadsTable("models/weapons/m200/v_snip_m200.dx90");
	AddFileToDownloadsTable("models/weapons/m200/v_snip_m200.vvd");
	AddFileToDownloadsTable("models/weapons/m200/w_snip_m200.mdl");
	AddFileToDownloadsTable("models/weapons/m200/w_snip_m200.dx90");
	AddFileToDownloadsTable("models/weapons/m200/w_snip_m200.phy");
	AddFileToDownloadsTable("models/weapons/m200/w_snip_m200.vvd");
	
	// Add textures to download list
	AddFileToDownloadsTable("materials/models/weapons/v_models/snip_m200/lens.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/snip_m200/Lens.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/snip_m200/Lens_n.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/snip_m200/m200.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/snip_m200/m200.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/snip_m200/m200_2.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/snip_m200/m200_2.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/snip_m200/m200_2_n.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/snip_m200/m200_2_si.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/snip_m200/m200_n.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/snip_m200/m200_si.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/snip_m200/rifle.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/snip_m200/rifle.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/snip_m200/rifle_normal.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/snip_m200/scope.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/snip_m200/scope.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/snip_m200/scope_n.vtf");
	AddFileToDownloadsTable("materials/models/weapons/w_models/w_snip_m200/scope.vtf");
	AddFileToDownloadsTable("materials/models/weapons/w_models/w_snip_m200/scope.vmt");
	AddFileToDownloadsTable("materials/models/weapons/w_models/w_snip_m200/w_m200.vtf");
	AddFileToDownloadsTable("materials/models/weapons/w_models/w_snip_m200/w_m200.vmt");
}

/**
 * Called after select an extraitem in equipment menu.
 * 
 * @param clientIndex		The client index.
 * @param extraitemIndex	Index of extraitem from ZP_RegisterExtraItem() native.
 *
 * @return					Plugin_Handled to block purhase. Anything else
 *                          	(like Plugin_Continue) to allow purhase and taking ammopacks.
 **/
public Action ZP_OnExtraBuyCommand(int clientIndex, int extraitemIndex)
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

		//**********************************************
		//* GIVE WEAPON                                *
		//**********************************************
		
		// Get weapon index from slot
		int iSlot = GetPlayerWeaponSlot(clientIndex, WEAPON_SLOT_PRIMARY);

		// If weapon is valid, then drop
		if (iSlot != WEAPON_SLOT_INVALID)
		{
			CS_DropWeapon(clientIndex, iSlot, true, false);
		}
		
		// Give item
		bHasCustomWeapon[clientIndex] = true;
		int weaponIndex = GivePlayerItem(clientIndex, WEAPON_REFERANCE);
		FakeClientCommandEx(clientIndex, "use %s", WEAPON_REFERANCE);
		
		// If weapon is valid, then switch
		if(IsValidEdict(weaponIndex))
		{
			SetEntPropEnt(clientIndex, Prop_Send, "m_hActiveWeapon", weaponIndex);
		}
	}
	
	// Allow buying
	return Plugin_Continue;
}

/**
 * Set dropped model.
 *
 * @param weaponIndex		The weapon index.
 **/
public void SetDroppedModel(int weaponIndex)
{
	// If weapon isn't custom
	if(!IsCustomItemEntity(weaponIndex))
	{
		return;
	}
	
	// Set dropped model
	SetEntityModel(weaponIndex, MODEL_WORLD);
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

	// If weapon isn't custom
	if(!IsCustomItem(clientIndex, weaponIndex))
	{
		return;
	}
	
	// Initialize sound
	char sSound[128];
	Format(sSound, sizeof(sSound), "*/%s", SOUND_FIRE);
	
	// Play sound
	EmitSoundToAll(sSound, clientIndex, SNDCHAN_WEAPON, SNDLEVEL_ROCKET);
	EmitSoundToAll(sSound, clientIndex, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
}

//**********************************************
//* DAMAGE FUNCTIONS                           *
//**********************************************

/**
 * Hook: OnTakeDamage
 * Called right before damage is done.
 * 
 * @param iVictim        The client index.
 * @param iAttacker      The client index of the attacker.
 * @param iInflicter     The entity index of the inflicter.
 * @param flDamage       The amount of damage inflicted.
 * @param pDamageBits    The type of damage inflicted.
 **/
public Action WeaponTakeDamage(int iVictim, int &iAttacker, int &iInflicter, float &flDamage, int &pDamageBits)
{
	// Initialize weapon index
	int weaponIndex;

	// If weapon isn't custom
	if(!IsCustomItem(iAttacker, weaponIndex))
	{
		return Plugin_Continue;
	}
	
	// Change damage
	flDamage *= WEAPON_MULTIPLIER_DAMAGE; 
	return Plugin_Changed;
}

/**
 * Hook: WeaponSwitchPost
 * Called, when player deploy any weapon.
 *
 * @param clientIndex	 The client index.
 * @param weaponIndex    The weapon index.
 **/
public void WeaponDeployPost(int clientIndex, int weaponIndex) 
{
	// If client just buy this custom weapon
	if(bHasCustomWeapon[clientIndex])
	{
		// Reset bool
		bHasCustomWeapon[clientIndex] = false;
		
		// Verify that the weapon is valid
		if(!IsValidEdict(weaponIndex))
		{
			return;
		}

		// Set custom name
		DispatchKeyValue(weaponIndex, "globalname", WEAPON_NAME);
	}
	
	// If weapon isn't valid, then stop
	if(!IsCustomItemEntity(weaponIndex))
	{
		return;
	}
	
	// Verify that the client is connected and alive
	if(!IsPlayerExist(clientIndex))
	{
		return;
	}

	// Set weapon models
	SetViewModel(weaponIndex, ZP_GetClientViewModel(clientIndex), iViewModel);
	SetWorldModel(weaponIndex, iWorldModel);
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
	SDKHook(clientIndex, SDKHook_OnTakeDamage,   	WeaponTakeDamage);
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
	RequestFrame(view_as<RequestFrameCallback>(SetDroppedModel), weaponIndex);
}

//**********************************************
//* STOCKS                                     *
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
	char sClassname[32];
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
	char sClassname[32];
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