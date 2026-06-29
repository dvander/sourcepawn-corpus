#include <FillUserInfo>
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.1"

public Plugin:myinfo =
{
	name = "[FillUserInfo] Test Plugin",
	author = "Master Xykon",
	description = "FillUserInfo Detour Tests",
	version = PLUGIN_VERSION
};

public OnPluginStart()
{
	CreateConVar("sm_fui_version", PLUGIN_VERSION, "FillUserInfo Detour", FCVAR_NOTIFY|FCVAR_PLUGIN);
	RegConsoleCmd("sm_fid", SetFID);
	RegConsoleCmd("sm_fname", SetFrName);
	RegConsoleCmd("sm_fakeplayer", SetFakePlayer);
	RegConsoleCmd("sm_hltv", SetHLTV);
	RegConsoleCmd("sm_name", SetName);
	RegConsoleCmd("sm_uid", SetUID);
	RegConsoleCmd("sm_guid", SetGUID);
}

public Action:SetFID(client, args)
{
	decl String:strTarget[64]; GetCmdArg(1, strTarget, sizeof(strTarget));
	
	new String:sArg2[34];
	GetCmdArg(2, sArg2, sizeof(sArg2));
	new iArg2 = StringToInt(sArg2);
	
	// Process the targets 
	decl String:strTargetName[MAX_TARGET_LENGTH];
	decl iTargetList[MAXPLAYERS], iTargetCount;
	decl bool:bTargetTranslate;
	
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
		
		new String:name[124];
		GetClientName(iTargetList[i], name, sizeof(name));
		
		// Equip item and tell to client.
		FUI_SetFriendsID(iTargetList[i], iArg2);
		SetClientInfo(iTargetList[i], "friendsID", sArg2);
		PrintToChatAll("Set FID to %i for %s", iArg2, name);  
	}
	
	return Plugin_Handled
}

public Action:SetFrName(client, args)
{
	decl String:strTarget[64]; GetCmdArg(1, strTarget, sizeof(strTarget));
	
	new String:sArg2[34];
	GetCmdArg(2, sArg2, sizeof(sArg2));
	
	// Process the targets 
	decl String:strTargetName[MAX_TARGET_LENGTH];
	decl iTargetList[MAXPLAYERS], iTargetCount;
	decl bool:bTargetTranslate;
	
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
		
		new String:name[124];
		GetClientName(iTargetList[i], name, sizeof(name));
		
		// Equip item and tell to client.
		FUI_SetFriendsName(iTargetList[i], sArg2);
		SetClientInfo(iTargetList[i], "friendsName", sArg2);
		PrintToChatAll("Set FrName to %s for %s", sArg2, name);  
	}
	
	return Plugin_Handled
}

public Action:SetFakePlayer(client, args)
{
	decl String:strTarget[64]; GetCmdArg(1, strTarget, sizeof(strTarget));
	
	new String:sArg2[34];
	GetCmdArg(2, sArg2, sizeof(sArg2));
	new iArg2 = StringToInt(sArg2);
	
	// Process the targets 
	decl String:strTargetName[MAX_TARGET_LENGTH];
	decl iTargetList[MAXPLAYERS], iTargetCount;
	decl bool:bTargetTranslate;
	
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
		
		new String:name[124];
		GetClientName(iTargetList[i], name, sizeof(name));
		
		// Equip item and tell to client.
		FUI_SetFakePlayer(iTargetList[i], iArg2);
		SetClientInfo(iTargetList[i], "fakeplayer", sArg2);
		PrintToChatAll("Set FakePlayer to %s for %s", iArg2, name);  
	}
	
	return Plugin_Handled
}

public Action:SetHLTV(client, args)
{
	decl String:strTarget[64]; GetCmdArg(1, strTarget, sizeof(strTarget));
	
	new String:sArg2[34];
	GetCmdArg(2, sArg2, sizeof(sArg2));
	new iArg2 = StringToInt(sArg2);
	
	// Process the targets 
	decl String:strTargetName[MAX_TARGET_LENGTH];
	decl iTargetList[MAXPLAYERS], iTargetCount;
	decl bool:bTargetTranslate;
	
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
		
		new String:name[124];
		GetClientName(iTargetList[i], name, sizeof(name));
		
		// Equip item and tell to client.
		FUI_SetHLTV(iTargetList[i], iArg2);
		SetClientInfo(iTargetList[i], "ishltv", sArg2);
		PrintToChatAll("Set HLTV to %i for %s", iArg2, name);  
	}
	
	return Plugin_Handled
}

public Action:SetName(client, args)
{
	decl String:strTarget[64]; GetCmdArg(1, strTarget, sizeof(strTarget));
	
	new String:sArg2[34];
	GetCmdArg(2, sArg2, sizeof(sArg2));
	
	// Process the targets 
	decl String:strTargetName[MAX_TARGET_LENGTH];
	decl iTargetList[MAXPLAYERS], iTargetCount;
	decl bool:bTargetTranslate;
	
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
		
		new String:name[124];
		GetClientName(iTargetList[i], name, sizeof(name));
		
		// Equip item and tell to client.
		FUI_SetName(iTargetList[i], sArg2);
		SetClientInfo(iTargetList[i], "name", sArg2);
		PrintToChatAll("Set Name to %s for %s", sArg2, name);  
	}
	
	return Plugin_Handled
}

public Action:SetUID(client, args)
{
	decl String:strTarget[64]; GetCmdArg(1, strTarget, sizeof(strTarget));
	
	new String:sArg2[34];
	GetCmdArg(2, sArg2, sizeof(sArg2));
	new iArg2 = StringToInt(sArg2);
	
	// Process the targets 
	decl String:strTargetName[MAX_TARGET_LENGTH];
	decl iTargetList[MAXPLAYERS], iTargetCount;
	decl bool:bTargetTranslate;
	
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
		
		new String:name[124];
		GetClientName(iTargetList[i], name, sizeof(name));
		
		// Equip item and tell to client.
		FUI_SetUserID(iTargetList[i], iArg2);
		SetClientInfo(iTargetList[i], "userID", sArg2);
		PrintToChatAll("Set UserID to %i for %s", iArg2, name);  
	}
	
	return Plugin_Handled
}

public Action:SetGUID(client, args)
{
	decl String:strTarget[64]; GetCmdArg(1, strTarget, sizeof(strTarget));
	
	new String:sArg2[34];
	GetCmdArg(2, sArg2, sizeof(sArg2));
	
	// Process the targets 
	decl String:strTargetName[MAX_TARGET_LENGTH];
	decl iTargetList[MAXPLAYERS], iTargetCount;
	decl bool:bTargetTranslate;
	
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
		
		new String:name[124];
		GetClientName(iTargetList[i], name, sizeof(name));
		
		// Equip item and tell to client.
		FUI_SetGUID(iTargetList[i], sArg2);
		SetClientInfo(iTargetList[i], "guid", sArg2);
		PrintToChatAll("Set GUID to %s for %s", sArg2, name);  
	}
	
	return Plugin_Handled
}