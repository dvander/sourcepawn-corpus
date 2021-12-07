#pragma semicolon 1
#include <sourcemod>
#include <tf2attributes>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[TF2] Sentry Fire Rate",
	author = "Pelipoika - edited by Arkarr",
	description = "Modify sentry fire rate NOTE: This plugin wasn't do by me. Pelipoika did it, I just edited what he have done to fit to this request : https://forums.alliedmods.net/showthread.php?t=236824",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	CreateConVar("sm_tf2_sfr_version", PLUGIN_VERSION, "TF2 Sentry Fire Rate version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_sfr", Command_RR, ADMFLAG_ROOT, "Set Sentry Fire Rate");
}

public Action:Command_RR(client, args)
{
	decl String:arg1[32];
	decl String:arg2[32];
	new Float:amount;
	
	GetCmdArg(2, arg2, sizeof(arg2));
	amount = StringToFloat(arg2);
	
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		ModSentryFireRate(target_list[i], amount);
	}
	return Plugin_Handled;
}

stock ModSentryFireRate(client, Float:amount)
{
	if(IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		new slot2 = GetPlayerWeaponSlot(client, 2);
		TF2Attrib_SetByName(slot2, "engy sentry fire rate increased", amount);
	}
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}