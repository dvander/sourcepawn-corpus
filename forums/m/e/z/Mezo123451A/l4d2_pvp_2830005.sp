#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.1.2"

// Forward declarations
forward Action Timer_HandleNewPlayer(Handle timer, any client);
forward Action Timer_TeleportAndEquip(Handle timer, any client);
forward Action Timer_TeleportToWarmup(Handle timer, any client);
forward Action Timer_RemoveSpawnProtection(Handle timer, any client);
forward Action Timer_CheckAbnormalHealth(Handle timer, any client);
forward Action Timer_VerifyPvPJoinSpawn(Handle timer, any data);
forward Action Timer_VerifyPostDeathRespawn(Handle timer, any data);
public bool ShouldCountKill(int victim, int attacker);

// Sound definitions
#define SOUND_GUN_GAME_LEVEL_UP "ui/littlereward.wav"  // Sound to play when leveling up in Gun Game
#define SOUND_GUN_GAME_KNIFE_LEVEL "ui/bigreward.wav" // Sound to play when reaching the knife level
#define SOUND_PVP_KILL "ui/littlereward.wav"
#define SOUND_PVP_HEADSHOT_KILL "ui/bigreward.wav"

#define TEAM_IDLE        1    // Idle/Spectator team
#define TEAM_SURVIVOR    2    // Survivor team
#define TEAM_INFECTED    3    // Infected team
#define MAX_TEAMS 2
#define TEAM_A 0
#define TEAM_B 1
#define MAX_SPAWNS 16
#define MAX_WARMUP_SPAWNS 16
#define SPAWN_FILE "data/l4d2_pvp_spawns_%s.txt"  // TDM spawns
#define WARMUP_SPAWN_FILE "data/l4d2_warmup_spawns_%s.txt"  // Warmup spawns
#define FFA_SPAWN_FILE "data/l4d2_ffa_spawns_%s.txt"  // FFA spawns
#define MAX_FFA_SPAWNS 32
#define FFA_AUTO_TARGET_SPAWNS 32
#define FFA_AUTO_MIN_GOOD_SPAWNS 8
#define FFA_AUTO_MAX_ANCHORS 160
#define FFA_AUTO_MIN_DISTANCE 760.0
#define FFA_AUTO_FALLBACK_DISTANCE 460.0
#define FFA_AUTO_EMERGENCY_DISTANCE 280.0
#define FFA_AUTO_LOS_DISTANCE 1400.0
#define FFA_AUTO_ANCHOR_DEDUPE 220.0
#define FFA_SPAWN_REUSE_COOLDOWN 5.0
#define FFA_SPAWN_OCCUPIED_RADIUS 140.0
#define TDM_AUTO_ARENA_MIN_RADIUS 1850.0
#define TDM_AUTO_ARENA_MAX_RADIUS 3400.0
#define TDM_AUTO_TEAM_CLUSTER_RADIUS 620.0
#define TDM_AUTO_TEAM_MIN_SEPARATION 1250.0
#define TDM_AUTO_TEAM_MAX_SEPARATION 3200.0
#define TDM_AUTO_TEAM_TARGET_SEPARATION 1900.0
#define TDM_AUTO_TEAM_FALLBACK_MIN_SEPARATION 850.0
#define TDM_AUTO_TEAM_FALLBACK_MAX_SEPARATION 3800.0
#define TDM_AUTO_MIN_TEAM_SPAWNS 6
#define TDM_SPAWN_ENEMY_MIN_DISTANCE 760.0
#define TDM_AUTO_CENTER_SCORE_WINDOW 1400.0
#define TDM_AUTO_CENTER_HISTORY 5
#define TDM_AUTO_HISTORY_CENTER_AVOID_RADIUS 1450.0
#define TDM_AUTO_HISTORY_MIDPOINT_AVOID_RADIUS 1850.0
#define SPAWN_WATCH_MAX_DISTANCE 3600.0
#define SPAWN_WATCH_DOT_MIN 0.60
#define SPAWN_WATCH_SCORE_PENALTY 2500.0
#define TDM_ARENA_DAMAGE_INTERVAL 1.0
#define TDM_ARENA_DAMAGE 8
#define TDM_ARENA_WARN_DISTANCE 120.0
#define TDM_ARENA_VISUAL_HEIGHT 130.0
#define TDM_ARENA_WALL_BUFFER 48.0
#define TDM_SPAWN_REUSE_COOLDOWN 4.0
#define TDM_SPAWN_OCCUPIED_RADIUS 130.0
#define SPAWN_PROTECTION_TIME 3.0
#define WARMUP_TIME 15.0
#define RESPAWN_TIME 7.0
#define RESPAWN_VERIFY_DELAY 8.2
#define RESPAWN_VERIFY_RETRY_DELAY 0.8
#define RESPAWN_VERIFY_MAX_ATTEMPTS 5
#define KILLCAM_TIME 7.0
#define PVP_STOP_LOCK_TIME 2.0
#define PLAYERS_PER_TEAM 4
#define BLOCK_RADIUS 150.0
#define SPRITE_BEAM "materials/sprites/laserbeam.vmt"
#define SPRITE_DURATION 10.0
#define SPRITE_HEIGHT 128.0
#define SPAWN_SHOW_REFRESH 1.0
#define GAMEDATA_FILE "l4d2_respawn"
#define WELCOME_INTERVAL 30.0
#define EASY_MULTIPLIER 0.2
#define NORMAL_MULTIPLIER 1.0    // Normal now does 100% damage (same as Expert)
#define ADVANCED_MULTIPLIER 1.0  // Advanced does 100% damage
#define EXPERT_MULTIPLIER 1.0    // Expert does 100% damage
#define GLOW_NONE 0
#define GLOW_OUTLINE 1
#define GLOW_FULL 2
#define GLOW_CONSTANT 3
#define WEAPON_AWP "weapon_sniper_awp"  // This is the correct weapon ID for CSS AWP in L4D2
#define CSS_AWP_MODEL "models/w_models/weapons/w_snip_awp.mdl"
#define CSS_AWP_VIEW_MODEL "models/v_models/v_snip_awp.mdl"
#define AWP_WARMUP_TIME 15.0
#define WEAPON_KNIFE "weapon_melee"
#define EF_BONEMERGE            (1 << 0)
#define EF_NOSHADOW             (1 << 4)
#define EF_PARENT_ANIMATES      (1 << 9)
#define KILLCAM_GLOW_COLOR      (255 | (128 << 8) | (0 << 16))
#define TEAM_GLOW_COLOR         (64 | (128 << 8) | (255 << 16))
#define CLIMB_GLOW_SEARCH_RADIUS 180.0
#define LAST_ATTACKER_CREDIT_TIME 8.0
#define HITMARKER_INNER_GAP 0.9
#define HITMARKER_OUTER_SIZE 2.7
#define HITMARKER_HEADSHOT_INNER_GAP 1.05
#define HITMARKER_HEADSHOT_OUTER_SIZE 3.1
#define HITMARKER_LIFE 0.13
#define HITMARKER_WIDTH 0.35
#define HITMARKER_COOLDOWN 0.035
#define HITMARKER_SCREEN_DISTANCE 40.0
#define HITMARKER_CLOSE_DISTANCE 260.0
#define HITMARKER_FAR_DISTANCE 2600.0
#define HITMARKER_MIN_SCALE 0.52
#define HITMARKER_MAX_SCALE 1.38
#define HITMARKER_BASE_FOV 90.0
#define HITMARKER_MIN_FOV_SCALE 0.26

bool g_bOneShotMode = false;
ConVar g_cvOneShotScoreLimit;
ConVar g_cvOneShotRoundTime;
int g_iBeamSprite;
bool g_bPvPActive = false;
bool g_bWarmupActive = false;
bool g_bWarmupEnabled = false; // Added: Flag to enable/disable warmup
bool g_bFFAActive = false;
float g_fPvPStopLockUntil = 0.0;
ConVar g_cvAWPRoundTime;
ConVar g_cvAWPScoreLimit;
bool g_bAWPActive = false;
bool g_bMatchEnded = false;
bool g_bSpawnProtection[MAXPLAYERS + 1] = {false, ...};
bool g_bIsJoining[MAXPLAYERS + 1];
int g_iPlayerTeam[MAXPLAYERS + 1];
float g_iLastTeamAnnounce[MAXPLAYERS + 1]; // Added: Timestamp of last team announcement per player
int g_iTeamScores[MAX_TEAMS] = {0, ...}; // Initialize scores to 0
int g_iLastAttacker[MAXPLAYERS + 1] = {0, ...};
char g_sLastWeapon[MAXPLAYERS + 1][32];  // Store the weapon name instead of just an ID
char g_sLastHurtWeapon[MAXPLAYERS + 1][32];
float g_fLastPvPAttackTime[MAXPLAYERS + 1];
float g_fNextHitMarkerTime[MAXPLAYERS + 1];
bool g_bLastHitWasHeadshot[MAXPLAYERS + 1];
Handle g_hRoundTimer = null;
Handle g_hFFARoundTimer = null;
Handle g_hAWPRoundTimer = null;
Handle g_hRespawnTimers[MAXPLAYERS + 1] = {null, ...};
Handle g_hInfectedCheckTimer = null;
Handle g_hMenuReminderTimer = null;
Handle g_hSwitchReminderTimer = null;
Handle g_hTeamGlowRefreshTimer = null;
Handle g_hKillcamTimer[MAXPLAYERS + 1];
Handle g_hMenuUpdateTimer[MAXPLAYERS + 1] = {null, ...};
int g_iLastMenuTime[MAXPLAYERS + 1] = {0, ...};
int g_iSafeRoomBlocker = -1;
bool g_bShowAllSpawnsPersistent = false;
Handle g_hShowSpawnsTimer = null;
bool g_bShowTDMSpawnsPersistent = false;
Handle g_hShowTDMSpawnsTimer = null;
bool g_bShowWarmupSpawnsPersistent = false;
Handle g_hShowWarmupSpawnsTimer = null;
bool g_bShowFFASpawnsPersistent = false;
Handle g_hShowFFASpawnsTimer = null;
ConVar g_cvRoundTime;
ConVar g_cvScoreLimit;
ConVar g_cvFFAScoreLimit;
ConVar g_cvFFARoundTime;
Handle g_hSDKRoundRespawn = null;
ConVar g_hSpecialSpawnInterval = null;
ConVar g_hCommonLimit = null;
ConVar g_hDirectorNoSpecials = null;
ConVar g_hDirectorNoMobs = null;
ConVar g_hDirectorNoBosses = null;
ConVar g_hGlowEnable;
ConVar g_hClimbGlow = null;
ConVar g_hNetworkOptimize;
ConVar g_hUpdateRate;
ConVar g_hMaxRate;
ConVar g_hMinRate;
ConVar g_hMaxCmdRate;
ConVar g_hMinCmdRate;
ConVar g_hSplitPacket;
ConVar g_hMaxClearTime;
int g_iPlayerKills[MAXPLAYERS + 1];
int g_iPlayerDeaths[MAXPLAYERS + 1];
int g_iAWPKills[MAXPLAYERS + 1];
float g_fAWPStartTime;
int g_iSaferoomBot = -1;
bool g_bSaferoomBotActive = false;
float g_fLastTeamAnnounce[MAXPLAYERS + 1];
int g_iKillcamTarget[MAXPLAYERS + 1];
bool g_bInKillcam[MAXPLAYERS + 1];
int g_iKillcamGlowProxy[MAXPLAYERS + 1];
int g_iTeamGlowProxy[MAXPLAYERS + 1];
int g_iTeamGlowProxyTeam[MAXPLAYERS + 1];
bool g_bTeamGlowExternal[MAXPLAYERS + 1];
bool g_bSavedClimbGlow = false;
int g_iSavedClimbGlow = 1;
int g_iActiveKillcams = 0;
float g_fKillcamAnchor[MAXPLAYERS+1][3];
float g_fDeathPosition[MAXPLAYERS+1][3];  // Store death positions
float g_fDeathAngles[MAXPLAYERS+1][3];    // Store death angles
ConVar g_cvWarmupEnabled;
bool g_bGunGameActive = false;  // Gun Game mode active flag
ConVar g_cvGunGameScoreLimit;   // Gun Game score limit ConVar
Handle g_hGunGameRoundTimer = null;  // Gun Game round timer
int g_iGunGameLevel[MAXPLAYERS + 1];  // Current weapon level for each player in Gun Game
bool g_bKnifeOneHitKill = false;  // Knife one-hit kill in Gun Game (set to false for vanilla damage)
int g_iGunGameKills[MAXPLAYERS + 1];  // Kills counter for Gun Game levels
float g_fLastGunGameWeaponMsgTime[MAXPLAYERS + 1];
float g_fLastGunGameFinalMsgTime[MAXPLAYERS + 1];
#define KILLS_PER_LEVEL 2   // Number of kills needed to level up (except knife)
bool g_bKnifeLevelSetup[MAXPLAYERS + 1] = {false, ...};  // Track if knife level setup was already done
bool g_bSelfKilled[MAXPLAYERS + 1]; // Track if player used !kill command
ConVar g_cvGunGameKillcam;
ConVar g_cvMusicEnabled;
ConVar g_cvMusicVolume;

// Global ConVars
// ConVar g_hSpawnProtectionTime;
// ConVar g_hSpawnBoundsRadius;
ConVar g_hHeadshotDamageMultiplier; // Headshot damage multiplier

// Kill request system
bool g_bKillRequestPending[MAXPLAYERS + 1];    // Track pending kill requests
int g_iKillRequestClient = -1;                 // Store the client ID who requested kill
Handle g_hKillRequestTimer = null;             // Timer handle for kill request timeout

// Health regeneration system
#define REGEN_DELAY 5.0           // Time in seconds before health regeneration starts
#define REGEN_INTERVAL 0.5      // How often to apply regeneration
#define REGEN_AMOUNT 5          // How much health to regenerate per interval
#define MAX_HEALTH 100          // Maximum health a player can have

// Health regeneration variables
float g_fLastDamageTime[MAXPLAYERS + 1];    // Track when each player last took damage
Handle g_hRegenTimer[MAXPLAYERS + 1];        // Timer handle for each player's health regeneration

public Action OnWeaponCanUse(int client, int weapon)
{
    // Gun Game mode - block ALL weapon pickups
    if (g_bGunGameActive && IsValidClient(client))
    {
        return Plugin_Handled; // Block all pickups in gun game mode
    }
    
    // Your existing AWP mode code here
    if (g_bAWPActive)
    {
        char weaponName[32];
        GetEdictClassname(weapon, weaponName, sizeof(weaponName));
        
        // In AWP mode, only allow AWP
        if (!StrEqual(weaponName, "weapon_sniper_awp"))
        {
            return Plugin_Handled;
        }
    }
    
    return Plugin_Continue; // Allow pickup if no restrictions
}

// Helper function to remove infected arms specifically
void RemoveInfectedArms(int client)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
        return;
    
    // Get all weapons and check for infected-related ones
    int weapon;
    char classname[64];
    
    // Check each weapon slot
    for (int i = 0; i < 5; i++)
    {
        weapon = GetPlayerWeaponSlot(client, i);
        if (weapon > 0)
        {
            GetEdictClassname(weapon, classname, sizeof(classname));
            if (StrContains(classname, "weapon_hunter", false) != -1 || 
                StrContains(classname, "claw", false) != -1 || 
                StrContains(classname, "infected", false) != -1)
            {
                RemovePlayerItem(client, weapon);
                AcceptEntityInput(weapon, "Kill");
                PrintToServer("[DEBUG] Removed infected weapon: %s from player %N", classname, client);
            }
        }
    }
    
    // Also check active weapon directly
    weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (weapon > 0)
    {
        GetEdictClassname(weapon, classname, sizeof(classname));
        if (StrContains(classname, "weapon_hunter", false) != -1 || 
            StrContains(classname, "claw", false) != -1 || 
            StrContains(classname, "infected", false) != -1)
        {
            RemovePlayerItem(client, weapon);
            AcceptEntityInput(weapon, "Kill");
            PrintToServer("[DEBUG] Removed active infected weapon: %s from player %N", classname, client);
        }
    }
}

// Special knife giving function, more reliable than regular approaches
bool GiveKnifeForLastStandFinale(int client)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
        return false;
    
    // First strip all weapons and make absolutely sure no infected arms remain
    StripWeapons(client);
    RemoveInfectedArms(client);
    
    // Create the melee weapon
    int melee = CreateEntityByName("weapon_melee");
    if (melee <= 0)
        return false;
    
    // Try to set it up as a knife/crowbar/katana
    char buffer[64];
    Format(buffer, sizeof(buffer), "l4d2_meleeweapon_%s", "knife");
    DispatchKeyValue(melee, "melee_script_name", "knife");
    
    DispatchSpawn(melee);
    
    // Force pickup of the weapon
    if (IsValidEntity(melee))
    {
        // Remove current secondary weapon if any
        int secondary = GetPlayerWeaponSlot(client, 1);
        if (secondary > 0)
        {
            RemovePlayerItem(client, secondary);
            RemoveEntity(secondary);
        }
        
        // Equip the melee weapon
        if (EquipPlayerWeapon(client, melee))
        {
            PrintToServer("[Debug] Successfully gave special knife weapon to client %d", client);
            return true;
        }
    }
    
    // If we got here, something went wrong
    if (IsValidEntity(melee))
    {
        RemoveEntity(melee);
    }
    
    // Try alternate approaches
    bool success = false;
    
    // Try direct give commands
    if (!success) 
    {
        success = ExecuteClientCommand(client, "give knife");
        PrintToServer("[Debug] Knife give result: %d", success);
    }
    if (!success) 
    {
        success = ExecuteClientCommand(client, "give machete");
        PrintToServer("[Debug] Machete give result: %d", success);
    }
    if (!success) 
    {
        success = ExecuteClientCommand(client, "give crowbar");
        PrintToServer("[Debug] Crowbar give result: %d", success);
    }
    
    return success;
}

// Timer specifically for enforcing knives at the final level
public Action Timer_ForceKnifeForLastStand(Handle timer, any client)
{
    if (!IsValidClient(client) || !g_bGunGameActive || !IsPlayerAlive(client))
        return Plugin_Stop;
    
    // Check if player is at knife level
    int maxLevel = g_cvGunGameScoreLimit.IntValue;
    if (g_iGunGameLevel[client] < maxLevel - 1)
        return Plugin_Stop;
    
    // Remove all weapons first
    StripWeapons(client);
    RemoveInfectedArms(client);
    
    // Force give a knife
    bool success = GiveKnifeForLastStandFinale(client);
    if (!success)
    {
        // Try standard methods if special method fails
        success = GivePlayerRealMeleeWeapon(client, "katana");
        if (!success) success = GivePlayerRealMeleeWeapon(client, "machete");
        if (!success) success = GivePlayerRealMeleeWeapon(client, "crowbar");
        if (!success) success = GivePlayerRealMeleeWeapon(client, "baseball_bat");
    }
    
    // Print debug info
    PrintToServer("[Gun Game] Force knife timer executed for player %N", client);
    
    return Plugin_Stop;
}

// Spawn point storage
float g_fSpawnPoints[MAX_TEAMS][MAX_SPAWNS][3];
float g_fSpawnAngles[MAX_TEAMS][MAX_SPAWNS][3];
int g_iSpawnCount[MAX_TEAMS];
float g_fTDMSpawnNextUse[MAX_TEAMS][MAX_SPAWNS];
int g_iLastTDMSpawnIndex[MAX_TEAMS] = {-1, -1};
bool g_bTDMArenaActive = false;
float g_fTDMArenaCenter[3];
float g_fTDMArenaRadius = 0.0;
Handle g_hTDMArenaTimer = null;
float g_fTDMArenaNextDamage[MAXPLAYERS + 1];
int g_iTDMCenterHistoryCount = 0;
int g_iTDMCenterHistoryNext = 0;
float g_fTDMCenterHistory[TDM_AUTO_CENTER_HISTORY][MAX_TEAMS][3];
float g_fTDMCenterMidHistory[TDM_AUTO_CENTER_HISTORY][3];

// Warmup spawn storage
float g_fWarmupSpawns[MAX_WARMUP_SPAWNS][3];
float g_fWarmupAngles[MAX_WARMUP_SPAWNS][3];
int g_iWarmupSpawnCount = 0;

// FFA spawn storage
float g_fFFASpawnPoints[MAX_FFA_SPAWNS][3];
float g_fFFASpawnAngles[MAX_FFA_SPAWNS][3];
int g_iFFASpawnCount = 0;
float g_fFFASpawnNextUse[MAX_FFA_SPAWNS];
int g_iLastFFASpawnIndex = -1;
int g_iFFAKills[MAXPLAYERS + 1];
float g_fFFAStartTime;  // To track when FFA mode started

// Weapon arrays
static const char g_sPrimaryWeapons[][] = {
    "weapon_smg",
    "weapon_smg_mp5",
    "weapon_smg_silenced",
    "weapon_pumpshotgun",
    "weapon_shotgun_chrome",
    "weapon_rifle",
    "weapon_rifle_desert",
    "weapon_rifle_ak47",
    "weapon_rifle_sg552",
    "weapon_autoshotgun",
    "weapon_shotgun_spas",
    "weapon_hunting_rifle",
    "weapon_sniper_military",
    "weapon_sniper_scout",
    "weapon_sniper_awp",
    "weapon_grenade_launcher",
    "weapon_rifle_m60"
};

static const char g_sSecondaryWeapons[][] = {
    "weapon_pistol",
    "weapon_pistol_magnum"
};

static const char g_sGrenades[][] = {
    "weapon_pipe_bomb",
    "weapon_molotov"
};

// Gun Game weapon progression array - starts with weaker weapons and progresses to stronger ones
static const char g_sGunGameWeapons[][] = {
    "weapon_pistol",         // Level 1
    "weapon_pistol_magnum",  // Level 2
    "weapon_smg",            // Level 3
    "weapon_smg_silenced",   // Level 4
    "weapon_smg_mp5",        // Level 5
    "weapon_pumpshotgun",    // Level 6
    "weapon_shotgun_chrome", // Level 7
    "weapon_rifle",          // Level 8
    "weapon_rifle_desert",   // Level 9
    "weapon_rifle_ak47",     // Level 10
    "weapon_rifle_sg552",    // Level 11
    "weapon_autoshotgun",    // Level 12
    "weapon_shotgun_spas",   // Level 13
    "weapon_hunting_rifle",  // Level 14
    "weapon_sniper_military",// Level 15
    "weapon_sniper_scout",   // Level 16
    "weapon_grenade_launcher", // Level 17
    "weapon_sniper_awp",     // Level 18
    "weapon_rifle_m60",      // Level 19
    "weapon_melee"           // Final level - melee weapon (knife/katana/crowbar)
};

// Array to store randomized Gun Game weapon order
char g_sRandomizedGunGameWeapons[sizeof(g_sGunGameWeapons)][32];

public Plugin myinfo = 
{
    name = "PvP Modes",
    author = "Mezo123451A",
    description = "PvP modes with respawns and warmup",
    version = "2.1.2",
    url = ""
};

bool SetGlowSendProp(int entity, const char[] prop, int value)
{
    if (!IsValidEntity(entity))
        return false;

    char netclass[64];
    if (!GetEntityNetClass(entity, netclass, sizeof(netclass)))
        return false;

    if (FindSendPropInfo(netclass, prop) < 1)
        return false;

    SetEntProp(entity, Prop_Send, prop, value);
    return true;
}

void SendKillcamGlowConVar(int client, bool enabled)
{
    if (g_hGlowEnable == null || !IsValidClient(client) || IsFakeClient(client))
        return;

    SendConVarValue(client, g_hGlowEnable, enabled ? "1" : "0");
}

void SetControlledGlowRendering(bool enabled)
{
    if (g_hGlowEnable == null)
        return;

    g_hGlowEnable.IntValue = enabled ? 1 : 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && !IsFakeClient(i))
        {
            SendConVarValue(i, g_hGlowEnable, enabled ? "1" : "0");
        }
    }
}

bool IsControlledGlowModeActive()
{
    return g_bPvPActive || g_bOneShotMode || g_bFFAActive || g_bAWPActive || g_bGunGameActive;
}

void SuppressClimbPluginGlow()
{
    if (g_hClimbGlow == null)
    {
        g_hClimbGlow = FindConVar("l4d_climb_glow");
    }

    if (g_hClimbGlow == null)
        return;

    if (!g_bSavedClimbGlow)
    {
        g_iSavedClimbGlow = g_hClimbGlow.IntValue;
        g_bSavedClimbGlow = true;
    }

    if (g_hClimbGlow.IntValue != 0)
    {
        g_hClimbGlow.IntValue = 0;
    }
}

void RestoreClimbPluginGlow()
{
    if (!g_bSavedClimbGlow)
        return;

    if (g_hClimbGlow == null)
    {
        g_hClimbGlow = FindConVar("l4d_climb_glow");
    }

    if (g_hClimbGlow != null)
    {
        g_hClimbGlow.IntValue = g_iSavedClimbGlow;
    }

    g_bSavedClimbGlow = false;
}

void EnsureGlowRefreshTimer()
{
    if (g_hTeamGlowRefreshTimer == null)
    {
        g_hTeamGlowRefreshTimer = CreateTimer(0.5, Timer_RefreshTeamGlows, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }
}

void StopGlowRefreshTimerIfIdle()
{
    if (IsControlledGlowModeActive())
        return;

    if (g_hTeamGlowRefreshTimer != null)
    {
        KillTimer(g_hTeamGlowRefreshTimer);
        g_hTeamGlowRefreshTimer = null;
    }

    RestoreClimbPluginGlow();
    SetControlledGlowRendering(false);
}

bool IsPvPGlowProxy(int entity)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_iKillcamGlowProxy[i] != 0 && EntRefToEntIndex(g_iKillcamGlowProxy[i]) == entity)
            return true;

        if (g_iTeamGlowProxy[i] != 0 && EntRefToEntIndex(g_iTeamGlowProxy[i]) == entity)
            return true;
    }

    return false;
}

void DisableNonPvPGlows()
{
    int maxEnts = GetMaxEntities();
    for (int entity = 1; entity < maxEnts; entity++)
    {
        DisableGlowForEntity(entity);
    }
}

void DisableGlowForEntity(int entity)
{
    if (!IsValidEntity(entity) || IsPvPGlowProxy(entity))
        return;

    ClearGlowProps(entity);
}

public Action Timer_DisableEntityGlow(Handle timer, any entityRef)
{
    int entity = EntRefToEntIndex(entityRef);
    if (entity != INVALID_ENT_REFERENCE)
    {
        DisableGlowForEntity(entity);
    }
    return Plugin_Stop;
}

int GetTeamGlowProxy(int target)
{
    if (target < 1 || target > MaxClients || g_iTeamGlowProxy[target] == 0)
        return -1;

    int entity = EntRefToEntIndex(g_iTeamGlowProxy[target]);
    if (entity == INVALID_ENT_REFERENCE)
    {
        g_iTeamGlowProxy[target] = 0;
        g_iTeamGlowProxyTeam[target] = -1;
        g_bTeamGlowExternal[target] = false;
        return -1;
    }

    return entity;
}

void ClearGlowProps(int entity)
{
    if (!IsValidEntity(entity))
        return;

    SetGlowSendProp(entity, "m_bSurvivorGlowEnabled", 0);
    SetGlowSendProp(entity, "m_iGlowType", 0);
    SetGlowSendProp(entity, "m_glowColorOverride", 0);
    SetGlowSendProp(entity, "m_nGlowRange", 0);
    SetGlowSendProp(entity, "m_nGlowRangeMin", 0);
    SetGlowSendProp(entity, "m_bFlashing", 0);
}

void ScrubVanillaSurvivorGlows()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
        {
            ClearGlowProps(i);
        }
    }
}

void ApplyTeamGlowProps(int entity)
{
    if (!IsValidEntity(entity))
        return;

    SetGlowSendProp(entity, "m_iGlowType", GLOW_CONSTANT);
    SetGlowSendProp(entity, "m_glowColorOverride", TEAM_GLOW_COLOR);
    SetGlowSendProp(entity, "m_nGlowRange", 0);
    SetGlowSendProp(entity, "m_nGlowRangeMin", 0);
    SetGlowSendProp(entity, "m_bFlashing", 0);
}

int FindClimbCloneForTarget(int target)
{
    if (!CanHaveTeamGlow(target))
        return -1;

    char targetModel[PLATFORM_MAX_PATH];
    GetEntPropString(target, Prop_Data, "m_ModelName", targetModel, sizeof(targetModel));
    if (targetModel[0] == '\0')
    {
        GetClientModel(target, targetModel, sizeof(targetModel));
    }

    if (targetModel[0] == '\0')
        return -1;

    float targetPos[3];
    GetClientAbsOrigin(target, targetPos);

    int bestClone = -1;
    float bestDistance = CLIMB_GLOW_SEARCH_RADIUS;
    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "prop_dynamic_override")) != -1)
    {
        if (!IsValidEntity(entity))
            continue;

        bool currentExternalGlow = g_bTeamGlowExternal[target] && g_iTeamGlowProxy[target] != 0 && EntRefToEntIndex(g_iTeamGlowProxy[target]) == entity;
        if (IsPvPGlowProxy(entity) && !currentExternalGlow)
            continue;

        char entityModel[PLATFORM_MAX_PATH];
        GetEntPropString(entity, Prop_Data, "m_ModelName", entityModel, sizeof(entityModel));
        if (!StrEqual(entityModel, targetModel, false))
            continue;

        float entityPos[3];
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityPos);
        float distance = GetVectorDistance(targetPos, entityPos);
        if (distance < bestDistance)
        {
            bestClone = entity;
            bestDistance = distance;
        }
    }

    return bestClone;
}

void RemoveTeamGlow(int target)
{
    int proxy = GetTeamGlowProxy(target);
    if (proxy != -1 && IsValidEntity(proxy))
    {
        AcceptEntityInput(proxy, "ClearParent");
        AcceptEntityInput(proxy, "Kill");
        if (IsValidEntity(proxy))
        {
            RemoveEntity(proxy);
        }
    }

    if (target >= 1 && target <= MaxClients)
    {
        g_iTeamGlowProxy[target] = 0;
        g_iTeamGlowProxyTeam[target] = -1;
        g_bTeamGlowExternal[target] = false;
    }
}

void RemoveAllTeamGlows()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        RemoveTeamGlow(i);
        SendKillcamGlowConVar(i, false);
    }
}

void CleanupOrphanPvPGlowProxies()
{
    char classname[64];
    char model[PLATFORM_MAX_PATH];
    int maxEnts = GetMaxEntities();

    for (int entity = MaxClients + 1; entity < maxEnts; entity++)
    {
        if (!IsValidEntity(entity) || IsPvPGlowProxy(entity))
            continue;

        GetEntityClassname(entity, classname, sizeof(classname));
        if (!StrEqual(classname, "commentary_dummy", false) && !StrEqual(classname, "prop_dynamic", false))
            continue;

        GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
        if (StrContains(model, "models/survivors/", false) == -1)
            continue;

        AcceptEntityInput(entity, "ClearParent");
        AcceptEntityInput(entity, "Kill");
        if (IsValidEntity(entity))
        {
            RemoveEntity(entity);
        }
    }
}

bool CanHaveTeamGlow(int target)
{
    return g_bPvPActive
        && IsValidClient(target)
        && IsPlayerAlive(target)
        && GetClientTeam(target) == TEAM_SURVIVOR
        && g_iPlayerTeam[target] >= 0
        && g_iPlayerTeam[target] < MAX_TEAMS;
}

bool CanSeeTeamGlow(int target, int viewer)
{
    return CanHaveTeamGlow(target)
        && g_iTeamGlowProxyTeam[target] == g_iPlayerTeam[target]
        && IsValidClient(viewer)
        && !IsFakeClient(viewer)
        && viewer != target
        && !g_bInKillcam[viewer]
        && GetClientTeam(viewer) == TEAM_SURVIVOR
        && g_iPlayerTeam[viewer] == g_iPlayerTeam[target];
}

void CreateTeamGlow(int target)
{
    RemoveTeamGlow(target);

    if (!CanHaveTeamGlow(target))
        return;

    int climbClone = FindClimbCloneForTarget(target);
    int parent = (climbClone != -1) ? climbClone : target;

    char model[PLATFORM_MAX_PATH];
    GetEntPropString(target, Prop_Data, "m_ModelName", model, sizeof(model));
    if (model[0] == '\0')
    {
        GetClientModel(target, model, sizeof(model));
    }

    if (model[0] == '\0')
        return;

    PrecacheModel(model, true);

    int proxy = CreateEntityByName("commentary_dummy");
    if (proxy == -1)
        return;

    SetEntityModel(proxy, model);
    SetEntProp(proxy, Prop_Send, "m_fEffects", EF_BONEMERGE | EF_NOSHADOW | EF_PARENT_ANIMATES);
    SetEntityRenderMode(proxy, RENDER_TRANSCOLOR);
    SetEntityRenderColor(proxy, 255, 255, 255, 0);

    SetVariantString("!activator");
    AcceptEntityInput(proxy, "SetParent", parent);

    float zero[3] = {0.0, 0.0, 0.0};
    TeleportEntity(proxy, zero, zero, NULL_VECTOR);

    if (climbClone != -1)
    {
        ClearGlowProps(climbClone);
    }
    ApplyTeamGlowProps(proxy);

    g_iTeamGlowProxy[target] = EntIndexToEntRef(proxy);
    g_iTeamGlowProxyTeam[target] = g_iPlayerTeam[target];
    g_bTeamGlowExternal[target] = (climbClone != -1);
    SDKHook(proxy, SDKHook_SetTransmit, Hook_TeamGlowTransmit);
}

void RefreshTeamGlows()
{
    if (!IsControlledGlowModeActive())
    {
        RemoveAllTeamGlows();
        SetControlledGlowRendering(false);
        RestoreClimbPluginGlow();
        return;
    }

    SetControlledGlowRendering(true);
    SuppressClimbPluginGlow();
    CleanupOrphanPvPGlowProxies();
    DisableNonPvPGlows();
    ScrubVanillaSurvivorGlows();

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && !IsFakeClient(i))
        {
            SendKillcamGlowConVar(i, true);
        }

        if (!g_bPvPActive || !CanHaveTeamGlow(i))
        {
            RemoveTeamGlow(i);
            continue;
        }

        bool shouldUseExternal = (FindClimbCloneForTarget(i) != -1);
        if (GetTeamGlowProxy(i) == -1 || g_iTeamGlowProxyTeam[i] != g_iPlayerTeam[i] || g_bTeamGlowExternal[i] != shouldUseExternal)
        {
            CreateTeamGlow(i);
        }
    }
}

public Action Timer_RefreshTeamGlows(Handle timer)
{
    if (!IsControlledGlowModeActive())
    {
        g_hTeamGlowRefreshTimer = null;
        RemoveAllTeamGlows();
        RestoreClimbPluginGlow();
        SetControlledGlowRendering(false);
        return Plugin_Stop;
    }

    RefreshTeamGlows();
    return Plugin_Continue;
}

public Action Timer_RebuildTeamGlows(Handle timer, any data)
{
    if (!g_bPvPActive)
        return Plugin_Stop;

    RemoveAllTeamGlows();
    CleanupOrphanPvPGlowProxies();
    RefreshTeamGlows();
    return Plugin_Stop;
}

public Action Hook_TeamGlowTransmit(int entity, int client)
{
    if (client < 1 || client > MaxClients)
        return Plugin_Handled;

    for (int target = 1; target <= MaxClients; target++)
    {
        if (g_iTeamGlowProxy[target] == 0)
            continue;

        if (EntRefToEntIndex(g_iTeamGlowProxy[target]) != entity)
            continue;

        if (g_iTeamGlowProxyTeam[target] != g_iPlayerTeam[target])
            return Plugin_Handled;

        return CanSeeTeamGlow(target, client) ? Plugin_Continue : Plugin_Handled;
    }

    return Plugin_Handled;
}

public void OnGameFrame()
{
    if (!IsControlledGlowModeActive())
        return;

    static float nextGlowScrub = 0.0;
    float now = GetGameTime();
    if (now < nextGlowScrub)
        return;

    ScrubVanillaSurvivorGlows();
    nextGlowScrub = now + 0.1;
}

int GetKillcamGlowProxy(int client)
{
    if (client < 1 || client > MaxClients || g_iKillcamGlowProxy[client] == 0)
        return -1;

    int entity = EntRefToEntIndex(g_iKillcamGlowProxy[client]);
    if (entity == INVALID_ENT_REFERENCE)
    {
        g_iKillcamGlowProxy[client] = 0;
        return -1;
    }

    return entity;
}

void RemoveKillcamGlow(int client)
{
    int proxy = GetKillcamGlowProxy(client);
    if (proxy != -1 && IsValidEntity(proxy))
    {
        AcceptEntityInput(proxy, "ClearParent");
        AcceptEntityInput(proxy, "Kill");
        if (IsValidEntity(proxy))
        {
            RemoveEntity(proxy);
        }
    }

    if (client >= 1 && client <= MaxClients)
    {
        g_iKillcamGlowProxy[client] = 0;
    }

    SendKillcamGlowConVar(client, false);
}

void CreateKillcamGlow(int victim, int target)
{
    RemoveKillcamGlow(victim);

    if (!IsValidClient(victim) || !IsValidClient(target) || !IsPlayerAlive(target))
        return;

    SetControlledGlowRendering(true);
    SuppressClimbPluginGlow();
    DisableNonPvPGlows();

    char model[PLATFORM_MAX_PATH];
    GetEntPropString(target, Prop_Data, "m_ModelName", model, sizeof(model));
    if (model[0] == '\0')
    {
        GetClientModel(target, model, sizeof(model));
    }

    if (model[0] == '\0')
        return;

    PrecacheModel(model, true);

    int proxy = CreateEntityByName("commentary_dummy");
    if (proxy == -1)
        return;

    SetEntityModel(proxy, model);
    SetEntProp(proxy, Prop_Send, "m_fEffects", EF_BONEMERGE | EF_NOSHADOW | EF_PARENT_ANIMATES);
    SetEntityRenderMode(proxy, RENDER_TRANSCOLOR);
    SetEntityRenderColor(proxy, 255, 255, 255, 0);

    SetVariantString("!activator");
    AcceptEntityInput(proxy, "SetParent", target);

    float zero[3] = {0.0, 0.0, 0.0};
    TeleportEntity(proxy, zero, zero, NULL_VECTOR);

    SetGlowSendProp(proxy, "m_iGlowType", GLOW_CONSTANT);
    SetGlowSendProp(proxy, "m_glowColorOverride", KILLCAM_GLOW_COLOR);
    SetGlowSendProp(proxy, "m_nGlowRange", 0);
    SetGlowSendProp(proxy, "m_nGlowRangeMin", 0);

    g_iKillcamGlowProxy[victim] = EntIndexToEntRef(proxy);
    SDKHook(proxy, SDKHook_SetTransmit, Hook_KillcamGlowTransmit);

    SendKillcamGlowConVar(victim, true);
}

public Action Hook_KillcamGlowTransmit(int entity, int client)
{
    if (client < 1 || client > MaxClients)
        return Plugin_Handled;

    for (int victim = 1; victim <= MaxClients; victim++)
    {
        if (g_iKillcamGlowProxy[victim] == 0)
            continue;

        if (EntRefToEntIndex(g_iKillcamGlowProxy[victim]) != entity)
            continue;

        if (client == victim && IsValidClient(victim) && g_bInKillcam[victim])
            return Plugin_Continue;

        return Plugin_Handled;
    }

    return Plugin_Handled;
}

stock void StartKillcam(int victim, int attacker)
{
    // Add check for Gun Game mode
    if (g_bGunGameActive && !g_cvGunGameKillcam.BoolValue)
    {
        // If killcam is disabled in Gun Game, just respawn immediately
        L4D_RespawnPlayer(victim);
        g_bSpawnProtection[victim] = true;
        CreateTimer(SPAWN_PROTECTION_TIME, Timer_RemoveSpawnProtection, victim);
        return;
    }
    
    if (!IsValidClient(victim) || !IsValidClient(attacker))
        return;

    RemoveTeamGlow(victim);

    g_bInKillcam[victim] = true;
    g_iKillcamTarget[victim] = attacker;
    g_iActiveKillcams++;
    CreateKillcamGlow(victim, attacker);
    
    // Store death position and angles
    GetClientAbsOrigin(victim, g_fDeathPosition[victim]);
    GetClientAbsAngles(victim, g_fDeathAngles[victim]);
    
    // Set observer mode to free roam (allows us to control the camera)
    SetEntProp(victim, Prop_Send, "m_iObserverMode", 6); // OBS_MODE_ROAMING
    
    // Position camera slightly above and behind death position
    float cameraPos[3];
    float vForward[3];
    GetAngleVectors(g_fDeathAngles[victim], vForward, NULL_VECTOR, NULL_VECTOR);
    cameraPos = g_fDeathPosition[victim];
    cameraPos[2] += 50.0; // Raise camera
    
    // Move camera back slightly
    ScaleVector(vForward, -50.0);
    AddVectors(cameraPos, vForward, cameraPos);
    g_fKillcamAnchor[victim] = cameraPos;
    
    // Teleport observer to camera position
    TeleportEntity(victim, cameraPos, NULL_VECTOR, NULL_VECTOR);
    
    // Create timer to update camera angles at 60Hz
    CreateTimer(0.016, Timer_UpdateKillcam, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    
    // Create timer to end killcam (without restoring glow yet)
    if (g_hKillcamTimer[victim] != null)
    {
        KillTimer(g_hKillcamTimer[victim]);
        g_hKillcamTimer[victim] = null;
    }
    g_hKillcamTimer[victim] = CreateTimer(KILLCAM_TIME, Timer_EndKillcam, victim);
    
    // Show message
    PrintHintText(victim, "Killed by %N - Respawning in %.0f seconds...", attacker, RESPAWN_TIME);
}

public Action Timer_UpdateKillcam(Handle timer, any client)
{
    if (!IsValidClient(client) || !g_bInKillcam[client])
    {
        RemoveKillcamGlow(client);
        return Plugin_Stop;
    }

    if (!IsValidClient(g_iKillcamTarget[client]))
    {
        RemoveKillcamGlow(client);
        return Plugin_Stop;
    }
    
    // Check if player has been respawned - if respawned, stop camera control
    if (IsPlayerAlive(client))
    {
        RemoveKillcamGlow(client);
        return Plugin_Stop;
    }

    static float lastGlowConVarSend[MAXPLAYERS + 1];
    float now = GetGameTime();
    if (now - lastGlowConVarSend[client] >= 0.5)
    {
        DisableNonPvPGlows();
        SendKillcamGlowConVar(client, true);
        lastGlowConVarSend[client] = now;
    }
    
    static float lastCameraAng[MAXPLAYERS+1][3];
    
    // Get killer's position
    float targetPos[3];
    float cameraPos[3];
    float angles[3];
    float vForward[3];
    
    GetClientAbsOrigin(g_iKillcamTarget[client], targetPos);
    GetClientEyeAngles(g_iKillcamTarget[client], angles);
    
    GetAngleVectors(angles, vForward, NULL_VECTOR, NULL_VECTOR);
    float angLerpFactor = 0.12;
    cameraPos = g_fKillcamAnchor[client];
    if (lastCameraAng[client][0] == 0.0 && lastCameraAng[client][1] == 0.0 && lastCameraAng[client][2] == 0.0)
        GetClientEyeAngles(g_iKillcamTarget[client], lastCameraAng[client]);
    
    // Calculate ideal angles to look at killer's head
    float targetEyePos[3];
    GetClientEyePosition(g_iKillcamTarget[client], targetEyePos);
    
    float dirToTarget[3];
    SubtractVectors(targetEyePos, cameraPos, dirToTarget);
    GetVectorAngles(dirToTarget, angles);
    
    // Smooth angle interpolation
    float smoothAngles[3];
    for (int i = 0; i < 3; i++)
    {
        // Handle angle wrapping for smooth interpolation (especially important for yaw)
        float angleDiff = angles[i] - lastCameraAng[client][i];
        
        // Normalize the angle difference to -180/+180 range
        if (angleDiff > 180.0) angleDiff -= 360.0;
        if (angleDiff < -180.0) angleDiff += 360.0;
        
        // Apply smooth lerp with the normalized difference
        smoothAngles[i] = lastCameraAng[client][i] + angleDiff * angLerpFactor;
        
        // Store for next frame
        lastCameraAng[client][i] = smoothAngles[i];
    }
    
    // Add a slight camera roll for more cinematic effect (only a couple degrees)
    smoothAngles[2] = 2.0 * Sine(GetGameTime() * 0.5);
    
    // Apply position and angle to spectator
    TeleportEntity(client, cameraPos, smoothAngles, NULL_VECTOR);
    
    return Plugin_Continue;
}

public Action Timer_EndKillcam(Handle timer, any client)
{
    if (!IsValidClient(client))
        return Plugin_Stop;
    
    // Prepare respawn data first while still in killcam
    bool gunGameActive = g_bGunGameActive;
    bool ffaActive = g_bFFAActive;
    bool pvpActive = g_bPvPActive;
    bool awpActive = g_bAWPActive;
    bool oneShotActive = g_bOneShotMode;
    int team = 0;
    
    if (pvpActive)
    {
        team = g_iPlayerTeam[client];
    }
    
    // Clear killcam timer reference
    g_hKillcamTimer[client] = null;
    
    // IMPORTANT: Respawn the player first before changing any camera settings
    L4D_RespawnPlayer(client);
    
    // Handle different modes - positioning and loadout
    if (gunGameActive)
    {
        TeleportToFFASpawn(client); // Make sure to teleport first
        CreateTimer(0.1, Timer_GiveNextGunGameWeapon, client);
    }
    else if (ffaActive)
    {
        TeleportToFFASpawn(client);
        GiveRandomLoadout(client);
    }
    else if (pvpActive)
    {
        // Use player team data from our plugin
        if (team >= 0 && team < MAX_TEAMS && g_iSpawnCount[team] > 0)
        {
            int spawnIdx = GetRandomInt(0, g_iSpawnCount[team] - 1);
            TeleportEntity(client, g_fSpawnPoints[team][spawnIdx], g_fSpawnAngles[team][spawnIdx], NULL_VECTOR);
        }
        else
        {
            // Fallback to regular spawn method
            TeleportToSpawn(client, team);
        }
        
        GiveRandomLoadout(client);
    }
    else if (awpActive || oneShotActive)
    {
        // Handle AWP and One Shot modes
        TeleportToFFASpawn(client);
        GiveRandomLoadout(client);
    }
    
    // Announce loadout for all players including host with a delay
    CreateTimer(0.7, Timer_ForceAnnounceLoadout, client);
    
    // Enable spawn protection
    g_bSpawnProtection[client] = true;
    SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
    // Add green glow to indicate spawn protection
    SetEntityRenderColor(client, 0, 255, 0, 200); // Green color with slight transparency
    CreateTimer(SPAWN_PROTECTION_TIME, Timer_RemoveSpawnProtection, client);
    
    // Only AFTER respawn and teleporting, now we can end the victim-only killcam glow.
    RemoveKillcamGlow(client);
    
    // End killcam state (do this last to avoid camera jump)
    g_bInKillcam[client] = false;
    g_iKillcamTarget[client] = -1;
    if (g_iActiveKillcams > 0) g_iActiveKillcams--;
    if (g_bPvPActive)
    {
        RefreshTeamGlows();
    }
    else
    {
        SetControlledGlowRendering(false);
    }
    
    return Plugin_Stop;
}

public void OnPluginStart()
{
    // Maximum network optimization settings
    SetConVarInt(FindConVar("net_queued_packet_thread"), 1);
    SetConVarInt(FindConVar("net_splitpacket_maxrate"), 200000);
    SetConVarInt(FindConVar("sv_parallel_packentities"), 1);
    SetConVarInt(FindConVar("sv_maxrate"), 150000);
    SetConVarInt(FindConVar("sv_minrate"), 50000);
    SetConVarInt(FindConVar("sv_maxcmdrate"), 66);
    SetConVarInt(FindConVar("sv_mincmdrate"), 30);
    SetConVarInt(FindConVar("sv_maxupdaterate"), 66);
    SetConVarInt(FindConVar("sv_minupdaterate"), 30);
    SetConVarFloat(FindConVar("net_maxcleartime"), 0.001);
    SetConVarInt(FindConVar("sv_client_min_interp_ratio"), 0);
    SetConVarInt(FindConVar("sv_client_max_interp_ratio"), 1);

    // Initialize randomized weapons array with default progression
    for (int i = 0; i < sizeof(g_sGunGameWeapons); i++)
    {
        strcopy(g_sRandomizedGunGameWeapons[i], sizeof(g_sRandomizedGunGameWeapons[]), g_sGunGameWeapons[i]);
    }

    PrintToServer("[PvP] Loading gamedata file...");
    Handle gamedata = LoadGameConfigFile(GAMEDATA_FILE);
    if (gamedata == null)
    {
        SetFailState("Failed to load gamedata file: %s", GAMEDATA_FILE);
    }
    PrintToServer("[PvP] Gamedata loaded successfully");

    PrintToServer("[PvP] Preparing SDK call...");
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "RoundRespawn");
    g_hSDKRoundRespawn = EndPrepSDKCall();
    delete gamedata;
    PrintToServer("[PvP] SDK call preparation completed");

    if (g_hSDKRoundRespawn == null)
    {
        SetFailState("Failed to create SDKCall for RoundRespawn");
    }
    PrintToServer("[PvP] SDK call created successfully");

    // Initialize ConVar handles
    g_hSpecialSpawnInterval = FindConVar("z_special_spawn_interval");
    g_hCommonLimit = FindConVar("z_common_limit");
    g_hDirectorNoSpecials = FindConVar("director_no_specials");
    g_hDirectorNoMobs = FindConVar("director_no_mobs");
    g_hDirectorNoBosses = FindConVar("director_no_bosses");
    g_hGlowEnable = FindConVar("sv_glowenable");
    g_hClimbGlow = FindConVar("l4d_climb_glow");

    // Find all network-related ConVars
    g_hNetworkOptimize = FindConVar("sv_client_min_interp_ratio");
    g_hUpdateRate = FindConVar("sv_maxupdaterate");
    g_hMaxRate = FindConVar("sv_maxrate");
    g_hMinRate = FindConVar("sv_minrate");
    g_hMaxCmdRate = FindConVar("sv_maxcmdrate");
    g_hMinCmdRate = FindConVar("sv_mincmdrate");
    g_hSplitPacket = FindConVar("net_splitpacket_maxrate");
    g_hMaxClearTime = FindConVar("net_maxcleartime");
    
    // Set optimal values
    if(g_hNetworkOptimize != null) g_hNetworkOptimize.SetInt(0);
    if(g_hUpdateRate != null) g_hUpdateRate.SetInt(30);
    if(g_hMaxRate != null) g_hMaxRate.SetInt(30000);
    if(g_hMinRate != null) g_hMinRate.SetInt(20000);
    if(g_hMaxCmdRate != null) g_hMaxCmdRate.SetInt(30);
    if(g_hMinCmdRate != null) g_hMinCmdRate.SetInt(20);
    if(g_hSplitPacket != null) g_hSplitPacket.SetInt(30000);
    if(g_hMaxClearTime != null) g_hMaxClearTime.SetFloat(0.001);

    g_bMatchEnded = false;

    // Commands
    RegAdminCmd("sm_startpvp", Command_StartPvP, ADMFLAG_ROOT, "Start PvP mode");
    RegAdminCmd("sm_stoppvp", Command_StopPvP, ADMFLAG_ROOT, "Stop PvP mode");
    AddCommandListener(Listener_RawSayCommand, "say");
    AddCommandListener(Listener_RawSayCommand, "say_team");
    RegConsoleCmd("sm_score", Command_ShowScore, "Show current scores");
    RegAdminCmd("sm_addspawn", Command_AddSpawn, ADMFLAG_ROOT, "Add a spawn point for a team");
    RegAdminCmd("sm_deletespawn", Command_DeleteSpawn, ADMFLAG_ROOT, "Delete closest spawn point");
    RegAdminCmd("sm_showspawns", Command_ShowSpawns, ADMFLAG_ROOT, "Show all spawn points");
    RegAdminCmd("sm_savespawns", Command_SaveSpawns, ADMFLAG_ROOT, "Save all spawn points");
    RegAdminCmd("sm_addwarmupspawn", Command_AddWarmupSpawn, ADMFLAG_ROOT, "Add a warmup spawn point");
    RegAdminCmd("sm_showwarmupspawns", Command_ShowWarmupSpawns, ADMFLAG_ROOT, "Show all warmup spawn points");
    RegAdminCmd("sm_savewarmupspawns", Command_SaveWarmupSpawns, ADMFLAG_ROOT, "Save all warmup spawn points");
    RegConsoleCmd("sm_h", Command_Help, "Show available commands");
    RegConsoleCmd("sm_m", Command_TeamMenu, "Show team menu");
    RegConsoleCmd("sm_menu", Command_TeamMenu, "Show team menu");
    RegAdminCmd("sm_spawnbot", Command_SpawnSaferoomBot, ADMFLAG_ROOT, "Spawn a saferoom anchor bot");
    RegAdminCmd("sm_removebot", Command_RemoveSaferoomBot, ADMFLAG_ROOT, "Remove the saferoom anchor bot");
    RegConsoleCmd("sm_switch", Command_SwitchTeam, "Switch to the opposite team if possible");
    RegAdminCmd("sm_startffa", Command_StartFFA, ADMFLAG_ROOT, "Start FFA mode");
    RegAdminCmd("sm_stopffa", Command_StopFFA, ADMFLAG_ROOT, "Stop FFA mode");
    RegAdminCmd("sm_addffa", Command_AddFFASpawn, ADMFLAG_ROOT, "Add a FFA spawn point");
    RegAdminCmd("sm_showffaspawns", Command_ShowFFASpawns, ADMFLAG_ROOT, "Show all FFA spawn points");
    RegAdminCmd("sm_saveffaspawns", Command_SaveFFASpawns, ADMFLAG_ROOT, "Save all FFA spawn points");
    RegAdminCmd("sm_deleteffaspawn", Command_DeleteFFASpawn, ADMFLAG_ROOT, "Delete closest FFA spawn point");
    RegAdminCmd("sm_showallspawnpoints", Command_ShowAllSpawnPoints, ADMFLAG_ROOT, "Show all spawn points persistently until a mode starts");
    RegAdminCmd("sm_startawp", Command_StartAWP, ADMFLAG_ROOT, "Start AWP mode");
    RegAdminCmd("sm_stopawp", Command_StopAWP, ADMFLAG_ROOT, "Stop AWP mode");
    RegConsoleCmd("sm_join", Command_JoinFromIdle, "Join the game from idle state");
    RegConsoleCmd("sm_kill", Command_KillSelf, "Kill yourself when stuck");
    RegAdminCmd("sm_startoneshot", Command_OneShotMode, ADMFLAG_ROOT, "Start One Shot TDM mode");
    RegAdminCmd("sm_stoponeshot", Command_StopOneShotMode, ADMFLAG_ROOT, "Stop One Shot TDM mode");
    RegAdminCmd("sm_startgungame", Command_StartGunGame, ADMFLAG_ROOT, "Start Gun Game mode (FFA with weapon progression)");
    RegAdminCmd("sm_stopgungame", Command_StopGunGame, ADMFLAG_ROOT, "Stop Gun Game mode");

    // ConVars
    g_cvRoundTime = CreateConVar("l4d2_pvp_roundtime", "5400", "Round time in seconds", _, true, 60.0);
    g_cvScoreLimit = CreateConVar("l4d2_pvp_scorelimit", "50", "Score limit to win the match", _, true, 1.0);
    g_cvFFAScoreLimit = CreateConVar("l4d2_ffa_scorelimit", "50", "Score limit to win FFA match", _, true, 1.0);
    g_cvFFARoundTime = CreateConVar("l4d2_ffa_roundtime", "5400", "Round time in seconds for FFA mode", _, true, 60.0);
    g_cvAWPRoundTime = CreateConVar("l4d2_awp_roundtime", "5400", "Round time in seconds for AWP mode", _, true, 60.0);
    g_cvAWPScoreLimit = CreateConVar("l4d2_awp_scorelimit", "50", "Score limit to win AWP match", _, true, 1.0);
    g_cvWarmupEnabled = CreateConVar("l4d2_pvp_warmup_enabled", "1", "Enable/disable warmup phase in PvP modes (0 = disabled, 1 = enabled)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvOneShotScoreLimit = CreateConVar("l4d2_oneshot_scorelimit", "50", "Score limit for One Shot mode");
    g_cvOneShotRoundTime = CreateConVar("l4d2_oneshot_roundtime", "5400", "Round time in seconds for One Shot mode", _, true, 60.0);
    g_cvGunGameScoreLimit = CreateConVar("l4d2_gungame_scorelimit", "20", "Number of levels to win Gun Game (should match number of weapons in progression)", _, true, 1.0);
    g_hHeadshotDamageMultiplier = CreateConVar("l4d2_pvp_headshot_multiplier", "1.5", "Damage multiplier for headshots (1.0 = normal damage)", _, true, 1.0);
    g_cvGunGameKillcam = CreateConVar("l4d2_gungame_killcam", "1", "Enable killcam in Gun Game mode (0 = disabled, 1 = enabled)", _, true, 0.0, true, 1.0);
    g_cvMusicEnabled = CreateConVar("l4d2_pvp_music_enabled", "1", "Enable music in PvP modes, including admin-menu music (0 = block, 1 = allow)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvMusicVolume = CreateConVar("l4d2_pvp_music_volume", "1.0", "Music volume applied to players when PvP music is enabled", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    // Add hook for Gun Game score limit changes
    g_cvGunGameScoreLimit.AddChangeHook(OnGunGameScoreLimitChanged);
    g_cvMusicEnabled.AddChangeHook(OnMusicSettingsChanged);
    g_cvMusicVolume.AddChangeHook(OnMusicSettingsChanged);

    // Create version ConVar
    CreateConVar("l4d2_pvp_version", PLUGIN_VERSION, "Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);

    // Create and execute the config file
    AutoExecConfig(true, "l4d2_pvp");

    // Initialize scores
    g_iTeamScores[TEAM_A] = 0;
    g_iTeamScores[TEAM_B] = 0;

    // Events
    HookEvent("player_hurt", Event_PlayerHurt);
    AddCommandListener(OnPlayerUse, "+use");
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_death", Event_PlayerDeath_BlockSound); 
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("weapon_fire", Event_WeaponFire);
    HookEvent("player_incapacitated", Event_PlayerIncap);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_first_spawn", Event_PlayerSpawn);
    HookEvent("player_team", Event_PlayerTeam);

    // Load spawn points
    LoadSpawnPoints();
    LoadWarmupSpawns();

    // Precache sprite
    g_iBeamSprite = PrecacheModel(SPRITE_BEAM);
    if (g_iBeamSprite == 0)
    {
        SetFailState("Failed to precache sprite: %s", SPRITE_BEAM);
    }
    PrecacheSound(SOUND_GUN_GAME_LEVEL_UP, true);
    PrecacheSound(SOUND_GUN_GAME_KNIFE_LEVEL, true);
    PrecacheSound(SOUND_PVP_KILL, true);
    PrecacheSound(SOUND_PVP_HEADSHOT_KILL, true);

    CreateTimer(1.0, Timer_KickBots, _, TIMER_REPEAT);

    // Start the switch reminder timer
    if (g_hSwitchReminderTimer != null)
        KillTimer(g_hSwitchReminderTimer);
    g_hSwitchReminderTimer = CreateTimer(GetRandomFloat(30.0, 60.0), Timer_SwitchReminder);

    // Hook damage
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
        {
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
        }
    }

    // Initialize killcam variables
    for (int i = 1; i <= MaxClients; i++)
    {
        g_hKillcamTimer[i] = null;
        g_iKillcamTarget[i] = -1;
        g_bInKillcam[i] = false;
        g_iKillcamGlowProxy[i] = 0;
        g_iTeamGlowProxy[i] = 0;
        g_iTeamGlowProxyTeam[i] = -1;
        g_bTeamGlowExternal[i] = false;
    }
    CleanupOrphanPvPGlowProxies();

    // Precache CSS AWP model
    PrecacheModel(CSS_AWP_MODEL, true);
    PrecacheModel("models/v_models/v_snip_awp.mdl", true);
    
    // Hook the player_death_pre event to prevent weapon drops in Gun Game
    HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);

    // Block survivor voice commands
    AddCommandListener(Command_BlockVoice, "vocalize");
    AddCommandListener(Command_BlockVoice, "SmartLook");
    
    // Hook sound system to block survivor voices and death sounds
    AddNormalSoundHook(NormalSHook);
    
    // Hook MusicCmd user message to block game music commands
    HookUserMessage(GetUserMessageId("MusicCmd"), UserMsg_MusicCmd, true);
    
    // Apply configured music setting.
    ApplyPvPMusicSettings();
    
    // Add this line with the other HookEvent calls
    HookEvent("player_ledge_grab", Event_PlayerLedgeGrab);

    // Add the !yes command for kill request approval
    RegConsoleCmd("sm_yes", Command_ApproveKill, "Approve a pending kill request");

    // Initialize health regeneration variables
    for (int i = 1; i <= MaxClients; i++)
    {
        g_fLastDamageTime[i] = 0.0;
        g_fLastPvPAttackTime[i] = 0.0;
        g_fNextHitMarkerTime[i] = 0.0;
        g_fLastGunGameWeaponMsgTime[i] = -99999.0;
        g_fLastGunGameFinalMsgTime[i] = -99999.0;
        g_hRegenTimer[i] = null;
    }
}

// Shuffle gun game weapons to create a randomized progression
void ShuffleGunGameWeapons()
{
    PrintToServer("[Gun Game] Shuffling weapon progression...");
    
    // First, copy all weapons except the final melee weapon to a temporary array
    int totalWeapons = sizeof(g_sGunGameWeapons);
    int weaponsToShuffle = totalWeapons - 1; // Don't shuffle the last weapon (melee)
    char tempWeapons[sizeof(g_sGunGameWeapons) - 1][32];
    
    for (int i = 0; i < weaponsToShuffle; i++)
    {
        strcopy(tempWeapons[i], sizeof(tempWeapons[]), g_sGunGameWeapons[i]);
    }
    
    // Fisher-Yates shuffle algorithm
    for (int i = weaponsToShuffle - 1; i > 0; i--)
    {
        int j = GetRandomInt(0, i);
        char temp[32];
        strcopy(temp, sizeof(temp), tempWeapons[i]);
        strcopy(tempWeapons[i], sizeof(tempWeapons[]), tempWeapons[j]);
        strcopy(tempWeapons[j], sizeof(tempWeapons[]), temp);
    }
    
    // Copy shuffled weapons to the randomized array
    for (int i = 0; i < weaponsToShuffle; i++)
    {
        strcopy(g_sRandomizedGunGameWeapons[i], sizeof(g_sRandomizedGunGameWeapons[]), tempWeapons[i]);
    }
    
    // Ensure melee weapon is always last
    strcopy(g_sRandomizedGunGameWeapons[totalWeapons - 1], sizeof(g_sRandomizedGunGameWeapons[]), g_sGunGameWeapons[totalWeapons - 1]);
    
    // Debug output
    PrintToServer("[Gun Game] Randomized weapon order:");
    for (int i = 0; i < totalWeapons; i++)
    {
        PrintToServer("  Level %d: %s", i + 1, g_sRandomizedGunGameWeapons[i]);
    }
    
    // Notify players of randomized progression
    PrintToChatAll("\x04[Gun Game] \x01Weapon progression has been \x05randomized\x01 for this round!");
}

public Action Timer_ForceFFASpawn(Handle timer, any client)
{
    if (!IsValidClient(client) || !g_bFFAActive)
        return Plugin_Stop;

    L4D_RespawnPlayer_Custom(client);
    
    // Ensure proper setup
    SetEntProp(client, Prop_Send, "m_survivorCharacter", GetRandomInt(0, 7));
    SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
    SetEntityMoveType(client, MOVETYPE_WALK);
    SetEntityRenderMode(client, RENDER_NORMAL);
    SetEntityRenderColor(client, 255, 255, 255, 255);
    SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
    
    // Double-check if still dead and force respawn again if needed
    if (!IsPlayerAlive(client))
    {
        L4D_RespawnPlayer(client);
        CreateTimer(0.2, Timer_ForceFFASpawn, client);
        return Plugin_Stop;
    }
    
    // Only proceed with loadout and teleport if alive
    if (IsPlayerAlive(client))
    {
        GiveRandomLoadout(client);
        TeleportToFFASpawn(client);
        AnnounceLoadout(client);
        
        // Enable spawn protection
        g_bSpawnProtection[client] = true;
        SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
        // Add green glow to indicate spawn protection
        SetEntityRenderColor(client, 0, 255, 0, 200); // Green color with slight transparency
        CreateTimer(SPAWN_PROTECTION_TIME, Timer_RemoveSpawnProtection, client);
        
        PrintToChat(client, "\x04[FFA] \x01You have joined Free-For-All mode!");
    }
    TeleportToFFASpawn(client);
    GiveRandomLoadout(client);
    return Plugin_Stop;
}

stock bool L4D_RespawnPlayer_Custom(int client)
{
    if (g_hSDKRoundRespawn != null)
    {
        PrintToServer("[FFA Debug] Attempting SDK respawn for %N", client);
        bool result = SDKCall(g_hSDKRoundRespawn, client);
        PrintToServer("[FFA Debug] SDK respawn result for %N: %d", client, result);
        return result;
    }
    PrintToServer("[FFA Debug] SDK respawn handle is null!");
    return false;
}

stock void GetFormattedWeaponName(const char[] weaponName, char[] formattedName, int maxLength)
{
    // Remove "weapon_" prefix if it exists
    char cleanName[32];
    strcopy(cleanName, sizeof(cleanName), weaponName);
    ReplaceString(cleanName, sizeof(cleanName), "weapon_", "");
    
    // Format based on clean weapon name
    if (StrEqual(cleanName, "smg"))
        strcopy(formattedName, maxLength, "Uzi");
    else if (StrEqual(cleanName, "smg_mp5"))
        strcopy(formattedName, maxLength, "MP5");
    else if (StrEqual(cleanName, "smg_silenced"))
        strcopy(formattedName, maxLength, "MAC-10");
    else if (StrEqual(cleanName, "pumpshotgun"))
        strcopy(formattedName, maxLength, "M870");
    else if (StrEqual(cleanName, "shotgun_chrome"))
        strcopy(formattedName, maxLength, "870");
    else if (StrEqual(cleanName, "rifle"))
        strcopy(formattedName, maxLength, "M16");
    else if (StrEqual(cleanName, "rifle_desert"))
        strcopy(formattedName, maxLength, "SCAR");
    else if (StrEqual(cleanName, "rifle_ak47"))
        strcopy(formattedName, maxLength, "AK47");
    else if (StrEqual(cleanName, "rifle_sg552"))
        strcopy(formattedName, maxLength, "SG552");
    else if (StrEqual(cleanName, "autoshotgun"))
        strcopy(formattedName, maxLength, "M1014");
    else if (StrEqual(cleanName, "shotgun_spas"))
        strcopy(formattedName, maxLength, "SPAS");
    else if (StrEqual(cleanName, "hunting_rifle"))
        strcopy(formattedName, maxLength, "M14");
    else if (StrEqual(cleanName, "sniper_military"))
        strcopy(formattedName, maxLength, "G3");
    else if (StrEqual(cleanName, "sniper_scout"))
        strcopy(formattedName, maxLength, "Scout");
    else if (StrEqual(cleanName, "sniper_awp"))
        strcopy(formattedName, maxLength, "AWP");
    else if (StrEqual(cleanName, "pistol"))
        strcopy(formattedName, maxLength, "P220");
    else if (StrEqual(cleanName, "pistol_magnum"))
        strcopy(formattedName, maxLength, "Magnum");
    else if (StrEqual(cleanName, "grenade_launcher"))
        strcopy(formattedName, maxLength, "Grenade Launcher");
    else if (StrEqual(cleanName, "grenade_launcher_projectile"))
        strcopy(formattedName, maxLength, "Grenade Launcher");
    else if (StrEqual(cleanName, "rifle_m60"))
        strcopy(formattedName, maxLength, "M60");
    // Add specific checks for melee weapons
    else if (StrEqual(cleanName, "melee"))
        strcopy(formattedName, maxLength, "melee");
    else if (StrContains(cleanName, "melee") != -1)
        strcopy(formattedName, maxLength, "melee");
    else if (StrContains(cleanName, "katana") != -1)
        strcopy(formattedName, maxLength, "katana");
    else if (StrContains(cleanName, "machete") != -1)
        strcopy(formattedName, maxLength, "machete");
    else if (StrContains(cleanName, "crowbar") != -1)
        strcopy(formattedName, maxLength, "crowbar");
    else if (StrContains(cleanName, "baseball_bat") != -1)
        strcopy(formattedName, maxLength, "baseball_bat");
    else if (StrContains(cleanName, "knife") != -1)
        strcopy(formattedName, maxLength, "knife");
    else if (StrEqual(cleanName, "inferno", false))
        strcopy(formattedName, maxLength, "Molotov");
    else if (StrEqual(cleanName, "pipe_bomb", false))
        strcopy(formattedName, maxLength, "Pipe Bomb");
    else if (StrEqual(cleanName, "prop_minigun_l4d1", false))
        strcopy(formattedName, maxLength, "Minigun");
    else if (StrEqual(cleanName, "prop_minigun", false))
        strcopy(formattedName, maxLength, "Minigun");
    else if (StrEqual(cleanName, "prop_minigun_l4d2", false))
        strcopy(formattedName, maxLength, "Minigun");
    
    else
        strcopy(formattedName, maxLength, cleanName);
        
    // Debug output for melee weapons
    if (StrContains(cleanName, "melee") != -1 || StrContains(formattedName, "melee") != -1 ||
        StrContains(cleanName, "katana") != -1 || StrContains(formattedName, "katana") != -1 ||
        StrContains(cleanName, "machete") != -1 || StrContains(formattedName, "machete") != -1 ||
        StrContains(cleanName, "crowbar") != -1 || StrContains(formattedName, "crowbar") != -1 ||
        StrContains(cleanName, "baseball") != -1 || StrContains(formattedName, "baseball") != -1 ||
        StrContains(cleanName, "knife") != -1 || StrContains(formattedName, "knife") != -1)
    {
        PrintToServer("[Melee Debug] Original weapon: '%s', Clean name: '%s', Formatted name: '%s'", 
            weaponName, cleanName, formattedName);
    }
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (g_bMatchEnded || g_bWarmupActive)
        return Plugin_Continue;

    int victim = GetClientOfUserId(event.GetInt("userid"));
    int eventAttacker = GetClientOfUserId(event.GetInt("attacker"));
    int trackedAttacker = (victim >= 0 && victim <= MaxClients) ? g_iLastAttacker[victim] : 0;
    bool hasRecentTrackedAttacker = IsValidClient(trackedAttacker) &&
        trackedAttacker != victim &&
        victim >= 0 &&
        victim <= MaxClients &&
        (GetGameTime() - g_fLastPvPAttackTime[victim]) <= LAST_ATTACKER_CREDIT_TIME;

    int attacker = eventAttacker;
    if ((!IsValidClient(attacker) || attacker == victim) && hasRecentTrackedAttacker)
    {
        attacker = trackedAttacker;
    }
    else if (IsValidClient(victim) && IsValidClient(attacker) && attacker != victim)
    {
        g_iLastAttacker[victim] = attacker;
        g_fLastPvPAttackTime[victim] = GetGameTime();
    }
    
    // Check if this was a self-kill via command
    if (IsValidClient(victim) && g_bSelfKilled[victim])
    {
        // Reset the flag so no kill is counted for anyone
        g_bSelfKilled[victim] = false;
        
        // Override the attacker to be the victim (self-kill) to prevent kill credits
        g_iLastAttacker[victim] = victim;
        attacker = victim;
    }

    // Reset knife level setup flag on death
    if (IsValidClient(victim))
    {
        g_bKnifeLevelSetup[victim] = false;
    }
    
    // Allow respawn even for suicides/world deaths
    if (!IsValidClient(victim))
        return Plugin_Continue;

    if (IsValidClient(attacker) && attacker != victim && ShouldShowHitMarker(attacker, victim, 1))
    {
        bool killWasHeadshot = g_bLastHitWasHeadshot[victim];
        ShowHitMarker(attacker, victim, killWasHeadshot, true);
        EmitSoundToClient(attacker, killWasHeadshot ? SOUND_PVP_HEADSHOT_KILL : SOUND_PVP_KILL);
    }

    g_bLastHitWasHeadshot[victim] = false;

    SchedulePostDeathRespawnVerify(victim, RESPAWN_VERIFY_DELAY, 0);

    // Create respawn timer regardless of death type
    DataPack respawnPack = new DataPack();
    respawnPack.WriteCell(GetClientUserId(victim));
    CreateTimer(RESPAWN_TIME, Timer_RespawnPlayer, respawnPack, TIMER_DATA_HNDL_CLOSE);

    // Only process kill stats if it's a valid kill
    if (IsValidClient(attacker) && attacker != victim)
{
    // Start killcam - this will handle the respawn
    StartKillcam(victim, attacker);
}
else
{
    // No valid attacker or self-kill, use basic respawn timer
    DataPack respawnDataPack = CreateDataPack();
    respawnDataPack.WriteCell(GetClientUserId(victim));
    
    // Flag for self-killed players
    if (g_bSelfKilled[victim])
    {
        respawnDataPack.WriteCell(1); // Mark as self-kill
    }
    else
    {
        respawnDataPack.WriteCell(0); // Mark as normal death
    }
    
    CreateTimer(RESPAWN_TIME, Timer_RespawnPlayer, respawnDataPack, TIMER_DATA_HNDL_CLOSE);
}
    {
        char weapon[32];
        event.GetString("weapon", weapon, sizeof(weapon));

        if (g_sLastWeapon[victim][0] == '\0')
        {
            char fallbackWeapon[32];
            strcopy(fallbackWeapon, sizeof(fallbackWeapon), weapon);
            if (fallbackWeapon[0] == '\0' && IsValidClient(attacker))
            {
                GetClientWeapon(attacker, fallbackWeapon, sizeof(fallbackWeapon));
            }

            if (fallbackWeapon[0] != '\0')
            {
                FormatWeaponName(fallbackWeapon, sizeof(fallbackWeapon));
                strcopy(g_sLastWeapon[victim], sizeof(g_sLastWeapon[]), fallbackWeapon);
                strcopy(g_sLastHurtWeapon[victim], sizeof(g_sLastHurtWeapon[]), fallbackWeapon);
            }
        }
        
        // Format weapon name
        char formattedWeapon[32];
        if (g_bAWPActive)
        {
            strcopy(formattedWeapon, sizeof(formattedWeapon), "AWP");
        }
        else
        {
            if (StrEqual(weapon, "weapon_smg"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "Uzi");
            else if (StrEqual(weapon, "weapon_smg_mp5"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "MP5");
            else if (StrEqual(weapon, "weapon_smg_silenced"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "MAC-10");
            else if (StrEqual(weapon, "weapon_pumpshotgun"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "M870");
            else if (StrEqual(weapon, "weapon_shotgun_chrome"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "Chrome 870");
            else if (StrEqual(weapon, "weapon_rifle"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "M16");
            else if (StrEqual(weapon, "weapon_rifle_desert"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "SCAR");
            else if (StrEqual(weapon, "weapon_rifle_ak47"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "AK47");
            else if (StrEqual(weapon, "weapon_rifle_sg552"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "SG552");
            else if (StrEqual(weapon, "weapon_autoshotgun"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "M1014");
            else if (StrEqual(weapon, "weapon_shotgun_spas"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "SPAS");
            else if (StrEqual(weapon, "weapon_hunting_rifle"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "M14");
            else if (StrEqual(weapon, "weapon_sniper_military"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "G3");
            else if (StrEqual(weapon, "weapon_sniper_scout"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "Scout");
            else if (StrEqual(weapon, "weapon_sniper_awp"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "AWP");
            else if (StrEqual(weapon, "weapon_pistol_magnum"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "Magnum");
            else if (StrEqual(weapon, "weapon_pistol"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "P220");
            else if (StrEqual(weapon, "pipe_bomb"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "Pipe Bomb");
            else if (StrEqual(weapon, "molotov"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "Molotov");
            else if (StrEqual(weapon, "grenade_launcher_projectile"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "Grenade Launcher");
            else if (StrEqual(weapon, "melee"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "Knife");
            else if (StrEqual(weapon, "weapon_melee"))
                strcopy(formattedWeapon, sizeof(formattedWeapon), "Knife");
            else
                strcopy(formattedWeapon, sizeof(formattedWeapon), g_sLastHurtWeapon[victim]);
        }

        // IMPORTANT: Process Gun Game-specific kill tracking first if active
if (g_bGunGameActive && IsValidClient(victim) && IsValidClient(attacker) && victim != attacker)
{
    // Start killcam first if enabled
    if (g_cvGunGameKillcam.BoolValue)
    {
        StartKillcam(victim, attacker);
    }
    else
    {
        // If killcam is disabled, create regular respawn timer
        Handle timerPack = CreateDataPack();
        WritePackCell(timerPack, GetClientUserId(victim));
        CreateTimer(RESPAWN_TIME, Timer_RespawnPlayer, timerPack, TIMER_DATA_HNDL_CLOSE);
    }

    char weaponUsed[32];
    event.GetString("weapon", weaponUsed, sizeof(weaponUsed));
    
    // Check if kill was with the knife in Gun Game
    int attackerLevel = g_iGunGameLevel[attacker];
    
    // Debug weapon information
    PrintToServer("[Gun Game Debug] Kill weapon: '%s', LastHurtWeapon: '%s', Attacker level: %d, Max level: %d, Score limit: %d", 
        weaponUsed, g_sLastHurtWeapon[victim], attackerLevel, sizeof(g_sRandomizedGunGameWeapons) - 1, g_cvGunGameScoreLimit.IntValue);
        
    // Additional debug for melee detection
    bool gunGameMeleeKill = StrEqual(weaponUsed, "melee") || 
        StrEqual(weaponUsed, "weapon_melee") || 
        StrContains(g_sLastHurtWeapon[victim], "melee") != -1 ||
        StrContains(g_sLastHurtWeapon[victim], "katana") != -1 ||
        StrContains(g_sLastHurtWeapon[victim], "machete") != -1 ||
        StrContains(g_sLastHurtWeapon[victim], "crowbar") != -1 ||
        StrContains(g_sLastHurtWeapon[victim], "baseball_bat") != -1 ||
        StrContains(g_sLastHurtWeapon[victim], "knife") != -1;
        
    PrintToServer("[Gun Game Debug] isMeleeKill: %d, At knife level: %d", 
        gunGameMeleeKill ? 1 : 0,
        (attackerLevel >= g_cvGunGameScoreLimit.IntValue - 1) ? 1 : 0);
            
            // Force weapon name to be "Knife" if it was a melee kill
            // Define isMeleeKill before using it
            bool isMeleeKill = StrEqual(weaponUsed, "melee") || 
                               StrEqual(weaponUsed, "weapon_melee") ||
                               StrContains(g_sLastHurtWeapon[victim], "melee") != -1 ||
                               StrContains(g_sLastHurtWeapon[victim], "katana") != -1 ||
                               StrContains(g_sLastHurtWeapon[victim], "machete") != -1 ||
                               StrContains(g_sLastHurtWeapon[victim], "crowbar") != -1 ||
                               StrContains(g_sLastHurtWeapon[victim], "baseball_bat") != -1 ||
                               StrContains(g_sLastHurtWeapon[victim], "knife") != -1;
            
            if (isMeleeKill) {
                strcopy(formattedWeapon, sizeof(formattedWeapon), "Knife");
            }
            
            // Increment the player's total kill count BEFORE displaying it
            g_iPlayerKills[attacker]++;
            
            // Display kill message with Gun Game tag
            PrintToChatAll("\x04[Gun Game] \x01%N killed %N with \x04%s \x01(\x04%d kills total\x01)",
                attacker, victim, formattedWeapon, g_iPlayerKills[attacker]);
            
            // Get the maximum level from the score limit ConVar
            int maxLevel = g_cvGunGameScoreLimit.IntValue;
            
            // Check if this is a knife kill at the final level - if so, end the game
            if (isMeleeKill && attackerLevel >= maxLevel - 1)
            {
                // Player got a knife kill at the final level - they win!
                PrintToChatAll("\x04[Gun Game] \x01%N got a knife kill and won the game!", attacker);
                
                // Add direct debug output
                PrintToServer("[DEBUG] KNIFE KILL WIN DETECTED! Ending game immediately!");
                
                // Force immediate game end rather than using a timer
                g_bGunGameActive = false;
                
                // Show winning message to all
                for (int i = 1; i <= MaxClients; i++)
                {
                    if (IsValidClient(i))
                    {
                        PrintCenterText(i, "%N WON THE GAME WITH A KNIFE KILL!", attacker);
                    }
                }
                
                // Call end game functions similar to FFA mode
                PrintToChatAll("\x04[Gun Game] \x01Match ended! %N wins with a knife kill! Total kills: %d", attacker, g_iPlayerKills[attacker]);
                CreateTimer(3.0, Timer_EndFFA, attacker);
                
                return Plugin_Continue;
            }

            // Ensure melee weapons perform one-hit kills in the final level of Gun Game mode
            if (g_bGunGameActive && g_bKnifeOneHitKill && IsValidClient(attacker) && IsValidClient(victim))
            {
                char weaponName[32];
                GetClientWeapon(attacker, weaponName, sizeof(weaponName));

                // Fix one-hit melee kill by checking for any melee weapon
                if (StrEqual(weaponName, "weapon_melee") || 
                    StrContains(weaponName, "melee") != -1 ||
                    StrContains(weaponName, "katana") != -1 ||
                    StrContains(weaponName, "machete") != -1 ||
                    StrContains(weaponName, "crowbar") != -1 ||
                    StrContains(weaponName, "bat") != -1 ||
                    StrContains(weaponName, "knife") != -1)
                {
                    // We can't set damage here, so just print a debug message
                    PrintToServer("[Gun Game] Melee weapon detected in death event for %N", attacker);
                }
            }

            // Adjust the kill count to start at 1 and not reset on level up
            // Increment the kill counter
            if (g_bGunGameActive)
            {
                g_iGunGameKills[attacker]++;
                
                // Level up after reaching KILLS_PER_LEVEL kills
                if (g_iGunGameKills[attacker] >= KILLS_PER_LEVEL)
                {
                    // Level up
                    g_iGunGameLevel[attacker]++;
                    // Don't reset kill counter, instead subtract the required kills
                    g_iGunGameKills[attacker] = g_iGunGameKills[attacker] - KILLS_PER_LEVEL;
                    
                    // Get the maximum level from the score limit ConVar
                    int scoreLimit = g_cvGunGameScoreLimit.IntValue;
                    
                    // Check if player has reached score limit level and set to knife level
                    if (g_iGunGameLevel[attacker] >= scoreLimit - 1)
                    {
                        PrintToChatAll("\x04[Gun Game] \x01%N has reached the score limit level!", attacker);
                        g_iGunGameLevel[attacker] = scoreLimit - 1; // Set to knife level
                        
                        // Play knife level sound for the player who leveled up
                        EmitSoundToClient(attacker, SOUND_GUN_GAME_KNIFE_LEVEL);
                    }
                    else
                    {
                        // Play normal level up sound
                        EmitSoundToClient(attacker, SOUND_GUN_GAME_LEVEL_UP);
                    }
                    
                    // Give new weapon after a short delay
                    CreateTimer(0.1, Timer_GiveNextGunGameWeapon, attacker);
                    
                    // Show level up message
                    char weaponName[32];
                    FormatGunGameWeaponDisplayName(g_sRandomizedGunGameWeapons[g_iGunGameLevel[attacker]], weaponName, sizeof(weaponName));
                    
                    // Format level display with color and details
                    PrintToChat(attacker, "\x04[Gun Game] \x01 Leveled up to %d/%d: \x05%s", 
                        g_iGunGameLevel[attacker] + 1, scoreLimit, weaponName);
                        
                    // Show current progress toward next level with more accurate kill counting
                    if (g_iGunGameLevel[attacker] >= scoreLimit - 1)
                    {
                        // Don't show "need more kills" message for knife level
                        PrintToChat(attacker, "\x04[Gun Game] \x01 You have reached the final level: \x05KNIFE\x01! Get a kill to win!");
                    }
                    else
                    {
                        PrintToChat(attacker, "\x04[Gun Game] \x01 Current weapon (Level %d/%d): %s. Need %d more kills to level up.",
                            g_iGunGameLevel[attacker] + 1, scoreLimit, weaponName, KILLS_PER_LEVEL - g_iGunGameKills[attacker]);
                    }
                }
                else
                {
                    // Show hint text for kill progress
                    PrintHintText(attacker, "Kills: %d/%d for next weapon (%d total)",
                        g_iGunGameKills[attacker], KILLS_PER_LEVEL, g_iPlayerKills[attacker]);
                }
            }
            
            // Return so we don't also process FFA kills
            return Plugin_Continue;
        }

        // Process standard PvP kills if Gun Game is not active
        if (g_bPvPActive)
        {
            // Check if this kill should be counted (not from !kill command)
            if (ShouldCountKill(victim, attacker))
            {
            g_iPlayerKills[attacker]++;
            g_iPlayerDeaths[victim]++;
            
                if (g_iPlayerTeam[attacker] != -1)
                {
                    g_iTeamScores[g_iPlayerTeam[attacker]]++;
                    PrintToChatAll("\x04[TDM] \x01%N \x01killed \x04%N\x01 with \x04%s",
                        attacker, victim, formattedWeapon);
                    PrintToChatAll("\x01(Red: \x04%d\x01 - Blue: \x04%d\x01)",
                        g_iTeamScores[TEAM_A], g_iTeamScores[TEAM_B]);
    
                    if (g_iTeamScores[g_iPlayerTeam[attacker]] >= g_cvScoreLimit.IntValue)
                    {
                        PrintToChatAll("\x04[TDM] \x01Match ended!");
                        PrintToChatAll("\x01(Red: \x04%d\x01 - Blue: \x04%d\x01)",
                            g_iTeamScores[TEAM_A], g_iTeamScores[TEAM_B]);
                        CreateTimer(3.0, Timer_EndMatch, g_iPlayerTeam[attacker]);
                    }
                }
            }
        }
        else if (g_bFFAActive)
        {
            // Check if this kill should be counted (not from !kill command)
            if (ShouldCountKill(victim, attacker))
            {
                g_iPlayerKills[attacker]++;
                g_iPlayerDeaths[victim]++;
                g_iFFAKills[attacker]++;
            
                PrintToChatAll("\x04[FFA] \x01%N killed %N with \x04%s \x01(\x04%d kills\x01)",
                    attacker, victim, formattedWeapon, g_iFFAKills[attacker]);
                
                if (g_iFFAKills[attacker] >= g_cvFFAScoreLimit.IntValue)
                {
                    PrintToChatAll("\x04[FFA] \x01Match ended! %N wins with \x04%d\x01 kills!",
                        attacker, g_iFFAKills[attacker]);
                    CreateTimer(3.0, Timer_EndFFA, attacker);
                }
            }
        }
        else if (g_bAWPActive)
        {
            // Check if this kill should be counted (not from !kill command)
            if (ShouldCountKill(victim, attacker))
            {
                g_iPlayerKills[attacker]++;
                g_iPlayerDeaths[victim]++;
                g_iAWPKills[attacker]++;
            
                // Use AWP tag for kill messages
                PrintToChatAll("\x04[AWP] \x01%N killed %N with \x04%s \x01(\x04%d kills\x01)",
                    attacker, victim, formattedWeapon, g_iAWPKills[attacker]);
                
                if (g_iAWPKills[attacker] >= g_cvAWPScoreLimit.IntValue)
                {
                    PrintToChatAll("\x04[AWP] \x01Match ended! %N wins with \x04%d\x01 kills!",
                        attacker, g_iAWPKills[attacker]);
                    CreateTimer(3.0, Timer_EndAWP, attacker);
                }
            }
        }
    }
    
    // Always create respawn timer regardless of death type
    DataPack dp = new DataPack();
    dp.WriteCell(GetClientUserId(victim));
    CreateTimer(RESPAWN_TIME, Timer_RespawnPlayer, dp, TIMER_DATA_HNDL_CLOSE);
    
    // Only start killcam for valid kills
    if (IsValidClient(attacker) && attacker != victim)
    {
        StartKillcam(victim, attacker);
    }
    
    // Handle Gun Game-specific death event
    if (g_bGunGameActive && IsValidClient(victim) && IsValidClient(attacker) && victim != attacker)
    {
        char weapon[32];
        event.GetString("weapon", weapon, sizeof(weapon));
        
        // Check if kill was with the knife in Gun Game
        int attackerLevel = g_iGunGameLevel[attacker];
        
        // Debug weapon information
        PrintToServer("[Gun Game Debug] Kill weapon: '%s', LastHurtWeapon: '%s', Attacker level: %d, Max level: %d, Score limit: %d", 
            weapon, g_sLastHurtWeapon[victim], attackerLevel, sizeof(g_sRandomizedGunGameWeapons) - 1, g_cvGunGameScoreLimit.IntValue);
        
        // Additional debug for melee detection
        PrintToServer("[Gun Game Debug] isMeleeKill: %d, isLastHurtMelee: %d, At knife level: %d", 
            StrEqual(weapon, "melee") || 
            StrEqual(weapon, "weapon_melee") ? 1 : 0, 
            StrContains(g_sLastHurtWeapon[victim], "melee") != -1 ||
            StrContains(g_sLastHurtWeapon[victim], "katana") != -1 ||
            StrContains(g_sLastHurtWeapon[victim], "machete") != -1 ||
            StrContains(g_sLastHurtWeapon[victim], "crowbar") != -1 ||
            StrContains(g_sLastHurtWeapon[victim], "baseball_bat") != -1 ||
            StrContains(g_sLastHurtWeapon[victim], "knife") != -1 ? 1 : 0, 
            (attackerLevel >= g_cvGunGameScoreLimit.IntValue - 1) ? 1 : 0);
        
        // Basic melee detection for weapon field
        bool isMeleeKill = StrEqual(weapon, "melee") || 
                           StrEqual(weapon, "weapon_melee");
        
        // Additional melee detection based on last hurt weapon
        bool isLastHurtMelee = StrContains(g_sLastHurtWeapon[victim], "melee") != -1 ||
                               StrContains(g_sLastHurtWeapon[victim], "katana") != -1 ||
                               StrContains(g_sLastHurtWeapon[victim], "machete") != -1 ||
                               StrContains(g_sLastHurtWeapon[victim], "crowbar") != -1 ||
                               StrContains(g_sLastHurtWeapon[victim], "baseball_bat") != -1 ||
                               StrContains(g_sLastHurtWeapon[victim], "knife") != -1;
        
        // If attacker used their assigned weapon (especially the knife for final level)
        if (attackerLevel == sizeof(g_sRandomizedGunGameWeapons) - 1 && (isMeleeKill || isLastHurtMelee))
        {
            // Win condition - final kill with knife
            PrintToServer("[Gun Game] WINNER DETECTED! %N got the final knife kill! Weapon: %s, LastHurt: %s", 
                attacker, weapon, g_sLastHurtWeapon[victim]);
                
            PrintToChatAll("\x04[Gun Game] \x01%N got the final knife kill and won the game!", attacker);
            
            // Alert all players with a center message
            for (int i = 1; i <= MaxClients; i++)
            {
                if (IsValidClient(i))
                {
                    PrintCenterText(i, "%N HAS WON GUN GAME WITH A KNIFE KILL!", attacker);
                }
            }
            
            // End the game - use a timer to ensure we don't have any threading issues
            DataPack pack = new DataPack();
            pack.WriteCell(attacker);
            CreateTimer(0.1, Timer_DelayedEndGunGame, pack, TIMER_DATA_HNDL_CLOSE);
            
                 return Plugin_Continue;
            }
        
        // For all other valid kills, increment the kill counter
        g_iPlayerKills[attacker]++; // Add player kill count here BEFORE displaying it
        g_iGunGameKills[attacker]++;
        
        // Level up after reaching KILLS_PER_LEVEL kills
        if (g_iGunGameKills[attacker] >= KILLS_PER_LEVEL)
        {
            // Level up
            g_iGunGameLevel[attacker]++;
            // Don't reset kill counter, instead subtract the required kills
            g_iGunGameKills[attacker] = g_iGunGameKills[attacker] - KILLS_PER_LEVEL;
            
            // Cap at max level
            if (g_iGunGameLevel[attacker] >= sizeof(g_sRandomizedGunGameWeapons))
                g_iGunGameLevel[attacker] = sizeof(g_sRandomizedGunGameWeapons) - 1;
                
            // Check if player has reached score limit level and end the game if so
            if (g_iGunGameLevel[attacker] >= g_cvGunGameScoreLimit.IntValue - 1)
            {
                PrintToChatAll("\x04[Gun Game] \x01%N has reached the score limit level!", attacker);
                g_iGunGameLevel[attacker] = sizeof(g_sRandomizedGunGameWeapons) - 1; // Set to knife level
            }
            
            // Play level up sound - use knife level sound if reached knife level
            if (g_iGunGameLevel[attacker] == sizeof(g_sRandomizedGunGameWeapons) - 1)
            {
                // Play knife level sound for the player who leveled up
                EmitSoundToClient(attacker, SOUND_GUN_GAME_KNIFE_LEVEL);
            }
            else
            {
                // Play normal level up sound
                EmitSoundToClient(attacker, SOUND_GUN_GAME_LEVEL_UP);
            }
            
            // Give new weapon after a short delay
            CreateTimer(0.1, Timer_GiveNextGunGameWeapon, attacker);
            
            // Show level up message
            char weaponName[32];
            FormatGunGameWeaponDisplayName(g_sRandomizedGunGameWeapons[g_iGunGameLevel[attacker]], weaponName, sizeof(weaponName));
            
            // Show hint text for level up
            PrintHintText(attacker, "LEVEL UP! New weapon: %s\nLevel: %d/%d", 
                weaponName, g_iGunGameLevel[attacker] + 1, sizeof(g_sRandomizedGunGameWeapons));
        }
        else
        {
            // Show hint text for kill progress
            PrintHintText(attacker, "Kills: %d/%d for next weapon (%d total)",
                g_iGunGameKills[attacker], KILLS_PER_LEVEL, g_iPlayerKills[attacker]);
        }
        
        // Update deaths (removed kill counter increment as it's now done at the top)
        g_iPlayerDeaths[victim]++;
    }
    
    return Plugin_Continue; 
}

public Action Timer_SetupFFAPlayer(Handle timer, any client)
{
    if (!IsValidClient(client))
    {
        PrintToServer("[FFA Debug] Timer_SetupFFAPlayer: Invalid client %d", client);
        return Plugin_Stop;
    }

    PrintToServer("[FFA Debug] Setting up FFA player %N", client);

    // Force respawn
    L4D_RespawnPlayer(client);
    
    // Ensure proper setup
    SetEntProp(client, Prop_Send, "m_survivorCharacter", GetRandomInt(0, 7));
    SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
    SetEntityMoveType(client, MOVETYPE_WALK);
    SetEntityRenderMode(client, RENDER_NORMAL);
    SetEntityRenderColor(client, 255, 255, 255, 255);
    SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
    
    // Double-check if still dead and force respawn again if needed
    if (!IsPlayerAlive(client))
    {
        CreateTimer(0.5, Timer_ForceFFASpawn, client);
        return Plugin_Stop;
    }
    
    // Give loadout and teleport
    GiveRandomLoadout(client);
    TeleportToFFASpawn(client);
    AnnounceLoadout(client);
    
    // Enable spawn protection
    g_bSpawnProtection[client] = true;
    SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
    // Add green glow to indicate spawn protection
    SetEntityRenderColor(client, 0, 255, 0, 200); // Green color with slight transparency
    CreateTimer(SPAWN_PROTECTION_TIME, Timer_RemoveSpawnProtection, client);
    
    return Plugin_Stop;
}

public Action Timer_HandleNewPlayer(Handle timer, any client)
{
    if (!IsValidClient(client) || g_bIsJoining[client])
        return Plugin_Stop;
        
    // Force client to join a team
    Command_JoinGame(client, 0);
    return Plugin_Stop;
}

void GiveRandomLoadout(int client)
{
    if (!IsValidClient(client))
        return;
        
    // If in AWP mode, use AWP loadout instead
    if (g_bAWPActive)
    {
        GiveAWPLoadout(client);
        return;
    }

    // Clear existing weapons
    StripWeapons(client);

    // Give random primary weapon
    char primaryWeapon[32];
    strcopy(primaryWeapon, sizeof(primaryWeapon), g_sPrimaryWeapons[GetRandomInt(0, sizeof(g_sPrimaryWeapons) - 1)]);
    
    // Give random secondary weapon
    char secondaryWeapon[32];
    strcopy(secondaryWeapon, sizeof(secondaryWeapon), g_sSecondaryWeapons[GetRandomInt(0, sizeof(g_sSecondaryWeapons) - 1)]);

    // Give the weapons
    GivePlayerItem(client, primaryWeapon);
    GivePlayerItem(client, secondaryWeapon);

    // Give random grenade
    GivePlayerItem(client, g_sGrenades[GetRandomInt(0, sizeof(g_sGrenades) - 1)]);
}

void FormatWeaponName(char[] weapon, int maxLength)
{
    if (StrContains(weapon, "weapon_", false) != -1)
    {
        ReplaceString(weapon, maxLength, "weapon_", "");
    }
    
    if (StrEqual(weapon, "smg", false))
        strcopy(weapon, maxLength, "Uzi");
    else if (StrEqual(weapon, "smg_mp5", false))
        strcopy(weapon, maxLength, "MP5");
    else if (StrEqual(weapon, "smg_silenced", false))
        strcopy(weapon, maxLength, "MAC-10");
    else if (StrEqual(weapon, "pumpshotgun", false))
        strcopy(weapon, maxLength, "M870");
    else if (StrEqual(weapon, "shotgun_chrome", false))
        strcopy(weapon, maxLength, "Chrome 870");
    else if (StrEqual(weapon, "rifle", false))
        strcopy(weapon, maxLength, "M16");
    else if (StrEqual(weapon, "rifle_desert", false))
        strcopy(weapon, maxLength, "SCAR");
    else if (StrEqual(weapon, "rifle_ak47", false))
        strcopy(weapon, maxLength, "AK47");
    else if (StrEqual(weapon, "rifle_sg552", false))
        strcopy(weapon, maxLength, "SG552");
    else if (StrEqual(weapon, "autoshotgun", false))
        strcopy(weapon, maxLength, "M1014");
    else if (StrEqual(weapon, "shotgun_spas", false))
        strcopy(weapon, maxLength, "SPAS");
    else if (StrEqual(weapon, "hunting_rifle", false))
        strcopy(weapon, maxLength, "M14");
    else if (StrEqual(weapon, "sniper_military", false))
        strcopy(weapon, maxLength, "G3");
    else if (StrEqual(weapon, "sniper_scout", false))
        strcopy(weapon, maxLength, "Scout");
    else if (StrEqual(weapon, "sniper_awp", false))
        strcopy(weapon, maxLength, "AWP");
    else if (StrEqual(weapon, "pistol", false))
        strcopy(weapon, maxLength, "P220");
    else if (StrEqual(weapon, "pistol_magnum", false))
        strcopy(weapon, maxLength, "Magnum");
    else if (StrEqual(weapon, "grenade_launcher", false))
        strcopy(weapon, maxLength, "Grenade Launcher");
    else if (StrEqual(weapon, "grenade_launcher_projectile", false))
        strcopy(weapon, maxLength, "Grenade Launcher");
    else if (StrEqual(weapon, "rifle_m60", false))
        strcopy(weapon, maxLength, "M60");
    else if (StrEqual(weapon, "pipe_bomb", false))
        strcopy(weapon, maxLength, "Pipe Bomb");
    else if (StrEqual(weapon, "molotov", false))
        strcopy(weapon, maxLength, "Molotov");
    else if (StrEqual(weapon, "prop_minigun_l4d1", false))
        strcopy(weapon, maxLength, "Minigun");
    else if (StrEqual(weapon, "prop_minigun", false))
        strcopy(weapon, maxLength, "Minigun");
    else if (StrEqual(weapon, "prop_minigun_l4d2", false))
        strcopy(weapon, maxLength, "Minigun");
}

void FormatGunGameWeaponDisplayName(const char[] weaponId, char[] displayName, int maxLength)
{
    strcopy(displayName, maxLength, weaponId);
    if (displayName[0] == '\0')
    {
        strcopy(displayName, maxLength, "Unknown");
        return;
    }

    if (StrEqual(displayName, "weapon_melee", false) || StrEqual(displayName, "melee", false))
    {
        strcopy(displayName, maxLength, "KNIFE");
        return;
    }

    GetFormattedWeaponName(displayName, displayName, maxLength);

    if (StrEqual(displayName, "870", false))
        strcopy(displayName, maxLength, "M870");

    if (StrEqual(displayName, "melee", false))
        strcopy(displayName, maxLength, "KNIFE");
}

public Action Timer_ForceJoinTeam(Handle timer, any client)
{
    if (!IsValidClient(client) || !g_bPvPActive)
        return Plugin_Stop;

    // Force respawn if dead
    if (!IsPlayerAlive(client))
    {
        L4D_RespawnPlayer(client);
    }

    // Auto-assign to team with fewer players
    int assignedTeam = GetTeamWithFewerPlayers();
    g_iPlayerTeam[client] = assignedTeam;
    ChangeClientTeam(client, TEAM_SURVIVOR);
    
    // Set team colors
    if (assignedTeam == TEAM_A)
    {
        SetEntityRenderColor(client, 255, 0, 0, 255);  // Red
        PrintToChatAll("\x04[PvP] \x01%N has joined the \x04RED\x01 team!", client);
    }
    else
    {
        SetEntityRenderColor(client, 0, 0, 255, 255);  // Blue
        PrintToChatAll("\x04[PvP] \x01%N has joined the \x03BLUE\x01 team!", client);
    }
    
    // Give loadout and teleport with a slight delay
    CreateTimer(0.1, Timer_GiveLoadout, client);
    CreateTimer(0.2, Timer_TeleportAndEquip, client);
    
    PrintToChat(client, "\x04[PvP] \x01Welcome to PvP mode!");
    return Plugin_Stop;
}

public Action Timer_InitialTeleport(Handle timer)
{
    // Teleport all players to warmup spawns
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && g_iPlayerTeam[i] != -1)
        {
            TeleportToWarmupSpawn(i);
            
            // Enable god mode during warmup
            SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
        }
    }
    return Plugin_Stop;
}



public Action Timer_FFARoundEnd(Handle timer)
{
    if (!g_bFFAActive)
        return Plugin_Stop;

    // Find the player with the most kills
    int winner = -1;
    int highestKills = -1;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && g_iFFAKills[i] > highestKills)
        {
            highestKills = g_iFFAKills[i];
            winner = i;
        }
    }

    // Announce winner
    if (winner != -1)
    {
        PrintToChatAll("\x04[FFA] \x01Time's up! \x04%N\x01 wins with \x04%d\x01 kills!", 
            winner, g_iFFAKills[winner]);
    }
    else
    {
        PrintToChatAll("\x04[FFA] \x01Time's up! No winner!");
    }

    // End FFA mode
    g_hFFARoundTimer = null;
    CreateTimer(3.0, Timer_EndFFA, winner);
    
    return Plugin_Stop;
}

public Action Timer_ExecuteJoinGame(Handle timer, any client)
{
    if (IsValidClient(client))
    {
        Command_JoinGame(client, 0);
    }
    return Plugin_Stop;
}

public Action Timer_KickBots(Handle timer)
{
    if (!g_bPvPActive && !g_bFFAActive && !g_bAWPActive)  // Add AWP mode check
        return Plugin_Continue;
        
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsFakeClient(i) && i != g_iSaferoomBot)
        {
            KickClient(i, "Bots are not allowed in PvP/FFA/AWP modes");
        }
    }
    
    return Plugin_Continue;
}

void JoinTeam(int client, int team)
{
    if (!IsValidClient(client))
        return;
        
    // Prevent joining if already on this team
    if (g_iPlayerTeam[client] == team)
    {
        PrintToChat(client, "\x04[TDM] \x01You are already on this team!");
        return;
    }
    
    g_iPlayerTeam[client] = team;
    g_bIsJoining[client] = true;
    
    // Set team colors
    if (team == TEAM_A)
    {
        SetEntityRenderColor(client, 255, 0, 0, 255);  // Red
        PrintToChatAll("\x04[TDM] \x01Player \x04%N\x01 has joined the \x04 RED\x01 team!", client);
    }
    else
    {
        SetEntityRenderColor(client, 0, 0, 255, 255);  // Blue
        PrintToChatAll("\x04[TDM] \x01Player \x04%N\x01 has joined the \x03 BLUE\x01 team!", client);
    }
    
    // Respawn player with new team
    ChangeClientTeam(client, TEAM_SURVIVOR);
    L4D_RespawnPlayer(client);
    CreateTimer(0.2, Timer_TeleportAndEquip, client);
    
    // Reset joining flag after a short delay
    CreateTimer(1.0, Timer_ResetJoiningFlag, client);
}

public int MenuHandler_TeamMenu(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            if (!g_bPvPActive)
                return 0;
                
            char info[32];
            menu.GetItem(param2, info, sizeof(info));
            
            if (StrEqual(info, "red"))
            {
                JoinTeam(param1, TEAM_A);
            }
            else if (StrEqual(info, "blue"))
            {
                JoinTeam(param1, TEAM_B);
            }
            else if (StrEqual(info, "spec"))
            {
                // Handle spectator mode if implemented
                PrintToChat(param1, "\x04[PvP] \x01Spectator mode not implemented yet!");
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

public Action Command_Menu(int client, int args)
{
    if (!g_bPvPActive && !g_bFFAActive)
    {
        PrintToChat(client, "\x04[PvP] \x01No game mode is currently active!");
        return Plugin_Handled;
    }
    
    if (g_bFFAActive)
    {
        // Show FFA scores
        PrintToChat(client, "\x04[FFA] \x01 Current Scores:");
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i))
            {
                PrintToChat(client, "\x04%N\x01: %d kills", i, g_iFFAKills[i]);
            }
        }
        
        // Show time remaining if round timer is active
        if (g_hFFARoundTimer != null)
        {
            int timeLeft = g_cvFFARoundTime.IntValue - RoundToFloor(GetGameTime() - g_fFFAStartTime);
            if (timeLeft > 0)
            {
                PrintToChat(client, "\x04[FFA] \x01Time remaining: \x04%d:%02d", timeLeft / 60, timeLeft % 60);
            }
        }
    }
    else if (g_bPvPActive)
    {
        ShowTeamMenu(client);
    }
    
    return Plugin_Handled;
}

public Action Timer_TeleportToWarmup(Handle timer, any client)
{
    if (!IsValidClient(client) || !g_bWarmupActive)
        return Plugin_Stop;
        
    TeleportToWarmupSpawn(client);
    GiveWarmupLoadout(client);
    SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
    return Plugin_Stop;
}

public Action Timer_EndWarmup(Handle timer)
{
    g_bWarmupActive = false;
    
    // Start the actual game
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && !IsFakeClient(i))
        {
            // Make vulnerable again
            SetEntProp(i, Prop_Data, "m_takedamage", 2, 1); 
            if (g_bFFAActive)
            {
                // Teleport to FFA spawn
                CreateTimer(0.2, Timer_TeleportAndEquipFFA, i);
            }
            else if (g_bPvPActive)
            {
                // Teleport to team spawn
                CreateTimer(0.2, Timer_TeleportAndEquip, i);
            }
        }
    }
    
    if (g_bFFAActive)
    {
        PrintToChatAll("\x04[FFA] \x01Warmup phase ended! Game started!");
    }
    else if (g_bPvPActive)
    {
        PrintToChatAll("\x04[TDM] \x01Warmup phase ended! Game started!");
    }
    
    return Plugin_Stop;
}

public Action Command_StopFFA(int client, int args)
{
    if (!g_bFFAActive)
    {
        ReplyToCommand(client, "\x04[FFA] \x01 Free-for-All mode is not active!");
        return Plugin_Handled;
    }
    
    EndFFAMode();
    PrintToChatAll("\x04[FFA] \x01 Free-for-All mode has been stopped by an admin!");
    return Plugin_Handled;
}

public Action Timer_TeleportAndEquipFFA(Handle timer, any client)
{
    if (!IsValidClient(client) || !g_bFFAActive)
        return Plugin_Stop;

    // Make sure player is alive
    if (!IsPlayerAlive(client))
    {
        L4D_RespawnPlayer(client);
        CreateTimer(0.2, Timer_TeleportAndEquipFFA, client);
        return Plugin_Stop;
    }
        
    // Teleport to random FFA spawn
    TeleportToFFASpawn(client);
    
    // Give loadout
    GiveRandomLoadout(client);
    AnnounceLoadout(client);
    
    // No spawn protection or transparency in FFA
    SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);  // Make sure damage is enabled
    SetEntityRenderMode(client, RENDER_NORMAL);  // Normal rendering
    SetEntityRenderColor(client, 255, 255, 255, 255);  // Full opacity
    
    return Plugin_Stop;
}

stock void LoadFFASpawns()
{
    // Always reset spawn count at the beginning of loading
    g_iFFASpawnCount = 0;
    ResetFFASpawnCooldowns();
    
    char path[PLATFORM_MAX_PATH];
    char mapName[64];
    GetCurrentMap(mapName, sizeof(mapName));
    
    char fileName[128];
    Format(fileName, sizeof(fileName), FFA_SPAWN_FILE, mapName);
    BuildPath(Path_SM, path, sizeof(path), fileName);
    
    if (!FileExists(path))
    {
        LogMessage("[FFA] No spawn points file found for map %s", mapName);
        return;
    }
    
    KeyValues kv = new KeyValues("FFASpawnPoints");
    kv.ImportFromFile(path);
    
    if (kv.GotoFirstSubKey())
    {
        do
        {
            kv.GetVector("position", g_fFFASpawnPoints[g_iFFASpawnCount]);
            kv.GetVector("angles", g_fFFASpawnAngles[g_iFFASpawnCount]);
            g_fFFASpawnNextUse[g_iFFASpawnCount] = 0.0;
            g_iFFASpawnCount++;
        } while (kv.GotoNextKey() && g_iFFASpawnCount < MAX_FFA_SPAWNS);
    }
    
    delete kv;
}

bool PrepareGeneratedFFASpawns(const char[] modeName, int client)
{
    if (GenerateAutoFFASpawns())
    {
        PrintToServer("[%s] Generated %d fair FFA spawn points for this map.", modeName, g_iFFASpawnCount);
        return true;
    }

    if (client > 0)
    {
        ReplyToCommand(client, "\x04[%s] \x01Could not generate fair FFA spawns on this map.", modeName);
    }
    PrintToServer("[%s] Failed to generate FFA spawn points for this map.", modeName);
    return false;
}

bool GenerateAutoFFASpawns()
{
    g_iFFASpawnCount = 0;
    ResetFFASpawnCooldowns();

    float anchors[FFA_AUTO_MAX_ANCHORS][3];
    int anchorCount = CollectFFAAutoAnchors(anchors, FFA_AUTO_MAX_ANCHORS);
    if (anchorCount == 0)
    {
        PrintToServer("[FFA] Auto spawn generator found no playable anchors.");
        return false;
    }

    ShuffleFFAAutoAnchors(anchors, anchorCount);
    AddFFASpawnsFromAnchors(anchors, anchorCount, FFA_AUTO_MIN_DISTANCE, true);
    AddFFASpawnsFromAnchors(anchors, anchorCount, FFA_AUTO_MIN_DISTANCE, false);
    AddFFASpawnsFromAnchors(anchors, anchorCount, FFA_AUTO_FALLBACK_DISTANCE, false);
    AddFFASpawnsFromAnchors(anchors, anchorCount, FFA_AUTO_EMERGENCY_DISTANCE, false);

    int attempts = 0;
    while (g_iFFASpawnCount < FFA_AUTO_MIN_GOOD_SPAWNS && attempts < 900)
    {
        attempts++;
        TryCreateRandomFFASpawn(anchors, anchorCount, FFA_AUTO_FALLBACK_DISTANCE, false);
    }

    if (g_iFFASpawnCount > 0 && g_iFFASpawnCount < FFA_AUTO_MIN_GOOD_SPAWNS)
    {
        PrintToServer("[FFA] Auto spawn generator only found %d spawn points; using them anyway.", g_iFFASpawnCount);
    }

    return g_iFFASpawnCount > 0;
}

int CollectFFAAutoAnchors(float anchors[][3], int maxAnchors)
{
    int anchorCount = 0;

    CollectFFAAutoNavAnchors(anchors, maxAnchors, anchorCount);
    if (anchorCount < FFA_AUTO_TARGET_SPAWNS)
    {
        CollectFFAAutoItemAnchors(anchors, maxAnchors, anchorCount);
    }
    return anchorCount;
}

void CollectFFAAutoNavAnchors(float anchors[][3], int maxAnchors, int &anchorCount)
{
    if (GetFeatureStatus(FeatureType_Native, "L4D_GetAllNavAreas") != FeatureStatus_Available ||
        GetFeatureStatus(FeatureType_Native, "L4D_FindRandomSpot") != FeatureStatus_Available)
    {
        return;
    }

    ArrayList areas = new ArrayList();
    L4D_GetAllNavAreas(areas);

    int areaCount = areas.Length;
    if (areaCount <= 0)
    {
        delete areas;
        return;
    }

    float pos[3];
    for (int pass = 0; pass < 2 && anchorCount < maxAnchors; pass++)
    {
        if (pass > 0 && anchorCount >= FFA_AUTO_TARGET_SPAWNS)
            break;

        int startIndex = GetRandomInt(0, areaCount - 1);
        for (int i = 0; i < areaCount && anchorCount < maxAnchors; i++)
        {
            int areaIndex = (startIndex + i) % areaCount;
            Address area = view_as<Address>(areas.Get(areaIndex));
            if (!IsPlayableFFANavArea(area, pass == 0))
                continue;

            L4D_FindRandomSpot(view_as<int>(area), pos);
            pos[2] += 6.0;

            AddFFAAutoAnchor(anchors, maxAnchors, anchorCount, pos);
        }
    }

    delete areas;
}

void ShuffleFFAAutoAnchors(float anchors[][3], int count)
{
    for (int i = count - 1; i > 0; i--)
    {
        int j = GetRandomInt(0, i);
        if (j == i)
            continue;

        float temp[3];
        temp[0] = anchors[i][0];
        temp[1] = anchors[i][1];
        temp[2] = anchors[i][2];

        anchors[i][0] = anchors[j][0];
        anchors[i][1] = anchors[j][1];
        anchors[i][2] = anchors[j][2];

        anchors[j][0] = temp[0];
        anchors[j][1] = temp[1];
        anchors[j][2] = temp[2];
    }
}

void CollectFFAAutoItemAnchors(float anchors[][3], int maxAnchors, int &anchorCount)
{
    static const char anchorClasses[][] =
    {
        "info_survivor_position",
        "info_player_start",
        "weapon_spawn",
        "weapon_pistol_spawn",
        "weapon_pistol_magnum_spawn",
        "weapon_melee_spawn",
        "weapon_first_aid_kit_spawn",
        "weapon_defibrillator_spawn",
        "weapon_pain_pills_spawn",
        "weapon_adrenaline_spawn",
        "weapon_molotov_spawn",
        "weapon_pipe_bomb_spawn",
        "weapon_vomitjar_spawn",
        "weapon_ammo_spawn",
        "weapon_smg",
        "weapon_smg_mp5",
        "weapon_smg_silenced",
        "weapon_pumpshotgun",
        "weapon_shotgun_chrome",
        "weapon_rifle",
        "weapon_rifle_desert",
        "weapon_rifle_ak47",
        "weapon_rifle_sg552",
        "weapon_autoshotgun",
        "weapon_shotgun_spas",
        "weapon_hunting_rifle",
        "weapon_sniper_military",
        "weapon_sniper_scout",
        "weapon_sniper_awp",
        "weapon_rifle_m60",
        "weapon_grenade_launcher",
        "weapon_pistol",
        "weapon_pistol_magnum",
        "weapon_melee",
        "weapon_first_aid_kit",
        "weapon_defibrillator",
        "weapon_pain_pills",
        "weapon_adrenaline",
        "weapon_molotov",
        "weapon_pipe_bomb",
        "weapon_vomitjar"
    };

    float pos[3];
    for (int i = 0; i < sizeof(anchorClasses) && anchorCount < maxAnchors; i++)
    {
        int entity = -1;
        while ((entity = FindEntityByClassname(entity, anchorClasses[i])) != -1 && anchorCount < maxAnchors)
        {
            if (!IsValidEntity(entity) || !GetEntityOriginSafe(entity, pos))
                continue;

            AddFFAAutoAnchor(anchors, maxAnchors, anchorCount, pos);
        }
    }

    for (int i = 1; i <= MaxClients && anchorCount < maxAnchors; i++)
    {
        if (!IsValidClient(i) || !IsPlayerAlive(i))
            continue;

        GetClientAbsOrigin(i, pos);
        AddFFAAutoAnchor(anchors, maxAnchors, anchorCount, pos);
    }
}

bool GetEntityOriginSafe(int entity, float pos[3])
{
    if (HasEntProp(entity, Prop_Send, "m_vecOrigin"))
    {
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
        return true;
    }

    if (HasEntProp(entity, Prop_Data, "m_vecOrigin"))
    {
        GetEntPropVector(entity, Prop_Data, "m_vecOrigin", pos);
        return true;
    }

    return false;
}

void AddFFAAutoAnchor(float anchors[][3], int maxAnchors, int &anchorCount, float origin[3])
{
    if (anchorCount >= maxAnchors)
        return;

    float ground[3];
    if (!FindGroundForFFASpawn(origin, ground) || !IsFFASpawnHullClear(ground))
        return;

    if (!IsFFASpawnOnPlayableNav(ground, false))
        return;

    for (int i = 0; i < anchorCount; i++)
    {
        if (GetVectorDistance(ground, anchors[i]) < FFA_AUTO_ANCHOR_DEDUPE)
            return;
    }

    anchors[anchorCount][0] = ground[0];
    anchors[anchorCount][1] = ground[1];
    anchors[anchorCount][2] = ground[2];
    anchorCount++;
}

void AddFFASpawnsFromAnchors(float anchors[][3], int anchorCount, float minDistance, bool requireCover)
{
    for (int i = 0; i < anchorCount && g_iFFASpawnCount < FFA_AUTO_TARGET_SPAWNS; i++)
    {
        if (IsFairFFASpawnCandidate(anchors[i], minDistance, requireCover))
        {
            AddGeneratedFFASpawn(anchors[i]);
        }
    }
}

bool TryCreateRandomFFASpawn(float anchors[][3], int anchorCount, float minDistance, bool requireCover)
{
    if (anchorCount <= 0 || g_iFFASpawnCount >= FFA_AUTO_TARGET_SPAWNS)
        return false;

    int anchor = GetRandomInt(0, anchorCount - 1);
    float candidate[3];
    candidate[0] = anchors[anchor][0];
    candidate[1] = anchors[anchor][1];
    candidate[2] = anchors[anchor][2];

    if (!IsFairFFASpawnCandidate(candidate, minDistance, requireCover))
        return false;

    AddGeneratedFFASpawn(candidate);
    return true;
}

void AddGeneratedFFASpawn(float pos[3])
{
    if (g_iFFASpawnCount >= MAX_FFA_SPAWNS)
        return;

    g_fFFASpawnPoints[g_iFFASpawnCount][0] = pos[0];
    g_fFFASpawnPoints[g_iFFASpawnCount][1] = pos[1];
    g_fFFASpawnPoints[g_iFFASpawnCount][2] = pos[2];
    BuildFFASpawnAngles(pos, g_fFFASpawnAngles[g_iFFASpawnCount]);
    g_fFFASpawnNextUse[g_iFFASpawnCount] = 0.0;
    g_iFFASpawnCount++;
}

void ResetFFASpawnCooldowns()
{
    g_iLastFFASpawnIndex = -1;
    for (int i = 0; i < MAX_FFA_SPAWNS; i++)
    {
        g_fFFASpawnNextUse[i] = 0.0;
    }
}

bool PrepareGeneratedTDMSpawns(const char[] modeName, int client)
{
    if (GenerateAutoTDMSpawns())
    {
        PrintToServer("[%s] Generated nav-safe TDM spawns. Red: %d Blue: %d",
            modeName, g_iSpawnCount[TEAM_A], g_iSpawnCount[TEAM_B]);
        return true;
    }

    if (client > 0)
    {
        ReplyToCommand(client, "\x04[%s] \x01Could not generate fair TDM spawns on this map.", modeName);
    }
    PrintToServer("[%s] Failed to generate TDM spawn points for this map.", modeName);
    return false;
}

bool PrepareManualTDMSpawns(const char[] modeName, int client)
{
    LoadSpawnPoints();
    g_bTDMArenaActive = false;
    g_fTDMArenaRadius = 0.0;

    if (g_iSpawnCount[TEAM_A] > 0 && g_iSpawnCount[TEAM_B] > 0)
    {
        PrintToServer("[%s] Loaded manual TDM spawns. Red: %d Blue: %d",
            modeName, g_iSpawnCount[TEAM_A], g_iSpawnCount[TEAM_B]);
        return true;
    }

    if (client > 0)
    {
        ReplyToCommand(client, "\x04[%s] \x01No manual Red/Blue TDM spawns found for this map.", modeName);
    }
    PrintToServer("[%s] Missing manual TDM spawns. Red: %d Blue: %d",
        modeName, g_iSpawnCount[TEAM_A], g_iSpawnCount[TEAM_B]);
    return false;
}

bool GenerateAutoTDMSpawns()
{
    for (int team = 0; team < MAX_TEAMS; team++)
    {
        g_iSpawnCount[team] = 0;
    }
    ResetTDMSpawnCooldowns();
    g_bTDMArenaActive = false;
    g_fTDMArenaRadius = 0.0;

    float anchors[FFA_AUTO_MAX_ANCHORS][3];
    int anchorCount = CollectFFAAutoAnchors(anchors, FFA_AUTO_MAX_ANCHORS);
    if (anchorCount < 2)
        return false;

    ShuffleFFAAutoAnchors(anchors, anchorCount);

    int redCenter = -1;
    int blueCenter = -1;
    if (!FindTDMTeamCenters(anchors, anchorCount, redCenter, blueCenter))
    {
        ResetTDMCenterHistory();
        if (!FindTDMTeamCenters(anchors, anchorCount, redCenter, blueCenter))
            return false;
    }

    BuildTDMSpawnAngles(anchors[redCenter], anchors[blueCenter], g_fSpawnAngles[TEAM_A][0]);
    BuildTDMSpawnAngles(anchors[blueCenter], anchors[redCenter], g_fSpawnAngles[TEAM_B][0]);

    AddGeneratedTDMSpawn(TEAM_A, anchors[redCenter], anchors[blueCenter]);
    AddGeneratedTDMSpawn(TEAM_B, anchors[blueCenter], anchors[redCenter]);

    BuildTDMTeamCluster(TEAM_A, anchors[redCenter], anchors[blueCenter], anchors, anchorCount, TDM_AUTO_TEAM_CLUSTER_RADIUS, 190.0);
    BuildTDMTeamCluster(TEAM_B, anchors[blueCenter], anchors[redCenter], anchors, anchorCount, TDM_AUTO_TEAM_CLUSTER_RADIUS, 190.0);

    if (g_iSpawnCount[TEAM_A] < TDM_AUTO_MIN_TEAM_SPAWNS)
        BuildTDMTeamCluster(TEAM_A, anchors[redCenter], anchors[blueCenter], anchors, anchorCount, TDM_AUTO_TEAM_CLUSTER_RADIUS + 280.0, 150.0);
    if (g_iSpawnCount[TEAM_B] < TDM_AUTO_MIN_TEAM_SPAWNS)
        BuildTDMTeamCluster(TEAM_B, anchors[blueCenter], anchors[redCenter], anchors, anchorCount, TDM_AUTO_TEAM_CLUSTER_RADIUS + 280.0, 150.0);

    if (g_iSpawnCount[TEAM_A] < TDM_AUTO_MIN_TEAM_SPAWNS)
        BuildTDMTeamCluster(TEAM_A, anchors[redCenter], anchors[blueCenter], anchors, anchorCount, TDM_AUTO_TEAM_CLUSTER_RADIUS + 560.0, 120.0);
    if (g_iSpawnCount[TEAM_B] < TDM_AUTO_MIN_TEAM_SPAWNS)
        BuildTDMTeamCluster(TEAM_B, anchors[blueCenter], anchors[redCenter], anchors, anchorCount, TDM_AUTO_TEAM_CLUSTER_RADIUS + 560.0, 120.0);

    if (g_iSpawnCount[TEAM_A] == 0 || g_iSpawnCount[TEAM_B] == 0)
        return false;

    g_fTDMArenaCenter[0] = (anchors[redCenter][0] + anchors[blueCenter][0]) * 0.5;
    g_fTDMArenaCenter[1] = (anchors[redCenter][1] + anchors[blueCenter][1]) * 0.5;
    g_fTDMArenaCenter[2] = (anchors[redCenter][2] + anchors[blueCenter][2]) * 0.5;
    g_fTDMArenaRadius = 0.0;
    g_bTDMArenaActive = false;

    StoreLastTDMCenterPair(anchors[redCenter], anchors[blueCenter]);
    return true;
}

bool FindTDMTeamCenters(float anchors[][3], int anchorCount, int &redCenter, int &blueCenter)
{
    float bestScore = -999999.0;

    for (int i = 0; i < anchorCount; i++)
    {
        for (int j = 0; j < anchorCount; j++)
        {
            if (i == j)
                continue;

            if (!IsTDMSpawnAnchorUsable(anchors[i]) || !IsTDMSpawnAnchorUsable(anchors[j]))
                continue;

            if (IsRecentTDMCenterPair(anchors[i], anchors[j]))
                continue;

            float distance = GetVectorDistance(anchors[i], anchors[j]);
            if (distance < TDM_AUTO_TEAM_MIN_SEPARATION || distance > TDM_AUTO_TEAM_MAX_SEPARATION)
                continue;

            int supportA = CountTDMNearbyAnchors(anchors[i], anchors, anchorCount, TDM_AUTO_TEAM_CLUSTER_RADIUS);
            int supportB = CountTDMNearbyAnchors(anchors[j], anchors, anchorCount, TDM_AUTO_TEAM_CLUSTER_RADIUS);
            if (supportA < 3 || supportB < 3)
                continue;

            float score = float(supportA + supportB) * 120.0 - FloatAbs(distance - TDM_AUTO_TEAM_TARGET_SEPARATION);
            if (score > bestScore)
            {
                bestScore = score;
            }
        }
    }

    int eligibleCount = 0;
    for (int i = 0; i < anchorCount; i++)
    {
        for (int j = 0; j < anchorCount; j++)
        {
            if (i == j)
                continue;

            if (!IsTDMSpawnAnchorUsable(anchors[i]) || !IsTDMSpawnAnchorUsable(anchors[j]))
                continue;

            if (IsRecentTDMCenterPair(anchors[i], anchors[j]))
                continue;

            float distance = GetVectorDistance(anchors[i], anchors[j]);
            if (distance < TDM_AUTO_TEAM_MIN_SEPARATION || distance > TDM_AUTO_TEAM_MAX_SEPARATION)
                continue;

            int supportA = CountTDMNearbyAnchors(anchors[i], anchors, anchorCount, TDM_AUTO_TEAM_CLUSTER_RADIUS);
            int supportB = CountTDMNearbyAnchors(anchors[j], anchors, anchorCount, TDM_AUTO_TEAM_CLUSTER_RADIUS);
            if (supportA < 3 || supportB < 3)
                continue;

            float score = float(supportA + supportB) * 120.0 - FloatAbs(distance - TDM_AUTO_TEAM_TARGET_SEPARATION);
            if (score < bestScore - TDM_AUTO_CENTER_SCORE_WINDOW)
                continue;

            eligibleCount++;
            if (GetRandomInt(1, eligibleCount) == 1)
            {
                redCenter = i;
                blueCenter = j;
            }
        }
    }

    if (redCenter != -1 && blueCenter != -1)
        return true;

    eligibleCount = 0;
    for (int i = 0; i < anchorCount; i++)
    {
        for (int j = 0; j < anchorCount; j++)
        {
            if (i == j)
                continue;

            if (!IsTDMSpawnAnchorUsable(anchors[i]) || !IsTDMSpawnAnchorUsable(anchors[j]))
                continue;

            if (IsRecentTDMCenterPair(anchors[i], anchors[j]))
                continue;

            float distance = GetVectorDistance(anchors[i], anchors[j]);
            if (distance >= TDM_AUTO_TEAM_FALLBACK_MIN_SEPARATION && distance <= TDM_AUTO_TEAM_FALLBACK_MAX_SEPARATION)
            {
                eligibleCount++;
                if (GetRandomInt(1, eligibleCount) == 1)
                {
                    redCenter = i;
                    blueCenter = j;
                }
            }
        }
    }

    return redCenter != -1 && blueCenter != -1;
}

void StoreLastTDMCenterPair(float redCenter[3], float blueCenter[3])
{
    int slot = g_iTDMCenterHistoryNext;

    g_fTDMCenterHistory[slot][TEAM_A][0] = redCenter[0];
    g_fTDMCenterHistory[slot][TEAM_A][1] = redCenter[1];
    g_fTDMCenterHistory[slot][TEAM_A][2] = redCenter[2];
    g_fTDMCenterHistory[slot][TEAM_B][0] = blueCenter[0];
    g_fTDMCenterHistory[slot][TEAM_B][1] = blueCenter[1];
    g_fTDMCenterHistory[slot][TEAM_B][2] = blueCenter[2];

    g_fTDMCenterMidHistory[slot][0] = (redCenter[0] + blueCenter[0]) * 0.5;
    g_fTDMCenterMidHistory[slot][1] = (redCenter[1] + blueCenter[1]) * 0.5;
    g_fTDMCenterMidHistory[slot][2] = (redCenter[2] + blueCenter[2]) * 0.5;

    g_iTDMCenterHistoryNext = (g_iTDMCenterHistoryNext + 1) % TDM_AUTO_CENTER_HISTORY;
    if (g_iTDMCenterHistoryCount < TDM_AUTO_CENTER_HISTORY)
        g_iTDMCenterHistoryCount++;
}

bool IsRecentTDMCenterPair(float redCenter[3], float blueCenter[3])
{
    if (g_iTDMCenterHistoryCount <= 0)
        return false;

    float midpoint[3];
    midpoint[0] = (redCenter[0] + blueCenter[0]) * 0.5;
    midpoint[1] = (redCenter[1] + blueCenter[1]) * 0.5;
    midpoint[2] = (redCenter[2] + blueCenter[2]) * 0.5;

    for (int i = 0; i < g_iTDMCenterHistoryCount; i++)
    {
        if (GetVectorDistance(midpoint, g_fTDMCenterMidHistory[i]) <= TDM_AUTO_HISTORY_MIDPOINT_AVOID_RADIUS)
            return true;

        bool sameSides =
            GetVectorDistance(redCenter, g_fTDMCenterHistory[i][TEAM_A]) <= TDM_AUTO_HISTORY_CENTER_AVOID_RADIUS &&
            GetVectorDistance(blueCenter, g_fTDMCenterHistory[i][TEAM_B]) <= TDM_AUTO_HISTORY_CENTER_AVOID_RADIUS;
        if (sameSides)
            return true;

        bool swappedSides =
            GetVectorDistance(redCenter, g_fTDMCenterHistory[i][TEAM_B]) <= TDM_AUTO_HISTORY_CENTER_AVOID_RADIUS &&
            GetVectorDistance(blueCenter, g_fTDMCenterHistory[i][TEAM_A]) <= TDM_AUTO_HISTORY_CENTER_AVOID_RADIUS;
        if (swappedSides)
            return true;
    }

    return false;
}

void ResetTDMCenterHistory()
{
    g_iTDMCenterHistoryCount = 0;
    g_iTDMCenterHistoryNext = 0;
}

int CountTDMNearbyAnchors(float center[3], float anchors[][3], int anchorCount, float radius)
{
    int count = 0;
    for (int i = 0; i < anchorCount; i++)
    {
        if (GetVectorDistance(center, anchors[i]) <= radius && IsTDMSpawnAnchorUsable(anchors[i]))
            count++;
    }
    return count;
}

void BuildTDMTeamCluster(int team, float teamCenter[3], float enemyCenter[3], float anchors[][3], int anchorCount, float radius, float minDistance)
{
    for (int i = 0; i < anchorCount && g_iSpawnCount[team] < MAX_SPAWNS; i++)
    {
        if (GetVectorDistance(teamCenter, anchors[i]) > radius)
            continue;

        if (!IsTDMSpawnCandidate(team, anchors[i], minDistance))
            continue;

        AddGeneratedTDMSpawn(team, anchors[i], enemyCenter);
    }
}

bool IsTDMSpawnCandidate(int team, float pos[3], float minDistance)
{
    if (!IsTDMSpawnAnchorUsable(pos))
        return false;

    for (int i = 0; i < g_iSpawnCount[team]; i++)
    {
        if (GetVectorDistance(pos, g_fSpawnPoints[team][i]) < minDistance)
            return false;
    }

    return true;
}

bool IsTDMSpawnAnchorUsable(float pos[3])
{
    return IsFFASpawnHullClear(pos) && IsFFASpawnOnPlayableNav(pos, false);
}

void AddGeneratedTDMSpawn(int team, float pos[3], float enemyCenter[3])
{
    if (team < 0 || team >= MAX_TEAMS || g_iSpawnCount[team] >= MAX_SPAWNS)
        return;

    int index = g_iSpawnCount[team];
    g_fSpawnPoints[team][index][0] = pos[0];
    g_fSpawnPoints[team][index][1] = pos[1];
    g_fSpawnPoints[team][index][2] = pos[2];
    BuildTDMSpawnAngles(pos, enemyCenter, g_fSpawnAngles[team][index]);
    g_fTDMSpawnNextUse[team][index] = 0.0;
    g_iSpawnCount[team]++;
}

void BuildTDMSpawnAngles(float from[3], float to[3], float ang[3])
{
    float direction[3];
    direction[0] = to[0] - from[0];
    direction[1] = to[1] - from[1];
    direction[2] = 0.0;
    GetVectorAngles(direction, ang);
    ang[0] = 0.0;
    ang[2] = 0.0;
}

void ResetTDMSpawnCooldowns()
{
    for (int team = 0; team < MAX_TEAMS; team++)
    {
        g_iLastTDMSpawnIndex[team] = -1;
        for (int i = 0; i < MAX_SPAWNS; i++)
        {
            g_fTDMSpawnNextUse[team][i] = 0.0;
        }
    }
}

void BuildFFASpawnAngles(float pos[3], float ang[3])
{
    ang[0] = 0.0;
    ang[1] = GetRandomFloat(-180.0, 180.0);
    ang[2] = 0.0;

    if (g_iFFASpawnCount == 0)
        return;

    int nearest = -1;
    float nearestDistance = 999999.0;
    for (int i = 0; i < g_iFFASpawnCount; i++)
    {
        float distance = GetVectorDistance(pos, g_fFFASpawnPoints[i]);
        if (distance < nearestDistance)
        {
            nearestDistance = distance;
            nearest = i;
        }
    }

    if (nearest != -1)
    {
        float direction[3];
        direction[0] = pos[0] - g_fFFASpawnPoints[nearest][0];
        direction[1] = pos[1] - g_fFFASpawnPoints[nearest][1];
        direction[2] = 0.0;
        GetVectorAngles(direction, ang);
        ang[0] = 0.0;
        ang[2] = 0.0;
    }
}

bool IsFairFFASpawnCandidate(float pos[3], float minDistance, bool requireCover)
{
    if (!IsFFASpawnHullClear(pos))
        return false;

    if (!IsFFASpawnOnPlayableNav(pos, false))
        return false;

    for (int i = 0; i < g_iFFASpawnCount; i++)
    {
        float distance = GetVectorDistance(pos, g_fFFASpawnPoints[i]);
        if (distance < minDistance)
            return false;

        if (requireCover && distance < FFA_AUTO_LOS_DISTANCE && HasFFASpawnLineOfSight(pos, g_fFFASpawnPoints[i]))
            return false;
    }

    return true;
}

bool IsFFASpawnOnPlayableNav(float pos[3], bool strictEscapeRoute)
{
    if (GetFeatureStatus(FeatureType_Native, "L4D_GetNearestNavArea") != FeatureStatus_Available)
        return true;

    Address area = view_as<Address>(L4D_GetNearestNavArea(pos, 90.0, false, false, true, TEAM_SURVIVOR));
    if (area == Address_Null)
        return false;

    return IsPlayableFFANavArea(area, strictEscapeRoute);
}

bool IsPlayableFFANavArea(Address area, bool strictEscapeRoute)
{
    if (area == Address_Null)
        return false;

    if (GetFeatureStatus(FeatureType_Native, "L4D_NavArea_IsBlocked") == FeatureStatus_Available)
    {
        if (L4D_NavArea_IsBlocked(area, TEAM_SURVIVOR, false) || L4D_NavArea_IsBlocked(area, TEAM_SURVIVOR, true))
            return false;
    }

    if (GetFeatureStatus(FeatureType_Native, "L4D_GetNavArea_AttributeFlags") == FeatureStatus_Available)
    {
        int flags = L4D_GetNavArea_AttributeFlags(area);
        int badFlags = NAV_BASE_OBSTACLE_TOP | NAV_BASE_CLIFF | NAV_BASE_TANK_ONLY | NAV_BASE_MOB_ONLY |
            NAV_BASE_PLAYERCLIP | NAV_BASE_BREAKABLEWALL |
            NAV_BASE_FLOW_BLOCKED | NAV_BASE_OUTSIDE_WORLD | NAV_BASE_NAV_BLOCKER;

        if ((flags & badFlags) != 0)
            return false;
    }

    if (GetFeatureStatus(FeatureType_Native, "L4D_GetNavArea_SpawnAttributes") == FeatureStatus_Available)
    {
        int spawnFlags = L4D_GetNavArea_SpawnAttributes(area);
        int badSpawnFlags = NAV_SPAWN_PLAYER_START | NAV_SPAWN_CHECKPOINT | NAV_SPAWN_RESCUE_VEHICLE |
            NAV_SPAWN_RESCUE_CLOSET | NAV_SPAWN_LYINGDOWN;

        if ((spawnFlags & badSpawnFlags) != 0)
            return false;

        if (strictEscapeRoute && (spawnFlags & NAV_SPAWN_ESCAPE_ROUTE) == 0)
            return false;
    }

    if (GetFeatureStatus(FeatureType_Native, "L4D2Direct_GetTerrorNavAreaFlow") == FeatureStatus_Available &&
        GetFeatureStatus(FeatureType_Native, "L4D2Direct_GetMapMaxFlowDistance") == FeatureStatus_Available)
    {
        float maxFlow = L4D2Direct_GetMapMaxFlowDistance();
        float flow = L4D2Direct_GetTerrorNavAreaFlow(area);

        if (maxFlow > 1000.0)
        {
            if (flow < 0.0 || flow > maxFlow)
                return false;

            if (strictEscapeRoute && (flow < maxFlow * 0.04 || flow > maxFlow * 0.96))
                return false;
        }
    }

    return true;
}

bool FindGroundForFFASpawn(float origin[3], float out[3])
{
    float start[3];
    float end[3];

    start[0] = origin[0];
    start[1] = origin[1];
    start[2] = origin[2] + 512.0;

    end[0] = origin[0];
    end[1] = origin[1];
    end[2] = origin[2] - 2048.0;

    TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter_FFASpawnNoPlayers);
    if (!TR_DidHit())
        return false;

    TR_GetEndPosition(out);
    out[2] += 6.0;
    return true;
}

bool IsFFASpawnHullClear(float pos[3])
{
    float mins[3] = {-16.0, -16.0, 0.0};
    float maxs[3] = {16.0, 16.0, 72.0};

    TR_TraceHullFilter(pos, pos, mins, maxs, MASK_PLAYERSOLID, TraceFilter_FFASpawnNoPlayers);
    return !TR_DidHit() && !TR_StartSolid();
}

bool HasFFASpawnLineOfSight(float a[3], float b[3])
{
    float start[3];
    float end[3];

    start[0] = a[0];
    start[1] = a[1];
    start[2] = a[2] + 48.0;

    end[0] = b[0];
    end[1] = b[1];
    end[2] = b[2] + 48.0;

    TR_TraceRayFilter(start, end, MASK_SOLID, RayType_EndPoint, TraceFilter_FFASpawnNoPlayers);
    return !TR_DidHit();
}

bool IsSpawnWatchedByEnemies(int spawningClient, float spawnPos[3], int spawnTeam, bool teamMode)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (i == spawningClient || !IsValidClient(i) || IsFakeClient(i) || !IsPlayerAlive(i))
            continue;

        if (teamMode)
        {
            if (g_iPlayerTeam[i] == -1 || g_iPlayerTeam[i] == spawnTeam)
                continue;
        }

        if (IsPlayerLookingAtSpawn(i, spawnPos))
            return true;
    }

    return false;
}

bool IsPlayerLookingAtSpawn(int viewer, float spawnPos[3])
{
    float eyePos[3];
    float eyeAngles[3];
    float viewForward[3];
    float target[3];

    GetClientEyePosition(viewer, eyePos);
    GetClientEyeAngles(viewer, eyeAngles);
    GetAngleVectors(eyeAngles, viewForward, NULL_VECTOR, NULL_VECTOR);

    target[0] = spawnPos[0] - eyePos[0];
    target[1] = spawnPos[1] - eyePos[1];
    target[2] = (spawnPos[2] + 48.0) - eyePos[2];

    float distance = GetVectorLength(target);
    if (distance > SPAWN_WATCH_MAX_DISTANCE)
        return false;

    if (distance <= 1.0)
        return true;

    NormalizeVector(target, target);
    if (GetVectorDotProduct(viewForward, target) < SPAWN_WATCH_DOT_MIN)
        return false;

    return HasSpawnVisibilityLine(eyePos, spawnPos);
}

bool HasSpawnVisibilityLine(float eyePos[3], float spawnPos[3])
{
    float end[3];
    end[0] = spawnPos[0];
    end[1] = spawnPos[1];
    end[2] = spawnPos[2] + 48.0;

    TR_TraceRayFilter(eyePos, end, MASK_SOLID, RayType_EndPoint, TraceFilter_FFASpawnNoPlayers);
    return !TR_DidHit();
}

public bool TraceFilter_FFASpawnNoPlayers(int entity, int contentsMask, any data)
{
    if (entity > 0 && entity <= MaxClients)
        return false;

    return true;
}

public Action Command_SaveFFASpawns(int client, int args)
{
    char path[PLATFORM_MAX_PATH];
    char mapName[64];
    GetCurrentMap(mapName, sizeof(mapName));
    
    char fileName[128];
    Format(fileName, sizeof(fileName), FFA_SPAWN_FILE, mapName);
    BuildPath(Path_SM, path, sizeof(path), fileName);
    
    KeyValues kv = new KeyValues("FFASpawnPoints");
    
    for (int i = 0; i < g_iFFASpawnCount; i++)
    {
        char spawnName[8];
        Format(spawnName, sizeof(spawnName), "Spawn%d", i);
        kv.JumpToKey(spawnName, true);
        kv.SetVector("position", g_fFFASpawnPoints[i]);
        kv.SetVector("angles", g_fFFASpawnAngles[i]);
        kv.GoBack();
    }
    
    kv.ExportToFile(path);
    delete kv;
    
    PrintToChat(client, "\x04[FFA] \x01Spawn points saved for map \x04%s\x01!", mapName);
    return Plugin_Handled;
}

public Action Command_ShowFFASpawns(int client, int args)
{
    if (!client) return Plugin_Handled;
    g_bShowAllSpawnsPersistent = false;
    if (g_hShowSpawnsTimer != null)
    {
        KillTimer(g_hShowSpawnsTimer);
        g_hShowSpawnsTimer = null;
    }
    g_bShowTDMSpawnsPersistent = false;
    if (g_hShowTDMSpawnsTimer != null)
    {
        KillTimer(g_hShowTDMSpawnsTimer);
        g_hShowTDMSpawnsTimer = null;
    }
    g_bShowWarmupSpawnsPersistent = false;
    if (g_hShowWarmupSpawnsTimer != null)
    {
        KillTimer(g_hShowWarmupSpawnsTimer);
        g_hShowWarmupSpawnsTimer = null;
    }

    g_bShowFFASpawnsPersistent = true;
    if (g_hShowFFASpawnsTimer != null)
    {
        KillTimer(g_hShowFFASpawnsTimer);
        g_hShowFFASpawnsTimer = null;
    }
    g_hShowFFASpawnsTimer = CreateTimer(SPAWN_SHOW_REFRESH, Timer_ShowFFASpawns, _, TIMER_REPEAT);
    PrintToChat(client, "\x04[FFA] \x01Showing FFA spawn points persistently.");
    return Plugin_Handled;
}

public Action Command_AddFFASpawn(int client, int args)
{
    if (!client) return Plugin_Handled;
    
    // Ensure g_iFFASpawnCount is in valid range (defensive programming)
    if (g_iFFASpawnCount < 0)
    {
        g_iFFASpawnCount = 0;
    }

    if (g_iFFASpawnCount >= MAX_FFA_SPAWNS)
    {
        ReplyToCommand(client, "[FFA] Maximum spawn points reached!");
        return Plugin_Handled;
    }

    float pos[3], ang[3];
    GetClientAbsOrigin(client, pos);
    GetClientAbsAngles(client, ang);

    g_fFFASpawnPoints[g_iFFASpawnCount] = pos;
    g_fFFASpawnAngles[g_iFFASpawnCount] = ang;
    g_fFFASpawnNextUse[g_iFFASpawnCount] = 0.0;
    g_iFFASpawnCount++;
    
    // Visual confirmation
    float vEndPos[3];
    vEndPos = pos;
    vEndPos[2] += SPRITE_HEIGHT;
    
    int color[4] = {255, 255, 0, 255}; // Yellow for FFA
    
    TE_SetupBeamPoints(pos, vEndPos, g_iBeamSprite, 0, 0, 0, SPAWN_SHOW_REFRESH, 
        3.0, 3.0, 1, 1.0, color, 0);
    TE_SendToAll();
    if (g_bShowTDMSpawnsPersistent)
        DrawTDMSpawnBeams();
    else if (g_bShowAllSpawnsPersistent)
        DrawAllSpawnBeams();
    
    PrintToChatAll("\x04[FFA] \x01New FFA spawn point added!");
    return Plugin_Handled;
}

public Action Command_StartFFA(int client, int args)
{
    if (g_bFFAActive)
    {
        ReplyToCommand(client, "\x04[FFA] \x01FFA mode is already active!");
        return Plugin_Handled;
    }

    // Reset all players to normal appearance before starting FFA
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            SetEntityRenderMode(i, RENDER_NORMAL);
            SetEntityRenderColor(i, 255, 255, 255, 255);
        }
    }

    // Load warmup spawns if not already loaded
    LoadWarmupSpawns();

    if (!PrepareGeneratedFFASpawns("FFA", client))
    {
        return Plugin_Handled;
    }

    if (g_iWarmupSpawnCount == 0 && g_cvWarmupEnabled.BoolValue)
    {
        PrintToServer("[FFA] No warmup spawns found; using generated fair FFA spawns for warmup.");
    }

    // Reset all player K/D stats
    for (int i = 1; i <= MaxClients; i++)
    {
        g_iPlayerKills[i] = 0;
        g_iPlayerDeaths[i] = 0;
        g_iFFAKills[i] = 0;
        g_bSpawnProtection[i] = false;  // Make sure spawn protection is off
    }
    
    g_bFFAActive = true;
    g_bMatchEnded = false;
    SetControlledGlowRendering(true);
    SuppressClimbPluginGlow();
    DisableNonPvPGlows();
    ApplyPvPMapCleanup();
    EnsureGlowRefreshTimer();

    // Remove all ground weapons and set up cleanup timer
    CleanupGroundWeapons();
    CreateTimer(5.0, Timer_CleanupGroundWeapons, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    
    // Remove health items from all players
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            RemoveHealthItems(i);
        }
    }

    // Only start warmup if enabled
    if (g_cvWarmupEnabled.BoolValue)
    {
        g_bWarmupActive = true;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i) && !IsFakeClient(i))
            {
                SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
                TeleportToWarmupSpawn(i);
                GiveWarmupLoadout(i);
            }
        }
        CreateTimer(WARMUP_TIME, Timer_WarmupEnd);
        PrintToChatAll("\x04[FFA] \x01 Warmup phase: \x04%.0f\x01 seconds!", WARMUP_TIME);
    }
    else
    {
        g_bWarmupActive = false;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i) && !IsFakeClient(i))
            {
                SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
                TeleportToFFASpawn(i);
                GiveRandomLoadout(i);
                AnnounceLoadout(i);
                RemoveHealthItems(i);  // Add health item removal for FFA mode
            }
        }
        PrintToChatAll("\x04[FFA] \x01 Match is now live! First to \x04%d\x01 kills wins!", g_cvFFAScoreLimit.IntValue);
    }

    g_fFFAStartTime = GetGameTime();

    // Start menu reminder timer
    if (g_hMenuReminderTimer != null)
        KillTimer(g_hMenuReminderTimer);
    g_hMenuReminderTimer = CreateTimer(GetRandomFloat(30.0, 60.0), Timer_MenuReminder);
    
    // Start round timer
    if (g_hFFARoundTimer != null)
        KillTimer(g_hFFARoundTimer);
    g_hFFARoundTimer = CreateTimer(float(g_cvFFARoundTime.IntValue), Timer_EndFFA);
    
    // Setup other game settings
    if (g_hGlowEnable != null)
        g_hGlowEnable.IntValue = 0;
        
    // Remove bots
    RemoveAllInfected();
    
    if (g_hInfectedCheckTimer == null)
        g_hInfectedCheckTimer = CreateTimer(1.0, Timer_CheckInfected, _, TIMER_REPEAT);
    
    return Plugin_Handled;
}

public Action Timer_EndFFA(Handle timer, any winner)
{
    // Don't show FFA messages if Gun Game is active
    if (!g_bGunGameActive && IsValidClient(winner))
    {
        PrintToChatAll("\x04[FFA] \x01 Match ended! \x04%N\x01 wins with \x04%d\x01 kills!", 
            winner, g_iFFAKills[winner]);
    }
    EndFFAMode();
    return Plugin_Stop;
}

void EndFFAMode()
{
    if (!g_bFFAActive)
        return;

    // Find winner based on kills
    int winnerClient = -1;
    int highestKills = -1;
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && g_iFFAKills[i] > highestKills)
        {
            highestKills = g_iFFAKills[i];
            winnerClient = i;
        }
    }

    // Announce winner - don't show if gun game is active
    if (winnerClient != -1 && !g_bGunGameActive)
    {
        PrintToChatAll("\x04[FFA] \x01Game Over! Winner: \x04%N\x01 with \x04%d\x01 kills!", 
            winnerClient, highestKills);
    }

    // Reset variables
    g_bFFAActive = false;
    
    // Kill timers
    if (g_hFFARoundTimer != null)
    {
        KillTimer(g_hFFARoundTimer);
        g_hFFARoundTimer = null;
    }

    // Reset all players
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
        {
            SetEntityRenderColor(i, 255, 255, 255, 255);  // Reset color
            g_iFFAKills[i] = 0;
        }
    }

    // Re-enable glow if needed
    RemoveAllTeamGlows();
    for (int i = 1; i <= MaxClients; i++)
    {
        RemoveKillcamGlow(i);
        g_bInKillcam[i] = false;
        g_iKillcamTarget[i] = -1;
    }
    StopGlowRefreshTimerIfIdle();
}

void TeleportToFFASpawn(int client)
{
    if (g_iFFASpawnCount == 0)
    {
        if (!PrepareGeneratedFFASpawns("FFA", 0))
        {
            PrintToServer("[FFA] No generated FFA spawns available!");
            return;
        }
    }

    int spawnIndex = SelectFFASpawnIndex(client);
    if (spawnIndex < 0)
    {
        PrintToServer("[FFA] Could not select a safe FFA spawn.");
        return;
    }

    TeleportEntity(client, g_fFFASpawnPoints[spawnIndex], g_fFFASpawnAngles[spawnIndex], NULL_VECTOR);
    g_iLastFFASpawnIndex = spawnIndex;
    g_fFFASpawnNextUse[spawnIndex] = GetGameTime() + FFA_SPAWN_REUSE_COOLDOWN;
    
    // Apply spawn protection for both FFA and Gun Game modes, but not for PvP mode
    if ((g_bFFAActive || g_bGunGameActive) && !g_bPvPActive)
    {
        g_bSpawnProtection[client] = true;
        SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
        
        // Apply green tint for spawn protection in FFA and Gun Game modes
        SetEntityRenderColor(client, 0, 255, 0, 200);  // Green color with slight transparency
        CreateTimer(SPAWN_PROTECTION_TIME, Timer_RemoveSpawnProtection, client);
        
        PrintHintText(client, "Spawn protection active for %.1f seconds", SPAWN_PROTECTION_TIME);
    }
    
    return;
}

int SelectFFASpawnIndex(int client)
{
    if (g_iFFASpawnCount <= 0)
        return -1;

    float now = GetGameTime();
    int best = -1;
    float bestScore = -999999.0;
    int fallback = -1;
    float fallbackTime = 99999999.0;
    int riskyBest = -1;
    float riskyBestScore = -999999.0;
    int fallbackAny = -1;
    float fallbackAnyTime = 99999999.0;

    for (int i = 0; i < g_iFFASpawnCount; i++)
    {
        if (g_iFFASpawnCount > 1 && i == g_iLastFFASpawnIndex)
            continue;

        bool occupied = IsFFASpawnOccupied(i, client);
        if (occupied)
            continue;

        bool watched = IsSpawnWatchedByEnemies(client, g_fFFASpawnPoints[i], -1, false);
        if (g_fFFASpawnNextUse[i] < fallbackAnyTime)
        {
            fallbackAny = i;
            fallbackAnyTime = g_fFFASpawnNextUse[i];
        }

        if (!watched && g_fFFASpawnNextUse[i] < fallbackTime)
        {
            fallback = i;
            fallbackTime = g_fFFASpawnNextUse[i];
        }

        if (g_fFFASpawnNextUse[i] > now)
            continue;

        float score = GetFFASpawnSafetyScore(i, client) + GetRandomFloat(0.0, 32.0);
        if (watched)
        {
            score -= SPAWN_WATCH_SCORE_PENALTY;
            if (score > riskyBestScore)
            {
                riskyBestScore = score;
                riskyBest = i;
            }
            continue;
        }

        if (score > bestScore)
        {
            bestScore = score;
            best = i;
        }
    }

    if (best != -1)
        return best;

    if (fallback != -1)
        return fallback;

    if (riskyBest != -1)
        return riskyBest;

    if (fallbackAny != -1)
        return fallbackAny;

    return GetRandomInt(0, g_iFFASpawnCount - 1);
}

bool IsFFASpawnOccupied(int spawnIndex, int spawningClient)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (i == spawningClient || !IsValidClient(i) || !IsPlayerAlive(i))
            continue;

        float pos[3];
        GetClientAbsOrigin(i, pos);
        if (GetVectorDistance(pos, g_fFFASpawnPoints[spawnIndex]) <= FFA_SPAWN_OCCUPIED_RADIUS)
            return true;
    }

    return false;
}

float GetFFASpawnSafetyScore(int spawnIndex, int spawningClient)
{
    float nearest = 2500.0;
    bool foundPlayer = false;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (i == spawningClient || !IsValidClient(i) || !IsPlayerAlive(i))
            continue;

        float pos[3];
        GetClientAbsOrigin(i, pos);
        float distance = GetVectorDistance(pos, g_fFFASpawnPoints[spawnIndex]);
        if (distance < nearest)
        {
            nearest = distance;
            foundPlayer = true;
        }
    }

    if (!foundPlayer)
        return GetRandomFloat(800.0, 1200.0);

    return nearest;
}

public void Event_PlayerDeath_FFA(Event event, const char[] name, bool dontBroadcast)
{
    PrintToServer("[FFA Debug] FFA Death Event triggered");
    
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = g_iLastAttacker[victim];  // Use last attacker instead of event attacker
    
    PrintToServer("[FFA Debug] Death - Attacker: %d, Victim: %d", attacker, victim);
    
    if (IsValidClient(victim))
    {
        g_iPlayerDeaths[victim]++;
        CreateTimer(RESPAWN_TIME, Timer_RespawnPlayer, victim);
    }
    
    if (IsValidClient(attacker) && attacker != victim)
    {
        if (ShouldCountKill(victim, attacker))
        {
            g_iFFAKills[attacker]++;
            g_iPlayerKills[attacker]++;
            
            // Announce kill with stored weapon
            PrintToChatAll("\x04[FFA] \x01%N \x01killed \x04%N\x01 with \x04%s \x01(%d kills)", 
                attacker, victim, g_sLastWeapon[victim], g_iFFAKills[attacker]);
            
            // Check win condition
            if (g_iFFAKills[attacker] >= g_cvFFAScoreLimit.IntValue)
            {
                CreateTimer(3.0, Timer_EndFFA, attacker);
            }
        }
    }

    // Handle respawn
    if (IsValidClient(victim))
    {
        CreateTimer(RESPAWN_TIME, Timer_RespawnPlayer, victim);
        PrintHintText(victim, "Respawning in %.0f seconds...", RESPAWN_TIME);
    }
}

public Action Timer_SwitchReminder(Handle timer)
{
    if (!g_bPvPActive)
    {
        g_hSwitchReminderTimer = null;
        return Plugin_Stop;
    }

    PrintToChatAll("\x04[TDM] \x01Type \x04!switch\x01 to join or change teams!");
    
    // Create new timer with random interval
    g_hSwitchReminderTimer = CreateTimer(GetRandomFloat(30.0, 60.0), Timer_SwitchReminder);
    return Plugin_Stop;
}

public Action Command_SwitchTeam(int client, int args)
{
    if (!g_bPvPActive)
    {
        PrintToChat(client, "\x04[PvP] \x01PvP mode is not active!");
        return Plugin_Handled;
    }

    if (!IsValidClient(client))
        return Plugin_Handled;

    RemoveAllTeamGlows();
    CleanupOrphanPvPGlowProxies();

    // Check if player is already on a team
    if (g_iPlayerTeam[client] == -1)
    {
        // Player is not on a team, assign them to one
        int teamACount = 0, teamBCount = 0;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i) && i != client)
            {
                if (g_iPlayerTeam[i] == TEAM_A)
                    teamACount++;
                else if (g_iPlayerTeam[i] == TEAM_B)
                    teamBCount++;
            }
        }

        // Assign to team with fewer players, or random if equal
        int assignedTeam = (teamACount <= teamBCount) ? TEAM_A : TEAM_B;
        g_iPlayerTeam[client] = assignedTeam;
        
        // Set team colors and announce
        if (assignedTeam == TEAM_A)
        {
            SetEntityRenderColor(client, 255, 0, 0, 255);  // Red
            PrintToChatAll("\x04[TDM] \x01Player \x04%N\x01 has joined the \x04 RED\x01 team!", client);
        }
        else
        {
            SetEntityRenderColor(client, 0, 0, 255, 255);  // Blue
            PrintToChatAll("\x04[TDM] \x01Player \x04%N\x01 has joined the \x03 BLUE\x01 team!", client);
        }
    }
    else
    {
        // Player is on a team, switch them
        int currentTeam = g_iPlayerTeam[client];
        int targetTeam = (currentTeam == TEAM_A) ? TEAM_B : TEAM_A;
        g_iPlayerTeam[client] = targetTeam;
        
        // Set team colors and announce
        if (targetTeam == TEAM_A)
        {
            SetEntityRenderColor(client, 255, 0, 0, 255);  // Red
            PrintToChatAll("\x04[TDM] \x01Player \x04%N\x01 has switched to the \x04 RED\x01 team!", client);
        }
        else
        {
            SetEntityRenderColor(client, 0, 0, 255, 255);  // Blue
            PrintToChatAll("\x04[TDM] \x01Player \x04%N\x01 has switched to the \x03 BLUE\x01 team!", client);
        }
    }

    // Respawn player with new team
    ChangeClientTeam(client, TEAM_SURVIVOR);
    L4D_RespawnPlayer(client);
    CreateTimer(0.2, Timer_TeleportAndEquip, client);
    RefreshTeamGlows();
    CreateTimer(0.4, Timer_RebuildTeamGlows, _, TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
    // Clear health regeneration timer
    if (g_hRegenTimer[client] != null)
    {
        KillTimer(g_hRegenTimer[client]);
        g_hRegenTimer[client] = null;
    }
    g_fLastDamageTime[client] = 0.0;
    g_fLastPvPAttackTime[client] = 0.0;
    g_fNextHitMarkerTime[client] = 0.0;
    g_iLastAttacker[client] = 0;

    g_bIsJoining[client] = false;
    g_fLastTeamAnnounce[client] = 0.0;
    
    // Clean up killcam
    if (g_hKillcamTimer[client] != null)
    {
        KillTimer(g_hKillcamTimer[client]);
        g_hKillcamTimer[client] = null;
    }
    g_bInKillcam[client] = false;
    g_iKillcamTarget[client] = -1;
    RemoveKillcamGlow(client);
    RemoveTeamGlow(client);
    
    // Remove glow if they were being watched
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_iKillcamTarget[i] == client)
        {
            RemoveKillcamGlow(i);
            g_bInKillcam[i] = false;
            g_iKillcamTarget[i] = -1;
            if (g_hKillcamTimer[i] != null)
            {
                KillTimer(g_hKillcamTimer[i]);
                g_hKillcamTimer[i] = null;
            }
        }
    }
    
    // Clean up menu update timer
    if (g_hMenuUpdateTimer[client] != null)
    {
        KillTimer(g_hMenuUpdateTimer[client]);
        g_hMenuUpdateTimer[client] = null;
    }
}

public Action Timer_ResetJoiningFlag(Handle timer, any client)
{
    g_bIsJoining[client] = false;
    return Plugin_Stop;
}

public void OnClientPostAdminCheck(int client)
{
    if (!IsValidClient(client) || IsFakeClient(client))
        return;
        
    // Reset player's team
    g_iPlayerTeam[client] = -1;
    g_fLastTeamAnnounce[client] = 0.0;
    
    // Reset K/D stats for new player
    g_iPlayerKills[client] = 0;
    g_iPlayerDeaths[client] = 0;
    g_iFFAKills[client] = 0;

    // If game is active, handle player join with slight delay
    if (g_bPvPActive)
    {
        CreateTimer(1.0, Timer_HandleNewPlayer, client);
    }
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int newTeam = event.GetInt("team");
    
    // Always block the default team change message
    event.BroadcastDisabled = true;
    
    // If PvP is active and player tries to join survivors, force team assignment
    if (g_bPvPActive && IsValidClient(client) && !IsFakeClient(client) && newTeam == TEAM_SURVIVOR)
    {
        CreateTimer(0.1, Timer_CheckTeamAssignment, client);
    }
    
    return Plugin_Changed;  // Changed from Continue to ensure message blocking
}

public Action OnPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int newTeam = event.GetInt("team");
    int oldTeam = event.GetInt("oldteam");
    
    // Handle players returning from idle in FFA or AWP mode
    if (oldTeam == TEAM_IDLE && (g_bFFAActive || g_bAWPActive) && newTeam == TEAM_SURVIVOR)
    {
        CreateTimer(0.5, Timer_HandleIdleReturn, client);
        return Plugin_Continue;
    }
    
    return Plugin_Continue;
}

public void ShowTeamMenu(int client)
{
    Menu menu = new Menu(TeamMenuHandler);
    menu.SetTitle("Team Deathmatch Scoreboard\nRed %d - Blue %d\n ", 
        g_iTeamScores[TEAM_A], g_iTeamScores[TEAM_B]);
    
    // Red Team
    menu.AddItem("", "Red Team:", ITEMDRAW_DISABLED);
    bool redTeamEmpty = true;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && !IsFakeClient(i) && g_iPlayerTeam[i] == TEAM_A)
        {
            char display[64];
            Format(display, sizeof(display), "  %N (K/D: %d/%d)", 
                i, g_iPlayerKills[i], g_iPlayerDeaths[i]);
            menu.AddItem("", display, ITEMDRAW_DISABLED);
            redTeamEmpty = false;
        }
    }
    if (redTeamEmpty)
        menu.AddItem("", "  (Empty)", ITEMDRAW_DISABLED);
    
    menu.AddItem("", " ", ITEMDRAW_SPACER);
    
    // Blue Team
    menu.AddItem("", "Blue Team:", ITEMDRAW_DISABLED);
    bool blueTeamEmpty = true;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && !IsFakeClient(i) && g_iPlayerTeam[i] == TEAM_B)
        {
            char display[64];
            Format(display, sizeof(display), "  %N (K/D: %d/%d)", 
                i, g_iPlayerKills[i], g_iPlayerDeaths[i]);
            menu.AddItem("", display, ITEMDRAW_DISABLED);
            blueTeamEmpty = false;
        }
    }
    if (blueTeamEmpty)
        menu.AddItem("", "  (Empty)", ITEMDRAW_DISABLED);
    
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public Action Command_JoinGame(int client, int args)
{
    if (!g_bPvPActive || !IsValidClient(client))
        return Plugin_Handled;

    // Prevent multiple joins
    if (g_iPlayerTeam[client] != -1)
    {
        PrintToChat(client, "\x04[TDM] \x01You are already on a team!");
        return Plugin_Handled;
    }

    // Check if announcement was made recently (within 2 seconds)
    float currentTime = GetGameTime();
    if (currentTime - g_iLastTeamAnnounce[client] < 2.0)
    {
        return Plugin_Handled;
    }

    // Get current team counts
    int redCount = 0, blueCount = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && !IsFakeClient(i))
        {
            if (g_iPlayerTeam[i] == TEAM_A)
                redCount++;
            else if (g_iPlayerTeam[i] == TEAM_B)
                blueCount++;
        }
    }

    // Force assignment to team with fewer players
    int team = (redCount <= blueCount) ? TEAM_A : TEAM_B;
    
    // Set team immediately
    g_iPlayerTeam[client] = team;
    g_bIsJoining[client] = true;
    
    // Force respawn and set model
    ChangeClientTeam(client, TEAM_SURVIVOR);
    SetEntProp(client, Prop_Send, "m_survivorCharacter", GetRandomInt(0, 7));
    SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
    L4D_RespawnPlayer_Custom(client);
    
    // Ensure player can move and is visible
    SetEntityMoveType(client, MOVETYPE_WALK);
    SetEntityRenderMode(client, RENDER_NORMAL);
    
    // Set team colors and announce ONCE
    if (team == TEAM_A)
    {
        SetEntityRenderColor(client, 255, 0, 0, 255);  // Red
        PrintToChatAll("\x04[TDM] \x01%N has joined the \x04 RED\x01 team!", client);
    }
    else
    {
        SetEntityRenderColor(client, 0, 0, 255, 255);  // Blue
        PrintToChatAll("\x04[TDM] \x01%N has joined the \x03 BLUE\x01 team!", client);
    }

    // Update last announcement time
    g_iLastTeamAnnounce[client] = currentTime;

    // Create timer to reset joining flag
    CreateTimer(1.0, Timer_ResetJoiningFlag, client);
    
    // Handle warmup vs active game
    if (g_bWarmupActive)
    {
        TeleportToWarmupSpawn(client);
        GiveWarmupLoadout(client);
        SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
    }
    else
    {
        TeleportToSpawn(client, team);
        GiveRandomLoadout(client);
        // AnnounceLoadout(client); // Commented out to avoid duplicate messages
        
        // Use timer to announce loadout for all players including host
        CreateTimer(0.7, Timer_ForceAnnounceLoadout, client);
        
        g_bSpawnProtection[client] = true;
        SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
        SetEntityRenderColor(client, 0, 255, 0, 200);  // Green color with slight transparency
        CreateTimer(SPAWN_PROTECTION_TIME, Timer_RemoveSpawnProtection, client);
    }
    
    // Ensure viewmodel is visible
    SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
    
    return Plugin_Handled;
}

public Action Timer_MenuReminder(Handle timer)
{
    // Rotate between different messages
    static int messageIndex = 0;
    
    switch (messageIndex)
    {
        case 0:
        {
            // Don't show the !m message in Gun Game mode
            if (!g_bGunGameActive)
            {
                if (g_bFFAActive)
                    PrintToChatAll("\x04[FFA] \x01Type \x04!m\x01 to see the current scores!");
                else if (g_bPvPActive)
                    PrintToChatAll("\x04[TDM] \x01Type \x04!m\x01 to see the current teams!");
                else if (g_bAWPActive)
                    PrintToChatAll("\x04[AWP] \x01Type \x04!m\x01 to see the current scores!");
                else if (g_bOneShotMode)
                    PrintToChatAll("\x04[One Shot] \x01Type \x04!m\x01 to see the current scores!");
            }
        }
        case 1:
        {
            PrintToChatAll("\x04[PvP] \x01Welcome to L4D2 PvP 2.1.2 (01-Jun-2026)!");
        }
        case 2:
        {
            PrintToChatAll("\x04[PvP] \x01Type \x04!lift\x01 to open the elevator menu!");
        }
        case 3:
        {
            PrintToChatAll("\x04[PvP] \x01Use \x04!lift\x01 to move, open, close, or stop elevators!");
        }
        case 4:
        {
            PrintToChatAll("\x04[PvP] \x01Gone idle? Type \x04!join\x01 to return to the game!");
        }
        case 5:
        {
            PrintToChatAll("\x04[PvP] \x01Want to respawn? Type \x04!kill\x01 to suicide (requires approval)!");
        }
    }
    
    // Cycle through messages
    messageIndex = (messageIndex + 1) % 6;
    
    // Create new timer with random interval
    g_hMenuReminderTimer = CreateTimer(GetRandomFloat(30.0, 60.0), Timer_MenuReminder);
    return Plugin_Stop;
}

public int TeamMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

public Action Command_TeamMenu(int client, int args)
{
    // Skip entirely for gun game mode
    if (g_bGunGameActive)
    {
        return Plugin_Handled;
    }

    if (!g_bPvPActive && !g_bFFAActive && !g_bAWPActive && !g_bOneShotMode)
    {
        PrintToChat(client, "\x04[PvP] \x01No game mode is currently active!");
        return Plugin_Handled;
    }
    
    // Start timer for live updates
    if (g_hMenuUpdateTimer[client] != null)
    {
        KillTimer(g_hMenuUpdateTimer[client]);
        g_hMenuUpdateTimer[client] = null;
    }
    g_hMenuUpdateTimer[client] = CreateTimer(1.0, Timer_UpdateMenu, client, TIMER_REPEAT);
    
    // Record the time for this menu update
    g_iLastMenuTime[client] = GetTime();
    
    Menu menu = new Menu(MenuHandler_TeamMenu);
    
    if (g_bAWPActive)
    {
        menu.SetTitle("AWP Scoreboard\n ");
        
        int playerCount = 0;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
            {
                char display[64];
                Format(display, sizeof(display), "%N: %d kills (%d/%d)", 
                    i, g_iAWPKills[i], g_iPlayerKills[i], g_iPlayerDeaths[i]);
                menu.AddItem("", display, ITEMDRAW_DISABLED);
                playerCount++;
            }
        }
        
        if (playerCount == 0)
        {
            menu.AddItem("", "No players in game", ITEMDRAW_DISABLED);
        }
        
        if (g_hAWPRoundTimer != null)
        {
            menu.AddItem("", " ", ITEMDRAW_SPACER);
            int timeLeft = g_cvAWPRoundTime.IntValue - RoundToFloor(GetGameTime() - g_fAWPStartTime);
            if (timeLeft > 0)
            {
                char timeDisplay[64];
                Format(timeDisplay, sizeof(timeDisplay), "Time remaining: %d:%02d", timeLeft / 60, timeLeft % 60);
                menu.AddItem("", timeDisplay, ITEMDRAW_DISABLED);
            }
        }
    }
    else if (g_bFFAActive)
    {
        menu.SetTitle("Free-For-All Scoreboard\n ");
        
        // Add scores for each player (exclude bots)
        int playerCount = 0;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
            {
                char display[64];
                Format(display, sizeof(display), "%N: %d kills (%d/%d)", 
                    i, g_iFFAKills[i], g_iPlayerKills[i], g_iPlayerDeaths[i]);
                menu.AddItem("", display, ITEMDRAW_DISABLED);
                playerCount++;
            }
        }
        
        if (playerCount == 0)
        {
            menu.AddItem("", "No players in game", ITEMDRAW_DISABLED);
        }
        
        // Add time remaining if round timer is active
        if (g_hFFARoundTimer != null)
        {
            menu.AddItem("", " ", ITEMDRAW_SPACER);
            int timeLeft = g_cvFFARoundTime.IntValue - RoundToFloor(GetGameTime() - g_fFFAStartTime);
            if (timeLeft > 0)
            {
                char timeDisplay[64];
                Format(timeDisplay, sizeof(timeDisplay), "Time remaining: %d:%02d", timeLeft / 60, timeLeft % 60);
                menu.AddItem("", timeDisplay, ITEMDRAW_DISABLED);
            }
        }
    }
    else if (g_bGunGameActive)
    {
        // Create Gun Game scoreboard with same format as FFA
        menu.SetTitle("Gun Game Scoreboard\n ");

        // Count active players and prepare for sorting
        int playerCount = 0;
        int sortedPlayers[MAXPLAYERS+1][3]; // Client index, level, kills
        
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i))
            {
                sortedPlayers[playerCount][0] = i;
                sortedPlayers[playerCount][1] = g_iGunGameLevel[i];
                sortedPlayers[playerCount][2] = g_iPlayerKills[i];
                playerCount++;
            }
        }
        
        // Sort players by level then kills (bubble sort)
        for (int i = 0; i < playerCount - 1; i++)
        {
            for (int j = 0; j < playerCount - i - 1; j++)
            {
                // Sort by level first (higher level first)
                if (sortedPlayers[j][1] < sortedPlayers[j+1][1] || 
                   (sortedPlayers[j][1] == sortedPlayers[j+1][1] && sortedPlayers[j][2] < sortedPlayers[j+1][2]))
                {
                    // Swap the positions
                    int tempClient = sortedPlayers[j][0];
                    int tempLevel = sortedPlayers[j][1];
                    int tempKills = sortedPlayers[j][2];
                    
                    sortedPlayers[j][0] = sortedPlayers[j+1][0];
                    sortedPlayers[j][1] = sortedPlayers[j+1][1];
                    sortedPlayers[j][2] = sortedPlayers[j+1][2];
                    
                    sortedPlayers[j+1][0] = tempClient;
                    sortedPlayers[j+1][1] = tempLevel;
                    sortedPlayers[j+1][2] = tempKills;
                }
            }
        }
        
        // Display players in sorted order
        char playerLine[64];
        char weaponName[32];
        
        for (int i = 0; i < playerCount; i++)
        {
            int playerIndex = sortedPlayers[i][0];
            
            if (g_iGunGameLevel[playerIndex] >= g_cvGunGameScoreLimit.IntValue - 1)
            {
                strcopy(weaponName, sizeof(weaponName), "KNIFE");
            }
            else
            {
                FormatGunGameWeaponDisplayName(g_sRandomizedGunGameWeapons[g_iGunGameLevel[playerIndex]], weaponName, sizeof(weaponName));
            }
            
            Format(playerLine, sizeof(playerLine), "%N - Level %d (%s) - %d kills", 
                playerIndex, g_iGunGameLevel[playerIndex] + 1, weaponName, g_iPlayerKills[playerIndex]);
            menu.AddItem("", playerLine, ITEMDRAW_DISABLED);
        }
        
        if (playerCount == 0)
        {
            menu.AddItem("", "No players in game", ITEMDRAW_DISABLED);
        }
        
        // Add time remaining if round timer is active
        if (g_hGunGameRoundTimer != null)
        {
            menu.AddItem("", " ", ITEMDRAW_SPACER);
            int timeLeft = GetConVarInt(g_cvFFARoundTime) - RoundToFloor(GetGameTime() - g_fFFAStartTime);
            if (timeLeft > 0)
            {
                char timeDisplay[64];
                Format(timeDisplay, sizeof(timeDisplay), "Time remaining: %d:%02d", timeLeft / 60, timeLeft % 60);
                menu.AddItem("", timeDisplay, ITEMDRAW_DISABLED);
            }
        }
        
        menu.ExitButton = true;
        menu.Display(client, MENU_TIME_FOREVER);
        return Plugin_Handled;
    }
    else if (g_bPvPActive)
    {
        menu.SetTitle("Team Deathmatch Scoreboard\nRed %d - Blue %d\n ", 
            g_iTeamScores[TEAM_A], g_iTeamScores[TEAM_B]);
        
        // Red Team
        menu.AddItem("", "Red Team:", ITEMDRAW_DISABLED);
        bool redTeamEmpty = true;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i) && !IsFakeClient(i) && g_iPlayerTeam[i] == TEAM_A)
            {
                char display[64];
                Format(display, sizeof(display), "  %N (K/D: %d/%d)", 
                    i, g_iPlayerKills[i], g_iPlayerDeaths[i]);
                menu.AddItem("", display, ITEMDRAW_DISABLED);
                redTeamEmpty = false;
            }
        }
        if (redTeamEmpty)
            menu.AddItem("", "  (Empty)", ITEMDRAW_DISABLED);
        
        menu.AddItem("", " ", ITEMDRAW_SPACER);
        
        // Blue Team
        menu.AddItem("", "Blue Team:", ITEMDRAW_DISABLED);
        bool blueTeamEmpty = true;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i) && !IsFakeClient(i) && g_iPlayerTeam[i] == TEAM_B)
            {
                char display[64];
                Format(display, sizeof(display), "  %N (K/D: %d/%d)", 
                    i, g_iPlayerKills[i], g_iPlayerDeaths[i]);
                menu.AddItem("", display, ITEMDRAW_DISABLED);
                blueTeamEmpty = false;
            }
        }
        if (blueTeamEmpty)
            menu.AddItem("", "  (Empty)", ITEMDRAW_DISABLED);
        
        // Add time remaining if round timer is active
        if (g_hRoundTimer != null)
        {
            menu.AddItem("", " ", ITEMDRAW_SPACER);
            int timeLeft = g_cvRoundTime.IntValue - RoundToFloor(GetGameTime() - g_fFFAStartTime);
            if (timeLeft > 0)
            {
                char timeDisplay[64];
                Format(timeDisplay, sizeof(timeDisplay), "Time remaining: %d:%02d", timeLeft / 60, timeLeft % 60);
                menu.AddItem("", timeDisplay, ITEMDRAW_DISABLED);
            }
        }
    }
    
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
    
    return Plugin_Handled;
}

public Action OnBotTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (victim == g_iSaferoomBot)
    {
        damage = 0.0;
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if (g_bPvPActive && IsValidClient(client) && IsPlayerAlive(client))
    {
        RestorePlayerColor(client);
        EnforceTDMArenaWall(client, true);
    }
}

void RestorePlayerColor(int client)
{
    if (!IsValidClient(client) || g_iPlayerTeam[client] == -1)
        return;
        
    SetEntityRenderMode(client, RENDER_NORMAL);
    
    if (g_iPlayerTeam[client] == TEAM_A)
    {
        SetEntityRenderColor(client, 255, 0, 0, 255);  // Red team
    }
    else if (g_iPlayerTeam[client] == TEAM_B)
    {
        SetEntityRenderColor(client, 0, 0, 255, 255);  // Blue team
    }
}

public Action Timer_KeepBotAlive(Handle timer, any bot)
{
    if (!g_bSaferoomBotActive || !IsClientInGame(bot) || bot != g_iSaferoomBot)
    {
        return Plugin_Stop;
    }

    // Keep essential properties
    SetEntProp(bot, Prop_Send, "m_iTeamNum", TEAM_SURVIVOR);
    
    // Ensure bot stays invulnerable - only use valid properties
    SetEntProp(bot, Prop_Data, "m_takedamage", 0, 1);
    SetEntProp(bot, Prop_Send, "m_isIncapacitated", 0);
    SetEntProp(bot, Prop_Send, "m_iHealth", 100000);
    SetEntProp(bot, Prop_Send, "m_iMaxHealth", 100000);
    SetEntProp(bot, Prop_Send, "m_bIsOnThirdStrike", 0);
    SetEntProp(bot, Prop_Send, "m_currentReviveCount", 0);
    
    // Simulate activity by making tiny movements
    float pos[3], ang[3];
    GetClientAbsOrigin(bot, pos);
    GetClientAbsAngles(bot, ang);
    
    // Slightly adjust the angle to simulate movement
    ang[1] += 0.1;
    if (ang[1] > 360.0) ang[1] = 0.0;
    
    TeleportEntity(bot, NULL_VECTOR, ang, NULL_VECTOR);
    
    return Plugin_Continue;
}

public Action Timer_RemoveSaferoomBot(Handle timer, any bot)
{
    if (g_bSaferoomBotActive && bot == g_iSaferoomBot && IsClientInGame(bot))
    {
        KickClient(bot);
        PrintToChatAll("\x04[PvP] \x01Saferoom bot has been automatically removed after 90 minutes.");
        g_iSaferoomBot = -1;
        g_bSaferoomBotActive = false;
    }
    return Plugin_Stop;
}

public Action Command_RemoveSaferoomBot(int client, int args)
{
    if (!g_bSaferoomBotActive)
    {
        ReplyToCommand(client, "\x04[PvP] \x01No saferoom bot is active!");
        return Plugin_Handled;
    }

    if (g_iSaferoomBot != -1 && IsClientInGame(g_iSaferoomBot))
    {
        KickClient(g_iSaferoomBot);
        PrintToChatAll("\x04[PvP] \x01Saferoom bot has been removed!");
    }

    g_iSaferoomBot = -1;
    g_bSaferoomBotActive = false;
    return Plugin_Handled;
}

public Action OnBotKick(int bot)
{
    if (bot == g_iSaferoomBot)
    {
        return Plugin_Handled;  // Block any attempt to kick the saferoom bot
    }
    return Plugin_Continue;
}

public Action Command_SpawnSaferoomBot(int client, int args)
{
    if (g_bSaferoomBotActive)
    {
        ReplyToCommand(client, "\x04[PvP] \x01Saferoom bot is already active!");
        return Plugin_Handled;
    }

    // Create the bot
    int bot = CreateFakeClient("SaferoomBot");
    if (bot == 0)
    {
        ReplyToCommand(client, "\x04[PvP] \x01Failed to create saferoom bot!");
        return Plugin_Handled;
    }

    // Setup the bot
    ChangeClientTeam(bot, TEAM_SURVIVOR);
    if (DispatchKeyValue(bot, "classname", "survivor") && DispatchSpawn(bot))
    {
        // Set bot's position
        float pos[3], ang[3];
        if (client > 0)
        {
            GetClientAbsOrigin(client, pos);
            GetClientAbsAngles(client, ang);
        }

        TeleportEntity(bot, pos, ang, NULL_VECTOR);
        
        // Make bot immortal
        SetEntProp(bot, Prop_Data, "m_takedamage", 0, 1);
        SetEntProp(bot, Prop_Send, "m_isIncapacitated", 0);
        SetEntProp(bot, Prop_Send, "m_iHealth", 100000);
        SetEntProp(bot, Prop_Send, "m_iMaxHealth", 100000);
        
        // Set default color (no team color)
        SetEntityRenderMode(bot, RENDER_NORMAL);
        SetEntityRenderColor(bot, 255, 255, 255, 255);  // Default white color
        
        // Store bot's reference and explicitly set no team
        g_iSaferoomBot = bot;
        g_bSaferoomBotActive = true;
        g_iPlayerTeam[bot] = -1;  // Explicitly set to no team
        
        // Create timers
        CreateTimer(1.0, Timer_KeepBotAlive, bot, TIMER_REPEAT);
        CreateTimer(5400.0, Timer_RemoveSaferoomBot, bot);
        
        PrintToChatAll("\x04[PvP] \x01Saferoom bot has been spawned! Will remain for 90 minutes.");
    }
    else
    {
        KickClient(bot);
        ReplyToCommand(client, "\x04[PvP] \x01Failed to spawn saferoom bot!");
    }

    return Plugin_Handled;
}

// Add helper function to check if client is saferoom bot
bool IsSaferoomBot(int client)
{
    return (g_bSaferoomBotActive && client == g_iSaferoomBot);
}

// Update IsValidClient to exclude saferoom bot
bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsSaferoomBot(client));
}

public Action Timer_TeleportAndEquip(Handle timer, any client)
{
    if (!IsValidClient(client) || !g_bPvPActive)
        return Plugin_Stop;

    PrintToServer("[TDM Debug] Teleporting and equipping: %N", client);

    // Make sure player is alive
    if (!IsPlayerAlive(client))
    {
        L4D_RespawnPlayer(client);
        CreateTimer(0.2, Timer_TeleportAndEquip, client);
        return Plugin_Stop;
    }

    // Teleport to team spawn
    TeleportToSpawn(client, g_iPlayerTeam[client]);
    
    // Give loadout
    GiveRandomLoadout(client);
    // AnnounceLoadout(client); // Commented out to avoid duplicate messages
    
    // Add a timer to announce loadout after a short delay
    CreateTimer(0.7, Timer_ForceAnnounceLoadout, client);

    return Plugin_Stop;
}

public Action Timer_GiveLoadout(Handle timer, any client)
{
    if (!IsValidClient(client) || (!g_bPvPActive && !g_bFFAActive))
        return Plugin_Stop;
        
    // Give weapons and items
    StripWeapons(client);
    
    // Give random primary weapon
    int randomPrimary = GetRandomInt(0, sizeof(g_sPrimaryWeapons) - 1);
    GivePlayerItem(client, g_sPrimaryWeapons[randomPrimary]);
    
    // Give random secondary weapon
    int randomSecondary = GetRandomInt(0, sizeof(g_sSecondaryWeapons) - 1);
    GivePlayerItem(client, g_sSecondaryWeapons[randomSecondary]);
    
    // Give random grenade
    int randomGrenade = GetRandomInt(0, sizeof(g_sGrenades) - 1);
    GivePlayerItem(client, g_sGrenades[randomGrenade]);
    
    // Use timer to announce loadout for all players including host
    CreateTimer(0.7, Timer_ForceAnnounceLoadout, client);
    
    return Plugin_Stop;
}

public Action Timer_CheckTeamAssignment(Handle timer, any client)
{
    if (!IsValidClient(client) || !g_bPvPActive || client == g_iSaferoomBot || g_bIsJoining[client])
        return Plugin_Stop;
    
    // If player doesn't have a team yet, assign them to the team with fewer players
    if (g_iPlayerTeam[client] == -1)
    {
        g_iPlayerTeam[client] = GetTeamWithFewerPlayers();
        g_bIsJoining[client] = true;
        
        // Set team colors without announcement (announcement happens in Command_JoinGame)
        if (g_iPlayerTeam[client] == TEAM_A)
        {
            SetEntityRenderColor(client, 255, 0, 0, 255);  // Red
        }
        else
        {
            SetEntityRenderColor(client, 0, 0, 255, 255);  // Blue
        }
        
        // Give loadout and teleport
        GiveRandomLoadout(client);
        TeleportToSpawn(client, g_iPlayerTeam[client]);
        
        // Enable spawn protection
        g_bSpawnProtection[client] = true;
        SetEntityRenderColor(client, 0, 255, 0, 200);  // Green color with slight transparency
        CreateTimer(SPAWN_PROTECTION_TIME, Timer_RemoveSpawnProtection, client);
        
        // Reset joining flag after a delay
        CreateTimer(1.0, Timer_ResetJoiningFlag, client);
    }
    
    return Plugin_Stop;
}

public void OnPluginEnd()
{
    // Restore default values when plugin is unloaded
    if (g_hDirectorNoSpecials != null)
        g_hDirectorNoSpecials.IntValue = 0;
    if (g_hCommonLimit != null)
        g_hCommonLimit.IntValue = 30;
    if (g_hSpecialSpawnInterval != null)
        g_hSpecialSpawnInterval.IntValue = 45;
    if (g_hDirectorNoMobs != null)
        g_hDirectorNoMobs.IntValue = 0;
    if (g_hDirectorNoBosses != null)
        g_hDirectorNoBosses.IntValue = 0;
        
    // Remove saferoom bot if exists
    if (g_iSaferoomBot != -1 && IsClientInGame(g_iSaferoomBot))
    {
        KickClient(g_iSaferoomBot);
        g_iSaferoomBot = -1;
        g_bSaferoomBotActive = false;
    }
    
    if (g_hMenuReminderTimer != null)
    {
        KillTimer(g_hMenuReminderTimer);
        g_hMenuReminderTimer = null;
    }
    
    if (g_hSwitchReminderTimer != null)
    {
        KillTimer(g_hSwitchReminderTimer);
        g_hSwitchReminderTimer = null;
    }

    // Add FFA cleanup
    if (g_bFFAActive)
    {
        EndFFAMode();
    }
    
    if (g_hFFARoundTimer != null)
    {
        KillTimer(g_hFFARoundTimer);
        g_hFFARoundTimer = null;
    }
    
    // End One Shot mode if active
    if (g_bOneShotMode)
    {
        EndOneShotMode();
    }

    RemoveAllTeamGlows();
    for (int i = 1; i <= MaxClients; i++)
    {
        RemoveKillcamGlow(i);
    }
    CleanupOrphanPvPGlowProxies();
    RestoreClimbPluginGlow();
    SetControlledGlowRendering(false);
}

public Action Command_ShowScore(int client, int args)
{
    if (g_bFFAActive)
    {
        PrintToChat(client, "\x04[FFA] \x01 Current Scores:");
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                PrintToChat(client, "\x04%N\x01: %d kills", i, g_iFFAKills[i]);
            }
        }
        return Plugin_Handled;
    }
    else if (g_bPvPActive)
    {
        PrintToChat(client, "\x04[TDM] \x01 Current Score: Red \x04%d\x01 - Blue \x04%d", 
            g_iTeamScores[TEAM_A], g_iTeamScores[TEAM_B]);
        return Plugin_Handled;
    }
    
    PrintToChat(client, "\x04[PvP] \x01No game mode is currently active!");
    return Plugin_Handled;
}

public void OnMapStart()
{
    // Precache models and materials
    g_iBeamSprite = PrecacheModel(SPRITE_BEAM, true);
    if (g_iBeamSprite == 0)
    {
        SetFailState("Failed to precache sprite on map start: %s", SPRITE_BEAM);
    }
    PrecacheModel("materials/sprites/laserbeam.vmt", true);
    PrecacheModel("materials/sprites/laserbeam.vtf", true);
    
    // Precache survivor models
    PrecacheModel("models/survivors/survivor_gambler.mdl", true);
    PrecacheModel("models/survivors/survivor_producer.mdl", true);
    PrecacheModel("models/survivors/survivor_coach.mdl", true);
    PrecacheModel("models/survivors/survivor_mechanic.mdl", true);
    
    // Precache AWP models
    PrecacheModel(CSS_AWP_MODEL, true);
    PrecacheModel("models/v_models/v_snip_awp.mdl", true);
    
    // Precache Gun Game sounds
    PrecacheSound(SOUND_GUN_GAME_LEVEL_UP, true);
    PrecacheSound(SOUND_GUN_GAME_KNIFE_LEVEL, true);
    PrecacheSound(SOUND_PVP_KILL, true);
    PrecacheSound(SOUND_PVP_HEADSHOT_KILL, true);
    
    // Load spawn points for the current map
    LoadSpawnPoints();
    LoadWarmupSpawns();
    g_iFFASpawnCount = 0;
    ResetTDMCenterHistory();
    
    // Reset match state ABER behalte Modi-Flags für Auto-Join
    g_bMatchEnded = false;
    g_bWarmupActive = false;
    // NICHT die Modi-Flags resetten! Sie bleiben bestehen.
    
    // Clear all timers
    ClearAllTimers();
    RemoveInvisibleWalls();
    RemoveFinaleEntities();
    // Also clear persistent spawn display timers and flags on map change
    g_bShowAllSpawnsPersistent = false;
    if (g_hShowSpawnsTimer != null)
    {
        KillTimer(g_hShowSpawnsTimer);
        g_hShowSpawnsTimer = null;
    }
    g_bShowTDMSpawnsPersistent = false;
    if (g_hShowTDMSpawnsTimer != null)
    {
        KillTimer(g_hShowTDMSpawnsTimer);
        g_hShowTDMSpawnsTimer = null;
    }
    g_bShowWarmupSpawnsPersistent = false;
    if (g_hShowWarmupSpawnsTimer != null)
    {
        KillTimer(g_hShowWarmupSpawnsTimer);
        g_hShowWarmupSpawnsTimer = null;
    }
    g_bShowFFASpawnsPersistent = false;
    if (g_hShowFFASpawnsTimer != null)
    {
        KillTimer(g_hShowFFASpawnsTimer);
        g_hShowFFASpawnsTimer = null;
    }
    
    // Precache knife models to make sure they're available
    PrecacheModel("models/weapons/melee/v_knife.mdl", true);
    PrecacheModel("models/weapons/melee/w_knife.mdl", true);
    
    // Reset kill request system
    ClearKillRequest();
    
    // Reset nur die Spieler-spezifischen Daten, nicht die Modi
    for (int i = 1; i <= MaxClients; i++)
    {
        g_iPlayerKills[i] = 0;
        g_iPlayerDeaths[i] = 0;
        g_iFFAKills[i] = 0;
        g_iAWPKills[i] = 0;
        g_iGunGameLevel[i] = 0;
        g_iGunGameKills[i] = 0;
        g_bSpawnProtection[i] = false;
        RemoveKillcamGlow(i);
        RemoveTeamGlow(i);
        g_bInKillcam[i] = false;
        g_iKillcamTarget[i] = -1;
        g_iPlayerTeam[i] = -1; // Wichtig: Team-Zuweisungen zurücksetzen
        
        if (IsValidClient(i))
        {
            SetEntityRenderColor(i, 255, 255, 255, 255);
        }
    }
    
    // Reset team scores
    g_iTeamScores[TEAM_A] = 0;
    g_iTeamScores[TEAM_B] = 0;

    if (IsControlledGlowModeActive())
    {
        EnsureGlowRefreshTimer();
    }

    if (g_bPvPActive || g_bFFAActive || g_bAWPActive || g_bGunGameActive || g_bOneShotMode)
    {
        CreateTimer(1.5, Timer_RestoreActiveModeAfterMapStart, _, TIMER_FLAG_NO_MAPCHANGE);
    }
}

void ClearAllTimers()
{
    // Clear round timer
    if (g_hRoundTimer != null)
    {
        KillTimer(g_hRoundTimer);
        g_hRoundTimer = null;
    }
    
    // Clear FFA round timer
    if (g_hFFARoundTimer != null)
    {
        KillTimer(g_hFFARoundTimer);
        g_hFFARoundTimer = null;
    }
    
    // Clear respawn timers
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_hRespawnTimers[i] != null)
        {
            KillTimer(g_hRespawnTimers[i]);
            g_hRespawnTimers[i] = null;
        }
    }
    
    // Clear other timers
    if (g_hInfectedCheckTimer != null)
    {
        KillTimer(g_hInfectedCheckTimer);
        g_hInfectedCheckTimer = null;
    }
    if (g_hTeamGlowRefreshTimer != null)
    {
        KillTimer(g_hTeamGlowRefreshTimer);
        g_hTeamGlowRefreshTimer = null;
    }

    if (g_hMenuReminderTimer != null)
    {
        KillTimer(g_hMenuReminderTimer);
        g_hMenuReminderTimer = null;
    }
    
    if (g_hSwitchReminderTimer != null)
    {
        KillTimer(g_hSwitchReminderTimer);
        g_hSwitchReminderTimer = null;
    }

    // Clear persistent spawn display timers as a safety net
    if (g_hShowSpawnsTimer != null)
    {
        KillTimer(g_hShowSpawnsTimer);
        g_hShowSpawnsTimer = null;
    }
    if (g_hShowTDMSpawnsTimer != null)
    {
        KillTimer(g_hShowTDMSpawnsTimer);
        g_hShowTDMSpawnsTimer = null;
    }
    if (g_hShowWarmupSpawnsTimer != null)
    {
        KillTimer(g_hShowWarmupSpawnsTimer);
        g_hShowWarmupSpawnsTimer = null;
    }
    if (g_hShowFFASpawnsTimer != null)
    {
        KillTimer(g_hShowFFASpawnsTimer);
        g_hShowFFASpawnsTimer = null;
    }
}

public Action Timer_RestoreActiveModeAfterMapStart(Handle timer)
{
    if (g_bFFAActive || g_bAWPActive || g_bGunGameActive || g_bPvPActive || g_bOneShotMode)
    {
        g_bMatchEnded = false;
    }

    if (g_bFFAActive || g_bAWPActive || g_bGunGameActive)
    {
        PrepareGeneratedFFASpawns(g_bGunGameActive ? "Gun Game" : (g_bAWPActive ? "AWP" : "FFA"), 0);
    }

    if (g_bOneShotMode)
    {
        PrepareGeneratedTDMSpawns("One Shot", 0);
        AssignTeams();
        StartTDMArenaTimer();

        if (g_hRoundTimer == null)
        {
            g_hRoundTimer = CreateTimer(float(g_cvRoundTime.IntValue), Timer_RoundEnd, _, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    else if (g_bPvPActive)
    {
        PrepareManualTDMSpawns("TDM", 0);
        AssignTeams();
        StartTDMArenaTimer();

        if (g_hRoundTimer == null)
        {
            g_hRoundTimer = CreateTimer(float(g_cvRoundTime.IntValue), Timer_RoundEnd, _, TIMER_FLAG_NO_MAPCHANGE);
        }
    }

    if (g_bFFAActive && !g_bGunGameActive && g_hFFARoundTimer == null)
    {
        g_fFFAStartTime = GetGameTime();
        g_hFFARoundTimer = CreateTimer(float(g_cvFFARoundTime.IntValue), Timer_EndFFA, _, TIMER_FLAG_NO_MAPCHANGE);
    }

    if (g_bGunGameActive && g_hGunGameRoundTimer == null)
    {
        g_fFFAStartTime = GetGameTime();
        g_hGunGameRoundTimer = CreateTimer(float(g_cvFFARoundTime.IntValue), Timer_EndGunGame, _, TIMER_FLAG_NO_MAPCHANGE);
    }

    if (g_bAWPActive && g_hAWPRoundTimer == null)
    {
        g_fAWPStartTime = GetGameTime();
        g_hAWPRoundTimer = CreateTimer(float(g_cvAWPRoundTime.IntValue), Timer_AWPRoundEnd, _, TIMER_FLAG_NO_MAPCHANGE);
    }

    SetControlledGlowRendering(true);
    DisableNonPvPGlows();
    ApplyPvPMapCleanup();
    EnsureGlowRefreshTimer();
    RemoveAllInfected();

    if (g_hInfectedCheckTimer == null)
    {
        g_hInfectedCheckTimer = CreateTimer(1.0, Timer_CheckInfected, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i) || IsFakeClient(i))
            continue;

        ChangeClientTeam(i, TEAM_SURVIVOR);

        if (g_bGunGameActive)
        {
            CreateTimer(0.4, Timer_SetupGunGamePlayer, i, TIMER_FLAG_NO_MAPCHANGE);
        }
        else if (g_bFFAActive)
        {
            CreateTimer(0.4, Timer_SetupFFAPlayer, i, TIMER_FLAG_NO_MAPCHANGE);
        }
        else if (g_bAWPActive)
        {
            CreateTimer(0.4, Timer_SetupAWPPlayer, i, TIMER_FLAG_NO_MAPCHANGE);
        }
        else if (g_bPvPActive)
        {
            CreateTimer(0.4, Timer_TeleportAndEquip, i, TIMER_FLAG_NO_MAPCHANGE);
        }
    }

    CleanupGroundWeapons();
    CreateTimer(5.0, Timer_CleanupGroundWeapons, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Stop;
}

public void OnClientPutInServer(int client)
{
    if (!IsValidClient(client) || IsFakeClient(client))
        return;
        
    // Reset player's team and stats
    g_iPlayerTeam[client] = -1;
    g_iPlayerKills[client] = 0;
    g_iPlayerDeaths[client] = 0;
    g_iFFAKills[client] = 0;
    g_iAWPKills[client] = 0;
    g_bSpawnProtection[client] = false;
    g_bIsJoining[client] = false;
    g_sLastWeapon[client][0] = '\0';
    g_sLastHurtWeapon[client][0] = '\0';
    g_iLastAttacker[client] = 0;
    g_fLastPvPAttackTime[client] = 0.0;
    g_fNextHitMarkerTime[client] = 0.0;
    g_iKillcamGlowProxy[client] = 0;
    g_iTeamGlowProxy[client] = 0;
    g_iTeamGlowProxyTeam[client] = -1;
    g_bTeamGlowExternal[client] = false;
    
    // Reset Gun Game stats when players join to fix the leveling issue
    g_iGunGameLevel[client] = 0;
    g_iGunGameKills[client] = 0;
    g_bKnifeLevelSetup[client] = false;
    g_fLastGunGameWeaponMsgTime[client] = -99999.0;
    g_fLastGunGameFinalMsgTime[client] = -99999.0;

    // Hook damage
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    
    // Handle joining players based on game mode with single reliable timer per mode
    if (g_bPvPActive)
    {
        PrintToServer("[TDM Debug] Setting up TDM player: %N", client);
        CreateTimer(1.0, Timer_SetupPvPPlayer, client); // Single timer with longer delay
        SchedulePvPJoinSpawnVerify(client, 2.0, 0);
        PrintToChat(client, "\x04[TDM] \x01Welcome to Team Deathmatch! You will be assigned to a team shortly...");
    }
    else if (g_bFFAActive && !g_bGunGameActive) // FFA but not Gun Game
    {
        PrintToServer("[FFA Debug] Setting up FFA player: %N", client);
        ChangeClientTeam(client, TEAM_SURVIVOR);
        CreateTimer(1.0, Timer_SetupFFAPlayer, client);
        PrintToChat(client, "\x04[FFA] \x01Welcome to Free-for-All mode! You will spawn shortly...");
    }
    else if (g_bGunGameActive)
    {
        PrintToServer("[GunGame Debug] Setting up Gun Game player: %N", client);
        ChangeClientTeam(client, TEAM_SURVIVOR);
        CreateTimer(1.0, Timer_SetupGunGamePlayer, client);
        PrintToChat(client, "\x04[Gun Game] \x01Welcome to Gun Game mode! You will spawn shortly...");
    }
    else if (g_bAWPActive)
    {
        PrintToServer("[AWP Debug] Setting up AWP player: %N", client);
        ChangeClientTeam(client, TEAM_SURVIVOR);
        CreateTimer(1.0, Timer_SetupAWPPlayer, client);
        PrintToChat(client, "\x04[AWP] \x01Welcome to AWP mode! You will spawn shortly...");
    }

    // Apply configured music setting for newly connected players.
    ApplyPvPMusicSettingsToClient(client);

    // Add this function to fix the 300 HP issue
    CreateTimer(0.5, Timer_CheckAbnormalHealth, client);
}

public Action Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (!IsValidClient(client))
        return Plugin_Continue;
        
    // Kill player instantly if in FFA, TDM, or AWP mode
    if (g_bFFAActive || g_bPvPActive || g_bAWPActive)
    {
        ForcePlayerSuicide(client);
        return Plugin_Continue;
    }
    
    return Plugin_Continue;
}

// Add this new function after Event_PlayerIncap
public Action Event_PlayerLedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (IsValidClient(client))
    {
        // Method 1: Apply immediate vertical velocity to force them down
        float vel[3] = {0.0, 0.0, -300.0};
        TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
        
        // Method 2: Force incapacitation instantly then force suicide
        L4D_SetPlayerIncapState(client, false);
        L4D_SetPlayerIsIncapacitated(client, false);
        
        // Method 3: Fully clear incap state
        SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0);
        SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
        
        // Only add a small delay for secondary fallback
        CreateTimer(0.05, Timer_ForceLedgeLetGo, client);
        
        // Debug message
        PrintToServer("[Debug] Applying aggressive ledge grab prevention for %N", client);
    }
    
    return Plugin_Continue;
}

public Action Timer_ForceLedgeLetGo(Handle timer, any client)
{
    if (IsValidClient(client) && IsPlayerAlive(client))
    {
        // Apply multiple techniques again as fallback
        float pos[3];
        GetClientAbsOrigin(client, pos);
        
        // Move player down slightly to break any ledge grab
        pos[2] -= 5.0;
        TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
        
        // Apply stronger downward force
        float vel[3] = {0.0, 0.0, -400.0};
        TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
        
        // Clear hanging state flags again
        SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0);
        SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
    }
    
    return Plugin_Stop;
}

// Helper function for L4D engine functionality
bool L4D_SetPlayerIncapState(int client, bool bIncap)
{
    if (!IsValidClient(client))
        return false;
        
    SetEntProp(client, Prop_Send, "m_isIncapacitated", bIncap ? 1 : 0);
    return true;
}

bool L4D_SetPlayerIsIncapacitated(int client, bool bIncap)
{
    if (!IsValidClient(client))
        return false;
        
    SetEntProp(client, Prop_Send, "m_isHangingFromLedge", bIncap ? 1 : 0);
    return true;
}

void AssignTeams()
{
    ArrayList players = new ArrayList();
    
    // Collect all valid players (exclude bots)
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR)
        {
            players.Push(i);
        }
    }
    
    // Reset team assignments
    for (int i = 1; i <= MaxClients; i++)
    {
        g_iPlayerTeam[i] = -1;
    }
    
    // Shuffle players
    for (int i = players.Length - 1; i > 0; i--)
    {
        int j = GetRandomInt(0, i);
        int temp = players.Get(i);
        players.Set(i, players.Get(j));
        players.Set(j, temp);
    }
    
    // Calculate how many players can be assigned to teams
    int maxPlayersPerTeam = PLAYERS_PER_TEAM;
    int totalPlayers = players.Length;
    int assignablePlayers = (totalPlayers > maxPlayersPerTeam * 2) ? maxPlayersPerTeam * 2 : totalPlayers;
    
    // Randomly assign players to teams
    for (int i = 0; i < assignablePlayers; i++)
    {
        int client = players.Get(i);
        
        // Determine team based on current balance
        int teamACount = 0, teamBCount = 0;
        for (int j = 1; j <= MaxClients; j++)
        {
            if (g_iPlayerTeam[j] == TEAM_A) teamACount++;
            else if (g_iPlayerTeam[j] == TEAM_B) teamBCount++;
        }
        
        // Assign to team with fewer players, or randomly if equal
        int assignedTeam;
        if (teamACount < teamBCount)
            assignedTeam = TEAM_A;
        else if (teamBCount < teamACount)
            assignedTeam = TEAM_B;
        else
            assignedTeam = GetRandomInt(0, 1) == 0 ? TEAM_A : TEAM_B;
        
        g_iPlayerTeam[client] = assignedTeam;
        
        // Set team colors and notify player
        if (assignedTeam == TEAM_A)
        {
            SetEntityRenderColor(client, 255, 0, 0, 255);
            if (!IsFakeClient(client))
                PrintToChat(client, "\x04[PvP] \x01You have been assigned to the \x04 RED\x01 team!");
        }
        else
        {
            SetEntityRenderColor(client, 0, 0, 255, 255);
            if (!IsFakeClient(client))
                PrintToChat(client, "\x04[PvP] \x01You have been assigned to the \x04 BLUE\x01 team!");
        }
    }
    
    // Move excess players to spectator
    for (int i = assignablePlayers; i < players.Length; i++)
    {
        int client = players.Get(i);
        ChangeClientTeam(client, 1);
        if (!IsFakeClient(client))
            PrintToChat(client, "\x04[PvP] \x01You have been moved to spectator mode as teams are full!");
    }
    
    // Print team counts
    int finalTeamACount = 0, finalTeamBCount = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_iPlayerTeam[i] == TEAM_A) finalTeamACount++;
        else if (g_iPlayerTeam[i] == TEAM_B) finalTeamBCount++;
    }
    PrintToChatAll("\x04[TDM] \x01Teams assigned: \x04%d\x01 Red vs \x04%d\x01 Blue", finalTeamACount, finalTeamBCount);
    
    delete players;
}

void RemoveAllInfected()
{
    static const char infectedTypes[][] = {
        "infected",
        "witch", 
        "tank",
        "boomer",
        "smoker", 
        "hunter",
        "spitter",
        "jockey",
        "charger"
    };
    
    // Remove all infected entities
    int entity = -1;
    for (int i = 0; i < sizeof(infectedTypes); i++)
    {
        while ((entity = FindEntityByClassname(entity, infectedTypes[i])) != -1)
        {
            RemoveEntity(entity);
        }
    }
    
    // Remove all special infected bots
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3)
        {
            KickClient(i, "Special Infected not allowed in PvP mode");
        }
    }
    
    // Disable director using the handles
    g_hDirectorNoSpecials.IntValue = 1;
    g_hCommonLimit.IntValue = 0;
    g_hSpecialSpawnInterval.IntValue = 999999;
    g_hDirectorNoMobs.IntValue = 1;
    g_hDirectorNoBosses.IntValue = 1;
}

public Action Timer_CheckInfected(Handle timer)
{
    if (!g_bPvPActive)
    {
        g_hInfectedCheckTimer = null;
        return Plugin_Stop;
    }
    
    // Remove all infected
    RemoveAllInfected();
    
    // Re-enforce director settings every check
    g_hDirectorNoSpecials.IntValue = 1;
    g_hCommonLimit.IntValue = 0;
    g_hSpecialSpawnInterval.IntValue = 999999;
    g_hDirectorNoMobs.IntValue = 1;
    g_hDirectorNoBosses.IntValue = 1;
    
    return Plugin_Continue;
}

void FinishRespawn(int client)
{
    if (!IsValidClient(client))
        return;
        
    // Reset player state
    SetEntProp(client, Prop_Send, "m_isGhost", 0);
    SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
    SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
    SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
    
    // Remove the problematic line and use these instead
    SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
    SetEntProp(client, Prop_Send, "m_iHealth", 100);
    SetEntProp(client, Prop_Send, "m_iMaxHealth", 100);
    SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
    SetEntProp(client, Prop_Send, "m_lifeState", 0);
    
    // Force team
    if (GetClientTeam(client) != TEAM_SURVIVOR)
    {
        ChangeClientTeam(client, TEAM_SURVIVOR);
    }
}

public Action Timer_FinishRespawn(Handle timer, any client)
{
    FinishRespawn(client);
    return Plugin_Stop;
}

void StripWeapons(int client)
{
    // Strip all weapons
    int itemIdx;
    for (int i = 0; i <= 4; i++)
    {
        while ((itemIdx = GetPlayerWeaponSlot(client, i)) != -1)
        {
            RemovePlayerItem(client, itemIdx);
            AcceptEntityInput(itemIdx, "Kill");
        }
    }
}

public Action Command_StartPvP(int client, int args)
{
    if (GetGameTime() < g_fPvPStopLockUntil)
    {
        ReplyToCommand(client, "\x04[PvP] \x01PvP was just stopped. Try again in a moment.");
        return Plugin_Handled;
    }

    // Prüfung angepasst: Nur warnen wenn bereits eine aktive Runde läuft, nicht nur wenn der Flag gesetzt ist
    if (g_bPvPActive && !g_bMatchEnded)
    {
        ReplyToCommand(client, "\x04[PvP] \x01 PvP mode is already active!");
        return Plugin_Handled;
    }

    if (g_bFFAActive || g_bAWPActive || g_bGunGameActive)
    {
        ReplyToCommand(client, "\x04[PvP] \x01 Cannot start while another mode is active!");
        return Plugin_Handled;
    }

    if (!PrepareManualTDMSpawns("TDM", client))
    {
        return Plugin_Handled;
    }

    // Initialize PvP mode using shared function
    InitializePvPMode();
    g_bMatchEnded = false; // Explizit auf false setzen

    // Add initial spawn point loading check
    if (g_iWarmupSpawnCount == 0)
    {
        LoadWarmupSpawns();
    }

    // Reset team scores und player stats für neuen Match
    g_iTeamScores[TEAM_A] = 0;
    g_iTeamScores[TEAM_B] = 0;
    
    // Reset player stats für neuen Match
    for (int i = 1; i <= MaxClients; i++)
    {
        g_iPlayerKills[i] = 0;
        g_iPlayerDeaths[i] = 0;
        g_bSpawnProtection[i] = false;
        // Team-Zuweisungen zurücksetzen für neue Zuweisung
        g_iPlayerTeam[i] = -1;
        
        if (IsValidClient(i))
        {
            SetEntityRenderColor(i, 255, 255, 255, 255);
        }
    }

    // Only start warmup if enabled
    if (g_cvWarmupEnabled.BoolValue)
    {
        g_bWarmupActive = true;
        AssignTeams(); // Teams vor warmup zuweisen
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i) && !IsFakeClient(i))
            {
                SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
                TeleportToWarmupSpawn(i);
                GiveWarmupLoadout(i);
            }
        }
        CreateTimer(WARMUP_TIME, Timer_WarmupEnd);
        PrintToChatAll("\x04[TDM] \x01 Warmup phase: \x04%.0f\x01 seconds!", WARMUP_TIME);
    }
    else
    {
        g_bWarmupActive = false;
        AssignTeams();
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i) && !IsFakeClient(i))
            {
                if (g_iPlayerTeam[i] != -1)
                {
                    SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
                    TeleportToSpawn(i, g_iPlayerTeam[i]);
                    GiveRandomLoadout(i);
                    AnnounceLoadout(i);
                }
            }
        }
        PrintToChatAll("\x04[TDM] \x01 Match is now live! First team to \x04%d\x01 kills wins!", g_cvScoreLimit.IntValue);
    }

    // Start both reminder timers - sichere Timer-Handhabung
    if (g_hSwitchReminderTimer != null)
    {
        KillTimer(g_hSwitchReminderTimer);
        g_hSwitchReminderTimer = null;
    }
    g_hSwitchReminderTimer = CreateTimer(GetRandomFloat(30.0, 60.0), Timer_SwitchReminder);
    
    if (g_hMenuReminderTimer != null)
    {
        KillTimer(g_hMenuReminderTimer);
        g_hMenuReminderTimer = null;
    }
    g_hMenuReminderTimer = CreateTimer(GetRandomFloat(30.0, 60.0), Timer_MenuReminder);
    
    // Start round timer - sichere Timer-Handhabung
    if (g_hRoundTimer != null)
    {
        KillTimer(g_hRoundTimer);
        g_hRoundTimer = null;
    }
    g_hRoundTimer = CreateTimer(float(g_cvRoundTime.IntValue), Timer_RoundEnd);
    
    // Spawn saferoom bot if not already active
    if (!g_bSaferoomBotActive)
    {
        // Create the bot
        int bot = CreateFakeClient("SaferoomBot");
        if (bot != 0)
        {
            ChangeClientTeam(bot, TEAM_SURVIVOR);
            if (DispatchKeyValue(bot, "classname", "survivor") && DispatchSpawn(bot))
            {
                // Set bot's position to client's position or saferoom
                float pos[3], ang[3];
                if (client > 0 && IsValidClient(client))
                {
                    GetClientAbsOrigin(client, pos);
                    GetClientAbsAngles(client, ang);
                }
                else
                {
                    // Default saferoom position if no client
                    pos[0] = 0.0;
                    pos[1] = 0.0;
                    pos[2] = 0.0;
                }

                TeleportEntity(bot, pos, ang, NULL_VECTOR);
                
                // Make bot immortal
                SetEntProp(bot, Prop_Data, "m_takedamage", 0, 1);
                
                // Store bot's reference
                g_iSaferoomBot = bot;
                g_bSaferoomBotActive = true;
                
                // Initial settings
                SetEntProp(bot, Prop_Send, "m_iTeamNum", TEAM_SURVIVOR);
                
                // Create a repeating timer to keep the bot active
                CreateTimer(1.0, Timer_KeepBotAlive, bot, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
                
                // Create a timer to remove the bot after 90 minutes
                CreateTimer(5400.0, Timer_RemoveSaferoomBot, bot, TIMER_FLAG_NO_MAPCHANGE);
                
                PrintToChatAll("\x04[PvP] \x01 Saferoom bot has been spawned! Will remain for 90 minutes.");
            }
            else
            {
                KickClient(bot);
                PrintToServer("[PvP] Failed to spawn saferoom bot!");
            }
        }
    }
    
    RemoveAllInfected();
    StartTDMArenaTimer();
    
    // Remove all ground weapons and set up cleanup timer
    CleanupGroundWeapons();
    CreateTimer(5.0, Timer_CleanupGroundWeapons, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    
    return Plugin_Handled;
}

public Action Command_StopPvP(int client, int args)
{
    g_fPvPStopLockUntil = GetGameTime() + PVP_STOP_LOCK_TIME;
    g_bMatchEnded = true;
    g_bWarmupActive = false;

    if (!g_bPvPActive && !g_bOneShotMode)
    {
        RemoveAllTeamGlows();
        CleanupOrphanPvPGlowProxies();
        DisableNonPvPGlows();
        StopGlowRefreshTimerIfIdle();
        ReplyToCommand(client, "\x04[PvP] \x01PvP mode is not active!");
        return Plugin_Handled;
    }
    
    // Remove saferoom bot if exists
    if (g_iSaferoomBot != -1 && IsClientInGame(g_iSaferoomBot))
    {
        KickClient(g_iSaferoomBot);
        g_iSaferoomBot = -1;
        g_bSaferoomBotActive = false;
    }
    
    if (g_hMenuReminderTimer != null)
    {
        KillTimer(g_hMenuReminderTimer);
        g_hMenuReminderTimer = null;
    }
    
    if (g_hSwitchReminderTimer != null)
    {
        KillTimer(g_hSwitchReminderTimer);
        g_hSwitchReminderTimer = null;
    }
    
    if (g_bOneShotMode)
    {
        EndOneShotMode();
    }
    EndPvPMode();
    PrintToChatAll("\x04[PvP] \x01PvP mode has been stopped by an admin!");
    return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
    if (!IsValidClient(client))
        return Plugin_Continue;

    char text[64];
    strcopy(text, sizeof(text), sArgs);
    TrimString(text);

    if (StrEqual(text, "!stoppvp", false) || StrEqual(text, "/stoppvp", false))
    {
        if (CheckCommandAccess(client, "sm_stoppvp", ADMFLAG_ROOT, true) || IsClientHost(client))
        {
            Command_StopPvP(client, 0);
            return Plugin_Stop;
        }
    }
    else if (StrEqual(text, "!startpvp", false) || StrEqual(text, "/startpvp", false))
    {
        if (CheckCommandAccess(client, "sm_startpvp", ADMFLAG_ROOT, true))
        {
            Command_StartPvP(client, 0);
            return Plugin_Stop;
        }
    }

    return Plugin_Continue;
}

public Action Listener_RawSayCommand(int client, const char[] command, int argc)
{
    if (client <= 0 || !IsClientInGame(client))
        return Plugin_Continue;

    char text[128];
    GetCmdArgString(text, sizeof(text));
    StripQuotes(text);
    TrimString(text);

    if (StrEqual(text, "!stoppvp", false) || StrEqual(text, "/stoppvp", false))
    {
        if (CheckCommandAccess(client, "sm_stoppvp", ADMFLAG_ROOT, true) || IsClientHost(client))
        {
            Command_StopPvP(client, 0);
        }
        return Plugin_Stop;
    }

    if (StrEqual(text, "!startpvp", false) || StrEqual(text, "/startpvp", false))
    {
        if (GetGameTime() < g_fPvPStopLockUntil)
        {
            ReplyToCommand(client, "\x04[PvP] \x01PvP was just stopped. Try again in a moment.");
            return Plugin_Stop;
        }
    }

    return Plugin_Continue;
}

public Action Command_Help(int client, int args)
{
    PrintToChat(client, "\x04[PvP] \x01 Available Commands:");
    PrintToChat(client, "\x04!score \x01- Show current match score");
    
    // Only show admin commands to admins
    if (CheckCommandAccess(client, "sm_generic", ADMFLAG_ROOT))
    {
        PrintToChat(client, "\x04=== Team Deathmatch Commands ===");
        PrintToChat(client, "\x04!startpvp \x01- Start Team Deathmatch mode");
        PrintToChat(client, "\x04!stoppvp \x01- Stop Team Deathmatch mode");
        PrintToChat(client, "\x04!addspawn \x01<team> - Add spawn point for team (0=Red, 1=Blue)");
        PrintToChat(client, "\x04!deletespawn \x01- Delete closest spawn point");
        PrintToChat(client, "\x04!showspawns \x01- Show all team spawn points");
        PrintToChat(client, "\x04!savespawns \x01- Save all team spawn points");
        
        PrintToChat(client, "\x04=== Free-for-All Commands ===");
        PrintToChat(client, "\x04!startffa \x01- Start Free-for-All mode");
        PrintToChat(client, "\x04!stopffa \x01- Stop Free-for-All mode");
        PrintToChat(client, "\x04!addffa \x01- Add a FFA spawn point");
        PrintToChat(client, "\x04!deleteffaspawn \x01- Delete closest FFA spawn point");
        PrintToChat(client, "\x04!showffaspawns \x01- Show all FFA spawn points");
        PrintToChat(client, "\x04!saveffaspawns \x01- Save all FFA spawn points");
        
        PrintToChat(client, "\x04=== AWP Mode Commands ===");
        PrintToChat(client, "\x04!startawp \x01- Start AWP mode");
        PrintToChat(client, "\x04!stopawp \x01- Stop AWP mode");
        
        PrintToChat(client, "\x04=== Custom Game Modes ===");
        PrintToChat(client, "\x04!startoneshot \x01- Start One Shot TDM mode (1 HP, instant kills)");
        PrintToChat(client, "\x04!stoponeshot \x01- Stop One Shot TDM mode");
        PrintToChat(client, "\x04!startgungame \x01- Start Gun Game mode (progress through weapon tiers)");
        PrintToChat(client, "\x04!stopgungame \x01- Stop Gun Game mode");
        
        PrintToChat(client, "\x04=== Warmup Commands ===");
        PrintToChat(client, "\x04!addwarmupspawn \x01- Add a warmup spawn point");
        PrintToChat(client, "\x04!showwarmupspawns \x01- Show all warmup spawn points");
        PrintToChat(client, "\x04!savewarmupspawns \x01- Save all warmup spawn points");
        
        PrintToChat(client, "\x04=== Other Commands ===");
        PrintToChat(client, "\x04!lift \x01- Open the elevator control menu");
        PrintToChat(client, "\x04!spawnbot \x01- Spawn a saferoom anchor bot");
        PrintToChat(client, "\x04!removebot \x01- Remove the saferoom anchor bot");
    }
    
    return Plugin_Handled;
}

public Action Command_AddSpawn(int client, int args)
{
    if (!client) return Plugin_Handled;
    
    if (args < 1)
    {
        ReplyToCommand(client, "[TDM] Usage: !addspawn <team> (0/red = Red, 1/blue = Blue)");
        return Plugin_Handled;
    }
    
    // Use a larger buffer for the argument
    char arg[64];
    GetCmdArg(1, arg, sizeof(arg));
    
    // Print debug info
    PrintToServer("[DEBUG] !addspawn argument: '%s'", arg);
    
    // Default to invalid team
    int team = -1;
    
    // Handle text input for team names with explicit case-insensitive check
    if (StrContains(arg, "red", false) != -1 || StrEqual(arg, "0"))
    {
        team = TEAM_A; // Red team (0)
        PrintToServer("[DEBUG] Identified as RED team");
    }
    else if (StrContains(arg, "blue", false) != -1 || StrEqual(arg, "1"))
    {
        team = TEAM_B; // Blue team (1)
        PrintToServer("[DEBUG] Identified as BLUE team");
    }
    else
    {
        // Try to convert to integer as a fallback with extra safety
        team = StringToInt(arg);
        PrintToServer("[DEBUG] Converted to integer: %d", team);
    }
    
    // Validate team with bounds check
    if (team < 0 || team >= MAX_TEAMS)
    {
        ReplyToCommand(client, "[TDM] Invalid team! Use 0/red for Red team or 1/blue for Blue team.");
        return Plugin_Handled;
    }
    
    // Safety check for spawn count array bounds
    if (g_iSpawnCount[team] < 0)
    {
        g_iSpawnCount[team] = 0;
        PrintToServer("[DEBUG] Reset negative spawn count for team %d", team);
    }
    
    if (g_iSpawnCount[team] >= MAX_SPAWNS)
    {
        ReplyToCommand(client, "[TDM] Maximum spawn points reached for this team!");
        return Plugin_Handled;
    }
    
    // Get client position and angles
    float pos[3], ang[3];
    GetClientAbsOrigin(client, pos);
    GetClientAbsAngles(client, ang);
    
    // Store spawn point
    g_fSpawnPoints[team][g_iSpawnCount[team]] = pos;
    g_fSpawnAngles[team][g_iSpawnCount[team]] = ang;
    g_fTDMSpawnNextUse[team][g_iSpawnCount[team]] = 0.0;
    g_iSpawnCount[team]++;
    
    // Visual confirmation
    float vEndPos[3];
    vEndPos = pos;
    vEndPos[2] += SPRITE_HEIGHT;
    
    int color[4];
    if (team == TEAM_A)
    {
        color[0] = 255;
        color[1] = 0;
        color[2] = 0;
        color[3] = 255;
    }
    else
    {
        color[0] = 0;
        color[1] = 0;
        color[2] = 255;
        color[3] = 255;
    }
    
    TE_SetupBeamPoints(pos, vEndPos, g_iBeamSprite, 0, 0, 0, SPAWN_SHOW_REFRESH, 
        3.0, 3.0, 1, 1.0, color, 0);
    TE_SendToAll();
    if (g_bShowWarmupSpawnsPersistent)
        DrawWarmupSpawnBeams();
    else if (g_bShowAllSpawnsPersistent)
        DrawAllSpawnBeams();
    
    PrintToChatAll("\x04[TDM] \x01New spawn point added for %s team!", team == TEAM_A ? "Red" : "Blue");
    return Plugin_Handled;
}

public Action Command_DeleteSpawn(int client, int args)
{
    if (!client) return Plugin_Handled;
    
    float pos[3];
    GetClientAbsOrigin(client, pos);
    
    float closestDist = 99999.0;
    int closestTeam = -1;
    int closestIndex = -1;
    
    for (int team = 0; team < MAX_TEAMS; team++)
    {
        for (int i = 0; i < g_iSpawnCount[team]; i++)
        {
            float dist = GetVectorDistance(pos, g_fSpawnPoints[team][i]);
            if (dist < closestDist)
            {
                closestDist = dist;
                closestTeam = team;
                closestIndex = i;
            }
        }
    }
    
    if (closestIndex != -1)
    {
        for (int i = closestIndex; i < g_iSpawnCount[closestTeam] - 1; i++)
        {
            g_fSpawnPoints[closestTeam][i] = g_fSpawnPoints[closestTeam][i + 1];
            g_fSpawnAngles[closestTeam][i] = g_fSpawnAngles[closestTeam][i + 1];
            g_fTDMSpawnNextUse[closestTeam][i] = g_fTDMSpawnNextUse[closestTeam][i + 1];
        }
        g_iSpawnCount[closestTeam]--;
        if (g_iLastTDMSpawnIndex[closestTeam] == closestIndex)
            g_iLastTDMSpawnIndex[closestTeam] = -1;
        
        PrintToChatAll("\x04[TDM] \x01Spawn point removed for %s team!", closestTeam == TEAM_A ? "Red" : "Blue");
    }
    else
    {
        PrintToChat(client, "\x04[PvP] \x01No spawn point found nearby!");
    }
    
    return Plugin_Handled;
}

void ShowNextSpawn(int team, int spawnIndex)
{
    float vStartPos[3], vEndPos[3];
    vStartPos = g_fSpawnPoints[team][spawnIndex];
    vEndPos = g_fSpawnPoints[team][spawnIndex];
    vEndPos[2] += SPRITE_HEIGHT;
    
    // Set up the beam
    TE_SetupBeamPoints(vStartPos, vEndPos, g_iBeamSprite, 0, 0, 0, SPRITE_DURATION, 
        3.0, 3.0, 1, 1.0, team == TEAM_A ? {255, 0, 0, 255} : {0, 0, 255, 255}, 0);
    TE_SendToAll();
    
    // Set up text above the beam
    char text[32];
    Format(text, sizeof(text), "Team %s Spawn %d", team == TEAM_A ? "Red" : "Blue", spawnIndex + 1);
    
    float textPos[3];
    textPos = g_fSpawnPoints[team][spawnIndex];
    textPos[2] += 50.0;
    
    // Create the text effect
    TE_SetupTextMessage(textPos, text, team == TEAM_A ? {255, 0, 0, 255} : {0, 0, 255, 255});
    TE_SendToAll();
}

public Action Timer_ShowNextSpawn(Handle timer, any data)
{
    int team = data / 1000;
    int spawn = data % 1000;
    ShowNextSpawn(team, spawn);  // Now just passing team and spawn
    return Plugin_Stop;
}

void ShowNextWarmupSpawn(int currentSpawn = 0) {
    if (currentSpawn < g_iWarmupSpawnCount) {
        float vStartPos[3], vEndPos[3];
        vStartPos = g_fWarmupSpawns[currentSpawn];
        vEndPos = g_fWarmupSpawns[currentSpawn];
        vEndPos[2] += SPRITE_HEIGHT;
        
        int color[4] = {255, 255, 0, 255};
        
        TE_SetupBeamPoints(vStartPos, vEndPos, g_iBeamSprite, 0, 0, 0, SPRITE_DURATION, 3.0, 3.0, 1, 1.0, color, 0);
        TE_SendToAll();
        
        char text[32];
        Format(text, sizeof(text), "Warmup Spawn %d", currentSpawn + 1);
        
        float textPos[3];
        textPos = g_fWarmupSpawns[currentSpawn];
        textPos[2] += 50.0;
        
        TE_SetupTextMessage(textPos, text, color);
        TE_SendToAll();
        
        // Schedule next warmup spawn point
        CreateTimer(1.0, Timer_ShowNextWarmupSpawn, currentSpawn + 1);
    }
}

public Action Timer_ShowNextWarmupSpawn(Handle timer, any currentSpawn) {
    ShowNextWarmupSpawn(currentSpawn);
    return Plugin_Stop;
}

public Action Command_ShowSpawns(int client, int args)
{
    if (!client) return Plugin_Handled;
    g_bShowAllSpawnsPersistent = false;
    if (g_hShowSpawnsTimer != null)
    {
        KillTimer(g_hShowSpawnsTimer);
        g_hShowSpawnsTimer = null;
    }
    g_bShowWarmupSpawnsPersistent = false;
    if (g_hShowWarmupSpawnsTimer != null)
    {
        KillTimer(g_hShowWarmupSpawnsTimer);
        g_hShowWarmupSpawnsTimer = null;
    }
    g_bShowFFASpawnsPersistent = false;
    if (g_hShowFFASpawnsTimer != null)
    {
        KillTimer(g_hShowFFASpawnsTimer);
        g_hShowFFASpawnsTimer = null;
    }

    g_bShowTDMSpawnsPersistent = true;
    if (g_hShowTDMSpawnsTimer != null)
    {
        KillTimer(g_hShowTDMSpawnsTimer);
        g_hShowTDMSpawnsTimer = null;
    }
    g_hShowTDMSpawnsTimer = CreateTimer(SPAWN_SHOW_REFRESH, Timer_ShowTDMSpawns, _, TIMER_REPEAT);
    PrintToChat(client, "\x04[TDM] \x01Showing team spawn points persistently.");
    return Plugin_Handled;
}

public Action Command_ShowAllSpawnPoints(int client, int args)
{
    if (!client) return Plugin_Handled;
    g_bShowAllSpawnsPersistent = true;
    if (g_hShowSpawnsTimer != null)
    {
        KillTimer(g_hShowSpawnsTimer);
        g_hShowSpawnsTimer = null;
    }
    g_hShowSpawnsTimer = CreateTimer(SPAWN_SHOW_REFRESH, Timer_ShowAllSpawns, _, TIMER_REPEAT);
    PrintToChatAll("\x04[PvP] \x01Showing all spawn points until a mode starts.");
    return Plugin_Handled;
}

void DrawAllSpawnBeams()
{
    for (int i = 0; i < g_iSpawnCount[TEAM_A]; i++)
    {
        float vStartPos[3], vEndPos[3];
        vStartPos = g_fSpawnPoints[TEAM_A][i];
        vEndPos = g_fSpawnPoints[TEAM_A][i];
        vEndPos[2] += SPRITE_HEIGHT;
        TE_SetupBeamPoints(vStartPos, vEndPos, g_iBeamSprite, 0, 0, 0, SPAWN_SHOW_REFRESH,
            3.0, 3.0, 1, 1.0, {255, 0, 0, 255}, 0);
        TE_SendToAll();
    }

    for (int i = 0; i < g_iSpawnCount[TEAM_B]; i++)
    {
        float vStartPos[3], vEndPos[3];
        vStartPos = g_fSpawnPoints[TEAM_B][i];
        vEndPos = g_fSpawnPoints[TEAM_B][i];
        vEndPos[2] += SPRITE_HEIGHT;
        TE_SetupBeamPoints(vStartPos, vEndPos, g_iBeamSprite, 0, 0, 0, SPAWN_SHOW_REFRESH,
            3.0, 3.0, 1, 1.0, {0, 0, 255, 255}, 0);
        TE_SendToAll();
    }

    for (int i = 0; i < g_iWarmupSpawnCount; i++)
    {
        float vStartPos[3], vEndPos[3];
        vStartPos = g_fWarmupSpawns[i];
        vEndPos = g_fWarmupSpawns[i];
        vEndPos[2] += SPRITE_HEIGHT;
        TE_SetupBeamPoints(vStartPos, vEndPos, g_iBeamSprite, 0, 0, 0, SPAWN_SHOW_REFRESH,
            3.0, 3.0, 1, 1.0, {0, 255, 0, 255}, 0);
        TE_SendToAll();
    }

    for (int i = 0; i < g_iFFASpawnCount; i++)
    {
        float vStartPos[3], vEndPos[3];
        vStartPos = g_fFFASpawnPoints[i];
        vEndPos = g_fFFASpawnPoints[i];
        vEndPos[2] += SPRITE_HEIGHT;
        TE_SetupBeamPoints(vStartPos, vEndPos, g_iBeamSprite, 0, 0, 0, SPAWN_SHOW_REFRESH,
            3.0, 3.0, 1, 1.0, {255, 255, 0, 255}, 0);
        TE_SendToAll();
    }
}

void DrawTDMSpawnBeams()
{
    for (int i = 0; i < g_iSpawnCount[TEAM_A]; i++)
    {
        float vStartPos[3], vEndPos[3];
        vStartPos = g_fSpawnPoints[TEAM_A][i];
        vEndPos = g_fSpawnPoints[TEAM_A][i];
        vEndPos[2] += SPRITE_HEIGHT;
        TE_SetupBeamPoints(vStartPos, vEndPos, g_iBeamSprite, 0, 0, 0, SPAWN_SHOW_REFRESH,
            3.0, 3.0, 1, 1.0, {255, 0, 0, 255}, 0);
        TE_SendToAll();
    }
    for (int i = 0; i < g_iSpawnCount[TEAM_B]; i++)
    {
        float vStartPos[3], vEndPos[3];
        vStartPos = g_fSpawnPoints[TEAM_B][i];
        vEndPos = g_fSpawnPoints[TEAM_B][i];
        vEndPos[2] += SPRITE_HEIGHT;
        TE_SetupBeamPoints(vStartPos, vEndPos, g_iBeamSprite, 0, 0, 0, SPAWN_SHOW_REFRESH,
            3.0, 3.0, 1, 1.0, {0, 0, 255, 255}, 0);
        TE_SendToAll();
    }
}

void DrawWarmupSpawnBeams()
{
    for (int i = 0; i < g_iWarmupSpawnCount; i++)
    {
        float vStartPos[3], vEndPos[3];
        vStartPos = g_fWarmupSpawns[i];
        vEndPos = g_fWarmupSpawns[i];
        vEndPos[2] += SPRITE_HEIGHT;
        TE_SetupBeamPoints(vStartPos, vEndPos, g_iBeamSprite, 0, 0, 0, SPAWN_SHOW_REFRESH,
            3.0, 3.0, 1, 1.0, {0, 255, 0, 255}, 0);
        TE_SendToAll();
    }
}

void DrawFFASpawnBeams()
{
    for (int i = 0; i < g_iFFASpawnCount; i++)
    {
        float vStartPos[3], vEndPos[3];
        vStartPos = g_fFFASpawnPoints[i];
        vEndPos = g_fFFASpawnPoints[i];
        vEndPos[2] += SPRITE_HEIGHT;
        TE_SetupBeamPoints(vStartPos, vEndPos, g_iBeamSprite, 0, 0, 0, SPAWN_SHOW_REFRESH,
            3.0, 3.0, 1, 1.0, {255, 255, 0, 255}, 0);
        TE_SendToAll();
    }
}

public Action Timer_ShowTDMSpawns(Handle timer)
{
    if (g_bPvPActive || g_bFFAActive || g_bAWPActive || g_bOneShotMode || g_bGunGameActive || g_bWarmupActive)
    {
        g_bShowTDMSpawnsPersistent = false;
        if (g_hShowTDMSpawnsTimer != null)
        {
            KillTimer(g_hShowTDMSpawnsTimer);
            g_hShowTDMSpawnsTimer = null;
        }
        return Plugin_Stop;
    }
    DrawTDMSpawnBeams();
    return Plugin_Continue;
}

public Action Timer_ShowWarmupSpawns(Handle timer)
{
    if (g_bPvPActive || g_bFFAActive || g_bAWPActive || g_bOneShotMode || g_bGunGameActive || g_bWarmupActive)
    {
        g_bShowWarmupSpawnsPersistent = false;
        if (g_hShowWarmupSpawnsTimer != null)
        {
            KillTimer(g_hShowWarmupSpawnsTimer);
            g_hShowWarmupSpawnsTimer = null;
        }
        return Plugin_Stop;
    }
    DrawWarmupSpawnBeams();
    return Plugin_Continue;
}

public Action Timer_ShowFFASpawns(Handle timer)
{
    if (g_bPvPActive || g_bFFAActive || g_bAWPActive || g_bOneShotMode || g_bGunGameActive || g_bWarmupActive)
    {
        g_bShowFFASpawnsPersistent = false;
        if (g_hShowFFASpawnsTimer != null)
        {
            KillTimer(g_hShowFFASpawnsTimer);
            g_hShowFFASpawnsTimer = null;
        }
        return Plugin_Stop;
    }
    DrawFFASpawnBeams();
    return Plugin_Continue;
}

public Action Timer_ShowAllSpawns(Handle timer)
{
    if (g_bPvPActive || g_bFFAActive || g_bAWPActive || g_bOneShotMode || g_bGunGameActive || g_bWarmupActive)
    {
        g_bShowAllSpawnsPersistent = false;
        if (g_hShowSpawnsTimer != null)
        {
            KillTimer(g_hShowSpawnsTimer);
            g_hShowSpawnsTimer = null;
        }
        return Plugin_Stop;
    }
    DrawAllSpawnBeams();
    return Plugin_Continue;
}

public Action Command_SaveSpawns(int client, int args)
{
    char path[PLATFORM_MAX_PATH];
    char mapName[64];
    GetCurrentMap(mapName, sizeof(mapName));
    
    char fileName[128];
    Format(fileName, sizeof(fileName), SPAWN_FILE, mapName);
    BuildPath(Path_SM, path, sizeof(path), fileName);
    
    KeyValues kv = new KeyValues("SpawnPoints");
    
    for (int team = 0; team < MAX_TEAMS; team++)
    {
        char section[8];
        Format(section, sizeof(section), "Team%d", team);
        kv.JumpToKey(section, true);
        
        for (int i = 0; i < g_iSpawnCount[team]; i++)
        {
            char spawnName[8];
            Format(spawnName, sizeof(spawnName), "Spawn%d", i);
            kv.JumpToKey(spawnName, true);
            kv.SetVector("position", g_fSpawnPoints[team][i]);
            kv.SetVector("angles", g_fSpawnAngles[team][i]);
            kv.GoBack();
        }
        kv.GoBack();
    }
    
    kv.ExportToFile(path);
    delete kv;
    
    PrintToChat(client, "\x04[PvP] \x01Spawn points saved for map \x04%s\x01!", mapName);
    return Plugin_Handled;
}

public Action Command_AddWarmupSpawn(int client, int args)
{
    if (!client) return Plugin_Handled;
    
    if (g_iWarmupSpawnCount >= MAX_WARMUP_SPAWNS)
    {
        ReplyToCommand(client, "[PvP] Maximum warmup spawn points reached!");
        return Plugin_Handled;
    }
    
    float pos[3], ang[3];
    GetClientAbsOrigin(client, pos);
    GetClientAbsAngles(client, ang);
    
    g_fWarmupSpawns[g_iWarmupSpawnCount] = pos;
    g_fWarmupAngles[g_iWarmupSpawnCount] = ang;
    g_iWarmupSpawnCount++;
    
    // Visual confirmation
    float vEndPos[3];
    vEndPos = pos;
    vEndPos[2] += SPRITE_HEIGHT;
    
    int color[4] = {0, 255, 0, 255}; // Green for warmup
    
    TE_SetupBeamPoints(pos, vEndPos, g_iBeamSprite, 0, 0, 0, SPAWN_SHOW_REFRESH, 
        3.0, 3.0, 1, 1.0, color, 0);
    TE_SendToAll();
    if (g_bShowFFASpawnsPersistent)
        DrawFFASpawnBeams();
    else if (g_bShowAllSpawnsPersistent)
        DrawAllSpawnBeams();
    
    PrintToChatAll("\x04[PvP] \x01New warmup spawn point added!");
    return Plugin_Handled;
}

public Action Command_ShowWarmupSpawns(int client, int args)
{
    if (!client) return Plugin_Handled;
    g_bShowAllSpawnsPersistent = false;
    if (g_hShowSpawnsTimer != null)
    {
        KillTimer(g_hShowSpawnsTimer);
        g_hShowSpawnsTimer = null;
    }
    g_bShowTDMSpawnsPersistent = false;
    if (g_hShowTDMSpawnsTimer != null)
    {
        KillTimer(g_hShowTDMSpawnsTimer);
        g_hShowTDMSpawnsTimer = null;
    }
    g_bShowFFASpawnsPersistent = false;
    if (g_hShowFFASpawnsTimer != null)
    {
        KillTimer(g_hShowFFASpawnsTimer);
        g_hShowFFASpawnsTimer = null;
    }

    g_bShowWarmupSpawnsPersistent = true;
    if (g_hShowWarmupSpawnsTimer != null)
    {
        KillTimer(g_hShowWarmupSpawnsTimer);
        g_hShowWarmupSpawnsTimer = null;
    }
    g_hShowWarmupSpawnsTimer = CreateTimer(SPAWN_SHOW_REFRESH, Timer_ShowWarmupSpawns, _, TIMER_REPEAT);
    PrintToChat(client, "\x04[PvP] \x01Showing warmup spawn points persistently.");
    return Plugin_Handled;
}

public Action Command_SaveWarmupSpawns(int client, int args)
{
    char path[PLATFORM_MAX_PATH];
    char mapName[64];
    GetCurrentMap(mapName, sizeof(mapName));
    
    char fileName[128];
    Format(fileName, sizeof(fileName), WARMUP_SPAWN_FILE, mapName);
    BuildPath(Path_SM, path, sizeof(path), fileName);
    
    KeyValues kv = new KeyValues("WarmupSpawns");
    
    for (int i = 0; i < g_iWarmupSpawnCount; i++)
    {
        char spawnName[8];
        Format(spawnName, sizeof(spawnName), "Spawn%d", i);
        kv.JumpToKey(spawnName, true);
        kv.SetVector("position", g_fWarmupSpawns[i]);
        kv.SetVector("angles", g_fWarmupAngles[i]);
        kv.GoBack();
    }
    
    bool success = kv.ExportToFile(path);
    delete kv;
    
    if (success)
    {
        PrintToChat(client, "\x04[PvP] \x01Warmup spawn points saved for map \x04%s\x01!", mapName);
        PrintToServer("[PvP] Saved %d warmup spawns to %s", g_iWarmupSpawnCount, path);
    }
    else
    {
        PrintToChat(client, "\x04[PvP] \x01 Error saving warmup spawn points!");
        PrintToServer("[PvP] Failed to save warmup spawns to %s", path);
    }
    
    return Plugin_Handled;
}

public void Event_PlayerDeath_Handler(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (!IsValidClient(victim))
        return;

    if (g_bPvPActive || g_bOneShotMode)
    {
        if (IsValidClient(attacker) && attacker != victim)
        {
            if (ShouldCountKill(victim, attacker))
            {
                g_iPlayerKills[attacker]++;
                g_iPlayerDeaths[victim]++;

                if (g_iPlayerTeam[attacker] == TEAM_A)
                {
                    g_iTeamScores[TEAM_A]++;
                    PrintToChatAll("\x04[%s] \x01%N \x01killed \x04%N\x01 with \x04%s",
                        g_bOneShotMode ? "OneShot" : "TDM",
                        attacker, victim, g_sLastWeapon[victim]);
                    PrintToChatAll("\x01(Red: \x04%d\x01 - Blue: \x04%d\x01)",
                        g_iTeamScores[TEAM_A], g_iTeamScores[TEAM_B]);
                }
                else if (g_iPlayerTeam[attacker] == TEAM_B)
                {
                    g_iTeamScores[TEAM_B]++;
                    PrintToChatAll("\x04[%s] \x01%N \x01killed \x04%N\x01 with \x04%s",
                        g_bOneShotMode ? "OneShot" : "TDM",
                        attacker, victim, g_sLastWeapon[victim]);
                    PrintToChatAll("\x01(Red: \x04%d\x01 - Blue: \x04%d\x01)",
                        g_iTeamScores[TEAM_A], g_iTeamScores[TEAM_B]);
                }

                if (IsValidClient(victim))
                {
                    SetEntPropEnt(victim, Prop_Send, "m_hObserverTarget", attacker);
                    SetEntProp(victim, Prop_Send, "m_iObserverMode", 4);
                }

                if (g_iTeamScores[TEAM_A] >= g_cvScoreLimit.IntValue || 
                    g_iTeamScores[TEAM_B] >= g_cvScoreLimit.IntValue)
                {
                    CreateTimer(3.0, Timer_EndMatch);
                }
            }
        }
    }
    else if (g_bFFAActive)
    {
        if (IsValidClient(attacker) && attacker != victim)
        {
            if (ShouldCountKill(victim, attacker))
            {
                g_iPlayerKills[attacker]++;
                g_iFFAKills[attacker]++;
                g_iPlayerDeaths[victim]++;

                PrintToChatAll("\x04[FFA] \x01%N \x01killed \x04%N\x01 with \x04%s",
                    attacker, victim, g_sLastWeapon[victim]);

                // Reset last attack time for victim
                g_fLastDamageTime[victim] = 0.0;

                if (g_iFFAKills[attacker] >= g_cvFFAScoreLimit.IntValue)
                {
                    CreateTimer(3.0, Timer_EndFFA);
                }
            }
        }
    }
    else if (g_bAWPActive)
    {
        if (IsValidClient(attacker) && attacker != victim)
        {
            if (ShouldCountKill(victim, attacker))
            {
                g_iPlayerKills[attacker]++;
                g_iAWPKills[attacker]++;
                g_iPlayerDeaths[victim]++;

                PrintToChatAll("\x04[AWP] \x01%N \x01killed \x04%N\x01 with \x04%s",
                    attacker, victim, g_sLastWeapon[victim]);

                if (g_iAWPKills[attacker] >= g_cvAWPScoreLimit.IntValue)
                {
                    CreateTimer(3.0, Timer_EndAWP);
                }
            }
        }
    }

    CreateTimer(3.0, Timer_RespawnPlayer, victim);
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    // Debug mode status
    PrintToServer("[Debug] Event_PlayerHurt called - Mode: %s", 
        g_bAWPActive ? "AWP" : (g_bFFAActive ? "FFA" : "Other"));

    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int damage = event.GetInt("dmg_health");
    int hitgroup = event.GetInt("hitgroup");
    bool headshot = (hitgroup == 1); // hitgroup 1 is the head
    
    if (!IsValidClient(victim) || !IsValidClient(attacker) || victim == attacker)
    {
        PrintToServer("[Debug] Invalid clients or self damage - V: %d, A: %d", victim, attacker);
        return Plugin_Continue;
    }

    if (ShouldShowHitMarker(attacker, victim, damage))
    {
        ShowHitMarker(attacker, victim, headshot);
    }
        
    char weapon[32];
    event.GetString("weapon", weapon, sizeof(weapon));
    
    // Format weapon name
    char formattedWeapon[32];
    GetFormattedWeaponName(weapon, formattedWeapon, sizeof(formattedWeapon));
    
    // Store the formatted weapon name for death event
    strcopy(g_sLastHurtWeapon[victim], sizeof(g_sLastHurtWeapon[]), formattedWeapon);
    
    // Store last attacker for death event
    g_iLastAttacker[victim] = attacker;
    g_fLastPvPAttackTime[victim] = GetGameTime();
    g_bLastHitWasHeadshot[victim] = headshot;
    
    // Apply headshot damage multiplier if it's a headshot
    if (headshot && !g_bAWPActive) // Skip in AWP mode since it's already one-shot
    {
        float multiplier = g_hHeadshotDamageMultiplier.FloatValue;
        int originalHealth = GetClientHealth(victim) + damage; // Original health before this hit
        int newDamage = RoundToNearest(float(damage) * multiplier); // Calculate new damage
        int newHealth = originalHealth - newDamage; // Calculate new health
        
        if (newHealth <= 0)
        {
            // If the increased damage would kill the player, force a suicide
            ForcePlayerSuicide(victim);
            // Remove headshot kill notification
        }
        else
        {
            // Otherwise apply the additional damage
            SetEntityHealth(victim, newHealth);
            // Remove headshot feedback message
        }
    }
    
    if (g_bAWPActive)
    {
        PrintToServer("[AWP Debug] Damage dealt: %d", damage);
        PrintToServer("[AWP Debug] Hurt Event - Attacker: %d (%N), Victim: %d (%N), Weapon: %s", 
            attacker, attacker, victim, victim, formattedWeapon);
            
        // If it's an AWP hit, make it a one-shot kill
        if (StrEqual(weapon, "sniper_awp"))
        {
            ForcePlayerSuicide(victim);
        }
    }
    else if (g_bFFAActive)
    {
        PrintToServer("[FFA Debug] Damage dealt: %d", damage);
        PrintToServer("[FFA Debug] Hurt Event - Attacker: %d (%N), Victim: %d (%N), Weapon: %s",
            attacker, attacker, victim, victim, formattedWeapon);
    }
    else if (g_bPvPActive)
    {
        PrintToServer("[TDM Debug] Damage dealt: %d", damage);
        PrintToServer("[TDM Debug] Hurt Event - Attacker: %d (%N), Victim: %d (%N), Weapon: %s",
            attacker, attacker, victim, victim, formattedWeapon);
    }
    
    PrintToServer("[Debug] Stored attacker %d (%N) for victim %d (%N) with weapon %s", 
        attacker, attacker, victim, victim, formattedWeapon);
    
    // Update last damage time for health regeneration
    g_fLastDamageTime[victim] = GetGameTime();
    
    // Clear any existing regen timer
    if (g_hRegenTimer[victim] != null)
    {
        KillTimer(g_hRegenTimer[victim]);
        g_hRegenTimer[victim] = null;
    }

    // Start new regeneration timer
    g_hRegenTimer[victim] = CreateTimer(REGEN_DELAY, Timer_RegenerateHealth, victim);
    
    return Plugin_Continue;
}

public Action Timer_EndMatch(Handle timer, any winningTeam)
{
    // Set match ended state
    g_bMatchEnded = true;
    
    // Announce winner with final score
    PrintToChatAll("\x04[TDM] \x01Match ended! %s team wins! Score: %d - %d", 
        winningTeam == TEAM_A ? "Red" : "Blue",
        g_iTeamScores[TEAM_A], 
        g_iTeamScores[TEAM_B]);
    
    // Re-enable infected spawning
    g_hDirectorNoSpecials.IntValue = 0;
    g_hCommonLimit.IntValue = 30;
    g_hSpecialSpawnInterval.IntValue = 45;
    g_hDirectorNoMobs.IntValue = 0;
    g_hDirectorNoBosses.IntValue = 0;
    
    RemoveAllTeamGlows();
    SetControlledGlowRendering(false);
    
    // Handle all players
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
        {
            // Make everyone invulnerable
            SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
            
            // Respawn if dead
            if (!IsPlayerAlive(i))
            {
                L4D_RespawnPlayer(i);
                
                // Ensure they have proper model and can move
                SetEntProp(i, Prop_Send, "m_survivorCharacter", GetRandomInt(0, 7));
                SetEntityModel(i, "models/survivors/survivor_gambler.mdl");
                SetEntityMoveType(i, MOVETYPE_WALK);
                
                // Ensure viewmodel is visible
                SetEntProp(i, Prop_Send, "m_iHideHUD", 0);
                
                // Give them a basic loadout
                StripWeapons(i);
                GivePlayerItem(i, "weapon_pistol");
            }
            
            // Reset player color to normal
            SetEntityRenderColor(i, 255, 255, 255, 255);
            
            // Reset player stats
            g_iPlayerKills[i] = 0;
            g_iPlayerDeaths[i] = 0;
            g_iFFAKills[i] = 0;
            g_iPlayerTeam[i] = -1;
            g_bSpawnProtection[i] = false;
            
            // Clear any respawn timers
            if (g_hRespawnTimers[i] != null)
            {
                KillTimer(g_hRespawnTimers[i]);
                g_hRespawnTimers[i] = null;
            }
        }
    }
    
    // Reset game state
    g_bPvPActive = false;
    g_bWarmupActive = false;
    g_bMatchEnded = true;
    
    // Reset scores
    g_iTeamScores[TEAM_A] = 0;
    g_iTeamScores[TEAM_B] = 0;
    
    // Kill round timer if it exists
    if (g_hRoundTimer != null)
    {
        KillTimer(g_hRoundTimer);
        g_hRoundTimer = null;
    }
    
    // Kill infected check timer if it exists
    if (g_hInfectedCheckTimer != null)
    {
        KillTimer(g_hInfectedCheckTimer);
        g_hInfectedCheckTimer = null;
    }
    
    // Remove blocker if it exists
    if (g_iSafeRoomBlocker != -1 && IsValidEntity(g_iSafeRoomBlocker))
    {
        RemoveEntity(g_iSafeRoomBlocker);
        g_iSafeRoomBlocker = -1;
    }
    
    return Plugin_Stop;
}

public void Event_PlayerDeathPre(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidClient(victim))
        return;

    // Scoring is handled in Event_PlayerDeath only. Keeping this hook passive avoids double counts
    // and lets the main handler credit kills after forced suicides/incaps.
    g_bKnifeLevelSetup[victim] = false;
}

bool ShouldShowHitMarker(int attacker, int victim, int damage)
{
    if (damage < 0)
        return false;

    if (!IsValidClient(attacker) || !IsValidClient(victim) || attacker == victim)
        return false;

    if (g_bWarmupActive || g_bMatchEnded)
        return false;

    if (!g_bPvPActive && !g_bFFAActive && !g_bAWPActive && !g_bGunGameActive && !g_bOneShotMode)
        return false;

    if (IsFakeClient(attacker) || IsFakeClient(victim))
        return false;

    if ((g_bPvPActive || g_bOneShotMode) &&
        g_iPlayerTeam[attacker] != -1 &&
        g_iPlayerTeam[victim] != -1 &&
        g_iPlayerTeam[attacker] == g_iPlayerTeam[victim])
    {
        return false;
    }

    return true;
}

void ShowHitMarker(int attacker, int victim, bool headshot, bool force = false)
{
    if (g_iBeamSprite <= 0 || !IsValidClient(attacker) || !IsValidClient(victim) || !IsPlayerAlive(attacker))
        return;

    float now = GetGameTime();
    if (!force && now < g_fNextHitMarkerTime[attacker])
        return;

    g_fNextHitMarkerTime[attacker] = now + HITMARKER_COOLDOWN;
    DrawHitMarkerFrame(attacker, victim, headshot);
}

void DrawHitMarkerFrame(int attacker, int victim, bool headshot)
{
    if (g_iBeamSprite <= 0 || !IsValidClient(attacker) || !IsValidClient(victim) || !IsPlayerAlive(attacker))
        return;

    float angles[3], fwd[3], right[3], up[3];
    float eye[3], center[3];
    GetClientEyePosition(attacker, eye);
    GetClientEyeAngles(attacker, angles);
    GetAngleVectors(angles, fwd, right, up);

    for (int i = 0; i < 3; i++)
    {
        center[i] = eye[i] + (fwd[i] * HITMARKER_SCREEN_DISTANCE);
    }

    float sizeScale = GetHitMarkerDistanceScale(attacker, victim) * GetHitMarkerFovScale(attacker);
    float inner = (headshot ? HITMARKER_HEADSHOT_INNER_GAP : HITMARKER_INNER_GAP) * sizeScale;
    float outer = (headshot ? HITMARKER_HEADSHOT_OUTER_SIZE : HITMARKER_OUTER_SIZE) * sizeScale;
    float width = HITMARKER_WIDTH;

    float segmentStart[4][3], segmentEnd[4][3];
    int signs[4][2] =
    {
        {-1,  1},
        { 1,  1},
        {-1, -1},
        { 1, -1}
    };

    for (int segment = 0; segment < 4; segment++)
    {
        float side = float(signs[segment][0]);
        float vertical = float(signs[segment][1]);

        for (int i = 0; i < 3; i++)
        {
            segmentStart[segment][i] = center[i] + (right[i] * side * inner) + (up[i] * vertical * inner);
            segmentEnd[segment][i] = center[i] + (right[i] * side * outer) + (up[i] * vertical * outer);
        }
    }

    int color[4];
    if (headshot)
    {
        color[0] = 255;
        color[1] = 55;
        color[2] = 35;
        color[3] = 255;
    }
    else
    {
        color[0] = 165;
        color[1] = 245;
        color[2] = 255;
        color[3] = 255;
    }

    for (int segment = 0; segment < 4; segment++)
    {
        TE_SetupBeamPoints(segmentStart[segment], segmentEnd[segment], g_iBeamSprite, 0, 0, 0, HITMARKER_LIFE, width, width, 0, 0.0, color, 0);
        TE_SendToClient(attacker);
    }
}

float GetHitMarkerDistanceScale(int attacker, int victim)
{
    float attackerEye[3], victimEye[3];
    GetClientEyePosition(attacker, attackerEye);
    GetClientEyePosition(victim, victimEye);

    float distance = GetVectorDistance(attackerEye, victimEye);
    if (distance <= HITMARKER_CLOSE_DISTANCE)
        return HITMARKER_MAX_SCALE;

    if (distance >= HITMARKER_FAR_DISTANCE)
        return HITMARKER_MIN_SCALE;

    float progress = (distance - HITMARKER_CLOSE_DISTANCE) / (HITMARKER_FAR_DISTANCE - HITMARKER_CLOSE_DISTANCE);
    return HITMARKER_MAX_SCALE - ((HITMARKER_MAX_SCALE - HITMARKER_MIN_SCALE) * progress);
}

float GetHitMarkerFovScale(int attacker)
{
    int fov = GetEntProp(attacker, Prop_Send, "m_iFOV");
    if (fov <= 0)
        return 1.0;

    float scale = float(fov) / HITMARKER_BASE_FOV;
    if (scale < HITMARKER_MIN_FOV_SCALE)
        return HITMARKER_MIN_FOV_SCALE;

    if (scale > 1.0)
        return 1.0;

    return scale;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    // Reset scores and states on round start
    g_bPvPActive = false;
    g_bOneShotMode = false;
    g_bFFAActive = false;
    g_bAWPActive = false;
    g_bGunGameActive = false;
    g_bWarmupActive = false;
    g_bMatchEnded = false;
    g_iTeamScores[TEAM_A] = 0;
    g_iTeamScores[TEAM_B] = 0;
    
    // Clear all timers
    if (g_hRoundTimer != null)
    {
        KillTimer(g_hRoundTimer);
        g_hRoundTimer = null;
    }
    
    if (g_hInfectedCheckTimer != null)
    {
        KillTimer(g_hInfectedCheckTimer);
        g_hInfectedCheckTimer = null;
    }
    if (g_hTeamGlowRefreshTimer != null)
    {
        KillTimer(g_hTeamGlowRefreshTimer);
        g_hTeamGlowRefreshTimer = null;
    }
    RestoreClimbPluginGlow();
    SetControlledGlowRendering(false);
    
    for (int i = 1; i <= MaxClients; i++)
    {
        g_iPlayerTeam[i] = -1;
        g_bSpawnProtection[i] = false;
        RemoveKillcamGlow(i);
        RemoveTeamGlow(i);
        g_bInKillcam[i] = false;
        g_iKillcamTarget[i] = -1;
        if (g_hRespawnTimers[i] != null)
        {
            KillTimer(g_hRespawnTimers[i]);
            g_hRespawnTimers[i] = null;
        }
        
        if (IsValidClient(i))
        {
            SetEntityRenderColor(i, 255, 255, 255, 255);
            SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
        }
    }
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (g_bPvPActive)
    {
        EndPvPMode();
    }
}

public Action Timer_RoundEnd(Handle timer)
{
    g_hRoundTimer = null;
    EndPvPMode();
    PrintToChatAll("\x04[PvP] \x01Round time limit reached!");
    return Plugin_Stop;
}

public Action Timer_RespawnPlayer(Handle timer, any data)
{
    int client = 0;
    
    // Check if the data is a DataPack or a direct client index
    if (data > MaxClients)
    {
        // It's a DataPack
        DataPack dp = view_as<DataPack>(data);
        dp.Reset();
        int userId = dp.ReadCell();
        client = GetClientOfUserId(userId);
        
        // Skip the self-kill flag - we don't need to use it since
        // we're handling teleports for all game modes properly now
        if (dp.IsReadable(1))
        {
            dp.ReadCell(); // Just read and discard
        }
    }
    else
    {
        // It's a direct client index
        client = data;
    }
    
    if (!IsValidClient(client))
        return Plugin_Stop;
        
    // Skip if player is in killcam - let the killcam timer handle respawn
    if (g_bInKillcam[client])
        return Plugin_Stop;
        
    L4D_RespawnPlayer(client);
    
    // Randomize character and set model
    int character = GetRandomInt(0, 7);
    SetEntProp(client, Prop_Send, "m_survivorCharacter", character);
    
    // Set appropriate model based on character
    switch(character)
    {
        case 0: SetEntityModel(client, "models/survivors/survivor_gambler.mdl");    // Nick
        case 1: SetEntityModel(client, "models/survivors/survivor_producer.mdl");   // Rochelle
        case 2: SetEntityModel(client, "models/survivors/survivor_coach.mdl");      // Coach
        case 3: SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");   // Ellis
        case 4: SetEntityModel(client, "models/survivors/survivor_namvet.mdl");     // Bill
        case 5: SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");  // Zoey
        case 6: SetEntityModel(client, "models/survivors/survivor_biker.mdl");      // Francis
        case 7: SetEntityModel(client, "models/survivors/survivor_manager.mdl");    // Louis
        default: SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
    }
    
    SetEntityMoveType(client, MOVETYPE_WALK);
    SetEntityRenderMode(client, RENDER_NORMAL);
    
    // Ensure viewmodel is visible
    SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
    
    // Handle mode-specific respawn logic
    if (g_bGunGameActive)
    {
        TeleportToFFASpawn(client); // Make sure we teleport in Gun Game mode too
        CreateTimer(0.1, Timer_GiveNextGunGameWeapon, client);
    }
    else if (g_bFFAActive)
    {
        TeleportToFFASpawn(client);
        GiveRandomLoadout(client);
    }
    else if (g_bPvPActive)
    {
        // Get player's team from our plugin-specific variable, not from GetClientTeam
        int playerTeam = g_iPlayerTeam[client];
        
        // If team ID is invalid, log it and fix it
        if (playerTeam < 0 || playerTeam >= MAX_TEAMS)
        {
            LogError("[PvP] Invalid team ID %d for player %N - defaulting to team TEAM_A", playerTeam, client);
            playerTeam = TEAM_A;
            g_iPlayerTeam[client] = TEAM_A;
        }
        
        // Apply team-based color
        if (playerTeam == TEAM_A)
        {
            SetEntityRenderColor(client, 255, 0, 0, 255);  // Red
        }
        else
        {
            SetEntityRenderColor(client, 0, 0, 255, 255);  // Blue
        }
        
        // Teleport to the correct team spawn
        TeleportToSpawn(client, playerTeam);
        GiveRandomLoadout(client);
    }
    else if (g_bAWPActive || g_bOneShotMode) // Handle other modes too
    {
        TeleportToFFASpawn(client);
        GiveRandomLoadout(client);
    }
    
    // Add One Shot mode check
    if (g_bOneShotMode)
    {
        SetupOneShotPlayer(client);
    }
    
    // ALWAYS announce loadout for ALL players (including host)
    // Use a small delay to ensure weapons are fully equipped
    CreateTimer(0.7, Timer_ForceAnnounceLoadout, client);
    
    // Enable spawn protection
    g_bSpawnProtection[client] = true;
    SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
    SetEntityRenderColor(client, 0, 255, 0, 200);  // Green color with slight transparency
    CreateTimer(SPAWN_PROTECTION_TIME, Timer_RemoveSpawnProtection, client);
    
    return Plugin_Stop;
}

void SchedulePostDeathRespawnVerify(int client, float delay, int attempt)
{
    if (!IsValidClient(client))
        return;

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteCell(attempt);
    CreateTimer(delay, Timer_VerifyPostDeathRespawn, pack, TIMER_DATA_HNDL_CLOSE | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_VerifyPostDeathRespawn(Handle timer, any data)
{
    DataPack pack = view_as<DataPack>(data);
    pack.Reset();
    int client = GetClientOfUserId(pack.ReadCell());
    int attempt = pack.ReadCell();

    if (!IsValidClient(client) || !IsPvPRespawnModeActive())
        return Plugin_Stop;

    if (!g_bInKillcam[client] && IsPlayerAlive(client))
        return Plugin_Stop;

    if (ForcePostDeathRespawn(client))
        return Plugin_Stop;

    if (attempt < RESPAWN_VERIFY_MAX_ATTEMPTS)
    {
        SchedulePostDeathRespawnVerify(client, RESPAWN_VERIFY_RETRY_DELAY, attempt + 1);
    }
    else
    {
        PrintToServer("[PvP Respawn] Failed to rescue %N from death screen after %d attempts.", client, attempt + 1);
    }

    return Plugin_Stop;
}

bool IsPvPRespawnModeActive()
{
    return !g_bMatchEnded && (g_bPvPActive || g_bFFAActive || g_bAWPActive || g_bGunGameActive || g_bOneShotMode);
}

bool ForcePostDeathRespawn(int client)
{
    if (!IsValidClient(client) || !IsPvPRespawnModeActive())
        return true;

    if (g_hKillcamTimer[client] != null)
    {
        KillTimer(g_hKillcamTimer[client]);
        g_hKillcamTimer[client] = null;
    }

    if (g_bInKillcam[client])
    {
        g_bInKillcam[client] = false;
        g_iKillcamTarget[client] = -1;
        if (g_iActiveKillcams > 0)
            g_iActiveKillcams--;
    }

    RemoveKillcamGlow(client);

    if (IsPlayerAlive(client))
    {
        RefreshRespawnGlowState();
        return true;
    }

    if (GetClientTeam(client) != TEAM_SURVIVOR)
        ChangeClientTeam(client, TEAM_SURVIVOR);

    L4D_RespawnPlayer_Custom(client);
    L4D_RespawnPlayer(client);

    if (!IsPlayerAlive(client))
        return false;

    SetupPostDeathRespawnedPlayer(client);
    RefreshRespawnGlowState();
    return true;
}

void SetupPostDeathRespawnedPlayer(int client)
{
    int character = GetRandomInt(0, 7);
    SetEntProp(client, Prop_Send, "m_survivorCharacter", character);

    switch (character)
    {
        case 0: SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
        case 1: SetEntityModel(client, "models/survivors/survivor_producer.mdl");
        case 2: SetEntityModel(client, "models/survivors/survivor_coach.mdl");
        case 3: SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
        case 4: SetEntityModel(client, "models/survivors/survivor_namvet.mdl");
        case 5: SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");
        case 6: SetEntityModel(client, "models/survivors/survivor_biker.mdl");
        case 7: SetEntityModel(client, "models/survivors/survivor_manager.mdl");
        default: SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
    }

    SetEntityMoveType(client, MOVETYPE_WALK);
    SetEntityRenderMode(client, RENDER_NORMAL);
    SetEntityRenderColor(client, 255, 255, 255, 255);
    SetEntProp(client, Prop_Send, "m_iHideHUD", 0);

    if (g_bGunGameActive)
    {
        TeleportToFFASpawn(client);
        CreateTimer(0.1, Timer_GiveNextGunGameWeapon, client);
    }
    else if (g_bFFAActive || g_bAWPActive || g_bOneShotMode)
    {
        TeleportToFFASpawn(client);
        GiveRandomLoadout(client);
    }
    else if (g_bPvPActive)
    {
        int team = g_iPlayerTeam[client];
        if (team < 0 || team >= MAX_TEAMS)
        {
            team = GetTeamWithFewerPlayers();
            g_iPlayerTeam[client] = team;
        }

        TeleportToSpawn(client, team);
        GiveRandomLoadout(client);
    }

    CreateTimer(0.7, Timer_ForceAnnounceLoadout, client);

    g_bSpawnProtection[client] = true;
    SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
    SetEntityRenderColor(client, 0, 255, 0, 200);
    CreateTimer(SPAWN_PROTECTION_TIME, Timer_RemoveSpawnProtection, client);
}

void RefreshRespawnGlowState()
{
    if (g_bPvPActive)
    {
        RefreshTeamGlows();
    }
    else
    {
        SetControlledGlowRendering(false);
    }
}

public Action Timer_RemoveEntity(Handle timer, any entity)
{
    if (IsValidEntity(entity))
        RemoveEntity(entity);
    return Plugin_Stop;
}

void EndPvPMode(int winningTeam = -1)
{
    // Kill the infected check timer
    if (g_hInfectedCheckTimer != null)
    {
        KillTimer(g_hInfectedCheckTimer);
        g_hInfectedCheckTimer = null;
    }
    if (g_hTeamGlowRefreshTimer != null)
    {
        KillTimer(g_hTeamGlowRefreshTimer);
        g_hTeamGlowRefreshTimer = null;
    }
    
    // Re-enable infected spawning
    g_hDirectorNoSpecials.IntValue = 0;
    g_hCommonLimit.IntValue = 30;
    g_hSpecialSpawnInterval.IntValue = 45;
    g_hDirectorNoMobs.IntValue = 0;
    g_hDirectorNoBosses.IntValue = 0;
    
    RemoveAllTeamGlows();
    
    g_bPvPActive = false;
    g_bOneShotMode = false;
    g_bWarmupActive = false;
    
    // Clear timers
    if (g_hRoundTimer != null)
    {
        KillTimer(g_hRoundTimer);
        g_hRoundTimer = null;
    }
    
    // Clear respawn timers
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_hRespawnTimers[i] != null)
        {
            KillTimer(g_hRespawnTimers[i]);
            g_hRespawnTimers[i] = null;
        }
        
        if (IsValidClient(i))
        {
            SetEntityRenderColor(i, 255, 255, 255, 255);
            g_iPlayerTeam[i] = -1;
            g_bSpawnProtection[i] = false;
            
            // Reset player state
            SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
            if (IsPlayerAlive(i))
            {
                SetEntityHealth(i, 100);
            }
        }
    }
    
    // Reset scores
    g_iTeamScores[TEAM_A] = 0;
    g_iTeamScores[TEAM_B] = 0;
    
    // Remove blocker
    if (g_iSafeRoomBlocker != -1 && IsValidEntity(g_iSafeRoomBlocker))
    {
        RemoveEntity(g_iSafeRoomBlocker);
        g_iSafeRoomBlocker = -1;
    }

    StopTDMArenaTimer();
    
    // Clean up killcams
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_hKillcamTimer[i] != null)
        {
            KillTimer(g_hKillcamTimer[i]);
            g_hKillcamTimer[i] = null;
        }
        RemoveKillcamGlow(i);
        RemoveTeamGlow(i);
        g_bInKillcam[i] = false;
        g_iKillcamTarget[i] = -1;
    }
    StopGlowRefreshTimerIfIdle();
    
    if (winningTeam != -1)
    {
        PrintToChatAll("\x04[TDM] \x01Match ended! %s team wins! Score: \x04%d\x01 - \x04%d\x01",
            winningTeam == TEAM_A ? "Red" : "Blue",
            g_iTeamScores[TEAM_A],
            g_iTeamScores[TEAM_B]);
    }
}

void StartTDMArenaTimer()
{
    StopTDMArenaTimer();
}

void StopTDMArenaTimer()
{
    if (g_hTDMArenaTimer != null)
    {
        KillTimer(g_hTDMArenaTimer);
        g_hTDMArenaTimer = null;
    }

    g_bTDMArenaActive = false;
    g_fTDMArenaRadius = 0.0;
    for (int i = 1; i <= MaxClients; i++)
    {
        g_fTDMArenaNextDamage[i] = 0.0;
    }
}

public Action Timer_TDMArena(Handle timer)
{
    if (!g_bPvPActive || !g_bTDMArenaActive)
    {
        g_hTDMArenaTimer = null;
        return Plugin_Stop;
    }

    DrawTDMArenaRing();

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i) || !IsPlayerAlive(i) || g_iPlayerTeam[i] == -1)
            continue;

        float pos[3];
        GetClientAbsOrigin(i, pos);
        float distance = GetHorizontalDistance(pos, g_fTDMArenaCenter);

        if (distance > g_fTDMArenaRadius)
        {
            EnforceTDMArenaWall(i, true);
        }
        else if (distance > g_fTDMArenaRadius - TDM_ARENA_WARN_DISTANCE)
        {
            PrintHintText(i, "Combat zone edge");
        }
    }

    return Plugin_Continue;
}

void EnforceTDMArenaWall(int client, bool applyDamage)
{
    if (!g_bPvPActive || !g_bTDMArenaActive || g_fTDMArenaRadius <= 0.0)
        return;

    if (!IsValidClient(client) || !IsPlayerAlive(client) || g_iPlayerTeam[client] == -1)
        return;

    float pos[3];
    GetClientAbsOrigin(client, pos);

    float dx = pos[0] - g_fTDMArenaCenter[0];
    float dy = pos[1] - g_fTDMArenaCenter[1];
    float distance = SquareRoot((dx * dx) + (dy * dy));
    if (distance <= g_fTDMArenaRadius)
        return;

    if (distance < 1.0)
    {
        dx = 1.0;
        dy = 0.0;
        distance = 1.0;
    }

    float safeRadius = g_fTDMArenaRadius - TDM_ARENA_WALL_BUFFER;
    if (safeRadius < 64.0)
        safeRadius = g_fTDMArenaRadius * 0.90;

    float scale = safeRadius / distance;
    float newPos[3];
    newPos[0] = g_fTDMArenaCenter[0] + (dx * scale);
    newPos[1] = g_fTDMArenaCenter[1] + (dy * scale);
    newPos[2] = pos[2];

    float zeroVel[3] = {0.0, 0.0, 0.0};
    TeleportEntity(client, newPos, NULL_VECTOR, zeroVel);

    PrintHintText(client, "Go back to the combat zone!");

    if (applyDamage && GetGameTime() >= g_fTDMArenaNextDamage[client])
    {
        g_fTDMArenaNextDamage[client] = GetGameTime() + TDM_ARENA_DAMAGE_INTERVAL;

        if (!g_bSpawnProtection[client])
        {
            int health = GetClientHealth(client);
            if (health <= TDM_ARENA_DAMAGE)
            {
                ForcePlayerSuicide(client);
            }
            else
            {
                SetEntityHealth(client, health - TDM_ARENA_DAMAGE);
                SetEntProp(client, Prop_Send, "m_iHealth", health - TDM_ARENA_DAMAGE);
            }
        }
    }
}

float GetHorizontalDistance(float a[3], float b[3])
{
    float dx = a[0] - b[0];
    float dy = a[1] - b[1];
    return SquareRoot((dx * dx) + (dy * dy));
}

void DrawTDMArenaRing()
{
    int color[4] = {255, 32, 32, 220};
    float center[3];
    center[0] = g_fTDMArenaCenter[0];
    center[1] = g_fTDMArenaCenter[1];
    center[2] = g_fTDMArenaCenter[2] + TDM_ARENA_VISUAL_HEIGHT;

    TE_SetupBeamRingPoint(center, g_fTDMArenaRadius - 10.0, g_fTDMArenaRadius, g_iBeamSprite, 0, 0, 12, 1.05, 12.0, 0.0, color, 10, 0);
    TE_SendToAll();

    center[2] += 70.0;
    TE_SetupBeamRingPoint(center, g_fTDMArenaRadius - 10.0, g_fTDMArenaRadius, g_iBeamSprite, 0, 0, 12, 1.05, 9.0, 0.0, color, 10, 0);
    TE_SendToAll();
}

// Update text message function to use color
void TE_SetupTextMessage(float pos[3], const char[] text, int color[4])
{
    int entity = CreateEntityByName("point_message");
    if (entity != -1)
    {
        DispatchKeyValue(entity, "message", text);
        DispatchSpawn(entity);
        TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
        
        // Set color
        SetVariantColor(color);
        AcceptEntityInput(entity, "Color");
        
        SetVariantString(text);
        AcceptEntityInput(entity, "ShowMessage");
        
        // Schedule removal using timer instead of undefined function
        CreateTimer(SPRITE_DURATION, Timer_RemoveEntity, entity);
    }
}

void GiveWarmupLoadout(int client)
{
    if (!IsValidClient(client))
        return;

    // Clear existing weapons
    StripWeapons(client);

    // Give basic weapons for warmup
    GivePlayerItem(client, "weapon_pistol");
    GivePlayerItem(client, "weapon_smg");
}

int GetTeamWithFewerPlayers()
{
    int redCount = 0;
    int blueCount = 0;
    
    // Count actual players on each team
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && !IsFakeClient(i))
        {
            if (g_iPlayerTeam[i] == TEAM_A)
                redCount++;
            else if (g_iPlayerTeam[i] == TEAM_B)
                blueCount++;
        }
    }
    
    PrintToServer("[PvP Debug] Team counts before assignment - Red: %d, Blue: %d", redCount, blueCount);
    
    // If teams are equal, randomly assign
    if (redCount == blueCount)
    {
        int team = GetRandomInt(0, 1) == 0 ? TEAM_A : TEAM_B;
        PrintToServer("[PvP Debug] Teams equal, randomly assigned to: %s", team == TEAM_A ? "RED" : "BLUE");
        return team;
    }
    
    // Otherwise, return team with fewer players
    int team = (redCount < blueCount) ? TEAM_A : TEAM_B;
    PrintToServer("[PvP Debug] Assigning to team with fewer players: %s", team == TEAM_A ? "RED" : "BLUE");
    return team;
}

public Action Timer_RemoveSpawnProtection(Handle timer, any client)
{
    if (!IsValidClient(client))
        return Plugin_Stop;
        
    g_bSpawnProtection[client] = false;
    SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
    PrintHintText(client, "Spawn protection has ended!");
    
    // Reset player color back to normal when spawn protection ends
    SetEntityRenderColor(client, 255, 255, 255, 255);
    
    return Plugin_Stop;
}

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    // Add weapon fire logic here if needed
    return;
}

public Action Timer_WarmupEnd(Handle timer)
{
    if (!g_bPvPActive && !g_bFFAActive)
        return Plugin_Stop;
        
    // Check if warmup is already ended to prevent double messages
    if (!g_bWarmupActive)
        return Plugin_Stop;
        
    g_bWarmupActive = false;
    
    // Enable damage and give random weapons
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && !IsFakeClient(i))
        {
            // Enable damage for both TDM and FFA modes
            SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
            
            // Give loadout and teleport based on game mode
            if (g_bFFAActive)
            {
                TeleportToFFASpawn(i);
                GiveRandomLoadout(i);
            }
            else if (g_bPvPActive && g_iPlayerTeam[i] != -1)
            {
                TeleportToSpawn(i, g_iPlayerTeam[i]);
                GiveRandomLoadout(i);
            }
            
            // Single announcement after giving loadout
            AnnounceLoadout(i);
        }
    }
    
    // Single announcement for game start
    if (g_bFFAActive)
    {
        PrintToChatAll("\x04[FFA] \x01 Warmup phase ended! Free-For-All match is now live!");
        PrintToChatAll("\x04[FFA] \x01 First to \x04%d\x01 kills wins!", g_cvFFAScoreLimit.IntValue);
    }
    else if (g_bPvPActive)
    {
        PrintToChatAll("\x04[TDM] \x01 Warmup phase ended! Team Deathmatch is now live!");
        PrintToChatAll("\x04[TDM] \x01 First team to \x04%d\x01 kills wins!", g_cvScoreLimit.IntValue);
    }
    
    return Plugin_Stop;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    bool controlledModeActive = g_bPvPActive || g_bFFAActive || g_bAWPActive || g_bGunGameActive || g_bOneShotMode;

    // Update regeneration timer regardless of damage source
    if (IsValidClient(victim))
    {
        // If it's world damage or self damage, clear any previous attacker tracking
        if (attacker == 0 || attacker == victim)
        {
            // L4D2 can emit self/world damage around incap and suicide; do not erase a fresh PvP attacker.
            if (!controlledModeActive || (GetGameTime() - g_fLastPvPAttackTime[victim]) > LAST_ATTACKER_CREDIT_TIME)
            {
                g_iLastAttacker[victim] = 0;
                g_fLastPvPAttackTime[victim] = 0.0;
            }
        }

        // Update health regen timing
        g_fLastDamageTime[victim] = GetGameTime();
        if (g_hRegenTimer[victim] != null)
        {
            KillTimer(g_hRegenTimer[victim]);
            g_hRegenTimer[victim] = null;
        }
        g_hRegenTimer[victim] = CreateTimer(REGEN_DELAY, Timer_RegenerateHealth, victim);
    }

    // Block damage if no mode is active or during warmup
    if (!controlledModeActive || g_bWarmupActive)
    {
        damage = 0.0;
        return Plugin_Changed;
    }

    // Skip if victim or attacker is invalid
    if (!IsValidClient(victim) || !IsValidClient(attacker) || victim == attacker)
        return Plugin_Continue;
        
    // Block team damage in TDM mode
    if (g_bPvPActive && g_iPlayerTeam[victim] != -1 && g_iPlayerTeam[attacker] != -1 && g_iPlayerTeam[victim] == g_iPlayerTeam[attacker])
    {
        damage = 0.0;
        return Plugin_Changed;
    }
        
    // Check if this is fall damage
    if (damagetype & DMG_FALL)
    {
        // Get current health
        int health = GetClientHealth(victim);
        
        // If damage would normally cause incapacitation, reduce damage to prevent it
        if (damage >= health)
        {
            // Cap damage to keep player alive with at least 1 health
            damage = health - 1.0;
            
            // Print debug message
            PrintToServer("[PvP Debug] Prevented fall incapacitation for %N (damage: %.0f, health: %d)", 
                victim, damage, health);
        }
        
        return Plugin_Changed;
    }

    // Check for knife level in Gun Game mode - make it one-hit kill
    if (g_bGunGameActive)
    {
        char weaponName[32];
        GetClientWeapon(attacker, weaponName, sizeof(weaponName));
        
        if (StrEqual(weaponName, "weapon_melee") && 
            g_iGunGameLevel[attacker] == sizeof(g_sRandomizedGunGameWeapons) - 1 && 
            g_bKnifeOneHitKill)  // Only enable one-hit kill if the flag is explicitly set
        {
            // Make knife one-hit kill by setting damage to a high value
            damage = float(GetClientHealth(victim)) + 100.0;
            PrintToServer("[Gun Game Debug] Applied one-hit kill from %N to %N with melee at final level", attacker, victim);
            return Plugin_Changed;
        }
    }
    
    // Store last attacker and weapon for kill feed
    g_iLastAttacker[victim] = attacker;
    g_fLastPvPAttackTime[victim] = GetGameTime();
    char weapon[32];
    GetClientWeapon(attacker, weapon, sizeof(weapon));
    FormatWeaponName(weapon, sizeof(weapon));
    strcopy(g_sLastWeapon[victim], sizeof(g_sLastWeapon[]), weapon);

    // Check spawn protection for both modes
    if (g_bSpawnProtection[victim])
    {
        damage = 0.0;
        return Plugin_Changed;
    }

    // Add One Shot mode check
    if (g_bOneShotMode)
    {
        if (!IsValidClient(victim) || !IsValidClient(attacker) || 
            victim == attacker)
            return Plugin_Continue;

        // Get the actual weapon being used - renamed to weaponName to avoid shadow warning
        char weaponName[32];
        int activeWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
        if (activeWeapon != -1)
        {
            GetEdictClassname(activeWeapon, weaponName, sizeof(weaponName));
            // Format the weapon name for display
            char formattedWeapon[32];
            GetFormattedWeaponName(weaponName, formattedWeapon, sizeof(formattedWeapon));
            // Store the formatted weapon for kill feed
            strcopy(g_sLastWeapon[victim], sizeof(g_sLastWeapon[]), formattedWeapon);
            strcopy(g_sLastHurtWeapon[victim], sizeof(g_sLastHurtWeapon[]), formattedWeapon);
        }

        // Make damage lethal but preserve weapon info
        damage = float(GetClientHealth(victim)) + 1.0;
        return Plugin_Changed;
    }
    
    // Handle the one-hit knife kill in Gun Game
    if (g_bGunGameActive && g_bKnifeOneHitKill && IsValidClient(attacker) && IsValidClient(victim))
    {
        char weaponName[32];
        GetClientWeapon(attacker, weaponName, sizeof(weaponName));
        
        // Fix one-hit melee kill by checking for any melee weapon
        if (StrEqual(weaponName, "weapon_melee") || 
            StrContains(weaponName, "melee") != -1 ||
            StrContains(weaponName, "katana") != -1 ||
            StrContains(weaponName, "machete") != -1 ||
            StrContains(weaponName, "crowbar") != -1 ||
            StrContains(weaponName, "bat") != -1 ||
            StrContains(weaponName, "knife") != -1)
        {
            // Always make melee do enough damage to kill in one hit
            damage = float(GetClientHealth(victim)) + 100.0;
            return Plugin_Changed;
        }
    }

    // Increase katana/knife damage at final level
    if (g_bGunGameActive && IsValidClient(attacker) && IsValidClient(victim)) 
    {
        int attackerLevel = g_iGunGameLevel[attacker];
        int maxLevel = sizeof(g_sRandomizedGunGameWeapons) - 1;
        
        // Check if attacker is at knife/katana level (final level)
        if (attackerLevel == maxLevel) 
        {
            char weaponName[64];
            GetClientWeapon(attacker, weaponName, sizeof(weaponName));
            
            // Check if it's a melee weapon (katana/knife)
            if (StrEqual(weaponName, "weapon_melee") || 
                StrContains(weaponName, "katana") != -1 || 
                StrContains(weaponName, "knife") != -1)
            {
                // Make it a one-hit kill (50 damage)
                damage = 50.0;
                return Plugin_Changed;
            }
        }
    }
    
    // In the damage handling code
    if (!IsValidClient(victim) || !IsValidClient(attacker))
    {
        // Handle self damage or invalid clients
        if (IsValidClient(victim))
        {
            // Update last damage time for health regeneration
            g_fLastDamageTime[victim] = GetGameTime();
            
            // Clear any existing regen timer
            if (g_hRegenTimer[victim] != null)
            {
                KillTimer(g_hRegenTimer[victim]);
                g_hRegenTimer[victim] = null;
            }
            
            // Start new regeneration timer
            g_hRegenTimer[victim] = CreateTimer(REGEN_DELAY, Timer_RegenerateHealth, victim);
        }
        PrintToServer("[Debug] Invalid clients or self damage - V: %d, A: %d", victim, attacker);
        return Plugin_Continue;
    }

    return Plugin_Continue;
}

public void LoadSpawnPoints()
{
    // Always reset spawn counts at the beginning of loading
    for (int team = 0; team < MAX_TEAMS; team++)
    {
        g_iSpawnCount[team] = 0;
    }
    ResetTDMSpawnCooldowns();
    
    char path[PLATFORM_MAX_PATH];
    char mapName[64];
    GetCurrentMap(mapName, sizeof(mapName));
    
    // Build path with map name
    char fileName[128];
    Format(fileName, sizeof(fileName), SPAWN_FILE, mapName);
    BuildPath(Path_SM, path, sizeof(path), fileName);
    
    if (!FileExists(path))
    {
        LogMessage("[PvP] No spawn points file found for map %s", mapName);
        return;
    }
    
    KeyValues kv = new KeyValues("SpawnPoints");
    kv.ImportFromFile(path);
    
    for (int team = 0; team < MAX_TEAMS; team++)
    {
        // g_iSpawnCount[team] = 0;  // Removed as it's now done at the beginning
        
        char section[8];
        Format(section, sizeof(section), "Team%d", team);
        
        if (kv.JumpToKey(section))
        {
            if (kv.GotoFirstSubKey())
            {
                do
                {
                    kv.GetVector("position", g_fSpawnPoints[team][g_iSpawnCount[team]]);
                    kv.GetVector("angles", g_fSpawnAngles[team][g_iSpawnCount[team]]);
                    g_fTDMSpawnNextUse[team][g_iSpawnCount[team]] = 0.0;
                    g_iSpawnCount[team]++;
                } while (kv.GotoNextKey() && g_iSpawnCount[team] < MAX_SPAWNS);
                kv.GoBack();
            }
            kv.GoBack();
        }
    }
    
    delete kv;
}

public void LoadWarmupSpawns()
{
    char path[PLATFORM_MAX_PATH];
    char mapName[64];
    GetCurrentMap(mapName, sizeof(mapName));
    
    // Build path with map name
    char fileName[128];
    Format(fileName, sizeof(fileName), WARMUP_SPAWN_FILE, mapName);
    BuildPath(Path_SM, path, sizeof(path), fileName);
    
    if (!FileExists(path))
    {
        LogMessage("[PvP] No warmup spawn points file found for map %s", mapName);
        return;
    }
        
    KeyValues kv = new KeyValues("WarmupSpawns");
    kv.ImportFromFile(path);
    
    g_iWarmupSpawnCount = 0;
    
    if (kv.GotoFirstSubKey())
    {
        do
        {
            kv.GetVector("position", g_fWarmupSpawns[g_iWarmupSpawnCount]);
            kv.GetVector("angles", g_fWarmupAngles[g_iWarmupSpawnCount]);
            g_iWarmupSpawnCount++;
        } while (kv.GotoNextKey() && g_iWarmupSpawnCount < MAX_WARMUP_SPAWNS);
    }
    delete kv;
}

void TeleportToSpawn(int client, int team)
{
    if (!IsValidClient(client) || team < 0 || team >= MAX_TEAMS)
        return;
        
    // Verify we have spawns for this team
    if (g_iSpawnCount[team] <= 0)
    {
        LogError("[TDM] No spawn points found for team %d", team);
        return;
    }

    int spawnIndex = SelectTDMSpawnIndex(client, team);
    if (spawnIndex < 0)
        return;
    
    // Debug print to verify spawn selection
    PrintToServer("[TDM] Teleporting player %N (Team: %s) to spawn %d", 
        client, 
        team == TEAM_A ? "Red" : "Blue", 
        spawnIndex);
    
    TeleportEntity(client, g_fSpawnPoints[team][spawnIndex], g_fSpawnAngles[team][spawnIndex], NULL_VECTOR);
    g_iLastTDMSpawnIndex[team] = spawnIndex;
    g_fTDMSpawnNextUse[team][spawnIndex] = GetGameTime() + TDM_SPAWN_REUSE_COOLDOWN;
}

int SelectTDMSpawnIndex(int client, int team)
{
    float now = GetGameTime();
    int best = -1;
    float bestScore = -999999.0;
    int fallback = -1;
    float fallbackTime = 99999999.0;
    int riskyBest = -1;
    float riskyBestScore = -999999.0;
    int fallbackAny = -1;
    float fallbackAnyTime = 99999999.0;

    for (int i = 0; i < g_iSpawnCount[team]; i++)
    {
        if (g_iSpawnCount[team] > 1 && i == g_iLastTDMSpawnIndex[team])
            continue;

        bool occupied = IsTDMSpawnOccupied(team, i, client);
        if (occupied)
            continue;

        bool watched = IsSpawnWatchedByEnemies(client, g_fSpawnPoints[team][i], team, true);
        bool enemyTooClose = IsTDMSpawnEnemyTooClose(team, i, client);
        bool risky = watched || enemyTooClose;

        if (g_fTDMSpawnNextUse[team][i] < fallbackAnyTime)
        {
            fallbackAny = i;
            fallbackAnyTime = g_fTDMSpawnNextUse[team][i];
        }

        if (!risky && g_fTDMSpawnNextUse[team][i] < fallbackTime)
        {
            fallback = i;
            fallbackTime = g_fTDMSpawnNextUse[team][i];
        }

        if (g_fTDMSpawnNextUse[team][i] > now)
            continue;

        float score = GetTDMSpawnSafetyScore(team, i, client) + GetRandomFloat(0.0, 24.0);
        if (risky)
        {
            score -= (watched ? SPAWN_WATCH_SCORE_PENALTY : 900.0);
            if (score > riskyBestScore)
            {
                riskyBestScore = score;
                riskyBest = i;
            }
            continue;
        }

        if (score > bestScore)
        {
            bestScore = score;
            best = i;
        }
    }

    if (best != -1)
        return best;

    if (fallback != -1)
        return fallback;

    if (riskyBest != -1)
        return riskyBest;

    if (fallbackAny != -1)
        return fallbackAny;

    return GetRandomInt(0, g_iSpawnCount[team] - 1);
}

bool IsTDMSpawnOccupied(int team, int spawnIndex, int spawningClient)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (i == spawningClient || !IsValidClient(i) || !IsPlayerAlive(i))
            continue;

        float pos[3];
        GetClientAbsOrigin(i, pos);
        if (GetVectorDistance(pos, g_fSpawnPoints[team][spawnIndex]) <= TDM_SPAWN_OCCUPIED_RADIUS)
            return true;
    }

    return false;
}

bool IsTDMSpawnEnemyTooClose(int team, int spawnIndex, int spawningClient)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (i == spawningClient || !IsValidClient(i) || !IsPlayerAlive(i))
            continue;

        if (g_iPlayerTeam[i] == -1 || g_iPlayerTeam[i] == team)
            continue;

        float pos[3];
        GetClientAbsOrigin(i, pos);
        if (GetVectorDistance(pos, g_fSpawnPoints[team][spawnIndex]) <= TDM_SPAWN_ENEMY_MIN_DISTANCE)
            return true;
    }

    return false;
}

float GetTDMSpawnSafetyScore(int team, int spawnIndex, int spawningClient)
{
    float nearestEnemy = 1800.0;
    float nearestTeammate = 800.0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (i == spawningClient || !IsValidClient(i) || !IsPlayerAlive(i))
            continue;

        float pos[3];
        GetClientAbsOrigin(i, pos);
        float distance = GetVectorDistance(pos, g_fSpawnPoints[team][spawnIndex]);

        if (g_iPlayerTeam[i] == team)
        {
            if (distance < nearestTeammate)
                nearestTeammate = distance;
        }
        else if (g_iPlayerTeam[i] != -1)
        {
            if (distance < nearestEnemy)
                nearestEnemy = distance;
        }
    }

    float score = nearestEnemy - (nearestTeammate * 0.15);
    if (nearestEnemy < TDM_SPAWN_ENEMY_MIN_DISTANCE)
    {
        score -= (TDM_SPAWN_ENEMY_MIN_DISTANCE - nearestEnemy) * 3.0;
    }

    return score;
}

void TeleportToWarmupSpawn(int client)
{
    if (g_iWarmupSpawnCount > 0)
    {
        int spawnIndex = GetRandomInt(0, g_iWarmupSpawnCount - 1);
        TeleportEntity(client, g_fWarmupSpawns[spawnIndex], g_fWarmupAngles[spawnIndex], NULL_VECTOR);
    }
    else if (g_bFFAActive || g_bAWPActive || g_bGunGameActive)
    {
        TeleportToFFASpawn(client);
    }
    else
    {
        LogError("[PvP] No warmup spawns available!");
        PrintToChatAll("\x04[PvP] \x01 Error: No warmup spawns found! Please add warmup spawns using !addwarmupspawn");
    }
}

void AnnounceLoadout(int client)
{
    // Use a static array to track the last time we started a delayed announcement for each client
    static float lastAnnouncementStartTime[MAXPLAYERS+1];
    float currentTime = GetGameTime();
    
    // If we've already started an announcement process in the last 3 seconds, don't start another one
    if (currentTime - lastAnnouncementStartTime[client] < 3.0)
        return;
    
    // Otherwise, record that we're starting an announcement process now
    lastAnnouncementStartTime[client] = currentTime;
    
    // Create the delayed announcement timer
    CreateTimer(0.5, Timer_DelayedAnnounceLoadout, client);
}

public Action Timer_DelayedAnnounceLoadout(Handle timer, any client)
{
    if (!IsValidClient(client))
        return Plugin_Stop;
        
    char primary[32], secondary[32];
    
    // Get the player's weapons - now we do this AFTER a short delay
    // to make sure the player actually has the correct weapons equipped
    int primaryWeapon = GetPlayerWeaponSlot(client, 0);
    int secondaryWeapon = GetPlayerWeaponSlot(client, 1);
    
    if (primaryWeapon != -1)
    {
        GetEntityClassname(primaryWeapon, primary, sizeof(primary));
        FormatWeaponName(primary, sizeof(primary));
    }
    else
    {
        strcopy(primary, sizeof(primary), "no primary");
    }
    
    if (secondaryWeapon != -1)
    {
        GetEntityClassname(secondaryWeapon, secondary, sizeof(secondary));
        FormatWeaponName(secondary, sizeof(secondary));
    }
    else
    {
        strcopy(secondary, sizeof(secondary), "no secondary");
    }
    
    // Add game mode prefix to make the message more visible
    if (g_bPvPActive)
    {
        PrintToChat(client, "\x04[TDM] \x01Your loadout: \x04%s\x01 + \x04%s", primary, secondary);
    }
    else if (g_bGunGameActive)
    {
        PrintToChat(client, "\x04[Gun Game] \x01Your loadout: \x04%s\x01 + \x04%s", primary, secondary);
    }
    else if (g_bFFAActive)
    {
        PrintToChat(client, "\x04[FFA] \x01Your loadout: \x04%s\x01 + \x04%s", primary, secondary);
    }
    else if (g_bAWPActive)
    {
        PrintToChat(client, "\x04[AWP] \x01Your loadout: \x04%s\x01 + \x04%s", primary, secondary);
    }
    else if (g_bOneShotMode)
    {
        PrintToChat(client, "\x04[One Shot] \x01Your loadout: \x04%s\x01 + \x04%s", primary, secondary);
    }
    else
    {
        PrintToChat(client, "\x04[PvP] \x01Your loadout: \x04%s\x01 + \x04%s", primary, secondary);
    }
    
    return Plugin_Stop;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidClient(client))
        return;
        
    // Fix for 300 HP bug - check after a short delay to catch any abnormal health settings
    CreateTimer(0.2, Timer_CheckAbnormalHealth, client);
        
    // Initialize health regeneration
    g_fLastDamageTime[client] = GetGameTime();
    if (g_hRegenTimer[client] != null)
    {
        KillTimer(g_hRegenTimer[client]);
        g_hRegenTimer[client] = null;
    }
    
    // Remove health items in TDM, FFA, OneShot and AWP modes
    if (g_bPvPActive || g_bFFAActive || g_bOneShotMode || g_bAWPActive)
    {
        // Add a slight delay to ensure items are removed after spawn
        CreateTimer(0.1, Timer_RemoveHealthItems, client);
    }
    
    // If in Gun Game mode, don't do anything here - weapon will be given by GiveGunGameWeapon
    if (g_bGunGameActive)
    {
        // Only handle model set, but don't give any items
        int character = GetRandomInt(0, 7);
        SetEntProp(client, Prop_Send, "m_survivorCharacter", character);
        
        // Set appropriate model based on character
        switch(character)
        {
            case 0: SetEntityModel(client, "models/survivors/survivor_gambler.mdl");    // Nick
            case 1: SetEntityModel(client, "models/survivors/survivor_producer.mdl");   // Rochelle
            case 2: SetEntityModel(client, "models/survivors/survivor_coach.mdl");      // Coach
            case 3: SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");   // Ellis
            case 4: SetEntityModel(client, "models/survivors/survivor_namvet.mdl");     // Bill
            case 5: SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");  // Zoey
            case 6: SetEntityModel(client, "models/survivors/survivor_biker.mdl");      // Francis
            case 7: SetEntityModel(client, "models/survivors/survivor_manager.mdl");    // Louis
            default: SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
        }
        
        // Let the Gun Game respawn system handle giving the weapon
        CreateTimer(0.1, Timer_TeleportAndEquipGunGame, client);
        return;
    }
        
    // Only handle model fixes if in PvP or FFA mode
    if (!g_bPvPActive && !g_bFFAActive)
        return;
        
    // Randomize character and set model
    int character = GetRandomInt(0, 7);
    SetEntProp(client, Prop_Send, "m_survivorCharacter", character);
    
    // Set appropriate model based on character
    switch(character)
    {
        case 0: SetEntityModel(client, "models/survivors/survivor_gambler.mdl");    // Nick
        case 1: SetEntityModel(client, "models/survivors/survivor_producer.mdl");   // Rochelle
        case 2: SetEntityModel(client, "models/survivors/survivor_coach.mdl");      // Coach
        case 3: SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");   // Ellis
        case 4: SetEntityModel(client, "models/survivors/survivor_namvet.mdl");     // Bill
        case 5: SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");  // Zoey
        case 6: SetEntityModel(client, "models/survivors/survivor_biker.mdl");      // Francis
        case 7: SetEntityModel(client, "models/survivors/survivor_manager.mdl");    // Louis
        default: SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
    }
    
    // Reset team colors if in TDM mode
    if (g_bPvPActive && g_iPlayerTeam[client] != -1)
    {
        if (g_iPlayerTeam[client] == TEAM_A)
        {
            SetEntityRenderColor(client, 255, 0, 0, 255);  // Red
        }
        else
        {
            SetEntityRenderColor(client, 0, 0, 255, 255);  // Blue
        }
    }
    
    // Add One Shot mode check
    if (g_bOneShotMode)
    {
        SetupOneShotPlayer(client);
    }
}

public Action Timer_CheckAbnormalHealth(Handle timer, any client)
{
    if (IsValidClient(client) && IsPlayerAlive(client))
    {
        int health = GetClientHealth(client);
        // If player somehow has more than 200 HP (likely the 300 HP bug)
        if (health > 200)
        {
            // Reset to normal health
            SetEntityHealth(client, 100);
            PrintToServer("[Health Debug] Fixed abnormal health value for client %d: %d -> 100", client, health);
        }
    }
    return Plugin_Continue;
}

public Action Command_StartAWP(int client, int args)
{
    PrintToServer("[AWP] Command_StartAWP called"); // Debug line
    
    if (g_bAWPActive)
    {
        ReplyToCommand(client, "\x04[AWP] \x01 AWP mode is already active!");
        return Plugin_Handled;
    }

    // Check if other modes are active
    if (g_bPvPActive || g_bFFAActive)
    {
        ReplyToCommand(client, "\x04[AWP] \x01 Cannot start AWP mode while another mode is active!");
        return Plugin_Handled;
    }

    if (!PrepareGeneratedFFASpawns("AWP", client))
    {
        return Plugin_Handled;
    }

    // Reset all player stats
    for (int i = 1; i <= MaxClients; i++)
    {
        g_iPlayerKills[i] = 0;
        g_iPlayerDeaths[i] = 0;
        g_iAWPKills[i] = 0;
    }

    // Kill existing timers safely
    if (g_hMenuReminderTimer != null)
    {
        KillTimer(g_hMenuReminderTimer);
        g_hMenuReminderTimer = null;
    }
    
    // Start both reminder timers
    if (g_hSwitchReminderTimer != null)
        KillTimer(g_hSwitchReminderTimer);
    g_hSwitchReminderTimer = CreateTimer(GetRandomFloat(30.0, 60.0), Timer_SwitchReminder);
    
    if (g_hMenuReminderTimer != null)
        KillTimer(g_hMenuReminderTimer);
    g_hMenuReminderTimer = CreateTimer(GetRandomFloat(30.0, 60.0), Timer_MenuReminder);

    // Initialize AWP mode
    g_bAWPActive = true;
    g_bMatchEnded = false;
    g_bWarmupActive = g_cvWarmupEnabled.BoolValue;
    SetControlledGlowRendering(true);
    SuppressClimbPluginGlow();
    DisableNonPvPGlows();
    ApplyPvPMapCleanup();
    EnsureGlowRefreshTimer();
    
    // Start round timer
    if (g_hAWPRoundTimer != null)
        KillTimer(g_hAWPRoundTimer);
    g_hAWPRoundTimer = CreateTimer(float(g_cvAWPRoundTime.IntValue), Timer_AWPRoundEnd);
    g_fAWPStartTime = GetGameTime();

    // Disable infected spawning
    if (g_hSpecialSpawnInterval != null)
        g_hSpecialSpawnInterval.IntValue = 99999;
    if (g_hCommonLimit != null)
        g_hCommonLimit.IntValue = 0;
    if (g_hDirectorNoSpecials != null)
        g_hDirectorNoSpecials.IntValue = 1;
    if (g_hDirectorNoMobs != null)
        g_hDirectorNoMobs.IntValue = 1;
    if (g_hDirectorNoBosses != null)
        g_hDirectorNoBosses.IntValue = 1;
        
    // Kill all existing infected
    KillAllInfected();
    
    // Disable glow if it's enabled
    if (g_hGlowEnable != null)
        g_hGlowEnable.IntValue = 0;
    
    // Setup all players
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && !IsFakeClient(i))
        {
            if (!IsPlayerAlive(i))
            {
                L4D_RespawnPlayer(i);
                CreateTimer(0.1, Timer_SetupAWPPlayer, i);
            }
            else
            {
                // Set character and model
                SetEntProp(i, Prop_Send, "m_survivorCharacter", GetRandomInt(0, 7));
                SetEntityModel(i, "models/survivors/survivor_gambler.mdl");
                SetEntityMoveType(i, MOVETYPE_WALK);
                SetEntityRenderMode(i, RENDER_NORMAL);
                SetEntityRenderColor(i, 255, 255, 255, 255);
                SetEntProp(i, Prop_Send, "m_iHideHUD", 0);
                
                GiveAWPLoadout(i);
            }
            
            // Set initial spawn protection
            g_bSpawnProtection[i] = true;
            SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
            // Add green glow to indicate spawn protection
            SetEntityRenderColor(i, 0, 255, 0, 200); // Green color with slight transparency
            CreateTimer(SPAWN_PROTECTION_TIME, Timer_RemoveSpawnProtection, i);
            
            // Teleport to warmup spawns during warmup
            if (g_bWarmupActive)
            {
                TeleportToWarmupSpawn(i);
            }
            else
            {
                TeleportToFFASpawn(i);
            }
            
            // Hook player for weapon pickup
            SDKHook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
        }
    }
    
    // Only start warmup if enabled
    if (g_bWarmupActive)
    {
        CreateTimer(AWP_WARMUP_TIME, Timer_EndAWPWarmup);
        PrintToChatAll("\x04[AWP] \x01Warmup phase: \x04%.0f\x01 seconds!", AWP_WARMUP_TIME);
    }
    else
    {
        PrintToChatAll("\x04[AWP] \x01 Match is now live!");
        PrintToChatAll("\x04[AWP] \x01 First to \x04%d\x01 kills wins!", g_cvAWPScoreLimit.IntValue);
    }
    
    // Announce mode start
    PrintToChatAll("\x04[AWP] \x01 AWP mode started!");
    
    // Remove ground weapons and health items
    CleanupGroundWeapons();
    CreateTimer(5.0, Timer_CleanupGroundWeapons, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    
    return Plugin_Handled;
}

public Action Command_StopAWP(int client, int args)
{
    if (!g_bAWPActive)
    {
        ReplyToCommand(client, "\x04[AWP] \x01 AWP mode is not active!");
        return Plugin_Handled;
    }
    
    EndAWPMode();
    PrintToChatAll("\x04[AWP] \x01 AWP mode has been stopped by an admin!");
    return Plugin_Handled;
}

void GiveAWPLoadout(int client)
{
    if (!IsValidClient(client))
        return;
        
    StripWeapons(client);
    
    // Only give AWP
    GivePlayerItem(client, "weapon_sniper_awp");
    
    // Set health to 100
    SetEntProp(client, Prop_Send, "m_iHealth", 100);
    SetEntProp(client, Prop_Send, "m_iMaxHealth", 100);
}

public Action Timer_EndAWPWarmup(Handle timer)
{
    PrintToServer("[AWP] Timer_EndAWPWarmup called"); // Debug line
    
    if (!g_bAWPActive)
        return Plugin_Stop;
        
    g_bWarmupActive = false;
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && !IsFakeClient(i))
        {
            SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
            SetupAWPPlayer(i);
            TeleportToFFASpawn(i);
            
            g_bSpawnProtection[i] = true;
            SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
            // Add green glow to indicate spawn protection
            SetEntityRenderColor(i, 0, 255, 0, 200); // Green color with slight transparency
            CreateTimer(SPAWN_PROTECTION_TIME, Timer_RemoveSpawnProtection, i);
        }
    }
    
    PrintToChatAll("\x04[AWP] \x01 Warmup phase ended! Match is now live!");
    PrintToChatAll("\x04[AWP] \x01 First to \x04%d\x01 kills wins!", g_cvAWPScoreLimit.IntValue);
    
    return Plugin_Stop;
}

public Action Timer_EndAWP(Handle timer)
{
    if (!g_bAWPActive)
        return Plugin_Stop;

    // Find winner based on kills
    int winnerClient = -1;
    int highestKills = -1;
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && g_iAWPKills[i] > highestKills)
        {
            highestKills = g_iAWPKills[i];
            winnerClient = i;
        }
    }

    if (winnerClient != -1)
    {
        PrintToChatAll("\x04[AWP] \x01 Time's up! Winner: \x04%N\x01 with \x04%d\x01 kills!", 
            winnerClient, g_iAWPKills[winnerClient]);
    }
    else
    {
        PrintToChatAll("\x04[AWP] \x01 Time's up! No winner!");
    }

    g_hAWPRoundTimer = null;
    CreateTimer(3.0, Timer_DelayedEndAWP);
    
    return Plugin_Stop;
}

void EndAWPMode()
{
    if (!g_bAWPActive)
        return;

    // Find winner
    int winnerClient = -1;
    int highestKills = -1;
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && g_iAWPKills[i] > highestKills)
        {
            highestKills = g_iAWPKills[i];
            winnerClient = i;
        }
    }

    if (winnerClient != -1)
    {
        PrintToChatAll("\x04[AWP] \x01 Game Over! Winner: \x04%N\x01 with \x04%d\x01 kills!", 
            winnerClient, highestKills);
    }

    g_bAWPActive = false;
    g_bWarmupActive = false;
    
    if (g_hAWPRoundTimer != null)
    {
        KillTimer(g_hAWPRoundTimer);
        g_hAWPRoundTimer = null;
    }

    // Reset all players
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
        {
            SetEntityRenderColor(i, 255, 255, 255, 255);
            g_iAWPKills[i] = 0;
            SetEntityHealth(i, 100);
        }
    }

    RemoveAllTeamGlows();
    for (int i = 1; i <= MaxClients; i++)
    {
        RemoveKillcamGlow(i);
        g_bInKillcam[i] = false;
        g_iKillcamTarget[i] = -1;
    }
    StopGlowRefreshTimerIfIdle();
}

public Action Timer_SetupAWPPlayer(Handle timer, any client)
{
    if (!IsValidClient(client) || !g_bAWPActive)
        return Plugin_Stop;

    if (!IsPlayerAlive(client))
    {
        L4D_RespawnPlayer(client);
        CreateTimer(0.2, Timer_SetupAWPPlayer, client);
        return Plugin_Stop;
    }

    // Set character and model
    SetEntProp(client, Prop_Send, "m_survivorCharacter", GetRandomInt(0, 7));
    SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
    SetEntityMoveType(client, MOVETYPE_WALK);
    SetEntityRenderMode(client, RENDER_NORMAL);
    SetEntityRenderColor(client, 255, 255, 255, 255);
    SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
    
    // Give AWP loadout (don't call SetupAWPPlayer here)
    GiveAWPLoadout(client);
    
    // Handle teleportation based on warmup state
    if (g_bWarmupActive)
    {
        TeleportToWarmupSpawn(client);
    }
    else
    {
        TeleportToFFASpawn(client);
    }
    
    // Set spawn protection
    g_bSpawnProtection[client] = true;
    SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
    // Add green glow to indicate spawn protection
    SetEntityRenderColor(client, 0, 255, 0, 200); // Green color with slight transparency
    CreateTimer(SPAWN_PROTECTION_TIME, Timer_RemoveSpawnProtection, client);
    
    return Plugin_Stop;
}

public Action Timer_DelayedEndAWP(Handle timer)
{
    EndAWPMode();
    return Plugin_Stop;
}

void SetupAWPPlayer(int client)
{
    if (!IsValidClient(client))
        return;

    // Clear existing weapons
    StripWeapons(client);

    // Set health to 1 BEFORE giving items
    SetEntityHealth(client, 1);
    SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
    
    // Give AWP
    GivePlayerItem(client, WEAPON_AWP);
    
    // Give healing items
    GivePlayerItem(client, "weapon_first_aid_kit");
    GivePlayerItem(client, "weapon_pain_pills");
    
    // Give random throwable
    switch(GetRandomInt(0, 1))
    {
        case 0: GivePlayerItem(client, "weapon_pipe_bomb");
        case 1: GivePlayerItem(client, "weapon_molotov");
    }
    
    // Set speed
    SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 220.0);
    SetEntProp(client, Prop_Send, "m_bAdrenalineActive", 1);
}

void KillAllInfected()
{
    // Kill all special infected
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 3)
        {
            ForcePlayerSuicide(i);
        }
    }
    
    // Kill all common infected
    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE)
    {
        AcceptEntityInput(entity, "Kill");
    }
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    // Skip if client is invalid or no mode is active
    if (!IsValidClient(client))
        return Plugin_Continue;

    // Handle AWP mode restrictions
    if (g_bAWPActive)
    {
        // Block reload if health items somehow got picked up
        if (buttons & IN_RELOAD)
        {
            int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
            if (activeWeapon != -1)
            {
                char weaponName[32];
                GetEdictClassname(activeWeapon, weaponName, sizeof(weaponName));
                if (StrEqual(weaponName, "weapon_first_aid_kit") || 
                    StrEqual(weaponName, "weapon_pain_pills") || 
                    StrEqual(weaponName, "weapon_adrenaline"))
                {
                    buttons &= ~IN_RELOAD;
                    return Plugin_Changed;
                }
            }
        }

        // Keep health at 100
        SetEntProp(client, Prop_Send, "m_iHealth", 100);
        SetEntProp(client, Prop_Send, "m_iMaxHealth", 100);
        SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
    }

    return Plugin_Continue;
}

public Action OnPlayerUse(int client, const char[] command, int argc)
{
    if (!g_bAWPActive || !IsValidClient(client))
        return Plugin_Continue;
        
    // Get entity being used
    int entity = GetClientAimTarget(client, false);
    if (entity == -1)
        return Plugin_Continue;
        
    char classname[64];
    GetEdictClassname(entity, classname, sizeof(classname));
    
    // Block health items
    if (StrEqual(classname, "weapon_first_aid_kit", false) ||
        StrEqual(classname, "weapon_pain_pills", false) ||
        StrEqual(classname, "weapon_adrenaline", false))
    {
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

public Action Timer_ForceHealth(Handle timer, any client)
{
    if (g_bAWPActive && IsValidClient(client) && IsPlayerAlive(client))
    {
        SetEntProp(client, Prop_Send, "m_iHealth", 1);
        SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
    }
    return Plugin_Stop;
}

public Action Timer_HandleIdleReturn(Handle timer, any client)
{
    if (!IsValidClient(client))
        return Plugin_Stop;
        
    if (g_bFFAActive)
    {
        Timer_SetupFFAPlayer(null, client);
    }
    else if (g_bAWPActive) 
    {
        Timer_SetupAWPPlayer(null, client);
    }
    
    return Plugin_Stop;
}

public Action Command_JoinFromIdle(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;
        
    if (GetClientTeam(client) != TEAM_IDLE)
    {
        PrintToChat(client, "\x04[PvP] \x01You are not in idle state!");
        return Plugin_Handled;
    }
    
    // Change to survivor team and setup based on current mode
    ChangeClientTeam(client, TEAM_SURVIVOR);
    
    if (g_bFFAActive)
    {
        CreateTimer(0.1, Timer_SetupFFAPlayer, client);
        PrintToChat(client, "\x04[FFA] \x01You have joined Free-For-All mode!");
    }
    else if (g_bAWPActive)
    {
        CreateTimer(0.1, Timer_SetupAWPPlayer, client);
        PrintToChat(client, "\x04[AWP] \x01You have joined AWP mode!");
    }
    else if (g_bPvPActive)
    {
        int team = GetTeamWithFewerPlayers();
        g_iPlayerTeam[client] = team;
        CreateTimer(0.1, Timer_ForceJoinTeam, client);
        PrintToChat(client, "\x04[TDM] \x01You have joined Team %s!", team == TEAM_A ? "RED" : "BLUE");
    }
    else
    {
        PrintToChat(client, "\x04[Info] \x01No game mode is currently active!");
    }
    
    return Plugin_Handled;
}

public Action Timer_AWPRoundEnd(Handle timer)
{
    g_hAWPRoundTimer = null;
    
    // Find winner based on kills
    int winnerClient = -1;
    int highestKills = -1;
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && g_iAWPKills[i] > highestKills)
        {
            highestKills = g_iAWPKills[i];
            winnerClient = i;
        }
    }

    if (winnerClient != -1)
    {
        PrintToChatAll("\x04[AWP] \x01 Time's up! Winner: \x04%N\x01 with \x04%d\x01 kills!", 
            winnerClient, g_iAWPKills[winnerClient]);
    }
    else
    {
        PrintToChatAll("\x04[AWP] \x01 Time's up! No winner!");
    }

    CreateTimer(3.0, Timer_DelayedEndAWP);
    return Plugin_Stop;
}

public Action Command_DeleteFFASpawn(int client, int args)
{
    if (!client) return Plugin_Handled;

    if (g_iFFASpawnCount == 0)
    {
        PrintToChat(client, "\x04[FFA] \x01 No FFA spawn points to delete!");
        return Plugin_Handled;
    }

    float clientPos[3];
    GetClientAbsOrigin(client, clientPos);

    int closestIndex = -1;
    float closestDistance = -1.0;

    for (int i = 0; i < g_iFFASpawnCount; i++)
    {
        float distance = GetVectorDistance(clientPos, g_fFFASpawnPoints[i]);
        if (closestIndex == -1 || distance < closestDistance)
        {
            closestIndex = i;
            closestDistance = distance;
        }
    }

    if (closestIndex != -1)
    {
        // Shift all spawn points after the deleted one
        for (int i = closestIndex; i < g_iFFASpawnCount - 1; i++)
        {
            g_fFFASpawnPoints[i] = g_fFFASpawnPoints[i + 1];
            g_fFFASpawnAngles[i] = g_fFFASpawnAngles[i + 1];
            g_fFFASpawnNextUse[i] = g_fFFASpawnNextUse[i + 1];
        }
        g_iFFASpawnCount--;
        if (g_iLastFFASpawnIndex == closestIndex)
            g_iLastFFASpawnIndex = -1;

        PrintToChatAll("\x04[FFA] \x01 Deleted closest FFA spawn point!");
    }

    return Plugin_Handled;
}

void DisplayUpdatedMenu(int client)
{
    Menu menu = new Menu(MenuHandler_TeamMenu);
    
    // Update time for this display
    g_iLastMenuTime[client] = GetTime();
    
    if (g_bAWPActive)
    {
        menu.SetTitle("AWP Scoreboard\n ");
        
        int playerCount = 0;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
            {
                char display[64];
                Format(display, sizeof(display), "%N: %d kills (%d/%d)", 
                    i, g_iAWPKills[i], g_iPlayerKills[i], g_iPlayerDeaths[i]);
                menu.AddItem("", display, ITEMDRAW_DISABLED);
                playerCount++;
            }
        }
        
        if (playerCount == 0)
        {
            menu.AddItem("", "No players in game", ITEMDRAW_DISABLED);
        }
        
        if (g_hAWPRoundTimer != null)
        {
            menu.AddItem("", " ", ITEMDRAW_SPACER);
            int timeLeft = g_cvAWPRoundTime.IntValue - RoundToFloor(GetGameTime() - g_fAWPStartTime);
            if (timeLeft > 0)
            {
                char timeDisplay[64];
                Format(timeDisplay, sizeof(timeDisplay), "Time remaining: %d:%02d", timeLeft / 60, timeLeft % 60);
                menu.AddItem("", timeDisplay, ITEMDRAW_DISABLED);
            }
        }
    }
    else if (g_bFFAActive)
    {
        menu.SetTitle("Free-For-All Scoreboard\n ");
        
        // Add scores for each player (exclude bots)
        int playerCount = 0;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
            {
                char display[64];
                Format(display, sizeof(display), "%N: %d kills (%d/%d)", 
                    i, g_iFFAKills[i], g_iPlayerKills[i], g_iPlayerDeaths[i]);
                menu.AddItem("", display, ITEMDRAW_DISABLED);
                playerCount++;
            }
        }
        
        if (playerCount == 0)
        {
            menu.AddItem("", "No players in game", ITEMDRAW_DISABLED);
        }
        
        // Add time remaining if round timer is active
        if (g_hFFARoundTimer != null)
        {
            menu.AddItem("", " ", ITEMDRAW_SPACER);
            int timeLeft = g_cvFFARoundTime.IntValue - RoundToFloor(GetGameTime() - g_fFFAStartTime);
            if (timeLeft > 0)
            {
                char timeDisplay[64];
                Format(timeDisplay, sizeof(timeDisplay), "Time remaining: %d:%02d", timeLeft / 60, timeLeft % 60);
                menu.AddItem("", timeDisplay, ITEMDRAW_DISABLED);
            }
        }
    }
    else if (g_bPvPActive)
    {
        menu.SetTitle("Team Deathmatch Scoreboard\nRed %d - Blue %d\n ", 
            g_iTeamScores[TEAM_A], g_iTeamScores[TEAM_B]);
        
        // Red Team
        menu.AddItem("", "Red Team:", ITEMDRAW_DISABLED);
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i) && g_iPlayerTeam[i] == TEAM_A)
            {
                char display[64];
                Format(display, sizeof(display), "  %N (K/D: %d/%d)", 
                    i, g_iPlayerKills[i], g_iPlayerDeaths[i]);
                menu.AddItem("", display, ITEMDRAW_DISABLED);
            }
        }
        
        menu.AddItem("", " ", ITEMDRAW_SPACER);
        
        // Blue Team
        menu.AddItem("", "Blue Team:", ITEMDRAW_DISABLED);
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i) && g_iPlayerTeam[i] == TEAM_B)
            {
                char display[64];
                Format(display, sizeof(display), "  %N (K/D: %d/%d)", 
                    i, g_iPlayerKills[i], g_iPlayerDeaths[i]);
                menu.AddItem("", display, ITEMDRAW_DISABLED);
            }
        }
        
        // Add time remaining if round timer is active
        if (g_hRoundTimer != null)
        {
            menu.AddItem("", " ", ITEMDRAW_SPACER);
            int timeLeft = g_cvRoundTime.IntValue - RoundToFloor(GetGameTime() - g_fFFAStartTime);
            if (timeLeft > 0)
            {
                char timeDisplay[64];
                Format(timeDisplay, sizeof(timeDisplay), "Time remaining: %d:%02d", timeLeft / 60, timeLeft % 60);
                menu.AddItem("", timeDisplay, ITEMDRAW_DISABLED);
            }
        }
    }
    
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public Action Timer_UpdateMenu(Handle timer, any client)
{
    if (!IsValidClient(client) || (!g_bPvPActive && !g_bFFAActive && !g_bAWPActive))
    {
        g_hMenuUpdateTimer[client] = null;
        return Plugin_Stop;
    }
    
    // Only update if at least 1 second has passed since last update
    int currentTime = GetTime();
    if (currentTime > g_iLastMenuTime[client])
    {
        // Check if the client still has a menu open
        if (GetClientMenu(client) != MenuSource_None)
        {
            // Re-display the menu with updated information
            CancelClientMenu(client);
            DisplayUpdatedMenu(client);
        }
        else
        {
            // If menu is closed, stop the timer
            g_hMenuUpdateTimer[client] = null;
            return Plugin_Stop;
        }
    }
    
    return Plugin_Continue;
}

public Action Command_OneShotMode(int client, int args)
{
    if (g_bOneShotMode)
    {
        ReplyToCommand(client, "\x04[One Shot] \x01Mode is already active!");
        return Plugin_Handled;
    }

    if (g_bFFAActive || g_bAWPActive || g_bGunGameActive)
    {
        ReplyToCommand(client, "\x04[One Shot] \x01 Cannot start while another mode is active!");
        return Plugin_Handled;
    }

    // Check if PvP mode needs to be started first
    if (!g_bPvPActive)
    {
        if (!PrepareGeneratedTDMSpawns("One Shot", client))
        {
            return Plugin_Handled;
        }
        
        // Initialize PvP mode first
        InitializePvPMode();
        AssignTeams();
        StartTDMArenaTimer();
    }

    g_bOneShotMode = true;
    g_bMatchEnded = false;
    
    // Setup all players
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
        {
            SetupOneShotPlayer(i);
        }
    }

    // Start round timer
    if (g_hRoundTimer != null)
    {
        KillTimer(g_hRoundTimer);
    }
    g_hRoundTimer = CreateTimer(float(g_cvOneShotRoundTime.IntValue), Timer_RoundEnd);

    PrintToChatAll("\x04[One Shot] \x01 Mode activated! One hit kills only!");
    PrintToChatAll("\x04[One Shot] \x01 First team to reach %d kills wins!", g_cvOneShotScoreLimit.IntValue);

    // Start menu reminder timer
    if (g_hMenuReminderTimer != null)
    {
        KillTimer(g_hMenuReminderTimer);
    }
    g_hMenuReminderTimer = CreateTimer(GetRandomFloat(30.0, 60.0), Timer_MenuReminder);

    // Remove ground weapons and health items
    CleanupGroundWeapons();
    CreateTimer(5.0, Timer_CleanupGroundWeapons, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    
    return Plugin_Handled;
}

public Action Command_StopGunGame(int client, int args)
{
    if (!g_bGunGameActive)
    {
        ReplyToCommand(client, "[Gun Game] Gun Game mode is not active!");
        return Plugin_Handled;
    }
    
    // Clear all player levels and weapons
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
        {
            g_iGunGameLevel[i] = 0;
            g_iGunGameKills[i] = 0;
            
            if (IsPlayerAlive(i))
            {
                StripWeapons(i);
            }
        }
    }
    
    // End the game with manual termination message
    PrintToChatAll("\x04[Gun Game] \x01Game has been manually terminated by an admin.");
    EndGunGame(-1);
    ReplyToCommand(client, "[Gun Game] Gun Game mode has been stopped");
    
    return Plugin_Handled;
}

public Action Timer_EndGunGame(Handle timer)
{
    g_hGunGameRoundTimer = null;
    
    if (!g_bGunGameActive)
        return Plugin_Stop;
    
    PrintToChatAll("\x04[Gun Game] \x01 Time limit reached! No winner.");
    EndGunGame(-1);
    
    return Plugin_Stop;
}

void EndGunGame(int winner)
{
    // Find highest level player if no winner specified
    int highestLevel = 0;
    int highestLevelPlayer = -1;
    int highestKills = 0;

    if (winner == -1)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i) && g_iGunGameLevel[i] > highestLevel)
            {
                highestLevel = g_iGunGameLevel[i];
                highestLevelPlayer = i;
                highestKills = g_iPlayerKills[i];
            }
            else if (IsValidClient(i) && g_iGunGameLevel[i] == highestLevel && g_iPlayerKills[i] > highestKills)
            {
                highestLevelPlayer = i;
                highestKills = g_iPlayerKills[i];
            }
        }
        winner = highestLevelPlayer;
    }

    // Announce winner if there is one
    if (winner != -1 && IsValidClient(winner))
    {
        int winnerKills = g_iPlayerKills[winner];
        PrintToChatAll("\x04[Gun Game] \x01%N has won Gun Game with %d kills!", winner, winnerKills);

        // Display center message to all players for better visibility
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i))
            {
                PrintCenterText(i, "%N HAS WON GUN GAME WITH %d KILLS!", winner, winnerKills);

                // Play victory sound for the winner
                if (i == winner)
                {
                    EmitSoundToClient(i, SOUND_GUN_GAME_LEVEL_UP);
                    EmitSoundToClient(i, SOUND_GUN_GAME_LEVEL_UP);
                }
            }
        }
    }
    
    // Reset mode flags
    g_bGunGameActive = false;
    g_bFFAActive = false;
    
    // Kill all timers
    if (g_hGunGameRoundTimer != null)
    {
        KillTimer(g_hGunGameRoundTimer);
        g_hGunGameRoundTimer = null;
    }
    
    // Reset all players
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
        {
            // Clear any hint text
            PrintHintText(i, "Gun Game has ended!");
            
            // Reset stats
            g_iGunGameLevel[i] = 0;
            g_iGunGameKills[i] = 0;
            g_iPlayerKills[i] = 0;
            g_iPlayerDeaths[i] = 0;
            g_fLastGunGameWeaponMsgTime[i] = -99999.0;
            g_fLastGunGameFinalMsgTime[i] = -99999.0;
            
            // Reset color and health
            SetEntityRenderColor(i, 255, 255, 255, 255);
            SetEntityHealth(i, 100);
            
            // If they're alive, strip their weapons
            if (IsPlayerAlive(i))
            {
                StripWeapons(i);
            }
        }
    }
    
    // Reset ConVars
    if (g_hSpecialSpawnInterval != null) SetConVarInt(g_hSpecialSpawnInterval, 45);
    if (g_hCommonLimit != null) SetConVarInt(g_hCommonLimit, 30);
    if (g_hDirectorNoSpecials != null) SetConVarInt(g_hDirectorNoSpecials, 0);
    if (g_hDirectorNoMobs != null) SetConVarInt(g_hDirectorNoMobs, 0);
    if (g_hDirectorNoBosses != null) SetConVarInt(g_hDirectorNoBosses, 0);
    RemoveAllTeamGlows();
    for (int i = 1; i <= MaxClients; i++)
    {
        RemoveKillcamGlow(i);
        g_bInKillcam[i] = false;
        g_iKillcamTarget[i] = -1;
    }
    StopGlowRefreshTimerIfIdle();
    
    // Add a delay before allowing new mode to start
    CreateTimer(3.0, Timer_AllowNewMode);
    
    PrintToChatAll("\x04[Gun Game] \x01Game has ended! Type !startgungame to play again.");
}

// Teleport and equip players with their current Gun Game weapon
public Action Timer_TeleportAndEquipGunGame(Handle timer, any client)
{
    if (!IsValidClient(client) || !g_bGunGameActive)
        return Plugin_Stop;

    // Make sure player is alive
    if (!IsPlayerAlive(client))
    {
        L4D_RespawnPlayer(client);
        CreateTimer(0.2, Timer_TeleportAndEquipGunGame, client);
        return Plugin_Stop;
    }
        
    // Teleport to random FFA spawn
    TeleportToFFASpawn(client);
    
    // Give current Gun Game weapon
    GiveGunGameWeapon(client);
    
    // Spawn protection is now handled in TeleportToFFASpawn
    
    return Plugin_Stop;
}

// Give player their current Gun Game weapon based on level
void GiveGunGameWeapon(int client)
{
    if (!IsValidClient(client) || !g_bGunGameActive)
        return;
    
    // Clear existing weapons
    StripWeapons(client);
    
    // Force remove any infected arms that might be present
    RemoveInfectedArms(client);
    
    // Get current weapon level (capped at max level)
    int maxLevel = g_cvGunGameScoreLimit.IntValue;
    int level = g_iGunGameLevel[client];
    
    // Ensure level doesn't exceed maximum
    if (level >= maxLevel - 1)
    {
        level = maxLevel - 1;
        g_iGunGameLevel[client] = level;
    }
    
    // Give the weapon for their current level
    char weapon[32];
    strcopy(weapon, sizeof(weapon), g_sRandomizedGunGameWeapons[level]);
    
    // Handle melee weapon specially for final level
    if (level >= maxLevel - 1 || StrEqual(weapon, "weapon_melee"))
    {
        // IMPORTANT: Extra strip to ensure no other weapons are present
        StripWeapons(client);
        RemoveInfectedArms(client);
        
        // Additional check for infected/hunter weapons
        int itemIdx;
        while ((itemIdx = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")) != -1)
        {
            RemovePlayerItem(client, itemIdx);
            AcceptEntityInput(itemIdx, "Kill");
        }
        
        // Also check for specific infected weapons (hunter claws)
        char classname[64];
        for (int i = 0; i < 5; i++)
        {
            int weaponSlot = GetPlayerWeaponSlot(client, i);
            if (weaponSlot > 0)
            {
                GetEdictClassname(weaponSlot, classname, sizeof(classname));
                if (StrContains(classname, "weapon_hunter") != -1 || 
                    StrContains(classname, "claw") != -1 || 
                    StrContains(classname, "infected") != -1)
                {
                    RemovePlayerItem(client, weaponSlot);
                    AcceptEntityInput(weaponSlot, "Kill");
                }
            }
        }
        
        bool success = false;
        
        // Try special knife handling first - more reliable
        success = GiveKnifeForLastStandFinale(client);
        
        // Regular approach if special handling failed
        if (!success)
        {
            // Try multiple types in case some aren't available
            if (!success) success = GivePlayerRealMeleeWeapon(client, "katana");
            if (!success) success = GivePlayerRealMeleeWeapon(client, "machete");
            if (!success) success = GivePlayerRealMeleeWeapon(client, "crowbar");
            if (!success) success = GivePlayerRealMeleeWeapon(client, "baseball_bat");
            
            // Try the alternate melee weapon giving approach if direct creation failed
            if (!success) 
            {
                PrintToServer("[Gun Game] Direct melee weapon approach failed, trying alternate approach for client %d", client);
                success = GivePlayerMeleeWeapon(client, "katana"); 
                if (!success) success = GivePlayerMeleeWeapon(client, "machete");
                if (!success) success = GivePlayerMeleeWeapon(client, "crowbar");
                if (!success) success = GivePlayerMeleeWeapon(client, "baseball_bat");
            }
            
            // Fallback approach - legacy method
            if (!success)
            {
                PrintToServer("[Gun Game] All melee weapon approaches failed, trying final fallback for client %d", client);
                int melee = GivePlayerItem(client, "weapon_melee");
                if (melee > 0)
                {
                    EquipPlayerWeapon(client, melee);
                    SetEntPropString(melee, Prop_Data, "m_strMapSetScriptName", "katana");
                }
            }
        }
        
        // Always add extra safeguards
        CreateTimer(0.1, Timer_ForceKnifeForLastStand, client);
        CreateTimer(0.5, Timer_ForceKnifeForLastStand, client);
        
        // Create delayed strip timer to ensure only melee remains
        CreateTimer(0.2, Timer_StripNonMelee, client);
        
        float currentTime = GetGameTime();
        
        if (currentTime - g_fLastGunGameFinalMsgTime[client] > 3.0)
        {
            PrintToChat(client, "\x04[Gun Game] \x01 You have reached the final level: \x05KNIFE\x01! Get a kill to win!");
            PrintHintText(client, "FINAL LEVEL: KNIFE!\nGet a kill to win the game!");
            g_fLastGunGameFinalMsgTime[client] = currentTime;
            
            // Create reminder timers
            CreateTimer(3.0, Timer_RemindKnifeLevel, client);
            CreateTimer(15.0, Timer_RemindKnifeLevel, client, TIMER_REPEAT);
        }
    }
    else
    {
        // Give normal weapon with ammo
        int item = GivePlayerItem(client, weapon);
        if (item > 0)
        {
            EquipPlayerWeapon(client, item);
            SetEntProp(client, Prop_Send, "m_iAmmo", 999, _, GetEntProp(item, Prop_Send, "m_iPrimaryAmmoType"));
        }
        
        // Show current weapon and level info
        char weaponName[32];
        FormatGunGameWeaponDisplayName(weapon, weaponName, sizeof(weaponName));
        
        float currentTime = GetGameTime();
        
        // Only show messages if we haven't shown them recently (within 3 seconds)
        if (currentTime - g_fLastGunGameWeaponMsgTime[client] > 3.0)
        {
            // Only show the weapon message if this isn't right after leveling up
            // This prevents duplicate messages when leveling up
            bool isLevelUp = (g_iGunGameKills[client] == 0 && g_iPlayerKills[client] > 0);
            if (!isLevelUp)
            {
                PrintToChat(client, "\x04[Gun Game] \x01 Current weapon (Level %d/%d): \x05%s\x01. Need \x05%d\x01 kills to level up.",
                    level + 1, maxLevel, weaponName, KILLS_PER_LEVEL);
                    
                // Show next weapon if not on final level
                if (level < maxLevel - 2)
                {
                    char nextWeaponName[32];
                    FormatGunGameWeaponDisplayName(g_sRandomizedGunGameWeapons[level + 1], nextWeaponName, sizeof(nextWeaponName));
                    
                    PrintToChat(client, "\x04[Gun Game] \x01 Next weapon: \x05%s\x01", nextWeaponName);
                }
                else if (level == maxLevel - 2)
                {
                    PrintToChat(client, "\x04[Gun Game] \x01 Next weapon: \x05KNIFE\x01 (Final Level)");
                }
            }
            
            g_fLastGunGameWeaponMsgTime[client] = currentTime;
        }
    }
    
    // No health items or other weapons in Gun Game mode
}

// Remind player they're on knife level
public Action Timer_RemindKnifeLevel(Handle timer, any client)
{
    // Check if game conditions are still valid
    if (!IsValidClient(client) || !g_bGunGameActive || !IsPlayerAlive(client))
        return Plugin_Stop;
    
    // Check if player is still on knife level
    int maxLevel = g_cvGunGameScoreLimit.IntValue;
    if (g_iGunGameLevel[client] >= maxLevel - 1)
    {
        PrintHintText(client, "FINAL LEVEL: KNIFE!\nGet a kill to win the game!");
        PrintToChat(client, "\x04[Gun Game] \x01 You're on the \x05KNIFE\x01 level! Get a melee kill to win!");
        
        // Apply universal fix - always use special handling
        RemoveInfectedArms(client);
        CreateTimer(0.1, Timer_ForceKnifeForLastStand, client);
        CreateTimer(0.2, Timer_StripNonMelee, client);
        
        return Plugin_Continue;
    }
    
    return Plugin_Stop;
}

public Action Timer_GiveNextGunGameWeapon(Handle timer, any client)
{
    if (!IsValidClient(client) || !g_bGunGameActive || !IsPlayerAlive(client))
        return Plugin_Stop;
    
    GiveGunGameWeapon(client);
    return Plugin_Stop;
}

// Initialize PvP mode (shared function between direct start and command)
void InitializePvPMode()
{
    // Activate PvP mode
    g_bPvPActive = true;
    g_bMatchEnded = false;
    
    // Kill existing timers safely
    if (g_hMenuReminderTimer != null)
    {
        KillTimer(g_hMenuReminderTimer);
        g_hMenuReminderTimer = null;
    }
    
    SetControlledGlowRendering(true);
    DisableNonPvPGlows();
    ApplyPvPMapCleanup();
    
    // Disable infected spawning immediately
    if (g_hDirectorNoSpecials != null) g_hDirectorNoSpecials.IntValue = 1;
    if (g_hCommonLimit != null) g_hCommonLimit.IntValue = 0;
    if (g_hSpecialSpawnInterval != null) g_hSpecialSpawnInterval.IntValue = 999999;
    if (g_hDirectorNoMobs != null) g_hDirectorNoMobs.IntValue = 1;
    if (g_hDirectorNoBosses != null) g_hDirectorNoBosses.IntValue = 1;
    
    // Start infected check timer if not already running
    if (g_hInfectedCheckTimer == null)
    {
        g_hInfectedCheckTimer = CreateTimer(1.0, Timer_CheckInfected, _, TIMER_REPEAT);
    }
    
    // Reset scores
    g_iTeamScores[TEAM_A] = 0;
    g_iTeamScores[TEAM_B] = 0;
    
    // Reset all player K/D stats
    for (int i = 1; i <= MaxClients; i++)
    {
        g_iPlayerKills[i] = 0;
        g_iPlayerDeaths[i] = 0;
    }
    
    RefreshTeamGlows();
    EnsureGlowRefreshTimer();
}

public Action Command_StopOneShotMode(int client, int args)
{
    if (!g_bOneShotMode)
    {
        ReplyToCommand(client, "\x04[One Shot] \x01Mode is not active!");
        return Plugin_Handled;
    }

    // End One Shot mode
    EndOneShotMode();
    
    // Also end PvP mode if it's active
    if (g_bPvPActive)
    {
        // Remove saferoom bot if exists
        if (g_iSaferoomBot != -1 && IsClientInGame(g_iSaferoomBot))
        {
            KickClient(g_iSaferoomBot);
            g_iSaferoomBot = -1;
            g_bSaferoomBotActive = false;
        }
        
        if (g_hMenuReminderTimer != null)
        {
            KillTimer(g_hMenuReminderTimer);
            g_hMenuReminderTimer = null;
        }
        
        if (g_hSwitchReminderTimer != null)
        {
            KillTimer(g_hSwitchReminderTimer);
            g_hSwitchReminderTimer = null;
        }
        
        EndPvPMode();
        PrintToChatAll("\x04[PvP] \x01PvP mode has been deactivated!");
    }
    else
    {
    PrintToChatAll("\x04[One Shot] \x01Mode has been deactivated!");
    }
    
    return Plugin_Handled;
}

void EndOneShotMode()
{
    if (!g_bOneShotMode)
        return;

    g_bOneShotMode = false;
    
    // Kill round timer if it exists
    if (g_hRoundTimer != null)
    {
        KillTimer(g_hRoundTimer);
        g_hRoundTimer = null;
    }
    
    // Reset all players to normal health
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
        {
            SetEntityHealth(i, 100);
            SetEntProp(i, Prop_Send, "m_iMaxHealth", 100);
        }
    }
}

void SetupOneShotPlayer(int client)
{
    if (!IsValidClient(client))
        return;

    // Set health to 100
    SetEntityHealth(client, 100);
    SetEntProp(client, Prop_Send, "m_iMaxHealth", 100);
    SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
    
    // Give random loadout (use existing function if available)
    GiveRandomLoadout(client);
    
    // Enable spawn protection briefly
    g_bSpawnProtection[client] = true;
    SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
    SetEntityRenderColor(client, 0, 255, 0, 200);  // Green color with slight transparency
    CreateTimer(SPAWN_PROTECTION_TIME, Timer_RemoveSpawnProtection, client);
    
    // Announce loadout
    AnnounceLoadout(client);
}

public Action Command_StartGunGame(int client, int args)
{
    if (g_bGunGameActive)
    {
        ReplyToCommand(client, "\x04[Gun Game] \x01 Gun Game mode is already active!");
        return Plugin_Handled;
    }

    if (g_bPvPActive || g_bFFAActive || g_bAWPActive)
    {
        ReplyToCommand(client, "\x04[Gun Game] \x01 Cannot start while another mode is active!");
        return Plugin_Handled;
    }

    if (!PrepareGeneratedFFASpawns("Gun Game", client))
    {
        return Plugin_Handled;
    }

    // Activate Gun Game mode
    g_bGunGameActive = true;
    g_bFFAActive = true; // Use FFA handling for most functions
    g_bMatchEnded = false;
    SetControlledGlowRendering(true);
    SuppressClimbPluginGlow();
    DisableNonPvPGlows();
    ApplyPvPMapCleanup();
    EnsureGlowRefreshTimer();
    
    // Generate randomized weapon progression for this round
    ShuffleGunGameWeapons();
    
    // Reset the knife one-hit kill flag when starting (fix for issue with knife persisting between rounds)
    g_bKnifeOneHitKill = false;

    // Reset all player stats
    for (int i = 1; i <= MaxClients; i++)
    {
        g_iPlayerKills[i] = 0;
        g_iPlayerDeaths[i] = 0;
        g_iFFAKills[i] = 0;
        g_iGunGameLevel[i] = 0;
        g_iGunGameKills[i] = 0; // Important: Reset kills counter
        g_bKnifeLevelSetup[i] = false;
        g_fLastGunGameWeaponMsgTime[i] = -99999.0;
        g_fLastGunGameFinalMsgTime[i] = -99999.0;
    }
    
    // Remove all weapons from the ground
    CleanupGroundWeapons();
    
    // Create timer to periodically check for and remove any new weapons that spawn
    CreateTimer(5.0, Timer_CleanupGroundWeapons, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

    // Load warmup spawns if they exist
    LoadWarmupSpawns();
    
    // Only start warmup if enabled
    if (g_bWarmupEnabled)
    {
        g_bWarmupActive = true;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i) && !IsFakeClient(i))
            {
                SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
                TeleportToWarmupSpawn(i);
                GiveWarmupLoadout(i);
            }
        }
        CreateTimer(WARMUP_TIME, Timer_WarmupEnd);
        PrintToChatAll("\x04[Gun Game] \x01 Warmup phase: \x04%.0f\x01 seconds!", WARMUP_TIME);
    }
    else
    {
        g_bWarmupActive = false;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i) && !IsFakeClient(i))
            {
                SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
                TeleportToFFASpawn(i);
                
                // In Gun Game mode, give weapon based on level
                GiveGunGameWeapon(i);
            }
        }
        PrintToChatAll("\x04[Gun Game] \x01 Match is now live! First to complete all \x04%d\x01 weapon levels wins!", g_cvGunGameScoreLimit.IntValue);
    }

    g_fFFAStartTime = GetGameTime();

    // Start round timer
    if (g_hGunGameRoundTimer != null)
        KillTimer(g_hGunGameRoundTimer);
    g_hGunGameRoundTimer = CreateTimer(float(GetConVarInt(g_cvFFARoundTime)), Timer_EndGunGame);
    
    // Setup other game settings
    if (g_hGlowEnable != null)
        g_hGlowEnable.IntValue = 0;
        
    // Remove bots
    RemoveAllInfected();
    
    if (g_hInfectedCheckTimer == null)
        g_hInfectedCheckTimer = CreateTimer(1.0, Timer_CheckInfected, _, TIMER_REPEAT);
    
    // Start menu reminder timer
    if (g_hMenuReminderTimer != null)
        KillTimer(g_hMenuReminderTimer);
    g_hMenuReminderTimer = CreateTimer(GetRandomFloat(30.0, 60.0), Timer_MenuReminder);
    
    PrintToChatAll("\x04[Gun Game] \x01Gun Game mode has been started!");
    return Plugin_Handled;
}

stock void BalanceTeams()
{
    // Get active player count
    int activePlayers = 0;
    int playerList[MAXPLAYERS + 1];
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && !IsFakeClient(i))
        {
            playerList[activePlayers] = i;
            activePlayers++;
        }
    }
    
    // Shuffle the player list
    for (int i = 0; i < activePlayers; i++) 
    {
        int randomIndex = GetRandomInt(0, activePlayers - 1);
        int temp = playerList[i];
        playerList[i] = playerList[randomIndex];
        playerList[randomIndex] = temp;
    }
    
    // Reset team counts
    int teamCounts[MAX_TEAMS];
    teamCounts[TEAM_A] = 0;
    teamCounts[TEAM_B] = 0;
    
    // Assign players to teams
    for (int i = 0; i < activePlayers; i++)
    {
        int player = playerList[i];
        int assignedTeam;
        
        if (teamCounts[TEAM_A] <= teamCounts[TEAM_B])
        {
            assignedTeam = TEAM_A;
        }
        else
        {
            assignedTeam = TEAM_B;
        }
        
        // Store player's team
        g_iPlayerTeam[player] = assignedTeam;
        teamCounts[assignedTeam]++;
        
        // Give appropriate team color (handle this in the code)
        if (assignedTeam == TEAM_A)
        {
            SetEntityRenderColor(player, 0, 0, 255, 255);  // Blue team
        }
        else
        {
            SetEntityRenderColor(player, 255, 0, 0, 255);  // Red team
        }
        
        // Announce team assignment if player is alive
        if (IsPlayerAlive(player))
        {
            PrintToChat(player, "\x04[PvP] \x01You have been assigned to \x04%s \x01Team.", 
                assignedTeam == TEAM_A ? "Blue" : "Red");
        }
    }
    
    PrintToChatAll("\x04[PvP] \x01Teams have been balanced! Blue: %d players, Red: %d players", 
        teamCounts[TEAM_A], teamCounts[TEAM_B]);
}

// Block survivor voice commands
public Action Command_BlockVoice(int client, const char[] command, int args)
{
    // Block all voice commands when in any PvP mode
    if (g_bPvPActive || g_bFFAActive || g_bGunGameActive || g_bAWPActive || g_bOneShotMode)
    {
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

// Block death sounds
public Action Event_PlayerDeath_BlockSound(Event event, const char[] name, bool dontBroadcast)
{
    // Block death sounds in all PvP modes
    if (g_bPvPActive || g_bFFAActive || g_bGunGameActive || g_bAWPActive || g_bOneShotMode)
    {
        event.BroadcastDisabled = true;
        return Plugin_Changed;
    }
    
    return Plugin_Continue;
}

// Block all survivor voice sounds
public Action NormalSHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
    // Block all music files completely
    if (!IsPvPMusicEnabled() &&
        (StrContains(sample, "music", false) != -1 || 
        StrContains(sample, "/music/", false) != -1 ||
        StrContains(sample, "sound/music", false) != -1 ||
        StrContains(sample, "saferoom", false) != -1 ||      // Block saferoom music
        StrContains(sample, "safe_room", false) != -1 ||     // Block alternate naming
        StrContains(sample, "saferooom", false) != -1))      // Block possible misspellings
    {
        PrintToServer("[Sound Debug] Blocked music: %s", sample);
        return Plugin_Stop;
    }
    
    // Block leftfordeathhit.wav specifically
    if (StrContains(sample, "leftfordeathhit", false) != -1)
    {
        PrintToServer("[Sound Debug] Blocked kill sound: %s", sample);
        return Plugin_Stop;
    }
    
    // Block radio voice sounds in finale maps
    if (StrContains(sample, "radio", false) != -1 || StrContains(sample, "Radio", false) != -1)
    {
        char mapName[128];
        GetCurrentMap(mapName, sizeof(mapName));
        if (StrContains(mapName, "finale", false) != -1)
        {
            PrintToServer("[Sound Debug] Blocked radio sound in finale: %s", sample);
            return Plugin_Stop;
        }
    }
    
    // Block survivor voice sounds in all PvP modes
    if ((g_bPvPActive || g_bFFAActive || g_bGunGameActive || g_bAWPActive || g_bOneShotMode) && IsValidClient(entity))
    {
        // Block survivor voice lines
        if (StrContains(sample, "survivor", false) != -1 && 
            (StrContains(sample, "voice", false) != -1 || 
             StrContains(sample, "death", false) != -1 || 
             StrContains(sample, "pain", false) != -1))
        {
            return Plugin_Stop;
        }
    }
    
    return Plugin_Continue;
}

// Hook for music commands from the game
public Action UserMsg_MusicCmd(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if (!IsPvPMusicEnabled())
    {
        PrintToServer("[Music Debug] Blocked music command from game");
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

bool IsPvPMusicEnabled()
{
    return g_cvMusicEnabled == null || g_cvMusicEnabled.BoolValue;
}

float GetPvPMusicVolume()
{
    if (!IsPvPMusicEnabled())
        return 0.0;

    if (g_cvMusicVolume == null)
        return 1.0;

    return g_cvMusicVolume.FloatValue;
}

public void OnMusicSettingsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    ApplyPvPMusicSettings();
}

void ApplyPvPMusicSettings()
{
    float musicVolume = GetPvPMusicVolume();
    ConVar snd_musicvolume = FindConVar("snd_musicvolume");
    if (snd_musicvolume != null)
    {
        snd_musicvolume.SetFloat(musicVolume);
        PrintToServer("[Music Debug] Set snd_musicvolume to %.2f", musicVolume);
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        ApplyPvPMusicSettingsToClient(i);
    }
}

void ApplyPvPMusicSettingsToClient(int client)
{
    if (IsValidClient(client) && !IsFakeClient(client))
    {
        float musicVolume = GetPvPMusicVolume();
        ClientCommand(client, "snd_musicvolume %.2f", musicVolume);
        PrintToServer("[Music Debug] Set snd_musicvolume to %.2f for player %d", musicVolume, client);
    }
}

// Function to give a player a reliable melee weapon
bool GivePlayerMeleeWeapon(int client, const char[] meleeClass)
{
    // Use the correct syntax for giving melee weapons in L4D2
    char command[256];
    Format(command, sizeof(command), "give %s", meleeClass);
    
    // Execute the command to give the exact melee weapon
    return ExecuteClientCommand(client, command);
}

// Helper function to execute commands as a client
bool ExecuteClientCommand(int client, const char[] command)
{
    if (!IsValidClient(client))
        return false;
    
    int flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, command);
    SetCommandFlags(command, flags);
    
    PrintToServer("[Debug] Executed command '%s' for client %d", command, client);
    return true;
}

// Function to directly give a melee weapon without requiring sv_cheats
bool GivePlayerRealMeleeWeapon(int client, const char[] meleeType)
{
    // This approach uses direct entity creation which doesn't require sv_cheats
    int melee = CreateEntityByName("weapon_melee");
    if (melee <= 0)
        return false;
        
    char buffer[64];
    Format(buffer, sizeof(buffer), "l4d2_meleeweapon_%s", meleeType);
    DispatchKeyValue(melee, "melee_script_name", meleeType);
    
    DispatchSpawn(melee);
    
    // Force pickup of the weapon
    if (IsValidEntity(melee) && IsValidClient(client))
    {
        // Remove current secondary weapon if any
        int secondary = GetPlayerWeaponSlot(client, 1);
        if (secondary > 0)
        {
            RemovePlayerItem(client, secondary);
            RemoveEntity(secondary);
        }
        
        // Equip the melee weapon
        if (EquipPlayerWeapon(client, melee))
        {
            PrintToServer("[Debug] Successfully gave melee weapon '%s' to client %d", meleeType, client);
            return true;
        }
    }
    
    // If we got here, something went wrong
    if (IsValidEntity(melee))
    {
        RemoveEntity(melee);
    }
    
    return false;
}

// Add hook for Gun Game score limit changes
void OnGunGameScoreLimitChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    // This function is called whenever l4d2_gungame_scorelimit is changed
    int newLimit = StringToInt(newValue);
    PrintToServer("[Gun Game] Score limit changed: %s -> %s", oldValue, newValue);
    
    // If Gun Game is currently active, notify all players
    if (g_bGunGameActive)
    {
        PrintToChatAll("\x04[Gun Game] \x01Score limit changed: \x04%s\x01 -> \x04%s", oldValue, newValue);
        PrintToChatAll("\x04[Gun Game] \x01Game will now end after %d levels or time limit!", newLimit);
        
        // Update players who are at or above the new limit level to the final (knife) level
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i))
            {
                // If player's level is at or above the new limit, set them to the knife level
                if (g_iGunGameLevel[i] >= newLimit - 1)
                {
                    g_iGunGameLevel[i] = newLimit - 1;
                    
                    // Only update weapon if player is alive
                    if (IsPlayerAlive(i))
                    {
                        // Give them the knife weapon immediately
                        CreateTimer(0.5, Timer_GiveNextGunGameWeapon, i);
                    }
                }
                // If player's level is below the new limit but was previously at knife level
                // (this happens when increasing the limit), update their weapon
                else if (g_iGunGameLevel[i] < newLimit - 1 && StringToInt(oldValue) - 1 <= g_iGunGameLevel[i])
                {
                    // Only update weapon if player is alive
                    if (IsPlayerAlive(i))
                    {
                        // Give them the appropriate weapon for their current level
                        CreateTimer(0.5, Timer_GiveNextGunGameWeapon, i);
                    }
                }
            }
        }
    }
}

// Timer to allow a new mode to start after a delay
public Action Timer_AllowNewMode(Handle timer)
{
    // Nothing specific to do here, just allows time to pass
    // before starting another mode
    return Plugin_Stop;
}

// Timer to end Gun Game with a short delay after a knife kill
public Action Timer_DelayedEndGunGame(Handle timer, DataPack pack)
{
    pack.Reset();
    int winner = pack.ReadCell();
    
    // Check if Gun Game is still active before ending
    if (!g_bGunGameActive)
    {
        PrintToServer("[Gun Game] Attempted to end inactive Gun Game - aborting");
        return Plugin_Stop;
    }
    
    PrintToServer("[Gun Game] Delayed end called with winner: %N", winner);
    
    // Show winner message to all players
    PrintToChatAll("\x04[Gun Game] \x01%N won with a knife kill! Total kills: %d", winner, g_iPlayerKills[winner]);
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
        {
            PrintCenterText(i, "%N WON GUN GAME WITH A KNIFE KILL! TOTAL KILLS: %d", winner, g_iPlayerKills[winner]);
        }
    }
    
    // End the game with this player as winner
    EndGunGame(winner);
    
    return Plugin_Stop;
}

// Timer to make sure only melee weapons are present at knife level
public Action Timer_StripNonMelee(Handle timer, any client)
{
    if (!IsValidClient(client) || !g_bGunGameActive || !IsPlayerAlive(client))
        return Plugin_Stop;
    
    // Check if player is at knife level
    int maxLevel = g_cvGunGameScoreLimit.IntValue;
    if (g_iGunGameLevel[client] >= maxLevel - 1)
    {
        // Check if we've already set up this player for knife level in this life
        if (!g_bKnifeLevelSetup[client])
        {
            // Strip all weapons first
            StripWeapons(client);
            
            // Use our helper to remove infected arms
            RemoveInfectedArms(client);
            
            // Now give only a melee weapon
            bool success = false;
            
            // Try special knife handling first - more reliable
            success = GiveKnifeForLastStandFinale(client);
            
            // Regular approach if special handling failed
            if (!success)
            {
                // Try multiple types in case some aren't available
                if (!success) success = GivePlayerRealMeleeWeapon(client, "katana");
                if (!success) success = GivePlayerRealMeleeWeapon(client, "machete");
                if (!success) success = GivePlayerRealMeleeWeapon(client, "crowbar");
                if (!success) success = GivePlayerRealMeleeWeapon(client, "baseball_bat");
                
                // Try the alternate melee weapon giving approach if direct creation failed
                if (!success) 
                {
                    PrintToServer("[Gun Game] Direct melee weapon approach failed, trying alternate approach for client %d", client);
                    success = GivePlayerMeleeWeapon(client, "katana"); 
                    if (!success) success = GivePlayerMeleeWeapon(client, "machete");
                    if (!success) success = GivePlayerMeleeWeapon(client, "crowbar");
                    if (!success) success = GivePlayerMeleeWeapon(client, "baseball_bat");
                }
                
                // Fallback approach - legacy method
                if (!success)
                {
                    PrintToServer("[Gun Game] All melee weapon approaches failed, trying final fallback for client %d", client);
                    int melee = GivePlayerItem(client, "weapon_melee");
                    if (melee > 0)
                    {
                        EquipPlayerWeapon(client, melee);
                        SetEntPropString(melee, Prop_Data, "m_strMapSetScriptName", "katana");
                    }
                }
            }
            
            // Always add extra safeguards
            CreateTimer(0.1, Timer_ForceKnifeForLastStand, client);
            CreateTimer(0.5, Timer_ForceKnifeForLastStand, client);
            
            // Set player health to 100 at knife level
            SetEntityHealth(client, 100);
            SetEntProp(client, Prop_Data, "m_iMaxHealth", 100);
            g_bKnifeOneHitKill = false;
            
            // Mark that we've done the knife level setup for this player
            g_bKnifeLevelSetup[client] = true;
            
            // Print debug info
            PrintToServer("[Gun Game] Stripped non-melee weapons from player %N at knife level and set health to 100", client);
        }
    }
    else
    {
        // Not at knife level, reset the flag
        g_bKnifeLevelSetup[client] = false;
    }
    
    return Plugin_Stop;
}

// Add this function to handle players joining during Gun Game mode
public Action Timer_SetupGunGamePlayer(Handle timer, any client)
{
    if (!IsValidClient(client) || !g_bGunGameActive)
        return Plugin_Stop;
    
    PrintToServer("[Gun Game] Setting up Gun Game player %N", client);
    
    // Make sure player is alive
    if (!IsPlayerAlive(client))
    {
        L4D_RespawnPlayer(client);
        CreateTimer(0.2, Timer_SetupGunGamePlayer, client);
        return Plugin_Stop;
    }
    
    // Teleport to FFA spawn
    TeleportToFFASpawn(client);
    
    // Set correct weapon for their level
    GiveGunGameWeapon(client);
    
    // Enable spawn protection
    g_bSpawnProtection[client] = true;
    SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
    SetEntityRenderColor(client, 0, 255, 0, 200);  // Green color with slight transparency
    CreateTimer(SPAWN_PROTECTION_TIME, Timer_RemoveSpawnProtection, client);
    
    // Welcome message
    PrintToChat(client, "\x04[Gun Game] \x01Welcome to Gun Game! First to complete all weapons wins!");
    char currentWeaponName[32];
    FormatGunGameWeaponDisplayName(g_sRandomizedGunGameWeapons[g_iGunGameLevel[client]], currentWeaponName, sizeof(currentWeaponName));
    PrintToChat(client, "\x04[Gun Game] \x01 Current weapon: %s (Level %d/%d)",
        currentWeaponName,
        g_iGunGameLevel[client] + 1,
        g_cvGunGameScoreLimit.IntValue);
    
    return Plugin_Stop;
}

void CleanupGroundWeapons()
{
    char prefix[32];
    
    // Set prefix based on active mode
    if (g_bGunGameActive)
    {
        strcopy(prefix, sizeof(prefix), "Gun Game");
        
    }
    else if (g_bFFAActive)
        strcopy(prefix, sizeof(prefix), "FFA");
    else if (g_bPvPActive)
        strcopy(prefix, sizeof(prefix), "TDM");
    else if (g_bOneShotMode)
        strcopy(prefix, sizeof(prefix), "OneShot");
    else if (g_bAWPActive)
        strcopy(prefix, sizeof(prefix), "AWP");
    else
        strcopy(prefix, sizeof(prefix), "PvP");

    // Define weapon classes to remove
    static const char weaponClasses[][] = {
        // Spawn points (always remove these)
        "weapon_spawn",
        "weapon_pistol_spawn",
        "weapon_pistol_magnum_spawn",
        "weapon_melee_spawn",
        "weapon_first_aid_kit_spawn",
        "weapon_defibrillator_spawn",
        "weapon_pain_pills_spawn",
        "weapon_adrenaline_spawn",
        "weapon_molotov_spawn",
        "weapon_pipe_bomb_spawn",
        "weapon_vomitjar_spawn",
        
        // Ground weapons to check
        "weapon_smg",
        "weapon_smg_mp5",
        "weapon_smg_silenced",
        "weapon_pumpshotgun",
        "weapon_shotgun_chrome",
        "weapon_rifle",
        "weapon_rifle_desert",
        "weapon_rifle_ak47",
        "weapon_rifle_sg552",
        "weapon_autoshotgun",
        "weapon_shotgun_spas",
        "weapon_hunting_rifle",
        "weapon_sniper_military",
        "weapon_sniper_awp",
        "weapon_sniper_scout",
        "weapon_rifle_m60",
        "weapon_grenade_launcher",
        "weapon_pistol",
        "weapon_pistol_magnum",
        "weapon_melee",
        "weapon_first_aid_kit",
        "weapon_pain_pills",
        "weapon_adrenaline",
        "weapon_defibrillator",
        "weapon_molotov",
        "weapon_pipe_bomb",
        "weapon_vomitjar",
        "weapon_gascan",
        "weapon_upgradepack_explosive",
        "weapon_upgradepack_incendiary"
    };

    int entity;
    char classname[64];

    // First pass: Remove all weapon spawns
    for (int i = 0; i < sizeof(weaponClasses); i++)
    {
        // Skip if not a spawn point
        if (StrContains(weaponClasses[i], "_spawn") == -1)
            continue;

        entity = -1;
        while ((entity = FindEntityByClassname(entity, weaponClasses[i])) != -1)
        {
            if (IsValidEntity(entity))
            {
                RemoveEntity(entity);
                PrintToServer("[%s] Removed spawn point: %s", prefix, weaponClasses[i]);
            }
        }
    }

    // Second pass: Remove ground weapons only if they have no owner
    for (int i = 0; i < sizeof(weaponClasses); i++)
    {
        // Skip spawn points in this pass
        if (StrContains(weaponClasses[i], "_spawn") != -1)
            continue;

        entity = -1;
        while ((entity = FindEntityByClassname(entity, weaponClasses[i])) != -1)
        {
            if (!IsValidEntity(entity))
                continue;

            // Check if the weapon has an owner
            int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
            
            // Only remove if it's on the ground (no owner)
            if (owner == -1)
            {
                GetEntityClassname(entity, classname, sizeof(classname));
                RemoveEntity(entity);
                PrintToServer("[%s] Removed ground weapon: %s", prefix, classname);
            }
        }
    }
}

public Action Timer_CleanupGroundWeapons(Handle timer)
{
    if (g_bPvPActive || g_bFFAActive || g_bOneShotMode || g_bAWPActive || g_bGunGameActive)
    {
        CleanupGroundWeapons();
    }
    return Plugin_Continue;
}

bool IsClientHost(int client)
{
    // In a listen server, client index 1 is always the host
    return (client == 1 && IsClientInGame(client) && !IsFakeClient(client));
}

int GetHostClient()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && IsClientHost(i))
        {
            return i;
        }
    }
    return -1;
}

public Action Command_KillSelf(int client, int args)
{
    if (!IsClientInGame(client))
        return Plugin_Handled;
    
    if (!IsPlayerAlive(client))
    {
        PrintToChat(client, "\x04[PvP] \x01You must be alive to use this command!");
        return Plugin_Handled;
    }

    // If the client is the host, kill them directly without approval
    if (IsClientHost(client))
    {
        g_bSelfKilled[client] = true;
        ForcePlayerSuicide(client);
        return Plugin_Handled;
    }

    // Check if there's already a pending kill request
    if (g_iKillRequestClient != -1)
    {
        PrintToChat(client, "\x04[PvP] \x01There is already a pending kill request. Please wait.");
        return Plugin_Handled;
    }

    g_iKillRequestClient = client;
    g_bKillRequestPending[client] = true;

    // Get the host client
    int hostClient = GetHostClient();
    
    if (hostClient != -1)
    {
        // Notify only the host
        PrintToChat(hostClient, "\x04[PvP] \x03%N\x01 has requested to kill themselves. Type \x04!yes\x01 to approve.", client);
    }

    PrintToChat(client, "\x04[PvP] \x01Your kill request has been sent to the host for approval.");

    // Create a timer to clear the request if not approved within 30 seconds
    if (g_hKillRequestTimer != null)
        KillTimer(g_hKillRequestTimer);
    
    g_hKillRequestTimer = CreateTimer(30.0, Timer_KillRequestTimeout);

    return Plugin_Handled;
}

public Action Command_ApproveKill(int client, int args)
{
    if (!IsClientInGame(client))
        return Plugin_Handled;

    // Check if the command user is the host
    if (!IsClientHost(client))
    {
        PrintToChat(client, "\x04[PvP] \x01Only the host can approve kill requests!");
        return Plugin_Handled;
    }

    // Check if there's a pending kill request
    if (g_iKillRequestClient == -1 || !g_bKillRequestPending[g_iKillRequestClient])
    {
        PrintToChat(client, "\x04[PvP] \x01There are no pending kill requests.");
        return Plugin_Handled;
    }

    int target = g_iKillRequestClient;

    // Check if the target is still valid and alive
    if (!IsClientInGame(target) || !IsPlayerAlive(target))
    {
        PrintToChat(client, "\x04[PvP] \x01The player who requested to kill themselves is no longer valid.");
        ClearKillRequest();
        return Plugin_Handled;
    }

    // Execute the kill
    g_bSelfKilled[target] = true;
    ForcePlayerSuicide(target);
    PrintToChatAll("\x04[PvP] \x03%N\x01's kill request was approved by \x03%N\x01.", target, client);

    // Clear the request
    ClearKillRequest();

    return Plugin_Handled;
}

public Action Timer_KillRequestTimeout(Handle timer)
{
    if (g_iKillRequestClient != -1)
    {
        if (IsClientInGame(g_iKillRequestClient))
        {
            PrintToChat(g_iKillRequestClient, "\x04[PvP] \x01Your kill request has timed out.");
        }
        ClearKillRequest();
    }
    g_hKillRequestTimer = null;
    return Plugin_Stop;
}

void ClearKillRequest()
{
    if (g_iKillRequestClient != -1)
    {
        g_bKillRequestPending[g_iKillRequestClient] = false;
    }
    g_iKillRequestClient = -1;
    
    if (g_hKillRequestTimer != null)
    {
        KillTimer(g_hKillRequestTimer);
        g_hKillRequestTimer = null;
    }
}

public bool ShouldCountKill(int victim, int attacker)
{
    // Invalid clients should not count
    if (!IsValidClient(victim) || !IsValidClient(attacker))
        return false;
        
    // Self-kills don't count
    if (victim == attacker)
        return false;
        
    // Don't count kills during warmup or after match ended
    if (g_bWarmupActive || g_bMatchEnded)
        return false;
        
    // Check if this was a self-kill via command (using the flag set in Command_KillSelf)
    if (g_bSelfKilled[victim])
        return false;
    
    // Only count player vs player kills (no bots, no infected, no world)
    if (IsFakeClient(attacker) || IsFakeClient(victim))
        return false;
    if (GetClientTeam(victim) != TEAM_SURVIVOR || GetClientTeam(attacker) != TEAM_SURVIVOR)
        return false;
    
    // Some death events do not preserve the tracked weapon; keep the kill valid.
    if (g_sLastWeapon[victim][0] == '\0')
        strcopy(g_sLastWeapon[victim], sizeof(g_sLastWeapon[]), "unknown");
    
    // All checks passed, this kill should count
    return true;
}

// Health regeneration timer
public Action Timer_RegenerateHealth(Handle timer, any client)
{
    // Clear the timer handle since this timer is done
    g_hRegenTimer[client] = null;

    // Make sure client is still valid and in game
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Stop;

    // Get current health
    int currentHealth = GetClientHealth(client);
    
    // Don't regenerate if already at max health
    if (currentHealth >= MAX_HEALTH)
        return Plugin_Stop;

    // Check if enough time has passed since last damage
    float timeSinceLastDamage = GetGameTime() - g_fLastDamageTime[client];
    
    // If we haven't waited long enough, set up the initial delay timer
    if (timeSinceLastDamage < REGEN_DELAY)
    {
        g_hRegenTimer[client] = CreateTimer(REGEN_DELAY - timeSinceLastDamage, Timer_RegenerateHealth, client);
        return Plugin_Stop;
    }

    // Calculate new health
    int newHealth = currentHealth + REGEN_AMOUNT;
    if (newHealth > MAX_HEALTH)
        newHealth = MAX_HEALTH;

    // Apply regeneration
    SetEntityHealth(client, newHealth);

    // Always continue regeneration if not at full health
    if (newHealth < MAX_HEALTH)
    {
        g_hRegenTimer[client] = CreateTimer(REGEN_INTERVAL, Timer_RegenerateHealth, client);
    }

    return Plugin_Stop;
}

public Action Timer_RemoveHealthItems(Handle timer, any client)
{
    if (IsValidClient(client) && IsPlayerAlive(client))
    {
        int item = GetPlayerWeaponSlot(client, 4);  // Slot 4 is for pills/medkits
        if (item != -1)
        {
            RemovePlayerItem(client, item);
            AcceptEntityInput(item, "Kill");
            PrintToServer("[PvP] Removed health item from player %N", client);
        }
    }
    return Plugin_Stop;
}
void RemoveHealthItems(int client)
{
    if (!IsValidClient(client))
        return;

    // Remove all items from slots 3, 4, and 5 (pills, medkits, adrenaline, etc.)
    for (int slot = 3; slot <= 5; slot++)
    {
        int item = GetPlayerWeaponSlot(client, slot);
        while (item != -1)
        {
            RemovePlayerItem(client, item);
            AcceptEntityInput(item, "Kill");
            PrintToServer("[PvP] Removed health item from slot %d for player %N", slot, client);
            item = GetPlayerWeaponSlot(client, slot);
        }
    }
    
    // Additional check for any remaining health items
    int item = -1;
    while ((item = FindEntityByClassname(item, "weapon_*")) != -1)
    {
        if (!IsValidEntity(item))
            continue;
            
        char classname[64];
        GetEntityClassname(item, classname, sizeof(classname));
        
        if (StrContains(classname, "first_aid", false) != -1 ||
            StrContains(classname, "pills", false) != -1 ||
            StrContains(classname, "adrenaline", false) != -1 ||
            StrContains(classname, "defibrillator", false) != -1)
        {
            int owner = GetEntPropEnt(item, Prop_Data, "m_hOwnerEntity");
            if (owner == client)
            {
                RemovePlayerItem(client, item);
                AcceptEntityInput(item, "Kill");
                PrintToServer("[PvP] Removed additional health item %s from player %N", classname, client);
            }
        }
    }
}

// Function to announce loadout to players including the host
public Action Timer_ForceAnnounceLoadout(Handle timer, any client)
{
    if (!IsValidClient(client))
        return Plugin_Stop;
        
    // Get the client's current weapons
    AnnounceLoadout(client);
    return Plugin_Stop;
}

public Action Timer_SetupPvPPlayer(Handle timer, any client)
{
    if (!IsValidClient(client) || !g_bPvPActive || g_bIsJoining[client])
        return Plugin_Stop;
    
    g_bIsJoining[client] = true;
    
    // Force respawn first
    ChangeClientTeam(client, TEAM_SURVIVOR);
    L4D_RespawnPlayer(client);
    
    // Wait for respawn to complete, then assign team
    CreateTimer(0.5, Timer_CompleteTeamSetup, client);
    SchedulePvPJoinSpawnVerify(client, 1.5, 0);
    
    return Plugin_Stop;
}

void SchedulePvPJoinSpawnVerify(int client, float delay, int attempt)
{
    if (!IsValidClient(client) || !g_bPvPActive)
        return;

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteCell(attempt);
    CreateTimer(delay, Timer_VerifyPvPJoinSpawn, pack, TIMER_DATA_HNDL_CLOSE | TIMER_FLAG_NO_MAPCHANGE);
}

bool EnsurePvPJoinSpawned(int client)
{
    if (!IsValidClient(client) || !g_bPvPActive)
        return true;

    bool needsSetup = false;
    if (GetClientTeam(client) != TEAM_SURVIVOR)
    {
        ChangeClientTeam(client, TEAM_SURVIVOR);
        needsSetup = true;
    }

    if (!IsPlayerAlive(client))
    {
        L4D_RespawnPlayer_Custom(client);
        L4D_RespawnPlayer(client);
        needsSetup = true;
    }

    if (!IsPlayerAlive(client))
        return false;

    int team = g_iPlayerTeam[client];
    if (team < 0 || team >= MAX_TEAMS)
    {
        team = GetTeamWithFewerPlayers();
        g_iPlayerTeam[client] = team;
        needsSetup = true;

        PrintToChatAll("\x04[TDM] \x01%N joined the \x04%s\x01 team!", client, team == TEAM_A ? "RED" : "BLUE");
    }

    if (needsSetup)
    {
        TeleportToSpawn(client, team);
        GiveRandomLoadout(client);
        CreateTimer(0.7, Timer_ForceAnnounceLoadout, client);

        g_bSpawnProtection[client] = true;
        SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
        SetEntityRenderColor(client, 0, 255, 0, 200);
        CreateTimer(SPAWN_PROTECTION_TIME, Timer_RemoveSpawnProtection, client);
    }

    g_bIsJoining[client] = false;
    RefreshTeamGlows();
    return true;
}

public Action Timer_VerifyPvPJoinSpawn(Handle timer, any data)
{
    DataPack pack = view_as<DataPack>(data);
    pack.Reset();
    int client = GetClientOfUserId(pack.ReadCell());
    int attempt = pack.ReadCell();

    if (!IsValidClient(client) || !g_bPvPActive)
        return Plugin_Stop;

    if (EnsurePvPJoinSpawned(client))
        return Plugin_Stop;

    if (attempt < 5)
    {
        g_bIsJoining[client] = false;
        SchedulePvPJoinSpawnVerify(client, 1.0, attempt + 1);
    }
    else
    {
        PrintToServer("[TDM Debug] Auto-spawn retry failed for %N after %d attempts", client, attempt + 1);
    }

    return Plugin_Stop;
}

public Action Timer_CompleteTeamSetup(Handle timer, any client)
{
    if (!IsValidClient(client) || !g_bPvPActive)
        return Plugin_Stop;
    
    // Ensure player is alive
    if (!IsPlayerAlive(client))
    {
        L4D_RespawnPlayer(client);
        CreateTimer(0.3, Timer_CompleteTeamSetup, client);
        return Plugin_Stop;
    }
    
    // Assign team
    int team = GetTeamWithFewerPlayers();
    g_iPlayerTeam[client] = team;
    
    // Set color and announce
    if (team == TEAM_A)
    {
        SetEntityRenderColor(client, 255, 0, 0, 255);
        PrintToChatAll("\x04[TDM] \x01%N joined the \x04RED\x01 team!", client);
    }
    else
    {
        SetEntityRenderColor(client, 0, 0, 255, 255);
        PrintToChatAll("\x04[TDM] \x01%N joined the \x04BLUE\x01 team!", client);
    }
    
    // Final setup
    TeleportToSpawn(client, team);
    GiveRandomLoadout(client);
    CreateTimer(0.7, Timer_ForceAnnounceLoadout, client);
    
    // Spawn protection
    g_bSpawnProtection[client] = true;
    SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
    SetEntityRenderColor(client, 0, 255, 0, 200);
    CreateTimer(SPAWN_PROTECTION_TIME, Timer_RemoveSpawnProtection, client);
    
    g_bIsJoining[client] = false;
    RefreshTeamGlows();
    return Plugin_Stop;
}
void RemoveInvisibleWalls()
{
    int maxEnt = GetMaxEntities();
    char cls[64];
    for (int ent = MaxClients + 1; ent < maxEnt; ent++)
    {
        if (!IsValidEntity(ent))
            continue;
        GetEntityClassname(ent, cls, sizeof(cls));
        if (StrEqual(cls, "env_player_blocker", false) ||
            StrEqual(cls, "env_physics_blocker", false) ||
            StrEqual(cls, "func_playerinfected_clip", false) ||
            StrEqual(cls, "func_playerghostinfected_clip", false) ||
            StrEqual(cls, "func_block_charge", false) ||
            StrEqual(cls, "func_nav_blocker", false) ||
            StrEqual(cls, "func_clip_vphysics", false) ||
            StrEqual(cls, "func_clip", false))
        {
            AcceptEntityInput(ent, "Disable");
            AcceptEntityInput(ent, "Kill");
            if (IsValidEntity(ent))
                RemoveEntity(ent);
        }
    }
}

void ApplyPvPMapCleanup()
{
    RemoveInvisibleWalls();
    RemoveFinaleEntities();
    CreateTimer(0.2, Timer_ApplyPvPMapCleanup, _, TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(1.0, Timer_ApplyPvPMapCleanup, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ApplyPvPMapCleanup(Handle timer, any data)
{
    if (IsControlledGlowModeActive())
    {
        RemoveInvisibleWalls();
        RemoveFinaleEntities();
    }
    return Plugin_Stop;
}

void RemoveFinaleEntities()
{
    int maxEnt = GetMaxEntities();
    char cls[64];
    char name[128];
    char model[128];
    for (int ent = MaxClients + 1; ent < maxEnt; ent++)
    {
        if (!IsValidEntity(ent))
            continue;
        GetEntityClassname(ent, cls, sizeof(cls));
        GetEntityStringPropSafe(ent, "m_iName", name, sizeof(name));
        GetEntityStringPropSafe(ent, "m_ModelName", model, sizeof(model));
        if (ShouldRemoveFinaleEntity(cls, name, model))
        {
            AcceptEntityInput(ent, "Disable");
            AcceptEntityInput(ent, "Kill");
            if (IsValidEntity(ent))
                RemoveEntity(ent);
        }
    }
}

void GetEntityStringPropSafe(int entity, const char[] prop, char[] buffer, int maxlen)
{
    buffer[0] = '\0';

    if (HasEntProp(entity, Prop_Data, prop))
    {
        GetEntPropString(entity, Prop_Data, prop, buffer, maxlen);
    }
    else if (HasEntProp(entity, Prop_Send, prop))
    {
        GetEntPropString(entity, Prop_Send, prop, buffer, maxlen);
    }
}

bool ShouldRemoveFinaleEntity(const char[] classname, const char[] targetName, const char[] model)
{
    if (StrEqual(classname, "trigger_finale", false))
        return true;

    bool finaleName = (StrContains(targetName, "finale", false) != -1) ||
        (StrContains(targetName, "radio", false) != -1) ||
        (StrContains(targetName, "rescue", false) != -1);
    bool finaleModel = (StrContains(model, "radio", false) != -1);

    if (!finaleName && !finaleModel)
        return false;

    return StrEqual(classname, "point_script_use_target", false) ||
        StrEqual(classname, "point_prop_use_target", false) ||
        StrEqual(classname, "logic_relay", false) ||
        StrEqual(classname, "trigger_multiple", false) ||
        StrEqual(classname, "func_button", false) ||
        StrEqual(classname, "func_button_timed", false) ||
        StrEqual(classname, "ambient_generic", false) ||
        StrEqual(classname, "prop_dynamic", false) ||
        StrEqual(classname, "prop_dynamic_override", false) ||
        StrEqual(classname, "prop_physics", false) ||
        StrEqual(classname, "prop_physics_multiplayer", false);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity <= MaxClients)
        return;

    if (IsControlledGlowModeActive())
    {
        CreateTimer(0.1, Timer_DisableEntityGlow, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
    }

    if (StrEqual(classname, "env_player_blocker", false) ||
        StrEqual(classname, "env_physics_blocker", false) ||
        StrEqual(classname, "func_playerinfected_clip", false) ||
        StrEqual(classname, "func_playerghostinfected_clip", false) ||
        StrEqual(classname, "func_block_charge", false) ||
        StrEqual(classname, "func_nav_blocker", false) ||
        StrEqual(classname, "func_clip_vphysics", false) ||
        StrEqual(classname, "func_clip", false) ||
        StrEqual(classname, "trigger_finale", false))
    {
        CreateTimer(0.1, Timer_KillEntitySafe, entity);
    }

    if (IsControlledGlowModeActive() && IsPotentialFinaleEntityClass(classname))
    {
        CreateTimer(0.1, Timer_RemoveFinaleEntityIfNeeded, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
    }
}

bool IsPotentialFinaleEntityClass(const char[] classname)
{
    return StrEqual(classname, "trigger_finale", false) ||
        StrEqual(classname, "point_script_use_target", false) ||
        StrEqual(classname, "point_prop_use_target", false) ||
        StrEqual(classname, "logic_relay", false) ||
        StrEqual(classname, "trigger_multiple", false) ||
        StrEqual(classname, "func_button", false) ||
        StrEqual(classname, "func_button_timed", false) ||
        StrEqual(classname, "ambient_generic", false) ||
        StrEqual(classname, "prop_dynamic", false) ||
        StrEqual(classname, "prop_dynamic_override", false) ||
        StrEqual(classname, "prop_physics", false) ||
        StrEqual(classname, "prop_physics_multiplayer", false);
}

public Action Timer_RemoveFinaleEntityIfNeeded(Handle timer, any entityRef)
{
    int entity = EntRefToEntIndex(entityRef);
    if (entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity))
        return Plugin_Stop;

    char classname[64];
    char name[128];
    char model[128];
    GetEntityClassname(entity, classname, sizeof(classname));
    GetEntityStringPropSafe(entity, "m_iName", name, sizeof(name));
    GetEntityStringPropSafe(entity, "m_ModelName", model, sizeof(model));

    if (ShouldRemoveFinaleEntity(classname, name, model))
    {
        AcceptEntityInput(entity, "Disable");
        AcceptEntityInput(entity, "Kill");
        if (IsValidEntity(entity))
            RemoveEntity(entity);
    }

    return Plugin_Stop;
}

public Action Timer_KillEntitySafe(Handle timer, any entity)
{
    if (!IsValidEntity(entity))
        return Plugin_Stop;
    AcceptEntityInput(entity, "Disable");
    AcceptEntityInput(entity, "Kill");
    if (IsValidEntity(entity))
        RemoveEntity(entity);
    return Plugin_Stop;
}
