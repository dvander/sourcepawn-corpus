#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

public Plugin:myinfo = {
	name = "Freak Fortress 2: Rage Model",
	author = "frog",
	version = "1.1"
};

new g_BossHealth;
new g_BossMaxHealth;
new g_BossLife;

new String:g_HealthModel1[PLATFORM_MAX_PATH];
new String:g_HealthModel2[PLATFORM_MAX_PATH];
new String:g_HealthModel3[PLATFORM_MAX_PATH];
new String:g_HealthModel4[PLATFORM_MAX_PATH];
new String:g_HealthModel5[PLATFORM_MAX_PATH];

new String:g_RageModel[PLATFORM_MAX_PATH];
new String:g_NormalModel[PLATFORM_MAX_PATH];
new String:g_ChangedModel[PLATFORM_MAX_PATH];

new String:g_LifeModel[10][PLATFORM_MAX_PATH];

new bool:g_ModelChanged;

new g_BossThreshold1 = -1;
new g_BossThreshold2 = -1;
new g_BossThreshold3 = -1;
new g_BossThreshold4 = -1;
new g_BossThreshold5 = -1;

new Handle:g_HealthModelTimer;


public OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	CreateTimer(1.0, BossHealthCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}


public Action:FF2_OnAbility2(index, const String:plugin_name[], const String:ability_name[], action)
{
	if (!strcmp(ability_name,"rage_model"))
		Rage_Model(ability_name, index);	//change model on rage
	else if (!strcmp(ability_name,"life_model"))
		Life_Model(index);	//change model on life lost
	return Plugin_Continue;
}


Rage_Model(const String:ability_name[], index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new duration=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 1);	//duration
	FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 2, g_RageModel, PLATFORM_MAX_PATH);	//rage model
	FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 3, g_NormalModel, PLATFORM_MAX_PATH);	//normal model

	ChangeBossModel(g_RageModel, Boss);
	
	CreateTimer(float(duration), RestoreModel, Boss);
}


Life_Model(index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	if (g_LifeModel[g_BossLife][0])
	{
		ChangeBossModel(g_LifeModel[g_BossLife], Boss);
		g_ChangedModel = g_LifeModel[g_BossLife];
		g_ModelChanged = true;
	}
	g_BossLife++;
}


public ChangeBossModel(const String:model[], any:client)
{
	SetVariantString(model);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
}


public Action:RestoreModel(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client) && FF2_GetBossIndex(client) != -1)
	{
		if (g_ModelChanged)
		{
			ChangeBossModel(g_ChangedModel, client);
		}
		else
		{
			ChangeBossModel(g_NormalModel, client);        
		}
	}
}


public Action:BossHealthCheck(Handle:timer)
{
	new damage = 0;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			damage += FF2_GetClientDamage(i);
		}
	}
	g_BossHealth = g_BossMaxHealth - damage;
	return Plugin_Continue;
}


public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_BossHealth = 0;
	g_BossLife = 0;
	g_BossMaxHealth = FF2_GetBossMaxHealth(0);
	g_ModelChanged = false;
	
	if (FF2_IsFF2Enabled())
	{
		new Boss = GetClientOfUserId(FF2_GetBossUserId(0));
		if (Boss>0)
		{
			if (FF2_HasAbility(0, this_plugin_name, "health_model"))
			{
				g_BossThreshold1 = FF2_GetAbilityArgument(0, this_plugin_name, "health_model", 1);
				FF2_GetAbilityArgumentString(0, this_plugin_name, "health_model", 2, g_HealthModel1, PLATFORM_MAX_PATH);
				g_BossThreshold2 = FF2_GetAbilityArgument(0, this_plugin_name, "health_model", 3);
				FF2_GetAbilityArgumentString(0, this_plugin_name, "health_model", 4, g_HealthModel2, PLATFORM_MAX_PATH);
				g_BossThreshold3 = FF2_GetAbilityArgument(0, this_plugin_name, "health_model", 5);
				FF2_GetAbilityArgumentString(0, this_plugin_name, "health_model", 6, g_HealthModel3, PLATFORM_MAX_PATH);
				g_BossThreshold4 = FF2_GetAbilityArgument(0, this_plugin_name, "health_model", 7);
				FF2_GetAbilityArgumentString(0, this_plugin_name, "health_model", 8, g_HealthModel4, PLATFORM_MAX_PATH);
				g_BossThreshold5 = FF2_GetAbilityArgument(0, this_plugin_name, "health_model", 9);
				FF2_GetAbilityArgumentString(0, this_plugin_name, "health_model", 10, g_HealthModel5, PLATFORM_MAX_PATH);

				g_HealthModelTimer = CreateTimer(1.0, SetBossModel, Boss, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
			if (FF2_HasAbility(0, this_plugin_name, "life_model"))
			{
				FF2_GetAbilityArgumentString(0, this_plugin_name, "life_model", 1, g_LifeModel[0], PLATFORM_MAX_PATH);
				FF2_GetAbilityArgumentString(0, this_plugin_name, "life_model", 2, g_LifeModel[1], PLATFORM_MAX_PATH);
				FF2_GetAbilityArgumentString(0, this_plugin_name, "life_model", 3, g_LifeModel[2], PLATFORM_MAX_PATH);    
				FF2_GetAbilityArgumentString(0, this_plugin_name, "life_model", 4, g_LifeModel[3], PLATFORM_MAX_PATH);
				FF2_GetAbilityArgumentString(0, this_plugin_name, "life_model", 6, g_LifeModel[5], PLATFORM_MAX_PATH);
				FF2_GetAbilityArgumentString(0, this_plugin_name, "life_model", 7, g_LifeModel[6], PLATFORM_MAX_PATH);
				FF2_GetAbilityArgumentString(0, this_plugin_name, "life_model", 8, g_LifeModel[7], PLATFORM_MAX_PATH);
				FF2_GetAbilityArgumentString(0, this_plugin_name, "life_model", 9, g_LifeModel[8], PLATFORM_MAX_PATH);
				FF2_GetAbilityArgumentString(0, this_plugin_name, "life_model", 10, g_LifeModel[9], PLATFORM_MAX_PATH);
			}
		}
	}
}


public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_HealthModelTimer != INVALID_HANDLE)
	{
		KillTimer(g_HealthModelTimer);
		g_HealthModelTimer = INVALID_HANDLE;
	}
}

 
public Action:SetBossModel(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (g_BossThreshold5 && float(g_BossHealth) < float(g_BossMaxHealth)*(float(g_BossThreshold5)/100))
		{
			ChangeBossModel(g_HealthModel5, client);
			g_ChangedModel = g_HealthModel5;
			g_BossThreshold5 = 0;
			g_ModelChanged = true;
		}
		else if (g_BossThreshold4 && g_BossHealth < float(g_BossMaxHealth)*(float(g_BossThreshold4)/100))
		{
			ChangeBossModel(g_HealthModel4, client);
			g_ChangedModel = g_HealthModel4;
			g_BossThreshold4 = 0;
			g_ModelChanged = true;
		}
		else if (g_BossThreshold3 && g_BossHealth < float(g_BossMaxHealth)*(float(g_BossThreshold3)/100))
		{
			ChangeBossModel(g_HealthModel3, client);
			g_ChangedModel = g_HealthModel3;
			g_BossThreshold3 = 0;
			g_ModelChanged = true;
		}
		else if (g_BossThreshold2 && g_BossHealth < float(g_BossMaxHealth)*(float(g_BossThreshold2)/100))
		{
			ChangeBossModel(g_HealthModel2, client);
			g_ChangedModel = g_HealthModel2;
			g_BossThreshold2 = 0;
			g_ModelChanged = true;
		}
		else if (g_BossThreshold1 && g_BossHealth < float(g_BossMaxHealth)*(float(g_BossThreshold1)/100))
		{
			ChangeBossModel(g_HealthModel1, client);
			g_ChangedModel = g_HealthModel1;
			g_BossThreshold1 = 0;
			g_ModelChanged = true;
		}
	}
}
