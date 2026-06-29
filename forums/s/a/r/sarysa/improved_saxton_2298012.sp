// no warranty blah blah don't sue blah blah doing this for fun blah blah...

//#define VSP_VERSION

#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <sdkhooks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#if defined VSP_VERSION
native FF2_GetBossMax(index=0); // hidden in ff2...
#endif
#include <tf2attributes>
#undef REQUIRE_PLUGIN
#tryinclude <ff2_dynamic_defaults>
#tryinclude <goomba>
#define REQUIRE_PLUGIN

/**
 * Rages for sarysa's improved version of Saxton Hale
 *
 * Replaced that stupid stun rage with actual physical fighting moves, which is far more appropriate for Saxton.
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
#define MAX_TERMINOLOGY_LENGTH 24
#define MAX_ABILITY_NAME_LENGTH 33
#define MAX_KILL_ID_LENGTH 33

// common array limits
#define MAX_CONDITIONS 10 // TF2 conditions (bleed, dazed, etc.)

#define MAX_PLAYERS_ARRAY 36
#define MAX_PLAYERS (MAX_PLAYERS_ARRAY < (MaxClients + 1) ? MAX_PLAYERS_ARRAY : (MaxClients + 1))

new bool:NULL_BLACKLIST[MAX_PLAYERS_ARRAY];

new MercTeam = _:TFTeam_Red;
new BossTeam = _:TFTeam_Blue;

new bool:RoundInProgress = false;
new bool:PluginActiveThisRound = false;

public Plugin:myinfo = {
	name = "Freak Fortress 2: Improved Saxton",
	author = "sarysa",
	version = "1.0.3",
}

#define FAR_FUTURE 100000000.0

/**
 * Shared
 */
#define SAXTON_KEY_RELOAD 0
#define SAXTON_KEY_SPECIAL 1
#define SAXTON_KEY_ALT_FIRE 2
#define MAX_RAGE_SOUNDS 3

/**
 * Saxton Lunge
 */
#define SL_STRING "saxton_lunge"
#define SL_ANIM_COND TFCond:83
#define SL_VERIFICATION_INTERVAL 0.05
#define SL_SOLIDIFY_INTERVAL 0.05
new bool:SL_ActiveThisRound;
new bool:SL_EnsureCollision = false; // an extra layer of protection for the collision fudging that lunge does
new bool:SL_CanUse[MAX_PLAYERS_ARRAY];
new bool:SL_IsUsing[MAX_PLAYERS_ARRAY]; // internal
new bool:SL_KeyDown[MAX_PLAYERS_ARRAY]; // internal
new Float:SL_InitialYaw[MAX_PLAYERS_ARRAY]; // internal
new Float:SL_InitialPitch[MAX_PLAYERS_ARRAY]; // internal, needed only for speed verification and proper push renewal
new Float:SL_OnCooldownUntil[MAX_PLAYERS_ARRAY]; // internal
new Float:SL_NextPushAt[MAX_PLAYERS_ARRAY]; // internal
new Float:SL_GraceEndsAt[MAX_PLAYERS_ARRAY]; // internal
new Float:SL_ForceRageEndAt[MAX_PLAYERS_ARRAY]; // internal
new bool:SL_AlreadyHit[MAX_PLAYERS_ARRAY]; // internal, victim use
new Float:SL_TrySolidifyAt; // internal
new SL_TrySolidifyBossClientIdx; // internal
new SL_DesiredKey[MAX_PLAYERS_ARRAY]; // based on arg1
new Float:SL_Cooldown[MAX_PLAYERS_ARRAY]; // arg2
new Float:SL_RageCost[MAX_PLAYERS_ARRAY]; // arg3
new Float:SL_Velocity[MAX_PLAYERS_ARRAY]; // arg4
new Float:SL_Damage[MAX_PLAYERS_ARRAY]; // arg5
new bool:SL_DestroyBuildings[MAX_PLAYERS_ARRAY]; // arg6
new Float:SL_BaseKnockback[MAX_PLAYERS_ARRAY]; // arg7
new Float:SL_CollisionDistance[MAX_PLAYERS_ARRAY]; // arg8
new Float:SL_CollisionHeight[MAX_PLAYERS_ARRAY]; // arg9
new Float:SL_CollisionRadius[MAX_PLAYERS_ARRAY]; // arg10
// arg11 only used at rage time
new String:SL_HitSound[MAX_SOUND_FILE_LENGTH]; // arg12, shared
new String:SL_HitEffect[MAX_EFFECT_NAME_LENGTH]; // arg13
new String:SL_CooldownError[MAX_CENTER_TEXT_LENGTH]; // arg16
new String:SL_NotEnoughRageError[MAX_CENTER_TEXT_LENGTH]; // arg17
new String:SL_InWaterError[MAX_CENTER_TEXT_LENGTH]; // arg18
new String:SL_WeighdownError[MAX_CENTER_TEXT_LENGTH]; // arg19
 
/**
 * Saxton Slam
 */
#define SS_STRING "saxton_slam"
#define SS_JUMP_FORCE 800.0
//hammer_impact_button was rejected by Chdata for the below
#define SS_EFFECT_GROUNDPOUND1 "hammer_impact_button_dust2"
#define SS_EFFECT_GROUNDPOUND2 "hammer_impact_button_ring"
new bool:SS_ActiveThisRound;
new bool:SS_CanUse[MAX_PLAYERS_ARRAY];
new bool:SS_IsUsing[MAX_PLAYERS_ARRAY]; // internal
new bool:SS_KeyDown[MAX_PLAYERS_ARRAY]; // internal
new Float:SS_PreparingUntil[MAX_PLAYERS_ARRAY]; // internal
new Float:SS_TauntingUntil[MAX_PLAYERS_ARRAY]; // internal
new Float:SS_OnCooldownUntil[MAX_PLAYERS_ARRAY]; // internal
new Float:SS_NoSlamUntil[MAX_PLAYERS_ARRAY]; // internal, workaround for a bug where slam sometimes happens in midair
new SS_PropEntRef[MAX_PLAYERS_ARRAY]; // internal
new bool:SS_WasFirstPerson[MAX_PLAYERS_ARRAY]; // internal
new TFClassType:SS_OldClass[MAX_PLAYERS_ARRAY]; // internal, lets a soldier do the party trick taunt
new SS_DesiredKey[MAX_PLAYERS_ARRAY]; // based on arg1
new Float:SS_Cooldown[MAX_PLAYERS_ARRAY]; // arg2
new Float:SS_RageCost[MAX_PLAYERS_ARRAY]; // arg3
new SS_ForcedTaunt[MAX_PLAYERS_ARRAY]; // arg4
new Float:SS_PropDelay[MAX_PLAYERS_ARRAY]; // arg5
new String:SS_PropModel[MAX_MODEL_FILE_LENGTH]; // arg6
new Float:SS_GravityDelay[MAX_PLAYERS_ARRAY]; // arg7
new Float:SS_GravitySetting[MAX_PLAYERS_ARRAY]; // arg8
new Float:SS_MaxDamage[MAX_PLAYERS_ARRAY]; // arg9
new Float:SS_Radius[MAX_PLAYERS_ARRAY]; // arg10
new Float:SS_DamageDecayExponent[MAX_PLAYERS_ARRAY]; // arg11
new Float:SS_BuildingDamageFactor[MAX_PLAYERS_ARRAY]; // arg12
new Float:SS_Knockback[MAX_PLAYERS_ARRAY]; // arg13
new Float:SS_PitchConstraint[MAX_PLAYERS_ARRAY][2]; // arg14
// arg14 and arg15 only used at rage time
new String:SS_CooldownError[MAX_CENTER_TEXT_LENGTH]; // arg16
new String:SS_NotEnoughRageError[MAX_CENTER_TEXT_LENGTH]; // arg17
new String:SS_NotMidairError[MAX_CENTER_TEXT_LENGTH]; // arg18
new String:SS_WeighdownError[MAX_CENTER_TEXT_LENGTH]; // arg19
 
/**
 * Saxton Berserker
 */
#define SB_STRING "rage_saxton_berserk"
#define SB_FLAG_AUTO_FIRE 0x0001
#define SB_FLAG_FLAMING_FISTS 0x0002
#define SB_FLAG_MEGAHEAL 0x0004
#define SB_FLAG_IGNITE_SOLDIER 0x0008
#define SB_FLAG_WEAK_KNOCKBACK_IMMUNE 0x0010
new bool:SB_ActiveThisRound;
new bool:SB_CanUse[MAX_PLAYERS_ARRAY];
new Float:SB_UsingUntil[MAX_PLAYERS_ARRAY];
new Float:SB_FireExpiresAt[MAX_PLAYERS_ARRAY]; // internal, victim use only
new bool:SB_GiveRageRefund[MAX_PLAYERS_ARRAY]; // internal, for extreme edge case
new SB_FlameEntRefs[MAX_PLAYERS_ARRAY][2]; // internal
new bool:SB_IsFists[MAX_PLAYERS_ARRAY]; // internal
new Float:SB_LastAttackAvailable[MAX_PLAYERS_ARRAY]; // internal
new bool:SB_IsAttack2[MAX_PLAYERS_ARRAY]; // internal
new TFClassType:SB_OriginalClass[MAX_PLAYERS_ARRAY]; // internal
new Float:SB_Duration[MAX_PLAYERS_ARRAY]; // arg1
// arg2-arg10 not stored
new Float:SB_Speed[MAX_PLAYERS_ARRAY]; // arg11
// arg12 not stored
new TFClassType:SB_TempClass[MAX_PLAYERS_ARRAY]; // arg13
new Float:SB_FireTimeLimit[MAX_PLAYERS_ARRAY]; // arg14
new SB_Flags[MAX_PLAYERS_ARRAY]; // arg19

/**
 * Saxton HUDs
 */
#define SH_STRING "saxton_huds" // a unified HUD, to prevent flicker
#define SH_MAX_HUD_FORMAT_LENGTH 30 // keep it short since it may be individualized in a multi-boss scenario and I don't want to waste too much data space
new bool:SH_ActiveThisRound;
new bool:SH_CanUse[MAX_PLAYERS_ARRAY];
new Float:SH_NextHUDAt[MAX_PLAYERS_ARRAY]; // internal
new Float:SH_HUDInterval[MAX_PLAYERS_ARRAY]; // internal, minor interface change if using Dynamic Defaults to minimize flicker
new SH_LastHPValue[MAX_PLAYERS_ARRAY]; // internal, for bullshit workaround
new Handle:SH_NormalHUDHandle;
new Handle:SH_AlertHUDHandle;
new Float:SH_HudY[MAX_PLAYERS_ARRAY]; // arg1
new String:SH_HudFormat[MAX_PLAYERS_ARRAY][SH_MAX_HUD_FORMAT_LENGTH]; // arg2
new bool:SH_DisplayHealth[MAX_PLAYERS_ARRAY]; // arg3
new bool:SH_DisplayRage[MAX_PLAYERS_ARRAY]; // arg4
new String:SH_LungeReadyStr[MAX_CENTER_TEXT_LENGTH]; // arg5, shared
new String:SH_LungeNotReadyStr[MAX_CENTER_TEXT_LENGTH]; // arg6, shared
new String:SH_SlamReadyStr[MAX_CENTER_TEXT_LENGTH]; // arg7, shared
new String:SH_SlamNotReadyStr[MAX_CENTER_TEXT_LENGTH]; // arg8, shared
new String:SH_BerserkReadyStr[MAX_CENTER_TEXT_LENGTH]; // arg9, shared
new String:SH_BerserkNotReadyStr[MAX_CENTER_TEXT_LENGTH]; // arg10, shared
new SH_NormalColor[MAX_PLAYERS_ARRAY]; // arg11
new SH_AlertColor[MAX_PLAYERS_ARRAY]; // arg12
new bool:SH_AlertIfNotReady[MAX_PLAYERS_ARRAY]; // arg13
new String:SH_HealthStr[MAX_CENTER_TEXT_LENGTH]; // arg14, shared
new String:SH_RageStr[MAX_CENTER_TEXT_LENGTH]; // arg15, shared
new bool:SH_AlertOnLowHP[MAX_PLAYERS_ARRAY]; // arg16

/**
 * Saxton Advanced Options
 */
#define SAO_STRING "saxton_advanced_options"
new bool:SAO_CanUse[MAX_PLAYERS_ARRAY];
new TFCond:SAO_LungeConditions[MAX_PLAYERS_ARRAY][MAX_CONDITIONS]; // arg1
new TFCond:SAO_SlamConditions[MAX_PLAYERS_ARRAY][MAX_CONDITIONS]; // arg2
new TFCond:SAO_BerserkConditions[MAX_PLAYERS_ARRAY][MAX_CONDITIONS]; // arg3
// args 12-19 aren't initialized
#define MAX_KILL_ID_LENGTH 33

/**
 * METHODS REQUIRED BY ff2 subplugin
 */
PrintRageWarning()
{
	PrintToServer("*********************************************************************");
	PrintToServer("*                             WARNING                               *");
	PrintToServer("*       DEBUG_FORCE_RAGE in improved_saxton.sp is set to true!      *");
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
	
	SH_NormalHUDHandle = CreateHudSynchronizer(); // All you need to use ShowSyncHudText is to initialize this handle once in OnPluginStart()
	SH_AlertHUDHandle = CreateHudSynchronizer();  // Then use a unique handle for what hudtext you want sync'd to not overlap itself.

	RegisterForceTaunt();
	
	if (DEBUG_FORCE_RAGE)
	{
		PrintRageWarning();
		RegAdminCmd(CMD_FORCE_RAGE, CmdForceRage, ADMFLAG_GENERIC);
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// in case round end isn't executing...
	// I'm keeping this around. it's a paranoia add in case for example a Stripper-made arena map is receiving the wrong events
	// or something else I can't even foresee. considering I may take long breaks from maintaining this I'd hate
	// to have to address problems resulting from its removal. Its existence is safe, regardless.
	Saxton_Cleanup();
	
	// since this can now be dynamically switched.
	BossTeam = FF2_GetBossTeam();
	RoundInProgress = true;
	
	// initialize variables
	PluginActiveThisRound = false;
	SL_ActiveThisRound = false;
	SS_ActiveThisRound = false;
	SB_ActiveThisRound = false;
	SH_ActiveThisRound = false;
	
	// initialize arrays
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		// all client inits
		SL_CanUse[clientIdx] = false;
		SS_CanUse[clientIdx] = false;
		SB_CanUse[clientIdx] = false;
		SH_CanUse[clientIdx] = false;
		SAO_CanUse[clientIdx] = false;
		SB_FireExpiresAt[clientIdx] = FAR_FUTURE;
		
		if (SL_EnsureCollision && IsLivingPlayer(clientIdx))
		{
			SetEntProp(clientIdx, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
			if (PRINT_DEBUG_SPAM)
				PrintToServer("Ensured correct collision for player %d", clientIdx);
		}

		// boss-only inits
		new bossIdx = IsLivingPlayer(clientIdx) ? FF2_GetBossIndex(clientIdx) : -1;
		if (bossIdx < 0)
			continue;

		if ((SL_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, SL_STRING)) == true)
		{
			PluginActiveThisRound = true;
			SL_ActiveThisRound = true;
			SL_IsUsing[clientIdx] = false;
			SL_OnCooldownUntil[clientIdx] = 0.0;
			SL_TrySolidifyAt = FAR_FUTURE;

			SL_DesiredKey[clientIdx] = Saxton_GetKey(bossIdx, SL_STRING, 1);
			SL_Cooldown[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SL_STRING, 2);
			SL_RageCost[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SL_STRING, 3);
			SL_Velocity[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SL_STRING, 4);
			SL_Damage[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SL_STRING, 5);
			SL_DestroyBuildings[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SL_STRING, 6) == 1;
			SL_BaseKnockback[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SL_STRING, 7);
			SL_CollisionDistance[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SL_STRING, 8);
			SL_CollisionHeight[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SL_STRING, 9);
			SL_CollisionRadius[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SL_STRING, 10);
			Saxton_ReadSounds(bossIdx, SL_STRING, 11);
			ReadSound(bossIdx, SL_STRING, 12, SL_HitSound);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SL_STRING, 13, SL_HitEffect, MAX_EFFECT_NAME_LENGTH);
			new bool:pcSuccess = ReadFloatRange(bossIdx, SL_STRING, 14, SS_PitchConstraint[clientIdx]);
			ReadCenterText(bossIdx, SL_STRING, 16, SL_CooldownError);
			ReadCenterText(bossIdx, SL_STRING, 17, SL_NotEnoughRageError);
			ReadCenterText(bossIdx, SL_STRING, 18, SL_InWaterError);
			ReadCenterText(bossIdx, SL_STRING, 19, SL_WeighdownError);

			// initialize key state
			SL_KeyDown[clientIdx] = (GetClientButtons(clientIdx) & SL_DesiredKey[clientIdx]) != 0;
			
			// fix pitch constraint
			if (!pcSuccess)
			{
				SS_PitchConstraint[clientIdx][0] = -90.0;
				SS_PitchConstraint[clientIdx][1] = 90.0;
			}
		}

		if ((SS_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, SS_STRING)) == true)
		{
			PluginActiveThisRound = true;
			SS_ActiveThisRound = true;
			SS_IsUsing[clientIdx] = false;
			SS_PropEntRef[clientIdx] = INVALID_ENTREF;
			SS_OnCooldownUntil[clientIdx] = 0.0;
			SS_PreparingUntil[clientIdx] = FAR_FUTURE;
			SS_TauntingUntil[clientIdx] = FAR_FUTURE;

			SS_DesiredKey[clientIdx] = Saxton_GetKey(bossIdx, SS_STRING, 1);
			SS_Cooldown[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SS_STRING, 2);
			SS_RageCost[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SS_STRING, 3);
			SS_ForcedTaunt[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SS_STRING, 4);
			SS_PropDelay[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SS_STRING, 5);
			ReadModel(bossIdx, SS_STRING, 6, SS_PropModel);
			SS_GravityDelay[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SS_STRING, 7);
			SS_GravitySetting[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SS_STRING, 8);
			SS_MaxDamage[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SS_STRING, 9);
			SS_Radius[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SS_STRING, 10);
			SS_DamageDecayExponent[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SS_STRING, 11);
			SS_BuildingDamageFactor[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SS_STRING, 12);
			SS_Knockback[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SS_STRING, 13);
			Saxton_ReadSounds(bossIdx, SS_STRING, 14);
			SS_SlamSound(bossIdx, false); // precaches it
			ReadCenterText(bossIdx, SS_STRING, 16, SS_CooldownError);
			ReadCenterText(bossIdx, SS_STRING, 17, SS_NotEnoughRageError);
			ReadCenterText(bossIdx, SS_STRING, 18, SS_NotMidairError);
			ReadCenterText(bossIdx, SS_STRING, 19, SS_WeighdownError);

			// initialize key state
			SS_KeyDown[clientIdx] = (GetClientButtons(clientIdx) & SS_DesiredKey[clientIdx]) != 0;
		}

		if ((SB_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, SB_STRING)) == true)
		{
			PluginActiveThisRound = true;
			SB_ActiveThisRound = true;
			SB_UsingUntil[clientIdx] = FAR_FUTURE;
			SB_FlameEntRefs[clientIdx][0] = INVALID_ENTREF;
			SB_FlameEntRefs[clientIdx][1] = INVALID_ENTREF;
			SB_GiveRageRefund[clientIdx] = false;
			SB_IsAttack2[clientIdx] = false;
			SB_LastAttackAvailable[clientIdx] = GetGameTime();
			
			// not much to load here...
			SB_Duration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SB_STRING, 1);
			SB_Speed[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SB_STRING, 11);
			SB_TempClass[clientIdx] = TFClassType:FF2_GetAbilityArgument(bossIdx, this_plugin_name, SB_STRING, 13);
			SB_FireTimeLimit[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SB_STRING, 14);

			SB_Flags[clientIdx] = ReadHexOrDecString(bossIdx, SB_STRING, 19);
		}

		if ((SH_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, SH_STRING)) == true)
		{
			PluginActiveThisRound = true;
			SH_ActiveThisRound = true;
			SH_NextHUDAt[clientIdx] = GetEngineTime();
			SH_HUDInterval[clientIdx] = 0.1;
			if (FF2_HasAbility(bossIdx, "ff2_dynamic_defaults", "dynamic_jump") || FF2_HasAbility(bossIdx, "ff2_dynamic_defaults", "dynamic_teleport"))
				SH_HUDInterval[clientIdx] = 0.2;
			
			SH_HudY[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SH_STRING, 1);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SH_STRING, 2, SH_HudFormat[clientIdx], SH_MAX_HUD_FORMAT_LENGTH);
			ReplaceString(SH_HudFormat[clientIdx], SH_MAX_HUD_FORMAT_LENGTH, "\\n", "\n");
			SH_DisplayHealth[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SH_STRING, 3) == 1;
			SH_DisplayRage[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SH_STRING, 4) == 1;
			ReadCenterText(bossIdx, SH_STRING, 5, SH_LungeReadyStr);
			ReadCenterText(bossIdx, SH_STRING, 6, SH_LungeNotReadyStr);
			ReadCenterText(bossIdx, SH_STRING, 7, SH_SlamReadyStr);
			ReadCenterText(bossIdx, SH_STRING, 8, SH_SlamNotReadyStr);
			ReadCenterText(bossIdx, SH_STRING, 9, SH_BerserkReadyStr);
			ReadCenterText(bossIdx, SH_STRING, 10, SH_BerserkNotReadyStr);
			SH_NormalColor[clientIdx] = ReadHexOrDecString(bossIdx, SH_STRING, 11);
			SH_AlertColor[clientIdx] = ReadHexOrDecString(bossIdx, SH_STRING, 12);
			SH_AlertIfNotReady[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SH_STRING, 13) == 1;
			ReadCenterText(bossIdx, SH_STRING, 14, SH_HealthStr);
			ReadCenterText(bossIdx, SH_STRING, 15, SH_RageStr);
			SH_AlertOnLowHP[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SH_STRING, 16) == 1;
		}
		
		if ((SAO_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, SAO_STRING)) == true)
		{
			ReadConditions(bossIdx, SAO_STRING, 1, SAO_LungeConditions[clientIdx]);
			ReadConditions(bossIdx, SAO_STRING, 2, SAO_SlamConditions[clientIdx]);
			ReadConditions(bossIdx, SAO_STRING, 3, SAO_BerserkConditions[clientIdx]);
		}
	}
	
	SL_EnsureCollision = false;
	
	// add prethink and death hook for saxton rages and saxton HUD
	if (SS_ActiveThisRound || SB_ActiveThisRound || SL_ActiveThisRound || SH_ActiveThisRound)
	{
		PrecacheSound(NOPE_AVI); // one more go at this, for paranoia sake
		HookEvent("player_death", Saxton_PlayerDeath, EventHookMode_Pre);
	
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (SS_CanUse[clientIdx] || SB_CanUse[clientIdx] || SL_CanUse[clientIdx])
				SDKHook(clientIdx, SDKHook_PreThink, Saxton_PreThink);
				
			if (SB_ActiveThisRound && IsClientInGame(clientIdx))
				SDKHook(clientIdx, SDKHook_OnTakeDamage, Saxton_OnTakeDamage);
		}
	}
	
	CreateTimer(0.3, Timer_PostRoundStartInits, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_PostRoundStartInits(Handle:timer)
{
	// hale suicided (or plugin not active)
	if (!RoundInProgress || !PluginActiveThisRound)
		return Plugin_Handled;
	
	// finish initialization of stuff
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx) || GetClientTeam(clientIdx) != BossTeam)
			continue;

		new bossIdx = FF2_GetBossIndex(clientIdx);
		if (bossIdx < 0)
			continue;
		
		if (SB_CanUse[clientIdx])
			SB_SwapWeapon(clientIdx, false);

		// HUD hiding settings. done after delay because of possible load order issues with Dynamic Defaults
		if (SH_CanUse[clientIdx])
		{
			FF2_SetFF2flags(clientIdx, FF2_GetFF2flags(clientIdx) | FF2FLAG_HUDDISABLED);
			DD_SetForceHUDEnabled(clientIdx, true);
		}
	}

	return Plugin_Handled;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundInProgress = false;
	Saxton_Cleanup();
}

public Saxton_Cleanup()
{
	if (!PluginActiveThisRound)
		return;

	PluginActiveThisRound = false;
	
	// remove prethink. also fix gravity, because it leaks.
	if (SS_ActiveThisRound || SB_ActiveThisRound || SL_ActiveThisRound || SH_ActiveThisRound)
	{
		if (SL_ActiveThisRound)
			SL_EnsureCollision = true;
	
		// putting these first, in case anything here causes an error...it'll minimize the damage, but not eliminate.
		SS_ActiveThisRound = false;
		SB_ActiveThisRound = false;
		SL_ActiveThisRound = false;
		SH_ActiveThisRound = false;
		
		UnhookEvent("player_death", Saxton_PlayerDeath, EventHookMode_Pre);
	
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsClientInGame(clientIdx))
			{
				if (SB_ActiveThisRound)
					SDKUnhook(clientIdx, SDKHook_OnTakeDamage, Saxton_OnTakeDamage);
				SDKUnhook(clientIdx, SDKHook_PreThink, Saxton_PreThink);
				
				// gravity changes leak across multiple rounds
				SetEntityGravity(clientIdx, 1.0);
				
				// the below will leak across multiple rounds. at least on old versions of FF2.
				FF2_SetFF2flags(clientIdx, FF2_GetFF2flags(clientIdx) & (~FF2FLAG_HUDDISABLED));

				// one of the rages immobilizes the hale briefly. don't let them remain stuck
				if (IsLivingPlayer(clientIdx))
					SetEntityMoveType(clientIdx, MOVETYPE_WALK);
			}

			if (SS_CanUse[clientIdx]) // do this even if they're dead
				SS_RemoveProp(clientIdx);
				
			// remove megaheal, in case somehow in some configuration this doesn't reset on round change
			if (IsLivingPlayer(clientIdx) && TF2_IsPlayerInCondition(clientIdx, TFCond_MegaHeal))
				TF2_RemoveCondition(clientIdx, TFCond_MegaHeal);
		}
	}
}

public Action:FF2_OnAbility2(bossIdx, const String:plugin_name[], const String:ability_name[], status)
{
	if (strcmp(plugin_name, this_plugin_name) != 0) // strictly enforce plugin match
		return Plugin_Continue;
	else if (!RoundInProgress) // don't execute these rages with 0 players alive
		return Plugin_Continue;
		
	if (!strcmp(ability_name, SB_STRING))
	{
		Rage_SaxtonBerserk(GetClientOfUserId(FF2_GetBossUserId(bossIdx)));
		
		if (PRINT_DEBUG_INFO)
			PrintToServer("[improved_saxton] Initiating Saxton Berserk");
	}

	return Plugin_Handled; // don't waste time continuing the search? honestly I don't know if FF2 gives a damn what this response is.
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
	
	if (!strcmp("lunge", unparsedArgs))
	{
		SL_Initiate(GetClientOfUserId(FF2_GetBossUserId(0)), GetEngineTime());
		PrintToConsole(user, "Forced boss to use saxton lunge");
		return Plugin_Handled;
	}
	else if (!strcmp("slam", unparsedArgs))
	{
		SS_Initiate(GetClientOfUserId(FF2_GetBossUserId(0)), GetEngineTime());
		PrintToConsole(user, "Forced boss to use saxton slam");
		return Plugin_Handled;
	}
	else if (!strcmp("berserk", unparsedArgs))
	{
		Rage_SaxtonBerserk(GetClientOfUserId(FF2_GetBossUserId(0)));
		PrintToConsole(user, "Forced boss to use saxton berserk");
		return Plugin_Handled;
	}
	
	PrintToServer("[improved_saxton] Rage not found: %s", unparsedArgs);
	return Plugin_Continue;
}

/**
 * Shared
 */
Saxton_GetKey(bossIdx, const String:abilityName[], argIdx)
{
	new keyId = FF2_GetAbilityArgument(bossIdx, this_plugin_name, abilityName, argIdx);
	if (keyId == SAXTON_KEY_RELOAD)
		return IN_RELOAD;
	else if (keyId == SAXTON_KEY_SPECIAL)
		return IN_ATTACK3;
	else if (keyId == SAXTON_KEY_ALT_FIRE)
		return IN_ATTACK2;
		
	PrintToServer("[improved_saxton] ERROR: Invalid key ID specified for %s. Ability has no key assigned and cannot be executed.", abilityName);
	return 0;
}

public Saxton_PreThink(clientIdx)
{
	if (!IsLivingPlayer(clientIdx))
		return;
		
	if (SS_CanUse[clientIdx])
		SS_PreThink(clientIdx);
	if (SB_CanUse[clientIdx])
		SB_PreThink(clientIdx);
	if (SL_CanUse[clientIdx])
		SL_PreThink(clientIdx);
	if (SH_CanUse[clientIdx])
		SH_PreThink(clientIdx);
}

new String:Saxton_Sounds[MAX_RAGE_SOUNDS][MAX_SOUND_FILE_LENGTH];
Saxton_ReadSounds(bossIdx, const String:abilityName[], argIdx)
{
	static String:readStr[(MAX_SOUND_FILE_LENGTH + 1) * MAX_RAGE_SOUNDS];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, abilityName, argIdx, readStr, sizeof(readStr));
	ExplodeString(readStr, ";", Saxton_Sounds, MAX_RAGE_SOUNDS, MAX_SOUND_FILE_LENGTH);
	for (new i = 0; i < MAX_RAGE_SOUNDS; i++)
		if (strlen(Saxton_Sounds[i]) > 3)
			PrecacheSound(Saxton_Sounds[i]);
}

Saxton_RandomSound()
{
	new count = 0;
	for (new i = 0; i < MAX_RAGE_SOUNDS; i++)
		if (strlen(Saxton_Sounds[i]) > 3)
			count++;
			
	if (count == 0)
		return;
		
	new rand = GetRandomInt(0, count-1);
	if (strlen(Saxton_Sounds[rand]) > 3)
	{
		EmitSoundToAll(Saxton_Sounds[rand]);
		EmitSoundToAll(Saxton_Sounds[rand]);
	}
}

public Saxton_GetKillStringWithDefault(bossIdx, const String:abilityName[], argIdx, String:killStr[MAX_KILL_ID_LENGTH], clientIdx, const String:defaultStr[])
{
	if (SAO_CanUse[clientIdx])
	{
		FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, abilityName, argIdx, killStr, MAX_KILL_ID_LENGTH);
		if (!IsEmptyString(killStr))
			return; // good enough
	}
	
	strcopy(killStr, MAX_KILL_ID_LENGTH, defaultStr);
}

// only hooking this for situational kill icons
// p.s. scripts/mod_textures.txt. You're welcome.
new bool:Saxton_TempGoomba = false;
public Action:Saxton_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (IsLivingPlayer(attacker))
	{
		static String:killWeapon[MAX_KILL_ID_LENGTH];
		static String:killName[MAX_KILL_ID_LENGTH];
		new bool:override = false;
		
		new bossIdx = FF2_GetBossIndex(attacker);
		if (bossIdx < 0)
			return Plugin_Continue;

		if (SS_CanUse[attacker] && SS_IsUsing[attacker])
		{
			override = true;
			if (Saxton_TempGoomba)
				Saxton_GetKillStringWithDefault(bossIdx, SAO_STRING, 15, killWeapon, attacker, "mantreads");
			else
				Saxton_GetKillStringWithDefault(bossIdx, SAO_STRING, 16, killWeapon, attacker, "firedeath");
			Saxton_GetKillStringWithDefault(bossIdx, SAO_STRING, 12, killName, attacker, "saxton slam");
		}
		
		if (SL_CanUse[attacker] && SL_IsUsing[attacker])
		{
			override = true;
			if (Saxton_TempGoomba)
				Saxton_GetKillStringWithDefault(bossIdx, SAO_STRING, 17, killWeapon, attacker, "mantreads");
			else
				Saxton_GetKillStringWithDefault(bossIdx, SAO_STRING, 18, killWeapon, attacker, "apocofists");
			Saxton_GetKillStringWithDefault(bossIdx, SAO_STRING, 13, killName, attacker, "saxton lunge");
		}
		
		if (SB_CanUse[attacker] && SB_UsingUntil[attacker] != FAR_FUTURE)
		{
			override = true;
			Saxton_GetKillStringWithDefault(bossIdx, SAO_STRING, 19, killWeapon, attacker, "vehicle");
			Saxton_GetKillStringWithDefault(bossIdx, SAO_STRING, 14, killName, attacker, "saxton berserk");
		}
		
		if (override)
		{
			SetEventString(event, "weapon", killWeapon); // train
			SetEventString(event, "weapon_logclassname", killName);
		}
	}
	
	return Plugin_Continue;
}

public Action:Saxton_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsLivingPlayer(victim) && IsLivingPlayer(attacker))
	{
		if (SB_CanUse[attacker] && SB_UsingUntil[attacker] != FAR_FUTURE)
		{
			if (TF2_GetPlayerClass(victim) == TFClass_Soldier)
			{
				if ((SB_Flags[attacker] & SB_FLAG_IGNITE_SOLDIER) != 0 && !TF2_IsPlayerInCondition(victim, TFCond_OnFire))
				{
					TF2_IgnitePlayer(victim, attacker);
					SB_FireExpiresAt[victim] = GetEngineTime() + SB_FireTimeLimit[attacker];
				}
			}
			else if (weapon == GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon"))
			{
				SB_FireExpiresAt[victim] = GetEngineTime() + SB_FireTimeLimit[attacker];
			}
		}
		else if (SB_CanUse[victim] && SB_UsingUntil[victim] != FAR_FUTURE)
		{
			if (SB_Flags[victim] & SB_FLAG_IGNITE_SOLDIER)
			{
				damagetype |= DMG_PREVENT_PHYSICS_FORCE;
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

public Saxton_AddConditions(clientIdx, const TFCond:conditions[MAX_CONDITIONS])
{
	if (!SAO_CanUse[clientIdx])
		return;

	for (new i = 0; i < MAX_CONDITIONS; i++)
		if (conditions[i] > TFCond:0)
			TF2_AddCondition(clientIdx, conditions[i], -1.0);
}

public Saxton_RemoveConditions(clientIdx, const TFCond:conditions[MAX_CONDITIONS])
{
	if (!SAO_CanUse[clientIdx])
		return;

	for (new i = 0; i < MAX_CONDITIONS; i++)
		if (conditions[i] > TFCond:0 && TF2_IsPlayerInCondition(clientIdx, conditions[i]))
			TF2_RemoveCondition(clientIdx, conditions[i]);
}

public Action:OnStomp(attacker, victim, &Float:damageMultiplier, &Float:damageBonus, &Float:JumpPower)
{
	if ((SS_ActiveThisRound && SS_CanUse[attacker] && SS_IsUsing[attacker]) || (SL_ActiveThisRound && SL_CanUse[attacker] && SL_IsUsing[attacker]))
	{
		Saxton_TempGoomba = true;
		SDKHooks_TakeDamage(victim, attacker, attacker, 9001.0, DMG_GENERIC, -1);
		Saxton_TempGoomba = false;
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/**
 * Saxton Lunge
 */
public bool:SL_RageAvailable(clientIdx, Float:curTime, bool:reportError)
{
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return false;
		
	if (FF2_GetBossCharge(bossIdx, 0) < SL_RageCost[clientIdx])
	{
		if (reportError)
		{
			if (!IsEmptyString(SL_NotEnoughRageError))
				PrintCenterText(clientIdx, SL_NotEnoughRageError, SL_RageCost[clientIdx]);
			Nope(clientIdx);
		}
		return false;
	}

	if (GetEntityGravity(clientIdx) == 6.0)
	{
		if (reportError)
		{
			if (!IsEmptyString(SL_WeighdownError))
				PrintCenterText(clientIdx, SL_WeighdownError);
			Nope(clientIdx);
		}
		return false;
	}
	
	if (IsFullyInWater(clientIdx))
	{
		if (reportError)
		{
			if (!IsEmptyString(SL_InWaterError))
				PrintCenterText(clientIdx, SL_InWaterError);
			Nope(clientIdx);
		}
		return false;
	}
	
	if (SL_OnCooldownUntil[clientIdx] > curTime)
	{
		if (reportError)
		{
			if (!IsEmptyString(SL_CooldownError))
				PrintCenterText(clientIdx, SL_CooldownError);
			Nope(clientIdx);
		}
		return false;
	}
	
	// fail silently if the user is stunned or taunting
	if (TF2_IsPlayerInCondition(clientIdx, TFCond_Dazed) || TF2_IsPlayerInCondition(clientIdx, TFCond_Taunting))
		return false;
		
	// don't allow while other rages are active
	if ((SL_CanUse[clientIdx] && SL_IsUsing[clientIdx]) || (SS_CanUse[clientIdx] && SS_IsUsing[clientIdx]) || SB_UsingUntil[clientIdx] != FAR_FUTURE)
		return false;
	
	// all conditions passed
	return true;
}

public SL_Initiate(clientIdx, Float:curTime)
{
	// remove rage
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return;
	FF2_SetBossCharge(bossIdx, 0, FF2_GetBossCharge(bossIdx, 0) - SL_RageCost[clientIdx]);

	// rage sound and initializations
	Saxton_ReadSounds(bossIdx, SL_STRING, 11);
	Saxton_RandomSound();
	SL_OnCooldownUntil[clientIdx] = curTime + SL_Cooldown[clientIdx];
	SL_NextPushAt[clientIdx] = curTime + SL_VERIFICATION_INTERVAL;
	SL_GraceEndsAt[clientIdx] = curTime + 0.1; // grace for still being on the ground, without this the rage ends immediately
	SL_ForceRageEndAt[clientIdx] = curTime + 1.0; // my code would allow people to surf endlessly on some maps. need to have to have a raw time limit.
	SL_IsUsing[clientIdx] = true;
	for (new victim = 1; victim < MAX_PLAYERS; victim++)
	{
		// set a neutral collision group to allow the hell to mow through enemies
		if (IsLivingPlayer(victim))
			SetEntProp(victim, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS_TRIGGER);
		SL_AlreadyHit[victim] = false;
	}

	// add condition 81 and megaheal
	TF2_AddCondition(clientIdx, SL_ANIM_COND, -1.0);
	TF2_AddCondition(clientIdx, TFCond_MegaHeal, -1.0);
	Saxton_AddConditions(clientIdx, SAO_LungeConditions[clientIdx]);

	// get eye angles, store pitch and yaw which are needed for renewal and collision
	static Float:angles[3];
	GetClientEyeAngles(clientIdx, angles);
	
	// added for 1.0.0: constrain pitch
	angles[0] = fmin(SS_PitchConstraint[clientIdx][1], fmax(SS_PitchConstraint[clientIdx][0], angles[0]));
	
	SL_InitialYaw[clientIdx] = angles[1];
	SL_InitialPitch[clientIdx] = angles[0];

	// push the hale
	static Float:velocity[3];
	GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(velocity, SL_Velocity[clientIdx]);
	if ((GetEntityFlags(clientIdx) & FL_ONGROUND) != 0 || GetEntProp(clientIdx, Prop_Send, "m_nWaterLevel") >= 1)
		velocity[2] = fmax(velocity[2], 310.0);
	else
		velocity[2] += 50.0; // a little boost to alleviate arcing issues
	TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, velocity);

	// disable dynamic abilities during the rage.
	DD_SetDisabled(clientIdx, true, true, true, true);
}

public SL_OnPlayerRunCmd(clientIdx, buttons, Float:curTime)
{
	new bool:keyDown = (buttons & SL_DesiredKey[clientIdx]) != 0;
	if (keyDown && !SL_KeyDown[clientIdx] && SL_RageAvailable(clientIdx, curTime, true))
	{
		SL_Initiate(clientIdx, curTime);
	}
	
	SL_KeyDown[clientIdx] = keyDown;
}

// special line of sight check since displacements can easily screw up origin to origin checks
// there'll be some bullshit misses but this is one of those rare cases attacks going through walls would be too common
public bool:SL_HasLineOfSight(Float:bossPos[3], Float:victimPos[3], Float:zOffset)
{
	static Float:tmpPos[3];
	bossPos[2] += zOffset;
	victimPos[2] += zOffset;
	TR_TraceRayFilter(bossPos, victimPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceWallsOnly);
	TR_GetEndPosition(tmpPos);
	bossPos[2] -= zOffset;
	victimPos[2] -= zOffset;
	tmpPos[2] -= zOffset;
	
	if (PRINT_DEBUG_SPAM)
		PrintToServer("[improved_saxton] Line of sight test: %f == %f && %f == %f && %f == %f", tmpPos[0], victimPos[0], tmpPos[1], victimPos[1], tmpPos[2], victimPos[2]);
	
	return tmpPos[0] == victimPos[0] && tmpPos[1] == victimPos[1] && tmpPos[2] == victimPos[2];
}

public SL_HitSoundsAndEffects(clientIdx, victim, Float:victimPos[3])
{
	if (strlen(SL_HitSound) > 3)
	{
		PseudoAmbientSound(victim, SL_HitSound[clientIdx]);
		PseudoAmbientSound(victim, SL_HitSound[clientIdx]);
	}
	
	if (!IsEmptyString(SL_HitEffect))
	{
		victimPos[2] += 41.5;
		ParticleEffectAt(victimPos, SL_HitEffect, 1.0);
		victimPos[2] -= 41.5;
	}
}

public SL_PreThink(clientIdx)
{
	new Float:curTime = GetEngineTime();
	
	if (SL_IsUsing[clientIdx])
	{
		// end rage now if player hit ground or water
		if (curTime >= SL_ForceRageEndAt[clientIdx] || (curTime >= SL_GraceEndsAt[clientIdx] && ((GetEntityFlags(clientIdx) & FL_ONGROUND) != 0) || IsFullyInWater(clientIdx)))
		{
			SL_IsUsing[clientIdx] = false;
			if (TF2_IsPlayerInCondition(clientIdx, SL_ANIM_COND))
				TF2_RemoveCondition(clientIdx, SL_ANIM_COND);
			if (TF2_IsPlayerInCondition(clientIdx, TFCond_MegaHeal))
				TF2_RemoveCondition(clientIdx, TFCond_MegaHeal);
			Saxton_RemoveConditions(clientIdx, SAO_LungeConditions[clientIdx]);
			DD_SetDisabled(clientIdx, false, false, false, false);
			SL_TrySolidifyAt = curTime;
			SL_TrySolidifyBossClientIdx = clientIdx;
			return;
		}

		// need to do a little work to determine the collision cylinder origin, which needs to be in front of the hale
		static Float:angles[3];
		angles[0] = 0.0; // ignore pitch for now
		angles[1] = SL_InitialYaw[clientIdx];
		static Float:bossPos[3];
		GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", bossPos);
		static Float:hitPos[3];
		TR_TraceRayFilter(bossPos, angles, MASK_PLAYERSOLID, RayType_Infinite, TraceWallsOnly);
		TR_GetEndPosition(hitPos);
		new Float:distance = GetVectorDistance(bossPos, hitPos);

		// constrain the distance of origin a little so it's not on top of a wall boundary,
		// and of course so it's not greater than the set limit
		if (distance >= SL_CollisionDistance[clientIdx])
			constrainDistance(bossPos, hitPos, distance, SL_CollisionDistance[clientIdx] - 0.1);
		else
			constrainDistance(bossPos, hitPos, distance, distance - 0.1);
			
		//PrintToServer("hitPos vs bossPos: %f,%f,%f vs %f,%f,%f     colrad=%f", hitPos[0], hitPos[1], hitPos[2], bossPos[0], bossPos[1], bossPos[2], SL_CollisionRadius[clientIdx]);

		// check collision every tick
		for (new victim = 1; victim < MAX_PLAYERS; victim++)
		{
			if (SL_AlreadyHit[victim] || !IsLivingPlayer(victim) || GetClientTeam(victim) == BossTeam)
				continue;

			// cylinder collision check
			static Float:victimPos[3];
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
			if (!CylinderCollision(hitPos, victimPos, SL_CollisionRadius[clientIdx], hitPos[2] - 103.0, hitPos[2] + SL_CollisionHeight[clientIdx]))
				continue;

			// so it's close enough. ensure we don't hit through a wall.
			if (SL_HasLineOfSight(hitPos, victimPos, 41.5))
			{
				SL_AlreadyHit[victim] = true;
				SL_HitSoundsAndEffects(clientIdx, victim, victimPos);

				// knockback first, this one takes the hale's velocity into account
				static Float:haleVelocity[3];
				GetEntPropVector(clientIdx, Prop_Data, "m_vecVelocity", haleVelocity);
				haleVelocity[2] = 0.0;
				static Float:velocity[3];
				GetVectorAnglesTwoPoints(hitPos, victimPos, angles);
				GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(velocity, SL_BaseKnockback[clientIdx] + SL_Velocity[clientIdx]); //getLinearVelocity(haleVelocity));
				if ((GetEntityFlags(victim) & FL_ONGROUND) != 0 && velocity[2] < 300.0) // minimum Z, gives victims lift
					velocity[2] = 300.0;
				else if (velocity[2] < 50.0)
					velocity[2] = 50.0; // if someone's jumping, keep them from falling too quickly and body blocking the hale
				TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, velocity);

				// damage is simple enough
				if (SL_Damage[clientIdx] > 0.0)
					FullyHookedDamage(victim, clientIdx, clientIdx, fixDamageForFF2(SL_Damage[clientIdx] * 0.33), DMG_CRIT, -1);
			}
		}

		// check buildings if applicable. hopefully doing this every frame isn't _too_ expensive.
		if (SL_DestroyBuildings[clientIdx]) for (new pass = 0; pass <= 2; pass++)
		{
			static String:classname[MAX_ENTITY_CLASSNAME_LENGTH];
			if (pass == 0) classname = "obj_sentrygun";
			else if (pass == 1) classname = "obj_dispenser";
			else if (pass == 2) classname = "obj_teleporter";

			new building = MaxClients + 1;
			while ((building = FindEntityByClassname(building, classname)) != -1)
			{
				if (GetEntProp(building, Prop_Send, "m_bCarried") || GetEntProp(building, Prop_Send, "m_bPlacing"))
					continue;

				static Float:buildingPos[3];
				GetEntPropVector(building, Prop_Send, "m_vecOrigin", buildingPos);
				if (!CylinderCollision(hitPos, buildingPos, SL_CollisionRadius[clientIdx], hitPos[2] - 103.0, hitPos[2] + SL_CollisionHeight[clientIdx]))
					continue;

				if (SL_HasLineOfSight(hitPos, buildingPos, 41.5))
				{
					SL_HitSoundsAndEffects(clientIdx, building, buildingPos);
					SDKHooks_TakeDamage(building, clientIdx, clientIdx, 9999.0, DMG_GENERIC, -1);
				}
			}
		}

		// next validity check
		if (curTime >= SL_NextPushAt[clientIdx])
		{
			// keep refreshing x/y. this also prevents air strafing
			static Float:velocity[3];
			GetEntPropVector(clientIdx, Prop_Data, "m_vecVelocity", velocity);
			new Float:currentZ = velocity[2];
			velocity[2] = 0.0;
			if (getLinearVelocity(velocity) < 100.0) // close enough to stopping
			{
				static Float:pushVel[3];
				angles[0] = SL_InitialPitch[clientIdx];
				angles[1] = SL_InitialYaw[clientIdx];
				GetAngleVectors(angles, pushVel, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(pushVel, SL_Velocity[clientIdx]);
				
				// renew the x/y push but maintain existing Z, lest this rage never end
				pushVel[2] = currentZ;
				TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, pushVel);
			}
			
			SL_NextPushAt[clientIdx] = curTime + SL_VERIFICATION_INTERVAL;
		}
	}
}

/**
 * Saxton Slam
 */
public SS_SlamSound(bossIdx, bool:play)
{
	static String:soundName[MAX_SOUND_FILE_LENGTH];
	ReadSound(bossIdx, SS_STRING, 15, soundName);
	if (play && strlen(soundName) > 3)
	{
		EmitSoundToAll(soundName);
		EmitSoundToAll(soundName);
	}
}
 
public SS_RemoveProp(clientIdx)
{
	if (SS_PropEntRef[clientIdx] == INVALID_ENTREF)
		return;
		
	RemoveEntity(INVALID_HANDLE, SS_PropEntRef[clientIdx]);
	SS_PropEntRef[clientIdx] = INVALID_ENTREF;
}

public Float:SS_CalculateDamage(clientIdx, Float:distance)
{
	new Float:damage;
	if (SS_DamageDecayExponent[clientIdx] <= 0.0)
		damage = SS_MaxDamage[clientIdx];
	else if (SS_DamageDecayExponent[clientIdx] == 1.0)
		damage = SS_MaxDamage[clientIdx] * (1.0 - (distance / SS_Radius[clientIdx]));
	else
	{
		damage = SS_MaxDamage[clientIdx] - (SS_MaxDamage[clientIdx] * (Pow(Pow(SS_Radius[clientIdx], SS_DamageDecayExponent[clientIdx]) -
			Pow(SS_Radius[clientIdx] - distance, SS_DamageDecayExponent[clientIdx]), 1.0 / SS_DamageDecayExponent[clientIdx]) / SS_Radius[clientIdx]));
	}
		
	return fmax(1.0, damage);
}

public bool:SS_RageAvailable(clientIdx, Float:curTime, bool:reportError)
{
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return false;
		
	if (FF2_GetBossCharge(bossIdx, 0) < SS_RageCost[clientIdx])
	{
		if (reportError)
		{
			if (!IsEmptyString(SS_NotEnoughRageError))
				PrintCenterText(clientIdx, SS_NotEnoughRageError, SS_RageCost[clientIdx]);
			Nope(clientIdx);
		}
		return false;
	}

	if (GetEntityGravity(clientIdx) == 6.0)
	{
		if (reportError)
		{
			if (!IsEmptyString(SS_WeighdownError))
				PrintCenterText(clientIdx, SS_WeighdownError);
			Nope(clientIdx);
		}
		return false;
	}
	
	if (GetEntityFlags(clientIdx) & (FL_ONGROUND | FL_SWIM | FL_INWATER))
	{
		if (reportError)
		{
			if (!IsEmptyString(SS_NotMidairError))
				PrintCenterText(clientIdx, SS_NotMidairError);
			Nope(clientIdx);
		}
		return false;
	}
	
	if (SS_OnCooldownUntil[clientIdx] > curTime)
	{
		if (reportError)
		{
			if (!IsEmptyString(SS_CooldownError))
				PrintCenterText(clientIdx, SS_CooldownError);
			Nope(clientIdx);
		}
		return false;
	}
	
	// fail silently if the user is stunned or taunting
	if (TF2_IsPlayerInCondition(clientIdx, TFCond_Dazed) || TF2_IsPlayerInCondition(clientIdx, TFCond_Taunting))
		return false;
		
	// don't allow while other rages are active
	if ((SS_CanUse[clientIdx] && SS_IsUsing[clientIdx]) || (SL_CanUse[clientIdx] && SL_IsUsing[clientIdx]) || SB_UsingUntil[clientIdx] != FAR_FUTURE)
		return false;
	
	// all conditions passed
	return true;
}

SS_CreateEarthquake(clientIdx)
{
	new Float:amplitude = 16.0;
	new Float:radius = SS_Radius[clientIdx];
	new Float:duration = 5.0;
	new Float:frequency = 255.0;

	new earthquake = CreateEntityByName("env_shake");
	if (IsValidEntity(earthquake))
	{
		static Float:halePos[3];
		GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", halePos);
	
		DispatchKeyValueFloat(earthquake, "amplitude", amplitude);
		DispatchKeyValueFloat(earthquake, "radius", radius * 2);
		DispatchKeyValueFloat(earthquake, "duration", duration + 2.0);
		DispatchKeyValueFloat(earthquake, "frequency", frequency);

		SetVariantString("spawnflags 4"); // no physics (physics is 8), affects people in air (4)
		AcceptEntityInput(earthquake, "AddOutput");

		// create
		DispatchSpawn(earthquake);
		TeleportEntity(earthquake, halePos, NULL_VECTOR, NULL_VECTOR);

		AcceptEntityInput(earthquake, "StartShake", 0);
		CreateTimer(duration + 0.1, RemoveEntity, EntIndexToEntRef(earthquake), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public SS_Initiate(clientIdx, Float:curTime)
{
	// remove rage
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return;
	FF2_SetBossCharge(bossIdx, 0, FF2_GetBossCharge(bossIdx, 0) - SS_RageCost[clientIdx]);
	
	// remove FOV effect, fixing an issue where lunge immediately followed by slam traps user in a higher FOV
	SetEntProp(clientIdx, Prop_Send, "m_iFOV", GetEntProp(clientIdx, Prop_Send, "m_iDefaultFOV"));
	SetEntPropFloat(clientIdx, Prop_Send, "m_flFOVTime", 0.0);
	
	Saxton_ReadSounds(bossIdx, SS_STRING, 14);
	Saxton_RandomSound();
	SS_TauntingUntil[clientIdx] = curTime + SS_PropDelay[clientIdx];
	SS_NoSlamUntil[clientIdx] = SS_TauntingUntil[clientIdx] + 0.2;
	SS_PreparingUntil[clientIdx] = curTime + SS_GravityDelay[clientIdx];
	SS_OnCooldownUntil[clientIdx] = curTime + SS_Cooldown[clientIdx];
	SS_IsUsing[clientIdx] = true;
	TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, Float:{0.0, 0.0, 0.0}); // stop velocity

	// set immobile and immovable
	SetEntityMoveType(clientIdx, MOVETYPE_NONE);
	TF2_AddCondition(clientIdx, TFCond_MegaHeal, -1.0);
	Saxton_AddConditions(clientIdx, SAO_SlamConditions[clientIdx]);
	if (strlen(SS_PropModel) > 3)
	{
		SS_RemoveProp(clientIdx); // in case the cooldown is zero and this rage is spammable
		new prop = CreateEntityByName("prop_physics");
		if (IsValidEntity(prop))
		{
			SetEntityModel(prop, SS_PropModel);
			DispatchSpawn(prop);
			static Float:spawnPos[3];
			GetEntPropVector(clientIdx, Prop_Data, "m_vecOrigin", spawnPos);
			TeleportEntity(prop, spawnPos, NULL_VECTOR, NULL_VECTOR);
			SetEntProp(prop, Prop_Data, "m_takedamage", 0);

			SetEntityMoveType(prop, MOVETYPE_NONE);
			SetEntProp(prop, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_NONE);
			SS_PropEntRef[clientIdx] = EntIndexToEntRef(prop);

			SetEntityRenderMode(prop, RENDER_TRANSCOLOR);
			SetEntityRenderColor(prop, 255, 255, 255, 0);
		}
	}

	// force third person during the rage
	SS_WasFirstPerson[clientIdx] = (GetEntProp(clientIdx, Prop_Send, "m_nForceTauntCam") == 0);
	SetVariantInt(1);
	AcceptEntityInput(clientIdx, "SetForcedTauntCam");

	// force the taunt. if the prop is good, this'll work.
	if (SS_ForcedTaunt[clientIdx] > 0)
	{
		SetEntProp(clientIdx, Prop_Send, "m_fFlags", GetEntProp(clientIdx, Prop_Send, "m_fFlags") | FL_ONGROUND);
		SS_OldClass[clientIdx] = TF2_GetPlayerClass(clientIdx);
		new TFClassType:newClass = GetClassOfTaunt(SS_ForcedTaunt[clientIdx], SS_OldClass[clientIdx]);
		if (SS_OldClass[clientIdx] != newClass)
			TF2_SetPlayerClass(clientIdx, newClass);
		ForceUserToTaunt(clientIdx, SS_ForcedTaunt[clientIdx]);
	}

	// disable dynamic abilities during the rage.
	DD_SetDisabled(clientIdx, true, true, true, true);
}

public SS_OnPlayerRunCmd(clientIdx, buttons, Float:curTime)
{
	new bool:keyDown = (buttons & SS_DesiredKey[clientIdx]) != 0;
	if (keyDown && !SS_KeyDown[clientIdx] && SS_RageAvailable(clientIdx, curTime, true))
		SS_Initiate(clientIdx, curTime);
	
	SS_KeyDown[clientIdx] = keyDown;
}

public SS_PreThink(clientIdx)
{
	new Float:curTime = GetEngineTime();
	
	if (SS_IsUsing[clientIdx])
	{
		if (curTime >= SS_TauntingUntil[clientIdx])
		{
			SS_TauntingUntil[clientIdx] = FAR_FUTURE;
			SetEntityMoveType(clientIdx, MOVETYPE_WALK);
			TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, Float:{0.0, 0.0, SS_JUMP_FORCE}); // simulate a high jump
			SS_RemoveProp(clientIdx);
			
			// fix their class
			if (SS_ForcedTaunt[clientIdx] > 0 && TF2_GetPlayerClass(clientIdx) != SS_OldClass[clientIdx])
				TF2_SetPlayerClass(clientIdx, SS_OldClass[clientIdx]);
		}
		else if (SS_TauntingUntil[clientIdx] != FAR_FUTURE) // this is plus the prop's physics rect are necessary for the trick to work
		{
			if (SS_ForcedTaunt[clientIdx] > 0 && !TF2_IsPlayerInCondition(clientIdx, TFCond_Taunting))
			{
				SetEntProp(clientIdx, Prop_Send, "m_fFlags", GetEntProp(clientIdx, Prop_Send, "m_fFlags") | FL_ONGROUND);
				ForceUserToTaunt(clientIdx, SS_ForcedTaunt[clientIdx]);
			}
		}
		
		if (SS_PreparingUntil[clientIdx] != FAR_FUTURE && SS_TauntingUntil[clientIdx] == FAR_FUTURE)
		{
			if (curTime >= SS_PreparingUntil[clientIdx])
			{
				SS_PreparingUntil[clientIdx] = FAR_FUTURE;
				TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, Float:{0.0, 0.0, -100.0}); // give them a head start downward
				SetEntityGravity(clientIdx, SS_GravitySetting[clientIdx]); // set gravity now
			}
			else
			{
				// if player hits a ceiling, suspend them in midair until it's time to fall
				static Float:velocity[3];
				GetEntPropVector(clientIdx, Prop_Data, "m_vecVelocity", velocity);
				if (velocity[2] < 0.0)
				{
					velocity[2] = 0.0;
					TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, velocity);
				}
			}
		}
	
		if (SS_PreparingUntil[clientIdx] == FAR_FUTURE)
		{
			if (curTime >= SS_NoSlamUntil[clientIdx] && (GetEntityFlags(clientIdx) & FL_ONGROUND) != 0)
			{
				// damage nearby players, but make this unhooked damage if it's under two thirds of the user's HP
				// or if it's a spy.
				static Float:halePos[3];
				GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", halePos);
				
				// either use override particle or default
				static String:effect1[MAX_EFFECT_NAME_LENGTH];
				static String:effect2[MAX_EFFECT_NAME_LENGTH];
				new bool:override = false;
				if (SAO_CanUse[clientIdx])
				{
					new bossIdx = FF2_GetBossIndex(clientIdx);
					if (bossIdx >= 0)
					{
						FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SAO_STRING, 4, effect1, MAX_EFFECT_NAME_LENGTH);
						FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SAO_STRING, 5, effect2, MAX_EFFECT_NAME_LENGTH);
						if (!IsEmptyString(effect1) || !IsEmptyString(effect2))
							override = true;
					}
				}
				
				if (!override)
				{
					effect1 = SS_EFFECT_GROUNDPOUND1;
					effect2 = SS_EFFECT_GROUNDPOUND2;
				}
	
				if (!IsEmptyString(effect1))
					ParticleEffectAt(halePos, effect1, 1.0);
				if (!IsEmptyString(effect2))
					ParticleEffectAt(halePos, effect2, 1.0);
				
				for (new victim = 1; victim < MAX_PLAYERS; victim++)
				{
					if (!IsLivingPlayer(victim) || GetClientTeam(victim) == BossTeam)
						continue;
					else if (IsTreadingWater(victim) || IsFullyInWater(victim) || CheckGroundClearance(victim, 80.0, true))
						continue;
						
					static Float:victimPos[3];
					GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
					new Float:distance = GetVectorDistance(halePos, victimPos);
					if (distance >= SS_Radius[clientIdx])
						continue;
					
					// knockback first
					static Float:angles[3];
					static Float:velocity[3];
					GetVectorAnglesTwoPoints(halePos, victimPos, angles);
					GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
					ScaleVector(velocity, SS_Knockback[clientIdx]);
					if ((GetEntityFlags(victim) & FL_ONGROUND) != 0 && velocity[2] < 300.0) // minimum Z, gives victims lift
						velocity[2] = 300.0;
					TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, velocity);
						
					// apply the damage
					if (SS_MaxDamage[clientIdx] > 0.0)
					{
						new Float:damage = SS_CalculateDamage(clientIdx, distance);
						if (TF2_GetPlayerClass(victim) == TFClass_Spy || float(GetEntProp(victim, Prop_Send, "m_iHealth")) * 0.66 >= damage)
							SDKHooks_TakeDamage(victim, clientIdx, clientIdx, damage, DMG_PREVENT_PHYSICS_FORCE, -1);
						else
							FullyHookedDamage(victim, clientIdx, clientIdx, fixDamageForFF2(damage), DMG_PREVENT_PHYSICS_FORCE, -1);
					}
				}
				
				// damage nearby buildings
				if (SS_MaxDamage[clientIdx] > 0.0 && SS_BuildingDamageFactor[clientIdx] > 0.0) for (new pass = 0; pass <= 2; pass++)
				{
					static String:classname[MAX_ENTITY_CLASSNAME_LENGTH];
					if (pass == 0) classname = "obj_sentrygun";
					else if (pass == 1) classname = "obj_dispenser";
					else if (pass == 2) classname = "obj_teleporter";
					
					new building = MaxClients + 1;
					while ((building = FindEntityByClassname(building, classname)) != -1)
					{
						if (GetEntProp(building, Prop_Send, "m_bCarried") || GetEntProp(building, Prop_Send, "m_bPlacing"))
							continue;
					
						static Float:buildingPos[3];
						GetEntPropVector(building, Prop_Send, "m_vecOrigin", buildingPos);
						new Float:distance = GetVectorDistance(buildingPos, halePos);
						if (distance >= SS_Radius[clientIdx])
							continue;
							
						new Float:damage = SS_CalculateDamage(clientIdx, distance);
						SDKHooks_TakeDamage(building, clientIdx, clientIdx, damage * SS_BuildingDamageFactor[clientIdx], DMG_GENERIC, -1);
					}
				}
				
				new bossIdx = FF2_GetBossIndex(clientIdx);
				if (bossIdx >= 0)
					SS_SlamSound(bossIdx, true);
				SS_CreateEarthquake(clientIdx);
			}
			
			// end the rage if on ground or in water. (in water, it'll fail to do damage)
			if (curTime >= SS_NoSlamUntil[clientIdx] && ((GetEntityFlags(clientIdx) & FL_ONGROUND) != 0 || IsFullyInWater(clientIdx)))
			{
				SS_IsUsing[clientIdx] = false;
				if (TF2_IsPlayerInCondition(clientIdx, TFCond_MegaHeal))
					TF2_RemoveCondition(clientIdx, TFCond_MegaHeal);
				Saxton_RemoveConditions(clientIdx, SAO_SlamConditions[clientIdx]);

				SetEntityGravity(clientIdx, 1.0);
				DD_SetDisabled(clientIdx, false, false, false, false);
				
				if (SS_WasFirstPerson[clientIdx])
				{
					SetVariantInt(0);
					AcceptEntityInput(clientIdx, "SetForcedTauntCam");
				}
			}
			else
			{
				// ensure gravity hasn't been changed, i.e. by default_abilities
				if (GetEntityGravity(clientIdx) != SS_GravitySetting[clientIdx])
					SetEntityGravity(clientIdx, SS_GravitySetting[clientIdx]);
			}
		}
	}
}

/**
 * Saxton Berserker
 */
public SB_SwapWeapon(clientIdx, bool:isRage)
{
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return;
		
	if (!isRage)
	{
		for (new i = 0; i < 2; i++)
		{
			if (SB_FlameEntRefs[clientIdx][i] != INVALID_ENTREF)
			{
				RemoveEntity(INVALID_HANDLE, SB_FlameEntRefs[clientIdx][i]);
				SB_FlameEntRefs[clientIdx][i] = INVALID_ENTREF;
			}
		}
	}
		
	static String:weaponName[MAX_WEAPON_NAME_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SB_STRING, (isRage ? 6 : 2), weaponName, MAX_WEAPON_NAME_LENGTH);
	new weaponIdx = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SB_STRING, (isRage ? 7 : 3));
	static String:weaponArgs[MAX_WEAPON_ARG_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SB_STRING, (isRage ? 8 : 4), weaponArgs, MAX_WEAPON_ARG_LENGTH);
	new weaponVisibility = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SB_STRING, (isRage ? 9 : 5));
	new slot = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SB_STRING, 10);
	
	TF2_RemoveWeaponSlot(clientIdx, slot);
	new weapon = SpawnWeapon(clientIdx, weaponName, weaponIdx, 101, 5, weaponArgs, weaponVisibility);
	if (IsValidEntity(weapon))
		SetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon", weapon);
		
	SB_IsFists[clientIdx] = strcmp(weaponName, "tf_weapon_fists") == 0;
	if (SB_IsFists[clientIdx] && isRage && (SB_Flags[clientIdx] & SB_FLAG_FLAMING_FISTS) != 0)
	{
		static String:attachmentStr[(MAX_ATTACHMENT_NAME_LENGTH + 1) * 2];
		FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SB_STRING, 12, attachmentStr, sizeof(attachmentStr));
		if (!IsEmptyString(attachmentStr))
		{
			static String:attachmentStrs[2][MAX_ATTACHMENT_NAME_LENGTH];
			ExplodeString(attachmentStr, ";", attachmentStrs, 2, MAX_ATTACHMENT_NAME_LENGTH);
			for (new i = 0; i < 2; i++)
			{
				if (!IsEmptyString(attachmentStrs[i]))
				{
					new particle = AttachParticleToAttachment(clientIdx, "superrare_burning1", attachmentStrs[i]);
					if (IsValidEntity(particle))
						SB_FlameEntRefs[clientIdx][i] = EntIndexToEntRef(particle);
				}
			}
		}
	}
}
 
public SB_PreThink(clientIdx)
{
	if (SB_UsingUntil[clientIdx] != FAR_FUTURE)
	{
		if (GetEngineTime() >= SB_UsingUntil[clientIdx])
		{
			SB_UsingUntil[clientIdx] = FAR_FUTURE;
			if (TF2_GetPlayerClass(clientIdx) != SB_OriginalClass[clientIdx])
				TF2_SetPlayerClass(clientIdx, SB_OriginalClass[clientIdx]);
			SB_SwapWeapon(clientIdx, false);
			if (TF2_IsPlayerInCondition(clientIdx, TFCond_MegaHeal))
				TF2_RemoveCondition(clientIdx, TFCond_MegaHeal);
			Saxton_RemoveConditions(clientIdx, SAO_BerserkConditions[clientIdx]);
		}
		else
			SetEntPropFloat(clientIdx, Prop_Send, "m_flMaxspeed", SB_Speed[clientIdx]);
	}
	
	if (SB_GiveRageRefund[clientIdx])
	{
		SB_GiveRageRefund[clientIdx] = false;
		new bossIdx = FF2_GetBossIndex(clientIdx);
		if (bossIdx < 0)
			return;
			
		FF2_SetBossCharge(bossIdx, 0, 100.0);
	}
}

public Action:SB_OnPlayerRunCmd(clientIdx, &buttons)
{
	if (SB_UsingUntil[clientIdx] == FAR_FUTURE || (SB_Flags[clientIdx] & SB_FLAG_AUTO_FIRE) == 0)
		return Plugin_Continue;
	
	new weapon = GetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(weapon))
		return Plugin_Continue;
		
	new Float:nextAttack = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");
	if (!SB_IsFists[clientIdx])
	{
		if (GetGameTime() >= nextAttack)
		{
			buttons |= IN_ATTACK;
			return Plugin_Changed;
		}
		return Plugin_Continue;
	}
	
	if (nextAttack > SB_LastAttackAvailable[clientIdx])
		SB_IsAttack2[clientIdx] = !SB_IsAttack2[clientIdx];
	SB_LastAttackAvailable[clientIdx] = nextAttack;
	
	// minimize the pressing of buttons to when they're needed. this minimizes accidental super jumps, etc.
	if (GetGameTime() >= nextAttack)
	{
		buttons |= (SB_IsAttack2[clientIdx] ? IN_ATTACK2 : IN_ATTACK);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Rage_SaxtonBerserk(clientIdx)
{
	// freak instance, but entirely possible
	if ((SL_CanUse[clientIdx] && SL_IsUsing[clientIdx]) || (SS_CanUse[clientIdx] && SS_IsUsing[clientIdx]))
	{
		SB_GiveRageRefund[clientIdx] = true;
		Nope(clientIdx);
		return;
	}

	if (SB_UsingUntil[clientIdx] == FAR_FUTURE) // in case of ragespam
	{
		SB_OriginalClass[clientIdx] = TF2_GetPlayerClass(clientIdx);
		if (SB_TempClass[clientIdx] > TFClassType:0 && SB_TempClass[clientIdx] != SB_OriginalClass[clientIdx])
			TF2_SetPlayerClass(clientIdx, SB_TempClass[clientIdx]);
		SB_SwapWeapon(clientIdx, true);
	}
	SB_UsingUntil[clientIdx] = GetEngineTime() + SB_Duration[clientIdx];
	if (SB_Flags[clientIdx] & SB_FLAG_MEGAHEAL)
		TF2_AddCondition(clientIdx, TFCond_MegaHeal, -1.0);
	Saxton_AddConditions(clientIdx, SAO_BerserkConditions[clientIdx]);
}

/**
 * Saxton HUDs
 */
public SH_PreThink(clientIdx)
{
	if (GetClientButtons(clientIdx) & IN_SCORE)
		return; // Don't show hud when player is viewing scoreboard, as it will only flash violently

	new Float:curTime = GetEngineTime();
	
	if (curTime >= SH_NextHUDAt[clientIdx])
	{
		SH_NextHUDAt[clientIdx] = curTime + SH_HUDInterval[clientIdx];
		new bossIdx = FF2_GetBossIndex(clientIdx);
		if (bossIdx < 0)
			return;
		
		// format health str
		static String:healthStr[80];
		healthStr = "";
#if defined VSP_VERSION
		new hp = FF2_GetBossMax(bossIdx);
#else
		new hp = GetEntProp(clientIdx, Prop_Send, "m_iHealth"); // see my rant about this at the bottom of this file.
#endif
		if (abs(hp - SH_LastHPValue[clientIdx]) <= 5) // this way it'll be wrong, but relatively stable in appearance
			hp = SH_LastHPValue[clientIdx];
		else
			SH_LastHPValue[clientIdx] = hp;
		new maxHP = FF2_GetBossMaxHealth(bossIdx);
		if (SH_DisplayHealth[clientIdx])
			Format(healthStr, sizeof(healthStr), SH_HealthStr, hp, maxHP);
		new bool:healthIsAlert = (SH_AlertOnLowHP[clientIdx] ? (hp * 3 <= maxHP) : false);

		// format rage str
		static String:rageStr[80];
		rageStr = "";
		if (SH_DisplayRage[clientIdx])
			Format(rageStr, sizeof(rageStr), SH_RageStr, FF2_GetBossCharge(bossIdx, 0));
			
		// format ability strs
		static String:lungeStr[MAX_CENTER_TEXT_LENGTH];
		new bool:lungeAvailable = (SL_CanUse[clientIdx] && SL_RageAvailable(clientIdx, curTime, false));
		if (!SL_CanUse[clientIdx])
			lungeStr = "";
		else
			Format(lungeStr, sizeof(lungeStr), (lungeAvailable ? SH_LungeReadyStr : SH_LungeNotReadyStr), SL_RageCost[clientIdx]);
		new bool:lungeIsAlert = (lungeAvailable && !SH_AlertIfNotReady[clientIdx]) || (!lungeAvailable && SH_AlertIfNotReady[clientIdx]);

		static String:slamStr[MAX_CENTER_TEXT_LENGTH];
		new bool:slamAvailable = (SS_CanUse[clientIdx] && SS_RageAvailable(clientIdx, curTime, false));
		if (!SS_CanUse[clientIdx])
			slamStr = "";
		else
			Format(slamStr, sizeof(slamStr), (slamAvailable ? SH_SlamReadyStr : SH_SlamNotReadyStr), SS_RageCost[clientIdx]);
		new bool:slamIsAlert = (slamAvailable && !SH_AlertIfNotReady[clientIdx]) || (!slamAvailable && SH_AlertIfNotReady[clientIdx]);

		static String:berserkStr[MAX_CENTER_TEXT_LENGTH];
		new bool:berserkAvailable = FF2_GetBossCharge(bossIdx, 0) >= 100.0;
		if (!SB_CanUse[clientIdx])
			berserkStr = "";
		else
			Format(berserkStr, sizeof(berserkStr), (berserkAvailable ? SH_BerserkReadyStr : SH_BerserkNotReadyStr), 100.0); // redundant percent in case someone slips up
		new bool:berserkIsAlert = (berserkAvailable && !SH_AlertIfNotReady[clientIdx]) || (!berserkAvailable && SH_AlertIfNotReady[clientIdx]);

		// normal HUD
		SetHudTextParams(-1.0, SH_HudY[clientIdx], SH_HUDInterval[clientIdx] + 0.05, GetR(SH_NormalColor[clientIdx]), GetG(SH_NormalColor[clientIdx]), GetB(SH_NormalColor[clientIdx]), 192);
		ShowSyncHudText(clientIdx, SH_NormalHUDHandle, SH_HudFormat[clientIdx], (!healthIsAlert ? healthStr : ""), rageStr,
					(!lungeIsAlert ? lungeStr : ""), (!slamIsAlert ? slamStr : ""), (!berserkIsAlert ? berserkStr : ""));
		
		// alert HUD
		SetHudTextParams(-1.0, SH_HudY[clientIdx], SH_HUDInterval[clientIdx] + 0.05, GetR(SH_AlertColor[clientIdx]), GetG(SH_AlertColor[clientIdx]), GetB(SH_AlertColor[clientIdx]), 192);
		ShowSyncHudText(clientIdx, SH_AlertHUDHandle, SH_HudFormat[clientIdx], (healthIsAlert ? healthStr : ""), "",
					(lungeIsAlert ? lungeStr : ""), (slamIsAlert ? slamStr : ""), (berserkIsAlert ? berserkStr : ""));
	}
}

/**
 * OnPlayerRunCmd/OnGameFrame
 */
public OnGameFrame()
{
	if (!PluginActiveThisRound || !RoundInProgress)
		return;
	
	new Float:curTime = GetEngineTime();

	// need this fallback for multi-boss, as the invisible prop has collision
	if (SS_ActiveThisRound)
	{
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (SS_CanUse[clientIdx] && !IsLivingPlayer(clientIdx))
				SS_RemoveProp(clientIdx);
		}
	}
	
	// this is best done on the game frame since it'll be either before or after movement checks are made
	// reducing the likelihood of this failing
	if (SL_ActiveThisRound)
	{
		if (curTime >= SL_TrySolidifyAt)
		{
			static Float:bossPos[3];
			GetEntPropVector(SL_TrySolidifyBossClientIdx, Prop_Send, "m_vecOrigin", bossPos);
			static Float:mins[3];
			static Float:maxs[3];
			mins[0] = bossPos[0] - 50.0;
			mins[1] = bossPos[1] - 50.0;
			mins[2] = bossPos[2] - 85.0;
			maxs[0] = bossPos[0] + 50.0;
			maxs[1] = bossPos[1] + 50.0;
			maxs[2] = bossPos[2] + 85.0;
		
			new bool:fail = false;
			for (new victim = 1; victim < MAX_PLAYERS; victim++)
			{
				if (!IsLivingPlayer(victim) || GetClientTeam(victim) == BossTeam)
					continue;
					
				static Float:victimPos[3];
				GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
				if (victimPos[0] >= mins[0] && victimPos[0] <= maxs[0] &&
					victimPos[1] >= mins[1] && victimPos[1] <= maxs[1] &&
					victimPos[2] >= mins[2] && victimPos[2] <= maxs[2])
				{
					fail = true;
					break;
				}
			}
			
			if (fail)
				SL_TrySolidifyAt = curTime + SL_SOLIDIFY_INTERVAL;
			else
			{
				SL_TrySolidifyAt = FAR_FUTURE;
				for (new victim = 1; victim < MAX_PLAYERS; victim++)
					if (IsLivingPlayer(victim))
						SetEntProp(victim, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
			}
		}
	}
	
	// also need the game frame for removing excess fire
	if (SB_ActiveThisRound)
	{
		for (new victim = 1; victim < MAX_PLAYERS; victim++)
		{
			if (IsLivingPlayer(victim) && curTime >= SB_FireExpiresAt[victim])
			{
				SB_FireExpiresAt[victim] = FAR_FUTURE;
				if (TF2_IsPlayerInCondition(victim, TFCond_OnFire))
					TF2_RemoveCondition(victim, TFCond_OnFire);
			}
		}
	}
}
 
public Action:OnPlayerRunCmd(clientIdx, &buttons, &impulse, Float:vel[3], Float:unusedangles[3], &weapon)
{
	if (!PluginActiveThisRound || !RoundInProgress)
		return Plugin_Continue;
	else if (!IsLivingPlayer(clientIdx))
		return Plugin_Continue;
		
	new Action:ret = Plugin_Continue;
		
	if (SS_ActiveThisRound && SS_CanUse[clientIdx])
		SS_OnPlayerRunCmd(clientIdx, buttons, GetEngineTime());
	if (SL_ActiveThisRound && SL_CanUse[clientIdx])
		SL_OnPlayerRunCmd(clientIdx, buttons, GetEngineTime());
	if (SB_ActiveThisRound && SB_CanUse[clientIdx])
		ret = SB_OnPlayerRunCmd(clientIdx, buttons);
	
	return ret;
}

/**
 * General helper stocks, some original, some taken/modified from other sources
 */
stock PlaySoundLocal(clientIdx, String:soundPath[], bool:followPlayer = true, stack = 1)
{
	// play a speech sound that travels normally, local from the player.
	decl Float:playerPos[3];
	GetClientEyePosition(clientIdx, playerPos);
	//PrintToServer("[improved_saxton] eye pos=%f,%f,%f     sound=%s", playerPos[0], playerPos[1], playerPos[2], soundPath);
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
		PrintToServer("[improved_saxton] Error: Invalid weapon spawned. client=%d name=%s idx=%d attr=%s", client, name, index, attribute);
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

stock bool:ReadFloatRange(bossIdx, const String:ability_name[], argInt, Float:range[2])
{
	static String:rangeStr[MAX_RANGE_STRING_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, rangeStr, MAX_RANGE_STRING_LENGTH);
	ParseFloatRange(rangeStr, range[0], range[1]); // do this even if the length is invalid, for stock backwards comatibility
	return (strlen(rangeStr) >= 3); // minimum length for valid range is 3
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
			PrintToServer("[improved_saxton] Hit player %d on trace.", entity);
		return true;
	}

	return false;
}

public bool:TraceRedPlayersAndBuildings(entity, contentsMask)
{
	if (IsLivingPlayer(entity) && GetClientTeam(entity) != BossTeam)
	{
		if (PRINT_DEBUG_SPAM)
			PrintToServer("[improved_saxton] Hit player %d on trace.", entity);
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
			PrintToServer("[improved_saxton] How the hell is volume greater than 1.0?");
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

// need to distinguish being fully in water and not, which is a little more complicated than it should be
stock bool:IsFullyInWater(clientIdx)
{
	new flags = GetEntityFlags(clientIdx);
	if ((flags & (FL_SWIM | FL_INWATER)) == 0)
		return false;

	new waterLevel = GetEntProp(clientIdx, Prop_Send, "m_nWaterLevel");
	if (waterLevel <= 1)
		return false;
		
	return true;
}

stock bool:IsTreadingWater(clientIdx)
{
	return (GetEntityFlags(clientIdx) & FL_ONGROUND) == 0 && GetEntProp(clientIdx, Prop_Send, "m_nWaterLevel") == 1;
}

stock bool:ShouldGetZBoost(clientIdx)
{
	new flags = GetEntityFlags(clientIdx);
	return (flags & FL_ONGROUND) != 0 || ((flags & (FL_SWIM | FL_INWATER)) != 0 && !IsFullyInWater(clientIdx));
}

/**
 * Credit to FlaminSarge
 */
new Handle:hPlayTaunt = INVALID_HANDLE;
public RegisterForceTaunt()
{
	new Handle:conf = LoadGameConfigFile("tf2.tauntem");
	if (conf == INVALID_HANDLE)
	{
		LogError("[improved_saxton] Unable to load gamedata/tf2.tauntem.txt. Guitar Hero DOT will not function.");
		return;
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CTFPlayer::PlayTauntSceneFromItem");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	hPlayTaunt = EndPrepSDKCall();
	if (hPlayTaunt == INVALID_HANDLE)
	{
		LogError("[improved_saxton] Unable to initialize call to CTFPlayer::PlayTauntSceneFromItem. Need to get updated tf2.tauntem.txt method signatures. Saxton Slam will not animate.");
		CloseHandle(conf);
		return;
	}
	CloseHandle(conf);
}

new congaFailurePrintout = false;
public ForceUserToTaunt(clientIdx, itemdef)
{
	if (hPlayTaunt == INVALID_HANDLE)
	{
		if (PRINT_DEBUG_INFO)
			PrintToServer("[improved_saxton] WARNING: RegisterForceTaunt() wasn't ever called, or it needs to be updated.");
		return;
	}
		
	new ent = MakeCEIVEnt(clientIdx, itemdef);
	if (!IsValidEntity(ent))
	{
		if (!congaFailurePrintout)
		{
			PrintToServer("[improved_saxton] Could not create %d taunt entity.", itemdef);
			congaFailurePrintout = true;
		}
		return;
	}
	new Address:pEconItemView = GetEntityAddress(ent) + Address:FindSendPropInfo("CTFWearable", "m_Item");
	if (pEconItemView <= Address_MinimumValid)
	{
		if (!congaFailurePrintout)
		{
			PrintToServer("[improved_saxton] Couldn't find CEconItemView for taunt %d.", itemdef);
			congaFailurePrintout = true;
		}
		AcceptEntityInput(ent, "Kill");
		return;
	}
	
	new bool:success = SDKCall(hPlayTaunt, clientIdx, pEconItemView);
	AcceptEntityInput(ent, "Kill");
	
	if (!success && PRINT_DEBUG_SPAM)
		PrintToServer("[improved_saxton] Failed to force %d to taunt %d.", clientIdx, itemdef);
	else if (PRINT_DEBUG_SPAM)
		PrintToServer("[improved_saxton] Successfully forced %d to taunt %d.", clientIdx, itemdef);
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

// sarysa's addition, needed to allow Saxton to use a non-soldier animation
// returns current player class for all-class taunts, indicating a class change is not necessary.
stock TFClassType:GetClassOfTaunt(tauntIdx, TFClassType:currentPlayerClass)
{
	switch (tauntIdx) // I literally never use these. except now. also it's weird that there's no break and they don't leak.
	{
		case 30609, 30614, 1116:
			return TFClass_Sniper;
		case 30572, 1119, 1117:
			return TFClass_Scout;
		case 1120, 1114:
			return TFClass_DemoMan;
		case 1115:
			return TFClass_Engineer;
		case 1113:
			return TFClass_Soldier;
		case 1112, 30570:
			return TFClass_Pyro;
		case 1109, 477:
			return TFClass_Medic;
		case 1108:
			return TFClass_Spy;
	}
	
	return currentPlayerClass;
}

/**
 * sarysa's reflection method for getting hale HP (backwards compatible)
 *
 * Also it failed miserably because reflection is impossible with native methods. Goddamn it.
 * I mean seriously. What the hell. I can't even use preprocessor to assign the correct native
 * method for getting current health for the user's version of FF2.
 * Old versions actually had a secret native for doing so, but the name changed.
 * Seriously. Why. Why the hell was it removed. Would it be so difficult to add a SECOND ONE
 * along with the hidden one? Did you think no one would find and use the hidden one?
 * Because I certainly did.
 * Gah.
 *
 * </rant> Dead code below. They're stocks so they won't get compiled in.
 */
#define HEALTH_METHOD_UNKNOWN 0
#define HEALTH_METHOD_OLD 1
#define HEALTH_METHOD_NEW 2
#define HEALTH_METHOD_CRAP 3
new getHealthMethod = HEALTH_METHOD_UNKNOWN;
stock GetHaleHealth(clientIdx, bossIdx)
{
	if (getHealthMethod == HEALTH_METHOD_UNKNOWN || getHealthMethod == HEALTH_METHOD_OLD)
	{
		new ret = GetOldBossHealth(bossIdx);
		if (ret != -1)
		{
			if (PRINT_DEBUG_INFO && getHealthMethod == HEALTH_METHOD_UNKNOWN)
				PrintToServer("[improved_saxton] Using old FF2 method for getting hale health.");
			getHealthMethod = HEALTH_METHOD_OLD;
			return ret;
		}
	}

	if (getHealthMethod == HEALTH_METHOD_UNKNOWN || getHealthMethod == HEALTH_METHOD_NEW)
	{
		new ret = GetNewBossHealth(bossIdx);
		if (ret != -1)
		{
			if (PRINT_DEBUG_INFO && getHealthMethod == HEALTH_METHOD_UNKNOWN)
				PrintToServer("[improved_saxton] Using new FF2 method for getting hale health.");
			getHealthMethod = HEALTH_METHOD_NEW;
			return ret;
		}
	}
	
	if (PRINT_DEBUG_INFO && getHealthMethod == HEALTH_METHOD_UNKNOWN)
		PrintToServer("[improved_saxton] Using crappy FF2 method for getting hale health. Yours must be heavily modified.");
	getHealthMethod = HEALTH_METHOD_CRAP;
	return GetEntProp(clientIdx, Prop_Send, "m_iHealth");
}

stock Handle:FindFF2Plugin()
{
	decl String:buffer[256];
	
	new Handle:iter = GetPluginIterator();
	new Handle:pl = INVALID_HANDLE;
	
	while (MorePlugins(iter))
	{
		pl = ReadPlugin(iter);
		
		GetPluginFilename(pl, buffer, sizeof(buffer));
		if (StrContains(buffer, "freak_fortress_2.smx", false) != -1)
			break;
		else
			pl = INVALID_HANDLE;
	}
	
	CloseHandle(iter);

	return pl;
}

stock GetOldBossHealth(bossIdx)
{
	new result = -1;

	new Handle:plugin = FindFF2Plugin();
	if (plugin != INVALID_HANDLE)
	{
		new Function:func = GetFunctionByName(plugin, "Native_GetHealth");
		if (func != INVALID_FUNCTION)
		{
			Call_StartFunction(plugin, func);
			Call_PushCell(bossIdx);
			Call_Finish(result);
		}
		else
			PrintToServer("ERROR: Could not find freak_fortress_2.sp:Native_GetHealth().");
	}
	else
		PrintToServer("ERROR: Could not find freak_fortress_2 plugin. Native_GetHealth() failed.");
		
	return result;
}

stock GetNewBossHealth(bossIdx)
{
	new result = -1;

	new Handle:plugin = FindFF2Plugin();
	if (plugin != INVALID_HANDLE)
	{
		new Function:func = GetFunctionByName(plugin, "Native_GetBossHealth");
		if (func != INVALID_FUNCTION)
		{
			Call_StartFunction(plugin, func);
			Call_PushCell(bossIdx);
			Call_Finish(result);
		}
		else
			PrintToServer("ERROR: Could not find freak_fortress_2.sp:Native_GetBossHealth().");
	}
	else
		PrintToServer("ERROR: Could not find freak_fortress_2 plugin. Native_GetBossHealth() failed.");
		
	return result;
}
