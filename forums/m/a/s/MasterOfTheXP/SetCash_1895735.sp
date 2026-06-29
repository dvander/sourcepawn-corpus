#pragma semicolon 1

#define PLUGIN_VERSION "1.0.3"


public Plugin:myinfo = 
{
	
	name = "Set Cash",
	
	author = "Tylerst",

	description = "Set target(s) cash for Mann vs Machine mode",

	version = PLUGIN_VERSION,
	
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
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
	RegAdminCmd("sm_setcash", Command_SetCash, ADMFLAG_GENERIC, "Set target(s) cash for Mann vs Machine mode, Usage: sm_setcash \"target\" \"amount(0-32767)\"");
	RegAdminCmd("sm_addcash", Command_AddCash, ADMFLAG_GENERIC, "Add to target(s) cash for Mann vs Machine mode, Usage: sm_setcash \"target\" \"amount(0-32767)\"");
	RegAdminCmd("sm_removecash", Command_RemoveCash, ADMFLAG_GENERIC, "Add to target(s) cash for Mann vs Machine mode, Usage: sm_setcash \"target\" \"amount(0-32767)\"");
}

public Action:Command_SetCash(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setcash \"target\" \"amount(0-32767)\"");
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
	if(iCash < 0) iCash = 0;
	if(iCash > 32767) iCash = 32767;

	for(new i = 0; i < target_count; i++)
	{
		SetEntProp(target_list[i], Prop_Send, "m_nCurrency", iCash);
	}
	return Plugin_Handled;
}

public Action:Command_AddCash(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addcash \"target\" \"amount(0-32767)\"");
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
	if(iCash < 0) iCash = 0;
	if(iCash > 32767) iCash = 32767;

	for(new i = 0; i < target_count; i++)
	{
		new iCurrentCash = GetEntProp(target_list[i], Prop_Send, "m_nCurrency");
		new iNewCash = iCurrentCash+iCash;
		if(iNewCash < 0) iNewCash = 0;
		if(iNewCash > 32767) iNewCash = 32767;	
		SetEntProp(target_list[i], Prop_Send, "m_nCurrency", iNewCash);
	}
	return Plugin_Handled;
}

public Action:Command_RemoveCash(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_removecash \"target\" \"amount(0-32767)\"");
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
	if(iCash < 0) iCash = 0;
	if(iCash > 32767) iCash = 32767;

	for(new i = 0; i < target_count; i++)
	{
		new iCurrentCash = GetEntProp(target_list[i], Prop_Send, "m_nCurrency");
		new iNewCash = iCurrentCash-iCash;
		if(iNewCash < 0) iNewCash = 0;
		if(iNewCash > 32767) iNewCash = 32767;	
		SetEntProp(target_list[i], Prop_Send, "m_nCurrency", iNewCash);
	}
	return Plugin_Handled;
}