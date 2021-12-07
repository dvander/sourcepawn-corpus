/*============================================================================================
							L4D & L4D2 ZSpawn: Zombie Spawn manager
----------------------------------------------------------------------------------------------
*	Author	:	Eärendil
*	Descrp	:	Zombie Spawn manager with admin command, autospawn and director control
*	Version	:	1.2
*	Link	:	https://forums.alliedmods.net/showthread.php?t=332272
----------------------------------------------------------------------------------------------
*	Table of contents:
		- ConVars																		(101)
		- ConVar Logic																	(246)
		- Events & Left 4 DHooks														(567)
		- Admin Commands																(768)
		- RayTrace																		(1015)
		- Timers																		(1083)
		- Logic																			(1214)
		- Changelog																		(1533)
==============================================================================================*/
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION		"1.2"
#define WEIGHT_L4D2			"1000,1000,1000,1000,1000,1000"
#define LIMIT_L4D2			"1,1,1,1,1,1"
#define WEIGHT_L4D			"1000,1000,1000"
#define LIMIT_L4D			"1,1,1"
#define	MAX_ZOMBIES	28		// This is the limit of special infected that the engine can spawn
#define CHAT_TAG			"\x04[\x05ZSpawn\x04] \x01"

bool	g_bL4D2, g_bAllow, g_bPluginOn, g_bAllowTank, g_bAllowWitch, g_bAllowMob, g_bGameStarted, g_bIsPanicEvent, g_bPluginSpawnRequest, g_bAutoSEnable, g_bAutoSFlowBlock, g_bAutoSTankBlock,
		g_bAutoSpawnBlocked, g_bAutoMEnable, g_bIsFinale, g_bBossPlaced, g_bWeightScale, g_bMapStarted;

int		g_iFlowToken, g_iNextMobSize, g_iMobAmountMin, g_iMobAmountMax, g_iVomitAmountMin, g_iVomitAmountMax, g_iTanksForRound,
		g_iTanksSpawned, g_iWitchesForRound, g_iWitchesSPawned, g_iAutoSTMod, g_iAutoSPanic, g_iArWeights[6], g_iArLimits[6], g_iSpecialLimit,
		g_iAutoSAmount, g_iArAllowSI[6], g_iGameMode, g_iSurvStLimit, g_iArClassQueue[MAX_ZOMBIES], g_iZClassAm, g_iTankScav, g_iGasCount;
		
ConVar	g_hAllow, g_hGameModes, g_hCurrGameMode, g_hAllowSI, g_hAllowTank, g_hAllowWitch, g_hAllowMob, g_hMobAmountMin, g_hMobAmountMax, g_hVomitAmountMin, g_hVomitAmountMax, 
		g_hTankMax, g_hTankMin, g_hWitchMax, g_hWitchMin, g_hAutoSEnable, g_hAutoSWeight, g_hAutoSTMin, g_hAutoSTMax, g_hAutoSTMod, g_hAutoSTDel, g_hAutoSFlowBlock, 
		g_hAutoSTankBlock, g_hAutoSPanic, g_hAutoSLimits, g_hSpecialLimit, g_hAutoMEnable, g_hAutoMTMin, g_hAutoMTMax, g_hAutoSAmount, g_hSurvStLimit,
		g_hSurvStTimeMin, g_hSurvStTimeMax, g_hSurvTime, g_hWeightScale, g_hGameModeOverride, g_hTankScav;
		
float	g_fMapFlow, g_fLastValidTFlow, g_fMaxMapProgress, g_fNextProgressTank, g_fNextProgressWitch, g_fAutoSTMin, g_fAutoSTMax, g_fAutoSTDel, g_fAutoMTMin,
		g_fAutoMTMax, g_fSurvStTimeMin, g_fSurvStTimeMax, g_fSurvTime, g_fSurvStart, g_fArTankFlow[64], g_fArWitchFlow[64];

Handle	g_hFlowTimer, g_hSpawnTimer, g_hMobTimer, g_hPanicTimer;

char	g_sAutoSWeight[64], g_sAutoSLimits[64], g_sAllowSI[64], g_sArWeights[7][16], g_sArLimits[6][16], g_sArAllowSI[8][16], g_sGameMode[64];
//Store the zombie names for calling zspawn and zauto
static char g_sZombieClasses_L4D2[8][] = 
{
	"tank",
	"smoker",
	"boomer",
	"hunter",
	"spitter",
	"jockey",
	"charger",
	"witch"
};

static char g_sZombieClasses_L4D[5][] =
{
	"tank",
	"smoker",
	"boomer",
	"hunter",
	"witch",
};

public Plugin myinfo =
{
	name = "[L4D & L4D2] ZSpawn: Zombie Spawn manager.",
	author = "Eärendil",
	description = "Controls zombie spawn, gives admin spawn commandsand autospawn zombies.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=332272",
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_Left4Dead2)
	{
		g_bL4D2 = true;
		g_iZClassAm = 6;
		return APLRes_Success;
	}
	if (GetEngineVersion() == Engine_Left4Dead)	// ADDED!
	{
		MarkNativeAsOptional("L4D2_IsTankInPlay");	// This native does not work in L4D
		g_iZClassAm = 3;
		return APLRes_Success;
	}
	strcopy(error, err_max, "This plugin only supports Left 4 Dead Series.");	// I will try to add L4D support for a next update
	return APLRes_SilentFailure;
}

//==========================================================================================
//									ConVars
//==========================================================================================
public void OnPluginStart()
{
	CreateConVar("zspawn_version", PLUGIN_VERSION,	"L4D ZSpawn Version", 	FCVAR_NOTIFY|FCVAR_DONTRECORD);
	// ConVars to enable/disable plugin
	g_hAllow			= CreateConVar("zspawn_enable", 			"1", 		"0 = Plugin off, 1 = Plugin on.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hGameModes		= CreateConVar("zspawn_gamemodes",			"",			"Enable the plugin in these gamemodes, separated by spaces. (Empty = all).", FCVAR_NOTIFY);
	// Enable/disable director specials, bosses and mobs.
	g_hAllowTank		= CreateConVar("zspawn_dir_allow_tank",			"1",		"Director can spawn tanks (0 = deny, 1 = allow).\nDirector is always allowed to spawn tanks on finales to prevent game errors.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hAllowWitch		= CreateConVar("zspawn_dir_allow_witch",		"1",		"Director can spawn witches (0 = deny, 1 = allow).", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hAllowMob			= CreateConVar("zspawn_dir_allow_mob",			"1", 		"Director can spawn mobs. Does not affect vomit mobs (0 = deny, 1 = allow).\nDirector is allowed to spawn always mobs on finales to prevent game errors.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	// Random mobs and vomit mobs spawn sizes
	g_hMobAmountMin		= CreateConVar("zspawn_mob_min",			"20",		"Minimum amount zombies to spawn when a mob starts.\nAffects mobs generated by Director or by Plugin.", FCVAR_NOTIFY, true, 0.0);
	g_hMobAmountMax		= CreateConVar("zspawn_mob_max",			"45",		"Maximum amount of zombies to spawn when a mob starts.\nAffects mobs generated by Director or by Plugin.", FCVAR_NOTIFY, true, 0.0);
	g_hVomitAmountMin	= CreateConVar("zspawn_vomitmob_min",		"20",		"Minimum amount zombies to spawn when someone is on vomit.", FCVAR_NOTIFY, true, 0.0);
	g_hVomitAmountMax	= CreateConVar("zspawn_vomitmob_max",		"45",		"Maximum amount of zombies to spawn when someone is on vomit.", FCVAR_NOTIFY, true, 0.0);
	// Autospawn Special ConVars
	g_hAutoSEnable		= CreateConVar("zspawn_autosp_enable",			"1",		"Allow Plugin to automatically spawn special infected (0 = deny, 1 = allow).", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hAutoSTMin		= CreateConVar("zspawn_autosp_time_min",		"10.0",		"Minimum amount of time in seconds between auto special spawn.", FCVAR_NOTIFY, true, 0.1);
	g_hAutoSTMax		= CreateConVar("zspawn_autosp_time_max",		"25.0",		"Maximum amount of time in seconds between auto special spawn.", FCVAR_NOTIFY, true, 1.0);
	g_hAutoSTMod		= CreateConVar("zspawn_autosp_time_mode",		"1",		"Spawn time mode: 0 = random, 1 = incremental, 2 = decremental.\nIncremental: When more specials are alive time will approach to its maximum value.\nDecremental: its the opposite as incremental.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	g_hAutoSTDel		= CreateConVar("zspawn_autosp_time_delay",		"10.0",		"When autospawn begins or resumes, add extra time to the first spawn.", FCVAR_NOTIFY, true, 0.0);
	g_hAutoSFlowBlock	= CreateConVar("zspawn_autosp_stop_notmoving",	"1",		"If Survivors stop moving for a while, autospawn will stop.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hAutoSTankBlock	= CreateConVar("zspawn_autosp_stop_tank",		"1",		"Stop autospawn if a tank is in game.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hAutoSPanic		= CreateConVar("zspawn_autosp_panic",			"1",		"Allow panic events to invalidate autospawn stops.\n0 = Dont resume autospawn on panic events.\n1 = Panic will invalidate autospawn stop with players not moving.\n2 = Panic will invalidate autospawn stop with tank in game.\n3 = Panic will invalidate all autospawn stops.", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	g_hSpecialLimit		= CreateConVar("zspawn_autosp_limit",			"6",		"Max amount of special infected alive, tanks and witches not included in this count.", FCVAR_NOTIFY, true, 0.0, true, float(MAX_ZOMBIES));
	g_hAutoSAmount		= CreateConVar("zspawn_autosp_amount",			"1",		"Amount of special infected that will be autospawned at once.", FCVAR_NOTIFY, true, 1.0, true, float(MAX_ZOMBIES));
	g_hWeightScale		= CreateConVar("zspawn_autosp_weight_scale",	"1",		"Special weight will decrease based on the amount of zombies of its class alive.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	// This emulates survival and allows server admin to easily configure the limit of specials and the spawn times over time
	g_hSurvTime			= CreateConVar("zspawn_survival_time",				"600.0", 	"Amount of time in seconds to reach default spawn times and zombie limits. \nSet to 0 if you dont want spawn times and limits vary over survival game.", FCVAR_NOTIFY, true, 0.0);
	g_hSurvStLimit		= CreateConVar("zspawn_survival_start_limit",		"5",		"Limit of special infected when survival starts. \nZombie limit will transition to 'zspawn_autosp_limit' over the time defined in'zspawn_survival_time'.", FCVAR_NOTIFY, true, 0.0);
	g_hSurvStTimeMin	= CreateConVar("zspawn_survival_time_min",			"20",		"Minimum time between special autospawns when survival starts. \nTime will transition to 'zspawn_autosp_time_min' over the time defined in'zspawn_survival_time'.", FCVAR_NOTIFY, true, 0.1);
	g_hSurvStTimeMax	= CreateConVar("zspawn_survival_time_max",			"45",		"Maximum time between special autospawns when survival starts. \nTime will transition to 'zspawn_autosp_time_man' over the time defined in'zspawn_survival_time'.", FCVAR_NOTIFY, true, 1.0);
	//Autospawn bosses. I added a limit of 64 because each boss must be saved in an array to repeat the amount and location of bosses in versus rounds
	g_hTankMin			= CreateConVar("zspawn_autotank_min",			"1",		"Minimum amount of tanks that will be autospawned on each map.", FCVAR_NOTIFY, true, 0.0, true, 64.0);
	g_hTankMax			= CreateConVar("zspawn_autotank_max",			"2",		"Maximum amount of tanks that will be autospawned on each map.", FCVAR_NOTIFY, true, 0.0, true, 64.0);
	g_hWitchMin			= CreateConVar("zspawn_autowitch_min",			"1",		"Minimum amount of witches that will be autospawned on each map.", FCVAR_NOTIFY, true, 0.0, true, 64.0);
	g_hWitchMax			= CreateConVar("zspawn_autowitch_max",			"3",		"Maximum amount of witches that will be autospawned on each map.", FCVAR_NOTIFY, true, 0.0, true, 64.0);
	// Autospawn mob
	g_hAutoMEnable		= CreateConVar("zspawn_automob_enable",			"1",		"Allow Plugin to automatically call mobs over time (0 = deny, 1 = allow).", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hAutoMTMin		= CreateConVar("zspawn_automob_time_min",		"90.0",		"Minimum amount of time in seconds between auto mob spawns.", FCVAR_NOTIFY, true, 0.1);
	g_hAutoMTMax		= CreateConVar("zspawn_automob_time_max",		"240.0",	"Maximum amount of time in seconds between auto mob spawns.", FCVAR_NOTIFY, true, 1.0);
	if (g_bL4D2)
	{
		g_hGameModeOverride	= CreateConVar("zspawn_gamemode_override",		"0",		"Force plugin to work in the gamemode that you choose.\nUse this convar if your gamemode or mutation is not detected correctly.\n0 = do not override, 1 = coop, 2 = versus, 3 = survival, 4 = Scavenge.", FCVAR_NOTIFY, true, 0.0, true, 4.0);
		g_hAllowSI			= CreateConVar("zspawn_dir_allow_special",	LIMIT_L4D2,		"Allow which special infected can be spawned by Director.\n0 = Special denied, 1 = Special allowed.\nMust place 6 values, separated by commas, no spaces.\n <smoker>,<boomer>,<hunter>,<spitter>,<jockey>,<charger>", FCVAR_NOTIFY);
		g_hAutoSWeight		= CreateConVar("zspawn_autosp_weights",		WEIGHT_L4D2,	"Autospawn zombie weights, it determines the chance that each special infected is spawned respect to the others.\nChance of special spawn = Weight/sum of all Weights.\nMust place 6 values, separated by comma, no spaces.\n<smoker>,<boomer>,<hunter>,<spitter>,<jockey>,<charger>", FCVAR_NOTIFY);
		g_hAutoSLimits		= CreateConVar("zspawn_autosp_limit_class",	LIMIT_L4D2,		"Limit of each special infected class alive, put the limits separated with commas, no spaces. \n <smoker>,<boomer>,<hunter>,<spitter>,<jockey>,<charger>", FCVAR_NOTIFY);
		g_hTankScav			= CreateConVar("zspawn_autotank_scav_score",	"10",		"Determines the required score in scavenge to spawn a tank.\nWhen a tank has spawned, the plugin will count again to spawn another one.\nThis works in scavenge gamemode and in campaing scavenge finales.\n0 = No tanks on scavenge.", FCVAR_NOTIFY, true, 0.0);
		RegAdminCmd("sm_zspawn",	ZSpawnView,		ADMFLAG_KICK,	"Spawn an infected at your cursor position. Usage: sm_zspawn <zombietype> <amount>.\nValid zombietypes: hunter, smoker, boomer, charger, jockey, spitter, tank, witch.\nAmount: 1-16 zombies, if amount is not assigned, this command will spawn 1 zombie.");
		RegAdminCmd("sm_zauto",		ZSpawnAuto,		ADMFLAG_KICK,	"Spawn an infected in an automatic position. Usage: sm_zauto <zombietype> <amount>.\nValid zombietypes: hunter, smoker, boomer, charger, jockey, spitter, tank, witch.\nAmount: 1-16 zombies, if amount is not assigned, this command will spawn 1 zombie.");
	}
	else
	{
		g_hGameModeOverride	= CreateConVar("zspawn_gamemode_override",		"0",		"Force plugin to work in the gamemode that you choose.\n0 = do not override, 1 = coop, 2 = versus, 3 = Survival.", FCVAR_NOTIFY, true, 0.0, true, 3.0);
		g_hAllowSI			= CreateConVar("zspawn_dir_allow_special",	LIMIT_L4D,		"Allow which special infected can be spawned by Director.\n0 = Special denied, 1 = Special allowed.\nMust place 3 values, separated by commas, no spaces.\n <smoker>,<boomer>,<hunter>", FCVAR_NOTIFY);
		g_hAutoSWeight		= CreateConVar("zspawn_autosp_weights",		WEIGHT_L4D,		"Autospawn zombie weights, it determines the chance that each special infected is spawned respect to the others.\nChance of special spawn = Weight/sum of all Weights.\nMust place 3 values, separated by comma, no spaces.\n<smoker>,<boomer>,<hunter>", FCVAR_NOTIFY);
		g_hAutoSLimits		= CreateConVar("zspawn_autosp_limit_class",	LIMIT_L4D,		"Limit of each special infected class alive, put the limits separated with commas, no spaces. \n <smoker>,<boomer>,<hunter>", FCVAR_NOTIFY);
		RegAdminCmd("sm_zspawn",	ZSpawnView,		ADMFLAG_KICK,	"Spawn an infected at your cursor position. Usage: sm_zspawn <zombietype> <amount>.\nValid zombietypes: hunter, smoker, boomer, tank, witch.\nAmount: 1-16 zombies, if amount is not assigned, this command will spawn 1 zombie.");
		RegAdminCmd("sm_zauto",		ZSpawnAuto,		ADMFLAG_KICK,	"Spawn an infected in an automatic position. Usage: sm_zauto <zombietype> <amount>.\nValid zombietypes: hunter, smoker, boomer, tank, witch.\nAmount: 1-16 zombies, if amount is not assigned, this command will spawn 1 zombie.");
	}
	RegAdminCmd("sm_zmob",		ZSpawnMob,		ADMFLAG_KICK,	"Creates a mob that will attack survivors. Usage sm_zmob <amount>.");
	
	g_hCurrGameMode		= FindConVar("mp_gamemode");
	
	g_bPluginOn = false;
	if (g_bL4D2) AutoExecConfig(true, "l4d2_zspawn");
	else AutoExecConfig(true, "l4d_zspawn");
	
	g_hAllow.AddChangeHook(CVarChange_Enable);
	g_hGameModes.AddChangeHook(CVarChange_Enable);
	g_hCurrGameMode.AddChangeHook(CVarChange_Enable);

	g_hAllowSI.AddChangeHook(CVarChange_CVars);
	g_hAllowTank.AddChangeHook(CVarChange_CVars);
	g_hAllowWitch.AddChangeHook(CVarChange_CVars);
	g_hAllowMob.AddChangeHook(CVarChange_CVars);
	g_hAutoSTMod.AddChangeHook(CVarChange_CVars);
	g_hAutoSTDel.AddChangeHook(CVarChange_CVars);
	g_hAutoSFlowBlock.AddChangeHook(CVarChange_CVars);
	g_hAutoSTankBlock.AddChangeHook(CVarChange_CVars);
	g_hAutoSPanic.AddChangeHook(CVarChange_CVars);
	g_hSpecialLimit.AddChangeHook(CVarChange_CVars);
	g_hAutoSTMod.AddChangeHook(CVarChange_CVars);
	g_hAutoSWeight.AddChangeHook(CVarChange_CVars);
	g_hAutoSLimits.AddChangeHook(CVarChange_CVars);
	g_hAutoSAmount.AddChangeHook(CVarChange_CVars);
	g_hSurvTime.AddChangeHook(CVarChange_CVars);
	g_hSurvStLimit.AddChangeHook(CVarChange_CVars);
	g_hWeightScale.AddChangeHook(CVarChange_CVars);
	if (g_bL4D2) g_hTankScav.AddChangeHook(CVarChange_CVars);
	
	g_hAutoMEnable.AddChangeHook(CVarChange_Timers);
	g_hAutoSEnable.AddChangeHook(CVarChange_Timers);
	
	g_hMobAmountMin.AddChangeHook(CVarChange_Limits);
	g_hMobAmountMax.AddChangeHook(CVarChange_Limits);
	g_hVomitAmountMin.AddChangeHook(CVarChange_Limits);
	g_hVomitAmountMax.AddChangeHook(CVarChange_Limits);
	g_hAutoMTMin.AddChangeHook(CVarChange_Limits);
	g_hAutoMTMax.AddChangeHook(CVarChange_Limits);
	g_hAutoSTMin.AddChangeHook(CVarChange_Limits);
	g_hAutoSTMax.AddChangeHook(CVarChange_Limits);
	g_hSurvStTimeMin.AddChangeHook(CVarChange_Limits);
	g_hSurvStTimeMax.AddChangeHook(CVarChange_Limits);
}

public void OnConfigsExecuted()
{
	GetGameMode();
	SwitchPlugin();
	GetCVars();
	GetWeights();
	GetAutoSpecialLimit();
	GetDirectorSpecialAllow();
	GetLimitCVars();
	CVarTimers();
}

public void CVarChange_Enable(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetGameMode();
	SwitchPlugin();
}

public void CVarChange_CVars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCVars();
	GetWeights();
	GetAutoSpecialLimit();
	GetDirectorSpecialAllow();
}

public void CVarChange_Limits(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetLimitCVars();
}

public void CVarChange_Timers(Handle convar, const char[] oldValue, const char[] newValue)
{
	CVarTimers();
}

//==========================================================================================
//									ConVar Logic
//==========================================================================================
void GetCVars()
{
	g_bAllowTank = g_hAllowTank.BoolValue;
	g_bAllowWitch = g_hAllowWitch.BoolValue;
	g_bAllowMob = g_hAllowMob.BoolValue;
	g_iVomitAmountMin = g_hVomitAmountMin.IntValue;
	g_iVomitAmountMax = g_hVomitAmountMax.IntValue;
	g_iSpecialLimit = g_hSpecialLimit.IntValue;
	g_fAutoSTDel = g_hAutoSTDel.FloatValue;
	g_bAutoSFlowBlock = g_hAutoSFlowBlock.BoolValue;
	g_bAutoSTankBlock = g_hAutoSTankBlock.BoolValue;
	g_iAutoSPanic = g_hAutoSPanic.IntValue;
	g_iAutoSTMod = g_hAutoSTMod.IntValue;
	g_iAutoSAmount = g_hAutoSAmount.IntValue;
	g_fSurvTime = g_hSurvTime.FloatValue;
	g_iSurvStLimit = g_hSurvStLimit.IntValue;
	g_bWeightScale = g_hWeightScale.BoolValue;
	if (g_bL4D2) g_iTankScav = g_hTankScav.IntValue;
}
// Enables/disables timers when CVar is changed if game has started
void CVarTimers()
{
	if (g_bAutoSEnable != g_hAutoSEnable.BoolValue)
	{
		g_bAutoSEnable = g_hAutoSEnable.BoolValue;
		if (g_bAutoSEnable && g_bGameStarted)
		{
			delete g_hSpawnTimer;
			g_hSpawnTimer = CreateTimer(NextSpawnTime(true), AutoSpawn_Timer);
			BlockSpecials();
		}
		if (!g_bAutoSEnable && g_bGameStarted)
		{
			delete g_hSpawnTimer;
			UnblockSpecials();
		}
	}
	if (g_bAutoMEnable != g_hAutoMEnable.BoolValue)
	{
		g_bAutoMEnable = g_hAutoMEnable.BoolValue;
		if (g_bAutoMEnable && g_bGameStarted)
		{
			delete g_hMobTimer;
			g_hMobTimer = CreateTimer(GetRandomFloat(g_fAutoMTMin, g_fAutoMTMax), Mob_Timer);
		}
		if (!g_bAutoMEnable && g_bGameStarted)
			delete g_hMobTimer;
	}
}

void GetWeights()
{
	g_hAutoSWeight.GetString(g_sAutoSWeight, sizeof(g_sAutoSWeight));

	if (ExplodeString(g_sAutoSWeight, ",", g_sArWeights, sizeof(g_sArWeights), sizeof(g_sArWeights[])) == g_iZClassAm)
	{
		for (int i = 0; i < g_iZClassAm; i++)
			g_iArWeights[i] = StringToInt(g_sArWeights[i]);
	}
	else 
	{
		ResetConVar(g_hAutoSWeight);
		PrintToServer("[ZSpawn] WARNING: Cannot get 'zspawn_auto_weights', check if the cvar has been set properly.");
		for (int i = 0; i < g_iZClassAm; i++)
			g_iArWeights[i] = 100;
	}
}

void GetAutoSpecialLimit()
{
	g_hAutoSLimits.GetString(g_sAutoSLimits, sizeof(g_sAutoSLimits));
	if (ExplodeString(g_sAutoSLimits, ",", g_sArLimits, sizeof(g_sArLimits), sizeof(g_sArLimits[])) == g_iZClassAm)
	{
		for (int i = 0; i < g_iZClassAm; i++)
			g_iArLimits[i] = StringToInt(g_sArLimits[i]);
	}
	else 
	{
		ResetConVar(g_hAutoSLimits);
		PrintToServer("[ZSpawn] WARNING: Cannot get 'zspawn_class_limit', check if the cvar has been set properly.");
		for (int i = 0; i < g_iZClassAm; i++)
			g_iArLimits[i] = 1;
	}
}

void GetDirectorSpecialAllow()
{
	g_hAllowSI.GetString(g_sAllowSI, sizeof(g_sAllowSI));
	if (ExplodeString(g_sAllowSI, ",", g_sArAllowSI, sizeof(g_sArAllowSI), sizeof(g_sArAllowSI[])) == g_iZClassAm)
	{
		for (int i = 0; i < g_iZClassAm; i++)
			g_iArAllowSI[i] = StringToInt(g_sArAllowSI[i]);
	}
	else 
	{
		ResetConVar(g_hAllowSI);
		PrintToServer("[ZSpawn] WARNING: Cannot get 'zspawn_director_special_allow', check if the cvar has been set properly.");
		for (int i = 0; i < g_iZClassAm; i++)
			g_iArAllowSI[i] = 1;
	}
}

void GetLimitCVars()
{
	g_fAutoSTMin = g_hAutoSTMin.FloatValue;
	g_iMobAmountMin = g_hMobAmountMin.IntValue;
	g_fAutoMTMin = g_hAutoMTMin.FloatValue;
	g_fSurvStTimeMin = g_hSurvStTimeMin.FloatValue;
	
	if(g_fAutoSTMin > g_hAutoSTMax.FloatValue)
	{
		PrintToServer("[ZSpawn] WARNING: 'zspawn_auto_time_max' cannot be lower than 'zspawn_auto_time_min', clamping.");
		g_fAutoSTMax = g_fAutoSTMin;
	}
	else g_fAutoSTMax = g_hAutoSTMax.FloatValue;

	if (g_iMobAmountMin > g_hMobAmountMax.IntValue)
	{
		PrintToServer("[ZSpawn] WARNING: 'zspawn_mob_max' cannot be lower than 'zspawn_mob_min', clamping.");
		g_iMobAmountMax = g_iMobAmountMin;
	}
	else g_iMobAmountMax = g_hMobAmountMax.IntValue;
		
	if (g_fAutoMTMin > g_hAutoMTMax.FloatValue)
	{
		PrintToServer("[ZSpawn] WARNING: 'zspawn_automob_time_max' cannot be lower than 'zspawn_automob_time_min, clamping.");
		g_fAutoMTMax = g_fAutoMTMin; 
	}
	else g_fAutoMTMax = g_hAutoMTMax.FloatValue;
	
	if (g_fSurvStTimeMin > g_hSurvStTimeMax.FloatValue)
	{
		PrintToServer("[ZSpawn] WARNING: 'zspawn_survival_time_max' cannot be lower than 'zspawn_survival_time_max', clamping.");
		g_fSurvStTimeMax = g_fSurvStTimeMin;
	}
	else g_fSurvStTimeMax = g_hSurvStTimeMin.FloatValue;
}

void SwitchPlugin()
{
	g_bAllow = g_hAllow.BoolValue;
	if (g_bPluginOn == false && g_bAllow == true && g_iGameMode != 0)
	{
		g_bPluginOn = true;
		SetMaxSpecials();
		HookEvent("create_panic_event", 	Event_Panic_Start);
		HookEvent("finale_start",			Event_Finale_Start);
		HookEvent("round_end",				Event_Round_End);
		if (g_bL4D2)
		{
			HookEvent("panic_event_finished", 	Event_Panic_End);	// This event does not exist on L4D
			HookEvent("gascan_pour_completed",	Event_Gascan);
		}
	}
	if (g_bPluginOn == true && (g_bAllow == false || g_iGameMode == 0))
	{
		g_bPluginOn = false;
		ResetMaxSpecials();
		UnblockSpecials();
		UnhookEvent("create_panic_event", 		Event_Panic_Start);
		UnhookEvent("finale_start",				Event_Finale_Start);
		UnhookEvent("round_end",				Event_Round_End);
		if (g_bL4D2)
		{
			UnhookEvent("panic_event_finished", Event_Panic_End);
			UnhookEvent("gascan_pour_completed",	Event_Gascan);
		}
	}
}

void GetGameMode()	//Returns 0 if gamemode is not allowed, 1-3 if gamemode is allowed
{
	g_iGameMode = 0;
	if (g_hCurrGameMode == null)
		return;

	char sGameModes[64];
	g_hCurrGameMode.GetString(g_sGameMode, sizeof(g_sGameMode));	// Store "mp_gamemode" result in g_sGameMode
	g_hGameModes.GetString(sGameModes, sizeof(sGameModes));		// Store all gamemodes which will start plugin in sGameModes
	
	if (sGameModes[0])	// If string is not empty that means that server admin only wants plugin in some gamemodes
	{
		if (StrContains(sGameModes, g_sGameMode, false) == -1)	// Check if the current gamemode is not in the list of allowed gamemodes
		{
			g_iGameMode = 0;
			return;
		}
	}
	if (g_hGameModeOverride.IntValue < 0)	// If server admin wants to override plugin gamemode behaviour
	{
		g_iGameMode = g_hGameModeOverride.IntValue;
		return;
	}
	if (!g_bMapStarted)
		return;
	// Special thanks to Silvers, for suggesting "info_gamemode"
	int entity = CreateEntityByName("info_gamemode");
	if( IsValidEntity(entity) )
	{
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "PostSpawnActivate");
		if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
			RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
	}
	
	if (g_iGameMode == 0)	// If we reach this line of code that means that the current gamemode is not detected.
		PrintToServer("[ZSpawn] ERROR: Plugin cannot detect current gamemode, use 'zspawn_gamemode_override' to get full functionality in this gamemode.");
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iGameMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iGameMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iGameMode = 3;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iGameMode = 4;
}


void EndGame()
{
	if (g_bGameStarted)
	{
		delete g_hFlowTimer;
		delete g_hSpawnTimer;
		delete g_hMobTimer;
		g_bGameStarted = false;
	}
	if (g_bIsFinale)
		g_bIsFinale = false;
		
	if (g_bIsPanicEvent)
		g_bIsPanicEvent = false;
}

void SetMaxSpecials()	// Remove SI limits for vs and survival, coop limits are overriden with script (see L4D_OnGetScriptValueInt)
{
	SetConVarBounds(FindConVar("z_max_player_zombies") , ConVarBound_Upper, true, float(MAX_ZOMBIES));
	SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, false);
	SetConVarFloat(FindConVar("z_max_player_zombies"), float(MAX_ZOMBIES));
	SetConVarInt(FindConVar("z_minion_limit"), MAX_ZOMBIES);
	if (g_bL4D2)
		SetConVarInt(FindConVar("survival_max_specials"), MAX_ZOMBIES);
	else
		SetConVarInt(FindConVar("holdout_max_specials"), MAX_ZOMBIES);
}

void ResetMaxSpecials()
{
	ResetConVar(FindConVar("z_max_player_zombies"), true, false);	// Reset convar for all clients but do not notify
	ResetConVar(FindConVar("z_minion_limit"), true, false);	
	if (g_bL4D2)
		ResetConVar(FindConVar("survival_max_specials"), true, false);
}

/* When autospawn is enabled plugin will block SI with ConVars, using "L4D_OnSpawnSpecial" to block everything but autospawn would block other plugin spawns,
 * making it incompatible with other plugins.*/
void BlockSpecials()	
{
	SetConVarInt(FindConVar("z_hunter_limit"), 0);
	if (g_bL4D2)
	{
		SetConVarInt(FindConVar("z_smoker_limit"), 0);
		SetConVarInt(FindConVar("survival_max_smokers"), 0);
		SetConVarInt(FindConVar("z_boomer_limit"), 0);
		SetConVarInt(FindConVar("survival_max_boomers"), 0);
		SetConVarInt(FindConVar("survival_max_hunters"), 0);
		SetConVarInt(FindConVar("z_spitter_limit"), 0);
		SetConVarInt(FindConVar("survival_max_spitters"), 0);
		SetConVarInt(FindConVar("z_jockey_limit"), 0);
		SetConVarInt(FindConVar("survival_max_jockeys"), 0);
		SetConVarInt(FindConVar("z_charger_limit"), 0);
		SetConVarInt(FindConVar("survival_max_chargers"), 0);
	}
	else
	{
		SetConVarInt(FindConVar("z_gas_limit"), 0);
		SetConVarInt(FindConVar("z_exploding_limit"), 0);
		SetConVarInt(FindConVar("holdout_max_boomers"), 0);
		SetConVarInt(FindConVar("holdout_max_smokers"), 0);
		SetConVarInt(FindConVar("holdout_max_hunters"), 0);
	}
}

void UnblockSpecials()
{
	ResetConVar(FindConVar("z_hunter_limit"), true, false);
	if (g_bL4D2)
	{
		ResetConVar(FindConVar("z_smoker_limit"), true, false);
		ResetConVar(FindConVar("survival_max_smokers"), true, false);
		ResetConVar(FindConVar("z_boomer_limit"), true, false);
		ResetConVar(FindConVar("survival_max_boomers"), true, false);
		ResetConVar(FindConVar("survival_max_hunters"), true, false);
		ResetConVar(FindConVar("z_spitter_limit"), true, false);
		ResetConVar(FindConVar("survival_max_spitters"), true, false);
		ResetConVar(FindConVar("z_jockey_limit"), true, false);
		ResetConVar(FindConVar("survival_max_jockeys"), true, false);
		ResetConVar(FindConVar("z_charger_limit"), true, false);
		ResetConVar(FindConVar("survival_max_chargers"), true, false);
	}
	else
	{
		ResetConVar(FindConVar("z_gas_limit"), true, false);
		ResetConVar(FindConVar("z_exploding_limit"), true, false);
		ResetConVar(FindConVar("holdout_max_boomers"), true, false);
		ResetConVar(FindConVar("holdout_max_smokers"), true, false);
		ResetConVar(FindConVar("holdout_max_hunters"), true, false);
	}
}
//==========================================================================================
//								Events & Left 4 DHooks
//==========================================================================================
public void OnMapStart()
{
	g_bBossPlaced = false;
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	EndGame();
}

public void OnPluginEnd()
{
	ResetMaxSpecials();
	UnblockSpecials();
}


public Action Event_Panic_Start(Event event, const char[] name, bool dontBroadcast)
{
	g_bIsPanicEvent = true;
	if (g_iGameMode == 3 && !g_bGameStarted)
	{
		g_fSurvStart = GetGameTime();		// We need a time reference to know when did survival started
		g_bGameStarted = true;
		if (g_bAutoSEnable)
		{
			g_hSpawnTimer = CreateTimer(NextSpawnTime(true), AutoSpawn_Timer);
			BlockSpecials();
		}
	}
	if (!g_bL4D2)
	{
		delete g_hPanicTimer;
		g_hPanicTimer = CreateTimer(120.0, Panic_Timer);	// "panic_event_finished" does not exist in L4D, create a timer that sets g_bIsPanicEvent to false after 2 minutes.
	}
}

public Action Event_Panic_End(Event event, const char[] name, bool dontBroadcast)
{
	g_bIsPanicEvent = false;
}

public Action Event_Finale_Start(Event event, const char[] name, bool dontBroadcast)
{
	g_bIsFinale = true;
}

public Action Event_Round_End(Event event, const char[] name, bool dontBroadcast)
{
	EndGame();
	UnblockSpecials();
}

public Action Event_Gascan(Event event, const char[] name, bool dontBroadcast)
{
	if (g_iTankScav == 0)
		return;
	
	g_iGasCount++;
	if (g_iGasCount >= g_iTankScav)
	{
		float vPos[3];
		L4D_GetRandomPZSpawnPosition(0, 8, 5, vPos);
		L4D2_SpawnTank(vPos, NULL_VECTOR);
		
	}
}
public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{

	if (g_iGameMode == 3)	//Block this event on survival or plugin will instantly start to spawn SI at the setup stage
		return;

	if (g_iGameMode != 4)
	{
		SetupBosses();
		g_fMaxMapProgress = 0.0;
		g_iTanksSpawned = 0;
		g_iWitchesSPawned = 0;
		g_fNextProgressTank = NextTankInProgress();
		g_fNextProgressWitch = NextWitchInProgress();
		delete g_hFlowTimer;
		g_hFlowTimer = CreateTimer(1.0, GetFlow_Timer, _, TIMER_REPEAT);
	}
	if (g_bAutoSEnable)
	{
		delete g_hSpawnTimer;
		SetMaxSpecials();
		g_hSpawnTimer = CreateTimer(NextSpawnTime(true), AutoSpawn_Timer);
		BlockSpecials();
	}	
	if (g_bAutoMEnable)
	{
		delete g_hMobTimer;
		g_hMobTimer = CreateTimer(GetRandomFloat(g_fAutoMTMin, g_fAutoMTMax), Mob_Timer);
	}	
	g_bGameStarted = true;
}
// Hook Special infected spawn. zombieClass: 1=Smoker, 2=Boomer, 3=Hunter, 4=Spitter, 5=Jockey, 6=Charger
public Action L4D_OnSpawnSpecial(int &zombieClass, const float vecPos[3], const float vecAng[3])
{
	if (!g_bPluginOn)
		return Plugin_Continue;
		
	if (g_bPluginSpawnRequest == true)	// If the spawn has been requested from the plugin, allow special to spawn
	{
		g_bPluginSpawnRequest = false;
		return Plugin_Continue;
	}
// Dont use this, it was used to block director spawns when autospawn was enabled, but also was blocking other plugins spawn
//	if (g_bAutoSEnable)	return Plugin_Handled;
		
	if (g_iArAllowSI[zombieClass -1] == 0)	// If zombieclass is forbidden plugin will try to spawn another random allowed class
	{
		int iValidClass = GetValidZombie();
		if (iValidClass == 0) 
			return Plugin_Handled;

		else
		{
			zombieClass = iValidClass;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action L4D_OnSpawnTank(const float vecPos[3], const float vecAng[3])
{
	if (!g_bPluginOn)
		return Plugin_Continue;

	if (g_bPluginSpawnRequest == true)
	{
		g_bPluginSpawnRequest = false;
		return Plugin_Continue;
	}
	if (!g_bAllowTank && !g_bIsFinale)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D_OnSpawnWitch(const float vecPos[3], const float vecAng[3])
{
	if (!g_bPluginOn)
		return Plugin_Continue;

	if (g_bPluginSpawnRequest == true)
	{
		g_bPluginSpawnRequest = false;
		return Plugin_Continue;
	}
	if (!g_bAllowWitch)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D_OnSpawnMob(int &amount)
{
	if (!g_bPluginOn)
		return Plugin_Continue;

	if (g_bPluginSpawnRequest)
	{
		amount = g_iNextMobSize;
		g_bPluginSpawnRequest = false;
		return Plugin_Changed;
	}	
	if (!g_bAllowMob && !g_bIsFinale && !g_bIsPanicEvent)
		return Plugin_Handled;

	amount = GetRandomInt(g_iMobAmountMin, g_iMobAmountMax);
	return Plugin_Changed;
}

public Action L4D_OnSpawnITMob(int &amount)
{
	if (!g_bPluginOn)
		return Plugin_Continue;

	amount = GetRandomInt(g_iVomitAmountMin, g_iVomitAmountMax);
	return Plugin_Changed;
}

//	This works fine on coop but fails to increase special limit on any other gamemode
public Action L4D_OnGetScriptValueInt(const char[] key, int &retVal)	// Change Directors script max specials to spawn SI over the limit
{
	if (StrEqual(key, "MaxSpecials"))
	{
		retVal = MAX_ZOMBIES;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
//==========================================================================================
//									Admin Commands
//==========================================================================================
public Action ZSpawnView(int client, int args)
{
	if (!g_bPluginOn)
		return Plugin_Handled;

	if (!client)
	{
		ReplyToCommand(client, "%s This command can be only used in game.", CHAT_TAG);
		return Plugin_Handled;
	}
	if (args < 1 || args > 2)
	{
		ReplyToCommand(client, "%s Invalid number of arguments, use sm_zspawn <zombietype> <amount>.", CHAT_TAG);
		return Plugin_Handled;
	}
	float vPos[3], vAng[3];
	if(!SetSpawnPos(client, vPos, vAng))
	{
		ReplyToCommand(client, "%s Cannot Spawn infected, please try another location.", CHAT_TAG);
		return Plugin_Handled;
	}
	
	char sArgs[16], sArgs2[8];
	int iAmt;
	GetCmdArg(1, sArgs, sizeof(sArgs));
	if (args == 2)
	{
		GetCmdArg(2, sArgs2, sizeof(sArgs2));
		iAmt = StringToInt(sArgs2);
	}
	if (iAmt < 1)
		iAmt = 1;
	if (iAmt > 16)
		iAmt = 16;
		
	int iClass = -1;
	for (int i = 0; i < g_iZClassAm + 2; i++)	// 3 or 6 zombie classes + tank & witch
	{
		if (g_bL4D2)
		{
			if (StrEqual(g_sZombieClasses_L4D2[i], sArgs, false))
			{
				iClass = i;
				break;
			}
		}
		else
		{
			if (StrEqual(g_sZombieClasses_L4D[i], sArgs, false))
			{
				iClass = i;
				break;
			}	
		}
	}
	int iZPreSpawnCount, iZPostSPawnCount;
	if (iClass < 0)
	{
		if (g_bL4D2)
			ReplyToCommand(client, "%s Invalid zombie class, valid classes: hunter, boomer, smoker, charger, jockey, spitter, tank & witch.", CHAT_TAG);
			
		else
			ReplyToCommand(client, "%s Invalid zombie class, valid classes: hunter, boomer, smoker, tank & witch.", CHAT_TAG);
		return Plugin_Handled;
	}
	else if (iClass == 0)
	{
		iZPreSpawnCount = GetSpecialAm();
		for (int i = 0; i < iAmt; i++)
		{
			g_bPluginSpawnRequest = true;
			L4D2_SpawnTank(vPos, NULL_VECTOR);
		}
		iZPostSPawnCount = GetSpecialAm();
	}
	else if (iClass <= g_iZClassAm)
	{
		iZPreSpawnCount = GetSpecialAm();
		for (int i = 0; i < iAmt; i++)
		{
			g_bPluginSpawnRequest = true;
			L4D2_SpawnSpecial(iClass, vPos, NULL_VECTOR);
		}
		iZPostSPawnCount = GetSpecialAm();
	}
	else
	{
		iZPreSpawnCount = GetWitchAm();
		for (int i = 0; i < iAmt; i++)
		{
			g_bPluginSpawnRequest = true;
			L4D2_SpawnWitch(vPos, NULL_VECTOR);
		}
		iZPostSPawnCount = GetWitchAm();
	}
	if (iZPreSpawnCount < iZPostSPawnCount)
	{
		if (iAmt == 1)
			ReplyToCommand(client, "%s Zombie successfully spawned.", CHAT_TAG);
			
		else
			ReplyToCommand(client, "%s Successfully spawned %i/%i zombies.", CHAT_TAG, (iZPostSPawnCount - iZPreSpawnCount), iAmt);
	}
	else
		ReplyToCommand(client, "%s ERROR: Zombie spawn failed.", CHAT_TAG);
		
	return Plugin_Handled;
}

public Action ZSpawnAuto(int client, int args)
{
	if (!g_bPluginOn)
		return Plugin_Handled;
		
	if (!client)
	{
		ReplyToCommand(client, "%s This command can be only used in game.", CHAT_TAG);
		return Plugin_Handled;
	}
	if (args < 1 || args > 2)
	{
		ReplyToCommand(client, "%s Invalid number of arguments, use sm_zspawn <zombietype> <amount>.", CHAT_TAG);
		return Plugin_Handled;
	}
	char sArgs[16], sArgs2[8];
	int iAmt;
	GetCmdArg(1, sArgs, sizeof(sArgs));
	if (args == 2)
	{
		GetCmdArg(2, sArgs2, sizeof(sArgs2));
		iAmt = StringToInt(sArgs2);
	}
	if (iAmt < 1)
		iAmt = 1;
	if (iAmt > 16)
		iAmt = 16;
		
	int iClass = -1;
	for (int i = 0; i < g_iZClassAm + 2; i++)	// 3 or 6 zombie classes + tank & witch
	{
		if (g_bL4D2)
		{
			if (StrEqual(g_sZombieClasses_L4D2[i], sArgs, false))
			{
				iClass = i;
				break;
			}
		}
		else
		{
			if (StrEqual(g_sZombieClasses_L4D[i], sArgs, false))
			{
				iClass = i;
				break;
			}	
		}
	}
	int iZPreSpawnCount, iZPostSPawnCount;
	if (iClass < 0)
	{
		if (g_bL4D2)
			ReplyToCommand(client, "%s Invalid zombie class, valid classes: hunter, boomer, smoker, charger, jockey, spitter, tank & witch.", CHAT_TAG);
			
		else
			ReplyToCommand(client, "%s Invalid zombie class, valid classes: hunter, boomer, smoker, tank & witch.", CHAT_TAG);
			
		return Plugin_Handled;
	}
	else
	{
		if (iClass == g_iZClassAm + 1)
			iZPreSpawnCount = GetWitchAm();

		else
			iZPreSpawnCount = GetSpecialAm();
			
		for (int i = 0; i < iAmt; i++)
		{
			g_bPluginSpawnRequest = true;
			SpawnZombie(client, iClass);
		}
		
		if (iClass == g_iZClassAm + 1)
			iZPostSPawnCount = GetWitchAm();

		else
			iZPostSPawnCount = GetSpecialAm();
	}
	if (iZPreSpawnCount < iZPostSPawnCount)
	{
		if (iAmt == 1)
			ReplyToCommand(client, "%s Zombie successfully spawned.", CHAT_TAG);
			
		else
			ReplyToCommand(client, "%s Successfully spawned %i/%i zombies.", CHAT_TAG, (iZPostSPawnCount - iZPreSpawnCount), iAmt);
	}
	else
		ReplyToCommand(client, "%s ERROR: Zombie spawn failed.", CHAT_TAG);
		
	return Plugin_Handled;
}

public Action ZSpawnMob (int client, int args)
{
	int i = -1;
	while ((i = FindEntityByClassname(i, "player")) != -1)
	{
	}
	if (!g_bPluginOn)
		return Plugin_Handled;

	if (!client)
	{
		ReplyToCommand(client, "%s This command can be only used in game.", CHAT_TAG);
		return Plugin_Handled;
	}
	if (args != 1)
	{
		ReplyToCommand(client, "%s Invalid number of arguments, use sm_zmob <amount>.", CHAT_TAG);
		return Plugin_Handled;
	}
	
	g_bPluginSpawnRequest = true;
	
	char sArgs[16];
	GetCmdArg(1, sArgs, sizeof(sArgs));
	g_iNextMobSize = StringToInt(sArgs);
	// Using a cheat command to call a mob
	if (g_bL4D2)
	{
		int iFlags = GetCommandFlags("z_spawn_old");
		SetCommandFlags("z_spawn_old", iFlags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "z_spawn_old %s", "mob");
		SetCommandFlags("z_spawn_old", iFlags);
	}
	else
	{
		int iFlags = GetCommandFlags("z_spawn");
		SetCommandFlags("z_spawn", iFlags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "z_spawn %s", "mob");
		SetCommandFlags("z_spawn", iFlags);	
	}
	return Plugin_Handled;
}
//==========================================================================================
//										RayTrace
//==========================================================================================
// I copied raytrace from Weapon Spawn by Silvers, and modified it: https://forums.alliedmods.net/showthread.php?t=222934
bool SetSpawnPos(int client, float vPos[3], float vAng[3])
{
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_NPCSOLID_BRUSHONLY, RayType_Infinite, _TraceFilter);

	if( TR_DidHit(trace) )
	{
		TR_GetEndPosition(vPos, trace);
		vPos[2] += 4.0;
		if (!HasNoObstacles(vPos))
		{
			delete trace;
			return false;
		}
	}
	delete trace;
	return true;
}

bool HasNoObstacles(const float vPos[3])
{
	float vAng[3], vEnd[3];
	Handle trace2;
	vAng[0] = -90.0;	// Fire a raytrace straight up to check if there is a roof that blocks zombie spawn
	trace2 = TR_TraceRayFilterEx(vPos, vAng, MASK_NPCSOLID_BRUSHONLY, RayType_Infinite, _TraceFilter);
	if (TR_DidHit(trace2))
	{
		TR_GetEndPosition(vEnd, trace2);
		if (GetVectorDistance(vEnd, vPos, true) < 5184.0)
		{
			delete trace2;
			return false;
		}
	}
	vAng[0]= 0.0;
	
	for (int i = 0; i < 8; i++)	// Fire 8 traces to check if there is a wall or an obstacle near the spawn which could block zombie
	{
		vAng[1] = 45.0 * i;
		trace2 = TR_TraceRayFilterEx(vPos, vAng, MASK_NPCSOLID_BRUSHONLY, RayType_Infinite, _TraceFilter);
		if (TR_DidHit(trace2))	// Fixed raytrace
		{
			TR_GetEndPosition(vEnd, trace2);
			if (GetVectorDistance(vEnd, vPos, true) < 256.0)
			{
				delete trace2;
				return false;
			}
		}
	}
	delete trace2;
	return true;
}

bool _TraceFilter(int entity, int contentsMask)
{
	char sName[32];
	GetEntityClassname (entity, sName, sizeof(sName));
	if (StrEqual(sName, "infected", false) || StrEqual(sName, "witch"))	// Ignore zombies and witches
		return false;
	return entity > MaxClients || !entity;
}
//==========================================================================================
//										Timers
//==========================================================================================
public Action GetFlow_Timer(Handle timer)		//Get team flow to check if team is moving and the map progress for spawns
{
	if (!g_bPluginOn)
		return Plugin_Continue;
	if (!g_bGameStarted)
		return Plugin_Stop;

	float fPlayerFlow, fTeamFlow, fFlowDelta, fHighestFlow, fMapProgress;
	int iAliveSurv = 0;
	
// Trying to get map max flow at the beggining of round is usually inacurate, it gets more and more accurate when survivors are closer to saferoom.
	g_fMapFlow = L4D2Direct_GetMapMaxFlowDistance();
	
// Get the count of alive survivors and the sum of all player flow to get the average team flow
	for (int i = 1; i < MaxClients; i++)	
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			fPlayerFlow = L4D2Direct_GetFlowDistance(i);
			if (fHighestFlow < fPlayerFlow)
				fHighestFlow = fPlayerFlow;

			fTeamFlow += fPlayerFlow;
			iAliveSurv++;
		}
	}
// Set the max map progress in % for boss spawning
	fMapProgress = (fHighestFlow * 100) / g_fMapFlow;	
	if (g_fMaxMapProgress < fMapProgress)
		g_fMaxMapProgress = fMapProgress;
		
// Determine if team has moved enough to add or remove tokens for autospawn. When 50 tokens have been reached autospawn will stop
	fTeamFlow = fTeamFlow/iAliveSurv;
	fFlowDelta = FloatAbs(fTeamFlow - g_fLastValidTFlow);
	if (fFlowDelta < 500.0)
	{
		if (g_iFlowToken < 50)
			g_iFlowToken ++;	// Add 1 token per timer (second) when survivors dont move 
		else
			g_iFlowToken = 50;
	}
	else
	{
		g_fLastValidTFlow = fTeamFlow;
		g_iFlowToken = 0;	//Remove all tokens if team moves
	}
	
// Compare map progress and progress required to spawn tankm for tank autospawn
	if (g_fNextProgressTank > -1.0 && g_fNextProgressTank < g_fMaxMapProgress)
	{
		SpawnZombie(RandomAliveSurvivor(), 0);
		g_iTanksSpawned++;
		g_fNextProgressTank = NextTankInProgress();
	}
	
	if (g_fNextProgressWitch > -1.0 && g_fNextProgressWitch < g_fMaxMapProgress)
	{
		SpawnZombie(RandomAliveSurvivor(), 7);
		g_iWitchesSPawned++;
		g_fNextProgressWitch = NextWitchInProgress();
	}
	return Plugin_Continue;
}

public Action AutoSpawn_Timer(Handle timer)
{
	g_hSpawnTimer = null;

	if (!g_bPluginOn || !g_bGameStarted)
		return;

	if (IsAutoAllowed() == 0)
	{
		g_bAutoSpawnBlocked = true;
		g_hSpawnTimer = CreateTimer(1.0, AutoSpawn_Timer);
		return;
	}
	int iSurvivor = RandomAliveSurvivor();
	NextSpecialSpawn();
	for (int i = 0; i < g_iAutoSAmount; i++)
	{	
		int zc = g_iArClassQueue[i];
		if (zc != -1)
			SpawnZombie(iSurvivor, zc + 1);
			
		else break;
	}
	if (IsAutoAllowed() == -1)	// A horde has enabled again the special spawn, it will respawn autospawn without adding a delay
	{
		g_bAutoSpawnBlocked = false;
		g_hSpawnTimer = CreateTimer(NextSpawnTime(false), AutoSpawn_Timer);
		return;
	}
	if (g_bAutoSpawnBlocked)	// Autospawn is resumed, but with a delay
	{
		g_bAutoSpawnBlocked = false;
		g_hSpawnTimer = CreateTimer(NextSpawnTime(true), AutoSpawn_Timer);
		return;
	}
	g_hSpawnTimer = CreateTimer(NextSpawnTime(false), AutoSpawn_Timer);
}

public Action Mob_Timer(Handle timer)
{
	g_hMobTimer = null;
	if(IsAutoAllowed() == 0)
	{
		g_hMobTimer = CreateTimer(1.0, Mob_Timer);
		return;
	}
	int iClient;
	for (iClient = 1; iClient < MaxClients; iClient++)
	{
		if (IsClientInGame(iClient) && IsClientConnected(iClient))
			break;
	}
	int iFlags = GetCommandFlags("z_spawn_old");
	SetCommandFlags("z_spawn_old", iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(iClient, "z_spawn_old %s", "mob");
	SetCommandFlags("z_spawn_old", iFlags);
	g_hMobTimer = CreateTimer(GetRandomFloat(g_fAutoMTMin, g_fAutoMTMax), Mob_Timer);
}

public Action Panic_Timer(Handle timer)
{
	g_bIsPanicEvent = false;
	g_hPanicTimer = null;
}
//==========================================================================================
//										Logic
//==========================================================================================
void SpawnZombie(int client, int zombieclass)
{
	float vPos[3];
	g_bPluginSpawnRequest = true;
	// This is the magic of the plugin: Spawn a zombie without disturbing ghost or dead infected players
	if (zombieclass == 0)
	{
		// Instead of using a random player, use the player with highest flow
		L4D_GetRandomPZSpawnPosition(L4D_GetHighestFlowSurvivor(), g_iZClassAm + 2, 5, vPos);	// I use 0 for tank but here is 8
		L4D2_SpawnTank(vPos, NULL_VECTOR);
		return;
	}
	if (zombieclass == g_iZClassAm + 1)
	{

		L4D_GetRandomPZSpawnPosition(L4D_GetHighestFlowSurvivor(), g_iZClassAm + 1, 5, vPos);
		L4D2_SpawnWitch(vPos, NULL_VECTOR);
		return;
	}
// First we get a suitable spot for the infected. We use a random alive survivor and we try to get the best spot for the special we want.
// This should try to spawn the infected at the best available spot to attack survivors.
	L4D_GetRandomPZSpawnPosition(client, zombieclass, 5, vPos);
// Spawn the infected with the vector we got previously. This native does not trigger players and will only spawn infected bots.
	
	L4D2_SpawnSpecial(zombieclass, vPos, NULL_VECTOR);
}

// Set the map progress which will unlock the next tank. If no more tanks will spawn, returns negative value
float NextTankInProgress()
{
	if (g_iTanksForRound == 0 || g_iTanksSpawned >= g_iTanksForRound)
		return -1.0;
	return g_fArTankFlow[g_iTanksSpawned];
}

float NextWitchInProgress()
{
	if (g_iWitchesForRound == 0 || g_iWitchesSPawned >= g_iWitchesForRound)
		return -1.0;
	return g_fArWitchFlow[g_iWitchesSPawned];
}

// This function is called to get next spawn time
float NextSpawnTime(const bool startloop)
{
	float fTime, fMinTime, fMaxTime;
	int iMaxSpecials;

// Modify max specials and spawn times in survival based over time	
	if (g_iGameMode == 3 && GetGameTime() < (g_fSurvStart + g_fSurvTime))
	{
		fMinTime = LinealInterpolation(0.0, g_fSurvTime, g_fSurvStTimeMin, g_fAutoSTMin, (GetGameTime() - g_fSurvStart));
		fMaxTime = LinealInterpolation(0.0, g_fSurvTime, g_fSurvStTimeMax, g_fAutoSTMax, (GetGameTime() - g_fSurvStart));
		iMaxSpecials = RoundToNearest(LinealInterpolation(0.0, g_fSurvTime, float(g_iSurvStLimit), float(g_iSpecialLimit), (GetGameTime() - g_fSurvStart)));
	}
	else
	{
		fMinTime = g_fAutoSTMin;
		fMaxTime = g_fAutoSTMax;
		iMaxSpecials = g_iSpecialLimit;
	}
	if (g_iAutoSTMod == 0)		// Random spawn times
	{
		fTime = GetRandomFloat(g_fAutoSTMin, g_fAutoSTMax);
		if (startloop)
		{
			fTime = fTime + g_fAutoSTDel;
		}
		return fTime;
	}
	if (g_iAutoSTMod == 1)	// Incremental time (more zombies = more time)
	{
		fTime = LinealInterpolation(0.0, float(iMaxSpecials), fMinTime, fMaxTime, float( AliveSpecials() ));
	}
	else	// Decremental time (more zombies = less time)
	{
		fTime = LinealInterpolation(float(iMaxSpecials), 0.0, fMinTime, fMaxTime, float( AliveSpecials() ));
	}
	return fTime;
	
}

float LinealInterpolation(const float x0, const float x1, const float y0, const float y1, const float x)
{
	float fSlope = (y1 - y0) / (x1 - x0);
	return (y0 + fSlope * (x - x0));
}

// Returns an available special class to spawn, if cannot spawn returns -1
void NextSpecialSpawn()	// v1.1: Optimized function to try to prevent server lags when spawning high amount of infected
{
	int iTotalAm, iArSpecialAm[6], iMaxSpecials, iArWeights[6];
	if (g_iGameMode == 3)
	{
		iMaxSpecials = RoundToNearest(LinealInterpolation(0.0, g_fSurvTime, float(g_iSurvStLimit), float(g_iSpecialLimit), (GetGameTime() - g_fSurvStart)));
	}
	else iMaxSpecials = g_iSpecialLimit;
	// Get a list of all alive zombies and for each class
	for (int i = 1; i < MaxClients; i++)	
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			if (g_bL4D2) // Ignore tanks
			{
				if (GetEntProp(i, Prop_Send, "m_zombieClass") == 8)	// ZombieClass for tank in L4D2
					continue;
			}
			else if (GetEntProp(i, Prop_Send, "m_zombieClass") == 5) // ZombieClass for tank in L4D
				continue;

			iTotalAm++;
			switch (GetEntProp(i, Prop_Send, "m_zombieClass"))
			{
				case 1: iArSpecialAm[0]++;
				case 2: iArSpecialAm[1]++;
				case 3: iArSpecialAm[2]++;
				case 4: iArSpecialAm[3]++;
				case 5: iArSpecialAm[4]++;
				case 6: iArSpecialAm[5]++;
			}
		}
	}
	if (iTotalAm >= iMaxSpecials) // For convenience, prevent starting loop if limit zombies have been reached
	{
		g_iArClassQueue[0] = -1;
		return;
	}
		
	for (int i = 0; i < g_iAutoSAmount; i++)
	{
		int iTotalWeight = 0;
		for (int j = 0; j < g_iZClassAm; j++)	// Fill an array which will store zombie weights for spawn chances
		{
			if (iArSpecialAm[j] >= g_iArLimits[j])	// If this class has reached its limit, skip this loop
			{
				iArWeights[j] = 0;
				continue;
			}
			else if (g_bWeightScale)	// DIvide class weight by alive class members +1
				iArWeights[j] = g_iArWeights[j] / (iArSpecialAm[j] + 1);
				
			else
				iArWeights[j] = g_iArWeights[j];
			
			iTotalWeight += iArWeights[j];	// Get also the total weight
		}
		if (iTotalWeight == 0) 	// If zombie classes are full (even if limit has not reached) stop this function
		{
			g_iArClassQueue[i] = -1;	// -1 is the signal to stop reading the array
			return;
		}
		
		// Get a random special infected based on the weights
		int iRoll = GetRandomInt(0, iTotalWeight);
		int iSum, iClass;
		for (iClass = 0; iClass < g_iZClassAm; iClass++)
		{
			if (iArWeights[iClass] + iSum > iRoll)
				break;
				
			iSum += iArWeights[iClass];
		}

		g_iArClassQueue[i] = iClass;	// Add the zombie class to the queue
		iArSpecialAm[iClass]++;			// Increase zombie class amount by 1
		iTotalAm++;						// Increase total zombies by 1
		if (iTotalAm >= iMaxSpecials && i < (MAX_ZOMBIES -1))	// Check again if we have reached the limit of specials to end loop 
		{
			g_iArClassQueue[i+1] = -1;							// Next class in the array will tell plugin to stop reading
			break;
		}
	}
}

// Check autospawn meets the conditions to spawn specials or mobs. 0 = Not allowed. 1 = allowed. -1 = Allowed but ignore first spawn delay
int IsAutoAllowed()
{
	if (g_bIsPanicEvent)
	{
		if (g_iAutoSPanic == 3)
			return -1;
		if (g_iAutoSPanic == 2)
		{
			if (g_bAutoSFlowBlock && g_iFlowToken == 50)
				return 0;
			
			return -1;
		}
		if (g_iAutoSPanic == 1)
		{
			if (g_bAutoSTankBlock && IsTankInPlay())
				return 0;
			
			return -1;
		}
	}
	else if ((g_bAutoSFlowBlock && g_iFlowToken == 50) || g_bAutoSTankBlock && IsTankInPlay())
		return 0;
		
	return 1;
}

int AliveSpecials()
{
	int iSpecials = 0;
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			if (GetEntProp(i, Prop_Send, "m_zombieClass") != 8)	//Ignore tanks
				iSpecials++;
		}
	}
	return iSpecials;
}

int GetValidZombie()	// If zombie cannot be spawned by director try to get another one
{
	int iRand = GetRandomInt(0, g_iZClassAm - 1);
	for (int i = 0; i < 6; i++)
	{
		if (g_iArAllowSI[iRand] < 0)
			return iRand + 1;	// Position in the array is 1 unit lower than the zombie class
		
		if (iRand == 5)
			iRand = 0;
			
		else
			iRand++;
	}
	return 0;
}

void SetupBosses()	// Decide where will spawn tanks and witches at the beggining of round
{
	if (g_iGameMode == 2 && g_bBossPlaced)	return; // Prevent to reset tanks and witches to make both teams in versus have the same conditions

	g_iTanksForRound = GetRandomInt(g_hTankMin.IntValue, g_hTankMax.IntValue);
	if (g_iTanksForRound > 0)
	{
		float fInterval = 100.0 / g_iTanksForRound;
		for (int i = 0; i < g_iTanksForRound; i++)
		{
			g_fArTankFlow[i] = fInterval * i + GetRandomFloat(0.0, fInterval);
		}
	}
	
	g_iWitchesForRound = GetRandomInt(g_hWitchMin.IntValue, g_hWitchMax.IntValue);
	if (g_iWitchesForRound > 0)
	{
		float fInterval = 100.0 / g_iWitchesForRound;
		for (int i = 0; i < g_iWitchesForRound; i++)
		{
			g_fArWitchFlow[i] = fInterval * i + GetRandomFloat(0.0, fInterval);
		}
	}
	g_bBossPlaced = true;
}

// Extracted from SpawnZombie() since v1.1 to improve performance
// Get a random survivor to spawn a zombie around him
int RandomAliveSurvivor()
{
	int iArPlayers[MAXPLAYERS+1], iAliveSurvivor;
	
	for (int i = 1; i < MaxClients; i++)	// Get all alive survivors
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			iArPlayers[iAliveSurvivor] = i;	//Store all survivor IDs here
			iAliveSurvivor++;
		}
	}
	if (iAliveSurvivor == 0)
		return 0;
	return iArPlayers[GetRandomInt(0, iAliveSurvivor)];
}

bool IsTankInPlay()
{
	if (g_bL4D2)	// Use Left 4 DHooks native
		return L4D2_IsTankInPlay();
		
	else	// Cannot use that native in L4D, so, lets use a loop to check if a player is a tank
	{
		for (int i = 1; i < MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 3 && GetEntProp(i, Prop_Send, "m_zombieClass") == 5)
				return true;
		}
	}
	return false;
}

int GetSpecialAm()
{
	int amount;
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
		amount++;
	}
	return amount;
}

int GetWitchAm()
{
	int amount;
	int i = -1;
	while ((i = FindEntityByClassname(i, "witch"))!= -1)
	{
		amount++;
	}
	PrintToServer("%i", amount);
	return amount;
}
/*============================================================================================
									Changelog
----------------------------------------------------------------------------------------------
* 1.0	(03-May-2021)
	- Initial release.
* 1.1	(05-May-2021)
	- Improved zombie spawn performance to decrease lag when spawning high amount of infected at once.
	- Prevent plugin errors when trying to use commands via server console.
	- Modified ConVar description and fixed some gramatical errors, ConVars are not affected, is not needed to update the cfg.
	- Fixed bug in sm_zspawn command which found witches or common infected as obstacles to spawn zombies.
	- "sm_zspawn" and "sm_zauto" now accept as an optional argument the amount of zombies to spawn (max 16), if not specified, the commands will spawn 1 zombie.
	- Admin commands now return messages via ReplyToCommand() instead of PrintToChat().
	- Addmin commmands return a message if a spawn was succeful.
* 1.2	(09-May-2021)
	- Added support for Left 4 Dead.
	- Plugin uses "info_gamemode" to check current gamemode (thanks to Silvers for the suggestion).
	- Fixed some spelling mistakes (again thanks to Silvers).
	- New ConVar "zspawn_gamemode_override" can force the plugin to emulate another gamemode, it can be used to solve bugs in mutations if the gamemode is not detected correctly.
	- [L4D2]Trying to add more than 6 values in special limits and weight convars will report and error instead of accepting the first 6 values.
	- Fixed leaks with ray trace handles.
	- Solved CloseHandle errors with timers.
	- Fixed the error getting invalid client (Client index 65 is invalid).
	- Solved bug in scavenge that stopped autospawn if "zspawn_autosp_stop_notmoving" was set to 1.
	- Plugin now can spawn tanks in scavenge when survivors reach specific scores (new ConVar "zspawn_autotank_scav_amount").
	- Admin spawn commands now report the amount of infected spawned, if no infected could be spawned it will report an error.
	- Autospawn of tanks and witches now uses the survivor closest to the end of map to get the spawn position.
	- If admins try to spawn more than 16 zombies the value will be clamped to 16.
	- Added tags in plugin messages.
==============================================================================================*/
