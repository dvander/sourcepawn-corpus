#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks> 
#pragma semicolon 1

new bool:backstab[MAXPLAYERS+1];

public OnPluginStart()
{
	RegConsoleCmd("sm_nobackstab", CMD_BackStab);
}

public OnClientPutInServer(client) 
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); 
}

public Action:CMD_BackStab(client, args)
{
	new String:target[PLATFORM_MAX_PATH];
	new String:enable[PLATFORM_MAX_PATH];
	GetCmdArg(1, target, PLATFORM_MAX_PATH);
	GetCmdArg(2, enable, PLATFORM_MAX_PATH);
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS];
	new target_count;
	new bool:tn_is_ml;
	if((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for(new i = 0; i < target_count; i++)
	{
		switch(StringToInt(enbale, 10))
		{
			case 0:
			{
				backstab[i] = true;
				ReplyToCommand(client, "Enabled Backstab Damage on : %s", target);
			}
			case 1:
			{
				backstab[i] = false;
				ReplyToCommand(client, "Disabled Backstab Damage on : %s", target);
			}
		}
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom) 
{ 
	if(victim > 0 && victim <= MaxClients && backstab[victim] == false && damagecustom == TF_CUSTOM_BACKSTAB)
	{
		return Plugin_Handled; 
	}
	return Plugin_Continue; 
}  