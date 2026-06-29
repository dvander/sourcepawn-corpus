#pragma semicolon 1
#include <sourcemod>

new Handle:kvData;

public Plugin:myinfo = 
{
	name = "Chat Pruge",
	author = "CanadaRox",
	description = "A plugin that blocks strings from say or say_team.",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	RegConsoleCmd("say", Say_Command);
	RegConsoleCmd("say_team", Say_Command);
	
	RegAdminCmd("sm_reloadfilters", ReloadFilters_Command, ADMFLAG_CONFIG, "Reloads the chat filters from purgechat.txt");
	
	KvLoad();
}

public OnPluginEnd()
{
	KvClose();
}

KvLoad()
{
	decl String:sNameBuffer[PLATFORM_MAX_PATH];
	
	kvData = CreateKeyValues("ChatPurge");
	BuildPath(Path_SM, sNameBuffer, sizeof(sNameBuffer), "configs/chatpurge.txt");
	
	if (!FileToKeyValues(kvData, sNameBuffer))
	{
		LogError("Could not load ChatPurge data (chatpurge.txt)");
		KvClose();
	}
}

KvClose()
{
	if (kvData != INVALID_HANDLE)
	{
		CloseHandle(kvData);
		kvData = INVALID_HANDLE;
	}
}

public Action:ReloadFilters_Command(client, args)
{
	KvClose();
	KvLoad();
	
	return Plugin_Handled;
}

public Action:Say_Command(client, args)
{
	decl String:sChatBuffer[MAX_NAME_LENGTH];
	
	GetCmdArgString(sChatBuffer, sizeof(sChatBuffer));
	StripQuotes(sChatBuffer);
	
	if (KvJumpToKey(kvData, sChatBuffer)) 
	{
		KvGoBack(kvData);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
