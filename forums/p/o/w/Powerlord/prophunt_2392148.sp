/**
 * vim: set ts=4 :
 * =============================================================================
 * TF2 PropHunt Redux
 * Hide as a prop from the evil Pyro menace... or hunt down the hidden prop scum
 * 
 * TF2 PropHunt (C)2007-2014 Darkimmortal.  All rights reserved.
 * TF2 PropHunt Redux (C)2013-2014 Powerlord (Ross Bemrose).  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: 3.4.0
 */
// PropHunt Redux by Powerlord
//         Based on
//  PropHunt by Darkimmortal
//   - GamingMasters.org -

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2items>
#include "morecolors.inc"

#undef REQUIRE_EXTENSIONS
#include <steamtools>
#include <SteamWorks>

#undef REQUIRE_PLUGIN
#include <updater>

#define REQUIRE_EXTENSIONS
#define REQUIRE_PLUGIN

#if !defined SNDCHAN_VOICE2
#define SNDCHAN_VOICE2 7
#endif

// This should be defined by SourceMod, but isn't.
#define ADMFLAG_NONE 0

#define MAXLANGUAGECODE 4

#define PL_VERSION "3.4.0.0 beta 3"

// sv_tags has a 255 limit
#define SV_TAGS_SIZE 255 

//--------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------- MAIN PROPHUNT CONFIGURATION -------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------

// Enable for global stats support (.inc file available on request due to potential for cheating and database abuse)
// Default: OFF
//#define STATS

// GM only stuff
//#define GM
 
#if defined GM
#define SELECTOR_PORTS "27019,27301"
#include <selector>
#endif

// Include support for Workshop maps
// Requires SourceMod 1.8 or later
// Default: ON
#define WORKSHOP_SUPPORT

// Include support for Opt-In MultiMod
// Default: OFF
//#define OIMM

// Include support for switching teams using gamedata
// You only really want to disable this if team switchs aren't working (i.e. gamedata hasn't yet been updated)
// Default: ON
#define SWITCH_TEAMS

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
#define LOG

// Allow props to Targe Charge with enemy collisions disabled by pressing reload - pretty shit tbh.
// Default: OFF
//#define CHARGE

// Max ammo in Pyro shotgun
// Default: 2
#define SHOTGUN_MAX_AMMO 2

// Deprecated and switched to ph_antihack cvar
// Anti-exploit system
// Default: ON
//#define ANTIHACK

// How long after a prop damages a Pyro should the they be credited for damaging them?
// Only applies during Last Prop mode and if a pyro kills themselves
// Default: 5
#define PROP_DAMAGE_TIME 5

// How many seconds before the round changes should teams be switched?
// Lowest possible setting is 0.1 due to how SourceMod timers work internally.
// Setting this lower than 0.2 may cause issues with some servers for the same issue as above.
// Default: 0.2
#define TEAM_CHANGE_TIME 0.2

// Minimum and maximum setup times
#define SETUP_MIN 30
#define SETUP_MAX 120

// "Production" URL (3.3 branch)
//#define UPDATE_URL "http://tf2.rbemrose.com/sourcemod/prophunt/prophunt.txt"

// "Dev" URL (3.4 branch)
#define UPDATE_URL "http://tf2.rbemrose.com/sourcemod/prophunt/dev/prophunt.txt"

//--------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------

#if defined OIMM
#include <optin_multimod>
#endif 

// Needed for stats2.inc compatibility
#define TEAM_BLUE _:TFTeam_Blue
#define TEAM_RED _:TFTeam_Red
#define TEAM_SPEC _:TFTeam_Spectator
#define TEAM_UNASSIGNED _:TFTeam_Unassigned

#define TEAM_PROP TEAM_RED
#define TEAM_HUNTER TEAM_BLUE

#define FLAMETHROWER "models/weapons/w_models/w_flamethrower.mdl"

#define STATE_WAT -1
#define STATE_IDLE 0
#define STATE_RUNNING 1
#define STATE_SWING 2
#define STATE_CROUCH 3

// Not sure what this is for, but pretty sure it's wrong.. player conditions are no longer defined like this
#define PLAYER_ONFIRE (1 << 14)

// Weapon Indexes
#define WEP_SHOTGUN_UNIQUE 199

//Pyro
#define WEP_SHOTGUNPYRO 12

#define WEP_PHLOGISTINATOR 594

#define LOCKVOL 0.7
#define UNBALANCE_LIMIT 1
#define MAXMODELNAME 96
// Not sure what this is for, but pretty sure it's wrong.. player conditions are no longer defined like this
#define TF2_PLAYERCOND_ONFIREALERT    (1<<20)

#define IN_MOVEMENT IN_MOVELEFT | IN_MOVERIGHT | IN_FORWARD | IN_BACK | IN_JUMP

#define TIMER_NAME "prop_hunt_timer"

enum
{
	Item_Classname,
	Item_Index,
	Item_Quality,
	Item_Level,
	Item_Attributes,
}

enum ScReason
{
	ScReason_TeamWin = 0,
	ScReason_TeamLose,
	ScReason_Death,
	ScReason_Kill,
	ScReason_Time,
	ScReason_Friendly
};

enum PropData
{
	String:PropData_Name[MAXMODELNAME],
	String:PropData_Offset[32], // 3 digits, plus 2 spaces, plus a null terminator
	String:PropData_Rotation[32], // 3 digits, plus 2 spaces, plus a null terminator
}

enum RoundChange
{
	RoundChange_NoChange,
	RoundChange_Enable,
	RoundChange_Disable,
}

enum
{
	ScoreData_Captures,
	ScoreData_Defenses,
	ScoreData_Kills,
	ScoreData_Deaths,
	ScoreData_Suicides,
	ScoreData_Dominations,
	ScoreData_Revenge,
	ScoreData_BuildingsBuilt,
	ScoreData_BuildingsDestroyed,
	ScoreData_Headshots,
	ScoreData_Backstabs,
	ScoreData_HealPoints,
	ScoreData_Invulns,
	ScoreData_Teleports,
	ScoreData_DamageDone,
	ScoreData_Crits,
	ScoreData_ResupplyPoints,
	ScoreData_KillAssists,
	ScoreData_BonusPoints,
	ScoreData_Points
}

enum
{
	TFClassBits_None = 0,
	TFClassBits_Scout = (1 << 0), // 1
	TFClassBits_Sniper = (1 << 1), // 2
	TFClassBits_Soldier = (1 << 2), // 4
	TFClassBits_DemoMan = (1 << 3), // 8
	TFClassBits_Medic = (1 << 4), // 16
	TFClassBits_Heavy = (1 << 5), // 32
	TFClassBits_Pyro = (1 << 6), // 64
	TFClassBits_Spy = (1 << 7), // 128
	TFClassBits_Engineer = (1 << 8) // 256
}

new bool:g_RoundOver = true;
new bool:g_inSetup = false;
new bool:g_inPreRound = true;
new bool:g_PlayerDied = false;
new Float:g_flRoundStart = 0.0;

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
new String:g_PlayerModel[MAXPLAYERS+1][PLATFORM_MAX_PATH];

new String:g_Mapname[PLATFORM_MAX_PATH];
new String:g_ServerIP[32];
new String:g_Version[16];

new g_Message_red;
new g_Message_blue;
new g_RoundTime = 175;
new g_Message_bit = 0;
new g_Setup = 0;
//new g_iVelocity = -1;

#if defined STATS
new bool:g_MapChanging = false;
new g_StartTime;
#endif

//new Handle:g_TimerStart = INVALID_HANDLE;
new	Handle:g_Sounds = INVALID_HANDLE;
new Handle:g_BroadcastSounds = INVALID_HANDLE;

new bool:g_Doors = false;
new bool:g_Relay = false;
new bool:g_Freeze = true;

//new bool:g_weaponRemovals[MAXITEMS];
//new Float:g_weaponNerfs[MAXITEMS];
//new Float:g_weaponSelfDamage[MAXITEMS];

new Handle:g_hWeaponRemovals;
new Handle:g_hPropWeaponRemovals;
new Handle:g_hWeaponNerfs;
new Handle:g_hWeaponSelfDamage;
new Handle:g_hWeaponStripAttribs;
new Handle:g_hWeaponAddAttribs;
new Handle:g_hWeaponReplacements;
new Handle:g_hWeaponReplacementPlayerClasses;

new g_classLimits[2][10];
new TFClassType:g_defaultClass[2];
new Float:g_classSpeeds[10][3]; //0 - Base speed, 1 - Max Speed, 2 - Increment Value
new Float:g_currentSpeed[MAXPLAYERS+1];

//new g_oFOV;
//new g_oDefFOV;

new Handle:g_PropData;
// Multi-language support
new Handle:g_ModelLanguages;
new Handle:g_PropNames;
new Handle:g_PropNamesIndex;

new Handle:g_ConfigKeyValues;
new Handle:g_ModelName;
new Handle:g_ModelOffset;
new Handle:g_ModelRotation;
new Handle:g_ModelSkin;
new Handle:g_Text1;
new Handle:g_Text2;
new Handle:g_Text3;
new Handle:g_Text4;

// PropHunt Redux Menus
//new Handle:g_RoundTimer = INVALID_HANDLE;
new Handle:g_PropMenu;
new Handle:g_ConfigMenu;

// PropHunt Redux CVars
new Handle:g_PHEnable;
new Handle:g_PHPropMenu;
new Handle:g_PHPropMenuRestrict;
new Handle:g_PHAdvertisements;
new Handle:g_PHPreventFallDamage;
new Handle:g_PHGameDescription;
new Handle:g_PHAirblast;
new Handle:g_PHAntiHack;
new Handle:g_PHReroll;
new Handle:g_PHStaticPropInfo;
new Handle:g_PHSetupLength;
new Handle:g_PHDamageBlocksPropChange;
new Handle:g_PHPropMenuNames;
new Handle:g_PHMultilingual;
new Handle:g_PHRespawnDuringSetup;
new Handle:g_PHUseUpdater;
new Handle:g_PHAllowTaunts;

new String:g_AdText[128] = "";

new bool:g_MapStarted = false;

// Track optional dependencies
new bool:g_SteamTools = false;
new bool:g_SteamWorks = false;
new bool:g_Updater = false;

#if defined OIMM
new bool:g_OptinMultiMod = false;
#endif

new bool:g_Enabled = true;

// Timers
new Handle:g_hAntiHack;
new Handle:g_hLocked;
new Handle:g_hScore;

// Valve CVars we're going to save and adjust
new Handle:g_hArenaRoundTime;
new g_ArenaRoundTime;
new Handle:g_hWeaponCriticals;
new g_WeaponCriticals;
new Handle:g_hIdledealmethod;
new g_Idledealmethod;
new Handle:g_hTournamentStopwatch;
new g_TournamentStopwatch;
new Handle:g_hTournamentHideDominationIcons;
new g_TournamentHideDominationIcons;
new Handle:g_hFriendlyfire;
new g_Friendlyfire;
new Handle:g_hGravity;
new g_Gravity;
new Handle:g_hForcecamera;
new g_Forcecamera;
new Handle:g_hArenaCapEnableTime;
new g_ArenaCapEnableTime;
new Handle:g_hTeamsUnbalanceLimit;
new g_TeamsUnbalanceLimit;
new Handle:g_hArenaMaxStreak;
new g_ArenaMaxStreak;
new Handle:g_hEnableRoundWaitTime;
new g_EnableRoundWaitTime;
new Handle:g_hWaitingForPlayerTime;
new g_WaitingForPlayerTime;
new Handle:g_hArenaUseQueue;
new bool:g_ArenaUseQueue;
new Handle:g_hShowVoiceIcons;
new g_ShowVoiceIcons;
new Handle:g_hSolidObjects;
new g_SolidObjects;
new Handle:g_hArenaPreroundTime;
new g_ArenaPreroundTime;
new Handle:g_hArenaFirstBlood;
new bool:g_ArenaFirstBlood;

new Handle:g_hWeaponDropTime;
new g_WeaponDropTime;

// Regular convars
#if !defined SWITCH_TEAMS
new Handle:g_hBonusRoundTime;
#endif
new Handle:g_hTags;


new g_Replacements[MAXPLAYERS+1][6];
new g_ReplacementCount[MAXPLAYERS+1];
new bool:g_bRegenerated[MAXPLAYERS+1];
new bool:g_Rerolled[MAXPLAYERS+1] = { false, ... };

new bool:g_CvarsSet;

new RoundChange:g_RoundChange;

new bool:g_CurrentlyFlaming[MAXPLAYERS+1];
new g_FlameCount[MAXPLAYERS+1];
#define FLY_COUNT 3

new g_LastPropDamageTime[MAXPLAYERS+1] = { -1, ... };
new g_LastPropPlayer = 0;

new bool:g_PHMap;

new bool:g_RoundStartMessageSent[MAXPLAYERS+1];

// Multi-round support
new g_RoundCount = 0;
new g_RoundCurrent = 0;
new g_RoundSwitchAlways = false;

// New override support for propmenu and stuff
new g_PropMenuOldFlags = 0;
new bool:g_PropMenuOverrideInstalled = false;
new g_PropRerollOldFlags = 0;
new bool:g_PropRerollOverrideInstalled = false;

new g_GameRulesProxy = INVALID_ENT_REFERENCE;

#if defined SHINX
new TFClassType:g_PreferredHunterClass[MAXPLAYERS+1] = { TFClass_Unknown, ... };
#endif

public Plugin:myinfo =
{
	name = "PropHunt Redux",
	author = "Darkimmortal, Geit, and Powerlord",
	description = "Hide as a prop from the evil Pyro menace... or hunt down the hidden prop scum",
	version = PL_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=228086"
}

// Updated in Prophunt Redux from Source SDK 2013's const.h
// https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/public/const.h
enum
{
	COLLISION_GROUP_NONE  = 0,
	COLLISION_GROUP_DEBRIS,			// Collides with nothing but world and static stuff
	COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
	COLLISION_GROUP_INTERACTIVE_DEBRIS,	// Collides with everything except other interactive debris or debris
	COLLISION_GROUP_INTERACTIVE,	// Collides with everything except interactive debris or debris
	COLLISION_GROUP_PLAYER,
	COLLISION_GROUP_BREAKABLE_GLASS,
	COLLISION_GROUP_VEHICLE,
	COLLISION_GROUP_PLAYER_MOVEMENT,  // For HL2, same as Collision_Group_Player, for
										// TF2, this filters out other players and CBaseObjects
	COLLISION_GROUP_NPC,			// Generic NPC group
	COLLISION_GROUP_IN_VEHICLE,		// for any entity inside a vehicle
	COLLISION_GROUP_WEAPON,			// for any weapons that need collision detection
	COLLISION_GROUP_VEHICLE_CLIP,	// vehicle clip brush to restrict vehicle movement
	COLLISION_GROUP_PROJECTILE,		// Projectiles!
	COLLISION_GROUP_DOOR_BLOCKER,	// Blocks entities not permitted to get near moving doors
	COLLISION_GROUP_PASSABLE_DOOR,	// Doors that the player shouldn't collide with
	COLLISION_GROUP_DISSOLVING,		// Things that are dissolving are in this group
	COLLISION_GROUP_PUSHAWAY,		// Nonsolid on client and server, pushaway in player code

	COLLISION_GROUP_NPC_ACTOR,		// Used so NPCs in scripts ignore the player.
	COLLISION_GROUP_NPC_SCRIPTED,	// USed for NPCs in scripts that should not collide with each other

	LAST_SHARED_COLLISION_GROUP
}

enum
{
	SOLID_NONE			= 0,	// no solid model
	SOLID_BSP			= 1,	// a BSP tree
	SOLID_BBOX			= 2,	// an AABB
	SOLID_OBB			= 3,	// an OBB (not implemented yet)
	SOLID_OBB_YAW		= 4,	// an OBB, constrained so that it can only yaw
	SOLID_CUSTOM		= 5,	// Always call into the entity for tests
	SOLID_VPHYSICS		= 6,	// solid vphysics object, get vcollide from the model and collide with that
	SOLID_LAST,
};

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

new Handle:g_hSwitchTeams;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		strcopy(error, err_max, "PropHunt Redux only works on Team Fortress 2.");
		return APLRes_Failure;
	}
	
	// This SHOULD be done in steamtools.inc, but isn't.
	MarkNativeAsOptional("Steam_SetGameDescription");

#if defined WORKSHOP_SUPPORT	
	// Part of SM 1.8
	MarkNativeAsOptional("GetMapDisplayName");
#endif

	/*
	CreateNative("PropHuntRedux_ValidateMap", Native_ValidateMap);
	CreateNative("PropHuntRedux_IsRunning", Native_IsRunning);
	CreateNative("PropHuntRedux_GetPropModel", Native_GetModel);
	CreateNative("PropHuntRedux_GetPropModelName", Native_GetModelName);
	
	RegPluginLibrary("prophuntredux");
	*/

	return APLRes_Success;
}

public OnPluginStart()
{
	new Handle:gc;
	
#if defined SWITCH_TEAMS
	gc = LoadGameConfigFile("tf2-switch-teams");
	
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(gc, SDKConf_Virtual, "CTFGameRules::SetSwitchTeams");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	g_hSwitchTeams = EndPrepSDKCall();
	
#if defined LOG
	LogMessage("[PH] Created call to SetSwitchTeams at vtable offset %d", GameConfGetOffset(gc, "CTFGameRules::SetSwitchTeams"));
#endif
	
	CloseHandle(gc);
#endif	
	decl String:hostname[255], String:ip[32], String:port[8]; //, String:map[92];
	GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));
	GetConVarString(FindConVar("ip"), ip, sizeof(ip));
	GetConVarString(FindConVar("hostport"), port, sizeof(port));

	Format(g_ServerIP, sizeof(g_ServerIP), "%s:%s", ip, port);

	new bool:statsbool = false;
#if defined STATS
	statsbool = true;
#endif

	g_hWeaponRemovals = CreateArray();
	g_hPropWeaponRemovals = CreateArray();
	g_hWeaponNerfs = CreateTrie();
	g_hWeaponSelfDamage = CreateTrie();
	g_hWeaponStripAttribs = CreateArray();
	g_hWeaponAddAttribs = CreateTrie();
	g_hWeaponReplacements = CreateTrie();
	g_hWeaponReplacementPlayerClasses = CreateTrie();
	
	Format(g_Version, sizeof(g_Version), "%s%s", PL_VERSION, statsbool ? "s":"");
	// PropHunt Redux now lies and pretends to be PropHunt as well
	CreateConVar("sm_prophunt_version", g_Version, "PropHunt Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	CreateConVar("prophunt_redux_version", g_Version, "PropHunt Redux Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_PHEnable = CreateConVar("ph_enable", "1", "Enables the plugin", FCVAR_DONTRECORD);
	g_PHPropMenu = CreateConVar("ph_propmenu", "0", "Control use of the propmenu command: -1 = Disabled, 0 = admins or people with the propmenu override, 1 = all players", _, true, -1.0, true, 1.0);
	g_PHPropMenuRestrict = CreateConVar("ph_propmenurestrict", "0", "If ph_propmenu is allowed, restrict typed props to the propmenu list?  Defaults to 0 (no).", _, true, 0.0, true, 1.0);
	g_PHAdvertisements = CreateConVar("ph_adtext", g_AdText, "Controls the text used for Advertisements");
	g_PHPreventFallDamage = CreateConVar("ph_preventfalldamage", "0", "Set to 1 to prevent fall damage.  Will use TF2Attributes if available due to client prediction", _, true, 0.0, true, 1.0);
	g_PHGameDescription = CreateConVar("ph_gamedescription", "1", "If SteamTools/SteamWorks is loaded, set the Game Description to PropHunt Redux?", _, true, 0.0, true, 1.0);
	g_PHAirblast = CreateConVar("ph_airblast", "0", "Allow Pyros to airblast? Takes effect on round change unless TF2Attributes is installed.", _, true, 0.0, true, 1.0);
	g_PHAntiHack = CreateConVar("ph_antihack", "1", "Make sure props don't have weapons. Leave this on unless you're having issues with other plugins.", _, true, 0.0, true, 1.0);
	g_PHReroll = CreateConVar("ph_propreroll", "0", "Control use of the propreroll command: -1 = Disabled, 0 = admins or people with the propreroll override, 1 = all players", _, true, -1.0, true, 1.0);
	g_PHStaticPropInfo = CreateConVar("ph_staticpropinfo", "1", "Kick players who have r_staticpropinfo set to 1?", _, true, 0.0, true, 1.0);
	g_PHSetupLength = CreateConVar("ph_setuplength", "30", "Amount of setup time in seconds.", _, true, float(SETUP_MIN), true, float(SETUP_MAX));
	g_PHDamageBlocksPropChange = CreateConVar("ph_burningblockspropchange", "1", "Block Prop Change while players are bleeding, jarated, or on fire? (Fixes bugs)", _, true, 0.0, true, 1.0);
	g_PHPropMenuNames = CreateConVar("ph_propmenuusenames", "0", "Use names for Prop Menu? This is disabled by default for compatibility reasons.", _, true, 0.0, true, 1.0);
	g_PHMultilingual = CreateConVar("ph_multilingual", "0", "Use multilingual support? Uses more Handles if enabled. Disabled by default as we have no alternate languages (yet)", _, true, 0.0, true, 1.0);
	g_PHRespawnDuringSetup = CreateConVar("ph_respawnduringsetup", "1", "If a player dies during setup, should we respawn them?", _, true, 0.0, true, 1.0);
	g_PHUseUpdater = CreateConVar("ph_useupdater", "1", "Use Updater to keep PropHunt Redux up to date? Only applies if the Updater plugin is installed.", _, true, 0.0, true, 1.0);
	g_PHAllowTaunts = CreateConVar("ph_allowproptaunts", "0", "Allow props to use taunt items", _, true, 0.0, true, 1.0);
	
	// These are expensive and should be done just once at plugin start.
	g_hArenaRoundTime = FindConVar("tf_arena_round_time");
	g_hWeaponCriticals = FindConVar("tf_weapon_criticals");
	g_hIdledealmethod = FindConVar("mp_idledealmethod");
	g_hTournamentStopwatch = FindConVar("mp_tournament_stopwatch");
	g_hTournamentHideDominationIcons = FindConVar("tf_tournament_hide_domination_icons");
	g_hFriendlyfire = FindConVar("mp_friendlyfire");
	g_hGravity = FindConVar("sv_gravity");
	g_hForcecamera = FindConVar("mp_forcecamera");
	g_hArenaCapEnableTime = FindConVar("tf_arena_override_cap_enable_time");
	g_hTeamsUnbalanceLimit = FindConVar("mp_teams_unbalance_limit");
	g_hArenaMaxStreak = FindConVar("tf_arena_max_streak");
	g_hEnableRoundWaitTime = FindConVar("mp_enableroundwaittime");
	g_hWaitingForPlayerTime = FindConVar("mp_waitingforplayers_time");
	g_hArenaUseQueue = FindConVar("tf_arena_use_queue");
	g_hShowVoiceIcons = FindConVar("mp_show_voice_icons");
	g_hSolidObjects = FindConVar("tf_solidobjects");
	g_hArenaPreroundTime = FindConVar("tf_arena_preround_time");
	g_hArenaFirstBlood = FindConVar("tf_arena_first_blood");
	
	g_hWeaponDropTime = FindConVar("tf_dropped_weapon_lifetime");
	
#if !defined SWITCH_TEAMS
	g_hBonusRoundTime = FindConVar("mp_bonusroundtime");
#endif

	g_hTags = FindConVar("sv_tags");
	
	HookConVarChange(g_PHEnable, OnEnabledChanged);
	HookConVarChange(g_PHAdvertisements, OnAdTextChanged);
	HookConVarChange(g_PHGameDescription, OnGameDescriptionChanged);
	HookConVarChange(g_PHAntiHack, OnAntiHackChanged);
	HookConVarChange(g_PHStaticPropInfo, OnAntiHackChanged);
	HookConVarChange(g_PHPropMenu, OnPropMenuChanged);
	HookConVarChange(g_PHReroll, OnPropRerollChanged);
	HookConVarChange(g_PHMultilingual, OnMultilingualChanged);
	HookConVarChange(g_PHUseUpdater, OnUseUpdaterChanged);

	g_Text1 = CreateHudSynchronizer();
	g_Text2 = CreateHudSynchronizer();
	g_Text3 = CreateHudSynchronizer();
	g_Text4 = CreateHudSynchronizer();

	AddServerTag("PropHunt");

	// Events
	HookEvent("player_spawn", Event_player_spawn);
	HookEvent("player_team", Event_player_team);
	HookEvent("player_death", Event_player_death, EventHookMode_Pre);
	HookEvent("arena_round_start", Event_arena_round_start);
	HookEvent("arena_win_panel", Event_arena_win_panel);
	HookEvent("post_inventory_application", Event_post_inventory_application);
	HookEvent("teamplay_broadcast_audio", Event_teamplay_broadcast_audio, EventHookMode_Pre);
	HookEvent("teamplay_round_start", Event_teamplay_round_start_pre, EventHookMode_Pre);
	HookEvent("teamplay_round_start", Event_teamplay_round_start);
	HookEvent("teamplay_restart_round", Event_teamplay_restart_round);
	//HookEvent("teamplay_setup_finished", Event_teamplay_setup_finished); // No longer used since 2.0.3 or so because of issues with certain maps

#if defined STATS
	Stats_Init();
#endif

	RegConsoleCmd("help", Command_motd);
	RegConsoleCmd("phstats", Command_motd);
	RegConsoleCmd("ph_stats", Command_motd);
	RegConsoleCmd("ph_config", Command_config);
	RegConsoleCmd("ph_settings", Command_config);
	//RegConsoleCmd("motd", Command_motd);
	RegAdminCmd("propmenu", Command_propmenu, ADMFLAG_KICK, "Select a new prop from the prop menu if allowed.");
	RegAdminCmd("propreroll", Command_propreroll, ADMFLAG_KICK, "Change your prop. Useable once per round if allowed.");

	// These are now parsed from the config file itself.
	//AddFileToDownloadsTable("sound/prophunt/found.mp3");
	//AddFileToDownloadsTable("sound/prophunt/snaaake.mp3");
	//AddFileToDownloadsTable("sound/prophunt/oneandonly.mp3");
	
	LoadTranslations("prophunt.phrases");
	LoadTranslations("common.phrases");
 
	g_Sounds = CreateTrie();
	g_BroadcastSounds = CreateTrie();
	
	// Don't do this at plugin start, but on configs executed
	//loadGlobalConfig();
	
	RegAdminCmd("ph_respawn", Command_respawn, ADMFLAG_ROOT, "Respawns you");
	RegAdminCmd("ph_switch", Command_switch, ADMFLAG_BAN, "Switches to RED");
	RegAdminCmd("ph_internet", Command_internet, ADMFLAG_BAN, "Spams Internet");
	RegAdminCmd("ph_pyro", Command_pyro, ADMFLAG_BAN, "Switches to BLU");
	RegAdminCmd("ph_reloadconfig", Command_ReloadConfig, ADMFLAG_BAN, "Reloads the PropHunt configuration");

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
	g_PropData = CreateTrie();
	g_PropNames = CreateTrie();
	g_PropNamesIndex = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));
	g_ModelLanguages = CreateArray(ByteCountToCells(MAXLANGUAGECODE));

	g_ModelName = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));
	g_ModelOffset = CreateArray(ByteCountToCells(11));
	g_ModelRotation = CreateArray(ByteCountToCells(11));
	g_ModelSkin = CreateArray();
	
	AutoExecConfig(true, "prophunt_redux");
	
	// Create Config menu
	g_ConfigMenu = CreateMenu(Handler_ConfigMenu, MENU_ACTIONS_DEFAULT|MenuAction_DisplayItem);
	SetMenuTitle(g_ConfigMenu, "PropHunt Configuration");
	SetMenuPagination(g_ConfigMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(g_ConfigMenu, true);
	AddMenuItem(g_ConfigMenu, "#version", PL_VERSION);
	AddMenuItem(g_ConfigMenu, "#airblast", "Airblast");
	AddMenuItem(g_ConfigMenu, "#propmenu", "PropMenu");
	AddMenuItem(g_ConfigMenu, "#proprestrict", "PropRestrict");
	AddMenuItem(g_ConfigMenu, "#propdamage", "PropChange");
	AddMenuItem(g_ConfigMenu, "#propreroll", "PropReroll");
	AddMenuItem(g_ConfigMenu, "#preventfalldamage", "Prevent Fall Damage");
	AddMenuItem(g_ConfigMenu, "#setuptime", "Setup Time");
#if defined STATS
	AddMenuItem(g_ConfigMenu, "#stats", "Stats");
#endif
}

ReadCommonPropData(bool:onlyLanguageRefresh = false)
{
	decl String:Path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Path, sizeof(Path), "data/prophunt/prop_common.txt");
	new Handle:propCommon = CreateKeyValues("propcommon");
	if (!FileToKeyValues(propCommon, Path))
	{
		LogError("Could not load the g_PropData file!");
		return;
	}
	
	if (!KvGotoFirstSubKey(propCommon))
	{
		LogError("Prop Common file is empty!");
		return;
	}		
	
	ClearPropNames();
	
	if (!onlyLanguageRefresh)
	{
		ClearTrie(g_PropData);
	}
	ClearArray(g_ModelLanguages);
	
	new counter = 0;
	do
	{
		counter++;
		decl String:modelPath[PLATFORM_MAX_PATH];
		
		new propData[PropData];
		
		KvGetSectionName(propCommon, modelPath, PLATFORM_MAX_PATH);
		KvGetString(propCommon, "name", propData[PropData_Name], sizeof(propData[PropData_Name]), ""); // Still around for compat reasons
		if (strlen(propData[PropData_Name]) == 0)
		{
			KvGetString(propCommon, "en", propData[PropData_Name], sizeof(propData[PropData_Name]), ""); // Default this to English otherwise
		}
		KvGetString(propCommon, "offset", propData[PropData_Offset], sizeof(propData[PropData_Offset]), "0 0 0");
		KvGetString(propCommon, "rotation", propData[PropData_Rotation], sizeof(propData[PropData_Rotation]), "0 0 0");

		if (strlen(propData[PropData_Name]) == 0)
		{
			// No "name" or "en" block means no prop name, but this isn't an error that prevents us from using the prop for offset and rotation
			LogError("Error getting prop name for %s", modelPath);
		}
		
		if (!onlyLanguageRefresh)
		{
			if (!SetTrieArray(g_PropData, modelPath, propData[0], sizeof(propData), false))
			{
				LogError("Error saving prop data for %s, probably a duplicate prop in data/prophunt/prop_common.txt", modelPath);
				continue;
			}
		}
		
		if (GetConVarBool(g_PHMultilingual))
		{
			new Handle:languageTrie = CreateTrie();
			
			for (new i=0;i<GetLanguageCount();i++)
			{
				decl String:lang[MAXLANGUAGECODE];
				decl String:name[MAXMODELNAME];
				GetLanguageInfo(i, lang, sizeof(lang));
				//search for the translation
				KvGetString(propCommon, lang, name, sizeof(name));

				// Make "en" read the "name" section for compatibility reasons if "en" isn't present
				if (strlen(name) <= 0 && StrEqual(lang, "en"))
				{
					strcopy(name, sizeof(name), propData[PropData_Name]);
				}
				
				if (strlen(name) > 0)
				{
					//language new?
					if (FindStringInArray(g_ModelLanguages, lang) == -1)
					{
#if defined LOG
						LogMessage("[PH] Adding language \"%s\" to languages list", lang);
#endif
						PushArrayString(g_ModelLanguages, lang);
					}
					
					SetTrieString(languageTrie, lang, name);
				}
			}
			
			if (!SetTrieValue(g_PropNames, modelPath, languageTrie, false))
			{
				LogError("Error saving prop names for %s", modelPath);
			}
			else
			{
				PushArrayString(g_PropNamesIndex, modelPath);
			}
		}
	} while (KvGotoNextKey(propCommon));
	
	CloseHandle(propCommon);
	
	LogMessage("Loaded %d props from props_common.txt", counter);
#if defined LOG
	LogMessage("[PH] Loaded %d language(s)", GetArraySize(g_ModelLanguages));
#endif
	
}

ClearPropNames()
{
	new arraySize = GetArraySize(g_PropNamesIndex);
	for (new i = 0; i < arraySize; i++)
	{
		decl String:modelName[PLATFORM_MAX_PATH];
		new Handle:languageTrie = INVALID_HANDLE;
		GetArrayString(g_PropNamesIndex, i, modelName, sizeof(modelName));
		if (GetTrieValue(g_PropNames, modelName, languageTrie) && languageTrie != INVALID_HANDLE)
		{
			CloseHandle(languageTrie);
		}
	}
	
	ClearTrie(g_PropNames);
	ClearArray(g_PropNamesIndex);
}

public OnAllPluginsLoaded()
{
	g_SteamTools = LibraryExists("SteamTools");
	g_SteamWorks = LibraryExists("SteamWorks");
	if (g_SteamTools || g_SteamWorks)
	{
#if defined LOG
		if (g_SteamTools)
			LogMessage("[PH] Found SteamTools on startup.");
			
		if (g_SteamWorks)
			LogMessage("[PH] Found SteamWorks on startup.");
#endif
		UpdateGameDescription();
	}
	
#if defined OIMM
	g_OptinMultiMod = LibraryExists("optin_multimod");
	if (g_OptinMultiMod)
	{
#if defined LOG
		LogMessage("[PH] Found Opt-In Multimod on startup.");
#endif
		OptInMultiMod_Register("prophunt", ValidateMap, MultiMod_Status, MultiMod_TranslateName);
	}
#endif

	g_Updater = LibraryExists("updater");
	
#if defined LOG
	if (g_Updater)
	{
		LogMessage("[PH] Found Updater on startup.");
	}
#endif
}

// Should we switch teams this round?
// Note: Don't confuse this with the games ShouldSwitchTeams
bool:Internal_ShouldSwitchTeams()
{
	new bool:lastRound = (g_RoundCurrent == g_RoundCount);
	if (lastRound)
	{
#if defined LOG
	LogMessage("[PH] This is the last of %d round(s).", g_RoundCount);
#endif
		g_RoundCurrent = 0;
	}
	
	if (g_RoundSwitchAlways || lastRound)
	{
		return true;
	}
	
#if defined LOG
	LogMessage("[PH] Teams will not be switched because it is not the last round and we are set to not always switch rounds.");
#endif

	return false;
}

loadGlobalConfig()
{
	decl String:Path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Path, sizeof(Path), "data/prophunt/prophunt_config.cfg");
	if (g_ConfigKeyValues != INVALID_HANDLE)
	{
		CloseHandle(g_ConfigKeyValues);
	}
	g_ConfigKeyValues = CreateKeyValues("prophunt_config");
	if (!FileToKeyValues(g_ConfigKeyValues, Path))
	{
		LogError("Could not load the PropHunt config file!");
	}
	
	config_parseWeapons();
	config_parseClasses();
	config_parseSounds();
	
	ReadCommonPropData(false);
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "SteamTools", false))
	{
#if defined LOG
		LogMessage("[PH] SteamTools Loaded ");
#endif
		g_SteamTools = true;
		UpdateGameDescription();
	}
	else
	if (StrEqual(name, "SteamWorks", false))
	{
#if defined LOG
		LogMessage("[PH] SteamWorks Loaded ");
#endif
		g_SteamWorks = true;
		UpdateGameDescription();
	}
#if defined OIMM
	else
	if (StrEqual(name, "optin_multimod", false))
	{
#if defined LOG
		LogMessage("[PH] Opt-in MultiMod Loaded ");
#endif
		g_OptinMultiMod = true;
	}
#endif
	else
	if (StrEqual(name, "updater", false))
	{
#if defined LOG
		LogMessage("[PH] Updater Loaded.");
#endif
		g_Updater = true;
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "SteamTools", false))
	{
#if defined LOG
		LogMessage("[PH] SteamTools Unloaded ");
#endif
		g_SteamTools = false;
	}
	else
	if (StrEqual(name, "SteamWorks", false))
	{
#if defined LOG
		LogMessage("[PH] SteamWorks Unloaded ");
#endif
		g_SteamWorks = false;
	}
#if defined OIMM
	else
	if (StrEqual(name, "optin_multimod", false))
	{
#if defined LOG
		LogMessage("[PH] Opt-In Multimod Unloaded ");
#endif
		g_OptinMultiMod = false;
	}
#endif
	else
	if (StrEqual(name, "updater", false))
	{
#if defined LOG
		LogMessage("[PH] Updater Unloaded.");
#endif
		g_Updater = false;
	}	
}

public OnGameDescriptionChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UpdateGameDescription();
}

public OnAntiHackChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!g_Enabled)
		return;
	
	if ((GetConVarBool(g_PHAntiHack) || GetConVarBool(g_PHStaticPropInfo)) && g_hAntiHack == INVALID_HANDLE)
	{
		g_hAntiHack = CreateTimer(7.0, Timer_AntiHack, _, TIMER_REPEAT);
		// Also run said timer 0.1 seconds after round start.
		CreateTimer(0.1, Timer_AntiHack, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (!GetConVarBool(g_PHAntiHack) && !GetConVarBool(g_PHStaticPropInfo) && g_hAntiHack != INVALID_HANDLE)
	{
		CloseHandle(g_hAntiHack);
		g_hAntiHack = INVALID_HANDLE;
	}
}

UpdateGameDescription(bool:bAddOnly=false)
{
	if (!g_SteamTools && !g_SteamWorks)
	{
		return;
	}
	
	decl String:gamemode[128];
	if (g_Enabled && GetConVarBool(g_PHGameDescription))
	{
		if (strlen(g_AdText) > 0)
		{
			Format(gamemode, sizeof(gamemode), "PropHunt Redux %s (%s)", g_Version, g_AdText);
		}
		else
		{
			Format(gamemode, sizeof(gamemode), "PropHunt Redux %s", g_Version);
		}
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
	
	if (g_SteamTools)
	{
		Steam_SetGameDescription(gamemode);
	}
	else
	if (g_SteamWorks)
	{
		SteamWorks_SetGameDescription(gamemode);
	}
}

config_parseWeapons()
{
	ClearArray(g_hWeaponRemovals);
	ClearArray(g_hPropWeaponRemovals);
	ClearTrie(g_hWeaponNerfs);
	ClearTrie(g_hWeaponSelfDamage);
	ClearArray(g_hWeaponStripAttribs);
	ClearTrie(g_hWeaponAddAttribs);
	ClearTrie(g_hWeaponReplacements);
	ClearTrie(g_hWeaponReplacementPlayerClasses);
	
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
				SetTrieValue(g_hWeaponNerfs, SectionName, KvGetFloat(g_ConfigKeyValues, "damage_hunters"));
			}
			if(KvGetDataType(g_ConfigKeyValues, "removed_hunters") == KvData_Int)
			{
				if (bool:KvGetNum(g_ConfigKeyValues, "removed_hunters"))
				{
					PushArrayCell(g_hWeaponRemovals, StringToInt(SectionName));
				}
			}
			if(KvGetDataType(g_ConfigKeyValues, "removed_props") == KvData_Int)
			{
				if (bool:KvGetNum(g_ConfigKeyValues, "removed_props"))
				{
					PushArrayCell(g_hPropWeaponRemovals, StringToInt(SectionName));
				}
			}
			if(KvGetDataType(g_ConfigKeyValues, "self_damage_hunters") == KvData_Float)
			{
				SetTrieValue(g_hWeaponSelfDamage, SectionName, KvGetFloat(g_ConfigKeyValues, "self_damage_hunters"));
			}
			if(KvGetDataType(g_ConfigKeyValues, "stripattribs") == KvData_Int)
			{
				if (bool:KvGetNum(g_ConfigKeyValues, "stripattribs"))
				{
					PushArrayCell(g_hWeaponStripAttribs, StringToInt(SectionName));
				}
			}
			if(KvGetDataType(g_ConfigKeyValues, "addattribs") == KvData_String)
			{
				new String:attribs[128];
				KvGetString(g_ConfigKeyValues, "addattribs", attribs, sizeof(attribs));
				
				if (attribs[0] != '\0')
				{
					SetTrieString(g_hWeaponAddAttribs, SectionName, attribs);
				}
			}
			if(KvGetDataType(g_ConfigKeyValues, "replace") == KvData_String)
			{
				new String:attribs[128];
				KvGetString(g_ConfigKeyValues, "replace", attribs, sizeof(attribs));
				
				new class = KvGetNum(g_ConfigKeyValues, "replace_onlyclasses", TFClassBits_None);
				
				if (attribs[0] != '\0')
				{
					SetTrieString(g_hWeaponReplacements, SectionName, attribs);
				}
				
				if (class != TFClassBits_None)
				{
					SetTrieValue(g_hWeaponReplacementPlayerClasses, SectionName, class);
				}
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
	new red = TEAM_PROP-2;
	new blue = TEAM_HUNTER-2;
	g_defaultClass[red] = TFClass_Scout;
	g_defaultClass[blue] = TFClass_Pyro;
	
	for(new i = 0; i < 10; i++)
	{
		g_classLimits[blue][i] = -1;
		g_classLimits[red][i] = -1;
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
				g_classLimits[blue][StringToInt(SectionName)] = KvGetNum(g_ConfigKeyValues, "hunter_limit");
			}
			if(KvGetDataType(g_ConfigKeyValues, "prop_limit") == KvData_Int)
			{
				g_classLimits[red][StringToInt(SectionName)] = KvGetNum(g_ConfigKeyValues, "prop_limit");
			}
			if(KvGetDataType(g_ConfigKeyValues, "hunter_default_class") == KvData_Int)
			{
				g_defaultClass[blue] = TFClassType:StringToInt(SectionName);
			}
			if(KvGetDataType(g_ConfigKeyValues, "prop_default_class") == KvData_Int)
			{
				g_defaultClass[red] = TFClassType:StringToInt(SectionName);
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
	ClearTrie(g_BroadcastSounds);
	
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
				decl String:soundString[PLATFORM_MAX_PATH];
				KvGetString(g_ConfigKeyValues, "sound", soundString, sizeof(soundString));
				
				if(PrecacheSound(soundString))
				{
					decl String:downloadString[PLATFORM_MAX_PATH];
					Format(downloadString, sizeof(downloadString), "sound/%s", soundString);
					AddFileToDownloadsTable(downloadString);
					
					SetTrieString(g_Sounds, SectionName, soundString, true);
				}
			}
			if(KvGetDataType(g_ConfigKeyValues, "broadcast") == KvData_String)
			{
				decl String:soundString[128];
				KvGetString(g_ConfigKeyValues, "broadcast", soundString, sizeof(soundString));
				
				PrecacheScriptSound(soundString);
				
				SetTrieString(g_BroadcastSounds, SectionName, soundString, true);
			}
			if(KvGetDataType(g_ConfigKeyValues, "game") == KvData_String)
			{
				decl String:soundString[128];
				KvGetString(g_ConfigKeyValues, "game", soundString, sizeof(soundString));
				
				PrecacheScriptSound(soundString);
				
				SetTrieString(g_BroadcastSounds, SectionName, soundString, true);
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

	SetConVarFlags(g_hArenaRoundTime, GetConVarFlags(g_hArenaRoundTime) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hArenaUseQueue, GetConVarFlags(g_hArenaUseQueue) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hArenaMaxStreak, GetConVarFlags(g_hArenaMaxStreak) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hTournamentStopwatch, GetConVarFlags(g_hTournamentStopwatch) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hTournamentHideDominationIcons, GetConVarFlags(g_hTournamentHideDominationIcons) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hTeamsUnbalanceLimit, GetConVarFlags(g_hTeamsUnbalanceLimit) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hArenaPreroundTime, GetConVarFlags(g_hArenaPreroundTime) & ~(FCVAR_NOTIFY));

	g_ArenaRoundTime = GetConVarInt(g_hArenaRoundTime);
	SetConVarInt(g_hArenaRoundTime, 0, true);
	
	g_ArenaUseQueue = GetConVarBool(g_hArenaUseQueue);
	SetConVarBool(g_hArenaUseQueue, false, true);

	g_ArenaMaxStreak = GetConVarInt(g_hArenaMaxStreak);
	SetConVarInt(g_hArenaMaxStreak, 4, true);
	
	g_TournamentStopwatch = GetConVarInt(g_hTournamentStopwatch);
	SetConVarInt(g_hTournamentStopwatch, 0, true);
	
	g_TournamentHideDominationIcons = GetConVarInt(g_hTournamentHideDominationIcons);
	SetConVarInt(g_hTournamentHideDominationIcons, 0, true);

	g_TeamsUnbalanceLimit = GetConVarInt(g_hTeamsUnbalanceLimit);
	SetConVarInt(g_hTeamsUnbalanceLimit, UNBALANCE_LIMIT, true);

	SetConVarBounds(g_hArenaPreroundTime, ConVarBound_Upper, false);
	g_ArenaPreroundTime = GetConVarInt(g_hArenaPreroundTime);
	SetConVarInt(g_hArenaPreroundTime, IsDedicatedServer() ? 20:5, true);
	
	g_WeaponCriticals = GetConVarInt(g_hWeaponCriticals);
	SetConVarInt(g_hWeaponCriticals, 0, true);
	
	g_Idledealmethod = GetConVarInt(g_hIdledealmethod);
	SetConVarInt(g_hIdledealmethod, 0, true);
	
	g_Friendlyfire = GetConVarInt(g_hFriendlyfire);
	SetConVarInt(g_hFriendlyfire, 0, true);
	
	g_Gravity = GetConVarInt(g_hGravity);
	SetConVarInt(g_hGravity, 500, true);
	
	g_Forcecamera = GetConVarInt(g_hForcecamera);
	SetConVarInt(g_hForcecamera, 1, true);
	
	g_ArenaCapEnableTime = GetConVarInt(g_hArenaCapEnableTime);
	SetConVarInt(g_hArenaCapEnableTime, 3600, true); // Set really high
	
	g_EnableRoundWaitTime = GetConVarInt(g_hEnableRoundWaitTime);
	SetConVarInt(g_hEnableRoundWaitTime, 0, true);

	g_WaitingForPlayerTime = GetConVarInt(g_hWaitingForPlayerTime);
	SetConVarInt(g_hWaitingForPlayerTime, 40, true);
	
	g_ShowVoiceIcons = GetConVarInt(g_hShowVoiceIcons);
	SetConVarInt(g_hShowVoiceIcons, 0, true);

	g_SolidObjects = GetConVarInt(g_hSolidObjects);
	SetConVarInt(g_hSolidObjects, 0, true);
	
	g_ArenaFirstBlood = GetConVarBool(g_hArenaFirstBlood);
	SetConVarBool(g_hArenaFirstBlood, false, true);
	
	g_WeaponDropTime = GetConVarInt(g_hWeaponDropTime);
	SetConVarInt(g_hWeaponDropTime, 0, true);
	
	g_CvarsSet = true;
}

ResetCVars()
{
	if (!g_CvarsSet)
		return;
	
	SetConVarFlags(g_hArenaRoundTime, GetConVarFlags(g_hArenaRoundTime) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hArenaUseQueue, GetConVarFlags(g_hArenaUseQueue) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hArenaMaxStreak, GetConVarFlags(g_hArenaMaxStreak) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hTeamsUnbalanceLimit, GetConVarFlags(g_hTeamsUnbalanceLimit) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hArenaPreroundTime, GetConVarFlags(g_hArenaPreroundTime) & ~(FCVAR_NOTIFY));

	SetConVarInt(g_hArenaRoundTime, g_ArenaRoundTime, true);
	SetConVarBool(g_hArenaUseQueue, g_ArenaUseQueue, true);
	SetConVarInt(g_hArenaMaxStreak, g_ArenaMaxStreak, true);
	SetConVarInt(g_hTournamentStopwatch, g_TournamentStopwatch, true);
	SetConVarInt(g_hTournamentHideDominationIcons, g_TournamentHideDominationIcons, true);
	SetConVarInt(g_hTeamsUnbalanceLimit, g_TeamsUnbalanceLimit, true);
	SetConVarInt(g_hArenaPreroundTime, g_ArenaPreroundTime, true);
	SetConVarInt(g_hWeaponCriticals, g_WeaponCriticals, true);
	SetConVarInt(g_hIdledealmethod, g_Idledealmethod, true);
	SetConVarInt(g_hFriendlyfire, g_Friendlyfire, true);
	SetConVarInt(g_hGravity, g_Gravity, true);
	SetConVarInt(g_hForcecamera, g_Forcecamera, true);
	SetConVarInt(g_hArenaCapEnableTime, g_ArenaCapEnableTime, true);
	SetConVarInt(g_hEnableRoundWaitTime, g_EnableRoundWaitTime, true);
	SetConVarInt(g_hWaitingForPlayerTime, g_WaitingForPlayerTime, true);
	SetConVarInt(g_hShowVoiceIcons, g_ShowVoiceIcons, true);
	SetConVarInt(g_hSolidObjects, g_SolidObjects, true);
	SetConVarBool(g_hArenaFirstBlood, g_ArenaFirstBlood, true);
	SetConVarInt(g_hWeaponDropTime, g_WeaponDropTime, true);
	
	g_CvarsSet = false;
}

public OnConfigsExecuted()
{
	g_Enabled = GetConVarBool(g_PHEnable) && g_PHMap;
	
	g_GameRulesProxy = EntIndexToEntRef(FindEntityByClassname(-1, "tf_gamerules"));
	
	if (GetConVarInt(g_PHPropMenu) == 1 && !g_PropMenuOverrideInstalled)
	{
		InstallPropMenuOverride();
	}
	
	if (GetConVarInt(g_PHReroll) == 1 && !g_PropRerollOverrideInstalled)
	{
		InstallPropRerollOverride();
	}
	
	if (g_Enabled)
	{
		SetCVars();
		Internal_AddServerTag();
	}
	else
	{
		Internal_RemoveServerTag();
	}
	
	UpdateGameDescription(true);
	
	CountRounds();
}

InstallPropMenuOverride()
{
	new tempFlags;
	if (GetCommandOverride("propmenu", Override_Command, tempFlags))
	{
		g_PropMenuOldFlags = tempFlags;
	}
	
	AddCommandOverride("propmenu", Override_Command, ADMFLAG_NONE);
	g_PropMenuOverrideInstalled = true;
}

RemovePropMenuOverride()
{
	if (g_PropMenuOldFlags == ADMFLAG_NONE)
	{
		UnsetCommandOverride("propmenu", Override_Command);
	}
	else
	{
		AddCommandOverride("propmenu", Override_Command, g_PropMenuOldFlags);
		g_PropMenuOldFlags = ADMFLAG_NONE;
	}
	
	g_PropMenuOverrideInstalled = false;
}

InstallPropRerollOverride()
{
	new tempFlags;
	if (GetCommandOverride("propreroll", Override_Command, tempFlags))
	{
		g_PropRerollOldFlags = tempFlags;
	}
	
	AddCommandOverride("propreroll", Override_Command, ADMFLAG_NONE);
	g_PropRerollOverrideInstalled = true;
}

RemovePropRerollOverride()
{
	if (g_PropRerollOldFlags == ADMFLAG_NONE)
	{
		UnsetCommandOverride("propreroll", Override_Command);
	}
	else
	{
		AddCommandOverride("propreroll", Override_Command, g_PropRerollOldFlags);
		g_PropRerollOldFlags = ADMFLAG_NONE;
	}
	
	g_PropRerollOverrideInstalled = false;
}

public OnPropMenuChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new newVal = GetConVarInt(g_PHPropMenu);
	if (g_PropMenuOverrideInstalled && newVal < 1)
	{
		RemovePropMenuOverride();
	}
	else if (!g_PropMenuOverrideInstalled && newVal == 1)
	{
		InstallPropMenuOverride();
	}
}

public OnPropRerollChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new newVal = GetConVarInt(g_PHReroll);
	if (g_PropRerollOverrideInstalled && newVal < 1)
	{
		RemovePropRerollOverride();
	}
	else if (!g_PropRerollOverrideInstalled && newVal == 1)
	{
		InstallPropRerollOverride();
	}
}

public OnMultilingualChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(convar))
	{
		ReadCommonPropData(true);
	}
	else
	{
		ClearPropNames();
	}
	
}

public OnRebuildAdminCache(AdminCachePart:part)
{
	if (part == AdminCache_Overrides && (GetConVarInt(g_PHPropMenu) == 1 || GetConVarInt(g_PHReroll) == 1))
	{
		CreateTimer(0.2, Timer_RestoreOverrides);
	}
}

public Action:Timer_RestoreOverrides(Handle:timer)
{
	if (GetConVarInt(g_PHPropMenu) == 1)
	{
		InstallPropMenuOverride();
	}
	
	if (GetConVarInt(g_PHReroll) == 1)
	{
		InstallPropRerollOverride();
	}
}

CountRounds()
{
	g_RoundCurrent = 0;
	g_RoundCount = 0;
	new entity = -1;
//	new prevPriority = 0;
	new bool:roundSwitchAlways = true;
	
	while ((entity = FindEntityByClassname(entity, "team_control_point_round")) != -1)
	{
		// Check if the round isn't disabled here?
		// Test on ph_kakariko to see if its other part is present.
		g_RoundCount++;
		// We'll look at round priorities again sometime in the future, ignore for now.
		/*
		new priority = GetEntProp(entity, Prop_Data, "m_nPriority");
		if (prevPriority == 0)
		{
			prevPriority = priority;
		}
		else
		if (prevPriority != priority)
		{
			
			roundSwitchAlways = false;
			break;
		}
		*/
	}
	
	// No team_control_point_round entities means we have just 1 round
	if (g_RoundCount == 0)
		g_RoundCount = 1;

	if (g_RoundCount % 2 == 0)
	{
		// For event number of rounds, never switch
		roundSwitchAlways = false;
	}
	
	g_RoundSwitchAlways = roundSwitchAlways;
	
#if defined LOG
	LogMessage("[PH] Map has %d round(s), Switch teams every round: %d", g_RoundCount, g_RoundSwitchAlways);
#endif
}


StartTimers(bool:noScoreTimer = false)
{
	if (g_hLocked == INVALID_HANDLE)
	{
		g_hLocked = CreateTimer(0.6, Timer_Locked, _, TIMER_REPEAT);
	}
		
	if (!noScoreTimer && g_hScore == INVALID_HANDLE)
	{
		g_hScore = CreateTimer(55.0, Timer_Score, _, TIMER_REPEAT);
	}

	if ((GetConVarBool(g_PHAntiHack) || GetConVarBool(g_PHStaticPropInfo)) && g_hAntiHack == INVALID_HANDLE)
	{
		g_hAntiHack = CreateTimer(7.0, Timer_AntiHack, _, TIMER_REPEAT);
		// Also run said timer 0.1 seconds after round start.
		CreateTimer(0.1, Timer_AntiHack, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

StopTimers()
{
	if (g_hAntiHack != INVALID_HANDLE)
	{
		CloseHandle(g_hAntiHack);
		g_hAntiHack = INVALID_HANDLE;
	}
	
	if (g_hLocked != INVALID_HANDLE)
	{
		CloseHandle(g_hLocked);
		g_hLocked = INVALID_HANDLE;
	}
	
	if (g_hScore != INVALID_HANDLE)
	{
		CloseHandle(g_hScore);
		g_hScore = INVALID_HANDLE;
	}
}

public OnEnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!g_MapStarted)
	{
		return;
	}
	
	if (GetConVarBool(g_PHEnable))
	{
		if (g_Enabled)
		{
			g_RoundChange = RoundChange_NoChange; // Reset in case it was RoundChange_Disable
		}
		else
		{
			new bool:enabled = IsPropHuntMap();
			if (enabled)
			{
				g_RoundChange = RoundChange_Enable;
			}
			else
			{
				g_RoundChange = RoundChange_NoChange;
			}
		}
	}
	else
	{
		if (g_Enabled)
		{
			g_RoundChange = RoundChange_Disable;
		}
		else
		{
			g_RoundChange = RoundChange_NoChange;
		}
	}
}

public OnAdTextChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(g_AdText, sizeof(g_AdText), newValue);
}

public OnUseUpdaterChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!g_Updater)
		return;
		
	if (GetConVarBool(convar))
	{
		Updater_ForceUpdate();
	}
}

public Action:Updater_OnPluginDownloading()
{
	return GetConVarBool(g_PHUseUpdater) ? Plugin_Continue : Plugin_Handled;
}

public Updater_OnPluginUpdated()
{
	PrintCenterTextAll("PropHunt Redux Updated, server restart may be required.");
	LogMessage("[PH] PropHunt Redux Updated, server restart may be required.");
}

public StartTouchHook(entity, other)
{
	if(other <= MaxClients && other > 0 && !g_TouchingCP[other] && IsClientInGame(other) && IsPlayerAlive(other))
	{
		FillHealth(other);
		ExtinguishPlayer(other);
		CPrintToChat(other, "%t", "#TF_PH_CPBonus");
		PH_EmitSoundToClient(other, "CPBonus", _, _, SNDLEVEL_AIRCRAFT);
		g_TouchingCP[other] = true;
	}
}

stock FillHealth (entity)
{
	if(IsValidEntity(entity))
	{
		SetEntityHealth(entity, GetEntProp(entity, Prop_Data, "m_iMaxHealth"));
	}
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
	if (!g_Enabled)
	{
		return;
	}
	/*
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
	*/
	if (strcmp(classname, "obj_sentrygun") == 0)
	{
		SDKHook(entity, SDKHook_Spawn, OnBullshitEntitySpawned);
	}
	else
	if(strcmp(classname, "prop_dynamic") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnCPEntitySpawned);
	}
	else
	if(strcmp(classname, "team_control_point_master") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnCPMasterSpawnedPost);
	}
	else
	if (strcmp(classname, "team_round_timer") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnTimerSpawned);
	}
	else
	if (strcmp(classname, "tf_logic_arena") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnArenaSpawned);
	}
}

public Action:OnBullshitEntitySpawned(entity)
{
	if(IsValidEntity(entity))
		AcceptEntityInput(entity, "Kill");
	
	return Plugin_Continue;
}

public OnCPEntitySpawned(entity)
{
	decl String:propName[500];
	GetEntPropString(entity, Prop_Data, "m_ModelName", propName, sizeof(propName));
	if(StrEqual(propName, "models/props_gameplay/cap_point_base.mdl"))
	{
		// Reset the skin to neutral.  I'm looking at you, cp_manor_event
		SetVariantInt(0);
		AcceptEntityInput(entity, "Skin");
		
		// Check if the control point is using VPhysics.
		// If not, make it so it does (fixes issues with CP touch)
		new curSolidType = GetEntProp(entity, Prop_Data, "m_nSolidType");
		if (curSolidType != SOLID_VPHYSICS)
		{
			new String:solidType[2];
			IntToString(SOLID_VPHYSICS, solidType, sizeof(solidType));
			DispatchKeyValue(entity, "solid", solidType);
#if defined LOG
			LogMessage("[PH] Converting control point to VPhysics.");
#endif
		}
		// Also, hook it for the heal touch hook
		SDKHook(entity, SDKHook_StartTouch, StartTouchHook);
	}
}

public Action:OnTimerSpawned(entity)
{
	// Attempt to shut the pre-round timer up at start, unless 5 secs or less are left
	decl String:name[64];
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
	
	if (!StrEqual(name, TIMER_NAME))
	{
		DispatchKeyValue(entity, "auto_countdown", "0");
		
		SetVariantString("On10SecRemain !self:AutoCountdown:1:0:-1");
		AcceptEntityInput(entity, "AddOutput");

		// Client always plays the bell when the status changes from "setup" to "normal", 
		// which is what the pregame timer apparently does
		//SetVariantString("On1SecRemain !self:AutoCountdown:0:0:-1");
		//AcceptEntityInput(entity, "AddOutput");
	}
}

public OnCPMasterSpawnedPost(entity)
{
#if defined LOG
	LogMessage("[PH] cpmaster spawned");
#endif
    
	if (!g_MapStarted)
	{
		return;
	}
	
	decl String:name[64];
	if (GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name)) == 0)
	{
		DispatchKeyValue(entity, "targetname", "master_control_point");
	}
	
	CreateRoundTimer(entity);
}

public Action:OnArenaSpawned(entity)
{
	decl String:finishedCommand[256];

	Format(finishedCommand, sizeof(finishedCommand), "OnArenaRoundStart %s:ShowInHUD:1:0:-1", TIMER_NAME);
	SetVariantString(finishedCommand);
	AcceptEntityInput(entity, "AddOutput");
	
	Format(finishedCommand, sizeof(finishedCommand), "OnArenaRoundStart %s:Resume:0:0:-1", TIMER_NAME);
	SetVariantString(finishedCommand);
	AcceptEntityInput(entity, "AddOutput");
	
	Format(finishedCommand, sizeof(finishedCommand), "OnArenaRoundStart %s:Enable:0:0:-1", TIMER_NAME);
	SetVariantString(finishedCommand);
	AcceptEntityInput(entity, "AddOutput");
}

CheckRoundTimer()
{
	new entity = -1;
	
	while ((entity = FindEntityByClassname(entity, "team_round_timer")) != -1)
	{
		new String:name[64];
		
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		
		if (StrEqual(name, TIMER_NAME))
		{
#if defined LOG
	LogMessage("[PH] Found timer: %d", entity);
#endif
			return;
		}
	}
	
	// No timer found, create it
	LogMessage("[PH] PropHunt timer is missing.  Attempting to recreate it...");
	new cpMaster = FindEntityByClassname(-1, "team_control_point_master");
	
	if (cpMaster > -1)
	{
		CreateRoundTimer(cpMaster);
	}
	else
	{
		LogError("[PH] Could not locate team_control_point_master when recreating PropHunt timer");
	}
}

CreateRoundTimer(entity)
{
	// We need to subtract 30 from the round time for compatibility with older PropHunt Versions
	decl String:time[5];
	IntToString(g_RoundTime - 30, time, sizeof(time));
	
	decl String:name[64];
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
	
	if (name[0] == '\0')
	{
		LogError("team_control_point_master %d has no name", entity);
		return;
	}
	
	// Create our timer.
	new timer = CreateEntityByName("team_round_timer");
	DispatchKeyValue(timer, "targetname", TIMER_NAME);
	new String:setupLength[5];
	if (g_Setup >= SETUP_MIN && g_Setup <= SETUP_MAX)
	{
		IntToString(g_Setup, setupLength, sizeof(setupLength));
	}
	else
	{
		GetConVarString(g_PHSetupLength, setupLength, sizeof(setupLength));		
	}
	DispatchKeyValue(timer, "setup_length", setupLength);
	DispatchKeyValue(timer, "reset_time", "1");
	DispatchKeyValue(timer, "auto_countdown", "1");
	DispatchKeyValue(timer, "timer_length", time);
	DispatchSpawn(timer);
	
#if defined LOG
	LogMessage("[PH] setting up cpmaster \"%s\" (%d) with team round timer \"%s\" (%d) ", name, entity, TIMER_NAME, timer);
#endif
    
	decl String:finishedCommand[256];
	
	Format(finishedCommand, sizeof(finishedCommand), "OnFinished %s:SetWinnerAndForceCaps:%d:0:-1", name, TEAM_PROP);
	SetVariantString(finishedCommand);
	AcceptEntityInput(timer, "AddOutput");
	
	HookSingleEntityOutput(timer, "OnSetupStart", OnSetupStart);
	HookSingleEntityOutput(timer, "OnSetupFinished", OnSetupFinished);
}

public OnMapEnd()
{
#if defined STATS
	g_MapChanging = true;
#endif

	// workaround for CreateEntityByName
	g_MapStarted = false;
	
	ResetCVars();
	StopTimers();
	new bool:remove = g_Enabled; // Save the enabled value
	g_Enabled = false;
	if (remove)
	{
		UpdateGameDescription();
	}
	
	for (new client = 1; client<=MaxClients; client++)
	{
		g_CurrentlyFlaming[client] = false;
		g_FlameCount[client] = 0;
	}

	ClearArray(g_ModelName);
	ClearArray(g_ModelOffset);
	ClearArray(g_ModelRotation);
	ClearArray(g_ModelSkin);

	ClearArray(g_hWeaponRemovals);
	ClearArray(g_hPropWeaponRemovals);
	ClearTrie(g_hWeaponNerfs);
	ClearTrie(g_hWeaponSelfDamage);
	ClearArray(g_hWeaponStripAttribs);
	ClearTrie(g_hWeaponAddAttribs);
	ClearTrie(g_hWeaponReplacements);
	ClearTrie(g_hWeaponReplacementPlayerClasses);
	
	ClearTrie(g_Sounds);
	ClearTrie(g_BroadcastSounds);
}

public OnMapStart()
{
	g_GameRulesProxy = INVALID_ENT_REFERENCE;
	GetCurrentMap(g_Mapname, sizeof(g_Mapname));
	
	g_PHMap = IsPropHuntMap();

	if (g_PHMap)
	{
		decl String:confil[PLATFORM_MAX_PATH], String:buffer[256], String:offset[32], String:rotation[32];
		
		new Handle:fl;
		
		if (g_PropMenu != INVALID_HANDLE)
		{
			CloseHandle(g_PropMenu);
			g_PropMenu = INVALID_HANDLE;
		}
		g_PropMenu = CreateMenu(Handler_PropMenu, MENU_ACTIONS_DEFAULT|MenuAction_DisplayItem);
		SetMenuTitle(g_PropMenu, "PropHunt Prop Menu");
		SetMenuExitButton(g_PropMenu, true);
		
		BuildPath(Path_SM, confil, sizeof(confil), "data/prophunt/prop_menu.txt");
		
		fl = CreateKeyValues("propmenu");
		if (FileToKeyValues(fl, confil))
		{
			new count = 0;
			PrintToServer("Successfully loaded %s", confil);
			KvGotoFirstSubKey(fl);
			do
			{
				KvGetSectionName(fl, buffer, sizeof(buffer));
				if (!FileExists(buffer, true))
				{
					LogError("prop_menu.txt: Prop does not exist: %s", buffer);
					continue;
				}
				AddMenuItem(g_PropMenu, buffer, buffer);
				count++;
			}
			while (KvGotoNextKey(fl));
			
			PrintToServer("Successfully parsed %s", confil);
			PrintToServer("Added %i models to prop menu.", GetMenuItemCount(g_PropMenu));
		}
		CloseHandle(fl);
		
		new sharedCount = 0;
		BuildPath(Path_SM, confil, sizeof(confil), "data/prophunt/props_allmaps.txt");
		
		fl = CreateKeyValues("sharedprops");
		if (FileToKeyValues(fl, confil))
		{
			PrintToServer("Successfully loaded %s", confil);
			KvGotoFirstSubKey(fl);
			do
			{
				KvGetSectionName(fl, buffer, sizeof(buffer));
				if (!FileExists(buffer, true))
				{
					LogError("props_allmaps.txt: Prop does not exist: %s", buffer);
					continue;
				}
				PushArrayString(g_ModelName, buffer);
				AddMenuItem(g_PropMenu, buffer, buffer);
				KvGetString(fl, "offset", offset, sizeof(offset), "0 0 0");
				PushArrayString(g_ModelOffset, offset);
				KvGetString(fl, "rotation", rotation, sizeof(rotation), "0 0 0");
				PushArrayString(g_ModelRotation, rotation);
				PushArrayCell(g_ModelSkin, KvGetNum(fl, "skin", 0));
			}
			while (KvGotoNextKey(fl));
			
			PrintToServer("Successfully parsed %s", confil);
			sharedCount = GetArraySize(g_ModelName);
			PrintToServer("Loaded %i shared models.", sharedCount);
		}
		CloseHandle(fl);
		
		if (!FindConfigFileForMap(g_Mapname, confil, sizeof(confil)))
		{
			LogMessage("[PH] Config file for map %s not found. Disabling plugin.", g_Mapname);
			g_Enabled = false;
			return;
		}
		
		fl = CreateKeyValues("prophuntmapconfig");
		
		if(!FileToKeyValues(fl, confil))
		{
			LogMessage("[PH] Config file for map %s at %s could not be opened. Disabling plugin.", g_Mapname, confil);
			CloseHandle(fl);
			g_Enabled = false;
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
				if (!FileExists(buffer, true))
				{
					LogError("%s: Prop does not exist: %s", confil, buffer);
					continue;
				}
				PushArrayString(g_ModelName, buffer);
				AddMenuItem(g_PropMenu, buffer, buffer);
				KvGetString(fl, "offset", offset, sizeof(offset), "0 0 0");
				PushArrayString(g_ModelOffset, offset);
				KvGetString(fl, "rotation", rotation, sizeof(rotation), "0 0 0");
				PushArrayString(g_ModelRotation, rotation);
				PushArrayCell(g_ModelSkin, KvGetNum(fl, "skin", 0));
			}
			while (KvGotoNextKey(fl));
			KvRewind(fl);
			KvJumpToKey(fl, "Settings", false);
			
			g_Doors = bool:KvGetNum(fl, "doors", 0);
			g_Relay = bool:KvGetNum(fl, "relay", 0);
			g_Freeze = bool:KvGetNum(fl, "freeze", 1);
			g_RoundTime = KvGetNum(fl, "round", 175);
			g_Setup = KvGetNum(fl, "setup", 30);
			
			PrintToServer("Successfully parsed %s", confil);
			PrintToServer("Loaded %i models, doors: %i, relay: %i, freeze: %i, round time: %i, setup: %i.", GetArraySize(g_ModelName)-sharedCount, g_Doors ? 1:0, g_Relay ? 1:0, g_Freeze ? 1:0, g_RoundTime, g_Setup);
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
		
		// workaround for CreateEntityByNsme
		g_MapStarted = true;
		
		loadGlobalConfig();
	}
	
	// workaround no win panel event - admin changes, rtv, etc.
	g_LastProp = false;
	for (new client = 1; client <= MaxClients; client++)
	{
		g_LastPropDamageTime[client] = -1;
	}
	g_LastPropPlayer = 0;
	g_RoundOver = true;
	g_inSetup = false;
	//g_inPreRound = true;
	g_PlayerDied = false;
	g_flRoundStart = 0.0;
	
	// Clear the replacement weapon list
	for (new i = 1; i <= MaxClients; ++i)
	{
		for (new j = 0; j < sizeof(g_Replacements[]); ++j)
		{
			g_Replacements[i][j] = -1;
		}
		g_ReplacementCount[i] = 0;
	}
	
#if defined STATS
	g_MapChanging = false;
#endif

}

public OnPluginEnd()
{
	PrintCenterTextAll("%t", "#TF_PH_PluginReload");
#if defined STATS
	Stats_Uninit();
#endif
	
	ResetCVars();
	if (g_SteamTools)
	{
		Steam_SetGameDescription("Team Fortress");
	}
	else
	if (g_SteamWorks)
	{
		SteamWorks_SetGameDescription("Team Fortress");
	}
#if defined OIMM
	if (g_OptinMultiMod)
	{
		OptInMultiMod_Unregister("prophunt");
	}
#endif
}

public Action:TakeDamageHook(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (!g_Enabled)
	{
		return Plugin_Continue;
	}
	
	if(victim > 0 && attacker > 0 && victim <= MaxClients && attacker <= MaxClients && IsClientInGame(victim) && IsClientInGame(attacker))
	{
		if (IsPlayerAlive(victim) && GetClientTeam(victim) == TEAM_PROP && GetClientTeam(attacker) == TEAM_HUNTER && !g_Hit[victim])
		{
			new Float:pos[3];
			GetClientAbsOrigin(victim, pos);
			PH_EmitSoundToClient(victim, "PropFound", _, SNDCHAN_WEAPON, _, _, 0.8, _, victim, pos);
			PH_EmitSoundToClient(attacker, "PropFound", _, SNDCHAN_WEAPON, _, _, 0.8, _, victim, pos);
			g_Hit[victim] = true;
		}
		else if (g_LastProp && IsPlayerAlive(attacker) && GetClientTeam(victim) == TEAM_HUNTER && GetClientTeam(attacker) == TEAM_PROP)
		{
			g_LastPropDamageTime[victim] = GetTime();
		}
	}
	
	if(weapon > MaxClients && IsValidEntity(weapon))
	{
		new String:weaponIndex[10];
		IntToString(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), weaponIndex, sizeof(weaponIndex));
		
		new Float:multiplier;
		if (GetTrieValue(g_hWeaponNerfs, weaponIndex, multiplier))
		{
			damage *= multiplier;
			return Plugin_Changed;
		}
	}
	
	//block prop drowning
	if(damagetype & DMG_DROWN && victim > 0 && victim <= MaxClients && IsClientInGame(victim) && GetClientTeam(victim) == TEAM_PROP && attacker == 0)
	{
		damage = 0.0;
		return Plugin_Changed;
	}

	// block fall damage if set
	if(GetConVarBool(g_PHPreventFallDamage) && damagetype & DMG_FALL && victim > 0 && victim <= MaxClients && IsClientInGame(victim) && attacker == 0)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock RemovePropModel (client){
	if(IsClientInGame(client) && IsPlayerAlive(client) && IsValidEntity(client))
	{
		SetVariantString("0 0 0");
		AcceptEntityInput(client, "SetCustomModelOffset");

		AcceptEntityInput(client, "ClearCustomModelRotation");
		
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		
		SetEntProp(client, Prop_Send, "m_bForcedSkin", false);
		SetEntProp(client, Prop_Send, "m_nForcedSkin", 0);
	}
}

#if defined STATS
public OnClientDisconnect(client)
{
	OCD(client);
}
#endif

public OnClientDisconnect_Post(client)
{
	ResetPlayer(client);
#if defined STATS
	OCD_Post(client);
#endif
}

stock SwitchView (target, bool:observer, bool:viewmodel){
	g_First[target] = !observer;
	
	SetVariantInt(observer ? 1 : 0);
	AcceptEntityInput(target, "SetForcedTauntCam");

	SetVariantInt(observer ? 1 : 0);
	AcceptEntityInput(target, "SetCustomModelVisibletoSelf");
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
	CReplyToCommand(client, "PropHunt Config reloaded");
	return Plugin_Handled;
}

public Action:Command_propmenu(client, args)
{
	if (!g_Enabled)
		return Plugin_Continue;
	
	if (client <= 0)
	{
		CReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	if(GetConVarInt(g_PHPropMenu) >= 0)
	{
		if(GetClientTeam(client) == TEAM_PROP && IsPlayerAlive(client))
		{
			if (GetCmdArgs() == 1)
			{
				if (CanPropChange(client))
				{
					decl String:model[PLATFORM_MAX_PATH];
					GetCmdArg(1, model, sizeof(model));
					
					if (!FileExists(model, true))
					{
						CReplyToCommand(client, "%t", "#TF_PH_PropModelNotFound");
						return Plugin_Handled;
					}
					
					new bool:restrict = true;
					
					restrict = GetConVarBool(g_PHPropMenuRestrict);
					if (restrict)
					{
						new found = false;
						
						new count = GetMenuItemCount(g_PropMenu);
						for (new i = 0; i < count; i++)
						{
							decl String:otherModel[PLATFORM_MAX_PATH];
							GetMenuItem(g_PropMenu, i, otherModel, sizeof(otherModel));
							if (strcmp(model, otherModel, false) == 0)
							{
								found = true;
								break;
							}
						}
						
						if (!found)
						{
							CReplyToCommand(client, "%t", "#TF_PH_PropMenuNotFound");
							return Plugin_Handled;
						}
					}
					g_RoundStartMessageSent[client] = false;
					strcopy(g_PlayerModel[client], sizeof(g_PlayerModel[]), model);
					RequestFrame(DoEquipProp, GetClientUserId(client));
				}
				else
				{
					CReplyToCommand(client, "%t", "#TF_PH_PropCantChange");
				}
			}
			else
			{
				if (GetClientMenu(client) == MenuSource_None)
				{
					DisplayMenu(g_PropMenu, client, MENU_TIME_FOREVER);
				}
			}
		}
		else
		{
			CReplyToCommand(client, "%t", "#TF_PH_PropMenuNotRedOrAlive");
		}
	}
	else
	{
		CReplyToCommand(client, "%t", "#TF_PH_PropMenuNoAccess");
	}
	return Plugin_Handled;
}

public Action:Command_propreroll(client, args)
{
	if (!g_Enabled)
		return Plugin_Continue;
	
	if (client <= 0)
	{
		CReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	if(GetConVarInt(g_PHReroll) >= 0)
	{
		if(GetClientTeam(client) == TEAM_PROP && IsPlayerAlive(client))
		{
			if (!g_Rerolled[client])
			{
				if (CanPropChange(client))
				{
					g_Rerolled[client] = true;
					g_PlayerModel[client] = "";
					g_RoundStartMessageSent[client] = false;
					RequestFrame(DoEquipProp, GetClientUserId(client));
				}
				else
				{
					CReplyToCommand(client, "%t", "#TF_PH_PropCantChange");
				}
			}
			else
			{
				CReplyToCommand(client, "%t", "#TF_PH_PropRerollLimit");
			}
		}
		else
		{
			CReplyToCommand(client, "%t", "#TF_PH_PropRerollNotRedOrAlive");
		}
	}
	else
	{
		CReplyToCommand(client, "%t", "#TF_PH_PropRerollNoAccess");
	}
	return Plugin_Handled;
}

public Handler_PropMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Display:
		{
			decl String:buffer[255];
			Format(buffer, sizeof(buffer), "%T", "#TF_PH_PropMenuName", param1);
			
			new Handle:panel = Handle:param2;
			SetPanelTitle(panel, buffer);
		}
		
		case MenuAction_Select:
		{
			if(IsClientInGame(param1))
			{
				if(GetConVarInt(g_PHPropMenu) == 1 || CheckCommandAccess(param1, "propmenu", ADMFLAG_KICK))
				{
					if(GetClientTeam(param1) == TEAM_PROP && IsPlayerAlive(param1))
					{
						if (CanPropChange(param1))
						{
							GetMenuItem(menu, param2, g_PlayerModel[param1], PLATFORM_MAX_PATH);
							g_RoundStartMessageSent[param1] = false;
							RequestFrame(DoEquipProp, GetClientUserId(param1));
						}
						else
						{
							CPrintToChat(param1, "%t", "#TF_PH_PropCantChange");
							new pos = GetMenuSelectionPosition();
							DisplayMenuAtItem(menu, param1, pos, MENU_TIME_FOREVER);
						}
					}
					else
					{
						CPrintToChat(param1, "%t", "#TF_PH_PropMenuNotRedOrAlive");
					}
				}
				else
				{
					CPrintToChat(param1, "%t", "#TF_PH_PropMenuNoAccess");
				}
			}
		}
		
		case MenuAction_DisplayItem:
		{
			if (!GetConVarBool(g_PHPropMenuNames))
			{
				return 0;
			}
			
			new String:model[PLATFORM_MAX_PATH];
			GetMenuItem(menu, param2, model, sizeof(model));
			
			new String:modelName[MAXMODELNAME];
			if (GetModelNameForClient(param1, model, modelName, sizeof(modelName)))
			{
				return RedrawMenuItem(modelName);
			}
		}
	}
	return 0;
}

bool:CanPropChange(client)
{
	if (!GetConVarBool(g_PHDamageBlocksPropChange))
	{
		return true;
	}
	
	if (TF2_IsPlayerInCondition(client, TFCond_OnFire) || TF2_IsPlayerInCondition(client, TFCond_Bleeding) || TF2_IsPlayerInCondition(client, TFCond_Jarated) || TF2_IsPlayerInCondition(client, TFCond_Milked))
	{
		return false;
	}
	return true;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponSwitchPost, WeaponSwitch);
	
	if (!g_Enabled)
		return;
	
	if (!IsFakeClient(client))
	{
		SendConVarValue(client, g_hArenaRoundTime, "600");
	}
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
	g_Rerolled[client] = false;
	g_CurrentlyFlaming[client] = false;
	g_FlameCount[client] = 0;
	g_LastPropDamageTime[client] = -1;
	g_RoundStartMessageSent[client] = false;
	g_bRegenerated[client] = false;
}

public Action: Command_respawn(client, args)
{
	if (!g_Enabled)
		return Plugin_Continue;
	
	if (client < 0)
	{
		CReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	TF2_RespawnPlayer(client);
	return Plugin_Handled;
}

public Action:Command_internet(client, args)
{
	if (!g_Enabled)
		return Plugin_Continue;
	
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
	
	if(GetTrieString(g_BroadcastSounds, soundid, sample, sizeof(sample)))
	{
		if (EntRefToEntIndex(g_GameRulesProxy) != INVALID_ENT_REFERENCE)
		{
			SetVariantString(sample);
			AcceptEntityInput(g_GameRulesProxy, "PlayVO");
		}
	}
	else if(GetTrieString(g_Sounds, soundid, sample, sizeof(sample)))
	{
		EmitSoundToAll(sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
	}
}

stock PH_EmitSoundToTeam(team, const String:soundid[], entity = SOUND_FROM_PLAYER, channel = SNDCHAN_AUTO, level = SNDLEVEL_NORMAL, flags = SND_NOFLAGS, Float:volume = SNDVOL_NORMAL, pitch = SNDPITCH_NORMAL, speakerentity = -1, const Float:origin[3] = NULL_VECTOR, const Float:dir[3] = NULL_VECTOR, bool:updatePos = true, Float:soundtime = 0.0)
{
	decl String:sample[128];
	
	if(GetTrieString(g_BroadcastSounds, soundid, sample, sizeof(sample)))
	{
		if (EntRefToEntIndex(g_GameRulesProxy) != INVALID_ENT_REFERENCE)
		{
			SetVariantString(sample);
			if (team == _:TFTeam_Red)
			{
				AcceptEntityInput(g_GameRulesProxy, "PlayVORed");
			}
			else if (team == _:TFTeam_Blue)
			{
				AcceptEntityInput(g_GameRulesProxy, "PlayVOBlue");
			}
			else if (team <= 0)
			{
				AcceptEntityInput(g_GameRulesProxy, "PlayVO");
			}
		}
	}
	else if(GetTrieString(g_Sounds, soundid, sample, sizeof(sample)))
	{
		new count = 0;
		new clients[MaxClients];
		
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == team)
			{
				clients[count++] = client;
			}
		}
		
		EmitSound(clients, count, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
	}
	
}


PH_EmitSoundToClient(client, const String:soundid[], entity = SOUND_FROM_PLAYER, channel = SNDCHAN_AUTO, level = SNDLEVEL_NORMAL, flags = SND_NOFLAGS, Float:volume = SNDVOL_NORMAL, pitch = SNDPITCH_NORMAL, speakerentity = -1, const Float:origin[3] = NULL_VECTOR, const Float:dir[3] = NULL_VECTOR, bool:updatePos = true, Float:soundtime = 0.0)
{
	decl String:sample[128];
	
	new bool:emitted = false;

	if(GetTrieString(g_BroadcastSounds, soundid, sample, sizeof(sample)))
	{
		emitted = EmitGameSoundToClient(client, sample, entity, flags, speakerentity, origin, dir, updatePos, soundtime);
	}

	if(!emitted && GetTrieString(g_Sounds, soundid, sample, sizeof(sample)))
	{
		EmitSoundToClient(client, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
	}
}

public Action:Command_switch(client, args)
{
	if (!g_Enabled)
		return Plugin_Continue;
	
	if (client < 0)
	{
		CReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	g_AllowedSpawn[client] = true;
	ChangeClientTeam(client, TEAM_PROP);
	TF2_RespawnPlayer(client);
	CreateTimer(0.5, Timer_Move, GetClientUserId(client));
	return Plugin_Handled;
}

public Action:Command_pyro(client, args)
{
	if (!g_Enabled)
		return Plugin_Continue;
	
	if (client < 0)
	{
		CReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	g_PlayerModel[client] = "";
	g_AllowedSpawn[client] = true;
	ChangeClientTeam(client, TEAM_HUNTER);
	TF2_RespawnPlayer(client);
	CreateTimer(0.5, Timer_Move, GetClientUserId(client));
	CreateTimer(0.8, Timer_Unfreeze, GetClientUserId(client));
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

stock bool:IsPropHuntMap ()
{
	return ValidateMap(g_Mapname);
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(!g_Enabled || g_RoundOver)
		return Plugin_Continue;
	
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_HUNTER && IsValidEntity(weapon))
	{
		if(strcmp(weaponname, "tf_weapon_flamethrower") == 0)
		{
			g_CurrentlyFlaming[client] = true;
			g_FlameCount[client] = 0;
		}
		else
			DoSelfDamage(client, weapon);
		
		result = false;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if (!g_Enabled || g_RoundOver || !g_CurrentlyFlaming[client])
	{
		return Plugin_Continue;
	}
	
	if (buttons & IN_ATTACK != IN_ATTACK)
	{
		g_CurrentlyFlaming[client] = false;
		g_FlameCount[client] = 0;
		return Plugin_Continue;
	}

	return Plugin_Continue;
}

public OnGameFrame()
{
	if (!g_Enabled || g_RoundOver)
	{
		return;
	}
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || !g_CurrentlyFlaming[client] || GetClientTeam(client) != TEAM_HUNTER || !IsPlayerAlive(client) || g_FlameCount[client]++ % FLY_COUNT != 0)
		{
			continue;
		}
		
		new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(weapon))
		{
			DoSelfDamage(client, weapon);
			AddVelocity(client, 1.0);
		}
	}
}

public WeaponSwitch(client, weapon)
{
	if (!g_Enabled || g_RoundOver || !g_CurrentlyFlaming[client])
	{
		return;
	}
	
	new String:weaponname[64];
	GetEntityClassname(weapon, weaponname, sizeof(weaponname));
	
	if(strcmp(weaponname, "tf_weapon_flamethrower") != 0)
	{
		g_CurrentlyFlaming[client] = false;
		g_FlameCount[client] = 0;
	}
}

stock DoSelfDamage(client, weapon)
{
	new Float:damage;
	new attacker = client;
	
	new String:weaponIndex[10];
	IntToString(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), weaponIndex, sizeof(weaponIndex));
	
	new String:weaponname[64];
	GetEntityClassname(weapon, weaponname, sizeof(weaponname));
	
	if (!GetTrieValue(g_hWeaponSelfDamage, weaponIndex, damage))
	{
		damage = 10.0;
	}
	
	if (g_LastProp && strcmp(weaponname, "tf_weapon_flamethrower") == 0 && g_LastPropPlayer > 0 && IsClientInGame(g_LastPropPlayer) && IsPlayerAlive(g_LastPropPlayer) && 
		g_LastPropDamageTime[client] > -1 && g_LastPropDamageTime[client] + PROP_DAMAGE_TIME >= GetTime() && damage >= GetEntProp(client, Prop_Send, "m_iHealth"))
	{
		attacker = g_LastPropPlayer;
		//weapon = 0;
	}
	
	// Attacker shouldn't be the weapon, it should be the player
	// weapon is no longer used as it caused bugs in bleed damage
	SDKHooks_TakeDamage(client, client, attacker, damage, DMG_PREVENT_PHYSICS_FORCE);
}

stock AddVelocity (client, Float:speed){
	new Float:velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

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
	if (!g_Enabled)
		return;
	
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
			if((buttons & IN_ATTACK) == IN_ATTACK && GetClientTeam(client) == TEAM_HUNTER)
			{
				g_Attacking[client] = true;
			}
			else
			{
				g_Attacking[client] = false;
			}

			if(GetClientTeam(client) == TEAM_PROP)
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
							GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
							//GetEntDataVector(client, g_iVelocity, velocity);
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
						//SetEntData(client, g_offsCollisionGroup, COLLISION_GROUP_DEBRIS_TRIGGER, _, true);
						SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS_TRIGGER);
						TF2_SetPlayerClass(client, TFClass_DemoMan, false);
						TF2_AddCondition(client, TFCond_Charging, 2.5);
						CreateTimer(2.5, Timer_Charge, GetClientUserId(client));
					}
				}
#endif
			}
			else
			if(GetClientTeam(client) == TEAM_HUNTER && TF2_GetPlayerClass(client) == TFClass_Pyro)
			{
				new shotgun = GetPlayerWeaponSlot(client, 1);
				if(IsValidEntity(shotgun))
				{
					new index = GetEntProp(shotgun, Prop_Send, "m_iItemDefinitionIndex");
					if (index == WEP_SHOTGUNPYRO || index == WEP_SHOTGUN_UNIQUE)
					{
						new ammoOffset = GetEntProp(shotgun, Prop_Send, "m_iPrimaryAmmoType");
						new clip = GetEntProp(shotgun, Prop_Send, "m_iClip1");
						SetEntProp(client, Prop_Send, "m_iAmmo", SHOTGUN_MAX_AMMO - clip, _, ammoOffset);
						if (clip > SHOTGUN_MAX_AMMO)
						{
							SetEntProp(shotgun, Prop_Send, "m_iClip1", SHOTGUN_MAX_AMMO);
						}
					}
				}
				
			}

		} // alive
	} // in game
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
	if (client <= 0)
	{
		CReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	if(IsClientInGame(client))
	{
		ShowMOTDPanel(client, "PropHunt Stats", "http://www.gamingmasters.org/prophunt/index.php", MOTDPANEL_TYPE_URL);
	}
	return Plugin_Handled;
}

public Action:Command_config(client, args)
{
	if (client == 0)
	{
		DisplayConfigToConsole(client);
	}
	else
	{
		if (GetClientMenu(client) == MenuSource_None)
		{
			DisplayMenu(g_ConfigMenu, client, MENU_TIME_FOREVER);
		}
	}
		
	return Plugin_Handled;
}

DisplayConfigToConsole(client)
{
	decl String:propMenuStatus[18];
	decl String:propRerollStatus[18];
	decl String:preventFallDamage[4];
	decl String:propChangeRestrict[4];
	decl String:airblast[4];
	decl String:propMenuRestrict[4];
	new propMenu = GetConVarInt(g_PHPropMenu);
	new propReroll = GetConVarInt(g_PHReroll);
	
	if (GetConVarBool(g_PHAirblast))
	{
		airblast = "On";
	}
	else
	{
		airblast = "Off";
	}
	
	switch (propMenu)
	{
		case -1:
		{
			propMenuStatus = "Off";
		}
		
		case 0:
		{
			propMenuStatus = "#TF_PH_Restricted";
		}
		
		case 1:
		{
			propMenuStatus = "On";
		}
	}
	
	if (GetConVarBool(g_PHPropMenuRestrict))
	{
		propMenuRestrict = "On";
	}
	else
	{
		propMenuRestrict = "Off";
	}
	
	if (GetConVarBool(g_PHDamageBlocksPropChange))
	{
		propChangeRestrict = "On";
	}
	else
	{
		propChangeRestrict = "Off";
	}
	
	switch (propReroll)
	{
		case -1:
		{
			propRerollStatus = "Off";
		}
		
		case 0:
		{
			propRerollStatus = "#TF_PH_Restricted";
		}
		
		case 1:
		{
			propRerollStatus = "On";
		}
	}
	
	if (GetConVarBool(g_PHPreventFallDamage))
	{
		preventFallDamage = "On";
	}
	else
	{
		preventFallDamage = "Off";
	}
	
	ReplyToCommand(client, "%t", "#TF_PH_ConfigName");
	ReplyToCommand(client, "---------------------");
	ReplyToCommand(client, "%t", "#TF_PH_ConfigVersion", PL_VERSION);
	ReplyToCommand(client, "%t", "#TF_PH_ConfigAirblast", airblast);
	ReplyToCommand(client, "%t", "#TF_PH_ConfigPropMenu", propMenuStatus);
	ReplyToCommand(client, "%t", "#TF_PH_ConfigPropMenuRestrict", propMenuRestrict);
	ReplyToCommand(client, "%t", "#TF_PH_ConfigPropChange", propChangeRestrict);
	ReplyToCommand(client, "%t", "#TF_PH_ConfigPropReroll", propRerollStatus);
	ReplyToCommand(client, "%t", "#TF_PH_ConfigPreventFallDamage", preventFallDamage);
	ReplyToCommand(client, "%t", "#TF_PH_ConfigSetupTime", GetConVarInt(g_PHSetupLength));
#if defined STATS
	ReplyToCommand(client, "%t", "#TF_PH_ConfigStats");
#endif
}

public Handler_ConfigMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Display:
		{
			decl String:buffer[255];
			Format(buffer, sizeof(buffer), "%T", "#TF_PH_ConfigName", param1);
			
			new Handle:panel = Handle:param2;
			SetPanelTitle(panel, buffer);
		}
		
		case MenuAction_Select:
		{
			// We really just close the menu when they select something
		}
		
		case MenuAction_DisplayItem:
		{
			decl String:infoBuf[64];
			GetMenuItem(menu, param2, infoBuf, sizeof(infoBuf));
			new String:buffer[255];
			
			if (StrEqual(infoBuf, "#version"))
			{
				Format(buffer, sizeof(buffer), "%T", "#TF_PH_ConfigVersion", param1, PL_VERSION);
			}
			else
			if (StrEqual(infoBuf, "#airblast"))
			{
				decl String:airblast[4];
				if (GetConVarBool(g_PHAirblast))
				{
					airblast = "On";
				}
				else
				{
					airblast = "Off";
				}
				
				Format(buffer, sizeof(buffer), "%T", "#TF_PH_ConfigAirblast", param1, airblast);
			}
			else
			if (StrEqual(infoBuf, "#propmenu"))
			{
				new propMenu = GetConVarInt(g_PHPropMenu);
				
				decl String:propMenuStatus[25];
				
				switch (propMenu)
				{
					case -1:
					{
						propMenuStatus = "Off";
					}
					
					case 0:
					{
						if (CheckCommandAccess(param1, "propmenu", ADMFLAG_KICK))
						{
							propMenuStatus = "#TF_PH_RestrictedAllowed";
						}
						else
						{
							propMenuStatus = "#TF_PH_RestrictedDenied";
						}
					}
					
					case 1:
					{
						propMenuStatus = "On";
					}
				}
				
				Format(buffer, sizeof(buffer), "%T", "#TF_PH_ConfigPropMenu", param1, propMenuStatus);
			}
			else
			if (StrEqual(infoBuf, "#proprestrict"))
			{
				decl String:propMenuRestrict[4];
				if (GetConVarBool(g_PHPropMenuRestrict))
				{
					propMenuRestrict = "On";
				}
				else
				{
					propMenuRestrict = "Off";
				}
				
				Format(buffer, sizeof(buffer), "%T", "#TF_PH_ConfigPropMenuRestrict", param1, propMenuRestrict);
			}
			else
			if (StrEqual(infoBuf, "#propdamage"))
			{
				decl String:propChangeRestrict[4];
				if (GetConVarBool(g_PHDamageBlocksPropChange))
				{
					propChangeRestrict = "On";
				}
				else
				{
					propChangeRestrict = "Off";
				}
				
				Format(buffer, sizeof(buffer), "%T", "#TF_PH_ConfigPropChange", param1, propChangeRestrict);
			}
			else
			if (StrEqual(infoBuf, "#propreroll"))
			{
				new propReroll = GetConVarInt(g_PHReroll);
				
				decl String:propRerollStatus[25];
				
				switch (propReroll)
				{
					case -1:
					{
						propRerollStatus = "Off";
					}
					
					case 0:
					{
						if (CheckCommandAccess(param1, "propreroll", ADMFLAG_KICK))
						{
							propRerollStatus = "#TF_PH_RestrictedAllowed";
						}
						else
						{
							propRerollStatus = "#TF_PH_RestrictedDenied";
						}
					}
					
					case 1:
					{
						propRerollStatus = "On";
					}
				}
				
				Format(buffer, sizeof(buffer), "%T", "#TF_PH_ConfigPropReroll", param1, propRerollStatus);
			}
			else
			if (StrEqual(infoBuf, "#preventfalldamage"))
			{
				decl String:preventFallDamage[4];
				if (GetConVarBool(g_PHPreventFallDamage))
				{
					preventFallDamage = "On";
				}
				else
				{
					preventFallDamage = "Off";
				}
				
				Format(buffer, sizeof(buffer), "%T", "#TF_PH_ConfigPreventFallDamage", param1, preventFallDamage);
			}
			else
			if (StrEqual(infoBuf, "#setuptime"))
			{
				Format(buffer, sizeof(buffer), "%T", "#TF_PH_ConfigSetupTime", param1, GetConVarInt(g_PHSetupLength));
			}
#if defined STATS
			else
			if (StrEqual(infoBuf, "#stats"))
			{
				Format(buffer, sizeof(buffer), "%T", "#TF_PH_ConfigStats", param1);
			}
#endif
			
			return RedrawMenuItem(buffer);
		}
	}
	return 0;
}

stock SetAlpha (target, alpha){
	SetWeaponsAlpha(target,alpha);
	SetEntityRenderMode(target, RENDER_TRANSCOLOR);
	SetEntityRenderColor(target, 255, 255, 255, alpha);
}

stock SetWeaponsAlpha (target, alpha){
	if(IsPlayerAlive(target))
	{
		// TF2 only supports 1 weapon per slot, so save time and just check all 6 slots.
		// Engy is the only class with 6 items (3 weapons, 2 tools, and an invisible builder)
		for(new i = 0; i <= 5; ++i)
		{
			new weapon = GetPlayerWeaponSlot(target, i);
			
			SetItemAlpha(weapon, alpha);
		}
	}
}

stock SetItemAlpha(item, alpha)
{
	if(item > -1 && IsValidEdict(item))
	{
		SetEntityRenderMode(item, RENDER_TRANSCOLOR);
		SetEntityRenderColor(item, 255, 255, 255, alpha);
		
		new String:classname[65];
		GetEntityClassname(item, classname, sizeof(classname));
		
		// If it's a weapon, lets adjust the alpha on its extra wearable and its viewmodel too
		if (strncmp(classname, "tf_weapon_", 10) == 0)
		{
			SetItemAlpha(GetEntPropEnt(item, Prop_Send, "m_hExtraWearable"), alpha);
			SetItemAlpha(GetEntPropEnt(item, Prop_Send, "m_hExtraWearableViewModel"), alpha);
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
	
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", clientSpeed);
	
	g_currentSpeed[client]  = clientSpeed;
}

ResetSpeed (client)
{	
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", g_currentSpeed[client]);
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	return entity != data;
}

public Action:Event_teamplay_broadcast_audio(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_Enabled)
		return Plugin_Continue;
	
	decl String:sound[64];
	GetEventString(event, "sound", sound, sizeof(sound));
	
	if (StrEqual(sound, "Announcer.AM_RoundStartRandom", false))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Event_player_team(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetEventInt(event, "team") > 1)
	{
		g_Spec[client] = false;
	}
	g_RoundStartMessageSent[client] = false;
}

public Event_arena_win_panel(Handle:event, const String:name[], bool:dontBroadcast)
{
	StopTimers();
#if defined LOG
	LogMessage("[PH] round end");
#endif

	g_RoundOver = true;
	//g_inPreRound = true;
	g_LastProp = false;
	
	if (!g_Enabled)
		return;

#if defined STATS
	new winner = GetEventInt(event, "winning_team");

	DbRound(winner);
#endif

	if (Internal_ShouldSwitchTeams())
	{
		/*
		 * Check if we need this or if classic works
		  
		new redScore;
		new bluScore;
		
		// This block is necessary because _score is always 0 for the losing team
		// even though scores aren't cleared when tf_arena_use_queue is set to 0
		if (winner == TEAM_RED)
		{
			redScore = GetEventInt(event, "red_score");
			bluScore = GetEventInt(event, "blue_score_prev");
		}
		else
		if (winner == TEAM_BLUE)
		{
			redScore = GetEventInt(event, "red_score_prev");
			bluScore = GetEventInt(event, "blue_score");
		}
		else
		{
			// Neither team wins, they both keep their previous scores
			redScore = GetEventInt(event, "red_score_prev");
			bluScore = GetEventInt(event, "blue_score_prev");
		}
		SwitchTeamScores(redScore, bluScore);

		*/

#if defined SWITCH_TEAMS
		// This is OK as arena_win_panel is fired *after* SetWinningTeam is called.
		SetSwitchTeams(true);
#else
		CreateTimer(GetConVarFloat(g_hBonusRoundTime) - TEAM_CHANGE_TIME, Timer_ChangeTeam, _, TIMER_FLAG_NO_MAPCHANGE);
#endif
	}
	
	SetConVarInt(g_hTeamsUnbalanceLimit, 0, true);

	for(new client=1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
#if defined STATS
			if(GetClientTeam(client) == winner)
			{
				AlterScore(client, 3, ScReason_TeamWin, 0);
			}
			else
			if(GetClientTeam(client) != _:TFTeam_Spectator)
			{
				AlterScore(client, -1, ScReason_TeamLose, 0);
			}
#endif
			// bit annoying when testing the plugin and/or maps on a listen server
			/*
			if(IsDedicatedServer())
			{
				team = GetClientTeam(client);
				if(team == TEAM_PROP || team == TEAM_HUNTER)
				{
					team = team == TEAM_PROP ? TEAM_HUNTER:TEAM_PROP;
					ChangeClientTeamAlive(client, team);
				}
			}
			*/
		}
		//ResetPlayer(client); // Players are now reset on round start instead of round end
	}

	SetConVarFlags(g_hTeamsUnbalanceLimit, GetConVarFlags(g_hTeamsUnbalanceLimit) & ~(FCVAR_NOTIFY));
	SetConVarInt(g_hTeamsUnbalanceLimit, UNBALANCE_LIMIT, true);
}

public Action:Timer_ChangeTeam(Handle:timer)
{
	for (new client = 1; client <= MaxClients; ++client)
	{
		if (!IsClientInGame(client))
		{
			continue;
		}
		
		if (GetClientTeam(client) == TEAM_HUNTER)
		{
			ChangeClientTeamAlive(client, TEAM_PROP);
		}
		else
		if (GetClientTeam(client) == TEAM_PROP)
		{
			RemovePropModel(client);
			ChangeClientTeamAlive(client, TEAM_HUNTER);
		}
		
	}
	return Plugin_Continue;
}

public Event_post_inventory_application(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// For whatever reason, this event is triggering after player death.
	// Block it here.
	if (client == 0 || !IsPlayerAlive(client))
	{
		return;
	}
	
#if defined LOG
	LogMessage("Doing post_inventory for %N", client);
#endif

	// In case there's an error, reset the replacementCount
	new replacementCount = g_ReplacementCount[client];
	g_ReplacementCount[client] = 0;
	
	if (replacementCount > 0)
	{
		for (new i = 0; i < replacementCount; ++i)
		{
			// DON'T require FORCE_GENERATION here, since they could pass back tf_weapon_shotgun 
			new Handle:weapon = TF2Items_CreateItem(OVERRIDE_ALL|PRESERVE_ATTRIBUTES);
			
			new String:defIndex[7];
			IntToString(g_Replacements[client][i], defIndex, sizeof(defIndex));
			
			new String:replacement[140];
			if (!GetTrieString(g_hWeaponReplacements, defIndex, replacement, sizeof(replacement)))
			{
				continue;
			}
			
			new String:pieces[5][128];
			
			ExplodeString(replacement, ":", pieces, sizeof(pieces), sizeof(pieces[]));

			TrimString(pieces[Item_Classname]);
			TrimString(pieces[Item_Index]);
			TrimString(pieces[Item_Quality]);
			TrimString(pieces[Item_Level]);
			TrimString(pieces[Item_Attributes]);
			
			new index = StringToInt(pieces[Item_Index]);
			new quality = StringToInt(pieces[Item_Quality]);
			new level = StringToInt(pieces[Item_Level]);
			TF2Items_SetClassname(weapon, pieces[Item_Classname]);
			TF2Items_SetItemIndex(weapon, index);
			TF2Items_SetQuality(weapon, quality);
			TF2Items_SetLevel(weapon, level);
			
			new attribCount = 0;
			if (strlen(pieces[Item_Attributes]) > 0)
			{
				new String:newAttribs[32][6];
				new count = ExplodeString(pieces[Item_Attributes], ";", newAttribs, sizeof(newAttribs), sizeof(newAttribs[]));
				if (count % 2 > 0)
				{
					LogError("Error parsing replacement attributes for item definition index %d", g_Replacements[client][i]);
					return;
				}
				
				for (new j = 0; j < count && attribCount < 16; j += 2)
				{
					TrimString(newAttribs[i]);
					TrimString(newAttribs[i+1]);
					new attrib = StringToInt(newAttribs[i]);
					new Float:value = StringToFloat(newAttribs[i+1]);
					TF2Items_SetAttribute(weapon, attribCount++, attrib, value);
				}
			}
			
			TF2Items_SetNumAttributes(weapon, attribCount);
			
			new item = TF2Items_GiveNamedItem(client, weapon);
			EquipPlayerWeapon(client, item);
			g_Replacements[client][i] = -1;
			CloseHandle(weapon);
		}
		
		//Players needs to be regenerated once to fix ammo counts
		if (g_bRegenerated[client])
		{
			g_bRegenerated[client] = false;
		}
		else
		{
#if defined LOG
			LogMessage("Respawning %N to correct ammo counts for weapon replacements", client);
#endif
			g_bRegenerated[client] = true;
			TF2_RegeneratePlayer(client);
		}			
	}
}

public Action:Event_teamplay_round_start_pre(Handle:event, const String:name[], bool:dontBroadcast)
{
	switch (g_RoundChange)
	{
		case RoundChange_Enable:
		{
			g_Enabled = true;
			SetCVars();
			
			UpdateGameDescription();
			g_RoundChange = RoundChange_NoChange;
			g_RoundCurrent = 0;
			
			Internal_AddServerTag();
		}
		
		case RoundChange_Disable:
		{
			g_Enabled = false;
			ResetCVars();
			
			UpdateGameDescription();
			g_RoundChange = RoundChange_NoChange;			

			Internal_RemoveServerTag();
		}
	}
	
	return Plugin_Continue;
}

public Event_teamplay_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	/*
	if (HasSwitchedTeams())
	{
		SwitchTeamScoresClassic();
	}
	*/

	StopTimers();
	
	if (!g_Enabled)
		return;

	CheckRoundTimer();
	
	g_inPreRound = true;
	g_PlayerDied = false;
	g_flRoundStart = 0.0;
	
	// This is now in round start after an issue was reported with last prop not resetting in 3.0.2
	g_LastProp = false;
	g_LastPropPlayer = 0;
	g_RoundOver = true;

	for (new client = 1; client <= MaxClients; client++)
	{
		ResetPlayer(client);	
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			// For some reason, this has to be set every round or the player GUI messes up
			SendConVarValue(client, g_hArenaRoundTime, "600");
		}
	}
	// Delay freeze by a frame
	RequestFrame(Delay_teamplay_round_start);
	
	// Arena maps should have a team_control_point_master already, but just in case...
	new ent = FindEntityByClassname(-1, "team_control_point_master");
	if (ent == -1)
	{
		ent = CreateEntityByName("team_control_point_master");
		DispatchKeyValue(ent, "targetname", "master_control_point");
		DispatchKeyValue(ent, "StartDisabled", "0");
		DispatchSpawn(ent);
	}

	//GameMode Explanation
	decl String:message[256];

	// Not sure this has to be done every round, but we'll keep it here just in case.
	
	//BLU
	Format(message, sizeof(message), "%T", "#TF_PH_BluHelp", LANG_SERVER);
	SetVariantString(message);
	AcceptEntityInput(g_GameRulesProxy, "SetBlueTeamGoalString");
	SetVariantString("2");
	AcceptEntityInput(g_GameRulesProxy, "SetBlueTeamRole");

	//RED
	Format(message, sizeof(message), "%T", "#TF_PH_RedHelp", LANG_SERVER);
	SetVariantString(message);
	AcceptEntityInput(g_GameRulesProxy, "SetRedTeamGoalString");
	SetVariantString("1");
	AcceptEntityInput(g_GameRulesProxy, "SetRedTeamRole");
}

public Delay_teamplay_round_start(any:data)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsClientObserver(i))
		{
			SetEntityMoveType(i, MOVETYPE_NONE);
		}
	}
}

public Event_teamplay_restart_round(Handle:event, const String:name[], bool:dontBroadcast)
{
	// I'm not sure what needs to be here... does teamplay_round_start get called on round restart?
}

public Event_arena_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
#if defined LOG
	LogMessage("[PH] round start - %i", g_RoundOver );
#endif

	g_inPreRound = false;
	
	if (!g_Enabled)
		return;
	
	g_inSetup = true;
	
	g_RoundCurrent++;
	
	StartTimers(true);
	
	if(g_RoundOver)
	{
		// bl4nk mentions arena_round_start, but I think he meant teamplay_round_start
		RequestFrame(Delay_arena_round_start);
		
		CreateTimer(0.1, Timer_Info);

#if defined STATS
		g_StartTime = GetTime();
#endif
	}
}

public Delay_arena_round_start(any:data)
{
	for(new client=1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(GetClientTeam(client) == TEAM_PROP)
			{
				RequestFrame(DoEquipProp, GetClientUserId(client));
				SetEntityMoveType(client, MOVETYPE_WALK);
			}
			else
			{
				RequestFrame(DoEquipHunter, GetClientUserId(client));
				if (!g_Freeze)
				{
					SetEntityMoveType(client, MOVETYPE_WALK);
				}
			}
			g_currentSpeed[client] = g_classSpeeds[TF2_GetPlayerClass(client)][0]; // Reset to default speed.
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

public Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_Enabled)
		return;
	
	new red = TEAM_PROP - 2;
	new blue = TEAM_HUNTER - 2;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Attempt to fix a bug where wrong items are being given out
	g_ReplacementCount[client] = 0;
	
	g_currentSpeed[client] = g_classSpeeds[TF2_GetPlayerClass(client)][0]; // Reset to default speed.
	
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		// stupid glitch fix
		if(!g_RoundOver && !g_AllowedSpawn[client])
		{
#if defined LOG
			LogMessage("[PH] %N spawned outside of a round");
#endif
			ForcePlayerSuicide(client);
			return;
		}
		// Wipe their model in case they were a prop last round and lived
		RemovePropModel(client);
		SDKHook(client, SDKHook_OnTakeDamage, TakeDamageHook);
		SDKHook(client, SDKHook_PreThink, PreThinkHook);
#if defined LOG
		LogMessage("[PH] Player spawn %N", client);
#endif
		g_Hit[client] = false;

		new team = GetClientTeam(client);
		if(team == TEAM_HUNTER)
		{
			if (!g_RoundStartMessageSent[client])
			{
				CPrintToChat(client, "%t", "#TF_PH_WaitingPeriodStarted");
				g_RoundStartMessageSent[client] = true;
			}
#if defined SHINX

			new TFClassType:clientClass = TF2_GetPlayerClass(client);
			if (g_classLimits[blue][clientClass] != -1 && GetClassCount(clientClass, TEAM_HUNTER) > g_classLimits[blue][clientClass])
			{
				if(g_classLimits[blue][clientClass] == 0)
				{
					// By default, this fires when they're Scout
					//CPrintToChat(client, "%t", "#TF_PH_ClassBlocked");
				}
				else
				{
					CPrintToChat(client, "%t", "#TF_PH_ClassFull");
				}

				if (g_PreferredHunterClass[client] != TFClass_Unknown && g_PreferredHunterClass[client] != clientClass)
				{
					TF2_SetPlayerClass(client, g_PreferredHunterClass[client], false);
				}
				else
				{
					TF2_SetPlayerClass(client, g_defaultClass[blue], false);
				}
				
				g_ReplacementCount[client] = 0;
				TF2_RespawnPlayer(client);
				
				return;
			}
			
			// If we didn't just change their class, store it for later
			g_PreferredHunterClass[client] = clientClass;
#else
			if(TF2_GetPlayerClass(client) != g_defaultClass[blue])
			{
				TF2_SetPlayerClass(client, g_defaultClass[blue], false);
				g_ReplacementCount[client] = 0;
				TF2_RespawnPlayer(client);
				return;
			}
#endif
			RequestFrame(DoEquipHunter, GetClientUserId(client));

		}
		else
		if(team == TEAM_PROP)
		{
			if(g_RoundOver)
			{
				SetEntityMoveType(client, MOVETYPE_NONE);
			}
			
			SetVariantString("");
			AcceptEntityInput(client, "DisableShadow");
			
			if(TF2_GetPlayerClass(client) != g_defaultClass[red])
			{
				// Last arg must be true or else you'll enter an endless loop
				TF2_SetPlayerClass(client, TFClassType:g_defaultClass[red], false);
				//ForcePlayerSuicide(client); // This is mandatory or else characters won't have their class changed
				TF2_RespawnPlayer(client);
				return;	// This was missing prior to PHR 3.3.4
			}
			// CreateTimer(0.1, Timer_DoEquip, GetClientUserId(client));
			RequestFrame(DoEquipProp, GetClientUserId(client));
		}
		else
		{
			// Players are spawning on a non-player team?
			#if defined LOG
			LogMessage("[PH] %N spawned on a non-player team: %d, slaying...", client, team);
			#endif
			ForcePlayerSuicide(client);
		}
		
		// BLU players need to be refrozen during setup time.
		if (g_inSetup && g_Freeze && team == TEAM_HUNTER)
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
		}
		else
		if (g_inPreRound)
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
		}
	}
}

public Action:Event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_Enabled || g_inPreRound)
		return Plugin_Continue;
	
	if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
	{
		// This shouldn't fire since Spy is usually disabled, but just in case...
		return Plugin_Continue;
	}

	// This should be a separate event now, but we're leaving this in just in case
	if (GetEventInt(event, "weaponid") == TF_WEAPON_BAT_FISH && GetEventInt(event, "customkill") == TF_CUSTOM_FISH_KILL)
	{
		return Plugin_Continue;
	}
	//new bool:changed = false;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_CurrentlyFlaming[client] = false;
	g_FlameCount[client] = 0;
	
	if(IsClientInGame(client) && GetClientTeam(client) == TEAM_PROP)
	{
#if defined LOG
		LogMessage("[PH] Player death %N", client);
#endif
		//RemovePropModel(client);

		CreateTimer(0.1, Timer_Ragdoll, GetClientUserId(client));

		SDKUnhook(client, SDKHook_OnTakeDamage, TakeDamageHook);
		SDKUnhook(client, SDKHook_PreThink, PreThinkHook);
	}

	if(g_inSetup && GetConVarBool(g_PHRespawnDuringSetup))
	{
#if defined LOG
		LogMessage("[PH] Respawning player %N during setup", client);
#endif

		CreateTimer(0.1, Timer_Respawn, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	
#if defined STATS
	decl String:weapon[64];
	new attackerID = GetEventInt(event, "attacker");
	new assisterID = GetEventInt(event, "assister");
	new clientID = GetEventInt(event, "userid");
	new weaponid = GetEventInt(event, "weaponid");
	GetEventString(event, "weapon", weapon, sizeof(weapon));
#endif

	if(!g_RoundOver)
		g_Spawned[client] = false;

	g_Hit[client] = false;
	
	// I would move this, but I'm not sure if it's used by STATS
	new playas = 0;
	for(new i=1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) /*&& !IsFakeClient(i)*/ && IsPlayerAlive(i) && GetClientTeam(i) == TEAM_PROP)
		{
			playas++;
		}
	}
	
	if (GetClientTeam(client) == TEAM_PROP)
	{
		if(!g_RoundOver)
		{
			PH_EmitSoundToClient(client, "PropDeath");
		}
		
		// This is to kill the particle effects from the Harvest Ghost prop and the like
		// Moved to RED-only section so we don't kill unusual effects.
		// Reference: https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/shared/particle_parse.cpp#L482
		SetVariantString("ParticleEffectStop");
		AcceptEntityInput(client, "DispatchEffect");
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
		
		// We now manually handle First Blood and avoid having the crit effect.
		// We also adjust the various sound times to be more in line with PropHunt.
		if (!g_PlayerDied && attacker != 0 && attacker != client)
		{
			// Fast is 0-30, regular is 31-90, finally is 91+
			new expendedTime = RoundToNearest(GetGameTime() - g_flRoundStart);
#if defined LOG
			LogMessage("[PH] Time to first death: %i", expendedTime);
#endif
			if (expendedTime <= 30)
			{
				PH_EmitSoundToAll("FirstBloodFast");
			}
			else if (expendedTime <= 90)
			{
				PH_EmitSoundToAll("FirstBlood");
			}
			else
			{
				PH_EmitSoundToAll("FirstBloodFinally");
			}
			
			g_PlayerDied = true;
		}

		if(!g_LastProp && playas == 2 && GetClientTeam(client) == TEAM_PROP)
		{
			g_LastProp = true;
			PH_EmitSoundToAll("OneAndOnly", _, _, SNDLEVEL_AIRCRAFT);
	#if defined SCATTERGUN
			for(new client2=1; client2 <= MaxClients; client2++)
			{
				// client who died may not show as dead to the game, so explicitly ignore them
				if(client2 != client && IsClientInGame(client2) && !IsFakeClient(client2) && IsPlayerAlive(client2))
				{
					if(GetClientTeam(client2) == TEAM_PROP)
					{
						g_LastPropPlayer = client2;
						TF2_RegeneratePlayer(client2);
					// Replaced by TF2Items_OnGiveNamedItem_Post
					//CreateTimer(0.1, Timer_WeaponAlpha, GetClientUserId(client2));
					}
					else
					if(GetClientTeam(client2) == TEAM_HUNTER)
					{
						TF2_AddCondition(client2, TFCond_Jarated, 15.0);
					}
				}
			}
	#endif
		}
	}
	
	return Plugin_Continue;
}

//////////////////////////////////////////////////////
///////////////////  TIMERS  ////////////////////////
////////////////////////////////////////////////////

public Action:Timer_Respawn(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client > 0)
	{
		g_AllowedSpawn[client] = true;
		TF2_RespawnPlayer(client);
	}
}

public Action:Timer_WeaponAlpha(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
		SetWeaponsAlpha(client, 0);
}

// This is used for the fading in of the game mode name and stuff
public Action:Timer_Info(Handle:timer)
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
				ShowSyncHudText(i, g_Text2, "By Darkimmortal, Geit, and Powerlord");
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

//public Action:Timer_DoEquipBlu(Handle:timer, any:UserId)
public DoEquipHunter(any:UserId)
{
	new client = GetClientOfUserId(UserId);
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (g_inSetup && g_Freeze)
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
		}
		else
		if(g_inPreRound)
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
		}

		SwitchView(client, false, true);
		SetAlpha(client, 255);
		
		new validWeapons;
		
		for (new i = 0; i < 3; i++)
		{
			new playerItemSlot = GetPlayerWeaponSlot(client, i);
			
			if(playerItemSlot > MaxClients && IsValidEntity(playerItemSlot))
			{
				validWeapons++;
			}
		}
		
		if(validWeapons == 0)
		{
			TF2_SetPlayerClass(client, TFClass_Pyro);
			g_AllowedSpawn[client] = true;
			TF2_RespawnPlayer(client);
		}
	}
}

//public Action:Timer_DoEquip(Handle:timer, any:UserId)
public DoEquipProp(any:UserId)
{
	new client = GetClientOfUserId(UserId);
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		//TF2_RegeneratePlayer(client);
		
#if defined LOG
		LogMessage("[PH] do equip %N", client);
#endif
		
		decl String:pname[32];
		Format(pname, sizeof(pname), "ph_player_%i", client);
		DispatchKeyValue(client, "targetname", pname);
#if defined LOG
		LogMessage("[PH] do equip_2 %N", client);
#endif
		
		new propData[PropData];
		
		// fire in a nice random model
		decl String:model[PLATFORM_MAX_PATH];
		new String:offset[32] = "0 0 0";
		new String:rotation[32] = "0 0 0";
		new skin = 0;		
		new modelIndex = -1;
		if(strlen(g_PlayerModel[client]) > 1)
		{
			model = g_PlayerModel[client];
			modelIndex = FindStringInArray(g_ModelName, model);
#if defined LOG
			LogMessage("[PH] Change \"%N\"'s user model to %s", client, model);
#endif
		}
		else
		{
			modelIndex = GetRandomInt(0, GetArraySize(g_ModelName)-1);
			GetArrayString(g_ModelName, modelIndex, model, sizeof(model));
		}
		
		// This wackiness with [0] is required when dealing with enums containing strings
		if (GetTrieArray(g_PropData, model, propData[0], sizeof(propData)))
		{
			strcopy(offset, sizeof(offset), propData[PropData_Offset]);
			strcopy(rotation, sizeof(rotation), propData[PropData_Rotation]);
		}

		if (!g_RoundStartMessageSent[client])
		{
			new String:modelName[MAXMODELNAME];
			GetModelNameForClient(client, model, modelName, sizeof(modelName));
			CPrintToChat(client, "%t", "#TF_PH_NowDisguised", modelName);
			g_RoundStartMessageSent[client] = true;
		}
		
		if (modelIndex > -1)
		{
			new String:tempOffset[32];
			new String:tempRotation[32];
			GetArrayString(g_ModelOffset, modelIndex, tempOffset, sizeof(tempOffset));
			GetArrayString(g_ModelRotation, modelIndex, tempRotation, sizeof(tempRotation));
			TrimString(tempOffset);
			TrimString(tempRotation);
			// We don't want to override the default value unless it's set to something other than "0 0 0"
			if (!StrEqual(tempOffset, "0 0 0"))
			{
				strcopy(offset, sizeof(offset), tempOffset);
			}
			if (!StrEqual(tempRotation, "0 0 0"))
			{
				strcopy(rotation, sizeof(rotation), tempRotation);
			}
			skin = GetArrayCell(g_ModelSkin, modelIndex);
		}
		
#if defined LOG
		LogMessage("[PH] do equip_3 %N", client);
#endif

#if defined LOG
		LogMessage("[PH] do equip_4 %N", client);
#endif
		// This is to kill the particle effects from the Harvest Ghost prop and the like
		SetVariantString("ParticleEffectStop");
		AcceptEntityInput(client, "DispatchEffect");
		
		g_PlayerModel[client] = model;
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetVariantString(offset);
		AcceptEntityInput(client, "SetCustomModelOffset");
		if (StrEqual(rotation, "0 0 0"))
		{
			AcceptEntityInput(client, "ClearCustomModelRotation");
		}
		else
		{
			SetVariantString(rotation);
			AcceptEntityInput(client, "SetCustomModelRotation");
		}
		SetVariantInt(1);
		AcceptEntityInput(client, "SetCustomModelRotates");
		if (skin > 0)
		{
			SetEntProp(client, Prop_Send, "m_bForcedSkin", true);
			SetEntProp(client, Prop_Send, "m_nForcedSkin", skin);
		}
		SwitchView(client, true, false);
#if defined LOG
		LogMessage("[PH] do equip_5 %N", client);
#endif
		
		if(!g_inPreRound)
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
}

public Action:Timer_Locked(Handle:timer, any:entity)
{
	for(new client=1; client <= MaxClients; client++)
	{
		if(g_RotLocked[client] && IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_PROP)
		{
			SetHudTextParamsEx(0.05, 0.05, 0.7, { /*0,204,255*/ 220, 90, 0, 255}, {0,0,0,0}, 1, 0.2, 0.2, 0.2);
			ShowSyncHudText(client, g_Text4, "PropLock Engaged");
		}
	}
}

public Action:Timer_AntiHack(Handle:timer, any:entity)
{
	new red = TEAM_PROP - 2;
	if(!g_RoundOver)
	{
		decl String:name[MAX_NAME_LENGTH];
		for(new client=1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
			{
				if (GetConVarBool(g_PHStaticPropInfo) && !IsFakeClient(client))
				{
					QueryClientConVar(client, "r_staticpropinfo", QueryStaticProp);
				}
				
				if(!g_LastProp && GetConVarBool(g_PHAntiHack) && GetClientTeam(client) == TEAM_PROP && TF2_GetPlayerClass(client) == g_defaultClass[red])
				{
					if(GetPlayerWeaponSlot(client, 1) != -1 || GetPlayerWeaponSlot(client, 0) != -1 || GetPlayerWeaponSlot(client, 2) != -1)
					{
						GetClientName(client, name, sizeof(name));
						CPrintToChatAll("%t", "#TF_PH_WeaponPunish", name);
						SwitchView(client, false, true);
						//ForcePlayerSuicide(client);
						g_PlayerModel[client] = "";
						TF2_RemoveAllWeapons(client); // This really needs to be left on
						//Timer_DoEquip(INVALID_HANDLE, GetClientUserId(client));
						RequestFrame(FixPropPlayer, GetClientUserId(client));
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

// Fix a prop player who still had weapons
// One frame shouldn't be enough to change players, but just in case...
public FixPropPlayer(any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client < 1 || GetClientTeam(client) != TEAM_PROP || g_LastProp)
		return;
	
	//TF2_RegeneratePlayer(client);
	
	TF2_RemoveAllWeapons(client);	
	
	//Timer_DoEquip(INVALID_HANDLE, userid);
	RequestFrame(DoEquipProp, userid);
}

public QueryStaticProp(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (result == ConVarQuery_Okay)
	{
		new value = StringToInt(cvarValue);
		if (value == 0)
		{
			return;
		}
		KickClient(client, "r_staticpropinfo was enabled");
		return;
	}
	KickClient(client, "r_staticpropinfo detection was blocked");
}

public Action:Timer_Ragdoll(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client < 1)
		return Plugin_Handled;
	
	new rag = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if(rag > MaxClients && IsValidEntity(rag))
	AcceptEntityInput(rag, "Kill");

	RemovePropModel(client);
	
	return Plugin_Handled;
}

public Action:Timer_Score(Handle:timer)
{
	for(new client=1; client <= MaxClients; client++)
	{
#if defined STATS
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_PROP)
		{
			AlterScore(client, 2, ScReason_Time, 0);
		}
#endif
		g_TouchingCP[client] = false;
	}
	CPrintToChatAll("%t", "#TF_PH_CPBonusRefreshed");
}

public OnSetupStart(const String:output[], caller, activator, Float:delay)
{
	g_inSetup = true;
	new Handle:event = CreateEvent("teamplay_update_timer");
	if (event != INVALID_HANDLE)
		FireEvent(event);
}

// This used to hook the teamplay_setup_finished event, but ph_kakariko messes with that
public OnSetupFinished(const String:output[], caller, activator, Float:delay)
{
	if (g_hScore != INVALID_HANDLE)
	{
		CloseHandle(g_hScore);
	}
	g_hScore = CreateTimer(55.0, Timer_Score, _, TIMER_REPEAT);
	TriggerTimer(g_hScore);
	
#if defined LOG
	LogMessage("[PH] Setup_Finish");
#endif
	g_RoundOver = false;
	g_inSetup = false;
	g_PlayerDied = false;	
	g_flRoundStart = GetGameTime();

	for(new client2=1; client2 <= MaxClients; client2++)
	{
		if(IsClientInGame(client2) && IsPlayerAlive(client2))
		{
			SetEntityMoveType(client2, MOVETYPE_WALK);
		}
	}
	CPrintToChatAll("%t", "#TF_PH_PyrosReleased");
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
		decl String:relayName[128];
		while ((ent = FindEntityByClassname(ent, "logic_relay")) != -1)
		{
			GetEntPropString(ent, Prop_Data, "m_iName", relayName, sizeof(relayName));
			if(strcmp(relayName, "hidingover", false) == 0)
			AcceptEntityInput(ent, "Trigger");
		}
	}
//	g_TimerStart = INVALID_HANDLE;
	//return Plugin_Handled;

}

#if defined CHARGE
public Action:Timer_Charge(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	new red = TEAM_PROP-2;
	if(client > 0 && IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
		TF2_SetPlayerClass(client, g_defaultClass[red], false);
	}
	return Plugin_Handled;
}
#endif

public Action:Timer_Unfreeze(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client > 0 && IsPlayerAlive(client))
		SetEntityMoveType(client, MOVETYPE_WALK);
	return Plugin_Handled;
}

public Action:Timer_Move(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client > 0)
	{
		g_AllowedSpawn[client] = false;
		if(IsPlayerAlive(client))
		{
			new rag = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
			if(IsValidEntity(rag))
			AcceptEntityInput(rag, "Kill");
			SetEntityMoveType(client, MOVETYPE_WALK);
			if(GetClientTeam(client) == TEAM_HUNTER)
			{
				RequestFrame(DoEquipHunter, GetClientUserId(client));
			}
			else
			{
				//CreateTimer(0.1, Timer_DoEquip, GetClientUserId(client));
				RequestFrame(DoEquipProp, GetClientUserId(client));
			}
		}
	}
	return Plugin_Handled;
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	// This section is to prevent Handle leaks
	static Handle:weapon = INVALID_HANDLE;
	if (weapon != INVALID_HANDLE)
	{
		CloseHandle(weapon);
		weapon = INVALID_HANDLE;
	}
	
	if (!g_Enabled)
		return Plugin_Continue;
	
	// Spectators shouldn't have their items
	if (IsClientObserver(client) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}
	
	// Block canteens and spellbooks for all players as the game will only check them ONCE
	// If they're ever shown, they will only end up in this block again if a different action item is equipped
	if (StrEqual(classname, "tf_powerup_bottle", false) || StrEqual(classname, "tf_weapon_spellbook", false))
	{
		return Plugin_Stop;
	}
	
	new team = GetClientTeam(client);
	
	if (team == TEAM_PROP)
	{
		// Taunt items have the classname "no_entity" now
		if (GetConVarBool(g_PHAllowTaunts) && StrEqual(classname, "no_entity", false))
		{
			return Plugin_Continue;
		}
		
		// If they're not the last prop, don't give them anything
		if (!g_LastProp)
		{
			return Plugin_Stop;
		}
	
		// Block wearables for Props
		// From testing, Action items still work even if you block them
		// Note: The Love and War update seems to have changed that, as taunt items won't work unless the taunt menu 
		//  was open before round start and can only be used once
		if (StrEqual(classname, "tf_wearable", false))
		{
			return Plugin_Stop;
		}

		if (FindValueInArray(g_hPropWeaponRemovals, iItemDefinitionIndex) >= 0)
		{
			return Plugin_Stop;
		}
	}

	// If they're using a blocked class, the game hasn't updated their class yet
	new TFClassType:clientClass = TF2_GetPlayerClass(client);
	if (g_classLimits[team-2][clientClass] == 0)
	{
#if defined LOG
		LogMessage("Class %d has a limit of %d on team %d, skipping.", clientClass, g_classLimits[team-2][clientClass], team);
#endif
		return Plugin_Continue;
	}
	
	new String:defIndex[7];
	IntToString(iItemDefinitionIndex, defIndex, sizeof(defIndex));
	
	new flags;	
	
	new String:replacement[140];
	new String:addAttributes[128];
	new bool:replace = GetTrieString(g_hWeaponReplacements, defIndex, replacement, sizeof(replacement));
	new bool:stripattribs = FindValueInArray(g_hWeaponStripAttribs , iItemDefinitionIndex) >= 0;
	new bool:addattribs = GetTrieString(g_hWeaponAddAttribs, defIndex, addAttributes, sizeof(addAttributes));
	new bool:removeAirblast = !GetConVarBool(g_PHAirblast) && StrEqual(classname, "tf_weapon_flamethrower");

	if (replace)
	{
		new classBits;
		
		if (!GetTrieValue(g_hWeaponReplacementPlayerClasses, defIndex, classBits))
		{
			g_Replacements[client][g_ReplacementCount[client]++] = iItemDefinitionIndex;
			return Plugin_Stop;
		}
		else
		{
			// We subtract 1 here because we're left shifting a 1, so 1 is intrinsically added to the class.
			new class = _:TF2_GetPlayerClass(client) - 1;
			if (classBits & (1 << class))
			{
				g_Replacements[client][g_ReplacementCount[client]++] = iItemDefinitionIndex;
				return Plugin_Stop;
			}
		}
		replace = false;
	}

	// If we're supposed to remove it, just block it here
	if (team == TEAM_HUNTER && FindValueInArray(g_hWeaponRemovals, iItemDefinitionIndex) >= 0)
	{
		return Plugin_Stop;
	}
	
	if (!replace && !stripattribs && !addattribs && !removeAirblast)
	{
		return Plugin_Continue;
	}
	
	new bool:weaponChanged = false;
	
	if (stripattribs)
	{
		weaponChanged = true;
	}
	else
	{
		flags |= PRESERVE_ATTRIBUTES;
	}
	
	flags |= OVERRIDE_ATTRIBUTES;
	
	weapon = TF2Items_CreateItem(flags);

	new attribCount = 0;
	// 594 is Phlogistinator and already has airblast disabled
	if (removeAirblast && (iItemDefinitionIndex != WEP_PHLOGISTINATOR || stripattribs))
	{
		TF2Items_SetAttribute(weapon, attribCount++, 356, 1.0); // "airblast disabled"
		weaponChanged = true;
	}
	
	if (addattribs)
	{
		// Pawn is dumb and this "shadows" a preceding variable despite being at a different block level
		new String:newAttribs2[32][6];
		new count = ExplodeString(addAttributes, ";", newAttribs2, sizeof(newAttribs2), sizeof(newAttribs2[]));
		if (count % 2 > 0)
		{
			LogError("Error parsing additional attributes for item definition index %d", iItemDefinitionIndex);
			return Plugin_Continue;
		}
		
		for (new i = 0; i < count && attribCount < 16; i += 2)
		{
			TrimString(newAttribs2[i]);
			TrimString(newAttribs2[i+1]);
			new attrib = StringToInt(newAttribs2[i]);
			new Float:value = StringToFloat(newAttribs2[i+1]);
			TF2Items_SetAttribute(weapon, attribCount++, attrib, value);
		}
	}
	
	if (attribCount > 0)
	{
		TF2Items_SetNumAttributes(weapon, attribCount);
		weaponChanged = true;
	}
		
	if (weaponChanged)
	{
		hItem = weapon;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

#if defined OIMM
public MultiMod_Status(bool:enabled)
{
	SetConVarBool(g_PHEnable, enabled);
}

public MultiMod_TranslateName(client, String:translation[], maxlength)
{
	Format(translation, maxlength, "%T", "#TF_PH_ModeName", client);
}
#endif

public bool:ValidateMap(const String:map[])
{
	return FindConfigFileForMap(map);
}

// These functions are based on versions taken from CS:S/CS:GO Hide and Seek
GetLanguageID(const String:langCode[])
{
	return FindStringInArray(g_ModelLanguages, langCode);
}

GetClientLanguageID(client, String:languageCode[]="", maxlen=0)
{
	decl String:langCode[MAXLANGUAGECODE];
	new languageID;
	if (client == LANG_SERVER)
	{
		languageID = GetServerLanguage();
	}
	else
	{
		languageID = GetClientLanguage(client);
	}
	
	GetLanguageInfo(languageID, langCode, sizeof(langCode));
#if defined LOG
	LogMessage("[PH] Client is using language code %s", langCode);
#endif
	// is client's prefered language available?
	new langID = GetLanguageID(langCode);
	if(langID != -1)
	{
		strcopy(languageCode, maxlen, langCode);
		return langID; // yes.
	}
	else
	{
#if defined LOG
		LogMessage("[PH] Language code \"%s\" not found.", langCode);
#endif
		GetLanguageInfo(GetServerLanguage(), langCode, sizeof(langCode));
#if defined LOG
		LogMessage("[PH] Falling back to server language code \"%s\".", langCode);
#endif
		// is default server language available?
		langID = GetLanguageID(langCode);
		if(langID != -1)
		{
			strcopy(languageCode, maxlen, langCode);
			return langID; // yes.
		}
		else
		{
#if defined LOG
			LogMessage("PH language \"%s\" not found, Falling back to \"en\".", langCode);
#endif
			// default to english
			langID = GetLanguageID("en");
			
			if (langID != -1)
			{
				strcopy(languageCode, maxlen, "en");
				return langID;
			}
			
			// english not found? happens on custom map configs e.g.
			// use the first language available
			// this should always work, since we would have SetFailState() on parse
			if(GetArraySize(g_ModelLanguages) > 0)
			{
#if defined LOG
				LogMessage("PH language \"en\" not found, Falling back to lang 0.");
#endif
				GetArrayString(g_ModelLanguages, 0, languageCode, maxlen);
				return 0;
			}
		}
	}
	// this should never happen
	return -1;
}

bool:GetModelNameForClient(client, const String:modelName[], String:name[], maxlen)
{
	if (GetConVarBool(g_PHMultilingual))
	{
		decl String:langCode[MAXLANGUAGECODE];
		
		GetClientLanguageID(client, langCode, sizeof(langCode));
#if defined LOG
		LogMessage("[PH] Retrieving %s name for %s", langCode, modelName);
#endif	
		new Handle:languageTrie;
		if (strlen(langCode) > 0 && GetTrieValue(g_PropNames, modelName, languageTrie) && languageTrie != INVALID_HANDLE && GetTrieString(languageTrie, langCode, name, maxlen))
		{
			return true;
		}
		else
		{
			strcopy(name, maxlen, modelName);
			return false;
		}
	}
	else
	{
		new propData[PropData];
		
		if (GetTrieArray(g_PropData, modelName, propData[0], sizeof(propData)))
		{
			strcopy(name, maxlen, propData[PropData_Name]);
			return true;
		}
		else
		{
			strcopy(name, maxlen, modelName);
			return false;
		}
	}
}

// Fix for weapon alphas for last prop
public TF2Items_OnGiveNamedItem_Post(client, String:classname[], itemDefinitionIndex, itemLevel, itemQuality, entityIndex)
{
	if (g_LastProp && g_LastPropPlayer == client && IsValidEntity(entityIndex))
	{
		SetItemAlpha(entityIndex, 0);
	}
}

stock bool:HasSwitchedTeams()
{
	return bool:GameRules_GetProp("m_bSwitchedTeamsThisRound");
}

SetSwitchTeams(bool:bSwitchTeams)
{
	// Note, this doesn't switch team scores... those are switched when SetWinner is called in the game
	// Also, SetWinner will override our selection here, so this must be sent AFTER arena_win_panel fires
	SDKCall(g_hSwitchTeams, bSwitchTeams);
}

// Manually switch the scores.
// The game only does this if SetWinningTeam is called with bSwitchTeams set to true.
// This is what DHooks did, but Arena confused it anyway and it only sometimes worked
stock SwitchTeamScoresClassic()
{
	new propScore = GetTeamScore(TEAM_PROP);
	new hunterScore = GetTeamScore(TEAM_HUNTER);
	
	if (propScore == 0 && hunterScore == 0)
	{
		return;
	}
	
#if defined LOG
	LogMessage("[PH] Swapping team scores: Props: %d, Hunters: %d", propScore, hunterScore);
#endif

	SetTeamScore(TEAM_PROP, hunterScore);
	SetTeamScore(TEAM_HUNTER, propScore);
}

// Only needed if SwitchTeamScoresClassic doesn't work (needs testing)
// Manually switch the scores.
// The game only does this if SetWinningTeam is called with bSwitchTeams set to true.
// This is what DHooks did, but Arena confused it anyway and it only sometimes worked
stock SwitchTeamScores(redScore, bluScore)
{
	/*
	 * Switch team scores
  	 * BLU: 2
	 * RED: 0
		
	 * To switch, REDchange should be +2, BLUchange should be -2
		
	 * 2 - 0 = REDchange = oldBLU - oldRED
	 * 0 - 2 = BLUchange = oldRED - oldBLU
	 */
	SetVariantInt(bluScore - redScore);
	AcceptEntityInput(g_GameRulesProxy, "AddRedTeamScore");
	
	SetVariantInt(redScore - bluScore);
	AcceptEntityInput(g_GameRulesProxy, "AddBlueTeamScore");
	
}

bool:FindConfigFileForMap(const String:map[], String:destination[] = "", maxlen = 0)
{
	new String:mapPiece[PLATFORM_MAX_PATH];
	
#if defined WORKSHOP_SUPPORT
	// Handle workshop maps
	if (GetFeatureStatus(FeatureType_Native, "GetMapDisplayName") == FeatureStatus_Available)
	{
		if (!GetMapDisplayName(map, mapPiece, sizeof(mapPiece)))
		{
			return false;
		}
	}
	else
	{
#endif
		strcopy(mapPiece, sizeof(mapPiece), map);
		
		if (!IsMapValid(mapPiece))
		{
			return false;
		}
#if defined WORKSHOP_SUPPORT
	}
#endif
	new String:confil[PLATFORM_MAX_PATH];
	
	// Optimization so we don't immediately rebuild the whole string after ExplodeString
	BuildPath(Path_SM, confil, sizeof(confil), "data/prophunt/maps/%s.cfg", mapPiece);
	if (FileExists(confil))
	{
		strcopy(destination, maxlen, confil);
#if defined LOG
		LogMessage("[PH] Using config file \"%s\"", confil);
#endif
		return true;
	}
	
	new String:fileParts[4][PLATFORM_MAX_PATH];
	new count = ExplodeString(mapPiece, "_", fileParts, sizeof(fileParts), sizeof(fileParts[])) - 1;
	
	while (count > 1)
	{
		mapPiece[0] = '\0';
		ImplodeStrings(fileParts, count, "_", mapPiece, sizeof(mapPiece));
		
		BuildPath(Path_SM, confil, sizeof(confil), "data/prophunt/maps/%s.cfg", mapPiece);
		
		if (FileExists(confil))
		{
			strcopy(destination, maxlen, confil);
#if defined LOG
			LogMessage("[PH] Using config file \"%s\"", confil);
#endif
			return true;
		}
		
		count--;
	}
	
	destination[0] = '\0'; // In case of decl
	return false;
}

// Natives

/*
public Native_ValidateMap(Handle:plugin, numParams)
{
	new mapLength;
	GetNativeStringLength(1, mapLength);
	
	new String:map[mapLength+1];
	GetNativeString(1, map, mapLength+1);
	
	return ValidateMap(map);
}

public Native_IsRunning(Handle:plugin, numParams)
{
	return g_Enabled;
}

public Native_GetModel(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (!IsClientInGame(client) || GetClientTeam(client) != TEAM_PROP || strlen(g_PlayerModel[client]) == 0)
	{
		return false;
	}
	
	SetNativeString(2, g_PlayerModel[client], GetNativeCell(3));
	
	return true;
}

public Native_GetModelName(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (!IsClientInGame(client) || GetClientTeam(client) != TEAM_PROP || strlen(g_PlayerModel[client]) == 0)
	{
		return false;
	}
	
	new targetClient = GetNativeCell(4);
	
	new length = GetNativeCell(3);
	new String:model[length];
	
	GetModelNameForClient(targetClient, g_PlayerModel[client], model, length);
	
	SetNativeString(2, model, length);
	return true;
}
*/

Internal_AddServerTag()
{
	new String:tags[SV_TAGS_SIZE+1];
	GetConVarString(g_hTags, tags, sizeof(tags));
	
	if (StrContains(tags, "PropHunt", false) == -1)
	{
		new String:tagArray[20][SV_TAGS_SIZE+1];
		new count = ExplodeString(tags, ",", tagArray, sizeof(tagArray), sizeof(tagArray[]));

		if (count < sizeof(tagArray))
		{
			tagArray[count] = "PropHunt";
			
			ImplodeStrings(tagArray, count+1, ",", tags, sizeof(tags));
			SetConVarString(g_hTags, tags);
		}
	}
}

Internal_RemoveServerTag()
{
	new String:tags[SV_TAGS_SIZE+1];
	GetConVarString(g_hTags, tags, sizeof(tags));
	
	if (StrContains(tags, "PropHunt", false) > -1)
	{
		new String:tagArray[20][SV_TAGS_SIZE+1];
		new count = ExplodeString(tags, ",", tagArray, sizeof(tagArray), sizeof(tagArray[]));

		for (new i = count - 1; i >= 0; i--)
		{
			TrimString(tagArray[i]);
			if (StrEqual(tagArray[i], "PropHunt", false))
			{
				count--;

				// Move all elements above this one down by one
				for (new j = i; j < count; j++)
				{
					tagArray[j] = tagArray[j+1];
				}
			}
		}
		
		ImplodeStrings(tagArray, count, ",", tags, sizeof(tags));
		SetConVarString(g_hTags, tags);
	}
	
}

// Below this point are the forward calls
// They're here so we have the code to call them organized.
/*
stock DbRound(winner)
{
	Call_StartForward(g_fStatsRoundWin);
	Call_PushCell(winner);
	Call_Finish();
}

stock AlterScore(client, SCReason:reason)
{
	Call_StartForward(g_fStatsAlterScore);
	Call_PushCell(client);
	Call_PushCell(reason);
	Call_Finish();
}

stock PlayerKilled(clientID, attackerID, assisterID, weaponid, const String:weapon[])
{
	Call_StartForward(g_fStatsPlayerKilled);
	Call_PushCell(clientID);
	Call_PushCell(attackerID);
	Call_PushCell(assisterID);
	Call_PushCell(weaponID);
	Call_PushString(weapon);
	Call_Finish();
}
*/
