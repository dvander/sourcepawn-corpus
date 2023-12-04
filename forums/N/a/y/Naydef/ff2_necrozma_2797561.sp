#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <ff2_ams>

#pragma newdecls required
#pragma semicolon 1


public Plugin myinfo =
{
	name = "Necrozma Abilties",
	description = "",
	author = "death, noobis",
	version = "1.1",
	url = ""
};

int BossTeam = 3;
int g_iBoss;
bool Rain_TriggerAMS[MAXPLAYERS+1];
float Rain_Damage[MAXPLAYERS+1];
float Rain_Speed[MAXPLAYERS+1];
float Rain_Radius[MAXPLAYERS+1];
float Rain_BlastRadius[MAXPLAYERS+1];
float Rain_Delay[MAXPLAYERS+1];
int Rain_MaxSpawns[MAXPLAYERS+1];
bool Rain_FreezeMovement[MAXPLAYERS+1];
int Rain_Shots[MAXPLAYERS+1];

public void OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	if(FF2_GetRoundState()==1)
	{
		BossTeam = FF2_GetBossTeam();
		HookAbilities();
	}
}

public void Event_RoundStart(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	BossTeam = FF2_GetBossTeam();
	HookAbilities();
}

public void Event_RoundEnd(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	for(int iClient=1; iClient<=MaxClients; iClient++)
	{
		if(IsValidClient(iClient, false, false))
		{
			SDKUnhook(iClient, SDKHook_PreThink, Rain_Think);
		}
		Rain_Shots[iClient] = 0;
		iClient++;
	}
}

public void HookAbilities()
{
	for(int iIndex; iIndex < MAXPLAYERS; iIndex++)
	{
		int iBoss=GetClientOfUserId(FF2_GetBossUserId(iIndex));
		if(!IsValidClient(iBoss))
		{
			break;
		}
		if(FF2_HasAbility(iIndex, this_plugin_name, "rage_necrozma"))
		{
			if((Rain_TriggerAMS[iBoss] = FF2_GetAbilityArgumentBool(iIndex, this_plugin_name, "rage_necrozma", 1)))
			{
				AMS_InitSubability(iIndex, iBoss, this_plugin_name, "rage_necrozma", "RAIN");
			}
			Rain_Damage[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_necrozma", 2, 0.0);
			Rain_Speed[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_necrozma", 3, 0.0);
			Rain_Radius[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_necrozma", 4, 0.0);
			Rain_BlastRadius[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_necrozma", 5, 0.0);
			Rain_Delay[iBoss] = FF2_GetAbilityArgumentFloat(iIndex, this_plugin_name, "rage_necrozma", 6, 0.0);
			Rain_MaxSpawns[iBoss] = FF2_GetAbilityArgument(iIndex, this_plugin_name, "rage_necrozma", 7, 0);
			Rain_FreezeMovement[iBoss] = FF2_GetAbilityArgumentBool(iIndex, this_plugin_name, "rage_necrozma", 8);
			g_iBoss = iBoss;
		}
	}
}

public void OnEntityDestroyed(int iEntity)
{
	if(iEntity==-1 || iEntity>2048)
	{
		return;
	}
	char sClassName[96];
	if (GetEntityClassname(iEntity, sClassName, sizeof(sClassName)))
	{
		if (!strcmp(sClassName, "tf_projectile_energy_ball", true))
		{
			char name[64];
			GetEntPropString(iEntity, Prop_Data, "m_target", name, sizeof(name));
			if(!StrEqual(name, "ff2_necrozma", false))
			{
				return;
			}
			float vEntOrigin[3];
			float vClientOrigin[3];
			GetEntPropVector(iEntity, Prop_Data, "m_vecAbsOrigin", vEntOrigin);
			for(int iClient = 1; iClient<=MaxClients; iClient++)
			{
				if(IsClientInGame(iClient) && IsPlayerAlive(iClient) && BossTeam != GetClientTeam(iClient))
				{
					GetClientAbsOrigin(iClient, vClientOrigin);
					if(GetVectorDistance(vEntOrigin, vClientOrigin, false) <= Rain_BlastRadius[g_iBoss])
					{
						SDKHooks_TakeDamage(iClient, iEntity, g_iBoss, Rain_Damage[g_iBoss], 0, -1, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
	}
}

public Action FF2_OnAbility2(int iBoss, const char[] pluginName, const char[] abilityName, int status)
{
	int iClient = GetClientOfUserId(FF2_GetBossUserId(iBoss));
	if(!strcmp(abilityName, "rage_necrozma", true))
	{
		Rage_Rain(iClient);
	}
	return Plugin_Continue;
}

public bool RAIN_CanInvoke(int iClient)
{
	return true;
}

public void Rage_Rain(int iClient)
{
	if(Rain_TriggerAMS[iClient])
	{
		return;
	}
	RAIN_Invoke(iClient);
}

public void RAIN_Invoke(int iClient)
{
	SDKHook(iClient, SDKHook_PreThink, Rain_Think);
	if(Rain_FreezeMovement[iClient])
	{
		SetEntityMoveType(iClient, MOVETYPE_NONE);
	}
	int iBoss = FF2_GetBossIndex(iClient);
	char sSound[256];
	float vPos[3];
	GetClientAbsOrigin(iClient, vPos);
	if(FF2_RandomSound("sound_ability", sSound, sizeof(sSound), iBoss, 5))
	{
		EmitSoundToAll(sSound, iClient, 0, 75, 0, 1.0, 100, iClient, vPos, NULL_VECTOR, true, 0.0);
		for (int iEnemy = 1; iEnemy < MaxClients; iEnemy++)
		{
			if(IsClientInGame(iEnemy) && iClient!=iEnemy)
			{
				EmitSoundToClient(iEnemy, sSound, iClient, 0, 75, 0, 1.0, 100, iClient, vPos, NULL_VECTOR, true, 0.0);
			}
			iEnemy--;
		}
	}
}

public void Rain_Think(int iClient)
{
	if (!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
	{
		SDKUnhook(iClient, SDKHook_PreThink, Rain_Think);
	}
	if (Rain_MaxSpawns[iClient] <= Rain_Shots[iClient])
	{
		Rain_Shots[iClient] = 0;
		SDKUnhook(iClient, SDKHook_PreThink, Rain_Think);
		if (Rain_FreezeMovement[iClient])
		{
			SetEntityMoveType(iClient, MOVETYPE_WALK);
		}
	}
	static float flShootAt;
	if (Rain_Delay[iClient] <= 0.0 || GetEngineTime() >= flShootAt)
	{
		int iRocket = CreateEntityByName("tf_projectile_energy_ball", -1);
		if (IsValidEdict(iRocket))
		{
			int iRandom = GetRandomInt(1, 3);
			SetEntPropEnt(iRocket, Prop_Send, "m_hOwnerEntity", iClient, 0);
			SetVariantInt(BossTeam);
			AcceptEntityInput(iRocket, "TeamNum", -1, -1, 0);
			SetVariantInt(BossTeam);
			AcceptEntityInput(iRocket, "SetTeam", -1, -1, 0);
			float vOrigin[3];
			float vAngles[3];
			float vVelocity[3];
			GetClientAbsOrigin(iClient, vOrigin);
			vOrigin[0] += GetRandomFloat(-Rain_Radius[iClient], Rain_Radius[iClient]);
			vOrigin[1] += GetRandomFloat(-Rain_Radius[iClient], Rain_Radius[iClient]);
			vOrigin[2] += 800.0;
			vAngles[0] = GetRandomFloat(50.0, 89.5);
			vAngles[1] = GetRandomFloat(-179.9, 179.9);
			vAngles[2] = 0.0;
			GetAngleVectors(vAngles, vVelocity, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(vVelocity, vVelocity);
			ScaleVector(vVelocity, Rain_Speed[iClient]);
			TeleportEntity(iRocket, vOrigin, vAngles, vVelocity);
			DispatchKeyValue(iRocket, "target", "ff2_necrozma");
			DispatchSpawn(iRocket);
			if(iRandom == 1)
			{
				SetEntProp(iRocket, Prop_Send, "m_iTeamNum", 3);
			}
			if(iRandom == 2)
			{
				SetEntProp(iRocket, Prop_Send, "m_iTeamNum", 2);
			}
			Rain_Shots[iClient]++;
		}
		if(Rain_Delay[iClient]>0.0)
		{
			flShootAt = Rain_Delay[iClient]+GetEngineTime();
		}
	}
}

bool IsValidClient(int iClient, bool bAlive=false, bool bTeam=false)
{
	if (iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
	{
		return false;
	}
	if (IsClientSourceTV(iClient) || IsClientReplay(iClient))
	{
		return false;
	}
	if (bAlive && !IsPlayerAlive(iClient))
	{
		return false;
	}
	if (bTeam && BossTeam != GetClientTeam(iClient))
	{
		return false;
	}
	return true;
}

public bool FF2_GetAbilityArgumentBool(int iBoss, char[] pluginName, char[] abilityName, int iArg)
{
	return FF2_GetAbilityArgument(iBoss, pluginName, abilityName, iArg, 1) == 1;
}


