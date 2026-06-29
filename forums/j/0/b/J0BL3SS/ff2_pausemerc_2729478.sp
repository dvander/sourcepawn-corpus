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

/*
 * Defines "rage_pausetime"
 */
 #define PST "pausemerc"
bool AMS_PST[MAXPLAYERS+1];					//internal - AMS Trigger
float PST_DELAY[MAXPLAYERS+1];				//arg1
float PST_Duration[MAXPLAYERS+1];			//arg2
float PST_Distance[MAXPLAYERS+1];			//arg3
int PST_PauseType[MAXPLAYERS+1];			//arg4
bool PST_FriendlyFire[MAXPLAYERS+1];		//arg5
char PST_Conditions[MAXPLAYERS+1][768];		//arg6
bool PST_StopDamage[MAXPLAYERS+1];			//arg7
float PST_DamageMax;						//arg8
bool PST_TurnProjectile[MAXPLAYERS+1]; 		//arg9
float PST_MinDmgProjectile[MAXPLAYERS+1]; 	//arg10
float PST_MaxDmgProjectile[MAXPLAYERS+1]; 	//arg11
bool PST_CritProjectile[MAXPLAYERS+1]; 		//arg12

float fl_BaseVelocity[5256][3]; 		//internal
float fl_BaseAngle[5256][3];			//internal
float fl_BaseOrigin[5256][3];			//internal
MoveType g_iBaseMoveType[5256];			//internal
float fl_Damage[MAXPLAYERS+1];			//internal

//float fl_DetonateTime[5256]; 			//internal - Please no more errors.
bool PauseTime = false;

public Plugin myinfo = 
{
	name = "Freak Fortress 2: PAUSEMERC",
	author = "J0BL3SS, LeAlex14",
	description = "Stop Velocity... All world frozen",
	version = "3.0.2",
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
	for(int i = 1; i <= MaxClients; i++)
	{
		AMS_PST[i] = false;
		SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	MainBoss_PrepareAbilities();
	CreateTimer(1.0, TimerHookSpawn, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ClearTriggers();
}

public void ClearTriggers()
{	
	for(int i = 1; i <= MaxClients; i++)
	{
		AMS_PST[i] = false;
		SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action TimerHookSpawn(Handle timer)
{
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int UserIdx = GetEventInt(event, "userid");
	int iClient = GetClientOfUserId(UserIdx);
	
	if(iClient != 0)
	{
		CreateTimer(0.3, SummonedBoss_PrepareAbilities, UserIdx, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		LogError("ERROR: Invalid client index. %s:Event_PlayerSpawn()", this_plugin_name);
	}
}

public Action SummonedBoss_PrepareAbilities(Handle timer, int UserIdx)
{
	int bossClientIdx = GetClientOfUserId(UserIdx);
	if(bossClientIdx != 0)
	{
		int bossIdx = FF2_GetBossIndex(bossClientIdx);
		if(bossIdx >= 0)
		{
			HookAbilities(bossIdx, bossClientIdx);
		}
		else
		{
			PrintToServer("WARNING: Respawned player has no boss index. %s:SummonedBoss_PrepareAbilities()", this_plugin_name);
			//LogError("WARNING: Respawned player has no boss index. %s:SummonedBoss_PrepareAbilities()", this_plugin_name);
		}
	}
	else
	{
		LogError("ERROR: Unable to find respawned player. %s:SummonedBoss_PrepareAbilities()", this_plugin_name);
	}
}

public void MainBoss_PrepareAbilities()
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
	{
		LogError("ERROR: Abilitypack called when round is over or when gamemode is not FF2. %s:MainBoss_PrepareAbilities()", this_plugin_name);
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

public void HookAbilities(int bossIdx, int bossClientIdx)
{
	if(bossIdx >= 0)	//just in case
	{
		if(FF2_HasAbility(bossIdx, this_plugin_name, PST))
		{
			//AMS Triggers
			AMS_PST[bossClientIdx] = AMS_IsSubabilityReady(bossIdx, this_plugin_name, PST);
			if(AMS_PST[bossClientIdx])
			{
				AMS_InitSubability(bossIdx, bossClientIdx, this_plugin_name, PST, "PST");
			}
			
			PST_DELAY[bossClientIdx]			= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, PST, 1, 0.0);
			PST_Duration[bossClientIdx] 		= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, PST, 2, 10.0);
			PST_Distance[bossClientIdx] 		= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, PST, 3, FF2_GetRageDist(bossIdx, this_plugin_name, NULL_STRING));
			PST_PauseType[bossClientIdx] 		= FF2_GetAbilityArgument(bossIdx, this_plugin_name, PST, 4, 4);
			PST_FriendlyFire[bossClientIdx] 	= view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, PST, 5, 1));
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, PST, 6, PST_Conditions[bossClientIdx], 768);
			PST_StopDamage[bossClientIdx] 		= view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, PST, 7, 0));
			PST_DamageMax						= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, PST, 8, 0.0);
			PST_TurnProjectile[bossClientIdx] 	= view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, PST, 9, 0));
			PST_MaxDmgProjectile[bossClientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, PST, 10, 0.0);
			PST_MinDmgProjectile[bossClientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, PST, 11, 0.0);
			PST_CritProjectile[bossClientIdx] 	= view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, PST, 12, 0));
		}
	}
}

public Action FF2_OnAbility2(int bossIdx, const char[] plugin_name, const char[] ability_name, int status)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		return Plugin_Continue; // Because some FF2 forks still allow RAGE to be activated when the round is over....
	
	int bossClientIdx = GetClientOfUserId(FF2_GetBossUserId(bossIdx));
	
	if(!strcmp(ability_name, PST))
	{
		if(AMS_PST[bossClientIdx])
		{
			if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability"))
			{
				AMS_PST[bossClientIdx] = false;
			}
			else
			{
				return Plugin_Continue;
			}
		}
		if(!AMS_PST[bossClientIdx])
		{
			PST_Invoke(bossClientIdx);
		}
	}
	return Plugin_Continue;
}

public bool PST_CanInvoke(int bossClientIdx)
{
	return true;
}

public void PST_Invoke(int bossClientIdx)
{
	CreateTimer(PST_DELAY[bossClientIdx], PauseTheWorld, bossClientIdx, TIMER_FLAG_NO_MAPCHANGE);
}

public Action PauseTheWorld(Handle timer, int bossClientIdx)
{
	float ClientPos[3], BossPos[3];
	GetEntPropVector(bossClientIdx, Prop_Send, "m_vecOrigin", BossPos);
	
	if(PST_PauseType[bossClientIdx] == 1 || PST_PauseType[bossClientIdx] == 3 || PST_PauseType[bossClientIdx] == 4)
	{
		for(int iClient = 1; iClient <= MaxClients; iClient++)
		{
			if(IsValidClient(iClient))
			{
				GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", ClientPos);
				if(GetVectorDistance(BossPos, ClientPos) <= PST_Distance[bossClientIdx])
				{
					if(PST_Conditions[bossClientIdx][0]!='\0')
					{
						if(!IsPlayerInSpecificConditions(iClient, PST_Conditions[bossClientIdx]))
						{
							if(PST_FriendlyFire[bossClientIdx])
							{
								if(bossClientIdx != iClient)
									Pause_Client(iClient, bossClientIdx);
							}
							else
							{
								if(GetClientTeam(iClient) != FF2_GetBossTeam() && bossClientIdx != iClient)
									Pause_Client(iClient, bossClientIdx);
							}	
						}
						else
						{
							PrintToServer("ERROR: Something went wrong at arg6, %s:PauseTheWorld()", this_plugin_name);
						}
					}
					else
					{
						if(PST_FriendlyFire[bossClientIdx])
						{
							if(bossClientIdx != iClient)
								Pause_Client(iClient, bossClientIdx);
						}
						else
						{
							if(GetClientTeam(iClient) != FF2_GetBossTeam() && bossClientIdx != iClient)
								Pause_Client(iClient, bossClientIdx);
						}
					}
				}
			}
		}
	}
	if(PST_PauseType[bossClientIdx] == 2 || PST_PauseType[bossClientIdx] == 3 || PST_PauseType[bossClientIdx] == 4)
	{
		int iEnt = -1;
		while((iEnt = FindEntityByClassname(iEnt, "tf_projectile_*")) != -1)
		{
			GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fl_BaseOrigin[iEnt]);
			if(GetVectorDistance(BossPos, fl_BaseOrigin[iEnt]) <= PST_Distance[bossClientIdx])
			{
				if(IsValidEdict(iEnt) && IsValidEntity(iEnt))
					Pause_Projectile(iEnt, bossClientIdx);
			}
		}
	}
	if(PST_PauseType[bossClientIdx] == 1 || PST_PauseType[bossClientIdx] == 4)
	{
		int iEnt = -1;
		while((iEnt = FindEntityByClassname(iEnt, "obj_*")) != -1)
		{
			static float BuildingPos[3];
			GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", BuildingPos);
			if(GetVectorDistance(BossPos, BuildingPos) <= PST_Distance[bossClientIdx])
			{
				if(IsValidEdict(iEnt) && IsValidEntity(iEnt))
					Pause_Building(iEnt, bossClientIdx);
			}
		}
	}
}

//
//	******************************
// 	**	Pause Entity & Clients	**
//	******************************
//
public void Pause_Projectile(int iEnt, int bossClientIdx)
{
	if(IsValidEdict(iEnt) && IsValidEntity(iEnt))
	{
		//Store Information
		GetEntPropVector(iEnt, Prop_Data, "m_vecVelocity", fl_BaseVelocity[iEnt]);
		GetEntPropVector(iEnt, Prop_Data, "m_angRotation", fl_BaseAngle[iEnt]);
		g_iBaseMoveType[iEnt] = GetEntityMoveType(iEnt);
		
		//Stop Movement
		SetEntPropVector(iEnt, Prop_Data, "m_vecVelocity", NULL_VECTOR);
		SetEntityMoveType(iEnt, MOVETYPE_NONE);
		
		//Timers
		DataPack prj;
		CreateDataTimer(PST_Duration[bossClientIdx], UnPause_Projectile, prj);
		prj.WriteCell(iEnt);
		prj.WriteCell(bossClientIdx);
	}
}

public void Pause_Client(int iClient, int bossClientIdx)
{
	if(IsValidClient(iClient))
	{
		//Store Information
		GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", fl_BaseVelocity[iClient]);
		GetEntPropVector(iClient, Prop_Data, "m_angRotation", fl_BaseAngle[iClient]);
		g_iBaseMoveType[iClient] = GetEntityMoveType(iClient);
			
		//Pause Animations
		SetEntProp(iClient, Prop_Send, "m_bIsPlayerSimulated", 0);
		SetEntProp(iClient, Prop_Send, "m_bSimulatedEveryTick", 0);
		SetEntProp(iClient, Prop_Send, "m_bAnimatedEveryTick", 0);
		SetEntProp(iClient, Prop_Send, "m_bClientSideAnimation", 0);
		SetEntProp(iClient, Prop_Send, "m_bClientSideFrameReset", 1);
			
		//Pause Movement
		TF2_AddCondition(iClient, TFCond_FreezeInput, -1.0);
		SetEntityMoveType(iClient, MOVETYPE_NONE);
		SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
		PauseTime = true;
			
		//Timers
		DataPack client;
		CreateDataTimer(PST_Duration[bossClientIdx], UnPause_Client, client);
		client.WriteCell(iClient);
		client.WriteCell(bossClientIdx);
	}
}

public void Pause_Building(int iEnt, int bossClientIdx)
{
	if(IsValidEdict(iEnt) && IsValidEntity(iEnt))
	{
		SetEntProp(iEnt, Prop_Send, "m_bDisabled", 1);
		
		//Timers
		DataPack build;
		CreateDataTimer(PST_Duration[bossClientIdx], UnPause_Building, build);
		build.WriteCell(iEnt);
		//build.WriteCell(bossClientIdx);
	}
}

//
//	*********************************
// 	*	 Unpause Entity & Clients	*
//	*********************************
//
public Action UnPause_Projectile(Handle timer, DataPack prj)
{
	int iEnt, bossClientIdx;
	/* Set to the beginning and unpack it */
	prj.Reset();
	iEnt = prj.ReadCell();
	bossClientIdx = prj.ReadCell();
	
	//Unpause
	if(IsValidEdict(iEnt) && IsValidEntity(iEnt))
	{
		SetEntPropVector(iEnt, Prop_Data, "m_angRotation", fl_BaseAngle[iEnt]);
		SetEntPropVector(iEnt, Prop_Data, "m_vecVelocity", fl_BaseVelocity[iEnt]);
		SetEntityMoveType(iEnt, g_iBaseMoveType[iEnt]);
		
		if(PST_TurnProjectile[bossClientIdx])
		{
			for(int i = 0; i<3 ;i++)
			{
				fl_BaseVelocity[iEnt][i] *= -1.0;
				fl_BaseAngle[iEnt][i] *= -1.0;
			}
			SetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity", bossClientIdx);
			if(PST_CritProjectile[bossClientIdx])
			{
				SetEntProp(iEnt, Prop_Send, "m_bCritical", 1, 1); //uuhh.. ok
			}
			if(PST_MinDmgProjectile[bossClientIdx] > 0.0)
			{
				//SetEntPropFloat(iSpell, Prop_Send, "m_flDamage", GetRandomFloat(PST_MinDmgProjectile[bossClientIdx], PST_MaxDmgProjectile[bossClientIdx]));
				SetEntDataFloat(iEnt, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, GetRandomFloat(PST_MinDmgProjectile[bossClientIdx], PST_MaxDmgProjectile[bossClientIdx]), true);
			}
			SetEntProp(iEnt, Prop_Send, "m_iTeamNum", GetClientTeam(bossClientIdx), 1);
			SetEntProp(iEnt, Prop_Send, "m_nSkin", (GetClientTeam(bossClientIdx)-2));
			TeleportEntity(iEnt, NULL_VECTOR, fl_BaseAngle[iEnt], fl_BaseVelocity[iEnt]);
		}
	}
}

public Action UnPause_Client(Handle timer, DataPack client)
{
	int iClient, bossClientIdx;
	/* Set to the beginning and unpack it */
	client.Reset();
	iClient = client.ReadCell();
	bossClientIdx = client.ReadCell();
	//Unpause
	if(IsValidClient(iClient))
	{
		//Set Stored Vectors
		SetEntPropVector(iClient, Prop_Data, "m_angRotation", fl_BaseAngle[iClient]);
		SetEntPropVector(iClient, Prop_Data, "m_vecVelocity", fl_BaseVelocity[iClient]);
		//Unpause Animations
		SetEntProp(iClient, Prop_Send, "m_bIsPlayerSimulated", 1);
		SetEntProp(iClient, Prop_Send, "m_bSimulatedEveryTick", 1);
		SetEntProp(iClient, Prop_Send, "m_bAnimatedEveryTick", 1);
		SetEntProp(iClient, Prop_Send, "m_bClientSideAnimation", 1);
		SetEntProp(iClient, Prop_Send, "m_bClientSideFrameReset", 0);
		//Enable Movement
		TF2_RemoveCondition(iClient, TFCond_FreezeInput);
		SetEntityMoveType(iClient, g_iBaseMoveType[iClient]);
		
		PauseTime = false;
		SDKUnhook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
		if(fl_Damage[iClient] > 0)
		{
			SDKHooks_TakeDamage(iClient, bossClientIdx, bossClientIdx, fl_Damage[iClient]);
			fl_Damage[iClient] = 0.0;
		}
	}
}

public Action UnPause_Building(Handle timer, DataPack build)
{
	int iEnt; //bossClientIdx;
	/* Set to the beginning and unpack it */
	build.Reset();
	iEnt = build.ReadCell();
	//bossClientIdx = build.ReadCell();
	
	//Unpause
	if(IsValidEdict(iEnt) && IsValidEntity(iEnt))
	{
		SetEntProp(iEnt, Prop_Send, "m_bDisabled", 0);
	}
}

//Damage Hooks
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(GetClientTeam(attacker) == FF2_GetBossTeam() && victim != attacker && IsValidClient(attacker))
	{
		if(PauseTime && PST_StopDamage[attacker])
		{
			fl_Damage[victim] += damage;
			if(PST_DamageMax <= fl_Damage[victim] && PST_DamageMax > 0)
			{
				fl_Damage[victim] = PST_DamageMax;
			}
			damage = 0.0;
			return Plugin_Changed;		
		}		
	}
	return Plugin_Continue;		
}

//
//	**************
// 	**	Stocks	**
//	**************
//
stock bool IsValidClient(int client)
{
	if(client <= 0 || client > MaxClients) return false;
	if(!IsClientInGame(client) || !IsClientConnected(client)) return false;
	if(IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;		
}

stock bool IsPlayerInSpecificConditions(int client, char[] cond)
{
	char conds[32][32];
	int count = ExplodeString(cond, " ; ", conds, sizeof(conds), sizeof(conds));
	if (count > 0)
	{
		for (int i = 0; i < count; i++)
		{
			return TF2_IsPlayerInCondition(client, view_as<TFCond>(StringToInt(conds[i])));
		}
	}
	return false;
}