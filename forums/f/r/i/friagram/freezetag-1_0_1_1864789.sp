/*
- Removed code changing hats back to transcolor before unfreezing players
- Optimized code calculating ring size, new/decl, and the way some data was handled.
- Added unfreeze ring progress indicators (white rings will expand outward, team visible only, only highest progress will show).
- Fixed the display of progress bars for frozen players (they will only see the highest progress).
- Removed ammo packs / dropped weapons / dispenser rubble from collision detection.
- Decreased the delay on respawning people in place (0.1 to 0.0).
- Changed death vector to store client eye positition (Players will now spawn looking up/down in the direction they died).
- Changed death vector to not teleport bots' velocities (they won't pop around when unfrozen).
- Late loading the plugin will now skip the first round (intended for waiting for players).
- Ice block will tilt a bit randomy.
- Players being unfrozen inside of entities will be teleported into teammates in the ducking position (so they won't get stuck in geometry).
- Map will not cycle if mp_timelimit is set to 0.
- Added Cvar and Config option for round limits to force map cycling (maxrounds in cfg, sm_freezetag_rounds convar)
- Added loop to remove screen overlay on round start
- Added log messages for incorrect map/time settings
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <sdkhooks>

#define PLUGIN_NAME                             "[TF2] Freeze Tag"
#define PLUGIN_AUTHOR                           "Friagram"
#define PLUGIN_VERSION                          "1.0.1"
#define PLUGIN_CONTACT                          "http://steamcommunity.com/groups/poniponiponi"

#define MODEL_ICEBLOCK  "models/custom/freezetag/iceblock.mdl"

#define RINGHEIGHT      15                                           // Height of ring from ground
#define RINGWIDTH       10.0                                         // Thickness of ring
#define PINGWIDTH       5.0                                          // Thickness of smaller progress rings

#define SOUND60         "HL1/fvox/sixty.wav"
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

#define SOUND_REVIVE    "items/smallmedkit1.wav"                      // Played just to client on revive

#define SPEC      1           // There are already defines for this, but I prefer my way
#define RED       2
#define BLU       3
#define STALEMATE 0

#define HUDX1 0.18  // FREEZE X
#define HUDY1 0.02  // FREEZE Y RED
#define HUDY2 0.06  // FREEZE Y BLU
#define HUDX2 -1.0  // TIMER X
#define HUDY3 0.10  // TIMER Y

#define PLAYERXY      60      // Distance to move players from origin of other players along the X/Y axis  49
#define PLAYERZ       50      // Height to raise on second iteration set
#define STUCKDISTANCE 80      // Distance to scan for players to unstick them

new Handle:g_hCvarVersion = INVALID_HANDLE;
new Handle:g_hCvarEnabled = INVALID_HANDLE;
new Handle:g_hCvarRadius = INVALID_HANDLE;
new Handle:g_hCvarduration = INVALID_HANDLE;
new Handle:g_hCvarproxpulse = INVALID_HANDLE;
new Handle:g_hCvarForceMulti = INVALID_HANDLE;
new Handle:g_hCvarForceCap = INVALID_HANDLE;
new Handle:g_hCvarOpenDoors = INVALID_HANDLE;
new Handle:g_hCvarOpenAPs = INVALID_HANDLE;
new Handle:g_hCvarDisableCaps = INVALID_HANDLE;
new Handle:g_hCvarDisableFlags = INVALID_HANDLE;
new Handle:g_hCvarUnfreezeHPRatio = INVALID_HANDLE;
new Handle:g_hCvarPreRoundTime = INVALID_HANDLE;
new Handle:g_hCvarFeedback = INVALID_HANDLE;
new Handle:g_hCvarTimer = INVALID_HANDLE;
new Handle:g_hCvarDisableTrains = INVALID_HANDLE;
new Handle:g_hCvarTimeLimit = INVALID_HANDLE;
new Handle:g_hCvarMaxRounds = INVALID_HANDLE;

new String:g_version[12];                       // Version Number
new bool:g_bEnabled;                            // Is the mod enabled?
new Float:g_freezeDist;                         // Radius to unfreeze a teammate
new g_freezeDur;                                // Seconds to unfreeze teammate
new Float:g_proximityIval;                      // Update interval for freeze beacon pulse
new Float:g_forceMulti;                         // Damage force multiplier for pushing players
new Float:g_forceCap;                           // Damage force cap for pushing players
new g_openDoors;                                // Open doors, 0 don't, 1 force open, 2 delete
new bool:g_openAPs;                             // Open doors, 0 don't, 1 open Area Portals
new bool:g_disableCaps;                         // Block players from capping points
new bool:g_disableFlags;                        // Block players from capping flags
new Float:g_unfreezeHPRatio;                    // Percent of health to restore them with when unfrozen
new g_preRoundTime;                             // Time to allow respawning and class change
new bool:g_feedback;                            // Do we want to show help messages?
new g_timeLeft;                                 // Length of round timer, in seconds
new bool:g_bDisableTrains;                      // Disable tracktrains
new g_mapTime;                                  // Length of map timer in seconds (mp_timelimit)
new g_maxRounds;                                // Max number of rounds to play (0 for no limit)

new g_proximityIter;                            // Stores iteration count for beacons

new bool:unassigned[MAXPLAYERS+1];		// Track New Players
new bool:frozen[MAXPLAYERS+1];			// Track Frozen Players
new activeround = 0;                            // Not active = 0, preround = 1, active = 2
new Float:deathVec[MAXPLAYERS+1][3];		// Track Death Positions
new Float:deathAng[MAXPLAYERS+1][3];		// Track Death Angle
new Float:deathVel[MAXPLAYERS+1][3];		// Track Death Velocity - LOL
new bool:deathDuck[MAXPLAYERS+1];               // Track Crouching State
new playerProx[MAXPLAYERS+1][MAXPLAYERS+1];	// Track Nearby Players When Frozen, BIG!
new bool:respawned[MAXPLAYERS+1];               // Track players being moved to spawnroom
new stuck[MAXPLAYERS+1];                        // Allow players to request being unstuck
new iceblock[MAXPLAYERS+1] = { -1, ... };       // Track iceblock models
new Float:chargemeter[MAXPLAYERS+1];            // Track charge meters
new TFClassType:playerclass[MAXPLAYERS+1];      // Track player's class so they can't change in maps without respawnrooms
new unfreezer[MAXPLAYERS+1];                    // Track the unfreezing client

static String:meter[] = "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";   // Progress Bar.. lol @ max len

new g_GlowSpriteRed;
new g_GlowSpriteBlue;
new gHalo1;

new g_cloakOffset;
//new g_offsCollisionGroup;

new g_roundTimeleft;                              // Game Timer
new Handle:timeleftHUD;
new Handle:g_gametimer;
new Float:g_mapStartTime;                         // Stores start time of map

new bool:bLateLoaded = false;
new g_rounds;                                     // Use this to track "waiting for players"
new g_bluscore;                                   // scoreboard tracking, some maps won't update properly
new g_redscore;

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
	bLateLoaded = bLateLoad;
	return APLRes_Success;
}

public OnPluginStart()
{
	g_hCvarVersion = CreateConVar("sm_tf2freezetag_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);

  	g_hCvarEnabled = CreateConVar("sm_freezetag_enabled", "1.0", "Enable/Disable Freezetag Mode [0/1]", FCVAR_PLUGIN, true, 0.0, true, 1.0);
        HookConVarChange(g_hCvarEnabled, ConVarEnabledChanged);

  	g_hCvarRadius = CreateConVar("sm_freezetag_radius", "150.00", "Unfreeze Radius Units [100-300]", FCVAR_PLUGIN, true, 100.0, true, 300.0);
        HookConVarChange(g_hCvarRadius, ConVarRadiusChanged);

   	g_hCvarduration = CreateConVar("sm_freezetag_duration", "3.0", "Unfreeze Duration [1-10]", FCVAR_PLUGIN, true, 1.0, true, 10.0);
        HookConVarChange(g_hCvarduration, ConVarDurationChanged);

  	g_hCvarproxpulse = CreateConVar("sm_freezetag_proxpulse", "0.33", "Update Interval For Beacons [0.1-1.0]", FCVAR_PLUGIN, true, 0.1, true, 1.0);
        HookConVarChange(g_hCvarproxpulse, ConVarProxPulseChanged);

  	g_hCvarForceMulti = CreateConVar("sm_freezetag_forcemulti", "10.00", "Damage Force Multiplier To Push Frozen People [0-1000]", FCVAR_PLUGIN, true, 0.0, true, 100.0);
        HookConVarChange(g_hCvarForceMulti, ConVarForceMultiChanged);

  	g_hCvarForceCap = CreateConVar("sm_freezetag_forcecap", "500.00", "Damage Force Cap To Push Frozen People [0-5000]", FCVAR_PLUGIN, true, 0.0, true, 5000.0);
        HookConVarChange(g_hCvarForceCap, ConVarForceCapChanged);

  	g_hCvarOpenDoors = CreateConVar("sm_freezetag_opendoors", "1.0", "0 - Do Not Change, 1 - Force Open, 2 - Remove Doors", FCVAR_PLUGIN, true, 0.0, true, 2.0);
        HookConVarChange(g_hCvarOpenDoors, ConVarOpenDoorsChanged);
        
  	g_hCvarOpenAPs = CreateConVar("sm_freezetag_openaps", "0.0", "0 - Do Not Change, 1 - Open Area Portals", FCVAR_PLUGIN, true, 0.0, true, 1.0);
        HookConVarChange(g_hCvarOpenAPs, ConVarOpenAPsChanged);

  	g_hCvarDisableCaps = CreateConVar("sm_freezetag_blockcaps", "1.0", "Enable/Disable Capture Points and Payloads [0/1]", FCVAR_PLUGIN, true, 0.0, true, 1.0);
        HookConVarChange(g_hCvarDisableCaps, ConVarForceDisableCapsChanged);

  	g_hCvarDisableFlags = CreateConVar("sm_freezetag_blockflags", "1.0", "Enable/Disable Flag Captures [0/1]", FCVAR_PLUGIN, true, 0.0, true, 1.0);
        HookConVarChange(g_hCvarDisableFlags, ConVarForceDisableFlagsChanged);

  	g_hCvarUnfreezeHPRatio = CreateConVar("sm_freezetag_hpratio", "0.5", "Unfreeze Health Restore Ratio [0.01-1.0]", FCVAR_PLUGIN, true, 0.01, true, 1.0);
        HookConVarChange(g_hCvarUnfreezeHPRatio, ConVarUnfreezeHPRatioChanged);

  	g_hCvarPreRoundTime = CreateConVar("sm_freezetag_preround", "10", "Preround Time to Allow Class Change in Seconds [0-20]", FCVAR_PLUGIN, true, 0.00, true, 20.0);
        HookConVarChange(g_hCvarPreRoundTime, ConVarPreRoundTimeChanged);

  	g_hCvarFeedback = CreateConVar("sm_freezetag_feedback", "1.0", "Enable/Disable Notification Messages [0/1]", FCVAR_PLUGIN, true, 0.0, true, 1.0);
        HookConVarChange(g_hCvarFeedback, ConVarFeedbackChanged);

  	g_hCvarTimer = CreateConVar("sm_freezetag_timer", "300", "Round Timer Length [60-1800]", FCVAR_PLUGIN, true, 60.0, true, 1800.0);
        HookConVarChange(g_hCvarTimer, ConVarTimeLeftChanged);

  	g_hCvarMaxRounds = CreateConVar("sm_freezetag_rounds", "30", "Max Rounds to Play [0-100]", FCVAR_PLUGIN, true, 0.0, true, 100.0);
        HookConVarChange(g_hCvarMaxRounds, ConVarMaxRoundsChanged);

  	g_hCvarDisableTrains = CreateConVar("sm_freezetag_disabletrains", "0.0", "Enable/Disable Tank Trains [0/1]", FCVAR_PLUGIN, true, 0.0, true, 1.0);
        HookConVarChange(g_hCvarDisableTrains, ConVarDisableTrainsChanged);
        
	g_hCvarTimeLimit = FindConVar("mp_timelimit");
	HookConVarChange(g_hCvarTimeLimit, ConVarTimeLimitChanged);

	decl String:gamedir[8];
	GetGameFolderName(gamedir, 8);
	if (!StrEqual(gamedir, "tf", false) && !StrEqual(gamedir, "tf_beta", false))
	{
		SetFailState("Freeze tag will only work for Team Fortress 2.");
        }
        
	RegAdminCmd("sm_freezetag_reloadconfigs", Command_Reloadconfigs, ADMFLAG_RCON, "Reload the Configuration File");
	RegAdminCmd("sm_freezetag_unfreeze", Command_Unfreeze, ADMFLAG_CHEATS, "Unfreeze Players in an Active Round");

	RegConsoleCmd("sm_freezetag", freezemenu);
	RegConsoleCmd("freezetag", freezemenu);

	RegConsoleCmd("stuck", Command_UnStuck);
	RegConsoleCmd("sm_stuck", Command_UnStuck);
	RegConsoleCmd("unstuck", Command_UnStuck);
	RegConsoleCmd("sm_unstuck", Command_UnStuck);

	HookEvent("teamplay_round_start", event_round_start);
	HookEvent("player_death", event_player_death);
	HookEvent("post_inventory_application", post_inventory_application,  EventHookMode_Post);

	AddCommandListener(Command_InterceptSuicide, "kill");                                           // Kill + Explode Alias
	AddCommandListener(Command_InterceptSuicide, "explode");

	AddCommandListener(Command_InterceptSwap, "spectate");                                          // Spectate + Jointeam Alias
	AddCommandListener(Command_InterceptSwap, "jointeam");

	AddCommandListener(Command_InterceptClass, "joinclass");
	
	AddCommandListener(Command_InterceptTaunt, "+taunt");
	AddCommandListener(Command_InterceptTaunt, "taunt");

	AddCommandListener(Command_InterceptItemTaunt, "+use_action_slot_item_server");
	AddCommandListener(Command_InterceptItemTaunt, "use_action_slot_item_server");

	g_cloakOffset = FindSendPropInfo("CTFPlayer", "m_flCloakMeter");                                // Spy Stealth meter

	timeleftHUD = CreateHudSynchronizer();                                                          // HUD printout for RED/BLU frozen and Timer

        LoadTranslations("freezetag.phrases");
	LoadTranslations("common.phrases");

        if (bLateLoaded)                                                                                // Plugin was loaded late, let's hook everything we need
	{
		new ent = -1;
		while ((ent = FindEntityByClassname(ent, "trigger_hurt")) != -1)                        // This shit will kill people, better respawn them
		{
			SDKHook(ent, SDKHook_StartTouch, OnHurtTouch);
			SDKHook(ent, SDKHook_Touch, OnHurtTouch);
		}
		ent = -1;
                while ((ent = FindEntityByClassname(ent, "trigger_capture_area")) != -1)                // Frozen people should not be able to cap
		{
			SDKHook(ent, SDKHook_StartTouch, OnCPTouch );
			SDKHook(ent, SDKHook_Touch, OnCPTouch);
		}
		ent = -1;
                while ((ent = FindEntityByClassname(ent, "trigger_multiple")) != -1)                    // Fix Doors From Closing
		{
			SDKHook(ent, SDKHook_StartTouch, OnDoorTouch);
			SDKHook(ent, SDKHook_Touch, OnDoorTouch);
		}
		ent = -1;
                while ((ent = FindEntityByClassname(ent, "trigger_teleport")) != -1)                    // Teleports on custom maps
		{
			SDKHook(ent, SDKHook_StartTouch, OnTeleTouch);
			SDKHook(ent, SDKHook_Touch, OnTeleTouch);
		}
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "item_teamflag")) != -1)                       // Frozen people should not interact with flags
		{
			SDKHook(ent, SDKHook_StartTouch, OnFlagTouch);
			SDKHook(ent, SDKHook_Touch, OnFlagTouch);
		}
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "player" )) != -1)                             // Hook players for damage prevention and force push
		{
			SDKHook(ent, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public OnConfigsExecuted()
{
	new String:strVersion[16]; GetConVarString(g_hCvarVersion, strVersion, sizeof(strVersion));
	if (StrEqual(strVersion, PLUGIN_VERSION) == false)
	{
		LogError("[TF2] Freeze Tag: WARNING, Your version has changed. Make sure your config file is up to date.");
	}
	SetConVarString(g_hCvarVersion, PLUGIN_VERSION);
	
	g_bEnabled = GetConVarBool(g_hCvarEnabled);

	if (g_bEnabled)                                                                                 // Let's Make Arena More Friendly
	{
		SetConVarInt(FindConVar("tf_arena_use_queue"),0);                                       // Allow full server to join in arena
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"),1);                                 // Force team balancing
		SetConVarInt(FindConVar("tf_arena_first_blood"),0);                                     // Overpowered
                SetConVarInt(FindConVar("mp_stalemate_enable"),0);                                      // Bad things will happen if stalemate is on
//		SetConVarInt(FindConVar("mp_forcecamera"),0);                                           // Not needed since now they don't actually stay dead -- rip ragdoll ice statues
//		SetConVarInt(FindConVar("mp_waitingforplayers_time"),60);                               // Someponies load slow, make it longer for them  -- better to put in server//map config

	        g_freezeDist = GetConVarFloat(g_hCvarRadius);                                           // freeze radius
	        g_freezeDur = GetConVarInt(g_hCvarduration);                                            // unfreeze time
	        g_proximityIval = GetConVarFloat(g_hCvarproxpulse);                                     // frequency of proximity updates
	        g_proximityIter = RoundToNearest(g_freezeDur/g_proximityIval);                          // calculate the interations here, and store it to save flops
	        g_forceMulti = GetConVarFloat(g_hCvarForceMulti);                                       // force multiplier
	        g_forceCap = GetConVarFloat(g_hCvarForceCap);                                           // force limit
	        g_openDoors = GetConVarInt(g_hCvarOpenDoors);                                           // door open method
	        g_openAPs = GetConVarBool(g_hCvarOpenAPs);                                              // open area portals?
	        g_disableCaps = GetConVarBool(g_hCvarDisableCaps);                                      // disable capture points?
	        g_disableFlags = GetConVarBool(g_hCvarDisableFlags);                                    // disable flags?
	        g_unfreezeHPRatio = GetConVarFloat(g_hCvarUnfreezeHPRatio);                             // unfreeze health ratio?
	        g_preRoundTime = GetConVarInt(g_hCvarPreRoundTime);                                     // preround time for class swaps
 	        g_feedback = GetConVarBool(g_hCvarFeedback);                                            // notification messages
	        g_timeLeft = GetConVarInt(g_hCvarTimer);                                                // round timelimit
	        g_bDisableTrains = GetConVarBool(g_hCvarDisableTrains);                                 // disable tank trains?
	        g_mapTime = GetConVarInt(g_hCvarTimeLimit) * 60;       // we need to track map time, so we can force map change for maps that have unconventional end triggers
                g_maxRounds = GetConVarInt(g_hCvarMaxRounds);                                           // rounds to play

                ReadMapConfigs();                                                                       // Load settings into convars from file, if possible (little slow, but happens once per map, and caps values).

                if(!g_mapTime && !g_maxRounds)
                {
                        LogMessage("[TF2] Freeze Tag: WARNING, You Have both [mp_timlimit 0] and [maxrounds 0] set, your map may never cycle!");
                }
	}
}

public OnMapStart()
{
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

	g_GlowSpriteRed = PrecacheModel("materials/sprites/halo01.vmt", true);                           // used for red proximity circles
        g_GlowSpriteBlue = PrecacheModel("sprites/blueglow2.vmt", true);                                 // used for blu proximity circles
	gHalo1 = PrecacheModel("materials/sprites/halo01.vmt", true);

        PrecacheModel(MODEL_ICEBLOCK, true);                                                             // iceblock model
	AddFileToDownloadsTable("models/custom/freezetag/iceblock.dx80.vtx");
	AddFileToDownloadsTable("models/custom/freezetag/iceblock.dx90.vtx");
	AddFileToDownloadsTable("models/custom/freezetag/iceblock.mdl");
	AddFileToDownloadsTable("models/custom/freezetag/iceblock.sw.vtx");
	AddFileToDownloadsTable("models/custom/freezetag/iceblock.vvd");
	AddFileToDownloadsTable("materials/models/custom/freezetag/ice_tint.vmt");
        AddFileToDownloadsTable("materials/models/custom/freezetag/ice_tint2.vmt");

	activeround = 0;
	unfreezeAll();                                                                                    // forces all players into ready state, all timers/status will die gracefully
        
        g_rounds = 0;
        g_bluscore = 0;                                                                                   // track the scoreboard, so we can set it
        g_redscore = 0;

        g_gametimer = INVALID_HANDLE;
}

///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////// USER Commands ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

public Action:Command_UnStuck(client, args)        // allows a player to expand their proximity to be saved if knocked into an unreachable position.
{
        if (!IsValidClient(client) || !IsPlayerAlive(client)) return Plugin_Handled;
	if (!g_bEnabled)
        {
                PrintToChat(client, "\x04[Freeze]:\x01 %t","cmd_notenabled");
                return Plugin_Handled;
        }
	if (activeround == 1 || GetClientTeam(client) <= SPEC)
        {
                PrintToChat(client, "\x04[Freeze]:\x01 %t","cmd_fromspec");
                return Plugin_Handled;
        }
        if (!frozen[client])
        {
                PrintToChat(client, "\x04[Freeze]:\x01 %t","cmd_notfrozen");
        }
        else if (stuck[client] == 0)
        {
                PrintToChat(client, "\x04[Freeze]:\x01 %t","stuck_feedback_use");
                stuck[client] = 1;
        }
        else if (stuck[client] == 1)
        {
                PrintToChat(client, "\x04[Freeze]:\x01 %t","stuck_feedback_flagged");
        }
        else
        {
                PrintToChat(client, "\x04[Freeze]:\x01 %t","stuck_feedback_cd");
        }
        
	return Plugin_Handled;
}

public Action:Command_Reloadconfigs(client, args)   // forces the map configs to be immediately updated fromt he configuration file
{
        ReadMapConfigs();
        ReplyToCommand(client, "%t","cmd_reloadcfg");

	return Plugin_Handled;
}

public Action:Command_Unfreeze(client, args)        // unfreezes target player(s) as if they were unfrozen by a teammate
{
        if (!IsValidClient(client)) return Plugin_Handled;
	if (!g_bEnabled)
        {
                PrintToChat(client, "\x04[Freeze]:\x01 %t","cmd_notenabled");
                return Plugin_Handled;
        }

        new String:arg1[32];

	GetCmdArg(1, arg1, sizeof(arg1));

	if (args == 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_freezetag_unfreeze <target>");
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
                if (frozen[target_list[i]])
                {
                	unfreezeClient(target_list[i],target_list[i]);
                }
        }

	return Plugin_Handled;
}

///////////////////////////////////////////////////////////////////////////////////
/////////////////////////////// CONVAR Functions //////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

public ConVarEnabledChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_bEnabled = (StringToInt(newvalue) == 0 ? false : true);                                      // Let's Make Arena More Friendly :D
        if(activeround)                                                                                // If a round is in progress, kill it, else do nothing
        {
                ForceTeamWin(STALEMATE);
        }
}
public ConVarDurationChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_freezeDur = StringToInt(newvalue);
	g_proximityIter = RoundToNearest(g_freezeDur/g_proximityIval);  // If this is changed, recalculate again.
}
public ConVarProxPulseChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_proximityIval = StringToFloat(newvalue);
	g_proximityIter = RoundToNearest(g_freezeDur/g_proximityIval);  // calculate the interations here, and store it to save flops.
}
public ConVarRadiusChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_freezeDist = StringToFloat(newvalue);
}
public ConVarForceMultiChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_forceMulti = StringToFloat(newvalue);
}
public ConVarForceCapChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
        g_forceCap = StringToFloat(newvalue);
}
public ConVarOpenDoorsChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_openDoors = StringToInt(newvalue);
}
public ConVarOpenAPsChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_openAPs = (StringToInt(newvalue) == 0 ? false : true);
}
public ConVarForceDisableCapsChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_disableCaps = (StringToInt(newvalue) == 0 ? false : true);
}
public ConVarForceDisableFlagsChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_disableFlags = (StringToInt(newvalue) == 0 ? false : true);
}
public ConVarUnfreezeHPRatioChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_unfreezeHPRatio = StringToFloat(newvalue);
}
public ConVarPreRoundTimeChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_preRoundTime = StringToInt(newvalue);
}
public ConVarFeedbackChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_feedback = (StringToInt(newvalue) == 0 ? false : true);
}
public ConVarTimeLeftChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_timeLeft = StringToInt(newvalue);
}
public ConVarMaxRoundsChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_maxRounds = StringToInt(newvalue);

        PrintToChatAll("MRC %i,%i",g_mapTime,g_maxRounds);
        if(!g_mapTime && !g_maxRounds)
        {
                LogMessage("[TF2] Freeze Tag: WARNING, You Have both [mp_timlimit 0] and [maxrounds 0] set, your map may never cycle!");
        }
}
public ConVarDisableTrainsChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_bDisableTrains = (StringToInt(newvalue) == 0 ? false : true);
}
public ConVarTimeLimitChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_mapTime = StringToInt(newvalue) * 60;

        PrintToChatAll("MTC %i,%i",g_mapTime,g_maxRounds);
        if(!g_mapTime && !g_maxRounds)
        {
                LogMessage("[TF2] Freeze Tag: WARNING, You Have both [mp_timlimit 0] and [maxrounds 0] set, your map may never cycle!");
        }
}

///////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////// Info Menu /////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

public Action:freezemenu(client, args)
{
        if (!IsValidClient(client))
        {
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

Help_ShowMainMenu(client)
{
        new Handle:menu = CreateMenu(Help_MainMenuHandler);
	SetMenuExitBackButton(menu, false);

	decl String:buffer[40];
        Format(buffer, 40, "                 Freeze Tag %s", PLUGIN_VERSION);
	SetMenuTitle(menu, buffer);

	AddMenuItem(menu, "rules", "Rules & Gameplay");
	AddMenuItem(menu, "tips", "Tips & Tricks");
	AddMenuItem(menu, "commands", "Commands");
	AddMenuItem(menu, "settings", "Map Settings");
        AddMenuItem(menu, "weapons", "Weapon Changes");
        AddMenuItem(menu, "credits", "Special Thanks");

	DisplayMenu(menu, client, 30);
}

public Help_MainMenuHandler(Handle:menu, MenuAction:action, param1, param2)     // Just a info menu panel that shows rules, about info, etc.
{                                                                               // Would need to completely re-do this for translations because of bizzarre spacing
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

                        DrawPanelText(cpanel, "Kill an enemy to freeze them in place and disable them.\nTo revive a frozen teammate, stand within their aura.\nBonked, Cloaked, or Invisible players may not revive.\nA team wins by elimination if all members of the opposing team are frozen.\nIf time expires, the team with the higher ratio of non-frozen players wins." );
                }
                else if (param2 == 1)
                {
                        SetPanelTitle(cpanel, "Tips:");
                        DrawPanelText(cpanel, " ");

                        DrawPanelText(cpanel, "Attack frozen enemies to push them around the map and gain control.\nCrouch while attacking enemies at close range to knock them out of corners.\nAttack frozen enemies to prevent enemy teammates from reviving them.\nHide behind frozen teammates while reviving them or fighting to block damage.\nRevive your teammates when possible to overwhelm the enemy." );
                }
                else if (param2 == 2)
                {
                        SetPanelTitle(cpanel, "Commands:");
                        DrawPanelText(cpanel, " ");

                        DrawPanelText(cpanel, "/stuck       If you become stuck outside of the map while frozen, type /stuck.\n                 You will be revived in your spawn room, frozen and will incur a minor\n                 health penalty upon revival for the rest of the map\n                 May only be used once per round.\n" );
                        DrawPanelText(cpanel, "/freezetag                           Help menu and information." );


                        DrawPanelText(cpanel, "/freezetag_unfreeze           Unfreezes a player (Admin Only)." );
                        DrawPanelText(cpanel, "/freezetag_reloadconfigs   Reloads map configs (Admin Only)." );
                }
                else if (param2 == 3)
                {
                        SetPanelTitle(cpanel, "Settings:");
                        decl String:buffer[40];
                        DrawPanelText(cpanel, " ");

	                Format(buffer, 40,     "Preround Length:  %i Seconds", g_preRoundTime);
                        DrawPanelText(cpanel, buffer);
	                Format(buffer, 40,     "Round Length:  %i Seconds", g_timeLeft);
                        DrawPanelText(cpanel, buffer);
	                DrawPanelText(cpanel, (g_forceMulti*g_forceCap ? "Damage Push: Enabled" : "Damage Push: Disabled") );
	                Format(buffer, 40,     "Revive Health:  %i Percent", RoundFloat(g_unfreezeHPRatio*100) );
                        DrawPanelText(cpanel, buffer);
	                Format(buffer, 40,     "Unfreeze Duration:  %i Seconds", g_freezeDur);
	                DrawPanelText(cpanel, buffer);
	                Format(buffer, 40,     "Unfreeze Radius:  %i Units", RoundFloat(g_freezeDist));
                        DrawPanelText(cpanel, buffer);
	                DrawPanelText(cpanel, (g_disableCaps ? "Capture Points: Disabled" : "Capture Points: Enabled") );
	                DrawPanelText(cpanel, (g_disableFlags ? "Capture The Flag: Disabled" : "Capture The Flag: Enabled") );
	                DrawPanelText(cpanel, (g_feedback ? "Feedback: Enabled" : "Feedback: Disabled") );
	                if(g_openDoors == 0)
	                {
                                DrawPanelText(cpanel, "Doors: Unchanged" );
                        }
                        else if(g_openDoors == 1)
	                {
                                DrawPanelText(cpanel, "Doors: Forced Open" );
                        }
                        else
	                {
                                DrawPanelText(cpanel, "Doors: Removed" );
                        }
	                DrawPanelText(cpanel, (g_bDisableTrains ? "Tank Trains: Disabled" : "Tank Trains: Enabled") );
	                DrawPanelText(cpanel, (g_openAPs ? "Area Portals: Forced Open" : "Area Portals: Unchanged") );
                }
                else if (param2 == 4)
                {
                        SetPanelTitle(cpanel, "Weapon Info:");
                        DrawPanelText(cpanel, " ");

                        DrawPanelText(cpanel, "Cloak and Dagger:       Replaced with Watch." );
                        DrawPanelText(cpanel, "Eureka Effect:              Replaced with Wrench." );
                        DrawPanelText(cpanel, "Holiday Punch:            Replaced with Fists." );
                        DrawPanelText(cpanel, "Medigun:                     Provides crit-boost instead of invulnerability." );
                        DrawPanelText(cpanel, "Phlogistinator:            50% damage protection, provides mini-crits." );
                        DrawPanelText(cpanel, "Ubersaw:                     Taunt disabled." );
                }
                else if (param2 == 5)
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
	else if (StrEqual( strClassname, "trigger_teleport", false ))
	{
		SDKHook(ent, SDKHook_StartTouch, OnTeleTouch);
		SDKHook(ent, SDKHook_Touch, OnTeleTouch);
	}
	else if (StrEqual( strClassname, "item_teamflag", false ))
	{
		SDKHook(ent, SDKHook_StartTouch, OnFlagTouch);
		SDKHook(ent, SDKHook_Touch, OnFlagTouch);
	}
}

public Action:OnHurtTouch(hurt, client)                                      // Easy way of locating nearby random valid safe spawn point
{
        if (activeround && IsValidClient(client) && frozen[client] )
	{                                                                    // If Mod disabled do nothing
                respawned[client] = true;
                TF2_RespawnPlayer(client);                                   // If active, respawn frozen players/move to spawnroom
		return Plugin_Handled;
        }
        return Plugin_Continue;
}

public Action:OnCPTouch(point, client)                                       // Control CP events and payload
{
	if (!g_bEnabled)                                                     // Mod disabled, allow caps
	{
                return Plugin_Continue;
        }
        if (!g_disableCaps && IsValidClient(client) && !frozen[client])
        {
                return Plugin_Continue;
        }                                                                    // Allow capping, but don't allow frozen players to cap
        return Plugin_Handled;
}

public Action:OnDoorTouch(door, client)                                      // Block Door Triggers
{
	if (g_openDoors == 1 && activeround && IsValidClient(client))        // If Mod disabled do nothing
	{                                                                    // If door forcing enabled, disable door triggers
                return Plugin_Handled;
 	}
        return Plugin_Continue;
}

public Action:OnTeleTouch(tele, client)                                      // Block all Teleports on Custom Maps
{
	if (activeround && IsValidClient(client))                            // If Mod disabled do nothing
        {                                                                    // If active block teleport triggers
        	return Plugin_Handled;
	}
        return Plugin_Continue;
}

public Action:OnFlagTouch(flag, client)                                      // Control Flag Events
{
	if (!g_bEnabled)                                                     // Mod disabled, allow caps
	{
                return Plugin_Continue;
        }
        if (!g_disableFlags && IsValidClient(client) && !frozen[client])     // Allow capping, but don't allow frozen players to cap
        {
                return Plugin_Continue;
        }
        return Plugin_Handled;
}

DropFlag(client)                                                             // From tf2betheghost, as with some other ontouches :)
{                                                                            // Forces client to drop the flag
	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return;
	}

	new flag = -1, iCTeam = GetClientTeam(client);
	while ((flag = FindEntityByClassname( flag, "item_teamflag")) != -1)
	{
		if (GetEntProp( flag, Prop_Send, "m_iTeamNum") == iCTeam)
			continue;
		if (GetEntProp( flag, Prop_Send, "m_nFlagStatus") != 1)
			continue;
		if (GetEntPropEnt( flag, Prop_Send, "m_hPrevOwner") != client)
			continue;
		AcceptEntityInput( flag, "ForceDrop" );
	}
}

remove_gameplay_ents()                                                       // Removes/Alters entities to make an arena style game mode
{
	new ent = -1;
	while ((ent = FindEntityByClassname2(ent, "func_respawnroomvisualizer")) != -1)       // No spawn protection
	{
		AcceptEntityInput(ent, "Kill");
	}
	ent = -1;
	while ((ent = FindEntityByClassname2(ent, "func_regenerate")) != -1)                  // No resupplying!
	{
		AcceptEntityInput(ent, "Kill");
	}
	if (g_openAPs)
	{
        	ent = -1;
		while ((ent = FindEntityByClassname2(ent, "func_areaportal")) != -1)          // Find Areaportals
		{
                	AcceptEntityInput(ent,"Open");
		}
        }
	if (g_openDoors == 1)
	{
        	ent = -1;
		while ((ent = FindEntityByClassname2(ent, "filter_activator_tfteam")) != -1)  // Cripple team specific entities, so they work for both/none
		{                                                                             // They will close in humiliation
			SetVariantInt(0);
                	AcceptEntityInput(ent,"SetTeam");
		}
        	ent = -1;
		while ((ent = FindEntityByClassname2(ent, "func_door")) != -1)                // Force Doors Open, Triggers can still close them
		{
			AcceptEntityInput(ent, "Unlock");
                        AcceptEntityInput(ent, "Open");
		}
	
	}
	else if (g_openDoors == 2)
	{
        	ent = -1;
		while ((ent = FindEntityByClassname2(ent, "func_door")) != -1)                // Delete the Doors, required for some maps - most can use this
		{
			AcceptEntityInput(ent, "Kill");
		}
        }
	ent = -1;
        while ((ent = FindEntityByClassname2(ent, "prop_dynamic")) != -1)                     // Don't need to see the cabinets
	{
		decl String:modelname[64];
                GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 64);
                if(strcmp(modelname,"models/props_gameplay/resupply_locker.mdl") == 0 ||
                   strcmp(modelname,"models/props_medieval/medieval_resupply.mdl") == 0)
                {
                	AcceptEntityInput(ent,"Kill");
                }
                else if(g_openDoors &&
                       (strcmp(modelname,"models/props_well/main_entrance_door.mdl") == 0))   // Hydro hides it rather than animates it, and it uses vphysics
                {                                                                             // If we set unsolid, players may get false positive stuck for ray trace?
                        AcceptEntityInput(ent,"Kill");
                }
                else if(g_openDoors &&                                                        // Set stupid door models to open state, if forced or deleted
                       (strcmp(modelname,"models/props_gameplay/door_slide_large_dynamic.mdl") == 0 ||
                        strcmp(modelname,"models/props_medieval/door_slide_small_dynamic.mdl") == 0))
                {
                        SetVariantString("Open");
                        AcceptEntityInput(ent,"SetAnimation");
                }                                                                             // Remove Control Point Models
                else if(g_disableCaps && strcmp(modelname,"models/props_gameplay/cap_point_base.mdl") == 0)
                {
                	AcceptEntityInput(ent,"Kill");
                }
        }
	if (g_disableCaps)
	{
        	ent = -1;
		while ((ent = FindEntityByClassname2(ent, "team_control_point")) != -1)       // Remove Control Point Hologram
		{
			if (ent > MaxClients && IsValidEdict(ent))
			{
			        SetVariantInt(1);                                             // Lock them, so idiots won't look for them
			        AcceptEntityInput(ent, "SetLocked");
                                AcceptEntityInput(ent, "HideModel");
                                SetVariantInt(600);
                                AcceptEntityInput(ent, "SetUnlockTime");
		        }
                }
                ent = -1;
	        while ((ent = FindEntityByClassname2(ent, "prop_physics")) != -1)             // Don't need to see the bomb cart
	        {
		        decl String:modelname[64];
                        GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 64);
                        if(g_disableCaps &&
                          (strcmp(modelname,"models/props_trainyard/bomb_cart.mdl") == 0 ||
                           strcmp(modelname,"models/props_trainyard/bomb_cart_red.mdl") == 0))
                        {
                	        AcceptEntityInput(ent,"Kill");
                        }
                }
	}
	if (g_disableFlags)
	{
        	ent = -1;
		while ((ent = FindEntityByClassname2(ent, "item_teamflag")) != -1)            // Remove Flags!
		{
			AcceptEntityInput(ent, "Kill");
		}
	}
	if (g_bDisableTrains)
	{
        	ent = -1;
		while ((ent = FindEntityByClassname2(ent, "func_tracktrain")) != -1)          // Remove Bomb Cart and Heal Beam, ghosts, trains
		{
			AcceptEntityInput(ent, "Kill");
		}
	}
}

remove_respawnrooms()
{
	new ent = -1;
	while ((ent = FindEntityByClassname2(ent, "func_respawnroom")) != -1)                 // No changing class and healing
	{                                                                                     // If bots are enabled, it will bitch about pathing, but it's ok.
		AcceptEntityInput(ent, "Kill");
	}
}

///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// Generic Hooks  ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
        if (g_gametimer != INVALID_HANDLE)
        {
                KillTimer(g_gametimer);
                g_gametimer = INVALID_HANDLE;                                                             // If a mp_restartround is issued, two timers can exist, this prevents it
        }
        if (g_rounds == 1)
        {
                g_mapStartTime = GetGameTime();                                                           // Store the game start timer, it resets itself after waiting for players ends
        }                                                                                                 // Possible problem if all players leave the server and rejoin. Oh well.
        if (g_bEnabled && g_rounds)                                                                          // Disable on first round (waiting for players)
        {
                activeround = 1;                                                                          // Set to active
                unfreezeAll();                                                                            // Clear Frozen array
                destroyIceBlock(0,true);                                                                  // Clear all lingering ice models
                remove_gameplay_ents();                                                                   // Force doors, remove cabinets, etc

                if (g_preRoundTime)
                {
                        SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
                        for (new i=1; i<=MaxClients; i++)
                        {
		                if (IsValidClient(i) && IsPlayerAlive(i))
		                {
                                        SetEntityMoveType(i, MOVETYPE_NONE);                              // Hard Freeze ALL for Setup
                                        SetEntProp(i, Prop_Send, "m_bGlowEnabled", 0);                    // Turn off glow if they still have it
                                        ClientCommand(i, "r_screenoverlay \"\"");                         // This should get taken care of, but don't want it staying forever in case
                                }
                        }
                        SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") | FCVAR_CHEAT);
                	CreateTimer(float(g_preRoundTime), Timer_PreRoundEnd, TIMER_FLAG_NO_MAPCHANGE);   // End the Pre-Round State, Start the Game... Derp
                }
                else                                                                                      // Pre-Round is Disabled, Skip it
                {
                	CreateTimer(0.1, Timer_PreRoundEnd, TIMER_FLAG_NO_MAPCHANGE);                     // End the Pre-Round State, Start the Game... Derp
                }
                StopGameTimer();                                                                          // Destroy the game timer, we don't need to see it in the hud, we have our own.
        }
        g_rounds++;
	return Plugin_Continue;
}

StopGameTimer()
{
	new entityTimer = FindEntityByClassname(-1, "team_round_timer");                                  // Removes timelimit from round/map
	if (entityTimer > -1)
	{
		AcceptEntityInput(entityTimer, "Kill");
	}
}

public Action:Timer_PreRoundEnd(Handle:timer)                                                             // Used to start the active round after warmup has finished
{
        for (new i=1; i<=MaxClients; i++)
        {
                if (IsValidClient(i) && IsPlayerAlive(i))
                {
                        SetEntityMoveType(i, MOVETYPE_WALK);                                              // Restore Movement for ALL
                }
        }
        remove_respawnrooms();                                                                            // Prevent Class Change
        activeround = 2;                                                                                  // Active Round, Game Has Begun
                        
        for (new i=1; i<=MaxClients; i++)
        {
        	if (IsValidClient(i) && IsPlayerAlive(i))                                  // If they are dead, the problem should resolve itself
		{
			playerclass[i] = TF2_GetPlayerClass(i);                           // Store everypony's active, non-queud player class
		}
        }

        g_roundTimeleft = g_timeLeft;                                                                     // Reset the round clock
        g_gametimer = CreateTimer(1.0, Timer_TeamFreezeCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);   // Check every 1 second to see if everyone is frozen/tick the hud
	return Plugin_Continue;
}

public post_inventory_application(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (g_bEnabled && IsValidClient(client) && IsPlayerAlive(client))                                 // Enabled here, activeround comes later
	{
                if (unassigned[client])                                                                   // Late joiners and spectators/afks, initialize variables, freeze them
                {
                        frozen[client] = false;                                                           // Set them unfrozen, so they can suicide
                        unassigned[client] = false;
                        stuck[client] = 0;
                        respawned[client] = false;
                	if (activeround == 2)
                	{
        	                if (IsValidClient(client) && IsPlayerAlive(client))                       // If they are dead, the problem should resolve itself
		                {
			                playerclass[client] = TF2_GetPlayerClass(client);                 // Store their class, doesn't matter when we do this for these late kids
		                }
                                FakeClientCommand(client,"kill");                                         // Slay them in the active round


                                if (g_feedback)
                                {
                                        PrintToChat(client,"\x04[Freeze]:\x01 %t","feedback_joinpenalty");
         	                }
                        }
                }
                if (respawned[client])                                                                    // They got moved back to spawn by trigger or stuck command and are still frozen
                {
                        giveDummyWeapons(client);                                                         // respawnplayer sent them here, so strip them down
                        respawned[client] = false;
                        if(IsFakeClient(client))                                                          // #&@# bots
                        {
                                SetEntityMoveType(client, MOVETYPE_NONE);
                        }
                }
                if (!frozen[client])
                {
                	if (activeround == 1)                                                             // Class swap in the pre-round
                	{
		                SetEntityMoveType(client, MOVETYPE_NONE);                                 // Hard Freeze for Setup, if they switched classes
                 	}

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
                 	else if(TF2_GetPlayerClass(client) == TFClass_Medic)                             // Deal with mediguns
                 	{
                         	new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		         	new medigunidx = (weapon > MaxClients && IsValidEdict(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
      	 		 	if (medigunidx != 411 && medigunidx != 998)                              // If it's not a quick fix or vaccinator, replace it with gimp kritz
                	 	{
                	         	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
                		 	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
                		 	if (hWeapon != INVALID_HANDLE)
                	         	{
                	        	 	TF2Items_SetClassname(hWeapon, "tf_weapon_medigun");
               		        	 	TF2Items_SetItemIndex(hWeapon, 29);
        	                	 	TF2Items_SetLevel(hWeapon, 100);
               		        	 	TF2Items_SetQuality(hWeapon, 5);

                                         	TF2Items_SetNumAttributes(hWeapon, 3);
        		        	 	TF2Items_SetAttribute(hWeapon, 0, 18, 1.0);
        		        	 	TF2Items_SetAttribute(hWeapon, 1, 292, 2.0);
        		        	 	TF2Items_SetAttribute(hWeapon, 2, 293, 1.0);

					 	weapon = TF2Items_GiveNamedItem(client, hWeapon);
                		         	CloseHandle(hWeapon);

                		         	if (IsValidEntity(weapon))
                		         	{
                                                 	EquipPlayerWeapon(client, weapon);
                                         	}
                	         	}
			 	}
                                if (chargemeter[client] != 0.0)                                          // Fix their medigun charge, if they got respawned from being stuck inside something
	                        {
	                                new medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	                                if (IsValidEntity(medigun))
	                                {
	                                        decl String:s[64];
                                 	        GetEdictClassname(medigun, s, sizeof(s));
	                                        if (!strcmp(s,"tf_weapon_medigun"))
	                                        {
                                                        SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel",chargemeter[client]);
	                                                chargemeter[client] = 0.0;
	                                        }
	                                }
	                        }
                 	}
	 	}
 	}
}
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////// Damage Hooks ////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
        if ((attacker > MaxClients || attacker < 1) && IsValidClient(client) && IsPlayerAlive(client) && frozen[client])
        {                                                                                      // Prevent Drowining, hurts, and other world damage to frozen players
        	damage = 0.0;
                return Plugin_Handled;
        }

        if (!IsValidClient(client) || !IsPlayerAlive(client) || !IsValidClient(attacker) || !IsPlayerAlive(attacker))
        {
                return Plugin_Continue;
        }

        if (frozen[client])                                                                    // We are only interested in corpsicles here
	{
        	if(IsFakeClient(client))                                                       // Bots can't move, just block damage and be done
        	{
                       damage = 0.0;

                       return Plugin_Changed;
                }

                new Float:newdamage = damage*g_forceMulti;
        	
                if(newdamage == 0.0)                                                           // If there's no force, don't bother
        	{
        		return Plugin_Continue;
                }
                
                decl Float:clientposition[3], Float:targetposition[3], Float:vector[3];
                decl Float:dist;

                GetClientAbsOrigin(attacker, clientposition);
                GetClientAbsOrigin(client, targetposition);
                dist = GetVectorDistance(clientposition, targetposition);

                if (dist < 550)                                                                // 550 is a good max range for push falloff, linear functions intercept around here
                {
		        MakeVectorFromPoints(clientposition, targetposition, vector);
		        NormalizeVector(vector, vector);

                        if (newdamage > g_forceCap)
                        {
                	        newdamage = g_forceCap;
                        }

			decl String:sWeapon[24];
			if (IsValidEdict(inflictor) && GetEdictClassname(inflictor, sWeapon, 24) && StrEqual(sWeapon, "tf_weapon_flamethrower"))
                        {                                                                       // If inflictor is valid ent, and it's set, and it's a flamethrower (wish I could use damagetype)
                                newdamage *= 5.0;                                               // Fire does only 6 damage per particle, just increase it by 5x
                                ScaleVector(vector, newdamage);
                                vector[2] =  (-0.171*dist)+308;                                 // f(x) = -.171x+308 [400,240][50,300] linear function, 50 is point blank, 400 is max flamethrower
                        }                                                                       // x = distance from target, y = height target is lifted up
                        else
                        {
                                ScaleVector(vector, newdamage);
                                vector[2] =  (-0.175*dist)+350;                                 // f(x) = -.175x+350 [2000,0][550,253.7][0,350] linear function, provides moderate knockbacks
                                if ( dist < 80 && (GetClientButtons(attacker) & IN_DUCK))       // If a player is within melee range and crouching, this will kock the target to the side, or back at them
                                {                                                               // Useful for knocking people out of corners, or back over the client's head to prevent knocking off cliffs
                                        vector[0] = -vector[0];
                                        vector[1] = -vector[1];
                                }
                        }

                        SetEntProp(client, Prop_Send, "m_bJumping", 1);                         // Force jump so they fly around
                        TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vector);
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

        if (TF2_IsPlayerInCondition(client, TFCond_DefenseBuffMmmph))                          // Handles the case in which anyone attacks a buffed phlog user
        {
                damage *= 2;

		return Plugin_Changed;
	}

	return Plugin_Continue;
	
}

public TF2_OnConditionAdded(client, TFCond:condition)                            // Damage over time/Stun conditions will cause them to move
{
       if (!frozen[client])
       {
              return;
       }
       else if (condition == TFCond_Bleeding)                                    // Boston Basher, Southern Hospitality, Cleaver...
       {
              TF2_RemoveCondition(client,TFCond_Bleeding);
              SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 1.0);
       }
       else if (condition == TFCond_SpeedBuffAlly)                               // Disciplinary Action
       {
              TF2_RemoveCondition(client,TFCond_SpeedBuffAlly);
              SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 1.0);
       }
       else if (condition == TFCond_Dazed)                                       // Scout Stun Ball
       {
              TF2_RemoveCondition(client,TFCond_Dazed);
              SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 1.0);
       }
       else if (condition == TFCond_OnFire)                                      // Sometimes it ticks the same time as freeze
       {
              TF2_RemoveCondition(client,TFCond_OnFire);
              SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 1.0);
       }
}


///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// Death + Connect //////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)                // Don't intercept deadringers
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

        if (activeround == 2 && IsValidClient(client))                                  // Freeze if Active Round
        {
                GetClientAbsOrigin(client, deathVec[client]);                           // Store the location they died at
                GetClientEyeAngles(client, deathAng[client]);                           // Store where they were looking
                GetEntPropVector(client, Prop_Data, "m_vecVelocity", deathVel[client]); // Store their Velocity
		if (GetEntProp(client, Prop_Send, "m_bDucked"))                         // Store if they were ducking or not
		{
                        deathDuck[client] = true;
		}
		else
		{
                        deathDuck[client] = false;
                }

                CreateTimer(0.01,Timer_RemoveRagdoll,GetEventInt(event, "userid"));     // Delete their ragdoll

                if (playerclass[client])                                                // Really they should have one, but for some reason they don't, the game would get totally borked
                {
                        TF2_SetPlayerClass(client, playerclass[client], false, true);   // Set them to their round-start class, resolve the queue class respawn bug
                }
                CreateTimer(0.0, Timer_FreezeClientInPlace, client);                    // Respawn and Freeze Player, have to delay this a bit or they don't come back? Why?
        }
        else if (activeround == 1 && IsValidClient(client))                             // Respawn if Pre Round
        {
                CreateTimer(0.01,Timer_RemoveRagdoll,GetEventInt(event, "userid"));     // Ragdolls look sloppy with team scrambles
                
                TF2_RespawnPlayer(client);
        }
        return Plugin_Continue;
}

public Action:Timer_FreezeClientInPlace(Handle:timer, any:client)                       // Respawns a player at their death vector
{
        if (activeround && IsValidClient(client))                                       // Prevent them from respawning near the end of round
        {
                if (deathDuck[client])                                                  // If they died crouching, set them ducking or they will get stuck
	        {
                        decl Float:collisionvec[3] = {24.0,24.0,62.0};                  // From some old ff2/vsh subplugin, I forget which (otaku?)
	                SetEntPropVector(client, Prop_Send, "m_vecMaxs", collisionvec);
	                SetEntProp(client, Prop_Send, "m_bDucked", 1);
	                SetEntityFlags(client, FL_DUCKING);
	        }
                TF2_RespawnPlayer(client);                                              // somewhat seamless transition from death into cube
                if (IsFakeClient(client))
                {
                      TeleportEntity(client, deathVec[client], deathAng[client], NULL_VECTOR);    // Bots will pop out of the cube if they have velocity
                }
                else
                {
                      TeleportEntity(client, deathVec[client], deathAng[client], deathVel[client]);
                }
                freezeClient(client);                                                   // Freeze Player, check proximity, draw rings, etc
                resolveFreezeSpawnOverlaps(client);                                     // Check to see if any nearby players became stuck in them, and push them away
        }
}

public Action:Timer_RemoveRagdoll(Handle:timer, any:userid)                             // From ff2, I think :S
{
	new client = GetClientOfUserId(userid);
	decl ragdoll;
	if (client>0 && (ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll"))>MaxClients)
	{
		AcceptEntityInput(ragdoll, "Kill");
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
        unassigned[client] = true;
}

public OnClientPostAdminCheck(client)
{
	if (g_bEnabled && g_feedback)
	{
                CreateTimer(45.0, Timer_WelcomeMessage, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnClientDisconnect(client)                                                       // Kill their ice model, if they have one
{
	if (activeround)
	{
		destroyIceBlock(client);
	}
}

public Action:Timer_WelcomeMessage(Handle:timer, any:client) {
	if (IsValidClient(client))
	{
		PrintToChat(client,"\x04[Freeze]:\x01 Welcome to Freeze Tag \x04%s\x01 by %s. %t",g_version,PLUGIN_AUTHOR,"feedback_welcomemsg");
	}
}

///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////// HUD /Win Funcs //////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

public Action:Timer_TeamFreezeCheck(Handle:timer)                    // The basis of this timer was borrowed from freak fortress 2 :D
{
        if (!activeround)
	{
                g_gametimer = INVALID_HANDLE;
                return Plugin_Stop;                                  // Failsafe if something bad happened and duplicate timers occur
        }

        new red;
        new redfrozen;
        new blue;
        new bluefrozen;

        for (new i=1; i<=MaxClients; i++)
	{
		if (IsValidClient(i))                                // Checking if they are alive will throw it off as people die for short periods of time
		{                                                    // Generally, nobody on a team should ever be "dead", and it should never happen.
                	new team = GetClientTeam(i);
                        if (team == RED)
                	{
                		if(frozen[i])
                                {
                                        redfrozen++;
                                }
                                else
                                {
                                        red++;
                                }
                	}
                	else if (team == BLU)
                	{
                		if(frozen[i])
                                {
                                        bluefrozen++;
                                }
                                else
                                {
                                        blue++;
                                }
                	}
                	else if (team == SPEC)                       // could probably just make this else.. it happens a lot too.
                	{
                                unassigned[i] = true;                // They are in spectator, set them unassigned so they can join the game (AFK managers do this, annoying)
                        }
		}
	}

        new Float:redratio = (float(redfrozen)/(float(red)+float(redfrozen)));                         // Ratio of Frozen/Unfrozen Players
        new Float:blueratio = (float(bluefrozen)/(float(blue)+float(bluefrozen)));                     // Smaller is more good.

	new time = g_roundTimeleft;
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

        decl String:s2[46];

	Format(s2,46,"RED %t: %i/%i\nBLU %t: %i/%i\n%s","hud_frozen",redfrozen,red+redfrozen,"hud_frozen",bluefrozen,blue+bluefrozen,s1);

        SetHudTextParams(HUDX1, HUDY1, 1.1, 255, 255, 255, 255);

        for (new i=1; i<=MaxClients; i++)                                                               // Print out HUD
	{
		if (IsValidClient(i) && !IsFakeClient(i))
		{
			ShowSyncHudText(i,timeleftHUD,s2);
		}
	}

	/////////////////////////////////////////// END GAME ON TIMER ///////////////////////////////////////////////////////

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
                if (redratio == blueratio)
                {
                        ForceTeamWin(STALEMATE);
                        if(g_feedback)
                        {
                                PrintToChatAll("\x04[Freeze]:\x01 %t [\x076E89D4%i/%i\x01 %t \x07F07560%i/%i\x01 %t]","winreason_tie",bluefrozen,blue+bluefrozen,"wincompare_frozen",redfrozen,red+redfrozen,"win_frozen");
                        }
                }
                else if(redratio > blueratio)
                {
                        ForceTeamWin(BLU);                                // BLU wins
                        if(g_feedback)
                        {
                                PrintToChatAll("\x04[Freeze]:\x01 %t \x076E89D4%t\x01 [\x076E89D4%i/%i\x01 %t \x07F07560%i/%i\x01 %t]","winreason_time","victory_blu",bluefrozen,blue+bluefrozen,"wincompare_frozen",redfrozen,red+redfrozen,"win_frozen");
                        }
                }
                else
                {
                        ForceTeamWin(RED);                                // RED wins
                        if(g_feedback)
                        {
                                PrintToChatAll("\x04[Freeze]:\x01 %t \x07F07560%t\x01 [\x07F07560%i/%i\x01 %t \x076E89D4%i/%i\x01 %t]","winreason_time","victory_red",redfrozen,red+redfrozen,"wincompare_frozen",bluefrozen,blue+bluefrozen,"win_frozen");
                        }
                }
		g_gametimer = INVALID_HANDLE;
                return Plugin_Stop;
	}
        else if (time < 10)
        {
                
                if (redratio > blueratio)
                {
                        for (new i=1; i<=MaxClients; i++)
                        {
		                if (IsValidClient(i) && IsPlayerAlive(i))                                   // Outline Everypony Who's Not Frozen
		                {
                                        if (GetClientTeam(i) == RED)
                                        {
                                                if (!frozen[i])
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
                                if (IsValidClient(i) && IsPlayerAlive(i))                                    // Outline Everypony Who's Not Frozen
		                {
                                        if (GetClientTeam(i) == BLU)
                                        {
                                                if (!frozen[i])
                                                {
                                                        if (TF2_GetPlayerClass(i) == TFClass_Spy)            // Red is winning, highlight blues
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

	/////////////////////////////////////////// END GAME ON ELIMINATION ///////////////////////////////////////////////////////
	
	if ((red+redfrozen == 0 && bluefrozen == 0) || (blue+bluefrozen == 0 && redfrozen == 0))            // Waiting for players to join a team, prevents 1v0 endgame victory loop.
        {
                return Plugin_Continue;                           // Do nothing
        }
        if (red == 0 && blue == 0)                                // Stalemate
        {
                ForceTeamWin(STALEMATE);                                                                    // should probably add in different feedback variable for this.
                if (g_feedback)
                {
                        PrintToChatAll("\x04[Freeze]:\x01 %t [\x076E89D4%i/%i\x01 %t \x07F07560%i/%i\x01 %t]","winreason_stalemate",bluefrozen,blue+bluefrozen,"wincompare_frozen",redfrozen,red+redfrozen,"win_frozen");
                }
		g_gametimer = INVALID_HANDLE;
                return Plugin_Stop;
        }
	if (red == 0)                                             // Red is ded baby
        {
                ForceTeamWin(BLU);
                if (g_feedback)
                {
                        PrintToChatAll("\x04[Freeze]:\x01 %t \x076E89D4Blue wins!\x01  [\x076E89D4%i/%i\x01 %t \x07F07560%i/%i\x01 %t]","winreason_elimination",bluefrozen,blue+bluefrozen,"wincompare_frozen",redfrozen,red+redfrozen,"win_frozen");
                }
		g_gametimer = INVALID_HANDLE;
                return Plugin_Stop;
	}
	if (blue == 0)                                            // Blue lost
        {
                ForceTeamWin(RED);
                if (g_feedback)
                {
                        PrintToChatAll("\x04[Freeze]:\x01 %t \x07F07560Red wins!\x01 [\x07F07560%i/%i\x01 %t \x076E89D4%i/%i\x01 %t]","winreason_elimination",redfrozen,red+redfrozen,"wincompare_frozen",bluefrozen,blue+bluefrozen,"win_frozen");
                }
		g_gametimer = INVALID_HANDLE;
                return Plugin_Stop;
	}

	return Plugin_Continue;
}

ForceTeamWin(team)                                                               // Borrowed from freak fortress 2
{
	CreateTimer(0.1, Timer_UnfreezeAllClients, TIMER_FLAG_NO_MAPCHANGE);     // Unfreezes people who died at round end, and need a second to respawn
	CreateTimer(1.0, Timer_UnfreezeAllClients, TIMER_FLAG_NO_MAPCHANGE);     // Unfreezes people who died at round end, and need a second to respawn
	CreateTimer(3.0, Timer_UnfreezeAllClients, TIMER_FLAG_NO_MAPCHANGE);     // Unfreezes people who died at round end, and need a second to respawn

        activeround = 0;                                                         // That's it Man, Game Over Man, It's Game Over

	new ent = FindEntityByClassname2(-1, "team_control_point_master");
	if (ent == -1)
	{
		ent = CreateEntityByName("team_control_point_master");
		DispatchSpawn(ent);
		AcceptEntityInput(ent, "Enable");
	}
	SetVariantInt(team);
	AcceptEntityInput(ent, "SetWinner");

	if (team == RED)                                                         // Set the scoreboard, since game win won't always do it
	{
                g_redscore++;
        }
        if (team == BLU)
        {
                g_bluscore++;
        }
        SetTeamScore(RED, g_redscore);                                           // We will set our own scores, since payload and shit fouls it up
        SetTeamScore(BLU, g_bluscore);

        if (g_mapTime && (GetGameTime() > (g_mapStartTime+g_mapTime)))           // If mp_timelimit is not set to 0
        {                                                                        // End the game if timelimit is over, happens on payloads and such
                LogMessage("[TF2] Freeze Tag: Forcing Map Change Due to Timelimit: %i",g_mapTime);
                CreateTimer(2.0, Timer_ForceGameEnd, TIMER_FLAG_NO_MAPCHANGE);   // Elapsed time is greater than map time, end this
        }
        else if (g_maxRounds && (g_rounds > g_maxRounds))                        // If round limit is not set to 0
        {                                                                        // End the game because user requested it
                LogMessage("[TF2] Freeze Tag: Forcing Map Change Due to Round Limit: %i",g_maxRounds);
                CreateTimer(2.0, Timer_ForceGameEnd, TIMER_FLAG_NO_MAPCHANGE);   // Max rounds played has occured
        }
}

public Action:Timer_ForceGameEnd(Handle:timer)                                   // Borrwed from time limit enforcer
{
	new ent  = FindEntityByClassname(-1, "game_end");                        // Find game end, or create a new one
	if (ent == -1 && (ent = CreateEntityByName("game_end")) == -1)
	{
		LogError("Unable to locate and create \"game_end\"!");
	}
	else
	{
                AcceptEntityInput(ent, "EndGame");                               // Game over man
	}
}

public Action:Timer_UnfreezeAllClients(Handle:timer)                             // Handles delayed unfreezing, and ends the round.
{
        for (new i=1; i<=MaxClients; i++)                                        // Re-attempt to unfreeze late frozen players
        {
                if (frozen[i] && IsValidClient(i) && IsPlayerAlive(i))
                {
                        unfreezeClient(i,i);
                }
        }
}

///////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////// Freeze /////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

freezeClient(client)
{
        prepareFreeze(client);                                                                  // Handle Weapons, Sentry Targetting, Movement
        createIceBlock(client);                                                                 // Spawn model, track model, etc.
        purgeProximity(client);                                                                 // Clear the proximity tracker
        unfreezer[client] = 0;                                                                  // Clear the freezing client
        CreateTimer(1.0, Timer_FreezeBeacon, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);     // Beacon To Test Nearby Players
        
        SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
        ClientCommand(client, "r_screenoverlay \"Effects/CombineShield/comshieldwall\"");       // HL2 overlay for frozen peepz
        SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") | FCVAR_CHEAT);

        frozen[client] = true;
}

prepareFreeze(client)                                                         // Needed for re-application if player is respawned
{
        if (g_disableFlags)
        {
                DropFlag(client);                                             // Drop the flag if flagging is enabled, ignore if disabled entierly
        }
        TF2_RemovePlayerDisguise(client);                                     // Just in case, remove disguise

        new iFlags = GetEntityFlags(client);
        SetEntityFlags(client, iFlags | FL_NOTARGET);                         // Sentry Target Off

        if (IsFakeClient(client))                                             // Bots ignore the speed restrictions
        {
                SetEntityMoveType(client, MOVETYPE_NONE);                     // Stop them from moving while respawning, to prevent them from moving @ respawn, tf2 does this
        }
        SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 1.0);
        if (!IsFakeClient(client))                                            // #@&# bots, they'll be stuck but it's the only way since they don't obey movement nerfs
        {
                new Handle:pack;
                CreateDataTimer(0.2, Timer_StopYouHaveViolatedTheLaw, pack, TIMER_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);   // Deal with the respawn freedom of movement resets
                WritePackCell(pack, client);
                WritePackCell(pack, 7);
        }

	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "tf_wearable")) != -1)
	{
		if (IsValidEntity(ent))
		{
			if (GetEntDataEnt2(ent, FindSendPropOffs("CTFWearable", "m_hOwnerEntity")) == client)
			{
                		SetEntityRenderMode(ent, RENDER_NORMAL);      // Prevent wearables from interfering with transparency, not needed since spies can't turn invis when frozen
			}                                                     // We could delete them, but what is tf2 worth without it's hats?
		}
	}

        giveDummyWeapons(client);                                             // Give them nerf bats... er fists
}

createIceBlock(client)
{
        if (IsValidEntity(iceblock[client]))                                  // Kill the old one if it somehow exists (admin slay frozen player or somesuch nonsense)
	{
		AcceptEntityInput(iceblock[client],"kill");
	}
	new ice1 = CreateEntityByName("prop_dynamic");
	if ( ice1 != -1 )
	{
		decl Float:pos[3];
		decl Float:angle[3];

		GetClientAbsOrigin(client, pos);
		GetClientAbsAngles(client, angle);                            // Spawn the ice block with the player's angle, so they won't all look the same
                angle[0] = GetRandomFloat(-5.0,5.0);                          // Purge eye position data, generate random variance
                angle[2] = GetRandomFloat(-5.0,5.0);

		DispatchKeyValue(ice1, "model", MODEL_ICEBLOCK);
		DispatchKeyValue(ice1, "solid", "0");
		if(GetClientTeam(client) == BLU)
		{
			DispatchKeyValue(ice1, "skin", "1");

		}
		DispatchSpawn(ice1);
		SetVariantString("idle");
		AcceptEntityInput(ice1, "SetAnimation", -1, -1, 0);
                TeleportEntity(ice1, pos, angle, NULL_VECTOR);                // Move it to the client
		AcceptEntityInput(ice1, "TurnOn");

                iceblock[client] = ice1;                                      // Preserve, for later
                CreateTimer(0.1, Timer_MoveIce, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);        // this timer is too frequent, but it looks horrible if it's lower
                EmitAmbientSound(SOUND_FREEZE, pos, client, SNDLEVEL_NORMAL );// Emit Sound When Block is Formed.
	}
}

public Action:Timer_MoveIce(Handle:timer, any:client)                         // Moves the ice, becase valve hates models parented to players.. also the .1 timer is realy rapey
{                                                                             // Perhaps a better method would be some trick to parent the item to another item or model on the player
        if (!frozen[client] ||                                                // It appears that t2 has disabled parenting of models to players
           (iceblock[client] == -1) ||
            !IsValidClient(client) ||
            !IsPlayerAlive(client) )
	{
                return Plugin_Stop;
        }
	decl Float:pos[3];

	GetClientAbsOrigin(client, pos);
        TeleportEntity(iceblock[client], pos, NULL_VECTOR, NULL_VECTOR);      // Move it to the client, ignore the angle, it'll look stupid turning
        
        return Plugin_Continue;
}

destroyIceBlock(client, bool:all=false)                                       // Destroys a single client's ice block, or all just pass a dummy variable.
{
	if (all)
	{
                for (new i=1; i<=MaxClients; i++)
                {
                        if (IsValidEntity(iceblock[i]))
	                {
		                AcceptEntityInput(iceblock[i],"kill");
		                iceblock[i] = -1;
	                }
                }
        }
        else
        {
                if (IsValidEntity(iceblock[client]))
	        {
		        AcceptEntityInput(iceblock[client],"kill");
		        iceblock[client] = -1;
	        }
        }
}

public Action:Timer_StopYouHaveViolatedTheLaw(Handle:timer, Handle:pack)      // Stop them from moving when they come back alive, inventory app allows movement for some few seconds
{                                                                             // If respawn worked faster and didn't #&@@ with movement speeds, we would not need this.
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new iterations = ReadPackCell (pack);

        if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
                return Plugin_Stop;
        }
        if (!frozen[client])                                                   // If they got unfrozen by command, or really quickly, kill the timer
        {
                if (IsFakeClient(client))
                {
                        SetEntityMoveType(client, MOVETYPE_WALK);              // Fix Bots
                }
                ResetPlayerSpeed(client);
                return Plugin_Stop;
        }
        if (iterations)
        {
                if (IsFakeClient(client))                                      // Bots ignore the speed restrictions
                {
                        SetEntityMoveType(client, MOVETYPE_NONE);              // Stop them from moving while respawning, to prevent them from moving @ respawn, tf2 does this
                }
                SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 1.0);
                new Handle:pack2;
                CreateDataTimer(0.2, Timer_StopYouHaveViolatedTheLaw, pack2, TIMER_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
                WritePackCell(pack2, client);
                WritePackCell(pack2, iterations-1);
        }
        else
        {
                if(g_feedback)
                {
		        PrintToChat(client, "\x04[Freeze]:\x01 %t","feedback_frozen");
                }
        }

        return Plugin_Continue;
}

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
                TF2Items_SetNumAttributes(hWeapon, 4);

                new weapon = TF2Items_GiveNamedItem(client, hWeapon);
                CloseHandle(hWeapon);

                if (IsValidEntity(weapon))
                {
                	EquipPlayerWeapon(client, weapon);
                }
	}
}

unfreezeClient(client, other)
{
        frozen[client] = false;                                              // Set this now, so they get proper weapons on inventory application hook

        decl Float:pos[3];
        GetClientAbsOrigin(client, pos);

        TF2_RemoveCondition(client, TFCond_InHealRadius);                    // Kill Lingering Particles
        destroyIceBlock(client);                                             // Remove ice model

        if (IsFakeClient(client))                                            // Un#&@# bots
        {
                SetEntityMoveType(client, MOVETYPE_WALK);
        }
        ResetPlayerSpeed(client);                                            // Restore Movement

        new iFlags = GetEntityFlags(client);
        SetEntityFlags(client, iFlags &~ FL_NOTARGET);                       // Sentry Target On

        TF2_RegeneratePlayer(client);                                        // Recover, restore weapons
        ResetPlayerHealth(client);                                           // Restore them with % max health by base class

/*
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "tf_wearable")) != -1)
	{
		if (IsValidEntity(ent))
		{
			if (GetEntDataEnt2(ent, FindSendPropOffs("CTFWearable", "m_hOwnerEntity")) == client)
			{
                		SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
			}
		}
	}
*/

        if (IsEntityStuck(client))                                           // Are they stuck in an entity that isn't a teammate?
        {
                decl Float:targetposition[3];
		GetClientAbsOrigin(other, targetposition);                   // Move them to their unfreezer's location, who shouldn't be stuck

		new Float:collisionvec[3] = { 24.0, 24.0, 62.0 };            // If the other person is being a troll and ducking somewhere when reviving them, fix

		SetEntPropVector(client, Prop_Send, "m_vecMaxs", collisionvec);
		SetEntProp(client, Prop_Send, "m_bDucked", 1);
		SetEntityFlags(client, FL_DUCKING);

                TeleportEntity(client, targetposition, NULL_VECTOR, NULL_VECTOR);
        }

        CreateTimer(0.5, Timer_CivilianCheck, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                                                                             // If they were spawned in an entity, they won't get weapons, keep trying until they get them
	decl String:soundfile[39];                                           // Play shatter sound
	Format(soundfile,39,"physics/glass/glass_impact_bullet%i.wav",GetRandomInt(1,3));
	EmitAmbientSound(soundfile, pos, client, SNDLEVEL_NORMAL );          // Emit Sound When Block is Destroyed.
        EmitSoundToClient(client,SOUND_REVIVE,_,SNDCHAN_VOICE,SNDLEVEL_NORMAL,_,1.0,_,_,_,_,_,_);

        SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
        ClientCommand(client, "r_screenoverlay \"\"");
        SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") | FCVAR_CHEAT);

	if (g_feedback)
	{
		PrintToChat(client, "\x04[Freeze]:\x01 %t","feedback_unfrozen");
	}
}

public Action:Timer_CivilianCheck(Handle:timer, any:client)                   // Tests to see if a client has no weapons, and fixes
{
       if ( frozen[client] ||
           !IsValidClient(client) ||
	   !IsPlayerAlive(client))
       {
              return Plugin_Stop;
       }

       new melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
       if (melee == -1)
       {
              TF2_RemoveCondition(client, TFCond_Taunting);             // If they are taunting, stop it or they will go civilian, also - highfive is dumb
              TF2_RegeneratePlayer(client);                             // Recover, restore weapons, will heal them, repeatedly, sucks.
              ResetPlayerHealth(client);                                // Restore them with % max health by base class
              TF2_SwitchtoIdealSlot(client);                            // Switch to Primary if possible, otherwise do melee
       
              return Plugin_Continue;
       }

       return Plugin_Stop;
}

TF2_SwitchtoIdealSlot(client)                                 // Forces a client to switch to primary weapon/secondary weapon if they have it
{
	decl String:classname[64];
	new primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	new melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if (primary > MaxClients && IsValidEdict(primary) && GetEdictClassname(primary, classname, sizeof(classname)))
	{
		FakeClientCommandEx(client, "use %s", classname);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", primary);
	}
	else if (melee > MaxClients && IsValidEdict(melee) && GetEdictClassname(melee, classname, sizeof(classname)))
	{
		FakeClientCommandEx(client, "use %s", classname);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", melee);
	}
}

bool:IsEntityStuck(ent)                                       // Tests if player is stuck in a non-teammate
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
        else if (IsValidEdict(entity))
        {
                decl String:ObjClassName[13];
                GetEdictClassname(entity, ObjClassName, sizeof(ObjClassName));

                if (StrEqual(ObjClassName, "tf_ammo_pack"))
                {
                        return false;                        // They're probably in their own dropped weapon, ignore
                }
        }

	return true;                                         // The client may become stuck in world geometry props, or buildables, do it
}

resolveFreezeSpawnOverlaps(client)                           // Tests if unfrozen player is stuck in frozen players and tries to move them to a safe place in line of sight
{                                                            // This is horribly sloppy, ugly function, and should be put out of its misery.
	new clientteam = GetClientTeam(client);              // Most of the time it will resolve quickly, unless they are on some rubble/weapon pile, then it will elevate them, else > respawn
        decl Float:enemyvec[3],Float:vec[3],Float:clientpos[3];
        GetClientAbsOrigin(client, clientpos);

        for (new i=1; i<=MaxClients; i++)
        {
                if (!frozen[i] && IsValidClient(i) && IsPlayerAlive(i) && (clientteam != GetClientTeam(i)) )                 // iterate over nonfrozen clients on opposite team
		{
                        GetClientAbsOrigin(i, enemyvec);
                        if (GetVectorDistance(clientpos,enemyvec) < STUCKDISTANCE)
                        {
                                vec[0] = enemyvec[0];
                                vec[1] = enemyvec[1];                                                                        // Grab their original stuck coordinates.
                                vec[2] = enemyvec[2];
                                new rotation;
                                if (IsStuckinCorpsickle(i))                                                                  // They're stuck, find a spot for them
        		        {                                                                                            // Assume cardinal+ordinal has free space nearby
                                        if (rotation == 0)        //right
                                        {
                                                enemyvec[0]+=PLAYERXY; // [80][0]
                                                TeleportEntity(i, enemyvec, NULL_VECTOR, NULL_VECTOR);
                                                TR_TraceRayFilter(vec, enemyvec,  MASK_PLAYERSOLID|MASK_VISIBLE, RayType_EndPoint, TraceFilterNotWorld, i);
                                                if (TR_DidHit() || IsStuckinCorpsickle(i))                                   // If they are still stuck, or trace hit a wall, try again
                                                {
                                                        rotation++;
                                                }
                                        }
                                        if (rotation == 1)   //right bottm
                                        {
                                                enemyvec[1]-=PLAYERXY; // [80][-80]
                                                TeleportEntity(i, enemyvec, NULL_VECTOR, NULL_VECTOR);
                                                TR_TraceRayFilter(vec, enemyvec,  MASK_PLAYERSOLID|MASK_VISIBLE, RayType_EndPoint, TraceFilterNotWorld, i);
                                                if (TR_DidHit() || IsStuckinCorpsickle(i))
                                                {
                                                        rotation++;
                                                }
                                        }
                                        if (rotation == 2)   //down
                                        {
                                                enemyvec[0]-=PLAYERXY; // [0][-80]
                                                TeleportEntity(i, enemyvec, NULL_VECTOR, NULL_VECTOR);
                                                TR_TraceRayFilter(vec, enemyvec,  MASK_PLAYERSOLID|MASK_VISIBLE, RayType_EndPoint, TraceFilterNotWorld, i);
                                                if (TR_DidHit() || IsStuckinCorpsickle(i))
                                                {
                                                        rotation++;
                                                }
                                        }
                                        if (rotation == 3)   //left bottm
                                        {
                                                enemyvec[0]-=PLAYERXY; // [-80][-80]
                                                TeleportEntity(i, enemyvec, NULL_VECTOR, NULL_VECTOR);
                                                TR_TraceRayFilter(vec, enemyvec,  MASK_PLAYERSOLID|MASK_VISIBLE, RayType_EndPoint, TraceFilterNotWorld, i);
                                                if (TR_DidHit() || IsStuckinCorpsickle(i))
                                                {
                                                        rotation++;
                                                }
                                        }
                		        if (rotation == 4)   //left
                                        {
                                                enemyvec[1]+=PLAYERXY; // [-80][0]
                                                TeleportEntity(i, enemyvec, NULL_VECTOR, NULL_VECTOR);
                                                TR_TraceRayFilter(vec, enemyvec,  MASK_PLAYERSOLID|MASK_VISIBLE, RayType_EndPoint, TraceFilterNotWorld, i);
                                                if (TR_DidHit() || IsStuckinCorpsickle(i))
                                                {
                                                        rotation++;
                                                }
                                        }
                		        if (rotation == 5)   //left top
                                        {
                                                enemyvec[1]+=PLAYERXY; // [-80][80]
                                                TeleportEntity(i, enemyvec, NULL_VECTOR, NULL_VECTOR);
                                                TR_TraceRayFilter(vec, enemyvec,  MASK_PLAYERSOLID|MASK_VISIBLE, RayType_EndPoint, TraceFilterNotWorld, i);
                                                if (TR_DidHit() || IsStuckinCorpsickle(i))
                                                {
                                                        rotation++;
                                                }
                                        }
                		        if (rotation == 6)   //top
                                        {
                                                enemyvec[0]+=PLAYERXY; // [0][80]
                                                TeleportEntity(i, enemyvec, NULL_VECTOR, NULL_VECTOR);
                                                TR_TraceRayFilter(vec, enemyvec,  MASK_PLAYERSOLID|MASK_VISIBLE, RayType_EndPoint, TraceFilterNotWorld, i);
                                                if (TR_DidHit() || IsStuckinCorpsickle(i))
                                                {
                                                        rotation++;
                                                }
                                        }
                		        if (rotation == 7)   //right top
                                        {
                                                enemyvec[0]+=PLAYERXY; // [80][80]
                                                TeleportEntity(i, enemyvec, NULL_VECTOR, NULL_VECTOR);
                                                TR_TraceRayFilter(vec, enemyvec,  MASK_PLAYERSOLID|MASK_VISIBLE, RayType_EndPoint, TraceFilterNotWorld, i);
                                                if (TR_DidHit() || IsStuckinCorpsickle(i))
                                                {
                                                        rotation++;
                                                }
                                        }
                                        if (rotation == 8)        //right
                                        {
                                                enemyvec[1]-=PLAYERXY; // [80][0]
                                                enemyvec[2]+=PLAYERZ;
                                                TeleportEntity(i, enemyvec, NULL_VECTOR, NULL_VECTOR);
                                                TR_TraceRayFilter(vec, enemyvec,  MASK_PLAYERSOLID|MASK_VISIBLE, RayType_EndPoint, TraceFilterNotWorld, i);
                                                if (TR_DidHit() || IsStuckinCorpsickle(i))                                   // If they are still stuck, or trace hit a wall, try again
                                                {
                                                        rotation++;
                                                }
                                        }
                                        if (rotation == 9)   //right bottm
                                        {
                                                enemyvec[1]-=PLAYERXY; // [80][-80]
                                                TeleportEntity(i, enemyvec, NULL_VECTOR, NULL_VECTOR);
                                                TR_TraceRayFilter(vec, enemyvec,  MASK_PLAYERSOLID|MASK_VISIBLE, RayType_EndPoint, TraceFilterNotWorld, i);
                                                if (TR_DidHit() || IsStuckinCorpsickle(i))
                                                {
                                                        rotation++;
                                                }
                                        }
                                        if (rotation == 10)   //down
                                        {
                                                enemyvec[0]-=PLAYERXY; // [0][-80]
                                                TeleportEntity(i, enemyvec, NULL_VECTOR, NULL_VECTOR);
                                                TR_TraceRayFilter(vec, enemyvec,  MASK_PLAYERSOLID|MASK_VISIBLE, RayType_EndPoint, TraceFilterNotWorld, i);
                                                if (TR_DidHit() || IsStuckinCorpsickle(i))
                                                {
                                                        rotation++;
                                                }
                                        }
                                        if (rotation == 11)   //left bottm
                                        {
                                                enemyvec[0]-=PLAYERXY; // [-80][-80]
                                                TeleportEntity(i, enemyvec, NULL_VECTOR, NULL_VECTOR);
                                                TR_TraceRayFilter(vec, enemyvec,  MASK_PLAYERSOLID|MASK_VISIBLE, RayType_EndPoint, TraceFilterNotWorld, i);
                                                if (TR_DidHit() || IsStuckinCorpsickle(i))
                                                {
                                                        rotation++;
                                                }
                                        }
                		        if (rotation == 12)   //left
                                        {
                                                enemyvec[1]+=PLAYERXY; // [-80][0]
                                                TeleportEntity(i, enemyvec, NULL_VECTOR, NULL_VECTOR);
                                                TR_TraceRayFilter(vec, enemyvec,  MASK_PLAYERSOLID|MASK_VISIBLE, RayType_EndPoint, TraceFilterNotWorld, i);
                                                if (TR_DidHit() || IsStuckinCorpsickle(i))
                                                {
                                                        rotation++;
                                                }
                                        }
                		        if (rotation == 13)   //left top
                                        {
                                                enemyvec[1]+=PLAYERXY; // [-80][80]
                                                TeleportEntity(i, enemyvec, NULL_VECTOR, NULL_VECTOR);
                                                TR_TraceRayFilter(vec, enemyvec,  MASK_PLAYERSOLID|MASK_VISIBLE, RayType_EndPoint, TraceFilterNotWorld, i);
                                                if (TR_DidHit() || IsStuckinCorpsickle(i))
                                                {
                                                        rotation++;
                                                }
                                        }
                		        if (rotation == 14)   //top
                                        {
                                                enemyvec[0]+=PLAYERXY; // [0][80]
                                                TeleportEntity(i, enemyvec, NULL_VECTOR, NULL_VECTOR);
                                                TR_TraceRayFilter(vec, enemyvec,  MASK_PLAYERSOLID|MASK_VISIBLE, RayType_EndPoint, TraceFilterNotWorld, i);
                                                if (TR_DidHit() || IsStuckinCorpsickle(i))
                                                {
                                                        rotation++;
                                                }
                                        }
                		        if (rotation == 15)   //right top
                                        {
                                                enemyvec[0]+=PLAYERXY; // [80][80]
                                                TeleportEntity(i, enemyvec, NULL_VECTOR, NULL_VECTOR);
                                                TR_TraceRayFilter(vec, enemyvec,  MASK_PLAYERSOLID|MASK_VISIBLE, RayType_EndPoint, TraceFilterNotWorld, i);
                                                if (TR_DidHit() || IsStuckinCorpsickle(i))
                                                {
                                                        rotation++;
                                                }
                                        }
        		                if (rotation == 16)                                                                           // Could not resolve, respawn alive (frozen = 0 now)
                                        {                                                                                             // Should store medic uber here

                                                if (TF2_GetPlayerClass(i) == TFClass_Medic)
	                                        {
	                                        	new medigun = GetPlayerWeaponSlot(i, TFWeaponSlot_Secondary);
	                                        	if (IsValidEntity(medigun))
	                                        	{
	                                        		decl String:s[64];
	                                        		GetEdictClassname(medigun, s, sizeof(s));
	                                        		if (!strcmp(s,"tf_weapon_medigun"))
	                                        		{
	                                                        	chargemeter[i] = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
	                                        		}
	                                        	}
	                                        }
                                                TF2_RespawnPlayer(i);
                	                        if (g_feedback)
                	                        {
                                                        PrintToChat(i,"\x04[Freeze]:\x01 %t","feedback_collide_respawn");
                	                        }
        	                        }
        	                }
        		}
                }
        }
        return;
}

bool:IsStuckinCorpsickle(ent)                                // Checks if a player is stuck inside of a frozen player on the other team, or world
{                                                            // Teammates and team-owned buildables are ignored.. Weapons and rubble and shit are not
	decl Float:flOrigin[3];
	decl Float:flMins[3];
	decl Float:flMaxs[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", flOrigin);
	GetEntPropVector(ent, Prop_Send, "m_vecMins", flMins);
	GetEntPropVector(ent, Prop_Send, "m_vecMaxs", flMaxs);

	TR_TraceHullFilter(flOrigin, flOrigin, flMins, flMaxs, MASK_SOLID, TraceFilterNotSelf, ent);
	return TR_DidHit();
}

public bool:TraceFilterNotSelf(entity, contentsMask, any:client)
{
        if ((entity > 0) && (entity <= MaxClients))          // player index range
        {
                if(frozen[entity] && GetClientTeam(entity) != GetClientTeam(client))
                {
                         return true;                        // The client is on a different team from the frozen enemy, do it
                }
                else
                {
                         return false;                       // The client is on the same team, or the other player isn't frozen, don't do it
                }
        }
        else if (IsValidEdict(entity))
        {
                decl String:ObjClassName[15];
                GetEdictClassname(entity, ObjClassName, sizeof(ObjClassName));

                if (StrEqual(ObjClassName, "tf_ammo_pack"))
                {
                        return false;
                }
                else if (StrEqual(ObjClassName, "obj_sentrygun"))
                {
                        if (GetClientTeam(client) == GetEntProp(entity, Prop_Send, "m_iTeamNum"))
                        {
                                return false;
                        }
                }
                else if (StrEqual(ObjClassName, "obj_dispenser"))
                {
                        if (GetClientTeam(client) == GetEntProp(entity, Prop_Send, "m_iTeamNum"))
                        {
                                return false;
                        }
                }
                else if (StrEqual(ObjClassName, "obj_teleporter"))
                {
                        if (GetClientTeam(client) == GetEntProp(entity, Prop_Send, "m_iTeamNum"))
                        {
                                return false;
                        }
                }
        }

	return true;                                         // The client may become stuck in world geometry props, or enemy buildables, do it
}

public bool:TraceFilterNotWorld(entity, mask, any:client)                    // Tests if the player is stuck in world geometry, props, etc.
{
        if ((entity == 0) || (entity > MaxClients))                          // outside of player index range
        {
                return true;
        }

	return false;
}

stock ResetPlayerSpeed(client)                                               // Decides what class player is and restores appropriate speed
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	switch(class)
	{
		case TFClass_DemoMan: SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 280.0);
		case TFClass_Engineer: SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 300.0);
		case TFClass_Heavy: SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 230.0);
		case TFClass_Medic: SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 320.0);
		case TFClass_Pyro: SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 300.0);
		case TFClass_Scout: SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 400.0);
		case TFClass_Sniper: SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 300.0);
		case TFClass_Soldier: SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 240.0);
		case TFClass_Spy: SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 300.0);
	}
}

stock ResetPlayerHealth(client)                                              // Decides what class player is and restores appropriate health
{
	new TFClassType:class = TF2_GetPlayerClass(client);
        if (stuck[client])                                                   // Penalize stuck clients by removing 20% base health for the rest of the round
        {                                                                    // yes.. that 20% is hard-coded in there, perhaps a cvar later, but I've already littered the server with so many.
                switch(class)
	        {
		        case TFClass_DemoMan: SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(140*g_unfreezeHPRatio));
		        case TFClass_Engineer: SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(100*g_unfreezeHPRatio));
		        case TFClass_Heavy: SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(240*g_unfreezeHPRatio));
		        case TFClass_Medic: SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(120*g_unfreezeHPRatio));
		        case TFClass_Pyro: SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(140*g_unfreezeHPRatio));
		        case TFClass_Scout: SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(100*g_unfreezeHPRatio));
		        case TFClass_Sniper: SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(100*g_unfreezeHPRatio));
		        case TFClass_Soldier: SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(160*g_unfreezeHPRatio));
		        case TFClass_Spy: SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(100*g_unfreezeHPRatio));
	        }
        }
        else
        {
                switch(class)
	        {
		        case TFClass_DemoMan: SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(175*g_unfreezeHPRatio));
		        case TFClass_Engineer: SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(125*g_unfreezeHPRatio));
		        case TFClass_Heavy: SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(300*g_unfreezeHPRatio));
		        case TFClass_Medic: SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(150*g_unfreezeHPRatio));
		        case TFClass_Pyro: SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(175*g_unfreezeHPRatio));
		        case TFClass_Scout: SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(125*g_unfreezeHPRatio));
		        case TFClass_Sniper: SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(125*g_unfreezeHPRatio));
		        case TFClass_Soldier: SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(200*g_unfreezeHPRatio));
		        case TFClass_Spy: SetEntProp(client, Prop_Data, "m_iHealth", RoundToNearest(125*g_unfreezeHPRatio));
	        }
        }
}

unfreezeAll()
{
        for (new i=0; i<sizeof(frozen); i++)                                 // Re-initialize frozen array
        {
        	frozen[i] = false;                                           // Set everyone to non-frozen
        	stuck[i] = 0;                                                // Set everyone to non-stuck
        	respawned[i] = false;
       	}
}

///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// Proximity ////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

public Action:Timer_FreezeBeacon(Handle:timer, any:client)                    // Handles Proximity Detection for the Frozen Player
{
	if (!frozen[client] ||
            !IsValidClient(client) ||
	    !IsPlayerAlive(client) )
	{
		return Plugin_Stop;
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //////// Weapon Check /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	new primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	new secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);

        if (primary != -1 || secondary != -1)                                   // Weapon replace mods and crap can grant them stuff after us, if they are equipped, strip them
        {
        	giveDummyWeapons(client);
                if (!IsFakeClient(client))
                {
                        new Handle:pack;
                        CreateDataTimer(0.2, Timer_StopYouHaveViolatedTheLaw, pack, TIMER_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);   // Deal with the weapon swap movement resets
                        WritePackCell(pack, client);
                        WritePackCell(pack, 7);
                }
	}
	else if ((IsValidEdict(weapon) && (weapon > 0)) &&
                 (GetEntProp(weapon, Prop_Send, "m_iEntityQuality") != 10) )   // Check the quality, if it's not 10 (nerf fists), replace it
        {
        	giveDummyWeapons(client);
                if(!IsFakeClient(client))
                {
                        new Handle:pack;
                        CreateDataTimer(0.2, Timer_StopYouHaveViolatedTheLaw, pack, TIMER_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);   // Deal with the weapon swap movement resets
                        WritePackCell(pack, client);
                        WritePackCell(pack, 7);
                }
        }

        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //////// Graphical ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	decl Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += RINGHEIGHT;                                                 // Raise height of rings

        decl Float:radius1;

        if (stuck[client] == 1)
        {
                radius1 = g_freezeDist + g_freezeDist + g_freezeDist;
        }
        else
        {
                radius1 = g_freezeDist + g_freezeDist;
        }
        new Float:radius2 = radius1 + 1;

	if (GetClientTeam(client) == 2)
        {                                                                     // Red Version
                for (new i=1; i<MaxClients; i++)
		{
			if (IsValidClient(i) && GetClientTeam(i) != BLU)      // Don't send to blue team, but allow spectators, etc.
			{
		                TE_SetupBeamRingPoint(vec, radius2, radius1, g_GlowSpriteRed, gHalo1, 0, 30, 1.0, RINGWIDTH, 0.0, {255,0,0,255}, 10, 0);
                                TE_SendToClient(i);
			}
		}
        }
        else
        {                                                                     // Blue Version
                for (new i=1; i<MaxClients; i++)
		{
			if (IsValidClient(i) && GetClientTeam(i) != RED)      // Don't send to red team, but allow spectators, etc.
			{
                		TE_SetupBeamRingPoint(vec, radius2, radius1, g_GlowSpriteBlue, gHalo1, 0, 30, 1.0, RINGWIDTH, 0.0, {255,255,255,255}, 10, 0);
                                TE_SendToClient(i);
			}
		}
        }

        TF2_AddCondition(client, TFCond_InHealRadius, 1.5);                   // Emit the particle effect to all
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //////// Proximity ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 1.0);                                        // Pulse Freeze Updates, Buffs Can Remove It

	new Float:vClientPosition[3], Float:dist, Float:maxdist;

        if (stuck[client] == 1)
        {
                maxdist = g_freezeDist + g_freezeDist;                                                  // Expand the radius for stuck players
        }
        else
        {
                maxdist = g_freezeDist;
        }

	vec[2] -= RINGHEIGHT;                                                                           // Set our vector back to AbsOrigin

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!frozen[i] && IsValidClient(i) && IsPlayerAlive(i))
		{
			GetClientEyePosition(i, vClientPosition);

			dist = GetVectorDistance(vClientPosition, vec, false);

			if (dist < maxdist)							        // Player is in range of the effect
			{
                                if ((GetClientTeam(client) == GetClientTeam(i)) && (i != client))	// Same team, not same player
                                {
                                        if (playerProx[client][i] == 0)                                 // First Detection of This Teammate in Range, Fire off Countdown
                                        {                                                               // It only pulses every second for initial detections, but that's good enough.
                                                playerProx[client][i] = 1;                              // This is somewhat costly to do, and the temp ents look best @ 1 second refresh

                                                new Handle:pack;
                                                CreateDataTimer(g_proximityIval, Timer_ProxTestCountdown, pack, TIMER_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
                                                WritePackCell(pack, client);
                                                WritePackCell(pack, i);
                                                WritePackCell(pack, g_proximityIter);
					}
                                }
			}
		}
	}

	return Plugin_Continue;
}

public Action:Timer_ProxTestCountdown(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new frozenguy = ReadPackCell(pack);
	new teammate = ReadPackCell(pack);
	new iterations = ReadPackCell (pack);

	if (!IsValidClient(frozenguy) ||
            !IsPlayerAlive(frozenguy) ||
            !IsValidClient(teammate) ||
	    !IsPlayerAlive(teammate))
	{
		return Plugin_Stop;
	}

	if (!frozen[frozenguy] || frozen[teammate])                    // Teammate became frozen or invalid, abort the timer)
	{
                PrintCenterText(frozenguy, "");                        // Clear Center Text
                PrintCenterText(teammate, "");

		return Plugin_Stop;
	}

        if (TF2_IsPlayerInCondition(teammate, TFCond_Cloaked) ||       // Clients meeting these conditions will be ignored
            TF2_IsPlayerInCondition(teammate, TFCond_Disguised) ||
            TF2_IsPlayerInCondition(teammate, TFCond_Bonked))
        {
                playerProx[frozenguy][teammate] = 0;                   // Teammate invalid, reset state so this teamate can fire off new countdown
                                                                       // Either kill it each pulse with plugins_stop and allow a new one to occur
                return Plugin_Stop;                                    // Or return plugin_continue and have spies have real long timers...
	}
	
        if(!unfreezer[frozenguy])
        {
                unfreezer[frozenguy] = teammate;                       // If no teammate is set as the ufnreezing client, this client is the one.
        }

        if (iterations == 0)                                           // Countdown hit, unfreeze the player!
        {
                if (stuck[frozenguy] == 1)                             // If they are being unstuck, move them to spawn
                {
                        playerProx[frozenguy][teammate] = 0;           // Allow reviving teammate to re-trigger revive on them later
                        stuck[frozenguy] = 2;                          // Increment stuck count to be out of valid range
                        respawned[frozenguy] = true;
                        TF2_RespawnPlayer(frozenguy);                  // Respawn frozen (frozen = 0 now)
                        if (g_feedback)
		        {
			        PrintToChat(frozenguy, "\x04[Freeze]:\x01 %t","feedback_stuck_saved");
		        }
                }
                else
                {
                        broadcastUnfreeze(frozenguy,teammate);         // Broadcast fake event message
                        unfreezeClient(frozenguy,teammate);            // Otherwise, Unfreeze Them
                }

                PrintCenterText(frozenguy, "");                        // Clear Center Text
                PrintCenterText(teammate, "");
                unfreezer[frozenguy] = 0;                              // We are done unfreezing the client, release the lock

		return Plugin_Stop;
        }
	if (testProx(frozenguy, teammate))
        {
                ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                //////// Graphical ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                if(unfreezer[frozenguy] == teammate)
                {
		        decl Float:vec[3];
		        GetClientAbsOrigin(frozenguy, vec);
		        vec[2] += RINGHEIGHT;                                                 // Raise height of rings
                                                                                      // 0 will be last iteration,   g_proximityIter = max iterations
                        new Float:ratio = (g_proximityIter-iterations)/float(g_proximityIter);
                        decl Float:radius1;

        	        if (stuck[frozenguy] == 1)
        	        {
                                radius1 = (g_freezeDist + g_freezeDist + g_freezeDist)*ratio;
        	        }
        	        else
        	        {
                                radius1 = (g_freezeDist + g_freezeDist)*ratio;
                        }

                        new Float:radius2 = radius1 + 1;                                      // Whatever radius 1 is, make this 1 larger.

		        if (GetClientTeam(frozenguy) == 2)
        	        {                                                                     // Red Version
                	        for (new i=1; i<MaxClients; i++)
			        {
				        if (IsValidClient(i) && GetClientTeam(i) != BLU)      // Don't send to blue team, but allow spectators, etc.
				        {
                			        TE_SetupBeamRingPoint(vec, radius2, radius1, g_GlowSpriteRed, gHalo1, 0, 30, g_proximityIval, PINGWIDTH, 0.0, {255,255,255,255}, 10, 0);
                                	        TE_SendToClient(i);
				        }
			        }
        	        }
        	        else
        	        {                                                                     // Blue Version
                        for (new i=1; i<MaxClients; i++)
		        {
				        if (IsValidClient(i) && GetClientTeam(i) != RED)      // Don't send to red team, but allow spectators, etc.
				        {
                			        TE_SetupBeamRingPoint(vec, radius2, radius1, g_GlowSpriteRed, gHalo1, 0, 30, g_proximityIval, PINGWIDTH, 0.0, {255,255,255,255}, 10, 0);
                                	        TE_SendToClient(i);
				        }
			        }
        	        }
                }
                ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                decl String:buffer[100];
                Format(buffer,iterations+1,meter);                     // Generate Meter

                PrintCenterText(teammate, buffer);                     // Don't flood the client

                if(unfreezer[frozenguy] == teammate)
                {
                        PrintCenterText(frozenguy, buffer);            // Don't flood the client, he's got enought to worry about

                }

                new Handle:datapack;                                   // Fire another timer, this same function once again
                CreateDataTimer(g_proximityIval, Timer_ProxTestCountdown, datapack, TIMER_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
                WritePackCell(datapack, frozenguy);
                WritePackCell(datapack, teammate);
                WritePackCell(datapack, iterations-1);                 // teammate was in range, increment count
        }
        else
        {
                PrintCenterText(frozenguy, "");                        // Clear Center Text
                PrintCenterText(teammate, "");
		playerProx[frozenguy][teammate] = 0;                   // Teammate moved away, reset state so this teamate can fire off new countdown

                if(unfreezer[frozenguy] == teammate)
                {
                        unfreezer[frozenguy] = 0;                      // If they were the first unfreezer, they arn't anymore.
                }

                return Plugin_Stop;                                    // We'd better get back, cause it'll be dark soon, and they mostly come at night... mostly
        }

	return Plugin_Continue;
}

stock testProx(frozenguy, teammate)                                    // Tests if two players are in range of eachother, returns true if they are
{
        decl Float:Position1[3], Float:Position2[3], Float:dist, Float:maxdist;
        if (stuck[frozenguy] == 1)
        {
                maxdist = g_freezeDist + g_freezeDist;                 // Double the distance for unstuck
        }
        else
        {
                maxdist = g_freezeDist;
        }
        GetClientAbsOrigin(frozenguy, Position1);
        GetClientAbsOrigin(teammate, Position2);
        dist = GetVectorDistance(Position1, Position2, false);
        if (dist <= maxdist)
        {
        	return true;
        }
	return false;
}

purgeProximity(client)
{
        for (new i=0; i<sizeof(playerProx[]); i++)
	{
		playerProx[client][i] = 0;				        // Initialize client array
	}
}

broadcastUnfreeze(frozenguy,teammate)                                           // Broadcast MSG = teammamte (icon) defended frozenguy, yay can be seen in logs
{
	new Handle:event = CreateEvent("teamplay_capture_blocked");
	if (event == INVALID_HANDLE)
	{
		return;
	}
        decl String:namefrozen[32];
        decl String:buffer[40] = "teammate ";
        GetClientName(frozenguy, namefrozen, 32);
        StrCat(buffer, 40, namefrozen);
	SetEventString(event, "cpname", buffer);
        SetEventInt(event, "blocker", teammate);
	FireEvent(event);
}

///////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////// Block Keys ////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

public Action:Command_InterceptTaunt(client, const String:command[], args)
{
	if (frozen[client])                                                                                  // Do not allow forzen players to taunt, handles heavy fists and taunt revive bugs
	{
		return Plugin_Handled;
	}
        if (activeround == 2 && IsValidClient(client) && (TF2_GetPlayerClass(client) == TFClass_Medic))      // Block Ubersaw Taunt, gives uber when taunting corpsicles
	{
		new weapon = GetEntPropEnt( client, Prop_Send, "m_hActiveWeapon" );
		if (weapon > MaxClients && IsValidEntity( weapon ) && (GetEntProp( weapon, Prop_Send, "m_iItemDefinitionIndex" ) == 37))
		{
			return Plugin_Handled;
	        }
        }
	return Plugin_Continue;
}

public Action:Command_InterceptItemTaunt(client, const String:command[], args)
{
	if (frozen[client])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Command_InterceptSuicide(client, const String:command[], args)                    // Kill + Explode is blocked
{
	if ((activeround && frozen[client]) || activeround == 1)                                // Block Suicide of Frozen Players and in the Pre-Round
	{
		if (g_feedback && IsValidClient(client))
		{
			if(activeround == 1)
                        {
                                PrintToChat(client, "\x04[Freeze]:\x01 %t","feedback_suicide_setup");
                        }
                        else
                        {
                                PrintToChat(client, "\x04[Freeze]:\x01 %t","feedback_suicide_activeround");
                        }
		}
                return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Command_InterceptSwap(client, const String:command[], args)                       // Spectate + Jointeam is blocked
{
	if (activeround == 2 && !unassigned[client])
	{                                                                                       // Block Swaps in the Active Round for Active Players
		if (g_feedback && IsValidClient(client))
		{
			PrintToChat(client, "\x04[Freeze]:\x01 %t","feedback_joinclass_activeround");
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Command_InterceptClass(client, const String:command[], args)                       // Joinclass is blocked
{
        if (activeround && unassigned[client] && IsValidClient(client) && !IsPlayerAlive(client))// Force new joiners to respawn in active round (else they'll be dead)
        {
                CreateTimer(0.1, Timer_RespawnLateJoiner, client);                               // Delay it
        }
        else if (activeround == 2 && !unassigned[client])
	{                                                                                        // Block Swaps in the Active Round for Active Players
		if (g_feedback && IsValidClient(client))
		{
			PrintToChat(client, "\x04[Freeze]:\x01 %t","feedback_joinclass_activeround");
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Timer_RespawnLateJoiner(Handle:timer, any:client)                                  // Respawns a player
{
	if (IsValidClient(client))
	{
                TF2_RespawnPlayer(client);
                if (activeround == 2)
                {
        	        if (IsValidClient(client) && IsPlayerAlive(client))                      // If they are dead, the problem should resolve itself
		        {
			        playerclass[client] = TF2_GetPlayerClass(client);                // Store their class, doesn't matter when we do this for these late kids
		        }
                        FakeClientCommand(client,"kill");                                        // Slay them in the active round

                        if (g_feedback)
                        {
                                PrintToChat(client,"\x04[Freeze]:\x01 %t","feedback_joinpenalty");
         	        }
                }
        }
}

public Action:OnPlayerRunCmd( Client, &buttons, &Impulse, Float:Vel[3], Float:Angles[3], &Weapon)
{
	if (frozen[Client])
	{
		buttons &= ~IN_JUMP;                                                             // Jumping is annoying, and silly ice statues can't jump.
		buttons &= ~IN_ATTACK;                                                           // Block attacking, can't stop CSP but they can't destroy stickies
		buttons &= ~IN_ATTACK2;                                                          // Other players won't see them attack either
	}
        return Plugin_Continue;
}

///////////////////////////////////////////////////////////////////////////////////
////////////////////////////////// Read Config ////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
stock ReadMapConfigs()                                                                           // Loads ConVars from file, perhaps backwards assed, but it's easy and flexible
{                                                                                                // Allows mod to function without config file, and anything can be changed on-the-fly
	new Handle:kv = CreateKeyValues("FreezeMaps");                                           // Values will also be range checked.
	decl String:file[256];
	BuildPath(Path_SM, file, sizeof(file), "configs/freezetag_maps.cfg");
	if (!FileToKeyValues(kv, file))
	{
		CloseHandle(kv);
		
		LogError("%s NOT loaded! File Required for Automatic Configuration!", file);
		return false;
	}

        decl String:mapName[32];
	GetCurrentMap(mapName, sizeof(mapName));

	for (new i=1; mapName[i] != '\0'; i++)
        {                                                            // Just parse between deliminators
		if (IsCharUpper(mapName[i]))
                {
			mapName[i] = CharToLower(mapName[i]);
		}
	}

        if (KvJumpToKey(kv, mapName))                                       // Map Found
        {
                LogMessage("[TF2] Freeze Tag: Located entry for map: %s in the freezetag configuration file, attempting to load map-specific settings.",mapName);
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

	new preround = KvGetNum(kv, "preround", -1);                        // So like.. if a val is not found, it'll use whatever is set in the convar
	new timer = KvGetNum(kv, "timer", -1);
	new maxrounds = KvGetNum(kv, "maxrounds", -1);
	new Float:radius = KvGetFloat(kv, "radius", -1.0);
	new duration = KvGetNum(kv, "duration", -1);
	new opendoors = KvGetNum(kv, "opendoors", -1);
	new openaps = KvGetNum(kv, "openaps", -1);
	new blockcaps = KvGetNum(kv, "blockcaps", -1);
	new blockflags = KvGetNum(kv, "blockflags", -1);
	new blocktrains = KvGetNum(kv, "blocktrains", -1);
	new Float:hpratio = KvGetFloat(kv, "hpratio", -1.0);
        new kvcount = 0;
	if (preround != -1)
	{
                SetConVarInt(g_hCvarPreRoundTime,preround);
                kvcount++;
        }
	if (timer != -1)
	{
                SetConVarInt(g_hCvarTimer,timer);
                kvcount++;
        }
	if (maxrounds != -1)
	{
                SetConVarInt(g_hCvarMaxRounds,maxrounds);
                kvcount++;
        }
	if (radius != -1)
	{
                SetConVarFloat(g_hCvarRadius,radius);
                kvcount++;
        }
	if (duration != -1)
	{
                SetConVarInt(g_hCvarduration,duration);
                kvcount++;
        }
	if (opendoors != -1)
	{
                SetConVarInt(g_hCvarOpenDoors,opendoors);
                kvcount++;
        }
	if (openaps != -1)
	{
                SetConVarBool(g_hCvarOpenAPs,openaps == 0 ? false : true);
                kvcount++;
        }
	if (blockcaps != -1)
	{
                SetConVarBool(g_hCvarDisableCaps,blockcaps == 0 ? false : true);
                kvcount++;
        }
	if (blockflags != -1)
	{
                SetConVarBool(g_hCvarDisableFlags,blockflags == 0 ? false : true);
                kvcount++;
        }
	if (blocktrains != -1)
	{
                SetConVarBool(g_hCvarDisableTrains,blocktrains == 0 ? false : true);
                kvcount++;
        }
	if (hpratio != -1.0)
	{
                SetConVarFloat(g_hCvarUnfreezeHPRatio,hpratio);
                kvcount++;
        }

	if(kvcount)
	{
                LogMessage("[TF2] Freeze Tag: Loaded %i settings for map: %s from the freezetag configuration file.",kvcount,mapName);
        }
        else
        {
                LogMessage("[TF2] Freeze Tag: ERROR: Loaded 0 settings for map: %s. Check your freezetag configuration file for errors.",mapName);
        }

        CloseHandle(kv);

        return true;
}

///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////// Stocks //////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

stock bool:IsValidClient(client)                                                              // *#@* ME
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}