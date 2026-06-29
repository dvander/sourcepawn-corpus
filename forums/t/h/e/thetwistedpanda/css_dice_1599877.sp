/*
	- New Effects
		- Mirror Damage
		- Vampirism
	- Configuration File (Not Hardcoded)
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <colors>

//=--=--=--=--=--=--=--=--=--=--=--=--=

#define PLUGIN_VERSION "3.0.9"

//=--=--=--=--=--=--=--=--=--=--=--=--=

enum PlayerData
{
	_iEffect = 0,
	_iPrim,
	_iSec,
	Float:_fPrim,
	Float:_fSec,
	Handle:_hPrim,
	Handle:_hSec
}
new g_PlayerData[MAXPLAYERS + 1][PlayerData];

enum AbuseData
{
	_iEffect = 0
}
new g_AbuseData[MAXPLAYERS + 1][AbuseData];

//=--=--=--=--=--=--=--=--=--=--=--=--=

//Effect Declarations
//{
	//Null Effect
	#define EFFECT_NONE 0

	//The maximum amount of effects the script has access to, plus 1.
	#define TOTAL_EFFECTS 41
	
	//Index for each effect as used by the script
	#define EFFECT_HEALTH_GAIN 1
	#define EFFECT_HEALTH_LOSE 2
	#define EFFECT_HEALTH_RAND 3
	#define EFFECT_GRAVITY_GAIN 4
	#define EFFECT_GRAVITY_LOSE 5
	#define EFFECT_GRAVITY_RAND 6
	#define EFFECT_SPEED_GAIN 7
	#define EFFECT_SPEED_LOSE 8
	#define EFFECT_SPEED_RAND 9
	#define EFFECT_COLOR 10
	#define EFFECT_ALPHA 11
	#define EFFECT_MODEL 12
	#define EFFECT_SNEAKY 13
	#define EFFECT_SLOW_POISON 14
	#define EFFECT_FAST_POISON 15
	#define EFFECT_SLOW_REGEN 16
	#define EFFECT_FAST_REGEN 17
	#define EFFECT_STRONG 18
	#define EFFECT_WEAK 19
	#define EFFECT_DEAL_RAND 20
	#define EFFECT_TANK 21
	#define EFFECT_SQUISHY 22
	#define EFFECT_TAKE_RAND 23
	#define EFFECT_SLAP_HURT 24
	#define EFFECT_SLAP_HEAL 25
	#define EFFECT_HIGH_JUMP 26
	#define EFFECT_LONG_JUMP 27
	#define EFFECT_SUPER_JUMP 28
	#define EFFECT_JUMP_FUCKER 29
	#define EFFECT_BEACON_TINY 30
	#define EFFECT_BEACON_LARGE 31
	#define EFFECT_BLIND_STATIC 32
	#define EFFECT_BLIND_RAND 33
	#define EFFECT_DRUG 34
	#define EFFECT_MONO 35
	#define EFFECT_STRIPPING 36
	#define EFFECT_VALIANT_SOUL 37
	#define EFFECT_NOBODY_LIKES_ME 38
	#define EFFECT_BOW_BEFORE_ME 39
	#define EFFECT_PACIFIST 40
	#define EFFECT_FULL_STRIPPING 41

	#define EFFECT_INVERTED 42
	//#define EFFECT_BURN_RAND 41
	//#define EFFECT_FREEZE_RAND 42
	//#define EFFECT_FREEZE_GRENADE 36
	//#define EFFECT_SMOKE_GRENADE 40
	//#define EFFECT_HOLY_GRENADE 41
	//#define EFFECT_SLIPPERY 47

	#define BURN_MIN 1.0
	#define BURN_MAX 1.0
	#define BURN_WAIT_MIN 1.0
	#define BURN_WAIT_MAX 1.0
	#define BURN_DAMAGE_CHANCE 0.20
	
	#define FREEZE_MIN 1.0
	#define FREEZE_MAX 1.0
	#define FREEZE_WAIT_MIN 1.0
	#define FREEZE_WAIT_MAX 1.0
	#define FREEZE_SLOW_CHANCE 0.20
	#define FREEZE_SLOW_MIN 1.0
	#define FREEZE_SLOW_MAX 1.0
	
	#define FREEZE_GRENADE_MIN 1.0
	#define FREEZE_GRENADE_MAX 1.0
	
	#define SMOKE_GRENADE_MIN 1.0
	#define SMOKE_GRENADE_MAX 1.0
	#define SMOKE_GRENADE_PUFF_CHANCE 10.0
	
	//Freeze Grenades - Individuals who see the flash are frozen for x seconds
	//Holy Hand Grenade ~ hegrenade that shoots big ass tesla beams
	//Smoke Grenade - Generates a cloud of smoke every x seconds
	//Slippery - Walk like you're ice skating
	//Burn - Randomly burn
	//Freeze - Randomly freeze
//}

//=--=--=--=--=--=--=--=--=--=--=--=--=

//Translation Declarations
//{
	//The number of translations available per effect
	new g_iTranslations[(TOTAL_EFFECTS + 1)] = { 1, ... };
//}

//=--=--=--=--=--=--=--=--=--=--=--=--=

//Miscellaneous
//{
	//Controls how many models the cvars css_dice_rtd_models_* can support.
	#define MODELS_MAX_ALLOWED 16
	//Controls the string size allowed for model cvars
	#define MODELS_MAX_STRING 256
//}

//=--=--=--=--=--=--=--=--=--=--=--=--=

//Health Effects
//{
	#define HEALTH_GAIN_COUNT 8
	#define HEALTH_GAIN_MIN 25
	#define HEALTH_GAIN_MAX 200
	new g_iEffectHealthGain[HEALTH_GAIN_COUNT] = { 25, 50, 75, 100, 125, 150, 175, 200 };

	#define HEALTH_LOSE_COUNT 11
	#define HEALTH_LOSE_MIN 5
	#define HEALTH_LOSE_MAX 95
	new g_iEffectHealthLose[HEALTH_LOSE_COUNT] = { 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 95 };

	#define HEALTH_RAND_MIN 0.10
	#define HEALTH_RAND_MAX 2.00
	
	//Conditional Effects
	#define COND_HEALTH_GAIN_MIN 1
	#define COND_HEALTH_GAIN_MAX 15
	#define COND_HEALTH_LOSE_MIN 1
	#define COND_HEALTH_LOSE_MAX 15
	
	//Poisoning
	#define POISON_SLOW_MIN 0.05
	#define POISON_SLOW_MAX 0.15
	#define POISON_SLOW_WAIT_MIN 25.0
	#define POISON_SLOW_WAIT_MAX 45.0
	
	#define POISON_FAST_MIN 0.01
	#define POISON_FAST_MAX 0.05
	#define POISON_FAST_WAIT_MIN 5.0
	#define POISON_FAST_WAIT_MAX 25.0

	//Reganing
	#define REGEN_SLOW_MIN 0.05
	#define REGEN_SLOW_MAX 0.15
	#define REGEN_SLOW_WAIT_MIN 25.0
	#define REGEN_SLOW_WAIT_MAX 50.0
	
	#define REGEN_FAST_MIN 0.01
	#define REGEN_FAST_MAX 0.05
	#define REGEN_FAST_WAIT_MIN 5.0
	#define REGEN_FAST_WAIT_MAX 25.0
	
	#define REGEN_HEALTH_MIN 150
	#define REGEN_HEALTH_MAX 450

//=--=--=--=--=--=--=--=--=--=--=--=--=

//Gravity Effect
//{
	#define GRAVITY_DEFAULT_VALUE 1.0

	#define GRAVITY_GAIN_COUNT 10
	#define GRAVITY_GAIN_MIN 0.05
	#define GRAVITY_GAIN_MAX 0.50
	new Float:g_fEffectGravityGain[GRAVITY_GAIN_COUNT] = { 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50 };

	#define GRAVITY_LOSE_COUNT 10
	#define GRAVITY_LOSE_MIN 0.05
	#define GRAVITY_LOSE_MAX 0.50
	new Float:g_fEffectGravityLose[GRAVITY_LOSE_COUNT] = { 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50 };

	#define GRAVITY_RAND_MIN 0.33
	#define GRAVITY_RAND_MAX 2.00
//}

//=--=--=--=--=--=--=--=--=--=--=--=--=

//Speed Effect
//{
	#define SPEED_DEFAULT_VALUE 1.0

	#define SPEED_GAIN_COUNT 10
	#define SPEED_GAIN_MIN 0.05
	#define SPEED_GAIN_MAX 0.50
	new Float:g_fEffectSpeedGain[SPEED_GAIN_COUNT] = { 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50 };

	#define SPEED_LOSE_COUNT 10
	#define SPEED_LOSE_MIN 0.05
	#define SPEED_LOSE_MAX 0.50
	new Float:g_fEffectSpeedLose[SPEED_LOSE_COUNT] = { 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50 };

	#define SPEED_RAND_MIN 0.33
	#define SPEED_RAND_MAX 2.00
//}

//=--=--=--=--=--=--=--=--=--=--=--=--=

//Model Effects
//{
	#define COLOR_CHANGE_MIN 1.0
	#define COLOR_CHANGE_MAX 30.0

	#define COLOR_COUNT 13
	new g_iEffectColor[COLOR_COUNT][4] =
	{
		{   0,   0,   0, 255},
		{   0,   0, 255, 255},
		{   0, 255,   0, 255},
		{ 255,   0,   0, 255},
		{ 255,   0, 255, 255},
		{   0, 255, 255, 255},
		{ 255, 255,   0, 255},
		{   0,   0, 128, 255},
		{   0, 128,   0, 255},
		{ 128,   0,   0, 255},
		{ 128,   0, 128, 255},
		{   0, 128, 128, 255},
		{ 128, 128,   0, 255}
	};

	#define ALPHA_COUNT 13
	new g_iEffectAlpha[ALPHA_COUNT][4] =
	{
		{ 255, 255, 255, 30},
		{ 255, 255, 255, 40},
		{ 255, 255, 255, 50},
		{ 255, 255, 255, 60},
		{ 255, 255, 255, 70},
		{ 255, 255, 255, 30},
		{ 255, 255, 255, 40},
		{ 255, 255, 255, 50},
		{ 255, 255, 255, 60},
		{ 255, 255, 255, 70},
		{ 255, 255, 255, 80},
		{ 255, 255, 255, 90},
		{ 255, 255, 255, 100}
	};
	
	#define MODEL_COUNT 24
	new const String:g_sEffectModel[MODEL_COUNT][2][128] =
	{
		{ "Classic Zombie", "models/zombie/classic.mdl" },
		{ "Poison Zombie", "models/zombie/poison.mdl" },
		{ "Fast Zombie", "models/zombie/fast.mdl" },
		{ "Zombie", "models/humans/charple01.mdl" },
		{ "Zombie", "models/humans/charple02.mdl" },
		{ "Zombie", "models/humans/charple03.mdl" },
		{ "Zombie", "models/humans/charple04.mdl" },
		{ "Corpse", "models/humans/corpse1.mdl" },
		{ "Antlion", "models/AntLion.mdl" },
		{ "Stalker", "models/stalker.mdl" },
		{ "Headcrab", "models/headcrabblack.mdl" },
		{ "Dog", "models/Dog.mdl" },
		{ "Vending Machine", "models/props/cs_office/vending_machine.mdl" },
		{ "Sofa", "models/props/cs_office/sofa.mdl" },
		{ "Dryer Box", "models/props/cs_assault/dryer_box.mdl" },
		{ "Office Chair", "models/props/cs_office/Chair_office.mdl" },
		{ "Comfy Chair", "models/props_combine/breenchair.mdl" },
		{ "File Cabinet", "models/props/cs_office/file_cabinet1.mdl" },
		{ "Barrel", "models/props/de_train/Barrel.mdl" },
		{ "Oil Drum", "models/props_c17/oildrum001.mdl" },
		{ "Explosive Barrel", "models/props_c17/oildrum001_explosive.mdl" },
		{ "Money Pallet", "models/props/cs_assault/moneypallete.mdl" },
		{ "Washer Box", "models/props/cs_assault/washer_box.mdl" },
		{ "HEV Suit", "models/items/hevsuit.mdl" }
	};
//}

//=--=--=--=--=--=--=--=--=--=--=--=--=

//Damaging Effects
//{
	//Weak
	#define WEAK_COUNT 13
	#define WEAK_MIN 0.20
	#define WEAK_MAX 0.80
	new Float:g_fEffectWeak[WEAK_COUNT] = { 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80 };

	//Strong
	#define STRONG_COUNT 10
	#define STRONG_MIN 1.20
	#define STRONG_MAX 3.00
	new Float:g_fEffectStrong[STRONG_COUNT] = { 1.20, 1.40, 1.60, 1.80, 2.00, 2.20, 2.40, 2.60, 2.80, 3.00 };

	//Tank
	#define TANK_COUNT 13
	#define TANK_MIN 0.20
	#define TANK_MAX 0.80
	new Float:g_fEffectTank[TANK_COUNT] = { 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80 };

	//Squishy
	#define SQUISHY_COUNT 10
	#define SQUISHY_MIN 1.20
	#define SQUISHY_MAX 3.00
	new Float:g_fEffectSquishy[SQUISHY_COUNT] = { 1.20, 1.40, 1.60, 1.80, 2.00, 2.20, 2.40, 2.60, 2.80, 3.00 };

	//Random
	#define DEAL_MIN 0.0
	#define DEAL_MAX 100.0

	#define TAKE_MIN 0.0
	#define TAKE_MAX 100.0
	
	//Slapping
	#define SLAP_HURT_MIN 0.01
	#define SLAP_HURT_MAX 0.05
	#define SLAP_HURT_WAIT_MIN 1.0
	#define SLAP_HURT_WAIT_MAX 30.0

	#define SLAP_HEAL_MIN 0.01
	#define SLAP_HEAL_MAX 0.05
	#define SLAP_HEAL_WAIT_MIN 1.0
	#define SLAP_HEAL_WAIT_MAX 30.0

	#define SLAP_MAX_HEALTH 300
//}

//=--=--=--=--=--=--=--=--=--=--=--=--=

//Jump Effects
//{
	#define JUMP_REFRESH_SOUND "UI/hint.wav"
	#define MAX_BHOP_VELOCITY 300.0

	#define LONG_JUMP_FACTOR_XY 1.66
	#define LONG_JUMP_FACTOR_Z 1.0
	new Float:g_fLongRefresh = 2.0;
	
	#define HIGH_JUMP_FACTOR_XY 1.0
	#define HIGH_JUMP_FACTOR_Z 1.66
	new Float:g_fHighRefresh = 0.0;
	
	#define SUPER_JUMP_FACTOR_XY 1.66
	#define SUPER_JUMP_FACTOR_Z 1.66
	new Float:g_fSuperRefresh = 3.5;
//}

//=--=--=--=--=--=--=--=--=--=--=--=--=

//Beacon Effects
//{
	#define BEACON_SOUND "buttons/blip1.wav"

	#define BEACON_TINY_MIN_SIZE 25.0
	#define BEACON_TINY_MAX_SIZE 325.0
	#define BEACON_TINY_AMOUNT 3
	#define BEACON_TINY_TIME 2.0
	
	#define BEACON_LARGE_MIN_SIZE 100.0
	#define BEACON_LARGE_MAX_SIZE 900.0
	#define BEACON_LARGE_AMOUNT 5
	#define BEACON_LARGE_TIME 2.0
//}

//=--=--=--=--=--=--=--=--=--=--=--=--=

//Random Burning
//{
	#define BURN_PROOF_CHANCE 2
	
	#define BURN_MIN_TIME 1.0
	#define BURN_MAX_TIME 15.0
	#define BURN_MIN_DAMAGE 0.15
	#define BURN_MAX_DAMAGE 1

	#define MIN_BURN_WAIT 1.0
	#define MAX_BURN_WAIT 20.0
	#define MIN_BURN_DAMAGE 0.33
	#define MAX_BURN_DAMAGE 1.75
//}

//=--=--=--=--=--=--=--=--=--=--=--=--=

//Screen Effects
//{
	//Mono
	#define MONO_COUNT 1
	new String:g_sEffectMono[MONO_COUNT][] =
	{
		"debug/yuv.vmt"
	};

	//Drug	
	#define DRUG_COUNT 3
	#define DRUG_MIN_TIME 1.0
	#define DRUG_MAX_TIME 15.0
	
	new Float:g_fEffectDrug[20] = { 0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0 };

	new String:g_sEffectDrug[DRUG_COUNT][] = 
	{
		"Effects/tp_eyefx/tpeye.vmt",
		"Effects/tp_eyefx/tpeye2.vmt",
		"Effects/tp_eyefx/tpeye3.vmt"
	};

	//Invert
	
	//Blind
	#define BLIND_COUNT 8
	new _iEffectBlindStatic[BLIND_COUNT] = { 160, 170, 180, 190, 200, 210, 220, 230 };
	
	#define BLIND_LOWEST 160
	#define BLIND_HIGEHST 230
	
	#define BLIND_MIN_TIME 1.0
	#define BLIND_MAX_TIME 15.0
//}

#define MIN_BURN_WAIT 1.0
#define MAX_BURN_WAIT 20.0
#define MIN_BURN_DAMAGE 0.33
#define MAX_BURN_DAMAGE 1.75

//=--=--=--=--=--=--=--=--=--=--=--=--=

#define ABUSE_RETRY 1
#define ABUSE_RESPAWN 2

#define PUNISH_TIMEOUT 1
#define PUNISH_APPLY 2
	
//=--=--=--=--=--=--=--=--=--=--=--=--=

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hDisabled = INVALID_HANDLE;
new Handle:g_hColors = INVALID_HANDLE;
new Handle:g_hModelsRed = INVALID_HANDLE;
new Handle:g_hColorsRed = INVALID_HANDLE;
new Handle:g_hModelsBlue = INVALID_HANDLE;
new Handle:g_hColorsBlue = INVALID_HANDLE;
new Handle:g_hFailure = INVALID_HANDLE;
new Handle:g_hUsable = INVALID_HANDLE;
new Handle:g_hAbuseDetect = INVALID_HANDLE;
new Handle:g_hAbusePunish = INVALID_HANDLE;
new Handle:g_hCommands = INVALID_HANDLE;
new Handle:g_hTranslations = INVALID_HANDLE;
new Handle:g_hKV_Abuse = INVALID_HANDLE;

//=--=--=--=--=--=--=--=--=--=--=--=--=

new Float:g_fFailure;
new bool:g_bEffectEnabled[(TOTAL_EFFECTS + 1)], bool:g_bLateLoad, bool:g_bEnabled, bool:g_bColors, bool:g_bEnding;
new g_iNumEffects, g_iEffectArray[(TOTAL_EFFECTS + 1)], g_iModelsRed, g_iModelsBlue, g_iColorsRed[4], g_iColorsBlue[4], g_iMyWeapons = -1, g_iUsable = -1, g_iBeamSprite, g_iHaloSprite, 
g_iAbuseDetect, g_iAbusePunish;
new String:g_sModelsRed[MODELS_MAX_ALLOWED][MODELS_MAX_STRING], String:g_sModelsBlue[MODELS_MAX_ALLOWED][MODELS_MAX_STRING], String:g_sPrefixChat[32], String:g_sPrefixConsole[32], 
String:g_sPrefixHint[32], String:g_sPrefixKeyHint[32];
new UserMsg:g_uFadeUserMsg = INVALID_MESSAGE_ID;

new g_iTeam[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];
new bool:g_bClass[MAXPLAYERS + 1];
new bool:g_bRolled[MAXPLAYERS + 1];
new String:g_sName[MAXPLAYERS + 1][32];
new String:g_sSteam[MAXPLAYERS + 1][32];

public Plugin:myinfo =
{
	name = "CSS Roll The Dice",
	author = "Twisted|Panda",
	description = "A custom \"roll the dice\" plugin designed specifically for non-competitive servers.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("css_dice.phrases");

	CreateConVar("css_dice_version", PLUGIN_VERSION, "CSS Dice: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("css_dice_enabled", "1", "Enables/disables all features of the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_hUsable = CreateConVar("css_dice_duration", "120", "The number of seconds after a round start that players can no longer RTD. (0 = Disabled)", FCVAR_NONE, true, 0.0);	
	HookConVarChange(g_hUsable, OnSettingsChange);
	g_hDisabled = CreateConVar("css_dice_disabled", "", "List of indexes, separated with \", \", to be disabled.", FCVAR_NONE);
	HookConVarChange(g_hDisabled, OnSettingsChange);
	g_hFailure = CreateConVar("css_dice_failure", "0.075", "The chance a user has of rolling dice that will have no effect.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hFailure, OnSettingsChange);
	g_hAbuseDetect = CreateConVar("css_dice_abuse_detect", "3", "Determines which forms of rtd abuse to detect. Total values to achieve multiple modes of detection. (0 = Disabled, 1 = Reconnect, 2 = Respawn)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hAbuseDetect, OnSettingsChange);
	g_hAbusePunish = CreateConVar("css_dice_abuse_punish", "2", "Determines the punishment for players who abuse rtd. Total values to achieve multiple modes of detection. (0 = Disabled, 1 = Timeout, 2 = Apply Previous)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hAbusePunish, OnSettingsChange);
	g_hColors = CreateConVar("css_dice_colors", "1", "If enabled, team colors will be applied in certain RTD effects.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hColors, OnSettingsChange);
	g_hModelsRed = CreateConVar("css_dice_models_red", "models/player/t_phoenix.mdl, models/player/t_leet.mdl, models/player/t_arctic.mdl, models/player/t_guerilla.mdl", "List of models, separated with \", \", to be used for Terrorists in certain RTD effects.", FCVAR_NONE);
	HookConVarChange(g_hModelsRed, OnSettingsChange);
	g_hColorsRed = CreateConVar("css_dice_colors_red", "255 0 0 255", "Color combination to be used for Terrorists in certain RTD effects.", FCVAR_NONE);
	HookConVarChange(g_hColorsRed, OnSettingsChange);
	g_hModelsBlue = CreateConVar("css_dice_models_blue", "models/player/ct_urban.mdl, models/player/ct_gsg9.mdl, models/player/ct_sas.mdl, models/player/ct_gign.mdl", "List of models, separated with \", \", to be used for Counter-Terrorists in certain RTD effects.", FCVAR_NONE);
	HookConVarChange(g_hModelsBlue, OnSettingsChange);
	g_hColorsBlue = CreateConVar("css_dice_colors_blue", "0 0 255 255", "Color combination to be used for Terrorists in certain RTD effects.", FCVAR_NONE);
	HookConVarChange(g_hColorsBlue, OnSettingsChange);
	AutoExecConfig(true, "css_dice");

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	AddCommandListener(Command_Class, "joinclass");
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Pre);
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);
	HookEvent("player_jump", Event_OnPlayerJump, EventHookMode_Pre);
	HookEvent("item_pickup", Event_OnItemPickup, EventHookMode_Pre);
	HookEvent("player_changename", Event_OnPlayerName, EventHookMode_Pre);
	HookEvent("hegrenade_detonate", Event_OnGrenadeDetonate);
	HookEvent("flashbang_detonate", Event_OnFlashDetonate);
	HookEvent("smokegrenade_detonate", Event_OnSmokeDetonate);
	
	g_uFadeUserMsg = GetUserMessageId("Fade");
	g_iMyWeapons = FindSendPropOffs("CBaseCombatCharacter", "m_hMyWeapons");
	RegServerCmd("css_dice_translation", Command_SetTranslation);
}

public OnPluginEnd()
{
	if(g_bEnabled)
	{
		ClearTrie(g_hCommands);
		ClearTrie(g_hTranslations);
		for(new i = 1; i <= MaxClients; i++)
			if(IsClientInGame(i))
				Void_RemoveEffect(i);
	}
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		if(g_hCommands == INVALID_HANDLE)
		{
			g_hCommands = CreateTrie();
			Void_SetCommands();
		}

		if(g_hTranslations == INVALID_HANDLE)
		{
			g_hTranslations = CreateTrie();
			Void_SetTranslations();
		}

		Void_SetEffects();
		Format(g_sPrefixChat, sizeof(g_sPrefixChat), "%T", "Prefix_Chat", LANG_SERVER);
		Format(g_sPrefixConsole, sizeof(g_sPrefixConsole), "%T", "Prefix_Console", LANG_SERVER);
		Format(g_sPrefixHint, sizeof(g_sPrefixHint), "%T", "Prefix_Hint", LANG_SERVER);
		Format(g_sPrefixKeyHint, sizeof(g_sPrefixKeyHint), "%T", "Prefix_KeyHint", LANG_SERVER);

		if(g_bLateLoad)
		{
			Void_SetClients();	
			g_bLateLoad = false;
		}
	}
}

public OnMapStart()
{
	Void_SetDefaults();

	if(g_bEnabled)
	{
		PrecacheSound(BEACON_SOUND, true);
		PrecacheSound(JUMP_REFRESH_SOUND, true);

		g_iBeamSprite = PrecacheModel("materials/sprites/laser.vmt");
		g_iHaloSprite = PrecacheModel("materials/sprites/halo01.vmt");

		for(new i = 0; i < g_iModelsRed; i++)
			PrecacheModel(g_sModelsRed[i], true);

		for(new i = 0; i < g_iModelsBlue; i++)
			PrecacheModel(g_sModelsBlue[i], true);

		for(new i = 0; i < MODEL_COUNT; i++)
			PrecacheModel(g_sEffectModel[i][1], true);
	}
}

public OnMapEnd()
{
	if(g_bEnabled)
	{
		if(g_hKV_Abuse != INVALID_HANDLE && CloseHandle(g_hKV_Abuse))
			g_hKV_Abuse = INVALID_HANDLE;
	}
}

public OnClientPutInServer(client)
{
	if(g_bEnabled)
	{
		SDKHook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
		SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	}
}

public OnClientConnected(client)
{
	if(g_bEnabled)
	{
		GetClientName(client, g_sName[client], 32);
	}
}

public OnClientPostAdminCheck(client)
{
	if(g_bEnabled)
	{
		if(IsClientInGame(client))
		{
			GetClientAuthString(client, g_sSteam[client], 32);
		}
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		if(g_bRolled[client] && g_bAlive[client] && g_iAbuseDetect & ABUSE_RETRY)
			KvSetNum(g_hKV_Abuse, g_sSteam[client], g_AbuseData[client][_iEffect]);

		Void_RemoveEffect(client);
		ClearPlayerData(client);
		ClearAbuseData(client);

		g_iTeam[client] = 0;
		g_bAlive[client] = false;
		g_bClass[client] = false;
	}
}

public Action:Command_Say(client, const String:command[], argc)
{
	if(g_bEnabled && client && IsClientInGame(client))
	{
		decl String:_sText[16];
		GetCmdArgString(_sText, sizeof(_sText));
		StripQuotes(_sText);
		TrimString(_sText);
		new _iSize = strlen(_sText);
		for (new i = 0; i < _iSize; i++)
			if (IsCharAlpha(_sText[i]) && IsCharUpper(_sText[i]))
				_sText[i] = CharToLower(_sText[i]);

		if(GetTrieValue(g_hCommands, _sText, _iSize))
		{
			if(g_bRolled[client])
				CPrintToChat(client, "%s%t", g_sPrefixChat, "self_command_rolled");
			else if(g_iTeam[client] <= CS_TEAM_SPECTATOR)
				CPrintToChat(client, "%s%t", g_sPrefixChat, "self_command_spectate");
			else if(!g_bAlive[client])
				CPrintToChat(client, "%s%t", g_sPrefixChat, "self_command_dead");
			else if(g_iUsable != -1 && GetTime() > g_iUsable)
				CPrintToChat(client, "%s%t", g_sPrefixChat, "self_command_disabled");
			else if(KvGetNum(g_hKV_Abuse, g_sSteam[client], EFFECT_NONE))
				CPrintToChat(client, "%s%t", g_sPrefixChat, "self_command_abuse_apply");
			else if(!g_bEnding)
			{
				if(GetRandomFloat(0.00, 1.00) < g_fFailure)
				{
					if(GetRandomFloat(0.00, 1.00) < g_fFailure)
						CPrintToChat(client, "%s%t", g_sPrefixChat, "self_command_chance");
					else
					{
						g_bRolled[client] = true;
						CPrintToChat(client, "%s%t", g_sPrefixChat, "self_command_failure");
						
						for(new i = 1; i <= MaxClients; i++)
							if(i != client && IsClientInGame(i))
								PrintToConsole(i, "%s%t", g_sPrefixConsole, "all_command_failure", g_sName[client]);
					}
				}
				else
				{
					g_bRolled[client] = true;
					Void_IssueEffect(client, g_iEffectArray[GetRandomInt(0, (g_iNumEffects - 1))]);
				}
			}
			
			return Plugin_Stop;
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		if(g_hKV_Abuse != INVALID_HANDLE)
			CloseHandle(g_hKV_Abuse);
		g_hKV_Abuse = CreateKeyValues("css_dice_abuse");

		g_bEnding = true;
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				Void_RemoveEffect(i);
				ClearPlayerData(i);
				ClearAbuseData(i);

				if(g_bClass[i] && g_iTeam[i] >= CS_TEAM_T)
				{
					FakeClientCommand(i, "joinclass %d", ((g_iTeam[i] == CS_TEAM_T) ? GetRandomInt(1, 4) : GetRandomInt(5, 8)));
					g_bClass[i] = false;
				}
			}
		}
	}
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		if(g_hKV_Abuse != INVALID_HANDLE)
			CloseHandle(g_hKV_Abuse);
		g_hKV_Abuse = CreateKeyValues("css_dice_abuse");

		g_bEnding = false;
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && g_bClass[i] && g_iTeam[i] >= CS_TEAM_T)
			{
				FakeClientCommand(i, "joinclass %d", ((g_iTeam[i] == CS_TEAM_T) ? GetRandomInt(1, 4) : GetRandomInt(5, 8)));
				g_bClass[i] = false;
			}
		}

		g_iUsable = GetConVarFloat(g_hUsable) > 0.0 ? (GetTime() + RoundToNearest(GetConVarFloat(g_hUsable))) : -1;
		CPrintToChatAll("%t", "Plugin_Active");
	}
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		if(g_bRolled[client] && g_iAbuseDetect & ABUSE_RESPAWN)
			KvSetNum(g_hKV_Abuse, g_sSteam[client], g_AbuseData[client][_iEffect]);

		g_bAlive[client] = false;
		for(new i = 1; i <= MaxClients; i++)
		{
			if(i != client && IsClientInGame(i) && g_PlayerData[i][_iEffect] > EFFECT_NONE)
			{
				new _iHealth = GetClientHealth(i);
				if(g_iTeam[i] != g_iTeam[client])
				{
					switch(g_PlayerData[i][_iEffect])
					{
						case EFFECT_BOW_BEFORE_ME:
						{
							new _iIncrease = GetRandomInt(COND_HEALTH_GAIN_MIN, COND_HEALTH_GAIN_MAX);
							SetEntityHealth(i, (_iHealth + _iIncrease));
							
							decl String:_sBuffer1[192], String:_sBuffer2[192];
							new Handle:_hTemp = StartMessageOne("KeyHintText", i);
							BfWriteByte(_hTemp, 1);
							Format(_sBuffer1, sizeof(_sBuffer1), "cond_gain_health_from_foe_%d", GetDiceTranslation("cond_gain_health_from_foe"));
							Format(_sBuffer2, sizeof(_sBuffer2), "%s%t", g_sPrefixKeyHint, _sBuffer1, _iIncrease);
							BfWriteString(_hTemp, _sBuffer2); 
							EndMessage();
						}
						case EFFECT_PACIFIST:
						{
							new _iDecrease = GetRandomInt(COND_HEALTH_LOSE_MIN, COND_HEALTH_LOSE_MAX);
							_iHealth -= _iDecrease;
							if(_iHealth < 0)
							{
								Void_SlayPlayer(i);

								decl String:_sBuffer1[192];
								new _iTranslation = GetDiceTranslation("cond_lose_health_death_foe");
								Format(_sBuffer1, sizeof(_sBuffer1), "self_cond_lose_health_death_foe_%d", _iTranslation);
								CPrintToChat(i, "%s%t", g_sPrefixChat, _sBuffer1);
								Format(_sBuffer1, sizeof(_sBuffer1), "all_cond_lose_health_death_foe_%d", _iTranslation);
								for(new j = 1; j <= MaxClients; j++)
									if(j != i && IsClientInGame(j))
										CPrintToChat(j, "%s%t", g_sPrefixChat, _sBuffer1, g_sName[i]);
							}
							else
							{
								SetEntityHealth(i, _iHealth);

								decl String:_sBuffer1[192], String:_sBuffer2[192];
								new Handle:_hTemp = StartMessageOne("KeyHintText", i);
								BfWriteByte(_hTemp, 1);
								Format(_sBuffer1, sizeof(_sBuffer1), "cond_lose_health_to_foe_%d", GetDiceTranslation("cond_lose_health_to_foe"));
								Format(_sBuffer2, sizeof(_sBuffer2), "%s%t", g_sPrefixKeyHint, _sBuffer1, _iDecrease);
								BfWriteString(_hTemp, _sBuffer2); 
								EndMessage();
							}
						}
					}
				}
				else
				{
					switch(g_PlayerData[i][_iEffect])
					{
						case EFFECT_VALIANT_SOUL:
						{
							new _iIncrease = GetRandomInt(COND_HEALTH_GAIN_MIN, COND_HEALTH_GAIN_MAX);
							SetEntityHealth(i, (_iHealth + _iIncrease));

							decl String:_sBuffer1[192], String:_sBuffer2[192];
							new Handle:_hTemp = StartMessageOne("KeyHintText", i);
							BfWriteByte(_hTemp, 1);
							Format(_sBuffer1, sizeof(_sBuffer1), "cond_gain_health_from_team_%d", GetDiceTranslation("cond_gain_health_from_team"));
							Format(_sBuffer2, sizeof(_sBuffer2), "%s%t", g_sPrefixKeyHint, _sBuffer1, _iIncrease);
							BfWriteString(_hTemp, _sBuffer2); 
							EndMessage();
						}
						case EFFECT_NOBODY_LIKES_ME:
						{
							new _iDecrease = GetRandomInt(COND_HEALTH_LOSE_MIN, COND_HEALTH_LOSE_MAX);
							_iHealth -= _iDecrease;
							if(_iHealth < 0)
							{
								Void_SlayPlayer(i);

								decl String:_sBuffer1[192];
								new _iTranslation = GetDiceTranslation("cond_lose_health_death_team");
								Format(_sBuffer1, sizeof(_sBuffer1), "self_cond_lose_health_death_team_%d", _iTranslation);
								CPrintToChat(i, "%s%t", g_sPrefixChat, _sBuffer1);
								Format(_sBuffer1, sizeof(_sBuffer1), "all_cond_lose_health_death_team_%d", _iTranslation);
								for(new j = 1; j <= MaxClients; j++)
									if(j != i && IsClientInGame(j))
										CPrintToChat(j, "%s%t", g_sPrefixChat, _sBuffer1, g_sName[i]);
							}
							else
							{
								SetEntityHealth(i, _iHealth);

								decl String:_sBuffer1[192], String:_sBuffer2[192];
								new Handle:_hTemp = StartMessageOne("KeyHintText", i);
								BfWriteByte(_hTemp, 1);
								Format(_sBuffer1, sizeof(_sBuffer1), "cond_lose_health_to_team_%d", GetDiceTranslation("cond_lose_health_to_team"));
								Format(_sBuffer2, sizeof(_sBuffer2), "%s%t", g_sPrefixKeyHint, _sBuffer1, _iDecrease);
								BfWriteString(_hTemp, _sBuffer2); 
								EndMessage();								
							}
						}
					}
				}
			}
		}

		if(!g_bEnding)
		{
			Void_RemoveEffect(client);
			ClearPlayerData(client);
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client) || g_iTeam[client] <= CS_TEAM_SPECTATOR)
			return Plugin_Continue;

		g_bAlive[client] = true;
		if(g_iAbuseDetect && g_iAbusePunish & PUNISH_APPLY)
		{
			new _iTemp = KvGetNum(g_hKV_Abuse, g_sSteam[client], EFFECT_NONE);
			if(_iTemp > EFFECT_NONE)
			{
				g_bRolled[client] = true;
				Void_IssueEffect(client, _iTemp);
				
				return Plugin_Continue;
			}
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		new _iPrevious = GetEventInt(event, "oldteam");
		g_iTeam[client] = GetEventInt(event, "team");
		if(g_iTeam[client] != _iPrevious)
		{
			if(g_iTeam[client] == CS_TEAM_SPECTATOR)
				g_bAlive[client] = false;

			if(g_bRolled[client] && g_iAbuseDetect & ABUSE_RESPAWN)
				KvSetNum(g_hKV_Abuse, g_sSteam[client], g_AbuseData[client][_iEffect]);

			Void_RemoveEffect(client);
			ClearPlayerData(client);
		}
	}
	
	return Plugin_Continue;
}

public Action:Command_Class(client, const String:command[], argc)
{
	if(g_bEnabled && client && IsClientInGame(client))
	{
		if(g_iAbuseDetect && g_iAbusePunish & PUNISH_TIMEOUT)
		{
			if(g_bClass[client])
				return Plugin_Handled;
			else
			{
				new _iTemp = KvGetNum(g_hKV_Abuse, g_sSteam[client], EFFECT_NONE);
				if(_iTemp > EFFECT_NONE)
				{
					CPrintToChat(client, "%s%t", g_sPrefixChat, "self_command_abuse_retry");
					
					g_bClass[client] = true;
					return Plugin_Handled;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_OnItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
		if(client && IsClientInGame(client) && g_PlayerData[client][_iEffect] > EFFECT_NONE)
		{
			switch(g_PlayerData[client][_iEffect])
			{
				/*
				case EFFECT_BURN:
				{
					decl String:_sTemp[64];
					GetEventString(event, "item", _sTemp, sizeof(_sTemp));
					
					if(StrEqual(_sTemp, "vest") || StrEqual(_sTemp, "vesthelm"))
						g_PlayerData[client][_hSec] = CreateTimer(0.1, Timer_StripArmor, GetClientUserId(client));
				}
				*/
				case EFFECT_STRIPPING:
				{
					g_PlayerData[client][_hSec] = CreateTimer(0.1, Timer_PerformStrip, GetClientUserId(client));
				}
				case EFFECT_FULL_STRIPPING:
				{
					g_PlayerData[client][_hSec] = CreateTimer(0.1, Timer_PerformStrip, GetClientUserId(client));
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnGrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client && IsClientInGame(client) && g_PlayerData[client][_iEffect] > EFFECT_NONE)
		{
		
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnFlashDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client && IsClientInGame(client) && g_PlayerData[client][_iEffect] > EFFECT_NONE)
		{
		
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_OnSmokeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client && IsClientInGame(client) && g_PlayerData[client][_iEffect] > EFFECT_NONE)
		{
		
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client && IsClientInGame(client) && g_bAlive[client] && g_PlayerData[client][_iEffect] > EFFECT_NONE)
		{
			switch(g_PlayerData[client][_iEffect])
			{
				case EFFECT_HIGH_JUMP, EFFECT_LONG_JUMP, EFFECT_SUPER_JUMP:
					g_PlayerData[client][_hPrim] = CreateTimer(0.1, Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
				case EFFECT_JUMP_FUCKER:
					g_PlayerData[client][_hPrim] = CreateTimer(0.15, Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerName(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client && IsClientInGame(client))
			GetEventString(event, "newname", g_sName[client], 32);
	}
}

//=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=
//  - Required to get several effects to work properly
//=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=
public OnGameFrame()
{
	if(g_bEnabled)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(g_bAlive[i] && IsClientInGame(i))
			{
				switch(g_PlayerData[i][_iEffect])
				{
					case EFFECT_DRUG:
						ClientCommand(i, "r_screenoverlay %s", g_sEffectDrug[g_PlayerData[i][_iPrim]]);
					case EFFECT_MONO:
						ClientCommand(i, "r_screenoverlay %s", g_sEffectMono[g_PlayerData[i][_iPrim]]);
				}
			}
		}
	}
}

//=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=
//  - Applies the specified effect to the client.
//=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=
Void_IssueEffect(client, effect)
{
	if(!IsClientInGame(client))
		return;

	decl String:_sBuffer1[192];
	new _iTranslation = GetEffectTranslation(effect);
	switch(effect)
	{
		case EFFECT_HEALTH_GAIN:
		{		
			decl _iTemp;
			if(GetRandomInt(0, 1))
				_iTemp = GetRandomInt(HEALTH_GAIN_MIN, HEALTH_GAIN_MAX);
			else
				_iTemp = g_iEffectHealthGain[GetRandomInt(0, (HEALTH_GAIN_COUNT - 1))];
			
			SetEntityHealth(client, (GetClientHealth(client) + _iTemp));
			
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_health_gain_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1, _iTemp);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_health_gain_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client], _iTemp);
		}
		case EFFECT_HEALTH_LOSE:
		{
			decl _iTemp;
			if(GetRandomInt(0, 1))
				_iTemp = GetRandomInt(HEALTH_LOSE_MIN, HEALTH_LOSE_MAX);
			else
				_iTemp = g_iEffectHealthLose[GetRandomInt(0, (HEALTH_LOSE_COUNT - 1))];

			new _iHealth = GetClientHealth(client);
			if((_iHealth - _iTemp) > 0)
				SetEntityHealth(client, (_iHealth - _iTemp));
			else
				Void_SlayPlayer(client);

			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_health_lose_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1, _iTemp);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_health_lose_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client], _iTemp);
		}
		case EFFECT_HEALTH_RAND:
		{
			new _iTemp = RoundToNearest(float(GetClientHealth(client)) * GetRandomFloat(HEALTH_RAND_MIN, HEALTH_RAND_MAX));

			SetEntityHealth(client, _iTemp);

			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_health_rand_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_health_rand_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_GRAVITY_GAIN:
		{
			new Float:_fBuffer;
			if(GetRandomInt(0, 1))
				_fBuffer = GetRandomFloat(GRAVITY_GAIN_MIN, GRAVITY_GAIN_MAX);
			else
				_fBuffer = g_fEffectGravityGain[GetRandomInt(0, (GRAVITY_GAIN_COUNT - 1))];
			g_PlayerData[client][_fPrim] = GRAVITY_DEFAULT_VALUE + _fBuffer;

			SetEntityGravity(client, GRAVITY_DEFAULT_VALUE);
			SetEffectGravity(client, GRAVITY_DEFAULT_VALUE);

			new _iDisplay = RoundToNearest(_fBuffer * 100.0);
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_gravity_gain_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1, _iDisplay, "%%");
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_gravity_gain_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client], _iDisplay, "%%");
		}
		case EFFECT_GRAVITY_LOSE:
		{
			new Float:_fBuffer;
			if(GetRandomInt(0, 1))
				_fBuffer = GetRandomFloat(GRAVITY_LOSE_MIN, GRAVITY_LOSE_MAX);
			else
				_fBuffer = g_fEffectGravityLose[GetRandomInt(0, (GRAVITY_LOSE_COUNT - 1))];
			g_PlayerData[client][_fPrim] = GRAVITY_DEFAULT_VALUE - _fBuffer;

			SetEntityGravity(client, GRAVITY_DEFAULT_VALUE);
			SetEffectGravity(client, GRAVITY_DEFAULT_VALUE);
			
			new _iDisplay = RoundToNearest(_fBuffer * 100.0);
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_gravity_lose_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1, _iDisplay, "%%");
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_gravity_lose_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client], _iDisplay, "%%");
		}
		case EFFECT_GRAVITY_RAND:
		{
			g_PlayerData[client][_fPrim] = GetRandomFloat(GRAVITY_RAND_MIN, GRAVITY_RAND_MAX);
			
			SetEntityGravity(client, GRAVITY_DEFAULT_VALUE);
			SetEffectGravity(client, GRAVITY_DEFAULT_VALUE);

			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_gravity_rand_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_gravity_rand_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);

		}
		case EFFECT_SPEED_GAIN:
		{
			new Float:_fBuffer;
			if(GetRandomInt(0, 1))
				_fBuffer = GetRandomFloat(SPEED_GAIN_MIN, SPEED_GAIN_MAX);
			else
				_fBuffer = g_fEffectSpeedGain[GetRandomInt(0, (SPEED_GAIN_COUNT - 1))];
			g_PlayerData[client][_fPrim] = SPEED_DEFAULT_VALUE + _fBuffer;

			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", SPEED_DEFAULT_VALUE);
			SetEffectSpeed(client, SPEED_DEFAULT_VALUE);

			new _iDisplay = RoundToNearest(_fBuffer * 100.0);
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_speed_gain_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1, _iDisplay, "%%");
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_speed_gain_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client], _iDisplay, "%%");
		}
		case EFFECT_SPEED_LOSE:
		{
			new Float:_fBuffer;
			if(GetRandomInt(0, 1))
				_fBuffer = GetRandomFloat(SPEED_LOSE_MIN, SPEED_LOSE_MAX);
			else
				_fBuffer = g_fEffectSpeedLose[GetRandomInt(0, (SPEED_LOSE_COUNT - 1))];
			g_PlayerData[client][_fPrim] = SPEED_DEFAULT_VALUE - _fBuffer;

			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", SPEED_DEFAULT_VALUE);
			SetEffectSpeed(client, SPEED_DEFAULT_VALUE);
			
			new _iDisplay = RoundToNearest(_fBuffer * 100.0);
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_speed_lose_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1, _iDisplay, "%%");
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_speed_lose_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client], _iDisplay, "%%");
		}
		case EFFECT_SPEED_RAND:
		{
			g_PlayerData[client][_fPrim] = GetRandomFloat(SPEED_RAND_MIN, SPEED_RAND_MAX);

			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", SPEED_DEFAULT_VALUE);
			SetEffectSpeed(client, SPEED_DEFAULT_VALUE);
			
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_speed_rand_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_speed_rand_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_COLOR:
		{
			new _iTemp = GetRandomInt(0, (COLOR_COUNT - 1));

			SetEffectApperance(client, g_iEffectColor[_iTemp], -1, 1);

			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_color_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_color_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_ALPHA:
		{
			new _iTemp = GetRandomInt(0, (ALPHA_COUNT - 1)), _iArray[4];

			if(g_bColors)
			{
				switch(g_iTeam[client])
				{
					case 2:
					{
						for(new i = 0; i < 3; i++)
							_iArray[i] = g_iColorsRed[i];
							
						_iArray[3] = g_iEffectAlpha[_iTemp][3];
					}
					case 3:
					{
						for(new i = 0; i < 3; i++)
							_iArray[i] = g_iColorsBlue[i];
							
						_iArray[3] = g_iEffectAlpha[_iTemp][3];
					}
				}
				
				SetEffectApperance(client, _iArray, -1, 1);
			}
			else
				SetEffectApperance(client, g_iEffectAlpha[_iTemp], -1, 1);

			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_alpha_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_alpha_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_MODEL:
		{
			new _iTemp = GetRandomInt(0, (MODEL_COUNT - 1));

			SetEntityModel(client, g_sEffectModel[_iTemp][1]);
			if(g_bColors)
			{
				switch(g_iTeam[client])
				{
					case 2:
						SetEntityRenderColor(client, g_iColorsRed[0], g_iColorsRed[1], g_iColorsRed[2], g_iColorsRed[3]);
					case 3:
						SetEntityRenderColor(client, g_iColorsBlue[0], g_iColorsBlue[1], g_iColorsBlue[2], g_iColorsBlue[3]);
				}
			}
			
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_model_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1, g_sEffectModel[_iTemp][0]);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_model_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client], g_sEffectModel[_iTemp][0]);
		}
		case EFFECT_SNEAKY:
		{
			switch(g_iTeam[client])
			{
				case 2:
				{
					SetEntityModel(client, g_sModelsBlue[GetRandomInt(0, (g_iModelsBlue - 1))]);
					if(g_bColors)
						SetEntityRenderColor(client, g_iColorsBlue[0], g_iColorsBlue[1], g_iColorsBlue[2], g_iColorsBlue[3]);
				}
				case 3:
				{
					SetEntityModel(client, g_sModelsRed[GetRandomInt(0, (g_iModelsRed - 1))]);
					if(g_bColors)
						SetEntityRenderColor(client, g_iColorsRed[0], g_iColorsRed[1], g_iColorsRed[2], g_iColorsRed[3]);
				}
			}

			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_sneaky_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_sneaky_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_SLOW_POISON:
		{
			g_PlayerData[client][_iPrim] = GetRandomInt(0, 1);

			Void_SlowPoison(client);

			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_slow_poison_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_slow_poison_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
						PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_FAST_POISON:
		{
			g_PlayerData[client][_iPrim] = GetRandomInt(0, 2);

			Void_FastPoison(client);

			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_fast_poison_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_fast_poison_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_SLOW_REGEN:
		{
			g_PlayerData[client][_iPrim] = GetRandomInt(REGEN_HEALTH_MIN, REGEN_HEALTH_MAX);

			Void_SlowRegen(client);

			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_slow_regen_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_slow_regen_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_FAST_REGEN:
		{
			g_PlayerData[client][_iPrim] = GetRandomInt(REGEN_HEALTH_MIN, REGEN_HEALTH_MAX);

			Void_FastRegen(client);

			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_fast_regen_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_fast_regen_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_STRONG:
		{
			if(GetRandomInt(0, 1))
				g_PlayerData[client][_fPrim] = GetRandomFloat(STRONG_MIN, STRONG_MAX);
			else
				g_PlayerData[client][_fPrim] = g_fEffectStrong[GetRandomInt(0, (STRONG_COUNT - 1))];

			new _iDisplay = RoundToNearest(g_PlayerData[client][_fPrim] * 100.0) - 100;
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_strong_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1, _iDisplay, "%%");
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_strong_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client], _iDisplay, "%%");
		}
		case EFFECT_WEAK:
		{
			if(GetRandomInt(0, 1))
				g_PlayerData[client][_fPrim] = GetRandomFloat(WEAK_MIN, WEAK_MAX);
			else
				g_PlayerData[client][_fPrim] = g_fEffectWeak[GetRandomInt(0, (WEAK_COUNT - 1))];

			new _iDisplay = 100 - RoundToNearest(g_PlayerData[client][_fPrim] * 100.0);
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_weak_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1, _iDisplay, "%%");
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_weak_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client], _iDisplay, "%%");
		}
		case EFFECT_DEAL_RAND:
		{
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_deal_rand_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_deal_rand_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_TANK:
		{
			if(GetRandomInt(0, 1))
				g_PlayerData[client][_fPrim] = GetRandomFloat(TANK_MIN, TANK_MAX);
			else
				g_PlayerData[client][_fPrim] = g_fEffectTank[GetRandomInt(0, (TANK_COUNT - 1))];
			
			new _iDisplay = 100 - RoundToNearest(g_PlayerData[client][_fPrim] * 100.0);
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_tank_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1, _iDisplay, "%%");
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_tank_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client], _iDisplay, "%%");
		}
		case EFFECT_SQUISHY:
		{
			if(GetRandomInt(0, 1))
				g_PlayerData[client][_fPrim] = GetRandomFloat(SQUISHY_MIN, SQUISHY_MAX);
			else
				g_PlayerData[client][_fPrim] = g_fEffectSquishy[GetRandomInt(0, (SQUISHY_COUNT - 1))];

			new _iDisplay = RoundToNearest(g_PlayerData[client][_fPrim] * 100.0) - 100;
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_squishy_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1, _iDisplay, "%%");
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_squishy_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client], _iDisplay, "%%");
		}
		case EFFECT_TAKE_RAND:
		{
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_take_rand_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_take_rand_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_SLAP_HURT:
		{
			g_PlayerData[client][_iPrim] = GetRandomInt(0, 2);

			Void_HurtingSlap(client);

			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_hurt_slap_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_hurt_slap_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_SLAP_HEAL:
		{
			Void_HealingSlap(client);

			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_heal_slap_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_heal_slap_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_HIGH_JUMP:
		{
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_high_jump_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_high_jump_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_LONG_JUMP:
		{
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_long_jump_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_long_jump_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_SUPER_JUMP:
		{
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_super_jump_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_super_jump_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_JUMP_FUCKER:
		{
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_jump_fucker_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_jump_fucker_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_BEACON_TINY:
		{
			Void_PerformTinyBeacon(client);

			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_tiny_beacon_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_tiny_beacon_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_BEACON_LARGE:
		{
			Void_PerformLargeBeacon(client);

			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_large_beacon_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_large_beacon_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_BLIND_STATIC:
		{
			Void_PerformBlind(client, false, false);

			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_blind_static_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_blind_static_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_BLIND_RAND:
		{
			Void_PerformBlind(client, true, false);

			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_blind_rand_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_blind_rand_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_DRUG:
		{
			g_PlayerData[client][_iPrim] = GetRandomInt(0, (DRUG_COUNT - 1));
			
			Void_PerformDrug(client, false);

			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_drug_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_drug_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_MONO:
		{
			g_PlayerData[client][_iPrim] = GetRandomInt(0, (MONO_COUNT - 1));

			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_mono_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_mono_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_STRIPPING:
		{
			g_PlayerData[client][_iPrim] = GetEntProp(client, Prop_Send, "m_iAccount");
			SetEntProp(client, Prop_Send, "m_iAccount", 0);

			decl _iTemp;
			for(new i = 0; i <= 5; i++)
			{
				while(i != 2 && (_iTemp = GetPlayerWeaponSlot(client, i)) != -1)
				{
					RemovePlayerItem(client, _iTemp);
					RemoveEdict(_iTemp);
				}
			}

			FakeClientCommandEx(client, "use weapon_knife");
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_strip_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_strip_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_VALIANT_SOUL:
		{
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_valiant_soul_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_valiant_soul_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_NOBODY_LIKES_ME:
		{
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_nobody_likes_me_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_nobody_likes_me_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_BOW_BEFORE_ME:
		{
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_bow_before_me_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_bow_before_me_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_PACIFIST:
		{
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_pacifist_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_pacifist_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_FULL_STRIPPING:
		{
			g_PlayerData[client][_iPrim] = GetEntProp(client, Prop_Send, "m_iAccount");
			SetEntProp(client, Prop_Send, "m_iAccount", 0);

			decl _iTemp;
			for(new i = 0; i <= 5; i++)
			{
				while((_iTemp = GetPlayerWeaponSlot(client, i)) != -1)
				{
					RemovePlayerItem(client, _iTemp);
					RemoveEdict(_iTemp);
				}
			}

			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_strip_full_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_strip_full_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		case EFFECT_INVERTED:
		{
			Format(_sBuffer1, sizeof(_sBuffer1), "self_effect_inverted_%d", _iTranslation);
			CPrintToChat(client, "%s%t", g_sPrefixChat, _sBuffer1);
			Format(_sBuffer1, sizeof(_sBuffer1), "all_effect_inverted_%d", _iTranslation);
			for(new i = 1; i <= MaxClients; i++)
				if(i != client && IsClientInGame(i))
					PrintToConsole(i, "%s%t", g_sPrefixConsole, _sBuffer1, g_sName[client]);
		}
		/*
		case EFFECT_BURN:
		{
			g_PlayerData[client][0] = GetRandomInt(1, 2);
			switch(g_PlayerData[client][0])
			{
				case 1:
				{
					g_fData[client][0] = GetRandomFloat(MIN_BURN_DAMAGE, MAX_BURN_DAMAGE * 2);
					SetEntProp(client, Prop_Send, "m_ArmorValue", (RoundToCeil(g_fData[client][0] * float(BURN_EFFECT_PER_SECOND)) + 1), 1);

					Void_PerformBurn(client, g_fData[client][0]);
					g_hTimers[client] = CreateTimer((g_fData[client][0] + GetRandomFloat(MIN_BURN_WAIT, MAX_BURN_WAIT)), Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
				}
				case 2:
				{
					g_fData[client][0] = GetRandomFloat(MIN_BURN_DAMAGE, MAX_BURN_DAMAGE);

					Void_PerformBurn(client, g_fData[client][0]);
					g_hTimers[client] = CreateTimer((g_fData[client][0] + GetRandomFloat(MIN_BURN_WAIT, MAX_BURN_WAIT)), Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			PrintDiceToAll(MSG_MODE_EFFECT, client, "effect_burn", true, g_PlayerData[client][_iEffect], 1, "");
		}
		*/
	}
	
	g_PlayerData[client][_iEffect] = effect;
	g_AbuseData[client][_iEffect] = effect;
}

//=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=
// - Timer function that handles the majority of RTD effects that need delays
//=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=
public Action:Timer_PerformEffect(Handle:timer, any:client)
{
	if(g_PlayerData[client][_hPrim] != INVALID_HANDLE)
		g_PlayerData[client][_hPrim] = INVALID_HANDLE;
		
	if(g_PlayerData[client][_hSec] != INVALID_HANDLE)
		g_PlayerData[client][_hSec] = INVALID_HANDLE;

	if(!g_bAlive[client] || g_PlayerData[client][_iEffect] == EFFECT_NONE)
		return Plugin_Handled;

	switch(g_PlayerData[client][_iEffect])
	{
		case EFFECT_GRAVITY_GAIN, EFFECT_GRAVITY_LOSE, EFFECT_GRAVITY_RAND:
		{
			SetEffectGravity(client, GetEntityGravity(client));
		}
		case EFFECT_SPEED_GAIN, EFFECT_SPEED_LOSE, EFFECT_SPEED_RAND:
		{
			SetEffectSpeed(client, GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue"));
		}
		case EFFECT_COLOR:
		{
			SetEffectApperance(client, g_iEffectColor[GetRandomInt(0, (COLOR_COUNT - 1))], -1, 1);
		}
		case EFFECT_ALPHA:
		{
			SetEffectApperance(client, g_iEffectAlpha[GetRandomInt(0, (ALPHA_COUNT - 1))], -1, 1);
		}
		case EFFECT_SLOW_POISON:
		{
			Void_SlowPoison(client);
		}
		case EFFECT_FAST_POISON:
		{
			Void_FastPoison(client);
		}
		case EFFECT_SLOW_REGEN:
		{
			Void_SlowRegen(client);
		}
		case EFFECT_FAST_REGEN:
		{
			Void_FastRegen(client);
		}
		case EFFECT_SLAP_HURT:
		{
			Void_HurtingSlap(client);
		}
		case EFFECT_SLAP_HEAL:
		{
			Void_HealingSlap(client);
		}
		case EFFECT_HIGH_JUMP, EFFECT_LONG_JUMP, EFFECT_SUPER_JUMP:
		{
			Void_PerformJump(client, g_PlayerData[client][_iEffect]);
		}
		case EFFECT_JUMP_FUCKER:
		{
			SlapPlayer(client, 0);
		}
		case EFFECT_BEACON_TINY:
		{
			Void_PerformTinyBeacon(client);
		}
		case EFFECT_BEACON_LARGE:
		{
			Void_PerformLargeBeacon(client);
		}
		case EFFECT_BLIND_RAND:
		{
			Void_PerformBlind(client, true, false);
		}
		case EFFECT_DRUG:
		{
			Void_PerformDrug(client, false);
		}
		case EFFECT_INVERTED:
		{
			Void_PerformInvert(client, false);
		}
		/*
		case EFFECT_BURN:
		{
			switch(g_PlayerData[client][0])
			{
				case 1:
				{
					g_fData[client][0] = GetRandomFloat(MIN_BURN_DAMAGE, MAX_BURN_DAMAGE * 2);
					SetEntProp(client, Prop_Send, "m_ArmorValue", (RoundToCeil(g_fData[client][0] * float(BURN_EFFECT_PER_SECOND)) + 1), 1);

					Void_PerformBurn(client, g_fData[client][0]);
					g_hTimers[client] = CreateTimer((g_fData[client][0] + GetRandomFloat(MIN_BURN_WAIT, MAX_BURN_WAIT)), Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
				}
				case 2:
				{
					g_fData[client][0] = GetRandomFloat(MIN_BURN_DAMAGE, MAX_BURN_DAMAGE);

					Void_PerformBurn(client, g_fData[client][0]);
					g_hTimers[client] = CreateTimer((g_fData[client][0] + GetRandomFloat(MIN_BURN_WAIT, MAX_BURN_WAIT)), Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		*/
	}
	
	return Plugin_Continue;
}

//=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=
//  - Ensures that the clients effect is removed before the next spawn/on disconnect.
//=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=
Void_RemoveEffect(client)
{
	if(IsClientInGame(client))
	{
		switch(g_PlayerData[client][_iEffect])
		{
			case EFFECT_STRIPPING:
			{
				if(g_PlayerData[client][_iPrim])
				{
					new _iCash = GetEntProp(client, Prop_Send, "m_iAccount");
					SetEntProp(client, Prop_Send, "m_iAccount", (_iCash + g_PlayerData[client][_iPrim]));
				}
			}
			case EFFECT_FULL_STRIPPING:
			{
				if(g_PlayerData[client][_iPrim])
				{
					new _iCash = GetEntProp(client, Prop_Send, "m_iAccount");
					SetEntProp(client, Prop_Send, "m_iAccount", (_iCash + g_PlayerData[client][_iPrim]));
				}
			}
			case EFFECT_BLIND_STATIC, EFFECT_BLIND_RAND:
			{
				Void_PerformBlind(client, false, true);
			}
			case EFFECT_DRUG:
			{
				Void_PerformDrug(client, true);
			}
			case EFFECT_MONO:
			{
				Void_ResetScreen(client);
			}
			case EFFECT_GRAVITY_GAIN, EFFECT_GRAVITY_LOSE, EFFECT_GRAVITY_RAND:
			{
				SetEntityGravity(client, GRAVITY_DEFAULT_VALUE);
			}
			case EFFECT_SPEED_GAIN, EFFECT_SPEED_LOSE, EFFECT_SPEED_RAND:
			{
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", SPEED_DEFAULT_VALUE);
			}
			case EFFECT_INVERTED:
			{
				Void_PerformInvert(client, true);
			}
		}
	}

	g_bRolled[client] = false;
}

/*
Void_PerformBurn(client, Float:length)
{
	ExtinguishEntity(client);
	IgniteEntity(client, length);
}
*/

//=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=
// ~ Strips the player of their armor if they attempt to pick it up
//=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=
public Action:Timer_StripArmor(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
	{
		if(g_PlayerData[client][_hSec] != INVALID_HANDLE)
			g_PlayerData[client][_hSec] = INVALID_HANDLE;

		SetEntProp(client, Prop_Send, "m_ArmorValue", g_PlayerData[client][0]);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
	}
}

public Action:Timer_PerformStrip(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
	{			
		if(g_PlayerData[client][_hSec] != INVALID_HANDLE)
			g_PlayerData[client][_hSec] = INVALID_HANDLE;

		decl _iEnt, String:_sTemp[32];
		for(new i = 0; i <= (7 * 4); i += 4)
		{
			_iEnt = GetEntDataEnt2(client, (g_iMyWeapons + i));
			if(_iEnt > 0 && IsValidEdict(_iEnt) && IsValidEntity(_iEnt))
			{
				if(g_PlayerData[client][_iPrim])
				{
					GetEdictClassname(_iEnt, _sTemp, sizeof(_sTemp));
					if(!StrEqual(_sTemp, "weapon_knife"))
					{
						RemovePlayerItem(client, _iEnt);
						RemoveEdict(_iEnt);
					}
				}
				else
				{
					RemovePlayerItem(client, _iEnt);
					RemoveEdict(_iEnt);
				}
			}
		}
	}
}

public Action:Hook_WeaponCanUse(client, weapon)
{
	if(g_bEnabled)
	{
		switch(g_PlayerData[client][_iEffect])
		{
			case EFFECT_STRIPPING:
			{
				decl String:_sTemp[32];
				GetEdictClassname(weapon, _sTemp, sizeof(_sTemp));
				if(!StrEqual(_sTemp, "weapon_knife"))
					return Plugin_Handled;
			}
			case EFFECT_FULL_STRIPPING:
			{
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

public Action:Hook_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(g_bEnabled)
	{
		if(0 < victim <= MaxClients)
		{
			switch(g_PlayerData[victim][_iEffect])
			{
				case EFFECT_TANK, EFFECT_SQUISHY:
				{
					if(attacker && damage > 0.0)
					{
						if(attacker <= MaxClients)
						{
							switch(g_PlayerData[attacker][_iEffect])
							{
								case EFFECT_STRONG, EFFECT_WEAK:
									damage *= g_PlayerData[attacker][_fPrim];
								case EFFECT_DEAL_RAND:
									damage = GetRandomFloat(DEAL_MIN, DEAL_MAX);
							}
						}

						damage *= g_PlayerData[victim][_fPrim];
						if(damage < 1.0)
							damage = 1.0;

						return Plugin_Changed;
					}
				}
				case EFFECT_TAKE_RAND:
				{
					if(attacker && damage > 0.0)
					{
						damage = GetRandomFloat(TAKE_MIN, TAKE_MAX);
						if(attacker <= MaxClients)
						{
							switch(g_PlayerData[attacker][_iEffect])
							{
								case EFFECT_STRONG, EFFECT_WEAK:
								{
									damage *= g_PlayerData[attacker][_fPrim];
									if(damage < 1.0)
										damage = 1.0;
								}
								case EFFECT_DEAL_RAND:
								{
									damage += GetRandomFloat(DEAL_MIN, DEAL_MAX);
								}
							}
						}

						return Plugin_Changed;
					}
				}
				default:
				{
					if(attacker && attacker <= MaxClients)
					{
						switch(g_PlayerData[attacker][_iEffect])
						{
							case EFFECT_STRONG, EFFECT_WEAK:
							{
								damage *= g_PlayerData[attacker][_fPrim];
								return Plugin_Changed;
							}
							case EFFECT_DEAL_RAND:
							{
								damage = GetRandomFloat(DEAL_MIN, DEAL_MAX);
								return Plugin_Changed;
							}
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

Void_SetCommands()
{
	ClearTrie(g_hCommands);
	SetTrieValue(g_hCommands, "rtd", 1);
	SetTrieValue(g_hCommands, "!rtd", 1);
	SetTrieValue(g_hCommands, "/rtd", 1);
	SetTrieValue(g_hCommands, "dice", 1);
	SetTrieValue(g_hCommands, "!dice", 1);
	SetTrieValue(g_hCommands, "/dice", 1);
	SetTrieValue(g_hCommands, "rollthedice", 1);
	SetTrieValue(g_hCommands, "!rollthedice", 1);
	SetTrieValue(g_hCommands, "/rollthedice", 1);
}

Void_SetTranslations()
{
	ClearTrie(g_hTranslations);
	SetTrieValue(g_hTranslations, "self_velocity_cap", 1);
	SetTrieValue(g_hTranslations, "cond_gain_health_from_foe", 1);
	SetTrieValue(g_hTranslations, "cond_lose_health_death_foe", 1);
	SetTrieValue(g_hTranslations, "cond_lose_health_to_foe", 1);
	SetTrieValue(g_hTranslations, "cond_gain_health_from_team", 1);
	SetTrieValue(g_hTranslations, "cond_lose_health_death_team", 1);
	SetTrieValue(g_hTranslations, "cond_lose_health_to_team", 1);
}

Void_SetDefaults()
{
	g_bEnabled = GetConVarInt(g_hEnabled) ? true : false;
	g_fFailure = GetConVarFloat(g_hFailure);
	g_iUsable = GetConVarFloat(g_hUsable) > 0.0 ? (GetTime() + RoundToNearest(GetConVarFloat(g_hUsable))) : -1;
	g_iAbuseDetect = GetConVarInt(g_hAbuseDetect);
	g_iAbusePunish = GetConVarInt(g_hAbusePunish);
	g_hKV_Abuse = (g_iAbuseDetect && g_bEnabled) ? CreateKeyValues("css_dice_abuse") : INVALID_HANDLE;
	g_bColors = GetConVarInt(g_hColors) ? true : false;
	
	decl String:_sTemp[1024], String:_sColors[4][8];
	GetConVarString(g_hModelsRed, _sTemp, sizeof(_sTemp));
	g_iModelsRed = ExplodeString(_sTemp, ", ", g_sModelsRed, MODELS_MAX_ALLOWED, MODELS_MAX_STRING);

	GetConVarString(g_hModelsBlue, _sTemp, sizeof(_sTemp));
	g_iModelsBlue = ExplodeString(_sTemp, ", ", g_sModelsBlue, MODELS_MAX_ALLOWED, MODELS_MAX_STRING);
	
	GetConVarString(g_hColorsRed, _sTemp, sizeof(_sTemp));
	ExplodeString(_sTemp, " ", _sColors, 4, 8);
	for(new i = 0; i <= 3; i++)
		g_iColorsRed[i] = StringToInt(_sColors[i]);

	GetConVarString(g_hColorsBlue, _sTemp, sizeof(_sTemp));
	ExplodeString(_sTemp, " ", _sColors, 4, 8);
	for(new i = 0; i <= 3; i++)
		g_iColorsBlue[i] = StringToInt(_sColors[i]);
}

Void_SetClients()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			g_iTeam[i] = GetClientTeam(i);
			g_bAlive[i] = IsPlayerAlive(i) ? true : false;
			GetClientAuthString(i, g_sSteam[i], 32);	
			
			g_bClass[i] = false;
			g_bRolled[i] = false;
			GetClientName(i, g_sName[i], 32);
			SDKHook(i, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
		}
	}
}

Void_SetEffects()
{
	decl _iTemp, String:_sTemp[1024], String:_sDisabledEffects[TOTAL_EFFECTS][4];
	GetConVarString(g_hDisabled, _sTemp, sizeof(_sTemp));
	_iTemp = ExplodeString(_sTemp, ", ", _sDisabledEffects, TOTAL_EFFECTS, 4);

	g_iNumEffects = 0;
	for(new i = 1; i <= TOTAL_EFFECTS; i++)
	{
		g_iEffectArray[i] = 0;
		g_bEffectEnabled[i] = true;

		for(new j = 0; j < _iTemp; j++)
		{
			if(StringToInt(_sDisabledEffects[j]) == i)
			{
				g_bEffectEnabled[i] = false;
				break;
			}
		}
		
		if(g_bEffectEnabled[i])
		{
			g_iEffectArray[g_iNumEffects] = i;
			if(g_iNumEffects < TOTAL_EFFECTS)
				g_iNumEffects++;
		}
	}
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
	{
		g_bEnabled = StringToInt(newvalue) ? true : false;

		if(!StringToInt(oldvalue) && g_bEnabled)
		{
			Void_SetDefaults();
			Void_SetEffects();
			Void_SetClients();
		}
	}
	else if(cvar == g_hDisabled)
		Void_SetEffects();
	else if(cvar == g_hFailure)
		g_fFailure = StringToFloat(newvalue);
	else if(cvar == g_hUsable)
		g_iUsable = StringToFloat(newvalue) > 0.0 ? (GetTime() + RoundToNearest(StringToFloat(newvalue))) : -1;
	else if(cvar == g_hColors)
		g_bColors = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hModelsRed)
	{
		g_iModelsRed = ExplodeString(newvalue, ", ", g_sModelsRed, MODELS_MAX_ALLOWED, MODELS_MAX_STRING);
		for(new i = 0; i < g_iModelsRed; i++)
			PrecacheModel(g_sModelsRed[i], true);
	}
	else if(cvar == g_hColorsRed)
	{
		decl String:_sColors1[4][8];
		ExplodeString(newvalue, " ", _sColors1, 4, 8);
		for(new i = 0; i <= 3; i++)
			g_iColorsRed[i] = StringToInt(_sColors1[i]);
	}
	else if(cvar == g_hModelsBlue)
	{
		g_iModelsBlue = ExplodeString(newvalue, ", ", g_sModelsBlue, MODELS_MAX_ALLOWED, MODELS_MAX_STRING);
		for(new i = 0; i < g_iModelsBlue; i++)
			PrecacheModel(g_sModelsBlue[i], true);
	}
	else if(cvar == g_hColorsBlue)
	{
		decl String:_sColors2[4][8];
		ExplodeString(newvalue, " ", _sColors2, 4, 8);
		for(new i = 0; i <= 3; i++)
			g_iColorsBlue[i] = StringToInt(_sColors2[i]);
	}
	else if(cvar == g_hAbuseDetect)
	{
		g_iAbuseDetect = StringToInt(newvalue);
		if(g_hKV_Abuse != INVALID_HANDLE)
			CloseHandle(g_hKV_Abuse);

		g_hKV_Abuse = (g_iAbuseDetect && g_bEnabled) ? CreateKeyValues("css_dice_abuse") : INVALID_HANDLE;
	}
	else if(cvar == g_hAbusePunish)
		g_iAbusePunish = StringToInt(newvalue);
}

public Action:Command_SetTranslation(args)
{
	if (args < 2)
	{
		LogError("|oG| Dice: Invalid Command Usage! \"css_dice_translation <effect/trans> <count>\"");
		return Plugin_Handled;
	}
	
	decl _iArg1, String:_sArg1[64], _iArg2, String:_sArg2[8];
	GetCmdArg(1, _sArg1, sizeof(_sArg1));
	GetCmdArg(2, _sArg2, sizeof(_sArg2));
	_iArg2 = StringToInt(_sArg2);
	_iArg2 = _iArg2 > 1 ? _iArg2 : 1;

	if(strlen(_sArg1) > 3)
	{
		TrimString(_sArg1);
		if(!GetTrieValue(g_hTranslations, _sArg1, _iArg1))
		{
			LogError("|oG| Dice: Invalid String! Provided (%s)", _sArg1);
			return Plugin_Handled;
		}
		
		SetTrieValue(g_hTranslations, _sArg1, _iArg1);
	}
	else
	{
		_iArg1 = StringToInt(_sArg1);
		if(_iArg1 < 0 || _iArg1 > g_iNumEffects)
		{
			LogError("|oG| Dice: Invalid Index! Provided (%d) ~ Min (0) ~ Max (%d)", _iArg1, g_iNumEffects);
			return Plugin_Handled;
		}

		g_iTranslations[_iArg1] = _iArg2;
	}

	return Plugin_Handled;
}

//============================================================================================================

//Translations
//{
	GetEffectTranslation(effect)
	{
		return g_iTranslations[effect] > 1 ? GetRandomInt(1, g_iTranslations[effect]) : 1;
	}
	
	GetDiceTranslation(const String:buffer[])
	{
		decl _iIndex;
		GetTrieValue(g_hTranslations, buffer, _iIndex);
		
		return _iIndex > 1 ? GetRandomInt(1, _iIndex) : 1;
	}
//}

//Miscellaneous
//{
	ClearPlayerData(client, bool:_bHandles = true)
	{
		g_PlayerData[client][_iEffect] = EFFECT_NONE;
		g_PlayerData[client][_iPrim] = 0;
		g_PlayerData[client][_iSec] = 0;
		g_PlayerData[client][_fPrim] = 0.0;
		g_PlayerData[client][_fSec] = 0.0;
		
		if(_bHandles)
		{
			if(g_PlayerData[client][_hPrim] != INVALID_HANDLE && CloseHandle(g_PlayerData[client][_hPrim]))
				g_PlayerData[client][_hPrim] = INVALID_HANDLE;

			if(g_PlayerData[client][_hSec] != INVALID_HANDLE && CloseHandle(g_PlayerData[client][_hSec]))
				g_PlayerData[client][_hSec] = INVALID_HANDLE;
		}
	}
	
	ClearAbuseData(client)
	{
		g_AbuseData[client][_iEffect] = EFFECT_NONE;
	}

	Void_SlayPlayer(client)
	{
		new _iEnt = CreateEntityByName("point_hurt");
		if (_iEnt != -1)
		{
			decl String:_sName[64];
			GetEntPropString(client, Prop_Data, "m_iName", _sName, sizeof(_sName));
			DispatchKeyValue(client, "targetname", "StartPlayerSuicide");
			DispatchKeyValue(_iEnt, "DamageTarget", "StartPlayerSuicide");
			DispatchKeyValue(_iEnt, "Damage", "100000");
			DispatchKeyValue(_iEnt, "DamageType", "0");
			DispatchSpawn(_iEnt);

			AcceptEntityInput(_iEnt, "Hurt");
			if(StrEqual(_sName, "", false))
				DispatchKeyValue(client, "targetname", "StopPlayerSuicide");
			else
				DispatchKeyValue(client, "targetname", _sName);
			AcceptEntityInput(_iEnt, "Kill");
		}
	}  
//}

//=--=--=--=--=--=--=--=--=--=--=--=--=

//Gravity Effect
//{
	SetEffectGravity(client, Float:_fTemp)
	{
		if(_fTemp == GRAVITY_DEFAULT_VALUE)
			SetEntityGravity(client, g_PlayerData[client][_fPrim]);

		g_PlayerData[client][_hPrim] = CreateTimer(0.1, Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
	}
//}

//Speed Effect
//{
	SetEffectSpeed(client, Float:_fTemp)
	{
		if(_fTemp == SPEED_DEFAULT_VALUE)
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_PlayerData[client][_fPrim]);
		
		g_PlayerData[client][_hPrim] = CreateTimer(0.1, Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
	}
//}

//Color / Alpha Effect
//{
	SetEffectApperance(client, array[4], effect = -1, mode = -1)
	{
		if(effect >= 0)
			SetEntityRenderFx(client, RenderFx:effect);

		if(mode >= 0)
			SetEntityRenderMode(client, RenderMode:mode);

		SetEntityRenderColor(client, array[0], array[1], array[2], array[3]);
		g_PlayerData[client][_hPrim] = CreateTimer(GetRandomFloat(COLOR_CHANGE_MIN, COLOR_CHANGE_MAX), Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
	}
//}

//Poison Effect
//{
	Void_FastPoison(client)
	{
		g_PlayerData[client][_fPrim] = GetRandomFloat(POISON_FAST_MIN, POISON_FAST_MAX);
		g_PlayerData[client][_fSec] = GetRandomFloat(POISON_FAST_WAIT_MIN, POISON_FAST_WAIT_MAX);

		new _iHealth = GetClientHealth(client), _iFix = RoundToCeil(g_PlayerData[client][_fPrim] * 100.0);
		new _iTemp = RoundToCeil(float(_iHealth) * g_PlayerData[client][_fPrim]);
		if(_iTemp < _iFix)
			_iTemp = _iFix;

		if((_iHealth - _iTemp)  > 0)
		{
			SetEntityHealth(client, (_iHealth - _iTemp));

			decl String:_sBuffer1[32];
			new Handle:_hTemp = StartMessageOne("KeyHintText", client);
			BfWriteByte(_hTemp, 1);
			Format(_sBuffer1, sizeof(_sBuffer1), "%s%t", g_sPrefixKeyHint, "self_health_decrease");
			BfWriteString(_hTemp, _sBuffer1); 
			EndMessage();	
		}
		else if(g_PlayerData[client][_iPrim])
			SetEntityHealth(client, 1);
		else
		{
			Void_SlayPlayer(client);
			return;
		}
		
		g_PlayerData[client][_hPrim] = CreateTimer(g_PlayerData[client][_fSec], Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	Void_SlowPoison(client)
	{
		g_PlayerData[client][_fPrim] = GetRandomFloat(POISON_SLOW_MIN, POISON_SLOW_MAX);
		g_PlayerData[client][_fSec] = GetRandomFloat(POISON_SLOW_WAIT_MIN, POISON_SLOW_WAIT_MAX);

		new _iHealth = GetClientHealth(client), _iFix = RoundToCeil(g_PlayerData[client][_fPrim] * 100.0);
		new _iTemp = RoundToCeil(float(_iHealth) * g_PlayerData[client][_fPrim]);
		if(_iTemp < _iFix)
			_iTemp = _iFix;

		if((_iHealth - _iTemp) > 0)
		{
			SetEntityHealth(client, (_iHealth - _iTemp));

			decl String:_sBuffer1[32];
			new Handle:_hTemp = StartMessageOne("KeyHintText", client);
			BfWriteByte(_hTemp, 1);
			Format(_sBuffer1, sizeof(_sBuffer1), "%s%t", g_sPrefixKeyHint, "self_health_decrease");
			BfWriteString(_hTemp, _sBuffer1); 
			EndMessage();	
		}
		else if(g_PlayerData[client][_iPrim])
			SetEntityHealth(client, 1);
		else
		{
			Void_SlayPlayer(client);
			return;
		}
		
		g_PlayerData[client][_hPrim] = CreateTimer(g_PlayerData[client][_fSec], Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
	}
//}

//Regen Effect
//{
	Void_FastRegen(client)
	{
		g_PlayerData[client][_fPrim] = GetRandomFloat(REGEN_FAST_MIN, REGEN_FAST_MAX);
		g_PlayerData[client][_fSec] = GetRandomFloat(REGEN_FAST_WAIT_MIN, REGEN_FAST_WAIT_MAX);

		new _iHealth = GetClientHealth(client);
		if(_iHealth > 1 && _iHealth < g_PlayerData[client][_iPrim])
		{
			SetEntityHealth(client, (_iHealth + RoundToCeil(float(_iHealth) * g_PlayerData[client][_fPrim])));

			decl String:_sBuffer1[32];
			new Handle:_hTemp = StartMessageOne("KeyHintText", client);
			BfWriteByte(_hTemp, 1);
			Format(_sBuffer1, sizeof(_sBuffer1), "%s%t", g_sPrefixKeyHint, "self_health_increase");
			BfWriteString(_hTemp, _sBuffer1); 
			EndMessage();	
		}

		g_PlayerData[client][_hPrim] = CreateTimer(g_PlayerData[client][_fSec], Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	Void_SlowRegen(client)
	{
		g_PlayerData[client][_fPrim] = GetRandomFloat(REGEN_SLOW_MIN, REGEN_SLOW_MAX);
		g_PlayerData[client][_fSec] = GetRandomFloat(REGEN_SLOW_WAIT_MIN, REGEN_SLOW_WAIT_MAX);

		new _iHealth = GetClientHealth(client);
		if(_iHealth > 1 && _iHealth < g_PlayerData[client][_iPrim])
		{
			SetEntityHealth(client, (_iHealth + RoundToCeil(float(_iHealth) * g_PlayerData[client][_fPrim])));
			
			decl String:_sBuffer1[32];
			new Handle:_hTemp = StartMessageOne("KeyHintText", client);
			BfWriteByte(_hTemp, 1);
			Format(_sBuffer1, sizeof(_sBuffer1), "%s%t", g_sPrefixKeyHint, "self_health_increase");
			BfWriteString(_hTemp, _sBuffer1); 
			EndMessage();	
		}

		g_PlayerData[client][_hPrim] = CreateTimer(g_PlayerData[client][_fSec], Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
	}
//}

//Slap Effects
//{
	Void_HurtingSlap(client)
	{
		g_PlayerData[client][_fPrim] = GetRandomFloat(SLAP_HURT_MIN, SLAP_HURT_MAX);
		g_PlayerData[client][_fSec] = GetRandomFloat(SLAP_HURT_WAIT_MIN, SLAP_HURT_WAIT_MAX);

		new _iHealth = GetClientHealth(client), _iFix = RoundToCeil(g_PlayerData[client][_fPrim] * 100.0);
		new _iTemp = RoundToCeil(float(_iHealth) * g_PlayerData[client][_fPrim]);
		if(_iTemp < _iFix)
			_iTemp = _iFix;

		if((_iHealth - _iTemp) > 0)
		{
			SlapPlayer(client, _iTemp);

			decl String:_sBuffer1[32];
			new Handle:_hTemp = StartMessageOne("KeyHintText", client);
			BfWriteByte(_hTemp, 1);
			Format(_sBuffer1, sizeof(_sBuffer1), "%s%t", g_sPrefixKeyHint, "self_health_decrease");
			BfWriteString(_hTemp, _sBuffer1); 
			EndMessage();
		}
		else if(g_PlayerData[client][_iPrim])
			SlapPlayer(client, 0);
		else
		{
			Void_SlayPlayer(client);
			return;
		}
		
		g_PlayerData[client][_hPrim] = CreateTimer(g_PlayerData[client][_fSec], Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	Void_HealingSlap(client)
	{
		g_PlayerData[client][_fPrim] = GetRandomFloat(SLAP_HEAL_MIN, SLAP_HEAL_MAX);
		g_PlayerData[client][_fSec] = GetRandomFloat(SLAP_HEAL_WAIT_MIN, SLAP_HEAL_WAIT_MAX);

		SlapPlayer(client, 0);
		new _iHealth = GetClientHealth(client);
		new _iTemp = _iHealth + RoundToCeil(float(_iHealth) * g_PlayerData[client][_fPrim]);
		if(_iTemp < SLAP_MAX_HEALTH)
		{
			SetEntityHealth(client, _iTemp);

			decl String:_sBuffer1[32];
			new Handle:_hTemp = StartMessageOne("KeyHintText", client);
			BfWriteByte(_hTemp, 1);
			Format(_sBuffer1, sizeof(_sBuffer1), "%s%t", g_sPrefixKeyHint, "self_health_increase");
			BfWriteString(_hTemp, _sBuffer1); 
			EndMessage();	
		}

		g_PlayerData[client][_hPrim] = CreateTimer(g_PlayerData[client][_fSec], Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
//}

//Jump Effects
//{
	Void_PerformJump(client, effect)
	{
		if(!g_PlayerData[client][_iPrim])
		{
			decl Float:g_fVelocity[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", g_fVelocity);
			if(g_fVelocity[0] > MAX_BHOP_VELOCITY || g_fVelocity[1] > MAX_BHOP_VELOCITY)
			{
				decl String:_sBuffer1[64], String:_sBuffer2[64];
				new Handle:_hTemp = StartMessageOne("KeyHintText", client);
				BfWriteByte(_hTemp, 1);
				Format(_sBuffer1, sizeof(_sBuffer1), "self_velocity_cap_%d", GetDiceTranslation("self_velocity_cap"));
				Format(_sBuffer2, sizeof(_sBuffer2), "%s%t", g_sPrefixKeyHint, _sBuffer1);
				BfWriteString(_hTemp, _sBuffer2); 
				EndMessage();
				return;
			}
			
			switch(effect)
			{
				case EFFECT_HIGH_JUMP:
				{
					g_fVelocity[0] *= HIGH_JUMP_FACTOR_XY;
					g_fVelocity[1] *= HIGH_JUMP_FACTOR_XY;
					g_fVelocity[2] *= HIGH_JUMP_FACTOR_Z;

					if(g_fHighRefresh)
					{
						g_PlayerData[client][_iPrim] = 1;
						g_PlayerData[client][_hSec] = CreateTimer(g_fHighRefresh, Timer_RecoverJump, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				case EFFECT_LONG_JUMP:
				{
					g_fVelocity[0] *= LONG_JUMP_FACTOR_XY;
					g_fVelocity[1] *= LONG_JUMP_FACTOR_XY;
					g_fVelocity[2] *= LONG_JUMP_FACTOR_Z;

					if(g_fLongRefresh)
					{
						g_PlayerData[client][_iPrim] = 1;
						g_PlayerData[client][_hSec] = CreateTimer(g_fLongRefresh, Timer_RecoverJump, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				case EFFECT_SUPER_JUMP:
				{
					g_fVelocity[0] *= SUPER_JUMP_FACTOR_XY;
					g_fVelocity[1] *= SUPER_JUMP_FACTOR_XY;
					g_fVelocity[2] *= SUPER_JUMP_FACTOR_Z;

					if(g_fSuperRefresh)
					{
						g_PlayerData[client][_iPrim] = 1;
						g_PlayerData[client][_hSec] = CreateTimer(g_fSuperRefresh, Timer_RecoverJump, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
					}
				}	
			}
			
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, g_fVelocity);
		}
	}

	public Action:Timer_RecoverJump(Handle:timer, any:userid)
	{
		new client = GetClientOfUserId(userid);
		if(client && IsClientInGame(client))
		{
			if(g_PlayerData[client][_hSec] != INVALID_HANDLE)
				g_PlayerData[client][_hSec] = INVALID_HANDLE;

			if(g_bAlive[client] && IsClientInGame(client))
			{
				g_PlayerData[client][_iPrim] = 0;
				switch(g_PlayerData[client][_iEffect])
				{
					case EFFECT_HIGH_JUMP:
						PrintHintText(client, "Your \"High Jump\" ability has recovered!");
					case EFFECT_LONG_JUMP:
						PrintHintText(client, "Your \"Long Jump\" ability has recovered!");
					case EFFECT_SUPER_JUMP:
						PrintHintText(client, "Your \"Super Jump\" ability has recovered!");
				}
				
				EmitSoundToClient(client, JUMP_REFRESH_SOUND, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_HOME);
				g_PlayerData[client][_hSec] = CreateTimer(1.0, Timer_RemoveHint, userid, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		
		return Plugin_Continue;
	}
	
	public Action:Timer_RemoveHint(Handle:timer, any:userid)
	{
		new client = GetClientOfUserId(userid);
		if(client && IsClientInGame(client))
		{
			if(g_PlayerData[client][_hSec] != INVALID_HANDLE)
				g_PlayerData[client][_hSec] = INVALID_HANDLE;

			if(IsClientInGame(client))
				PrintHintText(client, "");
		}

		return Plugin_Continue;
	}
//}

//Beacon Effects
//{
	Void_PerformTinyBeacon(client)
	{
		decl Float:_fOrigin[3], _iRandom[4];
		GetClientAbsOrigin(client, _fOrigin);

		for(new i = 1; i <= BEACON_TINY_AMOUNT; i++)
		{
			_fOrigin[2] += 7.5;
			for(new j = 0; j < 3; j++)
				_iRandom[j] = GetRandomInt(0, 255);
			_iRandom[3] = 255;
			TE_SetupBeamRingPoint(_fOrigin, BEACON_TINY_MIN_SIZE, BEACON_TINY_MAX_SIZE, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.75, 15.0, 1.0, _iRandom, 15, 0);
			TE_SendToAll();
		}

		GetClientEyePosition(client, _fOrigin);
		EmitAmbientSound(BEACON_SOUND, _fOrigin, client, SNDLEVEL_LIBRARY);

		g_PlayerData[client][_hPrim] = CreateTimer(BEACON_TINY_TIME, Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	Void_PerformLargeBeacon(client)
	{
		decl Float:_fOrigin[3], _iRandom[4];
		GetClientAbsOrigin(client, _fOrigin);

		for(new i = 1; i <= BEACON_LARGE_AMOUNT; i++)
		{
			_fOrigin[2] += 10;
			for(new j = 0; j < 3; j++)
				_iRandom[j] = GetRandomInt(0, 255);
			_iRandom[3] = 255;
			TE_SetupBeamRingPoint(_fOrigin, BEACON_LARGE_MIN_SIZE, BEACON_LARGE_MAX_SIZE, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.75, 15.0, 1.0, _iRandom, 15, 0);
			TE_SendToAll();
		}

		GetClientEyePosition(client, _fOrigin);
		EmitAmbientSound(BEACON_SOUND, _fOrigin, client, SNDLEVEL_LIBRARY);

		g_PlayerData[client][_hPrim] = CreateTimer(BEACON_LARGE_TIME, Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
	}
//}
	
//Random Burning
//{

//}

//Screen Effects
//{
	//Drug	
	Void_PerformDrug(client, bool:doRemove = false)
	{
		decl Float:_fAng[3];
		GetClientEyeAngles(client, _fAng);

		if(doRemove)
		{
			_fAng[2] = 0.0;
			Void_ResetScreen(client);
		}
		else
		{
			_fAng[2] = g_fEffectDrug[GetRandomInt(0, 100) % 20];
			
			g_PlayerData[client][_fPrim] = GetRandomFloat(DRUG_MIN_TIME, DRUG_MAX_TIME);
			g_PlayerData[client][_hPrim] = CreateTimer(g_PlayerData[client][_fPrim], Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
		}

		TeleportEntity(client, NULL_VECTOR, _fAng, NULL_VECTOR);
	}

	//Blind
	Void_PerformBlind(client, bool:doTimer = false, bool:doRemove = false)
	{
		new clients[2];
		clients[0] = client;

		new Handle:_hMsg = StartMessageEx(g_uFadeUserMsg, clients, 1);
		BfWriteShort(_hMsg, 1536);
		BfWriteShort(_hMsg, 1536);
		if(doRemove)
			BfWriteShort(_hMsg, (0x0001 | 0x0010));
		else
			BfWriteShort(_hMsg, (0x0002 | 0x0008));
		BfWriteByte(_hMsg, 0);
		BfWriteByte(_hMsg, 0);
		BfWriteByte(_hMsg, 0);
		if(doRemove)
			BfWriteByte(_hMsg, 0);
		else
		{
			if(GetRandomInt(0, 1))
				BfWriteByte(_hMsg, _iEffectBlindStatic[GetRandomInt(0, (BLIND_COUNT - 1))]);
			else
				BfWriteByte(_hMsg, GetRandomInt(BLIND_LOWEST, BLIND_HIGEHST));
		}
		EndMessage();
		
		if(doTimer && !doRemove)
		{
			g_PlayerData[client][_fPrim] = GetRandomFloat(BLIND_MIN_TIME, BLIND_MAX_TIME);
			g_PlayerData[client][_hPrim] = CreateTimer(g_PlayerData[client][_fPrim], Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	//Invert
	Void_PerformInvert(client, bool:doRemove = false)
	{
		decl Float:_fAng[3];
		GetClientEyeAngles(client, _fAng);

		if(doRemove)
		{
			_fAng[2] = 0.0;
			Void_ResetScreen(client);
		}
		else
		{
			_fAng[2] = 180.0;
			g_PlayerData[client][_hPrim] = CreateTimer(0.1, Timer_PerformEffect, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		TeleportEntity(client, NULL_VECTOR, _fAng, NULL_VECTOR);
	}

	//General
	Void_ResetScreen(client)
	{
		ClientCommand(client, "r_screenoverlay 0");
	}
//}