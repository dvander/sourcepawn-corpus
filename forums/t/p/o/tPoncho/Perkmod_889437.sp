/*========================================================================
==========================================================================

						P	E	R	K	M	O	D
						-------------------------
							by tPoncho, aka tP

- version 1.0:
		Initial release
- version 1.0.1:
		Changed code for Blind Luck with Doku's
- version 1.0.2:
		Attempted fix for outrageous health values for survivors.
		Fix for Double Tap not working on team switches.
- version 1.1:
		Replaced Speed Demon with Grasshopper.
		Included CVars to disable perks.
		Fix for various tank perks either not applying or applying too
			many times (double the trouble health multiplier).
		Added more info to perk CVars for min and max values allowed.
		Added in a CVar to disable plugin adjustments to survivor crawling.
		Changing teams to survivors should grant perks.
- version 1.1.1:
		Fixed Martial Artist not resetting fatigue.
		Removed	debug messages (oops!)
- version 1.2:
		New perk for Boomers - Motion Sickness, boosts movement speed and
			lets you run while vomiting.
		Reinstated Speed Demon (for hunters).
		Nerfed Metabolic Boost default value from 1.5 to 1.4.
		Nerfed Tongue Twister default values slightly (pull speed 1.75->1.5,
			shoot speed	1.75->1.5, range 1.75 unchanged).
		Unbreakable now gives bonus buffer on being revived.
		Hopefully fixed problem with unbreakable not applying sometimes.
		Hopefully fixed problem with second tank not spawning with Double
			Trouble.
		Minor fixes for (mostly) harmless server errors
- version 1.3:
		Double Trouble tanks can no longer be frustrated as long as	both
			are alive (band-aid solution to the disappearing-tank-when-both-
			tanks-are-alive-and-one-gets-frustrated problem).
		Pack Rat now gives ammo based on max ammo values set by the server
			instead of absolute values.
		Nerfed Dead Wreckening default value
			(damage multiplier 1.0 -> 0.5).
		Added in an option for players to pick random perks.
		Added in a CVar to force random perks on players every roundstart.
		Revised the show-menu code slightly to always show the initial
			"customize/playNOW!" menu on roundstarts.
		Revised some code so that disabling a perk that changes ConVars
			will make the plugin stop modifying those ConVars.
		Added in ConVars to selectively disable ConVar modifying for the
			perks Helping Hand and Blind Luck.
		Renamed	ConVar "l4d_perkmod_spirit_crawling" to
			"l4d_perkmod_spirit_enable_convarchanges" to keep the naming
			system consistent with the other new ConVar-change-permission
			ConVars.
- version 1.4:
		Revised Spirit so that self-reviving doesn't reset black-and-
			white health (thanks to AtomicStryker!). Self-reviving through
			Spirit won't increase the revive count towards black-and-white
			health,	however.
		Reduced default Spirit cooldown values
			(versus and survival 210s -> 150s, campaign 540s -> 240s).
		Bots now receive random perks. The pool of perks that bots can choose
			from can be adjusted with "l4d_perkmod_bot_<type> <range>".
			General format is "1,2,3,4,5", "3,2,5", etc.
		Added CVars to disable entire perk trees, which will stop all perks
			under that tree from working, and also hide	the perk tree from
			player menus.
		Revised perk code so that non-CVar-adjusting perks will also cease
			functioning if disabled in general.
		Fixed some code that was causing CVar-adjusting perks to adjust CVars
			even when disabled in game modes other than campaign.
		Added CVar to disable the player's option to randomize their perks
			("l4d_perkmod_randomperks_enable")
		Added missing code to when a player selects "Play NOW!" on the
			initial perk menu, which wasn't applying some perk benefits
			(thanks again, AtomicStryker!)
		Added an OnPluginEnd function.
- version 1.4.1:
		Fixed problems with never-ending music.
		Merged Speed Demon with Old School. Reduced Speed Demon to 1.4x and
			Old School to 3/6/12. CVar names are unchanged.
		Seemed to be some problems with damage adds. Fixed.
- version 1.4.2:
		Fixed PKT errors showing up on clients' console.

==========================================================================
========================================================================*/



//=============================
// Start
//=============================

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.4.2"

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
new g_iSur1[64];	//survivors, primary
new g_iSur2[64];	//survivors, secondary
new g_iInf1[64];	//boomer
new g_iInf2[64];	//tank
new g_iConfirm[64];	//check if perks are confirmed, to prevent mid-game changing abuses
new g_iInf3[64];	//smoker
new g_iInf4[64];	//hunter

//PYROTECHNICIAN PERK
//track how many grenades are carried for pyrotechnician perk
new g_iGren[64];
//used so functions don't confuse legitimate grenade pickups
//with acquisitions from grenadier perk
new g_iGrenThrow[64];
//used to track which type of grenade was used;
//1 = pipe, 2 = molotov
new g_iGrenType[64];

//SPIRIT PERK
//used to track whether a player is pounced or tongued
//0 = not currently disabled
//1 = disabled by hunter/smoker
new g_iPState[64];
//0 = not incapped
//1 = incapped
new g_iPIncap[64];
//used to keep track of whether cooldown is in effect
new g_iSpiritCooldown[64];
//used to track the timers themselves
new Handle:g_iSpiritTimer[64];

//DOUBLE TAP PERK
//used to track who has the double tap perk
//index goes up to 18, but each index has
//a value indicating a client index with DT
//so the plugin doesn't have to cycle a full
//18 times per game frame
new g_iDTRegisterIndex[64] = -1;
//and this tracks how many have DT
new g_iDTRegisterCount = 0;
//this tracks the current active weapon id
//in case the player changes guns
new g_iDTEntid[64] = -1;
//this tracks the engine time of the next
//attack for the weapon, after modification
//(modified interval + engine time)
new Float:g_flDTNextTime[64] = -1.0;

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
new g_iMARegisterIndex[64] = -1;
//and this tracks how many have MA
new g_iMARegisterCount = 0;

//PACK RAT PERK
//this keeps values of max ammo capacity that
//are calculated on round starts, since this
//perk seems inconsistent in calculating values
//on the fly... =/
new g_iPR_smg;
new g_iPR_shotgun;
new g_iPR_rifle;
new g_iPR_sniper;

//BARF BAGGED PERK
//used to track how many survivors are boomed at a given time
//because spawning a whole mob per player is WAY too many
//also used indirectly to check if someone is currently vomited on
new g_iSlimed=0;

//DEAD WRECKENING PERK
//used to track who vomited on a survivor last
new g_iSlimerLast=0;

//VARIOUS HUNTER/SMOKER PERKS
//used to track when a hunter is shredding
//or when a smoker is choking
//0 = not choking/pouncing
//1 = hunter is pouncing, smoker is dragging/choking
new g_iDisabling[64];

//TANKS
//tracks whether tanks are existent, and what perks have been given
//0 = no tank;
//1 = tank, but no special perks assigned yet;
//2 = tank, juggernaut has been given;
//3 = tank, double trouble has been given;
//4 = frustrated tank with double trouble is being passed to another player;
new g_iTank=0;
new g_iTankCount=0;		//tracks how many tanks there under double trouble modification
new g_iTankBotTicks=0;	//after 3 ticks, if tank is still a bot then give buffs
new g_iTank_MainId=0;	//tracks which tank is the "original", for Double Trouble

//VARS TO STORE CONVAR VALUES
//declare revive time var
new Float:g_flReviveTime= -1.0;
//declare vomit interval var
new Float:g_flVomitInt= -1.0;
//declare vomit fatigue var
new Float:g_flVomitFatigue= -1.0;
//declare yoink tongue speed var
new Float:g_flTongueSpeed= -1.0;
new Float:g_flTongueHitDelay= -1.0;
new Float:g_flTongueFlySpeed= -1.0;
new Float:g_flTongueRange= -1.0;
//declare drag and drop vars
new Float:g_flTongueDropTime= -1.0;
//declare tank speed var
new Float:g_flTankSpeed= -1.0;
//declare tank attack interval vars
new Float:g_flSwingInterval1= -1.0;
new Float:g_flSwingInterval2= -1.0;
new Float:g_flSwingInterval3= -1.0;
new Float:g_flRockInterval= -1.0;
//decluar tank rock speed var
new Float:g_flRockSpeed= -1.0;

//OFFSETS
new g_iHPBuffO			= -1;
new g_iRevCountO		= -1;
new g_iMeleeFatigueO	= -1;
new g_iNextPAttO		= -1;
new g_iNextSAttO		= -1;
new g_iActiveWO			= -1;
new g_iShotStartDurO	= -1;
new g_iShotInsertDurO	= -1;
new g_iShotEndDurO		= -1;
new g_iPlayRateO		= -1;
new g_iShotRelStateO	= -1;
new g_iNextAttO			= -1;
new g_iTimeIdleO		= -1;
new g_iLaggedMovementO	= -1;
new g_iFrustrationO		= -1;



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
new Handle:g_hSpirit_crawling;
new Handle:g_hSpirit_buff;
new Handle:g_hSpirit_cd;
new Handle:g_hSpirit_cd_sur;
new Handle:g_hSpirit_cd_vs;
//associated vars
new g_iSpirit_enable;
new g_iSpirit_enable_sur;
new g_iSpirit_enable_vs;
new g_iSpirit_crawling;
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
new Handle:g_hHelpHand_convar;
new Handle:g_hHelpHand_timemult;
new Handle:g_hHelpHand_buff;
new Handle:g_hHelpHand_buff_vs;
//associated vars
new g_iHelpHand_enable;
new g_iHelpHand_enable_sur;
new g_iHelpHand_enable_vs;
new g_iHelpHand_convar;
new Float:g_flHelpHand_timemult;
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
//blind luck, cooldown multiplier
//one-size-fits-all
new Handle:g_hBlind_enable;
new Handle:g_hBlind_cdmult;
new Handle:g_hBlind_convar;
//associated var
new g_iBlind_enable;
new g_iBlind_convar;
new Float:g_flBlind_cdmult;

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
//tongue twister, multipliers for tongue speed, pull speed, range
//one-size-fits-all
new Handle:g_hTongue_enable;
new Handle:g_hTongue_speedmult;
new Handle:g_hTongue_pullmult;
new Handle:g_hTongue_rangemult;
//associated vars
new g_iTongue_enable;
new Float:g_flTongue_speedmult;
new Float:g_flTongue_pullmult;
new Float:g_flTongue_rangemult;

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

//drag and drop, cooldown mult;
//one-size-fits-all
new Handle:g_hDrag_enable;
new Handle:g_hDrag_cdmult;
//associated var
new g_iDrag_enable;
new Float:g_flDrag_cdmult;


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

//speed demon, speed multiplier
//one-size-fits-all
new Handle:g_hSpeedDemon_enable;
new Handle:g_hSpeedDemon_rate;
//associated var
new g_iSpeedDemon_enable;
new Float:g_flSpeedDemon_rate;


//INF2 (TANK) PERKS
//adrenal glands, multipliers for punch cooldown,
//throw rock cooldown, and rock travel speed
//one-size-fits-all
new Handle:g_hAdrenal_enable;
new Handle:g_hAdrenal_punchcdmult;
new Handle:g_hAdrenal_throwcdmult;
new Handle:g_hAdrenal_rockspeedmult;
//associated vars
new g_iAdrenal_enable;
new Float:g_flAdrenal_punchcdmult;
new Float:g_flAdrenal_throwcdmult;
new Float:g_flAdrenal_rockspeedmult;

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

//double the trouble, health multiplier
//one-size-fits-all
new Handle:g_hDouble_enable;
new Handle:g_hDouble_hpmult;
//associated var
new g_iDouble_enable;
new Float:g_flDouble_hpmult;

//BOT CONTROLLER VARS
//these track the server's preference
//for what perks bots should use

//survivor
new Handle:g_hBot_Sur1;
new Handle:g_hBot_Sur2;
//boomer
new Handle:g_hBot_Inf1;
//smoker
new Handle:g_hBot_Inf3;
//hunter
new Handle:g_hBot_Inf4;
//tank
new Handle:g_hBot_Inf2;

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

//FORCE RANDOM PERKS
//tracks server setting for
//whether to force random perks

new Handle:g_hForceRandom;
new g_iForceRandom;

//ENABLE RANDOM PERKS BY PLAYER CHOICE
//tracks whether player can
//randomize their perks

new Handle:g_hRandomEnable;
new g_iRandomEnable;

//PERK TREES AVAILABILITY
//option for servers to completely
//disable entire perk trees

new Handle:g_hSur1_enable;
new Handle:g_hSur2_enable;
new Handle:g_hInf1_enable;
new Handle:g_hInf2_enable;
new Handle:g_hInf3_enable;
new Handle:g_hInf4_enable;
new g_iSur1_enable;
new g_iSur2_enable;
new g_iInf1_enable;
new g_iInf2_enable;
new g_iInf3_enable;
new g_iInf4_enable;

//this var keeps track of whether
//to enable DT and Stopping or not, so we don't
//have to do the checks every game frame, or
//every time someone gets hurt

new g_iDT_meta_enable;
new g_iStopping_meta_enable;



//=============================
// Hooking, Initialize Vars
//=============================

public OnPluginStart()
{
	//Plugin version for online tracking
	CreateConVar("l4d_perkmod_version", PLUGIN_VERSION, "Version of Perkmod for L4D", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
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
	HookEvent("revive_begin", Event_ReviveBeginPre, EventHookMode_Pre);	//helping hand
	HookEvent("revive_success", Event_ReviveSuccess);				//helping hand
	HookEvent("ammo_pickup", Event_AmmoPickup);						//pack rat
	HookEvent("player_use", Event_PlayerUse);						//pack rat
	HookEvent("player_incapacitated", Event_Incap);					//hard to kill
	//hooks for Inf1 perks (boomer)
	HookEvent("player_now_it", Event_PlayerNowIt);					//blind luck, barf bagged
	//hooks for Inf3 perks (smoker)
	HookEvent("ability_use", Event_AbilityUsePre, EventHookMode_Pre);	//twister, blind luck
	HookEvent("tongue_grab", Event_TongueGrabPre, EventHookMode_Pre);	//twister, spirit
	HookEvent("tongue_release", Event_TongueRelease);				//twister, spirit, +Inf
	HookEvent("tongue_grab", Event_TongueGrab);						//drag and drop
	HookEvent("player_spawn", Event_PlayerSpawn);					//MANY OTHER PERKS, twister
	//hooks for In4 perks (hunter)
	HookEvent("ability_use", Event_AbilityUse);						//grasshopper
	//hooks for Inf2 perks (tank)
	HookEvent("tank_spawn", Event_Tank_Spawn);						//all tank perks!
	HookEvent("tank_frustrated", Event_Tank_Frustrated, EventHookMode_Pre);	//most tank perks (reset)
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);	//some tank perks (reset)
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

	//init vars
	g_flVomitInt		=	GetConVarFloat(FindConVar("z_vomit_interval"));
	g_flVomitFatigue	=	GetConVarFloat(FindConVar("z_vomit_fatigue"));
	g_flTongueSpeed		=	GetConVarFloat(FindConVar("tongue_victim_max_speed"));
	g_flTongueHitDelay	=	GetConVarFloat(FindConVar("tongue_hit_delay"));
	g_flTongueFlySpeed	=	GetConVarFloat(FindConVar("tongue_fly_speed"));
	g_flTongueRange		=	GetConVarFloat(FindConVar("tongue_range"));
	g_flTongueDropTime	=	GetConVarFloat(FindConVar("tongue_player_dropping_to_ground_time"));
	g_flTankSpeed		=	GetConVarFloat(FindConVar("z_tank_speed_vs"));
	g_flSwingInterval1	=	GetConVarFloat(FindConVar("tank_swing_interval"));
	g_flSwingInterval2	=	GetConVarFloat(FindConVar("tank_swing_miss_interval"));
	g_flSwingInterval3	=	GetConVarFloat(FindConVar("z_tank_attack_interval"));
	g_flRockInterval	=	GetConVarFloat(FindConVar("z_tank_throw_interval"));
	g_flRockSpeed		=	GetConVarFloat(FindConVar("z_tank_throw_force"));
	g_flReviveTime		=	GetConVarFloat(FindConVar("survivor_revive_duration"));

	//get offsets
	g_iHPBuffO			=	FindSendPropOffs("CTerrorPlayer","m_healthBuffer");
	g_iRevCountO		=	FindSendPropOffs("CTerrorPlayer","m_currentReviveCount");
	g_iMeleeFatigueO	=	FindSendPropInfo("CTerrorPlayer","m_iShovePenalty");
	g_iNextPAttO		=	FindSendPropInfo("CBaseCombatWeapon","m_flNextPrimaryAttack");
	g_iNextSAttO		=	FindSendPropInfo("CBaseCombatWeapon","m_flNextSecondaryAttack");
	g_iActiveWO			=	FindSendPropInfo("CBaseCombatCharacter","m_hActiveWeapon");
	g_iShotStartDurO	=	FindSendPropInfo("CBaseShotgun","m_reloadStartDuration");
	g_iShotInsertDurO	=	FindSendPropInfo("CBaseShotgun","m_reloadInsertDuration");
	g_iShotEndDurO		=	FindSendPropInfo("CBaseShotgun","m_reloadEndDuration");
	g_iPlayRateO		=	FindSendPropInfo("CBaseCombatWeapon","m_flPlaybackRate");
	g_iShotRelStateO	=	FindSendPropInfo("CBaseShotgun","m_reloadState");
	g_iNextAttO			=	FindSendPropInfo("CTerrorPlayer","m_flNextAttack");
	g_iTimeIdleO		=	FindSendPropInfo("CTerrorGun","m_flTimeWeaponIdle");
	g_iLaggedMovementO	=	FindSendPropInfo("CTerrorPlayer","m_flLaggedMovementValue");
	g_iFrustrationO		=	FindSendPropInfo("Tank","m_frustration");

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
		"Stopping Power perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
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
		"Pyrotechnician perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
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
	g_iSpirit_cd=				240;

	g_hSpirit_cd_sur = CreateConVar(
		"l4d_perkmod_spirit_cooldown_sur" ,
		"210" ,
		"Spirit perk: Cooldown for self-reviving in seconds, survival (clamped between 1 < 1800)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSpirit_cd_sur, Convar_SpiritCDsur);
	g_iSpirit_cd_sur=			150;

	g_hSpirit_cd_vs = CreateConVar(
		"l4d_perkmod_spirit_cooldown_vs" ,
		"210" ,
		"Spirit perk: Cooldown for self-reviving in seconds, versus (clamped between 1 < 1800)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSpirit_cd_vs, Convar_SpiritCDvs);
	g_iSpirit_cd_vs=			150;

	g_hSpirit_enable = CreateConVar(
		"l4d_perkmod_spirit_enable" ,
		"1" ,
		"Spirit perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
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

	g_hSpirit_crawling = CreateConVar(
		"l4d_perkmod_spirit_enable_convarchanges" ,
		"1" ,
		"Spirit perk: Sets whether the crawling CVar will be touched at all by the Perkmod plugin, 0 = CVar will never be adjusted, 1 = CVar will be adjusted as per the perk" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSpirit_crawling, Convar_Spirit_crawling);
	g_iSpirit_crawling = 1;

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
		"Double Tap perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
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
		"Sleight of Hand perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
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
		"Unbreakable perk: Bonus health given for Unbreakable; this value is also given as bonus health buffer on being revived (clamped between 1 < 100)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hUnbreak_hp, Convar_Unbreak);
	g_iUnbreak_hp = 30;

	g_hUnbreak_enable = CreateConVar(
		"l4d_perkmod_unbreakable_enable" ,
		"1" ,
		"Unbreakable perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
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
		"Chem Reliant perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
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

	//helping hand
	g_hHelpHand_timemult = CreateConVar(
		"l4d_perkmod_helpinghand_timemultiplier" ,
		"0.6" ,
		"Helping Hand perk: Time multiplier to revive others with Helping Hand (clamped between 0.01 < 1.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hHelpHand_timemult, Convar_HelpTime);
	g_flHelpHand_timemult = 0.6;

	g_hHelpHand_buff = CreateConVar(
		"l4d_perkmod_helpinghand_bonusbuffer" ,
		"25" ,
		"Helping Hand perk: Bonus health buffer given to allies after reviving them, campaign/survival (clamped between 0 < 170)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hHelpHand_buff, Convar_HelpBuff);
	g_iHelpHand_buff = 25;

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
		"Helping Hand perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled (NOTE: This perk normally adjusts the survivor_revive_duration ConVar; disabling this perk will stop the plugin from adjusting this ConVar)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hHelpHand_enable, Convar_Help_en);
	g_iHelpHand_enable = 1;

	g_hHelpHand_enable_sur = CreateConVar(
		"l4d_perkmod_helpinghand_enable_survival" ,
		"1" ,
		"Helping Hand perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled (NOTE: This perk normally adjusts the survivor_revive_duration ConVar; disabling this perk will stop the plugin from adjusting this ConVar)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hHelpHand_enable_sur, Convar_Help_en_sur);
	g_iHelpHand_enable_sur = 1;

	g_hHelpHand_enable_vs = CreateConVar(
		"l4d_perkmod_helpinghand_enable_versus" ,
		"1" ,
		"Helping Hand perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled (NOTE: This perk normally adjusts the survivor_revive_duration ConVar; disabling this perk will stop the plugin from adjusting this ConVar)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hHelpHand_enable_vs, Convar_Help_en_vs);
	g_iHelpHand_enable_vs = 1;

	g_hHelpHand_convar = CreateConVar(
		"l4d_perkmod_helpinghand_enable_convarchanges" ,
		"1" ,
		"Helping Hand perk: This perk normally adjusts the survivor_revive_duration ConVar; setting this to 0 will stop the plugin from adjusting this ConVar" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hHelpHand_convar, Convar_Help_convar);
	g_iHelpHand_convar = 1;

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
		"Pack Rat perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
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
		"Hard to Kill perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
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
		"Martial Artist perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
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

	//blind luck
	g_hBlind_cdmult = CreateConVar(
		"l4d_perkmod_blindluck_timemultiplier" ,
		"0.67" ,
		"Blind Luck perk: Cooldown (default 30s) is multiplied by this value (clamped between 0.01 < 1.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hBlind_cdmult, Convar_Blind);
	g_flBlind_cdmult = 0.67;

	g_hBlind_enable = CreateConVar(
		"l4d_perkmod_blindluck_enable" ,
		"1" ,
		"Blind Luck perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled (NOTE: This perk normally adjusts the z_vomit_interval ConVar; disabling this perk will stop the plugin from adjusting this ConVar)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hBlind_enable, Convar_Blind_en);
	g_iBlind_enable = 1;

	g_hBlind_convar = CreateConVar(
		"l4d_perkmod_blindluck_enable_convarchanges" ,
		"1" ,
		"Blind Luck perk: This perk normally adjusts the z_vomit_interval ConVar; setting this to 0 will stop the plugin from adjusting this ConVar)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hBlind_convar, Convar_Blind_convar);
	g_iBlind_convar = 1;

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
		"Motion Sickness perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled (NOTE: This perk normally adjusts the z_vomit_fatigue ConVar; disabling this perk will stop the plugin from adjusting this ConVar)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hMotion_enable, Convar_Motion_en);
	g_iMotion_enable = 1;

	//tongue twister
	g_hTongue_speedmult = CreateConVar(
		"l4d_perkmod_tonguetwister_speedmultiplier" ,
		"1.5" ,
		"Tongue Twister perk: Tongue travel speed before grabbing a survivor; multiplied by this value (clamped between 1.0 < 5.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hTongue_speedmult, Convar_TongueSpeed);
	g_flTongue_speedmult = 1.5;

	g_hTongue_pullmult = CreateConVar(
		"l4d_perkmod_tonguetwister_pullmultiplier" ,
		"1.5" ,
		"Tongue Twister perk: Tongue pull speed after grabbing a survivor; multiplied by this value (clamped between 1.0 < 5.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hTongue_pullmult, Convar_TonguePull);
	g_flTongue_pullmult = 1.5;

	g_hTongue_rangemult = CreateConVar(
		"l4d_perkmod_tonguetwister_rangemultiplier" ,
		"1.75" ,
		"Tongue Twister perk: Tongue range; multiplied by this value (clamped between 1.0 < 5.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hTongue_rangemult, Convar_TongueRange);
	g_flTongue_rangemult = 1.75;

	g_hTongue_enable = CreateConVar(
		"l4d_perkmod_tonguetwister_enable" ,
		"1" ,
		"Tongue Twister perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled (NOTE: This perk normally adjusts the tongue_range, tongue_victim_max_speed and tongue_fly_speed ConVars; disabling this perk will stop the plugin from adjusting these ConVars)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hTongue_enable, Convar_Tongue_en);
	g_iTongue_enable = 1;

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

	//drag and drop
	g_hDrag_cdmult = CreateConVar(
		"l4d_perkmod_draganddrop_timemultiplier" ,
		"0.2" ,
		"Drag and Drop perk: Cooldown is multiplied by this value (clamped between 0.01 < 1.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hDrag_cdmult, Convar_Drag);
	g_flDrag_cdmult = 0.2;

	g_hDrag_enable = CreateConVar(
		"l4d_perkmod_draganddrop_enable" ,
		"1" ,
		"Drag and Drop perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled (NOTE: This perk normally adjusts the tongue_hit_delay and tongue_player_dropping_to_ground_time ConVars; disabling this perk will stop the plugin from adjusting these ConVars)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hDrag_enable, Convar_Drag_en);
	g_iDrag_enable = 1;

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
		"3" ,
		"Old School perk: Bonus claw damage; campaign (easy/normal), survival, versus (clamped between 1 < 100)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hOld_dmg, Convar_Old);
	g_iOld_dmg = 3;

	g_hOld_dmg_hard = CreateConVar(
		"l4d_perkmod_oldschool_damage_hard" ,
		"8" ,
		"Old School perk: Bonus claw damage; campaign (advanced) (clamped between 1 < 100)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hOld_dmg_hard, Convar_Oldhard);
	g_iOld_dmg_hard = 6;

	g_hOld_dmg_expert = CreateConVar(
		"l4d_perkmod_oldschool_damage_expert" ,
		"16" ,
		"Old School perk: Bonus claw damage; campaign (expert) (clamped between 1 < 100)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hOld_dmg_expert, Convar_Oldexpert);
	g_iOld_dmg_hard = 12;

	g_hOld_enable = CreateConVar(
		"l4d_perkmod_oldschool_enable" ,
		"1" ,
		"Old School perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hOld_enable, Convar_Old_en);
	g_iOld_enable = 1;

	//speed demon
	g_hSpeedDemon_rate = CreateConVar(
		"l4d_perkmod_speeddemon_rate" ,
		"1.4" ,
		"Speed Demon perk: Multiplier for time rate (clamped between 1.0 < 3.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSpeedDemon_rate, Convar_Demon);
	g_flSpeedDemon_rate = 1.4;

	g_hSpeedDemon_enable = CreateConVar(
		"l4d_perkmod_speeddemon_enable" ,
		"1" ,
		"Speed Demon perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSpeedDemon_enable, Convar_Demon_en);
	g_iSpeedDemon_enable = 1;

	//adrenal glands
	g_hAdrenal_punchcdmult = CreateConVar(
		"l4d_perkmod_adrenalglands_punchcooldownmultiplier" ,
		"0.5" ,
		"Adrenal Glands perk: Cooldown for punching is multiplied by this value (clamped between 0.01 < 1.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hAdrenal_punchcdmult, Convar_Adrenalpunchcd);
	g_flAdrenal_punchcdmult = 0.5;

	g_hAdrenal_throwcdmult = CreateConVar(
		"l4d_perkmod_adrenalglands_throwcooldownmultiplier" ,
		"0.4" ,
		"Adrenal Glands perk: Cooldown for throwing rocks is multiplied by this value (clamped between 0.01 < 1.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hAdrenal_throwcdmult, Convar_Adrenalthrowcd);
	g_flAdrenal_throwcdmult = 0.4;

	g_hAdrenal_rockspeedmult = CreateConVar(
		"l4d_perkmod_adrenalglands_rockspeedmultiplier" ,
		"1.5" ,
		"Adrenal Glands perk: Multiplier for the travel speed of thrown rocks (clamped between 1.0 < 4.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hAdrenal_rockspeedmult, Convar_Adrenalrockspeed);
	g_flAdrenal_rockspeedmult = 1.5;

	g_hAdrenal_enable = CreateConVar(
		"l4d_perkmod_adrenalglands_enable" ,
		"1" ,
		"Adrenal Glands perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled (NOTE: This perk normally adjusts the tank_swing_interval, tank_swing_miss_interval, z_tank_attack_interval, z_tank_throw_interval, and z_tank_throw_force ConVars; disabling this perk will stop the plugin from adjusting these ConVars)" ,
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
		"1.4" ,
		"Metabolic Boost perk: Run speed multiplier (clamped between 1.01 < 3.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hMetabolic_speedmult, Convar_Met);
	g_flMetabolic_speedmult = 1.4;

	g_hMetabolic_enable = CreateConVar(
		"l4d_perkmod_metabolicboost_enable" ,
		"1" ,
		"Metabolic Boost perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled (NOTE: This perk normally adjusts the z_tank_speed_vs ConVar; disabling this perk will stop the plugin from adjusting this ConVar)" ,
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

	//double the trouble
	g_hDouble_hpmult = CreateConVar(
		"l4d_perkmod_doublethetrouble_healthmultiplier" ,
		"0.6" ,
		"Double the Trouble: Health multiplier for all tanks spawned under the perk (clamped between 0.1 < 2.0)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hDouble_hpmult, Convar_Double);
	g_flDouble_hpmult = 0.6;

	g_hDouble_enable = CreateConVar(
		"l4d_perkmod_doublethetrouble_enable" ,
		"1" ,
		"Double the Trouble perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hDouble_enable, Convar_Double_en);
	g_iDouble_enable = 1;

	//bot preferences for perks
	g_hBot_Sur1 = CreateConVar(
		"l4d_perkmod_bot_survivor1" ,
		"1,2,3,4" ,
		"Bot preferences for Survivor 1 perks: 1 = stopping power, 2 = spirit, 3 = unbreakable, 4 = sleight of hand" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );

	g_hBot_Sur2 = CreateConVar(
		"l4d_perkmod_bot_survivor2" ,
		"1,2,3,4" ,
		"Bot preferences for Survivor 2 perks: 1 = chem reliant, 2 = helping hand, 3 = pack rat, 4 = hard to kill" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );

	g_hBot_Inf1 = CreateConVar(
		"l4d_perkmod_bot_boomer" ,
		"1,2,3" ,
		"Bot preferences for boomer perks: 1 = barf bagged, 2 = blind luck, 3 = dead wreckening (NOTE: You can select more than one using the format '1,3,4', and the game will randomize between your choices)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );

	g_hBot_Inf3 = CreateConVar(
		"l4d_perkmod_bot_smoker" ,
		"1,2,3" ,
		"Bot preferences for smoker perks: 1 = tongue twister, 2 = squeezer, 3 = drag and drop (NOTE: You can select more than one using the format '1,3,4', and the game will randomize between your choices)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );

	g_hBot_Inf4 = CreateConVar(
		"l4d_perkmod_bot_hunter" ,
		"1,2,3" ,
		"Bot preferences for hunter perks: 1 = efficient killer, 2 = speed demon, 3 = old school (NOTE: You can select more than one using the format '1,3,4', and the game will randomize between your choices)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );

	g_hBot_Inf2 = CreateConVar(
		"l4d_perkmod_bot_tank" ,
		"1,2,3,4,5" ,
		"Bot preferences for tank perks: 1 = adrenal glands, 2 = juggernaut, 3 = metabolic boost, 4 = storm caller, 5 = double the trouble (NOTE: You can select more than one using the format '1,3,4', and the game will randomize between your choices)" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );

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
		"Default selected perk for Boomer: 1 = barf bagged, 2 = blind luck, 3 = dead wreckening" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hInf1_default, Convar_Def_Inf1);
	g_iInf1_default = 1;

	g_hInf2_default = CreateConVar(
		"l4d_perkmod_default_tank" ,
		"2" ,
		"Default selected perk for Tank: 1 = adrenal glands, 2 = juggernaut, 3 = metabolic boost, 4 = storm caller, 5 = double the trouble" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hInf2_default, Convar_Def_Inf2);
	g_iInf2_default = 2;

	g_hInf3_default = CreateConVar(
		"l4d_perkmod_default_smoker" ,
		"1" ,
		"Default selected perk for Smoker: 1 = tongue twister, 2 = squeezer, 3 = drag and drop" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hInf3_default, Convar_Def_Inf3);
	g_iInf3_default = 1;

	g_hInf4_default = CreateConVar(
		"l4d_perkmod_default_hunter" ,
		"1" ,
		"Default selected perk for Hunter: 1 = body slam, 2 = efficient killer, 3 = grasshopper, 4 = old school, 5 = speed demon" ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hInf4_default, Convar_Def_Inf4);
	g_iInf4_default = 1;

	//force random perks
	g_hForceRandom = CreateConVar(
		"l4d_perkmod_forcerandomperks" ,
		"0" ,
		"If set to 1, players will be assigned random perks at roundstart, and they cannot edit their perks." ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hForceRandom, Convar_ForceRandom);
	g_iForceRandom = 0;

	//enable random perk choice
	g_hRandomEnable = CreateConVar(
		"l4d_perkmod_randomperks_enable" ,
		"1" ,
		"If set to 1, players will be allowed to randomize their perks at roundstart. Otherwise, they can only customize their perks or use default perks." ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hRandomEnable, Convar_Random_en);
	g_iRandomEnable = 1;

	//enable perk trees
	g_hSur1_enable = CreateConVar(
		"l4d_perkmod_perktree_survivor1_enable" ,
		"1" ,
		"If set to 1, players will be allowed to select perks from the Survivor 1 tree." ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSur1_enable, Convar_Sur1_en);
	g_iSur1_enable = 1;

	g_hSur2_enable = CreateConVar(
		"l4d_perkmod_perktree_survivor2_enable" ,
		"1" ,
		"If set to 1, players will be allowed to select perks from the Survivor 2 tree." ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hSur2_enable, Convar_Sur2_en);
	g_iSur2_enable = 1;

	g_hInf1_enable = CreateConVar(
		"l4d_perkmod_perktree_boomer_enable" ,
		"1" ,
		"If set to 1, players will be allowed to select perks from the Boomer tree." ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hInf1_enable, Convar_Inf1_en);
	g_iInf1_enable = 1;

	g_hInf2_enable = CreateConVar(
		"l4d_perkmod_perktree_tank_enable" ,
		"1" ,
		"If set to 1, players will be allowed to select perks from the Tank tree." ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hInf2_enable, Convar_Inf2_en);
	g_iInf2_enable = 1;

	g_hInf3_enable = CreateConVar(
		"l4d_perkmod_perktree_smoker_enable" ,
		"1" ,
		"If set to 1, players will be allowed to select perks from the Smoker tree." ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hInf3_enable, Convar_Inf3_en);
	g_iInf3_enable = 1;

	g_hInf4_enable = CreateConVar(
		"l4d_perkmod_perktree_hunter_enable" ,
		"1" ,
		"If set to 1, players will be allowed to select perks from the Hunter tree." ,
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	HookConVarChange(g_hInf4_enable, Convar_Inf4_en);
	g_iInf4_enable = 1;
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
//the enable/disable functions also call
//the checks-pre-calculate function
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
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iStopping_enable = iI;

	Stopping_RunChecks();
}

public Convar_Stopping_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iStopping_enable_sur = iI;

	Stopping_RunChecks();
}

public Convar_Stopping_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iStopping_enable_vs = iI;

	Stopping_RunChecks();
}

//spirit
public Convar_SpiritBuff (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<0)
		iI=0;
	else if (iI>170)
		iI=170;
	g_iSpirit_buff = iI;
}

public Convar_SpiritCD (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<1)
		iI=1;
	else if (iI>1800)
		iI=1800;
	g_iSpirit_cd = iI;
}

public Convar_SpiritCDsur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<1)
		iI=1;
	else if (iI>1800)
		iI=1800;
	g_iSpirit_cd_sur = iI;
}

public Convar_SpiritCDvs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<1)
		iI=1;
	else if (iI>1800)
		iI=1800;
	g_iSpirit_cd_vs = iI;
}

public Convar_Spirit_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iSpirit_enable = iI;
}

public Convar_Spirit_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iSpirit_enable_sur = iI;
}

public Convar_Spirit_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iSpirit_enable_vs = iI;
}

public Convar_Spirit_crawling (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iSpirit_crawling = iI;
}

//helping hand
public Convar_HelpTime (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.01)
		flF=0.01;
	else if (flF>1.0)
		flF=1.0;
	g_flHelpHand_timemult = flF;
}

public Convar_HelpBuff (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<1)
		iI=1;
	else if (iI>170)
		iI=170;
	g_iHelpHand_buff = iI;
}

public Convar_HelpBuffvs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<1)
		iI=1;
	else if (iI>170)
		iI=170;
	g_iHelpHand_buff_vs = iI;
}

public Convar_Help_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iHelpHand_enable = iI;
}

public Convar_Help_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iHelpHand_enable_sur = iI;
}

public Convar_Help_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iHelpHand_enable_vs = iI;
}

public Convar_Help_convar (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iHelpHand_convar = iI;
}

//unbreakable
public Convar_Unbreak (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<1)
		iI=1;
	else if (iI>100)
		iI=100;
	g_iUnbreak_hp = iI;
}

public Convar_Unbreak_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iUnbreak_enable = iI;
}

public Convar_Unbreak_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iUnbreak_enable_sur = iI;
}

public Convar_Unbreak_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iUnbreak_enable_vs = iI;
}

//double tap
//the enable/disable functions also call
//for the run-on-game-frame-check function
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
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iDT_enable = iI;

	DT_RunChecks();
}

public Convar_DT_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iDT_enable_sur = iI;

	DT_RunChecks();
}

public Convar_DT_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iDT_enable_vs = iI;

	DT_RunChecks();
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
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iSoH_enable = iI;
}

public Convar_SoH_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iSoH_enable_sur = iI;
}

public Convar_SoH_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iSoH_enable_vs = iI;
}

//chem reliant
public Convar_Chem (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<1)
		iI=1;
	else if (iI>150)
		iI=150;
	g_iChem_buff = iI;
}

public Convar_Chem_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iChem_enable = iI;
}

public Convar_Chem_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iChem_enable_sur = iI;
}

public Convar_Chem_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iChem_enable_vs = iI;
}

//pyrotechnician
public Convar_Pyro_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iPyro_enable = iI;
}

public Convar_Pyro_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iPyro_enable_sur = iI;
}

public Convar_Pyro_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iPyro_enable_vs = iI;
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
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iPack_enable = iI;
}

public Convar_Pack_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iPack_enable_sur = iI;
}

public Convar_Pack_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iPack_enable_vs = iI;
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
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iHard_enable = iI;
}

public Convar_Hard_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iHard_enable_sur = iI;
}

public Convar_Hard_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iHard_enable_vs = iI;
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
	MA_Rebuild();
}

public Convar_MA_coop (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<1.0)
		flF=1.0;
	else if (flF>1.5)
		flF=1.5;
	g_flMA_rate = flF;
	MA_Rebuild();
}

public Convar_MA_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iMA_enable = iI;
}

public Convar_MA_en_sur (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iMA_enable_sur = iI;
}

public Convar_MA_en_vs (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iMA_enable_vs = iI;
}

//barf bagged
public Convar_Barf_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iBarf_enable = iI;
}

//blind luck
public Convar_Blind (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.01)
		flF=0.01;
	else if (flF>1.0)
		flF=1.0;
	g_flBlind_cdmult = flF;
}

public Convar_Blind_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iBlind_enable = iI;
}

public Convar_Blind_convar (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iBlind_convar = iI;
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
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iDead_enable = iI;
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

//tongue twister
public Convar_TongueSpeed (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<1.0)
		flF=1.0;
	else if (flF>5.0)
		flF=5.0;
	g_flTongue_speedmult = flF;
}

public Convar_TonguePull (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<1.0)
		flF=1.0;
	else if (flF>5.0)
		flF=5.0;
	g_flTongue_pullmult = flF;
}

public Convar_TongueRange (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<1.0)
		flF=1.0;
	else if (flF>5.0)
		flF=5.0;
	g_flTongue_rangemult = flF;
}

public Convar_Tongue_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iTongue_enable = iI;
}

//squeezer
public Convar_Squeezer (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<1)
		iI=1;
	else if (iI>100)
		iI=100;
	g_iSqueezer_dmg = iI;
}

public Convar_SqueezerHard (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<1)
		iI=1;
	else if (iI>100)
		iI=100;
	g_iSqueezer_dmg_hard = iI;
}

public Convar_SqueezerExpert (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<1)
		iI=1;
	else if (iI>100)
		iI=100;
	g_iSqueezer_dmg_expert = iI;
}

public Convar_Squeezer_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iSqueezer_enable = iI;
}

//drag and drop
public Convar_Drag (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.01)
		flF=0.01;
	else if (flF>1.0)
		flF=1.0;
	g_flDrag_cdmult = flF;
}

public Convar_Drag_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iDrag_enable = iI;
}

//efficient killer
public Convar_Eff (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<1)
		iI=1;
	else if (iI>100)
		iI=100;
	g_iEfficient_dmg = iI;
}

public Convar_Effhard (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<1)
		iI=1;
	else if (iI>100)
		iI=100;
	g_iEfficient_dmg_hard = iI;
}

public Convar_Effexpert (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<1)
		iI=1;
	else if (iI>100)
		iI=100;
	g_iEfficient_dmg_expert = iI;
}

public Convar_Eff_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iEfficient_enable = iI;
}

//body slam
public Convar_Body (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<2)
		iI=2;
	else if (iI>100)
		iI=100;
	g_iBody_minbound = iI;
}

public Convar_Body_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iBody_enable = iI;
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
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iGrass_enable = iI;
}

//old school
public Convar_Old (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<1)
		iI=1;
	else if (iI>100)
		iI=100;
	g_iOld_dmg = iI;
}

public Convar_Oldhard (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<1)
		iI=1;
	else if (iI>100)
		iI=100;
	g_iOld_dmg_hard = iI;
}

public Convar_Oldexpert (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<1)
		iI=1;
	else if (iI>100)
		iI=100;
	g_iOld_dmg_expert = iI;
}

public Convar_Old_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iOld_enable = iI;
}

//speed demon
public Convar_Demon (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<1.0)
		flF=1.0;
	else if (flF>3.0)
		flF=3.0;
	g_flSpeedDemon_rate = flF;
}

public Convar_Demon_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iSpeedDemon_enable = iI;
}

//adrenal glands
public Convar_Adrenalpunchcd (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.01)
		flF=0.01;
	else if (flF>1.0)
		flF=1.0;
	g_flAdrenal_punchcdmult = flF;
}

public Convar_Adrenalthrowcd (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.01)
		flF=0.01;
	else if (flF>1.0)
		flF=1.0;
	g_flAdrenal_throwcdmult = flF;
}

public Convar_Adrenalrockspeed (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<1.0)
		flF=1.0;
	else if (flF>4.0)
		flF=4.0;
	g_flAdrenal_rockspeedmult = flF;
}

public Convar_Adrenal_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iAdrenal_enable = iI;
}

//juggernaut
public Convar_Jugg (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<1)
		iI=1;
	else if (iI>99999)
		iI=99999;
	g_iJuggernaut_hp = iI;
}

public Convar_Jugg_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iJuggernaut_enable = iI;
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
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iMetabolic_enable = iI;
}

//storm caller
public Convar_Storm (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<1)
		iI=1;
	else if (iI>10)
		iI=10;
	g_iStorm_mobcount = iI;
}

public Convar_Storm_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iStorm_enable = iI;
}

//double the trouble
public Convar_Double (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:flF=StringToFloat(newValue);
	if (flF<0.1)
		flF=0.1;
	else if (flF>2.0)
		flF=2.0;
	g_flDouble_hpmult = flF;
}

public Convar_Double_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;
	g_iDouble_enable = iI;
}

//default perks
public Convar_Def_Sur1 (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<=0)
		iI=1;
	else if (iI>6)
		iI=6;

	g_iSur1_default=iI;
}

public Convar_Def_Sur2 (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<=0)
		iI=1;
	else if (iI>5)
		iI=5;

	g_iSur2_default=iI;
}

public Convar_Def_Inf1 (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<=0)
		iI=1;
	else if (iI>3)
		iI=3;

	g_iInf1_default=iI;
}

public Convar_Def_Inf2 (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<=0)
		iI=1;
	else if (iI>5)
		iI=5;

	g_iInf2_default=iI;
}

public Convar_Def_Inf3 (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<=0)
		iI=1;
	else if (iI>3)
		iI=3;

	g_iInf3_default=iI;
}

public Convar_Def_Inf4 (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI<=0)
		iI=1;
	else if (iI>5)
		iI=5;

	g_iInf4_default=iI;
}

//force random perks
public Convar_ForceRandom (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;

	g_iForceRandom=iI;
}

//enable random perk choice
public Convar_Random_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;

	g_iRandomEnable=iI;
}

//perk trees
//Sur1 also runs the pre-calculate
//functions to check if certain perks should run
public Convar_Sur1_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;

	g_iSur1_enable=iI;

	DT_RunChecks();
	Stopping_RunChecks();
}

public Convar_Sur2_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;

	g_iSur2_enable=iI;
}

public Convar_Inf1_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;

	g_iInf1_enable=iI;
}

public Convar_Inf2_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;

	g_iInf2_enable=iI;
}

public Convar_Inf3_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;

	g_iInf3_enable=iI;
}

public Convar_Inf4_en (Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iI=StringToInt(newValue);
	if (iI==0)
		iI=0;
	else
		iI=1;

	g_iInf4_enable=iI;
}



//=============================
// Server, Misc Perk Functions
//=============================

//set default perks for connecting players
public Event_PConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iCid==0) return;

	//if any of the perks are set to 0, set default values
	if (g_iSur1[iCid]==0)
		g_iSur1[iCid] = g_iSur1_default;
	if (g_iSur2[iCid]==0)
		g_iSur2[iCid] = g_iSur2_default;
	if (g_iInf1[iCid]==0)
		g_iInf1[iCid] = g_iInf1_default;
	if (g_iInf2[iCid]==0)
		g_iInf2[iCid] = g_iInf2_default;
	if (g_iInf3[iCid]==0)
		g_iInf3[iCid] = g_iInf3_default;
	if (g_iInf4[iCid]==0)
		g_iInf4[iCid] = g_iInf4_default;
	g_iConfirm[iCid]=0;
	g_iGren[iCid]=0;
	g_iGrenThrow[iCid]=0;
	g_iGrenType[iCid]=0;
	g_iPState[iCid]=0;
	g_iPIncap[iCid]=0;
	g_iSpiritCooldown[iCid]=0;
	g_iDisabling[iCid]=0;

	if (g_iConfirm[iCid]==0
		&& IsFakeClient(iCid)==false)
		CreateTimer(1.0,Timer_ShowTopMenu,iCid);
}

//reset perk values when disconnected
//closes timer for spirit cooldown
//and rebuilds DT registry
public Event_PDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iCid==0) return;
	g_iSur1[iCid]=0;
	g_iSur2[iCid]=0;
	g_iInf1[iCid]=0;
	g_iInf2[iCid]=0;
	g_iInf3[iCid]=0;
	g_iInf4[iCid]=0;
	g_iConfirm[iCid]=0;
	g_iGren[iCid]=0;
	g_iGrenThrow[iCid]=0;
	g_iGrenType[iCid]=0;
	g_iPState[iCid]=0;
	g_iPIncap[iCid]=0;
	g_iSpiritCooldown[iCid]=0;
	g_iDisabling[iCid]=0;

	if (g_iSpiritTimer[iCid]!=INVALID_HANDLE)
	{
		CloseHandle(g_iSpiritTimer[iCid]);
		g_iSpiritTimer[iCid]=INVALID_HANDLE;
	}
	DT_Rebuild();
	MA_Rebuild();
}

//call menu on first spawn, otherwise set default values for bots
public Event_PlayerFirstSpawn (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iCid==0) return;
	if (g_iConfirm[iCid]==0
		&& IsFakeClient(iCid)==false)
	{
		CreateTimer(1.0,Timer_ShowTopMenu,iCid);
		PrintHintText(iCid,"Welcome to Perkmod!");
		PrintToChat(iCid,"\x03[SM] Welcome to Perkmod! If the menu doesn't come up, type !perks to display it.");
	}
}

//checks to show perks menu on roundstart
//and resets various vars to default
public Event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	//----DEBUG----
	//PrintToChatAll("\x03round start detected");

	for (new iI=1 ; iI<=MaxClients ; iI++)
	{
		//----DEBUG----
		//PrintToChatAll("\x03-cycle %i",iI);

		//reset vars related to spirit perk
		g_iPState[iI]=0;
		g_iPIncap[iI]=0;
		g_iSpiritCooldown[iI]=0;
		//reset var related to various hunter/smoker perks
		g_iDisabling[iI]=0;

		//reset var pointing to client's spirit timer
		//and close the timer handle
		if (g_iSpiritTimer[iI]!=INVALID_HANDLE)
		{
			CloseHandle(g_iSpiritTimer[iI]);
			g_iSpiritTimer[iI]=INVALID_HANDLE;
		}

		//before we run any functions on players
		//check if the game has any players to prevent
		//stupid error messages cropping up on the server
		if (IsServerProcessing()==false)
			continue;

		//only run these commands if player is in-game
		if (IsClientInGame(iI)==true)
		{
			//reset run speeds for martial artist
			SetEntDataFloat(iI,g_iLaggedMovementO, 1.0 ,true);

			if (IsFakeClient(iI)==true) continue;
			//show the perk menu if their perks are unconfirmed
			if (g_iConfirm[iI]==0)
				CreateTimer(1.0,Timer_ShowTopMenu,iI);
			//otherwise check for pyro's initial grenade
			//or for chem reliant's initial pills
			else if (g_iConfirm[iI]==1
				&& GetClientTeam(iI)==2)
			{
				if (g_iSur1[iI]==2) Event_Confirm_Grenadier(iI);
				if (g_iSur2[iI]==1) Event_Confirm_ChemReliant(iI);
			}
			//reset var related to blind luck perk
			//SendConVarValue(iI,hCvar,"0");
			SetEntProp(iI, Prop_Send, "m_iHideHUD", 0);
		}

	}

	decl Handle:hCvar;

	//reset vomit vars

	if (g_iInf1_enable==1
		&& g_iBlind_enable==1
		&& g_iBlind_convar==1)
	{
		hCvar=FindConVar("z_vomit_interval");
		ResetConVar(hCvar,false,false);
		g_flVomitInt=GetConVarFloat(hCvar);
	}

	if (g_iInf1_enable==1
		&& g_iMotion_enable==1)
	{
		hCvar=FindConVar("z_vomit_fatigue");
		ResetConVar(hCvar,false,false);
		g_flVomitFatigue=GetConVarFloat(hCvar);
	}

	//reset tongue vars

	if (g_iInf3_enable==1
		&& g_iTongue_enable==1)
	{
		hCvar=FindConVar("tongue_victim_max_speed");
		ResetConVar(hCvar,false,false);
		g_flTongueSpeed=GetConVarFloat(hCvar);

		hCvar=FindConVar("tongue_range");
		ResetConVar(hCvar,false,false);
		g_flTongueRange=GetConVarFloat(hCvar);

		hCvar=FindConVar("tongue_fly_speed");
		ResetConVar(hCvar,false,false);
		g_flTongueFlySpeed=GetConVarFloat(hCvar);
	}

	if (g_iInf3_enable==1
		&& g_iDrag_enable==1)
	{
		ResetConVar(FindConVar("tongue_allow_voluntary_release"),false,false);

		hCvar=FindConVar("tongue_hit_delay");
		ResetConVar(hCvar,false,false);
		g_flTongueHitDelay=GetConVarFloat(hCvar);

		hCvar=FindConVar("tongue_player_dropping_to_ground_time");
		ResetConVar(hCvar,false,false);
		g_flTongueDropTime=GetConVarFloat(hCvar);
	}

	//reset tank attack intervals
	//and rock throw force

	if (g_iInf2_enable==1
		&& g_iAdrenal_enable==1)
	{
		hCvar=FindConVar("tank_swing_interval");
		ResetConVar(hCvar,false,false);
		g_flSwingInterval1=GetConVarFloat(hCvar);

		hCvar=FindConVar("tank_swing_miss_interval");
		ResetConVar(hCvar,false,false);
		g_flSwingInterval2=GetConVarFloat(hCvar);

		hCvar=FindConVar("z_tank_attack_interval");
		ResetConVar(hCvar,false,false);
		g_flSwingInterval3=GetConVarFloat(hCvar);

		hCvar=FindConVar("z_tank_throw_interval");
		ResetConVar(hCvar,false,false);
		g_flRockInterval=GetConVarFloat(hCvar);

		hCvar=FindConVar("z_tank_throw_force");
		ResetConVar(hCvar,false,false);
		g_flRockSpeed=GetConVarFloat(hCvar);
	}

	//reset tank's speed to default value

	if (g_iInf2_enable==1
		&& g_iMetabolic_enable==1)
	{
		hCvar=FindConVar("z_tank_speed_vs");
		ResetConVar(hCvar,false,false);
		g_flTankSpeed=GetConVarFloat(hCvar);
	}

	//set crawling vars

	if (g_iSur1_enable==1
		&& g_iSpirit_crawling==1
		&& g_iSpirit_enable==1)
	{
		SetConVarInt(FindConVar("survivor_allow_crawling"),0,false,false);
		SetConVarFloat(FindConVar("survivor_crawl_speed"),30.0,false,false);
	}

	//finally, clear DT and MA registry
	DT_Clear();
	MA_Clear();
	//calculate pack rat capacities
	PR_Calculate();
	//recalculate DT and stopping power
	//permissions on game frame
	DT_RunChecks();
	Stopping_RunChecks();
	//reset boomer vars
	g_iSlimed		= 0;
	g_iSlimerLast	= 0;
	//reset tank vars
	g_iTank			= 0;
	g_iTankCount	= 0;

	//detect gamemode and difficulty
	new String:stArg[64];
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
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iCid==0) return;
	//reset vars related to spirit perk
	g_iPState[iCid]=0;
	g_iPIncap[iCid]=0;
	g_iSpiritCooldown[iCid]=0;
	g_iDisabling[iCid]=0;
	//and also close the spirit cooldown timer
	//and nullify the var pointing to it
	if (g_iSpiritTimer[iCid]!=INVALID_HANDLE)
	{
		CloseHandle(g_iSpiritTimer[iCid]);
		g_iSpiritTimer[iCid]=INVALID_HANDLE;
	}

	if (IsClientInGame(iCid)==true
		&& IsFakeClient(iCid)==false)
	{
		//reset var related to blind luck perk
		//SendConVarValue(iCid,FindConVar("sv_cheats"),"0");
		SetEntProp(iCid, Prop_Send, "m_iHideHUD", 0);
	}

	//rebuild registries for double tap and martial artist
	if (GetClientTeam(iCid)==2)
	{
		DT_Rebuild();
		MA_Rebuild();
	}

	//reset movement rate from martial artist
	SetEntDataFloat(iCid,g_iLaggedMovementO, 1.0 ,true);

	//----DEBUG----
	//PrintToChatAll("\x03end death routine for \x01%i",iCid);
}


//sets confirm to 0 and redisplays perks menu
public Event_PlayerTransitioned (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iCid==0) return;
	//reset their confirm perks var
	//and show the menu
	g_iConfirm[iCid]=0;
	CreateTimer(1.0,Timer_ShowTopMenu,iCid);
	//since we just changed maps
	//reset everything for the spirit cooldown timer
	if (g_iSpiritTimer[iCid]!=INVALID_HANDLE)
	{
		CloseHandle(g_iSpiritTimer[iCid]);
		g_iSpiritTimer[iCid]=INVALID_HANDLE;
	}
}

//resets everyone's confirm values on round end, mainly for survival and campaign
public Event_RoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	//----DEBUG----
	//PrintToChatAll("round end detected");

	DT_Clear();
	MA_Clear();

	for (new iI=1 ; iI<=MaxClients ; iI++)
	{
		g_iConfirm[iI]=0;
	}
}

//as round end function above
public OnMapEnd()
{
	//----DEBUG----
	//PrintToChatAll("map end detected");

	DT_Clear();
	MA_Clear();

	for (new iI=1 ; iI<=MaxClients ; iI++)
	{
		g_iConfirm[iI]=0;
	}
}

//Anything that uses a global timer for periodic
//checks is also called here; current functions called here:
//Sur1: Spirit, Sur2: Martial Artist
public Action:TimerPerks (Handle:timer, any:data)
{
	if (IsServerProcessing()==false)
		return Plugin_Continue;

	Spirit_Timer();
	MA_ResetFatigue();

	return Plugin_Continue;
}

//called on a player changing teams
//and rebuilds DT registry (and MA as well)
public Event_PlayerTeam (Handle:event, const String:name[], bool:dontBroadcast)
{
	//----DEBUG----
	//PrintToChatAll("\x03change team detected");

	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iCid==0
		|| IsValidEntity(iCid)==false
		|| IsClientInGame(iCid)==false) return;

	//reset vars related to spirit perk
	g_iPState[iCid]=0;
	g_iPIncap[iCid]=0;
	g_iSpiritCooldown[iCid]=0;
	//reset var related to various hunter/smoker perks
	g_iDisabling[iCid]=0;

	//reset var pointing to client's spirit timer
	//and close the timer handle
	if (g_iSpiritTimer[iCid]!=INVALID_HANDLE)
	{
		CloseHandle(g_iSpiritTimer[iCid]);
		g_iSpiritTimer[iCid]=INVALID_HANDLE;
	}

	//reset runspeed
	SetEntDataFloat(iCid,g_iLaggedMovementO, 1.0 ,true);

	//reset blind perk sendprop
	if (IsFakeClient(iCid)==false)
		SetEntProp(iCid, Prop_Send, "m_iHideHUD", 0);

	//rebuild MA and DT registries
	CreateTimer(0.3,Delayed_Rebuild,0);

	//apply perks if changing into survivors
	CreateTimer(0.3,Delayed_PerkChecks,iCid);

	//----DEBUG----
	//PrintToChatAll("\x03-end change team routine");
}

//trying a delayed rebuild so DT
//will work with team switches
public Action:Delayed_Rebuild (Handle:timer, any:data)
{
	DT_Rebuild();
	MA_Rebuild();
}

//delayed perk checks
public Action:Delayed_PerkChecks (Handle:timer, any:iCid)
{
	if (IsClientConnected(iCid)==false
		|| IsClientInGame(iCid)==false
		|| GetClientTeam(iCid)!=2)
		return Plugin_Continue;

	Event_Confirm_Unbreakable(iCid);
	Event_Confirm_PackRat(iCid);
	Event_Confirm_Grenadier(iCid);
	Event_Confirm_ChemReliant(iCid);

	return Plugin_Continue;
}

//delayed show menu to prevent weird not-showing on
//campaign round restarts...
//... since 1.3, also checks if force random perks server
//setting is on; if so, then assigns perks instead
public Action:Timer_ShowTopMenu (Handle:timer, any:iCid)
{
	//----DEBUG----
	//PrintToChatAll("\x03showing menu to \x01%i",iCid);

	if (g_iForceRandom==0)
		SendPanelToClient(Menu_Initial(iCid),iCid,Menu_ChooseInit,MENU_TIME_FOREVER);
	else
		AssignRandomPerks(iCid);
}

//assigns random perks
AssignRandomPerks (iCid)
{
	//don't do anything if
	//the client id is whacked
	//or if confirm perks is set
	if (iCid > MaxClients
		|| iCid <= 0
		|| g_iConfirm[iCid]==1)
		return;

	//we track which perks are randomizable
	//in this array
	new iPerkType[10];
	//and keep track of which perk we're on
	decl iPerkCount;


	//SUR1 PERK
	//---------
	iPerkCount=0;

	//1 stopping power
	if (g_iStopping_enable==1			&&	g_iL4D_GameMode==0
		|| g_iStopping_enable_sur==1	&&	g_iL4D_GameMode==1
		|| g_iStopping_enable_vs==1		&&	g_iL4D_GameMode==2)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=1;
	}

	//2 pyrotechnician
	if (g_iPyro_enable==1			&&	g_iL4D_GameMode==0
		|| g_iPyro_enable_sur==1	&&	g_iL4D_GameMode==1
		|| g_iPyro_enable_vs==1		&&	g_iL4D_GameMode==2)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=2;
	}

	//3 spirit
	if (g_iSpirit_enable==1			&&	g_iL4D_GameMode==0
		|| g_iSpirit_enable_sur==1	&&	g_iL4D_GameMode==1
		|| g_iSpirit_enable_vs==1	&&	g_iL4D_GameMode==2)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=3;
	}

	//4 double tap
	if (g_iDT_enable==1			&&	g_iL4D_GameMode==0
		|| g_iDT_enable_sur==1	&&	g_iL4D_GameMode==1
		|| g_iDT_enable_vs==1	&&	g_iL4D_GameMode==2)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=4;
	}

	//5 unbreakable
	if (g_iUnbreak_enable==1		&&	g_iL4D_GameMode==0
		|| g_iUnbreak_enable_sur==1	&&	g_iL4D_GameMode==1
		|| g_iUnbreak_enable_vs==1	&&	g_iL4D_GameMode==2)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=5;
	}

	//6 sleight of hand
	if (g_iSoH_enable==1		&&	g_iL4D_GameMode==0
		|| g_iSoH_enable_sur==1	&&	g_iL4D_GameMode==1
		|| g_iSoH_enable_vs==1	&&	g_iL4D_GameMode==2)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=6;
	}

	//randomize a perk
	if (iPerkCount>0)
		g_iSur1[iCid] = iPerkType[ GetRandomInt(1,iPerkCount) ];


	//SUR2 PERK
	//---------
	iPerkCount=0;

	//1 chem reliant
	if (g_iChem_enable==1			&&	g_iL4D_GameMode==0
		|| g_iChem_enable_sur==1	&&	g_iL4D_GameMode==1
		|| g_iChem_enable_vs==1		&&	g_iL4D_GameMode==2)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=1;
	}

	//2 helping hand
	if (g_iHelpHand_enable==1			&&	g_iL4D_GameMode==0
		|| g_iHelpHand_enable_sur==1	&&	g_iL4D_GameMode==1
		|| g_iHelpHand_enable_vs==1		&&	g_iL4D_GameMode==2)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=2;
	}

	//3 pack rat
	if (g_iPack_enable==1			&&	g_iL4D_GameMode==0
		|| g_iPack_enable_sur==1	&&	g_iL4D_GameMode==1
		|| g_iPack_enable_vs==1		&&	g_iL4D_GameMode==2)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=3;
	}

	//4 martial artist
	if (g_iMA_enable==1			&&	g_iL4D_GameMode==0
		|| g_iMA_enable_sur==1	&&	g_iL4D_GameMode==1
		|| g_iMA_enable_vs==1	&&	g_iL4D_GameMode==2)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=4;
	}

	//5 hard to kill
	if (g_iHard_enable==1			&&	g_iL4D_GameMode==0
		|| g_iHard_enable_sur==1	&&	g_iL4D_GameMode==1
		|| g_iHard_enable_vs==1		&&	g_iL4D_GameMode==2)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=5;
	}

	//randomize a perk
	if (iPerkCount>0)
		g_iSur2[iCid] = iPerkType[ GetRandomInt(1,iPerkCount) ];


	//INF1 (BOOMER) PERK
	//------------------
	iPerkCount=0;

	//1 barf bagged
	if (g_iBarf_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=1;
	}

	//2 blind luck
	if (g_iBlind_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=2;
	}

	//3 dead wreckening
	if (g_iDead_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=3;
	}

	//4 motion sickness
	if (g_iMotion_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=4;
	}

	//randomize a perk
	if (iPerkCount>0)
		g_iInf1[iCid] = iPerkType[ GetRandomInt(1,iPerkCount) ];


	//INF3 (SMOKER) PERK
	//------------------
	iPerkCount=0;

	//1 tongue twister
	if (g_iTongue_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=1;
	}

	//2 squeezer
	if (g_iSqueezer_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=2;
	}

	//3 drag and drop
	if (g_iDrag_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=3;
	}

	//randomize a perk
	if (iPerkCount>0)
		g_iInf3[iCid] = iPerkType[ GetRandomInt(1,iPerkCount) ];


	//INF4 (HUNTER) PERK
	//------------------
	iPerkCount=0;

	//1 body slam
	if (g_iBody_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=1;
	}

	//2 efficient killer
	if (g_iEfficient_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=2;
	}

	//3 grasshopper
	if (g_iGrass_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=3;
	}

	//4 old school
	if (g_iOld_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=4;
	}

	//5 speed demon
	if (g_iSpeedDemon_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=5;
	}

	//randomize a perk
	if (iPerkCount>0)
		g_iInf4[iCid] = iPerkType[ GetRandomInt(1,iPerkCount) ];


	//INF2 (TANK) PERK
	//----------------
	iPerkCount=0;

	//1 adrenal glands
	if (g_iAdrenal_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=1;
	}

	//2 Juggernaut
	if (g_iJuggernaut_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=2;
	}

	//3 metabolic boost
	if (g_iMetabolic_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=3;
	}

	//4 stormcaller
	if (g_iStorm_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=4;
	}

	//5 double the trouble
	if (g_iDouble_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=5;
	}

	//randomize a perk
	if (iPerkCount>0)
		g_iInf2[iCid] = iPerkType[ GetRandomInt(1,iPerkCount) ];


	//finally, confirm perks
	//and run the necessary functions
	//as if the player had confirmed
	//their perks through the traditional way
	g_iConfirm[iCid]=1;
	Event_Confirm_Unbreakable(iCid);
	Event_Confirm_PackRat(iCid);
	Event_Confirm_Grenadier(iCid);
	Event_Confirm_ChemReliant(iCid);
	Event_Confirm_DT(iCid);
	Event_Confirm_MA(iCid);

	//lastly, show a panel to the player
	//showing what perks they were given
	SendPanelToClient(Menu_ShowChoices(iCid),iCid,Menu_DoNothing,15);

}

//picks a random perk for bots
Bot_Sur1_PickRandom ()
{
	//stop if sur1 perks are disabled
	if (g_iSur1_enable==0)
		return 0;

	new iPerkType[12];
	new iPerkCount=0;

	decl String:stPerk[24];
	GetConVarString(g_hBot_Sur1,stPerk,24);

	//stopping power
	if (StrContains(stPerk,"1",false) != -1
		&& g_iStopping_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=1;
	}

	//spirit
	if (StrContains(stPerk,"2",false) != -1
		&& g_iSpirit_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=3;
	}

	//unbreakable
	if (StrContains(stPerk,"3",false) != -1
		&& g_iUnbreak_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=5;
	}

	//sleight of hand
	if (StrContains(stPerk,"4",false) != -1
		&& g_iSoH_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=6;
	}

	//randomize
	if (iPerkCount>0)
		return iPerkType[ GetRandomInt(1,iPerkCount) ];
	else
		return 0;
}

Bot_Sur2_PickRandom ()
{
	//stop if sur2 perks are disabled
	if (g_iSur2_enable==0)
		return 0;

	new iPerkType[12];
	new iPerkCount=0;

	decl String:stPerk[24];
	GetConVarString(g_hBot_Sur2,stPerk,24);

	//chem reliant
	if (StrContains(stPerk,"1",false) != -1
		&& g_iChem_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=1;
	}

	//helping hand
	if (StrContains(stPerk,"2",false) != -1
		&& g_iHelpHand_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=2;
	}

	//pack rat
	if (StrContains(stPerk,"3",false) != -1
		&& g_iPack_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=3;
	}

	//hard to kill
	if (StrContains(stPerk,"4",false) != -1
		&& g_iHard_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=5;
	}

	//randomize
	if (iPerkCount>0)
		return iPerkType[ GetRandomInt(1,iPerkCount) ];
	else
		return 0;
}

Bot_Inf1_PickRandom ()
{
	//stop if boomer perks are disabled
	if (g_iInf1_enable==0)
		return 0;

	//----DEBUG----
	//PrintToChatAll("\x03begin random perk for boomer");

	new iPerkType[12];
	new iPerkCount=0;

	decl String:stPerk[24];
	GetConVarString(g_hBot_Inf1,stPerk,24);

	//----DEBUG----
	//PrintToChatAll("\x03-stPerk: \x01%s",stPerk);

	//barf bagged
	if (StrContains(stPerk,"1",false) != -1
		&& g_iBarf_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=1;

		//----DEBUG----
		//PrintToChatAll("\x03-count \x01%i\x03, type \x01%i",iPerkCount,iPerkType[iPerkCount]);
	}

	//blind luck
	if (StrContains(stPerk,"2",false) != -1
		&& g_iBlind_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=2;

		//----DEBUG----
		//PrintToChatAll("\x03-count \x01%i\x03, type \x01%i",iPerkCount,iPerkType[iPerkCount]);
	}

	//dead wreckening
	if (StrContains(stPerk,"3",false) != -1
		&& g_iDead_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=3;

		//----DEBUG----
		//PrintToChatAll("\x03-count \x01%i\x03, type \x01%i",iPerkCount,iPerkType[iPerkCount]);
	}

	//randomize
	decl iReturn;
	if (iPerkCount>0)
		iReturn = iPerkType[ GetRandomInt(1,iPerkCount) ];
	else
		iReturn = 0;

	//----DEBUG----
	//PrintToChatAll("\x03-returning \x01%i",iReturn);

	return iReturn;
}

Bot_Inf2_PickRandom ()
{
	//stop if tank perks are disabled
	if (g_iInf2_enable==0)
		return 0;

	new iPerkType[12];
	new iPerkCount=0;

	decl String:stPerk[24];
	GetConVarString(g_hBot_Inf2,stPerk,24);

	//adrenal glands
	if (StrContains(stPerk,"1",false) != -1
		&& g_iAdrenal_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=1;
	}

	//juggernaut
	if (StrContains(stPerk,"2",false) != -1
		&& g_iJuggernaut_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=2;
	}

	//metabolic boost
	if (StrContains(stPerk,"3",false) != -1
		&& g_iMetabolic_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=3;
	}

	//storm caller
	if (StrContains(stPerk,"4",false) != -1
		&& g_iStorm_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=4;
	}

	//double trouble
	if (StrContains(stPerk,"5",false) != -1
		&& g_iDouble_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=5;
	}

	//randomize
	if (iPerkCount>0)
		return iPerkType[ GetRandomInt(1,iPerkCount) ];
	else
		return 0;
}

Bot_Inf3_PickRandom ()
{
	//stop if smoker perks are disabled
	if (g_iInf3_enable==0)
		return 0;

	new iPerkType[12];
	new iPerkCount=0;

	decl String:stPerk[24];
	GetConVarString(g_hBot_Inf3,stPerk,24);

	//tongue twister
	if (StrContains(stPerk,"1",false) != -1
		&& g_iTongue_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=1;
	}

	//squeezer
	if (StrContains(stPerk,"2",false) != -1
		&& g_iSqueezer_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=2;
	}

	//drag and drop
	if (StrContains(stPerk,"3",false) != -1
		&& g_iDrag_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=3;
	}

	//randomize
	if (iPerkCount>0)
		return iPerkType[ GetRandomInt(1,iPerkCount) ];
	else
		return 0;
}

Bot_Inf4_PickRandom ()
{
	//stop if hunter perks are disabled
	if (g_iInf4_enable==0)
		return 0;

	new iPerkType[12];
	new iPerkCount=0;

	decl String:stPerk[24];
	GetConVarString(g_hBot_Inf4,stPerk,24);

	//efficient killer
	if (StrContains(stPerk,"1",false) != -1
		&& g_iEfficient_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=1;
	}

	//speed demon
	if (StrContains(stPerk,"2",false) != -1
		&& g_iSpeedDemon_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=2;
	}

	//old school
	if (StrContains(stPerk,"3",false) != -1
		&& g_iOld_enable==1)
	{
		iPerkCount++;
		iPerkType[iPerkCount]=3;
	}

	//randomize
	if (iPerkCount>0)
		return iPerkType[ GetRandomInt(1,iPerkCount) ];
	else
		return 0;
}

//called when plugin is unloaded
//reset all the convars that had permission to run
public OnPluginEnd()
{
	//----DEBUG----
	//PrintToChatAll("\x03begin pluginend routine");

	for (new iI=1 ; iI<=MaxClients ; iI++)
	{
		//reset var pointing to client's spirit timer
		//and close the timer handle
		if (g_iSpiritTimer[iI]!=INVALID_HANDLE)
		{
			CloseHandle(g_iSpiritTimer[iI]);
			g_iSpiritTimer[iI]=INVALID_HANDLE;
		}

		//before we run any functions on players
		//check if the game has any players to prevent
		//stupid error messages cropping up on the server
		if (IsServerProcessing()==false)
			continue;

		//only run these commands if player is in-game
		if (IsClientInGame(iI)==true)
		{
			//reset run speeds for martial artist
			SetEntDataFloat(iI,g_iLaggedMovementO, 1.0 ,true);

			//reset var related to blind luck perk
			//SendConVarValue(iI,hCvar,"0");
			SetEntProp(iI, Prop_Send, "m_iHideHUD", 0);
		}

	}

	decl Handle:hCvar;

	//reset vomit vars

	if (g_iInf1_enable==1
		&& g_iBlind_enable==1
		&& g_iBlind_convar==1)
	{
		hCvar=FindConVar("z_vomit_interval");
		ResetConVar(hCvar,false,false);
		g_flVomitInt=GetConVarFloat(hCvar);
	}

	if (g_iInf1_enable==1
		&& g_iMotion_enable==1)
	{
		hCvar=FindConVar("z_vomit_fatigue");
		ResetConVar(hCvar,false,false);
		g_flVomitFatigue=GetConVarFloat(hCvar);
	}

	//reset tongue vars

	if (g_iInf3_enable==1
		&& g_iTongue_enable==1)
	{
		hCvar=FindConVar("tongue_victim_max_speed");
		ResetConVar(hCvar,false,false);
		g_flTongueSpeed=GetConVarFloat(hCvar);

		hCvar=FindConVar("tongue_range");
		ResetConVar(hCvar,false,false);
		g_flTongueRange=GetConVarFloat(hCvar);

		hCvar=FindConVar("tongue_fly_speed");
		ResetConVar(hCvar,false,false);
		g_flTongueFlySpeed=GetConVarFloat(hCvar);
	}

	if (g_iInf3_enable==1
		&& g_iDrag_enable==1)
	{
		ResetConVar(FindConVar("tongue_allow_voluntary_release"),false,false);

		hCvar=FindConVar("tongue_hit_delay");
		ResetConVar(hCvar,false,false);
		g_flTongueHitDelay=GetConVarFloat(hCvar);

		hCvar=FindConVar("tongue_player_dropping_to_ground_time");
		ResetConVar(hCvar,false,false);
		g_flTongueDropTime=GetConVarFloat(hCvar);
	}

	//reset tank attack intervals
	//and rock throw force

	if (g_iInf2_enable==1
		&& g_iAdrenal_enable==1)
	{
		hCvar=FindConVar("tank_swing_interval");
		ResetConVar(hCvar,false,false);
		g_flSwingInterval1=GetConVarFloat(hCvar);

		hCvar=FindConVar("tank_swing_miss_interval");
		ResetConVar(hCvar,false,false);
		g_flSwingInterval2=GetConVarFloat(hCvar);

		hCvar=FindConVar("z_tank_attack_interval");
		ResetConVar(hCvar,false,false);
		g_flSwingInterval3=GetConVarFloat(hCvar);

		hCvar=FindConVar("z_tank_throw_interval");
		ResetConVar(hCvar,false,false);
		g_flRockInterval=GetConVarFloat(hCvar);

		hCvar=FindConVar("z_tank_throw_force");
		ResetConVar(hCvar,false,false);
		g_flRockSpeed=GetConVarFloat(hCvar);
	}

	//reset tank's speed to default value

	if (g_iInf2_enable==1
		&& g_iMetabolic_enable==1)
	{
		hCvar=FindConVar("z_tank_speed_vs");
		ResetConVar(hCvar,false,false);
		g_flTankSpeed=GetConVarFloat(hCvar);
	}

	//set crawling vars

	if (g_iSur1_enable==1
		&& g_iSpirit_crawling==1
		&& g_iSpirit_enable==1)
	{
		SetConVarInt(FindConVar("survivor_allow_crawling"),0,false,false);
		SetConVarFloat(FindConVar("survivor_crawl_speed"),30.0,false,false);
	}

	//finally, clear DT and MA registry
	DT_Clear();
	MA_Clear();

	//----DEBUG----
	//PrintToChatAll("\x03-end pluginend routine");
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
	new iAtt=GetClientOfUserId(GetEventInt(event,"attacker"));
	new iVic=GetClientOfUserId(GetEventInt(event,"userid"));

	//----DEBUG----
	//new iType=GetEventInt(event,"type");
	//new String:sWeapon[128];
	//GetEventString(event,"weapon",sWeapon,128);
	//PrintToChatAll("\x03attacker:\x01%i\x03 weapon:\x01%s\x03 type:\x01%i",iAtt,sWeapon,iType);

	if (iVic==0) return Plugin_Continue;

	//check for dead wreckening damage add for zombies
	if (iAtt==0)
	{
		if (GetEventInt(event,"type")==128
			&& g_iSlimed>0
			&& g_iConfirm[g_iSlimerLast]==1
			&& g_iInf1[g_iSlimerLast]==3)
		{
			//check if perk is enabled
			if (g_iInf1_enable==0
				|| g_iDead_enable==0)
				return Plugin_Continue;

			//----DEBUG----
			//PrintToChatAll("\x03dead wreckening fire");

			new iDmgOrig=GetEventInt(event,"dmg_health");
			InfToSurDamageAdd(iVic, RoundToCeil(iDmgOrig * g_flDead_dmgmult) ,iDmgOrig);
		}
		return Plugin_Continue;
	}

	new iTA=GetClientTeam(iAtt);

	//if damage is from survivors to a non-survivor,
	//check for damage add (stopping power)
	if (iTA==2
		&& g_iSur1[iAtt]==1
		&& g_iConfirm[iAtt]==1
		&& GetClientTeam(iVic)!=2)
	{
		//check if perk is disabled
		if (g_iStopping_meta_enable==0)
			return Plugin_Continue;

		//----DEBUG----
		//PrintToChatAll("\x03Pre-mod bullet damage: \x01%i", GetEventInt(event,"dmg_health"));

		new iDmgOrig=GetEventInt(event,"dmg_health");
		new iDmgAdd= RoundToNearest(iDmgOrig * g_flStopping_dmgmult);
		new iHP=GetEntProp(iVic,Prop_Data,"m_iHealth");
		//to prevent strange death behaviour,
		//only deal the full damage add if health > damage add
		if (iHP>iDmgAdd)
		{
			SetEntProp(iVic,Prop_Data,"m_iHealth", iHP-iDmgAdd );
		}
		//if health < damage add, only deal health-1 damage
		else
		{
			iDmgAdd=iHP-1;
			//don't bother if the modified damage add
			//ends up being an insignificant amount
			if (iDmgAdd<0)
				return Plugin_Continue;
			SetEntProp(iVic,Prop_Data,"m_iHealth", iHP-iDmgAdd );
		}

		//----DEBUG----
		//PrintToChatAll("\x03Post-mod bullet damage: \x01%i",GetEventInt(event,"dmg_health"));

		return Plugin_Continue;
	}

	//otherwise, check for infected damage add types
	//(body slam, efficient killer, squeezer)
	else if (iTA==3
		&& g_iConfirm[iAtt]==1)
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
				&& g_iInf4[iAtt]==1)
			{
				//stop if body slam is disabled
				if (g_iInf4_enable==0
					|| g_iBody_enable==0)
					return Plugin_Continue;

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

					new iHP=GetEntProp(iVic,Prop_Data,"m_iHealth");

					//if health>8, then run normally
					if (iHP>iMinBound)
					{
						//----DEBUG----
						//PrintToChatAll("\x03iHP>8 condition");

						SetEntProp(iVic,Prop_Data,"m_iHealth", iHP-(iMinBound-iDmgOrig) );
						PrintHintText(iAtt,"Body Slam: %i bonus damage!", iMinBound-iDmgOrig);

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

						new Float:flHPBuff=GetEntDataFloat(iVic,g_iHPBuffO);

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
								SetEntProp(iVic,Prop_Data,"m_iHealth", iHP-iDmgCount );

								//if damage add is more than health buffer,
								//set damage add to health buffer amount
								new iHPBuff=RoundToFloor(flHPBuff);
								if (iHPBuff<iDmgAdd) iDmgAdd=iHPBuff;
								SetEntDataFloat(iVic,g_iHPBuffO, flHPBuff-iDmgAdd ,true);
								PrintHintText(iAtt,"Body Slam: %i bonus damage!", iDmgCount+iDmgAdd);

								//----DEBUG----
								//PrintToChatAll("\x03-damage to health: \x01%i\x03, current health: \x01%i",iDmgCount,GetEntProp(iVic,Prop_Data,"m_iHealth"));
								//PrintToChatAll("\x03-damage to buffer: \x01%i\x03, current buffer: \x01%f",iDmgAdd,GetEntDataFloat(iVic,g_iHPBuffO));

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

								SetEntProp(iVic,Prop_Data,"m_iHealth", iHP-iDmgAdd );
								PrintHintText(iAtt,"Body Slam: %i bonus damage!", iDmgAdd);
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
							SetEntProp(iVic,Prop_Data,"m_iHealth", iHP-iDmgAdd );
							PrintHintText(iAtt,"Body Slam: %i bonus damage!", iDmgAdd);

							//----DEBUG----
							//PrintToChatAll("\x03-iHP<8, %i bonus damage", iDmgAdd );

							return Plugin_Continue;
						}
					}
				}
				return Plugin_Continue;
			}

			//...check for efficient killer
			else if (g_iInf4[iAtt]==2
				&& g_iDisabling[iAtt]==1)
			{
				//stop if eff.killer is disabled
				if (g_iInf4_enable==0
					|| g_iEfficient_enable==0)
					return Plugin_Continue;

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

				InfToSurDamageAdd(iVic, iDmgAdd ,GetEventInt(event,"dmg_health"));
				return Plugin_Continue;
			}
			
			//check for old school
			else if (g_iInf4[iAtt]==4
				&& g_iDisabling[iAtt]==0)
			{
				//stop if old school is disabled
				if (g_iInf4_enable==0
					|| g_iOld_enable==0)
					return Plugin_Continue;

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

				InfToSurDamageAdd(iVic, iDmgAdd ,GetEventInt(event,"dmg_health"));
				return Plugin_Continue;
			}

		}

		//alternatively, if it's from a
		//SMOKER with the squeezer perk...
		else if (StrEqual(st_wpn,"smoker_claw")==true
			&& g_iInf3[iAtt]==2
			&& g_iDisabling[iAtt]>0)
		{
			//stop if perk is disabled
			if (g_iInf3_enable==0
				|| g_iSqueezer_enable==0)
				return Plugin_Continue;

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

			InfToSurDamageAdd(iVic, iDmgAdd ,GetEventInt(event,"dmg_health"));
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
InfToSurDamageAdd (any:iVic, any:iDmgAdd, any:iDmgOrig)
{
	//don't bother running if client id is zero
	//since sourcemod is intolerant of local servers
	//and if damage add is zero... why bother?
	if (iVic==0 || iDmgAdd<=0) return;

	new iHP=GetEntProp(iVic,Prop_Data,"m_iHealth");

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

		SetEntProp(iVic,Prop_Data,"m_iHealth", iHP-iDmgAdd );

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

		new Float:flHPBuff=GetEntDataFloat(iVic,g_iHPBuffO);

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
			SetEntProp(iVic,Prop_Data,"m_iHealth", iHP-iDmgCount );

			//and now we take the remainder of the
			//damage add and apply it to the health buffer.

			//if damage add is more than health buffer,
			//set damage add to health buffer amount
			new iHPBuff=RoundToFloor(flHPBuff);
			if (iHPBuff<iDmgAdd) iDmgAdd=iHPBuff;
			//and here we apply the damage to the buffer
			SetEntDataFloat(iVic,g_iHPBuffO, flHPBuff-iDmgAdd ,true);

			//finally, set the proper value in the event info

			//----DEBUG----
			//PrintToChatAll("\x03-damage to health: \x01%i\x03, current health: \x01%i",iDmgCount,GetEntProp(iVic,Prop_Data,"m_iHealth"));
			//PrintToChatAll("\x03-damage to buffer: \x01%i\x03, current buffer: \x01%f",iDmgAdd,GetEntDataFloat(iVic,g_iHPBuffO));

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

			SetEntProp(iVic,Prop_Data,"m_iHealth", iHP-iDmgAdd );

			//----DEBUG----
			//PrintToChatAll("\x03-%i bonus damage", iDmgAdd );

			return;
		}
	}
}



//=============================
// Sur1: Stopping Power
//=============================

//pre-calculates whether stopping power should
//run, since damage events can occur pretty often
Stopping_RunChecks ()
{
	if (g_iSur1_enable==1
		&& (g_iStopping_enable==1		&&	g_iL4D_GameMode==0
		|| g_iStopping_enable_sur==1	&&	g_iL4D_GameMode==1
		|| g_iStopping_enable_vs==1		&&	g_iL4D_GameMode==2))
		g_iStopping_meta_enable=1;
	else
		g_iStopping_meta_enable=0;
}

//against common infected
public Event_InfectedHurtPre (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"attacker"));

	if (iCid==0 || g_iConfirm[iCid]==0)
		return;

	//check if perk is disabled
	if (g_iStopping_meta_enable==0)
		return;

	//----DEBUG----
	//PrintToChatAll("\x03infected hurt, iAtt: %i, iEntid: %i, i_odmg: %i, iHP: %i",iAtt,iEntid,i_odmg,GetEntProp(iEntid,Prop_Data,"m_iHealth"));

	if (g_iSur1[iCid]==1
		&& GetClientTeam(iCid)==2)
	{
		new iEntid=GetEventInt(event,"entityid");
		new i_odmg=GetEventInt(event,"amount");
		new i_dmga=RoundToNearest(i_odmg * g_flStopping_dmgmult);

		//----DEBUG----
		//PrintToChatAll("\x03Pre-mod damage: \x01%i, \x03pre-mod health: \x01%i", GetEventInt(event,"amount"),GetEntProp(iEntid,Prop_Data,"m_iHealth"));

		SetEntProp(iEntid,Prop_Data,"m_iHealth", GetEntProp(iEntid,Prop_Data,"m_iHealth")-i_dmga );
		//******SetEventInt(event,"dmg_health", i_odmg+i_dmga );

		//----DEBUG----
		//PrintToChatAll("\x03Post-mod damage: \x01%i, \x03post-mod health: \x01%i",GetEventInt(event,"amount"),GetEntProp(iEntid,Prop_Data,"m_iHealth"));
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
	new iAtt=GetClientOfUserId(GetEventInt(event,"userid"));
	new iVic=GetClientOfUserId(GetEventInt(event,"victim"));

	if (iVic==0 || iAtt==0) return;

	//----DEBUG----
	//PrintToChatAll("\x03pounce land detected, client: \x01%i\x03, victim: \x01%i",iAtt,iVic);

	//spirit victim state is disabled
	g_iPState[iVic]=1;
	//+Inf, attacker is disabling someone
	g_iDisabling[iAtt]=1;
}

//tells plugin that the attacker is no longer disabling
//and if they have the immovable object perk, removes bonus hp
//and tells plugin victim is no longer disabled
public Event_PounceStop (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iAtt=GetClientOfUserId(GetEventInt(event,"userid"));
	new iVic=GetClientOfUserId(GetEventInt(event,"victim"));

	if (iVic==0 || iAtt==0) return;

	//----DEBUG----
	//PrintToChatAll("\x03pounce stop detected, attacker: \x01%i\x03, victim: \x01%i",iAtt,iVic);

	//victim is no longer disabled
	g_iPState[iVic]=0;
	//+Inf, attacker no longer disabling
	g_iDisabling[iAtt]=0;
}



//=============================
// Sur1: Spirit
//=============================

//detects when a person is hanging from a ledge
public Event_LedgeGrab (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));

	if (iCid==0) return;

	//----DEBUG----
	//PrintToChatAll("\x03spirit ledge grab detected, client: \x01%i",iCid);

	g_iPIncap[iCid]=1;
	g_iPState[iCid]=1;
}

//when a player goes down, check everyone for spirit
//only revive one guy at a time (it'd be theoretically impossible
//to have to revive two guys at the same time, though, under the
//old system)
public Action:Event_IncapPre (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iCid==0
		|| GetClientTeam(iCid)!=2)
		return Plugin_Continue;
	g_iPIncap[iCid]=1;
	new iCrawlClient=-1;

	//check if perk is enabled
	if (g_iSur1_enable==0		
		|| g_iSpirit_enable==0		&&	g_iL4D_GameMode==0
		|| g_iSpirit_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iSpirit_enable_vs==0	&&	g_iL4D_GameMode==2)
		return Plugin_Continue;

	//----DEBUG----
	//PrintToChatAll("\x03spirit incap detected, client: \x01%i",iCid);



	//SELF-REVIVE SECTION
	//-------------------
	for (new iI=1 ; iI<=MaxClients ; iI++)
	{
		//----DEBUG----
		//PrintToChatAll("-cycle %i",iI);

		//if g_iConfirm is zero, it's probably empty...
		//but in any case, don't bother with unconfirmed peeps
		//or with people not in the game
		if (g_iConfirm[iI]==0
			|| IsClientInGame(iI)==false)
			continue;

		//since we already checked for g_iConfirm earlier,
		//it'd be a waste of time to check again
		if (GetClientTeam(iI)==2
			&& g_iSur1[iI]==3
			&& g_iPIncap[iI]==1
			&& g_iPState[iI]==0
			&& IsClientInGame(iI)==true
			&& IsPlayerAlive(iI)==true)
		{
			//----DEBUG----
			//PrintToChatAll("\x03-attempting to revive player \x01%i",iI);

			//check for cooldown (to avoid abuses)
			if (g_iSpiritCooldown[iI]==1)
			{
				//----DEBUG----
				//PrintToChatAll("\x03-player revive on cooldown: \x01%i",iI);

				if (IsFakeClient(iI)==false)
					PrintHintText(iI,"You're too tired to self-revive!");
				continue;
			}

			//if the guy who just got incapped
			//is also a guy with spirit, don't
			//try to self-revive him, but do
			//try to enable crawling
			if (iI==iCid)
			{
				iCrawlClient=iI;
				if (g_iSpirit_crawling==1
					&& g_iSpirit_enable==1)
					SetConVarInt(FindConVar("survivor_allow_crawling"),1,false,false);
				continue;
			}

			//retrieve revive count, pre-self-revive
			new iRevCount_ret = GetEntData(iCid, g_iRevCountO, 1);

			//here we give health through the console command
			//which is used to revive the player (no other way
			//I know of, setting the m_isIncapacitated in
			//CTerrorPlayer revives them but they can't move!)
			new iflags=GetCommandFlags("give");
			SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
			FakeClientCommand(iI,"give health");
			SetCommandFlags("give", iflags);

			//set revive count, post-self-revive
			SetEntData(iI, g_iRevCountO, iRevCount_ret, 1);
			//and we give them bonus health buffer here
			SetEntDataFloat(iI,g_iHPBuffO, GetEntDataFloat(iI,g_iHPBuffO)+g_iSpirit_buff ,true);
			//and remove their health here (since "give health" gives them 100!)
			CreateTimer(0.1,Spirit_ChangeHP,iI);

			g_iSpiritCooldown[iI]=1;

			new iTime;
			if (g_iL4D_GameMode==2)
				iTime=g_iSpirit_cd_vs;
			else if (g_iL4D_GameMode==1)
				iTime=g_iSpirit_cd_sur;
			else
				iTime=g_iSpirit_cd;

			g_iSpiritTimer[iI]=CreateTimer(iTime*1.0,Spirit_CooldownTimer,iI);
			g_iPIncap[iI]=0;

			//show a message if it's not a bot
			if (IsFakeClient(iI)==false)
				PrintHintText(iI,"Spirit: you've self-revived!");

			//finally, since spirit fired, break the loop
			//since we only want one person to self-revive at a time
			break;
		}
	}



	//ALLOWING/DISALLOWING CRAWLING SECTION
	//-------------------------------------
	//here we check if there's anyone else with
	//the spirit perk who's also incapped, so we
	//know if we should continue allowing crawling

	//but first, if crawling adjustments are disallowed,
	//then just return right away
	if (g_iSpirit_crawling==0
		|| g_iSpirit_enable==0)
		return Plugin_Continue;

	for (new iI=1 ; iI<=MaxClients ; iI++)
	{
		if (iCrawlClient>0) break;
		if (g_iConfirm[iI]==0) continue;
		if (g_iSur1[iI]==3
			&& g_iPIncap[iI]!=0)
		{
			iCrawlClient=iI;
			break;
		}
	}
	if (iCrawlClient>0)
		SetConVarInt(FindConVar("survivor_allow_crawling"),1,false,false);
	else
		SetConVarInt(FindConVar("survivor_allow_crawling"),0,false,false);

	//lastly, check for whether we should
	//display a hint message to non-spirit
	//perk people that they can crawl
	if (iCrawlClient>0)
	{
		decl String:stName[64];
		GetClientName(iCrawlClient,stName,64);
		for (new iI3=1 ; iI3<=MaxClients ; iI3++)
		{
			if (IsClientInGame(iI3)==true
				&& GetClientTeam(iI3)==2
				&& g_iSur1[iI3]!=3
				&& g_iPIncap[iI3]!=0
				&& iCrawlClient!=iI3)
			{
				if (IsFakeClient(iI3)==false)
					PrintHintText(iI3,"Because of %s's spirit, you can now crawl!",stName);
				continue;
			}
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
	//check if perk is enabled
	if (g_iSur1_enable==0		
		|| g_iSpirit_enable==0		&&	g_iL4D_GameMode==0
		|| g_iSpirit_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iSpirit_enable_vs==0	&&	g_iL4D_GameMode==2)
		return;

	//this var counts how many people are incapped
	new iCount=0;

	//preliminary check; if no one has
	//the spirit perk, this function will return
	for (new iI=1 ; iI<=MaxClients ; iI++)
	{
		if (g_iSur1[iI]==3)
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
	new iCid[18];

	for (new iI=1 ; iI<=MaxClients ; iI++)
	{
		//fill array with whoever's incapped
		if (IsClientInGame(iI)==true
			&& GetClientTeam(iI)==2
			&& g_iPIncap[iI]==1)
		{
			iCount++;
			iCid[iCount]=iI;

			//----DEBUG----
			//PrintToChatAll("\x03-incap registering \x01%i",iI);
		}
	}

	//if the first two client ids are null, or
	//if the count was zero OR one, return
	//since someone can't self-revive if they're
	//the only ones incapped!
	if (iCount<=1
		|| iCid[1]<=0
		|| iCid[2]<=0)
		return;

	//----DEBUG----
	//PrintToChatAll("\x03-beginning self-revive checks, iCount=\x01%i",iCount);

	//now we check for someone to revive
	//and we only revive one person at a time
	for (new iI=1 ; iI<=iCount ; iI++)
	{
		//client ids are stored incrementally (X in 1, Y in 2, Z in 3,...)
		//in the array iCid[], and iI increases per tick, hence this mess =P
		//in short, here we use iCid[iI], NOT iI!
		if (g_iConfirm[iCid[iI]]==1
			&& g_iSur1[iCid[iI]]==3
			&& g_iPState[iCid[iI]]==0
			&& g_iSpiritCooldown[iCid[iI]]==0
			&& IsClientInGame(iCid[iI])==true
			&& IsPlayerAlive(iCid[iI])==true
			&& GetClientTeam(iCid[iI])==2)
		{
			//----DEBUG----
			//PrintToChatAll("\x03-reviving \x01%i",iCid[iI]);

			//retrieve revive count
			new iRevCount_ret = GetEntData(iCid[iI], g_iRevCountO, 1);

			//here we give health through the console command
			//which is used to revive the player (no other way
			//I know of, setting the m_isIncapacitated in
			//CTerrorPlayer revives them but they can't move!)
			new iflags=GetCommandFlags("give");
			SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
			FakeClientCommand(iCid[iI],"give health");
			SetCommandFlags("give", iflags);

			//set revive count after self-revive
			SetEntData(iCid[iI], g_iRevCountO, iRevCount_ret, 1);
			//and we give them bonus health buffer here
			SetEntDataFloat(iCid[iI],g_iHPBuffO, GetEntDataFloat(iCid[iI],g_iHPBuffO)+g_iSpirit_buff ,true);
			//and remove their health here (since "give health" gives them 100!)
			CreateTimer(0.1,Spirit_ChangeHP,iCid[iI]);

			g_iSpiritCooldown[iCid[iI]]=1;

			new iTime;
			if (g_iL4D_GameMode==2)
				iTime=g_iSpirit_cd_vs;
			else if (g_iL4D_GameMode==1)
				iTime=g_iSpirit_cd_sur;
			else
				iTime=g_iSpirit_cd;

			g_iSpiritTimer[iCid[iI]]=CreateTimer(iTime*1.0,Spirit_CooldownTimer,iCid[iI]);
			g_iPIncap[iCid[iI]]=0;

			//show a message if it's not a bot
			if (IsFakeClient(iCid[iI])==false)
				PrintHintText(iCid[iI],"Spirit: you've self-revived!");

			//here we check if there's anyone else with
			//the spirit perk who's also incapped, so we
			//know if we should continue allowing crawling

			//first, check if crawling adjustments are allowed
			//if not, then just break right away
			if (g_iSpirit_crawling==0
				|| g_iSpirit_enable==0)
				break;

			new iCrawlClient=-1;
			for (new iI2=1 ; iI2<=MaxClients ; iI2++)
			{
				if (g_iConfirm[iI2]==0) continue;
				if (g_iSur1[iI2]==3
					&& g_iPIncap[iI2]!=0)
				{
					iCrawlClient=iI2;
					break;
				}
			}
			if (iCrawlClient>0)
				SetConVarInt(FindConVar("survivor_allow_crawling"),1,false,false);
			else
				SetConVarInt(FindConVar("survivor_allow_crawling"),0,false,false);

			//finally, since spirit fired, break the loop
			//since we only want one person to self-revive at a time
			break;
		}
	}
}

//cooldown timer
public Action:Spirit_CooldownTimer (Handle:timer, any:iCid)
{
	//if the cooldown's been turned off,
	//that means a new round has started
	//and we can skip everything here
	if (g_iSpiritCooldown[iCid]==0) return Plugin_Continue;

	g_iSpiritCooldown[iCid]=0;
	//we don't call CloseHandle on the timer
	//since it should already close itself on end
	//but we do nullify the pointer var
	g_iSpiritTimer[iCid]=INVALID_HANDLE;

	//and this sends the client a hint message
	if (IsPlayerAlive(iCid)==true
		&& GetClientTeam(iCid)==2
		&& IsFakeClient(iCid)==false)
		PrintHintText(iCid,"You feel strong enough to self-revive again!");

	return Plugin_Continue;
}

//timer for removing hp
//(like juggernaut, removing it too quickly
//confuses the game and doesn't remove it =/)
public Action:Spirit_ChangeHP (Handle:timer, any:iCid)
{
	SetEntityHealth(iCid,1);
	return Plugin_Continue;
}



//=============================
// Sur1: Unbreakable
//=============================

//called when player is healed; gives 80% of bonus hp
public Event_PlayerHealed (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"subject"));
	if (iCid==0 || g_iConfirm[iCid]==0) return;

	//check if perk is enabled
	if (g_iSur1_enable==0
		|| g_iUnbreak_enable==0			&&	g_iL4D_GameMode==0
		|| g_iUnbreak_enable_sur==0		&&	g_iL4D_GameMode==1
		|| g_iUnbreak_enable_vs==0		&&	g_iL4D_GameMode==2)
		return;

	if (g_iSur1[iCid]==5)
	{
		CreateTimer(0.5,Unbreakable_Delayed_Heal,iCid);
		//SetEntProp(iCid,Prop_Data,"m_iHealth", GetEntProp(iCid,Prop_Data,"m_iHealth")+(g_iUnbreak_hp*8/10) );

		//run a check to see if for whatever reason
		//the player's health is above 200
		//since 200 is the clamped maximum for unbreakable
		//in which case we set their health to 200
		if (GetEntProp(iCid,Prop_Data,"m_iHealth") > 200)
			CreateTimer(0.5,Unbreakable_Delayed_SetHigh,iCid);

		SetEventInt(event,"health_restored", GetEventInt(event,"health_restored")+(g_iUnbreak_hp*8/10) );
		PrintHintText(iCid,"Unbreakable: bonus health!");
	}
}

//called when player confirms his choices;
//gives 30 hp (to bring hp to 130, assuming survivor
//wasn't stupid and got himself hurt before confirming perks)
Event_Confirm_Unbreakable (iCid)
{
	new iHP=GetEntProp(iCid,Prop_Data,"m_iHealth");
	if (iCid==0 || g_iConfirm[iCid]==0) return;
	new TC=GetClientTeam(iCid);

	//check if perk is enabled
	if (g_iSur1_enable==0
		|| g_iUnbreak_enable==0			&&	g_iL4D_GameMode==0
		|| g_iUnbreak_enable_sur==0		&&	g_iL4D_GameMode==1
		|| g_iUnbreak_enable_vs==0		&&	g_iL4D_GameMode==2)
	{
		//if not, check if hp is higher than it should be
		if (iHP>100
			&& TC==2)
		{
			//if it IS higher, reduce hp to 100
			//otherwise, no way to know whether previous owner
			//had unbreakable, so give the incoming player
			//the benefit of doubt
			CreateTimer(0.5,Unbreakable_Delayed_SetLow,iCid);
		}
		return;
	}

	//if we've gotten up to this point, the perk is enabled
	if (g_iSur1[iCid]==5
		&& TC==2)
	{
		if (iHP>100
			&& iHP < (100+g_iUnbreak_hp) )
			CreateTimer(0.5,Unbreakable_Delayed_Max,iCid);
		else if (iHP<=100)
			CreateTimer(0.5,Unbreakable_Delayed_Normal,iCid);
		PrintHintText(iCid,"Unbreakable: bonus health!");

		//run a check to see if for whatever reason
		//the player's health is above 200
		//since 200 is the clamped maximum for unbreakable
		//in which case we set their health to 200
		if (GetEntProp(iCid,Prop_Data,"m_iHealth") > 200)
			CreateTimer(0.5,Unbreakable_Delayed_SetHigh,iCid);
	}
	//if not, check if hp is higher than it should be
	else if (g_iSur1[iCid]!=5
		&& iHP>100
		&& TC==2)
	{
		//if it IS higher, reduce hp to 100
		//otherwise, no way to know whether previous owner
		//had unbreakable, so give the incoming player
		//the benefit of doubt
		CreateTimer(0.5,Unbreakable_Delayed_SetLow,iCid);
	}
}

//these timer functions apply health bonuses
//after a delay, hopefully to avoid bugs
public Action:Unbreakable_Delayed_Max (Handle:timer, any:iCid)
{
	SetEntProp(iCid,Prop_Data,"m_iHealth", 100+g_iUnbreak_hp );
}

public Action:Unbreakable_Delayed_Normal (Handle:timer, any:iCid)
{
	SetEntProp(iCid,Prop_Data,"m_iHealth", GetEntProp(iCid,Prop_Data,"m_iHealth")+g_iUnbreak_hp );
}

public Action:Unbreakable_Delayed_Heal (Handle:timer, any:iCid)
{
	SetEntProp(iCid,Prop_Data,"m_iHealth", GetEntProp(iCid,Prop_Data,"m_iHealth") + (g_iUnbreak_hp*8/10) );
}

public Action:Unbreakable_Delayed_Rescue (Handle:timer, any:iCid)
{
	SetEntProp(iCid,Prop_Data,"m_iHealth", GetEntProp(iCid,Prop_Data,"m_iHealth") + (g_iUnbreak_hp/2) );
}

public Action:Unbreakable_Delayed_SetHigh (Handle:timer, any:iCid)
{
	SetEntProp(iCid,Prop_Data,"m_iHealth", 200 );
}

public Action:Unbreakable_Delayed_SetLow (Handle:timer, any:iCid)
{
	SetEntProp(iCid,Prop_Data,"m_iHealth", 100 );
}

//=============================
// Sur1: Unbreakable,
// Sur1: Spirit,
// Sur1: Double Tap,
// Sur2: Martial Artist,
// Inf1: Blind Luck
//=============================

//called when survivor spawns from closet
public Event_PlayerRescued (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"victim"));
	if (iCid==0 || g_iConfirm[iCid]==0)
		return;

	//reset vars related to spirit perk
	g_iPState[iCid]=0;
	g_iPIncap[iCid]=0;
	g_iSpiritCooldown[iCid]=0;
	//reset var related to blind luck perk
	SetEntProp(iCid, Prop_Send, "m_iHideHUD", 0);
	//rebuilds double tap registry
	CreateTimer(0.3,Delayed_Rebuild,0);

	//checks for unbreakable health bonus
	if (g_iSur1[iCid]==5)
	{
		//check if perk is enabled
		if (g_iSur1_enable==0
			|| g_iUnbreak_enable==0			&&	g_iL4D_GameMode==0
			|| g_iUnbreak_enable_sur==0		&&	g_iL4D_GameMode==1
			|| g_iUnbreak_enable_vs==0		&&	g_iL4D_GameMode==2)
			return;

		CreateTimer(0.5,Unbreakable_Delayed_Rescue,iCid);
		PrintHintText(iCid,"Unbreakable: bonus health!");

		//run a check to see if for whatever reason
		//the player's health is above 200
		//since 200 is the clamped maximum for unbreakable
		//in which case we set their health to 200
		if (GetEntProp(iCid,Prop_Data,"m_iHealth") > 200)
			CreateTimer(0.5,Unbreakable_Delayed_SetHigh,iCid);
	}
}



//=============================
// Sur1: Double Tap
//=============================

//called on round starts and on convar changes
//does the checks to determine whether DT
//should be run every game frame
DT_RunChecks ()
{
	if (g_iSur1_enable==1
		&& (g_iDT_enable==1		&&	g_iL4D_GameMode==0
		|| g_iDT_enable_sur==1	&&	g_iL4D_GameMode==1
		|| g_iDT_enable_vs==1	&&	g_iL4D_GameMode==2))
		g_iDT_meta_enable=1;
	else
		g_iDT_meta_enable=0;
}

//called on confirming perks
//simply adds player to registry of DT users
Event_Confirm_DT (iCid)
{
	if (g_iDTRegisterCount<0)
		g_iDTRegisterCount=0;
	if (IsClientInGame(iCid)==true
		&& IsPlayerAlive(iCid)==true
		&& g_iSur1[iCid]==4
		&& g_iConfirm[iCid]==1
		&& GetClientTeam(iCid)==2)
	{
		g_iDTRegisterCount++;
		g_iDTRegisterIndex[g_iDTRegisterCount]=iCid;

		//----DEBUG----
		//PrintToChatAll("\x03double tap on confirm, registering \x01%i",iCid);
	}	
}

//called whenever the registry needs to be rebuilt
//to cull any players who have left or died, etc.
//(called on: player death, player disconnect,
//closet rescue, change teams)
DT_Rebuild ()
{
	//clears all DT-related vars
	DT_Clear();

	//if the server's not running or
	//is in the middle of loading, stop
	if (IsServerProcessing()==false)
		return;

	//----DEBUG----
	//PrintToChatAll("\x03double tap rebuilding registry");

	for (new iI=1 ; iI<=MaxClients ; iI++)
	{
		if (IsClientInGame(iI)==true
			&& IsPlayerAlive(iI)==true
			&& g_iSur1[iI]==4
			&& g_iConfirm[iI]==1
			&& GetClientTeam(iI)==2)
		{
			g_iDTRegisterCount++;
			g_iDTRegisterIndex[g_iDTRegisterCount]=iI;

			//----DEBUG----
			//PrintToChatAll("\x03-registering \x01%i",iI);
		}
	}
}

//called to clear out DT registry
//(called on: round start, round end, map end)
DT_Clear ()
{
	g_iDTRegisterCount=0;
	for (new iI=1 ; iI<=MaxClients ; iI++)
	{
		g_iDTRegisterIndex[iI]= -1;
		g_iDTEntid[iI] = -1;
		g_flDTNextTime[iI]= -1.0;
	}
}

//this is the big momma!
//since this is called EVERY game frame,
//we need to be careful not to run too many functions
//kinda hard, though, considering how many things
//we have to check for =.=
public OnGameFrame()
{
	//if frames aren't being processed,
	//don't bother - otherwise we get LAG
	//or even disconnects on map changes, etc...
	//or if no one has DT, don't bother either
	if (IsServerProcessing()==false)
		return;
	if (g_iDTRegisterCount==0)
		return;

	//stop if perk is disabled
	if (g_iDT_meta_enable==0)
		return;

	//this tracks the player's id, just to
	//make life less painful...
	decl iCid;
	//this tracks the player's gun id
	//since we adjust numbers on the gun,
	//not the player
	decl iEntid;
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
	for (new iI=1; iI<=g_iDTRegisterCount; iI++)
	{
		//PRE-CHECKS: RETRIEVE VARS
		//-------------------------

		iCid = g_iDTRegisterIndex[iI];
		//stop on this client
		//when the next client id is null
		if (iCid <= 0) return;
		//skip this client if they're disabled
		if (g_iPState[iCid]==1) continue;

		//we have to adjust numbers on the gun, not the player
		//so we get the active weapon id here
		iEntid = GetEntDataEnt2(iCid,g_iActiveWO);
		//if the retrieved gun id is -1, then...
		//wtf mate? just move on
		if (iEntid == -1) continue;
		//and here is the retrieved next attack time
		flNextTime_ret = GetEntDataFloat(iEntid,g_iNextPAttO);
		//and for retrieved next melee time
		flNextTime2_ret = GetEntDataFloat(iEntid,g_iNextSAttO);

		//----DEBUG----
		/*
		new iNextAttO=	FindSendPropInfo("CTerrorPlayer","m_flNextAttack");
		new iIdleTimeO=	FindSendPropInfo("CTerrorGun","m_flTimeWeaponIdle");
		PrintToChatAll("\x03DT, NextAttack \x01%i %f\x03, TimeIdle \x01%i %f",
			iNextAttO,
			GetEntDataFloat(iCid,iNextAttO),
			iIdleTimeO,
			GetEntDataFloat(iEntid,iIdleTimeO)
			);
		*/


		//CHECK 1: BEFORE ADJUSTED SHOT IS MADE
		//------------------------------------
		//since this will probably be the case most of
		//the time, we run this first
		//checks: gun is unchanged; time of shot has not passed
		//actions: nothing
		if (g_iDTEntid[iCid]==iEntid
			&& g_flDTNextTime[iCid]>=flNextTime_ret)
		{
			//----DEBUG----
			//PrintToChatAll("\x03DT client \x01%i\x03; before shot made",iCid );

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
			//PrintToChatAll("\x03DT client \x01%i\x03; melee attack inferred",iCid );

			continue;
		}


		//CHECK 3: AFTER ADJUSTED SHOT IS MADE
		//------------------------------------
		//at this point, either a gun was swapped, or
		//the attack time needs to be adjusted
		//checks: stored gun id same as retrieved gun id,
		// and retrieved next attack time is after stored value
		if (g_iDTEntid[iCid]==iEntid
			&& g_flDTNextTime[iCid] < flNextTime_ret)
		{
			//----DEBUG----
			//PrintToChatAll("\x03DT after adjusted shot\n-pre, client \x01%i\x03; entid \x01%i\x03; enginetime\x01 %f\x03; NextTime_orig \x01 %f\x03; interval \x01%f",iCid,iEntid,flGameTime,flNextTime_ret, flNextTime_ret-flGameTime );

			//this is a calculation of when the next primary attack
			//will be after applying double tap values
			flNextTime_calc = ( flNextTime_ret - flGameTime ) * g_flDT_rate + flGameTime;

			//then we store the value
			g_flDTNextTime[iCid] = flNextTime_calc;

			//and finally adjust the value in the gun
			SetEntDataFloat(iEntid, g_iNextPAttO, flNextTime_calc, true);

			//----DEBUG----
			//PrintToChatAll("\x03-post, NextTime_calc \x01 %f\x03; new interval \x01%f",GetEntDataFloat(iEntid,g_iNextPAttO), GetEntDataFloat(iEntid,g_iNextPAttO)-flGameTime );

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
		if (g_iDTEntid[iCid] != iEntid)
		{
			//----DEBUG----
			//PrintToChatAll("\x03DT client \x01%i\x03; weapon switch inferred",iCid );

			//now we update the stored vars
			g_iDTEntid[iCid]=iEntid;
			g_flDTNextTime[iCid]=flNextTime_ret;
			continue;
		}

		//----DEBUG----
		//PrintToChatAll("\x03DT client \x01%i\x03; reached end of checklist...",iCid );
	}
}



//=============================
// Sur1: Sleight of Hand
//=============================

//on the start of a reload
public Event_Reload (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iCid==0)
		return;

	//check if perk is disabled
	if (g_iSur1_enable==0
		|| g_iSoH_enable==0		&&	g_iL4D_GameMode==0
		|| g_iSoH_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iSoH_enable_vs==0	&&	g_iL4D_GameMode==2)
		return;

	if (g_iSur1[iCid]==6
		&& g_iConfirm[iCid]==1
		&& GetClientTeam(iCid)==2)
	{
		//----DEBUG----
		//PrintToChatAll("\x03SoH client \x01%i\x03; start of reload detected",iCid );

		new iEntid = GetEntDataEnt2(iCid,g_iActiveWO);
		if (IsValidEntity(iEntid)==false) return;

		decl String:stClass[32];
		GetEntityNetClass(iEntid,stClass,32);

		//----DEBUG----
		//PrintToChatAll("\x03-class of gun: \x01%s",stClass );

		//for non-shotguns
		if (StrContains(stClass,"shotgun",false) == -1)
		{
			SoH_MagStart(iEntid,iCid);
			return;
		}

		//shotguns are a bit trickier since the game
		//tracks per shell inserted - and there's TWO
		//different shotguns with different values =.=
		else if (StrContains(stClass,"autoshotgun",false) != -1)
		{
			CreateTimer(0.1,SoH_AutoshotgunStart,iEntid);
			return;
		}

		else if (StrContains(stClass,"pumpshotgun",false) != -1)
		{
			CreateTimer(0.1,SoH_PumpshotgunStart,iEntid);
			return;
		}
	}
}

//called for mag loaders
SoH_MagStart (iEntid, iCid)
{
	//----DEBUG----
	//PrintToChatAll("\x03-magazine loader detected");

	new Float:flGameTime = GetGameTime();
	new Float:flNextTime_ret = GetEntDataFloat(iEntid,g_iNextPAttO);

	//----DEBUG----
	/*PrintToChatAll("\x03- pre, gametime \x01%f\x03, retrieved nextattack\x01 %i %f\x03, retrieved time idle \x01%i %f",
		flGameTime,
		g_iNextAttO,
		GetEntDataFloat(iCid,g_iNextAttO),
		g_iTimeIdleO,
		GetEntDataFloat(iEntid,g_iTimeIdleO)
		);*/

	//this is a calculation of when the next primary attack
	//will be after applying sleight of hand values
	//NOTE: at this point, only calculate the interval itself,
	//without the actual game engine time factored in
	new Float:flNextTime_calc = ( flNextTime_ret - flGameTime ) * g_flSoH_rate ;

	//we change the playback rate of the gun
	//just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/g_flSoH_rate, true);

	//create a timer to reset the playrate after
	//time equal to the modified attack interval
	CreateTimer( flNextTime_calc, SoH_MagEnd, iEntid);

	//and finally we set the end reload time into the gun
	//so the player can actually shoot with it at the end
	flNextTime_calc += flGameTime;
	SetEntDataFloat(iEntid, g_iTimeIdleO, flNextTime_calc, true);
	SetEntDataFloat(iEntid, g_iNextPAttO, flNextTime_calc, true);
	SetEntDataFloat(iCid, g_iNextAttO, flNextTime_calc, true);

	//----DEBUG----
	/*PrintToChatAll("\x03- post, calculated nextattack \x01%f\x03, gametime \x01%f\x03, retrieved nextattack\x01 %i %f\x03, retrieved time idle \x01%i %f",
		flNextTime_calc,
		flGameTime,
		g_iNextAttO,
		GetEntDataFloat(iCid,g_iNextAttO),
		g_iTimeIdleO,
		GetEntDataFloat(iEntid,g_iTimeIdleO)
		);*/
}

//called for autoshotguns
public Action:SoH_AutoshotgunStart (Handle:timer, any:iEntid)
{
	//----DEBUG----
	/*PrintToChatAll("\x03-autoshotgun detected, iEntid \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i",
		iEntid,
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
	SetEntDataFloat(iEntid,	g_iShotStartDurO,	g_flSoHAutoS*g_flSoH_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotInsertDurO,	g_flSoHAutoI*g_flSoH_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotEndDurO,		g_flSoHAutoE*g_flSoH_rate,	true);

	//we change the playback rate of the gun
	//just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/g_flSoH_rate, true);

	//and then call a timer to periodically check whether the
	//gun is still reloading or not to reset the animation
	//but first check the reload state; if it's 2, then it
	//needs a pump/cock before it can shoot again, and thus
	//needs more time
	if (GetEntData(iEntid,g_iShotRelStateO)==2)
		CreateTimer(0.3,SoH_ShotgunEndCock,iEntid,TIMER_REPEAT);
	else
		CreateTimer(0.3,SoH_ShotgunEnd,iEntid,TIMER_REPEAT);

	//----DEBUG----
	/*PrintToChatAll("\x03- after mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_flSoHAutoS,
		g_flSoHAutoI,
		g_flSoHAutoE
		);*/

	return Plugin_Continue;
}

//called for pump shotguns
public Action:SoH_PumpshotgunStart (Handle:timer, any:iEntid)
{
	//----DEBUG----
	/*PrintToChatAll("\x03-pumpshotgun detected, iEntid \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i",
		iEntid,
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
	SetEntDataFloat(iEntid,	g_iShotStartDurO,	g_flSoHPumpS*g_flSoH_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotInsertDurO,	g_flSoHPumpI*g_flSoH_rate,	true);
	SetEntDataFloat(iEntid,	g_iShotEndDurO,		g_flSoHPumpE*g_flSoH_rate,	true);

	//we change the playback rate of the gun
	//just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/g_flSoH_rate, true);

	//and then call a timer to periodically check whether the
	//gun is still reloading or not to reset the animation
	if (GetEntData(iEntid,g_iShotRelStateO)==2)
		CreateTimer(0.3,SoH_ShotgunEndCock,iEntid,TIMER_REPEAT);
	else
		CreateTimer(0.3,SoH_ShotgunEnd,iEntid,TIMER_REPEAT);

	//----DEBUG----
	/*PrintToChatAll("\x03- after mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_flSoHPumpS,
		g_flSoHPumpI,
		g_flSoHPumpE
		);*/

	return Plugin_Continue;
}

//this resets the playback rate on non-shotguns
public Action:SoH_MagEnd (Handle:timer, any:iEntid)
{
	//----DEBUG----
	//PrintToChatAll("\x03SoH reset playback, magazine loader");

	if (iEntid <= 0
		|| IsValidEntity(iEntid)==false)
		return Plugin_Stop;

	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0, true);

	return Plugin_Stop;
}

//this resets the playback rate on shotguns
public Action:SoH_ShotgunEnd (Handle:timer, any:iEntid)
{
	//----DEBUG----
	//PrintToChatAll("\x03-autoshotgun tick");

	if (iEntid <= 0
		|| IsValidEntity(iEntid)==false)
		return Plugin_Stop;

	if (GetEntData(iEntid,g_iShotRelStateO)==0)
	{
		//----DEBUG----
		//PrintToChatAll("\x03-shotgun end reload detected");

		SetEntDataFloat(iEntid, g_iPlayRateO, 1.0, true);

		new iCid=GetEntPropEnt(iEntid,Prop_Data,"m_hOwner");
		new Float:flTime=GetGameTime()+0.2;
		SetEntDataFloat(iCid,	g_iNextAttO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iTimeIdleO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iNextPAttO,	flTime,	true);

		return Plugin_Stop;
	}
	return Plugin_Continue;
}

//since cocking requires more time, this function does
//exactly as the above, except it adds slightly more time
public Action:SoH_ShotgunEndCock (Handle:timer, any:iEntid)
{
	//----DEBUG----
	//PrintToChatAll("\x03-autoshotgun tick");

	if (iEntid <= 0
		|| IsValidEntity(iEntid)==false)
		return Plugin_Stop;

	if (GetEntData(iEntid,g_iShotRelStateO)==0)
	{
		//----DEBUG----
		//PrintToChatAll("\x03-shotgun end reload + cock detected");

		SetEntDataFloat(iEntid, g_iPlayRateO, 1.0, true);

		new iCid=GetEntPropEnt(iEntid,Prop_Data,"m_hOwner");
		new Float:flTime= GetGameTime() + 1.0;
		SetEntDataFloat(iCid,	g_iNextAttO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iTimeIdleO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iNextPAttO,	flTime,	true);

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
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iCid==0) return;
	if (g_iConfirm[iCid]==0)
		return;

	//check for grenadier perk
	if (g_iSur1[iCid]==2
		&& g_iSur1_enable==1
		&& (g_iPyro_enable==1		&&	g_iL4D_GameMode==0
		|| g_iPyro_enable_sur==1	&&	g_iL4D_GameMode==1
		|| g_iPyro_enable_vs==1		&&	g_iL4D_GameMode==2))
	{
		switch (g_iGrenThrow[iCid])
		{
		//only bother with checks if they aren't throwing
		case 0:
			{
				new String:st_wpn[24];
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
					if (g_iGren[iCid]==0
						|| g_iGren[iCid]==2)
					{
						g_iGren[iCid]=2;
						PrintHintText(iCid,"Grenadier: You are carrying %i %s(s)",g_iGren[iCid],st_wpn);
					}
					//otherwise, only give them one and tell them to
					//throw the grenade before picking up another one;
					//this is to prevent abuses with throwing infinite nades
					else
					{
						g_iGren[iCid]=1;
						PrintHintText(iCid,"You only picked up one %s! Throw your second grenade before picking up another.",st_wpn);
					}
				}
			}
		//if they are in the middle of throwing, then reset the var
		case 1:
			g_iGrenThrow[iCid]=0;
		}
	}

	//then check for pack rat perk separately
	if (g_iSur2[iCid]==3)
	{
		//check if perk is enabled
		if (g_iSur2_enable==0
			|| g_iPack_enable==0			&&	g_iL4D_GameMode==0
			|| g_iPack_enable_sur==0	&&	g_iL4D_GameMode==1
			|| g_iPack_enable_vs==0		&&	g_iL4D_GameMode==2)
			return;

		new String:st_wpn[24];
		GetEventString(event,"item",st_wpn,24);

		//only give ammo to owned gun, to prevent abuses

		if (StrEqual(st_wpn,"smg",false))
		{
			new iAmmoO=FindDataMapOffs(iCid,"m_iAmmo");
			//smg ammo +160, m_iAmmo offset +20
			SetEntData(iCid, iAmmoO	+20, GetEntData(iCid,iAmmoO	+20)	+g_iPR_smg);
			return ;
		}

		else if (StrEqual(st_wpn,"pumpshotgun",false)
			|| StrEqual(st_wpn,"autoshotgun",false))
		{
			new iAmmoO=FindDataMapOffs(iCid,"m_iAmmo");
			//pump,autoshotgun ammo +32, m_iAmmo offset +24
			SetEntData(iCid,iAmmoO	+24,GetEntData(iCid,iAmmoO	+24)	+g_iPR_shotgun);
			return ;
		}

		else if (StrEqual(st_wpn,"rifle",false))
		{
			new iAmmoO=FindDataMapOffs(iCid,"m_iAmmo");
			//rifle ammo +120, m_iAmmo offset +12
			SetEntData(iCid, iAmmoO	+12, GetEntData(iCid,iAmmoO	+12)	+g_iPR_rifle);
			return ;
		}

		else if (StrEqual(st_wpn,"hunting_rifle",false))
		{
			new iAmmoO=FindDataMapOffs(iCid,"m_iAmmo");
			//hunting rifle ammo +50, m_iAmmo offset +8
			SetEntData(iCid, iAmmoO	+8, GetEntData(iCid,iAmmoO	+8)		+g_iPR_sniper);
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
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iCid==0)
		return;

	//check if perk is enabled
	if (g_iSur1_enable==0
		|| g_iPyro_enable==0		&&	g_iL4D_GameMode==0
		|| g_iPyro_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iPyro_enable_vs==0		&&	g_iL4D_GameMode==2)
		return;

	if (g_iConfirm[iCid]==0) return;
	new String:st_wpn[24];
	GetEventString(event,"weapon",st_wpn,24);
	new bool:b_pipe=StrEqual(st_wpn,"pipe_bomb",false);
	new bool:b_mol=StrEqual(st_wpn,"molotov",false);
	if (g_iSur1[iCid]==2
		&& (b_pipe || b_mol))
	{
		g_iGren[iCid]--;		//reduce count by 1
		if (g_iGren[iCid]>0)		//do they still have grenades left?
		{
			if (b_pipe==true)
			{
				g_iGrenType[iCid]=1;
				st_wpn="pipe bomb";
			}
			else
			{
				g_iGrenType[iCid]=2;
			}
			PrintHintText(iCid,"Grenadier: You have %i %s(s) left",g_iGren[iCid],st_wpn);
			CreateTimer(2.5,Grenadier_DelayedGive,iCid);
		}
	}
}

//gives the grenade a few seconds later 
//(L4D takes a while to remove the grenade from inventory after it's been thrown)
public Action:Grenadier_DelayedGive (Handle:timer,any:iCid)
{
	if (iCid==0
		|| g_iConfirm[iCid]==0
		|| g_iSur1[iCid]!=2)
		return Plugin_Continue;

	new iflags=GetCommandFlags("give");
	new String:st_give[24];
	if (g_iGrenType[iCid]==1) st_give="give pipe_bomb";
	else st_give="give molotov";
	g_iGrenType[iCid]=0;
	g_iGrenThrow[iCid]=1;	//client now considered to be "in the middle of throwing"
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(iCid,st_give);
	SetCommandFlags("give", iflags);
	return Plugin_Continue;
}

//called on roundstarts or on confirming perks
//gives a random grenade to the player
Event_Confirm_Grenadier (iCid)
{
	if (iCid==0
		|| GetClientTeam(iCid)!=2
		|| IsPlayerAlive(iCid)==false
		|| g_iConfirm[iCid]==0
		|| g_iSur1[iCid]!=2)
		return;

	//check if perk is enabled
	if (g_iSur1_enable==0
		|| g_iPyro_enable==0		&&	g_iL4D_GameMode==0
		|| g_iPyro_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iPyro_enable_vs==0		&&	g_iL4D_GameMode==2)
		return;

	new iflags=GetCommandFlags("give");
	new String:st_give[24];
	if (GetRandomInt(1,2)==1) st_give="give pipe_bomb";
	else st_give="give molotov";
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(iCid,st_give);
	SetCommandFlags("give", iflags);
	return;
}



//=============================
// Sur2: Chem Reliant
//=============================

public Action:Event_PillsUsed (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"subject"));
	if (iCid==0) return Plugin_Continue;

	//check if perk is enabled
	if (g_iSur2_enable==0
		|| g_iChem_enable==0			&&	g_iL4D_GameMode==0
		|| g_iChem_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iChem_enable_vs==0		&&	g_iL4D_GameMode==2)
		return Plugin_Continue;

	//----DEBUG----
	//PrintToChatAll("\x03Pill user: \x01%i", iCid);

	if (g_iSur2[iCid]==1
		&& g_iConfirm[iCid]==1)
	{
		new Float:flBuff=GetEntDataFloat(iCid,g_iHPBuffO);
		new iHP=GetEntProp(iCid,Prop_Data,"m_iHealth");
		
		//so we need to test the maxbound for
		//how much health buffer we can give
		//which can vary depending on whether
		//they have unbreakable or not

		//CASE 1: HAS UNBREAKABLE
		if (g_iSur1[iCid]==5
			&& g_iSur1_enable==1
			&& (g_iUnbreak_enable==1	&&	g_iL4D_GameMode==0
			|| g_iUnbreak_enable_sur==1	&&	g_iL4D_GameMode==1
			|| g_iUnbreak_enable_vs==1	&&	g_iL4D_GameMode==2))
		{
			//CASE 1A:
			//combined health + chem reliant < max health possible
			if (flBuff + iHP + g_iChem_buff < 100 + g_iUnbreak_hp)
				//this is the easiest, just give them chem reliant bonus
				SetEntDataFloat(iCid,g_iHPBuffO, flBuff+g_iChem_buff ,true);

			//CASE 1B:
			//combined health + chem reliant > max health possible
			else
				//this is a bit trickier, give them the difference
				//between the max health possible and their current health
				SetEntDataFloat(iCid,g_iHPBuffO, (100.0+g_iUnbreak_hp)-iHP ,true);
		}
		//CASE 2: DOES NOT HAVE UNBREAKABLE
		else
		{
			//CASE 1A:
			//combined health + chem reliant < max health possible
			if (flBuff + iHP + g_iChem_buff < 100)
				//this is the easiest, just give them chem reliant bonus
				SetEntDataFloat(iCid,g_iHPBuffO, flBuff+g_iChem_buff ,true);

			//CASE 1B:
			//combined health + chem reliant > max health possible
			else
				//this is a bit trickier, give them the difference
				//between the max health possible and their current health
				SetEntDataFloat(iCid,g_iHPBuffO, 100.0-iHP ,true);
		}
	}
	return Plugin_Continue;
}

//called on roundstart or on confirming perks,
//gives pills off the start
Event_Confirm_ChemReliant (iCid)
{
	if (iCid==0
		|| GetClientTeam(iCid)!=2
		|| IsPlayerAlive(iCid)==false
		|| g_iConfirm[iCid]==0
		|| g_iSur2[iCid]!=1)
		return;

	//check if perk is enabled
	if (g_iSur2_enable==0
		|| g_iChem_enable==0			&&	g_iL4D_GameMode==0
		|| g_iChem_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iChem_enable_vs==0		&&	g_iL4D_GameMode==2)
		return;

	new iflags=GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(iCid,"give pain_pills");
	SetCommandFlags("give", iflags);

	return;
}



//=============================
// Sur2: Helping Hand
//=============================

//fired before reviving begins,reduces revive time
public Action:Event_ReviveBeginPre (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));

	if (iCid==0) return Plugin_Continue;

	//check if cvar changes are allowed
	//for this perk; if not, then stop
	if (g_iHelpHand_convar==0)
		return Plugin_Continue;

	//check if perk is enabled
	if (g_iSur2_enable==0
		|| g_iHelpHand_enable==0			&&	g_iL4D_GameMode==0
		|| g_iHelpHand_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iHelpHand_enable_vs==0		&&	g_iL4D_GameMode==2)
		return Plugin_Continue;

	//----DEBUG----
	//PrintToChatAll("\x03revive begin detected, reviver: \x01%i\x03, subject: \x01%i",iCid,iSub);

	//check for helping hand
	if (g_iSur2[iCid]==2
		&& g_iConfirm[iCid]==1)
	{
		//----DEBUG----
		//PrintToChatAll("\x03-perk present, setting revive time to \x01%f",g_flReviveTime/2);

		SetConVarFloat(FindConVar("survivor_revive_duration"), g_flReviveTime * g_flHelpHand_timemult ,false,false);
		return Plugin_Continue;
	}

	//otherwise, reset the revive duration
	else
	{
		//----DEBUG----
		//PrintToChatAll("\x03-no perk, attempting to reset revive time to \x01%f",g_flReviveTime);

		SetConVarFloat(FindConVar("survivor_revive_duration"),g_flReviveTime,false,false);
		return Plugin_Continue;
	}
}

//=============================
// Sur2: Helping Hand,
// Sur1: Spirit,
// Sur1: Unbreakable
//=============================

//at end of revive, reset convars and give bonus temp hp
//also handles ledge hangs (for spirit perk)
public Event_ReviveSuccess (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	new iSub=GetClientOfUserId(GetEventInt(event,"subject"));

	if (iCid==0 || iSub==0) return;

	new iLedge=GetEventInt(event,"ledge_hang");

	//----DEBUG----
	//PrintToChatAll("\x03life giver success detected, reviver: \x01%i\x03, subject: \x01%i",iCid,iSub);

	//check for unbreakable for the subject
	//only fires if they were NOT hanging from a ledge
	if (g_iSur1[iSub]==5
		&& g_iConfirm[iSub]==1
		&& GetEventInt(event,"ledge_hang")==0)
	{
		//check if perk is enabled
		if (g_iSur1_enable==1
			&& (g_iUnbreak_enable==1	&&	g_iL4D_GameMode==0
			|| g_iUnbreak_enable_sur==1	&&	g_iL4D_GameMode==1
			|| g_iUnbreak_enable_vs==1	&&	g_iL4D_GameMode==2))
		{
			SetEntDataFloat(iSub,g_iHPBuffO, GetEntDataFloat(iSub,g_iHPBuffO)+(g_iUnbreak_hp*8/10) ,true);
			PrintHintText(iSub,"Unbreakable: Bonus health buffer!");
		}
	}

	//then check for helping hand
	if (g_iSur2[iCid]==2
		&& g_iConfirm[iCid]==1
		&& g_iSur2_enable==1
		&& (g_iHelpHand_enable==1		&&	g_iL4D_GameMode==0
		|| g_iHelpHand_enable_sur==1	&&	g_iL4D_GameMode==1
		|| g_iHelpHand_enable_vs==1		&&	g_iL4D_GameMode==2))
	{
		switch (iLedge)
		{
		case 1:
			{
				g_iPState[iSub]=0;

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

				new String:st_name[24];
				GetClientName(iSub,st_name,24);
				PrintHintText(iCid,"Helping Hand: gave bonus temporary health to %s!",st_name);
				GetClientName(iCid,st_name,24);
				PrintHintText(iSub,"Helping Hand: %s gave you bonus temporary health!",st_name);
			}
		}
	}

	//----DEBUG----
	//PrintToChatAll("\x03-revive end, attempting to reset revive time to \x01%f",g_flReviveTime);

	//only adjust the convar if
	//convar changes are allowed
	//for this perk
	if (g_iHelpHand_convar==1
		&& g_iSur2_enable==1
		&& (g_iHelpHand_enable==1		&&	g_iL4D_GameMode==0
		|| g_iHelpHand_enable_sur==1	&&	g_iL4D_GameMode==1
		|| g_iHelpHand_enable_vs==1		&&	g_iL4D_GameMode==2))
		SetConVarFloat(FindConVar("survivor_revive_duration"),g_flReviveTime,false,false);

	//for the spirit perk,
	//player is labelled as no longer incapped
	g_iPIncap[iSub]=0;

	//and then check if we need to continue allowing crawling
	//by running checks through everyone...
	//...but first, check if spirit convar changes are allowed
	if (g_iSur1_enable==1
		&& g_iSpirit_crawling==1
		&& (g_iSpirit_enable==1		&&	g_iL4D_GameMode==0
		|| g_iSpirit_enable_sur==1	&&	g_iL4D_GameMode==1
		|| g_iSpirit_enable_vs==1	&&	g_iL4D_GameMode==2))
	{
		new iCrawlClient=-1;
		for (new iI2=1 ; iI2<=MaxClients ; iI2++)
		{
			if (g_iConfirm[iI2]==0) continue;
			if (g_iSur1[iI2]==3
				&& g_iPIncap[iI2]!=0)
			{
				iCrawlClient=iI2;
				break;
			}
		}
		if (iCrawlClient>0)
			SetConVarInt(FindConVar("survivor_allow_crawling"),1,false,false);
		else
			SetConVarInt(FindConVar("survivor_allow_crawling"),0,false,false);
	}
}



//=============================
// Sur2: Pack Rat
//=============================

//calculates ammo capacity
PR_Calculate ()
{
	g_iPR_smg		=	RoundToNearest( GetConVarInt(FindConVar("ammo_smg_max")) * g_flPack_ammomult );
	g_iPR_shotgun	=	RoundToNearest( GetConVarInt(FindConVar("ammo_buckshot_max")) * g_flPack_ammomult );
	g_iPR_rifle		=	RoundToNearest( GetConVarInt(FindConVar("ammo_assaultrifle_max")) * g_flPack_ammomult );
	g_iPR_sniper	=	RoundToNearest( GetConVarInt(FindConVar("ammo_huntingrifle_max")) * g_flPack_ammomult );
}

//on ammo pickup, check if pack rat is in effect
public Event_AmmoPickup (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iCid==0)
		return;

	if (g_iSur2[iCid]==3
		&& g_iConfirm[iCid]==1
		&& g_iSur2_enable==1
		&& (g_iPack_enable==1			&&	g_iL4D_GameMode==0
			|| g_iPack_enable_sur==1	&&	g_iL4D_GameMode==1
			|| g_iPack_enable_vs==1		&&	g_iL4D_GameMode==2))
	{
		new iAmmoO=FindDataMapOffs(iCid,"m_iAmmo");
		//hunting rifle ammo +60, m_iAmmo offset +8
		SetEntData(iCid, iAmmoO	+8, 180 + g_iPR_sniper );
		//rifle ammo +120, m_iAmmo offset +12
		SetEntData(iCid, iAmmoO	+12, 360 + g_iPR_rifle );
		//smg ammo +160, m_iAmmo offset +20
		SetEntData(iCid, iAmmoO	+20, 480 + g_iPR_smg );
		//pump,autoshotgun ammo +32, m_iAmmo offset +24
		SetEntData(iCid, iAmmoO	+24, 128 + g_iPR_shotgun );
	}
}

//called on confirming perks, show hint to pick up ammo now
public Event_Confirm_PackRat (iCid)
{
	if (iCid==0)
		return;

	//check if perk is enabled
	if (g_iSur2_enable==0
		|| g_iPack_enable==0		&&	g_iL4D_GameMode==0
		|| g_iPack_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iPack_enable_vs==0		&&	g_iL4D_GameMode==2)
		return;

	if (g_iConfirm[iCid]==1
		&& GetClientTeam(iCid)==2)
	{
		if (g_iSur2[iCid]==3)
		{
			new iAmmoO=FindDataMapOffs(iCid,"m_iAmmo");
			decl iAmmoCount;
			//hunting rifle ammo +60, m_iAmmo offset +8
			iAmmoCount=GetEntData(iCid,iAmmoO	+8);
			if (iAmmoCount<180)
				SetEntData(iCid, iAmmoO	+8, iAmmoCount + g_iPR_sniper );
			else
				SetEntData(iCid, iAmmoO +8, 180 + g_iPR_sniper );
			//rifle ammo +120, m_iAmmo offset +12
			iAmmoCount=GetEntData(iCid,iAmmoO	+12);
			if (iAmmoCount<360)
				SetEntData(iCid, iAmmoO	+12, iAmmoCount + g_iPR_rifle );
			else
				SetEntData(iCid, iAmmoO +12, 360 + g_iPR_rifle );
			//smg ammo +160, m_iAmmo offset +20
			iAmmoCount=GetEntData(iCid,iAmmoO	+20);
			if (iAmmoCount<480)
				SetEntData(iCid, iAmmoO	+20, iAmmoCount + g_iPR_smg );
			else
				SetEntData(iCid, iAmmoO +20, 480 + g_iPR_smg );
			//pump,autoshotgun ammo +32, m_iAmmo offset +24
			iAmmoCount=GetEntData(iCid,iAmmoO	+24);
			if (iAmmoCount<128)
				SetEntData(iCid, iAmmoO	+24, iAmmoCount + g_iPR_shotgun );
			else
				SetEntData(iCid, iAmmoO +24, 128 + g_iPR_shotgun );
		}
		//if the perk changed, check for ammo count of each gun
		//if it's higher than default max, reduce to default max
		else
		{
			new iAmmoO=FindDataMapOffs(iCid,"m_iAmmo");
			decl iAmmoCount;

			//check hunting rifle ammo, m_iAmmo offset +8
			iAmmoCount=GetEntData(iCid,iAmmoO	+8);
			if (iAmmoCount>180) SetEntData(iCid, iAmmoO	+8, 180);
			//check rifle ammo, m_iAmmo offset +12
			iAmmoCount=GetEntData(iCid,iAmmoO	+12);
			if (iAmmoCount>360) SetEntData(iCid, iAmmoO	+12, 360);
			//check smg ammo, m_iAmmo offset +20
			iAmmoCount=GetEntData(iCid,iAmmoO	+20);
			if (iAmmoCount>480) SetEntData(iCid, iAmmoO	+20, 480);
			//check shotgun ammo, m_iAmmo offset +24
			iAmmoCount=GetEntData(iCid,iAmmoO	+24);
			if (iAmmoCount>128) SetEntData(iCid, iAmmoO	+24, 128);
		}
	}
}

//called when player tries to pick up ammo,
//and has more than default max but less than perk max
public Event_PlayerUse (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iCid==0)
		return;

	//check if perk is enabled
	if (g_iSur2_enable==0
		|| g_iPack_enable==0			&&	g_iL4D_GameMode==0
		|| g_iPack_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iPack_enable_vs==0		&&	g_iL4D_GameMode==2)
		return;

	new iEntid=GetEventInt(event,"targetid");
	new String:st_entname[32];
	GetEdictClassname(iEntid,st_entname,32);

	//----DEBUG----
	/*
	PrintToChatAll("iEntid = %i",iEntid);
	PrintToChatAll("edict classname = %s",st_entname);
	*/

	//for any of the following code to work,
	//the player MUST have the pack rat perk
	//and have confirmed their perks
	if (g_iSur2[iCid]==3
		&& g_iConfirm[iCid]==1)
	{

		//if it's an ammo dump, check through all weapon ammo
		if (StrEqual(st_entname,"weapon_ammo_spawn")==true)
		{
			new iAmmoO=FindDataMapOffs(iCid,"m_iAmmo");
			decl iAmmoCount;
			decl iNewAmmoCount;

			//check hunting rifle ammo, m_iAmmo offset +8
			iAmmoCount=		GetEntData(iCid,iAmmoO	+8);
			iNewAmmoCount=	180 + g_iPR_sniper;
			if (iAmmoCount>=180 && iAmmoCount < iNewAmmoCount )
				SetEntData(iCid, iAmmoO	+8, iNewAmmoCount );

			//check rifle ammo, m_iAmmo offset +12
			iAmmoCount=		GetEntData(iCid,iAmmoO	+12);
			iNewAmmoCount=	360 + g_iPR_rifle;
			if (iAmmoCount>=360 && iAmmoCount < iNewAmmoCount )
				SetEntData(iCid, iAmmoO	+12, iNewAmmoCount );

			//check smg ammo, m_iAmmo offset +20
			iAmmoCount=		GetEntData(iCid,iAmmoO	+20);
			iNewAmmoCount=	480 + g_iPR_smg;
			if (iAmmoCount>=480 && iAmmoCount < iNewAmmoCount )
				SetEntData(iCid, iAmmoO	+20, iNewAmmoCount );

			//check shotgun ammo, m_iAmmo offset +24
			iAmmoCount=		GetEntData(iCid,iAmmoO	+24);
			iNewAmmoCount=	128 + g_iPR_shotgun;
			if (iAmmoCount>=128 && iAmmoCount< iNewAmmoCount )
				SetEntData(iCid, iAmmoO	+24, iNewAmmoCount );

		}

		//otherwise, if it's a weapon spawn...

		//check if smg needs more ammo
		else if (StrEqual(st_entname,"weapon_smg_spawn")==true)
		{
			new iAmmoO=FindDataMapOffs(iCid,"m_iAmmo");
			//check smg ammo, m_iAmmo offset +20
			new iAmmoCount=		GetEntData(iCid,iAmmoO	+20);
			new iNewAmmoCount=	480 + g_iPR_smg;
			if (iAmmoCount>=480 && iAmmoCount < iNewAmmoCount )
				SetEntData(iCid, iAmmoO	+20, iNewAmmoCount );
		}

		//check if rifle needs more ammo
		else if (StrEqual(st_entname,"weapon_rifle_spawn")==true)
		{
			new iAmmoO=FindDataMapOffs(iCid,"m_iAmmo");
			//check rifle ammo, m_iAmmo offset +12
			new iAmmoCount=		GetEntData(iCid,iAmmoO	+12);
			new iNewAmmoCount=	360 + g_iPR_rifle;
			if (iAmmoCount>=360 && iAmmoCount < iNewAmmoCount )
				SetEntData(iCid, iAmmoO	+12, iNewAmmoCount );
		}

		//check if hunting rifle needs more ammo
		else if (StrEqual(st_entname,"weapon_hunting_rifle_spawn")==true)
		{
			new iAmmoO=FindDataMapOffs(iCid,"m_iAmmo");
			//check hunting rifle ammo, m_iAmmo offset +8
			new iAmmoCount=		GetEntData(iCid,iAmmoO	+8);
			new iNewAmmoCount=	180 + g_iPR_sniper;
			if (iAmmoCount>=180 && iAmmoCount < iNewAmmoCount )
				SetEntData(iCid, iAmmoO	+8, iNewAmmoCount );
		}

		//check if shotgun types need more ammo
		else if (StrEqual(st_entname,"weapon_pumpshotgun_spawn")==true
			|| StrEqual(st_entname,"weapon_autoshotgun_spawn")==true)
		{
			new iAmmoO=FindDataMapOffs(iCid,"m_iAmmo");
			//check shotgun ammo, m_iAmmo offset +24
			new iAmmoCount=		GetEntData(iCid,iAmmoO	+24);
			new iNewAmmoCount=	128 + g_iPR_shotgun;
			if (iAmmoCount>=128 && iAmmoCount < iNewAmmoCount )
				SetEntData(iCid, iAmmoO	+24, iNewAmmoCount );
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
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iCid==0
		|| g_iConfirm[iCid]==0
		|| GetClientTeam(iCid)!=2)
		return;

	if (g_iSur2_enable==0
		|| g_iHard_enable==0		&&	g_iL4D_GameMode==0
		|| g_iHard_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iHard_enable_vs==0		&&	g_iL4D_GameMode==2)
		return;

	if (g_iSur2[iCid]==5)
	{
		new iHP=GetEntProp(iCid,Prop_Data,"m_iHealth");

		//----DEBUG----
		//PrintToChatAll("\x03hard to kill fire, client \x01%i\x03, health \x01%i",iCid,iHP);

		SetEntProp(iCid,Prop_Data,"m_iHealth", iHP + RoundToNearest(iHP*g_flHard_hpmult) );
		//SetEntDataFloat(iCid,g_iHPBuffO, flHPBuff+300 ,true);

		//----DEBUG----
		//PrintToChatAll("\x03-postfire values, health \x01%i",GetEntProp(iCid,Prop_Data,"m_iHealth"));
	}
}


//=============================
// Sur2: Martial Artist
//=============================

//called on confirming perks
//adds player to registry of MA users
//and sets movement speed
Event_Confirm_MA (iCid)
{
	if (g_iMARegisterCount<0)
		g_iMARegisterCount=0;

	//check if perk is enabled
	if (g_iSur2_enable==0
		|| g_iMA_enable==0		&&	g_iL4D_GameMode==0
		|| g_iMA_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iMA_enable_vs==0	&&	g_iL4D_GameMode==2)
		return;

	if (IsClientInGame(iCid)==true
		&& IsPlayerAlive(iCid)==true
		&& g_iSur2[iCid]==4
		&& g_iConfirm[iCid]==1
		&& GetClientTeam(iCid)==2)
	{
		g_iMARegisterCount++;
		g_iMARegisterIndex[g_iMARegisterCount]=iCid;

		decl Float:flSpeed;
		if (g_iL4D_GameMode==0)
			flSpeed=1.0*g_flMA_rate_coop;
		else
			flSpeed=1.0*g_flMA_rate;
		SetEntDataFloat(iCid,g_iLaggedMovementO, flSpeed ,true);

		//----DEBUG----
		//PrintToChatAll("\x03martial artist on confirm, registering \x01%i",iCid);
	}	
}

//called whenever the registry needs to be rebuilt
//to cull any players who have left or died, etc.
//resets survivor's speeds and reassigns speed boost
//(called on: player death, player disconnect,
//closet rescue, change teams, convar change)
MA_Rebuild ()
{
	//clears all DT-related vars
	MA_Clear();

	//if the server's not running or
	//is in the middle of loading, stop
	if (IsServerProcessing()==false)
		return;

	//check if perk is enabled
	if (g_iSur2_enable==0
		|| g_iMA_enable==0		&&	g_iL4D_GameMode==0
		|| g_iMA_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iMA_enable_vs==0	&&	g_iL4D_GameMode==2)
		return;

	//----DEBUG----
	//PrintToChatAll("\x03martial artist rebuilding registry");

	decl Float:flSpeed;
	for (new iI=1 ; iI<=MaxClients ; iI++)
	{
		if (IsClientInGame(iI)==true
			&& IsPlayerAlive(iI)==true
			&& g_iSur2[iI]==4
			&& g_iConfirm[iI]==1
			&& GetClientTeam(iI)==2)
		{
			g_iMARegisterCount++;
			g_iMARegisterIndex[g_iMARegisterCount]=iI;

			if (g_iL4D_GameMode==0)
				flSpeed=1.0*g_flMA_rate_coop;
			else
				flSpeed=1.0*g_flMA_rate;
			SetEntDataFloat(iI,g_iLaggedMovementO, flSpeed ,true);

			//----DEBUG----
			//PrintToChatAll("\x03-registering \x01%i",iI);
		}
	}
}

//called to clear out registry
//and reset movement speeds
//(called on: round start, round end, map end)
MA_Clear ()
{
	g_iMARegisterCount=0;
	for (new iI=1 ; iI<=MaxClients ; iI++)
	{
		g_iMARegisterIndex[iI]= -1;

		if (IsServerProcessing()==false)
			continue;

		//skip anyone who isn't a valid entity
		if (IsValidEntity(iI)==false)
			continue;

		//since more than one perk
		//gives bonus speed, only
		//reset speeds for survivors
		if (IsClientInGame(iI)==true
			&& GetClientTeam(iI)==2)
			SetEntDataFloat(iI,g_iLaggedMovementO, 1.0 ,true);
	}
}

//fires from "TimerPerks" function above
MA_ResetFatigue ()
{
	//check if perk is enabled
	if (g_iSur2_enable==0
		|| g_iMA_enable==0		&&	g_iL4D_GameMode==0
		|| g_iMA_enable_sur==0	&&	g_iL4D_GameMode==1
		|| g_iMA_enable_vs==0	&&	g_iL4D_GameMode==2)
		return;

	decl iCid;

	//theoretically, to get on the MA registry
	//all the necessary checks would have already
	//been run, so we don't bother with any checks here
	for (new iI=1; iI<=g_iMARegisterCount; iI++)
	{
		iCid = g_iMARegisterIndex[iI];
		//stop on this client
		//when the next client id is null
		if (iCid <= 0) return;
		//skip if it's not a valid entity
		if (IsValidEntity(iCid)==false) continue;
		//skip this client if they're disabled
		if (g_iPState[iCid]==1) continue;

		//----DEBUG----
		//PrintToChatAll("\x03martial artist fire, client \x01%i\x03, offset \x01%i",iI,g_iMeleeFatigueO);

		SetEntData(iCid,g_iMeleeFatigueO,0);
	}
}



//=============================
// Inf1: Blind Luck,
// Inf1: Barf Bagged,
// Inf1: Dead Wreckening
//(credits to grandwaziri and doku for Blind Luck)
//=============================

//on becoming slimed, check if player will lose hud
public Event_PlayerNowIt (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iAtt=GetClientOfUserId(GetEventInt(event,"attacker"));
	new iVic=GetClientOfUserId(GetEventInt(event,"userid"));

	if (iAtt==0 || iVic==0) return;

	//----DEBUG----
	//PrintToChatAll("\x03slimed detected, victim/client: \x01%i\x03, attacker: \x01%i",iVic,iAtt);

	//tell plugin another one got slimed (pungent)
	g_iSlimed++;
	//update plugin var for who vomited last (dead wreckening)
	g_iSlimerLast=iAtt;

	//check for blind luck
	//don't blind bots as per grandwaziri's plugin, they suck enough anyways
	if (g_iInf1[iAtt]==2
		&& g_iConfirm[iAtt]==1
		&& IsFakeClient(iVic)==false)
	{
		//check if perk is enabled
		if (g_iInf1_enable==0
			|| g_iBlind_enable==0)
			return;

		SetEntProp(iVic, Prop_Send, "m_iHideHUD", 64);

		//----DEBUG----
		//PrintToChatAll("\x03-attempting to hide hud");
	}

	//check for barf bagged
	//only spawn a mob if one guy got slimed
	//or if all four got slimed (max 2 extra mobs)
	else if (g_iInf1[iAtt]==1
		&& g_iConfirm[iAtt]==1
		&& (g_iSlimed==1 || g_iSlimed==4))
	{
		//check if perk is enabled
		if (g_iInf1_enable==0
			|| g_iBarf_enable==0)
			return;

		//----DEBUG----
		//PrintToChatAll("\x03-attempting to spawn a mob, g_iSlimed=\x01%i",g_iSlimed);

		new iflags=GetCommandFlags("z_spawn");
		SetCommandFlags("z_spawn", iflags & ~FCVAR_CHEAT);
		FakeClientCommand(iAtt,"z_spawn mob auto");
		SetCommandFlags("z_spawn", iflags);

		if (g_iSlimed==4) PrintHintText(iAtt,"Barf Bagged! A larger mob has been called!");
	}

	CreateTimer(15.0,PlayerNoLongerIt,iVic);
}

//on drying from slime, remove hud changes
//and lower count of people slimed (pungent)
public Action:PlayerNoLongerIt (Handle:timer, any:iCid)
{
	if (IsClientInGame(iCid)==true
		&& IsFakeClient(iCid)==false)
		SetEntProp(iCid, Prop_Send, "m_iHideHUD", 0);
		//SendConVarValue(iCid,FindConVar("sv_cheats"),"0");

	//----DEBUG----
	//PrintToChatAll("\x03client \x01%i\x03 no longer it \n attempting to restore hud",iCid);
	//PrintToChatAll("\x03old g_iSlimed: \x01%i",g_iSlimed);

	if (g_iSlimed>4) g_iSlimed=3;
	else if (g_iSlimed<0) g_iSlimed=0;
	else g_iSlimed--;

	//----DEBUG----
	//PrintToChatAll("\x03new g_iSlimed: \x01%i",g_iSlimed);

	return Plugin_Continue;
}



//=============================
// Inf3: Tongue Twister,
// Inf1: Blind Luck
//=============================

//increases tongue fire speed
//or decreases cooldown for blind luck
public Action:Event_AbilityUsePre (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iCid==0 || g_iConfirm[iCid]==0) return Plugin_Continue;
	decl String:st_ab[24];
	GetEventString(event,"ability",st_ab,24);

	//----DEBUG----
	//PrintToChatAll("\x03ability used: \x01%s", st_ab);

	//check for smoker-type perks
	if (StrEqual(st_ab,"ability_tongue",false)==true)
	{
		//stop if twister is disabled
		if (g_iTongue_enable==0)
			return Plugin_Continue;

		//check for twister
		if (g_iInf3[iCid]==1)
			SetConVarFloat(FindConVar("tongue_fly_speed"), g_flTongueFlySpeed*g_flTongue_speedmult ,false,false);
		else
			SetConVarFloat(FindConVar("tongue_fly_speed"),g_flTongueFlySpeed,false,false);
		return Plugin_Continue;
	}

	//check for boomer-type perks (blind luck)
	else if (StrEqual(st_ab,"ability_vomit",false)==true)
	{
		//stop if convar changes are disallowed for this perk
		if (g_iBlind_convar==0
			|| g_iBlind_enable==0
			|| g_iInf1_enable==0)
			return Plugin_Continue;

		if (g_iInf1[iCid]==2)
			SetConVarFloat(FindConVar("z_vomit_interval"), g_flVomitInt*g_flBlind_cdmult ,false,false);
		else
			SetConVarFloat(FindConVar("z_vomit_interval"), g_flVomitInt ,false,false);
		return Plugin_Continue;
	}
	return Plugin_Continue;
}


//=============================
// Inf3: Tongue Twister,
// Sur1: Spirit,
// +Inf
//=============================

//changes drag speed to 150% of original value (tongue twister)
//and sets player's state to disabled (spirit)
public Action:Event_TongueGrabPre (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iCid==0) return Plugin_Continue;

	//spirit perk, tell plugin player is disabled
	g_iPState[GetClientOfUserId(GetEventInt(event,"victim"))]=1;
	//+Inf, tell plugin attacker is disabling
	g_iDisabling[iCid]=1;

	//stop if twister is disabled
	if (g_iInf3_enable==0
		|| g_iTongue_enable==0)
		return Plugin_Continue;

	//----DEBUG----
	//PrintToChatAll("\x03yoink grab fired, client: \x01%i",iCid);

	if (g_iConfirm[iCid]==1)
	{
		switch (g_iInf3[iCid])
		{
		//yoink
		case 1:
			{
				SetConVarFloat(FindConVar("tongue_victim_max_speed"), g_flTongueSpeed*g_flTongue_pullmult ,false,false);
				
				//----DEBUG----
				//PrintToChatAll("\x03-checks passed, setting value to \x01%f",g_flTongueSpeed*3/2);
			}
		default:
			{
				SetConVarFloat(FindConVar("tongue_victim_max_speed"),g_flTongueSpeed,false,false);
				
				//----DEBUG----
				//PrintToChatAll("\x03-resetting drag speed to \x01%f",g_flTongueSpeed);
			}
		}
	}

	return Plugin_Continue;
}

//fires in all tongue releases
//resets tongue max drag speed (yoink)
//and set's player state to free (spirit)
//and resets tongue health (staying)
public Event_TongueRelease (Handle:event, const String:name[], bool:dontBroadcast)
{
	//only reset these convars if twister is enabled
	if (g_iInf3_enable==1
		&& g_iTongue_enable==1)
	{
		//SetConVarFloat(FindConVar("tongue_victim_max_speed"),g_flTongueSpeed,false,false);
		//SetConVarFloat(FindConVar("tongue_fly_speed"),g_flTongueFlySpeed,false,false);
		CreateTimer(3.0,Timer_TongueRelease,0);
	}

	//----DEBUG----
	//PrintToChatAll("\x03tongue release, resetting tongue speed value to \x01%f",g_flTongueSpeed);
	//PrintToChatAll("\x03resetting tongue speed to \x01%f", g_flTongueFlySpeed);

	//spirit perk, tell plugin player is free
	new iVic=GetClientOfUserId(GetEventInt(event,"victim"));
	if (iVic!=0) g_iPState[iVic]=0;
	//+Inf, tell plugin attacker is no longer disabling
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iCid!=0) g_iDisabling[iCid]=0;
}

//delayed convar reset
public Action:Timer_TongueRelease (Handle:timer, any:data)
{
	SetConVarFloat(FindConVar("tongue_victim_max_speed"),g_flTongueSpeed,false,false);
	SetConVarFloat(FindConVar("tongue_fly_speed"),g_flTongueFlySpeed,false,false);
	return Plugin_Continue;
}



//=============================
// Inf1: Motion Sickness,
// Inf3: Tongue Twister,
// Inf4: Speed Demon
// GENERAL: Health Max check
// GENERAL: Set perks for bots
//=============================

//sets tongue range on spawn
//or hunter altered time rate
//also, checks player against max health values
//if they're higher for any reason, set to max
public Event_PlayerSpawn (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));

	//check survivors for max health
	//they probably don't have any confirmed perks
	//since they just spawned, so set max to 100
	if (GetClientTeam(iCid)==2)
	{
		if ( GetEntProp(iCid,Prop_Data,"m_iHealth") > 100 )
			SetEntProp(iCid,Prop_Data,"m_iHealth", 100 );

		//set survivor bot's perks
		if (IsFakeClient(iCid)==true)
		{
			g_iConfirm[iCid]=1;
			g_iSur1[iCid] = Bot_Sur1_PickRandom();
			g_iSur2[iCid] = Bot_Sur2_PickRandom();

			Event_Confirm_Unbreakable(iCid);
			Event_Confirm_PackRat(iCid);
			Event_Confirm_ChemReliant(iCid);

			//----DEBUG----
			//PrintToChatAll("\x03survivor bot 1: \x01%i\x03, 2:\x01%i",g_iSur1[iCid],g_iSur2[iCid]);
		}

		//----DEBUG----
		//PrintToChatAll("\x03spawned survivor \x01%i\x03 health \x01%i", iCid, GetEntProp(iCid,Prop_Data,"m_iHealth") );

		return;
	}

	new String:st_class[32];
	GetClientModel(iCid,st_class,32);

	//check for smoker first
	if (StrContains(st_class,"smoker",false) != -1)
	{
		//----DEBUG----
		//PrintToChatAll("\x03smoker model detected");

		//reset their run speed
		SetEntDataFloat(iCid,g_iLaggedMovementO, 1.0 ,true);

		//run a max health check before
		//doing anything else
		new iMaxHP = GetConVarInt(FindConVar("z_gas_health"));
		if ( GetEntProp(iCid,Prop_Data,"m_iHealth") > iMaxHP)
			SetEntProp(iCid,Prop_Data,"m_iHealth", iMaxHP );

		//set bot perks
		if (IsFakeClient(iCid)==true)
		{
			g_iInf3[iCid] = Bot_Inf3_PickRandom();
			g_iConfirm[iCid]=1;

			//----DEBUG----
			//PrintToChatAll("\x03-smoker bot perk \x01%i",g_iInf3[iCid]);
		}

		//----DEBUG----
		//PrintToChatAll("\x03spawned smoker \x01%i\x03 health \x01%i\x03, maxhp \x01%i", iCid, GetEntProp(iCid,Prop_Data,"m_iHealth"), iMaxHP );

		//stop here if twister is disabled
		if (g_iInf3_enable==0
			|| g_iTongue_enable==0)
			return;

		//check for tongue twister
		if (g_iInf3[iCid]==1
			&& g_iConfirm[iCid]==1)
		{
			SetConVarFloat(FindConVar("tongue_range"), g_flTongueRange*g_flTongue_rangemult ,false,false);

			//----DEBUG----
			//PrintToChatAll("\x03-tongue range modified");
		}

		//otherwise, just reset convar
		else
		{
			SetConVarFloat(FindConVar("tongue_range"),g_flTongueRange,false,false);

			//----DEBUG----
			//PrintToChatAll("\x03-tongue range reset");
		}
	}

	//then check for hunter
	else if (StrContains(st_class,"hunter",false) != -1)
	{
		//run a max health check before
		//doing anything else
		new iMaxHP = GetConVarInt(FindConVar("z_hunter_health"));
		if ( GetEntProp(iCid,Prop_Data,"m_iHealth") > iMaxHP)
			SetEntProp(iCid,Prop_Data,"m_iHealth", iMaxHP );

		//set bot perks
		if (IsFakeClient(iCid)==true)
		{
			g_iInf4[iCid] = Bot_Inf4_PickRandom();
			g_iConfirm[iCid]=1;

			//----DEBUG----
			//PrintToChatAll("\x03-hunter bot perk \x01%i",g_iInf4[iCid]);
		}

		if (g_iInf4[iCid]==4
			&& g_iConfirm[iCid]==1
			&& g_iInf4_enable==1
			&& g_iSpeedDemon_enable==1)
		{
			SetEntDataFloat(iCid,g_iLaggedMovementO, 1.0*g_flSpeedDemon_rate ,true);

			//----DEBUG----
			//PrintToChatAll("\x03-speed demon apply");
		}
		else
		{
			//reset their run speed
			SetEntDataFloat(iCid,g_iLaggedMovementO, 1.0 ,true);
		}

		//----DEBUG----
		//PrintToChatAll("\x03spawned hunter \x01%i\x03 health \x01%i\x03, maxhp \x01%i", iCid, GetEntProp(iCid,Prop_Data,"m_iHealth"), iMaxHP );
	}

	//lastly, check for boomer
	//just for health max
	else if (StrContains(st_class, "boomer", false) != -1)
	{
		//reset their run speed
		SetEntDataFloat(iCid,g_iLaggedMovementO, 1.0 ,true);

		//run a max health check before
		//doing anything else
		new iMaxHP = GetConVarInt(FindConVar("z_exploding_health"));
		if ( GetEntProp(iCid,Prop_Data,"m_iHealth") > iMaxHP)
			SetEntProp(iCid,Prop_Data,"m_iHealth", iMaxHP );

		//set bot perks
		if (IsFakeClient(iCid)==true)
		{
			g_iInf1[iCid] = Bot_Inf1_PickRandom();
			g_iConfirm[iCid]=1;

			//----DEBUG----
			//PrintToChatAll("\x03-boomer bot perk \x01%i",g_iInf1[iCid]);
		}

		//stop here if the perk is disabled
		if (g_iMotion_enable==0
			|| g_iInf1_enable==0)
			return;

		//check for motion sickness
		if (g_iInf1[iCid]==4
			&& g_iConfirm[iCid]==1)
		{
			SetConVarFloat(FindConVar("z_vomit_fatigue"),0.0,false,false);
			SetEntDataFloat(iCid,g_iLaggedMovementO, 1.0*g_flMotion_rate ,true);
		}
		else
		{
			SetConVarFloat(FindConVar("z_vomit_fatigue"), g_flVomitFatigue ,false,false);
		}

		//----DEBUG----
		//PrintToChatAll("\x03spawned boomer \x01%i\x03 health \x01%i\x03, maxhp \x01%i", iCid, GetEntProp(iCid,Prop_Data,"m_iHealth"), iMaxHP );
	}
}



//=============================
// Inf3: Drag and Drop
//=============================

//alters cooldown to be faster
public Event_TongueGrab (Handle:event, const String:name[], bool:dontBroadcast)
{
	//----DEBUG----
	//PrintToChatAll("\x03drag and drop running checks");

	//stop if drag and drop is disabled
	if (g_iInf3_enable==0
		|| g_iDrag_enable==0)
		return;

	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));

	//if attacker id is null, reset vars
	if (iCid==0) 
	{
		SetConVarFloat(FindConVar("tongue_hit_delay"),g_flTongueHitDelay,false,false);
		SetConVarInt(FindConVar("tongue_allow_voluntary_release"),0,false,false);
		SetConVarFloat(FindConVar("tongue_player_dropping_to_ground_time"),g_flTongueDropTime,false,false);
		return ;
	}

	//check for drag and drop
	if (g_iInf3[iCid]==3
		&& g_iConfirm[iCid]==1)
	{
		//----DEBUG----
		//PrintToChatAll("\x03and again! reducing cooldown to \x01%f",g_flTongueHitDelay/2);

		SetConVarFloat(FindConVar("tongue_hit_delay"), g_flTongueHitDelay*g_flDrag_cdmult ,false,false);
		SetConVarInt(FindConVar("tongue_allow_voluntary_release"),1,false,false);
		SetConVarFloat(FindConVar("tongue_player_dropping_to_ground_time"),0.2,false,false);
		return ;
	}

	//all else fails, reset vars
	else
	{
		//----DEBUG----
		//PrintToChatAll("\x03and again! resetting cooldown to \x01%f",g_flTongueHitDelay);

		SetConVarFloat(FindConVar("tongue_hit_delay"),g_flTongueHitDelay,false,false);
		SetConVarInt(FindConVar("tongue_allow_voluntary_release"),0,false,false);
		SetConVarFloat(FindConVar("tongue_player_dropping_to_ground_time"),g_flTongueDropTime,false,false);
		return ;
	}
}



//=============================
// Inf4: Grasshopper
//=============================

public Event_AbilityUse (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iCid==0)
		return;

	//stop if grasshopper is disabled
	if (g_iInf4_enable==0
		|| g_iGrass_enable==0)
		return;

	if (GetClientTeam(iCid)==3
		&& g_iInf4[iCid]==3
		&& g_iConfirm[iCid]==1)
	{
		decl String:st_ab[24];
		GetEventString(event,"ability",st_ab,24);

		//check if it's a pounce/lunge
		if (StrEqual(st_ab,"ability_lunge",false)==true)
		{
			CreateTimer(0.1,Grasshopper_DelayedVel,iCid);

			//----DEBUG----
			//PrintToChatAll("\x03grasshopper fired");
		}
	}
}

//delayed velocity change, since the hunter doesn't
//actually start moving until some time after the event
public Action:Grasshopper_DelayedVel (Handle:timer, any:iCid)
{
	decl Float:vecVelocity[3];
	GetEntPropVector(iCid, Prop_Data, "m_vecVelocity", vecVelocity);
	vecVelocity[0] *= g_flGrass_rate;
	vecVelocity[1] *= g_flGrass_rate;
	vecVelocity[2] *= g_flGrass_rate;
	TeleportEntity(iCid, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}



//=============================
// Inf2: Tank Perks
//=============================


//PRIMARY TANK FUNCTION		----------------------
//primary function for handling tank spawns
public Event_Tank_Spawn (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iCid==0
		|| GetClientTeam(iCid)!=3)
		return;

	//----DEBUG----
	//PrintToChatAll("\x03Tank Spawn detected, client \x01%i\x03,g_iTank \x01%i", iCid, g_iTank);

	//reset their run speed
	//from martial artist or speed demon
	SetEntDataFloat(iCid,g_iLaggedMovementO, 1.0 ,true);

	//stop if tank perks are disallowed
	if (g_iInf2_enable==0)
		return;

	//start a check if it's a bot
	if (IsFakeClient(iCid)==true)
	{
		g_iTankBotTicks=0;
		CreateTimer(2.5,Timer_TankBot,iCid,TIMER_REPEAT);
	}

	else
		Tank_ApplyPerk(iCid);
}

Tank_ApplyPerk (any:iCid)
{
	//why apply tank perks to non-infected?
	if (GetClientTeam(iCid)!=3)
		return;
	
	//and make sure we're dealing with a tank
	new String:st_class[32];
	GetClientModel(iCid,st_class,32);
	if (StrContains(st_class,"hulk",false) == -1)
		return;

	//----DEBUG----
	//PrintToChatAll("\x03applying perks; tank detected, model: \x01%s",st_class);

	//first battery of tests for perks 1-4 (not double trouble)
	if (g_iTank<2
		&& g_iConfirm[iCid]==1
		&& g_iInf2[iCid]<5)
	{
		switch (g_iInf2[iCid])
		{
		//check for adrenal glands
		case 1:
			{
				//----DEBUG----
				//PrintToChatAll("\x03applying adrenal glands");

				g_iTank=1;

				//stop if adrenal glands is disabled
				if (g_iAdrenal_enable==0)
					return;

				SetConVarFloat(FindConVar("z_tank_throw_interval"),	g_flRockInterval *g_flAdrenal_throwcdmult	,false,false);
				SetConVarFloat(FindConVar("z_tank_throw_force"),	g_flRockSpeed *g_flAdrenal_rockspeedmult	,false,false);
				SetConVarFloat(FindConVar("tank_swing_interval"),	g_flSwingInterval1 *g_flAdrenal_punchcdmult	,false,false);
				SetConVarFloat(FindConVar("tank_swing_miss_interval"),	g_flSwingInterval2 *g_flAdrenal_punchcdmult	,false,false);
				SetConVarFloat(FindConVar("z_tank_attack_interval"),	g_flSwingInterval3 *g_flAdrenal_punchcdmult	,false,false);

				if (IsFakeClient(iCid)==false)
					PrintHintText(iCid,"Adrenal Glands: you can attack faster! and your rocks travel faster!");
				return ;
			}
		//check for juggernaut perk
		case 2:
			{
				//at least tell plugin that there's a tank
				g_iTank=1;

				//stop if juggernaut is disabled
				if (g_iJuggernaut_enable==0)
					return;

				//----DEBUG----
				//PrintToChatAll("\x03applying juggernaut");

				CreateTimer(0.1,Juggernaut_ChangeHP,iCid);

				//if it's gotten this far, juggernaut's
				//about to get applied so we tell plugin the news
				g_iTank=2;

				if (IsFakeClient(iCid)==false)
					PrintHintText(iCid,"Juggernaut: your health has increased!");

				return ;
			}

		//check for metabolic boost
		case 3:
			{
				//----DEBUG----
				//PrintToChatAll("\x03applying metabolic boost");

				g_iTank=1;

				//stop if metabolic boost is disabled
				if (g_iMetabolic_enable==0)
					return;

				SetConVarFloat(FindConVar("z_tank_speed_vs"), g_flTankSpeed*g_flMetabolic_speedmult ,false,false);
				if (IsFakeClient(iCid)==false)
					PrintHintText(iCid,"Metabolic Boost: your speed has increased!");
				return ;
			}

		//check for storm caller
		case 4:
			{
				g_iTank=1;

				//stop if storm caller is disabled
				if (g_iStorm_enable==0)
					return;

				//----DEBUG----
				//PrintToChatAll("\x03applying storm caller");

				new iflags=GetCommandFlags("z_spawn");
				SetCommandFlags("z_spawn", iflags & ~FCVAR_CHEAT);
				for (new iI=0 ; iI<=g_iStorm_mobcount ; iI++)
				{
					FakeClientCommand(iCid,"z_spawn mob auto");
				}
				SetCommandFlags("z_spawn", iflags);
				if (IsFakeClient(iCid)==false)
					PrintHintText(iCid,"Storm Caller: a zombie wave has been summoned!");

				return ;
			}
		}
	}

	//check for double trouble activation;
	//must have perk confirmed (g_iConfirm==1)
	//and double trouble must not be in effect (g_iTank!=3,4)
	else if (g_iInf2[iCid]==5
		&& g_iTank<3
		&& g_iConfirm[iCid]==1)
	{
		g_iTank=3;
		g_iTank_MainId=iCid;

		//stop if double trouble is disabled
		if (g_iDouble_enable==0)
			return;

		//recount the number of tanks left
		g_iTankCount=0;
		for (new iI=1 ; iI<=MaxClients ; iI++)
		{
			if (IsClientInGame(iI)==true
				&& IsPlayerAlive(iI)==true
				&& GetClientTeam(iI)==3)
			{
				GetClientModel(iI,st_class,32);
				if (StrContains(st_class,"hulk",false) != -1)
					g_iTankCount++;

				//----DEBUG----
				//PrintToChatAll("\x03-counting \x01%i",iI);
			}
		}
		
		//----DEBUG----
		//PrintToChatAll("\x03double trouble 1st tank apply");

		CreateTimer(0.1,DoubleTrouble_ChangeHP,iCid);
		CreateTimer(0.1,DoubleTrouble_SpawnTank,iCid);

		CreateTimer(3.0,DoubleTrouble_FrustrationTimer,iCid,TIMER_REPEAT);

		if (IsFakeClient(iCid)==false)
			PrintHintText(iCid,"Double Trouble: your health is reduced, and another tank has spawned!");
		return ;
	}

	//if double trouble is activated (g_iTank==3)
	//subsequent tanks will have reduced hp
	else if (g_iTank==3)
	{
		//stop if double trouble is disabled
		if (g_iDouble_enable==0)
			return;

		//recount the number of tanks left
		g_iTankCount=0;
		for (new iI=1 ; iI<=MaxClients ; iI++)
		{
			if (IsClientInGame(iI)==true
				&& IsPlayerAlive(iI)==true
				&& GetClientTeam(iI)==3)
			{
				GetClientModel(iI,st_class,32);
				if (StrContains(st_class,"hulk",false) != -1)
					g_iTankCount++;

				//----DEBUG----
				//PrintToChatAll("\x03-counting \x01%i",iI);
			}
		}

		//----DEBUG----
		//PrintToChatAll("\x03double trouble 2nd+ tank apply");

		if (IsFakeClient(iCid)==false)
			PrintHintText(iCid,"You have less health, and none of your tank perks will work!");
		CreateTimer(0.1,DoubleTrouble_ChangeHP,iCid);

		CreateTimer(3.0,DoubleTrouble_FrustrationTimer,iCid,TIMER_REPEAT);

		decl Float:vecOrigin[3];
		GetClientAbsOrigin(g_iTank_MainId,vecOrigin);
		TeleportEntity(iCid,vecOrigin,NULL_VECTOR,NULL_VECTOR);

		return ;
	}

	//if frustrated double trouble tank is being passed, do nothing
	else if (g_iTank==4)
	{
		//----DEBUG----
		//PrintToChatAll("\x03double trouble, frustration pass (no perks granted)");

		g_iTank=3;
		return ;
	}

	//if none of the special perks apply, just tell plugin that there's a tank
	else
	{
		//----DEBUG----
		//PrintToChatAll("\x03nothing applied, setting g_iTank to 1");

		g_iTank=1;
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
public Action:DoubleTrouble_ChangeHP (Handle:timer, any:iTankid)
{
	if (IsServerProcessing()==false
		|| iTankid==0
		|| IsClientInGame(iTankid)==false
		|| GetClientTeam(iTankid)!=3)
		return Plugin_Continue;

	SetEntityHealth(iTankid, RoundToCeil(GetEntProp(iTankid,Prop_Data,"m_iHealth")*g_flDouble_hpmult) );

	//----DEBUG----
	//PrintToChatAll("\x03double trouble apply hp reduction, health \x01%i", GetEntProp(iTankid,Prop_Data,"m_iHealth"));

	return Plugin_Continue;
}

public Action:DoubleTrouble_SpawnTank (Handle:timer, any:iCid)
{
	new iflags=GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", iflags & ~FCVAR_CHEAT);
	//FakeClientCommand(iCid,"z_spawn tank auto");
	FakeClientCommand(iCid,"z_spawn tank");
	SetCommandFlags("z_spawn", iflags);

	//----DEBUG----
	//PrintToChatAll("\x03double trouble attempting to spawn 2nd tank");
}

//resets frustration for double trouble tanks
//which is a band-aid solution =P for disappearing
//tanks whenever one becomes frustrated when there's
//two or more active tanks
public Action:DoubleTrouble_FrustrationTimer (Handle:timer, any:iCid)
{
	//----DEBUG----
	/*
	PrintToChatAll("\x03tank frustration reset begin");
	if (IsServerProcessing()==false)
		PrintToChatAll("\x03- not processing");
	if (IsClientInGame(iCid)==false)
		PrintToChatAll("\x03- not ingame");
	if (IsFakeClient(iCid)==true)
		PrintToChatAll("\x03- is a bot");
	if (IsPlayerAlive(iCid)==false)
		PrintToChatAll("\x03- not alive");
	if (GetClientTeam(iCid)!=3)
		PrintToChatAll("\x03- not infected");
	*/

	//recount the number of tanks left
	decl String:st_class[32];
	g_iTankCount=0;
	for (new iI=1 ; iI<=MaxClients ; iI++)
	{
		if (IsClientInGame(iI)==true
			&& IsPlayerAlive(iI)==true
			&& GetClientTeam(iI)==3)
		{
			GetClientModel(iI,st_class,32);
			if (StrContains(st_class,"hulk",false) != -1)
				g_iTankCount++;

			//----DEBUG----
			//PrintToChatAll("\x03-counting \x01%i",iI);
		}
	}

	//----DEBUG----
	//if (g_iTankCount<=1)
		//PrintToChatAll("\x03- 1 or less tanks");

	//stop the timer if any of these
	//conditions are true
	if (IsServerProcessing()==false
		|| IsClientInGame(iCid)==false
		|| IsFakeClient(iCid)==true
		|| IsPlayerAlive(iCid)==false
		|| GetClientTeam(iCid)!=3
		|| g_iTankCount<=1
		|| g_iInf2_enable==0
		|| g_iDouble_enable==0)
	{
		//----DEBUG----
		//PrintToChatAll("\x03- stopping, tankcount \x01%i",g_iTankCount);

		return Plugin_Stop;
	}

	//----DEBUG----
	//PrintToChatAll("\x03- checks passed, tankcount \x01%i",g_iTankCount);

	SetEntData(iCid,g_iFrustrationO,0);

	//----DEBUG----
	//PrintToChatAll("\x03- client \x01%i\x03, current frustration \x01%i", iCid, GetEntData(iCid,g_iFrustrationO) );

	return Plugin_Continue;
}



//when switching players from frustration, reset tank's hp and speed boost
public Action:Event_Tank_Frustrated(Handle:event, const String:name[], bool:dontBroadcast)
{
	//----DEBUG----
	//PrintToChatAll("\x03tank frustration detected");

	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));

	if (IsServerProcessing()==false
		|| iCid==0
		|| IsClientInGame(iCid)==false
		|| GetClientTeam(iCid)!=3)
		return Plugin_Continue;

	//if this is a tank spawned under double trouble, it gets no perks
	//setting g_iTank to 4 means any tank "spawns" get no perks
	//and the main tank spawn function won't do anything to the tank
	if (g_iTank==3) g_iTank=4;

	//reset tank attack intervals
	//only if adrenal glands is enabled
	if (g_iAdrenal_enable==1)
	{
		SetConVarFloat(FindConVar("z_tank_throw_interval"),g_flRockInterval,false,false);
		SetConVarFloat(FindConVar("z_tank_throw_force"),g_flRockSpeed,false,false);
		SetConVarFloat(FindConVar("tank_swing_interval"),g_flSwingInterval1,false,false);
		SetConVarFloat(FindConVar("tank_swing_miss_interval"),g_flSwingInterval2,false,false);
		SetConVarFloat(FindConVar("z_tank_attack_interval"),g_flSwingInterval3,false,false);
	}

	//reset tank speed
	//only if metabolic boost is enabled
	if (g_iMetabolic_enable==1)
		SetConVarFloat(FindConVar("z_tank_speed_vs"),g_flTankSpeed,false,false);
	
	return Plugin_Continue;
}


//detects a player death, is pre-hook mode because
//we need to get the player's class before it becomes null
public Action:Event_PlayerDeathPre (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iCid=GetClientOfUserId(GetEventInt(event,"userid"));
	if (iCid==0) return Plugin_Continue;

	decl String:st_class[32];
	GetClientModel(iCid,st_class,32);

	//----DEBUG----
	//PrintToChatAll("\x03player model: %s",st_class);

	if (StrContains(st_class,"hulk",false) != -1)
	{
		//if a tank is dead, recount the number of tanks left
		//start from zero...
		g_iTankCount=0;
		//...and count up
		for (new iI=1 ; iI<=MaxClients ; iI++)
		{
			if (IsClientInGame(iI)==true
				&& IsPlayerAlive(iI)==true
				&& GetClientTeam(iI)==3)
			{
				GetClientModel(iI,st_class,32);
				if (StrContains(st_class,"hulk",false) != -1)
					g_iTankCount++;

				//----DEBUG----
				//PrintToChatAll("\x03-counting \x01%i",iI);
			}
		}

		//----DEBUG----
		//PrintToChatAll("\x03new g_iTankCount= \x01%i",g_iTankCount);

		//if there are no more double trouble tanks, tell plugin there's no more tanks
		if (g_iTankCount==0)
			g_iTank=0;
		//if for some reason it goes below 0, reset vars
		else if (g_iTankCount<0)
		{
			g_iTankCount=0;
			g_iTank=0;
		}

		if (g_iAdrenal_enable==1)
		{
			//SetConVarFloat(FindConVar("z_tank_throw_interval"),g_flRockInterval,false,false);
			//SetConVarFloat(FindConVar("z_tank_throw_force"),g_flRockSpeed,false,false);
			//SetConVarFloat(FindConVar("tank_swing_interval"),g_flSwingInterval1,false,false);
			//SetConVarFloat(FindConVar("tank_swing_miss_interval"),g_flSwingInterval2,false,false);
			//SetConVarFloat(FindConVar("z_tank_attack_interval"),g_flSwingInterval3,false,false);
			CreateTimer(3.0,Timer_ResetAdrenal,0);
		}

		//reset tank speed
		//only if metabolic boost is enabled
		if (g_iMetabolic_enable==1)
			//SetConVarFloat(FindConVar("z_tank_speed_vs"),g_flTankSpeed,false,false);
			CreateTimer(3.0,Timer_ResetMetabolic,0);

		//----DEBUG----
		//PrintToChatAll("\x03-end tank death routine");
	}
	return Plugin_Continue;
}

//delayed convar reset
public Action:Timer_ResetAdrenal (Handle:timer, any:data)
{
	SetConVarFloat(FindConVar("z_tank_throw_interval"),g_flRockInterval,false,false);
	SetConVarFloat(FindConVar("z_tank_throw_force"),g_flRockSpeed,false,false);
	SetConVarFloat(FindConVar("tank_swing_interval"),g_flSwingInterval1,false,false);
	SetConVarFloat(FindConVar("tank_swing_miss_interval"),g_flSwingInterval2,false,false);
	SetConVarFloat(FindConVar("z_tank_attack_interval"),g_flSwingInterval3,false,false);
	return Plugin_Continue;
}

public Action:Timer_ResetMetabolic (Handle:timer, any:data)
{
	SetConVarFloat(FindConVar("z_tank_speed_vs"),g_flTankSpeed,false,false);
	return Plugin_Continue;
}

//timer to check for bots
public Action:Timer_TankBot (Handle:timer, any:iTankid)
{
	if (IsServerProcessing()==false
		|| IsValidEntity(iTankid)==false
		|| IsClientInGame(iTankid)==false
		|| IsFakeClient(iTankid)==false
		|| g_iTankBotTicks>=4
		|| g_iInf2_enable==0)
	{
		//----DEBUG----
		//PrintToChatAll("\x03stopping bot timer");

		return Plugin_Stop;
	}

	if (IsClientInGame(iTankid)==true
		&& IsFakeClient(iTankid)==true)
	{
		g_iTankBotTicks++;

		//----DEBUG----
		//PrintToChatAll("\x03tankbot tick %i",g_iTankBotTicks);

		if (g_iTankBotTicks>=3)
		{
			//----DEBUG----
			//PrintToChatAll("\x03bot tank detected");

			//set bot perks
			g_iInf2[iTankid] = Bot_Inf2_PickRandom();
			g_iConfirm[iTankid]=1;

			//----DEBUG----
			//PrintToChatAll("\x03-tank bot perk \x01%i",g_iInf2[iTankid]);

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
public Action:MenuOpen_OnSay(iCid, args)
{
	if (iCid==0) return Plugin_Continue;
	if (args<1) return Plugin_Continue;
	decl String:st_chat[64];
	GetCmdArg(1,st_chat,64);
	if (StrEqual(st_chat,"!perks",false)==true)
	{
		if (g_iConfirm[iCid]==0)
		{
			SendPanelToClient(Menu_Initial(iCid),iCid,Menu_ChooseInit,MENU_TIME_FOREVER);
			return Plugin_Continue;
		}
		SendPanelToClient(Menu_ShowChoices(iCid),iCid,Menu_DoNothing,15);
	}
	return Plugin_Continue;
}

//build initial menu
public Handle:Menu_Initial (iCid)
{
	new Handle:menu = CreatePanel();
	SetPanelTitle(menu, "tPoncho's Perkmod");
	DrawPanelText(menu,"This server is using Perkmod");
	DrawPanelText(menu,"Select option 1 to customize your perks");

	DrawPanelItem(menu,"Customize Perks");

	//random perks, enable only if cvar is set
	if (g_iRandomEnable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		DrawPanelText(menu,"You can opt to randomize your perks");
		DrawPanelText(menu,"but you can't change them afterwards");

		DrawPanelItem(menu,"Randomize Perks");
	}

	DrawPanelText(menu,"Otherwise, you can use whatever");
	DrawPanelText(menu,"perks you've selected already");
	DrawPanelText(menu,"by using option 3");

	DrawPanelItem(menu,"PLAY NOW!");
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
					AssignRandomPerks(param1);
					PrintHintText(param1,"Perkmod: Thanks and have fun!");
				}
			case 3:
				{
					g_iConfirm[param1]=1;
					Event_Confirm_Unbreakable(param1);
					Event_Confirm_PackRat(param1);
					Event_Confirm_Grenadier(param1);
					Event_Confirm_ChemReliant(param1);
					Event_Confirm_DT(param1);
					Event_Confirm_MA(param1);
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
public Handle:Menu_Top (iCid)
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
	switch (g_iSur1[iCid])
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
	if (g_iSur1_enable==1)
		DrawPanelItem(menu,st_display);
	else
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);

	//set name for sur2 perk
	switch (g_iSur2[iCid])
	{
		case 1: st_perk="Chem Reliant";
		case 2: st_perk="Helping Hand";
		case 3: st_perk="Pack Rat";
		case 4: st_perk="Martial Artist";
		case 5: st_perk="Hard to Kill";
		default: st_perk="Not set";
	}
	Format(st_display,64,"Survivor - Secondary (%s)", st_perk);
	if (g_iSur2_enable==1)
		DrawPanelItem(menu,st_display);
	else
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);

	//here we check for versus mode
	//if true, then just draw blanks

	new bool:bModeVersus=false;
	new String:stArg[64];
	GetConVarString(FindConVar("mp_gamemode"),stArg,64);
	if (StrEqual(stArg,"versus",false)==true)
		bModeVersus=true;
	else
		bModeVersus=false;

	//perks from here on will check whether
	//it's versus, if it is then the line will be blank

	//set name for inf1 perk
	switch (g_iInf1[iCid])
	{
		case 1: st_perk="Barf Bagged";
		case 2: st_perk="Blind Luck";
		case 3: st_perk="Dead Wreckening";
		case 4:	st_perk="Motion Sickness";
		default: st_perk="Not set";
	}
	Format(st_display,64,"Boomer (%s)", st_perk);
	if (g_iInf1_enable==1
		&& bModeVersus==true)
		DrawPanelItem(menu,st_display);
	else
		DrawPanelItem(menu,st_display, ITEMDRAW_NOTEXT);

	//set name for inf3 perk
	switch (g_iInf3[iCid])
	{
		case 1: st_perk="Tongue Twister";
		case 2: st_perk="Squeezer";
		case 3: st_perk="Drag and Drop";
		case 4: st_perk="Smoke Bomber";
		default: st_perk="Not set";
	}
	Format(st_display,64,"Smoker (%s)", st_perk);
	if (g_iInf3_enable==1
		&& bModeVersus==true)
		DrawPanelItem(menu,st_display);
	else
		DrawPanelItem(menu,st_display, ITEMDRAW_NOTEXT);

	//set name for inf4 perk
	switch (g_iInf4[iCid])
	{
		case 1: st_perk="Body Slam";
		case 2: st_perk="Efficient Killer";
		case 3: st_perk="Grasshopper";
		case 4: st_perk="Speed Demon";
		default: st_perk="Not set";
	}
	Format(st_display,64,"Hunter (%s)", st_perk);
	if (g_iInf4_enable==1
		&& bModeVersus==true)
		DrawPanelItem(menu,st_display);
	else
		DrawPanelItem(menu,st_display, ITEMDRAW_NOTEXT);

	//set name for inf2 perk
	switch (g_iInf2[iCid])
	{
		case 1: st_perk="Adrenal Glands";
		case 2: st_perk="Juggernaut";
		case 3: st_perk="Metabolic Boost";
		case 4: st_perk="Storm Caller";
		case 5: st_perk="Double the Trouble";
		default:st_perk="Not set";
	}
	Format(st_display,64,"Tank (%s)", st_perk);
	if (g_iInf2_enable==1
		&& bModeVersus==true)
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
public Handle:Menu_Confirm (iCid)
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
				g_iConfirm[param1]=1;
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

//shows perk choices
public Handle:Menu_ShowChoices (iCid)
{
	new Handle:menu=CreatePanel();
	SetPanelTitle(menu,"tPoncho's Perkmod: Your perks for this map");
	decl String:st_perk[128];

	//show sur1 perk
	switch (g_iSur1[iCid])
	{
		case 1:
			Format(st_perk,128,"Stopping Power (bonus %i%% damage)", RoundToNearest(g_flStopping_dmgmult*100) );
		case 2:
			st_perk="Pyrotechnician (carry 2 grenades)";
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
	if (g_iSur1_enable==1)
	{
		DrawPanelItem(menu,"Survivor, primary:");
		DrawPanelText(menu,st_perk);
	}

	//show sur2 perk
	switch (g_iSur2[iCid])
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
				if (g_iHelpHand_convar==1)
					Format(st_perk,128,"Helping Hand (revive others faster, gives %i bonus buffer)",iBuff);
				else
					Format(st_perk,128,"Helping Hand (gives %i bonus buffer to others on revive)",iBuff);
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
	if (g_iSur2_enable==1)
	{
		DrawPanelItem(menu,"Survivor, secondary:");
		DrawPanelText(menu,st_perk);
	}
		
	//test if it's versus mode,
	//otherwise just send the menu

	if (g_iL4D_GameMode!=2)
	{
		//SendPanelToClient(menu,iCid,Menu_DoNothing,15);
		//CloseHandle(menu);
		return menu;
	}

	//if it's gotten this far,
	//it must be versus so continue...

	//show inf1 perk
	switch (g_iInf1[iCid])
	{
		case 1:
			st_perk="Barf Bagged (vomit attracts more zombies)";
		case 2:
			{
				if (g_iBlind_convar==1)
					st_perk="Blind Luck (survivors lose hud on vomit, shorter cooldown)";
				else
					st_perk="Blind Luck (survivors lose hud on vomit)";
			}
		case 3:
			Format(st_perk,128,"Dead Wreckening (zombies do %i%% more damage on vomit)", RoundToNearest(100*g_flDead_dmgmult) );
		case 4:
			Format(st_perk,128,"Motion Sickness (can move while vomiting, run %i%% faster)", RoundToNearest( (g_flMotion_rate - 1) * 100 ) );
		default: st_perk="Not set";
	}
	if (g_iInf1_enable==1)
	{
		DrawPanelItem(menu,"Boomer:");
		DrawPanelText(menu,st_perk);
	}

	//show inf3 perk
	switch (g_iInf3[iCid])
	{
		case 1:
			st_perk="Tongue Twister (faster and longer tongue)";
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
		case 3:
			st_perk="Drag and Drop (shorter cooldown, manual release with FIRE2)";
		default:
			st_perk="Not set";
	}
	if (g_iInf3_enable==1)
	{
		DrawPanelItem(menu,"Smoker:");
		DrawPanelText(menu,st_perk);
	}

	//show inf4 perk
	switch (g_iInf4[iCid])
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
				
				new String:st_spd[24]="";
				new String:st_claw[24]="";
				new String:st_space[3]="";

				if (g_iSpeedDemon_enable==1)
					Format(st_spd,24,"%i%% faster", RoundToNearest( (g_flSpeedDemon_rate - 1) * 100 ) );
				if (g_iOld_enable==1)
					Format(st_claw,24,"+%i%% claw damage", iDmg);
				if (g_iOld_enable==1
					&& g_iSpeedDemon_enable==1)
					Format(st_space,3,", ");
				Format(st_perk,128,"Speed Demon (%s%s%s)", st_spd, st_space, st_claw);
			}
		default:
			st_perk="Not set";
	}
	if (g_iInf4_enable==1)
	{
		DrawPanelItem(menu,"Hunter:");
		DrawPanelText(menu,st_perk);
	}
	
	//show inf2 perk
	switch (g_iInf2[iCid])
	{
		case 1:
			st_perk="Adrenal Glands (bonus attack speed)";
		case 2:
			Format(st_perk,128,"Juggernaut (bonus %i health)",g_iJuggernaut_hp);
		case 3:
			Format(st_perk,128,"Metabolic Boost (bonus %i%% movespeed)", RoundToNearest((g_flMetabolic_speedmult-1)*100) );
		case 4:
			st_perk="Storm Caller (zombie wave on spawn)";
		case 5:
			Format(st_perk,128,"Double the Trouble (spawns two tanks at %i%% health)", RoundToNearest(g_flDouble_hpmult*100) );
		default: st_perk="Not set";
	}
	if (g_iInf2_enable)
	{
		DrawPanelItem(menu,"Tank:");
		DrawPanelText(menu,st_perk);
	}

	return menu;
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
		switch (g_iSur1[client])
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
		switch (g_iSur1[client])
		{
			case 4: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Double Tap %s",st_current);
		DrawPanelItem(menu,st_display);
		Format(st_display,64,"Fire %i%% faster", RoundToNearest(100 * ((1/g_flDT_rate)-1) ) );
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
		switch (g_iSur1[client])
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
		switch (g_iSur1[client])
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
		switch (g_iSur1[client])
		{
			case 3: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Spirit %s",st_current);
		DrawPanelItem(menu,st_display);
		DrawPanelText(menu,"When a teammate goes down you will self-revive");
		if (g_iSpirit_crawling==1)
			DrawPanelText(menu,"and you can crawl while incapped");
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
		switch (g_iSur1[client])
		{
			case 5: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Unbreakable %s",st_current);
		DrawPanelItem(menu,st_display);
		Format(st_display,64,"+%i health +%i health buffer on revive", g_iUnbreak_hp, g_iUnbreak_hp*8/10 );
		DrawPanelText(menu,st_display);
		Format(st_display,64,"+%i health with medkit +%i health on rescue", g_iUnbreak_hp*8/10, g_iUnbreak_hp/2 );
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
				g_iSur1[param1]=1;
			//double tap
			case 2:
				g_iSur1[param1]=4;
			//sleight of hand
			case 3:
				g_iSur1[param1]=6;
			//pyrotechnician
			case 4:
				g_iSur1[param1]=2;
			//spirit
			case 5:
				g_iSur1[param1]=3;
			//unbreakable
			case 6:
				g_iSur1[param1]=5;
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
		switch (g_iSur2[client])
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
		switch (g_iSur2[client])
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

		if (g_iHelpHand_convar==1)
		{
			Format(st_display,64,"You can revive others in %is and", RoundToNearest(g_flReviveTime*g_flHelpHand_timemult) );
			DrawPanelText(menu,st_display);
			Format(st_display,64,"give them +%i bonus health buffer", iBuff);
			DrawPanelText(menu,st_display);
		}
		else
		{
			DrawPanelText(menu,"When you revive others, you give");
			Format(st_display,64,"+%i bonus health buffer", iBuff);
			DrawPanelText(menu,st_display);
		}
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
		switch (g_iSur2[client])
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
		switch (g_iSur2[client])
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
		|| g_iMA_enable_vs==0	&&	g_iL4D_GameMode==2)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (g_iSur2[client])
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
				g_iSur2[param1]=1;
			//helping hand
			case 2:
				g_iSur2[param1]=2;
			//hard to kill
			case 3:
				g_iSur2[param1]=5;
			//pack rat
			case 4:
				g_iSur2[param1]=3;
			//martial artist
			case 5:
				g_iSur2[param1]=4;
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
		switch (g_iInf1[client])
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
		switch (g_iInf1[client])
		{
			case 2: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Blind Luck %s",st_current);
		DrawPanelItem(menu,st_display);
		DrawPanelText(menu,"Your vomit totally blocks survivor's HUDs");
		if (g_iBlind_convar==1)
		{
			Format(st_display,64,"and also recharges in %is", RoundToNearest(g_flVomitInt*g_flBlind_cdmult) );
			DrawPanelText(menu,st_display);
		}
		DrawPanelText(menu,"(thanks to Grandwazir for this perk!)");
	}

	//set name for perk 3
	if (g_iDead_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (g_iInf1[client])
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
		switch (g_iInf1[client])
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
				g_iInf1[param1]=1;
			//blind luck
			case 2:
				g_iInf1[param1]=2;
			//dead wreckening
			case 3:
				g_iInf1[param1]=3;
			//motion sickness
			case 4:
				g_iInf1[param1]=4;
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
		switch (g_iInf2[client])
		{
			case 1: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Adrenal Glands %s",st_current);
		DrawPanelItem(menu,st_display);
		Format(st_display,64,"Punch %i%% faster", RoundToNearest(100 * ((1/g_flAdrenal_punchcdmult)-1) ) );
		DrawPanelText(menu,st_display);
		Format(st_display,64,"Throw rocks %i%% faster", RoundToNearest(100 * ((1/g_flAdrenal_throwcdmult)-1) ) );
		DrawPanelText(menu,st_display);
		Format(st_display,64,"Rocks travel %i%% faster", RoundToNearest(100 * (g_flAdrenal_rockspeedmult-1)) );
		DrawPanelText(menu,st_display);
	}

	//set name for perk 2
	if (g_iJuggernaut_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (g_iInf2[client])
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
		switch (g_iInf2[client])
		{
			case 3: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Metabolic Boost %s",st_current);
		DrawPanelItem(menu,st_display);
		Format(st_display,64,"You can run +%i%% faster", RoundToNearest((g_flMetabolic_speedmult-1)*100) );
		DrawPanelText(menu,st_display);
	}

	//set name for perk 4
	if (g_iStorm_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (g_iInf2[client])
		{
			case 4: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Storm Caller %s",st_current);
		DrawPanelItem(menu,st_display);
		DrawPanelText(menu,"A zombie wave will spawn with you");
	}

	//set name for perk 5
	if (g_iDouble_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (g_iInf2[client])
		{
			case 5: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Double the Trouble %s",st_current);
		DrawPanelItem(menu,st_display);
		DrawPanelText(menu,"A second tank will spawn with you!");
		DrawPanelText(menu,"However, both tanks have no other perks");
		Format(st_display,64,"and both have only %i%% health", RoundToNearest(g_flDouble_hpmult*100) );
		DrawPanelText(menu,"Cannot become frustrated while both live");
		DrawPanelText(menu,st_display);
	}

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
				g_iInf2[param1]=1;
			//juggernaut
			case 2:
				g_iInf2[param1]=2;
			//metabolic boost
			case 3:
				g_iInf2[param1]=3;
			//storm caller
			case 4:
				g_iInf2[param1]=4;
			//double the trouble
			case 5:
				g_iInf2[param1]=5;
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
	if (g_iTongue_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (g_iInf3[client])
		{
			case 1: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Tongue Twister %s",st_current);
		DrawPanelItem(menu,st_display);
		Format(st_display,64,"Tongue shoots %i%% faster", RoundToNearest(100*(g_flTongue_speedmult-1)) );
		DrawPanelText(menu,st_display);
		Format(st_display,64,"Tongue range is %i%% farther", RoundToNearest(100*(g_flTongue_rangemult-1)) );
		DrawPanelText(menu,st_display);
		Format(st_display,64,"Tongue pulls %i%% faster", RoundToNearest(100*(g_flTongue_pullmult-1)) );
		DrawPanelText(menu,st_display);
	}

	//set name for perk 2
	if (g_iSqueezer_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (g_iInf3[client])
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
	if (g_iDrag_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (g_iInf3[client])
		{
			case 3: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Drag and Drop %s",st_current);
		DrawPanelItem(menu,st_display);
		DrawPanelText(menu,"You can release your target with FIRE2 (your melee");
		Format(st_display,64,"attack button) and your cooldown is %is long", RoundToNearest(g_flDrag_cdmult*g_flTongueHitDelay) );
		DrawPanelText(menu,st_display);
		DrawPanelText(menu,"plus on tongue break you recover faster");
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
			//tongue twister
			case 1:
				g_iInf3[param1]=1;
			//squeezer
			case 2:
				g_iInf3[param1]=2;
			//drag and drop
			case 3:
				g_iInf3[param1]=3;
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
		switch (g_iInf4[client])
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
		switch (g_iInf4[client])
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
		switch (g_iInf4[client])
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
	if (g_iOld_enable==0
		&& g_iSpeedDemon_enable==0)
	{
		DrawPanelItem(menu,"disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		switch (g_iInf4[client])
		{
			case 4: st_current="(CURRENT)";
			default: st_current="";
		}
		Format(st_display,64,"Speed Demon %s",st_current);
		DrawPanelItem(menu,st_display);
		decl iDmg;
		if (g_iL4D_Difficulty==2)
			iDmg=g_iOld_dmg_expert;
		else if (g_iL4D_Difficulty==1)
			iDmg=g_iOld_dmg_hard;
		else
			iDmg=g_iOld_dmg;

		if (g_iOld_enable==1)
		{
			Format(st_display,64,"Secondary claw swipes deals +%i damage", iDmg);
			DrawPanelText(menu,st_display);
		}
		if (g_iSpeedDemon_enable==1)
		{
			DrawPanelText(menu,"You run, jump, fall and pounce at an altered time rate");
			Format(st_display,64,"(%i%% faster) making it much harder for survivors", RoundToNearest( (g_flSpeedDemon_rate - 1) * 100 ) );
			DrawPanelText(menu,st_display);
			DrawPanelText(menu,"to effectively counter you");
		}
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
				g_iInf4[param1]=1;
			//efficient killer
			case 2:
				g_iInf4[param1]=2;
			//grasshopper
			case 3:
				g_iInf4[param1]=3;
			//old school
			case 4:
				g_iInf4[param1]=4;
			//speed demon
			case 5:
				g_iInf4[param1]=5;
		}
	}

	if (IsClientInGame(param1)==true)
		SendPanelToClient(Menu_Top(param1),param1,Menu_ChooseSubMenu,MENU_TIME_FOREVER);
}



//=============================
//	DEBUG
//=============================
/*
public Action:Debug_OnSay(iCid, args)
{
	if (args<1) return Plugin_Continue;
	decl String:st_chat[32];
	GetCmdArg(1,st_chat,32);

	if (StrEqual(st_chat,"debug reset perks",false)==true)
	{
		g_iConfirm[iCid]=0;
		PrintToChat(iCid,"\x03[SM] [DEBUG] g_iConfirm has been reset to 0");
		DT_Rebuild();
		MA_Rebuild();
		return Plugin_Continue;
	}

	if (StrEqual(st_chat,"debug spirit reset",false)==true)
	{
		PrintToChat(iCid,"\x03[SM] [DEBUG] spirit cooldown reset");
		g_iSpiritCooldown[iCid]=0;
		return Plugin_Continue;
	}

	if (StrEqual(st_chat,"debug death",false)==true)
	{
		new iDeathTimeO=FindSendPropOffs("CTerrorPlayer","m_flDeathTime");
		PrintToChat(iCid,"\x03[SM] [DEBUG] m_fldeathtime offset \x01%i\x03", iDeathTimeO);
		PrintToChat(iCid,"\x03[SM] [DEBUG] -value at offset: \x01%f", GetEntDataFloat(iCid,iDeathTimeO));
		return Plugin_Continue;
	}

	if (StrEqual(st_chat,"debug client",false)==true)
	{
		PrintToChat(iCid,"\x03[SM] [DEBUG] you are client: \x01%i", iCid);
		return Plugin_Continue;
	}

	if (StrEqual(st_chat,"debug anim",false)==true)
	{
		PrintToChat(iCid,"\x03[SM] [DEBUG] creating timer, client \x01%i\x03, gunid \x01%i",iCid,GetEntDataEnt2(iCid,g_iActiveWO));
		CreateTimer(0.2,Debug_AnimTimer,iCid,TIMER_REPEAT);

		return Plugin_Continue;
	}

	if (StrEqual(st_chat,"debug frustration",false)==true)
	{
		PrintToChat(iCid,"\x03[SM] [DEBUG] retrieving frustration values");
		new iOffs=FindSendPropOffs("Tank","m_frustration");
		PrintToChat(iCid,"\x03- offset \x01%i",iOffs);
		PrintToChat(iCid,"\x03- value at offset \x01%i", GetEntData(iCid,iOffs) );

		return Plugin_Continue;
	}

	if (StrEqual(st_chat,"debug stamina",false)==true)
	{
		PrintToChat(iCid,"\x03[SM] [DEBUG] creating timer, client \x01%i\x03",iCid);
		CreateTimer(0.2,Debug_StaminaTimer,iCid,TIMER_REPEAT);

		return Plugin_Continue;
	}

	if (StrEqual(st_chat,"debug maxclients",false)==true)
	{
		PrintToChat(iCid,"\x03[SM] [DEBUG] maxclients = \x01%i",MaxClients);

		return Plugin_Continue;
	}

	return Plugin_Continue;
}

public Action:Debug_AnimTimer (Handle:timer, any:iCid)
{
	new iGun = GetEntDataEnt2(iCid,g_iActiveWO);

	new iAnimTimeO = FindSendPropOffs("CTerrorGun","m_flAnimTime");
	PrintToChat(iCid,"\x03 m_flAnimTime \x01%i",iAnimTimeO);
	PrintToChat(iCid,"\x03 - value \x01%f", GetEntDataFloat(iGun,iAnimTimeO));

	new iSimTimeO = FindSendPropOffs("CTerrorGun","m_flSimulationTime");
	PrintToChat(iCid,"\x03 m_flSimulationTime \x01%i",iSimTimeO);
	PrintToChat(iCid,"\x03 - value \x01%f", GetEntDataFloat(iGun,iSimTimeO));

	new iSequenceO = FindSendPropOffs("CTerrorGun","m_nSequence");
	PrintToChat(iCid,"\x03 m_nSequence \x01%i",iSequenceO);
	PrintToChat(iCid,"\x03 - value \x01%i", GetEntData(iGun,iSequenceO));
}

public Action:Debug_StaminaTimer (Handle:timer, any:iCid)
{
	new iStaminaO = FindSendPropOffs("CTerrorPlayer","m_flStamina");
	PrintToChat(iCid,"\x03 m_flStamina \x01%i",iStaminaO);
	PrintToChat(iCid,"\x03 - value \x01%f", GetEntDataFloat(iCid,iStaminaO));
}
*/