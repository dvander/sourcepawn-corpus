#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <l4d2_luffy>

#define PLUGIN_NAME			"l4d2_luffy"
#define PLUGIN_VERSION		"0.9.1"
/*
v0.9.1
	  - corrected dummy and skin flipped.
	  - shield and rocket body part now use entity ref instead of index for lookup.
	  - old l4d2 default model included in. some commented out because its extras.
	  - entity rotation moved into the timer itself. for human readability. i make your life easy.
	  - fixed pickup animation scale problem.
	  - added cvar to enable/disable ammobox tweak to give flexibility to use other ammobox plugin.
	  - new cvar homing missile number
	  - new cvar homing missile damage
	  - new cvar shield damage
	  - cvar tank damage no longer tie to missile damage. its now saperated.
	  - new cvar health amount we steal during strength ability active when killing infected, tank or witch.
	  - fixed the life steal amount dosent subtract health and health buff properly.
	  - sheld ability timer merge into single timer.
	  - clock ability merged into single timer.
	  - homing missile targeting system updated. it now can bypass entity already in target list.
	  - added admin command to spawn model for debugging only.
	  - added admin command to reload map for debugging/refresh all plugins only.
	  - new cvar is homing missile allowed to target survivor if it idle( no damage done, its in cvar.. just for fun ).
	  - shield radius is now also the shield damage radius. probably cvar? but that dont make any sense to me.
	  -	added reset client if the player died
	  - Freeze/Unfreeze and player ability no longer interfere each other.
	  - new cvar animate healthbar from using medkit on/off.
	  - new cvar allow countdown hint message. this message kinda annoying.
	  - removed sprite follow player.
	  - beam sprite now hardcoded and changed to dorm looking type, old one annoying.
	  - new cvar allow witch drop luffy item.
	  - fixed the shield wont remove from world. << i forgot this guy was parented to player.
	  - updated bunce of varible poorly named and left bunch more. << i m out of sexy name. this rised my OCD level. no longer care :(
	  - removed the witch and common infected health check. this will crash the server.
	  - reinvented color system.. << now simplified and hardcoded.
	  - re-invented the model selection dice and ammobox dice. roll the dice ahead of time << we should have gained a small preformance improvement if i didnt re-invent new bug.
	  - new cvar missile allow golowing.
	  - added check for health animation will stop on ledge grab and continue after ledge revive succsess( untested ).
	  - added timer to remove the ammobox from world if no player pickup. Dont flood our server.
	  - added dash for the strength ability to make it less useless.
	  -	tried to address the issue where player get black screen death animation loop during shield active. << not much i can do other than make those player almost in god mode.
	  - added bool check for round end and force everything to terminate themself. hopefuly. this plugins grow even larger for me to stress test it on my own.
	  - i v decided there will be no wall check in between explosion and the target. we are done with the plugins size.
	  - no wall check between player shield and the target either. if you woke the witch next room on a narrow path, deal with it and good luck.
	  - re-invent the missile shooting function to easyly manipulate the desired direction and reuseablity.
	  - invented new function PCMasterRace_Render_ARGB() at 4K @260 fps for homing missile and airstrike. That right, you read that correctly, except the 4k things if your GC low end. :)
	  - reinvent the trace ray function for re-useability. useful to check wall and/or obstacle between 2 points in the future( if i change my mind somehow)
	  - 
	  - 
v 0.9 - plugins conversion.
	  - v0.9 still beta, probably will stay beta forever. no time to coding.
	  - added invalid value for -1. Not sure why should i.
	  - addressing array outbound inside timer
	  - corrected upgrade pack chat item name.
	  - luffy model changed for better solid type object. <<<== from Google translet.
	  - lyffy touch detection changed from distance to SDKHook.
	  - missile hit detection change to SDKHook.
	  - removed cvar weapon tear drop selection. dosent make any sense.
	  - passing serial to timer instead of index( index consider unsafe ).
	  - removed unnecessary client and entity check for preformance wise.
	  - added fail safe check. For example, an ability use 3 type of prop to make up
	    a single object, one fail in the creation chain will abort and reverse the proses
		by deleting the unfinish ability (i may oversight few leftover yet).
	  - correctecd rocket body and exaust wrong orientation;
	  - added new ability punishment.
	  - added new ability homing missile.
	  - some of the description for version v0.8 and below i typed 8 years ago turn out to be somewhat a lie.
	  - get rid of the weaponslot array that cause error. its unnecessary object store function plus stupid.
	  - rebuild missile firing sequence from player location to jet location. get rid of the multiple firing timer(its just stupid and expensive op).
	  - added sound for infected and witch hurt.
	  - custom model packed into vpk. plug and play. probably dosent comply with alliedmodder rule(source must be included uncompiled).
	  - added check if custom model not present, default l4d2 model will be loaded.
	  - fixed incorrect model file path causes model error ingame.
	  - 
	  - 
////////////////////////////////////////////////////////////
////// v0.8 Last edited by GsiX; 11-08-2012 at 03:29  //////
////////////////////////////////////////////////////////////
v 0.8 - improved item pick up condition.
	  - improved rocket.
	  - improved airstrike damage.
	  - add f18 model while launching air strike.
	  - added witch spawn limit.
	  - randomize between witch or lazer sight.
	  - added tank spawn limit.
	  - randomize between tank or explosive or incendiary.
	  - added new reward sound.
	  - added cvar for bot pick up.
	  - added shield.
	  - new sound.
	  - new model.
v 0.7 - little code cleanup.
	  - added ability summon airstrike.
	  - added item drop glowing.
	  - inproved visibility.
v 0.6 - update for luffy_rpg only.
v 0.5 - fixed weapon drop on empty ammo.
	  - added more weapon category.
v 0.4 - slight update.
v 0.3 - more update.
v 0.2 - addad beam spirit.
	  - change player colour more light.
	  - add cvar max HP regenerate.
	  - reset B&W on HP regen.
v 0.1 - fixed Luffy max spawn (Max 20).
	  - added 3 more model and more function.
v 0.0 - credit to Bacardi for the set parent problem.
	  - Credit to S-Slow for the awesome model.
	  - Credit to Powerload for the scrip explaination.
*/

///////////////// this is l4d2 ingame vanila model ////////////////
#define CLOCK_MDL			"models/props_fairgrounds/giraffe.mdl"
#define SPEED_MDL			"models/editor/air_node_hint.mdl"
#define POISON_MDL			"models/props_collectables/flower.mdl"
#define REGENHP_MDL			"models/props_collectables/mushrooms.mdl"
#define SHIELD_MDL			"models/props_fairgrounds/alligator.mdl"
#define STRENGTH_MDL		"models/props_fairgrounds/elephant.mdl"
#define GIFT_MDL			"models/items/l4d_gift.mdl"

//////////// this is custom model from the luffy_item.vpk ///////////
#define CLOCK_MDL2			"models/player/slow/amberlyn/sm_galaxy/star/slow.mdl"
#define SPEED_MDL2			"models/player/slow/amberlyn/sm_galaxy/star/slow_2.mdl"
#define POISON_MDL2			"models/player/slow/amberlyn/sm_galaxy/goomba/slow.mdl"
#define REGENHP_MDL2		"models/player/slow/amberlyn/sm_galaxy/life_mushroom/slow.mdl"
#define SHIELD_MDL2			"models/player/slow/amberlyn/sm_galaxy/koopa_troopa/slow.mdl"	//<< this guys wont scale
#define STRENGTH_MDL2		"models/props_fairgrounds/elephant.mdl"				//<< custom model except this one. i lost my chain chomp model :(
#define GIFT_MDL2			"models/player/slow/amberlyn/sm_galaxy/luma/slow.mdl"

/////////////////////////////////////////////////////////////
// incase you miss the old default l4d2 model .. its here. //
// replace file path from below to the #define l4d2 above. //
/////////////////////////////////////////////////////////////
// "models/editor/axis_helper_thick.mdl"
// "models/editor/air_node_hint.mdl"
// "models/editor/air_node.mdl"
// "models/editor/overlay_helper.mdl"
////////////////////////////////////////////////////////////

// dont replace this model below. its a default model.
#define JETF18_MDL				"models/f18/f18.mdl"							//<< the mother of all weapon + shield decoration. << dont change.
#define HOMING_MDL				"models/props_fairgrounds/mr_mustachio.mdl"		//<< this for homing missile base << you may change this, not critical.
#define	SDKHOOK_DMY				"models/props_fairgrounds/mr_mustachio.mdl"		//<< this for sdkhook dummy touch detection, wont visible ingame. << dont change this.

#define AMMO_MDL				"models/props/terror/ammo_stack.mdl"
#define RIOTSHIELD_MDL			"models/weapons/melee/w_riotshield.mdl"			// ability shield decoration model << i fall in love with this guy

#define REWARD_SND				"level/gnomeftw.wav"
#define HEALTH_SND				"ui/bigreward.wav"
#define SPEED_SND				"ui/pickup_guitarriff10.wav"
#define CLOCK_SND				"level/startwam.wav"
#define STRENGTH_SND			"ui/critical_event_1.wav"
#define SUPERSHIELD_SND			"ambient/alarms/klaxon1.wav"
#define TIMEOUT_SND				"ambient/machines/steam_release_2.wav"
#define TELEPOT_SND				"ui/menu_horror01.wav"
#define ZAP_1_SND				"ambient/energy/zap1.wav"
#define ZAP_2_SND				"ambient/energy/zap3.wav"
#define ZAP_3_SND				"ambient/energy/spark5.wav"
#define FREEZE_SND				"physics/glass/glass_impact_bullet4.wav"
#define AIRSTRIK1_SND			"npc/soldier1/misc05.wav"
#define AIRSTRIK2_SND			"npc/soldier1/misc06.wav"
#define AIRSTRIK3_SND			"npc/soldier1/misc10.wav"
#define JETPASS_SND				"animation/jets/jet_by_01_lr.wav"
#define TANK_SND				"player/tank/voice/attack/tank_attack_03.wav"
#define WITCH_SND				"npc/witch/voice/attack/female_distantscream1.wav"
#define AMMOPICKUP_SND			"sound/items/itempickup.wav"
#define GETHIT_SND				"sound/npc/infected/hit/hit_punch_02.wav"

#define MISSILE_DMY				"models/w_models/weapons/w_eq_molotov.mdl"		//<< our missile projectile dummy. dont change this
#define MISSILE_MDL				"models/missiles/f18_agm65maverick.mdl"
#define MISSILE1_SND			"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define MISSILE2_SND			"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_2.wav"

#define BEAMSPRITE_BLOOD		"materials/sprites/bloodspray.vmt"
#define BEAMSPRITE_BUBBLE		"materials/sprites/bubble.vmt"

#define SIZE_DROPBUFF			200		// array size for items drop tracking buffer
#define SIZE_ENTITYBUFF			2000	//<< array size too big. preformance inpact minimal.
										// (i do realize the existing of dynamic array but i m not willing to debug that :( << we are done here

// fine tune our missile
#define HOMING_HEIGHT_MIN		250.0	// min altitude vertical missile start to look for enemy << cvar probably???? no...
#define HOMING_EXPIRE			8.0		// if targeting rocket still survive longer than this, remove him from world.
#define HOMING_INTERVAL			0.5		// homing missile interval between missile shooting.
#define MISSILE_RADIUS			100.0	// missile damage radius and point push radius
#define MISSILE_TARGET_SPEED	1000.0	// targeting missile speed
#define MISSILE_IDLE_SPEED		200.0	// verticle idle missile speed

// fine tune our shield
#define SHIELD_RADIUS			70.0	// width opening of our shield also the damage radius effect.
#define SHIELD_PUSHSHIELD		300.0	// push value for the luffy shield ability
#define SHIELD_PUSHCLOCK		800.0	// push force for the luffy clock ability
#define SHIELD_DORM_RADIUS		200		// radius of our decoration/fake dorm shield
#define SHIELD_DORM_ALPHA		60		// color alpha of the fake dorm shield

// fine tune our strength midair dash/movement
#define DASH_FORCE				300.0	// force to propel player at desired direction during strength ability. << new problem.. he might chicken out and run to saferoom :(
#define DASH_HEIGHT				130.0	// only allow midair dash after reach this height.
#define STRENGTH_GRAVITY		0.3		// gravity mult for strength ability.

#define ANIMATION_COUNT			12		// play pickup animation this much to emulate small to big model. control the final animation size here.
#define AMMOBOX_LIFE			40.0	// ammobox stay on ground longer than this, remove him.

ConVar
g_ConVarLuffyEnable, g_ConVarLuffyChance, g_ConVarLuffyMax, g_ConVarSpeedCoolDown, g_ConVarClockCoolDown, g_ConVarStrengthCoolDown,
g_ConVarSpeedMax, g_ConVarMessage, g_ConVarHPregenMax, g_ConVarTankDrop, g_ConVarBotPickUp, g_ConVarBotDrop, g_ConVarItemGlow,
g_ConVarAirStrikeNum, g_ConVarHomingNum, g_ConVarMissaleSelf, g_ConVarMissaleDmg, g_ConVarTankDamage, g_ConVarItemStay, g_ConVarTankMax,
g_ConVarWitchMax, g_ConVarHinttext, g_ConVarShieldCoolDown, g_ConVarAmmoBoxUse, g_ConVarSuperShield, g_ConVarLifeSteal, g_ConVarShieldType,
g_ConVarAllowTargetSelf, g_ConVarAllowMedkitTweak, g_ConVarEnableCountdownMsg, g_ConVarWitchDrop, g_ConVarAllowPickAnime, g_ConVarAllowMissileColor;

bool
g_bLuffyEnable, g_bAllowMessage, g_bAllowTankDrop, g_bAllowBotPickUp, g_bAllowBotKillDrop, g_bAirStrikeSelf, g_bAllowTargetSelf,
g_bHinttext, g_bAllowAmmoboxTweak, g_bAllowHealAnimate, g_bAllowCountdownMsg, g_bAllowWitchDrop, g_bAllowPickupPlay, g_bAllowMissileColor;

int
g_iLuffyChance, g_iLuffySpawnMax, g_iSpeedCoolDown, g_iClockCoolDown, g_iStrengthCoolDown, g_iSuperSpeedMax,
g_iHPregenMax, g_iItemGlowType, g_iAirStrikeNum, g_iHomingNum, g_iHomeMissaleDmg, g_iTankDamage, g_iSuperShieldDamage,
g_iShieldType, g_iLifeStealAmount, g_iTankMax, g_iWitchMax, g_iShieldCoolDown;

float	g_fLuffyItemLife;

Handle	g_hT_ItemLifeSpawn[SIZE_ENTITYBUFF]		= { INVALID_HANDLE, ... };
Handle	g_hT_HealthRegen[MAXPLAYERS+1]			= { INVALID_HANDLE, ... };
Handle	g_hT_LuffySpeed[MAXPLAYERS+1]			= { INVALID_HANDLE, ... };
Handle	g_hT_LuffyStrength[MAXPLAYERS+1]		= { INVALID_HANDLE, ... };
Handle	g_hT_LuffyClock[MAXPLAYERS+1]			= { INVALID_HANDLE, ... };
Handle	g_hT_LuffyShield[MAXPLAYERS+1]			= { INVALID_HANDLE, ... };
Handle	g_hT_MoveFreeze[MAXPLAYERS+1]			= { INVALID_HANDLE, ... };
Handle	g_hT_AirStrike[MAXPLAYERS+1]			= { INVALID_HANDLE, ... };

bool	g_bAirStrikeBTN[MAXPLAYERS+1];
bool	g_bHomingBTN[MAXPLAYERS+1];
float	g_fHomingBaseHeight[SIZE_ENTITYBUFF]	= { 0.0, ... };
int		g_iHomingBaseOwner[SIZE_ENTITYBUFF]		= { INVALID_VALUE, ... };
int		g_iHomingBaseTarget[SIZE_ENTITYBUFF][SIZE_ENTITYBUFF];

int		g_iPlayerShield[MAXPLAYERS+1];
float	g_fAbilityCountdown[MAXPLAYERS+1]		= { 0.0, ... };
float	g_fClientTimeBuffer[MAXPLAYERS+1]		= { 0.0, ... };

int		g_iBeamSprite_Blood;
int		g_iBeamSprite_Bubble;

int		g_iWeaponDropBuffer[SIZE_DROPBUFF]		= { INVALID_VALUE, ... };
bool	g_bIsModelRandom[SIZE_ENTITYBUFF]		= { false, ... };
int		g_iCleintHPHealth[MAXPLAYERS+1]			= { 0, ... };
float	g_fCleintHPBuffer[MAXPLAYERS+1]			= { 0.0, ... };
int		g_iHintCountdown[MAXPLAYERS+1]			= { 0, ... };
int		g_iUnfreezCountdown[MAXPLAYERS+1]		= { 0, ... };
int		g_iClientMissile[MAXPLAYERS+1]			= { INVALID_VALUE, ... };
float	g_fLuffyLifeCounter[SIZE_ENTITYBUFF]	= { 0.0, ... };
bool	g_bIsRoundStart							= false;
int		g_iRandModelBff[SIZE_ENTITYBUFF][4];
int		g_iDrawDice[MAXPLAYERS+1][10];

int		g_iDropSelectionType[3];
int		g_iLuffyModelSelection[5];
int		g_iLuffySpawnCount						= 0;

char	g_sModelBuffer[10][128];
float	g_fModelScale[10];
bool	g_bSafeToRollNextDiceModel				= true;
bool	g_bIsParticlePrecached					= false;

float	g_fSkinAnimeScale[SIZE_ENTITYBUFF];		// buffer to store our pickup animation model scale
int		g_iSkinAnimeCount[SIZE_ENTITYBUFF];		// buffer to store our pickup animation count

bool	g_bIsPlayerHPInterrupted[MAXPLAYERS+1];
float	g_fDoubleDashTimeLast[MAXPLAYERS+1];
bool	g_bIsDoubleDashPaused[MAXPLAYERS+1];

char	g_sCURRENT_MAP[128];

////// debugging var only
bool	g_bDeveloperMode 	= false;		// if true = enable cheat for admin to use Air Strike and Homing Missile.. knock youself out.
bool	g_bBypassMissileCap	= false;		// if true, max number of missile cap 1000 bypassed. for debugging.
bool	g_bIsDebugMode		= false;		// if true, luffy drop body part, missile part and jet part highlighted. for debug.
bool	g_bShowDummyModel	= false;		// if true, sdkhook dummy will visible. for debug.



//////////////////////////////////////////////////////////////////////////////////////////////////////////
// if true, will precached custom model																	//
// (vpk must present in client addons folder aka the actual l4d2 addons game folder, not server folder).//
// if true but vpk addons not present, the game will automaticly precached the big red error model.		//
// if false, use default l4d2 model.																	//
//////////////////////////////////////////////////////////////////////////////////////////////////////////
bool g_bWithCustomModel = true;



public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= "GsiX",
	description	= "Si dead drop luffy item.",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?p=1819303#post1819303"
}

public void OnPluginStart()
{
	char plName[16];
	Format( plName, sizeof( plName ), "%s_version", PLUGIN_NAME );
	
	CreateConVar( plName, PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD );
	g_ConVarLuffyEnable			= CreateConVar( "l4d2_luffy_enabled",			"1",		"0:Off, 1:On,  Toggle plugin on/off", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarLuffyChance			= CreateConVar( "l4d2_luffy_chance",			"100",		"0% - 100%,  Chance SI drop luffy item.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarLuffyMax			= CreateConVar( "l4d2_luffy_max",				"6",		"Number of luffy item droped at once ( Max 20 Luffy ).", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarSpeedCoolDown		= CreateConVar( "l4d2_luffy_speed_cooldown",	"60",		"Time in seconds for Luffy Speed cool down.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarClockCoolDown		= CreateConVar( "l4d2_luffy_clock_cooldown",	"60",		"Time in seconds for Luffy Clock cool down.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarStrengthCoolDown	= CreateConVar( "l4d2_luffy_strength_cooldown",	"60",		"Time in seconds for Luffy Strength cool down.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarShieldCoolDown		= CreateConVar( "l4d2_luffy_shield_cooldown",	"60",		"Time in seconds for Luffy Shield cool down.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarSpeedMax			= CreateConVar( "l4d2_luffy_speedmax",			"100",		"0% - 100%, Max super speed added to normal speed.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarMessage				= CreateConVar( "l4d2_luffy_announce",			"1",		"0:Off, 1:On, Toggle announce to chat when Luffy item acquired.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarHPregenMax			= CreateConVar( "l4d2_luffy_regen_max",			"100",		"How much max HP we regenerate.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarTankDrop			= CreateConVar( "l4d2_luffy_tank_drop",			"1",		"0:Off, 1:On, If on tank will drop luffy item.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarBotPickUp			= CreateConVar( "l4d2_luffy_bot_pickup",		"0",		"0:Off, 1:On, If on Survivor Bot allowed to pick up Luffy item.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarBotDrop				= CreateConVar( "l4d2_luffy_bot_kill",			"1",		"0:Off, 1:On, If off, luffy item will not drop if SI killed by Survivor Bot.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarItemGlow			= CreateConVar( "l4d2_luffy_item_glow",			"6",		"0:off, 1:Light blue, 2:Pink, 3:Yellow, 4:Red, 5:Blue, 6:Random.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarAirStrikeNum		= CreateConVar( "l4d2_luffy_airstrike_num",		"100",		"How many air strike missile we launch ( Max=1000, This effect pc performance).", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarHomingNum			= CreateConVar( "l4d2_luffy_homing_num",		"100",		"How many homing missile we launch ( Max=1000, This effect pc performance).", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarMissaleSelf			= CreateConVar( "l4d2_luffy_airstrike_self",	"0",		"0:Off, 1:On, If on, missile allowed friendly fire.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarMissaleDmg			= CreateConVar( "l4d2_luffy_missile_damage",	"20",		"How much damage our missile done", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarTankDamage			= CreateConVar( "l4d2_luffy_tank_damage",		"60",		"How much damage our missile done to the Tank", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarItemStay			= CreateConVar( "l4d2_luffy_item_life",			"60",		"How long luffy item droped stay on the ground. Min: 10 sec, Max:300 sec.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarTankMax				= CreateConVar( "l4d2_luffy_tank_max",			"3",		"If number of Tank more than this, reward replaced with somting else.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarWitchMax			= CreateConVar( "l4d2_luffy_witch_max",			"6",		"If number of Witch more than this, reward replaced with somting else.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarHinttext			= CreateConVar( "l4d2_luffy_hint_msg",			"1",		"0:Off, 1:On, Toggel hint text announce", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarAmmoBoxUse			= CreateConVar( "l4d2_luffy_ammobox",			"1",		"0:Off, 1:On, Enable ammobox use", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarSuperShield			= CreateConVar( "l4d2_luffy_shield_damage",		"30",		"How much damage our shield done", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarLifeSteal			= CreateConVar( "l4d2_luffy_steal_health",		"5",		"Amout of life we gain if we kill SI during super strength.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarShieldType			= CreateConVar( "l4d2_luffy_shield_type",		"1",		"0:Shield follow body motion, 1:Shield allign to world plane", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarAllowTargetSelf		= CreateConVar( "l4d2_luffy_homing_self",		"0",		"0: Off, 1: On, Homing rocket may target Survivor if no other target found(no damage)", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarAllowMedkitTweak	= CreateConVar( "l4d2_luffy_medkit_tweak",		"1",		"0: Off, 1: On, Allow plugin to animate healthbar from Medkit use.)", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarEnableCountdownMsg	= CreateConVar( "l4d2_luffy_count_msg",			"0",		"0: Off, 1: On, If on and l4d2_luffy_announce is on, countdown hint will be display.)", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarWitchDrop			= CreateConVar( "l4d2_luffy_witch_drop",		"1",		"0: Off, 1: On, Allow witch death drop luffy item.)", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarAllowPickAnime		= CreateConVar( "l4d2_luffy_animepickup",		"1",		"0: Off, 1: On, If on, play pick up animation when pickup luffy item.)", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarAllowMissileColor	= CreateConVar( "l4d2_luffy_missile_color",		"1",		"0: Off, 1: On, If on, missile get color base on l4d2_luffy_item_glow.)", FCVAR_SPONLY|FCVAR_NOTIFY);
	AutoExecConfig( true, PLUGIN_NAME );
	
	HookEvent( "round_start",			EVENT_RoundStart );
	HookEvent( "round_end",				EVENT_RoundEnd );
	HookEvent( "map_transition",		EVENT_RoundEnd );
	HookEvent( "player_death",			EVENT_PlayerDeath,			EventHookMode_Post );
	HookEvent( "player_hurt",			EVENT_PlayerHurt,			EventHookMode_Post );
	HookEvent( "infected_hurt",			EVENT_InfectedHurt,			EventHookMode_Post );
	HookEvent( "witch_killed",			EVENT_WitchDeath,			EventHookMode_Post );
	HookEvent( "player_team",			EVENT_PlayerSpawn );
	HookEvent( "player_spawn",			EVENT_PlayerSpawn );
	HookEvent( "heal_begin",			EVENT_HealBegin,			EventHookMode_Post );
	HookEvent( "heal_success",			EVENT_HealSuccess,			EventHookMode_Post );
	HookEvent( "player_use",			EVENT_PlayerUse,			EventHookMode_Post );
	HookEvent( "survivor_rescued",		EVENT_SurvivorRescued );
	HookEvent( "upgrade_pack_used",		EVENT_UpgradePackUsed );
	HookEvent( "upgrade_pack_added",	EVENT_UpgradePackAdded );
	HookEvent( "revive_success",		EVENT_ReviveSuccsess );
	
	g_ConVarLuffyEnable.AddChangeHook( CVAR_Changed );
	g_ConVarLuffyChance.AddChangeHook( CVAR_Changed );
	g_ConVarLuffyMax.AddChangeHook( CVAR_Changed );
	g_ConVarSpeedCoolDown.AddChangeHook( CVAR_Changed );
	g_ConVarClockCoolDown.AddChangeHook( CVAR_Changed );
	g_ConVarStrengthCoolDown.AddChangeHook( CVAR_Changed );
	g_ConVarShieldCoolDown.AddChangeHook( CVAR_Changed );
	g_ConVarSpeedMax.AddChangeHook( CVAR_Changed );
	g_ConVarMessage.AddChangeHook( CVAR_Changed );
	g_ConVarHPregenMax.AddChangeHook( CVAR_Changed );
	g_ConVarTankDrop.AddChangeHook( CVAR_Changed );
	g_ConVarBotPickUp.AddChangeHook( CVAR_Changed );
	g_ConVarBotDrop.AddChangeHook( CVAR_Changed );
	g_ConVarItemGlow.AddChangeHook( CVAR_Changed );
	g_ConVarAirStrikeNum.AddChangeHook( CVAR_Changed );
	g_ConVarHomingNum.AddChangeHook( CVAR_Changed );
	g_ConVarMissaleSelf.AddChangeHook( CVAR_Changed );
	g_ConVarMissaleDmg.AddChangeHook( CVAR_Changed );
	g_ConVarTankDamage.AddChangeHook( CVAR_Changed );
	g_ConVarItemStay.AddChangeHook( CVAR_Changed );
	g_ConVarTankMax.AddChangeHook( CVAR_Changed );
	g_ConVarWitchMax.AddChangeHook( CVAR_Changed );
	g_ConVarHinttext.AddChangeHook( CVAR_Changed );
	g_ConVarAmmoBoxUse.AddChangeHook( CVAR_Changed );
	g_ConVarSuperShield.AddChangeHook( CVAR_Changed );
	g_ConVarLifeSteal.AddChangeHook( CVAR_Changed );
	g_ConVarShieldType.AddChangeHook( CVAR_Changed );
	g_ConVarAllowTargetSelf.AddChangeHook( CVAR_Changed );
	g_ConVarAllowMedkitTweak.AddChangeHook( CVAR_Changed );
	g_ConVarEnableCountdownMsg.AddChangeHook( CVAR_Changed );
	g_ConVarWitchDrop.AddChangeHook( CVAR_Changed );
	g_ConVarAllowPickAnime.AddChangeHook( CVAR_Changed );
	g_ConVarAllowMissileColor.AddChangeHook( CVAR_Changed );
	
	RegAdminCmd( "luffy_bazoka",	AdminMissileCheat,	ADMFLAG_ROOT );
	RegAdminCmd( "luffy_model",		AdminModelSpawn,	ADMFLAG_ROOT );
	RegAdminCmd( "luffy_ability",	AdminCheatAbility,	ADMFLAG_ROOT );
	RegAdminCmd( "luffy_reload",	AdminReloadMap,		ADMFLAG_ROOT );
	
	UpdateCVar();
}

public void OnConfigsExecuted()
{
	UpdateCVar();
}

public void OnMapStart()
{
	g_bIsParticlePrecached = false;
	CreateTimer( 0.1, Timer_PrecacheModel );
}

/// if you change the model to your own liking... each model scaled individualy in here.
public Action Timer_PrecacheModel( Handle timer, any data ) //<< ok
{
	int count_mdl = 0;
	if( g_bWithCustomModel )
	{
		if( PrecacheModel( CLOCK_MDL2 ) > 0 ) { count_mdl += 1; }
		g_fModelScale[POS_CLOCK] = 1.2;
		Format( g_sModelBuffer[POS_CLOCK], sizeof( g_sModelBuffer[] ), CLOCK_MDL2 );
		
		if( PrecacheModel( SPEED_MDL2 ) > 0 ) { count_mdl += 1; }
		g_fModelScale[POS_SPEED] = 1.0;
		Format( g_sModelBuffer[POS_SPEED], sizeof( g_sModelBuffer[] ), SPEED_MDL2 );
		
		if( PrecacheModel( POISON_MDL2 ) > 0 ) { count_mdl += 1; }
		g_fModelScale[POS_POISON] = 0.7;
		Format( g_sModelBuffer[POS_POISON], sizeof( g_sModelBuffer[] ), POISON_MDL2 );
		
		if( PrecacheModel( REGENHP_MDL2 ) > 0 ) { count_mdl += 1; }
		g_fModelScale[POS_REGEN] = 1.0;
		Format( g_sModelBuffer[POS_REGEN], sizeof( g_sModelBuffer[] ), REGENHP_MDL2 );
		
		if( PrecacheModel( SHIELD_MDL2 ) > 0 ) { count_mdl += 1; }
		g_fModelScale[POS_SHIELD] = 1.0;
		Format( g_sModelBuffer[POS_SHIELD], sizeof( g_sModelBuffer[] ), SHIELD_MDL2 );
		
		if( PrecacheModel( STRENGTH_MDL2 ) > 0 ) { count_mdl += 1; }
		g_fModelScale[POS_STRENGTH] = 1.0;
		Format( g_sModelBuffer[POS_STRENGTH], sizeof( g_sModelBuffer[] ), STRENGTH_MDL2 );
		
		if( PrecacheModel( GIFT_MDL2 ) > 0 ) { count_mdl += 1; }
		g_fModelScale[POS_GIFT] = 1.2;
		Format( g_sModelBuffer[POS_GIFT], sizeof( g_sModelBuffer[] ), GIFT_MDL2 );
		
		PrintToServer( "" );
		PrintToServer( "|LUFFY| Custom Luffy Model Precached |LUFFY|" );
		PrintToServer( "" );

	}
	else
	{
		if( PrecacheModel( CLOCK_MDL ) > 0 ) { count_mdl += 1; }
		g_fModelScale[POS_CLOCK] = 1.0;
		Format( g_sModelBuffer[POS_CLOCK], sizeof( g_sModelBuffer[] ), CLOCK_MDL );
		
		if( PrecacheModel( SPEED_MDL ) > 0 ) { count_mdl += 1; }
		g_fModelScale[POS_SPEED] = 1.0;
		Format( g_sModelBuffer[POS_SPEED], sizeof( g_sModelBuffer[] ), SPEED_MDL );
		
		if( PrecacheModel( POISON_MDL ) > 0 ) { count_mdl += 1; }
		g_fModelScale[POS_POISON] = 2.5;
		Format( g_sModelBuffer[POS_POISON], sizeof( g_sModelBuffer[] ), POISON_MDL );
		
		if( PrecacheModel( REGENHP_MDL ) > 0 ) { count_mdl += 1; }
		g_fModelScale[POS_REGEN] = 3.0;
		Format( g_sModelBuffer[POS_REGEN], sizeof( g_sModelBuffer[] ), REGENHP_MDL );
		
		if( PrecacheModel( SHIELD_MDL ) > 0 ) { count_mdl += 1; }
		g_fModelScale[POS_SHIELD] = 1.0;
		Format( g_sModelBuffer[POS_SHIELD], sizeof( g_sModelBuffer[] ), SHIELD_MDL );
		
		if( PrecacheModel( STRENGTH_MDL ) > 0 ) { count_mdl += 1; }
		g_fModelScale[POS_STRENGTH] = 1.0;
		Format( g_sModelBuffer[POS_STRENGTH], sizeof( g_sModelBuffer[] ), STRENGTH_MDL );
		
		if( PrecacheModel( GIFT_MDL ) > 0 ) { count_mdl += 1; }
		g_fModelScale[POS_GIFT] = 1.0;
		Format( g_sModelBuffer[POS_GIFT], sizeof( g_sModelBuffer[] ), GIFT_MDL );
		
		PrintToServer( "" );
		PrintToServer( "|LUFFY| Switched To Default L4D2 Model |LUFFY|" );
		PrintToServer( "" );
	}
	
	if( PrecacheModel( HOMING_MDL ) > 0 ) { count_mdl += 1; }
	g_fModelScale[POS_HOMING] = 1.4;
	Format( g_sModelBuffer[POS_HOMING], sizeof( g_sModelBuffer[] ), HOMING_MDL );
	
	if( PrecacheModel( JETF18_MDL ) > 0 ) { count_mdl += 1; }
	g_fModelScale[POS_JETF18] = 0.05;
	Format( g_sModelBuffer[POS_JETF18], sizeof( g_sModelBuffer[] ), JETF18_MDL );

	if( PrecacheModel( SDKHOOK_DMY ) > 0 ) { count_mdl += 1; }
	g_fModelScale[POS_SDKHOOK] = 1.0;
	Format( g_sModelBuffer[POS_SDKHOOK], sizeof( g_sModelBuffer[] ), SDKHOOK_DMY );
	
	if( PrecacheModel( AMMO_MDL ) > 0 ) { count_mdl += 1; }
	if( PrecacheModel( RIOTSHIELD_MDL ) > 0 ) { count_mdl += 1; }
	
	if( PrecacheModel( MISSILE_DMY ) > 0 ) { count_mdl += 1; }
	if( PrecacheModel( MISSILE_MDL ) > 0 ) { count_mdl += 1; }
	if( PrecacheModel( PARTICLE_CREATEFIRE ) > 0 ) { count_mdl += 1; }

	g_iBeamSprite_Blood	= PrecacheModel( BEAMSPRITE_BLOOD );
	if( g_iBeamSprite_Blood > 0 ) { count_mdl += 1; }
	
	g_iBeamSprite_Bubble	= PrecacheModel( BEAMSPRITE_BUBBLE );
	if( g_iBeamSprite_Bubble > 0 ) { count_mdl += 1; }
	
	int count_snd = 0;
	if( PrecacheSound( REWARD_SND, true )) { count_snd += 1; }
	if( PrecacheSound( HEALTH_SND, true )) { count_snd += 1; }
	if( PrecacheSound( SPEED_SND, true )) { count_snd += 1; }
	if( PrecacheSound( CLOCK_SND, true )) { count_snd += 1; }
	if( PrecacheSound( STRENGTH_SND, true )) { count_snd += 1; }
	if( PrecacheSound( TIMEOUT_SND, true )) { count_snd += 1; }
	if( PrecacheSound( TELEPOT_SND, true )) { count_snd += 1; }
	if( PrecacheSound( ZAP_1_SND, true )) { count_snd += 1; }
	if( PrecacheSound( ZAP_2_SND, true )) { count_snd += 1; }
	if( PrecacheSound( ZAP_3_SND, true )) { count_snd += 1; }
	if( PrecacheSound( FREEZE_SND, true )) { count_snd += 1; }
	if( PrecacheSound( AIRSTRIK1_SND, true )) { count_snd += 1; }
	if( PrecacheSound( AIRSTRIK2_SND, true )) { count_snd += 1; }
	if( PrecacheSound( AIRSTRIK3_SND, true )) { count_snd += 1; }
	if( PrecacheSound( MISSILE1_SND, true )) { count_snd += 1; }
	if( PrecacheSound( MISSILE2_SND, true )) { count_snd += 1; }
	if( PrecacheSound( JETPASS_SND, true )) { count_snd += 1; }
	if( PrecacheSound( TANK_SND, true )) { count_snd += 1; }
	if( PrecacheSound( WITCH_SND, true )) { count_snd += 1; }
	if( PrecacheSound( SUPERSHIELD_SND, true )) { count_snd += 1; }
	if( PrecacheSound( AMMOPICKUP_SND, true )) { count_snd += 1; }
	
	if( PrecacheSound( GETHIT_SND, true )) { count_snd += 1; }
	
	if( g_bIsDebugMode )
	{
		if( count_mdl < 17 )
		{
			PrintToServer( "" );
			PrintToServer( "|LUFFY| Error Precache model | less %d model |LUFFY|", ( 17 - count_mdl ));
			PrintToServer( "" );
		}
		else
		{
			PrintToServer( "|LUFFY| All Models Precached Succsessfuly |LUFFY|" );
		}
		
		if( count_snd < 22 )
		{
			PrintToServer( "" );
			PrintToServer( "|LUFFY| Error Precache sound | less %d sound |LUFFY|", ( 22 - count_snd ));
			PrintToServer( "" );
		}
		else
		{
			PrintToServer( "|LUFFY| All Sound Precached Succsessfuly |LUFFY|" );
		}
	}
	
	// scramble our selection dice buffer. This dont really give random but still better choice.
	float interval = 0.0;
	for( int i = 0; i < sizeof( g_iLuffyModelSelection ); i++ )
	{
		CreateTimer( interval, Timer_ScrambleModelSelectionDice, 0 );
		interval += 0.1;
	}
}

public void CVAR_Changed( Handle convar, const char[] oldValue, const char[] newValue ) //<< ok
{
	UpdateCVar();
	
	// in theory this will bug the luffy item, timer and bunch more if the plugins is disabled in the middle of the game.
	// dont care... its a massive headache.. do it on your own risk. or why would you want to do this in the middle of the game anyway.
	if ( !g_bLuffyEnable ) 	
	{
		/*
		for ( int  i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidSurvivor( i ))
			{
				ResetLuffyAbility( i );
			}
		}*/
		
		g_bIsRoundStart = false;	//<< this check help all active timer to kill themself if the plugin disable in midgame. The least i can do to fix things
	}
}

void UpdateCVar()	//<< ok
{
	g_bLuffyEnable			= g_ConVarLuffyEnable.BoolValue;
	g_iLuffyChance			= g_ConVarLuffyChance.IntValue;
	g_iLuffySpawnMax		= g_ConVarLuffyMax.IntValue;
	g_iSpeedCoolDown		= g_ConVarSpeedCoolDown.IntValue;
	g_iClockCoolDown		= g_ConVarClockCoolDown.IntValue;
	g_iStrengthCoolDown		= g_ConVarStrengthCoolDown.IntValue;
	g_iShieldCoolDown		= g_ConVarShieldCoolDown.IntValue;
	g_iSuperSpeedMax		= g_ConVarSpeedMax.IntValue;
	g_bAllowMessage			= g_ConVarMessage.BoolValue;
	g_iHPregenMax			= g_ConVarHPregenMax.IntValue;
	g_bAllowTankDrop		= g_ConVarTankDrop.BoolValue;
	g_bAllowBotPickUp		= g_ConVarBotPickUp.BoolValue;
	g_bAllowBotKillDrop		= g_ConVarBotDrop.BoolValue;
	g_iItemGlowType			= g_ConVarItemGlow.IntValue;
	g_iAirStrikeNum			= g_ConVarAirStrikeNum.IntValue;
	g_iHomingNum			= g_ConVarHomingNum.IntValue;
	g_bAirStrikeSelf		= g_ConVarMissaleSelf.BoolValue;
	g_iHomeMissaleDmg		= g_ConVarMissaleDmg.IntValue;
	g_iTankDamage			= g_ConVarTankDamage.IntValue;
	g_fLuffyItemLife		= g_ConVarItemStay.FloatValue;
	g_iTankMax				= g_ConVarTankMax.BoolValue;
	g_iWitchMax				= g_ConVarWitchMax.IntValue;
	g_bHinttext				= g_ConVarHinttext.BoolValue;
	g_bAllowAmmoboxTweak	= g_ConVarAmmoBoxUse.BoolValue;
	g_iSuperShieldDamage	= g_ConVarSuperShield.IntValue;
	g_iLifeStealAmount		= g_ConVarLifeSteal.IntValue;
	g_iShieldType			= g_ConVarShieldType.IntValue;
	g_bAllowTargetSelf		= g_ConVarAllowTargetSelf.BoolValue;
	g_bAllowHealAnimate		= g_ConVarAllowMedkitTweak.BoolValue;
	g_bAllowCountdownMsg	= g_ConVarEnableCountdownMsg.BoolValue;
	g_bAllowWitchDrop		= g_ConVarWitchDrop.BoolValue;
	g_bAllowPickupPlay		= g_ConVarAllowPickAnime.BoolValue;
	g_bAllowMissileColor	= g_ConVarAllowMissileColor.BoolValue;
}

public Action AdminMissileCheat( int client, any args ) //<< ok	 <<<<<========= admin cheat command.. intended for testing. Now leave it here.
{
	if ( IsValidSurvivor( client ) && g_bDeveloperMode )
	{
		g_bAirStrikeBTN[client]	= true;
		g_bHomingBTN[client] 	= true;
		switch( GetRandomInt( 1, 3 ))
		{
			case 1:
			{
				EmitSoundToClient( client, AIRSTRIK1_SND );
			}
			case 2:
			{
				EmitSoundToClient( client, AIRSTRIK2_SND );
			}
			case 3:
			{
				EmitSoundToClient( client, AIRSTRIK3_SND );
			}
		}
		PrintHintText( client, "++ Press 'RELOAD + FIRE' to launch Air Strike ++" );
	}
	return Plugin_Handled;
}

public Action AdminModelSpawn( int client, any args ) //<< ok	 <<<<<========= admin spawn command to test spawn model..
{
	if ( IsValidSurvivor( client ) && g_bDeveloperMode )
	{
		// Show client usage explanation if args less than 2
		if ( args < 2 )
		{
			ReplyToCommand( client, "[LUFFY]: Usage: luffy_model 1 3" );
			ReplyToCommand( client, "[LUFFY]: luffy_model 1(model type) 3(life = how long it stay on ground)" );
			return Plugin_Handled;
		}
		
		// Get first arg
		char arg1[8];
		GetCmdArg( 1, arg1, sizeof( arg1 ));
		int type = StringToInt( arg1 );
		
		int size = sizeof( g_sModelBuffer ) - 1;
		if( type < 0 || type > size )
		{
			ReplyToCommand( client, "[LUFFY]: valid model index >= 0 and index <= %d", size );
			return Plugin_Handled;
		}
		
		char arg2[8];
		GetCmdArg( 2, arg2, sizeof( arg2 ));
		float life = StringToFloat( arg2 );
		if( life < 1.0 || life > 120.0 )
		{
			ReplyToCommand( client, "[LUFFY]: second Args between 1 secs to 120 secs" );
			return Plugin_Handled;
		}
		
		float pos_start[3];
		float ang_start[3];
		float pos_end[3];
		
		GetClientEyePosition( client, pos_start );
		GetClientEyeAngles( client, ang_start );
		bool gotpos = TraceRayGetEndpoint( pos_start, ang_start, client, pos_end );
		if( gotpos )
		{
			pos_end[2] += 20.0;
			ang_start[0] = 0.0;
			int dummy	= CreatEntRenderModel( PROPTYPE_DYNAMIC, g_sModelBuffer[type], pos_end, ang_start, g_fModelScale[type] );
			if ( dummy != INVALID_VALUE )
			{
				PrintToChat( client, "[LUFFY]: Model spawn succsess..!!" );
				PrintToChat( client, "** %s **", g_sModelBuffer[type] );
				CreateTimer( 0.1, Timer_TestRotate, EntIndexToEntRef( dummy ), TIMER_REPEAT );
				CreateTimer( life, Timer_DeletIndex, EntIndexToEntRef( dummy ));
			}
		}
	}
	return Plugin_Handled;
}

public Action Timer_TestRotate( Handle timer, any entref ) //<< ok
{
	int ent = EntRefToEntIndex( entref );
	if( ent > MaxClients && IsValidEntity( ent ) && g_bIsRoundStart )
	{
		float ang[3];
		GetEntAngle( ent, ang, 20.0, AXIS_YAW );
		TeleportEntity( ent, NULL_VECTOR, ang, NULL_VECTOR );
		//PrintToChatAll( "ang[0]: %f | ang[1]: %f | ang[2]: %f", ang[0], ang[1], ang[2] );
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

public Action Timer_DeletIndex( Handle timer, any entref )		//<< ok
{
	int entity = GetEntIndex_IsValid( entref );
	if( entity > MaxClients && IsValidEntity( entity ))
	{
		AcceptEntityInput( entity, "Kill" );
	}
}

public Action AdminCheatAbility( int client, any args ) //<< ok	 <<<<<========= admin cheat command to get instant ability..
{
	if ( IsValidSurvivor( client ) && g_bDeveloperMode )
	{
		// Show client usage explanation if args less than 2
		if ( args < 1 )
		{
			ReplyToCommand( client, "[LUFFY]: Usage: luffy_ability 1(ability type)" );
			ReplyToCommand( client, "ability type: 1=Clock, 2=Speed, 3=Shield, 4=Strength, 5=Health, 6=Punishment" );
			return Plugin_Handled;
		}
		
		// Get first arg
		char arg1[8];
		GetCmdArg( 1, arg1, sizeof( arg1 ));
		int type = StringToInt( arg1 );
		if( type < 1 || type > 7 )
		{
			ReplyToCommand( client, "[LUFFY]: ability type: 1=Clock, 2=Speed, 3=Shield, 4=Strength, 5=Health, 6=Punishment, 7=Freeze" );
			return Plugin_Handled;
		}
		
		if( type == 1 )
		{
			if( g_fAbilityCountdown[client] == 0.0 )
			{
				RunLuffyClock( client );
				return Plugin_Handled;
			}
		}
		else if( type == 2 )
		{
			if( g_fAbilityCountdown[client] == 0.0 )
			{
				RunLuffySpeed( client );
				return Plugin_Handled;
			}
		}
		else if( type == 3 )
		{
			if( g_fAbilityCountdown[client] == 0.0 )
			{
				RunLuffyShield( client );
				return Plugin_Handled;
			}
		}
		else if( type == 4 )
		{
			if( g_fAbilityCountdown[client] == 0.0 )
			{
				RunLuffyStrength( client );
				return Plugin_Handled;
			}
		}
		else if( type == 5 )
		{
			if( g_hT_HealthRegen[client] == INVALID_HANDLE )
			{
				RunLuffyHealth( client );
				return Plugin_Handled;
			}
		}
		else if( type == 6 )
		{
			RunLuffyPunishment( client );
			return Plugin_Handled;
		}
		else if( type == 7 )
		{
			RunFreezeClient( client );
			return Plugin_Handled;
		}
		
		if( type > 0 && type < 6 )
		{
			if( g_hT_LuffyClock[client] != INVALID_HANDLE )
			{
				ReplyToCommand( client, "[LUFFY]: Luffy Clock still active.." );
			}
			else if( g_hT_LuffySpeed[client] != INVALID_HANDLE )
			{
				ReplyToCommand( client, "[LUFFY]: Luffy Speed still active.." );
			}
			else if( g_hT_LuffyShield[client] != INVALID_HANDLE )
			{
				ReplyToCommand( client, "[LUFFY]: Luffy Shield still active.." );
			}
			else if( g_hT_LuffyStrength[client] != INVALID_HANDLE )
			{
				ReplyToCommand( client, "[LUFFY]: Luffy Strength still active.." );
			}
			else
			{
				ReplyToCommand( client, "[LUFFY]: You should not see this message" );
			}
		}
	}
	return Plugin_Handled;
}

public Action AdminReloadMap( int client, any args ) //<< ok	 <<<<<========= admin command to reload the map, also for me to refresh plugins..
{
	if ( IsValidSurvivor( client ))
	{
		g_bIsRoundStart = false;
		ReplyToCommand( client, "\x01[LUFFY]: Reloading \x05%s \x01in 3 secs", g_sCURRENT_MAP );
		CreateTimer( 3.0, Timer_RestartServer, _ );
	}
}

public Action Timer_RestartServer( Handle timer, any userid ) //<< ok
{
	ServerCommand( "changelevel %s", g_sCURRENT_MAP );
}

public void EVENT_RoundStart ( Event event, const char[] name, bool dontBroadcast ) //<< ok
{
	g_bIsRoundStart = true;	//<< dont move this. its here in case user changing cvar in midgame << i suppost it create bug if uncheck.
	
	if ( !g_bLuffyEnable ) return;
	
	g_bSafeToRollNextDiceModel = true;
	
	GetCurrentMap( g_sCURRENT_MAP, sizeof( g_sCURRENT_MAP ));
	
	g_iLuffySpawnCount = 0;

	int j;
	for( int i = 0; i < SIZE_ENTITYBUFF; i++ )
	{
		g_hT_ItemLifeSpawn[i]		= INVALID_HANDLE;
		g_fHomingBaseHeight[i]		= 0.0;
		g_bIsModelRandom[i]			= false;
		g_fLuffyLifeCounter[i]		= 0.0;
		g_iRandModelBff[i][0]		= 0;
		g_iRandModelBff[i][1]		= 0;
		g_iRandModelBff[i][2]		= 0;
		g_iRandModelBff[i][3]		= 0;
		
		if ( i < SIZE_DROPBUFF )
		{
			g_iWeaponDropBuffer[i]	= INVALID_VALUE;
		}
		
		if ( i <= MAXPLAYERS )
		{
			g_iPlayerShield[i]		= INVALID_VALUE;
			g_iClientMissile[i]		= INVALID_VALUE;
			g_iHintCountdown[i]		= 0;
			g_iCleintHPHealth[i]	= 0;
			g_fCleintHPBuffer[i]	= 0.0;
			g_bAirStrikeBTN[i]		= false;
			g_bHomingBTN[i]			= false;
			g_hT_HealthRegen[i]		= INVALID_HANDLE;
			g_hT_LuffyClock[i]		= INVALID_HANDLE;
			g_hT_LuffyShield[i]		= INVALID_HANDLE;
			g_hT_LuffySpeed[i]		= INVALID_HANDLE;
			g_hT_LuffyStrength[i]	= INVALID_HANDLE;
			g_hT_MoveFreeze[i]		= INVALID_HANDLE;
		}
		
		for( j = 0; j < SIZE_ENTITYBUFF; j++ )
		{
			g_iHomingBaseTarget[i][j] = INVALID_VALUE;
		}
	}
}

public void EVENT_RoundEnd( Event event, const char[] name, bool dontBroadcast ) //<< ok
{
	g_bIsRoundStart = false;
	
	if ( !g_bLuffyEnable ) return;
	/*
	for( int  i = 1; i <= MaxClients; i++ )
	{
		if ( IsValidSurvivor( i ))
		{
			ResetLuffyAbility( i );
		}
	}
	*/
}

public void EVENT_PlayerSpawn( Event event, const char[] name, bool dontBroadcast ) //<< ok
{
	if ( !g_bLuffyEnable ) return;
	
	int userid = event.GetInt( "userid" );
	int client = GetClientOfUserId( userid );
	if ( IsValidSurvivor( client ))
	{
		g_bAirStrikeBTN[client]			= false;
		g_bHomingBTN[client] 			= false;
		g_hT_AirStrike[client]			= INVALID_HANDLE;
		g_hT_HealthRegen[client]		= INVALID_HANDLE;
		ResetLuffyAbility( client );
		FreezePlayerButton( client, false );
		
		if( !g_bIsParticlePrecached )
		{
			g_bIsParticlePrecached = true;
			CreateTimer( 0.0, Timer_PrecacheEntity, userid );
		}
	}
}

public Action Timer_PrecacheEntity( Handle timer, any data ) //<< ok
{
	int client = GetClientIndex( data, true );
	if( IsValidSurvivor( client ))
	{
		int count_prt = 0;
		bool missileshoot = false;

		float pos1[3];
		float pos2[3];
		GetEntOrigin( client, pos1, 3000.0 );
		GetEntOrigin( client, pos2, 5000.0 );
		
		if( CreatPointDamageRadius( pos1, PARTICLE_CREATEFIRE, 0, 0, -1 )) { count_prt += 1; }
		if( CreatePointParticle( pos1, PARTICLE_EXPLOSIVE, 0.1 )) { count_prt += 1; }
		if( CreatePointParticle( pos1, PARTICLE_ELECTRIC1, 0.1 )) { count_prt += 1; }
		if( CreatePointParticle( pos1, PARTICLE_ELECTRIC2, 0.1 )) { count_prt += 1; }
		
		int missile = CreateMissileProjectile( INVALID_VALUE, pos1, pos2 );
		if( missile != INVALID_VALUE )
		{
			ChangeDirectionAndShoot( missile, pos2, MISSILE_TARGET_SPEED, -90.0 ); //-90.0 is the molotov body pitch correction
			CreateTimer( 1.0, Timer_MissileExplode, EntIndexToEntRef( missile ));
			missileshoot = true;
		}
		
		if( g_bIsDebugMode )
		{
			if( count_prt < 4 )
			{
				PrintToServer( "" );
				PrintToServer( "|LUFFY| Error Precache particle | less %d particle |LUFFY|", ( 4 - count_prt ));
				PrintToServer( "" );
			}
			else
			{
				PrintToServer( "|LUFFY| All Particle Precached Succsessfuly |LUFFY|" );
			}
			
			if( missileshoot )
			{
				PrintToServer( "|LUFFY| Missile has beed precached :) |LUFFY|" );
			}
		}
	}
}

public void EVENT_SurvivorRescued( Event event, const char[] name, bool dontBroadcast ) //<< ok
{
	if ( !g_bLuffyEnable ) return;
	
	int  client = GetClientOfUserId( event.GetInt( "victim" ));
	if ( IsValidSurvivor( client ))
	{
		g_bAirStrikeBTN[client]			= false;
		g_bHomingBTN[client] 			= false;
		g_hT_AirStrike[client]			= INVALID_HANDLE;
		g_hT_HealthRegen[client]		= INVALID_HANDLE;
		ResetLuffyAbility( client );
		FreezePlayerButton( client, false );
	}
}

public void EVENT_PlayerDeath( Event event, const char[] name, bool dontBroadcast ) //<< ok
{
	if ( !g_bLuffyEnable ) return;

	int  badguy = GetClientOfUserId( event.GetInt( "userid" ));
	if ( IsValidInfected( badguy ))
	{
		int  attacker = GetClientOfUserId( event.GetInt( "attacker" ));
		if( IsValidSurvivor( attacker ))
		{
			if( ( IsFakeClient( attacker ) && !g_bAllowBotKillDrop ))
			{
				return;
			}
			
			// life steal during super strength.
			if ( g_hT_LuffyStrength[attacker] != INVALID_HANDLE )
			{
				float bff[3];
				float pos[3];
				GetEntOrigin( badguy, pos, 10.0 );
				
				for( int i = 1; i <= 5; i++ )
				{
					CopyArray3DF( pos, bff );
					bff[0] + GetRandomFloat( -50.0, 50.0 );
					bff[1] + GetRandomFloat( -50.0, 50.0 );
					CreatePointParticle( bff, PARTICLE_ELECTRIC1, 0.2 );
					
					CopyArray3DF( pos, bff );
					bff[0] + GetRandomFloat( -50.0, 50.0 );
					bff[1] + GetRandomFloat( -50.0, 50.0 );
					CreatePointParticle( bff, PARTICLE_ELECTRIC2, 0.2 );
				}
				switch( GetRandomInt( 1, 3 )) {
					case 1: {
						EmitSoundToAll( ZAP_1_SND, badguy, SNDCHAN_AUTO );
					}
					case 2: {
						EmitSoundToAll( ZAP_2_SND, badguy, SNDCHAN_AUTO );
					}
					case 3: {
						EmitSoundToAll( ZAP_3_SND, badguy, SNDCHAN_AUTO );
					}
				}
				
				int health	= GetPlayerHealth( attacker ) + g_iLifeStealAmount;
				if( health > 100 )
				{
					health = 100;					// make sure our healt plus stolen health dont exceed 100.
				}
				
				float buffer = GetPlayerHealthBuffer( attacker );
				float newbuff = float(health) + buffer;
				if( newbuff > 100.0 )				// make sure our healt plus buffer dont exceed 100.
				{
					newbuff = 100.0 - float(health);
				}
				SetPlayerHealth( attacker, health );
				SetPlayerHealthBuffer( attacker, newbuff );
			}
		}


		if ( GetZclass( badguy ) == ZOMBIE_TANK && !g_bAllowTankDrop )
		{
			return;
		}

		// we only roll 1 model dice at a time because we have a while loop in a timer
		// if not safe to roll, consider this kill a waste.
		if( g_bSafeToRollNextDiceModel && g_iLuffySpawnCount < g_iLuffySpawnMax )
		{
			RollLuffyDropDice( badguy );
		}
	}
}

public void EVENT_WitchDeath( Event event, const char[] name, bool dontBroadcast ) //<< ok
{
	if ( !g_bLuffyEnable || !g_bAllowWitchDrop ) return;

	int witch = event.GetInt( "witchid" );
	if ( witch > 0 && IsValidEntity( witch ))
	{
		char className[16];
		GetEntityClassname( witch, className, sizeof( className ));
		if( StrEqual( className, "witch", false ))
		{
			int attacker = GetClientOfUserId( event.GetInt( "userid" ));
			if( IsValidSurvivor( attacker ))
			{
				// life steal during super strength.
				if ( g_hT_LuffyStrength[attacker] != INVALID_HANDLE )
				{
					float bff[3];
					float pos[3];
					GetEntOrigin( witch, pos, 10.0 );
					
					for( int i = 1; i <= 5; i++ )
					{
						CopyArray3DF( pos, bff );
						bff[0] + GetRandomFloat( -50.0, 50.0 );
						bff[1] + GetRandomFloat( -50.0, 50.0 );
						CreatePointParticle( bff, PARTICLE_ELECTRIC1, 0.2 );
						
						CopyArray3DF( pos, bff );
						bff[0] + GetRandomFloat( -50.0, 50.0 );
						bff[1] + GetRandomFloat( -50.0, 50.0 );
						CreatePointParticle( bff, PARTICLE_ELECTRIC2, 0.2 );
					}
					switch( GetRandomInt( 1, 3 )) {
						case 1: {
							EmitSoundToAll( ZAP_1_SND, witch, SNDCHAN_AUTO );
						}
						case 2: {
							EmitSoundToAll( ZAP_2_SND, witch, SNDCHAN_AUTO );
						}
						case 3: {
							EmitSoundToAll( ZAP_3_SND, witch, SNDCHAN_AUTO );
						}
					}
					
					int health	= GetPlayerHealth( attacker ) + g_iLifeStealAmount;
					if( health > 100 )
					{
						health = 100;					// make sure our healt plus stolen health dont exceed 100.
					}
					
					float buffer = GetPlayerHealthBuffer( attacker );
					float newbuff = float(health) + buffer;
					if( newbuff > 100.0 )				// make sure our healt plus buffer dont exceed 100.
					{
						newbuff = 100.0 - float(health);
					}
					SetPlayerHealth( attacker, health );
					SetPlayerHealthBuffer( attacker, newbuff );
				}
			}
			
			// we only roll 1 model dice at a time because we have a while loop in a timer
			// if not safe to roll, consider this kill a waste.
			if( g_bSafeToRollNextDiceModel && g_iLuffySpawnCount < g_iLuffySpawnMax )
			{
				RollLuffyDropDice( witch );
			}
		}
	}
}

void RollLuffyDropDice( int client )
{
	int drop = true;
	float pos_infected[3];
	float pos_survivor[3];
	GetEntOrigin( client, pos_infected, 0.0 );
	
	// drop luffy item unless its too close to survivor
	for ( int  i = 1; i <= MaxClients; i ++ )
	{
		if ( IsValidSurvivor( i ))
		{
			GetEntOrigin( i, pos_survivor, 0.0 );
			if ( GetVectorDistance( pos_infected, pos_survivor ) <= 30.0 )
			{
				if( IsFakeClient( i ) && !g_bAllowBotPickUp ) { continue ;}

				drop = false;
				break;
			}
		}
	}

	if ( drop && GetRandomInt( 1, 100 ) <= g_iLuffyChance )
	{
		// option 1 = drop luffy item with selected model type.
		// option 2 = drop luffy item with random model type.
		// option 3 = drop ammobox. << this should have lifespan to prevent our server from flooded with ammobox.

		int modeltype		= 0;
		bool israndommodel	= true;
		bool candropluffy	= false;
		
		// determind which luffy drop type we get.
		// this while loop with GetRandomInt inside is damn expensive.
		// to avoid this we need timer to free this death event from while loop. 
		// but that gonna drag our drop interval chance between kill a bit longer. << not gonna do timer for this. i m done saving just a fraction of server preformance improvement.
		// update: for fakkk shake just do a random interger without while loop.... << Note to self >> do this next time you make an update.
		// update2: problem is we getting almost same chances every time. the random interger is not really random. << get a decision on this.
		
		while( g_iDropSelectionType[0] == g_iDropSelectionType[1] || g_iDropSelectionType[0] == g_iDropSelectionType[2] )
		{
			g_iDropSelectionType[0] = GetRandomInt( 1, 5 );
		}
		g_iDropSelectionType[2] = g_iDropSelectionType[1];
		g_iDropSelectionType[1] = g_iDropSelectionType[0];
		
		if( g_iDropSelectionType[0] > 3 )
		{
			modeltype		= g_iLuffyModelSelection[0];
			israndommodel	= false;	// this drop type not a random model
			candropluffy	= true;		// we allowed to drop luffy item
		}
		else if( g_iDropSelectionType[0] == 3 )
		{
			// model selection dont matter here. its random in timer
			candropluffy = true;	//we can drop
		}
		else
		{
			char ammoname[64];
			if( GetRandomInt( 1, 2 ) == 1 )
			{
				Format( ammoname, sizeof( ammoname ), "weapon_upgradepack_explosive" );
			}
			else
			{
				Format( ammoname, sizeof( ammoname ), "weapon_upgradepack_incendiary" );
			}
			
			int ammobox = GivePlayerItems( client, ammoname );
			if( ammobox != INVALID_VALUE )
			{
				// kill this ammobox to prevent out server flooded.
				CreateTimer( AMMOBOX_LIFE, Timer_AmmoBoxlife, EntIndexToEntRef( ammobox ), TIMER_FLAG_NO_MAPCHANGE );
			}
		}
		
		if( candropluffy )
		{
			float pos_world[3];
			float ang_world[3] = { 0.0, 0.0, 0.0 };
			GetEntOrigin( client, pos_world, 20.0 );

			// a dummy detect player touch
			int dummy = CreateEntParent( SDKHOOK_DMY, pos_world, ang_world, g_fModelScale[9] );
			
			float pos_parent[3] = { 0.0, 0.0, 0.0 };
			
			// a decoy skin.. what player actualy see but cant touch
			int skin = CreatEntChild( dummy, g_sModelBuffer[modeltype], pos_world, pos_parent, ang_world, g_fModelScale[modeltype] );
			
			if( dummy != INVALID_VALUE && skin != INVALID_VALUE )
			{
				if( g_bShowDummyModel )
				{
					ToggleGlowEnable( dummy, true );
				}
				else
				{
					SetRenderColour( dummy, g_iColor_White, 0 );	// make our dummy invisible
				}
				
				ToggleGlowEnable( skin, true );
				SDKHook( dummy, SDKHook_StartTouchPost, OnLuffyObjectTouch );
			}
			else
			{
				if( skin != INVALID_VALUE )
				{
					RemoveEdict( skin );
				}
				
				if( dummy != INVALID_VALUE )
				{
					RemoveEdict( skin );
				}
			}
			
			float life = g_fLuffyItemLife;
			if ( life > 300.0 ) life = 300.0;
			if ( life < 10.0 ) life = 10.0;
		
			g_iLuffySpawnCount++;
			g_bIsModelRandom[dummy]	= israndommodel;
			g_fLuffyLifeCounter[dummy] = life;
			g_hT_ItemLifeSpawn[dummy]	= CreateTimer( 0.1, Timer_LuffySpawnLife, EntIndexToEntRef( dummy ), TIMER_REPEAT );
			
			if( !israndommodel )
			{
				// determine which model to drop next ahead of time after
				
				g_bSafeToRollNextDiceModel = false;
				// create this timer to free EVENT_PlayerDeath and EVENT_WitchDeath our of while loop;
				CreateTimer( 0.05, Timer_ScrambleModelSelectionDice, 0, TIMER_FLAG_NO_MAPCHANGE );
			}
		}
	}
}

public Action Timer_ScrambleModelSelectionDice( Handle timer, any data )
{
	while(	g_iLuffyModelSelection[0] == g_iLuffyModelSelection[1] || g_iLuffyModelSelection[0] == g_iLuffyModelSelection[2] ||
			g_iLuffyModelSelection[0] == g_iLuffyModelSelection[3] || g_iLuffyModelSelection[0] == g_iLuffyModelSelection[4] ) {
			g_iLuffyModelSelection[0] = GetRandomInt( 0, 8 );
	}
	
	g_iLuffyModelSelection[4] = g_iLuffyModelSelection[3];
	g_iLuffyModelSelection[3] = g_iLuffyModelSelection[2];
	g_iLuffyModelSelection[2] = g_iLuffyModelSelection[1];
	g_iLuffyModelSelection[1] = g_iLuffyModelSelection[0];
	
	g_bSafeToRollNextDiceModel = true;
}

public Action Timer_LuffySpawnLife( Handle timer, any entref ) //<< ok
{
	int index = GetEntIndex_IsValid( entref );
	if( index > MaxClients )
	{
		int child = GetEntityChild( index );
		if( child > 0 && IsValidEntity( child ))
		{
			g_fLuffyLifeCounter[index] -= 0.1;
			if ( g_fLuffyLifeCounter[index] > 0.1 && g_bIsRoundStart )
			{
				float ang[3];
				GetEntAngle( index, ang, 20.0, AXIS_YAW );
				TeleportEntity( index, NULL_VECTOR, ang, NULL_VECTOR );
				
				if( g_bIsModelRandom[index] )
				{
					while ( g_iRandModelBff[index][0] == g_iRandModelBff[index][1] || g_iRandModelBff[index][0] == g_iRandModelBff[index][2] || g_iRandModelBff[index][0] == g_iRandModelBff[index][3] )
					{
						g_iRandModelBff[index][0] = GetRandomInt( 1, 9 );
					}
					g_iRandModelBff[index][3] = g_iRandModelBff[index][2];
					g_iRandModelBff[index][2] = g_iRandModelBff[index][1];
					g_iRandModelBff[index][1] = g_iRandModelBff[index][0];
					SetEntityModel( child, g_sModelBuffer[ g_iRandModelBff[index][0] ] );
					SetEntPropFloat( child, Prop_Send, "m_flModelScale", g_fModelScale[ g_iRandModelBff[index][0] ] );
				}
				return Plugin_Continue;
			}
	
			g_iLuffySpawnCount--;
			if( g_iLuffySpawnCount < 0 )
			{
				g_iLuffySpawnCount = 0;
			}
				
			g_hT_ItemLifeSpawn[index] = INVALID_HANDLE;
			SDKUnhook( index, SDKHook_StartTouchPost, OnLuffyObjectTouch );
			RemoveEntity_KillHierarchy( index );
		}
	}
	return Plugin_Stop;
}

public Action Timer_AmmoBoxlife( Handle timer, any entref )
{
	int ammobox = GetEntIndex_IsValid( entref );
	if( ammobox > MaxClients )
	{
		int client = GetOwner( ammobox );
		if( !IsValidSurvivor( client ))
		{
			RemoveEntity_Kill( ammobox );
		}
	}
}

public Action OnPlayerRunCmd( int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon ) //<< ok == launch airstrike and dashing here
{
	// this guy launching airstrike
	if (( buttons & IN_RELOAD ) && ( buttons & IN_ATTACK ))
	{
		if( ( g_bAirStrikeBTN[client] ) && g_hT_AirStrike[client] == INVALID_HANDLE )
		{
			g_bAirStrikeBTN[client]	= false;
			PrintHintTextToAll( "++ %N Launched Air Strike ++", client );
			
			switch( GetRandomInt( 1, 3 ))
			{
				case 1:
				{
					EmitSoundToAll( AIRSTRIK1_SND, client, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE );
				}
				case 2:
				{
					EmitSoundToAll( AIRSTRIK2_SND, client, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE );
				}
				case 3:
				{
					EmitSoundToAll( AIRSTRIK3_SND, client, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE );
				}
			}
			
			float jet_pos[3];
			float jet_ang[3];
			GetEntOrigin( client, jet_pos, 130.0 );				// always above player head
			GetEntAngle( client, jet_ang, 10.0, AXIS_PITCH );	// jet nose always pitch down 
			
			int jetf18 = CreatEntRenderModel( "prop_dynamic_override", g_sModelBuffer[POS_JETF18], jet_pos, jet_ang, g_fModelScale[POS_JETF18] );
			if( jetf18 != INVALID_VALUE )
			{
				SetOwner( jetf18, client );
				ToggleGlowEnable( jetf18, true );
				
				float flmOri[3] = { 0.0, 0.0, 0.0 };		// exaust pos relative to parent attachment
				float flmAng[3] = { 0.0, 180.0, 0.0 };		// exaust ang relative to parent attachment
				int exaust = CreateExaust( jetf18, flmOri, flmAng, g_iColor_Exaust );
				if( exaust != INVALID_VALUE )
				{
					int  miss = g_iAirStrikeNum;
					if( !g_bBypassMissileCap )
					{
						if ( miss < 1 ) miss = 1;
						if ( miss > 1000 ) miss = 1000;
					}
					
					g_iClientMissile[client] = miss + 1;	// plus 1 because we cutdown 1 missile before actually fire any
					g_hT_AirStrike[client] = CreateTimer( 0.1, Timer_JetF18Life, EntIndexToEntRef( jetf18 ), TIMER_REPEAT );
				}
			}
		}
	}
	
	// this guy using his dash to change position midair.
	if ( g_hT_LuffyStrength[client] != INVALID_HANDLE )
	{
		if( !g_bIsDoubleDashPaused[client] )
		{
			// pressing 3 button, forward, left and space wont detected. :(
			float direction = -1.0;
			if( (buttons & IN_FORWARD) && (buttons & IN_JUMP))
			{
				direction = 0.0;									
			}
			else if( (buttons & IN_BACK) && (buttons & IN_JUMP))
			{
				direction = 180.0;
			}
			else if( (buttons & IN_MOVELEFT) && (buttons & IN_JUMP))
			{
				direction = 90.0;
			}
			else if( (buttons & IN_MOVERIGHT) && (buttons & IN_JUMP))
			{
				direction = -90.0;
			}
			
			if( direction != -1 )
			{
				// roughly this is how we make our line of code longer and scared people away.
				// i mean calculate our next endpoint and get the final post based on known distance and angle.
				float pos_start[3];
				float pos_new[3];
				float ang_start[3];
				GetEntOrigin( client, pos_start, 10.0 );				// get our initial world pos for checking height, lift it 10 unit so it not on the ground.
				GetEntAngle( client, ang_start, 90.0, AXIS_PITCH );		// get our initial world ang and turn it downside/pitch so it facing our leg for checking height
				
				// check our distance from the ground, acuracy not matter so we ignore the inital 10 unit
				bool gotpos = TraceRayGetEndpoint( pos_start, ang_start, client, pos_new );
				if( gotpos )
				{
					if( GetVectorDistance( pos_start, pos_new ) > DASH_HEIGHT )			// our distance is safe to dash around
					{
						GetEntOrigin( client, pos_start, 0.0 );							// get our initial world pos	<< or just reuse the old value
						CopyArray3DF( pos_start, pos_new );								// copy or just get our initial world pos again so that we can manipulate later
						GetEntAngle( client, ang_start, direction, AXIS_YAW );			// get our inital forward world angle plus the manipulated direction at yaw angle.
						float radius = 100.0;											// roughly known/desired radius/distance surrounding us.
						
						// calculate where the intersection between known radius and known angle. final result is new endpoint/pos_new
						pos_new[0] += radius * Cosine( DegToRad( ang_start[1] ));
						pos_new[1] += radius * Sine( DegToRad( ang_start[1] ));
						
						float vec_new[3];
						MakeVectorFromPoints( pos_start, pos_new, vec_new );			// get vector from the 2 points. location where we start to our new location.
						NormalizeVector( vec_new, vec_new );							// always normalize when it is a vector.
						ScaleVector( vec_new, DASH_FORCE );								// scale it to create force.
						TeleportEntity( client, NULL_VECTOR, NULL_VECTOR, vec_new );	// push the guy.. walla... we dashing in midair.. :)
						g_bIsDoubleDashPaused[client] = true;							// we dashed once, wait until we touch the ground. the check inside the strength timer.
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_JetF18Life( Handle timer, any entref ) //<< ok
{
	int jetf18 = GetEntIndex_IsValid( entref );
	if( jetf18 > MaxClients )
	{
		int client = GetOwner( jetf18 );
		if ( IsValidSurvivor( client ))
		{
			if( g_bIsRoundStart )
			{
				g_iClientMissile[client] -= 1;
				if( g_iClientMissile[client] > 0 )
				{
					PCMasterRace_Render_ARGB( client, SHIELD_DORM_ALPHA );	// that right.. you read that correctly
					
					float pos_client[3];
					float clAng[3];
					GetEntOrigin( client, pos_client, 130.0 );
					GetEntAngle( client, clAng, 15.0, AXIS_PITCH );
					TeleportEntity( jetf18, pos_client,  clAng , NULL_VECTOR );
					
					// launch missile here
					float pos_start[3];
					float pos_end[3];
					float ang_start[3];
					
					GetClientEyePosition( client, pos_start );		// start pos of the missile
					GetClientEyeAngles( client, ang_start );		// start angle of the missile
					
					bool gotpos = TraceRayGetEndpoint( pos_start, ang_start, client, pos_end );
					if ( gotpos )
					{
						/// random missile start firing pos >>> near survivor owner of the missile
						pos_start[0] += GetRandomFloat( -30.0, 30.0 );		//<<< random pos around player location.
						pos_start[1] += GetRandomFloat( -30.0, 30.0 );		//<<< random pos around player location.
						pos_start[2] += GetRandomFloat( 100.0, 130.0 );		//<<< always above player head
						
						/// random missile target pos
						pos_end[0] += GetRandomFloat( -100.0, 100.0 );		//<<< scramble target pos. << for more accuracy zero the value
						pos_end[1] += GetRandomFloat( -100.0, 100.0 );		//<<< scramble target pos. << for more accuracy zero the value
						pos_end[2] += GetRandomFloat( -50.0, 50.0 );		//<<< scramble target pos. << for more accuracy zero the value
						
						int missile = CreateMissileProjectile( client, pos_start, pos_end );	// create a missile and shoot it.
						if( missile != INVALID_VALUE )
						{
							ChangeDirectionAndShoot( missile, pos_end, MISSILE_TARGET_SPEED, -90.0 );	// -90.0 is the molotove body pitch correction
						}
						// if this missile dont hit anything, we kill it.
						CreateTimer( HOMING_EXPIRE, Timer_MissileExplode, EntIndexToEntRef( missile ), TIMER_FLAG_NO_MAPCHANGE );
					}
					else
					{
						PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05Null aimed location!!" );
					}
					return Plugin_Continue;
				}
			}
			EmitSoundToClient( client, JETPASS_SND );
			g_hT_AirStrike[client] = INVALID_HANDLE;
		}
		RemoveEntity_KillHierarchy( jetf18 );
	}
	return Plugin_Stop;
}

int CreateMissileProjectile( int client, float pos_world_start[3], float pos_world_end[3] )	//<< ok
{
	// NOTE: We need the initial world position so the child entity created wont appear at world origin zero
	// and teleport to his parent origin attachment. firing hundred of missile make the child moving from world origin 
	// to his parent attachmen and it appear as if it was bagged.
	
	//// create projectile with physic so it interact with gravity and SDKHook function. act as a parent.
	float vecBuf[3];
	float vecAng[3];
	MakeVectorFromPoints( pos_world_start, pos_world_end, vecBuf );
	GetVectorAngles( vecBuf, vecAng );
	vecAng[0] -= 90.0;		// -90.0 = adjustment for the molotov orientation always facing target position.
	
	int body = INVALID_VALUE;
	int exaust = INVALID_VALUE;
	
	int head = CreatEntRenderModel( PROPTYPE_MOLOTOVE, MISSILE_DMY, pos_world_start, vecAng, 0.01 );
	if( head != INVALID_VALUE )
	{
		SetOwner( head, client );
		SetEntityGravity( head, 0.01 );
		SetEntPropFloat( head, Prop_Send,"m_flModelScale", 0.01 );
		
		// attach missile model to make it appealing and scared the bot infected away.	
		float pos_parent[3] = { 0.0, 2.0, -2.0 };		// center the model relative to molotov/parent
		float ang_parent[3] = { 90.0, 0.0, 0.0 };		// rotate the model relative to molotov/parent
		body = CreatEntChild( head, MISSILE_MDL, pos_world_start, pos_parent, ang_parent, 0.1 );
		if( body != INVALID_VALUE )
		{
			// attach exaust to make it look real rocket projectile.
			float pos_flm[3] = { 0.0, 2.0, 0.0 };		// origin relative to molotov/parent
			float ang_flm[3] = { -90.0, 0.0, 0.0 };		// angle relative to molotov/parent
			exaust = CreateExaust( head, pos_flm, ang_flm, g_iColor_Exaust );
			if( exaust != INVALID_VALUE )
			{
				if( g_bAllowMissileColor )
				{
					ToggleGlowEnable( head, true );
				}
				
				// if i cant read this next time, note to self >>> retire from coding.
				SDKHook( head, SDKHook_StartTouchPost, OnMissileTouch );
				
				ToggleGlowEnable( body, true );
				return head;
			}
		}
	}
	
	if ( exaust == INVALID_VALUE )
	{
		RemoveEntity_Kill( exaust );
		RemoveEntity_Kill( body );
		RemoveEntity_Kill( head );
	}
	return INVALID_VALUE;
}

void ChangeDirectionAndShoot( int entity, float pos_target[3], float speed, float pitch_angle_correction )
{
	float pos_start[3];
	float vecVel[3];
	float ang_start[3];
	GetEntOrigin( entity, pos_start, 0.0 );
	MakeVectorFromPoints( pos_start, pos_target, vecVel );
	GetVectorAngles( vecVel, ang_start );
	NormalizeVector( vecVel, vecVel );
	ScaleVector( vecVel, speed );					
	
	ang_start[0] += pitch_angle_correction;
	TeleportEntity( entity, pos_start, ang_start, NULL_VECTOR );
	TeleportEntity( entity, NULL_VECTOR, NULL_VECTOR, vecVel );
}

public Action Timer_MissileExplode( Handle timer, any entref )	//<< ok
{
	// our missile didnt hit anything, kill him.
	int missile = GetEntIndex_IsValid( entref );
	if( missile > MaxClients )
	{
		// if missile not SDKHook-ed it suppost not to error out.
		SDKUnhook( missile, SDKHook_StartTouchPost, OnMissileTouch );
		
		//missile explosion sound.
		switch( GetRandomInt( 1, 2 ))
		{
			case 1:	{ EmitSoundToAll( MISSILE1_SND, missile, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE )	;}
			case 2:	{ EmitSoundToAll( MISSILE2_SND, missile, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE )	;}
		}
		
		float missilePos[3];
		GetEntOrigin( missile, missilePos, 10.0 ); 
		
		int attacker = -1;
		int client = GetOwner( missile );
		if( IsValidSurvivor( client ))
		{
			attacker = client;
		}
		
		CreatePointParticle( missilePos, PARTICLE_EXPLOSIVE, 0.01 );
		CreatePointPush( 200.0, MISSILE_RADIUS, missilePos, 0.1 );
		RemoveEntity_KillHierarchy( missile );
		
		int base = GetEntIndex_IsValid( g_iHomingBaseOwner[missile] );
		if( base > MaxClients )
		{
			g_iHomingBaseTarget[base][missile] = INVALID_VALUE;
		}
		
		g_iHomingBaseOwner[missile] = INVALID_VALUE;
		g_fHomingBaseHeight[missile] = 0.0;
		
		// this is important, i should check if there is wall between the missile and the target
		// befor hurt/damage and/or push them. I m not gonna do that.. this plugin once reached 5k line of code so ya..
		char clname[64];
		float victimPos[3];
		int	cnt = GetEntityCount();
		for ( int i = 1; i <= cnt; i++ )
		{
			if ( i <= MaxClients )
			{
				if ( IsValidSurvivor( i ) && IsPlayerAlive( i ) && g_bAirStrikeSelf )
				{
					GetEntOrigin( i, victimPos, 10.0 );
					if ( GetVectorDistance( missilePos, victimPos ) <= MISSILE_RADIUS )
					{
						CreatePointHurt( attacker, i, 0, DAMAGE_EXPLOSIVE, missilePos, MISSILE_RADIUS );
					}
				}
				else if ( IsValidInfected( i ) && IsPlayerAlive( i ))
				{
					GetEntOrigin( i, victimPos, 10.0 );
					if ( GetVectorDistance( missilePos, victimPos ) <= MISSILE_RADIUS )
					{
						if( GetZclass( i ) == ZOMBIE_TANK )
						{
							CreatePointHurt( attacker, i, g_iTankDamage, DAMAGE_EXPLOSIVE, missilePos, MISSILE_RADIUS );
						}
						else
						{
							CreatePointHurt( attacker, i, g_iHomeMissaleDmg, DAMAGE_EXPLOSIVE, missilePos, MISSILE_RADIUS );
						}
					}
				}
			}
			else
			{
				if ( IsValidEntity( i ))
				{
					GetEntityClassname( i, clname, sizeof( clname ));
					if ( StrContains( clname, "infected", false ) != INVALID_VALUE || StrContains( clname, "witch", false ) != INVALID_VALUE ) // hurt and push only normal infected and witch
					{
						GetEntOrigin( i, victimPos, 10.0 );
						if ( GetVectorDistance( missilePos, victimPos ) <= MISSILE_RADIUS )
						{
							CreatePointHurt( attacker, i, g_iHomeMissaleDmg, DAMAGE_EXPLOSIVE, missilePos, MISSILE_RADIUS );
						}
					}
				}
			}
		}
	}
}

public Action OnMissileTouch( int hooked_ent, int toucher )		//<< ok
{
	if( IsValidSurvivor( toucher ))
	{
		return Plugin_Continue;
	}
	
	// free this sdkhook from the expensive damage computation
	if( hooked_ent > MaxClients && IsValidEntity( hooked_ent ))
	{
		SDKUnhook( hooked_ent, SDKHook_StartTouchPost, OnMissileTouch );
		CreateTimer( 0.0, Timer_MissileExplode, EntIndexToEntRef( hooked_ent ));
	}
	return Plugin_Continue;
}

public Action OnLuffyObjectTouch( int hooked_ent, int toucher )	//<< ok   
{
	if( IsValidSurvivor( toucher ))
	{
		if ( IsFakeClient( toucher ) && !g_bAllowBotPickUp )
		{
			return;
		}
		
		int child = GetEntityChild( hooked_ent );
		if( child > 0 && IsValidEntity( child ))
		{
			char modelName[128];
			GetEntPropString( child, Prop_Data, "m_ModelName", modelName, sizeof( modelName ));
			if( StrEqual( modelName, g_sModelBuffer[POS_JETF18], false ))
			{
				if( g_bAirStrikeBTN[toucher] )
				{
					PrintHintText( toucher, "++ Already Aquired Air Strike ++" );
					return;
				}
				else if( g_hT_AirStrike[toucher] != INVALID_HANDLE )
				{
					PrintHintText( toucher, "++ Air Strike In Progress ++" );
					return;
				}
			}
			else if( StrEqual( modelName, g_sModelBuffer[POS_HOMING], false ) && g_bHomingBTN[toucher] )
			{
				PrintHintText( toucher, "++ Already aquired Homing Missile ++" );
				return;
			}
			else if ( StrEqual( modelName, g_sModelBuffer[POS_REGEN], false))
			{
				if( GetPlayerHealth( toucher ) >= g_iHPregenMax )
				{
					PrintHintText( toucher, "-- You are healthy for Luffy Health --" );
					return;
				}
				else if(  g_hT_HealthRegen[toucher] != INVALID_HANDLE )
				{
					PrintHintText( toucher, "-- You Still On Luffy Drug --" );
					return;
				}
			}
			else if( StrEqual( modelName, g_sModelBuffer[POS_CLOCK], false) || StrEqual( modelName, g_sModelBuffer[POS_SPEED], false) ||
					 StrEqual( modelName, g_sModelBuffer[POS_SHIELD], false) || StrEqual( modelName, g_sModelBuffer[POS_STRENGTH], false )) {
				if ( g_hT_LuffyClock[toucher] != INVALID_HANDLE || g_hT_LuffySpeed[toucher] != INVALID_HANDLE ||
					 g_hT_LuffyShield[toucher] != INVALID_HANDLE || g_hT_LuffyStrength[toucher] != INVALID_HANDLE ) {
					PrintHintText( toucher, "-- Luffy Ability Still Active --" );
					return;
				}
			}
			
			g_iLuffySpawnCount--;
			if( g_iLuffySpawnCount < 0 )
			{
				g_iLuffySpawnCount = 0;
			}
			
			g_hT_ItemLifeSpawn[hooked_ent] = INVALID_HANDLE;	//<< we dont kill the timer. the timer kill itself
			
			SDKUnhook( hooked_ent, SDKHook_StartTouchPost, OnLuffyObjectTouch );
			RemoveEntity_KillHierarchy( hooked_ent );
			RewardPicker( toucher, modelName );
		}
	}
}

// all ability listed here for easy overview
void RewardPicker( int client, const char[] mName ) //<< ok.
{
	float scale = 0.0;
	if ( StrEqual( mName, g_sModelBuffer[POS_CLOCK], false ))		// clock device
	{
		scale = g_fModelScale[POS_CLOCK];
		RunLuffyClock( client );
	}
	else if ( StrEqual( mName, g_sModelBuffer[POS_SPEED], false ))	// super speed
	{
		scale = g_fModelScale[POS_SPEED];
		RunLuffySpeed( client );
	}
	else if ( StrEqual( mName, g_sModelBuffer[POS_POISON], false ))	// luffy poison
	{
		scale = g_fModelScale[POS_POISON];
		RunLuffyPunishment( client );
	}
	else if ( StrEqual( mName, g_sModelBuffer[POS_REGEN], false))	// player HP
	{
		scale = g_fModelScale[POS_REGEN];
		RunLuffyHealth( client );
	}
	else if ( StrEqual( mName, g_sModelBuffer[POS_SHIELD], false))	// player shield
	{
		scale = g_fModelScale[POS_SHIELD];
		RunLuffyShield( client );
	}
	else if ( StrEqual( mName, g_sModelBuffer[POS_STRENGTH], false))	//super strength
	{
		scale = g_fModelScale[POS_STRENGTH];
		RunLuffyStrength( client );
	}
	else if ( StrEqual( mName, g_sModelBuffer[POS_GIFT], false ))	// reward T2 weapon and give his primary weapon double ammo << now that sound rewarding.
	{																// not rewarding enough? Drop also random health buff. Still not rewarding? you greed af.
		scale = g_fModelScale[POS_GIFT];
		DropRandomWeapon( client, WEAPON_TIER2 );
		RestockPrimaryAmmo( client, 2 );
		switch( GetRandomInt( 0, 2 ))
		{
			case 0:	{ GivePlayerItems( client, "weapon_pain_pills" );	}
			case 1:	{ GivePlayerItems( client, "weapon_defibrillator" );}
			case 2:	{ GivePlayerItems( client, "weapon_adrenaline" );	}
		}
	}
	else if ( StrEqual( mName, g_sModelBuffer[POS_HOMING], false))	// homing missile
	{
		scale = g_fModelScale[POS_HOMING];
		g_bHomingBTN[client] = true;
		switch( GetRandomInt( 1, 3 ))
		{
			case 1:
			{
				EmitSoundToClient( client, AIRSTRIK1_SND );
			}
			case 2:
			{
				EmitSoundToClient( client, AIRSTRIK2_SND );
			}
			case 3:
			{
				EmitSoundToClient( client, AIRSTRIK3_SND );
			}
		}
		if ( g_bHinttext )
		{
			PrintToChatAll( "\x04[\x05LUFFY\x04]: %N \x05 acquired \x04Homing Missile", client );
		}
		PrintHintText( client, "++ Get Ammo Box And Deploy It ++" );
	}
	else if ( StrEqual( mName, g_sModelBuffer[POS_JETF18], false))	// air strike
	{
		scale = g_fModelScale[POS_JETF18];
		g_bAirStrikeBTN[client] = true;
		switch( GetRandomInt( 1, 3 ))
		{
			case 1:
			{
				EmitSoundToClient( client, AIRSTRIK1_SND );
			}
			case 2:
			{
				EmitSoundToClient( client, AIRSTRIK2_SND );
			}
			case 3:
			{
				EmitSoundToClient( client, AIRSTRIK3_SND );
			}
		}
		
		if ( g_bHinttext )
		{
			PrintToChatAll( "\x04[\x05LUFFY\x04]: %N \x05 acquired \x04Air Strike.", client );
		}
		PrintHintText( client, "++ Press 'RELOAD + FIRE' to launch Air Strike ++" );
	}
	
	if( g_bAllowPickupPlay )
	{
		float pos[3];
		float ang[3] = { 0.0, 0.0, 0.0 };
		GetEntOrigin( client, pos, 20.0 );
		GetEntAngle( client, ang, 0.0, AXIS_PITCH );
		ang[0] = 0.0;
		
		// just ordinary model animation. hacky way but it works. we emulate model scaling
		int skin = CreatEntRenderModel( PROPTYPE_DYNAMIC, mName, pos, ang, scale );
		if ( skin != INVALID_VALUE )
		{
			SetRenderColour( skin, g_iColor_White, 80 );
			g_fSkinAnimeScale[skin] = scale;
			g_iSkinAnimeCount[skin] = 1;
			CreateTimer( 0.1, Timer_PlayLuffyPickupAnimation, EntIndexToEntRef( skin ), TIMER_REPEAT );
		}
	}
}

public Action Timer_PlayLuffyPickupAnimation( Handle timer, any entref )
{
	int entity = GetEntIndex_IsValid( entref );
	if( entity > MaxClients )
	{
		if( g_bIsRoundStart && g_iSkinAnimeCount[entity] > 0 && g_iSkinAnimeCount[entity] <= ANIMATION_COUNT )
		{
			SetEntPropFloat( entity, Prop_Send, "m_flModelScale", g_fSkinAnimeScale[entity] );
			g_fSkinAnimeScale[entity] *= 1.2;
			g_iSkinAnimeCount[entity] += 1;
			return Plugin_Continue;
		}
		
		g_iSkinAnimeCount[entity] = 0;
		g_fSkinAnimeScale[entity] = 0.0;
		RemoveEntity_Kill( entity );
	}
	return Plugin_Stop;
}

// new and old melee weapon still not available. << got time search for the weapon cl name????
public void EVENT_UpgradePackUsed( Event event, const char[] name, bool dontBroadcast )  //<< ok == launch homing missile here.
{
	if ( !g_bLuffyEnable ) return;
	
	int  userid	= event.GetInt( "userid" );
	int  client	= GetClientOfUserId( userid );
	if ( IsValidSurvivor( client ))
	{
		bool destroy = true;
		
		if( !g_bHomingBTN[client] )
		{
			if( g_bAllowAmmoboxTweak )
			{
				// for first time usage, value always zero mean let player have the ammobox.
				switch( g_iDrawDice[client][0] )
				{
					case 1:  { DropRandomWeapon( client, WEAPON_TIER1 );					}
					case 2:	 { RunFreezeClient( client );									}
					case 3:	 { GivePlayerItems( client, "weapon_pipe_bomb" );				}
					case 4:	 { GivePlayerItems( client, "weapon_molotov" );					}
					case 5:	 { GivePlayerItems( client, "weapon_vomitjar" );				}
					case 6:  { CheatCommand( client, "z_spawn_old", "tank auto" );			}
					case 7:  { GivePlayerItems( client, "weapon_first_aid_kit" );			}
					case 8:	 { GivePlayerItems( client, "weapon_defibrillator" );			}
					case 9:  { GivePlayerItems( client, "weapon_pain_pills" );				}
					case 10: { DropRandomWeapon( client, WEAPON_TIER1 );					}
					case 11: { GivePlayerItems( client, "weapon_adrenaline" );				}
					case 12: { CheatCommand( client, "z_spawn_old", "witch auto" );			}
					case 13: { CheatCommand( client, "director_force_panic_event", "" );	}
					case 14: { GivePlayerItems( client, "upgrade_laser_sight" );			}
					case 15: { GivePlayerItems( client, "weapon_ammo_spawn" );				}
					case 16: { RewardTeleport( client, "Survivor" );						}
					case 17: { RewardTeleport( client, "Witch" );							}
					case 18: { RewardTeleport( client, "Tank" );							}
					case 19: { RunLuffyHealth( client );									}
					case 20: { DropRandomWeapon( client, WEAPON_TIER1 );					}
					case 21: { if ( g_bAllowMessage == true ) { PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You got empty box!!" ); }}
					default : {	destroy = false; }  /*<< give him the ammobox*/
				}
				
				// roll the next dice ahead of ammobox use after we are done doing things above... this should be a bit faster
				// also we free this EVENT_UpgradePackUsed from the huge while loop. 
				CreateTimer( 0.1, Timer_RollAmmoboxDice, userid );
			}
			else
			{
				destroy = false;
			}
		}
		else
		{
			int ammobox = event.GetInt( "upgradeid" );
			if( ammobox > MaxClients && IsValidEntity( ammobox ))
			{
				RunHomingMissile( client, ammobox );
				PrintHintTextToAll( "++ %N Launched Homing Missile ++", client );
			}
		}
		
		if( destroy )
		{
			RemoveEntity_Kill( event.GetInt( "upgradeid" ));
		}
	}
}

public Action Timer_RollAmmoboxDice( Handle timer, any userid )
{
	int client = GetClientIndex( userid, true );
	if( IsValidSurvivor( client ))
	{
		while ( g_iDrawDice[client][0] == g_iDrawDice[client][1] || 
				g_iDrawDice[client][0] == g_iDrawDice[client][2] || 
				g_iDrawDice[client][0] == g_iDrawDice[client][3] ||
				g_iDrawDice[client][0] == g_iDrawDice[client][4] ||
				g_iDrawDice[client][0] == g_iDrawDice[client][5] )
		{
			g_iDrawDice[client][0] = GetRandomInt( 1, 24 ); // total reward 21, we roll 24 so the extra digit is for allowing player to have the ammobox
		}
		g_iDrawDice[client][9] = g_iDrawDice[client][8];
		g_iDrawDice[client][8] = g_iDrawDice[client][7];
		g_iDrawDice[client][7] = g_iDrawDice[client][6];
		g_iDrawDice[client][6] = g_iDrawDice[client][5];
		g_iDrawDice[client][5] = g_iDrawDice[client][4];
		g_iDrawDice[client][4] = g_iDrawDice[client][3];
		g_iDrawDice[client][3] = g_iDrawDice[client][2];
		g_iDrawDice[client][2] = g_iDrawDice[client][1];
		g_iDrawDice[client][1] = g_iDrawDice[client][0];
	}
}

void RunHomingMissile( int client, int ammobox ) //<< ok
{
	float boxpos[3];
	float boxang[3];
	GetEntOrigin( ammobox, boxpos, 0.0 );
	GetEntAngle( ammobox, boxang, 0.0, 0 );

	// lunch missile.....
	int entity = CreatEntRenderModel( PROPTYPE_DYNAMIC, g_sModelBuffer[POS_HOMING], boxpos, boxang, 2.0 );
	if( entity != INVALID_VALUE )
	{
		SetOwner( entity, client );
		
		int  miss = g_iHomingNum;
		if( !g_bBypassMissileCap )
		{
			if ( miss < 1 ) miss = 1;
			if ( miss > 1000 ) miss = 1000;
		}
		
		float diff = 0.0;
		for( int i = 1; i <= miss; i ++ )
		{
			CreateTimer( diff, Timer_HomingBaseLaunch, EntIndexToEntRef( entity ), TIMER_FLAG_NO_MAPCHANGE );
			diff += HOMING_INTERVAL;
		}
		
		diff += 2.0;
		CreateTimer( diff, Timer_HomingBaseLife, EntIndexToEntRef( entity ), TIMER_FLAG_NO_MAPCHANGE );
		
		// track our HomingBase z pos.
		g_fHomingBaseHeight[entity] = boxpos[2];
		g_bHomingBTN[client] = false;
	}
}

public Action Timer_HomingBaseLife( Handle timer, any entref )	//<< ok
{
	int base = GetEntIndex_IsValid( entref );
	if( base > MaxClients )
	{
		RemoveEdict( base );
	}
}

public Action Timer_HomingBaseLaunch( Handle timer, any entref )	//<< ok
{
	int entity = GetEntIndex_IsValid( entref );
	if( entity > MaxClients )
	{
		if( g_bIsRoundStart )
		{
			float pos_launcher[3];
			GetEntOrigin( entity, pos_launcher, 30.0 );		// 30.0 always above launcher base.
			pos_launcher[0] += GetRandomFloat( -10.0, 10.0 );
			pos_launcher[1] += GetRandomFloat( -10.0, 10.0 );
			
			float pos_target[3];
			SetArray3DF( pos_target, pos_launcher[0], pos_launcher[1], ( pos_launcher[2] + 1000.0 )); // verticle position so the missile inital start verticly 
			
			int missile, client = GetOwner( entity );
			if( IsValidSurvivor( client ))
			{
				PCMasterRace_Render_ARGB( client, 130 );	// 0.5 interval between rendering is too slow.. so we render it at 4K 260hz resolution. I mean higher alpha.
				missile = CreateMissileProjectile( client, pos_launcher, pos_target );
			}
			else
			{
				missile = CreateMissileProjectile( entity, pos_launcher, pos_target );
			}
			
			if( missile != INVALID_VALUE )
			{
				// value 160.0 is the speed of our verticle missile. fly slower to buy time for the shooting/targeting missile to empty its target array
				ChangeDirectionAndShoot( missile, pos_target, MISSILE_IDLE_SPEED, -90.0 );	// -90.0 is the molotov body pitch correction 
				
				// track which 1 is our base.
				g_iHomingBaseOwner[missile] = EntIndexToEntRef( entity );
				g_iHomingBaseTarget[entity][missile] = INVALID_VALUE;
				
				// track our HomingBase z pos.
				g_fHomingBaseHeight[missile] = g_fHomingBaseHeight[entity];
				
				//SDKHook( missile, SDKHook_Think, OnMissileThink );	// <<< operation too expensive.
				CreateTimer( 0.1, Timer_HomingMissileHoming, EntIndexToEntRef( missile ), TIMER_REPEAT );
				CreateTimer( HOMING_EXPIRE, Timer_MissileExplode, EntIndexToEntRef( missile ), TIMER_FLAG_NO_MAPCHANGE );	//<< safety just incase our missile stuck
			}
		}
		else
		{
			RemoveEntity_Kill( entity );
		}
	}
}

public Action Timer_HomingMissileHoming( Handle timer, any entref )	//<< ok
{
	int missile = GetEntIndex_IsValid( entref );
	if( missile > MaxClients )
	{
		if( !g_bIsRoundStart )
		{
			// round is end, kill this guy.
			CreateTimer( 0.0, Timer_MissileExplode, EntIndexToEntRef( missile ));
			return Plugin_Stop;
		}
		
		int base = GetEntIndex_IsValid( g_iHomingBaseOwner[missile] );
		if( base > MaxClients )
		{
			if( g_iHomingBaseTarget[base][missile] == INVALID_VALUE )
			{
				float pos[3];
				GetEntOrigin( missile, pos, 0.0 );

				// distance between the vertical missile to his own HomingBase on the ground.
				float dist = pos[2] - g_fHomingBaseHeight[missile];
				
				// min height reached, search for target
				if( dist >= HOMING_HEIGHT_MIN )
				{
					int target = INVALID_VALUE;
					int entcount = GetEntityCount();
					int i;
					char clname[32];
					
					for( i = 1; i <= entcount; i++ )
					{
						if( i <= MaxClients )
						{
							if( IsValidInfected( i ) && IsPlayerAlive( i ))
							{
								// find SI and tank first and check if has been targeted
								if( GetZclass( i ) == ZOMBIE_TANK		|| GetZclass( i ) == ZOMBIE_SMOKER ||
									GetZclass( i ) == ZOMBIE_BOOMER		|| GetZclass( i ) == ZOMBIE_HUNTER ||
									GetZclass( i ) == ZOMBIE_SPITTER	|| GetZclass( i ) == ZOMBIE_JOCKEY ||
									GetZclass( i ) == ZOMBIE_CHARGER )
								{
									target = HomingCompareTarget( missile, i );
								}
								
								if( target != INVALID_VALUE )
								{
									break;
								}
							}
						}
						else
						{
							if( IsValidEntity( i ))
							{
								// no SI either.. so look for Witch or infected.
								GetEntityClassname( i, clname, sizeof( clname ));
								if( StrEqual( clname, "witch", false ) || StrEqual( clname, "infected", false ))
								{
									target = HomingCompareTarget( missile, i );
								}
								
								if( target != INVALID_VALUE )
								{
									break;
								}
							}
						}
					}
					
					if( target == INVALID_VALUE && g_bAllowTargetSelf )
					{
						// still no target, we sent the missile to the owner
						int client = GetOwner( missile );
						if( IsValidSurvivor( client ) && IsPlayerAlive( client ))
						{
							target = client;
						}
						else
						{
							// missile owner died, rage quit, disconnect? we sent the missile to the random survivor.
							// this always true because the round end if all survivor died or gone.
							int count = 0;
							int bff[MAXPLAYERS+1];
							
							for( i = 1; i <= MaxClients; i++ )
							{
								if( IsValidSurvivor( i ) && IsPlayerAlive( i ))
								{
									bff[count] = i;
									count++;
								}
							}
							count--;
							target = bff[ GetRandomInt( 0, count ) ];
						}
					}
					
					if( target != INVALID_VALUE )
					{
						// Store our target in the missile own base buffer so we can keep track
						// this particular base target and bypass it for another missile originated from the same base/family.
						// At the same time other base with it own missile family will not see this target and may populate it
						// for his own family taget collection. This is useful if multiple homing missile deployed.
						// Note to self: GsiX << dont fix or change something that aint broken. if it work as intended, it work << you bug producer.
						g_iHomingBaseTarget[base][missile] = target;
						
						//PrintToChatAll( "[MISSILE%d]: Found a target \x04%d", missile, target );
						
						// found a target, change direction and shoot it.
						float pos_target[3];
						GetEntOrigin( target, pos_target, 10.0 );				// 10.0 we dont target his leg
						ChangeDirectionAndShoot( missile, pos_target, MISSILE_TARGET_SPEED, -90.0 ); // -90.0 is the molotov body pitch correvtion 
						return Plugin_Stop;
					}
				}
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Stop;
}

int HomingCompareTarget( int missile, int target )		//<< ok
{
	int base = GetEntIndex_IsValid( g_iHomingBaseOwner[missile] );
	if( base > MaxClients )
	{
		// check if the target not targeted. return INVALID_VALUE for already targeted.
		for( int j = 0; j < sizeof( g_iHomingBaseTarget[] ); j++ )
		{
			if( g_iHomingBaseTarget[base][j] != INVALID_VALUE )
			{
				if( g_iHomingBaseTarget[base][j] == target )
				{
					return INVALID_VALUE;
				}
			}
		}
	}
	return target;
}

/////////////////////////////////////////////////////////////////////////
/////////////////////// Luffy RPG END HERE //////////////////////////////
/////////////////////////////////////////////////////////////////////////

public void EVENT_ReviveSuccsess( Event event, const char[] name, bool dontBroadcast ) //<< ok
{
	if ( !g_bLuffyEnable || !g_bAllowHealAnimate ) return;

	int userid = event.GetInt( "subject" );
	int client = GetClientOfUserId( userid );
	if( IsValidSurvivor( client ))
	{
		bool isledge = event.GetBool( "ledge_hang" );
		if( isledge && g_bIsPlayerHPInterrupted[client] )
		{
			g_bIsPlayerHPInterrupted[client] = false;
			SetPlayerHealth( client, g_iCleintHPHealth[client] );
			SetPlayerHealthBuffer( client, g_fCleintHPBuffer[client] );
			g_hT_HealthRegen[client] = CreateTimer( 0.1, Timer_LuffyHealth, userid, TIMER_REPEAT );
		}
	}
}

public void EVENT_PlayerUse( Event event, const char[] name, bool dontBroadcast ) //<< ok
{
	if ( !g_bLuffyEnable ) return;
	
	int  client = GetClientOfUserId( event.GetInt( "userid" ));
	if ( IsValidSurvivor( client ) && !IsFakeClient( client ) && g_bAllowAmmoboxTweak )
	{
		int  item = event.GetInt( "targetid" );
		if( item > MaxClients && IsValidEntity( item ))
		{
			char entname[64];
			int pos = CompareWeaponDropBuffer( item );
			if( pos != INVALID_VALUE )
			{
				GetEntityClassname( item, entname, sizeof( entname ));
				if ( StrEqual( entname, "upgrade_laser_sight", false ))
				{
					RemoveEntity_Kill( item );
					g_iWeaponDropBuffer[pos] = INVALID_VALUE;
				}
				else if ( StrEqual( entname, "weapon_ammo_spawn", false ) && RestockPrimaryAmmo( client, 1 ))
				{
					RemoveEntity_Kill( item );
					g_iWeaponDropBuffer[pos] = INVALID_VALUE;
				}
			}
		}
	}
}

public void EVENT_UpgradePackAdded( Event event, const char[] name, bool dontBroadcast ) //<< ok  ====================== this need fix, destroy only our own spawn ent.
{
	if ( !g_bLuffyEnable ) return;
	
	int  client	= GetClientOfUserId( event.GetInt( "userid" ));
	if ( IsValidSurvivor( client ) && !IsFakeClient( client ))
	{
		// destroy ammo explosive, fire and laser after human player pickup.
		int  item = event.GetInt( "upgradeid" );
		if ( item != INVALID_VALUE )
		{
			RemoveEntity_Kill( item );
		}
	}
}

public void EVENT_PlayerHurt( Event event, const char[] name, bool dontBroadcast ) //<< ok
{
	if ( !g_bLuffyEnable ) return;
	
	int  client		= GetClientOfUserId( event.GetInt( "userid" ));
	int  attacker	= GetClientOfUserId( event.GetInt( "attacker" ));
	if ( IsValidInfected( client ) && IsValidSurvivor( attacker ))
	{
		if ( g_hT_LuffyShield[attacker] != INVALID_HANDLE || g_hT_LuffyClock[attacker] != INVALID_HANDLE )
		{
			SetupBloodSpark( client );
		}
	}
}

public void EVENT_InfectedHurt( Event event, const char[] name, bool dontBroadcast ) //<< ok
{
	if ( !g_bLuffyEnable ) return;
	
	int  infected = GetClientOfUserId( event.GetInt( "entityid" ));
	int  attacker = GetClientOfUserId( event.GetInt( "attacker" ));
	if ( IsValidSurvivor( attacker ) && infected > MaxClients && IsValidEntity( infected ))
	{
		if ( g_hT_LuffyShield[attacker] != INVALID_HANDLE || g_hT_LuffyClock[attacker] != INVALID_HANDLE )
		{
			char className[16];
			GetEntityClassname( infected, className, sizeof( className ));
			if( StrEqual( className, "witch", false ))
			{
				SetupBloodSpark( infected );
			}
			else if( StrEqual( className, "infected", false ))
			{
				EmitSoundToAll( GETHIT_SND, infected, SNDCHAN_AUTO );
			}
		}
	}
}

public void EVENT_HealBegin( Event event, const char[] name, bool dontBroadcast ) //<< ok
{
	if ( !g_bLuffyEnable || !g_bAllowHealAnimate ) return;
	
	int  client = GetClientOfUserId( event.GetInt( "subject" ));
	if ( IsValidSurvivor( client ))
	{
		// lets animate the heal.
		// capture player health and health buffer from pill or syrange
		g_bIsPlayerHPInterrupted[client] = false;
		g_iCleintHPHealth[client] = GetPlayerHealth( client );
		g_fCleintHPBuffer[client] = GetPlayerHealthBuffer( client );
		if ( g_iCleintHPHealth[client] < 10 )
		{
			g_iCleintHPHealth[client] = 10;
		}
	}
}

public void EVENT_HealSuccess( Event event, const char[] name, bool dontBroadcast ) //<< ok
{
	if ( !g_bLuffyEnable || !g_bAllowHealAnimate ) return;
	
	int userid = event.GetInt( "subject" );
	int client = GetClientOfUserId( userid );
	if ( IsValidSurvivor( client ))
	{
		if ( g_iCleintHPHealth[client] > 0 )
		{
			// restore the health and healt buffer we capture earlier
			SetPlayerHealth( client, g_iCleintHPHealth[client] );
			SetPlayerHealthBuffer( client, g_fCleintHPBuffer[client] );
			
			g_bIsPlayerHPInterrupted[client] = false;
			g_hT_HealthRegen[client]	= CreateTimer( 0.1, Timer_LuffyHealth, userid, TIMER_REPEAT );
			g_iCleintHPHealth[client]	= 0;
			g_fCleintHPBuffer[client]	= 0.0;
		}
	}
}

public Action Timer_LuffyHealth( Handle timer, any userid ) //<< ok ====== lazy arse >> check legde grab and incap( we not entirely sure what happen during the animation )
{
	int client = GetClientIndex( userid, true );
	if ( IsValidSurvivor( client ))
	{
		if( IsPlayerAlive( client ))
		{
			int health = GetPlayerHealth( client );
			if( g_bIsRoundStart && health < g_iHPregenMax )
			{
				// // player not incap or ledge grab during animation, safe to continue
				if( !IsPlayerLedge( client ) && !IsPlayerIncap( client ))
				{
					g_iCleintHPHealth[client] = health + 1;
					g_fCleintHPBuffer[client] = 100.0 - float( g_iCleintHPHealth[client] );			// make sure our health dont exceed 100
					SetPlayerHealthBuffer( client, g_fCleintHPBuffer[client] );
					SetPlayerHealth( client, g_iCleintHPHealth[client] );
					return Plugin_Continue;
				}
				
				if( IsPlayerIncap( client ))
				{
					// mark player as hp regen intruppted
					g_bIsPlayerHPInterrupted[client] = true;
				}
			}
			
			if( !g_bIsPlayerHPInterrupted[client] )
			{
				SetPlayerHealthBuffer( client, 0.0 );
				SetPlayerHealth( client, 100 );
				ResetPlayerLifeCount( client );
				EmitSoundToClient( client, TIMEOUT_SND );
				g_iCleintHPHealth[client] = 0;
				g_fCleintHPBuffer[client] = 0.0;
			}
		}
		g_hT_HealthRegen[client] = INVALID_HANDLE;
	}
	return Plugin_Stop;
}

public Action Timer_RestoreCollution( Handle timer, any userid ) //<< ok
{
	int client = GetClientIndex( userid, true );
	if ( IsValidSurvivor( client )) 
	{
		SetEntityMoveType( client, MOVETYPE_WALK );
	}
}

// update: havent tested this since the first release v0.0 //<<Update: this should work but is cheating. //<update: its single player dangit
void CreateShieldPush( int client, int target, float force )	/// those teleport need simplified
{
	float pos_client[3];
	float pos_target[3];
	float vel_target[3];
	float ang_target[3];
	GetEntOrigin( client, pos_client, 0.0 );
	GetEntOrigin( target, pos_target, 0.0 );
	
	MakeVectorFromPoints( pos_client, pos_target, vel_target );
	GetVectorAngles( vel_target, ang_target );
	ang_target[0] -= 20.0;					// redirect him to the air, slightly
	GetAngleVectors( ang_target, vel_target, NULL_VECTOR, NULL_VECTOR);	// recalculate the velocity.
	NormalizeVector( vel_target, vel_target );
	ScaleVector( vel_target, force );
	TeleportEntity( target, NULL_VECTOR, NULL_VECTOR, vel_target );
	
	if( target <= MaxClients )
	{
		// if we cant push them, then kill the attacker
		bool isluck = false;
		if ( GetEntProp( client, Prop_Send, "m_tongueOwner" ) > 0 && GetZclass( target ) == ZOMBIE_SMOKER )
		{
			isluck = true;
			SetEntityMoveType( target, MOVETYPE_NOCLIP );
			CreateTimer( 0.1, Timer_RestoreCollution, GetClientIndex( target, false ));
		}
		else if( GetEntPropEnt( client, Prop_Send, "m_pounceAttacker" ) > 0 && GetZclass( target ) == ZOMBIE_CHARGER )
		{
			isluck = true;
			CheatCommand( target, "kill", "" );
		}
		else if ( GetEntPropEnt( client, Prop_Send, "m_jockeyAttacker" ) > 0 && GetZclass( target ) == ZOMBIE_JOCKEY )
		{
			isluck = true;
			CheatCommand( target, "dismount", "" );
		}
		
		if( isluck )
		{
			EmitSoundToClient( client, HEALTH_SND );
			if ( g_bHinttext )
			{
				PrintHintText( client, "++ You freed from %N ++", target );
			}
		}
	}
	
	// this is the section causing player screen to black out for the dying animation loop and cause them stuck with it untill client game restart.
	// never occour to me that someone actualy have the balls to stand on top of 10 boxes of fire cracker next to 10 gallon of gascan stack together.
	// we are going to fix him with 200 health buff aka half god mode. << in theory, this bug only happen to clock ability since the shield practilly immortal/god mode.
	if ( IsPlayerIncap( client ))
	{
		ResetPlayerIncap( client );
		CheatCommand( client, "give", "health" );
		SetPlayerHealthBuffer( client, 200.0 );		// give himm 200 health buff to break the incap loop. 100 buff will do but 20 flameable prop give us a lil concern.
		SetPlayerHealth( client, 1 );
		PrintHintText( client, "++ You recovered from Incap ++" );
	}
	else if(  IsPlayerLedge( client ))
	{
		ResetPlayerLedge( client );
	}
}

void RewardTeleport( int client, const char[] who ) //<< ok
{
	// if my memory serve me well, the witch and/or Tank in the map cause problem to our plugin. Cant recall what it is.
	// comment this out and debug yourself to findout.
	if ( StrContains( g_sCURRENT_MAP, "c5m2", false ) != INVALID_VALUE )
	{
		if ( StrEqual( who, "Witch", false ) || StrEqual( who, "Tank", false ))
		{
			if ( g_bHinttext )
			{
				PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You found \x05Empty Luffy!!" );
			}
			return;
		}
	}
	
	int  scan = INVALID_VALUE;
	
	if ( StrEqual( who, "Tank", false ))
	{
		for ( int  i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidInfected( i ) && IsPlayerAlive( i ))
			{
				if ( GetZclass( i ) == ZOMBIE_TANK )
				{
					scan = i;
					break;
				}
			}
		}
	}
	else if ( StrEqual( who, "Witch", false ))
	{
		char _name[64];
		int  _max	= GetEntityCount();
		for ( int  i = MaxClients; i <= _max; i++ )
		{
			if ( IsValidEntity( i ))
			{
				GetEntityClassname( i, _name, sizeof( _name ));
				if ( StrContains( _name, "witch", false) != INVALID_VALUE )
				{
					//if ( GetEntProp( i, Prop_Data, "m_iHealth" ) > 1 )	//<< this could be wrong/crashing the server <<< note to self >> test this
					//{														// update: ya.. checked my witch plugins, it will crash the server.
						scan = i;											// so we dont check her health... just teleport.
						break;
					//}
				}
			}
		}
	}
	else if ( StrEqual( who, "Infected", false ))
	{
		for ( int  i = MaxClients; i <= 1; i-- )
		{
			if ( IsValidInfected( i ) && IsPlayerAlive( i ))
			{
				scan = i;
				break;
			}
		}
	}
	else if ( StrEqual( who, "Survivor", false ))
	{
		for ( int  i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidSurvivor( i ) && i != client )
			{
				scan = i;
				break;
			}
		}
	}

	if ( scan == INVALID_VALUE )
	{
		
		if ( StrContains( who, "Survivor", false ) != INVALID_VALUE )
		{
			switch( GetRandomInt( 1, 3 ))
			{
				case 1: { GivePlayerItems( client, "weapon_defibrillator" );	}
				case 2: { GivePlayerItems( client, "weapon_pain_pills" );		}
				case 3: { GivePlayerItems( client, "weapon_adrenaline" );		}
			}
		}
		// we cant teleport him to tank, witch or infected, give him 1 instead.
		else if ( StrContains( who, "Tank", false ) != INVALID_VALUE )
		{
			CheatCommand( client, "z_spawn", "tank auto" );						// we cant teleport him to the tank, then give tank next to him.
		}
		else if ( StrContains( who, "Witch", false ) != INVALID_VALUE )
		{
			CheatCommand( client, "z_spawn", "witch auto" );					// we cant teleport him to the witch, then give witch next to him.
		}
		else if ( StrContains( who, "Infected", false ) != INVALID_VALUE )
		{
			switch( GetRandomInt( 1, 6 ))
			{
				case 1: { CheatCommand( client, "z_spawn", "smoker auto" ); }	// we cant teleport him to any SI, then give 1 next to him.
				case 2: { CheatCommand( client, "z_spawn", "boomer auto" ); }
				case 3: { CheatCommand( client, "z_spawn", "hunter auto" ); }
				case 4: { CheatCommand( client, "z_spawn", "spitter auto" ); }
				case 5: { CheatCommand( client, "z_spawn", "jockey auto" ); }
				case 6: { CheatCommand( client, "z_spawn", "charger auto" ); }
			}
		}
	}
	else
	{
		float _location[3];
		GetEntOrigin( scan, _location, 10.0 );
		TeleportEntity( client, _location, NULL_VECTOR, NULL_VECTOR );
		EmitSoundToClient( client, TELEPOT_SND );
		
		if ( g_bHinttext )
		{
			PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04Luffy %s Teleport.", who );
		}
	}
}

void RunLuffyHealth( int client ) //<< ok
{
	EmitSoundToClient( client, HEALTH_SND );
	g_bIsPlayerHPInterrupted[client] = false;
	g_hT_HealthRegen[client] = CreateTimer( 0.1, Timer_LuffyHealth, GetClientIndex( client, false ), TIMER_REPEAT );
	if ( g_bHinttext )
	{
		PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04Luffy Health" );
	}
}

void RunLuffyClock( int client ) //<< ok color = yellow
{
	int shield = SetupShield( client, SHIELD_TYPE_PUSH, 1 );
	if( shield != INVALID_VALUE )
	{
		EmitSoundToClient( client, CLOCK_SND );
		g_iHintCountdown[client] = g_iClockCoolDown;
		g_fAbilityCountdown[client] = float( g_iClockCoolDown );
		g_fClientTimeBuffer[client] = GetGameTime();
		SetRenderColour( client, g_iColor_Yellow, 220 );
		
		int userid = GetClientIndex( client, false );
		g_hT_LuffyClock[client] = CreateTimer( 0.1, Timer_LuffyClock, userid, TIMER_REPEAT );
		
		if ( g_bHinttext )
		{
			PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04Luffy Clock" );
			PrintHintText( client, "++ Luffy Clock last in %d sec ++", g_iClockCoolDown );
		}
	}
}

public Action Timer_LuffyClock( Handle timer, any userid ) //<< ok this have shield
{
	int client = GetClientIndex( userid, true );
	if ( IsValidSurvivor( client ))
	{
		if( IsPlayerAlive( client ) && g_bIsRoundStart )
		{
			g_fAbilityCountdown[client] -= 0.1 ;
			if( g_fAbilityCountdown[client] > 0.0 )
			{
				SetupShieldDorm( client, g_iColor_Yellow, SHIELD_DORM_RADIUS, g_iBeamSprite_Bubble, SHIELD_DORM_ALPHA );
				
				float pos_client[3];
				GetEntOrigin( client, pos_client, 20.0 );

				int shield = GetEntIndex_IsValid( g_iPlayerShield[client] );
				if( shield != INVALID_VALUE )
				{
					float currAng[3];
					GetEntAngle( shield, currAng, 20.0, AXIS_YAW );
					BoundAngleValue( currAng, currAng, 360.0, AXIS_YAW );			// prevent number from going huge
					
					if ( g_iShieldType == 1 )
					{
						TeleportEntity( shield, pos_client, currAng, NULL_VECTOR );
					}
					else
					{
						TeleportEntity( shield, NULL_VECTOR, currAng, NULL_VECTOR );
					}
				}
				
				float pos_target[3];
				char className[128];
				int  count_mdl = GetEntityCount();
				for ( int  i = 1; i <= count_mdl; i++ )
				{
					if ( i <= MaxClients )
					{
						if ( IsValidInfected( i ) && IsPlayerAlive( i ))
						{
							GetEntOrigin( i, pos_target, 20.0 );
							if ( GetVectorDistance( pos_client, pos_target ) <= SHIELD_RADIUS )
							{
								CreatePointHurt( client, i, 1, DAMAGE_EXPLOSIVE, pos_target, SHIELD_RADIUS );	// do 1 damage to tell the infected who is responsible for tackling his armpits.
								CreateShieldPush( client, i, SHIELD_PUSHCLOCK );								// we dont kill him, just push him harder
							}
						}
					}
					else
					{
						if ( IsValidEntity( i ))
						{
							GetEntityClassname( i, className, sizeof( className ));
							if ( StrEqual( className, "infected", false ) || StrEqual( className, "witch", false ))
							{
								GetEntOrigin( i, pos_target, 20.0 );
								if ( GetVectorDistance( pos_client, pos_target ) <= SHIELD_RADIUS )
								{
									CreatePointHurt( client, i, 1, DAMAGE_EXPLOSIVE, pos_target, SHIELD_RADIUS ); 	// do 1 damage to tell the witch who is responsible for tackling his armpits.
									CreateShieldPush( client, i, SHIELD_PUSHCLOCK );								// we dont kill him, just push him harder
								}
							}
						}
					}
				}
				
				if( g_bHinttext )
				{
					//calculate how long time has pass since we display our hint message
					float time = GetGameTime();
					float shif = time - g_fClientTimeBuffer[client];
					if( shif >= 1.0 )
					{
						g_iHintCountdown[client] -= 1;
						g_fClientTimeBuffer[client] = time;
					}
					
					if( g_bAllowCountdownMsg || g_iHintCountdown[client] == 3 || g_iHintCountdown[client] == 10 || g_iHintCountdown[client] == 20 )
					{
						PrintHintText( client, "++ Luffy Clock last in %d sec ++", g_iHintCountdown[client] );
					}
				}
				return Plugin_Continue;
			}
		}
		
		EmitSoundToClient( client, TIMEOUT_SND );
		ResetLuffyAbility( client );
		
		if ( g_bHinttext )
		{
			PrintHintText( client, "-- Luffy Clock time out --" );
		}
	}
	return Plugin_Stop;
}

void RunLuffySpeed( int client ) //<< ok color = blue
{
	EmitSoundToClient( client, SPEED_SND );
	g_iHintCountdown[client] = g_iSpeedCoolDown;
	g_fAbilityCountdown[client] = float( g_iSpeedCoolDown );
	g_fClientTimeBuffer[client] = GetGameTime();
	
	float speed = ( float( g_iSuperSpeedMax ) / 100.0 ) + 1.0;
	if ( speed > 2.0 ) speed = 2.0;
	if ( speed < 1.0 ) speed = 1.0;
	
	SetEntityGravity( client, 0.8 );
	SetEntPropFloat( client, Prop_Data, "m_flLaggedMovementValue", speed );
	SetRenderColour( client, g_iColor_LBlue, 220 );

	int userid = GetClientIndex( client, false );
	g_hT_LuffySpeed[client] = CreateTimer( 0.1, Timer_LuffySpeed, userid, TIMER_REPEAT );
	
	if ( g_bHinttext )
	{
		PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04Luffy Speed" );
		PrintHintText( client, "++ Luffy Speed last in %d sec ++", g_iSpeedCoolDown );
	}
}

public Action Timer_LuffySpeed( Handle timer, any userid ) //<< ok
{
	int client = GetClientIndex( userid, true );
	if ( IsValidSurvivor( client ))
	{
		if( IsPlayerAlive( client ) && g_bIsRoundStart )
		{
			g_fAbilityCountdown[client] -= 0.1 ;
			if( g_fAbilityCountdown[client] > 0.0 )
			{
				SetupShieldDorm( client, g_iColor_Blue, SHIELD_DORM_RADIUS, g_iBeamSprite_Bubble, SHIELD_DORM_ALPHA );
				
				if( g_bHinttext )
				{
					//calculate how long time has pass since we display our hint message
					float time = GetGameTime();
					float shif = time - g_fClientTimeBuffer[client];
					if( shif >= 1.0 )
					{
						g_iHintCountdown[client] -= 1;
						g_fClientTimeBuffer[client] = time;
					}
					
					if( g_bAllowCountdownMsg || g_iHintCountdown[client] == 3 || g_iHintCountdown[client] == 10 || g_iHintCountdown[client] == 20 )
					{
						PrintHintText( client, "++ Luffy Speed last in %d sec ++", g_iHintCountdown[client] );
					}
				}
				return Plugin_Continue;
			}
		}
		
		EmitSoundToClient( client, TIMEOUT_SND );
		ResetLuffyAbility( client );

		if ( g_bHinttext )
		{
			PrintHintText( client, "-- Luffy Speed time out --" );
		}
	}
	return Plugin_Stop;
}

void RunLuffyStrength( int client ) //<< test this ingame color = green
{
	EmitSoundToClient( client, STRENGTH_SND );
	g_iHintCountdown[client] = g_iStrengthCoolDown;
	g_fAbilityCountdown[client] = float( g_iStrengthCoolDown );
	SetEntityGravity( client, STRENGTH_GRAVITY );
	SetRenderColour( client,g_iColor_Green, 220 );
	
	float time = GetGameTime();
	g_fClientTimeBuffer[client]		= time;		// check how long since we display message to him
	g_fDoubleDashTimeLast[client]	= time;		// check his double dash key frame
	g_bIsDoubleDashPaused[client]	= false;
	
	int userid = GetClientIndex( client, false );
	g_hT_LuffyStrength[client] = CreateTimer( 0.1, Timer_LuffyStrength, userid, TIMER_REPEAT );
	
	if ( g_bHinttext )
	{
		PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04Luffy Strength" );
		PrintHintText( client, "++ Luffy Strength, press 'MOVE + SPACE' to Dash in midair ++", g_iStrengthCoolDown );
	}
}

public Action Timer_LuffyStrength( Handle timer, any userid ) //<< ok
{
	int client = GetClientIndex( userid, true );
	if ( IsValidSurvivor( client ))
	{
		if( IsPlayerAlive( client ) && g_bIsRoundStart )
		{
			if( (GetEntityFlags(client) & FL_ONGROUND) )
			{
				g_bIsDoubleDashPaused[client] = false;
			}
			
			g_fAbilityCountdown[client] -= 0.1 ;
			if( g_fAbilityCountdown[client] > 0.0 )
			{
				SetupShieldDorm( client, g_iColor_Green, SHIELD_DORM_RADIUS, g_iBeamSprite_Bubble, SHIELD_DORM_ALPHA );
				
				if( g_bHinttext )
				{
					//calculate how long time has pass since we display our hint message
					float time = GetGameTime();
					float shif = time - g_fClientTimeBuffer[client];
					if( shif >= 1.0 )
					{
						g_iHintCountdown[client] -= 1;
						g_fClientTimeBuffer[client] = time;
					}
					
					if( g_bAllowCountdownMsg || g_iHintCountdown[client] == 3 || g_iHintCountdown[client] == 10 || g_iHintCountdown[client] == 20 )
					{
						PrintHintText( client, "++ Luffy Strength last in %d sec ++", g_iHintCountdown[client] );
					}
				}
				return Plugin_Continue;
			}
		}
		
		EmitSoundToClient( client, TIMEOUT_SND );
		ResetLuffyAbility( client );
		
		if ( g_bHinttext )
		{
			PrintHintText( client, "-- Luffy Strength time out --" );
		}
	}
	return Plugin_Stop;
}

void RunLuffyShield( int client ) //<< ok color = red
{
	int shield = SetupShield( client, SHIELD_TYPE_DAMAGE, -1 );
	if( shield != INVALID_VALUE )
	{
		SetEntProp( client, Prop_Data, "m_takedamage", 0, 1 ); //<<<< i forget what is this, should be not taking damage. but setting it here is just wrong
		EmitSoundToClient( client, CLOCK_SND );
		
		g_iHintCountdown[client] = g_iShieldCoolDown;
		g_fAbilityCountdown[client] = float( g_iShieldCoolDown );
		g_fClientTimeBuffer[client] = GetGameTime();
		SetRenderColour( client, g_iColor_LRed, 220 );
		
		int userid = GetClientIndex( client, false );
		g_hT_LuffyShield[client] = CreateTimer( 0.1, Timer_LuffyShield, userid, TIMER_REPEAT );

		if ( g_bHinttext )
		{
			PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04Luffy Shield" );
			PrintHintText( client, "++ Luffy Shield last in %d sec ++", g_iShieldCoolDown );
		}
	}
}

public Action Timer_LuffyShield( Handle timer, any userid ) //<< ok this have shield <<< duh... the name says it.
{
	int client = GetClientIndex( userid, true );
	if ( IsValidSurvivor( client ))
	{
		if( IsPlayerAlive( client ) && g_bIsRoundStart )
		{
			g_fAbilityCountdown[client] -= 0.1 ;
			if( g_fAbilityCountdown[client] > 0.0 )
			{
				SetupShieldDorm( client, g_iColor_Red, SHIELD_DORM_RADIUS, g_iBeamSprite_Bubble, SHIELD_DORM_ALPHA );
				
				float pos_client[3];
				GetEntOrigin( client, pos_client, 0.0 );

				int shield = GetEntIndex_IsValid( g_iPlayerShield[client] );
				if( shield != INVALID_VALUE )
				{
					float currAng[3];
					GetEntAngle( shield, currAng, 20.0, AXIS_YAW );
					BoundAngleValue( currAng, currAng, 360.0, AXIS_YAW );		// prevent number from going huge
					
					if ( g_iShieldType == 1 )
					{
						float temp = pos_client[2];
						pos_client[2] += 30.0;
						TeleportEntity( shield, pos_client, currAng, NULL_VECTOR );
						pos_client[2] = temp;
					}
					else
					{
						TeleportEntity( shield, NULL_VECTOR, currAng, NULL_VECTOR );
					}
				}
				
				float pos_target[3];
				char className[64];
			
				int  eCount = GetEntityCount();
				for ( int  i = 1; i <= eCount; i++ )
				{
					if ( i <= MaxClients )
					{
						if ( IsValidInfected( i ) && IsPlayerAlive( i ))
						{
							GetEntOrigin( i, pos_target, 0.0 );
							if ( GetVectorDistance( pos_client, pos_target ) <= SHIELD_RADIUS )
							{
								if ( GetZclass( i ) == ZOMBIE_TANK )
								{
									CreatePointHurt( client, i, g_iTankDamage, DMG_GENERIC, pos_target, SHIELD_RADIUS );		// we give him some serious hits
									CreateShieldPush( client, i, SHIELD_PUSHSHIELD );											// but we dont push that hard
								}
								else
								{
									CreatePointHurt( client, i, g_iSuperShieldDamage, DMG_GENERIC, pos_target, SHIELD_RADIUS );	// we give him some serious hits
									CreateShieldPush( client, i, SHIELD_PUSHSHIELD );											// but we dont push that hard
								}
							}
						}
					}
					else
					{
						if ( IsValidEntity( i ))
						{
							GetEntityClassname( i, className, sizeof( className ));
							if ( StrEqual( className, "infected", false ) || StrEqual( className, "witch", false ))
							{
								GetEntOrigin( i, pos_target, 0.0 );
								if ( GetVectorDistance( pos_client, pos_target ) <= SHIELD_RADIUS )
								{
									CreatePointHurt( client, i, g_iSuperShieldDamage, DMG_GENERIC, pos_target, SHIELD_RADIUS );
									CreateShieldPush( client, i, SHIELD_PUSHSHIELD );
								}
							}
						}
					}
				}
				
				if( g_bHinttext )
				{
					//calculate how long time has pass since we display our hint message
					float time = GetGameTime();
					float shif = time - g_fClientTimeBuffer[client];
					if( shif >= 1.0 )
					{
						g_iHintCountdown[client] -= 1;
						g_fClientTimeBuffer[client] = time;
					}
					
					if( g_bAllowCountdownMsg || g_iHintCountdown[client] == 3 || g_iHintCountdown[client] == 10 || g_iHintCountdown[client] == 20 )
					{
						PrintHintText( client, "++ Luffy Shield last in %d sec ++", g_iHintCountdown[client] );
					}
				}
				return Plugin_Continue;
			}
		}
		
		EmitSoundToClient( client, TIMEOUT_SND );
		ResetLuffyAbility( client );

		if ( g_bHinttext )
		{
			PrintHintText( client, "-- Luffy Shield time out --" );
		}
	}
	return Plugin_Stop;
}

int SetupShield( int client, int type, int color ) //<< ok
{
	// shield type 1 = damage
	// shield type 2 = decoration
	// shield type 3 = push
	
	float wPos[3];
	float wAng[3];
	GetEntOrigin( client, wPos, 30.0 );
	GetEntAngle( client, wAng, 0.0, 0 );

	int  wingcenter = CreatEntRenderModel( PROPTYPE_DYNAMIC, SDKHOOK_DMY, wPos, wAng, 0.01 );
	if( wingcenter != INVALID_VALUE )
	{
		if ( g_iShieldType == 0 )
		{
			SetVariantString( "!activator" );
			AcceptEntityInput( wingcenter, "SetParent", client );
			SetVariantString( "spine" );
			AcceptEntityInput( wingcenter, "SetParentAttachment" );
			
			float pos[3] = { 0.0, 0.0, 0.0 };
			float ang[3] = { 0.0, 0.0, -90.0 };
			TeleportEntity( wingcenter, ang, pos, NULL_VECTOR);
		}
		
		SetRenderColour( wingcenter, g_iColor_White, 0 );
		g_iPlayerShield[client] = EntIndexToEntRef( wingcenter );
		
		/// attach the wing here
		int  numberWing;
		if ( type == SHIELD_TYPE_DAMAGE || type == SHIELD_TYPE_PUSH )
		{
			numberWing = 6;		// any number will do. it depend on our taste
			EmitSoundToClient( client, SUPERSHIELD_SND );
		}
		else
		{
			numberWing = 4;		// any number will do. it depend on our taste. this serve as decoration only.
		}
		
		float wingRadius		= SHIELD_RADIUS;				// wide of our wing opening, wing type 1 and 2 may not show correct distance due to its own orientation from parent.
		float incRadius			= 360.0 / float( numberWing );	// calculate space between our wing.
		float wingAngle			= 0.0;							// wing attachment start angle
		float wingFacing		= 90.0;							// manipulate which side of our wing facing
		float wingPosition[3]	= { 0.0, 0.0, 0.0 };			// position of our wing relative to the parent/center/body. whatever the name
		
		bool iswingsuccsess = true;								// check if our creation fully assemble
		int wing;
		// we draw a circle and determine each intersection point/distance for attachment
		for ( int i = 1; i <= numberWing; i ++ )
		{
			wingPosition[0] = wingRadius * Cosine( DegToRad( wingAngle ));	// calculate the intersect between radius and angle
			wingPosition[1] = wingRadius * Sine( DegToRad( wingAngle ));	// calculate the intersect between radius and angle
			
			wing = AttachWing( wingcenter, wPos, wingPosition, wingFacing, type, color );
			if ( wing == INVALID_VALUE )
			{
				PrintToServer( "" );
				PrintToServer( "|LUFFY| Error, wing creation failed |LUFFY|" );
				PrintToServer( "" );
				iswingsuccsess = false;
				break;
			}
			wingAngle	+= incRadius;	// next point attachment
			wingFacing	+= incRadius;	// where should our next wing facing.
		}
		
		// wing creation failed. delete all garbage
		if( !iswingsuccsess )
		{
			// for fail safe check. dont flood our server with garbage.
			DeletePlayerShield( client );
			wingcenter = INVALID_VALUE;
		}
	}
	return wingcenter;
}

int AttachWing( int parent, float pos_world[3], float pos_parent[3], float ang_adjustment, int type, int color ) //<< ok
{
	char model[128];
	float scale = g_fModelScale[POS_JETF18];
	Format( model, sizeof( model ), g_sModelBuffer[POS_JETF18] );

	float buffAng[3] = { 0.0, 0.0, 0.0 };
	if ( type == 1 )
	{
		buffAng[1] = ang_adjustment;
	}
	else if ( type == 2 )
	{
		buffAng[0] = -90.0;
		buffAng[1] = ( ang_adjustment + 90.0 );
	}
	else if ( type == 3 )
	{
		scale = 1.0;
		Format( model, sizeof( model ), RIOTSHIELD_MDL );
		buffAng[1] = ( ang_adjustment - 90.0 );
	}
	
	int  shield = CreatEntChild( parent, model, pos_world, pos_parent, buffAng, scale );
	if ( shield != INVALID_VALUE )
	{
		if ( type == 1 )
		{
			SetRenderColour( shield, g_iColor_White, 100 );
			ToggleGlowEnable( shield, true );
		}
		else if ( type == 2 )
		{
			if ( color == 1 ) SetRenderColour( shield, g_iColor_LRed, 70 );
			if ( color == 2 ) SetRenderColour( shield, g_iColor_LBlue, 70 );
			if ( color == 3 ) SetRenderColour( shield, g_iColor_LGreen, 70 );
		}
		else if ( type == 3 )
		{
			SetRenderColour( shield, g_iColor_Dark, 100 );
			ToggleGlowEnable( shield, true );
		}
	}
	return shield;
}

void DeletePlayerShield( int client )	//<< ok
{
	int shield = GetEntIndex_IsValid( g_iPlayerShield[client] );
	RemoveEntity_ClearParent( shield );
	g_iPlayerShield[client] = INVALID_VALUE;
}

void RunFreezeClient( int client ) //<< ok
{
	// froze his button
	FreezePlayerButton( client, true );
	
	float playerPos[3];
	GetEntOrigin( client, playerPos, 10.0 );
	switch( GetRandomInt( 1, 2 ))
	{
		case 1:
		{
			// freeze him for 10 second and give him explosion
			g_iUnfreezCountdown[client] = 10;
			switch( GetRandomInt( 1, 2 ))
			{
				case 1: { CreatPointDamageRadius( playerPos, PARTICLE_ELECTRIC1, 30, 300, client ); }
				case 2: { CreatPointDamageRadius( playerPos, PARTICLE_ELECTRIC2, 30, 300, client );	}
			}
			if( g_fAbilityCountdown[client] == 0.0 )		// if player ability still active, we dont spoil/overwrite the color
			{
				SetRenderColour( client, g_iColor_LBlue, 180 );
			}
		}
		case 2:
		{
			// freeze him and give him fire for 3 second
			g_iUnfreezCountdown[client] = 3;
			if( g_fAbilityCountdown[client] == 0.0 )		// if player ability still active, we dont spoil/overwrite the color
			{
				SetRenderColour( client, g_iColor_LRed, 180 );
			}
			CreatPointDamageRadius( playerPos, PARTICLE_CREATEFIRE, 20, 300, client );
		}
	}

	g_hT_MoveFreeze[client] = CreateTimer( 1.0, Timer_RestoreFrozenButton, GetClientIndex( client, false ), TIMER_REPEAT );
	EmitSoundToAll( FREEZE_SND, client, SNDCHAN_AUTO );
	PrintHintText( client, "-- You will be unfreze in %d sec --", g_iUnfreezCountdown[client] );
}

public Action Timer_RestoreFrozenButton( Handle timer, any userid )	//<< ok
{
	int client = GetClientIndex( userid, true );
	if( IsValidSurvivor( client ))
	{
		if( IsPlayerAlive( client ) && g_bIsRoundStart )
		{
			g_iUnfreezCountdown[client]--;
			if( g_iUnfreezCountdown[client] > 0 )
			{
				if( !IsPlayerIncap( client ) && !IsPlayerLedge( client ))
				{
					if ( g_bHinttext  && g_fAbilityCountdown[client] == 0.0 || !g_bAllowCountdownMsg )
					{
						PrintHintText( client, "-- You will be unfreze in %d sec --", g_iUnfreezCountdown[client] );
					}
					return Plugin_Continue;
				}
			}
		}
		
		// unfroze his button
		FreezePlayerButton( client, false );
		
		EmitSoundToClient( client, FREEZE_SND );
		g_hT_MoveFreeze[client] = INVALID_HANDLE;
		
		if( g_fAbilityCountdown[client] == 0.0 )
		{
			SetRenderColour( client, g_iColor_White, 255 );
		}
		
		if ( g_bHinttext )
		{
			PrintHintText( client, "++ You were unfrezed ++" );
		}
	}
	return Plugin_Stop;
}

void RunLuffyPunishment( int client ) //<< ok
{
	switch( GetRandomInt( 1, 5 ))
	{
		case 1 : { RewardTeleport( client, "Tank" );		}
		case 2 : { RewardTeleport( client, "Witch" );		}
		case 3 : { RewardTeleport( client, "Infected" );	}
		case 4 : { RunFreezeClient( client );				}
		case 5 : { RunFreezeClient( client );				}
	}
}

void ResetLuffyAbility( int client ) //<< ok
{
	DeletePlayerShield( client );
	
	g_fAbilityCountdown[client] = 0.0;
	g_fClientTimeBuffer[client] = 0.0;
	g_iHintCountdown[client] = 0;
	
	SetEntityGravity( client, 1.0 );
	SetEntProp( client, Prop_Data, "m_takedamage", 2, 1 );
	SetEntPropFloat( client, Prop_Data, "m_flLaggedMovementValue", 1.0 );

	SetRenderColour( client, g_iColor_White, 255 );
	g_hT_LuffyClock[client] = INVALID_HANDLE;
	g_hT_LuffySpeed[client] = INVALID_HANDLE;
	g_hT_LuffyShield[client] = INVALID_HANDLE;
	g_hT_LuffyStrength[client] = INVALID_HANDLE;
}

void DropRandomWeapon( int client, int selection )		//<< ok
{
	int  r;
	switch( selection )
	{
		case 0:
		{
			r = GetRandomInt( 1, 6 ); // t1 selection
		}
		case 1:
		{
			r = GetRandomInt( 7, 17 ); // t2 selection
		}
		case 2:
		{
			r = GetRandomInt( 1, 17 ); // t1 and t2 selection
		}
	}
	
	switch( r )
	{
		// T1 weapon
		case 1:
		{
			GivePlayerItems( client, "weapon_smg" );
		}
		case 2:
		{
			GivePlayerItems( client, "weapon_smg_silenced" );
		}
		case 3:
		{
			GivePlayerItems( client, "weapon_smg_mp5" );
		}
		case 4:
		{
			GivePlayerItems( client, "weapon_pumpshotgun" );
		}
		case 5:
		{
			GivePlayerItems( client, "weapon_shotgun_chrome" );
		}
		case 6:
		{
			GivePlayerItems( client, "weapon_hunting_rifle" );
		}
		// T2 weapon
		case 7:
		{
			GivePlayerItems( client, "weapon_rifle_m60" );
		}
		case 8:
		{
			GivePlayerItems( client, "weapon_grenade_launcher" );
		}
		case 9:
		{
			GivePlayerItems( client, "weapon_rifle" );
		}
		case 10:
		{
			GivePlayerItems( client, "weapon_rifle_ak47" );
		}
		case 11:
		{
			GivePlayerItems( client, "weapon_rifle_desert" );
		}
		case 12:
		{
			GivePlayerItems( client, "weapon_rifle_sg552" );
		}
		case 13:
		{
			GivePlayerItems( client, "weapon_shotgun_spas" );
		}
		case 14:
		{
			GivePlayerItems( client, "weapon_autoshotgun" );
		}
		case 15:
		{
			GivePlayerItems( client, "weapon_sniper_scout" );
		}
		case 16:
		{
			GivePlayerItems( client, "weapon_sniper_military" );
		}
		default:
		{
			GivePlayerItems( client, "weapon_sniper_awp" );
		}
	}
}

int GivePlayerItems( int client, const char[] item_name )		//<< ok 
{
	bool glow = true;
	char name_buffer[32];
	float z_pos = 30.0;
	
	if ( StrEqual( item_name, "weapon_rifle_m60", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Rifle M60" );
		if( client <= MaxClients )
		{
			EmitSoundToClient( client, REWARD_SND );	// the witch cant hear this
		}
	}
	else if ( StrEqual( item_name, "weapon_grenade_launcher", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Grenade Launcher" );
		if( client <= MaxClients )
		{
			EmitSoundToClient( client, REWARD_SND );	// the witch cant hear this
		}
	}
	else if ( StrEqual( item_name, "weapon_rifle", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Rifle M16" );
	}
	else if ( StrEqual( item_name, "weapon_rifle_ak47", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Rifle AK47" );
	}
	else if ( StrEqual( item_name, "weapon_rifle_desert", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Rifle Desert" );
	}
	else if ( StrEqual( item_name,"weapon_rifle_sg552", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Rifle SG552" );
	}
	else if ( StrEqual( item_name, "weapon_shotgun_spas", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Shotgun SPAS" );
	}
	else if ( StrEqual( item_name, "weapon_autoshotgun", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Auto Shotgun" );
	}
	else if ( StrEqual( item_name, "weapon_sniper_awp", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Sniper AWP" );
	}
	else if ( StrEqual( item_name, "weapon_sniper_military", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Sniper Military" );
	}
	else if ( StrEqual( item_name, "weapon_sniper_scout", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Sniper Scout" );
	}
	else if ( StrEqual( item_name, "weapon_hunting_rifle", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Hunting Rifle" );
	}
	else if ( StrEqual( item_name, "weapon_shotgun_chrome", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Shotgun Chrome" );
	}
	else if ( StrEqual( item_name, "weapon_pumpshotgun", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Pump Shotgun" );
	}
	else if ( StrEqual( item_name, "weapon_smg", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "SMG" );
	}
	else if ( StrEqual( item_name, "weapon_smg_silenced", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "SMG Silenced" );
	}
	else if ( StrEqual( item_name, "weapon_smg_mp5", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "SMG MP5" );
	}
	else if ( StrEqual( item_name, "weapon_upgradepack_explosive", false ))
	{
		Format( name_buffer, sizeof( name_buffer ), "Explosive Box" );
	}
	else if ( StrEqual( item_name, "weapon_upgradepack_incendiary", false ))
	{
		Format( name_buffer, sizeof( name_buffer ), "Incendiary Box" );
	}
	else if ( StrEqual( item_name, "weapon_first_aid_kit", false ))
	{
		Format( name_buffer, sizeof( name_buffer ), "First Aid Kit" );
	}
	else if ( StrEqual( item_name, "weapon_defibrillator", false ))
	{
		Format( name_buffer, sizeof( name_buffer ), "Defibrillator" );
		if( client <= MaxClients )
		{
			EmitSoundToClient( client, REWARD_SND );	// the witch cant hear this
		}
	}
	else if ( StrEqual( item_name, "weapon_pipe_bomb", false ))
	{
		Format( name_buffer, sizeof( name_buffer ), "Pipe Bomb" );
	}
	else if ( StrEqual( item_name, "weapon_molotov", false ))
	{
		Format( name_buffer, sizeof( name_buffer ), "Molotove" );
	}
	else if ( StrEqual( item_name, "weapon_vomitjar", false ))
	{
		Format( name_buffer, sizeof( name_buffer ), "Vomit Jar" );
	}
	else if ( StrEqual( item_name, "weapon_pain_pills", false ))
	{
		Format( name_buffer, sizeof( name_buffer ), "Pain Pill" );
	}
	else if ( StrEqual( item_name, "weapon_adrenaline", false ))
	{
		Format( name_buffer, sizeof( name_buffer ), "Adrenaline Syrange" );
	}
	else if ( StrEqual( item_name, "upgrade_laser_sight", false ))
	{
		z_pos = 0.0;
		Format( name_buffer, sizeof( name_buffer ), "Upgrade Laser Sight" );
		if( client <= MaxClients )
		{
			EmitSoundToClient( client, REWARD_SND );	// the witch cant hear this
		}
	}
	else if ( StrEqual( item_name, "weapon_ammo_spawn", false ))
	{
		z_pos = 0.0;
		Format( name_buffer, sizeof( name_buffer ), "Ammo Pile" );
		if( client <= MaxClients )
		{
			EmitSoundToClient( client, REWARD_SND );	// the witch cant hear this
		}
	}
	
	float pos[3];
	float ang[3];
	GetEntOrigin( client, pos, z_pos );
	GetEntAngle( client, ang, 0.0, 0 );
	
	int  entity = CreateWeaponEntity( item_name, pos, ang );
	if( entity != INVALID_VALUE )
	{
		int  wp = GetEmptyWeaponDropBuffer();
		if ( wp != INVALID_VALUE )
		{
			g_iWeaponDropBuffer[wp] = EntIndexToEntRef( entity );
		}
		
		if ( glow )
		{
			ToggleGlowEnable( entity, true );
		}
		
		if ( g_bHinttext && client <= MaxClients )
		{
			PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04%s", name_buffer );	// the witch cant read this
		}
	}
	else
	{
		PrintToServer( "|LUFFY| GivePlayerItems() failed.. check your spelling |LUFFY|" );
	}
	return entity;
}

int GetEmptyWeaponDropBuffer()     //<< ok
{
	for( int  i = 0; i < SIZE_DROPBUFF; i++ )
	{
		if ( g_iWeaponDropBuffer[i] == INVALID_VALUE )
		{
			return i;
		}
	}
	return INVALID_VALUE;
}

int CompareWeaponDropBuffer( int entity )     //<< ok
{
	int item;
	for( int  i = 0; i < SIZE_DROPBUFF; i++ )
	{
		if ( g_iWeaponDropBuffer[i] != INVALID_VALUE )
		{
			item = GetEntIndex_IsValid( g_iWeaponDropBuffer[i] );
			if( item != INVALID_VALUE && item == entity )
			{
				return i;
			}
		}
	}
	return INVALID_VALUE;
}

void SetupBloodSpark( int client )	//<< ok
{
	float pos[3];
	for ( int  i = 0; i <= 5; i++ )
	{
		// make our sprite appear random position near player
		GetEntOrigin( client, pos, GetRandomFloat( 10.0, 80.0 ));
		pos[0] += GetRandomFloat( -30.0, 30.0 );
		pos[1] += GetRandomFloat( -30.0, 30.0 );
		
		int color[4];
		int alpha = 80;
		switch( GetRandomInt( 1, 6 ))
		{
			case 1:
			{
				CopyColor_SetAlpha( g_iColor_Red, color, alpha );
			}
			case 2:
			{
				CopyColor_SetAlpha( g_iColor_Green, color, alpha );
			}
			case 3:
			{
				CopyColor_SetAlpha( g_iColor_Blue, color, alpha );
			}
			case 4:
			{
				CopyColor_SetAlpha( g_iColor_LGreen, color, alpha );
			}
			case 5:
			{
				CopyColor_SetAlpha( g_iColor_Pinky, color, alpha );
			}
			case 6:
			{
				CopyColor_SetAlpha( g_iColor_Yellow, color, alpha );
			}
		}
		
		TE_SetupBloodSprite( pos, NULL_VECTOR, color, GetRandomInt( 20, 60 ), g_iBeamSprite_Blood, g_iBeamSprite_Blood );
		TE_SendToAll();
		
		// random to make it sound appealing
		switch( GetRandomInt( 1, 3 )) {
			case 1: {
				EmitSoundToAll( ZAP_1_SND, client, SNDCHAN_AUTO );
			}
			case 2: {
				EmitSoundToAll( ZAP_2_SND, client, SNDCHAN_AUTO );
			}
			case 3: {
				EmitSoundToAll( ZAP_3_SND, client, SNDCHAN_AUTO );
			}
		}
	}
}

void ToggleGlowEnable( int entity, bool enable ) //<< ok
{
	int  m_glowtype = 0;
	int  m_glowcolor = 0;
	
	if ( enable )
	{
		m_glowtype = 3;
		
		int select;
		int color_rgb[3];

		int glow_type = g_iItemGlowType;
		if ( glow_type < 1 || glow_type > 6 )
		{
			glow_type = 6;
		}
		
		if ( glow_type == 6 )
		{
			select = GetRandomInt( 1, 5 );
		}
		else
		{
			select = glow_type;
		}
		
		switch( select )
		{
			case 1:
			{
				CopyColor( g_iColor_Red, color_rgb );
			}
			case 2:
			{
				CopyColor( g_iColor_Green, color_rgb );
			}
			case 3:
			{
				CopyColor( g_iColor_Blue, color_rgb );
			}
			case 4:
			{
				CopyColor( g_iColor_Pinky, color_rgb );
			}
			case 5:
			{
				CopyColor( g_iColor_Yellow, color_rgb );
			}
		}
		m_glowcolor = color_rgb[0] + ( color_rgb[1] * 256 ) + ( color_rgb[2] * 65536 );
	}
	SetEntProp( entity, Prop_Send, "m_iGlowType", m_glowtype );
	SetEntProp( entity, Prop_Send, "m_nGlowRange", 0 );
	SetEntProp( entity, Prop_Send, "m_glowColorOverride", m_glowcolor );
}

void CheatCommand( int client, const char[] cheats, const char[] command )   //<< ok
{
	if ( StrContains( command, "witch auto", false ) != INVALID_VALUE )
	{
		if( FindEntityAndCount( INVALID_VALUE, "Witch" ) < g_iWitchMax )
		{
			EmitSoundToClient( client, WITCH_SND );
			if ( g_bAllowMessage == true ) PrintToChatAll( "\x04[\x05LUFFY\x04]: \x04%N \x05acquired \x04Luffy Witch!!", client );
		}
		else
		{
			return;
		}
	}
	else if ( StrContains( command, "tank auto", false ) != INVALID_VALUE )
	{
		if( FindEntityAndCount( INVALID_VALUE, "Tank" ) < g_iTankMax )
		{
			EmitSoundToClient( client, TANK_SND );
			if ( g_bAllowMessage == true ) PrintToChatAll( "\x04[\x05LUFFY\x04]: \x04%N \x05acquired \x04Luffy Tank!!", client );
		}
		else
		{
			return;
		}
	}
	else if ( StrContains( cheats, "director_force_panic_event", false ) != INVALID_VALUE )
	{
		if ( g_bAllowMessage == true ) PrintToChatAll( "\x04[\x05LUFFY\x04]: \x04%N \x05acquired \x04Luffy Panic!!", client );
	}
	
	int  userflags = GetUserFlagBits( client );
	int  cmdflags = GetCommandFlags( cheats );
	
	
	SetUserFlagBits( client, ADMFLAG_ROOT );
	SetCommandFlags( cheats, cmdflags & ~FCVAR_CHEAT );
	FakeClientCommand( client,"%s %s", cheats, command );
	SetCommandFlags( cheats, cmdflags );
	SetUserFlagBits( client, userflags );
}

int FindEntityAndCount( int client, const char[] _findWhat ) //<< ok
{
	int  scan = 0;
	if ( StrEqual( _findWhat, "Tank", false ))
	{
		for ( int  i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidInfected( i ) && IsPlayerAlive( i ))
			{
				if ( GetZclass( i ) == ZOMBIE_TANK )
				{
					scan += 1;
				}
			}
		}
	}
	else if ( StrEqual( _findWhat, "Witch", false ))
	{
		char _name[64];
		int  _max	= GetEntityCount();
		for ( int  i = MaxClients; i <= _max; i++ )
		{
			if ( IsValidEntity( i ))
			{
				GetEntityClassname( i, _name, sizeof( _name ));
				if ( StrContains( _name, "witch", false) != INVALID_VALUE )
				{
					//if ( GetEntProp( i, Prop_Data, "m_iHealth" ) > 1 )	//<< this check will crash the server
					//{
						scan += 1;
					//}
				}
			}
		}
	}
	else if ( StrEqual( _findWhat, "Survivor", false ))
	{
		for ( int  i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidSurvivor( i ) && i != client )
			{
				scan += 1;
				break;
			}
		}
	}
	return scan;
}

bool RestockPrimaryAmmo( int client, int multiplayer )    //<< ok
{
	char weapon_name[64];
	int weapon = GetPlayerWeaponSlot( client, 0 );
	if( weapon > MaxClients && IsValidEntity( weapon ))
	{
		GetEntityClassname( weapon, weapon_name, sizeof( weapon_name ));
		int  ammoStock	= 0;

		if ( StrEqual( weapon_name, "weapon_rifle_m60", false ))
		{
			ammoStock = GetConVarInt( FindConVar( "ammo_m60_max" ));
		}
		else if ( StrEqual( weapon_name, "weapon_grenade_launcher", false ))
		{
			ammoStock = GetConVarInt( FindConVar("ammo_grenadelauncher_max"));
		}
		else if ( StrEqual( weapon_name, "weapon_rifle", false ) || StrEqual( weapon_name, "weapon_rifle_ak47", false ) || StrEqual( weapon_name, "weapon_rifle_desert", false ) || StrEqual( weapon_name,"weapon_rifle_sg552", false ))
		{
			ammoStock = GetConVarInt( FindConVar( "ammo_assaultrifle_max" ));
		}
		else if ( StrEqual( weapon_name, "weapon_shotgun_spas", false ) || StrEqual( weapon_name, "weapon_autoshotgun", false ))
		{
			ammoStock = GetConVarInt( FindConVar( "ammo_autoshotgun_max" ));
		}
		else if ( StrEqual( weapon_name, "weapon_sniper_awp", false ) || StrEqual( weapon_name, "weapon_sniper_military", false ) || StrEqual( weapon_name, "weapon_sniper_scout", false ))
		{
			ammoStock = GetConVarInt( FindConVar( "ammo_sniperrifle_max" ));
		}
		else if ( StrEqual( weapon_name, "weapon_hunting_rifle", false ))
		{
			ammoStock = GetConVarInt( FindConVar( "ammo_huntingrifle_max" ));
		}
		else if ( StrEqual( weapon_name, "weapon_shotgun_chrome", false ) || StrEqual( weapon_name, "weapon_pumpshotgun", false ))
		{
			ammoStock = GetConVarInt( FindConVar( "ammo_shotgun_max" ));
		}
		else if ( StrEqual( weapon_name, "weapon_smg", false ) || StrEqual( weapon_name, "weapon_smg_silenced", false ) || StrEqual( weapon_name, "weapon_smg_mp5", false ))
		{
			ammoStock = GetConVarInt( FindConVar( "ammo_smg_max" ));
		}
		
		if ( ammoStock > 0 )
		{
			ammoStock *= multiplayer;
			int  iPrimType = GetEntProp( weapon, Prop_Send, "m_iPrimaryAmmoType");
			SetEntProp( client, Prop_Send, "m_iAmmo", ammoStock, _, iPrimType );
			EmitSoundToClient( client, AMMOPICKUP_SND );
			return true;
		}
	}
	return false;
}

void PCMasterRace_Render_ARGB( int client, int alpha )
{
	// gamers.. i give ya a real rgb in l4d2 special for that expensive pc build..
	switch( GetRandomInt( 1, 3 ))
	{
		case 1:
		{
			SetupShieldDorm( client, g_iColor_Blue, (SHIELD_DORM_RADIUS - 100), g_iBeamSprite_Bubble, alpha );
			SetupShieldDorm( client, g_iColor_Green, (SHIELD_DORM_RADIUS - 50), g_iBeamSprite_Bubble, alpha );
			SetupShieldDorm( client, g_iColor_Red, SHIELD_DORM_RADIUS, g_iBeamSprite_Bubble, alpha );
		}
		case 2:
		{
			SetupShieldDorm( client, g_iColor_Red, (SHIELD_DORM_RADIUS - 100), g_iBeamSprite_Bubble, alpha );
			SetupShieldDorm( client, g_iColor_Blue, (SHIELD_DORM_RADIUS - 50), g_iBeamSprite_Bubble, alpha );
			SetupShieldDorm( client, g_iColor_Green, SHIELD_DORM_RADIUS, g_iBeamSprite_Bubble, alpha );
		}
		case 3:
		{
			SetupShieldDorm( client, g_iColor_Green, (SHIELD_DORM_RADIUS - 100), g_iBeamSprite_Bubble, alpha );
			SetupShieldDorm( client, g_iColor_Red, (SHIELD_DORM_RADIUS - 50), g_iBeamSprite_Bubble, alpha );
			SetupShieldDorm( client, g_iColor_Blue, SHIELD_DORM_RADIUS, g_iBeamSprite_Bubble, alpha );
		}
	}
}
