//  PropHunt by Darkimmortal
//   - GamingMasters.co.uk -

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#define PL_VERSION "1.8"
//--------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------- MAIN PROPHUNT CONFIGURATION -------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------

// Enable for global stats support (.inc file available on request due to potential for cheating and database abuse)
// Default: OFF
//#define STATS

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

#define SOUND_BEGIN "vo/announcer_am_gamestarting04.wav"
#define SOUND_LASTPLAYER "vo/announcer_am_lastmanalive01.wav"
#define SOUND_BONUS "vo/demoman_positivevocalization04.wav"
#define SOUND_INTERNET "vo/pyro_positivevocalization01.wav"
#define SOUND_SNAAAKE "prophunt/snaaake.mp3"
#define SOUND_FOUND "prophunt/found.mp3"
#define SOUND_ONEANDONLY "prophunt/oneandonly.mp3"
#define SOUND_COUNT30 "vo/announcer_begins_30sec.wav"
#define SOUND_COUNT20 "vo/announcer_begins_20sec.wav"
#define SOUND_COUNT10 "vo/announcer_begins_10sec.wav"
#define SOUND_COUNT5 "vo/announcer_begins_5sec.wav"
#define SOUND_COUNT4 "vo/announcer_begins_4sec.wav"
#define SOUND_COUNT3 "vo/announcer_begins_3sec.wav"
#define SOUND_COUNT2 "vo/announcer_begins_2sec.wav"
#define SOUND_COUNT1 "vo/announcer_begins_1sec.wav"
#define SOUND_REMAIN30 "vo/announcer_ends_30sec.wav"
#define SOUND_REMAIN10 "vo/announcer_ends_10sec.wav"
#define SOUND_REMAIN5 "vo/announcer_ends_5sec.wav"
#define SOUND_REMAIN4 "vo/announcer_ends_4sec.wav"
#define SOUND_REMAIN3 "vo/announcer_ends_3sec.wav"
#define SOUND_REMAIN2 "vo/announcer_ends_2sec.wav"
#define SOUND_REMAIN1 "vo/announcer_ends_1sec.wav"
#define SOUND_TIMEADDED1 "vo/announcer_time_awarded.wav"
#define SOUND_TIMEADDED2 "vo/announcer_time_added.wav"
#define SOUND_BUTTON_DISABLED "buttons/button10.wav"
#define SOUND_BUTTON_UNLOCK "buttons/button24.wav"
#define SOUND_BUTTON_LOCK "buttons/button3.wav"

#define FLAMETHROWER "models/weapons/w_models/w_flamethrower.mdl"

#define STATE_WAT -1
#define STATE_IDLE 0
#define STATE_RUNNING 1
#define STATE_SWING 2
#define STATE_CROUCH 3

#define CLASS_BLU TFClass_Pyro
#define CLASS_RED 1
#define PLAYER_ONFIRE (1 << 14)

// Weapon Indexes
#define WEP_SHOTGUN_UNIQUE 199
#define WEP_PISTOL_UNIQUE 209

//Pyro
#define WEP_FIREAXE 2
#define WEP_FIREAXE_UNIQUE 192
#define WEP_SHOTGUNPYRO 12

#define WEP_FLAMETHROWER 21
#define WEP_AXTINGUISHER 38
#define WEP_FLAREGUN 39
#define WEP_BACKBURNER 40
#define WEP_HOMEWRECKER 153
#define WEP_DETONATOR 351

//Heavy
#define WEP_FISTS 5
#define WEP_FISTS_UNIQUE 195
#define WEP_SHOTGUNHEAVY 11
#define WEP_MINIGUN 15
#define WEP_MINIGUN_UNIQUE 202
#define WEP_NATASCHA 41
#define WEP_SANDVICH 42
#define WEP_KGB 43
#define WEP_BRASSBEAST 312
#define WEP_IRONCURTAIN 298
#define WEP_TOMISLAV 424
#define WEP_FAMILYBUSINESS 425

//Demoman
#define WEP_BOTTLE 1
#define WEP_BOTTLE_UNIQUE 191
#define WEP_TARGE 131
#define WEP_EYELANDER 132
#define WEP_PAINTRAIN 154
#define WEP_SKULLCUTTER 172
#define WEP_SCREEN 406

//Sniper
#define WEP_SNIPER 14
#define WEP_SNIPER_UNIQUE 201
#define WEP_SMG 16
#define WEP_SMG_UNIQUE 203
#define WEP_HUNTSMAN 56
#define WEP_JARATE 58
#define WEP_SHIV 171
#define WEP_SYDNEYSLEEPER 230
#define WEP_BARGIN 402
#define WEP_MACHINA 526

//Medic
#define WEP_BONESAW 8
#define WEP_BONESAW_UNIQUE 198
#define WEP_NEEDLEGUN 17
#define WEP_NEEDLEGUN_UNIQUE 204
#define WEP_BLUTSAUGER 36
#define WEP_UBERSAW 37
#define WEP_AMPUTATOR 304
#define WEP_CRUSADERSCROSSBOW 305
#define WEP_VOW 413

//Scout
#define WEP_BAT 0
#define WEP_BAT_UNIQUE 190
#define WEP_SCATTERGUN 13
#define WEP_SCATTERGUN_UNIQUE 200
#define WEP_SCOUTPISTOL 23
#define WEP_SANDMAN 44
#define WEP_FORCEANATURE 45

//Soldier
#define WEP_SHOVEL 6
#define WEP_SHOVEL_UNIQUE 196
#define WEP_SHOTGUNSOLLY 10
#define WEP_ROCKETLAUNCHER 18
#define WEP_ROCKETLAUNCHER_UNIQUE 205
#define WEP_DIRECTHIT 127
#define WEP_EQUALIZER 128
#define WEP_BLACKBOX 228
#define WEP_LIBERTY 414
#define WEP_RESERVE 415
#define WEP_ROCKETLAUNCHER_ORIGINAL 513
#define WEP_COWMANGLER 441

//Engineer
#define WEP_WRENCH 7
#define WEP_WRENCH_UNIQUE 197
#define WEP_SHOTGUNENGINEER 9
#define WEP_ENGINIEERPISTOL 22
#define WEP_FRONTIERJUSTICE 141
#define WEP_LUGERMORPH 160
#define WEP_LUGERMORPH_2 294

#define LOCKVOL 0.7
#define UNBALANCE_LIMIT 1
#define MAXMODELNAME 96
#define TF2_PLAYERCOND_ONFIREALERT    (1<<20)

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
new g_Heavy_count;
new g_Message_blue;
new g_RoundTime = 175;
new g_Message_bit = 0;
new g_iVelocity = -1;
#if defined STATS
new bool:g_MapChanging = false;
new g_StartTime;
#endif

new Handle:g_TimerSound30 = INVALID_HANDLE;
new Handle:g_TimerSound20 = INVALID_HANDLE;
new Handle:g_TimerSound10 = INVALID_HANDLE;
new Handle:g_TimerSound5 = INVALID_HANDLE;
new Handle:g_TimerSound4 = INVALID_HANDLE;
new Handle:g_TimerSound3 = INVALID_HANDLE;
new Handle:g_TimerSound2 = INVALID_HANDLE;
new Handle:g_TimerSound1 = INVALID_HANDLE;
new Handle:g_TimerStart = INVALID_HANDLE;

new bool:g_Doors = false;
new bool:g_Relay = false;
new bool:g_Freeze = true;

new g_oFOV;
new g_oDefFOV;

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
new Handle:g_SelfDamageTrie = INVALID_HANDLE;

new Handle:g_PHEnable = INVALID_HANDLE;
new Handle:g_PHPropMenu = INVALID_HANDLE;
new Handle:g_PHAdmFlag = INVALID_HANDLE;
new Handle:g_PHAdvertisements = INVALID_HANDLE;

new String:g_AdText[128] = "GamingMasters.co.uk";

public Plugin:myinfo =
{
	name = "PropHunt",
	author = "Darkimmortal",
	description = "GamingMasters.co.uk",
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

#endif

public OnPluginStart()
{
	if (!IsPropHuntMap())
		Unload();

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
	g_PHPropMenu = CreateConVar("ph_propmenu", "0", "Control use of the propmenu command: -1 = Disabled, 0 = admin only, 1 = all players");
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
	HookEvent("player_changeclass", Event_player_changeclass);
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

	SoundLoad();
#if defined CHARGE
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
#endif
	LoadTranslations("prophunt.phrases");

	g_oFOV = FindSendPropOffs("CBasePlayer", "m_iFOV");
	g_oDefFOV = FindSendPropOffs("CBasePlayer", "m_iDefaultFOV");

	loadGlobalConfig();
	createTrie();
	

	RegAdminCmd("ph_respawn", Command_respawn, ADMFLAG_ROOT, "Respawns you");
	RegAdminCmd("ph_switch", Command_switch, ADMFLAG_KICK, "Switches to RED");
	RegAdminCmd("ph_internet", Command_internet, ADMFLAG_KICK, "Spams Internet");
	RegAdminCmd("ph_pyro", Command_pyro, ADMFLAG_KICK, "Switches to BLU");
	RegAdminCmd("ph_debug", Command_debug, ADMFLAG_KICK, "");

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
		LogError("Could not load the PropHunt config file!");
}

createTrie()
{
	if (g_ConfigKeyValues == INVALID_HANDLE)
	{
		return;
	}
	if (g_SelfDamageTrie != INVALID_HANDLE)
	{
		CloseHandle(g_SelfDamageTrie);
	}
	
	g_SelfDamageTrie = CreateTrie();
	
	while(KvGoBack(g_ConfigKeyValues))
	{
		continue;
	}
	
	if(KvJumpToKey(g_ConfigKeyValues, "firing_damage"))
	{
		do
		{
			decl String:WeaponName[128];
			KvGotoFirstSubKey(g_ConfigKeyValues);
			KvGetSectionName(g_ConfigKeyValues, WeaponName, sizeof(WeaponName));
			if(KvGetDataType(g_ConfigKeyValues, "self_damage") == KvData_Int)
			{
				SetTrieValue(g_SelfDamageTrie, WeaponName, KvGetNum(g_ConfigKeyValues, "self_damage"));
				LogMessage("[PH] Self-damage for %s set", WeaponName);
			}
			else
			{
				LogMessage("[PH] Invalid data value for %s in the firing_damage config", WeaponName);
			}
		}
		while(KvGotoNextKey(g_ConfigKeyValues));
	}
	else
	{
		LogMessage("[PH] Invalid config! Could not access subkey: firing_damage");
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
	SetConVarInt(FindConVar("tf_arena_preround_time"), IsDedicatedServer() ? 15:5, true);
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
	SetConVarInt(FindConVar("tf_show_voice_icons"), 1, true);
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
		PrintToChat(other, "%t", "cpbonus");
		EmitSoundToClient(other, SOUND_BONUS, _, _, SNDLEVEL_AIRCRAFT);
		g_TouchingCP[other] = true;
	}
}

stock FillHealth (entity){
	switch(TF2_GetPlayerClass(entity))
	{
	case TFClass_Heavy:
		SetEntityHealth(entity, 300);
	case TFClass_Sniper:
		SetEntityHealth(entity, 150);
	case TFClass_Pyro:
		SetEntityHealth(entity, 175);
	case TFClass_Scout:
		SetEntityHealth(entity, 150);
	case TFClass_Soldier:
		SetEntityHealth(entity, 200);
	case TFClass_Engineer:
		{
			if (GetEntProp(GetPlayerWeaponSlot(entity, 2), Prop_Send, "m_iEntityLevel") >= 5)
			{
			SetEntityHealth(entity, 150);
			}
			else
				SetEntityHealth(entity, 125);
		}
	case TFClass_DemoMan:
		SetEntityHealth(entity, 175);
	case TFClass_Spy:
		SetEntityHealth(entity, 125);
	case TFClass_Medic:
		SetEntityHealth(entity, 150);
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


public SoundLoad()
{
	PrecacheSound(SOUND_BEGIN);
	PrecacheSound(SOUND_LASTPLAYER);
	PrecacheSound(SOUND_BONUS);
	PrecacheSound(SOUND_INTERNET);
	PrecacheSound(SOUND_SNAAAKE);
	PrecacheSound(SOUND_FOUND);
	PrecacheSound(SOUND_ONEANDONLY);
	PrecacheSound(SOUND_COUNT30);
	PrecacheSound(SOUND_COUNT20);
	PrecacheSound(SOUND_COUNT10);
	PrecacheSound(SOUND_COUNT5);
	PrecacheSound(SOUND_COUNT4);
	PrecacheSound(SOUND_COUNT3);
	PrecacheSound(SOUND_COUNT2);
	PrecacheSound(SOUND_COUNT1);
	PrecacheSound(SOUND_TIMEADDED1);
	PrecacheSound(SOUND_TIMEADDED2);
	PrecacheSound(SOUND_BUTTON_DISABLED);
	PrecacheSound(SOUND_BUTTON_LOCK);
	PrecacheSound(SOUND_BUTTON_UNLOCK);
}

public OnMapEnd()
{
#if defined STATS
	g_MapChanging = true;
#endif

	// workaround no win panel event - admin changes, rtv, etc.
	g_RoundOver = true;
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

	SoundLoad();

	decl String:model[100];

	for(new i = 0; i < GetArraySize(g_ModelName); i++)
	{
		GetArrayString(g_ModelName, i, model, sizeof(model));
		PrecacheModel(model, true);
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
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
	if (strlen(g_AdText) > 0)
		Format(gameDesc, sizeof(gameDesc), "PropHunt %s (%s)", g_Version, g_AdText);
	else
		Format(gameDesc, sizeof(gameDesc), "PropHunt %s", g_Version);
		
	return Plugin_Changed;
}

public Action:Timer_TimeUp(Handle:timer, any:lol)
{
#if defined LOG
	LogMessage("[PH] Time Up");
#endif
	if(!g_RoundOver)
	{
		ForceTeamWin(TEAM_RED);
		g_RoundOver = true;
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

public OnPluginEnd()
{
	PrintCenterTextAll("%t", "plugin reload");
#if defined STATS
	Stats_Uninit();
#endif
}

public Action:TakeDamageHook(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(client > 0 && attacker > 0 && client < MaxClients && attacker < MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_RED
	   && IsClientInGame(attacker) && GetClientTeam(attacker) == TEAM_BLUE)
	{

		if(!g_Hit[client])
		{
			new Float:pos[3];
			GetClientAbsOrigin(client, pos);
			EmitSoundToClient(client, SOUND_FOUND, _, SNDCHAN_WEAPON, _, _, 0.8, _, client, pos);
			EmitSoundToClient(attacker, SOUND_FOUND, _, SNDCHAN_WEAPON, _, _, 0.8, _, client, pos);
			g_Hit[client] = true;
		}

		if(IsValidEntity(GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon")) )
		{
			switch(GetEntProp(GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon"), Prop_Send, "m_iItemDefinitionIndex"))
			{
				case WEP_DETONATOR:
				{
					damage = FloatMul(damage, 0.95);
				}
				case WEP_HUNTSMAN, WEP_FRONTIERJUSTICE:
				{
				damage = FloatMul(damage, 0.85);
				}
				case WEP_SHOTGUNHEAVY, WEP_SHOTGUNSOLLY, WEP_SHOTGUNENGINEER, WEP_BACKBURNER, WEP_SHOTGUNPYRO, WEP_SHOTGUN_UNIQUE: 
				{
					damage = FloatMul(damage, 0.8);
				}
				case WEP_MINIGUN, WEP_MINIGUN_UNIQUE, WEP_ROCKETLAUNCHER, WEP_ROCKETLAUNCHER_UNIQUE, WEP_DIRECTHIT, WEP_BLACKBOX, WEP_BRASSBEAST, WEP_IRONCURTAIN, WEP_TOMISLAV, WEP_LIBERTY, WEP_SCREEN, WEP_RESERVE, WEP_ROCKETLAUNCHER_ORIGINAL: 
				{
					damage = FloatMul(damage, 0.75);
				}
			}
			return Plugin_Changed;
		}

	}

	//block prop drowning
	if(damagetype == DMG_DROWN && client > 0 && client < MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_RED && attacker == 0)
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
	SetEntPropEnt(target, Prop_Send, "m_hObserverTarget", observer ? target:-1);
	SetEntProp(target, Prop_Send, "m_iObserverMode", observer ? 1:0);
	SetEntData(target, g_oFOV, observer ? 100:GetEntData(target, g_oDefFOV, 4), 4, true);
	SetEntProp(target, Prop_Send, "m_bDrawViewmodel", viewmodel ? 1:0);

	SetVariantBool(observer);
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

public Action:Event_player_team(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetEventInt(event, "team") > 1)
	{
		g_Spec[client] = false;
	}
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

public Action:Command_propmenu(client, args)
{
	if(GetConVarInt(g_PHPropMenu) == 1 || IsValidAdmin(client) && GetConVarInt(g_PHPropMenu) == 0)
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
	case MenuAction_Select:{
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

public Action:Command_debug(client, args)
{
	GetAnimeEnt(client);
	PrintToChat(client, "g_RoundOver = %s", g_RoundOver ? "true":"false");
}

public Action:Command_internet(client, args)
{
	decl String:name[255];
	for(new i = 0; i < 3; i++)
	{
		EmitSoundToAll(SOUND_INTERNET, _, _, SNDLEVEL_AIRCRAFT);
	}
	GetClientName(client, name, sizeof(name));
	return Plugin_Handled;
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
			CreateTimer(0.1, Timer_DoEquipBlu, client);
		}
		else
		{
			CreateTimer(0.1, Timer_DoEquip, client);
		}
	}
	return Plugin_Handled;
}

// much more reliable than an entity index array for cross-round code, since indexes are fucked with between rounds on srcds (only?)
stock GetAnimeEnt (client){
	new client2, ent;
	while(IsValidEntity(ent) && (ent = FindEntityByClassname(ent, "prop_dynamic")) != -1)
	{
		client2 = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if(client2 == client)
		{
			return ent;
		}
	}
	return -1;
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

public Action:Event_arena_win_panel(Handle:event, const String:name[], bool:dontBroadcast)
{
#if defined LOG
	LogMessage("[PH] round end");
#endif
	g_Heavy_count=0;


	g_RoundOver = true;

#if defined STATS
	new winner = GetEventInt(event, "winning_team");
	DbRound(winner);
#endif

	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0, true);

	new team, client;
	for(client=1; client <= MaxClients; client++)
	{
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
			ResetPlayer(client);
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
		PrintToChatAll("%t", "balance blu", cname);
		ChangeClientTeamAlive(client, TEAM_BLUE);
	}
	while(GetTeamClientCount(TEAM_BLUE) > GetTeamClientCount(TEAM_RED) +1 )
	{
		client = GetRandomPlayer(TEAM_BLUE);
		GetClientName(client, cname, sizeof(cname));
		PrintToChatAll("%t", "balance red", cname);
		ChangeClientTeamAlive(client, TEAM_RED);
	}
#if defined LOG
	LogMessage("Complete");
#endif

	SetConVarFlags(FindConVar("mp_teams_unbalance_limit"), GetConVarFlags(FindConVar("mp_teams_unbalance_limit")) & ~(FCVAR_NOTIFY));
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), UNBALANCE_LIMIT, true);

	StopPreroundTimers(false);
}

public StopPreroundTimers(bool:instant)
{
	StopTimer(g_TimerStart);
	StopTimer(g_TimerSound30);
	StopTimer(g_TimerSound20);
	StopTimer(g_TimerSound10);
	StopTimer(g_TimerSound5);
	StopTimer(g_TimerSound4);
	StopTimer(g_TimerSound3);
	StopTimer(g_TimerSound2);
	StopTimer(g_TimerSound1);
	if(instant)
		StopTimer(g_RoundTimer);
	else
		CreateTimer(2.0, Timer_AfterWinPanel);
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
	if(timer != INVALID_HANDLE) CloseHandle(timer);
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
				if(GetClientTeam(client) == TEAM_RED && TF2_GetPlayerClass(client) == TFClass_Scout)
				{
					if(GetPlayerWeaponSlot(client, 1) != -1 || GetPlayerWeaponSlot(client, 0) != -1 || GetPlayerWeaponSlot(client, 2) != -1)
					{
						GetClientName(client, name, sizeof(name));
						PrintToChatAll("\x04%t", "weapon punish", name);
						SwitchView(client, false, true);
						//ForcePlayerSuicide(client);
						TF2_RemoveAllWeapons(client);
					}
				}
			}
		}
	}
#endif
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
	PrintToChatAll("\x03%t", "cpbonus refreshed");
}


public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{

	if(g_RoundOver)
		return Plugin_Continue;

	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_BLUE)
	{
		new damage = 10, damage2 = 10;

		if(GetTrieValue(g_SelfDamageTrie, weaponname, damage2))
			damage = damage2;

		new helf = GetClientHealth(client)-damage;
		if(helf < 1)
			ForcePlayerSuicide(client);
		else
			SetEntityHealth(client, helf);

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

public PreThinkHook(client)
{

	if(IsClientInGame(client))
	{

		if(IsPlayerAlive(client))
		{
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
								EmitSoundToClient(client, SOUND_BUTTON_LOCK, _, _, _, _, LOCKVOL);
#endif
							}

						}
						else
						if(g_RotLocked[client])
						{
							SetVariantInt(1);
							AcceptEntityInput(client, "SetCustomModelRotates");
#if defined LOCKSOUND
							EmitSoundToClient(client, SOUND_BUTTON_UNLOCK, _, _, _, _, LOCKVOL);
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
						TF2_AddCondition(client, TFCond_Charging);
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

#if defined CHARGE
public Action:Timer_Charge(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		g_Charge[client] = false;
		SetEntData(client, g_offsCollisionGroup, COLLISION_GROUP_PLAYER, _, true);
		TF2_SetPlayerClass(client, TFClass_Scout, false);
	}
	return Plugin_Handled;
}
#endif

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
	g_LastProp = false;
	if(g_RoundOver)
	{

		for(new client=1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
			{
				if(GetClientTeam(client) == TEAM_RED)
					Timer_DoEquip(INVALID_HANDLE, client);
				if(GetClientTeam(client) == TEAM_BLUE)
					Timer_DoEquipBlu(INVALID_HANDLE, client);
			}
		}
		
		SetupRoundTime(g_RoundTime);
		
		//GameMode Explanation
		decl String:message[256];
		new ent;
		ent=FindEntityByClassname(-1, "tf_gamerules");

		//BLU
		Format(message, sizeof(message), "%T", "message blu", LANG_SERVER);
		SetVariantString(message);
		AcceptEntityInput(ent, "SetBlueTeamGoalString");
		SetVariantString("2");
		AcceptEntityInput(ent, "SetRedTeamRole");

		//RED
		Format(message, sizeof(message), "%T", "message red", LANG_SERVER);
		SetVariantString(message);
		AcceptEntityInput(ent, "SetRedTeamGoalString");
		SetVariantString("1");
		AcceptEntityInput(ent, "SetRedTeamRole");

		CreateTimer(0.1, Timer_Info);

		g_TimerSound30 = CreateTimer(0.1, Timer_Sound30, _, TIMER_FLAG_NO_MAPCHANGE);
		g_TimerSound20 = CreateTimer(10.0, Timer_Sound20, _, TIMER_FLAG_NO_MAPCHANGE);
		g_TimerSound10 = CreateTimer(20.0, Timer_Sound10, _, TIMER_FLAG_NO_MAPCHANGE);
		g_TimerSound5 = CreateTimer(25.0, Timer_Sound5, _, TIMER_FLAG_NO_MAPCHANGE);
		g_TimerSound4 = CreateTimer(26.0, Timer_Sound4, _, TIMER_FLAG_NO_MAPCHANGE);
		g_TimerSound3 = CreateTimer(27.0, Timer_Sound3, _, TIMER_FLAG_NO_MAPCHANGE);
		g_TimerSound2 = CreateTimer(28.0, Timer_Sound2, _, TIMER_FLAG_NO_MAPCHANGE);
		g_TimerSound1 = CreateTimer(29.0, Timer_Sound1, _, TIMER_FLAG_NO_MAPCHANGE);
		g_TimerStart = CreateTimer(30.0, Timer_Start, _, TIMER_FLAG_NO_MAPCHANGE);
		
#if defined STATS
		g_StartTime = GetTime();
#endif
	}
}

public SetupRoundTime(time)
{
	g_RoundTimer = CreateTimer(float(time-1), Timer_TimeUp, _, TIMER_FLAG_NO_MAPCHANGE);
	SetConVarInt(FindConVar("tf_arena_round_time"), time, true, false);
}

public Action:Timer_Sound30(Handle:timer, any:client)
{
	EmitSoundToAll(SOUND_COUNT30, _, _, SNDLEVEL_AIRCRAFT);
	g_TimerSound30 = INVALID_HANDLE;
	return Plugin_Handled;
}
public Action:Timer_Sound20(Handle:timer, any:client)
{
	EmitSoundToAll(SOUND_COUNT20, _, _, SNDLEVEL_AIRCRAFT);
	g_TimerSound20 = INVALID_HANDLE;
	return Plugin_Handled;
}
public Action:Timer_Sound10(Handle:timer, any:client)
{
	EmitSoundToAll(SOUND_COUNT10, _, _, SNDLEVEL_AIRCRAFT);
	g_TimerSound10 = INVALID_HANDLE;
	return Plugin_Handled;
}
public Action:Timer_Sound5(Handle:timer, any:client)
{
	EmitSoundToAll(SOUND_COUNT5, _, _, SNDLEVEL_AIRCRAFT);
	g_TimerSound5 = INVALID_HANDLE;
	return Plugin_Handled;
}
public Action:Timer_Sound4(Handle:timer, any:client)
{
	EmitSoundToAll(SOUND_COUNT4, _, _, SNDLEVEL_AIRCRAFT);
	g_TimerSound4 = INVALID_HANDLE;
	return Plugin_Handled;
}
public Action:Timer_Sound3(Handle:timer, any:client)
{
	EmitSoundToAll(SOUND_COUNT3, _, _, SNDLEVEL_AIRCRAFT);
	g_TimerSound3 = INVALID_HANDLE;
	return Plugin_Handled;
}
public Action:Timer_Sound2(Handle:timer, any:client)
{
	EmitSoundToAll(SOUND_COUNT2, _, _, SNDLEVEL_AIRCRAFT);
	g_TimerSound2 = INVALID_HANDLE;
	return Plugin_Handled;
}
public Action:Timer_Sound1(Handle:timer, any:client)
{
	EmitSoundToAll(SOUND_COUNT1, _, _, SNDLEVEL_AIRCRAFT);
	g_TimerSound1 = INVALID_HANDLE;
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
				ShowSyncHudText(i, g_Text2, "By Darkimmortal");
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



public Action:Timer_Start(Handle:timer, any:client)
{
#if defined LOG
	LogMessage("[PH] Timer_Start");
#endif
	g_RoundOver = false;

	for(new client2=1; client2 <= MaxClients; client2++)
	{
		if(IsClientInGame(client2) && IsPlayerAlive(client2) && GetClientTeam(client2) == TEAM_BLUE)
		{
			SetEntityMoveType(client2, MOVETYPE_WALK);
		}
	}
	PrintToChatAll("%t", "ready");
	EmitSoundToAll(SOUND_BEGIN, _, _, SNDLEVEL_AIRCRAFT);

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

public Action:Event_player_changeclass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new class = GetEventInt(event, "class");
	if(GetClientTeam(client) == TEAM_BLUE)
	{
		if (TFClassType:class == TFClass_Heavy && g_Heavy_count <= 2)
			g_Heavy_count++;
		else
		if (TFClassType:class == TFClass_Heavy)
		{
			TF2_SetPlayerClass(client, TFClassType:TFClass_Pyro);
			PrintToChat(client, "There are too many Heavies!");
			EmitSoundToClient(client, SOUND_BUTTON_DISABLED);
		}

		if (TF2_GetPlayerClass(client) == TFClass_Heavy)
			g_Heavy_count--;
	}
	return Plugin_Handled;
}

public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"));


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

			PrintToChat(client, "%t", "wait");
#if defined SHINX
			if(TF2_GetPlayerClass(client) != TFClass_Pyro && TF2_GetPlayerClass(client) != TFClass_Heavy && TF2_GetPlayerClass(client) != TFClass_Sniper &&
			   TF2_GetPlayerClass(client) != TFClass_DemoMan && TF2_GetPlayerClass(client) != TFClass_Soldier &&
			   TF2_GetPlayerClass(client) != TFClass_Medic && TF2_GetPlayerClass(client) != TFClass_Engineer)
			{
				TF2_SetPlayerClass(client, TFClassType:TFClass_Pyro);
				TF2_RespawnPlayer(client);
				return Plugin_Continue;
			}
#else
			if(TF2_GetPlayerClass(client) != TFClass_Pyro)
			{
				TF2_SetPlayerClass(client, TFClassType:TFClass_Pyro);
				TF2_RespawnPlayer(client);
				return Plugin_Continue;
			}
#endif
			CreateTimer(0.1, Timer_DoEquipBlu, client);

		}
		else
		if(GetClientTeam(client) == TEAM_RED)
		{
			SetVariantString("");
			AcceptEntityInput(client, "DisableShadow");

			if(_:TF2_GetPlayerClass(client) != CLASS_RED)
			{
				TF2_SetPlayerClass(client, TFClassType:CLASS_RED);
				TF2_RespawnPlayer(client);
				return Plugin_Continue;
			}

		}

	}
	return Plugin_Continue;
}

public Action:Timer_DoEquipBlu(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(g_Freeze)
			SetEntityMoveType(client, MOVETYPE_NONE);

		SwitchView(client, false, true);
		SetAlpha(client, 255);

		new slot0 = GetPlayerWeaponSlot(client, 0);
		new slot1 = GetPlayerWeaponSlot(client, 1);
		new slot2 = GetPlayerWeaponSlot(client, 2);

		if(TF2_GetPlayerClass(client) == TFClass_Sniper)
		{
			if(slot0 > MaxClients && IsValidEntity(slot0) && GetEntProp(slot0, Prop_Send, "m_iItemDefinitionIndex") == WEP_SNIPER 
			|| slot0 > MaxClients && IsValidEntity(slot0) && GetEntProp(slot0, Prop_Send, "m_iItemDefinitionIndex") == WEP_SNIPER_UNIQUE 
			|| slot0 > MaxClients && IsValidEntity(slot0) && GetEntProp(slot0, Prop_Send, "m_iItemDefinitionIndex") == WEP_SYDNEYSLEEPER 
			|| slot0 > MaxClients && IsValidEntity(slot0) && GetEntProp(slot0, Prop_Send, "m_iItemDefinitionIndex") == WEP_BARGIN
			|| slot0 > MaxClients && IsValidEntity(slot0) && GetEntProp(slot0, Prop_Send, "m_iItemDefinitionIndex") == WEP_MACHINA)
			{
				TF2_RemoveWeaponSlot(client, 0);
			}
			if(slot1 > MaxClients && IsValidEntity(slot1) && GetEntProp(slot1, Prop_Send, "m_iItemDefinitionIndex") == WEP_SMG || slot1 > MaxClients && IsValidEntity(slot1) && GetEntProp(slot1, Prop_Send, "m_iItemDefinitionIndex") == WEP_SMG_UNIQUE)
			{
				TF2_RemoveWeaponSlot(client, 1);
			}
		}
		else
		if(TF2_GetPlayerClass(client) == TFClass_Pyro)
		{
			if(slot1 > MaxClients && IsValidEntity(slot1) && GetEntProp(slot1, Prop_Send, "m_iItemDefinitionIndex") == WEP_SHOTGUNPYRO || slot1 > MaxClients && IsValidEntity(slot1) && GetEntProp(slot1, Prop_Send, "m_iItemDefinitionIndex") == WEP_SHOTGUN_UNIQUE)
			{
				SetEntData(GetPlayerWeaponSlot(client, 1), FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), SHOTGUN_MAX_AMMO);
			}
		}
		else
		if(TF2_GetPlayerClass(client) == TFClass_DemoMan)
		{
			TF2_RemoveWeaponSlot(client, 0);
			TF2_RemoveWeaponSlot(client, 1);
		}
		else
		if(TF2_GetPlayerClass(client) == TFClass_Heavy)
		{
			if(slot0 > MaxClients && IsValidEntity(slot0) && GetEntProp(slot0, Prop_Send, "m_iItemDefinitionIndex") == WEP_NATASCHA)
			{
				TF2_RemoveWeaponSlot(client, 0);
			}
			if(slot1 > MaxClients && IsValidEntity(slot1) && GetEntProp(slot1, Prop_Send, "m_iItemDefinitionIndex") == WEP_FAMILYBUSINESS)
			{
				TF2_RemoveWeaponSlot(client, 1);
			}
		}
		else
		if(TF2_GetPlayerClass(client) == TFClass_Medic)
		{
			if(slot0 > MaxClients && IsValidEntity(slot0) && GetEntProp(slot0, Prop_Send, "m_iItemDefinitionIndex") == WEP_BLUTSAUGER)
			{
				TF2_RemoveWeaponSlot(client, 0);
			}
			if(slot0 > MaxClients && IsValidEntity(slot0) && GetEntProp(slot0, Prop_Send, "m_iItemDefinitionIndex") == WEP_CRUSADERSCROSSBOW)
			{
				TF2_RemoveWeaponSlot(client, 0);
			}
			if(slot2 > MaxClients && IsValidEntity(slot2) && GetEntProp(slot2, Prop_Send, "m_iItemDefinitionIndex") == WEP_AMPUTATOR || slot2 > MaxClients && IsValidEntity(slot2) && GetEntProp(slot2, Prop_Send, "m_iItemDefinitionIndex") == WEP_VOW)
			{
				TF2_RemoveWeaponSlot(client, 2);
			}
			TF2_RemoveWeaponSlot(client, 1);
		}
		else
		if(TF2_GetPlayerClass(client) == TFClass_Engineer)
		{
			if(slot1 > MaxClients && IsValidEntity(slot1) && GetEntProp(slot1, Prop_Send, "m_iItemDefinitionIndex") == WEP_LUGERMORPH || slot1 > MaxClients && IsValidEntity(slot1) && GetEntProp(slot1, Prop_Send, "m_iItemDefinitionIndex") == WEP_ENGINIEERPISTOL || slot1 > MaxClients && IsValidEntity(slot1) && GetEntProp(slot1, Prop_Send, "m_iItemDefinitionIndex") == WEP_PISTOL_UNIQUE || slot1 > MaxClients && IsValidEntity(slot1) && GetEntProp(slot1, Prop_Send, "m_iItemDefinitionIndex") == WEP_LUGERMORPH_2)
			{
				TF2_RemoveWeaponSlot(client, 1);
			}
		}
		else
		if(TF2_GetPlayerClass(client) == TFClass_Soldier)
		{
			if(slot0 > MaxClients && IsValidEntity(slot0) && GetEntProp(slot0, Prop_Send, "m_iItemDefinitionIndex") == WEP_COWMANGLER )
			{
				TF2_RemoveWeaponSlot(client, 0);
			}
		}
	}
	return Plugin_Handled;
}

public Action:Command_motd(client, args)
{
	if(IsClientInGame(client))
	{
		ShowMOTDPanel(client, "PropHunt Stats", "http://www.gamingmasters.co.uk/prophunt/index.php", MOTDPANEL_TYPE_URL);
	}
	return Plugin_Handled;
}

public Action:Timer_DoEquip(Handle:timer, any:client)
{

	if(IsClientInGame(client))
	{
#if defined LOG
		LogMessage("[PH] do equip %N", client);
#endif
		// slot commands fix "remember last weapon" glitch, despite their client console spam
		FakeClientCommand(client, "slot0");
		FakeClientCommand(client, "slot3");
		TF2_RemoveAllWeapons(client);
		FakeClientCommand(client, "slot3");
		FakeClientCommand(client, "slot0");
	}

	if(IsClientInGame(client) && IsPlayerAlive(client))
	{

		decl String:pname[32];
		Format(pname, sizeof(pname), "ph_player_%i", client);
		DispatchKeyValue(client, "targetname", pname);

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
		decl String:nicemodel[MAXMODELNAME], String:nicemodel2[MAXMODELNAME];
		
		new lastslash = FindCharInString(model, '/', true)+1;
		strcopy(nicemodel, sizeof(nicemodel), model[lastslash]);
		ReplaceString(nicemodel, sizeof(nicemodel), ".mdl", "");
		
		KvGotoFirstSubKey(g_PropNames);
		KvJumpToKey(g_PropNames, "names", false);
		KvGetString(g_PropNames, nicemodel, nicemodel2, sizeof(nicemodel2));
		if (strlen(nicemodel2) > 0)
			strcopy(nicemodel, sizeof(nicemodel), nicemodel2);
		PrintToChat(client, "%t", "now disguised", nicemodel);
		GetArrayString(g_ModelOffset, RandomInt, offset, sizeof(offset));
		g_PlayerModel[client] = model;
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetVariantString(offset);
		AcceptEntityInput(client, "SetCustomModelOffset");
		SetVariantInt(1);
		AcceptEntityInput(client, "SetCustomModelRotates");
		SwitchView(client, true, false);
	}
	return Plugin_Handled;
}

stock SetAlpha (target, alpha){
	SetWeaponsAlpha(target,alpha);
	SetEntityRenderMode(target, RENDER_TRANSCOLOR);
	SetEntityRenderColor(target, 255, 255, 255, alpha);
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

		EmitSoundToClient(client, SOUND_SNAAAKE);
	}

	if(!g_RoundOver)
	{
		if(client > 0 && attacker > 0 && IsClientInGame(client) && IsClientInGame(attacker) && client != attacker)
		{
			if(GetClientTeam(client) == GetClientTeam(attacker))
			{
			}
			else
			{
#if defined STATS
				PlayerKilled(clientID, attackerID, assisterID, weaponid, weapon);
#endif
				if(IsPlayerAlive(attacker))
				{
					Speedup(attacker, 50);
					FillHealth(attacker);
				}
			}
			if(assister > 0 && IsClientInGame(assister))
			{
				if(IsPlayerAlive(assister))
				{
					Speedup(assister, 50);
					FillHealth(assister);
				}
			}
		}
	}

	if(playas == 2 && !g_RoundOver && GetClientTeam(client) == TEAM_RED)
	{
		g_LastProp = true;
		EmitSoundToAll(SOUND_ONEANDONLY, _, _, SNDLEVEL_AIRCRAFT);
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

public Action:Timer_WeaponAlpha(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
		SetWeaponsAlpha(client, 0);
}

stock Speedup (client, inc){
	new Float:speed = GetEntDataFloat(client, FindSendPropInfo("CTFPlayer", "m_flMaxspeed")) + inc;
	if(speed > 400) speed = 400.0;
	SetEntDataFloat(client, FindSendPropInfo("CTFPlayer", "m_flMaxspeed"), speed);
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	return entity != data;
}