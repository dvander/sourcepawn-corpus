#include <sourcemod>
#include <sdktools>
#include <ccc>
#include <morecolors>

#define PLUG_VER "1.0.0"

public Plugin myinfo =
{
	name = "[CCC Module] Set Tag",
	author = "aIM",
	description = "Allows users with a certain access to change their tag.",
	version = PLUG_VER,
	url = ""
};

// Maximum amount of tags. You can change this if you need more. //
#define TAGMAX 100

// Tags //
new String:TagName[TAGMAX][PLATFORM_MAX_PATH];
new TagIndex[TAGMAX];
new Count;
new CurrentTag[MAXPLAYERS + 1];
new String:hc[PLATFORM_MAX_PATH];

// ConVars //
new Handle:cvarUseMenu = INVALID_HANDLE;
new Handle:cvarAdminOnly = INVALID_HANDLE;

// Config Handle //
new Handle:hConfig = INVALID_HANDLE;

public OnPluginStart()
{
	cvarUseMenu = CreateConVar("ccc_tag_menu", "1", "Use menu to define tag. REQUIRES CONFIG FILE.", _, true, 0.0, true, 1.0);
	cvarAdminOnly = CreateConVar("ccc_tag_adminonly", "0", "Only admins can access the menu or change their tag trough command?", _, true, 0.0, true, 1.0);
	
	RegAdminCmd("sm_settag", Cmd_Tag, ADMFLAG_GENERIC, "Opens tag menu or sets tag on player, depending on cvar value.");
	RegAdminCmd("sm_colortag", Cmd_CTag, ADMFLAG_GENERIC, "Sets a player's tag color.");
	RegAdminCmd("sm_resettag", Cmd_ResetTag, ADMFLAG_GENERIC, "Resets tag on specified player.");
	
	RegAdminCmd("sm_forcetag", Cmd_FTag, ADMFLAG_ROOT, "Forces setting a tag on a player overriding the menu CVAR.");
	RegAdminCmd("sm_ccctags_reload", Cmd_LoadConfig, ADMFLAG_ROOT, "Reloads CCC Tags config.");
	
	BuildPath(Path_SM, hc, sizeof(hc), "configs/ccc_tags.cfg");
		
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
}

public OnMapStart()
{
	LoadConfig();
}

public OnClientPutInServer(client)
{
	CCC_ResetTag(client);
}

public Action Cmd_LoadConfig (client, args)
{
	LoadConfig();
	ReplyToCommand(client, "[CCC Tags] Reloaded config file.");
}

public Action Cmd_Tag (client, args)
{
	new bool:UsesMenu = GetConVarBool(cvarUseMenu);
	new bool:AdminOnly = GetConVarBool(cvarAdminOnly);
	if (UsesMenu)
	{
		if (AdminOnly)
		{
			if (!CheckCommandAccess(client, "tag_access", ADMFLAG_GENERIC))
			{
				CReplyToCommand(client, "{lightgray}[CCC Tags] {default}Menu is admin only!");
				return Plugin_Handled;
			}
		}
		DisplayTagMenu(client);
		return Plugin_Handled;
	}
	
	if (!UsesMenu && args < 2)
	{
		CReplyToCommand(client, "{lightgray}[CCC Tags] {default}Usage: sm_settag <player> <tag> [tagcolor]");
		return Plugin_Handled;
	}
	
	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client, 
			target_list, 
			MAXPLAYERS, 
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	decl String:tagName[256];
	GetCmdArg(2, tagName, sizeof(tagName));
	
	if (args == 3)
	{
		decl String:colorCodeStr[256];
		GetCmdArg(3, colorCodeStr, sizeof(colorCodeStr));
		new colorCode = StringToInt(colorCodeStr, 16);

		for (int i = 0; i < target_count; i++)
		{
			int target = target_list[i];
			if (!CCC_SetColor(target, CCC_TagColor, colorCode, false))
			{
				CReplyToCommand(client, "{lightgray}[CCC Tags] {default}Color %i is not valid!", colorCode);
				return Plugin_Handled;
			}
			
			CCC_SetTag(target, tagName);
			CCC_SetColor(target, CCC_TagColor, colorCode, false);
			CPrintToChat(target, "{lightgray}[CCC Tags] {default}ADMIN {red}%N {default}set color on your tag %s.", client, tagName);
		}
		CPrintToChat(client, "{lightgray}[CCC Tags] {default}Set color on %t with tag %s.", target_name, tagName);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];
		
		CCC_SetTag(target, tagName);
		CPrintToChat(target, "{lightgray}[CCC Tags] {default}ADMIN {red}%N {default}set tag %s on you.", client, tagName);
		CPrintToChat(client, "{lightgray}[CCC Tags] {default}Set tag %s on %t", tagName, target_name);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Cmd_FTag (client, args)
{
	if (args < 2)
	{
		CReplyToCommand(client, "{lightgray}[CCC Tags] {default}Usage: sm_forcetag <player> <tag> [tagcolor]");
		return Plugin_Handled;
	}
	
	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client, 
			target_list, 
			MAXPLAYERS, 
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	decl String:tagName[256];
	GetCmdArg(2, tagName, sizeof(tagName));
	
	if (args == 3)
	{
		decl String:colorCodeStr[256];
		GetCmdArg(3, colorCodeStr, sizeof(colorCodeStr));
		new colorCode = StringToInt(colorCodeStr, 16);

		for (int i = 0; i < target_count; i++)
		{
			int target = target_list[i];
			if (!CCC_SetColor(target, CCC_TagColor, colorCode, false))
			{
				CReplyToCommand(client, "{lightgray}[CCC Tags] {default}Color %i is not valid!", colorCode);
				return Plugin_Handled;
			}
			
			CCC_SetTag(target, tagName);
			CCC_SetColor(target, CCC_TagColor, colorCode, false);
			CPrintToChat(target, "{lightgray}[CCC Tags] {default}ADMIN {red}%N {default}set color on your tag %s.", client, tagName);
		}
		CPrintToChat(client, "{lightgray}[CCC Tags] {default}Set color on %t with tag %s.", target_name, tagName);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];
		
		CCC_SetTag(target, tagName);
		CPrintToChat(target, "{lightgray}[CCC Tags] {default}ADMIN {red}%N {default}set tag %s on you.", client, tagName);
		CPrintToChat(client, "{lightgray}[CCC Tags] {default}Set tag %s on %t", tagName, target_name);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Cmd_CTag (client, args)
{
	if (args < 2)
	{
		CReplyToCommand(client, "{lightgray}[CCC Tags] {default}Usage: sm_colortag <player> <color>");
		return Plugin_Handled;
	}
	
	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client, 
			target_list, 
			MAXPLAYERS, 
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	decl String:colorCodeStr[256];
	GetCmdArg(3, colorCodeStr, sizeof(colorCodeStr));
	int colorCode = StringToInt(colorCodeStr, 16);
	
	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];
		if (!CCC_SetColor(target, CCC_TagColor, colorCode, false))
		{
			CReplyToCommand(client, "{lightgray}[CCC Tags] {default}Color %i is not valid!", colorCode);
			return Plugin_Handled;
		}
		CCC_SetColor(target, CCC_TagColor, colorCode, false);
		CPrintToChat(target, "{lightgray}[CCC Tags] {default}ADMIN {red}%N {default}set color on your tag.", client);
		CPrintToChat(client, "{lightgray}[CCC Tags] {default}Set tag color on %t.", target_name);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Cmd_ResetTag (client, args)
{
	if (args < 1)
	{
		CReplyToCommand(client, "{lightgray}[CCC Tags] {default}Usage: sm_resettag <player>");
		return Plugin_Handled;
	}
	
	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client, 
			target_list, 
			MAXPLAYERS, 
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];
		CCC_ResetTag(target);
		CPrintToChat(target, "{lightgray}[CCC Tags] {default}ADMIN {red}%N {default}removed your current tag.", client);
		CPrintToChat(client, "{lightgray}[CCC Tags] {default}Removed tag on %t", target_name);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public MainMenuHandler(Handle:menu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(menu);
		return;
	}

	if(iAction == MenuAction_Select)
	{
		decl String:strBuffer[32],String:strSave[32];
		GetMenuItem(menu, iParam2, strBuffer, sizeof(strBuffer));

		new tagindex = StringToInt(strBuffer);
		CurrentTag[iParam1] = TagIndex[tagindex];
		IntToString(TagIndex[tagindex], strSave, sizeof(strSave));
		CPrintToChat(iParam1, "{lightgray}[CCC Tags] {default}You are now using the tag %s", TagName[tagindex]);	

		CCC_SetTag(iParam1, TagName[tagindex]);
	}
}

DisplayTagMenu(client)
{
	new Handle:menu = CreateMenu(MainMenuHandler);
	
	SetMenuTitle(menu, "CCC Tag Menu");
	
	new count = 0;
	
	decl String:StringTagIndex[4];
	for (new i = 0; i < Count; i++)
	{
		IntToString(i, StringTagIndex, sizeof(StringTagIndex));
		AddMenuItem(menu, StringTagIndex, TagName[i]);
		count++;
	}
	if (count == 0)
	{
		AddMenuItem(menu, "", "There are no tags available.",ITEMDRAW_DISABLED);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
	return;
}

stock LoadConfig()
{
	hConfig = CreateKeyValues("CCCTagMenu");
	
	if (!FileToKeyValues(hConfig, hc))
		SetFailState("Can't find menu file at %s ! Make sure it's there.", hc);
	
	for (new i = 0; i < TAGMAX; i++)
	{
		strcopy(TagName[i], sizeof(TagName[]), "");
	}
	Count = 0;
	
	new String:sIndex[8];
	
	if(!KvGotoFirstSubKey(hConfig))
	{
		SetFailState("Config is missing first key!");
		return;
	}
	do
	{
		KvGetSectionName(hConfig, sIndex, sizeof(sIndex));
		KvGetString(hConfig, "tag", TagName[Count], sizeof(TagName[]));
		
		Count++;
	}
	while(KvGotoNextKey(hConfig));
	
	CloseHandle(hConfig);
	
	LogMessage("Loaded %i tags for Set Tag.", Count);
}