#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <sdkhooks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <drain_over_time>
#include <drain_over_time_subplugin>

/**
 * Some default drain over time rages. It's a good example if you want to make your own.
 * Requires the drain over time platform:
 * - drain_over_time.sp
 * - drain_over_time.inc
 * - drain_over_time_subplugin.inc
 *
 * Known Issues:
 * - This is NOT the original source code, this is a rewriten decompiled binary,
 *   issues might be expected with possibility of missing/broken code and such.
 * 
 * Credits:
 * - Most of the work: sarysa
 * - Special thanks to Skeith and Kralthe for testing the manic mode (weapon switch) stuff.
 */
 
new BossTeam = _:TFTeam_Blue;

// change this to minimize console output
new PRINT_DEBUG_INFO = true;

// for getting things off the map that have an undesirable destruction delay (i.e. certain particle effects)
new Float:OFF_THE_MAP[3] = { 16383.0, 16383.0, -16383.0 };

#define MAX_PLAYERS_ARRAY 33
#define MAX_PLAYERS (MAX_PLAYERS_ARRAY < (MaxClients + 1) ? MAX_PLAYERS_ARRAY : (MaxClients + 1))

// this is very generous as really only VSH servers with the RTD mod would have this many
// (RTD allows temporary sentries and permanent dispensers to be spawned by non-engineers)
#define MAX_BUILDINGS 32

// text string limits. I've set these as low as reasonably possible.
// Enumerated strings are VERY wasteful. every character is 4 bytes!
// but the only way to get something resembling a struct is using the enumeration trick below.
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

new RoundInProgress;
new bool:PluginActiveThisRound;
new bool:BEAM_ActiveThisRound;
new bool:BEAM_CanUse[MAX_PLAYERS_ARRAY];
new bool:BEAM_IsUsing[MAX_PLAYERS_ARRAY];
new BEAM_TicksActive[MAX_PLAYERS_ARRAY];
new BEAM_LightingEntityRef[MAX_PLAYERS_ARRAY];
new BEAM_UserGlowEntityRef[MAX_PLAYERS_ARRAY];
new BEAM_AttachmentEntRef[MAX_PLAYERS_ARRAY];
new Beam_Laser;
new Beam_Glow;
new Float:BEAM_CloseDPT[MAX_PLAYERS_ARRAY];
new Float:BEAM_FarDPT[MAX_PLAYERS_ARRAY];
new BEAM_MaxDistance[MAX_PLAYERS_ARRAY];
new BEAM_BeamRadius[MAX_PLAYERS_ARRAY];
new BEAM_ColorHex[MAX_PLAYERS_ARRAY];
new BEAM_ChargeUpTime[MAX_PLAYERS_ARRAY];
new BEAM_WindDownTime[MAX_PLAYERS_ARRAY];
new String:BEAM_ChargeUpSound[MAX_PLAYERS_ARRAY][MAX_SOUND_FILE_LENGTH];
new String:BEAM_FiringSound[MAX_PLAYERS_ARRAY][MAX_SOUND_FILE_LENGTH];
new BEAM_FiringSoundLength[MAX_PLAYERS_ARRAY];
new String:BEAM_WindDownSound[MAX_PLAYERS_ARRAY][MAX_SOUND_FILE_LENGTH];
new Float:BEAM_CloseBuildingDPT[MAX_PLAYERS_ARRAY];
new Float:BEAM_FarBuildingDPT[MAX_PLAYERS_ARRAY];
new String:BEAM_WindDownStunGraphic[MAX_PLAYERS_ARRAY][MAX_EFFECT_NAME_LENGTH];
new bool:BEAM_DisablePreBeam[MAX_PLAYERS_ARRAY];
new bool:BEAM_AllowStun[MAX_PLAYERS_ARRAY];
new bool:BEAM_PreventCharge[MAX_PLAYERS_ARRAY];
new Float:BEAM_BeamOffset[MAX_PLAYERS_ARRAY][3];
new Float:BEAM_ZOffset[MAX_PLAYERS_ARRAY];
new bool:MM_ActiveThisRound;
new bool:MM_CanUse[MAX_PLAYERS_ARRAY];
new bool:MM_IsUsing[MAX_PLAYERS_ARRAY];
new String:MM_NormalModeModelSwap[MAX_PLAYERS_ARRAY][MAX_MODEL_FILE_LENGTH];
new String:MM_ManicModeWeaponName[MAX_PLAYERS_ARRAY][MAX_WEAPON_NAME_LENGTH];
new MM_ManicModeWeaponIdx[MAX_PLAYERS_ARRAY];
new String:MM_ManicModeWeaponArgs[MAX_PLAYERS_ARRAY][MAX_WEAPON_ARG_LENGTH];
new MM_ManicModeWeaponVisibility[MAX_PLAYERS_ARRAY];
new String:MM_NormalModeWeaponName[MAX_PLAYERS_ARRAY][MAX_WEAPON_NAME_LENGTH];
new MM_NormalModeWeaponIdx[MAX_PLAYERS_ARRAY];
new String:MM_NormalModeWeaponArgs[MAX_PLAYERS_ARRAY][MAX_WEAPON_ARG_LENGTH];
new MM_NormalModeWeaponVisibility[MAX_PLAYERS_ARRAY];
new bool:MM_SentryKnockbackImmune[MAX_PLAYERS_ARRAY];
new String:MM_ManicModeModelSwap[MAX_PLAYERS_ARRAY][MAX_MODEL_FILE_LENGTH];

public Plugin:myinfo =
{
	name = "Freak Fortress 2: Default DOTs",
	author = "sarysa",
	version = "1.1.3"
};

new bool:BEAM_HitDetected[MAX_PLAYERS_ARRAY];
new BEAM_BuildingHit[32];

public OnPluginStart2()
{
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	Beam_Laser = PrecacheModel("materials/sprites/laser.vmt", false);
	Beam_Glow = PrecacheModel("sprites/glow02.vmt", true);
	return;
}

public Action:FF2_OnAbility2(index, const String:plugin_name[], const String:ability_name[], status)
{
	return Plugin_Continue;
}

public Action:Event_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	RoundInProgress = 1;
	PluginActiveThisRound = false;
	BEAM_ActiveThisRound = false;
	MM_ActiveThisRound = false;
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		BEAM_CanUse[clientIdx] = false;
		BEAM_IsUsing[clientIdx] = false;
		BEAM_TicksActive[clientIdx] = 0;
		BEAM_LightingEntityRef[clientIdx] = -1;
		BEAM_UserGlowEntityRef[clientIdx] = -1;
		BEAM_AttachmentEntRef[clientIdx] = -1;
		MM_CanUse[clientIdx] = false;
		MM_IsUsing[clientIdx] = false;
		MM_SentryKnockbackImmune[clientIdx] = false;
	}
	return Plugin_Continue;
}

public Action:Event_RoundEnd(Handle:event, String:name[], bool:dontBroadcast)
{
	RoundInProgress = 0;
	if (BEAM_ActiveThisRound)
	{
		BEAM_ActiveThisRound = false;
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (BEAM_CanUse[clientIdx])
			{
				if (BEAM_LightingEntityRef[clientIdx] != -1)
				{
					RemoveEntityDA(INVALID_HANDLE, BEAM_LightingEntityRef[clientIdx]);
					BEAM_LightingEntityRef[clientIdx] = -1;
				}
				if (BEAM_UserGlowEntityRef[clientIdx] != -1)
				{
					DestroyEntity(INVALID_HANDLE, BEAM_UserGlowEntityRef[clientIdx]);
					BEAM_UserGlowEntityRef[clientIdx] = -1;
				}
				SetEntityMoveType(clientIdx, MoveType:2);
			}
		}
	}
	if (MM_ActiveThisRound)
	{
		MM_ActiveThisRound = false;
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (MM_CanUse[clientIdx])
			{
				if (IsClientInGame(clientIdx))
				{
					SDKUnhook(clientIdx, SDKHook_OnTakeDamage, MM_OnTakeDamage);
				}
				MM_CanUse[clientIdx] = false;
			}
		}
	}
	return Plugin_Continue;
}

DOTPostRoundStartInit()
{
	if (!RoundInProgress)
	{
		PrintToChatAll("DOTPostRoundStartInit() called when the round is over?! Shouldn't be possible!");
		return;
	}
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		new bossIdx = FF2_GetBossIndex(clientIdx);
		if (0 >= bossIdx)
		{
			BEAM_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, "dot_beam");
			if (BEAM_CanUse[clientIdx])
			{
				PluginActiveThisRound = true;
				BEAM_ActiveThisRound = true;
				BEAM_CloseDPT[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "dot_beam", 1, 0.0);
				BEAM_FarDPT[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "dot_beam", 2, 0.0);
				BEAM_MaxDistance[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, "dot_beam", 3, 0);
				BEAM_BeamRadius[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, "dot_beam", 4, 0);
				decl String:color[8];
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, "dot_beam", 5, color, 7);
				BEAM_ColorHex[clientIdx] = ParseColor(color);
				BEAM_ChargeUpTime[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, "dot_beam", 6, 0) / 100;
				BEAM_WindDownTime[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, "dot_beam", 7, 0) / 1000;
				ReadSound(bossIdx, "dot_beam", 8, BEAM_ChargeUpSound[clientIdx]);
				ReadSound(bossIdx, "dot_beam", 9, BEAM_FiringSound[clientIdx]);
				BEAM_FiringSoundLength[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, "dot_beam", 10, 0) / 100;
				ReadSound(bossIdx, "dot_beam", 11, BEAM_WindDownSound[clientIdx]);
				BEAM_CloseBuildingDPT[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "dot_beam", 12, 0.0);
				BEAM_FarBuildingDPT[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "dot_beam", 13, 0.0);
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, "dot_beam", 14, BEAM_WindDownStunGraphic[clientIdx], 48);
				new flags = FF2_GetAbilityArgument(bossIdx, this_plugin_name, "dot_beam", 15, 0);
				BEAM_DisablePreBeam[clientIdx] = flags & 1 == 1;
				BEAM_AllowStun[clientIdx] = flags & 2 == 2;
				BEAM_PreventCharge[clientIdx] = flags & 4 == 4;
				if (PRINT_DEBUG_INFO)
				{
					PrintToChatAll("[%s] BEAM flags: disablePreBeam=%d  allowStun=%d  preventCharge=%d", this_plugin_name, BEAM_DisablePreBeam[clientIdx], BEAM_AllowStun[clientIdx], BEAM_PreventCharge[clientIdx]);
				}
				new String:vectorStr[40];
				new String:vectorStrs[3][12];
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, "dot_beam", 16, vectorStr, 40);
				if (strlen(vectorStr) > 4)
				{
					ExplodeString(vectorStr, ",", vectorStrs, 3, 12, false);
					BEAM_BeamOffset[clientIdx][0] = StringToFloat(vectorStrs[0]);
					BEAM_BeamOffset[clientIdx][1] = StringToFloat(vectorStrs[1]);
					BEAM_BeamOffset[clientIdx][2] = StringToFloat(vectorStrs[2]);
				}
				Beam_Laser = PrecacheModel("materials/sprites/laser.vmt", false);
				Beam_Glow = PrecacheModel("sprites/glow02.vmt", true);
				static String:attachmentName[48];
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, "dot_beam", 17, attachmentName, 48);
				if (strlen(attachmentName[0]))
				{
					new attachmentParticle = AttachParticleToAttachment(clientIdx, "", attachmentName);
					if (IsValidEntity(attachmentParticle))
					{
						BEAM_AttachmentEntRef[clientIdx] = EntIndexToEntRef(attachmentParticle);
						if (PRINT_DEBUG_INFO)
						{
							PrintToChatAll("[%s] Beam will use valid attachment point %s.", this_plugin_name, attachmentName);
						}
					}
					else
					{
						PrintToChatAll("[%s] WARNING: Attachment point %s is missing. Beam will fall back to offset coords.", this_plugin_name, attachmentName);
					}
				}
				BEAM_ZOffset[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, "dot_beam", 18, 0.0);
				if (PRINT_DEBUG_INFO)
				{
					PrintToChatAll("[%s] Beam initialized for client %d, Damage is %f~%f, Distance is %d, chargetime=%d, winddowntime=%d", this_plugin_name, clientIdx, BEAM_CloseDPT[clientIdx], BEAM_FarDPT[clientIdx], BEAM_MaxDistance[clientIdx], BEAM_ChargeUpTime[clientIdx], BEAM_WindDownTime[clientIdx]);
				}
			}
			MM_CanUse[clientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, "rage_manic_mode");
			if (MM_CanUse[clientIdx])
			{
				PluginActiveThisRound = true;
				MM_ActiveThisRound = true;
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, "rage_manic_mode", 1, MM_ManicModeWeaponName[clientIdx], 40);
				MM_ManicModeWeaponIdx[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, "rage_manic_mode", 2, 0);
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, "rage_manic_mode", 3, MM_ManicModeWeaponArgs[clientIdx], 256);
				MM_ManicModeWeaponVisibility[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, "rage_manic_mode", 4, 0);
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, "rage_manic_mode", 5, MM_NormalModeWeaponName[clientIdx], 40);
				MM_NormalModeWeaponIdx[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, "rage_manic_mode", 6, 0);
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, "rage_manic_mode", 7, MM_NormalModeWeaponArgs[clientIdx], 256);
				MM_NormalModeWeaponVisibility[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, "rage_manic_mode", 8, 0);
				MM_SentryKnockbackImmune[clientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, "rage_manic_mode", 9, 0) == 1;
				ReadModel(bossIdx, "rage_manic_mode", 10, MM_ManicModeModelSwap[clientIdx]);
				GetEntPropString(clientIdx, Prop_Data, "m_ModelName", MM_NormalModeModelSwap[clientIdx], 80, 0);
				MM_IsUsing[clientIdx] = false;
				SwitchWeapon(clientIdx, MM_NormalModeWeaponName[clientIdx], MM_NormalModeWeaponIdx[clientIdx], MM_NormalModeWeaponArgs[clientIdx], MM_NormalModeWeaponVisibility[clientIdx]);
				SDKHook(clientIdx, SDKHook_OnTakeDamage, MM_OnTakeDamage);
				if (PRINT_DEBUG_INFO)
				{
					PrintToChatAll("[%s] Manic Mode initialized for client %d", this_plugin_name, clientIdx);
				}
			}
		}
	}
}

OnDOTAbilityActivated(clientIdx)
{
	if (!PluginActiveThisRound)
	{
		return;
	}
	if (BEAM_CanUse[clientIdx])
	{
		if (PRINT_DEBUG_INFO)
		{
			PrintToChatAll("[%s] %d is charging Beam.", this_plugin_name, clientIdx);
		}
		BEAM_IsUsing[clientIdx] = true;
		BEAM_TicksActive[clientIdx] = 0;
		SetEntityMoveType(clientIdx, MoveType:0);
		float startPoint[3];
		GetClientEyePosition(clientIdx, startPoint);
		startPoint[2] -= 25.0;
		BEAM_UserGlowEntityRef[clientIdx] = EntIndexToEntRef(ParticleEffectAt(startPoint, "ghost_glow", 0.0));
		if (strlen(BEAM_ChargeUpSound[clientIdx]) > 3)
		{
			EmitSoundToAll(BEAM_ChargeUpSound[clientIdx], -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
	}
	if (MM_CanUse[clientIdx])
	{
		if (PRINT_DEBUG_INFO)
		{
			PrintToChatAll("[%s] %d entered Manic Mode.", this_plugin_name, clientIdx);
		}
		SwitchWeapon(clientIdx, MM_ManicModeWeaponName[clientIdx], MM_ManicModeWeaponIdx[clientIdx], MM_ManicModeWeaponArgs[clientIdx], MM_ManicModeWeaponVisibility[clientIdx]);
		if (strlen(MM_ManicModeModelSwap[clientIdx]) > 3)
		{
			SwapModel(clientIdx, MM_ManicModeModelSwap[clientIdx]);
		}
		MM_IsUsing[clientIdx] = true;
	}
	return;
}

OnDOTAbilityDeactivated(clientIdx)
{
	if (!PluginActiveThisRound)
	{
		return;
	}
	if (BEAM_CanUse[clientIdx])
	{
		if (PRINT_DEBUG_INFO)
		{
			PrintToChatAll("[%s] %d stopped using beam.", this_plugin_name, clientIdx);
		}
		new Float:ZeroVec[3] = 0.0;
		TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, ZeroVec);
		if (strlen(BEAM_WindDownSound[clientIdx]) > 3)
		{
			EmitSoundToAll(BEAM_WindDownSound[clientIdx], -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
		BEAM_IsUsing[clientIdx] = false;
		SetEntityMoveType(clientIdx, MoveType:2);
		if (BEAM_LightingEntityRef[clientIdx] != -1)
		{
			RemoveEntityDA(INVALID_HANDLE, BEAM_LightingEntityRef[clientIdx]);
			BEAM_LightingEntityRef[clientIdx] = -1;
		}
		if (BEAM_UserGlowEntityRef[clientIdx] != -1)
		{
			DestroyEntity(INVALID_HANDLE, BEAM_UserGlowEntityRef[clientIdx]);
			BEAM_UserGlowEntityRef[clientIdx] = -1;
		}
		if (0 < BEAM_WindDownTime[clientIdx])
		{
			TF2_StunPlayer(clientIdx, float(BEAM_WindDownTime[clientIdx]), 0.0, 34, 0);
			if (strlen(BEAM_WindDownStunGraphic[clientIdx]) > 3)
			{
				new particle = AttachParticle(clientIdx, BEAM_WindDownStunGraphic[clientIdx], 75.0, true);
				if (IsValidEntity(particle))
				{
					CreateTimer(float(BEAM_WindDownTime[clientIdx]), RemoveEntityDA, EntIndexToEntRef(particle), 2);
				}
			}
		}
		BEAM_TicksActive[clientIdx] = 0;
	}
	if (MM_CanUse[clientIdx])
	{
		if (PRINT_DEBUG_INFO)
		{
			PrintToChatAll("[%s] %d exited Manic Mode.", this_plugin_name, clientIdx);
		}
		SwitchWeapon(clientIdx, MM_NormalModeWeaponName[clientIdx], MM_NormalModeWeaponIdx[clientIdx], MM_NormalModeWeaponArgs[clientIdx], MM_NormalModeWeaponVisibility[clientIdx]);
		if (strlen(MM_ManicModeModelSwap[clientIdx]) > 3)
		{
			SwapModel(clientIdx, MM_NormalModeModelSwap[clientIdx]);
		}
		MM_IsUsing[clientIdx] = false;
	}
	return;
}

OnDOTUserDeath(clientIdx, isInGame)
{
	if (!PluginActiveThisRound)
	{
		return;
	}
	if (BEAM_CanUse[clientIdx])
	{
		BEAM_IsUsing[clientIdx] = false;
		if (BEAM_LightingEntityRef[clientIdx] != -1)
		{
			RemoveEntityDA(INVALID_HANDLE, BEAM_LightingEntityRef[clientIdx]);
			BEAM_LightingEntityRef[clientIdx] = -1;
		}
		if (BEAM_UserGlowEntityRef[clientIdx] != -1)
		{
			DestroyEntity(INVALID_HANDLE, BEAM_UserGlowEntityRef[clientIdx]);
			BEAM_UserGlowEntityRef[clientIdx] = -1;
		}
	}
	return;
}

OnDOTAbilityTick(clientIdx, tickCount)
{
	if (!PluginActiveThisRound)
	{
		return;
	}
	if (BEAM_CanUse[clientIdx])
	{
		if (TF2_IsPlayerInCondition(clientIdx, TFCond:15) && !BEAM_AllowStun[clientIdx])
		{
			ForceDOTAbilityDeactivation(clientIdx);
		}
		TickBeam(clientIdx, tickCount);
	}
	return;
}

public bool:BEAM_TraceWallsOnly(entity, contentsMask)
{
	return !entity;
}

public bool:BEAM_TraceUsers(entity, contentsMask)
{
	static String:entityClassname[64];
	if (IsLivingPlayer(entity))
	{
		BEAM_HitDetected[entity] = true;
	}
	else
	{
		if (0 < entity)
		{
			GetEntityClassname(entity, entityClassname, 64);
			if (!strcmp("obj_sentrygun", entityClassname, true) || !strcmp("obj_dispenser", entityClassname, true) || !strcmp("obj_teleporter", entityClassname, true))
			{
				new i;
				while (i < 32)
				{
					if (!BEAM_BuildingHit[i])
					{
						BEAM_BuildingHit[i] = entity;
					}
					if (!(entity == BEAM_BuildingHit[i]))
					{
						if (i == 31)
						{
							PrintToChatAll("[%s] Warning: Somehow, more than %d buildings were caught in a single beam. Can't damage them all.", this_plugin_name);
						}
						i++;
					}
				}
			}
		}
	}
	return false;
}

public Action:OnPlayerRunCmd(clientIdx, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!PluginActiveThisRound || !BEAM_ActiveThisRound)
	{
		return Plugin_Continue;
	}
	if (!IsLivingPlayer(clientIdx) || BossTeam != GetClientTeam(clientIdx))
	{
		return Plugin_Continue;
	}
	if (BEAM_CanUse[clientIdx] && BEAM_IsUsing[clientIdx] && BEAM_PreventCharge[clientIdx])
	{
		buttons = buttons & -2049;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

GetBeamDrawStartPoint(clientIdx, Float:startPoint[3])
{
	if (BEAM_AttachmentEntRef[clientIdx] != -1)
	{
		new particle = EntRefToEntIndex(BEAM_AttachmentEntRef[clientIdx]);
		if (!IsValidEntity(particle))
		{
			BEAM_AttachmentEntRef[clientIdx] = -1;
		}
		else
		{
			GetEntPropVector(particle, Prop_Data, "m_vecAbsOrigin", startPoint, 0);
			startPoint[2] = BEAM_ZOffset[clientIdx];
		}
	}
	if (BEAM_AttachmentEntRef[clientIdx] == -1)
	{
		GetClientEyePosition(clientIdx, startPoint);
		new Float:angles[3] = 0.0;
		GetClientEyeAngles(clientIdx, angles);
		startPoint[2] -= 25.0;
		if (0.0 == BEAM_BeamOffset[clientIdx][0] && 0.0 == BEAM_BeamOffset[clientIdx][1] && 0.0 == BEAM_BeamOffset[clientIdx][2])
		{
			return;
		}
		new Float:tmp[3] = 0.0;
		new Float:actualBeamOffset[3] = 0.0;
		tmp[0] = BEAM_BeamOffset[clientIdx][0];
		tmp[1] = BEAM_BeamOffset[clientIdx][1];
		tmp[2] = 0.0;
		VectorRotate(tmp, angles, actualBeamOffset);
		actualBeamOffset[2] = BEAM_BeamOffset[clientIdx][2];
		startPoint[0] += actualBeamOffset[0];
		startPoint[1] += actualBeamOffset[1];
		startPoint[2] += actualBeamOffset[2];
	}
	return;
}

TickBeam(clientIdx, tickCount)
{
	BEAM_TicksActive[clientIdx] = tickCount;
	new Float:diameter = float(BEAM_BeamRadius[clientIdx] * 2);
	new r = GetR(BEAM_ColorHex[clientIdx]);
	new g = GetG(BEAM_ColorHex[clientIdx]);
	new b = GetB(BEAM_ColorHex[clientIdx]);
	/*new r = GetRandomInt(1, 254);
	new g = GetRandomInt(1, 254);	// This was just for fun
	new b = GetRandomInt(1, 254);*/
	if (tickCount < BEAM_ChargeUpTime[clientIdx] * 2 && !BEAM_DisablePreBeam[clientIdx])
	{
		static Float:startPoint[3];
		static Float:endPoint[3];
		GetBeamDrawStartPoint(clientIdx, startPoint);
		endPoint[0] = startPoint[0];
		endPoint[1] = startPoint[1];
		endPoint[2] = float(BEAM_MaxDistance[clientIdx]);
		if (BEAM_ChargeUpTime[clientIdx] > tickCount)
		{
			startPoint[2] += BEAM_MaxDistance[clientIdx] - tickCount * BEAM_MaxDistance[clientIdx] / BEAM_ChargeUpTime[clientIdx];
		}
		else
		{
			if (BEAM_ChargeUpTime[clientIdx] < tickCount)
			{
				endPoint[2] -= tickCount - BEAM_ChargeUpTime[clientIdx] * BEAM_MaxDistance[clientIdx] / BEAM_ChargeUpTime[clientIdx];
			}
		}
		decl colorLayer4[4];
		SetColorRGBA(colorLayer4, r, g, b, 255);
		decl colorLayer3[4];
		SetColorRGBA(colorLayer3, colorLayer4[0] * 7 + 255 / 8, colorLayer4[1] * 7 + 255 / 8, colorLayer4[2] * 7 + 255 / 8, 255);
		decl colorLayer2[4];
		SetColorRGBA(colorLayer2, colorLayer4[0] * 6 + 510 / 8, colorLayer4[1] * 6 + 510 / 8, colorLayer4[2] * 6 + 510 / 8, 255);
		decl colorLayer1[4];
		SetColorRGBA(colorLayer1, colorLayer4[0] * 5 + 765 / 8, colorLayer4[1] * 5 + 765 / 8, colorLayer4[2] * 5 + 765 / 8, 255);
		TE_SetupBeamPoints(startPoint, endPoint, Beam_Laser, 0, 0, 0, 0.18, ClampBeamWidth(diameter * 0.3 * 1.28), ClampBeamWidth(diameter * 0.3 * 1.28), 0, 1.0, colorLayer1, 3);
		TE_SendToAll(0.0);
		TE_SetupBeamPoints(startPoint, endPoint, Beam_Laser, 0, 0, 0, 0.18, ClampBeamWidth(diameter * 0.5 * 1.28), ClampBeamWidth(diameter * 0.5 * 1.28), 0, 1.0, colorLayer2, 3);
		TE_SendToAll(0.0);
		TE_SetupBeamPoints(startPoint, endPoint, Beam_Laser, 0, 0, 0, 0.18, ClampBeamWidth(diameter * 0.8 * 1.28), ClampBeamWidth(diameter * 0.8 * 1.28), 0, 1.0, colorLayer3, 3);
		TE_SendToAll(0.0);
		TE_SetupBeamPoints(startPoint, endPoint, Beam_Laser, 0, 0, 0, 0.18, ClampBeamWidth(diameter * 1.28), ClampBeamWidth(diameter * 1.28), 0, 1.0, colorLayer4, 3);
		TE_SendToAll(0.0);
		static glowColor[4];
		SetColorRGBA(glowColor, r, g, b, 255);
		TE_SetupBeamPoints(startPoint, endPoint, Beam_Glow, 0, 0, 0, 0.18, ClampBeamWidth(diameter * 1.28), ClampBeamWidth(diameter * 1.28), 0, 5.0, glowColor, 0);
		TE_SendToAll(0.0);
	}
	if (BEAM_ChargeUpTime[clientIdx] <= tickCount)
	{
		if (0 < BEAM_FiringSoundLength[clientIdx])
		{
			if (!(tickCount - BEAM_ChargeUpTime[clientIdx] % BEAM_FiringSoundLength[clientIdx]))
			{
				if (strlen(BEAM_FiringSound[clientIdx]) > 3)
				{
					EmitSoundToAll(BEAM_FiringSound[clientIdx], -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				}
			}
		}
		static Float:angles[3];
		static Float:startPoint[3];
		static Float:endPoint[3];
		static Float:hullMin[3];
		static Float:hullMax[3];
		static Float:playerPos[3];
		GetClientEyeAngles(clientIdx, angles);
		GetClientEyePosition(clientIdx, startPoint);
		new Handle:trace = TR_TraceRayFilterEx(startPoint, angles, 11, RayType:1, BEAM_TraceWallsOnly, any:0);
		if (TR_DidHit(trace))
		{
			TR_GetEndPosition(endPoint, trace);
			CloseHandle(trace);
			new Float:beamTraceDistance = GetVectorDistance(startPoint, endPoint, false);
			ConformLineDistance(endPoint, startPoint, endPoint, float(BEAM_MaxDistance[clientIdx]));
			new Float:lineReduce = BEAM_BeamRadius[clientIdx] * 2.0 / 3.0;
			new Float:curDist = GetVectorDistance(startPoint, endPoint, false);
			if (curDist > lineReduce)
			{
				ConformLineDistance(endPoint, startPoint, endPoint, curDist - lineReduce);
			}
			for (new i = 1; i < MAX_PLAYERS; i++)
			{
				BEAM_HitDetected[i] = false;
			}
			for (new building = 0; building < MAX_BUILDINGS; building++)
			{
				BEAM_BuildingHit[building] = false;
			}
			hullMin[0] = -float(BEAM_BeamRadius[clientIdx]);
			hullMin[1] = hullMin[0];
			hullMin[2] = hullMin[0];
			hullMax[0] = -hullMin[0];
			hullMax[1] = -hullMin[1];
			hullMax[2] = -hullMin[2];
			trace = TR_TraceHullFilterEx(startPoint, endPoint, hullMin, hullMax, 1073741824, BEAM_TraceUsers);	// 1073741824 is CONTENTS_LADDER?
			CloseHandle(trace);
			for (new victim = 1; victim < MAX_PLAYERS; victim++)
			{
				if (BEAM_HitDetected[victim] && BossTeam != GetClientTeam(victim))
				{
					GetEntPropVector(victim, Prop_Send, "m_vecOrigin", playerPos, 0);
					new Float:distance = GetVectorDistance(startPoint, playerPos, false);
					new Float:damage = BEAM_CloseDPT[clientIdx] - BEAM_CloseDPT[clientIdx] - BEAM_FarDPT[clientIdx] * distance / BEAM_MaxDistance[clientIdx];
					if (damage < 0)
						damage *= -1.0;
					SDKHooks_TakeDamage(victim, clientIdx, clientIdx, damage, 2048, GetPlayerWeaponSlot(clientIdx, 1), NULL_VECTOR, startPoint);	// 2048 is DMG_NOGIB?
					//Debug("Damage: %f | Weapon: %i", damage, GetPlayerWeaponSlot(clientIdx, 1));
				}
			}
			for (new building = 0; building < MAX_BUILDINGS; building++)
			{
				if (BEAM_BuildingHit[building])
				{
					GetEntPropVector(BEAM_BuildingHit[building], Prop_Send, "m_vecOrigin", playerPos, 0);
					new Float:distance = GetVectorDistance(startPoint, playerPos, false);
					new Float:damage = BEAM_CloseBuildingDPT[clientIdx] - BEAM_CloseBuildingDPT[clientIdx] - BEAM_FarBuildingDPT[clientIdx] * distance / BEAM_MaxDistance[clientIdx];
					if (damage < 0)
						damage *= -1.0;
					SDKHooks_TakeDamage(BEAM_BuildingHit[building], clientIdx, clientIdx, damage, 2048, GetPlayerWeaponSlot(clientIdx, 1), NULL_VECTOR, startPoint);	// 2048 is DMG_NOGIB?
					//Debug("Damage: %f | Weapon: %i", damage, GetPlayerWeaponSlot(clientIdx, 1));
				}
			}
			static Float:belowBossEyes[3];
			GetBeamDrawStartPoint(clientIdx, belowBossEyes);
			decl colorLayer4[4];
			SetColorRGBA(colorLayer4, r, g, b, 255);
			decl colorLayer3[4];
			SetColorRGBA(colorLayer3, colorLayer4[0] * 7 + 255 / 8, colorLayer4[1] * 7 + 255 / 8, colorLayer4[2] * 7 + 255 / 8, 255);
			decl colorLayer2[4];
			SetColorRGBA(colorLayer2, colorLayer4[0] * 6 + 510 / 8, colorLayer4[1] * 6 + 510 / 8, colorLayer4[2] * 6 + 510 / 8, 255);
			decl colorLayer1[4];
			SetColorRGBA(colorLayer1, colorLayer4[0] * 5 + 765 / 8, colorLayer4[1] * 5 + 765 / 8, colorLayer4[2] * 5 + 765 / 8, 255);
			TE_SetupBeamPoints(belowBossEyes, endPoint, Beam_Laser, 0, 0, 0, 0.18, ClampBeamWidth(diameter * 0.3 * 1.28), ClampBeamWidth(diameter * 0.3 * 1.28), 0, 1.0, colorLayer1, 3);
			TE_SendToAll(0.0);
			TE_SetupBeamPoints(belowBossEyes, endPoint, Beam_Laser, 0, 0, 0, 0.18, ClampBeamWidth(diameter * 0.5 * 1.28), ClampBeamWidth(diameter * 0.5 * 1.28), 0, 1.0, colorLayer2, 3);
			TE_SendToAll(0.0);
			TE_SetupBeamPoints(belowBossEyes, endPoint, Beam_Laser, 0, 0, 0, 0.18, ClampBeamWidth(diameter * 0.8 * 1.28), ClampBeamWidth(diameter * 0.8 * 1.28), 0, 1.0, colorLayer3, 3);
			TE_SendToAll(0.0);
			TE_SetupBeamPoints(belowBossEyes, endPoint, Beam_Laser, 0, 0, 0, 0.18, ClampBeamWidth(diameter * 1.28), ClampBeamWidth(diameter * 1.28), 0, 1.0, colorLayer4, 3);
			TE_SendToAll(0.0);
			decl glowColor[4];
			SetColorRGBA(glowColor, r, g, b, 255);
			TE_SetupBeamPoints(belowBossEyes, endPoint, Beam_Glow, 0, 0, 0, 0.18, ClampBeamWidth(diameter * 1.28), ClampBeamWidth(diameter * 1.28), 0, 5.0, glowColor, 0);
			TE_SendToAll(0.0);
			if (BEAM_ChargeUpTime[clientIdx] == tickCount)
			{
				new lightingEntity = CreateEntityByName("light_dynamic", -1);
				if (lightingEntity != -1)
				{
					decl String:colorBuffer[12];
					ColorToDecimalString(colorBuffer, BEAM_ColorHex[clientIdx]);
					DispatchKeyValue(lightingEntity, "_light", colorBuffer);
					DispatchKeyValue(lightingEntity, "brightness", "7");
					DispatchKeyValueFloat(lightingEntity, "distance", 180.0);
					DispatchKeyValue(lightingEntity, "style", "0");
					TeleportEntity(lightingEntity, belowBossEyes, NULL_VECTOR, NULL_VECTOR);
					DispatchSpawn(lightingEntity);
					BEAM_LightingEntityRef[clientIdx] = EntIndexToEntRef(lightingEntity);
				}
			}
			if (beamTraceDistance < BEAM_MaxDistance[clientIdx])
			{
				new explosion = CreateEntityByName("env_explosion", -1);
				if (explosion != -1)
				{
					DispatchKeyValue(explosion, "iMagnitude", "100");
					DispatchKeyValue(explosion, "spawnflags", "37");
					DispatchKeyValue(explosion, "iRadiusOverride", "100");
					DispatchKeyValueFloat(explosion, "DamageForce", 0.0);
					TeleportEntity(explosion, endPoint, NULL_VECTOR, NULL_VECTOR);
					DispatchSpawn(explosion);
					AcceptEntityInput(explosion, "Explode", -1, -1, 0);
					AcceptEntityInput(explosion, "Kill", -1, -1, 0);
				}
			}
		}
		else
		{
			PrintToChatAll("[%s] Error with dot_beam, could not determine end point for beam.", this_plugin_name);
		}
	}
	return;
}

/**
 * Ability Specific Methods
 */
// in manic mode, don't take knockback from sentries!
// note, sentry weapon entity is always -1 (recent edit, that "weapon" below is actually an entity index, bah)
new String:weaponBuffer[64]; // since this'd often get allocated like 500 times per hale match otherwise
public Action:MM_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (victim > 0 && victim < MAX_PLAYERS && GetClientTeam(victim) == BossTeam)
	{
		//PrintToChatAll("[default_dots_restored] boss attacked for %f damage by weapon %i, a/i=%d,%d...", damage, weapon, attacker, inflictor);
		
		// for reference, tweaking the damageForce/damagePosition did nothing
		if (MM_SentryKnockbackImmune[victim])
		{
			// validity check, in case player suicides for example
			if (attacker <= MAX_PLAYERS && attacker > 0)
			{
				// make sure it's an engineer as well
				if (TF2_GetPlayerClass(attacker) == TFClass_Engineer)
				{
					// one last check, check the object entity name
					if (IsValidEntity(inflictor))
					{
						GetEntityClassname(inflictor, weaponBuffer, 64);
						new weaponIdx = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
						if ((!strcmp("obj_sentrygun", weaponBuffer) || !strcmp("tf_projectile_sentryrocket", weaponBuffer)) || weaponIdx == 140) // included wrangler just in case
						{
							damagetype |= DMG_PREVENT_PHYSICS_FORCE;
							return Plugin_Changed;
						}
					}
				}
			}
		}
	}
	else
	{
		if (PRINT_DEBUG_INFO) // never seen this happen but it could be spam-tastic
			PrintToChatAll("[default_dots_restored] someone we don't care about got attacked for %f damage?!", damage);
	}
	
	return Plugin_Continue;
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

stock SwapModel(bossClient, const String:model[])
{
	SetVariantString(model);
	AcceptEntityInput(bossClient, "SetCustomModel");
	SetEntProp(bossClient, Prop_Send, "m_bUseClassAnimations", 1);
}

stock bool:IsLivingPlayer(int clientIdx)
{
	if (clientIdx <= 0 || clientIdx >= MAX_PLAYERS)
		return false;
		
	return IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx);
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

/**
 * Support Methods
 */
stock ParticleEffect(clientIdx, String:effectName[], Float:duration)
{
	if (strlen(effectName) < 3)
		return; // nothing to display
	if (duration == 0.0)
		duration = 0.1; // probably doesn't matter for this effect, I just don't feel comfortable passing 0 to a timer
		
	new particle = AttachParticle(clientIdx, effectName, 75.0);
	if (IsValidEntity(particle))
		CreateTimer(duration, RemoveEntityDA, EntIndexToEntRef(particle));
}

// a duration of 0.0 below means that it won't be removed by a timer
// and instead must be managed by the programmer
stock ParticleEffectAt(Float:position[3], String:effectName[], Float:duration = 0.0)
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
			CreateTimer(duration, RemoveEntityDA, EntIndexToEntRef(particle));
	}
	return particle;
}

stock SetColorRGBA(color[4], r, g, b, a)
{
	color[0] = abs(r)%256;
	color[1] = abs(g)%256;
	color[2] = abs(b)%256;
	color[3] = abs(a)%256;
}

stock ParseColor(String:colorStr[])
{
	new ret = 0;
	ret |= charToHex(colorStr[0])<<20;
	ret |= charToHex(colorStr[1])<<16;
	ret |= charToHex(colorStr[2])<<12;
	ret |= charToHex(colorStr[3])<<8;
	ret |= charToHex(colorStr[4])<<4;
	ret |= charToHex(colorStr[5]);
	return ret;
}

stock ColorToDecimalString(String:buffer[12], rgb)
{
	Format(buffer, 12, "%d %d %d", GetR(rgb), GetG(rgb), GetB(rgb));
}

stock abs(x)
{
	return x < 0 ? -x : x;
}

stock Float:fabs(Float:x)
{
	return x < 0.0 ? -x : x;
}

stock Float:fsquare(Float:x)
{
	return x * x;
}

stock charToHex(c)
{
	if (c >= '0' && c <= '9')
		return c - '0';
	else if (c >= 'a' && c <= 'f')
		return c - 'a' + 10;
	else if (c >= 'A' && c <= 'F')
		return c - 'A' + 10;
	
	// this is a user error, so print this out (it won't spam)
	PrintToChatAll("[%s] Invalid hex character, probably while parsing something's color. Please only use 0-9 and A-F in your color. c=%d", this_plugin_name, c);
	return 0;
}

stock Float:ConformAxisValue(Float:src, Float:dst, Float:distCorrectionFactor)
{
	return src - ((src - dst) * distCorrectionFactor);
}

// if the distance between two points is greater than max distance allowed
// fills result with a new destination point that lines on the line between src and dst
stock ConformLineDistance(Float:result[3], const Float:src[3], const Float:dst[3], Float:maxDistance)
{
	new Float:distance = GetVectorDistance(src, dst);
	if (distance <= maxDistance)
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

stock Float:ClampBeamWidth(Float:w) { return w > 128.0 ? 128.0 : w; }

// sourcepawn doesn't support macro methods :( boooo
stock GetA(c) { return abs(c>>24); }
stock GetR(c) { return abs((c>>16)&0xff); }
stock GetG(c) { return abs((c>>8 )&0xff); }
stock GetB(c) { return abs((c    )&0xff); }

/**
 * CODE BELOW WAS TAKEN FROM ff2_1st_set_abilities, I TAKE NO CREDIT FOR IT
 */
stock SpawnWeapon(client, String:name[], index, level, quality, String:attribute[], visible)
{
	new Handle:weapon=TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
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
		new i2=0;
		for(new i=0; i<count; i+=2)
		{
			new attrib=StringToInt(attributes[i]);
			if(attrib==0)
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

	if(weapon==INVALID_HANDLE)
	{
		return -1;
	}
	new entity=TF2Items_GiveNamedItem(client, weapon);
	CloseHandle(weapon);
	EquipPlayerWeapon(client, entity);
	
	// sarysa addition, since cheese's weapons are currently invisible
	if (!visible)
	{
		SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
		//SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", -1, _, 0);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
	}
	
	return entity;
}

/**
 * CODE BELOW TAKEN FROM default_abilities, I CLAIM NO CREDIT
 */
public Action:DestroyEntity(Handle:timer, any:entid) // well, this one's mine. ;P need to make slow kill entities disappear while they die.
{
	new entity = EntRefToEntIndex(entid);
	if (IsValidEdict(entity) && entity > MAX_PLAYERS)
	{
		// may not be the best way to handle this, but I can't find documentation re: toggling visibility. bah.
		// and the few lists of entity props I could find don't include it, so...
		TeleportEntity(entity, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR);
		RemoveEntityDA(timer, entid);
	}
}

public Action:RemoveEntityDA(Handle:timer, any:entid)
{
	new entity=EntRefToEntIndex(entid);
	if(IsValidEdict(entity) && entity>MAX_PLAYERS)
	{
		AcceptEntityInput(entity, "Kill");
	}
}

stock AttachParticle(entity, String:particleType[], Float:offset, bool:attach)
{
	new particle = CreateEntityByName("info_particle_system", -1);
	if (!IsValidEntity(particle))
	{
		return -1;
	}
	decl String:targetName[128];
	decl Float:position[3];
	GetEntPropVector(entity, PropType:0, "m_vecOrigin", position, 0);
	position[2] += offset;
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
	Format(targetName, 128, "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);
	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	if (attach)
	{
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, PropType:0, "m_hOwnerEntity", entity, 0);
	}
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start", -1, -1, 0);
	return particle;
}

stock AttachParticleToAttachment(entity, String:particleType[], String:attachmentPoint[])
{
	new particle = CreateEntityByName("info_particle_system", -1);
	if (!IsValidEntity(particle))
	{
		return -1;
	}
	decl String:targetName[128];
	decl Float:position[3];
	GetEntPropVector(entity, PropType:0, "m_vecOrigin", position, 0);
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
	Format(targetName, 128, "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);
	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	AcceptEntityInput(particle, "SetParent", particle, particle, 0);
	SetEntPropEnt(particle, PropType:0, "m_hOwnerEntity", entity, 0);
	SetVariantString(attachmentPoint);
	AcceptEntityInput(particle, "SetParentAttachment", -1, -1, 0);
	if (strlen(particleType[0]))
	{
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start", -1, -1, 0);
	}
	return particle;
}

stock bool:IsInstanceOf(entity, String:desiredClassname[])
{
	if (!IsValidEntity(entity))
	{
		return false;
	}
	static String:classname[48];
	GetEntityClassname(entity, classname, 48);
	return strcmp(classname, desiredClassname, true) == 0;
}

stock Float:DEG2RAD(Float:n)
{
	return n * 0.017453;
}

stock Float:DotProduct(Float:v1[3], Float:v2[4])
{
	return v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2];
}

stock VectorRotate2(Float:in1[3], Float:in2[3][4], Float:out[3])
{
	out[0] = DotProduct(in1, in2[0]);
	out[1] = DotProduct(in1, in2[1]);
	out[2] = DotProduct(in1, in2[2]);
	return;
}

stock AngleMatrix(Float:angles[3], Float:matrix[3][4])
{
	float sr = 0.0;
	float sp = 0.0;
	float sy = 0.0;
	float cr = 0.0;
	float cp = 0.0;
	float cy = 0.0;
	sy = Sine(DEG2RAD(angles[1]));
	cy = Cosine(DEG2RAD(angles[1]));
	sp = Sine(DEG2RAD(angles[0]));
	cp = Cosine(DEG2RAD(angles[0]));
	sr = Sine(DEG2RAD(angles[2]));
	cr = Cosine(DEG2RAD(angles[2]));
	matrix[0][0] = cp * cy;
	matrix[1][0] = cp * sy;
	matrix[2][0] = -sp;
	float crcy = cr * cy;
	float crsy = cr * sy;
	float srcy = sr * cy;
	float srsy = sr * sy;
	matrix[0][1] = sp * srcy - crsy;
	matrix[1][1] = sp * srsy + crcy;
	matrix[2][1] = sr * cp;
	matrix[0][2] = sp * crcy + srsy;
	matrix[1][2] = sp * crsy - srcy;
	matrix[2][2] = cr * cp;
	matrix[0][3] = 0.0;
	matrix[1][3] = 0.0;
	matrix[2][3] = 0.0;
	return;
}

stock VectorRotate(Float:inPoint[3], Float:angles[3], Float:outPoint[3])
{
	float matRotate[3][4];
	AngleMatrix(angles, matRotate);
	VectorRotate2(inPoint, matRotate, outPoint);
	return;
}

#file "FF2 Subplugin: Default DOTs Restored"