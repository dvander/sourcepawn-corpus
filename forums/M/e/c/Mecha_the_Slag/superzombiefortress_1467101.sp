////////////////////////////////////////////////////////////////////////////////
//
//   Super Zombie Fortress
//
//    This is an extended modification of dirtyminuth's ZF mod.
//
//    Author: dirtyminuth (original), Mecha the Slag (Super Zombie Fortress)
//
//    Credits: Sirot, original author of ZF.
//
////////////////////////////////////////////////////////////////////////////////

#pragma semicolon 1

//
// Includes
//
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <tf2_stocks>
#include <colors>
#include <tf2items>



#include "zf_util_base.inc"
#include "zf_util_pref.inc"

//#define FEATURE_GAMEPLAYBAN     64
#if defined FEATURE_GAMEPLAYBAN
#include <slaginventory>
#endif

//
// Plugin Information
//
#define PLUGIN_VERSION "1.05"
public Plugin:myinfo = 
{
    name                    = "Super Zombie Fortress",
    author                = "Mecha the Slag (Advanced), dirtyminuth (Recode), Sirot (Original)",
    description     = "Pits a team of survivors aganist an endless onslaught of zombies.",
    version             = PLUGIN_VERSION,
    url                     = "http://forums.alliedmods.net/showthread.php?p=1227078"
}

#define PLAYERBUILTOBJECT_ID_DISPENSER    0
#define PLAYERBUILTOBJECT_ID_TELENT         1
#define PLAYERBUILTOBJECT_ID_TELEXIT        2
#define PLAYERBUILTOBJECT_ID_SENTRY         3

#define GOO_INCREASE_RATE                   3

#define SOUND_BONUS                         "ui/trade_ready.wav"

//
// State
//

// Global State
new zf_bEnabled;
new zf_bNewRound;
new zf_spawnSurvivorsKilledCounter;
new zf_spawnZombiesKilledCounter;
// Client State
new zf_critBonus[MAXPLAYERS+1];
new zf_hoardeBonus[MAXPLAYERS+1];
new zf_rageTimer[MAXPLAYERS+1];

// Global Timer Handles
new Handle:zf_tMain;
new Handle:zf_tMainFast;
new Handle:zf_tMainSlow;
new Handle:zf_tHoarde;
new Handle:zf_tDataCollect;

// Cvar Handles
new Handle:zf_cvForceOn;
new Handle:zf_cvRatio;
new Handle:zf_cvAllowTeamPref;
new Handle:zf_cvSwapOnPayload;
new Handle:zf_cvSwapOnAttdef;
new Handle:zf_cvTankHealth;
new Handle:zf_cvTankHealthMin;
new Handle:zf_cvTankHealthMax;
new Handle:zf_cvTankTime;
new Handle:zf_cvFrenzyChance;
new Handle:zf_cvFrenzyTankChance;
new Handle:zf_cvTankOnce;

new Float:g_fZombieDamageScale = 1.0;

new g_StartTime = 0;
new g_AdditionalTime = 0;

// Sound system
new Handle:g_hMusicArray = INVALID_HANDLE;
new Handle:g_hFastRespawnArray = INVALID_HANDLE;

new Handle:hConfiguration = INVALID_HANDLE;
new Handle:hEquipWearable = INVALID_HANDLE;

new Handle:hWeaponSandman = INVALID_HANDLE;
new Handle:hWeaponWatch = INVALID_HANDLE;
new Handle:hWeaponStickyLauncher = INVALID_HANDLE;
new Handle:hWeaponRocketLauncher = INVALID_HANDLE;
new Handle:hWeaponSword = INVALID_HANDLE;
new Handle:hWeaponShovel = INVALID_HANDLE;
new Handle:hWeaponFists = INVALID_HANDLE;
new Handle:hWeaponSteelFists = INVALID_HANDLE;
new Handle:hWeaponSyringe = INVALID_HANDLE;
new Handle:hWeaponBonesaw = INVALID_HANDLE;
new Handle:hWeaponLochNLoad = INVALID_HANDLE;
new Handle:hWeaponFlareGun = INVALID_HANDLE;
new Handle:hWeaponShotgunPyro = INVALID_HANDLE;
new Handle:hWeaponShotgunSoldier = INVALID_HANDLE;
new Handle:hWeaponBison = INVALID_HANDLE;
new Handle:hWeaponTarge = INVALID_HANDLE;

new bool:g_bBackstabbed[MAXPLAYERS+1] = false;
new Handle:g_hBonus[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_hBonusTimers[MAXPLAYERS+1] = INVALID_HANDLE;
new g_iBonusCombo[MAXPLAYERS+1] = 0;
new g_iHitBonusCombo[MAXPLAYERS+1] = 0;
new bool:g_bBonusAlt[MAXPLAYERS+1] = false;
new Float:g_fDamageTakenLife[MAXPLAYERS+1] = 0.0;
new Float:g_fDamageDealtLife[MAXPLAYERS+1] = 0.0;
new bool:g_bRoundActive = false;

new g_iControlPointsInfo[20][2];
new g_iControlPoints = 0;
new bool:g_bCapturingLastPoint = false;
new g_iCarryingItem[MAXPLAYERS+1] = -1;

#define GAMEMODE_DEFAULT        0
#define GAMEMODE_NEW            1
new g_iMode = GAMEMODE_DEFAULT;

#define MUSIC_DRUMS             0
#define MUSIC_SLAYER_MILD       1
#define MUSIC_SLAYER            2
#define MUSIC_TRUMPET           3
#define MUSIC_SNARE             4
#define MUSIC_BANJO             5
#define MUSIC_HEART_SLOW        6
#define MUSIC_HEART_MEDIUM      7
#define MUSIC_HEART_FAST        8
#define MUSIC_RABIES            9
#define MUSIC_DEAD              10
#define MUSIC_INCOMING          11
#define MUSIC_PREPARE           12
#define MUSIC_DROWN             13
#define MUSIC_TANK              14
#define MUSIC_LASTSTAND         15
#define MUSIC_NEARDEATH         16
#define MUSIC_NEARDEATH2        17
#define MUSIC_AWARD             18
#define MUSIC_LASTTENSECONDS    19
#define MUSIC_MAX               20

#define MUSIC_NONE                  0
#define MUSIC_INTENSE               1
#define MUSIC_MILD                  2
#define MUSIC_VERYMILD3             3
#define MUSIC_VERYMILD2             4
#define MUSIC_VERYMILD1             5
#define MUSIC_GOO                   6
#define MUSIC_TANKMOOD              7
#define MUSIC_LASTSTANDMOOD         8
#define MUSIC_PLAYERNEARDEATH       9
#define MUSIC_LASTTENSECONDSMOOD    10

#define CHANNEL_MUSIC_NONE      0
#define CHANNEL_MUSIC_DRUMS     350
#define CHANNEL_MUSIC_SLAYER    351
#define CHANNEL_MUSIC_SINGLE    352

#define DISTANCE_GOO            6.0
#define TIME_GOO                6.0

#define INFECTED_NONE           0
#define INFECTED_TANK           1

enum TFClassWeapon
{
	TFClassWeapon_Unknown = 0,
	TFClassWeapon_Scout,
	TFClassWeapon_Sniper,
	TFClassWeapon_Soldier,
	TFClassWeapon_DemoMan,
	TFClassWeapon_Medic,
	TFClassWeapon_Heavy,
	TFClassWeapon_Pyro,
	TFClassWeapon_Spy,
	TFClassWeapon_Engineer,
	TFClassWeapon_Group_Shotgun
};


new g_iMusicCount[MUSIC_MAX] = 0;
new String:g_strMusicLast[MAXPLAYERS+1][MUSIC_MAX][PLATFORM_MAX_PATH];
new g_iMusicLevel[MAXPLAYERS+1] = 0;
new Handle:g_hMusicTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new g_iMusicRandom[MAXPLAYERS+1][2];
new g_iMusicFull[MAXPLAYERS+1] = 0;
new Handle:g_hGoo = INVALID_HANDLE;

new bool:g_bZombieRage = false;
new g_iZombieTank = 0;
new bool:g_bZombieRageAllowRespawn = false;
new g_iGooId = 0;
new g_iGooMultiplier[MAXPLAYERS+1] = 0;
new bool:g_bGooified[MAXPLAYERS+1] = false;
new bool:g_bHitOnce[MAXPLAYERS+1] = false;

new g_iSpecialInfected[MAXPLAYERS+1] = 0;
new g_iDamage[MAXPLAYERS+1] = 0;
new g_iKillsThisLife[MAXPLAYERS+1] = 0;
new g_iSuperHealth[MAXPLAYERS+1] = 0;
new g_iSuperHealthSubtract[MAXPLAYERS+1] = 0;
new g_iStartSurvivors = 0;

new bool:g_bTankOnce = false;

new String:g_strSoundFleshHit[][128] =
{
    "physics/flesh/flesh_impact_bullet1.wav",
    "physics/flesh/flesh_impact_bullet2.wav",
    "physics/flesh/flesh_impact_bullet3.wav",
    "physics/flesh/flesh_impact_bullet4.wav",
    "physics/flesh/flesh_impact_bullet5.wav"
};

new String:g_strSoundCritHit[][128] =
{
    "player/crit_received1.wav",
    "player/crit_received2.wav",
    "player/crit_received3.wav"
};

////////////////////////////////////////////////////////////
//
// Sourcemod Callbacks
//
////////////////////////////////////////////////////////////
public OnPluginStart()
{
    // Check for necessary extensions
    if(GetExtensionFileStatus("sdkhooks.ext") < 1)
        SetFailState("SDK Hooks is not loaded.");

    // Add server tag.
    AddServerTag("zf");    
                
    // Initialize global state
    zf_bEnabled = false;
    zf_bNewRound = true;
    setRoundState(RoundInit1);
            
    // Initialize timer handles
    zf_tMain = INVALID_HANDLE;
    zf_tMainSlow = INVALID_HANDLE;
    zf_tMainFast = INVALID_HANDLE;
    zf_tHoarde = INVALID_HANDLE;
    
    // Initialize other packages
    utilBaseInit();
    utilPrefInit();
    
    // Register cvars
    CreateConVar("sm_zf_version", PLUGIN_VERSION, "Current Zombie Fortress Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY); 
    zf_cvForceOn = CreateConVar("sm_zf_force_on", "1", "<0/1> Activate ZF for non-ZF maps.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    zf_cvRatio = CreateConVar("sm_zf_ratio", "0.8", "<0.01-1.00> Percentage of players that start as survivors.", FCVAR_PLUGIN, true, 0.01, true, 1.0);
    zf_cvAllowTeamPref = CreateConVar("sm_zf_allowteampref", "0", "<0/1> Allow use of team preference criteria.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    zf_cvSwapOnPayload = CreateConVar("sm_zf_swaponpayload", "1", "<0/1> Swap teams on non-ZF payload maps.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    zf_cvSwapOnAttdef = CreateConVar("sm_zf_swaponattdef", "1", "<0/1> Swap teams on non-ZF attack/defend maps.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    zf_cvTankHealth = CreateConVar("sm_zf_tank_health", "400", "Amount of health the Tank gets per alive survivor", FCVAR_PLUGIN, true, 10.0);
    zf_cvTankHealthMin = CreateConVar("sm_zf_tank_health_min", "1000", "Minimum amount of health the Tank can spawn with", FCVAR_PLUGIN, true, 0.0);
    zf_cvTankHealthMax = CreateConVar("sm_zf_tank_health_max", "8000", "Maximum amount of health the Tank can spawn with", FCVAR_PLUGIN, true, 0.0);
    zf_cvTankTime = CreateConVar("sm_zf_tank_time", "50.0", "Adjusts the damage the Tank takes per second. If the value is 70.0, the Tank will take damage that will make him die (if unhurt by survivors) after 70 seconds. 0 to disable.", FCVAR_PLUGIN, true, 0.0);
    zf_cvFrenzyChance = CreateConVar("sm_zf_frenzy_chance", "5.0", "% Chance of a random frenzy", FCVAR_PLUGIN, true, 0.0);
    zf_cvFrenzyTankChance = CreateConVar("sm_zf_frenzy_tank", "25.0", "% Chance of a Tank appearing instead of a frenzy", FCVAR_PLUGIN, true, 0.0);
    zf_cvTankOnce = CreateConVar("sm_zf_tank_once", "60.0", "Every round there is at least one Tank. If no Tank has appeared, a Tank will be manually created when there is sm_zf_tank_once time left. Ie. if the value is 60, the Tank will be spawned when there's 60% of the time left.", FCVAR_PLUGIN, true, 0.0);

    // Hook events
    HookEvent("teamplay_round_start", event_RoundStart);
    HookEvent("teamplay_setup_finished", event_SetupEnd);
    HookEvent("teamplay_round_win", event_RoundEnd);
    HookEvent("teamplay_timer_time_added", EventTimeAdded);
    HookEvent("player_spawn", event_PlayerSpawn);    
    HookEvent("player_death", event_PlayerDeath);
    
    HookEvent("player_builtobject", event_PlayerBuiltObject); 
    HookEvent("teamplay_point_captured", event_CPCapture); 
    HookEvent("teamplay_point_startcapture", event_CPCaptureStart); 

    // Register Admin Commands
    RegAdminCmd("sm_zf_enable", command_zfEnable, ADMFLAG_GENERIC, "Activates the Zombie Fortress plugin.");
    RegAdminCmd("sm_zf_disable", command_zfDisable, ADMFLAG_GENERIC, "Deactivates the Zombie Fortress plugin.");
    RegAdminCmd("sm_zf_swapteams", command_zfSwapTeams, ADMFLAG_GENERIC, "Swaps current team roles.");
    RegAdminCmd("sm_zf_rabies", command_rabies, ADMFLAG_GENERIC, "Rabies.");
    RegAdminCmd("sm_zf_goo", command_goo, ADMFLAG_GENERIC, "Goo!");
    RegAdminCmd("sm_zf_tank", command_tank, ADMFLAG_GENERIC, "Become a tank");
    RegAdminCmd("sm_zf_tank_random", command_tank_random, ADMFLAG_GENERIC, "Pick a random tank");
    
    // Hook Client Commands
    AddCommandListener(hook_JoinTeam, "jointeam");
    AddCommandListener(hook_JoinClass, "joinclass");
    AddCommandListener(hook_VoiceMenu, "voicemenu"); 
    // Hook Client Console Commands    
    AddCommandListener(hook_zfTeamPref, "zf_teampref");
    // Hook Client Chat / Console Commands
    RegConsoleCmd("zf", cmd_zfMenu);
    RegConsoleCmd("zf_menu", cmd_zfMenu); 
    
    CreateTimer(10.0, SpookySound, 0, TIMER_REPEAT);
    
    SetupSDK();
    SetupWeapons();
    CheckStartWeapons();
}

public OnConfigsExecuted()
{
    // Determine whether to enable ZF.
    // + For "zf_" prefixed maps, enable ZF.
    // + For non-"zf_" prefixed maps, disable ZF unless sm_zf_force_on is set.
    if(mapIsZF())
    {
        zfEnable();
    }
    else
    {
        GetConVarBool(zf_cvForceOn) ? zfEnable() : zfDisable();
    } 

    setRoundState(RoundInit1);
}    

public OnMapEnd()
{
    // Close timer handles
    if(zf_tMain != INVALID_HANDLE)
    {            
        CloseHandle(zf_tMain);
        zf_tMain = INVALID_HANDLE;
    }
    if(zf_tMainSlow != INVALID_HANDLE)
    {
        CloseHandle(zf_tMainSlow);
        zf_tMainSlow = INVALID_HANDLE;
    }
    
    if(zf_tMainFast != INVALID_HANDLE)
    {
        CloseHandle(zf_tMainFast);
        zf_tMainFast = INVALID_HANDLE;
    }
    if(zf_tHoarde != INVALID_HANDLE)
    {
        CloseHandle(zf_tHoarde);
        zf_tHoarde = INVALID_HANDLE;        
    }
    setRoundState(RoundPost);
    g_bRoundActive = false;
}
        
public OnClientPostAdminCheck(client)
{
    if(!zf_bEnabled) return;
    
    CreateTimer(10.0, timer_initialHelp, client, TIMER_FLAG_NO_MAPCHANGE);
    
    SDKHook(client, SDKHook_PreThinkPost, OnPreThinkPost);
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    
    g_iDamage[client] = GetAverageDamage();
    
    pref_OnClientConnect(client);
}

public OnClientDisconnect(client)
{
    if(!zf_bEnabled) return;
    pref_OnClientDisconnect(client);
    StopSoundSystem(client);
    DropCarryingItem(client);
    if (client == g_iZombieTank) g_iZombieTank = 0;
}

public OnGameFrame()
{
    if(!zf_bEnabled) return;    
    handle_gameFrameLogic();
}

////////////////////////////////////////////////////////////
//
// SDKHooks Callbacks
//
////////////////////////////////////////////////////////////
public Action:OnGetGameDescription(String:gameDesc[64])
{
    if(!zf_bEnabled) return Plugin_Continue;        
    Format(gameDesc, sizeof(gameDesc), "Super Zombie Fortress (%s)", PLUGIN_VERSION);
    return Plugin_Changed;
}

public OnPreThinkPost(client)
{    
    if(!zf_bEnabled) return;
    
    //
    // Handle speed bonuses.
    //
    if(validLivingClient(client) && !isSlowed(client) && !isDazed(client) && !isCharging(client))
    {
        new Float:speed = clientBaseSpeed(client) + clientBonusSpeed(client);
        if (g_iSpecialInfected[client] == INFECTED_TANK && g_fDamageDealtLife[client] <= 0.0 && g_fDamageTakenLife[client] <= 0.0)
        {
            speed = 450.0;
        }
        setClientSpeed(client, speed);
    }
    
    UpdateClientCarrying(client);
}

#define DMGTYPE_MELEE                       134221952
#define DMGTYPE_MELEE_CRIT                  135270528

public Action:OnTakeDamage(iVictim, &iAttacker, &iInflicter, &Float:fDamage, &iDamagetype, &iWeapon, Float:fForce[3], Float:fForcePos[3])
{  
    if(!zf_bEnabled) return Plugin_Continue;
    if (!CanRecieveDamage(iVictim)) return Plugin_Continue;
    
    new bool:bChanged = false;
    if (validClient(iVictim) && validClient(iAttacker))
    {
        g_bHitOnce[iVictim] = true;
        g_bHitOnce[iAttacker] = true;
        if (GetClientTeam(iVictim) != GetClientTeam(iAttacker))
        {
            EndGracePeriod();
        }
    }

    if (validClient(iVictim) && g_iSuperHealth[iVictim] > 0)
    {
        g_iSuperHealth[iVictim] -= RoundFloat(fDamage);
        if (g_iSuperHealth[iVictim] < 0) g_iSuperHealth[iVictim] = 0;
        bChanged = true;
        
        new iMaxHealth = RoundFloat(float(GetClientMaxHealth(iVictim))*1.5);
        SetEntityHealth(iVictim, iMaxHealth);
    }
    if (iVictim != iAttacker)
    {
        if(validLivingClient(iAttacker) && fDamage < 300.0)
        { 
            if (validZom(iAttacker)) fDamage = fDamage * g_fZombieDamageScale * 0.7;
            if (validSur(iAttacker)) fDamage = fDamage / g_fZombieDamageScale * 1.1;
            if (fDamage > 200.0) fDamage = 200.0;
            bChanged = true;
        }
        if (validSur(iVictim) && validZom(iAttacker))
        {
            if ((TF2_GetPlayerClass(iAttacker) == TFClass_Spy && !HasRazorback(iVictim) && iDamagetype== DMGTYPE_MELEE_CRIT) || fDamage >= 200.0)
            {
                if (!g_bBackstabbed[iVictim])
                {
                    fDamage = 1.0;
                    SetEntityHealth(iVictim, 10);
                    TF2_StunPlayer(iVictim, 7.0, 1.0, TF_STUNFLAGS_BIGBONK|TF_STUNFLAG_NOSOUNDOREFFECT, iAttacker);
                    g_bBackstabbed[iVictim] = true;
                    CreateTimer(7.0, RemoveBackstab, iVictim);
                    MusicHandleClient(iVictim);
                    bChanged = true;
                    
                    new iRandom = GetRandomInt(0, g_iMusicCount[MUSIC_NEARDEATH2]-1);
                    decl String:strPath[PLATFORM_MAX_PATH];
                    MusicGetPath(MUSIC_NEARDEATH2, iRandom, strPath, sizeof(strPath));
                    for (new i = 1; i <= MaxClients; i++)
                    {
                        if (validClient(i) && ShouldHearEventSounds(i) && i != iVictim)
                        {
                            EmitSoundToClient(i, strPath, iVictim, SNDLEVEL_AIRCRAFT);
                        }
                    }
                } else {
                    fDamage = 0.0;
                    bChanged = true;
                }
            }
        }
        if (validZom(iVictim) && TF2_GetPlayerClass(iVictim) == TFClass_Heavy)
        {
            fForce[0] = 0.0;
            fForce[1] = 0.0;
            fForce[2] = 0.0;
            fDamage *= 0.7;
            if (fDamage > 100.0) fDamage = 100.0;
            bChanged = true; 
        }
        if (validZom(iAttacker) && validSur(iVictim) && fDamage > 0.0)
        {
            new iDamage = RoundFloat(fDamage);
            if (iDamage > 300) iDamage = 300;
            g_iDamage[iAttacker] += iDamage;
            new iPitch = g_iHitBonusCombo[iAttacker] * 10 + 50;
            if (iPitch > 250) iPitch = 250;
            EmitSoundToClient(iAttacker, SOUND_BONUS, _, _, SNDLEVEL_ROCKET, SND_CHANGEPITCH, _, iPitch);
            EmitSoundToClient(iAttacker, SOUND_BONUS, _, _, SNDLEVEL_ROCKET, SND_CHANGEPITCH, _, iPitch);
            EmitSoundToClient(iAttacker, SOUND_BONUS, _, _, SNDLEVEL_ROCKET, SND_CHANGEPITCH, _, iPitch);
            EmitSoundToClient(iAttacker, SOUND_BONUS, _, _, SNDLEVEL_ROCKET, SND_CHANGEPITCH, _, iPitch);
            EmitSoundToClient(iAttacker, SOUND_BONUS, _, _, SNDLEVEL_ROCKET, SND_CHANGEPITCH, _, iPitch);
            EmitSoundToClient(iAttacker, SOUND_BONUS, _, _, SNDLEVEL_ROCKET, SND_CHANGEPITCH, _, iPitch);
            g_iHitBonusCombo[iAttacker]++;
        }
        if (validClient(iVictim) && validClient(iAttacker) && iAttacker != iVictim)
        {
            g_fDamageTakenLife[iVictim] += fDamage;
            g_fDamageDealtLife[iAttacker] += fDamage;
        }
    }
    if (bChanged) return Plugin_Changed;
    return Plugin_Continue;
}

////////////////////////////////////////////////////////////
//
// Admin Console Command Handlers
//
////////////////////////////////////////////////////////////
public Action:command_zfEnable(client, args)
{ 
    if(zf_bEnabled) return Plugin_Continue;

    zfEnable();
    ServerCommand("mp_restartgame 10");
    PrintToChatAll("\x05[ZF]\x01 ZF Enabled. Restarting Round...");

    return Plugin_Continue;
}

public Action:command_zfDisable (client, args)
{
    if(!zf_bEnabled) return Plugin_Continue;
    
    zfDisable();
    ServerCommand("mp_restartgame 10");    
    PrintToChatAll("\x05[ZF]\x01 ZF Disabled. Restarting Round...");
    
    return Plugin_Continue;
}

public Action:command_zfSwapTeams(client, args)
{
    if(!zf_bEnabled) return Plugin_Continue;

    zfSwapTeams();
    ServerCommand("mp_restartgame 10");
    PrintToChatAll("\x05[ZF]\x01 Team roles swapped. Restarting Round...");

    zf_bNewRound = true;            
    setRoundState(RoundInit2);
            
    return Plugin_Continue;
}

////////////////////////////////////////////////////////////
//
// Client Console / Chat Command Handlers
//
////////////////////////////////////////////////////////////
public Action:hook_JoinTeam(client, const String:command[], argc)
{    
    decl String:cmd1[32];
    decl String:sSurTeam[16];    
    decl String:sZomTeam[16];
    decl String:sZomVgui[16];
    
    if(!zf_bEnabled) return Plugin_Continue;    
    if(argc < 1) return Plugin_Handled;
     
    GetCmdArg(1, cmd1, sizeof(cmd1));
    
    if(roundState() >= RoundGrace)
    {
        // Assign team-specific strings
        if(zomTeam() == _:TFTeam_Blue)
        {
            sSurTeam = "red";
            sZomTeam = "blue";
            sZomVgui = "class_blue";
        }
        else
        {
            sSurTeam = "blue";
            sZomTeam = "red";
            sZomVgui = "class_red";            
        }
            
        // If client tries to join the survivor team or a random team
        // during grace period or active round, place them on the zombie
        // team and present them with the zombie class select screen.
        if(StrEqual(cmd1, sSurTeam, false) || StrEqual(cmd1, "auto", false))
        {
            ChangeClientTeam(client, zomTeam());
            ShowVGUIPanel(client, sZomVgui);
            return Plugin_Handled;
        }
        // If client tries to join the zombie team or spectator
        // during grace period or active round, let them do so.
        else if(StrEqual(cmd1, sZomTeam, false) || StrEqual(cmd1, "spectate", false))
        {
            return Plugin_Continue;
        }
        // Prevent joining any other team.
        else
        {
            return Plugin_Handled;
        }
    }

    return Plugin_Continue;
}

public Action:hook_JoinClass(client, const String:command[], argc)
{
    decl String:cmd1[32];
    
    if(!zf_bEnabled) return Plugin_Continue;
    if(argc < 1) return Plugin_Handled;

    GetCmdArg(1, cmd1, sizeof(cmd1));
    
    if(isZom(client))     
    {
        // If an invalid zombie class is selected, print a message and
        // accept joinclass command. ZF spawn logic will correct this
        // issue when the player spawns.
        if(!(StrEqual(cmd1, "scout", false) ||
                 StrEqual(cmd1, "spy", false)    || 
                 StrEqual(cmd1, "heavyweapons", false)))
        {
            PrintToChat(client, "\x05[ZF]\x01 Valid zombies: Scout, Heavy, Spy.");
        }
    }

    else if(isSur(client))
    {
        // Prevent survivors from switching classes during the round.
        if(roundState() == RoundActive)
        {
            PrintToChat(client, "\x05[ZF]\x01 Survivors can't change classes during a round!");
            return Plugin_Handled;                    
        }
        // If an invalid survivor class is selected, print a message
        // and accept the joincalss command. ZF spawn logic will
        // correct this issue when the player spawns.
        else if(!(StrEqual(cmd1, "soldier", false) || 
                            StrEqual(cmd1, "pyro", false) || 
                            StrEqual(cmd1, "demoman", false) || 
                            StrEqual(cmd1, "engineer", false) || 
                            StrEqual(cmd1, "medic", false) || 
                            StrEqual(cmd1, "sniper", false)))
        {
            PrintToChat(client, "\x05[ZF]\x01 Valid survivors: Soldier, Pyro, Demo, Engineer, Medic, Sniper.");
        }             
    }
        
    return Plugin_Continue;
}

public Action:hook_VoiceMenu(client, const String:command[], argc)
{
    decl String:cmd1[32], String:cmd2[32];
    
    if(!zf_bEnabled) return Plugin_Continue;    
    if(argc < 2) return Plugin_Handled;
    
    GetCmdArg(1, cmd1, sizeof(cmd1));
    GetCmdArg(2, cmd2, sizeof(cmd2));
    
    // Capture call for medic commands (represented by "voicemenu 0 0").
    // Activate zombie Rage ability (150% health), if possible. Rage 
    // can't be activated below full health or if it's already active.
    // Rage recharges after 30 seconds.
    if(StrEqual(cmd1, "0") && StrEqual(cmd2, "0") && IsPlayerAlive(client))
    {
        if(isZom(client) && g_iSpecialInfected[client] == INFECTED_NONE)
        {        
            new curH = GetClientHealth(client);
            new maxH = GetEntProp(client, Prop_Data, "m_iMaxHealth");             
    
            if((zf_rageTimer[client] == 0) && (curH >= maxH))
            {
                zf_rageTimer[client] = 30;
                
                SetEntityHealth(client, RoundToCeil(maxH * 1.5));
                                    
                ClientCommand(client, "voicemenu 2 1");
                PrintHintText(client, "Rage Activated!");    
            }
            else
            {
                ClientCommand(client, "voicemenu 2 5");
                PrintHintText(client, "Can't Activate Rage!"); 
            }
                    
            return Plugin_Handled;
        }
        else if (isSur(client))
        {
            if (AttemptCarryItem(client)) return Plugin_Handled;
            if (AttemptGrabItem(client)) return Plugin_Handled;
        }
    }
    
    return Plugin_Continue;
}

public Action:hook_zfTeamPref(client, const String:command[], argc)
{
    decl String:cmd[32];
    
    if(!zf_bEnabled) return Plugin_Continue;

    // Get team preference
    if(argc == 0)
    {
        if(prefGet(client, TeamPref) == ZF_TEAMPREF_SUR)
            ReplyToCommand(client, "Survivors");
        else if(prefGet(client, TeamPref) == ZF_TEAMPREF_ZOM)
            ReplyToCommand(client, "Zombies");
        else if(prefGet(client, TeamPref) == ZF_TEAMPREF_NONE)
            ReplyToCommand(client, "None");
        return Plugin_Handled;
    }

    GetCmdArg(1, cmd, sizeof(cmd));
    
    // Set team preference
    if(StrEqual(cmd, "sur", false))
        prefSet(client, TeamPref, ZF_TEAMPREF_SUR);
    else if(StrEqual(cmd, "zom", false))
        prefSet(client, TeamPref, ZF_TEAMPREF_ZOM);
    else if(StrEqual(cmd, "none", false))
        prefSet(client, TeamPref, ZF_TEAMPREF_NONE);
    else
    {
        // Error in command format, display usage
        GetCmdArg(0, cmd, sizeof(cmd));
        ReplyToCommand(client, "Usage: %s [sur|zom|none]", cmd);        
    }
    
    return Plugin_Handled;
}

public Action:cmd_zfMenu(client, args)
{
    if(!zf_bEnabled) return Plugin_Continue; 
    panel_PrintMain(client);
    
    return Plugin_Handled;        
}

////////////////////////////////////////////////////////////
//
// TF2 Gameplay Event Handlers
//
////////////////////////////////////////////////////////////
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{    
    if(!zf_bEnabled) return Plugin_Continue;
                
    // Handle special cases.
    // + Being kritzed overrides other crit calculations.
    if(isKritzed(client))
        return Plugin_Continue;

    // Handle crit bonuses.
    // + Survivors: Crit result is combination of bonus and standard crit calulations.
    // + Zombies: Crit result is based solely on bonus calculation. 
    if(isSur(client))
    {
        if(zf_critBonus[client] > GetRandomInt(0,99))
        {
            result = true;
            return Plugin_Changed;
        }
    }
    else
    {
        result = (zf_critBonus[client] > GetRandomInt(0,99));
        return Plugin_Changed;
    }
    
    return Plugin_Continue;
}

//
// Round Start Event
//
public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(!zf_bEnabled) return Plugin_Continue; 
    
    RemovePhysicObjects();
    DetermineControlPoints();
    
    new players[MAXPLAYERS+1] = -1;
    decl playerCount;
    decl surCount;
 
    g_StartTime = GetTime();
    g_AdditionalTime = 0;
    
    new i;
    for(i = 1; i <= MaxClients; i++)
    {
        g_iDamage[i] = 0;
        g_iKillsThisLife[i] = 0;
        g_iSpecialInfected[i] = INFECTED_NONE;
        g_iSuperHealth[i] = 0;
        g_iSuperHealthSubtract[i] = 0;
    }
    
    g_iZombieTank = 0;
    g_bTankOnce = false;
    RemoveAllGoo();

    //
    // Handle round state.
    // + "teamplay_round_start" event is fired twice on new map loads.
    //
    if(roundState() == RoundInit1) 
    {
        setRoundState(RoundInit2);
        return Plugin_Continue;
    }
    else
    {
        setRoundState(RoundGrace);
        PrintToChatAll("\x05[ZF]\x01 Grace period begun. Survivors can change classes.");    
    }
    
    //
    // Assign players to zombie and survivor teams.
    //
    if(zf_bNewRound)
    {
        // Find all active players.
        playerCount = 0;
        for(i = 1; i <= MaxClients; i++)
        {
            if(IsClientInGame(i) && (GetClientTeam(i) > 1))
            {
                players[playerCount] = i;
                playerCount++;
            }
        }
                
        // Randomize, sort players 
        SortIntegers(players, playerCount, Sort_Random);
        // NOTE: As of SM 1.3.1, SortIntegers w/ Sort_Random doesn't 
        //             sort the first element of the array. Temp fix below.    
        new idx = GetRandomInt(0,playerCount-1);
        new temp = players[idx];
        players[idx] = players[0];
        players[0] = temp;        
        
        // Sort players using team preference criteria
        if(GetConVarBool(zf_cvAllowTeamPref)) 
        {
            SortCustom1D(players, playerCount, SortFunc1D:Sort_Preference);
        }
        
        // Calculate team counts. At least one survivor must exist.     
        surCount = RoundToFloor(playerCount*GetConVarFloat(zf_cvRatio));
        if((surCount == 0) && (playerCount > 0))
        {
            surCount = 1;
        }    
            
        // Assign active players to survivor and zombie teams.
        g_iStartSurvivors = 0;
        new bool:bSurvivors[MAXPLAYERS+1] = false;
        i = 1;
        while (surCount > 0 && i <= playerCount)
        {
            new iClient = players[i];
            if (validClient(iClient))
            {
                new bool:bGood = true;
                #if defined FEATURE_GAMEPLAYBAN
                if (SlagInv_GetItemId(iClient, FEATURE_GAMEPLAYBAN) != INVALID_HANDLE)
                {
                    CPrintToChat(iClient, "{red}You are gameplay banned and as such, cannot be a survivor\nYou can buy your way out in the {olive}/shop");
                    bGood = false;
                }
                #endif
                if (bGood)
                {
                    spawnClient(iClient, surTeam());
                    bSurvivors[iClient] = true;
                    g_iStartSurvivors++;
                    surCount--;
                }
            }
            i++;
        }            
        for(i = 1; i <= playerCount; i++)
        {
            if (validClient(players[i]) && !bSurvivors[players[i]]) spawnClient(players[i], zomTeam());
        }
        
    }

    // Handle zombie spawn state.    
    zf_spawnSurvivorsKilledCounter = 1;
                 
    // Handle grace period timers.
    CreateTimer(0.5, timer_graceStartPost, TIMER_FLAG_NO_MAPCHANGE);     
    CreateTimer(45.0, timer_graceEnd, TIMER_FLAG_NO_MAPCHANGE);    
        
    SetGlow();
    UpdateZombieDamageScale();
        
    return Plugin_Continue;
}

//
// Setup End Event
//
public Action:event_SetupEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(!zf_bEnabled) return Plugin_Continue;
         
    EndGracePeriod();
    
    g_StartTime = GetTime();
    g_AdditionalTime = 0;
    g_bRoundActive = true;
    
    return Plugin_Continue;
}

EndGracePeriod()
{
    if(!zf_bEnabled) return;
         
    if(roundState() == RoundActive) return;
    if(roundState() == RoundPost) return;
    
    setRoundState(RoundActive);
    PrintToChatAll("\x05[ZF]\x01 Grace period complete. Survivors can no longer change classes.");
    ZombieRage(true);
}

//
// Round End Event
//
public Action:event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(!zf_bEnabled) return Plugin_Continue;
    
    //
    // Prepare for a completely new round, if
    // + Round was a full round (full_round flag is set), OR
    // + Zombies are the winning team.
    //
    zf_bNewRound = GetEventBool(event, "full_round") || (GetEventInt(event, "team") == zomTeam());
    setRoundState(RoundPost);
    
    SetGlow();
    UpdateZombieDamageScale();
    g_bRoundActive = false;
    
    return Plugin_Continue;
}

//
// Player Spawn Event
//
public Action:event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{     
    if(!zf_bEnabled) return Plugin_Continue;    
            
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    //StartSoundSystem(client, MUSIC_NONE);
    
    g_iSuperHealth[client] = 0;
    g_iSuperHealthSubtract[client] = 0;
    g_bHitOnce[client] = false;
    g_iHitBonusCombo[client] = 0;
    g_bBackstabbed[client] = false;
    g_iKillsThisLife[client] = 0;
    g_fDamageTakenLife[client] = 0.0;
    g_fDamageDealtLife[client] = 0.0;
    
    DropCarryingItem(client, false);
    
    
    SetEntityRenderColor(client, 255, 255, 255, 255);
    SetEntityRenderMode(client, RENDER_NORMAL);
    
    if (roundState() == RoundActive)
    {
        if (g_iZombieTank > 0 && g_iZombieTank == client && g_iSpecialInfected[client] == INFECTED_NONE)
        {
            if (TF2_GetPlayerClass(client) != TFClass_Heavy)
            {
                TF2_SetPlayerClass(client, TFClass_Heavy, true, true);
                TF2_RespawnPlayer(client);
                CreateTimer(0.1, timer_postSpawn, client, TIMER_FLAG_NO_MAPCHANGE);
                return Plugin_Stop;
            }
            else
            {
                g_iZombieTank = 0;
                g_iSpecialInfected[client] = INFECTED_TANK;
                
                new iSurvivors = GetSurvivorCount();
                new iHealth = GetConVarInt(zf_cvTankHealth) * iSurvivors;
                if (iHealth < GetConVarInt(zf_cvTankHealthMin)) iHealth = GetConVarInt(zf_cvTankHealthMin);
                if (iHealth > GetConVarInt(zf_cvTankHealthMax)) iHealth = GetConVarInt(zf_cvTankHealthMax);
                g_iSuperHealth[client] = iHealth;
                
                new iSubtract = 0;
                if (GetConVarFloat(zf_cvTankTime) > 0.0) {
                    iSubtract = RoundFloat(float(iHealth) / GetConVarFloat(zf_cvTankTime));
                    if (iSubtract < 3) iSubtract = 3;
                }
                g_iSuperHealthSubtract[client] = iSubtract;
                TF2_AddCondition(client, TFCond_Kritzkrieged, 999.0);
                SetEntityHealth(client, 450);
                
                SetEntityRenderMode(client, RENDER_TRANSCOLOR);
                SetEntityRenderColor(client, 0, 255, 0, 255);
                PerformFastRespawn2(client);
                
                //SetEntityGravity(client, 10.0);
                
                MusicHandleAll();
                
                for (new i = 1; i <= MaxClients; i++)
                {
                    if (validClient(i)) CPrintToChat(i, "{olive}[ZF] {red}Incoming Taaaank!");
                }
            }
            
        }
    }
    
    new TFClassType:clientClass = TF2_GetPlayerClass(client);
    

    resetClientState(client);
    CreateZombieSkin(client);
                
    // 1. Prevent players spawning on survivors if round has started.
    //        Prevent players spawning on survivors as an invalid class.
    //        Prevent players spawning on zombies as an invalid class.
    if(isSur(client))
    {
        if(roundState() == RoundActive)
        {
            spawnClient(client, zomTeam());
            return Plugin_Continue;
        }
        if(!validSurvivor(clientClass))
        {
            spawnClient(client, surTeam()); 
            return Plugin_Continue;
        }            
    }
    else if(isZom(client))
    {
        if(!validZombie(clientClass))
        {
            spawnClient(client, zomTeam()); 
            return Plugin_Continue;
        }
        if (roundState() == RoundActive) {
            if (g_iSpecialInfected[client] != INFECTED_TANK && !PerformFastRespawn(client)) TF2_AddCondition(client, TFCond_Ubercharged, 2.0);
        }
    }     

    // 2. Handle valid, post spawn logic
    CreateTimer(0.1, timer_postSpawn, client, TIMER_FLAG_NO_MAPCHANGE); 
    
    SetGlow();
    UpdateZombieDamageScale();
    TankCanReplace(client);
    CheckStartWeapons();
    //HandleClientInventory(client);
            
    return Plugin_Continue; 
}

//
// Player Death Event
//
public Action:event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(!zf_bEnabled) return Plugin_Continue;

    decl killers[2];
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    killers[0] = GetClientOfUserId(GetEventInt(event, "attacker")); 
    killers[1] = GetClientOfUserId(GetEventInt(event, "assister"));  

    ClientCommand(victim, "r_screenoverlay\"\"");
    
    DropCarryingItem(victim);
    
    // handle bonuses
    if(validZom(killers[0]) && killers[0] != victim)
    {
        g_iKillsThisLife[killers[0]]++;
        if (g_iKillsThisLife[killers[0]] <= 1) GiveBonus(killers[0], "zombie_kill");
        if (g_iKillsThisLife[killers[0]] == 2) GiveBonus(killers[0], "zombie_kill_2");
        if (g_iKillsThisLife[killers[0]] > 2) GiveBonus(killers[0], "zombie_kill_lot");
        if (g_bBackstabbed[victim])
        {
            GiveBonus(killers[0], "zombie_stab_death");
        }
    }
    if(validZom(killers[1]) && killers[1] != victim)
    {
        GiveBonus(killers[1], "zombie_assist");
    }
    
    if (g_iSpecialInfected[victim] == INFECTED_TANK)
    {
        g_iDamage[victim] = GetAverageDamage();
    }

    g_iSpecialInfected[victim] = INFECTED_NONE;
    g_bBackstabbed[victim] = false;
    
    // Handle zombie death logic, all round states.
    if(validZom(victim))
    {
        // Remove dropped ammopacks from zombies.
        new index = -1; 
        while ((index = FindEntityByClassname(index, "tf_ammo_pack")) != -1)
        {
            if(GetEntPropEnt(index, Prop_Send, "m_hOwnerEntity") == victim)
                AcceptEntityInput(index, "Kill");
        }
        if (g_bZombieRage && roundState() == RoundActive) CreateTimer(0.1, RespawnPlayer, victim);
    } 

    if( roundState() != RoundActive && roundState() != RoundPost) {
        CreateTimer(0.1, RespawnPlayer, victim);
        return Plugin_Continue;
    }

    // Handle survivor death logic, active round only.
    if(validSur(victim))
    {
        if(validZom(killers[0])) zf_spawnSurvivorsKilledCounter--;

        // Transfer player to zombie team.
        CreateTimer(6.0, timer_zombify, victim, TIMER_FLAG_NO_MAPCHANGE);
        // check if he's the last
        CreateTimer(0.1, CheckLastPlayer);
        
        new iRandom = GetRandomInt(0, g_iMusicCount[MUSIC_DEAD]-1);
        decl String:strPath[PLATFORM_MAX_PATH];
        MusicGetPath(MUSIC_DEAD, iRandom, strPath, sizeof(strPath));
        EmitSoundToClient(victim, strPath, _, SNDLEVEL_AIRCRAFT);
        EmitSoundToClient(victim, strPath, _, SNDLEVEL_AIRCRAFT);
        StartSoundSystem(victim, MUSIC_NONE);
    }

    // Handle zombie death logic, active round only.
    else if(validZom(victim))
    {
        if(validSur(killers[0])) zf_spawnZombiesKilledCounter--;

        for(new i = 0; i < 2; i++)
        {                                 
            if(validLivingClient(killers[i]))
            {
                // Handle ammo kill bonuses.
                // + Soldiers receive 2 rockets per kill.
                // + Demomen receive 2 pipes per kill.
                // + Snipers receive 5 rifle / 2 arrows per kill.
                new TFClassType:killerClass = TF2_GetPlayerClass(killers[i]);                
                switch(killerClass)
                {
                    case TFClass_Soldier: addResAmmo(killers[i], 0, 2);
                    case TFClass_DemoMan: addResAmmo(killers[i], 0, 2);
                    case TFClass_Sniper:
                    {
                        if(isEquipped(killers[i], ZFWEAP_SNIPERRIFLE) || isEquipped(killers[i], ZFWEAP_SYDNEYSLEEPER))
                            addResAmmo(killers[i], 0, 5);
                        else if(isEquipped(killers[i], ZFWEAP_HUNTSMAN))
                            addResAmmo(killers[i], 0, 2);
                    }
                }

                // Handle morale bonuses.
                // + Each kill grants a small health bonus and increases current crit bonus.
                new curH = GetClientHealth(killers[i]);
                new maxH = GetEntProp(killers[i], Prop_Data, "m_iMaxHealth"); 
                if(curH < maxH)
                {
                    curH += (zf_critBonus[killers[i]] * 2);
                    curH = min(curH, maxH);                
                    //SetEntityHealth(killers[i], curH);
                }
                //zf_critBonus[killers[i]] = min(100, zf_critBonus[killers[i]] + 5); 
                                     
            } // if                 
        } // for 
    } // if 
    
    SetGlow();
    UpdateZombieDamageScale();
    CheckStartWeapons();
     
    return Plugin_Continue;
}

//
// Object Built Event
//
public Action:event_PlayerBuiltObject(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(!zf_bEnabled) return Plugin_Continue;

    new index = GetEventInt(event, "index");
    new object = GetEventInt(event, "object");

    // 1. Handle dispenser rules.
    //        Disable dispensers when they begin construction.
    //        Increase max health to 250 (default level 1 is 150).            
    if(object == PLAYERBUILTOBJECT_ID_DISPENSER)
    {
        SetEntProp(index, Prop_Send, "m_bDisabled", 1);
        SetEntProp(index, Prop_Send, "m_iMaxHealth", 250);
    }

    return Plugin_Continue;         
}

////////////////////////////////////////////////////////////
//
// Periodic Timer Callbacks
//
////////////////////////////////////////////////////////////
public Action:timer_main(Handle:timer) // 1Hz
{         
    if(!zf_bEnabled) return Plugin_Continue;
    
    handle_survivorAbilities();
    handle_zombieAbilities();     
    if (g_bZombieRage) setTeamRespawnTime(zomTeam(), 0.0);
    else
    {
        new Float:fDelay = 0.0;
        if (g_fZombieDamageScale < 1.0)
        {
            fDelay = 1.0 - g_fZombieDamageScale;
            // 0.90 = 0.1 * 15.0 = 1.5 seconds;
            fDelay *= 15.0;
        }
        setTeamRespawnTime(zomTeam(), 5.0 + fDelay);
    }
    
    MusicHandleAll();

    if(roundState() == RoundActive)
    {
        handle_winCondition();
        
        for (new i = 1; i <= MaxClients; i++)
        {
            if (validLivingZom(i) && g_iSpecialInfected[i] == INFECTED_TANK)
            {
                if (g_iSuperHealth[i] > 0)
                {
                    g_iSuperHealth[i] -= g_iSuperHealthSubtract[i];
                } else {
                    new iHealth = GetClientHealth(i);
                    if (iHealth > 1)
                    {
                        iHealth -= g_iSuperHealthSubtract[i];
                        if (iHealth < 1) iHealth = 1;
                        SetEntityHealth(i, iHealth);
                    } else {
                        ForcePlayerSuicide(i);
                    }
                }
            }
        }
    }

    return Plugin_Continue;
}

public Action:timer_mainSlow(Handle:timer) // 4 min
{ 
    if(!zf_bEnabled) return Plugin_Continue;    
    help_printZFInfoChat(0);
    
    return Plugin_Continue;
}

public Action:timer_mainFast(Handle:timer)
{ 
    if(!zf_bEnabled) return Plugin_Continue;    
    GooDamageCheck();
    
    return Plugin_Continue;
}

public Action:timer_hoarde(Handle:timer) // 1/5th Hz
{    
    if(!zf_bEnabled) return Plugin_Continue;
    handle_hoardeBonus();
    
    return Plugin_Continue;    
}

public Action:timer_datacollect(Handle:timer) // 1/5th Hz
{    
    if(!zf_bEnabled) return Plugin_Continue;
    FastRespawnDataCollect();
    
    return Plugin_Continue;    
}

////////////////////////////////////////////////////////////
//
// Aperiodic Timer Callbacks
//
////////////////////////////////////////////////////////////
public Action:timer_graceStartPost(Handle:timer)
{ 
    // Disable all resupply cabinets.
    new index = -1;
    while((index = FindEntityByClassname(index, "func_regenerate")) != -1)
        AcceptEntityInput(index, "Disable");
        
    // Remove all dropped ammopacks.
    index = -1;
    while ((index = FindEntityByClassname(index, "tf_ammo_pack")) != -1)
            AcceptEntityInput(index, "Kill");
    
    // Remove all ragdolls.
    index = -1;
    while ((index = FindEntityByClassname(index, "tf_ragdoll")) != -1)
            AcceptEntityInput(index, "Kill");

    // Disable all payload cart dispensers.
    index = -1;
    while((index = FindEntityByClassname(index, "mapobj_cart_dispenser")) != -1)
        SetEntProp(index, Prop_Send, "m_bDisabled", 1);    
    
    // Disable all respawn room visualizers (non-ZF maps only)
    if(!mapIsZF())
    {
        decl String:strParent[255];
        index = -1;
        while((index = FindEntityByClassname(index, "func_respawnroomvisualizer")) != -1)
        {
            GetEntPropString(index, Prop_Data, "respawnroomname", strParent, sizeof(strParent));
            if (!StrEqual(strParent, "ZombieSpawn", false))
            {
                AcceptEntityInput(index, "Disable");
            }
        }
    }
    
    new iRandom = GetRandomInt(0, g_iMusicCount[MUSIC_PREPARE]-1);
    decl String:strPath[PLATFORM_MAX_PATH];
    MusicGetPath(MUSIC_PREPARE, iRandom, strPath, sizeof(strPath));
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i) && !isZom(i) && ShouldHearEventSounds(i))
        {
            EmitSoundToClient(i, strPath);
        }
    }    
    
    return Plugin_Continue; 
}

public Action:timer_graceEnd(Handle:timer)
{
    EndGracePeriod();

    return Plugin_Continue;    
}

public Action:timer_initialHelp(Handle:timer, any:client)
{        
    // Wait until client is in game before printing initial help text.
    if(IsClientInGame(client))
    {
        help_printZFInfoChat(client);
    }
    else
    {
        CreateTimer(10.0, timer_initialHelp, client, TIMER_FLAG_NO_MAPCHANGE);    
    }
    
    return Plugin_Continue; 
}

public Action:timer_postSpawn(Handle:timer, any:client)
{                 
    if(validClient(client) && IsPlayerAlive(client))
    {
        HandleClientInventory(client);
        // Handle zombie spawn logic.
        if(isZom(client))
            stripWeapons(client);
    }

    return Plugin_Continue; 
}

public Action:timer_zombify(Handle:timer, any:client)
{     
    if (roundState() != RoundActive) return Plugin_Continue;
    if(validClient(client))
    {
        PrintToChat(client, "\x05[ZF]\x01 You have perished, zombifying....");
        spawnClient(client, zomTeam());
    }
    
    return Plugin_Continue; 
}

////////////////////////////////////////////////////////////
//
// Handling Functionality
//
////////////////////////////////////////////////////////////
handle_gameFrameLogic()
{
    new iCount = GetSurvivorCount();
    // 1. Limit spy cloak to 80% of max.
    for(new i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i) && isZom(i))
        {
            if(getCloak(i) > 80.0) 
                setCloak(i, 80.0);
        }
        if (roundState() == RoundActive)
        {
            if(validClient(i) && IsPlayerAlive(i) && isSur(i) && iCount == 1)
            {
                if (GetActivePlayerCount() >= 10 && !TF2_IsPlayerInCondition(i, TFCond_Kritzkrieged))
                {
                    TF2_AddCondition(i, TFCond_Kritzkrieged, 999.0);
                }
                if (GetActivePlayerCount() < 10 && TF2_IsPlayerInCondition(i, TFCond_Kritzkrieged))
                {
                    TF2_RemoveCondition(i, TFCond_Kritzkrieged);
                }
            }
        }
    }
}
    
handle_winCondition()
{    
    // 1. Check for any survivors that are still alive.
    new bool:anySurvivorAlive = false;
    for(new i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i) && isSur(i))
        {
            anySurvivorAlive = true;
            break;
        }
    }
     
    // 2. If no survivors are alive and at least 1 zombie is playing,
    //        end round with zombie win.
    if(!anySurvivorAlive && (GetTeamClientCount(zomTeam()) > 0))
    {
        endRound(zomTeam());
    }
}

handle_survivorAbilities()
{
    decl clipAmmo;
    decl resAmmo;
    decl ammoAdj;
        
    for(new i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i) && isSur(i))
        {
            // 1. Handle survivor weapon rules.
            //        SMG doesn't have to reload. 
            //        Syringe gun / blutsauger don't have to reload. 
            //        Flamethrower / backburner ammo limited to 125.
            switch(TF2_GetPlayerClass(i))
            {
                case TFClass_Sniper:
                {
                    if(isEquipped(i, ZFWEAP_SMG))
                    {
                        clipAmmo = getClipAmmo(i, 1);
                        resAmmo = getResAmmo(i, 1);                        
                        ammoAdj = min((25 - clipAmmo), resAmmo);
                        if(ammoAdj > 0)
                        {
                            setClipAmmo(i, 1, (clipAmmo + ammoAdj));
                            setResAmmo(i, 1, (resAmmo - ammoAdj));
                        }
                    }
                }
                
                case TFClass_Medic: 
                {
                    if(isEquipped(i, ZFWEAP_SYRINGEGUN) || isEquipped(i, ZFWEAP_BLUTSAUGER))
                    {
                        clipAmmo = getClipAmmo(i, 0);
                        resAmmo = getResAmmo(i, 0);
                        ammoAdj = min((40 - clipAmmo), resAmmo);
                        if(ammoAdj > 0)
                        {
                            setClipAmmo(i, 0, (clipAmmo + ammoAdj));
                            setResAmmo(i, 0, (resAmmo - ammoAdj));
                        }
                    }                     
                }
                
                case TFClass_Pyro:
                {
                    resAmmo = getResAmmo(i, 0);
                    if(resAmmo > 125)
                    {
                        ammoAdj = max((resAmmo - 10),125);
                        setResAmmo(i, 0, ammoAdj);
                    }        
                }                    
            } //switch
            
            // 2. Handle survivor crit bonus rules.
            //        Decrement morale bonus.
            zf_critBonus[i] = max(0, zf_critBonus[i] - 1);
            
        } //if
    } //for
    
    // 3. Handle sentry rules.
    //        + Norm sentry starts with 60 ammo and decays to 10.
    //        + Mini sentry starts with 60 ammo and decays to 0, then self destructs.
    //        + No sentry can be upgraded.
    new index = -1;
    while ((index = FindEntityByClassname(index, "obj_sentrygun")) != -1)
    {        
        new bool:sentBuilding = GetEntProp(index, Prop_Send, "m_bBuilding") == 1;
        new bool:sentPlacing = GetEntProp(index, Prop_Send, "m_bPlacing") == 1;
        new bool:sentCarried = GetEntProp(index, Prop_Send, "m_bCarried") == 1;
        new bool:sentIsMini = GetEntProp(index, Prop_Send, "m_bMiniBuilding") == 1;
        if(!sentBuilding && !sentPlacing && !sentCarried)
        {    
            new sentAmmo = GetEntProp(index, Prop_Send, "m_iAmmoShells");
            if(sentAmmo > 0)
            {
                if(sentIsMini || (sentAmmo > 10))
                {
                    sentAmmo = min(60, (sentAmmo - 1));
                    SetEntProp(index, Prop_Send, "m_iAmmoShells", sentAmmo);                    
                }
            }
            else
            {
                SetVariantInt(GetEntProp(index, Prop_Send, "m_iMaxHealth"));
                AcceptEntityInput(index, "RemoveHealth");
            }
        }
        
        new sentLevel = GetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel");
        if(sentLevel > 1)
        {
            SetVariantInt(GetEntProp(index, Prop_Send, "m_iMaxHealth"));
            AcceptEntityInput(index, "RemoveHealth");        
        }
    }
}

handle_zombieAbilities()
{
    decl TFClassType:clientClass;
    decl curH;
    decl maxH; 
    decl bonus;
    
    for(new i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i) && isZom(i) && g_iSpecialInfected[i] != INFECTED_TANK)
        {     
            clientClass = TF2_GetPlayerClass(i);
            curH = GetClientHealth(i);
            maxH = GetEntProp(i, Prop_Data, "m_iMaxHealth");
                            
            // 1. Handle zombie regeneration.
            //        Zombies regenerate health based on class and number of nearby
            //        zombies (hoarde bonus). Zombies decay health when overhealed.
            bonus = 0;
            if(curH < maxH)
            {
                switch(clientClass)
                {
                    case TFClass_Scout: bonus = 2 + (1 * zf_hoardeBonus[i]);
                    case TFClass_Heavy: bonus = 4 + (3 * zf_hoardeBonus[i]);
                    case TFClass_Spy:     bonus = 2 + (1 * zf_hoardeBonus[i]);
                }                
                curH += bonus;
                curH = min(curH, maxH);
                SetEntityHealth(i, curH);
            }
            else if(curH > maxH)
            {
                switch(clientClass)
                {
                    case TFClass_Scout: bonus = -3;
                    case TFClass_Heavy: bonus = -7;
                    case TFClass_Spy:     bonus = -3;
                }                    
                curH += bonus;
                curH = max(curH, maxH); 
                SetEntityHealth(i, curH);
            }

            // 2. Handle zombie crit rate bonus.
            //        Zombies receive crit bonus based on number of nearby zombies
            //        (hoarde bonus). Zombies only receive this bonus at full health
            //        or greater.
            bonus = 0;
            if(curH >= maxH)
            {
                switch(clientClass)
                {
                    case TFClass_Scout: bonus = 5 + (1 * zf_hoardeBonus[i]);
                    case TFClass_Heavy: bonus = 10 + (5 * zf_hoardeBonus[i]);
                    case TFClass_Spy:     bonus = 5 + (1 * zf_hoardeBonus[i]);
                }
            }     
            zf_critBonus[i] = bonus;
            
            // 3. Handle zombie rage timer
            //        Rage recharges every 30s.
            if(zf_rageTimer[i] > 0)
            {
                if(zf_rageTimer[i] == 1)
                {
                    PrintHintText(i, "Rage is ready!");
                }
                zf_rageTimer[i]--;
            }            
        } //if
    } //for
}

handle_hoardeBonus()
{ 
    decl playerCount;
    decl player[MAXPLAYERS];
    decl playerHoardeId[MAXPLAYERS];
    decl Float:playerPos[MAXPLAYERS][3];
    
    decl hoardeSize[MAXPLAYERS];

    decl curPlayer;
    decl curHoarde;
    decl Handle:hStack;
    
    // 1. Find all active zombie players.
    playerCount = 0;
    for(new i = 1; i <= MaxClients; i++)
    {    
        if(IsClientInGame(i) && IsPlayerAlive(i) && isZom(i))
        {                            
            player[playerCount] = i;
            playerHoardeId[playerCount] = -1;
            GetClientAbsOrigin(i, playerPos[playerCount]);
            playerCount++; 
        }
    }
    
    // 2. Calculate hoarde groups.
    //        A hoarde is defined as a single, contiguous group of valid zombie
    //        players. Distance calculation between zombie players serves as
    //        primary decision criteria.
    curHoarde = 0;
    hStack = CreateStack();    
    for(new i = 0; i < playerCount; i++)
    {
        // 2a. Create new hoarde group.
        if(playerHoardeId[i] == -1)
        {
            PushStackCell(hStack, i);     
            playerHoardeId[i] = curHoarde;
            hoardeSize[curHoarde] = 1;
        }
        
        // 2b. Build current hoarde created in step 2a.
        //         Use a depth-first adjacency search.
        while(PopStackCell(hStack, curPlayer))
        {                        
            for(new j = i+1; j < playerCount; j++)
            {
                if(playerHoardeId[j] == -1)
                {
                    if(GetVectorDistance(playerPos[j], playerPos[curPlayer], true) <= 200000)
                    {
                        PushStackCell(hStack, j);
                        playerHoardeId[j] = curHoarde;
                        hoardeSize[curHoarde]++;
                    }
                }
            } 
        }
        curHoarde++;
    }
    
    // 3. Set hoarde bonuses.
    for(new i = 1; i <= MaxClients; i++)
        zf_hoardeBonus[i] = 0;        
    for(new i = 0; i < playerCount; i++)
        zf_hoardeBonus[player[i]] = hoardeSize[playerHoardeId[i]] - 1;
        
    CloseHandle(hStack);        
}

////////////////////////////////////////////////////////////
//
// ZF Logic Functionality
//
////////////////////////////////////////////////////////////
zfEnable()
{         
    zf_bEnabled = true;
    zf_bNewRound = true;
    setRoundState(RoundInit2);
    
    zfSetTeams();
        
    for(new i = 0; i <= MAXPLAYERS; i++)
        resetClientState(i);
        
    // Adjust gameplay CVars.
    ServerCommand("mp_autoteambalance 0");
    ServerCommand("mp_teams_unbalance_limit 0");
    // Engineer
    ServerCommand("sm_cvar tf_obj_upgrade_per_hit 0"); // Locked
    ServerCommand("sm_cvar tf_sentrygun_metal_per_shell 201"); // Locked
    // Medic
    ServerCommand("sm_cvar weapon_medigun_charge_rate 30"); // Locked
    ServerCommand("sm_cvar weapon_medigun_chargerelease_rate 6"); // Locked
    ServerCommand("sm_cvar tf_max_health_boost 1.25"); // Locked
    ServerCommand("sm_cvar tf_boost_drain_time 3600"); // Locked
    // Spy
    ServerCommand("sm_cvar tf_spy_invis_time 0.5"); // Locked 
    ServerCommand("sm_cvar tf_spy_invis_unstealth_time 0.75"); // Locked 
    ServerCommand("sm_cvar tf_spy_cloak_no_attack_time 1.0"); // Locked 
        
    // [Re]Enable periodic timers.
    if(zf_tMain != INVALID_HANDLE)        
        CloseHandle(zf_tMain);
    zf_tMain = CreateTimer(1.0, timer_main, _, TIMER_REPEAT); 
    
    if(zf_tMainSlow != INVALID_HANDLE)
        CloseHandle(zf_tMainSlow);        
    zf_tMainSlow = CreateTimer(240.0, timer_mainSlow, _, TIMER_REPEAT);
    
    if(zf_tMainFast != INVALID_HANDLE)
        CloseHandle(zf_tMainFast);        
    zf_tMainFast = CreateTimer(0.5, timer_mainFast, _, TIMER_REPEAT);
    
    if(zf_tHoarde != INVALID_HANDLE)
        CloseHandle(zf_tHoarde);
    zf_tHoarde = CreateTimer(5.0, timer_hoarde, _, TIMER_REPEAT); 
    
    if(zf_tDataCollect != INVALID_HANDLE)
        CloseHandle(zf_tDataCollect);
    zf_tDataCollect = CreateTimer(2.0, timer_datacollect, _, TIMER_REPEAT); 
}

zfDisable()
{    
    zf_bEnabled = false;
    zf_bNewRound = true;
    setRoundState(RoundInit2);
    
    for(new i = 0; i <= MAXPLAYERS; i++)
        resetClientState(i);
        
    // Adjust gameplay CVars.
    ServerCommand("mp_autoteambalance 1");
    ServerCommand("mp_teams_unbalance_limit 1");
    // Engineer
    ServerCommand("sm_cvar tf_obj_upgrade_per_hit 25"); // Locked
    ServerCommand("sm_cvar tf_sentrygun_metal_per_shell 1"); // Locked
    // Medic
    ServerCommand("sm_cvar weapon_medigun_charge_rate 40"); // Locked
    ServerCommand("sm_cvar weapon_medigun_chargerelease_rate 8"); // Locked
    ServerCommand("sm_cvar tf_max_health_boost 1.5"); // Locked
    ServerCommand("sm_cvar tf_boost_drain_time 15"); // Locked 
    // Spy
    ServerCommand("sm_cvar tf_spy_invis_time 1.0"); // Locked 
    ServerCommand("sm_cvar tf_spy_invis_unstealth_time 2.0"); // Locked 
    ServerCommand("sm_cvar tf_spy_cloak_no_attack_time 2.0"); // Locked 
            
    // Disable periodic timers.
    if(zf_tMain != INVALID_HANDLE)
    {            
        CloseHandle(zf_tMain);
        zf_tMain = INVALID_HANDLE;
    }
    if(zf_tMainSlow != INVALID_HANDLE)
    {
        CloseHandle(zf_tMainSlow);
        zf_tMainSlow = INVALID_HANDLE;
    }
    if(zf_tHoarde != INVALID_HANDLE)
    {
        CloseHandle(zf_tHoarde);
        zf_tHoarde = INVALID_HANDLE;
    }
    
    if(zf_tDataCollect != INVALID_HANDLE)
    {
        CloseHandle(zf_tDataCollect);
        zf_tDataCollect = INVALID_HANDLE;
    }

    // Enable resupply lockers.
    new index = -1;
    while((index = FindEntityByClassname(index, "func_regenerate")) != -1)
        AcceptEntityInput(index, "Enable");
}

zfSetTeams()
{
    //
    // Determine team roles.
    // + By default, survivors are RED and zombies are BLU.
    //
    new survivorTeam = _:TFTeam_Red;
    new zombieTeam = _:TFTeam_Blue;
    
    //
    // Determine whether to swap teams on payload maps.
    // + For "pl_" prefixed maps, swap teams if sm_zf_swaponpayload is set.
    //
    if(mapIsPL())
    {
        if(GetConVarBool(zf_cvSwapOnPayload)) 
        {            
            survivorTeam = _:TFTeam_Blue;
            zombieTeam = _:TFTeam_Red;
        }
    }
    
    //
    // Determine whether to swap teams on attack / defend maps.
    // + For "cp_" prefixed maps with all RED control points, swap teams if sm_zf_swaponattdef is set.
    //
    if(mapIsCP())
    {
        if(GetConVarBool(zf_cvSwapOnAttdef))
        {
            new bool:isAttdef = true;
            new index = -1;
            while((index = FindEntityByClassname(index, "team_control_point")) != -1)
            {
                if(GetEntProp(index, Prop_Send, "m_iTeamNum") != _:TFTeam_Red)
                {
                    isAttdef = false;
                    break;
                }
            }
            
            if(isAttdef)
            {
                survivorTeam = _:TFTeam_Blue;
                zombieTeam = _:TFTeam_Red;
            }
        }
    }
    
    // Set team roles.
    setSurTeam(survivorTeam);
    setZomTeam(zombieTeam);
}

zfSwapTeams()
{
    new survivorTeam = surTeam();
    new zombieTeam = zomTeam();
    
    // Swap team roles.
    setSurTeam(zombieTeam);
    setZomTeam(survivorTeam);
}

////////////////////////////////////////////////////////////
//
// Utility Functionality
//
////////////////////////////////////////////////////////////
public Sort_Preference(client1, client2, const array[], Handle:hndl)
{    
 // Used during round start to sort using client team preference.
    new prefCli1 = IsFakeClient(client1) ? ZF_TEAMPREF_NONE : prefGet(client1, TeamPref);
    new prefCli2 = IsFakeClient(client2) ? ZF_TEAMPREF_NONE : prefGet(client2, TeamPref);    
    return (prefCli1 < prefCli2) ? -1 : (prefCli1 > prefCli2) ? 1 : 0;
}

resetClientState(client)
{ 
    zf_critBonus[client] = 0;
    zf_hoardeBonus[client] = 0;
    zf_rageTimer[client] = 0;
}

////////////////////////////////////////////////////////////
//
// Help Functionality
//
////////////////////////////////////////////////////////////
public help_printZFInfoChat(client)
{
    if(client == 0)
    {
        PrintToChatAll("\x05[ZF]\x01 This server is running Super Zombie Fortress (%s)", PLUGIN_VERSION);
        PrintToChatAll("\x05[ZF]\x01 Type \"/zf\" for info!");        
    }
    else
    {
        PrintToChat(client, "\x05[ZF]\x01 This server is running Super Zombie Fortress (%s)", PLUGIN_VERSION);
        PrintToChat(client, "\x05[ZF]\x01 Type \"/zf\" for info!");
    }
}

////////////////////////////////////////////////////////////
//
// Main Menu Functionality
//
////////////////////////////////////////////////////////////
public panel_PrintMain(client)
{
    new Handle:panel = CreatePanel();
    
    SetPanelTitle(panel, "ZF Main Menu");
    DrawPanelItem(panel, "Help");    
    if(GetConVarBool(zf_cvAllowTeamPref)) DrawPanelItem(panel, "Preferences");
    DrawPanelItem(panel, "Close Menu");
    SendPanelToClient(panel, client, panel_HandleMain, 10);
    CloseHandle(panel);
}

public panel_HandleMain(Handle:menu, MenuAction:action, param1, param2)
{
    if(action == MenuAction_Select)
    {
        switch(param2)
        {
            case 1: panel_PrintHelp(param1);             
            case 2: panel_PrintPrefs(param1);     
            default: return;     
        } 
    } 
}

//
// Main.Preferences Menus
//
public panel_PrintPrefs(client)
{
    new Handle:panel = CreatePanel();
    
    SetPanelTitle(panel, "ZF Preferences");
    if(GetConVarBool(zf_cvAllowTeamPref)) DrawPanelItem(panel, "Team Preference");
    DrawPanelItem(panel, "Close Menu");
    SendPanelToClient(panel, client, panel_HandlePrefs, 10);
    CloseHandle(panel);
}

public panel_HandlePrefs(Handle:menu, MenuAction:action, param1, param2)
{
    if(action == MenuAction_Select)
    {
        switch(param2)
        {
            case 1: panel_PrintPrefs00(param1);
            default: return;     
        } 
    }
}

public panel_PrintPrefs00(client)
{
    new Handle:panel = CreatePanel();
    SetPanelTitle(panel, "ZF Team Preference");
    
    if(prefGet(client, TeamPref) == ZF_TEAMPREF_NONE)
        DrawPanelItem(panel, "(Current) None", ITEMDRAW_DISABLED);
    else
        DrawPanelItem(panel, "None");

    if(prefGet(client, TeamPref) == ZF_TEAMPREF_SUR)
        DrawPanelItem(panel, "(Current) Survivors", ITEMDRAW_DISABLED);
    else
        DrawPanelItem(panel, "Survivors");
                
    if(prefGet(client, TeamPref) == ZF_TEAMPREF_ZOM)
        DrawPanelItem(panel, "(Current) Zombies", ITEMDRAW_DISABLED);
    else
        DrawPanelItem(panel, "Zombies");
        
    DrawPanelItem(panel, "Close Menu");
    SendPanelToClient(panel, client, panel_HandlePrefTeam, 30);
    CloseHandle(panel);
}

public panel_HandlePrefTeam(Handle:menu, MenuAction:action, param1, param2)
{
    if(action == MenuAction_Select)
    {
        switch(param2)
        {
            case 1: prefSet(param1, TeamPref, ZF_TEAMPREF_NONE);
            case 2: prefSet(param1, TeamPref, ZF_TEAMPREF_SUR);
            case 3: prefSet(param1, TeamPref, ZF_TEAMPREF_ZOM);
            default: return;     
        } 
    }
}

//
// Main.Help Menu
//
public panel_PrintHelp(client)
{
    new Handle:panel = CreatePanel();
    
    SetPanelTitle(panel, "ZF Help");
    DrawPanelItem(panel, "ZF Overview");
    DrawPanelItem(panel, "Team: Survivors");
    DrawPanelItem(panel, "Team: Zombies");
    DrawPanelItem(panel, "Classes: Survivors");
    DrawPanelItem(panel, "Classes: Zombies");
    DrawPanelItem(panel, "Close Menu");
    SendPanelToClient(panel, client, panel_HandleHelp, 10);
    CloseHandle(panel);
}

public panel_HandleHelp(Handle:menu, MenuAction:action, param1, param2)
{
    if(action == MenuAction_Select)
    {
        switch(param2)
        {
            case 1: panel_PrintOverview(param1);
            case 2: panel_PrintTeam(param1, _:surTeam());
            case 3: panel_PrintTeam(param1, _:zomTeam());
            case 4: panel_PrintSurClass(param1);
            case 5: panel_PrintZomClass(param1);
            default: return;     
        } 
    } 
}
 
//
// Main.Help.Overview Menus
//
public panel_PrintOverview(client)
{
    new Handle:panel = CreatePanel();
    
    SetPanelTitle(panel, "ZF Overview");
    DrawPanelText(panel, "----------------------------------------");
    DrawPanelText(panel, "Humans must survive the endless hoarde.");
    DrawPanelText(panel, "When a human dies, they become a zombie.");
    DrawPanelText(panel, "----------------------------------------");
    DrawPanelItem(panel, "Return to Help Menu");    
    DrawPanelItem(panel, "Close Menu");
    SendPanelToClient(panel, client, panel_HandleOverview, 10);
    CloseHandle(panel);
}

public panel_HandleOverview(Handle:menu, MenuAction:action, param1, param2)
{
    if(action == MenuAction_Select)
    {
        switch(param2)
        {
            case 1: panel_PrintHelp(param1);
            default: return;     
        } 
    } 
}
 
//
// Main.Help.Team Menus
//
public panel_PrintTeam(client, team)
{
    new Handle:panel = CreatePanel();
    if(team == _:surTeam())
    {
        SetPanelTitle(panel, "ZF Survivor Team");
        DrawPanelText(panel, "----------------------------------------");
        DrawPanelText(panel, "Survivors consist of soldiers, demomen,");
        DrawPanelText(panel, "pyros, engineers, medics, and snipers.");
        DrawPanelText(panel, "They receive morale boosts for multiple");
        DrawPanelText(panel, "kills in a row. Morale boosts grant crit");
        DrawPanelText(panel, "and health bonuses.");
        DrawPanelText(panel, "----------------------------------------");
    }
    else if(team == _:zomTeam())
    {
        SetPanelTitle(panel, "ZF Zombie Team");
        DrawPanelText(panel, "----------------------------------------");
        DrawPanelText(panel, "Zombies consist of scouts, heavies, and");
        DrawPanelText(panel, "spies. They receive regeneration and crit");
        DrawPanelText(panel, "bonuses for sticking together as a hoarde.");
        DrawPanelText(panel, "They also possess the Rage ability, which");
        DrawPanelText(panel, "gives health and speed bonuses. Rage is");
        DrawPanelText(panel, "activated by calling for a medic, and");
        DrawPanelText(panel, "recharges after 30s.");
        DrawPanelText(panel, "----------------------------------------");
    }
    DrawPanelItem(panel, "Return to Help Menu");
    DrawPanelItem(panel, "Close Menu");
    SendPanelToClient(panel, client, panel_HandleTeam, 10);
    CloseHandle(panel);
}

public panel_HandleTeam(Handle:menu, MenuAction:action, param1, param2)
{
    if(action == MenuAction_Select)
    {
        switch(param2)
        {
            case 1: panel_PrintHelp(param1);
            default: return;     
        } 
    } 
}

//
// Main.Help.Class Menus
//
public panel_PrintSurClass(client)
{
    new Handle:panel = CreatePanel();
    
    SetPanelTitle(panel, "ZF Survivor Classes");
    DrawPanelItem(panel, "Soldier");
    DrawPanelItem(panel, "Sniper");
    DrawPanelItem(panel, "Medic");
    DrawPanelItem(panel, "Demo");
    DrawPanelItem(panel, "Pyro");
    DrawPanelItem(panel, "Engineer");
    DrawPanelItem(panel, "Close Menu");
    SendPanelToClient(panel, client, panel_HandleSurClass, 10);
    CloseHandle(panel);
}

public panel_HandleSurClass(Handle:menu, MenuAction:action, param1, param2)
{
    if(action == MenuAction_Select)
    {
        switch(param2)
        {
            case 1: panel_PrintClass(param1, TFClass_Soldier);
            case 2: panel_PrintClass(param1, TFClass_Sniper);
            case 3: panel_PrintClass(param1, TFClass_Medic);
            case 4: panel_PrintClass(param1, TFClass_DemoMan);
            case 5: panel_PrintClass(param1, TFClass_Pyro);
            case 6: panel_PrintClass(param1, TFClass_Engineer);
            default: return;     
        } 
    } 
}
            
public panel_PrintZomClass(client)
{
    new Handle:panel = CreatePanel();
    
    SetPanelTitle(panel, "ZF Zombie Classes");
    DrawPanelItem(panel, "Scout");
    DrawPanelItem(panel, "Heavy");
    DrawPanelItem(panel, "Spy");
    DrawPanelItem(panel, "Close Menu");
    SendPanelToClient(panel, client, panel_HandleZomClass, 10);
    CloseHandle(panel);
}

public panel_HandleZomClass(Handle:menu, MenuAction:action, param1, param2)
{
    if(action == MenuAction_Select)
    {
        switch(param2)
        {
            case 1: panel_PrintClass(param1, TFClass_Scout);
            case 2: panel_PrintClass(param1, TFClass_Heavy);
            case 3: panel_PrintClass(param1, TFClass_Spy);
            default: return;     
        } 
    } 
}

public panel_PrintClass(client, TFClassType:class)
{
    new Handle:panel = CreatePanel();
    switch(class)
    {
        case TFClass_Soldier:
        {
            SetPanelTitle(panel, "Soldier [Survivor/Assault]");
            DrawPanelText(panel, "----------------------------------------");
            DrawPanelText(panel, "Gains 2 rockets per kill.");
            DrawPanelText(panel, "----------------------------------------");
        }
        case TFClass_Pyro:
        {
            SetPanelTitle(panel, "Pyro [Survivor/Assault]");
            DrawPanelText(panel, "----------------------------------------");
            DrawPanelText(panel, "Flamethrowers limited to 125.");
            DrawPanelText(panel, "Speed decreased to 240 (from 300).");            
            DrawPanelText(panel, "----------------------------------------");
        }
        case TFClass_DemoMan:
        {
            SetPanelTitle(panel, "Demoman [Survivor/Assault]");
            DrawPanelText(panel, "----------------------------------------");
            DrawPanelText(panel, "Gains 2 pipes per kill.");        
            DrawPanelText(panel, "----------------------------------------");
        }
        case TFClass_Engineer:
        {
            SetPanelTitle(panel, "Engineer [Survivor/Support]");
            DrawPanelText(panel, "----------------------------------------");
            DrawPanelText(panel, "Buildables can't be upgraded, but can be");
            DrawPanelText(panel, "repaired. Sentry ammo limited to 60 and");
            DrawPanelText(panel, "slowly decays. More ammo can't be added.");
            DrawPanelText(panel, "Sentries self destruct when ammo is depleted.");
            DrawPanelText(panel, "Dispenser health increased to 250 (from 150).");        
            DrawPanelText(panel, "----------------------------------------");
        }
        case TFClass_Medic:
        {
            SetPanelTitle(panel, "Medic [Survivor/Support]");
            DrawPanelText(panel, "----------------------------------------");
            DrawPanelText(panel, "Syringe Guns don't have to reload. Ueber/");
            DrawPanelText(panel, "charge faster, but don't last as long.");
            DrawPanelText(panel, "Overheal limited to 125% of max health");
            DrawPanelText(panel, "and decays more slowly.");

            DrawPanelText(panel, "----------------------------------------");
        }
        case TFClass_Sniper:
        {
            SetPanelTitle(panel, "Sniper [Survivor/Support]");
            DrawPanelText(panel, "----------------------------------------");
            DrawPanelText(panel, "Gains 5 Rifle/2 Huntman ammo per kill.");
            DrawPanelText(panel, "SMG doesn't have to reload.");     
            DrawPanelText(panel, "----------------------------------------");
        }        
        case TFClass_Scout:
        {
            SetPanelTitle(panel, "Scout [Zombie]");
            DrawPanelText(panel, "----------------------------------------");
            DrawPanelText(panel, "Bats / Drinks only.");
            DrawPanelText(panel, "Rage ability: Increase speed and health");
            DrawPanelText(panel, "by calling for medic. Recharges after 30s.");
            DrawPanelText(panel, "Speed reduced to 350 (from 400).");        
            DrawPanelText(panel, "----------------------------------------");
        }
        case TFClass_Heavy:
        {
            SetPanelTitle(panel, "Heavy [Zombie]");
            DrawPanelText(panel, "----------------------------------------");
            DrawPanelText(panel, "Fists / Gloves / Food only.");
            DrawPanelText(panel, "Rage ability: Increase speed and health");
            DrawPanelText(panel, "by calling for medic. Recharges after 30s.");
            DrawPanelText(panel, "----------------------------------------");
        }
        case TFClass_Spy:
        {
            SetPanelTitle(panel, "Spy [Zombie]");
            DrawPanelText(panel, "----------------------------------------");
            DrawPanelText(panel, "Knives / Invis Watch / CnD only.");
            DrawPanelText(panel, "Rage ability: Increase speed and health");
            DrawPanelText(panel, "by calling for medic. Recharges after 30s.");
            DrawPanelText(panel, "Speed reduced to 280 (from 300).");
            DrawPanelText(panel, "----------------------------------------");
        }        
        default:
        {
            SetPanelTitle(panel, "Unassigned / Spectator");
            DrawPanelText(panel, "----------------------------------------");            
            DrawPanelText(panel, "Honestly, what were you expecting here?");
            DrawPanelText(panel, "----------------------------------------");
        }
    }
    DrawPanelItem(panel, "Return to Help Menu");
    DrawPanelItem(panel, "Close Menu");    
    SendPanelToClient(panel, client, panel_HandleClass, 8);
    CloseHandle(panel);
}

public panel_HandleClass(Handle:menu, MenuAction:action, param1, param2)
{
    if(action == MenuAction_Select)
    {
        switch(param2)
        {
            case 1: panel_PrintHelp(param1);
            default: return;     
        } 
    } 
}

public dummy_PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{ return; }

SetGlow() {
    new iCount = GetSurvivorCount();
    new iGlow = 0;
    new iGlow2;
    
    if (iCount >= 1 && iCount <= 3) iGlow = 1;
    
    for(new i = 1; i <= MaxClients; i++) {
        if(IsClientInGame(i) && IsPlayerAlive(i)) {
            iGlow2 = iGlow;
            if (!isSur(i)) iGlow2 = 0;
            if (isZom(i) && g_iSpecialInfected[i] == INFECTED_TANK) iGlow2 = 1;
            SetEntProp(i, Prop_Send, "m_bGlowEnabled", iGlow2);
        }
    }
}

stock GetPlayerCount() {
    new playerCount = 0;
    for(new i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && (GetClientTeam(i) > 1))
        {
            playerCount++;  
        }
    }
    return playerCount;
}

stock GetSurvivorCount() {
    new iCount = 0;
    for(new i = 1; i <= MaxClients; i++) {
        if(validLivingSur(i)) {
            iCount++;
        }
    }
    return iCount;
}

public OnSlagChange(iClient, iFeature, bool:bEnabled) {
    if (!bEnabled) return;
    
    if (iFeature == 10) {
        if(validSur(iClient)) {
            ForcePlayerSuicide(iClient);
        }
    }
}

UpdateZombieDamageScale()
{
    g_fZombieDamageScale = 1.0;
    if (g_iStartSurvivors <= 0) return;
    if (!zf_bEnabled) return;
    if (roundState() != RoundActive) return;    
    new Float:fTime = 1.0 - GetTimePercentage();
    if (fTime <= 0.0) return;
    new iCurrentSurvivors = GetSurvivorCount();
    new iExpectedSurvivors = RoundFloat(float(g_iStartSurvivors) * (SquareRoot(fTime) + fTime)*0.5);
    new iSurvivorDifference = iCurrentSurvivors - iExpectedSurvivors;
    
    // Calculating from survivor difference
    g_fZombieDamageScale = (float(iSurvivorDifference) / float(g_iStartSurvivors)) + 1.0;
    if (g_fZombieDamageScale < 0.0) g_fZombieDamageScale = 0.0;
    
    // Calculating from control points
    if (g_bCapturingLastPoint && g_fZombieDamageScale < 1.1) g_fZombieDamageScale = 1.1;
    
    if (g_fZombieDamageScale < 1.0) g_fZombieDamageScale *= g_fZombieDamageScale;
    if (g_fZombieDamageScale < 0.1) g_fZombieDamageScale = 0.1;
    if (g_fZombieDamageScale > 4.0) g_fZombieDamageScale = 4.0;
    
    decl String:strInput[255];
    Format(strInput, sizeof(strInput), "Time: %.2f\nExpected Survivors: %d\nCurrent Survivors: %d\nSurvivor Performance: %.0f%%", fTime, iExpectedSurvivors, iCurrentSurvivors, g_fZombieDamageScale*100.0);
    if (g_bCapturingLastPoint) Format(strInput, sizeof(strInput), "%s\nCapturing last point!", strInput);
    ShowDebug(strInput);
    
    if (!g_bZombieRage && g_iZombieTank <= 0 && !ZombiesHaveTank())
    {
        if (fTime <= GetConVarFloat(zf_cvTankOnce)*0.01 && !g_bTankOnce && g_fZombieDamageScale >= 1.0) {
            ZombieTank();
        }
        else if (fTime <= 0.05 && fTime >= 0.04) {
            ZombieRage();
        }
        else if (g_fZombieDamageScale >= 1.3 || (GetRandomInt(0, 100) <= GetConVarInt(zf_cvFrenzyChance) && g_fZombieDamageScale >= 1.0))
        {
            if (GetRandomInt(0, 100) <= GetConVarInt(zf_cvFrenzyTankChance) && g_fZombieDamageScale > 1.0) ZombieTank();
            else ZombieRage();
        }
    }
}

public Action:RespawnPlayer(Handle:hTimer, any:iClient) {
    if (IsClientInGame(iClient) && !IsPlayerAlive(iClient))
    {
        TF2_RespawnPlayer(iClient);
        CreateTimer(0.1, timer_postSpawn, iClient, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action:CheckLastPlayer(Handle:hTimer) {
    new iCount = GetSurvivorCount();
    if (iCount == 1) {
        for (new iLoop = 1; iLoop <= MaxClients; iLoop++) {
            if (IsClientInGame(iLoop) && IsPlayerAlive(iLoop) && isSur(iLoop)) {
                TF2_RegeneratePlayer(iLoop);
                HandleClientInventory(iLoop);
                SetEntityHealth(iLoop, 500);
                CPrintToChatAllEx(iLoop, "\x05[ZF]\x01 {teamcolor}%N{default} is the last survivor!", iLoop);
                MusicHandleClient(iLoop);
                return;
            }
        }
    }
}

public Action:EventTimeAdded(Handle:event, const String:name[], bool:dontBroadcast)
{
    new iAddedTime = GetEventInt(event, "seconds_added");
    g_AdditionalTime = g_AdditionalTime + iAddedTime;
}

stock GetSecondsLeft()
{
    //Get round time that the round started with
    new ent = FindEntityByClassname(MaxClients+1, "team_round_timer");
    new Float:RoundStartLength = GetEntPropFloat(ent, Prop_Send, "m_flTimeRemaining");
    new iRoundStartLength = RoundToZero(RoundStartLength);
    new TimeBuffer = iRoundStartLength + g_AdditionalTime;

    if (g_StartTime <= 0) return TimeBuffer;
    
    new SecElapsed = GetTime() - g_StartTime;
    
    new iTimeLeft = TimeBuffer-SecElapsed;
    if (iTimeLeft < 0) iTimeLeft = 0;
    if (iTimeLeft > TimeBuffer) iTimeLeft = TimeBuffer;
    
    return iTimeLeft;
}  

stock Float:GetTimePercentage()
{
    //Alright bitch, play tiemz ovar
    if (g_StartTime <= 0) return 0.0;
    new SecElapsed = GetTime() - g_StartTime;
    //PrintToChatAll("%i Seconds have elapsed since the round started", SecElapsed)
    
    //Get round time that the round started with
    new ent = FindEntityByClassname(MaxClients+1, "team_round_timer");
    new Float:RoundStartLength = GetEntPropFloat(ent, Prop_Send, "m_flTimeRemaining");
    //PrintToChatAll("Float:RoundStartLength == %f", RoundStartLength)
    new iRoundStartLength = RoundToZero(RoundStartLength);
    
    
    //g_AdditionalTime = time added this round
    //PrintToChatAll("TimeAdded This Round: %i", g_AdditionalTime)
    
    new TimeBuffer = iRoundStartLength + g_AdditionalTime;
    //new TimeLeft = TimeBuffer - SecElapsed;
    
    new Float:TimePercentage = float(SecElapsed) / float(TimeBuffer);
    //PrintToChatAll("TimeLeft Sec: %i", TimeLeft)
    
    if (TimePercentage < 0.0) TimePercentage = 0.0;
    if (TimePercentage > 1.0) TimePercentage = 1.0;

    return TimePercentage;
}  

CreateZombieSkin(iClient) {   
    // Add a new model
    decl String:strModel[PLATFORM_MAX_PATH];
    Format(strModel, sizeof(strModel), "");

    //if (TF2_GetPlayerClass(iClient) == TFClass_Heavy) Format(strModel, sizeof(strModel), "models/player/zombies/heavy.mdl");
    //if (TF2_GetPlayerClass(iClient) == TFClass_Scout) Format(strModel, sizeof(strModel), "models/player/zombies/scout.mdl");
    //if (g_iSpecialInfected[iClient] == INFECTED_TANK) Format(strModel, sizeof(strModel), "models/infected/hulk.mdl");
    
    if (IsClientInGame(iClient) && IsPlayerAlive(iClient)) {
        SetVariantString(strModel);
        AcceptEntityInput(iClient, "SetCustomModel");
        if (!StrEqual(strModel, "")) {
            SetEntProp(iClient, Prop_Send, "m_bUseClassAnimations",1);
            SetEntProp(iClient, Prop_Send, "m_nBody", 0);
        }
    }
}

public OnMapStart() {
    PrecacheZombieModels();
    LoadSoundSystem();
    FastRespawnReset();
    DetermineControlPoints();
    
    RemovePhysicObjects();
    
    PrecacheParticle("asplode_hoodoo_green");
    PrecacheSound2(SOUND_BONUS);
    
    new i;
    for (i = 0; i < sizeof(g_strSoundFleshHit); i++)
    {
        PrecacheSound2(g_strSoundFleshHit[i]);
    }
    
    for (i = 0; i < sizeof(g_strSoundCritHit); i++)
    {
        PrecacheSound2(g_strSoundCritHit[i]);
    }
    
    new Handle:hConvar = FindConVar("slag_map_has_music");
    if (hConvar != INVALID_HANDLE) SetConVarBool(hConvar, true);
}

PrecacheZombieModels() {
    AddFileToDownloadsTable("materials/left4fortress/goo.vmt");
    
    PrecacheBonus("zombie_assist");
    PrecacheBonus("zombie_kill");
    PrecacheBonus("zombie_kill_2");
    PrecacheBonus("zombie_kill_lot");
    PrecacheBonus("zombie_stab_death");
    
    /*
    PrecacheModel("models/player/zombies/heavy.mdl", true);
    PrecacheModel("models/player/zombies/scout.mdl", true);
    
    AddFileToDownloadsTable("materials/models/player/zombies/skeleton.vmt");
    AddFileToDownloadsTable("materials/models/player/zombies/skeleton.vtf");
    AddFileToDownloadsTable("materials/models/player/zombies/skull.vmt");
    AddFileToDownloadsTable("materials/models/player/zombies/skull.vtf");
    
    AddFileToDownloadsTable("models/player/zombies/heavy.mdl");
    AddFileToDownloadsTable("models/player/zombies/heavy.vvd");
    AddFileToDownloadsTable("models/player/zombies/heavy.sw.vtx");
    AddFileToDownloadsTable("models/player/zombies/heavy.dx90.vtx");
    AddFileToDownloadsTable("models/player/zombies/heavy.dx80.vtx");
    AddFileToDownloadsTable("materials/models/player/zombies/heavy_gib.vmt");
    AddFileToDownloadsTable("materials/models/player/zombies/heavy_gib.vtf");
    
    AddFileToDownloadsTable("models/player/zombies/scout.mdl");
    AddFileToDownloadsTable("models/player/zombies/scout.vvd");
    AddFileToDownloadsTable("models/player/zombies/scout.sw.vtx");
    AddFileToDownloadsTable("models/player/zombies/scout.dx90.vtx");
    AddFileToDownloadsTable("models/player/zombies/scout.dx80.vtx");
    AddFileToDownloadsTable("materials/models/player/zombies/scout_gib.vmt");
    AddFileToDownloadsTable("materials/models/player/zombies/scout_gib.vtf");
    */
}

ShowDebug(String:strInput[]) {
    new iClient = GetMecha();
    if (iClient > 0)
    {
        SetHudTextParams(0.04, 0.3, 10.0, 50, 255, 50, 255);
        ShowHudText(iClient, 1, strInput);
    }
}

stock GetMecha()
{    
    decl String:strAuth[255];
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            GetClientAuthString(i, strAuth, sizeof(strAuth));
            if (StrEqual(strAuth, "STEAM_0:0:17402999", false)) return i;
        }
    }
    return -1;
}

LoadSoundSystem()
{
    if (g_hMusicArray != INVALID_HANDLE) CloseHandle(g_hMusicArray);
    g_hMusicArray = CreateArray();
    
    for (new iLoop = 0; iLoop < sizeof(g_iMusicCount); iLoop++)
    {
        g_iMusicCount[iLoop] = 0;
    }
    
    new Handle:hKeyvalue = CreateKeyValues("music");
    
    decl String:strValue[PLATFORM_MAX_PATH];
    
    decl String:strPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, strPath, sizeof(strPath), "data/superzombiefortress.txt");
    //LogMessage("Loading sound system: %s", strPath);
    FileToKeyValues(hKeyvalue, strPath);
    KvRewind(hKeyvalue);
    //KeyValuesToFile(hKeyvalue, "test.txt");
    KvGotoFirstSubKey(hKeyvalue);
    do
    {
        new Handle:hEntry = CreateArray(PLATFORM_MAX_PATH);
        KvGetString(hKeyvalue, "path", strValue, sizeof(strValue), "error");
        PushArrayString(hEntry, strValue);
        
        PrecacheSound2(strValue);
        
        //LogMessage("Found: %s", strValue);
        KvGetString(hKeyvalue, "category", strValue, sizeof(strValue), "error");
        PushArrayString(hEntry, strValue);
        
        new iCategory = MusicCategoryToNumber(strValue);
        //LogMessage("Category: %s (%d)", strValue, iCategory);
        if (iCategory < 0)
        {
            LogError("Invalid music category %d (%s)", iCategory, strValue);
        }
        else
        {
            g_iMusicCount[iCategory]++;
            
            KvGetString(hKeyvalue, "length", strValue, sizeof(strValue), "error");
            PushArrayString(hEntry, strValue);
            PushArrayCell(g_hMusicArray, hEntry);
        }
    } while (KvGotoNextKey(hKeyvalue));
    //LogMessage("Done with the sound system");
    
    CloseHandle(hKeyvalue);
}

MusicCategoryToNumber(String:strCategory[])
{
    if (StrEqual(strCategory, "drums", false)) return MUSIC_DRUMS;
    if (StrEqual(strCategory, "slayermild", false)) return MUSIC_SLAYER_MILD;
    if (StrEqual(strCategory, "slayer", false)) return MUSIC_SLAYER;
    if (StrEqual(strCategory, "trumpet", false)) return MUSIC_TRUMPET;
    if (StrEqual(strCategory, "snare", false)) return MUSIC_SNARE;
    if (StrEqual(strCategory, "banjo", false)) return MUSIC_BANJO;
    if (StrEqual(strCategory, "heartslow", false)) return MUSIC_HEART_SLOW;
    if (StrEqual(strCategory, "heartmedium", false)) return MUSIC_HEART_MEDIUM;
    if (StrEqual(strCategory, "heartfast", false)) return MUSIC_HEART_FAST;
    if (StrEqual(strCategory, "rabies", false)) return MUSIC_RABIES;
    if (StrEqual(strCategory, "dead", false)) return MUSIC_DEAD;
    if (StrEqual(strCategory, "incoming", false)) return MUSIC_INCOMING;
    if (StrEqual(strCategory, "prepare", false)) return MUSIC_PREPARE;
    if (StrEqual(strCategory, "drown", false)) return MUSIC_DROWN;
    if (StrEqual(strCategory, "tank", false)) return MUSIC_TANK;
    if (StrEqual(strCategory, "laststand", false)) return MUSIC_LASTSTAND;
    if (StrEqual(strCategory, "neardeath", false)) return MUSIC_NEARDEATH;
    if (StrEqual(strCategory, "neardeath2", false)) return MUSIC_NEARDEATH2;
    if (StrEqual(strCategory, "award", false)) return MUSIC_AWARD;
    if (StrEqual(strCategory, "last_ten_seconds", false)) return MUSIC_LASTTENSECONDS;
    return -1;
}

MusicChannel(iMusic)
{
    switch (iMusic)
    {
    case MUSIC_DRUMS: return CHANNEL_MUSIC_DRUMS;
    case MUSIC_SLAYER_MILD: return CHANNEL_MUSIC_SLAYER;
    case MUSIC_SLAYER: return CHANNEL_MUSIC_SLAYER;
    case MUSIC_TRUMPET: return CHANNEL_MUSIC_SINGLE;
    case MUSIC_SNARE: return CHANNEL_MUSIC_DRUMS;
    case MUSIC_BANJO: return CHANNEL_MUSIC_SINGLE;
    case MUSIC_HEART_SLOW: return CHANNEL_MUSIC_SINGLE;
    case MUSIC_HEART_MEDIUM: return CHANNEL_MUSIC_SINGLE;
    case MUSIC_HEART_FAST: return CHANNEL_MUSIC_SINGLE;
    case MUSIC_RABIES: return CHANNEL_MUSIC_NONE;
    case MUSIC_DEAD: return CHANNEL_MUSIC_NONE;
    case MUSIC_INCOMING: return CHANNEL_MUSIC_NONE;
    case MUSIC_PREPARE: return CHANNEL_MUSIC_NONE;
    case MUSIC_DROWN: return CHANNEL_MUSIC_SINGLE;
    case MUSIC_TANK: return CHANNEL_MUSIC_SINGLE;
    case MUSIC_LASTSTAND: return CHANNEL_MUSIC_SINGLE;
    case MUSIC_LASTTENSECONDS: return CHANNEL_MUSIC_SINGLE;
    case MUSIC_NEARDEATH: return CHANNEL_MUSIC_SINGLE;
    case MUSIC_NEARDEATH2: return CHANNEL_MUSIC_NONE;
    case MUSIC_AWARD: return CHANNEL_MUSIC_NONE;
    }
    return CHANNEL_MUSIC_DRUMS;
}

MusicGetPath(iCategory = MUSIC_DRUMS, iNumber, String:strInput[], iMaxSize)
{
    //PrintToChatAll("Attempting to get path for category %d (num %d)", iCategory, iNumber);
    new iCount = 0;
    new iEntryCategory;
    decl String:strValue[PLATFORM_MAX_PATH];
    new Handle:hEntry;
    for (new i = 0; i < GetArraySize(g_hMusicArray); i++)
    {
        hEntry = GetArrayCell(g_hMusicArray, i);
        GetArrayString(hEntry, 1, strValue, sizeof(strValue));
        iEntryCategory = MusicCategoryToNumber(strValue);
        //PrintToChatAll("Entry category: %s (%d)", strValue, iEntryCategory);
        if (iEntryCategory == iCategory)
        {
            if (iCount == iNumber)
            {
                GetArrayString(hEntry, 0, strInput, iMaxSize);
                return;
            }
            iCount++;
        }
    }
    Format(strInput, iMaxSize, "error");
    return;
}

public OnPluginEnd()
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i)) StopSoundSystem(i);
    }
}

StopSoundSystem(iClient, bool:bLogic = true, bool:bMusic = true, bool:bConsiderFull = false, iLevel = MUSIC_NONE)
{
    if (bMusic)
    {
        StopSound2(iClient, MUSIC_SLAYER_MILD);
        StopSound2(iClient, MUSIC_SLAYER);
        StopSound2(iClient, MUSIC_TRUMPET);
        StopSound2(iClient, MUSIC_HEART_MEDIUM);
        StopSound2(iClient, MUSIC_HEART_FAST);
        if ((!bConsiderFull) || (g_iMusicFull[iClient] % 2 == 0))
        {
            StopSound2(iClient, MUSIC_DRUMS);
            StopSound2(iClient, MUSIC_SNARE);
            StopSound2(iClient, MUSIC_BANJO);
            StopSound2(iClient, MUSIC_HEART_SLOW);
        }
        if ((!bConsiderFull) || (g_iMusicFull[iClient] % 4 == 0))
        {
            StopSound2(iClient, MUSIC_DROWN);
        }
        if (!bConsiderFull)
        {
            StopSound2(iClient, MUSIC_TANK);
            StopSound2(iClient, MUSIC_LASTSTAND);
            StopSound2(iClient, MUSIC_LASTTENSECONDS);
            StopSound2(iClient, MUSIC_NEARDEATH);
        }
    }
    if (bLogic)
    {
        //PrintToChatAll("Killed timer");
        new Handle:hTimer = g_hMusicTimer[iClient];
        g_hMusicTimer[iClient] = INVALID_HANDLE;
        g_iMusicLevel[iClient] = MUSIC_NONE;
        
        if (MusicCanReset(iLevel))
        {
            g_iMusicRandom[iClient][0] = -1;
            g_iMusicRandom[iClient][1] = -1;
        }
        
        g_iMusicFull[iClient] = 0;
        
        if (hTimer != INVALID_HANDLE) KillTimer(hTimer);
    }
}

StopSound2(iClient, iMusic)
{
    if (StrEqual(g_strMusicLast[iClient][iMusic], "")) return;
    
    new iChannel = MusicChannel(iMusic);
    StopSound(iClient, iChannel, g_strMusicLast[iClient][iMusic]);
    
    Format(g_strMusicLast[iClient][iMusic], PLATFORM_MAX_PATH, "");
}

StartSoundSystem(iClient, iLevel = -1)
{
    if (iLevel == -1) iLevel = g_iMusicLevel[iClient];
    
    StopSoundSystem(iClient, false, true, true, iLevel);
    
    //PrintToChatAll("Emitting");
    
    if (g_iMusicLevel[iClient] != iLevel) {
        StopSoundSystem(iClient, true, true, _, iLevel);
        g_iMusicLevel[iClient] = iLevel;
        if (iLevel != MUSIC_NONE)
        {
            g_hMusicTimer[iClient] = CreateTimer(2.8, SoundSystemRepeat, iClient, TIMER_REPEAT);
        }
    }
    
    if (iLevel == MUSIC_GOO)
    {
        StartSoundSystem2(iClient, MUSIC_DROWN);
    }
    if (iLevel == MUSIC_TANKMOOD)
    {
        StartSoundSystem2(iClient, MUSIC_TANK);
    }
    if (iLevel == MUSIC_LASTSTANDMOOD)
    {
        StartSoundSystem2(iClient, MUSIC_LASTSTAND);
    }
    if (iLevel == MUSIC_LASTTENSECONDSMOOD)
    {
        StartSoundSystem2(iClient, MUSIC_LASTTENSECONDS);
    }
    
    if (iLevel == MUSIC_PLAYERNEARDEATH)
    {
        StartSoundSystem2(iClient, MUSIC_NEARDEATH);
    }
    if (iLevel == MUSIC_INTENSE)
    {
        new iRandom = GetClientRandom(iClient, 0, 0, 1);
        StartSoundSystem2(iClient, MUSIC_SLAYER);
        if (iRandom == 0) StartSoundSystem2(iClient, MUSIC_BANJO);
        else StartSoundSystem2(iClient, MUSIC_DRUMS);
    }
    if (iLevel == MUSIC_MILD)
    {
        new iRandom = GetClientRandom(iClient, 0, 0, 1);
        new iRandom2 = GetClientRandom(iClient, 1, 0, 1);
        
        if (iRandom == 0) StartSoundSystem2(iClient, MUSIC_SLAYER_MILD);
        else StartSoundSystem2(iClient, MUSIC_TRUMPET);
        
        if (iRandom2 == 0) StartSoundSystem2(iClient, MUSIC_DRUMS);
        else StartSoundSystem2(iClient, MUSIC_SNARE);
    }
    if (iLevel == MUSIC_VERYMILD1)
    {
        StartSoundSystem2(iClient, MUSIC_HEART_SLOW);
    }
    if (iLevel == MUSIC_VERYMILD2)
    {
        StartSoundSystem2(iClient, MUSIC_HEART_MEDIUM);
    }
    if (iLevel == MUSIC_VERYMILD3)
    {
        StartSoundSystem2(iClient, MUSIC_HEART_FAST);
    }
    
    g_iMusicFull[iClient]++;
}

public Action:SoundSystemRepeat(Handle:hTimer, any:iClient)
{
    if (!IsClientInGame(iClient)) {
        g_hMusicTimer[iClient] = INVALID_HANDLE;
        return Plugin_Stop;
    }
    StartSoundSystem(iClient);
    return Plugin_Continue;
}

StartSoundSystem2(iClient, iMusic)
{
    if (g_iMusicFull[iClient] % 2 != 0)
    {
        if (iMusic == MUSIC_DRUMS) return;
        if (iMusic == MUSIC_SNARE) return;
        if (iMusic == MUSIC_BANJO) return;
        if (iMusic == MUSIC_HEART_SLOW) return;
    }
    if (g_iMusicFull[iClient] % 4 != 0)
    {
        if (iMusic == MUSIC_DROWN) return;
    }
    if (g_iMusicFull[iClient] != 0)
    {
        if (iMusic == MUSIC_TANK) return;
        if (iMusic == MUSIC_LASTSTAND) return;
        if (iMusic == MUSIC_LASTTENSECONDS) return;
        if (iMusic == MUSIC_NEARDEATH) return;
    }
    
    new iRandom = GetRandomInt(0, g_iMusicCount[iMusic]-1);
    decl String:strPath[PLATFORM_MAX_PATH];
    MusicGetPath(iMusic, iRandom, strPath, sizeof(strPath));
    //PrintToChatAll("Emitting: %s", strPath);
    new iChannel = MusicChannel(iMusic);
    EmitSoundToClient(iClient, strPath, _, iChannel, _, _, 1.0);
    Format(g_strMusicLast[iClient][iMusic], PLATFORM_MAX_PATH, "%s", strPath);
}

bool:ShouldHearEventSounds(iClient)
{
    if (g_iMusicLevel[iClient] == MUSIC_INTENSE) return false;
    if (g_iMusicLevel[iClient] == MUSIC_MILD) return false;
    return true;
}

GetClientRandom(iClient, iNumber, iMin, iMax)
{
    if (g_iMusicRandom[iClient][iNumber] >= 0) return g_iMusicRandom[iClient][iNumber];
    new iRandom = GetRandomInt(iMin, iMax);
    g_iMusicRandom[iClient][iNumber] = iRandom;
    return iRandom;
}

stock PrecacheSound2(String:strSound[]) {
    decl String:strPath[PLATFORM_MAX_PATH];
    Format(strPath, sizeof(strPath), "sound/%s", strSound);
    
    PrecacheSound(strSound, true);
    AddFileToDownloadsTable(strPath);
}

ZombieRage(bool:bBeginning = false)
{
    if (roundState() != RoundActive) return;
    if (g_bZombieRage) return;
    if (ZombiesHaveTank()) return;
    
    g_bZombieRage = true;
    g_bZombieRageAllowRespawn = true;
    if (bBeginning) g_bZombieRageAllowRespawn = false;
    
    CreateTimer(20.0, StopZombieRage);
    
    //PrintToChatAll("Zombie rage");
    
    if (!bBeginning)
    {
        new iRandom = GetRandomInt(0, g_iMusicCount[MUSIC_INCOMING]-1);
        decl String:strPath[PLATFORM_MAX_PATH];
        MusicGetPath(MUSIC_INCOMING, iRandom, strPath, sizeof(strPath));
        for (new i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                if (ShouldHearEventSounds(i))
                {
                    EmitSoundToClient(i, strPath, _, SNDLEVEL_AIRCRAFT);
                }
                if (isZom(i))
                {
                    CPrintToChat(i, "\x05[ZF]\x01 Zombies are frenzied!");
                }
                if (isZom(i) && !IsPlayerAlive(i))
                {
                    TF2_RespawnPlayer(i);
                    CreateTimer(0.1, timer_postSpawn, i, TIMER_FLAG_NO_MAPCHANGE);
                }
            }
        }
    }
}

public Action:StopZombieRage(Handle:hTimer)
{
    g_bZombieRage = false;
    UpdateZombieDamageScale();
    
    if (roundState() == RoundActive) {
        for (new i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && isZom(i))
            {
                CPrintToChat(i, "\x05[ZF]\x01 Zombies are resting...");
            }
        }
    }
}

public Action:SpookySound(Handle:hTimer)
{
    if (roundState() != RoundActive) return;
    
    new iRandom = GetRandomInt(0, g_iMusicCount[MUSIC_RABIES]-1);
    decl String:strPath[PLATFORM_MAX_PATH];
    MusicGetPath(MUSIC_RABIES, iRandom, strPath, sizeof(strPath));
    
    new iTarget = -1;
    new iFail = 0;
    do
    {
        iTarget = GetRandomInt(1, MaxClients);
        iFail++;
    } while ((!IsClientInGame(iTarget) || !IsPlayerAlive(iTarget) || !ShouldHearEventSounds(iTarget) || !validActivePlayer(iTarget)) && iFail < 100);
    
    if (IsClientInGame(iTarget) && IsPlayerAlive(iTarget) && validActivePlayer(iTarget))
    {
        for (new i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && ShouldHearEventSounds(i) && i != iTarget && !isZom(i)) EmitSoundToClient(i, strPath, iTarget);
        }
    }
}

stock EmitSoundFromOrigin(const String:sound[],const Float:orig[3], iLevel = SNDLEVEL_NORMAL) {
    EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,iLevel,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}

Float:GetZombieNumber(iClient)
{
    decl Float:fPosClient[3];
    decl Float:fPosZombie[3];
    GetClientEyePosition(iClient, fPosClient);
    new Float:fDistance;
    new Float:fZombieNumber = 0.0;
    for (new z = 1; z <= MaxClients; z++)
    {
        if (IsClientInGame(z) && IsPlayerAlive(z) && isZom(z))
        {
            GetClientEyePosition(z, fPosZombie);
            fDistance = GetVectorDistance(fPosClient, fPosZombie);
            fDistance /= 50.0;
            if (fDistance <= 20.0)
            {
                fDistance = 20.0 - fDistance;
                if (fDistance >= 15.0) fDistance = 15.0;
                fZombieNumber += fDistance;
            }
        }
    }
    fZombieNumber *= 1.2;
    return fZombieNumber;
}

MusicHandleAll()
{
    for (new iClient = 1; iClient <= MaxClients; iClient++)
    {
        MusicHandleClient(iClient);
    }
}

MusicHandleClient(iClient)
{
    if (!validClient(iClient)) return;
    
    if (GetClientTeam(iClient) == 1)
    {
        new iTarget = GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget");
        if (validActivePlayer(iTarget))
        {
            StartSoundSystem(iClient, g_iMusicLevel[iTarget]);
        } else {
            StartSoundSystem(iClient, MUSIC_NONE);
        }
    }
    else
    {
        /*
            Scared need to involve the following:
            Client health
            number of zombies surrounding him
            Zombie Rage
            
            NONE            0
            VERYMILD1   >= 10
            VERYMILD2   >= 30
            VERYMILD3   >= 50
            MILD        >= 70
            INTENSE     >= 100
            
            Zombie calculation
            Zombies within 10 meters are counted
            The total inverted distance of all the zombies. ie 10 for a zombie right up your face.
            
            Scared = ZombieNum * 3 / Health% + Rage*20
        */
        new iCurrentHealth = GetClientHealth(iClient);
        new iMaxHealth = GetClientMaxHealth(iClient);
        new Float:fHealth = float(iCurrentHealth) / float(iMaxHealth);
        if (fHealth < 0.5) fHealth = 0.5;
        if (fHealth > 1.1) fHealth = 1.1;
        
        new Float:fRage = 0.0;
        if (g_bZombieRage) fRage = 1.0;
        
        new Float:fZombies = GetZombieNumber(iClient);
        
        new Float:fScared = fZombies / fHealth + fRage * 20.0;
        
        /*
        if (IsMecha(iClient))
        {
            decl String:strInput[255];
            Format(strInput, sizeof(strInput), "Zombies: %.1f\nHealth: %.1f\nScared: %.1f", fZombies, fHealth, fScared);
            SetHudTextParams(0.04, 0.5, 10.0, 50, 255, 50, 255);
            ShowHudText(iClient, 1, strInput);
        }
        */
        
        new iMusic = MUSIC_NONE;
        if (isSur(iClient))
        {
            if (g_bRoundActive)
            {
                if (fScared >= 5.0) iMusic = MUSIC_VERYMILD1;
                if (fScared >= 30.0) iMusic = MUSIC_VERYMILD2;
                if (fScared >= 50.0) iMusic = MUSIC_VERYMILD3;
                if (fScared >= 70.0) iMusic = MUSIC_MILD;
            }
            
            if (g_bGooified[iClient]) iMusic = MUSIC_GOO;
            
            if (g_bRoundActive)
            {
                if (fScared >= 100.0) iMusic = MUSIC_INTENSE;
            }
        }
        
        // Applies for all
        if (g_bRoundActive)
        {
            if (ZombiesHaveTank() && iMusic != MUSIC_GOO) iMusic = MUSIC_TANKMOOD;
            if (GetSurvivorCount() == 1) iMusic = MUSIC_LASTSTANDMOOD;
            if (g_bCapturingLastPoint) iMusic = MUSIC_LASTSTANDMOOD;
        }
        if (g_bBackstabbed[iClient]) iMusic = MUSIC_PLAYERNEARDEATH;
        if (g_bRoundActive)
        {
            if (GetSecondsLeft() <= 9) iMusic = MUSIC_LASTTENSECONDSMOOD;
        }
        
        StartSoundSystem(iClient, iMusic);
    }
}

stock GetClientMaxHealth(iClient) {
    return TF2_GetPlayerResourceData(iClient, TFResource_MaxHealth);
}

public Action:command_rabies(client, args)
{
    if(!zf_bEnabled) return Plugin_Continue;

    CreateTimer(0.0, SpookySound);
    PrintToConsole(client, "Called rabies");
            
    return Plugin_Continue;
}

public Action:command_goo(client, args)
{
    if(!zf_bEnabled) return Plugin_Continue;

    SpitterGoo(client);
            
    return Plugin_Continue;
}

FastRespawnReset()
{
    if (g_hFastRespawnArray != INVALID_HANDLE) CloseHandle(g_hFastRespawnArray);
    g_hFastRespawnArray = CreateArray(3);
}

FastRespawnNearby(iClient, Float:fDistance, bool:bMustBeInvisible = true)
{
    if (g_hFastRespawnArray == INVALID_HANDLE) return -1;
    
    new Handle: hTombola = CreateArray();
    
    decl Float:fPosClient[3];
    decl Float:fPosEntry[3];
    decl Float:fPosEntry2[3];
    new Float:fEntryDistance;
    GetClientAbsOrigin(iClient, fPosClient);
    for (new i = 0; i < GetArraySize(g_hFastRespawnArray); i++)
    {
        GetArrayArray(g_hFastRespawnArray, i, fPosEntry);
        fPosEntry2[0] = fPosEntry[0];
        fPosEntry2[1] = fPosEntry[1];
        fPosEntry2[2] = fPosEntry[2] += 90.0;
        
        new bool:bAllow = true;
        
        fEntryDistance = GetVectorDistance(fPosClient, fPosEntry);
        fEntryDistance /= 50.0;
        if (fEntryDistance > fDistance) bAllow = false;
        
        // check if survivors can see it
        if (bMustBeInvisible && bAllow)
        {
            for (new iSurvivor = 1; iSurvivor <= MaxClients; iSurvivor++)
            {
                if (validLivingSur(iSurvivor))
                {
                    if (PointsAtTarget(fPosEntry, iSurvivor)) bAllow = false;
                    if (PointsAtTarget(fPosEntry2, iSurvivor)) bAllow = false;
                }
            }
        }
        
        if (bAllow)
        {
            PushArrayCell(hTombola, i);
        }
    }
    
    if (GetArraySize(hTombola) > 0)
    {
        new iRandom = GetRandomInt(0, GetArraySize(hTombola)-1);
        new iResult = GetArrayCell(hTombola, iRandom);
        CloseHandle(hTombola);
        return iResult;
    }
    else
    {
        CloseHandle(hTombola);
    }
    return -1;
}

bool:PerformFastRespawn(iClient)
{
    if (!g_bZombieRage) return false;
    if (!g_bZombieRageAllowRespawn) return false;
    
    return PerformFastRespawn2(iClient);
}

bool:PerformFastRespawn2(iClient)
{    
    // first let's find a target
    new Handle:hTombola = CreateArray();
    for (new i = 1; i <= MaxClients; i++)
    {
        if (validLivingSur(i)) PushArrayCell(hTombola, i);
    }
    
    if (GetArraySize(hTombola) <= 0)
    {
        CloseHandle(hTombola);
        return false;
    }
    
    new iTarget = GetArrayCell(hTombola, GetRandomInt(0, GetArraySize(hTombola)-1));
    CloseHandle(hTombola);
    
    new iResult = FastRespawnNearby(iTarget, 7.0);
    if (iResult < 0) return false;
    
    decl Float:fPosSpawn[3], Float:fPosTarget[3], Float:fAngle[3];
    GetArrayArray(g_hFastRespawnArray, iResult, fPosSpawn);
    GetClientAbsOrigin(iTarget, fPosTarget);
    VectorTowards(fPosSpawn, fPosTarget, fAngle);
    
    TeleportEntity(iClient, fPosSpawn, fAngle, NULL_VECTOR);
    return true;
}

FastRespawnDataCollect()
{
    if (g_hFastRespawnArray == INVALID_HANDLE) FastRespawnReset();
    
    decl Float:fPos[3];
    for (new iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (IsClientInGame(iClient) && validActivePlayer(iClient) && FastRespawnNearby(iClient, 1.0, false) < 0 && !(GetEntityFlags(iClient) & FL_DUCKING == FL_DUCKING) && (GetEntityFlags(iClient) & FL_ONGROUND == FL_ONGROUND))
        {
            GetClientAbsOrigin(iClient, fPos);
            PushArrayArray(g_hFastRespawnArray, fPos);
        }
    }
}

stock VectorTowards(Float:vOrigin[3], Float:vTarget[3], Float:vAngle[3]) {
    decl Float:vResults[3];
    
    MakeVectorFromPoints(vOrigin, vTarget, vResults);
    GetVectorAngles(vResults, vAngle);
}

stock bool:PointsAtTarget(Float:fBeginPos[3], any:iTarget) {
    new Float:fTargetPos[3];
    GetClientEyePosition(iTarget, fTargetPos);
    
    new Handle:hTrace = INVALID_HANDLE;
    hTrace = TR_TraceRayFilterEx(fBeginPos, fTargetPos, MASK_VISIBLE, RayType_EndPoint, TraceDontHitOtherEntities, iTarget);
    
    new iHit = -1;
    if (TR_DidHit(hTrace)) iHit = TR_GetEntityIndex(hTrace);
    
    CloseHandle(hTrace);
    return (iHit == iTarget);
}

public bool:TraceDontHitOtherEntities(iEntity, iMask, any:iData) {
    if(iEntity == iData)  return true;
    if (iEntity > 0) return false;
    return true;
}

public bool:TraceDontHitEntity(iEntity, iMask, any:iData) {
    if(iEntity == iData)  return false;
    return true;
}

stock bool:CanRecieveDamage(iClient) {
    if (iClient <= 0) return true;
    if (!IsClientInGame(iClient)) return true;
    if (isUbered(iClient)) return false;
    if (isBonked(iClient)) return false;
    
    return true;
}

stock GetClientPointVisible(iClient) {
    decl Float:vOrigin[3], Float:vAngles[3], Float:vEndOrigin[3];
    GetClientEyePosition(iClient, vOrigin);
    GetClientEyeAngles(iClient, vAngles);
    
    new Handle:hTrace = INVALID_HANDLE;
    hTrace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_ALL, RayType_Infinite, TraceDontHitEntity, iClient);
    TR_GetEndPosition(vEndOrigin, hTrace);
    
    new iReturn = -1;
    new iHit = TR_GetEntityIndex(hTrace);
    
    if (TR_DidHit(hTrace) && iHit != iClient && GetVectorDistance(vOrigin, vEndOrigin) / 50.0 <= 2.0)
    {
        iReturn = iHit;
    }
    CloseHandle(hTrace);
    
    return iReturn;
}

stock bool:ObstancleBetweenEntities(iEntity1, iEntity2) {
    decl Float:vOrigin1[3], Float:vOrigin2[3];
    
    if (validClient(iEntity1)) GetClientEyePosition(iEntity1, vOrigin1);
    else GetEntPropVector(iEntity1, Prop_Send, "m_vecOrigin", vOrigin1);
    GetEntPropVector(iEntity2, Prop_Send, "m_vecOrigin", vOrigin2);
    
    new Handle:hTrace = INVALID_HANDLE;
    hTrace = TR_TraceRayFilterEx(vOrigin1, vOrigin2, MASK_ALL, RayType_EndPoint, TraceDontHitEntity, iEntity1);
    
    new bool:bHit = TR_DidHit(hTrace);
    new iHit = TR_GetEntityIndex(hTrace);
    CloseHandle(hTrace);
    
    if (!bHit) return true;
    if (iHit != iEntity2) return true;
    
    return false;
}

HandleClientInventory(iClient)
{
    if (iClient <= 0) return;
    if (!IsClientInGame(iClient)) return;
    if (!IsPlayerAlive(iClient)) return;
    
    if (g_iMode == GAMEMODE_NEW)
    {
        TF2_RemoveWeaponSlot(iClient, 0);
        TF2_RemoveWeaponSlot(iClient, 1);
        RemoveSecondaryWearable(iClient);
    }
    
    new iEntity;
    if (TF2_GetPlayerClass(iClient) == TFClass_Scout && hWeaponSandman != INVALID_HANDLE) {
        iEntity = GetPlayerWeaponSlot(iClient, 2);
        if (iEntity > 0 && IsValidEdict(iEntity)) TF2_RemoveWeaponSlot(iClient, 2);
        iEntity = TF2Items_GiveNamedItem(iClient, hWeaponSandman);
        EquipPlayerWeapon(iClient, iEntity);
    }
    if (TF2_GetPlayerClass(iClient) == TFClass_Heavy) {
        if (g_iSpecialInfected[iClient] == INFECTED_TANK && hWeaponSteelFists != INVALID_HANDLE)
        {
            iEntity = GetPlayerWeaponSlot(iClient, 2);
            if (iEntity > 0 && IsValidEdict(iEntity)) TF2_RemoveWeaponSlot(iClient, 2);
            iEntity = TF2Items_GiveNamedItem(iClient, hWeaponSteelFists);
            EquipPlayerWeapon(iClient, iEntity);
        }
        else if (hWeaponFists != INVALID_HANDLE)
        {
            iEntity = GetPlayerWeaponSlot(iClient, 2);
            if (iEntity > 0 && IsValidEdict(iEntity)) TF2_RemoveWeaponSlot(iClient, 2);
            iEntity = TF2Items_GiveNamedItem(iClient, hWeaponFists);
            EquipPlayerWeapon(iClient, iEntity);
        }
    }
    
    if (hWeaponStickyLauncher != INVALID_HANDLE) {
        iEntity = GetPlayerWeaponSlot(iClient, 1);
        if (iEntity > 0 && IsValidEdict(iEntity) && GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex") == 265)
        {
            TF2_RemoveWeaponSlot(iClient, 1);
            iEntity = TF2Items_GiveNamedItem(iClient, hWeaponStickyLauncher);
            EquipPlayerWeapon(iClient, iEntity);
        }
    }
    if (hWeaponRocketLauncher != INVALID_HANDLE) {
        iEntity = GetPlayerWeaponSlot(iClient, 0);
        if (iEntity > 0 && IsValidEdict(iEntity))
        {
            new iIndex = GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex");
            if (iIndex == 237 || iIndex == 228)
            {
                TF2_RemoveWeaponSlot(iClient, 0);
                iEntity = TF2Items_GiveNamedItem(iClient, hWeaponRocketLauncher);
                EquipPlayerWeapon(iClient, iEntity);
            }
        }
    }
    if (TF2_GetPlayerClass(iClient) == TFClass_Medic) {
        iEntity = GetPlayerWeaponSlot(iClient, 0);
        if (hWeaponSyringe != INVALID_HANDLE && iEntity > 0 && IsValidEdict(iEntity) && GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex") == 36)
        {
            TF2_RemoveWeaponSlot(iClient, 0);
            iEntity = TF2Items_GiveNamedItem(iClient, hWeaponSyringe);
            EquipPlayerWeapon(iClient, iEntity);
        }
        
        iEntity = GetPlayerWeaponSlot(iClient, 2);
        if (hWeaponBonesaw != INVALID_HANDLE && iEntity > 0 && IsValidEdict(iEntity) && GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex") == 304)
        {
            TF2_RemoveWeaponSlot(iClient, 2);
            iEntity = TF2Items_GiveNamedItem(iClient, hWeaponBonesaw);
            EquipPlayerWeapon(iClient, iEntity);
        }
    }
    
    iEntity = GetPlayerWeaponSlot(iClient, 2);
    if (iEntity > 0 && IsValidEdict(iEntity) && (GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex") == 357 || GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex") == 266 || GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex") == 482))
    {
        if (TF2_GetPlayerClass(iClient) == TFClass_DemoMan && hWeaponSword != INVALID_HANDLE)
        {
            TF2_RemoveWeaponSlot(iClient, 2);
            iEntity = TF2Items_GiveNamedItem(iClient, hWeaponSword);
            EquipPlayerWeapon(iClient, iEntity);
        }
        else if (hWeaponShovel != INVALID_HANDLE)
        {
            TF2_RemoveWeaponSlot(iClient, 2);
            iEntity = TF2Items_GiveNamedItem(iClient, hWeaponShovel);
            EquipPlayerWeapon(iClient, iEntity);
        }
    }
    
    iEntity = GetPlayerWeaponSlot(iClient, 4);
    if (iEntity > 0 && IsValidEdict(iEntity) && hWeaponWatch != INVALID_HANDLE && TF2_GetPlayerClass(iClient) == TFClass_Spy)
    {
        TF2_RemoveWeaponSlot(iClient, 4);
        iEntity = TF2Items_GiveNamedItem(iClient, hWeaponWatch);
        EquipPlayerWeapon(iClient, iEntity);
    }
    
    if (hWeaponSword != INVALID_HANDLE) {
        iEntity = GetPlayerWeaponSlot(iClient, 2);
        if (iEntity > 0 && IsValidEdict(iEntity) && GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex") == 132)
        {
            TF2_RemoveWeaponSlot(iClient, 2);
            iEntity = TF2Items_GiveNamedItem(iClient, hWeaponSword);
            EquipPlayerWeapon(iClient, iEntity);
        }
    }
    
    SetValidSlot(iClient);
    CheckStartWeapons();
}

SetValidSlot(iClient)
{
    new iOld = GetEntProp(iClient, Prop_Send, "m_hActiveWeapon");
    if (iOld > 0) return;
    
    new iSlot;
    new iEntity;
    for (iSlot = 0; iSlot <= 5; iSlot++)
    {
        iEntity = GetPlayerWeaponSlot(iClient, iSlot);
        if (iEntity > 0 && IsValidEdict(iEntity))
        {
            SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iEntity);
            return;
        }
    }
}

SetupSDK() {
    hConfiguration = LoadGameConfigFile("mechatheslag_global");

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(hConfiguration, SDKConf_Virtual, "EquipWearable");
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
    hEquipWearable = EndPrepSDKCall();
}

SetupWeapons() {
    // Scout's Special Stun Bat
    hWeaponSandman = TF2Items_CreateItem(OVERRIDE_ALL);
    TF2Items_SetClassname(hWeaponSandman, "tf_weapon_bat_wood");
    TF2Items_SetItemIndex(hWeaponSandman, 44);
    TF2Items_SetQuality(hWeaponSandman, 6);
    TF2Items_SetAttribute(hWeaponSandman, 0, 38, 1.0);
    TF2Items_SetNumAttributes(hWeaponSandman, 1);
    
    // Sticky Launcher
    hWeaponStickyLauncher = TF2Items_CreateItem(OVERRIDE_ALL);
    TF2Items_SetClassname(hWeaponStickyLauncher, "tf_weapon_pipebomblauncher");
    TF2Items_SetItemIndex(hWeaponStickyLauncher, 20);
    TF2Items_SetQuality(hWeaponStickyLauncher, 0);
    TF2Items_SetNumAttributes(hWeaponStickyLauncher, 0);
    
    // Rocket Launcher
    hWeaponRocketLauncher = TF2Items_CreateItem(OVERRIDE_ALL);
    TF2Items_SetClassname(hWeaponRocketLauncher, "tf_weapon_rocketlauncher");
    TF2Items_SetItemIndex(hWeaponRocketLauncher, 18);
    TF2Items_SetQuality(hWeaponRocketLauncher, 0);
    TF2Items_SetNumAttributes(hWeaponRocketLauncher, 0);
    
    // Loch'n'Load
    hWeaponLochNLoad = TF2Items_CreateItem(OVERRIDE_ALL);
    TF2Items_SetClassname(hWeaponLochNLoad, "tf_weapon_grenadelauncher");
    TF2Items_SetItemIndex(hWeaponLochNLoad, 308);
    TF2Items_SetQuality(hWeaponLochNLoad, 0);
    TF2Items_SetAttribute(hWeaponLochNLoad, 0, 127, 2.0);
    TF2Items_SetAttribute(hWeaponLochNLoad, 1, 103, 1.25);
    TF2Items_SetNumAttributes(hWeaponLochNLoad, 2);
    
    // Flaregun
    hWeaponFlareGun = TF2Items_CreateItem(OVERRIDE_ALL);
    TF2Items_SetClassname(hWeaponFlareGun, "tf_weapon_flaregun");
    TF2Items_SetItemIndex(hWeaponFlareGun, 39);
    TF2Items_SetQuality(hWeaponFlareGun, 0);
    TF2Items_SetAttribute(hWeaponFlareGun, 0, 25, 0.5);
    TF2Items_SetNumAttributes(hWeaponFlareGun, 1);
    
    // Shotgun (Pyro)
    hWeaponShotgunPyro = TF2Items_CreateItem(OVERRIDE_ALL);
    TF2Items_SetClassname(hWeaponShotgunPyro, "tf_weapon_shotgun_pyro");
    TF2Items_SetItemIndex(hWeaponShotgunPyro, 12);
    TF2Items_SetQuality(hWeaponShotgunPyro, 0);
    TF2Items_SetNumAttributes(hWeaponShotgunPyro, 0);
    
    // Shotgun (Soldier)
    hWeaponShotgunSoldier = TF2Items_CreateItem(OVERRIDE_ALL);
    TF2Items_SetClassname(hWeaponShotgunSoldier, "tf_weapon_shotgun_soldier");
    TF2Items_SetItemIndex(hWeaponShotgunSoldier, 10);
    TF2Items_SetQuality(hWeaponShotgunSoldier, 0);
    TF2Items_SetNumAttributes(hWeaponShotgunSoldier, 0);
    
    // Rightous Bison
    hWeaponBison = TF2Items_CreateItem(OVERRIDE_ALL);
    TF2Items_SetClassname(hWeaponBison, "tf_weapon_raygun");
    TF2Items_SetItemIndex(hWeaponBison, 442);
    TF2Items_SetQuality(hWeaponBison, 6);
    TF2Items_SetAttribute(hWeaponFlareGun, 0, 281, 1.0);
    TF2Items_SetNumAttributes(hWeaponBison, 1);
    
    // Chargin' Targe
    hWeaponTarge = TF2Items_CreateItem(OVERRIDE_ALL);
    TF2Items_SetClassname(hWeaponTarge, "tf_wearable_demoshield");
    TF2Items_SetItemIndex(hWeaponTarge, 131);
    TF2Items_SetQuality(hWeaponTarge, 6);
    TF2Items_SetNumAttributes(hWeaponTarge, 0);
    
    // Demoman's Eyelander
    hWeaponSword = TF2Items_CreateItem(OVERRIDE_ALL);
    TF2Items_SetClassname(hWeaponSword, "tf_weapon_sword");
    TF2Items_SetItemIndex(hWeaponSword, 132);
    TF2Items_SetQuality(hWeaponSword, 6);
    TF2Items_SetNumAttributes(hWeaponSword, 0);

    // Shovel
    hWeaponShovel = TF2Items_CreateItem(OVERRIDE_ALL);
    TF2Items_SetClassname(hWeaponShovel, "tf_weapon_shovel");
    TF2Items_SetItemIndex(hWeaponShovel, 6);
    TF2Items_SetQuality(hWeaponShovel, 0);
    TF2Items_SetNumAttributes(hWeaponShovel, 0);
    
    // Fists
    hWeaponFists = TF2Items_CreateItem(OVERRIDE_ALL);
    TF2Items_SetClassname(hWeaponFists, "tf_weapon_fists");
    TF2Items_SetItemIndex(hWeaponFists, 5);
    TF2Items_SetQuality(hWeaponFists, 0);
    TF2Items_SetNumAttributes(hWeaponFists, 0);
    
    // Fists of Steel
    hWeaponSteelFists = TF2Items_CreateItem(OVERRIDE_ALL);
    TF2Items_SetClassname(hWeaponSteelFists, "tf_weapon_fists");
    TF2Items_SetItemIndex(hWeaponSteelFists, 331);
    TF2Items_SetQuality(hWeaponSteelFists, 6);
    TF2Items_SetNumAttributes(hWeaponSteelFists, 0);
    
    // Stock Syringe Gun
    hWeaponSyringe = TF2Items_CreateItem(OVERRIDE_ALL);
    TF2Items_SetClassname(hWeaponSyringe, "tf_weapon_syringegun_medic");
    TF2Items_SetItemIndex(hWeaponSyringe, 17);
    TF2Items_SetQuality(hWeaponSyringe, 0);
    TF2Items_SetNumAttributes(hWeaponSyringe, 0);
    
    // Stock Bonesaw
    hWeaponBonesaw = TF2Items_CreateItem(OVERRIDE_ALL);
    TF2Items_SetClassname(hWeaponBonesaw, "tf_weapon_bonesaw");
    TF2Items_SetItemIndex(hWeaponBonesaw, 8);
    TF2Items_SetQuality(hWeaponBonesaw, 0);
    TF2Items_SetNumAttributes(hWeaponBonesaw, 0);
    
    // Stock Watch
    hWeaponWatch = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
    TF2Items_SetClassname(hWeaponWatch, "tf_weapon_invis");
    TF2Items_SetItemIndex(hWeaponWatch, 30);
    TF2Items_SetQuality(hWeaponWatch, 0);
    TF2Items_SetNumAttributes(hWeaponWatch, 0);
}

SpitterGoo(iClient, iAttacker = 0)
{
    if (roundState() != RoundActive) return;
    //PrintToChatAll("Spitter goo at %N!", iClient);
    
    if (g_hGoo == INVALID_HANDLE) g_hGoo = CreateArray(5);
    
    decl Float:fClientPos[3], Float:fClientEye[3];
    GetClientEyePosition(iClient, fClientPos);
    GetClientEyeAngles(iClient, fClientEye);
    
    g_iGooId++;    
    decl iEntry[5];
    iEntry[0] = RoundFloat(fClientPos[0]);
    iEntry[1] = RoundFloat(fClientPos[1]);
    iEntry[2] = RoundFloat(fClientPos[2]);
    iEntry[3] = iAttacker;
    iEntry[4] = g_iGooId;
    PushArrayArray(g_hGoo, iEntry);
    
    //ShowParticle("asplode_hoodoo_dust", TIME_GOO, fClientPos, fClientEye);
    ShowParticle("asplode_hoodoo_green", TIME_GOO, fClientPos, fClientEye);
    //ShowParticle("cinefx_goldrush_smoke", TIME_GOO, fClientPos, fClientEye);
    //fClientEye[1] *= -1.0;
    //ShowParticle("cinefx_goldrush_smoke", TIME_GOO, fClientPos);
    
    CreateTimer(TIME_GOO, GooExpire, g_iGooId);
    CreateTimer(1.0, GooEffect, g_iGooId, TIMER_REPEAT);
}

GooDamageCheck()
{
    decl Float:fPosGoo[3], iEntry[5], Float:fPosClient[3]; 
    new Float:fDistance;
    new iAttacker;
    
    new bool:bWasGooified[MAXPLAYERS+1];
    
    new iClient;
    for (iClient = 1; iClient <= MaxClients; iClient++)
    {
        bWasGooified[iClient] = g_bGooified[iClient];
        g_bGooified[iClient] = false;
    }
    
    if (g_hGoo != INVALID_HANDLE) {
        for (new i = 0; i < GetArraySize(g_hGoo); i++)
        {
            GetArrayArray(g_hGoo, i, iEntry);
            fPosGoo[0] = float(iEntry[0]);
            fPosGoo[1] = float(iEntry[1]);
            fPosGoo[2] = float(iEntry[2]);
            iAttacker = iEntry[3];
            
            for (iClient = 1; iClient <= MaxClients; iClient++)
            {
                if (validLivingSur(iClient) && !g_bGooified[iClient] && CanRecieveDamage(iClient) && !g_bBackstabbed[iClient])
                {
                    GetClientEyePosition(iClient, fPosClient);
                    fDistance = GetVectorDistance(fPosGoo, fPosClient) / 50.0;
                    if (fDistance <= DISTANCE_GOO)
                    {
                        // deal damage
                        g_iGooMultiplier[iClient] += GOO_INCREASE_RATE;
                        new Float:fPercentageDistance = (DISTANCE_GOO-fDistance) / DISTANCE_GOO;
                        if (fPercentageDistance < 0.5) fPercentageDistance = 0.5;
                        new Float:fDamage = float(g_iGooMultiplier[iClient])/float(GOO_INCREASE_RATE) * fPercentageDistance;
                        if (fDamage < 1.0) fDamage = 1.0;
                        new iDamage = RoundFloat(fDamage);
                        DealDamage(iClient, iDamage, iAttacker, _, "projectile_stun_ball");
                        g_bGooified[iClient] = true;
                        
                        if (fDamage >= 7.0)
                        {
                            new iRandom = GetRandomInt(0, sizeof(g_strSoundCritHit)-1);
                            EmitSoundToClient(iClient, g_strSoundCritHit[iRandom], _, SNDLEVEL_AIRCRAFT);
                        }
                        else
                        {
                            new iRandom = GetRandomInt(0, sizeof(g_strSoundFleshHit)-1);
                            EmitSoundToClient(iClient, g_strSoundFleshHit[iRandom], _, SNDLEVEL_AIRCRAFT);
                        }
                    }
                }
            }  
        }
    }
    for (iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (IsClientInGame(iClient))
        {
            if (validActivePlayer(iClient) && !g_bGooified[iClient] && g_iGooMultiplier[iClient] > 0)
            {
                g_iGooMultiplier[iClient]--;
            }
            
            //ScreenFade(client, red, green, blue, alpha, delay, type)
            if (!bWasGooified[iClient] && g_bGooified[iClient] && IsPlayerAlive(iClient))
            {
                // fade screen slightly green
                ClientCommand(iClient, "r_screenoverlay\"left4fortress/goo\"");
                MusicHandleClient(iClient);
                //PrintToChat(iClient, "You got goo'd!");
            }
            if (bWasGooified[iClient] && !g_bGooified[iClient])
            {
                // fade screen slightly green
                ClientCommand(iClient, "r_screenoverlay\"\"");
                MusicHandleClient(iClient);
                //PrintToChat(iClient, "You are no longer goo'd!");
            }
        }
    }
}

public Action:GooExpire(Handle:hTimer, any:iGoo)
{
    if (g_hGoo == INVALID_HANDLE) return;
    
    decl iEntry[5];
    new iEntryId;
    for (new i = 0; i < GetArraySize(g_hGoo); i++)
    {
        GetArrayArray(g_hGoo, i, iEntry);
        iEntryId = iEntry[4];
        if (iEntryId == iGoo)
        {
            RemoveFromArray(g_hGoo, i);
        }
        return;
    }
}

RemoveAllGoo()
{
    if (g_hGoo == INVALID_HANDLE) return;
    
    ClearArray(g_hGoo);
}

public Action:GooEffect(Handle:hTimer, any:iGoo)
{
    if (g_hGoo == INVALID_HANDLE) return Plugin_Stop;
    
    decl iEntry[5], Float:fPos[3];
    new iEntryId;
    for (new i = 0; i < GetArraySize(g_hGoo); i++)
    {
        GetArrayArray(g_hGoo, i, iEntry);
        iEntryId = iEntry[4];
        fPos[0] = float(iEntry[0]);
        fPos[1] = float(iEntry[1]);
        fPos[2] = float(iEntry[2]);
        if (iEntryId == iGoo)
        {
            ShowParticle("asplode_hoodoo_green", TIME_GOO, fPos);
            return Plugin_Continue;
        }
    }
    return Plugin_Stop;
}

public OnEntityCreated(iEntity, const String:strClassname[]) {
    if (StrEqual(strClassname, "tf_projectile_stun_ball", false)) {
        SDKHook(iEntity, SDKHook_StartTouch, BallStartTouch);
        SDKHook(iEntity, SDKHook_Touch, BallTouch);
    }
}

public Action:BallStartTouch(iEntity, iOther) {
    if (!zf_bEnabled) return Plugin_Continue;
    if (!IsClassname(iEntity, "tf_projectile_stun_ball")) return Plugin_Continue;
    
    if (iOther > 0 && iOther <= MaxClients && IsClientInGame(iOther) && IsPlayerAlive(iOther) && isSur(iOther))
    {
        new iOwner = GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity");
        SDKUnhook(iEntity, SDKHook_StartTouch, BallStartTouch);
        if (!(GetEntityFlags(iEntity) & FL_ONGROUND))
        {
            SpitterGoo(iOther, iOwner);
        }
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

public Action:BallTouch(iEntity, iOther) {
    if (!zf_bEnabled) return Plugin_Continue;
    if (!IsClassname(iEntity, "tf_projectile_stun_ball")) return Plugin_Continue;
    
    if (iOther > 0 && iOther <= MaxClients && IsClientInGame(iOther) && IsPlayerAlive(iOther) && isSur(iOther))
    {
        SDKUnhook(iEntity, SDKHook_StartTouch, BallStartTouch);
        SDKUnhook(iEntity, SDKHook_Touch, BallTouch);
        AcceptEntityInput(iEntity, "kill");
    }
    
    return Plugin_Stop;
}

stock ShowParticle(String:particlename[], Float:time, Float:pos[3], Float:ang[3]=NULL_VECTOR) {
    new particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle)) {
        TeleportEntity(particle, pos, ang, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", particlename);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, RemoveParticle, particle);
    }
    else {
        LogError("ShowParticle: could not create info_particle_system");
        return -1;
    }
    return particle;
}

stock PrecacheParticle(String:strName[]) {
    if(IsValidEntity(0)) {
        new iParticle = CreateEntityByName("info_particle_system");
        if (IsValidEdict(iParticle)) {
            new String:tName[32];
            GetEntPropString(0, Prop_Data, "m_iName", tName, sizeof(tName));
            DispatchKeyValue(iParticle, "targetname", "tf2particle");
            DispatchKeyValue(iParticle, "parentname", tName);
            DispatchKeyValue(iParticle, "effect_name", strName);
            DispatchSpawn(iParticle);
            SetVariantString(tName);
            AcceptEntityInput(iParticle, "SetParent", 0, iParticle, 0);
            ActivateEntity(iParticle);
            AcceptEntityInput(iParticle, "start");
            CreateTimer(0.01, RemoveParticle, iParticle);
        }
    }
}

public Action:RemoveParticle( Handle:timer, any:particle ) {
    if ( particle >= 0 && IsValidEntity(particle) ) {
        new String:classname[32];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false)) {
            AcceptEntityInput(particle, "stop");
            AcceptEntityInput(particle, "Kill");
            particle = -1;
        }
    }
}

stock DealDamage(iVictim, iDamage, iAttacker=0,iDmgType=DMG_GENERIC, String:strWeapon[]="") {
    if (!validClient(iAttacker)) iAttacker = 0;
    if(validClient(iVictim) && iDamage > 0){
        decl String:strDamage[16];
        IntToString(iDamage, strDamage, 16);
        decl String:strDamageType[32];
        IntToString(iDmgType, strDamageType, 32);
        new iHurt = CreateEntityByName("point_hurt");
        if(iHurt > 0 && IsValidEdict(iHurt)) {
            DispatchKeyValue(iVictim,"targetname","infectious_hurtme");
            DispatchKeyValue(iHurt,"DamageTarget","infectious_hurtme");
            DispatchKeyValue(iHurt,"Damage",strDamage);
            DispatchKeyValue(iHurt,"DamageType",strDamageType);
            if(!StrEqual(strWeapon, "")){
                DispatchKeyValue(iHurt,"classname", strWeapon);
            }
            DispatchSpawn(iHurt);
            AcceptEntityInput(iHurt,"Hurt", iAttacker);
            DispatchKeyValue(iHurt,"classname","point_hurt");
            DispatchKeyValue(iVictim,"targetname","infectious_donthurtme");
            RemoveEdict(iHurt);
        }
    }
}

GetMostDamageZom()
{
    new Handle:hArray = CreateArray();
    new i;
    new iHighest = 0;
    
    for (i = 1; i <= MaxClients; i++)
    {
        if (validZom(i))
        {
            if (g_iDamage[i] > iHighest) iHighest = g_iDamage[i];
        }
    }
    
    for (i = 1; i <= MaxClients; i++)
    {
        if (validZom(i) && g_iDamage[i] >= iHighest)
        {
            PushArrayCell(hArray, i);
        }
    }
    
    if (GetArraySize(hArray) <= 0)
    {
        CloseHandle(hArray);
        return 0;
    }
    
    new iClient = GetArrayCell(hArray, GetRandomInt(0, GetArraySize(hArray)-1));
    CloseHandle(hArray);
    return iClient;
}

bool:ZombiesHaveTank()
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (validLivingZom(i) && g_iSpecialInfected[i] == INFECTED_TANK) return true;
    }
    return false;
}

ZombieTank(iCaller = 0)
{
    if(!zf_bEnabled) return;
    if(roundState() != RoundActive) return;
    
    if (ZombiesHaveTank())
    {
        if (validClient(iCaller)) PrintToChat(iCaller, "Zombies already have a tank");
        return;
    }
    if (g_iZombieTank > 0)
    {   
        if (validClient(iCaller)) PrintToChat(iCaller, "A zombie tank is on the way");
        return;
    }
    if (g_bZombieRage)
    {
        if (validClient(iCaller)) PrintToChat(iCaller, "Zombies are frenzied");
        return;
    }
    
    g_iZombieTank = GetMostDamageZom();
    if (g_iZombieTank <= 0) return;
    
    for (new i = 1; i <= MaxClients; i++)
    {
        if (validZom(i))
        {
            CPrintToChat(i, "{olive}[ZF] {red}%N{default} was picked based on performance to become the TANK!", g_iZombieTank);
        }
    }
    if (validClient(iCaller)) {
        PrintToChat(iCaller, "Called tank");
    }
    
    g_bTankOnce = true;
}

public Action:command_tank(client, args)
{
    if(!zf_bEnabled) return Plugin_Handled;
    if (ZombiesHaveTank()) return Plugin_Handled;
    if (g_iZombieTank > 0) return Plugin_Handled;
    if (g_bZombieRage) return Plugin_Handled;

    g_iZombieTank = client;
    
    for (new i = 1; i <= MaxClients; i++)
    {
        if (validZom(i))
        {
            CPrintToChat(i, "{olive}[ZF] {red}%N{default} was picked based on performance to become the TANK!", g_iZombieTank);
        }
    }
            
    return Plugin_Handled;
}

bool:TankCanReplace(iClient)
{
    if (g_iZombieTank <= 0) return false;
    if (g_iZombieTank == iClient) return false;
    if (g_iSpecialInfected[iClient] != INFECTED_NONE) return false;
    if (TF2_GetPlayerClass(iClient) != TF2_GetPlayerClass(g_iZombieTank)) return false;
    
    new iHealth = GetClientHealth(g_iZombieTank);
    decl Float:fPos[3];
    decl Float:fAng[3];
    decl Float:fVel[3];
    
    GetClientAbsOrigin(g_iZombieTank, fPos);
    GetClientAbsAngles(g_iZombieTank, fVel);
    GetEntPropVector(g_iZombieTank, Prop_Data, "m_vecVelocity", fVel);
    SetEntityHealth(iClient, iHealth);
    TeleportEntity(iClient, fPos, fAng, fVel);
    
    TF2_RespawnPlayer(g_iZombieTank);
    CreateTimer(0.1, timer_postSpawn, g_iZombieTank, TIMER_FLAG_NO_MAPCHANGE);
    
    return true;
}

public Action:command_tank_random(client, args)
{
    if (!zf_bEnabled) return Plugin_Handled;
    ZombieTank(client);
            
    return Plugin_Handled;
}

stock FindEntityByClassname2(startEnt, const String:classname[]) {
    /* If startEnt isn't valid shifting it back to the nearest valid one */
    while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
    return FindEntityByClassname(startEnt, classname);
}

stock bool:HasRazorback(iClient) {
    new iEntity = -1;
    while ((iEntity = FindEntityByClassname2(iEntity, "tf_wearable")) != -1)
    {
        if (IsClassname(iEntity, "tf_wearable") && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient && GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex") == 57) return true;
    }
    return false;
}

stock bool:RemoveSecondaryWearable(iClient) {
    new iEntity = -1;
    while ((iEntity = FindEntityByClassname2(iEntity, "tf_wearable_demoshield")) != -1)
    {
        if (IsClassname(iEntity, "tf_wearable_demoshield") && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient)
        {
            RemoveEdict(iEntity);
            return true;
        }
    }
    return false;
}

public Action:RemoveBackstab(Handle:hTimer, any:iClient)
{
    if (!validClient(iClient)) return;
    if (!IsPlayerAlive(iClient)) return;
    g_bBackstabbed[iClient] = false;
}

bool:MusicCanReset(iMusic)
{
    if (iMusic == MUSIC_INTENSE) return false;
    if (iMusic == MUSIC_MILD) return false;
    if (iMusic == MUSIC_VERYMILD3) return false;
    return true;
}

stock bool:IsClassname(iEntity, String:strClassname[]) {
    if (iEntity <= 0) return false;
    if (!IsValidEdict(iEntity)) return false;
    
    decl String:strClassname2[32];
    GetEdictClassname(iEntity, strClassname2, sizeof(strClassname2));
    if (StrEqual(strClassname, strClassname2, false)) return true;
    return false;
}

GiveBonus(iClient, String:strBonus[])
{
    if (iClient <= 0) return;
    if (!IsClientInGame(iClient)) return;
    if (IsFakeClient(iClient)) return;
    
    //if (iClient != GetMecha()) return;
    
    if (g_hBonus[iClient] == INVALID_HANDLE)
    {
        g_iBonusCombo[iClient] = 0;
        g_bBonusAlt[iClient] = false;
        g_hBonus[iClient] = CreateArray(255);
    }
    
    PushArrayString(g_hBonus[iClient], strBonus);
    
    if (g_hBonusTimers[iClient] == INVALID_HANDLE) g_hBonusTimers[iClient] = CreateTimer(1.0, ShowBonus, iClient);
}

public Action:ShowBonus(Handle:hTimer, any:iClient)
{
    g_hBonusTimers[iClient] = INVALID_HANDLE;
    
    if (iClient <= 0) return Plugin_Handled;
    if (!IsClientInGame(iClient)) return Plugin_Handled;
    
    
    if (GetArraySize(g_hBonus[iClient]) <= 0)
    {
        ClientCommand(iClient, "r_screenoverlay\"\"");
        CloseHandle(g_hBonus[iClient]);
        g_hBonus[iClient] = INVALID_HANDLE;
        return Plugin_Handled;
    }
    
    if (!g_bBonusAlt[iClient])
    {
        decl String:strEntry[255];
        decl String:strPath[PLATFORM_MAX_PATH];
        GetArrayString(g_hBonus[iClient], 0, strEntry, sizeof(strEntry));
        Format(strPath, sizeof(strPath), "r_screenoverlay\"left4fortress/%s\"", strEntry);
        ClientCommand(iClient, strPath);
        
        new iPitch = g_iBonusCombo[iClient] * 30 + 100;
        if (iPitch > 250) iPitch = 250;
        
        new iRandom = GetRandomInt(0, g_iMusicCount[MUSIC_AWARD]-1);
        MusicGetPath(MUSIC_AWARD, iRandom, strPath, sizeof(strPath));
        
        EmitSoundToClient(iClient, strPath, _, _, _, SND_CHANGEPITCH, _, iPitch);
        EmitSoundToClient(iClient, strPath, _, _, _, SND_CHANGEPITCH, _, iPitch);
        EmitSoundToClient(iClient, strPath, _, _, _, SND_CHANGEPITCH, _, iPitch);
        EmitSoundToClient(iClient, strPath, _, _, _, SND_CHANGEPITCH, _, iPitch);
        EmitSoundToClient(iClient, strPath, _, _, _, SND_CHANGEPITCH, _, iPitch);
        EmitSoundToClient(iClient, strPath, _, _, _, SND_CHANGEPITCH, _, iPitch);
        EmitSoundToClient(iClient, strPath, _, _, _, SND_CHANGEPITCH, _, iPitch);
        EmitSoundToClient(iClient, strPath, _, _, _, SND_CHANGEPITCH, _, iPitch);
        EmitSoundToClient(iClient, strPath, _, _, _, SND_CHANGEPITCH, _, iPitch);
        EmitSoundToClient(iClient, strPath, _, _, _, SND_CHANGEPITCH, _, iPitch);
        EmitSoundToClient(iClient, strPath, _, _, _, SND_CHANGEPITCH, _, iPitch);
        EmitSoundToClient(iClient, strPath, _, _, _, SND_CHANGEPITCH, _, iPitch);
        EmitSoundToClient(iClient, strPath, _, _, _, SND_CHANGEPITCH, _, iPitch);
        
        g_iBonusCombo[iClient]++;
        
        if (g_hBonusTimers[iClient] == INVALID_HANDLE) g_hBonusTimers[iClient] = CreateTimer(1.9, ShowBonus, iClient);
    } else
    {
        ClientCommand(iClient, "r_screenoverlay\"\"");
        RemoveFromArray(g_hBonus[iClient], 0);
        if (g_hBonusTimers[iClient] == INVALID_HANDLE) g_hBonusTimers[iClient] = CreateTimer(0.1, ShowBonus, iClient);
    }
    
    TF2_SetPlayerResourceData(iClient, TFResource_TotalScore, 99);
    
    g_bBonusAlt[iClient] = !g_bBonusAlt[iClient];
    
    return Plugin_Handled;
}

GetAverageDamage()
{
    new iTotalDamage = 0;
    new iCount = 0;
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            iTotalDamage += g_iDamage[i];
            iCount++;
        }
    }
    return RoundFloat(float(iTotalDamage) / float(iCount));
}

PrecacheBonus(String:strPath[])
{
    decl String:strPath2[PLATFORM_MAX_PATH];
    Format(strPath2, sizeof(strPath2), "materials/left4fortress/%s.vmt", strPath);
    AddFileToDownloadsTable(strPath2);
    Format(strPath2, sizeof(strPath2), "materials/left4fortress/%s.vtf", strPath);
    AddFileToDownloadsTable(strPath2);
}

RemovePhysicObjects()
{
    if (g_iMode == GAMEMODE_NEW) return;
    new index = -1; 
    while ((index = FindEntityByClassname(index, "prop_physics")) != -1)
    {
        if (IsClassname(index, "prop_physics")) AcceptEntityInput(index, "Kill");
    }
}

GetActivePlayerCount()
{
    new i = 0;
    for (new j = 1; j <= MaxClients; j++)
    {
        if (validActivePlayer(j)) i++;
    }
    return i;
}

DetermineControlPoints()
{
    g_bCapturingLastPoint = false;
    g_iControlPoints = 0;
    
    for (new i = 0; i < sizeof(g_iControlPointsInfo); i++)
    {
        g_iControlPointsInfo[i][0] = -1;
    }
    
    //LogMessage("SZF: Calculating cps...");
    
    new iMaster = -1;

    new iEntity = -1;
    while ((iEntity = FindEntityByClassname2(iEntity, "team_control_point_master")) != -1) {
        if (IsClassname(iEntity, "team_control_point_master")) {
            iMaster = iEntity;
        }
    }
    
    if (iMaster <= 0)
    {
        //LogMessage("No master found");
        return;
    }
    
    iEntity = -1;
    while ((iEntity = FindEntityByClassname2(iEntity, "team_control_point")) != -1) {
        if (IsClassname(iEntity, "team_control_point") && g_iControlPoints < sizeof(g_iControlPointsInfo)) {
            new iIndex = GetEntProp(iEntity, Prop_Data, "m_iPointIndex");            
            g_iControlPointsInfo[g_iControlPoints][0] = iIndex;
            g_iControlPointsInfo[g_iControlPoints][1] = 0;
            g_iControlPoints++;
            
            //LogMessage("Found CP with index %d", iIndex);
        }
    }
    
    //LogMessage("Found a total of %d cps", g_iControlPoints);
    
    CheckRemainingCP();
}

public Action:event_CPCapture(Handle:hEvent, const String:strName[], bool:bHide)
{
    if (g_iControlPoints <= 0) return;
    
    //LogMessage("Captured CP");

    new iCaptureIndex = GetEventInt(hEvent, "cp");
    if (iCaptureIndex < 0) return;
    if (iCaptureIndex >= g_iControlPoints) return;
    
    for (new i = 0; i < g_iControlPoints; i++)
    {
        if (g_iControlPointsInfo[i][0] == iCaptureIndex)
        {
            g_iControlPointsInfo[i][1] = 2;
        }
    }
    
    CheckRemainingCP();
}

public Action:event_CPCaptureStart(Handle:hEvent, const String:strName[], bool:bHide)
{
    if (g_iControlPoints <= 0) return;
    

    new iCaptureIndex = GetEventInt(hEvent, "cp");
    //LogMessage("Began capturing CP #%d / (total %d)", iCaptureIndex, g_iControlPoints);
    if (iCaptureIndex < 0) return;
    if (iCaptureIndex >= g_iControlPoints) return;
    
    for (new i = 0; i < g_iControlPoints; i++)
    {
        if (g_iControlPointsInfo[i][0] == iCaptureIndex)
        {
            g_iControlPointsInfo[i][1] = 1;
            //LogMessage("Set capture status on %d to 1", i);
        }
    }
    
    //LogMessage("Done with capturing CP event");
    
    CheckRemainingCP();
}

CheckRemainingCP()
{
    g_bCapturingLastPoint = false;
    if (g_iControlPoints <= 0) return;
    
    //LogMessage("Checking remaining CP");

    new iCaptureCount = 0;
    new iCapturing = 0;
    for (new i = 0; i < g_iControlPoints; i++)
    {
        if (g_iControlPointsInfo[i][1] >= 2) iCaptureCount++;
        if (g_iControlPointsInfo[i][1] == 1) iCapturing++;
    }
    
    //LogMessage("Capture count: %d, Max CPs: %d, Capturing: %d", iCaptureCount, g_iControlPoints, iCapturing);
    
    if (iCaptureCount == g_iControlPoints-1 && iCapturing > 0)
    {
        g_bCapturingLastPoint = true;
        if (g_fZombieDamageScale < 1.0 && !g_bTankOnce) ZombieTank();
    }
}

TFClassWeapon:GetWeaponInfoFromModel(String:strModel[], &iSlot, &iSwitchSlot, &Handle:hWeapon, &bool:bWearable, String:strName[], iMaxSize)
{
    new TFClassWeapon:iClass = TFClassWeapon_Unknown;
    
    if (StrEqual(strModel, "models/weapons/c_models/c_lochnload/c_lochnload.mdl"))
    {
        hWeapon = hWeaponLochNLoad;
        iSlot = 0;
        iClass = TFClassWeapon_DemoMan;
        strcopy(strName, iMaxSize, "Loch'n'Load");
    }
    else if (StrEqual(strModel, "models/weapons/c_models/c_flaregun_pyro/c_flaregun_pyro.mdl"))
    {
        hWeapon = hWeaponFlareGun;
        iSlot = 1;
        iClass = TFClassWeapon_Pyro;
        strcopy(strName, iMaxSize, "Flaregun");
    }
    else if (StrEqual(strModel, "models/weapons/w_models/w_shotgun.mdl"))
    {
        hWeapon = hWeaponShotgunPyro;
        iSlot = 1;
        iClass = TFClassWeapon_Group_Shotgun;
        strcopy(strName, iMaxSize, "Shotgun");
    }
    else if (StrEqual(strModel, "models/weapons/c_models/c_drg_righteousbison/c_drg_righteousbison.mdl"))
    {
        hWeapon = hWeaponBison;
        iSlot = 1;
        iClass = TFClassWeapon_Soldier;
        strcopy(strName, iMaxSize, "Righteous Bison");
    }
    else if (StrEqual(strModel, "models/weapons/c_models/c_targe/c_targe.mdl"))
    {
        hWeapon = hWeaponTarge;
        iSlot = 1;
        iSwitchSlot = 2;
        bWearable = true;
        strcopy(strName, iMaxSize, "Chargin' Targe");
    }
    if (iSwitchSlot < 0) iSwitchSlot = iSlot;
    
    return iClass;
}

bool:AttemptGrabItem(iClient)
{
    new iTarget = GetClientPointVisible(iClient);
    
    new String:strClassname[255];
    if (iTarget > 0) GetEdictClassname(iTarget, strClassname, sizeof(strClassname));
    //PrintToChat(iClient, "AttemptGrabItem %d (%s)", iTarget, strClassname);
    if (iTarget <= 0 || !IsClassname(iTarget, "prop_dynamic")) return false;

    decl String:strModel[255];
    GetEntityModel(iTarget, strModel, sizeof(strModel));
    //PrintToChat(iClient, "Model: %s", strModel);
    
    new TFClassWeapon:iClass = TFClassWeapon:TF2_GetPlayerClass(iClient);
    
    new Handle:hWeapon = INVALID_HANDLE;
    new iSlot = -1;
    new iSwitchSlot = -1;
    new bool:bWearable = false;
    decl String:strName[255];
    
    new TFClassWeapon:iWeaponClass = GetWeaponInfoFromModel(strModel, iSlot, iSwitchSlot, hWeapon, bWearable, strName, sizeof(strName));
    if (hWeapon == INVALID_HANDLE || iSlot < 0) return false;
    
    // fix up multi-class weapons
    if (iWeaponClass == TFClassWeapon_Group_Shotgun)
    {
        if (iClass == TFClassWeapon_Pyro) hWeapon = hWeaponShotgunPyro;
        else if (iClass == TFClassWeapon_Soldier) hWeapon = hWeaponShotgunSoldier;
        else return false;
    }
    else if (iWeaponClass != iClass) return false;
    
    CPrintToChat(iClient, "You picked up a {olive}%s", strName);
    
    if (iSwitchSlot < 0) iSwitchSlot = iSlot;
    
    ClientCommand(iClient, "playgamesound ui/item_heavy_gun_drop.wav");
    ClientCommand(iClient, "playgamesound ui/item_heavy_gun_pickup.wav");
    
    // get his old model
    new iEntity = GetPlayerWeaponSlot2(iClient, iSlot);
    
    // check whether this is a start item. If it is, we need to place a primary or secondary down, so the client only has 1 item
    new iWeaponMode = GetWeaponType(iTarget);
    
    if (iWeaponMode == 1)
    {
        if (iEntity <= 0 || !IsValidEdict(iEntity))
        {
            iSlot = 0;
            iEntity = GetPlayerWeaponSlot2(iClient, iSlot);
        }
        if (iEntity <= 0 || !IsValidEdict(iEntity))
        {
            iSlot = 1;
            iEntity = GetPlayerWeaponSlot2(iClient, iSlot);
        }
    }
    
    // Replace it or remove it
    if (iWeaponMode != 1)
    {
        if (iEntity > 0 && IsValidEdict(iEntity))
        {
            if (IsClassname(iEntity, "tf_wearable_demoshield")) GetEntityModel(iEntity, strModel, sizeof(strModel), "m_nModelIndex");
            else GetEntityModel(iEntity, strModel, sizeof(strModel), "m_iWorldModelIndex");
            PrecacheModel(strModel);
            SetEntityModel(iTarget, strModel);
        }
        else
        {
            AcceptEntityInput(iTarget, "kill");
        }
    }
    
    TF2_RemoveWeaponSlot(iClient, iSlot);
    if (iSlot == 1) RemoveSecondaryWearable(iClient);
    iEntity = TF2Items_GiveNamedItem(iClient, hWeapon);
    if (bWearable) SDKCall(hEquipWearable, iClient, iEntity);
    else EquipPlayerWeapon(iClient, iEntity);
    
    ClientCommand(iClient, "slot%d", iSwitchSlot);
    
    CheckStartWeapons();
    
    return true;
}

GetModelPath(iIndex, String:strModel[], iMaxSize)
{
    new iTable = FindStringTable("modelprecache");
    ReadStringTable(iTable, iIndex, strModel, iMaxSize);
}

GetEntityModel(iEntity, String:strModel[], iMaxSize, String:strPropName[] = "m_nModelIndex")
{
    //m_iWorldModelIndex
    new iIndex = GetEntProp(iEntity, Prop_Send, strPropName);
    GetModelPath(iIndex, strModel, iMaxSize);
}

GetPlayerWeaponSlot2(iClient, iSlot)
{
    new iEntity = GetPlayerWeaponSlot(iClient, iSlot);
    if (iEntity > 0 && IsValidEdict(iEntity)) return iEntity;
    
    if (iSlot == 1)
    {
        iEntity = -1;
        while ((iEntity = FindEntityByClassname2(iEntity, "tf_wearable_demoshield")) != -1)
        {
            if (IsClassname(iEntity, "tf_wearable_demoshield") && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient) return iEntity;
        }
    }
    
    return -1;
}

CheckStartWeapons()
{
    new iClassesWithoutWeapons[10] = 0;
    
    for (new i = 1; i <= MaxClients; i++)
    {
        if (validLivingSur(i) && !DoesPlayerHaveRealWeapon(i))
        {
            new TFClassType:iClass = TF2_GetPlayerClass(i);
            iClassesWithoutWeapons[iClass]++;
            //PrintToChat(i, "You do not have a real weapon");
        }
    }
    
    decl String:strModel[PLATFORM_MAX_PATH];

    new iEntity = -1;
    while ((iEntity = FindEntityByClassname2(iEntity, "prop_dynamic")) != -1)
    {
        if (IsClassname(iEntity, "prop_dynamic") && GetWeaponType(iEntity) == 1)
        {
            GetEntityModel(iEntity, strModel, sizeof(strModel));
            new TFClassWeapon:iClass = GetWeaponClass(strModel);
            
            new Handle:hArray = CreateArray();
            if (iClass == TFClassWeapon_Group_Shotgun)
            {
                PushArrayCell(hArray, TFClassWeapon_Soldier);
                PushArrayCell(hArray, TFClassWeapon_Heavy);
                PushArrayCell(hArray, TFClassWeapon_Pyro);
                PushArrayCell(hArray, TFClassWeapon_Engineer);
            }
            else
            {
                PushArrayCell(hArray, iClass);
            }
            
            
            new bool:bEnable = false;
            for (new i = 0; i < GetArraySize(hArray); i++)
            {
                new iClass2 = GetArrayCell(hArray, i);
                //PrintToServer("Class: %d", iClass2);
                if (iClassesWithoutWeapons[iClass2] > 0)
                {
                    bEnable = true;
                    iClassesWithoutWeapons[iClass2]--;
                    //PrintToChatAll("Enabling weapon %s", strModel);
                }
            }
            
            if (bEnable)
            {
                AcceptEntityInput(iEntity, "TurnOn");
                AcceptEntityInput(iEntity, "EnableCollision");
            }
            else
            {
                AcceptEntityInput(iEntity, "TurnOff");
                AcceptEntityInput(iEntity, "DisableCollision");
            }
        }
    }
}

GetWeaponType(iEntity)
{
    decl String:strName[255];
    GetEntPropString(iEntity, Prop_Data, "m_iName", strName, sizeof(strName));
    if (StrEqual(strName, "szf_weapons_intro", false)) return 1;
    
    return 0;
}

TFClassWeapon:GetWeaponClass(String:strModel[])
{    
    new Handle:hWeapon = INVALID_HANDLE;
    new iSlot = -1;
    new iSwitchSlot = -1;
    new bool:bWearable = false;
    decl String:strName[255];
    
    new TFClassWeapon:iWeaponClass = GetWeaponInfoFromModel(strModel, iSlot, iSwitchSlot, hWeapon, bWearable, strName, sizeof(strName));
    
    return iWeaponClass;
}

bool:DoesPlayerHaveRealWeapon(iClient)
{
    new iEntity = GetPlayerWeaponSlot(iClient, 0);
    if (iEntity > 0 && IsValidEdict(iEntity)) return true;
    iEntity = GetPlayerWeaponSlot(iClient, 1);
    if (iEntity > 0 && IsValidEdict(iEntity)) return true;
    
    return false;
}

bool:AttemptCarryItem(iClient)
{
    if (DropCarryingItem(iClient)) return true;

    new iTarget = GetClientPointVisible(iClient);
    
    new String:strClassname[255];
    if (iTarget > 0) GetEdictClassname(iTarget, strClassname, sizeof(strClassname));
    if (iTarget <= 0 || !IsClassname(iTarget, "prop_physics")) return false;
    
    decl String:strName[255];
    GetEntPropString(iTarget, Prop_Data, "m_iName", strName, sizeof(strName));
    if (!StrEqual(strName, "gascan", false)) return false;
    
    g_iCarryingItem[iClient] = iTarget;
    SetEntProp(iClient, Prop_Send, "m_bDrawViewmodel", 0);
    //PrintToChat(iClient, "Picked up gas can %d", iTarget);
    AcceptEntityInput(iTarget, "DisableMotion");
    //PrintToChat(iClient, "m_usSolidFlags: %d", GetEntProp(iTarget, Prop_Send, "m_usSolidFlags"));
    //SetEntProp(iTarget, Prop_Send, "m_nSolidType", 0);
    
    ClientCommand(iClient, "playgamesound ui/item_paint_can_pickup.wav");
    ClientCommand(iClient, "playgamesound ui/item_paint_can_pickup.wav");
    
    return true;
}

UpdateClientCarrying(iClient)
{
    new iTarget = g_iCarryingItem[iClient];
    
    //PrintCenterText(iClient, "Teleporting gas can (%d)", iTarget);
    
    if (iTarget <= 0) return;
    if (!IsClassname(iTarget, "prop_physics"))
    {
        DropCarryingItem(iClient);
        return;
    }
    
    //PrintCenterText(iClient, "Teleporting gas can 1");
    
    decl String:strName[255];
    GetEntPropString(iTarget, Prop_Data, "m_iName", strName, sizeof(strName));
    if (!StrEqual(strName, "gascan", false)) return;
    
    decl Float:vOrigin[3], Float:vAngles[3], Float:vDistance[3];
    new Float:vEmpty[3];
    GetClientEyePosition(iClient, vOrigin);
    GetClientEyeAngles(iClient, vAngles);
    vAngles[0] = 5.0;
    
    vOrigin[2] -= 20.0;
    
    vAngles[2] += 35.0;
    AnglesToVelocity(vAngles, vDistance, 60.0);
    AddVectors(vOrigin, vDistance, vOrigin);
    TeleportEntity(iTarget, vOrigin, vAngles, vEmpty);
    
    //PrintCenterText(iClient, "Teleporting gas can");
}

bool:DropCarryingItem(iClient, bool:bDrop = true)
{
    new iTarget = g_iCarryingItem[iClient];
    if (iTarget <= 0) return false;
    
    g_iCarryingItem[iClient] = -1;
    SetEntProp(iClient, Prop_Send, "m_bDrawViewmodel", 1);
    
    if (!IsClassname(iTarget, "prop_physics")) return true;
    
    //PrintToChat(iClient, "Dropped gas can");
    //SetEntProp(iTarget, Prop_Send, "m_nSolidType", 6);
    AcceptEntityInput(iTarget, "EnableMotion");
   
    if (bDrop && (IsEntityStuck(iTarget) || ObstancleBetweenEntities(iClient, iTarget)))
    {
        decl Float:vOrigin[3];
        GetClientEyePosition(iClient, vOrigin);
        TeleportEntity(iTarget, vOrigin, NULL_VECTOR, NULL_VECTOR);
    }
    return true;
}

stock AnglesToVelocity(Float:fAngle[3], Float:fVelocity[3], Float:fSpeed = 1.0) {
    fVelocity[0] = Cosine(DegToRad(fAngle[1]));
    fVelocity[1] = Sine(DegToRad(fAngle[1]));
    fVelocity[2] = Sine(DegToRad(fAngle[0])) * -1.0;
    
    NormalizeVector(fVelocity, fVelocity);
    
    ScaleVector(fVelocity, fSpeed);
}

stock bool:IsEntityStuck(iEntity){
    decl Float:vecMin[3], Float:vecMax[3], Float:vecOrigin[3];
    
    GetEntPropVector(iEntity, Prop_Send, "m_vecMins", vecMin);
    GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", vecMax);
    GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", vecOrigin);
    
    TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceDontHitEntity, iEntity);
    return (TR_DidHit());
}