#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools_functions>
#include <freak_fortress_2>
#include <ff2_dynamic_defaults>
#include <freak_fortress_2_subplugin>
#include <drain_over_time>
#include <drain_over_time_subplugin>

#pragma newdecls required

#define PLUGIN_NAME 	"Freak Fortress 2: Skyregion DOT Abilitypack"
#define PLUGIN_AUTHOR 	"J0BL3SS"
#define PLUGIN_DESC 	"FF2 Subplugin: Skyregion DOT Abilities"

#define MAJOR_REVISION 	"1"
#define MINOR_REVISION 	"2"
#define STABLE_REVISION "1"
#define PLUGIN_VERSION 	MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define PLUGIN_URL "www.skyregiontr.com"

#define MAXPLAYERARRAY MAXPLAYERS+1


/*
 * Some Code Spinnets from:
 * "Freak Fortress 2: Fire Boss Pack" 			Version "1.0" by "Friagram" 	~ for Noclip Acceleration and Noclip Speed
 * "Freak Fortress 2: Blightcaler's Subplugin" 	Version "1.0" by "LeAlex" 		~ for DOT Phasewalk.
 * Thanks to: JuegosPablo for helping me about dot_noclip. LeAlex14 for dot_phasewalk's code, mainly created for DoctorKrazy's boss Hoovydundy
 */
 
 /*

	"abilityX"
	{
		"name"	"dot_noclip"
		"arg1"	"0"			//0-Don't teleport boss, 1-Teleport back where it activated the ability, 2-Teleport to random player
		"arg2"	"2.0"		//Stun time after noclip usage
		"arg3"	"1" 		//1-Block attack during noclip, 0-Allow boss to attack during noclip
		"arg4"	"1"			//1-Don't take damage during noclip, 0-Take Damage during noclip
		"arg5"	"5.0"		//Noclip Speed
		"arg6"	"5.0"		//Noclip Accelerate
		"plugin_name"	"sr_dot_abilities"
	}
	"abilityX"
	{
		"name"	"dot_regen"
		"arg1"	"1"			//Tickrate
		"arg2"	"0.0003" 	//Health gain per (arg1) tick. For self heal. (Value between 1.0 and 0.0)
		"arg3"	"0.0002"	//Health gain per (arg1) tick. For companions. (Value between 1.0 and 0.0)
		"arg4"	"1024.0"	//Companion Range to Heal
		"plugin_name"	"sr_dot_abilities"
	}
	"abilityX"
	{
		"name"	"dot_movespeed"
		"arg1"	"520.0"			//Boss Move Speed During dot usage
		"plugin_name"	"sr_dot_abilities"
	}
	"abilityX"
	{
		"name"		"dot_phasewalk"
		
		//Image Settings
		"arg1"		"5"				//Image Creation Tickrate
		"arg2"		"48"			//Image Duration Tickrate
		"arg3"		"utaunt_bubbles_glow_green_parent"	//Effect Particle Name
		
	
		"plugin_name"		"sr_dot_abilities"
	}
	"abilityX"
	{
		"name"	"dot_render"
		"arg1"	"255"	//Red
		"arg2"	"255"	//Blue
		"arg3"	"255"	//Green
		"arg4"	"125"	//Alpha
		"plugin_name"	"sr_dot_abilities"
	}
	"abilityX"
	{
		"name"	"dot_damage"
		"arg1"		"0.1"	// Knockback Multipler during dot usage
		"arg2"		"0.1"	// Damage Multipler	during dot usage
		"plugin_name"	"sr_dot_abilities"
	}
	"abilityX"
	{
		"name" "dot_no_collisions"
		
		"arg1"	"50"	// Collision range
		"arg2"	"9999"	// Damage to Player when dot disabled
	}

 */

/*
 * Shared Variables
 */
float DOT_ActivatePosition[3];					//internal
float DOT_CurrentPosition[3];					//internal
float zero[3] =  { 0.0, 0.0, 0.0 }; 			//internal
bool RoundInProgress = false;					//internal

Handle DN_hNoclipSpeed;							//internal
Handle DN_hNoclipAccelerate;					//internal
	
float DN_fNoclipSpeed;							//internal
float DN_fNoclipAccelerate;						//internal

/*
 * Global Variables "dot_noclip"
 */
#define DN_STRING "dot_noclip"

bool DOT_Noclip_CanUse[MAXPLAYERARRAY]; 	//internal
bool InNoclip[MAXPLAYERARRAY];				//internal

int DN_TeleportBack[MAXPLAYERARRAY];		//arg1
float DN_AfterStun[MAXPLAYERARRAY];			//arg2
float DN_NoclipSpeed[MAXPLAYERARRAY];		//arg3
float DN_NoclipAccelerate[MAXPLAYERARRAY];	//arg4

/*
 * Global Variables "dot_regen"
 */
#define DR_STRING "dot_regen"
bool DOT_Regen_CanUse[MAXPLAYERARRAY]; 		// internal

int DR_Tickrate[MAXPLAYERARRAY];			//arg1
float DR_HealthGainSelf[MAXPLAYERARRAY];	//arg2
float DR_HealthGainComp[MAXPLAYERARRAY];	//arg3
float DR_HealthRangeComp[MAXPLAYERARRAY];	//arg4

/*
 * Global Variables "dot_movespeed"
 */
#define DS_STRING "dot_movespeed"
bool DOT_Speed_CanUse[MAXPLAYERARRAY];			// internal
float DS_SpeedInHammerUnits[MAXPLAYERARRAY];	//arg1

/*
 * Global Variables "dot_phasewalk"
 */
#define DW_STRING "dot_phasewalk"
bool DOT_Walk_CanUse[MAXPLAYERARRAY]; 		// internal
int DW_CreateTickrate[MAXPLAYERARRAY];		//arg1	
int DW_RemoveTickrate[MAXPLAYERARRAY];		//arg2
char DW_EffectName[MAXPLAYERARRAY][768];	//arg10		
bool DW_BlockAttack[MAXPLAYERARRAY];		//arg11	

/*
 * Global Variables "dot_render"
 */
#define DRC_STRING "dot_render"
bool DOT_RenderColor_CanUse[MAXPLAYERARRAY];
int DRC_Colors[MAXPLAYERARRAY][4];			//arg1,2,3,4

/*
 * Global Variables "dot_damage"
 */
#define DDMG_STRING "dot_damage"
bool DOT_Damage_CanUse[MAXPLAYERARRAY];
float DDMG_DamageMultp[MAXPLAYERARRAY];		//arg1
float DDMG_KnockbackMultp[MAXPLAYERARRAY];	//arg2

/*
 * Global Variables "dot_no_collisions"
 */
#define DNC_STRING "dot_no_collisions"
bool DOT_NoCollisions_CanUse[MAXPLAYERARRAY];
float DNC_TelefragRange[MAXPLAYERARRAY];		//arg1
float DNC_TelefragDamage[MAXPLAYERARRAY];		//arg2

/*
 * Global Variables "dot_block_attack"
 */
#define DBA_STRING "dot_block_attack"
bool DOT_BlockAttack_CanUse[MAXPLAYERARRAY];	//blocks attack during dot

/*
 * Global Variables "dot_teleport_pos"

#define DT_STRING "dot_teleport_pos"
bool DOT_TeleportPos_CanUse[MAXPLAYERARRAY];
 */
 
float OFF_THE_MAP[3] =
{
	1182792704.0, 1182792704.0, -964690944.0
};

public Plugin myinfo = 
{
	name 		= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESC,
	version 	= PLUGIN_VERSION,
	url			= PLUGIN_URL,
};

public void OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart);
	HookEvent("teamplay_round_active", Event_RoundStart); // for non-arena maps
	
	HookEvent("arena_win_panel", Event_RoundEnd);
	HookEvent("teamplay_round_win", Event_RoundEnd); // for non-arena maps
	
	if(!((DN_hNoclipSpeed = FindConVar("sv_noclipspeed"))))
	{
		SetFailState("Could not locate CVAR sv_noclipspeed");
	}
	if(!((DN_hNoclipAccelerate = FindConVar("sv_noclipaccelerate"))))
	{
		SetFailState("Could not locate CVAR sv_noclipaccelerate");
	}
}

public void OnConfigsExecuted()
{
	DN_fNoclipSpeed = GetConVarFloat(DN_hNoclipSpeed);
	DN_fNoclipAccelerate = GetConVarFloat(DN_hNoclipAccelerate);
}

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
	return Plugin_Continue;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{	
	RoundInProgress = true;
	
	for(int bossClientIdx = 1; bossClientIdx <= MaxClients; bossClientIdx++)
	{
		DOT_Walk_CanUse[bossClientIdx] = false;
		DOT_Noclip_CanUse[bossClientIdx] = false;
		DOT_Regen_CanUse[bossClientIdx] = false;
		
		SDKUnhook(bossClientIdx, SDKHook_OnTakeDamage, DDMG_NoDamage);
		SDKUnhook(bossClientIdx, SDKHook_PreThink, DS_Speed_Prethink);
		
		int bossIdx = FF2_GetBossIndex(bossClientIdx);
		if(bossIdx >= 0)
		{
			GetEntPropVector(bossClientIdx, Prop_Send, "m_vecOrigin", DOT_ActivatePosition);
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	RoundInProgress = false;
	
	for(int bossClientIdx = 1; bossClientIdx < MaxClients; bossClientIdx++)
	{
		DOT_Noclip_CanUse[bossClientIdx] = false;
		DOT_Regen_CanUse[bossClientIdx] = false;
		DOT_Walk_CanUse[bossClientIdx] = false;
		DOT_Damage_CanUse[bossClientIdx] = false;
		DOT_NoCollisions_CanUse[bossClientIdx] = false;
		
		SDKUnhook(bossClientIdx, SDKHook_OnTakeDamage, DDMG_NoDamage);
		SDKUnhook(bossClientIdx, SDKHook_PreThink, DS_Speed_Prethink);
		
		if(InNoclip[bossClientIdx])
		{
			SetConVarFloat(DN_hNoclipSpeed, DN_fNoclipSpeed, false, false);
			SetConVarFloat(DN_hNoclipAccelerate, DN_fNoclipAccelerate, false, false);
			TeleportEntity(bossClientIdx, DOT_ActivatePosition, NULL_VECTOR, zero);
			InNoclip[bossClientIdx] = false;
		}
	}
}

public void DOTPostRoundStartInit()
{
	if (!RoundInProgress)
	{
		PrintToServer("[%n] DOTPostRoundStartInit() called when the round is over?! Shouldn't be possible!", this_plugin_name);
		return;
	}
	for(int bossClientIdx = 1; bossClientIdx <= MaxClients; bossClientIdx++)
	{
		int bossIdx = FF2_GetBossIndex(bossClientIdx);
		if(bossIdx >= 0)
		{
			//DOT Noclip
			DOT_Noclip_CanUse[bossClientIdx] 		= FF2_HasAbility(bossIdx, this_plugin_name, DN_STRING);
			if (DOT_Noclip_CanUse[bossClientIdx])
			{
				DN_TeleportBack[bossClientIdx] 			= FF2_GetAbilityArgument(bossIdx, this_plugin_name, DN_STRING, 1, 2);
				DN_AfterStun[bossClientIdx] 			= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DN_STRING, 2, 2.0);
				DN_NoclipSpeed[bossClientIdx] 			= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DN_STRING, 3, 5.0);
				DN_NoclipAccelerate[bossClientIdx]		= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DN_STRING, 4, 5.0);
			}
			//DOT Health Regerenation
			DOT_Regen_CanUse[bossClientIdx] 		= FF2_HasAbility(bossIdx, this_plugin_name, DR_STRING);
			if (DOT_Regen_CanUse[bossClientIdx])
			{
				DR_Tickrate[bossClientIdx] 				= FF2_GetAbilityArgument(bossIdx, this_plugin_name, DR_STRING, 1, 1);
				DR_HealthGainSelf[bossClientIdx] 		= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DR_STRING, 2, 0.0);
				DR_HealthGainComp[bossClientIdx] 		= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DR_STRING, 3, 0.0);
				DR_HealthRangeComp[bossClientIdx]		= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DR_STRING, 4, 1024.0);
			}
			//DOT Speed
			DOT_Speed_CanUse[bossClientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, DS_STRING);
			if (DOT_Speed_CanUse[bossClientIdx])
			{
				DS_SpeedInHammerUnits[bossClientIdx] 	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DS_STRING, 1, 520.0);
			}
			//DOT Phasewalk
			DOT_Walk_CanUse[bossClientIdx] 			= FF2_HasAbility(bossIdx, this_plugin_name, DW_STRING);
			if(DOT_Walk_CanUse[bossClientIdx])
			{
				DW_CreateTickrate[bossClientIdx] 	= FF2_GetAbilityArgument(bossIdx, this_plugin_name, DW_STRING, 1, 1);
				DW_RemoveTickrate[bossClientIdx] 	= FF2_GetAbilityArgument(bossIdx, this_plugin_name, DW_STRING, 2, 10);
				DW_BlockAttack[bossClientIdx]		= view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, DW_STRING, 3, 0));
				
				FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, DW_STRING, 4, DW_EffectName[bossClientIdx], 768);

			}
			//DOT RenderColor
			DOT_RenderColor_CanUse[bossClientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, DRC_STRING);
			if(DOT_RenderColor_CanUse[bossClientIdx])
			{
				DRC_Colors[bossClientIdx][0]	= FF2_GetAbilityArgument(bossIdx, this_plugin_name, DRC_STRING, 1, 255);
				DRC_Colors[bossClientIdx][1]	= FF2_GetAbilityArgument(bossIdx, this_plugin_name, DRC_STRING, 2, 255);
				DRC_Colors[bossClientIdx][2]	= FF2_GetAbilityArgument(bossIdx, this_plugin_name, DRC_STRING, 3, 255);
				DRC_Colors[bossClientIdx][3]	= FF2_GetAbilityArgument(bossIdx, this_plugin_name, DRC_STRING, 4, 255);
			}
			//DOT No Collisions
			DOT_NoCollisions_CanUse[bossClientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, DNC_STRING);
			if(DOT_NoCollisions_CanUse[bossClientIdx])
			{
				DNC_TelefragRange[bossClientIdx]	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DNC_STRING, 1, 50.0);
				DNC_TelefragDamage[bossClientIdx]	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DNC_STRING, 2, 9999.0);
			}
			//DOT Damage Multipler
			DOT_Damage_CanUse[bossClientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, DDMG_STRING);
			if(DOT_Damage_CanUse[bossClientIdx])
			{
				DDMG_DamageMultp[bossClientIdx] 	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DDMG_STRING, 1, 1.0);
				DDMG_KnockbackMultp[bossClientIdx] 	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, DDMG_STRING, 2, 1.0);
			}
		}
	}
}

public void OnDOTAbilityActivated(int bossClientIdx)
{
	GetEntPropVector(bossClientIdx, Prop_Send, "m_vecOrigin", DOT_ActivatePosition); //store dot activate position
	
	if(DOT_Noclip_CanUse[bossClientIdx])
	{
		InNoclip[bossClientIdx] = true;
			
		SetEntityMoveType(bossClientIdx, MOVETYPE_NOCLIP);
		SetConVarFloat(DN_hNoclipSpeed, DN_NoclipSpeed[bossClientIdx], false, false);
		SetConVarFloat(DN_hNoclipAccelerate, DN_NoclipAccelerate[bossClientIdx], false, false);
	}
	if(DOT_Walk_CanUse[bossClientIdx])
	{
		//--
	}
	if(DOT_Speed_CanUse[bossClientIdx])
	{
		SDKHook(bossClientIdx, SDKHook_PreThink, DS_Speed_Prethink);
	}
	if(DOT_RenderColor_CanUse[bossClientIdx])
	{
		SetEntityRenderMode(bossClientIdx, view_as<RenderMode>(2));
		SetEntityRenderColor(bossClientIdx, DRC_Colors[bossClientIdx][0], DRC_Colors[bossClientIdx][1], DRC_Colors[bossClientIdx][2], DRC_Colors[bossClientIdx][3]);
	}
	if(DOT_NoCollisions_CanUse[bossClientIdx])
	{
		for(int clientIdx = 1; clientIdx <= MaxClients; clientIdx++)
		{
			if(IsValidClient(clientIdx) && IsPlayerAlive(clientIdx))
			{
				SetEntProp(clientIdx, Prop_Data, "m_CollisionGroup", 2);
			}
		}
		
		int iBuilding = -1;
		while((iBuilding = FindEntityByClassname(iBuilding, "obj_*")) != -1)
		{
			static char strClassname[15];
			GetEntityClassname(iBuilding, strClassname, sizeof(strClassname));
			if(StrEqual(strClassname, "obj_dispenser") || StrEqual(strClassname, "obj_teleporter") || StrEqual(strClassname, "obj_sentrygun"))
			{
				SetEntProp(iBuilding, Prop_Data, "m_CollisionGroup", 2);
			}
		}
	}
	if(DOT_Damage_CanUse[bossClientIdx])
	{
		SDKHook(bossClientIdx, SDKHook_OnTakeDamage, DDMG_NoDamage);
	}
	if(DOT_BlockAttack_CanUse[bossClientIdx])
	{
		SetEntPropFloat(bossClientIdx, Prop_Send, "m_flNextAttack", GetGameTime() + 1000000.0); //What
	}
}

public void OnDOTAbilityDeactivated(int bossClientIdx)
{
	if(DOT_Noclip_CanUse[bossClientIdx])
	{
		InNoclip[bossClientIdx] = false;
		
		DN_AfterUsageTeleport(bossClientIdx);
		
		SetConVarFloat(DN_hNoclipSpeed, DN_fNoclipSpeed, false, false);
		SetConVarFloat(DN_hNoclipAccelerate, DN_fNoclipAccelerate, false, false);
		SetEntityMoveType(bossClientIdx, MOVETYPE_WALK);
	}
	if(DOT_Speed_CanUse[bossClientIdx])
	{
		SDKUnhook(bossClientIdx, SDKHook_PreThink, DS_Speed_Prethink);
	}
	if(DOT_Walk_CanUse[bossClientIdx])
	{
		if(DW_BlockAttack[bossClientIdx])
			SetEntPropFloat(bossClientIdx, Prop_Send, "m_flNextAttack", GetGameTime() + 1.0);  // far future
			
		DispatchKeyValue(bossClientIdx, "disableshadows", "0");
	}
	if(DOT_RenderColor_CanUse[bossClientIdx])
	{
		SetEntityRenderColor(bossClientIdx, 255, 255, 255, 255);
		SetEntityRenderMode(bossClientIdx, view_as<RenderMode>(1));
	}
	if(DOT_NoCollisions_CanUse[bossClientIdx])
	{
		float BossPos[3];
		GetClientAbsOrigin(bossClientIdx, BossPos);
		
		for(int clientIdx = 1; clientIdx <= MaxClients; clientIdx++)
		{
			if(IsValidClient(clientIdx) && IsPlayerAlive(clientIdx))
			{
				SetEntProp(clientIdx, Prop_Data, "m_CollisionGroup", 5);
				
				if(clientIdx != bossClientIdx)
				{
					float ClientPos[3];
					GetClientAbsOrigin(clientIdx, ClientPos);
					if(GetVectorDistance(BossPos,ClientPos) <= DNC_TelefragRange[bossClientIdx])
					{
						SDKHooks_TakeDamage(clientIdx, bossClientIdx, bossClientIdx, DNC_TelefragDamage[bossClientIdx], DMG_VEHICLE);
					}
				}
			}
		}
		int iBuilding = -1;
		while((iBuilding = FindEntityByClassname(iBuilding, "obj_*")) != -1)
		{
			static char strClassname[15];
			GetEntityClassname(iBuilding, strClassname, sizeof(strClassname));
			if(StrEqual(strClassname, "obj_dispenser") || StrEqual(strClassname, "obj_teleporter") || StrEqual(strClassname, "obj_sentrygun"))
			{
				static float BuildingPos[3];
				GetEntPropVector(iBuilding, Prop_Send, "m_vecOrigin", BuildingPos);
			
				SetEntProp(iBuilding, Prop_Data, "m_CollisionGroup", 5);
				if(GetVectorDistance(BossPos, BuildingPos) <= DNC_TelefragRange[bossClientIdx])
				{
					SDKHooks_TakeDamage(iBuilding, bossClientIdx, bossClientIdx, DNC_TelefragDamage[bossClientIdx], DMG_VEHICLE);
				}
			}
		}
	}
	if(DOT_Damage_CanUse[bossClientIdx])
	{
		SDKUnhook(bossClientIdx, SDKHook_OnTakeDamage, DDMG_NoDamage);
	}
	if(DOT_BlockAttack_CanUse[bossClientIdx])
	{
		SetEntPropFloat(bossClientIdx, Prop_Send, "m_flNextAttack", GetGameTime() + 1.0); //What
	}
}

public void DS_Speed_Prethink(int bossClientIdx)
{
	SetEntPropFloat(bossClientIdx, Prop_Send, "m_flMaxspeed", DS_SpeedInHammerUnits[bossClientIdx]);
}

public void OnDOTUserDeath(int bossClientIdx, int isInGame)
{
	// suppress
	if (bossClientIdx || isInGame) { }
}

public void OnDOTAbilityTick(int bossClientIdx, int tickCount)
{
	GetEntPropVector(bossClientIdx, Prop_Send, "m_vecOrigin", DOT_CurrentPosition);
	
	if (DOT_Noclip_CanUse[bossClientIdx] && (tickCount % 1 == 0))
	{ 
		//SetConVarFloat(DN_hNoclipSpeed, DN_NoclipSpeed[bossClientIdx], false, false);
		//SetConVarFloat(DN_hNoclipAccelerate, DN_NoclipAccelerate[bossClientIdx], false, false);	
	}
	if (DOT_Regen_CanUse[bossClientIdx] && (tickCount % DR_Tickrate[bossClientIdx] == 0))
	{
		int boss = FF2_GetBossIndex(bossClientIdx);
		float pos1[3], dist;
		
		int HPGainSelf = FF2_GetBossHealth(boss);
		int HPMaxSelf = FF2_GetBossMaxHealth(boss);
				
		HPGainSelf = RoundToCeil(HPGainSelf + (HPMaxSelf * DR_HealthGainSelf[bossClientIdx]));
		if((HPGainSelf > HPMaxSelf) || (HPMaxSelf == HPGainSelf))
		{
			HPGainSelf = HPMaxSelf;
		}
				
		FF2_SetBossHealth(boss, HPGainSelf);
			
		for(int Comp = 1; Comp <= MaxClients; Comp++)
		{
			if(IsValidClient(Comp) && GetClientTeam(Comp) == FF2_GetBossTeam())
			{
				int CompIndex = FF2_GetBossIndex(Comp);
				GetEntPropVector(Comp, Prop_Send, "m_vecOrigin", pos1);
				dist = GetVectorDistance(DOT_CurrentPosition, pos1);
				if(dist <= DR_HealthRangeComp[bossClientIdx] && CompIndex > 0)
				{
					int HPGainComp = FF2_GetBossHealth(CompIndex);
					int HPMaxComp = FF2_GetBossMaxHealth(CompIndex);
					
					HPGainComp = RoundToCeil(HPGainComp + (HPMaxComp * DR_HealthGainComp[bossClientIdx]));
					if((HPGainComp > HPMaxComp) || (HPGainComp == HPMaxComp))
					{
						HPGainComp = HPMaxComp;
					}
					FF2_SetBossHealth(CompIndex, HPGainComp);
				}
			}
		}
	}
	if (DOT_Walk_CanUse[bossClientIdx] && (tickCount % DW_CreateTickrate[bossClientIdx] == 0))
	{
		MakeAnImage(bossClientIdx);
	}
}


/*
 * @param client	boss's id to teleport
 */
public void DN_AfterUsageTeleport(int bossClientIdx)
{	
	switch(DN_TeleportBack[bossClientIdx])
	{
		case 0:
		{
			if (DN_AfterStun[bossClientIdx] > 0.0)
				TF2_StunPlayer(bossClientIdx, DN_AfterStun[bossClientIdx], 0.0, TF_STUNFLAGS_SMALLBONK | TF_STUNFLAG_NOSOUNDOREFFECT);	//stun, if set
		}
		case 1:
		{
			TeleportEntity(bossClientIdx, DOT_ActivatePosition, NULL_VECTOR, zero); //teleports boss where he did activated the dot ability
			if (DN_AfterStun[bossClientIdx] > 0.0)
				TF2_StunPlayer(bossClientIdx, DN_AfterStun[bossClientIdx], 0.0, TF_STUNFLAGS_SMALLBONK | TF_STUNFLAG_NOSOUNDOREFFECT); //stun, if set
		}
		case 2:
		{
			DD_PerformTeleport(bossClientIdx, DN_AfterStun[bossClientIdx],  true, true, false, false); //teleports boss the random player
		}
		default:
		{
			TeleportEntity(bossClientIdx, DOT_ActivatePosition, NULL_VECTOR, zero); //teleports boss where he did activated the dot ability
			if (DN_AfterStun[bossClientIdx] > 0.0)
				TF2_StunPlayer(bossClientIdx, DN_AfterStun[bossClientIdx], 0.0, TF_STUNFLAGS_SMALLBONK | TF_STUNFLAG_NOSOUNDOREFFECT); //stun, if set
		}
	}
}

public Action DDMG_NoDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	damageForce[0] = damageForce[0] * DDMG_KnockbackMultp[victim];
	damageForce[1] = damageForce[1] * DDMG_KnockbackMultp[victim];
	damageForce[2] = damageForce[2] * DDMG_KnockbackMultp[victim];
	
	damage = damage * DDMG_DamageMultp[victim];
	return Plugin_Changed;
}

//Thanks to LeAlex14 for sharing MakeAnImage() void
public Action MakeAnImage(int client)
{
	float clientPos[3] = 0.0;
	float clientAngles[3] = 0.0;
	float clientVel[3] = 0.0;
	GetClientAbsOrigin(client, clientPos);
	GetEntPropVector(client, Prop_Send, "m_angRotation", clientAngles);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", clientVel);
	SetEntityRenderMode(client, view_as<RenderMode>(2));
	
	float duration = DW_RemoveTickrate[client] / 10.0;
	
	if(DW_EffectName[client][0]!='\0')
	{
		int particle = CreateEntityByName("info_particle_system", -1);
		if(IsValidEntity(particle))
		{
			TeleportEntity(particle, clientPos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(particle, "targetname", "tf2particle");
			DispatchKeyValue(particle, "parentname", "animationentity");
			DispatchKeyValue(particle, "effect_name", DW_EffectName[client]);
			DispatchSpawn(particle);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start", -1, -1, 0);
			
			CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(particle), 2);
		}
	}
	
	int animationentity = CreateEntityByName("prop_physics_multiplayer", -1);
	if(IsValidEntity(animationentity))
	{
		char model[256];
		GetClientModel(client, model, 256);
		DispatchKeyValue(animationentity, "model", model);
		DispatchKeyValue(animationentity, "solid", "0");
		DispatchSpawn(animationentity);
		SetEntityMoveType(animationentity, MOVETYPE_FLYGRAVITY);
		AcceptEntityInput(animationentity, "TurnOn", animationentity, animationentity, 0);
		SetEntPropEnt(animationentity, view_as<PropType>(0), "m_hOwnerEntity", client, 0);
		if (GetEntProp(client, view_as<PropType>(0), "m_iTeamNum", 4, 0))
		{
			SetEntProp(animationentity, view_as<PropType>(0), "m_nSkin", GetClientTeam(client) + -2, 4, 0);
		}
		else
		{
			SetEntProp(animationentity, view_as<PropType>(0), "m_nSkin", GetEntProp(client, view_as<PropType>(0), "m_nForcedSkin", 4, 0), 4, 0);
		}
		SetEntProp(animationentity, view_as<PropType>(0), "m_nSequence", GetEntProp(client, view_as<PropType>(0), "m_nSequence", 4, 0), 4, 0);
		SetEntPropFloat(animationentity,view_as<PropType>(0), "m_flPlaybackRate", GetEntPropFloat(client, view_as<PropType>(0), "m_flPlaybackRate", 0), 0);
		DispatchKeyValue(client, "disableshadows", "1");
		TeleportEntity(animationentity, clientPos, clientAngles, clientVel);
	
		CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(animationentity), 2);
	}
}

public Action Timer_RemoveEntity(Handle timer, any entid)
{
	int entity = EntRefToEntIndex(entid);
	if (IsValidEdict(entity) && entity > MaxClients)
	{
		TeleportEntity(entity, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "Kill", -1, -1, 0);
	}
	return view_as<Action>(3);
}

/*
 *	@param client	Checks client valid or not
 *	@return 		true if client is valid
 */
stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client) || !IsClientConnected(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}