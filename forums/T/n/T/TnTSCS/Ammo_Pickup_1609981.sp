/* 
* 	Special thanks to the following for their help in IRC and 
* 	creation of the include and gamedata for the 
* 	CS_SetDroppedWeaponAmmo and CS_GetDroppedWeaponAmmo
* 
* 		psychonic
* 		Peace-Maker
* 		MatthiasVance
* 
* 
* 
* 	Change Log:
* 
* 		Version 0.1.0
* 			*	Initial release on request URL http://forums.alliedmods.net/showthread.php?t=173286
* 
*  */

#include <sdkhooks>
#include <cssdroppedammo>
#include <smlib\clients>

#define PLUGIN_VERSION "0.1.0"

public Plugin:myinfo = 
{
	name = "Ammo Pickup",
	author = "TnTSCS aka ClarkKent	",
	description = "Allows players to pick up ammo from dropped guns",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	// Create this plugins CVars
	new Handle:hRandom;// KyleS HATES handles
	
	HookConVarChange((hRandom = CreateConVar("sm_ammopickup_version", PLUGIN_VERSION, 
	"Version of 'Ammo Pickup'", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY)), OnVersionChanged);
	
	CloseHandle(hRandom);// KyleS HATES Handles
}


/**
 * Called once a client is authorized and fully in-game, and 
 * after all post-connection authorizations have been performed.  
 *
 * This callback is gauranteed to occur on all clients, and always 
 * after each OnClientPutInServer() call.
 *
 * @param client		Client index.
 * @noreturn
 */
public OnClientPostAdminCheck(client)
{
	// Apply SDKHooks on players so we know when a weapon is dropped and equiped
	SDKHook(client, SDKHook_WeaponDropPost, OnWeaponDropPost);
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}


/**
 * Called when a client is disconnecting from the server.
 *
 * @param client		Client index.
 * @noreturn
 */
// You still need to check IsClientInGame(client) if you want to do the client specific stuff (exvel)
public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		// Unhook these from players leaving the server
		SDKUnhook(client, SDKHook_WeaponDropPost, OnWeaponDropPost);
		SDKUnhook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
	}
}


/**
 * Called when a player picks up a weapon
 * 
 * @param client		client index
 * @param weapon	weapon index
 * @noreturn
 */
public OnWeaponEquipPost(client, weapon)
{
	if(IsValidEntity(weapon))
	{
		// Since this weapon was picked up, unhook it
		SDKUnhook(weapon, SDKHook_WeaponDropPost, OnWeaponDropPost);
	}
}


/**
 * Called when a player drops a weapon
 * 
 * @param client		client index
 * @param weapon	weapon index
 * @noreturn
 */
public OnWeaponDropPost(client, weapon)
{
	if(IsValidEntity(weapon))
	{
		// Hook weapon index so we know when someone touches it
		SDKHook(weapon, SDKHook_StartTouch, StartTouch);
	}
}


/**
 * Called when a player touches a weapon that was dropped
 * 
 * @param entity		entity index of weapon
 * @param other		entity index of player (client)
 * @noreturn
 */
public Action:StartTouch(entity, other)
{
	decl String:entityName[64];
	entityName[0] = '\0';
	
	GetEntityClassname(entity, entityName, sizeof(entityName));
	
	// See if entity class name starts with weapon_
	if(StrContains(entityName, "weapon_", false) != -1)
	{
		// ensure other is a player
		if(other > 0 && other <= MaxClients)
		{
			// Figure out if the gun their touching has the same ammo as the guns they're carrying
			ProcessAmmo(other, entity);
		}
	}
}


/**
 * Figure out if the gun the player is touching has the same ammo type as the guns
 * they have in either slot 0 or slot 1
 * If it's the same, strip the ammo from the gun and add it to the players ammo reserve
 * 
 * @param client		client index
 * @param weapon	weapon index of weapon being touched
 */
ProcessAmmo(client, weapon)
{
	decl String:WeaponName[64];	
	WeaponName[0] = '\0';
	
	new PlayerWeapon;
		
	PlayerWeapon = Client_GetWeaponBySlot(client, 0);
	
	if(PlayerWeapon != -1)
	{
		if(Weapon_GetPrimaryAmmoType(weapon) == Weapon_GetPrimaryAmmoType(PlayerWeapon))
		{				
			ProcessAmmo2(client, weapon, PlayerWeapon);
			return;
		}
	}
	
	PlayerWeapon = Client_GetWeaponBySlot(client, 1);
	
	if(PlayerWeapon != -1)
	{
		if(Weapon_GetPrimaryAmmoType(weapon) == Weapon_GetPrimaryAmmoType(PlayerWeapon))
		{
			ProcessAmmo2(client, weapon, PlayerWeapon);
			return;
		}
	}	
}


/**
 * Function to actually perform the ammo adjustments
 * 
 * @param client			client index
 * @param weapon		weapon index of weapon being touched
 * @param PlayerWeapon	weapon index of player
 */
ProcessAmmo2(client, weapon, PlayerWeapon)
{
	new WeaponAmmo, PlayerAmmo;
	
	decl String:WeaponName[64];	
	WeaponName[0] = '\0';
	
	WeaponAmmo = CS_GetDroppedWeaponAmmo(weapon);
	
	GetEntityClassname(PlayerWeapon, WeaponName, sizeof(WeaponName));
	
	Client_GetWeaponPlayerAmmo(client, WeaponName, PlayerAmmo);
	
	Client_SetWeaponPlayerAmmoEx(client, PlayerWeapon, WeaponAmmo + PlayerAmmo);
	
	CS_SetDroppedWeaponAmmo(weapon, 0);
	
	// No need to keep the weapon hooked since it no longer has ammo reserves
	SDKUnhook(weapon, SDKHook_StartTouch, StartTouch);
}

public OnVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (!StrEqual(newVal, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}