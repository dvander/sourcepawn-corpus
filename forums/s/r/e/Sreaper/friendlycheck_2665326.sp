#include <friendly>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "Friendly Check", 
	author = "Sreap (special thanks to 404UNF & 11530)", 
	description = "Check if a target is Friendly", 
	version = PLUGIN_VERSION, 
	url = ""
};


public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_friendly_check", UseFriendlyCheckCmd, ADMFLAG_GENERIC, "Check if the target is Friendly, Usage: sm_friendly_check \"target\"");
	RegAdminCmd("sm_fc", UseFriendlyCheckCmd, ADMFLAG_GENERIC, "Check if the target is Friendly, Usage: sm_fc \"target\"");
}


public Action UseFriendlyCheckCmd(int client, int args)
{
	if (args != 1)
	{
		char szCommandName[32];
		GetCmdArg(0, szCommandName, sizeof(szCommandName));
		
		ReplyToCommand(client, "[SM] Usage: %s \"target\"", szCommandName);
		return Plugin_Handled;
	}
	
	char strBuffer[MAX_NAME_LENGTH];
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	
	GetCmdArg(1, strBuffer, sizeof(strBuffer));
	
	if ((target_count = ProcessTargetString(strBuffer, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	char name[18];
	
	ReplyToCommand(client, "# userid name                friendly");
	for (int i = 0; i < target_count; i++)
	{
		if (IsValidClient(target_list[i]))
		{
			Format(name,sizeof(name),"\"%N\"",target_list[i]);
			{
				ReplyToCommand(client, "#%7d %19s %s", GetClientUserId(target_list[i]), name, (TF2Friendly_IsFriendly(target_list[i]) ? "Yes" : "No"));		
			}
		}
	}
	return Plugin_Handled;
}
stock bool IsValidClient(int client)
{
	return ((0 < client <= MaxClients) && IsClientInGame(client));
}