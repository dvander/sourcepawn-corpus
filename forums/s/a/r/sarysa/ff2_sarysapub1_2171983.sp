/**
 * sarysa's Public Pack #1
 */

#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

/**
 * Rages for Thi Barrett, a character of Rise of the Triad and a hale I'm working on.
 *
 * Note that ROTTProps and ROTTWeapons, if used by two bosses in a multi-boss setup, cannot be distinct for each boss.
 * There's too much to monitor for it to be practical (especially data size-wise) to also have tons of player-sized arrays involved.
 *
 * ROTTProps: Spawns Rise of the Triad props with the RELOAD key. Some props are for utility (like jump pads/45deg jump pads) while others
 *	      are damage rects. (like that spinning skewering thing) User can select between them with either SPECIAL or action slot.
 * Known Issues: Trains will destroy props that are above (or presumably below) them.
 *		 Due to the nature of the angle jump pads, they can easily spawn behind walls if user's back is to a wall. No real clean way around this.
 *
 * ROTTWeapons: E/G rage, gives the rager a random (they don't get to pick) weapon or powerup from ROTT.
 *     Credits: Asherkin and voogru I took some of their rocket spawning code, though I came up with my own brand of homing projectiles.
 * Known Issues: For armor to work, the hale must have a melee weapon specified with one of the ROTT melee weapon rage(s). I don't use the three 
 *		 vaccinator conditions because I've experienced rare crashes caused with those. (I'd rather not describe how it's done)
 *		 For some weird reason some base weapon attributes are leaking in for me, which is why I only went with rocket launchers
 *		 that are reskins of the default, or just don't matter in FF2 like the Black Box.
 *		 Split and Drunk missile use lazy math which is obvious when you shoot upwards or downwards. I've decided not to care.
 *		 Can't have real rocket jumping because of FF2 blocking self-damage and weighdown making crouching problematic, so 
 *		 I've implemented a close-enough variety. Most players will pick up on it quickly.
 *
 * Overall Credits: Some snippets taken from core FF2 code.
 *		    Friagram for pointing out some improvements for some of my earlier stocks.
 */
 
// copied from tf2 sdk
// solid types
#define SOLID_NONE 0 // no solid model
#define SOLID_BSP 1 // a BSP tree
#define SOLID_BBOX 2 // an AABB
#define SOLID_OBB 3 // an OBB (not implemented yet)
#define SOLID_OBB_YAW 4 // an OBB, constrained so that it can only yaw
#define SOLID_CUSTOM 5 // Always call into the entity for tests
#define SOLID_VPHYSICS 6 // solid vphysics object, get vcollide from the model and collide with that

#define FSOLID_CUSTOMRAYTEST 0x0001 // Ignore solid type + always call into the entity for ray tests
#define FSOLID_CUSTOMBOXTEST 0x0002 // Ignore solid type + always call into the entity for swept box tests
#define FSOLID_NOT_SOLID 0x0004 // Are we currently not solid?
#define FSOLID_TRIGGER 0x0008 // This is something may be collideable but fires touch functions
#define FSOLID_NOT_STANDABLE 0x0010 // You can't stand on this
#define FSOLID_VOLUME_CONTENTS 0x0020 // Contains volumetric contents (like water)
#define FSOLID_FORCE_WORLD_ALIGNED 0x0040 // Forces the collision rep to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
#define FSOLID_USE_TRIGGER_BOUNDS 0x0080 // Uses a special trigger bounds separate from the normal OBB
#define FSOLID_ROOT_PARENT_ALIGNED 0x0100 // Collisions are defined in root parent's local coordinate space
#define FSOLID_TRIGGER_TOUCH_DEBRIS 0x0200 // This trigger will touch debris objects

enum // Collision_Group_t in const.h
{
	COLLISION_GROUP_NONE  = 0,
	COLLISION_GROUP_DEBRIS,			// Collides with nothing but world and static stuff
	COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
	COLLISION_GROUP_INTERACTIVE_DEBRIS,	// Collides with everything except other interactive debris or debris
	COLLISION_GROUP_INTERACTIVE,	// Collides with everything except interactive debris or debris
	COLLISION_GROUP_PLAYER,
	COLLISION_GROUP_BREAKABLE_GLASS,
	COLLISION_GROUP_VEHICLE,
	COLLISION_GROUP_PLAYER_MOVEMENT,  // For HL2, same as Collision_Group_Player, for
										// TF2, this filters out other players and CBaseObjects
	COLLISION_GROUP_NPC,			// Generic NPC group
	COLLISION_GROUP_IN_VEHICLE,		// for any entity inside a vehicle
	COLLISION_GROUP_WEAPON,			// for any weapons that need collision detection
	COLLISION_GROUP_VEHICLE_CLIP,	// vehicle clip brush to restrict vehicle movement
	COLLISION_GROUP_PROJECTILE,		// Projectiles!
	COLLISION_GROUP_DOOR_BLOCKER,	// Blocks entities not permitted to get near moving doors
	COLLISION_GROUP_PASSABLE_DOOR,	// ** sarysa TF2 note: Must be scripted, not passable on physics prop (Doors that the player shouldn't collide with)
	COLLISION_GROUP_DISSOLVING,		// Things that are dissolving are in this group
	COLLISION_GROUP_PUSHAWAY,		// ** sarysa TF2 note: I could swear the collision detection is better for this than NONE. (Nonsolid on client and server, pushaway in player code)

	COLLISION_GROUP_NPC_ACTOR,		// Used so NPCs in scripts ignore the player.
	COLLISION_GROUP_NPC_SCRIPTED,	// USed for NPCs in scripts that should not collide with each other

	LAST_SHARED_COLLISION_GROUP
};
 
new bool:DEBUG_FORCE_RAGE = false;
#define ARG_LENGTH 256
 
new bool:PRINT_DEBUG_INFO = true;
new bool:PRINT_DEBUG_SPAM = false;
new bool:DEBUG_HUD = false;
 
new Float:OFF_THE_MAP[3] = { 16383.0, 16383.0, -16383.0 };

// text string limits
#define MAX_SOUND_FILE_LENGTH 80
#define MAX_MODEL_FILE_LENGTH 128
#define MAX_MATERIAL_FILE_LENGTH 128
#define MAX_WEAPON_NAME_LENGTH 64
#define MAX_WEAPON_ARG_LENGTH 256
#define MAX_EFFECT_NAME_LENGTH 48
#define MAX_ENTITY_CLASSNAME_LENGTH 48
#define MAX_CENTER_TEXT_LENGTH 170
#define MAX_RANGE_STRING_LENGTH 66
#define MAX_HULL_STRING_LENGTH 197
#define COLOR_BUFFER_SIZE 12
#define HEX_OR_DEC_STRING_LENGTH 12 // max -2 billion is 11 chars + null termination

#define MAX_PLAYERS_ARRAY 36
#define MAX_PLAYERS (MAX_PLAYERS_ARRAY < (MaxClients + 1) ? MAX_PLAYERS_ARRAY : (MaxClients + 1))

//new MercTeam = _:TFTeam_Red;
new BossTeam = _:TFTeam_Blue;

new RoundInProgress = false;
new bool:PluginActiveThisRound = false;

#define IsEmptyString(%1) (%1[0] == 0)

public Plugin:myinfo = {
	name = "Freak Fortress 2: sarysa's public mods, first pack (ROTT boss)",
	author = "sarysa",
	version = "1.1.1",
}

// debug mode, free props
new bool:RP_FreeProps = false;

// ROTT shared HUD
new Float:ROTT_HudRefreshAt[MAX_PLAYERS_ARRAY];

// ROTT props and sub-rages
#define RP_STRING "rage_rott_props"
#define MAX_PROP_NAME_LENGTH 41
#define PROP_INVALID -1
#define PROP_JUMP_PAD 0
#define PROP_ANGLE_PAD 1
#define PROP_SLICER 2
#define PROP_PLATFORM 3
#define PROP_COUNT 4
new bool:RP_ActiveThisRound = false;
new bool:RP_NoFallDamage = false; // arg18
new bool:RP_CanUse[MAX_PLAYERS_ARRAY]; // internal
new RP_CurrentlySelectedProp[MAX_PLAYERS_ARRAY]; // internal
new bool:RP_SpecialKeyDown[MAX_PLAYERS_ARRAY]; // internal
new bool:RP_AltFireKeyDown[MAX_PLAYERS_ARRAY]; // internal
new bool:RP_ReloadKeyDown[MAX_PLAYERS_ARRAY]; // internal
new bool:RP_CanDeployProp[MAX_PLAYERS_ARRAY][PROP_COUNT]; // arg1,3,5,6
new Float:RP_PropRageCost[MAX_PLAYERS_ARRAY][PROP_COUNT]; // arg2,4,6,8
new String:RP_PropName[PROP_COUNT][MAX_PROP_NAME_LENGTH]; // derived from various sub-rage args
new String:RP_StrNotEnoughRage[MAX_CENTER_TEXT_LENGTH]; // arg15
new String:RP_StrGroundOnly[MAX_CENTER_TEXT_LENGTH]; // arg16
new String:RP_StrPlayerBlocking[MAX_CENTER_TEXT_LENGTH]; // arg17
new String:RP_HUDMessage[MAX_CENTER_TEXT_LENGTH]; // arg19
new Float:RP_EffectTriggerInterval[PROP_COUNT]; // internal, with some derivation from some props
new RP_PropHealth[PROP_COUNT]; // internal, with some derivation from some props

#define RPJP_STRING "rage_rott_jump_pad_info"
#define RPJP_EffectTriggerInterval 0.2
new Float:RPJP_JumpPadIntensity; // arg1
new RPJP_JumpPadHealth; // arg2
new String:RPJP_JumpPadModel[MAX_MODEL_FILE_LENGTH]; // arg3
new Float:RPJP_JumpPadCollision[2][3]; // arg4
new String:RPJP_JumpPadSound[MAX_SOUND_FILE_LENGTH]; // arg10
new Float:RPJP_AnglePadIntensity; // arg11
new RPJP_AnglePadHealth; // arg12
new String:RPJP_AnglePadModel[MAX_MODEL_FILE_LENGTH]; // arg13
new Float:RPJP_AnglePadCollision[2][3];// arg14
new Float:RPJP_AnglePadDampeningFactor; // arg16

//#define RPS_STRING "rage_rott_slicer_info"
//#define RPP_STRING "rage_rott_platform_info"
#define RPSP_STRING "rage_rott_slicer_platform_info"
new Float:RPS_DelayBetweenChecks; // arg1
new Float:RPS_DamagePerCheck; // arg2
new bool:RPS_NegatePushForce; // arg3
new String:RPS_SlicerModel[MAX_MODEL_FILE_LENGTH]; // arg4
new Float:RPS_SlicerCollision[2][3];// arg5
new Float:RPS_DelayBeforeDamage; // arg6
new RPP_PlatformHealth; // arg1
new String:RPP_PlatformModel[MAX_MODEL_FILE_LENGTH]; // arg2

// error messages for props
#define NOPE_AVI "vo/engineer_no01.mp3"
#define RP_ERROR_STATE_NONE 0
#define RP_ERROR_STATE_NEED_RAGE 1
#define RP_ERROR_STATE_GROUND_ONLY 2
#define RP_ERROR_STATE_PLAYER_BLOCKING 3
#define RP_ERROR_STATE_UNKNOWN 4
new RP_ActiveErrorState[MAX_PLAYERS_ARRAY];
new Float:RP_DisplayErrorUntil[MAX_PLAYERS_ARRAY];

// ROTT weapons
#define RW_STRING "rage_rott_weapons"
#define RW_MAX_WEAPONS 10
#define RW_MAX_GODMODE_SOUNDS 5
#define RW_INVALID_INDEX RW_MAX_WEAPONS
#define RW_MISSING_MELEE (RW_MAX_WEAPONS+1)
#define RW_RJ_FAIL (RW_MAX_WEAPONS+2)
#define RW_MAX_MESSAGE_LENGTH 81
#define RW_TYPE_NORMAL 1
#define RW_TYPE_DRUNK 2
#define RW_TYPE_SPLIT 3
#define RW_TYPE_ARMOR 4
#define RW_TYPE_GOD_MODE 5
new RW_ActiveThisRound;
new String:RW_Messages[RW_MAX_WEAPONS+3][RW_MAX_MESSAGE_LENGTH];
new bool:RW_CanUse[MAX_PLAYERS_ARRAY]; // internal
new RW_ActiveMessageIndex[MAX_PLAYERS_ARRAY]; // internal
new Float:RW_MessageActiveUntil[MAX_PLAYERS_ARRAY]; // internal
new RW_ActiveWeaponSpec[MAX_PLAYERS_ARRAY]; // internal
new bool:RW_ArmorActive[MAX_PLAYERS_ARRAY]; // internal
new Float:RW_ArmorActiveUntil[MAX_PLAYERS_ARRAY]; // internal
new bool:RW_GodModeActive[MAX_PLAYERS_ARRAY]; // internal
new Float:RW_GodModeActiveUntil[MAX_PLAYERS_ARRAY]; // internal
new Float:RW_NextGodModeSoundAt[MAX_PLAYERS_ARRAY]; // internal
new RW_WeaponCount[MAX_PLAYERS_ARRAY]; // arg1
new RW_WeaponVisibility[MAX_PLAYERS_ARRAY]; // arg2
new Float:RW_HomingInterval; // arg3
new RW_WeaponChances[MAX_PLAYERS_ARRAY][RW_MAX_WEAPONS]; // arg4
// arg5 and arg6 not stored this way
new String:RW_GodModeSounds[RW_MAX_GODMODE_SOUNDS][MAX_SOUND_FILE_LENGTH]; // arg7
new Float:RW_RJIntensityFactor; // arg8
// arg19 is an error message not stored here

// ROTT weapon info. only reason I'm storing them is so i.e. drunk missile doesn't suddenly get heatseeker logic on weapon switch.
#define RWI_PREFIX "rage_rott_weapon_info"
new RWI_Type[RW_MAX_WEAPONS]; // arg1
// args 2-5 are only needed at rage time
new Float:RWI_Duration[RW_MAX_WEAPONS]; // arg6, god mode and armor only
new RWI_AdditionalProjectiles[RW_MAX_WEAPONS]; // arg7, drunk missile only
new Float:RWI_HomingDegreesPerSecond[RW_MAX_WEAPONS]; // arg8
new bool:RWI_ObsessiveHoming[RW_MAX_WEAPONS]; // arg9
new RWI_NumAdditionalExplosions[RW_MAX_WEAPONS]; // arg10
new Float:RWI_ExplosionInterval[RW_MAX_WEAPONS]; // arg11
new Float:RWI_RandomDeviationPerSecond[RW_MAX_WEAPONS]; // arg12
new RWI_ModelOverrideIdx[RW_MAX_WEAPONS]; // arg13
new String:RWI_ParticleOverride[RW_MAX_WEAPONS][MAX_EFFECT_NAME_LENGTH]; // arg14
// arg 15 is up there as RW_Messages
// arg 16 is only needed at rage time
new Float:RWI_LockOnAngle[RW_MAX_WEAPONS];
new Float:RWI_HomeAngle[RW_MAX_WEAPONS];

// ROTT monitored rockets
#define MAX_ROCKETS 30
#define FIREBOMB_EXPLOSION_RADIUS "150" // it's input as a string, so...lol
#define FIREBOMB_EXPLOSION_DISTANCE_BETWEEN 100.0
new RMR_Spec[MAX_ROCKETS];
new RMR_RocketEntRef[MAX_ROCKETS];
new Float:RMR_NextDeviationAt[MAX_ROCKETS];
new Float:RMR_HomingPerSecond[MAX_ROCKETS];
new Float:RMR_RandomDeviationPerSecond[MAX_ROCKETS];
new RMR_CurrentHomingTarget[MAX_ROCKETS];
new bool:RMR_CanRetarget[MAX_ROCKETS];
new Float:RMR_RocketVelocity[MAX_ROCKETS];
new bool:RMR_HasTargeted[MAX_ROCKETS];
new RMR_FirebombCount[MAX_ROCKETS];
new RMR_FirebombsActivated[MAX_ROCKETS];
new RMR_FirebombDamage[MAX_ROCKETS];
new RMR_RocketOwner[MAX_ROCKETS];
new Float:RMR_FirebombInterval[MAX_ROCKETS];
new Float:RMR_ChainExplosionStartedAt[MAX_ROCKETS];
new Float:RMR_LastPosition[MAX_ROCKETS][3];
new Float:RMR_LastAngle[MAX_ROCKETS][3];

// queued rockets, since they can't be immediately identified on spawn
#define ROCKET_QUEUE_SIZE 5
new RocketQueue[ROCKET_QUEUE_SIZE];
new RocketBeingCreated = false; // prevent endless recursion with the rocket queue

// ROTT's infinity pistol, though intentionally so weak as to be a joke/challenge more than anything (for balance)
// given to the user shortly after round start
#define RIP_STRING "rage_rott_infinity_pistol"
#define RIP_AWARD_INTERVAL 1.0 // 1 second between clip ammo awards
new bool:RIP_ActiveThisRound = false;
new bool:RIP_IsUsing[MAX_PLAYERS_ARRAY];
new Float:RIP_NextAwardTime[MAX_PLAYERS_ARRAY];
new RIP_AwardAmmoCount[MAX_PLAYERS_ARRAY];
new bool:RIP_IsPrimary[MAX_PLAYERS_ARRAY];

// fixed melee
#define RFM_STRING "rage_rott_fixed_melee"
new String:RFM_WeaponName[MAX_PLAYERS_ARRAY][MAX_WEAPON_NAME_LENGTH];
new RFM_WeaponIdx[MAX_PLAYERS_ARRAY];
new String:RFM_WeaponArgs[MAX_PLAYERS_ARRAY][MAX_WEAPON_ARG_LENGTH];
new RFM_WeaponVisibility[MAX_PLAYERS_ARRAY];
			
// combining the above two since I've run out of ability space.
#define RSW_STRING "rage_rott_static_weapons"

// individual ROTT props and their management
#define MAX_PROPS 100
new PROP_HighestSpawnedProp = -1;
new PROP_EntRef[MAX_PROPS];
new PROP_Type[MAX_PROPS];
new Float:PROP_NextTriggerTime[MAX_PROPS][MAX_PLAYERS_ARRAY]; // yes, this has a large data size. but it's for the best.
new PROP_OwnerUserId[MAX_PROPS];

/**
 * METHODS REQUIRED BY ff2 subplugin
 */
PrintRageWarning()
{
	PrintToServer("*********************************************************************");
	PrintToServer("*                             WARNING                               *");
	PrintToServer("*       DEBUG_FORCE_RAGE in ff2_sarysapub1.sp is set to true!       *");
	PrintToServer("*  Any admin can use the 'rage' command to use rages in this pack!  *");
	PrintToServer("*  This is only for test servers. Disable this on your live server. *");
	PrintToServer("*********************************************************************");
}
 
#define CMD_FORCE_RAGE "rage"
public OnPluginStart2()
{
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	
	if (DEBUG_FORCE_RAGE)
	{
		PrintRageWarning();
		RegAdminCmd(CMD_FORCE_RAGE, CmdForceRage, ADMFLAG_GENERIC);
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundInProgress = true;
	
	PluginActiveThisRound = false;
	RP_ActiveThisRound = false;
	RIP_ActiveThisRound = false;
	RW_ActiveThisRound = false;
	RP_HUDMessage[0] = 0;
	
	// initialize arrays
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		// ROTT weapons
		RW_CanUse[clientIdx] = false;
		RW_ActiveMessageIndex[clientIdx] = 0;
		RW_MessageActiveUntil[clientIdx] = 0.0;
		RW_ArmorActive[clientIdx] = false;
		RW_ArmorActiveUntil[clientIdx] = 0.0;
		RW_GodModeActive[clientIdx] = false;
		RW_GodModeActiveUntil[clientIdx] = 0.0;
	
		// ROTT props
		RP_CanUse[clientIdx] = false;
		RP_SpecialKeyDown[clientIdx] = false;
		RP_AltFireKeyDown[clientIdx] = false;
		RP_ReloadKeyDown[clientIdx] = false;
		RP_ActiveErrorState[clientIdx] = 0;
		RP_DisplayErrorUntil[clientIdx] = 0.0;
		RW_ArmorActive[clientIdx] = false;
		RW_GodModeActive[clientIdx] = false;

		// infinity pistol
		RIP_IsUsing[clientIdx] = false;
	
		// boss-only inits
		new bossIdx = FF2_GetBossIndex(clientIdx);
		if (bossIdx < 0)
			continue;
			
		// ROTT weapons
		RW_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, RW_STRING);
		if (RW_CanUse[clientIdx])
		{
			PluginActiveThisRound = true;
			RW_ActiveThisRound = true;
		
			// the overarching rage props
			RW_WeaponCount[clientIdx] = min(FF2_GetAbilityArgument(bossIdx, this_plugin_name, RW_STRING, 1), RW_MAX_WEAPONS);
			RW_WeaponVisibility[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RW_STRING, 2);
			RW_HomingInterval = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, RW_STRING, 3);
			
			new String:chancesStr[RW_MAX_WEAPONS * 3];
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RW_STRING, 4, chancesStr, 30);
			new String:chancesStrs[RW_MAX_WEAPONS][4];
			ExplodeString(chancesStr, ";", chancesStrs, RW_MAX_WEAPONS, 4);
			for (new i = 0; i < RW_WeaponCount[clientIdx]; i++)
				RW_WeaponChances[clientIdx][i] = StringToInt(chancesStrs[i]);

			new Float:maxAngleLockOn = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, RW_STRING, 5);
			new Float:maxAngleHome = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, RW_STRING, 6);
			for (new i = 0; i < RW_MAX_GODMODE_SOUNDS; i++)
				RW_GodModeSounds[i][0] = 0;
			new String:godModeSounds[(MAX_SOUND_FILE_LENGTH + 1) * RW_MAX_GODMODE_SOUNDS];
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RW_STRING, 7, godModeSounds, sizeof(godModeSounds));
			ExplodeString(godModeSounds, ";", RW_GodModeSounds, RW_MAX_GODMODE_SOUNDS, MAX_SOUND_FILE_LENGTH);
			for (new i = 0; i < RW_MAX_GODMODE_SOUNDS; i++)
				if (strlen(RW_GodModeSounds[i]) > 3)
					PrecacheSound(RW_GodModeSounds[i]);
					
			RW_RJIntensityFactor = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, RW_STRING, 8);
				
			// specific weapon info
			for (new i = 0; i < RW_WeaponCount[clientIdx]; i++)
			{
				static String:actualRWIString[40];
				Format(actualRWIString, 40, "%s%d", RWI_PREFIX, i);
				
				RWI_Type[i] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, actualRWIString, 1);
				RWI_Duration[i] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, actualRWIString, 6);
				RWI_AdditionalProjectiles[i] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, actualRWIString, 7);
				RWI_HomingDegreesPerSecond[i] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, actualRWIString, 8);
				RWI_ObsessiveHoming[i] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, actualRWIString, 9) == 1;
				RWI_NumAdditionalExplosions[i] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, actualRWIString, 10);
				RWI_ExplosionInterval[i] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, actualRWIString, 11);
				RWI_RandomDeviationPerSecond[i] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, actualRWIString, 12);
				RWI_ModelOverrideIdx[i] = ReadModelToInt(bossIdx, actualRWIString, 13);
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, actualRWIString, 14, RWI_ParticleOverride[i], MAX_EFFECT_NAME_LENGTH);
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, actualRWIString, 15, RW_Messages[i], RW_MAX_MESSAGE_LENGTH);
				ReplaceString(RW_Messages[i], RW_MAX_MESSAGE_LENGTH, "\\n", "\n");
				if (PRINT_DEBUG_SPAM)
					PrintToServer("[sarysapub1] Read in HUD message: %s", RW_Messages[i]);
				
				// not storing arg 16, but the sound must be precached
				static String:rageSound[MAX_SOUND_FILE_LENGTH];
				ReadSound(bossIdx, actualRWIString, 16, rageSound);
					
				// overrides for lock on and homing angle
				RWI_LockOnAngle[i] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, actualRWIString, 17);
				if (RWI_LockOnAngle[i] <= 0.0)
					RWI_LockOnAngle[i] = maxAngleLockOn;
				RWI_HomeAngle[i] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, actualRWIString, 18);
				if (RWI_HomeAngle[i] <= 0.0)
					RWI_HomeAngle[i] = maxAngleHome;
			}
			RW_Messages[RW_INVALID_INDEX] = "Weapon chances didn't add up to 100%.\nNotify your server admin.";
			RW_Messages[RW_MISSING_MELEE] = "Melee rage missing. Can't give armor.\nNotify your server admin.";
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RW_STRING, 19, RW_Messages[RW_RJ_FAIL], RW_MAX_MESSAGE_LENGTH);
		}
		
		// ROTT props
		RP_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, RP_STRING);
		if (RP_CanUse[clientIdx])
		{
			PluginActiveThisRound = true;
			RP_ActiveThisRound = true;
			RP_CurrentlySelectedProp[clientIdx] = -1;
			for (new i = 1; i <= 7; i += 2)
			{
				RP_CanDeployProp[clientIdx][i/2] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RP_STRING, i) == 1;
				RP_PropRageCost[clientIdx][i/2] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, RP_STRING, i+1);
				if (PRINT_DEBUG_SPAM)
					PrintToServer("[sarysapub1] Prop %d (actually %d): %d / %f", i, (i/2), RP_CanDeployProp[clientIdx][i/2], RP_PropRageCost[clientIdx][i/2]);
				
				if (RP_CanDeployProp[clientIdx][i/2] && RP_CurrentlySelectedProp[clientIdx] == -1)
					RP_CurrentlySelectedProp[clientIdx] = i / 2;
			}
			ReadCenterText(bossIdx, RP_STRING, 15, RP_StrNotEnoughRage);
			ReadCenterText(bossIdx, RP_STRING, 16, RP_StrGroundOnly);
			ReadCenterText(bossIdx, RP_STRING, 17, RP_StrPlayerBlocking);
			RP_NoFallDamage = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RP_STRING, 18) == 1;
			ReadCenterText(bossIdx, RP_STRING, 19, RP_HUDMessage);

			// jump pad info
			if ((RP_CanDeployProp[clientIdx][PROP_JUMP_PAD] || RP_CanDeployProp[clientIdx][PROP_ANGLE_PAD]) && FF2_HasAbility(bossIdx, this_plugin_name, RPJP_STRING))
			{
				RPJP_JumpPadIntensity = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, RPJP_STRING, 1);
				RPJP_JumpPadHealth = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RPJP_STRING, 2);
				ReadModel(bossIdx, RPJP_STRING, 3, RPJP_JumpPadModel);
				ReadHull(bossIdx, RPJP_STRING, 4, RPJP_JumpPadCollision);
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RPJP_STRING, 5, RP_PropName[PROP_JUMP_PAD], MAX_PROP_NAME_LENGTH);
				
				ReadSound(bossIdx, RPJP_STRING, 10, RPJP_JumpPadSound);
				
				RPJP_AnglePadIntensity = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, RPJP_STRING, 11);
				RPJP_AnglePadHealth = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RPJP_STRING, 12);
				ReadModel(bossIdx, RPJP_STRING, 13, RPJP_AnglePadModel);
				ReadHull(bossIdx, RPJP_STRING, 14, RPJP_AnglePadCollision);
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RPJP_STRING, 15, RP_PropName[PROP_ANGLE_PAD], MAX_PROP_NAME_LENGTH);
				RPJP_AnglePadDampeningFactor = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, RPJP_STRING, 16);
				
				// also, these
				RP_EffectTriggerInterval[PROP_JUMP_PAD] = RPJP_EffectTriggerInterval;
				RP_EffectTriggerInterval[PROP_ANGLE_PAD] = RPJP_EffectTriggerInterval;
				RP_PropHealth[PROP_JUMP_PAD] = RPJP_JumpPadHealth;
				RP_PropHealth[PROP_ANGLE_PAD] = RPJP_AnglePadHealth;
			}
			else
			{
				PrintToServer("[sarysapub1] WARNING: Jump pad and/or angle pad set to enabled but required rage %s missing.", RPJP_STRING);
				RP_CanDeployProp[clientIdx][PROP_JUMP_PAD] = false;
				RP_CanDeployProp[clientIdx][PROP_ANGLE_PAD] = false;
			}
			
			// slicer and platform info
			if (RP_CanDeployProp[clientIdx][PROP_SLICER] && FF2_HasAbility(bossIdx, this_plugin_name, RPSP_STRING))
			{
				// SLICER
				RPS_DelayBetweenChecks = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, RPSP_STRING, 1);
				RPS_DamagePerCheck = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, RPSP_STRING, 2);
				RPS_NegatePushForce = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RPSP_STRING, 3) == 1;
				ReadModel(bossIdx, RPSP_STRING, 4, RPS_SlicerModel);
				ReadHull(bossIdx, RPSP_STRING, 5, RPS_SlicerCollision);
				RPS_DelayBeforeDamage = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, RPSP_STRING, 6);
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RPSP_STRING, 7, RP_PropName[PROP_SLICER], MAX_PROP_NAME_LENGTH);
					
				// also, these
				RP_EffectTriggerInterval[PROP_SLICER] = RPS_DelayBetweenChecks;
				RP_PropHealth[PROP_SLICER] = 32000;
				
				// PLATFORM
				RPP_PlatformHealth = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RPSP_STRING, 11);
				ReadModel(bossIdx, RPSP_STRING, 12, RPP_PlatformModel);
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RPSP_STRING, 13, RP_PropName[PROP_PLATFORM], MAX_PROP_NAME_LENGTH);
					
				// also, this
				RP_PropHealth[PROP_PLATFORM] = RPP_PlatformHealth;
			}
			else
			{
				PrintToServer("[sarysapub1] WARNING: Slicer and/or platform set to enabled but required rage %s missing.", RPSP_STRING);
				RP_CanDeployProp[clientIdx][PROP_SLICER] = false;
				RP_CanDeployProp[clientIdx][PROP_PLATFORM] = false;
			}
				
			if (PRINT_DEBUG_INFO)
				PrintToServer("[sarysapub1] Boss will use ROTT Props, jumppad=%d  45jumppad=%d  slicer=%d  platform=%d", RP_CanDeployProp[clientIdx][PROP_JUMP_PAD], RP_CanDeployProp[clientIdx][PROP_ANGLE_PAD], RP_CanDeployProp[clientIdx][PROP_SLICER], RP_CanDeployProp[clientIdx][PROP_PLATFORM]);
				
			if (RP_CurrentlySelectedProp[clientIdx] == -1)
			{
				RP_CanUse[clientIdx] = false;
				if (PRINT_DEBUG_INFO)
					PrintToServer("[sarysapub1] Or not...none of the potential props are enabled.");
			}
		}
		
		if (RW_CanUse[clientIdx] || RP_CanUse[clientIdx])
		{
			ROTT_UpdateHUD(clientIdx);
			ROTT_HudRefreshAt[clientIdx] = GetEngineTime();
		}
	}
	
	if (RP_ActiveThisRound)
	{
		PROP_HighestSpawnedProp = -1;
		for (new i = 0; i < MAX_PROPS; i++)
			PROP_Type[i] = PROP_INVALID;
	}
	
	if (RW_ActiveThisRound)
	{
		for (new i = 0; i < ROCKET_QUEUE_SIZE; i++)
			RocketQueue[i] = -1;
		for (new i = 0; i < MAX_ROCKETS; i++)
			RMR_RocketEntRef[i] = 0;
			
		// object destroyed event
//		HookEvent("object_destroyed", RW_ObjectDestroyed, EventHookMode_Pre);
	}
	
	if (RP_ActiveThisRound || RW_ActiveThisRound)
	{
		PrecacheSound(NOPE_AVI); // it's used for error cases
	}
	
	// post-round start inits
	CreateTimer(0.3, Timer_PostRoundStartInits, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_PostRoundStartInits(Handle:timer)
{
	if (!RoundInProgress) // user suicided
		return Plugin_Continue;
		
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx))
			continue;
	
		// in case of last second respawns, disable fall damage here
		SDKHook(clientIdx, SDKHook_OnTakeDamage, ROTTDamageMonitor);
	
		// boss-only inits
		new bossIdx = FF2_GetBossIndex(clientIdx);
		if (bossIdx < 0)
			continue;
			
		// give the user their infinity pistol
		RIP_IsUsing[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, RIP_STRING);
		if (RIP_IsUsing[clientIdx])
		{
			PluginActiveThisRound = true;
			RIP_ActiveThisRound = true;
			
			new String:weaponName[MAX_WEAPON_NAME_LENGTH];
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RIP_STRING, 1, weaponName, sizeof(weaponName));
			new weaponIdx = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RIP_STRING, 2);
			new String:weaponArgs[MAX_WEAPON_ARG_LENGTH];
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RIP_STRING, 3, weaponArgs, sizeof(weaponArgs));
			new weaponVisibility = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RIP_STRING, 4);
			
			SpawnWeapon(clientIdx, weaponName, weaponIdx, 101, 5, weaponArgs, weaponVisibility);
			
			RIP_NextAwardTime[clientIdx] = GetEngineTime() + RIP_AWARD_INTERVAL;
			RIP_AwardAmmoCount[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RIP_STRING, 5);
			RIP_IsPrimary[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RIP_STRING, 6) == 1;
		}
		
		// replace the user's melee weapon
		if (FF2_HasAbility(bossIdx, this_plugin_name, RFM_STRING))
		{
			PluginActiveThisRound = true;
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RFM_STRING, 1, RFM_WeaponName[clientIdx], MAX_WEAPON_NAME_LENGTH);
			RFM_WeaponIdx[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RFM_STRING, 2);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RFM_STRING, 3, RFM_WeaponArgs[clientIdx], MAX_WEAPON_ARG_LENGTH);
			RFM_WeaponVisibility[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RFM_STRING, 4);
			
			TF2_RemoveWeaponSlot(clientIdx, TFWeaponSlot_Melee);
			new melee = SpawnWeapon(clientIdx, RFM_WeaponName[clientIdx], RFM_WeaponIdx[clientIdx], 101, 5, RFM_WeaponArgs[clientIdx], RFM_WeaponVisibility[clientIdx]);
			if (IsValidEntity(melee))
				SetEntPropEnt(clientIdx, Prop_Data, "m_hActiveWeapon", melee);
		}
		
		// the above two, but combined. sucks but I have no choice
		if (FF2_HasAbility(bossIdx, this_plugin_name, RSW_STRING))
		{
			// INFINITY PISTOL
			PluginActiveThisRound = true;
			RIP_IsUsing[clientIdx] = true;
			RIP_ActiveThisRound = true;
			
			new String:weaponName[MAX_WEAPON_NAME_LENGTH];
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RSW_STRING, 1, weaponName, sizeof(weaponName));
			new weaponIdx = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RSW_STRING, 2);
			new String:weaponArgs[MAX_WEAPON_ARG_LENGTH];
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RSW_STRING, 3, weaponArgs, sizeof(weaponArgs));
			new weaponVisibility = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RSW_STRING, 4);
			
			SpawnWeapon(clientIdx, weaponName, weaponIdx, 101, 5, weaponArgs, weaponVisibility);
			
			RIP_NextAwardTime[clientIdx] = GetEngineTime() + RIP_AWARD_INTERVAL;
			RIP_AwardAmmoCount[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RSW_STRING, 5);
			RIP_IsPrimary[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RSW_STRING, 6) == 1;
			
			// MELEE WEAPON
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RSW_STRING, 11, RFM_WeaponName[clientIdx], MAX_WEAPON_NAME_LENGTH);
			RFM_WeaponIdx[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RSW_STRING, 12);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RSW_STRING, 13, RFM_WeaponArgs[clientIdx], MAX_WEAPON_ARG_LENGTH);
			RFM_WeaponVisibility[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RSW_STRING, 14);
			
			TF2_RemoveWeaponSlot(clientIdx, TFWeaponSlot_Melee);
			new melee = SpawnWeapon(clientIdx, RFM_WeaponName[clientIdx], RFM_WeaponIdx[clientIdx], 101, 5, RFM_WeaponArgs[clientIdx], RFM_WeaponVisibility[clientIdx]);
			if (IsValidEntity(melee))
				SetEntPropEnt(clientIdx, Prop_Data, "m_hActiveWeapon", melee);
		}
	}
		
	return Plugin_Continue;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundInProgress = false;
	
	// infinity pistol
	RIP_ActiveThisRound = false;
	
	// rott props
	if (RP_ActiveThisRound)
	{
		RP_ActiveThisRound = false;
		
		// re-enable fall damage and stop monitoring players
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
			if (IsValidEntity(clientIdx) && IsClientInGame(clientIdx))
				SDKUnhook(clientIdx, SDKHook_OnTakeDamage, ROTTDamageMonitor);
		RP_NoFallDamage = false;
		
		// props get cleaned up automatically
	}
	
	// rott weapons
	if (RW_ActiveThisRound)
	{
		RW_ActiveThisRound = false;
		
		// object destroyed event
//		UnhookEvent("object_destroyed", RW_ObjectDestroyed, EventHookMode_Pre);
	}
}

public Action:FF2_OnAbility2(bossIdx, const String:plugin_name[], const String:ability_name[], status)
{
	if (strcmp(plugin_name, this_plugin_name) != 0)
		return Plugin_Continue;
	else if (!RoundInProgress) // don't execute these rages with 0 players alive
		return Plugin_Continue;

	if (!strcmp(ability_name, RW_STRING))
		Rage_ROTTWeapons(ability_name, bossIdx);
	// ROTT props not activated this way
		
	return Plugin_Continue;
}

/**
 * Debug Only!
 */
public Action:CmdForceRage(user, argsInt)
{
	// get actual args
	new String:unparsedArgs[ARG_LENGTH];
	GetCmdArgString(unparsedArgs, ARG_LENGTH);
	
	// gotta do this
	PrintRageWarning();
	
	if (!strcmp("rott", unparsedArgs))
	{
		PrintToConsole(user, "ROTT weapons rage.");
		Rage_ROTTWeapons(RW_STRING, 0);
		return Plugin_Handled;
	}
	else if (!strcmp("prop", unparsedArgs))
	{
		RP_FreeProps = !RP_FreeProps;
		PrintToConsole(user, "ROTT props 'free' cheat toggled. Currently %s", (RP_FreeProps ? "ON" : "OFF"));
		return Plugin_Handled;
	}
	
	PrintToServer("[sarysapub1] Rage not found: %s", unparsedArgs);
	return Plugin_Continue;
}

/**
 * Shared
 */
#define PROPS_MESSAGE_MAX 200
#define HUD_MESSAGE_MAX (RW_MAX_MESSAGE_LENGTH + 2 + PROPS_MESSAGE_MAX + 1 + PROPS_MESSAGE_MAX + 1 + PROPS_MESSAGE_MAX + 1)
new String:ROTT_HudMessage[MAX_PLAYERS_ARRAY][HUD_MESSAGE_MAX];
public ROTT_UpdateHUD(clientIdx)
{
	static String:weaponMessage[RW_MAX_MESSAGE_LENGTH];
	static String:errorMessage[PROPS_MESSAGE_MAX];
	static String:propsMessage[PROPS_MESSAGE_MAX];
	static String:debugMessage[PROPS_MESSAGE_MAX];
	
	if (RW_ActiveThisRound && RW_CanUse[clientIdx])
	{
		if (RW_ActiveMessageIndex[clientIdx] == -1)
			weaponMessage[0] = 0;
		else
			weaponMessage = RW_Messages[RW_ActiveMessageIndex[clientIdx]];
		//PrintToServer("Current weapon (%d / %f / %f) message: %s", RW_ActiveMessageIndex[clientIdx], RW_MessageActiveUntil, GetEngineTime(), weaponMessage);
	}
	
	if (RP_ActiveThisRound && RP_CanUse[clientIdx])
	{
		new curProp = RP_CurrentlySelectedProp[clientIdx];
		Format(propsMessage, PROPS_MESSAGE_MAX, RP_HUDMessage, RP_PropName[curProp], RP_PropRageCost[clientIdx][curProp]);
		
		if (RP_ActiveErrorState[clientIdx] != RP_ERROR_STATE_NONE && RP_DisplayErrorUntil[clientIdx] > GetEngineTime())
		{
			if (RP_ActiveErrorState[clientIdx] == RP_ERROR_STATE_NEED_RAGE)
				errorMessage = RP_StrNotEnoughRage;
			else if (RP_ActiveErrorState[clientIdx] == RP_ERROR_STATE_GROUND_ONLY)
				errorMessage = RP_StrGroundOnly;
			else if (RP_ActiveErrorState[clientIdx] == RP_ERROR_STATE_PLAYER_BLOCKING)
				errorMessage = RP_StrPlayerBlocking;
			else if (RP_ActiveErrorState[clientIdx] == RP_ERROR_STATE_UNKNOWN)
				errorMessage = "Unknown error. Could not create prop.";
		}
		else
		{
			errorMessage = "";
			RP_ActiveErrorState[clientIdx] = RP_ERROR_STATE_NONE;
		}
	}
	
	if (DEBUG_HUD)
	{
		Format(debugMessage, PROPS_MESSAGE_MAX, "Prop count: %d", (PROP_HighestSpawnedProp + 1));
	}
	
	Format(ROTT_HudMessage[clientIdx], HUD_MESSAGE_MAX, "%s\n%s\n%s\n%s", weaponMessage, errorMessage, propsMessage, debugMessage);
	//if (PRINT_DEBUG_SPAM)
	//	PrintToServer("HUD message updated, is now %s", ROTT_HudMessage[clientIdx]);
	ReplaceString(ROTT_HudMessage[clientIdx], HUD_MESSAGE_MAX, "\\n", "\n");
}

/**
 * ROTT Weapons
 */
public Rage_ROTTWeapons(const String:ability_name[], bossIdx)
{
	new clientIdx = GetClientOfUserId(FF2_GetBossUserId(bossIdx));
	
	// pick a random weapon
	new randomInt = GetRandomInt(1, 100);
	
	new weaponSpec = -1;
	new add = 0;
	for (new i = 0; i < RW_WeaponCount[clientIdx]; i++)
	{
		add += RW_WeaponChances[clientIdx][i];
		if (add >= randomInt)
		{
			weaponSpec = i;
			break;
		}
	}
	
	if (weaponSpec == -1)
	{
		PrintToServer("[sarysapub1] ERROR: Player didn't get a weapon because the chances didn't add up to 100%. (player rolled %d)", randomInt);
		RW_ActiveMessageIndex[clientIdx] = RW_INVALID_INDEX;
		RW_MessageActiveUntil[clientIdx] = GetEngineTime() + 20.0;
		return;
	}
	
	// get our actual ability info
	static String:actualRWIString[40];
	Format(actualRWIString, 40, "%s%d", RWI_PREFIX, weaponSpec);
	if (PRINT_DEBUG_INFO)
		PrintToServer("[sarysapub1] Giving player ROTT weapon specified in %s", actualRWIString);

	// special for armor
	if (RWI_Type[weaponSpec] == RW_TYPE_ARMOR)
	{
		// replace the melee weapon
		if (strlen(RFM_WeaponName[clientIdx]) < 3)
		{
			PrintToServer("sarysapub1] ERROR: Melee weapon must be specified with %s or %s. Cannot give the hale armor.", RFM_STRING, RSW_STRING);
			RW_ActiveMessageIndex[clientIdx] = RW_MISSING_MELEE;
			RW_MessageActiveUntil[clientIdx] = GetEngineTime() + 20.0;
			return;
		}
		
		// only change the user's active weapon if necessary
		new bool:shouldChangeWeapon = false;
		new oldWeapon = GetEntPropEnt(clientIdx, Prop_Data, "m_hActiveWeapon");
		if (IsValidEntity(oldWeapon))
		{
			static String:oldClassname[MAX_WEAPON_NAME_LENGTH];
			GetEntityClassname(oldWeapon, oldClassname, MAX_WEAPON_NAME_LENGTH);
			if (!strcmp(oldClassname, RFM_WeaponName[clientIdx]))
				shouldChangeWeapon = true;
		}
		
		static String:armorArgs[MAX_WEAPON_ARG_LENGTH];
		Format(armorArgs, MAX_WEAPON_ARG_LENGTH, "66 ; 0.00 ; 64 ; 0.00 ; 60 ; 0.00 ; %s", RFM_WeaponArgs[clientIdx]);
		TF2_RemoveWeaponSlot(clientIdx, TFWeaponSlot_Melee);
		new melee = SpawnWeapon(clientIdx, RFM_WeaponName[clientIdx], RFM_WeaponIdx[clientIdx], 101, 5, armorArgs, RFM_WeaponVisibility[clientIdx]);
		if (IsValidEntity(melee) && shouldChangeWeapon)
			SetEntPropEnt(clientIdx, Prop_Data, "m_hActiveWeapon", melee);
			
		if (PRINT_DEBUG_INFO)
			PrintToServer("[sarysapub1] ARMOR: Gave %d a %s(%d) with args %s", clientIdx, RFM_WeaponName[clientIdx], RFM_WeaponIdx[clientIdx], armorArgs);
			
		// start the timer
		RW_ArmorActive[clientIdx] = true;
		RW_ArmorActiveUntil[clientIdx] = GetEngineTime() + RWI_Duration[weaponSpec];
	}

	// read in the weapon to give to the player
	new clipSize = FF2_GetAbilityArgument(bossIdx, this_plugin_name, actualRWIString, 2);
	new String:weaponName[MAX_WEAPON_NAME_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, actualRWIString, 3, weaponName, MAX_WEAPON_NAME_LENGTH);
	
	// sarysa updated 2014-09-09, with armor gaining support for providing a rocket launcher
	// we can no longer assume no weapon name is safe
	if (strlen(weaponName) > 3)
	{
		// sarysa updated 2014-09-23
		// if the hale already has a weapon, check the clip.
		// if it's lower than the clip of the new weapon, 
		new bool:shouldAddWeapon = true;
		if (RWI_Type[weaponSpec] == RW_TYPE_ARMOR)
		{
			new oldWeapon = GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Primary);
			if (IsValidEntity(oldWeapon))
			{
				new oldClip = GetEntProp(oldWeapon, Prop_Send, "m_iClip1");
				if (oldClip > 0)
				{
					shouldAddWeapon = false;
					if (oldClip < clipSize)
						SetEntProp(oldWeapon, Prop_Send, "m_iClip1", clipSize);
				}
			}
		}
	
		if (shouldAddWeapon)
		{
			new weaponNum = FF2_GetAbilityArgument(bossIdx, this_plugin_name, actualRWIString, 4);
			new String:weaponArgs[MAX_WEAPON_ARG_LENGTH];
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, actualRWIString, 5, weaponArgs, MAX_WEAPON_ARG_LENGTH);

			// fully replace any old rocket launcher
			TF2_RemoveWeaponSlot(clientIdx, TFWeaponSlot_Primary);
			new weapon = SpawnWeapon(clientIdx, weaponName, weaponNum, 101, 5, weaponArgs, RW_WeaponVisibility[clientIdx]);
			if (IsValidEntity(weapon))
			{
				SetEntProp(weapon, Prop_Send, "m_iClip1", clipSize);

				// taken from 1st set abilities
				new ammoOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1);
				SetEntProp(clientIdx, Prop_Send, "m_iAmmo", 0, 4, ammoOffset);

				SetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon", weapon);
			}

			// change the active weapon spec
			RW_ActiveWeaponSpec[clientIdx] = weaponSpec;

			// stuff specific to god mode
			if (RWI_Type[weaponSpec] == RW_TYPE_GOD_MODE)
			{
				if (PRINT_DEBUG_INFO)
					PrintToServer("[sarysapub1] Player %d got god mode.", clientIdx);

				SetEntProp(clientIdx, Prop_Data, "m_takedamage", 0);
				TF2_AddCondition(clientIdx, TFCond_Ubercharged, -1.0);
				TF2_AddCondition(clientIdx, TFCond_MegaHeal, -1.0);

				RW_GodModeActive[clientIdx] = true;
				RW_GodModeActiveUntil[clientIdx] = GetEngineTime() + RWI_Duration[weaponSpec];
				RW_NextGodModeSoundAt[clientIdx] = GetEngineTime() + 2.5;
			}
		}
	}
		
	// display the message to the user
	RW_ActiveMessageIndex[clientIdx] = weaponSpec;
	RW_MessageActiveUntil[clientIdx] = GetEngineTime() + 5.0;
	ROTT_UpdateHUD(clientIdx);
	
	// play the rage sound
	new String:rageSound[MAX_SOUND_FILE_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, actualRWIString, 16, rageSound, MAX_SOUND_FILE_LENGTH);
	if (strlen(rageSound) > 3)
	{
		EmitSoundToAll(rageSound);
		EmitSoundToAll(rageSound);
		EmitSoundToAll(rageSound);
		//PlaySoundLocal(clientIdx, rageSound, true, 2);
	}
}

public DuplicateRocket(clientIdx, baseRocket, Float:speed, Float:spawnAngles[3], Float:zOffset)
{
	// create our rocket. no matter what, it's going to spawn, even if it ends up being out of map
	new String:classname[MAX_ENTITY_CLASSNAME_LENGTH] = "CTFProjectile_Rocket";
	new String:entname[MAX_ENTITY_CLASSNAME_LENGTH] = "tf_projectile_rocket";
	new rocket = CreateEntityByName(entname);
	if (!IsValidEntity(rocket))
	{
		PrintToServer("[sarysapub1] Error: Invalid entity %s. Won't spawn rocket.", entname);
		return -1;
	}
	
	// get spawn position from the base rocket
	new Float:spawnPosition[3];
	GetEntPropVector(baseRocket, Prop_Send, "m_vecOrigin", spawnPosition);
	spawnPosition[2] += zOffset; // fixes problem of new rocket colliding with old one
	
	// determine velocity
	new Float:spawnVelocity[3];
	GetAngleVectors(spawnAngles, spawnVelocity, NULL_VECTOR, NULL_VECTOR);
	spawnVelocity[0] *= speed;
	spawnVelocity[1] *= speed;
	spawnVelocity[2] *= speed;
	
	// deploy!
	SetEntProp(rocket, Prop_Send, "m_bCritical", GetEntProp(baseRocket, Prop_Send, "m_bCritical"));
	new damageOffset = FindSendPropOffs(classname, "m_iDeflected") + 4; // credit to voogru
	SetEntDataFloat(rocket, damageOffset, GetEntDataFloat(baseRocket, damageOffset), true);
	SetEntProp(rocket, Prop_Send, "m_nSkin", 1); // set skin to blue team's
	SetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity", clientIdx);
	SetVariantInt(BossTeam);
	AcceptEntityInput(rocket, "TeamNum", -1, -1, 0);
	SetVariantInt(BossTeam);
	AcceptEntityInput(rocket, "SetTeam", -1, -1, 0); 
	
	// I found this offset while trying to fix the sudden-explode issue with these rockets. it's another instance
	// of the owner entity, so why the hell not copy this over...probably useful for some things.
	new testOffset = FindSendPropOffs(classname, "m_bCritical") - 4;
	SetEntDataEnt2(rocket, testOffset, GetEntDataEnt2(baseRocket, testOffset), true);
	TeleportEntity(rocket, spawnPosition, spawnAngles, spawnVelocity);
	DispatchSpawn(rocket);
	
	SetEntProp(rocket, Prop_Send, "m_nSolidType", GetEntProp(baseRocket, Prop_Send, "m_nSolidType"));
	SetEntProp(rocket, Prop_Send, "m_usSolidFlags", GetEntProp(baseRocket, Prop_Send, "m_usSolidFlags"));
	SetEntProp(rocket, Prop_Send, "m_CollisionGroup", GetEntProp(baseRocket, Prop_Send, "m_CollisionGroup"));
	SetEntDataEnt2(rocket, testOffset, GetEntDataEnt2(baseRocket, testOffset), true);
	
	// to get stats from the user's melee weapon
	SetEntPropEnt(rocket, Prop_Send, "m_hOriginalLauncher", GetEntPropEnt(baseRocket, Prop_Send, "m_hOriginalLauncher"));
	SetEntPropEnt(rocket, Prop_Send, "m_hLauncher", GetEntPropEnt(baseRocket, Prop_Send, "m_hLauncher"));

	// must reskin after spawn
	SetEntProp(rocket, Prop_Send, "m_nModelIndex", GetEntProp(baseRocket, Prop_Send, "m_nModelIndex"));
	
	if (PRINT_DEBUG_SPAM)
		PrintToServer("[sarysapub1] Created a new rocket: %d", rocket);
	
	return rocket;
}

public MonitorRocket(clientIdx, rocket, Float:velocity)
{
	new spec = RW_ActiveWeaponSpec[clientIdx];
	
	// so even if we don't need to monitor a rocket, we may still need to reskin it
	if (RWI_ModelOverrideIdx[spec] != -1)
		SetEntProp(rocket, Prop_Send, "m_nModelIndex", RWI_ModelOverrideIdx[spec]);
		
	// trail override
	if (!IsEmptyString(RWI_ParticleOverride[spec]))
	{
		new particle = AttachParticle(rocket, RWI_ParticleOverride[spec]);
		if (IsValidEntity(particle))
			CreateTimer(10.0, RemoveEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE); // sanity timer
	}
	
	// mandatory sunbeams effect for god mode. gotta make it more god-like looking as in ROTT :P
	if (RWI_Type[spec] == RW_TYPE_GOD_MODE)
	{
		new particle = AttachParticle(rocket, "superrare_beams1");
		if (IsValidEntity(particle))
			CreateTimer(10.0, RemoveEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE); // sanity timer
	}
	
	// do we really, truly need to monitor this rocket?
	// now that there's fake rocket jumping, yes.
	//if (RWI_HomingDegreesPerSecond[spec] <= 0.0 && RWI_RandomDeviationPerSecond[spec] <= 0.0 && RWI_NumAdditionalExplosions[spec] <= 0)
	//{
	//	if (PRINT_DEBUG_SPAM)
	//		PrintToServer("[sarysapub1] Rocket created but does not need to be monitored.");
	//	return;
	//}
	
	// find a free spot
	new rocketIdx = -1;
	for (new i = 0; i < MAX_ROCKETS; i++)
	{
		if (RMR_RocketEntRef[i] == 0)
		{
			rocketIdx = i;
			break;
		}
	}
	
	// delete last rocket if somehow there's more than 30
	if (rocketIdx == -1)
	{
		RemoveRocketAt(0, false);
		rocketIdx = MAX_ROCKETS - 1;
	}
	
	// now just do copies and inits, simple stuff
	RMR_Spec[rocketIdx] = spec;
	RMR_RocketEntRef[rocketIdx] = EntIndexToEntRef(rocket);
	RMR_NextDeviationAt[rocketIdx] = GetEngineTime() + RW_HomingInterval;
	RMR_HomingPerSecond[rocketIdx] = RWI_HomingDegreesPerSecond[spec];
	RMR_RandomDeviationPerSecond[rocketIdx] = RWI_RandomDeviationPerSecond[spec];
	RMR_CurrentHomingTarget[rocketIdx] = -1;
	RMR_CanRetarget[rocketIdx] = !RWI_ObsessiveHoming[spec];
	RMR_RocketVelocity[rocketIdx] = velocity;
	RMR_HasTargeted[rocketIdx] = false;
	RMR_FirebombCount[rocketIdx] = RWI_NumAdditionalExplosions[spec];
	RMR_FirebombsActivated[rocketIdx] = 0;
	new damageOffset = FindSendPropOffs("CTFProjectile_Rocket", "m_iDeflected") + 4; // credit to voogru
	RMR_FirebombDamage[rocketIdx] = RoundFloat(GetEntDataFloat(rocket, damageOffset));
	RMR_RocketOwner[rocketIdx] = clientIdx;
	RMR_FirebombInterval[rocketIdx] = RWI_ExplosionInterval[spec];
	RMR_ChainExplosionStartedAt[rocketIdx] = 0.0;
	GetEntPropVector(rocket, Prop_Send, "m_vecOrigin", RMR_LastPosition[rocketIdx]);
	GetEntPropVector(rocket, Prop_Send, "m_angRotation", RMR_LastAngle[rocketIdx]);
	
	// efficiency, no sense doing the deviation check if there's no homing/deviation
	if (RMR_RandomDeviationPerSecond[rocketIdx] <= 0.0 && RMR_HomingPerSecond[rocketIdx] <= 0.0)
		RMR_NextDeviationAt[rocketIdx] = 999999.0;
}

public RemoveRocketAt(rocketIdx, bool:keepAlive)
{
	new rocket = EntRefToEntIndex(RMR_RocketEntRef[rocketIdx]);
	if (IsValidEntity(rocket) && !keepAlive)
		AcceptEntityInput(rocket, "kill");
		
	for (new i = rocketIdx; i < MAX_ROCKETS - 1; i++)
	{
		RMR_Spec[i] = RMR_Spec[i+1];
		RMR_RocketEntRef[i] = RMR_RocketEntRef[i+1];
		RMR_NextDeviationAt[i] = RMR_NextDeviationAt[i+1];
		RMR_HomingPerSecond[i] = RMR_HomingPerSecond[i+1];
		RMR_RandomDeviationPerSecond[i] = RMR_RandomDeviationPerSecond[i+1];
		RMR_CurrentHomingTarget[i] = RMR_CurrentHomingTarget[i+1];
		RMR_CanRetarget[i] = RMR_CanRetarget[i+1];
		RMR_RocketVelocity[i] = RMR_RocketVelocity[i+1];
		RMR_HasTargeted[i] = RMR_HasTargeted[i+1];
		RMR_FirebombCount[i] = RMR_FirebombCount[i+1];
		RMR_FirebombsActivated[i] = RMR_FirebombsActivated[i+1];
		RMR_FirebombDamage[i] = RMR_FirebombDamage[i+1];
		RMR_RocketOwner[i] = RMR_RocketOwner[i+1];
		RMR_FirebombInterval[i] = RMR_FirebombInterval[i+1];
		RMR_ChainExplosionStartedAt[i] = RMR_ChainExplosionStartedAt[i+1];
		RMR_LastPosition[i][0] = RMR_LastPosition[i+1][0];
		RMR_LastPosition[i][1] = RMR_LastPosition[i+1][1];
		RMR_LastPosition[i][2] = RMR_LastPosition[i+1][2];
		RMR_LastAngle[i][0] = RMR_LastAngle[i+1][0];
		RMR_LastAngle[i][1] = RMR_LastAngle[i+1][1];
		RMR_LastAngle[i][2] = RMR_LastAngle[i+1][2];
	}
	RMR_RocketEntRef[MAX_ROCKETS - 1] = 0;
}

public OnEntityCreated(rocket, const String:classname[])
{
	if (!RW_ActiveThisRound || strcmp(classname, "tf_projectile_rocket"))
		return;
		
	// don't let this execute while rockets are being created by me
	if (RocketBeingCreated)
		return;
		
	//PrintToServer("[sarysapub1] Rocket created... %d / %s", rocket, classname);
		
	// queue it up, as it hasn't been configured yet and is not ready for tracking or duplication
	for (new i = 0; i < ROCKET_QUEUE_SIZE; i++)
	{
		if (RocketQueue[i] == -1)
		{
			RocketQueue[i] = EntIndexToEntRef(rocket);
			break;
		}
	}
}

#define SPLIT_ANGLE_OFFSET 45.0
#define DRUNK_ANGLE_OFFSET 22.5
public TestRocket(rocket)
{
	new clientIdx = GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity") & 0xff;
	if (PRINT_DEBUG_SPAM)
		PrintToServer("[sarysapub1] Testing a rocket. Rocket owner... %d", clientIdx);
	if (!IsLivingPlayer(clientIdx) || !RW_CanUse[clientIdx])
		return;
		
	// so it's the player's rocket. now do we care?
	new spec = RW_ActiveWeaponSpec[clientIdx];
	
	// figure out its velocity
	new Float:vecVelocity[3];
	GetEntPropVector(rocket, Prop_Send, "m_vInitialVelocity", vecVelocity);
	new Float:speed = getLinearVelocity(vecVelocity);
	if (PRINT_DEBUG_SPAM)
		PrintToServer("[sarysapub1] Found missile to have velocity of %f", speed);
		
	// monitor the base rocket first
	MonitorRocket(clientIdx, rocket, speed);
		
	// stuff to do for split missile
	if (RWI_Type[spec] == RW_TYPE_SPLIT || RWI_Type[spec] == RW_TYPE_DRUNK)
	{
		RocketBeingCreated = true;
		
		// before turning the rocket, need to store its angle for the second rocket
		static Float:storedAngle[3];
		static Float:rocketAngle[3];
		GetEntPropVector(rocket, Prop_Send, "m_angRotation", storedAngle);
		
		if (RWI_Type[spec] == RW_TYPE_SPLIT)
		{
			// just change the yaw and velocity (split only)
			rocketAngle[0] = storedAngle[0];
			rocketAngle[1] = fixAngle(storedAngle[1] + SPLIT_ANGLE_OFFSET);
			rocketAngle[2] = storedAngle[2];
			GetAngleVectors(rocketAngle, vecVelocity, NULL_VECTOR, NULL_VECTOR);
			vecVelocity[0] *= speed;
			vecVelocity[1] *= speed;
			vecVelocity[2] *= speed;
			TeleportEntity(rocket, NULL_VECTOR, rocketAngle, vecVelocity);
			
			// spawn a second rocket and monitor it
			rocketAngle[0] = storedAngle[0];
			rocketAngle[1] = fixAngle(storedAngle[1] - SPLIT_ANGLE_OFFSET);
			rocketAngle[2] = storedAngle[2];
			new newRocket = DuplicateRocket(clientIdx, rocket, speed, rocketAngle, 0.1);
			if (IsValidEntity(newRocket))
				MonitorRocket(clientIdx, newRocket, speed);
		}
		else if (RWI_Type[spec] == RW_TYPE_DRUNK)
		{
			// spawn more missiles
			for (new i = 0; i < RWI_AdditionalProjectiles[spec]; i++)
			{
				new mod = i % 4;
				rocketAngle[0] = fixAngle(storedAngle[0] + (mod == 2 ? DRUNK_ANGLE_OFFSET : (mod == 3 ? -DRUNK_ANGLE_OFFSET : 0.0)));
				rocketAngle[1] = fixAngle(storedAngle[1] + (mod == 0 ? DRUNK_ANGLE_OFFSET : (mod == 1 ? -DRUNK_ANGLE_OFFSET : 0.0)));
				rocketAngle[2] = storedAngle[2];
				new newRocket = DuplicateRocket(clientIdx, rocket, speed, rocketAngle, 0.1 * float(i+1));
				if (IsValidEntity(newRocket))
					MonitorRocket(clientIdx, newRocket, speed);
			}
		}
		
			
		RocketBeingCreated = false;
	}
}

// specific to rott weapons, someday if I do proper homing outside of this it shouldn't be hale-central
public bool:RW_IsValidHomingTarget(target)
{
	if (!IsLivingPlayer(target))
		return false;
	else if (GetClientTeam(target) == BossTeam)
		return false;
	else if (TF2_IsPlayerInCondition(target, TFCond_Cloaked) || TF2_IsPlayerInCondition(target, TFCond_Stealthed))
		return false;
	else if (TF2_IsPlayerInCondition(target, TFCond_Disguised) && GetEntProp(target, Prop_Send, "m_nDisguiseTeam") == BossTeam)
		return false;
		
	return true;
}

// needed for short circuit
//public Action:RW_ObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
//{
//	new objectDestroyed = GetEventInt(event, "index");
//	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
//	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
//	
//	PrintToServer("objedest=%d    userid=%d    attacker=%d", objectDestroyed, userid, attacker);
//	
//	for (new i = 0; i < MAX_ROCKETS; i++)
//	{
//		if (RMR_RocketEntRef[i] == 0)
//			break;
//			
//		new rocket = EntRefToEntIndex(RMR_RocketEntRef[i]);
//		if (objectDestroyed == rocket)
//		{
//			if (PRINT_DEBUG_SPAM)
//				PrintToServer("[sarysapub1] Rocket at index %d got short circuited.", i);
//			RemoveRocketAt(i, true);
//			break;
//		}
//	}
//}

/**
 * ROTT Props
 */
public Action:ROTTDamageMonitor(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (RP_NoFallDamage)
		if (damagetype & DMG_FALL && attacker == 0 && inflictor == 0) // allow world fall damage
			return Plugin_Stop;
			
	if (!IsLivingPlayer(victim))
		return Plugin_Continue;
	
	if (RW_ActiveThisRound)
	{
		if (GetClientTeam(victim) == BossTeam)
		{
			if (RW_ArmorActive[victim])
			{
				if ((damagetype & DMG_BLAST) != 0 || (damagetype & DMG_BURN) != 0 || (damagetype & DMG_BULLET) != 0)
				{
					damage = 0.0;
					damagetype |= DMG_PREVENT_PHYSICS_FORCE;
					return Plugin_Changed; // seems that crits are getting through, and nothing I can do about mini-crits.
				}
			}
		}
	}

	return Plugin_Continue;
}
 
public Action:OnPropDamaged(prop, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (!IsLivingPlayer(attacker))
		return Plugin_Continue;
	else if (!IsValidEntity(prop))
		return Plugin_Continue;
		
	if ((damagetype & DMG_CLUB) && GetClientTeam(attacker) == BossTeam)
	{
		// allow bosses to 3-shot the props with melee
		damage = float(GetEntProp(prop, Prop_Data, "m_iMaxHealth") / 3);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public RP_SetErrorState(clientIdx, errorState)
{
	if (errorState != RP_ERROR_STATE_NONE)
		EmitSoundToClient(clientIdx, NOPE_AVI);
		
	RP_ActiveErrorState[clientIdx] = errorState;
	RP_DisplayErrorUntil[clientIdx] = GetEngineTime() + 5.0;
	ROTT_UpdateHUD(clientIdx);
}
 
public Action:RP_ActionSlot(clientIdx, const String:command[], argc)
{
	if (!IsLivingPlayer(clientIdx))
		return Plugin_Continue;
	else if (!RP_CanUse[clientIdx])
		return Plugin_Continue;
		
	IncrementProp(clientIdx);
	return Plugin_Stop;
}

public IncrementProp(clientIdx)
{
	if (RP_CurrentlySelectedProp[clientIdx] == -1)
		return;
		
	new oldSelection = RP_CurrentlySelectedProp[clientIdx];
	for (new i = oldSelection + 1; i < PROP_COUNT; i++)
	{
		if (RP_CanDeployProp[clientIdx][i])
		{
			RP_CurrentlySelectedProp[clientIdx] = i;
			break;
		}
	}
	
	if (RP_CurrentlySelectedProp[clientIdx] == oldSelection)
	{
		for (new i = 0; i < oldSelection; i++)
		{
			if (RP_CanDeployProp[clientIdx][i])
			{
				RP_CurrentlySelectedProp[clientIdx] = i;
				break;
			}
		}
	}
		
	ROTT_UpdateHUD(clientIdx);
}

public bool:SpawnProp(clientIdx)
{
	new propType = RP_CurrentlySelectedProp[clientIdx];
	if (propType < 0 || propType >= PROP_COUNT)
	{
		PrintToServer("[sarysapub1] Somehow user selected an invalid ROTT prop.");
		RP_SetErrorState(clientIdx, RP_ERROR_STATE_UNKNOWN);
		return false; // wtf?
	}
	
	// make sure there's sufficient rage
	new bossIdx = FF2_GetBossIndex(clientIdx);
	new Float:rageCost = RP_FreeProps ? 0.0 : RP_PropRageCost[clientIdx][propType];
	if (FF2_GetBossCharge(bossIdx, 0) < rageCost)
	{
		RP_SetErrorState(clientIdx, RP_ERROR_STATE_NEED_RAGE);
		return false;
	}
	
	// make sure user is on ground if it's the slicer
	if (propType == PROP_SLICER && (GetEntityFlags(clientIdx) & FL_ONGROUND) == 0)
	{
		RP_SetErrorState(clientIdx, RP_ERROR_STATE_GROUND_ONLY);
		return false;
	}
	
	// get our spawn point. the model should be configured correctly so we can place it on the user's coordinates.
	new Float:spawnPoint[3];
	GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", spawnPoint);
	
	// if it's any solid prop, make sure it's not spawned in a location that could trap another player
	if (propType != PROP_SLICER)
	{
		for (new victim = 1; victim < MAX_PLAYERS; victim++)
		{
			if (clientIdx == victim || !IsLivingPlayer(victim))
				continue;
				
			// need to do a cylinder test in a potential blocking radius, which is pretty big (I set max distance high [70.0] to be paranoid)
			static Float:victimOrigin[3];
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimOrigin);
			
			// that 108.0 is a generous 25.0 for the prop and 83.0 for the height of a player
			// needs to be even more stringent for the angle pad
			if (CylinderCollision(spawnPoint, victimOrigin, (propType == PROP_ANGLE_PAD ? 100.0 : 70.0), spawnPoint[2] - 108.0, propType == PROP_ANGLE_PAD ? (spawnPoint[2] + 25.0) : (spawnPoint[2] - 0.01)))
			{
				RP_SetErrorState(clientIdx, RP_ERROR_STATE_PLAYER_BLOCKING);
				return false;
			}
		}
	}
	
	// create the entity
	new prop = CreateEntityByName("prop_physics_override");
	if (!IsValidEntity(prop))
	{
		PrintToServer("[sarysapub1] Failed to create physics prop.");
		RP_SetErrorState(clientIdx, RP_ERROR_STATE_UNKNOWN);
		return false;
	}
	
	// everything but slicer can take damage
	SetEntProp(prop, Prop_Data, "m_takedamage", propType == PROP_SLICER ? 0 : 2);
	
	// give it the same angle of rotation as the player, but override the pitch
	new Float:propAngles[3];
	GetEntPropVector(clientIdx, Prop_Data, "m_angRotation", propAngles);
	propAngles[0] = propType == PROP_ANGLE_PAD ? 45.0 : 0.0;
	SetEntPropVector(prop, Prop_Data, "m_angRotation", propAngles);
	
	// set the model
	new String:modelName[MAX_MODEL_FILE_LENGTH];
	if (propType == PROP_JUMP_PAD)
	{
		modelName = RPJP_JumpPadModel;
		if (PRINT_DEBUG_SPAM)
			PrintToServer("[sarysapub1] %d will spawn a jump pad, model: %s", clientIdx, modelName);
	}
	else if (propType == PROP_ANGLE_PAD)
	{
		modelName = RPJP_AnglePadModel;
		if (PRINT_DEBUG_SPAM)
			PrintToServer("[sarysapub1] %d will spawn an angle pad, model: %s", clientIdx, modelName);
	}
	else if (propType == PROP_SLICER)
	{
		modelName = RPS_SlicerModel;
		if (PRINT_DEBUG_SPAM)
			PrintToServer("[sarysapub1] %d will spawn a slicer, model: %s", clientIdx, modelName);
	}
	else if (propType == PROP_PLATFORM)
	{
		modelName = RPP_PlatformModel;
		if (PRINT_DEBUG_SPAM)
			PrintToServer("[sarysapub1] %d will spawn a platform, model: %s", clientIdx, modelName);
	}
	
	if (strlen(modelName) < 3)
	{
		AcceptEntityInput(prop, "kill");
		PrintToServer("[sarysapub1] ERROR: Model not set for one of your props. Cannot spawn it.");
		RP_SetErrorState(clientIdx, RP_ERROR_STATE_UNKNOWN);
		return false;
	}
	SetEntityModel(prop, modelName);
	
	// angle pad needs to be moved 50HU behind the player so they don't get stuck
	if (propType == PROP_ANGLE_PAD)
	{
		new Float:testAngles[3];
		testAngles[0] = 0.0;
		testAngles[1] = propAngles[1];
		new Float:spawnOffset[3];
		GetAngleVectors(testAngles, spawnOffset, NULL_VECTOR, NULL_VECTOR);
		spawnOffset[0] = (-spawnOffset[0]) * 50.0;
		spawnOffset[1] = (-spawnOffset[1]) * 50.0;
		spawnOffset[2] = RPJP_AnglePadCollision[1][2]; // raise it up so it's not half in the ground
		
		spawnPoint[0] += spawnOffset[0];
		spawnPoint[1] += spawnOffset[1];
		spawnPoint[2] += spawnOffset[2];
	}
	
	// spawn and move it
	DispatchSpawn(prop);
	TeleportEntity(prop, spawnPoint, NULL_VECTOR, NULL_VECTOR);
	SetEntProp(prop, Prop_Data, "m_takedamage", propType == PROP_SLICER ? 0 : 2); // looks familiar.
	
	// set its health
	SetEntProp(prop, Prop_Data, "m_iMaxHealth", RP_PropHealth[propType]);
	SetEntProp(prop, Prop_Data, "m_iHealth", RP_PropHealth[propType]);
	
	// set its collision and movement
	SetEntityMoveType(prop, MOVETYPE_NONE);
	SetEntProp(prop, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_NONE); // fun fact, there is collision with players, but this flag keeps players from getting trapped upon approaching the prop.
	if (propType == PROP_SLICER)
	{
		SetEntProp(prop, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID); // not solid
		SetEntProp(prop, Prop_Send, "m_nSolidType", SOLID_NONE); // not solid
	}
		
	// damage hook it (need to let boss easily destroy it with melee, but not other weapons)
	SDKHook(prop, SDKHook_OnTakeDamage, OnPropDamaged);
	
	// find an open prop, or destroy an old one
	new propIdx = PROP_HighestSpawnedProp + 1;
	if (propIdx >= MAX_PROPS)
	{
		// oldest prop is always 0
		if (PRINT_DEBUG_SPAM)
			PrintToServer("[sarysapub1] Prop limit reached. Replacing oldest prop");
			
		DestroyProp(0, true);
		
		propIdx = PROP_HighestSpawnedProp + 1;
		if (propIdx >= MAX_PROPS)
		{
			PrintToServer("[sarysapub1] ERROR: Prop index is max props somehow...");
			propIdx = MAX_PROPS - 1;
		}
	}

	// initialize prop info
	PROP_HighestSpawnedProp = propIdx;
	PROP_EntRef[propIdx] = EntIndexToEntRef(prop);
	PROP_Type[propIdx] = propType;
	PROP_OwnerUserId[propIdx] = GetClientUserId(clientIdx);
	new Float:triggerTime = GetEngineTime() + (propType == PROP_SLICER ? RPS_DelayBeforeDamage : 0.0) - RP_EffectTriggerInterval[propType];
	for (new i = 1; i < MAX_PLAYERS; i++)
		PROP_NextTriggerTime[propIdx][i] = triggerTime;
		
	// trigger certain effects on the prop creator now, ignoring the collision check
	if (propType == PROP_JUMP_PAD)
		RP_TriggerJumpPad(clientIdx, propIdx);
	else if (propType == PROP_ANGLE_PAD)
		RP_TriggerAnglePad(clientIdx, propIdx, propAngles);
		
	if (DEBUG_HUD)
		ROTT_UpdateHUD(clientIdx);
		
	// spend the rage
	FF2_SetBossCharge(bossIdx, 0, FF2_GetBossCharge(bossIdx, 0) - rageCost);
		
	return true; // yay it works
}

public DestroyProp(propIdx, bool:reorder)
{
	new prop = EntRefToEntIndex(PROP_EntRef[propIdx]);
	if (IsValidEntity(prop))
		RemoveEntity(INVALID_HANDLE, prop);
		
	if (reorder)
	{
		// this is expensive. do it sparingly.
		for (new i = propIdx; i < PROP_HighestSpawnedProp; i++)
		{
			PROP_EntRef[i] = PROP_EntRef[i+1];
			PROP_Type[i] = PROP_Type[i+1];
			PROP_OwnerUserId[i] = PROP_OwnerUserId[i+1];
			for (new j = 0; j < MAX_PLAYERS; j++)
				PROP_NextTriggerTime[i][j] = PROP_NextTriggerTime[i+1][j];
		}
		PROP_HighestSpawnedProp--;
	}
	else
		PROP_EntRef[propIdx] = -1;
}

#define JUMP_PAD_DEFAULT_INTENSITY 1000.0
public RP_TriggerJumpPad(clientIdx, propIdx)
{
	// respect any existing velocity, but completely override Z
	static Float:playerVelocity[3];
	GetEntPropVector(clientIdx, Prop_Data, "m_vecVelocity", playerVelocity);
	playerVelocity[2] = JUMP_PAD_DEFAULT_INTENSITY * RPJP_JumpPadIntensity;
	SetEntPropVector(clientIdx, Prop_Data, "m_vecVelocity", playerVelocity);
	TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, playerVelocity);

	// play the sound
	if (strlen(RPJP_JumpPadSound) > 3)
		PlaySoundLocal(clientIdx, RPJP_JumpPadSound, true, 2);
		
	// set trigger time
	PROP_NextTriggerTime[propIdx][clientIdx] = GetEngineTime() + RP_EffectTriggerInterval[PROP_JUMP_PAD];
}

public RP_TriggerAnglePad(clientIdx, propIdx, Float:propAngles[3])
{
	// get the player's current velocity and dampen it if necessary
	static Float:playerVelocity[3];
	GetEntPropVector(clientIdx, Prop_Data, "m_vecVelocity", playerVelocity);
	playerVelocity[0] *= (1.0 - RPJP_AnglePadDampeningFactor);
	playerVelocity[1] *= (1.0 - RPJP_AnglePadDampeningFactor);
	playerVelocity[2] = 0.0;
	
	// get velocity vectors for this jump pad
	new Float:intensity = (JUMP_PAD_DEFAULT_INTENSITY * 2.0 / 3.0) * RPJP_AnglePadIntensity;
	new Float:tmpVelocity[3];
	GetAngleVectors(propAngles, tmpVelocity, NULL_VECTOR, NULL_VECTOR);
	tmpVelocity[0] *= intensity;
	tmpVelocity[1] *= intensity;
	tmpVelocity[2] *= intensity;
	
	// add the two vectors and change the player's trajectory (cancel out any opposing momentum)
	if (signIsDifferent(playerVelocity[0], tmpVelocity[0]))
		playerVelocity[0] = tmpVelocity[0];
	else
		playerVelocity[0] += tmpVelocity[0];
	if (signIsDifferent(playerVelocity[1], tmpVelocity[1]))
		playerVelocity[1] = tmpVelocity[1];
	else
		playerVelocity[1] += tmpVelocity[1];
	playerVelocity[2] += fabs(tmpVelocity[2]);
	SetEntPropVector(clientIdx, Prop_Data, "m_vecVelocity", playerVelocity);
	TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, playerVelocity);

	// play the sound
	if (strlen(RPJP_JumpPadSound) > 3)
		PlaySoundLocal(clientIdx, RPJP_JumpPadSound, true, 2);

	// set trigger time
	PROP_NextTriggerTime[propIdx][clientIdx] = GetEngineTime() + RP_EffectTriggerInterval[PROP_ANGLE_PAD];
}

public RP_TriggerSlicer(clientIdx, propIdx)
{
	// uber check
	if (!TF2_IsPlayerInCondition(clientIdx, TFCond_Ubercharged))
	{
		// damage the player, including self-damage
		new owner = GetClientOfUserId(PROP_OwnerUserId[propIdx]);
		if (!IsLivingPlayer(owner))
			owner = clientIdx;
		SDKHooks_TakeDamage(clientIdx, owner, owner, RPS_DamagePerCheck, DMG_GENERIC | (RPS_NegatePushForce ? DMG_PREVENT_PHYSICS_FORCE : 0), -1);
	}

	// set trigger time
	PROP_NextTriggerTime[propIdx][clientIdx] = GetEngineTime() + RP_EffectTriggerInterval[PROP_SLICER];
}

/**
 * OnPlayerRunCmd/OnGameFrame
 */
#define TARGET_Z_OFFSET 40.0
#define FAKE_RJ_MAX_DISTANCE 200.0
#define FAKE_RJ_DEFAULT_Z_INTENSITY 500.0
#define FAKE_RJ_DEFAULT_XY_FACTOR 1.5
public OnGameFrame()
{
	if (!PluginActiveThisRound || !RoundInProgress)
		return;

	new Float:curTime = GetEngineTime();

	// ROTT Props
	if (RP_ActiveThisRound)
	{
		// this is a very taxing method. try to alleviate it somewhat by getting all player living states and origins early
		static Float:clientBounds[MAX_PLAYERS_ARRAY][3];
		static bool:clientValid[MAX_PLAYERS_ARRAY];
		static bool:onGround[MAX_PLAYERS_ARRAY];
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			clientValid[clientIdx] = IsLivingPlayer(clientIdx);
			if (clientValid[clientIdx])
			{
				GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", clientBounds[clientIdx]);
				onGround[clientIdx] = (GetEntityFlags(clientIdx) & FL_ONGROUND) != 0;
			}
		}
		
		for (new propIdx = PROP_HighestSpawnedProp; propIdx >= 0; propIdx--)
		{
			new prop = EntRefToEntIndex(PROP_EntRef[propIdx]);
			if (!IsValidEntity(prop))
			{
				DestroyProp(propIdx, true);
				continue;
			}

			// if the prop is a platform, there is no logic to worry about
			if (PROP_Type[propIdx] == PROP_PLATFORM)
				continue;
				
			// get prop bounds
			static Float:propBounds[3];
			GetEntPropVector(prop, Prop_Send, "m_vecOrigin", propBounds);

			// collision tests on all living players
			if (PROP_Type[propIdx] == PROP_JUMP_PAD) // can do a more accurate test with this one
			{
				for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
				{
					if (!clientValid[clientIdx] || !onGround[clientIdx])
						continue;
					
					// do a cylinder collision test
					if (CylinderCollision(propBounds, clientBounds[clientIdx], RPJP_JumpPadCollision[0][0], propBounds[2] + RPJP_JumpPadCollision[0][2], propBounds[2] + RPJP_JumpPadCollision[1][2]))
					{
						if (PROP_NextTriggerTime[propIdx][clientIdx] <= curTime)
						{
							// push 'em up!
							RP_TriggerJumpPad(clientIdx, propIdx);
						}
					}
				}
			}
			else if (PROP_Type[propIdx] == PROP_ANGLE_PAD)
			{
				// get prop angles
				static Float:propAngles[3];
				GetEntPropVector(prop, Prop_Send, "m_angRotation", propAngles);
				
				// get proper collision min/max
				static Float:collisionMin[3];
				collisionMin[0] = propBounds[0] + RPJP_AnglePadCollision[0][0];
				collisionMin[1] = propBounds[1] + RPJP_AnglePadCollision[0][1];
				collisionMin[2] = propBounds[2] + RPJP_AnglePadCollision[0][2];
				static Float:collisionMax[3];
				collisionMax[0] = propBounds[0] + RPJP_AnglePadCollision[1][0];
				collisionMax[1] = propBounds[1] + RPJP_AnglePadCollision[1][1];
				collisionMax[2] = propBounds[2] + RPJP_AnglePadCollision[1][2];
				
				for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
				{
					if (!clientValid[clientIdx])
						continue;
						
					// do a rectangle collision test
					if (WithinBounds(clientBounds[clientIdx], collisionMin, collisionMax))
					{
						if (PROP_NextTriggerTime[propIdx][clientIdx] <= curTime)
						{
							// push 'em!
							RP_TriggerAnglePad(clientIdx, propIdx, propAngles);
						}
					}
				}
			}
			else // if (PROP_Type[propIdx] == PROP_SLICER) [currently implied]
			{
				for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
				{
					if (!clientValid[clientIdx])
						continue;
					
					// need a modifier that depends on if the player's ducking
					new Float:zMod = (GetEntityFlags(clientIdx) & FL_DUCKING) == 0 ? 83.0 : 63.0;

					// do a bounds check along the player, since this thing will be shorter than a player but larger than 20 HU tall
					if (CylinderCollision(propBounds, clientBounds[clientIdx], RPS_SlicerCollision[0][0], (propBounds[2] + RPS_SlicerCollision[0][2]) - zMod, propBounds[2] + RPS_SlicerCollision[1][2]))
					{
						// can we trigger the effect?
						if (PROP_NextTriggerTime[propIdx][clientIdx] <= curTime)
						{
							// damage them
							RP_TriggerSlicer(clientIdx, propIdx);

							PROP_NextTriggerTime[propIdx][clientIdx] = curTime + RP_EffectTriggerInterval[PROP_SLICER];
						}
					}
				}
			}
		}
	}

	// ROTT Weapons
	if (RW_ActiveThisRound)
	{
		// manage homing rockets and firebomb
		for (new rocketIdx = MAX_ROCKETS - 1; rocketIdx >= 0; rocketIdx--)
		{
			if (RMR_RocketEntRef[rocketIdx] == 0)
				continue;
			
			new rocket = EntRefToEntIndex(RMR_RocketEntRef[rocketIdx]);
			if (!IsValidEntity(rocket))
			{
				// fake rocket jump, even with the firebomb
				if (RMR_ChainExplosionStartedAt[rocketIdx] == 0.0 && IsLivingPlayer(RMR_RocketOwner[rocketIdx]) && RWI_Type[RMR_Spec[rocketIdx]] != RW_TYPE_GOD_MODE)
				{
					new type = RWI_Type[RMR_Spec[rocketIdx]];
				
					new Float:bossOrigin[3];
					GetEntPropVector(RMR_RocketOwner[rocketIdx], Prop_Send, "m_vecOrigin", bossOrigin);
					bossOrigin[2] += 80.0;
					new Float:distance = GetVectorDistance(bossOrigin, RMR_LastPosition[rocketIdx]);
					if (distance < FAKE_RJ_MAX_DISTANCE)
					{
						new Float:knockbackVector[3];
						knockbackVector[0] = bossOrigin[0] - RMR_LastPosition[rocketIdx][0];
						knockbackVector[1] = bossOrigin[1] - RMR_LastPosition[rocketIdx][1];
						knockbackVector[2] = bossOrigin[2] - RMR_LastPosition[rocketIdx][2];
						
						// normalize, as this'll eventually become our velocity
						NormalizeVector(knockbackVector, knockbackVector);
						
						// ok, I'm completely bullshitting this.
						// only if it kinda seems like the user tried to RJ and they're off the ground
						// will a RJ occur. 
						if (knockbackVector[2] > 0.25 && (GetEntityFlags(RMR_RocketOwner[rocketIdx]) & FL_ONGROUND) == 0)
						{
							new Float:factorToUse = 1.0 + ((FAKE_RJ_DEFAULT_XY_FACTOR - 1.0) * RW_RJIntensityFactor);
							new Float:intensityToUse = FAKE_RJ_DEFAULT_Z_INTENSITY * RW_RJIntensityFactor;
							
							if (type == RW_TYPE_SPLIT)
							{
								// split missiles are a little nuts without this, but drunk missiles are worse
								factorToUse = 1.0 + ((factorToUse - 1.0) / 2.0);
								intensityToUse /= 2.0;
							}
							else if (type == RW_TYPE_DRUNK)
							{
								// without this the hale would fly all over
								factorToUse = 1.0 + ((factorToUse - 1.0) / float(1 + RWI_AdditionalProjectiles[RMR_Spec[rocketIdx]]));
								intensityToUse /= float(1 + RWI_AdditionalProjectiles[RMR_Spec[rocketIdx]]);
							}
						
							new Float:vecVelocity[3];
							GetEntPropVector(RMR_RocketOwner[rocketIdx], Prop_Data, "m_vecVelocity", vecVelocity);
							vecVelocity[0] *= factorToUse;
							vecVelocity[1] *= factorToUse;
							vecVelocity[2] += intensityToUse;
							SetEntPropVector(RMR_RocketOwner[rocketIdx], Prop_Data, "m_vecVelocity", vecVelocity);
							TeleportEntity(RMR_RocketOwner[rocketIdx], NULL_VECTOR, NULL_VECTOR, vecVelocity);
						}
						
						// alert player not to try to RJ like normal
						if (knockbackVector[2] > 0.25 && (GetEntityFlags(RMR_RocketOwner[rocketIdx]) & FL_DUCKING) != 0)
						{
							RW_ActiveMessageIndex[RMR_RocketOwner[rocketIdx]] = RW_RJ_FAIL;
							RW_MessageActiveUntil[RMR_RocketOwner[rocketIdx]] = GetEngineTime() + 10.0;
							EmitSoundToClient(RMR_RocketOwner[rocketIdx], NOPE_AVI);
							ROTT_UpdateHUD(RMR_RocketOwner[rocketIdx]);
						}
					}
				}
			
				// firebombs managed by a dead entity
				if (RMR_FirebombsActivated[rocketIdx] < RMR_FirebombCount[rocketIdx])
				{
					// abort if the owner is dead
					if (!IsLivingPlayer(RMR_RocketOwner[rocketIdx]))
					{
						RemoveRocketAt(rocketIdx, true);
						if (PRINT_DEBUG_SPAM)
							PrintToServer("[sarysapub1] Rocket (firebomb) %d aborted because owner is dead.", rocketIdx);
						continue;
					}
				
					if (RMR_ChainExplosionStartedAt[rocketIdx] == 0.0)
					{
						RMR_ChainExplosionStartedAt[rocketIdx] = curTime;
						
						// tweak the origin based on pitch, to prevent minor obstacles from blocking explosions (only major ones should)
						if (RMR_LastAngle[rocketIdx][0] < 0.0) // rocket was fired up
							RMR_LastPosition[rocketIdx][2] -= 20.0;
						else if (RMR_LastAngle[rocketIdx][0] > 0.0) // rocket was fired down
							RMR_LastPosition[rocketIdx][2] += 20.0;
					}
				
					if (RMR_ChainExplosionStartedAt[rocketIdx] + (float(1 + RMR_FirebombsActivated[rocketIdx]) * RMR_FirebombInterval[rocketIdx]) <= curTime)
					{
						RMR_FirebombsActivated[rocketIdx]++;
						new Float:minDistance = FIREBOMB_EXPLOSION_DISTANCE_BETWEEN * float(RMR_FirebombsActivated[rocketIdx]);
						new Float:tmpVec[3];
						new Float:firebombAngles[3];
						firebombAngles[0] = 0.0; // in ROTT 2013 and ROTT 1994, the firebomb's pitch was always 0.0
						
						for (new i = 0; i < 4; i++)
						{
							firebombAngles[1] = fixAngle(RMR_LastAngle[rocketIdx][1] + (float(i) * 90.0));
							new Handle:trace = TR_TraceRayFilterEx(RMR_LastPosition[rocketIdx], firebombAngles, (CONTENTS_SOLID | CONTENTS_WINDOW | CONTENTS_GRATE), RayType_Infinite, TraceWallsOnly);
							TR_GetEndPosition(tmpVec, trace);
							CloseHandle(trace);
							new Float:distance = GetVectorDistance(RMR_LastPosition[rocketIdx], tmpVec);
							if (distance >= minDistance)
							{
								// test passed. constrain the distance and trigger an explosion.
								constrainDistance(RMR_LastPosition[rocketIdx], tmpVec, distance, minDistance);
								new firebomb = CreateEntityByName("env_explosion");
								new String:intAsString[12];
								Format(intAsString, 12, "%d", RMR_FirebombDamage[rocketIdx]);
								DispatchKeyValue(firebomb, "iMagnitude", intAsString);
								DispatchKeyValueFloat(firebomb, "DamageForce", 1.0);
								DispatchKeyValue(firebomb, "spawnflags", "0");
								DispatchKeyValue(firebomb, "iRadiusOverride", FIREBOMB_EXPLOSION_RADIUS);
								
								// set data pertinent to the user
								SetEntPropEnt(firebomb, Prop_Send, "m_hOwnerEntity", RMR_RocketOwner[rocketIdx]);
								//Format(intAsString, 12, "%d", RMR_RocketOwner[rocketIdx]); // not this way (but ff2 blocks it anyway)
								//DispatchKeyValue(firebomb, "ignoredEntity", intAsString);
								
								// spawn
								TeleportEntity(firebomb, tmpVec, NULL_VECTOR, NULL_VECTOR);
								DispatchSpawn(firebomb);
								
								// explode!
								AcceptEntityInput(firebomb, "Explode");
								AcceptEntityInput(firebomb, "kill");
							}
						}
					}
				
					// don't cease tracking this rocket until all explosions execute
					if (RMR_FirebombsActivated[rocketIdx] < RMR_FirebombCount[rocketIdx])
						continue;
				}
			
				RemoveRocketAt(rocketIdx, false);
				if (PRINT_DEBUG_SPAM)
					PrintToServer("[sarysapub1] Rocket %d natural end of life.", rocketIdx);
				continue;
			}
			
			// if this rocket has been airblasted, it becomes an ordinary RED rocket (...I know...)
			new owner = GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity");
			if (!IsLivingPlayer(owner) || GetClientTeam(owner) != BossTeam)
			{
				RemoveRocketAt(rocketIdx, true);
				if (PRINT_DEBUG_SPAM)
					PrintToServer("[sarysapub1] Rocket %d got airblasted or owner died.", rocketIdx);
				continue;
			}
			
			//PrintToServer("deltaTime=%f    interval=%f    randomdev=%f   nda=%f", deltaTime, RW_HomingInterval, RMR_RandomDeviationPerSecond[rocketIdx], RMR_NextDeviationAt[rocketIdx]);
			if (RMR_NextDeviationAt[rocketIdx] <= curTime)
			{
				new Float:deltaTime = (curTime - RMR_NextDeviationAt[rocketIdx]) + RW_HomingInterval;
				
				// get the angles and mess with them first
				static Float:rocketAngle[3];
				GetEntPropVector(rocket, Prop_Send, "m_angRotation", rocketAngle);
			
				// missile homing
				if (RMR_HomingPerSecond[rocketIdx] > 0.0)
				{
					static Float:targetOrigin[3];
					static Float:rocketOrigin[3];
					GetEntPropVector(rocket, Prop_Send, "m_vecOrigin", rocketOrigin);
					static Float:tmpAngles[3];
					static Float:tmpOrigin[3];
				
					// first, check if the current target is not out of homing range or dead
					if (RMR_CurrentHomingTarget[rocketIdx] != -1)
					{
						new target = EntRefToEntIndex(RMR_CurrentHomingTarget[rocketIdx]);
						if (!RW_IsValidHomingTarget(target))
						{
							if (PRINT_DEBUG_SPAM)
								PrintToServer("[sarysapub1] Homing target lost. %d is dead.", target);
							RMR_CurrentHomingTarget[rocketIdx] = -1;
						}
						else
						{
							GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetOrigin);
							targetOrigin[2] += TARGET_Z_OFFSET; // target their midsection
							
							// first do a ray trace. if that fails, target lost.
							GetRayAngles(rocketOrigin, targetOrigin, tmpAngles);
							new Handle:trace = TR_TraceRayFilterEx(rocketOrigin, tmpAngles, (CONTENTS_SOLID | CONTENTS_WINDOW | CONTENTS_GRATE), RayType_Infinite, TraceWallsOnly);
							TR_GetEndPosition(tmpOrigin, trace);
							CloseHandle(trace);
							if (GetVectorDistance(rocketOrigin, targetOrigin, true) > GetVectorDistance(rocketOrigin, tmpOrigin, true))
							{
								if (PRINT_DEBUG_SPAM)
									PrintToServer("[sarysapub1] Homing target lost. %d is behind a wall.", target);
								RMR_CurrentHomingTarget[rocketIdx] = -1;
							}
							else
							{
								// check the angles to ensure the rocket can still "see" the player, which is just a lazy check of pitch and yaw
								// though it's almost always going to be yaw that fails first
								if (!AngleWithinTolerance(rocketAngle, tmpAngles, RWI_HomeAngle[RMR_Spec[rocketIdx]]))
								{
									if (PRINT_DEBUG_SPAM)
										PrintToServer("[sarysapub1] Homing target lost. %d is out of homing tolerance. (%f,%f vs %f,%f)", target, rocketAngle[0], rocketAngle[1], tmpAngles[0], tmpAngles[1]);
									RMR_CurrentHomingTarget[rocketIdx] = -1;
								}
							}
						}
					}
					
					// see it homing can be (re)started
					if (RMR_CurrentHomingTarget[rocketIdx] == -1 && !(!RMR_CanRetarget[rocketIdx] && RMR_HasTargeted[rocketIdx]))
					{
						new Float:nearestValidDistance = 9999.0 * 9999.0;
						new Float:testDist = 0.0;
						new nearestValidTarget = -1;
					
						// find the closest target within tolerance
						for (new target = 1; target < MAX_PLAYERS; target++)
						{
							if (!RW_IsValidHomingTarget(target))
								continue;
								
							GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetOrigin);
							targetOrigin[2] += TARGET_Z_OFFSET;
							testDist = GetVectorDistance(rocketOrigin, targetOrigin, true);
							
							// least distance so far?
							if (testDist < nearestValidDistance)
							{
								GetRayAngles(rocketOrigin, targetOrigin, tmpAngles);
								new Handle:trace = TR_TraceRayFilterEx(rocketOrigin, tmpAngles, (CONTENTS_SOLID | CONTENTS_WINDOW | CONTENTS_GRATE), RayType_Infinite, TraceWallsOnly);
								TR_GetEndPosition(tmpOrigin, trace);
								CloseHandle(trace);
								
								// wall test passed?
								if (testDist < GetVectorDistance(rocketOrigin, tmpOrigin, true))
								{
									// angle tolerance passed?
									if (AngleWithinTolerance(rocketAngle, tmpAngles, RWI_LockOnAngle[RMR_Spec[rocketIdx]]))
									{
										nearestValidTarget = target;
										nearestValidDistance = testDist;
									}
								}
							}
						}
						
						// if we've locked on, reflect this
						if (nearestValidTarget != -1)
						{
							RMR_CurrentHomingTarget[rocketIdx] = EntIndexToEntRef(nearestValidTarget);
							RMR_HasTargeted[rocketIdx] = true;
						}
					}
					
					// now home! tmpAngles is already what we want it to be.
					if (RMR_CurrentHomingTarget[rocketIdx] != -1)
					{
						new Float:maxAngleDeviation = deltaTime * RMR_HomingPerSecond[rocketIdx];
						
						for (new i = 0; i < 2; i++)
						{
							if (fabs(rocketAngle[i] - tmpAngles[i]) <= RWI_HomeAngle[RMR_Spec[rocketIdx]])
							{
								if (rocketAngle[i] - tmpAngles[i] < 0.0)
									rocketAngle[i] += fmin(maxAngleDeviation, tmpAngles[i] - rocketAngle[i]);
								else
									rocketAngle[i] -= fmin(maxAngleDeviation, rocketAngle[i] - tmpAngles[i]);
							}
							else // it wrapped around
							{
								new Float:tmpRocketAngle = rocketAngle[i];
							
								if (rocketAngle[i] - tmpAngles[i] < 0.0)
									tmpRocketAngle += 360.0;
								else
									tmpRocketAngle -= 360.0;
									
								if (tmpRocketAngle - tmpAngles[i] < 0.0)
									rocketAngle[i] += fmin(maxAngleDeviation, tmpAngles[i] - tmpRocketAngle);
								else
									rocketAngle[i] -= fmin(maxAngleDeviation, tmpRocketAngle - tmpAngles[i]);
							}
							
							rocketAngle[i] = fixAngle(rocketAngle[i]);
						}
					}
				}
				
				// random deviation for drunk missile
				if (RMR_RandomDeviationPerSecond[rocketIdx] > 0.0)
				{
					new Float:maxAngleDeviation = deltaTime * RMR_RandomDeviationPerSecond[rocketIdx];
					rocketAngle[0] = fixAngle(rocketAngle[0] + RandomNegative(GetRandomFloat(0.0, maxAngleDeviation)));
					rocketAngle[1] = fixAngle(rocketAngle[1] + RandomNegative(GetRandomFloat(0.0, maxAngleDeviation)));
				}
				
				// now use the old velocity and tweak it to match the new angles
				new Float:vecVelocity[3];
				GetAngleVectors(rocketAngle, vecVelocity, NULL_VECTOR, NULL_VECTOR);
				vecVelocity[0] *= RMR_RocketVelocity[rocketIdx];
				vecVelocity[1] *= RMR_RocketVelocity[rocketIdx];
				vecVelocity[2] *= RMR_RocketVelocity[rocketIdx];
				
				// apply both changes
				TeleportEntity(rocket, NULL_VECTOR, rocketAngle, vecVelocity);
				
				RMR_NextDeviationAt[rocketIdx] = curTime + RW_HomingInterval;
			}
			
			// always need to get these if there'll be a firebomb
			if (RMR_FirebombCount[rocketIdx] > 0)
			{
				GetEntPropVector(rocket, Prop_Send, "m_vecOrigin", RMR_LastPosition[rocketIdx]);
				GetEntPropVector(rocket, Prop_Send, "m_angRotation", RMR_LastAngle[rocketIdx]);
			}
		}
		
		// test new rockets
		for (new i = 0; i < ROCKET_QUEUE_SIZE; i++)
		{
			if (RocketQueue[i] != -1)
			{
				new rocket = EntRefToEntIndex(RocketQueue[i]);
				if (IsValidEntity(rocket))
					TestRocket(rocket);
				RocketQueue[i] = -1;
			}
		}
	}
	
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx) || GetClientTeam(clientIdx) != BossTeam)
			continue;

		// ROTT Infinity Pistol
		if (RIP_ActiveThisRound && RIP_IsUsing[clientIdx])
		{
			if (RIP_NextAwardTime[clientIdx] <= GetEngineTime())
			{
				new pistol = GetPlayerWeaponSlot(clientIdx, RIP_IsPrimary[clientIdx] ? TFWeaponSlot_Primary : TFWeaponSlot_Secondary);
				if (IsValidEntity(pistol))
				{
					SetEntProp(pistol, Prop_Send, "m_iClip1", RIP_AwardAmmoCount[clientIdx]);
					SetEntProp(pistol, Prop_Send, "m_iClip2", RIP_AwardAmmoCount[clientIdx]);
				}

				RIP_NextAwardTime[clientIdx] = GetEngineTime() + RIP_AWARD_INTERVAL;
			}
		}
	
		// ROTT weapons
		if (RW_ActiveThisRound && RW_CanUse[clientIdx])
		{
			if (RW_ActiveMessageIndex[clientIdx] != -1 && RW_MessageActiveUntil[clientIdx] <= GetEngineTime())
			{
				RW_ActiveMessageIndex[clientIdx] = -1;
				ROTT_UpdateHUD(clientIdx);
			}

			// is it time to remove armor and/or god mode?
			if (RW_ArmorActive[clientIdx] && RW_ArmorActiveUntil[clientIdx] <= GetEngineTime())
			{
				if (PRINT_DEBUG_INFO)
					PrintToServer("[sarysapub1] Armor expired.");

				// only change the user's active weapon if necessary
				new bool:shouldChangeWeapon = false;
				new oldWeapon = GetEntPropEnt(clientIdx, Prop_Data, "m_hActiveWeapon");
				if (IsValidEntity(oldWeapon))
				{
					static String:oldClassname[MAX_WEAPON_NAME_LENGTH];
					GetEntityClassname(oldWeapon, oldClassname, MAX_WEAPON_NAME_LENGTH);
					if (!strcmp(oldClassname, RFM_WeaponName[clientIdx]))
						shouldChangeWeapon = true;
				}

				TF2_RemoveWeaponSlot(clientIdx, TFWeaponSlot_Melee);
				new melee = SpawnWeapon(clientIdx, RFM_WeaponName[clientIdx], RFM_WeaponIdx[clientIdx], 101, 5, RFM_WeaponArgs[clientIdx], RFM_WeaponVisibility[clientIdx]);
				if (IsValidEntity(melee) && shouldChangeWeapon)
					SetEntPropEnt(clientIdx, Prop_Data, "m_hActiveWeapon", melee);
				RW_ArmorActive[clientIdx] = false;
			}

			if (RW_GodModeActive[clientIdx] && RW_GodModeActiveUntil[clientIdx] <= GetEngineTime())
			{
				if (PRINT_DEBUG_INFO)
					PrintToServer("[sarysapub1] God mode expired.");
				SetEntProp(clientIdx, Prop_Data, "m_takedamage", 2);
				if (TF2_IsPlayerInCondition(clientIdx, TFCond_Ubercharged))
					TF2_RemoveCondition(clientIdx, TFCond_Ubercharged);
				if (TF2_IsPlayerInCondition(clientIdx, TFCond_MegaHeal))
					TF2_RemoveCondition(clientIdx, TFCond_MegaHeal);
				TF2_RemoveWeaponSlot(clientIdx, TFWeaponSlot_Primary); // remove the nearly bottomless rocket launcher
				SetEntPropEnt(clientIdx, Prop_Data, "m_hActiveWeapon", GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Melee));
				RW_GodModeActive[clientIdx] = false;
			}
			else if (RW_GodModeActive[clientIdx] && RW_NextGodModeSoundAt[clientIdx] <= GetEngineTime())
			{
				new highestSoundIndex = -1;
				for (new i = 0; i < RW_MAX_GODMODE_SOUNDS; i++)
				{
					if (!(strlen(RW_GodModeSounds[i]) > 3))
						break;
					highestSoundIndex = i;
				}

				if (highestSoundIndex > -1)
				{
					new soundIdx = GetRandomInt(0, highestSoundIndex);
					EmitSoundToAll(RW_GodModeSounds[soundIdx]);
					EmitSoundToAll(RW_GodModeSounds[soundIdx]);
				}

				RW_NextGodModeSoundAt[clientIdx] = GetEngineTime() + 5.0;
			}
		}

		// HUD
		if ((RP_ActiveThisRound || RW_ActiveThisRound) && (RP_CanUse[clientIdx] || RW_CanUse[clientIdx]))
		{
			if (ROTT_HudRefreshAt[clientIdx] <= GetEngineTime())
			{
				// going with the FF2 timer values, since I'd like it to be fairly responsive
				SetHudTextParams(-1.0, 0.6, 0.15, 255, 64, 64, 192);
				ShowHudText(clientIdx, -1, ROTT_HudMessage[clientIdx]);
				ROTT_HudRefreshAt[clientIdx] = GetEngineTime() + 0.1;
			}
		}
	}
}
 
public Action:OnPlayerRunCmd(clientIdx, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!PluginActiveThisRound || !RoundInProgress || !IsLivingPlayer(clientIdx))
		return Plugin_Continue;

	// ROTT props
	if (RP_ActiveThisRound && RP_CanUse[clientIdx])
	{
		if ((!RP_SpecialKeyDown[clientIdx] && (buttons & IN_ATTACK3)) || (!RP_AltFireKeyDown[clientIdx] && (buttons & IN_ATTACK2)))
			SpawnProp(clientIdx);
			
		if (!RP_ReloadKeyDown[clientIdx] && (buttons & IN_RELOAD))
			IncrementProp(clientIdx);
			
		RP_SpecialKeyDown[clientIdx] = (buttons & IN_ATTACK3) != 0;
		RP_AltFireKeyDown[clientIdx] = (buttons & IN_ATTACK2) != 0;
		RP_ReloadKeyDown[clientIdx] = (buttons & IN_RELOAD) != 0;
		
		// error state
		if (RP_ActiveErrorState[clientIdx] != RP_ERROR_STATE_NONE && RP_DisplayErrorUntil[clientIdx] <= GetEngineTime())
		{
			RP_ActiveErrorState[clientIdx] = RP_ERROR_STATE_NONE;
			ROTT_UpdateHUD(clientIdx);
		}
	}

	return Plugin_Continue;
}

/**
 * General helper stocks, some original, some taken/modified from other sources
 */
stock PlaySoundLocal(clientIdx, String:soundPath[], bool:followPlayer = true, stack = 1)
{
	// play a speech sound that travels normally, local from the player.
	decl Float:playerPos[3];
	GetClientEyePosition(clientIdx, playerPos);
	//PrintToServer("eye pos=%f,%f,%f     sound=%s", playerPos[0], playerPos[1], playerPos[2], soundPath);
	for (new i = 0; i < stack; i++)
		EmitAmbientSound(soundPath, playerPos, followPlayer ? clientIdx : SOUND_FROM_WORLD);
}

stock ParticleEffectAt(Float:position[3], String:effectName[], Float:duration = 0.1)
{
	if (IsEmptyString(effectName))
		return -1; // nothing to display
		
	new particle = CreateEntityByName("info_particle_system");
	if (particle != -1)
	{
		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "effect_name", effectName);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		if (duration > 0.0)
			CreateTimer(duration, RemoveEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	}
	return particle;
}

stock AttachParticle(entity, const String:particleType[], Float:offset=0.0, bool:attach=true)
{
	new particle = CreateEntityByName("info_particle_system");
	
	if (!IsValidEntity(particle))
		return -1;

	decl String:targetName[128];
	decl Float:position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[2] += offset;
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	if (attach)
	{
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	}
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	return particle;
}

public Action:RemoveEntity(Handle:timer, any:entid)
{
	new entity = EntRefToEntIndex(entid);
	if (IsValidEdict(entity) && entity > MaxClients)
	{
		TeleportEntity(entity, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR); // send it away first in case it feels like dying dramatically
		AcceptEntityInput(entity, "Kill");
	}
}

stock bool:IsLivingPlayer(clientIdx)
{
	if (clientIdx <= 0 || clientIdx >= MAX_PLAYERS)
		return false;
		
	return IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx);
}

stock bool:IsValidBoss(clientIdx)
{
	if (!IsLivingPlayer(clientIdx))
		return false;
		
	return GetClientTeam(clientIdx) == BossTeam;
}

stock FindRandomLivingMerc(team = 2, exclude = -1)
{
	new sanity = 0;
	while (sanity < 100) // break inside
	{
		new i = GetRandomInt(1, 22);
		if (IsLivingPlayer(i) && GetClientTeam(i) == team && i != exclude)
			return i;
			
		sanity++;
	}
			
	return -1;
}

stock SwitchWeapon(bossClient, String:weaponName[], weaponIdx, String:weaponAttributes[], visible)
{
	TF2_RemoveWeaponSlot(bossClient, TFWeaponSlot_Primary);
	TF2_RemoveWeaponSlot(bossClient, TFWeaponSlot_Secondary);
	TF2_RemoveWeaponSlot(bossClient, TFWeaponSlot_Melee);
	new weapon;
	weapon = SpawnWeapon(bossClient, weaponName, weaponIdx, 101, 5, weaponAttributes, visible);
	SetEntPropEnt(bossClient, Prop_Data, "m_hActiveWeapon", weapon);
}

stock SpawnWeapon(client, String:name[], index, level, quality, String:attribute[], visible = 1)
{
	new Handle:weapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, quality);
	new String:attributes[32][32];
	new count = ExplodeString(attribute, ";", attributes, 32, 32);
	if(count%2!=0)
	{
		count--;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		new i2 = 0;
		for(new i = 0; i < count; i += 2)
		{
			new attrib = StringToInt(attributes[i]);
			if (attrib == 0)
			{
				LogError("Bad weapon attribute passed: %s ; %s", attributes[i], attributes[i+1]);
				return -1;
			}
			TF2Items_SetAttribute(weapon, i2, attrib, StringToFloat(attributes[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}

	if (weapon == INVALID_HANDLE)
	{
		PrintToServer("[sarysapub1] Error: Invalid weapon spawned. client=%d name=%s idx=%d attr=%s", client, name, index, attribute);
		return -1;
	}

	new entity = TF2Items_GiveNamedItem(client, weapon);
	CloseHandle(weapon);
	EquipPlayerWeapon(client, entity);
	
	// sarysa addition
	if (!visible)
	{
		SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
	}
	
	return entity;
}

stock ParseFloatRange(String:rangeStr[MAX_RANGE_STRING_LENGTH], &Float:min, &Float:max)
{
	new String:rangeStrs[2][32];
	ExplodeString(rangeStr, ",", rangeStrs, 2, 32);
	min = StringToFloat(rangeStrs[0]);
	max = StringToFloat(rangeStrs[1]);
}

stock ParseHull(String:hullStr[MAX_HULL_STRING_LENGTH], Float:hull[2][3])
{
	new String:hullStrs[2][MAX_HULL_STRING_LENGTH / 2];
	new String:vectorStrs[3][MAX_HULL_STRING_LENGTH / 6];
	ExplodeString(hullStr, " ", hullStrs, 2, MAX_HULL_STRING_LENGTH / 2);
	for (new i = 0; i < 2; i++)
	{
		ExplodeString(hullStrs[i], ",", vectorStrs, 3, MAX_HULL_STRING_LENGTH / 6);
		hull[i][0] = StringToFloat(vectorStrs[0]);
		hull[i][1] = StringToFloat(vectorStrs[1]);
		hull[i][2] = StringToFloat(vectorStrs[2]);
	}
}

stock ReadHull(bossIdx, const String:ability_name[], argInt, Float:hull[2][3])
{
	static String:hullStr[MAX_HULL_STRING_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, hullStr, MAX_HULL_STRING_LENGTH);
	ParseHull(hullStr, hull);
}

stock ReadSound(bossIdx, const String:ability_name[], argInt, String:soundFile[MAX_SOUND_FILE_LENGTH])
{
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, soundFile, MAX_SOUND_FILE_LENGTH);
	if (strlen(soundFile) > 3)
		PrecacheSound(soundFile);
}

stock ReadModel(bossIdx, const String:ability_name[], argInt, String:modelFile[MAX_MODEL_FILE_LENGTH])
{
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, modelFile, MAX_MODEL_FILE_LENGTH);
	if (strlen(modelFile) > 3)
		PrecacheModel(modelFile);
}

stock ReadModelToInt(bossIdx, const String:ability_name[], argInt)
{
	static String:modelFile[MAX_MODEL_FILE_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, modelFile, MAX_MODEL_FILE_LENGTH);
	if (strlen(modelFile) > 3)
		return PrecacheModel(modelFile);
	return -1;
}

stock ReadCenterText(bossIdx, const String:ability_name[], argInt, String:centerText[MAX_CENTER_TEXT_LENGTH])
{
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, centerText, MAX_CENTER_TEXT_LENGTH);
	ReplaceString(centerText, MAX_CENTER_TEXT_LENGTH, "\\n", "\n");
}

public bool:TraceWallsOnly(entity, contentsMask)
{
	return false;
}

stock Float:fixAngle(Float:angle)
{
	new sanity = 0;
	while (angle < -180.0 && (sanity++) <= 10)
		angle = angle + 360.0;
	while (angle > 180.0 && (sanity++) <= 10)
		angle = angle - 360.0;
		
	return angle;
}

stock Float:fixDamageForFF2(Float:damage)
{
	if (damage <= 160.0)
		return damage / 3.0;
	return damage;
}

stock fixAngles(Float:angles[3])
{
	for (new i = 0; i < 3; i++)
		angles[i] = fixAngle(angles[i]);
}

stock abs(x)
{
	return x < 0 ? -x : x;
}

stock Float:fabs(Float:x)
{
	return x < 0 ? -x : x;
}

stock min(n1, n2)
{
	return n1 < n2 ? n1 : n2;
}

stock Float:fmin(Float:n1, Float:n2)
{
	return n1 < n2 ? n1 : n2;
}

stock max(n1, n2)
{
	return n1 > n2 ? n1 : n2;
}

stock Float:fmax(Float:n1, Float:n2)
{
	return n1 > n2 ? n1 : n2;
}

stock Float:DEG2RAD(Float:n) { return n * 0.017453; }

stock Float:RAD2DEG(Float:n) { return n * 57.29578; }

stock bool:WithinBounds(Float:point[3], Float:min[3], Float:max[3])
{
	return point[0] >= min[0] && point[0] <= max[0] &&
		point[1] >= min[1] && point[1] <= max[1] &&
		point[2] >= min[2] && point[2] <= max[2];
}

stock ReadHexOrDecInt(String:hexOrDecString[HEX_OR_DEC_STRING_LENGTH])
{
	if (StrContains(hexOrDecString, "0x") == 0)
	{
		new result = 0;
		for (new i = 2; i < 10 && hexOrDecString[i] != 0; i++)
		{
			result = result<<4;
				
			if (hexOrDecString[i] >= '0' && hexOrDecString[i] <= '9')
				result += hexOrDecString[i] - '0';
			else if (hexOrDecString[i] >= 'a' && hexOrDecString[i] <= 'f')
				result += hexOrDecString[i] - 'a' + 10;
			else if (hexOrDecString[i] >= 'A' && hexOrDecString[i] <= 'F')
				result += hexOrDecString[i] - 'A' + 10;
		}
		
		return result;
	}
	else
		return StringToInt(hexOrDecString);
}

stock ReadHexOrDecString(bossIdx, const String:ability_name[], argIdx)
{
	static String:hexOrDecString[HEX_OR_DEC_STRING_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argIdx, hexOrDecString, HEX_OR_DEC_STRING_LENGTH);
	return ReadHexOrDecInt(hexOrDecString);
}

stock Float:ConformAxisValue(Float:src, Float:dst, Float:distCorrectionFactor)
{
	return src - ((src - dst) * distCorrectionFactor);
}

stock ConformLineDistance(Float:result[3], const Float:src[3], const Float:dst[3], Float:maxDistance, bool:canExtend = false)
{
	new Float:distance = GetVectorDistance(src, dst);
	if (distance <= maxDistance && !canExtend)
	{
		// everything's okay.
		result[0] = dst[0];
		result[1] = dst[1];
		result[2] = dst[2];
	}
	else
	{
		// need to find a point at roughly maxdistance. (FP irregularities aside)
		new Float:distCorrectionFactor = maxDistance / distance;
		result[0] = ConformAxisValue(src[0], dst[0], distCorrectionFactor);
		result[1] = ConformAxisValue(src[1], dst[1], distCorrectionFactor);
		result[2] = ConformAxisValue(src[2], dst[2], distCorrectionFactor);
	}
}

stock bool:CylinderCollision(Float:cylinderOrigin[3], Float:colliderOrigin[3], Float:maxDistance, Float:zMin, Float:zMax)
{
	if (colliderOrigin[2] < zMin || colliderOrigin[2] > zMax)
		return false;

	static Float:tmpVec1[3];
	tmpVec1[0] = cylinderOrigin[0];
	tmpVec1[1] = cylinderOrigin[1];
	tmpVec1[2] = 0.0;
	static Float:tmpVec2[3];
	tmpVec2[0] = colliderOrigin[0];
	tmpVec2[1] = colliderOrigin[1];
	tmpVec2[2] = 0.0;
	
	return GetVectorDistance(tmpVec1, tmpVec2, true) <= maxDistance * maxDistance;
}

stock Float:getLinearVelocity(Float:vecVelocity[3])
{
	return SquareRoot((vecVelocity[0] * vecVelocity[0]) + (vecVelocity[1] * vecVelocity[1]) + (vecVelocity[2] * vecVelocity[2]));
}

stock Float:RandomNegative(Float:in)
{
	return in * (GetRandomInt(0, 1) == 1 ? 1.0 : -1.0);
}

stock Float:GetRayAngles(Float:startPoint[3], Float:endPoint[3], Float:angle[3])
{
	static Float:tmpVec[3];
	tmpVec[0] = endPoint[0] - startPoint[0];
	tmpVec[1] = endPoint[1] - startPoint[1];
	tmpVec[2] = endPoint[2] - startPoint[2];
	GetVectorAngles(tmpVec, angle);
}

stock bool:AngleWithinTolerance(Float:entityAngles[3], Float:targetAngles[3], Float:tolerance)
{
	static bool:tests[2];
	
	for (new i = 0; i < 2; i++)
		tests[i] = fabs(entityAngles[i] - targetAngles[i]) <= tolerance || fabs(entityAngles[i] - targetAngles[i]) >= 360.0 - tolerance;
	
	return tests[0] && tests[1];
}

stock constrainDistance(const Float:startPoint[], Float:endPoint[], Float:distance, Float:maxDistance)
{
	if (distance <= maxDistance)
		return; // nothing to do
		
	new Float:constrainFactor = maxDistance / distance;
	endPoint[0] = ((endPoint[0] - startPoint[0]) * constrainFactor) + startPoint[0];
	endPoint[1] = ((endPoint[1] - startPoint[1]) * constrainFactor) + startPoint[1];
	endPoint[2] = ((endPoint[2] - startPoint[2]) * constrainFactor) + startPoint[2];
}

stock bool:signIsDifferent(const Float:one, const Float:two)
{
	return one < 0.0 && two > 0.0 || one > 0.0 && two < 0.0;
}
