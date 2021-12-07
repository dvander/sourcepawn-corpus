#pragma semicolon 1

#include <tf2_stocks>
#include <tf2items>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <ff2_ams>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#pragma newdecls required

#define PLUGIN_NAME 	"Freak Fortress 2: Gravity"
#define PLUGIN_AUTHOR 	"J0BL3SS"
#define PLUGIN_DESC 	"Break the laws of quantum and create gravitational fields and shockwaves"

#define MAJOR_REVISION 	"1"
#define MINOR_REVISION 	"3"
#define STABLE_REVISION "0"
#define PLUGIN_VERSION 	MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define PLUGIN_URL "www.skyregiontr.com"

#define MAXPLAYERARRAY MAXPLAYERS+1

/*
 *	Defines "rage_gravity_X"
 */
bool AMS_GRV[10][MAXPLAYERS+1];				//Internal 	- AMS Trigger
int GRV_EffectMode[10][MAXPLAYERARRAY];		//arg1		- EffectMode
float GRV_Value[10][MAXPLAYERARRAY];		//arg2		- Gravity Value
float GRV_Distance[10][MAXPLAYERARRAY];		//arg3		- Rage Distance
float GRV_Duration[10][MAXPLAYERARRAY];		//arg4		- Rage Duration

/*
 *	Defines "rage_shockwave"
 */
#define SHW "rage_shockwave"
bool AMS_SHW[MAXPLAYERARRAY];				//Internal 	- AMS Trigger
float SHW_PlayerDamage[MAXPLAYERARRAY];		//arg1 		- Player damage at point blank
float SHW_BuildDamage[MAXPLAYERARRAY];		//arg2		- Building damage at point blank
float SHW_Distance[MAXPLAYERARRAY];			//arg3		- Distance
float SHW_KnockbackForce[MAXPLAYERARRAY];	//arg4		- Knockback Force
float SHW_MinZ[MAXPLAYERARRAY];				//arg5		- Minimum Z Insenity


/*
 *	Defines "rage_sigma"
 */
#define SIG "rage_sigma"
bool AMS_SIG[MAXPLAYERARRAY];				//Internal 	- AMS Trigger
bool SIG_Pos[MAXPLAYERARRAY];				//arg1		- Position; 1:Aim Pos, 2:Stand Pos
float SIG_Distance[MAXPLAYERARRAY];			//arg2		- Distance
float SIG_VelForce[MAXPLAYERARRAY];			//arg3		- Upward Velocity Force
float SIG_VelDuration[MAXPLAYERARRAY];		//arg4		- Gravity Force will be applied after this duration
float SIG_GravityForce[MAXPLAYERARRAY];		//arg5		- Gravity Force
float SIG_GravityDuration[MAXPLAYERARRAY];	//arg6		- Gravity Force Duration
bool SIG_ExplodeBuilding[MAXPLAYERARRAY];	//arg7		- Explode Buildings? 1:Yes, 2:No
float SIG_Damage[MAXPLAYERARRAY];			//arg8		- Damage to player
char SIG_Particle[MAXPLAYERARRAY][512];		//arg9		- Particle Effect to affected player	(Ignored if argument is blank)
char SIG_ParticlePoint[MAXPLAYERARRAY][128];//arg10		- Particle Replace Point				(Ignored if arg8 is blank)
int SIG_iParticle[MAXPLAYERARRAY];			//Internal

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
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ClearEverything();
	
	MainBoss_PrepareAbilities();
	CreateTimer(1.0, TimerHookSpawn, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TimerHookSpawn(Handle timer)
{
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int UserIdx = GetEventInt(event, "userid");
	
	if(IsValidClient(GetClientOfUserId(UserIdx)))
	{
		CreateTimer(0.3, SummonedBoss_PrepareAbilities, UserIdx, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		FF2_LogError("ERROR: Invalid client index. %s:Event_PlayerSpawn()", this_plugin_name);
	}
}

public Action SummonedBoss_PrepareAbilities(Handle timer, int UserIdx)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		return;

	int bossClientIdx = GetClientOfUserId(UserIdx);
	if(IsValidClient(bossClientIdx))
	{
		int bossIdx = FF2_GetBossIndex(bossClientIdx);
		if(bossIdx >= 0)
		{
			HookAbilities(bossIdx, bossClientIdx);
		}
	}
	else
	{
		FF2_LogError("ERROR: Unable to find respawned player. %s:SummonedBoss_PrepareAbilities()", this_plugin_name);
	}
}


public void MainBoss_PrepareAbilities()
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
	{
		FF2_LogError("ERROR: Abilitypack called when round is over or when gamemode is not FF2. %s:MainBoss_PrepareAbilities()", this_plugin_name);
		return;
	}
	for(int bossClientIdx = 1; bossClientIdx <= MaxClients; bossClientIdx++)
	{
		int bossIdx = FF2_GetBossIndex(bossClientIdx);
		if(bossIdx >= 0)
		{
			HookAbilities(bossIdx, bossClientIdx);
		}
	}
}


public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ClearEverything();
}

public void ClearEverything()
{	
	for(int i =1; i<= MaxClients; i++)
	{
		for(int Num = 0; Num < 10; Num++)
		{
			AMS_GRV[Num][i] = false;
		}
		
		AMS_SIG[i] = false;
		AMS_SHW[i] = false;
	}
}

public void HookAbilities(int bossIdx, int bossClientIdx)
{
	if(bossIdx >= 0)
	{
		//Rage Sigma
		if(FF2_HasAbility(bossIdx, this_plugin_name, SIG))
		{
			//AMS Triggers
			AMS_SIG[bossClientIdx] = AMS_IsSubabilityReady(bossIdx, this_plugin_name, SIG);
			if(AMS_SIG[bossClientIdx])
			{
				AMS_InitSubability(bossIdx, bossClientIdx, this_plugin_name, SIG, "SIG");
			}
			SIG_Pos[bossClientIdx] 				= view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, SIG, 1, 1));
			SIG_Distance[bossClientIdx] 		= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SIG, 2, 1024.0);
			SIG_VelForce[bossClientIdx] 		= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SIG, 3, 1200.0);
			SIG_VelDuration[bossClientIdx] 		= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SIG, 4, 1.3);
			SIG_GravityForce[bossClientIdx] 	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SIG, 5, 20.0);
			SIG_GravityDuration[bossClientIdx] 	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SIG, 6, 2.2);
			SIG_ExplodeBuilding[bossClientIdx] 	= view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, SIG, 7, 1));
			SIG_Damage[bossClientIdx]			= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SIG, 8, 0.0);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SIG, 9, SIG_Particle[bossClientIdx], 512);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, SIG, 10, SIG_ParticlePoint[bossClientIdx], 128);
			
			PrintToServer("Found ability \"%s\" on player %N. Hooking the ability. %s:HookAbilities()", SIG, bossClientIdx, this_plugin_name);
		}
		//Rage Shockwave
		if(FF2_HasAbility(bossIdx, this_plugin_name, SHW))
		{
			//AMS Triggers
			AMS_SHW[bossClientIdx] = AMS_IsSubabilityReady(bossIdx, this_plugin_name, SHW);
			if(AMS_SHW[bossClientIdx])
			{
				AMS_InitSubability(bossIdx, bossClientIdx, this_plugin_name, SHW, "SHW");
			}
			SHW_PlayerDamage[bossClientIdx] 	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SHW, 1, 80.0);
			SHW_BuildDamage[bossClientIdx] 		= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SHW, 2, 375.0);
			SHW_Distance[bossClientIdx] 		= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SHW, 3, 1200.0);
			SHW_KnockbackForce[bossClientIdx] 	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SHW, 4, 1500.0);
			SHW_MinZ[bossClientIdx] 			= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, SHW, 5, 425.0);
			
			PrintToServer("Found ability \"%s\" on player %N. Hooking the ability. %s:HookAbilities()", SHW, bossClientIdx, this_plugin_name);
		}
		//Rage Gravity
		char AbilityName[96], AbilityShort[96];
		for(int Num = 0; Num < 10; Num++)
		{
			Format(AbilityName, sizeof(AbilityName), "rage_gravity_%i", Num);
			if(FF2_HasAbility(bossIdx, this_plugin_name, AbilityName))
			{
				AMS_GRV[Num][bossClientIdx] = AMS_IsSubabilityReady(bossIdx, this_plugin_name, AbilityName);
				if(AMS_GRV[Num][bossClientIdx])
				{
					Format(AbilityShort, sizeof(AbilityShort), "GRV%i", Num);
					AMS_InitSubability(bossIdx, bossClientIdx, this_plugin_name, AbilityName, AbilityShort);
				}
				
				PrintToServer("Found ability \"%s\" on player %N. Hooking the ability. %s:HookAbilities()", AbilityName, bossClientIdx, this_plugin_name);
			}
		}
	}
}

public Action FF2_OnAbility2(int bossIdx, const char[] plugin_name, const char[] ability_name, int status)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		return Plugin_Continue; // Because some FF2 forks still allow RAGE to be activated when the round is over....
	
	int bossClientIdx = GetClientOfUserId(FF2_GetBossUserId(bossIdx));

	//Rage Sigma
	if(!strcmp(ability_name, SIG))
	{
		if(AMS_SIG[bossClientIdx])
		{
			if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability"))
			{
				AMS_SIG[bossClientIdx] = false;
			}
			else
			{
				return Plugin_Continue;
			}
		}
		if(!AMS_SIG[bossClientIdx])
		{
			SIG_Invoke(bossClientIdx);	
		}	
	}
	//Rage Shockwave
	if(!strcmp(ability_name, SHW))
	{
		if(AMS_SHW[bossClientIdx])
		{
			if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability"))
			{
				AMS_SHW[bossClientIdx] = false;
			}
			else
			{
				return Plugin_Continue;
			}
		}
		if(!AMS_SHW[bossClientIdx])
		{
			SHW_Invoke(bossClientIdx);
		}			
	}
	//Rage Gravity
	char AbilityName[96];
	for(int Num = 0; Num < 10; Num++)
	{
		Format(AbilityName, sizeof(AbilityName), "rage_gravity_%i", Num);
		if(!strcmp(ability_name, AbilityName))
		{
			if(AMS_GRV[Num][bossClientIdx])
			{
				if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability"))
				{
					AMS_GRV[Num][bossClientIdx] = false;
				}
				else
				{
					return Plugin_Continue;
				}
			}
			if(!AMS_GRV[Num][bossClientIdx])
			{
				InvokeGravity(bossIdx, bossClientIdx, ability_name, Num);
			}
		}
	}
	return Plugin_Continue;
}

public bool SIG_CanInvoke(int bossClientIdx)
{
	return true;
}

public void SIG_Invoke(int bossClientIdx)
{
	if(AMS_SIG[bossClientIdx])
	{
		FF2_EmitRandomSound(bossClientIdx, "sound_sigma");
	}
	
	float SigmaPos[3];
	if(SIG_Pos[bossClientIdx])
	{
		GetClientEyePosition(bossClientIdx, SigmaPos);
	}
	else
	{
		GetEntPropVector(bossClientIdx, Prop_Send, "m_vecOrigin", SigmaPos);
	}
		
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsValidClient(iClient) && GetClientTeam(iClient) != GetClientTeam(bossClientIdx) && GetClientTeam(iClient) != view_as<int>(TFTeam_Spectator) && IsPlayerAlive(iClient))
		{
			static float ClientPos[3];
			GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", ClientPos);
			if(GetVectorDistance(ClientPos, SigmaPos) <= SIG_Distance[bossClientIdx])
			{
				static float UPVel[3];
				UPVel[2] = SIG_VelForce[bossClientIdx];
				TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, UPVel);
				
				if(SIG_Particle[bossClientIdx][0] != '\0')
				{
					if(SIG_ParticlePoint[bossClientIdx][0] != '\0')
						SIG_iParticle[iClient] = CreateParticle(SIG_Particle[bossClientIdx], SIG_ParticlePoint[bossClientIdx], iClient);
					else
						SIG_iParticle[iClient] = CreateParticle(SIG_Particle[bossClientIdx], "head", iClient);
				}
				

				DataPack pack;
				CreateDataTimer(SIG_VelDuration[bossClientIdx], SIG_FixEverything, pack);
				pack.WriteCell(iClient);
				pack.WriteCell(bossClientIdx);
				pack.WriteFloat(SigmaPos[0]);
				pack.WriteFloat(SigmaPos[1]);
				pack.WriteFloat(SigmaPos[2]);
			}		
		}		
	}
}

public Action SIG_FixEverything(Handle timer, DataPack pack)
{
    int iClient, bossClientIdx;
    float SigmaPos[3];
    /* Set to the beginning and unpack it */
    pack.Reset();
    iClient = pack.ReadCell();
    bossClientIdx = pack.ReadCell();
    SigmaPos[0] = pack.ReadFloat();
    SigmaPos[1] = pack.ReadFloat();
    SigmaPos[2] = pack.ReadFloat();
    
    if(IsValidClient(iClient))
    {
    	if(SIG_Particle[bossClientIdx][0] != '\0' && IsValidEntity(SIG_iParticle[iClient]))
    	{
    		AcceptEntityInput(SIG_iParticle[iClient], "Kill");
    	}
    	
    	SetEntityGravity(iClient, SIG_GravityForce[bossClientIdx]);
    	
    	if(SIG_Damage[bossClientIdx] > 0.0)
    	{
    		SDKHooks_TakeDamage(iClient, bossClientIdx, bossClientIdx, SIG_Damage[bossClientIdx]);
    	}
    	
    	CreateTimer(SIG_GravityDuration[bossClientIdx], FixGravity, iClient, TIMER_FLAG_NO_MAPCHANGE);
    }
    
    int iBuilding = -1;
    while((iBuilding = FindEntityByClassname(iBuilding, "obj_*")) != -1)
    {
    	static float BuildingPos[3];
    	GetEntPropVector(iBuilding, Prop_Send, "m_vecOrigin", BuildingPos);
    	if(GetVectorDistance(BuildingPos, SigmaPos) <= SIG_Distance[bossClientIdx])
    	{
			static char strClassname[15];
			GetEntityClassname(iBuilding, strClassname, sizeof(strClassname));
			if(StrEqual(strClassname, "obj_dispenser") || StrEqual(strClassname, "obj_teleporter") || StrEqual(strClassname, "obj_sentrygun"))
			{
				int iOwner = GetEntPropEnt(iBuilding, Prop_Send, "m_hBuilder");
				if(IsValidClient(iOwner) && GetClientTeam(iOwner) != GetClientTeam(bossClientIdx))
				{
					SDKHooks_TakeDamage(iBuilding, bossClientIdx, bossClientIdx, 15.0, DMG_GENERIC | DMG_PREVENT_PHYSICS_FORCE, -1);
					if(IsValidEntity(iBuilding))
					{
						SetVariantInt(0); AcceptEntityInput(iBuilding, "SetHealth");
						SetVariantInt(1); AcceptEntityInput(iBuilding, "RemoveHealth");
					}
				}
			}
		}
	}
    return Plugin_Continue;
}


public bool SHW_CanInvoke(int bossClientIdx)
{
	return true;
}

public void SHW_Invoke(int bossClientIdx)
{
	if(AMS_SHW[bossClientIdx])
	{
		FF2_EmitRandomSound(bossClientIdx, "sound_shockwave");
	}
	
	static float fBossPos[3];
	GetEntPropVector(bossClientIdx, Prop_Send, "m_vecOrigin", fBossPos);
	
	//Player Damage
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsValidClient(iClient))
		{
			if(IsPlayerAlive(iClient) && GetClientTeam(iClient) != GetClientTeam(bossClientIdx))
			{
				static float ClientPos[3];
				GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", ClientPos);
				float flDist = GetVectorDistance(ClientPos, fBossPos);
				
				if(flDist <= SHW_Distance[bossClientIdx])
				{
					//Knockback
					static float angles[3], velocity[3];
					GetVectorAnglesTwoPoints(fBossPos, ClientPos, angles);
					GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
					
					ScaleVector(velocity, SHW_KnockbackForce[bossClientIdx] - (SHW_KnockbackForce[bossClientIdx] * flDist / SHW_Distance[bossClientIdx]));
					if(velocity[2] < SHW_MinZ[bossClientIdx])
						velocity[2] = SHW_MinZ[bossClientIdx];
					TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, velocity);
				
					// Player Damage
					float damage = SHW_PlayerDamage[bossClientIdx] - (SHW_PlayerDamage[bossClientIdx] * flDist / SHW_Distance[bossClientIdx]);
					if(damage > 0.0)
						SDKHooks_TakeDamage(iClient, bossClientIdx, bossClientIdx, damage, DMG_GENERIC | DMG_PREVENT_PHYSICS_FORCE, -1);
				}	
			}
		}
	}
	
	// Building Damage
	for(int pass = 0; pass < 3; pass++)
	{
		static char classname[32];
		
		switch(pass)
		{
			case 0:classname = "obj_sentrygun";
			case 1:classname = "obj_dispenser";
			case 2:classname = "obj_teleporter";
		}

		int iBuilding = -1;
		while((iBuilding = FindEntityByClassname(iBuilding, classname)) != -1)
		{
			int iOwner = GetEntPropEnt(iBuilding, Prop_Send, "m_hBuilder");
			if(IsValidClient(iOwner) && GetClientTeam(iOwner) != GetClientTeam(bossClientIdx))
			{
				static float fBuildingPos[3];
				GetEntPropVector(iBuilding, Prop_Send, "m_vecOrigin", fBuildingPos);
				float flDist = GetVectorDistance(fBuildingPos, fBossPos);
			
				if(flDist <= SHW_Distance[bossClientIdx])
				{
					float damage = SHW_BuildDamage[bossClientIdx] - (SHW_BuildDamage[bossClientIdx] * flDist / SHW_Distance[bossClientIdx]);
					if (damage > 0.0)
						SDKHooks_TakeDamage(iBuilding, bossClientIdx, bossClientIdx, damage, DMG_GENERIC | DMG_PREVENT_PHYSICS_FORCE, -1);
				}
			}
		}	
	}
}

public bool GRV0_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool GRV1_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool GRV2_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool GRV3_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool GRV4_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool GRV5_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool GRV6_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool GRV7_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool GRV8_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool GRV9_CanInvoke(int bossClientIdx)
{
	return true;
}

public void GRV0_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	InvokeGravity(bossIdx, bossClientIdx, "rage_gravity_0", 0);
}

public void GRV1_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	InvokeGravity(bossIdx, bossClientIdx, "rage_gravity_1", 1);
}

public void GRV2_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	InvokeGravity(bossIdx, bossClientIdx, "rage_gravity_2", 2);
}

public void GRV3_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	InvokeGravity(bossIdx, bossClientIdx, "rage_gravity_3", 3);
}

public void GRV4_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	InvokeGravity(bossIdx, bossClientIdx, "rage_gravity_4", 4);
}

public void GRV5_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	InvokeGravity(bossIdx, bossClientIdx, "rage_gravity_5", 5);
}

public void GRV6_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	InvokeGravity(bossIdx, bossClientIdx, "rage_gravity_6", 6);
}

public void GRV7_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	InvokeGravity(bossIdx, bossClientIdx, "rage_gravity_7", 7);
}

public void GRV8_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	InvokeGravity(bossIdx, bossClientIdx, "rage_gravity_8", 8);
}

public void GRV9_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	InvokeGravity(bossIdx, bossClientIdx, "rage_gravity_9", 9);
}

public void InvokeGravity(int bossIdx, int bossClientIdx, const char[] ability_name, int Num)
{
	GRV_EffectMode[Num][bossClientIdx] 	= FF2_GetAbilityArgument(bossIdx, this_plugin_name, ability_name, 1, 1);
	GRV_Value[Num][bossClientIdx] 		= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 2, 1.0);
	GRV_Distance[Num][bossClientIdx] 	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 3, 1024.0);
	GRV_Duration[Num][bossClientIdx] 	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 4, 10.0);
	
	
	if(AMS_GRV[Num][bossClientIdx])
	{
		char AbilitySound[128];
		Format(AbilitySound, sizeof(AbilitySound), "sound_gravity_%i", Num);
		FF2_EmitRandomSound(bossClientIdx, AbilitySound);
	}
	
	float BossPos[3], ClientPos[3];
	
	GetEntPropVector(bossClientIdx, Prop_Send, "m_vecOrigin", BossPos);
	for(int iClient = 1 ; iClient <= MaxClients; iClient++)
	{
		if(IsValidClient(iClient))
		{
			GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", ClientPos);
			if(GetVectorDistance(BossPos,ClientPos) <= GRV_Distance[Num][bossClientIdx])
			{
				switch(GRV_EffectMode[Num][bossClientIdx])
				{
					case 1:
					{
						if(GetClientTeam(iClient) != GetClientTeam(bossClientIdx))					//for only enemy team
							SetEntityGravity(iClient, GRV_Value[Num][bossClientIdx]);
					}
					case 2:
					{
						if(iClient == bossClientIdx) //For only boss
							SetEntityGravity(iClient, GRV_Value[Num][bossClientIdx]);
					}
					case 3:
					{
						if(GetClientTeam(iClient) == GetClientTeam(bossClientIdx))					//for only boss team
							SetEntityGravity(iClient, GRV_Value[Num][bossClientIdx]);
					}
					case 4:
					{
						if(iClient != bossClientIdx) // everyone expect boss
							SetEntityGravity(iClient, GRV_Value[Num][bossClientIdx]);
					}
					case 5:
					{
						SetEntityGravity(iClient, GRV_Value[Num][bossClientIdx]); // everyone in range
					}
				}
				//int UserIdx = GetClientUserId(iClient);
				CreateTimer(GRV_Duration[Num][bossClientIdx], FixGravity, iClient, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action FixGravity(Handle timer, int iClient/*UserIdx*/)
{
	//int iClient = GetClientOfUserId(UserIdx);
	if(/*!iClient && */IsValidClient(iClient) && IsPlayerAlive(iClient))
	{
		// GetClientFromSerial and GetClientOfUserId returns 0 if serial was invalid aka that client left, only checking if it's not 0 should be enough
		SetEntityGravity(iClient, 1.0);
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	if(client <= 0 || client > MaxClients) return false;
	if(!IsClientInGame(client) || !IsClientConnected(client)) return false;
	if(IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;		
}

stock float GetVectorAnglesTwoPoints(const float startPos[3], const float endPos[3], float angles[3])
{
	static float tmpVec[3];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}

stock int CreateParticle(const char[] particle, const char[] attachpoint, int client)
{
    float pos[3];
    
    GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
    
    int entity = CreateEntityByName("info_particle_system");
    TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
    DispatchKeyValue(entity, "effect_name", particle);
    
    SetVariantString("!activator");
    AcceptEntityInput(entity, "SetParent", client, entity, 0);
    
    SetVariantString(attachpoint);
    AcceptEntityInput(entity, "SetParentAttachment", entity, entity, 0);
    
    char t_Name[128];
    Format(t_Name, sizeof(t_Name), "target%i", client);
    
    DispatchKeyValue(entity, "targetname", t_Name);
    
    DispatchSpawn(entity);
    ActivateEntity(entity);
    AcceptEntityInput(entity, "start");
    return entity;
}

public void FF2_EmitRandomSound(int bossClientIdx, const char[] keyvalue)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	char sound[PLATFORM_MAX_PATH]; float pos[3];
	if(FF2_RandomSound(keyvalue, sound, sizeof(sound), bossIdx))
	{
		GetEntPropVector(bossClientIdx, Prop_Send, "m_vecOrigin", pos);
		EmitSoundToAll(sound, bossClientIdx, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, bossClientIdx, pos, NULL_VECTOR, true, 0.0);
		EmitSoundToAll(sound, bossClientIdx, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, bossClientIdx, pos, NULL_VECTOR, true, 0.0);
					
		for(int iClient = 1; iClient <= MaxClients; iClient++)
		{
			if(IsClientInGame(iClient) && iClient != bossClientIdx)
			{
				EmitSoundToClient(iClient, sound, bossClientIdx, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, bossClientIdx, pos, NULL_VECTOR, true, 0.0);
				EmitSoundToClient(iClient, sound, bossClientIdx, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, bossClientIdx, pos, NULL_VECTOR, true, 0.0);
			}
		}
	}
}

// Showckwave
public void SHW_ChangeFundamentalStats(int bossClientIdx, float PlayerDamage, float BuildingDamage, float Radius, float KnockbackForce, float MinZ_Insenity)
{
	if(IsValidClient(bossClientIdx))
	{
		if(PlayerDamage != -1.0)
		{
			SHW_PlayerDamage[bossClientIdx] = PlayerDamage;
		}
		if(BuildingDamage != -1.0)
		{
			SHW_BuildDamage[bossClientIdx] = BuildingDamage;
		}
		if(Radius != -1.0)
		{
			SHW_Distance[bossClientIdx] = Radius;
		}
		if(KnockbackForce != -1.0)
		{
			SHW_KnockbackForce[bossClientIdx] = KnockbackForce;
		}
		if(MinZ_Insenity)
		{
			SHW_MinZ[bossClientIdx] = MinZ_Insenity;
		}
	}
}

//Sigma
public void SIG_ChangeFundamentalStats(int bossClientIdx, int Position, float Radius, float VelocityForce, float VelocityDuration,
float GravityForce, float GravityDuration, int ExplodeBuilding, float Damage, const char[] ParticleName, const char[] ParticlePos)
{
	if(IsValidClient(bossClientIdx))
	{
		if(Position != -1)
		{
			if(view_as<bool>(Position))
			{
				SIG_Pos[bossClientIdx] = true;
			}
			else
			{
				SIG_Pos[bossClientIdx] = false;
			}
		}
		if(Radius != -1.0)
		{
			SIG_Distance[bossClientIdx] = Radius;
		}
		if(VelocityForce != -1.0)
		{
			SIG_VelForce[bossClientIdx] = VelocityForce;
		}
		if(VelocityDuration != -1.0)
		{
			SIG_VelDuration[bossClientIdx] = VelocityDuration;
		}
		if(GravityForce != -1.0)
		{
			SIG_GravityForce[bossClientIdx] = GravityForce;
		}
		if(GravityDuration != -1.0)
		{
			SIG_GravityDuration[bossClientIdx] = GravityDuration;
		}
		if(ExplodeBuilding != -1)
		{
			if(view_as<bool>(Position))
			{
				SIG_ExplodeBuilding[bossClientIdx] = true;
			}
			else
			{
				SIG_ExplodeBuilding[bossClientIdx] = false;
			}
		}
		if(Damage != -1.0)
		{
			SIG_Damage[bossClientIdx] = Damage;
		}
		if(ParticleName[0] != '\0')
		{
			Format(SIG_Particle[bossClientIdx], 512, "%s", ParticleName);
			//SIG_Particle[bossClientIdx][0] = ParticleName;
		}
		if(ParticlePos[0] != '\0')
		{
			Format(SIG_ParticlePoint[bossClientIdx], 512, "%s", ParticlePos);
			//SIG_ParticlePoint[bossClientIdx][0] = ParticlePos;
		}
	}
}

//Fix Gravity
public void GRV_FixGravity(int iClient)
{
	if(iClient == -1)
	{
		for(int i = 1; i<=MaxClients;i++)
		{
			if(IsValidClient(iClient) && IsPlayerAlive(iClient))
			{
				SetEntityGravity(iClient, 1.0);
			}
		}
	}
	else
	{
		if(IsValidClient(iClient) && IsPlayerAlive(iClient))
		{
			SetEntityGravity(iClient, 1.0);
		}
	}
}