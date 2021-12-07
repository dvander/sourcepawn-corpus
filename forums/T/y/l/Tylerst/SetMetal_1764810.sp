#pragma semicolon 1

#define PLUGIN_VERSION "1.0.1"


public Plugin:myinfo = 
{
	
	name = "Set Metal",
	
	author = "Tylerst",

	description = "Set metal on target(s)",

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

new Handle:g_hChat = INVALID_HANDLE;
new Handle:g_hLog = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("sm_smetal_version", PLUGIN_VERSION, "Set Metal", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hChat = CreateConVar("sm_smetal_chat", "1", "Show Set Metal changes in chat");
	g_hLog = CreateConVar("sm_smetal_log", "1", "Log Set Metal commands");
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_setmetal", Command_SetMetal, ADMFLAG_SLAY, "Set metal on target(s), [SM] Usage: sm_setmetal \"target\" \"metal(0-1023)\"");	
}

public Action:Command_SetMetal(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setmetal \"target\" \"metal(0-1023)\"");
		return Plugin_Handled;
	}

	new String:target[MAX_TARGET_LENGTH],String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, target, sizeof(target));		
	if((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	new String:strmetal[32], metal;
	GetCmdArg(2, strmetal, sizeof(strmetal));
	metal = StringToInt(strmetal);
	if(metal < 0) metal = 0;
	if(metal > 1023) metal = 1023;

	new bool:bLog = GetConVarBool(g_hLog);
	for(new i = 0; i < target_count; i++)
	{
		SetEntProp(target_list[i], Prop_Data, "m_iAmmo", metal, 4, 3);
		if(bLog) LogAction(client, target_list[i], "\"%L\" Set Metal for \"%L\" to %i", client, target_list[i], metal);
	}
	if(GetConVarBool(g_hChat)) ShowActivity2(client, "[SM] ","Set Metal for %s to %i", target_name, metal);

	return Plugin_Handled;
	
}