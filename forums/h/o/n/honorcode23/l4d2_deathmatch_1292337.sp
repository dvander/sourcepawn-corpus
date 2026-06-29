//Include needed code from sourcemod
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define GETVERSION "1.0.1a"
#define EXP_SOUND "ambient/explosions/explode_1.wav"
#define EXP_SOUND2 "ambient/explosions/explode_2.wav"
#define TCDEBUG 0 //Technical debug
#define DMDEBUG 0 //Deathmatch debug
#define DEBUG 0 //DEBUGGING
#define DEBUG_SPECIAL 0
#define MUSIC_DEBUG 0
#define CHATDEBUG 0
#pragma semicolon 2

#define SDKHOOKS 1 //ALLOW SDKHOOKS FUNCTIONS?

#define MAXENTITIES 2048
#define MAX_LINE_WIDTH 64
#define DB_NAME "deathmatch"

#define ALERTSOUND "music/terror/iamsocold.wav"
#define BEEPSOUND "player/heartbeatloop.wav"
#define FIRE_PARTICLE "gas_explosion_ground_fire"
#define EXPLOSION_PARTICLE "FluidExplosion_fps"
#define EXPLOSION_PARTICLE2 "weapon_grenade_explosion"
#define EXPLOSION_PARTICLE3 "explosion_huge_b"
#define FIRE_SOUND "ambient/fire/interior_fire01_stereo.wav"
#define EXPLOSION_SOUND "ambient/explosions/explode_1.wav"
#define EXPLOSION_SOUND2 "ambient/explosions/explode_2.wav"
#define EXPLOSION_SOUND3 "ambient/explosions/explode_3.wav"
#define BOOMSOUND "ambient/explosions/explode_1.wav"
#define BEEP_SOUND "ui/beep22.wav"
#define RADIO_MODEL "models/deadbodies/dead_male_civilian_radio.mdl"

#define MAX_WEAPONS 30
#define MAX_HEALTH 10
#define MAX_THROWABLE 10
#define MAX_AMMO 2
#define MAX_MELEE 5
#define MAX_MISC 5

#define SOUNDTYPE_WAIT 1
#define SOUNDTYPE_MATCH 2

#define HEART_BEAT "music/flu/concert/onebadman.wav"
#define HEART_BEAT2 "music/flu/concert/midnightride.wav"

#define WAITING_MUSIC "music/stmusic/deadeasy.wav"
#define WAITING_MUSIC2 "No/file/selected"

#define CLASS_CHARGER 6
#define CLASS_JOCKEY 5
#define CLASS_SPITTER 4
#define CLASS_HUNTER 3
#define CLASS_BOOMER 2
#define CLASS_SMOKER 1

//Integers, strings or floats that will be needed in the future
new score[MAXPLAYERS+1] = 0;
new deaths[MAXPLAYERS+1] = 0;
new kills[MAXPLAYERS+1] = 0;
new tscore[MAXPLAYERS+1] = 0;
new tdeaths[MAXPLAYERS+1] = 0;
new tkills[MAXPLAYERS+1] = 0;

new bool:allowmusic[MAXPLAYERS+1] = false;
new bool:notify[MAXPLAYERS+1] = false;
new killcount[MAXPLAYERS+1] = 0;
new points[MAXPLAYERS+1] = 0;
new zombieclass[MAXPLAYERS+1] = 0;
new bool:deathmatch = false;
new bool:g_bInside[MAXPLAYERS+1] = false;
new bool:g_bFirstDone = false;
new bool:g_bChoosedBoost[MAXPLAYERS+1] = false;
new bool:g_bTankQueue[MAXPLAYERS+1] = false;
new bool:g_bHunterQueue[MAXPLAYERS+1] = false;
new bool:g_bChargerQueue[MAXPLAYERS+1] = false;
new bool:g_bJockeyQueue[MAXPLAYERS+1] = false;
new bool:g_bSmokerQueue[MAXPLAYERS+1] = false;
new bool:g_bSpitterQueue[MAXPLAYERS+1] = false;
new bool:g_bBoomerQueue[MAXPLAYERS+1] = false;
new bool:g_bWitchQueue[MAXPLAYERS+1] = false;
new g_iClientOfTank[MAXPLAYERS+1] = 0;
new g_iClientOfWitch[MAXENTITIES+1] = 0;
new bool:g_bPanicProgress = false;
new g_iPanicIndex = 0;
new Float:last_bullet_hit[MAXPLAYERS+1][3];

new bool:g_bRespawnQueue[MAXPLAYERS+1] = false;
new bool:g_bBodyQueue[MAXPLAYERS+1] = false;

new bool:g_bClientLoaded[MAXPLAYERS+1] = false;

#if SDKHOOKS
//new Handle:g_bCanBeRemovedHandle = INVALID_HANDLE;
#endif

new bool:g_bLinked[MAXENTITIES+1] = false;
new bool:g_bHasActiveDefib[MAXPLAYERS+1] = false;
new trewardused[MAXPLAYERS+1] = 0;
new g_iFavBoost[MAXPLAYERS+1] = 0;
new g_iFavCharacter[MAXPLAYERS+1] = 0;
new g_iFavWeapon[MAXPLAYERS+1] = 0;
new bool:g_bAutoMenus[MAXPLAYERS+1] = false;
new bool:g_bShowDebugPanel[MAXPLAYERS+1] = false;

#if !SDKHOOKS
new bool:g_bWeaponManager = false;
#endif

#if !SDKHOOKS
new g_iLastPrimaryWeaponIndex[MAXPLAYERS+1];
#endif

new bool:g_bSQLManager = false;
new bool:g_bBeginDM = false;
new bool:g_bEndDM = false;

new g_iWinner = 0;

new NumPrinted = 90;
new Countdown = 512;

new g_iShotsReceived[MAXPLAYERS+1];
new g_iLastAttacker[MAXPLAYERS+1];

//Player boosts
new bool:g_bExtraHealth[MAXPLAYERS+1] = false;
new bool:g_bExtraSpeed[MAXPLAYERS+1] = false;
new bool:g_bInstaMeleeKill[MAXPLAYERS+1] = false;
new bool:g_bMedic[MAXPLAYERS+1] = false;
new bool:g_bExtraDmg[MAXPLAYERS+1] = false;
new bool:g_bUpgrade[MAXPLAYERS+1] = false;
new bool:g_bVomitDeath[MAXPLAYERS+1] = false;
new bool:g_bGameRunning = false;

new bool:g_bSpitterDeath[MAXPLAYERS+1] = false;
new bool:g_bInstantRespawn[MAXPLAYERS+1] = false;
new bool:g_bNoFire[MAXPLAYERS+1] = false;
new bool:g_bStalker[MAXPLAYERS+1] = false;
new bool:g_bGodMode[MAXPLAYERS+1] = false;
new bool:g_bNoIncap[MAXPLAYERS+1] = false;
new bool:g_bFastCombat[MAXPLAYERS+1] = false;

new bool:g_bIsStalker[MAXPLAYERS+1] = false;

new Handle:hDifficulty = INVALID_HANDLE;
new Handle:hIncapCount = INVALID_HANDLE;
new Handle:hGlowSurvivor = INVALID_HANDLE;
new Handle:hAllBot = INVALID_HANDLE;
new Handle:hNoCheck = INVALID_HANDLE;
new Handle:hBotFF = INVALID_HANDLE;
new Handle:hInfinite = INVALID_HANDLE;
new Handle:hStop = INVALID_HANDLE;

static Handle:hRoundRespawn = INVALID_HANDLE;
static Handle:hBecomeGhost = INVALID_HANDLE;
static Handle:hState_Transition = INVALID_HANDLE;
static Handle:hGameConf = INVALID_HANDLE;
static Handle:g_hGameConf2 = INVALID_HANDLE;
static Handle:sdkCallVomitPlayer = INVALID_HANDLE;
static Handle:sdkCallPushPlayer = INVALID_HANDLE;
static Handle:sdkCallVomitOnPlayer = INVALID_HANDLE;

#if SDKHOOKS
new Handle:g_hWeaponTimeout[2049] = INVALID_HANDLE;//
#endif
new Handle:hRespawnClientFalse[MAXPLAYERS+1] = INVALID_HANDLE;

static g_flLagMovement = 0;
new g_UpgradePackCanUseCountO = -1;

#if DEBUG
new Handle:logfile = INVALID_HANDLE;
#endif

//-----GLOBAL ENTITIES------||
new g_iDirector = 0;
new g_iTriggerFinale = 0;

//-----ACHIEVEMENTS-----||
new bool:g_bDistanceReaper[MAXPLAYERS+1] = false;
new bool:g_bBurningMachine[MAXPLAYERS+1] = false;
new bool:g_bIncapDealer[MAXPLAYERS+1] = false;
new bool:g_bPetCaller[MAXPLAYERS+1] = false;
new bool:g_bEndurance[MAXPLAYERS+1] = false;
new bool:g_bOneShot[MAXPLAYERS+1] = false;
new bool:g_bBodyGuard[MAXPLAYERS+1] = false;
new bool:g_bWidowMaker[MAXPLAYERS+1] = false;
new bool:g_bFallBitch[MAXPLAYERS+1] = false;
new bool:g_bSurprise[MAXPLAYERS+1] = false; //LIGHTING TRIGGER
new bool:g_bFirstDM[MAXPLAYERS+1] = false; //My First Deathmatch
new bool:g_bIWin[MAXPLAYERS+1] = false;

new Float:g_flSpawnTime[MAXPLAYERS+1];
new Float:g_flDeathTime[MAXPLAYERS+1];
new Float:g_flLongestAlive[MAXPLAYERS+1];

//
//-------------------------------CVARS----------------------------------||
//

//Weapon Manager System
new Handle:g_cvarWeaponManagerTimeout = INVALID_HANDLE;
new Handle:g_cvarWeaponManagerGiveSec = INVALID_HANDLE;
new Handle:g_cvarWeaponManagerGivePri = INVALID_HANDLE;
new Handle:g_cvarWeaponManagerEnable = INVALID_HANDLE;

//Reward System - Prices
new Handle:g_cvarRSTankCost = INVALID_HANDLE;
new Handle:g_cvarRSWitchCost = INVALID_HANDLE;
new Handle:g_cvarRSGnomeCost = INVALID_HANDLE;
new Handle:g_cvarRSPackCost = INVALID_HANDLE;
new Handle:g_cvarRSBombCost = INVALID_HANDLE;
new Handle:g_cvarRSPanicCost = INVALID_HANDLE;
new Handle:g_cvarRSVomitCost = INVALID_HANDLE;
new Handle:g_cvarRSLauncherCost = INVALID_HANDLE;

//Reward System - Points
new Handle:g_cvarRSPointsHumanKill = INVALID_HANDLE;
new Handle:g_cvarRSPointsBotKill = INVALID_HANDLE;
//new Handle:g_cvarRSPointsUnlinkedSpecial = INVALID_HANDLE;
new Handle:g_cvarRSPointsUnlinkedTank = INVALID_HANDLE;
new Handle:g_cvarRSPointsUnlinkedWitch = INVALID_HANDLE;
new Handle:g_cvarRSPointsGrenadeBlast = INVALID_HANDLE;
new Handle:g_cvarRSPointsLinkedSpecial = INVALID_HANDLE;
new Handle:g_cvarRSPointsLinkedTank = INVALID_HANDLE;
new Handle:g_cvarRSPointsLinkedWitch = INVALID_HANDLE;
new Handle:g_cvarRSPointsLinkedWitchSingle = INVALID_HANDLE;
//new Handle:g_cvarRSPointsLinkedSpecialKill = INVALID_HANDLE;
new Handle:g_cvarRSPointsLinkedTankKill = INVALID_HANDLE;
//new Handle:g_cvarRSPointsLinkedWitchKill = INVALID_HANDLE;
new Handle:g_cvarRSPointsStalkerKill = INVALID_HANDLE;
new Handle:g_cvarRSPointsFastKill = INVALID_HANDLE;
new Handle:g_cvarRSPointsBurningKill = INVALID_HANDLE;
new Handle:g_cvarRSPointsDistanceKill = INVALID_HANDLE;
new Handle:g_cvarRSPointsSingleHit = INVALID_HANDLE;
new Handle:g_cvarRSPointsEndurance = INVALID_HANDLE;
new Handle:g_cvarRSPointsRowKill = INVALID_HANDLE;
new Handle:g_cvarRSPointsLedgeHang = INVALID_HANDLE;

//Reward System - Calculations
new Handle:g_cvarRSCalcDistance = INVALID_HANDLE;
new Handle:g_cvarRSCalcRowKills = INVALID_HANDLE;
new Handle:g_cvarRSCalcEndurance = INVALID_HANDLE;

//Score System - Points
new Handle:g_cvarSSPointsGrenadeBlast = INVALID_HANDLE;
new Handle:g_cvarSSPointsHumanKill = INVALID_HANDLE;
new Handle:g_cvarSSPointsBotKill = INVALID_HANDLE;
new Handle:g_cvarSSPointsLedgeHang = INVALID_HANDLE;
new Handle:g_cvarSSPointsEndurance = INVALID_HANDLE;
new Handle:g_cvarSSPointsFastTrigger = INVALID_HANDLE;
new Handle:g_cvarSSPointsBurning = INVALID_HANDLE;
new Handle:g_cvarSSPointsInstaKill = INVALID_HANDLE;

//Score System - Interface
new Handle:g_cvarSSMenuDeath = INVALID_HANDLE;
new Handle:g_cvarSSMenuRoundEnd = INVALID_HANDLE;

//Boost System - Interface
new Handle:g_cvarBSAllowExtraHealth = INVALID_HANDLE;
new Handle:g_cvarBSAllowExtraSpeed = INVALID_HANDLE;
new Handle:g_cvarBSAllowInstaMeleeKills = INVALID_HANDLE;
new Handle:g_cvarBSAllowMedic = INVALID_HANDLE;
new Handle:g_cvarBSAllowUpgrade = INVALID_HANDLE;
new Handle:g_cvarBSAllowExtraDamage = INVALID_HANDLE;
new Handle:g_cvarBSAllowVomit = INVALID_HANDLE;
new Handle:g_cvarBSAllowSpitter = INVALID_HANDLE;
new Handle:g_cvarBSAllowInstaRespawn = INVALID_HANDLE;
new Handle:g_cvarBSAllowFire = INVALID_HANDLE;
new Handle:g_cvarBSAllowStalker = INVALID_HANDLE;
new Handle:g_cvarBSAllowGod = INVALID_HANDLE;
new Handle:g_cvarBSAllowNoIncap = INVALID_HANDLE;
new Handle:g_cvarBSAllowFastCombat = INVALID_HANDLE;

//Boost System - Calculations
new Handle:g_cvarBSCalcHealth = INVALID_HANDLE;
new Handle:g_cvarBSCalcSpeed = INVALID_HANDLE;
new Handle:g_cvarBSCalcStalkerTimeout = INVALID_HANDLE;
new Handle:g_cvarBSCalcGodTimeout = INVALID_HANDLE;
new Handle:g_cvarBSCalcFastMinAmount = INVALID_HANDLE;

//Deathmath - General
new Handle:g_cvarDeathmatchDefib = INVALID_HANDLE;

#if SDKHOOKS
new Handle:g_cvarDeathmatchVomitjar = INVALID_HANDLE;
new Handle:g_cvarDeathmatchPipeBomb = INVALID_HANDLE;
#endif
new Handle:g_cvarDeathmatchAllowWeapSpawn = INVALID_HANDLE;
new Handle:g_cvarDeathmatchAllowSurvival = INVALID_HANDLE;
new Handle:g_cvarDeathmatchDuration = INVALID_HANDLE;
new Handle:g_cvarDeathmatchWarmUpDuration = INVALID_HANDLE;
new Handle:g_cvarDeathmatchNoHang = INVALID_HANDLE;
new Handle:g_cvarDeathmatchWipeBody = INVALID_HANDLE;
new Handle:g_cvarDeathmatchBodyTimeout = INVALID_HANDLE;
new Handle:g_cvarDeathmatchExplosionPower = INVALID_HANDLE;
new Handle:g_cvarDeathmatchExplosionRadius = INVALID_HANDLE;
new Handle:g_cvarDeathmatchExplosionTrace = INVALID_HANDLE;
new Handle:g_cvarDeathmatchRefillPills = INVALID_HANDLE;
new Handle:g_cvarDeathmatchEnable = INVALID_HANDLE;
new Handle:g_cvarDeathmatchAutomatic = INVALID_HANDLE;
new Handle:g_cvarDeathmatchRespawnTime = INVALID_HANDLE;
new Handle:g_cvarDeathmatchMapMode = INVALID_HANDLE;
new Handle:g_cvarDeathmatchRespawnHealth = INVALID_HANDLE;

//SQL

//-----------------------FORWARDS AND NATIVES--------------||

//-------------------------SQL----------------------||
new Handle:db = INVALID_HANDLE;

//-------------------------ARRAY----------------------||

/****************************************************************************
*		Dusty1091 plugin source code - Adrenaline and Pills powerups plugin
*****************************************************************************/


//Used to track who has the weapon firing.
//Index goes up to 18, but each index has a value indicating a client index with
//DT so the plugin doesn't have to cycle a full 18 times per game frame
new g_iDTRegisterIndex[64] = -1;
//and this tracks how many have DT
new g_iDTRegisterCount = 0;
//this tracks the current active 'weapon id' in case the player changes guns
new g_iDTEntid[64] = -1;
//this tracks the engine time of the next attack for the weapon, after modification
//(modified interval + engine time)
new Float:g_flDTNextTime[64] = -1.0;
/* ***************************************************************************/
//similar to Double Tap
new g_iMARegisterIndex[64] = -1;
//and this tracks how many have MA
new g_iMARegisterCount = 0;
//these are similar to those used by Double Tap
new Float:g_flMANextTime[64] = -1.0;
new g_iMAEntid[64] = -1;
new g_iMAEntid_notmelee[64] = -1;
//this tracks the attack count, similar to twinSF
new g_iMAAttCount[64] = -1;
/* ***************************************************************************/
//Rates of the attacks
new Float:g_flDT_rate;
/*new Float:melee_speed[MAXPLAYERS+1];*/
new Float:g_fl_reload_rate;
/* ***************************************************************************/
//This keeps track of the default values for reload speeds for the different shotgun types
//NOTE: I got these values from tPoncho's own source
//NOTE: Pump and Chrome have identical values
const Float:g_fl_AutoS = 0.666666;
const Float:g_fl_AutoI = 0.4;
const Float:g_fl_AutoE = 0.675;
const Float:g_fl_SpasS = 0.5;
const Float:g_fl_SpasI = 0.375;
const Float:g_fl_SpasE = 0.699999;
const Float:g_fl_PumpS = 0.5;
const Float:g_fl_PumpI = 0.5;
const Float:g_fl_PumpE = 0.6;
/* ***************************************************************************/
//tracks if the game is L4D 2 (Support for L4D1 pending...)
new g_i_L4D_12 = 0;
/* ***************************************************************************/
//offsets
new g_iNextPAttO		= -1;
new g_iActiveWO			= -1;
new g_iShotStartDurO	= -1;
new g_iShotInsertDurO	= -1;
new g_iShotEndDurO		= -1;
new g_iPlayRateO		= -1;
new g_iShotRelStateO	= -1;
new g_iNextAttO			= -1;
new g_iTimeIdleO		= -1;
new g_iVMStartTimeO		= -1;
new g_iViewModelO		= -1;
new g_iNextSAttO		= -1;
new g_ActiveWeaponOffset;
/* ***************************************************************************/
//****************************************************************************



public Plugin:myinfo = 
{
	name = "[L4D2] Advanced Deathmatch",
	author = "honorcode23",
	description = "Deathmatch mode in Left 4 dead 2",
	version = GETVERSION,
	url = "no url"
}

public OnPluginStart()
{
	//Left 4 dead 2 only
	decl String:sGame[256];
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "left4dead2", false))
	{
		SetFailState("Advanced Deathmatch supports Left 4 dead 2 only!");
	}
	
	#if DEBUG
	LogMessage("[DEATHMATCH DEBUG] The deathmatch plugin is being loaded");
	#endif
	CreateConVar("l4d2_deathmatch_version", GETVERSION, "Version of the Deathmatch Game", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	//Deathmatch
	g_cvarDeathmatchEnable = CreateConVar("l4d2_deathmatch_enable", "1", "Enable the Deathmatch Game (This won't uninstall it completely)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarDeathmatchAutomatic = CreateConVar("l4d2_deathmatch_auto", "1", "Enable automatic startup. If disabled, and admin will have to type !deathmatch to start the game", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarDeathmatchDefib = CreateConVar("l4d2_deathmatch_defib_extra_speed", "1", "Should Defibrilators increase players speed?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarDeathmatchRespawnHealth = CreateConVar("l4d2_deathmatch_respawn_health", "100", "Amount of health that survivors respawn with", FCVAR_PLUGIN);
	
	#if SDKHOOKS
	g_cvarDeathmatchVomitjar = CreateConVar("l4d2_deathmatch_vomitjar_blind_enemies", "1", "Should Vomit (Puke) bottles blind enemies?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	#endif
	
	g_cvarDeathmatchAllowWeapSpawn = CreateConVar("l4d2_deathmatch_allow_weapon_arsenal", "1", "Should the plugin spawn a bunch of weapons on the center of the map?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarDeathmatchAllowSurvival = CreateConVar("l4d2_deathmatch_allow_survival_relay", "1", "Should the plugin execute a survival script if available?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	#if SDKHOOKS
	g_cvarDeathmatchPipeBomb = CreateConVar("l4d2_deathmatch_pipebomb_stronger", "1", "Should Pipe Boms be stronger?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	#endif
	
	g_cvarDeathmatchDuration = CreateConVar("l4d2_deathmatch_duration", "512", "How long should the deathmatch game last? (In Seconds)", FCVAR_PLUGIN);
	g_cvarDeathmatchWarmUpDuration = CreateConVar("l4d2_deathmatch_duration_waiting", "90", "How long should the warm up or waiting mode last before starting deathmatch? (In Seconds)");
	g_cvarDeathmatchNoHang = CreateConVar("l4d2_deathmatch_nohang", "1", "Should the plugin force players to fall if they are hanging?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarDeathmatchWipeBody = CreateConVar("l4d2_deathmatch_wipe_bodies", "1", "Should the plugin remove death bodies after a while? (Prevents Lag)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarDeathmatchBodyTimeout = CreateConVar("l4d2_deathmatch_wipe_bodies_timeout", "1", "How long should the plugin wait before removing a death bodie? (In Seconds)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarDeathmatchExplosionRadius = CreateConVar("l4d2_deathmatch_explosion_radius", "500", "Radius of the reward explosion", FCVAR_PLUGIN);
	g_cvarDeathmatchExplosionPower = CreateConVar("l4d2_deathmatch_explosion_power", "2000", "Power of the reward explosion", FCVAR_PLUGIN);
	g_cvarDeathmatchExplosionTrace = CreateConVar("l4d2_deathmatch_explosion_duration", "15", "Duration of the explosion's fire trace", FCVAR_PLUGIN);
	g_cvarDeathmatchRefillPills = CreateConVar("l4d2_deathmatch_pills_refill", "1", "Should Pain Pills refill a players weapon?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarDeathmatchRespawnTime = CreateConVar("l4d2_deathmatch_respawn_interval", "5", "Interval between death and respawn", FCVAR_PLUGIN);
	g_cvarDeathmatchMapMode = CreateConVar("l4d2_deathmatch_random_map", "0", "Allow random map when the game is over", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	//Weapon Manager
	g_cvarWeaponManagerTimeout = CreateConVar("l4d2_deathmatch_weaponmanager_timeout", "12", "Maximum time of a droped weapon to timeout (After this amount of time, the weapon gets removed)", FCVAR_PLUGIN);
	g_cvarWeaponManagerGiveSec = CreateConVar("l4d2_deathmatch_weaponmanager_secondary", "1", "Give secondary weapon for respawning players", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarWeaponManagerGivePri = CreateConVar("l4d2_deathmatch_weaponmanager_primary", "1", "Give primary weapon for respawning players", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarWeaponManagerEnable = CreateConVar("l4d2_deathmatch_weaponmanager_primary", "1", "Enable Weapon Manager System", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	//Reward System - Prices
	g_cvarRSTankCost = CreateConVar("l4d2_deathmatch_rewardsystem_cost_tank", "45", "How many points do the Tank (We have to fight THAT?) reward cost?", FCVAR_PLUGIN);
	g_cvarRSWitchCost = CreateConVar("l4d2_deathmatch_rewardsystem_cost_witch", "20", "How many points do the Witch (My ex-wife!) reward cost?", FCVAR_PLUGIN);
	g_cvarRSGnomeCost = CreateConVar("l4d2_deathmatch_rewardsystem_cost_gnome", "30", "How many points do the Gnome (Take it please) reward cost?", FCVAR_PLUGIN);
	g_cvarRSPackCost = CreateConVar("l4d2_deathmatch_rewardsystem_cost_pack", "35", "How many points do the SI Pack (I love pets) reward cost?", FCVAR_PLUGIN);
	g_cvarRSBombCost = CreateConVar("l4d2_deathmatch_rewardsystem_cost_bomb", "15", "How many points do the Bomb (Get down!) reward cost?", FCVAR_PLUGIN);
	g_cvarRSPanicCost = CreateConVar("l4d2_deathmatch_rewardsystem_cost_panic", "18", "How many points do the Panic Event (Here they come!) reward cost?", FCVAR_PLUGIN);
	g_cvarRSVomitCost = CreateConVar("l4d2_deathmatch_rewardsystem_cost_vomit", "25", "How many points do the Vomit All (Dont wear a white suit) reward cost?", FCVAR_PLUGIN);
	g_cvarRSLauncherCost = CreateConVar("l4d2_deathmatch_rewardsystem_cost_luancher", "45", "How many points do the Grenade Launcher (Who rules now?) reward cost?", FCVAR_PLUGIN);

	//Reward System - Points
	g_cvarRSPointsHumanKill = CreateConVar("l4d2_deathmatch_rewardsystem_points_humankill", "1", "How many points do the player get if he kills a Human Player?", FCVAR_PLUGIN);
	g_cvarRSPointsBotKill = CreateConVar("l4d2_deathmatch_rewardsystem_points_botkill", "0", "How many points do the player get if he kills a Bot Player?", FCVAR_PLUGIN);
	//g_cvarRSPointsUnlinkedSpecial = CreateConVar("l4d2_deathmatch_rewardsystem_points_unlinked_special", "0", "How many points do the player get if he kills a normal Special Infected", FCVAR_PLUGIN);
	g_cvarRSPointsUnlinkedTank = CreateConVar("l4d2_deathmatch_rewardsystem_points_unlinked_tank", "3", "How many points do the player get if he kills a Normal Tank", FCVAR_PLUGIN);
	g_cvarRSPointsUnlinkedWitch = CreateConVar("l4d2_deathmatch_rewardsystem_points_unlinked_witch", "2", "How many points do the player get if he kills a Normal Witch?", FCVAR_PLUGIN);
	g_cvarRSPointsGrenadeBlast = CreateConVar("l4d2_deathmatch_rewardsystem_points_launcher", "0", "How many points do the player get if he incapacitates a player with a grenade launcher?", FCVAR_PLUGIN);
	g_cvarRSPointsLinkedSpecial = CreateConVar("l4d2_deathmatch_rewardsystem_points_linked_special", "2", "How many points do the player get if he kills a Linked Special Infected (Reward SI)?", FCVAR_PLUGIN);
	g_cvarRSPointsLinkedTank = CreateConVar("l4d2_deathmatch_rewardsystem_points_linked_tank", "20", "How many points do the player get if he kills a Linked Tank (Reward Tank)?", FCVAR_PLUGIN);
	g_cvarRSPointsLinkedWitch = CreateConVar("l4d2_deathmatch_rewardsystem_points_linked_witch", "7", "How many points do the player get if he kills a Linked Witch(Reward Witch)?", FCVAR_PLUGIN);
	g_cvarRSPointsLinkedWitchSingle = CreateConVar("l4d2_deathmatch_rewardsystem_points_linked_witch_single", "15", "How many points do the player get if he kills a Linked Witch(Reward Witch) with a single shot?", FCVAR_PLUGIN);
	//g_cvarRSPointsLinkedSpecialKill = CreateConVar("l4d2_deathmatch_rewardsystem_points_specialkill", "0", "How many points do the player get if he kills a player with his Special Infected? (Note: This will also be added to the points he gets by killing a single player)", FCVAR_PLUGIN);
	g_cvarRSPointsLinkedTankKill = CreateConVar("l4d2_deathmatch_rewardsystem_points_tankkill", "1", "How many points do the player get if he kills a player with his Tank? (Note: This will also be added to the points he gets by killing a single player)", FCVAR_PLUGIN);
	//g_cvarRSPointsLinkedWitchKill = CreateConVar("l4d2_deathmatch_rewardsystem_points_witchkill", "0", How many points do the player get if he kills a player with his Witch? (Note: This will also be added to the points he gets by killing a single player)", FCVAR_PLUGIN);
	g_cvarRSPointsStalkerKill = CreateConVar("l4d2_deathmatch_rewardsystem_points_stalkerkill", "5", "How many points do the player get if he kills another player on Invisible State (Note: This will also be added to the points he gets by killing a single player)", FCVAR_PLUGIN);
	g_cvarRSPointsFastKill = CreateConVar("l4d2_deathmatch_rewardsystem_points_fastkill", "5", "How many points do the player get if he kills another player right after he respawned? (Note: This will also be added to the points he gets by killing a single player)", FCVAR_PLUGIN);
	g_cvarRSPointsBurningKill = CreateConVar("l4d2_deathmatch_rewardsystem_points_burningkill", "2", "How many points do the player get if he kills a player with fire? (Note: This will also be added to the points he gets by killing a single player)", FCVAR_PLUGIN);
	g_cvarRSPointsDistanceKill = CreateConVar("l4d2_deathmatch_rewardsystem_points_distancekill", "7", "How many points do the player get if he kills another player within a huge distance? (Note: This will also be added to the points he gets by killing a single player)", FCVAR_PLUGIN);
	g_cvarRSPointsSingleHit = CreateConVar("l4d2_deathmatch_rewardsystem_points_singlehit", "0", "How many points do the player get if he kills a player with a single melee shot? (Note: This will also be added to the points he gets by killing a single player)", FCVAR_PLUGIN);
	g_cvarRSPointsEndurance = CreateConVar("l4d2_deathmatch_rewardsystem_points_endurance", "15", "How many points do the player get if he last a long time", FCVAR_PLUGIN);
	g_cvarRSPointsRowKill = CreateConVar("l4d2_deathmatch_rewardsystem_points_rowkill", "10", "How many points do the player get if he kills a specific amount of players on one live", FCVAR_PLUGIN);
	g_cvarRSPointsLedgeHang = CreateConVar("l4d2_deathmatch_rewardsystem_points_ledgehang", "10", "How many points do the player get if he makes another player to hang from the ledge?", FCVAR_PLUGIN);

	//Reward System - Calculations
	g_cvarRSCalcDistance = CreateConVar("l4d2_deathmatch_rewardsystem_distance", "1000", "Minimum distance to get the 'DISTANCE REAPER' achievement, points, score and announcement", FCVAR_PLUGIN);
	g_cvarRSCalcRowKills = CreateConVar("l4d2_deathmatch_rewardsystem_rowkills", "4", "How many consecutive player kills are considered as a 'Row Kill'", FCVAR_PLUGIN);
	g_cvarRSCalcEndurance = CreateConVar("l4d2_deathmatch_rewardsystem_endurance", "90", "How long should the okayer last to get the 'ENDURANCE FIGHTER' achievement, points, score and announcement", FCVAR_PLUGIN);

	//Score System - Points
	g_cvarSSPointsGrenadeBlast = CreateConVar("l4d2_deathmatch_scoresystem_points_launcher", "1", "Score for incapacitating an enemy", FCVAR_PLUGIN);
	g_cvarSSPointsHumanKill = CreateConVar("l4d2_deathmatch_scoresystem_points_humankill", "8", "Score for killing a human", FCVAR_PLUGIN);
	g_cvarSSPointsBotKill = CreateConVar("l4d2_deathmatch_scoresystem_points_botkill", "1", "Score for killing a bot", FCVAR_PLUGIN);
	g_cvarSSPointsLedgeHang = CreateConVar("l4d2_deathmatch_scoresystem_points_hang", "15", "Score for forcing an enemy to hang from the ledge", FCVAR_PLUGIN);
	g_cvarSSPointsEndurance = CreateConVar("l4d2_deathmatch_scoresystem_points_endurance", "45", "Score for lasting alot alive", FCVAR_PLUGIN);
	g_cvarSSPointsFastTrigger = CreateConVar("l4d2_deathmatch_scoresystem_points_fasttrigger", "5", "Score for killing an enemy right after he spawned (Score added to the base killing score)", FCVAR_PLUGIN);
	g_cvarSSPointsBurning = CreateConVar("l4d2_deathmatch_scoresystem_points_burning", "1", "Score for burning an enemy (Score added to the base killing score)", FCVAR_PLUGIN);
	g_cvarSSPointsInstaKill = CreateConVar("l4d2_deathmatch_scoresystem_points_instakill", "2", "Score for killing an emeny with a single shot (Score added to the base killing score)", FCVAR_PLUGIN);

	//Score System - Interface
	g_cvarSSMenuDeath = CreateConVar("l4d2_deathmatch_scoresystem_showmenu_death", "1", "Show score stats on death?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarSSMenuRoundEnd = CreateConVar("l4d2_deathmatch_scoresystem_showmenu_roundend", "1", "Show score stats on Deathmatch round end?", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	//Boost System - Interface
	g_cvarBSAllowExtraHealth = CreateConVar("l4d2_deathmatch_boostsystem_allow_extrahealth", "1", "Allow Extra Health boost?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarBSAllowExtraSpeed = CreateConVar("l4d2_deathmatch_boostsystem_allow_extraspeed", "1", "Allow Extra Speed boost?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarBSAllowInstaMeleeKills = CreateConVar("l4d2_deathmatch_boostsystem_allow_instamelee", "1", "Allow Insta Melee Kills boost?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarBSAllowMedic = CreateConVar("l4d2_deathmatch_boostsystem_allow_medic", "1", "Allow Meidc boost?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarBSAllowUpgrade = CreateConVar("l4d2_deathmatch_boostsystem_allow_upgrade", "1", "Allow Upgrade boost?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarBSAllowExtraDamage = CreateConVar("l4d2_deathmatch_boostsystem_allow_extradamage", "1", "Allow Extra Damage boost?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarBSAllowVomit = CreateConVar("l4d2_deathmatch_boostsystem_allow_vomit", "1", "Allow Vomit On Death boost?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarBSAllowSpitter = CreateConVar("l4d2_deathmatch_boostsystem_allow_spitter", "1", "Allow Spawn Spitter On Death boost?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarBSAllowInstaRespawn = CreateConVar("l4d2_deathmatch_boostsystem_allow_instaspawn", "1", "Allow Insta Respawn boost?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarBSAllowFire = CreateConVar("l4d2_deathmatch_boostsystem_allow_nofire", "1", "Allow Fire Immunity boost?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarBSAllowStalker = CreateConVar("l4d2_deathmatch_boostsystem_allow_stalker", "1", "Allow Stalker boost?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarBSAllowGod = CreateConVar("l4d2_deathmatch_boostsystem_allow_god", "1", "Allow God Mode boost?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarBSAllowNoIncap = CreateConVar("l4d2_deathmatch_boostsystem_allow_noincap", "1", "Allow No Grenade Launcher Inca boost?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarBSAllowFastCombat = CreateConVar("l4d2_deathmatch_boostsystem_allow_fastcombat", "1", "Allow Fast Combat boost?", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	//Boost System - Calculations
	g_cvarBSCalcHealth = CreateConVar("l4d2_deathmatch_boostsystem_amount_health", "90", "Additional health for 'Extra Health' boost (DEF: 100+90 = 190)", FCVAR_PLUGIN);
	g_cvarBSCalcSpeed = CreateConVar("l4d2_deathmatch_boostsystem_amount_speed", "0.4", "Additional Speed for 'Extra Speed' boost(DEF: 1.0+0.4 = 1.4)", FCVAR_PLUGIN);
	g_cvarBSCalcStalkerTimeout = CreateConVar("l4d2_deathmatch_boostsystem_amount_stalker", "8", "How long should the Stalker boost last (DEF: 8 seconds)", FCVAR_PLUGIN);
	g_cvarBSCalcGodTimeout = CreateConVar("l4d2_deathmatch_boostsystem_amount_god", "8", "How long should the God Mode boost last (DEF: 8 seconds)", FCVAR_PLUGIN);
	g_cvarBSCalcFastMinAmount = CreateConVar("l4d2_deathmatch_boostsystem_amount_fastcombat", "30", "Minimum amount of health to allow Fast Combar boost (DEF: 30HP)", FCVAR_PLUGIN);
	//Create cfg file
	AutoExecConfig(true, "l4d2_deathmatch");
	
	#if DEBUG
	LogMessage("[DEATHMATCH DEBUG] Created the configuration variables file (AKA: CVARS)");
	#endif
	
	//Gamedata
	hGameConf = LoadGameConfigFile("l4d2deathmatch");
	
	//------SQL------
	OpenConnection();
	
	//-----Commands----------
	
	RegAdminCmd("sm_deathmatch", CmdDeathMatch, ADMFLAG_SLAY, "Creates a deathmatch game");
	RegAdminCmd("sm_deathmatch0", CmdDeathMatch0, ADMFLAG_SLAY, "Stops a deathmatch game");
	RegAdminCmd("sm_testpos", CmdTestPosition, ADMFLAG_SLAY, "Tests all available spots on this map");
	RegAdminCmd("sm_entityinfo", CmdEntityInfo, ADMFLAG_SLAY, "Returns the aiming entity classname");
	RegAdminCmd("sm_testscore", CmdTestScores, ADMFLAG_SLAY, "Tests the score menu");
	RegAdminCmd("sm_randommap", CmdRandomMap, ADMFLAG_SLAY, "Tests the random map function");
	RegAdminCmd("sm_rewardon", CmdRewardOn, ADMFLAG_SLAY, "Forces a reward");
	RegAdminCmd("sm_myweap", CmdMyWeap, ADMFLAG_SLAY, "my weapons");
	
	RegAdminCmd("sm_debugpanel", CmdDebugPanel, ADMFLAG_SLAY, "Show the debug panel");
	
	RegAdminCmd("sm_techtest_pos", CmdTechTestPos, ADMFLAG_ROOT, "Tests a random position using theorical chat printing");
	RegAdminCmd("sm_techtest_cent", CmdTechTestCent, ADMFLAG_ROOT, "Tests the center position using theorical chat printing");
	RegAdminCmd("sm_techtest_nextmap", CmdTechTestNextMap, ADMFLAG_ROOT, "Tests the next map using theorical chat printing");
	RegAdminCmd("sm_myname", CmdMyName, ADMFLAG_ROOT, "Retrieves your name?");
	
	RegConsoleCmd("sm_score", CmdScores, "Prints the current score to players");
	RegConsoleCmd("sm_scores", CmdScores, "Prints the current score to players");
	RegConsoleCmd("sm_reward", CmdReward, "Prints the ability menu to a player, only if it is enabled");
	RegConsoleCmd("sm_rewards", CmdReward, "Prints the ability menu to a player, only if it is enabled");
	RegConsoleCmd("sm_boost", CmdBoost, "Print the current boost menu to players");
	RegConsoleCmd("sm_boosts", CmdBoost, "Print the current boost menu to players");
	RegConsoleCmd("sm_respawn", CmdRespawn, "Respawn in-game");
	RegConsoleCmd("sm_settings", CmdSettings, "Edit and configure your settings");
	RegConsoleCmd("sm_setting", CmdSettings, "Edit and configure your settings");
	RegConsoleCmd("sm_mystats", CmdMyStats, "Check your current stats");
	RegConsoleCmd("sm_mystat", CmdMyStats, "Check your current stats");
	RegConsoleCmd("sm_ranking", CmdRanking, "Check the ranking");
	
	#if DEBUG
	LogMessage("[DEATHMATCH DEBUG] Succesfully created the client and admin commands");
	#endif
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("dead_survivor_visible", Event_DeathPlayerVisible);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_use", Event_PlayerUse);
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("witch_spawn", Event_WitchSpawn);
	HookEvent("witch_harasser_set", Event_WitchAngry);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("tank_killed", Event_TankKilled);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_ledge_grab", Event_LedgeGrab);
	HookEvent("item_pickup", Event_PickUp);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("weapon_reload", Event_WeaponReload);
	HookEvent("pills_used", Event_PillsUsed);
	
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("bullet_impact", Event_BulletImpact);
	
	AddNormalSoundHook(NormalSHook:Event_PlaySound);
	
	#if DEBUG
	LogMessage("[DEATHMATCH DEBUG] Events have been hooked and will be called i nthe future");
	#endif
	
	hDifficulty = FindConVar("z_difficulty");
	hIncapCount = FindConVar("survivor_max_incapacitated_count");
	hGlowSurvivor = FindConVar("sv_disable_glow_survivors");
	hAllBot = FindConVar("sb_all_bot_team");
	hNoCheck = FindConVar("director_no_death_check");
	hBotFF = FindConVar("sb_friendlyfire");
	hInfinite = FindConVar("sv_infinite_ammo");
	hStop = FindConVar("sb_stop");
	
	//-----------------------------------------------SDK CALLS RELATED
	if (hGameConf != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();
		if (hRoundRespawn == INVALID_HANDLE) SetFailState("L4D_SM_Respawn: RoundRespawn Signature broken");
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "BecomeGhost");
		PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
		hBecomeGhost = EndPrepSDKCall();
		if (hBecomeGhost == INVALID_HANDLE) LogError("L4D_SM_Respawn: BecomeGhost Signature broken");

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "State_Transition");
		PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
		hState_Transition = EndPrepSDKCall();
		if (hState_Transition == INVALID_HANDLE) LogError("L4D_SM_Respawn: State_Transition Signature broken");
	}
	else
	{
		SetFailState("could not find gamedata file at addons/sourcemod/gamedata/l4drespawn.txt , you FAILED AT INSTALLING");
	}
	
	//SDKCALL
	g_hGameConf2 = LoadGameConfigFile("l4d2deathmatch");
	if(g_hGameConf2 == INVALID_HANDLE)
	{
		SetFailState("Couldn't find the signatures file. Please, check that it is installed correctly.");
	}
	
	g_UpgradePackCanUseCountO = GameConfGetOffset(g_hGameConf2, "m_iUpgradePackCanUseCount");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf2, SDKConf_Signature, "CTerrorPlayer_OnHitByVomitJar");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkCallVomitPlayer = EndPrepSDKCall();
	
	if(sdkCallVomitPlayer == INVALID_HANDLE)
	{
		SetFailState("Unable to find the 'CTerrorPlayer_OnHitByVomitJar' signature, check the file version!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf2, SDKConf_Signature, "CTerrorPlayer_Fling");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkCallPushPlayer = EndPrepSDKCall();
	if(sdkCallPushPlayer == INVALID_HANDLE)
	{
		SetFailState("Unable to find the 'CTerrorPlayer_Fling' signature, check the file version!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf2, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkCallVomitOnPlayer = EndPrepSDKCall();
	
	if (sdkCallVomitOnPlayer == INVALID_HANDLE)
	{
		SetFailState("Unable to find the 'CTerror_Player_OnVomitedUpon' signature, check the file version!");
		return;
	}
	
	#if DEBUG
	LogMessage("[DEATHMATCH DEBUG] Successfully created and tracked SDK CALLS");
	#endif
}

public OnPluginEnd()
{
	#if DEBUG
	LogMessage("[DEATHMATCH DEBUG] The deathmatch plugin is being unloaded");
	#endif
	CloseConnection();
	#if DEBUG
	LogMessage("[DEATHMATCH DEBUG] Unloaded succesfully");
	#endif
}

#if SDKHOOKS
public Action:OnWeaponEquip(client, weapon)
{
	if(g_hWeaponTimeout[weapon] != INVALID_HANDLE)
	{
		KillTimer(g_hWeaponTimeout[weapon]);
		g_hWeaponTimeout[weapon] = INVALID_HANDLE;
	}
}


public Action:OnWeaponDrop(client, weapon)
{
	if(weapon >= MAXENTITIES)
	{
		LogError("[ERROR] The current entity is bigger than the capacity. Report this");
	}
	if(GetConVarBool(g_cvarWeaponManagerEnable))
	{
		if(g_hWeaponTimeout[weapon] != INVALID_HANDLE)
		{
			KillTimer(g_hWeaponTimeout[weapon]);
			g_hWeaponTimeout[weapon] = INVALID_HANDLE;
		}
		g_hWeaponTimeout[weapon] = CreateTimer(GetConVarFloat(g_cvarWeaponManagerTimeout), WeaponExistenceTimeout, weapon, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:WeaponExistenceTimeout(Handle:timer, any:weapon)
{
	g_hWeaponTimeout[weapon] = INVALID_HANDLE;
	if(weapon > 0 && IsValidEntity(weapon) && IsValidEdict(weapon) && g_bGameRunning && deathmatch)
	{
		decl String:class[64];
		GetEdictClassname(weapon, class, sizeof(class));
		if(StrEqual(class, "weapon_rifle")
		|| StrEqual(class, "weapon_rifle_desert")
		|| StrEqual(class, "weapon_rifle_ak47")
		|| StrEqual(class, "weapon_sniper_military")
		|| StrEqual(class, "weapon_shotgun_spas")
		|| StrEqual(class, "weapon_shotgun_chrome")
		|| StrEqual(class, "weapon_smg")
		|| StrEqual(class, "weapon_pumpshotgun")
		|| StrEqual(class, "weapon_first_aid_kit")
		|| StrEqual(class, "weapon_chainsaw")
		|| StrEqual(class, "weapon_adrenaline")
		|| StrEqual(class, "weapon_autoshotgun")
		|| StrEqual(class, "weapon_sniper_scout")
		|| StrEqual(class, "weapon_molotov")
		|| StrEqual(class, "weapon_upgradepack_incendiary")
		|| StrEqual(class, "weapon_upgradepack_explosive")
		|| StrEqual(class, "weapon_pain_pills")
		|| StrEqual(class, "weapon_pipe_bomb")
		|| StrEqual(class, "weapon_vomitjar")
		|| StrEqual(class, "weapon_smg_silenced")
		|| StrEqual(class, "weapon_smg_mp5")
		|| StrEqual(class, "weapon_sniper_awp")
		|| StrEqual(class, "weapon_sniper_scout")
		|| StrEqual(class, "weapon_rifle_sg552")
		|| StrEqual(class, "weapon_gnome")
		|| StrEqual(class, "weapon_pistol_magnum")
		|| StrEqual(class, "weapon_hunting_rifle")
		|| StrEqual(class, "weapon_pistol"))
		{
			AcceptEntityInput(weapon, "Kill");
			#if DEBUG
			PrintToServer("[WEAPON MANAGER] Weapon %s( ID: %i) timed out and got removed", class, weapon);
			PrintToServer("[ENTITY MANAGER] The current entity count is: %i/%i", GetValidEntityCount(), GetMaxEntities());
			#endif
			return;
		}
	}
	#if DEBUG
	WriteFileLine(logfile,"[WEAPON MANAGER] A weapon was on deleting queue, but it was either invalid or in usage");
	PrintToServer("[WEAPON MANAGER] A weapon was on deleting queue, but it was either invalid or in usage");
	#endif
}

public OnEntityCreated(entity, const String:class[])
{
	#if DMDEBUG
	new iCurrentEntities = GetValidEntityCount();
	new iMaxEntities = GetMaxEntities();
	LogMessage("Current entity count %i/%i", iCurrentEntities, iMaxEntities);
	#endif
	if(StrEqual(class, "upgrade_ammo_explosive") || StrEqual(class, "upgrade_ammo_incendiary"))
	{
		if(IsValidEntity(entity) && IsValidEdict(entity))
		{
			SetEntData(entity, g_UpgradePackCanUseCountO, 50, 1,true);
		}
	}
	
	if(StrContains(class, "weapon_") >= 0 || StrEqual(class, "survivor_death_model"))
	{
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
	}
	
	if(StrEqual(class, "weapon_gascan") || StrEqual(class, "weapon_propanetank") || StrEqual(class, "prop_physics"))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public OnEntitySpawned(entity)
{
	decl String:class[64];
	GetEdictClassname(entity, class, sizeof(class));
	
	if(StrEqual(class, "survivor_death_model"))
	{
		decl Float:pos[3];
		for(new i=1; i<=MaxClients; i++)
		{
			if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && g_bBodyQueue[i])
			{
				g_bBodyQueue[i] = false;
				GetClientAbsOrigin(i, pos);
				TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				return;
			}
		}
		return;
	}
	
	new Handle:keyvalues = INVALID_HANDLE;
	decl String:KvFileName[256];
	new bool:FileFound = false;
	
	BuildPath(Path_SM, KvFileName, sizeof(KvFileName), "data/deathmatch/l4d2_deathmatch_weapons.txt");
	
	if(!FileExists(KvFileName))
	{
		LogMessage("[WARNING] Unable to find the l4d2_deathmatch_weapons.txt file, the weapons ammo won't be affected");
		FileFound = false;
	}
	else
	{
		FileFound = true;
	}
	
	if(FileFound)
	{
		keyvalues = CreateKeyValues("l4d2_deathmatch_weapons");
		FileToKeyValues(keyvalues, KvFileName);
		KvRewind(keyvalues);
		decl String:weapon[256];
		strcopy(weapon, sizeof(weapon), class);
		ReplaceString(weapon, sizeof(weapon), "weapon_", "");
		if(KvJumpToKey(keyvalues, weapon))
		{
			new ammo = KvGetNum(keyvalues, "max ammo", 0);
			if(ammo <= 0)
			{
				CloseHandle(keyvalues);
				return;
			}
			SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", ammo, 4);
			SetEntProp(entity, Prop_Send, "m_iClip1", ammo);
			CloseHandle(keyvalues);
			return;
		}
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	decl String:class[64];
	GetEdictClassname(victim, class, sizeof(class));
	if(!deathmatch)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnEntityDestroyed(entity)
{
	if(!deathmatch)
		return;
		
	decl String:class[64];
	GetEdictClassname(entity, class, sizeof(class));
	#if TCDEBUG
	PrintToChatAll("%s got destroyed", class);
	#endif
	
	if(StrEqual(class, "vomitjar_projectile") && GetConVarBool(g_cvarDeathmatchVomitjar))
	{	
		decl Float:pos[3], tpos[3];
		new Float:MinDistance = 200.0;
		GetEntityAbsOrigin(entity, pos);
		pos[2] += 70.0;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)
			|| GetClientTeam(i) != 2
			|| !IsPlayerAlive(i))
			{
				continue;
			}
			GetClientEyePosition(i, Float:tpos);
			if (GetVectorDistance(Float:pos, Float:tpos) > Float:MinDistance
			|| !IsVisibleTo(Float:pos, Float:tpos))
			{
				continue;
			}
			SDKCall(sdkCallVomitOnPlayer, i, GetAnyValidSurvivor(), true);
		}
	}
	else if(StrEqual(class, "pipe_bomb_projectile") && GetConVarBool(g_cvarDeathmatchPipeBomb))
	{
		decl Float:pos[3];
		GetEntityAbsOrigin(entity, pos);
		pos[2] += 70.0;
		new explosion = CreateEntityByName("env_explosion");
		DispatchKeyValue(explosion, "iMagnitude", "300");
		DispatchKeyValue(explosion, "spawnflags", "1916");
		DispatchKeyValue(explosion, "iRadiusOverride", "200");
		DispatchSpawn(explosion);
		TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(explosion, "Explode");
		AcceptEntityInput(explosion, "Kill");
		decl Float:distance[3], Float:tpos[3], Float:ratio[3], Float:addVel[3], Float:tvec[3], Float:power, Float:flMxDistance;
		power = 300.0;
		flMxDistance = 200.0;
		for(new i=1; i<=MaxClients; i++)
		{
			if(i == 0 || !IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i))
			{
				continue;
			}
			if(GetClientTeam(i) != 2)
			{
				continue;
			}
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", tpos);
			distance[0] = (pos[0] - tpos[0]);
			distance[1] = (pos[1] - tpos[1]);
			distance[2] = (pos[2] - tpos[2]);
			
			new Float:realdistance = SquareRoot(FloatMul(distance[0],distance[0])+FloatMul(distance[1],distance[1]));
			if(realdistance <= flMxDistance)
			{			
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", tvec);
				
				addVel[0] = FloatMul(ratio[0]*-1, power);
				addVel[1] = FloatMul(ratio[1]*-1, power);
				addVel[2] = power;
				FlingPlayer(i, addVel, i);
			}
		}
		
	}
	else if(StrEqual(class, "witch"))
	{
		g_iClientOfWitch[entity] = 0;
		g_bLinked[entity] = false;
	}
}
#endif

public Event_PlayerUse(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new entityid = GetEventInt(event, "targetid");
	decl String:sHammer[256];
	if(entityid <= 0)
	{
		return;
	}
	if(entityid > 0)
	{
		GetEdictClassname(entityid, sHammer, sizeof(sHammer));
		if(StrEqual(sHammer, "upgrade_ammo_explosive") || StrEqual(sHammer, "upgrade_ammo_incendiary"))
		{
			SetEntData(entityid, FindSendPropInfo("CBaseUpgradeItem", "m_iUsedBySurvivorsMask"), 0, 1,true);
			if(!deathmatch)
			{
				SetEntData(entityid, g_UpgradePackCanUseCountO, 999, 1,true);
			}
			else
			{
				SetEntData(entityid, g_UpgradePackCanUseCountO, 1, 1,true);
			}
			#if DEBUG
			LogMessage("[DEATHMATCH DEBUG] upgrade_ammo_explosive entity used and changed the mask for multiple survivor upgrades");
			#endif
		}
	}
}

public Action:CmdTestScores(client, args)
{
	BuildScoreMenu(client);
	#if DEBUG
	LogMessage("[DEATHMATCH DEBUG] Command sm_testscores was called");
	#endif
}
public Action:CmdRewardOn(client, args)
{
	points[client] = 999;
	killcount[client] = 0;
	PrintToChat(client, "\x04Forced Points");
	#if DEBUG
	LogMessage("[DEATHMATCH DEBUG] Command sm_rewardon was called");
	#endif
}

public Action:CmdBoost(client, args)
{
	#if DEBUG
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogMessage("[COMMAND] %s (ID:%i) requested the sm_boost command", name, client);
	#endif
	if(g_bChoosedBoost[client])
	{
		if(notify[client])
		{
			PrintToChat(client, "\x03You have already selected your boost for this live!");
		}
		return Plugin_Handled;
	}
	BuildBoostMenu(client);
	return Plugin_Handled;
}

public Action:CmdRespawn(client, args)
{
	#if DEBUG
	LogMessage("[DEATHMATCH DEBUG] Command sm_respawn was called");
	#endif
	if(client <= 0)
	{
		return Plugin_Handled;
	}
	if(!deathmatch)
	{
		PrintToChat(client, "\x03Wait for the deathmatch game to begin!");
		return Plugin_Handled;
	}
	if(IsPlayerAlive(client))
	{
		PrintToChat(client, "\x03Please, wait while you are being reallocated");
		PrintHintText(client, "If you receive damage, the reallocate will be canceled");
		if(hRespawnClientFalse[client] != INVALID_HANDLE)
		{
			KillTimer(hRespawnClientFalse[client]);
			hRespawnClientFalse[client] = INVALID_HANDLE;
		}
		hRespawnClientFalse[client] = CreateTimer(GetConVarFloat(g_cvarDeathmatchRespawnTime), RespawnClientFalse, client, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Handled;
	}
	PrintToChat(client, "\x03You will respawn in %i seconds", GetConVarInt(g_cvarDeathmatchRespawnTime));
	g_bRespawnQueue[client] = true;
	CreateTimer(GetConVarFloat(g_cvarDeathmatchRespawnTime), RespawnClient, client, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}

public Action:RespawnClientFalse(Handle:timer, any:client)
{
	hRespawnClientFalse[client] = INVALID_HANDLE;
	decl Float:pos[3];
	pos = GetRandomRespawnPos(); //Get a random valid position for the specified map
	if(!deathmatch
	|| client <= 0
	|| !IsValidEntity(client)
	|| !IsClientInGame(client)
	|| !IsPlayerAlive(client)
	|| GetClientTeam(client) != 2
	|| zombieclass[client] == 8)
	{
		return;
	}
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR); // Teleports the client ot the valid position obtained
}

public Action:CmdScores(client, args)
{
	#if DEBUG
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogMessage("[COMMAND] %s (ID:%i) requested the sm_score command", name, client);
	PrintToServer("[COMMAND] %s (ID:%i) requested the sm_score command", name, client);
	#endif
	BuildScoreMenu(client);
	PrintToChat(client, "\x04Kills: %i ##, Deaths: %i ## Score: %i", kills[client], deaths[client], score[client]);
}
public Action:CmdMyWeap(client, args)
{
	decl String:weap[256];
	GetClientWeapon(client, weap, sizeof(weap));
	PrintToChat(client, "Your weapon is %s", weap);
}
public Action:CmdEntityInfo(client, args)
{
	new entity = GetClientAimTarget(client, false);

	if ((entity == -1) || (!IsValidEntity (entity)))
	{
		ReplyToCommand (client, "Invalid entity, or looking to nothing");
	}
	decl String:sNetwork[256], String:sHammer[256];
	if(entity <= 0)
	{
		return;
	}
	if(entity > 0)
	{
		GetEntityNetClass(entity, sNetwork, sizeof(sNetwork));
		GetEdictClassname(entity, sHammer, sizeof(sHammer));
		PrintToChat(client, "Hammer Classname: %s", sHammer);
		PrintToChat(client, "Network Classname: %s", sNetwork);
	}
}

public Action:CmdRandomMap(client, args)
{
	decl String:mapname[256];
	GetRandomValidMap(mapname, sizeof(mapname));
	PrintToChat(client, "NEXT MAP: %s", mapname);
}

public Action:CmdTestPosition(client, args)
{
	decl Float:pos[3];
	pos = GetRandomRespawnPos();
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
}

public OnMapStart()
{
	if(g_bGameRunning)
	{
		LogError("[FATAL ERROR] A map has already started ??");
		LogMessage("[FATAL ERROR] A map has already started ??");
		return;
	}
	g_bBeginDM = false;
	deathmatch = false;
	g_bPanicProgress = false;
	g_iPanicIndex = 0;
	CreateTimer(0.5, OnDeathmatchGameFrame, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	OpenConnection();
	if(!g_bSQLManager)
	{
		CreateTimer(30.0, timerSQLManager, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	//------SQL------
	Countdown = GetConVarInt(g_cvarDeathmatchDuration);
	if(!GetConVarBool(g_cvarDeathmatchEnable))
	{
		LogMessage("[DEATHMATCH] Deathmatch is disabled. Remove the stripper files to fully uninstall it!");
		return;
	}
	#if DEBUG
	if(logfile == INVALID_HANDLE)
	{
		logfile = OpenFile("/addons/sourcemod/logs/deathmatch_debug.log", "w");
		if(logfile == INVALID_HANDLE)
		{
			LogError("[DEATHMATCH FATAL ERROR] Unable to access the debuggin log file. Debugging is useless!");
		}
		else
		{
			LogMessage("[DEATHMATCH] Succesfully opened the debug file");
		}
	}
	#endif
	
	#if DEBUG
	LogMessage("---------------MAP STARTED------------");
	PrintToServer("---------------MAP STARTED------------");
	decl String:map[256];
	GetCurrentMap(map, sizeof(map));
	LogMessage("Current Map: %s", map);
	PrintToServer("Current Map: %s", map);
	#endif
	
	ServerCommand("exec deathmatch");
	SetConVarInt(hInfinite, 1, true, false);
	SetConVarInt(hStop, 0, true, false);
	g_iDirector = CreateEntityByName("info_director");
	DispatchSpawn(g_iDirector);
	if(GetConVarBool(g_cvarDeathmatchAllowWeapSpawn))
	{
		decl Float:pos[3];
		new item = 0;
		pos = GetCenterCoordinates();
		for(new i=1; i<=30; i++)
		{
			item = GetRandomItemSpawn();
			if(IsValidEntity(item) && IsValidEdict(item))
			{
				DispatchSpawn(item);
				SetUpAmmo(item);
				TeleportEntity(item, pos, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
	
	for(new i=1; i<=MaxClients; i++)
	{
		g_bChoosedBoost[i] = false;
		g_bClientLoaded[i] = false;
	}
	g_bGameRunning = true;
	CreateTimer(1.0, timerScriptsManager, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(1.0, timerPositionManager, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	g_flLagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	PrecacheSound(ALERTSOUND);
	PrecacheSound(BEEPSOUND);
	PrecacheSound(BOOMSOUND);
	PrecacheSound(FIRE_SOUND);
	PrecacheSound(EXPLOSION_SOUND);
	PrecacheSound(EXPLOSION_SOUND2);
	PrecacheSound(EXPLOSION_SOUND3);
	PrecacheSound(BEEP_SOUND);
	PrecacheSound(WAITING_MUSIC);
	PrecacheSound(WAITING_MUSIC2);
	
	PrecacheModel("sprites/muzzleflash4.vmt");
	
	PrecacheModel("models/infected/witch.mdl");
	PrecacheModel("models/infected/witch_bride.mdl");
	PrecacheModel(RADIO_MODEL);
	
	PrefetchSound(ALERTSOUND);
	PrefetchSound(BEEPSOUND);
	PrefetchSound(BOOMSOUND);
	PrefetchSound(FIRE_SOUND);
	PrefetchSound(BEEP_SOUND);
	PrefetchSound(EXPLOSION_SOUND);
	PrefetchSound(EXPLOSION_SOUND2);
	PrefetchSound(EXPLOSION_SOUND3);
	PrecacheSound(EXP_SOUND);
	PrecacheSound(EXP_SOUND2);
	PrecacheSound(HEART_BEAT);
	PrecacheSound(HEART_BEAT2);
	PrecacheSound("music/safe/themonsterswithout.wav");
	
	PrecacheAllTracks();
	AddTracksToTable();
	
	PrecacheParticle(FIRE_PARTICLE);
	PrecacheParticle(EXPLOSION_PARTICLE);
	PrecacheParticle(EXPLOSION_PARTICLE2);
	PrecacheParticle(EXPLOSION_PARTICLE3);
	
	hDifficulty = FindConVar("z_difficulty");
	for(new i=1; i<=MaxClients; i++)
	{
		kills[i] = 0;
		score[i] = 0;
		deaths[i] = 0;
	}
	CreateTimer(1.0, CheckDM, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(15.0, WipeEnt, _, TIMER_FLAG_NO_MAPCHANGE);
	#if DEBUG_SPECIAL
	LogMessage("[Deathmatch] Attempt to create the timer to begin the match");
	#endif
	if(GetConVarBool(g_cvarDeathmatchAutomatic) && !g_bBeginDM)
	{
		g_bBeginDM = true;
		#if DEBUG_SPECIAL
		LogMessage("[Deathmatch] The timer was created succesfully");
		#endif
		CreateTimer(1.0, BeginDM, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		#if DEBUG_SPECIAL
		LogMessage("[Deathmatch] Error creating the timer. The automatic start is disabled or it is already running");
		#endif
	}
	//*************************************************************************
	
	//**********************************Dusty's plugins
	//get offsets
	g_iNextPAttO		=	FindSendPropInfo("CBaseCombatWeapon","m_flNextPrimaryAttack");
	g_iActiveWO			=	FindSendPropInfo("CBaseCombatCharacter","m_hActiveWeapon");
	g_iShotStartDurO	=	FindSendPropInfo("CBaseShotgun","m_reloadStartDuration");
	g_iShotInsertDurO	=	FindSendPropInfo("CBaseShotgun","m_reloadInsertDuration");
	g_iShotEndDurO		=	FindSendPropInfo("CBaseShotgun","m_reloadEndDuration");
	g_iPlayRateO		=	FindSendPropInfo("CBaseCombatWeapon","m_flPlaybackRate");
	g_iShotRelStateO	=	FindSendPropInfo("CBaseShotgun","m_reloadState");
	g_iNextAttO			=	FindSendPropInfo("CTerrorPlayer","m_flNextAttack");
	g_iTimeIdleO		=	FindSendPropInfo("CTerrorGun","m_flTimeWeaponIdle");
	g_iVMStartTimeO		=	FindSendPropInfo("CTerrorViewModel","m_flLayerStartTime");
	g_iViewModelO		=	FindSendPropInfo("CTerrorPlayer","m_hViewModel");
	
	g_ActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	g_iNextSAttO		=	FindSendPropInfo("CBaseCombatWeapon","m_flNextSecondaryAttack");
	g_fl_reload_rate = 0.5714;
	g_flDT_rate = 0.6667;
	
	//**************************************************************
}

stock PrecacheParticle(String:ParticleName[])
{
	new Particle = CreateEntityByName("info_particle_system");
	if(IsValidEntity(Particle) && IsValidEdict(Particle))
	{
		DispatchKeyValue(Particle, "effect_name", ParticleName);
		DispatchSpawn(Particle);
		ActivateEntity(Particle);
		AcceptEntityInput(Particle, "start");
		CreateTimer(0.3, timerRemovePrecacheParticle, Particle, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:timerRemovePrecacheParticle(Handle:timer, any:Particle)
{
	if(IsValidEntity(Particle) && IsValidEdict(Particle))
	{
		AcceptEntityInput(Particle, "Kill");
	}
}
public Action:WipeEnt(Handle:timer)
{
	decl String:map[256];
	GetCurrentMap(map, sizeof(map));
	CheatCommand(_, "ent_remove_all", "trigger_finale");
	CheatCommand(_, "ent_remove_all", "func_button");
	CheatCommand(_, "ent_fire", "checkpoint_entrance close");
	CheatCommand(_, "ent_fire", "checkpoint_entrance disable");
	CheatCommand(_, "ent_fire", "checkpoint_exit lock");
	decl String:classname[256];
	for(new i=MaxClients+1; i<GetMaxEntities(); i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, classname, sizeof(classname));
			if(StrEqual(classname, "weapon_grenade_launcher_spawn"))
			{
				AcceptEntityInput(i, "Kill");
			}
		}
	}
}
public OnMapEnd()
{
	#if DEBUG
	LogMessage("[DEATHMATCH]-------------------------MAP END-------------------");
	#endif
	#if DEBUG
	LogMessage("[DEATHMATCH] Connection with the database is going to be terminated");
	#endif
	CloseConnection();
	#if DEBUG
	if(logfile != INVALID_HANDLE)
	{
		CloseHandle(logfile);
		logfile = INVALID_HANDLE;
	}
	#endif
	ClearAll();
	#if DEBUG
	LogMessage("[DEATHMATCH] Cleared the tick registry");
	#endif
	NumPrinted = GetConVarInt(g_cvarDeathmatchWarmUpDuration);
	g_bGameRunning = false;
	g_bFirstDone = false;
	#if DEBUG
	LogMessage("[DEATHMATCH] Global integers and bools cleared");
	#endif
	for(new i=1; i<=MaxClients; i++)
	{
		kills[i] = 0;
		score[i] = 0;
		deaths[i] = 0;
		
		g_bExtraHealth[i] = false;
		g_bExtraSpeed[i] = false;
		g_bInstaMeleeKill[i] = false;
		g_bMedic[i] = false;
		g_bUpgrade[i] = false;
		g_bExtraDmg[i] = false;
		g_bVomitDeath[i] = false;
		g_bSpitterDeath[i] = false;
		g_bInstantRespawn[i] = false;
		g_bNoFire[i] = false;
		g_bStalker[i] = false;
		g_bGodMode[i] = false;
		g_bNoIncap[i] = false;
		g_bFastCombat[i] = false;
		
		g_iShotsReceived[i] = 0;
		g_bWitchQueue[i] = false;
		g_bIsStalker[i] = false;
		g_bHasActiveDefib[i] = false;
		
		points[i] = 0;
		g_bLinked[i] = false;
		g_iClientOfTank[i] = 0;
		g_bTankQueue[i] = false;
		g_bHunterQueue[i] = false;
		g_bChargerQueue[i] = false;
		g_bJockeyQueue[i] = false;
		g_bSmokerQueue[i] = false;
		g_bSpitterQueue[i] = false;
		g_bBoomerQueue[i] = false;
		g_bInside[i] = false;
		g_iLastAttacker[i] = 0;
		g_bRespawnQueue[i] = false;
		g_bBodyQueue[i] = false;
		hRespawnClientFalse[i] = INVALID_HANDLE;
	}
	for(new i=MaxClients+1; i<=GetMaxEntities(); i++)
	{
		g_iClientOfWitch[i] = 0;
		g_bLinked[i] = false;
	}
	#if DEBUG
	LogMessage("[DEATHMATCH] General stats cleared");
	#endif
	#if DEBUG
	LogMessage("[DEATHMATCH] Map end functions are now over, plugin deactivated.");
	#endif
}
public OnClientDisconnect(client)
{
	RebuildAll();	
	//Player boosts
	g_bExtraHealth[client] = false;
	g_bExtraSpeed[client] = false;
	g_bInstaMeleeKill[client] = false;
	g_bMedic[client] = false;
	g_bExtraDmg[client] = false;
	g_bUpgrade[client] = false;
	g_bVomitDeath[client] = false;

	g_bSpitterDeath[client] = false;
	g_bInstantRespawn[client] = false;
	g_bNoFire[client] = false;
	g_bStalker[client] = false;
	g_bGodMode[client] = false;
	g_bNoIncap[client] = false;
	g_bFastCombat[client] = false;
	g_bIsStalker[client] = false;

	g_flSpawnTime[client] = 0.0;
	g_flDeathTime[client] = 0.0;
	for(new i=1; i < GetMaxEntities(); i++)
	{
		if(i<=0
		|| i>GetMaxEntities()
		|| !IsValidEntity(i)
		|| !IsValidEdict(i))
		{
			continue;
		}
		if(g_bLinked[i])
		{
			if(g_iClientOfTank[i] == client || g_iClientOfWitch[i] == client)
			{
				g_bLinked[i] = false;
				g_iClientOfTank[i] = 0;
				g_iClientOfWitch[i] = 0;
			}
		}
	}
}

public OnClientPutInServer(client)
{
	score[client] = 0;
	deaths[client] = 0;
	kills[client] = 0;
	killcount[client] = 0;
	points[client] = 0;
	zombieclass[client] = 0;
	g_bInside[client] = false;
	g_bChoosedBoost[client] = false;
	g_bTankQueue[client] = false;
	g_bHunterQueue[client] = false;
	g_bChargerQueue[client] = false;
	g_bJockeyQueue[client] = false;
	g_bSmokerQueue[client] = false;
	g_bSpitterQueue[client] = false;
	g_bBoomerQueue[client] = false;
	g_bHasActiveDefib[client] = false;
	g_iClientOfTank[client] = 0;
	g_bLinked[client] = false;
	g_iShotsReceived[client] = 0;
	g_bWitchQueue[client] = false;
	g_iLastAttacker[client] = 0;
	
	//Player boosts
	g_bExtraHealth[client] = false;
	g_bExtraSpeed[client] = false;
	g_bInstaMeleeKill[client] = false;
	g_bMedic[client] = false;
	g_bExtraDmg[client] = false;
	g_bUpgrade[client] = false;
	g_bVomitDeath[client] = false;

	g_bSpitterDeath[client] = false;
	g_bInstantRespawn[client] = false;
	g_bNoFire[client] = false;
	g_bStalker[client] = false;
	g_bGodMode[client] = false;
	g_bNoIncap[client] = false;
	g_bFastCombat[client] = false;
	g_bIsStalker[client] = false;
	g_bClientLoaded[client] = false;

	g_flSpawnTime[client] = 0.0;
	g_flDeathTime[client] = 0.0;
	g_bRespawnQueue[client] = false;
	g_bBodyQueue[client] = false;
	for(new i=1; i<=GetMaxEntities(); i++)
	{
		if(g_bLinked[i])
		{
			if(g_iClientOfTank[i] == client || g_iClientOfWitch[i] == client)
			{
				g_bLinked[i] = false;
				g_iClientOfTank[i] = 0;
				g_iClientOfWitch[i] = 0;
			}
		}
	}
	
	if(client <= 0
	|| !IsValidEntity(client)
	|| !IsValidEdict(client)
	|| !IsClientInGame(client))
	{
		return;
	}
	#if DEBUG
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogMessage("[EVENT] %s (ID:%i) was put in server", name, client);
	PrintToServer("[EVENT] %s (ID:%i) was put in server", name, client);
	#endif
	RebuildAll();
	CreateTimer(15.0, timerAdvert, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(5.5, timerUpdateDatabase, client, TIMER_FLAG_NO_MAPCHANGE);
	if(GetConVarBool(g_cvarWeaponManagerEnable))
	{
		CreateTimer(20.0, timerHook, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	if(!HasBoost(client) && g_iFavBoost[client] <= 0 && g_bAutoMenus[client])
	{
		BuildBoostMenu(client);
	}
	if(!HasBoost(client) && g_iFavBoost[client] > 0)
	{
		CreateTimer(8.0, timerChooseFavBoost, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:timerChooseFavBoost(Handle:timer, any:client)
{
	if(client <= 0
	|| !IsValidEntity(client)
	|| !IsValidEdict(client)
	|| !IsClientInGame(client)
	|| IsFakeClient(client))
	{
		return;
	}
	SetFavoriteBoost(client);
}

public Action:timerHook(Handle:timer, any:client)
{
	if(client > 0 && IsValidEntity(client) && IsValidEdict(client) && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		#if SDKHOOKS
		SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
		#endif
		#if DEBUG
		LogMessage("[WEAPONG MANAGER] Hooked OnWeaponDrop call");
		PrintToServer("[WEAPONG MANAGER] Hooked OnWeaponDrop call");
		#endif
		#if SDKHOOKS
		SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
		#endif
		#if DEBUG
		LogMessage("[WEAPONG MANAGER] Hooked OnWeaponEquip call");
		PrintToServer("[WEAPONG MANAGER] Hooked OnWeaponEquip call");
		#endif
		return;
	}
	#if DEBUG
	LogMessage("[WEAPONG MANAGER] Cant hook calls on an invalid ir restricted client");
	PrintToServer("[WEAPONG MANAGER] Cant hook calls on an invalid or restricted client");
	#endif
}

public Action:timerAdvert(Handle:timer, any:client)
{
	if(client > 0 && IsValidEntity(client) && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		if(!IsFakeClient(client))
		{
			PrintToChat(client, "\x04Welcome! Wait for the deathmatch game to begin, or type !respawn if you are death!");
		}
		if(!IsPlayerAlive(client) && !IsClientObserver(client))
		{
			CreateTimer(GetConVarFloat(g_cvarDeathmatchRespawnTime), RespawnClient, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

BuildBoostMenu(client)
{
	decl String:buffer[256];
	new Handle:menu = CreateMenu(Menu_Boost);
	AddMenuItem(menu, "health", "Extra health");
	AddMenuItem(menu, "speed", "Extra Speed");
	AddMenuItem(menu, "insta", "Insta Melee Kills");
	AddMenuItem(menu, "medic", "Medic (Spawn with medkit)");
	AddMenuItem(menu, "upgrade", "Upgrade (Spawn with random upgrades)");
	AddMenuItem(menu, "damage", "Extra damage");
	AddMenuItem(menu, "vomit", "Vomit enemy on death");
	
	AddMenuItem(menu, "spitter", "Spawn spitter on death");
	AddMenuItem(menu, "nowait", "Instant Respawn");
	AddMenuItem(menu, "nofire", "Fire immunity");
	Format(buffer, sizeof(buffer), "Invisible on respawn (%i seconds)", GetConVarInt(g_cvarBSCalcStalkerTimeout));
	AddMenuItem(menu, "stalker", buffer);
	Format(buffer, sizeof(buffer), "God mode on respawn (%i seconds)", GetConVarInt(g_cvarBSCalcGodTimeout));
	AddMenuItem(menu, "immunity", buffer);
	AddMenuItem(menu, "noincap", "No incapacitation");
	AddMenuItem(menu, "fastcombat", "Fast combat on low health");
	//AddMenuItem(menu, "acidspit", "Acid Spit on death");
	//AddMenuItem(menu, "pipebomb", "Pipe Bomb on death");
	//AddMenuItem(menu, "nobile", "Vomit Shield (No vomit from enemy survivors)";
	//AddMenuItem(menu, "noinfected", "Common infected Shield (No damage from infected");
	//AddMenuItem(menu, "nofling", "Stun Protection (No stun from explosions)");
	//AddMenuItem(menu, "tornado", "Small Gift (Stun enemy players within your radius)");
	SetMenuTitle(menu, "Choose a boost");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Menu_Boost(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if(GetClientTeam(param1) == 3)
		{
			PrintToChat(param1, "\x04Sorry, you cannot use a boost if you are on infected team");
			return;
		}
		g_bExtraHealth[param1] = false;
		g_bExtraSpeed[param1] = false;
		g_bInstaMeleeKill[param1] = false;
		g_bMedic[param1] = false;
		g_bUpgrade[param1] = false;
		g_bExtraDmg[param1] = false;
		g_bVomitDeath[param1] = false;
		g_bSpitterDeath[param1] = false;
		g_bInstantRespawn[param1] = false;
		g_bNoFire[param1] = false;
		g_bStalker[param1] = false;
		g_bGodMode[param1] = false;
		g_bNoIncap[param1] = false;
		g_bFastCombat[param1] = false;
		switch(param2)
		{
			case 0:
			{
				if(!GetConVarBool(g_cvarBSAllowExtraHealth))
				{
					PrintToChat(param1, "\x03The selected boost is not available!");
					BuildSettingsMenu(param1);
					return;
				}
				g_bExtraHealth[param1] = true;
				SetEntityHealth(param1, GetClientHealth(param1)+GetConVarInt(g_cvarBSCalcHealth));
			}
			case 1:
			{
				if(!GetConVarBool(g_cvarBSAllowExtraSpeed))
				{
					PrintToChat(param1, "\x03The selected boost is not available!");
					BuildSettingsMenu(param1);
					return;
				}
				g_bExtraSpeed[param1] = true;
				new Float:total = FloatAdd(1.0, GetConVarFloat(g_cvarBSCalcSpeed));
				SetEntDataFloat(param1, g_flLagMovement, total, true);
			}
			case 2:
			{
				if(!GetConVarBool(g_cvarBSAllowInstaMeleeKills))
				{
					PrintToChat(param1, "\x03The selected boost is not available!");
					BuildSettingsMenu(param1);
					return;
				}
				g_bInstaMeleeKill[param1] = true;
			}
			case 3:
			{
				if(!GetConVarBool(g_cvarBSAllowMedic))
				{
					PrintToChat(param1, "\x03The selected boost is not available!");
					BuildSettingsMenu(param1);
					return;
				}
				g_bMedic[param1] = true;
			}
			case 4:
			{
				if(!GetConVarBool(g_cvarBSAllowUpgrade))
				{
					PrintToChat(param1, "\x03The selected boost is not available!");
					BuildSettingsMenu(param1);
					return;
				}
				g_bUpgrade[param1] = true;
			}
			case 5:
			{
				if(!GetConVarBool(g_cvarBSAllowExtraDamage))
				{
					PrintToChat(param1, "\x03The selected boost is not available!");
					BuildSettingsMenu(param1);
					return;
				}
				g_bExtraDmg[param1] = true;
			}
			case 6:
			{
				if(!GetConVarBool(g_cvarBSAllowVomit))
				{
					PrintToChat(param1, "\x03The selected boost is not available!");
					BuildSettingsMenu(param1);
					return;
				}
				g_bVomitDeath[param1] = true;
			}
			case 7:
			{
				if(!GetConVarBool(g_cvarBSAllowSpitter))
				{
					PrintToChat(param1, "\x03The selected boost is not available!");
					BuildSettingsMenu(param1);
					return;
				}
				g_bSpitterDeath[param1] = true;
			}
			case 8:
			{
				if(!GetConVarBool(g_cvarBSAllowInstaRespawn))
				{
					PrintToChat(param1, "\x03The selected boost is not available!");
					BuildSettingsMenu(param1);
					return;
				}
				g_bInstantRespawn[param1] = true;
			}
			case 9:
			{
				if(!GetConVarBool(g_cvarBSAllowFire))
				{
					PrintToChat(param1, "\x03The selected boost is not available!");
					BuildSettingsMenu(param1);
					return;
				}
				g_bNoFire[param1] = true;
			}
			case 10:
			{
				if(!GetConVarBool(g_cvarBSAllowStalker))
				{
					PrintToChat(param1, "\x03The selected boost is not available!");
					BuildSettingsMenu(param1);
					return;
				}
				g_bStalker[param1] = true;
			}
			case 11:
			{
				if(!GetConVarBool(g_cvarBSAllowGod))
				{
					PrintToChat(param1, "\x03The selected boost is not available!");
					BuildSettingsMenu(param1);
					return;
				}
				g_bGodMode[param1] = true;
			}
			case 12:
			{
				if(!GetConVarBool(g_cvarBSAllowNoIncap))
				{
					PrintToChat(param1, "\x03The selected boost is not available!");
					BuildSettingsMenu(param1);
					return;
				}
				g_bNoIncap[param1] = true;
			}
			case 13:
			{
				if(!GetConVarBool(g_cvarBSAllowFastCombat))
				{
					PrintToChat(param1, "\x03The selected boost is not available!");
					BuildSettingsMenu(param1);
					return;
				}
				g_bFastCombat[param1] = true;
			}
		}
		g_iFavBoost[param1] = param2;
		PrintToChat(param1, "\x03Access here trough the settings menu (!settings) to change your boost anytime");
		g_bChoosedBoost[param1] = true;
		BuildSettingsMenu(param1);
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:CmdReward(client, args)
{
	PrintToChat(client, "\x03You currently have \x04%i \x03points", points[client]);
	BuildRewardMenu(client);
}

BuildRewardMenu(client)
{
	new Handle:menu = CreateMenu(Menu_Reward);
	SetMenuExitBackButton(menu, true);
	decl String:buffer[256];
	Format(buffer, sizeof(buffer), "We have to fight THAT? [%i]", GetConVarInt(g_cvarRSTankCost));
	AddMenuItem(menu, "spawntank", buffer);
	
	Format(buffer, sizeof(buffer), "Here they come! [%i]", GetConVarInt(g_cvarRSPanicCost));
	AddMenuItem(menu, "spawnhorde", buffer);
	
	Format(buffer, sizeof(buffer), "Get down! [%i]", GetConVarInt(g_cvarRSBombCost));
	AddMenuItem(menu, "airbombs", buffer);
	
	Format(buffer, sizeof(buffer), "My ex-wife! [%i]", GetConVarInt(g_cvarRSWitchCost));
	AddMenuItem(menu, "witch", buffer);
	
	Format(buffer, sizeof(buffer), "Who rules now? [%i]", GetConVarInt(g_cvarRSLauncherCost));
	AddMenuItem(menu, "grenade", buffer);
	
	Format(buffer, sizeof(buffer), "Dont wear a white suit [%i]", GetConVarInt(g_cvarRSVomitCost));
	AddMenuItem(menu, "vomit", buffer);
	
	Format(buffer, sizeof(buffer), "Take it please [%i]", GetConVarInt(g_cvarRSGnomeCost));
	AddMenuItem(menu, "gnome", buffer);
	
	Format(buffer, sizeof(buffer), "I love pets [%i]", GetConVarInt(g_cvarRSPackCost));
	AddMenuItem(menu, "yaysi", buffer);
	
	Format(buffer, sizeof(buffer), "You have to fight ME! [60]");
	AddMenuItem(menu, "metank", buffer);
	
	SetMenuTitle(menu, "Choose a reward");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Menu_Scores(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
	
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

BuildScoreMenu(client)
{
	new Handle:menu = CreateMenu(Menu_Scores);
	new first, second, third, fourth, fifth, sixth, seventh, eight, nineth, ten, eleven, twelve, thirteen, fourteen, fifteen, sixteen, seventeen, eighteen, nineteen, twenty;
	
	for(new i=1; i<=MaxClients; i++)
	{
		
		if(IsValidEntity(i) && IsClientInGame(i))
		{
			if((GetClientTeam(i) == 2 || GetClientTeam(i) == 3) && !IsFakeClient(i))
			{
				if(first == 0 || score[i] > score[first])
				{
					twenty = nineteen;
					nineteen = eighteen;
					eighteen = seventeen;
					seventeen = sixteen;
					sixteen = fifteen;
					fifteen = fourteen;
					fourteen = thirteen;
					thirteen = twelve;
					twelve = eleven;
					eleven = ten;
					ten = nineth;
					nineth = eight;
					eight = seventh;
					seventh = sixth;
					sixth = fifth;
					fifth = fourth;
					fourth = third;
					third = second;
					second = first;
					first = i;
					continue;
				}
				if(second == 0 || score[i] > score[second])
				{
					twenty = nineteen;
					nineteen = eighteen;
					eighteen = seventeen;
					seventeen = sixteen;
					sixteen = fifteen;
					fifteen = fourteen;
					fourteen = thirteen;
					thirteen = twelve;
					twelve = eleven;
					eleven = ten;
					ten = nineth;
					nineth = eight;
					eight = seventh;
					seventh = sixth;
					sixth = fifth;
					fifth = fourth;
					fourth = third;
					third = second;
					second = i;
					continue;
				}
				if(third == 0 || score[i] > score[third])
				{
					twenty = nineteen;
					nineteen = eighteen;
					eighteen = seventeen;
					seventeen = sixteen;
					sixteen = fifteen;
					fifteen = fourteen;
					fourteen = thirteen;
					thirteen = twelve;
					twelve = eleven;
					eleven = ten;
					ten = nineth;
					nineth = eight;
					eight = seventh;
					seventh = sixth;
					sixth = fifth;
					fifth = fourth;
					fourth = third;
					third = i;
					continue;
				}
				if(fourth == 0 || score[i] > score[fourth])
				{
					twenty = nineteen;
					nineteen = eighteen;
					eighteen = seventeen;
					seventeen = sixteen;
					sixteen = fifteen;
					fifteen = fourteen;
					fourteen = thirteen;
					thirteen = twelve;
					twelve = eleven;
					eleven = ten;
					ten = nineth;
					nineth = eight;
					eight = seventh;
					seventh = sixth;
					sixth = fifth;
					fifth = fourth;
					fourth = i;
					continue;
				}
				if(fifth == 0 || score[i] > score[fifth])
				{
					twenty = nineteen;
					nineteen = eighteen;
					eighteen = seventeen;
					seventeen = sixteen;
					sixteen = fifteen;
					fifteen = fourteen;
					fourteen = thirteen;
					thirteen = twelve;
					twelve = eleven;
					eleven = ten;
					ten = nineth;
					nineth = eight;
					eight = seventh;
					seventh = sixth;
					sixth = fifth;
					fifth = i;
					continue;
				}
				if(sixth == 0 || score[i] > score[sixth])
				{
					twenty = nineteen;
					nineteen = eighteen;
					eighteen = seventeen;
					seventeen = sixteen;
					sixteen = fifteen;
					fifteen = fourteen;
					fourteen = thirteen;
					thirteen = twelve;
					twelve = eleven;
					eleven = ten;
					ten = nineth;
					nineth = eight;
					eight = seventh;
					seventh = sixth;
					sixth = i;
					continue;
				}
				if(seventh == 0 || score[i] > score[seventh])
				{
					twenty = nineteen;
					nineteen = eighteen;
					eighteen = seventeen;
					seventeen = sixteen;
					sixteen = fifteen;
					fifteen = fourteen;
					fourteen = thirteen;
					thirteen = twelve;
					twelve = eleven;
					eleven = ten;
					ten = nineth;
					nineth = eight;
					eight = seventh;
					seventh = i;
					continue;
				}
				if(eight == 0 || score[i] > score[eight])
				{
					twenty = nineteen;
					nineteen = eighteen;
					eighteen = seventeen;
					seventeen = sixteen;
					sixteen = fifteen;
					fifteen = fourteen;
					fourteen = thirteen;
					thirteen = twelve;
					twelve = eleven;
					eleven = ten;
					ten = nineth;
					nineth = eight;
					eight = i;
					continue;
				}
				if(nineth == 0 || score[i] > score[nineth])
				{
					twenty = nineteen;
					nineteen = eighteen;
					eighteen = seventeen;
					seventeen = sixteen;
					sixteen = fifteen;
					fifteen = fourteen;
					fourteen = thirteen;
					thirteen = twelve;
					twelve = eleven;
					eleven = ten;
					ten = nineth;
					nineth = i;
					continue;
				}
				if(ten == 0 || score[i] > score[ten])
				{
					twenty = nineteen;
					nineteen = eighteen;
					eighteen = seventeen;
					seventeen = sixteen;
					sixteen = fifteen;
					fifteen = fourteen;
					fourteen = thirteen;
					thirteen = twelve;
					twelve = eleven;
					eleven = ten;
					ten = i;
					continue;
				}
				if(eleven == 0 || score[i] > score[eleven])
				{
					twenty = nineteen;
					nineteen = eighteen;
					eighteen = seventeen;
					seventeen = sixteen;
					sixteen = fifteen;
					fifteen = fourteen;
					fourteen = thirteen;
					thirteen = twelve;
					twelve = eleven;
					eleven = i;
					continue;
				}
				if(twelve == 0 || score[i] > score[twelve])
				{
					twenty = nineteen;
					nineteen = eighteen;
					eighteen = seventeen;
					seventeen = sixteen;
					sixteen = fifteen;
					fifteen = fourteen;
					fourteen = thirteen;
					thirteen = twelve;
					twelve = i;
					continue;
				}
				if(thirteen == 0 || score[i] > score[thirteen])
				{
					twenty = nineteen;
					nineteen = eighteen;
					eighteen = seventeen;
					seventeen = sixteen;
					sixteen = fifteen;
					fifteen = fourteen;
					fourteen = thirteen;
					thirteen = i;
					continue;
				}
				if(fourteen == 0 || score[i] > score[fourteen])
				{
					twenty = nineteen;
					nineteen = eighteen;
					eighteen = seventeen;
					seventeen = sixteen;
					sixteen = fifteen;
					fifteen = fourteen;
					fourteen = i;
					continue;
				}
				if(fifteen == 0 || score[i] > score[fifteen])
				{
					twenty = nineteen;
					nineteen = eighteen;
					eighteen = seventeen;
					seventeen = sixteen;
					sixteen = fifteen;
					fifteen = i;
					continue;
				}
				if(sixteen == 0 || score[i] > score[sixteen])
				{
					twenty = nineteen;
					nineteen = eighteen;
					eighteen = seventeen;
					seventeen = sixteen;
					sixteen = i;
					continue;
				}
				if(seventeen == 0 || score[i] > score[seventeen])
				{
					twenty = nineteen;
					nineteen = eighteen;
					eighteen = seventeen;
					seventeen = i;
					continue;
				}
				if(eighteen == 0 || score[i] > score[eighteen])
				{
					twenty = nineteen;
					nineteen = eighteen;
					eighteen = i;
					continue;
				}
				if(nineteen == 0 || score[i] > score[nineteen])
				{
					twenty = nineteen;
					nineteen = i;
					continue;
				}
				if(twenty == 0 || score[i] > score[twenty])
				{
					twenty = i;
					continue;
				}
			}
		}
	}
	decl String:name[256], String:content[256];
	if(first != 0)
	{
		GetClientName(first, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[first], name);
		AddMenuItem(menu, "first", content);
	}
	if(second != 0)
	{
		GetClientName(second, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[second], name);
		AddMenuItem(menu, "second", content);
	}
	if(third != 0)
	{
		GetClientName(third, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[third], name);
		AddMenuItem(menu, "third", content);
	}
	if(fourth != 0)
	{
		GetClientName(fourth, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[fourth], name);
		AddMenuItem(menu, "fourth", content);
	}
	if(fifth != 0)
	{
		GetClientName(fifth, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[fifth], name);
		AddMenuItem(menu, "fifth", content);
	}
	if(sixth != 0)
	{
		GetClientName(sixth, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[sixth], name);
		AddMenuItem(menu, "sixth", content);
	}
	if(seventh != 0)
	{
		GetClientName(seventh, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[seventh], name);
		AddMenuItem(menu, "seventh", content);
	}
	if(eight != 0)
	{
		GetClientName(eight, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[eight], name);
		AddMenuItem(menu, "eight", content);
	}
	if(nineth != 0)
	{
		GetClientName(nineth, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[nineth], name);
		AddMenuItem(menu, "nineth", content);
	}
	if(ten != 0)
	{
		GetClientName(ten, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[ten], name);
		AddMenuItem(menu, "ten", content);
	}
	if(eleven != 0)
	{
		GetClientName(eleven, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[eleven], name);
		AddMenuItem(menu, "eleven", content);
	}
	if(twelve != 0)
	{
		GetClientName(twelve, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[twelve], name);
		AddMenuItem(menu, "twelve", content);
	}
	if(thirteen != 0)
	{
		GetClientName(thirteen, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[thirteen], name);
		AddMenuItem(menu, "thirteen", content);
	}
	if(fourteen != 0)
	{
		GetClientName(fourteen, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[fourteen], name);
		AddMenuItem(menu, "fourteen", content);
	}
	if(fifteen != 0)
	{
		GetClientName(fifteen, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[fifteen], name);
		AddMenuItem(menu, "fifteen", content);
	}
	if(sixteen != 0)
	{
		GetClientName(sixteen, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[sixteen], name);
		AddMenuItem(menu, "sixteen", content);
	}
	if(seventeen != 0)
	{
		GetClientName(seventeen, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[seventeen], name);
		AddMenuItem(menu, "seventeen", content);
	}
	if(eighteen != 0)
	{
		GetClientName(eighteen, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[eighteen], name);
		AddMenuItem(menu, "eighteen", content);
	}
	if(nineteen != 0)
	{
		GetClientName(nineteen, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[nineteen], name);
		AddMenuItem(menu, "nineteen", content);
	}
	if(twenty != 0)
	{
		GetClientName(twenty, name, sizeof(name));
		Format(content, sizeof(content), "%i -- %s", score[twenty], name);
		AddMenuItem(menu, "twenty", content);
	}
	g_iWinner = first;
	SetMenuTitle(menu, "Scores");
	DisplayMenu(menu, client, 15);
}

public Menu_Reward(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			SpawnFriendlyTank(param1);
			case 1:
			SpawnHorde(param1);
			case 2:
			PutBombs(param1);
			case 3:
			SpawnWitch(param1);
			case 4:
			GiveLauncher(param1);
			case 5:
			VomitAll(param1);
			case 6:
			BombGnome(param1);
			case 7:
			SpecialParty(param1);
			case 8:
			BecomeTank(param1);
		}
		BuildRewardMenu(param1);
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public Action:SpecialParty(client)
{
	if(points[client] == 0)
	{
		PrintToChat(client, "\x04You don't have any reward points!");
		return;
	}
	new price = GetConVarInt(g_cvarRSPackCost);
	if(points[client] < price)
	{
		PrintToChat(client, "\x04You need %i points for this and you have %i", price, points[client]);
		return;
	}
	if(!g_bPetCaller[client])
	{
		decl String:name[256];
		g_bPetCaller[client] = true;
		GetClientName(client, name, sizeof(name));
		decl String:content[512];
		Format(content, sizeof(content), "\x05%s \x01earned the \x05PET SUMMONER \x01 achievement by calling his infected pets!", name);
		PrintToChatAllDM(content);
		UpdatePlayerAchievement(client);
	}
	#if DEBUG
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogMessage("[REWARD MANAGER] Special Party Reward called by %s (ID: %i)", name, client);
	PrintToServer("[REWARD MANAGER] Special Party Reward called by %s (ID: %i)", name, client);
	#endif
	
	g_bHunterQueue[client] = true;
	g_bChargerQueue[client] = true;
	g_bJockeyQueue[client] = true;
	g_bSmokerQueue[client] = true;
	g_bSpitterQueue[client] = true;
	g_bBoomerQueue[client] = true;
	CheatCommand(client, "z_spawn", "hunter auto");
	CheatCommand(client, "z_spawn", "charger auto");
	CheatCommand(client, "z_spawn", "jockey auto");
	CheatCommand(client, "z_spawn", "smoker auto");
	CheatCommand(client, "z_spawn", "spitter auto");
	CheatCommand(client, "z_spawn", "boomer auto");
	points[client] -= price;
	trewardused[client]++;
}

public Action:BombGnome(client)
{
	if(points[client] == 0)
	{
		PrintToChat(client, "\x04You don't have any reward points!");
		return;
	}
	new price = GetConVarInt(g_cvarRSGnomeCost);
	if(points[client] < price)
	{
		PrintToChat(client, "\x04You need %i points for this and you have %i", price, points[client]);
		return;
	}
	#if DEBUG
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogMessage("[REWARD MANAGER] BombGnome Reward called by %s (ID: %i)", name, client);
	PrintToServer("[REWARD MANAGER] BombGnome Reward called by %s (ID: %i)", name, client);
	#endif
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	new gnome = CreateEntityByName("weapon_gnome");
	DispatchSpawn(gnome);
	TeleportEntity(gnome, pos, NULL_VECTOR, NULL_VECTOR);
	PrintToChat(client, "\x03Do not pick up the gnome! It is a bomb!");
	points[client] -= price;
	trewardused[client]++;
}

public Action:VomitAll(client)
{
	if(points[client] == 0)
	{
		PrintToChat(client, "\x04You don't have any reward points!");
		return;
	}
	new price = GetConVarInt(g_cvarRSVomitCost);
	if(points[client] < price)
	{
		PrintToChat(client, "\x04You need %i points for this and you have %i", price, points[client]);
		return;
	}
	#if DEBUG
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogMessage("[REWARD MANAGER] VomitAll Reward called by %s (ID: %i)", name, client);
	PrintToServer("[REWARD MANAGER] VomitAll Reward called by %s (ID: %i)", name, client);
	#endif
	for(new i=1; i<=MaxClients; i++)
	{
		if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && i != client)
		{
			if(GetClientTeam(i) == 3)
			{
				SDKCall(sdkCallVomitPlayer, i, i, true);
			}
			if(GetClientTeam(i) == 2)
			{
				SDKCall(sdkCallVomitOnPlayer, i, i, true);
			}
		}
	}
	points[client] -= price;
	trewardused[client]++;
	g_iPanicIndex++;
	g_bPanicProgress = true;
	CreateTimer(20.0, timerPanicTimeout, g_iPanicIndex, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:timerPanicTimeout(Handle:timer, any:index)
{
	if(g_iPanicIndex != index)
	{
		return;
	}
	g_bPanicProgress = false;
}

public Action:GiveLauncher(client)
{
	if(points[client] == 0)
	{
		PrintToChat(client, "\x04You don't have any reward points!");
		return;
	}
	new price = GetConVarInt(g_cvarRSLauncherCost);
	if(points[client] < price)
	{
		PrintToChat(client, "\x04You need %i points for this and you have %i", price, points[client]);
		return;
	}
	#if DEBUG
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogMessage("[REWARD MANAGER] GiveLauncher Reward called by %s (ID: %i)", name, client);
	PrintToServer("[REWARD MANAGER] GiveLauncher Reward called by %s (ID: %i)", name, client);
	#endif
	CheatCommand(client, "give", "grenade_launcher");
	points[client] -= price;
	trewardused[client]++;
}

public Action:SpawnWitch(client)
{
	if(points[client] == 0)
	{
		PrintToChat(client, "\x04You don't have any reward points!");
		return;
	}
	new price = GetConVarInt(g_cvarRSWitchCost);
	if(points[client] < price)
	{
		PrintToChat(client, "\x04You need %i points for this and you have %i", price, points[client]);
		return;
	}
	#if DEBUG
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogMessage("[REWARD MANAGER]  SpawnWitch Reward called by %s (ID: %i)", name, client);
	PrintToServer("[REWARD MANAGER] SpawnWitch Reward called by %s (ID: %i)", name, client);
	#endif
	g_bWitchQueue[client] = true;
	CheatCommand(client, "z_spawn", "witch");
	points[client] -= price;
	trewardused[client]++;
}

public Action:SpawnFriendlyTank(client)
{
	if(points[client] == 0)
	{
		PrintToChat(client, "\x04You don't have any reward points!");
		return;
	}
	new price = GetConVarInt(g_cvarRSTankCost);
	if(points[client] < price)
	{
		PrintToChat(client, "\x04You need %i points for this and you have %i", price, points[client]);
		return;
	}
	#if DEBUG
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogMessage("[REWARD MANAGER] SpawnFriendlyTank Reward called by %s (ID: %i)", name, client);
	PrintToServer("[REWARD MANAGER] SpawnFriendlyTank Reward called by %s (ID: %i)", name, client);
	#endif
	g_bTankQueue[client] = true;
	CheatCommand(client, "z_spawn", "tank");
	points[client] -= price;
	trewardused[client]++;
}

public Action:BecomeTank(client)
{
	PrintToChat(client, "\x04This feature is not available yet, sorry.");
	return;
	if(points[client] == 0)
	{
		PrintToChat(client, "\x04You don't have any reward points!");
		return;
	}
	new price = 60;
	if(points[client] < price)
	{
		PrintToChat(client, "\x04You need %i points for this and you have %i", price, points[client]);
		return;
	}
	#if DEBUG
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogMessage("[REWARD MANAGER] BecomeTank Reward called by %s (ID: %i)", name, client);
	PrintToServer("[REWARD MANAGER] BecomeTank Reward called by %s (ID: %i)", name, client);
	#endif
	points[client] -= price;
	trewardused[client]++;
	ChangeClientTeam(client, 3);
	CheatCommand(client, "z_spawn", "tank");
}

public Action:SpawnHorde(client)
{
	if(points[client] == 0)
	{
		PrintToChat(client, "\x04You don't have any reward points!");
		return;
	}
	new price = GetConVarInt(g_cvarRSPanicCost);
	if(points[client] < price)
	{
		PrintToChat(client, "\x04You need %i points for this and you have %i", price, points[client]);
		return;
	}
	#if DEBUG
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogMessage("[REWARD MANAGER] SpawnHorde Reward called by %s (ID: %i)", name, client);
	PrintToServer("[REWARD MANAGER] SpawnHorde Reward called by %s (ID: %i)", name, client);
	#endif
	if(IsValidEntity(g_iDirector))
	{
		AcceptEntityInput(g_iDirector, "ForcePanicEvent");
	}
	points[client] -= price;
	trewardused[client]++;
	g_iPanicIndex++;
	g_bPanicProgress = true;
	CreateTimer(28.0, timerPanicTimeout, g_iPanicIndex, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:PutBombs(client)
{
	if(points[client] == 0)
	{
		PrintToChat(client, "\x04You don't have any reward points!");
		return;
	}
	new price = GetConVarInt(g_cvarRSBombCost);
	if(points[client] < price)
	{
		PrintToChat(client, "\x04You need %i points for this and you have %i", price, points[client]);
		return;
	}
	#if DEBUG
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	LogMessage("[REWARD MANAGER] PutBombs Reward called by %s (ID: %i)", name, client);
	PrintToServer("[REWARD MANAGER] PutBombs Reward called by %s (ID: %i)", name, client);
	#endif
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	PrintToChat(client, "\x04The bomb will explode in 5 seconds, get out!");
	new Handle:pack = CreateDataPack();
	WritePackFloat(pack, pos[0]);
	WritePackFloat(pack, pos[1]);
	WritePackFloat(pack, pos[2]);
	CreateTimer(5.0, ShowExplosion, pack, TIMER_FLAG_NO_MAPCHANGE);
	points[client] -= price;
	trewardused[client]++;
}

public Action:ShowExplosion(Handle:timer, Handle:pack)
{
	decl Float:pos[3];
	ResetPack(pack);
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);
	CreateExplosion(pos);
}

CreateExplosion(Float:pos[3])
{
	decl String:sRadius[256];
	decl String:sPower[256];
	new Float:flMxDistance = GetConVarFloat(g_cvarDeathmatchExplosionRadius);
	new Float:power = GetConVarFloat(g_cvarDeathmatchExplosionPower);
	IntToString(250, sRadius, sizeof(sRadius));
	IntToString(350, sPower, sizeof(sPower));
	new exParticle2 = CreateEntityByName("info_particle_system");
	new exParticle3 = CreateEntityByName("info_particle_system");
	new exTrace = CreateEntityByName("info_particle_system");
	new exPhys = CreateEntityByName("env_physexplosion");
	new exHurt = CreateEntityByName("point_hurt");
	new exParticle = CreateEntityByName("info_particle_system");
	new exEntity = CreateEntityByName("env_explosion");
	/*new exPush = CreateEntityByName("point_push");*/
	
	//Set up the particle explosion
	DispatchKeyValue(exParticle, "effect_name", EXPLOSION_PARTICLE);
	DispatchSpawn(exParticle);
	ActivateEntity(exParticle);
	TeleportEntity(exParticle, pos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(exParticle2, "effect_name", EXPLOSION_PARTICLE2);
	DispatchSpawn(exParticle2);
	ActivateEntity(exParticle2);
	TeleportEntity(exParticle2, pos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(exParticle3, "effect_name", EXPLOSION_PARTICLE3);
	DispatchSpawn(exParticle3);
	ActivateEntity(exParticle3);
	TeleportEntity(exParticle3, pos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(exTrace, "effect_name", FIRE_PARTICLE);
	DispatchSpawn(exTrace);
	ActivateEntity(exTrace);
	TeleportEntity(exTrace, pos, NULL_VECTOR, NULL_VECTOR);
	
	
	//Set up explosion entity
	DispatchKeyValue(exEntity, "fireballsprite", "sprites/muzzleflash4.vmt");
	DispatchKeyValue(exEntity, "iMagnitude", sPower);
	DispatchKeyValue(exEntity, "iRadiusOverride", sRadius);
	DispatchKeyValue(exEntity, "spawnflags", "828");
	DispatchSpawn(exEntity);
	TeleportEntity(exEntity, pos, NULL_VECTOR, NULL_VECTOR);
	
	//Set up physics movement explosion
	DispatchKeyValue(exPhys, "radius", sRadius);
	DispatchKeyValue(exPhys, "magnitude", sPower);
	DispatchSpawn(exPhys);
	TeleportEntity(exPhys, pos, NULL_VECTOR, NULL_VECTOR);
	
	
	//Set up hurt point
	DispatchKeyValue(exHurt, "DamageRadius", sRadius);
	DispatchKeyValue(exHurt, "DamageDelay", "0.1");
	DispatchKeyValue(exHurt, "Damage", "1");
	DispatchKeyValue(exHurt, "DamageType", "8");
	DispatchSpawn(exHurt);
	TeleportEntity(exHurt, pos, NULL_VECTOR, NULL_VECTOR);
	
	switch(GetRandomInt(1,3))
	{
		case 1:
		{
			EmitSoundToAll(EXPLOSION_SOUND);
		}
		case 2:
		{
			EmitSoundToAll(EXPLOSION_SOUND2);
		}
		case 3:
		{
			EmitSoundToAll(EXPLOSION_SOUND3);
		}
	}
	
	//BOOM!
	AcceptEntityInput(exParticle, "Start");
	AcceptEntityInput(exParticle2, "Start");
	AcceptEntityInput(exParticle3, "Start");
	AcceptEntityInput(exTrace, "Start");
	AcceptEntityInput(exEntity, "Explode");
	AcceptEntityInput(exPhys, "Explode");
	AcceptEntityInput(exHurt, "TurnOn");
	
	new Handle:pack2 = CreateDataPack();
	WritePackCell(pack2, exParticle);
	WritePackCell(pack2, exParticle2);
	WritePackCell(pack2, exParticle3);
	WritePackCell(pack2, exTrace);
	WritePackCell(pack2, exEntity);
	WritePackCell(pack2, exPhys);
	WritePackCell(pack2, exHurt);
	CreateTimer(18.0, timerDeleteParticles, pack2, TIMER_FLAG_NO_MAPCHANGE);
	
	
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, exTrace);
	WritePackCell(pack, exHurt);
	CreateTimer(GetConVarFloat(g_cvarDeathmatchExplosionTrace), timerStopFire, pack, TIMER_FLAG_NO_MAPCHANGE);
	decl Float:distance[3], Float:tpos[3], Float:ratio[3], Float:addVel[3], Float:tvec[3];
	for(new i=1; i<=MaxClients; i++)
	{
		if(i == 0 || !IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i))
		{
			continue;
		}
		if(GetClientTeam(i) != 2)
		{
			continue;
		}
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", tpos);
		distance[0] = (pos[0] - tpos[0]);
		distance[1] = (pos[1] - tpos[1]);
		distance[2] = (pos[2] - tpos[2]);
		
		new Float:realdistance = SquareRoot(FloatMul(distance[0],distance[0])+FloatMul(distance[1],distance[1]));
		if(realdistance <= flMxDistance)
		{			
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", tvec);
			
			addVel[0] = FloatMul(ratio[0]*-1, power);
			addVel[1] = FloatMul(ratio[1]*-1, power);
			addVel[2] = power;
			FlingPlayer(i, addVel, i);
		}
	}
}

public Action:timerStopFire(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new particle = ReadPackCell(pack);
	new hurt = ReadPackCell(pack);
	if(IsValidEntity(particle))
	{
		AcceptEntityInput(particle, "Stop");
	}
	if(IsValidEntity(hurt))
	{
		AcceptEntityInput(hurt, "TurnOff");
	}
}

public Action:timerDeleteParticles(Handle:timer, Handle:pack)
{
	if(!g_bGameRunning)
	{
		return;
	}
	ResetPack(pack);
	new entity1 = ReadPackCell(pack);
	new entity2 = ReadPackCell(pack);
	new entity3 = ReadPackCell(pack);
	new entity4 = ReadPackCell(pack);
	new entity5 = ReadPackCell(pack);
	new entity6 = ReadPackCell(pack);
	new entity7 = ReadPackCell(pack);
	if(IsValidEntity(entity1))
	{
		AcceptEntityInput(entity1, "Kill");
	}
	if(IsValidEntity(entity2))
	{
		AcceptEntityInput(entity2, "Kill");
	}
	if(IsValidEntity(entity3))
	{
		AcceptEntityInput(entity3, "Kill");
	}
	if(IsValidEntity(entity4))
	{
		AcceptEntityInput(entity4, "Kill");
	}
	if(IsValidEntity(entity5))
	{
		AcceptEntityInput(entity5, "Kill");
	}
	if(IsValidEntity(entity6))
	{
		AcceptEntityInput(entity6, "Kill");
	}
	if(IsValidEntity(entity7))
	{
		AcceptEntityInput(entity7, "Kill");
	}
}

stock FlingPlayer(target, Float:vector[3], attacker, Float:stunTime = 3.0)
{
	SDKCall(sdkCallPushPlayer, target, vector, 96, attacker, stunTime);
}

public Action:KillExp(Handle:timer, Handle:pack)
{
	if(!g_bGameRunning)
	{
		return;
	}
	ResetPack(pack);
	new ex_entity = ReadPackCell(pack);
	new ht_entity = ReadPackCell(pack);
	CloseHandle(pack);
	if(IsValidEntity(ex_entity))
	{
		AcceptEntityInput(ex_entity, "Kill");
	}
	if(IsValidEntity(ht_entity))
	{
		AcceptEntityInput(ht_entity, "Kill");
	}
}

public Event_BulletImpact(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && IsValidEntity(client) && IsClientInGame(client))
	{
		decl String:name[256];
		GetClientName(client, name, sizeof(name));
		last_bullet_hit[client][0] = GetEventFloat(event, "x");
		last_bullet_hit[client][1] = GetEventFloat(event, "y");
		last_bullet_hit[client][2] = GetEventFloat(event, "z");
	}
}

public Event_PlayerHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	decl String:weapon[256];
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage = GetEventInt(event, "dmg_health");
	new damagetype = GetEventInt(event, "type");
	
	if(victim > 0
	&& IsValidEntity(victim)
	&& IsClientInGame(victim)
	&& IsPlayerAlive(victim)
	&& GetClientTeam(victim) == 2)
	{
		if(attacker != victim)
		{
			g_iLastAttacker[victim] = attacker;
		}
		g_iShotsReceived[victim]++;
		
		if(hRespawnClientFalse[victim] != INVALID_HANDLE)
		{
			KillTimer(hRespawnClientFalse[victim]);
			hRespawnClientFalse[victim] = INVALID_HANDLE;
			PrintToChat(victim, "\x03Reallocate canceled. You received damage");
		}
		
		if(g_bNoFire[victim] && (damagetype == 8 || damagetype == 2056))
		{
			SetEntityHealth(victim, GetClientHealth(victim)+damage);
			return;
		}
		
		if(attacker > 0
		&& IsValidEntity(attacker)
		&& IsClientInGame(attacker)
		&& IsPlayerAlive(attacker)
		&& GetClientTeam(attacker) == 2)
		{
			new bool:headshot = IsHeadshot(victim, attacker);
			new bool:FileFound = false;
			new Handle:keyvalues = INVALID_HANDLE;
			decl String:KvFileName[256];
			
			BuildPath(Path_SM, KvFileName, sizeof(KvFileName), "data/deathmatch/l4d2_deathmatch_weapons.txt");
			
			if(!FileExists(KvFileName))
			{
				LogMessage("[WARNING] Unable to find the l4d2_deathmatch_weapons.txt file, the weapons damage won't be affected");
				FileFound = false;
			}
			else
			{
				FileFound = true;
			}
			
			if(FileFound)
			{
				keyvalues = CreateKeyValues("l4d2_deathmatch_weapons");
				FileToKeyValues(keyvalues, KvFileName);
				KvRewind(keyvalues);
				
				GetClientWeapon(attacker, weapon, sizeof(weapon));
				if(StrEqual(weapon, "weapon_melee"))
				{
					if(g_bInstaMeleeKill[attacker])
					{
						ForcePlayerSuicide(victim);
						kills[attacker]++;
						tkills[attacker]++;
						deaths[victim]++;
						tdeaths[victim]++;
						if(!IsFakeClient(victim))
						{
							score[attacker]+= GetConVarInt(g_cvarSSPointsHumanKill);
							tscore[attacker]+= GetConVarInt(g_cvarSSPointsHumanKill);
							points[attacker] += GetConVarInt(g_cvarRSPointsHumanKill);
						}
						else
						{
							score[attacker]+= GetConVarInt(g_cvarSSPointsBotKill);
							tscore[attacker]+= GetConVarInt(g_cvarSSPointsBotKill);
							points[attacker] += GetConVarInt(g_cvarRSPointsBotKill);
						}
					}
					else
					{
						decl String:action[256], Float:multiplier, Float:extra_multiplier;
						new action_chance, thealth, ndamage, fhealth, adamage;
						if(KvJumpToKey(keyvalues, "melee"))
						{
							if(headshot)
							{
								multiplier = KvGetFloat(keyvalues, "headshot multiplier", 1.0);
							}
							else
							{
								multiplier = KvGetFloat(keyvalues, "common multiplier", 1.0);
							}
							KvGetString(keyvalues, "special feature", action, sizeof(action), "none");
							action_chance = KvGetNum(keyvalues, "special feature chance", 1);
							
							thealth = (GetClientHealth(victim)+damage);
							ndamage = RoundToFloor(damage*multiplier);
							fhealth = thealth-ndamage;
							if(g_bExtraDmg[attacker])
							{
								extra_multiplier = KvGetFloat(keyvalues, "extra damage additional", 0.0);
								adamage = RoundToFloor(damage*extra_multiplier);
								fhealth-=adamage;
							}
							
							if(!StrEqual(action, "none"))
							{
								switch(GetRandomInt(action_chance, 100))
								{
									case 100:
									{
										if(StrEqual(action, "incap") && victim != attacker && !g_bNoIncap[victim] && GetEntProp(victim, Prop_Send, "m_isIncapacitated") != 1)
										{
											SetEntProp(victim, Prop_Send, "m_isIncapacitated", 1);
											decl String:vname[256], String:aname[256];
											GetClientName(attacker, aname, sizeof(aname));
											GetClientName(victim, vname, sizeof(vname));
											decl String:content[512];
											Format(content, sizeof(content), "\x05%s \x01incapacitated \x05%s \x01 !", aname, vname);
											PrintToChatAllDM(content);
											score[attacker]+=GetConVarInt(g_cvarSSPointsGrenadeBlast);
											tscore[attacker]+=GetConVarInt(g_cvarSSPointsGrenadeBlast);
											new rewardpts = GetConVarInt(g_cvarRSPointsGrenadeBlast);
											if(rewardpts  > 0)
											{
												if(notify[attacker])
												{
													PrintToChat(attacker, "\x04You received %i points for incapacitating a survivor!", rewardpts);
												}
												points[attacker]+=rewardpts;
												BuildRewardMenu(attacker);
											}
											if(!g_bIncapDealer[attacker])
											{
												decl String:name[256];
												g_bIncapDealer[attacker] = true;
												GetClientName(attacker, name, sizeof(name));				
												Format(content, sizeof(content), "\x05%s \x01earned the \x05INCAP DEALER \x01achievement by leaving incapacitated an enemy survivor!", name);
												PrintToChatAllDM(content);
												UpdatePlayerAchievement(attacker);
											}
										}
										else if(StrEqual(action, "vomit"))
										{
											SDKCall(sdkCallVomitOnPlayer, victim, attacker, true);
										}
										else if(StrEqual(action, "explosion"))
										{
											decl Float:pos[3];
											GetClientAbsOrigin(victim, pos);
											CreateExplosion(pos);
										}
									}
								}
							}
							
							if(fhealth <= 0)
							{
								ForcePlayerSuicide(victim);
								kills[attacker]++;
								tkills[attacker]++;
								deaths[victim]++;
								tdeaths[victim]++;
								if(!IsFakeClient(victim))
								{
									score[attacker]+= GetConVarInt(g_cvarSSPointsHumanKill);
									tscore[attacker]+= GetConVarInt(g_cvarSSPointsHumanKill);
									points[attacker] += GetConVarInt(g_cvarRSPointsHumanKill);
								}
								else
								{
									score[attacker]+= GetConVarInt(g_cvarSSPointsBotKill);
									tscore[attacker]+= GetConVarInt(g_cvarSSPointsBotKill);
									points[attacker] += GetConVarInt(g_cvarRSPointsBotKill);
								}
							}
							else
							{
								SetEntityHealth(victim, fhealth);
							}
							CloseHandle(keyvalues);
							return;
						}
						else
						{
						}
					}
				}
				else
				{
					decl String:action[256], Float:multiplier, Float:extra_multiplier;
					new action_chance, thealth, ndamage, fhealth, adamage;
					GetEventString(event, "weapon", weapon, sizeof(weapon));
					
					if(StrEqual(weapon, "grenade_launcher_projectile"))
					{
						Format(weapon, sizeof(weapon), "grenade_launcher");
					}
					else if(StrEqual(weapon, "dual_pistols"))
					{
						Format(weapon, sizeof(weapon), "pistol");
					}
					if(KvJumpToKey(keyvalues, weapon))
					{
						
						if(headshot)
						{
							multiplier = KvGetFloat(keyvalues, "headshot multiplier", 1.0);
						}
						else
						{
							multiplier = KvGetFloat(keyvalues, "common multiplier", 1.0);
						}
						KvGetString(keyvalues, "special feature", action, sizeof(action), "none");
						action_chance = KvGetNum(keyvalues, "special feature chance", 1);
						
						thealth = (GetClientHealth(victim)+damage);
						ndamage = RoundToFloor(damage*multiplier);
						fhealth = thealth-ndamage;
						if(g_bExtraDmg[attacker])
						{
							extra_multiplier = KvGetFloat(keyvalues, "extra damage additional", 0.0);
							adamage = RoundToFloor(damage*extra_multiplier);
							fhealth-=adamage;
						}
						
						if(!StrEqual(action, "none"))
							{
								switch(GetRandomInt(action_chance, 100))
								{
									case 100:
									{
										if(StrEqual(action, "incap") && victim != attacker && !g_bNoIncap[victim] && GetEntProp(victim, Prop_Send, "m_isIncapacitated") != 1)
										{
											SetEntProp(victim, Prop_Send, "m_isIncapacitated", 1);
											decl String:vname[256], String:aname[256];
											GetClientName(attacker, aname, sizeof(aname));
											GetClientName(victim, vname, sizeof(vname));
											decl String:content[512];
											Format(content, sizeof(content), "\x05%s \x01incapacitated \x05%s \x01 !", aname, vname);
											PrintToChatAllDM(content);
											score[attacker]+=GetConVarInt(g_cvarSSPointsGrenadeBlast);
											tscore[attacker]+=GetConVarInt(g_cvarSSPointsGrenadeBlast);
											new rewardpts = GetConVarInt(g_cvarRSPointsGrenadeBlast);
											if(rewardpts  > 0)
											{
												if(notify[attacker])
												{
													PrintToChat(attacker, "\x04You received %i points for incapacitating a survivor!", rewardpts);
												}
												points[attacker]+=rewardpts;
												BuildRewardMenu(attacker);
											}
											if(!g_bIncapDealer[attacker])
											{
												decl String:name[256];
												g_bIncapDealer[attacker] = true;
												GetClientName(attacker, name, sizeof(name));				
												Format(content, sizeof(content), "\x05%s \x01earned the \x05INCAP DEALER \x01achievement by leaving incapacitated an enemy survivor!", name);
												PrintToChatAllDM(content);
												UpdatePlayerAchievement(attacker);
											}
										}
										else if(StrEqual(action, "vomit"))
										{
											SDKCall(sdkCallVomitOnPlayer, victim, attacker, true);
										}
										else if(StrEqual(action, "explosion"))
										{
											decl Float:pos[3];
											GetClientAbsOrigin(victim, pos);
											CreateExplosion(pos);
										}
									}
								}
							}
						
						if(fhealth <= 0)
						{
							ForcePlayerSuicide(victim);
							kills[attacker]++;
							tkills[attacker]++;
							deaths[victim]++;
							tdeaths[victim]++;
							if(!IsFakeClient(victim))
							{
								score[attacker]+= GetConVarInt(g_cvarSSPointsHumanKill);
								tscore[attacker]+= GetConVarInt(g_cvarSSPointsHumanKill);
								points[attacker] += GetConVarInt(g_cvarRSPointsHumanKill);
							}
							else
							{
								score[attacker]+= GetConVarInt(g_cvarSSPointsBotKill);
								tscore[attacker]+= GetConVarInt(g_cvarSSPointsBotKill);
								points[attacker] += GetConVarInt(g_cvarRSPointsBotKill);
							}
						}
						else
						{
							SetEntityHealth(victim, fhealth);
						}
						CloseHandle(keyvalues);
						return;
					}
				}
			}
		}
	}
}

public Event_TankSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new tank = GetClientOfUserId(GetEventInt(event, "userid"));
	for(new i=1; i<=MaxClients; i++)
	{
		if(g_bTankQueue[i])
		{
			g_iClientOfTank[tank] = i;
			g_bTankQueue[i] = false;
			g_bLinked[tank] = true;
			#if TCDEBUG
			decl String:name[256];
			GetClientName(tank, name, sizeof(name));
			PrintToChat(i, "Your linked tank is %s(%i | id:%i)", name, tank, GetClientUserId(tank));
			#endif
			return;
		}
	}
}

public Event_WitchSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new witch = GetEventInt(event, "witchid");
	for(new i=1; i<=MaxClients; i++)
	{
		if(g_bWitchQueue[i])
		{
			g_iClientOfWitch[witch] = i;
			g_bWitchQueue[i] = false;
			g_bLinked[witch] = true;
			#if TCDEBUG
			decl String:name[256];
			GetClientName(witch, name, sizeof(name));
			PrintToChat(i, "Your linked witch is %i", witch);
			#endif
			return;
		}
	}
}

public Event_WitchAngry(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new witch = GetEventInt(event, "witchid");
	if(g_bLinked[witch])
	{
		if(g_iClientOfWitch[witch] != 0)
		{
			decl String:aname[256], String:vname[256];
			GetClientName(client, vname, sizeof(vname));
			GetClientName(g_iClientOfWitch[witch], aname, sizeof(aname));
			decl String:content[512];
			Format(content, sizeof(content), "\x05%s\x01 woke up \x05%s\x01's witch!", vname, aname);
			PrintToChatAllDM(content);
		}
	}
}

public Event_WitchKilled(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new witch = GetEventInt(event, "witchid");
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:oneshot = GetEventBool(event, "oneshot");
	if(attacker > 0 && IsValidEntity(attacker) && IsClientInGame(attacker) && GetClientTeam(attacker) == 2)
	{
		if(!g_bLinked[witch])
		{
			new rewardpts = GetConVarInt(g_cvarRSPointsUnlinkedWitch);
			if(notify[attacker])
			{
				PrintToChat(attacker, "\x04You received %i points for killing the witch!", rewardpts);
			}
			points[attacker]+=rewardpts;
			if(g_bAutoMenus[attacker])
			{
				BuildRewardMenu(attacker);
			}
		}
		else
		{
			if(oneshot && g_iClientOfWitch[witch] != attacker)
			{
				new rewardpts = GetConVarInt(g_cvarRSPointsLinkedWitchSingle);
				decl String:tname[256], String:kname[256];
				GetClientName(g_iClientOfWitch[witch], tname, sizeof(tname));
				GetClientName(attacker, kname, sizeof(kname));
				decl String:content[512];
				Format(content, sizeof(content), "\x05%s \x01Killed \x05%s's \x01Witch with a single shot and received %i points!", kname, tname, rewardpts);
				PrintToChatAllDM(content);
				points[attacker]+=rewardpts;
				if(g_bAutoMenus[attacker])
				{
					BuildRewardMenu(attacker);
				}
			}
			else if(!oneshot && g_iClientOfWitch[witch] != attacker)
			{
				new rewardpts = GetConVarInt(g_cvarRSPointsLinkedWitch);
				decl String:tname[256], String:kname[256];
				GetClientName(g_iClientOfWitch[witch], tname, sizeof(tname));
				GetClientName(attacker, kname, sizeof(kname));
				decl String:content[512];
				Format(content, sizeof(content), "\x05%s \x01Killed \x05%s's \x01Witch and received %i points!", kname, tname, rewardpts);
				PrintToChatAllDM(content);
				points[attacker]+=rewardpts;
				if(g_bAutoMenus[attacker])
				{
					BuildRewardMenu(attacker);
				}
			}
		}
	}
	if(g_bLinked[witch])
	{
		g_iClientOfWitch[witch] = 0;
		g_bLinked[witch] = false;
	}
}

public Event_TankKilled(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new tank = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(attacker > 0 && IsValidEntity(attacker) && IsClientInGame(attacker) && GetClientTeam(attacker) == 2)
	{
		if(!g_bLinked[tank])
		{
			new rewardpts = GetConVarInt(g_cvarRSPointsUnlinkedTank);
			if(notify[attacker])
			{
				PrintToChat(attacker, "\x04You received %i points for killing the tank!", rewardpts);
			}
			points[attacker]+=rewardpts;
			if(g_bAutoMenus[attacker])
			{
				BuildRewardMenu(attacker);
			}
		}
		else if(g_bLinked[tank] && g_iClientOfTank[tank] != attacker)
		{
			new rewardpts = GetConVarInt(g_cvarRSPointsLinkedTank);
			decl String:tname[256], String:kname[256];
			GetClientName(g_iClientOfTank[tank], tname, sizeof(tname));
			GetClientName(attacker, kname, sizeof(kname));
			decl String:content[512];
			Format(content, sizeof(content), "\x05%s \x01Killed \x05%s's \x01Tank and received %i points!", kname, tname, rewardpts);
			PrintToChatAllDM(content);
			points[attacker]+=rewardpts;
			if(g_bAutoMenus[attacker])
			{
				BuildRewardMenu(attacker);
			}
		}
	}
	if(g_bLinked[tank])
	{
		g_iClientOfTank[tank] = 0;
		g_bLinked[tank] = false;
	}
}

public Event_LedgeGrab(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new causer = GetClientOfUserId(GetEventInt(event, "causer"));
	if(causer > 0 && IsValidEntity(causer) && IsClientInGame(causer) && GetClientTeam(causer) == 2 && causer != client)
	{
		new rewardpts = GetConVarInt(g_cvarRSPointsLedgeHang);
		decl String:name[256];
		GetClientName(client, name, sizeof(name));
		if(notify[causer])
		{
			PrintToChat(causer, "\x04You caused \x05%s \x01to hang from the ledge. You get %i points!", name, rewardpts);
		}
		points[causer]+=rewardpts;
		score[causer]+= GetConVarInt(g_cvarSSPointsLedgeHang);
		tscore[causer]+= GetConVarInt(g_cvarSSPointsLedgeHang);
		if(g_bAutoMenus[causer])
		{
			BuildRewardMenu(causer);
		}
		if(!g_bFallBitch[causer])
		{
			decl String:aname[256];
			g_bFallBitch[causer] = true;
			GetClientName(causer, aname, sizeof(aname));
			decl String:content[512];
			Format(content, sizeof(content), "\x05 %s \x01 earned the \x05 GOODBYE MY FRIEND\x01 achievement by causing an enemy to hang from the ledge!", aname);
			PrintToChatAllDM(content);
			UpdatePlayerAchievement(client);
		}
	}
	if(GetConVarBool(g_cvarDeathmatchNoHang))
	{
		ForcePlayerSuicide(client);
	}
}

public Action:Event_PillsUsed(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!GetConVarBool(g_cvarDeathmatchRefillPills))
	{
		return;
	}
	if(client > 0 && IsValidEntity(client) && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		CheatCommand(client, "give", "ammo");
	}
}

public Action:Event_WeaponReload(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && IsValidEntity(client) && IsClientInGame(client) && IsPlayerAlive(client) && g_bFastCombat[client] && GetClientTeam(client) == 2)
	{
		new total = GetClientHealth(client);
		if(total > 45)
		{
			return;
		}
		AdrenReload(client);
	}
}

public Action:Event_WeaponFire(Handle:event, String:event_name[], bool:dontBroadcast)
{
	#if !SDKHOOKS
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:weapon[64];
	if(client > 0 && IsValidEntity(client) && IsValidEdict(client) && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		SetClientPrimaryWeapon(client, weapon);
	}
	#endif
}

public Event_PickUp(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client > 0 && IsValidEntity(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl String:item[256], Float:pos[3];
		GetEventString(event, "item", item, sizeof(item));
		if(StrEqual(item, "gnome"))
		{
			GetClientAbsOrigin(client, pos);
			#if DEBUG
			decl String:name[256];
			GetClientName(client, name, sizeof(name));
			LogMessage("[REWARD MANAGER] %s (ID: %i) picked the gnome", name, client);
			PrintToServer("[REWARD MANAGER] %s (ID: %i) picked the gnome", name, client);
			#endif
			PrintToChat(client, "\x03The gnome exploded. Do not pick it up next time!");
			CreateExplosion(pos);
		}
	}
}
public Event_PlayerFirstSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new bool:bot = GetEventBool(event, "isbot");
	if(!bot && !g_bFirstDone)
	{
		CreateTimer(1.0, WipeEnt, _, TIMER_FLAG_NO_MAPCHANGE);
		g_bFirstDone = true;
	}
}

public Event_PlayerDeath(Handle:event, String:event_name[], bool:dontBroadcast)
{
	RebuildAll();
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damagetype = GetEventInt(event, "type");
	UpdateStats(victim);
	g_bHasActiveDefib[victim] = false;
	if(victim > 0 && IsValidEntity(victim) && IsClientInGame(victim))
	{
		g_bBodyQueue[victim] = true;
		if(g_bInstantRespawn[victim])
		{
			SetEntDataFloat(victim, g_flLagMovement, 1.0, true);
			g_bRespawnQueue[victim] = true;
			CreateTimer(0.1, RespawnClient, victim, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{	
			SetEntDataFloat(victim, g_flLagMovement, 1.0, true);
			g_bRespawnQueue[victim] = true;
			CreateTimer(GetConVarFloat(g_cvarDeathmatchRespawnTime), RespawnClient, victim, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	//EnqueueWeapons(victim);
	if(attacker > 0 && IsValidEntity(attacker) && IsClientInGame(attacker) && GetClientTeam(attacker) == 2 && victim > 0 && IsValidEntity(victim) && IsClientInGame(victim) && GetClientTeam(victim) == 3)
	{
		if(g_bLinked[victim] && g_iClientOfTank[victim] != attacker)
		{
			new rewardpts = GetConVarInt(g_cvarRSPointsLinkedSpecial);
			if(rewardpts > 0)
			{
				decl String:tname[256], String:kname[256];
				GetClientName(g_iClientOfTank[victim], tname, sizeof(tname));
				GetClientName(attacker, kname, sizeof(kname));
				decl String:content[512];
				Format(content, sizeof(content), "\x05%s \x01Killed \x05%s's \x01Special Infected and received %i points!", kname, tname, rewardpts);
				PrintToChatAllDM(content);
				points[attacker]+=rewardpts;
				if(g_bAutoMenus[attacker])
				{
					BuildRewardMenu(attacker);
				}
			}
		}
	}
	if(g_bLinked[victim])
	{
		g_iClientOfTank[victim] = 0;
		g_bLinked[victim] = false;
	}
	if(victim > 0 && IsValidEntity(victim) && IsClientInGame(victim) && GetClientTeam(victim) == 2 && damagetype == 134217792)
	{
		SetEntityHealth(victim, 1);
	}
	if(victim > 0 && IsValidEntity(victim) && IsClientInGame(victim) && !IsFakeClient(victim) && GetClientTeam(victim) == 2)
	{
		g_flDeathTime[victim] = GetGameTime();
		new Float:flMinTime = GetConVarFloat(g_cvarRSCalcEndurance);
		new Float:flCurrentTime = g_flDeathTime[victim]-g_flSpawnTime[victim];
		if(flCurrentTime > g_flLongestAlive[victim] || g_flLongestAlive[victim] == 0.0)
		{
			g_flLongestAlive[victim] == flCurrentTime;
			UpdatePlayerLongestTime(victim);
		}
		if(flCurrentTime >= flMinTime)
		{
			new iMinTime = RoundToFloor(flMinTime);
			new rewardpts = GetConVarInt(g_cvarRSPointsEndurance);
			if(rewardpts > 0)
			{
				if(notify[victim])
				{
					PrintToChat(victim, "\x04You received %i points for lasting more than %i seconds alive!", rewardpts, iMinTime);
				}
				points[victim]+=rewardpts;
				score[victim]+=GetConVarInt(g_cvarSSPointsEndurance);
				tscore[victim]+=GetConVarInt(g_cvarSSPointsEndurance);
				if(g_bAutoMenus[victim])
				{
					BuildRewardMenu(victim);
				}
			}			
			if(!g_bEndurance[victim])
			{
				decl String:name[256];
				g_bEndurance[victim] = true;
				GetClientName(victim, name, sizeof(name));
				decl String:content[512];
				Format(content, sizeof(content), "\x05%s \x01earned the \x05ENDURANCE FIGHTER \x01achievement by lasting more than %i seconds alive!", name, iMinTime);
				PrintToChatAllDM(content);
				UpdatePlayerAchievement(victim);
			}
		}
		if(attacker > 0 && IsValidEntity(attacker) && IsClientInGame(attacker) && !IsFakeClient(attacker) && GetClientTeam(attacker) == 2)
		{
			if(flCurrentTime <= 5.0)
			{
				new rewardpts = GetConVarInt(g_cvarRSPointsFastKill);
				if(rewardpts > 0)
				{
					if(notify[g_iLastAttacker[victim]])
					{
						PrintToChat(g_iLastAttacker[victim], "\x04You received %i points for killing an enemy right after he spawned!", rewardpts);
					}
					points[g_iLastAttacker[victim]]+=rewardpts;
					score[g_iLastAttacker[victim]]+=GetConVarInt(g_cvarSSPointsFastTrigger);
					tscore[g_iLastAttacker[victim]]+=GetConVarInt(g_cvarSSPointsFastTrigger);
				}
				if(!g_bSurprise[g_iLastAttacker[victim]])
				{
					decl String:name[256];
					g_bSurprise[g_iLastAttacker[victim]] = true;
					GetClientName(g_iLastAttacker[victim], name, sizeof(name));
					decl String:content[512];
					Format(content, sizeof(content), "\x05%s \x01earned the \x05LIGHTING TRIGGER \x01achievement by killing an enemy right after he spawned!", name);
					PrintToChatAllDM(content);
					UpdatePlayerAchievement(g_iLastAttacker[victim]);
				}
			}
		}
		g_flSpawnTime[victim] = 0.0;
	}
	g_bChoosedBoost[victim] = false;
	if(victim != 0)
	{
		if(g_bSpitterDeath[victim])
		{
			CheatCommand(victim, "z_spawn", "spitter");
		}
	}
	if(victim > 0 && IsValidEntity(victim) && IsClientInGame(victim) && GetClientTeam(victim) == 2 && attacker > 0 && IsValidEntity(attacker) && IsClientInGame(attacker) && GetClientTeam(attacker) && (damagetype == 8 || damagetype == 2056) && victim != attacker)
	{
		new rewardpts = GetConVarInt(g_cvarRSPointsBurningKill);
		if(rewardpts > 0)
		{
			if(notify[attacker])
			{
				PrintToChat(attacker, "\x04You got %i points for burning an enemy survivor!", rewardpts);
			}
			points[attacker]+=rewardpts;
			score[attacker]+=GetConVarInt(g_cvarSSPointsBurning);
			tscore[attacker]+=GetConVarInt(g_cvarSSPointsBurning);
			if(g_bAutoMenus[attacker])
			{
				BuildRewardMenu(attacker);
			}
		}
		if(!g_bBurningMachine[attacker])
		{
			decl String:name[256];
			g_bBurningMachine[attacker] = true;
			GetClientName(attacker, name, sizeof(name));
			decl String:content[512];
			Format(content, sizeof(content), "\x05 %s \x01 earned the \x05 BURNING MACHINE\x01 achievement by roasting an enemy survivor!", name);
			PrintToChatAllDM(content);
			UpdatePlayerAchievement(victim);
		}
	}
	
	if(attacker == 0 && IsValidEntity(attacker) && IsValidEdict(attacker))
	{
		decl String:classname[256];
		GetEdictClassname(attacker, classname, sizeof(classname));
		if(StrEqual(classname, "witch"))
		{
			if(g_bLinked[attacker])
			{
				new attacker2 = g_iClientOfWitch[attacker];
				decl String:name[256];
				GetClientName(attacker2, name, sizeof(name));
				if(victim > 0 && IsValidEntity(victim) && IsClientInGame(victim) && GetClientTeam(victim) == 2)
				{
					if(notify[victim])
					{
						PrintToChat(victim, "\x05%s \x01's witch killed you!", name);
					}
					kills[attacker2]++;
					tkills[attacker2]++;
					deaths[victim]++;
					tdeaths[victim]++;
					killcount[victim] = 0;
					if(IsFakeClient(victim))
					{
						score[attacker2]+=GetConVarInt(g_cvarSSPointsBotKill);
						tscore[attacker2]+=GetConVarInt(g_cvarSSPointsBotKill);
						points[attacker2]+=GetConVarInt(g_cvarRSPointsBotKill);
					}
					else
					{
						score[attacker2]+=GetConVarInt(g_cvarSSPointsHumanKill);
						tscore[attacker2]+=GetConVarInt(g_cvarSSPointsHumanKill);
						points[attacker2]+=GetConVarInt(g_cvarRSPointsHumanKill);
					}
					if(!g_bWidowMaker[attacker2])
					{
						decl String:aname[256];
						g_bWidowMaker[attacker] = true;
						GetClientName(attacker, aname, sizeof(aname));
						decl String:content[512];
						Format(content, sizeof(content), "\x05%s \x01earned the \x05WIDOW MAKER \x01achievement by killing an enemy survivor with his Witch!", aname);
						PrintToChatAllDM(content);
						UpdatePlayerAchievement(victim);
					}
					return;
				}
			}
		}
	}
	//Survivors kills a controlled infected
	if(victim > 0
	&& IsValidEntity(victim)
	&& IsClientInGame(victim)
	&& !IsFakeClient(victim)
	&& GetClientTeam(victim) == 3)
	{
		deaths[victim]++;
		tdeaths[victim]++;
		if(g_bVomitDeath[victim])
		{
			SDKCall(sdkCallVomitPlayer, attacker, victim, true);
		}
	}
	
	if((victim > 0 && GetClientTeam(victim) == 2) && (attacker > 0 && GetClientTeam(attacker) == 3))
	{
		if(g_bVomitDeath[victim])
		{
			SDKCall(sdkCallVomitPlayer, attacker, victim, true);
		}
		if(!IsFakeClient(attacker))
		{
			if(IsFakeClient(victim))
			{
				kills[attacker]+=1;
				tkills[attacker]+=1;
				score[attacker]+=GetConVarInt(g_cvarSSPointsBotKill);
				tscore[attacker]+=GetConVarInt(g_cvarSSPointsBotKill);
			}
				
			if(!IsFakeClient(victim))
			{
				kills[attacker]+=1;
				tkills[attacker]+=1;
				deaths[victim]+=1;
				tdeaths[victim]+=1;
				score[attacker]+=GetConVarInt(g_cvarSSPointsHumanKill);
				tscore[attacker]+=GetConVarInt(g_cvarSSPointsHumanKill);
				killcount[attacker]++;
				killcount[victim] = 0;
			}
			if(!IsFakeClient(victim))
			{
				if(GetConVarBool(g_cvarSSMenuDeath))
				{
					if(g_bAutoMenus[victim])
					{
						BuildScoreMenu(victim);
						PrintToChat(victim, "\x04Kills: %i ##, Deaths: %i ## Score: %i", kills[victim], deaths[victim], score[victim]);
					}
				}
			}
		}
			
		if(g_bLinked[attacker] && IsFakeClient(attacker))
		{
			if(GetEntProp(attacker, Prop_Send, "m_zombieClass") == 8)
			{
				new lucky = g_iClientOfTank[attacker];
				if(lucky == victim)
				{
					deaths[victim]++;
					tdeaths[victim]++;
				}
				if(IsFakeClient(victim) && lucky != victim)
				{
					kills[lucky]+=1;
					tkills[lucky]+=1;
					score[lucky]+GetConVarInt(g_cvarSSPointsBotKill);
					tscore[lucky]+GetConVarInt(g_cvarSSPointsBotKill);
					points[lucky]+=GetConVarInt(g_cvarRSPointsBotKill);
				}
				if(!IsFakeClient(victim) && lucky != victim)
				{
					kills[lucky]++;
					tkills[lucky]++;
					deaths[victim]+=1;
					tdeaths[victim]+=1;
					score[lucky]+=GetConVarInt(g_cvarSSPointsHumanKill);
					tscore[lucky]+=GetConVarInt(g_cvarSSPointsHumanKill);
					points[lucky]+=GetConVarInt(g_cvarRSPointsHumanKill);
					killcount[victim] = 0;
					decl String:name[256];
					GetClientName(lucky, name, sizeof(name));
					if(notify[victim])
					{
						PrintToChat(victim, "\x05%s \x01's tank killed you!", name);
					}
					new attacker2 = g_iClientOfTank[attacker];
					new rewardpts = GetConVarInt(g_cvarRSPointsLinkedTankKill);
					if(rewardpts > 0)
					{
						if(notify[attacker2])
						{
							PrintToChat(attacker2, "\x04You received %i points for killing a survivor with your tank!", rewardpts);
						}
						points[attacker2]+=rewardpts;
						if(g_bAutoMenus[attacker2])
						{
							BuildRewardMenu(attacker);
						}
					}
					if(!g_bBodyGuard[attacker2])
					{
						decl String:aname[256];
						g_bBodyGuard[attacker2] = true;
						GetClientName(attacker2, aname, sizeof(aname));
						decl String:content[512];
						Format(content, sizeof(content), "\x05 %s \x01earned the \x05MY BODY GUARD \x01 achievement by killing an enemy survivor with his Tank!", aname);
						PrintToChatAllDM(content);
						UpdatePlayerAchievement(victim);
					}
				}
			}
			else
			{
				new lucky = g_iClientOfTank[attacker];
				if(lucky == victim)
				{
					deaths[victim]++;
					tdeaths[victim]++;
				}
				if(IsFakeClient(victim) && lucky != victim)
				{
					kills[lucky]+=1;
					tkills[lucky]+=1;
					score[lucky]+=GetConVarInt(g_cvarSSPointsBotKill);
					tscore[lucky]+=GetConVarInt(g_cvarSSPointsBotKill);
					points[lucky]+=GetConVarInt(g_cvarRSPointsBotKill);
				}
				if(!IsFakeClient(victim) && lucky != victim)
				{
					kills[lucky]++;
					deaths[victim]+=1;
					tdeaths[victim]+=1;
					score[lucky]+=GetConVarInt(g_cvarSSPointsHumanKill);
					tscore[lucky]+=GetConVarInt(g_cvarSSPointsHumanKill);
					points[lucky]+=GetConVarInt(g_cvarRSPointsHumanKill);
					killcount[victim] = 0;
					decl String:name[256];
					GetClientName(lucky, name, sizeof(name));
					if(notify[victim])
					{
						PrintToChat(victim, "\x05%s \x01's pet killed you!", name);
					}
				}
			}
		}
		if(!IsFakeClient(victim))
		{
			if(GetConVarBool(g_cvarSSMenuDeath))
			{
				if(g_bAutoMenus[victim])
				{
					BuildScoreMenu(victim);
					PrintToChat(victim, "\x04Kills: %i ##, Deaths: %i ## Score: %i", kills[victim], deaths[victim], score[victim]);
				}
			}
		}
	}
	if(victim > 0 && GetClientTeam(victim) == 2 && attacker > 0 && GetClientTeam(attacker) == 2)
	{
		if(victim == attacker)
		{
			deaths[victim]++;
			tdeaths[victim]++;
			if(g_iShotsReceived[victim] <= 1)
			{
				new rewardpts = GetConVarInt(g_cvarRSPointsSingleHit);
				decl String:vname[256];
				GetClientName(victim, vname, sizeof(vname));
				decl String:content[512];
				Format(content, sizeof(content), "\x05%s \x01 got killed with a single shot!", vname);
				PrintToChatAllDM(content);
				score[g_iLastAttacker[victim]]+=GetConVarInt(g_cvarSSPointsInstaKill);
				tscore[g_iLastAttacker[victim]]+=GetConVarInt(g_cvarSSPointsInstaKill);
				if(rewardpts > 0)
				{
					if(notify[g_iLastAttacker[victim]])
					{
						PrintToChat(g_iLastAttacker[victim], "\x04You received %i points for killing an enemy with a single shot!", rewardpts);
					}
					points[g_iLastAttacker[victim]]+=rewardpts;
					if(g_bAutoMenus[g_iLastAttacker[victim]])
					{
						BuildRewardMenu(g_iLastAttacker[victim]);
					}
				}
				if(!g_bOneShot[g_iLastAttacker[victim]] && g_iLastAttacker[victim] != 0)
				{
					decl String:name[256];
					g_bOneShot[g_iLastAttacker[victim]] = true;
					GetClientName(g_iLastAttacker[victim], name, sizeof(name));
					Format(content, sizeof(content), "\x05%s \x01earned the \x05FAST AND CLEAN \x01achievement by killing an enemy with a single shot!", name);
					PrintToChatAllDM(content);
					UpdatePlayerAchievement(victim);
				}
			}
			return;
		}
		if(g_bIsStalker[attacker] && !IsFakeClient(victim))
		{
			new rewardpts = GetConVarInt(g_cvarRSPointsStalkerKill);
			decl String:name[256];
			GetClientName(attacker, name, sizeof(name));
			if(notify[victim])
			{
				PrintToChat(victim, "\x05%s \x01killed you on invisible state!", name);
			}
			if(rewardpts > 0)
			{
				if(notify[attacker])
				{
					PrintToChat(attacker, "\x04You received %i points for killing a survivor on invisible state", rewardpts);
				}
				points[attacker]+=rewardpts;
				if(g_bAutoMenus[attacker])
				{
					BuildRewardMenu(attacker);
				}
			}
		}
		if(g_bVomitDeath[victim])
		{
			SDKCall(sdkCallVomitOnPlayer, attacker, attacker, true);
		}
		decl Float:apos[3], Float:tpos[3], Float:distance;
		GetClientAbsOrigin(victim, tpos);
		GetClientAbsOrigin(attacker, apos);
		distance = GetVectorDistance(apos, tpos);
		if(distance >= GetConVarFloat(g_cvarRSCalcDistance) && (damagetype != 8 && damagetype != 2056))
		{
			new rewardpts = GetConVarInt(g_cvarRSPointsDistanceKill);
			decl String:aname[256], String:tname[256];
			GetClientName(victim, tname, sizeof(tname));
			GetClientName(attacker, aname, sizeof(aname));
			new idistance = RoundToFloor(distance);
			if(rewardpts > 0)
			{
				decl String:content[512];
				Format(content, sizeof(content), "\x05%s \x01killed \x05%s \x01with a distance of \x05%i \x01and received %i points!", aname, tname, idistance, rewardpts);
				PrintToChatAllDM(content);
				points[attacker]+=rewardpts;
				if(g_bAutoMenus[attacker])
				{
					BuildRewardMenu(attacker);
				}
			}
			if(!g_bDistanceReaper[attacker])
			{
				decl String:name[256];
				g_bDistanceReaper[attacker] = true;
				GetClientName(attacker, name, sizeof(name));
				
				decl String:content[512];
				Format(content, sizeof(content), "\x05%s \x01earned the \x05DISTANCE REAPER \x01achievement by killing an enemy who was far away!", name);
				PrintToChatAllDM(content);
				UpdatePlayerAchievement(victim);
			}
		}
		if(IsFakeClient(victim))
		{
			kills[attacker]+=1;
			tkills[attacker]+=1;
			score[attacker]+=GetConVarInt(g_cvarSSPointsBotKill);
			tscore[attacker]+=GetConVarInt(g_cvarSSPointsBotKill);
			points[attacker]+=GetConVarInt(g_cvarRSPointsBotKill);
		}
			
		if(!IsFakeClient(victim))
		{
			kills[attacker]+=1;
			tkills[attacker]+=1;
			deaths[victim]+=1;
			tdeaths[victim]+=1;
			score[attacker]+=GetConVarInt(g_cvarSSPointsHumanKill);
			tscore[attacker]+=GetConVarInt(g_cvarSSPointsHumanKill);
			points[attacker]+=GetConVarInt(g_cvarRSPointsHumanKill);
			killcount[attacker]++;
			killcount[victim] = 0;
		}
		if(!IsFakeClient(victim))
		{
			if(GetConVarBool(g_cvarSSMenuDeath))
			{
				if(g_bAutoMenus[victim])
				{
					BuildScoreMenu(victim);
					PrintToChat(victim, "\x04Kills: %i ##, Deaths: %i ## Score: %i", kills[victim], deaths[victim], score[victim]);
				}
			}
		}
	}
	g_iShotsReceived[victim] = 0;
	if(killcount[attacker] >= GetConVarInt(g_cvarRSCalcRowKills))
	{
		points[attacker] += GetConVarInt(g_cvarRSPointsRowKill);
		killcount[attacker] = 0;
		if(notify[attacker])
		{
			PrintToChat(attacker, "\x04%i consecutive kills!, you get %i points!", GetConVarInt(g_cvarRSCalcRowKills), GetConVarInt(g_cvarRSPointsRowKill));
			PrintHintText(attacker, "%i consecutive kills!, you get %i points!", GetConVarInt(g_cvarRSCalcRowKills), GetConVarInt(g_cvarRSPointsRowKill));
		}
		if(g_bAutoMenus[attacker])
		{
			BuildRewardMenu(attacker);
		}
	}
	if(victim > 0 && IsValidEntity(victim) && IsClientInGame(victim))
	{
		zombieclass[victim] = GetEntProp(victim, Prop_Send, "m_zombieClass");
	}
	
	if(!deathmatch || zombieclass[victim] == 8)
	{
		return;
	}
}


public Event_DeathPlayerVisible(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(!deathmatch || !GetConVarBool(g_cvarDeathmatchWipeBody))
	{
		return;
	}
	new entity = GetEventInt(event, "subject");
	CreateTimer(GetConVarFloat(g_cvarDeathmatchBodyTimeout), RemoveEntity, entity, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:RemoveEntity(Handle:timer, any:entity)
{
	if(IsValidEntity(entity) && IsValidEdict(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
}

public Event_PlayerSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	RebuildAll();
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsFakeClient(client))
	{
		g_bInside[client] = true;
	}
	if(!deathmatch)
	{
		return;
	}
	if(client > 0 && IsValidEntity(client) && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2)
	{
		g_flSpawnTime[client] = GetGameTime();
		switch(g_iFavCharacter[client])
		{
			case 0:
			{
				SetEntProp(client, Prop_Send, "m_survivorCharacter", 0);
				SetEntityModel(client, "models/survivors/survivor_gambler.mdl");
			}
			case 1:
			{
				SetEntProp(client, Prop_Send, "m_survivorCharacter", 2);
				SetEntityModel(client, "models/survivors/survivor_coach.mdl");
			}
			case 2:
			{
				SetEntProp(client, Prop_Send, "m_survivorCharacter", 3);
				SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");
			}
			case 3:
			{
				SetEntProp(client, Prop_Send, "m_survivorCharacter", 1);
				SetEntityModel(client, "models/survivors/survivor_producer.mdl");
			}
		}
	}
	
	if(client > 0 && IsValidEntity(client) && IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		for(new i=1; i<=MaxClients; i++)
		{
			if(g_bSmokerQueue[i] && class == CLASS_SMOKER)
			{
				g_iClientOfTank[client] = i;
				g_bSmokerQueue[i] = false;
				g_bLinked[client] = true;
				#if TCDEBUG
				decl String:name[256];
				GetClientName(client, name, sizeof(name));
				PrintToChat(i, "Your linked special is %s(%i | id:%i)", name, client, GetClientUserId(client));
				#endif
				return;
			}
			if(g_bBoomerQueue[i] && class == CLASS_BOOMER)
			{
				g_iClientOfTank[client] = i;
				g_bBoomerQueue[i] = false;
				g_bLinked[client] = true;
				#if TCDEBUG
				decl String:name[256];
				GetClientName(client, name, sizeof(name));
				PrintToChat(i, "Your linked special is %s(%i | id:%i)", name, client, GetClientUserId(client));
				#endif
				return;
			}
			if(g_bHunterQueue[i] && class == CLASS_HUNTER)
			{
				g_iClientOfTank[client] = i;
				g_bHunterQueue[i] = false;
				g_bLinked[client] = true;
				#if TCDEBUG
				decl String:name[256];
				GetClientName(client, name, sizeof(name));
				PrintToChat(i, "Your linked special is %s(%i | id:%i)", name, client, GetClientUserId(client));
				#endif
				return;
			}
			if(g_bSpitterQueue[i] && class == CLASS_SPITTER)
			{
				g_iClientOfTank[client] = i;
				g_bSpitterQueue[i] = false;
				g_bLinked[client] = true;
				#if TCDEBUG
				decl String:name[256];
				GetClientName(client, name, sizeof(name));
				PrintToChat(i, "Your linked special is %s(%i | id:%i)", name, client, GetClientUserId(client));
				#endif
				return;
			}
			if(g_bJockeyQueue[i] && class == CLASS_JOCKEY)
			{
				g_iClientOfTank[client] = i;
				g_bJockeyQueue[i] = false;
				g_bLinked[client] = true;
				#if TCDEBUG
				decl String:name[256];
				GetClientName(client, name, sizeof(name));
				PrintToChat(i, "Your linked special is %s(%i | id:%i)", name, client, GetClientUserId(client));
				#endif
				return;
			}
			if(g_bChargerQueue[i] && class == CLASS_CHARGER)
			{
				g_iClientOfTank[client] = i;
				g_bChargerQueue[i] = false;
				g_bLinked[client] = true;
				#if TCDEBUG
				decl String:name[256];
				GetClientName(client, name, sizeof(name));
				PrintToChat(i, "Your linked special is %s(%i | id:%i)", name, client, GetClientUserId(client));
				#endif
				return;
			}
		}
	}
}

public Action:RespawnClient(Handle:timer, any:client)
{
	#if DEBUG
	LogMessage("[DEATHMATCH RESPAWN] A new respawn call is in progress [client: %i]", client);
	#endif
	decl Float:pos[3];
	pos = GetRandomRespawnPos(); //Get a random valid position for the specified map
	if(!deathmatch
	|| client <= 0
	|| !IsValidEntity(client)
	|| !IsClientInGame(client)
	|| GetClientTeam(client) != 2
	|| zombieclass[client] == 8
	|| !g_bRespawnQueue[client])
	{
		#if DEBUG
		LogMessage("[DEATHMATCH RESPAWN] The respawn was canceled");
		#endif
		return;
	}
	
	SDKCall(hRoundRespawn, client); //This perfroms the respawn
	g_bRespawnQueue[client] = false;
	
	#if DEBUG
	LogMessage("[RESPAWN] User %i got respawned", client);
	PrintToServer("[RESPAWN] User %i got respawned", client);
	#endif
	
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR); // Teleports the client ot the valid position obtained
	new respawn_health = GetConVarInt(g_cvarDeathmatchRespawnHealth);
	SetEntityHealth(client, respawn_health);
	SetEntProp(client, Prop_Send, "m_iMaxHealth", respawn_health);
	#if DEBUG
	LogMessage("[DEATHMATCH RESPAWN] The player was teleported to a valid location");
	#endif
	
	if(g_bExtraHealth[client])
	{
		new thealth = GetClientHealth(client)+GetConVarInt(g_cvarBSCalcHealth);
		SetEntityHealth(client, thealth);
		SetEntProp(client, Prop_Send, "m_iMaxHealth", thealth);
	}
	
	if(g_bExtraSpeed[client])
	{
		new Float:total = FloatAdd(1.0, GetConVarFloat(g_cvarBSCalcSpeed));
		SetEntDataFloat(client, g_flLagMovement, total, true);
	}
	if(GetConVarBool(g_cvarWeaponManagerGivePri) && GetConVarBool(g_cvarWeaponManagerEnable))
	{
		switch(g_iFavWeapon[client])
		{
			case 0:
			{
				switch(GetRandomInt(1, 6))
				{
					case 1:
					{
						CheatCommand(client, "give", "rifle_desert");
					}
					case 2:
					{
						CheatCommand(client, "give", "rifle_ak47");
					}
					case 3:
					{
						CheatCommand(client, "give", "rifle");
					}
					case 4:
					{
						CheatCommand(client, "give", "shotgun_spas");
					}
					case 5:
					{
						CheatCommand(client, "give", "shotgun_chrome");
					}
					case 6:
					{
						CheatCommand(client, "give", "sniper_military");
					}
				}
			}
			case 1:
			{
				CheatCommand(client, "give", "autoshotgun");
			}
			case 2:
			{
				CheatCommand(client, "give", "hunting_rifle");
			}
			case 3:
			{
				CheatCommand(client, "give", "pumpshotgun");
			}
			case 4:
			{
				CheatCommand(client, "give", "rifle");
			}
			case 5:
			{
				CheatCommand(client, "give", "rifle_ak47");
			}
			case 6:
			{
				CheatCommand(client, "give", "rifle_desert");
			}
			case 7:
			{
				CheatCommand(client, "give", "rifle_sg552");
			}
			case 8:
			{
				CheatCommand(client, "give", "shotgun_chrome");
			}
			case 9:
			{
				CheatCommand(client, "give", "shotgun_spas");
			}
			case 10:
			{
				CheatCommand(client, "give", "smg");
			}
			case 11:
			{
				CheatCommand(client, "give", "smg_mp5");
			}
			case 12:
			{
				CheatCommand(client, "give", "smg_silenced");
			}
			case 13:
			{
				CheatCommand(client, "give", "sniper_awp");
			}
			case 14:
			{
				CheatCommand(client, "give", "sniper_military");
			}
			case 15:
			{
				CheatCommand(client, "give", "sniper_scout");
			}
		}
		#if DEBUG
		LogMessage("[DEATHMATCH RESPAWN] A primary weapon was given to the client");
		#endif
	}
	
	if(GetConVarBool(g_cvarWeaponManagerGiveSec) && GetConVarBool(g_cvarWeaponManagerEnable))
	{
		switch(GetRandomInt(1, 9))
		{
			case 1:
			{
				CheatCommand(client, "give", "pistol_magnum");
			}
			case 2:
			{
				CheatCommand(client, "give", "pistol");
			}
			case 3:
			{
				CheatCommand(client, "give", "katana");
			}
			case 4:
			{
				CheatCommand(client, "give", "machete");
			}
			case 5:
			{
				CheatCommand(client, "give", "give baseball_bat");
			}
			case 6:
			{
				CheatCommand(client, "give", "give fireaxe");
			}
			case 7:
			{
				CheatCommand(client, "give", "give crowbar");
			}
			case 8:
			{
				CheatCommand(client, "give", "give cricket_bat");
			}
			case 9:
			{
				CheatCommand(client, "give", "chainsaw");
			}
		}
		#if DEBUG
		LogMessage("[DEATHMATCH RESPAWN] A secondary weapon was given to the client");
		#endif
	}				
	if(g_bUpgrade[client])
	{
		switch(GetRandomInt(1,3))
		{
			case 1:
			{
				CheatCommand(client, "upgrade_add", "LASER_SIGHT");
			}
			case 2:
			{
				CheatCommand(client, "upgrade_add", "INCENDIARY_AMMO");
			}
			case 3:
			{
				CheatCommand(client, "upgrade_add", "EXPLOSIVE_AMMO");
			}
		
		}
		#if DEBUG
		LogMessage("[DEATHMATCH RESPAWN] An upgrade was added to the player's weapon");
		#endif
	}
	if(g_bMedic[client])
	{
		CheatCommand(client, "give", "first_aid_kit");
	}
	if(g_bStalker[client])
	{
		SetEntityRenderColor(client, 255, 255 , 255 , 0);
		CreateTimer(GetConVarFloat(g_cvarBSCalcStalkerTimeout), timerRemoveColor, client, TIMER_FLAG_NO_MAPCHANGE);
		g_bIsStalker[client] = true;
	}
	if(g_bGodMode[client])
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		CreateTimer(GetConVarFloat(g_cvarBSCalcGodTimeout), timerRemoveGod, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	#if 0
	if(!IsFakeClient(client))
	{
		new Handle:keyvalues = INVALID_HANDLE;
		decl String:KvFileName[256];
		new bool:FileFound = false;
		
		BuildPath(Path_SM, KvFileName, sizeof(KvFileName), "data/deathmatch/l4d2_deathmatch_songlist.txt");
		
		if(!FileExists(KvFileName))
		{
			LogMessage("[WARNING] Unable to find the l4d2_deathmatch_songlist.txt file, no music will be heard!");
			FileFound = false;
		}
		else
		{
			FileFound = true;
		}
		
		if(FileFound)
		{
			keyvalues = CreateKeyValues("l4d2_deathmatch_songlist");
			FileToKeyValues(keyvalues, KvFileName);
			KvRewind(keyvalues);
			decl String:file_name[256];
			if(KvJumpToKey(keyvalues, "avoid spawn"))
			{
				new total_files = KvGetNum(keyvalues, "total sounds");
				if(total_files <= 0)
				{
					CloseHandle(keyvalues);
					return;
				}
				decl String:sound[64];
				for(new sound_file=1; sound_file<=total_files; sound_file++)
				{
					Format(sound, sizeof(sound), "sound%i", sound_file);
					KvGetString(keyvalues, sound, file_name, sizeof(file_name));
					StopSoundPerm(client, file_name);
					StopSoundPerm(client, file_name);
				}
			}
			CloseHandle(keyvalues);
		}
	}
	#endif
	#if DEBUG
	LogMessage("[DEATHMATCH RESPAWN] Respawn succeed, calling and ending the function");
	#endif
}

public Action:timerRemoveColor(Handle:timer, any:client)
{
	if(client > 0 && IsValidEntity(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntityRenderColor(client, 255, 255 , 255 , 255);
		g_bIsStalker[client] = false;
	}
}

public Action:timerRemoveGod(Handle:timer, any:client)
{
	if(client > 0 && IsValidEntity(client) && IsClientInGame(client))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
}

public Action:CmdDeathMatch(client, args)
{
	CreateDeathmatch(_);
}

public Action:CmdDeathMatch0(client, args)
{
	StopDeathmatch();
}

stock CreateDeathmatch(any:client = 0)
{
	deathmatch = true;
	#if DEBUG_SPECIAL
	LogMessage("[Deathmatch] The game started.");
	#endif
	#if DEBUG
	LogMessage("[DEATHMATCH] The round started");
	PrintToServer("[DEATHMATCH] The round started");
	#endif
	
	for(new i=1; i<=MaxClients; i++)
	{
		if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			StopMusicType(i, SOUNDTYPE_WAIT);
			if(!g_bFirstDM[i])
			{
				g_bFirstDM[i] = true;
				decl String:name[256];
				GetClientName(i, name, sizeof(name));
				decl String:content[512];
				Format(content, sizeof(content), "\x05%s \x01 earned the \x05 NOBODY SURVIVES\x01 achievement by playing his first deathmatch!", name);
				PrintToChatAllDM(content);
				UpdatePlayerAchievement(client);
			}
		}
	}
	
	g_iTriggerFinale = CreateEntityByName("trigger_finale");
	DispatchKeyValue(g_iTriggerFinale, "VersusTravelCompletion", "0.0");
	DispatchKeyValue(g_iTriggerFinale, "type", "2");
	DispatchKeyValue(g_iTriggerFinale, "model", RADIO_MODEL);
	DispatchKeyValue(g_iTriggerFinale, "ScriptFile", "Deathmatch_Finale");
	DispatchSpawn(g_iTriggerFinale);
	AcceptEntityInput(g_iTriggerFinale, "ForceFinaleStart");
	#if DEBUG
	LogMessage("[ENTITY MANAGER] Succesfully created the Trigger Finale entity (ID: %i)", g_iTriggerFinale);
	PrintToServer("[ENTITY MANAGER] Succesfully created the Trigger Finale entity (ID: %i)", g_iTriggerFinale);
	#endif
	
	#if !SDKHOOKS
	if(GetConVarBool(g_cvarWeaponManagerEnable) && !g_bWeaponManager)
	{
		CreateTimer(GetConVarFloat(g_cvarWeaponManagerTimeout), timerWeaponManagerSupport, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		g_bWeaponManager = true;
	}
	#endif
	decl String:map[256];
	GetCurrentMap(map, sizeof(map));
	
	//Delete possible entities that could interfere.
	new Handle:keyvalues = INVALID_HANDLE;
	decl String:KvFileName[256];
	new bool:FileFound = false;
	
	BuildPath(Path_SM, KvFileName, sizeof(KvFileName), "data/deathmatch/data_files/l4d2_deathmatch_relays.txt");
	
	if(!FileExists(KvFileName))
	{
		LogError("[ERROR] Unable to find the l4d2_deathmatch_relays.txt file, plugin is broken");
		FileFound = false;
	}
	else
	{
		FileFound = true;
	}
	
	if(FileFound)
	{
		keyvalues = CreateKeyValues("l4d2_deathmatch_relays");
		FileToKeyValues(keyvalues, KvFileName);
		KvRewind(keyvalues);
		decl String:relay[256];
		if(KvJumpToKey(keyvalues, map))
		{
			new total_relays = KvGetNum(keyvalues, "survival", 0);
			
			if(total_relays > 0)
			{
				decl String:relay_num[256];
				for(new relays = 1; relays <= total_relays; relays++)
				{
					Format(relay_num, sizeof(relay_num), "relay%i", relays);
					KvGetString(keyvalues, relay_num, relay, sizeof(relay), "invalid");
					if(!StrEqual(relay, "invalid"))
					{
						CheatCommand(_, "ent_fire", relay);
					}
				}
			}
		}
		CloseHandle(keyvalues);
	}
	
	
	PrintToChatAll("\x04Deathmatch have begun, kill them all!!!");
	PrintHintTextToAll("Deathmatch have begun, kill them all!!!");
	
	SetConVarString(hDifficulty, "Impossible", true, false);
	SetConVarInt(hIncapCount, 0, true, false);
	SetConVarInt(hGlowSurvivor, 1, true, false);
	SetConVarInt(hAllBot, 1, true, false);
	SetConVarInt(hNoCheck, 1, true, false);
	SetConVarInt(hBotFF, 1, true, false);
	SetConVarInt(hInfinite, 0, true, false);
	
	new Float:flCurrentTime = GetGameTime();
	if(!g_bEndDM)
	{
		CreateTimer(1.0, Timer_EndDM, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		g_bEndDM = true;
	}
	for(new i=1; i<=MaxClients; i++)
	{
		if(i <= 0 || !IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2)
		{
			continue;
		}
		g_flSpawnTime[i] = flCurrentTime;
		if(IsFakeClient(i))
		{
			ChooseRandomBoost(i);
		}
		if(!allowmusic[i])
		{
			PlayRandomTrack(i, SOUNDTYPE_MATCH);
		}
		SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
		decl Float:pos[3];
		pos = GetRandomRespawnPos();
		TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
	}
	#if DEBUG
	LogMessage("[DEATHMATCH] Choosed random boosts for fake clients");
	PrintToServer("[DEATHMATCH] Choosed random boosts for fake clients");
	#endif
}

public Action:StopDeathmatch()
{	
	deathmatch = false;
	#if DEBUG
	LogMessage("[DEATHMATCH END] --------------------Deathmatch end call------------------");
	#endif
	SetConVarInt(hStop, 1, true, false);
	#if DEBUG
	LogMessage("[DEATHMATCH END] Bots stopped");
	LogMessage("[DEATHMATCH END] Proceed to loop clients");
	#endif
	for(new i=1; i<=MaxClients; i++)
	{
		if(i > 0 && IsValidEntity(i) && IsValidEdict(i) && IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			#if DEBUG
			LogMessage("[DEATHMATCH END] Client %i passed the filters", i);
			#endif
			UpdateStats(i);
			
			#if DEBUG
			LogMessage("[DEATHMATCH END] Updating client stats");
			#endif
			EmitSoundToClient(i, "music/safe/themonsterswithout.wav");
			
			#if DEBUG
			LogMessage("[DEATHMATCH END] Emited the sound for the client");
			#endif
			if(GetConVarBool(g_cvarSSMenuRoundEnd))
			{
				BuildScoreMenu(i);
				#if DEBUG
				LogMessage("[DEATHMATCH END] Menu displayed for the client");
				#endif
			}
			SetEntDataFloat(i, FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue"), 0.0, true);
			#if DEBUG
			LogMessage("[DEATHMATCH END] Player cant move");
			#endif
			PrintToChat(i, "\x03Deathmatch mode is over!");
			PrintToChat(i, "\x04Kills: %i , Deaths: %i , Score: %i", kills[i], deaths[i], score[i]);
			PrintHintText(i, "Deathmatch mode is over!");
			SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
		}
		else if(i > 0 && IsValidEntity(i) && IsValidEdict(i) && IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i))
		{
			SetEntDataFloat(i, FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue"), 0.0, true);
			SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
		}
	}
	#if DEBUG
	LogMessage("[DEATHMATCH END] End of clients loop");
	#endif
	
	CreateTimer(20.0, timerChangeMap, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(5.0, timerChangeMapAnnounce, TIMER_FLAG_NO_MAPCHANGE);
	#if DEBUG
	LogMessage("[DEATHMATCH END] Map change timer created");
	#endif
	new winner = g_iWinner;
	if(!g_bIWin[winner])
	{
		g_bIWin[winner] = true;
		decl String:name[256];
		GetClientName(winner, name, sizeof(name));
		decl String:content[512];
		Format(content, sizeof(content), "\x05%s \x01earned the \x05BORN TO KILL \x01achievement by winning a deathmatch game for the first time!", name);
		PrintToChatAllDM(content);
		UpdatePlayerAchievement(winner);
	}
	#if DEBUG
	LogMessage("[DEATHMATCH END] --------------------Deathmatch end call completed------------------");
	#endif
}

public Action:timerChangeMapAnnounce(Handle:timer)
{
	PrintToChatAll("\x04The next map will be loaded in a few moments");
}

public Action:timerChangeMap(Handle:timer)
{
	#if DEBUG
	LogMessage("[DEATHMATCH] Change map called, getting random map");
	#endif
	decl String:mapname[256];
	if(GetConVarBool(g_cvarDeathmatchMapMode))
	{
		GetRandomValidMap(mapname, sizeof(mapname));
	}
	else
	{
		GetNextValidMap(mapname, sizeof(mapname));
	}
	#if DEBUG
	LogMessage("[DEATHMATCH] The selected map is %s", mapname);
	#endif
	ServerCommand("changelevel %s", mapname);
}

stock GetNextValidMap(String:map[], maxlen)
{
	decl String:currentmap[256], String:KvFileName[256];
	GetCurrentMap(currentmap, sizeof(currentmap));
	new bool:FileFound = false;
	new bool:MapFound = false;
	new Handle:keyvalues = INVALID_HANDLE;
	
	BuildPath(Path_SM, KvFileName, 128, "data/deathmatch/l4d2_deathmatch_mapline.txt");
	
	if(!FileExists(KvFileName))
	{
		LogMessage("[WARNING] Unable to find the l4d2_deathmatch_mapline.txt file, proceed to default map line!");
		FileFound = false;
	}
	else
	{
		FileFound = true;
	}
	
	if(FileFound)
	{
		keyvalues = CreateKeyValues("l4d2_deathmatch_coordinates");
		FileToKeyValues(keyvalues, KvFileName);
		KvRewind(keyvalues);
		if(KvJumpToKey(keyvalues, currentmap))
		{
			MapFound = true;
			KvGetString(keyvalues, "next map", map, maxlen, "c1m1_hotel");
			CloseHandle(keyvalues);
			return;
		}
		CloseHandle(keyvalues);
		MapFound = false;
		
	}
	if(!FileFound || !MapFound)
	{
		if(StrEqual(currentmap, "c1m1_hotel"))
		{
			Format(map, maxlen, "c1m4_atrium");
		}
		else if(StrEqual(currentmap, "c1m4_atrium"))
		{
			Format(map, maxlen, "c2m1_highway");
		}
		else if(StrEqual(currentmap, "c2m1_highway"))
		{
			Format(map, maxlen, "c2m4_barns");
		}
		else if(StrEqual(currentmap, "c2m4_barns"))
		{
			Format(map, maxlen, "c2m5_concert");
		}
		else if(StrEqual(currentmap, "c2m5_concert"))
		{
			Format(map, maxlen, "c3m4_plantation");
		}
		else if(StrEqual(currentmap, "c3m4_plantation"))
		{
			Format(map, maxlen, "c4m5_milltown_escape");
		}
		else if(StrEqual(currentmap, "c4m5_milltown_escape"))
		{
			Format(map, maxlen, "c5m1_waterfront");
		}
		else if(StrEqual(currentmap, "c5m1_waterfront"))
		{
			Format(map, maxlen, "c5m2_park");
		}
		else if(StrEqual(currentmap, "c5m2_park"))
		{
			Format(map, maxlen, "c5m5_bridge");
		}
		else if(StrEqual(currentmap, "c5m5_bridge"))
		{
			Format(map, maxlen, "c1m1_hotel");
		}
		else
		{
			Format(map, maxlen, "c1m1_hotel");
		}
	}
	CloseHandle(keyvalues);
}

GetRandomValidMap(String:map[], maxlen)
{
	new number = GetRandomInt(1,26);
	switch(number)
	{
		case 1:
		{
			Format(map, maxlen, "c1m4_atrium");
		}
		case 2:
		{
			Format(map, maxlen, "c2m1_highway");
		}
		case 3:
		{
			Format(map, maxlen, "c2m2_fairgrounds");
		}
		case 4:
		{
			Format(map, maxlen, "c2m3_coaster");
		}
		case 5:
		{
			Format(map, maxlen, "c2m4_barns");
		}
		case 6:
		{
			Format(map, maxlen, "c2m5_concert");
		}
		case 7:
		{
			Format(map, maxlen, "c3m1_plankcountry");
		}
		case 8:
		{
			Format(map, maxlen, "c3m2_swamp");
		}
		case 9:
		{
			Format(map, maxlen, "c3m3_shantytown");
		}
		case 10:
		{
			Format(map, maxlen, "c3m4_plantation");
		}
		case 11:
		{
			Format(map, maxlen, "c4m1_milltown_a");
		}
		case 12:
		{
			Format(map, maxlen, "c4m2_sugarmill_a");
		}
		case 13:
		{
			Format(map, maxlen, "c4m3_sugarmill_b");
		}
		case 14:
		{
			Format(map, maxlen, "c4m4_milltown_b");
		}
		case 15:
		{
			Format(map, maxlen, "c4m5_milltown_escape");
		}
		case 16:
		{
			Format(map, maxlen, "c5m1_waterfront");
		}
		case 17:
		{
			Format(map, maxlen, "c5m2_park");
		}
		case 18:
		{
			Format(map, maxlen, "c5m3_cemetery");
		}
		case 19:
		{
			Format(map, maxlen, "c5m4_quarter");
		}
		case 20:
		{
			//Format(map, maxlen, "c5m5_bridge");
			Format(map, maxlen, "c6m1_riverbank");
		}
		case 21:
		{
			Format(map, maxlen, "c6m1_riverbank");
		}
		case 22:
		{
			Format(map, maxlen, "c6m2_bedlam");
		}
		case 23:
		{
			Format(map, maxlen, "c6m3_port");
		}
		case 24:
		{
			Format(map, maxlen, "c1m1_hotel");
		}
		case 25:
		{
			Format(map, maxlen, "c1m2_streets");
		}
		case 26:
		{
			Format(map, maxlen, "c1m3_mall");
		}
	}
}

GetRandomItemSpawn()
{
	decl String:weapon[256];
	switch(GetRandomInt(1, 15))
	{
		case 1:
		{
			Format(weapon, sizeof(weapon), "weapon_rifle");
		}
		case 2:
		{
			Format(weapon, sizeof(weapon), "weapon_rifle_ak47");
		}
		case 3:
		{
			Format(weapon, sizeof(weapon), "weapon_rifle_sg552");
		}
		case 4:
		{
			Format(weapon, sizeof(weapon), "weapon_autoshotgun");
		}
		case 5:
		{
			Format(weapon, sizeof(weapon), "weapon_shotgun_spas");
		}
		case 6:
		{
			Format(weapon, sizeof(weapon), "weapon_hunting_rifle");
		}
		case 7:
		{
			Format(weapon, sizeof(weapon), "weapon_sniper_military");
		}
		case 8:
		{
			Format(weapon, sizeof(weapon), "weapon_sniper_awp");
		}
		case 9:
		{
			Format(weapon, sizeof(weapon), "weapon_sniper_scout");
		}
		case 10:
		{
			Format(weapon, sizeof(weapon), "weapon_pistol_magnum");
		}
		case 11:
		{
			Format(weapon, sizeof(weapon), "weapon_rifle_sg552");
		}
		case 12:
		{
			Format(weapon, sizeof(weapon), "weapon_pipe_bomb");
		}
		case 13:
		{
			Format(weapon, sizeof(weapon), "weapon_adrenaline");
		}
		case 14:
		{
			Format(weapon, sizeof(weapon), "weapon_pain_pills");
		}
		case 15:
		{
			Format(weapon, sizeof(weapon), "weapon_vomitjar");
		}
	}
	new entity = CreateEntityByName(weapon);
	return entity;
}

Float:GetCenterCoordinates()
{
	decl Float:pos[3];
	decl String:map[256], String:KvFileName[256];
	GetCurrentMap(map, sizeof(map));
	
	new bool:FileFound = false;
	new bool:MapFound = false;
	new Handle:keyvalues = INVALID_HANDLE;
	
	BuildPath(Path_SM, KvFileName, 128, "data/deathmatch/l4d2_deathmatch_coordinates.txt");
	
	if(!FileExists(KvFileName))
	{
		LogMessage("[WARNING] Unable to find the l4d2_deathmatch_coordinates.txt file, proceed to get default random respawn positions!");
		FileFound = false;
	}
	else
	{
		FileFound = true;
	}

	if(FileFound)
	{
		keyvalues = CreateKeyValues("l4d2_deathmatch_coordinates");
		FileToKeyValues(keyvalues, KvFileName);
		if(KvJumpToKey(keyvalues, map))
		{
			MapFound = true;
			KvGetVector(keyvalues, "center position", pos);
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
			return pos;
		}
		else
		{
			MapFound = false;
		}
		CloseHandle(keyvalues);
	}

	if(!FileFound || !MapFound)
	{
		LogMessage("[WARNING] The current map was not found on the keyvalues file!");
		if(StrEqual(map, "c1m1_hotel"))
		{
			pos[0] = 606.0;
			pos[1] = 5753.0;
			pos[2] = 2847.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c1m2_streets"))
		{
			pos[0] = 1361.0;
			pos[1] = 2676.0;
			pos[2] = 572.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c1m3_mall"))
		{
			pos[0] = 5839.0;
			pos[1] = -2617.0;
			pos[2] = 280.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c1m4_atrium"))
		{
			pos[0] = -4427.0;
			pos[1] = -3595.0;
			pos[2] = 62.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c2m1_highway"))
		{
			pos[0] = 2039.0;
			pos[1] = 4907.0;
			pos[2] = -975.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c2m2_fairgrounds"))
		{
			pos[0] = -1675.0;
			pos[1] = -555.0;
			pos[2] = -127.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c2m3_coaster"))
		{
			pos[0] = -460.0;
			pos[1] = 4283.0;
			pos[2] = 128.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c2m4_barns"))
		{
			pos[0] = -387.0;
			pos[1] = 1135.0;
			pos[2] = -191.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c2m5_concert"))
		{
			pos[0] = -2286.0;
			pos[1]= 3280.0;
			pos[2] = -113.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c3m1_plankcountry"))
		{
			pos[0] = -7870.0;
			pos[1]= 7623.0;
			pos[2] = 15.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c3m2_swamp"))
		{
			pos[0] = -4998.0;
			pos[1]= 3899.0;
			pos[2] = 17.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c3m3_shantytown"))
		{
			pos[0] = -5293.0;
			pos[1]= 963.0;
			pos[2] = 126.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c3m4_plantation"))
		{
			pos[0] = 1650.0;
			pos[1]= 886.0;
			pos[2] = 127.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c4m1_milltown_a"))
		{
			pos[0] = -5717.0;
			pos[1]= 7306.0;
			pos[2] = 292.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c4m2_sugarmill_a"))
		{
			pos[0] = 3148.0;
			pos[1]= -6063.0;
			pos[2] = 101.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c4m3_sugarmill_b"))
		{
			pos[0] = -1476.0;
			pos[1]= -9286.0;
			pos[2] = 608.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c4m4_milltown_b"))
		{
			pos[0] = 1184.0;
			pos[1]= 4460.0;
			pos[2] = 217.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c4m5_milltown_escape"))
		{
			pos[0] = -5757.0;
			pos[1]= 7322.0;
			pos[2] = 292.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c5m1_waterfront"))
		{
			pos[0] = -2231.0;
			pos[1]= -1036.0;
			pos[2] = -375.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c5m2_park"))
		{
			pos[0] = -5959.0;
			pos[1]= -2226.0;
			pos[2] = -255.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c5m3_cemetery"))
		{
			pos[0] = 4240.0;
			pos[1]= 3456.0;
			pos[2] = 0.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c5m4_quarter"))
		{
			pos[0] = -737.0;
			pos[1]= 2191.0;
			pos[2] = 64.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c5m5_bridge"))
		{
			pos[0] = 8626.0;
			pos[1]= 2926.0;
			pos[2] = 192.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c6m1_riverbank"))
		{
			pos[0] = 453.0;
			pos[1]= -24.0;
			pos[2] = 572.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c6m2_bedlam"))
		{
			pos[0] = 1263.0;
			pos[1]= 948.0;
			pos[2] = -15.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		else if(StrEqual(map, "c6m3_port"))
		{
			pos[0] = 527.0;
			pos[1]= 944.0;
			pos[2] = 160.0;
			
			pos[0]+=GetRandomFloat(-50.0, 50.0);
			pos[1]+=GetRandomFloat(-50.0, 50.0);
		}
		return pos;
	}
	return pos;
}

Float:GetRandomRespawnPos()
{
	decl Float:pos[3];
	decl String:map[256], String:KvFileName[256];
	new bool:FileFound = false;
	new bool:MapFound = false;
	new NumberOfCoordinates;
	new Handle:keyvalues = INVALID_HANDLE;
	GetCurrentMap(map, sizeof(map));
	
	BuildPath(Path_SM, KvFileName, 128, "data/deathmatch/l4d2_deathmatch_coordinates.txt");
	
	if(!FileExists(KvFileName))
	{
		LogMessage("[WARNING] Unable to find the l4d2_deathmatch_coordinates.txt file, proceed to get default random respawn positions!");
		FileFound = false;
	}
	else
	{
		FileFound = true;
	}

	if(FileFound)
	{
		keyvalues = CreateKeyValues("l4d2_deathmatch_coordinates");
		FileToKeyValues(keyvalues, KvFileName);
		if(KvJumpToKey(keyvalues, map))
		{
			MapFound = true;
			NumberOfCoordinates = KvGetNum(keyvalues, "position number");
			if(NumberOfCoordinates > 50)
			{
				LogMessage("[WARNING] There cannot be more than 50 respawn positions per map!");
			}
			else if(NumberOfCoordinates <= 0)
			{
				LogMessage("[WARNING] There must be atleast 1 random respawn position!");
			}
			if(MapFound)
			{
				switch(GetRandomInt(1, NumberOfCoordinates))
				{
					case 1:
					{
						KvGetVector(keyvalues, "pos1", pos);
					}
					case 2:
					{
						KvGetVector(keyvalues, "pos2", pos);
					}
					case 3:
					{
						KvGetVector(keyvalues, "pos3", pos);
					}
					case 4:
					{
						KvGetVector(keyvalues, "pos4", pos);
					}
					case 5:
					{
						KvGetVector(keyvalues, "pos5", pos);
					}
					case 6:
					{
						KvGetVector(keyvalues, "pos6", pos);
					}
					case 7:
					{
						KvGetVector(keyvalues, "pos7", pos);
					}
					case 8:
					{
						KvGetVector(keyvalues, "pos8", pos);
					}
					case 9:
					{
						KvGetVector(keyvalues, "pos9", pos);
					}
					case 10:
					{
						KvGetVector(keyvalues, "pos10", pos);
					}
					case 11:
					{
						KvGetVector(keyvalues, "pos11", pos);
					}
					case 12:
					{
						KvGetVector(keyvalues, "pos12", pos);
					}
					case 13:
					{
						KvGetVector(keyvalues, "pos13", pos);
					}
					case 14:
					{
						KvGetVector(keyvalues, "pos14", pos);
					}
					case 15:
					{
						KvGetVector(keyvalues, "pos15", pos);
					}
					case 16:
					{
						KvGetVector(keyvalues, "pos16", pos);
					}
					case 17:
					{
						KvGetVector(keyvalues, "pos17", pos);
					}
					case 18:
					{
						KvGetVector(keyvalues, "pos18", pos);
					}
					case 19:
					{
						KvGetVector(keyvalues, "pos19", pos);
					}
					case 20:
					{
						KvGetVector(keyvalues, "pos20", pos);
					}
					case 21:
					{
						KvGetVector(keyvalues, "pos21", pos);
					}
					case 22:
					{
						KvGetVector(keyvalues, "pos22", pos);
					}
					case 23:
					{
						KvGetVector(keyvalues, "pos23", pos);
					}
					case 24:
					{
						KvGetVector(keyvalues, "pos24", pos);
					}
					case 25:
					{
						KvGetVector(keyvalues, "pos25", pos);
					}
					case 26:
					{
						KvGetVector(keyvalues, "pos26", pos);
					}
					case 27:
					{
						KvGetVector(keyvalues, "pos27", pos);
					}
					case 28:
					{
						KvGetVector(keyvalues, "pos28", pos);
					}
					case 29:
					{
						KvGetVector(keyvalues, "pos29", pos);
					}
					case 30:
					{
						KvGetVector(keyvalues, "pos30", pos);
					}
					case 31:
					{
						KvGetVector(keyvalues, "pos31", pos);
					}
					case 32:
					{
						KvGetVector(keyvalues, "pos32", pos);
					}
					case 33:
					{
						KvGetVector(keyvalues, "pos33", pos);
					}
					case 34:
					{
						KvGetVector(keyvalues, "pos34", pos);
					}
					case 35:
					{
						KvGetVector(keyvalues, "pos35", pos);
					}
					case 36:
					{
						KvGetVector(keyvalues, "pos36", pos);
					}
					case 37:
					{
						KvGetVector(keyvalues, "pos37", pos);
					}
					case 38:
					{
						KvGetVector(keyvalues, "pos38", pos);
					}
					case 39:
					{
						KvGetVector(keyvalues, "pos39", pos);
					}
					case 40:
					{
						KvGetVector(keyvalues, "pos40", pos);
					}
					case 41:
					{
						KvGetVector(keyvalues, "pos41", pos);
					}
					case 42:
					{
						KvGetVector(keyvalues, "pos42", pos);
					}
					case 43:
					{
						KvGetVector(keyvalues, "pos43", pos);
					}
					case 44:
					{
						KvGetVector(keyvalues, "pos44", pos);
					}
					case 45:
					{
						KvGetVector(keyvalues, "pos45", pos);
					}
					case 46:
					{
						KvGetVector(keyvalues, "pos46", pos);
					}
					case 47:
					{
						KvGetVector(keyvalues, "pos47", pos);
					}
					case 48:
					{
						KvGetVector(keyvalues, "pos48", pos);
					}
					case 49:
					{
						KvGetVector(keyvalues, "pos49", pos);
					}
					case 50:
					{
						KvGetVector(keyvalues, "pos50", pos);
					}
					default:
					{
						KvGetVector(keyvalues, "pos1", pos);
					}
				}
			}
			CloseHandle(keyvalues);
			return pos;
		}
		CloseHandle(keyvalues);
		MapFound = false;
	}
	
	if(!FileFound || !MapFound)
	{
		if(StrEqual(map, "c1m1_hotel"))
		{
			switch(GetRandomInt(1,12))
			{
				case 1:
				{
					pos[0] = 532.0;
					pos[1] = 6204.0;
					pos[2] = 2656.0;
				}
				case 2:
				{
					pos[0] = 573.0;
					pos[1] = 5292.0;
					pos[2] = 2656.0;
				}
				case 3:
				{
					pos[0] = 1164.0;
					pos[1] = 6085.0;
					pos[2] = 2656.0;
				}
				case 4:
				{
					pos[0] = 2212.0;
					pos[1] = 6059.0;
					pos[2] = 2656.0;
				}
				case 5:
				{
					pos[0] = 2062.0;
					pos[1] = 6942.0;
					pos[2] = 2656.0;
				}
				case 6:
				{
					pos[0] = 2005.0;
					pos[1] = 7782.0;
					pos[2] = 2560.0;
				}
				case 7:
				{
					pos[0] = 2191.0;
					pos[1] = 7216.0;
					pos[2] = 2464.0;
				}
				case 8:
				{
					pos[0] = 1990.0;
					pos[1] = 6849.0;
					pos[2] = 2464.0;
				}
				case 9:
				{
					pos[0] = 2236.0;
					pos[1] = 6085.0;
					pos[2] = 2464.0;
				}
				case 10:
				{
					pos[0] = 1502.0;
					pos[1] = 5058.0;
					pos[2] = 2464.0;
				}
				case 11:
				{
					pos[0] = 2490.0;
					pos[1] = 5364.0;
					pos[2] = 2464.0;
				}
				case 12:
				{
					pos[0] = 2165.0;
					pos[1] = 5829.0;
					pos[2] = 2464.0;
				}
			}
		}
		
		else if(StrEqual(map, "c1m2_streets"))
		{
			switch(GetRandomInt(1,10))
			{
				case 1:
				{
					pos[0] = -3598.0;
					pos[1] = 2185.0;
					pos[2] = 320.0;
				}
				case 2:
				{
					pos[0] = -3773.0;
					pos[1] = 2207.0;
					pos[2] = 128.0;
				}
				case 3:
				{
					pos[0] = -2587.0;
					pos[1] = 1286.0;
					pos[2] = 0.0;
				}
				case 4:
				{
					pos[0] = -2792.0;
					pos[1] = 3004.0;
					pos[2] = 0.0;
				}
				case 5:
				{
					pos[0] = -2215.0;
					pos[1] = 1037.0;
					pos[2] = 41.0;
				}
				case 6:
				{
					pos[0] = -1206.0;
					pos[1] = 4254.0;
					pos[2] = 138.0;
				}
				case 7:
				{
					pos[0] = -905.0;
					pos[1] = 2381.0;
					pos[2] = 324.0;
				}
				case 8:
				{
					pos[0] = 3609.0;
					pos[1] = 2559.0;
					pos[2] = 444.0;
				}
				case 9:
				{
					pos[0] = 903.0;
					pos[1] = 4876.0;
					pos[2] = 448.0;
				}
				case 10:
				{
					pos[0] = 2010.0;
					pos[1] = 4547.0;
					pos[2] = 455.0;
				}
			}
		}
		if(StrEqual(map, "c1m3_mall"))
		{
			switch(GetRandomInt(1,13))
			{
				case 1:
				{
					pos[0] = 7297.0;
					pos[1] = -2372.0;
					pos[2] = 24.0;
				}
				case 2:
				{
					pos[0] = 6456.0;
					pos[1] = -3590.0;
					pos[2] = 24.0;
				}
				case 3:
				{
					pos[0] = 5443.0;
					pos[1] = -3509.0;
					pos[2] = 0.0;
				}
				case 4:
				{
					pos[0] = 7321.0;
					pos[1] = -2433.0;
					pos[2] = 280.0;
				}
				case 5:
				{
					pos[0] = 7468.0;
					pos[1] = -3332.0;
					pos[2] = 280.0;
				}
				case 6:
				{
					pos[0] = 6088.0;
					pos[1] = -3299.0;
					pos[2] = 280.0;
				}
				case 7:
				{
					pos[0] = 5316.0;
					pos[1] = -1794.0;
					pos[2] = 280.0;
				}
				case 8:
				{
					pos[0] = 2961.0;
					pos[1] = -2249.0;
					pos[2] = 280.0;
				}
				case 9:
				{
					pos[0] = 2951.0;
					pos[1] = -3011.0;
					pos[2] = 0.0;
				}
				case 10:
				{
					pos[0] = 3985.0;
					pos[1] = -290.0;
					pos[2] = 0.0;
				}
				case 11:
				{
					pos[0] = 2270.0;
					pos[1] = -478.0;
					pos[2] = 64.0;
				}
				case 12:
				{
					pos[0] = 1901.0;
					pos[1] = -1930.0;
					pos[2] = 280.0;
				}
				case 13:
				{
					pos[0] = 1873.0;
					pos[1] = 235.0;
					pos[2] = 280.0;
				}
			}
		}
			
		if(StrEqual(map, "c1m4_atrium"))
		{
			switch(GetRandomInt(1,30))
			{
				case 1:
				{
					pos[0] = -5393.0;
					pos[1] = -4440.0;
					pos[2] = 0.0;
				}
				case 2:
				{
					pos[0] = -6131.0;
					pos[1] = -3361.0;
					pos[2] = 0.0;
				}
				case 3:
				{
					pos[0] = -5403.0;
					pos[1] = -3796.0;
					pos[2] = 35.0;
				}
				case 4:
				{
					pos[0] = -4932.0;
					pos[1] = -3305.0;
					pos[2] = 0.0;
				}
				case 5:
				{
					pos[0] = -4810.0;
					pos[1] = -2390.0;
					pos[2] = 0.0;
				}
				case 6:
				{
					pos[0] = -4106.0;
					pos[1] = -2368.0;
					pos[2] = 0.0;
				}
				case 7:
				{
					pos[0] = -3640.0;
					pos[1] = -3166.0;
					pos[2] = 0.0;
				}
				case 8:
				{
					pos[0] = -3041.0;
					pos[1] = -3136.0;
					pos[2] = 0.0;
				}
				case 9:
				{
					pos[0] = -2453.0;
					pos[1] = -3361.0;
					pos[2] = 0.0;
				}
				case 10:
				{
					pos[0] = -2460.0;
					pos[1] = -4164.0;
					pos[2] = 0.0;
				}
				case 11:
				{
					pos[0] = -2823.0;
					pos[1] = -4419.0;
					pos[2] = 0.0;
				}
				case 12:
				{
					pos[0] = -3047.0;
					pos[1] = -4538.0;
					pos[2] = 0.0;
				}
				case 13:
				{
					pos[0] = -3495.0;
					pos[1] = -3860.0;
					pos[2] = 38.0;
				}
				case 14:
				{
					pos[0] = -4916.0;
					pos[1] = -4289.0;
					pos[2] = 280.0;
				}
				case 15:
				{
					pos[0] = -3027.0;
					pos[1] = -4627.0;
					pos[2] = 280.0;
				}
				case 16:
				{
					pos[0] = -2911.0;
					pos[1] = -3100.0;
					pos[2] = 280.0;
				}
				case 17:
				{
					pos[0] = -3721.0;
					pos[1] = -3497.0;
					pos[2] = 317.0;
				}
				case 18:
				{
					pos[0] = -4934.0;
					pos[1] = -2778.0;
					pos[2] = 280.0;
				}
				case 19:
				{
					pos[0] = -5381.0;
					pos[1] = -3523.0;
					pos[2] = 317.0;
				}
				case 20:
				{
					pos[0] = -5717.0;
					pos[1] = -3100.0;
					pos[2] = 280.0;
				}
				case 21:
				{
					pos[0] = -6140.0;
					pos[1] = -3375.0;
					pos[2] = 280.0;
				}
				case 22:
				{
					pos[0] = -4425.0;
					pos[1] = -4637.0;
					pos[2] = 536.0;
				}
				case 23:
				{
					pos[0] = -3369.0;
					pos[1] = -4327.0;
					pos[2] = 536.0;
				}
				case 24:
				{
					pos[0] = -5849.0;
					pos[1] = -3095.0;
					pos[2] = 536.0;
				}
				case 25:
				{
					pos[0] = -5749.0;
					pos[1] = -3521.0;
					pos[2] = 573.0;
				}
				case 26:
				{
					pos[0] = -3868.0;
					pos[1] = -3124.0;
					pos[2] = 536.0;
				}
				case 27:
				{
					pos[0] = -4707.0;
					pos[1] = -4251.0;
					pos[2] = 792.0;
				}
				case 28:
				{
					pos[0] = -3615.0;
					pos[1] = -4251.0;
					pos[2] = 792.0;
				}
				case 29:
				{
					pos[0] = -3101.0;
					pos[1] = -3450.0;
					pos[2] = 536.0;
				}
				case 30:
				{
					pos[0] = -2605.0;
					pos[1] = -4399.0;
					pos[2] = 536.0;
				}
			}
		}
		
		else if(StrEqual(map, "c2m1_highway"))
		{
			switch(GetRandomInt(1, 18))
			{
				case 1:
				{
					pos[0] = 2037.0;
					pos[1] = 3509.0;
					pos[2] = -807.0;

				}
				case 2:
				{
					pos[0] = 1740.0;
					pos[1] = 3214.0;
					pos[2] = -807.0;

				}
				case 3:
				{
					pos[0] = 1591.0;
					pos[1] = 3222.0;
					pos[2] = -807.0;

				}
				case 4:
				{
					pos[0] = 1292.0;
					pos[1] = 3231.0;
					pos[2] = -807.0;

				}
				case 5:
				{
					pos[0] = 1150.0;
					pos[1] = 3213.0;
					pos[2] = -807.0;

				}
				case 6:
				{
					pos[0] = 707.0;
					pos[1] = 3309.0;
					pos[2] = -974.0;

				}
				case 7:
				{
					pos[0] = 881.0;
					pos[1] = 3983.0;
					pos[2] = -967.0;

				}
				case 8:
				{
					pos[0] = 890.0;
					pos[1] = 4723.0;
					pos[2] = -967.0;
				}
				case 9:
				{
					pos[0] = 905.0;
					pos[1] = 5324.0;
					pos[2] = -967.0;
				}
				case 10:
				{
					pos[0] = 1693.0;
					pos[1] = 5790.0;
					pos[2] = -967.0;
				}
				case 11:
				{
					pos[0] = 1850.0;
					pos[1] = 5817.0;
					pos[2] = -967.0;
				}
				case 12:
				{
					pos[0] = 2687.0;
					pos[1] = 5943.0;
					pos[2] = -967.0;
				}
				case 13:
				{
					pos[0] = 3835.0;
					pos[1] = 5941.0;
					pos[2] = -998.0;
				}
				case 14:
				{
					pos[0] = 2981.0;
					pos[1] = 5007.0;
					pos[2] = -975.0;
				}
				case 15:
				{
					pos[0] = 3045.0;
					pos[1] = 3952.0;
					pos[2] = -967.0;
				}
				case 16:
				{
					pos[0] = 1066.0;
					pos[1] = 5325.0;
					pos[2] = -807.0;
				}
				case 17:
				{
					pos[0] = 1056.0;
					pos[1] = 4709.0;
					pos[2] = -807.0;
				}
				case 18:
				{
					pos[0] = 928.0;
					pos[1] = 3977.0;
					pos[2] = -807.0;
				}
			}
		}
		else if(StrEqual(map, "c2m2_fairgrounds"))
		{
			switch(GetRandomInt(1,10))
			{
				case 1:
				{
					pos[0] = -625.0;
					pos[1] = 1363.0;
					pos[2] = -127.0;
				}
				case 2:
				{
					pos[0] = -2445.0;
					pos[1] = 1501.0;
					pos[2] = -115.0;
				}
				case 3:
				{
					pos[0] = -3618.0;
					pos[1] = 726.0;
					pos[2] = -127.0;
				}
				case 4:
				{
					pos[0] = -3673.0;
					pos[1] = 1050.0;
					pos[2] = -127.0;
				}
				case 5:
				{
					pos[0] = -3014.0;
					pos[1] = -1075.0;
					pos[2] = -56.0;
				}
				case 6:
				{
					pos[0] = -2754.0;
					pos[1] = 1428.0;
					pos[2] = -100.0;
				}
				case 7:
				{
					pos[0] = -3514.0;
					pos[1] = -1971.0;
					pos[2] = -127.0;
				}
				case 8:
				{
					pos[0] = 845.0;
					pos[1] = -50.0;
					pos[2] = 0.0;
				}
				case 9:
				{
					pos[0] = 193.0;
					pos[1] = -1011.0;
					pos[2] = 0.0;
				}
				case 10:
				{
					pos[0] = -711.0;
					pos[1] = 1329.0;
					pos[2] = -70.0;
				}
			}
		}
		else if(StrEqual(map, "c2m3_coaster"))
		{
			switch(GetRandomInt(1,9))
			{
				case 1:
				{
					pos[0] = 2821.0;
					pos[1] = 1839.0;
					pos[2] = -7.0;
				}
				case 2:
				{
					pos[0] = 1614.0;
					pos[1] = 2026.0;
					pos[2] = -7.0;
				}
				case 3:
				{
					pos[0] = 3249.0;
					pos[1] = 2857.0;
					pos[2] = -7.0;
				}
				case 4:
				{
					pos[0] = 2171.0;
					pos[1] = 3720.0;
					pos[2] = -7.0;
				}
				case 5:
				{
					pos[0] = 2172.0;
					pos[1] = 3704.0;
					pos[2] = -7.0;
				}
				case 6:
				{
					pos[0] = 590.0;
					pos[1] = 4202.0;
					pos[2] = -7.0;
				}
				case 7:
				{
					pos[0] = 434.0;
					pos[1] = 4813.0;
					pos[2] = 124.0;
				}
				case 8:
				{
					pos[0] = -350.0;
					pos[1] = 4521.0;
					pos[2] = 128.0;
				}
				case 9:
				{
					pos[0] = 271.0;
					pos[1] = 3914.0;
					pos[2] = 218.0;
				}
			}
		}
		
		else if(StrEqual(map, "c2m4_barns"))
		{
			switch(GetRandomInt(1,8))
			{
				case 1:
				{
					pos[0] = -1994.0;
					pos[1] = 843.0;
					pos[2] = -183.0;
				}
				case 2:
				{
					pos[0] = 48.0;
					pos[1] = 672.0;
					pos[2] = -191.0;
				}
				case 3:
				{
					pos[0] = 857.0;
					pos[1] = 2364.0;
					pos[2] = -191.0;
				}
				case 4:
				{
					pos[0] = 1158.0;
					pos[1] = 2062.0;
					pos[2] = -159.0;
				}
				case 5:
				{
					pos[0] = 1798.0;
					pos[1] = 2318.0;
					pos[2] = -191.0;
				}
				case 6:
				{
					pos[0] = 2933.0;
					pos[1] = 2324.0;
					pos[2] = -191.0;
				}
				case 7:
				{
					pos[0] = 3195.0;
					pos[1] = 1440.0;
					pos[2] = -183.0;
				}
				case 8:
				{
					pos[0] = 2804.0;
					pos[1] = 3899.0;
					pos[2] = -183.0;
				}
			}
		}
		else if(StrEqual(map, "c2m5_concert"))
		{
			switch(GetRandomInt(1,17))
			{
				case 1:
				{
					pos[0] = -1678.0;
					pos[1] = 1810.0;
					pos[2] = 128.0;
				}
				case 2:
				{
					pos[0] = -848.0;
					pos[1] = 2361.0;
					pos[2] = 128.0;
				}
				case 3:
				{
					pos[0] = -1016.0;
					pos[1] = 3056.0;
					pos[2] = -255.0;
				}
				case 4:
				{
					pos[0] = -1142.0;
					pos[1] = 3636.0;
					pos[2] = -255.0;
				}
				case 5:
				{
					pos[0] = -1726.0;
					pos[1] = 3683.0;
					pos[2] = -255.0;
				}
				case 6:
				{
					pos[0] = -1847.0;
					pos[1] = 3365.0;
					pos[2] = -175.0;
				}
				case 7:
				{
					pos[0] = -2841.0;
					pos[1] = 3695.0;
					pos[2] = -255.0;
				}
				case 8:
				{
					pos[0] = -2880.0;
					pos[1] = 3248.0;
					pos[2] = -255.0;
				}
				case 9:
				{
					pos[0] = -4023.0;
					pos[1] = 3385.0;
					pos[2] = 128.0;
				}
				case 10:
				{
					pos[0] = -3739.0;
					pos[1] = 2370.0;
					pos[2] = 128.0;
				}
				case 11:
				{
					pos[0] = -2896.0;
					pos[1] = 1806.0;
					pos[2] = 128.0;
				}
				case 12:
				{
					pos[0] = -2760.0;
					pos[1] = 2479.0;
					pos[2] = 191.0;
				}
				case 13:
				{
					pos[0] = -1858.0;
					pos[1] = 2464.0;
					pos[2] = 300.0;
				}
				case 14:
				{
					pos[0] = -2293.0;
					pos[1] = 3499.0;
					pos[2] = 352.0;
				}
				case 15:
				{
					pos[0] = -1899.0;
					pos[1] = 2619.0;
					pos[2] = -141.0;
				}
				case 16:
				{
					pos[0] = -2781.0;
					pos[1] = 2588.0;
					pos[2] = -125.0;
				}
				case 17:
				{
					pos[0] = -2307.0;
					pos[1] = 3141.0;
					pos[2] = -175.0;
				}
			}
		}
		
		else if(StrEqual(map, "c3m1_plankcountry"))
		{
			switch(GetRandomInt(1,8))
			{
				case 1:
				{
					pos[0] = -10632.0;
					pos[1] = 8711.0;
					pos[2] = 160.0;
				}
				case 2:
				{
					pos[0] = -10813.0;
					pos[1] = 10640.0;
					pos[2] = 160.0;
				}
				case 3:
				{
					pos[0] = -8816.0;
					pos[1] = 9970.0;
					pos[2] = 96.0;
				}
				case 4:
				{
					pos[0] = -7832.0;
					pos[1] = 8812.0;
					pos[2] = 64.0;
				}
				case 5:
				{
					pos[0] = -9175.0;
					pos[1] = 7610.0;
					pos[2] = 138.0;
				}
				case 6:
				{
					pos[0] = -9025.0;
					pos[1] = 6836.0;
					pos[2] = 109.0;
				}
				case 7:
				{
					pos[0] = -6903.0;
					pos[1] = 6228.0;
					pos[2] = 32.0;
				}
				case 8:
				{
					pos[0] = -6285.0;
					pos[1] = 6064.0;
					pos[2] = 32.0;
				}
			}
		}
		
		else if(StrEqual(map, "c3m2_swamp"))
		{
			switch(GetRandomInt(1,10))
			{
				case 1:
				{
					pos[0] = -2094.0;
					pos[1] = 2504.0;
					pos[2] = -15.0;
				}
				case 2:
				{
					pos[0] = -2842.0;
					pos[1] = 1836.0;
					pos[2] = -15.0;
				}
				case 3:
				{
					pos[0] = -3083.0;
					pos[1] = 3179.0;
					pos[2] = 14.0;
				}
				case 4:
				{
					pos[0] = -3588.0;
					pos[1] = 4007.0;
					pos[2] = -1.0;
				}
				case 5:
				{
					pos[0] = -4879.0;
					pos[1] = 5344.0;
					pos[2] = 16.0;
				}
				case 6:
				{
					pos[0] = -6273.0;
					pos[1] = 5603.0;
					pos[2] = 5.0;
				}
				case 7:
				{
					pos[0] = -6429.0;
					pos[1] = 3187.0;
					pos[2] = 16.0;
				}
				case 8:
				{
					pos[0] = -8678.0;
					pos[1] = 4789.0;
					pos[2] = 16.0;
				}
				case 9:
				{
					pos[0] = -8772.0;
					pos[1] = 6564.0;
					pos[2] = 16.0;
				}
				case 10:
				{
					pos[0] = -7681.0;
					pos[1] = 6592.0;
					pos[2] = -31.0;
				}
			}
		}
		else if(StrEqual(map, "c3m3_shantytown"))
		{
			switch(GetRandomInt(1,21))
			{
				case 1:
				{
					pos[0] = -5702.0;
					pos[1] = 759.0;
					pos[2] = 161.0;
				}
				case 2:
				{
					pos[0] = -5324.0;
					pos[1] = 195.0;
					pos[2] = 160.0;
				}
				case 3:
				{
					pos[0] = -4840.0;
					pos[1] = 660.0;
					pos[2] = 148.0;
				}
				case 4:
				{
					pos[0] = -4718.0;
					pos[1] = 1302.0;
					pos[2] = 161.0;
				}
				case 5:
				{
					pos[0] = -4583.0;
					pos[1] = 192.0;
					pos[2] = 125.0;
				}
				case 6:
				{
					pos[0] = -3933.0;
					pos[1] = 1005.0;
					pos[2] = 8.0;
				}
				case 7:
				{
					pos[0] = -3595.0;
					pos[1] = -311.0;
					pos[2] = 22.0;
				}
				case 8:
				{
					pos[0] = -1962.0;
					pos[1] = -775.0;
					pos[2] = -23.0;
				}
				case 9:
				{
					pos[0] = -3737.0;
					pos[1] = -1970.0;
					pos[2] = 5.0;
				}
				case 10:
				{
					pos[0] = -4736.0;
					pos[1] = -301.0;
					pos[2] = -9.0;
				}
				case 11:
				{
					pos[0] = -5521.0;
					pos[1] = -1564.0;
					pos[2] = 99.0;
				}
				case 12:
				{
					pos[0] = -5580.0;
					pos[1] = -3208.0;
					pos[2] = 115.0;
				}
				case 13:
				{
					pos[0] = -4074.0;
					pos[1] = -3526.0;
					pos[2] = -5.0;
				}
				case 14:
				{
					pos[0] = -3452.0;
					pos[1] = -3863.0;
					pos[2] = -8.0;
				}
				case 15:
				{
					pos[0] = -2960.0;
					pos[1] = -2097.0;
					pos[2] = 0.0;
				}
				case 16:
				{
					pos[0] = -1240.0;
					pos[1] = -3254.0;
					pos[2] = 1.0;
				}
				case 17:
				{
					pos[0] = -1831.0;
					pos[1] = -3915.0;
					pos[2] = -2.0;
				}
				case 18:
				{
					pos[0] = -4184.0;
					pos[1] = -2582.0;
					pos[2] = 268.0;
				}
				case 19:
				{
					pos[0] = -3888.0;
					pos[1] = -3092.0;
					pos[2] = 281.0;
				}
				case 20:
				{
					pos[0] = -4027.0;
					pos[1] = -2406.0;
					pos[2] = 161.0;
				}
				case 21:
				{
					pos[0] = -3765.0;
					pos[1] = -2023.0;
					pos[2] = 202.0;
				}
			}
		}
		
		else if(StrEqual(map, "c3m4_plantation"))
		{
			switch(GetRandomInt(1,12))
			{
				case 1:
				{
					pos[0] = 860.407043;
					pos[1] = 1620.0;
					pos[2] = 129.0;
				}
				case 2:
				{
					pos[0] = 600.0;
					pos[1] = 321.0;
					pos[2] = 131.0;
				}
				case 3:
				{
					pos[0] = 2299.0;
					pos[1] = 112.0;
					pos[2] = 132.0;
				}
				case 4:
				{
					pos[0] = 2978.0;
					pos[1] = 1638.0;
					pos[2] = 140.0;
				}
				case 5:
				{
					pos[0] = 2615.0;
					pos[1] = 126.0;
					pos[2] = 224.0;
				}
				case 6:
				{
					pos[0] = 2097.0;
					pos[1] = 9.0;
					pos[2] = 224.0;
				}
				case 7:
				{
					pos[0] = 1189.0;
					pos[1] = -485.0;
					pos[2] = 224.0;
				}
				case 8:
				{
					pos[0] = 2018.0;
					pos[1] = -411.0;
					pos[2] = 224.0;
				}
				case 9:
				{
					pos[0] = 2745.0;
					pos[1] = -457.0;
					pos[2] = 416.0;
				}
				case 10:
				{
					pos[0] = 1879.0;
					pos[1] = 202.0;
					pos[2] = 416.0;
				}
				case 11:
				{
					pos[0] = 1237.0;
					pos[1] = 118.0;
					pos[2] = 416.0;
				}
				case 12:
				{
					pos[0] = 1989.0;
					pos[1] = -61.0;
					pos[2] = 600.0;
				}
			}
		}
		
		else if(StrEqual(map, "c4m1_milltown_a"))
		{
			switch(GetRandomInt(1,13))
			{
				case 1:
				{
					pos[0] = -3311.0;
					pos[1] = 7676.0;
					pos[2] = 104.0;
				}
				case 2:
				{
					pos[0] = -1782.0;
					pos[1] = 8013.0;
					pos[2] = 95.0;
				}
				case 3:
				{
					pos[0] = -2065.0;
					pos[1] = 5746.0;
					pos[2] = 98.0;
				}
				case 4:
				{
					pos[0] = -462.0;
					pos[1] = 6334.0;
					pos[2] = 264.0;
				}
				case 5:
				{
					pos[0] = -847.0;
					pos[1] = 5684.0;
					pos[2] = 264.0;
				}
				case 6:
				{
					pos[0] = 196.0;
					pos[1] = 4429.0;
					pos[2] = 104.0;
				}
				case 7:
				{
					pos[0] = 139.0;
					pos[1] = 2642.0;
					pos[2] = 101.0;
				}
				case 8:
				{
					pos[0] = 2221.0;
					pos[1] = 2482.0;
					pos[2] = 104.0;
				}
				case 9:
				{
					pos[0] = 4214.0;
					pos[1] = 3478.0;
					pos[2] = 96.0;
				}
				case 10:
				{
					pos[0] = 4089.0;
					pos[1] = 1653.0;
					pos[2] = 184.0;
				}
				case 11:
				{
					pos[0] = 4262.0;
					pos[1] = -364.0;
					pos[2] = 104.0;
				}
				case 12:
				{
					pos[0] = 3977.0;
					pos[1] = -672.0;
					pos[2] = 96.0;
				}
				case 13:
				{
					pos[0] = 4461.0;
					pos[1] = -333.0;
					pos[2] = 96.0;
				}
			}
		}
		
		else if(StrEqual(map, "c4m2_sugarmill_a"))
		{
			switch(GetRandomInt(1,16))
			{
				case 1:
				{
					pos[0] = 2499.0;
					pos[1] = -4679.0;
					pos[2] = 123.0;
				}
				case 2:
				{
					pos[0] = 2796.0;
					pos[1] = -3704.0;
					pos[2] = 100.0;
				}
				case 3:
				{
					pos[0] = 1085.0;
					pos[1] = -3974.0;
					pos[2] =96.0;
				}
				case 4:
				{
					pos[0] = 335.0;
					pos[1] = -4452.0;
					pos[2] = 96.0;
				}
				case 5:
				{
					pos[0] = 2824.0;
					pos[1] = -5528.0;
					pos[2] = 106.0;
				}
				case 6:
				{
					pos[0] = 1442.0;
					pos[1] = -6223.0;
					pos[2] = 104.0;
				}
				case 7:
				{
					pos[0] = 1748.0;
					pos[1] = -5446.0;
					pos[2] = 106.0;
				}
				case 8:
				{
					pos[0] = 304.0;
					pos[1] = -5336.0;
					pos[2] = 96.0;
				}
				case 9:
				{
					pos[0] = 120.0;
					pos[1] = -5776.0;
					pos[2] = 102.0;
				}
				case 10:
				{
					pos[0] = -478.0;
					pos[1] = -6548.0;
					pos[2] = 113.0;
				}
				case 11:
				{
					pos[0] = -1282.0;
					pos[1] = -8314.0;
					pos[2] = 96.0;
				}
				case 12:
				{
					pos[0] = -459.0;
					pos[1] = -8812.0;
					pos[2] = 97.0;
				}
				case 13:
				{
					pos[0] = -1835.0;
					pos[1] = -8559.0;
					pos[2] = 368.0;
				}
				case 14:
				{
					pos[0] = -457.0;
					pos[1] = -8632.0;
					pos[2] = 612.0;
				}
				case 15:
				{
					pos[0] = -520.0;
					pos[1] = -9288.0;
					pos[2] = 608.0;
				}
				case 16:
				{
					pos[0] = -1828.0;
					pos[1] = -8993.0;
					pos[2] = 608.0;
				}
			}
		}
		
		else if(StrEqual(map, "c4m3_sugarmill_b"))
		{
			switch(GetRandomInt(1,10))
			{
				case 1:
				{
					pos[0] = -1671.0;
					pos[1] = -9331.0;
					pos[2] = 608.0;
				}
				case 2:
				{
					pos[0] = -716.0;
					pos[1] = -8613.0;
					pos[2] = 608.0;
				}
				case 3:
				{
					pos[0] = -470.0;
					pos[1] = -8603.0;
					pos[2] = 353.0;
				}
				case 4:
				{
					pos[0] = -1251.0;
					pos[1] = -8196.0;
					pos[2] = 96.0;
				}
				case 5:
				{
					pos[0] = 564.0;
					pos[1] = -8489.0;
					pos[2] = 96.0;
				}
				case 6:
				{
					pos[0] = 619.0;
					pos[1] = -7294.0;
					pos[2] = 107.0;
				}
				case 7:
				{
					pos[0] = 137.0;
					pos[1] = -5657.0;
					pos[2] = 101.0;
				}
				case 8:
				{
					pos[0] = 497.0;
					pos[1] = -5757.0;
					pos[2] = 104.0;
				}
				case 9:
				{
					pos[0] = 1609.0;
					pos[1] = -6230.0;
					pos[2] = 104.0;
				}
				case 10:
				{
					pos[0] = 1438.0;
					pos[1] = -5428.0;
					pos[2] = 228.0;
				}
			}
		}
		
		else if(StrEqual(map, "c4m4_milltown_b"))
		{
			switch(GetRandomInt(1,13))
			{
				case 1:
				{
					pos[0] = 1825.0;
					pos[1] = 3189.0;
					pos[2] = 298.0;
				}
				case 2:
				{
					pos[0] = 1546.0;
					pos[1] = 4516.0;
					pos[2] = 217.0;
				}
				case 3:
				{
					pos[0] = 1639.0;
					pos[1] = 4397.0;
					pos[2] = 217.0;
				}
				case 4:
				{
					pos[0] = 199.0;
					pos[1] = 4225.0;
					pos[2] = 104.0;
				}
				case 5:
				{
					pos[0] = -323.0;
					pos[1] = 4598.0;
					pos[2] = 104.0;
				}
				case 6:
				{
					pos[0] = 1759.0;
					pos[1] = 5053.0;
					pos[2] = 125.0;
				}
				case 7:
				{
					pos[0] = 1322.0;
					pos[1] = 6589.0;
					pos[2] = 120.0;
				}
				case 8:
				{
					pos[0] = 1659.0;
					pos[1] = 7149.0;
					pos[2] = 224.0;
				}
				case 9:
				{
					pos[0] = -367.0;
					pos[1] = 6354.0;
					pos[2] = 264.0;
				}
				case 10:
				{
					pos[0] = -448.0;
					pos[1] = 5685.0;
					pos[2] = 104.0;
				}
				case 11:
				{
					pos[0] = -1514.0;
					pos[1] = 6740.0;
					pos[2] = 121.0;
				}
				case 12:
				{
					pos[0] = -2024.0;
					pos[1] = 5384.0;
					pos[2] = 97.0;
				}
				case 13:
				{
					pos[0] = -1693.0;
					pos[1] = 7703.0;
					pos[2] = 96.0;
				}
			}
		}
		
		else if(StrEqual(map, "c4m5_milltown_escape"))
		{
			switch(GetRandomInt(1,11))
			{
				case 1:
				{
					pos[0] = -4131.0;
					pos[1] = 7712.0;
					pos[2] = 97.0;
				}
				case 2:
				{
					pos[0] = -4163.0;
					pos[1] = 6757.0;
					pos[2] = 97.0;
				}
				case 3:
				{
					pos[0] = -4694.0;
					pos[1] = 7151.0;
					pos[2] = 140.0;
				}
				case 4:
				{
					pos[0] = -4612.0;
					pos[1] = 8412.0;
					pos[2] = 97.0;
				}
				case 5:
				{
					pos[0] = -6103.0;
					pos[1] = 8967.0;
					pos[2] = 96.0;
				}
				case 6:
				{
					pos[0] = -6312.0;
					pos[1] = 8004.0;
					pos[2] = 95.0;
				}
				case 7:
				{
					pos[0] = -6159.0;
					pos[1] = 7736.0;
					pos[2] = 104.0;
				}
				case 8:
				{
					pos[0] = -6910.0;
					pos[1] = 7122.0;
					pos[2] = 95.0;
				}
				case 9:
				{
					pos[0] = -6598.0;
					pos[1] = 6657.0;
					pos[2] = 96.0;
				}
				case 10:
				{
					pos[0] = -6693.0;
					pos[1] = 8515.0;
					pos[2] = 97.0;
				}
				case 11:
				{
					pos[0] = -7143.0;
					pos[1] = 8506.0;
					pos[2] = 116.0;
				}
			}
		}
		
		else if(StrEqual(map, "c5m1_waterfront"))
		{
			switch(GetRandomInt(1,15))
			{
				case 1:
				{
					pos[0] = 202.0;
					pos[1] = -761.0;
					pos[2] = -367.0;
				}
				case 2:
				{
					pos[0] = 234.0;
					pos[1] = 996.0;
					pos[2] = -375.0;
				}
				case 3:
				{
					pos[0] = -479.0;
					pos[1] = 99.0;
					pos[2] = -370.0;
				}
				case 4:
				{
					pos[0] = -1571.0;
					pos[1] = -46.0;
					pos[2] = -375.0;
				}
				case 5:
				{
					pos[0] = -1599.0;
					pos[1] = -905.0;
					pos[2] = -215.0;
				}
				case 6:
				{
					pos[0] = -727.0;
					pos[1] = -1434.0;
					pos[2] = -375.0;
				}
				case 7:
				{
					pos[0] = -1544.0;
					pos[1] = -1714.0;
					pos[2] = -375.0;
				}
				case 8:
				{
					pos[0] = -3041.0;
					pos[1] = -2332.0;
					pos[2] = -375.0;
				}
				case 9:
				{
					pos[0] = -1750.0;
					pos[1] = -1442.0;
					pos[2] = -374.0;
				}
				case 10:
				{
					pos[0] = -2693.0;
					pos[1] = -1603.0;
					pos[2] = -375.0;
				}
				case 11:
				{
					pos[0] = -2086.0;
					pos[1] = -382.0;
					pos[2] = -336.0;
				}
				case 12:
				{
					pos[0] = -2263.0;
					pos[1] = -14.0;
					pos[2] = -367.0;
				}
				case 13:
				{
					pos[0] = -2503.0;
					pos[1] = -84.0;
					pos[2] = -367.0;
				}
				case 14:
				{
					pos[0] = -3180.0;
					pos[1] = 489.0;
					pos[2] = -375.0;
				}
				case 15:
				{
					pos[0] = -3284.0;
					pos[1] = -1144.0;
					pos[2] = -375.0;
				}
			}
		}
		
		else if(StrEqual(map, "c5m2_park"))
		{
			switch(GetRandomInt(1,14))
			{
				case 1:
				{
					pos[0] = -3283.0;
					pos[1] = -2889.0;
					pos[2] = -375.0;
				}
				case 2:
				{
					pos[0] = -3266.0;
					pos[1] = -1317.0;
					pos[2] = -375.0;
				}
				case 3:
				{
					pos[0] = -4552.0;
					pos[1] = -3017.0;
					pos[2] = -191.0;
				}
				case 4:
				{
					pos[0] = -4727.0;
					pos[1] = -1475.0;
					pos[2] = -191.0;
				}
				case 5:
				{
					pos[0] = -5009.0;
					pos[1] = -2206.0;
					pos[2] = -303.0;
				}
				case 6:
				{
					pos[0] = -5672.0;
					pos[1] = -3212.0;
					pos[2] = -254.0;
				}
				case 7:
				{
					pos[0] = -6616.0;
					pos[1] = -3223.0;
					pos[2] = -255.0;
				}
				case 8:
				{
					pos[0] = -8048.0;
					pos[1] = -3606.0;
					pos[2] = -244.0;
				}
				case 9:
				{
					pos[0] = -7352.0;
					pos[1] = -2112.0;
					pos[2] = -255.0;
				}
				case 10:
				{
					pos[0] = -7702.0;
					pos[1] = -937.0;
					pos[2] = -255.0;
				}
				case 11:
				{
					pos[0] = -7686.0;
					pos[1] = -707.0;
					pos[2] = -255.0;
				}
				case 12:
				{
					pos[0] = -7601.0;
					pos[1] = -257.0;
					pos[2] = -246.0;
				}
				case 13:
				{
					pos[0] = -8526.0;
					pos[1] = -2117.0;
					pos[2] = -247.0;
				}
				case 14:
				{
					pos[0] = -8648.0;
					pos[1] = -4105.0;
					pos[2] = -247.0;
				}
			}
		}
		
		else if(StrEqual(map, "c5m3_cemetery"))
		{
			switch(GetRandomInt(1,11))
			{
				case 1:
				{
					pos[0] = 3086.0;
					pos[1] = 5606.0;
					pos[2] = 0.0;
				}
				case 2:
				{
					pos[0] = 3701.0;
					pos[1] = 5166.0;
					pos[2] = 164.0;
				}
				case 3:
				{
					pos[0] = 3447.0;
					pos[1] = 4972.0;
					pos[2] = 8.0;
				}
				case 4:
				{
					pos[0] = 5089.0;
					pos[1] = 5076.0;
					pos[2] = 1.0;
				}
				case 5:
				{
					pos[0] = 4895.0;
					pos[1] = 3820.0;
					pos[2] = 2.0;
				}
				case 6:
				{
					pos[0] = 3129.0;
					pos[1] = 3713.0;
					pos[2] = 3.0;
				}
				case 7:
				{
					pos[0] = 4912.0;
					pos[1] = 3290.0;
					pos[2] = 2.0;
				}
				case 8:
				{
					pos[0] = 4654.0;
					pos[1] = 2298.0;
					pos[2] = 5.0;
				}
				case 9:
				{
					pos[0] = 3454.0;
					pos[1] = 3274.0;
					pos[2] = 32.0;
				}
				case 10:
				{
					pos[0] = 3350.0;
					pos[1] = 2487.0;
					pos[2] = 176.0;
				}
				case 11:
				{
					pos[0] = 2898.0;
					pos[1] = 2517.0;
					pos[2] = 176.0;
				}
			}
		}
		
		else if(StrEqual(map, "c5m4_quarter"))
		{
			switch(GetRandomInt(1,15))
			{
				case 1:
				{
					pos[0] = -2872.0;
					pos[1] = 4036.0;
					pos[2] = 80.0;
				}
				case 2:
				{
					pos[0] = -3437.0;
					pos[1] = 3482.0;
					pos[2] = 68.0;
				}
				case 3:
				{
					pos[0] = -3300.0;
					pos[1] = 3194.0;
					pos[2] = 224.0;
				}
				case 4:
				{
					pos[0] = -2209.0;
					pos[1] = 3113.0;
					pos[2] = 64.0;
				}
				case 5:
				{
					pos[0] = -3684.0;
					pos[1] = 3122.0;
					pos[2] = 64.0;
				}
				case 6:
				{
					pos[0] = -2357.0;
					pos[1] = 2280.0;
					pos[2] = 64.0;
				}
				case 7:
				{
					pos[0] = -1509.0;
					pos[1] = 3215.0;
					pos[2] = 64.0;
				}
				case 8:
				{
					pos[0] = -189.0;
					pos[1] = 2072.0;
					pos[2] = 64.0;
				}
				case 9:
				{
					pos[0] = -971.0;
					pos[1] = 2420.0;
					pos[2] = 64.0;
				}
				case 10:
				{
					pos[0] = -919.0;
					pos[1] = 1779.0;
					pos[2] = 80.0;
				}
				case 11:
				{
					pos[0] = -684.0;
					pos[1] = 2016.0;
					pos[2] = 224.0;
				}
				case 12:
				{
					pos[0] = -1104.0;
					pos[1] = 2392.0;
					pos[2] = 72.0;
				}
				case 13:
				{
					pos[0] = -1088.0;
					pos[1] = -2052.0;
					pos[2] = 72.0;
				}
				case 14:
				{
					pos[0] = -1131.0;
					pos[1] = 1817.0;
					pos[2] = 64.0;
				}
				case 15:
				{
					pos[0] = -976.0;
					pos[1] = -1468.0;
					pos[2] = 96.0;
				}
			}
		}
		
		else if(StrEqual(map, "c5m5_bridge"))
		{
			switch(GetRandomInt(1,16))
			{
				case 1:
				{
					pos[0] = 8387.0;
					pos[1] = 1579.0;
					pos[2] = 192.0;
				}
				case 2:
				{
					pos[0] = 8269.0;
					pos[1] = 2096.0;
					pos[2] = 195.0;
				}
				case 3:
				{
					pos[0] = 7542.0;
					pos[1] = 2083.0;
					pos[2] = 193.0;
				}
				case 4:
				{
					pos[0] = 9265.0;
					pos[1] = 2942.0;
					pos[2] = 201.0;
				}
				case 5:
				{
					pos[0] = 8956.0;
					pos[1] = 4852.0;
					pos[2] = 192.0;
				}
				case 6:
				{
					pos[0] = 9371.0;
					pos[1] = 2477.0;
					pos[2] = 383.0;
				}
				case 7:
				{
					pos[0] = 9761.0;
					pos[1] = 3982.0;
					pos[2] = 460.0;
				}
				case 8:
				{
					pos[0] = 9544.0;
					pos[1] = 4718.0;
					pos[2] = 460.0;
				}
				case 9:
				{
					pos[0] = 8849.0;
					pos[1] = 5724.0;
					pos[2] = 456.0;
				}
				case 10:
				{
					pos[0] = 8444.0;
					pos[1] = 5689.0;
					pos[2] = 456.0;
				}
				case 11:
				{
					pos[0] = 7198.0;
					pos[1] = 3992.0;
					pos[2] = 168.0;
				}
				case 12:
				{
					pos[0] = 7665.0;
					pos[1] = 2640.0;
					pos[2] = 128.0;
				}
				case 13:
				{
					pos[0] = 6747.0;
					pos[1] = 6407.0;
					pos[2] = 455.0;
				}
				case 14:
				{
					pos[0] = 8051.0;
					pos[1] = 6481.0;
					pos[2] = 455.0;
				}
				case 15:
				{
					pos[0] = 8812.0;
					pos[1] = 6154.0;
					pos[2] = 460.0;
				}
				case 16:
				{
					pos[0] = 8040.0;
					pos[1] = 6402.0;
					pos[2] = 456.0;
				}
			}
		}
		
		else if(StrEqual(map, "c6m1_riverbank"))
		{
			switch(GetRandomInt(1,17))
			{
				case 1:
				{
					pos[0] = -3306.0;
					pos[1] = 312.0;
					pos[2] = 640.0;
				}
				case 2:
				{
					pos[0] = -2428.0;
					pos[1] = 324.0;
					pos[2] = 640.0;
				}
				case 3:
				{
					pos[0] = -2780.0;
					pos[1] = 186.0;
					pos[2] = 640.0;
				}
				case 4:
				{
					pos[0] = -2881.0;
					pos[1] = -913.0;
					pos[2] = 640.0;
				}
				case 5:
				{
					pos[0] = -2376.0;
					pos[1] = -1049.0;
					pos[2] = 640.0;
				}
				case 6:
				{
					pos[0] = -3221.0;
					pos[1] = -1103.0;
					pos[2] = 640.0;
				}
				case 7:
				{
					pos[0] = -1722.0;
					pos[1] = -934.0;
					pos[2] = 640.0;
				}
				case 8:
				{
					pos[0] = -1729.0;
					pos[1] = 217.0;
					pos[2] = 640.0;
				}
				case 9:
				{
					pos[0] = -1567.0;
					pos[1] = 173.0;
					pos[2] = 640.0;
				}
				case 10:
				{
					pos[0] = -1558.0;
					pos[1] = -889.0;
					pos[2] = 640.0;
				}
				case 11:
				{
					pos[0] = 43.0;
					pos[1] = -988.0;
					pos[2] = 640.0;
				}
				case 12:
				{
					pos[0] = 777.0;
					pos[1] = -1086.0;
					pos[2] = 688.0;
				}
				case 13:
				{
					pos[0] = 1626.0;
					pos[1] = -969.0;
					pos[2] = 576.0;
				}
				case 14:
				{
					pos[0] = 332.0;
					pos[1] = 359.0;
					pos[2] = 512.0;
				}
				case 15:
				{
					pos[0] = 1570.0;
					pos[1] = 357.0;
					pos[2] = 511.0;
				}
				case 16:
				{
					pos[0] = 1694.0;
					pos[1] = 74.0;
					pos[2] = 576.0;
				}
				case 17:
				{
					pos[0] = 1731.0;
					pos[1] = -1068.0;
					pos[2] = 576.0;
				}
			}
		}
		
		else if(StrEqual(map, "c6m2_bedlam"))
		{
			switch(GetRandomInt(1,14))
			{
				case 1:
				{
					pos[0] = 1530.0;
					pos[1] = -1674.0;
					pos[2] = 32.0;
				}
				case 2:
				{
					pos[0] = 1553.0;
					pos[1] = -306.0;
					pos[2] = 64.0;
				}
				case 3:
				{
					pos[0] = 2412.0;
					pos[1] = 38.0;
					pos[2] = -15.0;
				}
				case 4:
				{
					pos[0] = 761.0;
					pos[1] = 116.0;
					pos[2] = -27.0;
				}
				case 5:
				{
					pos[0] = 734.0;
					pos[1] = 482.0;
					pos[2] = -15.0;
				}
				case 6:
				{
					pos[0] = 2080.0;
					pos[1] = 1530.0;
					pos[2] = -185.0;
				}
				case 7:
				{
					pos[0] = -313.0;
					pos[1] = 1437.0;
					pos[2] = -71.0;
				}
				case 8:
				{
					pos[0] = 188.0;
					pos[1] = 2838.0;
					pos[2] = -151.0;
				}
				case 9:
				{
					pos[0] = 360.0;
					pos[1] = 2733.0;
					pos[2] = -151.0;
				}
				case 10:
				{
					pos[0] = 112.0;
					pos[1] = 2264.0;
					pos[2] = 16.0;
				}
				case 11:
				{
					pos[0] = 143.0;
					pos[1] = 2364.0;
					pos[2] = 176.0;
				}
				case 12:
				{
					pos[0] = 90.0;
					pos[1] = 3389.0;
					pos[2] = 8.0;
				}
				case 13:
				{
					pos[0] = 1244.0;
					pos[1] = 5011.0;
					pos[2] = 32.0;
				}
				case 14:
				{
					pos[0] = 2166.0;
					pos[1] = 4121.0;
					pos[2] = -158.0;
				}
			}
		}
		
		else if(StrEqual(map, "c6m3_port"))
		{
			switch(GetRandomInt(1,13))
			{
				case 1:
				{
					pos[0] = -1444.0;
					pos[1] = -483.0;
					pos[2] = 0.0;
				}
				case 2:
				{
					pos[0] = -1087.0;
					pos[1] = -341.0;
					pos[2] = 160.0;
				}
				case 3:
				{
					pos[0] = -731.0;
					pos[1] = 165.0;
					pos[2] = 160.0;
				}
				case 4:
				{
					pos[0] = -1561.0;
					pos[1] = -763.0;
					pos[2] = 160.0;
				}
				case 5:
				{
					pos[0] = -1822.0;
					pos[1] = 1824.0;
					pos[2] = 160.0;
				}
				case 6:
				{
					pos[0] = -931.0;
					pos[1] = 2114.0;
					pos[2] = 320.0;
				}
				case 7:
				{
					pos[0] = -2512.0;
					pos[1] = 434.0;
					pos[2] = 3.0;
				}
				case 8:
				{
					pos[0] = 474.0;
					pos[1] = 2026.0;
					pos[2] = 160.0;
				}
				case 9:
				{
					pos[0] = 870.0;
					pos[1] = 964.0;
					pos[2] = 0.0;
				}
				case 10:
				{
					pos[0] = 1837.0;
					pos[1] = 1206.0;
					pos[2] = -95.0;
				}
				case 11:
				{
					pos[0] = 1986.0;
					pos[1] = -621.0;
					pos[2] = 0.0;
				}
				case 12:
				{
					pos[0] = 665.0;
					pos[1] = -603.0;
					pos[2] = 160.0;
				}
				case 13:
				{
					pos[0] = 256.0;
					pos[1] = -1083.0;
					pos[2] = 414.0;
				}
			}
		}
	}
	return pos;
}
public Action:timerScriptsManager(Handle:timer)
{
	if(!g_bGameRunning)
	{
		return Plugin_Stop;
	}
	if(!deathmatch)
	{
		ServerCommand("script_execute Deathmatch_Idle");
	}
	if(deathmatch && g_bPanicProgress)
	{
		ServerCommand("script_execute Deathmatch_Reward");
	}
	if(deathmatch && !g_bPanicProgress)
	{
		ServerCommand("script_execute Deathmatch_Run");
	}
	return Plugin_Continue;
}

public Action:timerPositionManager(Handle:timer)
{
	if(deathmatch)
	{
		return Plugin_Stop;
	}
	if(!PlayersInGame())
	{
		return Plugin_Continue;
	}
	if(AllLoaded())
	{
		decl Float:pos[3];
		pos = GetCenterCoordinates();
		if(!(pos[0] == 0.0 && pos[1] == 0.0 && pos[2] == 0.0))
		{
			CreateTimer(15.0, timerPositions, _, TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Stop;
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
public Action:timerPositions(Handle:timer)
{
	for(new i=1; i<=MaxClients; i++)
	{
		LoadPlayer(i);
	}
	decl Float:pos[3];
	pos = GetCenterCoordinates();
	for(new i=1; i<=MaxClients; i++)
	{
		if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
			if(!IsFakeClient(i) && !allowmusic[i])
			{
				PlayRandomTrack(i, SOUNDTYPE_WAIT);
			}
		}
	}
	if(GetConVarBool(g_cvarDeathmatchAllowSurvival))
	{
		CreateTimer(2.5, timerSurvivalScript, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}
public Action:timerSurvivalScript(Handle:timer)
{
	decl String:map[256];
	GetCurrentMap(map, sizeof(map));
	new Handle:keyvalues = INVALID_HANDLE;
	decl String:KvFileName[256];
	new bool:FileFound = false;
	
	BuildPath(Path_SM, KvFileName, sizeof(KvFileName), "data/deathmatch/data_files/l4d2_deathmatch_relays.txt");
	
	if(!FileExists(KvFileName))
	{
		LogError("[ERROR] Unable to find the l4d2_deathmatch_relays.txt file, plugin is broken");
		FileFound = false;
	}
	else
	{
		FileFound = true;
	}
	
	if(FileFound)
	{
		keyvalues = CreateKeyValues("l4d2_deathmatch_relays");
		FileToKeyValues(keyvalues, KvFileName);
		KvRewind(keyvalues);
		decl String:relay[256];
		if(KvJumpToKey(keyvalues, map))
		{
			KvGetString(keyvalues, "survival", relay, sizeof(relay), "invalid");
			if(StrEqual(relay, "invalid"))
			{
				return;
			}
			CheatCommand(_, "ent_fire", relay);
		}
		CloseHandle(keyvalues);
	}
	CreateTimer(1.0, WipeEnt, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:BeginDM(Handle:timer)
{
	if(!g_bGameRunning || deathmatch)
	{
		#if DEBUG_SPECIAL
		LogMessage("[Deathmatch] The timer to being the match was canceled since it already started or the game isn't running");
		#endif
		g_bBeginDM = false;
		return Plugin_Stop;
	}
	if(!PlayersInGame())
	{
		PrintHintTextToAll("There are no players in the server!");
		#if TCDEBUG
		LogError("[DEATHMATCH] There are no players to beging the deathmatch");
		#endif
		return Plugin_Continue;
	}
	if(!AllLoaded())
	{
		PrintHintTextToAll("Waiting for everybody to load the game...");
		#if TCDEBUG
		LogError("[DEATHMATCH] Not everybody loaded the game");
		#endif
		return Plugin_Continue;
	}
	NumPrinted--;
	if(NumPrinted <= 0)
	{
		CreateDeathmatch(0);
		NumPrinted = GetConVarInt(g_cvarDeathmatchWarmUpDuration);
		g_bBeginDM = false;
		return Plugin_Stop;
	}
	PrintHintTextToAll("Deathmatch will begin in %i seconds. Get ready!", NumPrinted);
	return Plugin_Continue;
}

public Action:Timer_EndDM(Handle:timer)
{
	if(!deathmatch || !g_bGameRunning)
	{
		Countdown = GetConVarInt(g_cvarDeathmatchDuration);
		g_bEndDM = false;
		return Plugin_Stop;
	}
	
	if(!PlayersInGame())
	{
		PrintHintTextToAll("There are no players in the server! - Game Paused");
		return Plugin_Continue;
	}
	Countdown--;
	if(Countdown == 60)
	{
		PrintToChatAll("\x04Deathmatch will end in 60 seconds!");
		PrintHintTextToAll("Deathmatch will end in 60 seconds!");
	}
	if(Countdown == 30)
	{
		PrintHintTextToAll("Deathmatch will end in 30 seconds!");
		PrintToChatAll("\x04Deathmatch will end in 30 seconds!");
	}
	if(Countdown == 10)
	{
		PrintHintTextToAll("Deathmatch will end in 10 seconds!");
		PrintToChatAll("\x04Deathmatch will end in 10 seconds!");
	}
	if(Countdown <= 0)
	{
		StopDeathmatch();
		Countdown = GetConVarInt(g_cvarDeathmatchDuration);
		g_bEndDM = false;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:CheckDM(Handle:timer)
{
	if(deathmatch)
	{
		for(new i=1; i<=MaxClients; i++)
		{
			if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
			{
				SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
			}
		}
		return Plugin_Stop;
	}
	for(new i=1; i<=MaxClients; i++)
	{
		if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
		}
	}
	return Plugin_Continue;
}

stock CheatCommand(client = 0, String:command[], String:arguments[]="")
{
	if (!client || !IsClientInGame(client))
	{
		for (new target = 1; target <= MaxClients; target++)
		{
			if (IsClientInGame(target))
			{
				client = target;
				break;
			}
		}
		
		if (!client || !IsClientInGame(client)) return;
	}
	
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}

stock bool:HasBoost(client)
{
	if(!g_bExtraHealth[client] && !g_bExtraSpeed[client] && !g_bInstaMeleeKill[client] && !g_bMedic[client] && !g_bUpgrade[client] && !g_bExtraDmg[client] && !g_bVomitDeath[client])
	{
		return false;
	}
	else
	{
		return true;
	}
}

stock ChooseRandomBoost(client)
{
	g_bExtraHealth[client] = false;
	g_bExtraSpeed[client] = false;
	g_bInstaMeleeKill[client] = false;
	g_bMedic[client] = false;
	g_bUpgrade[client] = false;
	g_bExtraDmg[client] = false;
	g_bVomitDeath[client] = false;
	g_bSpitterDeath[client] = false;
	g_bInstantRespawn[client] = false;
	g_bNoFire[client] = false;
	g_bStalker[client] = false;
	g_bGodMode[client] = false;
	g_bNoIncap[client] = false;
	g_bFastCombat[client] = false;
	switch(GetRandomInt(0, 13))
	{
		case 0:
		{
			g_bExtraHealth[client] = true;
			SetEntityHealth(client, GetClientHealth(client)+GetConVarInt(g_cvarBSCalcHealth));
		}
		case 1:
		{
			g_bExtraSpeed[client] = true;
			new Float:total = FloatAdd(1.0, GetConVarFloat(g_cvarBSCalcSpeed));
			SetEntDataFloat(client, g_flLagMovement, total, true);
		}
		case 2:
		{
			g_bInstaMeleeKill[client] = true;
		}
		case 3:
		{
			g_bMedic[client] = true;
		}
		case 4:
		{
			g_bUpgrade[client] = true;
		}
		case 5:
		{
			g_bExtraDmg[client] = true;
		}
		case 6:
		{
			g_bVomitDeath[client] = true;
		}
		case 7:
		{
			g_bSpitterDeath[client] = true;
		}
		case 8:
		{
			g_bInstantRespawn[client] = true;
		}
		case 9:
		{
			g_bNoFire[client] = true;
		}
		case 10:
		{
			g_bStalker[client] = true;
		}
		case 11:
		{
			g_bGodMode[client] = true;
		}
		case 12:
		{
			g_bNoIncap[client] = true;
		}
		case 13:
		{
			g_bFastCombat[client] = true;
		}
	}
	if(!IsFakeClient(client))
	{
		PrintToChat(client, "\x03Type !boost to change your selected boost anytime");
	}
	g_bChoosedBoost[client] = true;
}

stock bool:PlayersInGame()
{
	new count = 0;
	for(new i=1; i<=MaxClients; i++)
	{
		if(i > 0 && IsValidEntity(i))
		{
			if(!IsFakeClient(i))
			{
				count++;
			}
		}
	}
	if(count <= 0)
	{
		return false;
	}
	else
	{
		return true;
	}
}
stock bool:AllLoaded()
{
	new totalcount = 0;
	new insidecount = 0;
	for(new i=1; i<=MaxClients; i++)
	{
		if(i > 0 && IsValidEntity(i))
		{
			if(!IsFakeClient(i))
			{
				if(IsClientInGame(i) && GetClientTeam(i) == 1 || GetClientTeam(i) == 3)
				{
					continue;
				}
				totalcount++;
				if(g_bInside[i])
				{
					insidecount++;
				}
			}
		}
	}
	if(totalcount == insidecount)
	{
		return true;
	}
	else
	{
		return false;
	}
}

stock SetUpAmmo(item)
{
	new ammo = 0;
	decl String:classname[256];
	GetEdictClassname(item, classname, sizeof(classname));
	if(StrEqual(classname, "weapon_rifle") || StrEqual(classname, "weapon_rifle_ak47") || StrEqual(classname, "weapon_rifle_desert") || StrEqual(classname, "weapon_rifle"))
	{
		ammo = 360;
	}
	else if(StrEqual(classname, "weapon_autoshotung") || StrEqual(classname, "weapon_shotgun_spas"))
	{
		ammo = 90;
	}
	else if(StrEqual(classname, "weapon_hunting_rifle"))
	{
		ammo = 150;
	}
	else if(StrEqual(classname, "weapon_sniper_military"))
	{
		ammo = 180;
	}
	else
	{
		return;
	}
	SetEntProp(item, Prop_Send, "m_iExtraPrimaryAmmo", ammo, 4);
	return;
}


public Action:OnDeathmatchGameFrame(Handle:timer)
{
	if(!g_bGameRunning)
	{
		return Plugin_Stop;
	}
	new count = GetAliveSurvivorCount();
	if(count <= 2)
	{
		EmergencyRespawn();
	}
	return Plugin_Continue;
}

stock GetAliveSurvivorCount()
{
	new count = 0;
	for(new i=1; i<=MaxClients; i++)
	{
		if(i > 0
		&& IsValidEntity(i)
		&& IsClientInGame(i)
		&& IsPlayerAlive(i)
		&& GetClientTeam(i) == 2)
		{
			count++;
		}
	}
	return count;
}

stock EmergencyRespawn()
{
	if(!deathmatch)
	{
		return;
	}
	for(new i=1; i<=MaxClients; i++)
	{
		if(i > 0
		&& IsValidEntity(i)
		&& IsClientInGame(i)
		&& !IsPlayerAlive(i)
		&& GetClientTeam(i) == 2)
		{
			CreateTimer(0.1, RespawnClient, i, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

//FAST RELOADING!
public OnGameFrame()
{
	//If server is not processing data or is loading, do nothing. This prevent lag or crashes.
	if (IsServerProcessing() && g_bGameRunning)
	{
		MA_OnGameFrame();
		DT_OnGameFrame();
	}
	
	if(!GetConVarBool(g_cvarDeathmatchDefib))
	{
		return;
	}
	if(!deathmatch)
	{
		return;
	}
	decl String:weap[256];
	for(new i=1; i<=MaxClients; i++)
	{
		//If the selected client was 0 or wasn't in game, discart
		//Checks: Is a survivor, is alive, is in game, has berserker running and the required convar is enabled
		if(i > 0 && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			GetClientWeapon(i, weap, sizeof(weap));
			if(!StrEqual(weap, "weapon_defibrillator"))
			{
				if(g_bExtraSpeed[i])
				{
					new Float:total = FloatAdd(1.0, GetConVarFloat(g_cvarBSCalcSpeed));
					SetEntDataFloat(i, g_flLagMovement, total, true);
				}
				else
				{
					SetEntDataFloat(i, g_flLagMovement, 1.0, true);
				}
			}
			else
			{			
				if(GetClientButtons(i) & IN_ATTACK)
				{
					SetEntDataFloat(i, g_flLagMovement, 1.7, true);
					//SetEntData(i, g_iShovePenalty, 0, 4);
				}
				else
				{
					if(g_bExtraSpeed[i])
					{
						new Float:total = FloatAdd(1.0, GetConVarFloat(g_cvarBSCalcSpeed));
						SetEntDataFloat(i, g_flLagMovement, total, true);
					}
					else
					{
						SetEntDataFloat(i, g_flLagMovement, 1.0, true);
					}
				}
			}
		}
	}
}

//This code belongs to Dusty1029, from here until it is specified, the code was made by him, and have no credits for it!
//On the start of a reload
AdrenReload (client)
{
	if (GetClientTeam(client) == 2)
	{
		#if TCDEBUG
		PrintToChatAll("\x03Client \x01%i\x03; start of reload detected",client );
		#endif
		new iEntid = GetEntDataEnt2(client, g_iActiveWO);
		if (IsValidEntity(iEntid)==false) return;
	
		decl String:stClass[32];
		GetEntityNetClass(iEntid,stClass,32);

		//for non-shotguns
		if (StrContains(stClass,"shotgun",false) == -1)
		{
			MagStart(iEntid, client);
			return;
		}
		//shotguns are a bit trickier since the game tracks per shell inserted
		//and there's TWO different shotguns with different values...
		else if (StrContains(stClass,"autoshotgun",false) != -1)
		{
			//create a pack to send clientid and gunid through to the timer
			new Handle:hPack = CreateDataPack();
			WritePackCell(hPack, client);
			WritePackCell(hPack, iEntid);
			CreateTimer(0.1,Timer_AutoshotgunStart,hPack);
			return;
		}
		else if (StrContains(stClass,"shotgun_spas",false) != -1)
		{
			//similar to the autoshotgun, create a pack to send
			new Handle:hPack = CreateDataPack();
			WritePackCell(hPack, client);
			WritePackCell(hPack, iEntid);
			CreateTimer(0.1,Timer_SpasShotgunStart,hPack);
			return;
		}
		else if (StrContains(stClass,"pumpshotgun",false) != -1 || StrContains(stClass,"shotgun_chrome",false) != -1)
		{
			new Handle:hPack = CreateDataPack();
			WritePackCell(hPack, client);
			WritePackCell(hPack, iEntid);
			CreateTimer(0.1,Timer_PumpshotgunStart,hPack);
			return;
		}
	}
}
// ////////////////////////////////////////////////////////////////////////////
//called for mag loaders
MagStart (iEntid, client)
{
	#if TCDEBUG
	PrintToChatAll("\x05-magazine loader detected,\x03 gametime \x01%f", GetGameTime());
	#endif
	new Float:flGameTime = GetGameTime();
	new Float:flNextTime_ret = GetEntDataFloat(iEntid,g_iNextPAttO);
	#if TCDEBUG
	PrintToChatAll("\x03- pre, gametime \x01%f\x03, retrieved nextattack\x01 %i %f\x03, retrieved time idle \x01%i %f",
		flGameTime,
		g_iNextAttO,
		GetEntDataFloat(client,g_iNextAttO),
		g_iTimeIdleO,
		GetEntDataFloat(iEntid,g_iTimeIdleO)
		);
	#endif

	//this is a calculation of when the next primary attack will be after applying reload values
	//NOTE: at this point, only calculate the interval itself, without the actual game engine time factored in
	
	new Float:flNextTime_calc = ( flNextTime_ret - flGameTime ) * g_fl_reload_rate ;
	
	//we change the playback rate of the gun, just so the player can "see" the gun reloading faster
	
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/g_fl_reload_rate, true);
	
	//create a timer to reset the playrate after time equal to the modified attack interval
	
	CreateTimer( flNextTime_calc, Timer_MagEnd, iEntid);
	
	//experiment to remove double-playback bug
	new Handle:hPack = CreateDataPack();
	WritePackCell(hPack, client);
	//this calculates the equivalent time for the reload to end
	new Float:flStartTime_calc = flGameTime - ( flNextTime_ret - flGameTime ) * ( 1 - g_fl_reload_rate ) ;
	WritePackFloat(hPack, flStartTime_calc);
	//now we create the timer that will prevent the annoying double playback
	if ( (flNextTime_calc - 0.4) > 0 )
		CreateTimer( flNextTime_calc - 0.4 , Timer_MagEnd2, hPack);
	//and finally we set the end reload time into the gun so the player can actually shoot with it at the end
	flNextTime_calc += flGameTime;
	SetEntDataFloat(iEntid, g_iTimeIdleO, flNextTime_calc, true);
	SetEntDataFloat(iEntid, g_iNextPAttO, flNextTime_calc, true);
	SetEntDataFloat(client, g_iNextAttO, flNextTime_calc, true);
	#if TCDEBUG
	PrintToChatAll("\x03- post, calculated nextattack \x01%f\x03, gametime \x01%f\x03, retrieved nextattack\x01 %i %f\x03, retrieved time idle \x01%i %f",
		flNextTime_calc,
		flGameTime,
		g_iNextAttO,
		GetEntDataFloat(client,g_iNextAttO),
		g_iTimeIdleO,
		GetEntDataFloat(iEntid,g_iTimeIdleO)
		);
	#endif
}

//called for autoshotguns
public Action:Timer_AutoshotgunStart (Handle:timer, Handle:hPack)
{
	KillTimer(timer);
	if (IsServerProcessing()==false)
		return Plugin_Stop;

	ResetPack(hPack);
	new iCid = ReadPackCell(hPack);
	new iEntid = ReadPackCell(hPack);
	CloseHandle(hPack);
	hPack = CreateDataPack();
	WritePackCell(hPack, iCid);
	WritePackCell(hPack, iEntid);

	if (iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid)==false
		|| IsValidEntity(iEntid)==false
		|| IsClientInGame(iCid)==false)
		return Plugin_Stop;

	#if TCDEBUG
	PrintToChatAll("\x03-autoshotgun detected, iEntid \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i",
		iEntid,
		g_iShotStartDurO,
		g_iShotInsertDurO,
		g_iShotEndDurO
		);
	PrintToChatAll("\x03- pre mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_fl_AutoS,
		0.4,
		g_fl_AutoE
		);
	#endif
		
	//then we set the new times in the gun
	SetEntDataFloat(iEntid,	g_iShotStartDurO,	g_fl_AutoS*g_fl_reload_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotInsertDurO,	0.4*g_fl_reload_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotEndDurO,		g_fl_AutoE*g_fl_reload_rate,	true);

	//we change the playback rate of the gun just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/g_fl_reload_rate, true);

	//and then call a timer to periodically check whether the gun is still reloading or not to reset the animation
	//but first check the reload state; if it's 2, then it needs a pump/cock before it can shoot again, and thus needs more time
	if (g_i_L4D_12 == 2)
		CreateTimer(0.3,Timer_ShotgunEnd,hPack,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	else if (g_i_L4D_12 == 1)
	{
		if (GetEntData(iEntid,g_iShotRelStateO)==2)
			CreateTimer(0.3,Timer_ShotgunEndCock,hPack,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		else
			CreateTimer(0.3,Timer_ShotgunEnd,hPack,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}

	#if TCDEBUG
	PrintToChatAll("\x03- after mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_fl_AutoS,
		0.4,
		g_fl_AutoE
		);
	#endif

	return Plugin_Stop;
}

public Action:Timer_SpasShotgunStart (Handle:timer, Handle:hPack)
{
	KillTimer(timer);
	if (IsServerProcessing()==false)
		return Plugin_Stop;

	ResetPack(hPack);
	new iCid = ReadPackCell(hPack);
	new iEntid = ReadPackCell(hPack);
	CloseHandle(hPack);
	hPack = CreateDataPack();
	WritePackCell(hPack, iCid);
	WritePackCell(hPack, iEntid);

	if (iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid)==false
		|| IsValidEntity(iEntid)==false
		|| IsClientInGame(iCid)==false)
		return Plugin_Stop;

	#if TCDEBUG
	PrintToChatAll("\x03-autoshotgun detected, iEntid \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i",
		iEntid,
		g_iShotStartDurO,
		g_iShotInsertDurO,
		g_iShotEndDurO
		);
	PrintToChatAll("\x03- pre mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_fl_SpasS,
		g_fl_SpasI,
		0.699999
		);
	#endif
		
	//then we set the new times in the gun
	SetEntDataFloat(iEntid,	g_iShotStartDurO,	g_fl_SpasS*g_fl_reload_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotInsertDurO,	g_fl_SpasI*g_fl_reload_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotEndDurO,		0.699999*g_fl_reload_rate,	true);

	//we change the playback rate of the gun just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/g_fl_reload_rate, true);

	//and then call a timer to periodically check whether the gun is still reloading or not to reset the animation
	//but first check the reload state; if it's 2, then it needs a pump/cock before it can shoot again, and thus needs more time
	CreateTimer(0.3,Timer_ShotgunEnd,hPack,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	#if TCDEBUG
	PrintToChatAll("\x03- after mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_fl_SpasS,
		g_fl_SpasI,
		0.699999
		);
	#endif

	return Plugin_Stop;
}

//called for pump/chrome shotguns
public Action:Timer_PumpshotgunStart (Handle:timer, Handle:hPack)
{
	KillTimer(timer);
	if (IsServerProcessing()==false)
		return Plugin_Stop;

	ResetPack(hPack);
	new iCid = ReadPackCell(hPack);
	new iEntid = ReadPackCell(hPack);
	CloseHandle(hPack);
	hPack = CreateDataPack();
	WritePackCell(hPack, iCid);
	WritePackCell(hPack, iEntid);

	if (iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid)==false
		|| IsValidEntity(iEntid)==false
		|| IsClientInGame(iCid)==false)
		return Plugin_Stop;

	#if TCDEBUG
	PrintToChatAll("\x03-pumpshotgun detected, iEntid \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i",
		iEntid,
		g_iShotStartDurO,
		g_iShotInsertDurO,
		g_iShotEndDurO
		);
	PrintToChatAll("\x03- pre mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_fl_PumpS,
		g_fl_PumpI,
		g_fl_PumpE
		);
	#endif

	//then we set the new times in the gun
	SetEntDataFloat(iEntid,	g_iShotStartDurO,	g_fl_PumpS*g_fl_reload_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotInsertDurO,	g_fl_PumpI*g_fl_reload_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotEndDurO,		g_fl_PumpE*g_fl_reload_rate,	true);

	//we change the playback rate of the gun just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/g_fl_reload_rate, true);

	//and then call a timer to periodically check whether the gun is still reloading or not to reset the animation
	if (g_i_L4D_12 == 2)
		CreateTimer(0.3,Timer_ShotgunEnd,hPack,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	else if (g_i_L4D_12 == 1)
	{
		if (GetEntData(iEntid,g_iShotRelStateO)==2)
			CreateTimer(0.3,Timer_ShotgunEndCock,hPack,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		else
			CreateTimer(0.3,Timer_ShotgunEnd,hPack,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}

	#if TCDEBUG
	PrintToChatAll("\x03- after mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_fl_PumpS,
		g_fl_PumpI,
		g_fl_PumpE
		);
	#endif

	return Plugin_Stop;
}
// ////////////////////////////////////////////////////////////////////////////
//this resets the playback rate on non-shotguns
public Action:Timer_MagEnd (Handle:timer, any:iEntid)
{
	KillTimer(timer);
	if (IsServerProcessing()==false)
		return Plugin_Stop;

	#if TCDEBUG
	PrintToChatAll("\x03Reset playback, magazine loader");
	#endif

	if (iEntid <= 0
		|| IsValidEntity(iEntid)==false)
		return Plugin_Stop;

	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0, true);

	return Plugin_Stop;
}

public Action:Timer_MagEnd2 (Handle:timer, Handle:hPack)
{
	KillTimer(timer);
	if (IsServerProcessing()==false)
	{
		CloseHandle(hPack);
		return Plugin_Stop;
	}

	#if TCDEBUG
	PrintToChatAll("\x03Reset playback, magazine loader");
	#endif

	ResetPack(hPack);
	new iCid = ReadPackCell(hPack);
	new Float:flStartTime_calc = ReadPackFloat(hPack);
	CloseHandle(hPack);

	if (iCid <= 0
		|| IsValidEntity(iCid)==false
		|| IsClientInGame(iCid)==false)
		return Plugin_Stop;

	//experimental, remove annoying double-playback
	new iVMid = GetEntDataEnt2(iCid,g_iViewModelO);
	SetEntDataFloat(iVMid, g_iVMStartTimeO, flStartTime_calc, true);

	#if TCDEBUG
	PrintToChatAll("\x03- end mag loader, icid \x01%i\x03 starttime \x01%f\x03 gametime \x01%f", iCid, flStartTime_calc, GetGameTime());
	#endif

	return Plugin_Stop;
}

public Action:Timer_ShotgunEnd (Handle:timer, Handle:hPack)
{
	#if TCDEBUG
	PrintToChatAll("\x03-autoshotgun tick");
	#endif

	ResetPack(hPack);
	new iCid = ReadPackCell(hPack);
	new iEntid = ReadPackCell(hPack);

	if (IsServerProcessing()==false
		|| iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid)==false
		|| IsValidEntity(iEntid)==false
		|| IsClientInGame(iCid)==false)
	{
		KillTimer(timer);
		return Plugin_Stop;
	}

	if (GetEntData(iEntid,g_iShotRelStateO)==0)
	{
		#if TCDEBUG
		PrintToChatAll("\x03-shotgun end reload detected");
		#endif

		SetEntDataFloat(iEntid, g_iPlayRateO, 1.0, true);

		//new iCid=GetEntPropEnt(iEntid,Prop_Data,"m_hOwner");
		new Float:flTime=GetGameTime()+0.2;
		SetEntDataFloat(iCid,	g_iNextAttO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iTimeIdleO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iNextPAttO,	flTime,	true);

		KillTimer(timer);
		CloseHandle(hPack);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}
// ////////////////////////////////////////////////////////////////////////////
//since cocking requires more time, this function does
//exactly as the above, except it adds slightly more time
public Action:Timer_ShotgunEndCock (Handle:timer, any:hPack)
{
	#if TCDEBUG
	PrintToChatAll("\x03-autoshotgun tick");
	#endif

	ResetPack(hPack);
	new iCid = ReadPackCell(hPack);
	new iEntid = ReadPackCell(hPack);

	if (IsServerProcessing()==false
		|| iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid)==false
		|| IsValidEntity(iEntid)==false
		|| IsClientInGame(iCid)==false)
	{
		KillTimer(timer);
		return Plugin_Stop;
	}

	if (GetEntData(iEntid,g_iShotRelStateO)==0)
	{
		#if TCDEBUG
		PrintToChatAll("\x03-shotgun end reload + cock detected");
		#endif

		SetEntDataFloat(iEntid, g_iPlayRateO, 1.0, true);

		//new iCid=GetEntPropEnt(iEntid,Prop_Data,"m_hOwner");
		new Float:flTime= GetGameTime() + 1.0;
		SetEntDataFloat(iCid,	g_iNextAttO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iTimeIdleO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iNextPAttO,	flTime,	true);

		KillTimer(timer);
		CloseHandle(hPack);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

RebuildAll ()
{
	MA_Rebuild();
	DT_Rebuild();
}

ClearAll ()
{
	MA_Clear();
	DT_Clear();
}
// ////////////////////////////////////////////////////////////////////////////
//called whenever the registry needs to be rebuilt to cull any players who have left or died, etc.
//resets survivor's speeds and reassigns speed boost
//(called on: player death, player disconnect, adrenaline popped, adrenaline ended, -> change teams, convar change)
MA_Rebuild ()
{
	//clears all DT-related vars
	MA_Clear();
	//if the server's not running or is in the middle of loading, stop
	if (IsServerProcessing()==false)
		return;
	#if TCDEBUG
	PrintToChatAll("\x03Rebuilding melee registry");
	#endif
	decl Float:temphp;
	new hp, total;
	for (new iI=1 ; iI<=MaxClients ; iI++)
	{
		if (IsClientInGame(iI)==true && IsPlayerAlive(iI)==true && GetClientTeam(iI)==2 && g_bFastCombat[iI])
		{
			temphp = GetEntPropFloat(iI, Prop_Send, "m_healthBuffer");
			hp = GetClientHealth(iI);
			total = hp+RoundToFloor(temphp);
			if(total > GetConVarInt(g_cvarBSCalcFastMinAmount))
			{
				continue;
			}
			g_iMARegisterCount++;
			g_iMARegisterIndex[g_iMARegisterCount]=iI;
			#if TCDEBUG
			PrintToChatAll("\x03-registering \x01%i",iI);
			#endif
		}
	}
}

//called to clear out registry and reset movement speeds
//(called on: round start, round end, map end)
MA_Clear ()
{
	g_iMARegisterCount=0;
	#if TCDEBUG
	PrintToChatAll("\x03Clearing melee registry");
	#endif
	for (new iI=1 ; iI<=MaxClients ; iI++)
	{
		g_iMARegisterIndex[iI]= -1;
	}
}
// ////////////////////////////////////////////////////////////////////////////
//called whenever the registry needs to be rebuilt to cull any players who have left or died, etc.
//(called on: player death, player disconnect, closet rescue, change teams)
DT_Rebuild ()
{
	//clears all DT-related vars
	DT_Clear();

	//if the server's not running or is in the middle of loading, stop
	if (IsServerProcessing()==false)
		return;
	#if TCDEBUG
	PrintToChatAll("\x03Rebuilding weapon firing registry");
	#endif
	decl Float:temphp;
	new hp, total;
	for (new iI=1 ; iI<=MaxClients ; iI++)
	{
		if (IsClientInGame(iI)==true && IsPlayerAlive(iI)==true && GetClientTeam(iI)==2 && g_bFastCombat[iI])
		{
			temphp = GetEntPropFloat(iI, Prop_Send, "m_healthBuffer");
			hp = GetClientHealth(iI);
			total = hp+RoundToFloor(temphp);
			if(total > GetConVarInt(g_cvarBSCalcFastMinAmount))
			{
				continue;
			}
			g_iDTRegisterCount++;
			g_iDTRegisterIndex[g_iDTRegisterCount]=iI;
			#if TCDEBUG
			PrintToChatAll("\x03-registering \x01%i",iI);
			#endif
		}
	}
}

//called to clear out DT registry
//(called on: round start, round end, map end)
DT_Clear ()
{
	g_iDTRegisterCount=0;
	#if TCDEBUG
	PrintToChatAll("\x03Clearing weapon firing registry");
	#endif
	for (new iI=1 ; iI<=MaxClients ; iI++)
	{
		g_iDTRegisterIndex[iI]= -1;
		g_iDTEntid[iI] = -1;
		g_flDTNextTime[iI]= -1.0;
	}
}
/* ***************************************************************************/
//Since this is called EVERY game frame, we need to be careful not to run too many functions
//kinda hard, though, considering how many things we have to check for =.=
MA_OnGameFrame()
{
	// if plugin is disabled, don't bother
	// or if no one has MA, don't bother either
	if (g_iMARegisterCount==0)
		return 0;

	decl iCid;
	//this tracks the player's ability id
	decl iEntid;
	//this tracks the calculated next attack
	decl Float:flNextTime_calc;
	//this, on the other hand, tracks the current next attack
	decl Float:flNextTime_ret;
	//and this tracks the game time
	new Float:flGameTime=GetGameTime();

	//theoretically, to get on the MA registry, all the necessary checks would have already
	//been run, so we don't bother with any checks here
	for (new iI=1; iI<=g_iMARegisterCount; iI++)
	{
		if(!g_bFastCombat[iI])
		{
			continue;
		}
		//PRE-CHECKS 1: RETRIEVE VARS
		//---------------------------
		iCid = g_iMARegisterIndex[iI];
		//stop on this client when the next client id is null
		if (iCid <= 0) continue;
		if(!IsClientInGame(iCid)) continue;
		if(!IsClientConnected(iCid)) continue; 
		if (!IsPlayerAlive(iCid)) continue;
		if(GetClientTeam(iCid) != 2) continue;
		iEntid = GetEntDataEnt2(iCid,g_ActiveWeaponOffset);
		//if the retrieved gun id is -1, then...
		//wtf mate? just move on
		if (iEntid == -1) continue;
		//and here is the retrieved next attack time
		flNextTime_ret = GetEntDataFloat(iEntid,g_iNextPAttO);

		//CHECK 1: IS PLAYER USING A KNOWN NON-MELEE WEAPON?
		//--------------------------------------------------
		//as the title states... to conserve processing power,
		//if the player's holding a gun for a prolonged time
		//then we want to be able to track that kind of state
		//and not bother with any checks
		//checks: weapon is non-melee weapon
		//actions: do nothing
		if (iEntid == g_iMAEntid_notmelee[iCid])
		{
			// PrintToChatAll("\x03Client \x01%i\x03; non melee weapon, ignoring",iCid );
			continue;
		}

		//CHECK 1.5: THE PLAYER HASN'T SWUNG HIS WEAPON FOR A WHILE
		//---------------------------------------------------------
		//in this case, if the player made 1 swing of his 2 strikes, and then paused long enough, 
		//we should reset his strike count so his next attack will allow him to strike twice
		//checks: is the delay between attacks greater than 1.5s?
		//actions: set attack count to 0, and CONTINUE CHECKS
		if (g_iMAEntid[iCid] == iEntid
				&& g_iMAAttCount[iCid]!=0
				&& (flGameTime - flNextTime_ret) > 1.0)
		{
			#if TCDEBUG
			PrintToChatAll("\x03Client \x01%i\x03; hasn't swung weapon",iCid );
			#endif
			g_iMAAttCount[iCid]=0;
		}

		//CHECK 2: BEFORE ADJUSTED ATT IS MADE
		//------------------------------------
		//since this will probably be the case most of the time, we run this first
		//checks: weapon is unchanged; time of shot has not passed
		//actions: do nothing
		if (g_iMAEntid[iCid] == iEntid
				&& g_flMANextTime[iCid]>=flNextTime_ret)
		{
			// PrintToChatAll("\x03DT client \x01%i\x03; before shot made",iCid );
			continue;
		}

		//CHECK 3: AFTER ADJUSTED ATT IS MADE
		//------------------------------------
		//at this point, either a gun was swapped, or the attack time needs to be adjusted
		//checks: stored gun id same as retrieved gun id,
		//        and retrieved next attack time is after stored value
		//actions: adjusts next attack time
		if (g_iMAEntid[iCid] == iEntid
				&& g_flMANextTime[iCid] < flNextTime_ret)
		{
			//----TCDEBUG----
			//PrintToChatAll("\x03DT after adjusted shot\n-pre, client \x01%i\x03; entid \x01%i\x03; enginetime\x01 %f\x03; NextTime_orig \x01 %f\x03; interval \x01%f",iCid,iEntid,flGameTime,flNextTime_ret, flNextTime_ret-flGameTime );

			//this is a calculation of when the next primary attack will be after applying double tap values
			//flNextTime_calc = ( flNextTime_ret - flGameTime ) * g_flMA_attrate + flGameTime;
			flNextTime_calc = flGameTime + 0.45 ;
			// flNextTime_calc = flGameTime + melee_speed[iCid] ;

			//then we store the value
			g_flMANextTime[iCid] = flNextTime_calc;

			//and finally adjust the value in the gun
			SetEntDataFloat(iEntid, g_iNextPAttO, flNextTime_calc, true);

			#if TCDEBUG
			PrintToChatAll("\x03-post, NextTime_calc \x01 %f\x03; new interval \x01%f",GetEntDataFloat(iEntid,g_iNextPAttO), GetEntDataFloat(iEntid,g_iNextPAttO)-flGameTime );
			#endif

			continue;
		}

		//CHECK 4: CHECK THE WEAPON
		//-------------------------
		//lastly, at this point we need to check if we are, in fact, using a melee weapon =P
		//we check if the current weapon is the same one stored in memory; if it is, move on;
		//otherwise, check if it's a melee weapon - if it is, store and continue; else, continue.
		//checks: if the active weapon is a melee weapon
		//actions: store the weapon's entid into either
		//         the known-melee or known-non-melee variable

		#if TCDEBUG
		PrintToChatAll("\x03DT client \x01%i\x03; weapon switch inferred",iCid );
		#endif

		//check if the weapon is a melee
		decl String:stName[32];
		GetEntityNetClass(iEntid,stName,32);
		if (StrEqual(stName,"CTerrorMeleeWeapon",false)==true)
		{
			//if yes, then store in known-melee var
			g_iMAEntid[iCid]=iEntid;
			g_flMANextTime[iCid]=flNextTime_ret;
			continue;
		}
		else
		{
			//if no, then store in known-non-melee var
			g_iMAEntid_notmelee[iCid]=iEntid;
			continue;
		}
	}
	return 0;
}
// ////////////////////////////////////////////////////////////////////////////
DT_OnGameFrame()
{
	// if plugin is disabled, don't bother
	// or if no one has DT, don't bother either
	if (g_iDTRegisterCount==0)
		return;

	//this tracks the player's id, just to make life less painful...
	decl iCid;
	//this tracks the player's gun id since we adjust numbers on the gun, not the player
	decl iEntid;
	//this tracks the calculated next attack
	decl Float:flNextTime_calc;
	//this, on the other hand, tracks the current next attack
	decl Float:flNextTime_ret;
	//and this tracks next melee attack times
	decl Float:flNextTime2_ret;
	//and this tracks the game time
	new Float:flGameTime=GetGameTime();

	//theoretically, to get on the DT registry all the necessary checks would have already
	//been run, so we don't bother with any checks here
	for (new iI=1; iI<=g_iDTRegisterCount; iI++)
	{
		if(!g_bFastCombat[iI])
		{
			return;
		}
		//PRE-CHECKS: RETRIEVE VARS
		//-------------------------
		iCid = g_iDTRegisterIndex[iI];
		//stop on this client when the next client id is null
		if (iCid <= 0) return;
		//skip this client if they're disabled
		//if (g_iPState[iCid]==1) continue;

		//we have to adjust numbers on the gun, not the player so we get the active weapon id here
		iEntid = GetEntDataEnt2(iCid, g_iActiveWO);
		//if the retrieved gun id is -1, then...
		//wtf mate? just move on
		if (iEntid == -1) continue;
		//and here is the retrieved next attack time
		flNextTime_ret = GetEntDataFloat(iEntid,g_iNextPAttO);
		//and for retrieved next melee time
		flNextTime2_ret = GetEntDataFloat(iEntid,g_iNextSAttO);

		//TCDEBUG
		/*new iNextAttO=	FindSendPropInfo("CTerrorPlayer","m_flNextAttack");
		new iIdleTimeO=	FindSendPropInfo("CTerrorGun","m_flTimeWeaponIdle");
		PrintToChatAll("\x03DT, NextAttack \x01%i %f\x03, TimeIdle \x01%i %f",
			iNextAttO,
			GetEntDataFloat(iCid,iNextAttO),
			iIdleTimeO,
			GetEntDataFloat(iEntid,iIdleTimeO)
			);*/

		//CHECK 1: BEFORE ADJUSTED SHOT IS MADE
		//------------------------------------
		//since this will probably be the case most of the time, we run this first
		//checks: gun is unchanged; time of shot has not passed
		//actions: nothing
		if (g_iDTEntid[iCid]==iEntid
			&& g_flDTNextTime[iCid]>=flNextTime_ret)
		{
			//----TCDEBUG----
			//PrintToChatAll("\x03DT client \x01%i\x03; before shot made",iCid );
			continue;
		}

		//CHECK 2: INFER IF MELEEING
		//--------------------------
		//since we don't want to shorten the interval incurred after swinging, we try to guess when
		//a melee attack is made
		//checks: if melee attack time > engine time
		//actions: nothing
		if (flNextTime2_ret > flGameTime)
		{
			//----TCDEBUG----
			//PrintToChatAll("\x03DT client \x01%i\x03; melee attack inferred",iCid );
			continue;
		}

		//CHECK 3: AFTER ADJUSTED SHOT IS MADE
		//------------------------------------
		//at this point, either a gun was swapped, or the attack time needs to be adjusted
		//checks: stored gun id same as retrieved gun id, and retrieved next attack time is after stored value
		if (g_iDTEntid[iCid]==iEntid
			&& g_flDTNextTime[iCid] < flNextTime_ret)
		{
			#if TCDEBUG
			PrintToChatAll("\x03DT after adjusted shot\n-pre, client \x01%i\x03; entid \x01%i\x03; enginetime\x01 %f\x03; NextTime_orig \x01 %f\x03; interval \x01%f",iCid,iEntid,flGameTime,flNextTime_ret, flNextTime_ret-flGameTime );
			#endif
			//this is a calculation of when the next primary attack
			//will be after applying double tap values
			flNextTime_calc = ( flNextTime_ret - flGameTime ) * g_flDT_rate + flGameTime;

			//then we store the value
			g_flDTNextTime[iCid] = flNextTime_calc;

			//and finally adjust the value in the gun
			SetEntDataFloat(iEntid, g_iNextPAttO, flNextTime_calc, true);

			#if TCDEBUG
			PrintToChatAll("\x03-post, NextTime_calc \x01 %f\x03; new interval \x01%f",GetEntDataFloat(iEntid,g_iNextPAttO), GetEntDataFloat(iEntid,g_iNextPAttO)-flGameTime );
			#endif
			continue;
		}

		//CHECK 4: ON WEAPON SWITCH
		//-------------------------
		//at this point, the only reason DT hasn't fired should be that the weapon had switched
		//checks: retrieved gun id doesn't match stored id or stored id is null
		//actions: updates stored gun id and sets stored next attack time to retrieved value
		if (g_iDTEntid[iCid] != iEntid)
		{
			#if TCDEBUG
			PrintToChatAll("\x03DT client \x01%i\x03; weapon switch inferred",iCid );
			#endif
			//now we update the stored vars
			g_iDTEntid[iCid]=iEntid;
			g_flDTNextTime[iCid]=flNextTime_ret;
			continue;
		}
		#if TCDEBUG
		PrintToChatAll("\x03DT client \x01%i\x03; reached end of checklist...",iCid );
		#endif
	}
}

//********************************************End of Dusty's code********************************


//CODE TAKEN FROM BILE THE WORLD PLUGIN!
#if SDKHOOKS
static bool:IsVisibleTo(Float:position[3], Float:targetposition[3])
{
	decl Float:vAngles[3], Float:vLookAt[3];
	
	MakeVectorFromPoints(position, targetposition, vLookAt); // compute vector from start to target
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace
	
	// execute Trace
	new Handle:trace = TR_TraceRayFilterEx(position, vAngles, MASK_SHOT, RayType_Infinite, _TraceFilter);
	
	new bool:isVisible = false;
	if (TR_DidHit(trace))
	{
		decl Float:vStart[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint
		
		if ((GetVectorDistance(position, vStart, false) + 25.0) >= GetVectorDistance(position, targetposition))
		{
			isVisible = true; // if trace ray lenght plus tolerance equal or bigger absolute distance, you hit the target
		}
	}
	else
	{
		LogError("Tracer Bug: Player-Zombie Trace did not hit anything, WTF");
		isVisible = true;
	}
	CloseHandle(trace);
	
	return isVisible;
}

public bool:_TraceFilter(entity, contentsMask)
{
	if (!entity || !IsValidEntity(entity)) // dont let WORLD, or invalid entities be hit
	{
		return false;
	}
	
	return true;
}
#endif

//entity abs origin code from here
//http://forums.alliedmods.net/showpost.php?s=e5dce96f11b8e938274902a8ad8e75e9&p=885168&postcount=3
stock GetEntityAbsOrigin(entity, Float:origin[3])
{
	if (entity && IsValidEntity(entity))
	{
		decl Float:mins[3], Float:maxs[3];
		GetEntPropVector(entity, Prop_Send,"m_vecOrigin", origin);
		GetEntPropVector(entity, Prop_Send,"m_vecMins", mins);
		GetEntPropVector(entity, Prop_Send,"m_vecMaxs", maxs);
		
		origin[0] += (mins[0] + maxs[0]) * 0.5;
		origin[1] += (mins[1] + maxs[1]) * 0.5;
		origin[2] += (mins[2] + maxs[2]) * 0.5;
	}
}

stock GetAnyValidSurvivor()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)
		&& GetClientTeam(i) == 2)
		{
			return i;
		}
	}
	return 1;
}

stock GetValidEntityCount()
{
	new count = 0;
	for(new i=1; i<=GetMaxEntities(); i++)
	{
		if(i > 0 && IsValidEntity(i) && IsValidEdict(i))
		{
			count++
		}
	}
	return count;
}

//---------------------------------------------WEAPON MANAGER--------------------------------
stock EnqueueWeapons(client)
{
	if(client > 0 && IsValidEntity(client) && IsValidEdict(client) && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		decl Float:pos[3], Float:tpos[3], String:class[32];
		GetClientAbsOrigin(client, pos);
		new maxents = GetMaxEntities();
		for (new i = MaxClients+1; i <= maxents; i++)
		{
			if(!IsValidEntity(i))
			{
				continue;
			}
			GetEdictClassname(i, class, sizeof(class));
			
			if(StrEqual(class, "weapon_rifle")
			|| StrEqual(class, "weapon_rifle_desert")
			|| StrEqual(class, "weapon_rifle_ak47")
			|| StrEqual(class, "weapon_sniper_military")
			|| StrEqual(class, "weapon_shotgun_spas")
			|| StrEqual(class, "weapon_shotgun_chrome")
			|| StrEqual(class, "weapon_smg")
			|| StrEqual(class, "weapon_pumpshotgun")
			|| StrEqual(class, "weapon_autoshotgun")
			|| StrEqual(class, "weapon_sniper_scout")
			|| StrEqual(class, "weapon_pain_pills")
			|| StrEqual(class, "weapon_pipe_bomb")
			|| StrEqual(class, "weapon_vomitjar")
			|| StrEqual(class, "weapon_smg_silenced")
			|| StrEqual(class, "weapon_smg_mp5")
			|| StrEqual(class, "weapon_sniper_awp")
			|| StrEqual(class, "weapon_sniper_scout")
			|| StrEqual(class, "weapon_rifle_sg552")
			|| StrEqual(class, "weapon_gnome")
			|| StrEqual(class, "weapon_hunting_rifle")
			|| StrEqual(class, "weapon_pistol"))
			{
				GetEntityAbsOrigin(i, tpos);
			}
			
			if(GetVectorDistance(pos, tpos) > 55.0)
			{
				continue;
			}
			CreateTimer(10.0, timerWeaponExistenceTimeout, i, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:timerWeaponExistenceTimeout(Handle:timer, any:weapon)
{
	if(!g_bGameRunning)
	{
		return;
	}
	if(weapon > 0 && IsValidEntity(weapon) && IsValidEdict(weapon))
	{
		AcceptEntityInput(weapon, "Kill");
		return;
	}
}

#if !SDKHOOKS
public Action:timerWeaponManagerSupport(Handle:timer)
{
	if(!g_bGameRunning)
	{
		g_bWeaponManager = false;
		return Plugin_Stop;
	}
	if(!GetConVarBool(g_cvarWeaponManagerEnable))
	{
		g_bWeaponManager = false;
		return Plugin_Stop;
	}
	for(new i=MaxClients+1; i<=GetMaxEntities(); i++)
	{
		if(i > 0 && IsValidEntity(i) && IsValidEdict(i))
		{
			decl String:class[32];
			GetEdictClassname(i, class, sizeof(class));
			if(StrEqual(class, "weapon_rifle")
			|| StrEqual(class, "weapon_rifle_desert")
			|| StrEqual(class, "weapon_rifle_ak47")
			|| StrEqual(class, "weapon_sniper_military")
			|| StrEqual(class, "weapon_shotgun_spas")
			|| StrEqual(class, "weapon_shotgun_chrome")
			|| StrEqual(class, "weapon_smg")
			|| StrEqual(class, "weapon_pumpshotgun")
			|| StrEqual(class, "weapon_autoshotgun")
			|| StrEqual(class, "weapon_sniper_scout")
			|| StrEqual(class, "weapon_smg_silenced")
			|| StrEqual(class, "weapon_smg_mp5")
			|| StrEqual(class, "weapon_sniper_awp")
			|| StrEqual(class, "weapon_sniper_scout")
			|| StrEqual(class, "weapon_rifle_sg552")
			|| StrEqual(class, "weapon_hunting_rifle"))
			{
				AcceptEntityInput(i, "Kill");
			}
		}
	}
	
	for(new i=1; i<=MaxClients; i++)
	{
		GivePastWeapon(i);
	}
	return Plugin_Continue;
}

stock GivePastWeapon(client)
{
	if(client > 0 && IsValidEntity(client) && IsValidEdict(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		switch(g_iLastPrimaryWeaponIndex[client])
		{
			case 1:
			CheatCommand(client, "give", "rifle");
			case 2:
			CheatCommand(client, "give", "rifle_ak47");
			case 3:
			CheatCommand(client, "give", "rifle_desert");
			case 4:
			CheatCommand(client, "give", "sniper_military");
			case 5:
			CheatCommand(client, "give", "shotgun_spas");
			case 6:
			CheatCommand(client, "give", "shotgun_chrome");
			case 7:
			CheatCommand(client, "give", "smg");
			case 8:
			CheatCommand(client, "give", "pumpshotgun");
			case 9:
			CheatCommand(client, "give", "autoshotgun");
			case 10:
			CheatCommand(client, "give", "sniper_scout");
			case 11:
			CheatCommand(client, "give", "smg_silenced");
			case 12:
			CheatCommand(client, "give", "smg_mp5");
			case 13:
			CheatCommand(client, "give", "sniper_awp");
			case 14:
			CheatCommand(client, "give", "sniper_scout");
			case 15:
			CheatCommand(client, "give", "rifle_sg552");
			case 16:
			CheatCommand(client, "give", "hunting_rifle");
		}
	}
}

stock SetClientPrimaryWeapon(client, String:weapon[])
{
	if(StrEqual(weapon, "weapon_rifle"))
	{
		g_iLastPrimaryWeaponIndex[client] = 1;
	}
	else if(StrEqual(weapon, "weapon_rifle_desert"))
	{
		g_iLastPrimaryWeaponIndex[client] = 2;
	}
	else if(StrEqual(weapon, "weapon_rifle_ak47"))
	{
		g_iLastPrimaryWeaponIndex[client] = 3;
	}
	else if(StrEqual(weapon, "weapon_sniper_military"))
	{
		g_iLastPrimaryWeaponIndex[client] = 4;
	}
	else if(StrEqual(weapon, "weapon_shotgun_spas"))
	{
		g_iLastPrimaryWeaponIndex[client] = 5;
	}
	else if(StrEqual(weapon, "weapon_shotgun_chrome"))
	{
		g_iLastPrimaryWeaponIndex[client] = 6;
	}
	else if(StrEqual(weapon, "weapon_smg"))
	{
		g_iLastPrimaryWeaponIndex[client] = 7;
	}
	else if(StrEqual(weapon, "weapon_pumpshotgun"))
	{
		g_iLastPrimaryWeaponIndex[client] = 8;
	}
	else if(StrEqual(weapon, "weapon_autoshotgun"))
	{
		g_iLastPrimaryWeaponIndex[client] = 9;
	}
	else if(StrEqual(weapon, "weapon_sniper_scout"))
	{
		g_iLastPrimaryWeaponIndex[client] = 10;
	}
	else if(StrEqual(weapon, "weapon_smg_silenced"))
	{
		g_iLastPrimaryWeaponIndex[client] = 11;
	}
	else if(StrEqual(weapon, "weapon_smg_mp5"))
	{
		g_iLastPrimaryWeaponIndex[client] = 12;
	}
	else if(StrEqual(weapon, "weapon_sniper_awp"))
	{
		g_iLastPrimaryWeaponIndex[client] = 13;
	}
	else if(StrEqual(weapon, "weapon_sniper_scout"))
	{
		g_iLastPrimaryWeaponIndex[client] = 14;
	}
	else if(StrEqual(weapon, "weapon_rifle_sg552"))
	{
		g_iLastPrimaryWeaponIndex[client] = 15;
	}
	else if(StrEqual(weapon, "weapon_hunting_rifle"))
	{
		g_iLastPrimaryWeaponIndex[client] = 16;
	}
	else
	{
		g_iLastPrimaryWeaponIndex[client] = 0;
	}
}
#endif

stock GetCurrentBoost(client, String:boost[] = "Unspecified", maxlen)
{
	switch(g_iFavBoost[client])
	{
		case -1:
		{
			Format(boost, maxlen, "Unspecified");
		}
		case 0:
		{
			Format(boost, maxlen, "Extra Health");
		}
		case 1:
		{
			Format(boost, maxlen, "Extra Speed");
		}
		case 2:
		{
			Format(boost, maxlen, "Insta Melee Kills");
		}
		case 3:
		{
			Format(boost, maxlen, "Medic");
		}
		case 4:
		{
			Format(boost, maxlen, "Upgrade");
		}
		case 5:
		{
			Format(boost, maxlen, "Extra Damage");
		}
		case 6:
		{
			Format(boost, maxlen, "Vomit enemy on death");
		}
		case 7:
		{
			Format(boost, maxlen, "Spawn spitter on death");
		}
		case 8:
		{
			Format(boost, maxlen, "Insta Respawn");
		}
		case 9:
		{
			Format(boost, maxlen, "Fire Immunity");
		}
		case 10:
		{
			Format(boost, maxlen, "Invisible Respawn");
		}
		case 11:
		{
			Format(boost, maxlen, "God Respawn");
		}
		case 12:
		{
			Format(boost, maxlen, "Grenade Launcher Incap Immunity");
		}
		case 13:
		{
			Format(boost, maxlen, "Fast Combat");
		}
	}
}

stock SetFavoriteBoost(client)
{
	new index = g_iFavBoost[client];
	
	g_bExtraHealth[client] = false;
	g_bExtraSpeed[client] = false;
	g_bInstaMeleeKill[client] = false;
	g_bMedic[client] = false;
	g_bUpgrade[client] = false;
	g_bExtraDmg[client] = false;
	g_bVomitDeath[client] = false;
	g_bSpitterDeath[client] = false;
	g_bInstantRespawn[client] = false;
	g_bNoFire[client] = false;
	g_bStalker[client] = false;
	g_bGodMode[client] = false;
	g_bNoIncap[client] = false;
	g_bFastCombat[client] = false;
	switch(index)
	{
		case 0:
		{
			if(!GetConVarBool(g_cvarBSAllowExtraHealth))
			{
				PrintToChat(client, "\x03The selected boost is not available!");
				BuildBoostMenu(client);
				return;
			}
			g_bExtraHealth[client] = true;
			SetEntityHealth(client, GetClientHealth(client)+GetConVarInt(g_cvarBSCalcHealth));
		}
		case 1:
		{
			if(!GetConVarBool(g_cvarBSAllowExtraSpeed))
			{
				PrintToChat(client, "\x03The selected boost is not available!");
				BuildBoostMenu(client);
				return;
			}
			g_bExtraSpeed[client] = true;
			new Float:total = FloatAdd(1.0, GetConVarFloat(g_cvarBSCalcSpeed));
			SetEntDataFloat(client, g_flLagMovement, total, true);
		}
		case 2:
		{
			if(!GetConVarBool(g_cvarBSAllowInstaMeleeKills))
			{
				PrintToChat(client, "\x03The selected boost is not available!");
				BuildBoostMenu(client);
				return;
			}
			g_bInstaMeleeKill[client] = true;
		}
		case 3:
		{
			if(!GetConVarBool(g_cvarBSAllowMedic))
			{
				PrintToChat(client, "\x03The selected boost is not available!");
				BuildBoostMenu(client);
				return;
			}
			g_bMedic[client] = true;
		}
		case 4:
		{
			if(!GetConVarBool(g_cvarBSAllowUpgrade))
			{
				PrintToChat(client, "\x03The selected boost is not available!");
				BuildBoostMenu(client);
				return;
			}
			g_bUpgrade[client] = true;
		}
		case 5:
		{
			if(!GetConVarBool(g_cvarBSAllowExtraDamage))
			{
				PrintToChat(client, "\x03The selected boost is not available!");
				BuildBoostMenu(client);
				return;
			}
			g_bExtraDmg[client] = true;
		}
		case 6:
		{
			if(!GetConVarBool(g_cvarBSAllowVomit))
			{
				PrintToChat(client, "\x03The selected boost is not available!");
				BuildBoostMenu(client);
				return;
			}
			g_bVomitDeath[client] = true;
		}
		case 7:
		{
			if(!GetConVarBool(g_cvarBSAllowSpitter))
			{
				PrintToChat(client, "\x03The selected boost is not available!");
				BuildBoostMenu(client);
				return;
			}
			g_bSpitterDeath[client] = true;
		}
		case 8:
		{
			if(!GetConVarBool(g_cvarBSAllowInstaRespawn))
			{
				PrintToChat(client, "\x03The selected boost is not available!");
				BuildBoostMenu(client);
				return;
			}
			g_bInstantRespawn[client] = true;
		}
		case 9:
		{
			if(!GetConVarBool(g_cvarBSAllowFire))
			{
				PrintToChat(client, "\x03The selected boost is not available!");
				BuildBoostMenu(client);
				return;
			}
			g_bNoFire[client] = true;
		}
		case 10:
		{
			if(!GetConVarBool(g_cvarBSAllowStalker))
			{
				PrintToChat(client, "\x03The selected boost is not available!");
				BuildBoostMenu(client);
				return;
			}
			g_bStalker[client] = true;
		}
		case 11:
		{
			if(!GetConVarBool(g_cvarBSAllowGod))
			{
				PrintToChat(client, "\x03The selected boost is not available!");
				BuildBoostMenu(client);
				return;
			}
			g_bGodMode[client] = true;
		}
		case 12:
		{
			if(!GetConVarBool(g_cvarBSAllowNoIncap))
			{
				PrintToChat(client, "\x03The selected boost is not available!");
				BuildBoostMenu(client);
				return;
			}
			g_bNoIncap[client] = true;
		}
		case 13:
		{
			if(!GetConVarBool(g_cvarBSAllowFastCombat))
			{
				PrintToChat(client, "\x03The selected boost is not available!");
				BuildBoostMenu(client);
				return;
			}
			g_bFastCombat[client] = true;
		}
	}
	PrintToChat(client, "\x03Your boost have been automatically selected. You can still change it in your settings");
}

public PrintToChatAllDM(const String:Content[])
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(i <= 0
		|| !IsValidEntity(i)
		|| !IsValidEdict(i)
		|| !IsClientInGame(i)
		|| IsFakeClient(i)
		|| !notify[i])
		{
			continue;
		}
		PrintToChat(i, "%s", Content);
	}
	return;
}


//*********************************************************************
//****************************** SETTINGS *****************************
//*********************************************************************
public Action:CmdSettings(client, args)
{
	BuildSettingsMenu(client);
	return Plugin_Handled;
}

BuildSettingsMenu(client)
{
	decl String:Buffer[256], String:boost[64];
	new Handle:menu = CreateMenu(Menu_Settings);
	
	if(allowmusic[client])
	{
		Format(Buffer, sizeof(Buffer), "Backround Music: OFF");
	}
	else
	{
		Format(Buffer, sizeof(Buffer), "Backround Music: ON");
	}
	AddMenuItem(menu, "music", Buffer);
	if(notify[client])
	{
		Format(Buffer, sizeof(Buffer), "Notifications: ON");
	}
	else
	{
		Format(Buffer, sizeof(Buffer), "Notifications: OFF");
	}
	AddMenuItem(menu, "notify", Buffer);
	switch(g_iFavCharacter[client])
	{
		//Nick
		case 0:
		{
			Format(Buffer, sizeof(Buffer), "Favorite Character: Nick");
		}
		//Coach
		case 1:
		{
			Format(Buffer, sizeof(Buffer), "Favorite Character: Coach");
		}
		//Ellis
		case 2:
		{
			Format(Buffer, sizeof(Buffer), "Favorite Character: Ellis");
		}
		//Rochelle
		case 3:
		{
			Format(Buffer, sizeof(Buffer), "Favorite Character: Rochelle");
		}
	}
	AddMenuItem(menu, "favchar", Buffer);
	switch(g_iFavWeapon[client])
	{
		case 0:
		{
			Format(Buffer, sizeof(Buffer), "Respawn Weapon: Random");
		}
		case 1:
		{
			Format(Buffer, sizeof(Buffer), "Respawn Weapon: Auto Shotgun");
		}
		case 2:
		{
			Format(Buffer, sizeof(Buffer), "Respawn Weapon: Hunting Rifle");
		}
		case 3:
		{
			Format(Buffer, sizeof(Buffer), "Respawn Weapon: Pump Shotgun");
		}
		case 4:
		{
			Format(Buffer, sizeof(Buffer), "Respawn Weapon: Rifle");
		}
		case 5:
		{
			Format(Buffer, sizeof(Buffer), "Respawn Weapon: Rifle AK47");
		}
		case 6:
		{
			Format(Buffer, sizeof(Buffer), "Respawn Weapon: Rifle Desert");
		}
		case 7:
		{
			Format(Buffer, sizeof(Buffer), "Respawn Weapon: Rifle SG552");
		}
		case 8:
		{
			Format(Buffer, sizeof(Buffer), "Respawn Weapon: Chrome Shotgun");
		}
		case 9:
		{
			Format(Buffer, sizeof(Buffer), "Respawn Weapon: Combat Shotgun");
		}
		case 10:
		{
			Format(Buffer, sizeof(Buffer), "Respawn Weapon: SMG");
		}
		case 11:
		{
			Format(Buffer, sizeof(Buffer), "Respawn Weapon: SMG MP5");
		}
		case 12:
		{
			Format(Buffer, sizeof(Buffer), "Respawn Weapon: SMG Silenced");
		}
		case 13:
		{
			Format(Buffer, sizeof(Buffer), "Respawn Weapon: Sniper AWP");
		}
		case 14:
		{
			Format(Buffer, sizeof(Buffer), "Respawn Weapon: Sniper Military");
		}
		case 15:
		{
			Format(Buffer, sizeof(Buffer), "Respawn Weapon: Sniper Scout");
		}
	}
	AddMenuItem(menu, "favweap", Buffer);
	
	GetCurrentBoost(client, boost, sizeof(boost));
	Format(Buffer, sizeof(Buffer), "Current Boost: %s", boost);
	AddMenuItem(menu, "favboost", Buffer);
	
	if(g_bAutoMenus[client])
	{
		Format(Buffer, sizeof(Buffer), "Automatic Menus: ON");
	}
	else
	{
		Format(Buffer, sizeof(Buffer), "Automatic Menus: OFF");
	}
	AddMenuItem(menu, "auto", Buffer);
	
	SetMenuExitButton(menu, true);
	decl String:name[256];
	GetClientName(client, name, sizeof(name));
	Format(Buffer, sizeof(Buffer), "%s's settings", name);
	SetMenuTitle(menu, Buffer);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Menu_Settings(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			{
				if(allowmusic[param1])
				{
					allowmusic[param1] = false;
					if(deathmatch)
					{
						PlayRandomTrack(param1, SOUNDTYPE_MATCH);
					}
					else
					{
						PlayRandomTrack(param1, SOUNDTYPE_WAIT);
					}
				}
				else if(!allowmusic[param1])
				{
					StopAllMusic(param1);
					allowmusic[param1] = true;
				}
				BuildSettingsMenu(param1);
				UpdatePlayerSettings(param1);
			}
			case 1:
			{
				if(!notify[param1])
				{
					notify[param1] = true;
				}
				else
				{
					notify[param1] = false;
				}
				BuildSettingsMenu(param1);
				UpdatePlayerSettings(param1);
			}
			case 2:
			{
				BuildCharacterMenu(param1);
			}
			case 3:
			{
				BuildWeaponMenu(param1);
			}
			case 4:
			{
				if(g_bChoosedBoost[param1])
				{
					PrintToChat(param1, "\x03You have already selected your boost for this live!");
					return;
				}
				BuildBoostMenu(param1);
			}
			case 5:
			{
				if(!g_bAutoMenus[param1])
				{
					g_bAutoMenus[param1] = true;
				}
				else
				{
					g_bAutoMenus[param1] = false;
				}
				BuildSettingsMenu(param1);
				UpdatePlayerSettings(param1);
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

BuildCharacterMenu(client)
{
	new Handle:menu = CreateMenu(Menu_Chars);
	AddMenuItem(menu, "nick", "Nick");
	AddMenuItem(menu, "coach", "Coach");
	AddMenuItem(menu, "ellis", "Ellis");
	AddMenuItem(menu, "rochelle", "Rochelle");
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	SetMenuExitButton(menu, true);
	SetMenuTitle(menu, "Select your favorite survivor");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Menu_Chars(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			{
				g_iFavCharacter[param1] = 0;
				SetEntProp(param1, Prop_Send, "m_survivorCharacter", 0);
				SetEntityModel(param1, "models/survivors/survivor_gambler.mdl");
			}
			case 1:
			{
				g_iFavCharacter[param1] = 1;
				SetEntProp(param1, Prop_Send, "m_survivorCharacter", 2);
				SetEntityModel(param1, "models/survivors/survivor_coach.mdl");
			}
			case 2:
			{
				g_iFavCharacter[param1] = 2;
				SetEntProp(param1, Prop_Send, "m_survivorCharacter", 3);
				SetEntityModel(param1, "models/survivors/survivor_mechanic.mdl");
			}
			case 3:
			{
				SetEntProp(param1, Prop_Send, "m_survivorCharacter", 1);
				SetEntityModel(param1, "models/survivors/survivor_producer.mdl");
				g_iFavCharacter[param1] = 3;
			}
		}
		BuildSettingsMenu(param1);
		UpdatePlayerSettings(param1);
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

BuildWeaponMenu(client)
{
	new Handle:menu = CreateMenu(Menu_Weaps);
	
	AddMenuItem(menu, "0", "Random");
	AddMenuItem(menu, "1", "Auto Shotgun");
	AddMenuItem(menu, "2", "Hunting Rifle");
	AddMenuItem(menu, "3", "Pump Shotgun");
	AddMenuItem(menu, "4", "Rifle");
	AddMenuItem(menu, "5", "Rifle AK47");
	AddMenuItem(menu, "6", "Rifle Desert");
	AddMenuItem(menu, "7", "Rifle SG552");
	AddMenuItem(menu, "8", "Chrome Shotgun");
	AddMenuItem(menu, "9", "Combat Shotgun");
	AddMenuItem(menu, "10", "SMG");
	AddMenuItem(menu, "11", "SMG MP5");
	AddMenuItem(menu, "12", "SMG Silenced");
	AddMenuItem(menu, "13", "Sniper AWP");
	AddMenuItem(menu, "14", "Sniper Military");
	AddMenuItem(menu, "15", "Sniper Scout");
	
	SetMenuExitBackButton(menu, true);
	SetMenuTitle(menu, "Select your respawn weapon");
	DisplayMenu(menu, client, 15);
}

public Menu_Weaps(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		g_iFavWeapon[param1] = param2;
		BuildSettingsMenu(param1);
		UpdatePlayerSettings(param1);
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
//*********************************************************************
//****************************** MY STATS *****************************
//*********************************************************************
public Action:CmdMyStats(client, args)
{
	if(!IsDatabaseResponding())
	{
		PrintToChat(client, "\x03Sorry, couldn't establish connection to the database. Try again later");
		return Plugin_Handled;
	}
	BuildStatsMenu(client);
	return Plugin_Handled;
}

BuildStatsMenu(client)
{
	new Handle:menu = CreateMenu(Menu_Stats);
	new myscore = tscore[client];
	new mykills = tkills[client];
	new mydeaths = tdeaths[client];
	new mylongtime = RoundToFloor(g_flLongestAlive[client]);
	new myreward = trewardused[client];
	decl String:name[256], String:ip[64], String:boost[64], String:Buffer[280];
	GetClientName(client, name, sizeof(name));
	GetClientIP(client, ip, sizeof(ip));
	GetCurrentBoost(client, boost, sizeof(boost));
	
	Format(Buffer, sizeof(Buffer), "Name: %s", name);
	AddMenuItem(menu, "name", Buffer);
	
	Format(Buffer, sizeof(Buffer), "IP: %s", ip);
	AddMenuItem(menu, "ip", Buffer);
	
	Format(Buffer, sizeof(Buffer), "Total Score: %i", myscore);
	AddMenuItem(menu, "score", Buffer);
	
	Format(Buffer, sizeof(Buffer), "Total Kills: %i", mykills);
	AddMenuItem(menu, "kills", Buffer);
	
	Format(Buffer, sizeof(Buffer), "Total Deaths: %i", mydeaths);
	AddMenuItem(menu, "deaths", Buffer);
	
	Format(Buffer, sizeof(Buffer), "Longest Time Alive: %i", mylongtime);
	AddMenuItem(menu, "longtime", Buffer);
	
	Format(Buffer, sizeof(Buffer), "Total Rewards Used: %i", myreward);
	AddMenuItem(menu, "reward", Buffer);
	
	Format(Buffer, sizeof(Buffer), "Favorite Boost: %s", boost);
	AddMenuItem(menu, "boost", Buffer);
	SetMenuTitle(menu, "Your Stats");
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Menu_Stats(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
	
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

//*********************************************************************
//****************************** RANKING ******************************
//*********************************************************************
public Action:CmdRanking(client, args)
{
	if(!IsDatabaseResponding())
	{
		PrintToChat(client, "\x03Sorry, couldn't establish connection to the database. Try again later");
		return Plugin_Handled;
	}
	RankingRequest(client);
	return Plugin_Handled;
}

//*********************************************************************
//******************************** SQL ********************************
//*********************************************************************
public Action:timerSQLManager(Handle:timer, any:client)
{
	if(!IsDatabaseResponding())
	{
		LogError("SQL Manager couldn't establish connection with the database");
		return Plugin_Continue;
	}
	if(!g_bGameRunning)
	{
		g_bSQLManager = false;
		return Plugin_Stop;
	}
	if(!deathmatch)
	{
		return Plugin_Continue;
	}
	for(new i=1; i<=MaxClients; i++)
	{
		UpdateStats(i);
		UpdatePlayerAchievement(i);
		UpdatePlayerSettings(i);
	}
	return Plugin_Continue;
}
public Action:timerUpdateDatabase(Handle:timer, any:client)
{
	if(!IsDatabaseResponding())
	{
		return;
	}
	if(client > 0 && IsValidEntity(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		#if DEBUG
		LogMessage("Updating the connected user");
		#endif
		decl String:SteamID[MAX_LINE_WIDTH];
		GetClientAuthStringReal(client, SteamID, sizeof(SteamID));
		decl String:query[512];
		Format(query, sizeof(query), "SELECT steamid FROM players WHERE steamid = '%s'", SteamID);
		if(client != 0)
		{
			SQL_TQuery(db, CreatePlayerDB, query, client);
		}
	}
}

public CreatePlayerDB(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(db == INVALID_HANDLE)
	{
		#if DEBUG
		LogMessage("No connection with the database");
		#endif
		return;
	}
	if(!IsDatabaseResponding())
	{
		return;
	}
	if (!client || hndl == INVALID_HANDLE)
	{
		return;
	}
	
	if(!SQL_GetRowCount(hndl))
	{
		new String:SteamID[MAX_LINE_WIDTH];
		GetClientAuthStringReal(client, SteamID, sizeof(SteamID));

		new String:query[512];
		#if DEBUG
		LogMessage("Quering...");
		#endif
		Format(query, sizeof(query), "INSERT IGNORE INTO players SET steamid = '%s'", SteamID);
		SQL_TQuery(db, SQLErrorCheckCallback, query);
	}
	UpdatePlayer(client);
	LoadPlayer(client);
}

public UpdatePlayer(client)
{
	if(!IsDatabaseResponding())
	{
		return;
	}
	if (!IsClientConnected(client))
		return;

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientAuthStringReal(client, SteamID, sizeof(SteamID));

	decl String:Name[MAX_LINE_WIDTH];
	GetClientName(client, Name, sizeof(Name));

	ReplaceString(Name, sizeof(Name), "<?php", "");
	ReplaceString(Name, sizeof(Name), "<?PHP", "");
	ReplaceString(Name, sizeof(Name), "?>", "");
	ReplaceString(Name, sizeof(Name), "\\", "");
	ReplaceString(Name, sizeof(Name), "\"", "");
	ReplaceString(Name, sizeof(Name), "'", "");
	ReplaceString(Name, sizeof(Name), ";", "");
	ReplaceString(Name, sizeof(Name), "´", "");
	ReplaceString(Name, sizeof(Name), "`", "");

	UpdatePlayerFull(client, SteamID, Name);
}

public UpdatePlayerFull(client, const String:SteamID[], const String:Name[])
{
	if(!IsDatabaseResponding())
	{
		return;
	}
	if(client <= 0
	|| !IsValidEntity(client)
	|| !IsValidEdict(client)
	|| !IsClientConnected(client)
	|| !IsClientInGame(client)
	|| IsFakeClient(client)
	|| !g_bClientLoaded[client])
	{
		return;
	}
	#if DEBUG
	PrintToServer("UpdatePlayerFull query was called for %i", client);
	#endif
	decl String:query[512];
	Format(query, sizeof(query), "UPDATE players SET name = '%s' WHERE steamid = '%s'", Name, SteamID);
	SQL_TQuery(db, UpdatePlayerCallback, query, client);
}

public UpdatePlayerAchievement(client)
{
	if(!IsDatabaseResponding())
	{
		return;
	}
	if(client <= 0
	|| !IsValidEntity(client)
	|| !IsValidEdict(client)
	|| !IsClientConnected(client)
	|| !IsClientInGame(client)
	|| IsFakeClient(client)
	|| !g_bClientLoaded[client])
	{
		return;
	}
	#if DEBUG
	PrintToServer("UpdatePlayerAchievement query was called for %i", client);
	#endif
	decl String:SteamID[MAX_LINE_WIDTH], String:query[512];
	GetClientAuthStringReal(client, SteamID, sizeof(SteamID));
	Format(query, sizeof(query), "UPDATE players SET award_distance = %i, award_burn = %i, award_incapdealer = %i, award_petcaller = %i, award_endurance = %i, award_oneshot = %i, award_guard = %i, award_widow = %i, award_fall = %i, award_ftrigger = %i, award_firstdm = %i, award_iwin = %i WHERE steamid = '%s'", g_bDistanceReaper[client], g_bBurningMachine[client], g_bIncapDealer[client], g_bPetCaller[client], g_bEndurance[client], g_bOneShot[client], g_bBodyGuard[client], g_bWidowMaker[client], g_bFallBitch[client], g_bSurprise[client], g_bFirstDM[client], g_bIWin[client], SteamID);
	SQL_TQuery(db, UpdatePlayerCallback, query, client);
}

public UpdatePlayerLongestTime(client)
{
	if(!IsDatabaseResponding())
	{
		return;
	}
	if(client <= 0
	|| !IsValidEntity(client)
	|| !IsValidEdict(client)
	|| !IsClientConnected(client)
	|| !IsClientInGame(client)
	|| IsFakeClient(client)
	|| !g_bClientLoaded[client])
	{
		return;
	}
	#if DEBUG
	PrintToServer("UpdateLongestTime query was called for %i", client);
	#endif
	decl String:SteamID[MAX_LINE_WIDTH], String:query[512];
	GetClientAuthStringReal(client, SteamID, sizeof(SteamID));
	new time = RoundToFloor(g_flLongestAlive[client]);
	Format(query, sizeof(query), "UPDATE players SET longtimealive = %i WHERE steamid = '%s'", time, SteamID);
	SQL_TQuery(db, UpdatePlayerCallback, query, client);
}

public UpdatePlayerSettings(client)
{
	if(!IsDatabaseResponding())
	{
		return;
	}
	if(client <= 0
	|| !IsValidEntity(client)
	|| !IsValidEdict(client)
	|| !IsClientConnected(client)
	|| !IsClientInGame(client)
	|| IsFakeClient(client)
	|| GetClientTeam(client) != 2
	|| !g_bClientLoaded[client])
	{
		return;
	}
	#if DEBUG
	PrintToServer("UpdatePlayerSettings query was called for %i", client);
	#endif
	
	decl String:query[512], String:SteamID[MAX_LINE_WIDTH];
	GetClientAuthStringReal(client, SteamID, sizeof(SteamID));
	Format(query, sizeof(query), "UPDATE players SET settings_music = %i, settings_notify = %i, settings_character = %i, settings_weapon = %i, settings_boost = %i, settings_menus = %i WHERE steamid = '%s'", allowmusic[client], notify[client], g_iFavCharacter[client], g_iFavWeapon[client], g_iFavBoost[client], g_bAutoMenus[client], SteamID);
	SQL_TQuery(db, UpdatePlayerCallback, query, client);
}

public LoadStats(client)
{
	if(!IsDatabaseResponding())
	{
		return;
	}
	if(client <= 0
	|| !IsValidEntity(client)
	|| !IsValidEdict(client)
	|| !IsClientConnected(client)
	|| !IsClientInGame(client)
	|| IsFakeClient(client)
	|| GetClientTeam(client) != 2
	|| !g_bClientLoaded[client])
	{
		return;
	}
	#if DEBUG
	PrintToServer("LoadStats query was called for %i", client);
	#endif
	decl String:SteamID[MAX_LINE_WIDTH], String:query[512];
	Format(query, sizeof(query), "SELECT score, kills, deaths, longtimealive, rewardused FROM players WHERE steamid = '%s'", SteamID);
	SQL_TQuery(db, LoadStatsCallback, query, client);
}

public LoadStatsCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(!IsDatabaseResponding())
	{
		return;
	}
	if (!client)
		return;
		
	if(!IsClientConnected(client))
		return;

	if (hndl == INVALID_HANDLE)
	{
		#if DEBUG
		LogError("LoadPlayer Query failed: %s", error);
		#endif
		return;
	}
	
	while(SQL_FetchRow(hndl))
	{
		tscore[client] = SQL_FetchInt(hndl, 0);
		tkills[client] = SQL_FetchInt(hndl, 1);
		tdeaths[client] = SQL_FetchInt(hndl, 2);
		g_flLongestAlive[client] = ConvertIntFloat(SQL_FetchInt(hndl, 3));
		trewardused[client] = SQL_FetchInt(hndl, 4);
	}
}

public UpdateStats(client)
{
	if(!IsDatabaseResponding())
	{
		return;
	}
	if(client <= 0
	|| !IsValidEntity(client)
	|| !IsValidEdict(client)
	|| !IsClientConnected(client)
	|| !IsClientInGame(client)
	|| IsFakeClient(client)
	|| GetClientTeam(client) != 2
	|| !g_bClientLoaded[client])
	{
		return;
	}
	
	#if DEBUG
	PrintToServer("UpdateStats query was called for %i", client);
	#endif
	new abscore = tscore[client];
	new abkills = tkills[client];
	new abdeaths = tdeaths[client];
	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientAuthStringReal(client, SteamID, sizeof(SteamID));
	UpdatePlayer(client);
	new time = RoundToFloor(g_flLongestAlive[client]);
	decl String:query[512];
	Format(query, sizeof(query), "UPDATE players SET score = %i, kills = %i, deaths = %i, longtimealive = %i, rewardused = %i WHERE steamid = '%s'", abscore, abkills, abdeaths, time, trewardused[client], SteamID);
	SQL_TQuery(db, UpdatePlayerCallback, query, client);
}

public UpdatePlayerCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (db == INVALID_HANDLE)
		return;

	if (!StrEqual("", error))
	{
		LogError("SQL Error: %s", error);
	}
}

GetClientAuthStringReal(client, String:auth[], maxlength)
{
	GetClientAuthString(client, auth, maxlength);

	if (StrEqual(auth, "STEAM_ID_LAN", false))
	{
		GetClientIP(client, auth, maxlength);
	}
}

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:queryid)
{
	if(!IsDatabaseResponding())
	{
		return;
	}
	if (db == INVALID_HANDLE)
		return;
		
	if(!StrEqual("", error))
	{
		LogError("SQL Error: %s", error);
	}
}

public LoadPlayer(client)
{
	if(!IsDatabaseResponding())
	{
		return;
	}
	#if DEBUG
	PrintToServer("Loading client stats...");
	#endif
	if(client <= 0
	|| !IsValidEdict(client)
	|| !IsValidEntity(client) 
	|| !IsClientConnected(client)
	|| !IsClientInGame(client)
	|| IsFakeClient(client))
	{
		#if DEBUG
		PrintToServer("Client %i failed to load stats!", client);
		#endif
		return;
	}
	#if DEBUG
	PrintToServer("---------------------QUERY START: LoadPlayer------------------");
	#endif
	decl String:SteamID[MAX_LINE_WIDTH], String:query[756];
	GetClientAuthStringReal(client, SteamID, sizeof(SteamID));
	
	Format(query, sizeof(query), "SELECT score, kills, deaths, longtimealive, rewardused, settings_music, settings_notify, settings_character, settings_boost, award_distance, award_burn, award_incapdealer, award_petcaller, award_endurance, award_oneshot, award_guard, award_widow, award_fall, award_ftrigger, award_firstdm, award_iwin, settings_weapon FROM players WHERE steamid = '%s'", SteamID);
	#if DEBUG
	PrintToServer("Last Player Query's size was of : %i/764", strlen(query));
	#endif
	if(strlen(query) >= 512)
	{
		LogError("****************FATAL ERROR! Query size is too big!*******************");
	}
	
	SQL_TQuery(db, LoadPlayerCallback, query, client);
	
	#if DEBUG
	PrintToServer("Succesfully sent the query");
	#endif
}
public LoadPlayerCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(!IsDatabaseResponding())
	{
		return;
	}
	if (!client)
		return;
		
	if(!IsClientConnected(client))
		return;

	if (hndl == INVALID_HANDLE && !IsFakeClient(client))
	{
		LogError("LoadPlayer Query failed: %s", error);
		return;
	}
	if(!SQL_GetRowCount(hndl))
	{
		#if DEBUG
		LogError("LoadPlayer Query failed: No SteamID matches");
		PrintToServer("---------------------QUERY FAIL: LoadPlayer------------------");
		#endif
		return;
	}
	while(SQL_FetchRow(hndl))
	{
		#if DEBUG
		PrintToServer("Getting the client data");
		#endif
		
		tscore[client] = SQL_FetchInt(hndl, 0);
		tkills[client] = SQL_FetchInt(hndl, 1);
		tdeaths[client] = SQL_FetchInt(hndl, 2);
		g_flLongestAlive[client] = ConvertIntFloat(SQL_FetchInt(hndl, 3));
		trewardused[client] = SQL_FetchInt(hndl, 4);
		allowmusic[client] = bool:SQL_FetchInt(hndl, 5);
		notify[client] = bool:SQL_FetchInt(hndl, 6);
		g_iFavCharacter[client] = SQL_FetchInt(hndl, 7);
		g_iFavBoost[client] = SQL_FetchInt(hndl, 8);
		g_bDistanceReaper[client] = bool:SQL_FetchInt(hndl, 9);
		g_bBurningMachine[client] = bool:SQL_FetchInt(hndl, 10);
		g_bIncapDealer[client] = bool:SQL_FetchInt(hndl, 11);
		g_bPetCaller[client] = bool:SQL_FetchInt(hndl, 12);
		g_bEndurance[client] = bool:SQL_FetchInt(hndl, 13);
		g_bOneShot[client] = bool:SQL_FetchInt(hndl, 14);
		g_bBodyGuard[client] = bool:SQL_FetchInt(hndl, 15);
		g_bWidowMaker[client] = bool:SQL_FetchInt(hndl, 16);
		g_bFallBitch[client] = bool:SQL_FetchInt(hndl, 17);
		g_bSurprise[client] = bool:SQL_FetchInt(hndl, 18);
		g_bFirstDM[client] = bool:SQL_FetchInt(hndl, 19);
		g_bIWin[client] = bool:SQL_FetchInt(hndl, 20);
		g_iFavWeapon[client] = bool:SQL_FetchInt(hndl, 21);
		g_bClientLoaded[client] = true;
		#if DEBUG
		PrintToServer("Data of the client obtained");
		#endif
		#if DEBUG
		PrintToServer("---------------------QUERY END: LoadPlayer------------------");
		#endif
		return;
	}
	#if DEBUG
	PrintToServer("---------------------QUERY FAIL: LoadPlayer------------------");
	#endif
}

public RankingRequest(client)
{
	if(!IsDatabaseResponding())
	{
		return;
	}
	if(client <= 0
	|| !IsValidEdict(client)
	|| !IsValidEntity(client) 
	|| !IsClientConnected(client)
	|| !IsClientInGame(client))
	{
		return;
	}
	
	decl String:query[512];
	Format(query, sizeof(query), "SELECT name, score FROM players ORDER BY score DESC LIMIT 10");
	if(IsDatabaseResponding())
	{
		SQL_TQuery(db, DisplayRanking, query, client);
	}
}

public DisplayRanking(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(!IsDatabaseResponding())
	{
		return;
	}
	if (!client)
		return;
		
	if(!IsClientConnected(client))
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("DisplayRanking Query failed: %s", error);
		return;
	}
	decl String:Name[64], String:Buffer[256];
	new rkscore = 0;
	new Handle:menu = CreateMenu(Menu_Ranking);
	SetMenuTitle(menu, "Best 10 players");
	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Name, sizeof(Name));
		rkscore = SQL_FetchInt(hndl, 1);
		
		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");
		
		Format(Buffer, sizeof(Buffer), "%s [%i]", Name, rkscore);
		AddMenuItem(menu, "addplayer", Buffer);
	}
	DisplayMenu(menu, client, 30);
}

public Menu_Ranking(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
	
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

stock bool:IsDatabaseResponding()
{
	if(db == INVALID_HANDLE || !SQL_CheckConfig(DB_NAME))
	{
		return false;
	}
	else
	{
		return true;
	}
}

stock OpenConnection()
{
	if(SQL_CheckConfig(DB_NAME))
	{
		new String:error[256];
		db = SQL_Connect(DB_NAME, true, error, sizeof(error));
		if (db == INVALID_HANDLE)
		{
			PrintToServer("Could not connect to the database! (%s)", error);
			LogError("Could not connect to the database! (%s)", error);
		}
	}
	else
	{
		LogError("The database was not found. Check databases.cfg!");
	}
}

stock CloseConnection()
{
	if(db != INVALID_HANDLE)
	{
		CloseHandle(db);
	}
}

stock Float:ConvertIntFloat(number)
{
	decl String:snumber[32], Float:flnumber;
	Format(snumber, sizeof(snumber), "%i.0", number);
	flnumber = StringToFloat(snumber);
	return flnumber;
}


public Action:CmdMyName(client, args)
{
	if(!IsDatabaseResponding())
	{
		return Plugin_Handled;
	}
	if(client <= 0
	|| !IsValidEdict(client)
	|| !IsValidEntity(client) 
	|| !IsClientConnected(client)
	|| !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	decl String:query[512], String:SteamID[256];
	GetClientAuthStringReal(client, SteamID, sizeof(SteamID));
	Format(query, sizeof(query), "SELECT name, score FROM players WHERE steamid = '%s'", SteamID);
	if(IsDatabaseResponding())
	{
		SQL_TQuery(db, MyNameCB, query, client);
	}
	return Plugin_Handled;
}

public MyNameCB(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(!IsDatabaseResponding())
	{
		return;
	}
	if (!client)
		return;
		
	if(!IsClientConnected(client))
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("DisplayRanking Query failed: %s", error);
		return;
	}
	decl String:Name[256];
	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Name, sizeof(Name));
	}
	PrintToChat(client, "Your name is: '%s'", Name);
}

//*********************************************************************
//***************************** DEBUG PANEL ***************************
//*********************************************************************
public Action:CmdDebugPanel(client, args)
{
	BuildDebugPanel(client);
	CreateTimer(1.0, timerDebugLoop, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action:timerDebugLoop(Handle:timer, any:client)
{
	if(!g_bGameRunning || !g_bShowDebugPanel[client])
	{
		return Plugin_Stop;
	}
	g_bShowDebugPanel[client] = true;
	BuildDebugPanel(client);
	return Plugin_Continue;
}

BuildDebugPanel(client)
{
	new Handle:menu = CreateMenu(Menu_DebugPanel);
	decl String:buffer[256];
	
	if(!deathmatch)
	{
		Format(buffer, sizeof(buffer), "Time to begin deathmatch: %i", NumPrinted);
	}
	else
	{
		Format(buffer, sizeof(buffer), "Time to begin deathmatch: Already Started");
	}
	AddMenuItem(menu, "begindm", buffer, ITEMDRAW_DISABLED);
	
	if(!deathmatch)
	{
		Format(buffer, sizeof(buffer), "Time to end deathmatch: Not started");
	}
	else
	{
		Format(buffer, sizeof(buffer), "Time to end deathmatch: %i", Countdown);
	}
	AddMenuItem(menu, "startdm", buffer, ITEMDRAW_DISABLED);
	new count = 0;
	for(new i=1; i<=MaxClients; i++)
	{
		if(i > 0 && IsValidEntity(i))
		{
			if(!IsFakeClient(i))
			{
				if(IsClientInGame(i) && GetClientTeam(i) == 1)
				{
					continue;
				}
				if(g_bInside[i])
				{
					count++;
				}
			}
		}
	}
	Format(buffer, sizeof(buffer), "Human players inside: %i", count);
	AddMenuItem(menu, "plyrs", buffer, ITEMDRAW_DISABLED);
	count = 0;
	
	SetMenuExitButton(menu, true);
	SetMenuTitle(menu, "Debug Panel");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Menu_DebugPanel(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
		
		}
		case MenuAction_Cancel:
		{
			g_bShowDebugPanel[param1] = false;
		}
		case MenuAction_End:
		{
			g_bShowDebugPanel[param1] = false;
			CloseHandle(menu);
		}
	}
}

stock StopSoundPerm(client, String:sound[])
{
	StopSound(client, SNDCHAN_AUTO, sound);
	StopSound(client, SNDCHAN_WEAPON, sound);
	StopSound(client, SNDCHAN_VOICE, sound);
	StopSound(client, SNDCHAN_ITEM, sound);
	StopSound(client, SNDCHAN_BODY, sound);
	StopSound(client, SNDCHAN_STREAM, sound);
	StopSound(client, SNDCHAN_VOICE_BASE, sound);
	StopSound(client, SNDCHAN_USER_BASE, sound);
}

public Action:CmdTechTestPos(client, args)
{
	decl Float:pos[3];
	pos = GetRandomRespawnPos();
	PrintToChat(client, "[THEC] Random position will be: %f %f %f", pos[0], pos[1], pos[2]);
}

public Action:CmdTechTestCent(client, args)
{
	decl Float:pos[3];
	pos = GetCenterCoordinates();
	PrintToChat(client, "[THEC] Center coorinates will be: %f %f %f", pos[0], pos[1], pos[2]);
}

public Action:CmdTechTestNextMap(client, args)
{
	decl String:map[256];
	GetNextValidMap(map, sizeof(map));
	PrintToChat(client, "[THEC] Next Map: %s", map);
}

stock StopMusicType(client, type)
{
	new Handle:keyvalues = INVALID_HANDLE;
	decl String:KvFileName[256];
	new bool:FileFound = false;
	
	BuildPath(Path_SM, KvFileName, sizeof(KvFileName), "data/deathmatch/l4d2_deathmatch_songlist.txt");
	
	if(!FileExists(KvFileName))
	{
		LogMessage("[WARNING] Unable to find the l4d2_deathmatch_songlist.txt file, no music will be heard!");
		FileFound = false;
	}
	else
	{
		FileFound = true;
	}
	
	if(FileFound)
	{
		keyvalues = CreateKeyValues("l4d2_deathmatch_songlist");
		FileToKeyValues(keyvalues, KvFileName);
		KvRewind(keyvalues);
		decl String:file_name[256];
		if(type == 1)
		{
			if(KvJumpToKey(keyvalues, "wait time"))
			{
				new total_files = KvGetNum(keyvalues, "total songs");
				if(total_files <= 0)
				{
					CloseHandle(keyvalues);
					return;
				}
				decl String:song[64];
				for(new song_file=1; song_file<=total_files; song_file++)
				{
					Format(song, sizeof(song), "song%i", song_file);
					KvGetString(keyvalues, song, file_name, sizeof(file_name));
					StopSoundPerm(client, file_name);
					StopSoundPerm(client, file_name);
				}
				CloseHandle(keyvalues);
				return;
			}
		}
		else if(type == 2)
		{
			if(KvJumpToKey(keyvalues, "match time"))
			{
				new total_files = KvGetNum(keyvalues, "total songs");
				if(total_files <= 0)
				{
					CloseHandle(keyvalues);
					return;
				}
				decl String:song[64];
				for(new song_file=1; song_file<=total_files; song_file++)
				{
					Format(song, sizeof(song), "song%i", song_file);
					KvGetString(keyvalues, song, file_name, sizeof(file_name));
					StopSoundPerm(client, file_name);
					StopSoundPerm(client, file_name);
				}
			}
		}
		CloseHandle(keyvalues);
	}
}

stock StopAllMusic(client)
{
	new Handle:keyvalues = INVALID_HANDLE;
	decl String:KvFileName[256];
	new bool:FileFound = false;
	
	BuildPath(Path_SM, KvFileName, sizeof(KvFileName), "data/deathmatch/l4d2_deathmatch_songlist.txt");
	
	if(!FileExists(KvFileName))
	{
		LogMessage("[WARNING] Unable to find the l4d2_deathmatch_songlist.txt file, no music will be heard!");
		FileFound = false;
	}
	else
	{
		FileFound = true;
	}
	
	if(FileFound)
	{
		keyvalues = CreateKeyValues("l4d2_deathmatch_songlist");
		FileToKeyValues(keyvalues, KvFileName);
		KvRewind(keyvalues);
		decl String:file_name[256];
		if(KvJumpToKey(keyvalues, "match time"))
		{
			new total_files = KvGetNum(keyvalues, "total songs");
			if(total_files <= 0)
			{
				CloseHandle(keyvalues);
				return;
			}
			decl String:song[64];
			for(new song_file=1; song_file<=total_files; song_file++)
			{
				Format(song, sizeof(song), "song%i", song_file);
				KvGetString(keyvalues, song, file_name, sizeof(file_name));
				StopSoundPerm(client, file_name);
				StopSoundPerm(client, file_name);
			}
		}
		KvRewind(keyvalues);
		if(KvJumpToKey(keyvalues, "wait time"))
		{
			new total_files = KvGetNum(keyvalues, "total songs");
			if(total_files <= 0)
			{
				CloseHandle(keyvalues);
				return;
			}
			decl String:song[64];
			for(new song_file=1; song_file<=total_files; song_file++)
			{
				Format(song, sizeof(song), "song%i", song_file);
				KvGetString(keyvalues, song, file_name, sizeof(file_name));
				StopSoundPerm(client, file_name);
				StopSoundPerm(client, file_name);
			}
		}
		CloseHandle(keyvalues);
	}
}

stock PlayRandomTrack(client, type)
{
	new Handle:keyvalues = INVALID_HANDLE;
	decl String:KvFileName[256];
	new bool:FileFound = false;
	
	BuildPath(Path_SM, KvFileName, sizeof(KvFileName), "data/deathmatch/l4d2_deathmatch_songlist.txt");
	
	if(!FileExists(KvFileName))
	{
		LogMessage("[WARNING] Unable to find the l4d2_deathmatch_songlist.txt file, no music will be heard!");
		FileFound = false;
	}
	else
	{
		FileFound = true;
	}
	
	if(FileFound)
	{
		keyvalues = CreateKeyValues("l4d2_deathmatch_songlist");
		FileToKeyValues(keyvalues, KvFileName);
		KvRewind(keyvalues);
		decl String:file_name[256];
		new pitch = 100;
		if(type == 2)
		{
			if(KvJumpToKey(keyvalues, "match time"))
			{
				new total_files = KvGetNum(keyvalues, "total songs");
				if(total_files <= 0)
				{
					CloseHandle(keyvalues);
					return;
				}
				switch(GetRandomInt(1, total_files))
				{
					case 1:
					{
						KvGetString(keyvalues, "song1", file_name, sizeof(file_name));
					}
					case 2:
					{
						KvGetString(keyvalues, "song2", file_name, sizeof(file_name));
					}
					case 3:
					{
						KvGetString(keyvalues, "song3", file_name, sizeof(file_name));
					}
					case 4:
					{
						KvGetString(keyvalues, "song4", file_name, sizeof(file_name));
					}
					case 5:
					{
						KvGetString(keyvalues, "song5", file_name, sizeof(file_name));
					}
					case 6:
					{
						KvGetString(keyvalues, "song6", file_name, sizeof(file_name));
					}
					case 7:
					{
						KvGetString(keyvalues, "song7", file_name, sizeof(file_name));
					}
					case 8:
					{
						KvGetString(keyvalues, "song8", file_name, sizeof(file_name));
					}
					case 9:
					{
						KvGetString(keyvalues, "song9", file_name, sizeof(file_name));
					}
					case 10:
					{
						KvGetString(keyvalues, "song10", file_name, sizeof(file_name));
					}
					case 11:
					{
						KvGetString(keyvalues, "song11", file_name, sizeof(file_name));
					}
					case 12:
					{
						KvGetString(keyvalues, "song12", file_name, sizeof(file_name));
					}
					case 13:
					{
						KvGetString(keyvalues, "song13", file_name, sizeof(file_name));
					}
					case 14:
					{
						KvGetString(keyvalues, "song14", file_name, sizeof(file_name));
					}
					case 15:
					{
						KvGetString(keyvalues, "song15", file_name, sizeof(file_name));
					}
					default:
					{
						KvGetString(keyvalues, "song1", file_name, sizeof(file_name));
					}
				}
			}
		}
		
		if(type == 1)
		{
			if(KvJumpToKey(keyvalues, "wait time"))
			{
				new total_files = KvGetNum(keyvalues, "total songs");
				pitch = KvSetNum(keyvalues, "pitch", 100);
				if(total_files <= 0)
				{
					CloseHandle(keyvalues);
					return;
				}
				switch(GetRandomInt(1, total_files))
				{
					case 1:
					{
						KvGetString(keyvalues, "song1", file_name, sizeof(file_name));
					}
					case 2:
					{
						KvGetString(keyvalues, "song2", file_name, sizeof(file_name));
					}
					case 3:
					{
						KvGetString(keyvalues, "song3", file_name, sizeof(file_name));
					}
					case 4:
					{
						KvGetString(keyvalues, "song4", file_name, sizeof(file_name));
					}
					case 5:
					{
						KvGetString(keyvalues, "song5", file_name, sizeof(file_name));
					}
					case 6:
					{
						KvGetString(keyvalues, "song6", file_name, sizeof(file_name));
					}
					case 7:
					{
						KvGetString(keyvalues, "song7", file_name, sizeof(file_name));
					}
					case 8:
					{
						KvGetString(keyvalues, "song8", file_name, sizeof(file_name));
					}
					case 9:
					{
						KvGetString(keyvalues, "song9", file_name, sizeof(file_name));
					}
					case 10:
					{
						KvGetString(keyvalues, "song10", file_name, sizeof(file_name));
					}
					case 11:
					{
						KvGetString(keyvalues, "song11", file_name, sizeof(file_name));
					}
					case 12:
					{
						KvGetString(keyvalues, "song12", file_name, sizeof(file_name));
					}
					case 13:
					{
						KvGetString(keyvalues, "song13", file_name, sizeof(file_name));
					}
					case 14:
					{
						KvGetString(keyvalues, "song14", file_name, sizeof(file_name));
					}
					case 15:
					{
						KvGetString(keyvalues, "song15", file_name, sizeof(file_name));
					}
					default:
					{
						KvGetString(keyvalues, "song1", file_name, sizeof(file_name));
					}
				}
			}
		}
		EmitSoundToClient(client, file_name, _, _, _, _, _, pitch);
		if(StrContains(file_name, ".mp3", false) >= 0)
		{
			EmitSoundToClient(client, file_name, _, _, _, _, _, pitch);
		}
		CloseHandle(keyvalues);
	}
}

#define PRECACHE_DEBUG 0

stock PrecacheAllTracks()
{
	#if PRECACHE_DEBUG
	LogMessage("[Precache] Proceed to precache files");
	#endif
	new Handle:keyvalues = INVALID_HANDLE;
	decl String:KvFileName[256];
	new bool:FileFound = false;
	
	BuildPath(Path_SM, KvFileName, sizeof(KvFileName), "data/deathmatch/l4d2_deathmatch_songlist.txt");
	
	if(!FileExists(KvFileName))
	{
		LogMessage("[WARNING] Unable to find the l4d2_deathmatch_songlist.txt file, no music will be heard!");
		FileFound = false;
	}
	else
	{
		FileFound = true;
	}
	
	if(FileFound)
	{
		#if PRECACHE_DEBUG
		LogMessage("[Precache] KeyValues file exists, continue...");
		#endif
		keyvalues = CreateKeyValues("l4d2_deathmatch_songlist");
		FileToKeyValues(keyvalues, KvFileName);
		KvRewind(keyvalues);
		decl String:file_name[256];
		if(KvJumpToKey(keyvalues, "match time"))
		{
			#if PRECACHE_DEBUG
			LogMessage("[Precache] Jumped to 'match time'");
			#endif
			new total_files = KvGetNum(keyvalues, "total songs");
			if(total_files <= 0)
			{
				#if PRECACHE_DEBUG
				LogMessage("[Precache] No files...");
				#endif
				CloseHandle(keyvalues);
				return;
			}
			decl String:song[64];
			for(new song_file=1; song_file<=total_files; song_file++)
			{
				Format(song, sizeof(song), "song%i", song_file);
				KvGetString(keyvalues, song, file_name, sizeof(file_name));
				PrecacheSound(file_name);
				#if PRECACHE_DEBUG
				LogMessage("[Precache] File %s precached", file_name);
				#endif
			}
		}
		#if PRECACHE_DEBUG
		LogMessage("[Precache] 'match time' done, proceed to 'wait time'");
		#endif
		KvRewind(keyvalues);
		if(KvJumpToKey(keyvalues, "wait time"))
		{
			#if PRECACHE_DEBUG
			LogMessage("[Precache] Jumped to 'wait time'");
			#endif
			new total_files = KvGetNum(keyvalues, "total songs");
			if(total_files <= 0)
			{
				#if PRECACHE_DEBUG
				LogMessage("[Precache] No files at 'wait time'");
				#endif
				CloseHandle(keyvalues);
				return;
			}
			decl String:song[64];
			for(new song_file=1; song_file<=total_files; song_file++)
			{
				Format(song, sizeof(song), "song%i", song_file);
				KvGetString(keyvalues, song, file_name, sizeof(file_name));
				PrecacheSound(file_name);
				#if PRECACHE_DEBUG
				LogMessage("[Precache] File %s precached", file_name);
				#endif
			}
		}
		else
		{
			#if PRECACHE_DEBUG
			LogMessage("[Precache] Unable to find 'wait time' ...?");
			#endif
		}
		#if PRECACHE_DEBUG
		LogMessage("[Precache] All files precached");
		#endif
		CloseHandle(keyvalues);
	}
}

stock AddTracksToTable()
{
	new Handle:keyvalues = INVALID_HANDLE;
	decl String:KvFileName[256];
	new bool:FileFound = false;
	
	BuildPath(Path_SM, KvFileName, sizeof(KvFileName), "data/deathmatch/l4d2_deathmatch_songlist.txt");
	
	if(!FileExists(KvFileName))
	{
		LogMessage("[WARNING] Unable to find the l4d2_deathmatch_songlist.txt file, no music will be heard!");
		FileFound = false;
	}
	else
	{
		FileFound = true;
	}
	
	if(FileFound)
	{
		keyvalues = CreateKeyValues("l4d2_deathmatch_songlist");
		FileToKeyValues(keyvalues, KvFileName);
		KvRewind(keyvalues);
		decl String:file_name[256];
		if(KvJumpToKey(keyvalues, "match time"))
		{
			new total_files = KvGetNum(keyvalues, "total songs");
			if(total_files <= 0)
			{
				CloseHandle(keyvalues);
				return;
			}
			decl String:song[64], String:Buffer[256];
			for(new song_file=1; song_file<=total_files; song_file++)
			{
				Format(song, sizeof(song), "song%i", song_file);
				Format(Buffer, sizeof(Buffer), "sound/%s", file_name);
				AddFileToDownloadsTable(Buffer);
			}
		}
		
		KvRewind(keyvalues);
		if(KvJumpToKey(keyvalues, "wait time"))
		{
			new total_files = KvGetNum(keyvalues, "total songs");
			if(total_files <= 0)
			{
				CloseHandle(keyvalues);
				return;
			}
			decl String:song[64], String:Buffer[256];
			for(new song_file=1; song_file<=total_files; song_file++)
			{
				Format(song, sizeof(song), "song%i", song_file);
				KvGetString(keyvalues, song, file_name, sizeof(file_name));
				Format(Buffer, sizeof(Buffer), "sound/%s", file_name);
				AddFileToDownloadsTable(Buffer);
			}
		}
		CloseHandle(keyvalues);
	}
}

public Action:Event_PlaySound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	new Handle:keyvalues = INVALID_HANDLE;
	decl String:KvFileName[256];
	new bool:FileFound = false;
	
	BuildPath(Path_SM, KvFileName, sizeof(KvFileName), "data/deathmatch/l4d2_deathmatch_songlist.txt");
	
	if(!FileExists(KvFileName))
	{
		LogMessage("[WARNING] Unable to find the l4d2_deathmatch_songlist.txt file, no music will be heard!");
		FileFound = false;
	}
	else
	{
		FileFound = true;
	}
	
	if(FileFound)
	{
		keyvalues = CreateKeyValues("l4d2_deathmatch_songlist");
		FileToKeyValues(keyvalues, KvFileName);
		KvRewind(keyvalues);
		decl String:file_name[256];
		if(KvJumpToKey(keyvalues, "avoid play"))
		{
			new total_files = KvGetNum(keyvalues, "total sounds");
			if(total_files <= 0)
			{
				CloseHandle(keyvalues);
				return Plugin_Continue;
			}
			decl String:safe[256];
			KvGetString(keyvalues, "master", safe, sizeof(safe));
			ReplaceString(sample, sizeof(sample), "/", "_");
			ReplaceString(sample, sizeof(sample), safe, "_");
			#if MUSIC_DEBUG
			LogMessage("[SOUND]%s", sample);
			#endif
			decl String:sound[64];
			for(new sound_file=1; sound_file<=total_files; sound_file++)
			{
				Format(sound, sizeof(sound), "sound%i", sound_file);
				KvGetString(keyvalues, sound, file_name, sizeof(file_name));
				ReplaceString(file_name, sizeof(file_name), "/", "_");
				ReplaceString(file_name, sizeof(file_name), safe, "_");
				if(StrContains(sample, file_name, false) >= 0)
				{
					volume = 0.0;
					CloseHandle(keyvalues);
					#if MUSIC_DEBUG
					LogMessage("[SOUND STOPED] %s", sample);
					#endif
					return Plugin_Changed;
				}
			}
		}
	}
	CloseHandle(keyvalues);
	return Plugin_Continue;
}

stock Float:GetBulletDistance(victim, attacker)
{
	decl Float:vpos[3], Float:bpos[3];
	GetClientAbsOrigin(victim, vpos);
	bpos[0] = last_bullet_hit[attacker][0];
	bpos[1] = last_bullet_hit[attacker][1];
	bpos[2] = last_bullet_hit[attacker][2];
	new Float:distance = GetVectorDistance(vpos, bpos);
	return distance;
}

stock bool:IsHeadshot(victim, attacker)
{
	new Handle:keyvalues = INVALID_HANDLE;
	decl String:KvFileName[256];
	new bool:FileFound = false;
	
	BuildPath(Path_SM, KvFileName, sizeof(KvFileName), "data/deathmatch/data_files/l4d2_deathmatch_modeloffs.txt");
	
	if(!FileExists(KvFileName))
	{
		LogError("[ERROR] Unable to find the l4d2_deathmatch_modeloffs.txt file, plugin is broken");
		FileFound = false;
	}
	else
	{
		FileFound = true;
	}
	
	if(FileFound)
	{
		keyvalues = CreateKeyValues("l4d2_deathmatch_songlist");
		FileToKeyValues(keyvalues, KvFileName);
		KvRewind(keyvalues);
		decl Float:distance_max, Float:distance_min, String:model[256], String:KvChar[256];
		GetClientModel(victim, model, sizeof(model));
		{
			if(StrContains(model, "survivor_mechanic", false) >= 0)
			{
				Format(KvChar, sizeof(KvChar), "Ellis");
			}
			
			if(StrContains(model, "survivor_coach", false) >= 0)
			{
				Format(KvChar, sizeof(KvChar), "Coach");
			}
			
			if(StrContains(model, "survivor_producer", false) >= 0)
			{
				Format(KvChar, sizeof(KvChar), "Rochelle");
			}
			
			if(StrContains(model, "survivor_gambler", false) >= 0)
			{
				Format(KvChar, sizeof(KvChar), "Nick");
			}
			
			if(StrContains(model, "survivor_namvet", false) >= 0)
			{
				Format(KvChar, sizeof(KvChar), "Bill");
			}
			
			if(StrContains(model, "survivor_teenangst", false) >= 0)
			{
				Format(KvChar, sizeof(KvChar), "Zoey");
			}
			
			if(StrContains(model, "survivor_biker", false) >= 0)
			{
				Format(KvChar, sizeof(KvChar), "Francis");
			}
			
			if(StrContains(model, "survivor_manager", false) >= 0)
			{
				Format(KvChar, sizeof(KvChar), "Louis");
			}
			
		}
		
		if(KvJumpToKey(keyvalues, KvChar))
		{
			new client_state;
			new health = GetClientHealth(victim);
			if(health <= 40)
			{
				client_state = 1;
			}
			else if(health >= 39 && health <= 25)
			{
				client_state = 2;
			}
			else if(health >= 24)
			{
				client_state = 3;
			}
			
			switch(client_state)
			{
				case 1:
				{
					distance_max = KvGetFloat(keyvalues, "head_fine_max", 5000.0);
					distance_min = KvGetFloat(keyvalues, "head_fine_min", 4999.0);
				}
				case 2:
				{
					distance_max = KvGetFloat(keyvalues, "head_hurt_max", 5000.0);
					distance_min = KvGetFloat(keyvalues, "head_hurt_min", 4999.0);
				}
				case 3:
				{
					distance_max = KvGetFloat(keyvalues, "head_crit_max", 5000.0);
					distance_min = KvGetFloat(keyvalues, "head_crit_min", 4999.0);
				}
			}
			new Float:distance = GetBulletDistance(victim, attacker);
			if(distance >= distance_min && distance <= distance_max)
			{
				return true;
			}
		}
	}
	return false;
}