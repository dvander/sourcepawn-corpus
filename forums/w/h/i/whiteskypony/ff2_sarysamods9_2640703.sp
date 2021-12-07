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
#include <tf2attributes>
#include <ff2_dynamic_defaults>
#undef REQUIRE_PLUGIN
#tryinclude <goomba>
#define REQUIRE_PLUGIN

/**
 * My ninth VSP rage pack, rages for Zecora, Spike, Starlight Glimmer, ?, ?
 *
 * JaratePotion: Takes the humble Sniper Jarate and turns it into a potion the hale can use to apply various effects.
 *
 * FF2SpeedOverride: Override FF2 speed management, do it right. :P
 *
 * RageLoveCurse: Pairs up players in a radius, forces attraction and causes damage relative to distance separated from "mate".
 *
 * Rage/DOTIllusions: Creates multiple self-illusions by reskinning players to the boss.
 * Known Issues: - Some classes may break horribly depending on the class of the swap model.
 *               - Not recommended for multiple bosses in one battle to have this ability, due to efficiency modifications that were necessary.
 */

// copied from tf2 sdk
// effects, for m_fEffects
#define EF_BONEMERGE 0x001	// Performs bone merge on client side
#define EF_BRIGHTLIGHT 0x002	// DLIGHT centered at entity origin
#define EF_DIMLIGHT 0x004	// player flashlight
#define EF_NOINTERP 0x008	// don't interpolate the next frame
#define EF_NOSHADOW 0x010	// Don't cast no shadow
#define EF_NODRAW 0x020		// don't draw entity
#define EF_NORECEIVESHADOW 0x040	// Don't receive no shadow
#define EF_BONEMERGE_FASTCULL 0x080	// For use with EF_BONEMERGE. If this is set, then it places this ent's origin at its
#define EF_ITEM_BLINK 0x100	// blink an item so that the user notices it.
#define EF_PARENT_ANIMATES 0x200	// always assume that the parent entity is animating

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

#define IsEmptyString(%1) (%1[0] == 0)

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
#define INVALID_ENTREF INVALID_ENT_REFERENCE

// text string limits
#define MAX_SOUND_FILE_LENGTH 80
#define MAX_MODEL_FILE_LENGTH 128
#define MAX_MATERIAL_FILE_LENGTH 128
#define MAX_WEAPON_NAME_LENGTH 64
#define MAX_WEAPON_ARG_LENGTH 256
#define MAX_EFFECT_NAME_LENGTH 48
#define MAX_ENTITY_CLASSNAME_LENGTH 48
#define MAX_CENTER_TEXT_LENGTH 256
#define MAX_RANGE_STRING_LENGTH 66
#define MAX_HULL_STRING_LENGTH 197
#define MAX_ATTACHMENT_NAME_LENGTH 48
#define COLOR_BUFFER_SIZE 12
#define HEX_OR_DEC_STRING_LENGTH 12 // max -2 billion is 11 chars + null termination
#define MAX_TERMINOLOGY_LENGTH 25
#define MAX_DESCRIPTION_LENGTH 129
#define MAX_ABILITY_NAME_LENGTH 65 // seems to be double-wide now, was 33 but that limited it to 16

// common array limits
#define MAX_CONDITIONS 10 // TF2 conditions (bleed, dazed, etc.)

#define MAX_PLAYERS_ARRAY 36
#define MAX_PLAYERS (MAX_PLAYERS_ARRAY < (MaxClients + 1) ? MAX_PLAYERS_ARRAY : (MaxClients + 1))

new bool:NULL_BLACKLIST[MAX_PLAYERS_ARRAY];

new MercTeam = _:TFTeam_Red;
new BossTeam = _:TFTeam_Blue;

new RoundInProgress = false;

public Plugin:myinfo = {
	name = "Freak Fortress 2: sarysa's mods, ninth pack",
	author = "sarysa",
	version = "1.1.9",
}

#define FAR_FUTURE 100000000.0
#define COND_JARATE_WATER 86

// REMOVE FROM PACK 10! taken from first set abilities
new Handle:cvarTimeScale = INVALID_HANDLE;
new Handle:cvarCheats = INVALID_HANDLE;

/**
 * Jarate Potion
 */
#define JP_STRING "jarate_potion"
#define JP_SPLASH_RADIUS_SQUARED (200.0 * 200.0) // used for ally buffs
#define JP_RECHARGE_SOUND "player/recharged.wav"
#define JP_FLAG_RELATIVE_SLOW 0x0001
#define JP_FLAG_RELATIVE_FAST 0x0002
#define JP_FLAG_FUNNY_VOICES 0x0004
#define JP_FLAG_BLOCK_AIRBLAST 0x0008
#define JP_FLAG_JARATE_VISIBLE 0x0010
#define JP_FLAG_FROZEN_GRACE_PERIOD 0x0020
new bool:JP_ActiveThisRound;
new bool:JP_CanUse[MAX_PLAYERS_ARRAY];
new Float:JP_RemoveConditionsAt[MAX_PLAYERS_ARRAY]; // internal
new Float:JP_RemoveInvulnAt[MAX_PLAYERS_ARRAY]; // internal
new TFCond:JP_Conditions[MAX_PLAYERS_ARRAY][MAX_CONDITIONS]; // internal, used by both friend and foe (also used by bumper cars easter egg)
new Float:JP_RestorePotionAt[MAX_PLAYERS_ARRAY]; // internal
new Float:JP_SafeResizeRetryAt[MAX_PLAYERS_ARRAY]; // internal
new Float:JP_SafeResizeShouldSlayAt[MAX_PLAYERS_ARRAY]; // internal
new JP_SlayMessageNext[MAX_PLAYERS_ARRAY]; // internal
new Float:JP_TargetSize[MAX_PLAYERS_ARRAY]; // internal
new JP_ActiveJarEntRef[MAX_PLAYERS_ARRAY]; // internal
new Float:JP_ActiveJarPos[MAX_PLAYERS_ARRAY][3]; // internal
new Float:JP_HeadScale[MAX_PLAYERS_ARRAY]; // internal
new Float:JP_ExpectedSpeed[MAX_PLAYERS_ARRAY]; // internal
new bool:JP_ModifyingSpeed[MAX_PLAYERS_ARRAY]; // internal
new bool:JP_WasAirblasted[MAX_PLAYERS_ARRAY]; // internal
new JP_TestJarEntRef; // internal
new Float:JP_RefreshDelay[MAX_PLAYERS_ARRAY]; // arg1
new String:JP_PotionModel[MAX_MODEL_FILE_LENGTH]; // arg2
new String:JP_VictimSound[MAX_SOUND_FILE_LENGTH]; // arg3
new Float:JP_EnemyEffectDuration[MAX_PLAYERS_ARRAY]; // arg4
new Float:JP_EnemySizeRange[MAX_PLAYERS_ARRAY][2]; // arg5
new Float:JP_EnemyHeadSizeRange[MAX_PLAYERS_ARRAY][2]; // arg6
new TFCond:JP_EnemyConditions[MAX_PLAYERS_ARRAY][MAX_CONDITIONS]; // arg7
new Float:JP_EnemyConditionChance[MAX_PLAYERS_ARRAY]; // arg8
new Float:JP_EnemyPetrificationChance[MAX_PLAYERS_ARRAY]; // arg9
new Float:JP_EnemyBumperCarsChance[MAX_PLAYERS_ARRAY]; // arg10
new Float:JP_AllyEffectDuration[MAX_PLAYERS_ARRAY]; // arg12
new TFCond:JP_AllyConditions[MAX_PLAYERS_ARRAY][MAX_CONDITIONS]; // arg13
new TFCond:JP_AllyRemoveConditions[MAX_PLAYERS_ARRAY][MAX_CONDITIONS]; // arg14
new String:JP_PotionFirstText[MAX_CENTER_TEXT_LENGTH]; // arg15
new String:JP_PotionRefreshText[MAX_CENTER_TEXT_LENGTH]; // arg16
new String:JP_SlayMessage[MAX_CENTER_TEXT_LENGTH]; // arg17
new JP_ItemIndex[MAX_PLAYERS_ARRAY]; // arg18
new JP_Flags; // arg19

/**
 * Speed Override
 */
#define SO_STRING "ff2_speed_override"
new bool:SO_ActiveThisRound;
new bool:SO_CanUse[MAX_PLAYERS_ARRAY];
new SO_MaxHP[MAX_PLAYERS_ARRAY]; // internal, grab this only once
new Float:SO_LowSpeed[MAX_PLAYERS_ARRAY]; // arg1
new Float:SO_HighSpeed[MAX_PLAYERS_ARRAY]; // arg2

/**
 * RageLoveCurse
 */
#define LC_STRING "rage_love_curse"
#define LC_BEAM_DURATION 0.2
#define LC_HUD_Y 0.68
#define LC_MATERIAL "materials/sprites/laser.vmt"
#define LC_FLAG_NO_BEAM 0x0001
#define LC_FLAG_UBER_IMMUNE 0x0002
#define LC_FLAG_ADDITIVE 0x0004
new LC_MATERIAL_INT;
new bool:LC_ActiveThisRound;
new bool:LC_IsAffected[MAX_PLAYERS_ARRAY]; // internal (victim use)
new Float:LC_AffectUntil[MAX_PLAYERS_ARRAY]; // internal (victim use)
new LC_Mate[MAX_PLAYERS_ARRAY]; // internal (victim use)
new LC_Curser[MAX_PLAYERS_ARRAY]; // internal (victim use)
new LC_ParticleEntRef[MAX_PLAYERS_ARRAY]; // internal (victim use)
new Float:LC_NextAttractionAt[MAX_PLAYERS_ARRAY]; // internal (victim use)
new Float:LC_NextDamageAt[MAX_PLAYERS_ARRAY]; // internal (victim use)
new Float:LC_NextBeamAt[MAX_PLAYERS_ARRAY]; // internal (victim use)
new Float:LC_NextHUDAt[MAX_PLAYERS_ARRAY]; // internal (victim use)
new Float:LC_Duration[MAX_PLAYERS_ARRAY]; // arg1
new Float:LC_Radius[MAX_PLAYERS_ARRAY]; // arg2
new Float:LC_MinDistance[MAX_PLAYERS_ARRAY]; // arg3
new LC_BeamColor[MAX_PLAYERS_ARRAY]; // arg4
new Float:LC_AttractionIntensity[MAX_PLAYERS_ARRAY]; // arg5
new Float:LC_AttractionInterval[MAX_PLAYERS_ARRAY]; // arg6
new Float:LC_DamageIntensity[MAX_PLAYERS_ARRAY]; // arg7
new Float:LC_DamageInterval[MAX_PLAYERS_ARRAY]; // arg8
new Float:LC_DamageOnMateDeath[MAX_PLAYERS_ARRAY]; // arg9
new String:LC_EffectName[MAX_EFFECT_NAME_LENGTH]; // arg10
new Float:LC_BeamInterval[MAX_PLAYERS_ARRAY]; // arg11
new String:LC_AfflictionMessage[MAX_CENTER_TEXT_LENGTH]; // arg12
new String:LC_CureMessage[MAX_CENTER_TEXT_LENGTH]; // arg13
new LC_Flags[MAX_PLAYERS_ARRAY]; // arg19

/**
 * RageIllusions and DOTIllusions
 */
#define RI_STRING "rage_illusions"
#define DI_STRING "dot_illusions"
#define RI_MODEL_VERIFICATION_INTERVAL 0.1
new bool:RI_ActiveThisRound;
new bool:RI_CanUse[MAX_PLAYERS_ARRAY];
new bool:RI_IsDOT[MAX_PLAYERS_ARRAY]; // internal
new Float:RI_IllusionsUntil; // internal (victim use)
new RI_IllusionOf[MAX_PLAYERS_ARRAY]; // internal (victim use)
new String:RI_OriginalModel[MAX_PLAYERS_ARRAY][MAX_MODEL_FILE_LENGTH]; // internal (victim use)
new Float:RI_VerifyModelAt[MAX_PLAYERS_ARRAY]; // internal (victim use)
new Float:RI_EnvironmentImmuneUntil[MAX_PLAYERS_ARRAY]; // internal (victim use)
new Float:RI_SafePos[3]; // internal
new Float:RI_Duration[MAX_PLAYERS_ARRAY]; // arg1
new Float:RI_Radius[MAX_PLAYERS_ARRAY]; // arg2
new Float:RI_IllusionsPerPlayer[MAX_PLAYERS_ARRAY]; // arg3
new String:RI_Model[MAX_MODEL_FILE_LENGTH]; // arg4
new bool:RI_ShouldTeleport[MAX_PLAYERS_ARRAY]; // arg5
new String:RI_Particle[MAX_EFFECT_NAME_LENGTH]; // arg6
new String:RI_Sound[MAX_SOUND_FILE_LENGTH]; // arg7
new bool:RI_ShouldRemoveDOTs[MAX_PLAYERS_ARRAY]; // arg8
new bool:RI_ShouldMatchGlow[MAX_PLAYERS_ARRAY]; // arg9

/**
 * Managed Flamethrower
 */
#define MF_STRING "managed_flamethrower"
#define MF_FLAG_INVIS_WATCH_WORKAROUND 0x0001
#define MF_FLAG_DEAD_RINGER_WORKAROUND 0x0002
#define MF_FLAG_MINICRIT_BURNING 0x0004
#define MF_FLAG_STRANGE_FLAMETHROWER 0x0008
#define MF_FLAG_FF2_MANAGES_DAMAGE 0x0010
#define MF_FLAG_VISIBLE 0x0020
#define MF_FLAG_ZERO_ALPHA_FLAMETHROWER 0x0040
#define MF_FLAG_AIRBLAST_DAMAGE_FIX 0x0080
#define MF_AMMO_REFRESH_INTERVAL 1.0
#define MF_TYPE_NORMAL 0
#define MF_TYPE_INVIS_WATCH 1
#define MF_TYPE_DEAD_RINGER 2
new bool:MF_ActiveThisRound;
new bool:MF_CanUse[MAX_PLAYERS_ARRAY];
new Float:MF_AmmoRefreshAt[MAX_PLAYERS_ARRAY]; // internal
new MF_PlayerType[MAX_PLAYERS_ARRAY]; // internal
new Float:MF_PendingDamage[MAX_PLAYERS_ARRAY]; // internal
new Float:MF_AfterburnEndsAt[MAX_PLAYERS_ARRAY]; // internal
new Float:MF_IgniteAt[MAX_PLAYERS_ARRAY]; // internal
new bool:MF_SoundPending[MAX_PLAYERS_ARRAY]; // internal, used to ensure the sound isn't spammed if many airblast targets
new Float:MF_MeleeDamageMultiplier[MAX_PLAYERS_ARRAY]; // arg1
new Float:MF_AirblastDamage[MAX_PLAYERS_ARRAY]; // arg2
new String:MF_AirblastParticle[MAX_EFFECT_NAME_LENGTH]; // arg3
new String:MF_AirblastSound[MAX_SOUND_FILE_LENGTH]; // arg4
new MF_AmmoPerSecond[MAX_PLAYERS_ARRAY]; // arg5
new MF_MaxAmmo[MAX_PLAYERS_ARRAY]; // arg6
new Float:MF_DamageCap[MAX_PLAYERS_ARRAY]; // arg7
new Float:MF_AfterburnCap[MAX_PLAYERS_ARRAY]; // arg8
new Float:MF_AfterburnDuration[MAX_PLAYERS_ARRAY]; // arg9
// arg10-arg12 need not be stored.
new Float:MF_ParticleDistance[MAX_PLAYERS_ARRAY]; // arg13
new MF_Flags[MAX_PLAYERS_ARRAY]; // arg19

/**
 * DOT Digger
 */
#define DD_STRING "dot_digger"
#define DD_FLAG_POOL_PARTY_FIX 0x0001
#define DD_FLAG_GEMS_CURRENT_EYE_ANGLE 0x0002
#define DD_FLAG_HOOKED_DAMAGE 0x0004
#define DD_RECOLOR_ALL 0x0008
new bool:DD_ActiveThisRound;
new bool:DD_CanUse[MAX_PLAYERS_ARRAY];
new bool:DD_IsUsing[MAX_PLAYERS_ARRAY]; // internal
new Float:DD_SpawnNextGemAt[MAX_PLAYERS_ARRAY]; // internal
new Float:DD_StoredYaw[MAX_PLAYERS_ARRAY]; // internal
new Float:DD_NextSoundAt[MAX_PLAYERS_ARRAY]; // internal
new Float:DD_StartTauntAt[MAX_PLAYERS_ARRAY]; // internal
new Float:DD_StopTauntAt[MAX_PLAYERS_ARRAY]; // internal
new DD_TauntIndex[MAX_PLAYERS_ARRAY]; // arg1
new Float:DD_GemInterval[MAX_PLAYERS_ARRAY]; // arg2
new Float:DD_GemLifetime[MAX_PLAYERS_ARRAY]; // arg3
new Float:DD_GemPitchRange[MAX_PLAYERS_ARRAY][2]; // arg4
new Float:DD_GemYawRange[MAX_PLAYERS_ARRAY][2]; // arg5
new Float:DD_GemIntensityRange[MAX_PLAYERS_ARRAY][2]; // arg6
new Float:DD_GemDamage[MAX_PLAYERS_ARRAY]; // arg7
new Float:DD_GemZOffset[MAX_PLAYERS_ARRAY]; // arg8
new Float:DD_CollisionRadius[MAX_PLAYERS_ARRAY]; // arg9
new Float:DD_GoombaDamageMult[MAX_PLAYERS_ARRAY]; // arg10
new Float:DD_GoombaFactorMult[MAX_PLAYERS_ARRAY]; // arg11
new Float:DD_GemSolidifyDelay[MAX_PLAYERS_ARRAY]; // SOFT-DISABLED, was arg12
new Float:DD_TauntInterval[MAX_PLAYERS_ARRAY]; // arg12
new String:DD_InAirError[MAX_CENTER_TEXT_LENGTH]; // arg13
new String:DD_Model[MAX_MODEL_FILE_LENGTH]; // arg14
new String:DD_InitialSound[MAX_SOUND_FILE_LENGTH]; // arg15
new Float:DD_SoundDelay; // arg16
new String:DD_LoopingSound[MAX_SOUND_FILE_LENGTH]; // arg17
new Float:DD_SoundInterval; // arg18
new DD_Flags[MAX_PLAYERS_ARRAY]; // arg19

#define MAX_GEMS 75
new DDG_EntRef[MAX_GEMS];
new DDG_Owner[MAX_GEMS];
new Float:DDG_SolidifyAt[MAX_GEMS];
new Float:DDG_DestroyAt[MAX_GEMS];

/**
 * Blink Hadouken
 */
#define BH_STRING "rage_blink_hadouken"
#define DBH_STRING "dot_blink_hadouken"
#define BH_HUD_INTERVAL 0.1
#define BH_FLAG_PROJECTILE_PENETRATION 0x0001
#define BH_FLAG_UNUSABLE_WHILE_STUNNED 0x0002
#define BH_KEY_MEDIC 0
#define BH_KEY_RELOAD 1
#define BH_KEY_SPECIAL 2
new bool:BH_ActiveThisRound;
new bool:BH_CanUse[MAX_PLAYERS_ARRAY];
new bool:BH_IsDOT[MAX_PLAYERS_ARRAY]; // internal
new BH_ProjectileEntRef[MAX_PLAYERS_ARRAY]; // internal, there can only be one at a time
new Float:BH_LastSafePos[MAX_PLAYERS_ARRAY][3]; // internal, last safe position for blink
new Float:BH_LastActualPos[MAX_PLAYERS_ARRAY][3]; // internal, used to prevent exploiting through walls
new Float:BH_UpdateHUDAt[MAX_PLAYERS_ARRAY]; // internal
new bool:BH_BlinkReady[MAX_PLAYERS_ARRAY]; // internal
new Float:BH_WithheldRage[MAX_PLAYERS_ARRAY]; // internal
new bool:BH_AlreadyHit[MAX_PLAYERS_ARRAY]; // internal, victim use only
new bool:BH_KeyDown[MAX_PLAYERS_ARRAY]; // internal
new Float:BH_BlinkAllowedAt[MAX_PLAYERS_ARRAY]; // internal
new Float:BH_RageCost[MAX_PLAYERS_ARRAY]; // arg1, ignored with DOT version
new Float:BH_Damage[MAX_PLAYERS_ARRAY]; // arg2
new Float:BH_Speed[MAX_PLAYERS_ARRAY]; // arg3
new Float:BH_Radius[MAX_PLAYERS_ARRAY]; // arg4
new BH_KeyID[MAX_PLAYERS_ARRAY]; // arg5
new Float:BH_HudY[MAX_PLAYERS_ARRAY]; // arg6
new BH_HudColor[MAX_PLAYERS_ARRAY]; // arg7
new String:BH_RageSound[MAX_SOUND_FILE_LENGTH]; // arg8
new String:BH_BlinkSound[MAX_SOUND_FILE_LENGTH]; // arg9
new BH_Model[MAX_PLAYERS_ARRAY]; // arg10
new String:BH_Particle[MAX_EFFECT_NAME_LENGTH]; // arg11
new Float:BH_SentryStunDuration[MAX_PLAYERS_ARRAY]; // arg12
new Float:BH_SentryStunRadius[MAX_PLAYERS_ARRAY]; // arg13
new BH_ModelRecolor[MAX_PLAYERS_ARRAY]; // arg14
new String:BH_NothingReadyHudText[MAX_CENTER_TEXT_LENGTH]; // arg16
new String:BH_BlinkReadyHudText[MAX_CENTER_TEXT_LENGTH]; // arg17
new String:BH_RageReadyHudText[MAX_CENTER_TEXT_LENGTH]; // arg18
new BH_Flags[MAX_PLAYERS_ARRAY]; // arg19

/**
 * Equalize
 */
#define RE_STRING "rage_equalize"
#define DE_STRING "dot_equalize"
#define DPE_STRING "dot_projectile_equalize"
#define SPE_STRING "spell_projectile_equalize"
#define RE_MODE_RAGE 0
#define RE_MODE_DOT 1
#define RE_MODE_PROJECTILE 2
#define RE_FLAG_SUPPRESS_HEADS 0x0001
#define RE_FLAG_SUPPRESS_AIR_JUMP 0x0002
#define RE_FLAG_SUPPRESS_OVERHEAL 0x0004
#define RE_FLAG_SUPPRESS_CLOAK 0x0008
#define RE_FLAG_STUN_SENTRIES 0x0010
#define RE_FLAG_DESTROY_BUILDINGS 0x0020
#define RE_FLAG_UNDISGUISE 0x0040
#define RE_FLAG_UBER_BLOCKS_SPELL 0x0080
new bool:RE_ActiveThisRound;
new bool:RE_CanUse[MAX_PLAYERS_ARRAY];
new RE_Mode[MAX_PLAYERS_ARRAY]; // internal, which of the three rages is this?
new RE_ProjectileEntRef[MAX_PLAYERS_ARRAY]; // how we determine who the projectile struck
//new Float:RE_ProjectileVel[MAX_PLAYERS_ARRAY][3]; // seems the initial push is not working?
//new Float:RE_ProjectileDespawnAt[MAX_PLAYERS_ARRAY]; // sanity check
new RE_OldSpyWeaponIdx[MAX_PLAYERS_ARRAY]; // internal, for spy victims
new RE_OldDemoHeadCount[MAX_PLAYERS_ARRAY]; // internal, for demoman victims (not touching sniper heads since they can't be gained by melee)
new RE_MaxHPOffset[MAX_PLAYERS_ARRAY]; // internal, victim's actual max HP plus this equals equalized max HP
new Float:RE_DamageModifier[MAX_PLAYERS_ARRAY]; // internal, modifier for victim incoming damage while equalized (offsets bonuses/nerfs for KGB and Goomba Scouts)
new Float:RE_EqualizedUntil[MAX_PLAYERS_ARRAY]; // internal
new RE_EqualizedBy[MAX_PLAYERS_ARRAY]; // internal
new Float:RE_ExpectedIntervalTime[MAX_PLAYERS_ARRAY]; // internal
new bool:RE_HadNoMelee[MAX_PLAYERS_ARRAY]; // internal
new Float:RE_OldSpeed[MAX_PLAYERS_ARRAY]; // internal
new RE_OldMaxHP[MAX_PLAYERS_ARRAY]; // internal
new Float:RE_Radius[MAX_PLAYERS_ARRAY]; // arg1
new Float:RE_Duration[MAX_PLAYERS_ARRAY]; // arg2
new RE_MaxHP; // arg3
new Float:RE_MeleeDamage[MAX_PLAYERS_ARRAY]; // arg4
new Float:RE_MeleeInterval[MAX_PLAYERS_ARRAY]; // arg5
new Float:RE_MoveSpeed[MAX_PLAYERS_ARRAY]; // arg6
new Float:RE_ProjectileSpeed[MAX_PLAYERS_ARRAY]; // arg7
new RE_ProjectileRecolor[MAX_PLAYERS_ARRAY]; // arg8
new String:RE_CastingParticle[MAX_EFFECT_NAME_LENGTH]; // arg9
new String:RE_CastingAttachment[MAX_ATTACHMENT_NAME_LENGTH]; // arg10
new String:RE_CastSound[MAX_SOUND_FILE_LENGTH]; // arg17
new String:RE_VictimSound[MAX_SOUND_FILE_LENGTH]; // arg18
new RE_Flags[MAX_PLAYERS_ARRAY]; // arg19

// spell projectile equalize -- interface for MSB
#define SPEI_STRING "spe_interface"
new String:SPEI_Name[MAX_TERMINOLOGY_LENGTH]; // arg3
new String:SPEI_Description[MAX_DESCRIPTION_LENGTH]; // arg4

/**
 * Rage Multi-Spell Base -- Copy over to other plugins that use this.
 *
 * It's gonna be strict, due to space concerns. Methods all subplugins must have:
 * bool:[prefix]_CanInvoke(clientIdx)
 * [prefix]_Invoke(clientIdx)
 * [prefix]_FormatHUDString(String:buffer[], bufferSize, String:format[], Float:rageRequired)
 */
#define MSB_MAX_PREFIX_SIZE 5

/**
 * Rage Multi-Spell Base -- This one is a bit of a doozy, since it uses callbacks.
 */
#define MSB_STRING "rage_multispell_base"
#define MSB_HUD_INTERVAL 0.2
#define MSB_MAX_SPELLS 10
new Handle:MSB_HUDHandle = INVALID_HANDLE;
new Handle:MSB_HUDReplaceHandle = INVALID_HANDLE;
new bool:MSB_ActiveThisRound;
new bool:MSB_CanUse[MAX_PLAYERS_ARRAY];
new MSB_NumSpells[MAX_PLAYERS_ARRAY]; // number of spells currently initialized. due to load order concerns, this can only be initialized on round end and plugin start.
new MSB_CurrentSpell[MAX_PLAYERS_ARRAY]; // internal
new MSB_SpellPackNum[MAX_PLAYERS_ARRAY][MSB_MAX_SPELLS]; // internal, must be initialized by every sub-ability
new String:MSB_SpellPrefix[MAX_PLAYERS_ARRAY][MSB_MAX_SPELLS][MSB_MAX_PREFIX_SIZE]; // internal, must be initialized by every sub-ability
new Float:MSB_SpellCost[MAX_PLAYERS_ARRAY][MSB_MAX_SPELLS]; // internal, must be initialized by every sub-ability
new Float:MSB_SpellCooldown[MAX_PLAYERS_ARRAY][MSB_MAX_SPELLS]; // internal, must be initialized by every sub-ability
new Float:MSB_CooldownEndsAt[MAX_PLAYERS_ARRAY][MSB_MAX_SPELLS]; // internal
new bool:MSB_ActKeyDown[MAX_PLAYERS_ARRAY]; // internal
new bool:MSB_SelKeyDown[MAX_PLAYERS_ARRAY]; // internal
new bool:MSB_ReverseSelKeyDown[MAX_PLAYERS_ARRAY]; // internal
new Float:MSB_UpdateHUDAt[MAX_PLAYERS_ARRAY]; // internal
new bool:MSB_TweakedHUDs[MAX_PLAYERS_ARRAY]; // internal
new bool:MSB_ActivatedByMedic[MAX_PLAYERS_ARRAY]; // internal
new bool:MSB_RageSpent[MAX_PLAYERS_ARRAY]; // internal
new MSB_ActivationKey[MAX_PLAYERS_ARRAY]; // derived from arg1
new MSB_SelectionKey[MAX_PLAYERS_ARRAY]; // derived from arg2
new MSB_ReverseSelectionKey[MAX_PLAYERS_ARRAY]; // derived from arg3
new MSB_HUDUnavailableColor[MAX_PLAYERS_ARRAY]; // arg4
new String:MSB_HUDUnavailableFormat[MAX_CENTER_TEXT_LENGTH]; // arg5
new MSB_HUDAvailableColor[MAX_PLAYERS_ARRAY]; // arg6
new String:MSB_HUDAvailableFormat[MAX_CENTER_TEXT_LENGTH]; // arg7
new Float:MSB_HudY[MAX_PLAYERS_ARRAY]; // arg8
new String:MSB_HUDReplacementFormat[MAX_CENTER_TEXT_LENGTH]; // arg9
new Float:MSB_HUDReplacementY[MAX_PLAYERS_ARRAY]; // arg10
new String:MSB_CastingParticle[MAX_EFFECT_NAME_LENGTH]; // arg11
new String:MSB_CastingAttachment[MAX_ATTACHMENT_NAME_LENGTH]; // arg12

/**
 * Spell Line Explosion
 */
#define SLE_STRING "spell_line_explosion"
#define SLE_TYPE_MIDAIR 0
#define SLE_TYPE_GROUND 1
#define SLE_TYPE_CEILING 2
new bool:SLE_ActiveThisRound;
new bool:SLE_CanUse[MAX_PLAYERS_ARRAY];
new Float:SLE_NextExplosionAt[MAX_PLAYERS_ARRAY]; // internal
new Float:SLE_Angles[MAX_PLAYERS_ARRAY][3]; // internal
new Float:SLE_LastPos[MAX_PLAYERS_ARRAY][3]; // internal
new SLE_ExplosionsLeft[MAX_PLAYERS_ARRAY]; // internal
new SLE_ProjectileEntRef[MAX_PLAYERS_ARRAY]; // internal
new SLE_ContinuationType[MAX_PLAYERS_ARRAY]; // internal, continuation for explosions
// arg1-arg2 are immediately passed on to rage_multispell_base
new String:SLE_Name[MAX_TERMINOLOGY_LENGTH]; // arg3
new String:SLE_Description[MAX_DESCRIPTION_LENGTH]; // arg4
new Float:SLE_Damage[MAX_PLAYERS_ARRAY]; // arg5
new Float:SLE_Radius[MAX_PLAYERS_ARRAY]; // arg6
new Float:SLE_Spacing[MAX_PLAYERS_ARRAY]; // arg7
new Float:SLE_TimeInterval[MAX_PLAYERS_ARRAY]; // arg8
new SLE_MaxExplosions[MAX_PLAYERS_ARRAY]; // arg9 (assuming nothing blocking, it'd always be this number of explosions)
new Float:SLE_MaxZOffset[MAX_PLAYERS_ARRAY]; // arg10 (can also be negative this)
new Float:SLE_ProjectileSpeed[MAX_PLAYERS_ARRAY]; // arg11

/**
 * Spell Repel Shield
 */
#define SRS_STRING "spell_repel_shield"
#define SRS_FLAG_UBER 0x0001
#define SRS_FLAG_INVINCIBILITY 0x0002
#define SRS_FLAG_MEGAHEAL 0x0004
#define SRS_TICK_INTERVAL 0.05
new bool:SRS_ActiveThisRound;
new bool:SRS_CanUse[MAX_PLAYERS_ARRAY];
new Float:SRS_NextTickAt[MAX_PLAYERS_ARRAY]; // internal
new Float:SRS_ActiveUntil[MAX_PLAYERS_ARRAY]; // internal
// arg1-arg2 are immediately passed on to rage_multispell_base
new String:SRS_Name[MAX_TERMINOLOGY_LENGTH]; // arg3
new String:SRS_Description[MAX_DESCRIPTION_LENGTH]; // arg4
new Float:SRS_RepelRadius[MAX_PLAYERS_ARRAY]; // arg5
new Float:SRS_RepelIntensity[MAX_PLAYERS_ARRAY]; // arg6
new Float:SRS_DamageRadius[MAX_PLAYERS_ARRAY]; // arg7
new Float:SRS_DamagePerTick[MAX_PLAYERS_ARRAY]; // arg8
new Float:SRS_Duration[MAX_PLAYERS_ARRAY]; // arg9
new SRS_Flags[MAX_PLAYERS_ARRAY]; // arg19

/**
 * Spell Freeze Escape
 */
#define SFE_STRING "spell_freeze_escape"
#define SFE_FLAG_INVINCIBLE 0x0001
new bool:SFE_ActiveThisRound;
new bool:SFE_CanUse[MAX_PLAYERS_ARRAY];
new SFE_ProjectileEntRef[MAX_PLAYERS_ARRAY]; // internal
new Float:SFE_FreezeEndsAt[MAX_PLAYERS_ARRAY]; // internal, for victims
new Float:SFE_ImmunityEndsAt[MAX_PLAYERS_ARRAY]; // internal, for victims
// arg1-arg2 are immediately passed on to rage_multispell_base
new String:SFE_Name[MAX_TERMINOLOGY_LENGTH]; // arg3
new String:SFE_Description[MAX_DESCRIPTION_LENGTH]; // arg4
new Float:SFE_RadiusConstraint[MAX_PLAYERS_ARRAY]; // arg5
new Float:SFE_FreezeDuration[MAX_PLAYERS_ARRAY]; // arg6
new Float:SFE_ImmunityExtension[MAX_PLAYERS_ARRAY]; // arg7
new Float:SFE_ProjectileSpeed[MAX_PLAYERS_ARRAY]; // arg8
new SFE_Flags[MAX_PLAYERS_ARRAY]; // arg19

/**
 * Medigun: Fake Vaccinator
 */
#define MFV_STRING "medigun_fake_vaccinator"
#define MFV_HUD_INTERVAL 0.2
#define MFV_MEDIGUN_TYPE_UBER 0
#define MFV_MEDIGUN_TYPE_KRITZ 1
#define MFV_MEDIGUN_TYPE_QUICK_FIX 2
#define MFV_MEDIGUN_TYPE_VACCINATOR 3 // error if this is true
new bool:MFV_ActiveThisRound;
new bool:MFV_CanUse[MAX_PLAYERS_ARRAY];
new Handle:MFV_HUDHandle = INVALID_HANDLE;
new Float:MFV_UpdateHUDAt[MAX_PLAYERS_ARRAY]; // internal
new MFV_BuffIdx[MAX_PLAYERS_ARRAY]; // index for last buff
new MFV_LastHealingTarget[MAX_PLAYERS_ARRAY]; // healing target last frame
new bool:MFV_LastUberchargeState[MAX_PLAYERS_ARRAY]; // if true, individual was ubercharged
new bool:MFV_SwitchKeyDown[MAX_PLAYERS_ARRAY]; // internal
new bool:MFV_ReverseSwitchKeyDown[MAX_PLAYERS_ARRAY]; // internal
new bool:MFV_MedicDeathHandled[MAX_PLAYERS_ARRAY]; // internal, if the medic dies before their partner, ensures the buff is removed
new MFV_ModeCount[MAX_PLAYERS_ARRAY]; // arg1
new TFCond:MFV_ModeNormalCondition[MAX_PLAYERS_ARRAY][MAX_CONDITIONS]; // arg2
new TFCond:MFV_ModeUberCondition[MAX_PLAYERS_ARRAY][MAX_CONDITIONS]; // arg3
new String:MFV_UberString[MAX_TERMINOLOGY_LENGTH]; // arg4
new String:MFV_Descriptions[MAX_CONDITIONS][MAX_TERMINOLOGY_LENGTH]; // arg5
new String:MFV_HudFormat[MAX_CENTER_TEXT_LENGTH]; // arg6
new MFV_HudColor[MAX_PLAYERS_ARRAY]; // arg7
new Float:MFV_HudY[MAX_PLAYERS_ARRAY]; // arg8
new MFV_SwitchKey[MAX_PLAYERS_ARRAY]; // arg9
new MFV_BaseMedigunType[MAX_PLAYERS_ARRAY]; // arg10

/**
 * Smart Ally Teleport
 */
#define SAT_STRING "ff2_smart_ally_teleport"
#define SAT_MODE_UNKNOWN -1
#define SAT_MODE_ALLIES_ALIVE 0
#define SAT_MODE_ALLIES_DEAD 1
new bool:SAT_ActiveThisRound;
new bool:SAT_CanUse[MAX_PLAYERS_ARRAY];
new SAT_LastMode[MAX_PLAYERS_ARRAY]; // internal
new Float:SAT_TeleportChargeAlive[MAX_PLAYERS_ARRAY]; // arg1
new Float:SAT_CooldownAlive[MAX_PLAYERS_ARRAY]; // arg2
new bool:SAT_AboveAlive[MAX_PLAYERS_ARRAY]; // arg3
new bool:SAT_SideAlive[MAX_PLAYERS_ARRAY]; // arg4
new Float:SAT_StunAlive[MAX_PLAYERS_ARRAY]; // arg5
new Float:SAT_TeleportChargeDead[MAX_PLAYERS_ARRAY]; // arg11
new Float:SAT_CooldownDead[MAX_PLAYERS_ARRAY]; // arg12
new bool:SAT_AboveDead[MAX_PLAYERS_ARRAY]; // arg13
new bool:SAT_SideDead[MAX_PLAYERS_ARRAY]; // arg14
new Float:SAT_StunDead[MAX_PLAYERS_ARRAY]; // arg15

/**
 * Weapon Selector and WS Specs
 *
 * Note that this rage explicitly cannot be used by two bosses at once. Code will even prevent you from trying.
 */
#define WS_STRING "rage_weapon_selector"
#define WS_HUD_INTERVAL 0.2
#define WS_SPAWN_MODE_NEVER 0
#define WS_SPAWN_MODE_BEFORE 1
#define WS_SPAWN_MODE_AFTER 2
#define WS_FLAG_REPLAY_SOUND_START 0x0001
#define WS_FLAG_REPLAY_SOUND_END 0x0002
#define WS_REPLAY_START_SOUND "replay/enterperformancemode.wav"
#define WS_REPLAY_END_SOUND "replay/exitperformancemode.wav"
#define WS_RELOAD_SOUND "weapons/shotgun_reload.wav"
new bool:WS_ActiveThisRound;
new bool:WS_CanUse[MAX_PLAYERS_ARRAY]; // this is the only thing here (for the hale) that uses MAX_PLAYERS_ARRAY, mainly for uniformity.
new bool:WS_SSKeyDown; // internal
new bool:WS_PSKeyDown; // internal
new WS_SecondarySelected; // internal
new WS_PrimarySelected; // internal
new WS_EquippedSecondary; // internal
new WS_EquippedPrimary; // internal
new Float:WS_SecondaryRemoveAt; // internal
new Float:WS_PrimaryRemoveAt; // internal
new Float:WS_RageEndsAt; // internal
new Float:WS_UpdateHUDAt; // internal
new Float:WS_EndBleedAt[MAX_PLAYERS_ARRAY]; // internal, for victims
new Float:WS_EndFireAt[MAX_PLAYERS_ARRAY]; // internal, for victims
new Handle:WS_HUDHandle = INVALID_HANDLE;
new TFClassType:WS_ActualClass;
new WS_SecondarySelectionKey; // arg1
new WS_PrimarySelectionKey; // arg2
new WS_SecondaryCount; // arg3
new WS_PrimaryCount; // arg4
new Float:WS_Duration; // arg5, has to be altered with time dilation
new Float:WS_TimeDilation; // arg6
new Float:WS_ReloadTime; // arg7, has to be altered with time dilation
new WS_SecondarySpawnMode; // arg8
new WS_PrimarySpawnMode; // arg9
new Float:WS_SecondaryTTL; // arg10
new Float:WS_PrimaryTTL; // arg11
// arg12 overslept and couldn't be here
new WS_HudColor; // arg13
new Float:WS_HudY; // arg14
new String:WS_SecondaryHUD[MAX_CENTER_TEXT_LENGTH]; // arg15
new String:WS_PrimaryHUD[MAX_CENTER_TEXT_LENGTH]; // arg16
new String:WS_EquippedHUD[MAX_CENTER_TEXT_LENGTH]; // arg17
new String:WS_MeleeName[MAX_TERMINOLOGY_LENGTH]; // arg18
new WS_Flags; // arg19

// weapon selector: specs
#define WSS_FORMAT "ws_specs_%d"
#define WSS_MAX_WEAPONS_PER_TYPE 10
#define WSS_SECONDARY_START 0
#define WSS_PRIMARY_START WSS_MAX_WEAPONS_PER_TYPE
#define WSS_MAX_WEAPONS (WSS_MAX_WEAPONS_PER_TYPE * 2)
#define WSS_ARG_OFFSET 10
#define WSS_VIS_TYPE_VISIBLE 0
#define WSS_VIS_TYPE_VIEWMODEL_ONLY 1
#define WSS_VIS_TYPE_INVISIBLE 2
new WSS_LastClipValue[WSS_MAX_WEAPONS]; // internal
new Float:WSS_LastClipValueTime[WSS_MAX_WEAPONS]; // internal
new String:WSS_WeaponName[WSS_MAX_WEAPONS][MAX_WEAPON_NAME_LENGTH]; // arg1 and arg11
new WSS_WeaponIdx[WSS_MAX_WEAPONS]; // arg2 and arg12
new String:WSS_WeaponArgs[WSS_MAX_WEAPONS][MAX_WEAPON_ARG_LENGTH]; // arg3 and arg13
new WSS_VisibilityType[WSS_MAX_WEAPONS]; // arg4 and arg14
new WSS_DefaultClip[WSS_MAX_WEAPONS]; // arg5 and arg15
new WSS_DefaultAmmo[WSS_MAX_WEAPONS]; // arg6 and arg16
new TFClassType:WSS_ClassChange[WSS_MAX_WEAPONS]; // arg7 and arg17
new String:WSS_AestheticName[WSS_MAX_WEAPONS][MAX_TERMINOLOGY_LENGTH]; // arg8 and arg18
new Float:WSS_DOTDuration[WSS_MAX_WEAPONS]; // arg9 and arg19
new bool:WSS_IsSingleReload[WSS_MAX_WEAPONS]; // arg10 and arg20

/**
 * METHODS REQUIRED BY ff2 subplugin
 */
PrintRageWarning()
{
	PrintToServer("*********************************************************************");
	PrintToServer("*                             WARNING                               *");
	PrintToServer("*       DEBUG_FORCE_RAGE in ff2_sarysamods9.sp is set to true!      *");
	PrintToServer("*  Any admin can use the 'rage' command to use rages in this pack!  *");
	PrintToServer("*  This is only for test servers. Disable this on your live server. *");
	PrintToServer("*********************************************************************");
}
 
#define CMD_FORCE_RAGE "rage"
public OnPluginStart2()
{
	// remove from pack10!
	cvarTimeScale = FindConVar("host_timescale");
	cvarCheats = FindConVar("sv_cheats");

	// special initialize here, since this can't be done in RoundStart
	MSB_RemoveSpellsFromAll();
	MSB_HUDHandle = CreateHudSynchronizer();
	MSB_HUDReplaceHandle = CreateHudSynchronizer();
	MFV_HUDHandle = CreateHudSynchronizer();
	WS_HUDHandle = CreateHudSynchronizer();
	
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	PrecacheSound(NOPE_AVI); // DO NOT DELETE IN FUTURE MOD PACKS
	for (new i = 0; i < MAX_PLAYERS_ARRAY; i++) // MAX_PLAYERS_ARRAY is correct here, this one time
		NULL_BLACKLIST[i] = false;
		
	// REMOVE IN PACK10
	RegisterForceTaunt();
	
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
	JP_ActiveThisRound = false;
	SO_ActiveThisRound = false;
	LC_ActiveThisRound = false;
	RI_ActiveThisRound = false;
	RI_IllusionsUntil = FAR_FUTURE;
	MF_ActiveThisRound = false;
	DD_ActiveThisRound = false;
	BH_ActiveThisRound = false;
	RE_ActiveThisRound = false;
	MSB_ActiveThisRound = false;
	SLE_ActiveThisRound = false;
	SRS_ActiveThisRound = false;
	SFE_ActiveThisRound = false;
	MFV_ActiveThisRound = false;
	SAT_ActiveThisRound = false;
	WS_ActiveThisRound = false;
	
	// initialize arrays
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		// all client inits
		JP_CanUse[clientIdx] = false;
		JP_RemoveConditionsAt[clientIdx] = FAR_FUTURE;
		JP_RemoveInvulnAt[clientIdx] = FAR_FUTURE;
		JP_SafeResizeRetryAt[clientIdx] = FAR_FUTURE;
		JP_ModifyingSpeed[clientIdx] = false;
		SO_CanUse[clientIdx] = false;
		LC_IsAffected[clientIdx] = false;
		LC_ParticleEntRef[clientIdx] = INVALID_ENTREF;
		RI_CanUse[clientIdx] = false;
		RI_IllusionOf[clientIdx] = -1;
		RI_EnvironmentImmuneUntil[clientIdx] = 0.0;
		MF_CanUse[clientIdx] = false;
		DD_CanUse[clientIdx] = false;
		BH_CanUse[clientIdx] = false;
		RE_CanUse[clientIdx] = false;
		RE_MaxHPOffset[clientIdx] = 0;
		RE_DamageModifier[clientIdx] = 1.0;
		RE_EqualizedUntil[clientIdx] = FAR_FUTURE;
		MSB_CanUse[clientIdx] = false;
		SLE_CanUse[clientIdx] = false;
		SRS_CanUse[clientIdx] = false;
		SFE_CanUse[clientIdx] = false;
		SFE_FreezeEndsAt[clientIdx] = FAR_FUTURE;
		SFE_ImmunityEndsAt[clientIdx] = FAR_FUTURE;
		MFV_CanUse[clientIdx] = false;
		SAT_CanUse[clientIdx] = false;
		WS_CanUse[clientIdx] = false;
		WS_EndBleedAt[clientIdx] = FAR_FUTURE;
		WS_EndFireAt[clientIdx] = FAR_FUTURE;

		// boss-only inits
		new bossIdx = IsLivingPlayer(clientIdx) ? FF2_GetBossIndex(clientIdx) : -1;
		if (bossIdx < 0)
			continue;

		if (FF2_HasAbility(bossIdx, this_plugin_name, JP_STRING))
		{
			JP_ActiveThisRound = true;
			JP_CanUse[clientIdx] = true;
			JP_RestorePotionAt[clientIdx] = FAR_FUTURE;
			JP_ActiveJarEntRef[clientIdx] = INVALID_ENTREF;
			JP_TestJarEntRef = INVALID_ENTREF;

			JP_RefreshDelay[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, JP_STRING, 1);
			ReadModel(bossIdx, JP_STRING, 2, JP_PotionModel);
			ReadSound(bossIdx, JP_STRING, 3, JP_VictimSound);
			JP_EnemyEffectDuration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, JP_STRING, 4);
			ReadFloatRange(bossIdx, JP_STRING, 5, JP_EnemySizeRange[clientIdx]);
			ReadFloatRange(bossIdx, JP_STRING, 6, JP_EnemyHeadSizeRange[clientIdx]);
			ReadConditions(bossIdx, JP_STRING, 7, JP_EnemyConditions[clientIdx]);
			JP_EnemyConditionChance[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, JP_STRING, 8);
			JP_EnemyPetrificationChance[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, JP_STRING, 9);
			JP_EnemyBumperCarsChance[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, JP_STRING, 10);
			JP_AllyEffectDuration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, JP_STRING, 12);
			ReadConditions(bossIdx, JP_STRING, 13, JP_AllyConditions[clientIdx]);
			ReadConditions(bossIdx, JP_STRING, 14, JP_AllyRemoveConditions[clientIdx]);
			ReadCenterText(bossIdx, JP_STRING, 15, JP_PotionFirstText);
			ReadCenterText(bossIdx, JP_STRING, 16, JP_PotionRefreshText);
			ReadCenterText(bossIdx, JP_STRING, 17, JP_SlayMessage);
			JP_ItemIndex[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, JP_STRING, 18);
			JP_Flags = ReadHexOrDecString(bossIdx, JP_STRING, 19);
			
			PrecacheSound(JP_RECHARGE_SOUND);
		}

		if (FF2_HasAbility(bossIdx, this_plugin_name, SO_STRING))
		{
			SO_ActiveThisRound = true;
			SO_CanUse[clientIdx] = true;
			
			SO_LowSpeed[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SO_STRING, 1);
			SO_HighSpeed[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SO_STRING, 2);
			
			SO_MaxHP[clientIdx] = FF2_GetBossMaxHealth(bossIdx);
		}
		
		if (FF2_HasAbility(bossIdx, this_plugin_name, LC_STRING))
		{
			LC_ActiveThisRound = true;
			LC_MATERIAL_INT = PrecacheModel(LC_MATERIAL);
			
			LC_Duration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, LC_STRING, 1);
			LC_Radius[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, LC_STRING, 2);
			LC_MinDistance[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, LC_STRING, 3);
			LC_BeamColor[clientIdx] = ReadHexOrDecString(bossIdx, LC_STRING, 4);
			LC_AttractionIntensity[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, LC_STRING, 5);
			LC_AttractionInterval[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, LC_STRING, 6);
			LC_DamageIntensity[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, LC_STRING, 7);
			LC_DamageInterval[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, LC_STRING, 8);
			LC_DamageOnMateDeath[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, LC_STRING, 9);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, LC_STRING, 10, LC_EffectName, MAX_EFFECT_NAME_LENGTH);
			LC_BeamInterval[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, LC_STRING, 11);
			ReadCenterText(bossIdx, LC_STRING, 12, LC_AfflictionMessage);
			ReadCenterText(bossIdx, LC_STRING, 13, LC_CureMessage);
			LC_Flags[clientIdx] = ReadHexOrDecString(bossIdx, LC_STRING, 19);
		}

		if (FF2_HasAbility(bossIdx, this_plugin_name, RI_STRING) || FF2_HasAbility(bossIdx, this_plugin_name, DI_STRING))
		{
			RI_ActiveThisRound = true;
			RI_CanUse[clientIdx] = true;
			RI_IsDOT[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, DI_STRING);
			
			static String:abilityName[MAX_ABILITY_NAME_LENGTH];
			abilityName = RI_IsDOT[clientIdx] ? DI_STRING : RI_STRING;
			RI_Duration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 1);
			RI_Radius[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 2);
			RI_IllusionsPerPlayer[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 3);
			ReadModel(bossIdx, abilityName, 4, RI_Model);
			RI_ShouldTeleport[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, abilityName, 5) == 1;
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, abilityName, 6, RI_Particle, MAX_EFFECT_NAME_LENGTH);
			ReadSound(bossIdx, abilityName, 7, RI_Sound);
			RI_ShouldRemoveDOTs[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, abilityName, 8) == 1;
			RI_ShouldMatchGlow[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, abilityName, 9) == 1;
			
			new randomRed = FindRandomPlayer(false);
			if (IsLivingPlayer(randomRed))
				GetEntPropVector(randomRed, Prop_Send, "m_vecOrigin", RI_SafePos);
		}
		
		if (FF2_HasAbility(bossIdx, this_plugin_name, MF_STRING))
		{
			MF_ActiveThisRound = true;
			MF_CanUse[clientIdx] = true;
			MF_SoundPending[clientIdx] = false;
			MF_AmmoRefreshAt[clientIdx] = GetEngineTime() + MF_AMMO_REFRESH_INTERVAL;
			
			MF_MeleeDamageMultiplier[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, MF_STRING, 1);
			MF_AirblastDamage[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, MF_STRING, 2);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, MF_STRING, 3, MF_AirblastParticle, MAX_EFFECT_NAME_LENGTH);
			ReadSound(bossIdx, MF_STRING, 4, MF_AirblastSound);
			MF_AmmoPerSecond[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, MF_STRING, 5);
			MF_MaxAmmo[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, MF_STRING, 6);
			MF_DamageCap[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, MF_STRING, 7);
			MF_AfterburnCap[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, MF_STRING, 8);
			MF_AfterburnDuration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, MF_STRING, 9);
			MF_ParticleDistance[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, MF_STRING, 13);
			MF_Flags[clientIdx] = ReadHexOrDecString(bossIdx, MF_STRING, 19);

			// inits for victims
			for (new victim = 1; victim < MAX_PLAYERS; victim++)
			{
				MF_PendingDamage[victim] = 0.0;
				MF_AfterburnEndsAt[victim] = FAR_FUTURE;
				MF_IgniteAt[victim] = FAR_FUTURE;
				MF_PlayerType[victim] = MF_TYPE_NORMAL;
			}
		}

		if (FF2_HasAbility(bossIdx, this_plugin_name, DD_STRING))
		{
			DD_ActiveThisRound = true;
			DD_CanUse[clientIdx] = true;
			DD_IsUsing[clientIdx] = false;
			
			DD_TauntIndex[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, DD_STRING, 1);
			DD_GemInterval[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DD_STRING, 2);
			DD_GemLifetime[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DD_STRING, 3);
			ReadFloatRange(bossIdx, DD_STRING, 4, DD_GemPitchRange[clientIdx]);
			ReadFloatRange(bossIdx, DD_STRING, 5, DD_GemYawRange[clientIdx]);
			ReadFloatRange(bossIdx, DD_STRING, 6, DD_GemIntensityRange[clientIdx]);
			DD_GemDamage[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DD_STRING, 7);
			DD_GemZOffset[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DD_STRING, 8);
			DD_CollisionRadius[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DD_STRING, 9);
			DD_GoombaDamageMult[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DD_STRING, 10);
			DD_GoombaFactorMult[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DD_STRING, 11);
			DD_GemSolidifyDelay[clientIdx] = 99999.0; //FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DD_STRING, 12);
			DD_TauntInterval[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DD_STRING, 12);
			ReadCenterText(bossIdx, DD_STRING, 13, DD_InAirError);
			ReadModel(bossIdx, DD_STRING, 14, DD_Model);
			ReadSound(bossIdx, DD_STRING, 15, DD_InitialSound);
			DD_SoundDelay = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DD_STRING, 16);
			ReadSound(bossIdx, DD_STRING, 17, DD_LoopingSound);
			DD_SoundInterval = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DD_STRING, 18);
			DD_Flags[clientIdx] = ReadHexOrDecString(bossIdx, DD_STRING, 19);
			
			// no model reskin? no ability
			if (strlen(DD_Model) <= 3)
			{
				PrintToServer("[sarysamods9] ERROR: No model reskin for %s, but one is required. Disabling rage.", DD_STRING);
				DD_ActiveThisRound = false;
				DD_CanUse[clientIdx] = false;
			}
		}
		
		if (FF2_HasAbility(bossIdx, this_plugin_name, BH_STRING) || FF2_HasAbility(bossIdx, this_plugin_name, DBH_STRING))
		{
			BH_ActiveThisRound = true;
			BH_CanUse[clientIdx] = true;
			BH_IsDOT[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, DBH_STRING);
			BH_ProjectileEntRef[clientIdx] = INVALID_ENTREF;
			BH_BlinkReady[clientIdx] = false;
			BH_UpdateHUDAt[clientIdx] = GetEngineTime() + 0.3;
			BH_WithheldRage[clientIdx] = 0.0;
			BH_KeyDown[clientIdx] = false;
			
			static String:abilityName[MAX_ABILITY_NAME_LENGTH];
			abilityName = BH_IsDOT[clientIdx] ? DBH_STRING : BH_STRING;
			BH_RageCost[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 1);
			BH_Damage[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 2);
			BH_Speed[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 3);
			BH_Radius[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 4);
			BH_KeyID[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, abilityName, 5);
			BH_HudY[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 6);
			BH_HudColor[clientIdx] = ReadHexOrDecString(bossIdx, abilityName, 7);
			ReadSound(bossIdx, abilityName, 8, BH_RageSound);
			ReadSound(bossIdx, abilityName, 9, BH_BlinkSound);
			BH_Model[clientIdx] = ReadModelToInt(bossIdx, abilityName, 10);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, abilityName, 11, BH_Particle, MAX_EFFECT_NAME_LENGTH);
			BH_SentryStunDuration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 12);
			BH_SentryStunRadius[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 13);
			BH_ModelRecolor[clientIdx] = ReadHexOrDecString(bossIdx, abilityName, 14);
			ReadCenterText(bossIdx, abilityName, 16, BH_NothingReadyHudText);
			ReadCenterText(bossIdx, abilityName, 17, BH_BlinkReadyHudText);
			ReadCenterText(bossIdx, abilityName, 18, BH_RageReadyHudText);
			BH_Flags[clientIdx] = ReadHexOrDecString(bossIdx, abilityName, 19);
			
			// grab rage cost from DOT plugin, since in this instance it's only used for the HUD
			if (BH_IsDOT[clientIdx] && FF2_HasAbility(bossIdx, "drain_over_time", "dot_base"))
				BH_RageCost[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, "drain_over_time", "dot_base", 1);
		}

		if ((RE_CanUse[clientIdx] = (FF2_HasAbility(bossIdx, this_plugin_name, RE_STRING) || FF2_HasAbility(bossIdx, this_plugin_name, DE_STRING) ||
				FF2_HasAbility(bossIdx, this_plugin_name, DPE_STRING) || FF2_HasAbility(bossIdx, this_plugin_name, SPE_STRING))) == true)
		{
			RE_ActiveThisRound = true;
			RE_ProjectileEntRef[clientIdx] = INVALID_ENTREF;
			RE_Mode[clientIdx] = RE_MODE_RAGE;
			if (FF2_HasAbility(bossIdx, this_plugin_name, DE_STRING))
				RE_Mode[clientIdx] = RE_MODE_DOT;
			else if (FF2_HasAbility(bossIdx, this_plugin_name, DPE_STRING) || FF2_HasAbility(bossIdx, this_plugin_name, SPE_STRING))
				RE_Mode[clientIdx] = RE_MODE_PROJECTILE;
			static String:abilityName[MAX_ABILITY_NAME_LENGTH];
			
			if (RE_Mode[clientIdx] == RE_MODE_DOT)
				abilityName = DE_STRING;
			else if (RE_Mode[clientIdx] == RE_MODE_PROJECTILE)
				abilityName = DPE_STRING;
			else
				abilityName = RE_STRING;
				
			// special things to do for spell projectile equalize
			if (FF2_HasAbility(bossIdx, this_plugin_name, SPE_STRING))
			{
				abilityName = SPE_STRING;
				
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SPEI_STRING, 3, SPEI_Name, MAX_TERMINOLOGY_LENGTH);
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SPEI_STRING, 4, SPEI_Description, MAX_DESCRIPTION_LENGTH);
				MSB_InitSubability(bossIdx, clientIdx, 9, SPEI_STRING, "SPEI");
			}

			RE_Radius[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 1);
			RE_Duration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 2);
			RE_MaxHP = FF2_GetAbilityArgument(bossIdx, this_plugin_name, abilityName, 3);
			RE_MeleeDamage[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 4);
			RE_MeleeInterval[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 5);
			RE_MoveSpeed[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 6);
			RE_ProjectileSpeed[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 7);
			RE_ProjectileRecolor[clientIdx] = ReadHexOrDecString(bossIdx, abilityName, 8);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, abilityName, 9, RE_CastingParticle, MAX_EFFECT_NAME_LENGTH);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, abilityName, 10, RE_CastingAttachment, MAX_ATTACHMENT_NAME_LENGTH);
			ReadSound(bossIdx, abilityName, 17, RE_CastSound);
			ReadSound(bossIdx, abilityName, 18, RE_VictimSound);
			RE_Flags[clientIdx] = ReadHexOrDecString(bossIdx, abilityName, 19);
		}

		if ((MSB_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, MSB_STRING)) == true)
		{
			MSB_ActiveThisRound = true;
			MSB_ActivatedByMedic[clientIdx] = false;
			MSB_RageSpent[clientIdx] = false;
			MSB_UpdateHUDAt[clientIdx] = 0.0;
			MSB_TweakedHUDs[clientIdx] = false;
			
			MSB_ActivationKey[clientIdx] = MSB_GetActionKey(bossIdx, 1);
			MSB_SelectionKey[clientIdx] = MSB_GetActionKey(bossIdx, 2);
			MSB_ReverseSelectionKey[clientIdx] = MSB_GetActionKey(bossIdx, 3);
			MSB_HUDUnavailableColor[clientIdx] = ReadHexOrDecString(bossIdx, MSB_STRING, 4);
			ReadCenterText(bossIdx, MSB_STRING, 5, MSB_HUDUnavailableFormat);
			MSB_HUDAvailableColor[clientIdx] = ReadHexOrDecString(bossIdx, MSB_STRING, 6);
			ReadCenterText(bossIdx, MSB_STRING, 7, MSB_HUDAvailableFormat);
			MSB_HudY[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, MSB_STRING, 8);
			ReadCenterText(bossIdx, MSB_STRING, 9, MSB_HUDReplacementFormat);
			MSB_HUDReplacementY[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, MSB_STRING, 10);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, MSB_STRING, 11, MSB_CastingParticle, MAX_EFFECT_NAME_LENGTH);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, MSB_STRING, 12, MSB_CastingAttachment, MAX_ATTACHMENT_NAME_LENGTH);

			MSB_ActKeyDown[clientIdx] = (GetClientButtons(clientIdx) & MSB_ActivationKey[clientIdx]) != 0;
			MSB_SelKeyDown[clientIdx] = (GetClientButtons(clientIdx) & MSB_SelectionKey[clientIdx]) != 0;
			MSB_ReverseSelKeyDown[clientIdx] = (GetClientButtons(clientIdx) & MSB_ReverseSelectionKey[clientIdx]) != 0;
		}

		if ((SLE_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, SLE_STRING)) == true)
		{
			SLE_ActiveThisRound = true;
			SLE_NextExplosionAt[clientIdx] = FAR_FUTURE;
			SLE_ProjectileEntRef[clientIdx] = INVALID_ENTREF;
			for (new i = 0; i < MSB_MAX_SPELLS; i++)
				MSB_CooldownEndsAt[clientIdx][i] = 0.0;
			
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SLE_STRING, 3, SLE_Name, MAX_TERMINOLOGY_LENGTH);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SLE_STRING, 4, SLE_Description, MAX_DESCRIPTION_LENGTH);
			SLE_Damage[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SLE_STRING, 5);
			SLE_Radius[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SLE_STRING, 6);
			SLE_Spacing[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SLE_STRING, 7);
			SLE_TimeInterval[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SLE_STRING, 8);
			SLE_MaxExplosions[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SLE_STRING, 9);
			SLE_MaxZOffset[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SLE_STRING, 10);
			SLE_ProjectileSpeed[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SLE_STRING, 11);
			ReadSoundWithoutSaving(bossIdx, SLE_STRING, 18);

			// best to do this last, in case any of the above can invalidate this spell
			MSB_InitSubability(bossIdx, clientIdx, 9, SLE_STRING, "SLE");
		}

		if ((SRS_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, SRS_STRING)) == true)
		{
			SRS_ActiveThisRound = true;
			SRS_ActiveUntil[clientIdx] = FAR_FUTURE;

			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SRS_STRING, 3, SRS_Name, MAX_TERMINOLOGY_LENGTH);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SRS_STRING, 4, SRS_Description, MAX_DESCRIPTION_LENGTH);
			SRS_RepelRadius[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SRS_STRING, 5);
			SRS_RepelIntensity[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SRS_STRING, 6);
			SRS_DamageRadius[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SRS_STRING, 7);
			SRS_DamagePerTick[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SRS_STRING, 8);
			SRS_Duration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SRS_STRING, 9);
			ReadSoundWithoutSaving(bossIdx, SRS_STRING, 18);
			SRS_Flags[clientIdx] = ReadHexOrDecString(bossIdx, SRS_STRING, 19);

			// best to do this last, in case any of the above can invalidate this spell
			MSB_InitSubability(bossIdx, clientIdx, 9, SRS_STRING, "SRS");
		}
		
		if ((SFE_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, SFE_STRING)) == true)
		{
			SFE_ActiveThisRound = true;
			SFE_ProjectileEntRef[clientIdx] = INVALID_ENTREF;

			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SFE_STRING, 3, SFE_Name, MAX_TERMINOLOGY_LENGTH);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SFE_STRING, 4, SFE_Description, MAX_DESCRIPTION_LENGTH);
			SFE_RadiusConstraint[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SFE_STRING, 5);
			SFE_FreezeDuration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SFE_STRING, 6);
			SFE_ImmunityExtension[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SFE_STRING, 7);
			SFE_ProjectileSpeed[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SFE_STRING, 8);
			ReadSoundWithoutSaving(bossIdx, SFE_STRING, 18);
			SFE_Flags[clientIdx] = ReadHexOrDecString(bossIdx, SFE_STRING, 19);

			// best to do this last, in case any of the above can invalidate this spell
			MSB_InitSubability(bossIdx, clientIdx, 9, SFE_STRING, "SFE");
		}

		if ((MFV_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, MFV_STRING)) == true)
		{
			MFV_ActiveThisRound = true;
			MFV_BuffIdx[clientIdx] = 0;
			MFV_LastHealingTarget[clientIdx] = -1;
			MFV_MedicDeathHandled[clientIdx] = false;
			MFV_UpdateHUDAt[clientIdx] = GetEngineTime();
			
			MFV_ModeCount[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, MFV_STRING, 1);
			ReadConditions(bossIdx, MFV_STRING, 2, MFV_ModeNormalCondition[clientIdx]);
			ReadConditions(bossIdx, MFV_STRING, 3, MFV_ModeUberCondition[clientIdx]);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, MFV_STRING, 4, MFV_UberString, MAX_TERMINOLOGY_LENGTH);
			static String:descStr[(MAX_TERMINOLOGY_LENGTH + 1) * MAX_CONDITIONS];
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, MFV_STRING, 5, descStr, sizeof(descStr));
			ExplodeString(descStr, ";", MFV_Descriptions, MAX_CONDITIONS, MAX_TERMINOLOGY_LENGTH);
			ReadCenterText(bossIdx, MFV_STRING, 6, MFV_HudFormat);
			MFV_HudColor[clientIdx] = ReadHexOrDecString(bossIdx, MFV_STRING, 7);
			MFV_HudY[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, MFV_STRING, 8);
			MFV_SwitchKey[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, MFV_STRING, 9);
			MFV_BaseMedigunType[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, MFV_STRING, 10);
			
			if (MFV_SwitchKey[clientIdx] == 0)
				MFV_SwitchKey[clientIdx] = IN_RELOAD;
			else
				MFV_SwitchKey[clientIdx] = IN_ATTACK3;
			
			MFV_SwitchKeyDown[clientIdx] = (GetClientButtons(clientIdx) & MFV_SwitchKey[clientIdx]) != 0;
			MFV_ReverseSwitchKeyDown[clientIdx] = (GetClientButtons(clientIdx) & IN_USE) != 0;
			
			if (MFV_ModeCount[clientIdx] >= MAX_CONDITIONS)
			{
				PrintToServer("[sarysamods9] WARNING: Set fake vaccinator mode count to %d, while only %d supported. Clamping.", MFV_ModeCount[clientIdx], MAX_CONDITIONS);
				MFV_ModeCount[clientIdx] = MAX_CONDITIONS;
			}
			
			if (MFV_BaseMedigunType[clientIdx] == MFV_MEDIGUN_TYPE_VACCINATOR || MFV_ModeCount[clientIdx] <= 0)
			{
				if (MFV_ModeCount[clientIdx] <= 0)
					PrintToServer("[sarysamods9] ERROR: No vaccinator modes. (arg1 <= 0) Disabling fake vaccinator.");
				else
					PrintToServer("[sarysamods9] ERROR: Actual vaccinator medigun type not supported. Please set it to be either uber, kritz, or quick fix. Disabling rage.");
				MFV_ActiveThisRound = false;
				MFV_CanUse[clientIdx] = false;
			}
		}

		if ((SAT_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, SAT_STRING)) == true)
		{
			SAT_ActiveThisRound = true;
			SAT_LastMode[clientIdx] = SAT_MODE_UNKNOWN;
			
			SAT_TeleportChargeAlive[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SAT_STRING, 1);
			SAT_CooldownAlive[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SAT_STRING, 2);
			SAT_AboveAlive[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SAT_STRING, 3) != 0;
			SAT_SideAlive[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SAT_STRING, 4) != 0;
			SAT_StunAlive[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SAT_STRING, 5);
			SAT_TeleportChargeDead[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SAT_STRING, 11);
			SAT_CooldownDead[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SAT_STRING, 12);
			SAT_AboveDead[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SAT_STRING, 13) != 0;
			SAT_SideDead[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SAT_STRING, 14) != 0;
			SAT_StunDead[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SAT_STRING, 15);
		}

		if ((WS_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, WS_STRING)) == true)
		{
			if (WS_ActiveThisRound)
			{
				PrintToServer("[sarysamods9] ***********************************************************************");
				PrintToServer("[sarysamods9] ERROR: Two bosses have ability %s, which is not supported.", WS_STRING);
				PrintToServer("[sarysamods9]        Client %d will have the ability disabled.", clientIdx);
				PrintToServer("[sarysamods9] ***********************************************************************");
				WS_CanUse[clientIdx] = false;
			}
			else
			{
				WS_ActiveThisRound = true;
				WS_SecondaryRemoveAt = FAR_FUTURE;
				WS_PrimaryRemoveAt = FAR_FUTURE;
				WS_UpdateHUDAt = GetEngineTime();
				WS_RageEndsAt = FAR_FUTURE;
				WS_SecondarySelected = 0;
				WS_PrimarySelected = 0;
				WS_EquippedSecondary = -1;
				WS_EquippedPrimary = -1;
				WS_ActualClass = TFClass_Unknown;
			
				WS_SecondarySelectionKey = WS_GetActionKey(bossIdx, 1);
				WS_PrimarySelectionKey = WS_GetActionKey(bossIdx, 2);
				WS_SecondaryCount = FF2_GetAbilityArgument(bossIdx, this_plugin_name, WS_STRING, 3);
				WS_PrimaryCount = FF2_GetAbilityArgument(bossIdx, this_plugin_name, WS_STRING, 4);
				WS_Duration = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, WS_STRING, 5);
				WS_TimeDilation = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, WS_STRING, 6);
				WS_ReloadTime = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, WS_STRING, 7);
				WS_SecondarySpawnMode = FF2_GetAbilityArgument(bossIdx, this_plugin_name, WS_STRING, 8);
				WS_PrimarySpawnMode = FF2_GetAbilityArgument(bossIdx, this_plugin_name, WS_STRING, 9);
				WS_SecondaryTTL = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, WS_STRING, 10);
				WS_PrimaryTTL = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, WS_STRING, 11);
				// arg12 called in sick. is actually addicted to GTA V
				WS_HudColor = ReadHexOrDecString(bossIdx, WS_STRING, 13);
				WS_HudY = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, WS_STRING, 14);
				ReadCenterText(bossIdx, WS_STRING, 15, WS_SecondaryHUD);
				ReadCenterText(bossIdx, WS_STRING, 16, WS_PrimaryHUD);
				ReadCenterText(bossIdx, WS_STRING, 17, WS_EquippedHUD);
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, WS_STRING, 18, WS_MeleeName, MAX_TERMINOLOGY_LENGTH);
				WS_Flags = ReadHexOrDecString(bossIdx, WS_STRING, 19);

				WS_SSKeyDown = (GetClientButtons(clientIdx) & WS_SecondarySelectionKey) != 0;
				WS_PSKeyDown = (GetClientButtons(clientIdx) & WS_PrimarySelectionKey) != 0;
				
				if (WS_TimeDilation <= 0.0)
					WS_TimeDilation = 1.0;
				
				// read in weapon specifications
				new primaryCount = 0;
				new secondaryCount = 0;
				for (new i = 0; i < WSS_MAX_WEAPONS_PER_TYPE; i++)
				{
					static String:abilityName[MAX_ABILITY_NAME_LENGTH];
					Format(abilityName, MAX_ABILITY_NAME_LENGTH, WSS_FORMAT, i);
					if (FF2_HasAbility(bossIdx, this_plugin_name, abilityName))
					{
						for (new pass = 0; pass <= 1; pass++)
						{
							// test to see if the pass is valid
							new passOffset = WSS_ARG_OFFSET * pass;
							if (FF2_GetAbilityArgument(bossIdx, this_plugin_name, abilityName, 2 + passOffset) <= 0)
								continue;
						
							new weaponIdx = (WSS_PRIMARY_START * pass) + (pass == 0 ? secondaryCount : primaryCount);
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, abilityName, 1 + passOffset, WSS_WeaponName[weaponIdx], MAX_WEAPON_NAME_LENGTH);
							WSS_WeaponIdx[weaponIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, abilityName, 2 + passOffset);
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, abilityName, 3 + passOffset, WSS_WeaponArgs[weaponIdx], MAX_WEAPON_ARG_LENGTH);
							WSS_VisibilityType[weaponIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, abilityName, 4 + passOffset);
							WSS_DefaultClip[weaponIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, abilityName, 5 + passOffset);
							WSS_DefaultAmmo[weaponIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, abilityName, 6 + passOffset);
							WSS_ClassChange[weaponIdx] = TFClassType:FF2_GetAbilityArgument(bossIdx, this_plugin_name, abilityName, 7 + passOffset);
							FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, abilityName, 8 + passOffset, WSS_AestheticName[weaponIdx], MAX_TERMINOLOGY_LENGTH);
							WSS_DOTDuration[weaponIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, abilityName, 9 + passOffset);
							WSS_IsSingleReload[weaponIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, abilityName, 10 + passOffset) == 1;
							
							if (pass == 0)
								secondaryCount++;
							else
								primaryCount++;
						}
					}
				}
				
				// ensure validity of counts
				if (WS_SecondaryCount > 0 && secondaryCount != WS_SecondaryCount)
				{
					PrintToServer("[sarysamods9] WARNING: Actual number of secondary weapons not equal to limit specified. (actual=%d, specified=%d) Will clamp specified if too high.", secondaryCount, WS_SecondaryCount);
					WS_SecondaryCount = min(secondaryCount, WS_SecondaryCount);
				}
				if (WS_PrimaryCount > 0 && primaryCount != WS_PrimaryCount)
				{
					PrintToServer("[sarysamods9] WARNING: Actual number of secondary weapons not equal to limit specified. (actual=%d, specified=%d) Will clamp specified if too high.", primaryCount, WS_PrimaryCount);
					WS_PrimaryCount = min(primaryCount, WS_PrimaryCount);
				}
				
				// after weapon specs are read, ensure spawn mode makes sense based on availability
				if (WS_SecondarySpawnMode != WS_SPAWN_MODE_NEVER && WS_SecondaryCount <= 0)
				{
					PrintToServer("[sarysamods9] WARNING: Spawn mode for secondary is not never but count is zero. Disabling secondary.");
					WS_SecondarySpawnMode = WS_SPAWN_MODE_NEVER;
				}
				if (WS_PrimarySpawnMode != WS_SPAWN_MODE_NEVER && WS_PrimaryCount <= 0)
				{
					PrintToServer("[sarysamods9] WARNING: Spawn mode for primary is not never but count is zero. Disabling primary.");
					WS_PrimarySpawnMode = WS_SPAWN_MODE_NEVER;
				}

				// precache sounds
				PrecacheSound(WS_REPLAY_START_SOUND);
				PrecacheSound(WS_REPLAY_END_SOUND);
				PrecacheSound(WS_RELOAD_SOUND);
			}
		}
	}
	
	if (JP_ActiveThisRound)
	{
		if (JP_Flags & JP_FLAG_FUNNY_VOICES)
			AddNormalSoundHook(JP_FunnyVoices);
	}
	
	if (SO_ActiveThisRound)
	{
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsLivingPlayer(clientIdx) && SO_CanUse[clientIdx])
				SDKHook(clientIdx, SDKHook_PreThink, SO_PreThink);
		}
	}
	
	if (RI_ActiveThisRound)
	{
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsLivingPlayer(clientIdx) && GetClientTeam(clientIdx) == MercTeam)
				SDKHook(clientIdx, SDKHook_OnTakeDamage, RI_OnTakeDamage);
		}
	}
	
	if (MF_ActiveThisRound)
	{
		HookEvent("object_deflected", MF_OnDeflect, EventHookMode_Pre);
		
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsClientInGame(clientIdx))
			{
				SDKHook(clientIdx, SDKHook_OnTakeDamage, MF_OnTakeDamage);
				SDKHook(clientIdx, SDKHook_OnTakeDamagePost, MF_OnTakeDamagePost);
			}
		}
	}
	
	if (DD_ActiveThisRound)
		DD_Initialize();
		
	if (BH_ActiveThisRound)
		BH_Initialize();
		
	if (RE_ActiveThisRound)
	{
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsClientInGame(clientIdx))
			{
				SDKHook(clientIdx, SDKHook_OnTakeDamage, RE_OnTakeDamage);
				SDKHook(clientIdx, SDKHook_OnTakeDamagePost, RE_OnTakeDamagePost);
			}
		}
		
		AddCommandListener(RE_BlockedCommands, "build");
		AddCommandListener(RE_BlockedCommands, "destroy");
	}
	
	if (MSB_ActiveThisRound)
		AddCommandListener(MSB_MedicCommand, "voicemenu");
		
	if (SLE_ActiveThisRound)
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
			if (IsClientInGame(clientIdx))
				SDKHook(clientIdx, SDKHook_OnTakeDamage, SLE_OnTakeDamage);
	
	if (SFE_ActiveThisRound)
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
			if (IsClientInGame(clientIdx))
				SDKHook(clientIdx, SDKHook_OnTakeDamage, SFE_OnTakeDamage);
				
	if (MFV_ActiveThisRound)
		HookEvent("player_death", MFV_PlayerDeath, EventHookMode_Pre);

	if (WS_ActiveThisRound)
	{
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsClientInGame(clientIdx))
			{
				SDKHook(clientIdx, SDKHook_OnTakeDamage, WS_OnTakeDamage);
				SDKHook(clientIdx, SDKHook_OnTakeDamagePost, WS_OnTakeDamagePost);
			}
		}
		HookEvent("player_death", WS_PlayerDeath, EventHookMode_Pre);
	}
	
	CreateTimer(0.3, Timer_PostRoundStartInits, _, TIMER_FLAG_NO_MAPCHANGE);
}

#define PROVIDE_ON_ACTIVE 128
#define MELEE_DAMAGE_INCREASE 206
#define ALL_DAMAGE_INCREASE 412
public Action:Timer_PostRoundStartInits(Handle:timer)
{
	// hale suicided
	if (!RoundInProgress)
		return Plugin_Handled;
	
	// finish initialization of stuff
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx))
			continue;
		
		// special potential victim inits for initialize
		if (RE_ActiveThisRound)
		{
			if (GetClientTeam(clientIdx) != BossTeam)
			{
				// get the max HP offset
				new maxHP = GetEntProp(clientIdx, Prop_Data, "m_iMaxHealth");
				RE_MaxHPOffset[clientIdx] = RE_MaxHP - maxHP;
					
				// getting their damage modifiers. will grab overall and melee.
				// yes I'm aware that melee tweaks may be invalid. I'm letting it slide in this case.
				new Float:modifier = 1.0;
				for (new pass = 0; pass <= 2; pass++)
				{
					new weapon = GetPlayerWeaponSlot(clientIdx, pass);
					if (!IsValidEntity(weapon))
						continue;

					// only accept provide on active from melee weapons
					if (GetWeaponAttribute(weapon, PROVIDE_ON_ACTIVE, 0.0) && pass != 2)
						continue;

					modifier *= GetWeaponAttribute(weapon, ALL_DAMAGE_INCREASE, 1.0);
					modifier *= GetWeaponAttribute(weapon, MELEE_DAMAGE_INCREASE, 1.0);
				}
				
				if (modifier <= 0.0)
				{
					PrintToServer("[sarysamods9] WARNING: Incoming damage modifier for %d somehow zero or below. Will not modify damage for this user while equalized.");
					modifier = 1.0;
				}
				RE_DamageModifier[clientIdx] = 1.0 / modifier;

				// ensure accuracy during development
				if (PRINT_DEBUG_SPAM)
					PrintToServer("[sarysamods9] For %d, max HP is %d and equalize HP offset is %d. Damage modifier is %f", clientIdx, maxHP, RE_MaxHPOffset[clientIdx], RE_DamageModifier[clientIdx]);
			}
		}
		
		if (GetClientTeam(clientIdx) != BossTeam)
			continue;
		new bossIdx = IsLivingPlayer(clientIdx) ? FF2_GetBossIndex(clientIdx) : -1;
		if (bossIdx < 0)
			continue;
		
		if (BH_CanUse[clientIdx] && !(BH_IsDOT[clientIdx] || BH_KeyID[clientIdx] != BH_KEY_MEDIC))
		{
			FF2_SetFF2flags(clientIdx, FF2_GetFF2flags(clientIdx) | FF2FLAG_HUDDISABLED);
			DD_SetForceHUDEnabled(clientIdx, true);
		}

		if (JP_CanUse[clientIdx])
		{
			// one attribute: refresh delay
			static String:attributes[32];
			Format(attributes, sizeof(attributes), "56 ; 1.0 ; 292 ; 4.0 ; 278 ; %f", JP_RefreshDelay[clientIdx] / 20.0);
			new bool:isMilk = (JP_ItemIndex[clientIdx] == 222 || JP_ItemIndex[clientIdx] == 1121);
			//new bool:isMilk = TF2_GetPlayerClass(clientIdx) == TFClass_Scout;
			new jarate = SpawnWeapon(clientIdx, (isMilk ? "tf_weapon_jar_milk" : "tf_weapon_jar"), JP_ItemIndex[clientIdx], 101, 5, attributes, (JP_Flags & JP_FLAG_JARATE_VISIBLE));
			if (IsValidEntity(jarate))
			{
				new offset = GetEntProp(jarate, Prop_Send, "m_iPrimaryAmmoType", 1);
				if (offset < 0)
				{
					PrintToServer("[sarysamods9] ERROR: Could not find necessary offset for enabling jar.");
					continue;
				}
				SetEntProp(clientIdx, Prop_Send, "m_iAmmo", 1, 4, offset);

				// inform the player
				PrintCenterText(clientIdx, JP_PotionFirstText);
			}
			else
				PrintToServer("[sarysamods9] ERROR: Jar item not valid. (isMilk=%d   itemIdx=%d)", isMilk, JP_ItemIndex[clientIdx]);

		}

		if (MF_CanUse[clientIdx])
		{
			new quality = ((MF_Flags[clientIdx] & MF_FLAG_STRANGE_FLAMETHROWER) != 0) ? 11 : 5;

			static String:weaponArgs[MAX_WEAPON_ARG_LENGTH];
			new weaponIdx = FF2_GetAbilityArgument(bossIdx, this_plugin_name, MF_STRING, 10);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, MF_STRING, 11, weaponArgs, MAX_WEAPON_ARG_LENGTH);
			new flamethrower = SpawnWeapon(clientIdx, "tf_weapon_flamethrower", weaponIdx, 101, quality, weaponArgs, any:((MF_Flags[clientIdx] & MF_FLAG_VISIBLE) != 0));
			if (IsValidEntity(flamethrower))
			{
				new offset = GetEntProp(flamethrower, Prop_Send, "m_iPrimaryAmmoType", 1);
				if (offset < 0)
					continue;
				SetEntProp(clientIdx, Prop_Send, "m_iAmmo", MF_MaxAmmo[clientIdx], 4, offset);

				// hide the flamethrower
				if (MF_Flags[clientIdx] & MF_FLAG_ZERO_ALPHA_FLAMETHROWER)
				{
					SetEntityRenderMode(flamethrower, RENDER_TRANSCOLOR);
					SetEntityRenderColor(flamethrower, 0, 0, 0, 0);
				}

				// make melee the default
				new melee = GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Melee);
				if (IsValidEntity(melee))
					SetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon", melee);
			}

			// message to player
			static String:introMessage[MAX_CENTER_TEXT_LENGTH];
			ReadCenterText(bossIdx, MF_STRING, 12, introMessage);
			if (!IsEmptyString(introMessage))
			{
				PrintCenterText(clientIdx, introMessage);
				PrintToChat(clientIdx, introMessage);
			}

			// get victims' player types now, for the dead ringer workaround
			// can't do it immediately on round start because some players may still be on wrong team
			for (new victim = 1; victim < MAX_PLAYERS; victim++)
			{
				if (!IsLivingPlayer(victim) || GetClientTeam(victim) == BossTeam)
					MF_PlayerType[victim] = MF_TYPE_NORMAL;
				else if (TF2_GetPlayerClass(victim) != TFClass_Spy)
					MF_PlayerType[victim] = MF_TYPE_NORMAL;
				else
				{
					new cloak = GetPlayerWeaponSlot(victim, 4);
					if (!IsValidEntity(cloak))
						MF_PlayerType[victim] = MF_TYPE_NORMAL;
					else
					{
						new cloakIdx = GetEntProp(cloak, Prop_Send, "m_iItemDefinitionIndex");
						if (cloakIdx == 59)
							MF_PlayerType[victim] = ((MF_Flags[clientIdx] & MF_FLAG_DEAD_RINGER_WORKAROUND) != 0) ? MF_TYPE_DEAD_RINGER : MF_TYPE_NORMAL;
						else
							MF_PlayerType[victim] = ((MF_Flags[clientIdx] & MF_FLAG_INVIS_WATCH_WORKAROUND) != 0) ? MF_TYPE_INVIS_WATCH : MF_TYPE_NORMAL;
					}
				}
			}
		}
		
		if (WS_CanUse[clientIdx])
			WS_ActualClass = TF2_GetPlayerClass(clientIdx);
	}

	return Plugin_Handled;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundInProgress = false;
	
	// special initialize here, since this can't be done in RoundStart
	MSB_RemoveSpellsFromAll();
	
	if (JP_ActiveThisRound)
	{
		JP_ActiveThisRound = false;
		
		RemoveNormalSoundHook(JP_FunnyVoices);
		
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (!IsLivingPlayer(clientIdx))
				continue;
				
			if (GetClientTeam(clientIdx) == MercTeam)
				JP_RemoveVictimConditions(clientIdx, GetEngineTime());
		}
	}

	if (SO_ActiveThisRound)
	{
		SO_ActiveThisRound = false;
		
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsClientInGame(clientIdx) && SO_CanUse[clientIdx])
				SDKUnhook(clientIdx, SDKHook_PreThink, SO_PreThink);
		}
	}
	
	if (LC_ActiveThisRound)
	{
		LC_ActiveThisRound = false;
		
		for (new victim = 1; victim < MAX_PLAYERS; victim++)
		{
			if (LC_IsAffected[victim])
				LC_RemoveCurse(victim);
		}
	}
	
	if (RI_ActiveThisRound)
	{
		RI_ActiveThisRound = false;
	
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsClientInGame(clientIdx))
				SDKUnhook(clientIdx, SDKHook_OnTakeDamage, RI_OnTakeDamage);
		}
	}

	if (MF_ActiveThisRound)
	{
		MF_ActiveThisRound = false;
		UnhookEvent("object_deflected", MF_OnDeflect, EventHookMode_Pre);
		
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsClientInGame(clientIdx))
			{
				SDKUnhook(clientIdx, SDKHook_OnTakeDamage, MF_OnTakeDamage);
				SDKUnhook(clientIdx, SDKHook_OnTakeDamagePost, MF_OnTakeDamagePost);
			}
		}
	}
	
	if (DD_ActiveThisRound)
		DD_Cleanup();
		
	if (BH_ActiveThisRound)
		BH_Cleanup();

	if (RE_ActiveThisRound)
	{
		RE_ActiveThisRound = false;
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsClientInGame(clientIdx))
			{
				SDKUnhook(clientIdx, SDKHook_OnTakeDamage, RE_OnTakeDamage);
				SDKUnhook(clientIdx, SDKHook_OnTakeDamagePost, RE_OnTakeDamagePost);
			}
		}
		
		RemoveCommandListener(RE_BlockedCommands, "build");
		RemoveCommandListener(RE_BlockedCommands, "destroy");
	}

	if (MSB_ActiveThisRound)
	{
		MSB_ActiveThisRound = false;
		RemoveCommandListener(MSB_MedicCommand, "voicemenu");
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
			FF2_SetFF2flags(clientIdx, FF2_GetFF2flags(clientIdx) & (~FF2FLAG_HUDDISABLED));
	}

	if (SLE_ActiveThisRound)
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
			if (IsClientInGame(clientIdx))
				SDKUnhook(clientIdx, SDKHook_OnTakeDamage, SLE_OnTakeDamage);	
	
	if (SFE_ActiveThisRound)
	{
		SFE_ActiveThisRound = false;
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsClientInGame(clientIdx))
				SDKUnhook(clientIdx, SDKHook_OnTakeDamage, SFE_OnTakeDamage);
		
			if (IsLivingPlayer(clientIdx))
			{
				SetEntityRenderMode(clientIdx, RENDER_TRANSCOLOR);
				SetEntityRenderColor(clientIdx, 255, 255, 255, 255);
				if (TF2_IsPlayerInCondition(clientIdx, TFCond_Dazed))
					TF2_RemoveCondition(clientIdx, TFCond_Dazed);
			}
		}
	}

	if (MFV_ActiveThisRound)
	{
		MFV_ActiveThisRound = false;
		UnhookEvent("player_death", MFV_PlayerDeath, EventHookMode_Pre);
	}

	if (WS_ActiveThisRound)
	{
		WS_ActiveThisRound = false;
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsClientInGame(clientIdx))
			{
				SDKUnhook(clientIdx, SDKHook_OnTakeDamage, WS_OnTakeDamage);
				SDKUnhook(clientIdx, SDKHook_OnTakeDamagePost, WS_OnTakeDamagePost);
			}
		}
		UnhookEvent("player_death", WS_PlayerDeath, EventHookMode_Pre);
		WS_RemoveTimeDilation();
	}
	
}

public Action:FF2_OnAbility2(bossIdx, const String:plugin_name[], const String:ability_name[], status)
{
	if (strcmp(plugin_name, this_plugin_name) != 0)
		return Plugin_Continue;
	else if (!RoundInProgress) // don't execute these rages with 0 players alive
		return Plugin_Continue;
		
	if (!strcmp(ability_name, LC_STRING))
	{
		if (PRINT_DEBUG_INFO)
			PrintToServer("[sarysamods9] Initiating Love Curse");

		Rage_LoveCurse(GetClientOfUserId(FF2_GetBossUserId(bossIdx)));
	}
	else if (!strcmp(ability_name, BH_STRING))
	{
		if (PRINT_DEBUG_INFO)
			PrintToServer("[sarysamods9] Initiating Blink Hadouken (FF2 caught it rather than this mod)");

		Rage_BlinkHadouken(GetClientOfUserId(FF2_GetBossUserId(bossIdx)));
	}
	else if (!strcmp(ability_name, RE_STRING))
	{
		if (PRINT_DEBUG_INFO)
			PrintToServer("[sarysamods9] Initiating Equalize");

		Rage_Equalize(GetClientOfUserId(FF2_GetBossUserId(bossIdx)));
	}
	else if (!strcmp(ability_name, MSB_STRING))
	{
		Rage_MultiSpellBase(GetClientOfUserId(FF2_GetBossUserId(bossIdx)));
	}
	else if (!strcmp(ability_name, WS_STRING))
	{
		if (PRINT_DEBUG_INFO)
			PrintToServer("[sarysamods9] Initiating Weapon Selector");

		Rage_WeaponSelector(GetClientOfUserId(FF2_GetBossUserId(bossIdx)));
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
	
	if (!strcmp("jarate", unparsedArgs))
	{
		JP_HandleJarated(GetClientOfUserId(FF2_GetBossUserId(0)), user, GetEngineTime());
		PrintToConsole(user, "Jarateing self.");
		
		return Plugin_Handled;
	}
	else if (!strcmp("lovecurse", unparsedArgs))
	{
		Rage_LoveCurse(GetClientOfUserId(FF2_GetBossUserId(0)));
		PrintToConsole(user, "love curse rage");
		
		return Plugin_Handled;
	}
	else if (!strcmp("equalize", unparsedArgs))
	{
		Rage_Equalize(GetClientOfUserId(FF2_GetBossUserId(0)));
		PrintToConsole(user, "equalize rage");
		
		return Plugin_Handled;
	}
	else if (!strcmp("dpe", unparsedArgs))
	{
		RE_OnDPActivate(GetClientOfUserId(FF2_GetBossUserId(0)));
		PrintToConsole(user, "equalize pewpew");
		
		return Plugin_Handled;
	}
	
	PrintToServer("[sarysamods9] Rage not found: %s", unparsedArgs);
	return Plugin_Continue;
}

/**
 * DOTs
 */
DOTPostRoundStartInit()
{
	if (!RoundInProgress)
	{
		PrintToServer("DOTPostRoundStartInit() called when the round is over?! Shouldn't be possible!");
		return;
	}
	
	// nothing to do
}
 
OnDOTAbilityActivated(clientIdx)
{
	if (RI_CanUse[clientIdx] && RI_IsDOT[clientIdx])
	{
		if (!RI_InitIllusions(clientIdx))
		{
			CancelDOTAbilityActivation(clientIdx);
			Nope(clientIdx);
		}
	}

	if (DD_CanUse[clientIdx])
	{
		if (!DD_OnActivate(clientIdx))
		{
			CancelDOTAbilityActivation(clientIdx);
			Nope(clientIdx);
		}
	}
	
	if (BH_CanUse[clientIdx] && BH_IsDOT[clientIdx])
	{
		if ((BH_Flags[clientIdx] & BH_FLAG_UNUSABLE_WHILE_STUNNED) && TF2_IsPlayerInCondition(clientIdx, TFCond_Dazed))
		{
			CancelDOTAbilityActivation(clientIdx);
			Nope(clientIdx);
			return;
		}
	
		BH_CreateHadouken(clientIdx);
		
		if (PRINT_DEBUG_INFO)
			PrintToServer("[sarysamods9] Initiating Blink Hadouken. (DOT version)");
	}

	if (RE_CanUse[clientIdx] && RE_Mode[clientIdx] == RE_MODE_DOT)
		RE_OnDOTActivate(clientIdx);
	else if (RE_CanUse[clientIdx] && RE_Mode[clientIdx] == RE_MODE_PROJECTILE)
		RE_OnDPActivate(clientIdx);
}

OnDOTAbilityDeactivated(clientIdx)
{
	if (DD_CanUse[clientIdx])
	{
		DD_OnDeactivate(clientIdx);
	}
	
	if (BH_CanUse[clientIdx] && BH_IsDOT[clientIdx])
	{	
		BH_Blink(clientIdx, true, true);
	}

	if (RE_CanUse[clientIdx] && RE_Mode[clientIdx] == RE_MODE_DOT)
		RE_OnDOTDeactivate(clientIdx);
}

OnDOTUserDeath(clientIdx, isInGame)
{
	// suppress
	if (clientIdx || isInGame) { }
}

Action:OnDOTAbilityTick(clientIdx, tickCount)
{	
	if (RI_CanUse[clientIdx] && RI_IsDOT[clientIdx])
	{
		ForceDOTAbilityDeactivation(clientIdx);
		return;
	}

	if (RE_CanUse[clientIdx] && RE_Mode[clientIdx] == RE_MODE_DOT)
		RE_OnDOTTick(clientIdx);
	else if (RE_CanUse[clientIdx] && RE_Mode[clientIdx] == RE_MODE_PROJECTILE)
		RE_OnDPTick(clientIdx);

	// suppress
	if (tickCount) { }
}

/**
 * Jarate Potion
 */
public JP_OnEntityCreated(entity, const String:classname[])
{
	if (StrContains(classname, "tf_projectile_jar") == 0) // will catch normal jarate and milk
		JP_TestJarEntRef = EntIndexToEntRef(entity);
}

public JP_HandleJarated(bossClientIdx, victim, Float:curTime) // back to bossClientIdx JUST THIS ONCE, would be too fucking confusing otherwise.
{
	new conditionCount = 0;

	if (GetClientTeam(victim) == MercTeam)
	{
		// bumper cars trumps all, but petrify trumps conditions
		new bool:bumperCars = (GetRandomFloat(0.0, 100.0) < JP_EnemyBumperCarsChance[bossClientIdx]);
		new bool:petrify = (GetRandomFloat(0.0, 100.0) < JP_EnemyPetrificationChance[bossClientIdx]);
		
		// remove existing conditions, no bumper cars or petrify on fail
		if (JP_RemoveConditionsAt[victim] != FAR_FUTURE)
		{
			if (!JP_RemoveVictimConditions(victim, curTime))
				bumperCars = petrify = false;
			JP_RemoveNeutralConditions(victim);
		}
		
		// reset, so sounds aren't wrong for petrify/bumper cars
		JP_HeadScale[victim] = 1.0;
		JP_TargetSize[victim] = 1.0;
		
		if (bumperCars)
		{
			TF2_AddCondition(victim, TFCond:82, -1.0);
			JP_Conditions[victim][conditionCount] = TFCond:82;
			conditionCount++;
		}
		else if (petrify)
		{
			TF2_AddCondition(victim, TFCond_Stealthed, -1.0);
			SetEntProp(victim, Prop_Data, "m_takedamage", 0);
			CreateRagdoll(victim, JP_EnemyEffectDuration[bossClientIdx]);
			TF2_StunPlayer(victim, JP_EnemyEffectDuration[bossClientIdx], 0.0, TF_STUNFLAG_BONKSTUCK | TF_STUNFLAG_NOSOUNDOREFFECT);
			JP_RemoveInvulnAt[victim] = curTime + JP_EnemyEffectDuration[bossClientIdx];
			if (JP_Flags & JP_FLAG_FROZEN_GRACE_PERIOD)
				JP_RemoveInvulnAt[victim] += 1.0;
		}
		else
		{
			// random head scale
			JP_HeadScale[victim] = GetRandomFloat(JP_EnemyHeadSizeRange[bossClientIdx][0], JP_EnemyHeadSizeRange[bossClientIdx][1]);
			SetEntPropFloat(victim, Prop_Send, "m_flHeadScale", JP_HeadScale[victim]);
			
			// random body scale
			JP_TargetSize[victim] = GetRandomFloat(JP_EnemySizeRange[bossClientIdx][0], JP_EnemySizeRange[bossClientIdx][1]);
			if (!AttemptResize(victim, false, JP_TargetSize[victim]))
			{
				JP_SafeResizeRetryAt[victim] = curTime + 0.1;
				JP_SafeResizeShouldSlayAt[victim] = FAR_FUTURE; // no slay for temporary resize
				JP_SlayMessageNext[victim] = 0;
			}
			
			// queue modification of speed
			if (((JP_Flags & JP_FLAG_RELATIVE_SLOW) != 0 && JP_TargetSize[victim] < 1.0) || ((JP_Flags & JP_FLAG_RELATIVE_FAST) != 0 && JP_TargetSize[victim] > 1.0))
			{
				JP_ModifyingSpeed[victim] = true;
				JP_ExpectedSpeed[victim] = 0.0;
			}
			
			// random conditions
			for (new i = 0; i < MAX_CONDITIONS; i++)
			{
				if (JP_EnemyConditions[bossClientIdx][i] == TFCond:0)
					break;
				if (GetRandomFloat(0.0, 100.0) > JP_EnemyConditionChance[bossClientIdx])
				{
					JP_Conditions[victim][conditionCount] = JP_EnemyConditions[bossClientIdx][i];
					TF2_AddCondition(victim, JP_Conditions[victim][conditionCount], -1.0);
					conditionCount++;
				}
			}
		}
		
		// sound file
		if (strlen(JP_VictimSound) > 3)
			EmitSoundToClient(victim, JP_VictimSound);
		
		// remove at
		JP_RemoveConditionsAt[victim] = curTime + JP_EnemyEffectDuration[bossClientIdx];
	}
	else if (GetClientTeam(victim) == BossTeam)
	{
		// conditions to add (not random)
		for (new i = 0; i < MAX_CONDITIONS; i++)
		{
			if (JP_AllyConditions[bossClientIdx][i] == TFCond:0)
				break;
			JP_Conditions[victim][conditionCount] = JP_AllyConditions[bossClientIdx][i];
			TF2_AddCondition(victim, JP_Conditions[victim][conditionCount], -1.0);
			conditionCount++;
		}
		
		// negative conditions to remove
		for (new i = 0; i < MAX_CONDITIONS; i++)
		{
			if (JP_AllyRemoveConditions[bossClientIdx][i] == TFCond:0)
				break;
				
			if (TF2_IsPlayerInCondition(victim, JP_AllyRemoveConditions[bossClientIdx][i]))
				TF2_RemoveCondition(victim, JP_AllyRemoveConditions[bossClientIdx][i]);
		}
		
		// remove buffs at
		JP_RemoveConditionsAt[victim] = curTime + JP_AllyEffectDuration[bossClientIdx];
	}
	
	for (new i = conditionCount; i < MAX_CONDITIONS; i++)
		JP_Conditions[victim][i] = TFCond:0;
}

public Action:JP_FunnyVoices(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &clientIdx, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (JP_ActiveThisRound && clientIdx > 0 && clientIdx < MAX_PLAYERS && channel == SNDCHAN_VOICE)
	{
		new Float:trueHeadScale = JP_TargetSize[clientIdx] * JP_HeadScale[clientIdx];
		if (trueHeadScale != 1.0 && trueHeadScale > 0.0 && JP_RemoveConditionsAt[clientIdx] != FAR_FUTURE)
		{
			// 400 (two octaves up) and 25 (two octaves down) are as far as voices can go without sounding like shit
			// and really, that's ear of the beholder. heh. most people would not argue 200/50...
			pitch = max(min(RoundToNearest(100 * (1.0 / trueHeadScale)), 250), 25);
			flags |= SND_CHANGEPITCH;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public bool:JP_RemoveVictimConditions(clientIdx, Float:curTime)
{
	new bool:result = true;
	
	// fix speed now
	if (JP_ModifyingSpeed[clientIdx])
	{
		JP_ModifyingSpeed[clientIdx] = false;
		new Float:curSpeed = GetEntPropFloat(clientIdx, Prop_Send, "m_flMaxspeed");
		if (curSpeed == JP_ExpectedSpeed[clientIdx] && JP_TargetSize[clientIdx] > 0.0 && JP_TargetSize[clientIdx] != 1.0)
		{
			curSpeed /= JP_TargetSize[clientIdx];
			SetEntPropFloat(clientIdx, Prop_Send, "m_flMaxspeed", curSpeed);
		}
	}
	
	if (TF2_IsPlayerInCondition(clientIdx, TFCond_Stealthed))
		TF2_RemoveCondition(clientIdx, TFCond_Stealthed);
	if (TF2_IsPlayerInCondition(clientIdx, TFCond_Dazed))
		TF2_RemoveCondition(clientIdx, TFCond_Dazed);
	if (!(result = AttemptResize(clientIdx, false, 1.0)))
	{
		JP_SafeResizeRetryAt[clientIdx] = curTime + 0.1;
		JP_SafeResizeShouldSlayAt[clientIdx] = curTime + 20.0;
		JP_SlayMessageNext[clientIdx] = 20;
		JP_TargetSize[clientIdx] = 1.0;
	}

	SetEntPropFloat(clientIdx, Prop_Send, "m_flHeadScale", 1.0);
	return result;
}

public JP_RemoveNeutralConditions(clientIdx)
{
	for (new i = 0; i < MAX_CONDITIONS; i++)
	{
		if (JP_Conditions[clientIdx][i] > TFCond:0 && TF2_IsPlayerInCondition(clientIdx, JP_Conditions[clientIdx][i]))
			TF2_RemoveCondition(clientIdx, JP_Conditions[clientIdx][i]);
	}

	JP_RemoveConditionsAt[clientIdx] = FAR_FUTURE;
}

public JP_Tick(Float:curTime)
{
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx))
			continue;
	
		if (GetClientTeam(clientIdx) == BossTeam)
		{
			// manage the potion, since recharge stat doesn't seem to work properly
			new jarate = GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Secondary);
			if (JP_CanUse[clientIdx] && IsValidEntity(jarate))
			{
				new offset = GetEntProp(jarate, Prop_Send, "m_iPrimaryAmmoType", 1);
				if (offset >= 0)
				{
					new ammo = GetEntProp(clientIdx, Prop_Send, "m_iAmmo", 4, offset);
					if (JP_RestorePotionAt[clientIdx] == FAR_FUTURE)
					{
						// this may never happen, or this may result from my meddling with ammo
						if (ammo > 1)
						{
							if (PRINT_DEBUG_INFO)
								PrintToServer("[sarysamods9] Note: Jar ammo went above 1, but will be lowered.");
							SetEntProp(clientIdx, Prop_Send, "m_iAmmo", 1, 4, offset);
						}
						else if (ammo == 0)
							JP_RestorePotionAt[clientIdx] = curTime + JP_RefreshDelay[clientIdx];
					}
					else if (curTime >= JP_RestorePotionAt[clientIdx])
					{
						SetEntProp(clientIdx, Prop_Send, "m_iAmmo", 1, 4, offset);
						JP_RestorePotionAt[clientIdx] = FAR_FUTURE;
						
						// inform the player
						PrintCenterText(clientIdx, JP_PotionRefreshText);
						EmitSoundToClient(clientIdx, JP_RECHARGE_SOUND); // this sound is lost when jar is granted my way
					}
					else if (ammo == 1) // also implied, potion not supposed to be restored yet
						SetEntProp(clientIdx, Prop_Send, "m_iAmmo", 0, 4, offset);
						
					if (ammo == 0 && GetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon") == jarate)
						if (IsValidEntity(GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Melee)))
						{
							SetEntPropFloat(clientIdx, Prop_Send, "m_flNextAttack", GetGameTime() + 0.3);
							SetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Melee));
						}
				}
				
				// if an active jar has been destroyed, apply effects to jarated/milked players
				// manually detect allies to buff
				if (JP_ActiveJarEntRef[clientIdx] != INVALID_ENTREF)
				{
					new jar = EntRefToEntIndex(JP_ActiveJarEntRef[clientIdx]);
					if (!IsValidEntity(jar))
					{
						JP_ActiveJarEntRef[clientIdx] = INVALID_ENTREF;
						
						new jaratedTeam = JP_WasAirblasted[clientIdx] ? BossTeam : MercTeam;
						new jarOwnerTeam = JP_WasAirblasted[clientIdx] ? MercTeam : BossTeam;
								
						// apply negatives to jarated/milked enemies, and positives to BossTeam
						for (new victim = 1; victim < MAX_PLAYERS; victim++)
						{
							if (!IsLivingPlayer(victim))
								continue;
								
							if (GetClientTeam(victim) == jarOwnerTeam)
							{
								static Float:victimPos[3];
								GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
								
								if (GetVectorDistance(victimPos, JP_ActiveJarPos[clientIdx], true) <= JP_SPLASH_RADIUS_SQUARED)
									JP_HandleJarated(clientIdx, victim, curTime);
							}
							else if (GetClientTeam(victim) == jaratedTeam)
							{
								new bool:apply = false;
								if ((apply = TF2_IsPlayerInCondition(victim, TFCond_Jarated)))
									TF2_RemoveCondition(victim, TFCond_Jarated);
								else if ((apply = TF2_IsPlayerInCondition(victim, TFCond_Milked)))
									TF2_RemoveCondition(victim, TFCond_Milked);
									
								if (apply)
									JP_HandleJarated(clientIdx, victim, curTime);
							}
						}
					}
					else // refresh its pos
					{
						// properly handle airblasted jarate
						if (GetEntProp(jar, Prop_Send, "m_iDeflected") != 0 && (JP_Flags & JP_FLAG_BLOCK_AIRBLAST) == 0)
							JP_ActiveJarEntRef[clientIdx] = INVALID_ENTREF;
						else
						{
							JP_WasAirblasted[clientIdx] = (GetEntProp(jar, Prop_Send, "m_iDeflected") != 0);
							GetEntPropVector(jar, Prop_Send, "m_vecOrigin", JP_ActiveJarPos[clientIdx]);
						}
					}
					
				}
				
				// test any newly created jar
				if (JP_TestJarEntRef != INVALID_ENTREF)
				{
					new jar = EntRefToEntIndex(JP_TestJarEntRef);
					if (IsValidEntity(jar))
					{
						new owner = GetEntPropEnt(jar, Prop_Send, "m_hThrower");// & 0x3f;
						if (owner == clientIdx)
						{
							JP_ActiveJarEntRef[clientIdx] = JP_TestJarEntRef;
							JP_WasAirblasted[clientIdx] = false;
							JP_TestJarEntRef = INVALID_ENTREF;
							
							// store its position
							GetEntPropVector(jar, Prop_Send, "m_vecOrigin", JP_ActiveJarPos[clientIdx]);
							
							// reskin it
							if (strlen(JP_PotionModel) > 3)
								SetEntityModel(jar, JP_PotionModel);
						}
					}
					else if (PRINT_DEBUG_INFO)
						PrintToServer("[sarysamods9] WARNING: Jarate became invalid before it could be tested.");
				}
			}
		}
		else
		{
			// invuln removal
			if (curTime >= JP_RemoveInvulnAt[clientIdx])
			{
				SetEntProp(clientIdx, Prop_Data, "m_takedamage", 2);
				JP_RemoveInvulnAt[clientIdx] = FAR_FUTURE;
			}

			// safe resize check
			if (curTime >= JP_SafeResizeRetryAt[clientIdx])
			{
				if (!AttemptResize(clientIdx, false, JP_TargetSize[clientIdx]))
				{
					JP_SafeResizeRetryAt[clientIdx] = curTime + 0.1;
					if (curTime >= JP_SafeResizeShouldSlayAt[clientIdx])
					{
						ForcePlayerSuicide(clientIdx);
						PrintCenterText(clientIdx, "");
					}
					else if (float(JP_SlayMessageNext[clientIdx]) >= JP_SafeResizeShouldSlayAt[clientIdx] - curTime)
					{
						PrintCenterText(clientIdx, JP_SlayMessage, JP_SlayMessageNext[clientIdx]);
						JP_SlayMessageNext[clientIdx]--;
					}
				}
				else
				{
					JP_SafeResizeRetryAt[clientIdx] = FAR_FUTURE;
					JP_SafeResizeShouldSlayAt[clientIdx] = FAR_FUTURE;
					PrintCenterText(clientIdx, "");
				}
			}
		
			// enemy: fix size, head size, unhide (note: using TFCond stealthed for hiding)
			if (curTime >= JP_RemoveConditionsAt[clientIdx])
				JP_RemoveVictimConditions(clientIdx, curTime);
			else if (JP_RemoveConditionsAt[clientIdx] != FAR_FUTURE)
			{
				// must update head size every frame
				if (JP_HeadScale[clientIdx] != 1.0)
					SetEntPropFloat(clientIdx, Prop_Send, "m_flHeadScale", JP_HeadScale[clientIdx]);
				
				// also fix incorrect speed
				if (JP_ModifyingSpeed[clientIdx])
				{
					new Float:curSpeed = GetEntPropFloat(clientIdx, Prop_Send, "m_flMaxspeed");
					if (curSpeed != JP_ExpectedSpeed[clientIdx])
					{
						curSpeed *= JP_TargetSize[clientIdx];
						SetEntPropFloat(clientIdx, Prop_Send, "m_flMaxspeed", curSpeed);
						JP_ExpectedSpeed[clientIdx] = curSpeed;
					}
				}
			}
		}
		
		// both: remove conditions
		if (curTime >= JP_RemoveConditionsAt[clientIdx])
			JP_RemoveNeutralConditions(clientIdx);
	}
	
	// the jar has surely been tested
	JP_TestJarEntRef = INVALID_ENTREF;
}

/**
 * Speed Override
 */
public SO_PreThink(clientIdx)
{
	if (IsLivingPlayer(clientIdx) && SO_CanUse[clientIdx] && SO_ActiveThisRound)
	{
		new Float:modifier = (TF2_IsPlayerInCondition(clientIdx, TFCond_Slowed) ? 0.60 : 1.0) * (TF2_IsPlayerInCondition(clientIdx, TFCond_SpeedBuffAlly) ? 1.35 : 1.0);
		if (SO_MaxHP[clientIdx] > 0)
		{
			new Float:baseSpeed = SO_LowSpeed[clientIdx] + ((1.0 - (float(FF2_GetBossMaxHealth(FF2_GetBossIndex(clientIdx))) / float(SO_MaxHP[clientIdx]))) * (SO_HighSpeed[clientIdx] - SO_LowSpeed[clientIdx]));
			SetEntPropFloat(clientIdx, Prop_Send, "m_flMaxspeed", modifier * baseSpeed);
		}
	}
}

/**
 * Love Curse
 */
public Rage_LoveCurse(clientIdx)
{
	new Float:curTime = GetEngineTime();

	// first, find valid potential targets.
	// anyone who's invalid but is already affected, just extend their existing rage. (ubers included, can't have mates on different timers)
	static bool:isValid[MAX_PLAYERS_ARRAY];
	new validCount = 0;
	static Float:bossPos[3];
	GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", bossPos);
	for (new victim = 1; victim < MAX_PLAYERS; victim++)
	{
		if (!IsLivingPlayer(victim) || GetClientTeam(victim) == BossTeam)
			isValid[victim] = false;
		else if (LC_IsAffected[victim])
		{
			// just extend in a ragespam case, regardless of distance or uber.
			// since rage works in pairs, would be too messy to do anything else.
			isValid[victim] = false;
			LC_AffectUntil[victim] = curTime + LC_Duration[clientIdx];
		}
		else if ((LC_Flags[clientIdx] & LC_FLAG_UBER_IMMUNE) != 0 && TF2_IsPlayerInCondition(victim, TFCond_Ubercharged))
			isValid[victim] = false;
		else
		{
			static Float:victimPos[3];
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
			isValid[victim] = GetVectorDistance(bossPos, victimPos) <= LC_Radius[clientIdx];
			if (isValid[victim])
				validCount++;
		}
	}
	
	// now make parings. if validCount is 1, a random player gets off the hook.
	new firstVictim;
	new bool:isSecond = false;
	while (validCount > 0)
	{
		new random = GetRandomInt(0, validCount - 1);
		for (new victim = 1; victim < MAX_PLAYERS; victim++)
		{
			if (isValid[victim])
			{
				if (random > 0)
					random--;
				else
				{
					if (isSecond)
					{
						// pair victim and firstVictim
						LC_IsAffected[victim] = LC_IsAffected[firstVictim] = true;
						LC_AffectUntil[victim] = LC_AffectUntil[firstVictim] = curTime + LC_Duration[clientIdx];
						LC_Curser[victim] = LC_Curser[firstVictim] = clientIdx;
						LC_NextAttractionAt[victim] = LC_NextAttractionAt[firstVictim] = curTime;
						LC_NextDamageAt[victim] = LC_NextDamageAt[firstVictim] = curTime + LC_DamageInterval[clientIdx]; // grace period
						LC_NextHUDAt[victim] = LC_NextHUDAt[firstVictim] = curTime;
						LC_Mate[victim] = firstVictim;
						LC_Mate[firstVictim] = victim;
						
						// since you don't want the beam drawing twice, only one player gets it
						LC_NextBeamAt[victim] = ((LC_Flags[clientIdx] & LC_FLAG_NO_BEAM) != 0) ? FAR_FUTURE : curTime;
						LC_NextBeamAt[firstVictim] = FAR_FUTURE;
						
						// create the lovey dovey particle
						if (strlen(LC_EffectName) > 0)
						{
							new effect = AttachParticle(victim, LC_EffectName, 80.0);
							if (IsValidEntity(effect))
								LC_ParticleEntRef[victim] = EntIndexToEntRef(effect);
							effect = AttachParticle(firstVictim, LC_EffectName, 80.0);
							if (IsValidEntity(effect))
								LC_ParticleEntRef[firstVictim] = EntIndexToEntRef(effect);
						}
						
						if (PRINT_DEBUG_SPAM)
							PrintToServer("[sarysamods9] Love Curse: Paired %d and %d", firstVictim, victim);
						
						isSecond = false;
					}
					else
					{
						firstVictim = victim;
						isSecond = true;
					}

					isValid[victim] = false;
					validCount--;
					break;
				}
			}
		}
	}
}

public LC_RemoveCurse(victim)
{
	LC_IsAffected[victim] = false;
	if (LC_ParticleEntRef[victim] != INVALID_ENTREF)
		RemoveEntity(INVALID_HANDLE, LC_ParticleEntRef[victim]);
	LC_ParticleEntRef[victim] = INVALID_ENTREF;
	
	if (IsLivingPlayer(victim) && RoundInProgress)
		PrintCenterText(victim, LC_CureMessage);
}

public LC_Tick(Float:curTime)
{
	// for this rage, the hale does nothing that needs ticking. how nice.
	for (new victim = 1; victim < MAX_PLAYERS; victim++)
	{
		if (!LC_IsAffected[victim])
			continue;
		
		// need to clean up stuff like the beam, even if the player's dead
		if (!IsLivingPlayer(victim) || curTime >= LC_AffectUntil[victim])
		{
			LC_RemoveCurse(victim);
			continue;
		}
		
		// remove curse if the curser is dead
		new curser = LC_Curser[victim];
		if (!IsLivingPlayer(curser))
		{
			LC_RemoveCurse(victim);
			continue;
		}
		
		// check if partner died, apply damage if that happens
		new partner = LC_Mate[victim];
		if (!IsLivingPlayer(partner))
		{
			if (LC_DamageOnMateDeath[curser] > 0.0)
				SDKHooks_TakeDamage(victim, curser, curser, LC_DamageOnMateDeath[curser] / 3.0, DMG_CRIT | DMG_PREVENT_PHYSICS_FORCE, -1);
			LC_RemoveCurse(victim);
			continue;
		}
		
		// draw the HUD
		if (curTime >= LC_NextHUDAt[victim])
		{
			static String:partnerStr[65];
			GetClientName(partner, partnerStr, sizeof(partnerStr));
			SetHudTextParams(-1.0, LC_HUD_Y, 0.1 + 0.05, GetR(LC_BeamColor[curser]), GetG(LC_BeamColor[curser]), GetB(LC_BeamColor[curser]), 192);
			ShowHudText(victim, -1, LC_AfflictionMessage, partnerStr);
			
			LC_NextHUDAt[victim] = curTime + 0.1;
		}
		
		// any reason to go on?
		if (!(curTime >= LC_NextAttractionAt[victim] || curTime >= LC_NextDamageAt[victim] || curTime >= LC_NextBeamAt[victim]))
			continue;
		
		// get distance now
		static Float:victimPos[3];
		static Float:partnerPos[3];
		GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
		GetEntPropVector(partner, Prop_Send, "m_vecOrigin", partnerPos);
		new Float:distance = GetVectorDistance(victimPos, partnerPos);
		
		// draw the beam
		if (curTime >= LC_NextBeamAt[victim])
		{
			victimPos[2] += 41.5;
			partnerPos[2] += 41.5;
			static beamColor[4];
			beamColor[0] = GetR(LC_BeamColor[curser]);
			beamColor[1] = GetG(LC_BeamColor[curser]);
			beamColor[2] = GetB(LC_BeamColor[curser]);
			beamColor[3] = 255;
			TE_SetupBeamPoints(victimPos, partnerPos, LC_MATERIAL_INT, 0, 0, 0, LC_BEAM_DURATION, 5.0, 5.0, 0, 10.0, beamColor, 0);
			TE_SendToAll();
			victimPos[2] -= 41.5;
			partnerPos[2] -= 41.5;
		
			LC_NextBeamAt[victim] += LC_BeamInterval[curser];
		}
		
		// with all that death stuff out of the way, lets work on attraction...
		if (curTime >= LC_NextAttractionAt[victim])
		{
			if (distance > LC_MinDistance[curser])
			{
				static Float:angles[3];
				GetVectorAnglesTwoPoints(victimPos, partnerPos, angles);
				if (GetEntityFlags(victim) & FL_ONGROUND)
					angles[0] = 0.0; // toss out pitch if on ground
				static Float:velocity[3];
				GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(velocity, distance * LC_AttractionIntensity[curser]);
				
				// is it additive?
				if (LC_Flags[curser] & LC_FLAG_ADDITIVE)
				{
					// even if it is, gotta cap it...
					static Float:oldVelocity[3];
					GetEntPropVector(victim, Prop_Data, "m_vecVelocity", oldVelocity);
					oldVelocity[0] = fmin(300.0, fmax(-300.0, oldVelocity[0]));
					oldVelocity[1] = fmin(300.0, fmax(-300.0, oldVelocity[1]));
					velocity[0] += oldVelocity[0];
					velocity[1] += oldVelocity[1];
					// velocity[2] intentionally omitted
				}
				
				// min Z if on ground
				if (GetEntityFlags(victim) & FL_ONGROUND)
					velocity[2] = fmax(325.0, velocity[2]);
				
				// apply velocity
				TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, velocity);
			}
			
			LC_NextAttractionAt[victim] += LC_AttractionInterval[curser];
		}
		
		// and then damage
		if (curTime >= LC_NextDamageAt[victim])
		{
			if (distance > LC_MinDistance[curser])
			{
				new Float:damage = distance * LC_DamageIntensity[curser];
				QuietDamage(victim, curser, curser, damage, DMG_PREVENT_PHYSICS_FORCE, -1);
			}

			LC_NextDamageAt[victim] += LC_DamageInterval[curser];
		}
	}
}

/**
 * Rage/DOT Illusions
 */
public Action:RI_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsLivingPlayer(attacker) || !IsLivingPlayer(victim))
		return Plugin_Continue;
	// on second thought, allowing fall damage to be blocked. 2015-05-30
	//else if (attacker == 0 && inflictor == 0 && (damagetype & DMG_FALL) != 0)
	//	return Plugin_Continue;
	else if (RI_EnvironmentImmuneUntil[victim] <= GetEngineTime() || damage < 15.0)
		return Plugin_Continue;
	
	TeleportEntity(victim, RI_SafePos, NULL_VECTOR, Float:{0.0, 0.0, 0.0});
	damage = 0.0;
	damagetype |= DMG_PREVENT_PHYSICS_FORCE;
	return Plugin_Changed;
}

public RI_SwapModel(clientIdx, const String:model[])
{
	SetVariantString(model);
	AcceptEntityInput(clientIdx, "SetCustomModel");
	SetEntProp(clientIdx, Prop_Send, "m_bUseClassAnimations", 1);
}

public bool:RI_InitIllusions(clientIdx)
{
	new Float:curTime = GetEngineTime();

	// first, find valid potential targets.
	// anyone who's invalid but is already affected, just extend their existing rage. (ubers included, can't have mates on different timers)
	static bool:isValid[MAX_PLAYERS_ARRAY];
	static bool:isProcessed[MAX_PLAYERS_ARRAY]; // so we don't corrupt the above array
	new validCount = 0;
	static Float:bossPos[3];
	GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", bossPos);
	for (new victim = 1; victim < MAX_PLAYERS; victim++)
	{
		isProcessed[victim] = false;
		if (!IsLivingPlayer(victim) || GetClientTeam(victim) == BossTeam)
			isValid[victim] = false;
		else if (RI_IllusionOf[victim] != -1)
			isValid[victim] = false;
		else if (GetEntPropFloat(victim, Prop_Send, "m_flModelScale") != GetEntPropFloat(clientIdx, Prop_Send, "m_flModelScale"))
		{
			PrintToServer("%f != %f    %d != %d", GetEntPropFloat(victim, Prop_Send, "m_flModelScale"), GetEntPropFloat(clientIdx, Prop_Send, "m_flModelScale"), GetEntPropFloat(victim, Prop_Send, "m_flModelScale"), GetEntPropFloat(clientIdx, Prop_Send, "m_flModelScale"));
			isValid[victim] = false;
		}
		else
		{
			static Float:victimPos[3];
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
			isValid[victim] = GetVectorDistance(bossPos, victimPos) <= RI_Radius[clientIdx];
			if (isValid[victim])
				validCount++;
		}
	}
	
	// if validCount is still 0, fail. the DOT version will refund rage.
	if (validCount == 0)
		return false;
		
	// adjust the valid count by the factor given by the player.
	new Float:newValidCountF = 1.0 + (validCount * RI_IllusionsPerPlayer[clientIdx]);
	new newValidCount = 0;
	while (newValidCountF >= 1.0)
	{
		newValidCount++;
		newValidCountF -= 1.0;
	}
	validCount = max(1, min(validCount, newValidCount));
		
	// verify model is correct
	if (strlen(RI_Model) <= 3)
		GetEntPropString(clientIdx, Prop_Data, "m_ModelName", RI_Model, MAX_MODEL_FILE_LENGTH);
		
	// now go through the array again. first person who's valid is also the one we swap with.
	new bool:swapped = !RI_ShouldTeleport[clientIdx];
	while (validCount > 0)
	{
		new random = GetRandomInt(0, validCount - 1);
		for (new victim = 1; victim < MAX_PLAYERS; victim++)
		{
			if (isValid[victim] && !isProcessed[victim])
			{
				if (random > 0)
					random--;
				else
				{
					isValid[victim] = false;
					validCount--;
					isProcessed[victim] = true;
					
					// particle on the victim
					static Float:victimPos[3];
					GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
					if (strlen(RI_Particle) > 0)
						ParticleEffectAt(victimPos, RI_Particle, 1.0);
				
					// perform the swap next
					if (!swapped)
					{
						swapped = true;

						// teleport and force ducking (hale)
						SetEntPropVector(clientIdx, Prop_Send, "m_vecMaxs", Float:{24.0, 24.0, 62.0});
						SetEntProp(clientIdx, Prop_Send, "m_bDucked", 1);
						SetEntityFlags(clientIdx, GetEntityFlags(clientIdx) | FL_DUCKING);
						TeleportEntity(clientIdx, victimPos, NULL_VECTOR, Float:{0.0, 0.0, 0.0});
						
						// teleport and force ducking (player)
						SetEntPropVector(victim, Prop_Send, "m_vecMaxs", Float:{24.0, 24.0, 62.0});
						SetEntProp(victim, Prop_Send, "m_bDucked", 1);
						SetEntityFlags(victim, GetEntityFlags(victim) | FL_DUCKING);
						TeleportEntity(victim, bossPos, NULL_VECTOR, Float:{0.0, 0.0, 0.0});
						
						// swapped player needs environmental immunity, to prevent trolling
						RI_EnvironmentImmuneUntil[victim] = curTime + 5.0;
					}
					
					// swap the victim's model, but don't forget to store the old model
					GetEntPropString(victim, Prop_Data, "m_ModelName", RI_OriginalModel[victim], MAX_MODEL_FILE_LENGTH);
					RI_SwapModel(victim, RI_Model);
					
					// hide all weapons...good chance this won't work.
					for (new i = 0; i < 4; i++)
					{
						new weapon = GetPlayerWeaponSlot(victim, i);
						if (IsValidEntity(weapon))
						{
							SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
							SetEntityRenderColor(weapon, 0, 0, 0, 0);
						}
					}
					
					// we've processed this one, but we still need to remove wearables
					RI_IllusionOf[victim] = clientIdx;
					RI_VerifyModelAt[victim] = curTime + RI_MODEL_VERIFICATION_INTERVAL;
					break;
				}
			}
		}
	}
	
	// time to hide, not remove all the wearables
	RI_IllusionsUntil = curTime + RI_Duration[clientIdx];
	RI_SetWearableVisibility(false);
	
	// remove DOTs from the hale
	if (RI_ShouldRemoveDOTs[clientIdx])
	{
		if (TF2_IsPlayerInCondition(clientIdx, TFCond_OnFire))
			TF2_RemoveCondition(clientIdx, TFCond_OnFire);
		if (TF2_IsPlayerInCondition(clientIdx, TFCond_Bleeding))
			TF2_RemoveCondition(clientIdx, TFCond_Bleeding);
	}
	
	// play the mapwide sound
	if (strlen(RI_Sound) > 3)
		EmitSoundToAll(RI_Sound);
		
	// particle on the hale
	if (strlen(RI_Particle) > 0)
		ParticleEffectAt(bossPos, RI_Particle, 1.0);
		
	return true;
}

public bool:RI_IsValveModel(const String:modelName[MAX_MODEL_FILE_LENGTH])
{
	if (!strcmp(modelName, "models/player/demo.mdl")) return true;
	else if (!strcmp(modelName, "models/player/engineer.mdl")) return true;
	else if (!strcmp(modelName, "models/player/heavy.mdl")) return true;
	else if (!strcmp(modelName, "models/player/medic.mdl")) return true;
	else if (!strcmp(modelName, "models/player/pyro.mdl")) return true;
	else if (!strcmp(modelName, "models/player/scout.mdl")) return true;
	else if (!strcmp(modelName, "models/player/sniper.mdl")) return true;
	else if (!strcmp(modelName, "models/player/soldier.mdl")) return true;
	else if (!strcmp(modelName, "models/player/spy.mdl")) return true;
	
	return false;
}

public RI_SetWearableVisibility(bool:visible)
{
	static String:classname[MAX_ENTITY_CLASSNAME_LENGTH];
	new owner;
	for (new pass = 0; pass < 3; pass++)
	{
		if (pass == 0) classname = "tf_wearable";
		else if (pass == 1) classname = "tf_wearable_demoshield";
		else if (pass == 2) classname = "tf_powerup_bottle";
		
		new wearable = -1;
		while ((wearable = FindEntityByClassname(wearable, classname)) != -1)
		{
			if ((owner = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity")) <= MAX_PLAYERS && owner > 0 && RI_IllusionOf[owner] != -1)
			{
				SetEntityRenderMode(wearable, RENDER_TRANSCOLOR);
				if (visible)
				{
					// only set it visible if model is a valve model
					if (RI_IsValveModel(RI_OriginalModel[owner]))
						SetEntityRenderColor(wearable, 255, 255, 255, 255);
				}
				else
					SetEntityRenderColor(wearable, 0, 0, 0, 0);
			}
		}
	}
}

public RI_Tick(Float:curTime)
{
	if (RI_IllusionsUntil == FAR_FUTURE)
		return; // nothing to do
	else if (curTime >= RI_IllusionsUntil)
	{
		RI_IllusionsUntil = FAR_FUTURE;
	
		// set wearables visible
		RI_SetWearableVisibility(true);
	
		// restore everyone's model to what it should be
		for (new victim = 1; victim < MAX_PLAYERS; victim++)
		{
			if (!IsLivingPlayer(victim) || GetClientTeam(victim) == BossTeam)
				continue;
			else if (RI_IllusionOf[victim] == -1)
				continue;
			else
			{
				RI_IllusionOf[victim] = -1;
				RI_SwapModel(victim, RI_OriginalModel[victim]);
				SetEntProp(victim, Prop_Send, "m_bGlowEnabled", 0);
				
				// set weapons visible
				for (new i = 0; i < 4; i++)
				{
					new weapon = GetPlayerWeaponSlot(victim, i);
					if (IsValidEntity(weapon))
					{
						SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
						SetEntityRenderColor(weapon, 255, 255, 255, 255);
					}
				}
			}
		}
		
		return;
	}
	
	// if we're past this point, the rage is active. do per-user checks
	for (new victim = 1; victim < MAX_PLAYERS; victim++)
	{
		if (!IsLivingPlayer(victim) || GetClientTeam(victim) == BossTeam)
			continue;
		else if (RI_IllusionOf[victim] == -1)
			continue;
			
		// is the inflictor dead? if so, it's time to end the rage prematurely.
		new patientZero = RI_IllusionOf[victim];
		if (!IsLivingPlayer(patientZero))
		{
			RI_IllusionsUntil = curTime - 0.1;
			RI_Tick(RI_IllusionsUntil);
			return;
		}
			
		// is it time to reverify the model? necessary due to potential /mm abuse
		if (curTime >= RI_VerifyModelAt[victim])
		{
			static String:modelName[MAX_MODEL_FILE_LENGTH];
			GetEntPropString(victim, Prop_Data, "m_ModelName", modelName, MAX_MODEL_FILE_LENGTH);
			if (strcmp(modelName, RI_Model) != 0)
				RI_SwapModel(victim, RI_Model);
				
			RI_VerifyModelAt[victim] = curTime + RI_MODEL_VERIFICATION_INTERVAL;
		}
		
		// always reverify m_bGlowEnabled
		if (RI_ShouldMatchGlow[patientZero])
		{
			new glowEnabled = GetEntProp(patientZero, Prop_Send, "m_bGlowEnabled");
			if (GetEntProp(victim, Prop_Send, "m_bGlowEnabled") != glowEnabled)
				SetEntProp(victim, Prop_Send, "m_bGlowEnabled", glowEnabled);
		}
	}
}

/**
 * Managed Flamethrower
 */
#define MF_MINICRIT_COND TFCond_CritCola
public MF_OnDeflect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "ownerid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetEventInt(event, "weaponid") != 0)
		return;
	else if (!IsLivingPlayer(victim) || GetClientTeam(victim) == BossTeam)
		return;
	else if (!IsLivingPlayer(attacker) || GetClientTeam(attacker) == MercTeam)
		return;
	else if (!MF_CanUse[attacker] || MF_AirblastDamage[attacker] <= 0.0)
		return;

	if (PRINT_DEBUG_SPAM)
		PrintToServer("[sarysamods9] %d deflected %d, will do %f damage", attacker, victim, MF_AirblastDamage[attacker]);

	SDKHooks_TakeDamage(victim, attacker, attacker, MF_AirblastDamage[attacker] / 3.0, DMG_CRIT, -1);
	MF_SoundPending[attacker] = true;
}

public MF_OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	if (IsLivingPlayer(attacker) && MF_CanUse[attacker])
	{
		if (TF2_IsPlayerInCondition(attacker, MF_MINICRIT_COND))
			TF2_RemoveCondition(attacker, MF_MINICRIT_COND);
	}
}

public Action:MF_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	//PrintToServer("%d %d %d %f 0x%x, %d, %d", victim, attacker, inflictor, damage, damagetype, weapon, damagecustom);
	if (!IsLivingPlayer(attacker) || GetClientTeam(attacker) != BossTeam)
		return Plugin_Continue;
	else if (damagetype & 0x40040)
	{
		if (MF_Flags[attacker] & MF_FLAG_AIRBLAST_DAMAGE_FIX)
		{
			damage /= 3.0;
			return Plugin_Changed;
		}
		return Plugin_Continue;
	}
	else if (weapon == -1 || !IsLivingPlayer(victim))
		return Plugin_Continue;
	else if (weapon != GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary))
	{	
		if ((weapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee) || (damage >= 30.0 && TF2_GetPlayerClass(victim) == TFClass_Soldier)) // detecting soldiers is very trying
		 			&& TF2_IsPlayerInCondition(victim, TFCond_OnFire))
		{
			if (PRINT_DEBUG_SPAM)
				PrintToServer("[sarysamods9] Multiplying burning player melee by %f", MF_MeleeDamageMultiplier[attacker]);
			if (MF_Flags[attacker] & MF_FLAG_MINICRIT_BURNING)
				TF2_AddCondition(attacker, TFCond_CritCola, -1.0);
			damage *= MF_MeleeDamageMultiplier[attacker];
			//PrintToServer("damage=%f", damage);
			return Plugin_Changed;
		}
		
		if (!(TF2_GetPlayerClass(victim) == TFClass_Soldier && (damagetype & DMG_BURN) != 0))
			return Plugin_Continue;
	}
	
	// if we're here, it's absolutely flamethrower damage. manage it properly.
	//PrintToServer("[sarysamods9] Flamethrower damage: %f 0x%x %d   class=%d  soldier=%d", damage, damagetype, damagecustom, TF2_GetPlayerClass(victim), (TF2_GetPlayerClass(victim) == TFClass_Soldier));
	new bool:isAfterburn = ((0x1000000 & damagetype) == 0);
	new Float:damageCap = isAfterburn ? MF_AfterburnCap[attacker] : MF_DamageCap[attacker];
	new bool:isManaged = false;
	if (MF_PlayerType[victim] != MF_TYPE_NORMAL)
	{
		if (MF_PlayerType[victim] == MF_TYPE_INVIS_WATCH && TF2_IsPlayerInCondition(victim, TFCond_Cloaked))
		{
			MF_PendingDamage[victim] += fmax(10.0, fmin(damage, damageCap)); // ensure it does _some_ damage
			isManaged = true;
		}
		else if (MF_PlayerType[victim] == MF_TYPE_DEAD_RINGER && GetEntProp(victim, Prop_Send, "m_bFeignDeathReady") > 0)
		{
			MF_PendingDamage[victim] += fmin(damage, damageCap) * 10.0; // ensure it does _some_ damage
			isManaged = true;
		}
	}
	
	if (!isManaged && (MF_Flags[attacker] & MF_FLAG_FF2_MANAGES_DAMAGE) == 0)
	{
		MF_PendingDamage[victim] += fmin(damage, damageCap);
		isManaged = true;
	}
	
	if (!isManaged)
		return Plugin_Continue;
	
	if (!isAfterburn)
		MF_IgniteAt[victim] = GetEngineTime();

	return Plugin_Handled;
}

public MF_Tick(Float:curTime)
{
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (MF_CanUse[clientIdx] && IsLivingPlayer(clientIdx))
		{
			// time to play the airblast sound? also, this means display the particle, too.
			if (MF_SoundPending[clientIdx])
			{
				MF_SoundPending[clientIdx] = false;
			
				// play the sound on the hale
				static Float:bossPos[3];
				GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", bossPos);
				if (strlen(MF_AirblastSound) > 3)
					EmitAmbientSound(MF_AirblastSound, bossPos, clientIdx);
					
				// display the particle 70 units in front of the hale
				if (!IsEmptyString(MF_AirblastParticle))
				{
					static Float:eyeAngles[3];
					static Float:endPos[3];
					GetClientEyeAngles(clientIdx, eyeAngles);
					eyeAngles[0] = 0.0; // toss out pitch
					TR_TraceRayFilter(bossPos, eyeAngles, (CONTENTS_SOLID | CONTENTS_WINDOW | CONTENTS_GRATE), RayType_Infinite, TraceWallsOnly);
					TR_GetEndPosition(endPos);
					ConformLineDistance(endPos, bossPos, endPos, MF_ParticleDistance[clientIdx], false);
					ParticleEffectAt(endPos, MF_AirblastParticle, 1.0);
				}
			}
			
			// handle pending damage on those who need it
			for (new victim = 1; victim < MAX_PLAYERS; victim++)
			{
				if (MF_PendingDamage[victim] > 0.0)
				{
					SDKHooks_TakeDamage(victim, clientIdx, clientIdx, MF_PendingDamage[victim], (curTime >= MF_IgniteAt[victim]) ? 0x1000808 : 0x808, GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Primary));
					if (curTime >= MF_IgniteAt[victim])
					{
						MF_AfterburnEndsAt[victim] = GetEngineTime() + MF_AfterburnDuration[clientIdx];
						//PrintToServer("ignited. dur=%f ends=%f", MF_AfterburnDuration[clientIdx], MF_AfterburnEndsAt[victim]);
						MF_IgniteAt[victim] = FAR_FUTURE;
					}
					MF_PendingDamage[victim] = 0.0;
				}
			}
			
			// refresh ammo
			if (curTime >= MF_AmmoRefreshAt[clientIdx])
			{
				MF_AmmoRefreshAt[clientIdx] += MF_AMMO_REFRESH_INTERVAL;

				new weapon = GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Primary);
				if (IsValidEntity(weapon))
				{
					new offset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1);
					if (offset < 0)
						continue;
					new ammo = GetEntProp(clientIdx, Prop_Send, "m_iAmmo", 4, offset);
					ammo = min(ammo + MF_AmmoPerSecond[clientIdx], MF_MaxAmmo[clientIdx]);
					SetEntProp(clientIdx, Prop_Send, "m_iAmmo", ammo, 4, offset);
				}
			}
		}
		else if (IsLivingPlayer(clientIdx) && GetClientTeam(clientIdx) == MercTeam)
		{
			if (TF2_IsPlayerInCondition(clientIdx, TFCond_OnFire))
			{
				if (curTime >= MF_AfterburnEndsAt[clientIdx])
				{
					TF2_RemoveCondition(clientIdx, TFCond_OnFire);
					MF_AfterburnEndsAt[clientIdx] = FAR_FUTURE;
				}
			}
			else
			{
				MF_AfterburnEndsAt[clientIdx] = FAR_FUTURE;
			}
		}
	}
}

/**
 * DOT Digger
 */
public DD_Initialize()
{
	for (new gemIdx = 0; gemIdx < MAX_GEMS; gemIdx++)
		DDG_EntRef[gemIdx] = INVALID_ENTREF;
}

public DD_Cleanup()
{
	DD_ActiveThisRound = false;
	for (new gemIdx = 0; gemIdx < MAX_GEMS; gemIdx++)
	{
		if (DDG_EntRef[gemIdx] != INVALID_ENTREF)
			RemoveEntity(INVALID_HANDLE, DDG_EntRef[gemIdx]);
		DDG_EntRef[gemIdx] = INVALID_ENTREF;
	}
}

public bool:DD_OnActivate(clientIdx)
{
	new flags = GetEntityFlags(clientIdx);
	if ((flags & FL_ONGROUND) == 0 || (flags & (FL_SWIM | FL_INWATER)) != 0)
	{
		Nope(clientIdx);
		PrintCenterText(clientIdx, DD_InAirError);
		return false;
	}
	
	// store yaw in case turning is not allowed
	static Float:angles[3];
	GetClientEyeAngles(clientIdx, angles);
	DD_StoredYaw[clientIdx] = angles[1];
	
	// force a specific taunt
	DD_StartTauntAt[clientIdx] = GetEngineTime();
	DD_StopTauntAt[clientIdx] = FAR_FUTURE;
		
	// stop their movement and add megaheal
	SetEntityMoveType(clientIdx, MOVETYPE_NONE);
	TF2_AddCondition(clientIdx, TFCond_MegaHeal, -1.0);
	
	// play the sound if it exists
	if (strlen(DD_InitialSound) > 3)
	{
		static Float:eyePos[3];
		GetClientEyePosition(clientIdx, eyePos);
		EmitAmbientSound(DD_InitialSound, eyePos, clientIdx);
	}
	DD_NextSoundAt[clientIdx] = GetEngineTime() + DD_SoundDelay;
	
	DD_SpawnNextGemAt[clientIdx] = GetEngineTime();
	DD_IsUsing[clientIdx] = true;
	return true;
}

public DD_OnDeactivate(clientIdx)
{
	// return their movement to normal, stop the taunt, and set using to false
	SetEntityMoveType(clientIdx, MOVETYPE_WALK);
	if (TF2_IsPlayerInCondition(clientIdx, TFCond_MegaHeal))
		TF2_RemoveCondition(clientIdx, TFCond_MegaHeal);
	if (TF2_IsPlayerInCondition(clientIdx, TFCond_Taunting))
		TF2_RemoveCondition(clientIdx, TFCond_Taunting);
	DD_IsUsing[clientIdx] = false;
}

public DD_RemoveGem(gemIdx)
{
	RemoveEntity(INVALID_HANDLE, DDG_EntRef[gemIdx]);
	DDG_EntRef[gemIdx] = INVALID_ENTREF;
	for (new i = gemIdx; i < MAX_GEMS - 2; i++)
	{
		DDG_EntRef[i] = DDG_EntRef[i+1];
		DDG_Owner[i] = DDG_Owner[i+1];
		DDG_SolidifyAt[i] = DDG_SolidifyAt[i+1];
		DDG_DestroyAt[i] = DDG_DestroyAt[i+1];
	}
	
	DDG_EntRef[MAX_GEMS - 1] = INVALID_ENTREF;
}

public DD_OnGemCollide(gemIdx, clientIdx, victim)
{
	if (DD_Flags[clientIdx] & DD_FLAG_HOOKED_DAMAGE)
		FullyHookedDamage(victim, clientIdx, clientIdx, fixDamageForFF2(DD_GemDamage[clientIdx] / 3), DMG_CRIT, GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Melee));
	else
		SDKHooks_TakeDamage(victim, clientIdx, clientIdx, DD_GemDamage[clientIdx] / 3, DMG_CRIT, GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Melee));
	DD_RemoveGem(gemIdx);
}

public Action:DD_OnStomp(attacker, victim, &Float:damageMultiplier, &Float:damageBonus, &Float:JumpPower)
{
	if (DD_CanUse[victim] && DD_IsUsing[victim])
	{
		damageMultiplier *= DD_GoombaFactorMult[victim];
		damageBonus *= DD_GoombaDamageMult[victim];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:DD_OnStartTouch(gem, victim)
{
	// touching any player, friend or foe, will result in the prop's destruction
	if (IsLivingPlayer(victim))
	{
		// determine the gem index. if indeterminable, destroy the prop.
		new gemIdx = -1;
		for (new i = 0; i < MAX_GEMS; i++)
		{
			if (DDG_EntRef[i] == INVALID_ENTREF)
				break;
			else if (EntRefToEntIndex(DDG_EntRef[i]) == gem)
			{
				gemIdx = i;
				break;
			}
		}
		if (gemIdx == -1)
		{
			PrintToServer("[sarysamods9] WARNING: Gem of indeterminable origin touch hooked a player. Destroying gem %d.", gem);
			AcceptEntityInput(gem, "kill");
			return Plugin_Handled;
		}
	
		if (GetClientTeam(victim) == MercTeam && IsLivingPlayer(victim) && IsLivingPlayer(DDG_Owner[gemIdx]))
			DD_OnGemCollide(gemIdx, DDG_Owner[gemIdx], victim);
		else
			DD_RemoveGem(gemIdx);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public DD_Tick(Float:curTime)
{
	// first tick anyone who can potentially use it
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!DD_CanUse[clientIdx] || !DD_IsUsing[clientIdx] || !IsLivingPlayer(clientIdx))
			continue;
		
		// gem spawning timer
		if (curTime >= DD_SpawnNextGemAt[clientIdx])
		{
			// find a free spot for the gem
			new gemIdx = -1;
			for (new i = 0; i < MAX_GEMS; i++)
			{
				if (DDG_EntRef[i] == INVALID_ENTREF)
				{
					gemIdx = i;
					break;
				}
			}
			
			if (gemIdx == -1)
			{
				DD_RemoveGem(0);
				gemIdx = MAX_GEMS - 1;
				if (PRINT_DEBUG_INFO)
					PrintToServer("[sarysamods9] WARNING: Had to remove a gem. There's a limit of %d gems and you're spawning them too fast or removing them too late.", MAX_GEMS);
			}
		
			// create a prop and toss it
			static Float:spawnPos[3];
			GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", spawnPos);
			spawnPos[2] += DD_GemZOffset[clientIdx];
			static Float:angles[3];
			angles[1] = DD_StoredYaw[clientIdx];
			if (DD_Flags[clientIdx] & DD_FLAG_GEMS_CURRENT_EYE_ANGLE)
				GetClientEyeAngles(clientIdx, angles);
			angles[0] = GetRandomFloat(DD_GemPitchRange[clientIdx][0], DD_GemPitchRange[clientIdx][1]);
			angles[1] = fixAngle(angles[1] + GetRandomFloat(DD_GemYawRange[clientIdx][0], DD_GemYawRange[clientIdx][1]));
			static Float:velocity[3];
			GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(velocity, GetRandomFloat(DD_GemIntensityRange[clientIdx][0], DD_GemIntensityRange[clientIdx][1]));
			new prop = CreateEntityByName("prop_physics_override");
			if (IsValidEntity(prop))
			{
				SetEntProp(prop, Prop_Data, "m_takedamage", 0);

				// tweak the model (note, its validity has already been verified)
				SetEntityModel(prop, DD_Model);

				// spawn and move it
				DispatchSpawn(prop);
				TeleportEntity(prop, spawnPos, angles, velocity);
				SetEntProp(prop, Prop_Data, "m_takedamage", 0);

				// collision, movetype, and scale
				SetEntProp(prop, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS_TRIGGER);

				// keep track of this prop
				DDG_EntRef[gemIdx] = EntIndexToEntRef(prop);
				DDG_Owner[gemIdx] = clientIdx;
				DDG_SolidifyAt[gemIdx] = curTime + DD_GemSolidifyDelay[clientIdx];
				DDG_DestroyAt[gemIdx] = curTime + DD_GemLifetime[clientIdx];
				
				// recolor it
				if (DD_Flags[clientIdx] & DD_RECOLOR_ALL)
				{
					SetEntityRenderMode(prop, RENDER_TRANSCOLOR);
					SetEntityRenderColor(prop, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), 255);
				}
			}
		
			DD_SpawnNextGemAt[clientIdx] += DD_GemInterval[clientIdx];
		}
		
		// play the next sound?
		if (curTime >= DD_NextSoundAt[clientIdx])
		{
			if (strlen(DD_LoopingSound) > 3)
			{
				static Float:eyePos[3];
				GetClientEyePosition(clientIdx, eyePos);
				EmitAmbientSound(DD_LoopingSound, eyePos, clientIdx);
			}
			DD_NextSoundAt[clientIdx] = curTime + DD_SoundInterval;
		}
		
		// start the taunt?
		if (curTime >= DD_StartTauntAt[clientIdx])
		{
			// rob them of a little charge so they don't blow all their rage. lol
			new bossIdx = FF2_GetBossIndex(clientIdx);
			if (FF2_GetBossCharge(bossIdx, 0) >= 100.0)
				FF2_SetBossCharge(bossIdx, 0, 99.49); // damn you, RoundFloat
				
			if (DD_TauntIndex[clientIdx] > 0)
				ForceUserToTaunt(clientIdx, DD_TauntIndex[clientIdx]);
			else
				FakeClientCommand(clientIdx, "taunt");
			DD_StopTauntAt[clientIdx] = curTime + 0.05;
			DD_StartTauntAt[clientIdx] = curTime + DD_TauntInterval[clientIdx];
		}
		
		// stop the taunt?
		if (curTime >= DD_StopTauntAt[clientIdx])
		{
			if (TF2_IsPlayerInCondition(clientIdx, TFCond_Taunting))
				TF2_RemoveCondition(clientIdx, TFCond_Taunting);
			DD_StopTauntAt[clientIdx] = FAR_FUTURE;
		}
	}
	
	// then tick all the gems
	for (new gemIdx = MAX_GEMS - 1; gemIdx >= 0; gemIdx--)
	{
		if (DDG_EntRef[gemIdx] == INVALID_ENTREF)
			continue;
		
		new gem = EntRefToEntIndex(DDG_EntRef[gemIdx]);
		new clientIdx = DDG_Owner[gemIdx];
		if (!IsValidEntity(gem) || !IsLivingPlayer(clientIdx))
		{
			DD_RemoveGem(gemIdx);
			continue;
		}
		else if (curTime >= DDG_DestroyAt[gemIdx])
		{
			DD_RemoveGem(gemIdx);
			continue;
		}
		
		if (curTime >= DDG_SolidifyAt[gemIdx])
		{
			// fix collision and add touch hooks, now that they matter
			SDKHook(gem, SDKHook_StartTouch, DD_OnStartTouch);
			SetEntProp(gem, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_NONE);
			DDG_SolidifyAt[gemIdx] = FAR_FUTURE;
		}
		else if (DDG_SolidifyAt[gemIdx] != FAR_FUTURE)
		{
			// still doing manual collision
			static Float:gemPos[3];
			GetEntPropVector(gem, Prop_Send, "m_vecOrigin", gemPos);
			for (new victim = 1; victim < MAX_PLAYERS; victim++)
			{
				if (!IsLivingPlayer(victim) || GetClientTeam(victim) != MercTeam)
					continue;
			
				static Float:victimPos[3];
				GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
				if (CylinderCollision(gemPos, victimPos, DD_CollisionRadius[clientIdx], gemPos[2] - (83.0 + DD_CollisionRadius[clientIdx]), gemPos[2] + DD_CollisionRadius[clientIdx]))
				{
					DD_OnGemCollide(gemIdx, clientIdx, victim);
					break;
				}
			}
			
			// if we hit something, continue
			if (DDG_EntRef[gemIdx] == INVALID_ENTREF)
				continue;
		}
	}
}

/**
 * Blink Hadouken
 */
public Action:BH_MedicCommand(clientIdx, const String:command[], argc)
{
	if (!IsLivingPlayer(clientIdx) || GetClientTeam(clientIdx) != BossTeam)
		return Plugin_Continue;
	
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0 || BH_KeyID[clientIdx] != BH_KEY_MEDIC)
		return Plugin_Continue;

	new String:unparsedArgs[4];
	GetCmdArgString(unparsedArgs, 4);
	if (!strcmp(unparsedArgs, "0 0"))
	{
		new Float:rage = FF2_GetBossCharge(bossIdx, 0);
	
		// do we have enough rage for this?
		if ((rage <= 0.0 && BH_WithheldRage[clientIdx] <= 0.0) || rage >= 99.5)
			return Plugin_Continue; // there's a good chance that FF2 picked up this one. do nothing.
			
		// is it time to end the blink?
		if (BH_BlinkReady[clientIdx])
		{
			BH_Blink(clientIdx);
			return Plugin_Continue;
		}
	
		if (rage < BH_RageCost[clientIdx])
			Nope(clientIdx);
		else if ((BH_Flags[clientIdx] & BH_FLAG_UNUSABLE_WHILE_STUNNED) && TF2_IsPlayerInCondition(clientIdx, TFCond_Dazed))
			Nope(clientIdx);
		else
		{
			FF2_SetBossCharge(bossIdx, 0, rage - BH_RageCost[clientIdx]);
			BH_CreateHadouken(clientIdx);

			if (PRINT_DEBUG_INFO)
				PrintToServer("[sarysamods9] Initiating Blink Hadouken (via this mod, not FF2)");
		}
		
	}
	
	return Plugin_Continue;
}
 
public BH_Initialize()
{
	new bool:medicHooked = false;
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (BH_CanUse[clientIdx] && !(BH_IsDOT[clientIdx] || BH_KeyID[clientIdx] != BH_KEY_MEDIC))
		{
			if (!medicHooked)
				AddCommandListener(BH_MedicCommand, "voicemenu");
			medicHooked = true;
		}
	}
}

public BH_Cleanup()
{
	BH_ActiveThisRound = false;
	RemoveCommandListener(BH_MedicCommand, "voicemenu");
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (IsClientInGame(clientIdx))
			FF2_SetFF2flags(clientIdx, FF2_GetFF2flags(clientIdx) & (~FF2FLAG_HUDDISABLED));
	}
}

public BH_CreateHadouken(clientIdx)
{
	// create our rocket. no matter what, it's going to spawn, even if it ends up being out of map
	new Float:damage = ((BH_Flags[clientIdx] & BH_FLAG_PROJECTILE_PENETRATION) != 0) ? 0.0 : fixDamageForFF2(BH_Damage[clientIdx]);
	new Float:speed = BH_Speed[clientIdx];
	new String:classname[MAX_ENTITY_CLASSNAME_LENGTH] = "CTFProjectile_Rocket";
	new String:entname[MAX_ENTITY_CLASSNAME_LENGTH] = "tf_projectile_rocket";
	
	new rocket = CreateEntityByName(entname);
	if (!IsValidEntity(rocket))
	{
		PrintToServer("[sarysamods9] Error: Invalid entity %s. Won't spawn rocket. This is sarysa's fault.", entname);
		return;
	}
	
	// get spawn position, angles, velocity
	static Float:spawnPos[3];
	static Float:eyePos[3];
	GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", spawnPos);
	GetClientEyePosition(clientIdx, eyePos);
	spawnPos[2] = eyePos[2];
	static Float:angles[3];
	GetClientEyeAngles(clientIdx, angles);
	static Float:velocity[3];
	GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(velocity, speed);
	
	// deploy!
	TeleportEntity(rocket, spawnPos, angles, velocity);
	SetEntProp(rocket, Prop_Send, "m_bCritical", false); // no random crits
	SetEntDataFloat(rocket, FindSendPropOffs(classname, "m_iDeflected") + 4, damage, true); // credit to voogru
	SetEntProp(rocket, Prop_Send, "m_nSkin", 1); // set skin to BLU team's
	SetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity", clientIdx);
	SetVariantInt(BossTeam);
	AcceptEntityInput(rocket, "TeamNum", -1, -1, 0);
	SetVariantInt(BossTeam);
	AcceptEntityInput(rocket, "SetTeam", -1, -1, 0); 
	DispatchSpawn(rocket);
	
	// change the collision
	if (BH_Flags[clientIdx] & BH_FLAG_PROJECTILE_PENETRATION)
		SetEntProp(rocket, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS_TRIGGER);
	
	// reskin after spawn
	if (BH_Model[clientIdx] != -1)
		SetEntProp(rocket, Prop_Send, "m_nModelIndex", BH_Model[clientIdx]);
		
	// play the rage sound
	if (strlen(BH_RageSound) > 3)
		EmitSoundToAll(BH_RageSound);
	
	// store it, and do other settings
	for (new victim = 1; victim < MAX_PLAYERS; victim++)
		BH_AlreadyHit[victim] = false;
	BH_ProjectileEntRef[clientIdx] = EntRefToEntIndex(rocket);
	GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", BH_LastSafePos[clientIdx]);
	BH_LastActualPos[clientIdx][0] = spawnPos[0];
	BH_LastActualPos[clientIdx][1] = spawnPos[1];
	BH_LastActualPos[clientIdx][2] = spawnPos[2];
	BH_BlinkReady[clientIdx] = true;
	BH_BlinkAllowedAt[clientIdx] = GetEngineTime() + 0.01; // fix yet another problem with using E for this rage.
	if (BH_ModelRecolor[clientIdx] > 0)
	{
		SetEntityRenderMode(rocket, RENDER_TRANSCOLOR);
		SetEntityRenderColor(rocket, GetR(BH_ModelRecolor[clientIdx]), GetG(BH_ModelRecolor[clientIdx]), GetB(BH_ModelRecolor[clientIdx]));
	}
}

stock BH_Blink(clientIdx, bool:calledByDOT = false, bool:force = false)
{
	if (BH_BlinkReady[clientIdx] && (force || GetEngineTime() >= BH_BlinkAllowedAt[clientIdx]))
	{
		BH_BlinkReady[clientIdx] = false;
		if (!IsEmptyString(BH_Particle))
			ParticleEffectAt(BH_LastSafePos[clientIdx], BH_Particle, 1.0);
		SetEntPropVector(clientIdx, Prop_Send, "m_vecMaxs", Float:{24.0, 24.0, 62.0});
		SetEntProp(clientIdx, Prop_Send, "m_bDucked", 1);
		SetEntityFlags(clientIdx, GetEntityFlags(clientIdx) | FL_DUCKING);
		TeleportEntity(clientIdx, BH_LastSafePos[clientIdx], NULL_VECTOR, Float:{0.0, 0.0, 0.0});
		
		// destroy the projectile
		if (BH_ProjectileEntRef[clientIdx] != INVALID_ENTREF && (BH_Flags[clientIdx] & BH_FLAG_PROJECTILE_PENETRATION) != 0)
		{
			RemoveEntity(INVALID_HANDLE, BH_ProjectileEntRef[clientIdx]);
			BH_ProjectileEntRef[clientIdx] = INVALID_ENTREF;
		}
		
		// play the sound
		if (strlen(BH_BlinkSound) > 3)
			EmitAmbientSound(BH_BlinkSound, BH_LastSafePos[clientIdx], clientIdx);
			
		// stun sentries
		if (BH_SentryStunRadius[clientIdx] > 0.0 && BH_SentryStunDuration[clientIdx] > 0.0)
			DSSG_PerformStunFromCoords(clientIdx, BH_LastSafePos[clientIdx], BH_SentryStunRadius[clientIdx], BH_SentryStunDuration[clientIdx]);
		
		// special DOT handling
		if (BH_IsDOT[clientIdx] && !calledByDOT)
			ForceDOTAbilityDeactivation(clientIdx);
	}
}

stock BH_DestroyProjectile(clientIdx)
{
	if (BH_ProjectileEntRef[clientIdx] != INVALID_ENTREF)
	{
		new projectile = EntRefToEntIndex(BH_ProjectileEntRef[clientIdx]);
		if (IsValidEntity(projectile))
			RemoveEntity(INVALID_HANDLE, BH_ProjectileEntRef[clientIdx]);
	}
	BH_ProjectileEntRef[clientIdx] = INVALID_ENTREF;
	
	// trigger the blink
	BH_Blink(clientIdx, false, true);
}

public bool:BH_IsPlayerSolid(const Float:pos1[3], const Float:pos2[3])
{
	static Float:endPos[3];
	TR_TraceRayFilter(pos1, pos2, MASK_PLAYERSOLID, RayType_EndPoint, TraceWallsOnly);
	TR_GetEndPosition(endPos);
	return (endPos[0] != pos2[0] || endPos[1] != pos2[1] || endPos[2] != pos2[2]);
}

public BH_Tick(Float:curTime)
{
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (IsLivingPlayer(clientIdx) && BH_CanUse[clientIdx])
		{
			// the robbery and restoration of rage, necessary to avoid ragespamming
			new bossIdx = FF2_GetBossIndex(clientIdx);
			if (bossIdx < 0)
				continue;
			
			if (BH_BlinkReady[clientIdx])
			{
				BH_WithheldRage[clientIdx] = fmin(100.0, BH_WithheldRage[clientIdx] + FF2_GetBossCharge(bossIdx, 0));
				FF2_SetBossCharge(bossIdx, 0, 0.0);
			}
			else if (BH_WithheldRage[clientIdx] > 0.0)
			{
				new Float:rage = fmin(100.0, BH_WithheldRage[clientIdx] + FF2_GetBossCharge(bossIdx, 0));
				FF2_SetBossCharge(bossIdx, 0, rage);
				BH_WithheldRage[clientIdx] = 0.0;
			}
			
			// refresh the HUD
			if (curTime >= BH_UpdateHUDAt[clientIdx])
			{
				BH_UpdateHUDAt[clientIdx] = curTime + BH_HUD_INTERVAL;
				new Float:actualRage = fmin(100.0, BH_WithheldRage[clientIdx] + FF2_GetBossCharge(bossIdx, 0));
				SetHudTextParams(-1.0, BH_HudY[clientIdx], BH_HUD_INTERVAL + 0.05, GetR(BH_HudColor[clientIdx]), GetG(BH_HudColor[clientIdx]), GetB(BH_HudColor[clientIdx]), 192);
				if (BH_BlinkReady[clientIdx])
					ShowHudText(clientIdx, -1, BH_BlinkReadyHudText, actualRage);
				else if (actualRage >= BH_RageCost[clientIdx])
					ShowHudText(clientIdx, -1, BH_RageReadyHudText, actualRage);
				else
					ShowHudText(clientIdx, -1, BH_NothingReadyHudText, actualRage);
			}
		
			// everything else below requires a valid projectile
			if (BH_ProjectileEntRef[clientIdx] == INVALID_ENTREF)
				continue;
				
			new projectile = EntRefToEntIndex(BH_ProjectileEntRef[clientIdx]);
			if (!IsValidEntity(projectile))
			{
				BH_ProjectileEntRef[clientIdx] = INVALID_ENTREF;
				BH_Blink(clientIdx, false, true);
				continue;
			}
			
			// airblast = end of run. destroy projectile and blink.
			if (GetEntProp(projectile, Prop_Send, "m_iDeflected") > 0)
			{
				BH_DestroyProjectile(clientIdx); // will also blink
				continue;
			}
			
			// recolor
			if (BH_ModelRecolor[clientIdx] > 0)
			{
				SetEntityRenderMode(projectile, RENDER_TRANSCOLOR);
				SetEntityRenderColor(projectile, GetR(BH_ModelRecolor[clientIdx]), GetG(BH_ModelRecolor[clientIdx]), GetB(BH_ModelRecolor[clientIdx]));
			}
			
			// do collision tests on players, before corrupting projectilePos
			static Float:projectilePos[3];
			GetEntPropVector(projectile, Prop_Send, "m_vecOrigin", projectilePos);
			if (BH_Flags[clientIdx] & BH_FLAG_PROJECTILE_PENETRATION)
			{
				for (new victim = 1; victim < MAX_PLAYERS; victim++)
				{
					if (!IsLivingPlayer(victim) || GetClientTeam(victim) == BossTeam)
						continue;
					else if (BH_AlreadyHit[victim])
						continue;
						
					static Float:victimPos[3];
					GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
					if (CylinderCollision(projectilePos, victimPos, BH_Radius[clientIdx], projectilePos[2] - (83.0 + BH_Radius[clientIdx]), projectilePos[2] + BH_Radius[clientIdx]))
					{
						BH_AlreadyHit[victim] = true;
						SDKHooks_TakeDamage(victim, clientIdx, clientIdx, BH_Damage[clientIdx] / 3, DMG_CRIT, GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Melee));
					}
				}
			}
			
			// destroy the projectile if the hadouken passes a barrier that players can't cross
			if (BH_IsPlayerSolid(BH_LastActualPos[clientIdx], projectilePos))
			{
				BH_DestroyProjectile(clientIdx); // will also blink
				continue;
			}
			else
			{
				BH_LastActualPos[clientIdx][0] = projectilePos[0];
				BH_LastActualPos[clientIdx][1] = projectilePos[1];
				BH_LastActualPos[clientIdx][2] = projectilePos[2];
			}
			
			// check validity of current spot for the future blink
			new bool:failure = false;
			static Float:testPos[3];
			for (int xOffCount = 0; xOffCount < 3; xOffCount++)
			{
				for (int yOffCount = 0; yOffCount < 3; yOffCount++)
				{
					failure = false;
					
					testPos[0] = projectilePos[0] + BH_GetXYOffset(xOffCount);
					testPos[1] = projectilePos[1] + BH_GetXYOffset(yOffCount);
					testPos[2] = projectilePos[2];
					if (!IsSpotSafe(clientIdx, testPos))
					{
						testPos[2] -= 41.0;
						if (BH_IsPlayerSolid(projectilePos, testPos) || !IsSpotSafe(clientIdx, testPos))
						{
							testPos[2] += 82.0;
							if (BH_IsPlayerSolid(projectilePos, testPos) || !IsSpotSafe(clientIdx, testPos))
								failure = true;
						}
					}
					
					if (!failure)
						break;
				}
				
				if (!failure)
					break;
			}
			if (!failure)
			{
				BH_LastSafePos[clientIdx][0] = testPos[0];
				BH_LastSafePos[clientIdx][1] = testPos[1];
				BH_LastSafePos[clientIdx][2] = testPos[2];
			}
		}
	}
}

Float:BH_GetXYOffset(offCount)
{
	if (offCount == 1)
		return -12.0;
	else if (offCount == 2)
		return 12.0;
	return 0.0;
}

public Rage_BlinkHadouken(clientIdx)
{
	if (BH_KeyID[clientIdx] != BH_KEY_MEDIC)
		return;
	
	// is it time to end the blink?
	if (BH_BlinkReady[clientIdx])
	{
		BH_Blink(clientIdx);
		BH_WithheldRage[clientIdx] = 100.0; // refund all rage, since raging triggered the blink
		return;
	}
	
	// make a hadouken, and hold the rest for refunding
	if ((BH_Flags[clientIdx] & BH_FLAG_UNUSABLE_WHILE_STUNNED) && TF2_IsPlayerInCondition(clientIdx, TFCond_Dazed))
	{
		Nope(clientIdx);
		BH_WithheldRage[clientIdx] = 100.0;
	}
	else
	{
		BH_CreateHadouken(clientIdx);
		BH_WithheldRage[clientIdx] = 100.0 - BH_RageCost[clientIdx];
	}
}

public BH_OnPlayerRunCmd(clientIdx, buttons)
{
	if (BH_IsDOT[clientIdx] || BH_KeyID[clientIdx] == BH_KEY_MEDIC)
		return;
		
	new interestingKey = (BH_KeyID[clientIdx] == BH_KEY_RELOAD) ? IN_RELOAD : ((BH_KeyID[clientIdx] == BH_KEY_SPECIAL) ? IN_ATTACK3 : 0);
	new bool:keyDown = (interestingKey & buttons) != 0;
	if (keyDown && !BH_KeyDown[clientIdx])
	{
		new bossIdx = FF2_GetBossIndex(clientIdx);
		if (BH_BlinkReady[clientIdx])
			BH_Blink(clientIdx, false, true);
		else if (bossIdx >= 0)
		{
			new Float:rage = FF2_GetBossCharge(bossIdx, 0);

			if (rage < BH_RageCost[clientIdx])
				Nope(clientIdx);
			else if ((BH_Flags[clientIdx] & BH_FLAG_UNUSABLE_WHILE_STUNNED) && TF2_IsPlayerInCondition(clientIdx, TFCond_Dazed))
				Nope(clientIdx);
			else
			{
				FF2_SetBossCharge(bossIdx, 0, rage - BH_RageCost[clientIdx]);
				BH_CreateHadouken(clientIdx);
				
				if (PRINT_DEBUG_INFO)
					PrintToServer("[sarysamods9] Initiating Blink Hadouken, via OnPlayerRunCmd.");
			}
		}
	}
	BH_KeyDown[clientIdx] = keyDown;
}

/**
 * Multiple Spells and Equalize
 */
// based on asherkin and voogru's code, though this is almost exactly like the code used for Snowdrop's rockets
// luckily energy ball and sentry rocket derive from rocket so they should be easy
public Spells_CreateRocket(clientIdx, Float:speed, recolor, bool:isCharged)
{
	// create our rocket. no matter what, it's going to spawn, even if it ends up being out of map
	new Float:damage = fixDamageForFF2(3.0);
	static String:classname[MAX_ENTITY_CLASSNAME_LENGTH] = "CTFProjectile_EnergyBall";
	static String:entname[MAX_ENTITY_CLASSNAME_LENGTH] = "tf_projectile_energy_ball";
	
	new rocket = CreateEntityByName(entname);
	if (!IsValidEntity(rocket))
	{
		PrintToServer("[sarysamods9] Error: Invalid entity %s. Won't spawn rocket. This is sarysa's fault.", entname);
		return -1;
	}
	
	// determine spawn position
	static Float:spawnPosition[3];
	GetEntPropVector(clientIdx, Prop_Data, "m_vecOrigin", spawnPosition);
	spawnPosition[2] += 70.0;
		
	// get angles for rocket (smart targeting)
	static Float:spawnAngles[3];
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
	
	// determine velocity
	static Float:spawnVelocity[3];
	GetAngleVectors(spawnAngles, spawnVelocity, NULL_VECTOR, NULL_VECTOR);
	spawnVelocity[0] *= speed;
	spawnVelocity[1] *= speed;
	spawnVelocity[2] *= speed;
	
	// deploy!
	TeleportEntity(rocket, spawnPosition, spawnAngles, spawnVelocity);
	SetEntProp(rocket, Prop_Send, "m_bChargedShot", isCharged); // charged shot
	SetEntDataFloat(rocket, FindSendPropOffs(classname, "m_iDeflected") + 4, damage, true); // credit to voogru
	SetEntProp(rocket, Prop_Send, "m_nSkin", 1); // set skin to blue team's
	SetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity", clientIdx);
	SetVariantInt(BossTeam);
	AcceptEntityInput(rocket, "TeamNum", -1, -1, 0);
	SetVariantInt(BossTeam);
	AcceptEntityInput(rocket, "SetTeam", -1, -1, 0); 
	DispatchSpawn(rocket);
	
	// to get stats from the user's melee weapon
	SetEntPropEnt(rocket, Prop_Send, "m_hOriginalLauncher", GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Melee));
	SetEntPropEnt(rocket, Prop_Send, "m_hLauncher", GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Melee));
	
	// recolor the rocket
	Spells_SetEnergyBallColor(rocket, recolor);
	
	return rocket;
}

public Spells_SetEnergyBallColor(projectile, recolor)
{
	static Float:colorVector[3];
	colorVector[0] = GetR(recolor) / 255.0;
	colorVector[1] = GetG(recolor) / 255.0;
	colorVector[2] = GetB(recolor) / 255.0;
	SetEntPropVector(projectile, Prop_Send, "m_vColor1", colorVector);
	SetEntPropVector(projectile, Prop_Send, "m_vColor2", colorVector);
}

/**
 * Equalize
 *
 * Note that it uses two prefixes here:
 * - RE (rage equalize) is the generic prefix
 * - SPEI (spell projectile equalize interface) is simply an interface for multi-spell base
 */
public SPEI_Invoke(clientIdx)
{
	RE_InitiateProjectileRage(clientIdx, false);
}

public bool:SPEI_CanInvoke(clientIdx)
{
	return RE_ProjectileEntRef[clientIdx] == INVALID_ENTREF;
}

public SPEI_FormatHUDString(String:buffer[], bufferSize, String:format[], Float:rageRequired)
{
	Format(buffer, bufferSize, format, SPEI_Name, rageRequired, SPEI_Description);
}
 
public RE_AssignNeutralWeapon(victim) // only used if someone has no melee weapon, i.e. magical heavies, or an unequalizable one, like spies
{
	new weapon = -1;
	switch (TF2_GetPlayerClass(victim)) // I'm still not comfortable with the lack of "break" or leaking in the SM version
	{
		case TFClass_Scout:
			weapon = SpawnWeapon(victim, "tf_weapon_bat", 190, 101, 5, "");
		case TFClass_Soldier:
			weapon = SpawnWeapon(victim, "tf_weapon_shovel", 196, 101, 5, "");
		case TFClass_Pyro:
			weapon = SpawnWeapon(victim, "tf_weapon_fireaxe", 192, 101, 5, "");
		case TFClass_DemoMan:
			weapon = SpawnWeapon(victim, "tf_weapon_bottle", 191, 101, 5, "");
		case TFClass_Heavy:
			weapon = SpawnWeapon(victim, "tf_weapon_fists", 195, 101, 5, "");
		case TFClass_Engineer:
			weapon = SpawnWeapon(victim, "tf_weapon_wrench", 197, 101, 5, "");
		case TFClass_Medic:
			weapon = SpawnWeapon(victim, "tf_weapon_bonesaw", 198, 101, 5, "");
		case TFClass_Sniper, TFClass_Spy: // not assigning knives
			weapon = SpawnWeapon(victim, "tf_weapon_club", 193, 101, 5, "");
	}
	
	if (IsValidEntity(weapon))
		SetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon", weapon);
}

// credit to FF2 base for this trick
public Action:RE_GetMaxHealth(victim, &maxHealth)
{
	if (!RE_ActiveThisRound || !IsLivingPlayer(victim))
	{
		SDKUnhook(victim, SDKHook_GetMaxHealth, RE_GetMaxHealth);
		return Plugin_Continue;
	}

	if (RE_EqualizedUntil[victim] != FAR_FUTURE)
	{
		maxHealth = RE_MaxHP;
		return Plugin_Changed;
	}
	SDKUnhook(victim, SDKHook_GetMaxHealth, RE_GetMaxHealth);
	return Plugin_Continue;
}

public Action:RE_BlockedCommands(victim, const String:command[], argc)
{
	if (!RE_ActiveThisRound)
		return Plugin_Continue;

	if (IsLivingPlayer(victim) && RE_EqualizedUntil[victim] != FAR_FUTURE)
		return Plugin_Stop;
	return Plugin_Continue;
}

public bool:RE_WasBleeding = false;
public bool:RE_WasBurning = false;
new bool:RE_DPEVictimArray[MAX_PLAYERS_ARRAY];
public Action:RE_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsLivingPlayer(victim) && GetClientTeam(victim) == MercTeam)
	{
		// check if the special equalize projectile hit the player
		if (IsLivingPlayer(attacker) && RE_CanUse[attacker])
		{
			if (RE_Mode[attacker] == RE_MODE_PROJECTILE && RE_ProjectileEntRef[attacker] != INVALID_ENTREF)
			{
				new projectile = EntRefToEntIndex(RE_ProjectileEntRef[attacker]);
				if (IsValidEntity(projectile) && projectile == inflictor)
				{
					if (PRINT_DEBUG_SPAM)
						PrintToServer("[sarysamods9] %d hit %d with equalize projectile, still must pass distance test.", attacker, victim);

					if (RE_Radius[attacker] <= 0.0 || IsInRange(inflictor, victim, RE_Radius[attacker]))
					{
						if (PRINT_DEBUG_SPAM)
							PrintToServer("[sarysamods9] Also within constrained range: %f", RE_Radius[attacker]);
						RE_DPEVictimArray[victim] = true;
					}
					return Plugin_Stop;
				}
			}
		}
		
		if (RE_EqualizedUntil[victim] != FAR_FUTURE)
		{
			//PrintToServer("incoming damage for victim, attacker=%d inflictor=%d damage=%f, damagetype=0x%x, weapon=%d vs %d", attacker, inflictor, damage, damagetype, weapon, GetPlayerWeaponSlot(victim, TFWeaponSlot_Melee));
			if (victim == attacker)
				return Plugin_Stop; // fix for boston basher, maybe GRU, etc.

			damage *= RE_DamageModifier[victim];
			return Plugin_Changed;
		}
	}

	if (IsLivingPlayer(attacker) && GetClientTeam(attacker) == MercTeam)
	{
		if (IsLivingPlayer(victim) && GetClientTeam(victim) == BossTeam)
		{
			if (RE_EqualizedUntil[attacker] != FAR_FUTURE && weapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee))
			{
				//PrintToServer("incoming damage for hale, attacker=%d inflictor=%d damage=%f, damagetype=0x%x, weapon=%d vs %d", attacker, inflictor, damage, damagetype, weapon, GetPlayerWeaponSlot(victim, TFWeaponSlot_Melee));
				if (damagetype & DMG_CLUB)
				{
					damage = RE_MeleeDamage[RE_EqualizedBy[attacker]];
					damagetype |= DMG_CRIT;
				}
				else
					damage = fmin(RE_MeleeDamage[RE_EqualizedBy[attacker]], damage);
				RE_WasBleeding = TF2_IsPlayerInCondition(victim, TFCond_Bleeding);
				RE_WasBurning = TF2_IsPlayerInCondition(victim, TFCond_OnFire);
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

public RE_OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	if (IsLivingPlayer(attacker) && GetClientTeam(attacker) == MercTeam)
	{
		if (IsLivingPlayer(victim) && GetClientTeam(victim) == BossTeam)
		{
			if (RE_EqualizedUntil[attacker] != FAR_FUTURE)
			{
				if (!RE_WasBleeding && TF2_IsPlayerInCondition(victim, TFCond_Bleeding))
					TF2_RemoveCondition(victim, TFCond_Bleeding);
					
				if (!RE_WasBurning && TF2_IsPlayerInCondition(victim, TFCond_OnFire))
					TF2_RemoveCondition(victim, TFCond_OnFire);
			}
		}
	}
	
	RE_WasBleeding = false;
	RE_WasBurning = false;
}
 
public RE_AddEqualize(bool:victimArray[MAX_PLAYERS_ARRAY], clientIdx, Float:curTime, Float:duration)
{
	// if this is being called, we need to remove bleed and fire.
	// otherwise, it can get damage boosted later.
	if (TF2_IsPlayerInCondition(clientIdx, TFCond_Bleeding))
		TF2_RemoveCondition(clientIdx, TFCond_Bleeding);
	if (TF2_IsPlayerInCondition(clientIdx, TFCond_OnFire))
		TF2_RemoveCondition(clientIdx, TFCond_OnFire);
				
	for (new victim = 1; victim < MAX_PLAYERS; victim++)
	{
		if (!victimArray[victim])
			continue;
		else if (TF2_IsPlayerInCondition(victim, TFCond_Ubercharged) && (RE_Flags[clientIdx] & RE_FLAG_UBER_BLOCKS_SPELL) != 0)
			continue;
		
		// play this regardless of it's a new equalize or a refresh
		if (strlen(RE_VictimSound) > 3)
		{
			EmitSoundToClient(victim, RE_VictimSound);
			EmitSoundToClient(victim, RE_VictimSound);
		}

		if (RE_EqualizedUntil[victim] != FAR_FUTURE)
		{
			RE_EqualizedUntil[victim] = curTime + duration;
			continue; // already equalized. this will be very common in the DOT version
		}
		
		// spy must undisguise now, before RE_EqualizedUntil is set
		if (TF2_GetPlayerClass(victim) == TFClass_Spy)
			if (RE_Flags[RE_EqualizedBy[victim]] & RE_FLAG_UNDISGUISE)
				TF2_RemovePlayerDisguise(victim);
		
		// various all class initial settings
		RE_EqualizedUntil[victim] = curTime + duration;
		RE_EqualizedBy[victim] = clientIdx;
		RE_ExpectedIntervalTime[victim] = FAR_FUTURE;
		
		//if (TF2_IsPlayerInCondition(victim, TFCond_Taunting))
		//	TF2_RemoveCondition(victim, TFCond_Taunting);
		RE_OldMaxHP[victim] = GetEntProp(victim, Prop_Data, "m_iMaxHealth");
		if (TF2_GetPlayerClass(victim) == TFClass_DemoMan)
			RE_OldMaxHP[victim] += 15 * (max(0, min(4, GetEntProp(victim, Prop_Send, "m_iDecapitations"))));
		SDKHook(victim, SDKHook_GetMaxHealth, RE_GetMaxHealth);
		SetEntProp(victim, Prop_Data, "m_iHealth", RE_MaxHP);
		SetEntProp(victim, Prop_Send, "m_iHealth", RE_MaxHP);
		RE_OldSpeed[victim] = GetEntPropFloat(victim, Prop_Send, "m_flMaxspeed");

		// need to stop engineers from carrying or placing
		// and destroy whatever they had. otherwise they'll be in a broken state.
		if (TF2_GetPlayerClass(victim) == TFClass_Engineer)
		{
			for (new pass = 0; pass <= 2; pass++)
			{
				static String:classname[MAX_ENTITY_CLASSNAME_LENGTH];
				if (pass == 0)
					classname = "obj_sentrygun";
				else if (pass == 1)
					classname = "obj_dispenser";
				else if (pass == 2)
					classname = "obj_teleporter";
					
				new building = -1;
				while ((building = FindEntityByClassname(building, classname)) != -1)
				{
					if (GetEntPropEnt(building, Prop_Send, "m_hBuilder") == victim)
					{
						if (GetEntProp(building, Prop_Send, "m_bPlacing") || GetEntProp(building, Prop_Send, "m_bCarried"))
						{
							if (PRINT_DEBUG_SPAM)
								PrintToServer("[sarysamods9] Destroyed engineer %d's building %d before weapon switch.", victim, building);
						
							AcceptEntityInput(building, "kill");
							break;
						}
						else if (RE_Flags[RE_EqualizedBy[victim]] & RE_FLAG_DESTROY_BUILDINGS)
						{
							SDKHooks_TakeDamage(building, clientIdx, clientIdx, 9999.0, DMG_GENERIC, -1);
						}
						else if (pass == 0 && (RE_Flags[RE_EqualizedBy[victim]] & RE_FLAG_STUN_SENTRIES) != 0)
						{
							DSSG_StunOneSentry(building, duration);
						}
					}
				}
			}
		}
		
		// stun and unstun to remove any invalid state (heavy shooting, allclass taunting, sniper scoped)
		// sniper scoped is especially nasty as it causes a client crash on instant weapon switch
		TF2_StunPlayer(victim, 0.1, 0.0, TF_STUNFLAG_BONKSTUCK | TF_STUNFLAG_NOSOUNDOREFFECT);
		TF2_RemoveCondition(victim, TFCond_Dazed);
		
		// heavy specific, shut down any active minigun
		if (TF2_GetPlayerClass(victim) == TFClass_Heavy)
		{
			new minigun = GetPlayerWeaponSlot(victim, TFWeaponSlot_Primary);
			if (IsValidEntity(minigun) && IsInstanceOf(minigun, "tf_weapon_minigun"))
				SetEntProp(minigun, Prop_Send, "m_iWeaponState", 0);
		}
		
		// sniper specific, stun the user and then unstun, hopefully getting them out of scope
		//if (TF2_GetPlayerClass(victim) == TFClass_Sniper)
		//{
		//	TF2_StunPlayer(victim, 0.1, 0.0, TF_STUNFLAG_BONKSTUCK | TF_STUNFLAG_NOSOUNDOREFFECT);
		//	TF2_RemoveCondition(victim, TFCond_Dazed);
		//}
		
		// restrict to melee now
		TF2_AddCondition(victim, TFCond_RestrictToMelee, -1.0); // this works, but the active weapon must also be changed
		RE_HadNoMelee[victim] = false;
		new weapon = GetPlayerWeaponSlot(victim, TFWeaponSlot_Melee);
		if (!IsValidEntity(weapon))
		{
			RE_AssignNeutralWeapon(victim);
			RE_HadNoMelee[victim] = true;
		}
		else
			SetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon", weapon);
		
		// spy specific: replace spy weapon and drain their cloak
		if (TF2_GetPlayerClass(victim) == TFClass_Spy)
		{
			if (!IsValidEntity(weapon))
				RE_OldSpyWeaponIdx[victim] = -1;
			else
			{
				RE_OldSpyWeaponIdx[victim] = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
				TF2_RemoveWeaponSlot(victim, TFWeaponSlot_Melee);
				RE_AssignNeutralWeapon(victim);
			}
				
			if (RE_Flags[RE_EqualizedBy[victim]] & RE_FLAG_SUPPRESS_CLOAK)
				SetEntPropFloat(victim, Prop_Send, "m_flCloakMeter", 0.0);
		}
		
		// demoman specific: store their old head count and remove their heads
		if (TF2_GetPlayerClass(victim) == TFClass_DemoMan)
		{
			if (RE_Flags[RE_EqualizedBy[victim]] & RE_FLAG_SUPPRESS_HEADS)
			{
				RE_OldDemoHeadCount[victim] = GetEntProp(victim, Prop_Send, "m_iDecapitations");
				SetEntProp(victim, Prop_Send, "m_iDecapitations", 0);
			}
		}
	}
}

public RE_RemoveEqualize(bool:victimArray[MAX_PLAYERS_ARRAY])
{
	for (new victim = 1; victim < MAX_PLAYERS; victim++)
	{
		if (!victimArray[victim])
			continue;
			
		// general cleanup
		RE_EqualizedUntil[victim] = FAR_FUTURE;
		TF2_RemoveCondition(victim, TFCond_RestrictToMelee);
		if (TF2_IsPlayerInCondition(victim, TFCond_Taunting))
			TF2_RemoveCondition(victim, TFCond_Taunting);
		SDKUnhook(victim, SDKHook_GetMaxHealth, RE_GetMaxHealth);
		SetEntProp(victim, Prop_Data, "m_iHealth", RE_OldMaxHP[victim]);
		SetEntProp(victim, Prop_Send, "m_iHealth", RE_OldMaxHP[victim]);
		SetEntPropFloat(victim, Prop_Send, "m_flMaxspeed", RE_OldSpeed[victim]);
		
		// spies: restore cloak and old weapon
		if (TF2_GetPlayerClass(victim) == TFClass_Spy)
		{
			TF2_RemoveWeaponSlot(victim, TFWeaponSlot_Melee);
			if (RE_OldSpyWeaponIdx[victim] == -1)
			{
				SetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(victim, TFWeaponSlot_Primary));
			}
			else
			{
				// YER and reskin(s), allow disguise since VSP does
				new weapon = -1;
				if (RE_OldSpyWeaponIdx[victim] == 225 || RE_OldSpyWeaponIdx[victim] == 574)
					weapon = SpawnWeapon(victim, "tf_weapon_knife", RE_OldSpyWeaponIdx[victim], 101, 5, "155 ; 0");
				else
					weapon = SpawnWeapon(victim, "tf_weapon_knife", RE_OldSpyWeaponIdx[victim], 101, 5, "");
					
				if (IsValidEntity(weapon))
					SetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon", weapon);
			}
							
			// fully restore cloak
			if (RE_Flags[RE_EqualizedBy[victim]] & RE_FLAG_SUPPRESS_CLOAK)
				SetEntPropFloat(victim, Prop_Send, "m_flCloakMeter", 100.0);
		}
		
		// demoman specific: store their old head count and remove their heads
		if (TF2_GetPlayerClass(victim) == TFClass_DemoMan)
			if (RE_Flags[RE_EqualizedBy[victim]] & RE_FLAG_SUPPRESS_HEADS)
				SetEntProp(victim, Prop_Send, "m_iDecapitations", RE_OldDemoHeadCount[victim]);
				
		// engineer specific: unstun sentry if it still stands
		if (TF2_GetPlayerClass(victim) == TFClass_Engineer && (RE_Flags[RE_EqualizedBy[victim]] & RE_FLAG_STUN_SENTRIES) != 0)
		{
			new building = -1;
			while ((building = FindEntityByClassname(building, "obj_sentrygun")) != -1)
			{
				if (GetEntPropEnt(building, Prop_Send, "m_hBuilder") == victim)
				{
					DSSG_UnstunOneSentry(building);
					break;
				}
			}
		}
				
		// all class except Spy, change weapon to something other than melee, if possible
		// secondary role is to ensure speed calculations are accurate
		if (TF2_GetPlayerClass(victim) != TFClass_Spy)
		{
			new weapon = GetPlayerWeaponSlot(victim, TFWeaponSlot_Primary);
			if (!IsValidEntity(weapon))
				weapon = GetPlayerWeaponSlot(victim, TFWeaponSlot_Secondary);
			if (IsValidEntity(weapon))
				SetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon", weapon);
				
			if (RE_HadNoMelee[victim])
			{
				RE_HadNoMelee[victim] = false;
				TF2_RemoveWeaponSlot(victim, TFWeaponSlot_Melee);
			}
		}
	}
}

public RE_Tick(Float:curTime)
{
	// checks for the hale done first and independent of checks for the victims
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx) || GetClientTeam(clientIdx) == MercTeam)
			continue;

		// check projectile if valid
		if (RE_CanUse[clientIdx] && RE_Mode[clientIdx] == RE_MODE_PROJECTILE)
		{
			if (RE_ProjectileEntRef[clientIdx] != INVALID_ENTREF)
			{
				new projectile = EntRefToEntIndex(RE_ProjectileEntRef[clientIdx]);
				if (!IsValidEntity(projectile))
				{
					RE_ProjectileEntRef[clientIdx] = INVALID_ENTREF;
					RE_AddEqualize(RE_DPEVictimArray, clientIdx, curTime, RE_Duration[clientIdx]);
				}
				else if (GetEntProp(projectile, Prop_Send, "m_iDeflected") != 0)
				{
					SetEntProp(projectile, Prop_Send, "m_iDeflected", 0);
					SetEntPropEnt(projectile, Prop_Send, "m_hOwnerEntity", clientIdx);
					SetEntPropEnt(projectile, Prop_Send, "m_hLauncher", GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Melee));
					Spells_SetEnergyBallColor(projectile, RE_ProjectileRecolor[clientIdx]);
				}
			}
		}
	}

	static bool:victimArray[MAX_PLAYERS_ARRAY];
	new bool:changed = false;
	for (new victim = 1; victim < MAX_PLAYERS; victim++)
	{
		victimArray[victim] = false;
		
		if (!IsLivingPlayer(victim) || GetClientTeam(victim) == BossTeam)
			continue;
		
		if (curTime >= RE_EqualizedUntil[victim])
		{
			victimArray[victim] = true;
			changed = true;
		}
		else if (RE_EqualizedUntil[victim] != FAR_FUTURE)
		{
			// maintain cloak and disguisesuppression
			if (TF2_GetPlayerClass(victim) == TFClass_Spy)
			{
				if (RE_Flags[RE_EqualizedBy[victim]] & RE_FLAG_SUPPRESS_CLOAK)
					SetEntPropFloat(victim, Prop_Send, "m_flCloakMeter", 0.0);
					
				TF2_RemovePlayerDisguise(victim);
			}
					
			// suppress heads
			if (TF2_GetPlayerClass(victim) == TFClass_DemoMan)
				if (RE_Flags[RE_EqualizedBy[victim]] & RE_FLAG_SUPPRESS_HEADS)
					SetEntProp(victim, Prop_Send, "m_iDecapitations", 0);
					
			// suppress scout double jump
			if (TF2_GetPlayerClass(victim) == TFClass_Scout && (GetEntityFlags(victim) & FL_ONGROUND) == 0)
				if (RE_Flags[RE_EqualizedBy[victim]] & RE_FLAG_SUPPRESS_AIR_JUMP)
					if (GetEntProp(victim, Prop_Send, "m_iAirDash") != 9999)
						SetEntProp(victim, Prop_Send, "m_iAirDash", 9999);
						
			// suppress overheal
			if (RE_Flags[RE_EqualizedBy[victim]] & RE_FLAG_SUPPRESS_OVERHEAL)
			{
				if (GetEntProp(victim, Prop_Data, "m_iHealth") > RE_MaxHP)
				{
					SetEntProp(victim, Prop_Data, "m_iHealth", RE_MaxHP);
					SetEntProp(victim, Prop_Send, "m_iHealth", RE_MaxHP);
				}
			}
			
			// adjust rate of fire interval when necessary
			new weapon = GetPlayerWeaponSlot(victim, TFWeaponSlot_Melee);
			if (IsValidEntity(weapon) && RE_ExpectedIntervalTime[victim] != GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack"))
			{
				RE_ExpectedIntervalTime[victim] = GetGameTime() + RE_MeleeInterval[RE_EqualizedBy[victim]];
				SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", RE_ExpectedIntervalTime[victim]);
			}
			
			// adjust move speed
			new Float:moveSpeed = RE_MoveSpeed[RE_EqualizedBy[victim]];
			if (moveSpeed != GetEntPropFloat(victim, Prop_Send, "m_flMaxspeed"))
				SetEntPropFloat(victim, Prop_Send, "m_flMaxspeed", moveSpeed);
		}
	}
	
	if (changed)
		RE_RemoveEqualize(victimArray);
}

public RE_DisplayCastingParticle(clientIdx)
{
	if (strlen(RE_CastSound) > 3)
		EmitSoundToAll(RE_CastSound);

	if (!IsEmptyString(RE_CastingParticle))
	{
		new particle = -1;
		if (IsEmptyString(RE_CastingAttachment))
		{
			// attach particle to z=70 offset
			particle = AttachParticle(clientIdx, RE_CastingParticle, 70.0, true);
		}
		else
		{
			// attach particle to attachment, only to remove it moments later
			particle = AttachParticleToAttachment(clientIdx, RE_CastingParticle, RE_CastingAttachment);
		}
		
		if (IsValidEntity(particle))
			CreateTimer(1.0, RemoveEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public RE_FindVictims(clientIdx, Float:duration, bool:cancelOthers)
{
	// determine who needs to be equalized
	new Float:radiusSquared = RE_Radius[clientIdx] * RE_Radius[clientIdx];
	static bool:victimArray[MAX_PLAYERS_ARRAY];
	static Float:bossPos[3];
	GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", bossPos);
	
	for (new victim = 1; victim < MAX_PLAYERS; victim++)
	{
		victimArray[victim] = false;
		if (!IsLivingPlayer(victim) || GetClientTeam(victim) == BossTeam)
			continue;
			
		static Float:victimPos[3];
		GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
		if (radiusSquared == 0.0 || GetVectorDistance(bossPos, victimPos, true) <= radiusSquared)
			victimArray[victim] = true;
	}
	
	RE_AddEqualize(victimArray, clientIdx, GetEngineTime(), RE_Duration[clientIdx]);
	
	if (cancelOthers)
	{
		new bool:changed = false;
		for (new victim = 1; victim < MAX_PLAYERS; victim++)
		{
			if (!IsLivingPlayer(victim) || GetClientTeam(victim) == BossTeam)
			{
				victimArray[victim] = false;
				continue;
			}
			
			// if someone got out of range, add them to the remove array
			if (!victimArray[victim] && RE_EqualizedBy[victim] == clientIdx && RE_EqualizedUntil[victim] != FAR_FUTURE)
			{
				changed = true;
				victimArray[victim] = true;
			}
			else
				victimArray[victim] = false;
		}
		
		if (changed)
			RE_RemoveEqualize(victimArray);
	}
}

public RE_InitiateProjectileRage(clientIdx, bool:isDOT)
{
	if (RE_ProjectileEntRef[clientIdx] != INVALID_ENTREF)
	{
		Nope(clientIdx);
		if (isDOT)
			CancelDOTAbilityActivation(clientIdx);
		return;
	}

	new rocket = Spells_CreateRocket(clientIdx, RE_ProjectileSpeed[clientIdx], RE_ProjectileRecolor[clientIdx], true);
	if (!IsValidEntity(rocket))
	{
		PrintCenterText(clientIdx, "Projectile failed to spawn. Notify an admin!");
		if (isDOT)
			CancelDOTAbilityActivation(clientIdx);
		return;
	}
	
	RE_DisplayCastingParticle(clientIdx);
	
	for (new victim = 1; victim < MAX_PLAYERS; victim++)
		RE_DPEVictimArray[victim] = false;
	RE_ProjectileEntRef[clientIdx] = EntIndexToEntRef(rocket);
}

public RE_OnDOTActivate(clientIdx)
{
	RE_FindVictims(clientIdx, 99999.0, false);
	RE_DisplayCastingParticle(clientIdx);
}

public RE_OnDOTDeactivate(clientIdx)
{
	static bool:victimArray[MAX_PLAYERS_ARRAY];
	new bool:changed = false;
	for (new victim = 1; victim < MAX_PLAYERS; victim++)
	{
		victimArray[victim] = false;
		if (!IsLivingPlayer(victim) || GetClientTeam(victim) == BossTeam)
			continue;
			
		if (RE_EqualizedBy[victim] == clientIdx && RE_EqualizedUntil[victim] != FAR_FUTURE)
		{
			changed = true;
			victimArray[victim] = true;
		}
	}
	
	if (changed)
		RE_RemoveEqualize(victimArray);
}

public RE_OnDOTTick(clientIdx)
{
	RE_FindVictims(clientIdx, 99999.0, true);
}
 
public RE_OnDPActivate(clientIdx)
{
	RE_InitiateProjectileRage(clientIdx, true);
}

public RE_OnDPTick(clientIdx)
{
	ForceDOTAbilityDeactivation(clientIdx);
}
 
public Rage_Equalize(clientIdx)
{
	RE_FindVictims(clientIdx, RE_Duration[clientIdx], false);
	RE_DisplayCastingParticle(clientIdx);
}

/**
 * Multi-Spell Base
 */
MSB_GetActionKey(bossIdx, argIdx)
{
	new keyIdx = FF2_GetAbilityArgument(bossIdx, this_plugin_name, MSB_STRING, argIdx);
	if (keyIdx == 1)
		return IN_RELOAD;
	else if (keyIdx == 2)
		return IN_ATTACK3;
	else if (keyIdx == 3)
		return IN_USE;
	return 0; // no key, implied is "call for medic"
}
 
MSB_RemoveSpellsFromAll()
{
	// ADD NOTHING ELSE HERE, this has to be called on plugin start so keep it minimal!
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		MSB_NumSpells[clientIdx] = 0;
		MSB_CurrentSpell[clientIdx] = 0;
	}
}

#define MSB_PLUGIN_NAME_MAX 33
#define MSB_METHOD_NAME_MAX 65
new String:MSB_PluginName[MSB_PLUGIN_NAME_MAX];
new String:MSB_MethodName[MSB_METHOD_NAME_MAX];
MSB_FixPluginName(packNum, bool:forReflection)
{
	if (forReflection)
		Format(MSB_PluginName, MSB_PLUGIN_NAME_MAX, "ff2_sarysamods%d.ff2", packNum);
	else
		Format(MSB_PluginName, MSB_PLUGIN_NAME_MAX, "ff2_sarysamods%d", packNum);
}

MSB_FixMethodName(const String:format[], const String:prefix[MSB_MAX_PREFIX_SIZE])
{
	Format(MSB_MethodName, MSB_METHOD_NAME_MAX, format, prefix);
}

// public interface - init
public MSB_InitSubability(bossIdx, clientIdx, packNum, const String:abilityName[MAX_ABILITY_NAME_LENGTH], const String:prefix[MSB_MAX_PREFIX_SIZE])
{
	if (MSB_NumSpells[clientIdx] >= MSB_MAX_SPELLS)
	{
		PrintToServer("[sarysamods9] ERROR: Boss %d (client %d) has too many spells. Cannot add %s from pack %d", bossIdx, clientIdx, abilityName, packNum);
		return;
	}
	//PrintToServer("[sarysamods9] INITTING: Boss %d (client %d) spell. %s from pack %d with prefix %s", bossIdx, clientIdx, abilityName, packNum, prefix);

	MSB_FixPluginName(packNum, false);
	new spellIdx = MSB_NumSpells[clientIdx];
	MSB_SpellPackNum[clientIdx][spellIdx] = packNum;
	strcopy(MSB_SpellPrefix[clientIdx][spellIdx], MSB_MAX_PREFIX_SIZE, prefix);
	MSB_SpellCost[clientIdx][spellIdx] = FF2_GetAbilityArgumentFloat(bossIdx, MSB_PluginName, abilityName, 1);
	MSB_SpellCooldown[clientIdx][spellIdx] = FF2_GetAbilityArgumentFloat(bossIdx, MSB_PluginName, abilityName, 2);
	MSB_NumSpells[clientIdx]++;
}

// private - used to minimize all reflection code
MSB_GetMethod(clientIdx, spellIdx, const String:format[], &Handle:retPlugin, &Function:retFunc)
{
	MSB_FixPluginName(MSB_SpellPackNum[clientIdx][spellIdx], true);
	MSB_FixMethodName(format, MSB_SpellPrefix[clientIdx][spellIdx]);

	static String:buffer[256];
	new Handle:iter = GetPluginIterator();
	new Handle:plugin = INVALID_HANDLE;
	while (MorePlugins(iter))
	{
		plugin = ReadPlugin(iter);
		
		GetPluginFilename(plugin, buffer, sizeof(buffer));
		if (StrContains(buffer, MSB_PluginName, false) != -1)
			break;
		else
			plugin = INVALID_HANDLE;
	}
	
	CloseHandle(iter);
	if (plugin != INVALID_HANDLE)
	{
		new Function:func = GetFunctionByName(plugin, MSB_MethodName);
		if (func != INVALID_FUNCTION)
		{
			retPlugin = plugin;
			retFunc = func;
		}
		else
			PrintToServer("[sarysamods9] ERROR: Could not find %s:%s()", MSB_PluginName, MSB_MethodName);
	}
	else
		PrintToServer("[sarysamods9] ERROR: Could not find %s. %s() failed.", MSB_PluginName, MSB_MethodName);
}

MSB_ExecuteSpell(clientIdx, spellIdx)
{
	if (!IsEmptyString(MSB_CastingParticle))
	{
		new particle = -1;
		if (IsEmptyString(MSB_CastingAttachment))
			particle = AttachParticle(clientIdx, MSB_CastingParticle, 70.0, true);
		else
			particle = AttachParticleToAttachment(clientIdx, MSB_CastingParticle, MSB_CastingAttachment);
			
		if (IsValidEntity(particle))
			CreateTimer(1.0, RemoveEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	}

	new Handle:plugin = INVALID_HANDLE;
	new Function:func = INVALID_FUNCTION;
	MSB_GetMethod(clientIdx, spellIdx, "%s_Invoke", plugin, func);
	if (plugin != INVALID_HANDLE && func != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, func);
		Call_PushCell(clientIdx);
		Call_Finish();
	}
}

bool:MSB_CanExecuteSpell(clientIdx, spellIdx)
{
	new bool:result = false;
	new Handle:plugin = INVALID_HANDLE;
	new Function:func = INVALID_FUNCTION;
	MSB_GetMethod(clientIdx, spellIdx, "%s_CanInvoke", plugin, func);
	if (plugin != INVALID_HANDLE && func != INVALID_FUNCTION)
	{
		//PrintToServer("can you oblige?");
		Call_StartFunction(plugin, func);
		Call_PushCell(clientIdx);
		Call_Finish(result);
		//PrintToServer("yay. I think. result=%d", result);
	}
	return result;
}

//new MSB_testshift = -2;
MSB_FormatHUD(clientIdx, spellIdx, String:buffer[MAX_CENTER_TEXT_LENGTH], String:format[MAX_CENTER_TEXT_LENGTH])
{
	//MSB_testshift++;
	//if (MSB_testshift >= 32)
	//	return;

	new Handle:plugin = INVALID_HANDLE;
	new Function:func = INVALID_FUNCTION;
	MSB_GetMethod(clientIdx, spellIdx, "%s_FormatHUDString", plugin, func);
	if (plugin != INVALID_HANDLE && func != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, func);
		Call_PushStringEx(buffer, MAX_CENTER_TEXT_LENGTH, 2, 1); //(MSB_testshift < 0) ? 0 : (1<<MSB_testshift));
		Call_PushCell(MAX_CENTER_TEXT_LENGTH);
		Call_PushStringEx(format, MAX_CENTER_TEXT_LENGTH, 2, 1); //(MSB_testshift < 0) ? 0 : (1<<MSB_testshift));
		Call_PushFloat(MSB_SpellCost[clientIdx][spellIdx]);
		Call_Finish();
	}
}

public bool:MSB_CurrentSpellAvailable(clientIdx, bossIdx, Float:curTime)
{
	if (TF2_IsPlayerInCondition(clientIdx, TFCond_Dazed))
		return false;

	new spellIdx = MSB_CurrentSpell[clientIdx];
	if (MSB_CooldownEndsAt[clientIdx][spellIdx] > curTime)
		return false;
		
	new Float:rage = FF2_GetBossCharge(bossIdx, 0);
	if (rage < MSB_SpellCost[clientIdx][spellIdx])
		return false;
	
	return MSB_CanExecuteSpell(clientIdx, spellIdx);
}

public Action:MSB_MedicCommand(clientIdx, const String:command[], argc)
{
	if (!IsLivingPlayer(clientIdx) || GetClientTeam(clientIdx) != BossTeam)
		return Plugin_Continue;
	
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0 || MSB_ActivationKey[clientIdx] != 0)
		return Plugin_Continue;

	new String:unparsedArgs[4];
	GetCmdArgString(unparsedArgs, 4);
	if (!strcmp(unparsedArgs, "0 0"))
		MSB_ActivatedByMedic[clientIdx] = true; // validity is checked next frame
	
	return Plugin_Continue;
}

public MSB_Tick(clientIdx, buttons, Float:curTime)
{
	if (MSB_NumSpells[clientIdx] == 0)
		return; // guess they haven't loaded yet.

	new bool:selKeyDown = (buttons & MSB_SelectionKey[clientIdx]) != 0;
	new bool:reverseSelKeyDown = (buttons & MSB_ReverseSelectionKey[clientIdx]) != 0;
	new bool:actKeyDown = (buttons & MSB_ActivationKey[clientIdx]) != 0;
	
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
	{
		PrintToServer("[sarysamods9] ERROR: Invalid boss index for %d or %d has no spells. Disabling multi-spell base.");
		MSB_CanUse[clientIdx] = false;
		return;
	}
	
	if (!MSB_TweakedHUDs[clientIdx])
	{
		MSB_TweakedHUDs[clientIdx] = true;
		FF2_SetFF2flags(clientIdx, FF2_GetFF2flags(clientIdx) | FF2FLAG_HUDDISABLED);
		DD_SetForceHUDEnabled(clientIdx, true);
	}
		
	// selection key first
	if (selKeyDown && !MSB_SelKeyDown[clientIdx])
	{
		MSB_CurrentSpell[clientIdx]++;
		MSB_CurrentSpell[clientIdx] %= MSB_NumSpells[clientIdx];
		MSB_UpdateHUDAt[clientIdx] = curTime;
	}
	MSB_SelKeyDown[clientIdx] = selKeyDown;
	
	// reverse selection key next
	if (reverseSelKeyDown && !MSB_ReverseSelKeyDown[clientIdx])
	{
		MSB_CurrentSpell[clientIdx]--;
		if (MSB_CurrentSpell[clientIdx] < 0)
			MSB_CurrentSpell[clientIdx] = MSB_NumSpells[clientIdx] - 1;
		MSB_UpdateHUDAt[clientIdx] = curTime;
	}
	MSB_ReverseSelKeyDown[clientIdx] = reverseSelKeyDown;
	
	// activation key after the selection change
	if ((actKeyDown && !MSB_ActKeyDown[clientIdx]) || MSB_ActivatedByMedic[clientIdx])
	{
		// refund rage if FF2 ate it up
		if (MSB_ActivatedByMedic[clientIdx] && MSB_RageSpent[clientIdx])
		{
			FF2_SetBossCharge(bossIdx, 0, 100.0);
		}
	
		MSB_ActivatedByMedic[clientIdx] = false;
		MSB_RageSpent[clientIdx] = false;
	
		new spellIdx = MSB_CurrentSpell[clientIdx];
		if (MSB_CurrentSpellAvailable(clientIdx, bossIdx, curTime))
		{
			MSB_ExecuteSpell(clientIdx, spellIdx);
			new Float:rage = FF2_GetBossCharge(bossIdx, 0);
			FF2_SetBossCharge(bossIdx, 0, rage - MSB_SpellCost[clientIdx][spellIdx]);
			MSB_CooldownEndsAt[clientIdx][spellIdx] = curTime + MSB_SpellCooldown[clientIdx][spellIdx];
			MSB_UpdateHUDAt[clientIdx] = curTime;
		}
	}
	MSB_ActKeyDown[clientIdx] = actKeyDown;
	
	// finally, do the HUD check
	if (curTime >= MSB_UpdateHUDAt[clientIdx] && (buttons & IN_SCORE) == 0)
	{
		MSB_UpdateHUDAt[clientIdx] = curTime + MSB_HUD_INTERVAL;
		new spellIdx = MSB_CurrentSpell[clientIdx];
		static String:buffer[MAX_CENTER_TEXT_LENGTH];
		new bool:available = MSB_CurrentSpellAvailable(clientIdx, bossIdx, curTime);
		
		// first the ability HUD
		if (available)
		{
			MSB_FormatHUD(clientIdx, spellIdx, buffer, MSB_HUDAvailableFormat);
			SetHudTextParams(-1.0, MSB_HudY[clientIdx], MSB_HUD_INTERVAL + 0.05, GetR(MSB_HUDAvailableColor[clientIdx]), GetG(MSB_HUDAvailableColor[clientIdx]), GetB(MSB_HUDAvailableColor[clientIdx]), 255);
		}
		else
		{
			MSB_FormatHUD(clientIdx, spellIdx, buffer, MSB_HUDUnavailableFormat);
			SetHudTextParams(-1.0, MSB_HudY[clientIdx], MSB_HUD_INTERVAL + 0.05, GetR(MSB_HUDUnavailableColor[clientIdx]), GetG(MSB_HUDUnavailableColor[clientIdx]), GetB(MSB_HUDUnavailableColor[clientIdx]), 255);
		}
		ShowSyncHudText(clientIdx, MSB_HUDHandle, buffer);
		
		// now the FF2 replacement HUD
		SetHudTextParams(-1.0, MSB_HUDReplacementY[clientIdx], MSB_HUD_INTERVAL + 0.05, 255, 255, 255, 255);
		ShowSyncHudText(clientIdx, MSB_HUDReplaceHandle, MSB_HUDReplacementFormat, FF2_GetBossCharge(bossIdx, 0), FF2_GetBossMaxHealth(bossIdx), FF2_GetBossMaxHealth(bossIdx));
	}
}

public Rage_MultiSpellBase(clientIdx)
{
	if (MSB_ActivationKey[clientIdx] == 0)
	{
		MSB_ActivatedByMedic[clientIdx] = true;
		MSB_RageSpent[clientIdx] = true; // signal rage refund next frame
	}
}

/**
 * Spell Line Explosion
 */
public SLE_Invoke(clientIdx)
{
	// create the projectile
	new projectile = Spells_CreateRocket(clientIdx, SLE_ProjectileSpeed[clientIdx], 0xffffff, false);
	GetClientEyeAngles(clientIdx, SLE_Angles[clientIdx]);
	if (!IsValidEntity(projectile))
	{
		PrintCenterText(clientIdx, "Couldn't make spell projectile. Notify an admin!");
		GetClientEyePosition(clientIdx, SLE_LastPos[clientIdx]);
		SLE_TriggerExplosion(clientIdx, GetEngineTime());
		return;
	}
	SLE_ProjectileEntRef[clientIdx] = EntIndexToEntRef(projectile);
	GetEntPropVector(projectile, Prop_Send, "m_vecOrigin", SLE_LastPos[clientIdx]);
	
	ReadAndPlayGlobalSoundWithClientIndex(clientIdx, SLE_STRING, 18);
}

public bool:SLE_CanInvoke(clientIdx)
{
	return SLE_ProjectileEntRef[clientIdx] == INVALID_ENTREF && SLE_NextExplosionAt[clientIdx] == FAR_FUTURE;
}

public SLE_FormatHUDString(String:buffer[], bufferSize, String:format[], Float:rageRequired)
{
	Format(buffer, bufferSize, format, SLE_Name, rageRequired, SLE_Description);
}

public Action:SLE_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsLivingPlayer(victim) && GetClientTeam(victim) == MercTeam)
	{
		if (IsLivingPlayer(attacker) && GetClientTeam(attacker) == BossTeam)
		{
			if (SLE_CanUse[attacker] && SLE_ProjectileEntRef[attacker] != INVALID_ENTREF)
			{
				new projectile = EntRefToEntIndex(SLE_ProjectileEntRef[attacker]);
				if (projectile == inflictor)
					return Plugin_Stop; // simply do no damage. doesn't matter if it hits someone.
			}
		}
	}
	return Plugin_Continue;
}

public SLE_GetClearances(Float:pos[3], &Float:toGround, &Float:toCeiling)
{
	static Float:tmpPos[3];
	TR_TraceRayFilter(pos, Float:{90.0, 0.0, 0.0}, MASK_PLAYERSOLID, RayType_Infinite, TraceWallsOnly);
	TR_GetEndPosition(tmpPos);
	toGround = fabs(tmpPos[2] - pos[2]);
	TR_TraceRayFilter(pos, Float:{-90.0, 0.0, 0.0}, MASK_PLAYERSOLID, RayType_Infinite, TraceWallsOnly);
	TR_GetEndPosition(tmpPos);
	toCeiling = fabs(tmpPos[2] - pos[2]);
}

public bool:SLE_TestLineOfSight(Float:srcPos[3], Float:dstPos[3])
{
	static Float:tmpPos[3];
	TR_TraceRayFilter(srcPos, dstPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceWallsOnly);
	TR_GetEndPosition(tmpPos);
	return dstPos[0] == tmpPos[0] && dstPos[1] == tmpPos[1] && dstPos[2] == tmpPos[2];
}

public SLE_AdjustLinePosition(clientIdx, Float:pos[3])
{
	new Float:toGround;
	new Float:toCeiling;
	static Float:testPos[3];
	SLE_GetClearances(pos, toGround, toCeiling);
	new Float:offset = SLE_ContinuationType[clientIdx] == SLE_TYPE_GROUND ? toGround : toCeiling;
	if (offset < 200.0)
	{
		new Float:difference = SLE_MaxZOffset[clientIdx] - offset;
		testPos[0] = pos[0];
		testPos[1] = pos[1];
		testPos[2] = pos[2] + (SLE_ContinuationType[clientIdx] == SLE_TYPE_GROUND ? difference : (-difference));
		if (SLE_TestLineOfSight(pos, testPos))
			pos[2] = testPos[2];
	}
}

public SLE_TriggerExplosion(clientIdx, Float:curTime)
{
	SLE_NextExplosionAt[clientIdx] = curTime;
	SLE_ExplosionsLeft[clientIdx] = SLE_MaxExplosions[clientIdx] - 1;
	new Float:toGround;
	new Float:toCeiling;
	SLE_GetClearances(SLE_LastPos[clientIdx], toGround, toCeiling);
	if (toGround <= 20.0)
		SLE_ContinuationType[clientIdx] = SLE_TYPE_GROUND;
	else if (toCeiling <= 20.0)
		SLE_ContinuationType[clientIdx] = SLE_TYPE_CEILING;
	else
		SLE_ContinuationType[clientIdx] = SLE_TYPE_MIDAIR;
		
	if (SLE_ContinuationType[clientIdx] != SLE_TYPE_MIDAIR)
	{
		SLE_Angles[clientIdx][0] = 0.0; // throw out pitch if we're following the ground or ceiling
		SLE_AdjustLinePosition(clientIdx, SLE_LastPos[clientIdx]);
	}
}

public SLE_Tick(clientIdx, Float:curTime)
{
	if (SLE_ProjectileEntRef[clientIdx] != INVALID_ENTREF)
	{
		new projectile = EntRefToEntIndex(SLE_ProjectileEntRef[clientIdx]);
		if (IsValidEntity(projectile))
		{
			GetEntPropVector(projectile, Prop_Send, "m_vecOrigin", SLE_LastPos[clientIdx]);
			if (GetEntProp(projectile, Prop_Send, "m_iDeflected") != 0)
			{
				// unlike others, the angle of rotation also must be updated
				SetEntProp(projectile, Prop_Send, "m_iDeflected", 0);
				SetEntPropEnt(projectile, Prop_Send, "m_hOwnerEntity", clientIdx);
				SetEntPropEnt(projectile, Prop_Send, "m_hLauncher", GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Melee));
				GetEntPropVector(projectile, Prop_Send, "m_angRotation", SLE_Angles[clientIdx]);
				Spells_SetEnergyBallColor(projectile, 0xffffff);
			}
		}
		else
		{
			SLE_ProjectileEntRef[clientIdx] = INVALID_ENTREF;
			SLE_TriggerExplosion(clientIdx, curTime);
		}
	}
	
	if (curTime >= SLE_NextExplosionAt[clientIdx])
	{
		// trigger the explosion now
		new explosion = CreateEntityByName("env_explosion");
		if (!IsValidEntity(explosion))
		{
			SLE_NextExplosionAt[clientIdx] = FAR_FUTURE;
			return;
		}
		new String:intAsString[12];
		Format(intAsString, 12, "%d", RoundFloat(fixDamageForFF2(SLE_Damage[clientIdx])));
		DispatchKeyValue(explosion, "iMagnitude", intAsString);
		DispatchKeyValueFloat(explosion, "DamageForce", 1.0);
		DispatchKeyValue(explosion, "spawnflags", "0");
		Format(intAsString, 12, "%d", RoundFloat(SLE_Radius[clientIdx]));
		DispatchKeyValue(explosion, "iRadiusOverride", intAsString);

		// set data pertinent to the user
		SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", clientIdx);

		// spawn
		TeleportEntity(explosion, SLE_LastPos[clientIdx], NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(explosion);

		// explode!
		AcceptEntityInput(explosion, "Explode");
		AcceptEntityInput(explosion, "kill");
		if (PRINT_DEBUG_SPAM)
			PrintToServer("[sarysamods9] Explosion at %f,%f,%f", SLE_LastPos[clientIdx][0], SLE_LastPos[clientIdx][1], SLE_LastPos[clientIdx][2]);
			
		// enough of the explosion. lets continue the line or end the rage.
		if (SLE_ExplosionsLeft[clientIdx] > 0)
		{
			SLE_ExplosionsLeft[clientIdx]--;
			SLE_NextExplosionAt[clientIdx] += SLE_TimeInterval[clientIdx];
			static Float:nextPos[3];
			new bool:fail = false;

			// get our line. angles has been adjusted for ground or ceiling to not use pitch.
			TR_TraceRayFilter(SLE_LastPos[clientIdx], SLE_Angles[clientIdx], MASK_PLAYERSOLID, RayType_Infinite, TraceWallsOnly);
			TR_GetEndPosition(nextPos);
			fail = !ConformLineDistance(nextPos, SLE_LastPos[clientIdx], nextPos, SLE_Spacing[clientIdx], true);
			
			// if the old pos can't reach the new pos, we've failed for midair
			if (!fail && !SLE_TestLineOfSight(SLE_LastPos[clientIdx], nextPos))
			{
				if (SLE_ContinuationType[clientIdx] == SLE_TYPE_MIDAIR)
					fail = true;
				else
				{
					// two chances to fix this.
					new Float:offset = SLE_Spacing[clientIdx] * 0.6; // assume the hill can't be TOO steep
					nextPos[2] += offset;
					if (!SLE_TestLineOfSight(SLE_LastPos[clientIdx], nextPos))
					{
						nextPos[2] -= (offset + offset);
						if (!SLE_TestLineOfSight(SLE_LastPos[clientIdx], nextPos))
						{
							nextPos[2] += offset; // for debug print accuracy
							fail = true; // just could not find a way past the obstacle. must've hit a wall
						}
					}
				}
			}
			
			// well if we haven't failed, lets do this
			if (!fail)
			{
				// try to get an optimal distance from our surface first
				SLE_AdjustLinePosition(clientIdx, nextPos);
				
				// now that we know where we truly want the explosion to go, store it
				SLE_LastPos[clientIdx][0] = nextPos[0];
				SLE_LastPos[clientIdx][1] = nextPos[1];
				SLE_LastPos[clientIdx][2] = nextPos[2];
			}
			else
			{
				// rage ended early
				if (PRINT_DEBUG_SPAM)
					PrintToServer("[sarysamods9] Line explosion ended early. Guess we hit a wall. %f,%f,%f --> %f,%f,%f",
							SLE_LastPos[clientIdx][0], SLE_LastPos[clientIdx][1], SLE_LastPos[clientIdx][2], 
							nextPos[0], nextPos[1], nextPos[2]);
							
				SLE_NextExplosionAt[clientIdx] = FAR_FUTURE;
			}
		}
		else
			SLE_NextExplosionAt[clientIdx] = FAR_FUTURE;
	}
}

/**
 * Spell Repel Shield
 */
public SRS_Invoke(clientIdx)
{
	if (SRS_ActiveUntil[clientIdx] == FAR_FUTURE) // only initialize if not already active
	{
		if (SRS_Flags[clientIdx] & SRS_FLAG_UBER)
			TF2_AddCondition(clientIdx, TFCond_Ubercharged, -1.0);
		if (SRS_Flags[clientIdx] & SRS_FLAG_INVINCIBILITY)
			SetEntProp(clientIdx, Prop_Data, "m_takedamage", 0);
		if (SRS_Flags[clientIdx] & SRS_FLAG_MEGAHEAL)
			TF2_AddCondition(clientIdx, TFCond_MegaHeal, -1.0);
		SRS_NextTickAt[clientIdx] = GetEngineTime();
	}
	
	// set or extend
	SRS_ActiveUntil[clientIdx] = GetEngineTime() + SRS_Duration[clientIdx];
	
	ReadAndPlayGlobalSoundWithClientIndex(clientIdx, SRS_STRING, 18);
}

public bool:SRS_CanInvoke(clientIdx)
{
	return true;
}

public SRS_FormatHUDString(String:buffer[], bufferSize, String:format[], Float:rageRequired)
{
	Format(buffer, bufferSize, format, SRS_Name, rageRequired, SRS_Description);
}

public SRS_Tick(clientIdx, Float:curTime)
{
	if (SRS_ActiveUntil[clientIdx] == FAR_FUTURE)
		return;
		
	if (curTime >= SRS_ActiveUntil[clientIdx])
	{
		if (SRS_Flags[clientIdx] & SRS_FLAG_UBER)
			TF2_RemoveCondition(clientIdx, TFCond_Ubercharged);
		if (SRS_Flags[clientIdx] & SRS_FLAG_INVINCIBILITY)
			SetEntProp(clientIdx, Prop_Data, "m_takedamage", 2);
		if (SRS_Flags[clientIdx] & SRS_FLAG_MEGAHEAL)
			TF2_RemoveCondition(clientIdx, TFCond_MegaHeal);
		SRS_ActiveUntil[clientIdx] = FAR_FUTURE;
	}
	else if (curTime >= SRS_NextTickAt[clientIdx])
	{
		SRS_NextTickAt[clientIdx] = curTime + SRS_TICK_INTERVAL;
	
		// knockback and damage
		new Float:kbRadiusSquared = SRS_RepelRadius[clientIdx] * SRS_RepelRadius[clientIdx];
		new Float:dmgRadiusSquared = SRS_DamageRadius[clientIdx] * SRS_DamageRadius[clientIdx];
		static Float:bossPos[3];
		GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", bossPos);
		bossPos[2] += 41.5; // offset it
		for (new victim = 1; victim < MAX_PLAYERS; victim++)
		{
			if (!IsLivingPlayer(victim) || GetClientTeam(victim) == BossTeam)
				continue;
				
			static Float:victimPos[3];
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
			victimPos[2] += 41.5; // offset this too
			new Float:distanceSquared = GetVectorDistance(bossPos, victimPos, true);
			if (distanceSquared <= kbRadiusSquared)
			{
				// neither distance based nor additive knockback
				static Float:angles[3];
				GetVectorAnglesTwoPoints(bossPos, victimPos, angles);
				static Float:velocity[3];
				GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(velocity, SRS_RepelIntensity[clientIdx]);
				if (GetEntityFlags(victim) & FL_ONGROUND)
					velocity[2] = fmax(velocity[2], 285.0);
				TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, velocity);
			}
			
			if (distanceSquared <= dmgRadiusSquared)
			{
				// not distance based damage
				QuietDamage(victim, clientIdx, clientIdx, SRS_DamagePerTick[clientIdx], DMG_GENERIC, -1);
			}
		}
	}
}

/**
 * Spell Freeze Escape
 */
public SFE_Invoke(clientIdx)
{
	// create the projectile
	new projectile = Spells_CreateRocket(clientIdx, SFE_ProjectileSpeed[clientIdx], 0xffffff, false);
	if (!IsValidEntity(projectile))
	{
		PrintCenterText(clientIdx, "Couldn't make spell projectile. Notify an admin!");
		return;
	}
	SFE_ProjectileEntRef[clientIdx] = EntIndexToEntRef(projectile);
	
	ReadAndPlayGlobalSoundWithClientIndex(clientIdx, SFE_STRING, 18);
}

public bool:SFE_CanInvoke(clientIdx)
{
	return SFE_ProjectileEntRef[clientIdx] == INVALID_ENTREF;
}

public SFE_FormatHUDString(String:buffer[], bufferSize, String:format[], Float:rageRequired)
{
	Format(buffer, bufferSize, format, SFE_Name, rageRequired, SFE_Description);
}

public Action:SFE_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsLivingPlayer(victim) && GetClientTeam(victim) == MercTeam)
	{
		if (IsLivingPlayer(attacker) && GetClientTeam(attacker) == BossTeam)
		{
			if (SFE_CanUse[attacker] && SFE_ProjectileEntRef[attacker] != INVALID_ENTREF)
			{
				new projectile = EntRefToEntIndex(SFE_ProjectileEntRef[attacker]);
				if (projectile == inflictor)
				{
					if (IsInRange(projectile, victim, SFE_RadiusConstraint[attacker]))
						SFE_FreezePlayer(victim, attacker);
					return Plugin_Stop;
				}
			}
		}
	}
	return Plugin_Continue;
}

public SFE_FreezePlayer(victim, clientIdx)
{
	SetEntityRenderMode(victim, RENDER_TRANSCOLOR);
	SetEntityRenderColor(victim, 255, 255, 255, 0);
	CreateRagdoll(victim, SFE_FreezeDuration[clientIdx]);
	SFE_FreezeEndsAt[victim] = GetEngineTime() + SFE_FreezeDuration[clientIdx];
	if (SFE_Flags[clientIdx] & SFE_FLAG_INVINCIBLE)
	{
		SetEntProp(victim, Prop_Data, "m_takedamage", 0);
		SFE_ImmunityEndsAt[victim] = SFE_FreezeEndsAt[victim] + SFE_ImmunityExtension[clientIdx];
	}
}

public SFE_Tick(Float:curTime)
{
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx))
			continue;
	
		if (SFE_CanUse[clientIdx] && SFE_ProjectileEntRef[clientIdx] != INVALID_ENTREF)
		{
			new projectile = EntRefToEntIndex(SFE_ProjectileEntRef[clientIdx]);
			if (!IsValidEntity(projectile))
				SFE_ProjectileEntRef[clientIdx] = INVALID_ENTREF;
			else if (GetEntProp(projectile, Prop_Send, "m_iDeflected") != 0)
			{
				//PrintToServer("deflected=%d    owner=%d    launcher=%d vs. %d",
				//		GetEntProp(projectile, Prop_Send, "m_iDeflected"),
				//		GetEntPropEnt(projectile, Prop_Send, "m_hOwnerEntity"),
				//		GetEntPropEnt(projectile, Prop_Send, "m_hLauncher"),
				//		GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Melee));
				SetEntProp(projectile, Prop_Send, "m_iDeflected", 0);
				SetEntPropEnt(projectile, Prop_Send, "m_hOwnerEntity", clientIdx);
				SetEntPropEnt(projectile, Prop_Send, "m_hLauncher", GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Melee));
				Spells_SetEnergyBallColor(projectile, 0xffffff);
			}
		}
		else if (GetClientTeam(clientIdx) == MercTeam)
		{
			if (curTime >= SFE_FreezeEndsAt[clientIdx])
			{
				SFE_FreezeEndsAt[clientIdx] = FAR_FUTURE;
				if (TF2_IsPlayerInCondition(clientIdx, TFCond_Dazed))
					TF2_RemoveCondition(clientIdx, TFCond_Dazed);
				SetEntityRenderMode(clientIdx, RENDER_TRANSCOLOR);
				SetEntityRenderColor(clientIdx, 255, 255, 255, 255);
			}
			else if (SFE_FreezeEndsAt[clientIdx] != FAR_FUTURE)
			{
				if (!TF2_IsPlayerInCondition(clientIdx, TFCond_Dazed))
					TF2_StunPlayer(clientIdx, 999.0, 0.0, TF_STUNFLAG_BONKSTUCK | TF_STUNFLAG_NOSOUNDOREFFECT);
				if (TF2_IsPlayerInCondition(clientIdx, TFCond_Taunting))
					TF2_RemoveCondition(clientIdx, TFCond_Taunting);
			}
			
			if (curTime >= SFE_ImmunityEndsAt[clientIdx])
			{
				SFE_ImmunityEndsAt[clientIdx] = FAR_FUTURE;
				SetEntProp(clientIdx, Prop_Data, "m_takedamage", 2);
			}
		}
	}
}

/**
 * Medigun: Fake Vaccinator
 */
public OnClientDisconnect(clientIdx)
{
	if (MFV_ActiveThisRound && MFV_CanUse[clientIdx])
		MFV_OnDeathOrDisconnect(clientIdx);
}

public Action:MFV_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// exclude dead ringer death
	if ((GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) != 0)
		return Plugin_Continue;
	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (MFV_CanUse[victim])
		MFV_OnDeathOrDisconnect(victim);
	return Plugin_Continue;
}
 
public MFV_OnDeathOrDisconnect(clientIdx)
{
	if (!MFV_MedicDeathHandled[clientIdx])
	{
		MFV_MedicDeathHandled[clientIdx] = true;
		if (IsLivingPlayer(MFV_LastHealingTarget[clientIdx]))
		{
			new TFCond:oldCond = MFV_LastUberchargeState[clientIdx] ? MFV_ModeUberCondition[clientIdx][MFV_BuffIdx[clientIdx]] : MFV_ModeNormalCondition[clientIdx][MFV_BuffIdx[clientIdx]];
			if (oldCond > TFCond:0 && TF2_IsPlayerInCondition(MFV_LastHealingTarget[clientIdx], oldCond))
				TF2_RemoveCondition(MFV_LastHealingTarget[clientIdx], oldCond);
		}
	}
}
 
public MFV_Tick(clientIdx, buttons, Float:curTime)
{
	// is this medic ubercharged, and who's their partner? important stuff before we continue
	new medigun = GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Secondary);
	if (!IsValidEntity(medigun))
		return; // fail quietly, in case it's meant for them to temporarily lose their medigun
	new bool:medigunOut = GetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon") == medigun;
	new bool:isUber = GetEntProp(medigun, Prop_Send, "m_bChargeRelease") != 0;
	new healingTarget = (GetEntProp(medigun, Prop_Send, "m_bHealing") != 0) ? GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget") : -1;
	new lastBuffIdx = MFV_BuffIdx[clientIdx];
	new TFCond:oldCond = MFV_LastUberchargeState[clientIdx] ? MFV_ModeUberCondition[clientIdx][lastBuffIdx] : MFV_ModeNormalCondition[clientIdx][lastBuffIdx];

	new bool:switchKeyDown = (buttons & MFV_SwitchKey[clientIdx]) != 0;
	new bool:reverseSwitchKeyDown = (buttons & IN_USE) != 0;
	if (switchKeyDown && !MFV_SwitchKeyDown[clientIdx] && medigunOut && !isUber)
	{
		MFV_BuffIdx[clientIdx]++;
		MFV_BuffIdx[clientIdx] %= MFV_ModeCount[clientIdx];
	}
	MFV_SwitchKeyDown[clientIdx] = switchKeyDown;

	if (reverseSwitchKeyDown && !MFV_ReverseSwitchKeyDown[clientIdx] && medigunOut && !isUber)
	{
		MFV_BuffIdx[clientIdx]--;
		if (MFV_BuffIdx[clientIdx] < 0)
			MFV_BuffIdx[clientIdx] = MFV_ModeCount[clientIdx] - 1;
	}
	MFV_ReverseSwitchKeyDown[clientIdx] = reverseSwitchKeyDown;

	// get the new condition
	new TFCond:newCond = isUber ? MFV_ModeUberCondition[clientIdx][MFV_BuffIdx[clientIdx]] : MFV_ModeNormalCondition[clientIdx][MFV_BuffIdx[clientIdx]];
	
	// ensure validity of existing buffs
	// first, remove any rogue buffs from the actual medigun
	new TFCond:baseCond = (MFV_BaseMedigunType[clientIdx] == MFV_MEDIGUN_TYPE_UBER) ? TFCond_Ubercharged : ((MFV_BaseMedigunType[clientIdx] == MFV_MEDIGUN_TYPE_KRITZ) ? TFCond_Kritzkrieged : TFCond_MegaHeal);
	if (TF2_IsPlayerInCondition(clientIdx, baseCond) && baseCond != newCond)
		TF2_RemoveCondition(clientIdx, baseCond);
	if (IsLivingPlayer(healingTarget))
		if (TF2_IsPlayerInCondition(healingTarget, baseCond) && baseCond != newCond)
			TF2_RemoveCondition(healingTarget, baseCond);
	
	// next, remove fake buffs from a lost target
	if (IsLivingPlayer(MFV_LastHealingTarget[clientIdx]) && MFV_LastHealingTarget[clientIdx] != healingTarget)
	{
		if (oldCond > TFCond:0 && TF2_IsPlayerInCondition(MFV_LastHealingTarget[clientIdx], oldCond))
			TF2_RemoveCondition(MFV_LastHealingTarget[clientIdx], oldCond);
	}
	
	// if the condition changed, remove the old cond from the user and the target
	if (oldCond != newCond && oldCond > TFCond:0)
	{
		if (TF2_IsPlayerInCondition(clientIdx, oldCond))
			TF2_RemoveCondition(clientIdx, oldCond);
		if (IsLivingPlayer(healingTarget))
			if (TF2_IsPlayerInCondition(healingTarget, oldCond))
				TF2_RemoveCondition(healingTarget, oldCond);
	}
	
	if (newCond > TFCond:0)
	{
		if (!medigunOut)
		{
			// medigun not out? remove condition from both.
			if (TF2_IsPlayerInCondition(clientIdx, newCond))
				TF2_RemoveCondition(clientIdx, newCond);
			if (IsLivingPlayer(healingTarget))
				if (TF2_IsPlayerInCondition(healingTarget, newCond))
					TF2_RemoveCondition(healingTarget, newCond);
		}
		else
		{
			// otherwise, add the new condition to the medic and the target
			if (!TF2_IsPlayerInCondition(clientIdx, newCond))
				TF2_AddCondition(clientIdx, newCond, -1.0);
			if (IsLivingPlayer(healingTarget))
				if (!TF2_IsPlayerInCondition(healingTarget, newCond))
					TF2_AddCondition(healingTarget, newCond, -1.0);
		}
	}
	
	// store stuff for later
	MFV_LastHealingTarget[clientIdx] = healingTarget;
	MFV_LastUberchargeState[clientIdx] = isUber;
	
	// finally, update the HUD
	if (curTime >= MFV_UpdateHUDAt[clientIdx] && (buttons & IN_SCORE) == 0)
	{
		MFV_UpdateHUDAt[clientIdx] = curTime + MFV_HUD_INTERVAL;
		SetHudTextParams(-1.0, MFV_HudY[clientIdx], MFV_HUD_INTERVAL + 0.05, GetR(MFV_HudColor[clientIdx]), GetG(MFV_HudColor[clientIdx]), GetB(MFV_HudColor[clientIdx]), 255);
		ShowSyncHudText(clientIdx, MFV_HUDHandle, MFV_HudFormat, MFV_UberString, MFV_Descriptions[MFV_BuffIdx[clientIdx]]);
	}
}

/**
 * Smart Ally Teleport
 */
public SAT_Tick(clientIdx)
{
	new bluCount = 0;
	for (new player = 1; player < MAX_PLAYERS; player++)
		if (IsLivingPlayer(player) && GetClientTeam(player) == BossTeam)
			bluCount++;
			
	if (bluCount == 1)
	{
		if (SAT_LastMode[clientIdx] != SAT_MODE_ALLIES_DEAD)
		{
			SAT_LastMode[clientIdx] = SAT_MODE_ALLIES_DEAD;
			DT_ChangeFundamentalStats(clientIdx, SAT_TeleportChargeDead[clientIdx], SAT_CooldownDead[clientIdx], SAT_StunDead[clientIdx]);
			DT_SetTargetTeam(clientIdx, false);
			DT_SetAboveSide(clientIdx, SAT_AboveDead[clientIdx], SAT_SideDead[clientIdx]);
		}
	}
	else if (bluCount > 1)
	{
		if (SAT_LastMode[clientIdx] != SAT_MODE_ALLIES_ALIVE)
		{
			SAT_LastMode[clientIdx] = SAT_MODE_ALLIES_ALIVE;
			DT_ChangeFundamentalStats(clientIdx, SAT_TeleportChargeAlive[clientIdx], SAT_CooldownAlive[clientIdx], SAT_StunAlive[clientIdx]);
			DT_SetTargetTeam(clientIdx, true);
			DT_SetAboveSide(clientIdx, SAT_AboveAlive[clientIdx], SAT_SideAlive[clientIdx]);
		}
	}
}

/**
 * Weapon Selector
 */
WS_GetActionKey(bossIdx, argIdx)
{
	new keyIdx = FF2_GetAbilityArgument(bossIdx, this_plugin_name, WS_STRING, argIdx);
	if (keyIdx == 0)
		return IN_RELOAD;
	else if (keyIdx == 1)
		return IN_ATTACK3;
	else if (keyIdx == 2)
		return IN_USE;
		
	// invalid key specified.
	PrintToServer("[sarysamods9] WARNING: Invalid key specified for iterating weapons for %s, arg %d. User won't be able to iterate through weapons.", WS_STRING, argIdx);
	return 0;
}

WS_SpawnWeapon(clientIdx, weaponIdx)
{
	new weapon = SpawnWeapon(clientIdx, WSS_WeaponName[weaponIdx], WSS_WeaponIdx[weaponIdx], 101, 5, WSS_WeaponArgs[weaponIdx], WSS_VisibilityType[weaponIdx] == WSS_VIS_TYPE_VISIBLE ? 1 : 0);
	if (IsValidEntity(weapon))
	{
		SetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon", weapon);
		new offset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1);
		if (offset >= 0)
		{
			SetEntProp(clientIdx, Prop_Send, "m_iAmmo", WSS_DefaultAmmo[weaponIdx], 4, offset);
			if (GetEntProp(weapon, Prop_Send, "m_iClip1") < 128)
				SetEntProp(weapon, Prop_Send, "m_iClip1", WSS_DefaultClip[weaponIdx]);
			WSS_LastClipValue[weaponIdx] = WSS_DefaultClip[weaponIdx];
			WSS_LastClipValueTime[weaponIdx] = GetEngineTime();
		}
		
		// invisible is necessary if the view model is awful
		if (WSS_VisibilityType[weaponIdx] == WSS_VIS_TYPE_INVISIBLE)
		{
			SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(weapon, 255, 255, 255, 0);
		}
	}
}

WS_SpawnSecondary(clientIdx)
{
	WS_SecondaryRemoveAt = FAR_FUTURE;
	TF2_RemoveWeaponSlot(clientIdx, TFWeaponSlot_Secondary);
	WS_SpawnWeapon(clientIdx, WS_SecondarySelected + WSS_SECONDARY_START);
	WS_EquippedSecondary = WS_SecondarySelected;
}

WS_SpawnPrimary(clientIdx)
{
	WS_PrimaryRemoveAt = FAR_FUTURE;
	TF2_RemoveWeaponSlot(clientIdx, TFWeaponSlot_Primary);
	WS_SpawnWeapon(clientIdx, WS_PrimarySelected + WSS_PRIMARY_START);
	WS_EquippedPrimary = WS_PrimarySelected;
}

// By Mecha the Slag, lifted from 1st set abilities and tweaked
WS_UpdateClientCheatValue(valueInt)
{
	if (cvarCheats == INVALID_HANDLE)
		return;

	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (IsClientInGame(clientIdx) && !IsFakeClient(clientIdx))
		{
			static String:valueS[2];
			IntToString(valueInt, valueS, sizeof(valueS));
			SendConVarValue(clientIdx, cvarCheats, valueS);
		}
	}
}

WS_RemoveTimeDilation()
{
	if (WS_TimeDilation != 1.0 && cvarTimeScale != INVALID_HANDLE)
	{
		SetConVarFloat(cvarTimeScale, 1.0);
		WS_UpdateClientCheatValue(0);

		if (WS_Flags & WS_FLAG_REPLAY_SOUND_END)
		{
			EmitSoundToAll(WS_REPLAY_END_SOUND);
			EmitSoundToAll(WS_REPLAY_END_SOUND);
		}
	}
}

public WS_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientIdx = GetClientOfUserId(GetEventInt(event, "userid"));
	if (WS_CanUse[clientIdx])
	{
		WS_RemoveTimeDilation();
	}
}

new bool:WS_WasBleeding = false;
new bool:WS_WasOnFire = false;
new WS_BleedFireWeapon = -1;
new WS_CheckBleedFireOn = -1;
public Action:WS_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsLivingPlayer(victim) && GetClientTeam(victim) == MercTeam)
	{
		if (IsLivingPlayer(attacker) && GetClientTeam(attacker) == BossTeam)
		{
			if (WS_CanUse[attacker])
			{
				WS_CheckBleedFireOn = victim;
				WS_BleedFireWeapon = weapon;
				WS_WasBleeding = TF2_IsPlayerInCondition(victim, TFCond_Bleeding);
				WS_WasOnFire = TF2_IsPlayerInCondition(victim, TFCond_OnFire);
			}
		}
	}
	
	return Plugin_Continue;
}

public WS_GetEquippedWeaponIdx(clientIdx, weapon)
{
	if (weapon == GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Secondary) && WS_EquippedSecondary != -1)
		return WS_EquippedSecondary + WSS_SECONDARY_START;
	else if (weapon == GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Primary) && WS_EquippedPrimary != -1)
		return WS_EquippedPrimary + WSS_PRIMARY_START;
		
	return -1;
}

public WS_OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	if (WS_CheckBleedFireOn != victim || !IsValidEntity(WS_BleedFireWeapon))
		return;
		
	if (IsLivingPlayer(victim))
	{
		new weaponIdx = WS_GetEquippedWeaponIdx(attacker, WS_BleedFireWeapon);
		if (weaponIdx != -1 && WSS_DOTDuration[weaponIdx] <= 0.0)
		{
			if (!WS_WasBleeding && TF2_IsPlayerInCondition(victim, TFCond_Bleeding))
			{
				if (WS_EndBleedAt[victim] == FAR_FUTURE)
					WS_EndBleedAt[victim] = GetEngineTime() + WSS_DOTDuration[weaponIdx];
				else
					WS_EndBleedAt[victim] = fmax(GetEngineTime() + WSS_DOTDuration[weaponIdx], WS_EndBleedAt[victim]);
			}
			if (!WS_WasOnFire && TF2_IsPlayerInCondition(victim, TFCond_OnFire))
			{
				if (WS_EndFireAt[victim] == FAR_FUTURE)
					WS_EndFireAt[victim] = GetEngineTime() + WSS_DOTDuration[weaponIdx];
				else
					WS_EndFireAt[victim] = fmax(GetEngineTime() + WSS_DOTDuration[weaponIdx], WS_EndFireAt[victim]);
			}
		}
	}
	WS_CheckBleedFireOn = -1;
}

public WS_TickVictims(victim, Float:curTime)
{
	if (GetClientTeam(victim) == BossTeam)
		return;
		
	if (curTime >= WS_EndBleedAt[victim])
	{
		WS_EndBleedAt[victim] = FAR_FUTURE;
		if (TF2_IsPlayerInCondition(victim, TFCond_Bleeding))
			TF2_RemoveCondition(victim, TFCond_Bleeding);
	}

	if (curTime >= WS_EndFireAt[victim])
	{
		WS_EndFireAt[victim] = FAR_FUTURE;
		if (TF2_IsPlayerInCondition(victim, TFCond_OnFire))
			TF2_RemoveCondition(victim, TFCond_OnFire);
	}
}

public WS_SetLastClipValues(clientIdx)
{
	for (new slot = 0; slot <= 1; slot++)
	{
		// get weapon index for that slot
		new weapon = GetPlayerWeaponSlot(clientIdx, slot);
		if (!IsValidEntity(weapon))
			continue;
			
		new weaponIdx = (slot == 0) ? WS_EquippedPrimary : WS_EquippedSecondary;
		if (weaponIdx < 0)
			continue;
		new clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
			
		// also need to ensure the time is updated every frame if weapon is inactive, so we don't reload immediately upon switch
		if (clip < 128 && (clip != WSS_LastClipValue[weaponIdx] || weapon != GetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon")))
		{
			WSS_LastClipValue[weaponIdx] = clip;
			WSS_LastClipValueTime[weaponIdx] = GetEngineTime();
		}
	}
}

public WS_Tick(clientIdx, buttons, Float:curTime)
{
	new bool:ssKeyDown = (buttons & WS_SecondarySelectionKey) != 0;
	if (ssKeyDown && !WS_SSKeyDown && WS_RageEndsAt == FAR_FUTURE && WS_SecondaryCount > 0)
	{
		WS_SecondarySelected++;
		WS_SecondarySelected %= WS_SecondaryCount;
		WS_UpdateHUDAt = curTime;
	}
	WS_SSKeyDown = ssKeyDown;

	new bool:psKeyDown = (buttons & WS_PrimarySelectionKey) != 0;
	if (psKeyDown && !WS_PSKeyDown && WS_RageEndsAt == FAR_FUTURE && WS_PrimaryCount > 0)
	{
		WS_PrimarySelected++;
		WS_PrimarySelected %= WS_PrimaryCount;
		WS_UpdateHUDAt = curTime;
	}
	WS_PSKeyDown = psKeyDown;
	
	// is it time to end the rage?
	PrintCenterText(clientIdx, "%f >= %f ?", curTime, WS_RageEndsAt);
	if (curTime >= WS_RageEndsAt)
	{
		WS_RageEndsAt = FAR_FUTURE;
		WS_RemoveTimeDilation();
		
		// any weapons to add?
		if (WS_SecondarySpawnMode == WS_SPAWN_MODE_AFTER)
			WS_SpawnSecondary(clientIdx);
		if (WS_PrimarySpawnMode == WS_SPAWN_MODE_AFTER)
			WS_SpawnPrimary(clientIdx);
			
		// trigger weapon removal if applicable (must be done after spawns above, which reset removal times)
		if (WS_SecondaryTTL > 0.0)
			WS_SecondaryRemoveAt = curTime + WS_SecondaryTTL;
		if (WS_PrimaryTTL > 0.0)
			WS_PrimaryRemoveAt = curTime + WS_PrimaryTTL;
	}
	
	// is it time to remove their secondary?
	if (curTime >= WS_SecondaryRemoveAt)
	{
		WS_SecondaryRemoveAt = FAR_FUTURE;
		TF2_RemoveWeaponSlot(clientIdx, TFWeaponSlot_Secondary);
		WS_EquippedSecondary = -1;
	}
	
	// is it time to remove their primary?
	if (curTime >= WS_PrimaryRemoveAt)
	{
		WS_PrimaryRemoveAt = FAR_FUTURE;
		TF2_RemoveWeaponSlot(clientIdx, TFWeaponSlot_Primary);
		WS_EquippedPrimary = -1;
	}
	
	// do we need to change the player's class?
	if (WS_ActualClass > TFClass_Unknown)
	{
		// get the current weapon's index
		new weaponIdx = WS_GetEquippedWeaponIdx(clientIdx, WS_BleedFireWeapon);
		if (weaponIdx >= 0 && WSS_ClassChange[weaponIdx] > TFClass_Unknown)
		{
			if (TF2_GetPlayerClass(clientIdx) != WSS_ClassChange[weaponIdx])
				TF2_SetPlayerClass(clientIdx, WSS_ClassChange[weaponIdx]);
		}
		else if (weaponIdx < 0 && TF2_GetPlayerClass(clientIdx) != WS_ActualClass)
			TF2_SetPlayerClass(clientIdx, WS_ActualClass);
			
		// tinker with reloading
		if (weaponIdx >= 0 && WS_RageEndsAt != FAR_FUTURE)
		{
			new weapon = GetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon");
			if (IsValidEntity(weapon) && weapon != GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Melee))
			{
				new clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
				new offset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1);
				if (offset >= 0 && clip < 128)
				{
					new ammo = GetEntProp(clientIdx, Prop_Send, "m_iAmmo", 4, offset);
					if (ammo > 0 && clip != WSS_DefaultClip[weaponIdx] && curTime >= WSS_LastClipValueTime[weaponIdx] + WS_ReloadTime)
					{
						// time to fake reload
						new reloadAmount = 1;
						if (!WSS_IsSingleReload[clientIdx])
							reloadAmount = min(ammo, WSS_DefaultClip[weaponIdx] - clip);
						SetEntProp(clientIdx, Prop_Send, "m_iAmmo", ammo - reloadAmount);
						SetEntProp(weapon, Prop_Send, "m_iClip1", clip + reloadAmount);
						EmitSoundToClient(clientIdx, WS_RELOAD_SOUND);
					}
				}
			}
		}

		// regardless of whether or not we've affected the currently equipped weapon, 
		// set the last clip values for all weapons if the rage is active
		if (WS_RageEndsAt != FAR_FUTURE)
			WS_SetLastClipValues(clientIdx);
	}
	
	// update HUD last
	if (curTime >= WS_UpdateHUDAt && (buttons & IN_SCORE) == 0)
	{
		WS_UpdateHUDAt = curTime + WS_HUD_INTERVAL;
		
		// get our HUD contents
		static String:secondaryHUD[MAX_CENTER_TEXT_LENGTH];
		static String:primaryHUD[MAX_CENTER_TEXT_LENGTH];
		if (WS_SecondarySpawnMode == WS_SPAWN_MODE_NEVER)
			secondaryHUD[0] = 0;
		else
			Format(secondaryHUD, MAX_CENTER_TEXT_LENGTH, WS_SecondaryHUD, WSS_AestheticName[WS_SecondarySelected + WSS_SECONDARY_START]);
		if (WS_PrimarySpawnMode == WS_SPAWN_MODE_NEVER)
			primaryHUD[0] = 0;
		else
			Format(primaryHUD, MAX_CENTER_TEXT_LENGTH, WS_PrimaryHUD, WSS_AestheticName[WS_PrimarySelected + WSS_PRIMARY_START]);
		
		// current equipped is particularly involved
		static String:equippedHUD[MAX_CENTER_TEXT_LENGTH];
		if (WS_EquippedPrimary != -1 && GetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Primary))
			Format(equippedHUD, MAX_CENTER_TEXT_LENGTH, WS_EquippedHUD, WSS_AestheticName[WS_EquippedPrimary + WSS_PRIMARY_START]);
		else if (WS_EquippedSecondary != -1 && GetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Secondary))
			Format(equippedHUD, MAX_CENTER_TEXT_LENGTH, WS_EquippedHUD, WSS_AestheticName[WS_EquippedSecondary + WSS_SECONDARY_START]);
		else if (GetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Melee))
			Format(equippedHUD, MAX_CENTER_TEXT_LENGTH, WS_EquippedHUD, WS_MeleeName);
		else
			Format(equippedHUD, MAX_CENTER_TEXT_LENGTH, WS_EquippedHUD, "Other");

		// actual HUD printout
		SetHudTextParams(-1.0, WS_HudY, WS_HUD_INTERVAL + 0.05, GetR(WS_HudColor), GetG(WS_HudColor), GetB(WS_HudColor), 255);
		ShowSyncHudText(clientIdx, WS_HUDHandle, "%s\n%s\n%s", secondaryHUD, primaryHUD, equippedHUD);
	}
}

public Rage_WeaponSelector(clientIdx)
{
	// just start the matrix effect and spawn weapons
	WS_RageEndsAt = GetEngineTime() + WS_Duration;
	if (WS_TimeDilation != 1.0 && cvarTimeScale != INVALID_HANDLE)
	{
		WS_UpdateClientCheatValue(1);
		SetConVarFloat(cvarTimeScale, WS_TimeDilation);
			
		if (WS_Flags & WS_FLAG_REPLAY_SOUND_START)
		{
			EmitSoundToAll(WS_REPLAY_START_SOUND);
			EmitSoundToAll(WS_REPLAY_START_SOUND);
		}
	}

	if (WS_SecondarySpawnMode == WS_SPAWN_MODE_BEFORE)
		WS_SpawnSecondary(clientIdx);
	if (WS_PrimarySpawnMode == WS_SPAWN_MODE_BEFORE)
		WS_SpawnPrimary(clientIdx);
		
	// ensure both weapons' reload variables are updated
	WS_SetLastClipValues(clientIdx);
}

/*
new Float:WS_ReloadTime; // arg7, has to be altered with time dilation
new WSS_LastClipValue[WSS_MAX_WEAPONS]; // internal
new Float:WSS_LastClipValueTime[WSS_MAX_WEAPONS]; // internal
*/

/**
 * OnPlayerRunCmd/OnGameFrame, with special guest star OnEntityCreated and introducing OnStomp
 */
public OnGameFrame()
{
	if (!RoundInProgress)
		return;
		
	new Float:curTime = GetEngineTime();
	
	if (JP_ActiveThisRound)
		JP_Tick(curTime);
	
	if (LC_ActiveThisRound)
		LC_Tick(curTime);
	
	if (RI_ActiveThisRound)
		RI_Tick(curTime);
	
	if (MF_ActiveThisRound)
		MF_Tick(curTime);
	
	if (DD_ActiveThisRound)
		DD_Tick(curTime);
	
	if (BH_ActiveThisRound)
		BH_Tick(curTime);
	
	if (RE_ActiveThisRound)
		RE_Tick(curTime);
	
	if (SFE_ActiveThisRound)
		SFE_Tick(curTime);
	
	if (SRS_ActiveThisRound || SLE_ActiveThisRound || SAT_ActiveThisRound || WS_ActiveThisRound)
	{
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (!IsLivingPlayer(clientIdx))
				continue;
			
			if (WS_ActiveThisRound)
				WS_TickVictims(clientIdx, curTime);
				
			if (SRS_CanUse[clientIdx])
				SRS_Tick(clientIdx, curTime);
				
			if (SLE_CanUse[clientIdx])
				SLE_Tick(clientIdx, curTime);
				
			if (SAT_CanUse[clientIdx])
				SAT_Tick(clientIdx);
		}
	}
}
 
public Action:OnPlayerRunCmd(clientIdx, &buttons, &impulse, Float:vel[3], Float:unusedangles[3], &weapon)
{
	if (!RoundInProgress)
		return Plugin_Continue;
	else if (!IsLivingPlayer(clientIdx))
		return Plugin_Continue;
		
	if (BH_ActiveThisRound && BH_CanUse[clientIdx])
		BH_OnPlayerRunCmd(clientIdx, buttons);
	
	if (MSB_ActiveThisRound && MSB_CanUse[clientIdx])
		MSB_Tick(clientIdx, buttons, GetEngineTime());
	
	if (MFV_ActiveThisRound && MFV_CanUse[clientIdx])
		MFV_Tick(clientIdx, buttons, GetEngineTime());
	
	if (WS_ActiveThisRound && WS_CanUse[clientIdx])
		WS_Tick(clientIdx, buttons, GetEngineTime());

	return Plugin_Continue;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (JP_ActiveThisRound)
		JP_OnEntityCreated(entity, classname);
}

public Action:OnStomp(attacker, victim, &Float:damageMultiplier, &Float:damageBonus, &Float:JumpPower)
{
	if (DD_ActiveThisRound)
		return DD_OnStomp(attacker, victim, damageMultiplier, damageBonus, JumpPower);
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
	//PrintToServer("[sarysamods9] eye pos=%f,%f,%f     sound=%s", playerPos[0], playerPos[1], playerPos[2], soundPath);
	for (new i = 0; i < stack; i++)
		EmitAmbientSound(soundPath, playerPos, followPlayer ? clientIdx : SOUND_FROM_WORLD);
}

stock ParticleEffectAt(Float:position[3], String:effectName[], Float:duration = 0.1)
{
	if (strlen(effectName) < 3)
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
stock AttachParticleToAttachment(entity, const String:particleType[], const String:attachmentPoint[]) // m_vecAbsOrigin. you're welcome.
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

	if (!IsEmptyString(particleType))
	{
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
	}
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
		PrintToServer("[sarysamods9] Error: Invalid weapon spawned. client=%d name=%s idx=%d attr=%s", client, name, index, attribute);
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

stock FindRandomPlayer(bool:isBossTeam, Float:position[3] = NULL_VECTOR, Float:maxDistance = 0.0, bool:anyTeam = false, bool:deadOnly = false)
{
	return FindRandomPlayerBlacklist(isBossTeam, NULL_BLACKLIST, position, maxDistance, anyTeam, deadOnly);
}

stock FindRandomPlayerBlacklist(bool:isBossTeam, const bool:blacklist[MAX_PLAYERS_ARRAY], Float:position[3] = NULL_VECTOR, Float:maxDistance = 0.0, bool:anyTeam = false, bool:deadOnly = false)
{
	new player = -1;

	// first, get a player count for the team we care about
	new playerCount = 0;
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!deadOnly && !IsLivingPlayer(clientIdx))
			continue;
		else if (deadOnly)
		{
			if (!IsClientInGame(clientIdx) || IsLivingPlayer(clientIdx))
				continue;
		}
			
		if (!deadOnly && maxDistance > 0.0 && !IsPlayerInRange(clientIdx, position, maxDistance))
			continue;
			
		if (blacklist[clientIdx])
			continue;

		// fixed to not grab people in spectator, since we can now include the dead
		new bool:valid = anyTeam && (GetClientTeam(clientIdx) == BossTeam || GetClientTeam(clientIdx) == MercTeam);
		if (!valid)
			valid = (isBossTeam && GetClientTeam(clientIdx) == BossTeam) || (!isBossTeam && GetClientTeam(clientIdx) == MercTeam);
			
		if (valid)
			playerCount++;
	}

	// ensure there's at least one living valid player
	if (playerCount <= 0)
		return -1;

	// now randomly choose our victim
	new rand = GetRandomInt(0, playerCount - 1);
	playerCount = 0;
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!deadOnly && !IsLivingPlayer(clientIdx))
			continue;
		else if (deadOnly)
		{
			if (!IsClientInGame(clientIdx) || IsLivingPlayer(clientIdx))
				continue;
		}
			
		if (!deadOnly && maxDistance > 0.0 && !IsPlayerInRange(clientIdx, position, maxDistance))
			continue;

		if (blacklist[clientIdx])
			continue;

		// fixed to not grab people in spectator, since we can now include the dead
		new bool:valid = anyTeam && (GetClientTeam(clientIdx) == BossTeam || GetClientTeam(clientIdx) == MercTeam);
		if (!valid)
			valid = (isBossTeam && GetClientTeam(clientIdx) == BossTeam) || (!isBossTeam && GetClientTeam(clientIdx) == MercTeam);
			
		if (valid)
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

stock bool:CheckLineOfSight(Float:position[3], targetEntity, Float:zOffset)
{
	static Float:targetPos[3];
	GetEntPropVector(targetEntity, Prop_Send, "m_vecOrigin", targetPos);
	targetPos[2] += zOffset;
	static Float:angles[3];
	GetVectorAnglesTwoPoints(position, targetPos, angles);
	
	new Handle:trace = TR_TraceRayFilterEx(position, angles, (CONTENTS_SOLID | CONTENTS_WINDOW | CONTENTS_GRATE), RayType_Infinite, TraceWallsOnly);
	static Float:endPos[3];
	TR_GetEndPosition(endPos, trace);
	CloseHandle(trace);
	
	return GetVectorDistance(position, targetPos, true) <= GetVectorDistance(position, endPos, true);
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
	ExplodeString(rangeStr, ";", rangeStrs, 2, 32);
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

stock ReadFloatRange(bossIdx, const String:ability_name[], argInt, Float:range[2])
{
	static String:rangeStr[MAX_RANGE_STRING_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, rangeStr, MAX_RANGE_STRING_LENGTH);
	ParseFloatRange(rangeStr, range[0], range[1]);
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

stock ReadSoundWithoutSaving(bossIdx, const String:ability_name[], argInt)
{
	static String:soundFile[MAX_SOUND_FILE_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, soundFile, MAX_SOUND_FILE_LENGTH);
	if (strlen(soundFile) > 3)
		PrecacheSound(soundFile);
}

stock ReadAndPlayGlobalSoundWithClientIndex(clientIdx, const String:ability_name[], argInt)
{
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return;
	static String:soundFile[MAX_SOUND_FILE_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, soundFile, MAX_SOUND_FILE_LENGTH);
	if (strlen(soundFile) > 3)
		EmitSoundToAll(soundFile);
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

stock ReadMaterial(bossIdx, const String:ability_name[], argInt, String:modelFile[MAX_MATERIAL_FILE_LENGTH])
{
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, modelFile, MAX_MATERIAL_FILE_LENGTH);
	if (strlen(modelFile) > 3)
		PrecacheModel(modelFile);
}

stock ReadMaterialToInt(bossIdx, const String:ability_name[], argInt)
{
	static String:modelFile[MAX_MATERIAL_FILE_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, modelFile, MAX_MATERIAL_FILE_LENGTH);
	if (strlen(modelFile) > 3)
		return PrecacheModel(modelFile);
	return -1;
}

stock ReadCenterText(bossIdx, const String:ability_name[], argInt, String:centerText[MAX_CENTER_TEXT_LENGTH])
{
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, centerText, MAX_CENTER_TEXT_LENGTH);
	ReplaceString(centerText, MAX_CENTER_TEXT_LENGTH, "\\n", "\n");
}

stock ReadConditions(bossIdx, const String:ability_name[], argInt, TFCond:conditions[MAX_CONDITIONS])
{
	static String:conditionStr[MAX_CONDITIONS * 4];
	static String:conditionStrs[MAX_CONDITIONS][4];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, conditionStr, sizeof(conditionStr));
	new count = ExplodeString(conditionStr, ";", conditionStrs, MAX_CONDITIONS, 4);
	for (new i = 0; i < MAX_CONDITIONS; i++)
	{
		if (i >= count)
			conditions[i] = TFCond:0;
		else
			conditions[i] = TFCond:StringToInt(conditionStrs[i]);
	}
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
			PrintToServer("[sarysamods9] Hit player %d on trace.", entity);
		return true;
	}

	return false;
}

public bool:TraceRedPlayersAndBuildings(entity, contentsMask)
{
	if (IsLivingPlayer(entity) && GetClientTeam(entity) != BossTeam)
	{
		if (PRINT_DEBUG_SPAM)
			PrintToServer("[sarysamods9] Hit player %d on trace.", entity);
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

stock QuietDamage(victim, inflictor, attacker, Float:damage, damageType=DMG_GENERIC, weapon=-1)
{
	new takedamage = GetEntProp(victim, Prop_Data, "m_takedamage");
	SetEntProp(victim, Prop_Data, "m_takedamage", 0);
	SDKHooks_TakeDamage(victim, inflictor, attacker, damage, damageType, weapon);
	SetEntProp(victim, Prop_Data, "m_takedamage", takedamage);
	SDKHooks_TakeDamage(victim, victim, victim, damage, damageType, weapon);
}

// for when damage to a hale needs to be recognized
stock SemiHookedDamage(victim, inflictor, attacker, Float:damage, damageType=DMG_GENERIC, weapon=-1)
{
	if (GetClientTeam(victim) != BossTeam)
		SDKHooks_TakeDamage(victim, inflictor, attacker, damage, damageType, weapon);
	else
		FullyHookedDamage(victim, inflictor, attacker, damage, damageType, weapon);
}

stock FullyHookedDamage(victim, inflictor, attacker, Float:damage, damageType=DMG_GENERIC, weapon=-1, Float:attackPos[3] = NULL_VECTOR)
{
	static String:dmgStr[16];
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
		if (!(attackPos[0] == NULL_VECTOR[0] && attackPos[1] == NULL_VECTOR[1] && attackPos[2] == NULL_VECTOR[2]))
		{
			TeleportEntity(pointHurt, attackPos, NULL_VECTOR, NULL_VECTOR);
		}
		else if (IsLivingPlayer(attacker))
		{
			static Float:attackerOrigin[3];
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", attackerOrigin);
			TeleportEntity(pointHurt, attackerOrigin, NULL_VECTOR, NULL_VECTOR);
		}
		AcceptEntityInput(pointHurt, "Hurt", attacker);
		DispatchKeyValue(pointHurt, "classname", "point_hurt");
		DispatchKeyValue(victim, "targetname", "noonespecial");
		RemoveEntity(INVALID_HANDLE, EntIndexToEntRef(pointHurt));
	}
}

// this version ignores obstacles
stock PseudoAmbientSound(clientIdx, String:soundPath[], count=1, Float:radius=1000.0, bool:skipSelf=false, bool:skipDead=false, Float:volumeFactor=1.0)
{
	static Float:emitterPos[3];
	static Float:listenerPos[3];
	if (!IsLivingPlayer(clientIdx)) // updated 2015-01-16 to allow non-players...finally.
		GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", emitterPos);
	else
		GetClientEyePosition(clientIdx, emitterPos);
	for (new listener = 1; listener < MAX_PLAYERS; listener++)
	{
		if (!IsClientInGame(listener))
			continue;
		else if (skipSelf && listener == clientIdx)
			continue;
		else if (skipDead && !IsLivingPlayer(listener))
			continue;
			
		GetClientEyePosition(listener, listenerPos);
		new Float:distance = GetVectorDistance(emitterPos, listenerPos);
		if (distance >= radius)
			continue;
		
		new Float:volume = (radius - distance) / radius;
		if (volume <= 0.0)
			continue;
		else if (volume > 1.0)
		{
			PrintToServer("[sarysamods9] How the hell is volume greater than 1.0?");
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

stock Float:fsquare(Float:x)
{
	return x * x;
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

stock bool:ConformLineDistance(Float:result[3], const Float:src[3], const Float:dst[3], Float:maxDistance, bool:canExtend = false)
{
	new Float:distance = GetVectorDistance(src, dst);
	if ((distance <= maxDistance && !canExtend) || distance <= 0.0)
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
	
	return distance != 0.0;
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

stock Float:RandomNegative(Float:someVal)
{
	return someVal * (GetRandomInt(0, 1) == 1 ? 1.0 : -1.0);
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

stock bool:PlayerIsInvincible(clientIdx)
{
	return TF2_IsPlayerInCondition(clientIdx, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(clientIdx, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(clientIdx, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInCondition(clientIdx, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(clientIdx, TFCond_Bonked);
}

stock bool:CheckGroundClearance(clientIdx, Float:minClearance, bool:failInWater)
{
	// standing? automatic fail.
	if (GetEntityFlags(clientIdx) & FL_ONGROUND)
		return false;
	else if (failInWater && (GetEntityFlags(clientIdx) & (FL_SWIM | FL_INWATER)))
		return false;
		
	// need to do a trace
	static Float:origin[3];
	GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", origin);
	
	new Handle:trace = TR_TraceRayFilterEx(origin, Float:{90.0,0.0,0.0}, (CONTENTS_SOLID | CONTENTS_WINDOW | CONTENTS_GRATE), RayType_Infinite, TraceWallsOnly);
	static Float:endPos[3];
	TR_GetEndPosition(endPos, trace);
	CloseHandle(trace);
	
	// only Z should change, so this is easy.
	return origin[2] - endPos[2] >= minClearance;
}

stock bool:IsInstanceOf(entity, const String:desiredClassname[])
{
	static String:classname[MAX_ENTITY_CLASSNAME_LENGTH];
	GetEntityClassname(entity, classname, MAX_ENTITY_CLASSNAME_LENGTH);
	return strcmp(classname, desiredClassname) == 0;
}

stock bool:IsInRange(entity1, entity2, Float:radius)
{
	radius *= radius;
	static Float:ent1Pos[3];
	static Float:ent2Pos[3];
	GetEntPropVector(entity1, Prop_Send, "m_vecOrigin", ent1Pos);
	GetEntPropVector(entity2, Prop_Send, "m_vecOrigin", ent2Pos);
	return radius >= GetVectorDistance(ent1Pos, ent2Pos, true);
}

/**
 * REMOVE FROM PACK10
 */
stock Handle:FindPack8()
{
	static String:buffer[256];
	new Handle:iter = GetPluginIterator();
	new Handle:pl = INVALID_HANDLE;
	while (MorePlugins(iter))
	{
		pl = ReadPlugin(iter);
		
		GetPluginFilename(pl, buffer, sizeof(buffer));
		if (StrContains(buffer, "ff2_sarysamods8.ff2", false) != -1)
			break;
		else
			pl = INVALID_HANDLE;
	}
	
	CloseHandle(iter);
	return pl;
}

stock bool:AttemptResize(clientIdx, bool:force, Float:sizeMultiplier)
{
	new bool:result = false;

	new Handle:plugin = FindPack8();
	if (plugin != INVALID_HANDLE)
	{
		new Function:func = GetFunctionByName(plugin, "AttemptResize");
		if (func != INVALID_FUNCTION)
		{
			Call_StartFunction(plugin, func);
			Call_PushCell(clientIdx);
			Call_PushCell(force);
			Call_PushFloat(sizeMultiplier);
			Call_Finish(result);
		}
		else
			PrintToServer("ERROR: Could not find ff2_sarysamods8.sp:AttemptResize().");
	}
	else
		PrintToServer("ERROR: Could not find ff2_sarysamods8 plugin. AttemptResize() failed.");
		
	return result;
}

stock bool:IsSpotSafe(clientIdx, const Float:pos[3], Float:sizeMultiplier = 1.0)
{
	new bool:result = false;

	new Handle:plugin = FindPack8();
	if (plugin != INVALID_HANDLE)
	{
		new Function:func = GetFunctionByName(plugin, "IsSpotSafe");
		if (func != INVALID_FUNCTION)
		{
			Call_StartFunction(plugin, func);
			Call_PushCell(clientIdx);
			Call_PushFloat(pos[0]);
			Call_PushFloat(pos[1]);
			Call_PushFloat(pos[2]);
			Call_PushFloat(sizeMultiplier);
			Call_Finish(result);
		}
		else
			PrintToServer("ERROR: Could not find ff2_sarysamods8.sp:IsSpotSafe().");
	}
	else
		PrintToServer("ERROR: Could not find ff2_sarysamods8 plugin. IsSpotSafe() failed.");
		
	return result;
}

public Float:GetWeaponAttribute(weapon, attribute, Float:defaultValue)
{
	new Address:addr = TF2Attrib_GetByDefIndex(weapon, attribute);
	if (addr < Address_MinimumValid)
		return defaultValue;
		
	return TF2Attrib_GetValue(addr);
}

/**
 * Taken from Roll the Dice mod by bl4nk
 *
 * DO NOT COPY TO PACK10
 */
CreateRagdoll(client, Float:flSelfDestruct=0.0)
{
	new iRag = CreateEntityByName("tf_ragdoll");
	if (iRag > MaxClients && IsValidEntity(iRag))
	{
		new Float:flPos[3];
		new Float:flAng[3];
		new Float:flVel[3];
		GetClientAbsOrigin(client, flPos);
		GetClientAbsAngles(client, flAng);
		
		TeleportEntity(iRag, flPos, flAng, flVel);
		
		SetEntProp(iRag, Prop_Send, "m_iPlayerIndex", client);
		SetEntProp(iRag, Prop_Send, "m_bIceRagdoll", 1);
		SetEntProp(iRag, Prop_Send, "m_iTeam", GetClientTeam(client));
		SetEntProp(iRag, Prop_Send, "m_iClass", _:TF2_GetPlayerClass(client));
		SetEntProp(iRag, Prop_Send, "m_bOnGround", 1);
		
		SetEntityMoveType(iRag, MOVETYPE_NONE);
		
		DispatchSpawn(iRag);
		ActivateEntity(iRag);
		
		if (flSelfDestruct > 0.0)
			CreateTimer(flSelfDestruct, RemoveEntity, EntIndexToEntRef(iRag), TIMER_FLAG_NO_MAPCHANGE);
		
		return iRag;
	}
	
	return 0;
}

/**
 * Credit to FlaminSarge (DO NOT COPY THESE TO PACK10!)
 */
new Handle:hPlayTaunt;
public RegisterForceTaunt()
{
	new Handle:conf = LoadGameConfigFile("tf2.tauntem");
	if (conf == INVALID_HANDLE)
	{
		PrintToServer("[sarysamods9] Unable to load gamedata/tf2.tauntem.txt. Guitar Hero DOT will not function.");
		return;
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CTFPlayer::PlayTauntSceneFromItem");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	hPlayTaunt = EndPrepSDKCall();
	if (hPlayTaunt == INVALID_HANDLE)
	{
		SetFailState("[sarysamods9] Unable to initialize call to CTFPlayer::PlayTauntSceneFromItem. Need to get updated tf2.tauntem.txt method signatures. Guitar Hero DOT will not function.");
		CloseHandle(conf);
		return;
	}
	CloseHandle(conf);
}

new congaFailurePrintout = false;
public ForceUserToTaunt(clientIdx, itemdef)
{
	if (hPlayTaunt == INVALID_HANDLE)
		return; // return silently
		
	new ent = MakeCEIVEnt(clientIdx, itemdef);
	if (!IsValidEntity(ent))
	{
		if (!congaFailurePrintout)
		{
			PrintToServer("[sarysamods9] Could not create %d taunt entity.", itemdef);
			congaFailurePrintout = true;
		}
		return;
	}
	new Address:pEconItemView = GetEntityAddress(ent) + Address:FindSendPropInfo("CTFWearable", "m_Item");
	if (pEconItemView <= Address_MinimumValid)
	{
		if (!congaFailurePrintout)
		{
			PrintToServer("[sarysamods9] Couldn't find CEconItemView for taunt %d.", itemdef);
			congaFailurePrintout = true;
		}
		AcceptEntityInput(ent, "Kill");
		return;
	}
	
	new bool:success = SDKCall(hPlayTaunt, clientIdx, pEconItemView);
	AcceptEntityInput(ent, "Kill");
	
	if (!success && PRINT_DEBUG_SPAM)
		PrintToServer("[sarysamods9] Failed to force %d to taunt %d.", clientIdx, itemdef);
}

stock MakeCEIVEnt(client, itemdef)
{
	static Handle:hItem;
	if (hItem == INVALID_HANDLE)
	{
		hItem = TF2Items_CreateItem(OVERRIDE_ALL|PRESERVE_ATTRIBUTES|FORCE_GENERATION);
		TF2Items_SetClassname(hItem, "tf_wearable_vm");
		TF2Items_SetQuality(hItem, 6);
		TF2Items_SetLevel(hItem, 1);
		TF2Items_SetNumAttributes(hItem, 0);
	}
	TF2Items_SetItemIndex(hItem, itemdef);
	return TF2Items_GiveNamedItem(client, hItem);
}
