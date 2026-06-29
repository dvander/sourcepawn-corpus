#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#pragma tabsize 0

#define L4D2 Vicious Infected
#define PLUGIN_VERSION "1.71"

#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_HUNTER 3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_TANK 8


///Boomer
//Bools
new bool:isBoomer = false;
new bool:isBileFeet = false;
new bool:isBileMask = false;
new bool:isBileMaskTilDry = false;
new bool:isBileShower = false;
new bool:isBileShowerTimeout;
new bool:isBileSwipe = false;

//Handles
new Handle:cvarBoomer;
new Handle:cvarBileFeet;
new Handle:cvarBileFeetSpeed;
new Handle:cvarBileMask;
new Handle:cvarBileMaskAmount;
new Handle:cvarBileMaskDuration;
new Handle:cvarBileShower;
new Handle:cvarBileShowerTimeout;
new Handle:cvarBileSwipe;
new Handle:cvarBileSwipeDuration;
new bileswipe[MAXPLAYERS+1];


///Charger
//Bools
new bool:isCharger = false;
new bool:isBrokenRibs = false;
new bool:isStowaway = false;
new bool:isSnappedLeg = false;
new bool:isCarried[MAXPLAYERS+1] = false;

//Handles
new Handle:cvarCharger;
new Handle:cvarBrokenRibs;
new Handle:cvarBrokenRibsDuration;
new Handle:cvarSnappedLeg;
new Handle:cvarSnappedLegDuration;
new Handle:cvarSnappedLegSpeed;
new Handle:cvarStowaway;
new Handle:cvarStowawayDamage;
new brokenribs[MAXPLAYERS+1];
new stowaway[MAXPLAYERS+1];


//Jockey
//Bools
new bool:isJockey = false;
new bool:isBacterial = false;
new bool:isDerbyDaze = false;
new bool:isGhostStalker = false;
new bool:isRiding = false;

//Handles
new Handle:cvarJockey;
new Handle:cvarBacterial;
new Handle:cvarBacterialDuration;
new Handle:cvarDerbyDaze;
new Handle:cvarDerbyDazeAmount;
new Handle:cvarGhostStalker;
new Handle:cvarGhostStalkerChance;
new bacterial[MAXPLAYERS+1];


//Hunter
//Bools
new bool:isHunter = false;
new bool:isCobraStrike = false;
new bool:isDeepWounds = false;

//Handles
new Handle:cvarHunter;
new Handle:cvarCobraStrike;
new Handle:cvarCobraStrikeChance;
new cvarCobraStrikeCount = 2;
new Handle:cvarDeepWounds;
new Handle:cvarDeepWoundsDuration;
new deepwounds[MAXPLAYERS+1];


///Smoker
//Bools
new bool:isSmoker = false;
new bool:isCollapsedLung = false;
new bool:isMoonWalk = false;
new bool:moonwalk[MAXPLAYERS+1];

//Handles
new Handle:cvarSmoker;
new Handle:cvarCollapsedLung;
new Handle:cvarCollapsedLungDuration;
new Handle:cvarMoonWalk;
new Handle:cvarMoonWalkSpeed;
new Handle:cvarMoonWalkStretch;
new Handle:MoonWalkTimer[MAXPLAYERS+1];
new collapsedlung[MAXPLAYERS+1];


///Spitter
//Bools
new bool:isSpitter = false;
new bool:isAcidSwipe = false;
new bool:isStickyGoo = false;
new bool:isSupergirl = false;

//Handles
new Handle:cvarSpitter;
new Handle:cvarAcidSwipe;
new Handle:cvarAcidSwipeDuration;
new Handle:cvarStickyGoo;
new Handle:cvarStickyGooDuration;
new Handle:cvarStickyGooSpeed;
new Handle:cvarSupergirl;
new Handle:cvarSupergirlDuration;
new acidswipe[MAXPLAYERS+1];


///Tank
//Bools
new bool:isTank = false;
new bool:isATank[MAXPLAYERS+1] = false;
new bool:isBurningRage = false;
new bool:isCullingSwarm = false;
new bool:isMourningWidow = false;
new bool:isWorriedWife = false;
new bool:isTankOnFire[MAXPLAYERS+1] = false;

//Handles
new Handle:cvarTank;
new Handle:cvarBurningRage;
new Handle:cvarBurningRageSpeed;
new Handle:BurningRageTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:cvarCullingSwarm;
new Handle:cvarMourningWidow;
new Handle:cvarWorriedWife;


///Witch
//Bools
new bool:isWitch = false;
new bool:isMiniBodyguard = false;
new bool:isMiniHealth = false;
new bool:isMiniTank[MAXPLAYERS+1] = false;
new bool:isMiniTankSpawn = false;
new bool:isSupportGroup = false;

//Handles
new Handle:cvarWitch;
new Handle:cvarMiniBodyguard;
new Handle:cvarMiniBodyguardHP;
new Handle:cvarMiniHealth;
new Handle:cvarSupportGroup;



///Generic
static laggedMovementOffset = 0;
new bool:isEnabled = false;
new bool:isAnnounce = false;
new bool:isSlowed[MAXPLAYERS+1] = false;

new Handle:cvarEnabled;
new Handle:cvarAnnounce;
new Handle:hBecomeGhost;
new Handle:hBecomeGhostAt;
new Handle:hGameConf;
new Handle:cvarTankMax;
new Handle:cvarTankMaxMap;
new Handle:cvarWitchMax;
new Handle:cvarWitchMaxMap;
new WitchActive;
new WitchSpawned;
new WitchMax;
new WitchMaxMap;
new TankActive;
new TankSpawned;
new TankMax;
new TankMaxMap;
new UserMsg:DerbyDazeMsgID;

public Plugin:myinfo = 
{
    name = "[L4D2] Vicious Infected",
    author = "Mortiegama",
    description = "This is a universal plugin that will add special abilities to the Infected team.",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=119891"
}

	//Special Thanks:
	//Oshroth - Acid/Bile Swipe:
	//http://forums.alliedmods.net/showthread.php?p=1117948

	//Olj - Smoke IT! (Moonwalk):
	//http://forums.alliedmods.net/showthread.php?p=936834

	//DieTeetasse - Jockey Blindfold (Derby Daze):
	//http://forums.alliedmods.net/showpost.php?p=1134514&postcount=5

public OnPluginStart()
{
	CreateConVar("l4d_vts_version", PLUGIN_VERSION, "Vicious Infected Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	//First we setup everything that we need for the Boomer
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_now_it", Event_PlayerNowIt);
	HookEvent("player_no_longer_it", Event_PlayerNotIt);

	cvarBoomer = CreateConVar("l4d_vts_boomer", "1", "Enables the Boomer abilities. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBileFeet = CreateConVar("l4d_vts_bilefeet", "0", "Increases the movement speed of the Boomer. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBileFeetSpeed = CreateConVar("l4d_vts_bilefeetspeed", "1", "How much does Bile Feet increase the Boomer movement speed. (Def 1.5)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBileMask = CreateConVar("l4d_vts_bilemask", "1", "Boomer Bile will cover the Survivors entire HUD. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBileMaskAmount = CreateConVar("l4d_vts_bilemaskamount", "200", "Amount of visibility covered by the Boomer's bile (0 = None, 255 = Total). (Def 200)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBileMaskDuration = CreateConVar("l4d_vts_bilemaskduration", "-1", "How long is the HUD hidden for after vomit (-1 = Until Dry, 0< is period of time). (Def 200)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBileShower = CreateConVar("l4d_vts_bileshower", "1", "Summons a mob when the Boomer vomits/explodes on a Survivor. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBileShowerTimeout = CreateConVar("l4d_vts_bileshowertimeout", "2", "How many seconds must a Boomer wait before summoning another mob. (Def 10)", FCVAR_PLUGIN, true, 1.0, false, _);
	cvarBileSwipe = CreateConVar("l4d_vts_bileswipe", "1", "When a Boomer claws a Survivor they will take damage over time (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBileSwipeDuration = CreateConVar("l4d_vts_bileswipeduration", "2", "For how many seconds does the Bile Swipe last. (Def 10)", FCVAR_PLUGIN, true, 1.0, false, _);
	CreateConVar("l4d_vts_bileswipedamage", "7", "How much damage is inflicted by Bile Swipe each second. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);



	//Next we setup everything that we need for the Charger
	HookEvent("charger_pummel_end", Event_ChargerPummelEnd);
	HookEvent("charger_impact", Event_ChargerImpact);
	HookEvent("charger_carry_start", Event_ChargerCarryStart);
	HookEvent("charger_carry_end", Event_ChargerCarryEnd);

	cvarCharger = CreateConVar("l4d_vts_charger", "1", "Enables the Charger abilities. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBrokenRibs = CreateConVar("l4d_vts_brokenribs", "1", "After a pummel ends the Survivor takes damage over time. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBrokenRibsDuration = CreateConVar("l4d_vts_brokenribsduration", "2", "For how many seconds does the Broken Ribs last. (Def 10)", FCVAR_PLUGIN, true, 1.0, false, _);
	CreateConVar("l4d_vts_brokenribsdamage", "7", "How much damage is inflicted by Broken Ribs each second. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSnappedLeg = CreateConVar("l4d_vts_snappedleg", "1", "After a charger collision movement speed is reduced. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSnappedLegDuration = CreateConVar("l4d_vts_snappedlegduration", "5", "For how many seconds will the Snapped Leg reduce movement speed. (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSnappedLegSpeed = CreateConVar("l4d_vts_snappedlegspeed", "0.65", "How much does Snapped Leg reduce movement speed. (Def 0.5)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarStowaway = CreateConVar("l4d_vts_stowaway", "1", "After a Charge the Survivor is damaged based upon carry time. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarStowawayDamage = CreateConVar("l4d_vts_stowawaydamage", "7", "How much damage is inflicted by Stowaway for each second carried. (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);




	//Next we setup everything that we need for the Jockey
	HookEvent("jockey_ride", Event_JockeyRideStart);
	HookEvent("jockey_ride_end", Event_JockeyRideEnd);

	cvarJockey = CreateConVar("l4d_vts_jockey", "1", "Enables the Jockey abilities. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBacterial = CreateConVar("l4d_vts_bacterialinfection", "1", "After a ride ends the Survivor takes damage over time. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBacterialDuration = CreateConVar("l4d_vts_bacterialduration", "2", "For how many seconds does the Bacterial Infection last. (Def 10)", FCVAR_PLUGIN, true, 1.0, false, _);
	CreateConVar("l4d_vts_bacterialdamage", "7", "How much damage is inflicted by Bacterial Infection each second. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarDerbyDaze = CreateConVar("l4d_vts_derbydaze", "0", "Jockey covers the Survivors eyes during a ride reducing visibility. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarDerbyDazeAmount = CreateConVar("l4d_vts_derbydazeamount", "0", "Amount of visibility covered by the Jockey's hand (0 = None, 255 = Total). (Def 200)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarGhostStalker = CreateConVar("l4d_vts_ghoststalker", "0", "When damaged, Jockey has a chance to returning to Ghost mode unless riding. (Def 0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarGhostStalkerChance = CreateConVar("l4d_vts_ghoststalkerchance", "0", "Chance that the Jockey will return to Ghost mode (5 = 5%). (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);



	//Next we setup everything that we need for the Hunter
	HookEvent("lunge_pounce", Event_PounceStart, EventHookMode_Pre);
	HookEvent("pounce_end", Event_PounceEnd);

	cvarHunter = CreateConVar("l4d_vts_hunter", "1", "Enables the Hunter abilities. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarCobraStrike = CreateConVar("l4d_vts_cobrastrike", "0", "Hunter pounce has a chance of instantly incapping and making Survivor B&W. (Def 0)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarCobraStrikeChance = CreateConVar("l4d_vts_cobrastrikechance", "0", "Chance that the Hunter pounce will incap Survivor (5 = 5%). (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);
	CreateConVar("l4d_vts_cobrastrikedamage", "100", "How much damage is inflicted by Cobra Strike (should be max Survivor HP). (Def 100)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarDeepWounds = CreateConVar("l4d_vts_deepwounds", "1", "After a pounce ends the Survivor takes damage over time. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarDeepWoundsDuration = CreateConVar("l4d_vts_deepwoundsduration", "2", "For how many seconds does the Deep Wounds last. (Def 10)", FCVAR_PLUGIN, true, 1.0, false, _);
	CreateConVar("l4d_vts_deepwoundsdamage", "7", "How much damage is inflicted by Deep Wounds each second. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);



	//Next we setup everything that we need for the Smoker
	HookEvent("choke_end", Event_ChokeEnd);
	HookEvent("tongue_grab", Event_TongueGrab);
	HookEvent("tongue_release", Event_TongueRelease, EventHookMode_Pre);

	cvarSmoker = CreateConVar("l4d_vts_smoker", "1", "Enables the Smoker abilities. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarCollapsedLung = CreateConVar("l4d_vts_collapsedlung", "1", "After a ride ends the Survivor takes damage over time. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarCollapsedLungDuration = CreateConVar("l4d_vts_collapsedlungduration", "5", "For how many seconds does the Collapsed Lung last. (Def 5)", FCVAR_PLUGIN, true, 1.0, false, _);
	CreateConVar("l4d_vts_collapsedlungdamage", "3", "How much damage is inflicted by Collapsed Lung each second. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarMoonWalk = CreateConVar("l4d_vts_moonwalk", "1", "Smoker is able to move and drag Survivor after tongue grab. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarMoonWalkSpeed = CreateConVar("l4d_vts_moonwalkspeed", "3.5", "How fast will the Smoker move after a tongue grab and drag. (Def 0.4)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarMoonWalkStretch = CreateConVar("l4d_vts_moonwalkstretch", "9000", "How far the Smokers tongue can stretch before it snaps. (Def 2000)", FCVAR_PLUGIN, true, 0.0, false, _);



	//Next we setup everything that we need for the Spitter
	HookEvent("entered_spit", Event_EnteredSpit);
	HookEvent("spit_burst", Event_SpitBurst);

	cvarSpitter = CreateConVar("l4d_vts_spitter", "1", "Enables the Spitter abilities. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarAcidSwipe = CreateConVar("l4d_vts_acidswipe", "1", "When a Spitter claws a Survivor they will take damage over time (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarAcidSwipeDuration = CreateConVar("l4d_vts_acidswipeduration", "5", "For how many seconds does the Acid Swipe last. (Def 10)", FCVAR_PLUGIN, true, 1.0, false, _);
	CreateConVar("l4d_vts_acidswipedamage", "2", "How much damage is inflicted by Acid Swipe each second. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarStickyGoo = CreateConVar("l4d_vts_stickygoo", "0", "Slows down Survivor when standing in spit. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarStickyGooDuration = CreateConVar("l4d_vts_stickygooduration", "0", "How long a Survivor is slowed for aftering entering spit. (Def 6)", FCVAR_PLUGIN, true, 1.0, false, _);
	cvarStickyGooSpeed = CreateConVar("l4d_vts_stickygoospeed", "0", "Speed reduction to Survivor. (Def 0.5)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSupergirl = CreateConVar("l4d_vts_supergirl", "0", "Temporary invulnerability after Spitter spits. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSupergirlDuration = CreateConVar("l4d_vts_supergirlduration", "0", "How long the Spitter is invulnerable. (Def 3)", FCVAR_PLUGIN, true, 1.0, false, _);



	//Next we setup everything that we need for the Tank
        HookEvent("tank_spawn", Event_TankSpawned);
	HookEvent("player_death", Event_TankKilled);

	cvarTank= CreateConVar("l4d_vts_tank", "1", "Enables the Tank abilities. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTankMax = CreateConVar("l4d_vts_tankmax", "5", "Maximum number of Tanks (Mini Bodyguard) allowed to spawn with this plugin at a time. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTankMaxMap = CreateConVar("l4d_vts_tankmaxmap", "99", "Maximum number of Tanks (Mini Bodyguard) allowed to spawn throughout an entire map. (Def 3)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBurningRage = CreateConVar("l4d_vts_burningrage", "1", "Increases the Tanks speed when on fire. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarBurningRageSpeed = CreateConVar("l4d_vts_burningragespeed", "1.25", "How much of a speed boost does Burning Rage give. (Def 1.25)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarCullingSwarm = CreateConVar("l4d_vts_cullingswarm", "1", "Spawns a Panic Event when the tank spawns. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarMourningWidow = CreateConVar("l4d_vts_mourningwidow", "1", "Spawns a Witch after the Tank dies. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarWorriedWife = CreateConVar("l4d_vts_worriedwife", "1", "Spawns a Witch when the Tank spawns. (Def 0)", FCVAR_PLUGIN, true, 0.0, false, _);



	//Finally we setup everything that we need for the Witch
	HookEvent("witch_killed", Event_WitchKilled);
        HookEvent("witch_harasser_set", Event_WitchAngered);

	cvarWitch = CreateConVar("l4d_vts_witch", "1", "Enables the Witch abilities. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarWitchMax = CreateConVar("l4d_vts_witchmax", "5", "Maximum number of Witches allowed to spawn with this plugin at a time. (Def 2)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarWitchMaxMap = CreateConVar("l4d_vts_witchmaxmap", "99", "Maximum number of Witches allowed to spawn throughout an entire map. (Def 6)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarMiniBodyguard = CreateConVar("l4d_vts_minibodyguard", "1", "Spawns a Tank when the Witch is killed. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarMiniBodyguardHP = CreateConVar("l4d_vts_minibodyguardhp", "1", "Percentage of HP to give the Bodyguard (0.25 = 25%). (Def 0.25)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarMiniHealth = CreateConVar("l4d_vts_minihealth", "1", "Changes the health of the Mini Bodyguard Tank. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSupportGroup = CreateConVar("l4d_vts_supportgroup", "1", "Spawns a mob when the Witch is angered. (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);



	//This area is for general information
	HookEvent("player_incapacitated", Event_PlayerIncapped);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_end", Event_RoundEnd);

	cvarEnabled = CreateConVar("l4d_vts_enable", "1", "Enables the Vicious Infected plugin.");
	cvarAnnounce = CreateConVar("l4d_vts_announce", "1", "Announce panic event and witch spawn?");

	laggedMovementOffset = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	AutoExecConfig(true, "plugin.L4D2.ViciousInfected");
	CreateTimer(3.0, OnPluginStart_Delayed, INVALID_HANDLE, TIMER_DATA_HNDL_CLOSE);

	if (GetConVarInt(cvarEnabled))
	{
	isEnabled = true;
	}

	hGameConf = LoadGameConfigFile("l4d2_viciousinfected");
	if (hGameConf != INVALID_HANDLE)
	{	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "BecomeGhost");
	PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
	hBecomeGhost = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "BecomeGhostAt");
	PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
	hBecomeGhostAt = EndPrepSDKCall();
	}
}

public Action:OnPluginStart_Delayed(Handle:timer)
{
	if (isEnabled)
	{
	//First we setup the Bool for the Boomer

	if (GetConVarInt(cvarBoomer))
	{
	isBoomer = true;
	}

	if (GetConVarInt(cvarBileFeet))
	{
	isBileFeet = true;
	}

	if (GetConVarInt(cvarBileMask))
	{
	isBileMask = true;
	}

	if (GetConVarInt(cvarBileMaskDuration) == -1)
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

	//Next we setup the Bool for the Charger

	if (GetConVarInt(cvarCharger))
	{
	isCharger = true;
	}

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

	//Next we setup the Bool for the Jockey

	if (GetConVarInt(cvarJockey))
	{
	isJockey = true;
	}

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

	//Next we setup the Bool for the Hunter

	if (GetConVarInt(cvarHunter))
	{
	isHunter = true;
	}

	if (GetConVarInt(cvarCobraStrike))
	{
	isCobraStrike = true;
	}

	if (GetConVarInt(cvarDeepWounds))
	{
	isDeepWounds = true;
	}

	//Next we setup the Bool for the Smoker

	if (GetConVarInt(cvarSmoker))
	{
	isSmoker = true;
	}

	if (GetConVarInt(cvarCollapsedLung))
	{
	isCollapsedLung = true;
	}


	if (GetConVarInt(cvarMoonWalk))
	{
	isMoonWalk = true;
	}

	//Next we setup the Bool for the Spitter

	if (GetConVarInt(cvarSpitter))
	{
	isSpitter = true;
	}

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

	//Next we setup the Bool for the Tank

	if (GetConVarInt(cvarTank))
	{
	isTank = true;
	}

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

	//Next we setup the Bool for the Tank

	if (GetConVarInt(cvarWitch))
	{
	isWitch = true;
	}

	if (GetConVarInt(cvarMiniBodyguard))
	{
	isMiniBodyguard = true;
	}

	if (GetConVarInt(cvarMiniHealth))
	{
	isMiniHealth = true;
	}

	if (GetConVarInt(cvarSupportGroup))
	{
	isSupportGroup = true;
	}

	//Finally we setup Generic Bools

	if (GetConVarInt(cvarAnnounce))
	{
	isAnnounce = true;
	}

	TankMax = GetConVarInt(cvarTankMax);
	TankMaxMap = GetConVarInt(cvarTankMaxMap);
	WitchMax = GetConVarInt(cvarWitchMax);
	WitchMaxMap = GetConVarInt(cvarWitchMaxMap);
	}
}

public OnMapStart()
{
	/* Precache Models */
	PrecacheModel("models/infected/witch.mdl", true);
	PrecacheModel("models/infected/witch_bride.mdl", true);	

	decl String:GameMode[16];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
	
	if (StrEqual(GameMode, "survival", false))
    	{
       	PrintToServer("Survival Mode does not allow Culling Swarm to be Enabled!");
	isCullingSwarm = false;
    	}
}


///Universal Events

//This will setup events that are required for more than one ability

public Event_PlayerSpawn (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
	new class = GetEntProp(client, Prop_Send, "m_zombieClass");
	if (class == ZOMBIECLASS_BOOMER)
	{
	if (isBoomer && isBileFeet)
	{
	CreateTimer(0.5, Event_BoomerBileFeet, client, TIMER_DATA_HNDL_CLOSE);
	}
	}
	}
}

public Event_PlayerHurt (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

//This is the Hook for Acid Swipe - Survivor takes damage over time after being Spitter clawed

	if (isSpitter && isAcidSwipe)
	{
	if (IsValidClient(client) && GetClientTeam(client) == 2 && StrEqual(weapon, "spitter_claw"))
	{
	PrintHintText(client, "The Spitter has coated you with corrosive acid!");
	if(acidswipe[client] <= 0)
	{
	acidswipe[client] = (GetConVarInt(cvarAcidSwipeDuration));
	CreateTimer(1.0, Timer_AcidSwipe, client, TIMER_DATA_HNDL_CLOSE);
	}
	}
	}

//This is the Hook for Bile Swipe - Survivor takes damage over time after being Boomer clawed

	if (isBoomer && isBileSwipe)
	{
	if (IsValidClient(client) && GetClientTeam(client) == 2 && isBileSwipe && StrEqual(weapon, "boomer_claw"))
	{
	PrintHintText(client, "The Boomer has coated you with stomach bile acid!");
	if(bileswipe[client] <= 0)
	{
	bileswipe[client] = (GetConVarInt(cvarBileSwipeDuration));
	CreateTimer(1.0, Timer_BileSwipe, client, TIMER_DATA_HNDL_CLOSE);
	}
	}
	}

//This is the Hook for Ghost Stalker - Chance that when taking damage Jockey will return to Ghost mode

	if (isJockey && isGhostStalker && !isRiding)
	{
	new class = GetEntProp(client, Prop_Send, "m_zombieClass");

	if (class == ZOMBIECLASS_JOCKEY)
	{
	new GhostStalkerChance = GetRandomInt(0, 99);
	new GhostStalkerPercent = (GetConVarInt(cvarGhostStalkerChance));

	if (IsValidClient(client) && !IsPlayerGhost(client) && (GhostStalkerChance < GhostStalkerPercent))
	{
	SDKCall(hBecomeGhost, client, 1);
	SDKCall(hBecomeGhostAt, client, 0);	
	}
	}
	}
}



///Boomer

//This will setup the Bile Feet - Increases the Boomer movement speed

public Action:Event_BoomerBileFeet(Handle:timer, any:client) 
{
	if (IsValidClient(client))
	{
	PrintHintText(client, "Bile Feet has granted you increased movement speed!");
	SetEntDataFloat(client, laggedMovementOffset, 1.0*GetConVarFloat(cvarBileFeetSpeed), true);
	}
}

//This will setup the Bile Mask - Hides the Survivor's HUD when vomited on

public Event_PlayerNotIt (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isBoomer && isBileMask)
	{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));

	if (IsValidClient(client))
	{	
	SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
	}
	}
}

public Action:Timer_BileMask(Handle:timer, any:client) 
{
	if (isBoomer && isBileMask)
	{
	if (IsValidClient(client))
	{	
	SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
	}
	}
}

//This will setup the Bile Shower - Summons a mob when Boomer vomits/explodes on a Survivor

public Event_PlayerNowIt (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isBoomer && isBileShower && !isBileShowerTimeout)
	{
	isBileShowerTimeout = true;
	CreateTimer(GetConVarFloat(cvarBileShowerTimeout), BileShowerTimeout, INVALID_HANDLE, TIMER_DATA_HNDL_CLOSE);
	new client = GetClientOfUserId(GetEventInt(event,"attacker"));
	new flags = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client,"z_spawn mob auto");
	SetCommandFlags("z_spawn", flags|FCVAR_CHEAT);
	}

	if (isBoomer && isBileMask)
	{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));

	if (IsValidClient(client))
	{	
	SetEntProp(client, Prop_Send, "m_iHideHUD", GetConVarInt(cvarBileMaskAmount));
	if (!isBileMaskTilDry)
	{
	CreateTimer(GetConVarFloat(cvarBileMaskDuration), Timer_BileMask, client, TIMER_DATA_HNDL_CLOSE);
	}
	}
	}
}

public Action:BileShowerTimeout(Handle:timer)
{
	isBileShowerTimeout = false;
}

//This will setup the Bile Swipe - Survivor takes damage over time after being Boomer clawed

public Action:Timer_BileSwipe(Handle:timer, any:client) 
{
	if (IsValidClient(client))
	{
	if(bileswipe[client] <= 0) return;

	Damage_BileSwipe(client);
	
	if(bileswipe[client] > 0) 
	{
	CreateTimer(1.0, Timer_BileSwipe, client, TIMER_DATA_HNDL_CLOSE);
	bileswipe[client] -= 1;
	}
	}
}

public Action:Damage_BileSwipe(client)
{
	new String:dmg_str[10];
        new String:dmg_type_str[10];
        IntToString((1 << 25),dmg_str,sizeof(dmg_type_str));
	GetConVarString(FindConVar("l4d_vts_bileswipedamage"), dmg_str, sizeof(dmg_str));
        new pointHurt=CreateEntityByName("point_hurt");
	DispatchKeyValue(client,"targetname","war3_hurtme");
	DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
	DispatchKeyValue(pointHurt,"Damage",dmg_str);
	DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt,"Hurt", client);
	DispatchKeyValue(client,"targetname","war3_donthurtme");
	RemoveEdict(pointHurt);
}



///Charger

//This will setup the Broken Ribs - Deals damage over time after a Charger Pummel has ended

public Event_ChargerPummelEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isCharger && isBrokenRibs)
	{
	new client = GetClientOfUserId(GetEventInt(event,"victim"));

	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
	PrintHintText(client, "The Charger broke your ribs!");
	if(brokenribs[client] <= 0)
	{
	brokenribs[client] = (GetConVarInt(cvarBrokenRibsDuration));
	CreateTimer(1.0, Timer_BrokenRibs, client, TIMER_DATA_HNDL_CLOSE);
	}
	}
	}	
}

public Action:Timer_BrokenRibs(Handle:timer, any:client) 
{
	if (IsValidClient(client))
	{
	if(brokenribs[client] <= 0) return;

	Damage_BrokenRibs(client);
	
	if(brokenribs[client] > 0) 
	{
	CreateTimer(1.0, Timer_BrokenRibs, client, TIMER_DATA_HNDL_CLOSE);
	brokenribs[client] -= 1;
	}
	}
}

public Action:Damage_BrokenRibs(client)
{
	new String:dmg_str[10];
        new String:dmg_type_str[10];
        IntToString((1 << 25),dmg_str,sizeof(dmg_type_str));
	GetConVarString(FindConVar("l4d_vts_brokenribsdamage"), dmg_str, sizeof(dmg_str));
        new pointHurt=CreateEntityByName("point_hurt");
	DispatchKeyValue(client,"targetname","war3_hurtme");
	DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
	DispatchKeyValue(pointHurt,"Damage",dmg_str);
	DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt,"Hurt", client);
	DispatchKeyValue(client,"targetname","war3_donthurtme");
	RemoveEdict(pointHurt);
}

//This will setup the Snapped Leg - Reduces Survivor movement speed if hit during charge
//
public Event_ChargerImpact (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isCharger && isSnappedLeg)
	{
	new client = GetClientOfUserId(GetEventInt(event,"victim"));

	if (IsValidClient(client) && GetClientTeam(client) == 2 && !isSlowed[client])
	{
	isSlowed[client] = true;
	PrintHintText(client, "The Charger's impact has broken your leg!");
	SetEntDataFloat(client, laggedMovementOffset, GetConVarFloat(cvarSnappedLegSpeed), true);
	CreateTimer(GetConVarFloat(cvarSnappedLegDuration), SnappedLeg, client, TIMER_DATA_HNDL_CLOSE);
	}
	}
}	

public Action:SnappedLeg(Handle:timer, any:client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
	SetEntDataFloat(client, laggedMovementOffset, 1.0, true); //sets the survivors speed back to normal
	PrintHintText(client, "Your leg is starting to feel better.");
	isSlowed[client] = false;
	}
}

//This will setup the Stowaway - Damages Survivor based upon amount of time carried

public Event_ChargerCarryStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isCharger && isStowaway)
	{
	new client = GetClientOfUserId(GetEventInt(event,"victim"));

	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
	stowaway[client] = 1;
	isCarried[client] = true;
	CreateTimer(0.5, Timer_Stowaway, client, TIMER_DATA_HNDL_CLOSE);
	}
	}	
}

public Action:Timer_Stowaway(Handle:timer, any:client) 
{
	if (IsValidClient(client))
	{
	if (isCarried[client])
	{
	CreateTimer(0.5, Timer_Stowaway, client, TIMER_DATA_HNDL_CLOSE);
	stowaway[client] += 1;
	}
	}
}

public Event_ChargerCarryEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"victim"));
	new attacker = GetClientOfUserId(GetEventInt(event,"userid"));

	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
	isCarried[client] = false;
	CreateTimer(0.1, Timer_StowawayDamage, client, TIMER_DATA_HNDL_CLOSE);
	new damage = GetConVarInt(cvarStowawayDamage);
	new count = (stowaway[client]*damage);
	PrintHintText(client, "The Charger found a Stowaway and inflicted %i damage for not having a ticket!", count);
	PrintHintText(attacker, "Stowaway: %i damage inflicted!", count);
	}
}

public Action:Timer_StowawayDamage(Handle:timer, any:client) 
{
	if (IsValidClient(client))
	{
	if(stowaway[client] <= 0) return;

	Damage_Stowaway(client);
	
	if(stowaway[client] > 0) 
	{
	CreateTimer(0.1, Timer_StowawayDamage, client, TIMER_DATA_HNDL_CLOSE);
	stowaway[client] -= 1;
	}
	}
}

public Action:Damage_Stowaway(client)
{
	new String:dmg_str[10];
        new String:dmg_type_str[10];
        IntToString((1 << 25),dmg_str,sizeof(dmg_type_str));
	GetConVarString(FindConVar("l4d_vts_stowawaydamage"), dmg_str, sizeof(dmg_str));
        new pointHurt=CreateEntityByName("point_hurt");
	DispatchKeyValue(client,"targetname","war3_hurtme");
	DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
	DispatchKeyValue(pointHurt,"Damage",dmg_str);
	DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt,"Hurt", client);
	DispatchKeyValue(client,"targetname","war3_donthurtme");
	RemoveEdict(pointHurt);
}



///Jockey

//This will setup the Bacterial Infection - Deals damage over time after Jockey Ride ended

public Event_JockeyRideEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isJockey && isBacterial)
	{
	new client = GetClientOfUserId(GetEventInt(event,"victim"));

	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
	PrintHintText(client, "The Jockey has caused a bacterial infection!");
	if(bacterial[client] <= 0)
	{
	bacterial[client] = (GetConVarInt(cvarBacterialDuration));
	CreateTimer(1.0, Timer_Bacterial, client, TIMER_DATA_HNDL_CLOSE);
	}
	}
	}

	if (isJockey && isDerbyDaze)
	{
	new client = GetClientOfUserId( GetEventInt( event, "victim"));

	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{	
	DerbyDaze(client, 0);
	SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
	}
	}

	if (isJockey && isGhostStalker)
	{
	isRiding = false;	
	}
}

public Action:Timer_Bacterial(Handle:timer, any:client) 
{
	if (IsValidClient(client))
	{
	if(bacterial[client] <= 0) 
	{
	return;
	}
	Damage_Bacterial(client);
	
	if(bacterial[client] > 0) 
	{
	CreateTimer(1.0, Timer_Bacterial, client, TIMER_DATA_HNDL_CLOSE);
	bacterial[client] -= 1;
	}
	}
}

public Action:Damage_Bacterial(client)
{
	new String:dmg_str[10];
        new String:dmg_type_str[10];
        IntToString((1 << 25),dmg_str,sizeof(dmg_type_str));
	GetConVarString(FindConVar("l4d_vts_bacterialdamage"), dmg_str, sizeof(dmg_str));
        new pointHurt=CreateEntityByName("point_hurt");
	DispatchKeyValue(client,"targetname","war3_hurtme");
	DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
	DispatchKeyValue(pointHurt,"Damage",dmg_str);
	DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt,"Hurt", client);
	DispatchKeyValue(client,"targetname","war3_donthurtme");
	RemoveEdict(pointHurt);
}

//This will setup Derby Daze - Blindfolds a Survivor during a Jockey ride

public Action:Event_JockeyRideStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	if (isJockey && isDerbyDaze)
	{
	new client = GetClientOfUserId( GetEventInt( event, "victim"));

	if (IsValidClient(client))
	{	
	DerbyDaze(client, GetConVarInt(cvarDerbyDazeAmount));
	SetEntProp(client, Prop_Send, "m_iHideHUD", GetConVarInt(cvarDerbyDazeAmount));
	}
	}

//This will setup Ghost Stalker - Chance that when taking damage Jockey will return to Ghost mode

	if (isJockey && isGhostStalker)
	{
	isRiding = true;	
	}

	return Plugin_Continue;
}

DerbyDaze(client, amount)
{
	new clients[2];
	clients[0] = client;

	DerbyDazeMsgID = GetUserMessageId("Fade");
	new Handle:message = StartMessageEx(DerbyDazeMsgID, clients, 1);
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





///Hunter

//This will setup the Cobra Strike - Chance of incapping or killing a Survivor on Pounce

public Event_PounceStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isHunter && isCobraStrike)
	{
	new client = GetClientOfUserId(GetEventInt(event,"victim"));
	new CobraStrikeChance = GetRandomInt(0, 99);
	new CobraStrikePercent = (GetConVarInt(cvarCobraStrikeChance));

	if (IsValidClient(client) && (CobraStrikeChance < CobraStrikePercent))
	{
	new String:dmg_str[10];
    	new String:dmg_type_str[10];
     	IntToString((1 << 25),dmg_str,sizeof(dmg_type_str));
	GetConVarString(FindConVar("l4d_vts_cobrastrikedamage"), dmg_str, sizeof(dmg_str));
	        new pointHurt=CreateEntityByName("point_hurt");
	DispatchKeyValue(client,"targetname","war3_hurtme");
	DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
	DispatchKeyValue(pointHurt,"Damage",dmg_str);
	DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt,"Hurt", client);
	DispatchKeyValue(client,"targetname","war3_donthurtme");
	RemoveEdict(pointHurt);

	new incapped = GetEntProp(client, Prop_Send, "m_currentReviveCount");
	if (incapped + 1 > cvarCobraStrikeCount){return;}
	
	SetEntProp(client, Prop_Send, "m_currentReviveCount", cvarCobraStrikeCount);
	}
	}
}

//This will setup the Deep Wounds - Deals damage over time after Hunter Pounce ended

public Event_PounceEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isHunter && isDeepWounds)
	{
	new client = GetClientOfUserId(GetEventInt(event,"victim"));

	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
	PrintHintText(client, "The Hunter has inflicted Deep Wounds, you're bleeding!");
	if(deepwounds[client] <= 0)
	{
	deepwounds[client] = (GetConVarInt(cvarDeepWoundsDuration));
	CreateTimer(1.0, Timer_DeepWounds, client, TIMER_DATA_HNDL_CLOSE);
	}
	}
	}	
}

public Action:Timer_DeepWounds(Handle:timer, any:client) 
{
	if (IsValidClient(client))
	{
	if(deepwounds[client] <= 0) 
	{
	return;
	}
	Damage_DeepWounds(client);
	
	if(deepwounds[client] > 0) 
	{
	CreateTimer(1.0, Timer_DeepWounds, client, TIMER_DATA_HNDL_CLOSE);
	deepwounds[client] -= 1;
	}
	}
}

public Action:Damage_DeepWounds(client)
{
	new String:dmg_str[10];
        new String:dmg_type_str[10];
        IntToString((1 << 25),dmg_str,sizeof(dmg_type_str));
	GetConVarString(FindConVar("l4d_vts_deepwoundsdamage"), dmg_str, sizeof(dmg_str));
        new pointHurt=CreateEntityByName("point_hurt");
	DispatchKeyValue(client,"targetname","war3_hurtme");
	DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
	DispatchKeyValue(pointHurt,"Damage",dmg_str);
	DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt,"Hurt", client);
	DispatchKeyValue(client,"targetname","war3_donthurtme");
	RemoveEdict(pointHurt);
}



///Smoker

//This will setup Collapsed Lung - Survivor takes damage over time after Choke End

public Event_ChokeEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isSmoker && isCollapsedLung)
	{
	new client = GetClientOfUserId(GetEventInt(event,"victim"));

	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
	PrintHintText(client, "The Smoker has collapsed your lung!");
	if(collapsedlung[client] <= 0)
	{
	collapsedlung[client] = (GetConVarInt(cvarCollapsedLungDuration));
	CreateTimer(1.0, Timer_CollapsedLung, client, TIMER_DATA_HNDL_CLOSE);
	}
	}
	}
}

public Action:Timer_CollapsedLung(Handle:timer, any:client) 
{
	if (IsValidClient(client))
	{
	if(collapsedlung[client] <= 0) 
	{
	return;
	}
	Damage_CollapsedLung(client);
	
	if(collapsedlung[client] > 0) 
	{
	CreateTimer(1.0, Timer_CollapsedLung, client, TIMER_DATA_HNDL_CLOSE);
	collapsedlung[client] -= 1;
	}
	}
}

public Action:Damage_CollapsedLung(client)
{
	new String:dmg_str[10];
        new String:dmg_type_str[10];
        IntToString((1 << 25),dmg_str,sizeof(dmg_type_str));
	GetConVarString(FindConVar("l4d_vts_collapsedlungdamage"), dmg_str, sizeof(dmg_str));
        new pointHurt=CreateEntityByName("point_hurt");
	DispatchKeyValue(client,"targetname","war3_hurtme");
	DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
	DispatchKeyValue(pointHurt,"Damage",dmg_str);
	DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt,"Hurt", client);
	DispatchKeyValue(client,"targetname","war3_donthurtme");
	RemoveEdict(pointHurt);
}

//This will setup the Moon Walk - Smoker is able to move and drag victims after ensnaring

public Event_TongueGrab (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isSmoker && isMoonWalk)
	{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new Handle:pack;

	if (IsValidClient(client))
	{
	moonwalk[client] = true;
	SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
	SetEntDataFloat(client, laggedMovementOffset, 1.0*GetConVarFloat(cvarMoonWalkSpeed), true);
	MoonWalkTimer[client] = CreateDataTimer(0.2, Timer_MoonWalk, pack, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	WritePackCell(pack, client);
	WritePackCell(pack, victim);
	}
	}
}

public Action:Timer_MoonWalk(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	if ((!IsValidClient(client))||(GetClientTeam(client)!=3)||(moonwalk[client] = false))
	{
	MoonWalkTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
	}
	
	new Victim = ReadPackCell(pack);
	if ((!IsValidClient(Victim))||(GetClientTeam(Victim)!=2)||(moonwalk[client] = false))
	{
	MoonWalkTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
	}
	
	new MoonWalkStretch = GetConVarInt(cvarMoonWalkStretch);
	new Float:SmokerPosition[3];
	new Float:VictimPosition[3];
	GetClientAbsOrigin(client,SmokerPosition);
	GetClientAbsOrigin(Victim,VictimPosition);
	new distance = RoundToNearest(GetVectorDistance(SmokerPosition, VictimPosition));

	if (distance > MoonWalkStretch)
	{
	SlapPlayer(client, 0, false);
	PrintHintText(client, "The Tongue has been stretched/bent and snapped!");
	}

	return Plugin_Continue;
}

public Action:Event_TongueRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isSmoker && isMoonWalk)	
	{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient(client))
	{
	moonwalk[client] = false;
	SetEntityMoveType(client, MOVETYPE_CUSTOM);
	SetEntDataFloat(client, laggedMovementOffset, 1.0, true);
	if (MoonWalkTimer[client] != INVALID_HANDLE)
	{
	CloseHandle(MoonWalkTimer[client]);
	MoonWalkTimer[client] = INVALID_HANDLE;
	}
	}
	}
}


///Spitter

//This will setup the Acid Swipe - Survivor takes damage over time after being Spitter clawed

public Action:Timer_AcidSwipe(Handle:timer, any:client) 
{
	if (IsValidClient(client))
	{
	if(acidswipe[client] <= 0) return;

	Damage_AcidSwipe(client);
	
	if(acidswipe[client] > 0) 
	{
	CreateTimer(1.0, Timer_AcidSwipe, client, TIMER_DATA_HNDL_CLOSE);
	acidswipe[client] -= 1;
	}
	}
}

public Action:Damage_AcidSwipe(client)
{
	new String:dmg_str[10];
        new String:dmg_type_str[10];
        IntToString((1 << 25),dmg_str,sizeof(dmg_type_str));
	GetConVarString(FindConVar("l4d_vts_acidswipedamage"), dmg_str, sizeof(dmg_str));
        new pointHurt=CreateEntityByName("point_hurt");
	DispatchKeyValue(client,"targetname","war3_hurtme");
	DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
	DispatchKeyValue(pointHurt,"Damage",dmg_str);
	DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt,"Hurt", client);
	DispatchKeyValue(client,"targetname","war3_donthurtme");
	RemoveEdict(pointHurt);
}

//This will setup Sticky Goo - Reduce the speed of Survivors if they enter Spit

public Event_EnteredSpit (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isSpitter && isStickyGoo)
	{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (IsValidClient(client) && GetClientTeam(client) == 2 && !isSlowed[client])
	{
	isSlowed[client] = true;
	PrintHintText(client, "Standing in the spit is slowing you down!");
	CreateTimer(GetConVarFloat(cvarStickyGooDuration), StickyGoo, client, TIMER_DATA_HNDL_CLOSE);
	SetEntDataFloat(client, laggedMovementOffset, GetConVarFloat(cvarStickyGooSpeed), true);
	}
	}
}

public Action:StickyGoo(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
	SetEntDataFloat(client, laggedMovementOffset, 1.0, true); //sets the survivors speed back to normal
	PrintHintText(client, "The spit is wearing off!");
	isSlowed[client] = false;
	}
}

//This will setup Supergirl - Makes the Spitter temporarily invulnerable after spitting
public Event_SpitBurst (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isSpitter && isSupergirl)
	{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (IsValidClient(client))
	{
	PrintHintText(client, "You are temporarily invulnerable!");
	CreateTimer(GetConVarFloat(cvarSupergirlDuration), Supergirl, client, TIMER_DATA_HNDL_CLOSE);
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	}
	}
}

public Action:Supergirl(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	PrintHintText(client, "You are no longer invulnerable!");
	}
}



///Tank

//This will setup Burning Rage - Speeds up the Tank when it is on fire

public Action:Timer_BurningRage(Handle:timer, any:client)
{
	if (IsValidClient(client) && IsPlayerOnFire(client) && !isTankOnFire[client])
	{
	isTankOnFire[client] = true;
	PrintHintText(client, "You're on fire, your Burning Rage has increased your speed!");
	SetEntDataFloat(client, laggedMovementOffset, 1.0*GetConVarFloat(cvarBurningRageSpeed), true);

	if (isAnnounce) PrintToChatAll("[SM] The Tank is on fire and his Burning Rage has increased his speed!");
	}

}

//This will setup Culling Swarm - Summons a Panic Event when the Tank has spawned

public Action:Event_TankSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	isATank[client] = true;
	
	if(IsValidClient(client))
	{

	if (isMiniTankSpawn && isMiniHealth)
	{
	isMiniTank[client] = true;
	CreateTimer(3.0, Timer_MiniBodyguard, client, TIMER_DATA_HNDL_CLOSE);
	isMiniTankSpawn = false;
	}

	if (isTank && isBurningRage)
	{
	if (!IsValidClient(client)) {return;}
	BurningRageTimer[client] = CreateTimer(0.5, Timer_BurningRage, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}

	if (isTank && isCullingSwarm && !isMiniTank[client])
	{
	new flags3 = GetCommandFlags("z_spawn");
	new flags4 = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("z_spawn", flags3 & ~FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flags4 & ~FCVAR_CHEAT);
	FakeClientCommand(client, "director_force_panic_event");
	SetCommandFlags("z_spawn", flags3|FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flags4|FCVAR_CHEAT);
	if (isAnnounce) PrintToChatAll("[SM] The Tank has caused a Panic Event!"); 
	}

	if (isTank && isWorriedWife && !isMiniTank[client])
	{
	if (WitchMax <= WitchActive){return;}
	if (WitchMaxMap <= WitchSpawned){return;}
	WitchSpawned = (WitchSpawned + 1);
	WitchActive = (WitchActive + 1);
	if(client == 0){return;}
	new flags3 = GetCommandFlags("z_spawn_old");
	SetCommandFlags("z_spawn_old", flags3 & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", "z_spawn_old", "witch auto");  
	PrintToServer("[Vicious Tank] Witch spawned.");
	SetCommandFlags("z_spawn_old", flags3|FCVAR_CHEAT);
	if (isAnnounce) PrintToChatAll("[SM] A Witch has spawned worried about the Tank!"); 
	}
	}
}

//This will setup Mourning Widow - Summons a Witch after the Tank has been killed

public Action:Event_TankKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidDeadTank(client) && isATank[client])
	{
	isTankOnFire[client] = false;
	isATank[client] = false;

	if (isTank && isMourningWidow && !isMiniTank[client])
	{
	if (WitchMax <= WitchActive){return;}
	if (WitchMaxMap <= WitchSpawned){return;}
	WitchSpawned = (WitchSpawned + 1);
	WitchActive = (WitchActive + 1);
	if(client == 0){return;}
	new flags3 = GetCommandFlags("z_spawn_old");
	SetCommandFlags("z_spawn_old", flags3 & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", "z_spawn_old", "witch auto");  
	PrintToServer("[Vicious Tank] Witch spawned.");
	SetCommandFlags("z_spawn_old", flags3|FCVAR_CHEAT);
	if (isAnnounce) PrintToChatAll("[SM] A Witch has appeared to mourn the tank!");
	}

	if (isMiniTank[client])
	{
	isMiniTank[client] = false;
	TankActive = (TankActive - 1);
	}
	
	if (BurningRageTimer[client] != INVALID_HANDLE)
	{
   	KillTimer(BurningRageTimer[client]);
	BurningRageTimer[client] = INVALID_HANDLE;
	}
	}


}



///Witch

//This will setup Mini Bodyguard - Spawns a low HP Tank when the Witch is killed

public Action:Event_WitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isWitch && isMiniBodyguard)
	{
	if (TankMax <= TankActive){return;}
	if (TankMaxMap <= TankSpawned){return;}
	TankSpawned = (TankSpawned + 1);
	TankActive = (TankActive + 1);
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client == 0){return;}
	isMiniTankSpawn = true;
	new flags2 = GetCommandFlags("z_spawn_old");
	SetCommandFlags("z_spawn_old", flags2 & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", "z_spawn_old", "tank auto");  
	PrintToServer("[Vicious Tank] Mini Tank spawned.");
	SetCommandFlags("z_spawn_old", flags2|FCVAR_CHEAT);

	if (isAnnounce) PrintToChatAll("[SM] A worthless Mini Bodyguard has appeared to protect the Witch!"); 
	}

	WitchActive = (WitchActive - 1);
}

public Action:Timer_MiniBodyguard(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
	new tMiniHP = GetClientHealth(client);
	new Float:tMiniPer = GetConVarFloat(cvarMiniBodyguardHP);
	new tMiniNewHP = RoundToZero(tMiniHP*tMiniPer);

	SetEntProp(client, Prop_Send, "m_iHealth", tMiniNewHP, true);
	}
}

//This will setup Support Group - Spawns a mob when the Witch is angered

public Action:Event_WitchAngered(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isWitch && isSupportGroup)
	{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	new flags = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client,"z_spawn mob auto");
	SetCommandFlags("z_spawn", flags|FCVAR_CHEAT);
	if (isAnnounce) PrintToChatAll("[SM] The Witch's anger management support group has appeared!"); 
	}
}


///Finally we setup some reset variables

public Event_PlayerIncapped (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isJockey && isDerbyDaze)
	{
	new client = GetClientOfUserId( GetEventInt( event, "victim"));

	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{	
	DerbyDaze(client, 0);
	SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
	}
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
	brokenribs[client] = 0;
	bacterial[client] = 0;
	collapsedlung[client] = 0;
	deepwounds[client] = 0;
	isSlowed[client] = false;
	DerbyDaze(client, 0);
	SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
	}
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
	brokenribs[client] = 0;
	bacterial[client] = 0;
	collapsedlung[client] = 0;
	deepwounds[client] = 0;
	isSlowed[client] = false;
	DerbyDaze(client, 0);
	SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
	brokenribs[client] = 0;
	bacterial[client] = 0;
	collapsedlung[client] = 0;
	deepwounds[client] = 0;
	isSlowed[client] = false;
	DerbyDaze(client, 0);
	SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
	}
	isMiniTank[client] = false;
	if (BurningRageTimer[client] != INVALID_HANDLE)
	{
   	KillTimer(BurningRageTimer[client]);
	BurningRageTimer[client] = INVALID_HANDLE;
	}
	isTankOnFire[client] = false;
	TankActive = 0;
	TankSpawned = 0;
	WitchActive = 0;
	WitchSpawned = 0;
}


public IsValidClient(client)
{
	if (client == 0)
	return false;

	if (!IsClientConnected(client))
	return false;
	
	//if (IsFakeClient(client))
	//return false;
	
	if (!IsClientInGame(client))
	return false;
	
	if (!IsPlayerAlive(client))
	return false;

	if (!IsValidEntity(client))
	return false;

	return true;
}

public IsValidDeadTank(client)
{
	if (client == 0)
	return false;

	if (!IsClientConnected(client))
	return false;
	
	//if (IsFakeClient(client))
	//return false;
	
	if (!IsClientInGame(client))
	return false;
	
	if (IsPlayerAlive(client))
	return false;

	if (!IsValidEntity(client))
	return false;

	return true;
}

bool:IsPlayerOnFire(client)
{
	if (IsValidClient(client))
	{
	if (GetEntProp(client, Prop_Data, "m_fFlags") & FL_ONFIRE) return true;
	else return false;
	}
	else return false;
}

public IsPlayerGhost(client)
{
	if (IsValidClient(client))
	{
	if (GetEntProp(client, Prop_Send, "m_isGhost")) return true;
	else return false;
	}
	else return false;
}