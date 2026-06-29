/* 
* 	DESCRIPTION:
* 		When a player dies, this plugin will drop ammo boxes for the weapon the player was carrying.  Other players 
* 		can pick up this ammo if their gun type matches, or if just their ammo type matches (if set this way).
* 
* 	Change Log:
* 
* 		Version 0.1.0.0
* 			*	Initial proper release on request URL http://forums.alliedmods.net/showthread.php?t=173286
* 
* 		Version 0.1.1.0
* 			*	Changed m_CollisionGroup from COLLISION_GROUP_NONE to COLLISION_GROUP_PLAYER
* 				-	Thanks to GrO for testing and confirming
* 			*	Added an enabled cvar
* 
* 		Version 0.1.1.1
* 			*	Fixed sound not playing - or level was too low... I just removed the level variable.
* 			*	Fixed ammo dropping through floor be redefining SOLID_VPHYSICS (I must have the wrong name for the value of 8)
* 
* 		Version 0.1.1.2
* 			*	Now using the correct definitions for m_usSolidFlags - thanks to KyleS for posting them from the SDK
* 			*	Removed Updater support
* 
*/

//========================================================================================
// INCLUDES
//========================================================================================

#include <sdkhooks>
#include <sdktools>
#include <smlib\clients>

//========================================================================================
// DEFINES
//========================================================================================

#define PLUGIN_VERSION "0.1.1.2"

#define 	PistolAmmo 				"models/items/boxsrounds.mdl"
#define 	OtherAmmo 				"models/items/boxmrounds.mdl"
#define 	SGAmmo 					"models/items/boxbuckshot.mdl"
#define		SOUND_FILE1				"items/itempickup.wav"
#define		SOUND_FILE2				"items/ammo_pickup.wav"

#define		PISTOLS					11
#define		RIFLES					10

//========================================================================================
// HANDLES & VARIABLES
//========================================================================================

new Handle:h_Trie;

new Handle:g_hGiveAmmo;

new SOUND_TYPE;
new SOUND_PLAY;
new bool:Enabled = true;
new bool:BotsDropAmmo = true;
new bool:PistolDrops = true;
new bool:RifleDrops = true;
new bool:AllowMixedAmmo = false;
//new bool:AllowAnyMixedAmmo = false;
new bool:AbideByMaxAmmo = true;

new String:SOUND_FILE[64];

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
	name = "Ammo From Dead",
	author = "TnTSCS aka ClarkKent	",
	description = "Players will drop their extra ammo when they die",
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
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_version", PLUGIN_VERSION, 
	"Version of 'Ammo From Dead'", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_enabled", "1", 
	"Am I enabled?  \n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnEnabledChanged);
	Enabled = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_botsdrop", "1", 
	"Do bots drop ammo?  \n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnBotsDropChanged);
	BotsDropAmmo = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_mixedammo", "1", 
	"Allow player to pickup ammo if \"ammo type\" is the same regardless of if \"gun type\" is different (UMP vs glock)?  \n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnMixedAmmoChanged);
	AllowMixedAmmo = GetConVarBool(hRandom);
	
	/*
	HookConVarChange((hRandom = CreateConVar("sm_afd_anymixedammo", "0", 
	"Allow player to pickup any pistol ammo for any pistol and the same for rifles and shotguns?  This will override sm_afd_mixedammo!!  \n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnAnyMixedAmmoChanged);
	AllowAnyMixedAmmo = GetConVarBool(hRandom);
	*/
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_pistols", "1", 
	"Drop pistol ammo?  \n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnPistolDropsChanged);
	PistolDrops = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_rifles", "1", 
	"Drop rifle (shotty, awp, auto, rifle) ammo?  \n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnRifleDropsChanged);
	RifleDrops = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_maxammo", "1", 
	"Should plugin abide by the weapon's max ammo when picking up dropped ammo?  \nIf yes, then the left over ammo will remain on the ground.  If all of the ammo is picked up, then the ammo box will disappear.  \n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnMaxAmmoChanged);
	AbideByMaxAmmo = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_sound", "1", 
	"Which sound should we play when ammo is picked up?\n1 = hl2/items/itempickup.wav \n2 = hl2/items/ammo_pickup.wav", _, true, 1.0, true, 2.0)), OnSoundTypeChanged);
	SOUND_TYPE = GetConVarInt(hRandom);
	SOUND_FILE = SOUND_FILE1;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_playsound", "1", 
	"Who should hear the sound?\n1 = Only the player \n2 = Everyone in the vicinity (like normal item pickups)", _, true, 1.0, true, 2.0)), OnPlaySoundChanged);
	SOUND_PLAY = GetConVarInt(hRandom);
	
	CloseHandle(hRandom);// KyleS HATES Handles
	
	h_Trie = CreateTrie();
	
	// Courtesy of Peace-Maker - thank you :)
	new Handle:hGameConf = LoadGameConfigFile("giveammo");
	if(hGameConf == INVALID_HANDLE)
	{
		SetFailState("Can't find giveammo.txt gamedata.");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	
	if(!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "GiveAmmo"))
	{
		SetFailState("Can't find CBaseCombatCharacter::GiveAmmo(int, int, bool) offset.");
	}
	
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hGiveAmmo = EndPrepSDKCall();
	
	CloseHandle(hGameConf);
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
	
	PrecacheSound(SOUND_FILE1, true);
	PrecacheSound(SOUND_FILE2, true);
	
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
	if(Enabled)
	{
		// Hook player so we know when a weapon is dropped
		SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
	}
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
	
	// Retrieve the client's health to find out if they're dropping the weapon because they just died or not
	new playerHealth = GetEntProp(client, Prop_Send, "m_iHealth");
	
	// If player is still alive, process drop as normal
	if(playerHealth > 0)
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
	
	// Ensure a successful entity creation - prop_physics_multiplayer
	if((ent = CreateEntityByName("prop_physics_multiplayer")) != -1)
	{
		new Float:origin[3];
		new Float:vel[3];
		
		GetClientEyePosition(client, origin);
		
		// Random throw how Knagg0 made
		vel[0] = GetRandomFloat(-200.0, 200.0);
		vel[1] = GetRandomFloat(-200.0, 200.0);
		vel[2] = GetRandomFloat(1.0, 200.0);
		
		TeleportEntity(ent, origin, NULL_VECTOR, vel); // Teleport ammo box
		
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
		DispatchKeyValue(ent, "massScale", "1.0"); // A scale multiplier for the object's mass, too light and it moves too easy with blasts
		DispatchKeyValue(ent, "targetname", targetname); // The name that other entities refer to this entity by.
		DispatchSpawn(ent); // Spawn the entity
		
		// Set the entity as solid, noclip, and unable to take damage
		SetEntProp(ent, Prop_Send, "m_usSolidFlags", FSOLID_TRIGGER);
		SetEntProp(ent, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
		
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
		
		// Get rid of the dropped ammo model and unhook the entity
		RemoveAmmoModel(entity);
		
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
		ProcessAmmo2(client, WeaponSlot0, ammo, type, weapontype, entity); // See function for details
		
		return;
	}
	
	/* 	If the client has a weapon in slot1 and the GUN_TYPE from the dropped ammo is a PISTOL (or CVar for Allow Mixed Ammo is true), and the ammo type from 
		dropped ammo is the same as the ammo type of the weapon the player has in slot1 */
	if(WeaponSlot1 != -1 && ((weapontype == PISTOLS || AllowMixedAmmo) && type == Weapon_GetPrimaryAmmoType(WeaponSlot1)))
	{
		RemoveFromTrie(h_Trie, sEntity); // Remove the information from the Trie since we've already extracted it
		ProcessAmmo2(client, WeaponSlot1, ammo, type, weapontype, entity); // See function for details
		
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
public ProcessAmmo2(client, PlayerWeapon, ammo, ammoType, weapontype, entity)
{
	new PlayerAmmo;
	
	decl String:WeaponName[64];	
	WeaponName[0] = '\0';
	
	GetEntityClassname(PlayerWeapon, WeaponName, sizeof(WeaponName)); // Get classname sting for weapon index
	
	Client_GetWeaponPlayerAmmo(client, WeaponName, PlayerAmmo); // Store the ammo the player currently has
	
	if(AbideByMaxAmmo)
	{
		/**
		 * GiveAmmo gives ammo of a certain type to a player - duh. (for SDKCall(g_hGiveAmmo)
		 *
		 * @param client		The client index.
		 * @param ammo			Amount of bullets to give. Is capped at weapon's limit.
		 * @param ammotype		Type of ammo to give to player.
		 * @param suppressSound Don't play the ammo pickup sound.
		 * 
		 * @return Amount of bullets actually given.
		 */
		new ret = SDKCall(g_hGiveAmmo, client, ammo, ammoType, true);
		
		if(ret != 0) // Player picked up 1 or more rounds from the ammo box
		{
			PlaySound(client);
		}
		
		if(ret != ammo) // Player only picked up part of the ammo that was in that ammo box
		{		
			new newammo = ammo - ret;
			
			// Convert the entity to a string to create the trie (since it requires a string)
			new String:sEntity[12]
			IntToString(entity, sEntity, sizeof(sEntity));
			
			// Set the ammo information for number of rounds, type of ammo, and gun_type
			new SetAmmoInfo[AmmoAttributes];
			SetAmmoInfo[ROUNDS] = newammo;
			SetAmmoInfo[TYPE] = ammoType;
			SetAmmoInfo[GUN_TYPE] = weapontype;
			
			// Set trie for this entity with ammo information
			SetTrieArray(h_Trie, sEntity, SetAmmoInfo[0], 3, true);
			
			return;
		}
		
		// Get rid of the dropped ammo model and unhook the entity since all of the ammo has been picked up
		RemoveAmmoModel(entity);
	}
	else // Give player all of the ammo since we're not abiding by any ammo limits
	{
		PlaySound(client);
		
		// Increase the ammo by the amount they just picked up from the dropped ammo box
		Client_SetWeaponPlayerAmmo(client, WeaponName, ammo + PlayerAmmo);
		
		// Get rid of the dropped ammo model and unhook the entity
		RemoveAmmoModel(entity);
	}
}

//========================================================================================

public PlaySound(client)
{
	switch(SOUND_PLAY)
	{
		case 1:
		{
			EmitSoundToClient(client, SOUND_FILE); // Play sound only to player
		}
		
		case 2:
		{
			EmitSoundToAll(SOUND_FILE, client); // Play sound to all players within range
		}
	}
}

//========================================================================================


public RemoveAmmoModel(entity)
{
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

public OnEnabledChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Enabled = GetConVarBool(cvar);
	
	switch(Enabled)
	{
		case 0:
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				SDKUnhook(i, SDKHook_WeaponDrop, OnWeaponDrop);
			}
		}
		
		case 1:
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				SDKHook(i, SDKHook_WeaponDrop, OnWeaponDrop);
			}
		}
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
/*
public OnAnyMixedAmmoChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AllowAnyMixedAmmo = GetConVarBool(cvar);
}
*/
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

public OnMaxAmmoChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AbideByMaxAmmo = GetConVarBool(cvar);
}

//========================================================================================

public OnSoundTypeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SOUND_TYPE = GetConVarInt(cvar);
	
	switch(SOUND_TYPE)
	{
		case 1:
		{
			SOUND_FILE = SOUND_FILE1;
		}
		case 2:
		{
			SOUND_FILE = SOUND_FILE2;
		}
	}
}

//========================================================================================

public OnPlaySoundChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SOUND_PLAY = GetConVarInt(cvar);
}

//========================================================================================