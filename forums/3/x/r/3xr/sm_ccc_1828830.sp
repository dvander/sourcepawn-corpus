#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <regex>
#include <scp>
#include <ccc>

#define PLUGIN_VERSION "1.0.0 Beta"

enum
{
	Tag = 0,
	Name,
	Chat,
	EnumSize
};

new bool:g_Colorized[MAXPLAYERS +1][EnumSize];
new bool:g_Changing[MAXPLAYERS +1][EnumSize];

new String:g_TagColor[MAXPLAYERS + 1][12];
new String:g_NameColor[MAXPLAYERS + 1][12];
new String:g_ChatColor[MAXPLAYERS + 1][12];

new Handle:cvarEnabled;
new Handle:cvarTag;
new Handle:cvarName;
new Handle:cvarChat;

new Handle:g_hCookieTag;
new Handle:g_hCookieName;
new Handle:g_hCookieChat;

new Handle:HexValues;

public Plugin:myinfo =
{
	name = "Custom Chat Colors Menu",
	author = "ReFlexPoison",
	description = "Select custom chat color settings via menu",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_cccm_version", PLUGIN_VERSION, "Chat Colors Version", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	cvarEnabled = CreateConVar("sm_cccm_enabled", "1", "Enable Custom Chat Colors Settings Menu\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarTag = CreateConVar("sm_cccm_tag", "1", "Enable custom colors for tags", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarName = CreateConVar("sm_cccm_name", "1", "Enable custom colors for name", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarChat = CreateConVar("sm_cccm_chat", "1", "Enable custom colors for chat", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	AutoExecConfig(true, "plugin.cccm");

	g_hCookieTag = RegClientCookie("cccm_tag", "", CookieAccess_Private);
	g_hCookieName = RegClientCookie("cccm_name", "", CookieAccess_Private);
	g_hCookieChat = RegClientCookie("cccm_chat", "", CookieAccess_Private);

	RegAdminCmd("sm_ccc", Command_Color, 0, "Enables color chat");

	AddCommandListener(Say, "say");
	AddCommandListener(Say, "say_team");

	LoadTranslations("core.phrases");
	LoadTranslations("cccm.phrases");

	HexValues = CompileRegex("([A-Fa-f0-9]{6})");
}

public OnClientConnected(client)
{
	if(!IsValidClient(client)) return;

	DisableAllChatSettings(client, false);
	g_Changing[client][Tag] = false;
	g_Changing[client][Name] = false;
	g_Changing[client][Chat] = false;

	if(!AreClientCookiesCached(client)) return;

	new String:cookie[12];

	GetClientCookie(client, g_hCookieTag, cookie, sizeof(cookie));
	if(!StrEqual(cookie, ""))
	{
		g_TagColor[client] = cookie;
		g_Colorized[client][Tag] = true;
	}

	GetClientCookie(client, g_hCookieName, cookie, sizeof(cookie));
	if(!StrEqual(cookie, ""))
	{
		g_NameColor[client] = cookie;
		g_Colorized[client][Name] = true;
	}

	GetClientCookie(client, g_hCookieChat, cookie, sizeof(cookie));
	if(!StrEqual(cookie, ""))
	{
		g_ChatColor[client] = cookie;
		g_Colorized[client][Chat] = true;
	}
}

public Action:OnChatMessage(&client, Handle:recipients, String:name[], String:message[])
{
	if(!GetConVarBool(cvarEnabled) || !IsValidClient(client) || !IsUserDesignated(client)) return Plugin_Continue;
	
	if(GetConVarBool(cvarName) && g_Colorized[client][Name]) Format(name, MAXLENGTH_NAME, "\x07%s%s", g_NameColor[client], name);
	if(GetConVarBool(cvarTag) && g_Colorized[client][Tag])
	{
		new String:c_Tag[64];
		new String:c_Name[64];

		CCC_GetTag(client, c_Tag, sizeof(c_Tag));
		CCC_GetNameColor(client, c_Name, sizeof(c_Name));

		new String:s[64];
		new String:i[64];

		if(GetConVarBool(cvarName)) Format(i, sizeof(i), "\x07%s", g_NameColor[client]);
		else CCC_GetNameColor(client, i, sizeof(i));

		if(g_Colorized[client][Name]) Format(s, sizeof(s), "%s%s", i, name);
		else Format(s, sizeof(s), "%s%s", c_Name, name);

		Format(name, MAXLENGTH_NAME, "\x07%s%s%s", g_TagColor[client], c_Tag, s);
	}
	if(GetConVarBool(cvarChat) && g_Colorized[client][Chat])
	{
		new String:final[MAXLENGTH_MESSAGE];
		Format(final, sizeof(final), "\x07%s%s", g_ChatColor[client], message);
		strcopy(message, MAXLENGTH_MESSAGE, final);
	}
	return Plugin_Changed;
}

public Action:OnTagApplied(client)
{
	if(GetConVarBool(cvarEnabled) && GetConVarBool(cvarTag) && IsValidClient(client) && IsUserDesignated(client) && g_Colorized[client][Tag]) return Plugin_Handled;
	return Plugin_Continue;
}

public Action:Command_Color(client, args)
{
	if(!GetConVarBool(cvarEnabled) || !IsValidClient(client) || !IsUserDesignated(client)) return Plugin_Continue;

	ColorMenu(client);
	return Plugin_Handled;
}

public ColorMenu(client)
{
	if(!GetConVarBool(cvarEnabled) || !IsValidClient(client) || !IsUserDesignated(client) || IsVoteInProgress()) return;

	new Handle:g_Panel = CreatePanel();

	new String:s[64];

	Format(s, sizeof(s), "%t", "Title");
	SetPanelTitle(g_Panel, s);

	DrawPanelText(g_Panel, " ");
	Format(s, sizeof(s), "%t", "ResetAll");
	DrawPanelItem(g_Panel, s);
	DrawPanelText(g_Panel, " ");

	if(g_Colorized[client][Tag]) Format(s, sizeof(s), "%t (%t: %s)", "Tag", "Current", g_TagColor[client]);
	else Format(s, sizeof(s), "%t (%t: %t)", "Tag", "Current", "Disabled");
	if(GetConVarBool(cvarTag)) DrawPanelItem(g_Panel, s);
	else DrawPanelItem(g_Panel, s, ITEMDRAW_DISABLED);

	if(g_Colorized[client][Name]) Format(s, sizeof(s), "%t (%t: %s)", "Name", "Current", g_NameColor[client]);
	else Format(s, sizeof(s), "%t (%t: %t)", "Name", "Current", "Disabled");
	if(GetConVarBool(cvarName)) DrawPanelItem(g_Panel, s);
	else DrawPanelItem(g_Panel, s, ITEMDRAW_DISABLED);

	if(g_Colorized[client][Chat]) Format(s, sizeof(s), "%t (%t: %s)", "Chat", "Current", g_ChatColor[client]);
	else Format(s, sizeof(s), "%t (%t: %t)", "Chat", "Current", "Disabled");
	if(GetConVarBool(cvarChat)) DrawPanelItem(g_Panel, s);
	else DrawPanelItem(g_Panel, s, ITEMDRAW_DISABLED);
	DrawPanelText(g_Panel, " ");
	Format(s, sizeof(s), "%t", "ValidHex");
	DrawPanelItem(g_Panel, s);

	DrawPanelText(g_Panel, " ");
	Format(s, sizeof(s), "%t", "Exit");
	DrawPanelItem(g_Panel, s);

	SendPanelToClient(g_Panel, client, ColorCallback, 60);
	CloseHandle(g_Panel);
}

public ColorCallback(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 1)
		{
			DisableAllChatSettings(param1, true);
			PrintToChat(param1, "[SM] %t", "ResetCom");
		}
		if(param2 == 2) TagMenu(param1);
		if(param2 == 3) NameMenu(param1);
		if(param2 == 4) ChatMenu(param1);
		if(param2 == 5) HexMenu(param1);
		if(param2 == 6) return;
	}
}

public TagMenu(client)
{
	if(!GetConVarBool(cvarEnabled) || !IsValidClient(client) || !IsUserDesignated(client) || IsVoteInProgress()) return;

	new Handle:g_Panel = CreatePanel();

	new String:s[64];

	if(g_Colorized[client][Tag]) Format(s, sizeof(s), "%t\n%t: %s", "TagSettings", "Current", g_TagColor[client]);
	else Format(s, sizeof(s), "%t\n%t: %t", "TagSettings", "Current", "Disabled");

	SetPanelTitle(g_Panel, s);
	DrawPanelText(g_Panel, " ");
	Format(s, sizeof(s), "%t", "Disable");
	DrawPanelItem(g_Panel, s);
	Format(s, sizeof(s), "%t", "Change");
	DrawPanelItem(g_Panel, s);
	DrawPanelText(g_Panel, " ");
	Format(s, sizeof(s), "%t", "Back");
	DrawPanelItem(g_Panel, s);
	Format(s, sizeof(s), "%t", "Exit");
	DrawPanelItem(g_Panel, s);

	SendPanelToClient(g_Panel, client, TagCallback, 60);
	CloseHandle(g_Panel);
}

public TagCallback(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 1) DisableTagSettings(param1, true);
		if(param2 == 2)
		{
			PrintToChat(param1, "[SM] %t", "NewHex");
			g_Changing[param1][Tag] = true;
		}
		if(param2 == 3) ColorMenu(param1);
		if(param2 == 4) return;
	}
}

public NameMenu(client)
{
	if(!GetConVarBool(cvarEnabled) || !IsValidClient(client) || !IsUserDesignated(client) || IsVoteInProgress()) return;

	new Handle:g_Panel = CreatePanel();

	new String:s[64];

	if(g_Colorized[client][Name]) Format(s, sizeof(s), "%t\n%t: %s", "NameSettings", "Current", g_NameColor[client]);
	else Format(s, sizeof(s), "%t\n%t: %t", "NameSettings", "Current", "Disabled");

	SetPanelTitle(g_Panel, s);
	DrawPanelText(g_Panel, " ");
	Format(s, sizeof(s), "%t", "Disable");
	DrawPanelItem(g_Panel, s);
	Format(s, sizeof(s), "%t", "Change");
	DrawPanelItem(g_Panel, s);
	DrawPanelText(g_Panel, " ");
	Format(s, sizeof(s), "%t", "Back");
	DrawPanelItem(g_Panel, s);
	Format(s, sizeof(s), "%t", "Exit");
	DrawPanelItem(g_Panel, s);

	SendPanelToClient(g_Panel, client, NameCallback, 60);
	CloseHandle(g_Panel);
}

public NameCallback(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 1) DisableNameSettings(param1, true);
		if(param2 == 2)
		{
			PrintToChat(param1, "[SM] %t", "NewHex");
			g_Changing[param1][Name] = true;
		}
		if(param2 == 3) ColorMenu(param1);
		if(param2 == 4) return;
	}
}

public ChatMenu(client)
{
	if(!GetConVarBool(cvarEnabled) || !IsValidClient(client) || !IsUserDesignated(client) || IsVoteInProgress()) return;

	new Handle:g_Panel = CreatePanel();

	new String:s[64];

	if(g_Colorized[client][Chat]) Format(s, sizeof(s), "%t\n%t: %s", "ChatSettings", "Current", g_ChatColor[client]);
	else Format(s, sizeof(s), "%t\n%t: %t", "NameSettings", "Current", "Disabled");

	SetPanelTitle(g_Panel, s);
	DrawPanelText(g_Panel, " ");
	Format(s, sizeof(s), "%t", "Disable");
	DrawPanelItem(g_Panel, s);
	Format(s, sizeof(s), "%t", "Change");
	DrawPanelItem(g_Panel, s);
	DrawPanelText(g_Panel, " ");
	Format(s, sizeof(s), "%t", "Back");
	DrawPanelItem(g_Panel, s);
	Format(s, sizeof(s), "%t", "Exit");
	DrawPanelItem(g_Panel, s);

	SendPanelToClient(g_Panel, client, ChatCallback, 60);
	CloseHandle(g_Panel);
}

public ChatCallback(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 1) DisableChatSettings(param1, true);
		if(param2 == 2)
		{
			PrintToChat(param1, "[SM] %t", "NewHex");
			g_Changing[param1][Chat] = true;
		}
		if(param2 == 3) ColorMenu(param1);
		if(param2 == 4) return;
	}
}

public HexMenu(client)
{
	if(!GetConVarBool(cvarEnabled) || !IsValidClient(client) || !IsUserDesignated(client) || IsVoteInProgress()) return;

	new Handle:g_Panel = CreatePanel();

	new String:s[64];

	Format(s, sizeof(s), "%t", "ValidHex");
	SetPanelTitle(g_Panel, s);
	DrawPanelText(g_Panel, " ");
	Format(s, sizeof(s), "%t", "HexM1");
	DrawPanelText(g_Panel, s);
	Format(s, sizeof(s), "%t", "HexM2");
	DrawPanelText(g_Panel, s);
	Format(s, sizeof(s), "%t", "HexM3");
	DrawPanelText(g_Panel, s);
	DrawPanelText(g_Panel, " ");
	Format(s, sizeof(s), "%t", "HexM4");
	DrawPanelText(g_Panel, s);
	Format(s, sizeof(s), "%t", "HexM5");
	DrawPanelText(g_Panel, s);
	DrawPanelText(g_Panel, " ");
	Format(s, sizeof(s), "%t", "Back");
	DrawPanelItem(g_Panel, s);
	Format(s, sizeof(s), "%t", "Exit");
	DrawPanelItem(g_Panel, s);

	SendPanelToClient(g_Panel, client, HexCallback, 60);
	CloseHandle(g_Panel);
}

public HexCallback(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 1) ColorMenu(param1);
		if(param2 == 2) return;
	}
}

public Action:Say(client, const String:command[], argc)
{
	if(!GetConVarBool(cvarEnabled) || !IsValidClient(client) || !IsUserDesignated(client)) return Plugin_Continue;

	new String:text[8];
	GetCmdArgString(text, sizeof(text));

	if(g_Changing[client][Tag])
	{
		if(MatchRegex(HexValues, text))
		{
			ReplaceString(text, sizeof(text), "\"", "");
			PrintToChat(client, "[SM] %t %s", "TagSet", text);
			g_TagColor[client] = text;
			g_Colorized[client][Tag] = true;
			SetClientCookie(client, g_hCookieTag, text);
		}
		else PrintToChat(client, "[SM] %t", "InvalidHex");

		g_Changing[client][Tag] = false;
		return Plugin_Handled;
	}

	if(g_Changing[client][Name])
	{
		if(MatchRegex(HexValues, text))
		{
			ReplaceString(text, sizeof(text), "\"", "");
			PrintToChat(client, "[SM] %t %s", "NameSet", text);
			g_NameColor[client] = text;
			g_Colorized[client][Name] = true;
			SetClientCookie(client, g_hCookieName, text);
		}
		else PrintToChat(client, "[SM] %t", "InvalidHex");

		g_Changing[client][Name] = false;
		return Plugin_Handled;
	}

	if(g_Changing[client][Chat])
	{
		if(MatchRegex(HexValues, text))
		{
			ReplaceString(text, sizeof(text), "\"", "");
			PrintToChat(client, "[SM] %t %s", "ChatSet", text);
			g_ChatColor[client] = text;
			g_Colorized[client][Chat] = true;
			SetClientCookie(client, g_hCookieChat, text);
		}
		else PrintToChat(client, "[SM] %t", "InvalidHex");

		g_Changing[client][Chat] = false;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock bool:IsValidClient(client, bool:replay = true)
{
	if(client <= 0 || client > MaxClients || !IsClientInGame(client) ) return false;
	if(replay && (IsClientSourceTV(client) || IsClientReplay(client))) return false;
	return true;
}

stock bool:IsUserDesignated(client)
{
	if(!CheckCommandAccess(client, "sm_ccc", 0)) return false;
	return true;
}

stock DisableTagSettings(client, bool:cookies = false)
{
	g_Colorized[client][Tag] = false;

	g_TagColor[client] = "";

	if(cookies) SetClientCookie(client, g_hCookieTag, "");
}

stock DisableNameSettings(client, bool:cookies = false)
{
	g_Colorized[client][Name] = false;

	g_NameColor[client] = "";

	if(cookies) SetClientCookie(client, g_hCookieName, "");
}

stock DisableChatSettings(client, bool:cookies = false)
{
	g_Colorized[client][Chat] = false;

	g_ChatColor[client] = "";

	if(cookies) SetClientCookie(client, g_hCookieChat, "");
}

stock DisableAllChatSettings(client, bool:cookies = false)
{
	g_Colorized[client][Tag] = false;
	g_Colorized[client][Name] = false;
	g_Colorized[client][Chat] = false;

	g_TagColor[client] = "";
	g_NameColor[client] = "";
	g_ChatColor[client] = "";

	if(cookies)
	{
		SetClientCookie(client, g_hCookieTag, "");
		SetClientCookie(client, g_hCookieName, "");
		SetClientCookie(client, g_hCookieChat, "");
	}
}