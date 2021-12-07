#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <regex>
#include <ccc>

// ====[ DEFINES ]=============================================================
#define PLUGIN_NAME "Custom Chat Colors Menu"
#define PLUGIN_VERSION "2.2"
#define MAX_COLORS 255
#define	TAG 0
#define NAME 1
#define CHAT 2
#define ENABLEFLAG_TAG (1 << TAG)
#define ENABLEFLAG_NAME (1 << NAME)
#define ENABLEFLAG_CHAT (1 << CHAT)

// ====[ HANDLES | CVARS ]=====================================================
new Handle:g_hCvarEnabled, g_iCvarEnabled;
new Handle:g_hCvarHideTags, bool:g_bCvarHideTags;
new Handle:g_hRegexHex;
new Handle:g_hSQL;

// ====[ VARIABLES ]===========================================================
new g_iColorCount;
new AdminFlag:g_iColorFlagList[MAX_COLORS][16];
new bool:g_bColorsLoaded[MAXPLAYERS + 1];
new bool:g_bColorAdminFlags[MAX_COLORS];
new bool:g_bHideTag[MAXPLAYERS + 1];
new bool:g_bAccessColor[MAXPLAYERS + 1][3];
new bool:g_bAccessHideTags[MAXPLAYERS + 1];
new String:g_strAuth[MAXPLAYERS + 1][32];
new String:g_strColor[MAXPLAYERS + 1][3][7];
new String:g_strColorName[MAX_COLORS][255];
new String:g_strColorHex[MAX_COLORS][255];
new String:g_strColorFlags[MAX_COLORS][255];
new String:g_strConfigFile[PLATFORM_MAX_PATH];
new String:g_strSQLDriver[16];

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "ReFlexPoison",
	description = "Change Custom Chat Colors settings through easy to access menus",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

// ====[ EVENTS ]==============================================================
public OnPluginStart()
{
	CreateConVar("sm_cccm_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_hCvarEnabled = CreateConVar("sm_cccm_enabled", "7", "Enable Custom Chat Colors Menu (Add up the numbers to choose)\n0 = Disabled\n1 = Tag\n2 = Name\n4 = Chat", FCVAR_PLUGIN, true, 0.0, true, 7.0);
	g_iCvarEnabled = GetConVarInt(g_hCvarEnabled);
	HookConVarChange(g_hCvarEnabled, OnConVarChange);

	g_hCvarHideTags = CreateConVar("sm_cccm_hidetags", "1", "Allow players to hide their chat tags\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_bCvarHideTags = GetConVarBool(g_hCvarHideTags);
	HookConVarChange(g_hCvarHideTags, OnConVarChange);

	AutoExecConfig(true, "plugin.custom-chatcolors-menu");

	RegAdminCmd("sm_ccc", Command_Color, ADMFLAG_GENERIC, "Open Custom Chat Colors Menu");
	RegAdminCmd("sm_reload_cccm", Command_Reload, ADMFLAG_ROOT, "Reloads Custom Chat Colors Menu config");
	RegAdminCmd("sm_tagcolor", Command_TagColor, ADMFLAG_ROOT, "Change tag color to a specified hexadecimal value");
	RegAdminCmd("sm_resettag", Command_ResetTagColor, ADMFLAG_GENERIC, "Reset tag color to default");
	RegAdminCmd("sm_namecolor", Command_NameColor, ADMFLAG_ROOT, "Change name color to a specified hexadecimal value");
	RegAdminCmd("sm_resetname", Command_ResetNameColor, ADMFLAG_GENERIC, "Reset name color to default");
	RegAdminCmd("sm_chatcolor", Command_ChatColor, ADMFLAG_ROOT, "Change chat color to a specified hexadecimal value");
	RegAdminCmd("sm_resetchat", Command_ResetChatColor, ADMFLAG_GENERIC, "Reset chat color to default");

	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("custom-chatcolors-menu.phrases");

	g_hRegexHex = CompileRegex("([A-Fa-f0-9]{6})");

	BuildPath(Path_SM, g_strConfigFile, sizeof(g_strConfigFile), "configs/custom-chatcolors-menu.cfg");

	g_hSQL = INVALID_HANDLE;
	if(SQL_CheckConfig("cccm"))
		SQL_TConnect(SQLQuery_Connect, "cccm");
}

public OnConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == g_hCvarEnabled)
		g_iCvarEnabled = GetConVarInt(g_hCvarEnabled);
	else if(hConvar == g_hCvarHideTags)
		g_bCvarHideTags = GetConVarBool(g_hCvarHideTags);
}

public SQL_LoadColors(iClient)
{
	if(!IsClientAuthorized(iClient))
		return;

	if(g_hSQL != INVALID_HANDLE)
	{
		decl String:strAuth[32];
		GetClientAuthString(iClient, strAuth, sizeof(strAuth));
		strcopy(g_strAuth[iClient], sizeof(g_strAuth[]), strAuth);

		decl String:strQuery[256];
		Format(strQuery, sizeof(strQuery), "SELECT hidetag, tagcolor, namecolor, chatcolor FROM cccm_users WHERE auth = '%s'", g_strAuth[iClient]);
		SQL_TQuery(g_hSQL, SQLQuery_LoadColors, strQuery, GetClientUserId(iClient), DBPrio_High);
	}
}

public OnConfigsExecuted()
{
	Config_Load();
}

public OnClientConnected(iClient)
{
	g_bColorsLoaded[iClient] = false;
	g_bHideTag[iClient] = false;
	g_bAccessColor[iClient][TAG] = false;
	g_bAccessColor[iClient][NAME] = false;
	g_bAccessColor[iClient][CHAT] = false;
	g_bAccessHideTags[iClient] = false;
	strcopy(g_strAuth[iClient], sizeof(g_strAuth[]), "");
	strcopy(g_strColor[iClient][TAG], sizeof(g_strColor[][]), "");
	strcopy(g_strColor[iClient][NAME], sizeof(g_strColor[][]), "");
	strcopy(g_strColor[iClient][CHAT], sizeof(g_strColor[][]), "");
}

public CCC_OnUserConfigLoaded(iClient)
{
	if(g_bColorsLoaded[iClient])
		return;

	decl String:strTag[7];
	IntToString(CCC_GetColor(iClient, CCC_TagColor), strTag, sizeof(strTag));
	if(IsValidHex(strTag))
		strcopy(g_strColor[iClient][TAG], sizeof(g_strColor[][]), strTag);

	decl String:strName[7];
	IntToString(CCC_GetColor(iClient, CCC_TagColor), strName, sizeof(strName));
	if(IsValidHex(strName))
		strcopy(g_strColor[iClient][NAME], sizeof(g_strColor[][]), strName);

	decl String:strChat[7];
	IntToString(CCC_GetColor(iClient, CCC_TagColor), strChat, sizeof(strChat));
	if(IsValidHex(strChat))
		strcopy(g_strColor[iClient][CHAT], sizeof(g_strColor[][]), strChat);
}

public OnClientAuthorized(iClient, const String:strAuth[])
{
	strcopy(g_strAuth[iClient], sizeof(g_strAuth[]), strAuth);
}

public OnRebuildAdminCache(AdminCachePart:iPart)
{
	for(new i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		OnClientConnected(i);
		OnClientPostAdminCheck(i);
	}
}

public OnClientPostAdminCheck(iClient)
{
	SQL_LoadColors(iClient);
	if(CheckCommandAccess(iClient, "sm_ccc_tag", ADMFLAG_GENERIC))
		g_bAccessColor[iClient][TAG] = true;
	if(CheckCommandAccess(iClient, "sm_ccc_name", ADMFLAG_GENERIC))
		g_bAccessColor[iClient][NAME] = true;
	if(CheckCommandAccess(iClient, "sm_ccc_chat", ADMFLAG_GENERIC))
		g_bAccessColor[iClient][CHAT] = true;
	if(CheckCommandAccess(iClient, "sm_ccc_hidetags", ADMFLAG_GENERIC))
		g_bAccessHideTags[iClient] = true;
}

public Action:CCC_OnColor(iClient, const String:strMessage[], CCC_ColorType:iType)
{
	if(iType == CCC_TagColor)
	{
		if(!(g_iCvarEnabled & ENABLEFLAG_TAG))
			return Plugin_Handled;

		if(g_bCvarHideTags && g_bHideTag[iClient] && g_bAccessHideTags[iClient])
			return Plugin_Handled;

		if(!StrEqual(g_strColor[iClient][TAG], "-1") && !IsValidHex(g_strColor[iClient][TAG]))
			return Plugin_Handled;
	}

	if(iType == CCC_NameColor)
	{
		if(!(g_iCvarEnabled & ENABLEFLAG_NAME))
			return Plugin_Handled;

		if(!IsValidHex(g_strColor[iClient][NAME]))
			return Plugin_Handled;
	}

	if(iType == CCC_ChatColor)
	{
		if(!(g_iCvarEnabled & ENABLEFLAG_CHAT))
			return Plugin_Handled;

		if(!IsValidHex(g_strColor[iClient][CHAT]))
			return Plugin_Handled;
	}

	return Plugin_Continue;
}

// ====[ COMMANDS ]============================================================
public Action:Command_Color(iClient, iArgs)
{
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	Menu_Settings(iClient);
	return Plugin_Handled;
}

public Action:Command_Reload(iClient, iArgs)
{
	Config_Load();
	ReplyToCommand(iClient, "[SM] Configuration file %s reloaded.", g_strConfigFile);
	return Plugin_Handled;
}

public Action:Command_TagColor(iClient, iArgs)
{
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	if(iArgs != 1)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_tagcolor <hex>");
		return Plugin_Handled;
	}

	decl String:strArg[32];
	GetCmdArgString(strArg, sizeof(strArg));
	ReplaceString(strArg, sizeof(strArg), "#", "", false);

	if(!IsValidHex(strArg))
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_tagcolor <hex>");
		return Plugin_Handled;
	}

	PrintToChat(iClient, "\x01[SM] %T \x07%s#%s\x01", "TagSet", iClient, strArg, strArg);
	strcopy(g_strColor[iClient][TAG], sizeof(g_strColor[][]), strArg);
	CCC_SetColor(iClient, CCC_TagColor, StringToInt(strArg, 16), false);

	if(g_hSQL != INVALID_HANDLE && IsClientAuthorized(iClient))
	{
		decl String:strQuery[256];
		Format(strQuery, sizeof(strQuery), "SELECT tagcolor FROM cccm_users WHERE auth = '%s'", g_strAuth[iClient]);
		SQL_TQuery(g_hSQL, SQLQuery_TagColor, strQuery, GetClientUserId(iClient), DBPrio_High);
	}

	return Plugin_Handled;
}

public Action:Command_ResetTagColor(iClient, iArgs)
{
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	PrintToChat(iClient, "[SM] %T", "TagReset", iClient);
	strcopy(g_strColor[iClient][TAG], sizeof(g_strColor[][]), "");
	CCC_ResetColor(iClient, CCC_TagColor);

	decl String:strTag[32];
	IntToString(CCC_GetColor(iClient, CCC_TagColor), strTag, sizeof(strTag));
	strcopy(g_strColor[iClient][TAG], sizeof(g_strColor[][]), strTag);

	if(g_hSQL != INVALID_HANDLE && IsClientAuthorized(iClient))
	{
		decl String:strQuery[256];
		Format(strQuery, sizeof(strQuery), "SELECT tagcolor FROM cccm_users WHERE auth = '%s'", g_strAuth[iClient]);
		SQL_TQuery(g_hSQL, SQLQuery_TagColor, strQuery, GetClientUserId(iClient), DBPrio_High);
	}

	return Plugin_Handled;
}

public Action:Command_NameColor(iClient, iArgs)
{
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	if(iArgs != 1)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_namecolor <hex>");
		return Plugin_Handled;
	}

	decl String:strArg[32];
	GetCmdArgString(strArg, sizeof(strArg));
	ReplaceString(strArg, sizeof(strArg), "#", "", false);

	if(!IsValidHex(strArg))
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_namecolor <hex>");
		return Plugin_Handled;
	}

	PrintToChat(iClient, "\x01[SM] %T \x07%s#%s\x01", "NameSet", iClient, strArg, strArg);
	strcopy(g_strColor[iClient][TAG], sizeof(g_strColor[][]), strArg);
	CCC_SetColor(iClient, CCC_TagColor, StringToInt(strArg, 16), false);

	if(g_hSQL != INVALID_HANDLE && IsClientAuthorized(iClient))
	{
		decl String:strQuery[256];
		Format(strQuery, sizeof(strQuery), "SELECT namecolor FROM cccm_users WHERE auth = '%s'", g_strAuth[iClient]);
		SQL_TQuery(g_hSQL, SQLQuery_TagColor, strQuery, GetClientUserId(iClient), DBPrio_High);
	}

	return Plugin_Handled;
}

public Action:Command_ResetNameColor(iClient, iArgs)
{
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	PrintToChat(iClient, "[SM] %T", "NameReset", iClient);
	strcopy(g_strColor[iClient][NAME], sizeof(g_strColor[][]), "");
	CCC_ResetColor(iClient, CCC_NameColor);

	if(g_hSQL != INVALID_HANDLE && IsClientAuthorized(iClient))
	{
		decl String:strQuery[256];
		Format(strQuery, sizeof(strQuery), "SELECT namecolor FROM cccm_users WHERE auth = '%s'", g_strAuth[iClient]);
		SQL_TQuery(g_hSQL, SQLQuery_NameColor, strQuery, GetClientUserId(iClient), DBPrio_High);
	}

	return Plugin_Handled;
}

public Action:Command_ChatColor(iClient, iArgs)
{
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	if(iArgs != 1)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_chatcolor <hex>");
		return Plugin_Handled;
	}

	decl String:strArg[32];
	GetCmdArgString(strArg, sizeof(strArg));
	ReplaceString(strArg, sizeof(strArg), "#", "", false);

	if(!IsValidHex(strArg))
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_chatcolor <hex>");
		return Plugin_Handled;
	}

	PrintToChat(iClient, "\x01[SM] %T \x07%s#%s\x01", "ChatSet", iClient, strArg, strArg);
	strcopy(g_strColor[iClient][TAG], sizeof(g_strColor[][]), strArg);
	CCC_SetColor(iClient, CCC_TagColor, StringToInt(strArg, 16), false);

	if(g_hSQL != INVALID_HANDLE && IsClientAuthorized(iClient))
	{
		decl String:strQuery[256];
		Format(strQuery, sizeof(strQuery), "SELECT chatcolor FROM cccm_users WHERE auth = '%s'", g_strAuth[iClient]);
		SQL_TQuery(g_hSQL, SQLQuery_TagColor, strQuery, GetClientUserId(iClient), DBPrio_High);
	}

	return Plugin_Handled;
}

public Action:Command_ResetChatColor(iClient, iArgs)
{
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	PrintToChat(iClient, "[SM] %T", "ChatReset", iClient);
	strcopy(g_strColor[iClient][CHAT], sizeof(g_strColor[][]), "");
	CCC_ResetColor(iClient, CCC_ChatColor);

	if(g_hSQL != INVALID_HANDLE && IsClientAuthorized(iClient))
	{
		decl String:strQuery[256];
		Format(strQuery, sizeof(strQuery), "SELECT chatcolor FROM cccm_users WHERE auth = '%s'", g_strAuth[iClient]);
		SQL_TQuery(g_hSQL, SQLQuery_ChatColor, strQuery, GetClientUserId(iClient), DBPrio_High);
	}

	return Plugin_Handled;
}

// ====[ MENUS ]===============================================================
public Menu_Settings(iClient)
{
	if(IsVoteInProgress())
		return;

	new Handle:hMenu = CreateMenu(MenuHandler_Settings);
	SetMenuTitle(hMenu, "%T:", "Title", iClient);

	decl String:strBuffer[32];
	Format(strBuffer, sizeof(strBuffer), "%T", "ChangeTag", iClient);
	if(g_iCvarEnabled & ENABLEFLAG_TAG && (g_bAccessColor[iClient][TAG] || (g_bCvarHideTags && g_bAccessHideTags[iClient])))
		AddMenuItem(hMenu, "Tag", strBuffer);
	else
		AddMenuItem(hMenu, "", strBuffer, ITEMDRAW_DISABLED);

	Format(strBuffer, sizeof(strBuffer), "%T", "ChangeName", iClient);
	if(g_iCvarEnabled & ENABLEFLAG_NAME && g_bAccessColor[iClient][NAME])
		AddMenuItem(hMenu, "Name", strBuffer);
	else
		AddMenuItem(hMenu, "", strBuffer, ITEMDRAW_DISABLED);

	Format(strBuffer, sizeof(strBuffer), "%T", "ChangeChat", iClient);
	if(g_iCvarEnabled & ENABLEFLAG_CHAT && g_bAccessColor[iClient][CHAT])
		AddMenuItem(hMenu, "Chat", strBuffer);
	else
		AddMenuItem(hMenu, "", strBuffer, ITEMDRAW_DISABLED);

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public MenuHandler_Settings(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Select)
	{
		decl String:strBuffer[32];
		GetMenuItem(hMenu, iParam2, strBuffer, sizeof(strBuffer));

		if(StrEqual(strBuffer, "Tag"))
			Menu_TagColor(iParam1);
		else if(StrEqual(strBuffer, "Name"))
			Menu_NameColor(iParam1);
		else if(StrEqual(strBuffer, "Chat"))
			Menu_ChatColor(iParam1);
	}
}

public Menu_TagColor(iClient)
{
	if(IsVoteInProgress())
		return;

	new Handle:hMenu = CreateMenu(MenuHandler_TagColor);
	SetMenuTitle(hMenu, "%T:", "TagColor", iClient);
	SetMenuExitBackButton(hMenu, true);

	decl String:strBuffer[32];
	if(g_bCvarHideTags && g_bAccessHideTags[iClient])
	{
		if(!g_bHideTag[iClient])
		{
			Format(strBuffer, sizeof(strBuffer), "%T", "HideTag", iClient);
			AddMenuItem(hMenu, "HideTag", strBuffer);
		}
		else
		{
			Format(strBuffer, sizeof(strBuffer), "%T", "ShowTag", iClient);
			AddMenuItem(hMenu, "HideTag", strBuffer);
		}
	}

	Format(strBuffer, sizeof(strBuffer), "%T", "Reset", iClient);
	AddMenuItem(hMenu, "Reset", strBuffer);

	decl String:strColorIndex[4];
	for(new i = 0; i < g_iColorCount; i++)
	{
		if(!g_bColorAdminFlags[i] || (g_bColorAdminFlags[i] && HasAdminFlag(iClient, g_iColorFlagList[i])))
		{
			IntToString(i, strColorIndex, sizeof(strColorIndex));
			AddMenuItem(hMenu, strColorIndex, g_strColorName[i]);
		}
	}

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public MenuHandler_TagColor(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Cancel && iParam2 == MenuCancel_ExitBack)
	{
		Menu_Settings(iParam1);
		return;
	}

	if(iAction == MenuAction_Select)
	{
		decl String:strBuffer[32];
		GetMenuItem(hMenu, iParam2, strBuffer, sizeof(strBuffer));

		if(StrEqual(strBuffer, "HideTag"))
		{
			if(g_bHideTag[iParam1])
			{
				g_bHideTag[iParam1] = false;
				PrintToChat(iParam1, "[SM] %T", "TagEnabled", iParam1);
			}
			else
			{
				g_bHideTag[iParam1] = true;
				PrintToChat(iParam1, "[SM] %T", "TagDisabled", iParam1);
			}

			if(g_hSQL != INVALID_HANDLE && IsClientAuthorized(iParam1))
			{
				decl String:strQuery[256];
				Format(strQuery, sizeof(strQuery), "SELECT hidetag FROM cccm_users WHERE auth = '%s'", g_strAuth[iParam1]);
				SQL_TQuery(g_hSQL, SQLQuery_HideTag, strQuery, GetClientUserId(iParam1), DBPrio_High);
			}
		}
		else
		{
			if(StrEqual(strBuffer, "Reset"))
			{
				PrintToChat(iParam1, "[SM] %T", "TagReset", iParam1);
				strcopy(g_strColor[iParam1][TAG], sizeof(g_strColor[][]), "");
				CCC_ResetColor(iParam1, CCC_TagColor);

				decl String:strTag[32];
				IntToString(CCC_GetColor(iParam1, CCC_TagColor), strTag, sizeof(strTag));
				strcopy(g_strColor[iParam1][TAG], sizeof(g_strColor[][]), strTag);
			}
			else
			{
				new iColorIndex = StringToInt(strBuffer);
				PrintToChat(iParam1, "\x01[SM] %T \x07%s%s\x01", "TagSet", iParam1, g_strColorHex[iColorIndex], g_strColorName[iColorIndex]);
				strcopy(g_strColor[iParam1][TAG], sizeof(g_strColor[][]), g_strColorHex[iColorIndex]);
				CCC_SetColor(iParam1, CCC_TagColor, StringToInt(g_strColorHex[iColorIndex], 16), false);
			}

			if(g_hSQL != INVALID_HANDLE && IsClientAuthorized(iParam1))
			{
				decl String:strQuery[256];
				Format(strQuery, sizeof(strQuery), "SELECT tagcolor FROM cccm_users WHERE auth = '%s'", g_strAuth[iParam1]);
				SQL_TQuery(g_hSQL, SQLQuery_TagColor, strQuery, GetClientUserId(iParam1), DBPrio_High);
			}
		}

		Menu_Settings(iParam1);
	}
}

public Menu_NameColor(iClient)
{
	if(IsVoteInProgress())
		return;

	new Handle:hMenu = CreateMenu(MenuHandler_NameColor);
	SetMenuTitle(hMenu, "%T:", "NameColor", iClient);
	SetMenuExitBackButton(hMenu, true);

	decl String:strBuffer[32];
	Format(strBuffer, sizeof(strBuffer), "%T", "Reset", iClient);
	AddMenuItem(hMenu, "Reset", strBuffer);

	decl String:strColorIndex[4];
	for(new i = 0; i < g_iColorCount; i++)
	{
		if(!g_bColorAdminFlags[i] || (g_bColorAdminFlags[i] && HasAdminFlag(iClient, g_iColorFlagList[i])))
		{
			IntToString(i, strColorIndex, sizeof(strColorIndex));
			AddMenuItem(hMenu, strColorIndex, g_strColorName[i]);
		}
	}

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public MenuHandler_NameColor(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Cancel && iParam2 == MenuCancel_ExitBack)
	{
		Menu_Settings(iParam1);
		return;
	}

	if(iAction == MenuAction_Select)
	{
		decl String:strBuffer[32];
		GetMenuItem(hMenu, iParam2, strBuffer, sizeof(strBuffer));

		if(StrEqual(strBuffer, "Reset"))
		{
			PrintToChat(iParam1, "[SM] %T", "NameReset", iParam1);
			strcopy(g_strColor[iParam1][NAME], sizeof(g_strColor[][]), "");
			CCC_ResetColor(iParam1, CCC_NameColor);
		}
		else
		{
			new iColorIndex = StringToInt(strBuffer);
			PrintToChat(iParam1, "\x01[SM] %T \x07%s%s\x01", "NameSet", iParam1, g_strColorHex[iColorIndex], g_strColorName[iColorIndex]);
			strcopy(g_strColor[iParam1][NAME], sizeof(g_strColor[][]), g_strColorHex[iColorIndex]);
			CCC_SetColor(iParam1, CCC_NameColor, StringToInt(g_strColorHex[iColorIndex], 16), false);
		}

		if(g_hSQL != INVALID_HANDLE && IsClientAuthorized(iParam1))
		{
			decl String:strQuery[256];
			Format(strQuery, sizeof(strQuery), "SELECT namecolor FROM cccm_users WHERE auth = '%s'", g_strAuth[iParam1]);
			SQL_TQuery(g_hSQL, SQLQuery_NameColor, strQuery, GetClientUserId(iParam1), DBPrio_High);
		}

		Menu_Settings(iParam1);
	}
}

public Menu_ChatColor(iClient)
{
	if(IsVoteInProgress())
		return;

	new Handle:hMenu = CreateMenu(MenuHandler_ChatColor);
	SetMenuTitle(hMenu, "%T:", "ChatColor", iClient);
	SetMenuExitBackButton(hMenu, true);

	decl String:strBuffer[32];
	Format(strBuffer, sizeof(strBuffer), "%T", "Reset", iClient);
	AddMenuItem(hMenu, "Reset", strBuffer);

	decl String:strColorIndex[4];
	for(new i = 0; i < g_iColorCount; i++)
	{
		if(!g_bColorAdminFlags[i] || (g_bColorAdminFlags[i] && HasAdminFlag(iClient, g_iColorFlagList[i])))
		{
			IntToString(i, strColorIndex, sizeof(strColorIndex));
			AddMenuItem(hMenu, strColorIndex, g_strColorName[i]);
		}
	}

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public MenuHandler_ChatColor(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Cancel && iParam2 == MenuCancel_ExitBack)
	{
		Menu_Settings(iParam1);
		return;
	}

	if(iAction == MenuAction_Select)
	{
		decl String:strBuffer[32];
		GetMenuItem(hMenu, iParam2, strBuffer, sizeof(strBuffer));

		if(StrEqual(strBuffer, "Reset"))
		{
			PrintToChat(iParam1, "[SM] %T", "ChatReset", iParam1);
			strcopy(g_strColor[iParam1][CHAT], sizeof(g_strColor[][]), "");
			CCC_ResetColor(iParam1, CCC_ChatColor);
		}
		else
		{
			new iColorIndex = StringToInt(strBuffer);
			PrintToChat(iParam1, "\x01[SM] %T \x07%s%s\x01", "ChatSet", iParam1, g_strColorHex[iColorIndex], g_strColorName[iColorIndex]);
			strcopy(g_strColor[iParam1][CHAT], sizeof(g_strColor[][]), g_strColorHex[iColorIndex]);
			CCC_SetColor(iParam1, CCC_ChatColor, StringToInt(g_strColorHex[iColorIndex], 16), false);
		}

		if(g_hSQL != INVALID_HANDLE && IsClientAuthorized(iParam1))
		{
			decl String:strQuery[256];
			Format(strQuery, sizeof(strQuery), "SELECT chatcolor FROM cccm_users WHERE auth = '%s'", g_strAuth[iParam1]);
			SQL_TQuery(g_hSQL, SQLQuery_ChatColor, strQuery, GetClientUserId(iParam1), DBPrio_High);
		}

		Menu_Settings(iParam1);
	}
}

// ====[ CONFIGURATION ]=======================================================
public Config_Load()
{
	if(!FileExists(g_strConfigFile))
	{
		SetFailState("Configuration file %s not found!", g_strConfigFile);
		return;
	}

	new Handle:hKeyValues = CreateKeyValues("CCC Menu Colors");
	if(!FileToKeyValues(hKeyValues, g_strConfigFile))
	{
		SetFailState("Improper structure for configuration file %s!", g_strConfigFile);
		return;
	}

	if(!KvGotoFirstSubKey(hKeyValues))
	{
		SetFailState("Can't find configuration file %s!", g_strConfigFile);
		return;
	}

	for(new i = 0; i < MAX_COLORS; i++)
	{
		strcopy(g_strColorName[i], sizeof(g_strColorName[]), "");
		strcopy(g_strColorHex[i], sizeof(g_strColorHex[]), "");
		strcopy(g_strColorFlags[i], sizeof(g_strColorFlags[]), "");
		g_bColorAdminFlags[i] = false;
		for(new i2 = 0; i2 < 16; i2++)
			g_iColorFlagList[i][i2] = AdminFlag:-1;
	}

	g_iColorCount = 0;
	do
	{
		KvGetString(hKeyValues, "name", g_strColorName[g_iColorCount], sizeof(g_strColorName[]));
		KvGetString(hKeyValues, "hex",	g_strColorHex[g_iColorCount], sizeof(g_strColorHex[]));
		ReplaceString(g_strColorHex[g_iColorCount], sizeof(g_strColorHex[]), "#", "", false);
		KvGetString(hKeyValues, "flags", g_strColorFlags[g_iColorCount], sizeof(g_strColorFlags[]));

		if(!IsValidHex(g_strColorHex[g_iColorCount]))
		{
			LogError("Invalid hexadecimal value for color %s.", g_strColorName[g_iColorCount]);
			strcopy(g_strColorName[g_iColorCount], sizeof(g_strColorName[]), "");
			strcopy(g_strColorHex[g_iColorCount], sizeof(g_strColorHex[]), "");
			strcopy(g_strColorFlags[g_iColorCount], sizeof(g_strColorFlags[]), "");
		}

		if(!StrEqual(g_strColorFlags[g_iColorCount], ""))
		{
			g_bColorAdminFlags[g_iColorCount] = true;
			FlagBitsToArray(ReadFlagString(g_strColorFlags[g_iColorCount]), g_iColorFlagList[g_iColorCount], sizeof(g_iColorFlagList[]));
		}

		g_iColorCount++;
	}
	while(KvGotoNextKey(hKeyValues));
	CloseHandle(hKeyValues);

	LogMessage("Loaded %i colors from configuration file %s.", g_iColorCount, g_strConfigFile);
}

// ====[ SQL QUERIES ]=========================================================
public SQLQuery_Connect(Handle:hOwner, Handle:hQuery, const String:strError[], any:iData)
{
	if(hQuery == INVALID_HANDLE)
		return;

	g_hSQL = hQuery;
	SQL_GetDriverIdent(hOwner, g_strSQLDriver, sizeof(g_strSQLDriver));

	if(StrEqual(g_strSQLDriver, "mysql", false))
	{
		LogMessage("MySQL server configured. Variable saving enabled.");
		SQL_TQuery(g_hSQL, SQLQuery_Update, "CREATE TABLE IF NOT EXISTS cccm_users (id INT(64) NOT NULL AUTO_INCREMENT, auth varchar(32) UNIQUE, hidetag varchar(1), tagcolor varchar(7), namecolor varchar(7), chatcolor varchar(7), PRIMARY KEY (id))", _, DBPrio_High);
	}
	else if(StrEqual(g_strSQLDriver, "sqlite", false))
	{
		LogMessage("SQlite server configured. Variable saving enabled.");
		SQL_TQuery(g_hSQL, SQLQuery_Update, "CREATE TABLE IF NOT EXISTS cccm_users (id INTERGER PRIMARY KEY, auth varchar(32) UNIQUE, hidetag varchar(1), tagcolor varchar(7), namecolor varchar(7), chatcolor varchar(7))", _, DBPrio_High);
	}
	else
	{
		LogMessage("Saved variable server not configured. Variable saving disabled.");
		return;
	}

	for(new i = 1; i <= MaxClients; ++i) if(IsClientInGame(i))
		SQL_LoadColors(i);
}

public SQLQuery_LoadColors(Handle:hOwner, Handle:hQuery, const String:strError[], any:iData)
{
	new iClient = GetClientOfUserId(iData);
	if(!IsValidClient(iClient))
		return;

	if(hOwner == INVALID_HANDLE || hQuery == INVALID_HANDLE)
	{
		LogError("SQL Error: %s", strError);
		return;
	}

	if(SQL_FetchRow(hQuery) && SQL_GetRowCount(hQuery) != 0)
	{
		g_bHideTag[iClient] = bool:SQL_FetchInt(hQuery, 0);

		decl String:strTag[7];
		SQL_FetchString(hQuery, 1, strTag, sizeof(strTag));
		if(IsValidHex(strTag))
		{
			strcopy(g_strColor[iClient][TAG], sizeof(g_strColor[][]), strTag);
			CCC_SetColor(iClient, CCC_TagColor, StringToInt(g_strColor[iClient][TAG], 16), false);
		}
		else if(StrEqual(strTag, "-1"))
			strcopy(g_strColor[iClient][TAG], sizeof(g_strColor[][]), "-1");

		decl String:strName[7];
		SQL_FetchString(hQuery, 2, strName, sizeof(strName));
		if(IsValidHex(strName))
		{
			strcopy(g_strColor[iClient][NAME], sizeof(g_strColor[][]), strName);
			CCC_SetColor(iClient, CCC_NameColor, StringToInt(g_strColor[iClient][NAME], 16), false);
		}

		decl String:strChat[7];
		SQL_FetchString(hQuery, 3, strChat, sizeof(strChat));
		if(IsValidHex(strChat))
		{
			strcopy(g_strColor[iClient][CHAT], sizeof(g_strColor[][]), strChat);
			CCC_SetColor(iClient, CCC_ChatColor, StringToInt(g_strColor[iClient][CHAT], 16), false);
		}

		g_bColorsLoaded[iClient] = true;
	}
}

public SQLQuery_HideTag(Handle:hOwner, Handle:hQuery, const String:strError[], any:iClientId)
{
	new iClient = GetClientOfUserId(iClientId);
	if(!IsValidClient(iClient))
		return;

	if(hOwner == INVALID_HANDLE || hQuery == INVALID_HANDLE)
	{
		LogError("SQL Error: %s", strError);
		return;
	}

	if(SQL_GetRowCount(hQuery) == 0)
	{
		decl String:strQuery[256];
		Format(strQuery, sizeof(strQuery), "INSERT INTO cccm_users (hidetag, auth) VALUES (%i, '%s')", g_bHideTag[iClient], g_strAuth[iClient]);
		SQL_TQuery(g_hSQL, SQLQuery_Update, strQuery, _, DBPrio_High);
	}
	else
	{
		decl String:strQuery[256];
		Format(strQuery, sizeof(strQuery), "UPDATE cccm_users SET hidetag = '%i' WHERE auth = '%s'", g_bHideTag[iClient], g_strAuth[iClient]);
		SQL_TQuery(g_hSQL, SQLQuery_Update, strQuery, _, DBPrio_Normal);
	}
}

public SQLQuery_TagColor(Handle:hOwner, Handle:hQuery, const String:strError[], any:iClientId)
{
	new iClient = GetClientOfUserId(iClientId);
	if(!IsValidClient(iClient))
		return;

	if(hOwner == INVALID_HANDLE || hQuery == INVALID_HANDLE)
	{
		LogError("SQL Error: %s", strError);
		return;
	}

	if(SQL_GetRowCount(hQuery) == 0)
	{
		decl String:strQuery[256];
		Format(strQuery, sizeof(strQuery), "INSERT INTO cccm_users (tagcolor, auth) VALUES ('%s', '%s')", g_strColor[iClient][TAG], g_strAuth[iClient]);
		SQL_TQuery(g_hSQL, SQLQuery_Update, strQuery, _, DBPrio_High);
	}
	else
	{
		decl String:strQuery[256];
		Format(strQuery, sizeof(strQuery), "UPDATE cccm_users SET tagcolor = '%s' WHERE auth = '%s'", g_strColor[iClient][TAG], g_strAuth[iClient]);
		SQL_TQuery(g_hSQL, SQLQuery_Update, strQuery, _, DBPrio_Normal);
	}
}

public SQLQuery_NameColor(Handle:hOwner, Handle:hQuery, const String:strError[], any:iClientId)
{
	new iClient = GetClientOfUserId(iClientId);
	if(!IsValidClient(iClient))
		return;

	if(hOwner == INVALID_HANDLE || hQuery == INVALID_HANDLE)
	{
		LogError("SQL Error: %s", strError);
		return;
	}

	if(SQL_GetRowCount(hQuery) == 0)
	{
		decl String:strQuery[256];
		Format(strQuery, sizeof(strQuery), "INSERT INTO cccm_users (namecolor, auth) VALUES ('%s', '%s')", g_strColor[iClient][NAME], g_strAuth[iClient]);
		SQL_TQuery(g_hSQL, SQLQuery_Update, strQuery, _, DBPrio_High);
	}
	else
	{
		decl String:strQuery[256];
		Format(strQuery, sizeof(strQuery), "UPDATE cccm_users SET namecolor = '%s' WHERE auth = '%s'", g_strColor[iClient][NAME], g_strAuth[iClient]);
		SQL_TQuery(g_hSQL, SQLQuery_Update, strQuery, _, DBPrio_Normal);
	}
}

public SQLQuery_ChatColor(Handle:hOwner, Handle:hQuery, const String:strError[], any:iClientId)
{
	new iClient = GetClientOfUserId(iClientId);
	if(!IsValidClient(iClient))
		return;

	if(hOwner == INVALID_HANDLE || hQuery == INVALID_HANDLE)
	{
		LogError("SQL Error: %s", strError);
		return;
	}

	if(SQL_GetRowCount(hQuery) == 0)
	{
		decl String:strQuery[256];
		Format(strQuery, sizeof(strQuery), "INSERT INTO cccm_users (chatcolor, auth) VALUES ('%s', '%s')", g_strColor[iClient][CHAT], g_strAuth[iClient]);
		SQL_TQuery(g_hSQL, SQLQuery_Update, strQuery, _, DBPrio_High);
	}
	else
	{
		decl String:strQuery[256];
		Format(strQuery, sizeof(strQuery), "UPDATE cccm_users SET chatcolor = '%s' WHERE auth = '%s'", g_strColor[iClient][CHAT], g_strAuth[iClient]);
		SQL_TQuery(g_hSQL, SQLQuery_Update, strQuery, _, DBPrio_Normal);
	}
}

public SQLQuery_Update(Handle:hOwner, Handle:hQuery, const String:strError[], any:iData)
{
	if(hQuery == INVALID_HANDLE)
		LogError("SQL Error: %s", strError);
}

// ====[ STOCKS ]==============================================================
stock bool:IsValidClient(iClient)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	return true;
}

stock bool:IsValidHex(const String:strHex[])
{
	if(strlen(strHex) == 6 && MatchRegex(g_hRegexHex, strHex))
		return true;
	return false;
}

stock bool:HasAdminFlag(iClient, const AdminFlag:iFlagList[16])
{
	new iFlags = GetUserFlagBits(iClient);
	if(iFlags & ADMFLAG_ROOT)
		return true;

	for(new i = 0; i < sizeof(iFlagList); i++)
	{
		if(iFlags & FlagToBit(iFlagList[i]))
			return true;
	}
	return false;
}