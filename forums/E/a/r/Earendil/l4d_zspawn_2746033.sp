/*============================================================================================
							L4D2 ZSpawn: Zombie Spawn manager
----------------------------------------------------------------------------------------------
*	Author	:	Eärendil
*	Descrp	:	Zombie Spawn manager with admin command, autospawn and director control
*	Version	:	1.1
*	Link	:	https://forums.alliedmods.net/showthread.php?t=332272
----------------------------------------------------------------------------------------------
*	Table of contents:
		- ConVars																		(77)
		- ConVar Logic																	(207)
		- Events & Left 4 DHooks														(472)
		- Admin Commands																(649)
		- RayTrace																		(763)
		- Timers																		(819)
		- Logic																			(932)
==============================================================================================*/
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "1.1"
#define AR_SWEIGHTS "1000,1000,1000,1000,1000,1000"
#define AR_SLIMITS	"1,1,1,1,1,1"
#define	MAX_ZOMBIES	28		// This is the limit of special infected that the engine can spawn

bool	g_bAllow, g_bPluginOn, g_bAllowTank, g_bAllowWitch, g_bAllowMob, g_bGameStarted, g_bIsPanicEvent, g_bPluginSpawnRequest, g_bAutoSEnable, g_bAutoSFlowBlock, g_bAutoSTankBlock,
		g_bAutoSpawnBlocked, g_bAutoMEnable, g_bIsFinale, g_bBossPlaced, g_bWeightScale;

int		g_iFlowToken, g_iNextMobSize, g_iMobAmountMin, g_iMobAmountMax, g_iVomitAmountMin, g_iVomitAmountMax, g_iTanksForRound,
		g_iTanksSpawned, g_iWitchesForRound, g_iWitchesSPawned, g_iAutoSTMod, g_iAutoSPanic, g_iArWeights[6], g_iArLimits[6], g_iSpecialLimit,
		g_iAutoSAmount, g_iArAllowSI[6], g_iGameMode, g_iSurvStLimit, g_iArClassQueue[MAX_ZOMBIES];
		
ConVar	g_hAllow, g_hGameModes, g_hCurrGameMode, g_hAllowSI, g_hAllowTank, g_hAllowWitch, g_hAllowMob, g_hMobAmountMin, g_hMobAmountMax, g_hVomitAmountMin, g_hVomitAmountMax, 
		g_hTankMax, g_hTankMin, g_hWitchMax, g_hWitchMin, g_hAutoSEnable, g_hAutoSWeight, g_hAutoSTMin, g_hAutoSTMax, g_hAutoSTMod, g_hAutoSTDel, g_hAutoSFlowBlock, 
		g_hAutoSTankBlock, g_hAutoSPanic, g_hAutoSLimits, g_hSpecialLimit, g_hAutoMEnable, g_hAutoMTMin, g_hAutoMTMax, g_hAutoSAmount, g_hSurvStLimit,
		g_hSurvStTimeMin, g_hSurvStTimeMax, g_hSurvTime, g_hWeightScale;
		
float	g_fMapFlow, g_fLastValidTFlow, g_fMaxMapProgress, g_fNextProgressTank, g_fNextProgressWitch, g_fAutoSTMin, g_fAutoSTMax, g_fAutoSTDel, g_fAutoMTMin,
		g_fAutoMTMax, g_fSurvStTimeMin, g_fSurvStTimeMax, g_fSurvTime, g_fSurvStart, g_fArTankFlow[64], g_fArWitchFlow[64];

Handle	g_hFlowTimer, g_hSpawnTimer, g_hMobTimer;

char	g_sAutoSWeight[64], g_sAutoSLimits[64], g_sAllowSI[64], g_sArWeights[6][16], g_sArLimits[6][16], g_sArAllowSI[8][16], g_sGameMode[64];
//Store the zombie name for calling zspawn and zauto
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

public Plugin myinfo =
{
	name = "[L4D2] ZSpawn: Zombie Spawn manager.",
	author = "Eärendil",
	description = "Controls zombie spawn, gives admin spawn commads and autospawn zombies.",
	version = PLUGIN_VERSION,
	url = "",
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if( GetEngineVersion() == Engine_Left4Dead2 )
		return APLRes_Success;
	
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");	// I will try to add L4D support for a next update
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
	g_hAllowSI			= CreateConVar("zspawn_dir_allow_special",	AR_SLIMITS,		"Allow which special infected can be spawned by Director.\n0 = Special denied, 1 = Special allowed.\nMust place 6 values, separated by commas, no spaces.\n <smoker>,<boomer>,<hunter>,<spitter>,<jockey>,<charger>", FCVAR_NOTIFY);
	g_hAllowTank		= CreateConVar("zspawn_dir_allow_tank",			"1",		"Director can spawn tanks (0 = deny, 1 = allow).\nDirector is allowed to spawn tanks on finales to prevent game errors.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hAllowWitch		= CreateConVar("zspawn_dir_allow_witch",		"1",		"Director can spawn witches (0 = deny, 1 = allow).", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hAllowMob			= CreateConVar("zspawn_dir_allow_mob",			"1", 		"Director can spawn mobs. Does not affect vomit mobs (0 = deny, 1 = allow).\nDirector is allowed to spawn mobs on finales to prevent game errors.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	// Random mobs and vomit mobs spawn sizes
	g_hMobAmountMin		= CreateConVar("zspawn_mob_min",			"20",		"Minimum amount zombies to spawn when a mob starts.\nAffects mobs generated by Director or by Plugin.", FCVAR_NOTIFY, true, 0.0);
	g_hMobAmountMax		= CreateConVar("zspawn_mob_max",			"45",		"Maximum amount of zombies to spawn when a mob starts.\nAffects mobs generated by Director or by Plugin.", FCVAR_NOTIFY, true, 0.0);
	g_hVomitAmountMin	= CreateConVar("zspawn_vomitmob_min",		"20",		"Minimum amount zombies to spawn when someone is on vomit.", FCVAR_NOTIFY, true, 0.0);
	g_hVomitAmountMax	= CreateConVar("zspawn_vomitmob_max",		"45",		"Maximum amount of zombies to spawn when someone is on vomit.", FCVAR_NOTIFY, true, 0.0);
	// Autospawn Special ConVars
	g_hAutoSEnable		= CreateConVar("zspawn_autosp_enable",			"1",		"Allow Plugin to automatically spawn special infected (0 = deny, 1 = allow).", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hAutoSWeight		= CreateConVar("zspawn_autosp_weights",		AR_SWEIGHTS,	"Autospawn zombie weights, it determines the chance that each special infected is spawned respect to the others.\nChance of special spawn = Weight/sum of all Weights.\nMust place 6 values, separated by comma, no spaces.\n<smoker>,<boomer>,<hunter>,<spitter>,<jockey>,<charger>", FCVAR_NOTIFY);
	g_hAutoSTMin		= CreateConVar("zspawn_autosp_time_min",		"10.0",		"Minimum amount of time in seconds between auto special spawn.", FCVAR_NOTIFY, true, 0.1);
	g_hAutoSTMax		= CreateConVar("zspawn_autosp_time_max",		"25.0",		"Maximum amount of time in seconds between auto special spawn.", FCVAR_NOTIFY, true, 1.0);
	g_hAutoSTMod		= CreateConVar("zspawn_autosp_time_mode",		"1",		"Spawn time mode: 0= random, 1 = incremental, 2 = decremental.\nIncremental: When more specials are alive time will approach to its maximum value.\nDecremental: is the oposite as incremental.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	g_hAutoSTDel		= CreateConVar("zspawn_autosp_time_delay",		"10.0",		"When autospawn begins or resumes, add extra time to the first spawn.", FCVAR_NOTIFY, true, 0.0);
	g_hAutoSFlowBlock	= CreateConVar("zspawn_autosp_stop_notmoving",	"1",		"If Survivors stop moving for a while, autospawn will stop.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hAutoSTankBlock	= CreateConVar("zspawn_autosp_stop_tank",		"1",		"Stop autospawn if a tank is in game.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hAutoSPanic		= CreateConVar("zspawn_autosp_panic",			"1",		"Allow panic events to invalidate autospawn stops.\n0 = Dont resume autospawn on panic events.\n1 = Panic will invalidate autospawn stop with players not moving.\n2 = Panic will invalidate autospawn block with tank in game.\n3 = Panic will invalidate all autospawn blocks.", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	g_hAutoSLimits		= CreateConVar("zspawn_autosp_limit_class",	AR_SLIMITS,		"Limit of each special infected class alive, put the limits separated with commas, no spaces. \n <smoker>,<boomer>,<hunter>,<spitter>,<jockey>,<charger>", FCVAR_NOTIFY);
	g_hSpecialLimit		= CreateConVar("zspawn_autosp_limit",			"6",		"Max amount of special infected alive, tanks and witches not included in this count.", FCVAR_NOTIFY, true, 0.0, true, float(MAX_ZOMBIES));
	g_hAutoSAmount		= CreateConVar("zspawn_autosp_amount",			"1",		"Amount of special infected that will be autospawned at once.", FCVAR_NOTIFY, true, 1.0, true, float(MAX_ZOMBIES));
	g_hWeightScale		= CreateConVar("zspawn_autosp_weight_scale",	"1",		"Special weight will decrease based on the amount of zombies of its class alive.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	// This emulates survival and allows server admin to easily configure the limit of specials and the spawn times over time
	g_hSurvTime			= CreateConVar("zspawn_survival_time",				"600.0", 	"Amount of time in seconds to reach default spawn times and zombie limits. \nSet to 0 if you dont want spawn times and limits vary over survival game.", FCVAR_NOTIFY, true, 0.0);
	g_hSurvStLimit		= CreateConVar("zspawn_survival_start_limit",		"5",		"Limit of special infected when survival starts. \nZombie limit will transition to 'zspawn_autosp_limit' over the time defined in'zspawn_survival_time'.", FCVAR_NOTIFY, true, 0.0);
	g_hSurvStTimeMin	= CreateConVar("zspawn_survival_time_min",			"20",		"Minium time between special autospawns when survival starts. \nTime will transition to 'zspawn_autosp_time_min' over the time defined in'zspawn_survival_time'.", FCVAR_NOTIFY, true, 0.1);
	g_hSurvStTimeMax	= CreateConVar("zspawn_survival_time_max",			"45",		"Maximum time between special autospawns when survival starts. \nTime will transition to 'zspawn_autosp_time_man' over the time defined in'zspawn_survival_time'.", FCVAR_NOTIFY, true, 1.0);
	//Autospawn bosses. I added a limit of 64 because each boss must be saved in an array to repeat the amount and location of bosses in versus rounds
	g_hTankMin			= CreateConVar("zspawn_autotank_min",			"1",		"Minimum amount of tanks that will be autospawned on each map.", FCVAR_NOTIFY, true, 0.0, true, 64.0);
	g_hTankMax			= CreateConVar("zspawn_autotank_max",			"2",		"Maximum amount of tanks that will be autospawned on each map.", FCVAR_NOTIFY, true, 0.0, true, 64.0);
	g_hWitchMin			= CreateConVar("zspawn_autowitch_min",			"1",		"Minimum amount of witches that will be autospawned on each map.", FCVAR_NOTIFY, true, 0.0, true, 64.0);
	g_hWitchMax			= CreateConVar("zspawn_autowitch_max",			"3",		"Maximum amount of witches that will be autospawned on each map.", FCVAR_NOTIFY, true, 0.0, true, 64.0);
	// Autospawn mob
	g_hAutoMEnable		= CreateConVar("zspawn_automob_enable",			"1",		"Allow Plugin to automatically call mobs over time (0 = deny, 1 = allow).", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hAutoMTMin		= CreateConVar("zspawn_automob_time_min",		"90",		"Minimum amount of time in seconds between auto mob spawns.", FCVAR_NOTIFY, true, 0.1);
	g_hAutoMTMax		= CreateConVar("zspawn_automob_time_max",		"240",		"Maximum amount of time in seconds between auto mob spawns.", FCVAR_NOTIFY, true, 1.0);
	
	RegAdminCmd("sm_zspawn",	ZSpawnView,		ADMFLAG_KICK,	"Spawn an infected at your cursor position. Usage: sm_zspawn <zombietype> <amount>.\nValid zombietypes: hunter, smoker, boomer, charger, jockey, spitter, tank, witch.\nAmount: 1-16 zombies, if amount is not assigned will spawn 1 zombie.");
	RegAdminCmd("sm_zauto",		ZSpawnAuto,		ADMFLAG_KICK,	"Spawn an infected in an automatic position. Usage: sm_zauto <zombietype> <amount>.\nValid zombietypes: hunter, smoker, boomer, charger, jockey, spitter, tank, witch.\nAmount: 1-16 zombies, if amount is not assigned will spawn 1 zombie.");
	RegAdminCmd("sm_zmob",		ZSpawnMob,		ADMFLAG_KICK,	"Creates a mob wich will attack survivors. Usage sm_zmob <amount>.");
	
	g_hCurrGameMode		= FindConVar("mp_gamemode");
	
	g_bPluginOn = false;
	AutoExecConfig (true, "l4d2_zspawn");
	
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
}
// Enables/disables timers when CVar is changed if game has started
void CVarTimers()
{
	if (g_bAutoSEnable != g_hAutoSEnable.BoolValue)
	{
		g_bAutoSEnable = g_hAutoSEnable.BoolValue;
		if (g_bAutoSEnable && g_bGameStarted)
		{
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
			g_hMobTimer = CreateTimer(GetRandomFloat(g_fAutoMTMin, g_fAutoMTMax), Mob_Timer);
			
		if (!g_bAutoMEnable && g_bGameStarted)
			delete g_hMobTimer;
	}
}

void GetWeights()
{
	g_hAutoSWeight.GetString(g_sAutoSWeight, sizeof(g_sAutoSWeight));

	if (ExplodeString(g_sAutoSWeight, ",", g_sArWeights, sizeof(g_sArWeights), sizeof(g_sArWeights[])) == 6)
	{
		for (int i = 0; i < sizeof(g_sArWeights); i++)
			g_iArWeights[i] = StringToInt(g_sArWeights[i]);
	}
	else 
	{
		ResetConVar(g_hAutoSWeight);
		PrintToServer("WARNING: Cannot get 'zspawn_auto_weights', check cvar has been set properly.");
		for (int i = 0; i < sizeof(g_iArWeights); i++)
			g_iArWeights[i] = 100;
	}
}

void GetAutoSpecialLimit()
{
	g_hAutoSLimits.GetString(g_sAutoSLimits, sizeof(g_sAutoSLimits));
	if (ExplodeString(g_sAutoSLimits, ",", g_sArLimits, sizeof(g_sArLimits), sizeof(g_sArLimits[])) == 6)
	{
		for (int i = 0; i < sizeof(g_sArLimits); i++)
			g_iArLimits[i] = StringToInt(g_sArLimits[i]);
	}
	else 
	{
		ResetConVar(g_hAutoSLimits);
		PrintToServer("WARNING: Cannot get 'zspawn_class_limit', check cvar has been set properly.");
		for (int i = 0; i < sizeof(g_iArLimits); i++)
			g_iArLimits[i] = 1;
	}
}

void GetDirectorSpecialAllow()
{
	g_hAllowSI.GetString(g_sAllowSI, sizeof(g_sAllowSI));
	if (ExplodeString(g_sAllowSI, ",", g_sArAllowSI, sizeof(g_sArAllowSI), sizeof(g_sArAllowSI[])) == 6)
	{
		for (int i = 0; i < sizeof(g_iArAllowSI); i++)
			g_iArAllowSI[i] = StringToInt(g_sArAllowSI[i]);
	}
	else 
	{
		ResetConVar(g_hAllowSI);
		PrintToServer("WARNING: Cannot get 'zspawn_director_special_allow', check cvar has been set properly.");
		for (int i = 0; i < sizeof(g_iArAllowSI); i++)
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
		PrintToServer("WARNING: 'zspawn_auto_time_max' cannot be lower than 'zspawn_auto_time_min', clamping.");
		g_fAutoSTMax = g_fAutoSTMin;
	}
	else g_fAutoSTMax = g_hAutoSTMax.FloatValue;

	if (g_iMobAmountMin > g_hMobAmountMax.IntValue)
	{
		PrintToServer("WARNING: 'zspawn_mob_max' cannot be lower than 'zspawn_mob_min', clamping.");
		g_iMobAmountMax = g_iMobAmountMin;
	}
	else g_iMobAmountMax = g_hMobAmountMax.IntValue;
		
	if (g_fAutoMTMin > g_hAutoMTMax.FloatValue)
	{
		PrintToServer("WARNING: 'zspawn_automob_time_max' cannot be lower than 'zspawn_automob_time_min, clamping.");
		g_fAutoMTMax = g_fAutoMTMin; 
	}
	else g_fAutoMTMax = g_hAutoMTMax.FloatValue;
	
	if (g_fSurvStTimeMin > g_hSurvStTimeMax.FloatValue)
	{
		PrintToServer("WARNING: 'zspawn_survival_time_max' cannot be lower than 'zspawn_survival_time_max', clamping.");
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
		HookEvent("panic_event_finished", 	Event_Panic_End);
		HookEvent("finale_start",			Event_Finale_Start);
		HookEvent("round_end",				Event_Round_End);
	}
	if (g_bPluginOn == true && (g_bAllow == false || g_iGameMode == 0))
	{
		g_bPluginOn = false;
		ResetMaxSpecials();
		UnblockSpecials();
		UnhookEvent("create_panic_event", 	Event_Panic_Start);
		UnhookEvent("panic_event_finished", Event_Panic_End);
		UnhookEvent("finale_start",			Event_Finale_Start);
		UnhookEvent("round_end",			Event_Round_End);
	}
}

void GetGameMode()	//Returns 0 if gamemode is not allowed, 1-3 if gamemode is allowed
{
	if (g_hCurrGameMode == null)
	{
		g_iGameMode = 0;
		return;
	}

	char sGameModes[64];
	g_hCurrGameMode.GetString(g_sGameMode, sizeof(g_sGameMode));	// Store "mp_gamemode" result in g_sGameMode
	g_hGameModes.GetString(sGameModes, sizeof(sGameModes));		// Store all gamemodes wich will start plugin in sGameModes
	
	if (sGameModes[0])	// If string is not empty that means that server admin only wants plugin in some gamemodes
	{
		if (StrContains(sGameModes, g_sGameMode, false) == -1)	// Check if the current gamemode is not in the list of allowed gamemodes
		{
			g_iGameMode = 0;
			return;
		}
	}
	//Make plugin universal for all official games and mutations: https://forums.alliedmods.net/showthread.php?p=893938
	if (StrEqual(g_sGameMode, "coop", false) || StrEqual(g_sGameMode, "realism", false) || StrEqual(g_sGameMode, "mutation3", false) || StrEqual(g_sGameMode, "mutation9", false) || StrEqual(g_sGameMode, "mutation1", false) || StrEqual(g_sGameMode, "mutation7", false) || StrEqual(g_sGameMode, "mutation10", false) || StrEqual(g_sGameMode, "mutation2", false) || StrEqual(g_sGameMode, "mutation4", false) || StrEqual(g_sGameMode, "mutation5", false) || StrEqual(g_sGameMode, "mutation14", false))
	{
		g_iGameMode = 1;
		return;
	}
	if (StrEqual(g_sGameMode, "versus", false) || StrEqual(g_sGameMode, "teamversus", false) || StrEqual(g_sGameMode, "scavenge", false) || StrEqual(g_sGameMode, "teamscavenge", false) || StrEqual(g_sGameMode, "mutation12", false) || StrEqual(g_sGameMode, "mutation13", false) || StrEqual(g_sGameMode, "mutation15", false) || StrEqual(g_sGameMode, "mutation11", false))
	{
		g_iGameMode = 2;
		return;
	}
	if (StrEqual(g_sGameMode, "survival", false))
	{
		g_iGameMode = 3;
		return;
	}
	g_iGameMode = 0;
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
	SetConVarInt(FindConVar("survival_max_specials"), MAX_ZOMBIES);
}

void ResetMaxSpecials()
{
	ResetConVar(FindConVar("z_max_player_zombies"));
	ResetConVar(FindConVar("z_minion_limit"));	
	ResetConVar(FindConVar("survival_max_specials"));
}

/* When autospawn is enabled plugin will block SI with ConVars, using "L4D_OnSpawnSpecial" to block everything but autospawn would block other plugin spawns,
 * making it incompatible with other plugins*/
void BlockSpecials()	
{
	SetConVarInt(FindConVar("z_smoker_limit"), 0);
	SetConVarInt(FindConVar("survival_max_smokers"), 0);
	SetConVarInt(FindConVar("z_boomer_limit"), 0);
	SetConVarInt(FindConVar("survival_max_boomers"), 0);
	SetConVarInt(FindConVar("z_hunter_limit"), 0);
	SetConVarInt(FindConVar("survival_max_hunters"), 0);
	SetConVarInt(FindConVar("z_spitter_limit"), 0);
	SetConVarInt(FindConVar("survival_max_spitters"), 0);
	SetConVarInt(FindConVar("z_jockey_limit"), 0);
	SetConVarInt(FindConVar("survival_max_jockeys"), 0);
	SetConVarInt(FindConVar("z_charger_limit"), 0);
	SetConVarInt(FindConVar("survival_max_chargers"), 0);
}

void UnblockSpecials()
{
	ResetConVar(FindConVar("z_smoker_limit"));
	ResetConVar(FindConVar("survival_max_smokers"));
	ResetConVar(FindConVar("z_boomer_limit"));
	ResetConVar(FindConVar("survival_max_boomers"));
	ResetConVar(FindConVar("z_hunter_limit"));
	ResetConVar(FindConVar("survival_max_hunters"));
	ResetConVar(FindConVar("z_spitter_limit"));
	ResetConVar(FindConVar("survival_max_spitters"));
	ResetConVar(FindConVar("z_jockey_limit"));
	ResetConVar(FindConVar("survival_max_jockeys"));
	ResetConVar(FindConVar("z_charger_limit"));
	ResetConVar(FindConVar("survival_max_chargers"));
}
//==========================================================================================
//								Events & Left 4 DHooks
//==========================================================================================
public void OnMapStart()
{
	g_bBossPlaced = false;	
}

public void OnMapEnd()
{
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

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{

	if (g_iGameMode == 3)	//Block this event on survival or plugin will instantly start to spawn SI at the setup stage
		return;

	if (g_bAutoSEnable) 
		SetMaxSpecials();

	SetupBosses();

	g_fMaxMapProgress = 0.0;
	g_iTanksSpawned = 0;
	g_iWitchesSPawned = 0;
	g_fNextProgressTank = NextTankInProgress();
	g_fNextProgressWitch = NextWitchInProgress();
	
	g_hFlowTimer = CreateTimer(1.0, GetFlow_Timer, _, TIMER_REPEAT);
	if (g_bAutoSEnable)
	{
		g_hSpawnTimer = CreateTimer(NextSpawnTime(true), AutoSpawn_Timer);
		BlockSpecials();
	}	
	if (g_bAutoMEnable)
		g_hMobTimer = CreateTimer(GetRandomFloat(g_fAutoMTMin, g_fAutoMTMax), Mob_Timer);
		
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
		ReplyToCommand(client, "This command can be only used in game.");
		return Plugin_Handled;
	}
	if (args < 1 || args > 2)
	{
		ReplyToCommand(client, "Invalid number of arguments, use sm_zspawn <zombietype> <amount>.");
		return Plugin_Handled;
	}
	float vPos[3], vAng[3];
	if(!SetSpawnPos(client, vPos, vAng))
	{
		ReplyToCommand(client, "Cannot Spawn infected, please try another location.");
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
	if (iAmt < 1 || iAmt > 16)
		iAmt = 1;
		
	int iClass = -1;
	for (int i = 0; i < sizeof(g_sZombieClasses_L4D2); i++)
	{
		if (StrEqual(g_sZombieClasses_L4D2[i], sArgs, false))
		{
			iClass = i;
			break;
		}
	}
	if (iClass < 0)
	{
		ReplyToCommand(client, "Invalid zombie class, valid classes: hunter, boomer, smoker, charger, jockey, spitter, tank & witch.");
		return Plugin_Handled;
	}
	else if (iClass == 0)
	{
		for (int i = 0; i < iAmt; i++)
		{
			g_bPluginSpawnRequest = true;
			L4D2_SpawnTank(vPos, NULL_VECTOR);
		}
	}
	else if (iClass < 7)
	{
		for (int i = 0; i < iAmt; i++)
		{
			g_bPluginSpawnRequest = true;
			L4D2_SpawnSpecial(iClass, vPos, NULL_VECTOR);
		}
	}
	else
	{
		for (int i = 0; i < iAmt; i++)
		{
			g_bPluginSpawnRequest = true;
			L4D2_SpawnWitch(vPos, NULL_VECTOR);
		}
	}
	ReplyToCommand(client, "Zombie spawned succefully.");
	return Plugin_Handled;
}

public Action ZSpawnAuto(int client, int args)
{
	if (!g_bPluginOn)
		return Plugin_Handled;
		
	if (!client)
	{
		ReplyToCommand(client, "This command can be only used in game.");
		return Plugin_Handled;
	}
	if (args < 1 || args > 2)
	{
		ReplyToCommand(client, "Invalid number of arguments, use sm_zspawn <zombietype> <amount>.");
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
	if (iAmt < 1 || iAmt > 16)
		iAmt = 1;
		
	int iClass = -1;
	for (int i = 0; i < 8; i++)
	{
		if (StrEqual(g_sZombieClasses_L4D2[i], sArgs, false))
		{
			iClass = i;
			break;
		}
	}
	
	if (iClass < 0)
		ReplyToCommand(client, "Invalid zombie class, valid classes: hunter, boomer, smoker, charger, jockey, spitter, tank & witch.");

	else
	{
		for (int i = 0; i < iAmt; i++)
		{
			g_bPluginSpawnRequest = true;
			SpawnZombie(client, iClass);
		}
	}
	ReplyToCommand(client, "Zombie spawned succefully.");
	return Plugin_Handled;
}

public Action ZSpawnMob (int client, int args)
{
	if (!g_bPluginOn)
		return Plugin_Handled;

	if (!client)
	{
		ReplyToCommand(client, "This command can be only used in game.");
		return Plugin_Handled;
	}
	if (args != 1)
	{
		ReplyToCommand(client, "Invalid number of arguments, use sm_zmob <amount>.");
		return Plugin_Handled;
	}
	
	g_bPluginSpawnRequest = true;
	
	char sArgs[16];
	GetCmdArg(1, sArgs, sizeof(sArgs));
	g_iNextMobSize = StringToInt(sArgs);
	// Using a cheat command to call a mob
	int iFlags = GetCommandFlags("z_spawn_old");
	SetCommandFlags("z_spawn_old", iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "z_spawn_old %s", "mob");
	SetCommandFlags("z_spawn_old", iFlags);
	
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
			return false;

	}
	return true;
}

bool HasNoObstacles(const float vPos[3])
{
	float vAng[3], vEnd[3];
	Handle trace2;
	
	vAng[0] = 180.0;	// Fire a raytrace straight up to check if there is a roof that blocks zombie spawn
	trace2 = TR_TraceRayFilterEx(vPos, vAng, MASK_NPCSOLID_BRUSHONLY, RayType_Infinite, _TraceFilter);
	if (TR_DidHit(trace2))
	{
		TR_GetEndPosition(vEnd, trace2);
		if (GetVectorDistance(vEnd, vPos, true) < 5184.0)
			return false;
		
	}
	vAng[0]= 0.0;
	
	for (int i = 0; i < 8; i++)	// Fire 8 traces to check if there is a wall or an obstacle near the spawn wich could block zombie
	{
		vAng[1] = 45.0 * i;
		trace2 = TR_TraceRayFilterEx(vPos, vAng, MASK_NPCSOLID_BRUSHONLY, RayType_Infinite, _TraceFilter);
		if (TR_DidHit(trace2))	// Fixed raytrace
		{
			TR_GetEndPosition(vEnd, trace2);
			if (GetVectorDistance(vEnd, vPos, true) < 256.0)
			return false;
		}
	}
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
	float fPlayerFlow, fTeamFlow, fFlowDelta, fHighestFlow, fMapProgress;
	int iAliveSurv = 0;
	
// Trying to get map max flow at the beggining of round is usually inacurate, it gets more and more accurate when survivors are closer to saferoom.
	g_fMapFlow = L4D2Direct_GetMapMaxFlowDistance();
	
// Get the count of alive survivors and the sum of all player flow to get the average team flow
	for (int i = 0; i < MaxClients; i++)	
	{
		if (IsValidClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
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

public Action Mob_Timer (Handle timer)
{
	if(IsAutoAllowed() == 0)
	{
		g_hMobTimer = CreateTimer(1.0, Mob_Timer);
		return;
	}
	int iClient;
	for (iClient = 0; iClient < MAXPLAYERS; iClient++)
	{
		if (IsValidClient(iClient))
			break;
	}
	int iFlags = GetCommandFlags("z_spawn_old");
	SetCommandFlags("z_spawn_old", iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(iClient, "z_spawn_old %s", "mob");
	SetCommandFlags("z_spawn_old", iFlags);
	g_hMobTimer = CreateTimer(GetRandomFloat(g_fAutoMTMin, g_fAutoMTMax), Mob_Timer);
}
//==========================================================================================
//										Logic
//==========================================================================================
bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;
	if (!IsClientConnected(client))
		return false;
	return IsClientInGame(client);
}

void SpawnZombie(int client, int zombieclass)
{
	float vPos[3];

	g_bPluginSpawnRequest = true;
	// This is the magic of the plugin: Spawn a zombie without disturbing ghost or dead infected players
	if (zombieclass == 0)
	{
// First we get a suitable spot for the infected. We use a random alive survivor and we try to get the best spot for the special we want.
// This should try to spawn the infected at the best available spot to attack survivors.
		L4D_GetRandomPZSpawnPosition(client, zombieclass, 8, vPos);	// I use 0 for tank but here is 8
// Spawn the infected with the vector we got previously. This native does not trigger players and will only spawn infected bots.
		L4D2_SpawnTank(vPos, NULL_VECTOR);
		return;
	}
	if (zombieclass == 7)
	{
		L4D_GetRandomPZSpawnPosition(client, zombieclass, 5, vPos);
		L4D2_SpawnWitch(vPos, NULL_VECTOR);
		return;
	}
	L4D_GetRandomPZSpawnPosition(client, zombieclass, 5, vPos);	
	L4D2_SpawnSpecial(zombieclass, vPos, NULL_VECTOR);
}

// Set the map progress wich will unlock the next tank. If no more tanks will spawn, returns negative value
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
	for (int i = 0; i < MAXPLAYERS; i++)	
	{
		if (IsValidClient(i) && GetClientTeam(i) == 3)
		{
			if (GetEntProp(i, Prop_Send, "m_zombieClass") == 8) // Ignore tanks
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
		for (int j = 0; j < 6; j++)	// Fill an array which will store zombie weights for spawn chances
		{
			if (iArSpecialAm[j] >= g_iArLimits[j])	// If this class has reached its limit, skip this loop
			{
				PrintToServer("Zombie in array pos %i, is forbidden", j);
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
		for (iClass = 0; iClass < 6; iClass++)
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
			if (g_bAutoSTankBlock && L4D2_IsTankInPlay())
				return 0;
			
			return -1;
		}
	}
	else if ((g_bAutoSFlowBlock && g_iFlowToken == 50) || g_bAutoSTankBlock && L4D2_IsTankInPlay())
		return 0;
		
	return 1;
}

int AliveSpecials()
{
	int iSpecials = 0;
	for (int i = 0; i < MAXPLAYERS; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == 3)
		{
			if (GetEntProp(i, Prop_Send, "m_zombieClass") != 8)	//Ignore tanks
				iSpecials++;
		}
	}
	return iSpecials;
}

int GetValidZombie()	// If zombie cannot be spawned by director try to get another one
{
	int iRand = GetRandomInt(0,5);
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
int RandomAliveSurvivor()
{
	int iArPlayers[MAXPLAYERS+1], iAliveSurvivor;
	
	for (int i = 0; i < MAXPLAYERS; i++)	// Get all alive survivors
	{
		if (IsValidClient(i) && GetClientTeam(i) == 2 &&IsPlayerAlive(i))
		{
			iArPlayers[iAliveSurvivor] = i;	//Store all survivor IDs here
			iAliveSurvivor++;
		}
	}
	if (iAliveSurvivor == 0)
		return 0;
	return iArPlayers[GetRandomInt(0, iAliveSurvivor)];
}

/*============================================================================================
									Changelog
----------------------------------------------------------------------------------------------
* 1.0 
	- Initial release.
* 1.1
	- Improved zombie spawn performance to decrease lag when spawning high amount of infected at once.
	- Prevent plugin errors when trying to use commands via server console.
	- Modified ConVar description and fixed some gramatical errors, ConVars are not affected, is not needed to update the cfg.
	- Fixed bug in sm_zspawn command which found witches or common infected as obstacles to spawn zombies.
	- "sm_zspawn" and "sm_zauto" now accept as an optional argument the amount of zombies to spawn (max 16), if not specified, the commands will spawn 1 zombie.
	- Admin commands now return messages via ReplyToCommand() instead of PrintToChat().
	- Addmin commmands return a message if a spawn was succeful.
==============================================================================================*/
