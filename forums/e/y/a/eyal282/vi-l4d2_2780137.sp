#include <left4dhooks>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "2.0"

#define ZOMBIECLASS_SMOKER  1
#define ZOMBIECLASS_BOOMER  2
#define ZOMBIECLASS_HUNTER  3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY  5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_TANK    8

bool isBoomer         = false;
bool isBileFeet       = false;
bool isBileMask       = false;
bool isBileMaskTilDry = false;
bool isBileShower     = false;
bool isBileShowerTimeout;
bool isBileSwipe = false;

Handle cvarBoomer;
Handle cvarBileFeet;
Handle cvarBileFeetSpeed;
Handle cvarBileFeetTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
Handle cvarBileMask;
Handle cvarBileMaskState;
Handle cvarBileMaskAmount;
Handle cvarBileMaskDuration;
Handle cvarBileMaskTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
Handle cvarBileShower;
Handle cvarBileShowerTimeout;
Handle cvarBileShowerTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
Handle cvarBileSwipe;
Handle cvarBileSwipeChance;
Handle cvarBileSwipeDuration;
Handle cvarBileSwipeTimer[MAXPLAYERS + 1] = INVALID_HANDLE;

int bileswipe[MAXPLAYERS + 1];

bool isCharger                 = false;
bool isBrokenRibs              = false;
bool isStowaway                = false;
bool isSnappedLeg              = false;
bool isCarried[MAXPLAYERS + 1] = false;

Handle cvarCharger;
Handle cvarBrokenRibs;
Handle cvarBrokenRibsChance;
Handle cvarBrokenRibsDuration;
Handle cvarBrokenRibsTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
Handle cvarSnappedLeg;
Handle cvarSnappedLegChance;
Handle cvarSnappedLegDuration;
Handle cvarSnappedLegTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
Handle cvarSnappedLegSpeed;
Handle cvarStowaway;
Handle cvarStowawayDamage;
Handle cvarStowawayTimer[MAXPLAYERS + 1]       = INVALID_HANDLE;
Handle cvarStowawayDamageTimer[MAXPLAYERS + 1] = INVALID_HANDLE;

int brokenribs[MAXPLAYERS + 1];
int stowaway[MAXPLAYERS + 1];

bool isJockey       = false;
bool isBacterial    = false;
bool isDerbyDaze    = false;
bool isGhostStalker = false;

Handle cvarJockey;
Handle cvarBacterial;
Handle cvarBacterialChance;
Handle cvarBacterialDuration;
Handle cvarBacterialTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
Handle cvarDerbyDaze;
Handle cvarDerbyDazeAmount;
Handle cvarGhostStalker;
Handle cvarGhostStalkerChance;

int bacterial[MAXPLAYERS + 1];

bool isHunter      = false;
bool isCobraStrike = false;
bool isDeepWounds  = false;

Handle cvarHunter;
Handle cvarCobraStrike;
Handle cvarCobraStrikeChance;
int    cvarCobraStrikeCount = 3;
Handle cvarDeepWounds;
Handle cvarDeepWoundsChance;
Handle cvarDeepWoundsDuration;
Handle cvarDeepWoundsTimer[MAXPLAYERS + 1] = INVALID_HANDLE;

int deepwounds[MAXPLAYERS + 1];

bool isSmoker        = false;
bool isCollapsedLung = false;
bool isMoonWalk      = false;

bool moonwalk[MAXPLAYERS + 1];

Handle cvarSmoker;
Handle cvarCollapsedLung;
Handle cvarCollapsedLungChance;
Handle cvarCollapsedLungDuration;
Handle cvarCollapsedLungTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
Handle cvarMoonWalk;
Handle cvarMoonWalkSpeed;
Handle cvarMoonWalkStretch;
Handle MoonWalkTimer[MAXPLAYERS + 1] = INVALID_HANDLE;

int collapsedlung[MAXPLAYERS + 1];

bool isSpitter        = false;
bool isAcidSwipe      = false;
bool isStickyGoo      = false;
bool isSupergirl      = false;
bool isSupergirlSpeed = false;

Handle cvarSpitter;
Handle cvarAcidSwipe;
Handle cvarAcidSwipeChance;
Handle cvarAcidSwipeDuration;
Handle cvarAcidSwipeTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
Handle cvarStickyGoo;
Handle cvarStickyGooDuration;
Handle cvarStickyGooSpeed;
Handle cvarStickyGooJump;
Handle cvarStickyGooTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
Handle cvarSupergirl;
Handle cvarSupergirlSpeed;
Handle cvarSupergirlDuration;
Handle cvarSupergirlSpeedDuration;
Handle cvarSupergirlTimer[MAXPLAYERS + 1]      = INVALID_HANDLE;
Handle cvarSupergirlSpeedTimer[MAXPLAYERS + 1] = INVALID_HANDLE;

int acidswipe[MAXPLAYERS + 1];

bool isTank                       = false;
bool isBurningRage                = false;
bool isCullingSwarm               = false;
bool isMourningWidow              = false;
bool isWorriedWife                = false;
bool isTankOnFire[MAXPLAYERS + 1] = false;
bool isFrustrated                 = false;

Handle cvarTank;
Handle cvarBurningRage;
Handle cvarBurningRageSpeed;
Handle BurningRageTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
Handle cvarCullingSwarm;
Handle cvarMourningWidow;
Handle cvarWorriedWife;

bool isWitch        = false;
bool isMoodSwing    = false;
bool isSupportGroup = false;

Handle cvarWitch;
Handle cvarMoodSwing;
Handle cvarMoodSwingMin;
Handle cvarMoodSwingMax;
Handle cvarSupportGroup;

int  velocityModifierOffset   = 0;
int  JUMPFLAG                 = IN_JUMP;
bool isEnabled                = false;
bool isAnnounce               = false;
bool isSlowed[MAXPLAYERS + 1] = false;

Handle PluginStartTimer = INVALID_HANDLE;
Handle cvarEnabled;
Handle cvarAnnounce;

Handle cvarTankMax;
Handle cvarTankMaxMap;
Handle cvarWitchMax;
Handle cvarWitchMaxMap;

int WitchActive;
int WitchSpawned;
int WitchMax;
int WitchMaxMap;
int TankActive;
int TankSpawned;
int TankMax;
int TankMaxMap;

UserMsg DerbyDazeMsgID;

public Plugin myinfo =
{
	name        = "[L4D2] Vicious Infected",
	author      = "Mortiegama ==> cravenge ==> Eyal282",
	description = "Provides int Abilities To Special Infected.",
	version     = PLUGIN_VERSION,
	url         = "http://forums.alliedmods.net/showthread.php?t=119891"
};

public void OnPluginStart()
{
	CreateConVar("vi-l4d2_version", PLUGIN_VERSION, "Vicious Infected Version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);

	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_now_it", OnPlayerNowIt);
	HookEvent("player_no_longer_it", OnPlayerNoLongerIt);

	cvarBoomer            = CreateConVar("vi-l4d2_boomer", "1", "Enable/Disable Boomer's Abilities", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarBileFeet          = CreateConVar("vi-l4d2_bilefeet", "1", "Enable/Disable Bile Feet Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarBileFeetSpeed     = CreateConVar("vi-l4d2_bilefeetspeed", "1.5", "Speed Multiplied By Bile Feet Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarBileMask          = CreateConVar("vi-l4d2_bilemask", "1", "Enable/Disable Bile Mask Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarBileMaskState     = CreateConVar("vi-l4d2_bilemaskstate", "1", "Bile Mask Ability State: 0=ConVar Based, 1=Until Fully Dried", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarBileMaskAmount    = CreateConVar("vi-l4d2_bilemaskamount", "200", "Amount Of Visibility Reduced By Bile Mask Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarBileMaskDuration  = CreateConVar("vi-l4d2_bilemaskduration", "-1.0", "Duration Of Bile Mask Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarBileShower        = CreateConVar("vi-l4d2_bileshower", "1", "Enable/Disable Bile Shower Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarBileShowerTimeout = CreateConVar("vi-l4d2_bileshowertimeout", "10.0", "Delay Before Bile Shower Ability Kicks In Again", FCVAR_NOTIFY, true, 1.0, false, _);
	cvarBileSwipe         = CreateConVar("vi-l4d2_bileswipe", "1", "Enable/Disable Bile Swipe Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarBileSwipeChance   = CreateConVar("vi-l4d2_bileswipechance", "100", "Chance Of Bile Swipe Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarBileSwipeDuration = CreateConVar("vi-l4d2_bileswipeduration", "10.0", "Duration Of Bile Swipe Ability", FCVAR_NOTIFY, true, 1.0, false, _);
	CreateConVar("vi-l4d2_bileswipedamage", "3", "Damage Inflicted By Bile Swipe Ability", FCVAR_NOTIFY, true, 0.0, false, _);

	HookEvent("charger_pummel_end", OnChargerPummelEnd);
	HookEvent("charger_impact", OnChargerImpact);
	HookEvent("charger_carry_start", OnChargerCarryStart);
	HookEvent("charger_carry_end", OnChargerCarryEnd);

	cvarCharger            = CreateConVar("vi-l4d2_charger", "1", "Enable/Disable Charger's Abilities", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarBrokenRibs         = CreateConVar("vi-l4d2_brokenribs", "1", "Enable/Disable Broken Ribs Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarBrokenRibsChance   = CreateConVar("vi-l4d2_brokenribschance", "100", "Chance Of Broken Ribs Ability To Be Applied", FCVAR_NOTIFY, true, 1.0, false, _);
	cvarBrokenRibsDuration = CreateConVar("vi-l4d2_brokenribsduration", "10.0", "Duration Of Broken Ribs Ability", FCVAR_NOTIFY, true, 1.0, false, _);
	CreateConVar("vi-l4d2_brokenribsdamage", "5", "Damage Inflicted By Broken Ribs Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarSnappedLeg         = CreateConVar("vi-l4d2_snappedleg", "1", "Enable/Disable Snapped Leg Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarSnappedLegChance   = CreateConVar("vi-l4d2_snappedlegchance", "100", "Chance Of Snapped Leg Ability To Be Applied", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarSnappedLegDuration = CreateConVar("vi-l4d2_snappedlegduration", "10.0", "Duration Of Snapped Leg Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarSnappedLegSpeed    = CreateConVar("vi-l4d2_snappedlegspeed", "0.5", "Speed Reduced By Snapped Leg Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarStowaway           = CreateConVar("vi-l4d2_stowaway", "1", "Enable/Disable Stowaway Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarStowawayDamage     = CreateConVar("vi-l4d2_stowawaydamage", "10", "Damage Inflicted By Stowaway Ability", FCVAR_NOTIFY, true, 0.0, false, _);

	HookEvent("jockey_ride", OnJockeyRide);
	HookEvent("jockey_ride_end", OnJockeyRideEnd);

	cvarJockey            = CreateConVar("vi-l4d2_jockey", "1", "Enable/Disable Jockey's Abilities", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarBacterial         = CreateConVar("vi-l4d2_bacterialinfection", "1", "Enable/Disable Bacterial Infection Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarBacterialChance   = CreateConVar("vi-l4d2_bacterialinfectionchance", "100", "Chance Of Bacterial Infection To Be Applied", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarBacterialDuration = CreateConVar("vi-l4d2_bacterialduration", "10.0", "Duration Of Bacterial Infection Ability", FCVAR_NOTIFY, true, 1.0, false, _);
	CreateConVar("vi-l4d2_bacterialdamage", "1", "Damage Inflicted By Bacterial Infection Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarDerbyDaze          = CreateConVar("vi-l4d2_derbydaze", "1", "Enable/Disable Derby Daze Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarDerbyDazeAmount    = CreateConVar("vi-l4d2_derbydazeamount", "200", "Amount Of Visibility Reduced By Derby Daze Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarGhostStalker       = CreateConVar("vi-l4d2_ghoststalker", "0", "When damaged, Jockey has a chance to returning to Ghost mode unless riding. (Def 0)", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarGhostStalkerChance = CreateConVar("vi-l4d2_ghoststalkerchance", "5", "Chance that the Jockey will return to Ghost mode (5 = 5%). (Def 5)", FCVAR_NOTIFY, true, 0.0, false, _);

	HookEvent("lunge_pounce", OnLungePounce, EventHookMode_Pre);
	HookEvent("pounce_end", OnPounceEnd);

	cvarHunter            = CreateConVar("vi-l4d2_hunter", "1", "Enable/Disable Hunter's Abilities", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarCobraStrike       = CreateConVar("vi-l4d2_cobrastrike", "0", "Enable/Disable Cobra Strike Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarCobraStrikeChance = CreateConVar("vi-l4d2_cobrastrikechance", "25", "Chance Of Cobra Strike Ability To Be Applied", FCVAR_NOTIFY, true, 0.0, false, _);
	CreateConVar("vi-l4d2_cobrastrikedamage", "200", "Damage Inflicted By Cobra Strike Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarDeepWounds         = CreateConVar("vi-l4d2_deepwounds", "1", "Enable/Disable Deep Wounds Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarDeepWoundsChance   = CreateConVar("vi-l4d2_deepwoundschance", "100", "Chance Of Deep Wounds Ability To Be Applied", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarDeepWoundsDuration = CreateConVar("vi-l4d2_deepwoundsduration", "10.0", "Duration Of Deep Wounds Ability", FCVAR_NOTIFY, true, 1.0, false, _);
	CreateConVar("vi-l4d2_deepwoundsdamage", "5", "Damage Inflicted By Deep Wounds Ability", FCVAR_NOTIFY, true, 0.0, false, _);

	HookEvent("choke_end", OnChokeEnd);
	HookEvent("tongue_grab", OnTongueGrab);
	HookEvent("tongue_release", OnTongueRelease, EventHookMode_Pre);

	cvarSmoker                = CreateConVar("vi-l4d2_smoker", "1", "Enable/Disable Smoker's Abilities", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarCollapsedLung         = CreateConVar("vi-l4d2_collapsedlung", "1", "Enable/Disable Collapsed Lung Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarCollapsedLungChance   = CreateConVar("vi-l4d2_collapsedlungchance", "100", "Chance Of Collapsed Lung Ability To Be Applied", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarCollapsedLungDuration = CreateConVar("vi-l4d2_collapsedlungduration", "10.0", "Duration Of Collapsed Lung Ability", FCVAR_NOTIFY, true, 1.0, false, _);
	CreateConVar("vi-l4d2_collapsedlungdamage", "2", "Damage Inflicted By Collapsed Lung Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarMoonWalk        = CreateConVar("vi-l4d2_moonwalk", "1", "Enable/Disable Moonwalk Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarMoonWalkSpeed   = CreateConVar("vi-l4d2_moonwalkspeed", "0.5", "Speed Multiplied By Moonwalk Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarMoonWalkStretch = CreateConVar("vi-l4d2_moonwalkstretch", "2500", "Stretching Range Covered By Moonwalk Ability", FCVAR_NOTIFY, true, 0.0, false, _);

	HookEvent("entered_spit", OnEnteredSpit);
	HookEvent("spit_burst", OnSpitBurst);

	cvarSpitter           = CreateConVar("vi-l4d2_spitter", "1", "Enable/Disable Spitter's Abilities", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarAcidSwipe         = CreateConVar("vi-l4d2_acidswipe", "1", "Enable/Disable Acid Swipe Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarAcidSwipeChance   = CreateConVar("vi-l4d2_acidswipechance", "100", "Chance Of Acid Swipe Ability To Be Applied", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarAcidSwipeDuration = CreateConVar("vi-l4d2_acidswipeduration", "10.0", "Duration Of Acid Swipe Ability", FCVAR_NOTIFY, true, 1.0, false, _);
	CreateConVar("vi-l4d2_acidswipedamage", "3", "Damage Inflicted By Acid Swipe Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarStickyGoo              = CreateConVar("vi-l4d2_stickygoo", "1", "Enable/Disable Sticky Goo Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarStickyGooDuration      = CreateConVar("vi-l4d2_stickygooduration", "10.0", "Duration Of Sticky Goo Duration", FCVAR_NOTIFY, true, 1.0, false, _);
	cvarStickyGooSpeed         = CreateConVar("vi-l4d2_stickygoospeed", "0.5", "Speed Reduced By Sticky Goo Jump Reduction Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarStickyGooJump          = CreateConVar("vi-l4d2_stickygoojump", "1", "Enable/Disable Sticky Goo Jump Reduction Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarSupergirl              = CreateConVar("vi-l4d2_supergirl", "1", "Enable/Disable Super Girl Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarSupergirlSpeed         = CreateConVar("vi-l4d2_supergirlspeed", "1", "Enable/Disable Super Girl Speed Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarSupergirlDuration      = CreateConVar("vi-l4d2_supergirlduration", "5.0", "Duration Of Super Girl Ability", FCVAR_NOTIFY, true, 1.0, false, _);
	cvarSupergirlSpeedDuration = CreateConVar("vi-l4d2_supergirlspeedduration", "5.0", "Duration Of Super Girl Speed Ability", FCVAR_NOTIFY, true, 1.0, false, _);

	HookEvent("tank_spawn", OnTankSpawned);
	HookEvent("player_death", OnTankKilled);
	HookEvent("tank_frustrated", OnTankFrustrated, EventHookMode_Pre);

	cvarTank             = CreateConVar("vi-l4d2_tank", "1", "Enable/Disable Tank's Abilities", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarTankMax          = CreateConVar("vi-l4d2_tankmax", "6", "Maximum Number Of Tanks Spawned By Plugin", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarTankMaxMap       = CreateConVar("vi-l4d2_tankmaxmap", "12", "Maximum Number Of Tanks Allowed To Spawn", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarBurningRage      = CreateConVar("vi-l4d2_burningrage", "1", "Enable/Disable Burning Rage Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarBurningRageSpeed = CreateConVar("vi-l4d2_burningragespeed", "1.50", "Speed Multiplied By Burning Rage Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarCullingSwarm     = CreateConVar("vi-l4d2_cullingswarm", "1", "Enable/Disable Culling Swarm Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarMourningWidow    = CreateConVar("vi-l4d2_mourningwidow", "0", "Enable/Disable Mourning Widow Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarWorriedWife      = CreateConVar("vi-l4d2_worriedwife", "0", "Enable/Disable Worried Wife Ability", FCVAR_NOTIFY, true, 0.0, false, _);

	HookEvent("witch_spawn", OnWitchSpawned);
	HookEvent("witch_killed", OnWitchKilled);
	HookEvent("witch_harasser_set", OnWitchHarasserSet);

	cvarWitch        = CreateConVar("vi-l4d2_witch", "1", "Enable/Disable Witch's Abilities", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarMoodSwing    = CreateConVar("vi-l4d2_moodswing", "1", "Enable/Disable Mood Swing Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarMoodSwingMin = CreateConVar("vi-l4d2_moodswingmin", "1500", "Minimum HP For Mood Swing Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarMoodSwingMax = CreateConVar("vi-l4d2_moodswingmax", "2000", "Maximum HP For Mood Swing Ability", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarWitchMax     = CreateConVar("vi-l4d2_witchmax", "4", "Maximum Number Of Witches Spawned By Plugin", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarWitchMaxMap  = CreateConVar("vi-l4d2_witchmaxmap", "8", "Maximum Number Of Witches Allowed To Spawn", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarSupportGroup = CreateConVar("vi-l4d2_supportgroup", "1", "Enable/Disable Support Group Ability", FCVAR_NOTIFY, true, 0.0, false, _);

	HookEvent("player_incapacitated", OnPlayerIncapped);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
	HookEvent("player_team", OnPlayerTeam);
	HookEvent("round_start", OnRoundReset);
	HookEvent("finale_win", OnRoundReset);
	HookEvent("map_transition", OnRoundReset);
	HookEvent("mission_lost", OnRoundReset);
	HookEvent("round_end", OnRoundReset);

	cvarEnabled  = CreateConVar("vi-l4d2_enable", "1", "Enable/Disable Plugin");
	cvarAnnounce = CreateConVar("vi-l4d2_announce", "1", "Enable/Disable Announcements");

	velocityModifierOffset = FindSendPropInfo("CTerrorPlayer", "m_flVelocityModifier");

	AutoExecConfig(true, "vi-l4d2");
	if (PluginStartTimer == INVALID_HANDLE)
	{
		PluginStartTimer = CreateTimer(3.0, OnPluginStart_Delayed);
	}

	if (GetConVarInt(cvarEnabled))
	{
		isEnabled = true;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		Func_OnClientPutInServer(i);
	}
}

public Action OnPluginStart_Delayed(Handle timer)
{
	if (isEnabled)
	{
		if (GetConVarInt(cvarBoomer))
		{
			isBoomer = true;
			if (GetConVarInt(cvarBileFeet))
			{
				isBileFeet = true;
			}

			if (GetConVarInt(cvarBileMask))
			{
				isBileMask = true;
			}

			if (GetConVarInt(cvarBileMaskState))
			{
				isBileMaskTilDry = true;
			}

			if (GetConVarInt(cvarBileShower))
			{
				isBileShower = true;
			}

			if (GetConVarInt(cvarBileSwipe))
			{
				isBileSwipe = true;
			}
		}

		if (GetConVarInt(cvarCharger))
		{
			isCharger = true;
			if (GetConVarInt(cvarBrokenRibs))
			{
				isBrokenRibs = true;
			}

			if (GetConVarInt(cvarSnappedLeg))
			{
				isSnappedLeg = true;
			}

			if (GetConVarInt(cvarStowaway))
			{
				isStowaway = true;
			}
		}

		if (GetConVarInt(cvarJockey))
		{
			isJockey = true;
			if (GetConVarInt(cvarBacterial))
			{
				isBacterial = true;
			}

			if (GetConVarInt(cvarDerbyDaze))
			{
				isDerbyDaze = true;
			}

			if (GetConVarInt(cvarGhostStalker))
			{
				isGhostStalker = true;
			}
		}

		if (GetConVarInt(cvarHunter))
		{
			isHunter = true;
			if (GetConVarInt(cvarCobraStrike))
			{
				isCobraStrike = true;
			}

			if (GetConVarInt(cvarDeepWounds))
			{
				isDeepWounds = true;
			}
		}

		if (GetConVarInt(cvarSmoker))
		{
			isSmoker = true;
			if (GetConVarInt(cvarCollapsedLung))
			{
				isCollapsedLung = true;
			}

			if (GetConVarInt(cvarMoonWalk))
			{
				isMoonWalk = true;
			}
		}

		if (GetConVarInt(cvarSpitter))
		{
			isSpitter = true;
			if (GetConVarInt(cvarAcidSwipe))
			{
				isAcidSwipe = true;
			}

			if (GetConVarInt(cvarStickyGoo))
			{
				isStickyGoo = true;
			}

			if (GetConVarInt(cvarSupergirl))
			{
				isSupergirl = true;
			}

			if (GetConVarInt(cvarSupergirlSpeed))
			{
				isSupergirlSpeed = true;
			}
		}

		if (GetConVarInt(cvarTank))
		{
			isTank = true;
			if (GetConVarInt(cvarBurningRage))
			{
				isBurningRage = true;
			}

			if (GetConVarInt(cvarCullingSwarm))
			{
				isCullingSwarm = true;
			}

			if (GetConVarInt(cvarMourningWidow))
			{
				isMourningWidow = true;
			}

			if (GetConVarInt(cvarWorriedWife))
			{
				isWorriedWife = true;
			}
		}

		if (GetConVarInt(cvarWitch))
		{
			isWitch = true;
			if (GetConVarInt(cvarMoodSwing))
			{
				isMoodSwing = true;
			}

			if (GetConVarInt(cvarSupportGroup))
			{
				isSupportGroup = true;
			}
		}

		if (GetConVarInt(cvarAnnounce))
		{
			isAnnounce = true;
		}

		TankMax     = GetConVarInt(cvarTankMax);
		TankMaxMap  = GetConVarInt(cvarTankMaxMap);
		WitchMax    = GetConVarInt(cvarWitchMax);
		WitchMaxMap = GetConVarInt(cvarWitchMaxMap);
		MoodSwingSet();

		if (PluginStartTimer != INVALID_HANDLE)
		{
			KillTimer(PluginStartTimer);
			PluginStartTimer = INVALID_HANDLE;
		}
	}

	return Plugin_Stop;
}

public void OnMapStart()
{
	PrecacheModel("models/infected/witch.mdl", true);
	PrecacheModel("models/infected/witch_bride.mdl", true);

	char GameMode[16];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
	if (StrEqual(GameMode, "survival", false))
	{
		isCullingSwarm = false;
	}
}

public void OnClientPutInServer(int client)
{
	Func_OnClientPutInServer(client);
}

public void Func_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (class == ZOMBIECLASS_BOOMER)
		{
			if (isBoomer && isBileFeet)
			{
				if (cvarBileFeetTimer[client] == INVALID_HANDLE)
				{
					cvarBileFeetTimer[client] = CreateTimer(0.5, OnBoomerBileFeet, client);
				}
			}
		}
	}
}

public void OnGameFrame()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && GetClientTeam(client) == 2 && isSlowed[client])
		{
			int flags = GetEntityFlags(client);
			if (flags & JUMPFLAG)
			{
				SetEntDataFloat(client, velocityModifierOffset, GetConVarFloat(cvarStickyGooJump), true);
			}
		}
	}
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (IsValidTank(victim))
	{
		if (isBurningRage)
		{
			if ((damagetype == 8 || damagetype == 2056 || damagetype == 268435464))
			{
				if (BurningRageTimer[victim] == INVALID_HANDLE)
				{
					BurningRageTimer[victim] = CreateTimer(0.5, Timer_BurningRage, victim, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
				}
				SDKUnhook(victim, SDKHook_OnTakeDamage, OnTakeDamage);

				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

public Action OnPlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	char weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	if (isSpitter && isAcidSwipe)
	{
		if (IsValidClient(client) && GetClientTeam(client) == 2 && StrEqual(weapon, "spitter_claw"))
		{
			int AcidSwipeChance  = GetRandomInt(0, 99);
			int AcidSwipePercent = GetConVarInt(cvarAcidSwipeChance);
			if (AcidSwipeChance < AcidSwipePercent)
			{
				if (isAnnounce)
				{
					PrintHintText(client, "You're Coated With Spit Acid!");
				}

				if (acidswipe[client] <= 0)
				{
					acidswipe[client] = GetConVarInt(cvarAcidSwipeDuration);
					if (cvarAcidSwipeTimer[client] == INVALID_HANDLE)
					{
						cvarAcidSwipeTimer[client] = CreateTimer(1.0, Timer_AcidSwipe, client, TIMER_REPEAT);
					}
				}
			}
		}
	}

	if (isBoomer && isBileSwipe)
	{
		if (IsValidClient(client) && GetClientTeam(client) == 2 && StrEqual(weapon, "boomer_claw"))
		{
			int BileSwipeChance  = GetRandomInt(0, 99);
			int BileSwipePercent = GetConVarInt(cvarBileSwipeChance);
			if (BileSwipeChance < BileSwipePercent)
			{
				if (isAnnounce)
				{
					PrintHintText(client, "You're Coated With Bile Acid!");
				}

				if (bileswipe[client] <= 0)
				{
					bileswipe[client] = GetConVarInt(cvarBileSwipeDuration);
					if (cvarBileSwipeTimer[client] == INVALID_HANDLE)
					{
						cvarBileSwipeTimer[client] = CreateTimer(1.0, Timer_BileSwipe, client, TIMER_REPEAT);
					}
				}
			}
		}
	}

	// This is the Hook for Ghost Stalker - Chance that when taking damage Jockey will return to Ghost mode

	if (isJockey && isGhostStalker)
	{
		L4D2ZombieClassType class = view_as<L4D2ZombieClassType>(GetEntProp(client, Prop_Send, "m_zombieClass"));

		if (class == L4D2ZombieClass_Jockey && L4D_GetVictimJockey(client) == 0)
		{
			int GhostStalkerChance  = GetRandomInt(0, 99);
			int GhostStalkerPercent = (GetConVarInt(cvarGhostStalkerChance));

			if (IsValidClient(client) && !IsPlayerGhost(client) && (GhostStalkerChance < GhostStalkerPercent))
			{
				int health = GetEventInt(event, "health");

				if (health <= 0)
					health = 1;

				// Prevents infinite health if you ghost stalk from death.
				L4D_SetClass(client, view_as<int>(L4D2ZombieClass_Charger));
				L4D_State_Transition(client, STATE_GHOST);

				L4D_SetClass(client, view_as<int>(L4D2ZombieClass_Jockey));

				SetEntityHealth(client, health);
			}
		}
	}
}

public Action OnBoomerBileFeet(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		if (isAnnounce)
		{
			PrintHintText(client, "Your Movement Speed Improved By Bile Feet Ability!");
		}
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0 * GetConVarFloat(cvarBileFeetSpeed));
		SetConVarFloat(FindConVar("z_vomit_fatigue"), 0.0, false, false);
	}

	if (cvarBileFeetTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarBileFeetTimer[client]);
		cvarBileFeetTimer[client] = INVALID_HANDLE;
	}

	return Plugin_Stop;
}

public Action OnPlayerNoLongerIt(Handle event, const char[] name, bool dontBroadcast)
{
	if (isBoomer && isBileMask)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (IsValidClient(client))
		{
			SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
		}
	}
}

public Action Timer_BileMask(Handle timer, any client)
{
	if (isBoomer && isBileMask)
	{
		if (IsValidClient(client))
		{
			SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
		}
	}

	if (cvarBileMaskTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarBileMaskTimer[client]);
		cvarBileMaskTimer[client] = INVALID_HANDLE;
	}

	return Plugin_Stop;
}

public Action OnPlayerNowIt(Handle event, const char[] name, bool dontBroadcast)
{
	if (isBoomer)
	{
		if (isBileShower && !isBileShowerTimeout)
		{
			int client = GetClientOfUserId(GetEventInt(event, "attacker"));
			if (!IsValidClient2(client))
			{
				return;
			}
			isBileShowerTimeout = true;
			if (cvarBileShowerTimer[client] == INVALID_HANDLE)
			{
				cvarBileShowerTimer[client] = CreateTimer(GetConVarFloat(cvarBileShowerTimeout), BileShowerTimeout, client);
			}
			int flags = GetCommandFlags("z_spawn_old");
			SetCommandFlags("z_spawn_old", flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "z_spawn_old mob auto");
			SetCommandFlags("z_spawn_old", flags | FCVAR_CHEAT);
		}

		if (isBileMask)
		{
			int client = GetClientOfUserId(GetEventInt(event, "userid"));
			if (IsValidClient(client))
			{
				SetEntProp(client, Prop_Send, "m_iHideHUD", GetConVarInt(cvarBileMaskAmount));
				if (!isBileMaskTilDry && cvarBileMaskTimer[client] == INVALID_HANDLE)
				{
					cvarBileMaskTimer[client] = CreateTimer(GetConVarFloat(cvarBileMaskDuration), Timer_BileMask, client);
				}
			}
		}
	}
}

public Action BileShowerTimeout(Handle timer, any client)
{
	isBileShowerTimeout = false;

	if (cvarBileShowerTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarBileShowerTimer[client]);
		cvarBileShowerTimer[client] = INVALID_HANDLE;
	}

	return Plugin_Stop;
}

public Action Timer_BileSwipe(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		if (bileswipe[client] <= 0)
		{
			if (cvarBileSwipeTimer[client] != INVALID_HANDLE)
			{
				KillTimer(cvarBileSwipeTimer[client]);
				cvarBileSwipeTimer[client] = INVALID_HANDLE;
			}

			return Plugin_Stop;
		}

		Damage_BileSwipe(client);

		if (bileswipe[client] > 0)
		{
			bileswipe[client] -= 1;
		}
	}

	return Plugin_Continue;
}

public Action Damage_BileSwipe(int client)
{
	char dmg_str[10];
	char dmg_type_str[10];
	IntToString((1 << 25), dmg_str, sizeof(dmg_type_str));
	GetConVarString(FindConVar("vi-l4d2_bileswipedamage"), dmg_str, sizeof(dmg_str));
	int pointHurt = CreateEntityByName("point_hurt");
	DispatchKeyValue(client, "targetname", "war3_hurtme");
	DispatchKeyValue(pointHurt, "DamageTarget", "war3_hurtme");
	DispatchKeyValue(pointHurt, "Damage", dmg_str);
	DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt, "Hurt", client);
	DispatchKeyValue(client, "targetname", "war3_donthurtme");
	RemoveEdict(pointHurt);
}

public Action OnChargerPummelEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if (isCharger && isBrokenRibs)
	{
		int client = GetClientOfUserId(GetEventInt(event, "victim"));
		if (IsValidClient(client) && GetClientTeam(client) == 2)
		{
			int BrokenRibsChance  = GetRandomInt(0, 99);
			int BrokenRibsPercent = GetConVarInt(cvarBrokenRibsChance);
			if (BrokenRibsChance < BrokenRibsPercent)
			{
				if (isAnnounce)
				{
					PrintHintText(client, "Charger Broke Your Ribs!");
				}

				if (brokenribs[client] <= 0)
				{
					brokenribs[client] = GetConVarInt(cvarBrokenRibsDuration);
					if (cvarBrokenRibsTimer[client] == INVALID_HANDLE)
					{
						cvarBrokenRibsTimer[client] = CreateTimer(1.0, Timer_BrokenRibs, client, TIMER_REPEAT);
					}
				}
			}
		}
	}
}

public Action Timer_BrokenRibs(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		if (brokenribs[client] <= 0)
		{
			if (cvarBrokenRibsTimer[client] != INVALID_HANDLE)
			{
				KillTimer(cvarBrokenRibsTimer[client]);
				cvarBrokenRibsTimer[client] = INVALID_HANDLE;
			}

			return Plugin_Stop;
		}

		Damage_BrokenRibs(client);

		if (brokenribs[client] > 0)
		{
			brokenribs[client] -= 1;
		}
	}

	return Plugin_Continue;
}

public Action Damage_BrokenRibs(int client)
{
	char dmg_str[10];
	char dmg_type_str[10];
	IntToString((1 << 25), dmg_str, sizeof(dmg_type_str));
	GetConVarString(FindConVar("vi-l4d2_brokenribsdamage"), dmg_str, sizeof(dmg_str));
	int pointHurt = CreateEntityByName("point_hurt");
	DispatchKeyValue(client, "targetname", "war3_hurtme");
	DispatchKeyValue(pointHurt, "DamageTarget", "war3_hurtme");
	DispatchKeyValue(pointHurt, "Damage", dmg_str);
	DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt, "Hurt", client);
	DispatchKeyValue(client, "targetname", "war3_donthurtme");
	RemoveEdict(pointHurt);
}

public Action OnChargerImpact(Handle event, const char[] name, bool dontBroadcast)
{
	if (isCharger && isSnappedLeg)
	{
		int client = GetClientOfUserId(GetEventInt(event, "victim"));
		if (IsValidClient(client) && GetClientTeam(client) == 2 && !isSlowed[client])
		{
			int SnappedLegChance  = GetRandomInt(0, 99);
			int SnappedLegPercent = GetConVarInt(cvarSnappedLegChance);
			if (SnappedLegChance < SnappedLegPercent)
			{
				isSlowed[client] = true;
				if (isAnnounce)
				{
					PrintHintText(client, "Charger Snapped Your Leg!");
				}
				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", GetConVarFloat(cvarSnappedLegSpeed));
				if (cvarSnappedLegTimer[client] == INVALID_HANDLE)
				{
					cvarSnappedLegTimer[client] = CreateTimer(GetConVarFloat(cvarSnappedLegDuration), SnappedLeg, client);
				}
			}
		}
	}
}

public Action SnappedLeg(Handle timer, any client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
		isSlowed[client] = false;
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
		if (isAnnounce)
		{
			PrintHintText(client, "Your Leg Is Healing!");
		}
	}

	if (cvarSnappedLegTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarSnappedLegTimer[client]);
		cvarSnappedLegTimer[client] = INVALID_HANDLE;
	}

	return Plugin_Stop;
}

public Action OnChargerCarryStart(Handle event, const char[] name, bool dontBroadcast)
{
	if (isCharger && isStowaway)
	{
		int client = GetClientOfUserId(GetEventInt(event, "victim"));
		if (IsValidClient(client) && GetClientTeam(client) == 2)
		{
			stowaway[client]  = 1;
			isCarried[client] = true;
			if (cvarStowawayTimer[client] == INVALID_HANDLE)
			{
				cvarStowawayTimer[client] = CreateTimer(0.5, Timer_Stowaway, client);
			}
		}
	}
}

public Action Timer_Stowaway(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		if (isCarried[client])
		{
			stowaway[client] += 1;
		}
	}

	if (cvarStowawayTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarStowawayTimer[client]);
		cvarStowawayTimer[client] = INVALID_HANDLE;
	}

	return Plugin_Stop;
}

public Action OnChargerCarryEnd(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
		isCarried[client] = false;
		if (cvarStowawayDamageTimer[client] == INVALID_HANDLE)
		{
			cvarStowawayDamageTimer[client] = CreateTimer(0.1, Timer_StowawayDamage, client, TIMER_REPEAT);
		}
		int damage = GetConVarInt(cvarStowawayDamage);
		int count  = stowaway[client] * damage;
		if (count > 10)
		{
			count = 10;
		}

		if (isAnnounce)
		{
			PrintHintText(client, "Charger Inflicted %i Damage To You For Being Stowaway!", count);
		}
	}
}

public Action Timer_StowawayDamage(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		if (stowaway[client] <= 0)
		{
			if (cvarStowawayDamageTimer[client] != INVALID_HANDLE)
			{
				KillTimer(cvarStowawayDamageTimer[client]);
				cvarStowawayDamageTimer[client] = INVALID_HANDLE;
			}

			return Plugin_Stop;
		}

		Damage_Stowaway(client);

		if (stowaway[client] > 0)
		{
			stowaway[client] -= 1;
		}
	}

	return Plugin_Continue;
}

public Action Damage_Stowaway(int client)
{
	char dmg_str[10];
	char dmg_type_str[10];
	IntToString((1 << 25), dmg_str, sizeof(dmg_type_str));
	GetConVarString(FindConVar("vi-l4d2_stowawaydamage"), dmg_str, sizeof(dmg_str));
	int pointHurt = CreateEntityByName("point_hurt");
	DispatchKeyValue(client, "targetname", "war3_hurtme");
	DispatchKeyValue(pointHurt, "DamageTarget", "war3_hurtme");
	DispatchKeyValue(pointHurt, "Damage", dmg_str);
	DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt, "Hurt", client);
	DispatchKeyValue(client, "targetname", "war3_donthurtme");
	RemoveEdict(pointHurt);
}

public Action OnJockeyRideEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if (isJockey)
	{
		int client = GetClientOfUserId(GetEventInt(event, "victim"));
		if (IsValidClient(client) && GetClientTeam(client) == 2)
		{
			if (isBacterial)
			{
				int BacterialChance  = GetRandomInt(0, 99);
				int BacterialPercent = GetConVarInt(cvarBacterialChance);
				if (BacterialChance < BacterialPercent)
				{
					if (isAnnounce)
					{
						PrintHintText(client, "Jockey Infected You With Bacteria!");
					}

					if (bacterial[client] <= 0)
					{
						bacterial[client] = GetConVarInt(cvarBacterialDuration);
						if (cvarBacterialTimer[client] == INVALID_HANDLE)
						{
							cvarBacterialTimer[client] = CreateTimer(1.0, Timer_Bacterial, client, TIMER_REPEAT);
						}
					}
				}
			}

			if (isDerbyDaze)
			{
				DerbyDaze(client, 0);
				SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
			}
		}
	}
}

public Action Timer_Bacterial(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		if (bacterial[client] <= 0)
		{
			if (cvarBacterialTimer[client] != INVALID_HANDLE)
			{
				KillTimer(cvarBacterialTimer[client]);
				cvarBacterialTimer[client] = INVALID_HANDLE;
			}

			return Plugin_Stop;
		}

		Damage_Bacterial(client);

		if (bacterial[client] > 0)
		{
			bacterial[client] -= 1;
		}
	}

	return Plugin_Continue;
}

public Action Damage_Bacterial(int client)
{
	char dmg_str[10];
	char dmg_type_str[10];
	IntToString((1 << 25), dmg_str, sizeof(dmg_type_str));
	GetConVarString(FindConVar("vi-l4d2_bacterialdamage"), dmg_str, sizeof(dmg_str));
	int pointHurt = CreateEntityByName("point_hurt");
	DispatchKeyValue(client, "targetname", "war3_hurtme");
	DispatchKeyValue(pointHurt, "DamageTarget", "war3_hurtme");
	DispatchKeyValue(pointHurt, "Damage", dmg_str);
	DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt, "Hurt", client);
	DispatchKeyValue(client, "targetname", "war3_donthurtme");
	RemoveEdict(pointHurt);
}

public Action OnJockeyRide(Handle event, const char[] name, bool dontBroadcast)
{
	if (isJockey)
	{
		if (isDerbyDaze)
		{
			int client = GetClientOfUserId(GetEventInt(event, "victim"));
			if (IsValidClient(client))
			{
				DerbyDaze(client, GetConVarInt(cvarDerbyDazeAmount));
				SetEntProp(client, Prop_Send, "m_iHideHUD", GetConVarInt(cvarDerbyDazeAmount));
			}
		}
	}
}

void DerbyDaze(int client, int amount)
{
	int clients[2];
	clients[0] = client;

	DerbyDazeMsgID = GetUserMessageId("Fade");
	Handle message = StartMessageEx(DerbyDazeMsgID, clients, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);

	if (amount == 0)
	{
		BfWriteShort(message, (0x0001 | 0x0010));
	}
	else
	{
		BfWriteShort(message, (0x0002 | 0x0008));
	}

	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, amount);

	EndMessage();
}

public Action OnLungePounce(Handle event, const char[] name, bool dontBroadcast)
{
	if (isHunter && isCobraStrike)
	{
		int client = GetClientOfUserId(GetEventInt(event, "victim"));
		if (IsValidClient(client) && GetClientTeam(client) == 2)
		{
			int CobraStrikeChance  = GetRandomInt(0, 99);
			int CobraStrikePercent = GetConVarInt(cvarCobraStrikeChance);
			if (CobraStrikeChance < CobraStrikePercent)
			{
				char dmg_str[10];
				char dmg_type_str[10];
				IntToString((1 << 25), dmg_str, sizeof(dmg_type_str));
				GetConVarString(FindConVar("vi-l4d2_cobrastrikedamage"), dmg_str, sizeof(dmg_str));
				int pointHurt = CreateEntityByName("point_hurt");
				DispatchKeyValue(client, "targetname", "war3_hurtme");
				DispatchKeyValue(pointHurt, "DamageTarget", "war3_hurtme");
				DispatchKeyValue(pointHurt, "Damage", dmg_str);
				DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);
				DispatchSpawn(pointHurt);
				AcceptEntityInput(pointHurt, "Hurt", client);
				DispatchKeyValue(client, "targetname", "war3_donthurtme");
				RemoveEdict(pointHurt);

				int incapped = GetEntProp(client, Prop_Send, "m_currentReviveCount");
				if (incapped == cvarCobraStrikeCount)
				{
					ForcePlayerSuicide(client);
				}
				else
				{
					SetEntProp(client, Prop_Send, "m_currentReviveCount", cvarCobraStrikeCount);
				}
			}
		}
	}
}

public Action OnPounceEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if (isHunter && isDeepWounds)
	{
		int client = GetClientOfUserId(GetEventInt(event, "victim"));
		if (IsValidClient(client) && GetClientTeam(client) == 2)
		{
			int DeepWoundsChance  = GetRandomInt(0, 99);
			int DeepWoundsPercent = GetConVarInt(cvarDeepWoundsChance);
			if (DeepWoundsChance < DeepWoundsPercent)
			{
				if (isAnnounce)
				{
					PrintHintText(client, "You're Bleeding Caused By Hunter's Deep Wounds Ability!");
				}

				if (deepwounds[client] <= 0)
				{
					deepwounds[client] = GetConVarInt(cvarDeepWoundsDuration);
					if (cvarDeepWoundsTimer[client] == INVALID_HANDLE)
					{
						cvarDeepWoundsTimer[client] = CreateTimer(1.0, Timer_DeepWounds, client, TIMER_REPEAT);
					}
				}
			}
		}
	}
}

public Action Timer_DeepWounds(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		if (deepwounds[client] <= 0)
		{
			if (cvarDeepWoundsTimer[client] != INVALID_HANDLE)
			{
				KillTimer(cvarDeepWoundsTimer[client]);
				cvarDeepWoundsTimer[client] = INVALID_HANDLE;
			}

			return Plugin_Stop;
		}

		Damage_DeepWounds(client);

		if (deepwounds[client] > 0)
		{
			deepwounds[client] -= 1;
		}
	}

	return Plugin_Continue;
}

public Action Damage_DeepWounds(int client)
{
	char dmg_str[10];
	char dmg_type_str[10];
	IntToString((1 << 25), dmg_str, sizeof(dmg_type_str));
	GetConVarString(FindConVar("vi-l4d2_deepwoundsdamage"), dmg_str, sizeof(dmg_str));
	int pointHurt = CreateEntityByName("point_hurt");
	DispatchKeyValue(client, "targetname", "war3_hurtme");
	DispatchKeyValue(pointHurt, "DamageTarget", "war3_hurtme");
	DispatchKeyValue(pointHurt, "Damage", dmg_str);
	DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt, "Hurt", client);
	DispatchKeyValue(client, "targetname", "war3_donthurtme");
	RemoveEdict(pointHurt);
}

public Action OnChokeEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if (isSmoker && isCollapsedLung)
	{
		int client = GetClientOfUserId(GetEventInt(event, "victim"));
		if (IsValidClient(client) && GetClientTeam(client) == 2)
		{
			int CollapsedLungChance  = GetRandomInt(0, 99);
			int CollapsedLungPercent = GetConVarInt(cvarCollapsedLungChance);
			if (CollapsedLungChance < CollapsedLungPercent)
			{
				if (isAnnounce)
				{
					PrintHintText(client, "Smoker Collapsed Your Lung!");
				}

				if (collapsedlung[client] <= 0)
				{
					collapsedlung[client] = GetConVarInt(cvarCollapsedLungDuration);
					if (cvarCollapsedLungTimer[client] == INVALID_HANDLE)
					{
						cvarCollapsedLungTimer[client] = CreateTimer(1.0, Timer_CollapsedLung, client, TIMER_REPEAT);
					}
				}
			}
		}
	}
}

public Action Timer_CollapsedLung(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		if (collapsedlung[client] <= 0)
		{
			if (cvarCollapsedLungTimer[client] != INVALID_HANDLE)
			{
				KillTimer(cvarCollapsedLungTimer[client]);
				cvarCollapsedLungTimer[client] = INVALID_HANDLE;
			}

			return Plugin_Stop;
		}

		Damage_CollapsedLung(client);

		if (collapsedlung[client] > 0)
		{
			collapsedlung[client] -= 1;
		}
	}

	return Plugin_Continue;
}

public Action Damage_CollapsedLung(int client)
{
	char dmg_str[10];
	char dmg_type_str[10];
	IntToString((1 << 25), dmg_str, sizeof(dmg_type_str));
	GetConVarString(FindConVar("vi-l4d2_collapsedlungdamage"), dmg_str, sizeof(dmg_str));
	int pointHurt = CreateEntityByName("point_hurt");
	DispatchKeyValue(client, "targetname", "war3_hurtme");
	DispatchKeyValue(pointHurt, "DamageTarget", "war3_hurtme");
	DispatchKeyValue(pointHurt, "Damage", dmg_str);
	DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt, "Hurt", client);
	DispatchKeyValue(client, "targetname", "war3_donthurtme");
	RemoveEdict(pointHurt);
}

public Action OnTongueGrab(Handle event, const char[] name, bool dontBroadcast)
{
	if (isSmoker && isMoonWalk)
	{
		int    client = GetClientOfUserId(GetEventInt(event, "userid"));
		int    victim = GetClientOfUserId(GetEventInt(event, "victim"));
		Handle pack;

		if (IsValidClient(client))
		{
			moonwalk[client] = true;
			SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0 * GetConVarFloat(cvarMoonWalkSpeed));
			if (MoonWalkTimer[client] == INVALID_HANDLE)
			{
				MoonWalkTimer[client] = CreateDataTimer(0.2, Timer_MoonWalk, pack, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
			}
			WritePackCell(pack, client);
			WritePackCell(pack, victim);
		}
	}
}

public Action Timer_MoonWalk(Handle timer, Handle pack)
{
	ResetPack(pack);
	int client = ReadPackCell(pack);
	if (!IsValidClient(client) || GetClientTeam(client) != 3 || !moonwalk[client])
	{
		KillTimer(MoonWalkTimer[client]);
		MoonWalkTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	int Victim = ReadPackCell(pack);
	if (!IsValidClient(Victim) || GetClientTeam(Victim) != 2 || !moonwalk[client])
	{
		KillTimer(MoonWalkTimer[client]);
		MoonWalkTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	int MoonWalkStretch = GetConVarInt(cvarMoonWalkStretch);

	float SmokerPosition[3];
	float VictimPosition[3];

	GetClientAbsOrigin(client, SmokerPosition);
	GetClientAbsOrigin(Victim, VictimPosition);

	int distance = RoundToNearest(GetVectorDistance(SmokerPosition, VictimPosition));
	if (distance > MoonWalkStretch)
	{
		SlapPlayer(client, 0, false);
		if (isAnnounce)
		{
			PrintHintText(Victim, "\x03[VI]\x04 You're Free!");
		}
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public Action OnTongueRelease(Handle event, const char[] name, bool dontBroadcast)
{
	if (isSmoker && isMoonWalk)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (IsValidClient(client))
		{
			moonwalk[client] = false;
			SetEntityMoveType(client, MOVETYPE_CUSTOM);
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
			if (MoonWalkTimer[client] != INVALID_HANDLE)
			{
				KillTimer(MoonWalkTimer[client]);
				MoonWalkTimer[client] = INVALID_HANDLE;
			}
		}
	}
}

public Action Timer_AcidSwipe(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		if (acidswipe[client] <= 0)
		{
			if (cvarAcidSwipeTimer[client] != INVALID_HANDLE)
			{
				KillTimer(cvarAcidSwipeTimer[client]);
				cvarAcidSwipeTimer[client] = INVALID_HANDLE;
			}

			return Plugin_Stop;
		}

		Damage_AcidSwipe(client);

		if (acidswipe[client] > 0)
		{
			acidswipe[client] -= 1;
		}
	}

	return Plugin_Continue;
}

public Action Damage_AcidSwipe(int client)
{
	char dmg_str[10];
	char dmg_type_str[10];
	IntToString((1 << 25), dmg_str, sizeof(dmg_type_str));
	GetConVarString(FindConVar("vi-l4d2_acidswipedamage"), dmg_str, sizeof(dmg_str));
	int pointHurt = CreateEntityByName("point_hurt");
	DispatchKeyValue(client, "targetname", "war3_hurtme");
	DispatchKeyValue(pointHurt, "DamageTarget", "war3_hurtme");
	DispatchKeyValue(pointHurt, "Damage", dmg_str);
	DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt, "Hurt", client);
	DispatchKeyValue(client, "targetname", "war3_donthurtme");
	RemoveEdict(pointHurt);
}

public Action OnEnteredSpit(Handle event, const char[] name, bool dontBroadcast)
{
	if (isSpitter && isStickyGoo)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (IsValidClient(client) && GetClientTeam(client) == 2 && !isSlowed[client])
		{
			isSlowed[client] = true;
			if (isAnnounce)
			{
				PrintHintText(client, "Sticky Goo's Slowing You Down!");
			}
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", GetConVarFloat(cvarStickyGooSpeed));
			if (cvarStickyGooTimer[client] == INVALID_HANDLE)
			{
				cvarStickyGooTimer[client] = CreateTimer(GetConVarFloat(cvarStickyGooDuration), StickyGoo, client);
			}
		}
	}
}

public Action StickyGoo(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		isSlowed[client] = false;
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
		if (isAnnounce)
		{
			PrintHintText(client, "Sticky Goo's Wearing Off!");
		}

		if (cvarStickyGooTimer[client] != INVALID_HANDLE)
		{
			KillTimer(cvarStickyGooTimer[client]);
			cvarStickyGooTimer[client] = INVALID_HANDLE;
		}
	}

	return Plugin_Stop;
}

public Action OnSpitBurst(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (isSpitter && IsValidClient(client))
	{
		if (isSupergirl)
		{
			if (isAnnounce)
			{
				PrintHintText(client, "Temporarily Invulnerable!");
			}
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			if (cvarSupergirlTimer[client] == INVALID_HANDLE)
			{
				cvarSupergirlTimer[client] = CreateTimer(GetConVarFloat(cvarSupergirlDuration), Supergirl, client);
			}
		}

		if (isSupergirlSpeed)
		{
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 2.0);
			if (cvarSupergirlSpeedTimer[client] == INVALID_HANDLE)
			{
				cvarSupergirlSpeedTimer[client] = CreateTimer(GetConVarFloat(cvarSupergirlSpeedDuration), SupergirlSpeed, client);
			}
		}
	}
}

public Action Supergirl(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		if (isAnnounce)
		{
			PrintHintText(client, "No Longer Invulnerable!");
		}
	}

	if (cvarSupergirlTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarSupergirlTimer[client]);
		cvarSupergirlTimer[client] = INVALID_HANDLE;
	}

	return Plugin_Stop;
}

public Action SupergirlSpeed(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
	}

	if (cvarSupergirlSpeedTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarSupergirlSpeedTimer[client]);
		cvarSupergirlSpeedTimer[client] = INVALID_HANDLE;
	}

	return Plugin_Stop;
}

public Action Timer_BurningRage(Handle timer, any client)
{
	if (IsValidClient(client) && IsPlayerOnFire(client) && !isTankOnFire[client])
	{
		isTankOnFire[client] = true;
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0 * GetConVarFloat(cvarBurningRageSpeed));
		if (isAnnounce)
		{
			PrintToChatAll("\x03[VI]\x04 Tank's Burning Rage Ability Boosted His Speed!");
		}
	}

	return Plugin_Continue;
}

public Action OnTankSpawned(Handle event, const char[] name, bool dontBroadcast)
{
	if (TankMax <= TankActive)
	{
		return;
	}

	if (TankMaxMap <= TankSpawned)
	{
		return;
	}

	TankSpawned = (TankSpawned + 1);
	TankActive  = (TankActive + 1);

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		if (isTank && IsValidTank(client))
		{
			if (isCullingSwarm)
			{
				int flags3 = GetCommandFlags("z_spawn_old");
				int flags4 = GetCommandFlags("director_force_panic_event");
				SetCommandFlags("z_spawn_old", flags3 & ~FCVAR_CHEAT);
				SetCommandFlags("director_force_panic_event", flags4 & ~FCVAR_CHEAT);
				FakeClientCommand(client, "director_force_panic_event");
				SetCommandFlags("z_spawn_old", flags3 | FCVAR_CHEAT);
				SetCommandFlags("director_force_panic_event", flags4 | FCVAR_CHEAT);
				if (isAnnounce)
				{
					PrintToChatAll("\x03[VI]\x04 Culling Mob Spawned!");
				}
			}

			if (isWorriedWife)
			{
				if (client == 0)
				{
					return;
				}

				int flags3 = GetCommandFlags("z_spawn_old");
				SetCommandFlags("z_spawn_old", flags3 & ~FCVAR_CHEAT);
				FakeClientCommand(client, "%s %s", "z_spawn_old", "witch auto");
				SetCommandFlags("z_spawn_old", flags3 | FCVAR_CHEAT);
				if (isAnnounce)
				{
					PrintToChatAll("\x03[VI]\x04 Worried Witch Spawned!");
				}
			}
		}
	}
}

public Action OnTankKilled(Handle event, const char[] name, bool dontBroadcast)
{
	TankActive = (TankActive - 1);

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidDeadTank(client) && GetClientTeam(client) == 3)
	{
		if (isTank && isMourningWidow)
		{
			if (client == 0)
			{
				return;
			}

			int flags3 = GetCommandFlags("z_spawn_old");
			SetCommandFlags("z_spawn_old", flags3 & ~FCVAR_CHEAT);
			FakeClientCommand(client, "%s %s", "z_spawn_old", "witch auto");
			SetCommandFlags("z_spawn_old", flags3 | FCVAR_CHEAT);
			if (isAnnounce)
			{
				PrintToChatAll("\x03[VI]\x04 Mourning Witch Spawned!");
			}
		}

		if (BurningRageTimer[client] != INVALID_HANDLE)
		{
			KillTimer(BurningRageTimer[client]);
			BurningRageTimer[client] = INVALID_HANDLE;
		}

		isTankOnFire[client] = false;
		isFrustrated         = false;
	}
}

public Action OnTankFrustrated(Handle event, const char[] name, bool dontBroadcast)
{
	isFrustrated = true;
}

public Action OnWitchSpawned(Handle event, const char[] name, bool dontBroadcast)
{
	if (WitchMax <= WitchActive)
	{
		return;
	}

	if (WitchMaxMap <= WitchSpawned)
	{
		return;
	}

	WitchSpawned = (WitchSpawned + 1);
	WitchActive  = (WitchActive + 1);

	if (isWitch && isMoodSwing)
	{
		MoodSwingSet();
	}
}

public void MoodSwingSet()
{
	int wHPMin = GetConVarInt(cvarMoodSwingMin);
	int wHPMax = GetConVarInt(cvarMoodSwingMax);
	int wHP    = GetRandomInt(wHPMin, wHPMax);
	SetConVarInt(FindConVar("z_witch_health"), wHP, false, false);
}

public Action OnWitchKilled(Handle event, const char[] name, bool dontBroadcast)
{
	WitchActive = (WitchActive - 1);
}

public Action OnWitchHarasserSet(Handle event, const char[] name, bool dontBroadcast)
{
	if (isWitch && isSupportGroup)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		int flags  = GetCommandFlags("z_spawn_old");
		SetCommandFlags("z_spawn_old", flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "z_spawn_old mob auto");
		SetCommandFlags("z_spawn_old", flags | FCVAR_CHEAT);
		if (isAnnounce)
		{
			PrintToChatAll("\x03[VI]\x05 Support Mob Spawned!");
		}
	}
}

public void Reset_Timers(int client)
{
	if (cvarBileSwipeTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarBileSwipeTimer[client]);
		cvarBileSwipeTimer[client] = INVALID_HANDLE;
	}

	if (cvarBrokenRibsTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarBrokenRibsTimer[client]);
		cvarBrokenRibsTimer[client] = INVALID_HANDLE;
	}

	if (cvarBacterialTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarBacterialTimer[client]);
		cvarBacterialTimer[client] = INVALID_HANDLE;
	}

	if (cvarDeepWoundsTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarDeepWoundsTimer[client]);
		cvarDeepWoundsTimer[client] = INVALID_HANDLE;
	}

	if (cvarCollapsedLungTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarCollapsedLungTimer[client]);
		cvarCollapsedLungTimer[client] = INVALID_HANDLE;
	}

	if (MoonWalkTimer[client] != INVALID_HANDLE)
	{
		KillTimer(MoonWalkTimer[client]);
		MoonWalkTimer[client] = INVALID_HANDLE;
	}

	if (cvarAcidSwipeTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarAcidSwipeTimer[client]);
		cvarAcidSwipeTimer[client] = INVALID_HANDLE;
	}

	if (BurningRageTimer[client] != INVALID_HANDLE)
	{
		KillTimer(BurningRageTimer[client]);
		BurningRageTimer[client] = INVALID_HANDLE;
	}
}

public Action OnPlayerIncapped(Handle event, const char[] name, bool dontBroadcast)
{
	if (isJockey && isDerbyDaze)
	{
		int client = GetClientOfUserId(GetEventInt(event, "victim"));
		if (IsValidClient(client) && GetClientTeam(client) == 2)
		{
			DerbyDaze(client, 0);
			SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
		}
	}
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient2(client) && GetClientTeam(client) == 2)
	{
		brokenribs[client]    = 0;
		bacterial[client]     = 0;
		collapsedlung[client] = 0;
		deepwounds[client]    = 0;
		bileswipe[client]     = 0;
		acidswipe[client]     = 0;
		stowaway[client]      = 0;
		isSlowed[client]      = false;
		DerbyDaze(client, 0);
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
		Reset_Timers(client);
	}
}

public Action OnPlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient2(client))
	{
		brokenribs[client]    = 0;
		bacterial[client]     = 0;
		collapsedlung[client] = 0;
		deepwounds[client]    = 0;
		bileswipe[client]     = 0;
		acidswipe[client]     = 0;
		stowaway[client]      = 0;
		isSlowed[client]      = false;
		DerbyDaze(client, 0);
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
		Reset_Timers(client);
	}
}

public Action OnRoundReset(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient2(client) && GetClientTeam(client) == 2)
	{
		brokenribs[client]    = 0;
		bacterial[client]     = 0;
		collapsedlung[client] = 0;
		deepwounds[client]    = 0;
		bileswipe[client]     = 0;
		acidswipe[client]     = 0;
		stowaway[client]      = 0;
		isSlowed[client]      = false;
		DerbyDaze(client, 0);
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
	}
	isTankOnFire[client] = false;
	isFrustrated         = false;
	TankActive           = 0;
	TankSpawned          = 0;
	WitchActive          = 0;
	WitchSpawned         = 0;
	Reset_Timers(client);
}

public bool IsValidClient(int client)
{
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return false;
	}

	return true;
}

public bool IsValidClient2(int client)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return false;
	}

	return true;
}

public bool IsValidTank(int client)
{
	if (!IsValidClient2(client) || !IsFakeClient(client) || GetEntProp(client, Prop_Send, "m_zombieClass") != 8 || isFrustrated)
	{
		return false;
	}

	return true;
}

public bool IsValidDeadTank(int client)
{
	if (!IsValidClient2(client) || GetEntProp(client, Prop_Send, "m_zombieClass") != 8 || IsPlayerAlive(client))
	{
		return false;
	}

	return true;
}

public bool IsPlayerOnFire(int client)
{
	if (IsValidClient(client))
	{
		if (GetEntProp(client, Prop_Data, "m_fFlags") & FL_ONFIRE)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	else
	{
		return false;
	}
}

stock bool IsPlayerGhost(int client)
{
	if (IsValidClient(client))
	{
		if (GetEntProp(client, Prop_Send, "m_isGhost")) return true;
		else return false;
	}
	else return false;
}