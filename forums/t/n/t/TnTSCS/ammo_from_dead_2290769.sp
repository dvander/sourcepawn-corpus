/* 
* 	DESCRIPTION:
* 		When a player dies, this plugin will drop ammo boxes for the weapon the player was carrying.  Other players 
* 		can pick up this ammo if their gun type matches, or if just their ammo type matches (if set this way).  You can also
* 		set a CVar that will allow pistols to be filled by any pistol ammo box dropped, rifles (smgs, machine guns, smg, snipers) to
* 		be filled by any rifle ammo box dropped, and shotguns to be filled by shotgun ammo boxes dropped.
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
* 		Version 0.2.0.0
* 			*	Added CVar to allow players to refill their pistols by running over the pistol ammo box, regardless of ammo-type... same for shotguns and 
* 				rifles (SMGs, machine guns, snipers, and rifles).
* 
* 		Version 0.2.0.1
* 			*	Went through code, added a return in ProcessAmmo2 function and added a few more lines of code  comments
* 			*	Fixed location descriptions for sound files
* 			*	Added Updater ability
* 			*	Public Release
* 
* 		Version 0.2.0.2
* 			*	Addressed bug where too many times the trie would fail when a player touched the ammo box entity.
* 
* 		Version 0.2.1.0
* 			+	Added dissolve feature for dropped ammo boxes (requested by blue zebra)
* 
* 		Version 0.2.1.1
* 			+	Added ability to change scale of models (requested by Allower - https://forums.alliedmods.net/member.php?u=237510)
* 			+	Added ability to use custom models
* 			*	Now using the include for AutoExecConfig to auto add missing config files for updated installations.
* 
* 		Version 0.2.1.2
* 			*	Changed to using API for give ammo instead of gamedata.
* 
* 		Version 0.2.1.3
* 			+	Added weapon_knife to ignore list
* 
* 	SPECIAL THANKS to Gr0 for all of the help provided in making this plugin what it is.  Without the relentless testing by GrO, 
* 	this plugin wouldn't be what it is.  It was his request and input that drove this plugin creation and tweaks.
* 
*/
#pragma semicolon 1
//========================================================================================
// INCLUDES
//========================================================================================

#include <sdkhooks>
#include <sdktools>
#include <smlib\clients>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <updater>

//========================================================================================
// DEFINES
//========================================================================================

#define PLUGIN_VERSION "0.2.1.3"

#define UPDATE_URL "http://dl.dropbox.com/u/3266762/ammo_from_dead.txt"

#define		SOUND_FILE1				"items/itempickup.wav" // cstrike\sound\items
#define		SOUND_FILE2				"items/ammo_pickup.wav" // hl2\sound\items
#define		SOUND_FILE3				"items/ammopickup.wav" // cstrike\sound\items

#define		PISTOLS					11
#define		RIFLES					10
#define		SHOTGUNS				9

//========================================================================================
// HANDLES & VARIABLES
//========================================================================================

new Handle:h_Trie;

//new Handle:g_hGiveAmmo;

new SOUND_TYPE;
new SOUND_PLAY;
new bool:Enabled = true;
new bool:BotsDropAmmo = true;
new bool:PistolDrops = true;
new bool:RifleDrops = true;
new bool:AllowMixedAmmo = false;
new bool:AllowAnyMixedAmmo = false;
new bool:AbideByMaxAmmo = true;
new bool:UseUpdater = false;
new bool:UseModelScale = false;
new bool:UseCustomModels = false;

new String:SOUND_FILE[64];
new String:g_sPistolModel[PLATFORM_MAX_PATH];
new String:g_sOtherModel[PLATFORM_MAX_PATH];
new String:g_sSGModel[PLATFORM_MAX_PATH];

new Float:lifetime = 0.0;
new DestroyMode = 0;
new Float:DisolveType = 0.0;
new Float:ScaleFactor = 1.0;

enum AmmoAttributes
{
ROUNDS,
TYPE,
GUN_TYPE,
RIFLE_TYPE
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
	new bool:appended;
	
	// Set the file for the include
	AutoExecConfig_SetFile("plugin.ammo_from_dead");
	
	// Create this plugins CVars
	new Handle:hRandom;// KyleS HATES handles
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_version", PLUGIN_VERSION, 
	"Version of 'Ammo From Dead'", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_afd_enabled", "1", 
	"Am I enabled?  \n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnEnabledChanged);
	Enabled = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_afd_botsdrop", "1", 
	"Do bots drop ammo?  \n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnBotsDropChanged);
	BotsDropAmmo = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_afd_mixedammo", "1", 
	"Allow player to pickup ammo if \"ammo type\" is the same regardless of if \"gun type\" is different (UMP vs glock)?  \n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnMixedAmmoChanged);
	AllowMixedAmmo = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_afd_anymixedammo", "0", 
	"If ON, players can refill their pistol ammo by picking up any pistol ammo box, same for shotguns with shotgun ammo box, and the same for rifles (SMG, Rifle, Sniper Rifle, and Machine Gun) with rifle ammo box.  \n1=ON, 0=OFF", _, true, 0.0, true, 1.0)), OnAnyMixedAmmoChanged);
	AllowAnyMixedAmmo = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_afd_pistols", "1", 
	"Drop pistol ammo?  \n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnPistolDropsChanged);
	PistolDrops = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_afd_rifles", "1", 
	"Drop rifle (shotty, awp, auto, rifle) ammo?  \n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnRifleDropsChanged);
	RifleDrops = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_afd_maxammo", "1", 
	"Should plugin abide by the weapon's max ammo when picking up dropped ammo?  \nIf yes, then the left over ammo will remain on the ground.  If all of the ammo is picked up, then the ammo box will disappear.  \n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnMaxAmmoChanged);
	AbideByMaxAmmo = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_afd_sound", "1", 
	"Which sound should we play when ammo is picked up?\n1 = cstrike/items/itempickup.wav \n2 = hl2/items/ammo_pickup.wav \n3 = cstrike/items/ammopickup.wav", _, true, 1.0, true, 3.0)), OnSoundTypeChanged);
	SOUND_TYPE = GetConVarInt(hRandom);
	SOUND_FILE = SOUND_FILE1;
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_afd_playsound", "1", 
	"Who should hear the sound?\n1 = Only the player \n2 = Everyone in the vicinity (like normal item pickups)", _, true, 1.0, true, 2.0)), OnPlaySoundChanged);
	SOUND_PLAY = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_afd_useupdater", "0", 
	"Utilize 'Updater' plugin to auto-update Ammo From Dead when updates are published?\n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnUseUpdaterChanged);
	UseUpdater = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_afd_lifetime", "20", 
	"How many seconds ammo model will stay.  Less than 1.0 is disabled.", _, true, 0.0)), OnLifetimeChanged);
	lifetime = GetConVarFloat(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_afd_destroymode", "2", 
	"How should the ammo model be destroyed?\n0 = Do not destroy, leave forever\n1 = Just make disappear\n2 = Use disolve feature.", _, true, 0.0, true, 2.0)), OnDestroyModeChanged);
	DestroyMode = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_afd_disolvetype", "3", 
	"If sm_afd_destroymode=2, choose dissolve type\n0 = Energy\n1 = Heavy electrical\n2 = Light electrical\n3 = Core effect", _, true, 0.0, true, 3.0)), OnDisolveTypeChanged);
	DisolveType = GetConVarFloat(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_afd_usemodelscale", "0", 
	"Scale the ammo model?\n1 = YES\n0 = NO", _, true, 0.0, true, 1.0)), OnUseModelScaleChanged);
	UseModelScale = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_afd_scalefactor", "1.0", 
	"Specify scale factor for model.\n1.0 = Unchanged\n<= 0.9 = Smaller\n>= 1.1 = Larger", _, true, 0.0, true, 5.0)), OnScaleFactorChanged);
	ScaleFactor = GetConVarFloat(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_afd_pistolammo_model", "models/items/boxsrounds.mdl", 
	"Specify the model to use for pistol ammo boxes.")), OnPistolModelChanged);
	GetConVarString(hRandom, g_sPistolModel, sizeof(g_sPistolModel));
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_afd_otherammo_model", "models/items/boxsrounds.mdl", 
	"Specify the model to use for other weapon ammo boxes.")), OnOtherModelChanged);
	GetConVarString(hRandom, g_sOtherModel, sizeof(g_sOtherModel));
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_afd_sgammo_model", "models/items/boxsrounds.mdl", 
	"Specify the model to use for shotgun ammo boxes.")), OnSGModelChanged);
	GetConVarString(hRandom, g_sSGModel, sizeof(g_sSGModel));
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_afd_usecustommodels", "0", 
	"Use models other than default valve models?\n1 = YES\n0 = NO\nIf YES, you must enter all related files into \"sourcemod/configs/ammo_from_dead.ini\"", _, true, 0.0, true, 1.0)), OnUseCustomModelsChanged);
	UseCustomModels = GetConVarBool(hRandom);
	SetAppend(appended);
	
	CloseHandle(hRandom);// KyleS HATES Handles
	
	// Trie to hold ammo information
	h_Trie = CreateTrie();
	/*
	// Courtesy of Peace-Maker - thank you :)
	// This SDKCall will allow the plugin to "GiveAmmo" and adhear to the ammo limits of the gun the player is holding.
	new Handle:hGameConf = LoadGameConfigFile("giveammo");
	if (hGameConf == INVALID_HANDLE)
	{
		SetFailState("Can't find giveammo.txt gamedata.");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "GiveAmmo"))
	{
		SetFailState("Can't find CBaseCombatCharacter::GiveAmmo(int, int, bool) offset.");
	}
	
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hGiveAmmo = EndPrepSDKCall();
	
	CloseHandle(hGameConf);
	*/
	
	AutoExecConfig(true, "plugin.ammo_from_dead");
	
	// Cleaning is an expensive operation and should be done at the end
	if (appended)
	{
		AutoExecConfig_CleanFile();
	}
}

//========================================================================================

SetAppend(&appended)
{
	if (AutoExecConfig_GetAppendResult() == AUTOEXEC_APPEND_SUCCESS)
	{
		appended = true;
	}
}

//========================================================================================

/**
 * Called after a library is added that the current plugin references 
 * optionally. A library is either a plugin name or extension name, as 
 * exposed via its include file.
 *
 * @param name			Library name.
 */
public OnLibraryAdded(const String:name[])
{
	// Check if plugin Updater exists, if it does, add this plugin to its list of managed plugins
	if (UseUpdater && StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
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
	// Check if plugin Updater exists, if it does, add this plugin to its list of managed plugins
	if (UseUpdater && LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	if (UseCustomModels)
	{
		LoadCustomModels();
	}
	
	// Pre-cache the models for the ammo boxes
	PrecacheModel(g_sPistolModel, true);
	PrecacheModel(g_sOtherModel, true);
	PrecacheModel(g_sSGModel, true);
	
	PrecacheSound(SOUND_FILE1, true);
	PrecacheSound(SOUND_FILE2, true);
	PrecacheSound(SOUND_FILE3, true);
	
	// Clear all entries of the Trie
	ClearTrie(h_Trie);
}

LoadCustomModels()
{
	// Open the INI file and add everythin in it to download table
	new String:file[PLATFORM_MAX_PATH];
	new String:buffer[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, file, sizeof(file), "configs/ammo_from_dead.ini");
	
	new Handle:fileh = OpenFile(file, "r"); // List of modes - http://www.cplusplus.com/reference/clibrary/cstdio/fopen/
	
	if (fileh == INVALID_HANDLE)
	{
		SetFailState("ammo_from_dead.ini file missing!!!");
	}
	
	// Go through each line of the file to add the needed files to the downloads table
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{
		TrimString(buffer);
   		
		if (FileExists(buffer))
		{
			AddFileToDownloadsTable(buffer);
		}
		
		if (IsEndOfFile(fileh))
		{
			break;
		}
	}
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
	if (Enabled && IsClientInGame(client))
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
	if (IsClientInGame(client))
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
	// Retrieve the client's health to find out if they're dropping the weapon because they just died or not
	new playerHealth = GetEntProp(client, Prop_Send, "m_iHealth");
	
	// If player is still alive, process drop as normal, since this is "drop ammo on 'death'"
	if (playerHealth > 0)
	{
		return Plugin_Continue;
	}
	
	new String:WeaponName[64];
	
	// Retrieve the weapon name since some SMLib functions require it.
	GetEntityClassname(weapon, WeaponName, sizeof(WeaponName));
	
	// If the weapon being dropped is the C4, knife, or any type of grenade, handle the drop as normal
	if (!strcmp(WeaponName, "weapon_c4", false) || !strcmp(WeaponName, "weapon_hegrenade", false) || 
		!strcmp(WeaponName, "weapon_flashbang", false) || !strcmp(WeaponName, "weapon_smokegrenade", false) ||
		!strcmp(WeaponName, "weapon_knife", false))
	{
		return Plugin_Continue;
	}
	
	// If client is a bot and no ammo drops for bots is set or the weapon index is not a valid entity, handle the weapon drop as normal
	if (!IsValidEntity(weapon) || (IsFakeClient(client) && !BotsDropAmmo))
	{
		return Plugin_Continue;
	}
	
	/* 
	* Since only one weapon will drop on death, we need to look at each one.
	* If a player has both a rifle type and pistol type when they die, they will only drop the rifle.
	* A pistol will drop on death if they only have a pistol and no rifle
	*/
	new WeaponSlot0 = GetPlayerWeaponSlot(client, 0); // Rifle Slot
	new WeaponSlot1 = GetPlayerWeaponSlot(client, 1); // Pistol Slot
	
	// If the weapon being dropped is a rifle, and rifle ammo drops are not allowed, handle the drop as normal
	if (WeaponSlot0 != -1 && (WeaponSlot0 == weapon && !RifleDrops))
	{
		return Plugin_Continue;
	}
	
	// If the weapon being dropped is a pistol, but pistol ammo drops are not allowed, handle the drop as normal
	if (WeaponSlot1 != -1 && (WeaponSlot1 == weapon && !PistolDrops))
	{
		return Plugin_Continue;
	}
	
	new ammo;
	
	// Retrieve the amount of ammo the player has that is 'extra' ammo, not including the amount already loaded in the active clip of the weapon.
	Client_GetWeaponPlayerAmmo(client, WeaponName, ammo);
	
	// If the extra ammo for the weapon is 0, no need to drop an ammo box
	if (ammo == 0)
	{
		return Plugin_Continue;
	}
	
	// Set the extra/reserve ammo for the weapon being dropped to 0 since we're going to be dropping an ammo box with that ammount
	Client_SetWeaponPlayerAmmo(client, WeaponName, 0);
	
	// See function for details
	DropAmmo(weapon, WeaponName, WeaponSlot0, WeaponSlot1, client, ammo);
	
	return Plugin_Continue;
}

//========================================================================================

public DropAmmo(any:weapon, const String:WeaponName[], any:WeaponSlot0, any:WeaponSlot1, any:client, any:ammo)
{
	new ent;
	
	// Ensure a successful entity creation - prop_physics_multiplayer
	if ((ent = CreateEntityByName("prop_physics_multiplayer")) != -1)
	{
		new Float:origin[3];
		new Float:vel[3];
		
		GetClientEyePosition(client, origin);
		
		// Random throw how Knagg0 made
		vel[0] = GetRandomFloat(-200.0, 200.0);
		vel[1] = GetRandomFloat(-200.0, 200.0);
		vel[2] = GetRandomFloat(1.0, 200.0);
		
		TeleportEntity(ent, origin, NULL_VECTOR, vel); // Teleport ammo box
		
		new String:targetname[100];
		
		Format(targetname, sizeof(targetname), "droppedammo_%i", ent); // Create name for entity - droppedammo_ENT#
		
		new weapontype;
		new rifletype;
		
		// If weapon being dropped is a RIFLE type (defined later if a shotgun)
		if (WeaponSlot0 != -1 && WeaponSlot0 == weapon)
		{
			// Set the weapon type to RIFLES so we know what type of gun (pistol or rifle) this ammo dropped from
			weapontype = RIFLES;
			
			if (StrContains(WeaponName, "xm1014") != -1 || StrContains(WeaponName, "m3") != -1)
			{
				// If rifle being dropped is a SHOTGUN, set ammo model's key name to SGAmmo
				DispatchKeyValue(ent, "model", g_sSGModel);
				
				// Set the weapon type to SHOTGUNS so we know this ammo came from a shotgun
				rifletype = SHOTGUNS;
			}
			else
			{
				// Otherwise set ammo model's key name to OtherAmmo
				DispatchKeyValue(ent, "model", g_sOtherModel);
				
				rifletype = RIFLES;
			}
		}
		
		// If weapon being dropped is a PISTOL type
		if (WeaponSlot1 != -1 && WeaponSlot1 == weapon)
		{
			DispatchKeyValue(ent, "model", g_sPistolModel); // Set the model's key name
			weapontype = PISTOLS; // Set the weapon type to PISTOLS so we know what type of gun (pistol or rifle) this ammo dropped from
		}
		
		// Set some of the Key Values of the newly created entity
		DispatchKeyValue(ent, "physicsmode", "2"); // Non-Solid, Server-side
		DispatchKeyValue(ent, "massScale", "8.0"); // A scale multiplier for the object's mass, too light and it moves too easy with blasts
		DispatchKeyValue(ent, "targetname", targetname); // The name that other entities refer to this entity by.
		DispatchSpawn(ent); // Spawn the entity
		
		if (UseModelScale)
		{
			SetEntPropFloat(ent, Prop_Send, "m_flModelScale", ScaleFactor);
		}
		
		#if 0
		Entity_SetOwner(ent, client);
		
		new Float:mins[3], Float:maxs[3];
		Entity_GetMinSize(ent, mins);
		Entity_GetMaxSize(ent, maxs);
		
		PrintToChatAll("Ammo min is %f, %f, %f", mins[0], mins[1], mins[2]);
		PrintToChatAll("Ammo max is %f, %f, %f", maxs[0], maxs[1], maxs[2]);
		
		ScaleVector(mins, 0.50);
		ScaleVector(maxs, 0.50);
		
		PrintToChatAll("Ammo scaled min is %f, %f, %f", mins[0], mins[1], mins[2]);
		PrintToChatAll("Ammo scaled max is %f, %f, %f", maxs[0], maxs[1], maxs[2]);
		
		Entity_SetMinMaxSize(ent, mins, maxs);
		
		//new enteffects = GetEntProp(ent, Prop_Send, "m_fEffects");
		//enteffects |= 32;
		//SetEntProp(ent, Prop_Send, "m_fEffects", enteffects);
		
		//Entity_SetMinSize(ent, mins);
		//Entity_SetMaxSize(ent, maxs);
		#endif
		
		
		// Thanks to Bacardi for this code from his Healthkit from dead
		if (DestroyMode > 0 && lifetime > 0.9)
		{
			if (DestroyMode == 2) // Disolve Effect
			{
				new entd;
				
				if ((entd = CreateEntityByName("env_entity_dissolver")) != -1)
				{
					DispatchKeyValueFloat(entd, "dissolvetype", DisolveType);
					
					DispatchKeyValue(entd, "magnitude", "250"); // How strongly to push away from the center. Maybe not work
					DispatchKeyValue(entd, "target", targetname); // "Targetname of the entity you want to dissolve."
					
					// Parent dissolver to healthkit. When entity destroyed, dissolver also.
					TeleportEntity(entd, origin, NULL_VECTOR, NULL_VECTOR);
					SetVariantString("!activator");
					AcceptEntityInput(entd, "SetParent", ent);
					
					Format(targetname, sizeof(targetname), "OnUser1 !self:Dissolve::%0.2f:-1", lifetime); // Delay dissolve
					SetVariantString(targetname);
					AcceptEntityInput(entd, "AddOutput");
					
					AcceptEntityInput(entd, "FireUser1");
				}
			}
			else // Just make disappear
			{
				Format(targetname, sizeof(targetname), "OnUser1 !self:kill::%0.2f:-1", lifetime);
				SetVariantString(targetname);
				AcceptEntityInput(ent, "AddOutput");
				AcceptEntityInput(ent, "FireUser1");
			}
		}
		
		// Set the entity as solid, noclip, and unable to take damage
		SetEntProp(ent, Prop_Send, "m_usSolidFlags", FSOLID_TRIGGER);
		SetEntProp(ent, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_WEAPON);
		
		// Get the ammo type of the weapon being dropped
		new type = Weapon_GetPrimaryAmmoType(weapon);
		
		// Convert the entity to a string to create the trie (since it requires a string)
		new String:sEntity[25];
		
		IntToString(ent, sEntity, sizeof(sEntity));
		
		// Set the ammo information for number of rounds, type of ammo, and gun_type for the Trie
		new SetAmmoInfo[AmmoAttributes];
		SetAmmoInfo[ROUNDS] = ammo;
		SetAmmoInfo[TYPE] = type;
		SetAmmoInfo[GUN_TYPE] = weapontype;
		SetAmmoInfo[RIFLE_TYPE] = rifletype;
		
		// Set trie for this entity with ammo information
		SetTrieArray(h_Trie, sEntity, SetAmmoInfo[0], 4, true);
		
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
	new String:model[128];
	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
	
	// Make sure "other" is a valid client/player and that the entity being touched is a dropped ammo model (droppedammo_ENT#)
	if (other > 0 && other <= MaxClients && (StrEqual(model, g_sPistolModel) || StrEqual(model, g_sSGModel) || StrEqual(model, g_sOtherModel)))
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
	new String:sEntity[25];
	
	IntToString(entity, sEntity, sizeof(sEntity));
	
	new GetAmmoInfo[AmmoAttributes];

	// Retrieves the stored information for the dropped ammo entity if it exists in the array GetAmmoInfo
	if (!GetTrieArray(h_Trie, sEntity, GetAmmoInfo[0], 4))
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
	new rifletype = GetAmmoInfo[RIFLE_TYPE];
	
	// Retrieve weapon indexes for slot0 and slot1 weapons from client
	new WeaponSlot0 = GetPlayerWeaponSlot(client, 0); // Rifle Slot
	new WeaponSlot1 = GetPlayerWeaponSlot(client, 1); // Pistol Slot
	
	/* 	If the client has a weapon in slot0 and the GUN_TYPE from the dropped ammo is a RIFLE (or CVar for Allow Mixed Ammo is true), and the ammo type from 
	*	dropped ammo is the same as the ammo type of the weapon the player has in slot0
	*	
	*	Or if the client has a weapon is slot0 and the GUN_TYPE from the dropped ammos is a RIFLE and AllowAnyMixedAmmo is true
	*/	
	if (WeaponSlot0 != -1 && ((weapontype == RIFLES && AllowAnyMixedAmmo && rifletype == RIFLES) || 
		((weapontype == RIFLES || AllowMixedAmmo) && type == Weapon_GetPrimaryAmmoType(WeaponSlot0))))
	{
		if (AllowAnyMixedAmmo)
		{
			type = Weapon_GetPrimaryAmmoType(WeaponSlot0);
		}
		
		ProcessAmmo2(client, WeaponSlot0, ammo, type, weapontype, entity); // See function for details
		
		return;
	}
	
	/* 	If the client has a weapon in slot1 and the GUN_TYPE from the dropped ammo is a PISTOL (or CVar for Allow Mixed Ammo is true), and the ammo type from 
	*	dropped ammo is the same as the ammo type of the weapon the player has in slot1 
	*	
	*	Or if the client has a weapon is slot1 and the GUN_TYPE from the dropped ammos is a PISTOL and AllowAnyMixedAmmo is true
	*/
	if (WeaponSlot1 != -1 && ((weapontype == PISTOLS && AllowAnyMixedAmmo) || 
		((weapontype == PISTOLS || AllowMixedAmmo) && type == Weapon_GetPrimaryAmmoType(WeaponSlot1))))
	{
		if (AllowAnyMixedAmmo)
		{
			type = Weapon_GetPrimaryAmmoType(WeaponSlot1);
		}
		
		//RemoveFromTrie(h_Trie, sEntity); // Remove the information from the Trie since we've already extracted it
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
	
	new String:WeaponName[64];
	
	// Get classname sting for weapon index
	GetEntityClassname(PlayerWeapon, WeaponName, sizeof(WeaponName));
	
	// Store the ammo the player currently has
	Client_GetWeaponPlayerAmmo(client, WeaponName, PlayerAmmo);
	
	// Convert the entity to a string to create the trie (since it requires a string)
	new String:sEntity[25];

	IntToString(entity, sEntity, sizeof(sEntity));
	
	// If AbideByMaxAmmo, then we don't give more ammo than what the max is for that gun.
	if (AbideByMaxAmmo)
	{
		new ret = GivePlayerAmmo(client, ammo, ammoType, true);
		
		if (ret != 0) // Player picked up 1 or more rounds from the ammo box
		{
			PlaySound(client);
		}
		else
		{
			// The player didn't pick up any ammo from that box because they already have the maximum amount of ammo allowed for that gun.
			return;
		}
		
		if (ret != ammo) // Player only picked up a portion of the ammo that was in that ammo box
		{
			// Figure out how much ammo is left after the player took some
			new newammo = ammo - ret;
			
			// Set the new ammo information for number of rounds, type of ammo, and gun_type
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
		RemoveFromTrie(h_Trie, sEntity); // Remove the information from the Trie since we're done with it
	}
	else // Give player all of the ammo since we're not abiding by any ammo limits
	{
		PlaySound(client);
		
		// Increase the ammo by the amount they just picked up from the dropped ammo box
		Client_SetWeaponPlayerAmmo(client, WeaponName, ammo + PlayerAmmo);
		
		// Get rid of the dropped ammo model and unhook the entity
		RemoveAmmoModel(entity);
		RemoveFromTrie(h_Trie, sEntity); // Remove the information from the Trie since we're done with it
	}
}

//========================================================================================

public PlaySound(client)
{
	switch (SOUND_PLAY)
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
	if (IsValidEntity(entity))
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

public OnAnyMixedAmmoChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AllowAnyMixedAmmo = GetConVarBool(cvar);
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
		case 3:
		{
			SOUND_FILE = SOUND_FILE3;
		}
	}
}

//========================================================================================

public OnPlaySoundChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SOUND_PLAY = GetConVarInt(cvar);
}

//========================================================================================

public OnUseUpdaterChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseUpdater = GetConVarBool(cvar);
}

//========================================================================================

public OnLifetimeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	lifetime = GetConVarFloat(cvar);
}

//========================================================================================

public OnDestroyModeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	DestroyMode = GetConVarInt(cvar);
}

//========================================================================================

public OnDisolveTypeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	DisolveType = GetConVarFloat(cvar);
}

//========================================================================================

public OnUseModelScaleChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseModelScale = GetConVarBool(cvar);
}

//========================================================================================

public OnScaleFactorChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	ScaleFactor = GetConVarFloat(cvar);
}

//========================================================================================

public OnPistolModelChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GetConVarString(cvar, g_sPistolModel, sizeof(g_sPistolModel));
}

//========================================================================================

public OnOtherModelChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GetConVarString(cvar, g_sOtherModel, sizeof(g_sOtherModel));
}

//========================================================================================

public OnSGModelChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GetConVarString(cvar, g_sSGModel, sizeof(g_sSGModel));
}

//========================================================================================

public OnUseCustomModelsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseCustomModels = GetConVarBool(cvar);
}

//========================================================================================