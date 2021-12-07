#include <sourcemod>
#include <convars>

#define _DEBUG
#define _VERSION_ "1.1"

ConVar g_cvMyCDVersion = null;
ConVar g_cvMyCDEnable = null;

public Plugin myinfo =
{
	name = "My CD",
	author = "MBC_표준FM_95.9㎒",
	description = "A plugin that announces players' connection and disconnection. Credit to Foolish",
	version = _VERSION_,
	url = "https://sban.jobggun.tk/"
}

public void OnPluginStart()
{
#if defined _DEBUG
	LoadTranslations("common.phrases");
#endif
	LoadTranslations("mycd.phrases");
	
	g_cvMyCDVersion = CreateConVar("sm_mycd_version", _VERSION_, "My CD Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvMyCDEnable = CreateConVar("sm_mycd_enable", "1", "Determines whether the plugin runs or not", FCVAR_NOTIFY, true, 0.0, true, 1.0);

#if defined _DEBUG
	RegAdminCmd("sm_mycd_debug_onconnect", cmdMyCDDebugOnConnect, ADMFLAG_GENERIC,  "Tests MyCD OnConnect Condition - For Debug");
	RegAdminCmd("sm_mycd_debug_ondisconnect", cmdMyCDDebugOnDisconnect, ADMFLAG_GENERIC, "Tests MyCD OnConnect Condition - For Debug");
#endif
}

public void MyCDOnConnect(int client)
{
	if(IsFakeClient(client)) return;
	
	char client_name[MAX_NAME_LENGTH];
	
	GetClientName(client, client_name, sizeof(client_name));
	
	PrintToChat(client, "%t", "OnConnect", client_name);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && i != client)
		{
			PrintToChat(i, "%t", "OnConnectAll", client_name);
		}
	}
	
	return;
}

public void OnClientPostAdminCheck(int client)
{
	if (g_cvMyCDEnable.BoolValue == false)
		return;
	MyCDOnConnect(client);
	
	return;
}

#if defined _DEBUG
public Action cmdMyCDDebugOnConnect(int client, int args)
{
	if (g_cvMyCDEnable.BoolValue == false)
		return Plugin_Handled;
	
	if (args == 0)
	{
		MyCDOnConnect(client);
	} else
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		
		if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			sizeof(target_list),
			0,
			target_name,
			sizeof(target_list),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		for(int i = 0; i < target_count; i++)
		{
			MyCDOnConnect(target_list[i]);
			LogAction(client, target_list[i], "%L initiated Connection Message of %L", client, target_list[i]); 
		}
		
		if (tn_is_ml)
		{
			ShowActivity2(client, "[SM] ", "%t", "OnConnectDebug", target_name);
		} else
		{
			ShowActivity2(client, "[SM] ", "Showed OnConnect Message to %s", target_name);
		}
	}
	
	return Plugin_Handled;
}
#endif

public void MyCDOnDisconnect(int client)
{
	char client_name[MAX_NAME_LENGTH];
	
	GetClientName(client, client_name, sizeof(client_name));
	
	PrintToChatAll("%t", "OnDisconnectAll", client_name);
	
	return;
}

public void OnClientDisconnect(int client)
{
	if (g_cvMyCDEnable.BoolValue == false)
		return;
	
	MyCDOnDisconnect(client);
	
	return;
}

#if defined _DEBUG
public Action cmdMyCDDebugOnDisconnect(int client, int args)
{
	if (g_cvMyCDEnable.BoolValue == false)
		return Plugin_Handled;
	
	if (args == 0)
	{
		MyCDOnDisconnect(client);
	} else
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		
		if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			sizeof(target_list),
			0,
			target_name,
			sizeof(target_list),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		for(int i = 0; i < target_count; i++)
		{
			MyCDOnDisconnect(target_list[i]);
			LogAction(client, target_list[i], "%L initiated Disconnection Message of %L", client, target_list[i]); 
		}
		
		if (tn_is_ml)
		{
			ShowActivity2(client, "[SM] ", "%t", "OnDisconnectDebug", target_name);
		} else
		{
			ShowActivity2(client, "[SM] ", "Showed OnDisconnect Message to %s", target_name);
		}
	}
	
	return Plugin_Handled;
}
#endif
