#include <FillUserInfo>
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.1-B"

public Plugin myinfo =
{
	name = "FillUserInfo Function Commands",
	author = "Master Xykon (Playa edit)",
	description = "FillUserInfo Detour Tests",
	version = PLUGIN_VERSION
};

public OnPluginStart()
{
	CreateConVar("sm_fui_version", PLUGIN_VERSION, "FillUserInfo Detour", FCVAR_NOTIFY);
	RegAdminCmd("sm_fid", SetFID, ADMFLAG_ROOT, "Set Friend ID(SteamID3)");
	RegAdminCmd("sm_fname", SetFrName, ADMFLAG_ROOT, "Set Friend Name");
	RegAdminCmd("sm_fakeplayer", SetFakePlayer, ADMFLAG_ROOT, "?");
	RegAdminCmd("sm_hltv", SetHLTV, ADMFLAG_ROOT, "?");
	RegAdminCmd("sm_name", SetName, ADMFLAG_ROOT, "Set Client(or Bot) Name, works like the name Console Command");
	RegAdminCmd("sm_uid", SetUID, ADMFLAG_ROOT, "Set User ID(SteamID3)");
	RegAdminCmd("sm_guid", SetGUID, ADMFLAG_ROOT, "Set User ID ~Unknown~");
}

public Action SetFID(client, args)
{
	char strTarget[64]; GetCmdArg(1, strTarget, sizeof(strTarget));
	
	char sArg2[34];
	GetCmdArg(2, sArg2, sizeof(sArg2));
	int iArg2 = StringToInt(sArg2);
	
	// Process the targets 
	char strTargetName[MAX_TARGET_LENGTH];
	int iTargetList[MAXPLAYERS], iTargetCount;
	bool bTargetTranslate;
	
	if ((iTargetCount = ProcessTargetString(strTarget, 0, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
	strTargetName, sizeof(strTargetName), bTargetTranslate)) <= 0)
	{
		ReplyToTargetError(0, iTargetCount);
		return Plugin_Handled;
	}
	
	// Apply to all targets
	for (new i = 0; i < iTargetCount; i++)
	{
		if (!IsClientInGame(iTargetList[i])) continue;
		
		char name[124];
		GetClientName(iTargetList[i], name, sizeof(name));
		
		// Equip item and tell to client.
		FUI_SetFriendsID(iTargetList[i], iArg2);
		SetClientInfo(iTargetList[i], "friendsID", sArg2);
		PrintToServer("Set FID to %i for %s", iArg2, name);  
	}
	
	return Plugin_Handled;
}

public Action SetFrName(client, args)
{
	char strTarget[64]; GetCmdArg(1, strTarget, sizeof(strTarget));
	
	char sArg2[34];
	GetCmdArg(2, sArg2, sizeof(sArg2));
	
	// Process the targets 
	char strTargetName[MAX_TARGET_LENGTH];
	int iTargetList[MAXPLAYERS], iTargetCount;
	bool bTargetTranslate;
	
	if ((iTargetCount = ProcessTargetString(strTarget, 0, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
	strTargetName, sizeof(strTargetName), bTargetTranslate)) <= 0)
	{
		ReplyToTargetError(0, iTargetCount);
		return Plugin_Handled;
	}
	
	// Apply to all targets
	for (new i = 0; i < iTargetCount; i++)
	{
		if (!IsClientInGame(iTargetList[i])) continue;
		
		char name[124];
		GetClientName(iTargetList[i], name, sizeof(name));
		
		// Equip item and tell to client.
		FUI_SetFriendsName(iTargetList[i], sArg2);
		SetClientInfo(iTargetList[i], "friendsName", sArg2);
		PrintToServer("Set FrName to %s for %s", sArg2, name);  
	}
	
	return Plugin_Handled;
}

public Action SetFakePlayer(client, args)
{
	char strTarget[64]; GetCmdArg(1, strTarget, sizeof(strTarget));
	
	char sArg2[34];
	GetCmdArg(2, sArg2, sizeof(sArg2));
	int iArg2 = StringToInt(sArg2);
	
	// Process the targets 
	char strTargetName[MAX_TARGET_LENGTH];
	int iTargetList[MAXPLAYERS], iTargetCount;
	bool bTargetTranslate;
	
	if ((iTargetCount = ProcessTargetString(strTarget, 0, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
	strTargetName, sizeof(strTargetName), bTargetTranslate)) <= 0)
	{
		ReplyToTargetError(0, iTargetCount);
		return Plugin_Handled;
	}
	
	// Apply to all targets
	for (new i = 0; i < iTargetCount; i++)
	{
		if (!IsClientInGame(iTargetList[i])) continue;
		
		char name[124];
		GetClientName(iTargetList[i], name, sizeof(name));
		
		// Equip item and tell to client.
		FUI_SetFakePlayer(iTargetList[i], iArg2);
		SetClientInfo(iTargetList[i], "fakeplayer", sArg2);
		PrintToServer("Set FakePlayer to %s for %s", iArg2, name);  
	}
	
	return Plugin_Handled;
}

public Action SetHLTV(client, args)
{
	char strTarget[64]; GetCmdArg(1, strTarget, sizeof(strTarget));
	
	char sArg2[34];
	GetCmdArg(2, sArg2, sizeof(sArg2));
	int iArg2 = StringToInt(sArg2);
	
	// Process the targets 
	char strTargetName[MAX_TARGET_LENGTH];
	int iTargetList[MAXPLAYERS], iTargetCount;
	bool bTargetTranslate;
	
	if ((iTargetCount = ProcessTargetString(strTarget, 0, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
	strTargetName, sizeof(strTargetName), bTargetTranslate)) <= 0)
	{
		ReplyToTargetError(0, iTargetCount);
		return Plugin_Handled;
	}
	
	// Apply to all targets
	for (new i = 0; i < iTargetCount; i++)
	{
		if (!IsClientInGame(iTargetList[i])) continue;
		
		char name[124];
		GetClientName(iTargetList[i], name, sizeof(name));
		
		// Equip item and tell to client.
		FUI_SetHLTV(iTargetList[i], iArg2);
		SetClientInfo(iTargetList[i], "ishltv", sArg2);
		PrintToServer("Set HLTV to %i for %s", iArg2, name);  
	}
	
	return Plugin_Handled;
}

public Action SetName(client, args)
{
	char strTarget[64]; GetCmdArg(1, strTarget, sizeof(strTarget));
	
	char sArg2[34];
	GetCmdArg(2, sArg2, sizeof(sArg2));
	
	// Process the targets 
	char strTargetName[MAX_TARGET_LENGTH];
	int iTargetList[MAXPLAYERS], iTargetCount;
	bool bTargetTranslate;
	
	if ((iTargetCount = ProcessTargetString(strTarget, 0, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
	strTargetName, sizeof(strTargetName), bTargetTranslate)) <= 0)
	{
		ReplyToTargetError(0, iTargetCount);
		return Plugin_Handled;
	}
	
	// Apply to all targets
	for (new i = 0; i < iTargetCount; i++)
	{
		if (!IsClientInGame(iTargetList[i])) continue;
		
		char name[124];
		GetClientName(iTargetList[i], name, sizeof(name));
		
		// Equip item and tell to client.
		FUI_SetName(iTargetList[i], sArg2);
		SetClientInfo(iTargetList[i], "name", sArg2);
		PrintToServer("Set Name to %s for %s", sArg2, name);  
	}
	
	return Plugin_Handled;
}

public Action SetUID(client, args)
{
	char strTarget[64]; GetCmdArg(1, strTarget, sizeof(strTarget));
	
	char sArg2[34];
	GetCmdArg(2, sArg2, sizeof(sArg2));
	int iArg2 = StringToInt(sArg2);
	
	// Process the targets 
	char strTargetName[MAX_TARGET_LENGTH];
	int iTargetList[MAXPLAYERS], iTargetCount;
	bool bTargetTranslate;
	
	if ((iTargetCount = ProcessTargetString(strTarget, 0, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
	strTargetName, sizeof(strTargetName), bTargetTranslate)) <= 0)
	{
		ReplyToTargetError(0, iTargetCount);
		return Plugin_Handled;
	}
	
	// Apply to all targets
	for (new i = 0; i < iTargetCount; i++)
	{
		if (!IsClientInGame(iTargetList[i])) continue;
		
		char name[124];
		GetClientName(iTargetList[i], name, sizeof(name));
		
		// Equip item and tell to client.
		FUI_SetUserID(iTargetList[i], iArg2);
		SetClientInfo(iTargetList[i], "userID", sArg2);
		PrintToServer("Set UserID to %i for %s", iArg2, name);  
	}
	
	return Plugin_Handled;
}

public Action SetGUID(client, args)
{
	char strTarget[64]; GetCmdArg(1, strTarget, sizeof(strTarget));
	
	char sArg2[34];
	GetCmdArg(2, sArg2, sizeof(sArg2));
	
	// Process the targets 
	char strTargetName[MAX_TARGET_LENGTH];
	int iTargetList[MAXPLAYERS], iTargetCount;
	bool bTargetTranslate;
	
	if ((iTargetCount = ProcessTargetString(strTarget, 0, iTargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
	strTargetName, sizeof(strTargetName), bTargetTranslate)) <= 0)
	{
		ReplyToTargetError(0, iTargetCount);
		return Plugin_Handled;
	}
	
	// Apply to all targets
	for (new i = 0; i < iTargetCount; i++)
	{
		if (!IsClientInGame(iTargetList[i])) continue;
		
		char name[124];
		GetClientName(iTargetList[i], name, sizeof(name));
		
		// Equip item and tell to client.
		FUI_SetGUID(iTargetList[i], sArg2);
		SetClientInfo(iTargetList[i], "guid", sArg2);
		PrintToServer("Set GUID to %s for %s", sArg2, name);  
	}
	
	return Plugin_Handled;
}