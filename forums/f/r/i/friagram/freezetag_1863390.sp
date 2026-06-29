#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <sdkhooks>

#define PLUGIN_NAME     "[TF2] Freeze Tag"
#define PLUGIN_AUTHOR   "Friagram"
#define PLUGIN_VERSION  "1.1.4"  
#define PLUGIN_CONTACT  "http://steamcommunity.com/groups/poniponiponi"

#define MAXENTS         2048                                          // Maximum entities to search through when finding map logic

#define COLOR_NORMAL    255, 255, 255, 255                            // Color to return solid stuff to
#define COLOR_RED       255, 0,   128, 192                            // Color to turn stuff on the red team to
#define COLOR_BLUE      0,   128, 255, 192                            // Color to turn stuff on the blue team to
#define COLOR_TRANS     255, 255, 255, 192                            // Color to return transparent stuff to

#define MODEL_ICEBLOCK  "models/custom/freezetag/iceshard.mdl"        // Ice Model

#define MODEL_SPY       "models/player/spy.mdl"                       // Don't change this, it's for the deadringer decoy
#define SPYTICKS        66                                            // Determines how long the decoy spy lasts for. Setting this to zero would be very bad.

#define RINGHEIGHT      15                                            // Height of rings from ground
#define RINGWIDTH       5.0                                           // Thickness of large rings
#define PINGWIDTH       3.0                                           // Thickness of smaller progress rings
#define AUTORINGWIDTH   3.0                                           // Thickness of auto unfreeze progress rings
#define AUTORINGHEIGHT  23.0                                          // Height of ring from ground (in addition to RINGHEIGHT)
#define AUTORINGBRIGHT  200                                           // Final brightness of the ring fade (0-255)

#define SOUND60         "HL1/fvox/sixty.wav"                          // Although we <3 the TF2 announcer, HEV is a great change
#define SOUNDWARN       "HL1/fvox/warning.wav"
#define SOUND30         "HL1/fvox/thirty.wav"
#define SOUND10         "HL1/fvox/ten.wav"
#define SOUNDTICKLOSS   "HL1/fvox/bell.wav"
#define SOUNDTICKWIN    "HL1/fvox/blip.wav"
#define SOUNDTICKTIE    "HL1/fvox/fuzz.wav"   

#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"      // freeze sound

#define SOUND_FREEZE1	"physics/glass/glass_impact_bullet1.wav"      // unfreeze sounds
#define SOUND_FREEZE2	"physics/glass/glass_impact_bullet2.wav"
#define SOUND_FREEZE3	"physics/glass/glass_impact_bullet3.wav"

#define SOUNDJOINCLASS1 "vo/npc/Barney/ba_damnit.wav"                 // Sounds played on changing class as a warning
#define SOUNDJOINCLASS2 "vo/Streetwar/rubble/ba_damnitall.wav"

#define SOUND_REVIVE    "items/smallmedkit1.wav"                      // Played just to client on revive

#define SPEC          1               // Easier integer comparisons of teams and wins, and for sending inputs to team entities
#define RED           2
#define BLU           3
#define STALEMATE     0

#define HUDX1         0.18            // FREEZE X Position for HUD
#define HUDY1         0.02            // FREEZE Y Position for HUD

#define PLAYERXY      60              // Distance to move players from origin of other players along the X/Y axis  49
#define PLAYERZ       50              // Height to raise on second iteration set
#define STUCKDISTANCE 80              // Distance to scan for players to unstick them

#define PARTICLEZ     30              // Distance to raise unfreezing particle effect from client's origin

//////////////// Convar Variables ////////////////////////////////////////////////////////////////////////////////////// 
new Handle:g_hCvarVersion = INVALID_HANDLE;
new Handle:g_hCvarEnabled = INVALID_HANDLE;
new Handle:g_hCvarFeedback = INVALID_HANDLE;
new Handle:g_hCvarCam = INVALID_HANDLE;
new Handle:g_hCvarproxpulse = INVALID_HANDLE;
new Handle:g_hCvarForceMulti = INVALID_HANDLE;
new Handle:g_hCvarForceCap = INVALID_HANDLE;
new Handle:g_hCvarUseModel = INVALID_HANDLE;
new Handle:g_hCvarTimeLimit = INVALID_HANDLE;

new bool:g_bEnabled;                              // Is the mod enabled?
new bool:g_bFeedback;                             // Do we want to show help messages?
new g_cam;                                        // 0 - no third person, 1 - force third person, 2 - remember client prefs before freeze
new Float:g_fProximityIval;                       // Update interval for freeze beacon pulse
new Float:g_fForceMulti;                          // Damage force multiplier for pushing players
new Float:g_fForceCap;                            // Damage force cap for pushing players
new bool:g_bUseModel;                             // Use the ice model?
new g_mapTime;                                    // Length of map timer in seconds (mp_timelimit)

///////////////// File Config Variables ////////////////////////////////////////////////////////////////////////////////
new g_preRoundTime;                               // Time to allow respawning and class change
new g_roundLength;                                // Length of round timer, in seconds
new bool:g_bEliminations;                         // Allow round-end by eliminations?
new g_maxRounds;                                  // Max number of rounds to play (0 for no limit)
new Float:g_fFreezeDist;                          // Radius to unfreeze a teammate
new g_freezeDur;                                  // Seconds to unfreeze teammate
new g_openDoors;                                  // Open doors, 0 don't, 1 force open, 2 delete (setting to 0 also enables game timer, and disabled pre-round lockout)
new bool:g_bRemoveRespawnrooms;                   // Remove respawn rooms and visualizers?
new bool:g_bOpenAPs;                              // Open doors, 0 don't, 1 open Area Portals
new bool:g_bDisableCaps;                          // Block players from capping points
new bool:g_bDisableFlags;                         // Block players from capping flags
new bool:g_bDisableTrains;                        // Disable tracktrains
new Float:g_fUnfreezeHPRatioRed;                  // Percent of health to restore them with when unfrozen
new Float:g_fUnfreezeHPRatioBlue;                 // Percent of health to restore them with when unfrozen
new g_autoTimeRed;                                // Number of seconds to automatically unfreeze frozen people
new g_autoTimeBlue;                               // Number of seconds to automatically unfreeze frozen people
new Float:g_fAutoHPRatioRed;                      // Percent of health to restore them withw hen unfrozen automatically
new Float:g_fAutoHPRatioBlue;                     // Percent of health to restore them withw hen unfrozen automatically
new bool:g_bTrackDamage;                          // Ignore damage to frozen players regarding auto unfreeze or not?
new bool:g_bAllowChangeclass;                     // Allow players to change class in active rounds?

new g_proximityIter;                              // [Optimization Variable] Stores iteration count for beacons
new Float:g_fRingIval;                            // [Optimization Variable] Store ring update interval
new g_autoTimeRedMax;                             // [Optimization Variable] Number of iterations to actually do (because it's not 1 every second)
new g_autoTimeBlueMax;                            // [Optimization Variable] Number of iterations to actually do (because it's not 1 every second)

///////////////// Player Variables /////////////////////////////////////////////////////////////////////////////////////
new bool:g_bUnassigned[MAXPLAYERS+1];		  // Track New Players
new bool:g_bFrozen[MAXPLAYERS+1];	          // Track Frozen Players
new g_iceblock[MAXPLAYERS+1];                     // Track iceblock models

new Float:g_fDeathVec[MAXPLAYERS+1][3];		  // Track Death Positions
new Float:g_fDeathAng[MAXPLAYERS+1][3];		  // Track Death Angle
new Float:g_fDeathVel[MAXPLAYERS+1][3];		  // Track Death Velocity - LOL
new bool:g_bDeathDuck[MAXPLAYERS+1];              // Track Crouching State
new g_playerProx[MAXPLAYERS+1][MAXPLAYERS+1];	  // Track Nearby Players When Frozen, BIG!
new g_unfreezer[MAXPLAYERS+1];                    // Track the unfreezing client so visual-priority can be granted
new bool:autoUnfreezeDamage[MAXPLAYERS+1];        // Track if the client took damage when frozen

new bool:g_bThirdperson[MAXPLAYERS+1];            // Track client cams
new g_stuck[MAXPLAYERS+1];                        // Allow players to request being unstuck

new TFClassType:g_playerclass[MAXPLAYERS+1];      // Track player's class so they can't change in maps without respawnrooms
new TFClassType:g_futureclass[MAXPLAYERS+1];      // Track player's requested class so they can change next game
new bool:g_bJoinclasswarn[MAXPLAYERS+1];          // Warn players without advaned joinclass settings that they'll get killed
new bool:g_bInrespawnroom[MAXPLAYERS+1];          // Track if players are inside respawn rooms

//////////////// Non-Player Variables //////////////////////////////////////////////////////////////////////////////////
static const String:g_sMeter[] = "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";   // Progress Bar.. lol @ max len
static const Float:g_fCollisionvec[3] = {24.0,24.0,62.0}; // bbox for ducking player

new g_NoSprite;                                   // Temp ent for spy decoy
new g_BeamSprite;                                 // Temp ent rings
new g_HaloSprite;                                 // temp ent rings

new g_cloakOffset;                                // Spy cloak meter
new g_wearableOffset;                             // Wearables
new g_primaryOffset;                              // Primary weapon attack speed
new g_secondaryOffset;                            // Secondary weapon attack speed

new bool:g_bLateLoaded = false;

new Handle:fnGetMaxHealth;

#define MAX_RESPAWNS 64
new g_RespawnEnt[MAX_RESPAWNS];
new g_RespawnCnt;

///////////////// Scoring and Rounds ///////////////////////////////////////////////////////////////////////////////////
new g_rounds;                                     // Use this to track "waiting for players" and round limits
new g_activeround = 0;                            // Not active = 0, preround = 1, active = 2

new g_roundTimeleft;                              // Game Timer in seconds
new Handle:g_hTimeleftHUD;                        // HUD synchronizer
new Handle:g_hGametimer;                          // Keeps track of repeating game timer clock
new Float:g_fMapStartTime;                        // Stores start time of map, to calculate time of map upon round win

new g_redfrozen;                                  // Global, so we can pass them to event_round_win for mixed/multimod game modes
new g_bluefrozen;
new g_redtotal;
new g_bluetotal;

new bool:g_bWaitingforplayers;                    // Track waiting for players, so we only start rounds on full rounds
new bool:g_bArenamaptype;                         // If it's an arena map, waiting for players constantly re-triggers, and must be skipped

enum g_eWinReason                                 // Win reason identifiers
{
	WIN_UNKNOWN=0,
        TIME_TIE,
	TIME_RED,
	TIME_BLU,
	ELIM_TIE,
	ELIM_RED,
	ELIM_BLU
};
new g_eWinReason:g_eRoundWinreason;               // This gets passed to event_round_win so FT knows what's going on

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
new bool:g_bHooked = false;                       // Track hooking of game events

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_NAME,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT
};

public APLRes:AskPluginLoad2(Handle:hPlugin, bool:bLateLoad, String:sError[], iErrorSize)
{
	g_bLateLoaded = bLateLoad;
	return APLRes_Success;
}

public OnPluginStart()
{
	///////////////////////////////////////////////////////////////////////////////// CVARS//////////////////////////////////////////////////////////////////////////////////////////////////
        g_hCvarVersion = CreateConVar("sm_tf2freezetag_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);

  	HookConVarChange(g_hCvarEnabled = CreateConVar("sm_freezetag_enabled", "1.0", "Enable/Disable Freezetag Mode [0/1]", FCVAR_PLUGIN, true, 0.0, true, 1.0), ConVarEnabledChanged);
        HookConVarChange(g_hCvarFeedback = CreateConVar("sm_freezetag_feedback", "1.0", "Enable/Disable Notification Messages [0/1]", FCVAR_PLUGIN, true, 0.0, true, 1.0), ConVarFeedbackChanged);
        HookConVarChange(g_hCvarCam = CreateConVar("sm_freezetag_thirdperson", "0.0", "Disable 0, Force TP 1, Preserve 2 [0-2]", FCVAR_PLUGIN, true, 0.0, true, 2.0), ConVarCamChanged);
        HookConVarChange(g_hCvarproxpulse = CreateConVar("sm_freezetag_proxpulse", "0.2", "Update Interval For Beacons [0.1-1.0]", FCVAR_PLUGIN, true, 0.1, true, 1.0), ConVarProxPulseChanged);
        HookConVarChange(g_hCvarForceMulti = CreateConVar("sm_freezetag_forcemulti", "10.0", "Damage Force Multiplier To Push Frozen People [0-1000]", FCVAR_PLUGIN, true, 0.0, true, 100.0), ConVarForceMultiChanged);
        HookConVarChange(g_hCvarForceCap = CreateConVar("sm_freezetag_forcecap", "500.0", "Damage Force Cap To Push Frozen People [0-5000]", FCVAR_PLUGIN, true, 0.0, true, 5000.0), ConVarForceCapChanged);
        g_hCvarUseModel = CreateConVar("sm_freezetag_model", "1.0", "Enable/Disable Ice Block Model [0/1]", FCVAR_PLUGIN, true, 0.0, true, 1.0);

        HookConVarChange(g_hCvarTimeLimit = FindConVar("mp_timelimit"), ConVarTimeLimitChanged);
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	decl String:gamedir[8];
	GetGameFolderName(gamedir, 8);
	if (!StrEqual(gamedir, "tf", false) && !StrEqual(gamedir, "tf_beta", false))
	{
		SetFailState("[TF2] Freeze Tag: Freeze tag will only work for Team Fortress 2.");
        }
        
	RegAdminCmd("sm_freezetag_reloadconfigs", Command_Reloadconfigs, ADMFLAG_RCON, "Reload the Configuration File");
	RegAdminCmd("sm_freezetag_unfreeze", Command_Unfreeze, ADMFLAG_CHEATS, "Unfreeze Players in an Active Round");

	RegConsoleCmd("sm_freezetag", Command_Freezemenu);
	RegConsoleCmd("freezetag", Command_Freezemenu);

	RegConsoleCmd("stuck", Command_UnStuck);
	RegConsoleCmd("sm_stuck", Command_UnStuck);
	RegConsoleCmd("unstuck", Command_UnStuck);
	RegConsoleCmd("sm_unstuck", Command_UnStuck);

	if ((g_cloakOffset = FindSendPropInfo("CTFPlayer", "m_flCloakMeter")) == -1)                    // Spy Stealth meter
	{
		SetFailState("[TF2] Freeze Tag: Freeze tag could not locate CTFPlayer:m_flCloakMeter");
        }
	if ((g_wearableOffset = FindSendPropOffs("CTFWearable", "m_hOwnerEntity"))  == -1)              // Wearables
	{
		SetFailState("[TF2] Freeze Tag: Freeze tag could not locate CTFWearable:m_hOwnerEntity");
        }
	if ((g_primaryOffset = FindSendPropOffs("CBaseCombatWeapon","m_flNextPrimaryAttack"))  == -1)   // Weapon attack speed, thx psychonic
	{
		SetFailState("[TF2] Freeze Tag: Freeze tag could not locate CBaseCombatWeapon:m_flNextPrimaryAttack");
        }
	if ((g_secondaryOffset = FindSendPropOffs("CBaseCombatWeapon","m_flNextSecondaryAttack"))  == -1)
	{
		SetFailState("[TF2] Freeze Tag: Freeze tag could not locate CBaseCombatWeapon:m_flNextSecondaryAttack");
        }

        new Handle:hConf = LoadGameConfigFile( "sdkhooks.games" );                                      // Psychonic, calc player health
	if( hConf == INVALID_HANDLE )
	{
		SetFailState( "Cannot find sdkhooks.games gamedata" );
	}

	StartPrepSDKCall( SDKCall_Entity );
	PrepSDKCall_SetFromConf( hConf, SDKConf_Virtual, "GetMaxHealth" );
	PrepSDKCall_SetReturnInfo( SDKType_PlainOldData, SDKPass_Plain );
	fnGetMaxHealth = EndPrepSDKCall();

	if( fnGetMaxHealth == INVALID_HANDLE )
	{
		SetFailState( "Failed to set up GetMaxHealth sdkcall" );
	}
        CloseHandle( hConf );

	g_hTimeleftHUD = CreateHudSynchronizer();                                                       // HUD printout for RED/BLU frozen and Timer

        LoadTranslations("freezetag.phrases");
	LoadTranslations("common.phrases");
}

public OnMapStart()
{
        decl String:mapName[32];                                                                        // Detect if the map is arena
	GetCurrentMap(mapName, 32);

        if (strncmp(mapName, "arena_", 6) == 0)
        {
                g_bArenamaptype = true;
        }
        else
        {
                g_bArenamaptype = false; 
        }

	PrecacheSound(SOUND_FREEZE, true);
        PrecacheSound(SOUND_FREEZE1, true);
        PrecacheSound(SOUND_FREEZE2, true);
        PrecacheSound(SOUND_FREEZE3, true);

        PrecacheSound(SOUND_REVIVE, true);

        PrecacheSound(SOUND60, true);
        PrecacheSound(SOUNDWARN, true);
        PrecacheSound(SOUND30, true);
        PrecacheSound(SOUND10, true);
        PrecacheSound(SOUNDTICKWIN, true);
        PrecacheSound(SOUNDTICKLOSS, true);
        PrecacheSound(SOUNDTICKTIE, true);

        PrecacheSound(SOUNDJOINCLASS1, true);
        PrecacheSound(SOUNDJOINCLASS2, true);

        g_NoSprite = PrecacheModel("materials/overlays/no_entry.vmt", true);                             // Fading No Entry Symbol for fake spy
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt", true);                           // Temp Ent Beam
	g_HaloSprite = PrecacheModel("materials/sprites/glow01.vmt", true);                              // Temp Ent Halo

        PrecacheModel(MODEL_SPY, true);                                                                  // If this isn't precached already, you should hang yourself with an ethernet cable :P

	g_activeround = 0;
        g_rounds = 0;
        g_bWaitingforplayers = true;                                                                     // The first round is always WFP, and for arena we must assume.
        g_hGametimer = INVALID_HANDLE;

        for (new i=1; i<=MaxClients; i++)
        {
        	g_iceblock[i] = INVALID_ENT_REFERENCE;                                                   // Initialize Icelbock Array
       	}
}

public OnConfigsExecuted()
{
	new String:strVersion[16];
        GetConVarString(g_hCvarVersion, strVersion, 16);                                                 // Check existing version, and compare to our version
	if (StrEqual(strVersion, PLUGIN_VERSION) == false)
	{
		LogError("[TF2] Freeze Tag: WARNING, Your version has changed. Make sure your config file is up to date.");
	}
	SetConVarString(g_hCvarVersion, PLUGIN_VERSION);                                                 // Update version to our real verison

	g_bEnabled = GetConVarBool(g_hCvarEnabled);
        g_bUseModel = GetConVarBool(g_hCvarUseModel);                                                    // Can only do this once really, since we have to decide on adding the files

        if (g_bUseModel)                                                                                 // Will we be using the refract model?
        {
                if (PrecacheModel(MODEL_ICEBLOCK, true))                                                 // iceblock model requested, make sure server has it
	        {
                        AddFileToDownloadsTable("models/custom/freezetag/iceshard.dx80.vtx");            // v2 model files (shard)
	                AddFileToDownloadsTable("models/custom/freezetag/iceshard.dx90.vtx");
	                AddFileToDownloadsTable("models/custom/freezetag/iceshard.mdl");
	                AddFileToDownloadsTable("models/custom/freezetag/iceshard.sw.vtx");
	                AddFileToDownloadsTable("models/custom/freezetag/iceshard.vvd");
	                AddFileToDownloadsTable("materials/models/custom/freezetag/ice_tint_red.vmt");
                        AddFileToDownloadsTable("materials/models/custom/freezetag/ice_tint_blue.vmt");
                }
                else
                {
                        LogError("[TF2] Freeze Tag: WARNING, the ice model was not loaded and has been disabled. Please verify your Freeze Tag installation.");
                        g_bUseModel = false;
                }
        }

        if (g_bEnabled)
        {
		if (!g_bHooked)
		{
                	addEvents();                                                                    // Hook game events
                	g_bHooked = true;                                                               // Assume success, no need to track it all
        	}
                initializeVars();                                                                       // Get convars, clear arrays, read map settings
                PrintToServer("[TF2] Freeze Tag is Enabled!");
        }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Initialize ConVars and read values from file
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
initializeVars()
{
	unfreezeAll();                                                                          // forces all players into ready state, all timers/status will die gracefully

	///////////////////////////////// Setup Game Mode /////////////////////////////////
	SetConVarInt(FindConVar("tf_arena_use_queue"),0);                                       // Allow full server to join in arena
//	SetConVarInt(FindConVar("mp_teams_unbalance_limit"),1);                                 // Force team balancing (if they use hale or something...)
	SetConVarInt(FindConVar("tf_arena_first_blood"),0);                                     // Overpowered
	SetConVarInt(FindConVar("mp_stalemate_enable"),0);                                      // Bad things will happen if stalemate is on
	SetConVarInt(FindConVar("tf_playergib"),0);                                             // They don't technically "die"

        ///////////////////////////////// Grab ConVars ////////////////////////////////////
	g_bFeedback = GetConVarBool(g_hCvarFeedback);                                           // notification messages
	g_cam = GetConVarInt(g_hCvarCam);                                                       // third person camera settings
	g_fProximityIval = GetConVarFloat(g_hCvarproxpulse);                                    // frequency of proximity updates
	g_fForceMulti = GetConVarFloat(g_hCvarForceMulti);                                      // force multiplier
	g_fForceCap = GetConVarFloat(g_hCvarForceCap);                                          // force limit
	g_mapTime = GetConVarInt(g_hCvarTimeLimit) * 60;                                        // we need to track map time, so we can force map change for maps that have unconventional end triggers

	////////////////////// Read Available Settings From File //////////////////////////
	ReadMapConfigs();                                                                       // Load map settings from file.

        /////////////////////////////// Set Other ConVars /////////////////////////////////
	SetConVarInt(FindConVar("mp_winlimit"),g_maxRounds);                                    // Set the winlimit to round limit
	SetConVarInt(FindConVar("mp_maxrounds"),g_maxRounds);                                   // Set the maxrounds to round limit

	if(!g_mapTime && !g_maxRounds)                                                          // Because dumb.
	{
		LogMessage("[TF2] Freeze Tag: WARNING, You Have both [mp_timlimit 0] and [maxrounds 0] set, your map may never cycle!");
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Reset Gibs
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public OnPluginEnd()
{
        SetConVarInt(FindConVar("tf_playergib"),1);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Hooks game events and command listeners
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
addEvents()
{
	HookEvent("teamplay_round_start", event_round_start, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win",event_round_win, EventHookMode_PostNoCopy);
	HookEvent("player_death", event_player_death);
	HookEvent("post_inventory_application", event_post_inventory_application, EventHookMode_Post);
	HookEvent("player_changeclass", event_player_changeclass, EventHookMode_Pre);
	HookEvent("player_spawn", event_player_spawn);

	AddCommandListener(Command_InterceptSuicide, "kill");                                           // Kill + Explode
	AddCommandListener(Command_InterceptSuicide, "explode");

	AddCommandListener(Command_InterceptSwap, "spectate");                                          // Spectate + Jointeam
	AddCommandListener(Command_InterceptSwap, "jointeam");

	AddCommandListener(Command_InterceptClass, "joinclass");                                        // Class change monitoring

	AddCommandListener(Command_InterceptTaunt, "+taunt");                                           // Block Taunts
	AddCommandListener(Command_InterceptTaunt, "taunt");

	AddCommandListener(Command_InterceptItemTaunt, "+use_action_slot_item_server");
	AddCommandListener(Command_InterceptItemTaunt, "use_action_slot_item_server");

        if (g_bLateLoaded)                                                                              // Plugin was loaded late, let's hook everything we need
        {
		decl String:entname[32];
                for (new ent = 1; ent < MAXENTS; ent++)
		{
			if (IsValidEntity(ent))
                	{
				GetEntityClassname(ent, entname, 32);
				if (!strcmp(entname,"player"))
				{
                        		SDKHook(ent, SDKHook_OnTakeDamage, OnTakeDamage);               // Lol.
                        	}
		        	else if (!strcmp(entname, "trigger_hurt"))
				{
					SDKHook(ent, SDKHook_StartTouch, OnHurtTouch);
					SDKHook(ent, SDKHook_Touch, OnHurtTouch);
                        	}
		        	else if (!strcmp(entname, "trigger_capture_area"))
				{
					SDKHook(ent, SDKHook_StartTouch, OnCPTouch );
					SDKHook(ent, SDKHook_Touch, OnCPTouch);
                        	}
		        	else if (!strcmp(entname, "trigger_multiple"))
				{
					SDKHook(ent, SDKHook_StartTouch, OnDoorTouch);
					SDKHook(ent, SDKHook_Touch, OnDoorTouch);
                        	}
		        	else if (!strcmp(entname, "item_teamflag"))
				{
					SDKHook(ent, SDKHook_StartTouch, OnFlagTouch);
					SDKHook(ent, SDKHook_Touch, OnFlagTouch);
                        	}
		        	else if (!strcmp(entname, "func_respawnroom"))
				{
					SDKHook(ent, SDKHook_StartTouch, OnRespawnRoomTouch);
					SDKHook(ent, SDKHook_Touch, OnRespawnRoomTouch);
					SDKHook(ent, SDKHook_EndTouch, OffRespawnRoomTouch);
                        	}
			}
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Unhooks game events and command lsiteners
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
removeEvents()
{
	UnhookEvent("teamplay_round_start", event_round_start, EventHookMode_PostNoCopy);
	UnhookEvent("teamplay_round_win",event_round_win, EventHookMode_PostNoCopy);
	UnhookEvent("player_death", event_player_death);
	UnhookEvent("post_inventory_application", event_post_inventory_application, EventHookMode_Post);
	UnhookEvent("player_changeclass", event_player_changeclass, EventHookMode_Pre);
	UnhookEvent("player_spawn", event_player_spawn);

	RemoveCommandListener(Command_InterceptSuicide, "kill");
	RemoveCommandListener(Command_InterceptSuicide, "explode");

	RemoveCommandListener(Command_InterceptSwap, "spectate");
	RemoveCommandListener(Command_InterceptSwap, "jointeam");

	RemoveCommandListener(Command_InterceptClass, "joinclass");

	RemoveCommandListener(Command_InterceptTaunt, "+taunt");
	RemoveCommandListener(Command_InterceptTaunt, "taunt");

	RemoveCommandListener(Command_InterceptItemTaunt, "+use_action_slot_item_server");
	RemoveCommandListener(Command_InterceptItemTaunt, "use_action_slot_item_server");

	decl String:entname[32];
        for (new ent = 1; ent < MAXENTS; ent++)
	{
		if (IsValidEntity(ent))
                {
			GetEntityClassname(ent, entname, 32);
			if (!strcmp(entname,"player"))
			{
                        	SDKUnhook(ent, SDKHook_OnTakeDamage, OnTakeDamage);
                        }
		        else if (!strcmp(entname, "trigger_hurt"))
			{
				SDKUnhook(ent, SDKHook_StartTouch, OnHurtTouch);
				SDKUnhook(ent, SDKHook_Touch, OnHurtTouch);
                        }
		        else if (!strcmp(entname, "trigger_capture_area"))
			{
				SDKUnhook(ent, SDKHook_StartTouch, OnCPTouch );
				SDKUnhook(ent, SDKHook_Touch, OnCPTouch);
                        }
		        else if (!strcmp(entname, "trigger_multiple"))
			{
				SDKUnhook(ent, SDKHook_StartTouch, OnDoorTouch);
				SDKUnhook(ent, SDKHook_Touch, OnDoorTouch);
                        }
		        else if (!strcmp(entname, "item_teamflag"))
			{
				SDKUnhook(ent, SDKHook_StartTouch, OnFlagTouch);
				SDKUnhook(ent, SDKHook_Touch, OnFlagTouch);
                        }
		        else if (!strcmp(entname, "func_respawnroom"))
			{
				SDKUnhook(ent, SDKHook_StartTouch, OnRespawnRoomTouch);
				SDKUnhook(ent, SDKHook_Touch, OnRespawnRoomTouch);
				SDKUnhook(ent, SDKHook_EndTouch, OffRespawnRoomTouch);
                        }
		}
	}
	
	SetConVarInt(FindConVar("tf_playergib"),1);                     // Re-Enable Player Gibs
}

public OnClientPutInServer(client)
{
	if (g_bEnabled)
        {
                SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
                g_bUnassigned[client] = true;
        }
}

public OnClientDisconnect(client)                                                               // Kill their ice model, if they have one
{
	if (g_bUseModel && g_activeround)
	{
		destroyIceBlock(client);
	}
}

///////////////////////////////////////////////////////////////////////////////////
/////////////////////////////// CONVAR Functions //////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

public ConVarEnabledChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_bEnabled = (StringToInt(newvalue) == 0 ? false : true);                                      // Let's Make Arena More Friendly :D

        if (g_bEnabled && !g_bHooked)                                                                  // Prevent this from happening on map load
        {
                addEvents();                                                                           // Force entities to be hooked
                initializeVars();                                                                      // Get convars, clear arrays, read map settings

                g_eRoundWinreason = WIN_UNKNOWN;
                ForceTeamWin(STALEMATE);                                                               // Generate a new round
                if (g_rounds == 0)
                {
                        g_rounds = 1;
                }
                PrintToServer("[TF2] Freeze Tag is Enabled! Initiating with Late-Start!");
                g_bHooked = true;
        }
        else if (!g_bEnabled && g_bHooked)                                                             // Remove hooks to reduce overhead
        {
                if (g_activeround)                                                                     // If a round is in progress, kill it to reset modified ents
                {
                        g_eRoundWinreason = WIN_UNKNOWN;
                        ForceTeamWin(STALEMATE);                                                       // Generate a new round
                }
                unfreezeAll();                                                                         // clear for onruncmd and onconditionadded
                removeEvents();
                PrintToServer("[TF2] Freeze Tag is now Disabled!");
                g_bHooked = false;
        }
}

public ConVarFeedbackChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])          // Feedback Messages
{
	g_bFeedback = (StringToInt(newvalue) == 0 ? false : true);
}

public ConVarCamChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])               // Third Person Camera Management
{
	g_cam = StringToInt(newvalue);
}

public ConVarProxPulseChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])         // Proximity Update Interval
{
	g_fProximityIval = StringToFloat(newvalue);
	g_proximityIter = RoundToNearest(g_freezeDur/g_fProximityIval);                                // calculate the interations here, and store it to save flops.
        g_fRingIval = g_fProximityIval + 0.1;
        g_autoTimeRedMax = RoundToCeil(g_autoTimeRed/g_fProximityIval);
        g_autoTimeBlueMax = RoundToCeil(g_autoTimeBlue/g_fProximityIval);
}

public ConVarForceMultiChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])        // Damage Force Multiplier For Pushing Players
{
	g_fForceMulti = StringToFloat(newvalue);
}

public ConVarForceCapChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])          // Maximum Force That Will be Applied
{
        g_fForceCap = StringToFloat(newvalue);
}

public ConVarTimeLimitChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])         // Monitor for Map Time Changes
{
	g_mapTime = StringToInt(newvalue) * 60;

        if(!g_mapTime && !g_maxRounds)
        {
                LogMessage("[TF2] Freeze Tag: WARNING, You Have both [mp_timlimit 0] and [maxrounds 0] set, your map may never cycle!");
        }
}

///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////// USER Commands ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Allows a player to expand their proximity to be saved if knocked into an unreachable position.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Command_UnStuck(client, args)
{
        if (!client)
        {
                ReplyToCommand(client, "[Freeze]: %t","Command is in-game only");           // Console does not need to use this
                return Plugin_Handled;
	}
        if (!g_bEnabled)
        {
                PrintToChat(client, "\x04[Freeze]:\x01 %t","cmd_notenabled");
                return Plugin_Handled;
        }
        if (!IsPlayerAlive(client))
        {
                PrintToChat(client, "\x04[Freeze]:\x01 %t","Target must be alive");         // Deaders don't need to use this
                return Plugin_Handled;
	}
	if (g_activeround == 1 || GetClientTeam(client) <= SPEC)
        {
                PrintToChat(client, "\x04[Freeze]:\x01 %t","cmd_fromspec");
                return Plugin_Handled;
        }
        if (!g_bFrozen[client])
        {
                PrintToChat(client, "\x04[Freeze]:\x01 %t","cmd_notfrozen");
        }
        else if (g_stuck[client] == 0)
        {
                PrintToChat(client, "\x04[Freeze]:\x01 %t","stuck_feedback_use");
                g_stuck[client] = 1;
        }
        else if (g_stuck[client] == 1)
        {
                PrintToChat(client, "\x04[Freeze]:\x01 %t","stuck_feedback_flagged");
        }
        else
        {
                PrintToChat(client, "\x04[Freeze]:\x01 %t","stuck_feedback_cd");
        }
        
	return Plugin_Handled;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Command to force the map configs to be immediately updated from the configuration file
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Command_Reloadconfigs(client, args)
{
        ReadMapConfigs();
        ReplyToCommand(client, "[Freeze]: %t","cmd_reloadcfg");

	return Plugin_Handled;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Command to unfreeze target player(s) as if they were unfrozen by a teammate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Command_Unfreeze(client, args)
{
	if (!g_bEnabled)
        {
                ReplyToCommand(client, "\x04[Freeze]:\x01 %t","cmd_notenabled");
                return Plugin_Handled;
        }

        new String:arg1[32];

	GetCmdArg(1, arg1, sizeof(arg1));

	if (args == 0)
	{
		ReplyToCommand(client, "[Freeze] Usage: sm_freezetag_unfreeze <target>");
		return Plugin_Handled;
	}

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1,client,target_list,MAXPLAYERS,COMMAND_FILTER_ALIVE,target_name,sizeof(target_name),tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

        for (new i = 0; i < target_count; i++)
	{
                if (g_bFrozen[target_list[i]])
                {                                                                                      // unfreezeClient(client, other, bool:automatic=false, bool:sound=true, bool:particles=true, bool:respawn=false)
                	unfreezeClient(target_list[i],target_list[i],_,false,false);                   // if they do @all it could produce too many sounds and particles
                }
        }

	return Plugin_Handled;
}

///////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////// Info Menu /////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Command to provide root menu to client
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Command_Freezemenu(client, args)
{
        if (!client)
        {
                ReplyToCommand(client, "[Freeze]: %t","Command is in-game only");           // Console does not need to use this
                return Plugin_Handled;
	}
	if (!g_bEnabled)
        {
                PrintToChat(client, "\x04[Freeze]:\x01 %t","cmd_notenabled");
                return Plugin_Handled;
        }

	Help_ShowMainMenu(client);

	return Plugin_Handled;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Displays root menu to client
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Help_ShowMainMenu(client)
{
        new Handle:menu = CreateMenu(Help_MainMenuHandler);
	SetMenuExitBackButton(menu, false);

	SetMenuTitle(menu, "                 Freeze Tag %s", PLUGIN_VERSION);

	AddMenuItem(menu, "rules",    "Rules & Gameplay");
	AddMenuItem(menu, "tips",     "Tips & Tricks");
        AddMenuItem(menu, "weapons",  "Weapon Changes");
        AddMenuItem(menu, "commands", "Commands");
        AddMenuItem(menu, "settings", "Game Settings");
        AddMenuItem(menu, "settings", "Entity Settings");
        AddMenuItem(menu, "credits",  "Special Thanks");

	DisplayMenu(menu, client, 30);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Generates menu text based upon client selection
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Help_MainMenuHandler(Handle:menu, MenuAction:action, param1, param2)     // Just a info menu panel that shows rules, about info, etc.
{                                                                               // Would need to completely re-do this for translations because of bizarre spacing
	if (action == MenuAction_End)
        {
		CloseHandle(menu);
	}
        else if (action == MenuAction_Select)
	{
                new Handle:cpanel = CreatePanel();
                if (param2 == 0)
                {
                        SetPanelTitle(cpanel, "Rules:");
                        DrawPanelText(cpanel, " ");

                        DrawPanelText(cpanel, "Kill an enemy to freeze them in place and disable them.\nTo revive a frozen teammate, stand within their aura.\nIf enabled, frozen players will revive automatically over time.\nBonked, Cloaked, or Invisible players may not revive.\nA team wins by elimination if all members of the opposing team are frozen.\nIf time expires, the team with the higher ratio of non-frozen players wins." );
                }
                else if (param2 == 1)
                {
                        SetPanelTitle(cpanel, "Tips:");
                        DrawPanelText(cpanel, " ");

                        DrawPanelText(cpanel, "Attack frozen enemies to push them around the map and gain control.\nCrouch while attacking enemies at close range to knock them out of corners.\nAttack frozen enemies to prevent enemy teammates from reviving them.\nDamage frozen enemies to prevent them from automatically reviving.\nHide behind frozen teammates while reviving them or fighting to block damage.\nRevive your teammates when possible to overwhelm the enemy." );
                }
                else if (param2 == 2)
                {
                        SetPanelTitle(cpanel, "Weapon Info:");
                        DrawPanelText(cpanel, " ");

                        DrawPanelText(cpanel, "Cloak and Dagger:       Replaced with Watch." );
                        DrawPanelText(cpanel, "Eureka Effect:              Replaced with Wrench." );
                        DrawPanelText(cpanel, "Holiday Punch:            Replaced with Fists." );
                        DrawPanelText(cpanel, "Phlogistinator:            50% damage protection, provides mini-crits." );
                        DrawPanelText(cpanel, "Ubersaw:                     Taunt disabled." );
                }
                else if (param2 == 3)
                {
                        SetPanelTitle(cpanel, "Commands:");
                        DrawPanelText(cpanel, " ");

                        DrawPanelText(cpanel, "/stuck       If you become stuck outside of the map while frozen, type /stuck.\n                 You will be revived in your spawn room, frozen and will incur a minor\n                 health penalty upon revival for the rest of the map\n                 May only be used once per round.\n" );
                        DrawPanelText(cpanel, "/freezetag                           Help menu and information." );


                        DrawPanelText(cpanel, "/freezetag_unfreeze           Unfreezes a player (Admin Only)." );
                        DrawPanelText(cpanel, "/freezetag_reloadconfigs   Reloads map configs (Admin Only)." );
                }
                else if (param2 == 4)
                {
                        SetPanelTitle(cpanel, "Game Settings:");
                        decl String:buffer[50];
                        DrawPanelText(cpanel, " ");

	                if (g_preRoundTime)
                        {
                                Format(buffer, 50,     "Preround Length:  [%i Sec]", g_preRoundTime);
                                DrawPanelText(cpanel, buffer);
                        }
                        if (g_roundLength)
	                {
                                Format(buffer, 50,     "Round Length:  [%i Sec]", g_roundLength);
                                DrawPanelText(cpanel, buffer);
                        }
                        if (g_maxRounds)
                        {
                                Format(buffer, 50,     "Round Limit:  [%i]", g_maxRounds);
                                DrawPanelText(cpanel, buffer);
                        }
	                DrawPanelText(cpanel, (g_fForceMulti*g_fForceCap ? "Damage Force Push:  [Enabled]" : "Damage Force Push:  [Disabled]") );  // Force push
	                Format(buffer, 50,     "Unfreeze Duration:  [%i Sec]", g_freezeDur);
	                DrawPanelText(cpanel, buffer);
	                Format(buffer, 50,     "Red Unfreeze Health:  [%i%%]", RoundFloat(g_fUnfreezeHPRatioRed*100) );
                        DrawPanelText(cpanel, buffer);
	                Format(buffer, 50,     "Blue Unfreeze Health:  [%i%%]", RoundFloat(g_fUnfreezeHPRatioBlue*100) );
                        DrawPanelText(cpanel, buffer);
	                if (g_autoTimeRed)
                        {
                                Format(buffer, 50,     "Red Auto Unfreeze Time:  [%i Sec]", g_autoTimeRed);
                                DrawPanelText(cpanel, buffer);
	                        if (g_fAutoHPRatioRed)
                                {
                                        Format(buffer, 50,     "Red Auto Unfreeze Health:  [%i%%]", RoundFloat(g_fAutoHPRatioRed*100) );
                                        DrawPanelText(cpanel, buffer);
                                }
                                else
                                {
                                        DrawPanelText(cpanel, "Red Auto Unfreeze:  [Respawns Player]");
                                }
                        }
                        else
                        {
                                DrawPanelText(cpanel, "Red Self Unfreeze:  [Disabled]");
                        }
	                if (g_autoTimeBlue)
                        {
                                Format(buffer, 50,     "Blue Auto Unfreeze Time:  [%i Sec]", g_autoTimeBlue);
                                DrawPanelText(cpanel, buffer);
	                        if (g_fAutoHPRatioBlue)
                                {
                                        Format(buffer, 50,     "Blue Auto Unfreeze Health:  [%i%%]", RoundFloat(g_fAutoHPRatioBlue*100) );
                                        DrawPanelText(cpanel, buffer);
                                }
                                else
                                {
                                        DrawPanelText(cpanel, "Blue Auto Unfreeze:  [Respawns Player]");
                                }
                        }
                        else
                        {
                                DrawPanelText(cpanel, "Blue Auto Unfreeze Time:  [Disabled]");
                        }
                        DrawPanelText(cpanel, (g_bTrackDamage ? "Damage Resets Auto Unfreeze:  [Yes]" : "Damage Resets Auto Unfreeze:  [No]") );
                        DrawPanelText(cpanel, (g_bAllowChangeclass ? "Change Class On Unfreeze:  [Yes]" : "Change Class On Unfreeze:  [No]") );
	                Format(buffer, 50,     "Unfreeze Radius:  [%i Units]", RoundFloat(g_fFreezeDist));
                        DrawPanelText(cpanel, buffer);
                        DrawPanelText(cpanel, (g_bEliminations ? "Elimination Wins:  [Yes]" : "Elimination Wins:  [No]") );
                        DrawPanelText(cpanel, (g_bFeedback ? "Feedback Messages:  [On]" : "Feedback Messages:  [Off]") );
                }
                else if (param2 == 5)
                {
                        SetPanelTitle(cpanel, "Entity Settings:");
                        DrawPanelText(cpanel, " ");

	                DrawPanelText(cpanel, (g_bDisableCaps ? "Capture Points:  [Off]" : "Capture Points:  [On]") );
                        DrawPanelText(cpanel, (g_bDisableFlags ? "Capture The Flag:  [Off]" : "Capture The Flag:  [On]") );
	                if(g_openDoors == 0)
	                {
                                DrawPanelText(cpanel, "Doors:  [Unchanged]" );
                        }
                        else if(g_openDoors == 1)
	                {
                                DrawPanelText(cpanel, "Doors:  [Forced Open]" );
                        }
                        else
	                {
                                DrawPanelText(cpanel, "Doors:  [Removed]" );
                        }
                        DrawPanelText(cpanel, (g_bRemoveRespawnrooms ? "Respawn Rooms:  [Off]" : "Respawn Rooms:  [On]") );
                        DrawPanelText(cpanel, (g_bDisableTrains ? "Tank Trains:  [Off]" : "Tank Trains:  [On]") );
	                DrawPanelText(cpanel, (g_bOpenAPs ? "Area Portals:  [Forced Open]" : "Area Portals:  [Unchanged]") );
                }
                else if (param2 == 6)
                {
                        decl String:buffer[40];
                        Format(buffer, 40, "%s %s by %s",PLUGIN_NAME,PLUGIN_VERSION,PLUGIN_AUTHOR);

                        SetPanelTitle(cpanel, buffer);
                        DrawPanelText(cpanel, " ");

                        DrawPanelText(cpanel, "Special Thanks:");
                        DrawPanelText(cpanel, " ");
                        DrawPanelText(cpanel, "Little Hero Dood, Sh4rk3y, Ryojin, Tindall, Aer, & rd1981\n    For many hours of testing and help with bugfixes." );
                        DrawPanelText(cpanel, " ");
                        DrawPanelText(cpanel, "The PoniPoniPoni Community\n    For using this mod, and providing feedback." );
                        DrawPanelText(cpanel, PLUGIN_CONTACT );
                }

                for (new j = 0; j < 7; ++j)
		DrawPanelItem(cpanel, " ", ITEMDRAW_NOTEXT);
		DrawPanelText(cpanel, " ");
		DrawPanelItem(cpanel, "Back", ITEMDRAW_CONTROL);

	        SendPanelToClient(cpanel, param1, Help_MenuHandler, 45);
	        CloseHandle(cpanel);
        }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Dloses menu or returns to previous menu
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Help_MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
        {
		CloseHandle(menu);
	}
        else if (menu == INVALID_HANDLE && action == MenuAction_Select)
        {
		Help_ShowMainMenu(param1);
	}
        else if (action == MenuAction_Cancel)
        {
		if (param2 == MenuCancel_ExitBack)
			Help_ShowMainMenu(param1);
	}
}

///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// Entity Control ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

public OnEntityCreated(ent, const String:strClassname[])
{
        if (g_bEnabled)                                                      // These ents spawn each round, if we toggle enabled it will find new ones and hook
        {
		if (StrEqual( strClassname, "trigger_hurt", false ))
		{
			SDKHook(ent, SDKHook_StartTouch, OnHurtTouch);
			SDKHook(ent, SDKHook_Touch, OnHurtTouch);
		}
		else if (StrEqual(strClassname, "trigger_capture_area", false ))
		{
			SDKHook(ent, SDKHook_StartTouch, OnCPTouch );
			SDKHook(ent, SDKHook_Touch, OnCPTouch );
		}
		else if (StrEqual(strClassname, "trigger_multiple", false ))
		{
			SDKHook(ent, SDKHook_StartTouch, OnDoorTouch);
			SDKHook(ent, SDKHook_Touch, OnDoorTouch);
		}
		else if (StrEqual( strClassname, "item_teamflag", false ))
		{
			SDKHook(ent, SDKHook_StartTouch, OnFlagTouch);
			SDKHook(ent, SDKHook_Touch, OnFlagTouch);
		}
		else if (StrEqual( strClassname, "func_respawnroom", false ))
		{
			SDKHook(ent, SDKHook_StartTouch, OnRespawnRoomTouch);
			SDKHook(ent, SDKHook_Touch, OnRespawnRoomTouch);
			SDKHook(ent, SDKHook_EndTouch, OffRespawnRoomTouch);
		}
		else if (g_activeround && StrEqual( strClassname, "tf_ragdoll", false ))       // destroy all ragdolls in the game, we won't be having any of that.
		{
			CreateTimer(0.0, Timer_RemoveEntity, EntIndexToEntRef(ent));
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Track Clients entering and touching respawn rooms
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public OnRespawnRoomTouch(respawn, client)
{
        if (g_activeround && client > 0 && client <= MaxClients)
	{
                if (GetEntProp(respawn,Prop_Send, "m_iTeamNum") == GetClientTeam(client))      // Bah, Powerlord was right.
                {
                        g_bInrespawnroom[client] = true;
                }
        }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Track Clients exiting respawn rooms
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public OffRespawnRoomTouch(hurt, client)
{
        if (g_activeround && client > 0 && client <= MaxClients)
	{
                g_bInrespawnroom[client] = false;
        }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Track Clients touching hurt triggers so that they can be teleported back to spawn points
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:OnHurtTouch(hurt, client)
{
        if (g_activeround && client > 0 && client <= MaxClients && g_bFrozen[client] )
	{                                                                    // If Mod disabled do nothing
                SendToSpawnPoint(client);
		return Plugin_Handled;
        }

        return Plugin_Continue;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Blocks players from using control points/capture zones if frozen or disabled
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:OnCPTouch(point, client)
{
        if (!g_bDisableCaps && client > 0 && client <= MaxClients && !g_bFrozen[client])
        {
                return Plugin_Continue;
        }
                                                                            // Allow capping, but don't allow frozen players to cap
        return Plugin_Handled;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Prevents doors from opening and closing by blocking trigger_multiple entities
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:OnDoorTouch(door, client)
{
	if (g_openDoors == 1 && g_activeround)                              // If Mod disabled do nothing
	{                                                                   // If door forcing enabled, disable door triggers
                return Plugin_Handled;
 	}

        return Plugin_Continue;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Prevents players from using the intelligence briefcase (flags) if frozen or disabled
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:OnFlagTouch(flag, client)                                     // Control Flag Events
{
        if (!g_bDisableFlags && client > 0 && client <= MaxClients && !g_bFrozen[client])// Allow capping, but don't allow frozen players to cap
        {
                return Plugin_Continue;
        }

        return Plugin_Handled;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Removes func_respawnroom and func_respawnroomvisualizer entities
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
removeRespawnrooms()
{
	new ent = MaxClients+1;
	while ((ent = FindEntityByClassname2(ent, "func_respawnroom")) != -1)                             // Entity may be hooked, but I don't think that matters
	{                                                                                                 // If bots are enabled, it will bitch about pathing, but it's ok.
		AcceptEntityInput(ent, "Kill");                                                           // Can't seem to block it's function with plugin_handled
	}
	ent = MaxClients+1;
	while ((ent = FindEntityByClassname2(ent, "func_respawnroomvisualizer")) != -1)                   // No spawn protection
	{
		AcceptEntityInput(ent, "Kill");
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Removes and modifies many gameplay entities based on loaded settings
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
removeGameplayEnts()
{
	decl String:entname[32];
        for (new ent = 1; ent < MAXENTS; ent++)
	{
		if (IsValidEntity(ent))
                {
			GetEntityClassname(ent, entname, 32);
			if (!strcmp(entname,"func_regenerate"))                                                         // Destroy Regenration Triggers, Sentry Immunity Bugs This Anyway
			{
                        	AcceptEntityInput(ent, "Kill");
                        }
		        else if (g_bOpenAPs && !strcmp(entname, "func_areaportal"))                                     // Open Area Portals
			{
                                AcceptEntityInput(ent,"Open");
                        }
		        else if (g_openDoors && !strcmp(entname, "func_door"))
			{
                                if(g_openDoors == 1)                                                                    // Open Doors Cleanly
                                {
			                AcceptEntityInput(ent, "Unlock");
                                        AcceptEntityInput(ent, "Open");
                                }
                                else
                                {
                                        AcceptEntityInput(ent, "Kill");                                                 // Delete Doors
                                }
                        }
		        else if (g_openDoors == 1 && !strcmp(entname, "filter_activator_tfteam"))
			{
			        SetVariantInt(0);
                	        AcceptEntityInput(ent,"SetTeam");                                                       // Make Triggers Work for Both Teams (Perhaps not needed if we also do trigger_multiples)
                        }
		        else if (!strcmp(entname, "prop_dynamic"))
			{
				decl String:modelname[64];
                		GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 64);
                		if (strcmp(modelname,"models/props_gameplay/resupply_locker.mdl") == 0 ||
                    	            strcmp(modelname,"models/props_medieval/medieval_resupply.mdl") == 0)
                		{
                			AcceptEntityInput(ent,"Kill");                                                  // Remove Resupply Locker Props
                		}
                		else if (g_openDoors &&
                        		(strcmp(modelname,"models/props_well/main_entrance_door.mdl") == 0))
                		{
                        		AcceptEntityInput(ent,"Kill");                                                  // Hydro hides well doors rather than animates it, and it uses vphysics
                		}
                		else if (g_openDoors &&
                        		(strcmp(modelname,"models/props_gameplay/door_slide_large_dynamic.mdl") == 0 ||
                         		 strcmp(modelname,"models/props_medieval/door_slide_small_dynamic.mdl") == 0))
                			{
                        			SetVariantString("Open");                                               // Set stupid door models to open state, if forced or deleted
                        			AcceptEntityInput(ent,"SetAnimation");
                			}
                		else if (g_bDisableCaps && strcmp(modelname,"models/props_gameplay/cap_point_base.mdl") == 0)
               			{
                			AcceptEntityInput(ent,"Kill");                                                  // Remove Control Point Models
                		}
                        }
		        else if (g_bDisableCaps && !strcmp(entname, "team_control_point"))
			{
			        SetVariantInt(1);                                                                       // Lock Control Points, So People Won't Look for Them
			        AcceptEntityInput(ent, "SetLocked");
                                AcceptEntityInput(ent, "HideModel");
                                SetVariantInt(600);                                                                     // Set Unlocking Time Arbitrarily High, so They Wont' Become Active Mid-Game
                                AcceptEntityInput(ent, "SetUnlockTime");
                        }
		        else if (g_bDisableCaps && !strcmp(entname, "prop_physics"))
			{
		                decl String:modelname[64];
                                GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 64);
                                if(g_bDisableCaps &&
                                  (strcmp(modelname,"models/props_trainyard/bomb_cart.mdl") == 0 ||
                                   strcmp(modelname,"models/props_trainyard/bomb_cart_red.mdl") == 0))
                                {
                	                AcceptEntityInput(ent,"Kill");                                                  // Remove Bomb-Cart Props
                                }
                        }
		        else if (g_bDisableFlags && !strcmp(entname, "item_teamflag"))
			{
                                AcceptEntityInput(ent, "Kill");                                                         // Remove Team Flags
                        }
		        else if (g_bDisableTrains && !strcmp(entname, "func_tracktrain"))
			{
                                AcceptEntityInput(ent, "Kill");                                                         // Remove Bomb Carts, Ghosts, and parented stuff
                        }
		}
	}
}

///////////////////////////////////////////////////////////////////////////////////
////////////////////////////////// Event Hooks  ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

public event_player_changeclass(Handle:event, const String:name[], bool:dontBroadcast)
{
        if (g_activeround == 2)                                                                 // If they are trying to pick a new class and a game is already in progress, save it
        {
                new client = GetClientOfUserId(GetEventInt(event, "userid"));
	        if (!g_bRemoveRespawnrooms && g_bInrespawnroom[client])
	        {
                        g_playerclass[client] = TFClassType:GetEventInt(event,"class");         // They are in an active respawn room, so their class got changed, set this to their class
                }
                else
                {
                        g_futureclass[client] = TFClassType:GetEventInt(event, "class");        // Their class was not changed, but they selected something, so save their preference
                }
        }
}

public event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!g_activeround)
	{
		if (g_futureclass[client] != TFClass_Unknown)                                   // If the player has a class selection queued, do it
		{
			switch(g_futureclass[client])                                           // Maintain compliance with class-limit enforcer plugins, by using joinclass isntead of forcing the change
			{
				case TFClass_DemoMan:  FakeClientCommand(client,"joinclass demoman");
				case TFClass_Engineer: FakeClientCommand(client,"joinclass engineer");
				case TFClass_Heavy:    FakeClientCommand(client,"joinclass heavyweapons");
				case TFClass_Medic:    FakeClientCommand(client,"joinclass medic");
				case TFClass_Pyro:     FakeClientCommand(client,"joinclass pyro");
				case TFClass_Scout:    FakeClientCommand(client,"joinclass scout");
				case TFClass_Sniper:   FakeClientCommand(client,"joinclass sniper");
				case TFClass_Soldier:  FakeClientCommand(client,"joinclass soldier");
				case TFClass_Spy:      FakeClientCommand(client,"joinclass spy");
			}
			g_futureclass[client] = TFClass_Unknown;                                // :D
                }
	}
}

public TF2_OnWaitingforplayersStart()
{
        if (!g_bArenamaptype)
        {
                g_bWaitingforplayers = true;
        }
}

public TF2_OnWaitingForPlayersEnd()
{
        g_bWaitingforplayers = false;
}

CacheSpawnPoints()
{
	g_RespawnCnt = 0;
        new ent = MaxClients+1;
        while (g_RespawnCnt < MAX_RESPAWNS && ((ent = FindEntityByClassname2(ent, "info_player_teamspawn")) != -1))
	{
		g_RespawnEnt[g_RespawnCnt] = EntIndexToEntRef(ent);                                       // store entity
                g_RespawnCnt++;
	}
}

SendToSpawnPoint(client)
{
        new team = GetClientTeam(client);
        for(new i=0; i<g_RespawnCnt; i++)
        {
                new spawnpoint = EntRefToEntIndex(g_RespawnEnt[i]);
                if(spawnpoint != INVALID_ENT_REFERENCE)
                {
                        if(GetEntProp(spawnpoint,Prop_Send, "m_iTeamNum") == team)     // try to put them at their first team owned spawnpoint
                        {
                                decl Float:spawnpointpos[3];
                                GetEntPropVector(spawnpoint, Prop_Send, "m_vecOrigin", spawnpointpos);
                                TeleportEntity(client, spawnpointpos, NULL_VECTOR, NULL_VECTOR);
                                return;
                        }
                }

        }
        
        for(new i=0; i<g_RespawnCnt; i++)
        {
                new spawnpoint = EntRefToEntIndex(g_RespawnEnt[i]);
                if(spawnpoint != INVALID_ENT_REFERENCE)
                {
                        if(GetEntProp(spawnpoint,Prop_Send, "m_iTeamNum") == 0)       // try to put them at the first shared spawnpoint
                        {
                                decl Float:spawnpointpos[3];
                                GetEntPropVector(spawnpoint, Prop_Send, "m_vecOrigin", spawnpointpos);
                                TeleportEntity(client, spawnpointpos, NULL_VECTOR, NULL_VECTOR);
                                return;
                        }
                }

        }

        return;
}

public event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
        if (g_hGametimer != INVALID_HANDLE)
        {
                KillTimer(g_hGametimer);
                g_hGametimer = INVALID_HANDLE;                                                            // Prevent duplicate timers from existing
        }

        if (g_rounds == 1)
        {
                g_fMapStartTime = GetGameTime();                                                          // Store the game start timer, it should be accurate here

		if (g_bFeedback)                                                                          // Info Message on first round
		{
                	PrintToChatAll("\x04[Freeze]:\x01 %t","feedback_welcomemsg");
		}
        }

        if (g_rounds && !g_bWaitingforplayers)                                                            // Disable on first round / waiting for players
        {
                g_activeround = 1;                                                                        // Set to active
                unfreezeAll();                                                                            // Clear Frozen array

                CacheSpawnPoints();

                if (g_bUseModel)
                {
                        destroyIceBlock(_,true);                                                          // Clear all lingering ice models (there should not be any at this point)
                }

                removeGameplayEnts();                                                                     // Force doors, remove cabinets, etc
                modifyGameTimer();                                                                        // Modify the Game Timer

                for (new i=1; i<=MaxClients; i++)
                {
		        if (IsClientInGame(i) && IsPlayerAlive(i))
		        {
                                SetEntProp(i, Prop_Send, "m_bGlowEnabled", 0);                            // Turn off glow if they still have it
                                SetEntityRenderMode(i, RENDER_NORMAL);                                    // Just in case
                                SetEntityRenderColor(i, COLOR_NORMAL);                                    // Just in case
                        }
                }
                if (g_preRoundTime)
                {
                        CreateTimer(float(g_preRoundTime), Timer_PreRoundEnd, _, TIMER_FLAG_NO_MAPCHANGE);           // End the Pre-Round State, Start the Game... Derp
                }
                else                                                                                                 // Pre-Round is Disabled, Skip it
                {
                	CreateTimer(0.0, Timer_PreRoundEnd, TIMER_FLAG_NO_MAPCHANGE);                                // End the Pre-Round State, Start the Game... Derp
                }


        }

        PrintToServer("[Freeze]: Starting Round: %i/%i, Waiting For Players: %s",g_rounds,g_maxRounds,(g_bWaitingforplayers ? "Yes" : "No"));

        g_rounds++;                                                                                       // Increment the round counter, so that we know what our current round is. This is 1 ahead.
        g_eRoundWinreason = WIN_UNKNOWN;
        g_bWaitingforplayers = false;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Sets the team_round_timer setup timer to preround time, if doors are not set to be forced open
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
modifyGameTimer()
{
	new entityTimer = FindEntityByClassname(-1, "team_round_timer");                                  // Removes timelimit from round/map
	if (entityTimer > -1)
	{
		if (g_openDoors)
                {
                        AcceptEntityInput(entityTimer, "Kill");
	        }
	        else
	        {
                        if (g_preRoundTime)                                                               // Waiting 1 minute between rounds SUCKS, set this to our preround.
                        {
                                SetVariantInt(g_preRoundTime);
                                AcceptEntityInput(entityTimer, "SetSetupTime");
                        }
                        else                                                                              // If they have it set to 0 VERY BAD THINGS will happen, set it to 5 (default warmup)
                        {
                                SetVariantInt(5);
                                AcceptEntityInput(entityTimer, "SetSetupTime");
                        }
                }
        }

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Ends the pre-round and begins the active round
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Timer_PreRoundEnd(Handle:timer)
{
        for (new i=1; i<=MaxClients; i++)
        {
                if (IsClientInGame(i) && IsPlayerAlive(i))
                {

                        TF2_AddCondition(i, TFCond_SpeedBuffAlly, 0.01);                          // Recalculate speed
                }
        }

        if (g_bRemoveRespawnrooms)
        {
                removeRespawnrooms();                                                                     // Prevent Class Change
        }

        g_activeround = 2;                                                                                // Active Round, Game Has Begun

        for (new i=1; i<=MaxClients; i++)
        {
        	if (IsClientInGame(i) && GetClientTeam(i) > SPEC)                                         // Only look at people who have teams
		{
			g_playerclass[i] = TF2_GetPlayerClass(i);                                         // Store everypony's active, non-queued player class. Presumably, it's valid.
                        if(!IsPlayerAlive(i))
                        {
                                TF2_RespawnPlayer(i);                                                     // Respawn Deaders. This shouldn't happen, but in rare cases it can
                        }
                }
        }

        g_roundTimeleft = g_roundLength;                                                                  // Reset the round clock
        g_hGametimer = CreateTimer(1.0, Timer_TeamFreezeCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);  // Check every 1 second to update the scoreboard / HUD
}

public event_post_inventory_application(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
                                                                                                          // Not sure if clients have to be validated here, but there have been some errors in the past from skipping validation
	if (client)                                                                                       // Enabled here, activeround comes later  (checking if userid is valid should be enough...)
	{
                if (g_bUnassigned[client])                                                                // Late joiners and spectators/afks, initialize variables, freeze them
                {
                        g_bFrozen[client] = false;                                                        // Set them unfrozen, so they can suicide
                        g_bUnassigned[client] = false;
                        g_stuck[client] = 0;
                	if (g_activeround == 2)
                	{
                        	FakeClientCommand(client,"kill");                                         // Slay them in the active round

                        	if (g_bFeedback)
                        	{
                                	PrintToChat(client,"\x04[Freeze]:\x01 %t","feedback_joinpenalty");
         	        	}
                	}
			g_playerclass[client] = TF2_GetPlayerClass(client);                               // Store the class of late joiners - it will persist for the round and reconnects
			g_futureclass[client] = TFClass_Unknown;
                }
                if (!g_bFrozen[client])
                {
                 	if (TF2_GetPlayerClass(client) == TFClass_Engineer)
                 	{
		         	new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);             // Deal with Eureka Effect
		         	if (weapon > MaxClients && IsValidEntity(weapon) && (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 589))
                                {
                		 	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
         		         	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
                		        if (hWeapon != INVALID_HANDLE)
               	        	        {
                	        	 	TF2Items_SetClassname(hWeapon, "tf_weapon_wrench");
                		         	TF2Items_SetItemIndex(hWeapon, 7);
                		         	TF2Items_SetLevel(hWeapon, 100);
                		         	TF2Items_SetQuality(hWeapon, 5);
                		         	TF2Items_SetNumAttributes(hWeapon, 0);

                		        	weapon = TF2Items_GiveNamedItem(client, hWeapon);
                		        	CloseHandle(hWeapon);

                		        	if (IsValidEntity(weapon))
                		        	{
                                                	EquipPlayerWeapon(client, weapon);
                                                }
                	         	}
			 	}
		 	}
                 	else if(TF2_GetPlayerClass(client) == TFClass_Heavy)
                 	{
		         	new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);             // Deal with Holiday Punch
		         	if (weapon > MaxClients && IsValidEntity(weapon) && (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 656))
                                {
                		 	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
         		         	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
                		        if (hWeapon != INVALID_HANDLE)
               	        	        {
             	        	 	 	TF2Items_SetClassname(hWeapon, "tf_weapon_fists");
              		         	        TF2Items_SetItemIndex(hWeapon, 5);
                		         	TF2Items_SetLevel(hWeapon, 100);
                		         	TF2Items_SetQuality(hWeapon, 5);
                		         	TF2Items_SetNumAttributes(hWeapon, 0);

                		        	weapon = TF2Items_GiveNamedItem(client, hWeapon);
                		        	CloseHandle(hWeapon);

                		        	if (IsValidEntity(weapon))
                		        	{
                                                	EquipPlayerWeapon(client, weapon);
                                                }
                	         	}
			 	}
                 	}
                 	else if(TF2_GetPlayerClass(client) == TFClass_Spy)
                 	{
		         	new weapon = GetPlayerWeaponSlot(client, 4);                              // Deal with cloak and dagger
		         	if (weapon > MaxClients && IsValidEntity(weapon) && (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 60))
                                {
                		 	TF2_RemoveWeaponSlot(client, 4);
         		         	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
                		        if (hWeapon != INVALID_HANDLE)
               	        	        {
                	        		TF2Items_SetClassname(hWeapon, "tf_weapon_invis");
               		        	 	TF2Items_SetItemIndex(hWeapon, 30);
                		        	TF2Items_SetLevel(hWeapon, 100);
                		        	TF2Items_SetQuality(hWeapon, 5);
                		        	TF2Items_SetNumAttributes(hWeapon, 0);

                		        	weapon = TF2Items_GiveNamedItem(client, hWeapon);
                		        	CloseHandle(hWeapon);

                		        	if (IsValidEntity(weapon))
                		        	{
                                                	EquipPlayerWeapon(client, weapon);
                                                }
                	         	}
			 	}
                 	}
	 	}
 	}
}

public event_round_win(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
        if (g_activeround)
	{
                g_activeround = 0;                                                                        // That's it Man, Game Over Man, It's Game Over

                if(g_bFeedback)
                {
                        switch(g_eRoundWinreason)
                        {
                                case TIME_TIE:    PrintToChatAll("\x04[Freeze]:\x01 %t [\x076E89D4%i/%i\x01 %t \x07F07560%i/%i\x01 %t]","winreason_tie",g_bluefrozen,g_bluetotal,"wincompare_frozen",g_redfrozen,g_redtotal,"win_frozen");
                                case TIME_RED:    PrintToChatAll("\x04[Freeze]:\x01 %t \x07F07560%t\x01 [\x07F07560%i/%i\x01 %t \x076E89D4%i/%i\x01 %t]","winreason_time","victory_red",g_redfrozen,g_redtotal,"wincompare_frozen",g_bluefrozen,g_bluetotal,"win_frozen");
                                case TIME_BLU:    PrintToChatAll("\x04[Freeze]:\x01 %t \x076E89D4%t\x01 [\x076E89D4%i/%i\x01 %t \x07F07560%i/%i\x01 %t]","winreason_time","victory_blu",g_bluefrozen,g_bluetotal,"wincompare_frozen",g_redfrozen,g_redtotal,"win_frozen");
                                case ELIM_TIE:    PrintToChatAll("\x04[Freeze]:\x01 %t [\x076E89D4%i/%i\x01 %t \x07F07560%i/%i\x01 %t]","winreason_stalemate",g_bluefrozen,g_bluetotal,"wincompare_frozen",g_redfrozen,g_redtotal,"win_frozen");
                                case ELIM_RED:    PrintToChatAll("\x04[Freeze]:\x01 %t \x07F07560%t\x01 [\x07F07560%i/%i\x01 %t \x076E89D4%i/%i\x01 %t]","winreason_elimination","victory_red",g_redfrozen,g_redtotal,"wincompare_frozen",g_bluefrozen,g_bluetotal,"win_frozen");
                                case ELIM_BLU:    PrintToChatAll("\x04[Freeze]:\x01 %t \x076E89D4%t\x01  [\x076E89D4%i/%i\x01 %t \x07F07560%i/%i\x01 %t]","winreason_elimination","victory_blu",g_bluefrozen,g_bluetotal,"wincompare_frozen",g_redfrozen,g_redtotal,"win_frozen");
                                case WIN_UNKNOWN: PrintToChatAll("\x04[Freeze]:\x01 %t [\x076E89D4%i/%i\x01 %t \x07F07560%i/%i\x01 %t]","winreason_unknown",g_bluefrozen,g_bluetotal,"wincompare_frozen",g_redfrozen,g_redtotal,"win_frozen");
                        }
                }

                CreateTimer(0.1, Timer_UnfreezeAllClients, TIMER_FLAG_NO_MAPCHANGE);                      // Unfreezes people who died at round end, and need a second to respawn
	        CreateTimer(1.0, Timer_UnfreezeAllClients, TIMER_FLAG_NO_MAPCHANGE);                      // Just to be safe

                if (g_mapTime && (GetGameTime() > (g_fMapStartTime+g_mapTime)))                           // If mp_timelimit is not set to 0
                {                                                                                         // End the game if timelimit is over, happens on payloads and such
                        LogMessage("[TF2] Freeze Tag: Forcing Map Change Due to Timelimit: %i",g_mapTime);
                        CreateTimer(2.0, Timer_ForceGameEnd, TIMER_FLAG_NO_MAPCHANGE);                    // Elapsed time is greater than map time, end this
                }
                else if (g_maxRounds && (g_rounds > g_maxRounds))                                         // If round limit is not set to 0
                {                                                                                         // End the game because user requested it
                        LogMessage("[TF2] Freeze Tag: Forcing Map Change Due to Round Limit: %i",g_maxRounds);
                        CreateTimer(2.0, Timer_ForceGameEnd, TIMER_FLAG_NO_MAPCHANGE);                    // Max rounds played has occured
                }
        }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Forces the server to cycle maps when timelimit or winlimit is hit
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Timer_ForceGameEnd(Handle:timer)                                   // Borrwed from time limit enforcer
{
	new ent  = FindEntityByClassname(-1, "game_end");                        // Find game end, or create a new one
	if (ent == -1 && (ent = CreateEntityByName("game_end")) == -1)
	{
		LogError("[TF2] Freeze Tag: Unable to Locate and Create \"game_end\"!");
	}
	else
	{
                AcceptEntityInput(ent, "EndGame");                               // Game over man, game over
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Unfreezes all clients
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Timer_UnfreezeAllClients(Handle:timer)
{
        for (new i=1; i<=MaxClients; i++)                                        // Re-attempt to unfreeze late frozen players
        {
                if (g_bFrozen[i] && IsClientInGame(i) && IsPlayerAlive(i))
                {                                                                // unfreezeClient(client, other, bool:automatic=false, bool:sound=true, bool:particles=true, bool:respawn=false)
                        unfreezeClient(i,i,_,false,false);                       // Too many simultaneous sounds or particles can cause problems
                }
        }
}

///////////////////////////////// Damage //////////////////////////////////////////

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
        if (attacker > MaxClients || attacker < 1)                                              // Attacker is not another player
        {
        	if(g_bFrozen[client])                                                           // Prevent Drowining, hurts, and other world damage to frozen players
        	{
                        damage = 0.0;
                        return Plugin_Changed;
                }
                else
                {
                        return Plugin_Continue;
                }
        }

        if (!IsClientInGame(attacker))                                                          // The attacker disconnected while attacking
        {
                return Plugin_Continue;
        }

        if (g_bFrozen[client])                                                                  // We are only interested in corpsicles here of opposing teams
	{
                if (GetClientTeam(client) == GetClientTeam(attacker))                           // Friendly Fire? Lol
                {
                        damage = 0.0;

                        return Plugin_Changed;
                }

                new Float:newdamage = damage*g_fForceMulti;
                if(newdamage == 0.0)                                                            // If there's no force, don't bother
        	{
                        return Plugin_Continue;
                }

                decl Float:clientposition[3], Float:targetposition[3], Float:vector[3];
                GetClientAbsOrigin(attacker, clientposition);
                GetClientAbsOrigin(client, targetposition);
                new Float:dist = GetVectorDistance(clientposition, targetposition);

                if (dist < 550.0)                                                               // 550 is a good max range for push falloff, linear functions intercept around here
                {
		        MakeVectorFromPoints(clientposition, targetposition, vector);
		        NormalizeVector(vector, vector);

                        if (newdamage > g_fForceCap)
                        {
                	        newdamage = g_fForceCap;
                        }

			decl String:sWeapon[24];
			if (IsValidEntity(inflictor) && GetEntityClassname(inflictor, sWeapon, 24) && StrEqual(sWeapon, "tf_weapon_flamethrower"))
                        {                                                                       // If inflictor is valid ent, and it's set, and it's a flamethrower (wish I could use damagetype)
                                newdamage *= 5.0;                                               // Fire does only 6 damage per particle, just increase it by an arbitrary 5x
                                ScaleVector(vector, newdamage);
                                vector[2] =  (-0.171*dist)+308.0;                               // f(x) = -.171x+308 [400,240][50,300] linear function, 50 is point blank, 400 is max flamethrower
                        }                                                                       // x = distance from target, y = height target is lifted up
                        else
                        {
                                ScaleVector(vector, newdamage);
                                vector[2] =  (-0.175*dist)+350.0;                               // f(x) = -.175x+350 [2000,0][550,253.7][0,350] linear function, provides moderate knockbacks
                                if ( dist < 80.0 && (GetClientButtons(attacker) & IN_DUCK))     // If a player is within melee range and crouching, this will kock the target to the side, or back at them
                                {                                                               // Useful for knocking people out of corners, or back over the client's head to prevent knocking off cliffs
                                        vector[0] = -vector[0];
                                        vector[1] = -vector[1];
                                }
                        }

                        SetEntProp(client, Prop_Send, "m_bJumping", 1);                         // Force jump so they fly around
                        TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vector);
                        autoUnfreezeDamage[client] = true;                                      // VGTA
		}
		damage = 0.0;

		return Plugin_Changed;
	}

        if (TF2_IsPlayerInCondition(attacker, TFCond_CritMmmph))                                // Convert mmmph crits to minicrits for attackers
	{
		new weapon = GetEntPropEnt( attacker, Prop_Send, "m_hActiveWeapon" );

                if (weapon > MaxClients &&
                    IsValidEntity(weapon) &&
                   (GetEntProp( weapon, Prop_Send, "m_iItemDefinitionIndex" ) == 594))          // Make sure they have a phlog out
                {
                        damagetype &= ~DMG_CRIT;                                                // Remove crit damage
                        TF2_AddCondition(attacker, TFCond_CritHype, 0.1);                       // Add mini-crit damage
                }
                if (TF2_IsPlayerInCondition(client, TFCond_DefenseBuffMmmph))                   // Handles the case in which a gimped phlog user attacks a buffed phlog user
                {
                        damage *= 2;                                                            // Double pyro damage intake for phlog users
	        }

                return Plugin_Changed;
	}

        if (TF2_IsPlayerInCondition(client, TFCond_DefenseBuffMmmph))                           // Handles the case in which anyone attacks a buffed phlog user
        {
                damage *= 2;

		return Plugin_Changed;
	}

	return Plugin_Continue;

}

///////////////////////////////// Conditions //////////////////////////////////////

public TF2_OnConditionAdded(client, TFCond:condition)
{
	if (g_bFrozen[client])
	{
		switch(condition)
		{
			case TFCond_Bleeding:				          // Boston Basher, Southern Hospitality, Cleaver...
			{
				TF2_RemoveCondition(client,TFCond_Bleeding);
				SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 1.0);
			}
			case TFCond_SpeedBuffAlly:				  // Disciplinary Action
			{
	      			TF2_RemoveCondition(client,TFCond_SpeedBuffAlly);
	      			SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 1.0);
			}
			case TFCond_Dazed:					  // Scout Stun Ball
			{
	      			TF2_RemoveCondition(client,TFCond_Dazed);
	      			SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 1.0);
			}
			case TFCond_OnFire:					  // Sometimes it ticks the same time as freeze
			{
	      			TF2_RemoveCondition(client,TFCond_OnFire);
	      			SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 1.0);
			}
		}
	}
}


//////////////////////////////// Death ////////////////////////////////////////////

public event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
        new client = GetClientOfUserId(GetEventInt(event, "userid"));

        if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)                          // Don't intercept deadringers
	{
                if (g_activeround == 2)                                                           // Create Fake Spy if Active Round
                {
                        new time = RoundToNearest(GetEngineTime());                               // Gotta have a unique identifier... This will do, we don't need a float.

                        new fakespy = createFakeSpy(client, time);                                // Spawn a prop_dynamic spy
                        if (fakespy != -1)                                                        // We need at least this entity, as everything is parented to it
                        {
                                if (g_bUseModel)                                                  // Spawn a ice model
                                {
                                        createFakeIceBlock(client, fakespy, time);
                                        //createIceLight(client, fakespy, time);
                                }
                                else
                                {
                                        SetEntityRenderMode(fakespy, RENDER_TRANSCOLOR);
                                        createFakeParticle(client, fakespy, time);
                                }

                                if (GetClientTeam(client) == 2)
                                {
                                        SetEntityRenderColor(fakespy, COLOR_RED);                 // Color them Translucent Red
                                }
                                else
                                {
                                        SetEntityRenderColor(fakespy, COLOR_BLUE);                // Color them Translucent Blue
                                }

                                EmitSoundToAll(SOUND_FREEZE, client);                             // Emit Sound When Block is Formed.

                                new Handle:spypack;
                                CreateDataTimer(0.1, Timer_TheIceIsaSpy, spypack, TIMER_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);   // Move the decoy with the spy
                                WritePackCell(spypack, GetClientUserId(client));
                                WritePackCell(spypack, EntIndexToEntRef(fakespy));                                             // spy model index mabye not needed if the parent hierarchy can be killed
                                WritePackCell(spypack, SPYTICKS);                                                              // iteration count (~10 seconds at 66?) I have no idea.
                                WritePackCell(spypack, 0);                                                                     // touching ground (assume not)
                        }
                }

		return;
        }

        if (g_activeround == 2)                                                           // Freeze if Active Round
        {

                if (g_cam == 2)                                                           // store client's current camera setting.
	        {
		        if(GetEntProp(client, Prop_Send, "m_nForceTauntCam"))             // 1 = first, 0 = third
		        {
                                g_bThirdperson[client] = true;
                        }
                        else
                        {
                                g_bThirdperson[client] = false;
                        }
                }

                GetClientAbsOrigin(client, g_fDeathVec[client]);                          // Store the location they died at
                GetClientEyeAngles(client, g_fDeathAng[client]);                          // Store where they were looking
                GetEntPropVector(client, Prop_Data, "m_vecVelocity", g_fDeathVel[client]);// Store their Velocity

	        if (GetEntProp(client, Prop_Send, "m_bDucked"))                           // Store if they were ducking or not
	        {
		        g_bDeathDuck[client] = true;
	        }
	        else
	        {
		        g_bDeathDuck[client] = false;
                }

                if (g_playerclass[client] != TFClass_Unknown)                             // Really they should have one, but for some reason they don't, the game would get totally borked
                {
                        TF2_SetPlayerClass(client, g_playerclass[client], false, true);   // Set them to their round-start class, resolve the queued class respawn bug
                }
                CreateTimer(0.0, Timer_FreezeClientInPlace, GetClientUserId(client));     // Respawn and Freeze Player on next frame
        }
        else if (g_activeround == 1)                                                      // Respawn if Pre Round
        {
                CreateTimer(0.0, Timer_RespawnPlayer, GetClientUserId(client));           // Delay respawn to next frame
        }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Tracks and moves a decoy spy generated by the deadringer
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Timer_TheIceIsaSpy(Handle:timer, Handle:pack)
{
        ResetPack(pack);

	new userid = ReadPackCell(pack);
	new client = GetClientOfUserId(userid);

        new ref = ReadPackCell(pack);
        new fakespy = EntRefToEntIndex(ref);

	new iterations = ReadPackCell(pack);
	new touchedground = ReadPackCell(pack);

        if (!iterations || !client || !IsClientInGame(client) || !IsPlayerAlive(client) || g_bFrozen[client])  // kill it
        {
                if (fakespy != INVALID_ENT_REFERENCE)
	        {
                        decl String:soundfile[39];                                                             // Play shatter sound
                        Format(soundfile,39,"physics/glass/glass_impact_bullet%i.wav",GetRandomInt(1,3));
                        EmitSoundToAll(soundfile, fakespy);                                                    // Emit Sound When Block is Destroyed.
                        AttachParticle(fakespy);                                                               // Particles!

                        AcceptEntityInput(fakespy,"kill");                                                     // and like that, he was gone
	        }

                return Plugin_Stop;     
        }

        if (touchedground)
        {
                new clientsteam = GetClientTeam(client);
                if (touchedground == 1)                                                                        // the block just hit the ground, now it's stationary
                {
                        new Float:spytime = (float(iterations)/SPYTICKS)*10;                                   // time for the effects to last upon touching ground
                        decl Float:pos[3];
                        GetEntPropVector(fakespy, Prop_Send, "m_vecOrigin", pos);
                        pos[2] += 100;

                        for (new i=1; i<=MaxClients; i++)
		        {
			        if (IsClientInGame(i) && GetClientTeam(i) == clientsteam)                      // spectators can't see this, but who really cares?
                                {
                                        TE_SetupGlowSprite(pos, g_NoSprite, spytime, 0.3, 20);
                                        TE_SendToClient(i);
                                }
			}

                	if ((clientsteam == RED && g_autoTimeRed) ||
                            (clientsteam == BLU && g_autoTimeBlue))                                            // Calculate alpha intensity for auto unfreeze progress. Killing 2 birds here.
	        	{
                        	decl Float:vec[3];
                        	GetEntPropVector(fakespy, Prop_Send, "m_vecOrigin", vec);
                        	decl lifecolors[4];

                        	vec[2] += AUTORINGHEIGHT + RINGHEIGHT;                                         // Raise height of rings to chest

                        	lifecolors[1] = 0;     // The fake spy looks better when his rings don't fade, besides it's hard to predict how fast to make them fade since his life is brief
                        	lifecolors[3] = 255;   // alpha
                        	if (clientsteam == RED)
                        	{
                                	lifecolors[0] = 255;
                                	lifecolors[2] = 0;
                                	TE_SetupBeamRingPoint(vec, 50.0, 51.0, g_BeamSprite, g_HaloSprite, 0, 10, spytime, AUTORINGWIDTH, 0.0, lifecolors, 10, 0);
                                	TE_SendToAll();
                                	vec[2] += AUTORINGHEIGHT;
                                	TE_SetupBeamRingPoint(vec, 50.0, 51.0, g_BeamSprite, g_HaloSprite, 0, 10, spytime, AUTORINGWIDTH, 0.0, lifecolors, 10, 0);
                                	TE_SendToAll();
                        	}
                        	else
                        	{
                                	lifecolors[0] = 0;
                                	lifecolors[2] = 255;
                                	TE_SetupBeamRingPoint(vec, 50.0, 51.0, g_BeamSprite, g_HaloSprite, 0, 10, spytime, AUTORINGWIDTH, 0.0, lifecolors, 10, 0);
                                	TE_SendToAll();
                                	vec[2] += AUTORINGHEIGHT;
                                	TE_SetupBeamRingPoint(vec, 50.0, 51.0, g_BeamSprite, g_HaloSprite, 0, 10, spytime, AUTORINGWIDTH, 0.0, lifecolors, 10, 0);
                                	TE_SendToAll();
                        	}
                	}
                }

                new Handle:spypack;
                CreateDataTimer(0.1, Timer_TheIceIsaSpy, spypack, TIMER_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);   // fire it again!
                WritePackCell(spypack, userid);
                WritePackCell(spypack, ref);                                                                   // spy model index
                WritePackCell(spypack, iterations-1);                                                          // iteration decrement
                WritePackCell(spypack, touchedground+1);                                                       // stop the block from moving foreeeeeeeeeever!
                
                return Plugin_Continue;
        }                                                          

        decl Float:pos[3];
        GetClientAbsOrigin(client, pos);
        TeleportEntity(fakespy, pos, NULL_VECTOR, NULL_VECTOR);                                        // Move it to the client, it'll clip, oh well.

        new Handle:spypack;
        CreateDataTimer(0.1, Timer_TheIceIsaSpy, spypack, TIMER_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);   // fire it again!
        WritePackCell(spypack, userid);
        WritePackCell(spypack, ref);                                                                   // spy model index
        WritePackCell(spypack, iterations-1);                                                          // iteration decrement
        WritePackCell(spypack, ((GetEntityFlags(client) & (FL_ONGROUND|FL_INWATER)) ? 1 : 0));         // test if they are touching ground on next iteration pack
                                                                                                       // Can i combine this bitwise operation? =S
        return Plugin_Continue;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Respawns and freezes a cient ad their death vector
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Timer_FreezeClientInPlace(Handle:timer, any:userid)
{
        new client = GetClientOfUserId(userid);
        if (client && IsClientInGame(client))
        {
                TF2_RespawnPlayer(client);                                                 // somewhat seamless transition from death into cube

	        if (g_bDeathDuck[client])                                                  // If they died ducking, force them to duck so they don't get stuck under ramps, etc.
                {
                        SetEntPropVector(client, Prop_Send, "m_vecMaxs", g_fCollisionvec);
	                SetEntProp(client, Prop_Send, "m_bDucked", 1);
	                SetEntityFlags(client, GetEntityFlags(client) | FL_DUCKING);
                }

                TeleportEntity(client, g_fDeathVec[client], g_fDeathAng[client], g_fDeathVel[client]);  // Players will continue along the path they had in life

                freezeClient(client);                                                      // Freeze Player, check proximity, draw rings, etc
        }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Removes an entity
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Timer_RemoveEntity(Handle:timer, any:ref)
{
	new ent = EntRefToEntIndex(ref);
        if (ent != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent, "Kill");
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Draws the hud, tracks the score, and tracks player status
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Timer_TeamFreezeCheck(Handle:timer)                    // The basis of this timer was borrowed from freak fortress 2 :D
{
        if (!g_activeround)
	{
                g_hGametimer = INVALID_HANDLE;
                
                return Plugin_Stop;                                  // Failsafe if something bad happened and duplicate timers occur
        }

        new red;
        new blue;
        
        g_redfrozen = 0;
        g_bluefrozen = 0;
        g_redtotal = 0;
        g_bluetotal = 0;

        for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))                               // Checking if they are alive will throw it off as people die for short periods of time
		{                                                    // Generally, nobody on a team should ever be "dead", and it should never happen.
                	new team = GetClientTeam(i);
                        if (team == RED)
                	{
                		if(g_bFrozen[i])
                                {
                                        g_redfrozen++;
                                }
                                else
                                {
                                        red++;
                                }
                                g_redtotal++;
                	}
                	else if (team == BLU)
                	{
                		if(g_bFrozen[i])
                                {
                                        g_bluefrozen++;
                                }
                                else
                                {
                                        blue++;
                                }
                                g_bluetotal++;
                	}
                	else                                         // Set everyone else to unassigned (Spec + Not chosen)
                	{
                                g_bUnassigned[i] = true;             // They have no team, set them unassigned so they can join the game (AFK managers do this, annoying)
                        }
		}
	}

        ///////////////////////////////////////// Nobody Is Playing /////////////////////////////////////////////////////////
	if ((g_redtotal+g_bluetotal) == 0)
	{
                g_activeround = 0;
                g_bWaitingforplayers = true;
                g_hGametimer = INVALID_HANDLE;

                return Plugin_Stop;                                  // Kill it, the server will restart the round when a player joins, and 2 timers would be running.
        }

        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        new Float:redratio = (float(g_redfrozen)/g_redtotal);        // Ratio of Frozen/Unfrozen Players
        new Float:blueratio = (float(g_bluefrozen)/g_bluetotal);     // Smaller is more good.
        new time = g_roundTimeleft;
        decl String:s2[64];                                          // I'll leave some small amount of room for translations (It won't line up if changed, oh well.

        if (!g_roundLength)                                          // If they have no timelimit for the rounds set, don't draw the timer
        {
                if (g_maxRounds)
                {
                        Format(s2,64,"RED %t: %i/%i\nBLU %t: %i/%i\n#%i","hud_frozen",g_redfrozen,g_redtotal,"hud_frozen",g_bluefrozen,g_bluetotal,g_rounds-1);
                }
                else
                {
                        Format(s2,64,"RED %t: %i/%i\nBLU %t: %i/%i","hud_frozen",g_redfrozen,g_redtotal,"hud_frozen",g_bluefrozen,g_bluetotal);
                }
        }
        else
        {
      		g_roundTimeleft--;

		decl String:s1[6];
		if (time/60 > 9)
			IntToString(time/60,s1,6);
		else
			Format(s1,6,"0%i",time/60);
		if (time%60 > 9)
			Format(s1,6,"%s:%i",s1,time%60);
		else
			Format(s1,6,"%s:0%i",s1,time%60);

                if (g_maxRounds)
                {
        		decl String:s3[6];
        		if(g_rounds > 10)
                		Format(s3,6,"#%i",g_rounds-1);
        		else
                		Format(s3,6,"  #%i",g_rounds-1);

                        Format(s2,64,"RED %t: %i/%i\nBLU %t: %i/%i\n%s          %s","hud_frozen",g_redfrozen,g_redtotal,"hud_frozen",g_bluefrozen,g_bluetotal,s1,s3);
		}
		else
		{
                        Format(s2,64,"RED %t: %i/%i\nBLU %t: %i/%i\n%s","hud_frozen",g_redfrozen,g_redtotal,"hud_frozen",g_bluefrozen,g_bluetotal,s1);
                }
        }

        SetHudTextParams(HUDX1, HUDY1, 1.1, 255, 255, 255, 255);

        for (new i=1; i<=MaxClients; i++)                                                // Print out HUD
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			ShowSyncHudText(i,g_hTimeleftHUD,s2);
		}
	}

        /////////////////////////////////////////// ONE TEAM IS EMPTY ///////////////////////// How Lonely They Must Be /////
	if (g_redtotal == 0 || g_bluetotal == 0)
	{
                for (new i=1; i<=MaxClients; i++)                                        // Unfreeze the client
                {
                        if (g_bFrozen[i] && IsClientInGame(i) && IsPlayerAlive(i))
                        {                                                                // unfreezeClient(client, other, bool:automatic=false, bool:sound=true, bool:particles=true, bool:respawn=false)
                                unfreezeClient(i,i,_,false,false);                       // No bells or whistles here.
                        }
                }
                if(g_roundLength)
                {
                        g_roundTimeleft++;                                               // Refund the second on the clock, stall it until somone else joins.
                }
                return Plugin_Continue;
        }

	/////////////////////////////////////////// END GAME ON TIMER ///////////////////////////////////////////////////////
        if (g_roundLength)
        {
		if (time == 60)
			EmitSoundToAll(SOUND60,_,SNDCHAN_VOICE,SNDLEVEL_NORMAL,_,1.0,_,_,_,_,_,_);
		else if (time == 31)
		{
                	EmitSoundToAll(SOUNDWARN,_,SNDCHAN_VOICE,SNDLEVEL_NORMAL,_,1.0,_,_,_,_,_,_);
        	}
		else if (time == 30)
		{
			EmitSoundToAll(SOUND30,_,SNDCHAN_VOICE,SNDLEVEL_NORMAL,_,1.0,_,_,_,_,_,_);
        	}
		else if (time == 10)
		{
			EmitSoundToAll(SOUND10,_,SNDCHAN_VOICE,SNDLEVEL_NORMAL,_,1.0,_,_,_,_,_,_);
		}
        	else if (!time)
		{
			if ((g_redtotal+g_bluetotal) == 1)
			{
                        	g_rounds--;                               // Do not count this round, it was 1v0
                        }
                	if (redratio == blueratio)
                	{
                        	g_eRoundWinreason = TIME_TIE;
                        	ForceTeamWin(STALEMATE);                          // timelimit tie

                	}
                	else if(redratio > blueratio)
                	{
                        	g_eRoundWinreason = TIME_BLU;
                        	ForceTeamWin(BLU);                                // timelimit BLU wins
                	}
                	else
                	{
                        	g_eRoundWinreason = TIME_RED;
                        	ForceTeamWin(RED);                                // timelimit RED wins
                	}
			g_hGametimer = INVALID_HANDLE;
		
                	return Plugin_Stop;
		}
        	else if (time < 10)
        	{
                	if (redratio > blueratio)
                	{
                        	for (new i=1; i<=MaxClients; i++)
                        	{
		                	if (IsClientInGame(i) && IsPlayerAlive(i))                                  // Outline Everypony Who's Not Frozen
		                	{
                                        	if (GetClientTeam(i) == RED)
                                        	{
                                                	if (!g_bFrozen[i])
                                                	{
                                                        	if (TF2_GetPlayerClass(i) == TFClass_Spy)           // Blu is winning, highlight reds
        		                                	{
        		                                        	SetEntDataFloat(i, g_cloakOffset, 0.0);
		        	                                	TF2_RemovePlayerDisguise(i);
                                                                	TF2_RemoveCondition(i, TFCond_Cloaked);
                                                        	}
                                                        	SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1);
                                                	}
                                                	EmitSoundToClient(i,SOUNDTICKLOSS,_,SNDCHAN_VOICE,SNDLEVEL_NORMAL,_,1.0,_,_,_,_,_,_);
                                        	}
                                        	else
                                        	{
                                                	EmitSoundToClient(i,SOUNDTICKWIN,_,SNDCHAN_VOICE,SNDLEVEL_NORMAL,_,1.0,_,_,_,_,_,_);
                                        	}
	        	        	}
                        	}
               		}
                	else if (blueratio > redratio)
                	{
                        	for (new i=1; i<=MaxClients; i++)
                        	{
                                	if (IsClientInGame(i) && IsPlayerAlive(i))                                  // Outline Everypony Who's Not Frozen
		                	{
                                        	if (GetClientTeam(i) == BLU)
                                        	{
                                                	if (!g_bFrozen[i])
                                                	{
                                                        	if (TF2_GetPlayerClass(i) == TFClass_Spy)           // Red is winning, highlight blues
                                                        	{
                                                                	SetEntDataFloat(i, g_cloakOffset, 0.0);
                                                                	TF2_RemovePlayerDisguise(i);
                                                                	TF2_RemoveCondition(i, TFCond_Cloaked);
                                                        	}
                                                        	SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1);
                                                	}
                                                	EmitSoundToClient(i,SOUNDTICKLOSS,_,SNDCHAN_VOICE,SNDLEVEL_NORMAL,_,1.0,_,_,_,_,_,_);
                                        	}
                                        	else
                                        	{
                                                	EmitSoundToClient(i,SOUNDTICKWIN,_,SNDCHAN_VOICE,SNDLEVEL_NORMAL,_,1.0,_,_,_,_,_,_);
                                        	}
                                	}
                        	}
	        	}
	        	else
	        	{
                        	EmitSoundToAll(SOUNDTICKTIE,_,SNDCHAN_VOICE,SNDLEVEL_NORMAL,_,1.0,_,_,_,_,_,_);
                	}
		}
        }

	/////////////////////////////////////////// END GAME ON ELIMINATION ///////////////////////////////////////////////////////

        if (g_bEliminations)
        {
                if ((red + blue) == 0)                                    // Stalemate
                {
                        g_eRoundWinreason = ELIM_TIE;                     // elimination tie
                        ForceTeamWin(STALEMATE);
		        g_hGametimer = INVALID_HANDLE;

                        return Plugin_Stop;
                }
	        if (red == 0)                                             // Red is ded baby
                {
                        g_eRoundWinreason = ELIM_BLU;                     // elimination BLU wins
                        ForceTeamWin(BLU);
		        g_hGametimer = INVALID_HANDLE;

                        return Plugin_Stop;
	        }
	        if (blue == 0)                                            // Blue lost
                {
                        g_eRoundWinreason = ELIM_RED;                     // elimination RED wins
                        ForceTeamWin(RED);
		        g_hGametimer = INVALID_HANDLE;

                        return Plugin_Stop;
	        }
        }

	return Plugin_Continue;
}

ForceTeamWin(team)
{
	new tcpm = FindEntityByClassname(-1, "team_control_point_master");
	if (tcpm == -1)
	{
		tcpm = CreateEntityByName("team_control_point_master");
		DispatchSpawn(tcpm);
		AcceptEntityInput(tcpm, "Enable");
	}
	if (FindEntityByClassname(-1, "team_control_point_round") == -1)
	{
                SetVariantInt(team);                              // Set the team
        }
        else
        {
                SetVariantInt(STALEMATE);                         // Multi-stage map, setting the team will be VERY BAD
        }
	AcceptEntityInput(tcpm, "SetWinner");
}

///////////////////////////////////////////////////////////////////////////////////
/////////////////////////////// Freeze Functions //////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Freezes a client
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
freezeClient(client)
{
        TF2_RemovePlayerDisguise(client);                                                       // Just in case, remove disguise

        giveDummyWeapons(client);                                                               // Give them nerf bats... er fists

        SetEntityFlags(client, GetEntityFlags(client) | FL_NOTARGET);                           // Sentry Target Off
        
        SetEntProp(client, Prop_Send, "m_CollisionGroup", 13);                                  // Remove collision from frozen players (projectile group, can still be hit by most weapons)

        SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 1.0);

        if (g_bUseModel)
        {
		createIceBlock(client, 0);                                                      // The spy needs time to parent, here we do not since light is disabled
                colorizeWearables(client, false);                                               // Render_normal the wearables
        }
        else
        {
                SetEntityRenderMode(client, RENDER_TRANSCOLOR);
                colorizeWearables(client);
        }

        if (GetClientTeam(client) == 2)
        {
                SetEntityRenderColor(client, COLOR_RED);                                        // Color them Translucent Red
        }
        else
        {
                SetEntityRenderColor(client, COLOR_BLUE);                                       // Color them Translucent Blue
        }

        EmitSoundToAll(SOUND_FREEZE, client);                                                   // Emit Sound When Player is Frozen.

        purgeProximity(client);                                                                 // Clear the proximity tracker
        g_unfreezer[client] = 0;                                                                // Clear the freezing client
        autoUnfreezeDamage[client] = false;                                                     // Did the client take damage while frozen?
        
        if(g_cam)
        {
                setThirdPerson(client, true);                                                   // Set their camera to third person
        }

        new Handle:beaconpack;
        CreateDataTimer(g_fProximityIval, Timer_FreezeBeacon, beaconpack, TIMER_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);       // Beacon To Test Nearby Players and maintaine life-state of iceblock
        WritePackCell(beaconpack, GetClientUserId(client));
        WritePackCell(beaconpack, 0);                                                                                      // Auto unfreeze timer, counts upward.

        g_bFrozen[client] = true;

        if(g_bFeedback)
        {
                PrintToChat(client, "\x04[Freeze]:\x01 %t","feedback_frozen");
        }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Changes the color and opacity of wearable items so they do not clip with transparent models
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
colorizeWearables(client, bool:transparent=true)
{
        if (transparent)
        {
                new ent = MaxClients+1;
	        while ((ent = FindEntityByClassname2(ent, "tf_wearable")) != -1)
	        {
		        if (IsValidEntity(ent))
		        {
			        if (GetEntDataEnt2(ent, g_wearableOffset) == client)
			        {
                                        SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                                        SetEntityRenderColor(ent, COLOR_TRANS);
			        }
		        }
	        }
        }
        else
        {
                new ent = MaxClients+1;
	        while ((ent = FindEntityByClassname2(ent, "tf_wearable")) != -1)
	        {
		        if (IsValidEntity(ent))
		        {
			        if (GetEntDataEnt2(ent, g_wearableOffset) == client)
			        {
                                        SetEntityRenderMode(ent, RENDER_NORMAL);
			        }
		        }
	        }
        }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Moves the ice model with the player, since parenting is disabled
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
/////////////                  Gameframe                 /////////////
//////////////////////////////////////////////////////////////////////

public OnGameFrame()
{
        if(g_activeround == 1)   // setup
        {
                for (new i=1; i<=MaxClients; i++)
                {
                        if (IsClientInGame(i) && IsPlayerAlive(i))
                        {
                                SetEntPropFloat(i, Prop_Data, "m_flMaxspeed", 1.0);
                        }
                }
        }
        else if(g_bUseModel)
        {
                for(new client=1; client<=MaxClients; client++)
	        {
        	        if(IsClientInGame(client))
        	        {
                                new iceblock = EntRefToEntIndex(g_iceblock[client]);
                                if (iceblock != INVALID_ENT_REFERENCE)
                                {
	                                decl Float:pos[3];
	                                GetClientAbsOrigin(client, pos);
                                        TeleportEntity(iceblock, pos, NULL_VECTOR, NULL_VECTOR);       // Move it to the client, ignore the angle, it'll look stupid turning
                                }
		        }
	        }
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Generates weapons with attributes suitable fro frozen players
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
giveDummyWeapons(client)
{
	TF2_RemoveAllWeapons(client);                                         // Purge Weapons
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if (hWeapon != INVALID_HANDLE)
	{
		TF2Items_SetClassname(hWeapon, "tf_weapon_fists");
                TF2Items_SetItemIndex(hWeapon, 5);                            // Give everyone fists, heavy could taunt kill, but that's blocked
		TF2Items_SetLevel(hWeapon, 100);
		TF2Items_SetQuality(hWeapon, 10);                             // Use 10 for quality check in loop
		TF2Items_SetAttribute(hWeapon, 0, 1, 0.0);
                TF2Items_SetAttribute(hWeapon, 1, 275, 1.0);
                TF2Items_SetAttribute(hWeapon, 2, 109, 0.0);
                TF2Items_SetAttribute(hWeapon, 3, 236, 1.0);
                TF2Items_SetAttribute(hWeapon, 4, 54, 0.0000001);
                TF2Items_SetNumAttributes(hWeapon, 5);

                new weapon = TF2Items_GiveNamedItem(client, hWeapon);
                CloseHandle(hWeapon);

                if (IsValidEntity(weapon))
                {
                	EquipPlayerWeapon(client, weapon);
                        SetEntDataFloat(weapon, g_primaryOffset, GetGameTime()+1800);      // This may or may not work properly, not quite sure how to calculate the time.
                        SetEntDataFloat(weapon, g_secondaryOffset, GetGameTime()+1800);
                }
	}
}

///////////////////////////////// Entity Spawns ///////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Creates a prop_dynamic ice model and tracks it
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
stock createIceBlock(client, time)
{
        new ice1 = EntRefToEntIndex(g_iceblock[client]);
        if (ice1 != INVALID_ENT_REFERENCE)                                   // Kill the old one if it somehow exists (admin slay frozen player or somesuch nonsense)
	{
		AcceptEntityInput(ice1, "Kill");
		g_iceblock[client] = INVALID_ENT_REFERENCE;                  // Just incase prop creation somehow fails, it will still take 1 frame for the old one to die
	}

	ice1 = CreateEntityByName("prop_dynamic");
	if ( ice1 != -1 )
	{
		decl Float:pos[3];
		decl Float:angle[3];

		GetClientAbsOrigin(client, pos);
		GetClientAbsAngles(client, angle);                            // Spawn the ice block with the player's angle, so they won't all look the same
                angle[0] = GetRandomFloat(-5.0,5.0);                          // Purge eye position data, generate random variance
                angle[2] = GetRandomFloat(-5.0,5.0);

                DispatchKeyValueVector(ice1, "origin", pos);
                DispatchKeyValueVector(ice1, "angles", angle);

                decl String:Buffer[32];
	        Format(Buffer, 32, "%i%i", client, time);
                DispatchKeyValue(ice1, "targetname", Buffer);                 // name the prop ent-time, so we can parent.
		
                DispatchKeyValue(ice1, "model", MODEL_ICEBLOCK);
		DispatchKeyValue(ice1, "solid", "0");
		DispatchKeyValue(ice1, "disableshadows", "1");
		if(GetClientTeam(client) == BLU)
		{
			DispatchKeyValue(ice1, "skin", "1");

		}
		DispatchSpawn(ice1);
		ActivateEntity(ice1);
		SetVariantString("idle");
		AcceptEntityInput(ice1, "SetAnimation", -1, -1, 0);
		AcceptEntityInput(ice1, "TurnOn");

                g_iceblock[client] = EntIndexToEntRef(ice1);                  // Preserve, for later
	}

	return ice1;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Creates a prop_dynamic spy
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
stock createFakeSpy(client, time)
{
	new fakespy = CreateEntityByName("prop_dynamic");                     // You don't need hats to have class, right?
	if ( fakespy != -1 )
	{
		decl Float:pos[3];
		decl Float:angle[3];

		GetClientAbsOrigin(client, pos);
		GetClientAbsAngles(client, angle);                            // Spawn the fake spy in the place of the real spy
                angle[0] = 0.0;                                               // Purge unneeded position data
                angle[2] = 0.0;

                DispatchKeyValueVector(fakespy, "origin", pos);
                DispatchKeyValueVector(fakespy, "angles", angle);

                decl String:Buffer[32];
	        Format(Buffer, 32, "%i%i", fakespy, time);
                DispatchKeyValue(fakespy, "targetname", Buffer);              // name the prop ent-time, so we can parent.
                
                DispatchKeyValue(fakespy, "model", MODEL_SPY);
		DispatchKeyValue(fakespy, "solid", "0");                      // It's a cheesy decoy, but if it's solid it will rape our spy
		if(GetClientTeam(client) == BLU)
		{
			DispatchKeyValue(fakespy, "skin", "1");

		}
		DispatchSpawn(fakespy);
		ActivateEntity(fakespy);
		SetVariantString("Stand_ITEM1");                              // LOOK AT MY DASHING EMPTY HANDS
		AcceptEntityInput(fakespy, "SetAnimation", -1, -1, 0);
		AcceptEntityInput(fakespy, "TurnOn");
	}

	return fakespy;                                                       // Return him, when he's killed all of the parented items also will be
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Creates a prop_dynamic ice model and parents it
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
createFakeIceBlock(client, parent, time)
{
	new ice1 = CreateEntityByName("prop_dynamic");
	if ( ice1 != -1 )
	{
		decl Float:pos[3];
		decl Float:angle[3];

		GetClientAbsOrigin(client, pos);
		GetClientAbsAngles(client, angle);                            // Spawn the ice block with the player's angle, so they won't all look the same
                angle[0] = GetRandomFloat(-5.0,5.0);                          // Purge eye position data, generate random variance
                angle[2] = GetRandomFloat(-5.0,5.0);

                DispatchKeyValueVector(ice1, "origin", pos);
                DispatchKeyValueVector(ice1, "angles", angle);

		DispatchKeyValue(ice1, "model", MODEL_ICEBLOCK);
		DispatchKeyValue(ice1, "solid", "0");
		DispatchKeyValue(ice1, "disableshadows", "1");
		if(GetClientTeam(client) == BLU)
		{
			DispatchKeyValue(ice1, "skin", "1");

		}
		DispatchSpawn(ice1);
		ActivateEntity(ice1);
		SetVariantString("idle");
		AcceptEntityInput(ice1, "SetAnimation", -1, -1, 0);
		AcceptEntityInput(ice1, "TurnOn");

	        decl String:Buffer[32];
	        Format(Buffer, 32, "%i%i", parent, time);
	        SetVariantString(Buffer);
	        AcceptEntityInput(ice1, "SetParent");                         // Parent the iceblock to the decoy spy
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Creates an info_particle_system and parents it
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
createFakeParticle(client, parent, time)
{                                                                             // Emit fake addcond particles
	new particle = CreateEntityByName("info_particle_system");
	if ( particle != -1 )
	{
		decl Float:Pos[3];
		GetClientAbsOrigin(client, Pos);

                DispatchKeyValueVector(particle, "origin", Pos);

		if(GetClientTeam(client) == RED)
		{
                	DispatchKeyValue(particle, "effect_name", "medic_healradius_red_buffed");
                }
                else
                {
                        DispatchKeyValue(particle, "effect_name", "medic_healradius_blue_buffed");
                }
		DispatchSpawn(particle);

	        decl String:Buffer[32];
	        Format(Buffer, 32, "%i%i", parent, time);
	        SetVariantString(Buffer);
	        AcceptEntityInput(particle, "SetParent");                     // Parent the iceblock to the decoy spy

		ActivateEntity(particle);
                AcceptEntityInput(particle, "start");
	}
}

///////////////////////////////////////////////////////////////////////////////////
///////////////////////////// Unfreeze Functions //////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Unfreezes a client
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
unfreezeClient(client, other, bool:automatic=false, bool:sound=true, bool:particles=true, bool:respawn=false)
{
        g_bFrozen[client] = false;                                           // Set this now, so they get proper weapons on inventory application hook

        if (g_bUseModel)
        {
                destroyIceBlock(client);                                     // Remove ice model
        }
        else
        {
                SetEntityRenderMode(client, RENDER_NORMAL);                  // Fix their render mode, wearables should get fixed via inventory application
                TF2_RemoveCondition(client, TFCond_InHealRadius);            // Kill Lingering Particles
        }

        SetEntityRenderColor(client, COLOR_NORMAL);                          // Fix their render color

        SetEntityFlags(client, GetEntityFlags(client) &~ FL_NOTARGET);       // Sentry Target On (Regenerate will not work without this flag set!)

        SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);                // Normal player Solidity

	if (sound)
	{
                decl String:soundfile[39];                                   // Play shatter sound
	        Format(soundfile,39,"physics/glass/glass_impact_bullet%i.wav",GetRandomInt(1,3));
	        EmitSoundToAll(soundfile, client);                           // Emit Sound When Unfrozen.
                EmitSoundToClient(client,SOUND_REVIVE,_,SNDCHAN_VOICE,SNDLEVEL_NORMAL,_,1.0,_,_,_,_,_,_);
        }

        if (particles)
        {
                AttachParticle(client);                                      // Particles!
        }

        if (g_cam)
        {
                setThirdPerson(client, false);                               // Set their camera to first person
        }

        if (g_activeround && g_bAllowChangeclass && g_futureclass[client] && (g_playerclass[client] != g_futureclass[client]))  // If class changing is permitted, and they queued a class, respawn them as that class
        {
                g_playerclass[client] = g_futureclass[client];
                g_futureclass[client] = TFClass_Unknown;
                TF2_SetPlayerClass(client, g_playerclass[client], false, true);      // Set their class!
                TF2_RespawnPlayer(client);                                           // Respawn Them as new class
        }
        else if (respawn)                                                            // Respawn the client in spawnroom
        {
                TF2_RespawnPlayer(client);                                           // Respawn them. If server ops allow enemies to go into their spawnroom, they could get stuck inside things, VGTW
        }
        else                                                                         // Regenerate them normally on the battlefield, do normal checks
        {
                TF2_RegeneratePlayer(client);                                        // Recover, restore weapons
                ResetPlayerHealth(client,automatic);                                 // Restore them with % max health by base class, pass the flag if it was done automatically or not

                if (IsEntityStuck(client))                                           // Are they stuck in an entity that isn't a teammate?
                {
                        decl Float:targetposition[3];
		        GetClientAbsOrigin(other, targetposition);                   // Move them to their unfreezer's location, who shouldn't be stuck

		        SetEntPropVector(client, Prop_Send, "m_vecMaxs", g_fCollisionvec);
		        SetEntProp(client, Prop_Send, "m_bDucked", 1);
		        SetEntityFlags(client, GetEntityFlags(client) | FL_DUCKING); // Force them to be ducking, just in case.

                        TeleportEntity(client, targetposition, NULL_VECTOR, NULL_VECTOR);
                }

                CreateTimer(0.5, Timer_CivilianCheck, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);          // If they were spawned in an entity, they won't get weapons, keep trying until they get them
        }                                                                                                                      // This happens rarely and resolves itself quickly. Delay ensures they won't chain heal and soak damage

	if (g_bFeedback)
	{
		PrintToChat(client, "\x04[Freeze]:\x01 %t","feedback_unfrozen");
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Destroys a single client's ice block model, or all client ice block models
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
destroyIceBlock(client=0, bool:all=false)                                     // Destroys a single client's ice block, or all - I could use 0 here instead of the bool, but that's bad practice =S
{
	decl ice;
        if (all)
	{
                for (new i=1; i<=MaxClients; i++)
                {
                        ice = EntRefToEntIndex(g_iceblock[i]);
                        if (ice != INVALID_ENT_REFERENCE)
	                {
                                AcceptEntityInput(ice,"Kill");
		                g_iceblock[i] = INVALID_ENT_REFERENCE;
	                }
                }
        }
        else
        {
                ice = EntRefToEntIndex(g_iceblock[client]);
                if (ice != INVALID_ENT_REFERENCE)
	        {
		        AcceptEntityInput(ice,"Kill");
		        g_iceblock[client] = INVALID_ENT_REFERENCE;
	        }
        }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Checks if a client has no weapons, and attempts to regenerate them
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Timer_CivilianCheck(Handle:timer, any:userid)                   // Tests to see if a client has no weapons, and fixes
{
       new client = GetClientOfUserId(userid);
       if (!client || !IsClientInGame(client) || g_bFrozen[client] || !IsPlayerAlive(client))
       {
              return Plugin_Stop;
       }

       new melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
       if (melee == -1)
       {
              TF2_RemoveCondition(client, TFCond_Taunting);                   // If they are taunting, stop it or they will go civilian, also - highfive is dumb
              TF2_RegeneratePlayer(client);                                   // Recover, restore weapons, will heal them, repeatedly, sucks.
              ResetPlayerHealth(client);                                      // Restore them with % max health by base class
              TF2_SwitchtoIdealSlot(client);                                  // Switch to Primary if possible, otherwise do melee
       
              return Plugin_Continue;
       }

       return Plugin_Stop;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Forces a client to switch to primary weapon slot, or melee if primary is not available
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
TF2_SwitchtoIdealSlot(client)
{
	decl String:classname[64];
	new primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	new melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if (primary > MaxClients && IsValidEntity(primary) && GetEntityClassname(primary, classname, sizeof(classname)))
	{
		FakeClientCommandEx(client, "use %s", classname);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", primary);
	}
	else if (melee > MaxClients && IsValidEntity(melee) && GetEntityClassname(melee, classname, sizeof(classname)))
	{
		FakeClientCommandEx(client, "use %s", classname);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", melee);
	}
}

///////////////////////////////////////////////////////////////////////////////////
///////////////////////////// Collision Detection /////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Tests if a player is stuck inside of a solid non-teammate-client entity
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
bool:IsEntityStuck(ent)
{
	decl Float:flOrigin[3];
	decl Float:flMins[3];
	decl Float:flMaxs[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", flOrigin);
	GetEntPropVector(ent, Prop_Send, "m_vecMins", flMins);
	GetEntPropVector(ent, Prop_Send, "m_vecMaxs", flMaxs);

	TR_TraceHullFilter(flOrigin, flOrigin, flMins, flMaxs, MASK_SOLID, TraceFilterNotTeam, ent);
	return TR_DidHit();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Filters out friendly teammates and tf_ammo_packs (weapons) which are not actually solid
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public bool:TraceFilterNotTeam(entity, contentsMask, any:client)
{
        if ((entity > 0) && (entity <= MaxClients))          // player index range
        {
                if (GetClientTeam(entity) != GetClientTeam(client))
                {
                         return true;                        // The client is on a different team from the enemy, do it
                }
                else
                {
                         return false;                       // The client is on the same team, don't do it
                }
        }
        else if (IsValidEntity(entity))
        {
                decl String:ObjClassName[32];

                if (GetEntityClassname(entity, ObjClassName, sizeof(ObjClassName)) && StrEqual(ObjClassName, "tf_ammo_pack"))
                {
                        return false;                        // They're probably in their own dropped weapon, ignore
                }
        }

	return true;                                         // The client may become stuck in world geometry props, or buildables, do it
}

///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// Reset Defaults ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Resets the health of a player back to a predefined amount
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
ResetPlayerHealth(client, bool:automatic=false)                              // Decides what class player is and restores appropriate health
{
        decl Float:ratio;
        
        if (automatic)
        {
                if (GetClientTeam(client) == RED)                            // If they were self-unfrozen, use this ratio
                {
                        ratio = g_fAutoHPRatioRed;
                }
                else
                {
                        ratio = g_fAutoHPRatioBlue;
                }
        }
        else
        {
                if (GetClientTeam(client) == RED)                            // If they were self-unfrozen, use this ratio
                {
                        ratio = g_fUnfreezeHPRatioRed;
                }
                else
                {
                        ratio = g_fUnfreezeHPRatioBlue;
                }
        }

        if (g_stuck[client])                                                 // Penalize stuck clients by removing 20% base health for the rest of the round
        {                                                                    // yes.. 20% penalty for "stuck" players
                ratio *= 0.80;
        }

	new curhp = SDKCall( fnGetMaxHealth, client );                       // Re-calculate health based on items and class
        new health = RoundToCeil(curhp*ratio);
	SetEntProp(client, Prop_Data, "m_iMaxHealth", health);
	SetEntProp(client, Prop_Send, "m_iHealth", health);
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Resets arrays dealing with frozen players
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
unfreezeAll()
{
        for (new i=1; i<=MaxClients; i++)                                       // Re-initialize frozen array
        {
        	g_bFrozen[i] = false;                                           // Set everyone to non-frozen
        	g_stuck[i] = 0;                                                 // Set everyone to non-stuck
       	}
}

///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// Proximity ////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Tracks the proximity of players near a frozen client, and emits temp ent rings
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Timer_FreezeBeacon(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new userid = ReadPackCell(pack);
        new client = GetClientOfUserId(userid);
        new iterations = ReadPackCell (pack);

        if (!client || !IsClientInGame(client) || !g_bFrozen[client] || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}

        new clientsteam = GetClientTeam(client);
	if ((iterations == g_autoTimeRedMax && (clientsteam == RED && g_autoTimeRed)) ||
            (iterations == g_autoTimeBlueMax && (clientsteam == BLU && g_autoTimeBlue)))
	{
		if (g_stuck[client] == 1)
		{
                	g_stuck[client] = 0;                                  // Unflag them as stuck, they self-unfroze
                }
                if ((clientsteam == RED && g_fAutoHPRatioRed == 0.0) ||
                    (clientsteam == BLU && g_fAutoHPRatioBlue == 0.0))        // If Ratio is set to 0, respawn them instead.
                {
                        broadcastUnfreeze(client,client);                     // unfreezeClient(client, other, bool:automatic=false, bool:sound=true, bool:particles=true, bool:respawn=false)
                        unfreezeClient(client,client,_,_,_,true);             // Respawn the player when unfrozen
                }
                else
                {
                        broadcastUnfreeze(client,client);                     // Broadcast fake event message ... derp.
		        unfreezeClient(client,client,true);                   // Unfreeze them automatic ratio HP
                }

		return Plugin_Stop;
        }

        //////// Weapon Check /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	new primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	new secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);

        if (primary != -1 || secondary != -1)                                   // Weapon replace mods and crap can grant them stuff after us, if they are equipped, strip them
        {
        	giveDummyWeapons(client);
	}
	else if ((IsValidEntity(weapon) && (weapon > 0)) &&
                 (GetEntProp(weapon, Prop_Send, "m_iEntityQuality") != 10) )   // Check the quality, if it's not 10 (nerf fists), replace it
        {
        	giveDummyWeapons(client);
        }

        //////// Graphical ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	decl Float:vec[3];
	GetClientAbsOrigin(client, vec);
        new bool:bStationary = (GetEntityFlags(client) & (FL_ONGROUND|FL_INWATER)) ? true : false;
	vec[2] += RINGHEIGHT;                                                  // Raise height of rings

        decl Float:radius1;
        decl lifecolors[4];

        if ((clientsteam == RED && g_autoTimeRed) || 
            (clientsteam == BLU && g_autoTimeBlue))                            // Create 2 rings that team color fade to white based upon auto unfreeze progress
	{
                if(g_bTrackDamage && autoUnfreezeDamage[client])               // They took some incoming force damage, sad for them
                {
                        iterations = 0;                                        // VGS
                        autoUnfreezeDamage[client] = false;                    // Reset their state, so they can start self-thawing
                }
                else
                {
                        iterations++;
                }

                if (bStationary)                                               // If they are on the ground or in water, generate tempents
                {
                        vec[2] += AUTORINGHEIGHT;                              // Raise height of rings to chest

                        lifecolors[3] = 255;   // alpha
                        if (clientsteam == RED)
                        {
                                lifecolors[1] = RoundToNearest( (float(iterations)/g_autoTimeRedMax  )*AUTORINGBRIGHT); // derp (GREEN).  autotime works best as an int in the timer loop, but integer division is bad.
                                lifecolors[0] = 255;
                                lifecolors[2] = lifecolors[1];
                                TE_SetupBeamRingPoint(vec, 50.0, 51.0, g_BeamSprite, g_HaloSprite, 0, 10, g_fRingIval, AUTORINGWIDTH, 0.0, lifecolors, 10, 0);
                                TE_SendToAll();
                                vec[2] += AUTORINGHEIGHT;
                                TE_SetupBeamRingPoint(vec, 50.0, 51.0, g_BeamSprite, g_HaloSprite, 0, 10, g_fRingIval, AUTORINGWIDTH, 0.0, lifecolors, 10, 0);
                                TE_SendToAll();
                        }
                        else
                        {
                                lifecolors[1] = RoundToNearest( (float(iterations)/g_autoTimeBlueMax  )*AUTORINGBRIGHT); // derp (GREEN).  autotime works best as an int in the timer loop, but integer division is bad.
                                lifecolors[0] = lifecolors[1];
                                lifecolors[2] = 255;
                                TE_SetupBeamRingPoint(vec, 50.0, 51.0, g_BeamSprite, g_HaloSprite, 0, 10, g_fRingIval, AUTORINGWIDTH, 0.0, lifecolors, 10, 0);
                                TE_SendToAll();
                                vec[2] += AUTORINGHEIGHT;
                                TE_SetupBeamRingPoint(vec, 50.0, 51.0, g_BeamSprite, g_HaloSprite, 0, 10, g_fRingIval, AUTORINGWIDTH, 0.0, lifecolors, 10, 0);
                                TE_SendToAll();
                        }

                        vec[2] -= AUTORINGHEIGHT + AUTORINGHEIGHT;                    // Return
                }
        }
        if (g_stuck[client] == 1)
        {
                radius1 = g_fFreezeDist + g_fFreezeDist + g_fFreezeDist;
        }
        else
        {
                radius1 = g_fFreezeDist + g_fFreezeDist;
        }
        new Float:radius2 = radius1 + 1;

        if (bStationary)
        {
		if (clientsteam == RED)
        	{                                                                     // Red Version
                	for (new i=1; i<=MaxClients; i++)
			{
				if (IsClientInGame(i))
                        	{
                                	if (GetClientTeam(i) != BLU)                  // Don't send location freeze indicators to blue team, but allow spectators, etc.
			        	{
		                        	TE_SetupBeamRingPoint(vec, radius2, radius1, g_BeamSprite, g_HaloSprite, 0, 10, g_fRingIval, PINGWIDTH, 0.0, {255,0,0,255}, 10, 0);
                                        	TE_SendToClient(i);
                                	}
                        	}
			}
        	}
        	else
        	{                                                                     // Blue Version
                	for (new i=1; i<=MaxClients; i++)
			{
				if (IsClientInGame(i))
				{
                                	if (GetClientTeam(i) != RED)                  // Don't send location freeze indicators to blue team, but allow spectators, etc.
			        	{
                				TE_SetupBeamRingPoint(vec, radius2, radius1, g_BeamSprite, g_HaloSprite, 0, 10, g_fRingIval, PINGWIDTH, 0.0, {0,0,255,255}, 10, 0);
                                		TE_SendToClient(i);
					}
				}
			}
        	}
        }

        if (!g_bUseModel)
        {
                TF2_AddCondition(client, TFCond_InHealRadius, 1.5);                   // Emit the particle effect to all
        }

        //////// Proximity ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 1.0);

	decl Float:vec2[3];
        decl Float:maxdist;

        if (g_stuck[client] == 1)
        {
                maxdist = g_fFreezeDist + g_fFreezeDist;                                                // Expand the radius for stuck players
        }
        else
        {
                maxdist = g_fFreezeDist;
        }

	vec[2] -= RINGHEIGHT;                                                                           // Set our vector back to AbsOrigin (this is the frozen player)

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!g_bFrozen[i] && IsClientInGame(i) && IsPlayerAlive(i))
		{
			GetClientEyePosition(i, vec2);                                                  // Get teammate's position

			if (GetVectorDistance(vec2, vec, false) < maxdist)			        // Player is in range of the effect
			{
                                if ((GetClientTeam(client) == GetClientTeam(i)) && (i != client))	// Same team, not same player
                                {
                                        if (g_playerProx[client][i] == 0)                               // First Detection of This Teammate in Range, Fire off Countdown
                                        {                                                               // It only pulses every second for initial detections, but that's good enough.
                                                g_playerProx[client][i] = 1;                            // This is somewhat costly to do, and the temp ents look best @ 1 second refresh

                                                new Handle:proxpack;
                                                CreateDataTimer(g_fProximityIval, Timer_ProxTestCountdown, proxpack, TIMER_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
                                                WritePackCell(proxpack, userid);
                                                WritePackCell(proxpack, GetClientUserId(i));
                                                WritePackCell(proxpack, g_proximityIter);
					}
                                }
			}
		}
	}
	
        new Handle:beaconpack;                                   // Fire another timer, this same function once again
        CreateDataTimer(g_fProximityIval, Timer_FreezeBeacon, beaconpack, TIMER_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
        WritePackCell(beaconpack, userid);
        WritePackCell(beaconpack, iterations++);                 // increment counter, easier to count upwards here

	return Plugin_Continue;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Tests if a player remains valid and in proximity to a frozen client
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Timer_ProxTestCountdown(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new frozenguyuserid = ReadPackCell(pack);
        new frozenguy = GetClientOfUserId(frozenguyuserid);

        new teammateuserid  = ReadPackCell(pack);
        new teammate = GetClientOfUserId(teammateuserid);

        new iterations = ReadPackCell(pack);

	if (!frozenguy || !IsClientInGame(frozenguy) || !IsPlayerAlive(frozenguy) || 
            !teammate ||!IsClientInGame(teammate) || !IsPlayerAlive(teammate))
	{
		return Plugin_Stop;
	}

	if (!g_bFrozen[frozenguy] || g_bFrozen[teammate])                 // Teammate became frozen or invalid, abort the timer)
	{
                PrintCenterText(frozenguy, "");                           // Clear Center Text
                PrintCenterText(teammate, "");

		return Plugin_Stop;
	}

        if (TF2_IsPlayerInCondition(teammate, TFCond_Cloaked) ||          // Clients meeting these conditions will be ignored
            TF2_IsPlayerInCondition(teammate, TFCond_Disguised) ||
            TF2_IsPlayerInCondition(teammate, TFCond_Bonked))
        {
                g_playerProx[frozenguy][teammate] = 0;                    // Teammate invalid, reset state so this teamate can fire off new countdown
                                                                          // Either kill it each pulse with plugins_stop and allow a new one to occur
                return Plugin_Stop;                                       // Or return plugin_continue and have spies have real long timers...
	}

        if (g_unfreezer[frozenguy] == 0)
        {
                g_unfreezer[frozenguy] = teammate;                        // If no teammate is set as the priority unfreezing client, this client is now the one.
        }

        if (iterations == 0)                                              // Countdown hit, unfreeze the player!
        {
                if (g_stuck[frozenguy] == 1)                              // If they are being unstuck, move them to spawn
                {
                        g_playerProx[frozenguy][teammate] = 0;            // Allow reviving teammate to re-trigger revive on them later
                        g_stuck[frozenguy] = 2;                           // Increment stuck count to be out of valid range
                        SendToSpawnPoint(frozenguy);                      // Respawn frozen (frozen = 0 now)
                        if (g_bFeedback)
		        {
			        PrintToChat(frozenguy, "\x04[Freeze]:\x01 %t","feedback_stuck_saved");
		        }
                }
                else
                {
                        broadcastUnfreeze(frozenguy,teammate);            // Broadcast fake event message
                        unfreezeClient(frozenguy,teammate);               // Otherwise, Unfreeze Them
                }                                                         // unfreezeClient(client, other, bool:automatic=false, bool:sound=true, bool:particles=true, bool:respawn=false)

                PrintCenterText(frozenguy, "");                           // Clear Center Text
                PrintCenterText(teammate, "");
                g_unfreezer[frozenguy] = 0;                               // We are done unfreezing the client, release the lock

		return Plugin_Stop;
        }
	if (testProx(frozenguy, teammate))                                // Teammate was within the frozen player's proximity ring!
        {

                //////// Graphical ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                if (g_unfreezer[frozenguy] == teammate && (GetEntityFlags(frozenguy) & (FL_ONGROUND|FL_INWATER)))
                {
		        decl Float:vec[3];
		        GetClientAbsOrigin(frozenguy, vec);
		        vec[2] += RINGHEIGHT;                                                 // Raise height of rings

                        new Float:ratio = (g_proximityIter-iterations)/float(g_proximityIter);// 0 will be last iteration,   g_proximityIter = max iterations
                        decl Float:radius1;

        	        if (g_stuck[frozenguy] == 1)
        	        {
                                radius1 = (g_fFreezeDist + g_fFreezeDist + g_fFreezeDist)*ratio;
        	        }
        	        else
        	        {
                                radius1 = (g_fFreezeDist + g_fFreezeDist)*ratio;
                        }

                        new Float:radius2 = radius1 + 1;                                      // Whatever radius 1 is, make this 1 larger.

		        if (GetClientTeam(frozenguy) == 2)
        	        {                                                                     // Red Version
                	        for (new i=1; i<=MaxClients; i++)
			        {
				        if (IsClientInGame(i) && GetClientTeam(i) != BLU)      // Don't send to blue team, but allow spectators, etc.
				        {
                			        TE_SetupBeamRingPoint(vec, radius2, radius1, g_BeamSprite, g_HaloSprite, 0, 10, g_fProximityIval, PINGWIDTH, 0.0, {255,255,255,255}, 10, 0);
                                	        TE_SendToClient(i);
				        }
			        }
        	        }
        	        else
        	        {                                                                     // Blue Version
                                for (new i=1; i<=MaxClients; i++)
		                {
				        if (IsClientInGame(i) && GetClientTeam(i) != RED)      // Don't send to red team, but allow spectators, etc.
				        {
                                                TE_SetupBeamRingPoint(vec, radius2, radius1, g_BeamSprite, g_HaloSprite, 0, 10, g_fProximityIval, PINGWIDTH, 0.0, {255,255,255,255}, 10, 0);
                                	        TE_SendToClient(i);
				        }
			        }
        	        }
                }
                ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                decl String:buffer[100];
                Format(buffer,iterations+1,g_sMeter);                  // Generate Meter.. Probably could do this with strcopy faster, IDK SM functions.

                PrintCenterText(teammate, buffer);

                if (g_unfreezer[frozenguy] == teammate)
                {
                        PrintCenterText(frozenguy, buffer);            // Don't flood the client, they've got enough to worry about
                }

                new Handle:proxpack;                                   // Fire another timer, this same function once again
                CreateDataTimer(g_fProximityIval, Timer_ProxTestCountdown, proxpack, TIMER_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
                WritePackCell(proxpack, frozenguyuserid);
                WritePackCell(proxpack, teammateuserid);
                WritePackCell(proxpack, iterations-1);                 // teammate was in range, decrement counter
        }
        else                                                           // Teammate went outside of frozen player's proximity ring!
        {
                PrintCenterText(teammate, "");                         // Clear Center Text

                if (g_unfreezer[frozenguy] == teammate)
                {
                        PrintCenterText(frozenguy, "");
                        g_unfreezer[frozenguy] = 0;                    // If they were the first unfreezer, they arn't anymore.
                }

		g_playerProx[frozenguy][teammate] = 0;                 // Teammate moved away, reset state so this teamate can fire off new countdown

                return Plugin_Stop;                                    // We'd better get back, cause it'll be dark soon, and they mostly come at night... mostly
        }

	return Plugin_Continue;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Tests if two players are in range of eachother, returns true if they are
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
stock testProx(frozenguy, teammate)
{
        decl Float:Position1[3], Float:Position2[3], Float:maxdist;
        if (g_stuck[frozenguy] == 1)
        {
                maxdist = g_fFreezeDist + g_fFreezeDist;               // Double the distance for unstuck
        }
        else
        {
                maxdist = g_fFreezeDist;
        }
        GetClientAbsOrigin(frozenguy, Position1);
        GetClientAbsOrigin(teammate, Position2);
        if (GetVectorDistance(Position1, Position2, false) <= maxdist)
        {
        	return true;
        }
	return false;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Resets the proximity array for a client
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
purgeProximity(client)
{
        for (new i=0; i<sizeof(g_playerProx[]); i++)
	{
		g_playerProx[client][i] = 0;				        // Initialize client array
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Broadcasts a fake event message to notify players of a player unfreeze
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
broadcastUnfreeze(frozenguy,teammate)                                           // Can be seen in logs, awards point on scoreboard for control point defense
{
        if (frozenguy == teammate)                                              // Self revive, special case
        {
	        new clientsteam = GetClientTeam(frozenguy);                     // Don't broadcast messages on auto-revive respawn
                if ((g_fAutoHPRatioRed  == 0.0  && clientsteam == RED) ||
	            (g_fAutoHPRatioBlue == 0.0  && clientsteam == BLU))
	        {
                        return;                                                 
                }
                else
                {                     
                        new Handle:event = CreateEvent("teamplay_capture_blocked");
			if (event != INVALID_HANDLE)
			{
                                SetEventString(event, "cpname", "themself!");   // Broadcast MSG = Frozenguy (icon) defended themself!
                                SetEventInt(event, "blocker", teammate);
                                FireEvent(event);
			}
                }
        }
        else
        {
                new Handle:event = CreateEvent("teamplay_capture_blocked");
		if (event != INVALID_HANDLE)
		{
                        decl String:namefrozen[30];
                        decl String:buffer[40] = "teammate ";
                        GetClientName(frozenguy, namefrozen, 30);
                        StrCat(buffer, 40, namefrozen);
	                SetEventString(event, "cpname", buffer);                // Broadcast MSG = Teammate (icon) defended teammate Frozenguy
	                SetEventInt(event, "blocker", teammate);
                        FireEvent(event);
                }
        }
        return;
}

///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// Block Commands ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Prevents frozen players from taunting, and medics from using  ubersaw taunts on frozen players
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Command_InterceptTaunt(client, const String:command[], args)
{
	if (g_bFrozen[client])                                                                                 // Do not allow forzen players to taunt, handles heavy fists and taunt revive bugs
	{
		return Plugin_Handled;
	}
        if (g_activeround == 2 && (TF2_GetPlayerClass(client) == TFClass_Medic))                               // Block Ubersaw Taunt, gives uber when taunting corpsicles
	{
		new weapon = GetEntPropEnt( client, Prop_Send, "m_hActiveWeapon" );
		if (weapon > MaxClients && IsValidEntity( weapon ))
		{
			new idx = GetEntProp( weapon, Prop_Send, "m_iItemDefinitionIndex" );
			if ( idx == 37 || idx == 1003 )
			{
                                return Plugin_Handled;
                        }                             
	        }
        }

	return Plugin_Continue;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Prevents frozen players from using action item taunts
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Command_InterceptItemTaunt(client, const String:command[], args)
{
	if (g_bFrozen[client])
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Prevents frozen players from suiciding
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Command_InterceptSuicide(client, const String:command[], args)                    // Kill + Explode is blocked
{
	if ((g_activeround && g_bFrozen[client]))                                               // Block Suicide of Frozen Players and in the Pre-Round
	{
		if (g_bFeedback)
		{
			PrintToChat(client, "\x04[Freeze]:\x01 %t","feedback_suicide_activeround");
		}
                return Plugin_Handled;
	}

	return Plugin_Continue;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Prevents players from changing teams
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Command_InterceptSwap(client, const String:command[], args)                       // Spectate + Jointeam is blocked
{
	if (g_activeround == 2 && !g_bUnassigned[client])
	{                                                                                       // Block Swaps in the Active Round for Active Players
		if (g_bFeedback)
		{
			PrintToChat(client, "\x04[Freeze]:\x01 %t","feedback_jointeam_activeround");
		}
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Prevents players from changing class if frozen or if the option is disabled
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Command_InterceptClass(client, const String:command[], args)                       // Joinclass is blocked
{
        if (g_activeround == 2 && !g_bUnassigned[client])
	{                                                                                        // Block Swaps in the Active Round for Active Players
                if (g_bFrozen[client])                                                           // They are frozen, changing class would kill them again.
                {
                	if (g_bFeedback)
			{
                  		PrintToChat(client, "\x04[Freeze]:\x01 %t","feedback_joinclass_suicide_activeround");
			}
			return Plugin_Handled;
                }
                if (!g_bRemoveRespawnrooms && g_bInrespawnroom[client])
                {
                        return Plugin_Continue;                                                  // They are changing class in a respawn room, they don't need feedback
                }
                if (g_bFeedback)
		{
			if (!g_bJoinclasswarn[client])                                           // Late joiners will recieve this right away due to double-join
			{
                                PrintToChat(client, "\x04[Freeze]:\x01 %t","feedback_joinclass_warn_activeround");
                                if (GetRandomInt(0,1))
                                {
                                        EmitSoundToClient(client,SOUNDJOINCLASS1,_,SNDCHAN_VOICE,SNDLEVEL_NORMAL,_,1.0,_,_,_,_,_,_);
                                }
                                else
                                {
                                        EmitSoundToClient(client,SOUNDJOINCLASS2,_,SNDCHAN_VOICE,SNDLEVEL_NORMAL,_,1.0,_,_,_,_,_,_);
                                }
                                g_bJoinclasswarn[client] = true;
                                return Plugin_Handled;                                           // Warn the client that they might kill themselves.
			}
			else                                                                     // They've been warmed, allow the class change command to go through.
			{
                                if (g_bAllowChangeclass)
                                {
                                        PrintToChat(client, "\x04[Freeze]:\x01 %t","feedback_joinclass_currentround");
                                }
                                else
                                {
                                        PrintToChat(client, "\x04[Freeze]:\x01 %t","feedback_joinclass_activeround");
                                }
		        }
                }
	}
        else if (g_activeround)                                                                  // Force new joiners and pre-round suiciders to respawn instantly
        {
                CreateTimer(0.0, Timer_RespawnPlayer, GetClientUserId(client));                  // Respawn them on the next frame
        }

	return Plugin_Continue;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Respawns a player
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Timer_RespawnPlayer(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
        if (client && IsClientInGame(client))
	{
                TF2_RespawnPlayer(client);
        }
}

public Action:OnPlayerRunCmd( client, &buttons, &Impulse, Float:Vel[3], Float:Angles[3], &Weapon)
{
	if (g_bFrozen[client])
	{
		buttons &= ~(IN_JUMP|IN_ATTACK|IN_ATTACK2);                                      // Prevent jumping and attacking
	}

        return Plugin_Continue;
}

///////////////////////////////////////////////////////////////////////////////////
////////////////////////////////// Read Config ////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Reads map-specific configuration variables from a file
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
ReadMapConfigs()                                                                                 // Loads settings from file and calculates timings
{                                                                                                // Values will be range checked
	new Handle:kv = CreateKeyValues("FreezeMaps");
	decl String:file[256];
	BuildPath(Path_SM, file, sizeof(file), "configs/freezetag_maps.cfg");
	if (!FileToKeyValues(kv, file))
	{
		CloseHandle(kv);
		
		SetFailState("[TF2] Freeze Tag: Unable to locate required configuration file: %s", file);
		return;
	}

        decl String:mapName[32];
	GetCurrentMap(mapName, sizeof(mapName));

	for (new i=1; mapName[i] != '\0'; i++)
        {                                                                   // Just parse between deliminators
		if (IsCharUpper(mapName[i]))
                {
			mapName[i] = CharToLower(mapName[i]);
		}
	}

        if (KvJumpToKey(kv, mapName))                                       // Map Found
        {
                LogMessage("[TF2] Freeze Tag: Located entry for map: %s in the freezetag configuration file, loading map-specific settings.",mapName);
        }
	else
	{
		LogMessage("[TF2] Freeze Tag: Could not find map: %s in the freezetag configuration file, no map-specific settings were loaded!",mapName);
                KvRewind(kv);                                               // Start from begining

                if (strncmp(mapName, "pl_", 3) == 0)                        // Payload default
                {
                        KvJumpToKey(kv, "pl_");
                        LogMessage("[TF2] Freeze Tag: Loading default settings template for prefix: pl");
                }
                else if (strncmp(mapName, "plr_", 4) == 0)                  // Payload race default
                {
                        KvJumpToKey(kv, "plr_");
                        LogMessage("[TF2] Freeze Tag: Loading default settings template for prefix: plr");
                }
                else if (strncmp(mapName, "cp_", 3) == 0)                   // Capture Points default
                {
                        KvJumpToKey(kv, "cp_");
                        LogMessage("[TF2] Freeze Tag: Loading default settings template for prefix: cp");
                }
                else if (strncmp(mapName, "ctf_", 4) == 0)                  // Capture The Flag default
                {
                        KvJumpToKey(kv, "ctf_");
                        LogMessage("[TF2] Freeze Tag: Loading default settings template for prefix: ctf");
                }
                else if (strncmp(mapName, "tc_", 3) == 0)                   // Territory Control default
                {
                        KvJumpToKey(kv, "tc_");
                        LogMessage("[TF2] Freeze Tag: Loading default settings template for prefix: tc");
                }
                else if (strncmp(mapName, "arena_", 6) == 0)                // Arena default
                {
                        KvJumpToKey(kv, "arena_");
                        LogMessage("[TF2] Freeze Tag: Loading default settings template for prefix: arena");
                }
                else if (strncmp(mapName, "koth_", 5) == 0)                 // Koth default
                {
                        KvJumpToKey(kv, "koth_");
                        LogMessage("[TF2] Freeze Tag: Loading default settings template for prefix: koth");
                }
                else if (strncmp(mapName, "dm_", 3) == 0)                   // Deathmatch default
                {
                        KvJumpToKey(kv, "dm_");
                        LogMessage("[TF2] Freeze Tag: Loading default settings template for prefix: dm");
                }
                else if (strncmp(mapName, "trade_", 6) == 0)                // Trade default
                {
                        KvJumpToKey(kv, "trade_");
                        LogMessage("[TF2] Freeze Tag: Loading default settings template for prefix: trade");
                }
                else                                                        // Universal Fallback
                {
                        KvJumpToKey(kv, "default");
                        LogMessage("[TF2] Freeze Tag: No prefix exists for this map, using the default template.");
                }
        }

        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Global Variable ///////////////////////////////// Value ////////// Default // Min // Max ///////////// Usage ////////////////////////////////////////////////////////////
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        g_preRoundTime =              clampNum(KvGetNum(kv, "preround",         10),    0,     20     );   // pre-round length, 0 to disable
        g_roundLength =               clampNum(KvGetNum(kv, "timer",            300),   0,     5940   );   // round time, 0 to disable
        g_bEliminations =            clampBool(KvGetNum(kv, "eliminations",     1)/*    0,     1    */);   // allow for eliminations, 1 - enable eliminations, 0 - disable
        g_maxRounds =                 clampNum(KvGetNum(kv, "maxrounds",        30),    0,     100    );   // maximum rounds allowed, 0 to disable
        g_fFreezeDist =           clampFloat(KvGetFloat(kv, "radius",           150.0), 100.0, 300.0  );   // unfreeze radius units
        g_freezeDur =                 clampNum(KvGetNum(kv, "duration",         3),     1,     10     );   // unfreeze duration seconds
        g_openDoors =                 clampNum(KvGetNum(kv, "opendoors",        1),     0,     2      );   // open door method 1 - gently, 2- delete, 0 - do not open and preserve game timer
        g_bRemoveRespawnrooms =      clampBool(KvGetNum(kv, "removespawns",     1)/*    0,     1    */);   // remove respawn rooms and visualizers, 1 - remove, 0 - do not remove
        g_bOpenAPs =                 clampBool(KvGetNum(kv, "openaps",          0)/*    0,     1    */);   // open area portals, 1 - open all, 0 - do nothing
        g_bDisableCaps =             clampBool(KvGetNum(kv, "blockcaps",        1)/*    0,     1    */);   // block capture points, 1 - disable them, 0 - enable
        g_bDisableFlags =            clampBool(KvGetNum(kv, "blockflags",       1)/*    0,     1    */);   // block flags, 1 - disable them, 0 - enable
        g_bDisableTrains =           clampBool(KvGetNum(kv, "blocktrains",      0)/*    0,     1    */);   // block tanktrains, 1 - disable them, 0 - enable
        g_fUnfreezeHPRatioRed =   clampFloat(KvGetFloat(kv, "hpratiored",       0.5),   0.01,  1.0    );   // percent of health restored when unfrozen on red
        g_fUnfreezeHPRatioBlue =  clampFloat(KvGetFloat(kv, "hpratioblue",      0.5),   0.01,  1.0    );   // percent of health restored when unfrozen on blue
        g_autoTimeRed =               clampNum(KvGetNum(kv, "autotimered",      60),    0,     5940   );   // time to be unfrozen automatically for red, 0 to unfreeze in respawnroom
        g_autoTimeBlue =              clampNum(KvGetNum(kv, "autotimeblue",     60),    0,     5940   );   // time to be unfrozen automatically for blue, 0 to unfreeze in respawnroom
        g_fAutoHPRatioRed =       clampFloat(KvGetFloat(kv, "autohpratiored",   0.25),  0.0,   1.0    );   // percent of health restored when unfrozen automatically on red
        g_fAutoHPRatioBlue =      clampFloat(KvGetFloat(kv, "autohpratioblue",  0.25),  0.0,   1.0    );   // percent of health restored when unfrozen automatically on blu
        g_bTrackDamage =             clampBool(KvGetNum(kv, "trackdamage",      1)/*    0,     1    */);   // resets automatic unfreeze timer on damage, 1 - allow resets, 0 - do not reset
        g_bAllowChangeclass =        clampBool(KvGetNum(kv, "allowchangeclass", 0)/*    0,     1    */);   // allow class change while a round is active, 1 - alow changes, 0 - do not allow

        CloseHandle(kv);

	g_proximityIter = RoundToNearest(g_freezeDur/g_fProximityIval);                                    // calculate the interations here, and store it to save flops.
        g_fRingIval = g_fProximityIval + 0.1;
        g_autoTimeRedMax = RoundToCeil(g_autoTimeRed/g_fProximityIval);
        g_autoTimeBlueMax = RoundToCeil(g_autoTimeBlue/g_fProximityIval);

        if(!g_mapTime && !g_maxRounds)                                                                     // warn ops who may have their server set up incorrectly.
        {
                LogMessage("[TF2] Freeze Tag: WARNING, You Have both [mp_timlimit 0] and [maxrounds 0] set, your map may never cycle!");
        }

        return;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Returns a float within the specified range
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
stock Float:clampFloat(Float:val, Float:lower, Float:upper)
{
        if (val < lower)
        {
                return lower;
        }
        if (val > upper)
        {
                return upper;
        }

        return val;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Returns an integer within the specified range
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
stock clampNum(val, lower, upper)
{
        if (val < lower)
        {
                return lower;
        }
        if (val > upper)
        {
                return upper;
        }

        return val;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Returns true if the input is nonzero, false if it is zero
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
stock bool:clampBool(val)
{
        if (val == 0)
        {
                return false;
        }

        return true;
}

///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////// Particles YAY ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Spwans an info_particle_system and emits particles
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

AttachParticle(ent)         // Borrowed from RTD and stripped down
{
	new particle = CreateEntityByName("info_particle_system");
	if (particle > MaxClients && IsValidEntity(particle))
	{
		new Float:pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += PARTICLEZ;

                DispatchKeyValueVector(particle, "origin", pos);

		DispatchKeyValue(particle, "effect_name", "xms_snowburst");
		DispatchSpawn(particle);

		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");

		CreateTimer(5.0, Timer_RemoveEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	}
}

///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////// Third Person ////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Forces a client into third person
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
setThirdPerson(client, bool:val)
{
        if(val)                                                                          // set them to third
        {
                CreateTimer(0.1, Timer_EnableTp, GetClientUserId(client));
        }
        else                                                                             // set them to first
        {
                if(g_cam == 2 && g_bThirdperson[client])                                 // client pref is first
                {
                        CreateTimer(0.2, Timer_EnableTp, GetClientUserId(client));       // Toggles FP first, to fix random glitches with it
                }
                else
                {
                        CreateTimer(0.2, Timer_EnableFp, GetClientUserId(client));       // Go to FP
                }
        }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Forces a client into first person and then third person after a short time
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Timer_EnableTp(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
        if (client && IsClientInGame(client) && IsPlayerAlive(client))                   // Perhaps their ent could take the input if they are dead.
	{
		SetVariantInt(0);                                                        // Enable FP camera
		AcceptEntityInput(client, "SetForcedTauntCam");
		CreateTimer(0.2, Timer_EnableTp2, userid);                               // Because sometimes, delay
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Forces a client into third person after some time
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Timer_EnableTp2(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
        if (client && IsClientInGame(client) && IsPlayerAlive(client))                   // Perhaps their ent could take the input if they are dead.
	{
		SetVariantInt(1);                                                        // Enable TP camera
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Forces a client into first person after some time
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Timer_EnableFp(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
        if (client && IsClientInGame(client) && IsPlayerAlive(client))                   // Perhaps their ent could take the input if they are dead.
	{
		SetVariantInt(0);                                                        // Enable FP camera
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Purpose: Finds stuff the other version may have missed
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}