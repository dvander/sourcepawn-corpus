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
* 		Version 0.2.0
* 			*	Implemented new model for dropped ammo and set it to where you could only pickup ammo if it was for the gun type you had
* 
* 		Version 0.2.1
* 			*	Various bug fixes regarding ammo amounts for same ammo type weapons
* 			*	Added CVar to allow you to pickup ammo if the ammo type is the same, regardless if gun type is different.
* 			*	Now have 3 ammo box models - one for pistols, one for rifles, and one for shotguns
* 			*	Added ammopickup.wav sound when player picks up ammo
* 			*	Added CVar to allow or not allow bots to drop ammo
* 			*	Added a bunch of comments to the code
* 
*  */

//========================================================================================
// INCLUDES
//========================================================================================

#include <sdkhooks>
#include <sdktools>
#include <smlib\clients>

//========================================================================================
// DEFINES
//========================================================================================

#define PLUGIN_VERSION "0.2.1"

#define 	PistolAmmo 				"models/items/boxsrounds.mdl"
#define 	OtherAmmo 				"models/items/boxmrounds.mdl"
#define 	SGAmmo 					"models/items/boxbuckshot.mdl"

#define 	SOLID_VPHYSICS			8
#define 	COLLISION_GROUP_NONE	0

#define		PISTOLS					11
#define		RIFLES					10

//========================================================================================
// VARIABLES
//========================================================================================

new Handle:h_Trie;

new bool:BotsDropAmmo = true;
new bool:PistolDrops = true;
new bool:RifleDrops = true;
new bool:AllowMixedAmmo = false;

enum AmmoAttributes
{
ROUNDS,
TYPE,
GUN_TYPE
};

//========================================================================================
//========================================================================================

public Plugin:myinfo = 
{
	name = "Ammo Pickup",
	author = "TnTSCS aka ClarkKent	",
	description = "Allows players to pick up ammo that was dropped from guns",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

//========================================================================================

/**
 * Called when the plugin is fully initialized and all known external references 
 * are resolved. This is only called once in the lifetime of the plugin, and is 
 * paired with OnPluginEnd().
 *
 * If any run-time error is thrown during this callback, the plugin will be marked 
 * as failed.
 *
 * It is not necessary to close any handles or remove hooks in this function.  
 * SourceMod guarantees that plugin shutdown automatically and correctly releases 
 * all resources.
 *
 * @noreturn
 */
public OnPluginStart()
{
	// Create this plugins CVars
	new Handle:hRandom;// KyleS HATES handles
	
	HookConVarChange((hRandom = CreateConVar("sm_ammopickup_version", PLUGIN_VERSION, 
	"Version of 'Ammo Pickup'", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_ammopickup_botsdrop", "1", 
	"Do bots drop ammo?  1=yes, 0=no'", _, true, 0.0, true, 1.0)), OnBotsDropChanged);
	BotsDropAmmo = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_ammopickup_mixedammo", "1", 
	"Allow player to pickup ammo if \"ammo type\" is the same regardless of if \"gun type\" is different (UMP vs glock)?  1=yes, 0=no'", _, true, 0.0, true, 1.0)), OnMixedAmmoChanged);
	AllowMixedAmmo = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_ammopickup_pistols", "1", 
	"Drop ammo on pistol drops?  1=yes, 0=no'", _, true, 0.0, true, 1.0)), OnPistolDropsChanged);
	PistolDrops = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_ammopickup_rifles", "1", 
	"Drop ammo on rifle (shotty, awp, auto, rifle) drops?  1=yes, 0=no'", _, true, 0.0, true, 1.0)), OnRifleDropsChanged);
	RifleDrops = GetConVarBool(hRandom);
	
	CloseHandle(hRandom);// KyleS HATES Handles
	
	h_Trie = CreateTrie();
}

//========================================================================================

/**
 * Called when the map has loaded, servercfgfile (server.cfg) has been 
 * executed, and all plugin configs are done executing.  This is the best
 * place to initialize plugin functions which are based on cvar data.  
 *
 * @note This will always be called once and only once per map.  It will be 
 * called after OnMapStart().
 *
 * @noreturn
 */
public OnConfigsExecuted()
{
	// Pre-cache the models for the ammo boxes
	PrecacheModel(PistolAmmo, true);
	PrecacheModel(OtherAmmo, true);
	PrecacheModel(SGAmmo, true);
	
	// Clear all entries of the Trie
	ClearTrie(h_Trie);
}

//========================================================================================

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
	// Hook player so we know when a weapon is dropped
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}

//========================================================================================

/**
 * Called when a client is disconnecting from the server.
 *
 * @param client		Client index.
 * @noreturn
 */
public OnClientDisconnect(client)
{
	// You still need to check IsClientInGame(client) if you want to do the client specific stuff (exvel)
	if(IsClientInGame(client))
	{
		// Unhook player since they're leaving the server
		SDKUnhook(client, SDKHook_WeaponDrop, OnWeaponDrop);
	}
}

//========================================================================================

/**
 * Called when a player drops a weapon (hooked with SDKHooks)
 * 
 * @param client		client index
 * @param weapon	weapon index
 * @noreturn
 */
public Action:OnWeaponDrop(client, weapon)
{
	// If client is a bot and no ammo drops for bots is set or the weapon index is not a valid entity, handle the drop as normal
	if((IsFakeClient(client) && !BotsDropAmmo) || !IsValidEntity(weapon))
	{
		return Plugin_Continue;
	}

	new WeaponSlot0 = Client_GetWeaponBySlot(client, 0); // Rifle Slot
	new WeaponSlot1 = Client_GetWeaponBySlot(client, 1); // Pistol Slot
	
	// If the weapon being dropped is a rifle, and rifle ammo drops are not allowed, handle the drop as normal
	if(WeaponSlot0 != -1 && (WeaponSlot0 == weapon && !RifleDrops))
	{
		return Plugin_Continue;
	}
	
	// If the weapon being dropped is a pistol, but pistol ammo drops are not allowed, handle the drop as normal
	if(WeaponSlot1 != -1 && (WeaponSlot1 == weapon && !PistolDrops))
	{
		return Plugin_Continue;
	}
	
	// Retrieve the client's health to find out if they're dropping the weapon because they just died
	new playerHealth = GetEntProp(client, Prop_Send, "m_iHealth");
	
	// If both weapons the player is holding have the same ammo type and the player drops one of them, while they're still alive, do not drop ammo
	if(playerHealth > 0 && WeaponSlot0 != -1 && WeaponSlot1 != -1 && (Weapon_GetPrimaryAmmoType(WeaponSlot0) == Weapon_GetPrimaryAmmoType(WeaponSlot1)))
	{
		return Plugin_Continue;
	}
	
	decl String:WeaponName[64];	
	WeaponName[0] = '\0';
	
	GetEntityClassname(weapon, WeaponName, sizeof(WeaponName));
	
	// If the weapon being dropped is the C4 or any type of grenade, handle the drop as normal
	if(!strcmp(WeaponName, "weapon_c4", false) || !strcmp(WeaponName, "weapon_hegrenade", false) || !strcmp(WeaponName, "weapon_flashbang", false) || !strcmp(WeaponName, "weapon_smokegrenade", false))
	{
		return Plugin_Continue;
	}
	
	new ammo;	
	Client_GetWeaponPlayerAmmo(client, WeaponName, ammo);
	
	// If the ammo for the weapon is 0, no need to drop an ammo box
	if(ammo == 0)
	{
		return Plugin_Continue;
	}
	
	// Set the reserve ammo for the weapon being dropped to 0 since we're going to be dropping an ammo box with that ammount
	Client_SetWeaponPlayerAmmo(client, WeaponName, 0);
	
	// See function for details
	DropAmmo(weapon, WeaponSlot0, WeaponSlot1, client, ammo);
	
	return Plugin_Continue
}

//========================================================================================

public DropAmmo(any:weapon, any:WeaponSlot0, any:WeaponSlot1, any:client, any:ammo)
{
	new ent;
	
	// Ensure a successful entity creation
	if((ent = CreateEntityByName("prop_physics_multiplayer")) != -1)
	{
		new Float:origin[3], Float:vel[3];
		
		GetClientEyePosition(client, origin); // Set origin to eye level of client
		
		// Random throw how Knagg0 made (from Bacardi's healthkit_from_dead plugin)
		vel[0] = GetRandomFloat(-100.0, 100.0);
		vel[1] = GetRandomFloat(-100.0, 100.0);
		vel[2] = GetRandomFloat(1.0, 100.0);
		
		TeleportEntity(ent, origin, NULL_VECTOR, vel); // Teleport kit and throw
		
		decl String:targetname[100];
		targetname[0] = '\0';
		
		Format(targetname, sizeof(targetname), "droppedammo_%i", ent); // Create name for entity - droppedammo_ENT#
		
		decl String:WeaponName[64];	
		WeaponName[0] = '\0';
		
		// Store the classname string of the weapon index
		GetEntityClassname(weapon, WeaponName, sizeof(WeaponName));
		
		new weapontype;
		
		// If weapon being dropped is a RIFLE type
		if(WeaponSlot0 != -1 && WeaponSlot0 == weapon)
		{
			if(StrContains(WeaponName, "xm1014") != -1 || StrContains(WeaponName, "m3") != -1)
			{
				// If rifle being dropped is a SHOTGUN, set ammo model's key name to SGAmmo
				DispatchKeyValue(ent, "model", SGAmmo);
			}
			else
			{
				// Otherwise set ammo model's key name to OtherAmmo
				DispatchKeyValue(ent, "model", OtherAmmo);
			}
			
			// Set the weapon type to RIFLES so we know what type of gun (pistol or rifle) this ammo dropped from
			weapontype = RIFLES;
		}
		
		// If weapon being dropped is a PISTOL type
		if(WeaponSlot1 != -1 && WeaponSlot1 == weapon)
		{
			DispatchKeyValue(ent, "model", PistolAmmo); // Set the model's key name
			weapontype = PISTOLS; // Set the weapon type to PISTOLS so we know what type of gun (pistol or rifle) this ammo dropped from
		}
		
		// Set some of the Key Values of the newly created entity
		DispatchKeyValue(ent, "physicsmode", "2"); // Non-Solid, Server-side
		DispatchKeyValue(ent, "massScale", "1.0"); // A scale multiplier for the object's mass. 
		DispatchKeyValue(ent, "targetname", targetname); // The name that other entities refer to this entity by.
		DispatchSpawn(ent); // Spawn the entity
		
		// Set the entity as solid, noclip, and unable to take damage
		SetEntProp(ent, Prop_Send, "m_usSolidFlags", SOLID_VPHYSICS);
		SetEntProp(ent, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_NONE);
		
		// Get the ammo type of the weapon being dropped
		new type = Weapon_GetPrimaryAmmoType(weapon);
		
		// Convert the entity to a string to create the trie (since it requires a string)
		new String:sEntity[12]
		IntToString(ent, sEntity, sizeof(sEntity));
		
		// Set the ammo information for number of rounds, type of ammo, and gun_type
		new SetAmmoInfo[AmmoAttributes];
		SetAmmoInfo[ROUNDS] = ammo;
		SetAmmoInfo[TYPE] = type;
		SetAmmoInfo[GUN_TYPE] = weapontype;
		
		// Set trie for this entity with ammo information
		SetTrieArray(h_Trie, sEntity, SetAmmoInfo[0], 3, true);
		
		// Hook the ammo box entity to know when a player touches it
		SDKHook(ent, SDKHook_StartTouch, StartTouch);
	}
}

//========================================================================================

/**
 * Called when a player touches a weapon that was dropped
 * 
 * @param entity		entity index of weapon
 * @param other		entity index of player (client)
 * @noreturn
 */
public Action:StartTouch(entity, other)
{
	// Retrieve and store the m_ModelName of the entity being touched
	decl String:model[128];
	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
	
	// Make sure "other" is a valid client/player and that the entity being touched is a dropped ammo model (droppedammo_ENT#)
	if(other > 0 && other <= MaxClients && (StrEqual(model, PistolAmmo) || StrEqual(model, SGAmmo) || StrEqual(model, OtherAmmo)))
	{
		// See function for details
		ProcessAmmo(entity, other);
	}
}

//========================================================================================

/**
 * Figure out if the gun the player is touching has the same ammo type as the guns
 * they have in either slot 0 or slot 1
 * If it's the same, strip the ammo from the gun and add it to the players ammo reserve
 * 
 * @param client		client index
 * @param weapon	weapon index of weapon being touched
 */
public ProcessAmmo(entity, client)
{
	// Convert the entity to a string to search the trie (since it requires a string)
	new String:sEntity[12];
	IntToString(entity, sEntity, sizeof(sEntity));
	
	new GetAmmoInfo[AmmoAttributes];
	
	// Retrieves the stored information for the dropped ammo entity if it exists in the array GetAmmoInfo
	if(!GetTrieArray(h_Trie, sEntity, GetAmmoInfo[0], 3))
	{
		LogMessage("****** Ammo Info does not exist!!!!");
		
		// Get rid of the entity and Unhook it from SDKHook_StartTouch
		if(IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
			SDKUnhook(entity, SDKHook_StartTouch, StartTouch);
		}
		
		// Since there was no information for this ammo, stop processing
		return;
	}
	
	// Retrieve information from Trie for rounds, type, and gun_type
	new ammo = GetAmmoInfo[ROUNDS];
	new type = GetAmmoInfo[TYPE];
	new weapontype = GetAmmoInfo[GUN_TYPE];
	
	decl String:WeaponName[64];
	WeaponName[0] = '\0';
	
	//new PlayerWeapon;
	
	// Retrieve weapon indexes for slot0 and slot1 weapons from client
	new WeaponSlot0 = Client_GetWeaponBySlot(client, 0); // Rifle Slot
	new WeaponSlot1 = Client_GetWeaponBySlot(client, 1); // Pistol Slot
	
	/* 	If the client has a weapon in slot0 and the GUN_TYPE from the dropped ammo is a RIFLE (or CVar for Allow Mixed Ammo is true), and the ammo type from 
		dropped ammo is the same as the ammo type of the weapon the player has in slot0 */
	if(WeaponSlot0 != -1 && ((weapontype == RIFLES || AllowMixedAmmo) && type == Weapon_GetPrimaryAmmoType(WeaponSlot0)))
	{
		RemoveFromTrie(h_Trie, sEntity); // Remove the information from the Trie since we've already extracted it
		ProcessAmmo2(client, WeaponSlot0, ammo, entity); // See function for details
		
		return;
	}
	
	/* 	If the client has a weapon in slot1 and the GUN_TYPE from the dropped ammo is a PISTOL (or CVar for Allow Mixed Ammo is true), and the ammo type from 
		dropped ammo is the same as the ammo type of the weapon the player has in slot1 */
	if(WeaponSlot1 != -1 && ((weapontype == PISTOLS || AllowMixedAmmo) && type == Weapon_GetPrimaryAmmoType(WeaponSlot1)))
	{
		RemoveFromTrie(h_Trie, sEntity); // Remove the information from the Trie since we've already extracted it
		ProcessAmmo2(client, WeaponSlot1, ammo, entity); // See function for details
		
		return;
	}
}

//========================================================================================

/**
 * Function to actually perform the ammo adjustments
 * 
 * @param client			client index
 * @param weapon		weapon index of weapon being touched
 * @param PlayerWeapon	weapon index of player
 */
public ProcessAmmo2(client, PlayerWeapon, ammo, entity)
{
	new PlayerAmmo;
	
	decl String:WeaponName[64];	
	WeaponName[0] = '\0';
	
	GetEntityClassname(PlayerWeapon, WeaponName, sizeof(WeaponName)); // Get classname sting for weapon index
	
	Client_GetWeaponPlayerAmmo(client, WeaponName, PlayerAmmo); // Store the ammo the player currently has

	Client_SetWeaponPlayerAmmo(client, WeaponName, ammo + PlayerAmmo); // Increase the ammo by the amount they just picked up from the dropped ammo box
	
	EmitSoundToClient(client, "items/ammopickup.wav"); // Audible indication the player picked up ammo
	
	// Get rid of the dropped ammo model and unhook the entity
	if(IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
		SDKUnhook(entity, SDKHook_StartTouch, StartTouch);
	}
}

//========================================================================================

public OnVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	// Make sure the version number is what is set in the compiled plugin, not a config file or changed CVar
	if (!StrEqual(newVal, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

//========================================================================================

public OnBotsDropChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	BotsDropAmmo = GetConVarBool(cvar);
}

//========================================================================================

public OnMixedAmmoChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AllowMixedAmmo = GetConVarBool(cvar);
}

//========================================================================================

public OnPistolDropsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	PistolDrops = GetConVarBool(cvar);
}

//========================================================================================

public OnRifleDropsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	RifleDrops = GetConVarBool(cvar);
}

//========================================================================================