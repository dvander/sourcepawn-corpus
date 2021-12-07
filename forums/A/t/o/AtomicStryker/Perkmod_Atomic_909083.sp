/*========================================================================
==========================================================================

						P	E	R	K	M	O	D
						-------------------------
							by tPoncho, aka tP

- version 1.0: Initial release
- version 1.0.1: Changed code for acid vomit with Doku's
- version 1.0.2: Attempted fix for outrageous health values for survivors,
		fix for Double Tap not working on team switches
- version 1.1: Replaced Speed Demon with Grasshopper, included CVars to
		disable perks, fix for various tank perks either not applying or
		applying too many times (double the trouble health multiplier),
		added more info to perk CVars for min and max values allowed,
		added in a CVar to disable plugin adjustments to survivor crawling,
		changing teams to survivors should grant perks
		
- version 1.1A: AtomicStrykers derivation (read: cheap ripoff :P ) with bugfixes and no more Convar changing

- version 1.2: New perk for Boomers - Motion Sickness, boosts movement speed
		and lets you run while vomiting
		
- version 1.2A:
		As above, including Motion Sickness - a convar is changed for the duration of vomiting and then reset
		also, fixed Regenerator - hadn't hooked the menu to actually set it onto the client.
		added burning hunter configurable extra damage
		added new Smoker Replacement Perk, Slingshot Stickytongue

==========================================================================
========================================================================*/



//=============================
// Start
//=============================

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.1A"

//info
public Plugin:myinfo=
{
	name="PerkMod",
	author="tPoncho",
	description="Adds Call Of Duty-style perks for L4D",
	version=PLUGIN_VERSION,
	url=""
}



//=============================
// Declare Global Variables
//=============================

//init player perk vars
new SurvivorUpgrade1[19];	//survivors, primary
new SurvivorUpgrade2[19];	//survivors, secondary
new BoomerUpgrade[19];	//boomer
new TankUpgrade[19];	//tank
new PerksConfirmed[19];	//check if perks are confirmed, to prevent mid-game changing abuses
new SmokerUpgrade[19];	//smoker
new HunterUpgrade[19];	//hunter

//PYROTECHNICIAN PERK
//track how many grenades are carried for pyrotechnician perk
new GrenadesCarried[19];
//used so functions don't confuse legitimate grenade pickups
//with acquisitions from grenadier perk
new GrenadeBeingTossed[19];
//used to track which type of grenade was used;
//1 = pipe, 2 = molotov
new GrenadeType[19];

//SPIRIT PERK
//used to track whether a player is pounced or tongued
//0 = not currently disabled
//1 = disabled by hunter/smoker
new SpiritState[19];
//0 = not incapped
//1 = incapped
new IsIncapped[19];
//used to keep track of whether cooldown is in effect
new SpiritCooldown[19];
//used to track the timers themselves
new Handle:SpiritTimer[19];

//DOUBLE TAP PERK
//used to track who has the double tap perk
//index goes up to 18, but each index has
//a value indicating a client index with DT
//so the plugin doesn't have to cycle a full
//18 times per game frame
new DoubleTapIndex[19] = -1;
//and this tracks how many have DT
new DoubleTapCount = 0;
//this tracks the current active weapon id
//in case the player changes guns
new DoubleTapWeapon[19] = -1;
//this tracks the engine time of the next
//attack for the weapon, after modification
//(modified interval + engine time)
new Float:DoubleTapNextShot[19] = -1.0;

//SLEIGHT OF HAND PERK
//this keeps track of the default values for
//reload speeds for the different shotgun types
//NOTE: I got these values over testing earlier
//and since it's a waste of processing time to
//retrieve these values constantly, we just use
//the pre-retrieved values
const Float:g_flSoHAutoS = 0.416666;
const Float:g_flSoHAutoI = 0.395999;
const Float:g_flSoHAutoE = 1.000000;
const Float:g_flSoHPumpS = 0.393939;
const Float:g_flSoHPumpI = 0.472999;
const Float:g_flSoHPumpE = 0.875000;

//MARTIAL ARTIST PERK
//similar to Double Tap
new MartialIndex[19] = -1;
//and this tracks how many have MA
new MartialCount = 0;

//PACK RAT PERK
//this keeps values of max ammo capacity that
//are calculated on round starts, since this
//perk seems inconsistent in calculating values
//on the fly... =/
new PackRat_SMG;
new PackRat_pumpgun;
new PackRat_m4rifle;
new PackRat_sniper;

new SMG_MaxAmmo;
new Pumpgun_MaxAmmo;
new M4Rifle_MaxAmmo;
new Sniper_MaxAmmo;

//BARF BAGGED PERK
//used to track how many survivors are boomed at a given time
//because spawning a whole mob per player is WAY too many
//also used indirectly to check if someone is currently vomited on
new SlimedCount=0;

//DEAD WRECKENING PERK
//used to track who vomited on a survivor last
new LastBoomer=0;

//VARIOUS HUNTER/SMOKER PERKS
//used to track when a hunter is shredding
//or when a smoker is choking
//0 = not choking/pouncing
//1 = hunter is pouncing, smoker is dragging/choking
new HasGrabbedSomeone[19];

//TANKS
//tracks whether tanks are existent, and what perks have been given
//0 = no tank;
//1 = tank, but no special perks assigned yet;
//2 = tank, juggernaut has been given;
//3 = tank, double trouble has been given;
//4 = frustrated tank with double trouble is being passed to another player;
new TankMode = 0;
new TankBotTicks = 0;	//after 3 ticks, if tank is still a bot then give buffs


//declare vomit fatigue var
new Float:g_flVomitFatigueDefault= -1.0;


//OFFSETS
new g_iHPBuffO			= -1;
new g_iMeleeFatigueO	= -1;
new g_iNextPAttO		= -1;
new g_iNextSAttO		= -1;
new g_iActiveGunO			= -1;
new g_iShotStartDurO	= -1;
new g_iShotInsertDurO	= -1;
new g_iShotEndDurO		= -1;
new g_iPlayRateO		= -1;
new g_iShotReloadStateO	= -1;
new g_iNextAttO			= -1;
new g_iTimeIdleO		= -1;
new g_iLaggedMovementO	= -1;
new	g_iBurnPercentO = -1;



//=============================
// Declare Variables that track
// base L4D ConVars
//=============================

//tracks game difficulty
//0 = easy, normal
//1 = hard/advanced
//2 = impossible/expert
new g_iL4D_Difficulty;

//tracks game mode
//0 = campaign
//1 = survival
//2 = versus
new g_iL4D_GameMode;


//=============================
// Declare Variables Related to
// the Plugin's Own ConVars
//=============================
//first line says the name of the perk
//second line describes how many types there are
//ie:
//"one-size-fits-all" = one variable across all game modes and difficulties
//"versus, non-versus" = one variable for versus games, one for non-versus games
//"normal, hard, expert" = separate variables for normal-versus-survival, advanced and expert


//SUR1 PERKS
//stopping power, damage multiplier
//one-size-fits-all
new Handle:g_hStopping_enable;
new Handle:g_hStopping_enable_sur;
new Handle:g_hStopping_enable_vs;
new Handle:g_hStopping_dmgmult;
//associated var
new g_iStopping_enable;
new g_iStopping_enable_sur;
new g_iStopping_enable_vs;
new Float:g_flStopping_dmgmult;

//spirit, bonus buffer and cooldown
//campaign, survival, versus
new Handle:g_hSpirit_enable;
new Handle:g_hSpirit_enable_sur;
new Handle:g_hSpirit_enable_vs;
new Handle:g_hSpirit_buff;
new Handle:g_hSpirit_cd;
new Handle:g_hSpirit_cd_sur;
new Handle:g_hSpirit_cd_vs;
//associated vars
new g_iSpirit_enable;
new g_iSpirit_enable_sur;
new g_iSpirit_enable_vs;
new g_iSpirit_buff;
new g_iSpirit_cd;
new g_iSpirit_cd_sur;
new g_iSpirit_cd_vs;

//unbreakable, bonus hp
//one-size-fits-all
new Handle:g_hUnbreak_enable;
new Handle:g_hUnbreak_enable_sur;
new Handle:g_hUnbreak_enable_vs;
new Handle:g_hUnbreak_hp;
//associated var
new g_iUnbreak_enable;
new g_iUnbreak_enable_sur;
new g_iUnbreak_enable_vs;
new g_iUnbreak_hp;

//double tap, fire rate
//one-size-fits-all
new Handle:g_hDT_enable;
new Handle:g_hDT_enable_sur;
new Handle:g_hDT_enable_vs;
new Handle:g_hDT_rate;
//associated var
new g_iDT_enable;
new g_iDT_enable_sur;
new g_iDT_enable_vs;
new Float:g_flDT_rate;

//sleight of hand, reload rate
//one-size-fits-all
new Handle:g_hSoH_enable;
new Handle:g_hSoH_enable_sur;
new Handle:g_hSoH_enable_vs;
new Handle:g_hSoH_rate;
//associated var
new g_iSoH_enable;
new g_iSoH_enable_sur;
new g_iSoH_enable_vs;
new Float:g_flSoH_rate;

//pyrotechnician
new Handle:g_hPyro_enable;
new Handle:g_hPyro_enable_sur;
new Handle:g_hPyro_enable_vs;
new g_iPyro_enable;
new g_iPyro_enable_sur;
new g_iPyro_enable_vs;


//SUR2 PERKS
//chem reliant, bonus buffer
//one-size-fits-all
new Handle:g_hChem_enable;
new Handle:g_hChem_enable_sur;
new Handle:g_hChem_enable_vs;
new Handle:g_hChem_buff;
//associated var
new g_iChem_enable;
new g_iChem_enable_sur;
new g_iChem_enable_vs;
new g_iChem_buff;

//helping hand, bonus buffer and time multiplier
//versus, non-versus
new Handle:g_hHelpHand_enable;
new Handle:g_hHelpHand_enable_sur;
new Handle:g_hHelpHand_enable_vs;
new Handle:g_hHelpHand_buff;
new Handle:g_hHelpHand_buff_vs;
//associated vars
new g_iHelpHand_enable;
new g_iHelpHand_enable_sur;
new g_iHelpHand_enable_vs;
new g_iHelpHand_buff;
new g_iHelpHand_buff_vs;

//pack rat, bonus ammo multiplier
//one-size-fits-all
new Handle:g_hPack_enable;
new Handle:g_hPack_enable_sur;
new Handle:g_hPack_enable_vs;
new Handle:g_hPack_ammomult;
//associated var
new g_iPack_enable;
new g_iPack_enable_sur;
new g_iPack_enable_vs;
new Float:g_flPack_ammomult;

//hard to kill, hp multiplier
//one-size-fits-all
new Handle:g_hHard_enable;
new Handle:g_hHard_enable_sur;
new Handle:g_hHard_enable_vs;
new Handle:g_hHard_hpmult;
//associated var
new g_iHard_enable;
new g_iHard_enable_sur;
new g_iHard_enable_vs;
new Float:g_flHard_hpmult;

//martial artist, movement rate
//campaign, non-campaign
new Handle:g_hMA_enable;
new Handle:g_hMA_enable_sur;
new Handle:g_hMA_enable_vs;
new Handle:g_hMA_rate;
new Handle:g_hMA_rate_coop;
//associated var
new g_iMA_enable;
new g_iMA_enable_sur;
new g_iMA_enable_vs;
new Float:g_flMA_rate;
new Float:g_flMA_rate_coop;


//INF1 (BOOMER) PERKS
//acid vomit, bile damage
//one-size-fits-all
new Handle:g_hBlind_enable;
new Handle:BileDamage;
//associated var
new g_iBlind_enable;

//dead wreckening, damage multiplier
//one-size-fits-all
new Handle:g_hDead_enable;
new Handle:g_hDead_dmgmult;
//associated var
new g_iDead_enable;
new Float:g_flDead_dmgmult;

//barf bagged
new Handle:g_hBarf_enable;
new g_iBarf_enable;

//motion sickness
//one-size-fits-all
new Handle:g_hMotion_rate;
new Handle:g_hMotion_enable;
//associated vars
new Float:g_flMotion_rate;
new g_iMotion_enable;


//INF3 (SMOKER) PERKS
//squeezer, bonus damage
//normal, hard, expert
//*used by bots in all modes
new Handle:g_hSqueezer_enable;
new Handle:g_hSqueezer_dmg;
new Handle:g_hSqueezer_dmg_hard;
new Handle:g_hSqueezer_dmg_expert;
//associated var
new g_iSqueezer_enable;
new g_iSqueezer_dmg;
new g_iSqueezer_dmg_hard;
new g_iSqueezer_dmg_expert;

// Regenerator, self healing
new Handle:g_hRegenerator_enable;
new Handle:g_hRegenerator_heal;
new g_iRegenerator_enable;
new g_iRegenerator_heal;

// Slingshot Stickytongue, jerks Survivors over small obstacles
new Handle:g_hSlingshot_enable;
new Handle:g_hSlingshot_force;
new g_iSlingshot_enable;
new g_iSlingshot_force;

//INF4 (HUNTER) PERKS
//body slam, minbound
//one-size-fits-all
new Handle:g_hBody_enable;
new Handle:g_hBody_minbound;
//associated var
new g_iBody_enable;
new g_iBody_minbound;

//efficient killer, bonus damage
//normal, hard, expert
//*used by bots in all modes
new Handle:g_hEfficient_enable;
new Handle:g_hEfficient_dmg;
new Handle:g_hEfficient_dmg_hard;
new Handle:g_hEfficient_dmg_expert;
//associated var
new g_iEfficient_enable;
new g_iEfficient_dmg;
new g_iEfficient_dmg_hard;
new g_iEfficient_dmg_expert;

// fire damage bonus
new Handle:g_hFlamingHunter_enable;
new Handle:g_hFlamingHunter_dmg;
new g_iFlamingHunter_enable;
new g_iFlamingHunter_dmg;

//grasshopper, speed multiplier
//one-size-fits-all
new Handle:g_hGrass_enable;
new Handle:g_hGrass_rate;
//associated var
new g_iGrass_enable;
new Float:g_flGrass_rate;

//old school, bonus damage
//normal, hard, expert
new Handle:g_hOld_enable;
new Handle:g_hOld_dmg;
new Handle:g_hOld_dmg_hard;
new Handle:g_hOld_dmg_expert;
//associated var
new g_iOld_enable;
new g_iOld_dmg;
new g_iOld_dmg_hard;
new g_iOld_dmg_expert;


//INF2 (TANK) PERKS
//adrenal glands, multipliers for punch cooldown,
//throw rock cooldown, and rock travel speed
//one-size-fits-all
new Handle:g_hAdrenal_enable;
//associated vars
new g_iAdrenal_enable;
new Handle:g_flAdrenal_punchdmgmult;

//juggernaut, bonus health
//one-size-fits-all
new Handle:g_hJuggernaut_enable;
new Handle:g_hJuggernaut_hp;
//associated var
new g_iJuggernaut_enable;
new g_iJuggernaut_hp;

//metabolic boost, speed multiplier
//one-size-fits-all
new Handle:g_hMetabolic_enable;
new Handle:g_hMetabolic_speedmult;
//associated var
new g_iMetabolic_enable;
new Float:g_flMetabolic_speedmult;

//storm caller, mobs spawned
//one-size-fits-all
new Handle:g_hStorm_enable;
new Handle:g_hStorm_mobcount;
//associated var
new g_iStorm_enable;
new g_iStorm_mobcount;

//BOT CONTROLLER VARS
//these track the server's preference
//for what perks bots should use
//NOTE: the values these are set at
//ignore whether the perks are actually
//disabled or not!

//sur1
//1 = stopping power
//2 = spirit
new Handle:g_hBot_Sur1;
new g_iBot_Sur1;

//sur2
//1 = chem reliant
//2 = helping hand
//3 = pack rat
//4 = hard to kill
new Handle:g_hBot_Sur2;
new g_iBot_Sur2;

//boomer
//1 = barf bagged
//2 = acid vomit
//3 = dead wreckening
new Handle:g_hBot_Inf1;
new g_iBot_Inf1;

//smoker
//1 = Regenerator
//2 = squeezer

new Handle:g_hBot_Inf3;
new g_iBot_Inf3;

//hunter
//1 = efficient killer
//2 = old school
new Handle:g_hBot_Inf4;
new g_iBot_Inf4;

//tank
//1 = adrenal glands
//2 = juggernaut
//3 = metabolic boost
//4 = storm caller

new Handle:g_hBot_Inf2;
new g_iBot_Inf2;

//DEFAULT PERKS
//These vars track the server's
//given default perks, to account
//for disabling perks

//sur1
new Handle:g_hSur1_default;
new g_iSur1_default;

//sur2
new Handle:g_hSur2_default;
new g_iSur2_default;

//inf1/boomer
new Handle:g_hInf1_default;
new g_iInf1_default;

//inf3/smoker
new Handle:g_hInf3_default;
new g_iInf3_default;

//inf4/hunter
new Handle:g_hInf4_default;
new g_iInf4_default;

//inf2/tank
new Handle:g_hInf2_default;
new g_iInf2_default;



//=============================
// Hooking, Initialize Vars
//=============================

public OnPluginStart()
{
	//Plugin version for online tracking
	CreateConVar("l4d_perkmod_version", PLUGIN_VERSION, "Version of Perkmod for L4D", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	//PERK FUNCTIONS
	//anything here that pertains to the actual
	//workings of the perks (ie, events and timers)

	//hooks for Sur1 perks
	HookEvent("player_hurt", Event_PlayerHurtPre, EventHookMode_Pre);	//stopping power, body slam, efficient killer, squeeze
	HookEvent("infected_hurt", Event_InfectedHurtPre, EventHookMode_Pre);	//stopping power
	HookEvent("item_pickup", Event_ItemPickup);						//pyro, pack rat
	HookEvent("spawner_give_item", Event_ItemPickup);				//pyro, pack rat
	HookEvent("weapon_fire", Event_WeaponFire);						//pyro
	HookEvent("lunge_pounce", Event_PounceLanded);					//spirit, +Inf
	HookEvent("pounce_stopped", Event_PounceStop);					//spirit, +Inf
	HookEvent("player_ledge_grab", Event_LedgeGrab);				//spirit
	HookEvent("player_incapacitated", Event_IncapPre, EventHookMode_Pre);	//spirit
	HookEvent("player_team", Event_PlayerTeam);						//double tap
	HookEvent("weapon_reload", Event_Reload);						//sleight of hand
	HookEvent("heal_success", Event_PlayerHealed);					//unbreakable
	HookEvent("survivor_rescued", Event_PlayerRescued);				//unbreakable
	//hooks for Sur2 perks
	HookEvent("pills_used", Event_PillsUsed, EventHookMode_Pre);	//chem reliant
	HookEvent("revive_success", Event_ReviveSuccess);				//helping hand
	HookEvent("ammo_pickup", Event_AmmoPickup);						//pack rat
	HookEvent("player_use", Event_PlayerUse);						//pack rat
	HookEvent("player_incapacitated", Event_Incap);					//hard to kill
	//hooks for Inf1 perks (boomer)
	HookEvent("player_now_it", Event_PlayerNowIt);					//acid vomit, barf bagged
	HookEvent("ability_use", Event_AbilityUsePre, EventHookMode_Pre);	//motion sickness
	//hooks for Inf3 perks (smoker)
	HookEvent("tongue_grab", Event_TongueGrabPre, EventHookMode_Pre);	//slingshot stickytongue, spirit
	HookEvent("tongue_release", Event_TongueRelease);				//spirit, +Inf
	HookEvent("player_spawn", Event_PlayerSpawn);					//lots of stuff
	//hooks for In4 perks (hunter)
	HookEvent("ability_use", Event_AbilityUse);						//grasshopper
	//hooks for Inf2 perks (tank)
	HookEvent("tank_spawn", Event_Tank_Spawn);						//all tank perks!
	//hooks for misc functions
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);		//check if we need to display menu
	HookEvent("player_transitioned", Event_PlayerTransitioned);		//redisplay perk menu after map change
	HookEvent("player_connect_full", Event_PConnect);				//set initial var values for perks
	HookEvent("player_disconnect", Event_PDisconnect);				//reset var values
	HookEvent("round_start", Event_RoundStart);						//display menu check, reset vars
	HookEvent("player_death", Event_PlayerDeath);					//reset vars
	HookEvent("round_end", Event_RoundEnd);							//unconfirm perks after round ends
	RegConsoleCmd("say", MenuOpen_OnSay);							//open menu if player typed "!perks"
	RegConsoleCmd("say_team", MenuOpen_OnSay);						//open menu if player typed "!perks" in teamchat
	HookConVarChange(FindConVar("z_difficulty"),Convar_Difficulty);	//tracks changes in difficulty
	HookConVarChange(FindConVar("mp_gamemode"),Convar_GameMode);	//tracks changes in game mode
	//debug hooks
	//RegConsoleCmd("say", Debug_OnSay);
	//RegConsoleCmd("say_team", Debug_OnSay);

	g_flVomitFatigueDefault	=	GetConVarFloat(FindConVar("z_vomit_fatigue"));
	
	//get offsets
	g_iHPBuffO			=	FindSendPropOffs("CTerrorPlayer","m_healthBuffer");
	g_iMeleeFatigueO		=	FindSendPropInfo("CTerrorPlayer","m_iShovePenalty");
	g_iNextPAttO			=	FindSendPropInfo("CBaseCombatWeapon","m_flNextPrimaryAttack");
	g_iNextSAttO			=	FindSendPropInfo("CBaseCombatWeapon","m_flNextSecondaryAttack");
	g_iActiveGunO			=	FindSendPropInfo("CBaseCombatCharacter","m_hActiveWeapon");
	g_iShotStartDurO		=	FindSendPropInfo("CBaseShotgun","m_reloadStartDuration");
	g_iShotInsertDurO	=	FindSendPropInfo("CBaseShotgun","m_reloadInsertDuration");
	g_iShotEndDurO		=	FindSendPropInfo("CBaseShotgun","m_reloadEndDuration");
	g_iPlayRateO			=	FindSendPropInfo("CBaseCombatWeapon","m_flPlaybackRate");
	g_iShotReloadStateO	=	FindSendPropInfo("CBaseShotgun","m_reloadState");
	g_iNextAttO			=	FindSendPropInfo("CTerrorPlayer","m_flNextAttack");
	g_iTimeIdleO			=	FindSendPropInfo("CTerrorGun","m_flTimeWeaponIdle");
	g_iLaggedMovementO	=	FindSendPropInfo("CTerrorPlayer","m_flLaggedMovementValue");
	g_iBurnPercentO		=	FindSendPropInfo("CTerrorPlayer", "m_burnPercent");

	//start global timer that
	//forces bots to have some perks
	//among other things
	//Martial Artist, Tongue Twister, Spirit
	CreateTimer(2.0,TimerPerks,0,TIMER_REPEAT);	//martial artist, spirit

	
	//CREATE AND INITIALIZE CONVARS
	//everything related to the convars that adjust
	//certain values for the perks

	CreateConvars();

	//finally, run a command to exec the .cfg file
	//to load the server's preferences for these cvars
	AutoExecConfig(true , "perkmod");

}

//just to give me a bit less of a headache,
//all convar creation is called here
CreateConvars()
{
	//stopping power
	g_hStopping_dmgmult = CreateConVar(
		"l4d_perkmod_stoppingpower_damagemultiplier" ,
		"0.3" ,
		"Stopping Power perk: Bonus damage multiplier, ADDED to base damage (clamped between 0.05 < 1.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hStopping_dmgmult, Convar_Stopping);
	g_flStopping_dmgmult = 0.3;

	g_hStopping_enable = CreateConVar(
		"l4d_perkmod_stoppingpower_enable" ,
		"1" ,
		"Stopping Power perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hStopping_enable, Convar_Stopping_en);
	g_iStopping_enable = 1;

	g_hStopping_enable_sur = CreateConVar(
		"l4d_perkmod_stoppingpower_enable_survival" ,
		"1" ,
		"Stopping Power perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hStopping_enable_sur, Convar_Stopping_en_sur);
	g_iStopping_enable_sur = 1;

	g_hStopping_enable_vs = CreateConVar(
		"l4d_perkmod_stoppingpower_enable_versus" ,
		"1" ,
		"Stopping Power perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hStopping_enable_vs, Convar_Stopping_en_vs);
	g_iStopping_enable_vs = 1;

	//pyrotechnician
	g_hPyro_enable = CreateConVar(
		"l4d_perkmod_pyrotechnician_enable" ,
		"1" ,
		"Pyrotechnician perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hPyro_enable, Convar_Pyro_en);
	g_iPyro_enable = 1;

	g_hPyro_enable_sur = CreateConVar(
		"l4d_perkmod_pyrotechnician_enable_survival" ,
		"1" ,
		"Pyrotechnician perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hPyro_enable_sur, Convar_Pyro_en_sur);
	g_iPyro_enable_sur = 1;

	g_hPyro_enable_vs = CreateConVar(
		"l4d_perkmod_pyrotechnician_enable_versus" ,
		"1" ,
		"Pyrotechnician perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hPyro_enable_vs, Convar_Pyro_en_vs);
	g_iPyro_enable_vs = 1;

	//spirit
	g_hSpirit_buff = CreateConVar(
		"l4d_perkmod_spirit_bonusbuffer" ,
		"30" ,
		"Spirit perk: Bonus health buffer on self-revive (clamped between 0 < 170)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSpirit_buff, Convar_SpiritBuff);
	g_iSpirit_buff=				30;

	g_hSpirit_cd = CreateConVar(
		"l4d_perkmod_spirit_cooldown" ,
		"540" ,
		"Spirit perk: Cooldown for self-reviving in seconds, campaign (clamped between 1 < 1800)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSpirit_cd, Convar_SpiritCD);
	g_iSpirit_cd=				540;

	g_hSpirit_cd_sur = CreateConVar(
		"l4d_perkmod_spirit_cooldown_sur" ,
		"210" ,
		"Spirit perk: Cooldown for self-reviving in seconds, survival (clamped between 1 < 1800)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSpirit_cd_sur, Convar_SpiritCDsur);
	g_iSpirit_cd_sur=			210;

	g_hSpirit_cd_vs = CreateConVar(
		"l4d_perkmod_spirit_cooldown_vs" ,
		"210" ,
		"Spirit perk: Cooldown for self-reviving in seconds, versus (clamped between 1 < 1800)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSpirit_cd_vs, Convar_SpiritCDvs);
	g_iSpirit_cd_vs=			210;

	g_hSpirit_enable = CreateConVar(
		"l4d_perkmod_spirit_enable" ,
		"1" ,
		"Spirit perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSpirit_enable, Convar_Spirit_en);
	g_iSpirit_enable = 1;

	g_hSpirit_enable_sur = CreateConVar(
		"l4d_perkmod_spirit_enable_survival" ,
		"1" ,
		"Spirit perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSpirit_enable_sur, Convar_Spirit_en_sur);
	g_iSpirit_enable_sur = 1;

	g_hSpirit_enable_vs = CreateConVar(
		"l4d_perkmod_spirit_enable_versus" ,
		"1" ,
		"Spirit perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSpirit_enable_vs, Convar_Spirit_en_vs);
	g_iSpirit_enable_vs = 1;

	//double tap
	g_hDT_rate = CreateConVar(
		"l4d_perkmod_doubletap_rate" ,
		"0.6667" ,
		"Double Tap perk: The interval between bullets fired is multiplied by this value. NOTE: a short enough interval will make the gun fire at only normal speed! (clamped between 0.2 < 0.9)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hDT_rate, Convar_DT);
	g_flDT_rate=			0.6667;

	g_hDT_enable = CreateConVar(
		"l4d_perkmod_doubletap_enable" ,
		"1" ,
		"Double Tap perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hDT_enable, Convar_DT_en);
	g_iDT_enable = 1;

	g_hDT_enable_sur = CreateConVar(
		"l4d_perkmod_doubletap_enable_survival" ,
		"1" ,
		"Double Tap perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hDT_enable_sur, Convar_DT_en_sur);
	g_iDT_enable_sur = 1;

	g_hDT_enable_vs = CreateConVar(
		"l4d_perkmod_doubletap_enable_versus" ,
		"1" ,
		"Double Tap perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hDT_enable_vs, Convar_DT_en_vs);
	g_iDT_enable_vs = 1;

	//sleight of hand
	g_hSoH_rate = CreateConVar(
		"l4d_perkmod_sleightofhand_rate" ,
		"0.4" ,
		"Sleight of Hand perk: The interval incurred by reloading is multiplied by this value (clamped between 0.2 < 0.9)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSoH_rate, Convar_SoH);
	g_flSoH_rate=			0.4;

	g_hSoH_enable = CreateConVar(
		"l4d_perkmod_sleightofhand_enable" ,
		"1" ,
		"Sleight of Hand perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSoH_enable, Convar_SoH_en);
	g_iSoH_enable = 1;

	g_hSoH_enable_sur = CreateConVar(
		"l4d_perkmod_sleightofhand_enable_survival" ,
		"1" ,
		"Sleight of Hand perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSoH_enable_sur, Convar_SoH_en_sur);
	g_iSoH_enable_sur = 1;

	g_hSoH_enable_vs = CreateConVar(
		"l4d_perkmod_sleightofhand_enable_versus" ,
		"1" ,
		"Sleight of Hand perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSoH_enable_vs, Convar_SoH_en_vs);
	g_iSoH_enable_vs = 1;

	//unbreakable
	g_hUnbreak_hp = CreateConVar(
		"l4d_perkmod_unbreakable_bonushealth" ,
		"30" ,
		"Unbreakable perk: Bonus health given for Unbreakable (clamped between 1 < 100)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hUnbreak_hp, Convar_Unbreak);
	g_iUnbreak_hp = 30;

	g_hUnbreak_enable = CreateConVar(
		"l4d_perkmod_unbreakable_enable" ,
		"1" ,
		"Unbreakable perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hUnbreak_enable, Convar_Unbreak_en);
	g_iUnbreak_enable = 1;

	g_hUnbreak_enable_sur = CreateConVar(
		"l4d_perkmod_unbreakable_enable_survival" ,
		"1" ,
		"Unbreakable perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hUnbreak_enable_sur, Convar_Unbreak_en_sur);
	g_iUnbreak_enable_sur = 1;

	g_hUnbreak_enable_vs = CreateConVar(
		"l4d_perkmod_unbreakable_enable_versus" ,
		"1" ,
		"Unbreakable perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hUnbreak_enable_vs, Convar_Unbreak_en_vs);
	g_iUnbreak_enable_vs = 1;

	//chem reliant
	g_hChem_buff = CreateConVar(
		"l4d_perkmod_chemreliant_bonusbuffer" ,
		"20" ,
		"Chem Reliant perk: Bonus health buffer given when taking pills (clamped between 1 < 150)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hChem_buff, Convar_Chem);
	g_iChem_buff = 20;

	g_hChem_enable = CreateConVar(
		"l4d_perkmod_chemreliant_enable" ,
		"1" ,
		"Chem Reliant perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hChem_enable, Convar_Chem_en);
	g_iChem_enable = 1;

	g_hChem_enable_sur = CreateConVar(
		"l4d_perkmod_chemreliant_enable_survival" ,
		"1" ,
		"Chem Reliant perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hChem_enable_sur, Convar_Chem_en_sur);
	g_iChem_enable_sur = 1;

	g_hChem_enable_vs = CreateConVar(
		"l4d_perkmod_chemreliant_enable_versus" ,
		"1" ,
		"Chem Reliant perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hChem_enable_vs, Convar_Chem_en_vs);
	g_iChem_enable_vs = 1;


	g_hHelpHand_buff = CreateConVar(
		"l4d_perkmod_helpinghand_bonusbuffer" ,
		"40" ,
		"Helping Hand perk: Bonus health buffer given to allies after reviving them, campaign/survival (clamped between 0 < 170)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hHelpHand_buff, Convar_HelpBuff);
	g_iHelpHand_buff = 40;

	g_hHelpHand_buff_vs = CreateConVar(
		"l4d_perkmod_helpinghand_bonusbuffer_vs" ,
		"10" ,
		"Helping Hand perk: Bonus health buffer given to allies after reviving them, versus (clamped between 0 < 170)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hHelpHand_buff_vs, Convar_HelpBuffvs);
	g_iHelpHand_buff_vs = 10;

	g_hHelpHand_enable = CreateConVar(
		"l4d_perkmod_helpinghand_enable" ,
		"1" ,
		"Helping Hand perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hHelpHand_enable, Convar_Help_en);
	g_iHelpHand_enable = 1;

	g_hHelpHand_enable_sur = CreateConVar(
		"l4d_perkmod_helpinghand_enable_survival" ,
		"1" ,
		"Helping Hand perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hHelpHand_enable_sur, Convar_Help_en_sur);
	g_iHelpHand_enable_sur = 1;

	g_hHelpHand_enable_vs = CreateConVar(
		"l4d_perkmod_helpinghand_enable_versus" ,
		"1" ,
		"Helping Hand perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hHelpHand_enable_vs, Convar_Help_en_vs);
	g_iHelpHand_enable_vs = 1;

	//pack rat
	g_hPack_ammomult = CreateConVar(
		"l4d_perkmod_packrat_ammomultiplier" ,
		"0.4" ,
		"Pack Rat perk: Bonus ammo capacity, ADDED to base capacity (clamped between 0.01 < 1.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hPack_ammomult, Convar_Pack);
	g_flPack_ammomult = 0.4;

	g_hPack_enable = CreateConVar(
		"l4d_perkmod_packrat_enable" ,
		"1" ,
		"Pack Rat perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hPack_enable, Convar_Pack_en);
	g_iPack_enable = 1;

	g_hPack_enable_sur = CreateConVar(
		"l4d_perkmod_packrat_enable_survival" ,
		"1" ,
		"Pack Rat perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hPack_enable_sur, Convar_Pack_en_sur);
	g_iPack_enable_sur = 1;

	g_hPack_enable_vs = CreateConVar(
		"l4d_perkmod_packrat_enable_versus" ,
		"1" ,
		"Pack Rat perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hPack_enable_vs, Convar_Pack_en_vs);
	g_iPack_enable_vs = 1;

	//hard to kill
	g_hHard_hpmult = CreateConVar(
		"l4d_perkmod_hardtokill_healthmultiplier" ,
		"1.0" ,
		"Hard to Kill perk: Bonus incap health multiplier, product is ADDED to base incap health (clamped between 0.01 < 3.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hHard_hpmult, Convar_Hard);
	g_flHard_hpmult = 1.0;

	g_hHard_enable = CreateConVar(
		"l4d_perkmod_hardtokill_enable" ,
		"1" ,
		"Hard to Kill perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hHard_enable, Convar_Hard_en);
	g_iHard_enable = 1;

	g_hHard_enable_sur = CreateConVar(
		"l4d_perkmod_hardtokill_enable_survival" ,
		"1" ,
		"Hard to Kill perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hHard_enable_sur, Convar_Hard_en_sur);
	g_iHard_enable_sur = 1;

	g_hHard_enable_vs = CreateConVar(
		"l4d_perkmod_hardtokill_enable_versus" ,
		"1" ,
		"Hard to Kill perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hHard_enable_vs, Convar_Hard_en_vs);
	g_iHard_enable_vs = 1;

	//martial artist
	g_hMA_rate = CreateConVar(
		"l4d_perkmod_martialartist_rate" ,
		"1.1" ,
		"Martial Artist perk: Movement rate is multiplied by this value (clamped between 0.0 < 0.5)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hMA_rate, Convar_MA);
	g_flMA_rate=			1.1;

	g_hMA_rate_coop = CreateConVar(
		"l4d_perkmod_martialartist_rate_coop" ,
		"1.2" ,
		"Martial Artist perk: Movement rate is multiplied by this value, campaign only" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hMA_rate_coop, Convar_MA_coop);
	g_flMA_rate_coop=			1.2;

	g_hMA_enable = CreateConVar(
		"l4d_perkmod_martialartist_enable" ,
		"1" ,
		"Martial Artist perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hMA_enable, Convar_MA_en);
	g_iMA_enable = 1;

	g_hMA_enable_sur = CreateConVar(
		"l4d_perkmod_martialartist_enable_survival" ,
		"1" ,
		"Martial Artist perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hMA_enable_sur, Convar_MA_en_sur);
	g_iMA_enable_sur = 1;

	g_hMA_enable_vs = CreateConVar(
		"l4d_perkmod_martialartist_enable_versus" ,
		"1" ,
		"Martial Artist perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hMA_enable_vs, Convar_MA_en_vs);
	g_iMA_enable_vs = 1;

	//barf bagged
	g_hBarf_enable = CreateConVar(
		"l4d_perkmod_barfbagged_enable" ,
		"1" ,
		"Barf Bagged perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hBarf_enable, Convar_Barf_en);
	g_iBarf_enable = 1;

	//acid vomit
	BileDamage = CreateConVar(
		"l4d_perkmod_blindluck_biledamage" ,
		"5.0" ,
		"Acid Vomit perk: Bile deals that much damage" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(BileDamage, Convar_BileDamage_change);

	g_hBlind_enable = CreateConVar(
		"l4d_perkmod_blindluck_enable" ,
		"1" ,
		"acid vomit perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hBlind_enable, Convar_Blind_en);
	g_iBlind_enable = 1;

	//dead wreckening
	g_hDead_dmgmult = CreateConVar(
		"l4d_perkmod_deadwreckening_damagemultiplier" ,
		"0.5" ,
		"Dead Wreckening perk: Common infected damage is multiplied by this value and ADDED to their base damage (clamped between 0.01 < 4.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hDead_dmgmult, Convar_Dead);
	g_flDead_dmgmult = 0.5;

	g_hDead_enable = CreateConVar(
		"l4d_perkmod_deadwreckening_enable" ,
		"1" ,
		"Dead Wreckening perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hDead_enable, Convar_Dead_en);
	g_iDead_enable = 1;
	
	//motion sickness
	g_hMotion_rate = CreateConVar(
		"l4d_perkmod_motionsickness_rate" ,
		"1.25" ,
		"Motion Sickness perk: Boomer movement is multiplied by this value (clamped between 1.0 < 4.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hMotion_rate, Convar_Motion);
	g_flMotion_rate = 1.25;

	g_hMotion_enable = CreateConVar(
		"l4d_perkmod_motionsickness_enable" ,
		"1" ,
		"Motion Sickness perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hMotion_enable, Convar_Motion_en);
	g_iMotion_enable = 1;

	//squeezer
	g_hSqueezer_dmg = CreateConVar(
		"l4d_perkmod_squeezer_dmg" ,
		"3" ,
		"Squeezer perk: Drag and choke bonus damage; campaign (easy/normal), versus, survival (clamped between 1 < 100)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSqueezer_dmg, Convar_Squeezer);
	g_iSqueezer_dmg = 3;

	g_hSqueezer_dmg_hard = CreateConVar(
		"l4d_perkmod_squeezer_dmg_hard" ,
		"6" ,
		"Squeezer perk: Drag and choke bonus damage; campaign (advanced) (clamped between 1 < 100)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSqueezer_dmg_hard, Convar_SqueezerHard);
	g_iSqueezer_dmg_hard = 6;

	g_hSqueezer_dmg_expert = CreateConVar(
		"l4d_perkmod_squeezer_dmg_expert" ,
		"12" ,
		"Squeezer perk: Drag and choke bonus damage; campaign (expert) (clamped between 1 < 100)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSqueezer_dmg_expert, Convar_SqueezerExpert);
	g_iSqueezer_dmg_expert = 12;

	g_hSqueezer_enable = CreateConVar(
		"l4d_perkmod_squeezer_enable" ,
		"1" ,
		"Squeezer perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSqueezer_enable, Convar_Squeezer_en);
	g_iSqueezer_enable = 1;
	
	//regenerator
	g_hRegenerator_heal = CreateConVar(
		"l4d_perkmod_regenerator_dmg" ,
		"40" ,
		"Regenerator perk: Heal by this amount every 2 seconds" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hRegenerator_heal, Convar_Regenerator);
	g_iRegenerator_heal = 40;
	
	g_hRegenerator_enable = CreateConVar(
		"l4d_perkmod_regenerator_enable" ,
		"1" ,
		"Regenerator perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hRegenerator_enable, Convar_Regenerator_en);
	g_iRegenerator_enable = 1;

	//slingshot stickytongue
	g_hSlingshot_force = CreateConVar(
		"l4d_perkmod_slingshot_force" ,
		"200" ,
		"Slingshot Stickytongue perk: Pull Jerk has this much force" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSlingshot_force, Convar_Slingshot);
	g_iSlingshot_force = 200;
	
	g_hSlingshot_enable = CreateConVar(
		"l4d_perkmod_slingshot_enable" ,
		"1" ,
		"Slingshot Stickytongue perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSlingshot_enable, Convar_Slingshot_en);
	g_iSlingshot_enable = 1;
	
	//body slam
	g_hBody_minbound = CreateConVar(
		"l4d_perkmod_bodyslam_minbound" ,
		"9" ,
		"Body Slam perk: Defines the minimum initial damage dealt by a pounce (clamped between 2 < 100)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hBody_minbound, Convar_Body);
	g_iBody_minbound = 9;

	g_hBody_enable = CreateConVar(
		"l4d_perkmod_bodyslam_enable" ,
		"1" ,
		"Body Slam perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hBody_enable, Convar_Body_en);
	g_iBody_enable = 1;

	//efficient killer
	g_hEfficient_dmg = CreateConVar(
		"l4d_perkmod_efficientkiller_damage" ,
		"2" ,
		"Efficient Killer perk: Bonus shred damage after a successful pounce; campaign (easy/normal), survival, versus (clamped between 1 < 100)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hEfficient_dmg, Convar_Eff);
	g_iEfficient_dmg = 2;

	g_hEfficient_dmg_hard = CreateConVar(
		"l4d_perkmod_efficientkiller_damage_hard" ,
		"4" ,
		"Efficient Killer perk: Bonus shred damage after a successful pounce; campaign (hard) (clamped between 1 < 100)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hEfficient_dmg_hard, Convar_Effhard);
	g_iEfficient_dmg_hard = 4;

	g_hEfficient_dmg_expert = CreateConVar(
		"l4d_perkmod_efficientkiller_damage_expert" ,
		"8" ,
		"Efficient Killer perk: Bonus shred damage after a successful pounce; campaign (expert) (clamped between 1 < 100)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hEfficient_dmg_expert, Convar_Effexpert);
	g_iEfficient_dmg_expert = 8;

	g_hEfficient_enable = CreateConVar(
		"l4d_perkmod_efficientkiller_enable" ,
		"1" ,
		"Efficient Killer perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hEfficient_enable, Convar_Eff_en);
	g_iEfficient_enable = 1;
	
	g_hFlamingHunter_enable = CreateConVar(
		"l4d_perkmod_flaminghunter_enable" ,
		"1" ,
		"Burning Hunters Extra Damage Coding, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hFlamingHunter_enable, Convar_FlamingHunter_en);
	g_iFlamingHunter_enable = 1;
	
	g_hFlamingHunter_dmg = CreateConVar(
		"l4d_perkmod_flaminghunter_damage" ,
		"4" ,
		"Burning Hunter Code: Bonus shred damage each shred while burning (clamped between 1 < 100)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hFlamingHunter_dmg, Convar_FlamingHunter);
	g_iFlamingHunter_dmg = 4;

	//grasshopper
	g_hGrass_rate = CreateConVar(
		"l4d_perkmod_grasshopper_rate" ,
		"1.2" ,
		"Grasshopper perk: Multiplier for time rate (clamped between 1.0 < 3.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hGrass_rate, Convar_Grass);
	g_flGrass_rate = 1.2;

	g_hGrass_enable = CreateConVar(
		"l4d_perkmod_grasshopper_enable" ,
		"1" ,
		"Grasshopper perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hGrass_enable, Convar_Grass_en);
	g_iGrass_enable = 1;

	//old school
	g_hOld_dmg = CreateConVar(
		"l4d_perkmod_oldschool_damage" ,
		"4" ,
		"Old School perk: Bonus claw damage; campaign (easy/normal), survival, versus (clamped between 1 < 100)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hOld_dmg, Convar_Old);
	g_iOld_dmg = 4;

	g_hOld_dmg_hard = CreateConVar(
		"l4d_perkmod_oldschool_damage_hard" ,
		"8" ,
		"Old School perk: Bonus claw damage; campaign (advanced) (clamped between 1 < 100)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hOld_dmg_hard, Convar_Oldhard);
	g_iOld_dmg_hard = 8;

	g_hOld_dmg_expert = CreateConVar(
		"l4d_perkmod_oldschool_damage_expert" ,
		"16" ,
		"Old School perk: Bonus claw damage; campaign (expert) (clamped between 1 < 100)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hOld_dmg_expert, Convar_Oldexpert);
	g_iOld_dmg_hard = 16;

	g_hOld_enable = CreateConVar(
		"l4d_perkmod_oldschool_enable" ,
		"1" ,
		"Old School perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hOld_enable, Convar_Old_en);
	g_iOld_enable = 1;

	//adrenal glands
	g_flAdrenal_punchdmgmult = CreateConVar(
		"l4d_perkmod_adrenalglands_punchextradamagemulti" ,
		"1.5" ,
		"Adrenal Glands perk: Punch Damage is multiplied by this value (clamped between 1.00 < 5.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_flAdrenal_punchdmgmult, Convar_Adrenalpunchdmgmult);

	g_hAdrenal_enable = CreateConVar(
		"l4d_perkmod_adrenalglands_enable" ,
		"1" ,
		"Adrenal Glands perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hAdrenal_enable, Convar_Adrenal_en);
	g_iAdrenal_enable = 1;

	//juggernaut
	g_hJuggernaut_hp = CreateConVar(
		"l4d_perkmod_juggernaut_health" ,
		"3000" ,
		"Juggernaut perk: Bonus health given to tanks; absolute value (clamped between 1 < 99999)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hJuggernaut_hp, Convar_Jugg);
	g_iJuggernaut_hp = 3000;

	g_hJuggernaut_enable = CreateConVar(
		"l4d_perkmod_juggernaut_enable" ,
		"1" ,
		"Juggernaut perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hJuggernaut_enable, Convar_Jugg_en);
	g_iJuggernaut_enable = 1;

	//metabolic boost
	g_hMetabolic_speedmult = CreateConVar(
		"l4d_perkmod_metabolicboost_speedmultiplier" ,
		"1.2" ,
		"Metabolic Boost perk: Run speed multiplier (clamped between 1.01 < 3.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hMetabolic_speedmult, Convar_Met);
	g_flMetabolic_speedmult = 1.2;

	g_hMetabolic_enable = CreateConVar(
		"l4d_perkmod_metabolicboost_enable" ,
		"1" ,
		"Metabolic Boost perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hMetabolic_enable, Convar_Met_en);
	g_iMetabolic_enable = 1;

	//storm caller
	g_hStorm_mobcount = CreateConVar(
		"l4d_perkmod_stormcaller_mobcount" ,
		"3" ,
		"Storm Caller perk: How many groups of zombies are spawned (clamped between 1 < 10)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hStorm_mobcount, Convar_Storm);
	g_iStorm_mobcount = 3;

	g_hStorm_enable = CreateConVar(
		"l4d_perkmod_stormcaller_enable" ,
		"1" ,
		"Storm Caller perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hStorm_enable, Convar_Storm_en);
	g_iStorm_enable = 1;

	//bot preferences for perks
	g_hBot_Sur1 = CreateConVar(
		"l4d_perkmod_bot_survivor1" ,
		"2" ,
		"Bot preferences for Survivor 1 perks: 1 = stopping power, 2 = spirit" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hBot_Sur1, Convar_Sur1);
	g_iBot_Sur1 = 3;

	g_hBot_Sur2 = CreateConVar(
		"l4d_perkmod_bot_survivor2" ,
		"4" ,
		"Bot preferences for Survivor 2 perks: 1 = chem reliant, 2 = helping hand, 3 = pack rat, 4 = hard to kill" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hBot_Sur2, Convar_Sur2);
	g_iBot_Sur2 = 5;

	g_hBot_Inf1 = CreateConVar(
		"l4d_perkmod_bot_boomer" ,
		"1" ,
		"Bot preferences for boomer perks: 1 = barf bagged, 2 = acid vomit, 3 = dead wreckening" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hBot_Inf1, Convar_Inf1);
	g_iBot_Inf1 = 1;

	g_hBot_Inf3 = CreateConVar(
		"l4d_perkmod_bot_smoker" ,
		"2" ,
		"Bot preferences for smoker perks: 1 = regenerator, 2 = squeezer" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hBot_Inf3, Convar_Inf3);
	g_iBot_Inf3 = 2;

	g_hBot_Inf4 = CreateConVar(
		"l4d_perkmod_bot_hunter" ,
		"1" ,
		"Bot preferences for hunter perks: 1 = efficient killer, 2 = old school" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hBot_Inf4, Convar_Inf4);
	g_iBot_Inf4 = 2;

	g_hBot_Inf2 = CreateConVar(
		"l4d_perkmod_bot_tank" ,
		"2" ,
		"Bot preferences for tank perks: 1 = adrenal glands, 2 = juggernaut, 3 = metabolic boost, 4 = storm caller" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hBot_Inf2, Convar_Inf2);
	g_iBot_Inf2 = 2;

	//default perks
	g_hSur1_default = CreateConVar(
		"l4d_perkmod_default_survivor1" ,
		"1" ,
		"Default selected perk for Survivor, Primary: 1 = stopping power, 2 = pyrotechnician, 3 = spirit, 4 = double tap, 5 = unbreakable, 6 = sleight of hand" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSur1_default, Convar_Def_Sur1);
	g_iSur1_default = 1;

	g_hSur2_default = CreateConVar(
		"l4d_perkmod_default_survivor2" ,
		"5" ,
		"Default selected perk for Survivor, Secondary: 1 = chem reliant, 2 = helping hand, 3 = pack rat, 4 = martial artist, 5 = hard to kill" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSur2_default, Convar_Def_Sur2);
	g_iSur2_default = 5;

	g_hInf1_default = CreateConVar(
		"l4d_perkmod_default_boomer" ,
		"1" ,
		"Default selected perk for Boomer: 1 = barf bagged, 2 = acid vomit, 3 = dead wreckening" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hInf1_default, Convar_Def_Inf1);
	g_iInf1_default = 1;

	g_hInf2_default = CreateConVar(
		"l4d_perkmod_default_tank" ,
		"2" ,
		"Default selected perk for Tank: 1 = adrenal glands, 2 = juggernaut, 3 = metabolic boost, 4 = storm caller" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hInf2_default, Convar_Def_Inf2);
	g_iInf2_default = 2;

	g_hInf3_default = CreateConVar(
		"l4d_perkmod_default_smoker" ,
		"2" ,
		"Default selected perk for Smoker: 1 = regenerator, 2 = squeezer",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hInf3_default, Convar_Def_Inf3);
	g_iInf3_default = 2;

	g_hInf4_default = CreateConVar(
		"l4d_perkmod_default_hunter" ,
		"1" ,
		"Default selected perk for Hunter: 1 = body slam, 2 = efficient killer, 3 = grasshopper, 4 = old school" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hInf4_default, Convar_Def_Inf4);
	g_iInf4_default = 1;
}
//=============================
// ConVar Changes
//=============================


//changes in base L4D convars
//---------------------------

//tracks changes in game difficulty
public Convar_Difficulty (Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(newValue,"hard",false)==true)
		g_iL4D_Difficulty=1;
	else if (StrEqual(newValue,"impossible",false)==true)
		g_iL4D_Difficulty=2;
	else
		g_iL4D_Difficulty=0;

	//----DEBUG----
	//PrintToChatAll("\x03difficulty change detected, new value: \x01%i",g_iL4D_Difficulty);
}

//tracks changes in game mode
public Convar_GameMode (Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(newValue,"versus",false)==true)
		g_iL4D_GameMode=2;
	else if (StrEqual(newValue,"survival",false)==true)
		g_iL4D_GameMode=1;
	else
		g_iL4D_GameMode=0;

	//----DEBUG----
	//PrintToChatAll("\x03gamemode change detected, new value: \x01%i",g_iL4D_GameMode);
}


//changes in perkmod convars
//---------------------------

//stopping power
public Convar_Stopping (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.05)
		flF=0.05;
	else if (flF>1.0)
		flF=1.0;
	g_flStopping_dmgmult = flF;
}

public Convar_Stopping_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iStopping_enable = i;
}

public Convar_Stopping_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iStopping_enable_sur = i;
}

public Convar_Stopping_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iStopping_enable_vs = i;
}

//spirit
public Convar_SpiritBuff (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<0)
		i=0;
	else if (i>170)
		i=170;
	g_iSpirit_buff = i;
}

public Convar_SpiritCD (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>1800)
		i=1800;
	g_iSpirit_cd = i;
}

public Convar_SpiritCDsur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>1800)
		i=1800;
	g_iSpirit_cd_sur = i;
}

public Convar_SpiritCDvs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>1800)
		i=1800;
	g_iSpirit_cd_vs = i;
}

public Convar_Spirit_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iSpirit_enable = i;
}

public Convar_Spirit_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iSpirit_enable_sur = i;
}

public Convar_Spirit_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iSpirit_enable_vs = i;
}

public Convar_HelpBuff (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>170)
		i=170;
	g_iHelpHand_buff = i;
}

public Convar_HelpBuffvs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>170)
		i=170;
	g_iHelpHand_buff_vs = i;
}

public Convar_Help_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iHelpHand_enable = i;
}

public Convar_Help_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iHelpHand_enable_sur = i;
}

public Convar_Help_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iHelpHand_enable_vs = i;
}

//unbreakable
public Convar_Unbreak (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>100)
		i=100;
	g_iUnbreak_hp = i;
}

public Convar_Unbreak_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iUnbreak_enable = i;
}

public Convar_Unbreak_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iUnbreak_enable_sur = i;
}

public Convar_Unbreak_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iUnbreak_enable_vs = i;
}

//double tap
public Convar_DT (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.02)
		flF=0.02;
	else if (flF>0.9)
		flF=0.9;
	g_flDT_rate = flF;
}

public Convar_DT_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iDT_enable = i;
}

public Convar_DT_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iDT_enable_sur = i;
}

public Convar_DT_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iDT_enable_vs = i;
}

//sleight of hand
public Convar_SoH (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.02)
		flF=0.02;
	else if (flF>0.9)
		flF=0.9;
	g_flSoH_rate = flF;
}

public Convar_SoH_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iSoH_enable = i;
}

public Convar_SoH_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iSoH_enable_sur = i;
}

public Convar_SoH_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iSoH_enable_vs = i;
}

//chem reliant
public Convar_Chem (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>150)
		i=150;
	g_iChem_buff = i;
}

public Convar_Chem_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iChem_enable = i;
}

public Convar_Chem_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iChem_enable_sur = i;
}

public Convar_Chem_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iChem_enable_vs = i;
}

//pyrotechnician
public Convar_Pyro_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iPyro_enable = i;
}

public Convar_Pyro_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iPyro_enable_sur = i;
}

public Convar_Pyro_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iPyro_enable_vs = i;
}

//pack rat
public Convar_Pack (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.01)
		flF=0.01;
	else if (flF>1.0)
		flF=1.0;
	g_flPack_ammomult = flF;
}

public Convar_Pack_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iPack_enable = i;
}

public Convar_Pack_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iPack_enable_sur = i;
}

public Convar_Pack_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iPack_enable_vs = i;
}

//hard to kill
public Convar_Hard (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.01)
		flF=0.01;
	else if (flF>3.0)
		flF=3.0;
	g_flHard_hpmult = flF;
}

public Convar_Hard_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iHard_enable = i;
}

public Convar_Hard_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iHard_enable_sur = i;
}

public Convar_Hard_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iHard_enable_vs = i;
}

//martial artist
//also rebuilds MA registry in order to
//reassign new speed values
public Convar_MA (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<1.0)
		flF=1.0;
	else if (flF>1.5)
		flF=1.5;
	g_flMA_rate = flF;
	MartialArtist_Rebuild();
}

public Convar_MA_coop (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<1.0)
		flF=1.0;
	else if (flF>1.5)
		flF=1.5;
	g_flMA_rate = flF;
	MartialArtist_Rebuild();
}

public Convar_MA_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iMA_enable = i;
}

public Convar_MA_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iMA_enable_sur = i;
}

public Convar_MA_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iMA_enable_vs = i;
}

//barf bagged
public Convar_Barf_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iBarf_enable = i;
}

//acid vomit
public Convar_BileDamage_change (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.00)
		flF=0.00;
	else if (flF>100)
		flF=100.0;
	SetConVarFloat(BileDamage, flF);
}

public Convar_Blind_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iBlind_enable = i;
}

//dead wreckening
public Convar_Dead (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.01)
		flF=0.01;
	else if (flF>4.0)
		flF=4.0;
	g_flDead_dmgmult = flF;
}

public Convar_Dead_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iDead_enable = i;
}

//motion sickness
public Convar_Motion (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<1.0)
		flF=1.0;
	else if (flF>4.0)
		flF=4.0;
	g_flMotion_rate = flF;
}

public Convar_Motion_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iMotion_enable = iI;
}

//squeezer
public Convar_Squeezer (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>100)
		i=100;
	g_iSqueezer_dmg = i;
}

public Convar_SqueezerHard (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>100)
		i=100;
	g_iSqueezer_dmg_hard = i;
}

public Convar_SqueezerExpert (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>100)
		i=100;
	g_iSqueezer_dmg_expert = i;
}

public Convar_Squeezer_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iSqueezer_enable = i;
}

//regenerator
public Convar_Regenerator (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>350)
		i=350;
	g_iRegenerator_heal = i;
}

public Convar_Regenerator_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iRegenerator_enable = i;
}

//slingshot stickytongue
public Convar_Slingshot (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<100)
		i=100;
	else if (i>1000)
		i=1000;
	g_iSlingshot_force = i;
}

public Convar_Slingshot_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iSlingshot_enable = i;
}


//efficient killer
public Convar_Eff (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>100)
		i=100;
	g_iEfficient_dmg = i;
}

public Convar_Effhard (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>100)
		i=100;
	g_iEfficient_dmg_hard = i;
}

public Convar_Effexpert (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>100)
		i=100;
	g_iEfficient_dmg_expert = i;
}

public Convar_Eff_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iEfficient_enable = i;
}

// Flaming Hunter code

public Convar_FlamingHunter (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>100)
		i=100;
	g_iFlamingHunter_dmg = i;
}

public Convar_FlamingHunter_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iFlamingHunter_enable = i;
}

//body slam
public Convar_Body (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<2)
		i=2;
	else if (i>100)
		i=100;
	g_iBody_minbound = i;
}

public Convar_Body_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iBody_enable = i;
}

//grasshopper
public Convar_Grass (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<1.0)
		flF=1.0;
	else if (flF>3.0)
		flF=3.0;
	g_flGrass_rate = flF;
}

public Convar_Grass_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iGrass_enable = i;
}

//old school
public Convar_Old (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>100)
		i=100;
	g_iOld_dmg = i;
}

public Convar_Oldhard (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>100)
		i=100;
	g_iOld_dmg_hard = i;
}

public Convar_Oldexpert (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>100)
		i=100;
	g_iOld_dmg_expert = i;
}

public Convar_Old_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iOld_enable = i;
}

//adrenal glands
public Convar_Adrenalpunchdmgmult (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<1.00)
		flF=1.00;
	else if (flF>5.0)
		flF=5.0;
	SetConVarFloat(g_flAdrenal_punchdmgmult, flF);
}

public Convar_Adrenal_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iAdrenal_enable = i;
}

//juggernaut
public Convar_Jugg (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>99999)
		i=99999;
	g_iJuggernaut_hp = i;
}

public Convar_Jugg_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iJuggernaut_enable = i;
}

//metabolic boost
public Convar_Met (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<1.01)
		flF=1.01;
	else if (flF>3.0)
		flF=3.0;
	g_flMetabolic_speedmult = flF;
}

public Convar_Met_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iMetabolic_enable = i;
}

//storm caller
public Convar_Storm (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<1)
		i=1;
	else if (i>10)
		i=10;
	g_iStorm_mobcount = i;
}

public Convar_Storm_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i==0)
		i=0;
	else
		i=1;
	g_iStorm_enable = i;
}

//bot preferences
public Convar_Sur1 (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	switch (i)
	{
		//stopping power
		case 1:
			g_iBot_Sur1 = 1;
		//spirit
		case 2:
			g_iBot_Sur1 = 3;
		default:
			g_iBot_Sur1 = 3;
	}
}

public Convar_Sur2 (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	switch (i)
	{
		//chem reliant
		case 1:
			g_iBot_Sur2 = 1;
		//helping hand
		case 2:
			g_iBot_Sur2 = 2;
		//pack rat
		case 3:
			g_iBot_Sur2 = 3;
		//hard to kill
		case 4:
			g_iBot_Sur2 = 5;
		default:
			g_iBot_Sur2 = 5;
	}
}

public Convar_Inf1 (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	switch (i)
	{
		//barf bagged
		case 1:
			g_iBot_Inf1 = 1;
		//acid vomit
		case 2:
			g_iBot_Inf1 = 2;
		//dead wreckening
		case 3:
			g_iBot_Inf1 = 3;
		default:
			g_iBot_Inf1 = 1;
	}
}

public Convar_Inf2 (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	switch (i)
	{
		//adrenal glands
		case 1:
			g_iBot_Inf2 = 1;
		//juggernaut
		case 2:
			g_iBot_Inf2 = 2;
		//metabolic boost
		case 3:
			g_iBot_Inf2 = 3;
		//storm caller
		case 4:
			g_iBot_Inf2 = 4;
		default:
			g_iBot_Inf2 = 2;
	}
}

public Convar_Inf3 (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	switch (i)
	{
		//tongue twister
		case 1:
			g_iBot_Inf3 = 1;
		//squeezer
		case 2:
			g_iBot_Inf3 = 2;
		default:
			g_iBot_Inf3 = 2;
	}
}

public Convar_Inf4 (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	switch (i)
	{
		//efficient killer
		case 1:
			g_iBot_Inf4 = 2;
		//old school
		case 3:
			g_iBot_Inf4 = 4;
		default:
			g_iBot_Inf4 = 2;
	}
}

//default perks
public Convar_Def_Sur1 (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<=0)
		i=1;
	else if (i>6)
		i=6;

	g_iSur1_default=i;
}

public Convar_Def_Sur2 (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<=0)
		i=1;
	else if (i>5)
		i=5;

	g_iSur2_default=i;
}

public Convar_Def_Inf1 (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<=0)
		i=1;
	else if (i>3)
		i=3;

	g_iInf1_default=i;
}

public Convar_Def_Inf2 (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<=0)
		i=1;
	else if (i>5)
		i=5;

	g_iInf2_default=i;
}

public Convar_Def_Inf3 (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<=0)
		i=1;
	else if (i>3)
		i=3;

	g_iInf3_default=i;
}

public Convar_Def_Inf4 (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new i=StringToInt(newValue);
	if (i<=0)
		i=1;
	else if (i>4)
		i=4;

	g_iInf4_default=i;
}



//=============================
// Server, Misc Perk Functions
//=============================

//set default perks for connecting players
public Event_PConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (client==0) return;

	//if any of the perks are set to 0, set default values
	if (SurvivorUpgrade1[client]==0)
		SurvivorUpgrade1[client] = g_iSur1_default;
	if (SurvivorUpgrade2[client]==0)
		SurvivorUpgrade2[client] = g_iSur2_default;
	if (BoomerUpgrade[client]==0)
		BoomerUpgrade[client] = g_iInf1_default;
	if (TankUpgrade[client]==0)
		TankUpgrade[client] = g_iInf2_default;
	if (SmokerUpgrade[client]==0)
		SmokerUpgrade[client] = g_iInf3_default;
	if (HunterUpgrade[client]==0)
		HunterUpgrade[client] = g_iInf4_default;
	PerksConfirmed[client]=0;
	GrenadesCarried[client]=0;
	GrenadeBeingTossed[client]=0;
	GrenadeType[client]=0;
	SpiritState[client]=0;
	IsIncapped[client]=0;
	SpiritCooldown[client]=0;
	HasGrabbedSomeone[client]=0;
}

//reset perk values when disconnected
//closes timer for spirit cooldown
//and rebuilds DT registry
public Event_PDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (client==0) return;
	SurvivorUpgrade1[client]=0;
	SurvivorUpgrade2[client]=0;
	BoomerUpgrade[client]=0;
	TankUpgrade[client]=0;
	SmokerUpgrade[client]=0;
	HunterUpgrade[client]=0;
	PerksConfirmed[client]=0;
	GrenadesCarried[client]=0;
	GrenadeBeingTossed[client]=0;
	GrenadeType[client]=0;
	SpiritState[client]=0;
	IsIncapped[client]=0;
	SpiritCooldown[client]=0;
	HasGrabbedSomeone[client]=0;

	if (SpiritTimer[client]!=INVALID_HANDLE)
	{
		CloseHandle(SpiritTimer[client]);
		SpiritTimer[client]=INVALID_HANDLE;
	}
	DoubleTap_Rebuild();
	MartialArtist_Rebuild();
}

//call menu on first spawn, otherwise set default values for bots
public Event_PlayerFirstSpawn (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (client==0) return;
	if (PerksConfirmed[client]==0 && IsFakeClient(client)==false)
	{
		SendPanelToClient(Menu_Initial(client),client,Menu_ChooseInit,MENU_TIME_FOREVER);
		//CreateTimer(0.3,Timer_ShowTopMenu,client);
		PrintHintText(client,"Welcome to Perkmod!");
		PrintToChat(client,"\x03[SM] Welcome to Perkmod! If the menu doesn't come up, type !perks to display it.");
	}
}

//checks to show perks menu on roundstart
//and resets various vars to default
public Event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	//----DEBUG----
	//PrintToChatAll("\x03round start detected");

	for (new i=1 ; i<=18 ; i++)
	{
		//----DEBUG----
		//PrintToChatAll("\x03-cycle %i",i);

		//reset vars related to spirit perk
		SpiritState[i]=0;
		IsIncapped[i]=0;
		SpiritCooldown[i]=0;
		//reset var related to various hunter/smoker perks
		HasGrabbedSomeone[i]=0;

		//reset var pointing to client's spirit timer
		//and close the timer handle
		if (SpiritTimer[i]!=INVALID_HANDLE)
		{
			CloseHandle(SpiritTimer[i]);
			SpiritTimer[i]=INVALID_HANDLE;
		}

		//before we run any functions on players
		//check if the game has any players to prevent
		//stupid error messages cropping up on the server
		if (IsServerProcessing()==false)
			continue;

		//only run these commands if player is in-game
		if (IsClientInGame(i)==true)
		{
			//reset run speeds for martial artist
			SetEntDataFloat(i,g_iLaggedMovementO, 1.0 ,true);

			if (IsFakeClient(i)==true) continue;
			//show the perk menu if their perks are unconfirmed
			if (PerksConfirmed[i]==0)
				CreateTimer(0.3,Timer_ShowTopMenu,i);
			//otherwise check for pyro's initial grenade
			//or for chem reliant's initial pills
			else if (PerksConfirmed[i]==1
				&& GetClientTeam(i)==2)
			{
				if (SurvivorUpgrade1[i]==2) Event_Confirm_Grenadier(i);
				if (SurvivorUpgrade2[i]==1) Event_Confirm_ChemReliant(i);
			}
			//reset var related to acid vomit perk
			//SendConVarValue(i,hCvar,"0");
			SetEntProp(i, Prop_Send, "m_iHideHUD", 0);
		}

	}

	//finally, clear DT and MA registry
	DoubleTap_Clear();
	MartialArtist_Clear();
	//calculate pack rat capacities
	PackRat_Calculate();
	//reset boomer vars
	SlimedCount		= 0;
	LastBoomer	= 0;
	//reset tank vars
	TankMode			= 0;

	//detect gamemode and difficulty
	decl String:stArg[64];
	//first, check difficulty
	GetConVarString(FindConVar("z_difficulty"),stArg,64);
	if (StrEqual(stArg,"hard",false)==true)
		g_iL4D_Difficulty=1;
	else if (StrEqual(stArg,"impossible",false)==true)
		g_iL4D_Difficulty=2;
	else
		g_iL4D_Difficulty=0;
	//next, check gamemode
	GetConVarString(FindConVar("mp_gamemode"),stArg,64);
	if (StrEqual(stArg,"versus",false)==true)
		g_iL4D_GameMode=2;
	else if (StrEqual(stArg,"survival",false)==true)
		g_iL4D_GameMode=1;
	else
		g_iL4D_GameMode=0;

	//----DEBUG----
	//PrintToChatAll("\x03-difficulty \x01%i\x03, gamemode \x01%i",g_iL4D_Difficulty,g_iL4D_GameMode);

	//----DEBUG----
	//PrintToChatAll("\x03-end round start routine");
}

//resets some temp vars related to perks
public Event_PlayerDeath (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (client==0) return;
	//reset vars related to spirit perk
	SpiritState[client]=0;
	IsIncapped[client]=0;
	SpiritCooldown[client]=0;
	HasGrabbedSomeone[client]=0;
	//and also close the spirit cooldown timer
	//and nullify the var pointing to it
	if (SpiritTimer[client]!=INVALID_HANDLE)
	{
		CloseHandle(SpiritTimer[client]);
		SpiritTimer[client]=INVALID_HANDLE;
	}

	if (IsClientInGame(client)==true
		&& IsFakeClient(client)==false)
	{
		//reset var related to acid vomit perk
		//SendConVarValue(client,FindConVar("sv_cheats"),"0");
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
	}

	//rebuild registries for double tap and martial artist
	if (GetClientTeam(client)==2)
	{
		DoubleTap_Rebuild();
		MartialArtist_Rebuild();
	}

	//reset movement rate from martial artist
	SetEntDataFloat(client,g_iLaggedMovementO, 1.0 ,true);

	//----DEBUG----
	//PrintToChatAll("\x03end death routine for \x01%i",client);
}


//sets confirm to 0 and redisplays perks menu
public Event_PlayerTransitioned (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (client==0) return;
	//reset their confirm perks var
	//and show the menu
	PerksConfirmed[client]=0;
	//SendPanelToClient(Menu_Top(client),client,Menu_ChooseSubMenu,MENU_TIME_FOREVER);
	CreateTimer(0.3,Timer_ShowTopMenu,client);
	//since we just changed maps
	//reset everything for the spirit cooldown timer
	if (SpiritTimer[client]!=INVALID_HANDLE)
	{
		CloseHandle(SpiritTimer[client]);
		SpiritTimer[client]=INVALID_HANDLE;
	}
}

//resets everyone's confirm values on round end, mainly for survival and campaign
public Event_RoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	//----DEBUG----
	//PrintToChatAll("round end detected");

	DoubleTap_Clear();
	MartialArtist_Clear();

	for (new i=1 ; i<=18 ; i++)
	{
		PerksConfirmed[i]=0;
	}
}

//as round end function above
public OnMapEnd()
{
	//----DEBUG----
	//PrintToChatAll("map end detected");

	DoubleTap_Clear();
	MartialArtist_Clear();

	for (new i=1 ; i<=18 ; i++)
	{
		PerksConfirmed[i]=0;
	}
}

//forces perks for bots, among other things. Anything
//that uses a global timer for periodic checks is also called here
//current functions called here:
//Sur1: Spirit, Sur2: Martial Artist, Inf3: Regenerator
public Action:TimerPerks (Handle:timer, any:data)
{
	if (IsServerProcessing()==false)
		return Plugin_Continue;

	for (new i=1 ; i<=18 ; i++)
	{
		//----DEBUG----
		//PrintToChatAll("\x03-cycle %i",i);

		//only run these commands if player is in-game
		if (IsClientInGame(i)==true && IsFakeClient(i)==true)
		{
			PerksConfirmed[i]=1;
			//sur1: spirit
			SurvivorUpgrade1[i] = g_iBot_Sur1;
			//sur2: hard to kill
			SurvivorUpgrade2[i] = g_iBot_Sur2;
			//boomer: barf bagged
			BoomerUpgrade[i] = g_iBot_Inf1;
			//tank: juggernaught
			TankUpgrade[i] = g_iBot_Inf2;
			//smoker: squeezer
			SmokerUpgrade[i] = g_iBot_Inf3;
			//hunter: efficient killer
			HunterUpgrade[i] = g_iBot_Inf4;

			//----DEBUG----
			//PrintToChatAll("\x03-bot perks for %i",i);
		}
	}

	Spirit_Timer();
	MA_ResetFatigue();
	Regenerator_Heal();

	return Plugin_Continue;
}

//called on a player changing teams
//and rebuilds DT registry (and MA as well)
public Event_PlayerTeam (Handle:event, const String:name[], bool:dontBroadcast)
{
	//----DEBUG----
	//PrintToChatAll("\x03change team detected");

	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (client==0
		|| IsValidEntity(client)==false
		|| IsClientInGame(client)==false) return;

	//reset vars related to spirit perk
	SpiritState[client]=0;
	IsIncapped[client]=0;
	SpiritCooldown[client]=0;
	//reset var related to various hunter/smoker perks
	HasGrabbedSomeone[client]=0;

	//reset var pointing to client's spirit timer
	//and close the timer handle
	if (SpiritTimer[client]!=INVALID_HANDLE)
	{
		CloseHandle(SpiritTimer[client]);
		SpiritTimer[client]=INVALID_HANDLE;
	}

	//reset runspeed
	SetEntDataFloat(client,g_iLaggedMovementO, 1.0 ,true);

	//reset blind perk sendprop
	if (IsFakeClient(client)==false)
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);

	//rebuild MA and DT registries
	CreateTimer(0.3,Delayed_Rebuild,0);

	//apply perks if changing into survivors
	CreateTimer(0.3,Delayed_PerkChecks,client);

	//----DEBUG----
	//PrintToChatAll("\x03-end change team routine");
}

//trying a delayed rebuild so DT
//will work with team switches
public Action:Delayed_Rebuild (Handle:timer, any:data)
{
	DoubleTap_Rebuild();
	MartialArtist_Rebuild();
}

//delayed perk checks
public Action:Delayed_PerkChecks (Handle:timer, any:client)
{
	if (!IsClientInGame(client)) return Plugin_Continue;
	if (GetClientTeam(client)!=2)
		return Plugin_Continue;

	Event_Confirm_Unbreakable(client);
	Event_Confirm_PackRat(client);
	Event_Confirm_Grenadier(client);
	Event_Confirm_ChemReliant(client);

	return Plugin_Continue;
}









//====================================================
//====================================================
//					P	E	R	K	S
//====================================================
//====================================================



//=============================
// Sur1: Stopping Power,
// Inf3: Squeezer,
// Inf4: Body Slam,
// Inf4: Efficient Killer
// Inf4: Old School
// Inf1: Dead Wreckening
//=============================

//this trigger only runs on players, not common infected
public Action:Event_PlayerHurtPre (Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker=GetClientOfUserId(GetEventInt(event,"attacker"));
	new victim=GetClientOfUserId(GetEventInt(event,"userid"));

	//----DEBUG----
	//new iType=GetEventInt(event,"type");
	//decl String:sWeapon[Pumpgun_MaxAmmo];
	//GetEventString(event,"weapon",sWeapon,Pumpgun_MaxAmmo);
	//PrintToChatAll("\x03attacker:\x01%i\x03 weapon:\x01%s\x03 type:\x01%i",attacker,sWeapon,iType);

	if (victim==0) return Plugin_Continue;

	//check for dead wreckening damage add for zombies
	if (attacker==0)
	{
		if (GetEventInt(event,"type")==Pumpgun_MaxAmmo
			&& SlimedCount>0
			&& PerksConfirmed[LastBoomer]==1
			&& BoomerUpgrade[LastBoomer]==3)
		{
			//----DEBUG----
			//PrintToChatAll("\x03dead wreckening fire");

			new iDmgOrig=GetEventInt(event,"dmg_health");
			InfectedToSurvivorDamageAdd(event,victim, RoundToCeil(iDmgOrig * g_flDead_dmgmult) ,iDmgOrig,true);
		}
		return Plugin_Continue;
	}

	new attackerteam = GetClientTeam(attacker);

	//if damage is from survivors to a non-survivor,
	//check for damage add (stopping power)
	if (attackerteam==2
		&& SurvivorUpgrade1[attacker]==1
		&& PerksConfirmed[attacker]==1
		&& GetClientTeam(victim)!=2)
	{
		//----DEBUG----
		//PrintToChatAll("\x03Pre-mod bullet damage: \x01%i", GetEventInt(event,"dmg_health"));

		new iDmgOrig=GetEventInt(event,"dmg_health");
		new iDmgAdd= RoundToNearest(iDmgOrig * g_flStopping_dmgmult);
		new iHP=GetEntProp(victim,Prop_Data,"m_iHealth");
		//to prevent strange death behaviour,
		//only deal the full damage add if health > damage add
		if (iHP>iDmgAdd)
		{
			SetEntProp(victim,Prop_Data,"m_iHealth", iHP-iDmgAdd );
			SetEventInt(event,"dmg_health", iDmgOrig+iDmgAdd );
		}
		//if health < damage add, only deal health-1 damage
		else
		{
			iDmgAdd=iHP-1;
			//don't bother if the modified damage add
			//ends up being an insignificant amount
			if (iDmgAdd<0)
				return Plugin_Continue;
			SetEntProp(victim,Prop_Data,"m_iHealth", iHP-iDmgAdd );
			SetEventInt(event,"dmg_health", iDmgOrig+iDmgAdd );
		}

		//----DEBUG----
		//PrintToChatAll("\x03Post-mod bullet damage: \x01%i",GetEventInt(event,"dmg_health"));

		return Plugin_Continue;
	}

	//otherwise, check for infected damage add types
	//(body slam, efficient killer, squeezer)
	else if (attackerteam==3
		&& PerksConfirmed[attacker]==1)
	{
		decl String:st_wpn[16];
		GetEventString(event,"weapon",st_wpn,16);

		//if it's a HUNTER-type damage...
		if (StrEqual(st_wpn,"hunter_claw"))
		{
			//----DEBUG----
			//PrintToChatAll("\x03-hunter claw damage detected, type: \x01%i",GetEventInt(event,"type"));

			//...check for body slam
			if (GetEventInt(event,"type")==1
				&& HunterUpgrade[attacker]==1)
			{
				//----DEBUG----
				//PrintToChatAll("\x03body slam check");

				new iDmgOrig=GetEventInt(event,"dmg_health");
				new iMinBound= g_iBody_minbound;

				//body slam only fires if pounce damage
				//was less than 8 (sets minimum pounce damage)
				//or whatever the minimum bound is (was originally 8...)
				if (iDmgOrig<iMinBound)
				{
					//----DEBUG----
					//PrintToChatAll("\x03body slam fire, running checks");

					new iHP=GetEntProp(victim,Prop_Data,"m_iHealth");

					//if health>8, then run normally
					if (iHP>iMinBound)
					{
						//----DEBUG----
						//PrintToChatAll("\x03iHP>8 condition");

						SetEntProp(victim,Prop_Data,"m_iHealth", iHP-(iMinBound-iDmgOrig) );
						SetEventInt(event,"dmg_health", iMinBound );
						PrintHintText(attacker,"Body Slam: %i bonus damage!", iMinBound-iDmgOrig);

						//----DEBUG----
						//PrintToChatAll("\x03-%i bonus damage", (iMinBound-iDmgOrig) );

						return Plugin_Continue;
					}
					//otherwise, we gotta do a bit of work
					//if survivor's health is
					//less than or equal to 8
					else
					{
						//----DEBUG----
						//PrintToChatAll("\x03iHP<8 condition");
						//PrintToChatAll("\x03-iDmgOrig<8 and iHP>1, iDmgOrig: \x01%i\x03, pre-mod iHP: \x01%i",iDmgOrig,iHP);

						new Float:flHPBuff=GetEntDataFloat(victim,g_iHPBuffO);

						//if victim has health buffer,
						//we need to do some extra work
						//to reduce health buffer as well
						if (flHPBuff>0)
						{
							//----DEBUG----
							//PrintToChatAll("\x03-flHPBuff>0 condition, pre-mod HPbuffer: \x01%f", flHPBuff);

							new iDmgAdd= iMinBound-iDmgOrig ;

							//if damage add exceeds health,
							//then we need to take the difference
							//and apply it to health buffer instead
							if (iDmgAdd>=iHP)
							{
								//----DEBUG----
								//PrintToChatAll("\x03-iDmgAdd>=iHP condition, pre-mod iDmgAdd: \x01%i",iDmgAdd);

								//we leave the survivor with 1 health
								//because the engine will take it away
								//when it applies the original damage
								//and we want to avoid strange death behaviour
								new iDmgCount=iHP-1;
								iDmgAdd-=iDmgCount;
								SetEntProp(victim,Prop_Data,"m_iHealth", iHP-iDmgCount );

								//if damage add is more than health buffer,
								//set damage add to health buffer amount
								new iHPBuff=RoundToFloor(flHPBuff);
								if (iHPBuff<iDmgAdd) iDmgAdd=iHPBuff;
								SetEntDataFloat(victim,g_iHPBuffO, flHPBuff-iDmgAdd ,true);
								SetEventInt(event,"dmg_health", iDmgOrig+iDmgAdd+iDmgCount );
								PrintHintText(attacker,"Body Slam: %i bonus damage!", iDmgCount+iDmgAdd);

								//----DEBUG----
								//PrintToChatAll("\x03-damage to health: \x01%i\x03, current health: \x01%i",iDmgCount,GetEntProp(victim,Prop_Data,"m_iHealth"));
								//PrintToChatAll("\x03-damage to buffer: \x01%i\x03, current buffer: \x01%f",iDmgAdd,GetEntDataFloat(victim,g_iHPBuffO));

								return Plugin_Continue;
							}

							//if damage add is less than health
							//remaining, then we simply deal
							//the extra damage and let the engine
							//deal with the rest
							else
							{
								//----DEBUG----
								//PrintToChatAll("\x03-iDmgAdd<iHP condition");

								SetEntProp(victim,Prop_Data,"m_iHealth", iHP-iDmgAdd );
								SetEventInt(event,"dmg_health", iDmgOrig+iDmgAdd );
								PrintHintText(attacker,"Body Slam: %i bonus damage!", iDmgAdd);
								return Plugin_Continue;
							}
						}

						//otherwise, it's straightforward
						//- just reduce victim's hp
						else
						{
							//----DEBUG----
							//PrintToChatAll("\x03no temp hp condition");

							//if original damage exceeds health,
							//just skip the rest since there's no
							//health buffer to worry about
							if (iDmgOrig>=iHP) return Plugin_Continue;
							new iDmgAdd= iMinBound-(iHP-iDmgOrig) ;
							//to prevent strange death behaviour,
							//reduce damage add to less than that
							//of remaining health if necessary
							if (iDmgAdd>=iHP) iDmgAdd=iHP-1;
							SetEntProp(victim,Prop_Data,"m_iHealth", iHP-iDmgAdd );
							SetEventInt(event,"dmg_health", iDmgOrig+iDmgAdd );
							PrintHintText(attacker,"Body Slam: %i bonus damage!", iDmgAdd);

							//----DEBUG----
							//PrintToChatAll("\x03-iHP<8, %i bonus damage", iDmgAdd );

							return Plugin_Continue;
						}
					}
				}
				return Plugin_Continue;
			}

			//...check for efficient killer
			else if (HunterUpgrade[attacker]==2
				&& HasGrabbedSomeone[attacker]==1)
			{
				//----DEBUG----
				//PrintToChatAll("\x03efficient killer fire");

				decl iDmgAdd;
				if (g_iL4D_GameMode==0)
				{
					if (g_iL4D_Difficulty==1)
						iDmgAdd=g_iEfficient_dmg_hard;
					else if (g_iL4D_Difficulty==2)
						iDmgAdd=g_iEfficient_dmg_expert;
					else
						iDmgAdd=g_iEfficient_dmg;
				}
				else
					iDmgAdd=g_iEfficient_dmg;

				InfectedToSurvivorDamageAdd(event,victim, iDmgAdd ,GetEventInt(event,"dmg_health"),true);
				return Plugin_Continue;
			}
			
			//check for old school
			else if (HunterUpgrade[attacker]==4
				&& HasGrabbedSomeone[attacker]==0)
			{
				//----DEBUG----
				//PrintToChatAll("\x03old school fire");

				decl iDmgAdd;
				if (g_iL4D_GameMode==0)
				{
					if (g_iL4D_Difficulty==1)
						iDmgAdd=g_iOld_dmg_hard;
					else if (g_iL4D_Difficulty==2)
						iDmgAdd=g_iOld_dmg_expert;
					else
						iDmgAdd=g_iOld_dmg;
				}
				else
					iDmgAdd=g_iOld_dmg;

				InfectedToSurvivorDamageAdd(event,victim, iDmgAdd ,GetEventInt(event,"dmg_health"),true);
				return Plugin_Continue;
			}
			
			// check for bonus fire damage.
			if (HasGrabbedSomeone[attacker]==1 && GetEntDataFloat(attacker, g_iBurnPercentO) > 0 && g_iFlamingHunter_enable == 1)
					InfectedToSurvivorDamageAdd(event, victim, g_iFlamingHunter_dmg, GetEventInt(event,"dmg_health"),true);

		}

		//alternatively, if it's from a
		//SMOKER with the squeezer perk...
		else if (StrEqual(st_wpn,"smoker_claw")==true
			&& SmokerUpgrade[attacker]==2
			&& HasGrabbedSomeone[attacker]>0)
		{
			//----DEBUG----
			//PrintToChatAll("\x03squeeze fire");

			decl iDmgAdd;
			if (g_iL4D_GameMode==0)
			{
				if (g_iL4D_Difficulty==1)
					iDmgAdd=g_iSqueezer_dmg_hard;
				else if (g_iL4D_Difficulty==2)
					iDmgAdd=g_iSqueezer_dmg_expert;
				else
					iDmgAdd=g_iSqueezer_dmg;
			}
			else
				iDmgAdd=g_iSqueezer_dmg;

			InfectedToSurvivorDamageAdd(event,victim, iDmgAdd ,GetEventInt(event,"dmg_health"),true);
			return Plugin_Continue;
		}
		
		
		//alternatively, if it's from a
		//TANK with the adrenal gland perk...
		else if (StrEqual(st_wpn,"tank_claw")==true
			&& TankUpgrade[attacker]==1)
		{
			decl Float:iDmgAdd;
			iDmgAdd = (GetEventInt(event,"dmg_health") * GetConVarFloat(g_flAdrenal_punchdmgmult));

			InfectedToSurvivorDamageAdd(event,victim, iDmgAdd ,GetEventInt(event,"dmg_health"),true);
			return Plugin_Continue;
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}



//This is a recently-added function adapted from the complex function I originally wrote
//for body slam. Simpler code I wrote for the other infected-to-survivor perks kept
//inadvertently killing the survivors when they weren't black-and-white... but since
//body slam never had that problem, I decided to use body slam's code to avoid that
//problem altogether... hence this giant function. However, since body slam doesn't fire
//if the original damage exceeds a minimum, it still has its own code.
InfectedToSurvivorDamageAdd (Handle:event, any:victim, any:iDmgAdd, any:iDmgOrig, bool:UpdateEvent)
{
	//don't bother running if client id is zero
	//since sourcemod is intolerant of local servers
	//and if damage add is zero... why bother?
	if (victim==0 || iDmgAdd<=0) return;

	new iHP=GetEntProp(victim,Prop_Data,"m_iHealth");

	//CONDITION 1:
	//HEALTH > DMGADD
	//-----------------
	//if health>Min, then run normally
	//easiest condition, since we can
	//apply the damage directly to their hp
	if (iHP>iDmgAdd)
	{
		//----DEBUG----
		//PrintToChatAll("\x03iHP>%i condition",iDmgAdd);

		SetEntProp(victim,Prop_Data,"m_iHealth", iHP-iDmgAdd );
		if (UpdateEvent==true) SetEventInt(event,"dmg_health", iDmgOrig+iDmgAdd );

		//----DEBUG----
		//PrintToChatAll("\x03-%i bonus damage", iDmgAdd );

		return;
	}

	//CONDITION 2:
	//HEALTH <= DMGADD
	//-----------------
	//otherwise, we gotta do a bit of work
	//if survivor's health is
	//less than or equal to 8
	else
	{
		//----DEBUG----
		//PrintToChatAll("\x03iHP<=%i condition",iDmgAdd);
		//PrintToChatAll("\x03-pre-mod iHP: \x01%i",iHP);

		new Float:flHPBuff=GetEntDataFloat(victim,g_iHPBuffO);

		//CONDITION 2A:
		//HEALTH <= DMGADD
		//&& BUFFER > 0
		//-----------------
		//if victim has health buffer,
		//we need to do some extra work
		//to reduce health buffer as well
		if (flHPBuff>0)
		{
			//----DEBUG----
			//PrintToChatAll("\x03-flHPBuff>0 condition, pre-mod HPbuffer: \x01%f", flHPBuff);

			//since we know the damage add exceeds
			//health, we need to take the difference
			//and apply it to health buffer instead

			//we leave the survivor with 1 health
			//because the engine will take it away
			//when it applies the original damage
			//and we want to avoid strange death behaviour
			//(which occurs if victim's health falls below 0)
			new iDmgCount=iHP-1;
			iDmgAdd-=iDmgCount;
			SetEntProp(victim,Prop_Data,"m_iHealth", iHP-iDmgCount );

			//and now we take the remainder of the
			//damage add and apply it to the health buffer.

			//if damage add is more than health buffer,
			//set damage add to health buffer amount
			new iHPBuff=RoundToFloor(flHPBuff);
			if (iHPBuff<iDmgAdd) iDmgAdd=iHPBuff;
			//and here we apply the damage to the buffer
			SetEntDataFloat(victim,g_iHPBuffO, flHPBuff-iDmgAdd ,true);

			//finally, set the proper value in the event info
			if (UpdateEvent==true) SetEventInt(event,"dmg_health", iDmgOrig+iDmgAdd+iDmgCount );

			//----DEBUG----
			//PrintToChatAll("\x03-damage to health: \x01%i\x03, current health: \x01%i",iDmgCount,GetEntProp(victim,Prop_Data,"m_iHealth"));
			//PrintToChatAll("\x03-damage to buffer: \x01%i\x03, current buffer: \x01%f",iDmgAdd,GetEntDataFloat(victim,g_iHPBuffO));

			return;
		}

		//CONDITION 2B:
		//HEALTH <= DMGADD
		//&& BUFFER <= 0
		//-----------------
		//without health buffer, it's straightforward
		//since we just need to apply however much
		//of the damage add we can to the victim's health
		else
		{
			//----DEBUG----
			//PrintToChatAll("\x03no temp hp condition");

			//if original damage exceeds health,
			//just skip the rest since there's no
			//health buffer to worry about,
			//and the engine will incap or kill
			//the survivor anyways with the base damage
			if (iDmgOrig>=iHP) return;

			//to prevent strange death behaviour,
			//reduce damage add to less than that
			//of remaining health if necessary
			if (iDmgAdd>=iHP) iDmgAdd=iHP-1;
			//and if this puts it below 0, just skip everything
			if (iDmgAdd<0) return;

			SetEntProp(victim,Prop_Data,"m_iHealth", iHP-iDmgAdd );

			//and finally update the event info
			if (UpdateEvent==true) SetEventInt(event,"dmg_health", iDmgOrig+iDmgAdd );

			//----DEBUG----
			//PrintToChatAll("\x03-%i bonus damage", iDmgAdd );

			return;
		}
	}
}



//=============================
// Sur1: Stopping Power
//=============================

//against common infected
public Event_InfectedHurtPre (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"attacker"));

	if (client==0 || PerksConfirmed[client]==0) return;

	//----DEBUG----
	//PrintToChatAll("\x03infected hurt, attacker: %i, entity: %i, i_odmg: %i, iHP: %i",attacker,entity,i_odmg,GetEntProp(entity,Prop_Data,"m_iHealth"));

	if (SurvivorUpgrade1[client]==1
		&& GetClientTeam(client)==2)
	{
		new entity=GetEventInt(event,"entityid");
		new i_odmg=GetEventInt(event,"amount");
		new i_dmga=RoundToNearest(i_odmg * g_flStopping_dmgmult);

		//----DEBUG----
		//PrintToChatAll("\x03Pre-mod damage: \x01%i, \x03pre-mod health: \x01%i", GetEventInt(event,"amount"),GetEntProp(entity,Prop_Data,"m_iHealth"));

		SetEntProp(entity,Prop_Data,"m_iHealth", GetEntProp(entity,Prop_Data,"m_iHealth")-i_dmga );
		SetEventInt(event,"dmg_health", i_odmg+i_dmga );

		//----DEBUG----
		//PrintToChatAll("\x03Post-mod damage: \x01%i, \x03post-mod health: \x01%i",GetEventInt(event,"amount"),GetEntProp(entity,Prop_Data,"m_iHealth"));
	}
}


//=============================
// Sur1: Spirit,
// +Inf
//=============================

//tells plugin that attacker is in act of disabling
//and if they have the immovable object perk, gives hp
//and tells plugin victim is disabled
public Event_PounceLanded (Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker=GetClientOfUserId(GetEventInt(event,"userid"));
	new victim=GetClientOfUserId(GetEventInt(event,"victim"));

	if (victim==0 || attacker==0) return;

	//----DEBUG----
	//PrintToChatAll("\x03pounce land detected, client: \x01%i\x03, victim: \x01%i",attacker,victim);

	//spirit victim state is disabled
	SpiritState[victim]=1;
	//+Inf, attacker is disabling someone
	HasGrabbedSomeone[attacker]=1;
}

//tells plugin that the attacker is no longer disabling
//and if they have the immovable object perk, removes bonus hp
//and tells plugin victim is no longer disabled
public Event_PounceStop (Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker=GetClientOfUserId(GetEventInt(event,"userid"));
	new victim=GetClientOfUserId(GetEventInt(event,"victim"));

	if (victim==0 || attacker==0) return;

	//----DEBUG----
	//PrintToChatAll("\x03pounce stop detected, attacker: \x01%i\x03, victim: \x01%i",attacker,victim);

	//victim is no longer disabled
	SpiritState[victim]=0;
	//+Inf, attacker no longer disabling
	HasGrabbedSomeone[attacker]=0;
}



//=============================
// Sur1: Spirit
//=============================

//detects when a person is hanging from a ledge
public Event_LedgeGrab (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));

	if (client==0) return;

	//----DEBUG----
	//PrintToChatAll("\x03spirit ledge grab detected, client: \x01%i",client);

	IsIncapped[client]=1;
	SpiritState[client]=1;
}

//when a player goes down, check everyone for spirit
//only revive one guy at a time (it'd be theoretically impossible
//to have to revive two guys at the same time, though, under the
//old system)
public Action:Event_IncapPre (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (client==0
		|| GetClientTeam(client)!=2)
		return Plugin_Continue;
	IsIncapped[client]=1;

	//----DEBUG----
	//PrintToChatAll("\x03spirit incap detected, client: \x01%i",client);



	//SELF-REVIVE SECTION
	//-------------------
	for (new i=1 ; i<=18 ; i++)
	{
		//----DEBUG----
		//PrintToChatAll("-cycle %i",i);

		//if PerksConfirmed is zero, it's probably empty...
		//but in any case, don't bother with unconfirmed peeps
		//or with people not in the game
		if (PerksConfirmed[i]==0
			|| IsClientInGame(i)==false)
			continue;

		//since we already checked for PerksConfirmed earlier,
		//it'd be a waste of time to check again
		if (GetClientTeam(i)==2
			&& SurvivorUpgrade1[i]==3
			&& IsIncapped[i]==1
			&& SpiritState[i]==0
			&& IsClientInGame(i)==true
			&& IsPlayerAlive(i)==true)
		{
			//----DEBUG----
			//PrintToChatAll("\x03-attempting to revive player \x01%i",i);

			//check for cooldown (to avoid abuses)
			if (SpiritCooldown[i]==1)
			{
				//----DEBUG----
				//PrintToChatAll("\x03-player revive on cooldown: \x01%i",i);

				if (IsFakeClient(i)==false)
					PrintHintText(i,"You're too tired to self-revive!");
				continue;
			}

			//here we give health through the console command
			//which is used to revive the player (no other way
			//I know of, setting the m_isIncapacitated in
			//CTerrorPlayer revives them but they can't move!)
			new iflags=GetCommandFlags("give");
			SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
			FakeClientCommand(i,"give health");
			SetCommandFlags("give", iflags);

			//and we give them bonus health buffer here
			SetEntDataFloat(i,g_iHPBuffO, GetEntDataFloat(i,g_iHPBuffO)+g_iSpirit_buff ,true);
			//and remove their health here (since "give health" gives them 100!)
			CreateTimer(0.1,Spirit_ChangeHP,i);

			SpiritCooldown[i]=1;

			new iTime;
			if (g_iL4D_GameMode==2)
				iTime=g_iSpirit_cd_vs;
			else if (g_iL4D_GameMode==1)
				iTime=g_iSpirit_cd_sur;
			else
				iTime=g_iSpirit_cd;

			SpiritTimer[i]=CreateTimer(iTime*1.0,Spirit_CooldownTimer,i);
			IsIncapped[i]=0;

			//show a message if it's not a bot
			if (IsFakeClient(i)==false)
				PrintHintText(i,"Spirit: you've self-revived!");

			//finally, since spirit fired, break the loop
			//since we only want one person to self-revive at a time
			break;
		}
	}
	return Plugin_Continue;
}

//called by global timer "TimerPerks"
//periodically runs checks to see if anyone should self-revive
//since sometimes self-revive won't fire if someone's being disabled
//by, say, a hunter
Spirit_Timer ()
{
	//this var counts how many people are incapped
	new iCount=0;

	//preliminary check; if no one has
	//the spirit perk, this function will return
	for (new i=1 ; i<=18 ; i++)
	{
		if (SurvivorUpgrade1[i]==3)
		{
			iCount++;
			break;
		}
	}
	if (iCount<=0) return;
	else iCount=0;

	//----DEBUG----
	//PrintToChatAll("\x03spirit timer check");

	//this array will hold client ids
	//for the possible candidates for self-revives
	new client[18];

	for (new i=1 ; i<=18 ; i++)
	{
		//fill array with whoever's incapped
		if (IsClientInGame(i)==true
			&& GetClientTeam(i)==2
			&& IsIncapped[i]==1)
		{
			iCount++;
			client[iCount]=i;

			//----DEBUG----
			//PrintToChatAll("\x03-incap registering \x01%i",i);
		}
	}

	//if the first two client ids are null, or
	//if the count was zero OR one, return
	//since someone can't self-revive if they're
	//the only ones incapped!
	if (iCount<=1
		|| client[1]<=0
		|| client[2]<=0)
		return;

	//----DEBUG----
	//PrintToChatAll("\x03-beginning self-revive checks, iCount=\x01%i",iCount);

	//now we check for someone to revive
	//and we only revive one person at a time
	for (new i=1 ; i<=iCount ; i++)
	{
		//client ids are stored incrementally (X in 1, Y in 2, Z in 3,...)
		//in the array client[], and i increases per tick, hence this mess =P
		//in short, here we use client[i], NOT i!
		if (PerksConfirmed[client[i]]==1
			&& SurvivorUpgrade1[client[i]]==3
			&& SpiritState[client[i]]==0
			&& SpiritCooldown[client[i]]==0
			&& IsClientInGame(client[i])==true
			&& IsPlayerAlive(client[i])==true
			&& GetClientTeam(client[i])==2)
		{
			//----DEBUG----
			//PrintToChatAll("\x03-reviving \x01%i",client[i]);

			//here we give health through the console command
			//which is used to revive the player (no other way
			//I know of, setting the m_isIncapacitated in
			//CTerrorPlayer revives them but they can't move!)
			new iflags=GetCommandFlags("give");
			SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
			FakeClientCommand(client[i],"give health");
			SetCommandFlags("give", iflags);

			//and we give them bonus health buffer here
			SetEntDataFloat(client[i],g_iHPBuffO, GetEntDataFloat(client[i],g_iHPBuffO)+g_iSpirit_buff ,true);
			//and remove their health here (since "give health" gives them 100!)
			CreateTimer(0.1,Spirit_ChangeHP,client[i]);

			SpiritCooldown[client[i]]=1;

			new iTime;
			if (g_iL4D_GameMode==2)
				iTime=g_iSpirit_cd_vs;
			else if (g_iL4D_GameMode==1)
				iTime=g_iSpirit_cd_sur;
			else
				iTime=g_iSpirit_cd;

			SpiritTimer[client[i]]=CreateTimer(iTime*1.0,Spirit_CooldownTimer,client[i]);
			IsIncapped[client[i]]=0;

			//show a message if it's not a bot
			if (IsFakeClient(client[i])==false)
				PrintHintText(client[i],"Spirit: you've self-revived!");

			//finally, since spirit fired, break the loop
			//since we only want one person to self-revive at a time
			break;
		}
	}
}

//cooldown timer
public Action:Spirit_CooldownTimer (Handle:timer, any:client)
{
	//if the cooldown's been turned off,
	//that means a new round has started
	//and we can skip everything here
	if (SpiritCooldown[client]==0) return Plugin_Continue;

	SpiritCooldown[client]=0;
	//we don't call CloseHandle on the timer
	//since it should already close itself on end
	//but we do nullify the pointer var
	SpiritTimer[client]=INVALID_HANDLE;

	//and this sends the client a hint message
	if (IsPlayerAlive(client)==true
		&& GetClientTeam(client)==2
		&& IsFakeClient(client)==false)
		PrintHintText(client,"You feel strong enough to self-revive again!");

	return Plugin_Continue;
}

//timer for removing hp
//(like juggernaut, removing it too quickly
//confuses the game and doesn't remove it =/)
public Action:Spirit_ChangeHP (Handle:timer, any:client)
{
	SetEntityHealth(client,1);
	return Plugin_Continue;
}



//=============================
// Sur1: Unbreakable
//=============================

//called when player is healed; gives 80% of bonus hp
public Event_PlayerHealed (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"subject"));
	if (client==0 || PerksConfirmed[client]==0) return;
	if (SurvivorUpgrade1[client]==5)
	{
		CreateTimer(0.5,Unbreakable_Delayed_Heal,client);
		//SetEntProp(client,Prop_Data,"m_iHealth", GetEntProp(client,Prop_Data,"m_iHealth")+(g_iUnbreak_hp*8/10) );

		//run a check to see if for whatever reason
		//the player's health is above 200
		//since 200 is the clamped maximum for unbreakable
		//in which case we set their health to 200
		if (GetEntProp(client,Prop_Data,"m_iHealth") > 200)
			CreateTimer(0.5,Unbreakable_Delayed_SetHigh,client);
			//SetEntProp(client,Prop_Data,"m_iHealth", 200 );

		SetEventInt(event,"health_restored", GetEventInt(event,"health_restored")+(g_iUnbreak_hp*8/10) );
		PrintHintText(client,"Unbreakable: bonus health!");
	}
}

//called when player confirms his choices;
//gives 30 hp (to bring hp to 130, assuming survivor
//wasn't stupid and got himself hurt before confirming perks)
Event_Confirm_Unbreakable (client)
{
	new iHP=GetEntProp(client,Prop_Data,"m_iHealth");
	if (client==0 || PerksConfirmed[client]==0) return;
	new TC=GetClientTeam(client);
	if (SurvivorUpgrade1[client]==5
		&& TC==2)
	{
		if (iHP>100
			&& iHP < (100+g_iUnbreak_hp) )
			CreateTimer(0.5,Unbreakable_Delayed_Max,client);
			//SetEntProp(client,Prop_Data,"m_iHealth", 100+g_iUnbreak_hp );
		else if (iHP<=100)
			CreateTimer(0.5,Unbreakable_Delayed_Normal,client);
			//SetEntProp(client,Prop_Data,"m_iHealth", iHP+g_iUnbreak_hp );
		PrintHintText(client,"Unbreakable: bonus health!");

		//run a check to see if for whatever reason
		//the player's health is above 200
		//since 200 is the clamped maximum for unbreakable
		//in which case we set their health to 200
		if (GetEntProp(client,Prop_Data,"m_iHealth") > 200)
			CreateTimer(0.5,Unbreakable_Delayed_SetHigh,client);
			//SetEntProp(client,Prop_Data,"m_iHealth", 200 );
	}
	//if not, check if hp is higher than it should be
	else if (SurvivorUpgrade1[client]!=5
		&& iHP>100
		&& TC==2)
	{
		//if it IS higher, reduce hp to 100
		//otherwise, no way to know whether previous owner
		//had unbreakable, so give the incoming player
		//the benefit of doubt
		CreateTimer(0.5,Unbreakable_Delayed_SetLow,client);
		//SetEntProp(client,Prop_Data,"m_iHealth", 100 );
	}
}

//these timer functions apply health bonuses
//after a delay, hopefully to avoid bugs
public Action:Unbreakable_Delayed_Max (Handle:timer, any:client)
{
	SetEntProp(client,Prop_Data,"m_iHealth", 100+g_iUnbreak_hp );
}

public Action:Unbreakable_Delayed_Normal (Handle:timer, any:client)
{
	SetEntProp(client,Prop_Data,"m_iHealth", GetEntProp(client,Prop_Data,"m_iHealth")+g_iUnbreak_hp );
}

public Action:Unbreakable_Delayed_Heal (Handle:timer, any:client)
{
	SetEntProp(client,Prop_Data,"m_iHealth", GetEntProp(client,Prop_Data,"m_iHealth") + (g_iUnbreak_hp*8/10) );
}

public Action:Unbreakable_Delayed_Rescue (Handle:timer, any:client)
{
	SetEntProp(client,Prop_Data,"m_iHealth", GetEntProp(client,Prop_Data,"m_iHealth") + (g_iUnbreak_hp/2) );
}

public Action:Unbreakable_Delayed_SetHigh (Handle:timer, any:client)
{
	SetEntProp(client,Prop_Data,"m_iHealth", 200 );
}

public Action:Unbreakable_Delayed_SetLow (Handle:timer, any:client)
{
	SetEntProp(client,Prop_Data,"m_iHealth", 100 );
}

//=============================
// Sur1: Unbreakable,
// Sur1: Spirit,
// Sur1: Double Tap,
// Sur2: Martial Artist,
// Inf1: acid vomit
//=============================

//called when survivor spawns from closet
public Event_PlayerRescued (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"victim"));
	if (client==0 || PerksConfirmed[client]==0) return;
	if (SurvivorUpgrade1[client]==5)
	{
		SetEntProp(client,Prop_Data,"m_iHealth", GetEntProp(client,Prop_Data,"m_iHealth")+(g_iUnbreak_hp/2) );
		PrintHintText(client,"Unbreakable: bonus health!");

		//run a check to see if for whatever reason
		//the player's health is above 200
		//since 200 is the clamped maximum for unbreakable
		//in which case we set their health to 200
		if (GetEntProp(client,Prop_Data,"m_iHealth") > 200)
			SetEntProp(client,Prop_Data,"m_iHealth", 200 );
	}
	//reset vars related to spirit perk
	SpiritState[client]=0;
	IsIncapped[client]=0;
	SpiritCooldown[client]=0;
	//reset var related to acid vomit perk
	//SendConVarValue(client,FindConVar("sv_cheats"),"0");
	SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
	//rebuilds double tap registry
	CreateTimer(0.3,Delayed_Rebuild,0);
}



//=============================
// Sur1: Double Tap
//=============================

//called on confirming perks
//simply adds player to registry of DT users
Event_Confirm_DT (client)
{
	if (DoubleTapCount<0)
		DoubleTapCount=0;
	if (IsClientInGame(client)==true
		&& IsPlayerAlive(client)==true
		&& SurvivorUpgrade1[client]==4
		&& PerksConfirmed[client]==1
		&& GetClientTeam(client)==2)
	{
		DoubleTapCount++;
		DoubleTapIndex[DoubleTapCount]=client;

		//----DEBUG----
		//PrintToChatAll("\x03double tap on confirm, registering \x01%i",client);
	}	
}

//called whenever the registry needs to be rebuilt
//to cull any players who have left or died, etc.
//(called on: player death, player disconnect,
//closet rescue, change teams)
DoubleTap_Rebuild ()
{
	//clears all DT-related vars
	DoubleTap_Clear();

	//if the server's not running or
	//is in the middle of loading, stop
	if (IsServerProcessing()==false)
		return;

	//----DEBUG----
	//PrintToChatAll("\x03double tap rebuilding registry");

	for (new i=1 ; i<=18 ; i++)
	{
		if (IsClientInGame(i)==true
			&& IsPlayerAlive(i)==true
			&& SurvivorUpgrade1[i]==4
			&& PerksConfirmed[i]==1
			&& GetClientTeam(i)==2)
		{
			DoubleTapCount++;
			DoubleTapIndex[DoubleTapCount]=i;

			//----DEBUG----
			//PrintToChatAll("\x03-registering \x01%i",i);
		}
	}
}

//called to clear out DT registry
//(called on: round start, round end, map end)
DoubleTap_Clear ()
{
	DoubleTapCount=0;
	for (new i=1 ; i<=18 ; i++)
	{
		DoubleTapIndex[i]= -1;
		DoubleTapWeapon[i] = -1;
		DoubleTapNextShot[i]= -1.0;
	}
}

//this is the big momma!
//since this is called EVERY game frame,
//we need to be careful not to run too many functions
public OnGameFrame()
{
	//if frames aren't being processed,
	//don't bother - otherwise we get LAG
	//or even disconnects on map changes, etc...
	//or if no one has DT, don't bother either
	if (IsServerProcessing()==false)
		return;
	if (DoubleTapCount==0)
		return;

	//this tracks the player's id, just to
	//make life less painful...
	decl client;
	//this tracks the player's gun id
	//since we adjust numbers on the gun,
	//not the player
	decl entity;
	//this tracks the calculated next attack
	decl Float:flNextTime_calc;
	//this, on the other hand, tracks the current next attack
	decl Float:flNextTime_ret;
	//and this tracks next melee attack times
	decl Float:flNextTime2_ret;
	//and this tracks the game time
	new Float:flGameTime=GetGameTime();

	//theoretically, to get on the DT registry
	//all the necessary checks would have already
	//been run, so we don't bother with any checks here
	for (new i=1; i<=DoubleTapCount; i++)
	{
		//PRE-CHECKS: RETRIEVE VARS
		//-------------------------

		client = DoubleTapIndex[i];
		//stop on this client
		//when the next client id is null
		if (client <= 0) return;
		//skip this client if they're disabled
		if (SpiritState[client]==1) continue;

		//we have to adjust numbers on the gun, not the player
		//so we get the active weapon id here
		entity = GetEntDataEnt2(client,g_iActiveGunO);
		//if the retrieved gun id is -1, then...
		//wtf mate? just move on
		if (entity == -1) continue;
		//and here is the retrieved next attack time
		flNextTime_ret = GetEntDataFloat(entity,g_iNextPAttO);
		//and for retrieved next melee time
		flNextTime2_ret = GetEntDataFloat(entity,g_iNextSAttO);

		//----DEBUG----
		/*
		new iNextAttO=	FindSendPropInfo("CTerrorPlayer","m_flNextAttack");
		new iIdleTimeO=	FindSendPropInfo("CTerrorGun","m_flTimeWeaponIdle");
		PrintToChatAll("\x03DT, NextAttack \x01%i %f\x03, TimeIdle \x01%i %f",
			iNextAttO,
			GetEntDataFloat(client,iNextAttO),
			iIdleTimeO,
			GetEntDataFloat(entity,iIdleTimeO)
			);
		*/


		//CHECK 1: BEFORE ADJUSTED SHOT IS MADE
		//------------------------------------
		//since this will probably be the case most of
		//the time, we run this first
		//checks: gun is unchanged; time of shot has not passed
		//actions: nothing
		if (DoubleTapWeapon[client]==entity
			&& DoubleTapNextShot[client]>=flNextTime_ret)
		{
			//----DEBUG----
			//PrintToChatAll("\x03DT client \x01%i\x03; before shot made",client );

			continue;
		}


		//CHECK 2: INFER IF MELEEING
		//--------------------------
		//since we don't want to shorten the interval
		//incurred after swinging, we try to guess when
		//a melee attack is made
		//checks: if melee attack time > engine time
		//actions: nothign
		if (flNextTime2_ret > flGameTime)
		{
			//----DEBUG----
			//PrintToChatAll("\x03DT client \x01%i\x03; melee attack inferred",client );

			continue;
		}


		//CHECK 3: AFTER ADJUSTED SHOT IS MADE
		//------------------------------------
		//at this point, either a gun was swapped, or
		//the attack time needs to be adjusted
		//checks: stored gun id same as retrieved gun id,
		// and retrieved next attack time is after stored value
		if (DoubleTapWeapon[client]==entity
			&& DoubleTapNextShot[client] < flNextTime_ret)
		{
			//----DEBUG----
			//PrintToChatAll("\x03DT after adjusted shot\n-pre, client \x01%i\x03; entid \x01%i\x03; enginetime\x01 %f\x03; NextTime_orig \x01 %f\x03; interval \x01%f",client,entity,flGameTime,flNextTime_ret, flNextTime_ret-flGameTime );

			//this is a calculation of when the next primary attack
			//will be after applying double tap values
			flNextTime_calc = ( flNextTime_ret - flGameTime ) * g_flDT_rate + flGameTime;

			//then we store the value
			DoubleTapNextShot[client] = flNextTime_calc;

			//and finally adjust the value in the gun
			SetEntDataFloat(entity, g_iNextPAttO, flNextTime_calc, true);

			//----DEBUG----
			//PrintToChatAll("\x03-post, NextTime_calc \x01 %f\x03; new interval \x01%f",GetEntDataFloat(entity,g_iNextPAttO), GetEntDataFloat(entity,g_iNextPAttO)-flGameTime );

			continue;
		}


		//CHECK 4: ON WEAPON SWITCH
		//-------------------------
		//at this point, the only reason DT hasn't fired
		//should be that the weapon had switched
		//checks: retrieved gun id doesn't match stored id
		// or stored id is null
		//actions: updates stored gun id
		// and sets stored next attack time to retrieved value
		if (DoubleTapWeapon[client] != entity)
		{
			//----DEBUG----
			//PrintToChatAll("\x03DT client \x01%i\x03; weapon switch inferred",client );

			//now we update the stored vars
			DoubleTapWeapon[client]=entity;
			DoubleTapNextShot[client]=flNextTime_ret;
			continue;
		}

		//----DEBUG----
		//PrintToChatAll("\x03DT client \x01%i\x03; reached end of checklist...",client );
	}
}



//=============================
// Sur1: Sleight of Hand
//=============================

//on the start of a reload
public Event_Reload (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (client==0) return;
	if (SurvivorUpgrade1[client]==6
		&& PerksConfirmed[client]==1
		&& GetClientTeam(client)==2)
	{
		//----DEBUG----
		//PrintToChatAll("\x03SoH client \x01%i\x03; start of reload detected",client );

		new entity = GetEntDataEnt2(client,g_iActiveGunO);
		if (IsValidEntity(entity)==false) return;

		decl String:stClass[32];
		GetEntityNetClass(entity,stClass,32);

		//----DEBUG----
		//PrintToChatAll("\x03-class of gun: \x01%s",stClass );

		//for non-shotguns
		if (StrContains(stClass,"shotgun",false) == -1)
		{
			SoH_MagStart(entity,client);
			return;
		}

		//shotguns are a bit trickier since the game
		//tracks per shell inserted - and there's TWO
		//different shotguns with different values =.=
		else if (StrContains(stClass,"autoshotgun",false) != -1)
		{
			CreateTimer(0.1,SoH_AutoshotgunStart,entity);
			return;
		}

		else if (StrContains(stClass,"pumpshotgun",false) != -1)
		{
			CreateTimer(0.1,SoH_PumpshotgunStart,entity);
			return;
		}
	}
}

//called for mag loaders
SoH_MagStart (entity, client)
{
	//----DEBUG----
	//PrintToChatAll("\x03-magazine loader detected");

	new Float:flGameTime = GetGameTime();
	new Float:flNextTime_ret = GetEntDataFloat(entity,g_iNextPAttO);

	//----DEBUG----
	/*PrintToChatAll("\x03- pre, gametime \x01%f\x03, retrieved nextattack\x01 %i %f\x03, retrieved time idle \x01%i %f",
		flGameTime,
		g_iNextAttO,
		GetEntDataFloat(client,g_iNextAttO),
		g_iTimeIdleO,
		GetEntDataFloat(entity,g_iTimeIdleO)
		);*/

	//this is a calculation of when the next primary attack
	//will be after applying sleight of hand values
	//NOTE: at this point, only calculate the interval itself,
	//without the actual game engine time factored in
	new Float:flNextTime_calc = ( flNextTime_ret - flGameTime ) * g_flSoH_rate ;

	//we change the playback rate of the gun
	//just so the player can "see" the gun reloading faster
	SetEntDataFloat(entity, g_iPlayRateO, 1.0/g_flSoH_rate, true);

	//create a timer to reset the playrate after
	//time equal to the modified attack interval
	CreateTimer( flNextTime_calc, SoH_MagEnd, entity );
	CreateTimer( (flNextTime_ret-flGameTime+0.3), SoH_MagEnd2, entity );

	//and finally we set the end reload time into the gun
	//so the player can actually shoot with it at the end
	flNextTime_calc += flGameTime;
	SetEntDataFloat(entity, g_iTimeIdleO, flNextTime_calc, true);
	SetEntDataFloat(entity, g_iNextPAttO, flNextTime_calc, true);
	SetEntDataFloat(client, g_iNextAttO, flNextTime_calc, true);

	//----DEBUG----
	/*PrintToChatAll("\x03- post, calculated nextattack \x01%f\x03, gametime \x01%f\x03, retrieved nextattack\x01 %i %f\x03, retrieved time idle \x01%i %f",
		flNextTime_calc,
		flGameTime,
		g_iNextAttO,
		GetEntDataFloat(client,g_iNextAttO),
		g_iTimeIdleO,
		GetEntDataFloat(entity,g_iTimeIdleO)
		);*/
}

//called for autoshotguns
public Action:SoH_AutoshotgunStart (Handle:timer, any:entity)
{
	//----DEBUG----
	/*PrintToChatAll("\x03-autoshotgun detected, entity \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i",
		entity,
		g_iShotStartDurO,
		g_iShotInsertDurO,
		g_iShotEndDurO
		);
	PrintToChatAll("\x03- pre mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_flSoHAutoS,
		g_flSoHAutoI,
		g_flSoHAutoE
		);*/
				
	//then we set the new times in the gun
	SetEntDataFloat(entity,	g_iShotStartDurO,	g_flSoHAutoS*g_flSoH_rate,	true);
	SetEntDataFloat(entity,	g_iShotInsertDurO,	g_flSoHAutoI*g_flSoH_rate,	true);
	SetEntDataFloat(entity,	g_iShotEndDurO,		g_flSoHAutoE*g_flSoH_rate,	true);

	//we change the playback rate of the gun
	//just so the player can "see" the gun reloading faster
	SetEntDataFloat(entity, g_iPlayRateO, 1.0/g_flSoH_rate, true);

	//and then call a timer to periodically check whether the
	//gun is still reloading or not to reset the animation
	//but first check the reload state; if it's 2, then it
	//needs a pump/cock before it can shoot again, and thus
	//needs more time
	if (GetEntData(entity,g_iShotReloadStateO)==2)
		CreateTimer(0.3,SoH_ShotgunEndCock,entity,TIMER_REPEAT);
	else
		CreateTimer(0.3,SoH_ShotgunEnd,entity,TIMER_REPEAT);

	//----DEBUG----
	/*PrintToChatAll("\x03- after mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_flSoHAutoS,
		g_flSoHAutoI,
		g_flSoHAutoE
		);*/

	return Plugin_Continue;
}

//called for pump shotguns
public Action:SoH_PumpshotgunStart (Handle:timer, any:entity)
{
	//----DEBUG----
	/*PrintToChatAll("\x03-pumpshotgun detected, entity \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i",
		entity,
		g_iShotStartDurO,
		g_iShotInsertDurO,
		g_iShotEndDurO
		);
	PrintToChatAll("\x03- pre mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_flSoHPumpS,
		g_flSoHPumpI,
		g_flSoHPumpE
		);*/

	//then we set the new times in the gun
	SetEntDataFloat(entity,	g_iShotStartDurO,	g_flSoHPumpS*g_flSoH_rate,	true);
	SetEntDataFloat(entity,	g_iShotInsertDurO,	g_flSoHPumpI*g_flSoH_rate,	true);
	SetEntDataFloat(entity,	g_iShotEndDurO,		g_flSoHPumpE*g_flSoH_rate,	true);

	//we change the playback rate of the gun
	//just so the player can "see" the gun reloading faster
	SetEntDataFloat(entity, g_iPlayRateO, 1.0/g_flSoH_rate, true);

	//and then call a timer to periodically check whether the
	//gun is still reloading or not to reset the animation
	if (GetEntData(entity,g_iShotReloadStateO)==2)
		CreateTimer(0.3,SoH_ShotgunEndCock,entity,TIMER_REPEAT);
	else
		CreateTimer(0.3,SoH_ShotgunEnd,entity,TIMER_REPEAT);

	//----DEBUG----
	/*PrintToChatAll("\x03- after mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_flSoHPumpS,
		g_flSoHPumpI,
		g_flSoHPumpE
		);*/

	return Plugin_Continue;
}

//this resets the playback rate on non-shotguns
public Action:SoH_MagEnd (Handle:timer, any:entity)
{
	//----DEBUG----
	//PrintToChatAll("\x03SoH reset playback, magazine loader");

	if (entity <= 0
		|| IsValidEntity(entity)==false)
		return Plugin_Stop;

	SetEntDataFloat(entity, g_iPlayRateO, 0.1, true);
	return Plugin_Continue;
}

public Action:SoH_MagEnd2 (Handle:timer, any:entity)
{
	SetEntDataFloat(entity, g_iPlayRateO, 1.0, true);
	return Plugin_Continue;
}

//this resets the playback rate on shotguns
public Action:SoH_ShotgunEnd (Handle:timer, any:entity)
{
	//----DEBUG----
	//PrintToChatAll("\x03-autoshotgun tick");

	if (entity <= 0
		|| IsValidEntity(entity)==false)
		return Plugin_Stop;

	if (GetEntData(entity,g_iShotReloadStateO)==0)
	{
		//----DEBUG----
		//PrintToChatAll("\x03-shotgun end reload detected");

		SetEntDataFloat(entity, g_iPlayRateO, 1.0, true);

		new client=GetEntPropEnt(entity,Prop_Data,"m_hOwner");
		new Float:flTime=GetGameTime()+0.2;
		SetEntDataFloat(client,	g_iNextAttO,	flTime,	true);
		SetEntDataFloat(entity,	g_iTimeIdleO,	flTime,	true);
		SetEntDataFloat(entity,	g_iNextPAttO,	flTime,	true);

		return Plugin_Stop;
	}
	return Plugin_Continue;
}

//since cocking requires more time, this function does
//exactly as the above, except it adds slightly more time
public Action:SoH_ShotgunEndCock (Handle:timer, any:entity)
{
	//----DEBUG----
	//PrintToChatAll("\x03-autoshotgun tick");

	if (entity <= 0
		|| IsValidEntity(entity)==false)
		return Plugin_Stop;

	if (GetEntData(entity,g_iShotReloadStateO)==0)
	{
		//----DEBUG----
		//PrintToChatAll("\x03-shotgun end reload + cock detected");

		SetEntDataFloat(entity, g_iPlayRateO, 1.0, true);

		new client=GetEntPropEnt(entity,Prop_Data,"m_hOwner");
		new Float:flTime= GetGameTime() + 1.0;
		SetEntDataFloat(client,	g_iNextAttO,	flTime,	true);
		SetEntDataFloat(entity,	g_iTimeIdleO,	flTime,	true);
		SetEntDataFloat(entity,	g_iNextPAttO,	flTime,	true);

		return Plugin_Stop;
	}
	return Plugin_Continue;
}



//=============================
// Sur1: Pyrotechnician,
// Sur2: Pack Rat
//=============================

//if item that was picked up is a grenade type, set carried amount in var
public Event_ItemPickup (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (client==0) return;
	if (PerksConfirmed[client]==0) return;
	//check for grenadier perk
	if (SurvivorUpgrade1[client]==2)
	{
		switch (GrenadeBeingTossed[client])
		{
		//only bother with checks if they aren't throwing
		case 0:
			{
				decl String:st_wpn[24];
				GetEventString(event,"item",st_wpn,24);
				new bool:bPipe=StrEqual(st_wpn,"pipe_bomb",false);
				//check if the weapon is a grenade type
				if (bPipe==true
					|| StrEqual(st_wpn,"molotov",false)==true)
				{
					if (bPipe==true)
					{
						st_wpn="pipe bomb";
					}
					//if so, then check if either 0 or 2 are being carried
					//if true, then act normally and give player 2 grenades
					if (GrenadesCarried[client]==0
						|| GrenadesCarried[client]==2)
					{
						GrenadesCarried[client]=2;
						PrintHintText(client,"Grenadier: You are carrying %i %s(s)",GrenadesCarried[client],st_wpn);
					}
					//otherwise, only give them one and tell them to
					//throw the grenade before picking up another one;
					//this is to prevent abuses with throwing infinite nades
					else
					{
						GrenadesCarried[client]=1;
						PrintHintText(client,"You only picked up one %s! Throw your second grenade before picking up another.",st_wpn);
					}
				}
			}
		//if they are in the middle of throwing, then reset the var
		case 1: GrenadeBeingTossed[client]=0;
		}
	}

	//then check for pack rat perk separately
	if (SurvivorUpgrade2[client]==3)
	{
		decl String:st_wpn[24];
		GetEventString(event,"item",st_wpn,24);

		//only give ammo to owned gun, to prevent abuses

		if (StrEqual(st_wpn,"smg",false))
		{
			new iAmmoO=FindDataMapOffs(client,"m_iAmmo");
			//smg ammo +160, m_iAmmo offset +20
			SetEntData(client, iAmmoO	+20, GetEntData(client,iAmmoO	+20)	+PackRat_SMG);
			return ;
		}

		else if (StrEqual(st_wpn,"pumpshotgun",false)
			|| StrEqual(st_wpn,"autoshotgun",false))
		{
			new iAmmoO=FindDataMapOffs(client,"m_iAmmo");
			//pump,autoshotgun ammo +32, m_iAmmo offset +24
			SetEntData(client,iAmmoO	+24,GetEntData(client,iAmmoO	+24)	+PackRat_pumpgun);
			return ;
		}

		else if (StrEqual(st_wpn,"rifle",false))
		{
			new iAmmoO=FindDataMapOffs(client,"m_iAmmo");
			//rifle ammo +120, m_iAmmo offset +12
			SetEntData(client, iAmmoO	+12, GetEntData(client,iAmmoO	+12)	+PackRat_m4rifle);
			return ;
		}

		else if (StrEqual(st_wpn,"hunting_rifle",false))
		{
			new iAmmoO=FindDataMapOffs(client,"m_iAmmo");
			//hunting rifle ammo +50, m_iAmmo offset +8
			SetEntData(client, iAmmoO	+8, GetEntData(client,iAmmoO	+8)		+PackRat_sniper);
			return ;
		}
	}
}



//=============================
// Sur1: Pyrotechnician
//=============================

//called when tossing
public Event_WeaponFire (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (client==0) return;
	if (PerksConfirmed[client]==0) return;
	decl String:st_wpn[24];
	GetEventString(event,"weapon",st_wpn,24);
	new bool:b_pipe=StrEqual(st_wpn,"pipe_bomb",false);
	new bool:b_mol=StrEqual(st_wpn,"molotov",false);
	if (SurvivorUpgrade1[client]==2
		&& (b_pipe || b_mol))
	{
		GrenadesCarried[client]--;		//reduce count by 1
		if (GrenadesCarried[client]>0)		//do they still have grenades left?
		{
			if (b_pipe==true)
			{
				GrenadeType[client]=1;
				st_wpn="pipe bomb";
			}
			else
			{
				GrenadeType[client]=2;
			}
			PrintHintText(client,"Grenadier: You have %i %s(s) left",GrenadesCarried[client],st_wpn);
			CreateTimer(2.5,Grenadier_DelayedGive,client);
		}
	}
}

//gives the grenade a few seconds later 
//(L4D takes a while to remove the grenade from inventory after it's been thrown)
public Action:Grenadier_DelayedGive (Handle:timer,any:client)
{
	if (client==0
		|| PerksConfirmed[client]==0
		|| SurvivorUpgrade1[client]!=2)
		return Plugin_Continue;

	new iflags=GetCommandFlags("give");
	decl String:st_give[24];
	if (GrenadeType[client]==1) st_give="give pipe_bomb";
	else st_give="give molotov";
	GrenadeType[client]=0;
	GrenadeBeingTossed[client]=1;	//client now considered to be "in the middle of throwing"
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(client,st_give);
	SetCommandFlags("give", iflags);
	return Plugin_Continue;
}

//called on roundstarts or on confirming perks
//gives a random grenade to the player
Event_Confirm_Grenadier (client)
{
	if (client==0
		|| GetClientTeam(client)!=2
		|| IsPlayerAlive(client)==false
		|| PerksConfirmed[client]==0
		|| SurvivorUpgrade1[client]!=2) return;
	new iflags=GetCommandFlags("give");
	decl String:st_give[24];
	if (GetRandomInt(1,2)==1) st_give="give pipe_bomb";
	else st_give="give molotov";
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(client,st_give);
	SetCommandFlags("give", iflags);
	return;
}



//=============================
// Sur2: Chem Reliant
//=============================

public Action:Event_PillsUsed (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"subject"));
	if (client==0) return Plugin_Continue;

	//----DEBUG----
	//PrintToChatAll("\x03Pill user: \x01%i", client);

	if (SurvivorUpgrade2[client]==1
		&& PerksConfirmed[client]==1)
	{
		new Float:flBuff=GetEntDataFloat(client,g_iHPBuffO);
		new iHP=GetEntProp(client,Prop_Data,"m_iHealth");
		
		//so we need to test the maxbound for
		//how much health buffer we can give
		//which can vary depending on whether
		//they have unbreakable or not

		//CASE 1: HAS UNBREAKABLE
		if (SurvivorUpgrade1[client]==5)
		{
			//CASE 1A:
			//combined health + chem reliant < max health possible
			if (flBuff + iHP + g_iChem_buff < 100 + g_iUnbreak_hp)
				//this is the easiest, just give them chem reliant bonus
				SetEntDataFloat(client,g_iHPBuffO, flBuff+g_iChem_buff ,true);

			//CASE 1B:
			//combined health + chem reliant > max health possible
			else
				//this is a bit trickier, give them the difference
				//between the max health possible and their current health
				SetEntDataFloat(client,g_iHPBuffO, (100.0+g_iUnbreak_hp)-iHP ,true);
		}
		//CASE 2: DOES NOT HAVE UNBREAKABLE
		else
		{
			//CASE 1A:
			//combined health + chem reliant < max health possible
			if (flBuff + iHP + g_iChem_buff < 100)
				//this is the easiest, just give them chem reliant bonus
				SetEntDataFloat(client,g_iHPBuffO, flBuff+g_iChem_buff ,true);

			//CASE 1B:
			//combined health + chem reliant > max health possible
			else
				//this is a bit trickier, give them the difference
				//between the max health possible and their current health
				SetEntDataFloat(client,g_iHPBuffO, 100.0-iHP ,true);
		}
	}
	return Plugin_Continue;
}

//called on roundstart or on confirming perks,
//gives pills off the start
Event_Confirm_ChemReliant (client)
{
	if (client==0
		|| GetClientTeam(client)!=2
		|| IsPlayerAlive(client)==false
		|| PerksConfirmed[client]==0
		|| SurvivorUpgrade2[client]!=1)
		return;

	new iflags=GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(client,"give pain_pills");
	SetCommandFlags("give", iflags);

	return;
}


//=============================
// Sur2: Helping Hand,
// Sur1: Spirit
//=============================

//at end of revive, reset convars and give bonus temp hp
//also handles ledge hangs (for spirit perk)
public Event_ReviveSuccess (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	new iSub=GetClientOfUserId(GetEventInt(event,"subject"));

	if (client==0 || iSub==0) return;

	//----DEBUG----
	//PrintToChatAll("\x03life giver success detected, reviver: \x01%i\x03, subject: \x01%i",client,iSub);

	if (SurvivorUpgrade2[client]==2
		&& PerksConfirmed[client]==1)
	{
		switch (GetEventInt(event,"ledge_hang"))
		{
		case 1:
			{
				SpiritState[iSub]=0;

				//----DEBUG----
				//PrintToChatAll("\x03-ledge hang save detected");
			}
		case 0:
			{
				//----DEBUG----
				//PrintToChatAll("\x03-m_healthBuffer offset: \x01%i",iHPBuffO);
				//PrintToChatAll("\x03-client \x01%i\x03 value at offset: \x01%f",iSub,GetEntDataFloat(iSub,g_iHPBuffO));

				decl iBuff;
				if (g_iL4D_GameMode==2)
					iBuff=g_iHelpHand_buff_vs;
				else
					iBuff=g_iHelpHand_buff;

				SetEntDataFloat(iSub,g_iHPBuffO, GetEntDataFloat(iSub,g_iHPBuffO)+iBuff ,true);

				//----DEBUG----
				//PrintToChatAll("\x03-value at offset, post-mod: \x01%f",GetEntDataFloat(iSub,g_iHPBuffO));

				decl String:st_name[24];
				GetClientName(iSub,st_name,24);
				PrintHintText(client,"Helping Hand: gave bonus temporary health to %s!",st_name);
				GetClientName(client,st_name,24);
				PrintHintText(iSub,"Helping Hand: %s gave you bonus temporary health!",st_name);
			}
		}
	}

	//for the spirit perk,
	//player is labelled as no longer incapped
	IsIncapped[iSub]=0;

}



//=============================
// Sur2: Pack Rat
//=============================

//calculates ammo capacity
PackRat_Calculate ()
{
	SMG_MaxAmmo = GetConVarInt(FindConVar("ammo_smg_max"));
	Pumpgun_MaxAmmo = GetConVarInt(FindConVar("ammo_buckshot_max"));
	M4Rifle_MaxAmmo = GetConVarInt(FindConVar("ammo_assaultrifle_max"));
	Sniper_MaxAmmo = GetConVarInt(FindConVar("ammo_huntingrifle_max"));
	
	PackRat_SMG		=	RoundToNearest( SMG_MaxAmmo * g_flPack_ammomult );
	PackRat_pumpgun	=	RoundToNearest( Pumpgun_MaxAmmo * g_flPack_ammomult );
	PackRat_m4rifle		=	RoundToNearest( M4Rifle_MaxAmmo * g_flPack_ammomult );
	PackRat_sniper	=	RoundToNearest( Sniper_MaxAmmo * g_flPack_ammomult );
}

//on ammo pickup, check if pack rat is in effect
public Event_AmmoPickup (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (client==0) return;
	if (SurvivorUpgrade2[client]==3 && PerksConfirmed[client]==1)
	{
		new iAmmoO=FindDataMapOffs(client,"m_iAmmo");
		//hunting rifle ammo +60, m_iAmmo offset +8
		SetEntData(client, iAmmoO	+8, Sniper_MaxAmmo + PackRat_sniper );
		//rifle ammo +120, m_iAmmo offset +12
		SetEntData(client, iAmmoO	+12, M4Rifle_MaxAmmo + PackRat_m4rifle );
		//smg ammo +160, m_iAmmo offset +20
		SetEntData(client, iAmmoO	+20, SMG_MaxAmmo + PackRat_SMG );
		//pump,autoshotgun ammo +32, m_iAmmo offset +24
		SetEntData(client, iAmmoO	+24, Pumpgun_MaxAmmo + PackRat_pumpgun );
	}
}

//called on confirming perks, show hint to pick up ammo now
public Event_Confirm_PackRat (client)
{
	if (client==0) return;
	if (PerksConfirmed[client]==1
		&& GetClientTeam(client)==2)
	{
		if (SurvivorUpgrade2[client]==3)
		{
			new iAmmoO=FindDataMapOffs(client,"m_iAmmo");
			decl iAmmoCount;
			//hunting rifle ammo +60, m_iAmmo offset +8
			iAmmoCount=GetEntData(client,iAmmoO	+8);
			if (iAmmoCount<Sniper_MaxAmmo)
				SetEntData(client, iAmmoO	+8, iAmmoCount + PackRat_sniper );
			else
				SetEntData(client, iAmmoO +8, Sniper_MaxAmmo + PackRat_sniper );
			//rifle ammo +120, m_iAmmo offset +12
			iAmmoCount=GetEntData(client,iAmmoO	+12);
			if (iAmmoCount<M4Rifle_MaxAmmo)
				SetEntData(client, iAmmoO	+12, iAmmoCount + PackRat_m4rifle );
			else
				SetEntData(client, iAmmoO +12, M4Rifle_MaxAmmo + PackRat_m4rifle );
			//smg ammo +160, m_iAmmo offset +20
			iAmmoCount=GetEntData(client,iAmmoO	+20);
			if (iAmmoCount<SMG_MaxAmmo)
				SetEntData(client, iAmmoO	+20, iAmmoCount + PackRat_SMG );
			else
				SetEntData(client, iAmmoO +20, SMG_MaxAmmo + PackRat_SMG );
			//pump,autoshotgun ammo +32, m_iAmmo offset +24
			iAmmoCount=GetEntData(client,iAmmoO	+24);
			if (iAmmoCount<Pumpgun_MaxAmmo)
				SetEntData(client, iAmmoO	+24, iAmmoCount + PackRat_pumpgun );
			else
				SetEntData(client, iAmmoO +24, Pumpgun_MaxAmmo + PackRat_pumpgun );
		}
		//if the perk changed, check for ammo count of each gun
		//if it's higher than default max, reduce to default max
		else
		{
			new iAmmoO=FindDataMapOffs(client,"m_iAmmo");
			decl iAmmoCount;

			//check hunting rifle ammo, m_iAmmo offset +8
			iAmmoCount=GetEntData(client,iAmmoO	+8);
			if (iAmmoCount>Sniper_MaxAmmo) SetEntData(client, iAmmoO	+8, Sniper_MaxAmmo);
			//check rifle ammo, m_iAmmo offset +12
			iAmmoCount=GetEntData(client,iAmmoO	+12);
			if (iAmmoCount>M4Rifle_MaxAmmo) SetEntData(client, iAmmoO	+12, M4Rifle_MaxAmmo);
			//check smg ammo, m_iAmmo offset +20
			iAmmoCount=GetEntData(client,iAmmoO	+20);
			if (iAmmoCount>SMG_MaxAmmo) SetEntData(client, iAmmoO	+20, SMG_MaxAmmo);
			//check shotgun ammo, m_iAmmo offset +24
			iAmmoCount=GetEntData(client,iAmmoO	+24);
			if (iAmmoCount>Pumpgun_MaxAmmo) SetEntData(client, iAmmoO	+24, Pumpgun_MaxAmmo);
		}
	}
}

//called when player tries to pick up ammo,
//and has more than default max but less than perk max
public Event_PlayerUse (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (client==0) return;
	new entity=GetEventInt(event,"targetid");
	decl String:st_entname[32];
	GetEdictClassname(entity,st_entname,32);

	//----DEBUG----
	/*
	PrintToChatAll("entity = %i",entity);
	PrintToChatAll("edict classname = %s",st_entname);
	*/

	//for any of the following code to work,
	//the player MUST have the pack rat perk
	//and have confirmed their perks
	if (SurvivorUpgrade2[client]==3
		&& PerksConfirmed[client]==1)
	{

		//if it's an ammo dump, check through all weapon ammo
		if (StrEqual(st_entname,"weapon_ammo_spawn")==true)
		{
			new iAmmoO=FindDataMapOffs(client,"m_iAmmo");
			decl iAmmoCount;
			decl iNewAmmoCount;

			//check hunting rifle ammo, m_iAmmo offset +8
			iAmmoCount=		GetEntData(client,iAmmoO	+8);
			iNewAmmoCount=	Sniper_MaxAmmo + PackRat_sniper;
			if (iAmmoCount>=Sniper_MaxAmmo && iAmmoCount < iNewAmmoCount )
				SetEntData(client, iAmmoO	+8, iNewAmmoCount );

			//check rifle ammo, m_iAmmo offset +12
			iAmmoCount=		GetEntData(client,iAmmoO	+12);
			iNewAmmoCount=	M4Rifle_MaxAmmo + PackRat_m4rifle;
			if (iAmmoCount>=M4Rifle_MaxAmmo && iAmmoCount < iNewAmmoCount )
				SetEntData(client, iAmmoO	+12, iNewAmmoCount );

			//check smg ammo, m_iAmmo offset +20
			iAmmoCount=		GetEntData(client,iAmmoO	+20);
			iNewAmmoCount=	SMG_MaxAmmo + PackRat_SMG;
			if (iAmmoCount>=SMG_MaxAmmo && iAmmoCount < iNewAmmoCount )
				SetEntData(client, iAmmoO	+20, iNewAmmoCount );

			//check shotgun ammo, m_iAmmo offset +24
			iAmmoCount=		GetEntData(client,iAmmoO	+24);
			iNewAmmoCount=	Pumpgun_MaxAmmo + PackRat_pumpgun;
			if (iAmmoCount>=Pumpgun_MaxAmmo && iAmmoCount< iNewAmmoCount )
				SetEntData(client, iAmmoO	+24, iNewAmmoCount );

		}

		//otherwise, if it's a weapon spawn...

		//check if smg needs more ammo
		else if (StrEqual(st_entname,"weapon_smg_spawn")==true)
		{
			new iAmmoO=FindDataMapOffs(client,"m_iAmmo");
			//check smg ammo, m_iAmmo offset +20
			new iAmmoCount=		GetEntData(client,iAmmoO	+20);
			new iNewAmmoCount=	SMG_MaxAmmo + PackRat_SMG;
			if (iAmmoCount>=SMG_MaxAmmo && iAmmoCount < iNewAmmoCount )
				SetEntData(client, iAmmoO	+20, iNewAmmoCount );
		}

		//check if rifle needs more ammo
		else if (StrEqual(st_entname,"weapon_rifle_spawn")==true)
		{
			new iAmmoO=FindDataMapOffs(client,"m_iAmmo");
			//check rifle ammo, m_iAmmo offset +12
			new iAmmoCount=		GetEntData(client,iAmmoO	+12);
			new iNewAmmoCount=	M4Rifle_MaxAmmo + PackRat_m4rifle;
			if (iAmmoCount>=M4Rifle_MaxAmmo && iAmmoCount < iNewAmmoCount )
				SetEntData(client, iAmmoO	+12, iNewAmmoCount );
		}

		//check if hunting rifle needs more ammo
		else if (StrEqual(st_entname,"weapon_hunting_rifle_spawn")==true)
		{
			new iAmmoO=FindDataMapOffs(client,"m_iAmmo");
			//check hunting rifle ammo, m_iAmmo offset +8
			new iAmmoCount=		GetEntData(client,iAmmoO	+8);
			new iNewAmmoCount=	Sniper_MaxAmmo + PackRat_sniper;
			if (iAmmoCount>=Sniper_MaxAmmo && iAmmoCount < iNewAmmoCount )
				SetEntData(client, iAmmoO	+8, iNewAmmoCount );
		}

		//check if shotgun types need more ammo
		else if (StrEqual(st_entname,"weapon_pumpshotgun_spawn")==true
			|| StrEqual(st_entname,"weapon_autoshotgun_spawn")==true)
		{
			new iAmmoO=FindDataMapOffs(client,"m_iAmmo");
			//check shotgun ammo, m_iAmmo offset +24
			new iAmmoCount=		GetEntData(client,iAmmoO	+24);
			new iNewAmmoCount=	Pumpgun_MaxAmmo + PackRat_pumpgun;
			if (iAmmoCount>=Pumpgun_MaxAmmo && iAmmoCount < iNewAmmoCount )
				SetEntData(client, iAmmoO	+24, iNewAmmoCount );
		}

	}
}



//=============================
// Sur2: Hard to Kill
//=============================

//since the pre-event fire version of this function
//for the spirit perk already handles the vars related
//to the incap state (for other perks), this function
//strictly deals with only the hard to kill perk
public Event_Incap (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (client==0
		|| PerksConfirmed[client]==0
		|| GetClientTeam(client)!=2)
		return;

	if (SurvivorUpgrade2[client]==5)
	{
		new iHP=GetEntProp(client,Prop_Data,"m_iHealth");

		//----DEBUG----
		//PrintToChatAll("\x03hard to kill fire, client \x01%i\x03, health \x01%i",client,iHP);

		SetEntProp(client,Prop_Data,"m_iHealth", iHP + RoundToNearest(iHP*g_flHard_hpmult) );
		//SetEntDataFloat(client,g_iHPBuffO, flHPBuff+300 ,true);

		//----DEBUG----
		//PrintToChatAll("\x03-postfire values, health \x01%i",GetEntProp(client,Prop_Data,"m_iHealth"));
	}
}


//=============================
// Sur2: Martial Artist
//=============================

//called on confirming perks
//adds player to registry of MA users
//and sets movement speed
Event_Confirm_MA (client)
{
	if (MartialCount<0)
		MartialCount=0;
	if (IsClientInGame(client)==true
		&& IsPlayerAlive(client)==true
		&& SurvivorUpgrade2[client]==4
		&& PerksConfirmed[client]==1
		&& GetClientTeam(client)==2)
	{
		MartialCount++;
		MartialIndex[MartialCount]=client;

		decl Float:flSpeed;
		if (g_iL4D_GameMode==0)
			flSpeed=1.0*g_flMA_rate_coop;
		else
			flSpeed=1.0*g_flMA_rate;
		SetEntDataFloat(client,g_iLaggedMovementO, flSpeed ,true);

		//----DEBUG----
		//PrintToChatAll("\x03martial artist on confirm, registering \x01%i",client);
	}	
}

//called whenever the registry needs to be rebuilt
//to cull any players who have left or died, etc.
//resets survivor's speeds and reassigns speed boost
//(called on: player death, player disconnect,
//closet rescue, change teams, convar change)
MartialArtist_Rebuild ()
{
	//clears all DT-related vars
	MartialArtist_Clear();

	//if the server's not running or
	//is in the middle of loading, stop
	if (IsServerProcessing()==false)
		return;

	//----DEBUG----
	//PrintToChatAll("\x03martial artist rebuilding registry");

	for (new i=1 ; i<=18 ; i++)
	{
		if (IsClientInGame(i)==true
			&& IsPlayerAlive(i)==true
			&& SurvivorUpgrade2[i]==4
			&& PerksConfirmed[i]==1
			&& GetClientTeam(i)==2)
		{
			MartialCount++;
			MartialIndex[MartialCount]=i;

			decl Float:flSpeed;
			if (g_iL4D_GameMode==0)
				flSpeed=1.0*g_flMA_rate_coop;
			else
				flSpeed=1.0*g_flMA_rate;
			SetEntDataFloat(i,g_iLaggedMovementO, flSpeed ,true);

			//----DEBUG----
			//PrintToChatAll("\x03-registering \x01%i",i);
		}
	}
}

//called to clear out registry
//and reset movement speeds
//(called on: round start, round end, map end)
MartialArtist_Clear ()
{
	MartialCount=0;
	for (new i=1 ; i<=18 ; i++)
	{
		MartialIndex[i]= -1;

		if (IsServerProcessing()==false)
			continue;

		//skip anyone who isn't a valid entity
		if (IsValidEntity(i)==false) continue;

		//since more than one perk
		//gives bonus speed, only
		//reset speeds for survivors
		if (IsClientInGame(i)==true
			&& GetClientTeam(i)==2)
			SetEntDataFloat(i,g_iLaggedMovementO, 1.0 ,true);
	}
}

//fires from "TimerPerks" function above
MA_ResetFatigue ()
{
	decl client;

	//theoretically, to get on the MA registry
	//all the necessary checks would have already
	//been run, so we don't bother with any checks here
	for (new i=1; i<=MartialCount; i++)
	{
		client = MartialIndex[i];
		//stop on this client
		//when the next client id is null
		if (client <= 0) return;
		//skip if it's not a valid entity
		if (IsValidEntity(client)==false) continue;
		//skip this client if they're disabled
		if (SpiritState[client]==1) continue;

		//----DEBUG----
		//PrintToChatAll("\x03martial artist fire, client \x01%i\x03, offset \x01%i",i,g_iMeleeFatigueO);

		SetEntData(client,g_iMeleeFatigueO,0);
	}
}

Regenerator_Heal ()
{
	//PrintToChatAll("Regenerator Call.");
	decl maxclients;
	maxclients = GetMaxClients();
	for (new i=1; i<=maxclients; i++)
	{	
		if (!IsClientInGame(i)) continue;
		if (IsPlayerAlive(i) && GetClientTeam(i) == 3 && SmokerUpgrade[i]==1)
		{
			decl String:st_class[32];
			GetClientModel(i,st_class,32);
			//check for being smoker
			if (StrContains(st_class,"smoker",false) != -1)
			{
				//PrintToChatAll("Regenerator found a Smoker in client %i", i);
				new currenthealth = GetEntProp(i,Prop_Data,"m_iHealth");
				if (g_iRegenerator_heal + currenthealth >= GetConVarInt(FindConVar("z_gas_health")))
				{
					SetEntProp(i, Prop_Data, "m_iHealth", GetConVarInt(FindConVar("z_gas_health")));
					//PrintToChatAll("Max health heal found and set");
				}
				if (g_iRegenerator_heal + currenthealth < GetConVarInt(FindConVar("z_gas_health")))
				{
					SetEntProp(i, Prop_Data, "m_iHealth", g_iRegenerator_heal + currenthealth);
					//PrintToChatAll("Less than max health heal found and set");
				}
				continue;
			}
		}
	}
}

//=============================
// Inf1: acid vomit,
// Inf1: Barf Bagged,
// Inf1: Dead Wreckening
//(credits to grandwaziri and doku for acid vomit)
//=============================

//on becoming slimed, check if player will lose hud
public Event_PlayerNowIt (Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker=GetClientOfUserId(GetEventInt(event,"attacker"));
	new victim=GetClientOfUserId(GetEventInt(event,"userid"));

	if (attacker==0 || victim==0) return;

	//----DEBUG----
	//PrintToChatAll("\x03slimed detected, victim/client: \x01%i\x03, attacker: \x01%i",victim,attacker);

	//tell plugin another one got slimed (pungent)
	SlimedCount++;
	//update plugin var for who vomited last (dead wreckening)
	LastBoomer=attacker;

	//check for acid vomit
	if (BoomerUpgrade[attacker]==1
		&& PerksConfirmed[attacker]==1
		&& IsFakeClient(victim)==false)
	{

		new damage = RoundToFloor(GetConVarFloat(BileDamage));
		new hardhp = GetEntProp(victim, Prop_Data, "m_iHealth");
		
		if (damage < hardhp)
		{
			SetEntProp(victim, Prop_Send, "m_iHealth", (hardhp-damage));
		}

		if (damage > hardhp)
		{
			new Float:temphp = GetEntPropFloat(victim, Prop_Send, "m_healthBuffer");
			new Float:damagefloat = GetConVarFloat(BileDamage);

			if (damagefloat < temphp)
			{
				SetEntPropFloat(victim, Prop_Send, "m_healthBuffer", (temphp - damagefloat));
			}
		}
	}
	
	//don't blind bots as per grandwaziri's plugin, they suck enough anyways
	if (BoomerUpgrade[attacker]==2
		&& PerksConfirmed[attacker]==1
		&& IsFakeClient(victim)==false)
	{
		//SendConVarValue(victim,FindConVar("sv_cheats"),"1");
		//ClientCommand(victim,"hidehud 64");
		SetEntProp(victim, Prop_Send, "m_iHideHUD", 64);

		//----DEBUG----
		//PrintToChatAll("\x03-attempting to hide hud");
	}
	
	new flags = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
	for (new i = 0; i <= 4; i++)
	{
	FakeClientCommand(attacker,"z_spawn zombie auto");
	}
	SetCommandFlags("z_spawn", flags);
	
	//check for barf bagged
	//only spawn a mob if one guy got slimed
	//or if all four got slimed (max 2 extra mobs)
	if (BoomerUpgrade[attacker]==1	&& PerksConfirmed[attacker]==1 && SlimedCount==4)
	{
		new iflags=GetCommandFlags("z_spawn");
		SetCommandFlags("z_spawn", iflags & ~FCVAR_CHEAT);
		FakeClientCommand(attacker,"z_spawn mob auto");
		SetCommandFlags("z_spawn", iflags);
		
		if (SlimedCount==4) PrintHintText(attacker,"Barf Bagged! A larger mob has been called!");
	}

	CreateTimer(15.0,PlayerNoLongerIt,victim);
}

//on drying from slime, remove hud changes
//and lower count of people slimed (pungent)
public Action:PlayerNoLongerIt (Handle:timer, any:client)
{
	if (IsClientInGame(client)==true
		&& IsFakeClient(client)==false)
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
		//SendConVarValue(client,FindConVar("sv_cheats"),"0");

	//----DEBUG----
	//PrintToChatAll("\x03client \x01%i\x03 no longer it \n attempting to restore hud",client);
	//PrintToChatAll("\x03old SlimedCount: \x01%i",SlimedCount);

	if (SlimedCount>4) SlimedCount=3;
	else if (SlimedCount<0) SlimedCount=0;
	else SlimedCount--;

	//----DEBUG----
	//PrintToChatAll("\x03new SlimedCount: \x01%i",SlimedCount);

	return Plugin_Continue;
}

public Action:Event_AbilityUsePre (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (client==0 || PerksConfirmed[client]==0) return Plugin_Continue;
	decl String:st_ab[24];
	GetEventString(event,"ability",st_ab,24);

	//----DEBUG----
	//PrintToChatAll("\x03ability used: \x01%s", st_ab);

	//check for boomer-type perks (motion sickness)
	if (StrEqual(st_ab,"ability_vomit",false)==true)
	{
		if (BoomerUpgrade[client]==4)
		{
			SetConVarFloat(FindConVar("z_vomit_fatigue"),0.0,true,true);
			CreateTimer(GetConVarFloat(FindConVar("z_vomit_duration")), ResetVomitFatigue,0); // reset fatigue after vomit duration. its technically a convar change but .. 2 boomers biling at once?
		}
		else
			SetConVarFloat(FindConVar("z_vomit_fatigue"), g_flVomitFatigueDefault ,true,true);
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public Action:ResetVomitFatigue (Handle:timer, any:data)
{
	SetConVarFloat(FindConVar("z_vomit_fatigue"), g_flVomitFatigueDefault ,true,true);
}


//=============================
// Sur1: Spirit,
// Inf3: Slingshot Stickytongue
//=============================

//and sets player's state to disabled (spirit)
public Action:Event_TongueGrabPre (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (client==0 || victim==0) return Plugin_Continue;

	//spirit perk, tell plugin player is disabled
	SpiritState[victim]=1;
	//+Inf, tell plugin attacker is disabling
	HasGrabbedSomeone[client]=1;
	
	if (SmokerUpgrade[client]==3)
	{
		decl Float:targetpos[3], Float:smokerpos[3];
		GetClientAbsOrigin(client, smokerpos);
		GetClientAbsOrigin(victim, targetpos);
		
		new Float:distance = GetVectorDistance(smokerpos, targetpos);
		if (distance <= 100) return Plugin_Continue; // dont bother if theyre standing close together.
		
		
		decl Float:SmokerEyePos[3];
		decl Float:VictimEyePos[3];
		decl Float:TonguePullVector[3];
		decl Float:TonguePullAngles[3];
		
		GetClientEyePosition(client, SmokerEyePos);
		GetClientEyePosition(victim, VictimEyePos);
		MakeVectorFromPoints(VictimEyePos, SmokerEyePos, TonguePullVector);
		GetVectorAngles(TonguePullVector, TonguePullAngles);

		decl Float:current[3];
		GetEntPropVector(victim, Prop_Data, "m_vecVelocity", current);
		
		new Float:power = GetConVarFloat(g_hSlingshot_force);
		TonguePullVector[0] = FloatMul( Cosine( DegToRad(TonguePullAngles[1])  ) , power);
		TonguePullVector[1] = FloatMul( Sine( DegToRad(TonguePullAngles[1])  ) , power);
		
		decl Float:resulting[3];
		resulting[0] = FloatAdd(current[0], TonguePullVector[0]);
		resulting[1] = FloatAdd(current[1], TonguePullVector[1]);
		resulting[2] = power*2;
		
		new Handle:pulldata = CreateDataPack();
		CreateTimer(0.5, ExecutePull, pulldata);
		WritePackCell(pulldata, victim);
		WritePackFloat(pulldata, resulting[0]);
		WritePackFloat(pulldata, resulting[1]);
		WritePackFloat(pulldata, resulting[2]);
	}

	return Plugin_Continue;
}

public Action:ExecutePull(Handle:times, Handle:pulldata)
{
	ResetPack(pulldata);
	new victim = ReadPackCell(pulldata);
	decl Float:resulting[3];
	resulting[0] = ReadPackFloat(pulldata);
	resulting[1] = ReadPackFloat(pulldata);
	resulting[2] = ReadPackFloat(pulldata);
	CloseHandle(pulldata);
	
	TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, resulting);
}

//fires in all tongue releases
//and set's player state to free (spirit)
//and resets tongue health (staying)
public Event_TongueRelease (Handle:event, const String:name[], bool:dontBroadcast)
{
	//spirit perk, tell plugin player is free
	new victim=GetClientOfUserId(GetEventInt(event,"victim"));
	if (victim!=0) SpiritState[victim]=0;
	//+Inf, tell plugin attacker is no longer disabling
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (client!=0) HasGrabbedSomeone[client]=0;
}

//=============================
// GENERAL: Health Max check
//=============================

//or hunter altered time rate
//also, checks player against max health values
//if they're higher for any reason, set to max
public Event_PlayerSpawn (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));

	//----DEBUG----
	//PrintToChatAll("\x03spawn check init, stored att \x01%i\x03, stored vic \x01%i",g_iSmokeBomber_att[client],g_iSmokeBomber_vic[client]);

	//check survivors for max health
	//they probably don't have any confirmed perks
	//since they just spawned, so set max to 100
	if (GetClientTeam(client)==2)
	{
		if ( GetEntProp(client,Prop_Data,"m_iHealth") > 100 )
			SetEntProp(client,Prop_Data,"m_iHealth", 100 );

		//----DEBUG----
		//PrintToChatAll("\x03spawned survivor \x01%i\x03 health \x01%i", client, GetEntProp(client,Prop_Data,"m_iHealth") );

		return;
	}

	decl String:st_class[32];
	GetClientModel(client,st_class,32);

	//check for smoker first
	if (StrContains(st_class,"smoker",false) != -1)
	{
		//----DEBUG----
		//PrintToChatAll("\x03smoker model detected");

		//run a max health check before
		//doing anything else
		new iMaxHP = GetConVarInt(FindConVar("z_gas_health"));
		if ( GetEntProp(client,Prop_Data,"m_iHealth") > iMaxHP)
			SetEntProp(client,Prop_Data,"m_iHealth", iMaxHP );

		//----DEBUG----
		//PrintToChatAll("\x03spawned smoker \x01%i\x03 health \x01%i\x03, maxhp \x01%i", client, GetEntProp(client,Prop_Data,"m_iHealth"), iMaxHP );

	}

	//then check for hunter
	else if (StrContains(st_class,"hunter",false) != -1)
	{
		//run a max health check before
		//doing anything else
		new iMaxHP = GetConVarInt(FindConVar("z_hunter_health"));
		if ( GetEntProp(client,Prop_Data,"m_iHealth") > iMaxHP)
			SetEntProp(client,Prop_Data,"m_iHealth", iMaxHP );

		//----DEBUG----
		//PrintToChatAll("\x03spawned hunter \x01%i\x03 health \x01%i\x03, maxhp \x01%i", client, GetEntProp(client,Prop_Data,"m_iHealth"), iMaxHP );
	}

	//lastly, check for boomer
	//just for health max
	else if (StrContains(st_class, "boomer", false) != -1)
	{
		//run a max health check before
		//doing anything else
		new iMaxHP = GetConVarInt(FindConVar("z_exploding_health"));
		if ( GetEntProp(client,Prop_Data,"m_iHealth") > iMaxHP)
			SetEntProp(client,Prop_Data,"m_iHealth", iMaxHP );
			
		//check for motion sickness
		if (BoomerUpgrade[client]==4	&& PerksConfirmed[client]==1)
		{
			SetEntDataFloat(client,g_iLaggedMovementO, 1.0*g_flMotion_rate ,true);
		}

		//----DEBUG----
		//PrintToChatAll("\x03spawned boomer \x01%i\x03 health \x01%i\x03, maxhp \x01%i", client, GetEntProp(client,Prop_Data,"m_iHealth"), iMaxHP );
	}
}



//=============================
// Inf4: Grasshopper
//=============================

public Event_AbilityUse (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (client==0) return;

	if (GetClientTeam(client)==3
		&& HunterUpgrade[client]==3
		&& PerksConfirmed[client]==1)
	{
		decl String:st_ab[24];
		GetEventString(event,"ability",st_ab,24);

		//check if it's a pounce/lunge
		if (StrEqual(st_ab,"ability_lunge",false)==true)
		{
			CreateTimer(0.1,Grasshopper_DelayedVel,client);

			//----DEBUG----
			//PrintToChatAll("\x03grasshopper fired");
		}
	}
}

//delayed velocity change, since the hunter doesn't
//actually start moving until some time after the event
public Action:Grasshopper_DelayedVel (Handle:timer, any:client)
{
	decl Float:vecVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVelocity);
	vecVelocity[0] *= g_flGrass_rate;
	vecVelocity[1] *= g_flGrass_rate;
	vecVelocity[2] *= g_flGrass_rate;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}



//=============================
// Inf2: Tank Perks
//=============================


//PRIMARY TANK FUNCTION		----------------------
//primary function for handling tank spawns
public Event_Tank_Spawn (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (client==0
		|| GetClientTeam(client)!=3)
		return;

	//----DEBUG----
	//PrintToChatAll("\x03Tank Spawn detected, client \x01%i\x03,TankMode \x01%i", client, TankMode);

	//start a check if it's a bot
	if (IsFakeClient(client)==true)
	{
		TankBotTicks=0;
		CreateTimer(2.5,Timer_TankBot,client,TIMER_REPEAT);
	}

	else
		Tank_ApplyPerk(client);
}

Tank_ApplyPerk (any:client)
{
	//why apply tank perks to non-infected?
	if (GetClientTeam(client)!=3)
		return;
	
	//and make sure we're dealing with a tank
	decl String:st_class[32];
	GetClientModel(client,st_class,32);
	if (StrContains(st_class,"hulk",false) == -1)
		return;

	//----DEBUG----
	//PrintToChatAll("\x03applying perks; tank detected, model: \x01%s",st_class);

	//first battery of tests for perks 1-4
	if (TankMode<2
		&& PerksConfirmed[client]==1
		&& TankUpgrade[client]<5)
	{
		switch (TankUpgrade[client])
		{
		//check for adrenal glands
		case 1:
			{
				//----DEBUG----
				//PrintToChatAll("\x03applying adrenal glands");

				//WHATEVER

				if (IsFakeClient(client)==false)
					PrintHintText(client,"Adrenal Glands: more Punch damage!");
				TankMode=1;
				return ;
			}
		//check for juggernaut perk
		case 2:
			{
				//----DEBUG----
				//PrintToChatAll("\x03applying juggernaut");

				CreateTimer(0.1,Juggernaut_ChangeHP,client);
				TankMode=2;
				if (IsFakeClient(client)==false)
					PrintHintText(client,"Juggernaut: your health has increased!");

				return ;
			}

		//check for metabolic boost
		case 3:
			{
				//----DEBUG----
				//PrintToChatAll("\x03applying metabolic boost");
				new Float:flSpeed = 1.0 * g_flMetabolic_speedmult;
				SetEntDataFloat(client, g_iLaggedMovementO, flSpeed ,true);
		
				if (IsFakeClient(client)==false)
					PrintHintText(client,"Metabolic Boost: your speed has increased!");
				TankMode=1;
				return ;
			}

		//check for storm caller
		case 4:
			{
				//----DEBUG----
				//PrintToChatAll("\x03applying storm caller");

				new iflags=GetCommandFlags("z_spawn");
				SetCommandFlags("z_spawn", iflags & ~FCVAR_CHEAT);
				for (new i=0 ; i<=g_iStorm_mobcount ; i++)
				{
					FakeClientCommand(client,"z_spawn mob auto");
				}
				SetCommandFlags("z_spawn", iflags);
				if (IsFakeClient(client)==false)
					PrintHintText(client,"Storm Caller: a zombie wave has been summoned!");

				TankMode=1;
				return ;
			}
		}
	}


	//if none of the special perks apply, just tell plugin that there's a tank
	else
	{
		//----DEBUG----
		//PrintToChatAll("\x03nothing applied, setting TankMode to 1");

		TankMode=1;
		return ;
	}
}
//END PRIMARY TANK FUNCTION ----------------------

//timer functions to change tank's hp
//since doing it immediately doesn't seem to work =/
public Action:Juggernaut_ChangeHP (Handle:timer, any:iTankid)
{
	if (IsServerProcessing()==false
		|| iTankid==0
		|| IsClientInGame(iTankid)==false
		|| GetClientTeam(iTankid)!=3)
		return Plugin_Continue;

	SetEntityHealth(iTankid, GetEntProp(iTankid,Prop_Data,"m_iHealth") + g_iJuggernaut_hp );

	//----DEBUG----
	//PrintToChatAll("\x03juggernaut apply hp boost, health\x01 %i", GetEntProp(iTankid,Prop_Data,"m_iHealth"));

	return Plugin_Continue;
}


//timer to check for bots
public Action:Timer_TankBot (Handle:timer, any:iTankid)
{
	if (IsValidEntity(iTankid)==false
		|| IsClientInGame(iTankid)==false
		|| IsFakeClient(iTankid)==false
		|| TankBotTicks>=4)
	{
		//----DEBUG----
		//PrintToChatAll("\x03stopping bot timer");

		return Plugin_Stop;
	}

	if (IsClientInGame(iTankid)==true
		&& IsFakeClient(iTankid)==true)
	{
		TankBotTicks++;

		//----DEBUG----
		//PrintToChatAll("\x03tankbot tick %i",TankBotTicks);

		if (TankBotTicks>=3)
		{
			//----DEBUG----
			PrintToChatAll("\x03[Perk Mod] bot tank detected");

			Tank_ApplyPerk(iTankid);
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}





//====================================================
//====================================================
//					M	E	N	U
//====================================================
//====================================================



//=============================
//	CHAT CHECK, TOP MENU, SELECT SUBMENU
//=============================

//check chat
public Action:MenuOpen_OnSay(client, args)
{
	if (client==0) return Plugin_Continue;
	if (args<1) return Plugin_Continue;
	decl String:st_chat[64];
	GetCmdArg(1,st_chat,64);
	if (StrEqual(st_chat,"!perks",false)==true)
	{
		if (PerksConfirmed[client]==0)
		{
			SendPanelToClient(Menu_Top(client),client,Menu_ChooseSubMenu,MENU_TIME_FOREVER);
			return Plugin_Continue;
		}
		new Handle:menu=CreatePanel();
		SetPanelTitle(menu,"tPoncho's Perkmod: Your perks for this map");
		decl String:st_perk[128];
		//show sur1 perk
		switch (SurvivorUpgrade1[client])
		{
			case 1:
				Format(st_perk,128,"Stopping Power (bonus %i%% damage)", RoundToNearest(g_flStopping_dmgmult*100) );
			case 2:
				Format(st_perk,128,"Pyrotechnician, carry 2 grenades");
			case 3:
				{
					decl iTime;
					if (g_iL4D_GameMode==2)
						iTime=g_iSpirit_cd_vs;
					else if (g_iL4D_GameMode==1)
						iTime=g_iSpirit_cd_sur;
					else
						iTime=g_iSpirit_cd;
					Format(st_perk,128,"Spirit (self-revive on teammate incap, %i min cooldown)", iTime/60 );
				}
			case 4:
				Format(st_perk,128,"Double Tap (fires %i%% faster)", RoundToNearest(100 * ((1/g_flDT_rate)-1) ) ) ;
			case 5:
				Format(st_perk,128,"Unbreakable (bonus +%i health)",g_iUnbreak_hp);
			case 6:
				Format(st_perk,128,"Sleight of Hand (reloads %i%% faster)", RoundToNearest(100 * ((1/g_flSoH_rate)-1) ) ) ;
			default:
				st_perk="Not set";
		}
		DrawPanelItem(menu,"Survivor, primary:");
		DrawPanelText(menu,st_perk);
		//show sur2 perk
		switch (SurvivorUpgrade2[client])
		{
			case 1:
				Format(st_perk,128,"Chem Reliant (bonus +%i temp health with pills)",g_iChem_buff);
			case 2:
				{
					decl iBuff;
					if (g_iL4D_GameMode==2)
						iBuff=g_iHelpHand_buff_vs;
					else
						iBuff=g_iHelpHand_buff;
					Format(st_perk,128,"Helping Hand (give %i bonus buffer)",iBuff);
				}
			case 3:
				Format(st_perk,128,"Pack Rat (carry %i%% more ammo)", RoundToNearest(g_flPack_ammomult*100) );
			case 4:
				{
					if (g_iL4D_GameMode==0)
						Format(st_perk,128,"Martial Artist (run %i%% faster)", RoundToNearest( (g_flMA_rate_coop - 1) * 100 ) );
					else
						Format(st_perk,128,"Martial Artist (no melee fatigue, run %i%% faster)", RoundToNearest( (g_flMA_rate - 1) * 100 ) );
				}
			case 5:
				Format(st_perk,128,"Hard to Kill (%i%% more health when incapped)", RoundToNearest(g_flHard_hpmult*100) );
			default:
				st_perk="Not set";
		}
		DrawPanelItem(menu,"Survivor, secondary:");
		DrawPanelText(menu,st_perk);
		
		//test if it's versus mode,
		//otherwise just send the menu

		if (g_iL4D_GameMode!=2)
		{
			SendPanelToClient(menu,client,Menu_DoNothing,15);
			CloseHandle(menu);
			return Plugin_Continue;
		}

		//if it's gotten this far,
		//it must be versus so continue...

		//show inf1 perk
		switch (BoomerUpgrade[client])
		{
			case 1:
				st_perk="Barf Bagged (vomit attracts more zombies)";
			case 2:
				st_perk="Acid Vomit (survivors lose hud on vomit, vomit damage)";
			case 3:
				Format(st_perk,128,"Dead Wreckening (zombies do %i%% more damage on vomit)", RoundToNearest(100*g_flDead_dmgmult) );
			default: st_perk="Not set";
		}
		DrawPanelItem(menu,"Boomer:");
		DrawPanelText(menu,st_perk);
		//show inf3 perk
		switch (SmokerUpgrade[client])
		{
			case 1:
				st_perk="Regenerator: Heal automatically";
			case 2:
				{
					decl iDmg;
					if (g_iL4D_Difficulty==2)
						iDmg=g_iSqueezer_dmg_expert;
					else if (g_iL4D_Difficulty==1)
						iDmg=g_iSqueezer_dmg_hard;
					else
						iDmg=g_iSqueezer_dmg;
					Format(st_perk,128,"Squeezer (bonus +%i damage)",iDmg);
				}
			default:
				st_perk="Not set";
		}
		DrawPanelItem(menu,"Smoker:");
		DrawPanelText(menu,st_perk);
		//show inf4 perk
		switch (HunterUpgrade[client])
		{
			case 1:
				Format(st_perk,128,"Body Slam (minimum %i pounce damage)",g_iBody_minbound);
			case 2:
				{
					decl iDmg;
					if (g_iL4D_Difficulty==2)
						iDmg=g_iEfficient_dmg_expert;
					else if (g_iL4D_Difficulty==1)
						iDmg=g_iEfficient_dmg_hard;
					else
						iDmg=g_iEfficient_dmg;
					Format(st_perk,128,"Efficient Killer (bonus +%i shred damage)",iDmg);
				}
			case 3:
				Format(st_perk,128,"Grasshopper (pounce %i%% farther)", RoundToNearest( (g_flGrass_rate - 1) * 100 ) );
			case 4:
				{
					decl iDmg;
					if (g_iL4D_Difficulty==2)
						iDmg=g_iOld_dmg_expert;
					else if (g_iL4D_Difficulty==1)
						iDmg=g_iOld_dmg_hard;
					else
						iDmg=g_iOld_dmg;
					Format(st_perk,128,"Old School (bonus +%i claw damage)",iDmg);
				}
			default:
				st_perk="Not set";
		}
		DrawPanelItem(menu,"Hunter:");
		DrawPanelText(menu,st_perk);
		//show inf2 perk
		switch (TankUpgrade[client])
		{
			case 1:
				st_perk="Adrenal Glands (bonus attack power)";
			case 2:
				Format(st_perk,128,"Juggernaut (bonus %i health)",g_iJuggernaut_hp);
			case 3:
				Format(st_perk,128,"Metabolic Boost (speed increases to %i%)", RoundToNearest((g_flMetabolic_speedmult)*100) );
			case 4:
				st_perk="Storm Caller (zombie wave on spawn)";
			default: st_perk="Not set";
		}
		DrawPanelItem(menu,"Tank:");
		DrawPanelText(menu,st_perk);
		SendPanelToClient(menu,client,Menu_DoNothing,15);
		CloseHandle(menu);
	}
	return Plugin_Continue;
}

//build initial menu
public Handle:Menu_Initial (client)
{
	new Handle:menu = CreatePanel();
	SetPanelTitle(menu, "tPoncho's Perkmod");
	DrawPanelText(menu,"This server is using Perkmod");
	DrawPanelText(menu,"Select option 1 to customize your perks");

	DrawPanelItem(menu,"Customize Perks");

	DrawPanelText(menu,"Otherwise, if you just want to");
	DrawPanelText(menu,"jump into the action with default");
	DrawPanelText(menu,"perks select option 2");

	DrawPanelItem(menu,"Use default perks and PLAY NOW!");

	return menu;
}

public Menu_ChooseInit (Handle:topmenu, MenuAction:action, param1, param2)
{
	if (topmenu!=INVALID_HANDLE) CloseHandle(topmenu);
	if (action==MenuAction_Select)
	{
		switch(param2)
		{
			case 1:
				SendPanelToClient(Menu_Top(param1),param1,Menu_ChooseSubMenu,MENU_TIME_FOREVER);
			case 2:
				{
					PerksConfirmed[param1]=1;
					PrintHintText(param1,"Perkmod: Thanks and have fun!");
				}
			default:
				{
					if (IsClientInGame(param1)==true)
						SendPanelToClient(Menu_Top(param1),param1,Menu_ChooseSubMenu,MENU_TIME_FOREVER);
				}
		}
	}

	else
	{
		if (IsClientInGame(param1)==true)
			SendPanelToClient(Menu_Top(param1),param1,Menu_ChooseSubMenu,MENU_TIME_FOREVER);
	}
}

//build top menu
public Handle:Menu_Top (client)
{
	new Handle:menu = CreatePanel();
	SetPanelTitle(menu, "tPoncho's Perkmod - Main Menu");
	DrawPanelText(menu,"Select a submenu to choose a perk");
	DrawPanelText(menu,"(IMPORTANT! Keys 6 through 10 may not");
	DrawPanelText(menu,"be enabled by default. To quickly enable");
	DrawPanelText(menu,"them - enable then disable the gamepad");
	DrawPanelText(menu,"under options - keyboard/mouse)");
	decl String:st_perk[32];
	decl String:st_display[64];

	//set name for sur1 perk
	switch (SurvivorUpgrade1[client])
	{
		case 1: st_perk="Stopping Power";
		case 2: st_perk="Pyrotechnician";
		case 3: st_perk="Spirit";
		case 4: st_perk="Double Tap";
		case 5: st_perk="Unbreakable";
		case 6: st_perk="Sleight of Hand";
		default: st_perk="Not set";
	}
	Format(st_display,64,"Survivor - Primary (%s)",st_perk);
	DrawPanelItem(menu,st_display);

	//set name for sur2 perk
	switch (SurvivorUpgrade2[client])
	{
		case 1: st_perk="Chem Reliant";
		case 2: st_perk="Helping Hand";
		case 3: st_perk="Pack Rat";
		case 4: st_perk="Martial Artist";
		case 5: st_perk="Hard to Kill";
		default: st_perk="Not set";
	}
	Format(st_display,64,"Survivor - Secondary (%s)", st_perk);
	DrawPanelItem(menu,st_display);

	//here we check for versus mode
	//if true, then just draw blanks

	new bool:bModeVersus=false;
	decl String:stArg[64];
	GetConVarString(FindConVar("mp_gamemode"),stArg,64);
	if (StrEqual(stArg,"versus",false)==true)
		bModeVersus=true;
	else
		bModeVersus=false;

	//perks from here on will check whether
	//it's versus, if it is then the line will be blank

	//set name for inf1 perk
	switch (BoomerUpgrade[client])
	{
		case 1: st_perk="Barf Bagged";
		case 2: st_perk="Acid Vomit";
		case 3: st_perk="Dead Wreckening";
		case 4:	st_perk="Motion Sickness";
		default: st_perk="Not set";
	}
	Format(st_display,64,"Boomer (%s)", st_perk);
	if (bModeVersus==true)
		DrawPanelItem(menu,st_display);
	else
		DrawPanelItem(menu,st_display, ITEMDRAW_NOTEXT);

	//set name for inf3 perk
	switch (SmokerUpgrade[client])
	{
		case 1: st_perk="Regenerator";
		case 2: st_perk="Squeezer";
		case 3: st_perk="Slingshot Stickytongue";
		default: st_perk="Not set";
	}
	Format(st_display,64,"Smoker (%s)", st_perk);
	if (bModeVersus==true)
		DrawPanelItem(menu,st_display);
	else
		DrawPanelItem(menu,st_display, ITEMDRAW_NOTEXT);

	//set name for inf4 perk
	switch (HunterUpgrade[client])
	{
		case 1: st_perk="Body Slam";
		case 2: st_perk="Efficient Killer";
		case 3: st_perk="Grasshopper";
		case 4: st_perk="Old School";
		default: st_perk="Not set";
	}
	Format(st_display,64,"Hunter (%s)", st_perk);
	if (bModeVersus==true)
		DrawPanelItem(menu,st_display);
	else
		DrawPanelItem(menu,st_display, ITEMDRAW_NOTEXT);

	//set name for inf2 perk
	switch (TankUpgrade[client])
	{
		case 1: st_perk="Adrenal Glands";
		case 2: st_perk="Juggernaut";
		case 3: st_perk="Metabolic Boost";
		case 4: st_perk="Storm Caller";
		default:st_perk="Not set";
	}
	Format(st_display,64,"Tank (%s)", st_perk);
	if (bModeVersus==true)
		DrawPanelItem(menu,st_display);
	else
		DrawPanelItem(menu,st_display, ITEMDRAW_NOTEXT);

	DrawPanelText(menu,"In order for your perks to work");
	DrawPanelText(menu,"you MUST hit 'done'");
	DrawPanelItem(menu,"DONE");
	return menu;
}

//choose a submenu from top perk menu
public Menu_ChooseSubMenu (Handle:topmenu, MenuAction:action, param1, param2)
{
	if (topmenu!=INVALID_HANDLE) CloseHandle(topmenu);
	if (action==MenuAction_Select)
	{
		switch(param2)
		{
			case 1:
				SendPanelToClient(Menu_Sur1Perk(param1),param1,Menu_ChooseSur1Perk,MENU_TIME_FOREVER);
			case 2:
				SendPanelToClient(Menu_Sur2Perk(param1),param1,Menu_ChooseSur2Perk,MENU_TIME_FOREVER);
			case 3:
				SendPanelToClient(Menu_Inf1Perk(param1),param1,Menu_ChooseInf1Perk,MENU_TIME_FOREVER);
			case 4:
				SendPanelToClient(Menu_Inf3Perk(param1),param1,Menu_ChooseInf3Perk,MENU_TIME_FOREVER);
			case 5:
				SendPanelToClient(Menu_Inf4Perk(param1),param1,Menu_ChooseInf4Perk,MENU_TIME_FOREVER);
			case 6:
				SendPanelToClient(Menu_Inf2Perk(param1),param1,Menu_ChooseInf2Perk,MENU_TIME_FOREVER);
			case 7:
				SendPanelToClient(Menu_Confirm(param1),param1,Menu_ChooseConfirm,MENU_TIME_FOREVER);
			default:
				{
					if (IsClientInGame(param1)==true)
						SendPanelToClient(Menu_Top(param1),param1,Menu_ChooseSubMenu,MENU_TIME_FOREVER);
				}
		}
	}

	else
	{
		if (IsClientInGame(param1)==true)
			SendPanelToClient(Menu_Top(param1),param1,Menu_ChooseSubMenu,MENU_TIME_FOREVER);
	}
}

//menu for confirming perk choices
public Handle:Menu_Confirm (client)
{
	new Handle:menu = CreatePanel();
	SetPanelTitle(menu, "Are you sure?");
	DrawPanelText(menu,"");
	DrawPanelText(menu,"Once confirmed you cannot change");
	DrawPanelText(menu,"your perks until the next map!");
	DrawPanelItem(menu,"CONFIRM");
	DrawPanelText(menu,"If you cancel remember that your");
	DrawPanelText(menu,"perks will not take effect until");
	DrawPanelText(menu,"you hit confirm!");
	DrawPanelItem(menu,"CANCEL");
	return menu;
}

//confirm
public Menu_ChooseConfirm (Handle:topmenu, MenuAction:action, param1, param2)
{
	if (topmenu!=INVALID_HANDLE) CloseHandle(topmenu);
	if (action==MenuAction_Select)
	{
		switch(param2)
		{
			case 1:
			{
				PerksConfirmed[param1]=1;
				PrintToChat(param1,"\x03[SM] You've confirmed your Perk choices; they will now take effect. You may not change your Perks until the next map. \n\n To check your perks, type !perks");
				Event_Confirm_Unbreakable(param1);
				Event_Confirm_PackRat(param1);
				Event_Confirm_Grenadier(param1);
				Event_Confirm_ChemReliant(param1);
				Event_Confirm_DT(param1);
				Event_Confirm_MA(param1);
			}
			case 2:
				SendPanelToClient(Menu_Top(param1),param1,Menu_ChooseSubMenu,MENU_TIME_FOREVER);
			default:
			{
				if (IsClientInGame(param1)==true)
					SendPanelToClient(Menu_Top(param1),param1,Menu_ChooseSubMenu,MENU_TIME_FOREVER);
			}
		}
	}

	else
		SendPanelToClient(Menu_Top(param1),param1,Menu_ChooseSubMenu,MENU_TIME_FOREVER);
}

//do nothing
//for displaying perk choices after confirming
public Menu_DoNothing (Handle:topmenu, MenuAction:action, param1, param2)
{}

//delayed show menu
//to prevent weird not-showing on
//campaign round restarts
public Action:Timer_ShowTopMenu (Handle:timer, any:client)
{
	//----DEBUG----
	//PrintToChatAll("\x03showing menu to \x01%i",client);

	SendPanelToClient(Menu_Top(client),client,Menu_ChooseSubMenu,MENU_TIME_FOREVER);
}



//=============================
//	SUR1 PERK CHOICE
//=============================

//build menu for Sur1 Perks
public Handle:Menu_Sur1Perk (client)
{
	new Handle:menu = CreatePanel();
	SetPanelTitle(menu, "tPoncho's Perkmod - Survivor: Primary");
	decl String:st_display[64];
	decl String:st_current[10];

	//set name for perk 1
	if (g_iStopping_enable==0			&&	g_iL4D_GameMode==0
		|| g_iStopping_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iStopping_enable_vs==0		&&	g_iL4D_GameMode==2)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (SurvivorUpgrade1[client])
		{
			case 1: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Stopping Power %s",st_current);
		DrawPanelItem(menu,st_display);
		Format(st_display,64,"+%i%% damage", RoundToNearest(g_flStopping_dmgmult*100) );
		DrawPanelText(menu,st_display);
	}

	//set name for perk 4
	if (g_iDT_enable==0			&&	g_iL4D_GameMode==0
		|| g_iDT_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iDT_enable_vs==0	&&	g_iL4D_GameMode==2)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (SurvivorUpgrade1[client])
		{
			case 4: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Double Tap %s",st_current);
		DrawPanelItem(menu,st_display);
		Format(st_display,64,"Fire %i%% faster (but not miniguns)", RoundToNearest(100 * ((1/g_flDT_rate)-1) ) );
		DrawPanelText(menu,st_display);
	}

	//set name for perk 6
	if (g_iSoH_enable==0			&&	g_iL4D_GameMode==0
		|| g_iSoH_enable_sur==0		&&	g_iL4D_GameMode==1
		|| g_iSoH_enable_vs==0		&&	g_iL4D_GameMode==2)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (SurvivorUpgrade1[client])
		{
			case 6: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Sleight of Hand %s",st_current);
		DrawPanelItem(menu,st_display);
		Format(st_display,64,"Reload %i%% faster", RoundToNearest(100 * ((1/g_flSoH_rate)-1) ) );
		DrawPanelText(menu,st_display);
	}

	//set name for perk 2
	if (g_iPyro_enable==0			&&	g_iL4D_GameMode==0
		|| g_iPyro_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iPyro_enable_vs==0		&&	g_iL4D_GameMode==2)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (SurvivorUpgrade1[client])
		{
			case 2: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Pyrotechnician %s",st_current);
		DrawPanelItem(menu,st_display);
		DrawPanelText(menu,"Picking up a grenade gives you two");
		DrawPanelText(menu,"and you start the round with a grenade");
	}

	//set name for perk 3
	if (g_iSpirit_enable==0			&&	g_iL4D_GameMode==0
		|| g_iSpirit_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iSpirit_enable_vs==0	&&	g_iL4D_GameMode==2)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (SurvivorUpgrade1[client])
		{
			case 3: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Spirit %s",st_current);
		DrawPanelItem(menu,st_display);
		DrawPanelText(menu,"When a teammate goes down you will self-revive");

		decl iTime;
		if (g_iL4D_GameMode==2)
			iTime=g_iSpirit_cd_vs;
		else if (g_iL4D_GameMode==1)
			iTime=g_iSpirit_cd_sur;
		else
			iTime=g_iSpirit_cd;
		Format(st_display,64,"+%i bonus health buffer, %i min cooldown", g_iSpirit_buff , iTime/60 );
		DrawPanelText(menu,st_display);
	}

	//set name for perk 5
	if (g_iUnbreak_enable==0			&&	g_iL4D_GameMode==0
		|| g_iUnbreak_enable_sur==0		&&	g_iL4D_GameMode==1
		|| g_iUnbreak_enable_vs==0		&&	g_iL4D_GameMode==2)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (SurvivorUpgrade1[client])
		{
			case 5: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Unbreakable %s",st_current);
		DrawPanelItem(menu,st_display);
		Format(st_display,64,"+%i health",g_iUnbreak_hp);
		DrawPanelText(menu,st_display);
	}

	return menu;
}

//setting Sur1 perk and returning to top menu
public Menu_ChooseSur1Perk (Handle:menu, MenuAction:action, param1, param2)
{
	if (menu!=INVALID_HANDLE) CloseHandle(menu);
	if (action==MenuAction_Select)
	{
		switch(param2)
		{
			//stopping power
			case 1:
				SurvivorUpgrade1[param1]=1;
			//double tap
			case 2:
				SurvivorUpgrade1[param1]=4;
			//sleight of hand
			case 3:
				SurvivorUpgrade1[param1]=6;
			//pyrotechnician
			case 4:
				SurvivorUpgrade1[param1]=2;
			//spirit
			case 5:
				SurvivorUpgrade1[param1]=3;
			//unbreakable
			case 6:
				SurvivorUpgrade1[param1]=5;
		}
	}

	if (IsClientInGame(param1)==true)
		SendPanelToClient(Menu_Top(param1),param1,Menu_ChooseSubMenu,MENU_TIME_FOREVER);
}



//=============================
//	SUR2 CHOICE
//=============================

//build menu for Sur2 Perks
public Handle:Menu_Sur2Perk (client)
{
	new Handle:menu = CreatePanel();
	SetPanelTitle(menu, "tPoncho's Perkmod - Survivor: Secondary");
	decl String:st_display[64];
	decl String:st_current[10];

	//set name for perk 1
	if (g_iChem_enable==0			&&	g_iL4D_GameMode==0
		|| g_iChem_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iChem_enable_vs==0		&&	g_iL4D_GameMode==2)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (SurvivorUpgrade2[client])
		{
			case 1: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Chem Reliant %s",st_current);
		DrawPanelItem(menu,st_display);
		Format(st_display,64,"You gain +%i bonus health buffer when taking pills", g_iChem_buff);
		DrawPanelText(menu,st_display);
		DrawPanelText(menu,"and you start the round with extra pills");
	}

	//set name for perk 2
	if (g_iHelpHand_enable==0			&&	g_iL4D_GameMode==0
		|| g_iHelpHand_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iHelpHand_enable_vs==0		&&	g_iL4D_GameMode==2)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (SurvivorUpgrade2[client])
		{
			case 2: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Helping Hand %s",st_current);
		DrawPanelItem(menu,st_display);
		decl iBuff;
		if (g_iL4D_GameMode==2)
			iBuff=g_iHelpHand_buff_vs;
		else
			iBuff=g_iHelpHand_buff;
		Format(st_display,64,"give them +%i bonus health buffer", iBuff);
		DrawPanelText(menu,st_display);
	}

	//set name for perk 5
	if (g_iHard_enable==0			&&	g_iL4D_GameMode==0
		|| g_iHard_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iHard_enable_vs==0		&&	g_iL4D_GameMode==2)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (SurvivorUpgrade2[client])
		{
			case 5: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Hard to Kill %s",st_current);
		DrawPanelItem(menu,st_display);
		DrawPanelText(menu,"When you are incapped you have");
		Format(st_display,64,"%i%% more health buffer", RoundToNearest(100*g_flHard_hpmult) );
		DrawPanelText(menu,st_display);
	}

	//set name for perk 3
	if (g_iPack_enable==0			&&	g_iL4D_GameMode==0
		|| g_iPack_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iPack_enable_vs==0		&&	g_iL4D_GameMode==2)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (SurvivorUpgrade2[client])
		{
			case 3: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Pack Rat %s",st_current);
		DrawPanelItem(menu,st_display);
		Format(st_display,64,"You can carry %i%% more ammo", RoundToNearest(g_flPack_ammomult*100) );
		DrawPanelText(menu,st_display);
	}

	//set name for perk 4
	if (g_iMA_enable==0			&&	g_iL4D_GameMode==0
		|| g_iMA_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iMA_enable_vs==0		&&	g_iL4D_GameMode==2)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (SurvivorUpgrade2[client])
		{
			case 4: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Martial Artist %s",st_current);
		DrawPanelItem(menu,st_display);
		if (g_iL4D_GameMode==0)
		{
			Format(st_display,64,"You run %i%% faster", RoundToNearest( (g_flMA_rate_coop - 1) * 100 ) );
			DrawPanelText(menu,st_display);
		}
		else
		{
			DrawPanelText(menu,"You never suffer from melee fatigue");
			Format(st_display,64,"and you run %i%% faster", RoundToNearest( (g_flMA_rate - 1) * 100 ) );
			DrawPanelText(menu,st_display);
		}
	}

	return menu;
}

//setting Sur2 perk and returning to top menu
public Menu_ChooseSur2Perk (Handle:menu, MenuAction:action, param1, param2)
{
	if (menu!=INVALID_HANDLE) CloseHandle(menu);
	if (action==MenuAction_Select)
	{
		switch(param2)
		{
			//chem reliant
			case 1:
				SurvivorUpgrade2[param1]=1;
			//helping hand
			case 2:
				SurvivorUpgrade2[param1]=2;
			//hard to kill
			case 3:
				SurvivorUpgrade2[param1]=5;
			//pack rat
			case 4:
				SurvivorUpgrade2[param1]=3;
			//martial artist
			case 5:
				SurvivorUpgrade2[param1]=4;
		}
	}

	if (IsClientInGame(param1)==true)
		SendPanelToClient(Menu_Top(param1),param1,Menu_ChooseSubMenu,MENU_TIME_FOREVER);
}



//=============================
//	INF1 CHOICE (BOOMER)
//=============================

//build menu for Inf1 Perks
public Handle:Menu_Inf1Perk (client)
{
	new Handle:menu = CreatePanel();
	SetPanelTitle(menu, "tPoncho's Perkmod - Boomer");
	decl String:st_display[64];
	decl String:st_current[10];

	//set name for perk 1
	if (g_iBarf_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (BoomerUpgrade[client])
		{
			case 1: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Barf Bagged %s",st_current);
		DrawPanelItem(menu,st_display);
		DrawPanelText(menu,"Your vomit calls more zombies");
	}

	//set name for perk 2
	if (g_iBlind_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (BoomerUpgrade[client])
		{
			case 2: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Acid Vomit %s",st_current);
		DrawPanelItem(menu,st_display);
		DrawPanelText(menu,"Your vomit totally blocks survivor's HUDs");
		Format(st_display,64,"and also deals %i damage", RoundFloat(GetConVarFloat(BileDamage)));
		DrawPanelText(menu,st_display);
		DrawPanelText(menu,"(thanks to Grandwazir for this perk!)");
	}

	//set name for perk 3
	if (g_iDead_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (BoomerUpgrade[client])
		{
			case 3: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Dead Wreckening %s",st_current);
		DrawPanelItem(menu,st_display);
		Format(st_display,64,"Zombies do %i%% more damage when any", RoundToNearest(g_flDead_dmgmult*100) );
		DrawPanelText(menu,st_display);
		DrawPanelText(menu,"survivors are vomited upon");
	}

	//set name for perk 4
	if (g_iMotion_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (BoomerUpgrade[client])
		{
			case 4: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Motion Sickness %s",st_current);
		DrawPanelItem(menu,st_display);
		DrawPanelText(menu,"You can move while vomiting");
		Format(st_display,64,"and you run +%i%% faster", RoundToNearest( (g_flMotion_rate - 1) * 100 ) );
		DrawPanelText(menu,st_display);
	}

	return menu;
}

//setting Inf1 perk and returning to top menu
public Menu_ChooseInf1Perk (Handle:menu, MenuAction:action, param1, param2)
{
	if (menu!=INVALID_HANDLE) CloseHandle(menu);
	if (action==MenuAction_Select)
	{
		switch(param2)
		{
			//barf bagged
			case 1:
				BoomerUpgrade[param1]=1;
			//acid vomit
			case 2:
				BoomerUpgrade[param1]=2;
			//dead wreckening
			case 3:
				BoomerUpgrade[param1]=3;
			//motion sickness
			case 4:
				BoomerUpgrade[param1]=4;
		}
	}

	if (IsClientInGame(param1)==true)
		SendPanelToClient(Menu_Top(param1),param1,Menu_ChooseSubMenu,MENU_TIME_FOREVER);
}



//=============================
//	INF2 CHOICE (TANK)
//=============================

//build menu for Inf2 Perks
public Handle:Menu_Inf2Perk (client)
{
	new Handle:menu = CreatePanel();
	SetPanelTitle(menu, "tPoncho's Perkmod - Tank");
	decl String:st_display[64];
	decl String:st_current[10];

	//set name for perk 1
	if (g_iAdrenal_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (TankUpgrade[client])
		{
			case 1: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Adrenal Glands %s",st_current);
		DrawPanelItem(menu,st_display);
		Format(st_display,64,"Punch for extra damage");
		DrawPanelText(menu,st_display);
	}

	//set name for perk 2
	if (g_iJuggernaut_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (TankUpgrade[client])
		{
			case 2: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Juggernaut %s",st_current);
		DrawPanelItem(menu,st_display);
		Format(st_display,64,"You have +%i more health", g_iJuggernaut_hp);
		DrawPanelText(menu,st_display);
	}

	//set name for perk 3
	if (g_iMetabolic_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (TankUpgrade[client])
		{
			case 3: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Metabolic Boost %s",st_current);
		DrawPanelItem(menu,st_display);
		Format(st_display,64,"You move +%i%% faster", RoundToNearest((g_flMetabolic_speedmult-1)*100) );
		DrawPanelText(menu,st_display);
	}

	//set name for perk 4
	if (g_iStorm_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (TankUpgrade[client])
		{
			case 4: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Storm Caller %s",st_current);
		DrawPanelItem(menu,st_display);
		DrawPanelText(menu,"A zombie wave will spawn with you");
	}

	//set name for perk 5

	DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);

	return menu;
}

//setting Inf2 perk and returning to top menu
public Menu_ChooseInf2Perk (Handle:menu, MenuAction:action, param1, param2)
{
	if (menu!=INVALID_HANDLE) CloseHandle(menu);
	if (action==MenuAction_Select)
	{
		switch(param2)
		{
			//adrenal glands
			case 1:
				TankUpgrade[param1]=1;
			//juggernaut
			case 2:
				TankUpgrade[param1]=2;
			//metabolic boost
			case 3:
				TankUpgrade[param1]=3;
			//storm caller
			case 4:
				TankUpgrade[param1]=4;
		}
	}

	if (IsClientInGame(param1)==true)
		SendPanelToClient(Menu_Top(param1),param1,Menu_ChooseSubMenu,MENU_TIME_FOREVER);
}



//=============================
//	INF3 CHOICE (SMOKER)
//=============================

//build menu for Inf3 Perks
public Handle:Menu_Inf3Perk (client)
{
	new Handle:menu = CreatePanel();
	SetPanelTitle(menu, "tPoncho's Perkmod - Smoker");
	decl String:st_display[64];
	decl String:st_current[10];

	//set name for perk 1
	if (g_iRegenerator_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (SmokerUpgrade[client])
		{
			case 1: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Regenerator %s",st_current);
		DrawPanelItem(menu,st_display);
		decl iDmg;
		iDmg=g_iRegenerator_heal;
		
		Format(st_display,64,"You regenerate %i health every 2 seconds", iDmg);
		DrawPanelText(menu,st_display);
	}

	//set name for perk 2
	if (g_iSqueezer_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (SmokerUpgrade[client])
		{
			case 2: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Squeezer %s",st_current);
		DrawPanelItem(menu,st_display);
		decl iDmg;
		if (g_iL4D_Difficulty==2)
			iDmg=g_iSqueezer_dmg_expert;
		else if (g_iL4D_Difficulty==1)
			iDmg=g_iSqueezer_dmg_hard;
		else
			iDmg=g_iSqueezer_dmg;
		Format(st_display,64,"Your tongue deals +%i damage while choking", iDmg);
		DrawPanelText(menu,st_display);
	}

	
	//set name for perk 3
	if (g_iSlingshot_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (SmokerUpgrade[client])
		{
			case 3: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Slingshot Sticktongue %s",st_current);
		DrawPanelItem(menu,st_display);
		decl iForce;
		iForce = g_iSlingshot_force;
		
		Format(st_display,64,"On successfull pull Survivors get jerked to you with %i force", iForce);
		DrawPanelText(menu,st_display);
	}

	return menu;
}

//setting Inf3 perk and returning to top menu
public Menu_ChooseInf3Perk (Handle:menu, MenuAction:action, param1, param2)
{
	if (menu!=INVALID_HANDLE) CloseHandle(menu);
	if (action==MenuAction_Select)
	{
		switch(param2)
		{
			//Regenerator
			case 1:
				SmokerUpgrade[param1]=1;
			//squeezer
			case 2:
				SmokerUpgrade[param1]=2;
			//slingshot stickytongue
			case 3:
				SmokerUpgrade[param1]=3;
		}
	}

	if (IsClientInGame(param1)==true)
		SendPanelToClient(Menu_Top(param1),param1,Menu_ChooseSubMenu,MENU_TIME_FOREVER);
}



//=============================
//	INF4 CHOICE (HUNTER)
//=============================

//build menu for Inf4 Perks
public Handle:Menu_Inf4Perk (client)
{
	new Handle:menu = CreatePanel();
	SetPanelTitle(menu, "tPoncho's Perkmod - Hunter");
	decl String:st_display[64];
	decl String:st_current[10];

	//set name for perk 1
	if (g_iBody_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (HunterUpgrade[client])
		{
			case 1: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Body Slam %s",st_current);
		DrawPanelItem(menu,st_display);
		Format(st_display,64,"Your pounces always deal at least %i damage",g_iBody_minbound);
		DrawPanelText(menu,st_display);
	}

	//set name for perk 2
	if (g_iEfficient_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (HunterUpgrade[client])
		{
			case 2: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Efficient Killer %s",st_current);
		DrawPanelItem(menu,st_display);
		decl iDmg;
		if (g_iL4D_Difficulty==2)
			iDmg=g_iEfficient_dmg_expert;
		else if (g_iL4D_Difficulty==1)
			iDmg=g_iEfficient_dmg_hard;
		else
			iDmg=g_iEfficient_dmg;
		Format(st_display,64,"You deal +%i damage per shred",iDmg);
		DrawPanelText(menu,st_display);
		DrawPanelText(menu,"on pounced survivors");
	}

	//set name for perk 3
	if (g_iGrass_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (HunterUpgrade[client])
		{
			case 3: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Grasshopper %s",st_current);
		DrawPanelItem(menu,st_display);
		Format(st_display,64,"You pounce %i%% faster and farther", RoundToNearest( (g_flGrass_rate - 1) * 100 ) );
		DrawPanelText(menu,st_display);
	}

	//set name for perk 4
	if (g_iOld_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (HunterUpgrade[client])
		{
			case 4: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Old School %s",st_current);
		DrawPanelItem(menu,st_display);
		decl iDmg;
		if (g_iL4D_Difficulty==2)
			iDmg=g_iOld_dmg_expert;
		else if (g_iL4D_Difficulty==1)
			iDmg=g_iOld_dmg_hard;
		else
			iDmg=g_iOld_dmg;
		Format(st_display,64,"Secondary claw swipes deals +%i damage", iDmg);
		DrawPanelText(menu,st_display);
	}

	return menu;
}

//setting Inf4 perk and returning to top menu
public Menu_ChooseInf4Perk (Handle:menu, MenuAction:action, param1, param2)
{
	if (menu!=INVALID_HANDLE) CloseHandle(menu);
	if (action==MenuAction_Select)
	{
		switch(param2)
		{
			//body slam
			case 1:
				HunterUpgrade[param1]=1;
			//efficient killer
			case 2:
				HunterUpgrade[param1]=2;
			//grasshopper
			case 3:
				HunterUpgrade[param1]=3;
			//old school
			case 4:
				HunterUpgrade[param1]=4;
		}
	}

	if (IsClientInGame(param1)==true)
		SendPanelToClient(Menu_Top(param1),param1,Menu_ChooseSubMenu,MENU_TIME_FOREVER);
}