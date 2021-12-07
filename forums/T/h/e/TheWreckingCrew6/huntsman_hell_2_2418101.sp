#include <sourcemod>
#include <entity_prop_stocks>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <adminmenu>

#include <updater>
#include <morecolors>

#undef REQUIRE_EXTENSIONS
#include <steamtools>

// Include support for Opt-In MultiMod
// Default: OFF
//#define OIMM

#if defined OIMM
#undef REQUIRE_PLUGIN
#include <optin_multimod>
#endif

#pragma semicolon 1

//Projectile entity names.
#define BOW "tf_weapon_compound_bow"
#define CROSSBOW "tf_weapon_crossbow"
#define RR "tf_weapon_shotgun_building_rescue"
#define ARROW "tf_projectile_arrow"
#define HEALING_BOLT "tf_projectile_healing_bolt"

#define CHAT_PREF_COLOR "{cyan}[HH2] {Gold}"
#define CHAT_PREF "[HH2] "

//Definitions for kill types
#define KILL_FLAMETHROWER "flamethrower"
#define KILL_FIREARROW "huntsman"
#define KILL_EXPLOSION "env_explosion"

//Jump Charge definitions
#define JUMPCHARGETIME 1
#define JUMPCHARGE (25 * JUMPCHARGETIME)

//Our Version
#define VERSION "1.0.3"

//Our Updater URL
#define UPDATE_URL    "http://www.tf2app.com/thewreckingcrew6/plugins/hh2/updater.txt"

public Plugin:myinfo = 
{
	name = "[TF2] Huntsman Hell 2",
	author = "Powerlord  && TheWreckingCrew6",
	description = "All Snipers, all with Huntsman and Jarate, most likely firing arrows that explode and set you on fire.  What could go wrong?",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=282022"
}

new String:g_Sounds_Explode[][] = { "weapons/explode1.wav", "weapons/explode2.wav", "weapons/explode3.wav" };
new String:g_Sounds_Jump[][] = { "vo/sniper_specialcompleted02.mp3", "vo/sniper_specialcompleted17.mp3", "vo/sniper_specialcompleted19.mp3", "vo/sniper_laughshort01.mp3", "vo/sniper_laughshort04.mp3" };
new String:g_Sounds_MedicJump[][] = { "vo/medic_mvm_say_ready02.mp3", "vo/medic_mvm_wave_end06.mp3", "vo/medic_mvm_get_upgrade03.mp3", "vo/medic_sf12_badmagic09.mp3", "vo/medic_sf12_taunts03.mp3" };
new String:g_Sounds_EngyJump[][] = { "vo/engineer_battlecry05.mp3", "vo/engineer_mvm_say_ready02.mp3", "vo/engineer_mvm_wave_end07.mp3", "vo/engineer_laughshort01.mp3", "vo/engineer_incoming01.mp3" };
new String:g_Sounds_MedicRound[][] = { "vo/medic_laughevil04.mp3", "vo/medic_laughevil05.mp3", "vo/medic_laughlong01.mp3", "vo/medic_laughlong02.mp3" };
new String:g_Sounds_EngyRound[][] = { "vo/engineer_laughevil02.mp3", "vo/engineer_laughevil06.mp3", "vo/engineer_laughlong01.mp3", "vo/engineer_laughlong02.mp3" };
new String:g_Sounds_SniperRound[][] = { "vo/sniper_laughevil01.mp3", "vo/sniper_laughevil02.mp3", "vo/sniper_laughlong01.mp3", "vo/sniper_laughlong02.mp3" };

new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new Handle:g_Cvar_GameDescription = INVALID_HANDLE;
new Handle:g_Cvar_AutoUpdate = INVALID_HANDLE;
new Handle:g_Cvar_ReloadUpdate = INVALID_HANDLE;

new Handle:g_Cvar_ArrowCount = INVALID_HANDLE;
new Handle:g_Cvar_FireArrows = INVALID_HANDLE;
new Handle:g_Cvar_Explode = INVALID_HANDLE;
new Handle:g_Cvar_ExplodeFire = INVALID_HANDLE;
new Handle:g_Cvar_ExplodeFireSelf = INVALID_HANDLE;
new Handle:g_Cvar_ExplodeRadius = INVALID_HANDLE;
new Handle:g_Cvar_ExplodeDamage = INVALID_HANDLE;

new Handle:g_Cvar_SuperJump = INVALID_HANDLE;
new Handle:g_Cvar_SuperJumpTime = INVALID_HANDLE;
new Handle:g_Cvar_DoubleJump = INVALID_HANDLE;
new Handle:g_Cvar_FallDamage = INVALID_HANDLE;
new Handle:g_Cvar_SpecialRound = INVALID_HANDLE;

new Handle:g_Cvar_StartingHealth = INVALID_HANDLE;
new Handle:g_Cvar_JarateOutline = INVALID_HANDLE;
new Handle:g_Cvar_JarateFriendlies = INVALID_HANDLE;
new Handle:g_Cvar_FFJarateDistance = INVALID_HANDLE;
new Handle:g_Cvar_FFJarateTime = INVALID_HANDLE;

new Handle:g_Cvar_MedicRound = INVALID_HANDLE;
new Handle:g_Cvar_MedicArrowCount = INVALID_HANDLE;
new Handle:g_Cvar_MedicStartingHealth = INVALID_HANDLE;

new Handle:g_Cvar_EngyRound = INVALID_HANDLE;
new Handle:g_Cvar_EngyBoltCount = INVALID_HANDLE;
new Handle:g_Cvar_EngyStartingHealth = INVALID_HANDLE;
new Handle:g_Cvar_BlockBuildings = INVALID_HANDLE;

new Handle:jumpHUD;

new Handle:gH_AdminMenu;

new Handle:g_hJumpTimer = INVALID_HANDLE;
new g_JumpCharge[MAXPLAYERS+1] = { 0, ... };
new bool:g_bDoubleJumped[MAXPLAYERS+1];
new g_LastButtons[MAXPLAYERS+1];
new g_bJarated[MAXPLAYERS+1];

new bool:g_bSteamTools = false;
new bool:g_bUpdater = false;
new bool:g_bForceUpdate = false;

new bool:g_bBowOut[MAXPLAYERS+1];

#if defined OIMM
new bool:g_bMultiMod = false;
#endif

new bool:g_bLateLoad = false;

new bool: g_bSpecialRound = false;

new bool:g_bMedicRound = false;
new bool:g_bSetMedicRound = false;

new bool:g_bEngyRound = false;
new bool:g_bSetEngyRound = false;

/******************************************************************************************
 *                                  PLUGIN STARTUP FUNCTIONS                              *
 ******************************************************************************************/

//For our natives and late loading.
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("Steam_SetGameDescription");
	g_bLateLoad = late;
	
	return APLRes_Success;
}

//When our plugin starts up, everything has to get setup.
public OnPluginStart()
{
	//Translations
	LoadTranslations("common.phrases");
	LoadTranslations("huntsmanhell2.phrases");
	
	//Basic Version CVar
	CreateConVar("hh2_version", VERSION, "Huntsman Hell 2 Version", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_DONTRECORD);
	
	//Plugin Controls
	g_Cvar_Enabled = CreateConVar("hh2_enabled", "1", "Enable Huntsman Hell 2?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_GameDescription = CreateConVar("hh2_gamedescription", "1", "If SteamTools is loaded, set the Game Description to Huntsman Hell 2?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvar_AutoUpdate = CreateConVar("hh2_autoupdate", "1", "If Updater is installed, we want to autoupdate this ish.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvar_ReloadUpdate = CreateConVar("hh2_reloadupdate", "1", "If an Update is installed, do you want to reload the plugin automatically?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	//Huntsman Settings
	g_Cvar_StartingHealth = CreateConVar("hh2_health", "400", "Amount of Health players to start with", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 65.0, true, 800.0);
	g_Cvar_ArrowCount = CreateConVar("hh2_arrowmultiplier", "4.0", "How many times the normal number of arrows should we have? Normal arrow count is 12.5 (banker rounded down to 12)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.1, true, 8.0);
	
	//Overall Settings
	g_Cvar_SuperJump = CreateConVar("hh2_superjump", "1", "Should super jump be enabled in Huntsman Hell 2?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_SuperJumpTime = CreateConVar("hh2_superjumptime", "5", "How Long should the recharge time be on Super Jumps?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 60.0);
	g_Cvar_DoubleJump = CreateConVar("hh2_doublejump", "1", "Should double jump be enabled in Huntsman Hell 2?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_FallDamage = CreateConVar("hh2_falldamage", "0", "Should players take fall damage?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_SpecialRound = CreateConVar("hh2_specialchance", "10", "Chance of the current round being either an engy/medic round.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	
	g_Cvar_FireArrows = CreateConVar("hh2_firearrows", "1", "Should all arrows catch on fire in Huntsman Hell 2?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_Explode = CreateConVar("hh2_explode", "1", "Should arrows explode when they hit something?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_ExplodeRadius = CreateConVar("hh2_exploderadius", "200", "If arrows explode, the radius of explosion in hammer units.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0);
	g_Cvar_ExplodeDamage = CreateConVar("hh2_explodedamage", "50", "If arrows explode, the damage the explosion does.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0);
	g_Cvar_ExplodeFire = CreateConVar("hh2_explodefire", "0", "Should explosions catch players on fire?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_ExplodeFireSelf = CreateConVar("hh2_explodefireself", "0", "Should explosions catch yourself on fire?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	//Medic Round Settings
	g_Cvar_MedicRound = CreateConVar("hh2_medicchance", "50", "Chance of a Special Round being Medics. Must Add up to 100 with huntsmanhell_engychance!", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	g_Cvar_MedicArrowCount = CreateConVar("hh2_medicarrowmultiplier", "1.32", "How many times the normal number of arrows should we have? Normal arrow count is 37.5 (banker rounded up to 38)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.1, true, 8.0);
	g_Cvar_MedicStartingHealth = CreateConVar("hh2_medichealth", "300", "Amount of Health players to start with during Medic rounds", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 65.0, true, 800.0);
	
	//Engy Round Settings
	g_Cvar_EngyRound = CreateConVar("hh2_engychance", "50", "Chance of a Special Round being engies. Must Add up to 100 with huntsmanhell_medicchance!", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	g_Cvar_EngyBoltCount = CreateConVar("hh2_engyboltmultiplier", "2.6", "How many times the normal number of bolts should we have? Normal arrow count is 20", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.1, true, 8.0);
	g_Cvar_EngyStartingHealth = CreateConVar("hh2_engyhealth", "300", "Amount of Health players to start with during Engy rounds", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 65.0, true, 800.0);
	g_Cvar_BlockBuildings = CreateConVar("hh2_blockbuildings", "1", "Do you want the plugin to block engies from buildings their buildings? (WARNING: IF DISABLED, IT WILL BECOME STUPID RIDICULOUS ON AN ENGY ROUND!)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	//Jarate Settings
	g_Cvar_JarateOutline = CreateConVar("hh2_jarateoutline", "0", "Should players who are jarated be outlined?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_JarateFriendlies = CreateConVar("hh2_FFJarate", "0", "Do you want Jarate to spash on teammates too? (CAREFUL :D THIS INCLUDES YOU)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_FFJarateDistance = CreateConVar("hh2_FFJarateDist", "750.0", "Max distance a player can be from jarate to be covered in piss (float)", _, true, 300.0, true, 1000.0);
	g_Cvar_FFJarateTime = CreateConVar("hh2_FFJarateTime", "7.0", "Time in seconds to cover player in piss (float)", _, true, 3.0, true, 12.0);
	
	//Create That File
	AutoExecConfig(true, "huntsmanhell2");
	
	//Event Hooking
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("post_inventory_application", Event_Inventory);
	HookEvent("player_death", Event_Death, EventHookMode_Pre);
	
	//Hooking Our Convars
	HookConVarChange(g_Cvar_Enabled, Cvar_Enabled);
	HookConVarChange(g_Cvar_GameDescription, Cvar_GameDescription);
	
	//Console Commands
	RegConsoleCmd("hh2_help", Command_Info, "Huntsman Hell 2 help");
	
	//Admin Commands
	RegAdminCmd("hh2_medicround", Command_MedicRound, ADMFLAG_ROOT, "Set/Unset Next Round to Medic Round.");
	RegAdminCmd("hh2_engyround", Command_EngyRound, ADMFLAG_ROOT, "Set/Unset Next Round to Engy Round.");
	RegAdminCmd("hh2_update", Command_Update, ADMFLAG_ROOT, "Force check for an update for Huntsman Hell 2.");
	
	//Command Listeners
	AddCommandListener(CommandCallback, "build");

	//Our Huds
	jumpHUD = CreateHudSynchronizer();
	
	//If the adminmenu is loaded, let's get it going in here! :D
	new Handle:topmenu;
	if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

#if defined OIMM
public OnPluginEnd()
{
	if (g_bMultiMod)
	{
		OptInMultiMod_Unregister("Huntsman Hell 2");
	}
}
#endif

//Once our plugins our loaded, let's see if steamtools is up and running.
public OnAllPluginsLoaded()
{
	g_bUpdater = LibraryExists("updater");
	g_bSteamTools = LibraryExists("SteamTools");
	
	if (g_bSteamTools && GetConVarBool(g_Cvar_GameDescription))
	{
		//If Steamtools is loaded and you have it enabled, let's change the game description.
		UpdateGameDescription();
	}

	#if defined OIMM
	g_bMultiMod = LibraryExists("optin_multimod");
	if (g_bMultiMod)
	{
		OptInMultiMod_Register("Huntsman Hell 2", MultiMod_CheckValidMap, MultiMod_StatusChanged, MultiMod_TranslateName);
	}
	#endif
	
	if (g_bUpdater)
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

//Once our configs are done executing, we can get started up in here.
public OnConfigsExecuted()
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	if (g_bLateLoad)
	{
		for (new i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i))
			{
				SDKHook(i, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
			}
		}
		g_bLateLoad = false;
	}
	
	if (g_hJumpTimer == INVALID_HANDLE)
	{
		g_hJumpTimer = CreateTimer(0.2, JumpTimer, _, TIMER_REPEAT);
	}
	
	UpdateGameDescription(true);
	ChooseSpecialRound();
}

/******************************************************************************************
 *                                     LIBRARY FUNCTIONS                                  *
 ******************************************************************************************/

//If libraries are added, we need to change something.
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "SteamTools", false))
	{
		g_bSteamTools = true;
	}
	
	else if (StrEqual(name, "updater"))
    {
		g_bUpdater = true;
    }
    
	#if defined OIMM
	else if (StrEqual(name, "optin_multimod", false))
	{
		g_bMultiMod = true;
		OptInMultiMod_Register("Huntsman Hell 2", MultiMod_CheckValidMap, MultiMod_StatusChanged, MultiMod_TranslateName);
	}
	#endif
	
	if (g_bUpdater)
		Updater_AddPlugin(UPDATE_URL);
	
	if (g_bSteamTools && GetConVarBool(g_Cvar_GameDescription))
		UpdateGameDescription();
}

//Can't keep trying to use libraries that aren't there anymore.
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "SteamTools", false))
	{
		g_bSteamTools = false;
	}
	
	#if defined OIMM
	else if (StrEqual(name, "optin_multimod", false))
	{
		g_bMultiMod = false;
	}
	#endif
	
	else if (StrEqual(name, "adminmenu"))
	{
		gH_AdminMenu = INVALID_HANDLE;
	}
	
	else if (StrEqual(name, "updater"))
	{
		g_bUpdater = false;
	}
}

/******************************************************************************************
 *                                       UPDATER                                          *
 ******************************************************************************************/

//When Updater is Checking for an update, here's what we wish to do.
public Action Updater_OnPluginChecking (){

	if(!GetConVarBool(g_Cvar_AutoUpdate) && !g_bForceUpdate)
		return Plugin_Handled;
		
	for(new i = 1; i <= MAXPLAYERS; i++)
	{
		if(CheckCommandAccess(i, "hh2_update", ADMFLAG_ROOT, false))
			CPrintToChat(i, "%s %T", CHAT_PREF_COLOR, "Update_Checking", i);
	}
	
	PrintToServer("%s %T", CHAT_PREF, "Update_Checking", LANG_SERVER);
	
	g_bForceUpdate = false;
	
	return Plugin_Continue;

}

public Action:Updater_OnPluginDownloading()
{
	for(new i = 1; i <= MAXPLAYERS; i++)
	{
		if(CheckCommandAccess(i, "hh2_update", ADMFLAG_ROOT, false))
			CPrintToChat(i, "%s %T", CHAT_PREF_COLOR, "Update_Download", i);
	}
	
	PrintToServer("%s %T", CHAT_PREF, "Update_Download", LANG_SERVER);
	
	return Plugin_Continue;
}

public Updater_OnPluginUpdating()
{
	for(new i = 1; i <= MAXPLAYERS; i++)
	{
		if(CheckCommandAccess(i, "hh2_update", ADMFLAG_ROOT, false))
			CPrintToChat(i, "%s %T", CHAT_PREF_COLOR, "Update_Install", i);
	}
	
	PrintToServer("%s %T", CHAT_PREF, "Update_Install", LANG_SERVER);
}

//When our plugin is updated, if you want to reload the plugin, it will reload it.
public int Updater_OnPluginUpdated ()
{
	PrintToServer("%s %T", CHAT_PREF, "Successful_Update", LANG_SERVER);
	
	for(new i = 1; i <= MAXPLAYERS; i++)
	{
		if(CheckCommandAccess(i, "hh2_update", ADMFLAG_ROOT, false))
			CPrintToChat(i, "%s %T", CHAT_PREF_COLOR, "Successful_Update", i);
	}
	
	if(GetConVarBool(g_Cvar_ReloadUpdate))
	{
		ReloadPlugin();
		PrintToServer("%s %T", CHAT_PREF, "Reload_Plugin", LANG_SERVER);
		for(new i = 1; i <= MAXPLAYERS; i++)
	{
		if(CheckCommandAccess(i, "hh2_update", ADMFLAG_ROOT, false))
			CPrintToChat(i, "%s %T", CHAT_PREF_COLOR, "Reload_Plugin", i);
	}
	}
}

public Update(int client)
{
	if(!g_bUpdater)
	{
		CPrintToChat(client, "%s %T", CHAT_PREF_COLOR, "No_Updater", client);
	}
	else
	{
		g_bForceUpdate = true;
		if(!Updater_ForceUpdate())
		{
			CReplyToCommand(client, "%s %T", CHAT_PREF_COLOR, "Cant_Update", client);
		}
		g_bForceUpdate = false;
	}
}

/******************************************************************************************
 *                           SETTING UP OUR NEEDED VARIABLES :D                           *
 ******************************************************************************************/

//On map start let's initialize our variables.
public OnMapStart()
{
	for (new i = 0; i < sizeof(g_Sounds_Explode); ++i)
	{
		PrecacheSound(g_Sounds_Explode[i]);
	}
	
	for (new i = 0; i < sizeof(g_Sounds_Jump); ++i)
	{
		PrecacheSound(g_Sounds_Jump[i]);
	}
	
	for (new i = 0; i < sizeof(g_Sounds_MedicJump); ++i)
	{
		PrecacheSound(g_Sounds_MedicJump[i]);
	}
	
	for (new i = 0; i < sizeof(g_Sounds_MedicRound); i++)
	{
		PrecacheSound(g_Sounds_MedicRound[i]);
	}
	
	for(new i = 0; i < sizeof(g_Sounds_EngyRound); i++)
	{
		PrecacheSound(g_Sounds_EngyRound[i]);
	}
	
	for(new i = 0; i < sizeof(g_Sounds_SniperRound); i++)
	{
		PrecacheSound(g_Sounds_SniperRound[i]);
	}
	
	for(new i = 0; i < sizeof(g_bJarated); i++)
	{
		g_bJarated[i] = false;
	}
	
	for(new i = 0; i < sizeof(g_bBowOut); i++)
	{
		g_bBowOut[i] = false;
	}
}

//At the end of a map let's de-initialize our variables.
public OnMapEnd()
{
	if (g_hJumpTimer != INVALID_HANDLE)
	{
		CloseHandle(g_hJumpTimer);
		g_hJumpTimer = INVALID_HANDLE;
	}
}

//Once a client is in, we need to prepare them for our gamemode.
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	new TFClassType:class;
	if (g_bMedicRound)
	{
		class = TFClass_Medic;
	}
	else if (g_bEngyRound)
	{
		class = TFClass_Engineer;
	}
	else
	{
		class = TFClass_Sniper;
	}

	SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", class);
	
	CPrintToChat(client, "%s %T", CHAT_PREF_COLOR, "login_help", client);
}

//When a client disconnects, let's default all their variables back to normal.
public OnClientDisconnect_Post(client)
{
	g_bDoubleJumped[client] = false;
	g_LastButtons[client] = 0;
	g_JumpCharge[client] = 0;
	g_bJarated[client] = false;
	g_bBowOut[client] = false;
}

/******************************************************************************************
 *                                     ADMIN MENU SUPPORT                                 *
 ******************************************************************************************/

//When the admin menu is ready, lets define our topmenu object, and add our commands to it.
public OnAdminMenuReady(Handle:topmenu)
{
	if(topmenu == gH_AdminMenu)
	{
		return;
	}
	
	gH_AdminMenu = topmenu;
	
	new TopMenuObject:server_commands = FindTopMenuCategory(gH_AdminMenu, ADMINMENU_SERVERCOMMANDS);
	
	AddToTopMenu(gH_AdminMenu, "hh2_medicround", TopMenuObject_Item, AdminMenu_MedicRound, server_commands, "hh2_medicround", ADMFLAG_ROOT);
	AddToTopMenu(gH_AdminMenu, "hh2_engyround", TopMenuObject_Item, AdminMenu_EngyRound, server_commands, "hh2_engyround", ADMFLAG_ROOT);
	
	AddToTopMenu(gH_AdminMenu, "hh2_update", TopMenuObject_Item, AdminMenu_Updater, server_commands, "hh2_update", ADMFLAG_ROOT);
}

//Admin Menu Handler for our Force Medic Round Command.
public AdminMenu_MedicRound(Handle:hTopMenu, TopMenuAction:action, TopMenuObject:tmoObjectID, param, String:szBuffer[], iMaxLength) {
	if (!IsValidClient(param))
		return;

	if (action == TopMenuAction_DisplayOption)
	{
		if(!g_bSetMedicRound)
			Format(szBuffer, iMaxLength, "%T", "Force_Medic", param);
		else
			Format(szBuffer, iMaxLength, "%T", "Cancel_Medic", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if(!g_bSetMedicRound)
		{
			CPrintToChat(param, "%s %T", CHAT_PREF_COLOR, "mRound_Enabled", param);
			g_bSetMedicRound = true;
			g_bSetEngyRound = false;
		}
		else
		{
			CPrintToChat(param, "%s %T", CHAT_PREF_COLOR, "mRound_Disabled", param);
			g_bSetMedicRound = false;
		}
	}
}

//Admin Menu Handler for our Force Engy Round Command.
public AdminMenu_EngyRound(Handle:hTopMenu, TopMenuAction:action, TopMenuObject:tmoObjectID, param, String:szBuffer[], iMaxLength) {
	if (!IsValidClient(param))
		return;

	if (action == TopMenuAction_DisplayOption)
	{
		if(!g_bSetEngyRound)
			Format(szBuffer, iMaxLength, "%T", "Force_Engy", param);
		else
			Format(szBuffer, iMaxLength, "%T", "Cancel_Engy", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if(!g_bSetEngyRound)
		{
			CPrintToChat(param, "%s %T", CHAT_PREF_COLOR, "eRound_Enabled", param);
			g_bSetMedicRound = false;
			g_bSetEngyRound = true;
		}
		else
		{
			CPrintToChat(param, "%s %T", CHAT_PREF_COLOR, "eRound_Disabled", param);
			g_bSetEngyRound = false;
		}
	}
}

public AdminMenu_Updater(Handle:hTopMenu, TopMenuAction:action, TopMenuObject:tmoObjectID, param, String:szBuffer[], iMaxLength)
{
	if(!IsValidClient(param))
		return;
		
	if (action == TopMenuAction_DisplayOption)
	{
		Format(szBuffer, iMaxLength, "%T", "Check_Updater", param);
	}
	else if (action == TopMenuAction_SelectOption && g_bUpdater && GetConVarBool(g_Cvar_AutoUpdate))
	{
		Update(param);
	}
}

/******************************************************************************************
 *                                       COMMANDS                                         *
 ******************************************************************************************/

//Our Force Medic Round Command.
public Action:Command_MedicRound(client, args)
{
	if (!IsValidClient(client))
		return;
	
	if(!g_bSetMedicRound)
	{
		CPrintToChat(client, "%s %T", CHAT_PREF_COLOR, "mRound_Enabled", LANG_SERVER);
		g_bSetMedicRound = true;
		g_bSetEngyRound = false;
	}
	else
	{
		CPrintToChat(client, "%s %T", CHAT_PREF_COLOR, "mRound_Disabled", LANG_SERVER);
		g_bSetMedicRound = false;
	}
}

//Our Force Engy Round Command.
public Action:Command_EngyRound(client, args)
{
	if (!IsValidClient(client))
		return;
	
	if(!g_bSetEngyRound)
	{
		CPrintToChat(client, "%s %T", CHAT_PREF_COLOR, "eRound_Enabled", LANG_SERVER);
		g_bSetMedicRound = false;
		g_bSetEngyRound = true;
	}
	else
	{
		CPrintToChat(client, "%s %T", CHAT_PREF_COLOR, "eRound_Disabled", LANG_SERVER);
		g_bSetEngyRound = false;
	}
}

//Our plugin info Command.
public Action:Command_Info(client, args)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return Plugin_Continue;
	}
	
	if (client == 0)
	{
		CReplyToCommand(client, "%s %t", CHAT_PREF_COLOR, "Command is in-game only");
		return Plugin_Handled;
	}
	
	new Handle:menu = CreateMenu(MenuHandler_Info, MenuAction_Display | MenuAction_End | MenuAction_DisplayItem);
	
	SetMenuTitle(menu, "%T", "help_title", LANG_SERVER);

	AddMenuItem(menu, "help_basic", "help_basic", ITEMDRAW_DISABLED);
	
	new arrows = RoundToFloor(25.0 * (GetConVarFloat(g_Cvar_ArrowCount) / 2.0)) + 1;

	new String:numbers[5];
	IntToString(arrows, numbers, sizeof(numbers));
	AddMenuItem(menu, "help_arrows", numbers, ITEMDRAW_DISABLED);

	IntToString(GetConVarInt(g_Cvar_StartingHealth), numbers, sizeof(numbers));
	AddMenuItem(menu, "help_health", numbers, ITEMDRAW_DISABLED);
	
	if (GetConVarBool(g_Cvar_Explode))
	{
		AddMenuItem(menu, "help_explosions", "help_explosions", ITEMDRAW_DISABLED);
	}
	
	if (GetConVarBool(g_Cvar_DoubleJump))
	{
		AddMenuItem(menu, "help_doublejump", "help_doublejump", ITEMDRAW_DISABLED);
	}
	
	if (GetConVarBool(g_Cvar_SuperJump))
	{
		AddMenuItem(menu, "help_superjump", "help_superjump", ITEMDRAW_DISABLED);
	}
	
	if (!GetConVarBool(g_Cvar_FallDamage))
	{
		AddMenuItem(menu, "help_falldamage", "help_falldamage", ITEMDRAW_DISABLED);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

//Our Update Command, that allows you to update the plugin on command.
public Action:Command_Update (int client, int args){

	if(!g_bUpdater || !GetConVarBool(g_Cvar_AutoUpdate)){
	
		CReplyToCommand(client, "%s %T", CHAT_PREF_COLOR, "No_Updater", client);
		return Plugin_Handled;
	
	}
	
	Update(client);
	
	return Plugin_Handled;

}

/******************************************************************************************
 *                                          INFO MENU                                     *
 ******************************************************************************************/

//The Menu Handler for our Info Menu.
public MenuHandler_Info(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Display:
		{
			new String:buffer[128];
			Format(buffer, sizeof(buffer), "%T", "help_title", param1);
			SetPanelTitle(Handle:param2, buffer);
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		
		case MenuAction_DisplayItem:
		{
			new String:item[20];
			new String:display[20];
			GetMenuItem(menu, param2, item, sizeof(item), _, display, sizeof(display));
			
			new String:buffer[128];
			
			if (StrEqual(item, "help_basic"))
			{
				Format(buffer, sizeof(buffer), "%T", "help_basic", param1);
				return RedrawMenuItem(buffer);
			}
			else if (StrEqual(item, "help_arrows"))
			{
				new String:arrowType[30];
				if (GetConVarBool(g_Cvar_Explode) && GetConVarBool(g_Cvar_FireArrows))
				{
					strcopy(arrowType, sizeof(arrowType), "help_arrows_explodingfire");
				}
				else if (GetConVarBool(g_Cvar_Explode))
				{
					strcopy(arrowType, sizeof(arrowType), "help_arrows_exploding");
				}
				else if (GetConVarBool(g_Cvar_FireArrows))
				{
					strcopy(arrowType, sizeof(arrowType), "help_arrows_fire");
				}
				else
				{
					strcopy(arrowType, sizeof(arrowType), "help_arrows_normal");
				}
				
				Format(buffer, sizeof(buffer), "%T", "help_arrows", param1, StringToInt(display), arrowType);
				return RedrawMenuItem(buffer);
			}
			else if (StrEqual(item, "help_explosions"))
			{
				new String:explodeType[30];
				if (GetConVarBool(g_Cvar_ExplodeFireSelf))
				{
					strcopy(explodeType, sizeof(explodeType), "help_explosionsfireself");
				}
				else if (GetConVarBool(g_Cvar_ExplodeFire))
				{
					strcopy(explodeType, sizeof(explodeType), "help_explosionsfire");
				}
				Format(buffer, sizeof(buffer), "%T", explodeType, param1);
				return RedrawMenuItem(buffer);
			}
			else if (StrEqual(item, "help_health"))
			{
				Format(buffer, sizeof(buffer), "%T", "help_health", param1, StringToInt(display));
				return RedrawMenuItem(buffer);
			}
			else if (StrEqual(item, "help_doublejump"))
			{
				Format(buffer, sizeof(buffer), "%T", "help_doublejump", param1);
				return RedrawMenuItem(buffer);
			}
			else if (StrEqual(item, "help_superjump"))
			{
				Format(buffer, sizeof(buffer), "%T", "help_superjump", param1);
				return RedrawMenuItem(buffer);
			}
			else if (StrEqual(item, "help_falldamage"))
			{
				Format(buffer, sizeof(buffer), "%T", "help_falldamage", param1);
				return RedrawMenuItem(buffer);
			}
		}
	}
	
	return 0;
}

/******************************************************************************************
 *                         IF WE CHANGE THE STATUS OF THE PLUGIN                          *
 ******************************************************************************************/

//If you disable the plugin, we need to update all of our stuff.
public Cvar_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(g_Cvar_Enabled))
	{
		ChooseSpecialRound();
		CPrintToChatAll("%s %t", CHAT_PREF_COLOR, "login_help");
		if (g_hJumpTimer == INVALID_HANDLE)
		{
			CreateTimer(0.2, JumpTimer, _, TIMER_REPEAT);
		}
	}
	else
	{
		// Stop the timer while we're not running
		CloseHandle(g_hJumpTimer);
		g_hJumpTimer = INVALID_HANDLE;
	}
	
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		TF2Attrib_RemoveAll(i);
		
		if (IsPlayerAlive(i))
		{
			TF2_RemoveAllWeapons(i);
			if (GetConVarBool(g_Cvar_Enabled))
			{
				//TF2_SetPlayerClass(i, TFClass_Sniper); // Might as well only respawn them once
				g_bDoubleJumped[i] = false;
				g_LastButtons[i] = 0;
				g_JumpCharge[i] = 0;
			}
			
			TF2_RespawnPlayer(i);
			TF2_RegeneratePlayer(i);
		}
	}
	UpdateGameDescription();
}	

/******************************************************************************************
 *                   SETTING UP OUR CUSTOM GAME DESCRIPTION USING STEAMTOOLS              *
 ******************************************************************************************/

//If you decide you want/don't want the custom gamemode description, this changes it.
public Cvar_GameDescription(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UpdateGameDescription();
}

//Update our Custom Game Description.
UpdateGameDescription(bool:bAddOnly=false)
{
	if (g_bSteamTools)
	{
		new String:gamemode[64];
		if (GetConVarBool(g_Cvar_Enabled) && GetConVarBool(g_Cvar_GameDescription))
		{
			Format(gamemode, sizeof(gamemode), "Huntsman Hell 2 v.%s", VERSION);
		}
		else if (bAddOnly)
		{
			// Leave it alone if we're not running, should only be used when configs are executed
			return;
		}
		else
		{
			strcopy(gamemode, sizeof(gamemode), "Team Fortress");
		}
		Steam_SetGameDescription(gamemode);
	}
}

/******************************************************************************************
 *                                      EVENT HOOKS                                       *
 ******************************************************************************************/

//When someone dies, we have some hooking to do here.
public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return Plugin_Continue;
	}
	
	new victim = GetEventInt(event, "victim_entindex");
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if (StrEqual(weapon, KILL_FLAMETHROWER) && attacker != victim)
	{
		SetEventString(event, "weapon", "huntsman");
		SetEventInt(event, "damagebits", (GetEventInt(event, "damagebits") & DMG_CRIT) | DMG_BURN | DMG_PREVENT_PHYSICS_FORCE);
		SetEventInt(event, "customkill", TF_CUSTOM_BURNING_ARROW);
	}

	if (StrEqual(weapon, KILL_EXPLOSION))
	{
		SetEventString(event, "weapon", "tf_pumpkin_bomb");
		SetEventInt(event, "damagebits", (GetEventInt(event, "damagebits") & DMG_CRIT) | DMG_BLAST | DMG_RADIATION | DMG_POISON);
		SetEventInt(event, "customkill", TF_CUSTOM_PUMPKIN_BOMB);
	}
	
	return Plugin_Continue;
}

//When the round starts, lets reset our jump charges.
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	for (new i = 1; i <= MaxClients; ++i)
	{
		g_JumpCharge[i] = 0;
	}
	
	if (g_bMedicRound)
	{
		new random = GetRandomInt(0, sizeof(g_Sounds_MedicRound)-1);
		EmitSoundToAll(g_Sounds_MedicRound[random], _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, _, _, _, _, _);
	}
	else if (g_bEngyRound)
	{
		new random = GetRandomInt(0, sizeof(g_Sounds_EngyRound) - 1);
		EmitSoundToAll(g_Sounds_EngyRound[random], _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, _, _, _, _, _);
	}
	else
	{
		new random = GetRandomInt(0, sizeof(g_Sounds_SniperRound) - 1);
		EmitSoundToAll(g_Sounds_SniperRound[random], _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, _, _, _, _, _);
	}
}

//When the round ends, lets see what'
public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_Cvar_Enabled))
	{
		g_bMedicRound = false;
		g_bEngyRound = false;
		ChooseSpecialRound();
	}
}

//When you spawn, we need to figure out what's happening this round, and reset your settings.
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	g_bDoubleJumped[client] = false;
	g_LastButtons[client] = 0;
	g_JumpCharge[client] = 0;
	
	new TFClassType:class = TFClassType:GetEventInt(event, "class");
	
	if (g_bMedicRound)
	{
		if (class != TFClass_Medic)
		{
			// Directions say param 3 is both ignored and to set it to false in a player spawn hook...
			TF2_SetPlayerClass(client, TFClass_Medic, false); 
			
			TF2_RespawnPlayer(client);
			TF2_RegeneratePlayer(client);
		}
	}
	else if (g_bEngyRound)
	{
		if (class != TFClass_Engineer)
		{
			// Directions say param 3 is both ignored and to set it to false in a player spawn hook...
			TF2_SetPlayerClass(client, TFClass_Engineer, false); 
			
			TF2_RespawnPlayer(client);
			TF2_RegeneratePlayer(client);
		}
	}
	else
	{
		if (class != TFClass_Sniper)
		{
			// Directions say param 3 is both ignored and to set it to false in a player spawn hook...
			TF2_SetPlayerClass(client, TFClass_Sniper, false); 
			
			TF2_RespawnPlayer(client);
			TF2_RegeneratePlayer(client);
		}
	}
	
	new currentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	new primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);

	if(currentWeapon == primary && !g_bMedicRound && !g_bEngyRound)
	{
		g_bBowOut[client] = true;
		SetEntProp(primary, Prop_Send, "m_bArrowAlight", 1);
	}
	else
	{
		g_bBowOut[client] = false;
		SetEntProp(primary, Prop_Send, "m_bArrowAlight", 1);
	}
}

//Lets set your inventory.
public Action:Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new healthDiff = (GetConVarInt(g_Cvar_StartingHealth) - 125);

	if (g_bMedicRound)
	{
		// This is to prevent replacing their inventory if they just spawned as a different class and we haven't changed them yet
		if (TF2_GetPlayerClass(client) != TFClass_Medic)
		{
			return;
		}
		
		new primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if (primary == -1)
		{
			new Handle:item = TF2Items_CreateItem(OVERRIDE_ALL|PRESERVE_ATTRIBUTES);
			TF2Items_SetClassname(item, "tf_weapon_crossbow");
			TF2Items_SetItemIndex(item, 305);
			TF2Items_SetLevel(item, 15);
			TF2Items_SetQuality(item, 6);
			primary = TF2Items_GiveNamedItem(client, item);
			CloseHandle(item);
			EquipPlayerWeapon(client, primary);
		}
		
		// Base is 150 and normally set to 0.25
		TF2Attrib_SetByName(primary, "maxammo primary reduced", GetConVarFloat(g_Cvar_MedicArrowCount) * 0.25);
		
		// Medic base health is 150
		healthDiff = (GetConVarInt(g_Cvar_MedicStartingHealth) - 150);
	}
	else if (g_bEngyRound)
	{
		// This is to prevent replacing their inventory if they just spawned as a different class and we haven't changed them yet
		if (TF2_GetPlayerClass(client) != TFClass_Engineer)
		{
			return;
		}
		
		new primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if (primary == -1)
		{
			new Handle:item = TF2Items_CreateItem(OVERRIDE_ALL|PRESERVE_ATTRIBUTES);
			TF2Items_SetClassname(item, RR);
			TF2Items_SetItemIndex(item, 997);
			TF2Items_SetLevel(item, 15);
			TF2Items_SetQuality(item, 6);
			primary = TF2Items_GiveNamedItem(client, item);
			CloseHandle(item);
			EquipPlayerWeapon(client, primary);
		}
		
		// Base is 125 and normally set to 0.50
		TF2Attrib_SetByName(primary, "maxammo primary reduced", GetConVarFloat(g_Cvar_EngyBoltCount) * 0.50);
		
		// Engy base health is 125
		healthDiff = (GetConVarInt(g_Cvar_EngyStartingHealth) - 125);
	}
	else
	{
		// This is to prevent replacing their inventory if they just spawned as a different class and we haven't changed them yet
		if (TF2_GetPlayerClass(client) != TFClass_Sniper)
		{
			return;
		}

		new primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if (primary == -1)
		{
			new Handle:item = TF2Items_CreateItem(OVERRIDE_ALL|PRESERVE_ATTRIBUTES);
			TF2Items_SetClassname(item, "tf_weapon_compound_bow");
			TF2Items_SetItemIndex(item, 56);
			TF2Items_SetLevel(item, 10);
			TF2Items_SetQuality(item, 6);
			primary = TF2Items_GiveNamedItem(client, item); // disable fancy class select anim
			CloseHandle(item);
			EquipPlayerWeapon(client, primary);
		}
		
		new secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		
		if (secondary == -1)
		{
			new Handle:item = TF2Items_CreateItem(OVERRIDE_ALL|PRESERVE_ATTRIBUTES);
			TF2Items_SetClassname(item, "tf_weapon_jar");
			TF2Items_SetItemIndex(item, 58);
			TF2Items_SetLevel(item, 5);
			TF2Items_SetQuality(item, 6);
			secondary = TF2Items_GiveNamedItem(client, item);
			CloseHandle(item);
			EquipPlayerWeapon(client, secondary);
		}
		
		// Base is 25 and normally set to 0.50
		TF2Attrib_SetByName(primary, "hidden primary max ammo bonus", GetConVarFloat(g_Cvar_ArrowCount) * 0.5);

		// Sniper base health is 125
		healthDiff = (GetConVarInt(g_Cvar_StartingHealth) - 125);
	}
	
	if (healthDiff > 0)
	{
		TF2Attrib_SetByName(client, "max health additive bonus", float(healthDiff));
	}
	else if (healthDiff < 0)
	{
		TF2Attrib_SetByName(client, "max health additive penalty", float(healthDiff));
	}
	
	if (!GetConVarBool(g_Cvar_FallDamage))
	{
		TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
	}
}

//When you take damage, lets set you on firea.
public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	if (!GetConVarBool(g_Cvar_Enabled) || !GetConVarBool(g_Cvar_ExplodeFire) || victim <= 0 || victim > MaxClients ||
	attacker <= 0 || attacker > MaxClients || !IsValidEntity(inflictor))
	{
		return;
	}
	
	
	new String:classname[64];
	if (GetEntityClassname(inflictor, classname, sizeof(classname)) && StrEqual(classname, "env_explosion"))
	{
		new attackerTeam = GetClientTeam(attacker);
		new victimTeam = GetClientTeam(victim);

		if ((!GetConVarBool(g_Cvar_ExplodeFireSelf) && victim == attacker) || (victim != attacker && attackerTeam == victimTeam))
		{
			return;
		}
		TF2_IgnitePlayer(victim, attacker);
	}
}

/******************************************************************************************
 *                                 TF2 CONDITION FORWARDS                                 *
 ******************************************************************************************/

//When someone get's a condition added to them, this gets called.
public TF2_OnConditionAdded(int client, TFCond condition)
{
	if(condition != TFCond_Jarated || !GetConVarBool(g_Cvar_JarateOutline) || !GetConVarBool(g_Cvar_Enabled))
		return;
	else
	{
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
		g_bJarated[client] = true;
	}
}

//When Someone gets a condition removed from them, this gets called.
public TF2_OnConditionRemoved(int client, TFCond condition)
{
	if(condition != TFCond_Jarated || !GetConVarBool(g_Cvar_JarateOutline) || !GetConVarBool(g_Cvar_Enabled))
		return;
	else
	{
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
		g_bJarated[client] = false;
	}
}

//Whenever someone fires, the game decides if it is a critical, and this gets called.
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (GetConVarBool(g_Cvar_Enabled) && GetConVarBool(g_Cvar_JarateFriendlies))
	{
		if (StrEqual(weaponname, "tf_weapon_jar"))
		{
			CreateTimer(0.0, FindJar, client);
		}
	}
	return Plugin_Continue;
}

//When an entity is created, this is automatically called.
public OnEntityCreated(entity, const String:classname[])
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	if (StrEqual(classname, ARROW))
	{
		if (GetConVarBool(g_Cvar_Explode))
		{
			SDKHook(entity, SDKHook_StartTouchPost, Arrow_Explode);
		}
		
		if(GetConVarBool(g_Cvar_FireArrows) && g_bEngyRound)
		{
			SDKHook(entity, SDKHook_Spawn, Arrow_Light);
		}
	}

	if (StrEqual(classname, HEALING_BOLT))
	{
		if (GetConVarBool(g_Cvar_Explode))
		{
			SDKHook(entity, SDKHook_StartTouchPost, Arrow_Explode);
		}
		
		if (GetConVarBool(g_Cvar_FireArrows))
		{
			SDKHook(entity, SDKHook_Spawn, Arrow_Light);
		}
	}
}

/******************************************************************************************
 *                            DECIDING IF NEXT ROUND IS SPECIAL                           *
 ******************************************************************************************/

//We need to decide what type of round next round is going to be.
ChooseSpecialRound()
{
	g_bMedicRound = false;
	g_bEngyRound = false;
	if(g_bSetMedicRound || g_bSetEngyRound)
	{
		if(g_bSetMedicRound)
		{
			g_bMedicRound = true;
			g_bEngyRound = false;
		}
		else
		{
			g_bEngyRound = true;
			g_bMedicRound = false;
		}
	}
	
	else
	{
		new specialPercent = GetConVarInt(g_Cvar_SpecialRound);
		// Do a switch so we don't waste our time with random if it's always on or off.
		switch (specialPercent)
		{
			case 0:
			{
				g_bSpecialRound = false;
			}
			
			case 100:
			{
				g_bSpecialRound = true;
			}
			
			default:
			{
				new chance = GetRandomInt(1, 100);
				if (chance <= specialPercent)
				{
					g_bSpecialRound = true;
				}
				else
				{
					g_bSpecialRound = false;
				}
				
			}
		}
		
		if(g_bSpecialRound)
		{
			new medicPercent = GetConVarInt(g_Cvar_MedicRound);
			new engyPercent = GetConVarInt(g_Cvar_EngyRound);
			new totalPercent = medicPercent + engyPercent;
			
			new decision = GetRandomInt(1, totalPercent);
			
			if(decision <= medicPercent)
			{
				g_bMedicRound = true;
				g_bEngyRound = false;
			}
			else
			{
				g_bEngyRound = true;
				g_bMedicRound = false;
			}
		}
		
		else
		{
			g_bMedicRound = false;
			g_bEngyRound = false;
		}
	}
	
	g_bSpecialRound = false;
	g_bSetMedicRound = false;
	g_bSetEngyRound = false;
}

/******************************************************************************************
 *                                BLOCKING "BUILD" COMMANDS                               *
 ******************************************************************************************/

//What is called whenever you try to build anything as an engineer.
public Action:CommandCallback(int client, const char[] command, int args)
{
	if(GetConVarBool(g_Cvar_Enabled) && GetConVarBool(g_Cvar_BlockBuildings))
	{
		CPrintToChat(client, "%s %T", CHAT_PREF_COLOR, "disabled_buildings", client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

/******************************************************************************************
 *                                      TF2ITEMS EVENT                                    *
 ******************************************************************************************/

//When you are given your base items on spawn, we don't want you to have everything.
public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	static Handle:item = INVALID_HANDLE;
	
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return Plugin_Continue;
	}
	
	if (item != INVALID_HANDLE)
	{
		CloseHandle(item);
		item = INVALID_HANDLE;
	}
	
	// Block SMG, shields, and sniper rifles
	if (StrEqual(classname, "tf_weapon_smg") || iItemDefinitionIndex == 57 || iItemDefinitionIndex == 231 || iItemDefinitionIndex == 642 || StrEqual(classname, "tf_weapon_sniperrifle") || StrEqual(classname, "tf_weapon_sniperrifle_decap"))
	{
		return Plugin_Handled;
	}
	
	// Block Syringe Guns and Mediguns
	if (StrEqual(classname, "tf_weapon_syringegun_medic") || StrEqual(classname, "tf_weapon_medigun"))
	{
		return Plugin_Handled;
	}
	
	// Blocks PDAs and Secondaries
	if((StrEqual(classname, "tf_weapon_pda_engineer_build") && GetConVarBool(g_Cvar_BlockBuildings)) || (StrEqual(classname, "tf_weapon_pda_engineer_destroy") && GetConVarBool(g_Cvar_BlockBuildings)) || StrEqual(classname, "tf_weapon_pistol") || StrEqual(classname, "tf_weapon_laser_pointer") || StrEqual(classname, "tf_weapon_mechanical_arm") || StrEqual(classname, "tf_weapon_shotgun_primary") || StrEqual(classname, "tf_weapon_shotgun") || StrEqual(classname, "tf_weapon_sentry_revenge") || StrEqual(classname, "tf_weapon_drg_pomson"))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/******************************************************************************************
 *                                 EXPLODING PROJECTILES?                                 *
 ******************************************************************************************/

//Explosive arrows. Using an entity.
public Arrow_Explode(entity, other)
{
	new Float:origin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	new team = GetEntProp(entity, Prop_Send, "m_iTeamNum");
	
	new explosion = CreateEntityByName("env_explosion");
	
	if (!IsValidEntity(explosion))
	{
		return;
	}
	
	new String:teamString[2];
	new String:magnitudeString[6];
	new String:radiusString[5];
	IntToString(team, teamString, sizeof(teamString));
	
	GetConVarString(g_Cvar_ExplodeDamage, magnitudeString, sizeof(magnitudeString));
	GetConVarString(g_Cvar_ExplodeRadius, radiusString, sizeof(radiusString));
	
	DispatchKeyValue(explosion, "iMagnitude", magnitudeString);
	DispatchKeyValue(explosion, "iRadiusOverride", radiusString);
	DispatchKeyValue(explosion, "TeamNum", teamString);
	
	SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", owner);
	
	TeleportEntity(explosion, origin, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(explosion);
	
	AcceptEntityInput(explosion, "Explode");
	// Destroy it after a tenth of a second so it still exists during OnTakeDamagePost
	CreateTimer(0.1, Timer_DestroyExplosion, EntIndexToEntRef(explosion), TIMER_FLAG_NO_MAPCHANGE);
	
	new random = GetRandomInt(0, sizeof(g_Sounds_Explode)-1);
	EmitSoundToAll(g_Sounds_Explode[random], entity, SNDCHAN_WEAPON, _, _, _, _, _, origin);
	
	SDKUnhook(entity, SDKHook_Spawn, Arrow_Explode);
}

//Got blow that ish up.
public Action:Timer_DestroyExplosion(Handle:timer, any:explosionRef)
{
	new explosion = EntRefToEntIndex(explosionRef);
	if (explosion != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(explosion, "Kill");
	}
	
	return Plugin_Continue;
}

/******************************************************************************************
 *                           PROJECTILES CATCH PEOPLE ON FIIIRE                           *
 ******************************************************************************************/

//FIRE
public Arrow_Light(entity)
{
	// Sniper arrows will be already lit, but Medic arrows won't
	if (!GetEntProp(entity, Prop_Send, "m_bArrowAlight"))
	{
		SetEntProp(entity, Prop_Send, "m_bArrowAlight", 1);
	}
	
	SDKUnhook(entity, SDKHook_Spawn, Arrow_Light);
}

/******************************************************************************************
 *                                     SUPPPAAAA JUMPS                                    *
 ******************************************************************************************/

//Our timers for our super jump charges.
public Action:JumpTimer(Handle:hTimer)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return Plugin_Stop;
	}
	
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
		{
			continue;
		}
		
		if (g_bDoubleJumped[i] && (GetEntityFlags(i) & FL_ONGROUND))
		{
			g_bDoubleJumped[i] = false;
		}
		
		new primary = GetPlayerWeaponSlot(i, TFWeaponSlot_Primary);
		new currentWeapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
		
		if(GetConVarBool(g_Cvar_FireArrows) && !g_bMedicRound && !g_bEngyRound)
		{
			if(g_bBowOut[i] && primary != currentWeapon)
			{
				g_bBowOut[i] = false;
				
				if (GetEntProp(primary, Prop_Send, "m_bArrowAlight") == 1)
				{
					SetEntProp(primary, Prop_Send, "m_bArrowAlight", 0);
				}
			}
			else if(!g_bBowOut[i] && primary == currentWeapon)
			{
				g_bBowOut[i] = true;
				
				if (GetEntProp(primary, Prop_Send, "m_bArrowAlight") == 0)
				{
					SetEntProp(primary, Prop_Send, "m_bArrowAlight", 1);
				}
			}
			else if(g_bBowOut[i] && primary == currentWeapon)
			{
				if (GetEntProp(primary, Prop_Send, "m_bArrowAlight") == 0)
				{
					SetEntProp(primary, Prop_Send, "m_bArrowAlight", 1);
				}
			}
			else
			{
				if (GetEntProp(primary, Prop_Send, "m_bArrowAlight") == 1)
				{
					SetEntProp(primary, Prop_Send, "m_bArrowAlight", 0);
				}
			}
		}
		
		if (!GetConVarBool(g_Cvar_SuperJump))
		{
			continue;
		}
		
		SetHudTextParams(-1.0, 0.88, 0.35, 255, 255, 255, 255);
		new buttons = GetClientButtons(i);
		if (((buttons & IN_DUCK) || (buttons & IN_ATTACK2)) && (g_JumpCharge[i] >= 0) && !(buttons & IN_JUMP))
		{
			if (g_JumpCharge[i] + 5 < JUMPCHARGE)
			{
				g_JumpCharge[i] += 5;
			}
			else
			{
				g_JumpCharge[i] = JUMPCHARGE;
			}
			
			ShowSyncHudText(i, jumpHUD, "%T", "jump_status", i, g_JumpCharge[i] * 4);
		}
		else if (g_JumpCharge[i] < 0)
		{
			g_JumpCharge[i] += 5;
			ShowSyncHudText(i, jumpHUD, "%T", "jump_status_2", i, -g_JumpCharge[i]/20);
		}
		else
		{
			decl Float:ang[3];
			GetClientEyeAngles(i, ang);
			if ((ang[0] < -45.0) && (g_JumpCharge[i] > 1))
			{
				decl Float:pos[3];
				decl Float:vel[3];
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", vel);
				vel[2]=750 + g_JumpCharge[i] * 13.0;
				SetEntProp(i, Prop_Send, "m_bJumping", 1);
				vel[0] *= (1+Sine(float(g_JumpCharge[i]) * FLOAT_PI / 50));
				vel[1] *= (1+Sine(float(g_JumpCharge[i]) * FLOAT_PI / 50));
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vel);
				g_JumpCharge[i]=GetConVarInt(g_Cvar_SuperJumpTime) * -20;
				
				if (g_bMedicRound)
				{
					new random = GetRandomInt(0, sizeof(g_Sounds_MedicJump)-1);
					EmitSoundToAll(g_Sounds_MedicJump[random], i, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, _, _, _, _, pos);
				}
				else if (g_bEngyRound)
				{
					new random = GetRandomInt(0, sizeof(g_Sounds_EngyJump) - 1);
					EmitSoundToAll(g_Sounds_EngyJump[random], i, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, _, _, _, _, pos);
				}
				else
				{
					new random = GetRandomInt(0, sizeof(g_Sounds_Jump)-1);
					EmitSoundToAll(g_Sounds_Jump[random], i, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, _, _, _, _, pos);
				}
			}
			else
			{
				g_JumpCharge[i] = 0;
			}
		}
	}
	
	return Plugin_Continue;
}

/******************************************************************************************
 *                                    DOUBLE JUMPS                                        *
 ******************************************************************************************/

//When a player jumps, we need to see if he has double jumped.
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!GetConVarBool(g_Cvar_Enabled) || !GetConVarBool(g_Cvar_DoubleJump))
	{
		return Plugin_Continue;
	}
	
	if ((buttons & IN_JUMP) && !(g_LastButtons[client] & IN_JUMP) && !(GetEntityFlags(client) & FL_ONGROUND) && !g_bDoubleJumped[client])
	{
		DoClientDoubleJump(client);
		g_bDoubleJumped[client] = true;
	}
	g_LastButtons[client] = buttons;
	return Plugin_Continue;
}

//If the player decides to double jump, we need to perform the second jump.
stock DoClientDoubleJump(client)
{
	decl Float:forwardVector[3];
	new Float:x, Float:y, Float:z;
	CleanupClientDirection(client, GetClientButtons(client), x, y, z);
	forwardVector[0] = x;
	forwardVector[1] = y;
	forwardVector[2] = z;
	new Float:speed = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
	ScaleVector(forwardVector, speed);
	forwardVector[2] = 245.0;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, forwardVector);
}

/******************************************************************************************
 *                       JARATE FUNCTIONS FOR g_Cvar_JarateFriendlies                     *
 ******************************************************************************************/

//See where your thrown jar of piss is.
public Action:FindJar(Handle:timer, const any:client)
{
	new index = -1, Handle:pack;
	
	while ((index = FindEntityByClassname(index, "tf_weapon_jar")) != -1)
	{
		if (client == GetEntPropEnt(index, Prop_Send, "m_hOwner"))
		{
			if (GetEntProp(index, Prop_Send, "m_iState") == 2)
			{
				CreateTimer(0.1, FindJar, client);
			}
			else
			{
				CreateDataTimer(0.3, JaratePlayers, pack);
				WritePackCell(pack, client);
				WritePackCell(pack, index);
			}
		}
	}
}

//Once your piss lands, we need to see if friendlies are close enough to get hit.
public Action:JaratePlayers(Handle:timer, Handle:dataPack)
{
	decl Float:jarOrigin[3], Float:throwerOrigin[3], Float:clientOrigin[3], Float:distance;
	ResetPack(dataPack);
	new client = ReadPackCell(dataPack), index = ReadPackCell(dataPack), team = GetClientTeam(client);
	
	GetEntPropVector(index, Prop_Send, "m_vecMaxs", jarOrigin);
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", throwerOrigin);
	
	//Convert to absolute origin
	jarOrigin[0] += throwerOrigin[0];
	jarOrigin[1] += throwerOrigin[1];
	jarOrigin[2] += throwerOrigin[2];
	
	for (new i = 1; i < MaxClients; ++i)
	{
		if (IsClientInGame(i))
		{	
			if (GetClientTeam(i) == team && client != i)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", clientOrigin);
				
				distance = GetVectorDistance(jarOrigin, clientOrigin);
				if (distance <= GetConVarFloat(g_Cvar_FFJarateDistance))
				{
					g_bJarated[i] = true;
					CreateTimer(GetConVarFloat(g_Cvar_FFJarateTime), jarateFalse);
					TF2_AddCondition(i, TFCond_Jarated, GetConVarFloat(g_Cvar_FFJarateTime));
				}
			}
		}
	}
}

//What is called once jarate wears off.
public Action:jarateFalse(Handle:timer, any:client)
{
	g_bJarated[client] = false;
}

/******************************************************************************************
 *                                        MULTIMOD                                        *
 ******************************************************************************************/

//Multi mod checks.
public bool:MultiMod_CheckValidMap(const String:map[])
{
	// Doesn't work so well on Mann Vs. Machine, Vs. Saxton Hale, or Prop Hunt maps
	if (StrContains(map, "mvm_", false) != -1 || StrContains(map, "vsh_", false) != -1 || StrContains(map, "ph_", false) != -1)
	{
		return false;
	}
	
	return true;
}

//If the multimod status changes, we need to change the boolean.
public MultiMod_StatusChanged(bool:enabled)
{
	SetConVarBool(g_Cvar_Enabled, enabled);
}

//Translations name.
public MultiMod_TranslateName(client, String:translation[], maxlength)
{
	Format(translation, maxlength, "%T", "game_mode", client);
}

/******************************************************************************************
 *                                       STOCKS                                           *
 ******************************************************************************************/

//The stock that helps us clean up where a client is going.
stock CleanupClientDirection(client, buttons, &Float:x, &Float:y, &Float:z)
{
	buttons = buttons & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT);
	if ((buttons & (IN_FORWARD|IN_BACK)) == (IN_FORWARD|IN_BACK))
	{
		buttons &= ~IN_FORWARD;
		buttons &= ~IN_BACK;
	}
	if ((buttons & (IN_MOVELEFT|IN_MOVERIGHT)) == (IN_MOVELEFT|IN_MOVERIGHT))
	{
		buttons &= ~IN_MOVELEFT;
		buttons &= ~IN_MOVERIGHT;
	}
	if ((buttons & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT)) == 0)
	{
		x = 0.0;
		y = 0.0;
		z = 230.0;
		return;
	}
	decl Float:clientEyeAngle[3];
	GetClientEyeAngles(client, clientEyeAngle);
	clientEyeAngle[0] = 0.0;
	clientEyeAngle[2] = 0.0;
	switch (buttons)
	{
		case (IN_FORWARD|IN_MOVELEFT): clientEyeAngle[1] += 45.0;
		case (IN_FORWARD|IN_MOVERIGHT): clientEyeAngle[1] -= 45.0;
		case (IN_BACK|IN_MOVELEFT): clientEyeAngle[1] += 135.0;
		case (IN_BACK|IN_MOVERIGHT): clientEyeAngle[1] -= 135.0;
		case (IN_MOVELEFT): clientEyeAngle[1] += 90.0;
		case (IN_BACK): clientEyeAngle[1] += 179.9;
		case (IN_MOVERIGHT): clientEyeAngle[1] -= 90.0;
		default: {}
	}
	if (clientEyeAngle[1] <= -180.0) clientEyeAngle[1] += 360.0;
	if (clientEyeAngle[1] > 180.0) clientEyeAngle[1] -= 360.0;
	GetAngleVectors(clientEyeAngle, clientEyeAngle, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(clientEyeAngle, clientEyeAngle);
	x = clientEyeAngle[0];
	y = clientEyeAngle[1];
	z = clientEyeAngle[2];
}

//Checks a client to see if it is valid.
stock bool:IsValidClient(client, bool:checkstv = true) {
	if (client <= 0 || client > MaxClients)
		return false;
	if (!IsClientInGame(client))
		return false;
	if (checkstv && (IsClientReplay(client) || IsClientSourceTV(client)))
		return false;
	return true;
}

stock int EscapeString(const char[] input, int escape, int escaper, char[] output, int maxlen)
{
	// Number of chars we escaped
	int escaped = 0;

	// Format output buffer to ""
	Format(output, maxlen, "");


	// For each char in the input string
	for(int offset = 0; offset < strlen(input); offset++){

		// Get char at the current position
		int ch = input[offset];

		// Found the escape or escaper char
		if(ch == escape || ch == escaper){

			// Escape the escape char with the escaper^^
			Format(output, maxlen, "%s%c%c", output, escaper, ch);

			// Increase numbers of chars we escaped
			escaped++;

		}else
			// Add other char to output buffer
			Format(output, maxlen, "%s%c", output, ch);
	}

	// Return escaped chars
	return escaped;
}

stock int CountCharInString (const char[] sString, char cChar)
{

	int i = 0, count = 0;
	
	while(sString[i] != '\0')
		if(sString[i++] == cChar)
			count++;

	return count;

}

stock int ReadFlagFromConVar(Handle hCvar)
{

	char sBuffer[32];
	GetConVarString(hCvar, sBuffer, sizeof(sBuffer));

	return ReadFlagString(sBuffer);

}

stock bool IsClientAllowed (int client)
{
	if(!IsClientConnected(client))
	{
		PrintToChat(client, "Client Is Connected");
		return false;
	}
	
	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	
	new String:flags[16];
	GetConVarString(g_Cvar_RequiredFlag, flags, sizeof(flags));
	new ibFlags = ReadFlagString(flags);
	
	if(!StrEqual(flags, ""))
	{
		if(view_as<bool>(GetUserFlagBits(client) & ibFlags))
		{
			return true;
		}
	}
	else if(StrEqual(flags, ""))
	{
		return true;
	}
	
	return false;
}

stock bool IsClientDonator(int client)
{
	if(!IsClientConnected(client))
	{
		return false;
	}
	
	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	
	new String:flags[16];
	GetConVarString(g_Cvar_DonatorFlag, flags, sizeof(flags));
	new ibFlags = ReadFlagString(flags);
	if(!StrEqual(flags, ""))
	{
		if(view_as<bool>(GetUserFlagBits(client) & ibFlags))
		{
			return true;
		}
	}
	
	return false;
}
