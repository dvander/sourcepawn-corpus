#pragma semicolon 1

#define PLUGIN_VERSION "1.1.0"


public Plugin:myinfo = 
{
	
	name = "Set Cash",
	
	author = "Tylerst",

	description = "Set target(s) cash for Mann vs Machine mode",

	version = PLUGIN_VERSION,
	
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if(GetEngineVersion() != Engine_TF2)
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("sm_setcash_version", PLUGIN_VERSION, "SetCash", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_setcash", Command_SetCash, ADMFLAG_GENERIC, "Set target(s) cash for Mann vs Machine mode, Usage: sm_setcash \"target\" \"amount\"");
	RegAdminCmd("sm_addcash", Command_AddCash, ADMFLAG_GENERIC, "Add to target(s) cash for Mann vs Machine mode, Usage: sm_setcash \"target\" \"amount\"");
	RegAdminCmd("sm_removecash", Command_RemoveCash, ADMFLAG_GENERIC, "Add to target(s) cash for Mann vs Machine mode, Usage: sm_setcash \"target\" \"amount\"");

	HookEvent("player_spawn", Event_PlayerSpawn);
}


public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, Timer_CheckCash, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_CheckCash(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(GetCash(client) < 0) SetCash(client, 0);
}

public Action:Command_SetCash(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setcash \"target\" \"amount\"");
		return Plugin_Handled;
	}

	new String:strTarget[MAX_TARGET_LENGTH], String:strCash[32], iCash, String:target_name[MAX_TARGET_LENGTH],target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, strCash, sizeof(strCash));
	iCash = StringToInt(strCash);

	for(new i = 0; i < target_count; i++)
	{
		SetCash(target_list[i], iCash);
	}
	return Plugin_Handled;
}

public Action:Command_AddCash(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addcash \"target\" \"amount\"");
		return Plugin_Handled;
	}

	new String:strTarget[MAX_TARGET_LENGTH], String:strCash[32], iCash, String:target_name[MAX_TARGET_LENGTH],target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, strCash, sizeof(strCash));
	iCash = StringToInt(strCash);

	for(new i = 0; i < target_count; i++)
	{
		SetCash(target_list[i], GetCash(target_list[i])+iCash);
	}
	return Plugin_Handled;
}

public Action:Command_RemoveCash(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_removecash \"target\" \"amount\"");
		return Plugin_Handled;
	}

	new String:strTarget[MAX_TARGET_LENGTH], String:strCash[32], iCash, String:target_name[MAX_TARGET_LENGTH],target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, strCash, sizeof(strCash));
	iCash = StringToInt(strCash);

	for(new i = 0; i < target_count; i++)
	{
		SetCash(target_list[i], GetCash(target_list[i])-iCash);
	}
	return Plugin_Handled;
}


stock SetCash(client, iAmount)
{
	if(iAmount < 0) iAmount = 0;
	SetEntProp(client, Prop_Send, "m_nCurrency", iAmount);
}

stock GetCash(client)
{
	return GetEntProp(client, Prop_Send, "m_nCurrency");
}