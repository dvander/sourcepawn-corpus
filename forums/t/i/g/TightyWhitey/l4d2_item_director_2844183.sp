#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "1.2"
#define LOG_FILE "logs/item_director_debug.log"

ConVar g_cvEnable;
ConVar g_cvAllowedModes;
ConVar g_hMPGameMode;
ConVar g_cvReplaceRadius;
ConVar g_cvWeaponEnable;
ConVar g_cvWeaponRadius;
ConVar g_cvWeaponRadiusIgnore;
ConVar g_cvMedkitEnable;
ConVar g_cvMedkitRadius;
ConVar g_cvMedkitRadiusIgnore;
ConVar g_cvCabinetRadius;
ConVar g_cvMedkitNearCabinet;
ConVar g_cvReplaceItem;
ConVar g_cvDebug;
ConVar g_cvVisibleSpawn;
ConVar g_cvFailCooldown;
ConVar g_cvCleanupEnable;
ConVar g_cvCleanupRadius;
ConVar g_cvCleanupDelay;
ConVar g_cvCleanupRespawnEnable;
ConVar g_cvRequireLeftSafeArea;
ConVar g_cvConditionEnable;
ConVar g_cvConditionFlowMin;
ConVar g_cvConditionFlowMax;
ConVar g_cvConditionMaxMeds;
ConVar g_cvBypassCooldown;
ConVar g_cvConditionHud;
ConVar g_cvConditionDebug;
ConVar g_cvConditionInitialNearby;
ConVar g_cvConditionInitialNearbyCooldown;
ConVar g_cvHealthDebug;
ConVar g_cvTempHealthRadius;
ConVar g_cvDefibEnable;
ConVar g_cvDefibDebug;
ConVar g_cvDefibHud;
ConVar g_cvDefibRadius;
ConVar g_cvDefibRadiusIgnore;
ConVar g_cvDefibFlowMin;
ConVar g_cvDefibFlowMax;
ConVar g_cvDefibNearCabinet;
ConVar g_cvSpawnImmediate;
ConVar g_cvSaferoomIgnoreRadius;
ConVar g_cvSpawnPointMode;
ConVar g_cvWeaponNoPrimarySpawn;
ConVar g_cvConditionInitialClear;
ConVar g_cvWeaponProposeInitialClear;
ConVar g_cvConditionInitialClearFailed;
ConVar g_cvWeaponProposeInitialClearFailed;
ConVar g_cvBondingThreshold;
ConVar g_cvBondingMissCooldown;
ConVar g_cvFinaleIgnoreRadius;

// Weapon cvars
ConVar g_cvWeaponHud;
ConVar g_cvWeaponDebug;
ConVar g_cvWeaponAmmoPercent;
ConVar g_cvWeaponNearCabinet;

// Ammo cvars
ConVar g_cvAmmoEnable;
ConVar g_cvAmmoRadius;
ConVar g_cvAmmoRadiusIgnore;
ConVar g_cvAmmoSpawnMode;
ConVar g_cvAmmoThreshold;
ConVar g_cvAmmoHud;
ConVar g_cvAmmoDebug;

// Temp health spawn cvars
ConVar g_cvTempHealthSpawnEnable;
ConVar g_cvTempHealthSpawnFlowMin;
ConVar g_cvTempHealthSpawnFlowMax;
ConVar g_cvTempHealthSpawnIgnoreRadius;
ConVar g_cvTempHealthSpawnDebug;
ConVar g_cvTempHealthSpawnHud;

// Propose cvars
ConVar g_cvWeaponPropose;
ConVar g_cvWeaponProposeHud;
ConVar g_cvWeaponProposeInitialMin;
ConVar g_cvWeaponProposeInitialMax;
ConVar g_cvWeaponProposeMin;
ConVar g_cvWeaponProposeMax;
ConVar g_cvWeaponProposeDebug;
ConVar g_cvLaserSightEnable;
ConVar g_cvLaserSightRadius;
ConVar g_cvLaserSightRadiusIgnore;
ConVar g_cvLaserSightChanceFlowRoll;   
ConVar g_cvLaserSightChance;          
ConVar g_cvLaserSightDebug;
ConVar g_cvLaserSightHud;
ConVar g_cvBondingEnable;
ConVar g_cvBondingInterval;
ConVar g_cvBondingFraction;
ConVar g_cvBondingMissCooldownClear;
ConVar g_cvBondingDecayEnable;
ConVar g_cvBondingDecayInterval;
ConVar g_cvBondingDecayThreshold;
ConVar g_cvBondingMissCooldownClearFailed;
ConVar g_cvUpgradePackEnable;
ConVar g_cvUpgradePackRadiusIgnore;
ConVar g_cvUpgradePackChance;
ConVar g_cvUpgradePackDebug;
ConVar g_cvUpgradePackHud;
ConVar g_cvUpgradePackRadius;

ConVar g_cvBondingDebug;
ConVar g_cvBondingHud;

bool g_bModeAllowed = true;
bool g_bDefibNearCabinet = false;
bool g_bEnabled = true;
float g_fReplaceRadius = 1.0;
bool g_bWeaponEnable = true;
float g_fWeaponRadius = 1000.0;
float g_fWeaponRadiusIgnore = 700.0;
bool g_bMedkitEnable = true;
float g_fMedkitRadius = 1000.0;
float g_fMedkitRadiusIgnore = 700.0;
float g_fCabinetRadius = 200.0;
float g_fSaferoomIgnoreRadius = 0.0;
bool g_bMedkitNearCabinet = false;
bool g_bReplaceItem = true;
bool g_bDebug = false;
bool g_bSpawnIfVisible = false;
float g_fFailCooldown = 900.0;
bool g_bCleanupEnable = true;
float g_fCleanupRadius = 4500.0;
float g_fCleanupDelay = 900.0;
bool g_bCleanupRespawnEnable = true;
bool g_bRequireLeftSafeArea = true;
bool g_bLeftSafeArea = false;

bool g_bConditionEnable = true;
float g_fConditionFlowMin = 3000.0;
float g_fConditionFlowMax = 4500.0;
int g_iConditionMaxMeds = 2;
float g_fBypassCooldown = 900.0;
bool g_bConditionHud = true;
bool g_bConditionDebug = false;
bool g_bConditionInitialNearby = true;
float g_fConditionInitialNearbyCooldown = 900.0;
bool g_bHealthDebug = false;
float g_fTempHealthRadius = 1000.0;

bool g_bDefibEnable = true;
bool g_bDefibDebug = false;
bool g_bDefibHud = true;
float g_fDefibRadius = 1000.0;
float g_fDefibRadiusIgnore = 700.0;
float g_fDefibFlowMin = 2000.0;
float g_fDefibFlowMax = 6000.0;

bool g_bNearFinale[2048];
float g_fFinaleIgnoreRadius;

int g_iCondition = 0;
int g_iLastCondition = -1;
float g_fNextSpawnFlow = -1.0;
float g_fBypassTime[2048];
float g_fLastInitialSpawn = 0.0;
int g_iPendingSpawns = 0;
int g_iInitialKitsGiven = 0;
int g_iSpawnPointMode = 2;

float g_fNextDefibFlow = -1.0;
float g_fLastDefibDistance = -1.0;

bool g_bPendingMedkitSpawn = false;
int  g_iPendingMedkitCount = 0;
bool g_bPendingDefibSpawn   = false;
int  g_iPendingDefibCount   = 0;

// Weapon globals
bool g_bWeaponHud = true;
bool g_bWeaponDebug = false;
float g_fWeaponAmmoPercent = 95.0;
bool g_bWeaponNearCabinet = false;
Handle g_hWeaponHudTimer = null;
int g_iTeleportWeaponIndex = 0;
bool g_bWeaponNoPrimarySpawn = true;
int g_iConditionInitialClear = 2;
int g_iProposeInitialClear;
bool g_bConditionInitialClearFailed;
bool g_bWeaponProposeInitialClearFailed;

// Ammo globals
bool   g_bAmmoEnable;
float  g_fAmmoRadius;
float  g_fAmmoRadiusIgnore;
int    g_iAmmoSpawnMode;      
float  g_fAmmoThreshold;      
bool   g_bAmmoHud;
bool   g_bAmmoDebug;

// Propose globals
bool g_bWeaponPropose;
bool g_bProposeHud;
float g_fProposeInitialMin;
float g_fProposeInitialMax;
float g_fProposeMin;
float g_fProposeMax;
bool g_bProposeDebug;
bool g_bProposeInitialDone;
int g_iProposeInitialSpawned;
float g_fProposeNextFlow = -1.0;
bool g_bProposePendingSpawn;
float g_fProposeRemaining = 0.0;    

ConVar g_cvThrowableEnable;
ConVar g_cvThrowableFlowMin;
ConVar g_cvThrowableFlowMax;
ConVar g_cvThrowableRadius;
ConVar g_cvThrowableRadiusIgnore;
ConVar g_cvThrowableDebug;
ConVar g_cvThrowableHud;
ConVar g_cvThrowableCoverage;

Handle g_hProposeHudTimer = null;

Handle g_hConditionTimer = null;
Handle g_hConditionHudTimer = null;
Handle g_hHealthTimer = null;
Handle g_hDefibHudTimer = null;
Handle g_hAmmoHudTimer = null;
bool   g_bTempHealthSpawnEnable;
float  g_fTempHealthSpawnFlowMin;
float  g_fTempHealthSpawnFlowMax;
float  g_fTempHealthSpawnIgnoreRadius;
bool   g_bTempHealthSpawnDebug;
bool   g_bTempHealthSpawnHud;

float g_fTempHealthSpawnNextFlow = -1.0;
bool  g_bTempHealthSpawnPending   = false;

bool  g_bTempHealthSpawned[2048];          

Handle g_hTempHealthSpawnHudTimer = null;

bool g_bHasItemTempHealth[MAXPLAYERS+1];

bool   g_bThrowableEnable;
float  g_fThrowableFlowMin;
float  g_fThrowableFlowMax;
float  g_fThrowableRadius;
float  g_fThrowableRadiusIgnore;
bool   g_bThrowableDebug;
bool   g_bThrowableHud;

float g_fThrowableNextFlow = -1.0;
bool  g_bThrowablePending   = false;

bool  g_bThrowableSpawned[2048];

Handle g_hThrowableHudTimer = null;

bool g_bThrowableCoverage;

bool   g_bLaserSightEnable;
float  g_fLaserSightRadius;
float  g_fLaserSightRadiusIgnore;
bool   g_bLaserSightChanceFlowRoll;
int    g_iLaserSightChance;            
bool   g_bLaserSightDebug;
bool   g_bLaserSightHud;

float g_fLaserSightNextFlow = -1.0;
bool  g_bLaserSightPending   = false;

bool  g_bLaserSightSpawned[2048];

Handle g_hLaserSightHudTimer = null;

bool   g_bUpgradePackEnable;
float  g_fUpgradePackRadiusIgnore;
int    g_iUpgradePackChance;
bool   g_bUpgradePackDebug;
bool   g_bUpgradePackHud;
float g_fUpgradePackRadius = 1000.0;

float g_fUpgradePackNextFlow = -1.0;
bool  g_bUpgradePackPending   = false;

bool  g_bUpgradePackSpawned[2048];
Handle g_hUpgradePackHudTimer = null;

// Weapon Bonding
bool  g_bBondingEnable;
float g_fBondingInterval = 42.0;
float g_fBondingFraction = 0.25;
float g_fBondingThreshold = 1.0;
bool  g_bBondingDebug;
bool  g_bBondingHud;
float g_fBondingIncrementPerSecond;
bool  g_bPendingCarryover[4];
int   g_iBondingMissCooldownClear = 2;
bool g_bBondingMissCooldownClearFailed;
bool g_bMissCooldownSetThisMap[4];
bool g_bFirstRoundOnMap;

float g_fWeaponBondingChar[4][2048];      
bool  g_bPlayerBondingReady[MAXPLAYERS+1];
bool  g_bBondingLaserPending;

float g_fBondingMissCooldown = 900.0;
float g_fBondingMissCooldownUntil[4];   
bool  g_bBondingDecayEnable;
float g_fBondingDecayInterval;
float g_fBondingDecayThreshold;
float g_fBondingDecayPerSecond;

float g_fWeaponLastDropTime[4][2048];
bool  g_bCharNearLaser[4];              

float g_fCarryoverBonding[4];            
float g_fMapStartBonding[4];             

bool  g_bBondingLaserGiven[4];          
int   g_iLastPrimaryWeapon[MAXPLAYERS+1] = { -1, ... };

Handle g_hBondingTimer = null;
Handle g_hBondingHudTimer = null;

char g_sCarryoverWeaponClass[4][64];
char g_sWeaponEntityClass[2048][64];

static const char g_sWeapons[][] = {
    "weapon_rifle", "weapon_rifle_ak47", "weapon_rifle_desert", "weapon_rifle_sg552",
    "weapon_smg", "weapon_smg_silenced", "weapon_smg_mp5", "weapon_pumpshotgun",
    "weapon_shotgun_chrome", "weapon_autoshotgun", "weapon_shotgun_spas", "weapon_hunting_rifle",
    "weapon_sniper_military", "weapon_sniper_awp", "weapon_sniper_scout", "weapon_rifle_m60",
    "weapon_grenade_launcher"
};

static const char g_sThrowableNames[][] = {
    "weapon_pipe_bomb",
    "weapon_molotov",
    "weapon_vomitjar"
};

float g_vSpawnerPos[2048][3];
float g_vSpawnerAng[2048][3];
int g_iSpawnerCount = 0;

bool g_bUsedIndex[2048];
bool g_bWeaponSpawned[2048];
bool g_bMedkitSpawned[2048];
bool g_bDefibSpawned[2048];
bool g_bNearCabinet[2048];
bool g_bNearSaferoom[2048];
float g_fLastVisibilityFail[2048];

ArrayList g_aCleanupItems;
ArrayList g_aCleanupTimers;
ArrayList g_aCleanupIndex;
ArrayList g_aCleanupType;
float g_fLastCleanupCheck;

Handle g_hProximityTimer = null;
Handle g_hCleanupTimer = null;
char g_sLogPath[PLATFORM_MAX_PATH];

int g_iTeleportIndex = 0;
int g_iTeleportTempIndex = 0;
int g_iTeleportDefibIndex = 0;

ConVar g_hCvar_PillsDecay;
float g_fCvar_PillsDecay = 0.27;

float g_fLastItemPickupTime;

public Plugin myinfo = {
    name = "Item Director",
    author = "Tighty-Whitey",
    description = "Adaptive item director",
    version = "1.2",
    url = ""
};

public void OnPluginStart()
{
    BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), LOG_FILE);

    g_cvEnable                 = CreateConVar("item_director_enable", "1", "Master enable (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvAllowedModes = CreateConVar("item_director_modes", "", "Comma‑separated allowed game modes (no spaces). Empty = all.", FCVAR_NOTIFY);
    g_cvReplaceRadius          = CreateConVar("item_director_replace_radius", "1.0", "Radius around spawn to remove the original item spawner", FCVAR_NOTIFY);
    g_cvWeaponEnable           = CreateConVar("item_director_weapon_enable", "1", "Enable proximity weapon spawn (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvWeaponRadius           = CreateConVar("item_director_weapon_radius", "1000.0", "Outer radius around original item spawn to spawn a weapon", FCVAR_NOTIFY);
    g_cvWeaponRadiusIgnore     = CreateConVar("item_director_weapon_radius_ignore", "700.0", "Inner radius – weapon will NOT spawn if survivor is closer than this", FCVAR_NOTIFY);
    g_cvMedkitEnable           = CreateConVar("item_director_medkit_enable", "1", "Enable medkit spawn (condition system) (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvMedkitRadius           = CreateConVar("item_director_medkit_radius", "1000.0", "Outer radius around original item spawn to spawn a first aid kit", FCVAR_NOTIFY);
    g_cvMedkitRadiusIgnore     = CreateConVar("item_director_medkit_radius_ignore", "700.0", "Inner radius – medkit will NOT spawn if survivor is closer than this", FCVAR_NOTIFY);
    g_cvCabinetRadius          = CreateConVar("item_director_cabinet_ignore_radius", "200.0", "Radius around medical cabinets to block spawns", FCVAR_NOTIFY);
    g_cvMedkitNearCabinet      = CreateConVar("item_director_medkit_near_cabinet", "0", "Allow medkits to spawn near medical cabinets (0=No, 1=Yes)", FCVAR_NOTIFY);
    g_cvReplaceItem            = CreateConVar("item_director_replace_item", "1", "Replace the original item at the spawn point (0=No, 1=Yes)", FCVAR_NOTIFY);
    g_cvDebug                  = CreateConVar("item_director_debug", "0", "Write debug messages to log file (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvVisibleSpawn           = CreateConVar("item_director_visible", "0", "0 = Only spawn when NOT visible to survivors. 1 = Spawn even if visible.", FCVAR_NOTIFY);
    g_cvFailCooldown           = CreateConVar("item_director_visibility_fail_cooldown", "0", "Cooldown length for a spawn point that was visible to any survivor. Off by default, highly aggressive. (0=Off).", FCVAR_NOTIFY);
    g_cvCleanupEnable          = CreateConVar("item_director_cleanup_enable", "1", "Enable cleanup of items when survivors are far away for too long (0=Off, 1=On).", FCVAR_NOTIFY);
    g_cvCleanupRadius          = CreateConVar("item_director_cleanup_radius", "3000.0", "Distance (units) beyond which survivors are considered 'away' from an item.", FCVAR_NOTIFY);
    g_cvCleanupDelay           = CreateConVar("item_director_cleanup_delay", "900.0", "Seconds survivors must remain away before the item is removed.", FCVAR_NOTIFY);
    g_cvCleanupRespawnEnable   = CreateConVar("item_director_cleanup_respawn_enable", "1", "Allow spawn points to become active again after cleanup removes their item (0=No, 1=Yes).", FCVAR_NOTIFY);
    g_cvRequireLeftSafeArea    = CreateConVar("item_director_require_left_safe_area", "1", "Only allow spawning after survivors have left the starting safe area (0=No, 1=Yes).", FCVAR_NOTIFY);
    g_cvConditionEnable        = CreateConVar("item_director_condition_enable", "1", "Enable condition‑based medkit system (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvConditionFlowMin       = CreateConVar("item_director_condition_flow_min", "3000", "Minimum flow travel between medkit spawn attempts", FCVAR_NOTIFY);
    g_cvConditionFlowMax       = CreateConVar("item_director_condition_flow_max", "4500", "Maximum flow travel between medkit spawn attempts", FCVAR_NOTIFY);
    g_cvConditionMaxMeds       = CreateConVar("item_director_condition_max_medkits", "2", "Maximum TOTAL first aid kits (map + plugin) allowed on the ground at once", FCVAR_NOTIFY);
    g_cvBypassCooldown         = CreateConVar("item_director_bypass_cooldown", "600.0", "Cooldown due to location being blocked after a survivor passed within the ignore radius", FCVAR_NOTIFY);
    g_cvConditionHud           = CreateConVar("item_director_condition_hud_enable", "0", "Show condition HUD (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvConditionDebug         = CreateConVar("item_director_condition_debug", "0", "Write condition debug messages to log file (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvConditionInitialNearby = CreateConVar("item_director_condition_initial_nearby", "1", "When condition activates from 0, immediately attempt spawn at the closest valid location (0=only flow travel)", FCVAR_NOTIFY);
    g_cvConditionInitialNearbyCooldown = CreateConVar("item_director_condition_initial_nearby_cooldown", "900.0", "Seconds before the initial nearby spawn can happen again after a successful spawn (0=always)", FCVAR_NOTIFY);
    g_cvConditionInitialClear = CreateConVar("item_director_condition_initial_clear", "2", "Clear cooldown for the initial state of medkit spawns to allow medkit spawns to trigger earlier. (0 = clear on round start & map start, 1 = clear on map start, 2 = clear on campaign start, 3 = never clear)", FCVAR_NOTIFY);
    g_cvConditionInitialClearFailed = CreateConVar("item_director_condition_initial_clear_failed", "1", "Clear medkit initial cooldown on mission failed (0=No, 1=Yes)", FCVAR_NOTIFY);
    g_cvHealthDebug            = CreateConVar("item_director_health_debug", "0", "Enable health‑item trace logs (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvTempHealthRadius       = CreateConVar("item_director_temp_health_radius", "1000", "Radius to count ground temporary health items (pills & adrenaline). 0=Off.", FCVAR_NOTIFY);

    g_cvDefibEnable            = CreateConVar("item_director_defibrillator_enable", "1", "Enable defibrillator spawning (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvDefibDebug             = CreateConVar("item_director_defibrillator_debug", "0", "Write defibrillator debug messages to log file (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvDefibHud               = CreateConVar("item_director_defibrillator_hud_enable", "0", "Show defibrillator HUD (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvDefibRadius            = CreateConVar("item_director_defibrillator_radius", "1000.0", "Outer radius around original item spawn to spawn a defibrillator", FCVAR_NOTIFY);
    g_cvDefibRadiusIgnore      = CreateConVar("item_director_defibrillator_radius_ignore", "700.0", "Inner radius – defibrillator will NOT spawn if survivor is closer than this", FCVAR_NOTIFY);
    g_cvDefibFlowMin           = CreateConVar("item_director_defibrillator_flow_min", "2000", "Minimum flow travel between defibrillator spawn attempts", FCVAR_NOTIFY);
    g_cvDefibFlowMax           = CreateConVar("item_director_defibrillator_flow_max", "6000", "Maximum flow travel between defibrillator spawn attempts", FCVAR_NOTIFY);
    g_cvDefibNearCabinet       = CreateConVar("item_director_defibrillator_near_cabinet", "0", "Allow defibrillators to spawn near medical cabinets (0=No, 1=Yes)", FCVAR_NOTIFY);
    g_cvSpawnImmediate         = CreateConVar("item_director_spawn_immediate", "1", "When a flow-travel spawn fails, spawn the item(s) as soon as a valid location is available (1 = Yes, 0 = set new flow target)", FCVAR_NOTIFY);
    g_cvSaferoomIgnoreRadius   = CreateConVar("item_director_saferoom_ignore_radius", "600.0", "Radius around saferoom to block weapon/medkit/defib spawns (0=Off)", FCVAR_NOTIFY);
    g_cvSpawnPointMode         = CreateConVar("item_director_spawn_point_mode", "2", "Spawn point source: 1=Pills/Adrenaline only, 2=All item spawners. Mode 2 allows for significantly more potential areas.", FCVAR_NOTIFY);

    g_cvWeaponHud              = CreateConVar("item_director_weapon_hud_enable", "0", "Show weapon spawn HUD (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvWeaponDebug            = CreateConVar("item_director_weapon_debug", "0", "Write weapon debug messages to log (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvWeaponAmmoPercent      = CreateConVar("item_director_weapon_ammo_percent", "-1", "Percent of max reserve ammo below which to spawn a weapon. Set to -1 to disable ammo‑based spawning.", FCVAR_NOTIFY);
    g_cvWeaponNearCabinet      = CreateConVar("item_director_weapon_near_cabinet", "0", "Allow weapons to spawn near medical cabinets (0=No, 1=Yes)", FCVAR_NOTIFY);
    g_cvWeaponNoPrimarySpawn   = CreateConVar("item_director_weapon_noprimary_spawn", "1", "Spawn a weapon when a survivor has no primary weapon and nowhere near other weapons (0=Off, 1=On)", FCVAR_NOTIFY);

    g_cvWeaponPropose = CreateConVar("item_director_weapon_propose", "1", "Enable flow‑based weapon spawning (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvWeaponProposeHud = CreateConVar("item_director_weapon_propose_hud_enable", "0", "Show weapon propose HUD (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvWeaponProposeInitialMin = CreateConVar("item_director_weapon_propose_initial_min", "2000.0", "Min flow travel for initial propose spawns", FCVAR_NOTIFY);
    g_cvWeaponProposeInitialMax = CreateConVar("item_director_weapon_propose_initial_max", "8000.0", "Max flow travel for initial propose spawns", FCVAR_NOTIFY);
    g_cvWeaponProposeMin = CreateConVar("item_director_weapon_propose_min", "3000.0", "Min flow travel for ongoing propose spawns", FCVAR_NOTIFY);
    g_cvWeaponProposeMax = CreateConVar("item_director_weapon_propose_max", "15000.0", "Max flow travel for ongoing propose spawns", FCVAR_NOTIFY);
    g_cvWeaponProposeInitialClear = CreateConVar("item_director_weapon_propose_initial_clear", "2", "Clear the initial state of weapon proposal to allow them to trigger earlier. (0 = clear on round start & map start, 1 = clear on map start, 2 = clear on campaign start)", FCVAR_NOTIFY);
    g_cvWeaponProposeInitialClearFailed = CreateConVar("item_director_weapon_propose_initial_clear_failed", "1", "Clear weapon propose initial state on mission failed (0=No, 1=Yes)", FCVAR_NOTIFY);
    g_cvWeaponProposeDebug = CreateConVar("item_director_weapon_propose_debug", "0", "Write weapon propose debug messages to log (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvAmmoEnable      = CreateConVar("item_director_ammo_enable",             "1",       "Enable ammo spawning (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvAmmoRadius      = CreateConVar("item_director_ammo_radius",             "1000.0",  "Outer radius around spawn to spawn ammo", FCVAR_NOTIFY);
    g_cvAmmoRadiusIgnore= CreateConVar("item_director_ammo_radius_ignore",      "700.0",   "Inner radius – ammo will NOT spawn if survivor is closer than this", FCVAR_NOTIFY);
    g_cvAmmoSpawnMode   = CreateConVar("item_director_ammo_spawn_mode",         "1",       "Ammo spawn mode: 1 = per player, 2 = team pool", FCVAR_NOTIFY);
    g_cvAmmoThreshold   = CreateConVar("item_director_ammo_threshold",          "15.0",    "Ammo reserve percent threshold (if ammo% <= this, spawn may trigger)", FCVAR_NOTIFY);
    g_cvAmmoHud         = CreateConVar("item_director_ammo_hud_enable",         "0",       "Show ammo HUD (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvAmmoDebug       = CreateConVar("item_director_ammo_debug",              "0",       "Write ammo debug messages to log (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvTempHealthSpawnEnable      = CreateConVar("item_director_temp_health_spawn_enable",          "1",        "Enable flow‑based temporary health spawning (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvTempHealthSpawnFlowMin     = CreateConVar("item_director_temp_health_spawn_flow_min",         "2000.0",   "Min flow travel between temp health spawn attempts", FCVAR_NOTIFY);
    g_cvTempHealthSpawnFlowMax     = CreateConVar("item_director_temp_health_spawn_flow_max",         "12000.0",  "Max flow travel between temp health spawn attempts", FCVAR_NOTIFY);
    g_cvTempHealthSpawnIgnoreRadius= CreateConVar("item_director_temp_health_spawn_ignore_radius",    "700.0",    "Inner radius – temp health will NOT spawn if survivor is closer than this", FCVAR_NOTIFY);
    g_cvTempHealthSpawnDebug       = CreateConVar("item_director_temp_health_spawn_debug",            "0",        "Write temp health spawn debug messages to log (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvTempHealthSpawnHud         = CreateConVar("item_director_temp_health_spawn_hud_enable",       "0",        "Show temp health spawn HUD (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvThrowableEnable      = CreateConVar("item_director_throwable_enable",          "1",        "Enable flow‑based throwable spawning (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvThrowableFlowMin     = CreateConVar("item_director_throwable_flow_min",         "2000.0",   "Min flow travel between throwable spawn attempts", FCVAR_NOTIFY);
    g_cvThrowableFlowMax     = CreateConVar("item_director_throwable_flow_max",         "10000.0",   "Max flow travel between throwable spawn attempts", FCVAR_NOTIFY);
    g_cvThrowableRadius      = CreateConVar("item_director_throwable_radius",           "1000.0",   "Outer radius around spawn to count a throwable as available", FCVAR_NOTIFY);
    g_cvThrowableRadiusIgnore= CreateConVar("item_director_throwable_radius_ignore",    "700.0",    "Inner radius – throwable will NOT spawn if survivor is closer than this", FCVAR_NOTIFY);
    g_cvThrowableDebug       = CreateConVar("item_director_throwable_debug",            "0",        "Write throwable debug messages to log (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvThrowableHud         = CreateConVar("item_director_throwable_hud_enable",       "0",        "Show throwable HUD (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvThrowableCoverage    = CreateConVar("item_director_throwable_coverage_enable",  "0", "Enable throwable coverage checks (0=Flow‑only, 1=Coverage‑based)", FCVAR_NOTIFY);
    g_cvLaserSightEnable        = CreateConVar("item_director_lasersight_enable",              "1",    "Enable laser‑sight spawning (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvLaserSightRadius        = CreateConVar("item_director_lasersight_radius",              "1000.0", "Outer radius around spawn to count an existing laser as present", FCVAR_NOTIFY);
    g_cvLaserSightRadiusIgnore  = CreateConVar("item_director_lasersight_radius_ignore",       "700.0",  "Inner radius – laser will NOT spawn if survivor is closer than this", FCVAR_NOTIFY);
    g_cvLaserSightChanceFlowRoll = CreateConVar("item_director_lasersight_chance_flow_roll",    "0",     "Enable chance‑based flow target. Disabled by default. Lasers spawn based on weapon bonding system (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvLaserSightChance        = CreateConVar("item_director_lasersight_chance",              "33",    "Percent chance to spawn when flow target is reached", FCVAR_NOTIFY);
    g_cvLaserSightDebug         = CreateConVar("item_director_lasersight_debug",               "0",     "Write laser‑sight debug messages to log (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvLaserSightHud           = CreateConVar("item_director_lasersight_hud_enable",         "0",     "Show laser‑sight HUD (0=Off, 1=On)", FCVAR_NOTIFY);
    
    g_cvUpgradePackEnable        = CreateConVar("item_director_upgradepack_enable",           "1",    "Enable chance‑based upgrade pack spawning (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvUpgradePackRadius = CreateConVar("item_director_upgradepack_radius", "1000.0", "Outer radius for upgrade pack spawn (0=no limit)", FCVAR_NOTIFY);
    g_cvUpgradePackRadiusIgnore  = CreateConVar("item_director_upgradepack_radius_ignore",    "700.0","Inner radius – upgrade pack will NOT spawn if survivor is closer than this", FCVAR_NOTIFY);
    g_cvUpgradePackChance        = CreateConVar("item_director_upgradepack_chance",           "33",   "Percent chance to spawn when flow target is reached", FCVAR_NOTIFY);
    g_cvUpgradePackDebug         = CreateConVar("item_director_upgradepack_debug",            "0",    "Write upgrade pack debug messages to log (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvUpgradePackHud           = CreateConVar("item_director_upgradepack_hud_enable",       "0",    "Show upgrade pack HUD (0=Off, 1=On)", FCVAR_NOTIFY);

    g_cvBondingEnable   = CreateConVar("item_director_weapon_bonding_enable", "1", "Enable weapon bonding laser spawns", FCVAR_NOTIFY);
    g_cvBondingInterval = CreateConVar("item_director_weapon_bonding_interval", "42.0", "Seconds per 0.1 bonding increase (42 => 7 min to max)", FCVAR_NOTIFY);
    g_cvBondingFraction = CreateConVar("item_director_weapon_bonding_fraction", "0.25", "Fraction of alive team needed with max bonding to trigger laser", FCVAR_NOTIFY);
    g_cvBondingThreshold = CreateConVar("item_director_weapon_bonding_threshold", "1.0", "Bonding value at which a player counts as ready (0.0 – 1.0)", FCVAR_NOTIFY);
    g_cvBondingMissCooldown = CreateConVar("item_director_weapon_bonding_miss_cooldown", "900.0", "Seconds a survivor who leaves a laser range without picking it up cannot trigger a new bonding laser spawn.", FCVAR_NOTIFY);
    g_cvBondingDebug    = CreateConVar("item_director_weapon_bonding_debug", "0", "Write weapon bonding debug to log (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvBondingHud = CreateConVar("item_director_weapon_bonding_hud_enable", "0", "Show weapon bonding HUD (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvBondingMissCooldownClear = CreateConVar("item_director_weapon_bonding_miss_cooldown_clear", "2", "When to clear the miss cooldown: 0 = round start & map start, 1 = map start, 2 = campaign start, 3 = never clear.", FCVAR_NOTIFY);
    g_cvBondingDecayEnable    = CreateConVar("item_director_weapon_bonding_decay_enable",    "1",       "Enable bonding decay while weapon is dropped (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvBondingDecayInterval  = CreateConVar("item_director_weapon_bonding_decay_interval",  "84.0",    "Seconds per 0.1 bonding decay (default 84 => 14 min to fully decay from 1.0)", FCVAR_NOTIFY);
    g_cvBondingMissCooldownClearFailed     = CreateConVar("item_director_weapon_bonding_miss_cooldown_clear_failed",      "1", "Clear bonding miss cooldown on mission failed, but only if that cooldown was applied on the same map where mission failed. (0=Off, 1=On)", FCVAR_NOTIFY);
    g_cvBondingDecayThreshold = CreateConVar("item_director_weapon_bonding_decay_threshold", "0.0",     "Minimum bonding value after decay", FCVAR_NOTIFY);
    
    g_cvFinaleIgnoreRadius  = CreateConVar("item_director_finale_ignore_radius", "1000.0", "Radius around finale areas to block spawns (0=Off)", FCVAR_NOTIFY);

    AutoExecConfig(true, "l4d2_item_director");

    g_hCvar_PillsDecay = FindConVar("pain_pills_decay_rate");
    if (g_hCvar_PillsDecay != null)
    {
        g_fCvar_PillsDecay = g_hCvar_PillsDecay.FloatValue;
        g_hCvar_PillsDecay.AddChangeHook(OnPillsDecayChanged);
    }

    g_cvEnable.AddChangeHook(OnCvarChanged);
    g_cvAllowedModes.AddChangeHook(OnCvarChanged);
    g_cvReplaceRadius.AddChangeHook(OnCvarChanged);
    g_cvWeaponEnable.AddChangeHook(OnCvarChanged);
    g_cvWeaponRadius.AddChangeHook(OnCvarChanged);
    g_cvWeaponRadiusIgnore.AddChangeHook(OnCvarChanged);
    g_cvMedkitEnable.AddChangeHook(OnCvarChanged);
    g_cvMedkitRadius.AddChangeHook(OnCvarChanged);
    g_cvMedkitRadiusIgnore.AddChangeHook(OnCvarChanged);
    g_cvCabinetRadius.AddChangeHook(OnCvarChanged);
    g_cvMedkitNearCabinet.AddChangeHook(OnCvarChanged);
    g_cvReplaceItem.AddChangeHook(OnCvarChanged);
    g_cvDebug.AddChangeHook(OnCvarChanged);
    g_cvVisibleSpawn.AddChangeHook(OnCvarChanged);
    g_cvFailCooldown.AddChangeHook(OnCvarChanged);
    g_cvCleanupEnable.AddChangeHook(OnCvarChanged);
    g_cvCleanupRadius.AddChangeHook(OnCvarChanged);
    g_cvCleanupDelay.AddChangeHook(OnCvarChanged);
    g_cvCleanupRespawnEnable.AddChangeHook(OnCvarChanged);
    g_cvRequireLeftSafeArea.AddChangeHook(OnCvarChanged);
    g_cvConditionEnable.AddChangeHook(OnCvarChanged);
    g_cvConditionFlowMin.AddChangeHook(OnCvarChanged);
    g_cvConditionFlowMax.AddChangeHook(OnCvarChanged);
    g_cvConditionMaxMeds.AddChangeHook(OnCvarChanged);
    g_cvBypassCooldown.AddChangeHook(OnCvarChanged);
    g_cvConditionHud.AddChangeHook(OnCvarChanged);
    g_cvConditionDebug.AddChangeHook(OnCvarChanged);
    g_cvConditionInitialNearby.AddChangeHook(OnCvarChanged);
    g_cvConditionInitialNearbyCooldown.AddChangeHook(OnCvarChanged);
    g_cvConditionInitialClear.AddChangeHook(OnCvarChanged);
    g_cvHealthDebug.AddChangeHook(OnCvarChanged);
    g_cvTempHealthRadius.AddChangeHook(OnCvarChanged);
    g_cvDefibEnable.AddChangeHook(OnCvarChanged);
    g_cvDefibDebug.AddChangeHook(OnCvarChanged);
    g_cvDefibHud.AddChangeHook(OnCvarChanged);
    g_cvDefibRadius.AddChangeHook(OnCvarChanged);
    g_cvDefibRadiusIgnore.AddChangeHook(OnCvarChanged);
    g_cvDefibFlowMin.AddChangeHook(OnCvarChanged);
    g_cvDefibFlowMax.AddChangeHook(OnCvarChanged);
    g_cvDefibNearCabinet.AddChangeHook(OnCvarChanged);
    g_cvSpawnImmediate.AddChangeHook(OnCvarChanged);
    g_cvSaferoomIgnoreRadius.AddChangeHook(OnCvarChanged);
    g_cvSpawnPointMode.AddChangeHook(OnCvarChanged);
    g_cvWeaponHud.AddChangeHook(OnCvarChanged);
    g_cvWeaponDebug.AddChangeHook(OnCvarChanged);
    g_cvWeaponAmmoPercent.AddChangeHook(OnCvarChanged);
    g_cvWeaponNearCabinet.AddChangeHook(OnCvarChanged);
    g_cvWeaponNoPrimarySpawn.AddChangeHook(OnCvarChanged);
    g_cvWeaponPropose.AddChangeHook(OnCvarChanged);
    g_cvWeaponProposeHud.AddChangeHook(OnCvarChanged);
    g_cvWeaponProposeInitialMin.AddChangeHook(OnCvarChanged);
    g_cvWeaponProposeInitialMax.AddChangeHook(OnCvarChanged);
    g_cvWeaponProposeMin.AddChangeHook(OnCvarChanged);
    g_cvWeaponProposeMax.AddChangeHook(OnCvarChanged);
    g_cvWeaponProposeInitialClear.AddChangeHook(OnCvarChanged);
    g_cvWeaponProposeDebug.AddChangeHook(OnCvarChanged);
    g_cvConditionInitialClearFailed.AddChangeHook(OnCvarChanged);
    g_cvWeaponProposeInitialClearFailed.AddChangeHook(OnCvarChanged);
    g_cvAmmoEnable.AddChangeHook(OnCvarChanged);
    g_cvAmmoRadius.AddChangeHook(OnCvarChanged);
    g_cvAmmoRadiusIgnore.AddChangeHook(OnCvarChanged);
    g_cvAmmoSpawnMode.AddChangeHook(OnCvarChanged);
    g_cvAmmoThreshold.AddChangeHook(OnCvarChanged);
    g_cvAmmoHud.AddChangeHook(OnCvarChanged);
    g_cvAmmoDebug.AddChangeHook(OnCvarChanged);
    g_cvTempHealthSpawnEnable.AddChangeHook(OnCvarChanged);
    g_cvTempHealthSpawnFlowMin.AddChangeHook(OnCvarChanged);
    g_cvTempHealthSpawnFlowMax.AddChangeHook(OnCvarChanged);
    g_cvTempHealthSpawnIgnoreRadius.AddChangeHook(OnCvarChanged);
    g_cvTempHealthSpawnDebug.AddChangeHook(OnCvarChanged);
    g_cvTempHealthSpawnHud.AddChangeHook(OnCvarChanged);
    g_cvThrowableEnable.AddChangeHook(OnCvarChanged);
    g_cvThrowableFlowMin.AddChangeHook(OnCvarChanged);
    g_cvThrowableFlowMax.AddChangeHook(OnCvarChanged);
    g_cvThrowableRadius.AddChangeHook(OnCvarChanged);
    g_cvThrowableRadiusIgnore.AddChangeHook(OnCvarChanged);
    g_cvThrowableDebug.AddChangeHook(OnCvarChanged);
    g_cvThrowableHud.AddChangeHook(OnCvarChanged);
    g_cvThrowableCoverage.AddChangeHook(OnCvarChanged);
    g_cvLaserSightEnable.AddChangeHook(OnCvarChanged);
    g_cvLaserSightRadius.AddChangeHook(OnCvarChanged);
    g_cvLaserSightRadiusIgnore.AddChangeHook(OnCvarChanged);
    g_cvLaserSightChanceFlowRoll.AddChangeHook(OnCvarChanged);
    g_cvLaserSightChance.AddChangeHook(OnCvarChanged);
    g_cvUpgradePackEnable.AddChangeHook(OnCvarChanged);
    g_cvUpgradePackRadius.AddChangeHook(OnCvarChanged);
    g_cvUpgradePackRadiusIgnore.AddChangeHook(OnCvarChanged);
    g_cvUpgradePackChance.AddChangeHook(OnCvarChanged);
    g_cvUpgradePackDebug.AddChangeHook(OnCvarChanged);
    g_cvUpgradePackHud.AddChangeHook(OnCvarChanged);
    g_cvBondingThreshold.AddChangeHook(OnCvarChanged);
    g_cvBondingDecayEnable.AddChangeHook(OnCvarChanged);
    g_cvBondingDecayInterval.AddChangeHook(OnCvarChanged);
    g_cvBondingDecayThreshold.AddChangeHook(OnCvarChanged);
    g_cvLaserSightDebug.AddChangeHook(OnCvarChanged);
    g_cvLaserSightHud.AddChangeHook(OnCvarChanged);
    g_cvFinaleIgnoreRadius.AddChangeHook(OnCvarChanged);
    
    g_cvBondingEnable.AddChangeHook(OnCvarChanged);
    g_cvBondingInterval.AddChangeHook(OnCvarChanged);
    g_cvBondingFraction.AddChangeHook(OnCvarChanged);
    g_cvBondingDebug.AddChangeHook(OnCvarChanged);
    g_cvBondingHud.AddChangeHook(OnCvarChanged);
    g_cvBondingMissCooldown.AddChangeHook(OnCvarChanged);
    g_cvBondingMissCooldownClear.AddChangeHook(OnCvarChanged);
    g_cvBondingMissCooldownClearFailed.AddChangeHook(OnCvarChanged);

    HookEvent("item_pickup", Event_ItemPickup);
    HookEvent("weapon_drop", Event_WeaponDrop);
    HookEvent("pills_used", Event_PillsUsed);
    HookEvent("adrenaline_used", Event_AdrenalineUsed);
    HookEvent("heal_begin", Event_HealBegin);
    HookEvent("heal_success", Event_HealSuccess);
    HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end",   Event_RoundEnd,   EventHookMode_PostNoCopy);
    HookEvent("player_left_safe_area", Event_PlayerLeftSafeArea, EventHookMode_PostNoCopy);
    HookEvent("upgrade_pack_used", Event_UpgradePackUsed, EventHookMode_Post);

    g_aCleanupItems = new ArrayList();
    g_aCleanupTimers = new ArrayList();
    g_aCleanupIndex = new ArrayList();
    g_aCleanupType = new ArrayList();

    RegAdminCmd("sm_teleport", Cmd_Teleport, ADMFLAG_ROOT, "Teleport to the next spawned first aid kit");
    RegAdminCmd("sm_teleporttemp", Cmd_TeleportTemp, ADMFLAG_ROOT, "Teleport to the next temporary health item in range");
    RegAdminCmd("sm_teleportdefib", Cmd_TeleportDefib, ADMFLAG_ROOT, "Teleport to the next defibrillator in range");
    RegAdminCmd("sm_teleportweapon", Cmd_TeleportWeapon, ADMFLAG_ROOT, "Teleport to the next spawned weapon");
    RegAdminCmd("sm_teleportammo", Cmd_TeleportAmmo, ADMFLAG_ROOT, "Teleport to the next spawned ammo");
    RegAdminCmd("sm_teleportthrowable", Cmd_TeleportThrowable, ADMFLAG_ROOT, "Teleport to the next throwable item in range");
    RegAdminCmd("sm_teleportlaser", Cmd_TeleportLaser, ADMFLAG_ROOT, "Teleport to the next laser‑sight item in range");
    RegAdminCmd("sm_teleportupgradepack", Cmd_TeleportUpgradePack, ADMFLAG_ROOT, "Teleport to the next upgrade pack in range");
}

void OnPillsDecayChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_fCvar_PillsDecay = g_hCvar_PillsDecay.FloatValue;
}

public void OnConfigsExecuted()
{
    ApplyCvars();
    ManageTimers();
}

void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    ApplyCvars();
    ManageTimers();
}

void ApplyCvars()
{
    g_bEnabled           = g_cvEnable.BoolValue;
    g_fReplaceRadius     = g_cvReplaceRadius.FloatValue;
    g_bWeaponEnable      = g_cvWeaponEnable.BoolValue;
    g_fWeaponRadius      = g_cvWeaponRadius.FloatValue;
    g_fWeaponRadiusIgnore = g_cvWeaponRadiusIgnore.FloatValue;
    g_bMedkitEnable      = g_cvMedkitEnable.BoolValue;
    g_fMedkitRadius      = g_cvMedkitRadius.FloatValue;
    g_fMedkitRadiusIgnore = g_cvMedkitRadiusIgnore.FloatValue;
    g_fCabinetRadius     = g_cvCabinetRadius.FloatValue;
    g_bMedkitNearCabinet = g_cvMedkitNearCabinet.BoolValue;
    g_bReplaceItem       = g_cvReplaceItem.BoolValue;
    g_bDebug             = g_cvDebug.BoolValue;
    g_bSpawnIfVisible    = g_cvVisibleSpawn.BoolValue;
    g_fFailCooldown      = g_cvFailCooldown.FloatValue;
    g_bCleanupEnable     = g_cvCleanupEnable.BoolValue;
    g_fCleanupRadius     = g_cvCleanupRadius.FloatValue;
    g_fCleanupDelay      = g_cvCleanupDelay.FloatValue;
    g_bCleanupRespawnEnable = g_cvCleanupRespawnEnable.BoolValue;
    g_bRequireLeftSafeArea = g_cvRequireLeftSafeArea.BoolValue;
    g_bConditionEnable   = g_cvConditionEnable.BoolValue;
    g_fConditionFlowMin  = g_cvConditionFlowMin.FloatValue;
    g_fConditionFlowMax  = g_cvConditionFlowMax.FloatValue;
    g_iConditionMaxMeds  = g_cvConditionMaxMeds.IntValue;
    g_fBypassCooldown    = g_cvBypassCooldown.FloatValue;
    g_bConditionHud      = g_cvConditionHud.BoolValue;
    g_bConditionDebug    = g_cvConditionDebug.BoolValue;
    g_bConditionInitialNearby = g_cvConditionInitialNearby.BoolValue;
    g_fConditionInitialNearbyCooldown = g_cvConditionInitialNearbyCooldown.FloatValue;
    g_iConditionInitialClear = g_cvConditionInitialClear.IntValue;
    g_bConditionInitialClearFailed = g_cvConditionInitialClearFailed.BoolValue;
    g_bWeaponProposeInitialClearFailed = g_cvWeaponProposeInitialClearFailed.BoolValue;
    g_bHealthDebug       = g_cvHealthDebug.BoolValue;
    g_fTempHealthRadius  = g_cvTempHealthRadius.FloatValue;

    g_bDefibEnable       = g_cvDefibEnable.BoolValue;
    g_bDefibDebug        = g_cvDefibDebug.BoolValue;
    g_bDefibHud          = g_cvDefibHud.BoolValue;
    g_fDefibRadius       = g_cvDefibRadius.FloatValue;
    g_fDefibRadiusIgnore = g_cvDefibRadiusIgnore.FloatValue;
    g_fDefibFlowMin      = g_cvDefibFlowMin.FloatValue;
    g_fDefibFlowMax      = g_cvDefibFlowMax.FloatValue;
    g_bDefibNearCabinet  = g_cvDefibNearCabinet.BoolValue;
    g_fSaferoomIgnoreRadius = g_cvSaferoomIgnoreRadius.FloatValue;
    g_iSpawnPointMode    = g_cvSpawnPointMode.IntValue;

    g_bWeaponHud         = g_cvWeaponHud.BoolValue;
    g_bWeaponDebug       = g_cvWeaponDebug.BoolValue;
    g_fWeaponAmmoPercent = g_cvWeaponAmmoPercent.FloatValue;
    g_bWeaponNearCabinet = g_cvWeaponNearCabinet.BoolValue;
    g_bWeaponNoPrimarySpawn = g_cvWeaponNoPrimarySpawn.BoolValue;

    g_bWeaponPropose = g_cvWeaponPropose.BoolValue;
    g_bProposeHud = g_cvWeaponProposeHud.BoolValue;
    g_fProposeInitialMin = g_cvWeaponProposeInitialMin.FloatValue;
    g_fProposeInitialMax = g_cvWeaponProposeInitialMax.FloatValue;
    g_fProposeMin = g_cvWeaponProposeMin.FloatValue;
    g_fProposeMax = g_cvWeaponProposeMax.FloatValue;
    g_iProposeInitialClear = g_cvWeaponProposeInitialClear.IntValue;
    g_bProposeDebug = g_cvWeaponProposeDebug.BoolValue;
    
    g_bAmmoEnable         = g_cvAmmoEnable.BoolValue;
    g_fAmmoRadius         = g_cvAmmoRadius.FloatValue;
    g_fAmmoRadiusIgnore   = g_cvAmmoRadiusIgnore.FloatValue;
    g_iAmmoSpawnMode      = g_cvAmmoSpawnMode.IntValue;
    g_fAmmoThreshold      = g_cvAmmoThreshold.FloatValue;
    g_bAmmoHud            = g_cvAmmoHud.BoolValue;
    g_bAmmoDebug          = g_cvAmmoDebug.BoolValue;

    g_bTempHealthSpawnEnable       = g_cvTempHealthSpawnEnable.BoolValue;
    g_fTempHealthSpawnFlowMin      = g_cvTempHealthSpawnFlowMin.FloatValue;
    g_fTempHealthSpawnFlowMax      = g_cvTempHealthSpawnFlowMax.FloatValue;
    g_fTempHealthSpawnIgnoreRadius = g_cvTempHealthSpawnIgnoreRadius.FloatValue;
    g_bTempHealthSpawnDebug        = g_cvTempHealthSpawnDebug.BoolValue;
    g_bTempHealthSpawnHud          = g_cvTempHealthSpawnHud.BoolValue;

    g_bThrowableEnable       = g_cvThrowableEnable.BoolValue;
    g_fThrowableFlowMin      = g_cvThrowableFlowMin.FloatValue;
    g_fThrowableFlowMax      = g_cvThrowableFlowMax.FloatValue;
    g_fThrowableRadius       = g_cvThrowableRadius.FloatValue;
    g_fThrowableRadiusIgnore = g_cvThrowableRadiusIgnore.FloatValue;
    g_bThrowableDebug        = g_cvThrowableDebug.BoolValue;
    g_bThrowableHud          = g_cvThrowableHud.BoolValue;
    g_bThrowableCoverage = g_cvThrowableCoverage.BoolValue;

    g_bLaserSightEnable         = g_cvLaserSightEnable.BoolValue;
    g_fLaserSightRadius         = g_cvLaserSightRadius.FloatValue;
    g_fLaserSightRadiusIgnore   = g_cvLaserSightRadiusIgnore.FloatValue;
    g_bLaserSightChanceFlowRoll = g_cvLaserSightChanceFlowRoll.BoolValue;
    g_iLaserSightChance         = g_cvLaserSightChance.IntValue;
    g_bLaserSightDebug          = g_cvLaserSightDebug.BoolValue;
    g_bLaserSightHud            = g_cvLaserSightHud.BoolValue;

    g_bUpgradePackEnable       = g_cvUpgradePackEnable.BoolValue;
    g_fUpgradePackRadius       = g_cvUpgradePackRadius.FloatValue;
    g_fUpgradePackRadiusIgnore = g_cvUpgradePackRadiusIgnore.FloatValue;
    g_iUpgradePackChance       = g_cvUpgradePackChance.IntValue;
    g_bUpgradePackDebug        = g_cvUpgradePackDebug.BoolValue;
    g_bUpgradePackHud          = g_cvUpgradePackHud.BoolValue;

    g_bBondingEnable   = g_cvBondingEnable.BoolValue;
    g_fBondingInterval = g_cvBondingInterval.FloatValue;
    g_fBondingFraction = g_cvBondingFraction.FloatValue;
    g_fBondingThreshold = g_cvBondingThreshold.FloatValue;
    g_fBondingMissCooldown = g_cvBondingMissCooldown.FloatValue;
    g_iBondingMissCooldownClear = g_cvBondingMissCooldownClear.IntValue;
    g_bBondingDecayEnable    = g_cvBondingDecayEnable.BoolValue;
    g_fBondingDecayInterval  = g_cvBondingDecayInterval.FloatValue;
    g_fBondingDecayThreshold = g_cvBondingDecayThreshold.FloatValue;
    g_bBondingMissCooldownClearFailed   = g_cvBondingMissCooldownClearFailed.BoolValue;
    g_bBondingDebug    = g_cvBondingDebug.BoolValue;
    g_bBondingHud = g_cvBondingHud.BoolValue;
    g_fFinaleIgnoreRadius = g_cvFinaleIgnoreRadius.FloatValue;

    UpdateAllowedGameMode();

    if (g_hCvar_PillsDecay != null)
    g_fCvar_PillsDecay = g_hCvar_PillsDecay.FloatValue;

    if (g_fWeaponAmmoPercent > 100.0) g_fWeaponAmmoPercent = 100.0;

    if (g_fReplaceRadius < 1.0) g_fReplaceRadius = 1.0;
    if (g_fWeaponRadius < 1.0) g_fWeaponRadius = 1.0;
    if (g_fWeaponRadiusIgnore < 0.0) g_fWeaponRadiusIgnore = 0.0;
    if (g_fMedkitRadius < 1.0) g_fMedkitRadius = 1.0;
    if (g_fMedkitRadiusIgnore < 0.0) g_fMedkitRadiusIgnore = 0.0;
    if (g_fCabinetRadius < 1.0) g_fCabinetRadius = 1.0;
    if (g_fFailCooldown < 0.0) g_fFailCooldown = 0.0;
    if (g_fCleanupRadius < 1.0) g_fCleanupRadius = 1.0;
    if (g_fCleanupDelay < 1.0) g_fCleanupDelay = 1.0;
    if (g_fConditionFlowMin < 1.0) g_fConditionFlowMin = 1.0;
    if (g_fConditionFlowMax < g_fConditionFlowMin) g_fConditionFlowMax = g_fConditionFlowMin;
    if (g_iConditionMaxMeds < 0) g_iConditionMaxMeds = 0;
    if (g_fBypassCooldown < 0.0) g_fBypassCooldown = 0.0;
    if (g_fTempHealthRadius < 0.0) g_fTempHealthRadius = 0.0;
    if (g_fDefibRadius < 1.0) g_fDefibRadius = 1.0;
    if (g_fDefibRadiusIgnore < 0.0) g_fDefibRadiusIgnore = 0.0;
    if (g_fDefibFlowMin < 1.0) g_fDefibFlowMin = 1.0;
    if (g_fDefibFlowMax < g_fDefibFlowMin) g_fDefibFlowMax = g_fDefibFlowMin;
    if (g_fSaferoomIgnoreRadius < 0.0) g_fSaferoomIgnoreRadius = 0.0;

    if (g_fProposeInitialMin > g_fProposeInitialMax) g_fProposeInitialMax = g_fProposeInitialMin;
    if (g_fProposeMin > g_fProposeMax) g_fProposeMax = g_fProposeMin;
    if (g_fAmmoRadius < 1.0) g_fAmmoRadius = 1.0;
    if (g_fAmmoRadiusIgnore < 0.0) g_fAmmoRadiusIgnore = 0.0;
    if (g_fAmmoThreshold > 100.0) g_fAmmoThreshold = 100.0;
    if (g_fTempHealthSpawnIgnoreRadius < 0.0) g_fTempHealthSpawnIgnoreRadius = 0.0;
    if (g_fTempHealthSpawnFlowMin > g_fTempHealthSpawnFlowMax) g_fTempHealthSpawnFlowMax = g_fTempHealthSpawnFlowMin;
    if (g_fThrowableRadius < 1.0) g_fThrowableRadius = 1.0;
    if (g_fThrowableRadiusIgnore < 0.0) g_fThrowableRadiusIgnore = 0.0;
    if (g_fThrowableFlowMin > g_fThrowableFlowMax) g_fThrowableFlowMax = g_fThrowableFlowMin;
    if (g_fLaserSightRadius < 1.0) g_fLaserSightRadius = 1.0;
    if (g_fLaserSightRadiusIgnore < 0.0) g_fLaserSightRadiusIgnore = 0.0;
    if (g_iLaserSightChance < 0) g_iLaserSightChance = 0;
    if (g_iLaserSightChance > 100) g_iLaserSightChance = 100;
    if (g_fUpgradePackRadiusIgnore < 0.0) g_fUpgradePackRadiusIgnore = 0.0;
    if (g_iUpgradePackChance < 0) g_iUpgradePackChance = 0;
    if (g_iUpgradePackChance > 100) g_iUpgradePackChance = 100;
    if (g_fUpgradePackRadius < 0.0) g_fUpgradePackRadius = 0.0;
    if (g_fBondingInterval <= 0.0) g_fBondingInterval = 1.0;
    g_fBondingIncrementPerSecond = 0.1 / g_fBondingInterval;
    if (g_fBondingThreshold < 0.0) g_fBondingThreshold = 0.0;
    if (g_fBondingThreshold > 1.0) g_fBondingThreshold = 1.0;
    if (g_fBondingMissCooldown < 0.0) g_fBondingMissCooldown = 0.0;
    if (g_fFinaleIgnoreRadius < 0.0) g_fFinaleIgnoreRadius = 0.0;
    if (g_fBondingDecayInterval < 1.0) g_fBondingDecayInterval = 1.0;
    if (g_fBondingDecayThreshold < 0.0) g_fBondingDecayThreshold = 0.0;
    if (g_fBondingDecayThreshold > g_fBondingThreshold) g_fBondingDecayThreshold = g_fBondingThreshold;
    g_fBondingDecayPerSecond = 0.1 / g_fBondingDecayInterval;
}

void UpdateAllowedGameMode()
{
    g_bModeAllowed = true;
    if (g_cvAllowedModes == null) return;

    char list[256];
    g_cvAllowedModes.GetString(list, sizeof(list));
    TrimString(list);
    if (!list[0]) return;

    if (g_hMPGameMode == null)
    g_hMPGameMode = FindConVar("mp_gamemode");

    if (g_hMPGameMode == null)
    {
        g_bModeAllowed = false;
        return;
    }

    char currentMode[64];
    g_hMPGameMode.GetString(currentMode, sizeof(currentMode));
    TrimString(currentMode);

    char hay[320], needle[96];
    Format(hay, sizeof(hay), ",%s,", list);
    Format(needle, sizeof(needle), ",%s,", currentMode);

    g_bModeAllowed = (StrContains(hay, needle, false) != -1);
}

void ManageTimers()
{
    if (g_hProximityTimer != null) { KillTimer(g_hProximityTimer); g_hProximityTimer = null; }
    if (g_hCleanupTimer != null) { KillTimer(g_hCleanupTimer); g_hCleanupTimer = null; }
    if (g_hConditionTimer != null) { KillTimer(g_hConditionTimer); g_hConditionTimer = null; }
    if (g_hConditionHudTimer != null) { KillTimer(g_hConditionHudTimer); g_hConditionHudTimer = null; }
    if (g_hDefibHudTimer != null) { KillTimer(g_hDefibHudTimer); g_hDefibHudTimer = null; }
    if (g_hHealthTimer != null) { KillTimer(g_hHealthTimer); g_hHealthTimer = null; }
    if (g_hWeaponHudTimer != null) { KillTimer(g_hWeaponHudTimer); g_hWeaponHudTimer = null; }
    if (g_hProposeHudTimer != null) { KillTimer(g_hProposeHudTimer); g_hProposeHudTimer = null; }
    if (g_hAmmoHudTimer != null) { KillTimer(g_hAmmoHudTimer); g_hAmmoHudTimer = null; }
    if (g_hTempHealthSpawnHudTimer != null) { KillTimer(g_hTempHealthSpawnHudTimer); g_hTempHealthSpawnHudTimer = null; }
    if (g_hThrowableHudTimer != null) { KillTimer(g_hThrowableHudTimer); g_hThrowableHudTimer = null; }
    if (g_hLaserSightHudTimer != null) { KillTimer(g_hLaserSightHudTimer); g_hLaserSightHudTimer = null; }
    if (g_hUpgradePackHudTimer != null) { KillTimer(g_hUpgradePackHudTimer); g_hUpgradePackHudTimer = null; }
    if (g_hBondingTimer != null) { KillTimer(g_hBondingTimer); g_hBondingTimer = null; }
    if (g_hBondingHudTimer != null) { KillTimer(g_hBondingHudTimer); g_hBondingHudTimer = null; }

    if (!g_bEnabled || !g_bModeAllowed) return;

    if (g_bEnabled && (g_bWeaponEnable || (g_bConditionEnable && g_bMedkitEnable && g_fBypassCooldown > 0.0)))
    g_hProximityTimer = CreateTimer(0.5, Timer_CheckProximity, _, TIMER_REPEAT);

    if (g_bEnabled && g_bCleanupEnable) {
    g_hCleanupTimer = CreateTimer(5.0, Timer_CheckCleanup, _, TIMER_REPEAT);
    g_fLastCleanupCheck = GetGameTime();
    }

    if (g_bEnabled && (g_bConditionEnable || g_bDefibEnable)) {
    g_hConditionTimer = CreateTimer(1.0, Timer_CheckCondition, _, TIMER_REPEAT);
    if (g_bConditionHud)
    g_hConditionHudTimer = CreateTimer(1.0, Timer_UpdateHud, _, TIMER_REPEAT);
    if (g_bDefibHud)
    g_hDefibHudTimer = CreateTimer(1.0, Timer_UpdateDefibHud, _, TIMER_REPEAT);
    }

    if (g_bEnabled && g_bHealthDebug)
    g_hHealthTimer = CreateTimer(2.0, Timer_DumpHealth, _, TIMER_REPEAT);

    if (g_bWeaponHud) {
    if (g_hWeaponHudTimer != null) KillTimer(g_hWeaponHudTimer);
    g_hWeaponHudTimer = CreateTimer(1.0, Timer_UpdateWeaponHud, _, TIMER_REPEAT);
    } else {
    if (g_hWeaponHudTimer != null) { KillTimer(g_hWeaponHudTimer); g_hWeaponHudTimer = null; }
    }

    // Propose HUD
    if (g_hProposeHudTimer != null) { KillTimer(g_hProposeHudTimer); g_hProposeHudTimer = null; }
    if (g_bWeaponPropose && g_bProposeHud)
    g_hProposeHudTimer = CreateTimer(1.0, Timer_UpdateProposeHud, _, TIMER_REPEAT);

    // Ammo HUD
    if (g_hAmmoHudTimer != null) { KillTimer(g_hAmmoHudTimer); g_hAmmoHudTimer = null; }
    if (g_bAmmoEnable && g_bAmmoHud)
    g_hAmmoHudTimer = CreateTimer(1.0, Timer_UpdateAmmoHud, _, TIMER_REPEAT);

    // Temp health spawn HUD
    if (g_hTempHealthSpawnHudTimer != null) { KillTimer(g_hTempHealthSpawnHudTimer); g_hTempHealthSpawnHudTimer = null; }
    if (g_bTempHealthSpawnEnable && g_bTempHealthSpawnHud)
    g_hTempHealthSpawnHudTimer = CreateTimer(1.0, Timer_UpdateTempHealthSpawnHud, _, TIMER_REPEAT);

    // Throwable HUD
    if (g_hThrowableHudTimer != null) { KillTimer(g_hThrowableHudTimer); g_hThrowableHudTimer = null; }
    if (g_bThrowableEnable && g_bThrowableHud)
    g_hThrowableHudTimer = CreateTimer(1.0, Timer_UpdateThrowableHud, _, TIMER_REPEAT);

    // Laser‑sight HUD
    if (g_hLaserSightHudTimer != null) { KillTimer(g_hLaserSightHudTimer); g_hLaserSightHudTimer = null; }
    if (g_bLaserSightEnable && g_bLaserSightHud)
    g_hLaserSightHudTimer = CreateTimer(1.0, Timer_UpdateLaserSightHud, _, TIMER_REPEAT);

    // Upgrade-pack HUD
    if (g_hUpgradePackHudTimer != null) { KillTimer(g_hUpgradePackHudTimer); g_hUpgradePackHudTimer = null; }
    if (g_bUpgradePackEnable && g_bUpgradePackHud)
    g_hUpgradePackHudTimer = CreateTimer(1.0, Timer_UpdateUpgradePackHud, _, TIMER_REPEAT);

    // Weapon Bonding timer
    if (g_hBondingTimer != null) { KillTimer(g_hBondingTimer); g_hBondingTimer = null; }
    if (g_bEnabled && g_bBondingEnable)
    g_hBondingTimer = CreateTimer(1.0, Timer_BondingTick, _, TIMER_REPEAT);

    // Bonding HUD timer
    if (g_hBondingHudTimer != null) { KillTimer(g_hBondingHudTimer); g_hBondingHudTimer = null; }
    if (g_bEnabled && g_bBondingEnable && g_bBondingHud)
    g_hBondingHudTimer = CreateTimer(1.0, Timer_UpdateBondingHud, _, TIMER_REPEAT);
}
void LogDebug(const char[] format, any ...)
{
    if (!g_bDebug && !g_bConditionDebug && !g_bHealthDebug && !g_bDefibDebug && !g_bWeaponDebug) return;
    char buffer[512];
    VFormat(buffer, sizeof(buffer), format, 2);
    LogToFileEx(g_sLogPath, "%s", buffer);
}

void LogHealth(const char[] format, any ...)
{
    if (!g_bHealthDebug) return;
    char buffer[512];
    VFormat(buffer, sizeof(buffer), format, 2);
    LogToFileEx(g_sLogPath, "%s", buffer);
}

// Health trace events
void Event_ItemPickup(Event event, const char[] name, bool dontBroadcast)
{
    g_fLastItemPickupTime = GetGameTime();
    if (!g_bHealthDebug) return;
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2) return;
    char item[64];
    event.GetString("item", item, sizeof(item));
    char cname[64];
    GetClientName(client, cname, sizeof(cname));
    LogHealth("[HEALTH] %s picked up %s", cname, item);
}

void Event_WeaponDrop(Event event, const char[] name, bool dontBroadcast)
{
    g_fLastItemPickupTime = GetGameTime();

    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
    return;

    // If decay is enabled, record the drop time for the weapon entity
    if (g_bBondingDecayEnable)
    {
        // Find the dropped weapon
        char sWeaponClass[64];
        event.GetString("weapon", sWeaponClass, sizeof(sWeaponClass));

        float vClientOrigin[3];
        GetClientAbsOrigin(client, vClientOrigin);

        int ent = -1;
        while ((ent = FindEntityByClassname(ent, sWeaponClass)) != -1)
        {
            if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1)
            continue;

            float vEnt[3];
            GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vEnt);
            if (GetVectorDistance(vClientOrigin, vEnt) <= 100.0)
            {
                int character = GetEntProp(client, Prop_Send, "m_survivorCharacter");
                if (character >= 0 && character <= 3)
                {
                    g_fWeaponLastDropTime[character][ent] = GetGameTime();

                    if (g_bBondingDebug)
                    LogToFileEx(g_sLogPath, "[Bonding] Decay start: char %d weapon %d (%s)",
                    character, ent, sWeaponClass);
                }
                break;
            }
        }
    }
}

void Event_PillsUsed(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
    g_bHasItemTempHealth[client] = true;

    if (!g_bHealthDebug) return;
    char cname[64];
    GetClientName(client, cname, sizeof(cname));
    LogHealth("[HEALTH] %s used pain pills", cname);
}

void Event_AdrenalineUsed(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
    g_bHasItemTempHealth[client] = true;

    if (!g_bHealthDebug) return;
    char cname[64];
    GetClientName(client, cname, sizeof(cname));
    LogHealth("[HEALTH] %s used adrenaline", cname);
}

void Event_HealBegin(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bHealthDebug) return;
    int healer = GetClientOfUserId(event.GetInt("userid"));
    int subject = GetClientOfUserId(event.GetInt("subject"));
    if (healer <= 0 || !IsClientInGame(healer) || GetClientTeam(healer) != 2) return;
    char hname[64], sname[64];
    GetClientName(healer, hname, sizeof(hname));
    GetClientName(subject, sname, sizeof(sname));
    LogHealth("[HEALTH] %s started healing %s", hname, sname);
}

void Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bHealthDebug) return;
    int healer = GetClientOfUserId(event.GetInt("userid"));
    int subject = GetClientOfUserId(event.GetInt("subject"));
    if (healer <= 0 || !IsClientInGame(healer) || GetClientTeam(healer) != 2) return;
    char hname[64], sname[64];
    GetClientName(healer, hname, sizeof(hname));
    GetClientName(subject, sname, sizeof(sname));
    LogHealth("[HEALTH] %s finished healing %s", hname, sname);
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bHealthDebug) return;
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int dmg = event.GetInt("dmg_health");
    if (victim <= 0 || !IsClientInGame(victim) || GetClientTeam(victim) != 2) return;
    char vname[64];
    GetClientName(victim, vname, sizeof(vname));
    char aname[64] = "world";
    if (attacker > 0 && IsClientInGame(attacker))
    GetClientName(attacker, aname, sizeof(aname));
    int remaining = GetClientHealth(victim);
    LogHealth("[HEALTH] %s took %d damage from %s (remaining %d)", vname, dmg, aname, remaining);
}

void Event_UpgradePackUsed(Event event, const char[] name, bool dontBroadcast)
{
    if (event.GetInt("upgrade_id") != 2) return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2) return;

    if (g_bBondingDebug)
    {
        int weapon = GetPlayerWeaponSlot(client, 0);
        char wname[64];
        if (weapon != -1 && IsValidEntity(weapon))
        GetEdictClassname(weapon, wname, sizeof(wname));
        else
        wname = "unknown";
        LogToFileEx(g_sLogPath, "[Bonding] PICKUP – Client %d applied laser to weapon %d (%s)",
        client, weapon, wname);
    }
}

public Action Timer_DumpHealth(Handle timer)
{
    if (!g_bEnabled || !g_bHealthDebug) return Plugin_Continue;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
        {
            int real = GetClientHealth(i);
            float buf = GetEntPropFloat(i, Prop_Send, "m_healthBuffer");
            float bufTime = GetEntPropFloat(i, Prop_Send, "m_healthBufferTime");
            float curBuf = buf;
            if (buf > 0.0 && bufTime > 0.0)
            {
                curBuf = buf - g_fCvar_PillsDecay * (GetGameTime() - bufTime);
                if (curBuf < 0.0) curBuf = 0.0;
            }
            int total = real + RoundToCeil(curBuf);
            if (total > 100) total = 100;
            char cname[64];
            GetClientName(i, cname, sizeof(cname));
            LogHealth("[HEALTH] %s : real=%d buffer=%.0f total=%d %s",
            cname, real, curBuf, total,
            (real > 40) ? "H" : ((total > 40) ? "I" : "C"));
        }
    }
    return Plugin_Continue;
}

void OnFramePrecomputeSaferoom()
{
    if (!g_bEnabled || !L4D_HasMapStarted()) return;

    for (int i = 0; i < g_iSpawnerCount; i++)
    g_bNearSaferoom[i] = false;

    if (g_fSaferoomIgnoreRadius <= 0.0) return;

    ArrayList navs = new ArrayList();
    L4D_GetAllNavAreas(navs);
    float vAreaCenter[3];

    for (int i = 0; i < navs.Length; i++)
    {
        Address nav = view_as<Address>(navs.Get(i));
        int spawnFlags = L4D_GetNavArea_SpawnAttributes(nav);
        if (!(spawnFlags & NAV_SPAWN_CHECKPOINT))
        continue;

        L4D_GetNavAreaCenter(nav, vAreaCenter);

        for (int j = 0; j < g_iSpawnerCount; j++)
        {
            if (!g_bNearSaferoom[j] &&
            GetVectorDistance(g_vSpawnerPos[j], vAreaCenter) <= g_fSaferoomIgnoreRadius)
            {
            g_bNearSaferoom[j] = true;
            }
        }
    }
    delete navs;

    LogDebug("Saferoom proximity: radius %.0f precomputed", g_fSaferoomIgnoreRadius);
}

void OnFramePrecomputeFinale()
{
    if (!g_bEnabled || !L4D_HasMapStarted()) return;

    for (int i = 0; i < g_iSpawnerCount; i++)
    g_bNearFinale[i] = false;

    if (g_fFinaleIgnoreRadius <= 0.0) return;

    ArrayList navs = new ArrayList();
    L4D_GetAllNavAreas(navs);
    float vAreaCenter[3];

    for (int i = 0; i < navs.Length; i++)
    {
        Address nav = view_as<Address>(navs.Get(i));

        // Check the same flag that L4D_IsNavArea_Final would use
        int spawnFlags = L4D_GetNavArea_SpawnAttributes(nav);
        if (!(spawnFlags & NAV_SPAWN_FINALE))
        continue;

        L4D_GetNavAreaCenter(nav, vAreaCenter);

        for (int j = 0; j < g_iSpawnerCount; j++)
        {
            if (!g_bNearFinale[j] &&
                GetVectorDistance(g_vSpawnerPos[j], vAreaCenter) <= g_fFinaleIgnoreRadius)
            {
                g_bNearFinale[j] = true;
            }
        }
    }
    delete navs;

    LogDebug("Finale proximity: radius %.0f precomputed", g_fFinaleIgnoreRadius);
}

void ResetBondingMissCooldown(bool bMapStart, bool bCampaignStart)
{
    int mode = g_iBondingMissCooldownClear;
    if (mode == 3) return;                                          

    bool bClear = false;
    if (mode == 0) bClear = true;                                   
    else if (mode == 1 && bMapStart) bClear = true;                 
    else if (mode == 2 && bCampaignStart) bClear = true;            

    if (!bClear) return;

    for (int i = 0; i < 4; i++)
    {
        g_fBondingMissCooldownUntil[i] = 0.0;
        g_bCharNearLaser[i] = false;
    }

    if (g_bBondingDebug)
    LogToFileEx(g_sLogPath, "[Bonding] Miss cooldown arrays cleared (mode=%d, mapStart=%d, campaignStart=%d)",
    mode, bMapStart, bCampaignStart);
}

public void OnMapStart()
{
    ResetAllState();              
    g_bLeftSafeArea = false;

    ApplyCvars();
    ManageTimers();

    if (!g_bEnabled) return;

    g_iSpawnPointMode = g_cvSpawnPointMode.IntValue;

    if (g_iSpawnPointMode == 2)
    CacheAllSpawners();
    else
    CachePillSpawners();

    PrecomputeCabinetProximity();
    RequestFrame(OnFramePrecomputeSaferoom);
    RequestFrame(OnFramePrecomputeFinale);
    PrecacheModel("models/w_models/Weapons/w_laser_sights.mdl", true);

    ResetProposeInitial(true, L4D_IsFirstMapInScenario());
    if (!g_bProposeInitialDone || g_iProposeInitialSpawned > 0)
    {
        if (g_fProposeRemaining > 0.0)
        {
            float curFlow = GetLeadingSurvivorFlow();
            g_fProposeNextFlow = curFlow + g_fProposeRemaining;
            if (g_bProposeDebug)
            LogDebug("MapStart: Propose remaining %.0f, new nextFlow=%.0f (curFlow=%.0f)", g_fProposeRemaining, g_fProposeNextFlow, curFlow);
        }
    }
    if (g_bProposeInitialDone) g_fProposeNextFlow = -1.0;
    ResetMedkitInitial(true, L4D_IsFirstMapInScenario());

    // Weapon Bonding carryover
    if (g_bBondingEnable)
    {
        if (L4D_IsFirstMapInScenario())
        {
            for (int i = 0; i < 4; i++)
            {
                g_fCarryoverBonding[i] = 0.0;
                g_sCarryoverWeaponClass[i][0] = '\0';
                g_fMapStartBonding[i] = 0.0;
            }
            // clear bonding‑laser‑given flags at campaign start
            for (int i = 0; i < 4; i++)
            g_bBondingLaserGiven[i] = false;

            if (g_bBondingDebug)
            LogToFileEx(g_sLogPath, "[Bonding] Campaign start – bonding carryover and laser‑given flags cleared.");
        }
        else
        {
            for (int i = 0; i < 4; i++)
            {
                g_fMapStartBonding[i] = g_fCarryoverBonding[i];
                g_bPendingCarryover[i] = true;
            }

            if (g_bBondingDebug)
            LogToFileEx(g_sLogPath, "[Bonding] Map transition – pending carryover queued: %.2f %.2f %.2f %.2f",
            g_fCarryoverBonding[0], g_fCarryoverBonding[1],
            g_fCarryoverBonding[2], g_fCarryoverBonding[3]);
        }

        // Miss cooldown clearing
        ResetBondingMissCooldown(true, L4D_IsFirstMapInScenario());
    }

    g_bFirstRoundOnMap = true;
    for (int i = 0; i < 4; i++)
        g_bMissCooldownSetThisMap[i] = false;

    LogDebug("Map Start: Cached %d spawn positions (mode %d)", g_iSpawnerCount, g_iSpawnPointMode);
}

public void OnMapEnd()
{
    ResetAllState();
    g_bLeftSafeArea = false;
}

void ResetAllState()
{
    g_iSpawnerCount = 0;
    for (int i = 0; i < 2048; i++)
    {
        g_bUsedIndex[i] = false;
        g_bWeaponSpawned[i] = false;
        g_bMedkitSpawned[i] = false;
        g_bDefibSpawned[i] = false;
        g_bNearCabinet[i] = false;
        g_bNearSaferoom[i] = false;
        g_bNearFinale[i] = false;
        g_fLastVisibilityFail[i] = 0.0;
        g_fBypassTime[i] = 0.0;
        g_bTempHealthSpawned[i] = false;
        g_bThrowableSpawned[i] = false;
        g_bLaserSightSpawned[i] = false;
        g_bUpgradePackSpawned[i] = false;         
        g_sWeaponEntityClass[i][0] = '\0';
    }

    // Weapon bonding per‑map clear
    for (int c = 0; c < 4; c++)
    {
        for (int i = 0; i < 2048; i++)
        {
            g_fWeaponBondingChar[c][i] = 0.0;
            g_fWeaponLastDropTime[c][i] = 0.0;
        }
    }

    ClearCleanupTracking();
    g_iCondition = 0;
    g_iLastCondition = -1;
    g_fNextSpawnFlow = -1.0;
    g_iPendingSpawns = 0;
    g_iInitialKitsGiven = 0;
    g_fNextDefibFlow = -1.0;
    g_iTeleportIndex = 0;
    g_iTeleportTempIndex = 0;
    g_iTeleportDefibIndex = 0;
    g_iTeleportWeaponIndex = 0;

    g_bPendingMedkitSpawn = false;
    g_iPendingMedkitCount = 0;
    g_bPendingDefibSpawn   = false;
    g_iPendingDefibCount   = 0;

    g_fTempHealthSpawnNextFlow = -1.0;
    g_bTempHealthSpawnPending  = false;

    g_fThrowableNextFlow = -1.0;
    g_bThrowablePending = false;

    g_fLaserSightNextFlow = -1.0;
    g_bLaserSightPending = false;

    g_fUpgradePackNextFlow = -1.0;                 
    g_bUpgradePackPending = false;                 

    // Weapon bonding – per‑client ready flags and pending
    for (int i = 1; i <= MaxClients; i++)
    g_bPlayerBondingReady[i] = false;
    g_bBondingLaserPending = false;

    for (int i = 1; i <= MaxClients; i++)
    g_bHasItemTempHealth[i] = false;
}

void ClearCleanupTracking()
{
    g_aCleanupItems.Clear();
    g_aCleanupTimers.Clear();
    g_aCleanupIndex.Clear();
    g_aCleanupType.Clear();
}

void CachePillSpawners()
{
    int maxEnts = GetMaxEntities();
    char classname[64];
    for (int entity = MaxClients + 1; entity <= maxEnts; entity++)
    {
        if (!IsValidEntity(entity)) continue;
        GetEdictClassname(entity, classname, sizeof(classname));

        if (StrEqual(classname, "weapon_pain_pills_spawn") ||
        StrEqual(classname, "weapon_adrenaline_spawn"))
        {
            CacheSpawnerPosition(entity);
        }
        else if (StrEqual(classname, "weapon_item_spawn"))
        {
            char sItem[32];
            if (GetItemSpawnerType(entity, sItem, sizeof(sItem)) &&
            (StrEqual(sItem, "pain_pills", false) || StrEqual(sItem, "adrenaline", false)))
            {
                CacheSpawnerPosition(entity);
            }
        }
    }
}

void CacheAllSpawners()
{
    int maxEnts = GetMaxEntities();
    char classname[64];
    for (int entity = MaxClients + 1; entity <= maxEnts; entity++)
    {
        if (!IsValidEntity(entity)) continue;
        GetEdictClassname(entity, classname, sizeof(classname));
        if (StrContains(classname, "weapon_") == 0 && StrContains(classname, "_spawn") != -1)
        {
            CacheSpawnerPosition(entity);
        }
    }
}

void CacheSpawnerPosition(int entity)
{
    if (g_iSpawnerCount < sizeof(g_vSpawnerPos))
    {
        GetEntPropVector(entity, Prop_Data, "m_vecOrigin",   g_vSpawnerPos[g_iSpawnerCount]);
        GetEntPropVector(entity, Prop_Data, "m_angRotation", g_vSpawnerAng[g_iSpawnerCount]);
        g_fBypassTime[g_iSpawnerCount] = 0.0;
        g_iSpawnerCount++;
    }
}

bool GetItemSpawnerType(int entity, char[] buffer, int maxlen)
{
    static int offsItem = -1;
    if (offsItem == -1)
    offsItem = FindDataMapInfo(entity, "m_iszItem");
    if (offsItem == -1)
    return false;
    return GetEntPropString(entity, Prop_Data, "m_iszItem", buffer, maxlen) > 0;
}

void PrecomputeCabinetProximity()
{
    ArrayList cabinets = new ArrayList(3);
    int cabinet = -1;
    float vCabOrigin[3];
    while ((cabinet = FindEntityByClassname(cabinet, "prop_health_cabinet")) != -1)
    {
        GetEntPropVector(cabinet, Prop_Data, "m_vecOrigin", vCabOrigin);
        cabinets.Push(vCabOrigin[0]);
        cabinets.Push(vCabOrigin[1]);
        cabinets.Push(vCabOrigin[2]);
    }
    int cabCount = cabinets.Length / 3;
    for (int i = 0; i < g_iSpawnerCount; i++)
    {
        g_bNearCabinet[i] = false;
        for (int j = 0; j < cabCount; j++)
        {
            vCabOrigin[0] = cabinets.Get(j*3);
            vCabOrigin[1] = cabinets.Get(j*3 + 1);
            vCabOrigin[2] = cabinets.Get(j*3 + 2);
            if (GetVectorDistance(g_vSpawnerPos[i], vCabOrigin) <= g_fCabinetRadius)
            {
                g_bNearCabinet[i] = true;
                break;
            }
        }
    }
    delete cabinets;
}

public Action Timer_RoundStart_Bonding(Handle timer)
{
    if (!g_bEnabled || !g_bBondingEnable)
    return Plugin_Stop;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
        {
            int character = GetEntProp(client, Prop_Send, "m_survivorCharacter");
            if (character < 0 || character > 3) continue;

            int weapon = GetPlayerWeaponSlot(client, 0);
            if (weapon != -1 && IsValidEntity(weapon))
            {
                g_fWeaponBondingChar[character][weapon] = g_fMapStartBonding[character];

                if (g_bBondingDebug)
                LogToFileEx(g_sLogPath, "[Bonding] RoundStart: char %d weapon %d reset to %.2f (mapStartBonding was %.2f)",
                character, weapon, g_fWeaponBondingChar[character][weapon], g_fMapStartBonding[character]);
            }
            else
            {
                if (g_bBondingDebug)
                LogToFileEx(g_sLogPath, "[Bonding] RoundStart: char %d has no valid primary weapon (weapon=%d)", character, weapon);
            }
        }
    }
    g_bBondingLaserPending = false;
    return Plugin_Stop;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    for (int i = 0; i < g_iSpawnerCount; i++)
    {
        g_bUsedIndex[i] = false;
        g_bWeaponSpawned[i] = false;
        g_bMedkitSpawned[i] = false;
        g_bDefibSpawned[i] = false;
        g_fLastVisibilityFail[i] = 0.0;
        g_fBypassTime[i] = 0.0;
        g_bTempHealthSpawned[i] = false;
        g_bThrowableSpawned[i] = false;
        g_bLaserSightSpawned[i] = false;
        g_bUpgradePackSpawned[i] = false;
        g_bNearSaferoom[i] = false;
        g_bNearFinale[i] = false;           
    }

    for (int c = 0; c < 4; c++)
    {
        for (int i = 0; i < 2048; i++)
        {
            g_fWeaponBondingChar[c][i] = 0.0;
            g_fWeaponLastDropTime[c][i] = 0.0;
        }
    }
    for (int i = 0; i < 2048; i++)
        g_sWeaponEntityClass[i][0] = '\0';

    for (int i = 1; i <= MaxClients; i++)
        g_bPlayerBondingReady[i] = false;
    g_bBondingLaserPending = false;

    ClearCleanupTracking();
    
    g_bLeftSafeArea = false;
    if (L4D_HasAnySurvivorLeftSafeArea())
    {
        g_bLeftSafeArea = true;
    }
    
    g_iCondition = 0;
    g_iLastCondition = -1;
    g_fNextSpawnFlow = -1.0;
    g_iPendingSpawns = 0;
    g_iInitialKitsGiven = 0;
    g_fNextDefibFlow = -1.0;
    g_iTeleportIndex = 0;
    g_iTeleportTempIndex = 0;
    g_iTeleportDefibIndex = 0;
    g_iTeleportWeaponIndex = 0;

    g_bPendingMedkitSpawn = false;
    g_iPendingMedkitCount = 0;
    g_bPendingDefibSpawn   = false;
    g_iPendingDefibCount   = 0;

    g_iSpawnerCount = 0;
    if (g_iSpawnPointMode == 2)
        CacheAllSpawners();
    else
        CachePillSpawners();

    PrecomputeCabinetProximity();
    RequestFrame(OnFramePrecomputeSaferoom);
    RequestFrame(OnFramePrecomputeFinale);

    ResetProposeInitial(false, false);
    if (g_iProposeInitialClear == 0) ClearProposeInitial();
    ResetMedkitInitial(false, false);
    if (g_iConditionInitialClear == 0) ClearMedkitInitial();

    g_fTempHealthSpawnNextFlow = -1.0;
    g_bTempHealthSpawnPending  = false;

    g_fThrowableNextFlow = -1.0;
    g_bThrowablePending = false;

    g_fLaserSightNextFlow = -1.0;
    g_bLaserSightPending = false;

    g_fUpgradePackNextFlow = -1.0;                
    g_bUpgradePackPending = false;                

    for (int i = 1; i <= MaxClients; i++)
        g_bHasItemTempHealth[i] = false;

    // Weapon Bonding round‑start reset
    if (g_bBondingEnable)
    {
        CreateTimer(2.0, Timer_RoundStart_Bonding, _, TIMER_FLAG_NO_MAPCHANGE);
    }

    // Weapon Bonding miss cooldown clearing
    if (g_bBondingEnable)
    {
        ResetBondingMissCooldown(false, false);
    }

    // Reset near‑laser flag to prevent false miss cooldown after a wipe
    if (g_bBondingEnable)
    {
        for (int i = 0; i < 4; i++)
            g_bCharNearLaser[i] = false;
    }

    for (int i = 0; i < 4; i++)
        g_bMissCooldownSetThisMap[i] = false;

    LogDebug("Round Start: Reset all state, re‑cached %d spawn points (mode %d)", g_iSpawnerCount, g_iSpawnPointMode);
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    for (int i = 0; i < g_iSpawnerCount; i++)
    {
        g_bUsedIndex[i] = false;
        g_bWeaponSpawned[i] = false;
        g_bMedkitSpawned[i] = false;
        g_bDefibSpawned[i] = false;
        g_fLastVisibilityFail[i] = 0.0;
        g_fBypassTime[i] = 0.0;
        g_bTempHealthSpawned[i] = false;
        g_bThrowableSpawned[i] = false;
        g_bLaserSightSpawned[i] = false;
        g_bUpgradePackSpawned[i] = false;           
    }

    ClearCleanupTracking();
    g_bLeftSafeArea = false;
    g_iCondition = 0;
    g_iLastCondition = -1;
    g_fNextSpawnFlow = -1.0;
    g_iPendingSpawns = 0;
    g_iInitialKitsGiven = 0;
    g_fNextDefibFlow = -1.0;
    g_iTeleportIndex = 0;
    g_iTeleportTempIndex = 0;
    g_iTeleportDefibIndex = 0;
    g_bPendingMedkitSpawn = false;
    g_iPendingMedkitCount = 0;
    g_bPendingDefibSpawn   = false;
    g_iPendingDefibCount   = 0;

    int reason = event.GetInt("reason");
    if (reason == 1)
    {
        if (g_bConditionInitialClearFailed)
            ClearMedkitInitial();
        if (g_bWeaponProposeInitialClearFailed)
            ClearProposeInitial();

        // Clear bonding miss cooldown on mission fail (same‑map only)
        if (g_bBondingMissCooldownClearFailed)
        {
            for (int i = 0; i < 4; i++)
            {
                if (g_bMissCooldownSetThisMap[i])
                {
                    g_fBondingMissCooldownUntil[i] = 0.0;
                    g_bCharNearLaser[i] = false;
                    g_bMissCooldownSetThisMap[i] = false;
                }
            }
        }

        g_bFirstRoundOnMap = false;
    }

    g_fTempHealthSpawnNextFlow = -1.0;
    g_bTempHealthSpawnPending  = false;

    g_fThrowableNextFlow = -1.0;
    g_bThrowablePending = false;

    g_fLaserSightNextFlow = -1.0;
    g_bLaserSightPending = false;

    g_fUpgradePackNextFlow = -1.0;                 
    g_bUpgradePackPending = false;                 

    for (int i = 1; i <= MaxClients; i++)
    g_bHasItemTempHealth[i] = false;

    LogDebug("Round End: Reset all state");
}

void Event_PlayerLeftSafeArea(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bLeftSafeArea)
    {
        g_bLeftSafeArea = true;
        LogDebug("Survivor left safe area – spawning enabled");
    }
}

// Player health state
void GetPlayerHealthState(int client, int &state, bool &hasKit, bool &hasTemp, int &tempBoost)
{
    tempBoost = 0;
    if (GetEntProp(client, Prop_Send, "m_isIncapacitated"))
    {
        state = 2;
        int kitEnt = GetPlayerWeaponSlot(client, 3);
        hasKit = (kitEnt != -1 && IsValidEntity(kitEnt));
        int tempEnt = GetPlayerWeaponSlot(client, 4);
        hasTemp = (tempEnt != -1 && IsValidEntity(tempEnt));
        if (hasTemp)
        {
            char cls[64];
            GetEdictClassname(tempEnt, cls, sizeof(cls));
            if (StrContains(cls, "adrenaline", false) != -1)
            tempBoost = 25;
            else
            tempBoost = 50;
        }
        return;
    }

    int realHealth = GetClientHealth(client);
    float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
    float bufferTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
    float gameTime = GetGameTime();

    float currentBuffer = buffer;
    if (buffer > 0.0 && bufferTime > 0.0)
    {
        currentBuffer = buffer - g_fCvar_PillsDecay * (gameTime - bufferTime);
        if (currentBuffer < 0.0) currentBuffer = 0.0;
    }

    int totalHealth = realHealth + RoundToCeil(currentBuffer);
    if (totalHealth > 100) totalHealth = 100;

    int kitEnt = GetPlayerWeaponSlot(client, 3);
    hasKit = (kitEnt != -1 && IsValidEntity(kitEnt));
    int tempEnt = GetPlayerWeaponSlot(client, 4);
    hasTemp = (tempEnt != -1 && IsValidEntity(tempEnt));
    if (hasTemp)
    {
        char cls[64];
        GetEdictClassname(tempEnt, cls, sizeof(cls));
        if (StrContains(cls, "adrenaline", false) != -1)
        tempBoost = 25;
        else
        tempBoost = 50;
    }

    if (realHealth > 40)
    state = 0;
    else if (totalHealth > 40)
    state = 1;
    else
    state = 2;
}

int CountEffectiveGroundKits()
{
    int count = 0;
    int ent = -1;
    float vKit[3], vSurv[3];
    char name[64];
    float radius = g_fMedkitRadius;

    while ((ent = FindEntityByClassname(ent, "weapon_first_aid_kit")) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vKit);
        bool counted = false;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) continue;
            GetClientAbsOrigin(i, vSurv);
            float dist = GetVectorDistance(vSurv, vKit);
            if (dist <= radius)
            {
                GetClientName(i, name, sizeof(name));
                LogDebug("KitCount: REAL kit %d at (%.0f,%.0f,%.0f) -> counted because survivor '%s' (dist %.0f) is within %.0f",
                ent, vKit[0], vKit[1], vKit[2], name, dist, radius);
                count++;
                counted = true;
                break;
            }
        }
        if (!counted)
        LogDebug("KitCount: REAL kit %d at (%.0f,%.0f,%.0f) -> NO survivor within %.0f",
        ent, vKit[0], vKit[1], vKit[2], radius);
    }

    ent = -1;
    while ((ent = FindEntityByClassname(ent, "weapon_first_aid_kit_spawn")) != -1)
    {
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vKit);
        bool counted = false;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) continue;
            GetClientAbsOrigin(i, vSurv);
            float dist = GetVectorDistance(vSurv, vKit);
            if (dist <= radius)
            {
                GetClientName(i, name, sizeof(name));
                LogDebug("KitCount: SPAWNER %d at (%.0f,%.0f,%.0f) -> counted because survivor '%s' (dist %.0f) is within %.0f",
                ent, vKit[0], vKit[1], vKit[2], name, dist, radius);
                count++;
                counted = true;
                break;
            }
        }
        if (!counted)
        LogDebug("KitCount: SPAWNER %d at (%.0f,%.0f,%.0f) -> NO survivor within %.0f",
         ent, vKit[0], vKit[1], vKit[2], radius);
    }

    ent = -1;
    char sItem[32];
    while ((ent = FindEntityByClassname(ent, "weapon_item_spawn")) != -1)
    {
        if (!GetItemSpawnerType(ent, sItem, sizeof(sItem))) continue;
        if (!StrEqual(sItem, "first_aid_kit", false)) continue;
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vKit);
        bool counted = false;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) continue;
            GetClientAbsOrigin(i, vSurv);
            float dist = GetVectorDistance(vSurv, vKit);
            if (dist <= radius)
            {
                GetClientName(i, name, sizeof(name));
                LogDebug("KitCount: ITEM_SPAWN %d at (%.0f,%.0f,%.0f) -> counted because survivor '%s' (dist %.0f) is within %.0f",
                ent, vKit[0], vKit[1], vKit[2], name, dist, radius);
                count++;
                counted = true;
                break;
            }
        }
        if (!counted)
        LogDebug("KitCount: ITEM_SPAWN %d at (%.0f,%.0f,%.0f) -> NO survivor within %.0f",
        ent, vKit[0], vKit[1], vKit[2], radius);
    }

    return count;
}

void CountEffectiveGroundTemps(int &pills, int &adren)
{
    pills = 0;
    adren = 0;
    if (g_fTempHealthRadius <= 0.0)
    {
        if (g_bConditionDebug)
        LogDebug("CountGroundTemps: disabled (radius=%.0f)", g_fTempHealthRadius);
        return;
    }

    float vItem[3], vSurv[3];
    int ent = -1;

    while ((ent = FindEntityByClassname(ent, "weapon_pain_pills_spawn")) != -1)
    {
        if (!IsValidEntity(ent)) continue;
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) continue;
            GetClientAbsOrigin(i, vSurv);
            if (GetVectorDistance(vSurv, vItem) <= g_fTempHealthRadius)
            {
                pills++;
                break;
            }
        }
    }

    ent = -1;
    while ((ent = FindEntityByClassname(ent, "weapon_adrenaline_spawn")) != -1)
    {
        if (!IsValidEntity(ent)) continue;
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) continue;
            GetClientAbsOrigin(i, vSurv);
            if (GetVectorDistance(vSurv, vItem) <= g_fTempHealthRadius)
            {
                adren++;
                break;
            }
        }
    }

    ent = -1;
    while ((ent = FindEntityByClassname(ent, "weapon_item_spawn")) != -1)
    {
        char sItem[32];
        if (!GetItemSpawnerType(ent, sItem, sizeof(sItem))) continue;
        if (StrEqual(sItem, "pain_pills", false) || StrEqual(sItem, "adrenaline", false))
        {
            GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
            for (int i = 1; i <= MaxClients; i++)
            {
                if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) continue;
                GetClientAbsOrigin(i, vSurv);
                if (GetVectorDistance(vSurv, vItem) <= g_fTempHealthRadius)
                {
                    if (sItem[0] == 'p') pills++; else adren++;
                    break;
                }
            }
        }
    }

    ent = -1;
    while ((ent = FindEntityByClassname(ent, "weapon_pain_pills")) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) continue;
            GetClientAbsOrigin(i, vSurv);
            if (GetVectorDistance(vSurv, vItem) <= g_fTempHealthRadius)
            {
                pills++;
                break;
            }
        }
    }
    ent = -1;
    while ((ent = FindEntityByClassname(ent, "weapon_adrenaline")) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) continue;
            GetClientAbsOrigin(i, vSurv);
            if (GetVectorDistance(vSurv, vItem) <= g_fTempHealthRadius)
            {
                adren++;
                break;
            }
        }
    }

    if (g_bConditionDebug)
    LogDebug("CountGroundTemps: total counted pills=%d, adren=%d", pills, adren);
}

void AssignGroundTemps(int pills, int adren, int[] playerState, bool[] hasTemp, int[] tempBoost, bool[] isIncap, int aliveCount, int[] currentTotalHealths)
{
    for (int pass = 0; pass < 2; pass++)
    {
        int count = (pass == 0) ? pills : adren;
        int boost = (pass == 0) ? 50 : 25;
        while (count > 0)
        {
            int best = -1;
            int bestState = -1;
            int bestHealth = 1000;

            for (int i = 0; i < aliveCount; i++)
            {
                if (isIncap[i]) continue;
                if (hasTemp[i]) continue;

                int state = playerState[i];
                if (state > bestState)
                {
                    bestState = state;
                    best = i;
                    bestHealth = currentTotalHealths[i];
                }
                else if (state == bestState && currentTotalHealths[i] < bestHealth)
                {
                    best = i;
                    bestHealth = currentTotalHealths[i];
                }
            }

            if (best == -1) break;

            hasTemp[best] = true;
            tempBoost[best] = boost;
            count--;
        }
    }
}

int GetCurrentCondition()
{
    int aliveCount = 0;
    int playerState[MAXPLAYERS+1];
    bool hasKit[MAXPLAYERS+1], hasTemp[MAXPLAYERS+1];
    int currentTotalHealths[MAXPLAYERS+1], tempBoosts[MAXPLAYERS+1];
    bool isIncap[MAXPLAYERS+1];
    char nameBuf[64];
    char debugLine[512];
    Format(debugLine, sizeof(debugLine), "Condition check: ");

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
        {
            int state;
            bool kit; bool temp;
            int boost;
            GetPlayerHealthState(i, state, kit, temp, boost);

            playerState[aliveCount] = state;
            hasKit[aliveCount] = false;
            hasTemp[aliveCount] = false;
            tempBoosts[aliveCount] = 0;

            int real = GetClientHealth(i);
            float buf = GetEntPropFloat(i, Prop_Send, "m_healthBuffer");
            float bufTime = GetEntPropFloat(i, Prop_Send, "m_healthBufferTime");
            float gameTime = GetGameTime();
            float curBuf = buf;
            if (buf > 0.0 && bufTime > 0.0)
            {
                curBuf = buf - g_fCvar_PillsDecay * (gameTime - bufTime);
                if (curBuf < 0.0) curBuf = 0.0;
            }
            int totalHealth = real + RoundToCeil(curBuf);
            if (totalHealth > 100) totalHealth = 100;
            currentTotalHealths[aliveCount] = totalHealth;

            isIncap[aliveCount] = !!GetEntProp(i, Prop_Send, "m_isIncapacitated");

            GetClientName(i, nameBuf, sizeof(nameBuf));
            Format(debugLine, sizeof(debugLine), "%s P%d(%s %d/%d %s%s)", debugLine, aliveCount+1,
            nameBuf, real, totalHealth,
            playerState[aliveCount]==0?"H":(playerState[aliveCount]==1?"I":"C"),
            isIncap[aliveCount] ? " (incap)" : "");
            aliveCount++;
        }
    }
    if (aliveCount == 0)
    {
        LogDebug("%s -> no alive survivors, condition 0", debugLine);
        return 0;
    }

    int totalKits = CountEffectiveGroundKits();
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
        {
            int kitEnt = GetPlayerWeaponSlot(i, 3);
            if (kitEnt != -1 && IsValidEntity(kitEnt))
            totalKits++;
        }
    }

    int kitsUsed = 0;
    bool kitReservedFor[MAXPLAYERS+1] = { false, ... };

    while (totalKits > 0)
    {
        int bestIdx = -1;
        int bestState = -1;
        int bestHealth = 1000;

        for (int i = 0; i < aliveCount; i++)
        {
            if (playerState[i] == 0) continue;
            if (kitReservedFor[i]) continue;

            int state = playerState[i];
            if (state > bestState)
            {
                bestState = state;
                bestIdx = i;
                bestHealth = currentTotalHealths[i];
            }
            else if (state == bestState && currentTotalHealths[i] < bestHealth)
            {
                bestIdx = i;
                bestHealth = currentTotalHealths[i];
            }
        }

        if (bestIdx == -1) break;

        if (isIncap[bestIdx])
        kitReservedFor[bestIdx] = true;
        else
        playerState[bestIdx] = 0;

        totalKits--;
        kitsUsed++;
    }

    int groundPills, groundAdren;
    CountEffectiveGroundTemps(groundPills, groundAdren);

    int carriedPills = 0;
    int carriedAdren = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
        {
            int tempEnt = GetPlayerWeaponSlot(i, 4);
            if (tempEnt != -1 && IsValidEntity(tempEnt))
            {
                char cls[32];
                GetEdictClassname(tempEnt, cls, sizeof(cls));
                if (StrContains(cls, "adrenaline", false) != -1)
                carriedAdren++;
                else if (StrContains(cls, "pain_pills", false) != -1)
                carriedPills++;
            }
        }
    }

    int totalPills = groundPills + carriedPills;
    int totalAdren = groundAdren + carriedAdren;

    for (int i = 0; i < aliveCount; i++)
    {
        hasTemp[i] = false;
        tempBoosts[i] = 0;
    }

    AssignGroundTemps(totalPills, totalAdren, playerState, hasTemp, tempBoosts, isIncap, aliveCount, currentTotalHealths);

    for (int i = 0; i < aliveCount; i++)
    {
        if (isIncap[i]) continue;
        if (playerState[i] == 2 && hasTemp[i])
        {
            int newTotal = currentTotalHealths[i] + tempBoosts[i];
            if (newTotal > 100) newTotal = 100;
            if (newTotal > 40)
            playerState[i] = 1;
        }
    }

    int critical = 0, injured = 0, healthy = 0;
    char finalState[128];
    Format(finalState, sizeof(finalState), "Final states: ");
    for (int i = 0; i < aliveCount; i++)
    {
        if (isIncap[i])
        {
            if (kitReservedFor[i])
            Format(finalState, sizeof(finalState), "%sC(r)", finalState);
            else
            {
                Format(finalState, sizeof(finalState), "%sC", finalState);
                critical++;
            }
        }
        else
        {
            if (playerState[i] == 2) critical++;
            else if (playerState[i] == 1) injured++;
            else healthy++;
            Format(finalState, sizeof(finalState), "%s%s", finalState,
            playerState[i]==0?"H":(playerState[i]==1?"I":"C"));
        }
    }

    int newCond;
    if (critical >= 2) newCond = 2;
    else if (critical == 1) newCond = 1;
    else if (aliveCount >= 3 && injured >= RoundToCeil(float(aliveCount) * 0.75)) newCond = 1;
    else newCond = 0;

    Format(debugLine, sizeof(debugLine), "%s | Ground kits: %d | Unified temps: %d (pills:%d adren:%d) [g:%d+%d, c:%d+%d] | Kits used: %d",
        debugLine,
        CountEffectiveGroundKits(),
        totalPills+totalAdren, totalPills, totalAdren,
        groundPills, groundAdren, carriedPills, carriedAdren,
        kitsUsed);

    LogDebug("%s | Simulation: unified pool (kits→temps) | %s | -> Condition %d",
    debugLine, finalState, newCond);
    return newCond;
}

float GetLeadingSurvivorFlow()
{
    float maxFlow = 0.0;
    for (int c = 1; c <= MaxClients; c++)
    {
        if (IsClientInGame(c) && GetClientTeam(c) == 2 && IsPlayerAlive(c))
        {
            float f = L4D2Direct_GetFlowDistance(c);
            if (f > maxFlow) maxFlow = f;
        }
    }
    return maxFlow;
}

int GetLeadingSurvivorClient()
{
    int result = 0;
    float maxFlow = 0.0;
    for (int c = 1; c <= MaxClients; c++)
    {
        if (IsClientInGame(c) && GetClientTeam(c) == 2 && IsPlayerAlive(c))
        {
            float f = L4D2Direct_GetFlowDistance(c);
            if (f > maxFlow) { maxFlow = f; result = c; }
        }
    }
    return result;
}

// Condition timer and spawn logic
Action Timer_CheckCondition(Handle timer)
{
    if (!g_bEnabled || !g_bLeftSafeArea)
    return Plugin_Continue;

    if (g_bConditionEnable && g_bMedkitEnable)
    {
        if (GetGameTime() - g_fLastItemPickupTime < 0.7)
        return Plugin_Continue;

        if (g_bPendingMedkitSpawn)
        {
            if (g_iCondition == 0)
            {
                g_bPendingMedkitSpawn = false;
                g_iPendingMedkitCount = 0;
                LogDebug("Pending medkit spawn cancelled – condition is 0");
            }
            else
            {
                int kitsToSpawn = g_iPendingMedkitCount;
                for (int i = 0; i < kitsToSpawn; i++)
                {
                    if (SpawnMedkitAtClosestValid())
                    g_iPendingMedkitCount--;
                    else
                    break;
                }
                if (g_iPendingMedkitCount <= 0)
                {
                    g_bPendingMedkitSpawn = false;
                    g_iPendingMedkitCount = 0;
                    LogDebug("Pending medkit spawn completed");
                }
            }
        }

        int newCond = GetCurrentCondition();
        if (newCond != g_iCondition)
        {
            LogDebug("Condition changed: %d -> %d", g_iCondition, newCond);
            int oldCond = g_iCondition;
            g_iLastCondition = oldCond;
            g_iCondition = newCond;

            g_bPendingMedkitSpawn = false;
            g_iPendingMedkitCount = 0;

            if (newCond > oldCond)
            {
                float curFlow = GetLeadingSurvivorFlow();
                if (g_fNextSpawnFlow > curFlow && g_fNextSpawnFlow > 0.0)
                {
                    LogDebug("Condition increased from %d to %d – keeping existing target flow %.0f (current flow %.0f)",
                    oldCond, newCond, g_fNextSpawnFlow, curFlow);
                }
                else
                {
                    g_fNextSpawnFlow = curFlow + GetRandomFloat(g_fConditionFlowMin, g_fConditionFlowMax);
                    LogDebug("Set next spawn flow (fallback): %.0f (current flow %.0f)", g_fNextSpawnFlow, curFlow);
                }
            }
            else
            {
                if (newCond == 0)
                {
                    g_fNextSpawnFlow = -1.0;
                    LogDebug("Condition decreased to 0 – resetting flow timer");
                }
                else
                {
                    LogDebug("Condition decreased from %d to %d (keeping target flow: %.0f)", oldCond, newCond, g_fNextSpawnFlow);
                }
            }

            g_iPendingSpawns = 0;

            if (newCond == 0)
            {
                g_iInitialKitsGiven = 0;
            }
            else if (g_bConditionInitialNearby && newCond >= 1)
            {
                float now = GetGameTime();
                int totalNeeded = (newCond == 2) ? 2 : 1;
                int additional = totalNeeded - g_iInitialKitsGiven;

                if (additional > 0)
                {
                    bool cooldownPassed = (g_fConditionInitialNearbyCooldown <= 0.0 ||
                    g_fLastInitialSpawn == 0.0 ||
                    (now - g_fLastInitialSpawn) >= g_fConditionInitialNearbyCooldown);

                    if (g_iInitialKitsGiven == 0 && !cooldownPassed)
                    {
                        LogDebug("Initial spawn blocked by global cooldown (first spawn of streak)");
                    }
                    else
                    {
                        g_iPendingSpawns = additional;
                        LogDebug("Initial spawn queued (%d kits) – escalation (already given %d, need %d)",
                        additional, g_iInitialKitsGiven, totalNeeded);
                    }
                }
                else
                {
                    LogDebug("No additional initial kits to spawn (already given %d, need %d)", g_iInitialKitsGiven, totalNeeded);
                }
            }
        }

        if (g_iPendingSpawns > 0)
        {
            float now = GetGameTime();
            int spawned = 0;
            while (g_iPendingSpawns > 0)
            {
                if (SpawnMedkitAtClosestValid())
                {
                    g_iPendingSpawns--;
                    g_iInitialKitsGiven++;
                    g_fLastInitialSpawn = now;
                    spawned++;
                }
                else
                {
                    LogDebug("Initial spawn failed – aborting remaining queue");
                    g_iPendingSpawns = 0;
                }
            }
            if (spawned > 0)
            LogDebug("Initial spawn finished: %d kits placed, cooldown set", spawned);
        }

        if (g_iCondition > 0 && !g_bPendingMedkitSpawn)
        {
            float curFlow = GetLeadingSurvivorFlow();
            if (curFlow > 0.0)
            {
                if (g_fNextSpawnFlow < 0.0)
                g_fNextSpawnFlow = curFlow + GetRandomFloat(g_fConditionFlowMin, g_fConditionFlowMax);

                if (curFlow >= g_fNextSpawnFlow)
                {
                    int maxToSpawn = (g_iCondition == 2) ? 2 : 1;
                    int currentTotalKits = CountEffectiveGroundKits();
                    int availableSlots = g_iConditionMaxMeds - currentTotalKits;
                    if (availableSlots < 0) availableSlots = 0;
                    if (maxToSpawn > availableSlots) maxToSpawn = availableSlots;
                    LogDebug("Flow spawn: cond=%d maxToSpawn=%d currentKits=%d maxAllowed=%d slots=%d",
                    g_iCondition, maxToSpawn, currentTotalKits, g_iConditionMaxMeds, availableSlots);

                    int spawned = 0;
                    for (int i = 0; i < maxToSpawn; i++)
                    {
                        if (SpawnMedkitAtClosestValid())
                            spawned++;
                        else
                        {
                            LogDebug("Spawn failed: no valid location (flow attempt)");
                            break;
                        }
                    }

                    if (spawned == 0)
                    {
                        if (g_cvSpawnImmediate.IntValue == 1)
                        {
                            g_bPendingMedkitSpawn = true;
                            g_iPendingMedkitCount = maxToSpawn;
                            g_fNextSpawnFlow = -1.0;
                            LogDebug("Flow spawn completely failed – pending medkit spawn (%d kits)", maxToSpawn);
                        }
                        else
                        {
                            g_fNextSpawnFlow = curFlow + GetRandomFloat(g_fConditionFlowMin, g_fConditionFlowMax);
                            LogDebug("Flow spawn failed – setting new random target at %.0f", g_fNextSpawnFlow);
                        }
                    }
                    else
                    {
                        int remaining = maxToSpawn - spawned;
                        if (remaining > 0)
                        {
                            if (g_cvSpawnImmediate.IntValue == 1)
                            {
                                g_bPendingMedkitSpawn = true;
                                g_iPendingMedkitCount = remaining;
                                g_fNextSpawnFlow = -1.0;
                                LogDebug("Partial flow spawn – pending medkit spawn for %d remaining kits", remaining);
                            }
                            else
                            {
                                g_fNextSpawnFlow = curFlow + GetRandomFloat(g_fConditionFlowMin, g_fConditionFlowMax);
                                LogDebug("Flow spawn partial: %d/%d spawned, next at %.0f", spawned, maxToSpawn, g_fNextSpawnFlow);
                            }
                        }
                        else
                        {
                            g_fNextSpawnFlow = curFlow + GetRandomFloat(g_fConditionFlowMin, g_fConditionFlowMax);
                            LogDebug("Flow spawn result: %d/%d spawned, next at %.0f", spawned, maxToSpawn, g_fNextSpawnFlow);
                        }
                    }
                }
            }
        }
    }

    if (g_bDefibEnable)
    {
        CheckDefibSpawn();
    }

    return Plugin_Continue;
}

// Defibrillator logic
int CountAvailableDefibs()
{
    int count = 0;
    float vEnt[3], vSurv[3];

    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "weapon_defibrillator")) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1)
        {
            LogDebug("DefibCount: entity %d skipped (carried)", ent);
            continue;
        }
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vEnt);
        bool found = false;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
            continue;
            GetClientAbsOrigin(i, vSurv);
            float dist = GetVectorDistance(vSurv, vEnt);
            if (dist <= g_fDefibRadius)
            {
                char name[64];
                GetClientName(i, name, sizeof(name));
                LogDebug("DefibCount: ground defib %d counted (survivor '%s' dist %.0f)", ent, name, dist);
                count++;
                found = true;
                break;
            }
        }
        if (!found)
        LogDebug("DefibCount: ground defib %d NOT counted (no survivor within %.0f)", ent, g_fDefibRadius);
    }

    ent = -1;
    while ((ent = FindEntityByClassname(ent, "weapon_defibrillator_spawn")) != -1)
    {
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vEnt);
        bool found = false;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
            continue;
            GetClientAbsOrigin(i, vSurv);
            if (GetVectorDistance(vSurv, vEnt) <= g_fDefibRadius)
            {
                LogDebug("DefibCount: spawner %d counted (survivor %d dist within %.0f)", ent, i, g_fDefibRadius);
                count++;
                found = true;
                break;
            }
        }
        if (!found)
        LogDebug("DefibCount: spawner %d NOT counted (no survivor within %.0f)", ent, g_fDefibRadius);
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
        {
            int item = GetPlayerWeaponSlot(i, 3);
            if (item != -1 && IsValidEntity(item))
            {
                char cls[64];
                GetEdictClassname(item, cls, sizeof(cls));
                if (StrEqual(cls, "weapon_defibrillator", false))
                {
                    char name[64];
                    GetClientName(i, name, sizeof(name));
                    LogDebug("DefibCount: carried defib counted (survivor '%s')", name);
                    count++;
                }
            }
        }
    }

    LogDebug("DefibCount: total available defibs = %d", count);
    return count;
}

void CheckDefibSpawn()
{
    int alive = 0, dead = 0;
    for (int c = 1; c <= MaxClients; c++)
    {
        if (IsClientInGame(c) && GetClientTeam(c) == 2)
        {
            if (IsPlayerAlive(c)) alive++;
            else dead++;
        }
    }
    int total = alive + dead;

    if (dead == 0 || total < 3)
    {
        LogDebug("Defib: no dead survivors or total < 3, resetting timer");
        g_fNextDefibFlow = -1.0;
        g_bPendingDefibSpawn = false;
        g_iPendingDefibCount = 0;
        return;
    }

    if (g_bPendingDefibSpawn)
    {
        int availableDefibs = CountAvailableDefibs();
        int neededDefibs = dead - availableDefibs;
        if (neededDefibs <= 0)
        {
            g_bPendingDefibSpawn = false;
            g_iPendingDefibCount = 0;
            LogDebug("Defib: pending spawn – enough defibs now (%d), cleared", availableDefibs);
            return;
        }

        g_iPendingDefibCount = neededDefibs;
        while (g_iPendingDefibCount > 0)
        {
            if (SpawnDefibAtClosestValid())
            g_iPendingDefibCount--;
            else
            break;
        }

        if (g_iPendingDefibCount == 0)
        {
            g_bPendingDefibSpawn = false;
            g_iPendingDefibCount = 0;
            LogDebug("Defib: pending spawn completed");
        }
        return;
    }

    int availableDefibs = CountAvailableDefibs();
    int neededDefibs = dead - availableDefibs;
    if (neededDefibs <= 0)
    {
        LogDebug("Defib: enough defibs available (%d) for %d dead – no new spawn target",
        availableDefibs, dead);
        g_fNextDefibFlow = -1.0;
        return;
    }
    else
    {
        LogDebug("Defib: need %d defibs, have %d – will try to spawn more",
        neededDefibs, availableDefibs);
    }

    float frac = (alive - 1) / float(total - 2);
    float distance = g_fDefibFlowMin + frac * (g_fDefibFlowMax - g_fDefibFlowMin);
    LogDebug("Defib: alive=%d dead=%d total=%d -> distance=%.0f", alive, dead, total, distance);

    float curFlow = GetLeadingSurvivorFlow();
    if (curFlow <= 0.0) return;

    if (g_fNextDefibFlow > 0.0 && distance != g_fLastDefibDistance)
    {
        g_fNextDefibFlow = curFlow + distance;
        g_fLastDefibDistance = distance;
        LogDebug("Defib: distance changed – updated target to %.0f (current flow %.0f, new distance %.0f)",
        g_fNextDefibFlow, curFlow, distance);
    }

    if (g_fNextDefibFlow < 0.0)
    {
        g_fNextDefibFlow = curFlow + distance;
        g_fLastDefibDistance = distance;
        LogDebug("Defib: set new target flow %.0f (current %.0f, distance %.0f)", g_fNextDefibFlow, curFlow, distance);
        return;
    }

    if (curFlow >= g_fNextDefibFlow)
    {
        LogDebug("Defib: target reached (flow %.0f >= %.0f), attempting spawn", curFlow, g_fNextDefibFlow);
        if (SpawnDefibAtClosestValid())
        {
            g_fNextDefibFlow = -1.0;
            LogDebug("Defib: spawned successfully, resetting target");
        }
        else
        {
            if (g_cvSpawnImmediate.IntValue == 1)
            {
                g_bPendingDefibSpawn = true;
                g_iPendingDefibCount = 1;
                g_fNextDefibFlow = -1.0;
                LogDebug("Defib: spawn failed – pending defib spawn");
            }
            else
            {
                g_fNextDefibFlow = curFlow + GetRandomFloat(g_fConditionFlowMin, g_fConditionFlowMax);
                g_fLastDefibDistance = -1.0;
                LogDebug("Defib: spawn failed, setting new random target at %.0f", g_fNextDefibFlow);
            }
        }
    }
}

bool IsAnySurvivorNearDefib()
{
    float vDefib[3], vSurv[3];
    int ent = -1;

    while ((ent = FindEntityByClassname(ent, "weapon_defibrillator")) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1)
        continue;
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vDefib);
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
            continue;
            GetClientAbsOrigin(i, vSurv);
            if (GetVectorDistance(vSurv, vDefib) <= g_fDefibRadius)
            return true;
        }
    }

    ent = -1;
    while ((ent = FindEntityByClassname(ent, "weapon_defibrillator_spawn")) != -1)
    {
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vDefib);
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
            continue;
            GetClientAbsOrigin(i, vSurv);
            if (GetVectorDistance(vSurv, vDefib) <= g_fDefibRadius)
            return true;
        }
    }

    return false;
}

bool SpawnDefibAtClosestValid()
{
    int leadClient = GetLeadingSurvivorClient();
    if (leadClient == 0)
    {
        for (int c = 1; c <= MaxClients; c++)
        {
            if (IsClientInGame(c) && GetClientTeam(c) == 2 && IsPlayerAlive(c))
            {
                leadClient = c;
                break;
            }
        }
        if (leadClient == 0)
        {
            LogDebug("SpawnDefibAtClosestValid: no alive survivor");
            return false;
        }
        LogDebug("SpawnDefibAtClosestValid: using fallback survivor %d", leadClient);
    }

    float vLead[3];
    GetClientAbsOrigin(leadClient, vLead);
    float gameTime = GetGameTime();

    int bestIdx = -1;
    float bestDist = 999999.0;

    for (int i = 0; i < g_iSpawnerCount; i++)
    {
        if (g_bUsedIndex[i] || g_bDefibSpawned[i] || g_bWeaponSpawned[i] || g_bMedkitSpawned[i] || g_bTempHealthSpawned[i] || g_bThrowableSpawned[i] || g_bLaserSightSpawned[i] || g_bUpgradePackSpawned[i]) continue;
        if (g_bNearCabinet[i] && !g_bDefibNearCabinet)
        continue;
        if (g_bNearSaferoom[i] && g_fSaferoomIgnoreRadius > 0.0)
        continue;
        if (g_bNearFinale[i] && g_fFinaleIgnoreRadius > 0.0)
        continue;

        if (!g_bSpawnIfVisible)
        {
            float vTarget[3];
            vTarget = g_vSpawnerPos[i];
            vTarget[2] += 30.0;
            if (IsPositionVisibleToAnySurvivor(vTarget))
            {
                if (g_fFailCooldown > 0.0)
                {
                    if (gameTime - g_fLastVisibilityFail[i] >= g_fFailCooldown)
                    g_fLastVisibilityFail[i] = gameTime;
                }
                continue;
            }
            if (g_fFailCooldown > 0.0 && g_fLastVisibilityFail[i] > 0.0)
            {
                if (gameTime - g_fLastVisibilityFail[i] < g_fFailCooldown)
                continue;
            }
        }

        if (g_fBypassCooldown > 0.0 && g_fBypassTime[i] > 0.0)
        {
            if (gameTime - g_fBypassTime[i] < g_fBypassCooldown)
            continue;
        }

        float dist = GetVectorDistance(vLead, g_vSpawnerPos[i]);
        if (dist >= g_fDefibRadiusIgnore && dist <= g_fDefibRadius)
        {
            if (dist < bestDist) { bestDist = dist; bestIdx = i; }
        }
    }

    if (bestIdx != -1)
    {
        int ent = CreateEntityByName("weapon_defibrillator");
        if (ent == -1) return false;
        float vOrigin[3];
        vOrigin = g_vSpawnerPos[bestIdx];
        vOrigin[2] += 5.0;
        TeleportEntity(ent, vOrigin, g_vSpawnerAng[bestIdx], NULL_VECTOR);
        DispatchSpawn(ent);

        g_bDefibSpawned[bestIdx] = true;
        g_bUsedIndex[bestIdx] = true;

        if (g_bReplaceItem) RemoveItemsAtPosition(g_vSpawnerPos[bestIdx], ent);
        if (g_bCleanupEnable)
        {
            g_aCleanupItems.Push(EntIndexToEntRef(ent));
            g_aCleanupTimers.Push(0.0);
            g_aCleanupIndex.Push(bestIdx);
            g_aCleanupType.Push(2);
        }
        LogDebug("Defibrillator spawned at index %d (dist %.0f)", bestIdx, bestDist);
        return true;
    }

    LogDebug("No valid spawn point for defibrillator");
    return false;
}

// Admin teleport commands
Action Cmd_TeleportDefib(int client, int args)
{
    if (!g_bEnabled)
    {
        ReplyToCommand(client, "[SM] Plugin is disabled.");
        return Plugin_Handled;
    }

    ArrayList validEnts = new ArrayList();
    ArrayList validSpawnIdx = new ArrayList();
    float vItem[3], vSurv[3];
    bool found;

    for (int i = 0; i < g_aCleanupItems.Length; i++)
    {
        if (g_aCleanupType.Get(i) != 2) continue;
        int ref = g_aCleanupItems.Get(i);
        int ent = EntRefToEntIndex(ref);
        if (ent == INVALID_ENT_REFERENCE || !IsValidEntity(ent)) continue;
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;

        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
        bool inRange = false;
        for (int j = 1; j <= MaxClients; j++)
        {
            if (!IsClientInGame(j) || GetClientTeam(j) != 2 || !IsPlayerAlive(j)) continue;
            GetClientAbsOrigin(j, vSurv);
            if (GetVectorDistance(vSurv, vItem) <= g_fDefibRadius)
            {
                inRange = true;
                break;
            }
        }
        if (!inRange) continue;

        int ref2 = EntIndexToEntRef(ent);
        if (validEnts.FindValue(ref2) != -1) continue;
        validEnts.Push(ref2);
        validSpawnIdx.Push(g_aCleanupIndex.Get(i));
        found = true;
    }

    int entScan = -1;
    while ((entScan = FindEntityByClassname(entScan, "weapon_defibrillator")) != -1)
    {
        if (GetEntPropEnt(entScan, Prop_Send, "m_hOwnerEntity") != -1) continue;
        GetEntPropVector(entScan, Prop_Data, "m_vecOrigin", vItem);

        bool inRange = false;
        for (int j = 1; j <= MaxClients; j++)
        {
            if (!IsClientInGame(j) || GetClientTeam(j) != 2 || !IsPlayerAlive(j)) continue;
            GetClientAbsOrigin(j, vSurv);
            if (GetVectorDistance(vSurv, vItem) <= g_fDefibRadius)
            {
                inRange = true;
                break;
            }
        }
        if (!inRange) continue;

        int ref = EntIndexToEntRef(entScan);
        if (validEnts.FindValue(ref) != -1) continue;
        int spawnIdx = -1;
        for (int i = 0; i < g_iSpawnerCount; i++)
        {
            if (GetVectorDistance(vItem, g_vSpawnerPos[i]) < 50.0)
            {
                spawnIdx = i;
                break;
            }
        }
        validEnts.Push(ref);
        validSpawnIdx.Push(spawnIdx);
        found = true;
    }

    if (!found)
    {
        ReplyToCommand(client, "[SM] No valid defibrillator entities within range.");
        delete validEnts;
        delete validSpawnIdx;
        return Plugin_Handled;
    }

    if (g_iTeleportDefibIndex >= validEnts.Length || g_iTeleportDefibIndex < 0)
    g_iTeleportDefibIndex = 0;

    int ref = validEnts.Get(g_iTeleportDefibIndex);
    int ent = EntRefToEntIndex(ref);
    if (ent == INVALID_ENT_REFERENCE || !IsValidEntity(ent))
    {
        ReplyToCommand(client, "[SM] Selected defibrillator entity no longer exists.");
        delete validEnts;
        delete validSpawnIdx;
        return Plugin_Handled;
    }

    float vPos[3];
    GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vPos);
    TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
    int spawnIdx = validSpawnIdx.Get(g_iTeleportDefibIndex);
    LogDebug("TeleportDefib! Client %d to defib (cleanup slot %d, spawn idx %d), pos %.0f %.0f %.0f",
    client, g_iTeleportDefibIndex, spawnIdx, vPos[0], vPos[1], vPos[2]);
    ReplyToCommand(client, "[SM] Teleported to defibrillator #%d (spawn index %d).", g_iTeleportDefibIndex + 1, spawnIdx);
    g_iTeleportDefibIndex++;
    delete validEnts;
    delete validSpawnIdx;
    return Plugin_Handled;
}

Action Cmd_TeleportWeapon(int client, int args)
{
    if (!g_bEnabled) { ReplyToCommand(client, "[SM] Plugin is disabled."); return Plugin_Handled; }

    ArrayList validEnts = new ArrayList();
    ArrayList validSpawnIdx = new ArrayList();
    float vItem[3], vSurv[3];
    bool found;

    // Cleanup‑tracked weapons
    for (int i = 0; i < g_aCleanupItems.Length; i++)
    {
        if (g_aCleanupType.Get(i) != 0) continue;
        int ref = g_aCleanupItems.Get(i);
        int ent = EntRefToEntIndex(ref);
        if (ent == INVALID_ENT_REFERENCE || !IsValidEntity(ent)) continue;
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;

        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
        bool inRange = false;
        for (int j = 1; j <= MaxClients; j++)
        {
            if (!IsClientInGame(j) || GetClientTeam(j) != 2 || !IsPlayerAlive(j)) continue;
            GetClientAbsOrigin(j, vSurv);
            if (GetVectorDistance(vSurv, vItem) <= g_fWeaponRadius) { inRange = true; break; }
        }
        if (!inRange) continue;

        int ref2 = EntIndexToEntRef(ent);
        if (validEnts.FindValue(ref2) != -1) continue;
        validEnts.Push(ref2);
        validSpawnIdx.Push(g_aCleanupIndex.Get(i));
        found = true;
    }

    int entScan = -1;
    while ((entScan = FindEntityByClassname(entScan, "weapon_*")) != -1)
    {
        if (!IsValidEntity(entScan)) continue;
        if (GetEntPropEnt(entScan, Prop_Send, "m_hOwnerEntity") != -1) continue;

        char cls[64];
        GetEdictClassname(entScan, cls, sizeof(cls));
        if (StrContains(cls, "_spawn") != -1) continue;

        bool isPrimary = false;
        for (int w = 0; w < sizeof(g_sWeapons); w++)
        if (StrEqual(cls, g_sWeapons[w], false)) { isPrimary = true; break; }
        if (!isPrimary) continue;

        GetEntPropVector(entScan, Prop_Data, "m_vecOrigin", vItem);
        bool inRange = false;
        for (int j = 1; j <= MaxClients; j++)
        {
            if (!IsClientInGame(j) || GetClientTeam(j) != 2 || !IsPlayerAlive(j)) continue;
            GetClientAbsOrigin(j, vSurv);
            if (GetVectorDistance(vSurv, vItem) <= g_fWeaponRadius) { inRange = true; break; }
        }
        if (!inRange) continue;

        int ref = EntIndexToEntRef(entScan);
        if (validEnts.FindValue(ref) != -1) continue;
        int spawnIdx = -1;
        for (int i = 0; i < g_iSpawnerCount; i++)
        if (GetVectorDistance(vItem, g_vSpawnerPos[i]) < 50.0) { spawnIdx = i; break; }
        validEnts.Push(ref);
        validSpawnIdx.Push(spawnIdx);
        found = true;
    }

    if (!found) { ReplyToCommand(client, "[SM] No valid weapon entities within range."); delete validEnts; delete validSpawnIdx; return Plugin_Handled; }

    if (g_iTeleportWeaponIndex >= validEnts.Length || g_iTeleportWeaponIndex < 0)
    g_iTeleportWeaponIndex = 0;

    int ref = validEnts.Get(g_iTeleportWeaponIndex);
    int ent = EntRefToEntIndex(ref);
    if (ent == INVALID_ENT_REFERENCE || !IsValidEntity(ent))
    {
        ReplyToCommand(client, "[SM] Selected weapon entity no longer exists.");
        delete validEnts; delete validSpawnIdx;
        return Plugin_Handled;
    }

    float vPos[3];
    GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vPos);
    TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
    int spawnIdx = validSpawnIdx.Get(g_iTeleportWeaponIndex);
    LogDebug("TeleportWeapon! Client %d to weapon (cleanup slot %d, spawn idx %d)", client, g_iTeleportWeaponIndex, spawnIdx);
    ReplyToCommand(client, "[SM] Teleported to weapon #%d (spawn index %d).", g_iTeleportWeaponIndex+1, spawnIdx);
    g_iTeleportWeaponIndex++;
    delete validEnts; delete validSpawnIdx;
    return Plugin_Handled;
}

Action Cmd_TeleportThrowable(int client, int args)
{
    if (!g_bEnabled)
    {
        ReplyToCommand(client, "[SM] Plugin is disabled.");
        return Plugin_Handled;
    }
    if (g_fThrowableRadius <= 0.0)
    {
        ReplyToCommand(client, "[SM] Throwable detection is disabled (item_director_throwable_radius = 0).");
        return Plugin_Handled;
    }

    ArrayList validEnts = new ArrayList();
    ArrayList validSpawnIdx = new ArrayList();

    float vMyPos[3];
    GetClientAbsOrigin(client, vMyPos);
    float vItem[3];

    for (int i = 0; i < sizeof(g_sThrowableNames); i++)
    {
        int ent = -1;
        while ((ent = FindEntityByClassname(ent, g_sThrowableNames[i])) != -1)
        {
            if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
            GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
            if (GetVectorDistance(vMyPos, vItem) <= g_fThrowableRadius)
            {
                int ref = EntIndexToEntRef(ent);
                if (validEnts.FindValue(ref) == -1)
                {
                    validEnts.Push(ref);
                    int spawnIdx = -1;
                    for (int j = 0; j < g_iSpawnerCount; j++)
                    {
                        if (GetVectorDistance(vItem, g_vSpawnerPos[j]) < 50.0)
                        { spawnIdx = j; break; }
                    }
                    validSpawnIdx.Push(spawnIdx);
                }
            }
        }
    }

    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "weapon_item_spawn")) != -1)
    {
        char sItem[32];
        if (!GetItemSpawnerType(ent, sItem, sizeof(sItem))) continue;
        if (StrEqual(sItem, "pipe_bomb", false) || StrEqual(sItem, "molotov", false) || StrEqual(sItem, "vomitjar", false))
        {
            GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
            if (GetVectorDistance(vMyPos, vItem) <= g_fThrowableRadius)
            {
                int ref = EntIndexToEntRef(ent);
                if (validEnts.FindValue(ref) == -1)
                {
                    validEnts.Push(ref);
                    int spawnIdx = -1;
                    for (int j = 0; j < g_iSpawnerCount; j++)
                    {
                        if (GetVectorDistance(vItem, g_vSpawnerPos[j]) < 50.0)
                        { spawnIdx = j; break; }
                    }
                    validSpawnIdx.Push(spawnIdx);
                }
            }
        }
    }

    static const char sThrowSpawners[][] = {
        "weapon_molotov_spawn",
        "weapon_pipe_bomb_spawn",
        "weapon_vomitjar_spawn"
    };
    for (int i = 0; i < sizeof(sThrowSpawners); i++)
    {
        ent = -1;
        while ((ent = FindEntityByClassname(ent, sThrowSpawners[i])) != -1)
        {
            GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
            if (GetVectorDistance(vMyPos, vItem) <= g_fThrowableRadius)
            {
                int ref = EntIndexToEntRef(ent);
                if (validEnts.FindValue(ref) == -1)
                {
                    validEnts.Push(ref);
                    int spawnIdx = -1;
                    for (int j = 0; j < g_iSpawnerCount; j++)
                    {
                        if (GetVectorDistance(vItem, g_vSpawnerPos[j]) < 50.0)
                        { spawnIdx = j; break; }
                    }
                    validSpawnIdx.Push(spawnIdx);
                }
            }
        }
    }

    if (validEnts.Length == 0)
    {
        ReplyToCommand(client, "[SM] No throwable items in range.");
        delete validEnts;
        delete validSpawnIdx;
        return Plugin_Handled;
    }

    static int teleportThrowIdx = 0;
    if (teleportThrowIdx >= validEnts.Length) teleportThrowIdx = 0;

    int ref = validEnts.Get(teleportThrowIdx);
    int teleEnt = EntRefToEntIndex(ref);
    if (teleEnt == INVALID_ENT_REFERENCE || !IsValidEntity(teleEnt))
    {
        ReplyToCommand(client, "[SM] Selected throwable no longer exists.");
        delete validEnts; delete validSpawnIdx;
        return Plugin_Handled;
    }

    float vPos[3];
    GetEntPropVector(teleEnt, Prop_Data, "m_vecOrigin", vPos);
    TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
    int spawnIdx = validSpawnIdx.Get(teleportThrowIdx);

    char classname[64];
    GetEdictClassname(teleEnt, classname, sizeof(classname));
    
    if (g_bThrowableDebug)
        LogToFileEx(g_sLogPath, "TeleportThrowable! Client %d to %s, spawn index %d, pos %.0f %.0f %.0f",
        client, classname, spawnIdx, vPos[0], vPos[1], vPos[2]);
    
    ReplyToCommand(client, "[SM] Teleported to %s (spawn index %d).", classname, spawnIdx);

    teleportThrowIdx++;
    delete validEnts; delete validSpawnIdx;
    return Plugin_Handled;
}

Action Cmd_TeleportLaser(int client, int args)
{
    if (!g_bEnabled)
    {
        ReplyToCommand(client, "[SM] Plugin is disabled.");
        return Plugin_Handled;
    }
    if (g_fLaserSightRadius <= 0.0)
    {
        ReplyToCommand(client, "[SM] Laser‑sight detection is disabled (radius = 0).");
        return Plugin_Handled;
    }

    ArrayList validEnts = new ArrayList();
    ArrayList validSpawnIdx = new ArrayList();
    float vMyPos[3], vItem[3];
    GetClientAbsOrigin(client, vMyPos);

    // DEBUG: log own position
    if (g_bLaserSightDebug)
    LogToFileEx(g_sLogPath, "TeleportLaser debug: my pos %.0f %.0f %.0f", vMyPos[0], vMyPos[1], vMyPos[2]);

    // Cleanup‑tracked lasers
    for (int i = 0; i < g_aCleanupItems.Length; i++)
    {
        if (g_aCleanupType.Get(i) != 7) continue;
        int ref = g_aCleanupItems.Get(i);
        int ent = EntRefToEntIndex(ref);
        if (ent == INVALID_ENT_REFERENCE || !IsValidEntity(ent)) continue;
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;

        int idx = g_aCleanupIndex.Get(i);
        if (idx >= 0 && idx < g_iSpawnerCount)
            vItem = g_vSpawnerPos[idx];
        else
            GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);

        float dist = GetVectorDistance(vMyPos, vItem);

        // DEBUG: log this cleanup item
        if (g_bLaserSightDebug)
        LogToFileEx(g_sLogPath, "TeleportLaser debug: cleanup idx %d ent %d dist %.0f", idx, ent, dist);

        if (dist <= g_fLaserSightRadius)
        {
            int ref2 = EntIndexToEntRef(ent);
            if (validEnts.FindValue(ref2) == -1)
            {
                validEnts.Push(ref2);
                validSpawnIdx.Push(idx);
            }
        }
    }

    // Entity scans
    char classname[64];
    int ent = -1;

    // weapon_upgradepack_laser
    while ((ent = FindEntityByClassname(ent, "weapon_upgradepack_laser")) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
        GetEdictClassname(ent, classname, sizeof(classname));
        if (g_bLaserSightDebug)
        LogToFileEx(g_sLogPath, "TeleportLaser debug: found entity %d class %s at %.0f %.0f %.0f dist %.0f",
        ent, classname, vItem[0], vItem[1], vItem[2], GetVectorDistance(vMyPos, vItem));

        if (GetVectorDistance(vMyPos, vItem) <= g_fLaserSightRadius)
        {
            int ref = EntIndexToEntRef(ent);
            if (validEnts.FindValue(ref) == -1)
            {
                validEnts.Push(ref);
                int spawnIdx = -1;
                for (int j = 0; j < g_iSpawnerCount; j++)
                    if (GetVectorDistance(vItem, g_vSpawnerPos[j]) < 50.0) { spawnIdx = j; break; }
                validSpawnIdx.Push(spawnIdx);
            }
        }
    }

    // upgrade_laser_sight
    ent = -1;
    while ((ent = FindEntityByClassname(ent, "upgrade_laser_sight")) != -1)
    {
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
        GetEdictClassname(ent, classname, sizeof(classname));
        if (g_bLaserSightDebug)
        LogToFileEx(g_sLogPath, "TeleportLaser debug: found entity %d class %s at %.0f %.0f %.0f dist %.0f",
        ent, classname, vItem[0], vItem[1], vItem[2], GetVectorDistance(vMyPos, vItem));

        if (GetVectorDistance(vMyPos, vItem) <= g_fLaserSightRadius)
        {
            int ref = EntIndexToEntRef(ent);
            if (validEnts.FindValue(ref) == -1)
            {
                validEnts.Push(ref);
                int spawnIdx = -1;
                for (int j = 0; j < g_iSpawnerCount; j++)
                    if (GetVectorDistance(vItem, g_vSpawnerPos[j]) < 50.0) { spawnIdx = j; break; }
                validSpawnIdx.Push(spawnIdx);
            }
        }
    }

    // weapon_upgradepack_laser_spawn
    ent = -1;
    while ((ent = FindEntityByClassname(ent, "weapon_upgradepack_laser_spawn")) != -1)
    {
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
        GetEdictClassname(ent, classname, sizeof(classname));
        if (g_bLaserSightDebug)
        LogToFileEx(g_sLogPath, "TeleportLaser debug: found entity %d class %s at %.0f %.0f %.0f dist %.0f",
        ent, classname, vItem[0], vItem[1], vItem[2], GetVectorDistance(vMyPos, vItem));

        if (GetVectorDistance(vMyPos, vItem) <= g_fLaserSightRadius)
        {
            int ref = EntIndexToEntRef(ent);
            if (validEnts.FindValue(ref) == -1)
            {
                validEnts.Push(ref);
                int spawnIdx = -1;
                for (int j = 0; j < g_iSpawnerCount; j++)
                    if (GetVectorDistance(vItem, g_vSpawnerPos[j]) < 50.0) { spawnIdx = j; break; }
                validSpawnIdx.Push(spawnIdx);
            }
        }
    }

    if (validEnts.Length == 0)
    {
        ReplyToCommand(client, "[SM] No laser‑sight items within range.");
        delete validEnts; delete validSpawnIdx;
        return Plugin_Handled;
    }

    static int teleportLaserIdx = 0;
    if (teleportLaserIdx >= validEnts.Length) teleportLaserIdx = 0;
    int ref = validEnts.Get(teleportLaserIdx);
    int teleEnt = EntRefToEntIndex(ref);
    if (teleEnt == INVALID_ENT_REFERENCE || !IsValidEntity(teleEnt))
    {
        ReplyToCommand(client, "[SM] Selected laser‑sight no longer exists.");
        delete validEnts; delete validSpawnIdx;
        return Plugin_Handled;
    }

    float vPos[3];
    int spawnIdx = validSpawnIdx.Get(teleportLaserIdx);
    if (spawnIdx >= 0 && spawnIdx < g_iSpawnerCount)
        vPos = g_vSpawnerPos[spawnIdx];
    else
        GetEntPropVector(teleEnt, Prop_Data, "m_vecOrigin", vPos);

    TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
    char cls[64];
    GetEdictClassname(teleEnt, cls, sizeof(cls));

    if (g_bLaserSightDebug)
        LogToFileEx(g_sLogPath, "TeleportLaser! Client %d to %s, spawn index %d, pos %.0f %.0f %.0f",
            client, cls, spawnIdx, vPos[0], vPos[1], vPos[2]);

    ReplyToCommand(client, "[SM] Teleported to %s (spawn index %d).", cls, spawnIdx);
    teleportLaserIdx++;
    delete validEnts; delete validSpawnIdx;
    return Plugin_Handled;
}

Action Cmd_TeleportUpgradePack(int client, int args)
{
    if (!g_bEnabled)
    {
        ReplyToCommand(client, "[SM] Plugin is disabled.");
        return Plugin_Handled;
    }
    if (g_fUpgradePackRadiusIgnore <= 0.0)
    {
        ReplyToCommand(client, "[SM] Upgrade pack detection is disabled (ignore radius <= 0).");
        return Plugin_Handled;
    }

    ArrayList validEnts = new ArrayList();
    ArrayList validSpawnIdx = new ArrayList();
    float vMyPos[3], vItem[3];
    GetClientAbsOrigin(client, vMyPos);

    // Cleanup‑tracked upgrade packs (type 8)
    for (int i = 0; i < g_aCleanupItems.Length; i++)
    {
        if (g_aCleanupType.Get(i) != 8) continue;
        int ref = g_aCleanupItems.Get(i);
        int ent = EntRefToEntIndex(ref);
        if (ent == INVALID_ENT_REFERENCE || !IsValidEntity(ent)) continue;
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;

        int idx = g_aCleanupIndex.Get(i);
        if (idx >= 0 && idx < g_iSpawnerCount)
            vItem = g_vSpawnerPos[idx];
        else
            GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
        float dist = GetVectorDistance(vMyPos, vItem);
        if (dist <= 2000.0)   // arbitrary range for admin teleport
        {
            int ref2 = EntIndexToEntRef(ent);
            if (validEnts.FindValue(ref2) == -1)
            {
                validEnts.Push(ref2);
                validSpawnIdx.Push(idx);
            }
        }
    }

    // Scan for physical upgrade packs
    char upgradeClasses[2][] = { "weapon_upgradepack_incendiary", "weapon_upgradepack_explosive" };
    for (int k = 0; k < 2; k++)
    {
        int ent = -1;
        while ((ent = FindEntityByClassname(ent, upgradeClasses[k])) != -1)
        {
            if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
            GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
            if (GetVectorDistance(vMyPos, vItem) <= 2000.0)
            {
                int ref = EntIndexToEntRef(ent);
                if (validEnts.FindValue(ref) == -1)
                {
                    validEnts.Push(ref);
                    int spawnIdx = -1;
                    for (int j = 0; j < g_iSpawnerCount; j++)
                        if (GetVectorDistance(vItem, g_vSpawnerPos[j]) < 50.0) { spawnIdx = j; break; }
                    validSpawnIdx.Push(spawnIdx);
                }
            }
        }
    }

    // Scan for spawners
    char spawnerClasses[2][] = { "weapon_upgradepack_incendiary_spawn", "weapon_upgradepack_explosive_spawn" };
    for (int k = 0; k < 2; k++)
    {
        int ent = -1;
        while ((ent = FindEntityByClassname(ent, spawnerClasses[k])) != -1)
        {
            GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
            if (GetVectorDistance(vMyPos, vItem) <= 2000.0)
            {
                int ref = EntIndexToEntRef(ent);
                if (validEnts.FindValue(ref) == -1)
                {
                    validEnts.Push(ref);
                    int spawnIdx = -1;
                    for (int j = 0; j < g_iSpawnerCount; j++)
                        if (GetVectorDistance(vItem, g_vSpawnerPos[j]) < 50.0) { spawnIdx = j; break; }
                    validSpawnIdx.Push(spawnIdx);
                }
            }
        }
    }

    if (validEnts.Length == 0)
    {
        ReplyToCommand(client, "[SM] No upgrade pack items nearby.");
        delete validEnts;
        delete validSpawnIdx;
        return Plugin_Handled;
    }

    static int teleportUpgradeIdx = 0;
    if (teleportUpgradeIdx >= validEnts.Length) teleportUpgradeIdx = 0;

    int ref = validEnts.Get(teleportUpgradeIdx);
    int teleEnt = EntRefToEntIndex(ref);
    if (teleEnt == INVALID_ENT_REFERENCE || !IsValidEntity(teleEnt))
    {
        ReplyToCommand(client, "[SM] Selected upgrade pack no longer exists.");
        delete validEnts; delete validSpawnIdx;
        return Plugin_Handled;
    }

    float vPos[3];
    int spawnIdx = validSpawnIdx.Get(teleportUpgradeIdx);
    if (spawnIdx >= 0 && spawnIdx < g_iSpawnerCount)
        vPos = g_vSpawnerPos[spawnIdx];
    else
        GetEntPropVector(teleEnt, Prop_Data, "m_vecOrigin", vPos);

    TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
    char cls[64];
    GetEdictClassname(teleEnt, cls, sizeof(cls));

    if (g_bUpgradePackDebug)
        LogToFileEx(g_sLogPath, "TeleportUpgradePack! Client %d to %s, spawn index %d", client, cls, spawnIdx);

    ReplyToCommand(client, "[SM] Teleported to %s (spawn index %d).", cls, spawnIdx);
    teleportUpgradeIdx++;
    delete validEnts; delete validSpawnIdx;
    return Plugin_Handled;
}

Action Timer_UpdateDefibHud(Handle timer)
{
    if (!g_bEnabled || !g_bDefibHud || !g_bDefibEnable || !g_bLeftSafeArea)
        return Plugin_Continue;

    float curFlow = GetLeadingSurvivorFlow();
    char line[128];

    if (g_bPendingDefibSpawn)
    {
        Format(line, sizeof(line), "Defib | Spawn pending...");
    }
    else if (g_fNextDefibFlow > 0.0)
    {
        Format(line, sizeof(line), "Defib | Flow: %.0f / %.0f", curFlow, g_fNextDefibFlow);
    }
    else
    {
        Format(line, sizeof(line), "Defib | Flow: %.0f (no dead)", curFlow);
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && (GetUserFlagBits(i) & ADMFLAG_ROOT))
            PrintHintText(i, "%s", line);
    }
    return Plugin_Continue;
}

Action Timer_UpdateWeaponHud(Handle timer)
{
    if (!g_bEnabled || !g_bWeaponHud || !g_bWeaponEnable || !g_bLeftSafeArea)
        return Plugin_Continue;

    char line[128];
    Format(line, sizeof(line), "Weapon | Ammo threshold: %.0f%%", g_fWeaponAmmoPercent);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && (GetUserFlagBits(i) & ADMFLAG_ROOT))
            PrintHintText(i, "%s", line);
    }
    return Plugin_Continue;
}

Action Timer_UpdateProposeHud(Handle timer)
{
    if (!g_bEnabled || !g_bWeaponPropose || !g_bProposeHud || !g_bLeftSafeArea)
        return Plugin_Continue;

    char line[128];
    float curFlow = GetLeadingSurvivorFlow();

    if (g_bProposeInitialDone)
    {
        if (g_bProposePendingSpawn)
            Format(line, sizeof(line), "Propose | Ongoing | Spawn pending...");
        else
            Format(line, sizeof(line), "Propose | Ongoing | Flow: %.0f / %.0f", curFlow, g_fProposeNextFlow);
    }
    else
    {
        int alive = GetAliveSurvivorCount();
        Format(line, sizeof(line), "Propose | Initial %d/%d | %sFlow: %.0f / %.0f",
            g_iProposeInitialSpawned, alive,
            g_bProposePendingSpawn ? "Pending! " : "",
            curFlow, g_fProposeNextFlow);
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && (GetUserFlagBits(i) & ADMFLAG_ROOT))
            PrintHintText(i, "%s", line);
    }

    return Plugin_Continue;
}

// Cleanup
Action Timer_CheckCleanup(Handle timer)
{
    if (!g_bEnabled || !g_bCleanupEnable || g_aCleanupItems.Length == 0)
    return Plugin_Continue;

    float fGameTime = GetGameTime();
    float fDelta = fGameTime - g_fLastCleanupCheck;
    g_fLastCleanupCheck = fGameTime;

    float vItemPos[3];
    bool bAnySurvivorNear;

    for (int i = g_aCleanupItems.Length - 1; i >= 0; i--)
    {
        int ref = g_aCleanupItems.Get(i);
        int entity = EntRefToEntIndex(ref);
        int idx = g_aCleanupIndex.Get(i);
        int type = g_aCleanupType.Get(i);

        // Entity gone (picked up, removed, etc.)
        if (entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity))
        {
            if (g_bCleanupRespawnEnable)
            {
                if (type == 0) g_bWeaponSpawned[idx] = false;
                else if (type == 1) g_bMedkitSpawned[idx] = false;
                else if (type == 2) g_bDefibSpawned[idx] = false;
                else if (type == 4) g_bUsedIndex[idx] = false;
                else if (type == 5) g_bTempHealthSpawned[idx] = false;
                else if (type == 6) g_bThrowableSpawned[idx] = false;
                else if (type == 7) g_bLaserSightSpawned[idx] = false;
                else if (type == 8) g_bUpgradePackSpawned[idx] = false;
                g_bUsedIndex[idx] = false;            
            }
            g_aCleanupItems.Erase(i);
            g_aCleanupTimers.Erase(i);
            g_aCleanupIndex.Erase(i);
            g_aCleanupType.Erase(i);
            continue;
        }

        GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vItemPos);
        bAnySurvivorNear = false;
        for (int client = 1; client <= MaxClients; client++)
        {
            if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
            continue;
            float vClientOrigin[3];
            GetClientAbsOrigin(client, vClientOrigin);
            if (GetVectorDistance(vClientOrigin, vItemPos) <= g_fCleanupRadius)
            {
                bAnySurvivorNear = true;
                break;
            }
        }

        if (bAnySurvivorNear)
        {
            g_aCleanupTimers.Set(i, 0.0);
        }
        else
        {
            float fCurrent = g_aCleanupTimers.Get(i);
            fCurrent += fDelta;
            if (fCurrent >= g_fCleanupDelay)
            {
                RemoveEntity(entity);
                if (g_bCleanupRespawnEnable)
                {
                    if (type == 0) g_bWeaponSpawned[idx] = false;
                    else if (type == 1) g_bMedkitSpawned[idx] = false;
                    else if (type == 2) g_bDefibSpawned[idx] = false;
                    else if (type == 4) g_bUsedIndex[idx] = false;
                    else if (type == 5) g_bTempHealthSpawned[idx] = false;
                    else if (type == 6) g_bThrowableSpawned[idx] = false;
                    else if (type == 7) g_bLaserSightSpawned[idx] = false;
                    else if (type == 8) g_bUpgradePackSpawned[idx] = false;
                    g_bUsedIndex[idx] = false;
                    LogDebug("Cleanup: Removed %s at index %d (away for %.0f sec) – spawn point re-enabled",
                    type == 0 ? "weapon" : (type == 1 ? "medkit" : (type == 2 ? "defib" : (type == 4 ? "ammo" : (type == 5 ? "temphealth" : (type == 6 ? "throwable" : (type == 7 ? "laser" : "upgradepack")))))), idx, fCurrent);
                }
                else
                {
                    LogDebug("Cleanup: Removed %s at index %d (away for %.0f sec) – spawn point remains disabled",
                    type == 0 ? "weapon" : (type == 1 ? "medkit" : (type == 2 ? "defib" : (type == 4 ? "ammo" : (type == 5 ? "temphealth" : (type == 6 ? "throwable" : (type == 7 ? "laser" : "upgradepack")))))), idx, fCurrent);
                }
                g_aCleanupItems.Erase(i);
                g_aCleanupTimers.Erase(i);
                g_aCleanupIndex.Erase(i);
                g_aCleanupType.Erase(i);
            }
            else
            {
                g_aCleanupTimers.Set(i, fCurrent);
            }
        }
    }
    return Plugin_Continue;
}

// Helper functions
bool IsPositionVisibleToAnySurvivor(float vTarget[3])
{
    float vEye[3];
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
        continue;
        GetClientEyePosition(client, vEye);
        Handle hTrace = TR_TraceRayFilterEx(vEye, vTarget, MASK_VISIBLE, RayType_EndPoint, TraceFilter_IgnoreAll);
        bool hit = TR_DidHit(hTrace);
        delete hTrace;
        if (!hit) return true;
    }
    return false;
}

bool TraceFilter_IgnoreAll(int entity, int contentsMask) { return false; }

int SpawnWeaponAt(int index)
{
    int weaponType = GetRandomInt(0, sizeof(g_sWeapons) - 1);
    int weapon = CreateEntityByName(g_sWeapons[weaponType]);
    if (weapon == -1) return -1;

    float vAngles[3];
    vAngles[0] = 0.0;
    vAngles[1] = g_vSpawnerAng[index][1];
    vAngles[2] = 0.0;

    float vOrigin[3];
    vOrigin[0] = g_vSpawnerPos[index][0];
    vOrigin[1] = g_vSpawnerPos[index][1];
    vOrigin[2] = g_vSpawnerPos[index][2] + 10.0;

    float vEnd[3];
    vEnd = vOrigin;
    vEnd[2] -= 50.0;

    Handle hTrace = TR_TraceRayFilterEx(vOrigin, vEnd, MASK_SOLID, RayType_EndPoint, TraceFilter_NoPlayers);
    if (TR_DidHit(hTrace))
    {
        TR_GetEndPosition(vOrigin, hTrace);
    }
    else
    {
        vOrigin = g_vSpawnerPos[index];
        vOrigin[2] += 5.0;
    }
    delete hTrace;

    vOrigin[2] += 1.0;

    // Spawn the weapon
    TeleportEntity(weapon, vOrigin, vAngles, NULL_VECTOR);
    DispatchSpawn(weapon);
    SetEntProp(weapon, Prop_Send, "m_iExtraPrimaryAmmo", 999);

    float vCurPos[3];
    GetEntPropVector(weapon, Prop_Send, "m_vecOrigin", vCurPos);
    vCurPos[2] += 10.0;
    TeleportEntity(weapon, vCurPos, NULL_VECTOR, NULL_VECTOR);

    if (g_bReplaceItem)
    RemoveItemsAtPosition(g_vSpawnerPos[index], weapon);

    return weapon;
}

bool PlayerNeedsAmmo(int client, float &percent, int &maxReserve)
{
    int primary = GetPlayerWeaponSlot(client, 0);
    if (primary == -1) return false;

    char wepClass[64];
    GetEdictClassname(primary, wepClass, sizeof(wepClass));

    int ammoType = GetEntProp(primary, Prop_Data, "m_iPrimaryAmmoType");
    int extra    = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType);

    bool bM60Special = false;
    maxReserve = 0;

    if (StrEqual(wepClass, "weapon_rifle_m60"))
    {
        ConVar hM60 = FindConVar("ammo_m60_max");
        if (hM60 != null && hM60.IntValue > 0)
        maxReserve = hM60.IntValue;
        else
        bM60Special = true;
    }
    else
    {
        maxReserve = AmmoDef.MaxCarry_Call(ammoType, client);
    }

    if (bM60Special)
    {
        int clip = GetEntProp(primary, Prop_Send, "m_iClip1");
        percent = float(clip) * 100.0 / 150.0;
    }
    else
    {
        if (maxReserve <= 0) return false;
        percent = float(extra) * 100.0 / float(maxReserve);
    }

    return (percent <= g_fAmmoThreshold);
}

int SpawnAmmoAt(int index)
{
    int ammo = CreateEntityByName("weapon_ammo_spawn");
    if (ammo == -1) return -1;

    float vAngles[3];
    vAngles[0] = 0.0;
    vAngles[1] = g_vSpawnerAng[index][1];
    vAngles[2] = 0.0;

    float vOrigin[3];
    vOrigin[0] = g_vSpawnerPos[index][0];
    vOrigin[1] = g_vSpawnerPos[index][1];
    vOrigin[2] = g_vSpawnerPos[index][2] + 10.0;

    float vEnd[3];
    vEnd = vOrigin;
    vEnd[2] -= 50.0;

    Handle hTrace = TR_TraceRayFilterEx(vOrigin, vEnd, MASK_SOLID, RayType_EndPoint, TraceFilter_NoPlayers);
    if (TR_DidHit(hTrace))
        TR_GetEndPosition(vOrigin, hTrace);
    else
    {
        vOrigin = g_vSpawnerPos[index];
        vOrigin[2] += 5.0;
    }
    delete hTrace;
    vOrigin[2] += 1.0;

    TeleportEntity(ammo, vOrigin, vAngles, NULL_VECTOR);
    DispatchSpawn(ammo);

    if (g_bReplaceItem)
    RemoveItemsAtPosition(g_vSpawnerPos[index], ammo);

    return ammo;
}

int SpawnTempHealthAt(int index)
{
    char classname[32];
    if (GetRandomInt(0, 1) == 0)
    classname = "weapon_pain_pills";
    else
    classname = "weapon_adrenaline";

    int item = CreateEntityByName(classname);
    if (item == -1) return -1;

    float vAngles[3];
    vAngles[0] = 0.0;
    vAngles[1] = g_vSpawnerAng[index][1];
    vAngles[2] = 0.0;

    float vOrigin[3];
    vOrigin[0] = g_vSpawnerPos[index][0];
    vOrigin[1] = g_vSpawnerPos[index][1];
    vOrigin[2] = g_vSpawnerPos[index][2] + 10.0;

    float vEnd[3];
    vEnd = vOrigin;
    vEnd[2] -= 50.0;

    Handle hTrace = TR_TraceRayFilterEx(vOrigin, vEnd, MASK_SOLID, RayType_EndPoint, TraceFilter_NoPlayers);
    if (TR_DidHit(hTrace))
    TR_GetEndPosition(vOrigin, hTrace);
    else
    {
        vOrigin = g_vSpawnerPos[index];
        vOrigin[2] += 5.0;
    }
    delete hTrace;
    vOrigin[2] += 1.0;

    TeleportEntity(item, vOrigin, vAngles, NULL_VECTOR);
    DispatchSpawn(item);

    if (g_bReplaceItem)
    RemoveItemsAtPosition(g_vSpawnerPos[index], item);

    return item;
}

static const char g_sThrowables[][] = { "weapon_pipe_bomb", "weapon_molotov", "weapon_vomitjar" };

int SpawnThrowableAt(int index)
{
    int type = GetRandomInt(0, sizeof(g_sThrowableNames) - 1);
    int item = CreateEntityByName(g_sThrowableNames[type]);
    if (item == -1) return -1;

    float vAngles[3];
    vAngles[0] = 0.0;
    vAngles[1] = g_vSpawnerAng[index][1];
    vAngles[2] = 0.0;

    float vOrigin[3];
    vOrigin[0] = g_vSpawnerPos[index][0];
    vOrigin[1] = g_vSpawnerPos[index][1];
    vOrigin[2] = g_vSpawnerPos[index][2] + 10.0;

    float vEnd[3];
    vEnd = vOrigin;
    vEnd[2] -= 50.0;

    Handle hTrace = TR_TraceRayFilterEx(vOrigin, vEnd, MASK_SOLID, RayType_EndPoint, TraceFilter_NoPlayers);
    if (TR_DidHit(hTrace))
        TR_GetEndPosition(vOrigin, hTrace);
    else
    {
        vOrigin = g_vSpawnerPos[index];
        vOrigin[2] += 5.0;
    }
    delete hTrace;
    vOrigin[2] += 1.0;

    TeleportEntity(item, vOrigin, vAngles, NULL_VECTOR);
    DispatchSpawn(item);

    if (g_bReplaceItem)
        RemoveItemsAtPosition(g_vSpawnerPos[index], item);

    return item;
}

int SpawnLaserSightAt(int index)
{
    int item = CreateEntityByName("upgrade_laser_sight");
    if (item == -1) return -1;

    SetEntityModel(item, "models/w_models/Weapons/w_laser_sights.mdl");

    float vAngles[3];
    vAngles[0] = 0.0;
    vAngles[1] = g_vSpawnerAng[index][1];
    vAngles[2] = 0.0;

    float vOrigin[3];
    vOrigin[0] = g_vSpawnerPos[index][0];
    vOrigin[1] = g_vSpawnerPos[index][1];
    vOrigin[2] = g_vSpawnerPos[index][2] + 10.0;

    float vEnd[3];
    vEnd = vOrigin;
    vEnd[2] -= 50.0;

    Handle hTrace = TR_TraceRayFilterEx(vOrigin, vEnd, MASK_SOLID, RayType_EndPoint, TraceFilter_NoPlayers);
    if (TR_DidHit(hTrace))
    TR_GetEndPosition(vOrigin, hTrace);
    else
    {
        vOrigin = g_vSpawnerPos[index];
        vOrigin[2] += 5.0;
    }
    delete hTrace;
    vOrigin[2] += 1.0;

    TeleportEntity(item, vOrigin, vAngles, NULL_VECTOR);
    DispatchSpawn(item);

    if (g_bReplaceItem)
    RemoveItemsAtPosition(g_vSpawnerPos[index], item);

    return item;
}

int SpawnUpgradePackAt(int index)
{
    // Randomly choose incendiary or explosive (50/50)
    char classname[64];
    if (GetRandomInt(0, 1) == 0)
    classname = "weapon_upgradepack_incendiary";
    else
    classname = "weapon_upgradepack_explosive";

    int item = CreateEntityByName(classname);
    if (item == -1) return -1;

    float vAngles[3];
    vAngles[0] = 0.0;
    vAngles[1] = g_vSpawnerAng[index][1];
    vAngles[2] = 0.0;

    float vOrigin[3];
    vOrigin[0] = g_vSpawnerPos[index][0];
    vOrigin[1] = g_vSpawnerPos[index][1];
    vOrigin[2] = g_vSpawnerPos[index][2] + 10.0;

    float vEnd[3];
    vEnd = vOrigin;
    vEnd[2] -= 50.0;

    Handle hTrace = TR_TraceRayFilterEx(vOrigin, vEnd, MASK_SOLID, RayType_EndPoint, TraceFilter_NoPlayers);
    if (TR_DidHit(hTrace))
        TR_GetEndPosition(vOrigin, hTrace);
    else
    {
        vOrigin = g_vSpawnerPos[index];
        vOrigin[2] += 5.0;
    }
    delete hTrace;
    vOrigin[2] += 1.0;

    TeleportEntity(item, vOrigin, vAngles, NULL_VECTOR);
    DispatchSpawn(item);

    if (g_bReplaceItem)
        RemoveItemsAtPosition(g_vSpawnerPos[index], item);

    return item;
}

bool TraceFilter_NoPlayers(int entity, int contentsMask)
{
    return entity > MaxClients || entity <= 0;
}

void RemoveItemsAtPosition(float vCenter[3], int excludeEnt = -1)
{
    float vEntOrigin[3];
    int maxEnts = GetMaxEntities();
    char classname[64];

    for (int entity = MaxClients + 1; entity <= maxEnts; entity++)
    {
        if (!IsValidEntity(entity)) continue;
        if (entity == excludeEnt) continue;

        GetEdictClassname(entity, classname, sizeof(classname));
        if (StrContains(classname, "weapon_") == 0 && StrContains(classname, "_spawn") != -1)
        {
            GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vEntOrigin);
            if (GetVectorDistance(vEntOrigin, vCenter) <= g_fReplaceRadius)
            {
                RemoveEntity(entity);
            }
        }
    }
}

// Teleport commands
Action Cmd_Teleport(int client, int args)
{
    if (!g_bEnabled)
    {
        ReplyToCommand(client, "[SM] Plugin is disabled.");
        return Plugin_Handled;
    }

    ArrayList validEnts = new ArrayList();
    ArrayList validSpawnIdx = new ArrayList();

    float vItem[3], vSurv[3];
    bool found;

    for (int i = 0; i < g_aCleanupItems.Length; i++)
    {
        if (g_aCleanupType.Get(i) != 1) continue;
        int ref = g_aCleanupItems.Get(i);
        int ent = EntRefToEntIndex(ref);
        if (ent == INVALID_ENT_REFERENCE || !IsValidEntity(ent)) continue;
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;

        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);

        bool inRange = false;
        for (int j = 1; j <= MaxClients; j++)
        {
            if (!IsClientInGame(j) || GetClientTeam(j) != 2 || !IsPlayerAlive(j)) continue;
            GetClientAbsOrigin(j, vSurv);
            if (GetVectorDistance(vSurv, vItem) <= g_fMedkitRadius)
            {
                inRange = true;
                break;
            }
        }
        if (!inRange) continue;

        int ref2 = EntIndexToEntRef(ent);
        if (validEnts.FindValue(ref2) == -1)
        {
            validEnts.Push(ref2);
            int spawnIdx = g_aCleanupIndex.Get(i);
            validSpawnIdx.Push(spawnIdx);
            found = true;
        }
    }

    int entScan = -1;
    while ((entScan = FindEntityByClassname(entScan, "weapon_first_aid_kit")) != -1)
    {
        if (GetEntPropEnt(entScan, Prop_Send, "m_hOwnerEntity") != -1) continue;

        GetEntPropVector(entScan, Prop_Data, "m_vecOrigin", vItem);

        bool inRange = false;
        for (int j = 1; j <= MaxClients; j++)
        {
            if (!IsClientInGame(j) || GetClientTeam(j) != 2 || !IsPlayerAlive(j)) continue;
            GetClientAbsOrigin(j, vSurv);
            if (GetVectorDistance(vSurv, vItem) <= g_fMedkitRadius)
            {
                inRange = true;
                break;
            }
        }
        if (!inRange) continue;

        int ref = EntIndexToEntRef(entScan);
        if (validEnts.FindValue(ref) != -1) continue;

        int spawnIdx = -1;
        for (int i = 0; i < g_iSpawnerCount; i++)
        {
            if (GetVectorDistance(vItem, g_vSpawnerPos[i]) < 50.0)
            {
                spawnIdx = i;
                break;
            }
        }
        validEnts.Push(ref);
        validSpawnIdx.Push(spawnIdx);
        found = true;
    }

    if (!found)
    {
        ReplyToCommand(client, "[SM] No valid medkit entities within range.");
        delete validEnts;
        delete validSpawnIdx;
        return Plugin_Handled;
    }

    if (g_iTeleportIndex >= validEnts.Length || g_iTeleportIndex < 0)
    g_iTeleportIndex = 0;

    int ref = validEnts.Get(g_iTeleportIndex);
    int ent = EntRefToEntIndex(ref);
    if (ent == INVALID_ENT_REFERENCE || !IsValidEntity(ent))
    {
        ReplyToCommand(client, "[SM] Selected medkit entity no longer exists.");
        delete validEnts;
        delete validSpawnIdx;
        return Plugin_Handled;
    }

    float vPos[3];
    GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vPos);
    TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
    int spawnIdx = validSpawnIdx.Get(g_iTeleportIndex);
    LogDebug("Teleport! Client %d to medkit (cleanup slot %d, spawn idx %d), pos %.0f %.0f %.0f",
    client, g_iTeleportIndex, spawnIdx, vPos[0], vPos[1], vPos[2]);
    ReplyToCommand(client, "[SM] Teleported to medkit #%d (spawn index %d).", g_iTeleportIndex + 1, spawnIdx);
    g_iTeleportIndex++;
    delete validEnts;
    delete validSpawnIdx;
    return Plugin_Handled;
}

Action Cmd_TeleportTemp(int client, int args)
{
    if (!g_bEnabled)
    {
        ReplyToCommand(client, "[SM] Plugin is disabled.");
        return Plugin_Handled;
    }
    if (g_fTempHealthRadius <= 0.0)
    {
        ReplyToCommand(client, "[SM] Temporary health item detection is disabled (item_director_temp_health_radius = 0).");
        return Plugin_Handled;
    }

    ArrayList validEnts = new ArrayList();
    ArrayList validSpawnIdx = new ArrayList();
    
    float vMyPos[3];
    GetClientAbsOrigin(client, vMyPos);
    
    float vItem[3];
    int ent = -1;

    while ((ent = FindEntityByClassname(ent, "weapon_pain_pills_spawn")) != -1)
    {
        if (!IsValidEntity(ent)) continue;
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
        if (GetVectorDistance(vMyPos, vItem) <= g_fTempHealthRadius)
        {
            int ref = EntIndexToEntRef(ent);
            if (validEnts.FindValue(ref) == -1)
            {
                validEnts.Push(ref);
                int spawnIdx = -1;
                for (int j = 0; j < g_iSpawnerCount; j++)
                {
                    if (GetVectorDistance(vItem, g_vSpawnerPos[j]) < 50.0)
                    {
                        spawnIdx = j;
                        break;
                    }
                }
                validSpawnIdx.Push(spawnIdx);
            }
        }
    }

    ent = -1;
    while ((ent = FindEntityByClassname(ent, "weapon_adrenaline_spawn")) != -1)
    {
        if (!IsValidEntity(ent)) continue;
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
        if (GetVectorDistance(vMyPos, vItem) <= g_fTempHealthRadius)
        {
            int ref = EntIndexToEntRef(ent);
            if (validEnts.FindValue(ref) == -1)
            {
                validEnts.Push(ref);
                int spawnIdx = -1;
                for (int j = 0; j < g_iSpawnerCount; j++)
                {
                    if (GetVectorDistance(vItem, g_vSpawnerPos[j]) < 50.0)
                    {
                        spawnIdx = j;
                        break;
                    }
                }
                validSpawnIdx.Push(spawnIdx);
            }
        }
    }

    ent = -1;
    while ((ent = FindEntityByClassname(ent, "weapon_item_spawn")) != -1)
    {
        char sItem[32];
        if (!GetItemSpawnerType(ent, sItem, sizeof(sItem))) continue;
        if (StrEqual(sItem, "pain_pills", false) || StrEqual(sItem, "adrenaline", false))
        {
            if (!IsValidEntity(ent)) continue;
            GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
            if (GetVectorDistance(vMyPos, vItem) <= g_fTempHealthRadius)
            {
                int ref = EntIndexToEntRef(ent);
                if (validEnts.FindValue(ref) == -1)
                {
                    validEnts.Push(ref);
                    int spawnIdx = -1;
                    for (int j = 0; j < g_iSpawnerCount; j++)
                    {
                        if (GetVectorDistance(vItem, g_vSpawnerPos[j]) < 50.0)
                        {
                            spawnIdx = j;
                            break;
                        }
                    }
                    validSpawnIdx.Push(spawnIdx);
                }
            }
        }
    }

    ent = -1;
    while ((ent = FindEntityByClassname(ent, "weapon_pain_pills")) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
        if (GetVectorDistance(vMyPos, vItem) <= g_fTempHealthRadius)
        {
            int ref = EntIndexToEntRef(ent);
            if (validEnts.FindValue(ref) == -1)
            {
                validEnts.Push(ref);
                int spawnIdx = -1;
                for (int j = 0; j < g_iSpawnerCount; j++)
                {
                    if (GetVectorDistance(vItem, g_vSpawnerPos[j]) < 50.0)
                    {
                        spawnIdx = j;
                        break;
                    }
                }
                validSpawnIdx.Push(spawnIdx);
            }
        }
    }

    ent = -1;
    while ((ent = FindEntityByClassname(ent, "weapon_adrenaline")) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
        if (GetVectorDistance(vMyPos, vItem) <= g_fTempHealthRadius)
        {
            int ref = EntIndexToEntRef(ent);
            if (validEnts.FindValue(ref) == -1)
            {
                validEnts.Push(ref);
                int spawnIdx = -1;
                for (int j = 0; j < g_iSpawnerCount; j++)
                {
                    if (GetVectorDistance(vItem, g_vSpawnerPos[j]) < 50.0)
                    {
                        spawnIdx = j;
                        break;
                    }
                }
                validSpawnIdx.Push(spawnIdx);
            }
        }
    }

    if (validEnts.Length == 0)
    {
        ReplyToCommand(client, "[SM] No temporary health items in range.");
        delete validEnts;
        delete validSpawnIdx;
        return Plugin_Handled;
    }

    if (g_iTeleportTempIndex >= validEnts.Length || g_iTeleportTempIndex < 0)
    g_iTeleportTempIndex = 0;

    int ref = validEnts.Get(g_iTeleportTempIndex);
    int teleEnt = EntRefToEntIndex(ref);
    if (teleEnt == INVALID_ENT_REFERENCE || !IsValidEntity(teleEnt))
    {
        ReplyToCommand(client, "[SM] Selected item no longer exists.");
        delete validEnts;
        delete validSpawnIdx;
        return Plugin_Handled;
    }

    float vPos[3];
    GetEntPropVector(teleEnt, Prop_Data, "m_vecOrigin", vPos);
    TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
    int spawnIdx = validSpawnIdx.Get(g_iTeleportTempIndex);

    char classname[64];
    GetEdictClassname(teleEnt, classname, sizeof(classname));
    LogDebug("TeleportTemp! Client %d to %s, spawn index %d, pos %.0f %.0f %.0f",
    client, classname, spawnIdx, vPos[0], vPos[1], vPos[2]);
    ReplyToCommand(client, "[SM] Teleported to %s (spawn index %d).", classname, spawnIdx);

    g_iTeleportTempIndex++;
    delete validEnts;
    delete validSpawnIdx;
    return Plugin_Handled;
}

Action Cmd_TeleportAmmo(int client, int args)
{
    if (!g_bEnabled) { ReplyToCommand(client, "[SM] Plugin is disabled."); return Plugin_Handled; }

    ArrayList validEnts = new ArrayList();
    ArrayList validSpawnIdx = new ArrayList();
    float vItem[3], vSurv[3];
    bool found;

    // Cleanup‑tracked ammo
    for (int i = 0; i < g_aCleanupItems.Length; i++)
    {
        if (g_aCleanupType.Get(i) != 4) continue;
        int ref = g_aCleanupItems.Get(i);
        int ent = EntRefToEntIndex(ref);
        if (ent == INVALID_ENT_REFERENCE || !IsValidEntity(ent)) continue;

        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vItem);
        bool inRange = false;
        for (int j = 1; j <= MaxClients; j++)
        {
            if (!IsClientInGame(j) || GetClientTeam(j) != 2 || !IsPlayerAlive(j)) continue;
            GetClientAbsOrigin(j, vSurv);
            if (GetVectorDistance(vSurv, vItem) <= g_fAmmoRadius) { inRange = true; break; }
        }
        if (!inRange) continue;

        int ref2 = EntIndexToEntRef(ent);
        if (validEnts.FindValue(ref2) != -1) continue;
        validEnts.Push(ref2);
        validSpawnIdx.Push(g_aCleanupIndex.Get(i));
        found = true;
    }

    // Any ground ammo not tracked
    int entScan = -1;
    while ((entScan = FindEntityByClassname(entScan, "weapon_ammo_spawn")) != -1)
    {
        if (!IsValidEntity(entScan)) continue;
        GetEntPropVector(entScan, Prop_Data, "m_vecOrigin", vItem);
        bool inRange = false;
        for (int j = 1; j <= MaxClients; j++)
        {
            if (!IsClientInGame(j) || GetClientTeam(j) != 2 || !IsPlayerAlive(j)) continue;
            GetClientAbsOrigin(j, vSurv);
            if (GetVectorDistance(vSurv, vItem) <= g_fAmmoRadius) { inRange = true; break; }
        }
        if (!inRange) continue;

        int ref = EntIndexToEntRef(entScan);
        if (validEnts.FindValue(ref) != -1) continue;
        int spawnIdx = -1;
        for (int i = 0; i < g_iSpawnerCount; i++)
        if (GetVectorDistance(vItem, g_vSpawnerPos[i]) < 50.0) { spawnIdx = i; break; }
        validEnts.Push(ref);
        validSpawnIdx.Push(spawnIdx);
        found = true;
    }

    if (!found) { ReplyToCommand(client, "[SM] No ammo entities within range."); delete validEnts; delete validSpawnIdx; return Plugin_Handled; }

    static int teleportAmmoIndex = 0;
    if (teleportAmmoIndex >= validEnts.Length) teleportAmmoIndex = 0;
    int ref = validEnts.Get(teleportAmmoIndex);
    int ent = EntRefToEntIndex(ref);
    if (ent == INVALID_ENT_REFERENCE || !IsValidEntity(ent))
    {
        ReplyToCommand(client, "[SM] Selected ammo entity no longer exists.");
        delete validEnts; delete validSpawnIdx;
        return Plugin_Handled;
    }

    float vPos[3];
    GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vPos);
    TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
    int spawnIdx = validSpawnIdx.Get(teleportAmmoIndex);
    
    if (g_bAmmoDebug)
        LogToFileEx(g_sLogPath, "TeleportAmmo! Client %d to ammo (spawn idx %d)", client, spawnIdx);
    
    ReplyToCommand(client, "[SM] Teleported to ammo #%d (spawn index %d).", teleportAmmoIndex+1, spawnIdx);
    teleportAmmoIndex++;
    delete validEnts; delete validSpawnIdx;
    return Plugin_Handled;
}

Action Timer_UpdateAmmoHud(Handle timer)
{
    if (!g_bEnabled || !g_bAmmoEnable || !g_bAmmoHud || !g_bLeftSafeArea)
        return Plugin_Continue;

    char line[128];

    int ammoInRange = 0;
    float vAmmo[3], vSurv[3];
    int ammoEnt = -1;
    while ((ammoEnt = FindEntityByClassname(ammoEnt, "weapon_ammo_spawn")) != -1)
    {
        GetEntPropVector(ammoEnt, Prop_Data, "m_vecOrigin", vAmmo);
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) continue;
            GetClientAbsOrigin(i, vSurv);
            if (GetVectorDistance(vSurv, vAmmo) <= g_fAmmoRadius)
            {
                ammoInRange++;
                break;
            }
        }
    }

    if (g_iAmmoSpawnMode == 1)
    {
        float lowest = 101.0;
        int needCnt = 0;
        for (int client = 1; client <= MaxClients; client++)
        {
            if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) continue;
            float percent;
            int maxR;
            if (PlayerNeedsAmmo(client, percent, maxR))
            {
                needCnt++;
                if (percent < lowest) lowest = percent;
            }
        }
        if (needCnt > 0)
        {
            Format(line, sizeof(line), "Ammo | %d player(s) low | Lowest %.0f%% | %s",
                needCnt, lowest,
                ammoInRange > 0 ? "pile exists" : "spawn ready");
        }
        else
        {
            Format(line, sizeof(line), "Ammo | All players OK | %s",
                ammoInRange > 0 ? "pile exists" : "no need");
        }
    }
    else
    {
        int totalCurrent = 0, totalMax = 0;
        for (int client = 1; client <= MaxClients; client++)
        {
            if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) continue;
            int primary = GetPlayerWeaponSlot(client, 0);
            if (primary != -1)
            {
                int ammoType = GetEntProp(primary, Prop_Data, "m_iPrimaryAmmoType");
                int extra    = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType);
                int maxRes   = AmmoDef.MaxCarry_Call(ammoType, client);
                totalCurrent += extra;
                totalMax     += maxRes;
            }
        }
        if (totalMax > 0)
        {
            float teamPct = float(totalCurrent) * 100.0 / float(totalMax);
            Format(line, sizeof(line), "Ammo | Team pool %.0f%% (%d/%d) | %s",
                teamPct, totalCurrent, totalMax,
                (teamPct <= g_fAmmoThreshold && ammoInRange == 0) ? "spawn ready" :
                (teamPct <= g_fAmmoThreshold && ammoInRange > 0) ? "pile exists" :
                "no need");
        }
        else
        {
            Format(line, sizeof(line), "Ammo | Team pool unknown");
        }
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && (GetUserFlagBits(i) & ADMFLAG_ROOT))
            PrintHintText(i, "%s", line);
    }

    return Plugin_Continue;
}

Action Timer_UpdateTempHealthSpawnHud(Handle timer)
{
    if (!g_bEnabled || !g_bTempHealthSpawnEnable || !g_bTempHealthSpawnHud || !g_bLeftSafeArea)
        return Plugin_Continue;

    char line[128];
    float curFlow = GetLeadingSurvivorFlow();

    int need = 0;
    bool uncovered = false;
    float vSurvPos[3], vTemp[3];

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) continue;

        int tempSlot = GetPlayerWeaponSlot(client, 4);
        bool bHasTempItem = (tempSlot != -1 && IsValidEntity(tempSlot));

        float buf = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
        float bufTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
        float currentBuffer = 0.0;
        if (buf > 0.0 && bufTime > 0.0)
        {
            currentBuffer = buf - g_fCvar_PillsDecay * (GetGameTime() - bufTime);
            if (currentBuffer < 0.0) currentBuffer = 0.0;
        }

        if (g_bHasItemTempHealth[client] && currentBuffer <= 0.0)
            g_bHasItemTempHealth[client] = false;

        bool bHasTempHealth = g_bHasItemTempHealth[client];

        if (!bHasTempItem && !bHasTempHealth)
        {
            need++;

            bool bHasGroundItem = false;
            int ent = -1;

            while ((ent = FindEntityByClassname(ent, "weapon_pain_pills")) != -1)
            {
                if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
                GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                GetClientAbsOrigin(client, vSurvPos);
                if (GetVectorDistance(vSurvPos, vTemp) <= g_fTempHealthRadius)
                { bHasGroundItem = true; break; }
            }
            if (!bHasGroundItem)
            {
                ent = -1;
                while ((ent = FindEntityByClassname(ent, "weapon_adrenaline")) != -1)
                {
                    if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
                    GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                    GetClientAbsOrigin(client, vSurvPos);
                    if (GetVectorDistance(vSurvPos, vTemp) <= g_fTempHealthRadius)
                    { bHasGroundItem = true; break; }
                }
            }
            if (!bHasGroundItem)
            {
                ent = -1;
                while ((ent = FindEntityByClassname(ent, "weapon_pain_pills_spawn")) != -1)
                {
                    GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                    GetClientAbsOrigin(client, vSurvPos);
                    if (GetVectorDistance(vSurvPos, vTemp) <= g_fTempHealthRadius)
                    { bHasGroundItem = true; break; }
                }
            }
            if (!bHasGroundItem)
            {
                ent = -1;
                while ((ent = FindEntityByClassname(ent, "weapon_adrenaline_spawn")) != -1)
                {
                    GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                    GetClientAbsOrigin(client, vSurvPos);
                    if (GetVectorDistance(vSurvPos, vTemp) <= g_fTempHealthRadius)
                    { bHasGroundItem = true; break; }
                }
            }
            if (!bHasGroundItem)
            {
                ent = -1;
                while ((ent = FindEntityByClassname(ent, "weapon_item_spawn")) != -1)
                {
                    char sItem[32];
                    if (!GetItemSpawnerType(ent, sItem, sizeof(sItem))) continue;
                    if (StrEqual(sItem, "pain_pills", false) || StrEqual(sItem, "adrenaline", false))
                    {
                        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                        GetClientAbsOrigin(client, vSurvPos);
                        if (GetVectorDistance(vSurvPos, vTemp) <= g_fTempHealthRadius)
                        { bHasGroundItem = true; break; }
                    }
                }
            }

            if (!bHasGroundItem)
                uncovered = true;
        }
    }

    if (!uncovered)
        Format(line, sizeof(line), "TempHealth | All covered");
    else if (g_bTempHealthSpawnPending)
        Format(line, sizeof(line), "TempHealth | Need: %d | Pending", need);
    else
        Format(line, sizeof(line), "TempHealth | Need: %d | Flow: %.0f / %.0f", need, curFlow, g_fTempHealthSpawnNextFlow);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && (GetUserFlagBits(i) & ADMFLAG_ROOT))
            PrintHintText(i, "%s", line);
    }

    return Plugin_Continue;
}


Action Timer_UpdateThrowableHud(Handle timer)
{
    if (!g_bEnabled || !g_bThrowableEnable || !g_bThrowableHud || !g_bLeftSafeArea)
        return Plugin_Continue;

    char line[128];
    float curFlow = GetLeadingSurvivorFlow();

    int need = 0;
    float vSurvPos[3], vTemp[3];

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) continue;

        int throwSlot = GetPlayerWeaponSlot(client, 2);
        bool bHasThrowable = (throwSlot != -1 && IsValidEntity(throwSlot));

        if (!bHasThrowable)
        {
            int ent = -1;
            while ((ent = FindEntityByClassname(ent, "weapon_pipe_bomb")) != -1)
            {
                if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
                GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                GetClientAbsOrigin(client, vSurvPos);
                if (GetVectorDistance(vSurvPos, vTemp) <= g_fThrowableRadius) { bHasThrowable = true; break; }
            }
        }
        if (!bHasThrowable)
        {
            int ent = -1;
            while ((ent = FindEntityByClassname(ent, "weapon_molotov")) != -1)
            {
                if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
                GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                GetClientAbsOrigin(client, vSurvPos);
                if (GetVectorDistance(vSurvPos, vTemp) <= g_fThrowableRadius) { bHasThrowable = true; break; }
            }
        }
        if (!bHasThrowable)
        {
            int ent = -1;
            while ((ent = FindEntityByClassname(ent, "weapon_vomitjar")) != -1)
            {
                if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
                GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                GetClientAbsOrigin(client, vSurvPos);
                if (GetVectorDistance(vSurvPos, vTemp) <= g_fThrowableRadius) { bHasThrowable = true; break; }
            }
        }

        if (!bHasThrowable)
        {
            int ent = -1;
            while ((ent = FindEntityByClassname(ent, "weapon_item_spawn")) != -1)
            {
                char sItem[32];
                if (!GetItemSpawnerType(ent, sItem, sizeof(sItem))) continue;
                if (StrEqual(sItem, "pipe_bomb", false) || StrEqual(sItem, "molotov", false) || StrEqual(sItem, "vomitjar", false))
                {
                    GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                    GetClientAbsOrigin(client, vSurvPos);
                    if (GetVectorDistance(vSurvPos, vTemp) <= g_fThrowableRadius) { bHasThrowable = true; break; }
                }
            }
        }

        if (!bHasThrowable)
        {
            int ent = -1;
            while ((ent = FindEntityByClassname(ent, "weapon_molotov_spawn")) != -1)
            {
                GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                GetClientAbsOrigin(client, vSurvPos);
                if (GetVectorDistance(vSurvPos, vTemp) <= g_fThrowableRadius) { bHasThrowable = true; break; }
            }
        }
        if (!bHasThrowable)
        {
            int ent = -1;
            while ((ent = FindEntityByClassname(ent, "weapon_pipe_bomb_spawn")) != -1)
            {
                GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                GetClientAbsOrigin(client, vSurvPos);
                if (GetVectorDistance(vSurvPos, vTemp) <= g_fThrowableRadius) { bHasThrowable = true; break; }
            }
        }
        if (!bHasThrowable)
        {
            int ent = -1;
            while ((ent = FindEntityByClassname(ent, "weapon_vomitjar_spawn")) != -1)
            {
                GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                GetClientAbsOrigin(client, vSurvPos);
                if (GetVectorDistance(vSurvPos, vTemp) <= g_fThrowableRadius) { bHasThrowable = true; break; }
            }
        }

        if (!bHasThrowable)
            need++;
    }

    if (g_bThrowableCoverage)
    {
        if (need == 0)
            Format(line, sizeof(line), "Throwables | All covered");
        else if (g_bThrowablePending)
            Format(line, sizeof(line), "Throwables | Need: %d | Pending", need);
        else
            Format(line, sizeof(line), "Throwables | Need: %d | Flow: %.0f / %.0f", need, curFlow, g_fThrowableNextFlow);
    }
    else
    {
        if (g_bThrowablePending)
            Format(line, sizeof(line), "Throwables | Pending");
        else
            Format(line, sizeof(line), "Throwables | Flow: %.0f / %.0f", curFlow, g_fThrowableNextFlow);
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && (GetUserFlagBits(i) & ADMFLAG_ROOT))
            PrintHintText(i, "%s", line);
    }

    return Plugin_Continue;
}

Action Timer_UpdateLaserSightHud(Handle timer)
{
    if (!g_bEnabled || !g_bLaserSightEnable || !g_bLaserSightHud || !g_bLeftSafeArea)
        return Plugin_Continue;

    char line[128];
    float curFlow = GetLeadingSurvivorFlow();

    if (g_bLaserSightPending)
        Format(line, sizeof(line), "LaserSight | Pending");
    else if (g_fLaserSightNextFlow > 0.0)
        Format(line, sizeof(line), "LaserSight | Flow: %.0f / %.0f", curFlow, g_fLaserSightNextFlow);
    else
        Format(line, sizeof(line), "LaserSight | Flow: %.0f (no target)", curFlow);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && (GetUserFlagBits(i) & ADMFLAG_ROOT))
            PrintHintText(i, "%s", line);
    }

    return Plugin_Continue;
}

// Propose helpers
int GetAliveSurvivorCount()
{
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
    if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
    count++;
    return count;
}

Action Timer_UpdateUpgradePackHud(Handle timer)
{
    if (!g_bEnabled || !g_bUpgradePackEnable || !g_bUpgradePackHud || !g_bLeftSafeArea)
        return Plugin_Continue;

    char line[128];
    float curFlow = GetLeadingSurvivorFlow();

    if (g_bUpgradePackPending)
        Format(line, sizeof(line), "UpgradePack | Pending");
    else if (g_fUpgradePackNextFlow > 0.0)
        Format(line, sizeof(line), "UpgradePack | Flow: %.0f / %.0f", curFlow, g_fUpgradePackNextFlow);
    else
        Format(line, sizeof(line), "UpgradePack | Flow: %.0f (no target)", curFlow);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && (GetUserFlagBits(i) & ADMFLAG_ROOT))
            PrintHintText(i, "%s", line);
    }
    return Plugin_Continue;
}

void ClearProposeInitial()
{
    g_bProposeInitialDone = false;
    g_iProposeInitialSpawned = 0;
    g_fProposeNextFlow = -1.0;
    g_fProposeRemaining = 0.0;
    g_bProposePendingSpawn = false;
}

void ResetProposeInitial(bool bMapStart, bool bCampaignStart)
{
    int mode = g_iProposeInitialClear;
    if (mode == 0)                          // clear on round start & map start
    {
        ClearProposeInitial();
    }
    else if (mode == 1 && bMapStart)        // map start only
    {
        ClearProposeInitial();
    }
    else if (mode == 2 && bCampaignStart)   // campaign start only
    {
        ClearProposeInitial();
    }
}

void ResetMedkitInitial(bool bMapStart, bool bCampaignStart)
{
    int mode = g_iConditionInitialClear;
    if (mode == 0)  // clear on round start & map start → always clear
    {
        ClearMedkitInitial();
    }
    else if (mode == 1 && bMapStart)        // map start only
    {
        ClearMedkitInitial();
    }
    else if (mode == 2 && bCampaignStart)   // campaign start only
    {
        ClearMedkitInitial();
    }
    // mode 3 – never clear → do nothing
}

void ClearMedkitInitial()
{
    g_fLastInitialSpawn = 0.0;
    g_iInitialKitsGiven = 0;
}

// Proximity timer (weapon, ammo, throwables, lasers)
Action Timer_CheckProximity(Handle timer)
{
    if (!g_bEnabled || g_iSpawnerCount == 0)
    return Plugin_Continue;
    if (g_bRequireLeftSafeArea && !g_bLeftSafeArea)
    return Plugin_Continue;

    float fGameTime = GetGameTime();

    // Bypass cooldown
    if (g_fBypassCooldown > 0.0)
    {
        for (int i = 0; i < g_iSpawnerCount; i++)
        {
            if (g_fBypassTime[i] > 0.0 && (fGameTime - g_fBypassTime[i] < g_fBypassCooldown))
            continue;

            bool entered = false;
            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
                continue;

                float vClientOrigin[3];
                GetClientAbsOrigin(client, vClientOrigin);
float dist = GetVectorDistance(vClientOrigin, g_vSpawnerPos[i]);
if (dist <= g_fMedkitRadiusIgnore     || dist <= g_fDefibRadiusIgnore ||
    dist <= g_fWeaponRadiusIgnore     || dist <= g_fAmmoRadiusIgnore   ||
    dist <= g_fThrowableRadiusIgnore  || dist <= g_fLaserSightRadiusIgnore ||
    dist <= g_fUpgradePackRadiusIgnore || dist <= g_fTempHealthSpawnIgnoreRadius)
{
    entered = true;
    break;
}
            }
            if (entered)
            {
                g_fBypassTime[i] = fGameTime;
                LogDebug("Bypass cooldown started for index %d", i);
            }
        }
    }

    // Adaptive weapon spawning
    if (g_bWeaponEnable)
    {
        LogDebug("Weapon check running...");

        // Direct entity index scan
        float vGroundWeaponPos[2048][3];
        char  sGroundWeaponClass[2048][64];
        int iGroundWeaponCount = 0;
        int maxEnts = GetMaxEntities();
        char cls[64];
        for (int ent = MaxClients + 1; ent <= maxEnts; ent++)
        {
            if (!IsValidEntity(ent)) continue;
            GetEdictClassname(ent, cls, sizeof(cls));
            if (StrContains(cls, "weapon_") != 0) continue;

            if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;

            bool isPrimary = false;

            if (StrContains(cls, "_spawn") != -1)
            {
                if (StrEqual(cls, "weapon_item_spawn"))
                {
                    char sItem[32];
                    if (GetItemSpawnerType(ent, sItem, sizeof(sItem)))
                    {
                        char fullName[64];
                        Format(fullName, sizeof(fullName), "weapon_%s", sItem);
                        for (int w = 0; w < sizeof(g_sWeapons); w++)
                        if (StrEqual(fullName, g_sWeapons[w], false)) { isPrimary = true; break; }
                    }
                }
                else if (StrEqual(cls, "weapon_spawn"))
                {
                    int wepID = GetEntProp(ent, Prop_Send, "m_weaponID");
                    if (wepID == 2   // SMG
                        || wepID == 3   // Pump Shotgun
                        || wepID == 4   // Auto Shotgun
                        || wepID == 5   // Rifle
                        || wepID == 6   // Hunting Rifle
                        || wepID == 7   // SMG Silenced
                        || wepID == 8   // Shotgun Chrome
                        || wepID == 9   // Rifle Desert
                        || wepID == 10  // Sniper Military
                        || wepID == 11  // Shotgun SPAS
                        || wepID == 21  // Grenade Launcher
                        || wepID == 26  // AK47
                        || wepID == 33  // MP5
                        || wepID == 34  // SG552
                        || wepID == 35  // AWP
                        || wepID == 36  // Scout
                        || wepID == 37) // M60
                    {
                        isPrimary = true;
                    }
                }
                else
                {
                    char baseName[64];
                    strcopy(baseName, sizeof(baseName), cls);
                    int len = strlen(baseName) - 6;
                    if (len > 0) baseName[len] = '\0';
                    for (int w = 0; w < sizeof(g_sWeapons); w++)
                    if (StrEqual(baseName, g_sWeapons[w], false)) { isPrimary = true; break; }
                }
            }
            else   // Physical weapon
            {
                for (int w = 0; w < sizeof(g_sWeapons); w++)
                if (StrEqual(cls, g_sWeapons[w], false)) { isPrimary = true; break; }

                // Skip low‑ammo weapons only when ammo‑based spawning is active
                if (isPrimary && g_fWeaponAmmoPercent >= 0)
                {
                    float fPercent = 0.0;
                    bool bValid = false;

                    int ammoType = GetEntProp(ent, Prop_Data, "m_iPrimaryAmmoType");
                    int clip = GetEntProp(ent, Prop_Send, "m_iClip1");
                    int extra = GetEntProp(ent, Prop_Send, "m_iExtraPrimaryAmmo");

                    if (StrEqual(cls, "weapon_rifle_m60"))
                    {
                        fPercent = float(clip) * 100.0 / 150.0;
                        bValid = true;
                    }
                    else
                    {
                        int maxReserve = AmmoDef.MaxCarry_Call(ammoType, 0);
                        if (maxReserve > 0)
                        {
                            fPercent = float(extra) * 100.0 / float(maxReserve);
                            bValid = true;
                        }
                    }

                    if (bValid && fPercent <= g_fWeaponAmmoPercent)
                    {
                        isPrimary = false;
                    }
                }
            }

            if (!isPrimary) continue;

            GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vGroundWeaponPos[iGroundWeaponCount]);
            strcopy(sGroundWeaponClass[iGroundWeaponCount], sizeof(sGroundWeaponClass[]), cls);
            iGroundWeaponCount++;
            if (iGroundWeaponCount >= 2048) break;
        }

        static float fLastWeaponCountLogTime = 0.0;
        if (fGameTime - fLastWeaponCountLogTime >= 5.0)
        {
            fLastWeaponCountLogTime = fGameTime;
            if (g_bWeaponDebug)
            LogToFileEx(g_sLogPath, "Weapon check: found %d ground primary weapons (incl. spawners)", iGroundWeaponCount);
        }

        float vClientOrigin[3];
        for (int client = 1; client <= MaxClients; client++)
        {
            if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
            continue;

            bool bNeedsWeapon = false;
            int primary = GetPlayerWeaponSlot(client, 0);

            if (primary == -1 && g_bWeaponNoPrimarySpawn)
            {
                bNeedsWeapon = true;
                if (g_bWeaponDebug)
                LogDebug("Client %d needs weapon (no primary)", client);
            }
            else if (primary != -1 && g_fWeaponAmmoPercent >= 0)
            {
                char wepClass[64];
                GetEdictClassname(primary, wepClass, sizeof(wepClass));
                int ammoType = GetEntProp(primary, Prop_Data, "m_iPrimaryAmmoType");
                int extra = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType);

                int maxReserve = 0;
                bool bM60Special = false;

                if (StrEqual(wepClass, "weapon_rifle_m60"))
                {
                    ConVar hM60 = FindConVar("ammo_m60_max");
                    if (hM60 != null && hM60.IntValue > 0)
                    maxReserve = hM60.IntValue;
                    else
                    bM60Special = true;
                }
                else
                {
                    maxReserve = AmmoDef.MaxCarry_Call(ammoType, client);
                }

                float percent;
                if (bM60Special)
                {
                    int clip = GetEntProp(primary, Prop_Send, "m_iClip1");
                    percent = float(clip) * 100.0 / 150.0;
                    if (g_bWeaponDebug)
                    LogDebug("Client %d ammo: weapon=M60 (no reserve) clip=%d maxClip=150 percent=%.1f%%", client, clip, percent);
                }
                else
                {
                    if (maxReserve <= 0)
                    {
                        if (g_bWeaponDebug)
                        LogDebug("Client %d ammo: weapon=%s – max reserve unknown, skipping", client, wepClass);
                        continue;
                    }
                    percent = float(extra) * 100.0 / float(maxReserve);
                    if (g_bWeaponDebug)
                    LogDebug("Client %d ammo: weapon=%s extra=%d maxReserve=%d percent=%.1f%% threshold=%.0f%%",
                    client, wepClass, extra, maxReserve, percent, g_fWeaponAmmoPercent);
                }

                if (percent <= g_fWeaponAmmoPercent)
                {
                    bNeedsWeapon = true;
                    if (g_bWeaponDebug)
                    LogDebug("Client %d needs weapon (ammo %.1f%% <= %.0f%%)", client, percent, g_fWeaponAmmoPercent);
                }
                else if (g_bWeaponDebug)
                LogDebug("Client %d does NOT need weapon (ammo %.1f%%)", client, percent);
            }

            if (!bNeedsWeapon)
            continue;

            GetClientAbsOrigin(client, vClientOrigin);

            bool bWeaponNearby = false;
            for (int i = 0; i < iGroundWeaponCount; i++)
            {
                if (GetVectorDistance(vClientOrigin, vGroundWeaponPos[i]) <= g_fWeaponRadius)
                {
                    bWeaponNearby = true;
                    break;
                }
            }

            if (bWeaponNearby)
            {
                if (g_bWeaponDebug)
                {
                    LogDebug("Client %d has a weapon nearby – skipping spawn. Nearby weapons:", client);
                    for (int i = 0; i < iGroundWeaponCount; i++)
                    {
                        float dist = GetVectorDistance(vClientOrigin, vGroundWeaponPos[i]);
                        if (dist <= g_fWeaponRadius)
                        LogDebug("   [%d] %s (distance %.0f)", i, sGroundWeaponClass[i], dist);
                    }
                }
                else
                LogDebug("Client %d has a weapon nearby – skipping spawn", client);
                continue;
            }

            int bestIdx = -1;
            float bestDist = 999999.0;
            for (int i = 0; i < g_iSpawnerCount; i++)
            {
                if (g_bUsedIndex[i] || g_bWeaponSpawned[i] || g_bMedkitSpawned[i] || g_bDefibSpawned[i] || g_bTempHealthSpawned[i] || g_bThrowableSpawned[i] || g_bLaserSightSpawned[i] || g_bUpgradePackSpawned[i]) continue;
                if (g_bNearCabinet[i] && !g_bWeaponNearCabinet)
                continue;
                if (g_bNearSaferoom[i] && g_fSaferoomIgnoreRadius > 0.0)
                continue;
                if (g_bNearFinale[i] && g_fFinaleIgnoreRadius > 0.0)
                continue;

                if (!g_bSpawnIfVisible)
                {
                    float vTarget[3];
                    vTarget = g_vSpawnerPos[i];
                    vTarget[2] += 30.0;
                    if (IsPositionVisibleToAnySurvivor(vTarget))
                    {
                        if (g_fFailCooldown > 0.0)
                        {
                            if (fGameTime - g_fLastVisibilityFail[i] >= g_fFailCooldown)
                            g_fLastVisibilityFail[i] = fGameTime;
                        }
                        continue;
                    }
                    if (g_fFailCooldown > 0.0 && g_fLastVisibilityFail[i] > 0.0)
                    {
                        if (fGameTime - g_fLastVisibilityFail[i] < g_fFailCooldown)
                        continue;
                    }
                }

                if (g_fBypassCooldown > 0.0 && g_fBypassTime[i] > 0.0)
                {
                    if (fGameTime - g_fBypassTime[i] < g_fBypassCooldown)
                    continue;
                }

                float dist = GetVectorDistance(vClientOrigin, g_vSpawnerPos[i]);
                if (dist >= g_fWeaponRadiusIgnore && dist <= g_fWeaponRadius)
                {
                    if (dist < bestDist) { bestDist = dist; bestIdx = i; }
                }
            }

            if (bestIdx != -1)
            {
                int weapon = SpawnWeaponAt(bestIdx);
                if (weapon != -1)
                {
                    g_bWeaponSpawned[bestIdx] = true;
                    g_bUsedIndex[bestIdx] = true;
                    if (g_bWeaponDebug)
                    LogDebug(">>> SPAWNED WEAPON for client %d at index %d (dist %.0f)", client, bestIdx, bestDist);
                    if (g_bCleanupEnable)
                    {
                        g_aCleanupItems.Push(EntIndexToEntRef(weapon));
                        g_aCleanupTimers.Push(0.0);
                        g_aCleanupIndex.Push(bestIdx);
                        g_aCleanupType.Push(0);
                    }
                }
            }
            else if (g_bWeaponDebug)
            LogDebug("No valid spawn point for client %d within weapon ring [%.0f, %.0f]", client, g_fWeaponRadiusIgnore, g_fWeaponRadius);
        }
    }

    // Weapon Propose
    if (g_bWeaponPropose)
    {
        int lead = GetLeadingSurvivorClient();
        if (lead != 0)
        {
            float vLead[3];
            GetClientAbsOrigin(lead, vLead);

            int aliveCount = GetAliveSurvivorCount();
            float curFlow = GetLeadingSurvivorFlow();

            if (g_bProposeDebug)
            {
                LogToFileEx(g_sLogPath, "ProposeDebug: State: initialDone=%d, spawned=%d, alive=%d, pending=%d, nextFlow=%.0f, curFlow=%.0f",
                g_bProposeInitialDone, g_iProposeInitialSpawned, aliveCount, g_bProposePendingSpawn, g_fProposeNextFlow, curFlow);
            }

            // Pending spawn from previous failed attempt
            if (g_bProposePendingSpawn)
            {
                if (g_bProposeDebug)
                LogToFileEx(g_sLogPath, "ProposeDebug: Attempting to fulfill pending spawn...");

                int bestIdx = -1;
                float bestDist = 999999.0;
                for (int i = 0; i < g_iSpawnerCount; i++)
                {
                    if (g_bUsedIndex[i] || g_bWeaponSpawned[i] || g_bMedkitSpawned[i] || g_bDefibSpawned[i] || g_bTempHealthSpawned[i] || g_bThrowableSpawned[i] || g_bLaserSightSpawned[i] || g_bUpgradePackSpawned[i]) continue;
                    if (g_bNearCabinet[i] && !g_bWeaponNearCabinet) continue;
                    if (g_bNearSaferoom[i] && g_fSaferoomIgnoreRadius > 0.0) continue;
                    if (g_bNearFinale[i] && g_fFinaleIgnoreRadius > 0.0) continue;

                    float vTarget[3];
                    vTarget = g_vSpawnerPos[i];
                    vTarget[2] += 30.0;
                    if (!g_bSpawnIfVisible && IsPositionVisibleToAnySurvivor(vTarget))
                    {
                        if (g_fFailCooldown > 0.0 && (fGameTime - g_fLastVisibilityFail[i] >= g_fFailCooldown))
                        g_fLastVisibilityFail[i] = fGameTime;
                        if (g_bProposeDebug)
                        LogToFileEx(g_sLogPath, "ProposeDebug: Pending spawn skipped index %d (visible, fail cooldown updated)", i);
                        continue;
                    }
                    if (g_fFailCooldown > 0.0 && g_fLastVisibilityFail[i] > 0.0 && (fGameTime - g_fLastVisibilityFail[i] < g_fFailCooldown))
                    {
                        if (g_bProposeDebug)
                        LogToFileEx(g_sLogPath, "ProposeDebug: Pending spawn skipped index %d (visibility cooldown %d)", i, g_fLastVisibilityFail[i]);
                        continue;
                    }
                    if (g_fBypassCooldown > 0.0 && g_fBypassTime[i] > 0.0 && (fGameTime - g_fBypassTime[i] < g_fBypassCooldown))
                    {
                        if (g_bProposeDebug)
                        LogToFileEx(g_sLogPath, "ProposeDebug: Pending spawn skipped index %d (bypass cooldown %d)", i, g_fBypassTime[i]);
                        continue;
                    }

                    float dist = GetVectorDistance(vLead, g_vSpawnerPos[i]);
                    if (dist >= g_fWeaponRadiusIgnore && dist <= g_fWeaponRadius)
                    {
                        if (dist < bestDist) { bestDist = dist; bestIdx = i; }
                    }
                }

                if (bestIdx != -1)
                {
                    int weapon = SpawnWeaponAt(bestIdx);
                    if (weapon != -1)
                    {
                        g_bWeaponSpawned[bestIdx] = true;
                        g_bUsedIndex[bestIdx] = true;
                        g_bProposePendingSpawn = false;
                        if (!g_bProposeInitialDone)
                        g_iProposeInitialSpawned++;

                        // Setting new target flow – store remaining
                        if (g_bProposeInitialDone)
                        {
                            g_fProposeNextFlow = curFlow + GetRandomFloat(g_fProposeMin, g_fProposeMax);
                            g_fProposeRemaining = g_fProposeNextFlow - curFlow;
                        }
                        else
                        {
                            g_fProposeNextFlow = curFlow + GetRandomFloat(g_fProposeInitialMin, g_fProposeInitialMax);
                            g_fProposeRemaining = g_fProposeNextFlow - curFlow;
                        }

                        if (g_bCleanupEnable)
                        {
                            g_aCleanupItems.Push(EntIndexToEntRef(weapon));
                            g_aCleanupTimers.Push(0.0);
                            g_aCleanupIndex.Push(bestIdx);
                            g_aCleanupType.Push(0);
                        }
                        if (g_bProposeDebug)
                        LogToFileEx(g_sLogPath, "ProposeDebug: Spawned pending weapon at index %d, next flow = %.0f", bestIdx, g_fProposeNextFlow);
                    }
                }
                else if (g_bProposeDebug)
                LogToFileEx(g_sLogPath, "ProposeDebug: Pending spawn failed – no valid spawn point found");
            }
            else   
            {
                bool bNeedSpawn = false;
                if (!g_bProposeInitialDone)
                {
                    if (g_iProposeInitialSpawned < aliveCount)
                    {
                        bNeedSpawn = true;
                        if (g_bProposeDebug)
                        LogToFileEx(g_sLogPath, "ProposeDebug: Initial phase – need more spawns (%d/%d)", g_iProposeInitialSpawned, aliveCount);
                    }
                    else
                    {
                        g_bProposeInitialDone = true; 
                        if (g_bProposeDebug)
                        LogToFileEx(g_sLogPath, "ProposeDebug: Initial phase complete, switching to ongoing");
                    }
                }
                else
                {
                    bNeedSpawn = true;
                }

                if (bNeedSpawn)
                {
                    if (g_fProposeNextFlow < 0.0)
                    {
                        if (!g_bProposeInitialDone)
                        {
                            g_fProposeNextFlow = curFlow + GetRandomFloat(g_fProposeInitialMin, g_fProposeInitialMax);
                            g_fProposeRemaining = g_fProposeNextFlow - curFlow;
                        }
                        else
                        {
                            g_fProposeNextFlow = curFlow + GetRandomFloat(g_fProposeMin, g_fProposeMax);
                            g_fProposeRemaining = g_fProposeNextFlow - curFlow;
                        }
                        if (g_bProposeDebug)
                        LogToFileEx(g_sLogPath, "ProposeDebug: Set new flow target %.0f (phase=%s)", g_fProposeNextFlow, g_bProposeInitialDone ? "ongoing" : "initial");
                    }

                    if (curFlow >= g_fProposeNextFlow)
                    {
                        if (g_bProposeDebug)
                        LogToFileEx(g_sLogPath, "ProposeDebug: Flow target reached (%.0f >= %.0f), attempting spawn", curFlow, g_fProposeNextFlow);

                        int bestIdx = -1;
                        float bestDist = 999999.0;
                        for (int i = 0; i < g_iSpawnerCount; i++)
                        {
                    if (g_bUsedIndex[i] || g_bWeaponSpawned[i] || g_bMedkitSpawned[i] || g_bDefibSpawned[i] || g_bTempHealthSpawned[i] || g_bThrowableSpawned[i] || g_bLaserSightSpawned[i] || g_bUpgradePackSpawned[i]) continue;
                            if (g_bNearCabinet[i] && !g_bWeaponNearCabinet) continue;
                            if (g_bNearSaferoom[i] && g_fSaferoomIgnoreRadius > 0.0) continue;
                            if (g_bNearFinale[i] && g_fFinaleIgnoreRadius > 0.0) continue;

                            float vTarget[3];
                            vTarget = g_vSpawnerPos[i];
                            vTarget[2] += 30.0;
                            if (!g_bSpawnIfVisible && IsPositionVisibleToAnySurvivor(vTarget))
                            {
                                if (g_fFailCooldown > 0.0 && (fGameTime - g_fLastVisibilityFail[i] >= g_fFailCooldown))
                                    g_fLastVisibilityFail[i] = fGameTime;
                                if (g_bProposeDebug)
                                    LogToFileEx(g_sLogPath, "ProposeDebug: Spawn point %d rejected (visible)", i);
                                continue;
                            }
                            if (g_fFailCooldown > 0.0 && g_fLastVisibilityFail[i] > 0.0 && (fGameTime - g_fLastVisibilityFail[i] < g_fFailCooldown))
                            {
                                if (g_bProposeDebug)
                                    LogToFileEx(g_sLogPath, "ProposeDebug: Spawn point %d rejected (fail cooldown)", i);
                                continue;
                            }
                            if (g_fBypassCooldown > 0.0 && g_fBypassTime[i] > 0.0 && (fGameTime - g_fBypassTime[i] < g_fBypassCooldown))
                            {
                                if (g_bProposeDebug)
                                    LogToFileEx(g_sLogPath, "ProposeDebug: Spawn point %d rejected (bypass cooldown)", i);
                                continue;
                            }

                            float dist = GetVectorDistance(vLead, g_vSpawnerPos[i]);
                            if (dist >= g_fWeaponRadiusIgnore && dist <= g_fWeaponRadius)
                            {
                                if (dist < bestDist) { bestDist = dist; bestIdx = i; }
                            }
                        }

                        if (bestIdx != -1)
                        {
                            int weapon = SpawnWeaponAt(bestIdx);
                            if (weapon != -1)
                            {
                                g_bWeaponSpawned[bestIdx] = true;
                                g_bUsedIndex[bestIdx] = true;
                                if (!g_bProposeInitialDone)
                                    g_iProposeInitialSpawned++;

                                if (g_bProposeInitialDone)
                                {
                                    g_fProposeNextFlow = curFlow + GetRandomFloat(g_fProposeMin, g_fProposeMax);
                                    g_fProposeRemaining = g_fProposeNextFlow - curFlow;
                                }
                                else
                                {
                                    g_fProposeNextFlow = curFlow + GetRandomFloat(g_fProposeInitialMin, g_fProposeInitialMax);
                                    g_fProposeRemaining = g_fProposeNextFlow - curFlow;
                                }

                                if (g_bCleanupEnable)
                                {
                                    g_aCleanupItems.Push(EntIndexToEntRef(weapon));
                                    g_aCleanupTimers.Push(0.0);
                                    g_aCleanupIndex.Push(bestIdx);
                                    g_aCleanupType.Push(0);
                                }
                                if (g_bProposeDebug)
                                LogToFileEx(g_sLogPath, "ProposeDebug: Spawned weapon at index %d, next flow = %.0f", bestIdx, g_fProposeNextFlow);
                            }
                            else
                            {
                                g_bProposePendingSpawn = true;
                                if (g_bProposeDebug)
                                LogToFileEx(g_sLogPath, "ProposeDebug: Spawn failed (CreateEntityByName returned -1), setting pending");
                            }
                        }
                        else
                        {
                            g_bProposePendingSpawn = true;
                            if (g_bProposeDebug)
                            LogToFileEx(g_sLogPath, "ProposeDebug: No valid spawn point found, setting pending");
                        }
                    }
                }
            }
        }
    }

    // Ammo spawning
    if (g_bAmmoEnable && g_fAmmoThreshold >= 0.0)
    {
        // Count existing ground ammo piles within range
        int ammoInRange = 0;
        float vAmmo[3], vSurv[3];
        int ammoEnt = -1;
        while ((ammoEnt = FindEntityByClassname(ammoEnt, "weapon_ammo_spawn")) != -1)
        {
            GetEntPropVector(ammoEnt, Prop_Data, "m_vecOrigin", vAmmo);
            for (int i = 1; i <= MaxClients; i++)
            {
                if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) continue;
                GetClientAbsOrigin(i, vSurv);
                if (GetVectorDistance(vSurv, vAmmo) <= g_fAmmoRadius)
                {
                    ammoInRange++;
                    break;
                }
            }
        }

        if (g_bAmmoDebug)
        LogToFileEx(g_sLogPath, "AmmoDebug: Ground ammo piles in range = %d", ammoInRange);

        // Determine if spawn is needed based on mode
        bool bShouldSpawn = false;
        int spawnForClient = 0;

        switch (g_iAmmoSpawnMode)
        {
            case 1:   // per player
            {
                for (int client = 1; client <= MaxClients; client++)
                {
                    if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) continue;
                    int primary = GetPlayerWeaponSlot(client, 0);
                    if (primary == -1)
                    {
                        if (g_bAmmoDebug)
                        LogToFileEx(g_sLogPath, "AmmoDebug: Player %d has no primary – skipped", client);
                        continue;
                    }
                    char wepClass[64];
                    GetEdictClassname(primary, wepClass, sizeof(wepClass));
                    float percent;
                    int maxR;
                    if (PlayerNeedsAmmo(client, percent, maxR))
                    {
                        if (g_bAmmoDebug)
                        LogToFileEx(g_sLogPath, "AmmoDebug: Player %d weapon=%s ammo=%.1f%% (threshold %.1f%%) – needs ammo",
                        client, wepClass, percent, g_fAmmoThreshold);
                        if (ammoInRange == 0)
                        {
                            bShouldSpawn = true;
                            spawnForClient = client;
                            break;
                        }
                        else
                        {
                            if (g_bAmmoDebug)
                            LogToFileEx(g_sLogPath, "AmmoDebug: Spawn blocked – %d ammo pile(s) already in range", ammoInRange);
                        }
                    }
                    else
                    {
                        if (g_bAmmoDebug)
                        LogToFileEx(g_sLogPath, "AmmoDebug: Player %d weapon=%s ammo=%.1f%% (threshold %.1f%%) – OK",
                        client, wepClass, percent, g_fAmmoThreshold);
                    }
                }
            }
            case 2:   // team pool
            {
                int totalCurrent = 0, totalMax = 0;
                char debugLine[512];
                bool first = true;
                Format(debugLine, sizeof(debugLine), "AmmoDebug: Team pool – ");
                for (int client = 1; client <= MaxClients; client++)
                {
                    if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) continue;
                    int primary = GetPlayerWeaponSlot(client, 0);
                    if (primary != -1)
                    {
                        char wepClass[64];
                        GetEdictClassname(primary, wepClass, sizeof(wepClass));
                        int ammoType = GetEntProp(primary, Prop_Data, "m_iPrimaryAmmoType");
                        int extra    = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType);
                        int maxRes   = AmmoDef.MaxCarry_Call(ammoType, client);
                        totalCurrent += extra;
                        totalMax     += maxRes;
                        if (g_bAmmoDebug)
                        {
                            Format(debugLine, sizeof(debugLine), "%s%s%d/%d (%s)" , debugLine,
                            first ? "" : " + ",
                            extra, maxRes, wepClass);
                            first = false;
                        }
                    }
                }
                if (totalMax > 0)
                {
                    float teamPercent = float(totalCurrent) * 100.0 / float(totalMax);
                    if (g_bAmmoDebug)
                    LogToFileEx(g_sLogPath, "%s => %d/%d = %.1f%%", debugLine, totalCurrent, totalMax, teamPercent);
                    if (teamPercent <= g_fAmmoThreshold)
                    {
                        if (ammoInRange == 0)
                        {
                            bShouldSpawn = true;
                            // spawn near the player with the lowest ammo percentage
                            float bestPercent = 101.0;
                            for (int client = 1; client <= MaxClients; client++)
                            {
                                if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) continue;
                                float pct;
                                int mr;
                                if (PlayerNeedsAmmo(client, pct, mr) && pct < bestPercent)
                                {
                                    bestPercent = pct;
                                    spawnForClient = client;
                                }
                            }
                            if (g_bAmmoDebug)
                            LogToFileEx(g_sLogPath, "AmmoDebug: Team pool below threshold – spawning near player %d (lowest %.1f%%)", spawnForClient, bestPercent);
                        }
                        else
                        {
                            if (g_bAmmoDebug)
                            LogToFileEx(g_sLogPath, "AmmoDebug: Team pool below threshold, but %d ammo pile(s) already in range – skipping", ammoInRange);
                        }
                    }
                    else
                    {
                        if (g_bAmmoDebug)
                        LogToFileEx(g_sLogPath, "AmmoDebug: Team pool %.1f%% above threshold %.1f%% – no need", teamPercent, g_fAmmoThreshold);
                    }
                }
                else
                {
                    if (g_bAmmoDebug)
                    LogToFileEx(g_sLogPath, "AmmoDebug: Team pool calculation failed (no valid max reserves)");
                }
            }
        }

        if (bShouldSpawn && spawnForClient != 0)
        {
            float vClientOrigin[3];
            GetClientAbsOrigin(spawnForClient, vClientOrigin);
            int bestIdx = -1;
            float bestDist = 999999.0;
            for (int i = 0; i < g_iSpawnerCount; i++)
            {
                if (g_bUsedIndex[i] || g_bWeaponSpawned[i] || g_bMedkitSpawned[i] || g_bDefibSpawned[i] ||
                g_bTempHealthSpawned[i] || g_bThrowableSpawned[i] || g_bLaserSightSpawned[i] || g_bUpgradePackSpawned[i]) continue;
                if (g_bNearCabinet[i] && !g_bWeaponNearCabinet) continue;
                if (g_bNearSaferoom[i] && g_fSaferoomIgnoreRadius > 0.0) continue;
                if (g_bNearFinale[i] && g_fFinaleIgnoreRadius > 0.0) continue;

                // Visibility checks
                if (!g_bSpawnIfVisible)
                {
                    float vTarget[3];
                    vTarget = g_vSpawnerPos[i];
                    vTarget[2] += 30.0;
                    if (IsPositionVisibleToAnySurvivor(vTarget))
                    {
                        if (g_fFailCooldown > 0.0 && (fGameTime - g_fLastVisibilityFail[i] >= g_fFailCooldown))
                        g_fLastVisibilityFail[i] = fGameTime;
                        continue;
                    }
                    if (g_fFailCooldown > 0.0 && g_fLastVisibilityFail[i] > 0.0 && (fGameTime - g_fLastVisibilityFail[i] < g_fFailCooldown))
                    continue;
                }
                if (g_fBypassCooldown > 0.0 && g_fBypassTime[i] > 0.0 && (fGameTime - g_fBypassTime[i] < g_fBypassCooldown))
                continue;

                float dist = GetVectorDistance(vClientOrigin, g_vSpawnerPos[i]);
                if (dist >= g_fAmmoRadiusIgnore && dist <= g_fAmmoRadius)
                {
                    if (dist < bestDist) { bestDist = dist; bestIdx = i; }
                }
            }

            if (bestIdx != -1)
            {
                int ammo = SpawnAmmoAt(bestIdx);
                if (ammo != -1)
                {
                    g_bUsedIndex[bestIdx] = true;
                    if (g_bCleanupEnable)
                    {
                        g_aCleanupItems.Push(EntIndexToEntRef(ammo));
                        g_aCleanupTimers.Push(0.0);
                        g_aCleanupIndex.Push(bestIdx);
                        g_aCleanupType.Push(4);
                    }
                    if (g_bAmmoDebug)
                    LogToFileEx(g_sLogPath, "AmmoDebug: Spawned ammo at index %d (dist %.0f)", bestIdx, bestDist);
                }
            }
            else if (g_bAmmoDebug)
            LogToFileEx(g_sLogPath, "AmmoDebug: No valid spawn point for ammo near player %d", spawnForClient);
        }
    }

    // Temp Health Spawning
    if (g_bTempHealthSpawnEnable && g_fTempHealthRadius > 0.0)
    {
        int needCount = 0;
        bool bUncovered = false;
        float vSurvPos[3], vTemp[3];

        for (int client = 1; client <= MaxClients; client++)
        {
            if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) continue;

            // Carried temp‑health item (pills/adrenaline)
            int tempSlot = GetPlayerWeaponSlot(client, 4);
            bool bHasTempItem = (tempSlot != -1 && IsValidEntity(tempSlot));

            // Decayed buffer
            float buf = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
            float bufTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
            float currentBuffer = 0.0;
            if (buf > 0.0 && bufTime > 0.0)
            {
                currentBuffer = buf - g_fCvar_PillsDecay * (GetGameTime() - bufTime);
                if (currentBuffer < 0.0) currentBuffer = 0.0;
            }

            // Only consider buffer as real temp health if it came from an actual item use
            if (g_bHasItemTempHealth[client] && currentBuffer <= 0.0)
            g_bHasItemTempHealth[client] = false;

            bool bHasTempHealth = g_bHasItemTempHealth[client];

            if (g_bTempHealthSpawnDebug)
            LogToFileEx(g_sLogPath, "[TempDebug] Client %d: hasTempItem=%d, buf=%.2f, bufTime=%.2f, gameTime=%.2f",
            client, bHasTempItem, buf, bufTime, GetGameTime());

            if (!bHasTempItem && !bHasTempHealth)
            {
                needCount++;

                // Full ground scan: physical items + spawners
                bool bHasGroundItem = false;
                int ent = -1;

                // Physical pills
                while ((ent = FindEntityByClassname(ent, "weapon_pain_pills")) != -1)
                {
                    if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
                    GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                    GetClientAbsOrigin(client, vSurvPos);
                    if (GetVectorDistance(vSurvPos, vTemp) <= g_fTempHealthRadius)
                    {
                        bHasGroundItem = true;
                        break;
                    }
                }
                // Physical adrenaline
                if (!bHasGroundItem)
                {
                    ent = -1;
                    while ((ent = FindEntityByClassname(ent, "weapon_adrenaline")) != -1)
                    {
                        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
                        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                        GetClientAbsOrigin(client, vSurvPos);
                        if (GetVectorDistance(vSurvPos, vTemp) <= g_fTempHealthRadius)
                        {
                            bHasGroundItem = true;
                            break;
                        }
                    }
                }
                // Static spawners
                if (!bHasGroundItem)
                {
                    ent = -1;
                    while ((ent = FindEntityByClassname(ent, "weapon_pain_pills_spawn")) != -1)
                    {
                        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                        GetClientAbsOrigin(client, vSurvPos);
                        if (GetVectorDistance(vSurvPos, vTemp) <= g_fTempHealthRadius)
                        {
                            bHasGroundItem = true;
                            break;
                        }
                    }
                }
                // Static spawners (adrenaline)
                if (!bHasGroundItem)
                {
                    ent = -1;
                    while ((ent = FindEntityByClassname(ent, "weapon_adrenaline_spawn")) != -1)
                    {
                        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                        GetClientAbsOrigin(client, vSurvPos);
                        if (GetVectorDistance(vSurvPos, vTemp) <= g_fTempHealthRadius)
                        {
                            bHasGroundItem = true;
                            break;
                        }
                    }
                }
                // weapon_item_spawn with pain_pills or adrenaline
                if (!bHasGroundItem)
                {
                    ent = -1;
                    while ((ent = FindEntityByClassname(ent, "weapon_item_spawn")) != -1)
                    {
                        char sItem[32];
                        if (!GetItemSpawnerType(ent, sItem, sizeof(sItem))) continue;
                        if (StrEqual(sItem, "pain_pills", false) || StrEqual(sItem, "adrenaline", false))
                        {
                            GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                            GetClientAbsOrigin(client, vSurvPos);
                            if (GetVectorDistance(vSurvPos, vTemp) <= g_fTempHealthRadius)
                            {
                                bHasGroundItem = true;
                                break;
                            }
                        }
                    }
                }

                if (!bHasGroundItem)
                    bUncovered = true;
            }
        }

        if (g_bTempHealthSpawnDebug)
        LogToFileEx(g_sLogPath, "TempHealthSpawnDebug: Survivors without temp = %d, uncovered = %d", needCount, bUncovered);

        if (bUncovered)
        {
            float curFlow = GetLeadingSurvivorFlow();
            if (curFlow > 0.0)
            {
                if (g_fTempHealthSpawnNextFlow < 0.0 || g_bTempHealthSpawnPending)
                {
                    g_fTempHealthSpawnNextFlow = curFlow + GetRandomFloat(g_fTempHealthSpawnFlowMin, g_fTempHealthSpawnFlowMax);
                    if (g_bTempHealthSpawnDebug)
                    LogToFileEx(g_sLogPath, "TempHealthSpawnDebug: Need spawned – set next flow to %.0f (cur=%.0f)", g_fTempHealthSpawnNextFlow, curFlow);
                }

                if (curFlow >= g_fTempHealthSpawnNextFlow)
                {
                    if (g_bTempHealthSpawnDebug)
                    LogToFileEx(g_sLogPath, "TempHealthSpawnDebug: Flow target reached (cur=%.0f >= %.0f) – attempting spawn", curFlow, g_fTempHealthSpawnNextFlow);

                    int lead = GetLeadingSurvivorClient();
                    if (lead != 0)
                    {
                        float vLead[3];
                        GetClientAbsOrigin(lead, vLead);
                        int bestIdx = -1;
                        float bestDist = 999999.0;
                        for (int i = 0; i < g_iSpawnerCount; i++)
                        {
                            if (g_bUsedIndex[i] || g_bWeaponSpawned[i] || g_bMedkitSpawned[i] || g_bDefibSpawned[i] || g_bTempHealthSpawned[i] || g_bThrowableSpawned[i] || g_bLaserSightSpawned[i] || g_bUpgradePackSpawned[i]) continue;
                            if (g_bNearCabinet[i] && !g_bWeaponNearCabinet) continue;
                            if (g_bNearSaferoom[i] && g_fSaferoomIgnoreRadius > 0.0) continue;
                            if (g_bNearFinale[i] && g_fFinaleIgnoreRadius > 0.0) continue;

                            if (!g_bSpawnIfVisible)
                            {
                                float vTarget[3];
                                vTarget = g_vSpawnerPos[i];
                                vTarget[2] += 30.0;
                                if (IsPositionVisibleToAnySurvivor(vTarget))
                                {
                                    if (g_fFailCooldown > 0.0 && (fGameTime - g_fLastVisibilityFail[i] >= g_fFailCooldown))
                                    g_fLastVisibilityFail[i] = fGameTime;
                                    continue;
                                }
                                if (g_fFailCooldown > 0.0 && g_fLastVisibilityFail[i] > 0.0 && (fGameTime - g_fLastVisibilityFail[i] < g_fFailCooldown))
                                continue;
                            }
                            if (g_fBypassCooldown > 0.0 && g_fBypassTime[i] > 0.0 && (fGameTime - g_fBypassTime[i] < g_fBypassCooldown))
                            continue;

                            float dist = GetVectorDistance(vLead, g_vSpawnerPos[i]);
                            if (dist >= g_fTempHealthSpawnIgnoreRadius && dist <= g_fTempHealthRadius)
                            {
                                if (dist < bestDist) { bestDist = dist; bestIdx = i; }
                            }
                        }

                        if (bestIdx != -1)
                        {
                            int item = SpawnTempHealthAt(bestIdx);
                            if (item != -1)
                            {
                                g_bTempHealthSpawned[bestIdx] = true;
                                g_bUsedIndex[bestIdx] = true;
                                g_bTempHealthSpawnPending = false;
                                g_fTempHealthSpawnNextFlow = curFlow + GetRandomFloat(g_fTempHealthSpawnFlowMin, g_fTempHealthSpawnFlowMax);

                                if (g_bCleanupEnable)
                                {
                                    g_aCleanupItems.Push(EntIndexToEntRef(item));
                                    g_aCleanupTimers.Push(0.0);
                                    g_aCleanupIndex.Push(bestIdx);
                                    g_aCleanupType.Push(5);
                                }

                                CreateTimer(3.0, Timer_FreezeTempHealth, EntIndexToEntRef(item), TIMER_FLAG_NO_MAPCHANGE);

                                if (g_bTempHealthSpawnDebug)
                                LogToFileEx(g_sLogPath, "TempHealthSpawnDebug: Spawned temp health at index %d (dist %.0f), next flow = %.0f", bestIdx, bestDist, g_fTempHealthSpawnNextFlow);
                            }
                            else
                            {
                                g_bTempHealthSpawnPending = true;
                                if (g_bTempHealthSpawnDebug)
                                LogToFileEx(g_sLogPath, "TempHealthSpawnDebug: Spawn failed – no valid point, pending");
                            }
                        }
                        else
                        {
                            g_bTempHealthSpawnPending = true;
                            if (g_bTempHealthSpawnDebug)
                            LogToFileEx(g_sLogPath, "TempHealthSpawnDebug: No valid spawn point found – pending");
                        }
                    }
                }
            }
        }
        else
        {
            g_fTempHealthSpawnNextFlow = -1.0;
            g_bTempHealthSpawnPending = false;
        }
    }

    // Throwable Spawning
    if (g_bThrowableEnable && g_fThrowableRadius > 0.0)
    {
        int aliveCount = 0;
        int uncovered = 0;

        if (g_bThrowableCoverage)
        {
            float vSurvPos[3], vTemp[3];
            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) continue;
                aliveCount++;

                // Carried throwable (slot 2 = pipe/molotov/vomitjar)
                int throwSlot = GetPlayerWeaponSlot(client, 2);
                bool bHasThrowable = (throwSlot != -1 && IsValidEntity(throwSlot));

                // Ground throwables
                if (!bHasThrowable)
                {
                    int ent = -1;
                    while ((ent = FindEntityByClassname(ent, "weapon_pipe_bomb")) != -1)
                    {
                        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
                        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                        GetClientAbsOrigin(client, vSurvPos);
                        if (GetVectorDistance(vSurvPos, vTemp) <= g_fThrowableRadius) { bHasThrowable = true; break; }
                    }
                }
                if (!bHasThrowable)
                {
                    int ent = -1;
                    while ((ent = FindEntityByClassname(ent, "weapon_molotov")) != -1)
                    {
                        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
                        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                        GetClientAbsOrigin(client, vSurvPos);
                        if (GetVectorDistance(vSurvPos, vTemp) <= g_fThrowableRadius) { bHasThrowable = true; break; }
                    }
                }
                if (!bHasThrowable)
                {
                    int ent = -1;
                    while ((ent = FindEntityByClassname(ent, "weapon_vomitjar")) != -1)
                    {
                        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
                        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                        GetClientAbsOrigin(client, vSurvPos);
                        if (GetVectorDistance(vSurvPos, vTemp) <= g_fThrowableRadius) { bHasThrowable = true; break; }
                    }
                }

                // Non‑physical spawners: weapon_item_spawn with throwable items
                if (!bHasThrowable)
                {
                    int ent = -1;
                    while ((ent = FindEntityByClassname(ent, "weapon_item_spawn")) != -1)
                    {
                        char sItem[32];
                        if (!GetItemSpawnerType(ent, sItem, sizeof(sItem))) continue;
                        if (StrEqual(sItem, "pipe_bomb", false) || StrEqual(sItem, "molotov", false) || StrEqual(sItem, "vomitjar", false))
                        {
                            GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                            GetClientAbsOrigin(client, vSurvPos);
                            if (GetVectorDistance(vSurvPos, vTemp) <= g_fThrowableRadius) { bHasThrowable = true; break; }
                        }
                    }
                }

                // Dedicated non-physical throwable spawners
                if (!bHasThrowable)
                {
                    int ent = -1;
                    while ((ent = FindEntityByClassname(ent, "weapon_molotov_spawn")) != -1)
                    {
                        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                        GetClientAbsOrigin(client, vSurvPos);
                        if (GetVectorDistance(vSurvPos, vTemp) <= g_fThrowableRadius) { bHasThrowable = true; break; }
                    }
                }
                if (!bHasThrowable)
                {
                    int ent = -1;
                    while ((ent = FindEntityByClassname(ent, "weapon_pipe_bomb_spawn")) != -1)
                    {
                        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                        GetClientAbsOrigin(client, vSurvPos);
                        if (GetVectorDistance(vSurvPos, vTemp) <= g_fThrowableRadius) { bHasThrowable = true; break; }
                    }
                }
                if (!bHasThrowable)
                {
                    int ent = -1;
                    while ((ent = FindEntityByClassname(ent, "weapon_vomitjar_spawn")) != -1)
                    {
                        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
                        GetClientAbsOrigin(client, vSurvPos);
                        if (GetVectorDistance(vSurvPos, vTemp) <= g_fThrowableRadius) { bHasThrowable = true; break; }
                    }
                }

                if (!bHasThrowable)
                    uncovered++;
            }
        }
        else
        {
            for (int client = 1; client <= MaxClients; client++)
            if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
            aliveCount++;
            uncovered = 1;   // force a spawn attempt when the flow target is reached
            if (g_bThrowableDebug)
            LogToFileEx(g_sLogPath, "ThrowableDebug: Flow‑only mode, alive survivors = %d, uncovered forced", aliveCount);
        }

        if (g_bThrowableDebug && g_bThrowableCoverage)
        LogToFileEx(g_sLogPath, "ThrowableDebug: Alive survivors = %d, uncovered = %d", aliveCount, uncovered);

        if (uncovered > 0)
        {
            float curFlow = GetLeadingSurvivorFlow();
            if (curFlow > 0.0)
            {
                if (g_fThrowableNextFlow < 0.0 || g_bThrowablePending)
                {
                    g_fThrowableNextFlow = curFlow + GetRandomFloat(g_fThrowableFlowMin, g_fThrowableFlowMax);
                    if (g_bThrowableDebug)
                    LogToFileEx(g_sLogPath, "ThrowableDebug: Need spawned – set next flow to %.0f (cur=%.0f)", g_fThrowableNextFlow, curFlow);
                }

                if (curFlow >= g_fThrowableNextFlow)
                {
                    if (g_bThrowableDebug)
                    LogToFileEx(g_sLogPath, "ThrowableDebug: Flow target reached (cur=%.0f >= %.0f) – attempting spawn", curFlow, g_fThrowableNextFlow);

                    int lead = GetLeadingSurvivorClient();
                    if (lead != 0)
                    {
                        float vLead[3];
                        GetClientAbsOrigin(lead, vLead);
                        int bestIdx = -1;
                        float bestDist = 999999.0;
                        for (int i = 0; i < g_iSpawnerCount; i++)
                        {
                            if (g_bUsedIndex[i] || g_bWeaponSpawned[i] || g_bMedkitSpawned[i] || g_bDefibSpawned[i] || g_bTempHealthSpawned[i] || g_bThrowableSpawned[i] || g_bLaserSightSpawned[i] || g_bUpgradePackSpawned[i]) continue;
                            if (g_bNearCabinet[i] && !g_bWeaponNearCabinet) continue;
                            if (g_bNearSaferoom[i] && g_fSaferoomIgnoreRadius > 0.0) continue;
                            if (g_bNearFinale[i] && g_fFinaleIgnoreRadius > 0.0) continue;

                            if (!g_bSpawnIfVisible)
                            {
                                float vTarget[3];
                                vTarget = g_vSpawnerPos[i];
                                vTarget[2] += 30.0;
                                if (IsPositionVisibleToAnySurvivor(vTarget))
                                {
                                    if (g_fFailCooldown > 0.0 && (fGameTime - g_fLastVisibilityFail[i] >= g_fFailCooldown))
                                    g_fLastVisibilityFail[i] = fGameTime;
                                    continue;
                                }
                                if (g_fFailCooldown > 0.0 && g_fLastVisibilityFail[i] > 0.0 && (fGameTime - g_fLastVisibilityFail[i] < g_fFailCooldown))
                                    continue;
                            }
                            if (g_fBypassCooldown > 0.0 && g_fBypassTime[i] > 0.0 && (fGameTime - g_fBypassTime[i] < g_fBypassCooldown))
                                continue;

                            float dist = GetVectorDistance(vLead, g_vSpawnerPos[i]);
                            if (dist >= g_fThrowableRadiusIgnore && dist <= g_fThrowableRadius)
                            {
                                if (dist < bestDist) { bestDist = dist; bestIdx = i; }
                            }
                        }

                        if (bestIdx != -1)
                        {
                            int item = SpawnThrowableAt(bestIdx);
                            if (item != -1)
                            {
                                g_bThrowableSpawned[bestIdx] = true;
                                g_bUsedIndex[bestIdx] = true;
                                g_bThrowablePending = false;
                                g_fThrowableNextFlow = curFlow + GetRandomFloat(g_fThrowableFlowMin, g_fThrowableFlowMax);

                                if (g_bCleanupEnable)
                                {
                                    g_aCleanupItems.Push(EntIndexToEntRef(item));
                                    g_aCleanupTimers.Push(0.0);
                                    g_aCleanupIndex.Push(bestIdx);
                                    g_aCleanupType.Push(6);
                                }
                                if (g_bThrowableDebug)
                                LogToFileEx(g_sLogPath, "ThrowableDebug: Spawned throwable at index %d (dist %.0f), next flow = %.0f", bestIdx, bestDist, g_fThrowableNextFlow);
                            }
                            else
                            {
                                g_bThrowablePending = true;
                                if (g_bThrowableDebug)
                                LogToFileEx(g_sLogPath, "ThrowableDebug: Spawn failed – no valid point, pending");
                            }
                        }
                        else
                        {
                            g_bThrowablePending = true;
                            if (g_bThrowableDebug)
                            LogToFileEx(g_sLogPath, "ThrowableDebug: No valid spawn point found – pending");
                        }
                    }
                }
            }
        }
        else
        {
            g_fThrowableNextFlow = -1.0;
            g_bThrowablePending = false;
        }
    }

// Laser‑sight Spawning
if (g_bLaserSightEnable && g_fLaserSightRadius > 0.0)
{
    // Laser range
    bool bLaserCovered = false;
    float vSurvPos[3], vTemp[3];
    int ent = -1;

    while (!bLaserCovered && (ent = FindEntityByClassname(ent, "weapon_upgradepack_laser")) != -1)
    {
        if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
        GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
        for (int client = 1; client <= MaxClients; client++)
        {
            if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) continue;
            GetClientAbsOrigin(client, vSurvPos);
            if (GetVectorDistance(vSurvPos, vTemp) <= g_fLaserSightRadius) { bLaserCovered = true; break; }
        }
    }
    if (!bLaserCovered)
    {
        ent = -1;
        while ((ent = FindEntityByClassname(ent, "upgrade_laser_sight")) != -1)
        {
            GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) continue;
                GetClientAbsOrigin(client, vSurvPos);
                if (GetVectorDistance(vSurvPos, vTemp) <= g_fLaserSightRadius) { bLaserCovered = true; break; }
            }
            if (bLaserCovered) break;
        }
    }
    if (!bLaserCovered)
    {
        ent = -1;
        while ((ent = FindEntityByClassname(ent, "weapon_upgradepack_laser_spawn")) != -1)
        {
            GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vTemp);
            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) continue;
                GetClientAbsOrigin(client, vSurvPos);
                if (GetVectorDistance(vSurvPos, vTemp) <= g_fLaserSightRadius) { bLaserCovered = true; break; }
            }
            if (bLaserCovered) break;
        }
    }

    if (g_bLaserSightDebug)
        LogToFileEx(g_sLogPath, "LaserSightDebug: Covered = %d", bLaserCovered);

    if (bLaserCovered)
    {
        g_fLaserSightNextFlow = -1.0;
        g_bLaserSightPending = false;
        g_bBondingLaserPending = false;   
    }
    else
    {
        // Bonding laser spawn
        if (g_bBondingLaserPending)
        {
            int lead = GetLeadingSurvivorClient();
            if (lead != 0)
            {
                float vLead[3];
                GetClientAbsOrigin(lead, vLead);
                int bestIdx = -1;
                float bestDist = 999999.0;
                for (int i = 0; i < g_iSpawnerCount; i++)
                {
                    if (g_bUsedIndex[i] || g_bWeaponSpawned[i] || g_bMedkitSpawned[i] || g_bDefibSpawned[i] || g_bTempHealthSpawned[i] || g_bThrowableSpawned[i] || g_bLaserSightSpawned[i] || g_bUpgradePackSpawned[i]) continue;
                    if (g_bNearCabinet[i] && !g_bWeaponNearCabinet) continue;
                    if (g_bNearSaferoom[i] && g_fSaferoomIgnoreRadius > 0.0) continue;
                    if (g_bNearFinale[i] && g_fFinaleIgnoreRadius > 0.0) continue;

                    if (!g_bSpawnIfVisible)
                    {
                        float vTarget[3];
                        vTarget = g_vSpawnerPos[i];
                        vTarget[2] += 30.0;
                        if (IsPositionVisibleToAnySurvivor(vTarget))
                        {
                            if (g_fFailCooldown > 0.0 && (fGameTime - g_fLastVisibilityFail[i] >= g_fFailCooldown))
                            g_fLastVisibilityFail[i] = fGameTime;
                            continue;
                        }
                        if (g_fFailCooldown > 0.0 && g_fLastVisibilityFail[i] > 0.0 && (fGameTime - g_fLastVisibilityFail[i] < g_fFailCooldown))
                        continue;
                    }
                    // Bypass cooldown
                    if (g_fBypassCooldown > 0.0 && g_fBypassTime[i] > 0.0 && (fGameTime - g_fBypassTime[i] < g_fBypassCooldown))
                    continue;

                    float dist = GetVectorDistance(vLead, g_vSpawnerPos[i]);
                    if (dist >= g_fLaserSightRadiusIgnore && dist <= g_fLaserSightRadius)
                    {
                        if (dist < bestDist) { bestDist = dist; bestIdx = i; }
                    }
                }

                if (bestIdx != -1)
                {
                    int item = SpawnLaserSightAt(bestIdx);
                    if (item != -1)
                    {
                        g_bLaserSightSpawned[bestIdx] = true;
                        g_bUsedIndex[bestIdx] = true;
                        g_bBondingLaserPending = false;

                        for (int c = 1; c <= MaxClients; c++)
                            if (g_bPlayerBondingReady[c])
                            {
                                int character = GetEntProp(c, Prop_Send, "m_survivorCharacter");
                                if (character >= 0 && character <= 3)
                                g_bBondingLaserGiven[character] = true;
                            }

                        if (g_bCleanupEnable)
                        {
                            g_aCleanupItems.Push(EntIndexToEntRef(item));
                            g_aCleanupTimers.Push(0.0);
                            g_aCleanupIndex.Push(bestIdx);
                            g_aCleanupType.Push(7);
                        }
                        if (g_bLaserSightDebug)
                        LogToFileEx(g_sLogPath, "LaserSightDebug: Bonding laser spawned at index %d", bestIdx);
                    }
                }
            }
        }
        // Chance‑based / pending flow
        else if (g_bLaserSightChanceFlowRoll)
        {
            float curFlow = GetLeadingSurvivorFlow();

            // Pending retry
            if (g_bLaserSightPending)
            {
                if (g_bLaserSightDebug)
                LogToFileEx(g_sLogPath, "LaserSightDebug: Pending spawn active, trying immediate spawn...");

                int lead = GetLeadingSurvivorClient();
                if (lead != 0)
                {
                    float vLead[3];
                    GetClientAbsOrigin(lead, vLead);
                    int bestIdx = -1;
                    float bestDist = 999999.0;
                    for (int i = 0; i < g_iSpawnerCount; i++)
                    {
                        if (g_bUsedIndex[i] || g_bWeaponSpawned[i] || g_bMedkitSpawned[i] || g_bDefibSpawned[i] || g_bTempHealthSpawned[i] || g_bThrowableSpawned[i] || g_bLaserSightSpawned[i] || g_bUpgradePackSpawned[i]) continue;
                        if (g_bNearCabinet[i] && !g_bWeaponNearCabinet) continue;
                        if (g_bNearSaferoom[i] && g_fSaferoomIgnoreRadius > 0.0) continue;
                        if (g_bNearFinale[i] && g_fFinaleIgnoreRadius > 0.0) continue;

                        if (!g_bSpawnIfVisible)
                        {
                            float vTarget[3];
                            vTarget = g_vSpawnerPos[i];
                            vTarget[2] += 30.0;
                            if (IsPositionVisibleToAnySurvivor(vTarget))
                            {
                                if (g_fFailCooldown > 0.0 && (fGameTime - g_fLastVisibilityFail[i] >= g_fFailCooldown))
                                g_fLastVisibilityFail[i] = fGameTime;
                                continue;
                            }
                            if (g_fFailCooldown > 0.0 && g_fLastVisibilityFail[i] > 0.0 && (fGameTime - g_fLastVisibilityFail[i] < g_fFailCooldown))
                            continue;
                        }
                        // Bypass cooldown
                        if (g_fBypassCooldown > 0.0 && g_fBypassTime[i] > 0.0 && (fGameTime - g_fBypassTime[i] < g_fBypassCooldown))
                        continue;

                        float dist = GetVectorDistance(vLead, g_vSpawnerPos[i]);
                        if (dist >= g_fLaserSightRadiusIgnore && dist <= g_fLaserSightRadius)
                        {
                            if (dist < bestDist) { bestDist = dist; bestIdx = i; }
                        }
                    }

                    if (bestIdx != -1)
                    {
                        int item = SpawnLaserSightAt(bestIdx);
                        if (item != -1)
                        {
                            g_bLaserSightSpawned[bestIdx] = true;
                            g_bUsedIndex[bestIdx] = true;
                            g_bLaserSightPending = false;
                            g_fLaserSightNextFlow = -1.0;
                            if (g_bCleanupEnable)
                            {
                                g_aCleanupItems.Push(EntIndexToEntRef(item));
                                g_aCleanupTimers.Push(0.0);
                                g_aCleanupIndex.Push(bestIdx);
                                g_aCleanupType.Push(7);
                            }
                            if (g_bLaserSightDebug)
                            LogToFileEx(g_sLogPath, "LaserSightDebug: Pending spawn succeeded at index %d (dist %.0f)", bestIdx, bestDist);
                        }
                        else
                        {
                            if (g_bLaserSightDebug)
                            LogToFileEx(g_sLogPath, "LaserSightDebug: Pending spawn failed – will retry next cycle");
                        }
                    }
                    else
                    {
                        if (g_bLaserSightDebug)
                        LogToFileEx(g_sLogPath, "LaserSightDebug: No valid spawn point while pending – retrying");
                    }
                }
            }
            else
            {
                // Flow‑based spawning
                if (curFlow > 0.0)
                {
                    if (g_fLaserSightNextFlow < 0.0)
                    {
                        float mapMax = L4D2Direct_GetMapMaxFlowDistance();
                        if (mapMax > curFlow)
                        {
                            g_fLaserSightNextFlow = curFlow + GetRandomFloat(0.0, mapMax - curFlow);
                            if (g_bLaserSightDebug)
                            LogToFileEx(g_sLogPath, "LaserSightDebug: New flow target = %.0f (cur=%.0f, mapMax=%.0f)", g_fLaserSightNextFlow, curFlow, mapMax);
                        }
                    }

                    if (g_fLaserSightNextFlow > 0.0 && curFlow >= g_fLaserSightNextFlow)
                    {
                        if (g_bLaserSightDebug)
                        LogToFileEx(g_sLogPath, "LaserSightDebug: Flow target reached (cur=%.0f >= %.0f) – rolling chance", curFlow, g_fLaserSightNextFlow);

                        if (GetRandomInt(0, 100) <= g_iLaserSightChance)
                        {
                            if (g_bLaserSightDebug)
                            LogToFileEx(g_sLogPath, "LaserSightDebug: Chance succeeded, attempting spawn");

                            int lead = GetLeadingSurvivorClient();
                            if (lead != 0)
                            {
                                float vLead[3];
                                GetClientAbsOrigin(lead, vLead);
                                int bestIdx = -1;
                                float bestDist = 999999.0;
                                for (int i = 0; i < g_iSpawnerCount; i++)
                                {
                                    if (g_bUsedIndex[i] || g_bWeaponSpawned[i] || g_bMedkitSpawned[i] || g_bDefibSpawned[i] || g_bTempHealthSpawned[i] || g_bThrowableSpawned[i] || g_bLaserSightSpawned[i] || g_bUpgradePackSpawned[i]) continue;
                                    if (g_bNearCabinet[i] && !g_bWeaponNearCabinet) continue;
                                    if (g_bNearSaferoom[i] && g_fSaferoomIgnoreRadius > 0.0) continue;
                                    if (g_bNearFinale[i] && g_fFinaleIgnoreRadius > 0.0) continue;

                                    if (!g_bSpawnIfVisible)
                                    {
                                        float vTarget[3];
                                        vTarget = g_vSpawnerPos[i];
                                        vTarget[2] += 30.0;
                                        if (IsPositionVisibleToAnySurvivor(vTarget))
                                        {
                                            if (g_fFailCooldown > 0.0 && (fGameTime - g_fLastVisibilityFail[i] >= g_fFailCooldown))
                                            g_fLastVisibilityFail[i] = fGameTime;
                                            continue;
                                        }
                                        if (g_fFailCooldown > 0.0 && g_fLastVisibilityFail[i] > 0.0 && (fGameTime - g_fLastVisibilityFail[i] < g_fFailCooldown))
                                        continue;
                                    }
                                    // Bypass cooldown
                                    if (g_fBypassCooldown > 0.0 && g_fBypassTime[i] > 0.0 && (fGameTime - g_fBypassTime[i] < g_fBypassCooldown))
                                    continue;

                                    float dist = GetVectorDistance(vLead, g_vSpawnerPos[i]);
                                    if (dist >= g_fLaserSightRadiusIgnore && dist <= g_fLaserSightRadius)
                                    {
                                        if (dist < bestDist) { bestDist = dist; bestIdx = i; }
                                    }
                                }

                                if (bestIdx != -1)
                                {
                                    int item = SpawnLaserSightAt(bestIdx);
                                    if (item != -1)
                                    {
                                        g_bLaserSightSpawned[bestIdx] = true;
                                        g_bUsedIndex[bestIdx] = true;
                                        g_bLaserSightPending = false;
                                        g_fLaserSightNextFlow = -1.0;
                                        if (g_bCleanupEnable)
                                        {
                                            g_aCleanupItems.Push(EntIndexToEntRef(item));
                                            g_aCleanupTimers.Push(0.0);
                                            g_aCleanupIndex.Push(bestIdx);
                                            g_aCleanupType.Push(7);
                                        }
                                        if (g_bLaserSightDebug)
                                        LogToFileEx(g_sLogPath, "LaserSightDebug: Spawned laser sight at index %d (dist %.0f)", bestIdx, bestDist);
                                    }
                                    else
                                    {
                                        g_bLaserSightPending = true;
                                        if (g_bLaserSightDebug)
                                        LogToFileEx(g_sLogPath, "LaserSightDebug: Spawn failed – setting pending for immediate retry");
                                    }
                                }
                                else
                                {
                                    g_bLaserSightPending = true;
                                    if (g_bLaserSightDebug)
                                    LogToFileEx(g_sLogPath, "LaserSightDebug: No valid spawn point found – setting pending");
                                }
                            }
                        }
                        else
                        {
                            g_fLaserSightNextFlow = -1.0;
                            if (g_bLaserSightDebug)
                            LogToFileEx(g_sLogPath, "LaserSightDebug: Chance failed, will pick new target next cycle");
                        }
                    }
                }
            }
        }
    }
}

// Upgrade Pack Spawning
if (g_bUpgradePackEnable)
{
    float curFlow = GetLeadingSurvivorFlow();

    // Pending retry from a previous failed spawn
    if (g_bUpgradePackPending)
    {
        if (g_bUpgradePackDebug)
            LogToFileEx(g_sLogPath, "UpgradePackDebug: Pending spawn active, trying immediate spawn...");

        int lead = GetLeadingSurvivorClient();
        if (lead != 0)
        {
            float vLead[3];
            GetClientAbsOrigin(lead, vLead);
            int bestIdx = -1;
            float bestDist = 999999.0;
            for (int i = 0; i < g_iSpawnerCount; i++)
            {
                if (g_bUsedIndex[i] || g_bWeaponSpawned[i] || g_bMedkitSpawned[i] || g_bDefibSpawned[i] || g_bTempHealthSpawned[i] || g_bThrowableSpawned[i] || g_bLaserSightSpawned[i] || g_bUpgradePackSpawned[i]) continue;
                if (g_bNearCabinet[i] && !g_bWeaponNearCabinet) continue;   // you can add a separate upgrade cabinet cvar if needed; reuse weaponNearCabinet for now
                if (g_bNearSaferoom[i] && g_fSaferoomIgnoreRadius > 0.0) continue;
                if (g_bNearFinale[i] && g_fFinaleIgnoreRadius > 0.0) continue;

                if (!g_bSpawnIfVisible)
                {
                    float vTarget[3];
                    vTarget = g_vSpawnerPos[i];
                    vTarget[2] += 30.0;
                    if (IsPositionVisibleToAnySurvivor(vTarget))
                    {
                        if (g_fFailCooldown > 0.0 && (fGameTime - g_fLastVisibilityFail[i] >= g_fFailCooldown))
                            g_fLastVisibilityFail[i] = fGameTime;
                        continue;
                    }
                    if (g_fFailCooldown > 0.0 && g_fLastVisibilityFail[i] > 0.0 && (fGameTime - g_fLastVisibilityFail[i] < g_fFailCooldown))
                        continue;
                }
                if (g_fBypassCooldown > 0.0 && g_fBypassTime[i] > 0.0 && (fGameTime - g_fBypassTime[i] < g_fBypassCooldown))
                    continue;

                float dist = GetVectorDistance(vLead, g_vSpawnerPos[i]);
if (dist >= g_fUpgradePackRadiusIgnore && (g_fUpgradePackRadius <= 0.0 || dist <= g_fUpgradePackRadius))
{
    if (dist < bestDist) { bestDist = dist; bestIdx = i; }
}
            }

            if (bestIdx != -1)
            {
                int item = SpawnUpgradePackAt(bestIdx);
                if (item != -1)
                {
                    g_bUpgradePackSpawned[bestIdx] = true;
                    g_bUsedIndex[bestIdx] = true;
                    g_bUpgradePackPending = false;
                    g_fUpgradePackNextFlow = -1.0;
                    if (g_bCleanupEnable)
                    {
                        g_aCleanupItems.Push(EntIndexToEntRef(item));
                        g_aCleanupTimers.Push(0.0);
                        g_aCleanupIndex.Push(bestIdx);
                        g_aCleanupType.Push(8); 
                    }
                    if (g_bUpgradePackDebug)
                        LogToFileEx(g_sLogPath, "UpgradePackDebug: Pending spawn succeeded at index %d (dist %.0f)", bestIdx, bestDist);
                }
                else if (g_bUpgradePackDebug)
                    LogToFileEx(g_sLogPath, "UpgradePackDebug: Pending spawn failed – will retry");
            }
            else if (g_bUpgradePackDebug)
                LogToFileEx(g_sLogPath, "UpgradePackDebug: No valid spawn point while pending");
        }
    }
    else   // Normal flow‑based spawning
    {
        if (curFlow > 0.0)
        {
            if (g_fUpgradePackNextFlow < 0.0)
            {
                float mapMax = L4D2Direct_GetMapMaxFlowDistance();
                if (mapMax > curFlow)
                {
                    g_fUpgradePackNextFlow = curFlow + GetRandomFloat(0.0, mapMax - curFlow);
                    if (g_bUpgradePackDebug)
                        LogToFileEx(g_sLogPath, "UpgradePackDebug: New flow target = %.0f (cur=%.0f, mapMax=%.0f)", g_fUpgradePackNextFlow, curFlow, mapMax);
                }
            }

            if (g_fUpgradePackNextFlow > 0.0 && curFlow >= g_fUpgradePackNextFlow)
            {
                if (g_bUpgradePackDebug)
                    LogToFileEx(g_sLogPath, "UpgradePackDebug: Flow target reached (cur=%.0f >= %.0f) – rolling chance", curFlow, g_fUpgradePackNextFlow);

                if (GetRandomInt(0, 100) <= g_iUpgradePackChance)
                {
                    if (g_bUpgradePackDebug)
                        LogToFileEx(g_sLogPath, "UpgradePackDebug: Chance succeeded, attempting spawn");

                    int lead = GetLeadingSurvivorClient();
                    if (lead != 0)
                    {
                        float vLead[3];
                        GetClientAbsOrigin(lead, vLead);
                        int bestIdx = -1;
                        float bestDist = 999999.0;
                        for (int i = 0; i < g_iSpawnerCount; i++)
                        {
                            if (g_bUsedIndex[i] || g_bWeaponSpawned[i] || g_bMedkitSpawned[i] || g_bDefibSpawned[i] || g_bTempHealthSpawned[i] || g_bThrowableSpawned[i] || g_bLaserSightSpawned[i] || g_bUpgradePackSpawned[i]) continue;
                            if (g_bNearCabinet[i] && !g_bWeaponNearCabinet) continue;
                            if (g_bNearSaferoom[i] && g_fSaferoomIgnoreRadius > 0.0) continue;
                            if (g_bNearFinale[i] && g_fFinaleIgnoreRadius > 0.0) continue;

                            if (!g_bSpawnIfVisible)
                            {
                                float vTarget[3];
                                vTarget = g_vSpawnerPos[i];
                                vTarget[2] += 30.0;
                                if (IsPositionVisibleToAnySurvivor(vTarget))
                                {
                                    if (g_fFailCooldown > 0.0 && (fGameTime - g_fLastVisibilityFail[i] >= g_fFailCooldown))
                                        g_fLastVisibilityFail[i] = fGameTime;
                                    continue;
                                }
                                if (g_fFailCooldown > 0.0 && g_fLastVisibilityFail[i] > 0.0 && (fGameTime - g_fLastVisibilityFail[i] < g_fFailCooldown))
                                    continue;
                            }
                            if (g_fBypassCooldown > 0.0 && g_fBypassTime[i] > 0.0 && (fGameTime - g_fBypassTime[i] < g_fBypassCooldown))
                                continue;

                            float dist = GetVectorDistance(vLead, g_vSpawnerPos[i]);
                            if (dist >= g_fUpgradePackRadiusIgnore && (g_fUpgradePackRadius <= 0.0 || dist <= g_fUpgradePackRadius))
                            {
                                if (dist < bestDist) { bestDist = dist; bestIdx = i; }
                            }
                        }

                        if (bestIdx != -1)
                        {
                            int item = SpawnUpgradePackAt(bestIdx);
                            if (item != -1)
                            {
                                g_bUpgradePackSpawned[bestIdx] = true;
                                g_bUsedIndex[bestIdx] = true;
                                g_bUpgradePackPending = false;
                                g_fUpgradePackNextFlow = -1.0;
                                if (g_bCleanupEnable)
                                {
                                    g_aCleanupItems.Push(EntIndexToEntRef(item));
                                    g_aCleanupTimers.Push(0.0);
                                    g_aCleanupIndex.Push(bestIdx);
                                    g_aCleanupType.Push(8);
                                }
                                if (g_bUpgradePackDebug)
                                    LogToFileEx(g_sLogPath, "UpgradePackDebug: Spawned upgrade pack at index %d (dist %.0f)", bestIdx, bestDist);
                            }
                            else
                            {
                                g_bUpgradePackPending = true;
                                if (g_bUpgradePackDebug)
                                    LogToFileEx(g_sLogPath, "UpgradePackDebug: Spawn failed – setting pending for immediate retry");
                            }
                        }
                        else
                        {
                            g_bUpgradePackPending = true;
                            if (g_bUpgradePackDebug)
                                LogToFileEx(g_sLogPath, "UpgradePackDebug: No valid spawn point found – setting pending");
                        }
                    }
                }
                else
                {
                    g_fUpgradePackNextFlow = -1.0;
                    if (g_bUpgradePackDebug)
                        LogToFileEx(g_sLogPath, "UpgradePackDebug: Chance failed, will pick new target next cycle");
                }
            }
        }
    }
}

    // Medkit visibility fail cooldown
    if (g_bMedkitEnable && !g_bSpawnIfVisible && g_fFailCooldown > 0.0)
    {
        float vMedTarget[3];
        for (int i = 0; i < g_iSpawnerCount; i++)
        {
            if (g_bMedkitSpawned[i] || g_bWeaponSpawned[i] || g_bDefibSpawned[i])
            continue;
            if (g_fLastVisibilityFail[i] > 0.0 && (fGameTime - g_fLastVisibilityFail[i] < g_fFailCooldown))
            continue;

            vMedTarget = g_vSpawnerPos[i];
            vMedTarget[2] += 30.0;
            if (IsPositionVisibleToAnySurvivor(vMedTarget))
            {
                g_fLastVisibilityFail[i] = fGameTime;
                LogDebug("Medkit spawn point %d is now visible – fail cooldown set", i);
            }
        }
    }

    return Plugin_Continue;
}

// HUD and medkit functions
Action Timer_UpdateHud(Handle timer)
{
    if (!g_bEnabled || !g_bConditionHud || !g_bConditionEnable || !g_bMedkitEnable)
        return Plugin_Continue;

    char line[128];
    float curFlow = GetLeadingSurvivorFlow();

    if (g_bPendingMedkitSpawn)
    {
        Format(line, sizeof(line), "Condition: %d | Spawn pending...", g_iCondition);
    }
    else if (g_fNextSpawnFlow > 0.0)
    {
        Format(line, sizeof(line), "Condition: %d | Flow: %.0f / %.0f", g_iCondition, curFlow, g_fNextSpawnFlow);
    }
    else
    {
        Format(line, sizeof(line), "Condition: %d | Flow: %.0f (no target)", g_iCondition, curFlow);
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && (GetUserFlagBits(i) & ADMFLAG_ROOT))
            PrintHintText(i, "%s", line);
    }
    return Plugin_Continue;
}

Action Timer_UpdateBondingHud(Handle timer)
{
    if (!g_bEnabled || !g_bBondingEnable || !g_bBondingHud || !g_bLeftSafeArea)
        return Plugin_Continue;

    char line[128];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && (GetUserFlagBits(i) & ADMFLAG_ROOT))
        {
            int weapon = GetPlayerWeaponSlot(i, 0);
            int character = GetEntProp(i, Prop_Send, "m_survivorCharacter");
            float bonding = 0.0;
            if (weapon != -1 && IsValidEntity(weapon) && character >= 0 && character <= 3)
                bonding = g_fWeaponBondingChar[character][weapon];

            float threshold = g_fBondingThreshold;
            if (bonding >= threshold)
            {
                if (g_bBondingLaserPending)
                    Format(line, sizeof(line), "Weapon Bonding: %.2f/%.2f | Laser incoming...", bonding, threshold);
                else
                    Format(line, sizeof(line), "Weapon Bonding: %.2f/%.2f | Ready", bonding, threshold);
            }
            else
                Format(line, sizeof(line), "Weapon Bonding: %.2f/%.2f", bonding, threshold);

            PrintHintText(i, "%s", line);
        }
    }
    return Plugin_Continue;
}

bool SpawnMedkitAtClosestValid()
{
    LogDebug("SpawnMedkitAtClosestValid: g_iSpawnerCount=%d", g_iSpawnerCount);
    if (g_iSpawnerCount == 0) { CacheAllSpawners(); }
    int leadClient = GetLeadingSurvivorClient();
    if (leadClient == 0)
    {
        for (int c = 1; c <= MaxClients; c++)
        {
            if (IsClientInGame(c) && GetClientTeam(c) == 2 && IsPlayerAlive(c))
            {
                leadClient = c;
                break;
            }
        }
        if (leadClient == 0)
        {
            LogDebug("SpawnMedkitAtClosestValid: no alive survivor");
            return false;
        }
        LogDebug("SpawnMedkitAtClosestValid: using fallback survivor %d", leadClient);
    }

    float vLead[3];
    GetClientAbsOrigin(leadClient, vLead);
    float gameTime = GetGameTime();

    int bestIdx = -1;
    float bestDist = 999999.0;

    for (int i = 0; i < g_iSpawnerCount; i++)
    {
        if (g_bUsedIndex[i] || g_bMedkitSpawned[i] || g_bWeaponSpawned[i] || g_bDefibSpawned[i] || g_bTempHealthSpawned[i] || g_bThrowableSpawned[i] || g_bLaserSightSpawned[i] || g_bUpgradePackSpawned[i]) continue;
        if (g_bNearCabinet[i] && !g_bMedkitNearCabinet)
        continue;
        if (g_bNearSaferoom[i] && g_fSaferoomIgnoreRadius > 0.0)
        continue;
        if (g_bNearFinale[i] && g_fFinaleIgnoreRadius > 0.0)
        continue;

        if (!g_bSpawnIfVisible)
        {
            float vTarget[3];
            vTarget = g_vSpawnerPos[i];
            vTarget[2] += 30.0;
            if (IsPositionVisibleToAnySurvivor(vTarget))
            {
                if (g_fFailCooldown > 0.0)
                {
                    if (gameTime - g_fLastVisibilityFail[i] >= g_fFailCooldown)
                    g_fLastVisibilityFail[i] = gameTime;
                }
                continue;
            }
            if (g_fFailCooldown > 0.0 && g_fLastVisibilityFail[i] > 0.0)
            {
                if (gameTime - g_fLastVisibilityFail[i] < g_fFailCooldown)
                continue;
            }
        }

        if (g_fBypassCooldown > 0.0 && g_fBypassTime[i] > 0.0)
        {
            if (gameTime - g_fBypassTime[i] < g_fBypassCooldown)
            continue;
        }

        float dist = GetVectorDistance(vLead, g_vSpawnerPos[i]);
        if (dist >= g_fMedkitRadiusIgnore && dist <= g_fMedkitRadius)
        {
            if (dist < bestDist) { bestDist = dist; bestIdx = i; }
        }
    }

    if (bestIdx != -1)
    {
        int ent = SpawnMedkitAt(bestIdx);
        if (ent != -1)
        {
            g_bMedkitSpawned[bestIdx] = true;
            g_bUsedIndex[bestIdx] = true;

            if (g_bReplaceItem) RemoveItemsAtPosition(g_vSpawnerPos[bestIdx], ent);
            if (g_bCleanupEnable)
            {
                g_aCleanupItems.Push(EntIndexToEntRef(ent));
                g_aCleanupTimers.Push(0.0);
                g_aCleanupIndex.Push(bestIdx);
                g_aCleanupType.Push(1);
            }
            LogDebug("Medkit spawned at index %d (dist %.0f)", bestIdx, bestDist);
            return true;
        }
        else
        {
            LogDebug("Failed to create medkit entity at index %d", bestIdx);
        }
    }
    else
    {
        LogDebug("No valid spawn point: ring [%.0f, %.0f], cabinets: %s, bypass: %.0f sec, visibility checks active",
        g_fMedkitRadiusIgnore, g_fMedkitRadius,
        g_bMedkitNearCabinet ? "allowed" : "blocked",
        g_fBypassCooldown);
    }
    return false;
}

int SpawnMedkitAt(int index)
{
    int medkit = CreateEntityByName("weapon_first_aid_kit");
    if (medkit == -1) return -1;
    float vOrigin[3];
    vOrigin = g_vSpawnerPos[index];
    vOrigin[2] += 5.0;
    TeleportEntity(medkit, vOrigin, g_vSpawnerAng[index], NULL_VECTOR);
    DispatchSpawn(medkit);
    return medkit;
}

public Action Timer_FreezeTempHealth(Handle timer, int ref)
{
    int item = EntRefToEntIndex(ref);
    if (item == INVALID_ENT_REFERENCE || !IsValidEntity(item))
    return Plugin_Stop;

    if (GetEntPropEnt(item, Prop_Send, "m_hOwnerEntity") != -1)
    return Plugin_Stop;

    SetEntityMoveType(item, MOVETYPE_NONE);
    float zeroVec[3];
    TeleportEntity(item, NULL_VECTOR, NULL_VECTOR, zeroVec);
    return Plugin_Stop;
}

public Action Timer_BondingTick(Handle timer)
{
    if (!g_bEnabled || !g_bBondingEnable || !g_bLeftSafeArea)
    return Plugin_Continue;

    int alive = 0, ready = 0;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
        continue;

        int weapon = GetPlayerWeaponSlot(client, 0);
        if (weapon == -1 || !IsValidEntity(weapon))
        {
            g_bPlayerBondingReady[client] = false;
            alive++;
            if (g_bBondingDebug)
            LogToFileEx(g_sLogPath, "[Bonding] Client %d: no primary weapon", client);
            continue;
        }

        int character = GetEntProp(client, Prop_Send, "m_survivorCharacter");
        if (character < 0 || character > 3) continue;
        bool bNearLaser = false;
        float vSurv[3], vLaser[3];
        GetClientAbsOrigin(client, vSurv);
        int ent = -1;

        // Standard laser boxes
        while (!bNearLaser && (ent = FindEntityByClassname(ent, "weapon_upgradepack_laser")) != -1)
        {
            if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1) continue;
            GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vLaser);
            if (GetVectorDistance(vSurv, vLaser) <= g_fLaserSightRadius)
            bNearLaser = true;
        }
        // Plugin‑spawned laser boxes
        if (!bNearLaser)
        {
            ent = -1;
            while ((ent = FindEntityByClassname(ent, "upgrade_laser_sight")) != -1)
            {
                GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vLaser);
                if (GetVectorDistance(vSurv, vLaser) <= g_fLaserSightRadius)
                {
                    bNearLaser = true;
                    break;
                }
            }
        }
        // Laser‑sight spawners
        if (!bNearLaser)
        {
            ent = -1;
            while ((ent = FindEntityByClassname(ent, "weapon_upgradepack_laser_spawn")) != -1)
            {
                GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vLaser);
                if (GetVectorDistance(vSurv, vLaser) <= g_fLaserSightRadius)
                {
                    bNearLaser = true;
                    break;
                }
            }
        }
        if (bNearLaser)
        {
            g_bCharNearLaser[character] = true;
        }
        else if (g_bCharNearLaser[character])
        {
            g_bCharNearLaser[character] = false;

            int bitVec = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
            if (!(bitVec & 4))
            {
                g_fBondingMissCooldownUntil[character] = GetGameTime() + g_fBondingMissCooldown;
                g_bMissCooldownSetThisMap[character] = true;
                if (g_bBondingDebug)
                LogToFileEx(g_sLogPath, "[Bonding] Miss cooldown set for character %d (until %.0f)",
                character, g_fBondingMissCooldownUntil[character]);
            }
        }

        // Weapon‑switch tracking
        if (g_iLastPrimaryWeapon[client] != weapon)
        {
            // If decay is enabled and the old weapon is valid, record its drop time
            if (g_bBondingDecayEnable && g_iLastPrimaryWeapon[client] != -1)
            {
                int oldWeapon = g_iLastPrimaryWeapon[client];
                if (IsValidEntity(oldWeapon))
                {
                    g_fWeaponLastDropTime[character][oldWeapon] = GetGameTime();

                    if (g_bBondingDebug)
                    LogToFileEx(g_sLogPath, "[Bonding] Decay start (switch): char %d oldWeapon %d",
                    character, oldWeapon);
                }
            }

            g_iLastPrimaryWeapon[client] = weapon;
            g_bBondingLaserGiven[character] = false;
        }

        // Pending carryover
        if (g_bPendingCarryover[character])
        {
            char currentWeaponClass[64];
            GetEdictClassname(weapon, currentWeaponClass, sizeof(currentWeaponClass));

            if (strcmp(currentWeaponClass, g_sCarryoverWeaponClass[character]) == 0)
            {
                // Same weapon type – transfer the bonding value
                g_fWeaponBondingChar[character][weapon] = g_fCarryoverBonding[character];
                g_sWeaponEntityClass[weapon] = currentWeaponClass;

                if (g_bBondingDebug)
                LogToFileEx(g_sLogPath, "[Bonding] Carryover applied – same weapon %s for char %d (value %.2f)",
                currentWeaponClass, character, g_fCarryoverBonding[character]);
            }
            else
            {
                // Weapon changed – discard the old bonding
                g_fWeaponBondingChar[character][weapon] = 0.0;
                g_fCarryoverBonding[character] = 0.0;
                g_sCarryoverWeaponClass[character][0] = '\0';
                g_sWeaponEntityClass[weapon][0] = '\0';

                if (g_bBondingDebug)
                LogToFileEx(g_sLogPath, "[Bonding] Carryover discarded – weapon changed from %s to %s (char %d)",
                g_sCarryoverWeaponClass[character], currentWeaponClass, character);
            }

            g_bPendingCarryover[character] = false;
        }

        // Get current class for verification
        char szClass[64];
        GetEdictClassname(weapon, szClass, sizeof(szClass));

        // Prevent bonding from carrying over to a different weapon class
        if (g_fWeaponBondingChar[character][weapon] > 0.0)
        {
            if (g_sWeaponEntityClass[weapon][0] == '\0')
            {
                strcopy(g_sWeaponEntityClass[weapon], sizeof(g_sWeaponEntityClass[]), szClass);
            }
            else if (strcmp(g_sWeaponEntityClass[weapon], szClass) != 0)
            {
                // Entity index reused for a different weapon – reset bonding
                g_fWeaponBondingChar[character][weapon] = 0.0;
                g_fCarryoverBonding[character] = 0.0;
                g_fWeaponLastDropTime[character][weapon] = 0.0;
                g_sWeaponEntityClass[weapon][0] = '\0';

                if (g_bBondingDebug)
                LogToFileEx(g_sLogPath, "[Bonding] Reset bonding for char %d weapon %d – class changed to %s",
                character, weapon, szClass);
            }
        }

        // Apply bonding decay if character re‑picks up a weapon they dropped earlier
        if (g_bBondingDecayEnable && g_fWeaponLastDropTime[character][weapon] > 0.0)
        {
            float timeAway = GetGameTime() - g_fWeaponLastDropTime[character][weapon];
            float decay = timeAway * g_fBondingDecayPerSecond;
            float currentBonding = g_fWeaponBondingChar[character][weapon];
            currentBonding -= decay;
            if (currentBonding < g_fBondingDecayThreshold)
            currentBonding = g_fBondingDecayThreshold;

            g_fWeaponBondingChar[character][weapon] = currentBonding;
            g_fCarryoverBonding[character] = currentBonding;
            g_fWeaponLastDropTime[character][weapon] = 0.0;
            g_sWeaponEntityClass[weapon] = szClass;   // store class

            if (g_bBondingDebug)
            LogToFileEx(g_sLogPath, "[Bonding] Decay applied: char %d weapon %d, away %.1f sec, new bonding=%.3f",
            character, weapon, timeAway, currentBonding);
        }

        // Bonding increase
        float bonding = g_fWeaponBondingChar[character][weapon] + g_fBondingIncrementPerSecond;
        if (bonding > g_fBondingThreshold) bonding = g_fBondingThreshold;
        g_fWeaponBondingChar[character][weapon] = bonding;
        g_fCarryoverBonding[character] = bonding;
        g_sWeaponEntityClass[weapon] = szClass;   // store class

        // Remember the weapon class for carryover validation on next map
        GetEdictClassname(weapon, g_sCarryoverWeaponClass[character], sizeof(g_sCarryoverWeaponClass[]));

        int bitVec = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
        if (g_bBondingDebug)
        {
            char wname[64];
            GetEdictClassname(weapon, wname, sizeof(wname));
            LogToFileEx(g_sLogPath, "[Bonding] Client %d (char %d) weapon=%d (%s) bonding=%.3f bitVec=%d laser=%d near=%d",
            client, character, weapon, wname, bonding, bitVec, (bitVec & 4) ? 1 : 0, bNearLaser);
        }

        // Determine "ready" status
        bool bSkipDueToMissCooldown = (GetGameTime() < g_fBondingMissCooldownUntil[character]);

        if (bSkipDueToMissCooldown)
        {
            g_bPlayerBondingReady[client] = false;
            if (g_bBondingDebug)
            LogToFileEx(g_sLogPath, "[Bonding] Client %d (char %d) blocked by miss cooldown (%.0f sec left)",
            client, character, g_fBondingMissCooldownUntil[character] - GetGameTime());
        }
        else if (g_bBondingLaserGiven[character])
        {
            if (bitVec & 4)
            {
                g_bPlayerBondingReady[client] = false;
            }
            else
            {
                g_bBondingLaserGiven[character] = false;
                if (bonding >= g_fBondingThreshold && !(bitVec & 4))
                {
                    g_bPlayerBondingReady[client] = true;
                    ready++;
                }
                else
                {
                    g_bPlayerBondingReady[client] = false;
                }
            }
        }
        else if (bonding >= g_fBondingThreshold)
        {
            if (!(bitVec & 4))
            {
                g_bPlayerBondingReady[client] = true;
                ready++;
            }
            else
                g_bPlayerBondingReady[client] = false;
        }
        else
            g_bPlayerBondingReady[client] = false;

        alive++;
    }

    // Bonding threshold
    if (alive > 0 && float(ready) / alive >= g_fBondingFraction)
    {
        // Laser‑proximity check
        bool bAnyLaserNear = false;
        for (int i = 0; i < 4; i++)
        {
            if (g_bCharNearLaser[i])
            {
                bAnyLaserNear = true;
                break;
            }
        }

        if (g_bBondingDebug)
        LogToFileEx(g_sLogPath, "[Bonding] Laser nearby check: %d", bAnyLaserNear);

        if (!bAnyLaserNear)
        {
            if (!g_bBondingLaserPending)
            {
                g_bBondingLaserPending = true;
                if (g_bBondingDebug)
                    LogToFileEx(g_sLogPath, "[Bonding] Laser spawn pending (ready=%d/%d)", ready, alive);
            }
        }
        else
        {
            if (g_bBondingLaserPending && g_bBondingDebug)
            LogToFileEx(g_sLogPath, "[Bonding] Laser already nearby – clearing pending");
            g_bBondingLaserPending = false;
        }
    }
    else
    {
        if (g_bBondingLaserPending && g_bBondingDebug)
        LogToFileEx(g_sLogPath, "[Bonding] Condition lost – clearing pending");
        g_bBondingLaserPending = false;
    }

    return Plugin_Continue;
}