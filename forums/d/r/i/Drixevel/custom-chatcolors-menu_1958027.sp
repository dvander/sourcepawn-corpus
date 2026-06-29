#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <clientprefs>
#include <regex>
#define REQUIRE_PLUGIN
#include <scp>
#include <ccc>
#undef REQUIRE_PLUGIN

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION		"1.3.0"
#define CONFIG				"configs/custom-chatcolors-menu.cfg"
#define dTag				(1 << 0)
#define dName				(1 << 1)
#define dChat				(1 << 2)

// ====[ HANDLES | CVARS ]=====================================================
new Handle:cvarEnabled;
new Handle:cvarUseConfig;
new Handle:cvarHideTags;
new Handle:g_hCookieTag;
new Handle:g_hCookieName;
new Handle:g_hCookieChat;
new Handle:g_hCookieHideTag;
new Handle:g_hRegexHex;

// ====[ VARIABLES ]===========================================================
enum
{
	iTag,
	iName,
	iChat,
};

new g_iEnabled;
new bool:g_bUseConfig;
new bool:g_bHideTags;
new bool:g_bHideTag			[MAXPLAYERS + 1];
new bool:g_bColorized		[MAXPLAYERS + 1][3];
new bool:g_bChanging		[MAXPLAYERS + 1][3];
new String:g_strColor		[MAXPLAYERS + 1][3][12];

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Custom Chat Colors Menu",
	author = "ReFlexPoison",
	description = "Change CCC settings via menu",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

//Custom Chat Colors: https://forums.alliedmods.net/showthread.php?t=186695
//Simple Chat Processor: https://forums.alliedmods.net/showthread.php?t=198501

// ====[ FUNCTIONS ]===========================================================
public OnPluginStart()
{
	CreateConVar("sm_cccm_version", PLUGIN_VERSION, "CCC Menu Version", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	cvarEnabled = CreateConVar("sm_cccm_enabled", "7", "Enable CCC Menu (Add up the numbers to choose)\n0 = Disabled\n1 = Tag\n2 = Name\n4 = Chat", FCVAR_PLUGIN, true, 0.0, true, 7.0);
	cvarUseConfig = CreateConVar("sm_cccm_useconfig", "1", "Enable use of config file. Use this if you want players to only use specifc color values in their chat messages\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarHideTags = CreateConVar("sm_cccm_hidetags", "1", "Allow hiding of chat tags\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	g_iEnabled = GetConVarInt(cvarEnabled);
	g_bUseConfig = GetConVarBool(cvarUseConfig);
	g_bHideTags = GetConVarBool(cvarHideTags);

	HookConVarChange(cvarEnabled, CVarChange);
	HookConVarChange(cvarUseConfig, CVarChange);
	HookConVarChange(cvarHideTags, CVarChange);

	AutoExecConfig(true, "plugin.custom-chatcolors-menu");

	g_hCookieTag = RegClientCookie("cccm_tag", "", CookieAccess_Private);
	g_hCookieName = RegClientCookie("cccm_name", "", CookieAccess_Private);
	g_hCookieChat = RegClientCookie("cccm_chat", "", CookieAccess_Private);
	g_hCookieHideTag = RegClientCookie("cccm_hidetag", "", CookieAccess_Private);

	RegAdminCmd("sm_ccc", CCCCmd, 0, "Open CCC Menu");

	AddCommandListener(SayCmd, "say");
	AddCommandListener(SayCmd, "say_team");

	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("custom-chatcolors-menu.phrases");

	g_hRegexHex = CompileRegex("([A-Fa-f0-9]{6})");
}

public CVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == cvarEnabled)
	{
		g_iEnabled = GetConVarInt(cvarEnabled);
		for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
		{
			if(!(g_iEnabled & dTag))
				DisableTagSettings(i);
			if(!(g_iEnabled & dName))
				DisableNameSettings(i);
			if(!(g_iEnabled & dChat))
				DisableChatSettings(i);
			for(new z = 0 ; z <= 2 ; z++)
				g_bChanging[i][z] = false;
		}
	}
	if(hConvar == cvarUseConfig)
	{
		decl String:strPath[64];
		Format(strPath, sizeof(strPath), "addons/sourcemod/%s", CONFIG);
		if(StrEqual(strNewValue, "1") && !FileExists(strPath))
		{
			PrintToServer("Config: %s not found!", CONFIG);
			SetConVarBool(cvarUseConfig, false);
		}
		g_bUseConfig = GetConVarBool(cvarUseConfig);
		for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
		{
			for(new z = 0; z <= 2 ; z++)
				g_bChanging[i][z] = false;
		}
	}
	if(hConvar == cvarHideTags)
		g_bHideTags = GetConVarBool(cvarHideTags);
}

public OnConfigsExecuted()
{
	decl String:strPath[64];
	Format(strPath, sizeof(strPath), "addons/sourcemod/%s", CONFIG);
	if(!FileExists(strPath))
	{
		PrintToServer("Config: %s not found!", CONFIG);
		SetConVarBool(cvarUseConfig, false);
		g_bUseConfig = GetConVarBool(cvarUseConfig);
	}
}

public OnClientPostAdminCheck(iClient)
{
	DisableAllChatSettings(iClient, false);
	g_bHideTag[iClient] = false;
	for(new i = 0 ; i <= 2 ; i++)
		g_bChanging[iClient][i] = false;

	if(IsValidClient(iClient) && AreClientCookiesCached(iClient))
		LoadClientCookies(iClient);
	else
		CreateTimer(1.0, Timer_LoadCookies, iClient, TIMER_REPEAT);
}

public Action:CCC_OnTagApplied(iClient)
{
	if(g_iEnabled >= 0 && g_bHideTags && g_bHideTag[iClient])
		return Plugin_Handled;
	return Plugin_Continue;
}

// ====[ TIMERS ]==============================================================
public Action:Timer_LoadCookies(Handle:hTimer, any:iClient)
{
	if(!IsValidClient(iClient) || !AreClientCookiesCached(iClient))
		return Plugin_Continue;

	LoadClientCookies(iClient);
	return Plugin_Stop;
}

// ====[ COMMANDS ]============================================================
public Action:CCCCmd(iClient, iArgs)
{
	if(iClient == 0)
	{
		SetGlobalTransTarget(iClient);
		ReplyToCommand(iClient, "%t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(g_iEnabled <= 0 || !IsValidClient(iClient))
		return Plugin_Continue;

	ColorMenu(iClient);
	return Plugin_Handled;
}

public Action:SayCmd(iClient, const String:strCommand[], iArgs)
{
	if(g_iEnabled <= 0 || !IsValidClient(iClient) || !IsUserDesignated(iClient))
		return Plugin_Continue;

	decl String:strText[8];
	GetCmdArgString(strText, sizeof(strText));

	SetGlobalTransTarget(iClient);
	if((g_bChanging[iClient][iTag] || g_bChanging[iClient][iName] || g_bChanging[iClient][iChat]) && !IsValidHex(strText))
	{
		PrintToChat(iClient, "[SM] %t", "InvalidHex");
		for(new i = 0; i <= 2; i++)
			g_bChanging[iClient][i] = false;
		return Plugin_Handled;
	}

	if(g_bChanging[iClient][iTag])
	{
		ReplaceString(strText, sizeof(strText), "\"", "");
		PrintToChat(iClient, "[SM] %t #%s", "TagSet", strText);

		strcopy(g_strColor[iClient][iTag], 8, strText);
		g_bColorized[iClient][iTag] = true;
		CCC_SetColor(iClient, CCC_TagColor, StringToInt(g_strColor[iClient][iTag], 16), false);

		SetClientCookie(iClient, g_hCookieTag, strText);
		g_bChanging[iClient][iTag] = false;
		return Plugin_Handled;
	}

	if(g_bChanging[iClient][iName])
	{
		ReplaceString(strText, sizeof(strText), "\"", "");
		PrintToChat(iClient, "[SM] %t #%s", "NameSet", strText);

		strcopy(g_strColor[iClient][iName], 8, strText);
		g_bColorized[iClient][iName] = true;
		CCC_SetColor(iClient, CCC_NameColor, StringToInt(g_strColor[iClient][iName], 16), false);

		SetClientCookie(iClient, g_hCookieName, strText);
		g_bChanging[iClient][iName] = false;
		return Plugin_Handled;
	}

	if(g_bChanging[iClient][iChat])
	{
		ReplaceString(strText, sizeof(strText), "\"", "");
		PrintToChat(iClient, "[SM] %t #%s", "ChatSet", strText);

		strcopy(g_strColor[iClient][iChat], 8, strText);
		g_bColorized[iClient][iChat] = true;
		CCC_SetColor(iClient, CCC_ChatColor, StringToInt(g_strColor[iClient][iChat], 16), false);

		SetClientCookie(iClient, g_hCookieChat, strText);
		g_bChanging[iClient][iChat] = false;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

// ====[ MENUS ]===============================================================
public ColorMenu(iClient)
{
	if(g_iEnabled <= 0 || !IsValidClient(iClient) || !IsUserDesignated(iClient))
		return;

	new Handle:hMenu = CreateMenu(ColorCallback);

	SetGlobalTransTarget(iClient);
	SetMenuTitle(hMenu, "%t:", "Title");

	decl String:strInfo[64];
	Format(strInfo, sizeof(strInfo), "%t", "ResetAll");
	AddMenuItem(hMenu, "Reset", strInfo);

	AddMenuItem(hMenu, "", " ", ITEMDRAW_SPACER);

	Format(strInfo, sizeof(strInfo), "%t", "Tag");
	if(g_iEnabled & dTag)
		AddMenuItem(hMenu, "Tag", strInfo);
	else
		AddMenuItem(hMenu, "", strInfo, ITEMDRAW_DISABLED);

	Format(strInfo, sizeof(strInfo), "%t", "Name");
	if(g_iEnabled & dName)
		AddMenuItem(hMenu, "Name", strInfo);
	else
		AddMenuItem(hMenu, "", strInfo, ITEMDRAW_DISABLED);

	Format(strInfo, sizeof(strInfo), "%t", "Chat");
	if(g_iEnabled & dChat)
		AddMenuItem(hMenu, "Chat", strInfo);
	else
		AddMenuItem(hMenu, "", strInfo, ITEMDRAW_DISABLED);

	if(!g_bUseConfig)
	{
		AddMenuItem(hMenu, "", " ", ITEMDRAW_SPACER);
		Format(strInfo, sizeof(strInfo), "%t", "ValidHex");
		AddMenuItem(hMenu, "Hex", strInfo);
	}

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public ColorCallback(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
		CloseHandle(hMenu);
	if(iAction == MenuAction_Select)
	{
		decl String:strInfo[64];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));
		if(StrEqual(strInfo, "Reset"))
		{
			DisableAllChatSettings(iParam1, true);
			SetGlobalTransTarget(iParam1);
			PrintToChat(iParam1, "[SM] %t", "ResetCom");
		}
		if(StrEqual(strInfo, "Tag"))
			TagMenu(iParam1);
		if(StrEqual(strInfo, "Name"))
			NameMenu(iParam1);
		if(StrEqual(strInfo, "Chat"))
			ChatMenu(iParam1);
		if(StrEqual(strInfo, "Hex"))
			HexMenu(iParam1);
	}
}

public TagMenu(iClient)
{
	if(g_iEnabled <= 0 || !(g_iEnabled & dTag) || !IsValidClient(iClient) || !IsUserDesignated(iClient) || IsVoteInProgress() || CheckCommandAccess(iClient, "CCCTagFlag", ADMFLAG_ROOT))
		return;

	new Handle:hMenu = CreateMenu(TagCallback);
	SetMenuExitBackButton(hMenu, true);

	SetGlobalTransTarget(iClient);
	if(g_bColorized[iClient][iTag])
		SetMenuTitle(hMenu, "%t\n%t: %s", "TagSettings", "Current", g_strColor[iClient][iTag]);
	else
		SetMenuTitle(hMenu, "%t\n%t: %t", "TagSettings", "Current", "Disabled");

	AddMenuItem(hMenu, "", " ", ITEMDRAW_SPACER);

	decl String:strInfo[64];
	if(g_bHideTags)
	{
		if(g_bHideTag[iClient])
			Format(strInfo, sizeof(strInfo), "%t", "Show");
		else
			Format(strInfo, sizeof(strInfo), "%t", "Hide");
		AddMenuItem(hMenu, "Hide", strInfo);
	}

	Format(strInfo, sizeof(strInfo), "%t", "Disable");
	AddMenuItem(hMenu, "Disable", strInfo);

	Format(strInfo, sizeof(strInfo), "%t", "Change");
	AddMenuItem(hMenu, "Change", strInfo);

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public TagCallback(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
		CloseHandle(hMenu);
	if(iAction == MenuAction_Cancel && iParam2 == MenuCancel_ExitBack)
		ColorMenu(iParam1);
	if(g_iEnabled & dTag && iAction == MenuAction_Select)
	{
		decl String:strInfo[64];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));
		SetGlobalTransTarget(iParam1);
		if(StrEqual(strInfo, "Hide"))
		{
			if(g_bHideTag[iParam1])
			{
				g_bHideTag[iParam1] = false;
				PrintToChat(iParam1, "[SM] %t", "Visible");
				SetClientCookie(iParam1, g_hCookieHideTag, "0");
			}
			else
			{
				g_bHideTag[iParam1] = true;
				PrintToChat(iParam1, "[SM] %t", "Hidden");
				SetClientCookie(iParam1, g_hCookieHideTag, "1");
			}
			ColorMenu(iParam1);
		}
		if(StrEqual(strInfo, "Disable"))
		{
			DisableTagSettings(iParam1, true);
			PrintToChat(iParam1, "[SM] %t", "ResetComTag");
			ColorMenu(iParam1);
		}
		if(StrEqual(strInfo, "Change"))
		{
			if(g_bUseConfig)
				ColorConfigMenu(iParam1, iTag);
			else
			{
				PrintToChat(iParam1, "[SM] %t", "NewHex");
				g_bChanging[iParam1][iTag] = true;
			}
		}
	}
}

public NameMenu(iClient)
{
	if(g_iEnabled <= 0 || !(g_iEnabled & dName)|| !IsValidClient(iClient) || !IsUserDesignated(iClient) || IsVoteInProgress())
		return;

	new Handle:hMenu = CreateMenu(NameCallback);
	SetMenuExitBackButton(hMenu, true);

	SetGlobalTransTarget(iClient);
	if(g_bColorized[iClient][iName])
		SetMenuTitle(hMenu, "%t\n%t: %s", "NameSettings", "Current", g_strColor[iClient][iName]);
	else
		SetMenuTitle(hMenu, "%t\n%t: %t", "NameSettings", "Current", "Disabled");

	AddMenuItem(hMenu, "", " ", ITEMDRAW_SPACER);

	decl String:strInfo[64];
	Format(strInfo, sizeof(strInfo), "%t", "Disable");
	AddMenuItem(hMenu, "Disable", strInfo);

	Format(strInfo, sizeof(strInfo), "%t", "Change");
	AddMenuItem(hMenu, "Change", strInfo);

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public NameCallback(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
		CloseHandle(hMenu);
	if(iAction == MenuAction_Cancel && iParam2 == MenuCancel_ExitBack)
		ColorMenu(iParam1);
	if(g_iEnabled & dName && iAction == MenuAction_Select)
	{
		decl String:strInfo[64];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));
		SetGlobalTransTarget(iParam1);
		if(StrEqual(strInfo, "Disable"))
		{
			DisableNameSettings(iParam1, true);
			PrintToChat(iParam1, "[SM] %t", "ResetComName");
			ColorMenu(iParam1);
		}
		if(StrEqual(strInfo, "Change"))
		{
			if(g_bUseConfig)
				ColorConfigMenu(iParam1, iName);
			else
			{
				PrintToChat(iParam1, "[SM] %t", "NewHex");
				g_bChanging[iParam1][iName] = true;
			}
		}
	}
}

public ChatMenu(iClient)
{
	if(g_iEnabled <= 0 || !(g_iEnabled & dChat) || !IsValidClient(iClient) || !IsUserDesignated(iClient) || IsVoteInProgress())
		return;

	new Handle:hMenu = CreateMenu(ChatCallback);
	SetMenuExitBackButton(hMenu, true);

	SetGlobalTransTarget(iClient);
	if(g_bColorized[iClient][iChat])
		SetMenuTitle(hMenu, "%t\n%t: %s", "ChatSettings", "Current", g_strColor[iClient][iChat]);
	else
		SetMenuTitle(hMenu, "%t\n%t: %t", "ChatSettings", "Current", "Disabled");

	AddMenuItem(hMenu, "", " ", ITEMDRAW_SPACER);

	decl String:strInfo[64];
	Format(strInfo, sizeof(strInfo), "%t", "Disable");
	AddMenuItem(hMenu, "Disable", strInfo);

	Format(strInfo, sizeof(strInfo), "%t", "Change");
	AddMenuItem(hMenu, "Change", strInfo);

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public ChatCallback(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
		CloseHandle(hMenu);
	if(iAction == MenuAction_Cancel && iParam2 == MenuCancel_ExitBack)
		ColorMenu(iParam1);
	if(g_iEnabled & dChat && iAction == MenuAction_Select)
	{
		decl String:strInfo[64];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));
		SetGlobalTransTarget(iParam1);
		if(StrEqual(strInfo, "Disable"))
		{
			DisableChatSettings(iParam1, true);
			PrintToChat(iParam1, "[SM] %t", "ResetComChat");
			ColorMenu(iParam1);
		}
		if(StrEqual(strInfo, "Change"))
		{
			if(g_bUseConfig)
				ColorConfigMenu(iParam1, iChat);
			else
			{
				PrintToChat(iParam1, "[SM] %t", "NewHex");
				g_bChanging[iParam1][iChat] = true;
			}
		}
	}
}

public ColorConfigMenu(iClient, iMenuID)
{
	if(g_iEnabled <= 0 || !IsValidClient(iClient) || !IsUserDesignated(iClient) || IsVoteInProgress())
		return;

	new Handle:hMenu;
	SetGlobalTransTarget(iClient);
	switch(iMenuID)
	{
		case 0:
		{
			if(g_iEnabled & dChat)
			{
				hMenu = CreateMenu(TagColorMenuH);
				SetMenuTitle(hMenu, "%t:", "TagColor");
			}
		}
		case 1:
		{
			if(g_iEnabled & dName)
			{
				hMenu = CreateMenu(NameColorMenuH);
				SetMenuTitle(hMenu, "%t:", "NameColor");
			}
		}
		case 2:
		{
			if(g_iEnabled & dChat)
			{
				hMenu = CreateMenu(ChatColorMenuH);
				SetMenuTitle(hMenu, "%t:", "ChatColor");
			}
		}
	}
	if(hMenu == INVALID_HANDLE)
	{
		CloseHandle(hMenu);
		return;
	}
	SetMenuExitBackButton(hMenu, true);

	decl String:strLocation[64];
	BuildPath(Path_SM, strLocation, sizeof(strLocation), CONFIG);

	new Handle:hKv = CreateKeyValues("CCC Menu Colors");
	FileToKeyValues(hKv, strLocation);

	if(!KvGotoFirstSubKey(hKv))
	{
		CloseHandle(hMenu);
		SetFailState("Can't find config file %s!", strLocation);
		return;
	}

	decl String:strName[32];
	decl String:strHex[12];
	decl String:strFlags[16];
	do
	{
		KvGetString(hKv, "name", strName, sizeof(strName));
		KvGetString(hKv, "hex",	strHex, sizeof(strHex));
		KvGetString(hKv, "flags", strFlags, sizeof(strFlags), "none");

		new AdminFlag:iFlagList[16];
		new bool:bFlags = (!StrEqual(strFlags, "none") && !StrEqual(strFlags, ""));
		if(bFlags)
			FlagBitsToArray(ReadFlagString(strFlags), iFlagList, sizeof(iFlagList));

		ReplaceString(strHex, sizeof(strHex), "#", "", false);
		if(IsValidHex(strHex) && strlen(strHex) == 6)
		{
			if(bFlags)
			{
				if(HasAdminFlag(iClient, iFlagList))
					AddMenuItem(hMenu, strHex, strName);
			}
			else
				AddMenuItem(hMenu, strHex, strName);
		}
	}
	while(KvGotoNextKey(hKv));
	CloseHandle(hKv);

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public TagColorMenuH(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
		CloseHandle(hMenu);
	if(iAction == MenuAction_Cancel && iParam2 == MenuCancel_ExitBack)
		ColorMenu(iParam1);
	if(g_iEnabled & dTag && IsValidClient(iParam1) && iAction == MenuAction_Select)
	{
		decl String:strInfo[16];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));
		strcopy(g_strColor[iParam1][iTag], 7, strInfo);
		g_bColorized[iParam1][iTag] = true;

		SetGlobalTransTarget(iParam1);
		PrintToChat(iParam1, "[SM] %t #%s", "TagSet", strInfo);
		SetClientCookie(iParam1, g_hCookieTag, g_strColor[iParam1][iTag]);
		CCC_SetColor(iParam1, CCC_TagColor, StringToInt(strInfo, 16), false);

		ColorMenu(iParam1);
	}
}

public NameColorMenuH(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
		CloseHandle(hMenu);
	if(iAction == MenuAction_Cancel && iParam2 == MenuCancel_ExitBack)
		ColorMenu(iParam1);
	if(g_iEnabled & dName && IsValidClient(iParam1) && iAction == MenuAction_Select)
	{
		decl String:strInfo[16];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));
		strcopy(g_strColor[iParam1][iName], 7, strInfo);
		g_bColorized[iParam1][iName] = true;

		SetGlobalTransTarget(iParam1);
		PrintToChat(iParam1, "[SM] %t #%s", "NameSet", strInfo);
		SetClientCookie(iParam1, g_hCookieName, g_strColor[iParam1][iName]);
		CCC_SetColor(iParam1, CCC_NameColor, StringToInt(strInfo, 16), false);

		ColorMenu(iParam1);
	}
}

public ChatColorMenuH(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
		CloseHandle(hMenu);
	if(iAction == MenuAction_Cancel && iParam2 == MenuCancel_ExitBack)
		ColorMenu(iParam1);
	if(g_iEnabled & dChat && IsValidClient(iParam1) && iAction == MenuAction_Select)
	{
		decl String:strInfo[16];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));
		strcopy(g_strColor[iParam1][iChat], 7, strInfo);
		g_bColorized[iParam1][iChat] = true;

		SetGlobalTransTarget(iParam1);
		PrintToChat(iParam1, "[SM] %t #%s", "ChatSet", strInfo);
		SetClientCookie(iParam1, g_hCookieChat, g_strColor[iParam1][iChat]);
		CCC_SetColor(iParam1, CCC_ChatColor, StringToInt(strInfo, 16), false);

		ColorMenu(iParam1);
	}
}

public HexMenu(iClient)
{
	if(g_iEnabled <= 0 || !IsValidClient(iClient) || !IsUserDesignated(iClient) || IsVoteInProgress())
		return;

	new Handle:hMenu = CreateMenu(HexCallback);
	SetGlobalTransTarget(iClient);
	SetMenuTitle(hMenu, "%t", "ValidHex");
	SetMenuExitBackButton(hMenu, true);

	AddMenuItem(hMenu, "", " ", ITEMDRAW_SPACER);

	decl String:strInfo[64];
	Format(strInfo, sizeof(strInfo), "%t", "HexM1");
	AddMenuItem(hMenu, "1", strInfo, ITEMDRAW_DISABLED);

	Format(strInfo, sizeof(strInfo), "%t", "HexM2");
	AddMenuItem(hMenu, "2", strInfo, ITEMDRAW_DISABLED);

	Format(strInfo, sizeof(strInfo), "%t", "HexM3");
	AddMenuItem(hMenu, "3", strInfo, ITEMDRAW_DISABLED);

	AddMenuItem(hMenu, "", " ", ITEMDRAW_SPACER);

	Format(strInfo, sizeof(strInfo), "%t", "HexM4");
	AddMenuItem(hMenu, "4", strInfo, ITEMDRAW_DISABLED);

	Format(strInfo, sizeof(strInfo), "%t", "HexM5");
	AddMenuItem(hMenu, "5", strInfo, ITEMDRAW_DISABLED);

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public HexCallback(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
		CloseHandle(hMenu);
	if(iAction == MenuAction_Cancel && iParam2 == MenuCancel_ExitBack)
		ColorMenu(iParam1);
}

// ====[ STOCKS ]==============================================================
stock bool:IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}

stock bool:IsUserDesignated(iClient)
{
	if(!CheckCommandAccess(iClient, "sm_ccc", 0))
		return false;
	return true;
}

stock bool:IsValidHex(const String:strHex[])
{
	if(MatchRegex(g_hRegexHex, strHex))
		return true;
	return false;
}

stock bool:HasAdminFlag(iClient, AdminFlag:iFlagList[16])
{
	new iFlags = GetUserFlagBits(iClient);
	if(iFlags & ADMFLAG_ROOT)
		return true;
	else
	{
		for(new i = 0; i < sizeof(iFlagList); i++)
		{
			if(iFlags & FlagToBit(iFlagList[i]))
				return true;
		}
		return false;
	}
}

stock LoadClientCookies(iClient)
{
	if(!IsUserDesignated(iClient))
		return;

	decl String:strCookie[12];
	GetClientCookie(iClient, g_hCookieTag, strCookie, sizeof(strCookie));
	if(IsValidHex(strCookie) && g_iEnabled & dTag)
	{
		strcopy(g_strColor[iClient][iTag], 7, strCookie);
		g_bColorized[iClient][iTag] = true;
		CCC_SetColor(iClient, CCC_TagColor, StringToInt(strCookie, 16), false);
	}

	GetClientCookie(iClient, g_hCookieName, strCookie, sizeof(strCookie));
	if(IsValidHex(strCookie) && g_iEnabled & dName)
	{
		strcopy(g_strColor[iClient][iName], 7, strCookie);
		g_bColorized[iClient][iName] = true;
		CCC_SetColor(iClient, CCC_NameColor, StringToInt(strCookie, 16), false);
	}

	GetClientCookie(iClient, g_hCookieChat, strCookie, sizeof(strCookie));
	if(IsValidHex(strCookie) && g_iEnabled & dChat)
	{
		strcopy(g_strColor[iClient][iChat], 7, strCookie);
		g_bColorized[iClient][iChat] = true;
		CCC_SetColor(iClient, CCC_ChatColor, StringToInt(strCookie, 16), false);
	}

	GetClientCookie(iClient, g_hCookieHideTag, strCookie, sizeof(strCookie));
	if(StrEqual(strCookie, "1"))
		g_bHideTag[iClient] = true;
}

stock DisableTagSettings(iClient, bool:bCookies = false)
{
	strcopy("", 0, g_strColor[iClient][iTag]);
	g_bColorized[iClient][iTag] = false;

	CCC_ResetColor(iClient, CCC_TagColor);

	if(bCookies)
		SetClientCookie(iClient, g_hCookieTag, "");
}

stock DisableNameSettings(iClient, bool:bCookies = false)
{
	strcopy("", 0, g_strColor[iClient][iName]);
	g_bColorized[iClient][iName] = false;

	CCC_ResetColor(iClient, CCC_NameColor);

	if(bCookies)
		SetClientCookie(iClient, g_hCookieName, "");
}

stock DisableChatSettings(iClient, bool:bCookies = false)
{
	strcopy("", 0, g_strColor[iClient][iChat]);
	g_bColorized[iClient][iChat] = false;

	CCC_ResetColor(iClient, CCC_ChatColor);

	if(bCookies)
		SetClientCookie(iClient, g_hCookieChat, "");
}

stock DisableAllChatSettings(iClient, bool:bCookies = false)
{
	for(new i = 0; i <= 2 ; i++)
	{
		strcopy("", 0, g_strColor[iClient][i]);
		g_bColorized[iClient][i] = false;
	}

	CCC_ResetColor(iClient, CCC_TagColor);
	CCC_ResetColor(iClient, CCC_NameColor);
	CCC_ResetColor(iClient, CCC_ChatColor);

	if(bCookies)
	{
		SetClientCookie(iClient, g_hCookieTag, "");
		SetClientCookie(iClient, g_hCookieName, "");
		SetClientCookie(iClient, g_hCookieChat, "");
	}
}