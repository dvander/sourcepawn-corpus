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
#tryinclude <freak_fortress_2_extras>
#include <tf2attributes>
#include <ff2_dynamic_defaults>
#include <ff2_ams>
#undef REQUIRE_PLUGIN
#tryinclude <goomba>
#define REQUIRE_PLUGIN

/**
 * Third pack of public rages primarily for Epic Scout
 *
 * Credits:
 * - Rages designed and coded by sarysa
 * - Some stocks from FF2 and Friagram
 * - Credit to Friagram for Epic Scout's razorback body group trick. Which ultimately Valve blocked anyway.
 *           One day I'll learn to give up on things like bodygroups.
 * - SHADoW helped with testing and snippets.
 * - Spawn Ragdoll code by bl4nk
 * - Mecha the Slag for the replay stuff
 * - Inspired by Rise of the Epic Scout by Crash Maul
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
#define MAX_BODY_GROUP_LENGTH 48

// common array limits
#define MAX_CONDITIONS 10 // TF2 conditions (bleed, dazed, etc.)

#define MAX_PLAYERS_ARRAY 36
#define MAX_PLAYERS (MAX_PLAYERS_ARRAY < (MaxClients + 1) ? MAX_PLAYERS_ARRAY : (MaxClients + 1))

new bool:NULL_BLACKLIST[MAX_PLAYERS_ARRAY];

new MercTeam = _:TFTeam_Red;
new BossTeam = _:TFTeam_Blue;

new RoundInProgress = false;

public Plugin:myinfo = {
	name = "Freak Fortress 2: sarysa's public mods, third pack",
	author = "sarysa",
	version = "1.0.2 BBG",
}

#define FAR_FUTURE 100000000.0
#define COND_JARATE_WATER 86

// taken from 1st set abilities
new Handle:cvarTimeScale = INVALID_HANDLE;
new Handle:cvarCheats = INVALID_HANDLE;

/**
 * Ability Management System -- This one is a bit of a doozy, since it uses callbacks.
 *
 * It's basically a port of the spell system I use for Starlight Glimmer on VSP.
 * With some improvements.
 */
#define AMS_STRING "ability_management_system"
#define AMS_MAX_PREFIX_SIZE 5 // NOTE: this needs to be included in the .inc
#define AMS_PLUGIN_NAME_LENGTH 33 // this also needs to be included in the .inc
#define AMS_HUD_INTERVAL 0.2
#define AMS_MAX_SPELLS 10
new Handle:AMS_HUDHandle = INVALID_HANDLE;
new Handle:AMS_HUDReplaceHandle = INVALID_HANDLE;
new bool:AMS_ActiveThisRound;
new bool:AMS_CanUse[MAX_PLAYERS_ARRAY];
new AMS_NumSpells[MAX_PLAYERS_ARRAY]; // number of spells currently initialized. due to load order concerns, this can only be initialized on round end and plugin start.
new AMS_CurrentSpell[MAX_PLAYERS_ARRAY]; // internal
new String:AMS_AbilityPack[MAX_PLAYERS_ARRAY][AMS_MAX_SPELLS][AMS_PLUGIN_NAME_LENGTH]; // internal, must be initialized by every sub-ability
new String:AMS_AbilityPrefix[MAX_PLAYERS_ARRAY][AMS_MAX_SPELLS][AMS_MAX_PREFIX_SIZE]; // internal, must be initialized by every sub-ability
new Float:AMS_AbilityCost[MAX_PLAYERS_ARRAY][AMS_MAX_SPELLS]; // internal, must be initialized by every sub-ability
new Float:AMS_AbilityCooldown[MAX_PLAYERS_ARRAY][AMS_MAX_SPELLS]; // internal, must be initialized by every sub-ability
new Float:AMS_CooldownEndsAt[MAX_PLAYERS_ARRAY][AMS_MAX_SPELLS]; // internal
new String:AMS_AbilityName[MAX_PLAYERS_ARRAY][AMS_MAX_SPELLS][MAX_TERMINOLOGY_LENGTH]; // internal, must be initialized by every sub-ability
new String:AMS_AbilityDescription[MAX_PLAYERS_ARRAY][AMS_MAX_SPELLS][MAX_DESCRIPTION_LENGTH]; // internal, must be initialized by every sub-ability
new bool:AMS_AbilityCanBeEnded[MAX_PLAYERS_ARRAY][AMS_MAX_SPELLS]; // internal, optional param for sub-abilities
new bool:AMS_ActKeyDown[MAX_PLAYERS_ARRAY]; // internal
new bool:AMS_SelKeyDown[MAX_PLAYERS_ARRAY]; // internal
new bool:AMS_ReverseSelKeyDown[MAX_PLAYERS_ARRAY]; // internal
new Float:AMS_UpdateHUDAt[MAX_PLAYERS_ARRAY]; // internal
new bool:AMS_TweakedHUDs[MAX_PLAYERS_ARRAY]; // internal
new bool:AMS_ActivatedByMedic[MAX_PLAYERS_ARRAY]; // internal
new bool:AMS_RageSpent[MAX_PLAYERS_ARRAY]; // internal
new AMS_ActivationKey[MAX_PLAYERS_ARRAY]; // derived from arg1
new AMS_SelectionKey[MAX_PLAYERS_ARRAY]; // derived from arg2
new AMS_ReverseSelectionKey[MAX_PLAYERS_ARRAY]; // derived from arg3
new AMS_HUDUnavailableColor[MAX_PLAYERS_ARRAY]; // arg4
new String:AMS_HUDUnavailableFormat[MAX_CENTER_TEXT_LENGTH]; // arg5
new AMS_HUDAvailableColor[MAX_PLAYERS_ARRAY]; // arg6
new String:AMS_HUDAvailableFormat[MAX_CENTER_TEXT_LENGTH]; // arg7
new Float:AMS_HudY[MAX_PLAYERS_ARRAY]; // arg8
new String:AMS_HUDReplacementFormat[MAX_CENTER_TEXT_LENGTH]; // arg9
new Float:AMS_HUDReplacementY[MAX_PLAYERS_ARRAY]; // arg10
new String:AMS_CastingParticle[MAX_EFFECT_NAME_LENGTH]; // arg11
new String:AMS_CastingAttachment[MAX_ATTACHMENT_NAME_LENGTH]; // arg12

/**
 * Rage Random Weapon, compatible with the AMS system
 */
#define RRW_STRING "rage_random_weapon"
#define RRW_TRIGGER_E 0
#define RRW_TRIGGER_AMS 1
#define RRW_MAX_WEAPONS 10
new bool:RRW_ActiveThisRound;
new bool:RRW_CanUse[MAX_PLAYERS_ARRAY];
new RRW_WeaponEntRef[MAX_PLAYERS_ARRAY][RRW_MAX_WEAPONS]; // internal
new Float:RRW_RemoveWeaponAt[MAX_PLAYERS_ARRAY][RRW_MAX_WEAPONS]; // internal
new RRW_WearableEntRef[MAX_PLAYERS_ARRAY][RRW_MAX_WEAPONS]; // internal
new RRW_Trigger[MAX_PLAYERS_ARRAY]; // arg1
new RRW_WeaponCount[MAX_PLAYERS_ARRAY]; // arg2
new Float:RRW_WeaponLifetime[MAX_PLAYERS_ARRAY]; // arg3 (0.0 = never expire)
new RRW_Slot[MAX_PLAYERS_ARRAY][RRW_MAX_WEAPONS]; // argX6 (16, 26, 36...106)
new RRW_TempWearable[MAX_PLAYERS_ARRAY][RRW_MAX_WEAPONS]; // argX7 (17, 27, 37...107)

/**
 * Rage Steal Next Weapon
 */
#define SNW_STRING "rage_steal_next_weapon"
#define SNW_TRIGGER_E 0
#define SNW_TRIGGER_AMS 1
#define SNW_NUM_WEAPONS 9
new bool:SNW_ActiveThisRound;
new bool:SNW_CanUse[MAX_PLAYERS_ARRAY];
new Float:SNW_StealingUntil[MAX_PLAYERS_ARRAY]; // internal
new SNW_WeaponEntRef[MAX_PLAYERS_ARRAY][SNW_NUM_WEAPONS]; // internal
new Float:SNW_RemoveWeaponAt[MAX_PLAYERS_ARRAY][SNW_NUM_WEAPONS]; // internal
new SNW_SuppressedSlot[MAX_PLAYERS_ARRAY]; // internal, note that this is used for VICTIMS, not the hale
new Float:SNW_SlotSuppressedUntil[MAX_PLAYERS_ARRAY]; // internal, note that this is used for VICTIMS, not the hale
new SNW_Trigger[MAX_PLAYERS_ARRAY]; // arg1
new Float:SNW_StealDuration[MAX_PLAYERS_ARRAY]; // arg2
new Float:SNW_WeaponKeepDuration[MAX_PLAYERS_ARRAY]; // arg3
// arg4 is used at rage time
new Float:SNW_SlotSuppressionDuration[MAX_PLAYERS_ARRAY]; // arg5
// args X1 to X8 also only used at rage time, except X6
new SNW_Slot[MAX_PLAYERS_ARRAY][SNW_NUM_WEAPONS]; // argX6 (16, 26, 36...96)

/**
 * Rage Front Protection
 */
#define FP_STRING "rage_front_protection"
#define FP_TRIGGER_E 0
#define FP_TRIGGER_AMS 1
new bool:FP_ActiveThisRound;
new bool:FP_CanUse[MAX_PLAYERS_ARRAY];
new Float:FP_ProtectedUntil[MAX_PLAYERS_ARRAY]; // internal
new Float:FP_DamageRemaining[MAX_PLAYERS_ARRAY]; // internal
new FP_WearableEntRef[MAX_PLAYERS_ARRAY]; // internal
new String:FP_NormalModel[MAX_PLAYERS_ARRAY][MAX_MODEL_FILE_LENGTH]; // internal
new FP_Trigger[MAX_PLAYERS_ARRAY]; // arg1
new Float:FP_Duration[MAX_PLAYERS_ARRAY]; // arg2
new Float:FP_Damage[MAX_PLAYERS_ARRAY]; // arg3
new String:FP_ShotBlockedSound[MAX_PLAYERS_ARRAY][MAX_SOUND_FILE_LENGTH]; // arg4
new Float:FP_MinYawBlock[MAX_PLAYERS_ARRAY]; // arg5
new Float:FP_MaxYawBlock[MAX_PLAYERS_ARRAY]; // arg6
// arg8, mapwide rage sound, does not need to be stored
new FP_WearableIdx[MAX_PLAYERS_ARRAY]; // arg9
new String:FP_ShieldedModel[MAX_PLAYERS_ARRAY][MAX_MODEL_FILE_LENGTH]; // arg10

/**
 * Rage Fake Dead Ringer
 */
#define FDR_STRING "rage_fake_dead_ringer"
#define FDR_TRIGGER_E 0
#define FDR_TRIGGER_AMS 1
#define FDR_SOUND "player/spy_uncloak_feigndeath.wav"
new bool:FDR_ActiveThisRound;
new bool:FDR_CanUse[MAX_PLAYERS_ARRAY];
new bool:FDR_IsPending[MAX_PLAYERS_ARRAY]; // internal
new Float:FDR_EndsAt[MAX_PLAYERS_ARRAY]; // internal
new bool:FDR_FirstTick[MAX_PLAYERS_ARRAY]; // internal
new Float:FDR_GoombaBlockedUntil[MAX_PLAYERS_ARRAY]; // internal
new FDR_Trigger[MAX_PLAYERS_ARRAY]; // arg1
new Float:FDR_MaxDuration[MAX_PLAYERS_ARRAY]; // arg2
new Float:FDR_UncloakAttackWait[MAX_PLAYERS_ARRAY]; // arg3

/**
 * Rage Dodge Specific Damage
 */
#define DSD_STRING "rage_dodge_specific_damage"
#define DSD_TRIGGER_E 0
#define DSD_TRIGGER_AMS 1
new bool:DSD_ActiveThisRound;
new bool:DSD_CanUse[MAX_PLAYERS_ARRAY];
new Float:DSD_ActiveUntil[MAX_PLAYERS_ARRAY]; // internal
new DSD_Trigger[MAX_PLAYERS_ARRAY]; // arg1
new Float:DSD_Duration[MAX_PLAYERS_ARRAY]; // arg2
new Float:DSD_MoveSpeed[MAX_PLAYERS_ARRAY]; // arg3
new Float:DSD_ReplaySpeed[MAX_PLAYERS_ARRAY]; // arg4
new bool:DSD_DodgeBullets[MAX_PLAYERS_ARRAY]; // arg5
new bool:DSD_DodgeBlast[MAX_PLAYERS_ARRAY]; // arg6
new bool:DSD_DodgeFire[MAX_PLAYERS_ARRAY]; // arg7
new bool:DSD_DodgeMelee[MAX_PLAYERS_ARRAY]; // arg8
// arg9 is mapwide rage sound, does not need to be stored

/**
 * Rage AMS Dynamic Teleport
 */
#define ADT_STRING "rage_ams_dynamic_teleport"
#define ADT_TRIGGER_E 0
#define ADT_TRIGGER_AMS 1
// oddly enough, ActiveThisRound and CanUse are not needed for once.
new ADT_Trigger[MAX_PLAYERS_ARRAY]; // arg1
new bool:ADT_TeleportTop[MAX_PLAYERS_ARRAY]; // arg2
new bool:ADT_TeleportSide[MAX_PLAYERS_ARRAY]; // arg3
new Float:ADT_SelfStunDuration[MAX_PLAYERS_ARRAY]; // arg4
// arg5 is mapwide rage sound, does not need to be stored
new ADT_MaxEnemiesToFunction[MAX_PLAYERS_ARRAY]; // arg6

/**
 * METHODS REQUIRED BY ff2 subplugin
 */
PrintRageWarning()
{
	PrintToServer("*********************************************************************");
	PrintToServer("*                             WARNING                               *");
	PrintToServer("*       DEBUG_FORCE_RAGE in ff2_sarysapub3.sp is set to true!       *");
	PrintToServer("*  Any admin can use the 'rage' command to use rages in this pack!  *");
	PrintToServer("*  This is only for test servers. Disable this on your live server. *");
	PrintToServer("*********************************************************************");
}
 
#define CMD_FORCE_RAGE "rage"
public OnPluginStart2()
{
	// special initialize here, since this can't be done in RoundStart
	cvarTimeScale = FindConVar("host_timescale");
	cvarCheats = FindConVar("sv_cheats");
	AMS_RemoveSpellsFromAll();
	AMS_HUDHandle = CreateHudSynchronizer();
	AMS_HUDReplaceHandle = CreateHudSynchronizer();
	
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	PrecacheSound(NOPE_AVI);
	for (new i = 0; i < MAX_PLAYERS_ARRAY; i++) // MAX_PLAYERS_ARRAY is correct here, this one time
		NULL_BLACKLIST[i] = false;
		
	if (DEBUG_FORCE_RAGE)
	{
		PrintRageWarning();
		RegAdminCmd(CMD_FORCE_RAGE, CmdForceRage, ADMFLAG_GENERIC);
	}
	if(FF2_GetRoundState()==1)
	{
		HookAbilities();
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	HookAbilities();
}

public HookAbilities()
{
	RoundInProgress = true;
	
	// initialize variables
	AMS_ActiveThisRound = false;
	RRW_ActiveThisRound = false;
	SNW_ActiveThisRound = false;
	FP_ActiveThisRound = false;
	FDR_ActiveThisRound = false;
	DSD_ActiveThisRound = false;
	
	// initialize arrays
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		// all client inits
		AMS_CanUse[clientIdx] = false;
		RRW_CanUse[clientIdx] = false;
		SNW_SuppressedSlot[clientIdx] = -1;
		SNW_CanUse[clientIdx] = false;
		FP_CanUse[clientIdx] = false;
		FDR_CanUse[clientIdx] = false;
		DSD_CanUse[clientIdx] = false;

		// boss-only inits
		new bossIdx = IsLivingPlayer(clientIdx) ? FF2_GetBossIndex(clientIdx) : -1;
		if (bossIdx < 0)
			continue;

		if ((AMS_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, AMS_STRING)) == true)
		{
			AMS_ActiveThisRound = true;
			AMS_ActivatedByMedic[clientIdx] = false;
			AMS_RageSpent[clientIdx] = false;
			AMS_UpdateHUDAt[clientIdx] = 0.0;
			AMS_TweakedHUDs[clientIdx] = false;
			
			AMS_ActivationKey[clientIdx] = AMS_GetActionKey(bossIdx, 1);
			AMS_SelectionKey[clientIdx] = AMS_GetActionKey(bossIdx, 2);
			AMS_ReverseSelectionKey[clientIdx] = AMS_GetActionKey(bossIdx, 3);
			AMS_HUDUnavailableColor[clientIdx] = ReadHexOrDecString(bossIdx, AMS_STRING, 4);
			ReadCenterText(bossIdx, AMS_STRING, 5, AMS_HUDUnavailableFormat);
			AMS_HUDAvailableColor[clientIdx] = ReadHexOrDecString(bossIdx, AMS_STRING, 6);
			ReadCenterText(bossIdx, AMS_STRING, 7, AMS_HUDAvailableFormat);
			AMS_HudY[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, AMS_STRING, 8);
			ReadCenterText(bossIdx, AMS_STRING, 9, AMS_HUDReplacementFormat);
			AMS_HUDReplacementY[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, AMS_STRING, 10);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AMS_STRING, 11, AMS_CastingParticle, MAX_EFFECT_NAME_LENGTH);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, AMS_STRING, 12, AMS_CastingAttachment, MAX_ATTACHMENT_NAME_LENGTH);

			AMS_ActKeyDown[clientIdx] = (GetClientButtons(clientIdx) & AMS_ActivationKey[clientIdx]) != 0;
			AMS_SelKeyDown[clientIdx] = (GetClientButtons(clientIdx) & AMS_SelectionKey[clientIdx]) != 0;
			AMS_ReverseSelKeyDown[clientIdx] = (GetClientButtons(clientIdx) & AMS_ReverseSelectionKey[clientIdx]) != 0;
		}

		if ((RRW_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, RRW_STRING)) == true)
		{
			RRW_ActiveThisRound = true;
			
			RRW_Trigger[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RRW_STRING, 1);
			RRW_WeaponCount[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RRW_STRING, 2);
			RRW_WeaponLifetime[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, RRW_STRING, 3);
			
			RRW_WeaponCount[clientIdx] = min(RRW_WeaponCount[clientIdx], RRW_MAX_WEAPONS);
			for (new i = 0; i < RRW_WeaponCount[clientIdx]; i++)
			{
				new offset = (10 * (i + 1));
				RRW_WeaponEntRef[clientIdx][i] = INVALID_ENTREF;
				RRW_RemoveWeaponAt[clientIdx][i] = FAR_FUTURE;
				RRW_WearableEntRef[clientIdx][i] = INVALID_ENTREF;
				
				// a couple need to be stored as they're needed often
				RRW_Slot[clientIdx][i] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RRW_STRING, 6 + offset);
				RRW_TempWearable[clientIdx][i] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RRW_STRING, 7 + offset);
			}

			// sound to precache
			static String:soundFile[MAX_SOUND_FILE_LENGTH];
			ReadSound(bossIdx, RRW_STRING, 4, soundFile);
			
			if (RRW_Trigger[clientIdx] == RRW_TRIGGER_AMS)
				AMS_InitSubability(bossIdx, clientIdx, this_plugin_name, RRW_STRING, "RRW");
		}

		if ((SNW_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, SNW_STRING)) == true)
		{
			SNW_ActiveThisRound = true;
			SNW_StealingUntil[clientIdx] = 0.0;

			// sound to precache
			static String:soundFile[MAX_SOUND_FILE_LENGTH];
			ReadSound(bossIdx, SNW_STRING, 4, soundFile);
			
			SNW_Trigger[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SNW_STRING, 1);
			SNW_StealDuration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SNW_STRING, 2);
			SNW_WeaponKeepDuration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SNW_STRING, 3);
			SNW_SlotSuppressionDuration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SNW_STRING, 5);
			for (new i = 0; i < SNW_NUM_WEAPONS; i++)
			{
				new offset = (10 * (i + 1));
				SNW_WeaponEntRef[clientIdx][i] = INVALID_ENTREF;
				SNW_RemoveWeaponAt[clientIdx][i] = FAR_FUTURE;
				
				// honestly there's no reason to store this version. meh.
				SNW_Slot[clientIdx][i] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SNW_STRING, 6 + offset);
				ReadSound(bossIdx, SNW_STRING, 9 + offset, soundFile);
			}
			
			if (SNW_Trigger[clientIdx] == SNW_TRIGGER_AMS)
				AMS_InitSubability(bossIdx, clientIdx, this_plugin_name, SNW_STRING, "SNW");
		}

		if ((FP_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, FP_STRING)) == true)
		{
			FP_ActiveThisRound = true;
			FP_ProtectedUntil[clientIdx] = FAR_FUTURE;
			FP_DamageRemaining[clientIdx] = 0.0;
			FP_WearableEntRef[clientIdx] = INVALID_ENTREF;
			
			FP_Trigger[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, FP_STRING, 1);
			FP_Duration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, FP_STRING, 2);
			FP_Damage[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, FP_STRING, 3);
			ReadSound(bossIdx, FP_STRING, 4, FP_ShotBlockedSound[clientIdx]);
			FP_MinYawBlock[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, FP_STRING, 5);
			FP_MaxYawBlock[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, FP_STRING, 6);
			FP_WearableIdx[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, FP_STRING, 9);
			ReadModel(bossIdx, FP_STRING, 10, FP_ShieldedModel[clientIdx]);

			// sounds to precache
			static String:soundFile[MAX_SOUND_FILE_LENGTH];
			ReadSound(bossIdx, FP_STRING, 7, soundFile);
			ReadSound(bossIdx, FP_STRING, 8, soundFile);

			if (FP_Trigger[clientIdx] == FP_TRIGGER_AMS)
				AMS_InitSubability(bossIdx, clientIdx, this_plugin_name, FP_STRING, "FP");
		}

		if ((FDR_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, FDR_STRING)) == true)
		{
			FDR_ActiveThisRound = true;
			FDR_EndsAt[clientIdx] = FAR_FUTURE;
			FDR_IsPending[clientIdx] = false;

			FDR_Trigger[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, FDR_STRING, 1);
			FDR_MaxDuration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, FDR_STRING, 2);
			FDR_UncloakAttackWait[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, FDR_STRING, 3);
			PrecacheSound(FDR_SOUND);

			if (FDR_Trigger[clientIdx] == FDR_TRIGGER_AMS)
				AMS_InitSubability(bossIdx, clientIdx, this_plugin_name, FDR_STRING, "FDR");
		}

		if ((DSD_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, DSD_STRING)) == true)
		{
			DSD_ActiveThisRound = true;
			DSD_ActiveUntil[clientIdx] = FAR_FUTURE;

			DSD_Trigger[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, DSD_STRING, 1);
			DSD_Duration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DSD_STRING, 2);
			DSD_MoveSpeed[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DSD_STRING, 3);
			DSD_ReplaySpeed[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DSD_STRING, 4);
			DSD_DodgeBullets[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, DSD_STRING, 5) == 1;
			DSD_DodgeBlast[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, DSD_STRING, 6) == 1;
			DSD_DodgeFire[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, DSD_STRING, 7) == 1;
			DSD_DodgeMelee[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, DSD_STRING, 8) == 1;

			// sounds to precache
			static String:soundFile[MAX_SOUND_FILE_LENGTH];
			ReadSound(bossIdx, DSD_STRING, 9, soundFile);

			if (DSD_Trigger[clientIdx] == DSD_TRIGGER_AMS)
				AMS_InitSubability(bossIdx, clientIdx, this_plugin_name, DSD_STRING, "DSD");
		}

		if (FF2_HasAbility(bossIdx, this_plugin_name, ADT_STRING))
		{
			ADT_Trigger[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, ADT_STRING, 1);
			ADT_TeleportTop[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, ADT_STRING, 2) == 1;
			ADT_TeleportSide[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, ADT_STRING, 3) == 1;
			ADT_SelfStunDuration[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ADT_STRING, 4);
			ADT_MaxEnemiesToFunction[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, ADT_STRING, 6);

			// sounds to precache
			static String:soundFile[MAX_SOUND_FILE_LENGTH];
			ReadSound(bossIdx, ADT_STRING, 5, soundFile);

			if (ADT_Trigger[clientIdx] == ADT_TRIGGER_AMS)
				AMS_InitSubability(bossIdx, clientIdx, this_plugin_name, ADT_STRING, "ADT");
		}
	}
	
	if (AMS_ActiveThisRound)
		AddCommandListener(AMS_MedicCommand, "voicemenu");
		
	if (SNW_ActiveThisRound)
	{
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsClientInGame(clientIdx))
				SDKHook(clientIdx, SDKHook_OnTakeDamage, SNW_OnTakeDamage);
		}
	}
		
	if (FP_ActiveThisRound)
	{
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsLivingPlayer(clientIdx) && FP_CanUse[clientIdx])
				SDKHook(clientIdx, SDKHook_OnTakeDamageAlive, FP_OnTakeDamageAlive);
		}
	}

	if (FDR_ActiveThisRound)
	{
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsLivingPlayer(clientIdx) && FDR_CanUse[clientIdx])
			{
				SDKHook(clientIdx, SDKHook_PreThink, FDR_PreThink);
				SDKHook(clientIdx, SDKHook_OnTakeDamage, FDR_OnTakeDamage);
			}
		}
	}
		
	if (DSD_ActiveThisRound)
	{
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsLivingPlayer(clientIdx) && DSD_CanUse[clientIdx])
				SDKHook(clientIdx, SDKHook_OnTakeDamage, DSD_OnTakeDamage);
		}
	}
		
	CreateTimer(0.3, Timer_PostRoundStartInits, _, TIMER_FLAG_NO_MAPCHANGE);
}

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

		// need to be well past the first round bug check
		if (FP_ActiveThisRound && FP_CanUse[clientIdx])
			GetEntPropString(clientIdx, Prop_Data, "m_ModelName", FP_NormalModel[clientIdx], MAX_MODEL_FILE_LENGTH);
	}

	return Plugin_Handled;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundInProgress = false;
	
	// special initialize here, since this can't be done in RoundStart.
	// it is intended that this is always done.
	AMS_RemoveSpellsFromAll();

	if (AMS_ActiveThisRound)
	{
		AMS_ActiveThisRound = false;
		RemoveCommandListener(AMS_MedicCommand, "voicemenu");
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
			FF2_SetFF2flags(clientIdx, FF2_GetFF2flags(clientIdx) & (~FF2FLAG_HUDDISABLED));
	}

	if (SNW_ActiveThisRound)
	{
		SNW_ActiveThisRound = false;

		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsClientInGame(clientIdx))
				SDKUnhook(clientIdx, SDKHook_OnTakeDamage, SNW_OnTakeDamage);
		}
	}

	if (FP_ActiveThisRound)
	{
		FP_ActiveThisRound = false;
	
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsClientInGame(clientIdx) && FP_CanUse[clientIdx])
				SDKUnhook(clientIdx, SDKHook_OnTakeDamageAlive, FP_OnTakeDamageAlive);
		}
	}

	if (FDR_ActiveThisRound)
	{
		FDR_ActiveThisRound = false;
		
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsClientInGame(clientIdx) && FDR_CanUse[clientIdx])
			{
				SDKUnhook(clientIdx, SDKHook_PreThink, FDR_PreThink);
				SDKUnhook(clientIdx, SDKHook_OnTakeDamage, FDR_OnTakeDamage);
			}
		}
	}
	
	if (DSD_ActiveThisRound)
	{
		DSD_ActiveThisRound = false;
	
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (DSD_CanUse[clientIdx])
			{
				if (IsClientInGame(clientIdx))
					SDKUnhook(clientIdx, SDKHook_OnTakeDamage, DSD_OnTakeDamage);

				if (DSD_ActiveUntil[clientIdx] != FAR_FUTURE && DSD_ReplaySpeed[clientIdx] > 0.0)
				{
					SetConVarFloat(cvarTimeScale, 1.0);
					DSD_UpdateClientCheatValue(0);
				}
			}
		}
	}
}

public Action:FF2_OnAbility2(bossIdx, const String:plugin_name[], const String:ability_name[], status)
{
	if (strcmp(plugin_name, this_plugin_name) != 0)
		return Plugin_Continue;
	else if (!RoundInProgress) // don't execute these rages with 0 players alive
		return Plugin_Continue;
		
	if (!strcmp(ability_name, AMS_STRING))
	{
		Rage_MultiSpellBase(GetClientOfUserId(FF2_GetBossUserId(bossIdx)));
	}
	else if (!strcmp(ability_name, RRW_STRING))
	{
		Rage_RandomWeapon(GetClientOfUserId(FF2_GetBossUserId(bossIdx)));
	}
	else if (!strcmp(ability_name, SNW_STRING))
	{
		Rage_StealNextWeapon(GetClientOfUserId(FF2_GetBossUserId(bossIdx)));
	}
	else if (!strcmp(ability_name, FP_STRING))
	{
		Rage_FrontProtection(GetClientOfUserId(FF2_GetBossUserId(bossIdx)));
	}
	else if (!strcmp(ability_name, FDR_STRING))
	{
		Rage_FakeDeadRinger(GetClientOfUserId(FF2_GetBossUserId(bossIdx)));
	}
	else if (!strcmp(ability_name, DSD_STRING))
	{
		Rage_DodgeSpecificDamage(GetClientOfUserId(FF2_GetBossUserId(bossIdx)));
	}
	else if (!strcmp(ability_name, ADT_STRING))
	{
		Rage_AMSDynamicTeleport(GetClientOfUserId(FF2_GetBossUserId(bossIdx)));
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
	
	if (!strcmp("deadringer", unparsedArgs))
	{
		FDR_Invoke(GetClientOfUserId(FF2_GetBossUserId(0)));
		PrintToConsole(user, "Forcing dead ringer.");
		
		return Plugin_Handled;
	}
	else if (!strcmp("robme", unparsedArgs))
	{
		SNW_SetClassWeapon(GetClientOfUserId(FF2_GetBossUserId(0)), user, _:TF2_GetPlayerClass(user));
		PrintToConsole(user, "Gonna get robbed.");
		
		return Plugin_Handled;
	}
	
	PrintToServer("[sarysapub3] Rage not found: %s", unparsedArgs);
	return Plugin_Continue;
}

/**
 * Multi-Spell Base
 */
AMS_GetActionKey(bossIdx, argIdx)
{
	new keyIdx = FF2_GetAbilityArgument(bossIdx, this_plugin_name, AMS_STRING, argIdx);
	if (keyIdx == 1)
		return IN_RELOAD;
	else if (keyIdx == 2)
		return IN_ATTACK3;
	else if (keyIdx == 3)
		return IN_USE;
	return 0; // no key, implied is "call for medic"
}
 
AMS_RemoveSpellsFromAll()
{
	// ADD NOTHING ELSE HERE, this has to be called on plugin start so keep it minimal!
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		AMS_NumSpells[clientIdx] = 0;
		AMS_CurrentSpell[clientIdx] = 0;
	}
}

#define AMS_PLUGIN_NAME_MAX 33
#define AMS_METHOD_NAME_MAX 65
new String:AMS_PluginName[AMS_PLUGIN_NAME_MAX];
new String:AMS_MethodName[AMS_METHOD_NAME_MAX];
AMS_FixPluginName(const String:pluginName[], bool:forReflection)
{
	if (forReflection)
		Format(AMS_PluginName, AMS_PLUGIN_NAME_MAX, "%s.ff2", pluginName);
	else
		Format(AMS_PluginName, AMS_PLUGIN_NAME_MAX, "%s", pluginName);
}

AMS_FixMethodName(const String:format[], const String:prefix[AMS_MAX_PREFIX_SIZE])
{
	Format(AMS_MethodName, AMS_METHOD_NAME_MAX, format, prefix);
}
/*
// public interface - init
public AMS_InitSubability(bossIdx, clientIdx, const String:pluginName[], const String:abilityName[MAX_ABILITY_NAME_LENGTH], const String:prefix[AMS_MAX_PREFIX_SIZE])
{
	new slot = FF2_GetAbilityArgument(bossIdx, pluginName, abilityName, 1006);
	if (slot >= AMS_MAX_SPELLS)
	{
		PrintToServer("[sarysapub3] AMS ERROR: Ability slot %d exceeds limit of %d. ability=%s", slot, AMS_MAX_SPELLS, abilityName);
		return;
	}

	strcopy(AMS_AbilityPack[clientIdx][slot], AMS_PLUGIN_NAME_LENGTH, pluginName);
	strcopy(AMS_AbilityPrefix[clientIdx][slot], AMS_MAX_PREFIX_SIZE, prefix);
	new Float:initialCooldown = FF2_GetAbilityArgumentFloat(bossIdx, pluginName, abilityName, 1001);
	AMS_CooldownEndsAt[clientIdx][slot] = GetEngineTime() + initialCooldown;
	AMS_AbilityCooldown[clientIdx][slot] = FF2_GetAbilityArgumentFloat(bossIdx, pluginName, abilityName, 1002);
	FF2_GetAbilityArgumentString(bossIdx, pluginName, abilityName, 1003, AMS_AbilityName[clientIdx][slot], MAX_TERMINOLOGY_LENGTH);
	FF2_GetAbilityArgumentString(bossIdx, pluginName, abilityName, 1004, AMS_AbilityDescription[clientIdx][slot], MAX_DESCRIPTION_LENGTH);
	AMS_AbilityCost[clientIdx][slot] = FF2_GetAbilityArgumentFloat(bossIdx, pluginName, abilityName, 1005);
	AMS_AbilityCanBeEnded[clientIdx][slot] = FF2_GetAbilityArgument(bossIdx, pluginName, abilityName, 1007) == 1;
	AMS_NumSpells[clientIdx]++;
	
	AMS_NumSpells[clientIdx] = min(AMS_MAX_SPELLS, AMS_NumSpells[clientIdx]);
	
	Debug("SARYSAPUB3 - AMS_INITSUBABILITY: bossIdx %i | clientIdx %i | pluginName %s | abilityName %s | prefix %s | slot %i", bossIdx, clientIdx, pluginName, abilityName, prefix, slot);
	
}
*/
// private - used to minimize all reflection code
AMS_GetMethod(clientIdx, spellIdx, const String:format[], &Handle:retPlugin, &Function:retFunc)
{
	AMS_FixPluginName(AMS_AbilityPack[clientIdx][spellIdx], true);
	AMS_FixMethodName(format, AMS_AbilityPrefix[clientIdx][spellIdx]);

	static String:buffer[256];
	new Handle:iter = GetPluginIterator();
	new Handle:plugin = INVALID_HANDLE;
	while (MorePlugins(iter))
	{
		plugin = ReadPlugin(iter);
		
		GetPluginFilename(plugin, buffer, sizeof(buffer));
		if (StrContains(buffer, AMS_PluginName, false) != -1)
			break;
		else
			plugin = INVALID_HANDLE;
	}
	
	CloseHandle(iter);
	if (plugin != INVALID_HANDLE)
	{
		new Function:func = GetFunctionByName(plugin, AMS_MethodName);
		if (func != INVALID_FUNCTION)
		{
			retPlugin = plugin;
			retFunc = func;
		}
		else
			PrintToServer("[sarysapub3] ERROR: Could not find %s:%s()", AMS_PluginName, AMS_MethodName);
	}
	else
		PrintToServer("[sarysapub3] ERROR: Could not find %s. %s() failed.", AMS_PluginName, AMS_MethodName);
}

AMS_ExecuteSpell(clientIdx, spellIdx)
{
	if (!IsEmptyString(AMS_CastingParticle))
	{
		new particle = -1;
		if (IsEmptyString(AMS_CastingAttachment))
			particle = AttachParticle(clientIdx, AMS_CastingParticle, 70.0, true);
		else
			particle = AttachParticleToAttachment(clientIdx, AMS_CastingParticle, AMS_CastingAttachment);
			
		if (IsValidEntity(particle))
			CreateTimer(1.0, RemoveEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	}

	new Handle:plugin = INVALID_HANDLE;
	new Function:func = INVALID_FUNCTION;
	AMS_GetMethod(clientIdx, spellIdx, "%s_Invoke", plugin, func);
	if (plugin != INVALID_HANDLE && func != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, func);
		Call_PushCell(clientIdx);
		Call_Finish();
	}
}

bool:AMS_CanExecuteSpell(clientIdx, spellIdx)
{
	new bool:result = false;
	new Handle:plugin = INVALID_HANDLE;
	new Function:func = INVALID_FUNCTION;
	AMS_GetMethod(clientIdx, spellIdx, "%s_CanInvoke", plugin, func);
	if (plugin != INVALID_HANDLE && func != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, func);
		Call_PushCell(clientIdx);
		Call_Finish(result);
	}
	return result;
}

AMS_EndAbility(clientIdx, spellIdx)
{
	new bool:result = false;
	new Handle:plugin = INVALID_HANDLE;
	new Function:func = INVALID_FUNCTION;
	AMS_GetMethod(clientIdx, spellIdx, "%s_EndAbility", plugin, func);
	if (plugin != INVALID_HANDLE && func != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, func);
		Call_PushCell(clientIdx);
		Call_Finish(result);
	}
	return result;
}

public bool:AMS_CurrentSpellAvailable(clientIdx, bossIdx, Float:curTime)
{
	if (TF2_IsPlayerInCondition(clientIdx, TFCond_Dazed))
		return false;

	new spellIdx = AMS_CurrentSpell[clientIdx];
	if (AMS_CooldownEndsAt[clientIdx][spellIdx] > curTime)
		return false;
		
	new Float:rage = FF2_GetBossCharge(bossIdx, 0);
	if (rage < AMS_AbilityCost[clientIdx][spellIdx])
		return false;
	
	return AMS_CanExecuteSpell(clientIdx, spellIdx);
}

public Action:AMS_MedicCommand(clientIdx, const String:command[], argc)
{
	if (!IsLivingPlayer(clientIdx) || GetClientTeam(clientIdx) != BossTeam)
		return Plugin_Continue;
	
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0 || AMS_ActivationKey[clientIdx] != 0)
		return Plugin_Continue;

	new String:unparsedArgs[4];
	GetCmdArgString(unparsedArgs, 4);
	if (!strcmp(unparsedArgs, "0 0"))
		AMS_ActivatedByMedic[clientIdx] = true; // validity is checked next frame
	
	return Plugin_Continue;
}

public AMS_Tick(clientIdx, buttons, Float:curTime)
{
	if (AMS_NumSpells[clientIdx] == 0)
		return; // guess they haven't loaded yet.

	new bool:selKeyDown = (buttons & AMS_SelectionKey[clientIdx]) != 0;
	new bool:reverseSelKeyDown = (buttons & AMS_ReverseSelectionKey[clientIdx]) != 0;
	new bool:actKeyDown = (buttons & AMS_ActivationKey[clientIdx]) != 0;
	
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
	{
		PrintToServer("[sarysapub3] ERROR: Invalid boss index for %d or %d has no spells. Disabling multi-spell base.");
		AMS_CanUse[clientIdx] = false;
		return;
	}
	
	if (!AMS_TweakedHUDs[clientIdx])
	{
		AMS_TweakedHUDs[clientIdx] = true;
		FF2_SetFF2flags(clientIdx, FF2_GetFF2flags(clientIdx) | FF2FLAG_HUDDISABLED);
		DD_SetForceHUDEnabled(clientIdx, true);
	}
		
	// selection key first
	if (selKeyDown && !AMS_SelKeyDown[clientIdx])
	{
		AMS_CurrentSpell[clientIdx]++;
		AMS_CurrentSpell[clientIdx] %= AMS_NumSpells[clientIdx];
		AMS_UpdateHUDAt[clientIdx] = curTime;
	}
	AMS_SelKeyDown[clientIdx] = selKeyDown;
	
	// reverse selection key next
	if (reverseSelKeyDown && !AMS_ReverseSelKeyDown[clientIdx])
	{
		AMS_CurrentSpell[clientIdx]--;
		if (AMS_CurrentSpell[clientIdx] < 0)
			AMS_CurrentSpell[clientIdx] = AMS_NumSpells[clientIdx] - 1;
		AMS_UpdateHUDAt[clientIdx] = curTime;
	}
	AMS_ReverseSelKeyDown[clientIdx] = reverseSelKeyDown;
	
	// activation key after the selection change
	if ((actKeyDown && !AMS_ActKeyDown[clientIdx]) || AMS_ActivatedByMedic[clientIdx])
	{
		// refund rage if FF2 ate it up
		if (AMS_ActivatedByMedic[clientIdx] && AMS_RageSpent[clientIdx])
		{
			FF2_SetBossCharge(bossIdx, 0, 100.0);
		}
	
		AMS_ActivatedByMedic[clientIdx] = false;
		AMS_RageSpent[clientIdx] = false;
	
		new spellIdx = AMS_CurrentSpell[clientIdx];
		if (AMS_CurrentSpellAvailable(clientIdx, bossIdx, curTime))
		{
			AMS_ExecuteSpell(clientIdx, spellIdx);
			new Float:rage = FF2_GetBossCharge(bossIdx, 0);
			FF2_SetBossCharge(bossIdx, 0, rage - AMS_AbilityCost[clientIdx][spellIdx]);
			AMS_CooldownEndsAt[clientIdx][spellIdx] = curTime + AMS_AbilityCooldown[clientIdx][spellIdx];
			AMS_UpdateHUDAt[clientIdx] = curTime;
		}
		else if (AMS_AbilityCanBeEnded[clientIdx][spellIdx])
			AMS_EndAbility(clientIdx, spellIdx);
	}
	AMS_ActKeyDown[clientIdx] = actKeyDown;
	
	// finally, do the HUD check
	if (curTime >= AMS_UpdateHUDAt[clientIdx] && (buttons & IN_SCORE) == 0)
	{
		AMS_UpdateHUDAt[clientIdx] = curTime + AMS_HUD_INTERVAL;
		new spellIdx = AMS_CurrentSpell[clientIdx];
		static String:buffer[MAX_CENTER_TEXT_LENGTH];
		new bool:available = AMS_CurrentSpellAvailable(clientIdx, bossIdx, curTime);
		
		// first the ability HUD
		if (available)
		{
			Format(buffer, MAX_CENTER_TEXT_LENGTH, AMS_HUDAvailableFormat, AMS_AbilityName[clientIdx][spellIdx], AMS_AbilityCost[clientIdx][spellIdx], AMS_AbilityDescription[clientIdx][spellIdx]);
			SetHudTextParams(-1.0, AMS_HudY[clientIdx], AMS_HUD_INTERVAL + 0.05, GetR(AMS_HUDAvailableColor[clientIdx]), GetG(AMS_HUDAvailableColor[clientIdx]), GetB(AMS_HUDAvailableColor[clientIdx]), 255);
		}
		else
		{
			Format(buffer, MAX_CENTER_TEXT_LENGTH, AMS_HUDUnavailableFormat, AMS_AbilityName[clientIdx][spellIdx], AMS_AbilityCost[clientIdx][spellIdx], AMS_AbilityDescription[clientIdx][spellIdx]);
			SetHudTextParams(-1.0, AMS_HudY[clientIdx], AMS_HUD_INTERVAL + 0.05, GetR(AMS_HUDUnavailableColor[clientIdx]), GetG(AMS_HUDUnavailableColor[clientIdx]), GetB(AMS_HUDUnavailableColor[clientIdx]), 255);
		}
		ShowSyncHudText(clientIdx, AMS_HUDHandle, buffer);
		
		// now the FF2 replacement HUD
		if (!IsEmptyString(AMS_HUDReplacementFormat))
		{
			SetHudTextParams(-1.0, AMS_HUDReplacementY[clientIdx], AMS_HUD_INTERVAL + 0.05, 255, 255, 255, 255);
			ShowSyncHudText(clientIdx, AMS_HUDReplaceHandle, AMS_HUDReplacementFormat, FF2_GetBossCharge(bossIdx, 0), GetEntProp(clientIdx, Prop_Data, "m_iHealth"), FF2_GetBossMaxHealth(bossIdx));
		}
	}
}

public Rage_MultiSpellBase(clientIdx)
{
	if (AMS_ActivationKey[clientIdx] == 0)
	{
		AMS_ActivatedByMedic[clientIdx] = true;
		AMS_RageSpent[clientIdx] = true; // signal rage refund next frame
	}
}

/**
 * Rage Random Weapon
 */
public Rage_RandomWeapon(clientIdx)
{
	if (RRW_Trigger[clientIdx] != RRW_TRIGGER_E)
		return;
		
	RRW_Invoke(clientIdx);
}

public bool:RRW_CanInvoke(clientIdx)
{
	return true; // no special conditions will prevent this ability
}

public RRW_Invoke(clientIdx)
{
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return;

	new rand = GetRandomInt(0, RRW_WeaponCount[clientIdx] - 1);
	new argOffset = (rand + 1) * 10;
	
	static String:weaponName[MAX_WEAPON_NAME_LENGTH];
	static String:weaponArgs[MAX_WEAPON_ARG_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RRW_STRING, argOffset + 1, weaponName, MAX_WEAPON_NAME_LENGTH);
	new weaponIdx = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RRW_STRING, argOffset + 2);
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, RRW_STRING, argOffset + 3, weaponArgs, MAX_WEAPON_ARG_LENGTH);
	new weaponVisibility = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RRW_STRING, argOffset + 4);
	new alpha = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RRW_STRING, argOffset + 5);
	new clip = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RRW_STRING, argOffset + 8);
	new ammo = FF2_GetAbilityArgument(bossIdx, this_plugin_name, RRW_STRING, argOffset + 9);
	
	PrepareForWeaponSwitch(clientIdx, true);
	TF2_RemoveWeaponSlot(clientIdx, RRW_Slot[clientIdx][rand]);
	new weapon = SpawnWeapon(clientIdx, weaponName, weaponIdx, 101, 5, weaponArgs, weaponVisibility);
	if (!IsValidEntity(weapon))
	{
		PrintCenterText(clientIdx, "Failed to spawn weapon %s / %d. Notify an admin!", weaponName, weaponIdx);
		return;
	}
	
	// alpha transparency, best if the viewmodel doesn't hold it well
	if (alpha != 255)
	{
		SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
		SetEntityRenderColor(weapon, 255, 255, 255, alpha);
	}
	
	// do not make it the active weapon if Dynamic Parkour is active
	if (!DP_IsLatched(clientIdx))
		SetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon", weapon);
		
	// set clip and ammo last
	new offset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1);
	if (offset >= 0)
	{
		SetEntProp(clientIdx, Prop_Send, "m_iAmmo", ammo, 4, offset);
			
		// the weirdness below is to avoid setting clips for invalid weapons like huntsman, flamethrower, minigun, and sniper rifles.
		// without the check below, these weapons would break.
		// as for energy weapons, I frankly don't care. they're a mess. don't use this code for making energy weapons.
		if (GetEntProp(weapon, Prop_Send, "m_iClip1") > 1 && GetEntProp(weapon, Prop_Send, "m_iClip1") < 128)
			SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
	}
	
	// delay primary/secondary attack ever so slightly
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.5);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 0.5);
		
	// store what needs to be stored
	RRW_WeaponEntRef[clientIdx][rand] = EntIndexToEntRef(weapon);
	RRW_RemoveWeaponAt[clientIdx][rand] = (RRW_WeaponLifetime[clientIdx] <= 0.0 ? FAR_FUTURE : (GetEngineTime() + RRW_WeaponLifetime[clientIdx]));
	RRW_ToggleWearable(clientIdx, rand, false); // remove old wearable for this slot, if applicable
	
	// play the sound
	static String:soundFile[MAX_SOUND_FILE_LENGTH];
	ReadSound(bossIdx, RRW_STRING, 4, soundFile);
	if (strlen(soundFile) > 3)
		EmitSoundToAll(soundFile);
}

public RRW_ToggleWearable(clientIdx, weaponIdx, bool:shouldAdd)
{
	if (RRW_TempWearable[clientIdx][weaponIdx] <= 0)
		return;
		
	if (shouldAdd && RRW_WearableEntRef[clientIdx][weaponIdx] == INVALID_ENTREF)
	{
		new wearable = SpawnWeapon(clientIdx, "tf_wearable", RRW_TempWearable[clientIdx][weaponIdx], 101, 5, "", 1);
		if (IsValidEntity(wearable))
		{
			RRW_WearableEntRef[clientIdx][weaponIdx] = EntIndexToEntRef(wearable);
			SetEntityRenderMode(wearable, RENDER_TRANSCOLOR);
			SetEntityRenderColor(wearable, 255, 255, 255, 0);
		}
	}
	else if (!shouldAdd && RRW_WearableEntRef[clientIdx][weaponIdx] != INVALID_ENTREF)
	{
		new wearable = EntRefToEntIndex(RRW_WearableEntRef[clientIdx][weaponIdx]);
		if (IsValidEntity(wearable))
			TF2_RemoveWearable(clientIdx, wearable);
		RRW_WearableEntRef[clientIdx][weaponIdx] = INVALID_ENTREF;
	}
}

public RRW_Tick(clientIdx, Float:curTime)
{
	for (new i = 0; i < RRW_WeaponCount[clientIdx]; i++)
	{
		if (RRW_WeaponEntRef[clientIdx][i] == INVALID_ENTREF)
			continue;
			
		new weapon = EntRefToEntIndex(RRW_WeaponEntRef[clientIdx][i]);
		if (!IsValidEntity(weapon))
		{
			RRW_ToggleWearable(clientIdx, i, false);
			RRW_WeaponEntRef[clientIdx][i] = INVALID_ENTREF;
			continue;
		}
		
		// this only happens if someone else's weapon spawning code is crap
		new weaponAtSlot = GetPlayerWeaponSlot(clientIdx, RRW_Slot[clientIdx][i]);
		if (weapon != weaponAtSlot)
		{
			if (PRINT_DEBUG_INFO)
				PrintToServer("[sarysapub3] WARNING: Multiple weapons at slot %d. Removing the old weapon. (someone's code sucks)", RRW_Slot[clientIdx][i]);
			RRW_ToggleWearable(clientIdx, i, false);
			AcceptEntityInput(weapon, "kill");
			RRW_WeaponEntRef[clientIdx][i] = INVALID_ENTREF;
			continue;
		}
		
		new activeWeapon = GetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon");
		if (curTime >= RRW_RemoveWeaponAt[clientIdx][i])
		{
			if (activeWeapon == weapon) // set them to melee
			{
				PrepareForWeaponSwitch(clientIdx, true);
		
				SetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(clientIdx, 2));
			}
			TF2_RemoveWeaponSlot(clientIdx, RRW_Slot[clientIdx][i]);
			RRW_ToggleWearable(clientIdx, i, false);
			RRW_WeaponEntRef[clientIdx][i] = INVALID_ENTREF;
			continue;
		}
		
		if (activeWeapon != weapon)
			RRW_ToggleWearable(clientIdx, i, false);
		else if (activeWeapon == weapon)
			RRW_ToggleWearable(clientIdx, i, true);
	}
}

/**
 * Rage Steal Next Weapon
 */
public Rage_StealNextWeapon(clientIdx)
{
	if (SNW_Trigger[clientIdx] != SNW_TRIGGER_E)
		return;
		
	SNW_Invoke(clientIdx);
}

public bool:SNW_CanInvoke(clientIdx)
{
	return true; // no special conditions will prevent this ability
}

public SNW_Invoke(clientIdx)
{
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return;

	SNW_StealingUntil[clientIdx] = GetEngineTime() + SNW_StealDuration[clientIdx];

	// play the sound, which serves as a warning to players
	static String:soundFile[MAX_SOUND_FILE_LENGTH];
	ReadSound(bossIdx, SNW_STRING, 4, soundFile);
	if (strlen(soundFile) > 3)
		EmitSoundToAll(soundFile);
}

public Action:SNW_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePos[3], damagecustom)
{
	if (!IsLivingPlayer(victim) || !IsLivingPlayer(attacker))
		return Plugin_Continue;
	else if (GetClientTeam(victim) == GetClientTeam(attacker))
		return Plugin_Continue; // tends to only pertain to self-damage
	else if (PlayerIsInvincible(victim))
		return Plugin_Continue;
		
	if (SNW_CanUse[attacker] && GetEngineTime() < SNW_StealingUntil[attacker] && (damagetype & DMG_CLUB) != 0)
		SNW_SetClassWeapon(attacker, victim, _:TF2_GetPlayerClass(victim));
		
	return Plugin_Continue;
}

public SNW_SetClassWeapon(clientIdx, victim, classIdx)
{
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return;

	classIdx -= 1; // class 0 is "Unknown"
	classIdx = max(0, classIdx);
	new argOffset = (classIdx + 1) * 10;
	
	static String:weaponName[MAX_WEAPON_NAME_LENGTH];
	static String:weaponArgs[MAX_WEAPON_ARG_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SNW_STRING, argOffset + 1, weaponName, MAX_WEAPON_NAME_LENGTH);
	new weaponIdx = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SNW_STRING, argOffset + 2);
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SNW_STRING, argOffset + 3, weaponArgs, MAX_WEAPON_ARG_LENGTH);
	new weaponVisibility = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SNW_STRING, argOffset + 4);
	new alpha = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SNW_STRING, argOffset + 5);
	
	PrepareForWeaponSwitch(clientIdx, true);
	TF2_RemoveWeaponSlot(clientIdx, SNW_Slot[clientIdx][classIdx]);
	new weapon = SpawnWeapon(clientIdx, weaponName, weaponIdx, 101, 5, weaponArgs, weaponVisibility);
	if (!IsValidEntity(weapon))
	{
		PrintCenterText(clientIdx, "Failed to spawn weapon %s / %d. Notify an admin!", weaponName, weaponIdx);
		return;
	}
	
	// alpha transparency, best if the viewmodel doesn't hold it well
	if (alpha != 255)
	{
		SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
		SetEntityRenderColor(weapon, 255, 255, 255, alpha);
	}
	
	// do not make it the active weapon if Dynamic Parkour is active
	if (!DP_IsLatched(clientIdx))
		SetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon", weapon);
		
	// play a sound on the victim
	static String:soundFile[MAX_SOUND_FILE_LENGTH];
	ReadSound(bossIdx, SNW_STRING, 9 + argOffset, soundFile);
	if (strlen(soundFile) > 3)
		PseudoAmbientSound(victim, soundFile, 1, 1000.0);
		
	// ammo/clip last
	new clip = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SNW_STRING, argOffset + 7);
	new ammo = FF2_GetAbilityArgument(bossIdx, this_plugin_name, SNW_STRING, argOffset + 8);

	new offset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1);
	if (offset >= 0)
	{
		SetEntProp(clientIdx, Prop_Send, "m_iAmmo", ammo, 4, offset);

		// the weirdness below is to avoid setting clips for invalid weapons like huntsman, flamethrower, minigun, and sniper rifles.
		// without the check below, these weapons would break.
		// as for energy weapons, I frankly don't care. they're a mess. don't use this code for making energy weapons.
		if (GetEntProp(weapon, Prop_Send, "m_iClip1") > 1 && GetEntProp(weapon, Prop_Send, "m_iClip1") < 128)
			SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
	}
		
	// delay primary/secondary attack ever so slightly
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.5);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 0.5);
		
	// store what needs to be stored
	SNW_StealingUntil[clientIdx] = 0.0;
	SNW_WeaponEntRef[clientIdx][classIdx] = EntIndexToEntRef(weapon);
	SNW_RemoveWeaponAt[clientIdx][classIdx] = (SNW_WeaponKeepDuration[clientIdx] <= 0.0 ? FAR_FUTURE : (GetEngineTime() + SNW_WeaponKeepDuration[clientIdx]));
	SNW_SuppressedSlot[victim] = SNW_Slot[clientIdx][classIdx];
	SNW_SlotSuppressedUntil[victim] = GetEngineTime() + SNW_SlotSuppressionDuration[clientIdx];
}

public SNW_Tick(Float:curTime)
{
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx))
			continue;
		else if (!SNW_CanUse[clientIdx])
		{
			if (SNW_SuppressedSlot[clientIdx] != -1)
			{
				if (curTime >= SNW_SlotSuppressedUntil[clientIdx])
					SNW_SuppressedSlot[clientIdx] = -1;
				else if (GetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(clientIdx, SNW_SuppressedSlot[clientIdx]))
				{
					for (new slot = 2; slot >= 0; slot--)
					{
						if (slot == SNW_SuppressedSlot[clientIdx])
							continue;
						new weapon = GetPlayerWeaponSlot(clientIdx, slot);
						if (IsValidEntity(weapon))
						{
							PrepareForWeaponSwitch(clientIdx, false);
		
							SetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon", weapon);
							break;
						}
					}
				}
			}
			continue;
		}
			
		// the rest only executes for the hale
		for (new i = 0; i < SNW_NUM_WEAPONS; i++)
		{
			if (SNW_WeaponEntRef[clientIdx][i] == INVALID_ENTREF)
				continue;

			new weapon = EntRefToEntIndex(SNW_WeaponEntRef[clientIdx][i]);
			if (!IsValidEntity(weapon))
			{
				SNW_WeaponEntRef[clientIdx][i] = INVALID_ENTREF;
				continue;
			}

			// this only happens if someone else's weapon spawning code is crap
			new weaponAtSlot = GetPlayerWeaponSlot(clientIdx, SNW_Slot[clientIdx][i]);
			if (weapon != weaponAtSlot)
			{
				if (PRINT_DEBUG_INFO)
					PrintToServer("[sarysapub3] WARNING: Multiple weapons at slot %d. Removing the old weapon. (someone's code sucks)", SNW_Slot[clientIdx][i]);
				AcceptEntityInput(weapon, "kill");
				SNW_WeaponEntRef[clientIdx][i] = INVALID_ENTREF;
				continue;
			}

			new activeWeapon = GetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon");
			if (curTime >= SNW_RemoveWeaponAt[clientIdx][i])
			{
				if (activeWeapon == weapon) // set them to melee
				{
					PrepareForWeaponSwitch(clientIdx, true);
		
					SetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(clientIdx, 2));
				}
				TF2_RemoveWeaponSlot(clientIdx, SNW_Slot[clientIdx][i]);
				SNW_WeaponEntRef[clientIdx][i] = INVALID_ENTREF;
				continue;
			}
		}
	}
}

/**
 * Rage Front Protection
 */
public Rage_FrontProtection(clientIdx)
{
	if (FP_Trigger[clientIdx] != FP_TRIGGER_E)
		return;
		
	FP_Invoke(clientIdx);
}

public bool:FP_CanInvoke(clientIdx)
{
	return true; // no special conditions will prevent this ability
}

public FP_EndRage(clientIdx)
{
	FP_ProtectedUntil[clientIdx] = FAR_FUTURE;
	FP_DamageRemaining[clientIdx] = 0.0;

	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return;

	static String:soundFile[MAX_SOUND_FILE_LENGTH];
	ReadSound(bossIdx, FP_STRING, 7, soundFile);
	if (strlen(soundFile) > 3)
		EmitSoundToAll(soundFile);
		
	if (FP_WearableIdx[clientIdx] > 0 && FP_WearableEntRef[clientIdx] != INVALID_ENTREF)
	{
		new wearable = EntRefToEntIndex(FP_WearableEntRef[clientIdx]);
		if (IsValidEntity(wearable))
			TF2_RemoveWearable(clientIdx, wearable);
		FP_WearableEntRef[clientIdx] = INVALID_ENTREF;
	}

	if (strlen(FP_ShieldedModel[clientIdx]) > 3 && strlen(FP_NormalModel[clientIdx]) > 3)
		SwapModel(clientIdx, FP_NormalModel[clientIdx]);
}

// fun fact: OTDA is completely inaccurate if the target is ubered. (instead of "what if not ubered" damage, it's just the same arbitrary base damage that OTD uses)
public Action:FP_OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:thisneverworks[3], damagecustom)
{
	if (!IsLivingPlayer(victim) || !IsLivingPlayer(attacker))
		return Plugin_Continue;
	else if (!FP_CanUse[victim] || FP_DamageRemaining[victim] == 0.0 || damagecustom == TF_CUSTOM_BACKSTAB)
		return Plugin_Continue;
	else if (TF2_IsPlayerInCondition(victim, TFCond_Ubercharged)) // it still goes through
		return Plugin_Continue;
		
	// need position of either the inflictor or the attacker
	new posEntity = IsValidEntity(inflictor) ? inflictor : attacker;
	static Float:actualDamagePos[3];
	static Float:victimPos[3];
	static Float:angle[3];
	static Float:eyeAngles[3];
	GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
	GetEntPropVector(posEntity, Prop_Send, "m_vecOrigin", actualDamagePos);
	GetVectorAnglesTwoPoints(victimPos, actualDamagePos, angle);
	GetClientEyeAngles(victim, eyeAngles);
	
	// need the yaw offset from the player's POV, and set it up to be between (-180.0..180.0]
	new Float:yawOffset = fixAngle(angle[1]) - fixAngle(eyeAngles[1]);
	if (yawOffset <= -180.0)
		yawOffset += 360.0;
	else if (yawOffset > 180.0)
		yawOffset -= 360.0;
		
	// now it's a simple check
	if (yawOffset >= FP_MinYawBlock[victim] && yawOffset <= FP_MaxYawBlock[victim])
	{
		FP_DamageRemaining[victim] -= damage;
		if (FP_DamageRemaining[victim] <= 0.0)
			FP_EndRage(victim);
		else if (strlen(FP_ShotBlockedSound[victim]) > 3)
		{
			EmitSoundToClient(victim, FP_ShotBlockedSound[victim]);
			EmitSoundToClient(attacker, FP_ShotBlockedSound[victim]);
		}
		damage = 0.0; // intentionally not doing partial damage cutting. entire big hits can be lost even if the shield only has 5HP.
		damagetype |= DMG_PREVENT_PHYSICS_FORCE;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public FP_Invoke(clientIdx)
{
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return;

	// play the sound, which serves as a warning to players
	static String:soundFile[MAX_SOUND_FILE_LENGTH];
	ReadSound(bossIdx, FP_STRING, 8, soundFile);
	if (strlen(soundFile) > 3)
		EmitSoundToAll(soundFile);
		
	// set the settings
	FP_ProtectedUntil[clientIdx] = FP_Duration[clientIdx] <= 0.0 ? FAR_FUTURE : (GetEngineTime() + FP_Duration[clientIdx]);
	FP_DamageRemaining[clientIdx] = FP_Damage[clientIdx];
	
	// toggle bodygroups
	if (FP_WearableIdx[clientIdx] > 0 && FP_WearableEntRef[clientIdx] == INVALID_ENTREF)
	{
		new wearable = SpawnWeapon(clientIdx, "tf_wearable", FP_WearableIdx[clientIdx], 101, 5, "", 1);
		if (IsValidEntity(wearable))
		{
			FP_WearableEntRef[clientIdx] = EntIndexToEntRef(wearable);
			
			// this might seem unnecessary since Valve supposedly hides it, but I was seeing self-wearables on my test server.
			SetEntityRenderMode(wearable, RENDER_TRANSCOLOR);
			SetEntityRenderColor(wearable, 255, 255, 255, 0);
		}
	}

	if (strlen(FP_ShieldedModel[clientIdx]) > 3 && strlen(FP_NormalModel[clientIdx]) > 3)
		SwapModel(clientIdx, FP_ShieldedModel[clientIdx]);
}

public FP_Tick(clientIdx, Float:curTime)
{
	if (curTime >= FP_ProtectedUntil[clientIdx])
		FP_EndRage(clientIdx);
}

/**
 * Rage Fake Dead Ringer
 */
public Rage_FakeDeadRinger(clientIdx)
{
	if (FDR_Trigger[clientIdx] != FDR_TRIGGER_E)
		return;
		
	FDR_Invoke(clientIdx);
}

public bool:FDR_CanInvoke(clientIdx)
{
	return FDR_EndsAt[clientIdx] == FAR_FUTURE;
}

public FDR_Invoke(clientIdx)
{
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return;

	FDR_IsPending[clientIdx] = true;
}

public FDR_EndAbility(clientIdx)
{
	if (FDR_EndsAt[clientIdx] == FAR_FUTURE)
		return; // common concern with the AMS

	FDR_DelayWeaponsBy(clientIdx, FDR_UncloakAttackWait[clientIdx]);
	FDR_EndsAt[clientIdx] = FAR_FUTURE;
	static Float:bossPos[3];
	GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", bossPos);
	bossPos[2] += 41.0;
	EmitAmbientSound(FDR_SOUND, bossPos, clientIdx);
	EmitAmbientSound(FDR_SOUND, bossPos, clientIdx);
	
	if (TF2_IsPlayerInCondition(clientIdx, TFCond_Cloaked))
		TF2_RemoveCondition(clientIdx, TFCond_Cloaked);
	TF2_AddCondition(clientIdx, TFCond_Cloaked, 0.05); // allow for fade out
	if (TF2_IsPlayerInCondition(clientIdx, TFCond_DeadRingered))
		TF2_RemoveCondition(clientIdx, TFCond_DeadRingered);
	if (TF2_IsPlayerInCondition(clientIdx, TFCond_Stealthed))
		TF2_RemoveCondition(clientIdx, TFCond_Stealthed);

	FDR_GoombaBlockedUntil[clientIdx]  = GetEngineTime() + FDR_UncloakAttackWait[clientIdx];
}

public FDR_DelayWeaponsBy(clientIdx, Float:delayTime)
{
	for (new slot = 0; slot <= 2; slot++)
	{
		new weapon = GetPlayerWeaponSlot(clientIdx, slot);
		if (IsValidEntity(weapon))
		{
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + delayTime);
			SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + delayTime);
		}
	}
}

public Action:FDR_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePos[3], damagecustom)
{
	if (!IsLivingPlayer(victim) || !FDR_CanUse[victim])
		return Plugin_Continue;
	else if (FDR_EndsAt[victim] != FAR_FUTURE)
	{
		damage *= 0.1;
		return Plugin_Changed;
	}
	else if (!FDR_IsPending[victim])
		return Plugin_Continue;
	
	damage *= 0.1;
	FDR_FeignDeath(victim);
	return Plugin_Changed;
}

public FDR_FeignDeath(victim)
{
	FDR_IsPending[victim] = false;
	CreateRagdoll(victim, 0.0, false);
	FDR_EndsAt[victim] = GetEngineTime() + FDR_MaxDuration[victim];
	FDR_DelayWeaponsBy(victim, FDR_MaxDuration[victim] + FDR_UncloakAttackWait[victim]);
	SetEntPropFloat(victim, Prop_Send, "m_flCloakMeter", 100.0);
	//TF2_AddCondition(victim, TFCond_Cloaked, FDR_MaxDuration[victim]);
	TF2_AddCondition(victim, TFCond_DeadRingered, FDR_MaxDuration[victim]);
	TF2_AddCondition(victim, TFCond_Stealthed, FDR_MaxDuration[victim]);
	FDR_FirstTick[victim] = true; // trigger things like losing afterburn
}

// this is needed mainly for enforcement, since I doubt the system really enjoys cloaking scouts
public FDR_PreThink(clientIdx)
{
	new Float:curTime = GetEngineTime();

	if (FDR_EndsAt[clientIdx] != FAR_FUTURE)
	{
		if (curTime >= FDR_EndsAt[clientIdx])
			FDR_EndAbility(clientIdx);
		else
		{
			//if (!TF2_IsPlayerInCondition(clientIdx, TFCond_Cloaked))
			//	TF2_AddCondition(clientIdx, TFCond_Cloaked, FDR_MaxDuration[clientIdx]);
			if (!TF2_IsPlayerInCondition(clientIdx, TFCond_DeadRingered))
				TF2_AddCondition(clientIdx, TFCond_DeadRingered, FDR_MaxDuration[clientIdx]);
			if (!TF2_IsPlayerInCondition(clientIdx, TFCond_Stealthed))
				TF2_AddCondition(clientIdx, TFCond_Stealthed, FDR_MaxDuration[clientIdx]);
			if (GetEntPropFloat(clientIdx, Prop_Send, "m_flCloakMeter") != 100.0)
				SetEntPropFloat(clientIdx, Prop_Send, "m_flCloakMeter", 100.0);
				
			if (FDR_FirstTick[clientIdx])
			{
				FDR_FirstTick[clientIdx] = false;
				if (TF2_IsPlayerInCondition(clientIdx, TFCond_OnFire))
					TF2_RemoveCondition(clientIdx, TFCond_OnFire);
				if (TF2_IsPlayerInCondition(clientIdx, TFCond_Bleeding))
					TF2_RemoveCondition(clientIdx, TFCond_Bleeding);
				if (TF2_IsPlayerInCondition(clientIdx, TFCond_MarkedForDeath))
					TF2_RemoveCondition(clientIdx, TFCond_MarkedForDeath);
			}
		}
	}
}

public Action:FDR_OnStomp(attacker, victim, &Float:damageMultiplier, &Float:damageBonus, &Float:JumpPower)
{
	if (FDR_CanUse[attacker])
	{
		if (FDR_EndsAt[attacker] != FAR_FUTURE || GetEngineTime() < FDR_GoombaBlockedUntil[attacker])
			return Plugin_Handled;
	}
	else if (FDR_CanUse[victim])
	{
		if (FDR_IsPending[victim])
		{
			FDR_FeignDeath(victim);
			damageMultiplier *= 0.1;
			damageBonus *= 0.1;
			return Plugin_Changed;
		}
		else if (FDR_EndsAt[victim] != FAR_FUTURE)
		{
			damageMultiplier *= 0.1;
			damageBonus *= 0.1;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

/**
 * Rage Dodge Specific Damage
 */
public Action:DSD_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePos[3], damagecustom)
{
	if (!IsLivingPlayer(victim) || !DSD_CanUse[victim])
		return Plugin_Continue;
		
	if (DSD_ActiveUntil[victim] != FAR_FUTURE && GetEngineTime() < DSD_ActiveUntil[victim])
	{
		if ((DSD_DodgeBullets[victim] && (damagetype & (DMG_BULLET | DMG_BUCKSHOT) != 0)) ||
			(DSD_DodgeBlast[victim] && (damagetype & (DMG_BLAST) != 0)) ||
			(DSD_DodgeFire[victim] && (damagetype & (DMG_BURN) != 0)) ||
			(DSD_DodgeMelee[victim] && (damagetype & (DMG_CLUB) != 0)))
		{
			damage = 0.0;
			damagetype |= DMG_PREVENT_PHYSICS_FORCE;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public Rage_DodgeSpecificDamage(clientIdx)
{
	if (DSD_Trigger[clientIdx] != DSD_TRIGGER_E)
		return;
		
	DSD_Invoke(clientIdx);
}

public bool:DSD_CanInvoke(clientIdx)
{
	return true;
}

public DSD_Invoke(clientIdx)
{
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return;

	DSD_ActiveUntil[clientIdx] = GetEngineTime() + DSD_Duration[clientIdx];
	if (DSD_ReplaySpeed[clientIdx] > 0.0)
	{
		DSD_UpdateClientCheatValue(1);
		SetConVarFloat(cvarTimeScale, DSD_ReplaySpeed[clientIdx]);
	}
	if (DSD_MoveSpeed[clientIdx] > 0.0)
		DSM_SetOverrideSpeed(clientIdx, DSD_MoveSpeed[clientIdx]);

	static String:soundFile[MAX_SOUND_FILE_LENGTH];
	ReadSound(bossIdx, DSD_STRING, 9, soundFile);
	if (strlen(soundFile) > 3)
		EmitSoundToAll(soundFile);
}

public DSD_Tick(clientIdx, Float:curTime)
{
	if (DSD_ActiveUntil[clientIdx] == FAR_FUTURE)
		return;
		
	if (curTime >= DSD_ActiveUntil[clientIdx])
	{
		DSD_ActiveUntil[clientIdx] = FAR_FUTURE;
		if (DSD_ReplaySpeed[clientIdx] > 0.0)
		{
			SetConVarFloat(cvarTimeScale, 1.0);
			DSD_UpdateClientCheatValue(0);
		}
		if (DSD_MoveSpeed[clientIdx] > 0.0)
			DSM_SetOverrideSpeed(clientIdx);
	}
}

// By Mecha the Slag, lifted from 1st set abilities and tweaked
DSD_UpdateClientCheatValue(valueInt)
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

/**
 * Rage AMS Dynamic Teleport
 */
public Rage_AMSDynamicTeleport(clientIdx)
{
	if (ADT_Trigger[clientIdx] != ADT_TRIGGER_E)
		return;
		
	ADT_Invoke(clientIdx);
}

public bool:ADT_CanInvoke(clientIdx)
{
	if (ADT_MaxEnemiesToFunction[clientIdx] == 0)
		return true;
		
	new numPlayers = 0;
	new enemyTeam = GetClientTeam(clientIdx) == BossTeam ? MercTeam : BossTeam; // why the fuck are mercs allowed on BLU? seriously. WHY THE FUCK.
	for (new enemy = 1; enemy < MAX_PLAYERS; enemy++)
	{
		if (IsLivingPlayer(enemy) && GetClientTeam(enemy) == enemyTeam)
			numPlayers++;
	}
	return numPlayers <= ADT_MaxEnemiesToFunction[clientIdx];
}

public ADT_Invoke(clientIdx)
{
	new bossIdx = FF2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return;

	// perform the teleport
	DD_PerformTeleport(clientIdx, ADT_SelfStunDuration[clientIdx], ADT_TeleportTop[clientIdx], ADT_TeleportSide[clientIdx], false, false);

	// play the sound
	static String:soundFile[MAX_SOUND_FILE_LENGTH];
	ReadSound(bossIdx, ADT_STRING, 5, soundFile);
	if (strlen(soundFile) > 3)
		EmitSoundToAll(soundFile);
}

/**
 * OnPlayerRunCmd/OnGameFrame, with special guest OnStomp
 */
public OnGameFrame()
{
	if (!RoundInProgress)
		return;
		
	new Float:curTime = GetEngineTime();
	
	if (RRW_ActiveThisRound || FP_ActiveThisRound || DSD_ActiveThisRound)
	{
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (!IsLivingPlayer(clientIdx))
				continue;
		
			if (RRW_CanUse[clientIdx])
				RRW_Tick(clientIdx, curTime);
			if (FP_CanUse[clientIdx])
				FP_Tick(clientIdx, curTime);
			if (DSD_CanUse[clientIdx])
				DSD_Tick(clientIdx, curTime);
		}
	}
	
	if (SNW_ActiveThisRound)
		SNW_Tick(curTime);
}
 
public Action:OnPlayerRunCmd(clientIdx, &buttons, &impulse, Float:vel[3], Float:unusedangles[3], &weapon)
{
	if (!RoundInProgress)
		return Plugin_Continue;
	else if (!IsLivingPlayer(clientIdx))
		return Plugin_Continue;
		
	if (AMS_ActiveThisRound && AMS_CanUse[clientIdx])
		AMS_Tick(clientIdx, buttons, GetEngineTime());

	return Plugin_Continue;
}

public Action:OnStomp(attacker, victim, &Float:damageMultiplier, &Float:damageBonus, &Float:JumpPower)
{
	return FDR_OnStomp(attacker, victim, damageMultiplier, damageBonus, JumpPower);
}

/**
 * General helper stocks, some original, some taken/modified from other sources
 */
stock PlaySoundLocal(clientIdx, String:soundPath[], bool:followPlayer = true, stack = 1)
{
	// play a speech sound that travels normally, local from the player.
	decl Float:playerPos[3];
	GetClientEyePosition(clientIdx, playerPos);
	//PrintToServer("[sarysapub3] eye pos=%f,%f,%f     sound=%s", playerPos[0], playerPos[1], playerPos[2], soundPath);
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

// need to briefly stun the target if they have continuous or other special weapons out
// these weapons can do so much as crash the user's client if they're quick switched
// the stun-unstun will prevent this from happening, but it may or may not stop the target's motion if on ground
stock PrepareForWeaponSwitch(clientIdx, bool:isBoss)
{
	new primary = GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Primary);
	if (!IsValidEntity(primary) || primary != GetEntPropEnt(clientIdx, Prop_Send, "m_hActiveWeapon"))
		return;
	
	new bool:shouldStun = false;
	static String:restoreClassname[MAX_ENTITY_CLASSNAME_LENGTH];
	new itemDefinitionIndex = -1;
	if (EntityStartsWith(primary, "tf_weapon_minigun") || EntityStartsWith(primary, "tf_weapon_compound_bow"))
	{
		//SetEntProp(primary, Prop_Send, "m_iWeaponState", 0);
		if (!isBoss)
		{
			GetEntityClassname(primary, restoreClassname, MAX_ENTITY_CLASSNAME_LENGTH);
			itemDefinitionIndex = GetEntProp(primary, Prop_Send, "m_iItemDefinitionIndex");
			TF2_RemoveWeaponSlot(clientIdx, TFWeaponSlot_Primary);
		}
		shouldStun = true;
	}
	else if (EntityStartsWith(primary, "tf_weapon_sniperrifle") || EntityStartsWith(primary, "tf_weapon_flamethrower"))
		shouldStun = true;

	if (shouldStun)
	{
		TF2_StunPlayer(clientIdx, 0.1, 0.0, TF_STUNFLAG_BONKSTUCK | TF_STUNFLAG_NOSOUNDOREFFECT);
		TF2_RemoveCondition(clientIdx, TFCond_Dazed);
	}
	
	if (itemDefinitionIndex != -1)
	{
		if (!strcmp(restoreClassname, "tf_weapon_compound_bow"))
		{
//			SpawnWeapon(clientIdx, restoreClassname, itemDefinitionIndex, 5, 10, "37 ; 0.5 ; 328 ; 1.0 ; 2 ; 1.5", 1, true);
			SpawnWeapon(clientIdx, restoreClassname, itemDefinitionIndex, 5, 10, "2 ; 1.5", 1, true);
		}
		else
		{
			switch (itemDefinitionIndex)
			{
//				case 312: // brass beast
//					SpawnWeapon(clientIdx, restoreClassname, itemDefinitionIndex, 5, 10, "2 ; 1.2 ; 86 ; 1.5 ; 183 ; 0.4", 1, true);
//				case 424: // tomislav
//					SpawnWeapon(clientIdx, restoreClassname, itemDefinitionIndex, 5, 10, "5 ; 1.1 ; 87 ; 1.1 ; 238 ; 1 ; 375 ; 50", 1, true);
//				case 811, 832: // huo-long heater
//					SpawnWeapon(clientIdx, restoreClassname, itemDefinitionIndex, 5, 10, "430 ; 15.0 ; 431 ; 6.0 ; 153 ; 1.0", 1, true);
				default:
					SpawnWeapon(clientIdx, restoreClassname, itemDefinitionIndex, 5, 10, "", 1, true);
			}
		}
	}
}

#if !defined _FF2_Extras_included
stock SpawnWeapon(client, String:name[], index, level, quality, String:attribute[], visible = 1, bool:preserve = false)
{
	new Handle:weapon = TF2Items_CreateItem((preserve ? PRESERVE_ATTRIBUTES : OVERRIDE_ALL) | FORCE_GENERATION);
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
	
	// sarysa addition
	if (!visible)
	{
		SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
	}
	
	if (StrContains(name, "tf_wearable") != 0)
		EquipPlayerWeapon(client, entity);
	else
		Wearable_EquipWearable(client, entity);
	return entity;
}

new Handle:S93SF_equipWearable = INVALID_HANDLE;
stock Wearable_EquipWearable(client, wearable)
{
	if(S93SF_equipWearable==INVALID_HANDLE)
	{
		new Handle:config=LoadGameConfigFile("equipwearable");
		if(config==INVALID_HANDLE)
		{
			LogError("[FF2] EquipWearable gamedata could not be found; make sure /gamedata/equipwearable.txt exists.");
			return;
		}

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(config, SDKConf_Virtual, "EquipWearable");
		CloseHandle(config);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		if((S93SF_equipWearable=EndPrepSDKCall())==INVALID_HANDLE)
		{
			LogError("[FF2] Couldn't load SDK function (CTFPlayer::EquipWearable). SDK call failed.");
			return;
		}
	}
	SDKCall(S93SF_equipWearable, client, wearable);
}
#endif

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
			PrintToServer("[sarysapub3] Hit player %d on trace.", entity);
		return true;
	}

	return false;
}

public bool:TraceRedPlayersAndBuildings(entity, contentsMask)
{
	if (IsLivingPlayer(entity) && GetClientTeam(entity) != BossTeam)
	{
		if (PRINT_DEBUG_SPAM)
			PrintToServer("[sarysapub3] Hit player %d on trace.", entity);
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
			PrintToServer("[sarysapub3] How the hell is volume greater than 1.0?");
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

stock bool:EntityStartsWith(entity, const String:desiredPrefix[])
{
	static String:classname[MAX_ENTITY_CLASSNAME_LENGTH];
	GetEntityClassname(entity, classname, MAX_ENTITY_CLASSNAME_LENGTH);
	return StrContains(classname, desiredPrefix) == 0;
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

SwapModel(clientIdx, const String:model[])
{
	// standard important check here...
	if (!IsClientInGame(clientIdx) || !IsPlayerAlive(clientIdx))
		return;
		
	SetVariantString(model);
	AcceptEntityInput(clientIdx, "SetCustomModel");
	SetEntProp(clientIdx, Prop_Send, "m_bUseClassAnimations", 1);
}

/**
 * Taken from Roll the Dice mod by bl4nk
 */
CreateRagdoll(client, Float:flSelfDestruct=0.0, bool:isIce=false)
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
		if (isIce)
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