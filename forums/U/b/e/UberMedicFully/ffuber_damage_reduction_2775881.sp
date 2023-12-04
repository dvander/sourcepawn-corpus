#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

float damage_reduct;
float duration;

public OnPluginStart2()
{
	HookEvent("arena_round_start", OnRoundStart);
	HookEvent("arena_win_panel", OnRoundEnd);
}

public void FF2_OnAbility2(int boss, const char[] pluginName, const char[] ability_name, int iStatus) 
{
	int client = GetClientOfUserId(FF2_GetBossUserId(boss));
	
	if(!strcmp(ability_name, "special_resistance"))	
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		CreateTimer(duration, endrage, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 1; client <=MaxClients; client++)
	{		
		if (IsValidClient(client))
		{
			int boss = FF2_GetBossIndex(client);
			
			if (boss>=0)
			{
				if (FF2_HasAbility(boss, this_plugin_name, "special_resistance"))
				{
					damage_reduct = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "special_resistance", 1);
					duration = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "special_resistance", 2);
				}
			}
		}
	}
}

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action endrage(Handle timer, int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{	
	int boss = FF2_GetBossIndex(client);
	if (FF2_HasAbility(boss, this_plugin_name, "special_resistance"))
	{
		damage = damage - (damage * damage_reduct);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

//Dunno from where i got this honestly
stock bool IsValidClient(int client, bool replaycheck = true)
{
    if ( client <= 0 || client > MaxClients ) return false; 
    if ( !IsClientInGame( client ) ) return false; 
    if ( !IsPlayerAlive( client ) ) return false; 
    return true; 
}