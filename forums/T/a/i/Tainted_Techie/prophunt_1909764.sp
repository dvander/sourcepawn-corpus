//  PropHunt by Darkimmortal
//   - GamingMasters.org -

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>




#define PL_VERSION "1.93"
//--------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------- MAIN PROPHUNT CONFIGURATION -------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------

// Enable for global stats support (.inc file available on request due to potential for cheating and database abuse)
// Default: OFF
//#define STATS

#if defined STATS
#define SELECTOR_PORTS "27019"
#include <selector>
#endif

// Give last prop a scattergun and apply jarate to all pyros on last prop alive
// Default: ON
#define SCATTERGUN

// Prop Lock/Unlock sounds
// Default: ON
#define LOCKSOUND

// Extra classes
// Default: ON
#define SHINX

// Event and query logging for debugging purposes
// Default: OFF
//#define LOG

// Allow props to Targe Charge with enemy collisions disabled by pressing reload - pretty shit tbh.
// Default: OFF
//#define CHARGE

// Max ammo in Pyro shotgun
// Default: 2
#define SHOTGUN_MAX_AMMO 2

// Airblast permitted
// Default: NO
//#define AIRBLAST

// Anti-exploit system
// Default: ON
#define ANTIHACK

//--------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------

#define TEAM_BLUE 3
#define TEAM_RED 2
#define TEAM_SPEC 1
#define TEAM_UNASSIGNED 0

#define FLAMETHROWER "models/weapons/w_models/w_flamethrower.mdl"

#define STATE_WAT -1
#define STATE_IDLE 0
#define STATE_RUNNING 1
#define STATE_SWING 2
#define STATE_CROUCH 3

#define PLAYER_ONFIRE (1 << 14)

// Weapon Indexes
#define WEP_SHOTGUN_UNIQUE 199

//Pyro
#define WEP_SHOTGUNPYRO 12

#define LOCKVOL 0.7
#define UNBALANCE_LIMIT 1
#define MAXMODELNAME 96
#define TF2_PLAYERCOND_ONFIREALERT    (1<<20)
#define MAXITEMS 1024

#define IN_MOVEMENT IN_MOVELEFT | IN_MOVERIGHT | IN_FORWARD | IN_BACK | IN_JUMP

enum ScReason
{
	ScReason_TeamWin = 0,
	ScReason_TeamLose,
	ScReason_Death,
	ScReason_Kill,
	ScReason_Time,
	ScReason_Friendly
};

new bool:g_RoundOver = true;
new bool:g_inPreRound = true;

new bool:g_LastProp;
new bool:g_Attacking[MAXPLAYERS+1];
new bool:g_SetClass[MAXPLAYERS+1];
new bool:g_Spawned[MAXPLAYERS+1];
new bool:g_TouchingCP[MAXPLAYERS+1];
new bool:g_Charge[MAXPLAYERS+1];
new bool:g_First[MAXPLAYERS+1];
new bool:g_HoldingLMB[MAXPLAYERS+1];
new bool:g_HoldingRMB[MAXPLAYERS+1];
new bool:g_AllowedSpawn[MAXPLAYERS+1];
new bool:g_RotLocked[MAXPLAYERS+1];
new bool:g_Hit[MAXPLAYERS+1];
new bool:g_Spec[MAXPLAYERS+1];
new String:g_PlayerModel[MAXPLAYERS+1][MAXMODELNAME];

new String:g_Mapname[128];
new String:g_ServerIP[32];
new String:g_Version[8];

#if defined CHARGE
new g_offsCollisionGroup;
#endif

new g_Message_red;
new g_Message_blue;
new g_RoundTime = 175;
new g_Message_bit = 0;
new g_iVelocity = -1;

#if defined STATS
new bool:g_MapChanging = false;
new g_StartTime;
#endif

new Handle:g_TimerStart = INVALID_HANDLE;
new Handle:g_CountdownSoundTimers[8] = INVALID_HANDLE;
new const String:g_CountdownSounds[][] = { "Countdown30", "Countdown20", "Countdown10", "Countdown5", "Countdown4", "Countdown3", "Countdown2", "Countdown1" };
new	Handle:g_Sounds = INVALID_HANDLE;

new bool:g_Doors = false;
new bool:g_Relay = false;
new bool:g_Freeze = true;

new bool:g_weaponRemovals[MAXITEMS];
new Float:g_weaponNerfs[MAXITEMS];
new Float:g_weaponSelfDamage[MAXITEMS];

new g_classLimits[2][10];
new TFClassType:g_defaultClass[2];
new Float:g_classSpeeds[10][3]; //0 - Base speed, 1 - Max Speed, 2 - Increment Value
new Float:g_currentSpeed[MAXPLAYERS+1];

//new g_oFOV;
//new g_oDefFOV;

new Handle:g_PropNames = INVALID_HANDLE;
new Handle:g_ConfigKeyValues = INVALID_HANDLE;
new Handle:g_ModelName = INVALID_HANDLE;
new Handle:g_ModelOffset = INVALID_HANDLE;
new Handle:g_Text1 = INVALID_HANDLE;
new Handle:g_Text2 = INVALID_HANDLE;
new Handle:g_Text3 = INVALID_HANDLE;
new Handle:g_Text4 = INVALID_HANDLE;

new Handle:g_RoundTimer = INVALID_HANDLE;
new Handle:g_PropMenu = INVALID_HANDLE;

new Handle:g_PHEnable = INVALID_HANDLE;
new Handle:g_PHPropMenu = INVALID_HANDLE;
new Handle:g_PHAdmFlag = INVALID_HANDLE;
new Handle:g_PHAdvertisements = INVALID_HANDLE;

new String:g_AdText[128] = "GamingMasters.org";

public Plugin:myinfo =
{
	name = "PropHunt",
	author = "Darkimmortal",
	description = "GamingMasters.org",
	version = PL_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=107104"
}

enum
{
	COLLISION_GROUP_NONE  = 0,
	COLLISION_GROUP_DEBRIS,       // Collides with nothing but world and static stuff
	COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
	COLLISION_GROUP_INTERACTIVE_DEB, // Collides with everything except other interactive debris or debris
	COLLISION_GROUP_INTERACTIVE,  // Collides with everything except interactive debris or debris
	COLLISION_GROUP_PLAYER,
	COLLISION_GROUP_BREAKABLE_GLASS,
	COLLISION_GROUP_VEHICLE,
	COLLISION_GROUP_PLAYER_MOVEMENT, // For HL2, same as Collision_Group_Player
	COLLISION_GROUP_NPC,          // Generic NPC group
	COLLISION_GROUP_IN_VEHICLE,   // for any entity inside a vehicle
	COLLISION_GROUP_WEAPON,       // for any weapons that need collision detection
	COLLISION_GROUP_VEHICLE_CLIP, // vehicle clip brush to restrict vehicle movement
	COLLISION_GROUP_PROJECTILE,   // Projectiles!
	COLLISION_GROUP_DOOR_BLOCKER, // Blocks entities not permitted to get near moving doors
	COLLISION_GROUP_PASSABLE_DOOR, // Doors that the player shouldn't collide with
	COLLISION_GROUP_DISSOLVING,   // Things that are dissolving are in this group
	COLLISION_GROUP_PUSHAWAY,     // Nonsolid on client and server, pushaway in player code
	COLLISION_GROUP_NPC_ACTOR,        // Used so NPCs in scripts ignore the player.
}

#if defined STATS

#include "prophunt\stats2.inc"
/*
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:hostname[255], String:ip[32], String:port[8]; //, String:map[92];
	GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));
	GetConVarString(FindConVar("ip"), ip, sizeof(ip));
	GetConVarString(FindConVar("hostport"), port, sizeof(port));

	if(StrContains(hostname, "GamingMasters.co.uk", false) != -1)
	{
		if(StrContains(hostname, "PropHunt", false) == -1 && StrContains(hostname, "Arena", false) == -1 && StrContains(hostname, "Dark", false) == -1 &&
				StrContains(ip, "8.9.4.169", false) == -1)
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}
*/
#endif

public OnPluginStart()
{
	if (!IsPropHuntMap()){
		Unload();
		return;
	}

	decl String:hostname[255], String:ip[32], String:port[8]; //, String:map[92];
	GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));
	GetConVarString(FindConVar("ip"), ip, sizeof(ip));
	GetConVarString(FindConVar("hostport"), port, sizeof(port));

	Format(g_ServerIP, sizeof(g_ServerIP), "%s:%s", ip, port);


	if(GetExtensionFileStatus("sdkhooks.ext") < 1)
	SetFailState("SDK Hooks is not loaded.");

	new bool:statsbool = false;
#if defined STATS
	statsbool = true;
#endif

	Format(g_Version, sizeof(g_Version), "%s%s", PL_VERSION, statsbool ? "s":"");
	CreateConVar("sm_prophunt_version", g_Version, "PropHunt Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_PHAdmFlag = CreateConVar("ph_propmenu_flag", "c", "Flag to use for the PropMenu");
	g_PHEnable = CreateConVar("ph_enable", "1", "Enables the plugin");
	g_PHPropMenu = CreateConVar("ph_propmenu", "0", "Control use of the propmenu command: -1 = Disabled, 0 = admin only, 1 = all players, 2 = Donors only");
	g_PHAdvertisements = CreateConVar("ph_adtext", g_AdText, "Controls the text used for Advertisements");

	HookConVarChange(g_PHEnable, OnConVarChanged);
	HookConVarChange(g_PHAdvertisements, OnConVarChanged);

	g_Text1 = CreateHudSynchronizer();
	g_Text2 = CreateHudSynchronizer();
	g_Text3 = CreateHudSynchronizer();
	g_Text4 = CreateHudSynchronizer();

	AddServerTag("PropHunt");


	HookEvent("player_spawn", Event_player_spawn);
	HookEvent("player_team", Event_player_team);
	HookEvent("player_death", Event_player_death, EventHookMode_Pre);
	HookEvent("arena_round_start", Event_arena_round_start, EventHookMode_Post);
	HookEvent("arena_win_panel", Event_arena_win_panel);
	HookEvent("post_inventory_application", CallCheckInventory, EventHookMode_Post);

#if defined STATS
	Stats_Init();
#endif

	RegConsoleCmd("help", Command_motd);
	RegConsoleCmd("motd", Command_motd);
	RegConsoleCmd("propmenu", Command_propmenu);

	AddFileToDownloadsTable("sound/prophunt/found.mp3");
	AddFileToDownloadsTable("sound/prophunt/snaaake.mp3");
	AddFileToDownloadsTable("sound/prophunt/oneandonly.mp3");
	
#if defined CHARGE
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
#endif
	LoadTranslations("prophunt.phrases");
 
	//g_oFOV = FindSendPropOffs("CBasePlayer", "m_iFOV");
	//g_oDefFOV = FindSendPropOffs("CBasePlayer", "m_iDefaultFOV");
	
	g_Sounds = CreateTrie();
	
	loadGlobalConfig();
	

	RegAdminCmd("ph_respawn", Command_respawn, ADMFLAG_ROOT, "Respawns you");
	RegAdminCmd("ph_switch", Command_switch, ADMFLAG_BAN, "Switches to RED");
	RegAdminCmd("ph_internet", Command_internet, ADMFLAG_BAN, "Spams Internet");
	RegAdminCmd("ph_pyro", Command_pyro, ADMFLAG_BAN, "Switches to BLU");
	RegAdminCmd("ph_reloadconfig", Command_ReloadConfig, ADMFLAG_BAN, "Reloads the PropHunt configuration");

	if((g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]")) == -1)
	LogError("Could not find offset for CBasePlayer::m_vecVelocity[0]");

	CreateTimer(7.0, Timer_AntiHack, 0, TIMER_REPEAT);
	CreateTimer(0.6, Timer_Locked, 0, TIMER_REPEAT);
	CreateTimer(55.0, Timer_Score, 0, TIMER_REPEAT);


	for(new client=1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			ForcePlayerSuicide(client);
#if defined STATS
			OnClientPostAdminCheck(client);
#endif
		}
	}
	decl String:Path[256];
	BuildPath(Path_SM, Path, sizeof(Path), "data/prophunt/prop_names.txt");
	g_PropNames = CreateKeyValues("g_PropNames");
	if (!FileToKeyValues(g_PropNames, Path))
	LogError("Could not load the g_PropNames file!");
	
	SetCVars();
}

loadGlobalConfig()
{
	decl String:Path[256];
	BuildPath(Path_SM, Path, sizeof(Path), "data/prophunt/prophunt_config.cfg");
	g_ConfigKeyValues = CreateKeyValues("prophunt_config");
	if (!FileToKeyValues(g_ConfigKeyValues, Path))
	{
		LogError("Could not load the PropHunt config file!");
	}
	
	
	config_parseWeapons();
	config_parseClasses();
	config_parseSounds();
}

config_parseWeapons()
{
	for(new i = 0; i < MAXITEMS; i++)
	{
		g_weaponNerfs[i] = 1.0;
		g_weaponSelfDamage[i] = 10.0;
		g_weaponRemovals[i] = false;
	}
	
	if (g_ConfigKeyValues == INVALID_HANDLE)
	{
		return;
	}
	
	while(KvGoBack(g_ConfigKeyValues))
	{
		continue;
	}
	
	if(KvJumpToKey(g_ConfigKeyValues, "items"))
	{
		do
		{
			decl String:SectionName[128];
			KvGotoFirstSubKey(g_ConfigKeyValues);
			KvGetSectionName(g_ConfigKeyValues, SectionName, sizeof(SectionName));
			if(KvGetDataType(g_ConfigKeyValues, "damage_hunters") == KvData_Float)
			{
				g_weaponNerfs[StringToInt(SectionName)] = KvGetFloat(g_ConfigKeyValues, "damage_hunters");
			}
			if(KvGetDataType(g_ConfigKeyValues, "removed_hunters") == KvData_Int)
			{
				g_weaponRemovals[StringToInt(SectionName)] = bool:KvGetNum(g_ConfigKeyValues, "removed_hunters");
			}
			if(KvGetDataType(g_ConfigKeyValues, "self_damage_hunters") == KvData_Float)
			{
				g_weaponSelfDamage[StringToInt(SectionName)] = KvGetFloat(g_ConfigKeyValues, "self_damage_hunters");
			}
		}
		while(KvGotoNextKey(g_ConfigKeyValues));
	}
	else
	{
		LogMessage("[PH] Invalid config! Could not access subkey: items");
	}
}

config_parseClasses()
{
	g_defaultClass[TEAM_RED-2] = TFClass_Scout;
	g_defaultClass[TEAM_BLUE-2] = TFClass_Pyro;
	
	for(new i = 0; i < 10; i++)
	{
		g_classLimits[TEAM_BLUE-2][i] = -1;
		g_classLimits[TEAM_RED-2][i] = -1;
		g_classSpeeds[i][0] = 300.0;
		g_classSpeeds[i][1] = 400.0;
		g_classSpeeds[i][2] = 15.0;
	}
	
	if (g_ConfigKeyValues == INVALID_HANDLE)
	{
		return;
	}
	
	while(KvGoBack(g_ConfigKeyValues))
	{
		continue;
	}
	
	if(KvJumpToKey(g_ConfigKeyValues, "classes"))
	{
		do
		{
			decl String:SectionName[128];
			KvGotoFirstSubKey(g_ConfigKeyValues);
			KvGetSectionName(g_ConfigKeyValues, SectionName, sizeof(SectionName));
			if(KvGetDataType(g_ConfigKeyValues, "hunter_limit") == KvData_Int)
			{
				g_classLimits[TEAM_BLUE-2][StringToInt(SectionName)] = KvGetNum(g_ConfigKeyValues, "hunter_limit");
			}
			if(KvGetDataType(g_ConfigKeyValues, "prop_limit") == KvData_Int)
			{
				g_classLimits[TEAM_RED-2][StringToInt(SectionName)] = KvGetNum(g_ConfigKeyValues, "prop_limit");
			}
			if(KvGetDataType(g_ConfigKeyValues, "hunter_default_class") == KvData_Int)
			{
				g_defaultClass[TEAM_BLUE-2] = TFClassType:StringToInt(SectionName);
			}
			if(KvGetDataType(g_ConfigKeyValues, "prop_default_class") == KvData_Int)
			{
				g_defaultClass[TEAM_RED-2] = TFClassType:StringToInt(SectionName);
			}
			if(KvGetDataType(g_ConfigKeyValues, "base_speed") == KvData_Float)
			{
				g_classSpeeds[StringToInt(SectionName)][0] = KvGetFloat(g_ConfigKeyValues, "base_speed");
			}
			if(KvGetDataType(g_ConfigKeyValues, "max_speed") == KvData_Float)
			{
				g_classSpeeds[StringToInt(SectionName)][1] = KvGetFloat(g_ConfigKeyValues, "max_speed");
			}
			if(KvGetDataType(g_ConfigKeyValues, "speed_increment") == KvData_Float)
			{
				g_classSpeeds[StringToInt(SectionName)][2] = KvGetFloat(g_ConfigKeyValues, "speed_increment");
			}
			
		}
		while(KvGotoNextKey(g_ConfigKeyValues));
	}
	else
	{
		LogMessage("[PH] Invalid config! Could not access subkey: classes");
	}
}

config_parseSounds()
{
	ClearTrie(g_Sounds);
	
	if (g_ConfigKeyValues == INVALID_HANDLE)
	{
		return;
	}
	
	while(KvGoBack(g_ConfigKeyValues))
	{
		continue;
	}
	
	if(KvJumpToKey(g_ConfigKeyValues, "sounds"))
	{
		do
		{
			decl String:SectionName[128];
			KvGotoFirstSubKey(g_ConfigKeyValues);
			KvGetSectionName(g_ConfigKeyValues, SectionName, sizeof(SectionName));
			if(KvGetDataType(g_ConfigKeyValues, "sound") == KvData_String)
			{
				decl String:soundString[128];
				KvGetString(g_ConfigKeyValues, "sound", soundString, sizeof(soundString));
				
				if(PrecacheSound(soundString))
				{
					SetTrieString(g_Sounds, SectionName, soundString, true);
				}
			}
		}
		while(KvGotoNextKey(g_ConfigKeyValues));
	}
	else
	{
		LogMessage("[PH] Invalid config! Could not access subkey: sounds");
	}
}

SetCVars(){

	new Handle:cvar = INVALID_HANDLE;
	cvar = FindConVar("tf_arena_round_time");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	cvar = FindConVar("tf_arena_use_queue");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	cvar = FindConVar("tf_arena_max_streak");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	cvar = FindConVar("mp_tournament");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	cvar = FindConVar("mp_tournament_stopwatch");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	cvar = FindConVar("tf_tournament_hide_domination_icons");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	cvar = FindConVar("mp_teams_unbalance_limit");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	cvar = FindConVar("tf_arena_preround_time");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	cvar = FindConVar("mp_autoteambalance");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	cvar = FindConVar("mp_autoteambalance");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));

	SetConVarInt(FindConVar("tf_weapon_criticals"), 1, true);
	SetConVarInt(FindConVar("mp_idlemaxtime"), 0, true);
	SetConVarInt(FindConVar("mp_tournament_stopwatch"), 0, true);
	SetConVarInt(FindConVar("mp_idledealmethod"), 0, true);
	SetConVarInt(FindConVar("tf_tournament_hide_domination_icons"), 0, true);
	SetConVarInt(FindConVar("mp_maxrounds"), 0, true);
	SetConVarInt(FindConVar("sv_alltalk"), 1, true);
	SetConVarInt(FindConVar("mp_friendlyfire"), 0, true);
	SetConVarInt(FindConVar("sv_gravity"), 500, true);
	SetConVarInt(FindConVar("mp_forcecamera"), 1, true);
	SetConVarInt(FindConVar("tf_arena_override_cap_enable_time"), 1, true);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), UNBALANCE_LIMIT, true);
	SetConVarInt(FindConVar("mp_autoteambalance"), 0, true);
	SetConVarInt(FindConVar("tf_arena_max_streak"), 5, true);
	SetConVarInt(FindConVar("mp_enableroundwaittime"), 0, true);
	SetConVarInt(FindConVar("mp_stalemate_timelimit"), 5, true);
	SetConVarInt(FindConVar("tf_weapon_criticals"), 1, true);
	SetConVarInt(FindConVar("mp_waitingforplayers_time"), 40, true);
	SetConVarInt(FindConVar("tf_arena_use_queue"), 0, true);
	SetConVarInt(FindConVar("mp_stalemate_enable"), 1, true);
	SetConVarInt(FindConVar("mp_show_voice_icons"), 0, true);
	SetConVarInt(FindConVar("mp_bonusroundtime"), 5, true);
	SetConVarInt(FindConVar("tf_solidobjects"), 0, true);
	
	SetConVarBounds(FindConVar("tf_arena_preround_time"), ConVarBound_Upper, false);
	SetConVarInt(FindConVar("tf_arena_preround_time"), IsDedicatedServer() ? 20:5, true);
#if !defined AIRBLAST
	SetConVarInt(FindConVar("tf_flamethrower_burstammo"), 201, true);
#endif
	
	cvar = FindConVar("mp_idledealmethod");
	if(GetConVarInt(cvar) == 1)
	{
		SetConVarInt(cvar, 2, true);
	}
	
	if(GetExtensionFileStatus("runteamlogic.ext") == 1)
	{
		cvar = FindConVar("rtl_arenateamsize");
		SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
		SetConVarInt(FindConVar("rtl_arenateamsize"), 16);
	}
}

ResetCVars()
{

	new Handle:cvar = INVALID_HANDLE;
	cvar = FindConVar("tf_arena_round_time");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	cvar = FindConVar("tf_arena_use_queue");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	cvar = FindConVar("tf_arena_max_streak");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	cvar = FindConVar("mp_teams_unbalance_limit");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	cvar = FindConVar("tf_arena_preround_time");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	cvar = FindConVar("mp_autoteambalance");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));

	SetConVarInt(FindConVar("mp_idlemaxtime"), 3, true);
	SetConVarInt(FindConVar("mp_maxrounds"), 0, true);
	SetConVarInt(FindConVar("sv_alltalk"), 0, true);
	SetConVarInt(FindConVar("sv_gravity"), 800, true);
	SetConVarInt(FindConVar("mp_forcecamera"), 0, true);
	SetConVarInt(FindConVar("tf_arena_override_cap_enable_time"), 0, true);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 1, true);
	SetConVarInt(FindConVar("mp_autoteambalance"), 1, true);
	SetConVarInt(FindConVar("tf_arena_max_streak"), 5, true);
	SetConVarInt(FindConVar("mp_enableroundwaittime"), 1, true);
	SetConVarInt(FindConVar("mp_stalemate_timelimit"), 5, true);
	SetConVarInt(FindConVar("mp_waitingforplayers_time"), 30, true);
	SetConVarInt(FindConVar("mp_stalemate_enable"), 0, true);
	SetConVarInt(FindConVar("mp_show_voice_icons"), 1, true);
	SetConVarInt(FindConVar("mp_bonusroundtime"), 15, true);
	SetConVarInt(FindConVar("tf_arena_preround_time"), 5, true);
	SetConVarInt(FindConVar("tf_solidobjects"), 1, true);
	
#if !defined AIRBLAST
	SetConVarInt(FindConVar("tf_flamethrower_burstammo"), 20, true);
#endif

	
	if(GetExtensionFileStatus("runteamlogic.ext") == 1)
	{
		cvar = FindConVar("rtl_arenateamsize");
		SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
		SetConVarInt(FindConVar("rtl_arenateamsize"), 16);
	}
}

public OnConfigsExecuted()
{
	SetCVars();
}

public OnConVarChanged(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	if (hCvar == g_PHEnable)
	{
		if(StringToInt(newValue) != 1)
		{
			Unload();
		}
	}
	else if (hCvar == g_PHAdvertisements)
	{
		strcopy(g_AdText, sizeof(g_AdText), newValue);
	}
}

public Unload()
{
	/// @TODO: Some fancy GetPluginFilename stuff
	if (g_PropNames != INVALID_HANDLE)
	CloseHandle(g_PropNames);
	ResetCVars();
	ServerCommand("sm plugins unload prophunt");
}

public Action:CallCheckInventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.5, CheckInventory, GetEventInt(event, "userid"));
}

public Action:CheckInventory(Handle:timer, any:userid)
{
	new entity;
	new prev = 0;
	new client = GetClientOfUserId(userid);
	if(client)
	{
		while((entity = FindEntityByClassname(entity, "tf_wearable")) != -1 && IsValidEntity(entity))
		{
			if(IsClientInGame(client) && GetClientTeam(client) == TEAM_RED && IsValidEntity(entity) && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 255, 255, 255, 0);
				if (prev && IsValidEdict(prev)) 
				RemoveEdict(prev);
				prev = entity;
			}
			else
			if(IsValidEdict(entity) && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 255, 255, 255, 255);
				SetVariantString("");
				AcceptEntityInput(client, "EnableShadow");
			}
		}
		if (prev && IsValidEdict(prev)) 
		RemoveEdict(prev);
	}
}

public StartTouchHook(entity, other)
{
	if(other <= MaxClients && other > 0 && !g_TouchingCP[other] && IsClientInGame(other) && IsPlayerAlive(other))
	{
		FillHealth(other);
		ExtinguishPlayer(other);
		PrintToChat(other, "%t", "#TF_PH_CPBonus");
		PH_EmitSoundToClient(other, "CPBonus", _, _, SNDLEVEL_AIRCRAFT);
		g_TouchingCP[other] = true;
	}
}

stock FillHealth (entity)
{
	if(IsValidEntity(entity))
	{
		SetEntityHealth(entity, GetEntData(entity, FindDataMapOffs(entity, "m_iMaxHealth")));
	}
}

stock bool:IsValidAdmin(client)
{
	decl String:flags[26];
	GetConVarString(g_PHAdmFlag, flags, sizeof(flags));
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	new iFlags = ReadFlagString(flags);
	if (GetUserFlagBits(client) & iFlags)
	{
		return true;
	}
	return false;
}

stock bool:IsValidDonor(client)
{
	decl String:flags[26];
	GetConVarString(g_PHAdmFlag, flags, sizeof(flags));
	if (GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
	{
		return true;
	}
	return false;
}

stock ExtinguishPlayer (client){
	if(IsClientInGame(client) && IsPlayerAlive(client) && IsValidEntity(client))
	{
		ExtinguishEntity(client);
		TF2_RemoveCondition(client, TFCond_OnFire);
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if(strcmp(classname, "team_control_point") == 0 ||
			strcmp(classname, "team_control_point_round") == 0 ||
			strcmp(classname, "trigger_capture_area") == 0 ||
			strcmp(classname, "func_respawnroom") == 0 ||
			strcmp(classname, "func_respawnroomvisualizer") == 0 ||
			strcmp(classname, "obj_sentrygun") == 0)
	{
		SDKHook(entity, SDKHook_Spawn, OnBullshitEntitySpawned);
	}
	else
	if(strcmp(classname, "prop_dynamic") == 0 || strcmp(classname, "prop_static") == 0)
	{
		SDKHook(entity, SDKHook_Spawn, OnCPEntitySpawned);
	}
}

public OnBullshitEntitySpawned(entity)
{
	if(IsValidEntity(entity))
	AcceptEntityInput(entity, "Kill");
}

public OnCPEntitySpawned(entity)
{
	decl String:propName[500];
	GetEntPropString(entity, Prop_Data, "m_ModelName", propName, sizeof(propName));
	if(StrEqual(propName, "models/props_gameplay/cap_point_base.mdl"))
	{
		SDKHook(entity, SDKHook_StartTouch, StartTouchHook);
	}
}

public OnMapEnd()
{
#if defined STATS
	g_MapChanging = true;
#endif

	// workaround no win panel event - admin changes, rtv, etc.
	g_RoundOver = true;
	g_inPreRound = true;
}

public OnMapStart()
{
	GetCurrentMap(g_Mapname, sizeof(g_Mapname));

	new arraySize = ByteCountToCells(100);
	g_ModelName = CreateArray(arraySize);
	g_ModelOffset = CreateArray(arraySize);
	PushArrayString(g_ModelName, "models/props_gameplay/cap_point_base.mdl");
	PushArrayString(g_ModelOffset, "0 0 0");
	
#if defined STATS
	g_MapChanging = false;
#endif

	if (g_PropMenu != INVALID_HANDLE)
	{
		CloseHandle(g_PropMenu);
		g_PropMenu = INVALID_HANDLE;
	}
	g_PropMenu = CreateMenu(Handler_PropMenu);
	SetMenuTitle(g_PropMenu, "PropHunt Prop Menu");
	SetMenuExitButton(g_PropMenu, true);
	AddMenuItem(g_PropMenu, "models/player/pyro.mdl", "models/player/pyro.mdl");
	AddMenuItem(g_PropMenu, "models/props_halloween/ghost.mdl", "models/props_halloween/ghost.mdl");

	decl String:confil[192], String:buffer[256], String:offset[32], String:tidyname[2][32], String:maptidyname[128];
	ExplodeString(g_Mapname, "_", tidyname, 2, 32);
	Format(maptidyname, sizeof(maptidyname), "%s_%s", tidyname[0], tidyname[1]);
	BuildPath(Path_SM, confil, sizeof(confil), "data/prophunt/maps/%s.cfg", maptidyname);
	new Handle:fl = CreateKeyValues("prophuntmapconfig");

	if(!FileToKeyValues(fl, confil))
	{
		LogMessage("[PH] Config file for map %s not found at %s. Unloading plugin.", maptidyname, confil);
		CloseHandle(fl);
		Unload();
		return;
	}
	else
	{
		PrintToServer("Successfully loaded %s", confil);
		KvGotoFirstSubKey(fl);
		KvJumpToKey(fl, "Props", false);
		KvGotoFirstSubKey(fl);
		do
		{
			KvGetSectionName(fl, buffer, sizeof(buffer));
			PushArrayString(g_ModelName, buffer);
			AddMenuItem(g_PropMenu, buffer, buffer);
			KvGetString(fl, "offset", offset, sizeof(offset), "0 0 0");
			PushArrayString(g_ModelOffset, offset);
		}
		while (KvGotoNextKey(fl));
		KvRewind(fl);
		KvJumpToKey(fl, "Settings", false);

		KvGetString(fl, "doors", buffer, sizeof(buffer), "0");
		g_Doors = strcmp(buffer, "1") == 0;

		KvGetString(fl, "relay", buffer, sizeof(buffer), "0");
		g_Relay = strcmp(buffer, "1") == 0;

		KvGetString(fl, "freeze", buffer, sizeof(buffer), "1");
		g_Freeze = strcmp(buffer, "1") == 0;

		KvGetString(fl, "round", buffer, sizeof(buffer), "175");
		g_RoundTime = StringToInt(buffer);

		PrintToServer("Successfully parsed %s", confil);
		PrintToServer("Loaded %i models, doors: %i, relay: %i, freeze: %i, round time: %i.", GetArraySize(g_ModelName)-1, g_Doors ? 1:0, g_Relay ? 1:0, g_Freeze ? 1:0, g_RoundTime);
	}
	CloseHandle(fl);

	decl String:model[100];

	for(new i = 0; i < GetArraySize(g_ModelName); i++)
	{
		GetArrayString(g_ModelName, i, model, sizeof(model));
		if(PrecacheModel(model, true) == 0)
		{
			RemoveFromArray(g_ModelName, i);
		}
	}

	PrecacheModel(FLAMETHROWER, true);
	
	/*new ent = FindEntityByClassname(-1, "team_control_point_master");
	if (ent == 1)
	{
		AcceptEntityInput(ent, "Kill");
	}
	ent = CreateEntityByName("team_control_point_master");
	DispatchKeyValue(ent, "switch_teams", "1");
	DispatchSpawn(ent);
	AcceptEntityInput(ent, "Enable");*/
	
	loadGlobalConfig();
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
	if (strlen(g_AdText) > 0)
	Format(gameDesc, sizeof(gameDesc), "PropHunt %s (%s)", g_Version, g_AdText);
	else
	Format(gameDesc, sizeof(gameDesc), "PropHunt %s", g_Version);
	
	return Plugin_Changed;
}

public OnPluginEnd()
{
	PrintCenterTextAll("%t", "#TF_PH_PluginReload");
#if defined STATS
	Stats_Uninit();
#endif
}

public Action:TakeDamageHook(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	
	if(victim > 0 && attacker > 0 && victim < MaxClients && attacker < MaxClients && IsClientInGame(victim) && IsPlayerAlive(victim) && GetClientTeam(victim) == TEAM_RED
			&& IsClientInGame(attacker) && GetClientTeam(attacker) == TEAM_BLUE)
	{

		if(!g_Hit[victim])
		{
			new Float:pos[3];
			GetClientAbsOrigin(victim, pos);
			PH_EmitSoundToClient(victim, "PropFound", _, SNDCHAN_WEAPON, _, _, 0.8, _, victim, pos);
			PH_EmitSoundToClient(attacker, "PropFound", _, SNDCHAN_WEAPON, _, _, 0.8, _, victim, pos);
			g_Hit[victim] = true;
		}
	}
	
	if(weapon > MaxClients && IsValidEntity(weapon))
	{
		damage = FloatMul(damage, g_weaponNerfs[GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")]);
		return Plugin_Changed;
	}
	
	//block prop drowning
	if(damagetype == DMG_DROWN && victim > 0 && victim < MaxClients && IsClientInGame(victim) && GetClientTeam(victim) == TEAM_RED && attacker == 0)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}


stock RemoveAnimeModel (client){
	if(IsClientInGame(client) && IsPlayerAlive(client) && IsValidEntity(client))
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
	}
}

public OnClientDisconnect(client)
{
#if defined STATS
	OCD(client);
#endif
}

public OnClientDisconnect_Post(client)
{
	ResetPlayer(client);
#if defined STATS
	OCD_Post(client);
#endif
}

stock SwitchView (target, bool:observer, bool:viewmodel){
	g_First[target] = !observer;
	/*SetEntPropEnt(target, Prop_Send, "m_hObserverTarget", observer ? target:-1);
	SetEntProp(target, Prop_Send, "m_iObserverMode", observer ? 1:0);
	SetEntData(target, g_oFOV, observer ? 100:GetEntData(target, g_oDefFOV, 4), 4, true);
	SetEntProp(target, Prop_Send, "m_bDrawViewmodel", viewmodel ? 1:0);*/
	
	SetVariantInt(observer ? 1 : 0);
	AcceptEntityInput(target, "SetForcedTauntCam");

	SetVariantInt(observer ? 1 : 0);
	AcceptEntityInput(target, "SetCustomModelVisibletoSelf");
}


stock ForceTeamWin (team){
	new ent = FindEntityByClassname(-1, "team_control_point_master");
	if (ent == -1)
	{
		ent = CreateEntityByName("team_control_point_master");
		DispatchSpawn(ent);
		AcceptEntityInput(ent, "Enable");
	}
	SetVariantInt(team);
	AcceptEntityInput(ent, "SetWinner");
}

public Action:Command_jointeam(client, args)
{
	decl String:argstr[16];
	GetCmdArgString(argstr, sizeof(argstr));
	if(StrEqual(argstr, "spectatearena"))
	{
		g_Spec[client] = true;
	}
	else
	{
		g_Spec[client] = false;
	}
	return Plugin_Continue;
}

public Action:Command_ReloadConfig(client, args)
{
	loadGlobalConfig();
	ReplyToCommand(client, "PropHunt Config reloaded");
	return Plugin_Handled;
}

public Action:Command_propmenu(client, args)
{
	if(GetConVarInt(g_PHPropMenu) == 1)
	{
		if(GetClientTeam(client) == TEAM_RED && IsPlayerAlive(client))
		{
			if (GetCmdArgs() == 1)
			{
				decl String:model[MAXMODELNAME];
				GetCmdArg(1, model, MAXMODELNAME);
				strcopy(g_PlayerModel[client], MAXMODELNAME, model); 
				Timer_DoEquip(INVALID_HANDLE, client);
			}
			else
			{
				DisplayMenu(g_PropMenu, client, MENU_TIME_FOREVER);
			}
		}
		else
		{
			PrintToChat(client, "You must be alive on RED to access the prop menu.");
		}
	}
	else if(IsValidAdmin(client) && GetConVarInt(g_PHPropMenu) == 0)
	{
		if(GetClientTeam(client) == TEAM_RED && IsPlayerAlive(client))
		{
			if (GetCmdArgs() == 1)
			{
				decl String:model[MAXMODELNAME];
				GetCmdArg(1, model, MAXMODELNAME);
				strcopy(g_PlayerModel[client], MAXMODELNAME, model); 
				Timer_DoEquip(INVALID_HANDLE, client);
			}
			else
			{
				DisplayMenu(g_PropMenu, client, MENU_TIME_FOREVER);
			}
		}
		else
		{
			PrintToChat(client, "You must be alive on RED to access the prop menu.");
		}
	}
	else if(IsValidDonor(client) && GetConVarInt(g_PHPropMenu) == 2)
	{
		if(GetClientTeam(client) == TEAM_RED && IsPlayerAlive(client))
		{
			if (GetCmdArgs() == 1)
			{
				decl String:model[MAXMODELNAME];
				GetCmdArg(1, model, MAXMODELNAME);
				strcopy(g_PlayerModel[client], MAXMODELNAME, model); 
				Timer_DoEquip(INVALID_HANDLE, client);
			}
			else
			{
				DisplayMenu(g_PropMenu, client, MENU_TIME_FOREVER);
			}
		}
		else
		{
			PrintToChat(client, "You must be alive on RED to access the prop menu.");
		}
	}
	else
	{
		PrintToChat(client, "You do not have access to the prop menu.");
	}
	return Plugin_Handled;
}


public Handler_PropMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			if(IsClientInGame(param1))
			{
				if(GetConVarInt(g_PHPropMenu) == 1 || IsValidAdmin(param1))
				{
					if(GetClientTeam(param1) == TEAM_RED && IsPlayerAlive(param1))
					{
						GetMenuItem(menu, param2, g_PlayerModel[param1], MAXMODELNAME);
						Timer_DoEquip(INVALID_HANDLE, param1);
					}
					else
					{
						PrintToChat(param1, "You must be alive on RED to access the prop menu.");
					}
				}
				else if(GetConVarInt(g_PHPropMenu) == 2 || IsValidDonor(param1))
				{
					if(GetClientTeam(param1) == TEAM_RED && IsPlayerAlive(param1))
					{
						GetMenuItem(menu, param2, g_PlayerModel[param1], MAXMODELNAME);
						Timer_DoEquip(INVALID_HANDLE, param1);
					}
					else
					{
						PrintToChat(param1, "You must be alive on RED to access the prop menu.");
					}
				}
				else if(GetConVarInt(g_PHPropMenu) == 0)
				{
					if(GetClientTeam(param1) == TEAM_RED && IsPlayerAlive(param1))
					{
						GetMenuItem(menu, param2, g_PlayerModel[param1], MAXMODELNAME);
						Timer_DoEquip(INVALID_HANDLE, param1);
					}
					else
					{
						PrintToChat(param1, "You must be alive on RED to access the prop menu.");
					}
				}
				else
				{
					PrintToChat(param1, "You do not have access to the prop menu.");
				}
			}
		}
	}
}

public OnClientPutInServer(client)
{
	ResetPlayer(client);
}

public ResetPlayer(client)
{
	g_Spawned[client] = false;
	g_Charge[client] = false;
	g_AllowedSpawn[client] = false;
	g_Hit[client] = false;
	g_Attacking[client] = false;
	g_RotLocked[client] = false;
	g_Spec[client] = false;
	g_TouchingCP[client] = false;
	g_First[client] = false;
	g_PlayerModel[client] = "";
	g_SetClass[client] = false;
}

public Action: Command_respawn(client, args)
{
	TF2_RespawnPlayer(client);
	return Plugin_Handled;
}

public Action:Command_internet(client, args)
{
	decl String:name[255];
	for(new i = 0; i < 3; i++)
	{
		PH_EmitSoundToAll("Internet", _, _, SNDLEVEL_AIRCRAFT);
	}
	GetClientName(client, name, sizeof(name));
	return Plugin_Handled;
}

PH_EmitSoundToAll(const String:soundid[], entity = SOUND_FROM_PLAYER, channel = SNDCHAN_AUTO, level = SNDLEVEL_NORMAL, flags = SND_NOFLAGS, Float:volume = SNDVOL_NORMAL, pitch = SNDPITCH_NORMAL, speakerentity = -1, const Float:origin[3] = NULL_VECTOR, const Float:dir[3] = NULL_VECTOR, bool:updatePos = true, Float:soundtime = 0.0)
{
	decl String:sample[128];
	if(GetTrieString(g_Sounds, soundid, sample, sizeof(sample)))
	{
		if(!IsSoundPrecached(sample))
		{
			PrecacheSound(sample);
		}
		EmitSoundToAll(sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
	}
}

PH_EmitSoundToClient(client, const String:soundid[], entity = SOUND_FROM_PLAYER, channel = SNDCHAN_AUTO, level = SNDLEVEL_NORMAL, flags = SND_NOFLAGS, Float:volume = SNDVOL_NORMAL, pitch = SNDPITCH_NORMAL, speakerentity = -1, const Float:origin[3] = NULL_VECTOR, const Float:dir[3] = NULL_VECTOR, bool:updatePos = true, Float:soundtime = 0.0)
{
	decl String:sample[128];
	if(GetTrieString(g_Sounds, soundid, sample, sizeof(sample)))
	{
		if(!IsSoundPrecached(sample))
		{
			PrecacheSound(sample);
		}
		EmitSoundToClient(client, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
	}
}

public Action:Command_switch(client, args)
{
	g_AllowedSpawn[client] = true;
	ChangeClientTeam(client, TEAM_RED);
	TF2_RespawnPlayer(client);
	CreateTimer(0.5, Timer_Move, client);
	return Plugin_Handled;
}

public Action:Command_pyro(client, args)
{
	g_PlayerModel[client] = "";
	g_AllowedSpawn[client] = true;
	ChangeClientTeam(client, TEAM_BLUE);
	TF2_RespawnPlayer(client);
	CreateTimer(0.5, Timer_Move, client);
	CreateTimer(0.8, Timer_Unfreeze, client);
	return Plugin_Handled;
}
stock PlayersAlive (){
	new alive = 0;
	for(new i=1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		alive++;
	}
	return alive;
}

public StopPreroundTimers(bool:instant)
{
	StopTimer(g_TimerStart);
	for (new i = 0; i < sizeof(g_CountdownSoundTimers); i++)
	{
		if(g_CountdownSoundTimers[i] != INVALID_HANDLE)
		{
			StopTimer(g_CountdownSoundTimers[i]);
		}
	}
	if(instant)
	{
		StopTimer(g_RoundTimer);
	}
	else
	{
		CreateTimer(2.0, Timer_AfterWinPanel);
	}
}

stock ChangeClientTeamAlive (client, team)
{
	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, team);
	SetEntProp(client, Prop_Send, "m_lifeState", 0);
}

stock GetRandomPlayer (team)
{
	new client, totalclients;

	for(client=1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			totalclients++;
		}
	}

	new clientarray[totalclients], i;
	for(client=1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			clientarray[i] = client;
			i++;
		}
	}

	do
	{
		client = clientarray[GetRandomInt(0, totalclients-1)];
	}
	while( !(IsClientInGame(client) && GetClientTeam(client) == team) );
	return client;
}

stock StopTimer (Handle:timer)
{
	if(timer != INVALID_HANDLE) KillTimer(timer);
	timer = INVALID_HANDLE;
}

stock IsPropHuntMap ()
{
	GetCurrentMap(g_Mapname, sizeof(g_Mapname));

	new String:confil[192], String:tidyname[2][32], String:maptidyname[128];
	ExplodeString(g_Mapname, "_", tidyname, 2, 32);
	Format(maptidyname, sizeof(maptidyname), "%s_%s", tidyname[0], tidyname[1]);
	BuildPath(Path_SM, confil, sizeof(confil), "data/prophunt/maps/%s.cfg", maptidyname);
	new Handle:fl = CreateKeyValues("prophuntmapconfig");

	if(!FileToKeyValues(fl, confil))
	{
		LogMessage("[PH] Config file for map %s not found at %s. Unloading plugin.", maptidyname, confil);
		CloseHandle(fl);
		return false;
	}
	else
	{
		CloseHandle(fl);
		return true;
	}
}


public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{

	if(g_RoundOver)
	return Plugin_Continue;
	
	
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_BLUE && IsValidEntity(weapon))
	{
		new Float:damage = 10.0;
		damage = g_weaponSelfDamage[GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")];
		
		SDKHooks_TakeDamage(client, client, weapon, damage, DMG_PREVENT_PHYSICS_FORCE);
		
		if(strcmp(weaponname, "tf_weapon_flamethrower") == 0) AddVelocity(client, 1.0);

		result = false;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock AddVelocity (client, Float:speed){
	new Float:velocity[3];
	GetEntDataVector(client, g_iVelocity, velocity);

	// fucking win
	if(velocity[0] < 200 && velocity[0] > -200)
	velocity[0] *= (1.08 * speed);
	if(velocity[1] < 200 && velocity[1] > -200)
	velocity[1] *= (1.08 * speed);
	if(velocity[2] > 0 && velocity[2] < 400)
	velocity[2] = velocity[2] * 1.15 * speed;

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
}

public Action:SetTransmitHook(entity, client)
{
	if(g_First[client] && client == entity)
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

/*
public PreThinkHook(client)
{

	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(!(TF2_IsPlayerInCondition(client, TFCond_Slowed) || TF2_IsPlayerInCondition(client, TFCond_Zoomed) || 
		TF2_IsPlayerInCondition(client, TFCond_Bonked) || TF2_IsPlayerInCondition(client, TFCond_Dazed) || 
		TF2_IsPlayerInCondition(client, TFCond_Charging) || TF2_IsPlayerInCondition(client, TFCond_SpeedBuffAlly)))
		{
			ResetSpeed(client);
		}
		
		new clientButtons = GetClientButtons(client);

		if(GetClientTeam(client) == TEAM_RED)
		{
			if(clientButtons & IN_ATTACK && !g_HoldingLMB[client] || g_RotLocked[client])
			{
				g_HoldingLMB[client] = true;
				if(!g_RotLocked[client])
				{
					new Float:velocity[3];
					GetEntDataVector(client, g_iVelocity, velocity);
					// if the client is moving, don't allow them to lock in place
					if(velocity[0] > -5 && velocity[1] > -5 && velocity[2] > -5 && velocity[0] < 5 && velocity[1] < 5 && velocity[2] < 5)
					{
						//PrintToChatAll("PH DEBUG: %L Has locked their prop!", client);
						SetVariantInt(0);
						AcceptEntityInput(client, "SetCustomModelRotates");
						g_RotLocked[client] = true;
#if defined LOCKSOUND
						PH_EmitSoundToClient(client, "LockSound", _, _, _, _, LOCKVOL);
#endif
					}
				}
				else if(clientButtons & IN_MOVEMENT)
				{
					//PrintToChatAll("PH DEBUG: %L Has unlocked their prop!", client);
					SetVariantInt(1);
					AcceptEntityInput(client, "SetCustomModelRotates");
#if defined LOCKSOUND
					PH_EmitSoundToClient(client, "UnlockSound", _, _, _, _, LOCKVOL);
#endif
					g_RotLocked[client] = false;
				}
			}
			else if(!(clientButtons & IN_ATTACK))
			{
				g_HoldingLMB[client] = false;
			}
			
			if((clientButtons & IN_ATTACK2) == IN_ATTACK2 && !g_HoldingRMB[client])
			{
				//PrintToChatAll("PH DEBUG: %L Has clicked!", client);
				g_HoldingRMB[client] = true;
				if(g_First[client])
				{
					PrintHintText(client, "Third Person mode selected");
					SwitchView(client, true, false);
				}
				else
				{
					PrintHintText(client, "First Person mode selected");
					SwitchView(client, false, false);
				}

			}
			else
			if((clientButtons & IN_ATTACK2) != IN_ATTACK2)
			{
				g_HoldingRMB[client] = false;
			}
#if defined CHARGE
			if((clientButtons & IN_RELOAD) == IN_RELOAD)
			{
				if(!g_Charge[client])
				{
					g_Charge[client] = true;
					SetEntData(client, g_offsCollisionGroup, COLLISION_GROUP_DEBRIS_TRIGGER, _, true);
					TF2_SetPlayerClass(client, TFClass_DemoMan, false);
					TF2_AddCondition(client, TFCond_Charging, 2.5);
					CreateTimer(2.5, Timer_Charge, client);
				}
			}
#endif
		}
		else
		if(GetClientTeam(client) == TEAM_BLUE && TF2_GetPlayerClass(client) == TFClass_Pyro)
		{
			if(IsValidEntity(GetPlayerWeaponSlot(client, 1)) && GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iItemDefinitionIndex") == WEP_SHOTGUNPYRO || IsValidEntity(GetPlayerWeaponSlot(client, 1)) && GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iItemDefinitionIndex") == WEP_SHOTGUN_UNIQUE)
			{
				SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 8, SHOTGUN_MAX_AMMO-GetEntData(GetPlayerWeaponSlot(client, 1), FindSendPropInfo("CBaseCombatWeapon", "m_iClip1")));
				if(GetEntData(GetPlayerWeaponSlot(client, 1), FindSendPropInfo("CBaseCombatWeapon", "m_iClip1")) > SHOTGUN_MAX_AMMO)
				{
					SetEntData(GetPlayerWeaponSlot(client, 1), FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), SHOTGUN_MAX_AMMO);
				}
			}
		}
	} // in game
}
*/


public PreThinkHook(client)
{

	if(IsClientInGame(client))
	{

		if(IsPlayerAlive(client))
		{
			if(!(TF2_IsPlayerInCondition(client, TFCond_Slowed) || TF2_IsPlayerInCondition(client, TFCond_Zoomed) || 
			TF2_IsPlayerInCondition(client, TFCond_Bonked) || TF2_IsPlayerInCondition(client, TFCond_Dazed) || 
			TF2_IsPlayerInCondition(client, TFCond_Charging) || TF2_IsPlayerInCondition(client, TFCond_SpeedBuffAlly)))
			{
				ResetSpeed(client);
			}
			
			new buttons = GetClientButtons(client);
			if((buttons & IN_ATTACK) == IN_ATTACK && GetClientTeam(client) == TEAM_BLUE)
			{
				g_Attacking[client] = true;
			}
			else
			{
				g_Attacking[client] = false;
			}

			if(GetClientTeam(client) == TEAM_RED)
			{
				// tl;dr - (LMB and not crouching OR any movement key while locked) AND not holding key
				if(((((buttons & IN_ATTACK) == IN_ATTACK && (buttons & IN_DUCK) != IN_DUCK) ||
								((buttons & IN_FORWARD) == IN_FORWARD || (buttons & IN_MOVELEFT) == IN_MOVELEFT || (buttons & IN_MOVERIGHT) == IN_MOVERIGHT ||
									(buttons & IN_BACK) == IN_BACK || (buttons & IN_JUMP) == IN_JUMP) && g_RotLocked[client])) && !g_HoldingLMB[client]
						)
				{
					g_HoldingLMB[client] = true;
					if(GetPlayerWeaponSlot(client, 0) == -1)
					{

						if(!g_RotLocked[client])
						{
							new Float:velocity[3];
							GetEntDataVector(client, g_iVelocity, velocity);
							// if the client is moving, don't allow them to lock in place
							if(velocity[0] > -5 && velocity[1] > -5 && velocity[2] > -5 && velocity[0] < 5 && velocity[1] < 5 && velocity[2] < 5)
							{
								SetVariantInt(0);
								AcceptEntityInput(client, "SetCustomModelRotates");
								g_RotLocked[client] = true;
#if defined LOCKSOUND
								PH_EmitSoundToClient(client, "LockSound", _, _, _, _, LOCKVOL);
#endif
							}

						}
						else
						if(g_RotLocked[client])
						{
							SetVariantInt(1);
							AcceptEntityInput(client, "SetCustomModelRotates");
#if defined LOCKSOUND
							PH_EmitSoundToClient(client, "UnlockSound", _, _, _, _, LOCKVOL);
#endif
							g_RotLocked[client] = false;
						}
					}
				}
				else if((buttons & IN_ATTACK) != IN_ATTACK)
				{
					g_HoldingLMB[client] = false;
				}

				if((buttons & IN_ATTACK2) == IN_ATTACK2 && !g_HoldingRMB[client])
				{
					g_HoldingRMB[client] = true;
					if(g_First[client])
					{
						PrintHintText(client, "Third Person mode selected");
						SwitchView(client, true, false);
					}
					else
					{
						PrintHintText(client, "First Person mode selected");
						SwitchView(client, false, false);
					}

				}
				else
				if((buttons & IN_ATTACK2) != IN_ATTACK2)
				{
					g_HoldingRMB[client] = false;
				}
#if defined CHARGE
				if((buttons & IN_RELOAD) == IN_RELOAD)
				{
					if(!g_Charge[client])
					{
						g_Charge[client] = true;
						SetEntData(client, g_offsCollisionGroup, COLLISION_GROUP_DEBRIS_TRIGGER, _, true);
						TF2_SetPlayerClass(client, TFClass_DemoMan, false);
						TF2_AddCondition(client, TFCond_Charging, 2.5);
						CreateTimer(2.5, Timer_Charge, client);
					}
				}
#endif
			}
			else
			if(GetClientTeam(client) == TEAM_BLUE && TF2_GetPlayerClass(client) == TFClass_Pyro)
			{
				if(IsValidEntity(GetPlayerWeaponSlot(client, 1)) && GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iItemDefinitionIndex") == WEP_SHOTGUNPYRO || IsValidEntity(GetPlayerWeaponSlot(client, 1)) && GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iItemDefinitionIndex") == WEP_SHOTGUN_UNIQUE)
				{
					SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 8, SHOTGUN_MAX_AMMO-GetEntData(GetPlayerWeaponSlot(client, 1), FindSendPropInfo("CBaseCombatWeapon", "m_iClip1")));
					if(GetEntData(GetPlayerWeaponSlot(client, 1), FindSendPropInfo("CBaseCombatWeapon", "m_iClip1")) > SHOTGUN_MAX_AMMO)
					{
						SetEntData(GetPlayerWeaponSlot(client, 1), FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), SHOTGUN_MAX_AMMO);
					}
				}
			}

		} // alive
	} // in game
}

public SetupRoundTime(time)
{
	g_RoundTimer = CreateTimer(float(time-1), Timer_TimeUp, _, TIMER_FLAG_NO_MAPCHANGE);
	SetConVarInt(FindConVar("tf_arena_round_time"), time, true, false);
}


public GetClassCount(TFClassType:class, team) 
{
	new classCount;
	for(new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == team && TF2_GetPlayerClass(client) == class)
		{
			classCount++;
		}
	}
	return classCount;
}


public Action:Command_motd(client, args)
{
	if(IsClientInGame(client))
	{
		ShowMOTDPanel(client, "PropHunt Stats", "http://www.gamingmasters.org/prophunt/index.php", MOTDPANEL_TYPE_URL);
	}
	return Plugin_Handled;
}


stock SetAlpha (target, alpha){
	SetWeaponsAlpha(target,alpha);
	SetEntityRenderMode(target, RENDER_TRANSCOLOR);
	SetEntityRenderColor(target, 255, 255, 255, alpha);
}

stock SetWeaponsAlpha (target, alpha){
	if(IsPlayerAlive(target))
	{
		decl String:classname[64];
		new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");
		for(new i = 0, weapon; i < 47; i += 4)
		{
			weapon = GetEntDataEnt2(target, m_hMyWeapons + i);
			if(weapon > -1 && IsValidEdict(weapon))
			{
				GetEdictClassname(weapon, classname, sizeof(classname));
				if(StrContains(classname, "tf_weapon", false) != -1)
				{
					SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
					SetEntityRenderColor(weapon, 255, 255, 255, alpha);
				}
			}
		}
	}
}

public Speedup (client)
{
	new TFClassType:clientClass = TF2_GetPlayerClass(client);
	
	new Float:clientSpeed = g_currentSpeed[client] + g_classSpeeds[clientClass][2];
	
	if(clientSpeed < g_classSpeeds[clientClass][0])
	{
		clientSpeed = g_classSpeeds[clientClass][0];
	}
	else if(clientSpeed > g_classSpeeds[clientClass][1])
	{
		clientSpeed = g_classSpeeds[clientClass][1];
	}
	
	SetEntDataFloat(client, FindSendPropInfo("CTFPlayer", "m_flMaxspeed"), clientSpeed);
	
	g_currentSpeed[client]  = clientSpeed;
}

ResetSpeed (client)
{	
		SetEntDataFloat(client, FindSendPropInfo("CTFPlayer", "m_flMaxspeed"), g_currentSpeed[client]);
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	return entity != data;
}

public Action:Event_player_team(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetEventInt(event, "team") > 1)
	{
		g_Spec[client] = false;
	}
}

public Action:Event_arena_win_panel(Handle:event, const String:name[], bool:dontBroadcast)
{
#if defined LOG
	LogMessage("[PH] round end");
#endif


	g_RoundOver = true;
	g_inPreRound = true;

#if defined STATS
	new winner = GetEventInt(event, "winning_team");
	DbRound(winner);
#endif

	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0, true);

	new team, client;
	for(client=1; client <= MaxClients; client++)
	{
		ResetPlayer(client);
		if(IsClientInGame(client))
		{
#if defined STATS
			if(GetClientTeam(client) == winner)
			{
				AlterScore(client, 3, ScReason_TeamWin, 0);
			}
			else
			if(GetClientTeam(client) != TEAM_SPEC)
			{
				AlterScore(client, -1, ScReason_TeamLose, 0);
			}
#endif
			// bit annoying when testing the plugin and/or maps on a listen server
			if(IsDedicatedServer())
			{
				team = GetClientTeam(client);
				if(team == TEAM_RED || team == TEAM_BLUE)
				{
					team = team == TEAM_RED ? TEAM_BLUE:TEAM_RED;
					ChangeClientTeamAlive(client, team);
				}
			}
		}
	}

#if defined LOG
	LogMessage("Team balancing...");
#endif
	decl String:cname[64];
	while(GetTeamClientCount(TEAM_RED) > GetTeamClientCount(TEAM_BLUE) )
	{
		client = GetRandomPlayer(TEAM_RED);
		GetClientName(client, cname, sizeof(cname));
		PrintToChatAll("%t", "#TF_PH_BalanceBlu", cname);
		ChangeClientTeamAlive(client, TEAM_BLUE);
	}
	while(GetTeamClientCount(TEAM_BLUE) > GetTeamClientCount(TEAM_RED) +1 )
	{
		client = GetRandomPlayer(TEAM_BLUE);
		GetClientName(client, cname, sizeof(cname));
		PrintToChatAll("%t", "#TF_PH_BalanceRed", cname);
		ChangeClientTeamAlive(client, TEAM_RED);
	}
#if defined LOG
	LogMessage("Complete");
#endif

	SetConVarFlags(FindConVar("mp_teams_unbalance_limit"), GetConVarFlags(FindConVar("mp_teams_unbalance_limit")) & ~(FCVAR_NOTIFY));
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), UNBALANCE_LIMIT, true);

	StopPreroundTimers(false);
}

public Action:Event_teamplay_round_start_pre(Handle:event, const String:name[], bool:dontBroadcast)
{
	new bool:reset = GetEventBool(event, "full_reset");
#if defined LOG
	LogMessage("[PH] teamplay round start: %i, %i", reset, g_RoundOver);
#endif
	// checking for the first time this calls (pre-setup), i think
	if(reset && g_RoundOver)
	{
		new team, zteam=TEAM_BLUE;
		for(new client=1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
			{

				team = GetClientTeam(client);

				// prevent sitting out
				if(team == TEAM_SPEC && !g_Spec[client])
				{
					ChangeClientTeam(client, zteam);
					zteam = zteam == TEAM_BLUE ? TEAM_RED:TEAM_BLUE;
				}

			}
		}
	}
}

public Action:Event_arena_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
#if defined LOG
	LogMessage("[PH] round start - %i", g_RoundOver );
#endif
	g_inPreRound = false;
	g_LastProp = false;
	if(g_RoundOver)
	{

		for(new client=1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
			{
				if(GetClientTeam(client) == TEAM_RED)
				{
					Timer_DoEquip(INVALID_HANDLE, client);
					SetEntityMoveType(client, MOVETYPE_WALK);
				}
				else
				{
					Timer_DoEquipBlu(INVALID_HANDLE, client);
				}
				g_currentSpeed[client] = g_classSpeeds[TF2_GetPlayerClass(client)][0]; // Reset to default speed.
			}
		}
		
		SetupRoundTime(g_RoundTime);
		
		//GameMode Explanation
		decl String:message[256];
		new ent;
		ent=FindEntityByClassname(-1, "tf_gamerules");

		//BLU
		Format(message, sizeof(message), "%T", "#TF_PH_BluHelp", LANG_SERVER);
		SetVariantString(message);
		AcceptEntityInput(ent, "SetBlueTeamGoalString");
		SetVariantString("2");
		AcceptEntityInput(ent, "SetRedTeamRole");

		//RED
		Format(message, sizeof(message), "%T", "#TF_PH_RedHelp", LANG_SERVER);
		SetVariantString(message);
		AcceptEntityInput(ent, "SetRedTeamGoalString");
		SetVariantString("1");
		AcceptEntityInput(ent, "SetRedTeamRole");

		CreateTimer(0.1, Timer_Info);
		
		g_CountdownSoundTimers[0] = CreateTimer(0.1, Timer_PlaySound, 0, TIMER_FLAG_NO_MAPCHANGE);
		g_CountdownSoundTimers[1] = CreateTimer(10.0, Timer_PlaySound, 1, TIMER_FLAG_NO_MAPCHANGE);
		g_CountdownSoundTimers[2] = CreateTimer(20.0, Timer_PlaySound, 2, TIMER_FLAG_NO_MAPCHANGE);
		g_CountdownSoundTimers[3] = CreateTimer(25.0, Timer_PlaySound, 3, TIMER_FLAG_NO_MAPCHANGE);
		g_CountdownSoundTimers[4] = CreateTimer(26.0, Timer_PlaySound, 4, TIMER_FLAG_NO_MAPCHANGE);
		g_CountdownSoundTimers[5] = CreateTimer(27.0, Timer_PlaySound, 5, TIMER_FLAG_NO_MAPCHANGE);
		g_CountdownSoundTimers[6] = CreateTimer(28.0, Timer_PlaySound, 6, TIMER_FLAG_NO_MAPCHANGE);
		g_CountdownSoundTimers[7] = CreateTimer(29.0, Timer_PlaySound, 7, TIMER_FLAG_NO_MAPCHANGE);
		
		
		g_TimerStart = CreateTimer(30.0, Timer_Start, _, TIMER_FLAG_NO_MAPCHANGE);
		
#if defined STATS
		g_StartTime = GetTime();
#endif
	}
}

stock RemovePlayerCanteen(client)
{
	new edict = MaxClients+1;
	while((edict = FindEntityByClassname(edict, "tf_powerup_bottle")) != -1)
	{
		new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
		if(idx == 489)
		{
			AcceptEntityInput(edict, "Kill");
		}
	}
}

stock bool:IsValidClient(client, bool:replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client, false)){			
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		RemovePlayerCanteen(client);	
	}
		
	g_currentSpeed[client] = g_classSpeeds[TF2_GetPlayerClass(client)][0]; // Reset to default speed.
	
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		// stupid glitch fix
		if(!g_RoundOver && !g_AllowedSpawn[client])
		{
			ForcePlayerSuicide(client);
			return Plugin_Continue;
		}
		RemoveAnimeModel(client);
		SDKHook(client, SDKHook_OnTakeDamage, TakeDamageHook);
		SDKHook(client, SDKHook_PreThink, PreThinkHook);
#if defined LOG
		LogMessage("[PH] Player spawn %N", client);
#endif
		g_Hit[client] = false;

		if(GetClientTeam(client) == TEAM_BLUE)
		{

			PrintToChat(client, "%t", "#TF_PH_WaitingPeriodStarted");
#if defined SHINX

			new TFClassType:clientClass = TF2_GetPlayerClass(client);
			if (g_classLimits[TEAM_BLUE-2][clientClass] != -1 && GetClassCount(clientClass, TEAM_BLUE) > g_classLimits[TEAM_BLUE-2][clientClass])
			{
				if(g_classLimits[TEAM_BLUE-2][clientClass] == 0)
				{
					//PrintToChat(client, "%t", "#TF_PH_ClassBlocked");
				}
				else
				{
					PrintToChat(client, "%t", "#TF_PH_ClassFull");
				}
				
				TF2_SetPlayerClass(client, g_defaultClass[TEAM_BLUE-2]);
				TF2_RespawnPlayer(client);
				
				return Plugin_Continue;
			}
			
#else
			if(TF2_GetPlayerClass(client) != g_defaultClass[TEAM_BLUE-2])
			{
				TF2_SetPlayerClass(client, g_defaultClass[TEAM_BLUE-2]);
				TF2_RespawnPlayer(client);
				return Plugin_Continue;
			}
#endif
			CreateTimer(0.1, Timer_DoEquipBlu, GetClientUserId(client));

		}
		else
		if(GetClientTeam(client) == TEAM_RED)
		{
			if(g_RoundOver)
			{
				SetEntityMoveType(client, MOVETYPE_NONE);
			}
			
			SetVariantString("");
			AcceptEntityInput(client, "DisableShadow");
			
			if(TF2_GetPlayerClass(client) != g_defaultClass[TEAM_RED-2])
			{
				TF2_SetPlayerClass(client, TFClassType:g_defaultClass[TEAM_RED-2]);
				TF2_RespawnPlayer(client);
			}
			CreateTimer(0.1, Timer_DoEquip, client);
		}

	}
	return Plugin_Continue;
}

public Action:Event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{

	if (GetEventInt(event, "weaponid") == TF_WEAPON_BAT_FISH && GetEventInt(event, "customkill") == TF_CUSTOM_FISH_KILL)
	{
		return Plugin_Continue;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsClientInGame(client))
	{
#if defined LOG
		LogMessage("[PH] Player death %N", client);
#endif
		//RemoveAnimeModel(client);

		CreateTimer(0.1, Timer_Ragdoll, client);

		SDKUnhook(client, SDKHook_OnTakeDamage, TakeDamageHook);
		SDKUnhook(client, SDKHook_PreThink, PreThinkHook);
	}

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	
#if defined STATS
	decl String:weapon[64];
	new assisterID = GetEventInt(event, "assister");
	new attackerID = GetEventInt(event, "attacker");
	new clientID = GetEventInt(event, "userid");
	new weaponid = GetEventInt(event, "weaponid");
	GetEventString(event, "weapon", weapon, sizeof(weapon));
#endif

	if(!g_RoundOver)
	g_Spawned[client] = false;

	g_Hit[client] = false;

	new playas = 0;
	for(new i=1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) /*&& !IsFakeClient(i)*/ && IsPlayerAlive(i) && GetClientTeam(i) == TEAM_RED)
		{
			playas++;
		}
	}


	if(!g_RoundOver && GetClientTeam(client) == TEAM_RED)
	{

		PH_EmitSoundToClient(client, "PropDeath");
	}

	if(!g_RoundOver)
	{
		if(client > 0 && attacker > 0 && IsClientInGame(client) && IsClientInGame(attacker) && client != attacker)
		{
#if defined STATS
			PlayerKilled(clientID, attackerID, assisterID, weaponid, weapon);
#endif
			if(IsPlayerAlive(attacker))
			{
				Speedup(attacker);
				FillHealth(attacker);
			}
			
			if(assister > 0 && IsClientInGame(assister))
			{
				if(IsPlayerAlive(assister))
				{
					Speedup(assister);
					FillHealth(assister);
				}
			}
			
		}
	}

	if(playas == 2 && !g_RoundOver && GetClientTeam(client) == TEAM_RED)
	{
		g_LastProp = true;
		PH_EmitSoundToAll("OneAndOnly", _, _, SNDLEVEL_AIRCRAFT);
#if defined SCATTERGUN
		for(new client2=1; client2 <= MaxClients; client2++)
		{
			if(IsClientInGame(client2) && !IsFakeClient(client2) && IsPlayerAlive(client2))
			{
				if(GetClientTeam(client2) == TEAM_RED)
				{
					TF2_RegeneratePlayer(client2);
					CreateTimer(0.2, Timer_WeaponAlpha, client2);
				}
				else
				if(GetClientTeam(client2) == TEAM_BLUE)
				{
					TF2_AddCondition(client2, TFCond_Jarated, 15.0);
				}
			}
		}
#endif
	}
	SetVariantString("ParticleEffectStop");
	AcceptEntityInput(client, "DispatchEffect");
	return Plugin_Continue;
}

//////////////////////////////////////////////////////
///////////////////  TIMERS  ////////////////////////
////////////////////////////////////////////////////


public Action:Timer_WeaponAlpha(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	SetWeaponsAlpha(client, 0);
}
public Action:Timer_PlaySound(Handle:timer, any:data)
{
	PH_EmitSoundToAll(g_CountdownSounds[data], _, _, SNDLEVEL_AIRCRAFT);
	g_CountdownSoundTimers[data] = INVALID_HANDLE;
	return Plugin_Handled;
}

public Action:Timer_Info(Handle:timer, any:client)
{
	g_Message_bit++;

	if(g_Message_bit == 2)
	{
		SetHudTextParamsEx(-1.0, 0.22, 5.0, {0,204,255,255}, {0,0,0,255}, 2, 1.0, 0.05, 0.5);
		for(new i=1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				ShowSyncHudText(i, g_Text1, "PropHunt %s", g_Version);
			}
		}
	}
	else if(g_Message_bit == 3)
	{
		SetHudTextParamsEx(-1.0, 0.25, 4.0, {255,128,0,255}, {0,0,0,255}, 2, 1.0, 0.05, 0.5);
		for(new i=1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				ShowSyncHudText(i, g_Text2, "By Darkimmortal and Geit");
			}
		}
	}
	else if(g_Message_bit == 4 && strlen(g_AdText) > 0)
	{
		SetHudTextParamsEx(-1.0, 0.3, 3.0, {0,220,0,255}, {0,0,0,255}, 2, 1.0, 0.05, 0.5);
		for(new i=1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				ShowSyncHudText(i, g_Text3, g_AdText);
			}
		}
	}
	
	if(g_Message_bit < 10 && IsValidEntity(g_Message_red) && IsValidEntity(g_Message_blue))
	{
		AcceptEntityInput(g_Message_red, "Display");
		AcceptEntityInput(g_Message_blue, "Display");
		CreateTimer(1.0, Timer_Info);
	}
}

public Action:Timer_DoEquipBlu (Handle:timer, any: UserId)
{
	new client = GetClientOfUserId(UserId);
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(g_Freeze)
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
		}

		SwitchView(client, false, true);
		SetAlpha(client, 255);
		
		new removedWeapons, validWeapons;
		
		for (new i = 0; i < 5; i++)
		{
			new playerItemSlot = GetPlayerWeaponSlot(client, i);
			
			if(playerItemSlot > MaxClients && IsValidEntity(playerItemSlot))
			{
				validWeapons++;
				if( g_weaponRemovals[GetEntProp(playerItemSlot, Prop_Send, "m_iItemDefinitionIndex")])
				{
					TF2_RemoveWeaponSlot(client, i);
					removedWeapons++;
				}			
			}
		}
		if(validWeapons == removedWeapons)
		{
			TF2_SetPlayerClass(client, TFClass_Pyro);
			g_AllowedSpawn[client] = true;
			TF2_RespawnPlayer(client);
		}
	}
	return Plugin_Handled;
}

public Action:Timer_DoEquip(Handle:timer, any:client)
{

	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		//TF2_RegeneratePlayer(client);
		
		#if defined LOG
				LogMessage("[PH] do equip %N", client);
		#endif
		// slot commands fix "remember last weapon" glitch, despite their client console spam
		FakeClientCommand(client, "slot0");
		FakeClientCommand(client, "slot3");
		TF2_RemoveAllWeapons(client);
		FakeClientCommand(client, "slot3");
		FakeClientCommand(client, "slot0");
		
		decl String:pname[32];
		Format(pname, sizeof(pname), "ph_player_%i", client);
		DispatchKeyValue(client, "targetname", pname);
		#if defined LOG
				LogMessage("[PH] do equip_2 %N", client);
		#endif
		// fire in a nice random model
		decl String:model[MAXMODELNAME], String:offset[32];
		new RandomInt = GetRandomInt(0, GetArraySize(g_ModelName)-1);
		if(strlen(g_PlayerModel[client]) > 1)
		{
			model = g_PlayerModel[client];
		}
		else
		{
			GetArrayString(g_ModelName, RandomInt, model, sizeof(model));
		}
		#if defined LOG
				LogMessage("[PH] do equip_3 %N", client);
		#endif
		if(strlen(g_PlayerModel[client]) < 1)
		{
			decl String:nicemodel[MAXMODELNAME], String:nicemodel2[MAXMODELNAME];
			
			new lastslash = FindCharInString(model, '/', true)+1;
			strcopy(nicemodel, sizeof(nicemodel), model[lastslash]);
			ReplaceString(nicemodel, sizeof(nicemodel), ".mdl", "");
			
			KvGotoFirstSubKey(g_PropNames);
			KvJumpToKey(g_PropNames, "names", false);
			KvGetString(g_PropNames, nicemodel, nicemodel2, sizeof(nicemodel2));
			if (strlen(nicemodel2) > 0)
			strcopy(nicemodel, sizeof(nicemodel), nicemodel2);
			PrintToChat(client, "%t", "#TF_PH_NowDisguised", nicemodel);
		}
		#if defined LOG
				LogMessage("[PH] do equip_4 %N", client);
		#endif
		GetArrayString(g_ModelOffset, RandomInt, offset, sizeof(offset));
		g_PlayerModel[client] = model;
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetVariantString(offset);
		AcceptEntityInput(client, "SetCustomModelOffset");
		SetVariantInt(1);
		AcceptEntityInput(client, "SetCustomModelRotates");
		SwitchView(client, true, false);
		#if defined LOG
				LogMessage("[PH] do equip_5 %N", client);
		#endif
		
		if(!g_inPreRound)
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
	return Plugin_Handled;
}

public Action:Timer_Locked(Handle:timer, any:entity)
{
	for(new client=1; client <= MaxClients; client++)
	{
		if(g_RotLocked[client] && IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_RED)
		{
			SetHudTextParamsEx(0.05, 0.05, 0.7, { /*0,204,255*/ 220, 90, 0, 255}, {0,0,0,0}, 1, 0.2, 0.2, 0.2);
			ShowSyncHudText(client, g_Text4, "PropLock Engaged");
		}
	}
}

public Action:Timer_AntiHack(Handle:timer, any:entity)
{
#if defined ANTIHACK
	if(!g_RoundOver && !g_LastProp)
	{
		decl String:name[64];
		for(new client=1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
			{
				if(GetClientTeam(client) == TEAM_RED && TF2_GetPlayerClass(client) == g_defaultClass[TEAM_RED-2])
				{
					if(GetPlayerWeaponSlot(client, 1) != -1 || GetPlayerWeaponSlot(client, 0) != -1 || GetPlayerWeaponSlot(client, 2) != -1)
					{
						GetClientName(client, name, sizeof(name));
						PrintToChatAll("\x04%t", "#TF_PH_WeaponPunish", name);
						SwitchView(client, false, true);
						//ForcePlayerSuicide(client);
						g_PlayerModel[client] = "";
						Timer_DoEquip(INVALID_HANDLE, client);
						TF2_RemoveAllWeapons(client);
					}
				}
			}
		}
	}
#endif
}

public Action:Timer_Ragdoll(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		new rag = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(rag > MaxClients && IsValidEntity(rag))
		AcceptEntityInput(rag, "Kill");
	}
	return Plugin_Handled;
}

public Action:Timer_Score(Handle:timer, any:entity)
{
	for(new client=1; client <= MaxClients; client++)
	{
#if defined STATS
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_RED)
		{
			AlterScore(client, 2, ScReason_Time, 0);
		}
#endif
		g_TouchingCP[client] = false;
	}
	PrintToChatAll("\x03%t", "#TF_PH_CPBonusRefreshed");
}

public Action:Timer_Start(Handle:timer, any:client)
{
#if defined LOG
	LogMessage("[PH] Timer_Start");
#endif
	g_RoundOver = false;

	for(new client2=1; client2 <= MaxClients; client2++)
	{
		if(IsClientInGame(client2) && IsPlayerAlive(client2))
		{
			SetEntityMoveType(client2, MOVETYPE_WALK);
		}
	}
	PrintToChatAll("%t", "#TF_PH_PyrosReleased");
	PH_EmitSoundToAll("RoundStart", _, _, SNDLEVEL_AIRCRAFT);

	new ent;
	if(g_Doors)
	{
		while ((ent = FindEntityByClassname(ent, "func_door")) != -1)
		{
			AcceptEntityInput(ent, "Open");
		}
	}

	if(g_Relay)
	{
		decl String:name[128];
		while ((ent = FindEntityByClassname(ent, "logic_relay")) != -1)
		{
			GetEntPropString(ent, Prop_Data, "m_iName", name, sizeof(name));
			if(strcmp(name, "hidingover", false) == 0)
			AcceptEntityInput(ent, "Trigger");
		}
	}
	g_TimerStart = INVALID_HANDLE;
	return Plugin_Handled;

}

#if defined CHARGE
public Action:Timer_Charge(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntData(client, g_offsCollisionGroup, COLLISION_GROUP_PLAYER, _, true);
		TF2_SetPlayerClass(client, g_defaultClass[TEAM_RED-2], false);
	}
	return Plugin_Handled;
}
#endif

public Action:Timer_TimeUp(Handle:timer, any:lol)
{
#if defined LOG
	LogMessage("[PH] Time Up");
#endif
	if(!g_RoundOver)
	{
		ForceTeamWin(TEAM_RED);
		g_RoundOver = true;
		g_inPreRound = true;
	}
	g_RoundTimer = INVALID_HANDLE;
	return Plugin_Handled;
}

public Action:Timer_AfterWinPanel(Handle:timer, any:lol)
{
#if defined LOG
	LogMessage("[PH] After Win Panel");
#endif
	StopTimer(g_RoundTimer);
}

public Action:Timer_Unfreeze(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	SetEntityMoveType(client, MOVETYPE_WALK);
	return Plugin_Handled;
}

public Action:Timer_Move(Handle:timer, any:client)
{
	g_AllowedSpawn[client] = false;
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		new rag = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(IsValidEntity(rag))
		AcceptEntityInput(rag, "Kill");
		SetEntityMoveType(client, MOVETYPE_WALK);
		if(GetClientTeam(client) == TEAM_BLUE)
		{
			CreateTimer(0.1, Timer_DoEquipBlu, GetClientUserId(client));
		}
		else
		{
			CreateTimer(0.1, Timer_DoEquip, client);
		}
	}
	return Plugin_Handled;
}
