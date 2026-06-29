#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#pragma newdecls required

Handle OnHaleRage = INVALID_HANDLE;
int BossTeam = view_as<int>(TFTeam_Blue);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	OnHaleRage=CreateGlobalForward("VSH_OnDoRage", ET_Hook, Param_FloatByRef);
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "Freak Fortress 2: SCP-173 Special Abilities",
	description = "Decompiled and Rewroten version",
	author = "OriginalNero, Rewrite by Batfoxkid, Decompiled by Maximilian_",
	version = "1.1"
};

public void OnPluginStart2()
{
	HookEvent("arena_round_start", OnRoundStart);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Pre);
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(!FF2_IsFF2Enabled())
		return Plugin_Continue;

	CreateTimer(0.5, Timer_GetBossTeam, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Timer_GetBossTeam(Handle timer)
{
	BossTeam = FF2_GetBossTeam();
	return Plugin_Continue;
}

public Action OnRoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			int boss = FF2_GetBossIndex(client);
			if(boss >= 0)
			{
				if(FF2_HasAbility(boss, this_plugin_name, "ff2_scp"))
				{
					TF2_RemoveCondition(client, TFCond_HalloweenKartNoTurn);
					TurnOnLights();
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
	int client = GetClientOfUserId(FF2_GetBossUserId(boss));
	int slot = FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 0);
	if(!slot)
	{
		if(!boss)
		{
			Action action=Plugin_Continue;
			Call_StartForward(OnHaleRage);
			float distance=FF2_GetRageDist(boss, this_plugin_name, ability_name);
			float newDistance=distance;
			Call_PushFloatRef(newDistance);
			Call_Finish(action);
			if(action!=Plugin_Continue && action!=Plugin_Changed)
			{
				return Plugin_Continue;
			}
			else if(action==Plugin_Changed)
			{
				distance=newDistance;
			}
		}
	}

	if(!strcmp(ability_name, "ff2_scp"))
	{
		TF2_AddCondition(client, TFCond_TeleportedGlow, FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 1, 5.0));
		CreateTimer(0.1, EatRage, boss, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action EatRage(Handle timer, any boss)
{
	FF2_SetBossCharge(boss, 0, 0.0);
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState()!=1 || !IsClientInGame(client))
		return;

	if(condition==TFCond_TeleportedGlow)
	{
		int boss = FF2_GetBossIndex(client);
		if(boss >= 0)
		{
			if(FF2_HasAbility(boss, this_plugin_name, "ff2_scp"))
			{
				TF2_RemoveCondition(client, TFCond_HalloweenKartNoTurn);
			}
		}
	}
	else if(condition==TFCond_HalloweenKartNoTurn)
	{
		int boss = FF2_GetBossIndex(client);
		if(boss >= 0)
		{
			if(FF2_HasAbility(boss, this_plugin_name, "ff2_scp"))
			{
				TurnOnLights();
			}
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState()!=1 || !IsClientInGame(client))
		return;

	if(condition==TFCond_TeleportedGlow)
	{
		int boss = FF2_GetBossIndex(client);
		if(boss >= 0)
		{
			if(FF2_HasAbility(boss, this_plugin_name, "ff2_scp"))
			{
				TF2_AddCondition(client, TFCond_HalloweenKartNoTurn, -1.0);
			}
		}
	}
	else if(condition==TFCond_HalloweenKartNoTurn)
	{
		int boss = FF2_GetBossIndex(client);
		if(boss >= 0)
		{
			if(FF2_HasAbility(boss, this_plugin_name, "ff2_scp"))
			{
				TurnOffLights();
			}
		}
	}
}

void TurnOnLights()
{
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & -FCVAR_CHEAT);
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target))
		{
			if(view_as<int>(GetClientTeam(target))!=BossTeam && IsPlayerAlive(target))
			{
				ClientCommand(target, "r_screenoverlay \"\"");
			}
		}
	}
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
}

void TurnOffLights()
{
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & -FCVAR_CHEAT);
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target))
		{
			if(view_as<int>(GetClientTeam(target))!=BossTeam && IsPlayerAlive(target))
			{
				ClientCommand(target, "r_screenoverlay \"%s\"", "effects/tp_eyefx/tp_black");
			}
		}
	}
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
}