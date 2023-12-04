#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "TSG"
#define PLUGIN_VERSION "1.1.1"

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
//#include <sdkhooks>

public Plugin myinfo = 
{
	name = "SimpleConditions",
	author = PLUGIN_AUTHOR,
	description = "N/A",
	version = PLUGIN_VERSION,
	url = "N/A"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_addcond", Command_CondAdd, ADMFLAG_BAN, "sm_addcond <target> <condition>"); //sm_addcond <name|#userid> <condition>
	RegAdminCmd("sm_removecond", Command_CondRemove, ADMFLAG_BAN, "sm_removecond <target> <condition>"); //sm_removecond <name|#userid> <condition>
	CreateConVar("sm_sc_ver", PLUGIN_VERSION, "SimpleConditions Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	PrintToServer("[SimpleConditions] Loaded Successfully!");
}

public Action Command_CondAdd(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addcond <target> <condition>");
		return Plugin_Handled;
	}
	
	char arg1[32], arg2[32];
	
	//Set the condition to 0 by default
	int condition = 0;
	
	//Get the arguments
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	condition = StringToInt(arg2);
	
	/**
	* target_name - stores the noun identifying the target(s)
	* target_list - array to store clients
	* target_count - variable to store number of clients
	* tn_is_ml - stores whether the noun must be translated
	*/
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE, /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		TF2_AddCondition(target_list[i], condition);	
	}
	
	if (tn_is_ml)
	{
		ReplyToCommand(client, "[SM] Applied condition!");
	}
	else
	{
		ReplyToCommand(client, "[SM] Applied condition!");
	}
 
	return Plugin_Handled;
}

public Action Command_CondRemove(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_removecond <target> <condition>");
		return Plugin_Handled;
	}
	
	char arg1[32], arg2[32];
	
	//Set the condition to 0 by default
	int condition = 0;
	
	//Get the arguments
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	condition = StringToInt(arg2);
	
	/**
	* target_name - stores the noun identifying the target(s)
	* target_list - array to store clients
	* target_count - variable to store number of clients
	* tn_is_ml - stores whether the noun must be translated
	*/
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE, /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		TF2_RemoveCondition(target_list[i], condition);	
	}
	
	if (tn_is_ml)
	{
		ReplyToCommand(client, "[SM] Removed condition!");
	}
	else
	{
		ReplyToCommand(client, "[SM] Removed condition!");
	}
 
	return Plugin_Handled;
}