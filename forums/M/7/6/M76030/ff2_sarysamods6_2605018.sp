// no warranty blah blah don't sue blah blah doing this for fun blah blah...

#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <drain_over_time>
#include <drain_over_time_subplugin>
#include <morecolors>
#undef REQUIRE_PLUGIN
#include <goomba>
#define REQUIRE_PLUGIN

/**
 * My sixth VSP rage pack, rages for Sweetie Bot, Pip Squeak, and has water arena which Sea Pony will use.
 *
 * RageRocketBarrage: Fires multiple uncontrollable non-homing rockets in succession and finishes it off with a cow mangler charged shot.
 *		      Includes a model swap option for Sweetie Bot and supports her attachment points.
 *
 * (Rage/DOT)HaywireSentries: In a specified interval, makes sentries face a random position (or random player) and forces them
 *			      to fire. The typical outcome is they just waste ammo.
 * Known issues: Not intended for a multi-boss setup. Restrict it to single boss, or only give it to one boss of a duo.
 *
 * FF2WaterWeakness: A weakness to water that can manifest itself as damage in water, a sound effect complaining, and/or an overlay while in water.
 *
 * FF2StepSounds: Replacement for a user's step sounds, with options for fine tuning.
 * Known issues: User still hears their own normal footsteps. I believe the client is responsible for this, which is why.
 * 
 * FF2SimplePassives: Simple passive abilities that can prevent soft and hard stuns, afterburn, bleed, getting milked...
 *
 * RageMercConditions: Allows applying of conditions to all mercs and the hale in a radius. If mercs leave the radius, the condition is lost.
 *
 * RageTorpedoAttack: Gives user N charges for an alt-fire (or reload) activated attack which shoots forward, causing massive damage.
 * Known issues: Barrel roll option causes music to stop for the hale. This aesthetic can be disabled in the config file.
 * 
 * DOTNecromancy: Allows reviving the last dead player as a minion, assuming they haven't been dead too long.
 *
 * FF2WaterArena: Sets the arena to be underwater for the entire round. Solves most problems for you, but allows setting of pyro damage, dalokohs
 *		  overheal, damage of fireball spell, and will be modified in the future for future problems...
 * Credits: phatrages for the PreThink water
 *	    EasSidezz for the DX8 fix: https://forums.alliedmods.net/showthread.php?t=257118
 *
 * FF2UnderwaterCharge: A velocity push similar to RageTorpedoAttack but it gives more play control options, cooldown option, and does no damage.
 *                      It's intended to be the underwater equivalent of super jump.
 *
 * FF2UnderwaterSpeed: Since lame water breaks the hale's speed modifications, I made my own.
 *
 * MULTIPLE MOD CREDITS:
 * - Once again used a modified version of asherkin and voogru's rocket creation code.
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

new Float:OFF_THE_MAP[3] = { 16383.0, 16383.0, -16383.0 };

#define NOPE_AVI "vo/engineer_no01.mp3" // DO NOT DELETE FROM FUTURE PACKS

// text string limits
#define MAX_SOUND_FILE_LENGTH 80
#define MAX_MODEL_FILE_LENGTH 128
#define MAX_MATERIAL_FILE_LENGTH 128
#define MAX_WEAPON_NAME_LENGTH 64
#define MAX_WEAPON_ARG_LENGTH 256
#define MAX_EFFECT_NAME_LENGTH 48
#define MAX_ENTITY_CLASSNAME_LENGTH 48
#define MAX_CENTER_TEXT_LENGTH 128
#define MAX_RANGE_STRING_LENGTH 66
#define MAX_HULL_STRING_LENGTH 197
#define MAX_ATTACHMENT_NAME_LENGTH 48
#define COLOR_BUFFER_SIZE 12
#define HEX_OR_DEC_STRING_LENGTH 12 // max -2 billion is 11 chars + null termination

#define MAX_PLAYERS_ARRAY 36
#define MAX_PLAYERS (MAX_PLAYERS_ARRAY < (MaxClients + 1) ? MAX_PLAYERS_ARRAY : (MaxClients + 1))

new MercTeam = _:TFTeam_Red;
new BossTeam = _:TFTeam_Blue;

new RoundInProgress = false;
new bool:PluginActiveThisRound = false;

public Plugin:myinfo = {
	name = "Freak Fortress 2: sarysa's mods, sixth pack",
	author = "sarysa",
	version = "1.1.4",
}

#define FAR_FUTURE 100000000.0
#define IsEmptyString(%1) (%1[0] == 0)
#define COND_JARATE_WATER 86

/**
 * Rocket Barrage
 */
#define RB_STRING "rage_rocket_barrage"
#define RB2_STRING "rocket_barrage2"
#define RB_MAX_ATTACHMENT_POINTS 10
#define RB_ROCKET_POINTS_STR_LENGTH ((RB_MAX_ATTACHMENT_POINTS * (MAX_ATTACHMENT_NAME_LENGTH+1)) + 1)
#define RB_FLAG_SMART_TARGETING 0x0001
#define RB_FLAG_CHARGED_SHOT 0x0002
#define RB_FLAG_IMMOBILE_CHARGING 0x0004
#define RB_FLAG_USE_SENTRYROCKET 0x0008
new bool:RB_ActiveThisRound = false;
new bool:RB_IsUsing[MAX_PLAYERS_ARRAY]; // internal
new RB_RocketsRemaining[MAX_PLAYERS_ARRAY]; // internal, related to arg1
new RB_AttachmentEntRef[MAX_PLAYERS_ARRAY][RB_MAX_ATTACHMENT_POINTS]; // internal, related to arg2
new RB_CurrentAttachmentIdx[MAX_PLAYERS_ARRAY]; // internal, related to arg2
new RB_TotalAttachments[MAX_PLAYERS_ARRAY]; // internal, related to arg2
new Float:RB_FireNextRocketAt[MAX_PLAYERS_ARRAY]; // internal, related to arg3
new Float:RB_FireChargedShotAt[MAX_PLAYERS_ARRAY]; // internal
new RB_ChargedAttachmentEntRef[MAX_PLAYERS_ARRAY]; // internal, related to arg6
new Float:RB_UntransformAt[MAX_PLAYERS_ARRAY]; // internal, related to rb2 arg1
// arg1-2 must be done at rage time
new Float:RB_FireInterval[MAX_PLAYERS_ARRAY]; // arg3
new Float:RB_RocketDamage[MAX_PLAYERS_ARRAY]; // arg4
new Float:RB_ChargedShotDuration[MAX_PLAYERS_ARRAY]; // arg5
// arg6 must be done at rage time
new Float:RB_ChargedDamage[MAX_PLAYERS_ARRAY]; // arg7
// arg8 only needed once, will get it when the shot fires
// arg9-arg10 only needed once per rage
new Float:RB_RocketSpeed[MAX_PLAYERS_ARRAY]; // arg11
new Float:RB_ChargedSpeed[MAX_PLAYERS_ARRAY]; // arg12
// arg13-arg18 only needed once per rage
new RB_Flags[MAX_PLAYERS_ARRAY]; // arg19
// rb2 args
new Float:RB_UntransformDelay[MAX_PLAYERS_ARRAY]; // rb2 arg1
new String:RB_ChargingSound[MAX_SOUND_FILE_LENGTH]; // rb2 arg2
new String:RB_ChargedShotSound[MAX_SOUND_FILE_LENGTH]; // rb2 arg3
new String:RB_RocketFireSound[MAX_SOUND_FILE_LENGTH]; // rb2 arg4
new String:RB_ToWeaponsSound[MAX_SOUND_FILE_LENGTH]; // rb2 arg5
new String:RB_ToNormalSound[MAX_SOUND_FILE_LENGTH]; // rb2 arg6
new String:RB_ToWeaponsEffect[MAX_EFFECT_NAME_LENGTH]; // rb2 arg7
new String:RB_ToNormalEffect[MAX_EFFECT_NAME_LENGTH]; // rb2 arg8
new String:RB_LocationMarkerEffect[MAX_EFFECT_NAME_LENGTH]; // rb2 arg9

// rocket types
#define ROCKET_TYPE_NORMAL 0
#define ROCKET_TYPE_SENTRY 1
#define ROCKET_TYPE_ENERGY 2
// neutral particle
#define RB_NEUTRAL_PARTICLE "crutgun_firstperson"

/**
 * Haywire Sentries
 */
#define RHS_STRING "rage_haywire_sentries"
#define DHS_STRING "dot_haywire_sentries"
#define HS_ROCKET_SOUND "weapons/sentry_rocket.wav"
#define HS_HUD_POSITION 0.68
#define HS_HUD_REFRESH_INTERVAL 1.0
new bool:HS_ActiveThisRound = false;
new bool:HS_CanUse[MAX_PLAYERS_ARRAY]; // internal
new bool:HS_IsDOT[MAX_PLAYERS_ARRAY]; // internal
new bool:HS_IsActive[MAX_PLAYERS_ARRAY]; // internal
new Float:HS_DeactivateAt[MAX_PLAYERS_ARRAY]; // internal
new Float:HS_NextSearchAt[MAX_PLAYERS_ARRAY]; // internal
new Float:HS_NextHUDAt[MAX_PLAYERS_ARRAY]; // internal
// arg1 (duration) is only used by the rage version, at rage time
new Float:HS_Radius[MAX_PLAYERS_ARRAY]; // arg2
new Float:HS_BulletInterval[MAX_PLAYERS_ARRAY]; // arg3
new Float:HS_RocketInterval[MAX_PLAYERS_ARRAY]; // arg4
new Float:HS_RetargetInterval[MAX_PLAYERS_ARRAY]; // arg5
new HS_RetargetMode[MAX_PLAYERS_ARRAY]; // arg6
new Float:HS_SearchInterval[MAX_PLAYERS_ARRAY]; // arg7
new String:HS_ParticleName[MAX_EFFECT_NAME_LENGTH]; // arg8
new String:HS_NoSentriesStr[MAX_CENTER_TEXT_LENGTH]; // arg9
new Float:HS_RocketDamage; // arg10
new String:HS_HudMessage[MAX_CENTER_TEXT_LENGTH]; // arg11

// the actual sentries
#define MAX_HAYWIRE_SENTRIES 10
#define HW_RETARGET_RED_ONLY 0
#define HW_RETARGET_ANYONE 1
#define HW_RETARGET_RANDOM_ANGLE 2
new Sentry_EntRef[MAX_HAYWIRE_SENTRIES];
new Float:Sentry_NextBulletAt[MAX_HAYWIRE_SENTRIES];
new Float:Sentry_NextRocketAt[MAX_HAYWIRE_SENTRIES];
new Float:Sentry_NextRetargetAt[MAX_HAYWIRE_SENTRIES];
new Float:Sentry_CurrentAngle[MAX_HAYWIRE_SENTRIES][3];
new Sentry_Saboteur[MAX_HAYWIRE_SENTRIES];
new Sentry_ParticleEntRef[MAX_HAYWIRE_SENTRIES];

/**
 * Water Weakness
 */
#define WW_STRING "ff2_water_weakness"
new WW_ActiveThisRound = false;
new bool:WW_CanUse[MAX_PLAYERS_ARRAY]; // internal
new bool:WW_WasInWater[MAX_PLAYERS_ARRAY]; // internal
new Float:WW_CanTakeDamageAt[MAX_PLAYERS_ARRAY]; // internal, related to arg2
new WW_CurrentOverlayFrame[MAX_PLAYERS_ARRAY]; // internal, related to arg4
new Float:WW_NextOverlayUpdateAt[MAX_PLAYERS_ARRAY]; // internal, related to arg5
new Float:WW_NextSoundAt[MAX_PLAYERS_ARRAY]; // internal, related to arg7
new Float:WW_Damage[MAX_PLAYERS_ARRAY]; // arg1
new Float:WW_DamageInterval[MAX_PLAYERS_ARRAY]; // arg2
new String:WW_OverlayMaterial[MAX_MATERIAL_FILE_LENGTH]; // arg3
new WW_FrameCount[MAX_PLAYERS_ARRAY]; // arg4
new Float:WW_OverlayInterval[MAX_PLAYERS_ARRAY]; // arg5
new String:WW_SoundFile[MAX_SOUND_FILE_LENGTH]; // arg6
new Float:WW_SoundInterval[MAX_PLAYERS_ARRAY]; // arg7

/**
 * Step Sounds
 */
#define SS_STRING "ff2_step_sounds"
new bool:SS_ActiveThisRound;
new bool:SS_CanUse[MAX_PLAYERS_ARRAY]; // internal
new bool:SS_IsQueued[MAX_PLAYERS_ARRAY]; // internal, get around anti-recursion code. which may or may not exist. who knows. something weird is going wrong with this super-basic ability.
new String:SS_Sound[MAX_PLAYERS_ARRAY][MAX_SOUND_FILE_LENGTH]; // arg1
new Float:SS_Volume[MAX_PLAYERS_ARRAY]; // arg2
new Float:SS_Radius[MAX_PLAYERS_ARRAY]; // arg3
new SS_RepeatCount[MAX_PLAYERS_ARRAY]; // arg4
new bool:SS_IgnorePlayer[MAX_PLAYERS_ARRAY]; // arg5
new bool:SS_IgnoreDead[MAX_PLAYERS_ARRAY]; // arg6

/**
 * Simple Passives
 */
#define SP_STRING "ff2_simple_passives"
new bool:SP_ActiveThisRound;
new bool:SP_CanUse[MAX_PLAYERS_ARRAY]; // internal
new bool:SP_SoftStunImmune[MAX_PLAYERS_ARRAY]; // arg1
new bool:SP_HardStunImmune[MAX_PLAYERS_ARRAY]; // arg2
new bool:SP_Fireproof[MAX_PLAYERS_ARRAY]; // arg3
new bool:SP_Bleedproof[MAX_PLAYERS_ARRAY]; // arg4
new bool:SP_Frictionless[MAX_PLAYERS_ARRAY]; // arg5
new bool:SP_Untraceable[MAX_PLAYERS_ARRAY]; // arg6

/**
 * Rage Merc Conditions
 */
#define MC_STRING "rage_merc_conditions"
#define MC_MAX_CONDITIONS 10
#define MC_RADIUS_CHECK_INTERVAL 0.25
#define MC_OVERLAY_FIX_INTERVAL 0.5
new bool:MC_ActiveThisRound;
new bool:MC_CanUse[MAX_PLAYERS_ARRAY]; // internal
new Float:MC_NextRadiusCheckAt[MAX_PLAYERS_ARRAY]; // internal
new bool:MC_ClearJarateNextTick[MAX_PLAYERS_ARRAY]; // internal
new Float:MC_NextOverlayFixAt; // internal
new Float:MC_RageEndsAt[MAX_PLAYERS_ARRAY]; // internal, based on arg1
new MC_MercConditions[MAX_PLAYERS_ARRAY][MC_MAX_CONDITIONS]; // arg2
new Float:MC_Radius[MAX_PLAYERS_ARRAY]; // arg3
new MC_BossConditions[MAX_PLAYERS_ARRAY][MC_MAX_CONDITIONS]; // arg4
new bool:MC_ClearJarate[MAX_PLAYERS_ARRAY]; // arg5
new bool:MC_FirstPersonFix[MAX_PLAYERS_ARRAY]; // arg6
new bool:MC_CleanWaterOverlay; // arg7

/**
 * Torpedo Attack
 */
#define TA_STRING "rage_torpedo_attack"
#define TA_CHARGE_REFRESH_INTERVAL 0.08
#define TA_HUD_POSITION 0.68
#define TA_HUD_REFRESH_INTERVAL 0.1
new bool:TA_ActiveThisRound;
new bool:TA_CanUse[MAX_PLAYERS_ARRAY]; // internal
new bool:TA_IsCharging[MAX_PLAYERS_ARRAY]; // internal
new Float:TA_ChargingUntil[MAX_PLAYERS_ARRAY]; // internal
new Float:TA_CanBeDamagedAt[MAX_PLAYERS_ARRAY][MAX_PLAYERS_ARRAY]; // internal
new TA_ParticleEntRef[MAX_PLAYERS_ARRAY]; // internal
new Float:TA_SpinAngle[MAX_PLAYERS_ARRAY][3]; // internal, where roll is actually used for once
new bool:TA_DesiredKeyDown[MAX_PLAYERS_ARRAY]; // internal
new Float:TA_RefreshChargeAt[MAX_PLAYERS_ARRAY]; // internal
new Float:TA_NextHUDAt[MAX_PLAYERS_ARRAY]; // internal
new TA_BarrelRollEntRef[MAX_PLAYERS_ARRAY]; // internal
new TA_UsesRemaining[MAX_PLAYERS_ARRAY]; // internal, set by arg1
new bool:TA_Cond86Required[MAX_PLAYERS_ARRAY]; // arg2
new Float:TA_ChargeVelocity[MAX_PLAYERS_ARRAY]; // arg3
new Float:TA_ChargeDuration[MAX_PLAYERS_ARRAY]; // arg4
new Float:TA_TimeForOneSpin[MAX_PLAYERS_ARRAY]; // arg5
new String:TA_Particle[MAX_EFFECT_NAME_LENGTH]; // arg6
new Float:TA_Damage[MAX_PLAYERS_ARRAY]; // arg7
new Float:TA_KnockbackIntensity[MAX_PLAYERS_ARRAY]; // arg8
new Float:TA_DamageInterval[MAX_PLAYERS_ARRAY]; // arg9
new String:TA_Sound[MAX_SOUND_FILE_LENGTH]; // arg10
new bool:TA_IsAltFireActivated[MAX_PLAYERS_ARRAY]; // arg11
new String:TA_HudMessage[MAX_CENTER_TEXT_LENGTH]; // arg12
new bool:TA_ApplyMegaHeal[MAX_PLAYERS_ARRAY]; // arg13
new String:TA_HitSound[MAX_SOUND_FILE_LENGTH]; // arg14
new Float:TA_CollisionHull[2][3]; // arg15
new String:TA_BarrelRollModel[MAX_MODEL_FILE_LENGTH]; // arg16

/**
 * DOT Necromancy
 */
#define NM_STRING "dot_necromancy" // would be weird to have one letter ability prefixes
#define NM_HUD_POSITION 0.60
#define NM_HUD_REFRESH_INTERVAL 0.1
#define NM_POSITION_CHECK_INTERVAL 0.1
#define NM_MODEL_INTERVAL 0.1
#define NM_MODEL_MAX_RETRIES 5
#define NM_SUCCESS 0
#define NM_FAIL_DEAD_TOO_LONG 1
#define NM_FAIL_ALREADY_REVIVED 2
#define NM_FAIL_NO_ONE_OR_LOGGED 3
new bool:NM_ActiveThisRound;
new bool:NM_CanUse[MAX_PLAYERS_ARRAY];
new Float:NM_CheckPositionAt; // only need one of this, since it's recording the states of dead players
new Float:NM_LastPosition[MAX_PLAYERS_ARRAY][3]; // internal, last position of players before they died
new Float:NM_DiedAt[MAX_PLAYERS_ARRAY]; // internal, time they died
new NM_LastDeadPlayer; // internal
new NM_ModelRetries[MAX_PLAYERS_ARRAY]; // internal
new TFClassType:NM_LastClass[MAX_PLAYERS_ARRAY]; // internal
new Float:NM_DespawnAt[MAX_PLAYERS_ARRAY]; // internal, related to arg9. if unused, set to FAR_FUTURE
new NM_MinionBelongsTo[MAX_PLAYERS_ARRAY]; // internal, for despawning minions when the boss dies
new Float:NM_RevivalAnimationFinishAt[MAX_PLAYERS_ARRAY]; // internal, related to arg10
new Float:NM_InvincibilityEndsAt[MAX_PLAYERS_ARRAY]; // internal, related to arg10 and arg11
new Float:NM_ModelSwapRetryAt[MAX_PLAYERS_ARRAY]; // internal, for common problem with minion rages
new Float:NM_NextHUDAt[MAX_PLAYERS_ARRAY]; // internal
new Float:NM_MaxDeadTime[MAX_PLAYERS_ARRAY]; // arg1
// arg 2 inefficient to store this way
new NM_MinionClass[MAX_PLAYERS_ARRAY]; // arg3
// arg 4 inefficient to store this way
new NM_MinionWeaponIdx[MAX_PLAYERS_ARRAY]; // arg5
// arg 6 inefficient to store this way
new NM_MinionWeaponVisibility[MAX_PLAYERS_ARRAY]; // arg7
new Float:NM_MinionMaxHP[MAX_PLAYERS_ARRAY]; // arg8
new Float:NM_MinionLifespan[MAX_PLAYERS_ARRAY]; // arg9
new Float:NM_SpawnAnimationDuration[MAX_PLAYERS_ARRAY]; // arg10
new Float:NM_InvincibilityDuration[MAX_PLAYERS_ARRAY]; // arg11
new String:NM_SpawnParticle[MAX_EFFECT_NAME_LENGTH]; // arg12
new Float:NM_SpawnParticleOffset; // arg13
new String:NM_HudMessage[MAX_CENTER_TEXT_LENGTH]; // arg14
// fail strings
new String:NM_NoOneOrLoggedStr[MAX_CENTER_TEXT_LENGTH]; // arg16
new String:NM_AlreadyRevivedStr[MAX_CENTER_TEXT_LENGTH]; // arg17
new String:NM_DeadTooLongStr[MAX_CENTER_TEXT_LENGTH]; // arg18

/**
 * Water Arena
 */
#define WA_STRING "ff2_water_arena"
#define WA_MAX_HP_DRAIN_WEAPONS 10
#define WA_MAX_ROCKET_MINICRIT_BLACKLIST 30
new bool:WA_ActiveThisRound;
new Float:WA_FixOverlayAt; // internal
new Float:WA_PlayWaterSoundAt[MAX_PLAYERS_ARRAY]; // internal
new Float:WA_RestoreWaterAt[MAX_PLAYERS_ARRAY]; // internal
new bool:WA_AltFireDown[MAX_PLAYERS_ARRAY]; // internal
new bool:WA_FireDown[MAX_PLAYERS_ARRAY]; // internal
new bool:WA_CrouchDown[MAX_PLAYERS_ARRAY]; // internal
new bool:WA_UsingSpellbookLameWater[MAX_PLAYERS_ARRAY]; // internal
new bool:WA_IsThirdPerson[MAX_PLAYERS_ARRAY]; // internal, reflects their setting on the other mod
new bool:WA_OverlayOptOut[MAX_PLAYERS_ARRAY]; // internal, setting for water overlay
new bool:WA_OverlaySupported[MAX_PLAYERS_ARRAY]; // internal, determined by dx80 check
new WA_OOOUserId[MAX_PLAYERS_ARRAY]; // internal, check this every round start that matters
// sandvich and dalokah's handling
#define WA_HEAVY_CONSUMPTION_TIME 4.3
#define WA_HEAVY_EATING_SOUND "vo/sandwicheat09.mp3"
new bool:WA_IsEatingHeavyFood[MAX_PLAYERS_ARRAY]; // internal
new bool:WA_IsDalokohs[MAX_PLAYERS_ARRAY]; // internal
new WA_HeavyFoodHPPerTick[MAX_PLAYERS_ARRAY]; // internal
new WA_HeavyFoodTickCount[MAX_PLAYERS_ARRAY]; // internal
new Float:WA_HeavyFoodStartedAt[MAX_PLAYERS_ARRAY]; // internal
// bonk and crit-a-cola handling
#define WA_SCOUT_DRINKING_SOUND "player/pl_scout_dodge_can_drink.wav"
new bool:WA_IsDrinking[MAX_PLAYERS_ARRAY]; // internal
new bool:WA_IsBonk[MAX_PLAYERS_ARRAY]; // internal
new Float:WA_DrinkingUntil[MAX_PLAYERS_ARRAY]; // internal
new Float:WA_EffectLastsUntil[MAX_PLAYERS_ARRAY]; // internal
// consumable handling
new Float:WA_ConsumableCooldownUntil[MAX_PLAYERS_ARRAY];
// sandman handling
#define WA_SANDMAN_LAMEWATER_DURATION 0.5 // note, it has to be artificially long because sometimes firstperson fails otherwise
new Float:WA_RemoveLameWaterAt[MAX_PLAYERS_ARRAY];
// fix for bug where condition 86 is lost when a player almost lags out
#define WA_WATER_RESTORE_INTERVAL 0.05
new Float:WA_MassRestoreWaterAt;
// the crouch problem
#define WA_CROUCH_JEER_SOUND "vo/scout_jeers06.mp3"
new Float:WA_NoWaterUntil[MAX_PLAYERS_ARRAY];
// 2014-12-23, sometimes the perspective doesn't fix itself
#define FIX_PERSPECTIVE_COUNT 3
new Float:WA_FixPerspectiveAt[MAX_PLAYERS_ARRAY][FIX_PERSPECTIVE_COUNT];
// 2014-12-23, swap the hale to good water when all engies are dead, since lame water is troubled
new bool:WA_AllEngiesDead;
// server operator args
new Float:WA_PyroSecondaryBoost; // arg1
new Float:WA_PyroMeleeBoost; // arg2
new Float:WA_FixInterval; // arg3
new String:WA_UnderwaterSound[MAX_SOUND_FILE_LENGTH]; // arg4
new Float:WA_SoundLoopInterval; // arg5
new Float:WA_Damage; // arg6
new Float:WA_Velocity; // arg7
new bool:WA_AllowSandman; // arg8
new String:WA_UnderwaterOverlay[MAX_MATERIAL_FILE_LENGTH]; // arg9
new Float:WA_HeavyDalokohsBoost; // arg10
new WA_HeavyDalokohsTick; // arg11
new WA_HeavySandvichTick; // arg12
new String:WA_PyroShotgunArgs[MAX_WEAPON_ARG_LENGTH]; // arg13
new String:WA_SniperRifleArgs[MAX_WEAPON_ARG_LENGTH]; // arg14
new WA_HeavyHPDrainWeapons[WA_MAX_HP_DRAIN_WEAPONS]; // arg15
new bool:WA_DontShowNoOverlayInstructions; // arg16
new bool:WA_DontSwitchToGoodWater; // arg17
new bool:WA_RocketMinicritDisabled; // arg18 (related)
new WA_SoldierNoMinicritWeapons[WA_MAX_ROCKET_MINICRIT_BLACKLIST]; // arg18

/**
 * Underwater Charge
 */
#define UC_STRING "ff2_underwater_charge"
#define UC_TYPE_RESTRICTED 0
#define UC_TYPE_FREE 1
#define UC_HUD_POSITION 0.87
#define UC_HUD_REFRESH_INTERVAL 0.1
new bool:UC_ActiveThisRound;
new bool:UC_CanUse[MAX_PLAYERS_ARRAY]; // internal
new Float:UC_LockedAngle[MAX_PLAYERS_ARRAY][3]; // internal, if arg1 is 0
new Float:UC_RefreshChargeAt[MAX_PLAYERS_ARRAY]; // internal, related to arg3
new Float:UC_EndChargeAt[MAX_PLAYERS_ARRAY]; // internal, related to arg5
new Float:UC_UsableAt[MAX_PLAYERS_ARRAY]; // internal, related to arg6
new bool:UC_KeyDown[MAX_PLAYERS_ARRAY]; // internal, related to arg9
new Float:UC_NextHUDAt[MAX_PLAYERS_ARRAY]; // internal
new UC_ChargeType[MAX_PLAYERS_ARRAY]; // arg1
new Float:UC_VelDampening[MAX_PLAYERS_ARRAY]; // arg2
new Float:UC_ChargeVel[MAX_PLAYERS_ARRAY]; // arg3
new Float:UC_ChargeRefreshInterval[MAX_PLAYERS_ARRAY]; // arg4
new Float:UC_Duration[MAX_PLAYERS_ARRAY]; // arg5
new Float:UC_Cooldown[MAX_PLAYERS_ARRAY]; // arg6
new String:UC_Sound[MAX_SOUND_FILE_LENGTH]; // arg7
new Float:UC_RageCost[MAX_PLAYERS_ARRAY]; // arg8
new bool:UC_AltFireActivated[MAX_PLAYERS_ARRAY]; // arg9
new String:UC_CooldownStr[MAX_CENTER_TEXT_LENGTH]; // arg16
new String:UC_InstructionStr[MAX_CENTER_TEXT_LENGTH]; // arg17
new String:UC_NotEnoughRageStr[MAX_CENTER_TEXT_LENGTH]; // arg18

/**
 * Underwater Speed
 */
#define US_STRING "ff2_underwater_speed"
new bool:US_ActiveThisRound;
new bool:US_CanUse[MAX_PLAYERS_ARRAY];
new US_MaxHP[MAX_PLAYERS_ARRAY]; // internal
new Float:US_StartSpeed[MAX_PLAYERS_ARRAY]; // arg1
new Float:US_EndSpeed[MAX_PLAYERS_ARRAY]; // arg2

/**
 * Weapon Blacklist
 */
#define WB_STRING_PREFIX "ff2_weapon_blacklist"
#define WB_ABILITY_HIGHEST 99 // inclusive
#define WB_ABILITY_STRLEN 30

/**
 * METHODS REQUIRED BY ff2 subplugin
 */
PrintRageWarning()
{
	PrintToServer("*********************************************************************");
	PrintToServer("*                             WARNING                               *");
	PrintToServer("*       DEBUG_FORCE_RAGE in ff2_sarysamods6.sp is set to true!      *");
	PrintToServer("*  Any admin can use the 'rage' command to use rages in this pack!  *");
	PrintToServer("*  This is only for test servers. Disable this on your live server. *");
	PrintToServer("*********************************************************************");
}
 
#define CMD_FORCE_RAGE "rage"
public OnPluginStart2()
{
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	PrecacheSound(NOPE_AVI); // DO NOT DELETE IN FUTURE MOD PACKS
	
	RegConsoleCmd("nooverlay", WA_NoOverlay);
	RegConsoleCmd("yesoverlay", WA_YesOverlay);
	for (new clientIdx = 0; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		WA_OverlayOptOut[clientIdx] = false;
		WA_OOOUserId[clientIdx] = 0;
	}
	
	if (DEBUG_FORCE_RAGE)
	{
		PrintRageWarning();
		RegAdminCmd(CMD_FORCE_RAGE, CmdForceRage, ADMFLAG_GENERIC);
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundInProgress = true;
	
	// initialize variables
	PluginActiveThisRound = false;
	RB_ActiveThisRound = false;
	HS_ActiveThisRound = false;
	WW_ActiveThisRound = false;
	SS_ActiveThisRound = false;
	SP_ActiveThisRound = false;
	MC_ActiveThisRound = false;
	TA_ActiveThisRound = false;
	NM_ActiveThisRound = false;
	if (WA_ActiveThisRound) // in case by some freak circumstance it did not unload last round
		WA_RemoveHooks();
	WA_ActiveThisRound = false;
	WA_AllEngiesDead = false;
	UC_ActiveThisRound = false;
	US_ActiveThisRound = false;
	
	for (new i = 0; i < MAX_HAYWIRE_SENTRIES; i++)
	{
		Sentry_EntRef[i] = 0;
		Sentry_Saboteur[i] = 0;
	}
	
	// initialize arrays
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		// all client inits
		RB_IsUsing[clientIdx] = false;
		RB_FireNextRocketAt[clientIdx] = FAR_FUTURE;
		RB_FireChargedShotAt[clientIdx] = FAR_FUTURE;
		RB_CurrentAttachmentIdx[clientIdx] = 0;
		RB_TotalAttachments[clientIdx] = 1;
		HS_CanUse[clientIdx] = false;
		HS_IsActive[clientIdx] = false;
		HS_IsDOT[clientIdx] = false;
		WW_CanUse[clientIdx] = false;
		SS_CanUse[clientIdx] = false;
		SP_CanUse[clientIdx] = false;
		MC_CanUse[clientIdx] = false;
		MC_RageEndsAt[clientIdx] = 0.0;
		MC_ClearJarateNextTick[clientIdx] = false;
		TA_CanUse[clientIdx] = false;
		TA_IsCharging[clientIdx] = false;
		TA_BarrelRollEntRef[clientIdx] = 0;
		NM_CanUse[clientIdx] = false;
		NM_MinionBelongsTo[clientIdx] = -1;
		NM_LastDeadPlayer = -1;
		NM_LastClass[clientIdx] = TFClass_Unknown;
		WA_RestoreWaterAt[clientIdx] = FAR_FUTURE;
		WA_AltFireDown[clientIdx] = false;
		WA_FireDown[clientIdx] = false;
		WA_UsingSpellbookLameWater[clientIdx] = false;
		WA_IsEatingHeavyFood[clientIdx] = false;
		WA_ConsumableCooldownUntil[clientIdx] = 0.0;
		WA_IsDrinking[clientIdx] = false;
		WA_EffectLastsUntil[clientIdx] = 0.0;
		WA_RemoveLameWaterAt[clientIdx] = FAR_FUTURE;
		WA_CrouchDown[clientIdx] = false;
		WA_NoWaterUntil[clientIdx] = 0.0;
		WA_OverlaySupported[clientIdx] = true;
		for (new i = 0; i < FIX_PERSPECTIVE_COUNT; i++)
			WA_FixPerspectiveAt[clientIdx][i] = FAR_FUTURE;
		UC_CanUse[clientIdx] = false;
		US_CanUse[clientIdx] = false;
	
		// boss-only inits
		new bossIdx = FF2_GetBossIndex(clientIdx);
		if (bossIdx < 0)
			continue;
			
		// haywire sentries
		HS_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, RHS_STRING) || FF2_HasAbility(bossIdx, this_plugin_name, DHS_STRING);
		if (HS_CanUse[clientIdx])
		{
			PluginActiveThisRound = true;
			HS_ActiveThisRound = true;
			new String:abilityName[32] = RHS_STRING;
			if ((HS_IsDOT[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, DHS_STRING)) == true)
				abilityName = DHS_STRING;
		
			// ability props
			HS_Radius[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 2);
			HS_BulletInterval[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 3);
			HS_RocketInterval[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 4);
			HS_RetargetInterval[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 5);
			HS_RetargetMode[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, abilityName, 6);
			HS_SearchInterval[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 7);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, abilityName, 8, HS_ParticleName, MAX_EFFECT_NAME_LENGTH);
			ReadCenterText(bossIdx, abilityName, 9, HS_NoSentriesStr);
			HS_RocketDamage = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 10);
			ReadCenterText(bossIdx, abilityName, 11, HS_HudMessage);
			
			// HUD updating
			HS_NextHUDAt[clientIdx] = GetEngineTime();

			// precache firing sound
			PrecacheSound(HS_ROCKET_SOUND);
		}
		
		// water weakness
		if (FF2_HasAbility(bossIdx, this_plugin_name, WW_STRING))
		{
			PluginActiveThisRound = true;
			WW_ActiveThisRound = true;
			WW_CanUse[clientIdx] = true;
			WW_WasInWater[clientIdx] = false;
			WW_CanTakeDamageAt[clientIdx] = GetEngineTime();
			WW_CurrentOverlayFrame[clientIdx] = 0;
			WW_NextOverlayUpdateAt[clientIdx] = GetEngineTime();
			WW_NextSoundAt[clientIdx] = GetEngineTime();
			
			WW_Damage[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, WW_STRING, 1);
			WW_DamageInterval[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, WW_STRING, 2);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, WW_STRING, 3, WW_OverlayMaterial, MAX_MATERIAL_FILE_LENGTH);
			WW_FrameCount[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, WW_STRING, 4);
			WW_OverlayInterval[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, WW_STRING, 5);
			ReadSound(bossIdx, WW_STRING, 6, WW_SoundFile);
			WW_SoundInterval[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, WW_STRING, 7);
		}
		
		// step sounds
		if (FF2_HasAbility(bossIdx, this_plugin_name, SS_STRING))
		{
			PluginActiveThisRound = true;
			SS_ActiveThisRound = true;
			SS_CanUse[clientIdx] = true;
			
			ReadSound(bossIdx, SS_STRING, 1, SS_Sound[clientIdx]);
			SS_Volume[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SS_STRING, 2);
			SS_Radius[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SS_STRING, 3);
			SS_RepeatCount[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SS_STRING, 4);
			SS_IgnorePlayer[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SS_STRING, 5) == 1;
			SS_IgnoreDead[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SS_STRING, 6) == 1;
		}
		
		// simple passives
		if (FF2_HasAbility(bossIdx, this_plugin_name, SP_STRING))
		{
			PluginActiveThisRound = true;
			SP_ActiveThisRound = true;
			SP_CanUse[clientIdx] = true;
			
			SP_SoftStunImmune[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SP_STRING, 1) == 1;
			SP_HardStunImmune[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SP_STRING, 2) == 1;
			SP_Fireproof[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SP_STRING, 3) == 1;
			SP_Bleedproof[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SP_STRING, 4) == 1;
			SP_Frictionless[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SP_STRING, 5) == 1;
			SP_Untraceable[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SP_STRING, 6) == 1;
		}
		
		if (FF2_HasAbility(bossIdx, this_plugin_name, MC_STRING))
		{
			// init this stuff now, even though it's a pure G rage
			// since it is managed in onplayerruncmd
			PluginActiveThisRound = true;
			MC_ActiveThisRound = true;
			MC_CanUse[clientIdx] = true;
			
			// merc conditions
			new String:conditions[MC_MAX_CONDITIONS*4];
			new String:splitConditions[MC_MAX_CONDITIONS][4];
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, MC_STRING, 2, conditions, MC_MAX_CONDITIONS*4);
			new substrCount = ExplodeString(conditions, ";", splitConditions, MC_MAX_CONDITIONS, 4);
			for (new i = 0; i < MC_MAX_CONDITIONS; i++)
				MC_MercConditions[clientIdx][i] = substrCount > i ? StringToInt(splitConditions[i]) : -1;
				
			// aoe radius
			MC_Radius[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, MC_STRING, 3);
			
			// boss (team) conditions
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, MC_STRING, 4, conditions, MC_MAX_CONDITIONS*4);
			substrCount = ExplodeString(conditions, ";", splitConditions, MC_MAX_CONDITIONS, 4);
			for (new i = 0; i < MC_MAX_CONDITIONS; i++)
				MC_BossConditions[clientIdx][i] = substrCount > i ? StringToInt(splitConditions[i]) : -1;
				
			// for specific conditions
			MC_ClearJarate[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, MC_STRING, 5) == 1;
			MC_FirstPersonFix[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, MC_STRING, 6) == 1;
			MC_CleanWaterOverlay = FF2_GetAbilityArgument(bossIdx, this_plugin_name, MC_STRING, 7) == 1;
		}
		
		if (FF2_HasAbility(bossIdx, this_plugin_name, TA_STRING))
		{
			PluginActiveThisRound = true;
			TA_ActiveThisRound = true;
			TA_CanUse[clientIdx] = true;
			TA_NextHUDAt[clientIdx] = GetEngineTime();
			
			TA_Cond86Required[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, TA_STRING, 2) == 1;
			TA_ChargeVelocity[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, TA_STRING, 3);
			TA_ChargeDuration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, TA_STRING, 4);
			TA_TimeForOneSpin[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, TA_STRING, 5);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, TA_STRING, 6, TA_Particle, MAX_EFFECT_NAME_LENGTH);
			TA_Damage[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, TA_STRING, 7);
			TA_KnockbackIntensity[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, TA_STRING, 8);
			TA_DamageInterval[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, TA_STRING, 9);
			ReadSound(bossIdx, TA_STRING, 10, TA_Sound);
			TA_IsAltFireActivated[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, TA_STRING, 11) == 1;
			ReadCenterText(bossIdx, TA_STRING, 12, TA_HudMessage);
			TA_ApplyMegaHeal[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, TA_STRING, 13) == 1;
			ReadSound(bossIdx, TA_STRING, 14, TA_HitSound);
			ReadHull(bossIdx, TA_STRING, 15, TA_CollisionHull);
			ReadModel(bossIdx, TA_STRING, 16, TA_BarrelRollModel);
			
			if (strlen(TA_BarrelRollModel) <= 3)
			{
				TA_BarrelRollModel = "models/props_mining/sign001.mdl"; // this will be buggy but at least it won't crash the server/client
				PrecacheModel(TA_BarrelRollModel);
			}
		}
		
		if (FF2_HasAbility(bossIdx, this_plugin_name, NM_STRING))
		{
			PluginActiveThisRound = true;
			NM_ActiveThisRound = true;
			NM_CanUse[clientIdx] = true;
			NM_CheckPositionAt = GetEngineTime();
			NM_NextHUDAt[clientIdx] = GetEngineTime();
			
			NM_MaxDeadTime[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, NM_STRING, 1);
			ReadModelToInt(bossIdx, NM_STRING, 2); // precache, don't store
			NM_MinionClass[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, NM_STRING, 3);
			NM_MinionWeaponIdx[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, NM_STRING, 5);
			NM_MinionWeaponVisibility[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, NM_STRING, 7);
			NM_MinionMaxHP[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, NM_STRING, 8);
			NM_MinionLifespan[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, NM_STRING, 9);
			NM_SpawnAnimationDuration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, NM_STRING, 10);
			NM_InvincibilityDuration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, NM_STRING, 11);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, NM_STRING, 12, NM_SpawnParticle, MAX_EFFECT_NAME_LENGTH);
			NM_SpawnParticleOffset = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, NM_STRING, 13);
			ReadCenterText(bossIdx, NM_STRING, 14, NM_HudMessage);

			// error strings
			ReadCenterText(bossIdx, NM_STRING, 16, NM_NoOneOrLoggedStr);
			ReadCenterText(bossIdx, NM_STRING, 17, NM_AlreadyRevivedStr);
			ReadCenterText(bossIdx, NM_STRING, 18, NM_DeadTooLongStr);
		}
		
		if (FF2_HasAbility(bossIdx, this_plugin_name, WA_STRING))
		{
			PluginActiveThisRound = true;
			WA_ActiveThisRound = true;
			WA_FixOverlayAt = GetEngineTime();
			WA_MassRestoreWaterAt = GetEngineTime() + 1.0;

			WA_PyroSecondaryBoost = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, WA_STRING, 1);
			WA_PyroMeleeBoost = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, WA_STRING, 2);
			WA_FixInterval = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, WA_STRING, 3);
			
			ReadSound(bossIdx, WA_STRING, 4, WA_UnderwaterSound);
			WA_SoundLoopInterval = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, WA_STRING, 5);
			WA_Damage = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, WA_STRING, 6);
			WA_Velocity = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, WA_STRING, 7);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, WA_STRING, 8, WA_UnderwaterOverlay, MAX_MATERIAL_FILE_LENGTH);
			WA_AllowSandman = (FF2_GetAbilityArgument(bossIdx, this_plugin_name, WA_STRING, 9) == 1);
			WA_HeavyDalokohsBoost = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, WA_STRING, 10);
			WA_HeavyDalokohsTick = FF2_GetAbilityArgument(bossIdx, this_plugin_name, WA_STRING, 11);
			WA_HeavySandvichTick = FF2_GetAbilityArgument(bossIdx, this_plugin_name, WA_STRING, 12);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, WA_STRING, 13, WA_PyroShotgunArgs, MAX_WEAPON_ARG_LENGTH);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, WA_STRING, 14, WA_SniperRifleArgs, MAX_WEAPON_ARG_LENGTH);
			
			// heavy HP drain weapons
			new String:heavyHPDrainWeapons[WA_MAX_HP_DRAIN_WEAPONS * 6];
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, WA_STRING, 15, heavyHPDrainWeapons, WA_MAX_HP_DRAIN_WEAPONS * 6);
			new String:hhdwStrings[WA_MAX_HP_DRAIN_WEAPONS][6];
			ExplodeString(heavyHPDrainWeapons, ",", hhdwStrings, WA_MAX_HP_DRAIN_WEAPONS, 6);
			for (new i = 0; i < WA_MAX_HP_DRAIN_WEAPONS; i++)
				WA_HeavyHPDrainWeapons[i] = StringToInt(hhdwStrings[i]);
				
			// arg 16 and 17
			WA_DontShowNoOverlayInstructions = (FF2_GetAbilityArgument(bossIdx, this_plugin_name, WA_STRING, 16) == 1);
			WA_DontSwitchToGoodWater = (FF2_GetAbilityArgument(bossIdx, this_plugin_name, WA_STRING, 17) == 1);
			
			// rocket minicrit blacklist
			new String:rocketMinicritBlacklist[WA_MAX_ROCKET_MINICRIT_BLACKLIST * 6];
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, WA_STRING, 18, rocketMinicritBlacklist, WA_MAX_ROCKET_MINICRIT_BLACKLIST * 6);
			WA_RocketMinicritDisabled = !strcmp(rocketMinicritBlacklist, "*");
			if (!WA_RocketMinicritDisabled)
			{
				new String:rmdStrings[WA_MAX_ROCKET_MINICRIT_BLACKLIST][6];
				ExplodeString(rocketMinicritBlacklist, ",", rmdStrings, WA_MAX_ROCKET_MINICRIT_BLACKLIST, 6);
				for (new i = 0; i < WA_MAX_ROCKET_MINICRIT_BLACKLIST; i++)
					WA_SoldierNoMinicritWeapons[i] = StringToInt(rmdStrings[i]);
			}
			
			// precache
			PrecacheSound(WA_HEAVY_EATING_SOUND);
			PrecacheSound(WA_SCOUT_DRINKING_SOUND);
			PrecacheSound(WA_CROUCH_JEER_SOUND);
		}
		
		if (FF2_HasAbility(bossIdx, this_plugin_name, UC_STRING))
		{
			PluginActiveThisRound = true;
			UC_ActiveThisRound = true;
			UC_CanUse[clientIdx] = true;
			
			UC_ChargeType[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, UC_STRING, 1);
			UC_VelDampening[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, UC_STRING, 2);
			UC_ChargeVel[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, UC_STRING, 3);
			UC_ChargeRefreshInterval[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, UC_STRING, 4);
			UC_Duration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, UC_STRING, 5);
			UC_Cooldown[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, UC_STRING, 6);
			ReadSound(bossIdx, UC_STRING, 7, UC_Sound);
			UC_RageCost[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, UC_STRING, 8);
			UC_AltFireActivated[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, UC_STRING, 9) == 1;
			
			// HUD strings
			ReadCenterText(bossIdx, UC_STRING, 16, UC_CooldownStr);
			ReadCenterText(bossIdx, UC_STRING, 17, UC_InstructionStr);
			ReadCenterText(bossIdx, UC_STRING, 18, UC_NotEnoughRageStr);

			// precaches and inits
			UC_EndChargeAt[clientIdx] = FAR_FUTURE;
			UC_RefreshChargeAt[clientIdx] = FAR_FUTURE;
			UC_UsableAt[clientIdx] = GetEngineTime();
			UC_KeyDown[clientIdx] = false;
			UC_NextHUDAt[clientIdx] = GetEngineTime();
			
			// warn user they're using a bad ability combo
			if (UC_CanUse[clientIdx] && !WA_ActiveThisRound)
				PrintToServer("[sarysamods6] WARNING: You're using ability %s without ability %s. If this is part of a duo boss and the other has %s, that is fine. Otherwise, expect ability performance to suck.", UC_STRING, UC_STRING, WA_STRING);
				
			if (PRINT_DEBUG_INFO)
				PrintToServer("[sarysamods6] %d using underwater charge this round.", clientIdx);
		}
		
		if (FF2_HasAbility(bossIdx, this_plugin_name, US_STRING))
		{
			PluginActiveThisRound = true;
			US_ActiveThisRound = true;
			US_CanUse[clientIdx] = true;
			US_MaxHP[clientIdx] = 3000;
			
			US_StartSpeed[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, US_STRING, 1);
			US_EndSpeed[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, US_STRING, 2);
		}
	}
	
	if (SS_ActiveThisRound)
		AddNormalSoundHook(HookStepSound);
		
	if (NM_ActiveThisRound)
		HookEvent("player_death", NM_PlayerDeath);
		
	if (WA_ActiveThisRound)
	{
		WA_AddHooks();
		WA_ReplaceBrokenWeapons();
		WA_PerformDX80Check();

		// check user IDs for overlay opt out still match
		for (new clientIdx = 0; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (!IsLivingPlayer(clientIdx))
				continue;
				
			if (WA_OverlayOptOut[clientIdx] && WA_OOOUserId[clientIdx] != GetClientUserId(clientIdx))
				WA_OverlayOptOut[clientIdx] = false;
			
			if (!WA_DontShowNoOverlayInstructions)
			{
				PrintCenterText(clientIdx, "If the water overlay is a missing texture\nand you cannot see anything, type\n!nooverlay in chat to remove.");
				CPrintToChat(clientIdx, "{black}If the water overlay is a missing texture\nand you cannot see anything, type\n!nooverlay in chat to remove.");
			}
		}
		
		// destroy all trigger_push entities on the map, since maps like crevice have a problem where you can't swim back up
		new String:mapName[64];
		GetCurrentMap(mapName, sizeof(mapName));
		if (StrContains(mapName, "megaman6") < 0)
		{
			new triggerPush = -1;
			while ((triggerPush = FindEntityByClassname(triggerPush, "trigger_push")) != -1)
				AcceptEntityInput(triggerPush, "kill");
		}
	}
	
	// need to initialize rocket barrage later.
	CreateTimer(0.3, PostRoundStartInits, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:PostRoundStartInits(Handle:timer)
{
	if (!RoundInProgress)
		return;
		
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		RB_IsUsing[clientIdx] = false;

		if (!IsLivingPlayer(clientIdx))
			continue;

		// boss-only inits
		new bossIdx = FF2_GetBossIndex(clientIdx);
		if (bossIdx < 0)
			continue;

		if (FF2_HasAbility(bossIdx, this_plugin_name, RB_STRING))
		{
			PluginActiveThisRound = true;
			RB_ActiveThisRound = true;

			RB_FireInterval[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, RB_STRING, 3);
			RB_RocketDamage[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, RB_STRING, 4);
			RB_ChargedShotDuration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, RB_STRING, 5);
			RB_ChargedDamage[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, RB_STRING, 7);
			RB_RocketSpeed[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, RB_STRING, 11);
			RB_ChargedSpeed[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, RB_STRING, 12);
			RB_Flags[clientIdx] = ReadHexOrDecString(bossIdx, RB_STRING, 19);

			// precache what needs to be precached
			ReadModelToInt(bossIdx, RB_STRING, 9);
			ReadModelToInt(bossIdx, RB_STRING, 10);

			// swap out the weapon now, for consistency
			RB_WeaponSwap(clientIdx, false);
			
			// ensure required secondary rage is present
			if (!FF2_HasAbility(bossIdx, this_plugin_name, RB2_STRING))
			{
				PrintToServer("[sarysamods6] *******************************************************************************");
				PrintToServer("[sarysamods6] ERROR: Required rage %s is missing. %s will be disabled.", RB2_STRING, RB_STRING);
				PrintToServer("[sarysamods6] *******************************************************************************");
				RB_ActiveThisRound = false;
			}
			else
			{
				RB_UntransformDelay[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, RB2_STRING, 1);
				ReadSound(bossIdx, RB2_STRING, 2, RB_ChargingSound);
				ReadSound(bossIdx, RB2_STRING, 3, RB_ChargedShotSound);
				ReadSound(bossIdx, RB2_STRING, 4, RB_RocketFireSound);
				ReadSound(bossIdx, RB2_STRING, 5, RB_ToWeaponsSound);
				ReadSound(bossIdx, RB2_STRING, 6, RB_ToNormalSound);
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RB2_STRING, 7, RB_ToWeaponsEffect, MAX_EFFECT_NAME_LENGTH);
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RB2_STRING, 8, RB_ToNormalEffect, MAX_EFFECT_NAME_LENGTH);
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RB2_STRING, 9, RB_LocationMarkerEffect, MAX_EFFECT_NAME_LENGTH);
			}
		}
		
		// underwater speed, get max HP now
		if (US_ActiveThisRound && US_CanUse[clientIdx])
			US_MaxHP[clientIdx] = FF2_GetBossMaxHealth(bossIdx);
		
		// weapon blacklist
		new String:abilityName[WB_ABILITY_STRLEN];
		for (new i = 0; i <= WB_ABILITY_HIGHEST; i++)
		{
			Format(abilityName, WB_ABILITY_STRLEN, "%s%d", WB_STRING_PREFIX, i);
			if (FF2_HasAbility(bossIdx, this_plugin_name, abilityName))
			{
				new blacklistIdx = FF2_GetAbilityArgument(bossIdx, this_plugin_name, abilityName, 1);
				static String:weaponName[MAX_WEAPON_NAME_LENGTH];
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, abilityName, 2, weaponName, MAX_WEAPON_NAME_LENGTH);
				new weaponIdx = FF2_GetAbilityArgument(bossIdx, this_plugin_name, abilityName, 3);
				static String:weaponArgs[MAX_WEAPON_ARG_LENGTH];
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, abilityName, 4, weaponArgs, MAX_WEAPON_ARG_LENGTH);
				new clipSize = FF2_GetAbilityArgument(bossIdx, this_plugin_name, abilityName, 5);
				new ammoSize = FF2_GetAbilityArgument(bossIdx, this_plugin_name, abilityName, 6);
				static String:errorMsg[MAX_CENTER_TEXT_LENGTH];
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, abilityName, 7, errorMsg, MAX_CENTER_TEXT_LENGTH);
				for (new victim = 1; victim < MAX_PLAYERS; victim++)
				{
					if (!IsLivingPlayer(victim) || GetClientTeam(victim) == BossTeam)
						continue;
				
					for (new slot = 0; slot <= 2; slot++)
					{
						new weapon = GetPlayerWeaponSlot(victim, slot);
						if (!IsValidEntity(weapon))
							continue;
							
						// if it's blacklisted, replace it.
						if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == blacklistIdx)
						{
							TF2_RemoveWeaponSlot(victim, slot);
							weapon = SpawnWeapon(victim, weaponName, weaponIdx, 100, 1, weaponArgs, true);
							if (IsValidEntity(weapon))
							{
								SetEntPropEnt(victim, Prop_Data, "m_hActiveWeapon", weapon);
								
								// fix ammo and clip
								new offset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1);
								SetEntProp(victim, Prop_Send, "m_iAmmo", ammoSize, 4, offset);
								SetEntProp(weapon, Prop_Send, "m_iClip1", clipSize);
								SetEntProp(weapon, Prop_Send, "m_iClip2", clipSize);
							}
								
							// print to chat if there's a message to print
							if (!IsEmptyString(errorMsg))
								PrintToChat(victim, errorMsg);
								
							// we're done with this player.
							break;
						}
					}
				}
			}
			else if (i >= 1)
				break; // don't check all 99, would be wasteful. assume a list of blacklisted weapons starts with 0 or 1.
		}
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundInProgress = false;
	
	if (HS_ActiveThisRound)
	{
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (HS_IsActive[clientIdx])
				HS_StopHaywire(clientIdx);
		}

		HS_ActiveThisRound = false;
	}
	
	if (RB_ActiveThisRound)
	{
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS;  clientIdx++)
		{
			if (RB_IsUsing[clientIdx])
				RB_EndRage(clientIdx, false);
		}
		
		RB_ActiveThisRound = false;
	}
	
	WW_ActiveThisRound = false;
	
	if (SS_ActiveThisRound)
	{
		SS_ActiveThisRound = false;
		RemoveNormalSoundHook(HookStepSound);
	}
	
	SP_ActiveThisRound = false;
	
	if (MC_ActiveThisRound)
	{
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS;  clientIdx++)
		{
			if (MC_CanUse[clientIdx] && MC_RageEndsAt[clientIdx] != 0)
				MC_EndRage(clientIdx);
		}
		
		MC_ActiveThisRound = false;
	}

	if (TA_ActiveThisRound)
	{
		// fix barrel roll
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (TA_CanUse[clientIdx])
			{
				RemoveEntity(INVALID_HANDLE, TA_BarrelRollEntRef[clientIdx]);
				TA_BarrelRollEntRef[clientIdx] = 0;
				if (IsClientInGame(clientIdx))
					SetClientViewEntity(clientIdx, clientIdx);
			}
		}
	
		TA_ActiveThisRound = false;
	}

	if (NM_ActiveThisRound)
	{
		UnhookEvent("player_death", NM_PlayerDeath);
		
		// fix player classes now
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (!IsClientInGame(clientIdx) || GetClientTeam(clientIdx) <= _:TFTeam_Spectator)
				continue;
				
			if (NM_LastClass[clientIdx] != TFClass_Unknown)
			{
				TF2_SetPlayerClass(clientIdx, NM_LastClass[clientIdx]);
				NM_LastClass[clientIdx] = TFClass_Unknown;
			}
		}
		
		NM_ActiveThisRound = false;
	}
	
	if (WA_ActiveThisRound)
	{
		WA_RemoveHooks();
		WA_ActiveThisRound = false;
	}
	
	UC_ActiveThisRound = false;
}

public Action:FF2_OnAbility2(bossIdx, const String:plugin_name[], const String:ability_name[], status)
{
	if (strcmp(plugin_name, this_plugin_name) != 0)
		return Plugin_Continue;
	else if (!RoundInProgress) // don't execute these rages with 0 players alive
		return Plugin_Continue;
		
	new clientIdx = GetClientOfUserId(FF2_GetBossUserId(bossIdx));

	if (!strcmp(ability_name, RHS_STRING))
	{
		HS_StartHaywire(clientIdx, GetEngineTime() + FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 1));
		
		if (PRINT_DEBUG_INFO)
			PrintToServer("[sarysamods6] Initiating haywire sentries. Expires at %f", HS_DeactivateAt[clientIdx]);
	}
	else if (!strcmp(ability_name, RB_STRING))
	{
		Rage_RocketBarrage(ability_name, bossIdx);
		
		if (PRINT_DEBUG_INFO)
			PrintToServer("[sarysamods6] Executed the Rocket Barrage rage.");
	}
	else if (!strcmp(ability_name, MC_STRING))
	{
		Rage_MercConditions(ability_name, bossIdx);
		
		if (PRINT_DEBUG_INFO)
			PrintToServer("[sarysamods6] Executed the Merc Conditions rage.");
	}
	else if (!strcmp(ability_name, TA_STRING))
	{
		Rage_TorpedoAttack(ability_name, bossIdx);
		
		if (PRINT_DEBUG_INFO)
			PrintToServer("[sarysamods6] Executed the Torpedo Attack rage.");
	}
		
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
	
	if (!strcmp("barrage", unparsedArgs))
	{
		PrintToConsole(user, "Will trigger Rocket Barrage.");
		Rage_RocketBarrage(RB_STRING, 0);
		
		return Plugin_Handled;
	}
	else if (!strcmp("haywire", unparsedArgs))
	{
		PrintToConsole(user, "Will trigger Haywire Sentries.");
		// TODO
		return Plugin_Handled;
	}
	else if (!strcmp("necro", unparsedArgs))
	{
		PrintToConsole(user, "Will trigger necro minion.");
		NM_ReviveLast(GetClientOfUserId(FF2_GetBossUserId(0)));
		return Plugin_Handled;
	}
	
	PrintToServer("[sarysamods6] Rage not found: %s", unparsedArgs);
	return Plugin_Continue;
}

/**
 * DOTs
 */
DOTPostRoundStartInit()
{
	if (!RoundInProgress)
	{
		PrintToServer("[sarysamods6] DOTPostRoundStartInit() called when the round is over?! Shouldn't be possible!");
		return;
	}
	
	// nothing to do
}
 
OnDOTAbilityActivated(clientIdx)
{
	if (!PluginActiveThisRound)
		return;

	if (HS_CanUse[clientIdx] && HS_IsDOT[clientIdx])
	{
		if (FindEntityByClassname(-1, "obj_sentrygun") == -1)
		{
			Nope(clientIdx);
			PrintCenterText(clientIdx, HS_NoSentriesStr);
			CancelDOTAbilityActivation(clientIdx);
			return;
		}
	
		HS_StartHaywire(clientIdx, FAR_FUTURE);
	}
	
	if (NM_CanUse[clientIdx])
	{
		new result = NM_ReviveLast(clientIdx);
		
		if (result != NM_SUCCESS)
		{
			Nope(clientIdx);
			if (result == NM_FAIL_DEAD_TOO_LONG)
				PrintCenterText(clientIdx, NM_DeadTooLongStr);
			else if (result == NM_FAIL_ALREADY_REVIVED)
				PrintCenterText(clientIdx, NM_AlreadyRevivedStr);
			else if (result == NM_FAIL_NO_ONE_OR_LOGGED)
				PrintCenterText(clientIdx, NM_NoOneOrLoggedStr);
			CancelDOTAbilityActivation(clientIdx);
			return;
		}
	}
}

OnDOTAbilityDeactivated(clientIdx)
{
	if (!PluginActiveThisRound)
		return;

	if (HS_CanUse[clientIdx] && HS_IsDOT[clientIdx])
	{
		HS_StopHaywire(clientIdx);
	}
}

OnDOTUserDeath(clientIdx, isInGame)
{
	// suppress
	if (clientIdx || isInGame) { }
}

Action:OnDOTAbilityTick(clientIdx, tickCount)
{	
	if (!PluginActiveThisRound)
		return;

	if (NM_CanUse[clientIdx])
	{
		// since DOT teleport is just a one-time action, deactivate it.
		ForceDOTAbilityDeactivation(clientIdx);
	}

	// suppress
	if (clientIdx || tickCount) { }
}

/**
 * Haywire Sentries
 */
public RemoveSentryAt(sentryIdx)
{
	Sentry_EntRef[sentryIdx] = 0;
	RemoveEntity(INVALID_HANDLE, Sentry_ParticleEntRef[sentryIdx]);

	for (new i = sentryIdx; i < MAX_HAYWIRE_SENTRIES - 2; i++)
	{
		Sentry_EntRef[i] = Sentry_EntRef[i+1];
		Sentry_NextBulletAt[i] = Sentry_NextBulletAt[i+1];
		Sentry_NextRocketAt[i] = Sentry_NextRocketAt[i+1];
		Sentry_NextRetargetAt[i] = Sentry_NextRetargetAt[i+1];
		Sentry_Saboteur[i] = Sentry_Saboteur[i+1];
		Sentry_ParticleEntRef[i] = Sentry_ParticleEntRef[i+1];
		for (new axis = 0; axis < 3; axis++)
			Sentry_CurrentAngle[i][axis] = Sentry_CurrentAngle[i+1][axis];
	}
}

public HS_StartHaywire(clientIdx, Float:deactivateAt)
{
	HS_NextSearchAt[clientIdx] = GetEngineTime();
	HS_IsActive[clientIdx] = true;
	HS_DeactivateAt[clientIdx] = deactivateAt;
	
	for (new i = 0; i < MAX_HAYWIRE_SENTRIES; i++)
	{
		Sentry_ParticleEntRef[i] = 0;
		Sentry_EntRef[i] = 0;
	}
}

public HS_StopHaywire(clientIdx)
{
	HS_IsActive[clientIdx] = false;
	HS_DeactivateAt[clientIdx] = FAR_FUTURE;
	for (new i = 0; i < MAX_HAYWIRE_SENTRIES; i++)
	{
		if (Sentry_ParticleEntRef[i] == 0)
			continue;
			
		RemoveEntity(INVALID_HANDLE, Sentry_ParticleEntRef[i]);
		Sentry_ParticleEntRef[i] = 0;
	}
}

// based on asherkin and voogru's code, though this is almost exactly like the code used for Snowdrop's rockets
// luckily energy ball and sentry rocket derive from rocket so they should be easy
public HS_CreateRocket(engie, sentry, Float:sentryAngle[3])
{
	// create our rocket. no matter what, it's going to spawn, even if it ends up being out of map
	new Float:speed = 1100.0;
	new Float:damage = HS_RocketDamage;
	new String:classname[MAX_ENTITY_CLASSNAME_LENGTH] = "CTFProjectile_SentryRocket";
	new String:entname[MAX_ENTITY_CLASSNAME_LENGTH] = "tf_projectile_sentryrocket";
	
	new rocket = CreateEntityByName(entname);
	if (!IsValidEntity(rocket))
	{
		PrintToServer("[sarysamods6] Error: Invalid entity %s. Won't spawn rocket. This is sarysa's fault.", entname);
		return;
	}
	
	// determine spawn position
	static Float:spawnPosition[3];
	static Float:sentryPos[3];
	GetEntPropVector(sentry, Prop_Data, "m_vecOrigin", sentryPos);
	sentryPos[2] += 50;
	static Float:endPos[3];
	new Handle:trace = TR_TraceRayFilterEx(sentryPos, sentryAngle, (CONTENTS_SOLID | CONTENTS_WINDOW | CONTENTS_GRATE), RayType_Infinite, TraceWallsOnly);
	TR_GetEndPosition(endPos, trace);
	CloseHandle(trace);
	ConformLineDistance(spawnPosition, sentryPos, endPos, 35.0, false);
	
	// determine velocity
	static Float:spawnVelocity[3];
	GetAngleVectors(sentryAngle, spawnVelocity, NULL_VECTOR, NULL_VECTOR);
	spawnVelocity[0] *= speed;
	spawnVelocity[1] *= speed;
	spawnVelocity[2] *= speed;
	
	// deploy!
	TeleportEntity(rocket, spawnPosition, sentryAngle, spawnVelocity);
	SetEntProp(rocket, Prop_Send, "m_bCritical", false); // no random crits
	SetEntDataFloat(rocket, FindSendPropOffs(classname, "m_iDeflected") + 4, damage, true); // credit to voogru
	SetEntProp(rocket, Prop_Send, "m_nSkin", 0); // set skin to red team's
	SetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity", engie);
	SetVariantInt(MercTeam);
	AcceptEntityInput(rocket, "TeamNum", -1, -1, 0);
	SetVariantInt(MercTeam);
	AcceptEntityInput(rocket, "SetTeam", -1, -1, 0); 
	DispatchSpawn(rocket);
	
	// play the sound
	EmitAmbientSound(HS_ROCKET_SOUND, spawnPosition, SOUND_FROM_WORLD);
	
	// to get stats from the sentry
	SetEntPropEnt(rocket, Prop_Send, "m_hOriginalLauncher", GetPlayerWeaponSlot(engie, TFWeaponSlot_Melee));
	SetEntPropEnt(rocket, Prop_Send, "m_hLauncher", GetPlayerWeaponSlot(engie, TFWeaponSlot_Melee));
}

public HS_Tick(Float:curTime)
{
	// find sentries to turn haywire. also, update the HUD if necessary.
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx) || !HS_IsActive[clientIdx])
			continue;
			
		if (curTime >= HS_NextSearchAt[clientIdx])
		{
			// square the dist for efficiency. also get the player's coords.
			static Float:bossOrigin[3];
			GetEntPropVector(clientIdx, Prop_Data, "m_vecOrigin", bossOrigin);
			new Float:maxDist = HS_Radius[clientIdx] * HS_Radius[clientIdx];

			new sentry = -1;
			while ((sentry = FindEntityByClassname(sentry, "obj_sentrygun")) != -1)
			{
				new bool:controllable = true;
			
				// many tests to see if a building is controllable
				static Float:sentryOrigin[3];
				GetEntPropVector(sentry, Prop_Data, "m_vecOrigin", sentryOrigin);
				if (GetVectorDistance(bossOrigin, sentryOrigin, true) > maxDist)
					controllable = false;
				else if (GetEntProp(sentry, Prop_Send, "m_bDisabled"))
					controllable = false;
				else if (GetEntProp(sentry, Prop_Send, "m_bBuilding"))
					controllable = false;
				else if (GetEntProp(sentry, Prop_Send, "m_bPlacing"))
					controllable = false;
				else if (GetEntProp(sentry, Prop_Send, "m_bCarried"))
					controllable = false;
				else if (GetEntProp(sentry, Prop_Send, "m_bPlayerControlled")) // wrangler
					controllable = false;
				else if (!IsLivingPlayer(GetEntPropEnt(sentry, Prop_Send, "m_hBuilder")))
					controllable = false;
				
				if (controllable)
				{
					// add a building to the list, if not already there.
					for (new sentryIdx = 0; sentryIdx < MAX_HAYWIRE_SENTRIES; sentryIdx++)
					{
						if (Sentry_EntRef[sentryIdx] == 0)
						{
							// we reached the last entry. guess the sentry isn't there, so add this one.
							Sentry_EntRef[sentryIdx] = EntIndexToEntRef(sentry);
							Sentry_NextBulletAt[sentryIdx] = curTime;
							Sentry_NextRocketAt[sentryIdx] = curTime;
							Sentry_NextRetargetAt[sentryIdx] = curTime;
							Sentry_Saboteur[sentryIdx] = clientIdx;
							
							// add the particle
							if (!IsEmptyString(HS_ParticleName))
							{
								sentryOrigin[2] += 40.0;
								new effect = ParticleEffectAt(sentryOrigin, HS_ParticleName, 0.0);
								Sentry_ParticleEntRef[sentryIdx] = EntIndexToEntRef(effect);
							}
							break;
						}
						else if (EntRefToEntIndex(Sentry_EntRef[sentryIdx]) == sentry)
							break; // sentry is already being controlled.
					}
				}
				else
				{
					// remove a building from the list.
					for (new sentryIdx = 0; sentryIdx < MAX_HAYWIRE_SENTRIES; sentryIdx++)
					{
						if (Sentry_EntRef[sentryIdx] == 0)
							break; // it's not there
						else if (EntRefToEntIndex(Sentry_EntRef[sentryIdx]) == sentry)
						{
							RemoveSentryAt(sentryIdx);
							break;
						}
					}
				}
			}
			
			HS_NextSearchAt[clientIdx] = curTime + HS_SearchInterval[clientIdx];
		}
	}

	// cycle through the current sentries and make them act weird
	for (new sentryIdx = MAX_HAYWIRE_SENTRIES - 1; sentryIdx >= 0; sentryIdx--)
	{
		if (Sentry_EntRef[sentryIdx] == 0)
			continue;

		new sentry = EntRefToEntIndex(Sentry_EntRef[sentryIdx]);
		new saboteur = Sentry_Saboteur[sentryIdx];
		if (!IsValidEntity(sentry) || !IsLivingPlayer(saboteur))
		{
			RemoveSentryAt(sentryIdx);
			continue;
		}

		// is the ability active on the saboteur?
		if (!HS_IsActive[saboteur])
		{
			RemoveSentryAt(sentryIdx);
			continue;
		}
		
		// is the engie alive?
		new engie = GetEntPropEnt(sentry, Prop_Send, "m_hBuilder");
		if (!IsLivingPlayer(engie))
		{
			RemoveSentryAt(sentryIdx);
			continue;
		}

		// check the angle interval first
		if (curTime >= Sentry_NextRetargetAt[sentryIdx])
		{
			if (HS_RetargetMode[saboteur] == HW_RETARGET_RANDOM_ANGLE)
			{
				Sentry_CurrentAngle[sentryIdx][0] = GetRandomFloat(-60.0, 60.0); // pitch
				Sentry_CurrentAngle[sentryIdx][1] = GetRandomFloat(-179.9, 179.9); // yaw
				Sentry_CurrentAngle[sentryIdx][2] = 0.0; // unused roll
			}
			else
			{
				new livingCount = 0;
				for (new i = 1; i < MAX_PLAYERS; i++) if (IsLivingPlayer(i))
					livingCount++;

				new target = FindRandomPlayer(false, NULL_VECTOR, 0.0, HS_RetargetMode[saboteur] == HW_RETARGET_ANYONE);
				if (IsValidEntity(target))
				{
					static Float:startPos[3];
					GetEntPropVector(sentry, Prop_Data, "m_vecOrigin", startPos);
					static Float:endPos[3];
					GetEntPropVector(target, Prop_Data, "m_vecOrigin", endPos);
					GetRayAngles(startPos, endPos, Sentry_CurrentAngle[sentryIdx]);
				}
			}

			Sentry_NextRetargetAt[sentryIdx] += HS_RetargetInterval[saboteur];
		}

		// force the angle now (figured this out myself :D )
		new angleOffsetB = FindSendPropInfo("CObjectSentrygun", "m_iAmmoShells") - 16;
		new angleOffsetA = angleOffsetB - 12;
		SetEntDataVector(sentry, angleOffsetA, Sentry_CurrentAngle[sentryIdx]);
		SetEntDataVector(sentry, angleOffsetB, Sentry_CurrentAngle[sentryIdx]);

		// force firing bullets if applicable
		if (curTime >= Sentry_NextBulletAt[sentryIdx])
		{
			// credit to FlaminSarge
			// alas, it only works with wrangled guns.
			//new initialOffset = FindSendPropInfo("CObjectSentrygun", "m_hEnemy");
			//new hitscanOffset = initialOffset + 4;
			//SetEntData(sentry, hitscanOffset, 1, 1, true);

			Sentry_NextBulletAt[sentryIdx] += HS_BulletInterval[saboteur];
		}

		// force firing rockets if applicable
		if (curTime >= Sentry_NextRocketAt[sentryIdx])
		{
			// credit to FlaminSarge
			// alas, it only works with wrangled guns.
			//new initialOffset = FindSendPropInfo("CObjectSentrygun", "m_hEnemy");
			//new rocketOffset = initialOffset + 5;
			//SetEntData(sentry, rocketOffset, 1, 1, true);
			
			// so instead, we'll have it fire generated rockets that belong to the sentry's owner.
			HS_CreateRocket(engie, sentry, Sentry_CurrentAngle[sentryIdx]);

			Sentry_NextRocketAt[sentryIdx] += HS_RocketInterval[saboteur];
		}
	}
}

/**
 * Rocket Barrage
 */
public RB_StartChargedShot(clientIdx)
{
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return;

	// hold user and set time for charged shot fire
	RB_FireNextRocketAt[clientIdx] = FAR_FUTURE;
	RB_FireChargedShotAt[clientIdx] = GetEngineTime() + RB_ChargedShotDuration[clientIdx];
	if (RB_Flags[clientIdx] & RB_FLAG_IMMOBILE_CHARGING)
		SetEntityMoveType(clientIdx, MOVETYPE_NONE);
		
	// change the player's weapon to the charged shot version
	RB_WeaponSwap(clientIdx, true);
		
	// play the charging sound
	if (strlen(RB_ChargingSound) > 3)
		PseudoAmbientSound(clientIdx, RB_ChargingSound, 2);
		
	// pull in the particle effect that denotes charging
	static String:particleName[MAX_EFFECT_NAME_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RB_STRING, 8, particleName, MAX_EFFECT_NAME_LENGTH);
	static String:attachment[MAX_ATTACHMENT_NAME_LENGTH];
	RB_GetEnergyAttachment(clientIdx, attachment);
	
	// attach!
	new effect = -1;
	if (!IsEmptyString(attachment))
	{
		effect = AttachParticleToAttachment(clientIdx, particleName, attachment);
	}
	else
	{
		if (PRINT_DEBUG_INFO)
			PrintToServer("[sarysamods6] Particle name provided for charged shot but no attachment point specified. Defaulting to 80HU above origin.");

		effect = AttachParticle(clientIdx, particleName, 80.0);
	}

	if (IsValidEntity(effect))
		CreateTimer(RB_ChargedShotDuration[clientIdx], RemoveEntity, EntIndexToEntRef(effect), TIMER_FLAG_NO_MAPCHANGE);
}

public RB_QueueEndRage(clientIdx, Float:curTime)
{
	RB_UntransformAt[clientIdx] = curTime + RB_UntransformDelay[clientIdx];
	RB_FireNextRocketAt[clientIdx] = FAR_FUTURE;
	RB_FireChargedShotAt[clientIdx] = FAR_FUTURE;
	SetEntityMoveType(clientIdx, MOVETYPE_WALK);
	TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, Float:{0.0,0.0,0.0});
}

public RB_EndRage(clientIdx, bool:rageStarting)
{
	if (!RB_IsUsing[clientIdx])
		return;
		
	if (rageStarting && PRINT_DEBUG_INFO)
		PrintToServer("[sarysamods6] Ragespam handled for rocket barrage for client %d. Interrupted previous rage.", clientIdx);

	if (IsLivingPlayer(clientIdx))
	{
		// let them walk again
		SetEntityMoveType(clientIdx, MOVETYPE_WALK);
		
		// change their model
		if (!rageStarting)
			RB_SwapModel(clientIdx, false);
	}
	
	// delete particle entities if not a ragespam condition
	if (!rageStarting)
	{
		for (new i = 0; i < RB_MAX_ATTACHMENT_POINTS; i++)
			RemoveEntity(INVALID_HANDLE, RB_AttachmentEntRef[clientIdx][i]);
		RemoveEntity(INVALID_HANDLE, RB_ChargedAttachmentEntRef[clientIdx]);
	}
	
	RB_FireNextRocketAt[clientIdx] = FAR_FUTURE;
	RB_FireChargedShotAt[clientIdx] = FAR_FUTURE;
	RB_IsUsing[clientIdx] = false;
}

public RB_SwapModel(clientIdx, bool:rageStarting)
{
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return;

	// get model name based on if rage is starting or ending
	static String:modelName[MAX_MODEL_FILE_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RB_STRING, rageStarting ? 10 : 9, modelName, MAX_MODEL_FILE_LENGTH);
	
	// change model
	SetVariantString(modelName);
	AcceptEntityInput(clientIdx, "SetCustomModel");
	SetEntProp(clientIdx, Prop_Send, "m_bUseClassAnimations", 1);
	
	// play the sound
	static String:bestSound[MAX_SOUND_FILE_LENGTH];
	bestSound = rageStarting ? RB_ToWeaponsSound : RB_ToNormalSound;
	PseudoAmbientSound(clientIdx, bestSound, 2);
	
	// do the particle effect
	static String:bestParticle[MAX_EFFECT_NAME_LENGTH];
	bestParticle = rageStarting ? RB_ToWeaponsEffect : RB_ToNormalEffect;
	if (!IsEmptyString(bestParticle))
	{
		static Float:bossPos[3];
		GetEntPropVector(clientIdx, Prop_Data, "m_vecOrigin", bossPos);
		bossPos[2] += 41.5;
		ParticleEffectAt(bossPos, bestParticle, 1.0);
	}
}

public RB_WeaponSwap(clientIdx, bool:chargedShot)
{
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
	{
		PrintToServer("[sarysamods6] WARNING: Somehow boss is invalid for client %d?! Can't swap weapon.", clientIdx);
		return;
	}

	// attributes first
	static String:weaponAttributes[MAX_WEAPON_ARG_LENGTH];
	static String:attributesBase[MAX_WEAPON_ARG_LENGTH];
	static String:attributesAppend[MAX_WEAPON_ARG_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RB_STRING, 15, attributesBase, MAX_WEAPON_ARG_LENGTH);
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RB_STRING, chargedShot ? 18 : 17, attributesAppend, MAX_WEAPON_ARG_LENGTH);
	if (strlen(attributesAppend) > 4) // one attribute pair is minimum 5 characters
		Format(weaponAttributes, MAX_WEAPON_ARG_LENGTH, "%s ; %s", attributesBase, attributesAppend);
	else
		weaponAttributes = attributesBase;
	
	// weapon name, index, and visibility
	static String:weaponName[MAX_WEAPON_NAME_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RB_STRING, 13, weaponName, MAX_WEAPON_NAME_LENGTH);
	new weaponIndex = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RB_STRING, 14);
	new weaponVisibility = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RB_STRING, 16);
	
	// switch weapon, ah it's good to see the old stock get use again
	SwitchWeapon(clientIdx, weaponName, weaponIndex, weaponAttributes, weaponVisibility);
}

public RB_GetEnergyAttachment(clientIdx, String:attachment[MAX_ATTACHMENT_NAME_LENGTH])
{
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return;

	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RB_STRING, 6, attachment, MAX_ATTACHMENT_NAME_LENGTH);
}

// based on asherkin and voogru's code, though this is almost exactly like the code used for Snowdrop's rockets
// luckily energy ball and sentry rocket derive from rocket so they should be easy
public RB_CreateRocket(clientIdx, Float:untweakedDamage, Float:untweakedSpeed, rocketType, spawnLocationEntity)
{
	// create our rocket. no matter what, it's going to spawn, even if it ends up being out of map
	new Float:speed = untweakedSpeed;
	new Float:damage = fixDamageForFF2(untweakedDamage);
	new String:classname[MAX_ENTITY_CLASSNAME_LENGTH] = "CTFProjectile_Rocket";
	new String:entname[MAX_ENTITY_CLASSNAME_LENGTH] = "tf_projectile_rocket";
	if (rocketType == ROCKET_TYPE_SENTRY)
	{
		classname = "CTFProjectile_SentryRocket";
		entname = "tf_projectile_sentryrocket";
	}
	else if (rocketType == ROCKET_TYPE_ENERGY)
	{
		classname = "CTFProjectile_EnergyBall";
		entname = "tf_projectile_energy_ball";
	}
	
	new rocket = CreateEntityByName(entname);
	if (!IsValidEntity(rocket))
	{
		PrintToServer("[sarysamods6] Error: Invalid entity %s. Won't spawn rocket. This is sarysa's fault.", entname);
		return;
	}
	
	// determine spawn position
	static Float:spawnPosition[3];
	if (IsValidEntity(spawnLocationEntity)) // by default, spawn on the attachment point
	{
		//GetEntPropVector(spawnLocationEntity, Prop_Send, "m_vecOrigin", spawnPosition); // nope
		//GetEntDataVector(spawnLocationEntity, FindSendPropOffs("CParticleSystem", "m_vecOrigin") - 136, spawnPosition); // literal offset: 0x290 as of 2014-11-20
		GetEntPropVector(spawnLocationEntity, Prop_Data, "m_vecAbsOrigin", spawnPosition);
	}
	else // but if that fails, spawn on the player origin and offset the Z
	{
		GetEntPropVector(clientIdx, Prop_Data, "m_vecOrigin", spawnPosition);
		spawnPosition[2] += 70.0;
	}
		
	// get angles for rocket
	// TODO: smart targeting?
	//trace = TR_TraceRayFilterEx(traceEndPosition, traceAngles, (CONTENTS_SOLID | CONTENTS_WINDOW | CONTENTS_GRATE), RayType_Infinite, TraceWallsOnly);
	//TR_GetEndPosition(spawnPosition, trace);
	//CloseHandle(trace);
	static Float:spawnAngles[3];
	if (RB_Flags[clientIdx] & RB_FLAG_SMART_TARGETING)
	{
		// angles lead to whatever the player's looking at if we do smart targeting
		static Float:eyePos[3];
		static Float:eyeAngles[3];
		GetClientEyePosition(clientIdx, eyePos);
		GetClientEyeAngles(clientIdx, eyeAngles);
		
		// trace
		static Float:endPos[3];
		new Handle:trace = TR_TraceRayFilterEx(eyePos, eyeAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRedPlayersAndBuildings);
		TR_GetEndPosition(endPos, trace);
		CloseHandle(trace);
		
		// get the angle the line from the rocket spawn to the object we care about. that's our spawn angle.
		GetRayAngles(spawnPosition, endPos, spawnAngles);
	}
	else
	{
		// angles are the user's eye angles if we do dumb targeting
		GetClientEyeAngles(clientIdx, spawnAngles);
	}
	
	// determine velocity
	static Float:spawnVelocity[3];
	GetAngleVectors(spawnAngles, spawnVelocity, NULL_VECTOR, NULL_VECTOR);
	spawnVelocity[0] *= speed;
	spawnVelocity[1] *= speed;
	spawnVelocity[2] *= speed;
	
	// deploy!
	TeleportEntity(rocket, spawnPosition, spawnAngles, spawnVelocity);
	if (rocketType != ROCKET_TYPE_ENERGY) // energy ball does not have this prop, oddly enough
		SetEntProp(rocket, Prop_Send, "m_bCritical", false); // no random crits
	if (rocketType == ROCKET_TYPE_ENERGY)
		SetEntProp(rocket, Prop_Send, "m_bChargedShot", true); // charged shot
	SetEntDataFloat(rocket, FindSendPropOffs(classname, "m_iDeflected") + 4, damage, true); // credit to voogru
	SetEntProp(rocket, Prop_Send, "m_nSkin", 1); // set skin to blue team's
	SetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity", clientIdx);
	SetVariantInt(BossTeam);
	AcceptEntityInput(rocket, "TeamNum", -1, -1, 0);
	SetVariantInt(BossTeam);
	AcceptEntityInput(rocket, "SetTeam", -1, -1, 0); 
	DispatchSpawn(rocket);
	
	// play the sound
	static String:bestSound[MAX_SOUND_FILE_LENGTH];
	bestSound = rocketType == ROCKET_TYPE_ENERGY ? RB_ChargedShotSound : RB_RocketFireSound;
	if (strlen(bestSound) > 3)
	{
		EmitAmbientSound(bestSound, spawnPosition, SOUND_FROM_WORLD);
		EmitAmbientSound(bestSound, spawnPosition, SOUND_FROM_WORLD);
	}
	
	// to get stats from the user's melee weapon
	SetEntPropEnt(rocket, Prop_Send, "m_hOriginalLauncher", GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Melee));
	SetEntPropEnt(rocket, Prop_Send, "m_hLauncher", GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Melee));
}

public RB_Tick(clientIdx, Float:curTime)
{
	if (curTime >= RB_FireNextRocketAt[clientIdx])
	{
		if (RB_RocketsRemaining[clientIdx] == 0)
		{
			if ((RB_Flags[clientIdx] & RB_FLAG_CHARGED_SHOT) != 0)
				RB_StartChargedShot(clientIdx);
			else
				RB_QueueEndRage(clientIdx, curTime);
		}
		else
		{
			new spawnLocationEntity = EntRefToEntIndex(RB_AttachmentEntRef[clientIdx][RB_CurrentAttachmentIdx[clientIdx]]);
			new rocketType = (RB_Flags[clientIdx] & RB_FLAG_USE_SENTRYROCKET) != 0 ? ROCKET_TYPE_SENTRY : ROCKET_TYPE_NORMAL;
			RB_CreateRocket(clientIdx, RB_RocketDamage[clientIdx], RB_RocketSpeed[clientIdx], rocketType, spawnLocationEntity);
		
			RB_CurrentAttachmentIdx[clientIdx] = (RB_CurrentAttachmentIdx[clientIdx] + 1) % RB_TotalAttachments[clientIdx];
			RB_RocketsRemaining[clientIdx]--;
			RB_FireNextRocketAt[clientIdx] += RB_FireInterval[clientIdx];
		}
	}
	
	if (curTime >= RB_FireChargedShotAt[clientIdx])
	{
		// fire the rocket
		new spawnLocationEntity = EntRefToEntIndex(RB_ChargedAttachmentEntRef[clientIdx]);
		RB_CreateRocket(clientIdx, RB_ChargedDamage[clientIdx], RB_ChargedSpeed[clientIdx], ROCKET_TYPE_ENERGY, spawnLocationEntity);
		
		// queue end of rage
		RB_QueueEndRage(clientIdx, curTime);
	}

	if (curTime >= RB_UntransformAt[clientIdx])
	{
		// simply end the rage
		RB_EndRage(clientIdx, false);
	}
}

public Rage_RocketBarrage(const String:ability_name[], bossIdx)
{
	// need the client index
	new clientIdx = GetClientOfUserId(FF2_GetBossUserId(bossIdx));

	// freak situation. should only occur in testing.
	if (!RB_ActiveThisRound)
	{
		PrintToServer("[sarysamods6] ERROR: Somehow the hale raged in the first 0.3 seconds of the match. Rocket barrage will not execute. Client: %d", clientIdx);
		return;
	}

	// first, end the rage in case of ragespam.
	new bool:ragespam = RB_IsUsing[clientIdx];
	RB_EndRage(clientIdx, true);
	
	// change their model and create attachment entities
	if (!ragespam)
	{
		RB_SwapModel(clientIdx, true);
		
		// create attachment entities
		static String:rocketAttachments[RB_ROCKET_POINTS_STR_LENGTH];
		FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, 2, rocketAttachments, RB_ROCKET_POINTS_STR_LENGTH);

		RB_TotalAttachments[clientIdx] = 0;
		static String:splitAttachments[RB_MAX_ATTACHMENT_POINTS][MAX_ATTACHMENT_NAME_LENGTH];
		new strCount = ExplodeString(rocketAttachments, ";", splitAttachments, RB_MAX_ATTACHMENT_POINTS, MAX_ATTACHMENT_NAME_LENGTH);
		for (new i = 0; i < strCount && i < RB_MAX_ATTACHMENT_POINTS; i++)
		{
			if (!IsEmptyString(splitAttachments[i]))
			{
				new effect = AttachParticleToAttachment(clientIdx, RB_LocationMarkerEffect, splitAttachments[i]);
				if (IsValidEntity(effect))
				{
					RB_AttachmentEntRef[clientIdx][i] = EntIndexToEntRef(effect);
					RB_TotalAttachments[clientIdx]++;
				}
				else
					RB_AttachmentEntRef[clientIdx][RB_TotalAttachments[clientIdx]] = 0;
			}
		}
		
		// make sure total attachments isn't 1
		if (RB_TotalAttachments[clientIdx] == 0)
		{
			RB_TotalAttachments[clientIdx] = 1;
			if (PRINT_DEBUG_INFO)
				PrintToServer("[sarysamods6] WARNING: No attachment points specified for ordinary rockets with rocket barrage. Will behave oddly.");
		}

		static String:attachment[MAX_ATTACHMENT_NAME_LENGTH];
		RB_GetEnergyAttachment(clientIdx, attachment);
		if (!IsEmptyString(attachment))
		{
			new effect = AttachParticleToAttachment(clientIdx, RB_LocationMarkerEffect, attachment);
			if (IsValidEntity(effect))
				RB_ChargedAttachmentEntRef[clientIdx] = EntIndexToEntRef(effect);
			else
				RB_ChargedAttachmentEntRef[clientIdx] = 0;
		}
		else if (PRINT_DEBUG_INFO)
			PrintToServer("[sarysamods6] WARNING: No attachment point specified for charged rocket with rocket barrage. Will behave oddly.");
	}
	
	// change the player's weapon to the normal shot version
	RB_WeaponSwap(clientIdx, false);
	
	// how many rockets are we firing?
	RB_RocketsRemaining[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, ability_name, 1);
	
	// signal rage start and set the first rocket to go off now. (probably next tick)
	RB_IsUsing[clientIdx] = true;
	RB_UntransformAt[clientIdx] = FAR_FUTURE;
	RB_CurrentAttachmentIdx[clientIdx] = 0;
	RB_FireNextRocketAt[clientIdx] = GetEngineTime() + 0.05;
}

/**
 * Step Sounds
 */ 
public Action:HookStepSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &clientIdx, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsLivingPlayer(clientIdx) || !SS_CanUse[clientIdx])
		return Plugin_Continue;
		
	// here we give poorly considered std c methods modern names, so StrContains can actually be numeric and not boolean!
	// but it's just like learning them again, since yanno, a modern sounding StrContains would be...a boolean...but it's not...
	// yeah.
	if (StrContains(sample, "footstep") != -1 && strcmp(sample, SS_Sound[clientIdx]) != 0)
	{
		SS_IsQueued[clientIdx] = true;
		return Plugin_Handled; // nothing to change to. cancel the sound
	}
	
	return Plugin_Continue;
}

public PlayQueuedSound(clientIdx)
{
	if (SS_IsQueued[clientIdx])
	{
		if (strlen(SS_Sound[clientIdx]) > 3)
			PseudoAmbientSound(clientIdx, SS_Sound[clientIdx], SS_RepeatCount[clientIdx], SS_Radius[clientIdx], SS_IgnorePlayer[clientIdx], SS_IgnoreDead[clientIdx], SS_Volume[clientIdx]);
		SS_IsQueued[clientIdx] = false;
	}
}

/**
 * Water Weakness
 */
public WW_Tick(clientIdx, Float:curTime)
{
	if (GetEntityFlags(clientIdx) & (FL_SWIM | FL_INWATER))
	{
		// needed for overlay removal
		WW_WasInWater[clientIdx] = true;

		// if we can hurt the player, hurt them.
		if (curTime >= WW_CanTakeDamageAt[clientIdx])
		{
			if (WW_Damage[clientIdx] > 0.0)
			{
				new attackingMerc = FindRandomPlayer(false);

				if (IsLivingPlayer(attackingMerc))
					SemiHookedDamage(clientIdx, attackingMerc, attackingMerc, WW_Damage[clientIdx], DMG_GENERIC | DMG_PREVENT_PHYSICS_FORCE);
			}

			WW_CanTakeDamageAt[clientIdx] = curTime + WW_DamageInterval[clientIdx];
		}

		// if it's time to update the overlay, update it.
		if (curTime >= WW_NextOverlayUpdateAt[clientIdx])
		{
			if (strlen(WW_OverlayMaterial) > 3)
			{
				new flags = GetCommandFlags("r_screenoverlay");
				SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
				if (WW_FrameCount[clientIdx] > 1)
					ClientCommand(clientIdx, "r_screenoverlay \"%s%d.vmt\"", WW_OverlayMaterial, WW_CurrentOverlayFrame[clientIdx] + 1);
				else
					ClientCommand(clientIdx, "r_screenoverlay \"%s.vmt\"", WW_OverlayMaterial);
				SetCommandFlags("r_screenoverlay", flags);

				if (WW_FrameCount[clientIdx] > 1)
					WW_CurrentOverlayFrame[clientIdx] = (WW_CurrentOverlayFrame[clientIdx] + 1) % WW_FrameCount[clientIdx];
			}

			WW_NextOverlayUpdateAt[clientIdx] = curTime + WW_OverlayInterval[clientIdx];
		}

		// if it's safe to play the sound file, play it.
		if (curTime >= WW_NextSoundAt[clientIdx])
		{
			if (strlen(WW_SoundFile) > 3)
				EmitSoundToAll(WW_SoundFile);

			WW_NextSoundAt[clientIdx] = curTime + WW_SoundInterval[clientIdx];
		}
	}
	else if (WW_WasInWater[clientIdx])
	{
		// remove the overlay
		new flags = GetCommandFlags("r_screenoverlay");
		SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
		ClientCommand(clientIdx, "r_screenoverlay \"\"");
		SetCommandFlags("r_screenoverlay", flags);

		WW_WasInWater[clientIdx] = false;
	}
}

/**
 * Simple Passives
 */
public SP_RemoveDebuffs(clientIdx)
{
	if (SP_SoftStunImmune[clientIdx] && TF2_IsPlayerInCondition(clientIdx, TFCond_Dazed))
		if (GetEntProp(clientIdx, Prop_Send, "m_iStunFlags") & TF_STUNFLAG_SLOWDOWN)
			TF2_RemoveCondition(clientIdx, TFCond_Dazed);
	
	if (SP_HardStunImmune[clientIdx] && TF2_IsPlayerInCondition(clientIdx, TFCond_Dazed))
		if (GetEntProp(clientIdx, Prop_Send, "m_iStunFlags") & TF_STUNFLAG_BONKSTUCK)
			TF2_RemoveCondition(clientIdx, TFCond_Dazed);
			
	if (SP_Fireproof[clientIdx] && TF2_IsPlayerInCondition(clientIdx, TFCond_OnFire))
		TF2_RemoveCondition(clientIdx, TFCond_OnFire);
	
	if (SP_Bleedproof[clientIdx] && TF2_IsPlayerInCondition(clientIdx, TFCond_Bleeding))
		TF2_RemoveCondition(clientIdx, TFCond_Bleeding);
	
	if (SP_Frictionless[clientIdx])
	{
		if (TF2_IsPlayerInCondition(clientIdx, TFCond_Jarated))
			TF2_RemoveCondition(clientIdx, TFCond_Jarated);
		if (TF2_IsPlayerInCondition(clientIdx, TFCond_Milked))
			TF2_RemoveCondition(clientIdx, TFCond_Milked);
			
		// unfortunately, seems to be no way to detect a wet player. boo.
	}
	
	if (SP_Untraceable[clientIdx] && GetEntProp(clientIdx, Prop_Send, "m_bGlowEnabled"))
		SetEntProp(clientIdx, Prop_Send, "m_bGlowEnabled", 0);
}

/**
 * Merc Conditions
 */
public MC_FixWaterOverlay(target, bool:remove)
{
	new flags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
	if (remove)
		ClientCommand(target, "r_screenoverlay \"\"");
	else if (MC_CleanWaterOverlay)
		ClientCommand(target, "r_screenoverlay \"effects/water_warp\"");
	SetCommandFlags("r_screenoverlay", flags);
}

public MC_ForceFirstPerson(target)
{
	if (GetEntProp(target, Prop_Send, "m_nForceTauntCam") == 1)
		return;
		
	new flags = GetCommandFlags("firstperson");
	SetCommandFlags("firstperson", flags & ~FCVAR_CHEAT);
	ClientCommand(target, "firstperson");
	SetCommandFlags("firstperson", flags);
}
 
public MC_AddConditionsToTarget(clientIdx, target)
{
	if (GetClientTeam(target) == MercTeam)
	{
		for (new i = 0; i < MC_MAX_CONDITIONS; i++)
		{
			if (MC_MercConditions[clientIdx][i] == -1)
				break;

			if (!TF2_IsPlayerInCondition(target, TFCond:MC_MercConditions[clientIdx][i]))
			{
				TF2_AddCondition(target, TFCond:MC_MercConditions[clientIdx][i], -1.0);
				if (MC_FirstPersonFix[clientIdx])
					MC_ForceFirstPerson(target);
			}
		}
	}
	else
	{
		for (new i = 0; i < MC_MAX_CONDITIONS; i++)
		{
			if (MC_BossConditions[clientIdx][i] == -1)
				break;

			if (!TF2_IsPlayerInCondition(target, TFCond:MC_BossConditions[clientIdx][i]))
			{
				TF2_AddCondition(target, TFCond:MC_BossConditions[clientIdx][i], -1.0);
				if (MC_FirstPersonFix[clientIdx])
					MC_ForceFirstPerson(target);
					
				if (MC_BossConditions[clientIdx][i] == COND_JARATE_WATER)
				{
					// 2015-10-03, fix a bug for Pip Squeak
					SnapTheRope(clientIdx);
				}
			}
		}
	}
}
 
public MC_RemoveConditionsFromTarget(clientIdx, target)
{
	if (GetClientTeam(target) == MercTeam)
	{
		for (new i = 0; i < MC_MAX_CONDITIONS; i++)
		{
			if (MC_MercConditions[clientIdx][i] == -1)
				break;

			if (TF2_IsPlayerInCondition(target, TFCond:MC_MercConditions[clientIdx][i]))
			{
				TF2_RemoveCondition(target, TFCond:MC_MercConditions[clientIdx][i]);
				if (MC_MercConditions[clientIdx][i] == COND_JARATE_WATER && MC_ClearJarate[clientIdx])
					MC_ClearJarateNextTick[target] = true;
				if (MC_MercConditions[clientIdx][i] == COND_JARATE_WATER)
					MC_FixWaterOverlay(target, true);
			}
		}
	}
	else
	{
		for (new i = 0; i < MC_MAX_CONDITIONS; i++)
		{
			if (MC_BossConditions[clientIdx][i] == -1)
				break;

			if (TF2_IsPlayerInCondition(target, TFCond:MC_BossConditions[clientIdx][i]))
			{
				TF2_RemoveCondition(target, TFCond:MC_BossConditions[clientIdx][i]);
				if (MC_BossConditions[clientIdx][i] == COND_JARATE_WATER && MC_ClearJarate[clientIdx])
					MC_ClearJarateNextTick[target] = true;
				if (MC_BossConditions[clientIdx][i] == COND_JARATE_WATER)
				{
					MC_FixWaterOverlay(target, true);
				}
			}
		}
	}
}

public MC_EndRage(clientIdx)
{
	for (new target = 1; target < MAX_PLAYERS; target++)
	{
		if (!IsLivingPlayer(target))
			continue;
			
		MC_RemoveConditionsFromTarget(clientIdx, target);
	}

	MC_RageEndsAt[clientIdx] = 0.0;
}

public MC_Tick(clientIdx, Float:curTime)
{
	// special actions that much occur next tick, even if rage is finished
	for (new target = 1; target < MAX_PLAYERS; target++)
	{
		if (!IsLivingPlayer(target))
			continue;
			
		if (MC_ClearJarateNextTick[target])
		{
			if (TF2_IsPlayerInCondition(target, TFCond_Jarated))
				TF2_RemoveCondition(target, TFCond_Jarated);
			MC_ClearJarateNextTick[target] = false;
		}
	}
	
	// don't execute anything else if rage is inactive.
	if (MC_RageEndsAt[clientIdx] == 0.0)
		return;
		
	// end the rage?
	if (curTime >= MC_RageEndsAt[clientIdx])
	{
		MC_EndRage(clientIdx);
		return;
	}
	
	// don't want to do this mildly expensive check every tick
	if (curTime < MC_NextRadiusCheckAt[clientIdx])
		return;

	new Float:bossPos[3];
	GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", bossPos);
	new Float:maxDist = MC_Radius[clientIdx] * MC_Radius[clientIdx];

	for (new target = 1; target < MAX_PLAYERS; target++)
	{
		if (!IsLivingPlayer(target))
			continue;
			
		static Float:playerPos[3];
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", playerPos);
		if (GetVectorDistance(bossPos, playerPos, true) <= maxDist)
		{
			// add conditions
			MC_AddConditionsToTarget(clientIdx, target);
		}
		else
		{
			// remove conditions
			MC_RemoveConditionsFromTarget(clientIdx, target);
		}
	}
	
	// overlay fix
	if (curTime >= MC_NextOverlayFixAt)
	{
		for (new target = 1; target < MAX_PLAYERS; target++)
		{
			if (IsLivingPlayer(target) && TF2_IsPlayerInCondition(target, TFCond:COND_JARATE_WATER))
				MC_FixWaterOverlay(target, false);
		}
		
		MC_NextOverlayFixAt = curTime + MC_OVERLAY_FIX_INTERVAL;
	}
}

public Rage_MercConditions(const String:ability_name[], bossIdx)
{
	// need the client index
	new clientIdx = GetClientOfUserId(FF2_GetBossUserId(bossIdx));
	
	MC_RageEndsAt[clientIdx] = GetEngineTime() + FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 1);
	MC_NextRadiusCheckAt[clientIdx] = GetEngineTime();
	MC_NextOverlayFixAt = GetEngineTime();
}

/**
 * Torpedo Attack
 */
public bool:TA_WaterConditionPassed(clientIdx)
{
	if (!TA_Cond86Required[clientIdx])
		return true;
		
	return TF2_IsPlayerInCondition(clientIdx, TFCond:COND_JARATE_WATER) || GetEntProp(clientIdx, Prop_Send, "m_nWaterLevel") > 0;//((GetEntityFlags(clientIdx) & (FL_SWIM | FL_INWATER)) != 0);
}
 
public TA_Tick(clientIdx, Float:curTime, buttons)
{
	new bool:desiredKeyDown = TA_IsAltFireActivated[clientIdx] ? ((buttons & IN_ATTACK2) != 0) : ((buttons & IN_RELOAD) != 0);
	
	// ensure charging state is still valid, or set it up if the player triggered it.
	if (TA_IsCharging[clientIdx])
	{
		// time to end the charge?
		if (curTime >= TA_ChargingUntil[clientIdx] || !TA_WaterConditionPassed(clientIdx))
		{
			// fix the user's roll
			RemoveEntity(INVALID_HANDLE, TA_BarrelRollEntRef[clientIdx]);
			TA_BarrelRollEntRef[clientIdx] = 0;
			SetClientViewEntity(clientIdx, clientIdx);
			TA_SpinAngle[clientIdx][2] = 0.0;
			TeleportEntity(clientIdx, NULL_VECTOR, TA_SpinAngle[clientIdx], NULL_VECTOR);
			
			// otherwise disable the charge and remove any charging particle
			TA_IsCharging[clientIdx] = false;
			if (TA_ParticleEntRef[clientIdx] != 0)
				RemoveEntity(INVALID_HANDLE, TA_ParticleEntRef[clientIdx]);
			TA_ParticleEntRef[clientIdx] = 0;
			
			// remove megaheal
			if (TA_ApplyMegaHeal[clientIdx])
				TF2_RemoveCondition(clientIdx, TFCond_MegaHeal);
		}
	}
	else if (TA_UsesRemaining[clientIdx] > 0 && TA_WaterConditionPassed(clientIdx))
	{
		// eligible for charging. is the key down?
		if (desiredKeyDown && !TA_DesiredKeyDown[clientIdx])
		{
			// it's all we need. get the ball rolling
			TA_UsesRemaining[clientIdx]--;
			TA_IsCharging[clientIdx] = true;
			GetClientEyeAngles(clientIdx, TA_SpinAngle[clientIdx]);
			TA_ChargingUntil[clientIdx] = curTime + TA_ChargeDuration[clientIdx];
			for (new i = 1; i < MAX_PLAYERS; i++)
				TA_CanBeDamagedAt[clientIdx][i] = curTime;
			TA_RefreshChargeAt[clientIdx] = curTime;
			if (!IsEmptyString(TA_Particle))
			{
				new particle = AttachParticle(clientIdx, TA_Particle);
				if (IsValidEntity(particle))
					TA_ParticleEntRef[clientIdx] = EntIndexToEntRef(particle);
			}
			
			// add megaheal, unless otherwise specified
			if (TA_ApplyMegaHeal[clientIdx])
				TF2_AddCondition(clientIdx, TFCond_MegaHeal, -1.0);
				
			// play sound
			if (strlen(TA_Sound) > 3)
				PseudoAmbientSound(clientIdx, TA_Sound);
				
			// create the barrel roll entity, but only if the user will roll
			// because there's a bug that causes it to crap out the music
			if (TA_TimeForOneSpin[clientIdx] > 0.0)
			{
				new Float:spawnPos[3];
				new Float:spawnAngles[3];
				GetClientEyePosition(clientIdx, spawnPos);
				GetClientEyeAngles(clientIdx, spawnAngles);
				new barrelRollProp = CreateEntityByName("prop_physics_override");
				if (IsValidEntity(barrelRollProp))
				{
					// the actual spawning process
					SetEntityModel(barrelRollProp, TA_BarrelRollModel);
					TeleportEntity(barrelRollProp, spawnPos, spawnAngles, NULL_VECTOR);
					DispatchSpawn(barrelRollProp);
					SetEntProp(barrelRollProp, Prop_Data, "m_takedamage", 0);

					// no collision
					SetEntProp(barrelRollProp, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_NONE);
					SetEntProp(barrelRollProp, Prop_Send, "m_usSolidFlags", 4);
					SetEntProp(barrelRollProp, Prop_Send, "m_nSolidType", 0);

					// attach it to the user
					DispatchSpawn(barrelRollProp);
					SetVariantString("!activator");
					AcceptEntityInput(barrelRollProp, "SetParent", clientIdx);
					SetEntPropEnt(barrelRollProp, Prop_Send, "m_hOwnerEntity", clientIdx);

					// set user's view to this prop
					SetClientViewEntity(clientIdx, barrelRollProp);
					TA_BarrelRollEntRef[clientIdx] = EntIndexToEntRef(barrelRollProp);
				}
			}
		}
	}
	
	// various checks, velocity push, damage tick
	if (TA_IsCharging[clientIdx])
	{
		// refresh the velocity push
		static Float:velocity[3];
		new bool:velocityUpdated = false;
		if (curTime >= TA_RefreshChargeAt[clientIdx])
		{
			velocityUpdated = true;
			GetAngleVectors(TA_SpinAngle[clientIdx], velocity, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(velocity, TA_ChargeVelocity[clientIdx]);
			
			TA_RefreshChargeAt[clientIdx] += TA_CHARGE_REFRESH_INTERVAL;
		}
		
		// update the user's roll (and velocity, if applicable)
		if (TA_TimeForOneSpin[clientIdx] > 0.0)
		{
			new Float:chargeTime = TA_ChargeDuration[clientIdx] - (TA_ChargingUntil[clientIdx] - curTime);
			TA_SpinAngle[clientIdx][2] = chargeTime / TA_TimeForOneSpin[clientIdx];
			for (new sanity = 0; sanity < 30; sanity++)
			{
				if (TA_SpinAngle[clientIdx][2] < 1.0)
					break;
				
				TA_SpinAngle[clientIdx][2] -= 1.0;
			}
			TA_SpinAngle[clientIdx][2] *= 360.0;
			//PrintToServer("chargeTime=%f   spinTime=%f   roll=%f", chargeTime, TA_TimeForOneSpin[clientIdx], TA_SpinAngle[clientIdx][2]);
		}
		TeleportEntity(clientIdx, NULL_VECTOR, TA_BarrelRollEntRef[clientIdx] != 0 ? NULL_VECTOR : TA_SpinAngle[clientIdx], velocityUpdated ? velocity : NULL_VECTOR);
		
		// update the angles of the barrel roll prop
		new barrelRollProp = EntRefToEntIndex(TA_BarrelRollEntRef[clientIdx]);
		if (IsValidEntity(barrelRollProp))
		{
			static Float:brpAngles[3];
			GetEntPropVector(barrelRollProp, Prop_Data, "m_angRotation", brpAngles);
			brpAngles[2] = TA_SpinAngle[clientIdx][2];
			TeleportEntity(barrelRollProp, NULL_VECTOR, brpAngles, NULL_VECTOR);
		}
		
		// check the damage/knockback AOE
		static Float:bossPos[3];
		GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", bossPos);
		static Float:victimPos[3];
		new Float:cylinderRadius = fabs(TA_CollisionHull[0][0]) + fabs(TA_CollisionHull[0][1]) + fabs(TA_CollisionHull[1][0]) + fabs(TA_CollisionHull[1][1]);
		cylinderRadius *= 0.25;
		for (new victim = 1; victim < MAX_PLAYERS; victim++)
		{
			if (!IsLivingPlayer(victim) || curTime < TA_CanBeDamagedAt[clientIdx][victim])
				continue;
			else if (victim == clientIdx || GetClientTeam(clientIdx) == GetClientTeam(victim))
				continue;
		
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
			if (CylinderCollision(bossPos, victimPos, cylinderRadius, (bossPos[2] + TA_CollisionHull[0][2]) - 83.0, bossPos[2] + TA_CollisionHull[1][2]))
			{
				// play sound
				if (strlen(TA_HitSound) > 3)
					PseudoAmbientSound(victim, TA_HitSound);
				
				// damage
				if (!TF2_IsPlayerInCondition(victim, TFCond_Ubercharged))
					SDKHooks_TakeDamage(victim, clientIdx, clientIdx, TA_Damage[clientIdx], DMG_GENERIC, -1);
				
				// knockback
				static Float:kbVel[3];
				MakeVectorFromPoints(bossPos, victimPos, kbVel);
				ScaleVector(kbVel, TA_KnockbackIntensity[clientIdx]);
				
				// set immune for a short period
				TA_CanBeDamagedAt[clientIdx][victim] = curTime + TA_DamageInterval[clientIdx];
			}
		}
		
		// damage AOE for buildings
		for (new pass = 0; pass < 3; pass++)
		{
			static String:classname[64];
			if (pass == 0)
				classname = "obj_sentrygun";
			else if (pass == 1)
				classname = "obj_dispenser";
			else if (pass == 2)
				classname = "obj_teleporter";
				
			new building = -1;
			while ((building = FindEntityByClassname(building, classname)) != -1)
			{
				if (GetEntProp(building, Prop_Send, "m_bCarried") || GetEntProp(building, Prop_Send, "m_bPlacing"))
					continue;
					
				GetEntPropVector(building, Prop_Send, "m_vecOrigin", victimPos);
				if (CylinderCollision(bossPos, victimPos, cylinderRadius, (bossPos[2] + TA_CollisionHull[0][2]) - 83.0, bossPos[2] + TA_CollisionHull[1][2]))
					SDKHooks_TakeDamage(building, clientIdx, clientIdx, 9999.0, DMG_GENERIC, -1);
			}
		}
	}
	
	// update the hud, but only show it if charges are available.
	if (curTime >= TA_NextHUDAt[clientIdx])
	{
		if (TA_UsesRemaining[clientIdx] > 0 && TA_WaterConditionPassed(clientIdx))
		{
			SetHudTextParams(-1.0, TA_HUD_POSITION, TA_HUD_REFRESH_INTERVAL + 0.05, 64, 255, 64, 192);
			ShowHudText(clientIdx, -1, TA_HudMessage, TA_UsesRemaining[clientIdx]);
		}

		TA_NextHUDAt[clientIdx] = curTime + TA_HUD_REFRESH_INTERVAL;
	}
	
	TA_DesiredKeyDown[clientIdx] = desiredKeyDown;
}

public Rage_TorpedoAttack(const String:ability_name[], bossIdx)
{
	// need the client index
	new clientIdx = GetClientOfUserId(FF2_GetBossUserId(bossIdx));
	
	// just setting the uses remaining is enough to trigger the rage
	TA_UsesRemaining[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, ability_name, 1);
}

/**
 * DOT Necromancy
 */
public Action:NM_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// exclude dead ringer death
	if ((GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) != 0)
		return Plugin_Continue;
	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsClientInGame(victim) && GetClientTeam(victim) == MercTeam)
	{
		NM_LastDeadPlayer = victim;
		NM_DiedAt[victim] = GetEngineTime();
	}
	
	return Plugin_Continue;
}

public NM_ReviveLast(clientIdx)
{
	if (NM_LastDeadPlayer == -1)
		return NM_FAIL_NO_ONE_OR_LOGGED; // no one died yet
	else if (!IsClientInGame(NM_LastDeadPlayer))
		return NM_FAIL_NO_ONE_OR_LOGGED; // last dead player logged
	else if (GetEngineTime() > NM_DiedAt[NM_LastDeadPlayer] + NM_MaxDeadTime[clientIdx])
		return NM_FAIL_DEAD_TOO_LONG; // player dead too long
	else if (GetClientTeam(NM_LastDeadPlayer) != MercTeam)
		return NM_FAIL_ALREADY_REVIVED; // player already revived
		
	// bring in certain strings for weapon stats and models
	new bossIdx = FF2_GetBossIndex(clientIdx);
	static String:modelName[MAX_MODEL_FILE_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, NM_STRING, 2, modelName, MAX_MODEL_FILE_LENGTH);
	static String:weaponName[MAX_WEAPON_NAME_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, NM_STRING, 4, weaponName, MAX_WEAPON_NAME_LENGTH);
	static String:weaponArgs[MAX_WEAPON_ARG_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, NM_STRING, 6, weaponArgs, MAX_WEAPON_ARG_LENGTH);
	
	// revive the player
	new minion = NM_LastDeadPlayer;
	NM_LastClass[minion] = TF2_GetPlayerClass(minion);
	FF2_SetFF2flags(minion, FF2_GetFF2flags(minion) | FF2FLAG_ALLOWSPAWNINBOSSTEAM);
	ChangeClientTeam(minion, BossTeam);
	TF2_RespawnPlayer(minion);
	TF2_SetPlayerClass(minion, TFClassType:NM_MinionClass[clientIdx]);
	
	// change model
	if (strlen(modelName) > 3)
	{
		SetVariantString(modelName);
		AcceptEntityInput(minion, "SetCustomModel");
		SetEntProp(minion, Prop_Send, "m_bUseClassAnimations", 1);
	}
	
	// strip all weapons and add the desired weapon
	new weapon;
	TF2_RemoveAllWeapons(minion);
	weapon = SpawnWeapon(minion, weaponName, NM_MinionWeaponIdx[clientIdx], 101, 5, weaponArgs);
	if (IsValidEdict(weapon))
	{
		SetEntPropEnt(minion, Prop_Send, "m_hActiveWeapon", weapon);
		if (NM_MinionWeaponVisibility[clientIdx] == 0)
			SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", -1);
	}
	
	// set various clone properties (owner, time to die, model retry time, etc.)
	NM_DespawnAt[minion] = GetEngineTime() + (NM_MinionLifespan[clientIdx] > 0.0 ? NM_MinionLifespan[clientIdx] : FAR_FUTURE);
	NM_MinionBelongsTo[minion] = clientIdx;
	NM_ModelSwapRetryAt[minion] = GetEngineTime() + NM_MODEL_INTERVAL;
	NM_ModelRetries[minion] = 0;
	NM_LastDeadPlayer = -1; // don't revive this player again, i.e. if they suicide
	NM_RevivalAnimationFinishAt[minion] = GetEngineTime() + NM_SpawnAnimationDuration[clientIdx];
	NM_InvincibilityEndsAt[minion] = NM_RevivalAnimationFinishAt[minion] + NM_InvincibilityDuration[clientIdx];
	
	// teleport and heal the clone (animate the hale in)
	TeleportEntity(minion, NM_LastPosition[minion], NULL_VECTOR, NULL_VECTOR);
	SetEntProp(minion, Prop_Data, "m_takedamage", 0);
	TF2_AddCondition(minion, TFCond_Ubercharged, -1.0);
	SetEntProp(minion, Prop_Data, "m_iHealth", RoundFloat(NM_MinionMaxHP[clientIdx]));
	SetEntProp(minion, Prop_Send, "m_iHealth", RoundFloat(NM_MinionMaxHP[clientIdx]));
	
	// display a particle effect
	if (!IsEmptyString(NM_SpawnParticle))
	{
		new Float:particleOrigin[3];
		particleOrigin[0] = NM_LastPosition[minion][0];
		particleOrigin[1] = NM_LastPosition[minion][1];
		particleOrigin[2] = NM_LastPosition[minion][2] + NM_SpawnParticleOffset;
		ParticleEffectAt(particleOrigin, NM_SpawnParticle, 1.0);
	}
	
	// remove wearables
	new entity;
	new owner;
	while((entity=FindEntityByClassname(entity, "tf_wearable"))!=-1)
	{
		if((owner=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==BossTeam)
		{
			TF2_RemoveWearable(owner, entity);
		}
	}

	while((entity=FindEntityByClassname(entity, "tf_wearable_demoshield"))!=-1)
	{
		if((owner=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==BossTeam)
		{
			TF2_RemoveWearable(owner, entity);
		}
	}

	while((entity=FindEntityByClassname(entity, "tf_powerup_bottle"))!=-1)
	{
		if((owner=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==BossTeam)
		{
			TF2_RemoveWearable(owner, entity);
		}
	}
		
	return NM_SUCCESS;
}

public NM_KillMinion(minion)
{
	NM_MinionBelongsTo[minion] = -1;
	new killer = FindRandomPlayer(false);
	if (killer == -1)
		killer = minion;

	SetEntProp(minion, Prop_Data, "m_takedamage", 2);
	if (TF2_IsPlayerInCondition(minion, TFCond_Ubercharged))
		TF2_RemoveCondition(minion, TFCond_Ubercharged);
	SDKHooks_TakeDamage(minion, killer, killer, 9999.0, DMG_GENERIC, -1);
}

public NM_TickBoss(clientIdx, Float:curTime)
{
	// only thing to tick: if dead, despawn all minions.
	if (!IsLivingPlayer(clientIdx))
	{
		for (new minion = 1; minion < MAX_PLAYERS; minion++)
		{
			if (NM_MinionBelongsTo[minion] == clientIdx)
				NM_KillMinion(minion);
		}
	}
	else
	{
		// oh, and the HUD message...since we need one.
		if (curTime >= NM_NextHUDAt[clientIdx])
		{
			SetHudTextParams(-1.0, NM_HUD_POSITION, NM_HUD_REFRESH_INTERVAL + 0.05, 64, 255, 64, 192);
			ShowHudText(clientIdx, -1, NM_HudMessage);

			NM_NextHUDAt[clientIdx] = curTime + NM_HUD_REFRESH_INTERVAL;
		}
	}
}

public NM_TickMinion(minion, Float:curTime)
{
	// model retry, fixes a glitch
	if (curTime >= NM_ModelSwapRetryAt[minion])
	{
		new bossIdx = FF2_GetBossIndex(NM_MinionBelongsTo[minion]);
		static String:modelName[MAX_MODEL_FILE_LENGTH];
		FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, NM_STRING, 2, modelName, MAX_MODEL_FILE_LENGTH);
		
		if (strlen(modelName) > 3)
		{
			SetVariantString(modelName);
			AcceptEntityInput(minion, "SetCustomModel");
			SetEntProp(minion, Prop_Send, "m_bUseClassAnimations", 1);
			TF2_SetPlayerClass(minion, TFClassType:NM_MinionClass[NM_MinionBelongsTo[minion]]);
		}
		
		NM_ModelRetries[minion]++;
		if (NM_ModelRetries[minion] >= NM_MODEL_MAX_RETRIES)
			NM_ModelSwapRetryAt[minion] = FAR_FUTURE;
		else
			NM_ModelSwapRetryAt[minion] = curTime + NM_MODEL_INTERVAL;
	}

	// remove invincibility
	if (curTime >= NM_InvincibilityEndsAt[minion])
	{
		TF2_RemoveCondition(minion, TFCond_Ubercharged);
		SetEntProp(minion, Prop_Data, "m_takedamage", 2);
		NM_InvincibilityEndsAt[minion] = FAR_FUTURE;
	}
	
	// despawn
	if (curTime >= NM_DespawnAt[minion])
	{
		NM_KillMinion(minion);
		NM_DespawnAt[minion] = FAR_FUTURE;
	}
}

public NM_TickLivingMercs(Float:curTime)
{
	if (curTime >= NM_CheckPositionAt)
	{
		for (new merc = 1; merc < MAX_PLAYERS; merc++)
		{
			if (!IsLivingPlayer(merc) || GetClientTeam(merc) == BossTeam)
				continue;
				
			GetEntPropVector(merc, Prop_Send, "m_vecOrigin", NM_LastPosition[merc]);
		}
	
		NM_CheckPositionAt = curTime + NM_POSITION_CHECK_INTERVAL;
	}
}

/**
 * Water Arena
 */
public WA_DX80Result(QueryCookie:cookie, clientIdx, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (result == ConVarQuery_Okay)
	{
		if (cvarValue[0] > '0' && cvarValue[0] < '9')
		{
			if (PRINT_DEBUG_SPAM)
				PrintToServer("[sarysamods6] Client %d has directX level below 9. Overlay is not supported.", clientIdx);
			WA_OverlaySupported[clientIdx] = false;
		}
	}
	else if (PRINT_DEBUG_INFO)
		PrintToServer("[sarysamods6] WARNING: DX8 query failed for %d. Result is %d (note, this is rare, but expected)", clientIdx, result);
}
 
public Action:WA_PerformDX80Check()
{
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		WA_OverlaySupported[clientIdx] = false;
		if (IsClientInGame(clientIdx))
		{
			WA_OverlaySupported[clientIdx] = true;
			QueryClientConVar(clientIdx, "mat_dxlevel", WA_DX80Result);
		}
	}
}
 
public Action:WA_NoOverlay(clientIdx, argsInt)
{
	WA_OverlayOptOut[clientIdx] = true;
	WA_OOOUserId[clientIdx] = GetClientUserId(clientIdx);
	if (WA_ActiveThisRound)
		WA_FixOverlay(clientIdx, true);

	PrintCenterText(clientIdx, "You have chosen not to show the water overlay.\nThis setting will remain until map change or you log out.\nType !yesoverlay to restore water overlay.");
	return Plugin_Handled;
}

public Action:WA_YesOverlay(clientIdx, argsInt)
{
	WA_OverlayOptOut[clientIdx] = false;
	if (WA_ActiveThisRound)
		WA_FixOverlay(clientIdx, false);
		
	PrintCenterText(clientIdx, "You have chosen to show the water overlay.\nType !nooverlay if you have problems with it.");
	return Plugin_Handled;
}
 
public WA_SetToFirstPerson(clientIdx)
{
	new flags = GetCommandFlags("firstperson");
	SetCommandFlags("firstperson", flags & ~FCVAR_CHEAT);
	ClientCommand(clientIdx, "firstperson");
	SetCommandFlags("firstperson", flags);
}

public WA_SetToThirdPerson(clientIdx)
{
	new flags = GetCommandFlags("thirdperson");
	SetCommandFlags("thirdperson", flags & ~FCVAR_CHEAT);
	ClientCommand(clientIdx, "thirdperson");
	SetCommandFlags("thirdperson", flags);
}
 
public Action:WA_OnCmdThirdPerson(clientIdx, const String:command[], argc)
{
	if (!WA_ActiveThisRound)
		return Plugin_Continue; // just in case
		
	WA_IsThirdPerson[clientIdx] = true;
	if (IsLivingPlayer(clientIdx) && TF2_IsPlayerInCondition(clientIdx, TFCond:COND_JARATE_WATER))
		WA_SetToThirdPerson(clientIdx);
		
	return Plugin_Continue;
}

public Action:WA_OnCmdFirstPerson(clientIdx, const String:command[], argc)
{
	if (!WA_ActiveThisRound)
		return Plugin_Continue; // just in case
		
	WA_IsThirdPerson[clientIdx] = false;
	if (IsLivingPlayer(clientIdx) && TF2_IsPlayerInCondition(clientIdx, TFCond:COND_JARATE_WATER))
		WA_SetToFirstPerson(clientIdx);
		
	return Plugin_Continue;
}

public Action:OnStomp(attacker, victim, &Float:damageMultiplier, &Float:damageBonus, &Float:JumpPower)
{
	// disable goombas entirely in a water arena
	if (WA_ActiveThisRound)
		return Plugin_Handled;
		
	return Plugin_Continue;
}

// only do this once. people shouldn't be latespawning at all, after all...
public WA_ReplaceBrokenWeapons()
{
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx))
			continue;
	
		new TFClassType:playerClass = TF2_GetPlayerClass(clientIdx);
		if (playerClass == TFClass_Pyro)
		{
			// only allow shotgun secondary. replace all others with stock shotgun.
			new secondary = GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Secondary);
			if (!IsValidEntity(secondary))
				continue;
				
			new String:classname[MAX_ENTITY_CLASSNAME_LENGTH];
			GetEntityClassname(secondary, classname, MAX_ENTITY_CLASSNAME_LENGTH);
			if (StrContains(classname, "tf_weapon_shotgun") == -1) // this should be 95% future-proof.
			{
				TF2_RemoveWeaponSlot(clientIdx, TFWeaponSlot_Secondary);
				new weapon = SpawnWeapon(clientIdx, "tf_weapon_shotgun_pyro", 12, 1, 0, WA_PyroShotgunArgs);
				if (IsValidEntity(weapon))
				{
					new offset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1);
					SetEntProp(clientIdx, Prop_Send, "m_iAmmo", 32, 4, offset);
				}
				PrintToChat(clientIdx, "Your Pyro secondary doesn't work in water. Replaced with a shotgun.");
			}
		}
		else if (playerClass == TFClass_Sniper)
		{
			// only allow shotgun secondary. replace all others with stock shotgun.
			new primary = GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Primary);
			if (!IsValidEntity(primary))
				continue;
				
			new String:classname[MAX_ENTITY_CLASSNAME_LENGTH];
			GetEntityClassname(primary, classname, MAX_ENTITY_CLASSNAME_LENGTH);
			if (!strcmp(classname, "tf_weapon_compound_bow")) // this should be 95% future-proof.
			{
				TF2_RemoveWeaponSlot(clientIdx, TFWeaponSlot_Primary);
				new weapon = SpawnWeapon(clientIdx, "tf_weapon_sniperrifle", 14, 1, 0, WA_SniperRifleArgs);
				if (IsValidEntity(weapon))
				{
					SetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon", weapon);
					new offset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1);
					SetEntProp(clientIdx, Prop_Send, "m_iAmmo", 25, 4, offset);
				}
				PrintToChat(clientIdx, "Your bow doesn't work in water. Replaced with a sniper rifle.");
			}
		}
		else if (playerClass == TFClass_Heavy)
		{
			// dalokohs or fishcake secondary
			new secondary = GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Secondary);
			if (!IsValidEntity(secondary))
				continue;
				
			new weaponIdx = GetEntProp(secondary, Prop_Send, "m_iItemDefinitionIndex");
			if (weaponIdx == 159 || weaponIdx == 433)
			{
				TF2_RemoveWeaponSlot(clientIdx, TFWeaponSlot_Secondary);
				new String:attr[20];
				Format(attr, sizeof(attr), "26 ; %f", WA_HeavyDalokohsBoost);
				SpawnWeapon(clientIdx, "tf_weapon_lunchbox", weaponIdx, 1, 0, attr);
				PrintToChat(clientIdx, "Your Dalokohs has given you a permanent HP boost this round.");
			}
		}
	}
}

public bool:WA_ShouldHaveLameWater(clientIdx)
{
	return IsLivingPlayer(clientIdx) && ((GetClientTeam(clientIdx) == BossTeam && !WA_AllEngiesDead) || WA_UsingSpellbookLameWater[clientIdx] || WA_RemoveLameWaterAt[clientIdx] != FAR_FUTURE);
}

public WA_PreThink(clientIdx) // credit to phatrages. knew about this prop but I would never have thought I needed to do this in a think.
{
	if (!WA_ActiveThisRound) // just in case
		SDKUnhook(clientIdx, SDKHook_PreThink, WA_PreThink);

	if (WA_ShouldHaveLameWater(clientIdx))
	{
		if (WA_NoWaterUntil[clientIdx] > GetEngineTime())
		{
			//PrintToServer("no water %d", clientIdx);
			SetEntProp(clientIdx, Prop_Send, "m_nWaterLevel", 0);
		}
		else
			SetEntProp(clientIdx, Prop_Send, "m_nWaterLevel", 3);
	}
	
	if (US_ActiveThisRound && IsLivingPlayer(clientIdx))
	{
		if (US_CanUse[clientIdx] && US_MaxHP[clientIdx] > 0)
		{
			new Float:healthFactor = 1.0 - (float(GetEntProp(clientIdx, Prop_Data, "m_iHealth")) / float(US_MaxHP[clientIdx]));
			new Float:moveSpeed = US_StartSpeed[clientIdx] + ((US_EndSpeed[clientIdx] - US_StartSpeed[clientIdx]) * healthFactor);
			if (TF2_IsPlayerInCondition(clientIdx, TFCond_Dazed))
				moveSpeed *= 0.5;
			if (TF2_IsPlayerInCondition(clientIdx, TFCond_SpeedBuffAlly))
				moveSpeed *= 1.35;
			if (TF2_IsPlayerInCondition(clientIdx, TFCond_Slowed))
				moveSpeed *= 0.4;
			SetEntPropFloat(clientIdx, Prop_Send, "m_flMaxspeed", moveSpeed);
		}
	}
}

public WA_FixOverlay(clientIdx, bool:remove)
{
	new flags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
	if (remove || WA_OverlayOptOut[clientIdx] || !WA_OverlaySupported[clientIdx])
		ClientCommand(clientIdx, "r_screenoverlay \"\"");
	else
		ClientCommand(clientIdx, "r_screenoverlay \"%s\"", WA_UnderwaterOverlay);
	SetCommandFlags("r_screenoverlay", flags);
}

public WA_GoodWater(clientIdx)
{
	TF2_AddCondition(clientIdx, TFCond:COND_JARATE_WATER, -1.0);
	
	// fix to first person
	if (GetEntProp(clientIdx, Prop_Send, "m_nForceTauntCam") == 0)
	{
		WA_SetToFirstPerson(clientIdx);
		WA_IsThirdPerson[clientIdx] = false;
		for (new i = 0; i < FIX_PERSPECTIVE_COUNT; i++)
			WA_FixPerspectiveAt[clientIdx][i] = GetEngineTime() + (0.5 * (i+1)); // a backup perspective fix
	}
	else
		WA_IsThirdPerson[clientIdx] = true;
	
	// fix the overlay now
	WA_FixOverlay(clientIdx, false);
	
	// never play underwater sound
	WA_PlayWaterSoundAt[clientIdx] = FAR_FUTURE;
}

public WA_LameWater(clientIdx)
{
	WA_FixOverlay(clientIdx, false);
	WA_PlayWaterSoundAt[clientIdx] = GetEngineTime();
}

public bool:WA_SpellbookActive(clientIdx)
{
	new weapon = GetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(weapon))
		return false;
		
	static String:classname[MAX_ENTITY_CLASSNAME_LENGTH];
	GetEntityClassname(weapon, classname, MAX_ENTITY_CLASSNAME_LENGTH);
	if (!strcmp(classname, "tf_weapon_spellbook"))
		return true;
	return false;
}

public Action:WA_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	// don't let users drown or catch fire.
	if (damagetype & (DMG_DROWN | DMG_BURN))
		return Plugin_Handled;
		
	// boost pyro damage
	if (IsLivingPlayer(attacker) && TF2_GetPlayerClass(attacker) == TFClass_Pyro)
	{
		if (weapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Secondary))
		{
			damage *= WA_PyroSecondaryBoost;
			return Plugin_Changed;
		}
		else if (weapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee))
		{
			damage *= WA_PyroMeleeBoost;
			return Plugin_Changed;
		}
	}
		
	return Plugin_Continue;
}
 
public WA_AddHooks()
{
	HookEvent("player_spawn", WA_PlayerSpawn, EventHookMode_Post);
	AddCommandListener(WA_OnCmdThirdPerson, "tp");
	AddCommandListener(WA_OnCmdThirdPerson, "sm_thirdperson");
	AddCommandListener(WA_OnCmdFirstPerson, "fp");
	AddCommandListener(WA_OnCmdFirstPerson, "sm_firstperson");
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx))
			continue;
	
		if (GetClientTeam(clientIdx) == BossTeam)
			WA_LameWater(clientIdx);
		else
			WA_GoodWater(clientIdx);
		SDKHook(clientIdx, SDKHook_PreThink, WA_PreThink); // every player needs to use this, because of spellbook issue
		SDKHook(clientIdx, SDKHook_OnTakeDamage, WA_OnTakeDamage);
	}
}

public WA_RemoveHooks()
{
	UnhookEvent("player_spawn", WA_PlayerSpawn, EventHookMode_Post);
	RemoveCommandListener(WA_OnCmdThirdPerson, "tp");
	RemoveCommandListener(WA_OnCmdThirdPerson, "sm_thirdperson");
	RemoveCommandListener(WA_OnCmdFirstPerson, "fp");
	RemoveCommandListener(WA_OnCmdFirstPerson, "sm_firstperson");
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		// must remove hooks from dead players as well.
		if (!IsClientInGame(clientIdx))
			continue;
	
		SDKUnhook(clientIdx, SDKHook_PreThink, WA_PreThink);
		SDKUnhook(clientIdx, SDKHook_OnTakeDamage, WA_OnTakeDamage);
		WA_FixOverlay(clientIdx, true); // remove water overlay
		
		// in case they're immobile or still in water
		if (IsLivingPlayer(clientIdx))
		{
			SetEntityMoveType(clientIdx, MOVETYPE_WALK);

			if (TF2_IsPlayerInCondition(clientIdx, TFCond:COND_JARATE_WATER))
				TF2_RemoveCondition(clientIdx, TFCond:COND_JARATE_WATER);
		}
	}
}

public Action:WA_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientIdx = GetClientOfUserId(GetEventInt(event, "userid"));

	// if someone latespawned or was summoned, the hooks need to be applied to them
	if (GetClientTeam(clientIdx) == BossTeam)
		WA_LameWater(clientIdx);
	else
		WA_GoodWater(clientIdx);
	SDKHook(clientIdx, SDKHook_PreThink, WA_PreThink); // every player needs to use this, because of spellbook issue
	SDKHook(clientIdx, SDKHook_OnTakeDamage, WA_OnTakeDamage);
}

// based on asherkin and voogru's code, though this is almost exactly like the code used for Snowdrop's rockets
// luckily energy ball and sentry rocket derive from rocket so they should be easy
public WA_CreateRocket(owner, Float:position[3], Float:angle[3])
{
	// create our rocket. no matter what, it's going to spawn, even if it ends up being out of map
	new Float:speed = WA_Velocity;
	new Float:damage = WA_Damage;
	//PrintToServer("speed=%f    damage=%f", speed, damage);
	new String:classname[MAX_ENTITY_CLASSNAME_LENGTH] = "CTFProjectile_Rocket";
	new String:entname[MAX_ENTITY_CLASSNAME_LENGTH] = "tf_projectile_rocket";
	
	new rocket = CreateEntityByName(entname);
	if (!IsValidEntity(rocket))
	{
		PrintToServer("[sarysamods6] Error: Invalid entity %s. Won't spawn rocket. This is sarysa's fault.", entname);
		return;
	}
	
	// determine spawn position
	static Float:spawnVelocity[3];
	GetAngleVectors(angle, spawnVelocity, NULL_VECTOR, NULL_VECTOR);
	spawnVelocity[0] *= speed;
	spawnVelocity[1] *= speed;
	spawnVelocity[2] *= speed;
	
	// deploy!
	TeleportEntity(rocket, position, angle, spawnVelocity);
	SetEntProp(rocket, Prop_Send, "m_bCritical", false); // no random crits
	SetEntDataFloat(rocket, FindSendPropOffs(classname, "m_iDeflected") + 4, damage, true); // credit to voogru
	SetEntProp(rocket, Prop_Send, "m_nSkin", 0); // set skin to red team's
	SetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity", owner);
	SetVariantInt(MercTeam);
	AcceptEntityInput(rocket, "TeamNum", -1, -1, 0);
	SetVariantInt(MercTeam);
	AcceptEntityInput(rocket, "SetTeam", -1, -1, 0); 
	DispatchSpawn(rocket);
	
	// to get stats from the sentry
	SetEntPropEnt(rocket, Prop_Send, "m_hOriginalLauncher", GetPlayerWeaponSlot(owner, TFWeaponSlot_Melee));
	SetEntPropEnt(rocket, Prop_Send, "m_hLauncher", GetPlayerWeaponSlot(owner, TFWeaponSlot_Melee));
}

public WA_Tick(Float:curTime)
{
	// fix the water overlay periodically
	if (curTime >= WA_FixOverlayAt)
	{
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsClientInGame(clientIdx))
				WA_FixOverlay(clientIdx, false);
		}
		
		WA_FixOverlayAt = curTime + WA_FixInterval;
	}
	
	// fix the water condition periodically
	if (curTime >= WA_MassRestoreWaterAt)
	{
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (!IsLivingPlayer(clientIdx))
				continue;
		
			if (!TF2_IsPlayerInCondition(clientIdx, TFCond:COND_JARATE_WATER) && WA_RestoreWaterAt[clientIdx] == FAR_FUTURE && !WA_ShouldHaveLameWater(clientIdx))
				TF2_AddCondition(clientIdx, TFCond:COND_JARATE_WATER, -1.0);
		}
	
		WA_MassRestoreWaterAt = curTime + WA_WATER_RESTORE_INTERVAL;
	}
	
	// individual intervals for special actions that must be handled
	new bool:engieFound = false;
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		// prevent replacement client, who could be dx8, from getting overlay in spectate if not supported
		if (!IsClientInGame(clientIdx))
			WA_OverlaySupported[clientIdx] = false;
	
		if (!IsLivingPlayer(clientIdx))
			continue;
			
		if (GetClientTeam(clientIdx) == MercTeam && TF2_GetPlayerClass(clientIdx) == TFClass_Engineer)
			engieFound = true;
			
		// remove jarate
		if (TF2_IsPlayerInCondition(clientIdx, TFCond_Jarated))
			TF2_RemoveCondition(clientIdx, TFCond_Jarated);
		
		// boss checks every frame
		if (GetClientTeam(clientIdx) == BossTeam)
		{
			if (WA_AllEngiesDead && !TF2_IsPlayerInCondition(clientIdx, TFCond:COND_JARATE_WATER))
				WA_GoodWater(clientIdx);
			
			if (TF2_IsPlayerInCondition(clientIdx, TFCond_OnFire))
				TF2_RemoveCondition(clientIdx, TFCond_OnFire);
		}
		
		// soldier rocket minicrits
		if (!WA_RocketMinicritDisabled && TF2_GetPlayerClass(clientIdx) == TFClass_Soldier)
		{
			new bool:shouldHaveMinicrits = false;
		
			new weaponIdx = GetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon");
			if (weaponIdx != -1 && weaponIdx == GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Primary))
			{
				new bool:blacklisted = false;
				for (new i = 0; i < WA_MAX_ROCKET_MINICRIT_BLACKLIST; i++)
				{
					if (WA_SoldierNoMinicritWeapons[i] == 0)
						break;
					else if (WA_SoldierNoMinicritWeapons[i] == weaponIdx)
					{
						blacklisted = true;
						break;
					}
				}
				
				if (!blacklisted)
					shouldHaveMinicrits = true;
			}
			
			if (TF2_IsPlayerInCondition(clientIdx, TFCond_CritCola) && !shouldHaveMinicrits)
				TF2_RemoveCondition(clientIdx, TFCond_CritCola);
			else if (!TF2_IsPlayerInCondition(clientIdx, TFCond_CritCola) && shouldHaveMinicrits)
				TF2_AddCondition(clientIdx, TFCond_CritCola, -1.0);
		}
		
		// in case the perspective isn't fixed the first time, which sometimes happens
		for (new i = 0; i < FIX_PERSPECTIVE_COUNT; i++)
		{
			if (curTime >= WA_FixPerspectiveAt[clientIdx][i])
			{
				WA_FixPerspectiveAt[clientIdx][i] = FAR_FUTURE;
				WA_SetToFirstPerson(clientIdx);
			}
		}

		// replay the water sound for folks with lame water
		if (curTime >= WA_PlayWaterSoundAt[clientIdx])
		{
			if (strlen(WA_UnderwaterSound) > 3)
				EmitSoundToClient(clientIdx, WA_UnderwaterSound);
			WA_PlayWaterSoundAt[clientIdx] = curTime + WA_SoundLoopInterval;
		}
		
		// restore water, i.e. for engineers. only good water users will ever need this.
		if (curTime >= WA_RestoreWaterAt[clientIdx] && !TF2_IsPlayerInCondition(clientIdx, TFCond_Taunting))
		{
			SetEntityMoveType(clientIdx, MOVETYPE_WALK);
			WA_GoodWater(clientIdx);
		}
		
		// heavy food, manual consumption
		if (WA_IsEatingHeavyFood[clientIdx])
		{
			new expectedTicks = RoundFloat((4.0 * (curTime - WA_HeavyFoodStartedAt[clientIdx])) / WA_HEAVY_CONSUMPTION_TIME);
			if (expectedTicks > 4)
				expectedTicks = 4;
			
			if (expectedTicks > WA_HeavyFoodTickCount[clientIdx])
			{
				WA_HeavyFoodTickCount[clientIdx]++;
				new actualMaxHP = (WA_IsDalokohs[clientIdx] ? RoundFloat(WA_HeavyDalokohsBoost) : 0) + GetEntProp(clientIdx, Prop_Data, "m_iMaxHealth");
				
				if (GetEntProp(clientIdx, Prop_Send, "m_iHealth") < actualMaxHP)
				{
					// sandvich or dalo..?
					new hpThisTick = WA_HeavyFoodHPPerTick[clientIdx];
					new hpToSet = GetEntProp(clientIdx, Prop_Send, "m_iHealth") + hpThisTick;
					hpToSet = min(hpToSet, actualMaxHP);
					SetEntProp(clientIdx, Prop_Data, "m_iHealth", hpToSet);
					SetEntProp(clientIdx, Prop_Send, "m_iHealth", hpToSet);
				}
			}
			
			if (curTime > WA_HeavyFoodStartedAt[clientIdx] + WA_HEAVY_CONSUMPTION_TIME)
			{
				SetEntityMoveType(clientIdx, MOVETYPE_WALK);
				TF2_RemoveCondition(clientIdx, TFCond_Dazed);
				if (!WA_IsThirdPerson[clientIdx])
					WA_SetToFirstPerson(clientIdx);
				WA_IsEatingHeavyFood[clientIdx] = false;
			}
		}
		else if (WA_EffectLastsUntil[clientIdx] != 0.0)
		{
			if (curTime >= WA_EffectLastsUntil[clientIdx] && !WA_IsDrinking[clientIdx])
			{
				if (WA_IsBonk[clientIdx] && TF2_IsPlayerInCondition(clientIdx, TFCond_Bonked))
					TF2_RemoveCondition(clientIdx, TFCond_Bonked);
				else if (!WA_IsBonk[clientIdx] && TF2_IsPlayerInCondition(clientIdx, TFCond_CritCola))
					TF2_RemoveCondition(clientIdx, TFCond_CritCola);
					
				if (!WA_IsThirdPerson[clientIdx] && WA_IsBonk[clientIdx])
					WA_SetToFirstPerson(clientIdx);
					
				WA_EffectLastsUntil[clientIdx] = 0.0;
			}
			else if (!WA_IsDrinking[clientIdx])
			{
				if (WA_IsBonk[clientIdx] && !TF2_IsPlayerInCondition(clientIdx, TFCond_Bonked))
					TF2_AddCondition(clientIdx, TFCond_Bonked, -1.0);
				else if (!WA_IsBonk[clientIdx] && !TF2_IsPlayerInCondition(clientIdx, TFCond_CritCola))
					TF2_AddCondition(clientIdx, TFCond_CritCola, -1.0);
			}
			
			if (WA_IsDrinking[clientIdx] && curTime >= WA_DrinkingUntil[clientIdx])
			{
				WA_DrinkingUntil[clientIdx] = FAR_FUTURE;
				WA_IsDrinking[clientIdx] = false;
				SetEntityMoveType(clientIdx, MOVETYPE_WALK);
				if (!WA_IsThirdPerson[clientIdx] && !WA_IsBonk[clientIdx])
					WA_SetToFirstPerson(clientIdx);
				TF2_RemoveCondition(clientIdx, TFCond_Dazed);
			}
		}
		
		// has to be checked every tick
		if (WA_UsingSpellbookLameWater[clientIdx] && !WA_SpellbookActive(clientIdx))
		{
			if (WA_RemoveLameWaterAt[clientIdx] == FAR_FUTURE)
				WA_GoodWater(clientIdx);
			WA_UsingSpellbookLameWater[clientIdx] = false;
		}
		else if (!WA_UsingSpellbookLameWater[clientIdx] && WA_SpellbookActive(clientIdx))
		{
			if (WA_RemoveLameWaterAt[clientIdx] == FAR_FUTURE)
			{
				TF2_RemoveCondition(clientIdx, TFCond:COND_JARATE_WATER);
				WA_LameWater(clientIdx);
			}
			WA_UsingSpellbookLameWater[clientIdx] = true;
		}
		
		// remove lame water used by sandman at the appropriate time
		if (curTime >= WA_RemoveLameWaterAt[clientIdx] && WA_RemoveLameWaterAt[clientIdx] != FAR_FUTURE)
		{
			if (!WA_UsingSpellbookLameWater[clientIdx])
				WA_GoodWater(clientIdx);
				
			WA_RemoveLameWaterAt[clientIdx] = FAR_FUTURE;
		}
	}
	WA_AllEngiesDead = !engieFound && !WA_DontSwitchToGoodWater;
	
	// replace spell fireballs with rockets
	new fireball = FindEntityByClassname(-1, "tf_projectile_spellfireball");
	if (IsValidEntity(fireball))
	{
		new owner = GetEntPropEnt(fireball, Prop_Send, "m_hOwnerEntity");
		static Float:position[3];
		static Float:angle[3];
		GetEntPropVector(fireball, Prop_Data, "m_angRotation", angle);
		GetEntPropVector(fireball, Prop_Data, "m_vecOrigin", position);
		
		// the only way to tell a meteor fireball from the other kind is to guess based on distance
		new bool:isMeteor = false;
		if (!IsLivingPlayer(owner))
			isMeteor = true; // high probability
		else
		{
			static Float:adjustedOwnerPos[3];
			GetEntPropVector(owner, Prop_Data, "m_vecOrigin", adjustedOwnerPos);
			adjustedOwnerPos[2] += 60.0;
			if (GetVectorDistance(adjustedOwnerPos, position, true) > (120.0 * 120.0))
				isMeteor = true;
		}
		
		if (isMeteor) // angle is BS. point it straight down.
			angle[0] = 90.0;
	
		AcceptEntityInput(fireball, "kill");
		WA_CreateRocket(owner, position, angle);
	}
}

public WA_OnPlayerRunCmd(clientIdx, buttons)
{
	if (TF2_GetPlayerClass(clientIdx) == TFClass_Engineer && !WA_UsingSpellbookLameWater[clientIdx])
	{
		new Float:curTime = GetEngineTime();
		new bool:useKeyDown = (buttons & IN_ATTACK2) != 0;
	
		if (useKeyDown && !WA_AltFireDown[clientIdx])
		{
			// make sure they're not using the wrangler. otherwise, they're trying to pick up a building.
			new weapon = GetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon");
			new bool:proceed = false;
			if (!IsValidEntity(weapon))
				proceed = true;
			else
			{
				new weaponIdx = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
				if (weaponIdx != 140 && weaponIdx != 1086) // wrangler and festive wrangler
					proceed = true;
			}
			
			// just in case, though the timing window for this weapon is miniscule
			if (!TF2_IsPlayerInCondition(clientIdx, TFCond:COND_JARATE_WATER))
				proceed = false;
			
			if (proceed)
			{
				TF2_RemoveCondition(clientIdx, TFCond:COND_JARATE_WATER);
				WA_FixOverlay(clientIdx, false);
				SetEntityMoveType(clientIdx, MOVETYPE_NONE);
				WA_RestoreWaterAt[clientIdx] = curTime + 0.01;
			}
		}
		
		WA_AltFireDown[clientIdx] = useKeyDown;
	}
	
	if (WA_AllowSandman && TF2_GetPlayerClass(clientIdx) == TFClass_Scout && !WA_UsingSpellbookLameWater[clientIdx] && WA_RemoveLameWaterAt[clientIdx] == FAR_FUTURE)
	{
		new Float:curTime = GetEngineTime();
		new bool:useKeyDown = (buttons & IN_ATTACK2) != 0;
	
		if (useKeyDown && !WA_AltFireDown[clientIdx])
		{
			// make sure they're not using the wrangler. otherwise, they're trying to pick up a building.
			new weapon = GetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon");
			new bool:proceed = false;
			if (IsValidEntity(weapon))
			{
				static String:classname[MAX_ENTITY_CLASSNAME_LENGTH];
				GetEntityClassname(weapon, classname, MAX_ENTITY_CLASSNAME_LENGTH);
				if (!strcmp(classname, "tf_weapon_bat_wood"))
					proceed = true;
				else if (!strcmp(classname, "tf_weapon_bat_giftwrap"))
					proceed = true;
			}
			
			// just in case, though the timing window for this weapon is miniscule
			if (!TF2_IsPlayerInCondition(clientIdx, TFCond:COND_JARATE_WATER))
				proceed = false;
			
			if (proceed)
			{
				TF2_RemoveCondition(clientIdx, TFCond:COND_JARATE_WATER);
				WA_LameWater(clientIdx);
				WA_RemoveLameWaterAt[clientIdx] = curTime + WA_SANDMAN_LAMEWATER_DURATION;
			}
		}
		
		WA_AltFireDown[clientIdx] = useKeyDown;
	}
	
	if ((TF2_GetPlayerClass(clientIdx) == TFClass_Heavy || TF2_GetPlayerClass(clientIdx) == TFClass_Scout) && !WA_UsingSpellbookLameWater[clientIdx])
	{
		new Float:curTime = GetEngineTime();
		new bool:useKeyDown = (buttons & IN_ATTACK) != 0;
		
		if (useKeyDown && !WA_FireDown[clientIdx])
		{
			// is active weapon lunchbox?
			new weapon = GetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon");
			if (!IsValidEntity(weapon))
				return;
				
			new weaponIdx = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			new bool:consumedSomething = false;
			if (TF2_GetPlayerClass(clientIdx) == TFClass_Heavy && !WA_IsEatingHeavyFood[clientIdx])
			{
				if ((weaponIdx == 42 || weaponIdx == 863 || weaponIdx == 1002) // sandvich
					|| (weaponIdx == 159 || weaponIdx == 433)) // dalokohs
				{
					new actualMaxHP = (WA_IsDalokohs[clientIdx] ? RoundFloat(WA_HeavyDalokohsBoost) : 0) + GetEntProp(clientIdx, Prop_Data, "m_iMaxHealth");

					if (curTime < WA_ConsumableCooldownUntil[clientIdx])
					{
						Nope(clientIdx);
						PrintCenterText(clientIdx, "%.1f seconds cooldown remaining.", WA_ConsumableCooldownUntil[clientIdx] - curTime);
					}
					else if (GetEntProp(clientIdx, Prop_Send, "m_iHealth") >= actualMaxHP)
					{
						Nope(clientIdx);
						PrintCenterText(clientIdx, "Your health is already full!");
					}
					else
					{
						consumedSomething = true;
						PseudoAmbientSound(clientIdx, WA_HEAVY_EATING_SOUND, 1, 500.0);
						WA_HeavyFoodStartedAt[clientIdx] = curTime;
						WA_IsEatingHeavyFood[clientIdx] = true;
						WA_HeavyFoodTickCount[clientIdx] = 0;

						if (weaponIdx == 159 || weaponIdx == 433)
						{
							WA_IsDalokohs[clientIdx] = true;
							WA_HeavyFoodHPPerTick[clientIdx] = WA_HeavyDalokohsTick;
						}
						else
						{
							WA_ConsumableCooldownUntil[clientIdx] = curTime + 30.0; // this is so fucking lame, but I can't figure out the good way
							WA_IsDalokohs[clientIdx] = false;
							WA_HeavyFoodHPPerTick[clientIdx] = WA_HeavySandvichTick;
						}
							
						// heavy will toss sandvich when bonkstuck, need to swap to a different item if possible
						// sarysa 2014-12-23, rarely tosses dalokohs as well, which is bad because it never regenerates.
						new weaponToSwap = GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Melee);
						if (!IsValidEntity(weaponToSwap))
							weaponToSwap = GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Primary);
						else
						{
							new meleeWeaponIdx = GetEntProp(weaponToSwap, Prop_Send, "m_iItemDefinitionIndex");

							// don't switch do a weapon that drains hp.
							for (new i = 0; i < WA_MAX_HP_DRAIN_WEAPONS; i++)
							{
								if (WA_HeavyHPDrainWeapons[i] == meleeWeaponIdx)
								{
									weaponToSwap = GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Primary);
									break;
								}
							}
						}

						if (IsValidEntity(weaponToSwap))
							SetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon", weaponToSwap);
					}
				}
			}
			else if (TF2_GetPlayerClass(clientIdx) == TFClass_Scout && !WA_IsDrinking[clientIdx])
			{
				if (weaponIdx == 46 || weaponIdx == 163)
				{
					if (curTime < WA_ConsumableCooldownUntil[clientIdx])
					{
						Nope(clientIdx);
						PrintCenterText(clientIdx, "%.1f seconds cooldown remaining.", WA_ConsumableCooldownUntil[clientIdx] - curTime);
					}
					else
					{
						consumedSomething = true;
						PseudoAmbientSound(clientIdx, WA_SCOUT_DRINKING_SOUND, 1, 500.0);
						WA_IsDrinking[clientIdx] = true;
						WA_IsBonk[clientIdx] = (weaponIdx == 46);
						WA_DrinkingUntil[clientIdx] = curTime + 1.2;
						WA_EffectLastsUntil[clientIdx] = WA_DrinkingUntil[clientIdx] + 8.0;
						WA_ConsumableCooldownUntil[clientIdx] = curTime + 30.0; // this is so fucking lame, but I can't figure out the good way
						
						// swap to primary first, melee second. mainly for crit-a-cola
						new weaponToSwap = GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Primary);
						if (!IsValidEntity(weaponToSwap))
							weaponToSwap = GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Melee);
						if (IsValidEntity(weaponToSwap))
							SetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon", weaponToSwap);
					}
				}
			}
			
			if (consumedSomething)
			{
				new stunner = FindRandomPlayer(true);
				if (IsLivingPlayer(stunner))
					TF2_StunPlayer(clientIdx, 99999.0, 0.0, TF_STUNFLAG_BONKSTUCK | TF_STUNFLAG_NOSOUNDOREFFECT, stunner);
				SetEntityMoveType(clientIdx, MOVETYPE_NONE);
				WA_SetToThirdPerson(clientIdx);
			}
		}
	
		WA_FireDown[clientIdx] = useKeyDown;
	}
}

/**
 * Underwater Charge
 */
public UC_Tick(clientIdx, Float:curTime, buttons)
{
	new bool:keyDown = UC_AltFireActivated[clientIdx] ? ((buttons & IN_ATTACK2) != 0) : ((buttons & IN_RELOAD) != 0);

	if (UC_EndChargeAt[clientIdx] != FAR_FUTURE)
	{
		if (curTime > UC_EndChargeAt[clientIdx])
		{
			UC_EndChargeAt[clientIdx] = FAR_FUTURE;
		}
	}
	else if (keyDown && !UC_KeyDown[clientIdx] && curTime >= UC_UsableAt[clientIdx])
	{
		new bossIdx = FF2_GetBossIndex(clientIdx);
		new Float:bossRage = FF2_GetBossCharge(bossIdx, 0);
		if (UC_RageCost[clientIdx] > bossRage)
		{
			PrintCenterText(clientIdx, UC_NotEnoughRageStr, UC_RageCost[clientIdx]);
		}
		else
		{
			if (UC_RageCost[clientIdx] > 0.0)
				FF2_SetBossCharge(bossIdx, 0, bossRage - UC_RageCost[clientIdx]);
		
			// start the charge
			UC_EndChargeAt[clientIdx] = curTime + UC_Duration[clientIdx];
			UC_RefreshChargeAt[clientIdx] = curTime; // now!
			GetClientEyeAngles(clientIdx, UC_LockedAngle[clientIdx]);
			
			// play the sound
			if (strlen(UC_Sound) > 3)
				PseudoAmbientSound(clientIdx, UC_Sound);
			
			// cooldown!
			UC_UsableAt[clientIdx] = curTime + UC_Cooldown[clientIdx];
		}
	}
	
	// charge ticks
	if (UC_EndChargeAt[clientIdx] != FAR_FUTURE)
	{
		// force player angle if restricted type
		if (UC_ChargeType[clientIdx] == UC_TYPE_RESTRICTED)
		{
			TeleportEntity(clientIdx, NULL_VECTOR, UC_LockedAngle[clientIdx], NULL_VECTOR);
		}
		
		if (curTime >= UC_RefreshChargeAt[clientIdx])
		{
			static Float:velocity[3];
			GetEntPropVector(clientIdx, Prop_Data, "m_vecVelocity", velocity);
			ScaleVector(velocity, UC_VelDampening[clientIdx]);
			
			static Float:newVelocity[3];
			static Float:angleToUse[3];
			if (UC_ChargeType[clientIdx] == UC_TYPE_RESTRICTED)
			{
				angleToUse[0] = UC_LockedAngle[clientIdx][0];
				angleToUse[1] = UC_LockedAngle[clientIdx][1];
				angleToUse[2] = UC_LockedAngle[clientIdx][2];
			}
			else
				GetClientEyeAngles(clientIdx, angleToUse);
			GetAngleVectors(angleToUse, newVelocity, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(newVelocity, UC_ChargeVel[clientIdx]);
			
			newVelocity[0] += velocity[0];
			newVelocity[1] += velocity[1];
			newVelocity[2] += velocity[2];
				
			TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, newVelocity);
			
			UC_RefreshChargeAt[clientIdx] = curTime + UC_ChargeRefreshInterval[clientIdx];
		}
	}
	
	// refresh the HUD
	if (curTime >= UC_NextHUDAt[clientIdx])
	{
		if (curTime >= UC_UsableAt[clientIdx])
		{
			SetHudTextParams(-1.0, UC_HUD_POSITION, UC_HUD_REFRESH_INTERVAL + 0.05, 64, 255, 64, 192);
			ShowHudText(clientIdx, -1, UC_InstructionStr);
		}
		else
		{
			SetHudTextParams(-1.0, UC_HUD_POSITION, UC_HUD_REFRESH_INTERVAL + 0.05, 255, 64, 64, 192);
			ShowHudText(clientIdx, -1, UC_CooldownStr, UC_UsableAt[clientIdx] - curTime);
		}

		UC_NextHUDAt[clientIdx] = curTime + UC_HUD_REFRESH_INTERVAL;
	}

	UC_KeyDown[clientIdx] = keyDown;
}

/**
 * OnPlayerRunCmd/OnGameFrame
 */
#define IMPERFECT_FLIGHT_FACTOR 25
public OnGameFrame()
{
	if (!PluginActiveThisRound || !RoundInProgress)
		return;
		
	new Float:curTime = GetEngineTime();
	
	if (HS_ActiveThisRound)
	{
		HS_Tick(curTime);
	}
	
	if (NM_ActiveThisRound)
	{
		NM_TickLivingMercs(curTime);
	}
	
	if (WA_ActiveThisRound)
	{
		WA_Tick(curTime);
	}

	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		// NOT A BUG
		// this ability ticks even after the user is dead.
		if (NM_ActiveThisRound && NM_CanUse[clientIdx])
			NM_TickBoss(clientIdx, curTime);
		
		// living player required for the below
		if (!IsLivingPlayer(clientIdx))
			continue;
		
		if (NM_ActiveThisRound && NM_MinionBelongsTo[clientIdx] > 0)
			NM_TickMinion(clientIdx, curTime);

		// boss team required for all the below
		if (GetClientTeam(clientIdx) != BossTeam)
			continue;

		if (RB_ActiveThisRound && RB_IsUsing[clientIdx])
			RB_Tick(clientIdx, curTime);

		if (HS_ActiveThisRound && HS_CanUse[clientIdx])
		{
			if (HS_DeactivateAt[clientIdx] <= curTime)
				HS_StopHaywire(clientIdx);

			if (curTime >= HS_NextHUDAt[clientIdx])
			{
				SetHudTextParams(-1.0, HS_HUD_POSITION, HS_HUD_REFRESH_INTERVAL + 0.05, 64, 255, 64, 192);
				ShowHudText(clientIdx, -1, HS_HudMessage);
				HS_NextHUDAt[clientIdx] = curTime + HS_HUD_REFRESH_INTERVAL;
			}
		}

		if (SS_ActiveThisRound && SS_CanUse[clientIdx])
			PlayQueuedSound(clientIdx);

		if (SP_ActiveThisRound && SP_CanUse[clientIdx])
			SP_RemoveDebuffs(clientIdx);

		if (MC_ActiveThisRound && MC_CanUse[clientIdx])
			MC_Tick(clientIdx, curTime);

		if (WW_ActiveThisRound && WW_CanUse[clientIdx])
			WW_Tick(clientIdx, curTime);
	}
}
 
public Action:OnPlayerRunCmd(clientIdx, &buttons, &impulse, Float:vel[3], Float:unusedangles[3], &weapon)
{
	if (!PluginActiveThisRound || !RoundInProgress)
		return Plugin_Continue;
	else if (!IsLivingPlayer(clientIdx))
		return Plugin_Continue;
	
	new Action:result = Plugin_Continue;
		
	if (TA_ActiveThisRound && TA_CanUse[clientIdx])
		TA_Tick(clientIdx, GetEngineTime(), buttons);

	if (WA_ActiveThisRound)
	{
		if (GetClientTeam(clientIdx) != BossTeam)
			WA_OnPlayerRunCmd(clientIdx, buttons);
		else if (!WA_AllEngiesDead)
		{
			if ((buttons & IN_DUCK) != 0 && !WA_CrouchDown[clientIdx])
			{
				EmitSoundToClient(clientIdx, WA_CROUCH_JEER_SOUND);
				PrintCenterText(clientIdx, "Don't crouch! It causes earthquakes.\nTo fix, very rapidly double crouch.\nOr spam crouches on the ocean floor.\nIt may take a few tries to work.");
			}
			else if (WA_CrouchDown[clientIdx] && (buttons & IN_DUCK) == 0)
			{
				WA_NoWaterUntil[clientIdx] = GetEngineTime() + 0.05;
				SetEntProp(clientIdx, Prop_Send, "m_nWaterLevel", 0);
			}
			
			WA_CrouchDown[clientIdx] = (buttons & IN_DUCK) != 0;
		}
	}
		
	if (UC_ActiveThisRound && UC_CanUse[clientIdx])
		UC_Tick(clientIdx, GetEngineTime(), buttons);

	return result;
}

/**
 * General helper stocks, some original, some taken/modified from other sources
 */
stock PlaySoundLocal(clientIdx, String:soundPath[], bool:followPlayer = true, stack = 1)
{
	// play a speech sound that travels normally, local from the player.
	decl Float:playerPos[3];
	GetClientEyePosition(clientIdx, playerPos);
	//PrintToServer("[sarysamods6] eye pos=%f,%f,%f     sound=%s", playerPos[0], playerPos[1], playerPos[2], soundPath);
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

// adapted from the above and Friagram's halloween 2013 (which standing alone did not work for me)
stock AttachParticleToAttachment(entity, const String:particleType[], const String:attachmentPoint[])
{
	new particle = CreateEntityByName("info_particle_system");
	
	if (!IsValidEntity(particle))
		return -1;

	decl String:targetName[128];
	decl Float:position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	AcceptEntityInput(particle, "SetParent", particle, particle, 0);
	SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	
	SetVariantString(attachmentPoint);
	AcceptEntityInput(particle, "SetParentAttachment");

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

public Action:RemoveEntityNoTele(Handle:timer, any:entid)
{
	new entity = EntRefToEntIndex(entid);
	if (IsValidEdict(entity) && entity > MaxClients)
		AcceptEntityInput(entity, "Kill");
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
		PrintToServer("[sarysamods6] Error: Invalid weapon spawned. client=%d name=%s idx=%d attr=%s", client, name, index, attribute);
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

stock bool:IsPlayerInRange(player, Float:position[3], Float:maxDistance)
{
	maxDistance *= maxDistance;
	
	static Float:playerPos[3];
	GetEntPropVector(player, Prop_Data, "m_vecOrigin", playerPos);
	return GetVectorDistance(position, playerPos, true) <= maxDistance;
}

stock FindRandomPlayer(bool:isBossTeam, Float:position[3] = NULL_VECTOR, Float:maxDistance = 0.0, bool:anyTeam = false)
{
	new player = -1;

	// first, get a player count for the team we care about
	new playerCount = 0;
	for (new clientIdx = 0; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx))
			continue;
			
		if (maxDistance > 0.0 && !IsPlayerInRange(clientIdx, position, maxDistance))
			continue;

		if ((isBossTeam && GetClientTeam(clientIdx) == BossTeam) || (!isBossTeam && GetClientTeam(clientIdx) != BossTeam) || anyTeam)
			playerCount++;
	}

	// ensure there's at least one living valid player
	if (playerCount <= 0)
		return -1;

	// now randomly choose our victim
	new rand = GetRandomInt(0, playerCount - 1);
	playerCount = 0;
	for (new clientIdx = 0; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx))
			continue;

		if (maxDistance > 0.0 && !IsPlayerInRange(clientIdx, position, maxDistance))
			continue;
			
		if ((isBossTeam && GetClientTeam(clientIdx) == BossTeam) || (!isBossTeam && GetClientTeam(clientIdx) != BossTeam) || anyTeam)
		{
			if (playerCount == rand) // needed if rand is 0
			{
				player = clientIdx;
				break;
			}
			playerCount++;
			if (playerCount == rand) // needed if rand is playerCount - 1, executes for all others except 0
			{
				player = clientIdx;
				break;
			}
		}
	}
	
	return player;
}
			
stock FindRandomSpawn(bool:bluSpawn, bool:redSpawn)
{
	new spawn = -1;

	// first, get a spawn count for the team(s) we care about
	new spawnCount = 0;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "info_player_teamspawn")) != -1)
	{
		new teamNum = GetEntProp(entity, Prop_Send, "m_iTeamNum");
		if ((teamNum == BossTeam && bluSpawn) || (teamNum != BossTeam && redSpawn))
			spawnCount++;
	}

	// ensure there's at least one valid spawn
	if (spawnCount <= 0)
		return -1;

	// now randomly choose our spawn
	new rand = GetRandomInt(0, spawnCount - 1);
	spawnCount = 0;
	while ((entity = FindEntityByClassname(entity, "info_player_teamspawn")) != -1)
	{
		new teamNum = GetEntProp(entity, Prop_Send, "m_iTeamNum");
		if ((teamNum == BossTeam && bluSpawn) || (teamNum != BossTeam && redSpawn))
		{
			if (spawnCount == rand)
				spawn = entity;
			spawnCount++;
			if (spawnCount == rand)
				spawn = entity;
		}
	}
	
	return spawn;
}

stock GetLivingMercCount()
{
	// recalculate living players
	new livingMercCount = 0;
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		if (IsLivingPlayer(clientIdx) && GetClientTeam(clientIdx) != BossTeam)
			livingMercCount++;
	
	return livingMercCount;
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

public bool:TraceRedPlayers(entity, contentsMask)
{
	if (IsLivingPlayer(entity) && GetClientTeam(entity) != BossTeam)
	{
		if (PRINT_DEBUG_SPAM)
			PrintToServer("[sarysamods6] Hit player %d on trace.", entity);
		return true;
	}

	return false;
}

public bool:TraceRedPlayersAndBuildings(entity, contentsMask)
{
	if (IsLivingPlayer(entity) && GetClientTeam(entity) != BossTeam)
	{
		if (PRINT_DEBUG_SPAM)
			PrintToServer("[sarysamods6] Hit player %d on trace.", entity);
		return true;
	}
	else if (IsValidEntity(entity))
	{
		static String:classname[MAX_ENTITY_CLASSNAME_LENGTH];
		GetEntityClassname(entity, classname, sizeof(classname));
		classname[4] = 0;
		if (!strcmp(classname, "obj_")) // all buildings start with this
			return true;
	}

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

// really wish that the original GetVectorAngles() worked this way.
stock Float:GetVectorAnglesTwoPoints(const Float:startPos[3], const Float:endPos[3], Float:angles[3])
{
	static Float:tmpVec[3];
	//tmpVec[0] = startPos[0] - endPos[0];
	//tmpVec[1] = startPos[1] - endPos[1];
	//tmpVec[2] = startPos[2] - endPos[2];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}

stock Float:GetVelocityFromPointsAndInterval(Float:pointA[3], Float:pointB[3], Float:deltaTime)
{
	if (deltaTime <= 0.0)
		return 0.0;

	return GetVectorDistance(pointA, pointB) * (1.0 / deltaTime);
}

stock Float:fixDamageForFF2(Float:damage)
{
	if (damage <= 160.0)
		return damage / 3.0;
	return damage;
}

// for when damage to a hale needs to be recognized
stock SemiHookedDamage(victim, inflictor, attacker, Float:damage, damageType=DMG_GENERIC, weapon=-1)
{
	if (GetClientTeam(victim) != BossTeam)
		SDKHooks_TakeDamage(victim, inflictor, attacker, damage, damageType, weapon);
	else
	{
		new String:dmgStr[16];
		IntToString(RoundFloat(damage), dmgStr, sizeof(dmgStr));
	
		// took this from war3...I hope it doesn't double damage like I've heard old versions do
		new pointHurt = CreateEntityByName("point_hurt");
		if (IsValidEntity(pointHurt))
		{
			DispatchKeyValue(victim, "targetname", "halevictim");
			DispatchKeyValue(pointHurt, "DamageTarget", "halevictim");
			DispatchKeyValue(pointHurt, "Damage", dmgStr);
			DispatchKeyValueFormat(pointHurt, "DamageType", "%d", damageType);
			
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt, "Hurt", attacker);
			DispatchKeyValue(pointHurt, "classname", "point_hurt");
			DispatchKeyValue(victim, "targetname", "noonespecial");
			RemoveEntity(INVALID_HANDLE, EntIndexToEntRef(pointHurt));
		}
	}
}

// this version ignores obstacles
stock PseudoAmbientSound(clientIdx, String:soundPath[], count=1, Float:radius=1000.0, bool:skipSelf=false, bool:skipDead=false, Float:volumeFactor=1.0)
{
	decl Float:emitterPos[3];
	decl Float:listenerPos[3];
	GetClientEyePosition(clientIdx, emitterPos);
	for (new listener = 1; listener < MAX_PLAYERS; listener++)
	{
		if (!IsClientInGame(listener))
			continue;
		else if (skipSelf && listener == clientIdx)
			continue;
		else if (skipDead && !IsLivingPlayer(listener))
			continue;
			
		// knowing virtually nothing about sound engineering, I'm kind of BSing this here...
		// but I'm pretty sure decibal dropoff is best done logarithmically.
		// so I'm doing that here.
		GetClientEyePosition(listener, listenerPos);
		new Float:distance = GetVectorDistance(emitterPos, listenerPos);
		if (distance >= radius)
			continue;
		
		new Float:logMe = (radius - distance) / (radius / 10.0);
		if (logMe <= 0.0) // just a precaution, since EVERYTHING tosses an exception in this game
			continue;
			
		new Float:volume = Logarithm(logMe) * volumeFactor;
		if (volume <= 0.0)
			continue;
		else if (volume > 1.0)
		{
			PrintToServer("[sarysamods6] How the hell is volume greater than 1.0?");
			volume = 1.0;
		}
		
		for (new i = 0; i < count; i++)
			EmitSoundToClient(listener, soundPath, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, volume);
	}
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

stock bool:RectangleCollision(Float:hull[2][3], Float:point[3])
{
	return (point[0] >= hull[0][0] && point[0] <= hull[1][0]) &&
		(point[1] >= hull[0][1] && point[1] <= hull[1][1]) &&
		(point[2] >= hull[0][2] && point[2] <= hull[1][2]);
}

stock Float:getLinearVelocity(Float:vecVelocity[3])
{
	return SquareRoot((vecVelocity[0] * vecVelocity[0]) + (vecVelocity[1] * vecVelocity[1]) + (vecVelocity[2] * vecVelocity[2]));
}

stock Float:getBaseVelocityFromYaw(const Float:angle[3], Float:vel[3])
{
	vel[0] = Cosine(angle[1]); // same as unit circle
	//vel[1] = -Sine(angle[1]); // inverse of unit circle
	vel[1] = Sine(angle[1]); // ...or also same of unit circle? must not test in game at 3am...
	vel[2] = 0.0; // unaffected
}

stock Float:RandomNegative(Float:val)
{
	return val * (GetRandomInt(0, 1) == 1 ? 1.0 : -1.0);
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

stock GetA(c) { return abs(c>>24); }
stock GetR(c) { return abs((c>>16)&0xff); }
stock GetG(c) { return abs((c>>8 )&0xff); }
stock GetB(c) { return abs((c    )&0xff); }

stock ColorToDecimalString(String:buffer[COLOR_BUFFER_SIZE], rgb)
{
	Format(buffer, COLOR_BUFFER_SIZE, "%d %d %d", GetR(rgb), GetG(rgb), GetB(rgb));
}

stock BlendColorsRGB(oldColor, Float:oldWeight, newColor, Float:newWeight)
{
	new r = min(RoundFloat((GetR(oldColor) * oldWeight) + (GetR(newColor) * newWeight)), 255);
	new g = min(RoundFloat((GetG(oldColor) * oldWeight) + (GetG(newColor) * newWeight)), 255);
	new b = min(RoundFloat((GetB(oldColor) * oldWeight) + (GetB(newColor) * newWeight)), 255);
	return (r<<16) + (g<<8) + b;
}

stock Nope(clientIdx)
{
	EmitSoundToClient(clientIdx, NOPE_AVI);
}

// stole this stock from KissLick. it's a good stock!
stock DispatchKeyValueFormat(entity, const String:keyName[], const String:format[], any:...)
{
	static String:value[256];
	VFormat(value, sizeof(value), format, 4);

	DispatchKeyValue(entity, keyName, value);
} 

/**
 * Reflection! Yay! Snap the rope.
 */
#define PACK5_PLUGIN_FILENAME "ff2_sarysamods5.ff2"
stock GetMethod(const String:methodName[], &Handle:retPlugin, &Function:retFunc)
{
	static String:buffer[256];
	new Handle:iter = GetPluginIterator();
	new Handle:plugin = INVALID_HANDLE;
	while (MorePlugins(iter))
	{
		plugin = ReadPlugin(iter);
		
		GetPluginFilename(plugin, buffer, sizeof(buffer));
		if (StrContains(buffer, PACK5_PLUGIN_FILENAME, false) != -1)
			break;
		else
			plugin = INVALID_HANDLE;
	}
	
	CloseHandle(iter);
	if (plugin != INVALID_HANDLE)
	{
		new Function:func = GetFunctionByName(plugin, methodName);
		if (func != INVALID_FUNCTION)
		{
			retPlugin = plugin;
			retFunc = func;
		}
		else
			PrintToServer("[ff2_sarysamods6] ERROR: Could not find %s:%s()", PACK5_PLUGIN_FILENAME, methodName);
	}
	else
		PrintToServer("[ff2_sarysamods6] ERROR: Could not find %s. %s() failed.", PACK5_PLUGIN_FILENAME, methodName);
}
 
stock SnapTheRope(clientIdx)
{
	new Handle:plugin = INVALID_HANDLE;
	new Function:func = INVALID_FUNCTION;
	GetMethod("CancelHookshot", plugin, func);
	if (plugin == INVALID_HANDLE || func == INVALID_FUNCTION)
		return;
	
	Call_StartFunction(plugin, func);
	Call_PushCell(clientIdx);
	Call_PushCell(0); // ropeSnapped
	Call_PushCell(0); // errorIdx
	Call_Finish();
	CloseHandle(plugin);
}
