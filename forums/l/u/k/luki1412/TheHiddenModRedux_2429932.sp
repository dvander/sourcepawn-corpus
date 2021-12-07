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
#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#define REQUIRE_EXTENSIONS

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME "THMR"
#define PLUGIN_VERSION "1.24"

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
//float gvars
float g_fHiddenStamina;
float g_fHiddenInvisibility;
float g_fHiddenVisible;
float g_fHiddenBomb;
float g_fTickInterval;
//handles
Handle g_hTick;
Handle g_hHiddenHudHp;
Handle g_hHiddenHudStamina;
Handle g_hHiddenHudClusterBomb;
Handle g_hHiddenHudHunger;
ConVar g_hCV_hidden_version;
ConVar g_hCV_hidden_enabled;
ConVar g_hCV_hidden_taunts;
ConVar g_hCV_hidden_forcebotsclass;
ConVar g_hCV_hidden_tauntdamage;
ConVar g_hCV_hidden_visible_damage; 
ConVar g_hCV_hidden_visible_jarate; 
ConVar g_hCV_hidden_visible_pounce;
ConVar g_hCV_hidden_visible_bomb;
ConVar g_hCV_hidden_allowpyroweapons;
ConVar g_hCV_hidden_allowheavyweapons;
ConVar g_hCV_hidden_allowsentries;
ConVar g_hCV_hidden_allowdispenserupgrade;
ConVar g_hCV_hidden_allowteleporterupgrade;
ConVar g_hCV_hidden_allowrazorback;
ConVar g_hCV_hidden_hpperplayer;
ConVar g_hCV_hidden_hpperkill;
ConVar g_hCV_hidden_hpbase;
ConVar g_hCV_hidden_stamina;
ConVar g_hCV_hidden_starvationtime;
ConVar g_hCV_hidden_bombtime;
ConVar g_hCV_hidden_bombletcount;
ConVar g_hCV_hidden_bombletmagnitude;
ConVar g_hCV_hidden_bombletspreadvel;
ConVar g_hCV_hidden_bombthrowspeed;
ConVar g_hCV_hidden_bombdetonationdelay;
ConVar g_hCV_hidden_bombignoreuser;
ConVar g_hCV_hidden_ghosts;
Handle g_hWeaponEquip;
Handle g_hGameConfig;
//cvar globals
int g_iCV_hidden_tauntdamage;
bool g_bCV_hidden_ghosts;
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

#if defined _steamtools_included
bool g_bSteamTools = false;
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
	if(GetEngineVersion() != Engine_TF2) 
	{
		Format(error, err_max, "[%s] This plugin only works for Team Fortress 2.", PLUGIN_NAME);
		return APLRes_Failure;
	}

	g_bLateLoad = late;
	#if defined _steamtools_included
	MarkNativeAsOptional("Steam_SetGameDescription");
	#endif
	return APLRes_Success;
}

public void OnPluginStart() 
{
	g_hCV_hidden_version = CreateConVar("sm_thehidden_version", PLUGIN_VERSION, "TF2 The Hidden Mod Redux version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD); 
	g_hCV_hidden_enabled = CreateConVar("sm_thehidden_enabled", "1", "Enables/disables the Hidden Mod Redux.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_taunts = CreateConVar("sm_thehidden_allowtaunts", "1", "Enables/disables taunts.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_tauntdamage = CreateConVar("sm_thehidden_allowtauntdamage", "0", "Allow/disallow players to damage The Hidden while taunting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_allowpyroweapons = CreateConVar("sm_thehidden_allowpyroprimaries", "0", "Set whether pyros are allowed to use primary weapons.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_allowsentries = CreateConVar("sm_thehidden_allowsentries", "0", "Set whether engineers are allowed to build sentries.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_allowdispenserupgrade = CreateConVar("sm_thehidden_allowdispenserupgrade", "1", "Set whether engineers are allowed to upgrade dispensers.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_allowteleporterupgrade = CreateConVar("sm_thehidden_allowteleporterupgrade", "1", "Set whether engineers are allowed to upgrade teleporters.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_allowheavyweapons = CreateConVar("sm_thehidden_allowheavyprimaries", "0", "Set whether heavies are allowed to use primary weapons.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_allowrazorback = CreateConVar("sm_thehidden_allowrazorback", "0", "Allow/disallow razorbacks for snipers.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_visible_damage = CreateConVar("sm_thehidden_visibledamage", "0.5", "How much time is the Hidden visible for, after taking weapon damage.", FCVAR_NONE, true, 0.0, true, 5.0);
	g_hCV_hidden_visible_jarate = CreateConVar("sm_thehidden_visiblejarate", "1.0", "How much time is the Hidden visible for, when splashed with jarate, mad milk, or bonked.", FCVAR_NONE, true, 0.0, true, 5.0);
	g_hCV_hidden_visible_pounce = CreateConVar("sm_thehidden_visiblepounce", "0.25", "How much time is the Hidden visible for, when dashing.", FCVAR_NONE, true, 0.0, true, 5.0);
	g_hCV_hidden_visible_bomb = CreateConVar("sm_thehidden_visiblebomb", "1.5", "How much time is the Hidden visible for, after throwing the cluster bomb.", FCVAR_NONE, true, 0.0, true, 5.0);
	g_hCV_hidden_hpbase = CreateConVar("sm_thehidden_hpbase", "300", "Amount of hp used for calculating the Hidden's starting/max hp.", FCVAR_NONE, true, 1.0, true, 10000.0);
	g_hCV_hidden_hpperplayer = CreateConVar("sm_thehidden_hpincreaseperplayer", "70", "This amount of hp, multiplied by the number of players, plus the base hp, equals The Hidden's hp.", FCVAR_NONE, true, 0.0, true, 1000.0);
	g_hCV_hidden_hpperkill = CreateConVar("sm_thehidden_hpincreaseperkill", "50", "Amount of hp the Hidden gets back after he kills a player. This value changes based on victim's class.", FCVAR_NONE, true, 0.0, true, 1000.0);
	g_hCV_hidden_forcebotsclass = CreateConVar("sm_thehidden_forcebotsclass", "1", "Force bots to play as snipers only.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_bombletcount = CreateConVar("sm_thehidden_bombletcount", "10", "Amount of bomb clusters(bomblets) inside a cluster bomb.", FCVAR_NONE, true, 1.0, true, 30.0);
	g_hCV_hidden_bombletmagnitude = CreateConVar("sm_thehidden_bombletmagnitude", "30.0", "Magnitude of a bomblet.", FCVAR_NONE, true, 1.0, true, 1000.0);
	g_hCV_hidden_bombletspreadvel = CreateConVar("sm_thehidden_bombletspreadvel", "60.0", "Spread velocity for a randomized direction, bomblets are going to use.", FCVAR_NONE, true, 1.0, true, 500.0);
	g_hCV_hidden_bombthrowspeed = CreateConVar("sm_thehidden_bombthrowspeed", "2000.0", "Cluster bomb throw speed.", FCVAR_NONE, true, 1.0, true, 10000.0);
	g_hCV_hidden_bombdetonationdelay = CreateConVar("sm_thehidden_bombdetonationdelay", "1.8", "Delay of the cluster bomb detonation.", FCVAR_NONE, true, 0.1, true, 100.0);
	g_hCV_hidden_bombignoreuser = CreateConVar("sm_thehidden_bombignoreuser", "0", "Sets whether the bomb should ignore the Hidden or not.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_stamina = CreateConVar("sm_thehidden_stamina", "20.0", "The Hidden's stamina.", FCVAR_NONE, true, 1.0, true, 1000.0);
	g_hCV_hidden_starvationtime = CreateConVar("sm_thehidden_starvationtime", "100.0", "Time until the Hidden dies without killing.", FCVAR_NONE, true, 10.0, true, 1000.0);
	g_hCV_hidden_bombtime = CreateConVar("sm_thehidden_bombtime", "20.0", "Cluster bomb cooldown.", FCVAR_NONE, true, 1.0, true, 1000.0);
	g_hCV_hidden_ghosts = CreateConVar("sm_thehidden_ghosts", "0", "Sets whether red players should turn to ghosts after death.", FCVAR_NONE, true, 0.0, true, 1.0);
    
	g_fTickInterval = GetTickInterval(); // 0.014999 default
	
	RegAdminCmd("sm_nexthidden", Cmd_NextHidden, ADMFLAG_CHEATS, "Forces a certain player to be the next Hidden, regardless of who wins the round.");
	RegConsoleCmd("sm_hiddenhelp", Cmd_HiddenHelp, "Shows the help menu for the Hidden mod redux.");
	
	#if defined _steamtools_included
	g_bSteamTools = LibraryExists("SteamTools");
	#endif
	
	// Auto-create the config file
	AutoExecConfig(true, "The_Hidden_Mod_Redux");
	SetConVarString(g_hCV_hidden_version, PLUGIN_VERSION);
	LoadCvars();
	LoadTranslations("the.hidden.mod.redux.phrases");
	
	if(g_bLateLoad && GetConVarBool(g_hCV_hidden_enabled) && IsArenaMap()) 
	{
		OnConfigsExecuted();
		ActivatePlugin();
	} 

	HookConVarChange(g_hCV_hidden_enabled, cvhook_enabled);
	g_hHiddenHudHp = CreateHudSynchronizer();
	g_hHiddenHudStamina = CreateHudSynchronizer();
	g_hHiddenHudHunger = CreateHudSynchronizer();
	g_hHiddenHudClusterBomb = CreateHudSynchronizer();
	
	g_hGameConfig = LoadGameConfigFile("the.hidden.mod.redux");
	
	if(!g_hGameConfig)
	{
		SetFailState("[%s] Can't find the.hidden.mod.redux.txt gamedata! Can't continue.", PLUGIN_NAME);
	}	
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Virtual, "WeaponEquip");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWeaponEquip = EndPrepSDKCall();

	if(!g_hWeaponEquip)
	{
		SetFailState("[%s] Failed to prepare the SDKCall forgiving weapons. Try updating gamedata or restarting your server.", PLUGIN_NAME);
	}
}
//remove hidden's vision, everything else gets unloaded by sourcemod
public void OnPluginEnd() 
{
	if(!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return;
	}
	
	if(g_iTheCurrentHidden && IsPlayerHereLoopCheck(g_iTheCurrentHidden) && IsPlayerAlive(g_iTheCurrentHidden))
	{
		RemoveHiddenPowers(g_iTheCurrentHidden);
		TF2_SetPlayerClass(g_iTheCurrentHidden, TFClass_Spy);
		CreateTimer(0.1, Timer_Respawn, g_iTheCurrentHidden, TIMER_FLAG_NO_MAPCHANGE);
	}

	DeactivatePlugin();	
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsPlayerHereLoopCheck(i))
		{
			SetEntProp(i, Prop_Send, "m_bGlowEnabled", 0);
		}
	}
	
	CreateTimer(2.0, Timer_Win, _, TIMER_FLAG_NO_MAPCHANGE);
}
//if steamtools is running
#if defined _steamtools_included
public void OnLibraryAdded(const char[] name) 
{
	if(strcmp(name, "SteamTools", false) == 0) 
	{
		g_bSteamTools = true;
	}
	
}
#endif
//if steamtools isnt running anymore
#if defined _steamtools_included
public void OnLibraryRemoved(const char[] name) 
{
	if(strcmp(name, "SteamTools", false) == 0) 
	{
		g_bSteamTools = false;
	}
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
	PrecacheModel("models/props_halloween/ghost.mdl", true);
	PrecacheSound("vo/halloween_boo1.mp3", true);
	PrecacheSound("vo/halloween_boo2.mp3", true);
	PrecacheSound("vo/halloween_boo3.mp3", true);
	PrecacheSound("vo/halloween_boo4.mp3", true);
	PrecacheSound("vo/halloween_boo5.mp3", true);
	PrecacheSound("vo/halloween_boo6.mp3", true);
	PrecacheSound("vo/halloween_boo7.mp3", true);

	g_iHaloSprite = PrecacheModel(g_sHaloSprite, true);
	g_iBeamSprite = PrecacheModel(g_sBeamSprite, true);
	
	if(GetConVarBool(g_hCV_hidden_enabled) && IsArenaMap()) 
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
	if(GetConVarBool(g_hCV_hidden_enabled)) 
	{
		DeactivatePlugin();
	}
}
// Hook when player takes damage for max damage calc
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); 
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
	g_bCV_hidden_ghosts = GetConVarBool(g_hCV_hidden_ghosts);
	g_bCV_hidden_forcebotsclass = GetConVarBool(g_hCV_hidden_forcebotsclass);
}
//activate the mod
void ActivatePlugin() 
{
	if(g_bActivated)
	{
		return;
	}
	
	CreateTimer(30.0, Timer_Win, _, TIMER_FLAG_NO_MAPCHANGE);
	
	g_bActivated = true;
	g_bTimerDieTick = false;
	g_hTick = CreateTimer(0.2, Timer_Tick, _, TIMER_REPEAT);
	
	HookEvent("teamplay_round_win", teamplay_round_win, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_start", teamplay_round_start, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", arena_round_start, EventHookMode_PostNoCopy);

	HookEvent("player_spawn", player_spawn);
	HookEvent("player_hurt", player_hurt_pre, EventHookMode_Pre);
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
	
	if(serverTags != null) 
	{
		char tags[512];
		GetConVarString(serverTags, tags, sizeof(tags));
		
		if(StrContains(tags, "thehidden", false) == -1)
		{
			char newTags[512];
			Format(newTags, sizeof(newTags), "%s,%s", tags, "thehidden");
			SetConVarString(serverTags, newTags);
		}
	}
	
	#if defined _steamtools_included	
	if(g_bSteamTools)
	{
		SetGameDescription(); 
	}
	#endif
	
	for(int i = 1; i <= MaxClients; i++) 
	{
		if(IsPlayerHereLoopCheck(i)) 
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		} 
	} 
}
//deactivate the mod
void DeactivatePlugin() 
{
	if(!g_bActivated)
	{
		return;
	}
	
	g_bActivated = false;
	g_bTimerDieTick = true;
	g_hTick = null;
	CreateTimer(1.0, Timer_EnableCps, _, TIMER_FLAG_NO_MAPCHANGE);
	
	UnhookEvent("teamplay_round_win", teamplay_round_win, EventHookMode_PostNoCopy);
	UnhookEvent("teamplay_round_start", teamplay_round_start, EventHookMode_PostNoCopy);
	UnhookEvent("arena_round_start", arena_round_start, EventHookMode_PostNoCopy);

	UnhookEvent("player_spawn", player_spawn);
	UnhookEvent("player_hurt", player_hurt_pre, EventHookMode_Pre);
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
	
	if(serverTags != null) 
	{
		char tags[512];
		GetConVarString(serverTags, tags, sizeof(tags));
		
		if(StrContains(tags, "thehidden", false) != -1)
		{
			ReplaceString(tags, sizeof(tags), "thehidden", "", true);
			SetConVarString(serverTags, tags);
		}
	}
	
	#if defined _steamtools_included	
	if(g_bSteamTools)
	{
		SetGameDescription(); 
	}
	#endif
}
//block some buildings upgrades
public void player_upgradedobject(Handle event, const char[] name, bool dontBroadcast)
{
	if(!GetConVarBool(g_hCV_hidden_enabled))
	{
		return;
	}
	
	int objectid = GetEventInt(event,"index");
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	int obj = GetEntProp(objectid, Prop_Send, "m_iObjectType");
	int metaloff = FindDataMapInfo(client, "m_iAmmo") + (3 * 4);
	int upgrademetalcost = GetEntProp(objectid, Prop_Send, "m_iUpgradeMetalRequired");
	int clientsmetal = GetEntData(client, metaloff, 4) + upgrademetalcost;
	if (clientsmetal > 200) {
		clientsmetal = 200;
	}
	
	if(GetConVarBool(g_hCV_hidden_allowdispenserupgrade) == false && obj == view_as<int>(TFObject_Dispenser)) 
	{
		SetEntProp(objectid, Prop_Send, "m_iUpgradeLevel", 0);
		SetEntPropFloat(objectid, Prop_Send, "m_flPercentageConstructed", 0.99 );
		SetEntProp(objectid, Prop_Send, "m_bBuilding", 1);
		SetEntData(client, metaloff, clientsmetal, 4, true);
		CPrintToChat(client,"{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_eng");
		return;
	}
	
	if(GetConVarBool(g_hCV_hidden_allowteleporterupgrade) == false && obj == view_as<int>(TFObject_Teleporter)) 
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
	if(!GetConVarBool(g_hCV_hidden_enabled))
	{
		return;
	}
	
	int objectid = GetEventInt(event,"index");
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	int obj = GetEntProp(objectid, Prop_Send, "m_iObjectType");
	int metaloff = FindDataMapInfo(client, "m_iAmmo") + (3 * 4);
	int clientsmetal = GetEntData(client, metaloff, 4) + 125;
	if (clientsmetal > 200) {
		clientsmetal = 200;
	}
	
	if(GetConVarBool(g_hCV_hidden_allowsentries) == false && obj == view_as<int>(TFObject_Sentry)) 
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
	if(!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}
	
	if(client == g_iTheCurrentHidden) 
	{
		if(g_bHiddenSticky && (buttons&IN_JUMP > 0)) 
		{
			HiddenUnstick();
		}
		
		if(buttons&IN_ATTACK) 
		{
			TF2_RemoveCondition(client, TFCond_Cloaked);
			AddHiddenVisible(0.75);
			
			if(IsFakeClient(client) && GetRandomUInt(0,10) == 0)
			{
				HiddenBombTrigger();
			}
			
			return Plugin_Changed;
		}
		
		if(buttons&IN_ATTACK2 && !IsFakeClient(client)) 
		{
			buttons&=~IN_ATTACK2;
			HiddenSuperJump();
			return Plugin_Changed;
		}
		
		if(buttons&IN_RELOAD) 
		{
			HiddenBombTrigger();
		}
	}
	return Plugin_Continue;
}
//lets block sentries for engies
public Action Cmd_build(int client, char[] cmd, int args)
{
	if(!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int building = StringToInt(arg1);
	
	if(!GetConVarBool(g_hCV_hidden_allowsentries) && building == view_as<int>(TFObject_Sentry)) 
	{
		CPrintToChat(client, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_eng3");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
//block taunts
public Action Cmd_taunt(int client, char[] cmd, int args)
{
	if(!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}
	
	if(!GetConVarBool(g_hCV_hidden_taunts)) 
	{
		CPrintToChat(client, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_taunts");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
//team selection
public Action Cmd_join(int client, char[] cmd, int args)
{
	if(!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}

	if(args > 1) 
	{
		return Plugin_Handled;
	}

	if(Client_TotalBlue() == 1)
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		if(StrEqual(arg1, "red", true)) 
		{
			return Plugin_Continue;
		}
		else if(StrEqual(arg1, "spectator", true) || StrEqual(arg1, "spectate", true))
		{
			if(IsPlayerHere(client)) 
			{
				if(TF2_IsPlayerInCondition(client, TFCond_HalloweenInHell)) 
				{
					TF2_RemoveCondition(client, TFCond_HalloweenInHell);
				}
				
				if(TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode)) 
				{
					TF2_RemoveCondition(client, TFCond_HalloweenGhostMode);
				}
			}

			return Plugin_Continue;
		}
		else
		{
			if(StrEqual(arg1, "auto", true))
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
	if(!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}

	if(args > 1 || !IsPlayerHere(client)) 
	{
		return Plugin_Handled;
	}

	int team = GetClientTeam(client);
	if(team < 3)
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
			
		if(StrEqual(arg1, "scout", true) || StrEqual(arg1, "soldier", true) || StrEqual(arg1, "pyro", true) || StrEqual(arg1, "heavyweapons", true) || StrEqual(arg1, "engineer", true) || StrEqual(arg1, "demoman", true) || StrEqual(arg1, "medic", true) || StrEqual(arg1, "sniper", true))
		{
			return Plugin_Continue;
		}
		else
		{
			if(StrEqual(arg1, "random", true))
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
	if(!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}

	if(client == g_iTheCurrentHidden)
	{
		if(damagetype & DMG_FALL)
		{
			return Plugin_Handled;
		}
		
		if(g_iCV_hidden_tauntdamage == 0)
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
public void player_hurt_pre(Handle event, const char[] name, bool dontBroadcast) 
{
	if(!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return;
	}

	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(victim != g_iTheCurrentHidden)
	{
		return;
	}

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));	
	int damage = GetEventInt(event, "damageamount");

	if(attacker != g_iTheCurrentHidden)
	{
		if(damage > g_iHiddenCurrentHp) 
		{
			g_iDamageToHidden[attacker] += g_iHiddenCurrentHp;
		}
		else
		{
			g_iDamageToHidden[attacker] += damage;
		}
	}	
}

//a player got hurt, only care about the hidden
public void player_hurt(Handle event, const char[] name, bool dontBroadcast) 
{
	if(!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return;
	}

	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(victim != g_iTheCurrentHidden)
	{
		return;
	}

	int damage = GetEventInt(event, "damageamount");
	g_iHiddenCurrentHp -= damage;
	
	if(g_iHiddenCurrentHp < 0)
	{
		g_iHiddenCurrentHp = 0;
	}
}
//a player spawned. lets check their classes and change/respawn if needed
public void player_spawn(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!GetConVarBool(g_hCV_hidden_enabled) || !IsPlayerHere(client) || !IsPlayerAlive(client)) 
	{
		return;
	}

	g_iDamageToHidden[client] = 0;
	TFClassType class = view_as<TFClassType>(GetEventInt(event, "class"));
	
	if(client == g_iTheCurrentHidden) 
	{
		if(class != TFClass_Spy)
		{
			SetEntProp(client, Prop_Send, "m_lifeState", 2);
			ChangeClientTeam(client, 3);
			TF2_SetPlayerClass(client, TFClass_Spy, false, true);
			CreateTimer(0.1, Timer_Respawn, client, TIMER_FLAG_NO_MAPCHANGE);
			return;
		}
		else
		{
			RequestFrame(GiveHiddenPowers, client);
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
			SetVariantString("");
			AcceptEntityInput(client, "SetCustomModel");
		}
		
		if(IsFakeClient(client))
		{
			g_bTimerDie = false;
			CreateTimer(1.0, Timer_Beacon, client, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT );
		}
		
		return;
	}
	else
	{
		int team = GetClientTeam(client);
		
		if(g_bCV_hidden_forcebotsclass && IsFakeClient(client) && class != TFClass_Sniper)
		{
			SetEntProp(client, Prop_Send, "m_lifeState", 2);
			ChangeClientTeam(client, 2);
			TF2_SetPlayerClass(client, TFClass_Sniper, false, true);
			CreateTimer(0.1, Timer_Respawn, client, TIMER_FLAG_NO_MAPCHANGE);
			return;	
		}

		if(class == TFClass_Unknown || class == TFClass_Spy || team != 2) 
		{
			SetEntProp(client, Prop_Send, "m_lifeState", 2);
			ChangeClientTeam(client, 2);
			TF2_SetPlayerClass(client, view_as<TFClassType>(PickAClass()), false, true);
			CreateTimer(0.1, Timer_Respawn, client, TIMER_FLAG_NO_MAPCHANGE);
			return;
		}
		
		if((!GetConVarBool(g_hCV_hidden_allowpyroweapons) && class == TFClass_Pyro) || (!GetConVarBool(g_hCV_hidden_allowheavyweapons) && class == TFClass_Heavy)) 
		{
			TF2_RemoveWeaponSlot(client, 0);
			EquipPlayerWeapon(client, GetPlayerWeaponSlot(client, 2));
		}
		
		if(class == TFClass_Sniper && !GetConVarBool(g_hCV_hidden_allowrazorback))
		{
			int i = MaxClients+1;
			int ent = 0;
			
			for(int n = 0; n <= MaxClients; n++) 
			{
				ent = FindEntityByClassname(i, "tf_wearable");
				
				if(IsValidEntity(ent)) 
				{
					if(GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex") == 57)
					{
						AcceptEntityInput(ent, "Kill");
					}
					
					i = ent;
				} 
				else 
				{
					break;
				}
			} 
		}

		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
	}
}
//a player died
public void player_death(Handle event, const char[] name, bool dontBroadcast) 
{
	if(!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return;
	}

	if(!g_bPlaying)
	{
		return;
	}

	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(victim != g_iTheCurrentHidden)
	{
		SetEntProp(victim, Prop_Send, "m_bGlowEnabled", 0);

		if(TF2_IsPlayerInCondition(victim, TFCond_HalloweenGhostMode)) 
		{   
			RequestFrame(GhostFix, victim);
		}

		if(attacker == g_iTheCurrentHidden)
		{
			g_fHiddenInvisibility = g_fCV_hidden_starvationtime;
			int hpperkill = GetConVarInt(g_hCV_hidden_hpperkill);
			int customkill = GetEventInt(event, "customkill");
			int weaponi = GetEventInt(event, "weaponid");
			
			if(IsPlayerHere(g_iTheCurrentHidden) && IsPlayerAlive(g_iTheCurrentHidden))
			{
				if(customkill != TF_CUSTOM_BACKSTAB && weaponi == TF_WEAPON_KNIFE)
				{				
					TFClassType classv = TF2_GetPlayerClass(victim);
					
					switch (classv)
					{
						case TFClass_Scout, TFClass_Sniper, TFClass_Engineer:
						{
							g_iHiddenCurrentHp += hpperkill; 
							
							if(g_iHiddenCurrentHp > g_iHiddenHpMax) 
							{
								g_iHiddenCurrentHp = g_iHiddenHpMax;
							}			
						}
						case TFClass_Heavy, TFClass_Soldier:
						{
							g_iHiddenCurrentHp += hpperkill+20;
							
							if(g_iHiddenCurrentHp > g_iHiddenHpMax) 
							{
								g_iHiddenCurrentHp = g_iHiddenHpMax;
							}
						}
						default:
						{
							g_iHiddenCurrentHp += hpperkill+10;
							
							if(g_iHiddenCurrentHp > g_iHiddenHpMax) 
							{
								g_iHiddenCurrentHp = g_iHiddenHpMax;
							}
						}
					}

					CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_kill", victim);

					if(!g_bCV_hidden_ghosts) 
					{
						RequestFrame(Dissolve, victim);
					}
				}
				else
				{
					if(!g_bCV_hidden_ghosts) 
					{
					   RequestFrame(GibRagdoll, victim);
					}

					CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_kill2", victim);
				}
			}

			if(GetAliveEnemiesCount() <= 1)
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
		
		if(attacker != g_iTheCurrentHidden && attacker != 0 && !g_bHiddenStarvation) 
		{
			int top = 0;
			
			for(int i = 1; i <= MaxClients; i++)
			{
				if(g_iDamageToHidden[i] >= g_iDamageToHidden[top])
				{
					top = i;
				}
			}

			CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_win2");
			
			if(top > 0 && g_iDamageToHidden[top] > 0)
			{
				g_iForceNextHidden = GetClientUserId(top);
				CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_winner", top);
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
			
			if(g_bHiddenStarvation)
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
//spawn another ragdoll
public void GibRagdoll(int client)
{
	int oldragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	
	if(oldragdoll != -1)
	{
		float RagOrigin[3], RagForce[3], RagVel[3];
		GetEntPropVector(oldragdoll, Prop_Send, "m_vecRagdollOrigin", RagOrigin);
		GetEntPropVector(oldragdoll, Prop_Send, "m_vecForce", RagForce);
		GetEntPropVector(oldragdoll, Prop_Send, "m_vecRagdollVelocity", RagVel);
		AcceptEntityInput(oldragdoll, "Kill");
		
		int newragdoll = CreateEntityByName("tf_ragdoll");
		
		if(newragdoll != -1)
		{
			SetEntPropVector(newragdoll, Prop_Send, "m_vecRagdollOrigin", RagOrigin);
			SetEntPropVector(newragdoll, Prop_Send, "m_vecForce", RagForce);
			SetEntPropVector(newragdoll, Prop_Send, "m_vecRagdollVelocity", RagVel);
			SetEntProp(newragdoll, Prop_Send, "m_iPlayerIndex", client);
			SetEntProp(newragdoll, Prop_Send, "m_bGib", 1);
			DispatchSpawn(newragdoll);
		}
	}
}
//lets fix the ghost
public void GhostFix(int client)
{
    RequestFrame(GhostFix2, client);
}
//one more frame delay to fix flying cosmetics
public void GhostFix2(int client)
{
    if(IsPlayerHere(client)) 
    {
		SetEntProp(client, Prop_Send, "m_lifeState", 2);
		SetVariantInt(2);
		AcceptEntityInput(client, "SetForcedTauntCam");

		SetVariantInt(1);
		AcceptEntityInput(client, "SetCustomModelRotates");

		SetVariantString("models/props_halloween/ghost.mdl");
		AcceptEntityInput(client, "SetCustomModel");
    }
}
//the game frame, less = better
public void OnGameFrame()
{	
	if(g_iTheCurrentHidden == 0) 
	{
		return;
	}

	if(IsPlayerHere(g_iTheCurrentHidden) && IsPlayerAlive(g_iTheCurrentHidden))
	{
		if(GetClientHealth(g_iTheCurrentHidden) > 0) 
		{
			if(g_iHiddenCurrentHp > g_iHiddenHpMax) 
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
		
		if(!g_bHiddenSticky) 
		{
			HiddenUnstick();
			
			if(g_fHiddenStamina < g_fCV_hidden_stamina && !g_bJumped) 
			{
				g_fHiddenStamina += g_fTickInterval*3;
				
				if(g_fHiddenStamina > g_fCV_hidden_stamina) 
				{
					g_fHiddenStamina = g_fCV_hidden_stamina;
				}
			}
		} 
		else
		{
			g_fHiddenStamina -= g_fTickInterval;
			
			if(g_fHiddenStamina <= 0.0) 
			{
				g_fHiddenStamina = 0.0;
				g_bHiddenSticky = false;
				HiddenUnstick();
			} 
			else if(GetEntityMoveType(g_iTheCurrentHidden) == MOVETYPE_WALK) 
			{
				SetEntityMoveType(g_iTheCurrentHidden, MOVETYPE_NONE);
			}
		}
		
		if(g_fHiddenVisible > 0.0) 
		{
			g_fHiddenVisible -= g_fTickInterval;
			
			if(g_fHiddenVisible < 0.0) 
			{
				g_fHiddenVisible = 0.0;
			}
		}
		
		if(g_fHiddenInvisibility > 0.0) 
		{
			g_fHiddenInvisibility -= g_fTickInterval;

			if(g_fHiddenVisible <= 0.0) 
			{
				if(!TF2_IsPlayerInCondition(g_iTheCurrentHidden, TFCond_Cloaked) && !TF2_IsPlayerInCondition(g_iTheCurrentHidden, TFCond_Taunting)) 
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
		
		if(g_fHiddenBomb > 0.0) 
		{
			g_fHiddenBomb -= g_fTickInterval;
			
			if(g_fHiddenBomb < 0.0) 
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
	if(client != g_iTheCurrentHidden)
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
			if(!IsFakeClient(client))
			{
				TF2_RemoveCondition(client, condition);
			}
		}
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
	if(!CanPlay()) 
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

	if(g_bCV_hidden_ghosts) 
	{   
		for(int client = 1; client <= MaxClients; client++) 
		{
			if(IsPlayerHereLoopCheck(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client)) 
			{
				TF2_AddCondition(client, TFCond_HalloweenInHell, 999999.0, 0);
			}
		}
	}
}
//a beacon for the hidden bot
public Action Timer_Beacon(Handle timer, any client)
{
	if(!IsPlayerHereLoopCheck(client) || !IsPlayerAlive(client) || g_bTimerDie == true)
	{
		return Plugin_Stop;
	}
	
	float vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;
	
	if(g_iBeamSprite > -1 && g_iHaloSprite > -1)
	{
		int Color[4] = {0, 0, 255, 255};
		TE_SetupBeamRingPoint(vec, 10.0, 400.0, g_iBeamSprite, g_iHaloSprite, 0, 15, 0.5, 5.0, 0.0, Color, 10, 0);
		TE_SendToAll();
	}
	
	if(g_sBlipSound[0])
	{
		GetClientEyePosition(client, vec);
		EmitAmbientSound(g_sBlipSound, vec, client, SNDLEVEL_RAIDSIREN);	
	}
	
	return Plugin_Continue;
}
//disable control points
public Action Timer_DisableCps(Handle timer) 
{
	int i = MaxClients+1;
	int CP = 0;
	
	for(int n = 0; n <= 5; n++) 
	{
		CP = FindEntityByClassname(i, "trigger_capture_area");
		
		if(IsValidEntity(CP)) 
		{
			AcceptEntityInput(CP, "Disable");
			i = CP;
		} 
		else 
		{
			break;
		}
	} 
}
//enable control points
public Action Timer_EnableCps(Handle timer) 
{
	int i = MaxClients+1;
	int CP = 0;
	
	for(int n = 0; n <= 5; n++) 
	{
		CP = FindEntityByClassname(i, "trigger_capture_area");
		if(IsValidEntity(CP)) 
		{
			AcceptEntityInput(CP, "Enable");
			i = CP;
		} 
		else 
		{
			break;
		}
	} 
}
//timer callback for new game
public void NewGame() 
{
	if(g_iTheCurrentHidden != 0) 
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
	
	if(g_hTick == null)
	{
		g_hTick = CreateTimer(0.1, Timer_Tick, _, TIMER_REPEAT);
	}
}
public void RespawnAll(int client)
{
    Client_RespawnAll(false);
}
//timer callback for resetting the hidden
public Action Timer_ResetHidden(Handle timer) 
{
	ResetHidden();
}
//timer callback for respawn
public Action Timer_Respawn(Handle timer, any data) 
{
	TF2_RespawnPlayer(data);
}
//notify everyone that they can use the help command
public Action NotifyPlayers(Handle timer) 
{
	CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_notify");
}
//jump check
public Action Timer_Jumped(Handle timer, any data)
{
	g_bJumped = false;
}
//force round restart
public Action Timer_Win(Handle timer, any data) 
{
	CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_botkill");

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsPlayerHereLoopCheck(i) && IsFakeClient(i) && IsPlayerAlive(i))
		{
			Client_TakeDamage(i, i, 99999, DMG_CRUSH, "");
		}
	}
}
//ragdol dissolve timer
public void Dissolve(int client) 
{
	if(!IsPlayerHere(client)) 
	{
		return;
	}
	
	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	
	if(ragdoll < 0) 
	{
		return;
	}
	
	char dname[32];
	char dtype[32];
	Format(dname, sizeof(dname), "dis_%d", client);
	Format(dtype, sizeof(dtype), "%d", 3);
	int ent = CreateEntityByName("env_entity_dissolver");
	
	if(IsValidEntity(ent)) 
	{
		DispatchKeyValue(ragdoll, "targetname", dname);
		DispatchKeyValue(ent, "dissolvetype", dtype);
		DispatchKeyValue(ent, "target", dname);
		DispatchKeyValue(ent, "magnitude", "10");
		AcceptEntityInput(ent, "Dissolve", ragdoll, ragdoll);
		AcceptEntityInput(ent, "Kill");
	}
}
//hud timer
public Action Timer_Tick(Handle timer) 
{
	if(g_bTimerDieTick == true)
	{
		return Plugin_Stop;
	}
	
	ShowHiddenHP();
	return Plugin_Continue;
}
//force next hidden command
public Action Cmd_NextHidden(int client, int args) 
{
	if(!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}
	
	if(args != 1) 
	{
		CReplyToCommand(client, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_command");
		return Plugin_Handled;
	}
	
	char tmp[128];
	GetCmdArg(1, tmp, sizeof(tmp));
	int target = FindTarget(client, tmp, false, false);
	
	if(target < 1)
	{
		CReplyToCommand(client, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_command5");
		return Plugin_Handled;
	}
	
	if(GetClientTeam(target) <= 1)
	{
		CReplyToCommand(client, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_command2");
		return Plugin_Handled;	
	}
	
	g_iForceCommandHidden = GetClientUserId(target);
	CReplyToCommand(client, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_command3", target);
	return Plugin_Handled;
}
//cmd for help menu
public Action Cmd_HiddenHelp(int client, int args)
{
	if(!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}
	
	if(IsPlayerHere(client))
	{
		char buffer[256];
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

	return Plugin_Handled;
}
//help menu handler
public int PanelHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	int client = param1;
	char buffer[512];

	if (action == MenuAction_Select && IsPlayerHere(client))
	{
		switch (param2)
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
}

public int PanelHandler2(Menu menu, MenuAction action, int param1, int param2)
{
	int client = param1;
	char buffer[256];
	
	if (action == MenuAction_Select && param2 != 2 && IsPlayerHere(client))
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
}

public int PanelHandler3(Menu menu, MenuAction action, int param1, int param2)
{
	int client = param1;
	char buffer[512];
	
	if (param2 != 2 && IsPlayerHere(client))
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
}

public int PanelHandler4(Menu menu, MenuAction action, int param1, int param2)
{
	int client = param1;
	char buffer[512];
	
	if (param2 != 2 && IsPlayerHere(client))
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
}

//pause the invisibility
void AddHiddenVisible(float value) 
{
	if(g_fHiddenVisible < value) 
	{
		g_fHiddenVisible = value;
	}
}
//is this an arena map?
bool IsArenaMap() 
{
	char curMap[32];
	GetCurrentMap(curMap, sizeof(curMap));
	return strncmp("arena_", curMap, 6, false) == 0;
}
//remove the hidden powers on disconnect
public void OnClientDisconnect(int client) 
{
	g_iDamageToHidden[client] = 0;
	
	if(client == g_iTheCurrentHidden) 
	{
		ResetHidden();
	}
}
//is there enough players? can we play?
bool CanPlay() 
{
	int numClients = Client_Total();
	// Requires 2 or more players, including bots in the server.
	if(numClients >= 2) 
	{
		return true;
	} 
	else 
	{
		return false;
	}
}
//number of players
int Client_Total()
{
	int numClients = 0;
	
	for(int client = 1; client <= MaxClients; client++) {
		
		if(!IsClientConnected(client) || !IsClientInGame(client) || IsClientReplay(client) || IsClientSourceTV(client) || GetClientTeam(client) <= 1 ) 
		{
			continue;
		}
		
		numClients++;
	}
	
	return numClients;
}
//players on blue
int Client_TotalBlue()
{
	int numClients = 0;
	
	for(int client = 1; client <= MaxClients; client++) {
		
		if(!IsClientConnected(client) || !IsClientInGame(client) || IsClientReplay(client) || IsClientSourceTV(client) || GetClientTeam(client) != 3 ) 
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
	int num = Client_Get(clients);

	if(num == 0) 
	{
		return -1;
	}
	else if(num == 1) 
	{
		return clients[0];
	}

	int random = GetRandomUInt(0, num-1);
	return clients[random];
}
//clients count
int Client_Get(int[] clients)
{
	int x = 0;
	
	for(int client = 1; client <= MaxClients; client++) 
	{
		if(IsPlayerHereLoopCheck(client) && GetClientTeam(client) >= 2) 
		{
			clients[x++] = client;
		}
	}

	return x;
}
//how many enemies left?
int GetAliveEnemiesCount() 
{
	int clients = 0;
	
	for( int i = 1; i <= MaxClients; i++ ) 
	{
		if( IsPlayerHereLoopCheck(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && !IsClientSourceTV(i) && !IsClientReplay(i) ) 
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
	
	if(IsPlayerHere(forcedcommand) && GetClientTeam(forcedcommand) > 1 )
	{
		g_iTheCurrentHidden = forcedcommand;
		g_iForceCommandHidden = 0;
		g_iForceNextHidden = 0;
		CPrintToChatAll("{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_command4", forcedcommand);
	}
	else
	{
		int forced = GetClientOfUserId(g_iForceNextHidden);
		
		if(IsPlayerHere(forced) && GetClientTeam(forced) > 1 ) 
		{
			g_iTheCurrentHidden = forced;
			g_iForceNextHidden = 0;
		} 
		else 
		{
			g_iTheCurrentHidden = Client_GetRandom();
			g_iForceNextHidden = 0;
		}
	}
	
	CreateTimer(3.0, NotifyPlayers, _, TIMER_FLAG_NO_MAPCHANGE );
}
//dash/superjump
bool HiddenSuperJump() 
{
	if(g_iTheCurrentHidden == 0 || HiddenStick() != -1 || g_fHiddenStamina < 5.0 || g_bJumped) 
	{
		return;
	}
		
	HiddenUnstick();
	
	float ang[3];
	float vel[3];
	GetClientEyeAngles(g_iTheCurrentHidden, ang);
	GetEntPropVector(g_iTheCurrentHidden, Prop_Data, "m_vecAbsVelocity", vel);
	
	float tmp[3];
	
	GetAngleVectors(ang, tmp, NULL_VECTOR, NULL_VECTOR);
	
	vel[0] += tmp[0]*700.0;
	vel[1] += tmp[1]*700.0;
	vel[2] += tmp[2]*1320.0;
	
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
	if(g_iTheCurrentHidden == 0) 
	{
		return 0;
	}
	
	float pos[3];
	float ang[3];
	
	GetClientEyeAngles(g_iTheCurrentHidden, ang);
	GetClientEyePosition(g_iTheCurrentHidden, pos);
	
	Handle ray = TR_TraceRayFilterEx(pos, ang, MASK_ALL, RayType_Infinite, TraceRay_HitWorld);
	
	if(TR_DidHit(ray)) 
	{
		float pos2[3];
		TR_GetEndPosition(pos2, ray);
		
		if(GetVectorDistance(pos, pos2) < 64.0) 
		{
			if(g_bHiddenSticky) 
			{
				CloseHandle(ray);
				return 0;
			}
			
			g_bHiddenSticky=true;
			
			if(GetEntityMoveType(g_iTheCurrentHidden)!=MOVETYPE_NONE) 
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
	
	if(GetEntityMoveType(g_iTheCurrentHidden) == MOVETYPE_NONE) 
	{
		SetEntityMoveType(g_iTheCurrentHidden, MOVETYPE_WALK);
		float vel[3] = 0.0;
		TeleportEntity(g_iTheCurrentHidden, NULL_VECTOR, NULL_VECTOR, vel);
	}
}
//give vision
void GiveHiddenVision(int i) 
{
	OverlayCommand(i, "effects/combine_binocoverlay");
}
//remove it
void RemoveHiddenVision(int i) 
{
	OverlayCommand(i, "\"\"");
}
//hud stuff
void ShowHiddenHP() 
{
	if(g_iTheCurrentHidden == 0)
	{
		return;
	}
	
	int perc = RoundToCeil(float(g_iHiddenCurrentHp)/float(g_iHiddenHpMax)*100.0);
	int ponc = RoundToCeil(g_fHiddenStamina/g_fCV_hidden_stamina*100.0);
	int cbomb = RoundToCeil(100.0-g_fHiddenBomb/g_fCV_hidden_bombtime*100.0);
	float starv = g_fHiddenInvisibility/g_fCV_hidden_starvationtime*100.0; 
	int hung = RoundToCeil(100.0-starv);
	
	if(perc <= 0.0)
	{
		return;
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsPlayerHereLoopCheck(i) && !IsFakeClient(i) && GetClientTeam(i) > 0)
		{
			if(i != g_iTheCurrentHidden)
			{
				if(perc > 25.0) 
				{
					SetHudTextParams(-1.0, 0.1, 0.23, 50, 255, 50, 255, 1, 0.0, 0.0, 0.0);
				} 
				else 
				{
					SetHudTextParams(-1.0, 0.1, 0.23, 255, 50, 50, 255, 1, 0.0, 0.0, 0.0);
				}
				
				ShowSyncHudText(i, g_hHiddenHudHp, "%t: %.0i%%", "hidden_hud", perc);
			}
			else
			{
				if(perc > 25.0) 
				{
					SetHudTextParams(-1.0, 0.1, 0.23, 40, 255, 40, 255, 1, 0.0, 0.0, 0.0);
				} 
				else 
				{
					SetHudTextParams(-1.0, 0.1, 0.23, 255, 50, 50, 255, 1, 0.0, 0.0, 0.0);
				}
				
				ShowSyncHudText(g_iTheCurrentHidden, g_hHiddenHudHp, "%t: %.0i%%", "hidden_hud2", perc);
			
				SetHudTextParams(-1.0, 0.125, 0.23, 10, 255, 128, 255, 1, 0.0, 0.0, 0.0);
				ShowSyncHudText(g_iTheCurrentHidden, g_hHiddenHudStamina, "%t: %.0i%%", "hidden_hud3", ponc);
				
				SetHudTextParams(-1.0, 0.150, 0.23, 70, 70, 255, 255, 1, 0.0, 0.0, 0.0);
				ShowSyncHudText(g_iTheCurrentHidden, g_hHiddenHudClusterBomb, "%t: %.0i%%", "hidden_hud4", cbomb);
				
				SetHudTextParams(-1.0, 0.175, 0.23, 144, 40, 255, 255, 1, 0.0, 0.0, 0.0);
				ShowSyncHudText(g_iTheCurrentHidden, g_hHiddenHudHunger, "%t: %.0i%%", "hidden_hud5", hung);
			}
		}
	} 
}
//give hidden powers
void GiveHiddenPowers(int i) 
{
	if(!i) 
	{
		return;
	}
	
	TF2_RemoveWeaponSlot(i, 0); // Revolver
	//TF2_RemoveWeaponSlot(i, 1); // Sapper	
	TF2_RemoveWeaponSlot(i, 2); // Knife
	
	if(!IsFakeClient(i))
	{
		Client_SetHideHud(i, ( 1<<3 ));
		GiveHiddenVision(i);
		TF2_RemoveWeaponSlot(i, 3); // Disguise Kit
	}

	TF2_RemoveWeaponSlot(i, 4); // Invisibility Watch
	CreateNamedItem(i, 4, "tf_weapon_knife", 1, 0);
	//CreateNamedItem(i, 1080, "tf_weapon_sapper", 99, 5);
}
//remove hidden's powers
void RemoveHiddenPowers(int i) 
{
	RemoveHiddenVision(i);
	TF2_RemoveCondition(i, TFCond_Cloaked);
	SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", 320.0);
	Client_SetHideHud(i, 0);
}
//hide hidden's hud
void Client_SetHideHud(int client, int flags)
{
	SetEntProp(client, Prop_Send, "m_iHideHUD", flags);
}
//reset the hidden
void ResetHidden() 
{
	if(IsPlayerHere(g_iTheCurrentHidden)) 
	{
		RemoveHiddenPowers(g_iTheCurrentHidden);
	}
	
	g_iTheCurrentHidden = 0;
}
//set the overlay
void OverlayCommand(int client, char[] overlay) 
{    
	if(IsPlayerHere(client)) 
	{
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT));
		ClientCommand(client, "r_screenoverlay %s", overlay);
	}
}
//respawn everyone according to the plan
void Client_RespawnAll(bool Notify) 
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsPlayerHereLoopCheck(i))
		{
			switch (GetClientTeam(i))
			{
				case 0,1:
				{
					continue;
				}
				case 2:
				{
					if(i == g_iTheCurrentHidden)
					{
						SetEntProp(i, Prop_Send, "m_lifeState", 2);
						ChangeClientTeam(i, 3);
						TF2_SetPlayerClass(i, TFClass_Spy);
						CreateTimer(0.1, Timer_Respawn, i, TIMER_FLAG_NO_MAPCHANGE);
						if(Notify)
						{
							CPrintToChat(i, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_team");
						}
					}
				}
				case 3:
				{
					if(i != g_iTheCurrentHidden)
					{
						SetEntProp(i, Prop_Send, "m_lifeState", 2);
						ChangeClientTeam(i, 2);
						
						if(IsFakeClient(i) && g_bCV_hidden_forcebotsclass)
						{
							TF2_SetPlayerClass(i, TFClass_Sniper);
						}
						else
						{
							TF2_SetPlayerClass(i, view_as<TFClassType>(PickAClass()));
						}
						
						CreateTimer(0.1, Timer_Respawn, i, TIMER_FLAG_NO_MAPCHANGE);
						if(Notify)
						{
							CPrintToChat(i, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_team");
						}
					}
				}
			}
		}
	}
}
//shoot the bomb if ready
bool HiddenBombTrigger() 
{
	if(g_iTheCurrentHidden == 0 || g_fHiddenBomb > 0.0) 
	{
		return false;
	}

	Command_ClusterBomb(g_iTheCurrentHidden);	
	AddHiddenVisible(g_fCV_hidden_visible_bomb);
	return true;
}
//enable or disable the plugin - cvar changed
public void cvhook_enabled(Handle cvar, const char[] oldVal, const char[] newVal) 
{
	if(GetConVarBool(g_hCV_hidden_enabled) && IsArenaMap()) 
	{
		ActivatePlugin();
	} 
	else 
	{
		DeactivatePlugin();
	}
}
//cbomb and bomblets
public Action Command_ClusterBomb(int client)
{
	if(IsPlayerHere(client) && IsPlayerAlive(client))
	{
		if(GetMaxEntities() - GetEntityCount() < 200)
		{
			CPrintToChat(client, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_problem");
			g_fHiddenBomb = 1.0;
			return Plugin_Handled;
		}
		
		float pos[3];
		float ePos[3];
		float angs[3];
		float vecs[3];			
		GetClientEyePosition(client, pos);
		GetClientEyeAngles(client, angs);
		GetAngleVectors(angs, vecs, NULL_VECTOR, NULL_VECTOR);
		Handle trace = TR_TraceRayFilterEx(pos, angs, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

		if(TR_DidHit(trace))
		{
			TR_GetEndPosition(ePos, trace);
			if(GetVectorDistance(ePos, pos, false) < 45.0)
			{
				CPrintToChat(client, "{mediumseagreen}[%s] %t", PLUGIN_NAME, "hidden_problem2");
				g_fHiddenBomb = 1.0;
				return Plugin_Handled;
			}
		}
		
		CloseHandle(trace);			
		pos[0] += vecs[0] * 32.0;
		pos[1] += vecs[1] * 32.0;
		ScaleVector(vecs, GetConVarFloat(g_hCV_hidden_bombthrowspeed));
		int ent = CreateEntityByName("prop_physics_override");
		
		if(IsValidEntity(ent))
		{					
			DispatchKeyValue(ent, "model", g_sCanisterModel);						
			SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
			SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
			DispatchKeyValue(ent, "nodamageforces", "1");
			DispatchKeyValue(ent, "spawnflags", "512");
			SetEntProp(ent, Prop_Send, "m_iTeamNum", 3);
			SetEntProp(ent, Prop_Send, "m_nSkin", 1);
			DispatchSpawn(ent);
			TeleportEntity(ent, pos, NULL_VECTOR, vecs);
			g_fHiddenBomb = g_fCV_hidden_bombtime;
			CreateTimer(GetConVarFloat(g_hCV_hidden_bombdetonationdelay), SpawnClusters, ent, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	return Plugin_Handled;
}
public Action SpawnClusters(Handle timer, any ent)
{
	if(IsValidEntity(ent))
	{
		float pos[3];
		GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
		EmitAmbientSound(g_sDetonationSound, pos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, 0.0);
		int client = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		AcceptEntityInput(ent, "Kill");
		float ang[3];
		
		for(int i = 0; i < GetConVarInt(g_hCV_hidden_bombletcount); i++)
		{
			float fsv = GetConVarFloat(g_hCV_hidden_bombletspreadvel);
			ang[0] = ((GetURandomFloat() + 0.1) * fsv) * ((GetURandomFloat() + 0.1) * 0.8);
			ang[1] = ((GetURandomFloat() + 0.1) * fsv) * ((GetURandomFloat() + 0.1) * 0.8);
			ang[2] = ((GetURandomFloat() + 0.1) * fsv) * ((GetURandomFloat() + 0.1) * 0.8);
			
			int ent2 = CreateEntityByName("prop_physics_override");
			
			if(IsValidEntity(ent2))
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
}
public Action ExplodeBomblet(Handle timer, any ent)
{
	if(IsValidEntity(ent))
	{
		float pos[3];
		GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
		pos[2] += 4.0;
		int client = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		int team = GetEntProp(client, Prop_Send, "m_iTeamNum");
		AcceptEntityInput(ent, "Kill");
		int explosion = CreateEntityByName("env_explosion");
		
		if(IsValidEntity(explosion))
		{
			int physexplosion = CreateEntityByName("point_push");
			int tMag = GetConVarInt(g_hCV_hidden_bombletmagnitude);

			if(IsValidEntity(physexplosion))
			{
				SetEntPropFloat(physexplosion, Prop_Data, "m_flMagnitude", tMag*24.0);
				SetEntPropFloat(physexplosion, Prop_Data, "m_flRadius", tMag*12.0);
				SetEntProp(physexplosion, Prop_Data, "m_bEnabled", 0);
				DispatchKeyValue(physexplosion, "spawnflags", "24");
				SetEntProp(physexplosion, Prop_Send, "m_iTeamNum", team);
				SetEntPropEnt(physexplosion, Prop_Send, "m_hOwnerEntity", explosion);
				DispatchSpawn(physexplosion);
				ActivateEntity(physexplosion);
				
				TeleportEntity(physexplosion, pos, NULL_VECTOR, NULL_VECTOR);				
			}

			SetEntProp(explosion, Prop_Data, "m_iMagnitude", tMag);
			SetEntProp(explosion, Prop_Send, "m_iTeamNum", team);
			SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", client);
			if(GetConVarBool(g_hCV_hidden_bombignoreuser))
			{
				SetEntPropEnt(explosion, Prop_Data, "m_hEntityIgnore", client);
			}
			
			DispatchSpawn(explosion);
			ActivateEntity(explosion);
			
			TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);				
			AcceptEntityInput(explosion, "Explode");
			AcceptEntityInput(physexplosion, "Enable");
			AcceptEntityInput(explosion, "Kill");

			CreateTimer(0.4, StopPush, physexplosion, TIMER_FLAG_NO_MAPCHANGE);
		}		
	}
}

public Action StopPush(Handle timer, any ent)
{
	if(IsValidEntity(ent))
	{
		AcceptEntityInput(ent, "Kill");
	}
}

bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	if(contentsMask == -15)
	{
		LogToGame("WutFace");		
	}
	
	return entity > MaxClients || !entity;
}

bool TraceRay_HitWorld(int entity, int contentsMask) 
{
	if(contentsMask == -15)
	{
		LogToGame("WutFace");		
	}
	
	return entity == 0;
}
//creating a weapon
bool CreateNamedItem(int client, int itemindex, char[] classname, int level, int quality)
{
	int weapon = CreateEntityByName(classname);
	
	if(!IsValidEntity(weapon))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));	
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);	
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);	
	
	if(StrEqual(classname, "tf_weapon_builder", true) || StrEqual(classname, "tf_weapon_sapper", true))
	{
		SetEntProp( weapon, Prop_Send, "m_iObjectType", 3 );
	}
	
	DispatchSpawn(weapon);
	SDKCall(g_hWeaponEquip, client, weapon);
	return true;
} 
//a check used for non-loops
bool IsPlayerHere(int client)
{
	return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}
//a check used for loops
bool IsPlayerHereLoopCheck(int client)
{
	return (IsClientConnected(client) && IsClientInGame(client));
}
//changing the game in server browser
#if defined _steamtools_included
void SetGameDescription() 
{
	char gameDesc[64];
	
	if(GetConVarBool(g_hCV_hidden_enabled)) 
	{
		Format(gameDesc, sizeof(gameDesc), "The Hidden Mod Redux");
	} 
	else 
	{
		gameDesc = "Team Fortress";
	}
	
	Steam_SetGameDescription(gameDesc);
}
#endif
//a better way to kill players
void Client_TakeDamage(int victim, int attacker, int damage, int dmg_type = DMG_GENERIC, const char[] weapon) 
{ 
  if(IsPlayerHere(victim)) 
  { 
    char sDamage[16]; 
    char sDamageType[32]; 
    IntToString(damage, sDamage, sizeof(sDamage)); 
    IntToString(dmg_type, sDamageType, sizeof(sDamageType)); 
    int index = CreateEntityByName("point_hurt");

    if(IsValidEntity(index)) 
    { 
      DispatchKeyValue(victim,"targetname","cod_hurtme"); 
      DispatchKeyValue(index,"DamageTarget","cod_hurtme"); 
      DispatchKeyValue(index,"Damage", sDamage); 
      DispatchKeyValue(index,"DamageType",sDamageType); 
      DispatchKeyValue(index,"classname",weapon); 
      DispatchSpawn(index); 
      AcceptEntityInput(index,"Hurt", attacker); 
      DispatchKeyValue(index,"classname","point_hurt"); 
      DispatchKeyValue(victim,"targetname","cod_donthurtme"); 
      RemoveEdict(index); 
    } 
  } 
}
int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1) + min);
}
//pick a class
int PickAClass()
{
	int cl = GetRandomUInt(1,8);
	
	if(cl == 8)
	{
		cl = 9;
	}
	
	return cl;	
}