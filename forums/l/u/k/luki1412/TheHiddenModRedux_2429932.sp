/* [TF2] The Hidden Mod Redux
*
* Originally created by Matheus28 - http://forums.alliedmods.net/showthread.php?t=143577
* Then modified and improved by atomic-penguin(Eric G. Wolfe) and Daniel Murray - https://forums.alliedmods.net/showthread.php?t=206742
* Redux by luki1412
*/

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <morecolors>
#include <clients>
#include <dbi>
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#define REQUIRE_EXTENSIONS

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME "THMR"
#define PLUGIN_VERSION "1.37"

//int gvars
int g_iTheCurrentHidden;
int g_iHiddenCurrentHp;
int g_iHiddenHpMax;
int g_iForceNextHidden;
int g_iForceCommandHidden;
int g_iDamageToHidden[MAXPLAYERS+1];
//bool gvars
bool g_bHiddenSticky;
bool g_bPlaying; 
bool g_bHiddenStarvation;
bool g_bActivated;
bool g_bTimerDie;
bool g_bTimerDieTick;
bool g_bLateLoad;
bool g_bJumped;
bool g_bHiddenPref[MAXPLAYERS+1] = {true, ...};
bool g_bHiddenPrefFunctionality = true;
//float gvars
float g_fHiddenStamina;
float g_fHiddenInvisibility;
float g_fHiddenVisible;
float g_fHiddenBomb;
float g_fTickInterval;
//handles
Handle g_hHiddenHudHp;
Handle g_hHiddenHudStamina;
Handle g_hHiddenHudClusterBomb;
Handle g_hHiddenHudHunger;
Database g_hHiddenPrefDB;
ConVar g_hCV_hidden_pref;
ConVar g_hCV_hidden_version;
ConVar g_hCV_hidden_enabled;
ConVar g_hCV_hidden_taunts;
ConVar g_hCV_hidden_forcebotsclass;
ConVar g_hCV_hidden_tauntdamage;
ConVar g_hCV_hidden_visible_damage; 
ConVar g_hCV_hidden_visible_jarate; 
ConVar g_hCV_hidden_visible_pounce;
ConVar g_hCV_hidden_visible_bomb;
ConVar g_hCV_hidden_replacepyroweapons;
ConVar g_hCV_hidden_replaceheavyweapons;
ConVar g_hCV_hidden_allowsentries;
ConVar g_hCV_hidden_allowdispenserupgrade;
ConVar g_hCV_hidden_allowteleporterupgrade;
ConVar g_hCV_hidden_allowrazorback;
ConVar g_hCV_hidden_hpperplayer;
ConVar g_hCV_hidden_hpbase;
ConVar g_hCV_hidden_stamina;
ConVar g_hCV_hidden_starvationtime;
ConVar g_hCV_hidden_bombtime;
ConVar g_hCV_hidden_bombletcount;
ConVar g_hCV_hidden_bombletmagnitude;
ConVar g_hCV_hidden_bombletspreadvel;
ConVar g_hCV_hidden_bombthrowspeed;
ConVar g_hCV_hidden_bombdetonationdelay;
Handle g_hWeaponEquip;
//cvar globals
int g_iCV_hidden_tauntdamage;
bool g_bCV_hidden_forcebotsclass;
float g_fCV_hidden_stamina;
float g_fCV_hidden_starvationtime;
float g_fCV_hidden_bombtime;
float g_fCV_hidden_visible_damage; 
float g_fCV_hidden_visible_jarate; 
float g_fCV_hidden_visible_pounce;
float g_fCV_hidden_visible_bomb;
//cbomb precache
char g_sCanisterModel[255] = "models/effects/bday_gib01.mdl";
char g_sBombletModel[255] = "models/weapons/w_models/w_grenade_grenadelauncher.mdl";
char g_sDetonationSound[255] = "ambient/machines/slicer3.wav";
//beacon
int g_iBeamSprite = -1;
int g_iHaloSprite = -1;
char g_sBlipSound[255] = "buttons/blip1.wav";
char g_sBeamSprite[255] = "sprites/laser.vmt";
char g_sHaloSprite[255] = "sprites/halo01.vmt";

#if defined _SteamWorks_Included
bool g_bSteamWorks = false;
#endif

public Plugin myinfo = 
{
	name = "The Hidden Mod Redux",
	author = "luki1412",
	description = "The Hidden:Source-like mod for TF2",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=43109"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	if (GetEngineVersion() != Engine_TF2) 
	{
		Format(error, err_max, "[%s] This plugin only works for Team Fortress 2.", PLUGIN_NAME);
		return APLRes_Failure;
	}

	g_bLateLoad = late;
	#if defined _SteamWorks_Included
	MarkNativeAsOptional("SteamWorks_SetGameDescription");
	#endif
	return APLRes_Success;
}

public void OnPluginStart() 
{
	g_hCV_hidden_version = CreateConVar("sm_thehidden_version", PLUGIN_VERSION, "TF2 The Hidden Mod Redux version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD); 
	g_hCV_hidden_enabled = CreateConVar("sm_thehidden_enabled", "1", "Enables/disables the Hidden Mod Redux.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_taunts = CreateConVar("sm_thehidden_allowtaunts", "1", "Enables/disables taunts.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_tauntdamage = CreateConVar("sm_thehidden_allowtauntdamage", "0", "Allow/disallow players to damage The Hidden with their taunts.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_replacepyroweapons = CreateConVar("sm_thehidden_replacepyroprimaries", "1", "Set whether pyro's primary weapons should be replaced with Dragon's Fury.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_replaceheavyweapons = CreateConVar("sm_thehidden_replaceheavyprimaries", "1", "Set whether pyro's primary weapons should be replaced with Brass Beast that has lowered damage.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_allowsentries = CreateConVar("sm_thehidden_allowsentries", "0", "Set whether engineers are allowed to build sentries.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_allowdispenserupgrade = CreateConVar("sm_thehidden_allowdispenserupgrade", "1", "Set whether engineers are allowed to upgrade dispensers.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_allowteleporterupgrade = CreateConVar("sm_thehidden_allowteleporterupgrade", "1", "Set whether engineers are allowed to upgrade teleporters.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_allowrazorback = CreateConVar("sm_thehidden_allowrazorback", "0", "Allow/disallow razorbacks for snipers.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_visible_damage = CreateConVar("sm_thehidden_visibledamage", "0.5", "How much time is the Hidden visible for, after taking weapon damage.", FCVAR_NONE, true, 0.0, true, 5.0);
	g_hCV_hidden_visible_jarate = CreateConVar("sm_thehidden_visiblejarate", "1.0", "How much time is the Hidden visible for, when splashed with jarate, mad milk, or bonked.", FCVAR_NONE, true, 0.0, true, 5.0);
	g_hCV_hidden_visible_pounce = CreateConVar("sm_thehidden_visiblepounce", "0.25", "How much time is the Hidden visible for, when dashing.", FCVAR_NONE, true, 0.0, true, 5.0);
	g_hCV_hidden_visible_bomb = CreateConVar("sm_thehidden_visiblebomb", "1.5", "How much time is the Hidden visible for, after throwing the cluster bomb.", FCVAR_NONE, true, 0.0, true, 5.0);
	g_hCV_hidden_hpbase = CreateConVar("sm_thehidden_hpbase", "300", "Amount of hp used for calculating the Hidden's starting/max hp.", FCVAR_NONE, true, 1.0, true, 10000.0);
	g_hCV_hidden_hpperplayer = CreateConVar("sm_thehidden_hpincreaseperplayer", "70", "This amount of hp, multiplied by the number of players, plus the base hp, equals The Hidden's hp. This is also the amount of HP the Hidden gets after butterknife kills.", FCVAR_NONE, true, 0.0, true, 1000.0);
	g_hCV_hidden_forcebotsclass = CreateConVar("sm_thehidden_forcebotsclass", "1", "Force bots to play as snipers only.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_bombletcount = CreateConVar("sm_thehidden_bombletcount", "6", "Amount of bomb clusters(bomblets) inside a cluster bomb.", FCVAR_NONE, true, 1.0, true, 30.0);
	g_hCV_hidden_bombletmagnitude = CreateConVar("sm_thehidden_bombletmagnitude", "50.0", "Magnitude of a bomblet.", FCVAR_NONE, true, 1.0, true, 1000.0);
	g_hCV_hidden_bombletspreadvel = CreateConVar("sm_thehidden_bombletspreadvel", "50.0", "Maximum spread velocity for a randomized direction, bomblets are going to use.", FCVAR_NONE, true, 1.0, true, 500.0);
	g_hCV_hidden_bombthrowspeed = CreateConVar("sm_thehidden_bombthrowspeed", "1800.0", "Cluster bomb throw speed.", FCVAR_NONE, true, 1.0, true, 8000.0);
	g_hCV_hidden_bombdetonationdelay = CreateConVar("sm_thehidden_bombdetonationdelay", "1.8", "Delay of the cluster bomb detonation.", FCVAR_NONE, true, 0.1, true, 100.0);
	g_hCV_hidden_stamina = CreateConVar("sm_thehidden_stamina", "20.0", "The Hidden's stamina.", FCVAR_NONE, true, 1.0, true, 1000.0);
	g_hCV_hidden_starvationtime = CreateConVar("sm_thehidden_starvationtime", "100.0", "Time until the Hidden dies without killing anyone.", FCVAR_NONE, true, 10.0, true, 1000.0);
	g_hCV_hidden_bombtime = CreateConVar("sm_thehidden_bombtime", "20.0", "Cluster bomb cooldown.", FCVAR_NONE, true, 1.0, true, 1000.0);
	g_hCV_hidden_pref = CreateConVar("sm_thehidden_preferenceenabled", "1", "Sets whether The Hidden preference should be enabled.", FCVAR_NONE, true, 0.0, true, 1.0);
    
	g_fTickInterval = GetTickInterval(); // 0.014999 default

	RegAdminCmd("sm_nexthidden", Cmd_NextHidden, ADMFLAG_CHEATS, "Forces a certain player to be the next Hidden, regardless of who wins the round.");
	RegAdminCmd("sm_hiddennext", Cmd_NextHidden, ADMFLAG_CHEATS, "Forces a certain player to be the next Hidden, regardless of who wins the round.");
	RegConsoleCmd("sm_hiddenhelp", Cmd_HiddenHelp, "Shows the help menu for the Hidden mod redux.");
	RegConsoleCmd("sm_hiddenpref", Cmd_HiddenPref, "Shows the Hidden preference menu.");
	RegConsoleCmd("sm_hiddenpreference", Cmd_HiddenPref, "Shows the Hidden preference menu.");
	
	char errorMessage[255];
	g_hHiddenPrefDB = SQLite_UseDatabase("thehiddenmod", errorMessage, sizeof(errorMessage));

	if (g_hHiddenPrefDB == null) 
	{
		LogError("Failed to connect to the sqlite database for preferences. The Hidden preferences cannot be enabled. Error: %s", errorMessage);
		g_bHiddenPrefFunctionality = false;
	} 
	else 
	{
		if (!CheckTablePresence()) 
		{
			LogMessage("No default table inside the sqlite database for preferences present. Attempting to create one now.");
			if (!CreatePreferenceTable()) 
			{
				LogError("Failed to create the default table inside the sqlite database for preferences. The Hidden preferences cannot be enabled.");
				g_bHiddenPrefFunctionality = false;
			} 
			else 
			{
				LogMessage("The default table inside the sqlite database for preferences was successfully created.");
				g_bHiddenPrefFunctionality = true;
			}
		}
	}

	#if defined _SteamWorks_Included
	g_bSteamWorks = LibraryExists("SteamWorks");
	#endif
	
	// Auto-create the config file
	AutoExecConfig(true, "The_Hidden_Mod_Redux");
	SetConVarString(g_hCV_hidden_version, PLUGIN_VERSION);
	LoadCvars();
	LoadTranslations("the.hidden.mod.redux.phrases");
	
	if (g_bLateLoad && GetConVarBool(g_hCV_hidden_enabled) && IsArenaMap()) 
	{
		OnConfigsExecuted();
		ActivatePlugin();
	} 

	HookConVarChange(g_hCV_hidden_enabled, cvhook_enabled);
	g_hHiddenHudHp = CreateHudSynchronizer();
	g_hHiddenHudStamina = CreateHudSynchronizer();
	g_hHiddenHudHunger = CreateHudSynchronizer();
	g_hHiddenHudClusterBomb = CreateHudSynchronizer();

	GameData hGameConfig = LoadGameConfigFile("the.hidden.mod.redux");
	
	if (!hGameConfig)
	{
		SetFailState("[%s] Can't find the.hidden.mod.redux.txt gamedata! Can't continue.", PLUGIN_NAME);
	}	
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Virtual, "WeaponEquip");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWeaponEquip = EndPrepSDKCall();

	if (!g_hWeaponEquip)
	{
		SetFailState("[%s] Failed to prepare the SDKCall for giving weapons. Try updating gamedata or restarting your server.", PLUGIN_NAME);
	}

	delete hGameConfig;
}
//remove hidden's vision, everything else gets unloaded by sourcemod
public void OnPluginEnd() 
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return;
	}
	
	if (g_iTheCurrentHidden && IsClientInGame(g_iTheCurrentHidden) && IsPlayerAlive(g_iTheCurrentHidden))
	{
		RemoveHiddenPowers(g_iTheCurrentHidden);
		TF2_SetPlayerClass(g_iTheCurrentHidden, TFClass_Spy);
		RequestFrame(Respawn, g_iTheCurrentHidden);
	}

	DeactivatePlugin();	
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SetEntProp(i, Prop_Send, "m_bGlowEnabled", 0);
		}
	}
	
	CreateTimer(2.0, Timer_Win, _, TIMER_FLAG_NO_MAPCHANGE);
}
//if SteamWorks is running
#if defined _SteamWorks_Included
public void OnLibraryAdded(const char[] name) 
{
	if (strcmp(name, "SteamWorks", false) == 0) 
	{
		g_bSteamWorks = true;
	}
	
}
//if SteamWorks isnt running anymore
public void OnLibraryRemoved(const char[] name) 
{
	if (strcmp(name, "SteamWorks", false) == 0) 
	{
		g_bSteamWorks = false;
	}
}
//changing the game in the server browser
void SetGameDescription() 
{
	char gameDesc[64];
	
	if (GetConVarBool(g_hCV_hidden_enabled)) 
	{
		Format(gameDesc, sizeof(gameDesc), "The Hidden Mod Redux");
	} 
	else 
	{
		gameDesc = "Team Fortress";
	}
	
	SteamWorks_SetGameDescription(gameDesc);
}
#endif
//change some tf2 cvars
public void OnConfigsExecuted() 
{
	SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
	SetConVarInt(FindConVar("tf_arena_override_team_size"), 32);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
	SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
	SetConVarInt(FindConVar("mp_autoteambalance"), 0);
	SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), 0);
	SetConVarInt(FindConVar("tf_classlimit"), 0);
	SetConVarInt(FindConVar("tf_playergib"), 0);
	SetConVarInt(FindConVar("tf_bot_reevaluate_class_in_spawnroom"), 0);
	SetConVarString(FindConVar("tf_bot_force_class"), "");
}
//attempt to activate the plugin on mapstart, change game and precache sounds and models
public void OnMapStart() 
{
	PrecacheSound(g_sDetonationSound, true);
	PrecacheModel(g_sCanisterModel, true);
	PrecacheModel(g_sBombletModel, true);
	PrecacheSound(g_sBlipSound, true);

	g_iHaloSprite = PrecacheModel(g_sHaloSprite, true);
	g_iBeamSprite = PrecacheModel(g_sBeamSprite, true);
	
	if (GetConVarBool(g_hCV_hidden_enabled) && IsArenaMap()) 
	{
		ActivatePlugin();
	} 
	else
	{
		LogMessage("This plugin isn't enabled or the current map isn't an arena map. Deactivating the plugin.");
		DeactivatePlugin();
	}
}
//deactivate the plugin on mapend, change game back
public void OnMapEnd() 
{
	if (GetConVarBool(g_hCV_hidden_enabled)) 
	{
		DeactivatePlugin();
	}
}
//load these only when the game starts
void LoadCvars()
{
	g_fCV_hidden_stamina = GetConVarFloat(g_hCV_hidden_stamina);
	g_fCV_hidden_starvationtime = GetConVarFloat(g_hCV_hidden_starvationtime);
	g_fCV_hidden_bombtime = GetConVarFloat(g_hCV_hidden_bombtime);
	g_fCV_hidden_visible_damage = GetConVarFloat(g_hCV_hidden_visible_damage); 
	g_fCV_hidden_visible_jarate = GetConVarFloat(g_hCV_hidden_visible_jarate); 
	g_fCV_hidden_visible_pounce = GetConVarFloat(g_hCV_hidden_visible_pounce);
	g_fCV_hidden_visible_bomb = GetConVarFloat(g_hCV_hidden_visible_bomb);
	g_iCV_hidden_tauntdamage = GetConVarInt(g_hCV_hidden_tauntdamage);
	g_bCV_hidden_forcebotsclass = GetConVarBool(g_hCV_hidden_forcebotsclass);
}
//activate the mod
void ActivatePlugin() 
{
	if (g_bActivated)
	{
		return;
	}

	CreateTimer(30.0, Timer_Win, _, TIMER_FLAG_NO_MAPCHANGE);
	
	g_bActivated = true;
	g_bTimerDieTick = false;
	CreateTimer(0.1, Timer_Tick, _, TIMER_REPEAT);
	
	HookEvent("teamplay_round_win", teamplay_round_win, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_start", teamplay_round_start, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", arena_round_start, EventHookMode_PostNoCopy);

	HookEvent("player_spawn", player_spawn);
	HookEvent("player_hurt", player_hurt);
	HookEvent("player_death", player_death);
	HookEvent("player_upgradedobject", player_upgradedobject);
	HookEvent("player_builtobject", player_builtobject);

	AddCommandListener(Cmd_build, "build");
	AddCommandListener(Cmd_taunt, "taunt");
	AddCommandListener(Cmd_taunt, "+taunt");
	AddCommandListener(Cmd_join, "jointeam");
	AddCommandListener(Cmd_class, "joinclass");
	
	ConVar serverTags = FindConVar("sv_tags");
	
	if (serverTags != null) 
	{
		char tags[512];
		GetConVarString(serverTags, tags, sizeof(tags));
		
		if (StrContains(tags, "thehidden", false) == -1)
		{
			char newTags[512];
			Format(newTags, sizeof(newTags), "%s,%s", tags, "thehidden");
			SetConVarString(serverTags, newTags);
		}
	}
	
	#if defined _SteamWorks_Included	
	if (g_bSteamWorks)
	{
		SetGameDescription(); 
	}
	#endif
	
	for(int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i)) 
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		} 
	} 
}
//deactivate the mod
void DeactivatePlugin() 
{
	if (!g_bActivated)
	{
		return;
	}

	g_bActivated = false;
	g_bTimerDieTick = true;
	CreateTimer(1.0, Timer_EnableCps, _, TIMER_FLAG_NO_MAPCHANGE);
	
	UnhookEvent("teamplay_round_win", teamplay_round_win, EventHookMode_PostNoCopy);
	UnhookEvent("teamplay_round_start", teamplay_round_start, EventHookMode_PostNoCopy);
	UnhookEvent("arena_round_start", arena_round_start, EventHookMode_PostNoCopy);

	UnhookEvent("player_spawn", player_spawn);
	UnhookEvent("player_hurt", player_hurt);
	UnhookEvent("player_death", player_death);
	UnhookEvent("player_upgradedobject", player_upgradedobject);
	UnhookEvent("player_builtobject", player_builtobject);

	RemoveCommandListener(Cmd_build, "build");
	RemoveCommandListener(Cmd_join, "jointeam");
	RemoveCommandListener(Cmd_taunt, "taunt");
	RemoveCommandListener(Cmd_taunt, "+taunt");
	RemoveCommandListener(Cmd_class, "joinclass");	
	
	ConVar serverTags = FindConVar("sv_tags");
	
	if (serverTags != null) 
	{
		char tags[512];
		GetConVarString(serverTags, tags, sizeof(tags));
		
		if (StrContains(tags, "thehidden", false) != -1)
		{
			ReplaceString(tags, sizeof(tags), "thehidden", "", true);
			SetConVarString(serverTags, tags);
		}
	}
	
	#if defined _SteamWorks_Included	
	if (g_bSteamWorks)
	{
		SetGameDescription(); 
	}
	#endif
}
// Hook when player takes damage for max damage calc
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); 
}
//remove the hidden powers on disconnect
public void OnClientDisconnect(int client) 
{
	g_iDamageToHidden[client] = 0;
	g_bHiddenPref[client] = true;

	if (client == g_iTheCurrentHidden) 
	{
		ResetHidden();
	}
}
//read prefs
public void OnClientAuthorized(int client, const char[] auth)
{
	if (IsClientConnected(client)) 
	{
		if (IsFakeClient(client)) 
		{
			g_bHiddenPref[client] = true;
		} 
		else 
		{
			g_bHiddenPref[client] = GetClientHiddenPreference(client);
		}	
	}
}
//block some buildings upgrades
public void player_upgradedobject(Handle event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(g_hCV_hidden_enabled))
	{
		return;
	}
	
	int objectid = GetEventInt(event,"index");
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	int obj = GetEntProp(objectid, Prop_Send, "m_iObjectType");
	int metaloff = FindDataMapInfo(client, "m_iAmmo") + (3 * 4);
	int upgrademetalcost = GetEntProp(objectid, Prop_Send, "m_iUpgradeMetalRequired");
	int clientsmetal = GetEntData(client, metaloff, 4) + upgrademetalcost;

	if (clientsmetal > 200) 
	{
		clientsmetal = 200;
	}
	
	if (GetConVarBool(g_hCV_hidden_allowdispenserupgrade) == false && obj == view_as<int>(TFObject_Dispenser)) 
	{
		SetEntProp(objectid, Prop_Send, "m_iUpgradeLevel", 0);
		SetEntPropFloat(objectid, Prop_Send, "m_flPercentageConstructed", 0.99 );
		SetEntProp(objectid, Prop_Send, "m_bBuilding", 1);
		SetEntData(client, metaloff, clientsmetal, 4, true);
		CPrintToChat(client,"{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_eng");
		return;
	}
	
	if (GetConVarBool(g_hCV_hidden_allowteleporterupgrade) == false && obj == view_as<int>(TFObject_Teleporter)) 
	{
		SetEntProp(objectid, Prop_Send, "m_iUpgradeLevel", 0);
		SetEntPropFloat(objectid, Prop_Send, "m_flPercentageConstructed", 0.99 );
		SetEntProp(objectid, Prop_Send, "m_bBuilding", 1);
		SetEntData(client, metaloff, clientsmetal, 4, true);
		CPrintToChat(client,"{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_eng2");
		return;
	}
}
//block some buildings
public void player_builtobject(Handle event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(g_hCV_hidden_enabled))
	{
		return;
	}
	
	int objectid = GetEventInt(event,"index");
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	int obj = GetEntProp(objectid, Prop_Send, "m_iObjectType");
	int metaloff = FindDataMapInfo(client, "m_iAmmo") + (3 * 4);
	int clientsmetal = GetEntData(client, metaloff, 4) + 125;

	if (clientsmetal > 200) 
	{
		clientsmetal = 200;
	}
	
	if (GetConVarBool(g_hCV_hidden_allowsentries) == false && obj == view_as<int>(TFObject_Sentry)) 
	{
		AcceptEntityInput(objectid, "Kill");
		SetEntData(client, metaloff, clientsmetal, 4, true);
		CPrintToChat(client, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_eng3");
		return;
	}
}
//a player pressed a button
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) 
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}
	
	if (client == g_iTheCurrentHidden) 
	{
		if (g_bHiddenSticky && (buttons&IN_JUMP > 0)) 
		{
			HiddenUnstick();
		}
		
		if (buttons&IN_ATTACK) 
		{
			TF2_RemoveCondition(client, TFCond_Cloaked);
			AddHiddenVisible(0.75);
			
			if (IsFakeClient(client) && GetRandomUInt(0,10) == 0)
			{
				HiddenBombTrigger();
			}
			
			return Plugin_Changed;
		}
		
		if (buttons&IN_ATTACK2 && !IsFakeClient(client)) 
		{
			buttons&=~IN_ATTACK2;
			HiddenSuperJump();
			return Plugin_Changed;
		}
		
		if (buttons&IN_RELOAD) 
		{
			HiddenBombTrigger();
		}
	}
	return Plugin_Continue;
}
//lets block sentries for engies
public Action Cmd_build(int client, char[] cmd, int args)
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int building = StringToInt(arg1);
	
	if (!GetConVarBool(g_hCV_hidden_allowsentries) && building == view_as<int>(TFObject_Sentry)) 
	{
		CPrintToChat(client, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_eng3");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
//block taunts
public Action Cmd_taunt(int client, char[] cmd, int args)
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}
	
	if (!GetConVarBool(g_hCV_hidden_taunts)) 
	{
		CPrintToChat(client, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_taunts");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
//team selection
public Action Cmd_join(int client, char[] cmd, int args)
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}

	if (args > 1) 
	{
		return Plugin_Handled;
	}

	if (Client_Total(2) == 1)
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		if (StrEqual(arg1, "red", true) || StrEqual(arg1, "spectator", true) || StrEqual(arg1, "spectate", true)) 
		{
			return Plugin_Continue;
		}
		else
		{
			if (StrEqual(arg1, "auto", true))
			{
				ChangeClientTeam(client, 2);
				ShowVGUIPanel(client, "class_red");
			}
			else
			{
				PrintCenterText(client, "%t", "hidden_team2");
				ChangeClientTeam(client, 2);
				ShowVGUIPanel(client, "class_red");
			}

			return Plugin_Handled;
    	}
  	}

	return Plugin_Continue;
}
//class change
public Action Cmd_class(int client, char[] cmd, int args)
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}

	if (args > 1 || !IsPlayerHere(client)) 
	{
		return Plugin_Handled;
	}

	int team = GetClientTeam(client);

	if (team < 3)
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
			
		if (StrEqual(arg1, "scout", true) || StrEqual(arg1, "soldier", true) || StrEqual(arg1, "pyro", true) || StrEqual(arg1, "heavyweapons", true) || StrEqual(arg1, "engineer", true) || StrEqual(arg1, "demoman", true) || StrEqual(arg1, "medic", true) || StrEqual(arg1, "sniper", true))
		{
			return Plugin_Continue;
		}
		else
		{
			if (StrEqual(arg1, "random", true))
			{
				SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", PickAClass());
			}
			else
			{
				PrintCenterText(client, "%t", "hidden_class");
				ShowVGUIPanel(client, team == 3 ? "class_blue" : "class_red");		
			}
			return Plugin_Handled;
		}
	}
	else
	{
		PrintCenterText(client, "%t", "hidden_class2");
		return Plugin_Handled;
	}
}
//on take damage hook
public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}

	if (client == g_iTheCurrentHidden)
	{
		if (GetConVarBool(g_hCV_hidden_replaceheavyweapons) && (weapon>0) && (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 312)) 
		{
			damage /= 5.0;
			return Plugin_Changed;
		}

		if (damagetype & DMG_FALL)
		{
			return Plugin_Handled;
		}
		
		if (g_iCV_hidden_tauntdamage == 0)
		{
			switch (damagecustom)
			{
				case TF_CUSTOM_TAUNT_HADOUKEN,TF_CUSTOM_TAUNT_HIGH_NOON,TF_CUSTOM_TAUNT_GRAND_SLAM,TF_CUSTOM_TAUNT_FENCING,TF_CUSTOM_TAUNT_ARROW_STAB,TF_CUSTOM_TAUNT_GRENADE,TF_CUSTOM_TAUNT_BARBARIAN_SWING,TF_CUSTOM_TAUNT_UBERSLICE,TF_CUSTOM_TAUNT_ENGINEER_SMASH,TF_CUSTOM_TAUNT_ENGINEER_ARM,TF_CUSTOM_TAUNT_ARMAGEDDON,TF_CUSTOM_TAUNT_ALLCLASS_GUITAR_RIFF,TF_CUSTOM_FLARE_PELLET,TF_CUSTOM_TAUNTATK_GASBLAST:
				{
					return Plugin_Handled;
				}
			}
		}		
	}
	
	return Plugin_Continue;
}
//a player got hurt, only care about the hidden
public void player_hurt(Handle event, const char[] name, bool dontBroadcast) 
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return;
	}

	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (victim != g_iTheCurrentHidden)
	{
		return;
	}

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));	
	int damage = GetEventInt(event, "damageamount");

	if (attacker != g_iTheCurrentHidden)
	{
		if (damage > g_iHiddenCurrentHp) 
		{
			g_iDamageToHidden[attacker] += g_iHiddenCurrentHp;
		}
		else
		{
			g_iDamageToHidden[attacker] += damage;
		}
	}

	g_iHiddenCurrentHp -= damage;
	
	if (g_iHiddenCurrentHp < 0)
	{
		g_iHiddenCurrentHp = 0;
	}
}
//a player spawned. lets check their classes and change/respawn if needed
public void player_spawn(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!GetConVarBool(g_hCV_hidden_enabled) || !IsPlayerHere(client) || !IsPlayerAlive(client)) 
	{
		return;
	}
	
	g_iDamageToHidden[client] = 0;
	TFClassType class = view_as<TFClassType>(GetEventInt(event, "class"));
	int team = GetClientTeam(client);

	if (client == g_iTheCurrentHidden) 
	{
		if (team != 3) {
			SetEntProp(client, Prop_Send, "m_lifeState", 2);
			ChangeClientTeam(client, 3);
			if (!IsPlayerAlive(client)) {
				RequestFrame(Respawn, client);
			}
			return;
		}

		if (class != TFClass_Spy)
		{
			TF2_SetPlayerClass(client, TFClass_Spy, false, true);
			RequestFrame(Respawn, client);
		}
		else
		{
			RequestFrame(GiveHiddenPowers, client);
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
		}
		
		return;
	}
	else
	{
		if (team != 2) {
			SetEntProp(client, Prop_Send, "m_lifeState", 2);
			ChangeClientTeam(client, 2);
			if (!IsPlayerAlive(client)) {
				RequestFrame(Respawn, client);
			}
			return;
		}

		if (g_bCV_hidden_forcebotsclass && IsFakeClient(client) && class != TFClass_Sniper)
		{
			TF2_SetPlayerClass(client, TFClass_Sniper, false, true);
			RequestFrame(Respawn, client);
			return;	
		}

		if (class == TFClass_Unknown || class == TFClass_Spy) 
		{
			TF2_SetPlayerClass(client, view_as<TFClassType>(PickAClass()), false, true);
			RequestFrame(Respawn, client);
			return;
		}

		if (GetConVarBool(g_hCV_hidden_replaceheavyweapons) && class == TFClass_Heavy) 
		{
			RequestFrame(HandleHeavyWeapons, client);
		}
		
		if (GetConVarBool(g_hCV_hidden_replacepyroweapons) && class == TFClass_Pyro) 
		{
			RequestFrame(HandlePyroWeapons, client);
		}

		if (!GetConVarBool(g_hCV_hidden_allowrazorback) && class == TFClass_Sniper)
		{
			int ent = MaxClients+1;
			
			for(int n = 0; n <= MaxClients; n++) 
			{
				ent = FindEntityByClassname(ent, "tf_wearable");
				
				if (IsValidEntity(ent)) 
				{
					if (GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex") == 57)
					{
						AcceptEntityInput(ent, "Kill");
						break;
					}
				} 
				else 
				{
					break;
				}
			} 
		}

		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
	}
}
//a player died
public void player_death(Handle event, const char[] name, bool dontBroadcast) 
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return;
	}

	if (!g_bPlaying)
	{
		return;
	}

	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (victim != g_iTheCurrentHidden)
	{
		SetEntProp(victim, Prop_Send, "m_bGlowEnabled", 0);

		if (attacker == g_iTheCurrentHidden)
		{
			g_fHiddenInvisibility = g_fCV_hidden_starvationtime;
			int customkill = GetEventInt(event, "customkill");
			int weaponi = GetEventInt(event, "weaponid");
			
			if (IsPlayerHere(g_iTheCurrentHidden) && IsPlayerAlive(g_iTheCurrentHidden))
			{
				if (customkill != TF_CUSTOM_BACKSTAB && weaponi == TF_WEAPON_KNIFE)
				{
					int hpperkill = GetConVarInt(g_hCV_hidden_hpperplayer);
					
					g_iHiddenCurrentHp += hpperkill; 
					
					if (g_iHiddenCurrentHp > g_iHiddenHpMax) 
					{
						g_iHiddenCurrentHp = g_iHiddenHpMax;
					}

					CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_kill", victim);

					RequestFrame(DissolveRagdoll, victim);
				}
				else
				{
					RequestFrame(GibRagdoll, victim);

					CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_kill2", victim);
				}
			}

			if (GetAliveEnemiesCount() <= 1)
			{
				g_iForceNextHidden = 0;
				CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_win");
			}
		}
	}
	else
	{
		g_iHiddenCurrentHp = 0;
		RemoveHiddenPowers(victim);
		
		if (attacker != g_iTheCurrentHidden && attacker != 0 && !g_bHiddenStarvation) 
		{
			int top = 0;
			
			for(int i = 1; i <= MaxClients; i++)
			{
				if (g_iDamageToHidden[i] >= g_iDamageToHidden[top])
				{
					top = i;
				}
			}

			CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_win2");
			
			if (top > 0 && g_iDamageToHidden[top] > 0)
			{
				g_iForceNextHidden = GetClientUserId(top);

				if (IsHiddenPreferenceEnabled() && (g_bHiddenPref[top] == false)) 
				{
					CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_pref_winner_no_hidden", top);
					g_iForceNextHidden = 0;
				} 
				else 
				{
					CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_winner", top);
				}	
			}
			else
			{
				g_iForceNextHidden = 0;
				CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_winner2");
			}
		}
		else
		{
			g_iForceNextHidden = 0;
			
			if (g_bHiddenStarvation)
			{
				CPrintToChatAll("{mediumseagreen}[%s]{powderblue} %t", PLUGIN_NAME, "hidden_win3");
			}
			else
			{
				CPrintToChatAll("{mediumseagreen}[%s]{powderblue} %t", PLUGIN_NAME, "hidden_win4");
			}
		} 
	}

	return;
}
//spawn another ragdoll so we can gib it
public void GibRagdoll(int client)
{
	int oldragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	
	if (oldragdoll < 0)
	{
		return;
	}

	float RagOrigin[3], RagForce[3], RagVel[3];
	GetEntPropVector(oldragdoll, Prop_Send, "m_vecRagdollOrigin", RagOrigin);
	GetEntPropVector(oldragdoll, Prop_Send, "m_vecForce", RagForce);
	GetEntPropVector(oldragdoll, Prop_Send, "m_vecRagdollVelocity", RagVel);
	AcceptEntityInput(oldragdoll, "Kill");
	
	int newragdoll = CreateEntityByName("tf_ragdoll");
	
	if (IsValidEntity(newragdoll))
	{
		SetEntPropVector(newragdoll, Prop_Send, "m_vecRagdollOrigin", RagOrigin);
		SetEntPropVector(newragdoll, Prop_Send, "m_vecForce", RagForce);
		SetEntPropVector(newragdoll, Prop_Send, "m_vecRagdollVelocity", RagVel);
		SetEntPropEnt(newragdoll, Prop_Send, "m_hPlayer", client);
		SetEntProp(newragdoll, Prop_Send, "m_bGib", 1);
		DispatchSpawn(newragdoll);
	}
}
//ragdoll dissolve
public void DissolveRagdoll(int client) 
{
	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	
	if (ragdoll < 0) 
	{
		return;
	}
	
	int ent = CreateEntityByName("env_entity_dissolver");
	
	if (IsValidEntity(ent)) 
	{
		DispatchKeyValue(ent, "dissolvetype", "3");
		DispatchKeyValue(ent, "target", "!activator");
		DispatchKeyValue(ent, "magnitude", "20");
		AcceptEntityInput(ent, "Dissolve", ragdoll, ragdoll);
		AcceptEntityInput(ent, "Kill");
	}
}
//the game frame, less = better
public void OnGameFrame()
{	
	if (g_iTheCurrentHidden == 0) 
	{
		return;
	}

	if (IsPlayerHere(g_iTheCurrentHidden) && IsPlayerAlive(g_iTheCurrentHidden))
	{
		if (GetClientHealth(g_iTheCurrentHidden) > 0) 
		{
			if (g_iHiddenCurrentHp > g_iHiddenHpMax) 
			{
				SetEntityHealth(g_iTheCurrentHidden, g_iHiddenHpMax);
			} 
			else 
			{
				SetEntityHealth(g_iTheCurrentHidden, g_iHiddenCurrentHp);
			}
		}
		else
		{
			g_iHiddenCurrentHp = 0;
		}
		
		SetEntPropFloat(g_iTheCurrentHidden, Prop_Send, "m_flMaxspeed", 400.0);
		
		if (!g_bHiddenSticky) 
		{
			HiddenUnstick();
			
			if (g_fHiddenStamina < g_fCV_hidden_stamina && !g_bJumped) 
			{
				g_fHiddenStamina += g_fTickInterval*3;
				
				if (g_fHiddenStamina > g_fCV_hidden_stamina) 
				{
					g_fHiddenStamina = g_fCV_hidden_stamina;
				}
			}
		} 
		else
		{
			g_fHiddenStamina -= g_fTickInterval;
			
			if (g_fHiddenStamina <= 0.0) 
			{
				g_fHiddenStamina = 0.0;
				g_bHiddenSticky = false;
				HiddenUnstick();
			} 
			else if (GetEntityMoveType(g_iTheCurrentHidden) == MOVETYPE_WALK) 
			{
				SetEntityMoveType(g_iTheCurrentHidden, MOVETYPE_NONE);
			}
		}
		
		if (g_fHiddenVisible > 0.0) 
		{
			g_fHiddenVisible -= g_fTickInterval;
			
			if (g_fHiddenVisible < 0.0) 
			{
				g_fHiddenVisible = 0.0;
			}
		}
		
		if (g_fHiddenInvisibility > 0.0) 
		{
			g_fHiddenInvisibility -= g_fTickInterval;

			if (g_fHiddenVisible <= 0.0) 
			{
				if (!TF2_IsPlayerInCondition(g_iTheCurrentHidden, TFCond_Cloaked) && !TF2_IsPlayerInCondition(g_iTheCurrentHidden, TFCond_Taunting)) 
				{
					TF2_AddCondition(g_iTheCurrentHidden, TFCond_Cloaked, -1.0);
				}
			} 
			else 
			{
				TF2_RemoveCondition(g_iTheCurrentHidden, TFCond_Cloaked);
			}
		} 
		else 
		{
			TF2_RemoveCondition(g_iTheCurrentHidden, TFCond_Cloaked);
			g_fHiddenInvisibility = 0.0;
			g_bHiddenStarvation = true;
			Client_TakeDamage(g_iTheCurrentHidden, 0, 99999, DMG_CRUSH, "");
			return;
		}
		
		if (g_fHiddenBomb > 0.0) 
		{
			g_fHiddenBomb -= g_fTickInterval;
			
			if (g_fHiddenBomb < 0.0) 
			{
				g_fHiddenBomb = 0.0;
			}
		}

		SetEntPropFloat(g_iTheCurrentHidden, Prop_Send, "m_flCloakMeter", 100.0);
	} 	
}
//conditions
public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (client != g_iTheCurrentHidden)
	{
		return;
	}
	
	switch (condition)
	{
		case TFCond_OnFire:
		{
			AddHiddenVisible(g_fCV_hidden_visible_damage);
			TF2_RemoveCondition(client, condition);
			GiveHiddenVision(client);			
		}
		case TFCond_Ubercharged:
		{
			TF2_RemoveCondition(client, condition);
			GiveHiddenVision(client);		
		}
		case TFCond_Jarated:
		{
			AddHiddenVisible(g_fCV_hidden_visible_jarate);
			TF2_RemoveCondition(client, condition);
			GiveHiddenVision(client);
		}
		case TFCond_Milked, TFCond_Bonked:
		{
			AddHiddenVisible(g_fCV_hidden_visible_jarate);
			TF2_RemoveCondition(client, condition);	
		}
		case TFCond_Taunting:
		{
			AddHiddenVisible(g_fCV_hidden_visible_jarate);
		}
		case TFCond_Bleeding:
		{
			AddHiddenVisible(g_fCV_hidden_visible_damage);
			TF2_RemoveCondition(client, condition);
			GiveHiddenVision(client);
		}
		case TFCond_DeadRingered, TFCond_Kritzkrieged, TFCond_MarkedForDeath, TFCond_CritOnFirstBlood:
		{
			TF2_RemoveCondition(client, condition);
		}
		case TFCond_Disguising, TFCond_Disguised:
		{
			if (!IsFakeClient(client))
			{
				TF2_RemoveCondition(client, condition);
			}
		}
	}
}
//pause the invisibility
void AddHiddenVisible(float value) 
{
	if (g_fHiddenVisible < value) 
	{
		g_fHiddenVisible = value;
	}
}
//someone won, reset the hidden
public void teamplay_round_win(Handle event, const char[] name, bool dontBroadcast) 
{
	g_bPlaying = true;
	g_bTimerDie = true;
	CreateTimer(0.1, Timer_ResetHidden, _, TIMER_FLAG_NO_MAPCHANGE);
}
//round start - players cant move but they can change classes
public void teamplay_round_start(Handle event, const char[] name, bool dontBroadcast) 
{
	if (!CanPlay()) 
	{
		CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_start");
		return;
	}

	LoadCvars();	
	g_bPlaying = false;
	NewGame();
}
//arena start - players can move, cant change classes
public void arena_round_start(Handle event, const char[] name, bool dontBroadcast) 
{
	Client_RespawnAll(true);
	g_bPlaying = true;
	g_bHiddenStarvation = false;

	if (IsClientInGame(g_iTheCurrentHidden) && IsFakeClient(g_iTheCurrentHidden) && IsPlayerAlive(g_iTheCurrentHidden))
	{
		g_bTimerDie = false;
		CreateTimer(1.0, Timer_Beacon, g_iTheCurrentHidden, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT );
	}
}
//a beacon for the hidden bot
public Action Timer_Beacon(Handle timer, any client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || g_bTimerDie == true)
	{
		return Plugin_Stop;
	}
	
	float vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;
	
	if (g_iBeamSprite > -1 && g_iHaloSprite > -1)
	{
		int Color[4] = {10, 10, 255, 255};
		TE_SetupBeamRingPoint(vec, 10.0, 400.0, g_iBeamSprite, g_iHaloSprite, 0, 30, 1.0, 10.0, 0.0, Color, 10, 0);
		TE_SendToAll();
	}
	
	if (g_sBlipSound[0])
	{
		EmitAmbientSound(g_sBlipSound, vec, client, SNDLEVEL_RAIDSIREN);	
	}
	
	return Plugin_Continue;
}
//disable control points
public Action Timer_DisableCps(Handle timer) 
{
	int CPTCA = MaxClients+1;

	while((CPTCA = FindEntityByClassname(CPTCA, "trigger_capture_area")) != -1) 
	{
		if (IsValidEntity(CPTCA)) 
		{
			AcceptEntityInput(CPTCA, "Disable");
		}
	}

	int logic = FindEntityByClassname(MaxClients+1, "tf_logic_arena");

	if (IsValidEntity(logic)) 
	{
		SetEntPropFloat(logic, Prop_Data, "m_flTimeToEnableCapPoint", 0.0);
	}

	return Plugin_Continue;
}
//enable control points
public Action Timer_EnableCps(Handle timer) 
{
	int CPTCA = MaxClients+11;

	while((CPTCA = FindEntityByClassname(CPTCA, "trigger_capture_area")) != -1) 
	{
		if (IsValidEntity(CPTCA)) 
		{
			AcceptEntityInput(CPTCA, "Enable");
		}
	}

	int logic = FindEntityByClassname(MaxClients+1, "tf_logic_arena");

	if (IsValidEntity(logic)) 
	{
		SetEntPropFloat(logic, Prop_Data, "m_flTimeToEnableCapPoint", 60.0);
	}

	return Plugin_Continue;
}
//new game
void NewGame() 
{
	if (g_iTheCurrentHidden != 0) 
	{
		return;
	}
	
	CreateTimer(1.0, Timer_DisableCps, _, TIMER_FLAG_NO_MAPCHANGE);
	SelectHidden();

	for(int n = 0; n <= MAXPLAYERS; n++) 
	{
		g_iDamageToHidden[n] = 0;
	}
	
	RequestFrame(RespawnAll, _);
}
//respawn all
public void RespawnAll(int client)
{
    Client_RespawnAll(false);
}
//timer callback for resetting the hidden
public Action Timer_ResetHidden(Handle timer) 
{
	ResetHidden();
	return Plugin_Continue;
}
//respawn a player
public void Respawn(int client) 
{
	TF2_RespawnPlayer(client);
	return;
}
//notify everyone that they can use the help command and pref command
public Action NotifyPlayers(Handle timer) 
{
	CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_notify");

	if (IsHiddenPreferenceEnabled()) 
	{
		CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_notify2");
	}

	return Plugin_Continue;
}
//jump check
public Action Timer_Jumped(Handle timer, any data)
{
	g_bJumped = false;
	return Plugin_Continue;
}
//kill all bots at the start
public Action Timer_Win(Handle timer, any data) 
{
	CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_botkill");

	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && IsPlayerAlive(i))
		{
			Client_TakeDamage(i, i, 99999, DMG_CRUSH, "");
		}
	}

	return Plugin_Continue;
}
//hud timer
public Action Timer_Tick(Handle timer) 
{
	if (g_bTimerDieTick == true)
	{
		return Plugin_Stop;
	}
	
	ShowHiddenHP();
	return Plugin_Continue;
}
//force next hidden command
public Action Cmd_NextHidden(int client, int args) 
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}
	
	if (args != 1) 
	{
		CReplyToCommand(client, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_command");
		return Plugin_Handled;
	}
	
	char tmp[128];
	GetCmdArg(1, tmp, sizeof(tmp));
	int target = FindTarget(client, tmp, false, false);
	
	if (target < 1)
	{
		CReplyToCommand(client, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_command5");
		return Plugin_Handled;
	}
	
	if (GetClientTeam(target) <= 1)
	{
		CReplyToCommand(client, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_command2");
		return Plugin_Handled;	
	}
	
	g_iForceCommandHidden = GetClientUserId(target);
	CReplyToCommand(client, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_command3", target);
	return Plugin_Handled;
}
//cmd for pref menu
public Action Cmd_HiddenPref(int client, int args)
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}
	
	if (!IsHiddenPreferenceEnabled()) 
	{
		CPrintToChat(client, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_pref_disabled");
		return Plugin_Continue;
	}

	if (IsPlayerHere(client))
	{
		char buffer[256];
		Panel panel = new Panel();
		Format(buffer,256,"%t","hidden_pref");
		panel.SetTitle(buffer);
		Format(buffer,256,"%t%s","hidden_pref_control", g_bHiddenPref[client] == true ? " ✓" : "");
		panel.DrawItem(buffer);
		Format(buffer,256,"%t%s","hidden_pref_control2", g_bHiddenPref[client] == false ? " ✓" : "");
		panel.DrawItem(buffer);
		Format(buffer,10,"%t","hidden_menu_control3");
		panel.DrawItem(buffer,ITEMDRAW_CONTROL);
		panel.Send(client, PerfPanelHandler, 30);
	 
		delete panel;
	}

	return Plugin_Handled;
}
//pref menu handler
public int PerfPanelHandler(Menu menu, MenuAction action, int client, int selection)
{
	if (action == MenuAction_Select && IsPlayerHere(client))
	{
		switch (selection)
		{
			case 1: {
				SetClientHiddenPreference(client,1);
				g_bHiddenPref[client] = true;
			}
			case 2: {
				SetClientHiddenPreference(client,0);
				g_bHiddenPref[client] = false;
			}
		}
	}

	return 0;
}
//does the preference sql table exist
bool CheckTablePresence()
{
	DBResultSet query = SQL_Query(g_hHiddenPrefDB, "SELECT name FROM sqlite_master WHERE type='table' AND name='preference'");
	if (query == null)
	{
		char error[255];
		SQL_GetError(g_hHiddenPrefDB, error, sizeof(error));
		LogError("Failed to check whether the Hidden preference table exists (error: %s)", error);
		return false;
	} 
	else 
	{
		bool result = false;

		if (query.RowCount == 1) 
		{
			result = true;
		}

		delete query;
		return result;
	}
}
//create the preference sql table
bool CreatePreferenceTable()
{
	return SQL_FastQuery(g_hHiddenPrefDB, "CREATE TABLE 'preference' ('STEAM_ID' TEXT NOT NULL,	'Preference' INTEGER NOT NULL DEFAULT 1, PRIMARY KEY('STEAM_ID'))");
}
//set pref
bool SetClientHiddenPreference(int client, int preference)
{
	char steamId[32];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	char queryString[100];
	Format(queryString, sizeof(queryString), "REPLACE INTO preference VALUES ('%s',%i)", steamId, preference);

	bool success = SQL_FastQuery(g_hHiddenPrefDB, queryString);
	if (success == true) 
	{
		CPrintToChat(client, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_pref_change_success");
		return true;
	} 
	else 
	{
		CPrintToChat(client, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_pref_change_failure");
		char error[255];
		SQL_GetError(g_hHiddenPrefDB, error, sizeof(error));
		LogError("Failed to set the Hidden preference (error: %s)", error);
		return false;
	}
}
//get pref
bool GetClientHiddenPreference(int client)
{
	char steamId[32];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	char queryString[100];
	Format(queryString, sizeof(queryString), "SELECT Preference FROM preference WHERE STEAM_ID = '%s'",steamId);

	DBResultSet query = SQL_Query(g_hHiddenPrefDB, queryString);
	if (query == null)
	{
		char error[255];
		SQL_GetError(g_hHiddenPrefDB, error, sizeof(error));
		LogError("Failed to query the Hidden preference (error: %s)", error);
		return true;
	} 
	else 
	{
		/* Process results here! */
		bool result = true;
		if (SQL_FetchRow(query)) 
		{
			result = SQL_FetchInt(query, 0) == 1 ? true : false;
		}
		/* Free the Handle */
		delete query;
		return result;
	}
}
//cmd for help menu
public Action Cmd_HiddenHelp(int client, int args)
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}
	
	if (IsPlayerHere(client))
	{
		char buffer[256];
		Panel panel = new Panel();
		Format(buffer,256,"%t","hidden_menu_title");
		panel.SetTitle(buffer);
		Format(buffer,256,"%t","hidden_menu");
		panel.DrawItem(buffer);
		Format(buffer,256,"%t","hidden_menu2");
		panel.DrawItem(buffer);
		Format(buffer,256,"%t","hidden_menu3");
		panel.DrawItem(buffer);
		Format(buffer,10,"%t","hidden_menu_control3");
		panel.DrawItem(buffer,ITEMDRAW_CONTROL);
		panel.Send(client, PanelHandler1, 30);
	 
		delete panel;
	}

	return Plugin_Handled;
}
//help menu handler
public int PanelHandler1(Menu menu, MenuAction action, int client, int selection)
{
	char buffer[512];

	if (action == MenuAction_Select && IsPlayerHere(client))
	{
		switch (selection)
		{
			case 1: {
				Panel panel = new Panel();
				Format(buffer,512,"%t","hidden_menu");
				panel.SetTitle(buffer);
				panel.DrawText("------------------------------");
				Format(buffer,512,"%t","hidden_help");
				panel.DrawText(buffer);
				Format(buffer,10,"%t","hidden_menu_control2");
				panel.DrawItem(buffer,ITEMDRAW_CONTROL);
				Format(buffer,10,"%t","hidden_menu_control3");
				panel.DrawItem(buffer,ITEMDRAW_CONTROL);
				panel.Send(client, PanelHandler2, 100);
			 
				delete panel;
			}
			case 2: {
				Panel panel = new Panel();
				Format(buffer,512,"%t","hidden_menu2");
				panel.SetTitle(buffer);
				panel.DrawText("------------------------------");
				Format(buffer,512,"%t","hidden_help2");
				panel.DrawText(buffer);
				Format(buffer,10,"%t","hidden_menu_control");
				panel.DrawItem(buffer,ITEMDRAW_CONTROL);
				Format(buffer,10,"%t","hidden_menu_control3");
				panel.DrawItem(buffer,ITEMDRAW_CONTROL);
				panel.Send(client, PanelHandler3, 100);
			 
				delete panel;
			}
			case 3: {
				Panel panel = new Panel();
				Format(buffer,512,"%t","hidden_menu3");
				panel.SetTitle(buffer);
				panel.DrawText("------------------------------");
				Format(buffer,512,"%t","hidden_help3");
				panel.DrawText(buffer);
				Format(buffer,10,"%t","hidden_menu_control");
				panel.DrawItem(buffer,ITEMDRAW_CONTROL);
				Format(buffer,10,"%t","hidden_menu_control3");
				panel.DrawItem(buffer,ITEMDRAW_CONTROL);
				panel.Send(client, PanelHandler4, 100);
			 
				delete panel;
			}
		}
	}

	return 0;
}

public int PanelHandler2(Menu menu, MenuAction action, int client, int selection)
{
	char buffer[256];
	
	if (action == MenuAction_Select && selection != 2 && IsPlayerHere(client))
	{
		Format(buffer,256,"%t","hidden_menu");
		Panel panel = new Panel();
		panel.SetTitle("The Hidden Mod Redux help menu");
		panel.DrawItem(buffer);
		Format(buffer,256,"%t","hidden_menu2");
		panel.DrawItem(buffer);
		Format(buffer,256,"%t","hidden_menu3");
		panel.DrawItem(buffer);
		Format(buffer,10,"%t","hidden_menu_control3");
		panel.DrawItem(buffer,ITEMDRAW_CONTROL);
		panel.Send(client, PanelHandler1, 30);
	 
		delete panel;
	}

	return 0;
}

public int PanelHandler3(Menu menu, MenuAction action, int client, int selection)
{
	char buffer[512];
	
	if (selection != 2 && IsPlayerHere(client))
	{
		Panel panel = new Panel();
		Format(buffer,512,"%t","hidden_menu2");
		panel.SetTitle(buffer);
		panel.DrawText("------------------------------");
		Format(buffer,512,"%t","hidden_help2b");
		panel.DrawText(buffer);
		Format(buffer,10,"%t","hidden_menu_control2");
		panel.DrawItem(buffer,ITEMDRAW_CONTROL);
		Format(buffer,10,"%t","hidden_menu_control3");
		panel.DrawItem(buffer,ITEMDRAW_CONTROL);
		panel.Send(client, PanelHandler2, 100);
	 
		delete panel;
	}

	return 0;
}

public int PanelHandler4(Menu menu, MenuAction action, int client, int selection)
{
	char buffer[512];
	
	if (selection != 2 && IsPlayerHere(client))
	{
		Panel panel = new Panel();
		Format(buffer,512,"%t","hidden_menu3");
		panel.SetTitle(buffer);
		panel.DrawText("------------------------------");
		Format(buffer,512,"%t","hidden_help3b");
		panel.DrawText(buffer);
		Format(buffer,10,"%t","hidden_menu_control2");
		panel.DrawItem(buffer,ITEMDRAW_CONTROL);
		Format(buffer,10,"%t","hidden_menu_control3");
		panel.DrawItem(buffer,ITEMDRAW_CONTROL);
		panel.Send(client, PanelHandler2, 100);
	 
		delete panel;
	}

	return 0;
}
//is this an arena map?
bool IsArenaMap() 
{
	return FindEntityByClassname(MaxClients+1, "tf_logic_arena") > -1;
}
//is there enough players? can we play?
bool CanPlay() 
{
	int numClients = Client_Total();
	// Requires 2 or more players, including bots in the server.
	if (numClients >= 2) 
	{
		return true;
	} 
	else 
	{
		return false;
	}
}
//enable or disable the plugin - cvar changed
public void cvhook_enabled(Handle cvar, const char[] oldVal, const char[] newVal) 
{
	if (GetConVarBool(g_hCV_hidden_enabled) && IsArenaMap()) 
	{
		ActivatePlugin();
	} 
	else 
	{
		DeactivatePlugin();
	}
}
//respawn everyone according to the plan
void Client_RespawnAll(bool Notify) 
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			switch (GetClientTeam(i))
			{
				case 0,1:
				{
					continue;
				}
				case 2:
				{
					if (i == g_iTheCurrentHidden)
					{
						SetEntProp(i, Prop_Send, "m_lifeState", 2);
						TF2_SetPlayerClass(i, TFClass_Spy, false, true);
						ChangeClientTeam(i, 3);
						if (!IsPlayerAlive(i)) {
							RequestFrame(Respawn, i);
						}

						if (Notify)
						{
							CPrintToChat(i, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_team");
						}
					}
				}
				case 3:
				{
					if (i != g_iTheCurrentHidden)
					{
						SetEntProp(i, Prop_Send, "m_lifeState", 2);
						TF2_SetPlayerClass(i, view_as<TFClassType>(PickAClass()), false, true);
						ChangeClientTeam(i, 2);
						if (!IsPlayerAlive(i)) {
							RequestFrame(Respawn, i);
						}

						if (Notify)
						{
							CPrintToChat(i, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_team");
						}
					}
				}
			}
		}
	}
}
//number of players
int Client_Total(int divider = 1)
{
	int numClients = 0;
	
	for(int client = 1; client <= MaxClients; client++) 
	{
		
		if (!IsClientInGame(client) || IsClientReplay(client) || IsClientSourceTV(client) || GetClientTeam(client) <= divider ) 
		{
			continue;
		}
		
		numClients++;
	}
	
	return numClients;
}
//get a random player
int Client_GetRandom()
{
	int[] clients = new int[MaxClients];
	int num;

	if (IsHiddenPreferenceEnabled()) 
	{
		num = Client_Get(clients, true);

		if (num == 0) 
		{
			CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_pref_no_hidden");
			num = Client_Get(clients, false);
		}
	} 
	else 
	{
		num = Client_Get(clients, false);
	}

	if (num == 0) 
	{
		return -1;
	}
	else if (num == 1) 
	{
		return clients[0];
	}

	int random = GetRandomUInt(0, num-1);
	return clients[random];
}
//clients count
int Client_Get(int[] clients, bool considerPref)
{
	int x = 0;
	
	for(int client = 1; client <= MaxClients; client++) 
	{
		if (IsClientInGame(client) && (GetClientTeam(client) >= 2) && ((considerPref == true && g_bHiddenPref[client] == true) || considerPref == false)) 
		{
			clients[x++] = client;
		}
	}

	return x;
}
//pick a random class
int PickAClass()
{
	int cl = GetRandomUInt(1,8);
	
	if (cl == 8)
	{
		cl = 9;
	}
	
	return cl;	
}
//how many enemies left?
int GetAliveEnemiesCount() 
{
	int clients = 0;
	
	for( int i = 1; i <= MaxClients; i++ ) 
	{
		if ( IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && !IsClientSourceTV(i) && !IsClientReplay(i) ) 
		{
			clients += 1;
		}
	}

	return clients;
}
//select the hidden
void SelectHidden() 
{
	g_iTheCurrentHidden = 0;
	g_iHiddenHpMax = GetConVarInt(g_hCV_hidden_hpbase)+((Client_Total()-1)*GetConVarInt(g_hCV_hidden_hpperplayer));
	g_iHiddenCurrentHp = g_iHiddenHpMax;
	g_fHiddenVisible = 0.0;
	g_fHiddenStamina = g_fCV_hidden_stamina;
	g_bHiddenSticky = false;
	g_fHiddenInvisibility = g_fCV_hidden_starvationtime;
	g_fHiddenBomb = 0.0;
	int forcedcommand = GetClientOfUserId(g_iForceCommandHidden);
	
	if (IsPlayerHere(forcedcommand) && (GetClientTeam(forcedcommand) > 1 ))
	{
		g_iTheCurrentHidden = forcedcommand;
		g_iForceCommandHidden = 0;
		CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_command4", forcedcommand);
	}
	else
	{
		int lastWinner = GetClientOfUserId(g_iForceNextHidden);
		
		if (IsPlayerHere(lastWinner) && (GetClientTeam(lastWinner) > 1)) 
		{
			if (IsHiddenPreferenceEnabled() && (g_bHiddenPref[lastWinner] == false)) 
			{
				CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_pref_changed_after_winning", lastWinner);
				g_iTheCurrentHidden = Client_GetRandom();
			} 
			else 
			{
				g_iTheCurrentHidden = lastWinner;
			}
		} 
		else 
		{
			g_iTheCurrentHidden = Client_GetRandom();
		}
	}

	g_iForceNextHidden = 0;
	CreateTimer(3.0, NotifyPlayers, _, TIMER_FLAG_NO_MAPCHANGE );
}
//is hidden preference enabled and working
bool IsHiddenPreferenceEnabled() 
{
	return ((g_bHiddenPrefFunctionality == true) && (GetConVarBool(g_hCV_hidden_pref) == true)) ? true : false;
}
//dash/superjump
void HiddenSuperJump() 
{
	if (g_iTheCurrentHidden == 0 || HiddenStick() != -1 || g_fHiddenStamina < 5.0 || g_bJumped) 
	{
		return;
	}
		
	HiddenUnstick();
	float ang[3];
	GetClientEyeAngles(g_iTheCurrentHidden, ang);
	float vel[3];
	GetEntPropVector(g_iTheCurrentHidden, Prop_Data, "m_vecAbsVelocity", vel);
	float tmp[3];
	GetAngleVectors(ang, tmp, NULL_VECTOR, NULL_VECTOR);
	vel[0] += tmp[0] * 1000.0;
	vel[1] += tmp[1] * 1000.0;
	vel[2] += tmp[2] * 1000.0;
	TeleportEntity(g_iTheCurrentHidden, NULL_VECTOR, NULL_VECTOR, vel);
	AddHiddenVisible(g_fCV_hidden_visible_pounce);
	g_fHiddenStamina -= 5.0;
	g_bJumped = true;
	CreateTimer(1.4, Timer_Jumped, _, TIMER_FLAG_NO_MAPCHANGE);
	return;
}
//stick to the walls
int HiddenStick() 
{
	if (g_iTheCurrentHidden == 0) 
	{
		return 0;
	}
	
	float pos[3];
	float ang[3];
	GetClientEyeAngles(g_iTheCurrentHidden, ang);
	GetClientEyePosition(g_iTheCurrentHidden, pos);
	Handle ray = TR_TraceRayFilterEx(pos, ang, MASK_ALL, RayType_Infinite, TraceRay_HitWorld);
	
	if (TR_DidHit(ray)) 
	{
		float pos2[3];
		TR_GetEndPosition(pos2, ray);
		
		if (GetVectorDistance(pos, pos2) < 64.0) 
		{
			if (g_bHiddenSticky) 
			{
				CloseHandle(ray);
				return 0;
			}
			
			g_bHiddenSticky=true;
			
			if (GetEntityMoveType(g_iTheCurrentHidden)!=MOVETYPE_NONE) 
			{
				SetEntityMoveType(g_iTheCurrentHidden, MOVETYPE_NONE);
			}
			
			CloseHandle(ray);
			return 1;
		} 
		else 
		{
			CloseHandle(ray);
			return -1;
		}
	} 
	else 
	{
		CloseHandle(ray);
		return -1;
	}
}
//unstick the person
void HiddenUnstick() 
{
	g_bHiddenSticky=false;
	
	if (GetEntityMoveType(g_iTheCurrentHidden) == MOVETYPE_NONE) 
	{
		SetEntityMoveType(g_iTheCurrentHidden, MOVETYPE_WALK);
		float vel[3] = {0.0, ...};
		TeleportEntity(g_iTheCurrentHidden, NULL_VECTOR, NULL_VECTOR, vel);
	}
}
//hud stuff
void ShowHiddenHP() 
{
	if (g_iTheCurrentHidden == 0)
	{
		return;
	}
	
	int hppercent = RoundToCeil(float(g_iHiddenCurrentHp)/float(g_iHiddenHpMax)*100.0);
	int stamina = RoundToCeil(g_fHiddenStamina/g_fCV_hidden_stamina*100.0);
	int clusterbomb = RoundToCeil(100.0-g_fHiddenBomb/g_fCV_hidden_bombtime*100.0);
	int hunger = RoundToCeil(100.0-(g_fHiddenInvisibility/g_fCV_hidden_starvationtime*100.0));
	
	if (hppercent <= 0.0)
	{
		return;
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 0)
		{
			if (i != g_iTheCurrentHidden)
			{
				if (hppercent > 25.0) 
				{
					SetHudTextParams(-1.0, 0.1, 0.2, 50, 255, 50, 255, 0, 0.0, 0.0, 0.0);
				} 
				else 
				{
					SetHudTextParams(-1.0, 0.1, 0.2, 255, 50, 50, 255, 0, 0.0, 0.0, 0.0);
				}
				
				ShowSyncHudText(i, g_hHiddenHudHp, "%t: %.0i%%", "hidden_hud", hppercent);
			}
			else
			{
				if (hppercent > 25.0) 
				{
					SetHudTextParams(-1.0, 0.1, 0.2, 40, 255, 40, 255, 0, 0.0, 0.0, 0.0);
				} 
				else 
				{
					SetHudTextParams(-1.0, 0.1, 0.2, 255, 50, 50, 255, 0, 0.0, 0.0, 0.0);
				}
				
				ShowSyncHudText(g_iTheCurrentHidden, g_hHiddenHudHp, "%t: %.0i%%", "hidden_hud2", hppercent);
				SetHudTextParams(-1.0, 0.125, 0.2, 10, 255, 128, 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(g_iTheCurrentHidden, g_hHiddenHudStamina, "%t: %.0i%%", "hidden_hud3", stamina);
				SetHudTextParams(-1.0, 0.150, 0.2, 70, 70, 255, 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(g_iTheCurrentHidden, g_hHiddenHudClusterBomb, "%t: %.0i%%", "hidden_hud4", clusterbomb);
				SetHudTextParams(-1.0, 0.175, 0.2, 144, 40, 255, 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(g_iTheCurrentHidden, g_hHiddenHudHunger, "%t: %.0i%%", "hidden_hud5", hunger);
			}
		}
	} 
}
//create a weapon
bool CreateNamedItem(int client, char[] classname, int itemindex, int level = 0, int quality = 6)
{
	int weapon = CreateEntityByName(classname);
	
	if (!IsValidEntity(weapon))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));	
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);	
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);	
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);

	if (!DispatchSpawn(weapon)) 
	{
		AcceptEntityInput(weapon, "Kill");
		return false;
	}

	if (itemindex == 735) 
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iObjectType"), 3);
		SetEntData(weapon, FindDataMapInfo(weapon, "m_iSubType"), 3);
		int buildables[4] = {0,0,0,1};
		SetEntDataArray(weapon, FindSendPropInfo(entclass, "m_aBuildableObjectTypes"), buildables, 4);
	}
	
	if (itemindex == 1178)
	{
		int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, 40, 4);
	}

	SDKCall(g_hWeaponEquip, client, weapon);
	return true;
}

void HandleHeavyWeapons(int client) 
{
	if (!client) 
	{
		return;
	}

	int wep = GetPlayerWeaponSlot(client, 0);
	int wepIndex = GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex");

	if (wepIndex != 312) 
	{
		TF2_RemoveWeaponSlot(client, 0);
		CreateNamedItem(client, "tf_weapon_minigun", 312,  1, 0);
	}
}

void HandlePyroWeapons(int client) 
{
	if (!client) 
	{
		return;
	}
	
	int wep = GetPlayerWeaponSlot(client, 0);
	int wepIndex = GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex");

	if (wepIndex != 1178) 
	{
		TF2_RemoveWeaponSlot(client, 0);
		CreateNamedItem(client, "tf_weapon_rocketlauncher_fireball", 1178,  1, 0);
	}
}
//give vision
void GiveHiddenVision(int client) 
{
	OverlayCommand(client, "effects/combine_binocoverlay");
}
//remove vision
void RemoveHiddenVision(int client) 
{
	OverlayCommand(client, "\"\"");
}
//set hidden's hud
void Client_SetHideHud(int client, int flags)
{
	SetEntProp(client, Prop_Send, "m_iHideHUD", flags);
}
//give hidden powers
void GiveHiddenPowers(int client) 
{
	if (!client) 
	{
		return;
	}
	
	TF2_RemoveWeaponSlot(client, 0); // Revolver
	TF2_RemoveWeaponSlot(client, 1); // Sapper	
	TF2_RemoveWeaponSlot(client, 2); // Knife
	
	if (!IsFakeClient(client))
	{
		Client_SetHideHud(client, ( 1<<3 ));
		GiveHiddenVision(client);
		TF2_RemoveWeaponSlot(client, 3); // Disguise Kit
	}

	TF2_RemoveWeaponSlot(client, 4); // Invisibility Watch
	CreateNamedItem(client, "tf_weapon_knife", 4,  1, 0);
	CreateNamedItem(client, "tf_weapon_builder", 735, 1, 0);
}
//remove hidden's powers
void RemoveHiddenPowers(int client) 
{
	RemoveHiddenVision(client);
	TF2_RemoveCondition(client, TFCond_Cloaked);
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 320.0);
	Client_SetHideHud(client, 0);
}
//reset the hidden
void ResetHidden() 
{
	if (IsPlayerHere(g_iTheCurrentHidden)) 
	{
		RemoveHiddenPowers(g_iTheCurrentHidden);
	}
	
	g_iTheCurrentHidden = 0;
}
//set the overlay
void OverlayCommand(int client, char[] overlay) 
{    
	if (IsPlayerHere(client)) 
	{
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT));
		ClientCommand(client, "r_screenoverlay %s", overlay);
	}
}
//shoot the bomb if ready
bool HiddenBombTrigger() 
{
	if (g_iTheCurrentHidden == 0 || g_fHiddenBomb > 0.0) 
	{
		return false;
	}

	Command_ClusterBomb(g_iTheCurrentHidden);	
	AddHiddenVisible(g_fCV_hidden_visible_bomb);
	return true;
}
//cbomb and bomblets
public Action Command_ClusterBomb(int client)
{
	if (IsPlayerHere(client) && IsPlayerAlive(client) && g_iTheCurrentHidden != 0)
	{
		float eyePosVecs[3];
		float angVecs[3];
		float fwdVecs[3];			
		GetClientEyePosition(client, eyePosVecs);
		GetClientEyeAngles(client, angVecs);
		GetAngleVectors(angVecs, fwdVecs, NULL_VECTOR, NULL_VECTOR);
		Handle trace = TR_TraceRayFilterEx(eyePosVecs, angVecs, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

		if (TR_DidHit(trace))
		{
			float ePos[3];
			TR_GetEndPosition(ePos, trace);

			if (GetVectorDistance(ePos, eyePosVecs, false) < 45.0)
			{
				CPrintToChat(client, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_problem");
				g_fHiddenBomb = 1.0;
				CloseHandle(trace);
				return Plugin_Handled;
			}
		}
		
		CloseHandle(trace);			
		eyePosVecs[0] += fwdVecs[0] * 32.0;
		eyePosVecs[1] += fwdVecs[1] * 32.0;
		ScaleVector(fwdVecs, GetConVarFloat(g_hCV_hidden_bombthrowspeed));
		int ent = CreateEntityByName("prop_physics_override");
		
		if (IsValidEntity(ent))
		{					
			DispatchKeyValue(ent, "model", g_sCanisterModel);						
			SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
			SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
			DispatchKeyValue(ent, "nodamageforces", "1");
			DispatchKeyValue(ent, "spawnflags", "512");
			SetEntProp(ent, Prop_Send, "m_iTeamNum", 3);
			SetEntProp(ent, Prop_Send, "m_nSkin", 1);
			DispatchSpawn(ent);
			TeleportEntity(ent, eyePosVecs, NULL_VECTOR, fwdVecs);
			g_fHiddenBomb = g_fCV_hidden_bombtime;
			CreateTimer(GetConVarFloat(g_hCV_hidden_bombdetonationdelay), SpawnClusters, ent, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	return Plugin_Handled;
}
//spawn bomb clusters
public Action SpawnClusters(Handle timer, any ent)
{
	if (IsValidEntity(ent))
	{
		float pos[3];
		GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
		int client = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		int particle = CreateEntityByName("info_particle_system");
		AcceptEntityInput(ent, "Kill");
		EmitAmbientSound(g_sDetonationSound, pos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, 0.0);
		
		if (IsValidEntity(particle))
		{					
			DispatchKeyValue(particle, "effect_name", "pyrovision_explosion");
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(particle);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
			CreateTimer(5.0, StopParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
		}

		if (g_iTheCurrentHidden == 0) 
		{
			return Plugin_Handled;
		}

		float ang[3];
		int bombCOunt = GetConVarInt(g_hCV_hidden_bombletcount);

		for(int i = 0; i < bombCOunt; i++)
		{
			float fsv = GetConVarFloat(g_hCV_hidden_bombletspreadvel);
			float minsp = 1.0;
			ang[0] = (GetURandomFloat() * (fsv - minsp) + minsp);
			ang[1] = (GetURandomFloat() * (fsv - minsp) + minsp);
			ang[2] = (GetURandomFloat() * (fsv - minsp) + minsp);
			int ent2 = CreateEntityByName("prop_physics_override");
			
			if (IsValidEntity(ent2))
			{					
				DispatchKeyValue(ent2, "model", g_sBombletModel);	
				SetEntPropEnt(ent2, Prop_Send, "m_hOwnerEntity", client);
				DispatchKeyValue(ent2, "nodamageforces", "1");
				DispatchKeyValue(ent2, "spawnflags", "512");
				SetEntProp(ent2, Prop_Send, "m_nSkin", 1);
				SetEntProp(ent2, Prop_Send, "m_iTeamNum", 3);
				DispatchSpawn(ent2);
				TeleportEntity(ent2, pos, NULL_VECTOR, ang);
				CreateTimer((GetURandomFloat() + 0.1) / 2.0 + 0.5, ExplodeBomblet, ent2, TIMER_FLAG_NO_MAPCHANGE);
			}			
		}
	}

	return Plugin_Handled;
}
//stop the particle
public Action StopParticle(Handle timer, any particle)
{
	if (IsValidEntity(particle))
	{
		AcceptEntityInput(particle, "kill");
	}

	return Plugin_Handled;
}
//explode each cluster/bomblet
public Action ExplodeBomblet(Handle timer, any ent)
{
	if (IsValidEntity(ent))
	{
		float pos[3];
		GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
		pos[2] += 2.0;
		int client = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		int team = GetEntProp(client, Prop_Send, "m_iTeamNum");
		AcceptEntityInput(ent, "Kill");

		if (g_iTheCurrentHidden == 0) 
		{
			return Plugin_Handled;
		}

		int explosion = CreateEntityByName("env_explosion");
		
		if (IsValidEntity(explosion))
		{
			int physexplosion = CreateEntityByName("point_push");

			if (IsValidEntity(physexplosion))
			{
				SetEntPropFloat(physexplosion, Prop_Data, "m_flMagnitude", 600.0);
				SetEntPropFloat(physexplosion, Prop_Data, "m_flRadius", 200.0);
				SetEntProp(physexplosion, Prop_Data, "m_bEnabled", 0);
				DispatchKeyValue(physexplosion, "spawnflags", "27");
				SetEntProp(physexplosion, Prop_Send, "m_iTeamNum", team);
				SetEntPropEnt(physexplosion, Prop_Send, "m_hOwnerEntity", explosion);
				DispatchSpawn(physexplosion);
				ActivateEntity(physexplosion);
				TeleportEntity(physexplosion, pos, NULL_VECTOR, NULL_VECTOR);				
			}

			int tMag = GetConVarInt(g_hCV_hidden_bombletmagnitude);
			SetEntProp(explosion, Prop_Data, "m_iMagnitude", tMag);
			DispatchKeyValue(explosion, "spawnflags", "16384");
			SetEntPropFloat(explosion, Prop_Data, "m_flDamageForce", 0.0);
			SetEntProp(explosion, Prop_Send, "m_iTeamNum", team);
			SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", client);
			DispatchSpawn(explosion);
			ActivateEntity(explosion);
			TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);				
			AcceptEntityInput(explosion, "Explode");

			if (IsValidEntity(physexplosion))
			{
				AcceptEntityInput(physexplosion, "Enable");
				CreateTimer(0.4, StopPush, physexplosion, TIMER_FLAG_NO_MAPCHANGE);
			}

			AcceptEntityInput(explosion, "Kill");
		}		
	}

	return Plugin_Handled;
}

public Action StopPush(Handle timer, any ent)
{
	if (IsValidEntity(ent))
	{
		AcceptEntityInput(ent, "Kill");
	}

	return Plugin_Continue;
}

bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}

bool TraceRay_HitWorld(int entity, int contentsMask) 
{
	return entity == 0;
}
//a better way to dmg players
void Client_TakeDamage(int victim, int attacker, int damage, int dmg_type = DMG_GENERIC, const char[] weapon) 
{ 
	if (IsPlayerHere(victim)) 
	{ 
		char sDamage[16]; 
		char sDamageType[32]; 
		IntToString(damage, sDamage, sizeof(sDamage)); 
		IntToString(dmg_type, sDamageType, sizeof(sDamageType)); 
		int index = CreateEntityByName("point_hurt");

		if (IsValidEntity(index)) 
		{ 
			DispatchKeyValue(victim,"targetname","cod_hurtme"); 
			DispatchKeyValue(index,"DamageTarget","cod_hurtme"); 
			DispatchKeyValue(index,"Damage",sDamage); 
			DispatchKeyValue(index,"DamageType",sDamageType); 
			DispatchKeyValue(index,"classname",weapon); 
			DispatchSpawn(index); 
			AcceptEntityInput(index,"Hurt",attacker); 
			DispatchKeyValue(index,"classname","point_hurt"); 
			DispatchKeyValue(victim,"targetname","cod_donthurtme"); 
			RemoveEdict(index); 
		} 
	} 
}
//random int
int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}
//a check used for non-loops
bool IsPlayerHere(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}