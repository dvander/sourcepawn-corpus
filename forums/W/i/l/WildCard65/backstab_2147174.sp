#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks> 
#pragma semicolon 1

new bool:backstab[MAXPLAYERS+1];

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	RegConsoleCmd("sm_nobackstab", CMD_BackStab);
	AddCommandOverride("sm_nobackstab_target", Override_Command, ADMFLAG_GENERIC);
}

public OnClientPutInServer(client) 
{
	backstab[client] = false;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); 
}

public Action:CMD_BackStab(client, args)
{
	if (args < 1 && CheckCommandAccess(client, "sm_nobackstab_target", ADMFLAG_GENERIC) && (args < 1 || args > 1))
	{
		ReplyToCommand(client, "Usage: sm_nobackstab [#userid or name] <0 or 1> //1 to allow target to be backstabbed, 0 to not allow target to be backstabbed, pass only client to toggle.");
		return Plugin_Handled;
	}
	if (!CheckCommandAccess(client, "sm_nobackstab_target", ADMFLAG_GENERIC))
	{
		new String:enable[2];
		if (args == 1)
		{
			GetCmdArg(1, enable, sizeof(enable));
			backstab[client] = bool:StringToInt(enable);
		}
		else
			backstab[client] = !backstab[client];
		ReplyToCommand(client, "Your backstab status is now: %s", backstab[client] ? "Enabled" : "Disabled");
	}
	else
	{
		new String:target[MAX_NAME_LENGTH];
		GetCmdArg(1, target, MAX_NAME_LENGTH);
		new bool:toggle = true;
		new bool:tempNess;
		if (args == 2)
		{
			new String:enable[2];
			GetCmdArg(2, enable, sizeof(enable));
			tempNess = bool:StringToInt(enable);
			toggle = false;
		}
		new String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS];
		new target_count;
		new bool:tn_is_ml;
		if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, 0, target_name, MAX_TARGET_LENGTH, tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		new String:output[(strlen("You have disabled backstab damage on ") + MAX_NAME_LENGTH + 2)*target_count];
		if (tn_is_ml && toggle)
			Format(output, (strlen("You have disabled backstab damage on ") + MAX_NAME_LENGTH + 2)*target_count, "You have toggled backstab damage on %T", target_name);
		else if(tn_is_ml && !toggle)
			Format(output, (strlen("You have disabled backstab damage on ") + MAX_NAME_LENGTH + 2)*target_count, "You have %s backstab damage on %T", tempNess ? "enabled" : "disabled", target_name);
		else if(target_count == 1 && toggle)
			Format(output, (strlen("You have disabled backstab damage on ") + MAX_NAME_LENGTH + 2)*target_count, "You have toggled backstab damage on %N", target_list[0]);
		else if(target_count == 1 && !toggle)
			Format(output, (strlen("You have disabled backstab damage on ") + MAX_NAME_LENGTH + 2)*target_count, "You have %s backstab damage on %N", tempNess ? "enabled" : "disabled", target_list[0]);
		for (new i = 0; i < target_count; i++)
		{
			if (toggle)
			{
				backstab[target_list[i]] = !backstab[target_list[i]];
			}
			else
			{
				backstab[target_list[i]] = tempNess;
			}
		}
		ReplyToCommand(client, output);
	}
	return Plugin_Handled;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom) 
{ 
	if(!backstab[victim] && damagecustom == TF_CUSTOM_BACKSTAB)
	{
		return Plugin_Handled; 
	}
	return Plugin_Continue; 
}  