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
* 			+	Added dissolve feature for dropped ammo boxes (requested by blue zebra), using Bacardi's method from Healthkit from dead.
* 
* 		Version 0.2.1.1
* 			+	Added dissolve feature for dropped weapons (requested by blue zebra).
* 
*		Version 0.2.1.2
* 			*	Changed the prop type to avoid the mayhem bug and changed to collision alteration to before the prop is spawned.
* 
* 		Version 0.2.1.3
* 			*	Fixed error in code that stopped the ammo boxes from working after being touched once.
* 			*	Fixed the bug where shotguns could pickup rifle ammo
* 
* 		Version 0.2.1.4
* 			*	Fixed gamedata file - plugin now requires SM 1.4.4
* 
* 		Version 0.2.1.5
* 			*	Fixed gamedata file for 02/05/13 CS:S update
* 
* 		Version 0.2.1.6
* 			*	Fixed gamedata file for 04/16/13 CS:S update
* 
* 		Version 0.2.1.7
* 			*	Refixed gamedata file for 04/16/2013 CS:S update
* 
* 		Version 0.2.1.8
* 			*	Removed left over debug command
* 
* 		Version 0.2.1.9
* 			*	Gamedata-less and SMLIB-less - by Shadowysn (I didn't find StrikerMan's version or the GD-less fork by TnTSCS until I finished this edit by myself sorry)
* 			*	Updater functionality removed since plugin has not seen any updates in a long time.
* 				It can still be re-enabled by USE_UPDATER define. - by Shadowysn
* 
* 			=	TnTSCS FORK MERGE: https://forums.alliedmods.net/showpost.php?p=2194313&postcount=150
* 			+	Added ability to change scale of models (requested by Allower - https://forums.alliedmods.net/member.php?u=237510)
* 			+	Added ability to use and send custom models to the download table
* 
* 			=	TnTSCS FORK MERGE: https://forums.alliedmods.net/showpost.php?p=2290769&postcount=157
* 			+	Added weapon_knife to ignore list
* 
* 			=	TnTSCS FORK MERGE: https://forums.alliedmods.net/showpost.php?p=2291478&postcount=167
* 			+	Enhanced ammo box model scale to have separate values for Pistols, Rifles, and Shotguns.
* 
* 			*	Fixed the physics of the scaled models not being scaled as well, causing the 'floaty' issue described in 
* 				https://forums.alliedmods.net/showpost.php?p=2295070&postcount=176 - by Shadowysn
* 
* 			=	Suggested by pubhero: https://forums.alliedmods.net/member.php?u=193144
* 			+	Team-based color can be applied to the ammo boxes using sm_afd_color_t and sm_afd_color_ct cvars - by Shadowysn
* 			+	Team-based pickup restriction functionality, use sm_afd_team_restrict - by Shadowysn
* 			+	Ammo can now have velocity/damage parameters set with the sm_afd_damagemode cvar - by Shadowysn
* 			+	Ammo can now have health which takes effect in sm_afd_damagemode 2, using the sm_afd_health cvar.
* 				When destroyed, dust particle effects and broken brass/shells based on ammo count will be spawned.
* 				NOTE: These effects will not be spawned if the ammo box wasn't shot or exploded - by Shadowysn
* 
* 	SPECIAL THANKS to Gr0 for all of the help provided in making this plugin what it is.  Without the relentless testing by GrO, 
* 	this plugin wouldn't be what it is.  It was his request and input that drove this plugin creation and tweaks.
* 
*/

//========================================================================================
// INCLUDES
//========================================================================================

#define USE_UPDATER 0 // Should be defined here so updater include can be excluded

#include <sdkhooks>
#include <sdktools>
//#include <smlib\clients> // obsoleted by new SM functions and basic netprops
#if USE_UPDATER
#undef REQUIRE_PLUGIN
#include <updater>
#endif

#pragma semicolon 1
#pragma newdecls required

//========================================================================================
// DEFINES
//========================================================================================

#define PLUGIN_VERSION "0.2.1.9"

#define UPDATE_URL "http://dl.dropbox.com/u/3266762/ammo_from_dead.txt"

#define USE_CUST_MODEL_FORK 1

#define 	DefaultPistolAmmo 			"models/items/boxsrounds.mdl"	// Default model
#define 	DefaultOtherAmmo 				"models/items/boxmrounds.mdl"	// Default model
#define 	DefaultSGAmmo 				"models/items/boxbuckshot.mdl"	// Default model
#define		SOUND_FILE1				"items/itempickup.wav" // cstrike\sound\items
#define		SOUND_FILE2				"items/ammo_pickup.wav" // hl2\sound\items
#define		SOUND_FILE3				"items/ammopickup.wav" // cstrike\sound\items

#define		PISTOLS					11
#define		RIFLES					10
#define		SHOTGUNS				9

#define		TEAM_T	2
#define		TEAM_CT	3

//========================================================================================
// HANDLES & VARIABLES
//========================================================================================

StringMap h_Trie;

int SOUND_TYPE;
int SOUND_PLAY;
bool Enabled = true;
bool BotsDropAmmo = true;
bool PistolDrops = true;
bool RifleDrops = true;
bool AllowMixedAmmo = false;
bool AllowAnyMixedAmmo = false;
bool AbideByMaxAmmo = true;
#if USE_UPDATER
bool UseUpdater = false;
#endif
#if USE_CUST_MODEL_FORK
bool UseCustomModels = false;
#endif

char SOUND_FILE[64];
#if USE_CUST_MODEL_FORK
char g_sPistolModel[PLATFORM_MAX_PATH];
char g_sOtherModel[PLATFORM_MAX_PATH];
char g_sSGModel[PLATFORM_MAX_PATH];
float ScaleFactorPistol,
ScaleFactorRifle,
ScaleFactorShotgun = 1.0;
#endif

float lifetime;
int DestroyMode;
float DisolveType;

int GunDestroyMode;
float gunlifetime,
GunDisolveType;

int ammoDamageMode;
int ammoHealth = 100;
char ammoColorT[12];
char ammoColorCT[12];
int teamRestrict;

enum AmmoAttributes
{
	ROUNDS,
	TYPE,
	GUN_TYPE,
	RIFLE_TYPE
};

//========================================================================================
//========================================================================================

public Plugin myinfo = 
{
	name = "Ammo From Dead",
	author = "TnTSCS aka ClarkKent",
	description = "Players will drop their extra ammo when they die",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

bool g_bLateLoad;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_CSS)
	{
		g_bLateLoad = late;
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Counter-Strike Source.");
	return APLRes_SilentFailure;
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
public void OnPluginStart()
{
	// Create this plugins CVars
	ConVar hRandom;// KyleS HATES handles
	ConVar hEnabled;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_version", PLUGIN_VERSION, 
	"Version of 'Ammo From Dead'", FCVAR_NONE | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hEnabled = CreateConVar("sm_afd_enabled", "1", 
	"Am I enabled?  \n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnEnabledChanged);
	Enabled = hEnabled.BoolValue;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_botsdrop", "1", 
	"Do bots drop ammo?  \n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnBotsDropChanged);
	BotsDropAmmo = hRandom.BoolValue;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_mixedammo", "1", 
	"Allow player to pickup ammo if \"ammo type\" is the same regardless of if \"gun type\" is different (UMP vs glock)?  \n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnMixedAmmoChanged);
	AllowMixedAmmo = hRandom.BoolValue;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_anymixedammo", "0", 
	"If ON, players can refill their pistol ammo by picking up any pistol ammo box, same for shotguns with shotgun ammo box, and the same for rifles (SMG, Rifle, Sniper Rifle, and Machine Gun) with rifle ammo box.  \n1=ON, 0=OFF", _, true, 0.0, true, 1.0)), OnAnyMixedAmmoChanged);
	AllowAnyMixedAmmo = hRandom.BoolValue;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_pistols", "1", 
	"Drop pistol ammo?  \n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnPistolDropsChanged);
	PistolDrops = hRandom.BoolValue;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_rifles", "1", 
	"Drop rifle (shotty, awp, auto, rifle) ammo?  \n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnRifleDropsChanged);
	RifleDrops = hRandom.BoolValue;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_maxammo", "1", 
	"Should plugin abide by the weapon's max ammo when picking up dropped ammo?  \nIf yes, then the left over ammo will remain on the ground.  If all of the ammo is picked up, then the ammo box will disappear.  \n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnMaxAmmoChanged);
	AbideByMaxAmmo = hRandom.BoolValue;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_sound", "1", 
	"Which sound should we play when ammo is picked up?\n1 = cstrike/items/itempickup.wav \n2 = hl2/items/ammo_pickup.wav \n3 = cstrike/items/ammopickup.wav", _, true, 1.0, true, 3.0)), OnSoundTypeChanged);
	SOUND_TYPE = hRandom.IntValue;
	SOUND_FILE = SOUND_FILE1;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_playsound", "1", 
	"Who should hear the sound?\n1 = Only the player \n2 = Everyone in the vicinity (like normal item pickups)", _, true, 1.0, true, 2.0)), OnPlaySoundChanged);
	SOUND_PLAY = hRandom.IntValue;
	#if USE_UPDATER
	HookConVarChange((hRandom = CreateConVar("sm_afd_useupdater", "0", 
	"Utilize 'Updater' plugin to auto-update Ammo From Dead when updates are published?\n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnUseUpdaterChanged);
	UseUpdater = hRandom.BoolValue;
	#endif
	HookConVarChange((hRandom = CreateConVar("sm_afd_lifetime", "20", 
	"How many seconds ammo model will stay.  Less than 1.0 is disabled.", _, true, 0.0)), OnLifetimeChanged);
	lifetime = hRandom.FloatValue;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_destroymode", "0", 
	"How should the ammo model be destroyed?\n0 = Do not destroy, leave forever\n1 = Just disappear\n2 = Use dissolve feature.", _, true, 0.0, true, 2.0)), OnDestroyModeChanged);
	DestroyMode = hRandom.IntValue;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_disolvetype", "3", 
	"If sm_afd_destroymode=2, choose dissolve type\n0 = Energy\n1 = Heavy electrical\n2 = Light electrical\n3 = Core effect", _, true, 0.0, true, 3.0)), OnDisolveTypeChanged);
	DisolveType = hRandom.FloatValue;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_gunlifetime", "20", 
	"How many seconds gun model will stay.  Less than 1.0 is disabled.", _, true, 0.0)), OnGunLifetimeChanged);
	gunlifetime = hRandom.FloatValue;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_gundestroymode", "0", 
	"How should the gun model be destroyed?\n0 = Do not destroy, leave forever\n1 = Just disappear\n2 = Use dissolve feature.", _, true, 0.0, true, 2.0)), OnGunDestroyModeChanged);
	GunDestroyMode = hRandom.IntValue;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_gundissolvetype", "3", 
	"If sm_afd_destroymode=2, choose dissolve type\n0 = Energy\n1 = Heavy electrical\n2 = Light electrical\n3 = Core effect", _, true, 0.0, true, 3.0)), OnGunDisolveTypeChanged);
	GunDisolveType = hRandom.FloatValue;
	// Ported from Version 0.2.1.1 fork https://forums.alliedmods.net/showpost.php?p=2194313&postcount=150
	#if USE_CUST_MODEL_FORK
	HookConVarChange((hRandom = CreateConVar("sm_afd_scalefactor_pistol", "1.0", 
	"Specify scale factor for pistol ammo box model.\n1.0 = Unchanged\n<= 0.9 = Smaller\n>= 1.1 = Larger", _, true, 0.0, true, 5.0)), OnScaleFactorPistolChanged);
	ScaleFactorPistol = hRandom.FloatValue;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_scalefactor_rifle", "1.0", 
	"Specify scale factor for rifle ammo box model.\n1.0 = Unchanged\n<= 0.9 = Smaller\n>= 1.1 = Larger", _, true, 0.0, true, 5.0)), OnScaleFactorRifleChanged);
	ScaleFactorRifle = hRandom.FloatValue;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_scalefactor_shotgun", "1.0", 
	"Specify scale factor for shotgun ammo box model.\n1.0 = Unchanged\n<= 0.9 = Smaller\n>= 1.1 = Larger", _, true, 0.0, true, 5.0)), OnScaleFactorShotgunChanged);
	ScaleFactorShotgun = hRandom.FloatValue;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_pistolammo_model", DefaultPistolAmmo, 
	"Specify the model to use for pistol ammo boxes.")), OnPistolModelChanged);
	hRandom.GetString(g_sPistolModel, sizeof(g_sPistolModel));
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_otherammo_model", DefaultOtherAmmo, 
	"Specify the model to use for other weapon ammo boxes.")), OnOtherModelChanged);
	hRandom.GetString(g_sOtherModel, sizeof(g_sOtherModel));
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_sgammo_model", DefaultSGAmmo, 
	"Specify the model to use for shotgun ammo boxes.")), OnSGModelChanged);
	hRandom.GetString(g_sSGModel, sizeof(g_sSGModel));
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_usecustommodels", "0", 
	"Use models other than default valve models?\n1 = YES\n0 = NO\nIf YES, you must enter all related files into \"sourcemod/configs/ammo_from_dead.ini\"", _, true, 0.0, true, 1.0)), OnUseCustomModelsChanged);
	UseCustomModels = hRandom.BoolValue;
	#endif
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_damagemode", "1", 
	"How do ammo boxes handle damage/velocity from shots or explosions?\n0 = No effect.\n1 = Velocity only.\n2 = Velocity + health.", _, true, 0.0, true, 2.0)), OnAmmoDamageModeChanged);
	ammoDamageMode = hRandom.IntValue;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_health", "100", 
	"If sm_afd_damagemode=2, the health for all ammo boxes.", _, true, 1.0)), OnAmmoHealthChanged);
	ammoHealth = hRandom.IntValue;
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_color_t", "255 127 127", 
	"The color for all ammo boxes dropped by Terrorists. Set to 0 for no color.")), OnAmmoColorChangedT);
	hRandom.GetString(ammoColorT, sizeof(ammoColorT));
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_color_ct", "127 127 255", 
	"The color for all ammo boxes dropped by Counter-Terrorists. Set to 0 for no color.")), OnAmmoColorChangedCT);
	hRandom.GetString(ammoColorCT, sizeof(ammoColorCT));
	
	HookConVarChange((hRandom = CreateConVar("sm_afd_team_restrict", "0", 
	"Set who can pick up ammo packs based on team.\n0 = Everyone.\n1 = Pickup your team only.\n2 = Pickup opposite team only.", _, true, 0.0, true, 2.0)), OnTeamRestrictChanged);
	teamRestrict = hRandom.IntValue;
	
	CloseHandle(hRandom);// KyleS HATES Handles
	
	// Trie to hold ammo information
	h_Trie = CreateTrie();
	
	// Execute the config file, and let it autoname it
	AutoExecConfig(true);
	
	if (g_bLateLoad)
	{ OnEnabledChanged(hEnabled, "", ""); }
	CloseHandle(hEnabled);
	
	HookEntityOutput("prop_physics", "OnBreak", OnAmmoBreak);
}

public void OnPluginEnd()
{
	UnhookEntityOutput("prop_physics", "OnBreak", OnAmmoBreak);
}

//========================================================================================

/**
 * Called after a library is added that the current plugin references 
 * optionally. A library is either a plugin name or extension name, as 
 * exposed via its include file.
 *
 * @param name			Library name.
 */
#if USE_UPDATER
public void OnLibraryAdded(const char[] name)
{
	// Check if plugin Updater exists, if it does, add this plugin to its list of managed plugins
	if (UseUpdater && strcmp(name, "updater") == 0)
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
#endif
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
public void OnConfigsExecuted()
{
	#if USE_UPDATER
	// Check if plugin Updater exists, if it does, add this plugin to its list of managed plugins
	if (UseUpdater && LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
	#if USE_CUST_MODEL_FORK
	if (UseCustomModels)
	{
		LoadCustomModels();
	}
	#endif
	// Pre-cache the models for the ammo boxes
	#if USE_CUST_MODEL_FORK
	PrecacheModel(g_sPistolModel, true);
	PrecacheModel(g_sOtherModel, true);
	PrecacheModel(g_sSGModel, true);
	#else
	PrecacheModel(DefaultPistolAmmo, true);
	PrecacheModel(DefaultOtherAmmo, true);
	PrecacheModel(DefaultSGAmmo, true);
	#endif
	
	PrecacheSound(SOUND_FILE1, true);
	PrecacheSound(SOUND_FILE2, true);
	PrecacheSound(SOUND_FILE3, true);
	
	// Clear all entries of the Trie
	ClearTrie(h_Trie);
}
#if USE_CUST_MODEL_FORK
void LoadCustomModels()
{
	// Open the INI file and add everythin in it to download table
	char fileStr[PLATFORM_MAX_PATH];
	char buffer[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, fileStr, sizeof(fileStr), "configs/ammo_from_dead.ini");
	
	Handle fileh = OpenFile(fileStr, "r"); // List of modes - http://www.cplusplus.com/reference/clibrary/cstdio/fopen/
	
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
#endif
//========================================================================================

/**
 * Called when a client is entering the game.
 *
 * Whether a client has a steamid is undefined until OnClientAuthorized
 * is called, which may occur either before or after OnClientPutInServer.
 * Similarly, use OnClientPostAdminCheck() if you need to verify whether 
 * connecting players are admins.
 *
 * GetClientCount() will include clients as they are passed through this 
 * function, as clients are already in game at this point.
 *
 * @param client        Client index.
 */
public void OnClientPutInServer(int client)
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
public void OnClientDisconnect(int client)
{
	// You still need to check IsClientInGame(client) if you want to do the client specific stuff (exvel)
	if (Enabled && IsClientInGame(client))
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
Action OnWeaponDrop(int client, int weapon)
{
	// Retrieve the client's health to find out if they're dropping the weapon because they just died or not
	int playerHealth = GetEntProp(client, Prop_Send, "m_iHealth");
	
	// If player is still alive, process drop as normal, since this is "drop ammo on 'death'"
	if (playerHealth > 0)
	{
		return Plugin_Continue;
	}
	
	char WeaponName[64];
	
	// Retrieve the weapon name since some SMLib functions require it.
	GetEntityClassname(weapon, WeaponName, sizeof(WeaponName));
	
	// If the weapon being dropped is the C4, knife, or any type of grenade, handle the drop as normal
	if (strcmp(WeaponName, "weapon_c4", false) == 0 || 
		strcmp(WeaponName, "weapon_hegrenade", false) == 0 || 
		strcmp(WeaponName, "weapon_flashbang", false) == 0 || 
		strcmp(WeaponName, "weapon_smokegrenade", false) == 0 ||
		strcmp(WeaponName, "weapon_knife", false) == 0)
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
	
	int WeaponSlot0 = GetPlayerWeaponSlot(client, 0); // Rifle Slot
	int WeaponSlot1 = GetPlayerWeaponSlot(client, 1); // Pistol Slot
	
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
	
	// Retrieve the amount of ammo the player has that is 'extra' ammo, not including the amount already loaded in the active clip of the weapon.
	int ammo = GetWeaponPlayerAmmo(client, weapon);
	
	// If the extra ammo for the weapon is 0, no need to drop an ammo box
	if (ammo == 0)
	{
		return Plugin_Continue;
	}
	
	// Set the extra/reserve ammo for the weapon being dropped to 0 since we're going to be dropping an ammo box with that ammount
	SetWeaponPlayerAmmo(client, weapon, 0);
	
	// See function for details
	DropAmmo(weapon, WeaponName, WeaponSlot0, WeaponSlot1, client, ammo);
	
	if (GunDestroyMode > 0 && gunlifetime > 0.9)
	{
		float origin[3];
		
		GetClientEyePosition(client, origin);
		
		Format(WeaponName, sizeof(WeaponName), "droppedgun_%i", weapon);
		DispatchKeyValue(weapon, "targetname", WeaponName);
		
		if (GunDestroyMode == 2) // Disolve Effect
		{
			int entd;
			
			if ((entd = CreateEntityByName("env_entity_dissolver")) != -1)
			{
				DispatchKeyValueFloat(entd, "dissolvetype", GunDisolveType);
				
				DispatchKeyValue(entd, "magnitude", "250"); // How strongly to push away from the center. Maybe not work
				DispatchKeyValue(entd, "target", WeaponName); // "Targetname of the entity you want to dissolve."
				
				// Parent dissolver to healthkit. When entity destroyed, dissolver also.
				TeleportEntity(entd, origin, NULL_VECTOR, NULL_VECTOR);
				SetVariantString("!activator");
				AcceptEntityInput(entd, "SetParent", weapon);
				
				Format(WeaponName, sizeof(WeaponName), "OnUser1 !self:Dissolve::%0.2f:-1", gunlifetime); // Delay dissolve
				SetVariantString(WeaponName);
				AcceptEntityInput(entd, "AddOutput");
				
				AcceptEntityInput(entd, "FireUser1");
			}
		}
		else // Just make disappear
		{
			Format(WeaponName, sizeof(WeaponName), "OnUser1 !self:kill::%0.2f:-1", gunlifetime);
			SetVariantString(WeaponName);
			AcceptEntityInput(weapon, "AddOutput");
			AcceptEntityInput(weapon, "FireUser1");
		}
	}
	
	return Plugin_Continue;
}

//========================================================================================

void DropAmmo(int weapon, const char[] WeaponName, int WeaponSlot0, int WeaponSlot1, int client, int ammo)
{
	int ent;
	
	// Ensure a successful entity creation - prop_physics_multiplayer
	if ((ent = CreateEntityByName("prop_physics")) != -1) // _multiplayer
	{
		float origin[3];
		float vel[3];
		
		GetClientEyePosition(client, origin);
		
		// Random throw how Knagg0 made
		vel[0] = GetRandomFloat(-200.0, 200.0);
		vel[1] = GetRandomFloat(-200.0, 200.0);
		vel[2] = GetRandomFloat(1.0, 200.0);
		
		TeleportEntity(ent, origin, NULL_VECTOR, vel); // Teleport ammo box
		
		char targetname[100];
		
		Format(targetname, sizeof(targetname), "droppedammo_%i", ent); // Create name for entity - droppedammo_ENT#
		
		int weapontype, rifletype;
		
		// If weapon being dropped is a RIFLE type (defined later if a shotgun)
		if (WeaponSlot0 != -1 && WeaponSlot0 == weapon)
		{
			// Set the weapon type to RIFLES so we know what type of gun (pistol or rifle) this ammo dropped from
			weapontype = RIFLES;
			
			if (strcmp(WeaponName, "weapon_xm1014", false) == 0 || strcmp(WeaponName, "weapon_m3", false) == 0)
			{
				// If rifle being dropped is a SHOTGUN, set ammo model's key name to SGAmmo
				#if USE_CUST_MODEL_FORK
				DispatchKeyValue(ent, "model", g_sSGModel);
				#else
				DispatchKeyValue(ent, "model", DefaultSGAmmo);
				#endif
				
				// Set the weapon type to SHOTGUNS so we know this ammo came from a shotgun
				rifletype = SHOTGUNS;
			}
			else
			{
				// Otherwise set ammo model's key name to OtherAmmo
				#if USE_CUST_MODEL_FORK
				DispatchKeyValue(ent, "model", g_sOtherModel);
				#else
				DispatchKeyValue(ent, "model", DefaultOtherAmmo);
				#endif
				
				rifletype = RIFLES;
			}
		}
		
		// If weapon being dropped is a PISTOL type
		if (WeaponSlot1 != -1 && WeaponSlot1 == weapon)
		{
			// Set the model's key name
			#if USE_CUST_MODEL_FORK
			DispatchKeyValue(ent, "model", g_sPistolModel);
			#else
			DispatchKeyValue(ent, "model", DefaultPistolAmmo);
			#endif
			weapontype = PISTOLS; // Set the weapon type to PISTOLS so we know what type of gun (pistol or rifle) this ammo dropped from
		}
		
		// Set some of the Key Values of the newly created entity
		DispatchKeyValue(ent, "physicsmode", "2"); // Non-Solid, Server-side
		DispatchKeyValue(ent, "massScale", "8.0"); // A scale multiplier for the object's mass, too light and it moves too easy with blasts
		DispatchKeyValue(ent, "targetname", targetname); // The name that other entities refer to this entity by.
		
		//SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
		
		// Get the player's team and set it on the ammo as well as set appropriate color
		int team = GetClientTeam(client);
		SetEntProp(ent, Prop_Send, "m_iTeamNum", team);
		switch (team)
		{
			case TEAM_T:
			{
				if (ammoColorT[0] != '\0' && ammoColorT[0] != '0')
				{
					DispatchKeyValue(ent, "rendermode", "1");
					DispatchKeyValue(ent, "rendercolor", ammoColorT);
				}
			}
			case TEAM_CT:
			{
				if (ammoColorCT[0] != '\0' && ammoColorCT[0] != '0')
				{
					DispatchKeyValue(ent, "rendermode", "1");
					DispatchKeyValue(ent, "rendercolor", ammoColorCT);
				}
			}
		}
		
		DispatchSpawn(ent); // Spawn the entity
		
		// Below three SetEntProps need to be done before ActivateEntity.
		// If done after ActivateEntity, it uses old pre-scaled mins/maxs for StartTouch.
		// If done before DispatchSpawn, it seems StartTouch won't work at all. Maybe m_usSolidFlags is reset
		#if USE_CUST_MODEL_FORK
		float scaleBy;
		switch (weapontype)
		{
			case PISTOLS: scaleBy = ScaleFactorPistol;
			default:
			{
				switch (rifletype)
				{
					case RIFLES:		scaleBy = ScaleFactorRifle;
					default:		scaleBy = ScaleFactorShotgun;
				}
			}
		}
		
		if (scaleBy != 1.0)
		{
			SetEntPropFloat(ent, Prop_Send, "m_flModelScale", scaleBy);
			//new enteffects = GetEntProp(ent, Prop_Send, "m_fEffects");
			//enteffects |= 32;
			//SetEntProp(ent, Prop_Send, "m_fEffects", enteffects);
			// ent_bbox droppedammo_*;ent_text droppedammo_*
		}
		#endif
		// Set the entity as solid, noclip, and unable to take damage.
		SetEntProp(ent, Prop_Send, "m_usSolidFlags", 8); // FSOLID_TRIGGER
		SetEntProp(ent, Prop_Send, "m_CollisionGroup", 11); // COLLISION_GROUP_WEAPON
		SetEntProp(ent, Prop_Data, "m_takedamage", ammoDamageMode);
		SetEntProp(ent, Prop_Data, "m_iHealth", ammoHealth);
		
		ActivateEntity(ent); // Activating the entity seems to update the physics, so scaled model actually has the 
		// appropriate scaled physics model
		
		// Thanks to Bacardi for this code from his Healthkit from dead
		if (DestroyMode > 0 && lifetime > 0.9)
		{
			if (DestroyMode == 2) // Disolve Effect
			{
				int entd;
				
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
		
		// Get the ammo type of the weapon being dropped
		int type = GetPrimaryAmmoType(weapon);
		
		// Convert the entity to a string to create the trie (since it requires a string)
		char sEntity[25];
		
		IntToString(ent, sEntity, sizeof(sEntity));
		
		// Set the ammo information for number of rounds, type of ammo, and gun_type for the Trie
		int SetAmmoInfo[AmmoAttributes];
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
void StartTouch(int entity, int other)
{
	// Shadowysn: Since you're hooking onto the specific entities that are spawned by this plugin, 
	// why check m_ModelName?
	// Redundant check was removed.
	// Make sure "ammo box" isn't worldspawn and "other" is a valid client/player
	if (entity != 0 && other > 0 && other <= MaxClients)
	{
		if (teamRestrict == 0)
		{
			// See function for details
			ProcessAmmo(entity, other);
		}
		else
		{
			int entityTeam = GetEntProp(entity, Prop_Send, "m_iTeamNum");
			int otherTeam = GetClientTeam(other);
			switch (teamRestrict)
			{
				case 1: if (entityTeam == otherTeam) ProcessAmmo(entity, other);
				case 2: if (entityTeam != otherTeam) ProcessAmmo(entity, other);
			}
		}
	}
}

//========================================================================================

/**
 * Called when an entity output is fired.
 *
 * @param output        Name of the output that fired.
 * @param caller        Entity index of the caller.
 * @param activator     Entity index of the activator.
 * @param delay         Delay in seconds? before the event gets fired.
 * @return              Anything other than Plugin_Continue will supress this event,
 *                      returning Plugin_Continue will allow it to propagate the results
 *                      of this output to any entity inputs.
 */
void OnAmmoBreak(const char[] output, int caller, int activator, float delay)
{
	// Check if it's ammo from this plugin
	char targetname[13];
	GetEntPropString(caller, Prop_Data, "m_iName", targetname, sizeof(targetname));
	if (strcmp(targetname, "droppedammo_", false) != 0) return;
	
	float origin[3], mins[3], maxs[3];
	GetEntPropVector(caller, Prop_Data, "m_vecAbsOrigin", origin);
	GetEntPropVector(caller, Prop_Data, "m_vecMins", mins);
	GetEntPropVector(caller, Prop_Data, "m_vecMaxs", maxs);
	
	// Series of calculations for the middle of the ammo box's bounding box
	origin[0] += (mins[0] + maxs[0]) * 0.5;
	origin[1] += (mins[1] + maxs[1]) * 0.5;
	origin[2] += (mins[2] + maxs[2]) * 0.5;
	
	// DispatchEffect spawns the effects in the absolute origin of the entity, so the abs origin is manipulated
	SetEntPropVector(caller, Prop_Data, "m_vecAbsOrigin", origin);
	
	// Prep for ammo information
	char sEntity[25];
	IntToString(caller, sEntity, sizeof(sEntity));
	int GetAmmoInfo[AmmoAttributes];
	
	// Get the stored information
	if (GetTrieArray(h_Trie, sEntity, GetAmmoInfo[0], 4))
	{
		int ammo = GetAmmoInfo[ROUNDS];
		int weapontype = GetAmmoInfo[GUN_TYPE];
		int rifletype = GetAmmoInfo[RIFLE_TYPE];
		
		// We should only dispatch about a max of 50 effects
		if (ammo > 40) ammo = 40;
		
		float angle[3];
		
		// Spawn dust to indicate the non-bullet parts breaking
		for (int i = 1; i <= 10; i++)
		{
			SetVariantString("WheelDust");
			AcceptEntityInput(caller, "DispatchEffect");
		}
		
		// We need both weapontype and rifletype to determine which effects to spawn
		switch (weapontype)
		{
			case PISTOLS:
			{
				// Global pistol brass
				for (int i = 1; i <= ammo; i++)
				{
					angle[0] = GetRandomFloat(360.0, -360.0); angle[1] = GetRandomFloat(360.0, -360.0);
					SetEntPropVector(caller, Prop_Data, "m_angAbsRotation", angle);
					SetVariantString("EjectBrass_57");
					AcceptEntityInput(caller, "DispatchEffect");
				}
			}
			default:
			{
				switch (rifletype)
				{
					case RIFLES:
					{
						// Global rifle/other brass
						for (int i = 1; i <= ammo; i++)
						{
							angle[0] = GetRandomFloat(360.0, -360.0); angle[1] = GetRandomFloat(360.0, -360.0);
							SetEntPropVector(caller, Prop_Data, "m_angAbsRotation", angle);
							SetVariantString("EjectBrass_338Mag");
							AcceptEntityInput(caller, "DispatchEffect");
						}
					}
					default:
					{
						// Global shotgun shells
						for (int i = 1; i <= ammo; i++)
						{
							angle[0] = GetRandomFloat(360.0, -360.0); angle[1] = GetRandomFloat(360.0, -360.0);
							SetEntPropVector(caller, Prop_Data, "m_angAbsRotation", angle);
							SetVariantString("EjectBrass_12Gauge");
							AcceptEntityInput(caller, "DispatchEffect");
						}
					}
				}
			}
		}
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
void ProcessAmmo(int entity, int client)
{
	// Convert the entity to a string to search the trie (since it requires a string)
	char sEntity[25];
	
	IntToString(entity, sEntity, sizeof(sEntity));
	
	int GetAmmoInfo[AmmoAttributes];

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
	int ammo = GetAmmoInfo[ROUNDS];
	int type = GetAmmoInfo[TYPE];
	int weapontype = GetAmmoInfo[GUN_TYPE];
	int rifletype = GetAmmoInfo[RIFLE_TYPE];
	
	// Retrieve weapon indexes for slot0 and slot1 weapons from client
	int WeaponSlot0 = GetPlayerWeaponSlot(client, 0); // Rifle Slot
	int WeaponSlot1 = GetPlayerWeaponSlot(client, 1); // Pistol Slot
	
	int playerrifletype;
	
	if (WeaponSlot0 != -1)// && (StrContains(WeaponName, "xm1014") != -1 || StrContains(WeaponName, "m3") != -1))
	{
		char WeaponName[64];
		
		GetEntityClassname(WeaponSlot0, WeaponName, sizeof(WeaponName));
		
		if (strcmp(WeaponName, "weapon_xm1014", false) == 0 || strcmp(WeaponName, "weapon_m3", false) == 0)
		{
			playerrifletype = SHOTGUNS;
		}
		else
		{
			playerrifletype = RIFLES;
		}
	}
	
	/* 	If the client has a weapon in slot0 and the GUN_TYPE from the dropped ammo is a RIFLE (or CVar for Allow Mixed Ammo is true), and the ammo type from 
	*	dropped ammo is the same as the ammo type of the weapon the player has in slot0
	*	
	*	Or if the client has a weapon is slot0 and the GUN_TYPE from the dropped ammos is a RIFLE and AllowAnyMixedAmmo is true
	*/
	if (WeaponSlot0 != -1 && ((weapontype == RIFLES && AllowAnyMixedAmmo && rifletype == playerrifletype) || 
		((weapontype == RIFLES || AllowMixedAmmo) && (type == GetPrimaryAmmoType(WeaponSlot0)))))
	{
		if (AllowAnyMixedAmmo && rifletype == playerrifletype)
		{
			type = GetPrimaryAmmoType(WeaponSlot0);
		}
		
		ProcessAmmo2(client, WeaponSlot0, ammo, type, weapontype, entity, rifletype); // See function for details
		
		return;
	}
	
	/* 	If the client has a weapon in slot1 and the GUN_TYPE from the dropped ammo is a PISTOL (or CVar for Allow Mixed Ammo is true), and the ammo type from 
	*	dropped ammo is the same as the ammo type of the weapon the player has in slot1 
	*	
	*	Or if the client has a weapon is slot1 and the GUN_TYPE from the dropped ammos is a PISTOL and AllowAnyMixedAmmo is true
	*/
	if (WeaponSlot1 != -1 && ((weapontype == PISTOLS && AllowAnyMixedAmmo) || 
		((weapontype == PISTOLS || AllowMixedAmmo) && type == GetPrimaryAmmoType(WeaponSlot1))))
	{
		if (AllowAnyMixedAmmo)
		{
			type = GetPrimaryAmmoType(WeaponSlot1);
		}
		
		//RemoveFromTrie(h_Trie, sEntity); // Remove the information from the Trie since we've already extracted it
		ProcessAmmo2(client, WeaponSlot1, ammo, type, weapontype, entity, rifletype); // See function for details
		
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
void ProcessAmmo2(int client, int PlayerWeapon, int ammo, int ammoType, int weapontype, int entity, int rifletype)
{
	// Store the ammo the player currently has
	int PlayerAmmo = GetWeaponPlayerAmmo(client, PlayerWeapon);
	
	// Convert the entity to a string to create the trie (since it requires a string)
	char sEntity[25];

	IntToString(entity, sEntity, sizeof(sEntity));
	
	// If AbideByMaxAmmo, then we don't give more ammo than what the max is for that gun.
	if (AbideByMaxAmmo)
	{
		int ret = GivePlayerAmmo(client, ammo, ammoType, true);
		
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
			int newammo = ammo - ret;
			
			// Set the new ammo information for number of rounds, type of ammo, and gun_type
			int SetAmmoInfo[AmmoAttributes];
			SetAmmoInfo[ROUNDS] = newammo;
			SetAmmoInfo[TYPE] = ammoType;
			SetAmmoInfo[GUN_TYPE] = weapontype;
			SetAmmoInfo[RIFLE_TYPE] = rifletype;
			
			// Set trie for this entity with ammo information
			SetTrieArray(h_Trie, sEntity, SetAmmoInfo[0], 4, true);
			
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
		SetWeaponPlayerAmmo(client, PlayerWeapon, ammo + PlayerAmmo);
		
		// Get rid of the dropped ammo model and unhook the entity
		RemoveAmmoModel(entity);
		RemoveFromTrie(h_Trie, sEntity); // Remove the information from the Trie since we're done with it
	}
}

//========================================================================================

stock int GetWeaponPlayerAmmo(int client, int weapon)
{ return GetEntProp(client, Prop_Send, "m_iAmmo", _, GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType")); }

stock void SetWeaponPlayerAmmo(int client, int weapon, int ammo)
{ SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType")); }

stock int GetPrimaryAmmoType(int weapon)
{ return GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"); }

stock void PlaySound(int client)
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


stock void RemoveAmmoModel(int entity)
{
	if (IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
		SDKUnhook(entity, SDKHook_StartTouch, StartTouch);
	}
}

//========================================================================================

void OnVersionChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	// Make sure the version number is what is set in the compiled plugin, not a config file or changed CVar
	if (strcmp(newVal, PLUGIN_VERSION) != 0) cvar.SetString(PLUGIN_VERSION);
}

//========================================================================================

void OnEnabledChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	Enabled = cvar.BoolValue;
	
	switch (Enabled)
	{
		case false:
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i)) continue;
				SDKUnhook(i, SDKHook_WeaponDrop, OnWeaponDrop);
			}
		}
		case true:
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i)) continue;
				SDKHook(i, SDKHook_WeaponDrop, OnWeaponDrop);
			}
		}
	}
}

//========================================================================================

void OnBotsDropChanged(ConVar cvar, const char[] oldVal, const char[] newVal)		{ BotsDropAmmo =		cvar.BoolValue; }
void OnMixedAmmoChanged(ConVar cvar, const char[] oldVal, const char[] newVal)		{ AllowMixedAmmo =	cvar.BoolValue; }
void OnAnyMixedAmmoChanged(ConVar cvar, const char[] oldVal, const char[] newVal)	{ AllowAnyMixedAmmo =	cvar.BoolValue; }
void OnPistolDropsChanged(ConVar cvar, const char[] oldVal, const char[] newVal)	{ PistolDrops =		cvar.BoolValue; }
void OnRifleDropsChanged(ConVar cvar, const char[] oldVal, const char[] newVal)	{ RifleDrops =		cvar.BoolValue; }
void OnMaxAmmoChanged(ConVar cvar, const char[] oldVal, const char[] newVal)		{ AbideByMaxAmmo =	cvar.BoolValue; }
void OnSoundTypeChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	SOUND_TYPE = cvar.IntValue;
	
	switch (SOUND_TYPE)
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
void OnPlaySoundChanged(ConVar cvar, const char[] oldVal, const char[] newVal)		{ SOUND_PLAY =		cvar.IntValue; }
#if USE_UPDATER
void OnUseUpdaterChanged(ConVar cvar, const char[] oldVal, const char[] newVal)	{ UseUpdater =		cvar.BoolValue; }
#endif
void OnLifetimeChanged(ConVar cvar, const char[] oldVal, const char[] newVal)		{ lifetime =			cvar.FloatValue; }
void OnDestroyModeChanged(ConVar cvar, const char[] oldVal, const char[] newVal)	{ DestroyMode =		cvar.IntValue; }
void OnDisolveTypeChanged(ConVar cvar, const char[] oldVal, const char[] newVal)	{ DisolveType =		cvar.FloatValue; }
void OnGunLifetimeChanged(ConVar cvar, const char[] oldVal, const char[] newVal)	{ gunlifetime =		cvar.FloatValue; }
void OnGunDestroyModeChanged(ConVar cvar, const char[] oldVal, const char[] newVal)	{ GunDestroyMode =	cvar.IntValue; }
void OnGunDisolveTypeChanged(ConVar cvar, const char[] oldVal, const char[] newVal)	{ GunDisolveType =	cvar.FloatValue; }
#if USE_CUST_MODEL_FORK
void OnScaleFactorPistolChanged(ConVar cvar, const char[] oldVal, const char[] newVal)		{ ScaleFactorPistol =		cvar.FloatValue; }
void OnScaleFactorRifleChanged(ConVar cvar, const char[] oldVal, const char[] newVal)		{ ScaleFactorRifle =		cvar.FloatValue; }
void OnScaleFactorShotgunChanged(ConVar cvar, const char[] oldVal, const char[] newVal)		{ ScaleFactorShotgun =	cvar.FloatValue; }
void OnPistolModelChanged(ConVar cvar, const char[] oldVal, const char[] newVal)		{ cvar.GetString(g_sPistolModel,	sizeof(g_sPistolModel)); }
void OnOtherModelChanged(ConVar cvar, const char[] oldVal, const char[] newVal)		{ cvar.GetString(g_sOtherModel,		sizeof(g_sOtherModel)); }
void OnSGModelChanged(ConVar cvar, const char[] oldVal, const char[] newVal)			{ cvar.GetString(g_sSGModel,		sizeof(g_sSGModel)); }
void OnUseCustomModelsChanged(ConVar cvar, const char[] oldVal, const char[] newVal)	{ UseCustomModels =	cvar.BoolValue; }
#endif
void OnAmmoDamageModeChanged(ConVar cvar, const char[] oldVal, const char[] newVal)		{ ammoDamageMode =	cvar.IntValue; }
void OnAmmoHealthChanged(ConVar cvar, const char[] oldVal, const char[] newVal)		{ ammoHealth =		cvar.IntValue; }
void OnAmmoColorChangedT(ConVar cvar, const char[] oldVal, const char[] newVal)		{ cvar.GetString(ammoColorT,		sizeof(ammoColorT)); }
void OnAmmoColorChangedCT(ConVar cvar, const char[] oldVal, const char[] newVal)		{ cvar.GetString(ammoColorCT,		sizeof(ammoColorCT)); }
void OnTeamRestrictChanged(ConVar cvar, const char[] oldVal, const char[] newVal)		{ teamRestrict =		cvar.IntValue; }