#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.1"
  
public Plugin:myinfo =
{
	name = "TF2 Add Condition",
	author = "Tylerst",
	description = "Add a condition on a target(s) for a specified time",
	version = PLUGIN_VERSION,
}

public OnPluginStart()
{
	LoadTranslations("common.phrases")
	RegAdminCmd("sm_addcond", Command_Addcond, ADMFLAG_SLAY)
}
 
public Action:Command_Addcond(client, args)
{
	new String:arg1[32], String:arg2[5], String:arg3[32];
	new cond;
	new Float:dur;
 
	GetCmdArg(1, arg1, sizeof(arg1))
	GetCmdArg(2, arg2, sizeof(arg2))
	GetCmdArg(3, arg3, sizeof(arg3))


	if (args == 3)
	{
		cond = StringToInt(arg2); 
		dur = StringToFloat(arg3);
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_addcond <target> <condition number> <duration>");
		return Plugin_Handled;
	}

	if(cond < 0 || cond >27)
	{
		ReplyToCommand(client, "Condition number must be from 0 to 27");
	}

	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count
	new bool:tn_is_ml
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		if (cond == 1 && TF2_GetPlayerClass(target_list[i]) != TFClass_Sniper)
		{
			return Plugin_Handled
		}
		if (cond == 4 && TF2_GetPlayerClass(target_list[i]) != TFClass_Spy)
		{
			return Plugin_Handled
		}
		if (cond == 7)
		{
			FakeClientCommand(target_list[i], "taunt");
			return Plugin_Handled;
		}
		if (cond == 22)
		{
			TF2_IgnitePlayer(target_list[i], target_list[i]);
			return Plugin_Handled;
		}
		if (cond == 25)
		{
			TF2_MakeBleed(client, target_list[i], dur);
			return Plugin_Handled;
		}
		else
		{		
			TF2_AddCondition(target_list[i], TFCond:cond, dur);
		}
	}
 
	return Plugin_Handled;
}
//Slowed = 0
//Zoomed = 1 - Only works on Snipers
//Disguising = 2
//Disguised = 3
//Cloaked = 4 - Only works on Spies
//Ubercharged = 5
//Teleportglow = 6
//Taunting = 7
//Uberchargefade = 8
//Unknown1 = 9
//Teleporting = 10
//Kritzkrieged = 11
//Deadringered = 13
//Bonked = 14
//Dazed = 15
//Buffed = 16
//Charging = 17
//Demobuff = 18
//Critcola = 19
//Healing = 20
//Unknown3 = 21
//OnFire = 22
//Overhealed = 23
//Jarated= 24
//Bleeding = 25
//Defensebuffed = 26
//Milked = 27