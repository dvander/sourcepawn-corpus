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
 *	Defines "rage_projectile_X"
 */
bool 	AMS_PRJ[10][MAXPLAYERS+1];				//Internal 	- AMS Trigger
char 	PRJ_EntityName[10][768];				//arg1		- Projectile Name
float 	PRJ_Velocity[10][MAXPLAYERS+1];			//arg2		- Projectile Velocity

float 	PRJ_MinDamage[10][MAXPLAYERS+1],		//arg3		- Minimum Damage
		PRJ_MaxDamage[10][MAXPLAYERS+1];		//arg4		- Maximum Damage
		
int		PRJ_Crit[10][MAXPLAYERS+1];				//arg4		- Critz: -1=Use Defaults, 1=Crit, 0=No Random Crits

public Plugin myinfo = 
{
	name = "Freak Fortress 2: Cast Projectile",
	author = "J0BL3SS",
	version = "1.1.0",
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

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ClearAMSTriggers();
}

public void ClearAMSTriggers()
{	
	for(int Num = 0; Num < 10; Num++)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			AMS_PRJ[Num][i] = false;
		}
	}

}

public void HookAbilities(int bossIdx, int bossClientIdx)
{
	if(bossIdx >= 0)
	{
		char AbilityName[96], AbilityShort[96];
		for(int Num = 0; Num < 10; Num++)
		{
			Format(AbilityName, sizeof(AbilityName), "rage_projectile_%i", Num);
			if(FF2_HasAbility(bossIdx, this_plugin_name, AbilityName))
			{
				AMS_PRJ[Num][bossClientIdx] = AMS_IsSubabilityReady(bossIdx, this_plugin_name, AbilityName);
				if(AMS_PRJ[Num][bossClientIdx])
				{
					Format(AbilityShort, sizeof(AbilityShort), "PRJ%i", Num);
					AMS_InitSubability(bossIdx, bossClientIdx, this_plugin_name, AbilityName, AbilityShort);
				}
			}
		}
	}
}

public Action FF2_OnAbility2(int bossIdx, const char[] plugin_name, const char[] ability_name, int status)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		return Plugin_Continue; // Because some FF2 forks still allow RAGE to be activated when the round is over....
	
	int bossClientIdx = GetClientOfUserId(FF2_GetBossUserId(bossIdx));

	//Rage Gravity
	char AbilityName[96];
	for(int Num = 0; Num < 10; Num++)
	{
		Format(AbilityName, sizeof(AbilityName), "rage_projectile_%i", Num);
		if(!strcmp(ability_name, AbilityName))
		{
			if(AMS_PRJ[Num][bossClientIdx])
			{
				if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability"))
				{
					AMS_PRJ[Num][bossClientIdx] = false;
				}
				else
				{
					return Plugin_Continue;
				}
			}
			if(!AMS_PRJ[Num][bossClientIdx])
			{
				CastSpell(bossIdx, bossClientIdx, ability_name, Num);
			}
		}
	}
	return Plugin_Continue;
}


public bool PRJ0_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool PRJ1_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool PRJ2_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool PRJ3_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool PRJ4_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool PRJ5_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool PRJ6_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool PRJ7_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool PRJ8_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool PRJ9_CanInvoke(int bossClientIdx)
{
	return true;
}

public void PRJ0_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_0", 0);
}

public void PRJ1_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_1", 1);
}

public void PRJ2_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_2", 2);
}

public void PRJ3_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_3", 3);
}

public void PRJ4_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_4", 4);
}

public void PRJ5_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_5", 5);
}

public void PRJ6_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_6", 6);
}

public void PRJ7_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_7", 7);
}

public void PRJ8_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_8", 8);
}

public void PRJ9_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_9", 9);
}

public void CastSpell(int bossIdx, int bossClientIdx, const char[] ability_name, int Num)
{
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, 1, PRJ_EntityName[Num], 768);
	PRJ_Velocity[Num][bossClientIdx] 	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 2, 1100.0);
	
	PRJ_MinDamage[Num][bossClientIdx] 	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 3, 33.0);
	PRJ_MaxDamage[Num][bossClientIdx] 	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 4, 35.0);
	PRJ_Crit[Num][bossClientIdx] 		= FF2_GetAbilityArgument(bossIdx, this_plugin_name, ability_name, 5, -1);
	
	if(AMS_PRJ[Num][bossClientIdx])
	{
		char AbilitySound[128], sound[PLATFORM_MAX_PATH];
		Format(AbilitySound, sizeof(AbilitySound), "sound_projectile_%i", Num);
		if(FF2_RandomSound(AbilitySound, sound, sizeof(sound), bossIdx))
		{
			EmitSoundToAll(sound, bossClientIdx);
			EmitSoundToAll(sound, bossClientIdx);	
		}
	}
	
	float flAng[3], flPos[3];
	GetClientEyeAngles(bossClientIdx, flAng);
	GetClientEyePosition(bossClientIdx, flPos);
	
	int iTeam = GetClientTeam(bossClientIdx);
	int iProjectile = CreateEntityByName(PRJ_EntityName[Num]);
	
	float flVel1[3], flVel2[3];
	GetAngleVectors(flAng, flVel2, NULL_VECTOR, NULL_VECTOR);
	
	flVel1[0] = flVel2[0] * PRJ_Velocity[Num][bossClientIdx];
	flVel1[1] = flVel2[1] * PRJ_Velocity[Num][bossClientIdx];
	flVel1[2] = flVel2[2] * PRJ_Velocity[Num][bossClientIdx];
	
	SetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity", bossClientIdx);
	if(!IsProjectileTypeSpell(PRJ_EntityName[Num]))
	{
		SetEntDataFloat(iProjectile, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4,
		GetRandomFloat(PRJ_MinDamage[Num][bossClientIdx], PRJ_MaxDamage[Num][bossClientIdx]), true);
		
		int CritValue;
		
		if(PRJ_Crit[Num][bossClientIdx] == 1) CritValue = 1;
		else if(PRJ_Crit[Num][bossClientIdx] == 0) CritValue = 0;
		else CritValue = (GetRandomInt(0, 100) <= 3 ? 1 : 0);
			
		SetEntProp(iProjectile, Prop_Send, "m_bCritical", CritValue, 1);
	}
	SetEntProp(iProjectile, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iProjectile, Prop_Send, "m_nSkin", (iTeam-2));
	
	TeleportEntity(iProjectile, flPos, flAng, NULL_VECTOR);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(iProjectile, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iProjectile, "SetTeam", -1, -1, 0);
	
	DispatchSpawn(iProjectile);
	TeleportEntity(iProjectile, NULL_VECTOR, NULL_VECTOR, flVel1);
}

stock bool IsValidClient(int client)
{
	if(client <= 0 || client > MaxClients) return false;
	if(!IsClientInGame(client) || !IsClientConnected(client)) return false;
	if(IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;		
}

stock bool IsProjectileTypeSpell(const char[] entity_name)
{
	if(StrContains(entity_name, "tf_projectile_spell", false) != -1 || !strcmp(entity_name, "tf_projectile_lightningorb")) return true;
	else return false;
}
