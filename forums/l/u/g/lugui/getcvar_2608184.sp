#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

int user;


public Plugin myinfo =  {
	name = "Get client Cvar", 
	author = "lugui", 
	description = "Allows a admin to query any cvar on aclients by cvar name", 
	version = "1.0", 
};

public void OnPluginStart()
{
	
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_getcvar", Command_GetCvar, ADMFLAG_ROOT, "Get a client's cvar");
}

public Action Command_GetCvar(client, args)
{
	user = client;
	if (args < 2)
		{
			ReplyToCommand(client, "Usage: sm_cvar <client> <cvar>");
		}
	else{
		char arg1[32], arg2[256];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_TARGET_NONE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		for (int i = 0; i < target_count; i++)
		{
			if(IsValidClient(target_list[i])){
				QueryClientConVar(target_list[i], arg2, CheckCvar);
			}
		}
	}

	return Plugin_Handled;
}

public CheckCvar(QueryCookie cookie, client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	PrintToChat(user, "Cvar at %N: %s", client, cvarValue);
}


IsValidClient( client ) 
{
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) && !IsFakeClient(client)){
		return false; 
	}
	return true; 
}