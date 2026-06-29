// no warranty blah blah don't sue blah blah doing this for fun blah blah...

#include <tf2_stocks>
#include <sdkhooks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#if defined VSP_VERSION
native int FF2_GetBossMax(int index=0); // hidden in ff2...
#endif
#undef REQUIRE_PLUGIN
#tryinclude <ff2_dynamic_defaults>
#tryinclude <goomba>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

/**
 * Rages for sarysa's improved version of Saxton Hale
 *
 * Replaced that stupid stun rage with actual physical fighting moves, which is far more appropriate for Saxton.
 */

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
 
bool DEBUG_FORCE_RAGE = true;
#define ARG_LENGTH 256
 
bool PRINT_DEBUG_INFO = false;
bool PRINT_DEBUG_SPAM = false;

float OFF_THE_MAP[3] = { 16383.0, 16383.0, -16383.0 };

#define NOPE_AVI "vo/engineer_no01.mp3" // DO NOT DELETE FROM FUTURE PACKS

#define INVALID_ENTREF INVALID_ENT_REFERENCE
#define INVALID_ENTITY -1

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
#define MAX_ATTACHMENT_NAME_LENGTH 48
#define MAX_HULL_STRING_LENGTH 197
#define HEX_OR_DEC_STRING_LENGTH 12 // max -2 billion is 11 chars + null termination

// common array limits
#define MAX_CONDITIONS 10 // TF2 conditions (bleed, dazed, etc.)

#define MAX_PLAYERS_ARRAY 36
#define MAX_PLAYERS (MAX_PLAYERS_ARRAY < (MaxClients + 1) ? MAX_PLAYERS_ARRAY : (MaxClients + 1))

bool RoundInProgress = false;
bool PluginActiveThisRound = false;

public Plugin myinfo = {
	name = "Freak Fortress 2: Improved Saxton",
	author = "sarysa",
	version = "1.0.5",
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
#define SL_ANIM_COND view_as<TFCond>(TFCond_HalloweenKartDash)
#define SL_VERIFICATION_INTERVAL 0.05
#define SL_SOLIDIFY_INTERVAL 0.05
bool SL_ActiveThisRound;
bool SL_EnsureCollision = false; // an extra layer of protection for the collision fudging that lunge does
bool SL_CanUse[MAX_PLAYERS_ARRAY];
bool SL_IsUsing[MAX_PLAYERS_ARRAY]; // internal
bool SL_KeyDown[MAX_PLAYERS_ARRAY]; // internal
float SL_InitialYaw[MAX_PLAYERS_ARRAY]; // internal
float SL_InitialPitch[MAX_PLAYERS_ARRAY]; // internal, needed only for speed verification and proper push renewal
float SL_OnCooldownUntil[MAX_PLAYERS_ARRAY]; // internal
float SL_NextPushAt[MAX_PLAYERS_ARRAY]; // internal
float SL_GraceEndsAt[MAX_PLAYERS_ARRAY]; // internal
float SL_ForceRageEndAt[MAX_PLAYERS_ARRAY]; // internal
bool SL_AlreadyHit[MAX_PLAYERS_ARRAY]; // internal, victim use
float SL_TrySolidifyAt; // internal
int SL_TrySolidifyBossClientIdx; // internal
int SL_DesiredKey[MAX_PLAYERS_ARRAY]; // based on arg1
float SL_Cooldown[MAX_PLAYERS_ARRAY]; // arg2
float SL_RageCost[MAX_PLAYERS_ARRAY]; // arg3
float SL_Velocity[MAX_PLAYERS_ARRAY]; // arg4
float SL_Damage[MAX_PLAYERS_ARRAY]; // arg5
bool SL_DestroyBuildings[MAX_PLAYERS_ARRAY]; // arg6
float SL_BaseKnockback[MAX_PLAYERS_ARRAY]; // arg7
float SL_CollisionDistance[MAX_PLAYERS_ARRAY]; // arg8
float SL_CollisionHeight[MAX_PLAYERS_ARRAY]; // arg9
float SL_CollisionRadius[MAX_PLAYERS_ARRAY]; // arg10
// arg11 only used at rage time
char SL_HitSound[MAX_SOUND_FILE_LENGTH]; // arg12, shared
char SL_HitEffect[MAX_EFFECT_NAME_LENGTH]; // arg13
char SL_CooldownError[MAX_CENTER_TEXT_LENGTH]; // arg16
char SL_NotEnoughRageError[MAX_CENTER_TEXT_LENGTH]; // arg17
char SL_InWaterError[MAX_CENTER_TEXT_LENGTH]; // arg18
char SL_WeighdownError[MAX_CENTER_TEXT_LENGTH]; // arg19
 
/**
 * Saxton Slam
 */
#define SS_STRING "saxton_slam"
#define SS_JUMP_FORCE 800.0
#define SS_SAXTON_MODEL "models/sarysa/saxton/saxton_hale_by_thepfa_beta1.mdl"
//hammer_impact_button was rejected by Chdata for the below
#define SS_EFFECT_GROUNDPOUND1 "hammer_impact_button_dust2"
#define SS_EFFECT_GROUNDPOUND2 "hammer_impact_button_ring"
bool SS_ActiveThisRound;
bool SS_CanUse[MAX_PLAYERS_ARRAY];
bool SS_IsUsing[MAX_PLAYERS_ARRAY]; // internal
bool SS_KeyDown[MAX_PLAYERS_ARRAY]; // internal
float SS_PreparingUntil[MAX_PLAYERS_ARRAY]; // internal
float SS_TauntingUntil[MAX_PLAYERS_ARRAY]; // internal
float SS_OnCooldownUntil[MAX_PLAYERS_ARRAY]; // internal
float SS_NoSlamUntil[MAX_PLAYERS_ARRAY]; // internal, workaround for a bug where slam sometimes happens in midair
bool SS_WasFirstPerson[MAX_PLAYERS_ARRAY]; // internal
int SS_DesiredKey[MAX_PLAYERS_ARRAY]; // based on arg1
float SS_Cooldown[MAX_PLAYERS_ARRAY]; // arg2
float SS_RageCost[MAX_PLAYERS_ARRAY]; // arg3
int SS_ForcedTaunt[MAX_PLAYERS_ARRAY]; // arg4
float SS_PropDelay[MAX_PLAYERS_ARRAY]; // arg5
char SS_PropModel[MAX_MODEL_FILE_LENGTH]; // arg6
float SS_GravityDelay[MAX_PLAYERS_ARRAY]; // arg7
float SS_GravitySetting[MAX_PLAYERS_ARRAY]; // arg8
float SS_MaxDamage[MAX_PLAYERS_ARRAY]; // arg9
float SS_Radius[MAX_PLAYERS_ARRAY]; // arg10
float SS_DamageDecayExponent[MAX_PLAYERS_ARRAY]; // arg11
float SS_BuildingDamageFactor[MAX_PLAYERS_ARRAY]; // arg12
float SS_Knockback[MAX_PLAYERS_ARRAY]; // arg13
float SS_PitchConstraint[MAX_PLAYERS_ARRAY][2]; // arg14
// arg14 and arg15 only used at rage time
char SS_CooldownError[MAX_CENTER_TEXT_LENGTH]; // arg16
char SS_NotEnoughRageError[MAX_CENTER_TEXT_LENGTH]; // arg17
char SS_NotMidairError[MAX_CENTER_TEXT_LENGTH]; // arg18
char SS_WeighdownError[MAX_CENTER_TEXT_LENGTH]; // arg19
int SS_SaxtonEntRef[MAX_PLAYERS_ARRAY] = {INVALID_ENTREF, ...};

/**
 * Saxton Berserker
 */
#define SB_STRING "rage_saxton_berserk"
#define SB_FLAG_AUTO_FIRE 0x0001
#define SB_FLAG_FLAMING_FISTS 0x0002
#define SB_FLAG_MEGAHEAL 0x0004
#define SB_FLAG_IGNITE_SOLDIER 0x0008
#define SB_FLAG_WEAK_KNOCKBACK_IMMUNE 0x0010
bool SB_ActiveThisRound;
bool SB_CanUse[MAX_PLAYERS_ARRAY];
float SB_UsingUntil[MAX_PLAYERS_ARRAY];
float SB_FireExpiresAt[MAX_PLAYERS_ARRAY]; // internal, victim use only
bool SB_GiveRageRefund[MAX_PLAYERS_ARRAY]; // internal, for extreme edge case
int SB_FlameEntRefs[MAX_PLAYERS_ARRAY][2]; // internal
bool SB_IsFists[MAX_PLAYERS_ARRAY]; // internal
float SB_LastAttackAvailable[MAX_PLAYERS_ARRAY]; // internal
bool SB_IsAttack2[MAX_PLAYERS_ARRAY]; // internal
TFClassType SB_OriginalClass[MAX_PLAYERS_ARRAY]; // internal
float SB_Duration[MAX_PLAYERS_ARRAY]; // arg1
// arg2-arg10 not stored
float SB_Speed[MAX_PLAYERS_ARRAY]; // arg11
// arg12 not stored
TFClassType SB_TempClass[MAX_PLAYERS_ARRAY]; // arg13
float SB_FireTimeLimit[MAX_PLAYERS_ARRAY]; // arg14
int SB_Flags[MAX_PLAYERS_ARRAY]; // arg19

/**
 * Saxton HUDs
 */
#define SH_STRING "saxton_huds" // a unified HUD, to prevent flicker
#define SH_MAX_HUD_FORMAT_LENGTH 30 // keep it short since it may be individualized in a multi-boss scenario and I don't want to waste too much data space
bool SH_ActiveThisRound;
bool SH_CanUse[MAX_PLAYERS_ARRAY];
float SH_NextHUDAt[MAX_PLAYERS_ARRAY]; // internal
float SH_HUDInterval[MAX_PLAYERS_ARRAY]; // internal, minor interface change if using Dynamic Defaults to minimize flicker
int SH_LastHPValue[MAX_PLAYERS_ARRAY]; // internal, for bullshit workaround
Handle SH_NormalHUDHandle;
Handle SH_AlertHUDHandle;
float SH_HudY[MAX_PLAYERS_ARRAY]; // arg1
char SH_HudFormat[MAX_PLAYERS_ARRAY][SH_MAX_HUD_FORMAT_LENGTH]; // arg2
bool SH_DisplayHealth[MAX_PLAYERS_ARRAY]; // arg3
bool SH_DisplayRage[MAX_PLAYERS_ARRAY]; // arg4
char SH_LungeReadyStr[MAX_CENTER_TEXT_LENGTH]; // arg5, shared
char SH_LungeNotReadyStr[MAX_CENTER_TEXT_LENGTH]; // arg6, shared
char SH_SlamReadyStr[MAX_CENTER_TEXT_LENGTH]; // arg7, shared
char SH_SlamNotReadyStr[MAX_CENTER_TEXT_LENGTH]; // arg8, shared
char SH_BerserkReadyStr[MAX_CENTER_TEXT_LENGTH]; // arg9, shared
char SH_BerserkNotReadyStr[MAX_CENTER_TEXT_LENGTH]; // arg10, shared
int SH_NormalColor[MAX_PLAYERS_ARRAY]; // arg11
int SH_AlertColor[MAX_PLAYERS_ARRAY]; // arg12
bool SH_AlertIfNotReady[MAX_PLAYERS_ARRAY]; // arg13
char SH_HealthStr[MAX_CENTER_TEXT_LENGTH]; // arg14, shared
char SH_RageStr[MAX_CENTER_TEXT_LENGTH]; // arg15, shared
bool SH_AlertOnLowHP[MAX_PLAYERS_ARRAY]; // arg16

/**
 * Saxton Advanced Options
 */
#define SAO_STRING "saxton_advanced_options"
bool SAO_CanUse[MAX_PLAYERS_ARRAY];
TFCond SAO_LungeConditions[MAX_PLAYERS_ARRAY][MAX_CONDITIONS]; // arg1
TFCond SAO_SlamConditions[MAX_PLAYERS_ARRAY][MAX_CONDITIONS]; // arg2
TFCond SAO_BerserkConditions[MAX_PLAYERS_ARRAY][MAX_CONDITIONS]; // arg3
// args 12-19 aren't initialized
#define MAX_KILL_ID_LENGTH 33

/**
 * METHODS REQUIRED BY ff2 subplugin
 */
void PrintRageWarning()
{
	PrintToServer("*********************************************************************");
	PrintToServer("*                             WARNING                               *");
	PrintToServer("*       DEBUG_FORCE_RAGE in improved_saxton.sp is set to true!      *");
	PrintToServer("*  Any admin can use the 'rage' command to use rages in this pack!  *");
	PrintToServer("*  This is only for test servers. Disable this on your live server. *");
	PrintToServer("*********************************************************************");
}
 
#define CMD_FORCE_RAGE "rage"
public void OnPluginStart2()
{
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	PrecacheSound(NOPE_AVI); // DO NOT DELETE IN FUTURE MOD PACKS
	
	SH_NormalHUDHandle = CreateHudSynchronizer(); // All you need to use ShowSyncHudText is to initialize this handle once in OnPluginStart()
	SH_AlertHUDHandle = CreateHudSynchronizer();  // Then use a unique handle for what hudtext you want sync'd to not overlap itself.
	
	if (DEBUG_FORCE_RAGE)
	{
		PrintRageWarning();
		RegAdminCmd(CMD_FORCE_RAGE, CmdForceRage, ADMFLAG_GENERIC);
	}
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// in case round end isn't executing...
	// I'm keeping this around. it's a paranoia add in case for example a Stripper-made arena map is receiving the wrong events
	// or something else I can't even foresee. considering I may take long breaks from maintaining this I'd hate
	// to have to address problems resulting from its removal. Its existence is safe, regardless.
	Saxton_Cleanup();
	
	RoundInProgress = true;
	
	// initialize variables
	PluginActiveThisRound = false;
	SL_ActiveThisRound = false;
	SS_ActiveThisRound = false;
	SB_ActiveThisRound = false;
	SH_ActiveThisRound = false;
	
	// initialize arrays
	for (int clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
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
		int bossIdx = IsLivingPlayer(clientIdx) ? FF2_GetBossIndex(clientIdx) : -1;
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
			bool pcSuccess = ReadFloatRange(bossIdx, SL_STRING, 14, SS_PitchConstraint[clientIdx]);
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
			
			// create animating prop
			PrecacheModel(SS_SAXTON_MODEL);
			SS_SaxtonEntRef[clientIdx] = CreateSaxtonProp();
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
			SB_TempClass[clientIdx] = view_as<TFClassType>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, SB_STRING, 13));
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
	
		for (int clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (SS_CanUse[clientIdx] || SB_CanUse[clientIdx] || SL_CanUse[clientIdx])
				SDKHook(clientIdx, SDKHook_PreThink, Saxton_PreThink);
				
			if (SB_ActiveThisRound && IsClientInGame(clientIdx))
				SDKHook(clientIdx, SDKHook_OnTakeDamage, Saxton_OnTakeDamage);
		}
	}
	
	CreateTimer(0.3, Timer_PostRoundStartInits, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_PostRoundStartInits(Handle timer)
{
	// hale suicided (or plugin not active)
	if (!RoundInProgress || !PluginActiveThisRound)
		return Plugin_Handled;
	
	// finish initialization of stuff
	for (int clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx))
			continue;

		int bossIdx = FF2_GetBossIndex(clientIdx);
		if (bossIdx < 0)
			continue;
		
		if (SB_CanUse[clientIdx])
			SB_SwapWeapon(clientIdx, false);

		// HUD hiding settings. done after delay because of possible load order issues with Dynamic Defaults
		if (SH_CanUse[clientIdx])
		{
			FF2_SetFF2flags(clientIdx, FF2_GetFF2flags(clientIdx)|FF2FLAG_HUDDISABLED);
			DD_SetForceHUDEnabled(clientIdx, true);
		}
	}

	return Plugin_Handled;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	RoundInProgress = false;
	Saxton_Cleanup();
}

public void Saxton_Cleanup()
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
	
		for (int clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsClientInGame(clientIdx))
			{
				SDKUnhook(clientIdx, SDKHook_OnTakeDamage, Saxton_OnTakeDamage);
				SDKUnhook(clientIdx, SDKHook_PreThink, Saxton_PreThink);
				
				// the below will leak across multiple rounds. at least on old versions of FF2.
				FF2_SetFF2flags(clientIdx, FF2_GetFF2flags(clientIdx)&~FF2FLAG_HUDDISABLED);

				if (IsLivingPlayer(clientIdx))
				{
					// one of the rages immobilizes the hale briefly. don't let them remain stuck
					SetEntityMoveType(clientIdx, MOVETYPE_WALK);
					
					// gravity changes leak across multiple rounds
					SetEntityGravity(clientIdx, 1.0);
					
					// remove megaheal, in case somehow in some configuration this doesn't reset on round change
					if(TF2_IsPlayerInCondition(clientIdx, TFCond_MegaHeal))
						TF2_RemoveCondition(clientIdx, TFCond_MegaHeal);
				}
			}
			
			if(IsValidEntity(SS_SaxtonEntRef[clientIdx]))
			{
				RemoveEntity(EntRefToEntIndex(SS_SaxtonEntRef[clientIdx]));
				SS_SaxtonEntRef[clientIdx] = INVALID_ENTITY;
			}
		}
	}
}

public Action FF2_OnAbility2(int bossIdx, const char[] plugin_name, const char[] ability_name, int status)
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
public Action CmdForceRage(int user, int argsInt)
{
	// get actual args
	char unparsedArgs[ARG_LENGTH];
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
int Saxton_GetKey(int bossIdx, const char[] abilityName, int argIdx)
{
	int keyId = FF2_GetAbilityArgument(bossIdx, this_plugin_name, abilityName, argIdx);
	if (keyId == SAXTON_KEY_RELOAD)
		return IN_RELOAD;
	else if (keyId == SAXTON_KEY_SPECIAL)
		return IN_ATTACK3;
	else if (keyId == SAXTON_KEY_ALT_FIRE)
		return IN_ATTACK2;
		
	PrintToServer("[improved_saxton] ERROR: Invalid key ID specified for %s. Ability has no key assigned and cannot be executed.", abilityName);
	return 0;
}

public void Saxton_PreThink(int clientIdx)
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

char Saxton_Sounds[MAX_RAGE_SOUNDS][MAX_SOUND_FILE_LENGTH];
void Saxton_ReadSounds(int bossIdx, const char[] abilityName, int argIdx)
{
	static char readStr[(MAX_SOUND_FILE_LENGTH + 1) * MAX_RAGE_SOUNDS];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, abilityName, argIdx, readStr, sizeof(readStr));
	ExplodeString(readStr, ";", Saxton_Sounds, MAX_RAGE_SOUNDS, MAX_SOUND_FILE_LENGTH);
	for (int i = 0; i < MAX_RAGE_SOUNDS; i++)
		if (strlen(Saxton_Sounds[i]) > 3)
			PrecacheSound(Saxton_Sounds[i]);
}

void Saxton_RandomSound()
{
	int count = 0;
	for (int i = 0; i < MAX_RAGE_SOUNDS; i++)
		if (strlen(Saxton_Sounds[i]) > 3)
			count++;
			
	if (count == 0)
		return;
		
	int rand = GetRandomInt(0, count-1);
	if (strlen(Saxton_Sounds[rand]) > 3)
	{
		EmitSoundToAll(Saxton_Sounds[rand]);
		EmitSoundToAll(Saxton_Sounds[rand]);
	}
}

public void Saxton_GetKillStringWithDefault(int bossIdx, const char[] abilityName, int argIdx, char[] killStr, int clientIdx, const char[] defaultStr)
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
bool Saxton_TempGoomba = false;
public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (IsLivingPlayer(attacker))
	{
		static char killWeapon[MAX_KILL_ID_LENGTH];
		static char killName[MAX_KILL_ID_LENGTH];
		bool override = false;
		
		int bossIdx = FF2_GetBossIndex(attacker);
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
			event.SetString("weapon", killWeapon); // train
			event.SetString("weapon_logclassname", killName);
		}
	}
	
	return Plugin_Continue;
}

public Action Saxton_OnTakeDamage(int victim, int& attacker, int& inflictor, 
							float& damage, int& damagetype, int& weapon,
							float damageForce[3], float damagePosition[3], int damagecustom)
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

public void Saxton_AddConditions(int clientIdx, const TFCond[] conditions)
{
	if (!SAO_CanUse[clientIdx])
		return;

	for (int i = 0; i < MAX_CONDITIONS; i++)
		if (conditions[i] > view_as<TFCond>(0))
			TF2_AddCondition(clientIdx, conditions[i], -1.0);
}

public void Saxton_RemoveConditions(int clientIdx, const TFCond[] conditions)
{
	if (!SAO_CanUse[clientIdx])
		return;

	for (int i = 0; i < MAX_CONDITIONS; i++)
		if (conditions[i] > view_as<TFCond>(0) && TF2_IsPlayerInCondition(clientIdx, conditions[i]))
			TF2_RemoveCondition(clientIdx, conditions[i]);
}

public Action OnStomp(int attacker, int victim, float& damageMultiplier, float& damageBonus, float& JumpPower)
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
public bool SL_RageAvailable(int clientIdx, float curTime, bool reportError)
{
	int bossIdx = FF2_GetBossIndex(clientIdx);
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
	if ((SL_CanUse[clientIdx] && SL_IsUsing[clientIdx]) || (SS_CanUse[clientIdx] && SS_IsUsing[clientIdx]) || (SB_CanUse[clientIdx] && SB_UsingUntil[clientIdx] != FAR_FUTURE))
		return false;
	
	// all conditions passed
	return true;
}

public void SL_Initiate(int clientIdx, float curTime)
{
	// remove rage
	int bossIdx = FF2_GetBossIndex(clientIdx);
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
	for (int victim = 1; victim < MAX_PLAYERS; victim++)
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
	static float angles[3];
	GetClientEyeAngles(clientIdx, angles);
	
	// added for 1.0.0: constrain pitch
	angles[0] = fmin(SS_PitchConstraint[clientIdx][1], fmax(SS_PitchConstraint[clientIdx][0], angles[0]));
	
	SL_InitialYaw[clientIdx] = angles[1];
	SL_InitialPitch[clientIdx] = angles[0];

	// push the hale
	static float velocity[3];
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

public void SL_OnPlayerRunCmd(int clientIdx, int buttons, float curTime)
{
	bool keyDown = (buttons & SL_DesiredKey[clientIdx]) != 0;
	if (keyDown && !SL_KeyDown[clientIdx] && SL_RageAvailable(clientIdx, curTime, true))
	{
		SL_Initiate(clientIdx, curTime);
	}
	
	SL_KeyDown[clientIdx] = keyDown;
}

// special line of sight check since displacements can easily screw up origin to origin checks
// there'll be some bullshit misses but this is one of those rare cases attacks going through walls would be too common
public bool SL_HasLineOfSight(float bossPos[3], float victimPos[3], float zOffset)
{
	static float tmpPos[3];
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

public void SL_HitSoundsAndEffects(int clientIdx, int victim, float victimPos[3])
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

public void SL_PreThink(int clientIdx)
{
	float curTime = GetEngineTime();
	
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
		static float angles[3];
		angles[0] = 0.0; // ignore pitch for now
		angles[1] = SL_InitialYaw[clientIdx];
		static float bossPos[3];
		GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", bossPos);
		static float hitPos[3];
		TR_TraceRayFilter(bossPos, angles, MASK_PLAYERSOLID, RayType_Infinite, TraceWallsOnly);
		TR_GetEndPosition(hitPos);
		float distance = GetVectorDistance(bossPos, hitPos);

		// constrain the distance of origin a little so it's not on top of a wall boundary,
		// and of course so it's not greater than the set limit
		if (distance >= SL_CollisionDistance[clientIdx])
			constrainDistance(bossPos, hitPos, distance, SL_CollisionDistance[clientIdx] - 0.1);
		else
			constrainDistance(bossPos, hitPos, distance, distance - 0.1);
			
		//PrintToServer("hitPos vs bossPos: %f,%f,%f vs %f,%f,%f     colrad=%f", hitPos[0], hitPos[1], hitPos[2], bossPos[0], bossPos[1], bossPos[2], SL_CollisionRadius[clientIdx]);

		// check collision every tick
		for (int victim = 1; victim < MAX_PLAYERS; victim++)
		{
			if (SL_AlreadyHit[victim] || !IsLivingPlayer(victim) || GetClientTeam(victim) == GetClientTeam(clientIdx))
				continue;

			// cylinder collision check
			static float victimPos[3];
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
			if (!CylinderCollision(hitPos, victimPos, SL_CollisionRadius[clientIdx], hitPos[2] - 103.0, hitPos[2] + SL_CollisionHeight[clientIdx]))
				continue;

			// so it's close enough. ensure we don't hit through a wall.
			if (SL_HasLineOfSight(hitPos, victimPos, 41.5))
			{
				SL_AlreadyHit[victim] = true;
				SL_HitSoundsAndEffects(clientIdx, victim, victimPos);

				// knockback first, this one takes the hale's velocity into account
				static float haleVelocity[3];
				GetEntPropVector(clientIdx, Prop_Data, "m_vecVelocity", haleVelocity);
				haleVelocity[2] = 0.0;
				static float velocity[3];
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
		if (SL_DestroyBuildings[clientIdx]) for (int pass = 0; pass <= 2; pass++)
		{
			static char classname[MAX_ENTITY_CLASSNAME_LENGTH];
			if (pass == 0) classname = "obj_sentrygun";
			else if (pass == 1) classname = "obj_dispenser";
			else if (pass == 2) classname = "obj_teleporter";

			int building = MaxClients + 1;
			while ((building = FindEntityByClassname(building, classname)) != -1)
			{
				if (GetEntProp(building, Prop_Send, "m_bCarried") || GetEntProp(building, Prop_Send, "m_bPlacing"))
					continue;

				static float buildingPos[3];
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
			static float velocity[3];
			GetEntPropVector(clientIdx, Prop_Data, "m_vecVelocity", velocity);
			float currentZ = velocity[2];
			velocity[2] = 0.0;
			if (getLinearVelocity(velocity) < 100.0) // close enough to stopping
			{
				static float pushVel[3];
				angles[0] = SL_InitialPitch[clientIdx];
				angles[1] = SL_InitialYaw[clientIdx];
				GetAngleVectors(angles, pushVel, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(pushVel, SL_Velocity[clientIdx]);
				
				// reint the x/y push but maintain existing Z, lest this rage never end
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
public void SS_SlamSound(int bossIdx, bool play)
{
	static char soundName[MAX_SOUND_FILE_LENGTH];
	ReadSound(bossIdx, SS_STRING, 15, soundName);
	if (play && strlen(soundName) > 3)
	{
		EmitSoundToAll(soundName);
		EmitSoundToAll(soundName);
	}
}

public float SS_CalculateDamage(int clientIdx, float distance)
{
	float damage;
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

public bool SS_RageAvailable(int clientIdx, float curTime, bool reportError)
{
	int bossIdx = FF2_GetBossIndex(clientIdx);
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
	if ((SS_CanUse[clientIdx] && SS_IsUsing[clientIdx]) || (SL_CanUse[clientIdx] && SL_IsUsing[clientIdx]) || (SB_CanUse[clientIdx] && SB_UsingUntil[clientIdx] != FAR_FUTURE))
		return false;
	
	// all conditions passed
	return true;
}

void SS_CreateEarthquake(int clientIdx)
{
	float amplitude = 16.0;
	float radius = SS_Radius[clientIdx];
	float duration = 5.0;
	float frequency = 255.0;

	int earthquake = CreateEntityByName("env_shake");
	if (IsValidEntity(earthquake))
	{
		static float halePos[3];
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
		CreateTimer(duration + 0.1, Timer_RemoveEntity, EntIndexToEntRef(earthquake), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void SS_Initiate(int clientIdx, float curTime)
{
	// remove rage
	int bossIdx = FF2_GetBossIndex(clientIdx);
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
	TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0})); // stop velocity
	
	SetEntityRenderMode(clientIdx, RENDER_TRANSCOLOR);
	SetEntityRenderColor(clientIdx, 255, 255, 255, 0);

	// set immobile and immovable
	SetEntityMoveType(clientIdx, MOVETYPE_NONE);
	TF2_AddCondition(clientIdx, TFCond_MegaHeal, -1.0);
	Saxton_AddConditions(clientIdx, SAO_SlamConditions[clientIdx]);

	// force third person during the rage
	SS_WasFirstPerson[clientIdx] = (GetEntProp(clientIdx, Prop_Send, "m_nForceTauntCam") == 0);
	SetVariantInt(1);
	AcceptEntityInput(clientIdx, "SetForcedTauntCam");

	// force the taunt. if the prop is good, this'll work.
	if(IsValidEntity(SS_SaxtonEntRef[clientIdx]))
	{
		SetVariantString("taunt_party_trick");
		AcceptEntityInput(EntRefToEntIndex(SS_SaxtonEntRef[clientIdx]), "SetAnimation");
	}

	// disable dynamic abilities during the rage.
	DD_SetDisabled(clientIdx, true, true, true, true);
}

public void SS_OnPlayerRunCmd(int clientIdx, int buttons, float curTime)
{
	bool keyDown = (buttons & SS_DesiredKey[clientIdx]) != 0;
	if (keyDown && !SS_KeyDown[clientIdx] && SS_RageAvailable(clientIdx, curTime, true))
		SS_Initiate(clientIdx, curTime);
	
	SS_KeyDown[clientIdx] = keyDown;
}

public void SS_PreThink(int clientIdx)
{
	float curTime = GetEngineTime();
	
	if (SS_IsUsing[clientIdx])
	{
		if (curTime >= SS_TauntingUntil[clientIdx])
		{
			SS_TauntingUntil[clientIdx] = FAR_FUTURE;
			SetEntityMoveType(clientIdx, MOVETYPE_WALK);
			TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, SS_JUMP_FORCE})); // simulate a high jump
		}
		
		if (SS_PreparingUntil[clientIdx] != FAR_FUTURE && SS_TauntingUntil[clientIdx] == FAR_FUTURE)
		{
			if (curTime >= SS_PreparingUntil[clientIdx])
			{
				SS_PreparingUntil[clientIdx] = FAR_FUTURE;
				TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, -100.0})); // give them a head start downward
				SetEntityGravity(clientIdx, SS_GravitySetting[clientIdx]); // set gravity now
			}
			else
			{
				// if player hits a ceiling, suspend them in midair until it's time to fall
				static float velocity[3];
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
				static float halePos[3];
				GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", halePos);
				
				// either use override particle or default
				static char effect1[MAX_EFFECT_NAME_LENGTH];
				static char effect2[MAX_EFFECT_NAME_LENGTH];
				bool override = false;
				if (SAO_CanUse[clientIdx])
				{
					int bossIdx = FF2_GetBossIndex(clientIdx);
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
				
				for (int victim = 1; victim < MAX_PLAYERS; victim++)
				{
					if (!IsLivingPlayer(victim) || GetClientTeam(victim) == GetClientTeam(clientIdx))
						continue;
					else if (IsTreadingWater(victim) || IsFullyInWater(victim) || CheckGroundClearance(victim, 80.0, true))
						continue;
						
					static float victimPos[3];
					GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
					float distance = GetVectorDistance(halePos, victimPos);
					if (distance >= SS_Radius[clientIdx])
						continue;
					
					// knockback first
					static float angles[3];
					static float velocity[3];
					GetVectorAnglesTwoPoints(halePos, victimPos, angles);
					GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
					ScaleVector(velocity, SS_Knockback[clientIdx]);
					if ((GetEntityFlags(victim) & FL_ONGROUND) != 0 && velocity[2] < 300.0) // minimum Z, gives victims lift
						velocity[2] = 300.0;
					TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, velocity);
						
					// apply the damage
					if (SS_MaxDamage[clientIdx] > 0.0)
					{
						float damage = SS_CalculateDamage(clientIdx, distance);
						if (TF2_GetPlayerClass(victim) == TFClass_Spy || float(GetEntProp(victim, Prop_Send, "m_iHealth")) * 0.66 >= damage)
							SDKHooks_TakeDamage(victim, clientIdx, clientIdx, damage, DMG_PREVENT_PHYSICS_FORCE, -1);
						else
							FullyHookedDamage(victim, clientIdx, clientIdx, fixDamageForFF2(damage), DMG_PREVENT_PHYSICS_FORCE, -1);
					}
				}
				
				// damage nearby buildings
				if (SS_MaxDamage[clientIdx] > 0.0 && SS_BuildingDamageFactor[clientIdx] > 0.0)
				{
					int building = MaxClients + 1;
					while ((building = FindEntityByClassname(building, "obj_*")) != -1)
					{
						if (GetEntProp(building, Prop_Send, "m_bCarried") || GetEntProp(building, Prop_Send, "m_bPlacing"))
							continue;
					
						static float buildingPos[3];
						GetEntPropVector(building, Prop_Send, "m_vecOrigin", buildingPos);
						float distance = GetVectorDistance(buildingPos, halePos);
						if (distance >= SS_Radius[clientIdx])
							continue;
							
						float damage = SS_CalculateDamage(clientIdx, distance);
						SDKHooks_TakeDamage(building, clientIdx, clientIdx, damage * SS_BuildingDamageFactor[clientIdx], DMG_GENERIC, -1);
					}
				}
				
				int bossIdx = FF2_GetBossIndex(clientIdx);
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
				
				SetEntityRenderMode(clientIdx, RENDER_TRANSCOLOR);
				SetEntityRenderColor(clientIdx, 255, 255, 255, 255);

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
		
		static float SS_SaxPos[3], SS_SaxAng[3];
		GetClientAbsOrigin(clientIdx, SS_SaxPos);
		GetClientEyeAngles(clientIdx, SS_SaxAng);
		
		SS_SaxAng[0] = 0.0;
		SS_SaxAng[2] = 0.0;
		if(IsValidEntity(SS_SaxtonEntRef[clientIdx]))
			TeleportEntity(EntRefToEntIndex(SS_SaxtonEntRef[clientIdx]), SS_SaxPos, SS_SaxAng, NULL_VECTOR);
	}
	else
	{
		if(IsValidEntity(SS_SaxtonEntRef[clientIdx]))
			TeleportEntity(EntRefToEntIndex(SS_SaxtonEntRef[clientIdx]), OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR);
	}
}

/**
 * Saxton Berserker
 */
public void SB_SwapWeapon(int clientIdx, bool isRage)
{
	int bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return;
		
	if (!isRage)
	{
		for (int i = 0; i < 2; i++)
		{
			if (SB_FlameEntRefs[clientIdx][i] != INVALID_ENTREF)
			{
				Timer_RemoveEntity(INVALID_HANDLE, SB_FlameEntRefs[clientIdx][i]);
				SB_FlameEntRefs[clientIdx][i] = INVALID_ENTREF;
			}
		}
	}
		
	static char weaponName[MAX_WEAPON_NAME_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SB_STRING, (isRage ? 6 : 2), weaponName, MAX_WEAPON_NAME_LENGTH);
	int weaponIdx = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SB_STRING, (isRage ? 7 : 3));
	static char weaponArgs[MAX_WEAPON_ARG_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SB_STRING, (isRage ? 8 : 4), weaponArgs, MAX_WEAPON_ARG_LENGTH);
	bool weaponVisibility = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SB_STRING, (isRage ? 9 : 5)) != 0;
	int slot = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SB_STRING, 10);
	
	TF2_RemoveWeaponSlot(clientIdx, slot);
	int weapon = SpawnWeapon(clientIdx, weaponName, weaponIdx, 101, 5, weaponArgs, weaponVisibility);
	if (IsValidEntity(weapon))
		SetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon", weapon);
		
	SB_IsFists[clientIdx] = strcmp(weaponName, "tf_weapon_fists") == 0;
	if (SB_IsFists[clientIdx] && isRage && (SB_Flags[clientIdx] & SB_FLAG_FLAMING_FISTS) != 0)
	{
		static char attachmentStr[(MAX_ATTACHMENT_NAME_LENGTH + 1) * 2];
		FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SB_STRING, 12, attachmentStr, sizeof(attachmentStr));
		if (!IsEmptyString(attachmentStr))
		{
			static char attachmentStrs[2][MAX_ATTACHMENT_NAME_LENGTH];
			ExplodeString(attachmentStr, ";", attachmentStrs, 2, MAX_ATTACHMENT_NAME_LENGTH);
			for (int i = 0; i < 2; i++)
			{
				if (!IsEmptyString(attachmentStrs[i]))
				{
					int particle = AttachParticleToAttachment(clientIdx, "superrare_burning1", attachmentStrs[i]);
					if (IsValidEntity(particle))
						SB_FlameEntRefs[clientIdx][i] = EntIndexToEntRef(particle);
				}
			}
		}
	}
}
 
public void SB_PreThink(int clientIdx)
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
		int bossIdx = FF2_GetBossIndex(clientIdx);
		if (bossIdx < 0)
			return;
			
		FF2_SetBossCharge(bossIdx, 0, 100.0);
	}
}

public Action SB_OnPlayerRunCmd(int clientIdx, int& buttons)
{
	if (SB_UsingUntil[clientIdx] == FAR_FUTURE || (SB_Flags[clientIdx] & SB_FLAG_AUTO_FIRE) == 0)
		return Plugin_Continue;
	
	int weapon = GetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(weapon))
		return Plugin_Continue;
		
	float nextAttack = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");
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

public void Rage_SaxtonBerserk(int clientIdx)
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
		if (SB_TempClass[clientIdx] > TFClass_Unknown && SB_TempClass[clientIdx] != SB_OriginalClass[clientIdx])
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
public void SH_PreThink(int clientIdx)
{
	if (GetClientButtons(clientIdx) & IN_SCORE)
		return; // Don't show hud when player is viewing scoreboard, as it will only flash violently

	float curTime = GetEngineTime();
	
	if (curTime >= SH_NextHUDAt[clientIdx])
	{
		SH_NextHUDAt[clientIdx] = curTime + SH_HUDInterval[clientIdx];
		int bossIdx = FF2_GetBossIndex(clientIdx);
		if (bossIdx < 0)
			return;
		
		// format health str
		static char healthStr[80];
		healthStr = "";
#if defined VSP_VERSION
		int hp = FF2_GetBossMax(bossIdx);
#else
		int hp = GetEntProp(clientIdx, Prop_Send, "m_iHealth"); // see my rant about this at the bottom of this file.
#endif
		if (abs(hp - SH_LastHPValue[clientIdx]) <= 5) // this way it'll be wrong, but relatively stable in appearance
			hp = SH_LastHPValue[clientIdx];
		else
			SH_LastHPValue[clientIdx] = hp;
		int maxHP = FF2_GetBossMaxHealth(bossIdx);
		if (SH_DisplayHealth[clientIdx])
			Format(healthStr, sizeof(healthStr), SH_HealthStr, hp, maxHP);
		bool healthIsAlert = (SH_AlertOnLowHP[clientIdx] ? (hp * 3 <= maxHP) : false);

		// format rage str
		static char rageStr[80];
		rageStr = "";
		if (SH_DisplayRage[clientIdx])
			FormatEx(rageStr, sizeof(rageStr), SH_RageStr, FF2_GetBossCharge(bossIdx, 0));
			
		// format ability strs
		static char lungeStr[MAX_CENTER_TEXT_LENGTH];
		bool lungeAvailable = (SL_CanUse[clientIdx] && SL_RageAvailable(clientIdx, curTime, false));
		if (!SL_CanUse[clientIdx])
			lungeStr = "";
		else
			FormatEx(lungeStr, sizeof(lungeStr), (lungeAvailable ? SH_LungeReadyStr : SH_LungeNotReadyStr), SL_RageCost[clientIdx]);
		bool lungeIsAlert = (lungeAvailable && !SH_AlertIfNotReady[clientIdx]) || (!lungeAvailable && SH_AlertIfNotReady[clientIdx]);

		static char slamStr[MAX_CENTER_TEXT_LENGTH];
		bool slamAvailable = (SS_CanUse[clientIdx] && SS_RageAvailable(clientIdx, curTime, false));
		if (!SS_CanUse[clientIdx])
			slamStr = "";
		else
			FormatEx(slamStr, sizeof(slamStr), (slamAvailable ? SH_SlamReadyStr : SH_SlamNotReadyStr), SS_RageCost[clientIdx]);
		bool slamIsAlert = (slamAvailable && !SH_AlertIfNotReady[clientIdx]) || (!slamAvailable && SH_AlertIfNotReady[clientIdx]);

		static char berserkStr[MAX_CENTER_TEXT_LENGTH];
		bool berserkAvailable = FF2_GetBossCharge(bossIdx, 0) >= 100.0;
		if (!SB_CanUse[clientIdx])
			berserkStr = "";
		else
			FormatEx(berserkStr, sizeof(berserkStr), (berserkAvailable ? SH_BerserkReadyStr : SH_BerserkNotReadyStr), 100.0); // redundant percent in case someone slips up
		bool berserkIsAlert = (berserkAvailable && !SH_AlertIfNotReady[clientIdx]) || (!berserkAvailable && SH_AlertIfNotReady[clientIdx]);

		// normal HUD
		SetHudTextParams(-1.0, SH_HudY[clientIdx], SH_HUDInterval[clientIdx] + 0.05, GetR(SH_NormalColor[clientIdx]), GetG(SH_NormalColor[clientIdx]), GetB(SH_NormalColor[clientIdx]), 192);
		ShowSyncHudText(clientIdx, SH_NormalHUDHandle, SH_HudFormat[clientIdx], (!healthIsAlert ? healthStr : ""), rageStr, (!lungeIsAlert ? lungeStr : ""), (!slamIsAlert ? slamStr : ""), (!berserkIsAlert ? berserkStr : ""));
		
		// alert HUD
		SetHudTextParams(-1.0, SH_HudY[clientIdx], SH_HUDInterval[clientIdx] + 0.05, GetR(SH_AlertColor[clientIdx]), GetG(SH_AlertColor[clientIdx]), GetB(SH_AlertColor[clientIdx]), 192);
		ShowSyncHudText(clientIdx, SH_AlertHUDHandle, SH_HudFormat[clientIdx], (healthIsAlert ? healthStr : ""), "", (lungeIsAlert ? lungeStr : ""), (slamIsAlert ? slamStr : ""), (berserkIsAlert ? berserkStr : ""));
	}
}

/**
 * OnPlayerRunCmd/OnGameFrame
 */
public void OnGameFrame()
{
	if (!PluginActiveThisRound || !RoundInProgress)
		return;
	
	float curTime = GetEngineTime();
	
	// this is best done on the game frame since it'll be either before or after movement checks are made
	// reducing the likelihood of this failing
	if (SL_ActiveThisRound)
	{
		if (curTime >= SL_TrySolidifyAt)
		{
			static float bossPos[3];
			GetEntPropVector(SL_TrySolidifyBossClientIdx, Prop_Send, "m_vecOrigin", bossPos);
			static float mins[3];
			static float maxs[3];
			mins[0] = bossPos[0] - 50.0;
			mins[1] = bossPos[1] - 50.0;
			mins[2] = bossPos[2] - 85.0;
			maxs[0] = bossPos[0] + 50.0;
			maxs[1] = bossPos[1] + 50.0;
			maxs[2] = bossPos[2] + 85.0;
		
			bool fail = false;
			for (int victim = 1; victim < MAX_PLAYERS; victim++)
			{
				if (!IsLivingPlayer(victim) || GetClientTeam(victim) == GetClientTeam(SL_TrySolidifyBossClientIdx))
					continue;
					
				static float victimPos[3];
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
				for (int victim = 1; victim < MAX_PLAYERS; victim++)
					if (IsLivingPlayer(victim))
						SetEntProp(victim, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
			}
		}
	}
	
	// also need the game frame for removing excess fire
	if (SB_ActiveThisRound)
	{
		for (int victim = 1; victim < MAX_PLAYERS; victim++)
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
 
public Action OnPlayerRunCmd(int clientIdx, int& buttons, int& impulse, 
							float vel[3], float angles[3], int& weapon, 
							int &subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!PluginActiveThisRound || !RoundInProgress)
		return Plugin_Continue;
	else if (!IsLivingPlayer(clientIdx))
		return Plugin_Continue;
		
	Action ret = Plugin_Continue;
		
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
stock void PlaySoundLocal(int clientIdx, char[] soundPath, bool followPlayer = true, int stack = 1)
{
	// play a speech sound that travels normally, local from the player.
	static float playerPos[3];
	GetClientEyePosition(clientIdx, playerPos);
	//PrintToServer("[improved_saxton] eye pos=%f,%f,%f     sound=%s", playerPos[0], playerPos[1], playerPos[2], soundPath);
	for (int i = 0; i < stack; i++)
		EmitAmbientSound(soundPath, playerPos, followPlayer ? clientIdx : SOUND_FROM_WORLD);
}

stock int ParticleEffectAt(float position[3], char[] effectName, float duration = 0.1)
{
	if (strlen(effectName) < 3)
		return -1; // nothing to display
		
	int particle = CreateEntityByName("info_particle_system");
	if (particle != -1)
	{
		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "effect_name", effectName);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		if (duration > 0.0)
			CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	}
	return particle;
}

stock int AttachParticle(int entity, const char[] particleType, float offset=0.0, bool attach=true)
{
	int particle = CreateEntityByName("info_particle_system");
	
	if (!IsValidEntity(particle))
		return -1;

	static char targetName[128];
	static float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[2] += offset;
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	FormatEx(targetName, sizeof(targetName), "target%i", entity);
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
stock int AttachParticleToAttachment(int entity, const char[] particleType, const char[] attachmentPoint) // m_vecAbsOrigin. you're welcome.
{
	int particle = CreateEntityByName("info_particle_system");
	
	if (!IsValidEntity(particle))
		return -1;

	static char targetName[128];
	static float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	FormatEx(targetName, sizeof(targetName), "target%i", entity);
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

public Action Timer_RemoveEntity(Handle timer, any entid)
{
	int entity = EntRefToEntIndex(entid);
	if (IsValidEntity(entity))
		RemoveEntity(entity);
}

stock bool IsLivingPlayer(int clientIdx)
{
	if (clientIdx <= 0 || clientIdx >= MAX_PLAYERS)
		return false;
		
	return IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx);
}

stock int SpawnWeapon(int client, char[] name, int index, int level, int quality, char[] attribute, bool visible = true)
{
	Handle weapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, quality);
	char attributes[32][32];
	int count = ExplodeString(attribute, ";", attributes, 32, 32);
	if(count%2!=0)
	{
		count--;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		int i2 = 0;
		for(int i = 0; i < count; i += 2)
		{
			int attrib = StringToInt(attributes[i]);
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

	int entity = TF2Items_GiveNamedItem(client, weapon);
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

stock bool IsPlayerInRange(int player, float position[3], float maxDistance)
{
	maxDistance *= maxDistance;
	
	static float playerPos[3];
	GetEntPropVector(player, Prop_Data, "m_vecOrigin", playerPos);
	return GetVectorDistance(position, playerPos, true) <= maxDistance;
}

stock bool CheckLineOfSight(float position[3], int targetEntity, float zOffset)
{
	static float targetPos[3];
	GetEntPropVector(targetEntity, Prop_Send, "m_vecOrigin", targetPos);
	targetPos[2] += zOffset;
	static float angles[3];
	GetVectorAnglesTwoPoints(position, targetPos, angles);
	
	Handle trace = TR_TraceRayFilterEx(position, angles, (CONTENTS_SOLID|CONTENTS_WINDOW|CONTENTS_GRATE), RayType_Infinite, TraceWallsOnly);
	static float endPos[3];
	TR_GetEndPosition(endPos, trace);
	CloseHandle(trace);
	
	return GetVectorDistance(position, targetPos, true) <= GetVectorDistance(position, endPos, true);
}
	
stock void ParseFloatRange(char[] rangeStr, float& min, float& max)
{
	char rangeStrs[2][32];
	ExplodeString(rangeStr, ";", rangeStrs, 2, 32);
	min = StringToFloat(rangeStrs[0]);
	max = StringToFloat(rangeStrs[1]);
}

stock void ParseHull(char[] hullStr, float hull[2][3])
{
	char hullStrs[2][MAX_HULL_STRING_LENGTH / 2];
	char vectorStrs[3][MAX_HULL_STRING_LENGTH / 6];
	ExplodeString(hullStr, " ", hullStrs, 2, MAX_HULL_STRING_LENGTH / 2);
	for (int i = 0; i < 2; i++)
	{
		ExplodeString(hullStrs[i], ",", vectorStrs, 3, MAX_HULL_STRING_LENGTH / 6);
		hull[i][0] = StringToFloat(vectorStrs[0]);
		hull[i][1] = StringToFloat(vectorStrs[1]);
		hull[i][2] = StringToFloat(vectorStrs[2]);
	}
}

stock bool ReadFloatRange(int bossIdx, const char[] ability_name, int argInt, float range[2])
{
	static char rangeStr[MAX_RANGE_STRING_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, rangeStr, MAX_RANGE_STRING_LENGTH);
	ParseFloatRange(rangeStr, range[0], range[1]); // do this even if the length is invalid, for stock backwards comatibility
	return (strlen(rangeStr) >= 3); // minimum length for valid range is 3
}

stock void ReadSound(int bossIdx, const char[] ability_name, int argInt, char[] soundFile)
{
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, soundFile, MAX_SOUND_FILE_LENGTH);
	if (strlen(soundFile) > 3)
		PrecacheSound(soundFile);
}

stock void ReadModel(int bossIdx, const char[] ability_name, int argInt, char[] modelFile)
{
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, modelFile, MAX_MODEL_FILE_LENGTH);
	if (strlen(modelFile) > 3)
		PrecacheModel(modelFile);
}

stock void ReadMaterial(int bossIdx, const char[] ability_name, int argInt, char[] modelFile)
{
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, modelFile, MAX_MATERIAL_FILE_LENGTH);
	if (strlen(modelFile) > 3)
		PrecacheModel(modelFile);
}

stock int ReadMaterialToInt(int bossIdx, const char[] ability_name, int argInt)
{
	static char modelFile[MAX_MATERIAL_FILE_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, modelFile, MAX_MATERIAL_FILE_LENGTH);
	if (strlen(modelFile) > 3)
		return PrecacheModel(modelFile);
	return -1;
}

stock void ReadCenterText(int bossIdx, const char[] ability_name, int argInt, char[] centerText)
{
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, centerText, MAX_CENTER_TEXT_LENGTH);
	ReplaceString(centerText, MAX_CENTER_TEXT_LENGTH, "\\n", "\n");
}

stock void ReadConditions(int bossIdx, const char[] ability_name, int argInt, TFCond[] conditions)
{
	static char conditionStr[MAX_CONDITIONS * 4];
	static char conditionStrs[MAX_CONDITIONS][4];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, conditionStr, sizeof(conditionStr));
	int count = ExplodeString(conditionStr, ";", conditionStrs, MAX_CONDITIONS, 4);
	for (int i = 0; i < MAX_CONDITIONS; i++)
	{
		if (i >= count)
			conditions[i] = view_as<TFCond>(0);
		else
			conditions[i] = view_as<TFCond>(StringToInt(conditionStrs[i]));
	}
}

public bool TraceWallsOnly(int entity, int contentsMask)
{
	return false;
}

// really wish that the original GetVectorAngles() worked this way.
stock float GetVectorAnglesTwoPoints(const float startPos[3], const float endPos[3], float angles[3])
{
	static float tmpVec[3];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}

stock float GetVelocityFromPointsAndInterval(float pointA[3], float pointB[3], float deltaTime)
{
	if (deltaTime <= 0.0)
		return 0.0;

	return GetVectorDistance(pointA, pointB) * (1.0 / deltaTime);
}

stock float fixDamageForFF2(float damage)
{
	if (damage <= 160.0)
		return damage / 3.0;
	return damage;
}

stock void QuietDamage(int victim, int inflictor, int attacker, float damage, int damageType=DMG_GENERIC, int weapon=-1)
{
	int takedamage = GetEntProp(victim, Prop_Data, "m_takedamage");
	SetEntProp(victim, Prop_Data, "m_takedamage", 0);
	SDKHooks_TakeDamage(victim, inflictor, attacker, damage, damageType, weapon);
	SetEntProp(victim, Prop_Data, "m_takedamage", takedamage);
	SDKHooks_TakeDamage(victim, victim, victim, damage, damageType, weapon);
}

stock void FullyHookedDamage(int victim, int inflictor, int attacker, float damage, int damageType=DMG_GENERIC, int weapon=-1, float attackPos[3] = NULL_VECTOR)
{
	static char dmgStr[16];
	IntToString(RoundFloat(damage), dmgStr, sizeof(dmgStr));

	// took this from war3...I hope it doesn't double damage like I've heard old versions do
	int pointHurt = CreateEntityByName("point_hurt");
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
			static float attackerOrigin[3];
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", attackerOrigin);
			TeleportEntity(pointHurt, attackerOrigin, NULL_VECTOR, NULL_VECTOR);
		}
		AcceptEntityInput(pointHurt, "Hurt", attacker);
		DispatchKeyValue(pointHurt, "classname", "point_hurt");
		DispatchKeyValue(victim, "targetname", "noonespecial");
		Timer_RemoveEntity(INVALID_HANDLE, EntIndexToEntRef(pointHurt));
	}
}

// this version ignores obstacles
stock void PseudoAmbientSound(int clientIdx, char[] soundPath, int count=1, float radius=1000.0, bool skipSelf=false, bool skipDead=false, float volumeFactor=1.0)
{
	static float emitterPos[3];
	static float listenerPos[3];
	if (!IsLivingPlayer(clientIdx)) // updated 2015-01-16 to allow non-players...finally.
		GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", emitterPos);
	else
		GetClientEyePosition(clientIdx, emitterPos);
	for (int listener = 1; listener < MAX_PLAYERS; listener++)
	{
		if (!IsClientInGame(listener))
			continue;
		else if (skipSelf && listener == clientIdx)
			continue;
		else if (skipDead && !IsLivingPlayer(listener))
			continue;
			
		GetClientEyePosition(listener, listenerPos);
		float distance = GetVectorDistance(emitterPos, listenerPos);
		if (distance >= radius)
			continue;
		
		float volume = (radius - distance) / radius;
		if (volume <= 0.0)
			continue;
		else if (volume > 1.0)
		{
			PrintToServer("[improved_saxton] How the hell is volume greater than 1.0?");
			volume = 1.0;
		}
		
		for (int i = 0; i < count; i++)
			EmitSoundToClient(listener, soundPath, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, volume);
	}
}

stock int abs(int x)
{
	return x < 0 ? -x : x;
}

stock float fmin(float n1, float n2)
{
	return n1 < n2 ? n1 : n2;
}

stock int max(int n1, int n2)
{
	return n1 > n2 ? n1 : n2;
}

stock float fmax(float n1, float n2)
{
	return n1 > n2 ? n1 : n2;
}

stock int ReadHexOrDecInt(char[] hexOrDecString)
{
	if (StrContains(hexOrDecString, "0x") == 0)
	{
		int result = 0;
		for (int i = 2; i < 10 && hexOrDecString[i] != 0; i++)
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

stock int ReadHexOrDecString(int bossIdx, const char[] ability_name, int argIdx)
{
	static char hexOrDecString[HEX_OR_DEC_STRING_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argIdx, hexOrDecString, HEX_OR_DEC_STRING_LENGTH);
	return ReadHexOrDecInt(hexOrDecString);
}

stock bool CylinderCollision(float cylinderOrigin[3], float colliderOrigin[3], float maxDistance, float zMin, float zMax)
{
	if (colliderOrigin[2] < zMin || colliderOrigin[2] > zMax)
		return false;

	static float tmpVec1[3];
	tmpVec1[0] = cylinderOrigin[0];
	tmpVec1[1] = cylinderOrigin[1];
	tmpVec1[2] = 0.0;
	static float tmpVec2[3];
	tmpVec2[0] = colliderOrigin[0];
	tmpVec2[1] = colliderOrigin[1];
	tmpVec2[2] = 0.0;
	
	return GetVectorDistance(tmpVec1, tmpVec2, true) <= maxDistance * maxDistance;
}

stock float getLinearVelocity(float vecVelocity[3])
{
	return SquareRoot((vecVelocity[0] * vecVelocity[0]) + (vecVelocity[1] * vecVelocity[1]) + (vecVelocity[2] * vecVelocity[2]));
}

stock void constrainDistance(const float[] startPoint, float[] endPoint, float distance, float maxDistance)
{
	if (distance <= maxDistance)
		return; // nothing to do
		
	float constrainFactor = maxDistance / distance;
	endPoint[0] = ((endPoint[0] - startPoint[0]) * constrainFactor) + startPoint[0];
	endPoint[1] = ((endPoint[1] - startPoint[1]) * constrainFactor) + startPoint[1];
	endPoint[2] = ((endPoint[2] - startPoint[2]) * constrainFactor) + startPoint[2];
}

stock int GetA(int c) { return abs(c>>24); }
stock int GetR(int c) { return abs((c>>16)&0xff); }
stock int GetG(int c) { return abs((c>>8 )&0xff); }
stock int GetB(int c) { return abs((c    )&0xff); }

stock void Nope(int clientIdx)
{
	EmitSoundToClient(clientIdx, NOPE_AVI);
}

// stole this stock from KissLick. it's a good stock!
stock void DispatchKeyValueFormat(int entity, const char[] keyName, const char[] format, any ...)
{
	static char value[256];
	VFormat(value, sizeof(value), format, 4);

	DispatchKeyValue(entity, keyName, value);
} 

stock bool CheckGroundClearance(int clientIdx, float minClearance, bool failInWater)
{
	// standing? automatic fail.
	if (GetEntityFlags(clientIdx) & FL_ONGROUND)
		return false;
	else if (failInWater && (GetEntityFlags(clientIdx) & (FL_SWIM | FL_INWATER)))
		return false;
		
	// need to do a trace
	static float origin[3];
	GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", origin);
	
	Handle trace = TR_TraceRayFilterEx(origin, view_as<float>({90.0,0.0,0.0}), (CONTENTS_SOLID | CONTENTS_WINDOW | CONTENTS_GRATE), RayType_Infinite, TraceWallsOnly);
	static float endPos[3];
	TR_GetEndPosition(endPos, trace);
	CloseHandle(trace);
	
	// only Z should change, so this is easy.
	return origin[2] - endPos[2] >= minClearance;
}

// need to distinguish being fully in water and not, which is a little more complicated than it should be
stock bool IsFullyInWater(int clientIdx)
{
	int flags = GetEntityFlags(clientIdx);
	if ((flags & (FL_SWIM | FL_INWATER)) == 0)
		return false;

	int waterLevel = GetEntProp(clientIdx, Prop_Send, "m_nWaterLevel");
	if (waterLevel <= 1)
		return false;
		
	return true;
}

stock bool IsTreadingWater(int clientIdx)
{
	return (GetEntityFlags(clientIdx) & FL_ONGROUND) == 0 && GetEntProp(clientIdx, Prop_Send, "m_nWaterLevel") == 1;
}

stock int CreateSaxtonProp()
{
	int iSaxton = CreateEntityByName("prop_dynamic");
	if(IsValidEntity(iSaxton))
	{
		DispatchKeyValue(iSaxton, "model", SS_SAXTON_MODEL);
		
		DispatchSpawn(iSaxton);
		
		TeleportEntity(iSaxton, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR);
		
		SetVariantString("stand_MELEE");
		AcceptEntityInput(iSaxton, "SetDefaultAnimation");
		SetVariantString("stand_MELEE");
		AcceptEntityInput(iSaxton, "SetAnimation");
		
		return EntIndexToEntRef(iSaxton);
	}
	return INVALID_ENT_REFERENCE;
}

