 //cookie1 =  tag name
//cookie 2 = disabled / enabled
//cookie 3 = animated / not

#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "LaFF"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};

Handle hCookie;
Handle hCookie2;
Handle hCookie3;

bool HasAnimatedTag[MAXPLAYERS + 1];
bool IsSettingTag[MAXPLAYERS + 1] = false;
bool HasTag[MAXPLAYERS + 1];
char g_sTag[MAXPLAYERS + 1][32];
int g_iLastIndex[MAXPLAYERS + 1];

public void OnPluginStart()
{
	CreateTimer(1.0, Timer_UpdateTag, _, TIMER_REPEAT);
	RegConsoleCmd("sm_settag", command_tag);
	RegConsoleCmd("sm_tag", command_tag);
	RegConsoleCmd("sm_showtags", command_show);
	AddCommandListener(Command_Say, "say");
	
	hCookie = RegClientCookie("TestCookie", "Test cookie", CookieAccess_Public);
	hCookie2 = RegClientCookie("TestCookies", "Test cookie", CookieAccess_Public);
	hCookie3 = RegClientCookie("TestCookiess", "Test cookie", CookieAccess_Public);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!AreClientCookiesCached(i))
		{
			continue;
		}
		OnClientCookiesCached(i);
	}
}

void OnClientCookiesCached(int client)
{
	char cookievalue[32];
	GetClientCookie(client, hCookie, cookievalue, sizeof(cookievalue));
	strcopy(g_sTag[client], sizeof(g_sTag), cookievalue);
	
	GetClientCookie(client, hCookie2, cookievalue, sizeof(cookievalue));
	if (StrEqual(cookievalue, "1"))
	{
		HasTag[client] = true;
	} else {
		HasTag[client] = false;
	}
	GetClientCookie(client, hCookie3, cookievalue, sizeof(cookievalue));
	GetClientCookie(client, hCookie2, cookievalue, sizeof(cookievalue));
	if (StrEqual(cookievalue, "1"))
	{
		if (IsVIP(client))
		{
			HasAnimatedTag[client] = true;
		}
	} else {
		HasAnimatedTag[client] = false;
	}
}

public Action command_show(int client, int args)
{
	OpenMenu(client);
}
void OpenMenu(int client)
{
	char txt[128];
	Menu menu = new Menu(mMenu);
	menu.SetTitle("Client tags by LaFF");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))continue;
		if (!IsVIP)continue;
		if (!HasTag[i])continue;
		Format(txt, sizeof(txt), "%N \n  %s", i, g_sTag[i]);
		menu.AddItem("", txt, ITEMDRAW_DISABLED);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}
public Action command_tag(int client, int args)
{
	OpenTagMenu(client);
}
public Action Timer_UpdateTag(Handle timer)
{
	char buffer[32];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !g_sTag[i][0])
		{
			continue;
		}
		if (!HasTag[i])
		{
			CS_SetClientClanTag(i, " ");
			continue;
		}
		if (!HasAnimatedTag[i])
		{
			if (IsVIP(i))
			{
				CS_SetClientClanTag(i, g_sTag[i]);
			}
			continue;
		}
		
		
		strcopy(buffer, g_iLastIndex[i] + 1, g_sTag[i]);
		g_iLastIndex[i] += 1;
		
		CS_SetClientClanTag(i, buffer);
		
		if (g_iLastIndex[i] > strlen(g_sTag[i]))
		{
			g_iLastIndex[i] = 0;
		}
	}
}


public Action Command_Say(int client, const char[] command, int args)
{
	char message[128];
	GetCmdArgString(message, sizeof(message));
	StripQuotes(message);
	if (IsSettingTag[client])
	{
		if (strlen(message) > 30)
		{
			PrintToChat(client, "[\x0BTAG\x01] \x02Too long tag name!");
			IsSettingTag[client] = false;
		} else {
			if (StrEqual(message, "cancel"))
			{
				PrintToChat(client, "[\x0BTAG\x01] Canceled.");
				IsSettingTag[client] = false;
				return Plugin_Handled;
			}
			strcopy(g_sTag[client], sizeof(g_sTag), message);
			PrintToChat(client, "[\x0BTAG\x01] \x01You have set your tag to \x04%s", g_sTag[client]);
			SetClientCookie(client, hCookie, g_sTag[client]);
			IsSettingTag[client] = false;
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		HasTag[i] = false;
		HasAnimatedTag[i] = false;
		g_sTag[i] = " ";
		char cookievalue[32];
		GetClientCookie(i, hCookie, cookievalue, sizeof(cookievalue));
		strcopy(g_sTag[i], sizeof(g_sTag), cookievalue);
		
		GetClientCookie(i, hCookie2, cookievalue, sizeof(cookievalue));
		if (StrEqual(cookievalue, "1"))
		{
			HasTag[i] = true;
		} else {
			HasTag[i] = false;
		}
		GetClientCookie(i, hCookie3, cookievalue, sizeof(cookievalue));
		if (StrEqual(cookievalue, "1"))
		{
			HasAnimatedTag[i] = true;
		} else {
			HasAnimatedTag[i] = false;
		}
	}
}
public void OnClientPutInServer(int client)
{
	HasTag[client] = false;
	HasAnimatedTag[client] = false;
	g_sTag[client] = " ";
	char cookievalue[32];
	GetClientCookie(client, hCookie, cookievalue, sizeof(cookievalue));
	strcopy(g_sTag[client], sizeof(g_sTag), cookievalue);
	
	GetClientCookie(client, hCookie2, cookievalue, sizeof(cookievalue));
	if (StrEqual(cookievalue, "1"))
	{
		HasTag[client] = true;
	} else {
		HasTag[client] = false;
	}
	GetClientCookie(client, hCookie3, cookievalue, sizeof(cookievalue));
	if (StrEqual(cookievalue, "1"))
	{
		HasAnimatedTag[client] = true;
	} else {
		HasAnimatedTag[client] = false;
	}
}

void OpenTagMenu(int client)
{
	char txt[128];
	Menu menu = new Menu(mTagMenu);
	menu.SetTitle("Slide tag by LaFF \nTag settings \n----------");
	Format(txt, sizeof(txt), "Your tag [%s]", g_sTag[client]);
	menu.AddItem("", txt, ITEMDRAW_DISABLED);
	menu.AddItem("", "", ITEMDRAW_SPACER);
	if (HasTag[client])
	{
		Format(txt, sizeof(txt), "Show tag [enabled]");
	} else {
		Format(txt, sizeof(txt), "Show tag [disabled]");
	}
	menu.AddItem("disable", txt);
	if (HasAnimatedTag[client])
	{
		Format(txt, sizeof(txt), "Animated tag [enabled]");
	} else {
		Format(txt, sizeof(txt), "Animated tag [disabled]");
	}
	menu.AddItem("", "", ITEMDRAW_SPACER);
	menu.AddItem("animated", txt, IsVIP(client) ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	Format(txt, sizeof(txt), "new tag (type in chat) \n----------");
	menu.AddItem("new", txt);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int mMenu(Menu menu, MenuAction mAction, int param1, int param2)
{
	switch (mAction)
	{
		case MenuAction_End:
		{
			delete menu;
		}
	}
}
public int mTagMenu(Menu menu, MenuAction mAction, int param1, int param2)
{
	switch (mAction)
	{
		case MenuAction_Select:
		{
			char szItem[32];
			menu.GetItem(param2, szItem, sizeof(szItem));
			if (StrEqual(szItem, "disable"))
			{
				if (!HasTag[param1])
				{
					PrintToChat(param1, "[\x0BTAG\x01] \x01You have \x04enabled \x01your tag");
					CS_SetClientClanTag(param1, g_sTag[param1]);
					HasTag[param1] = true;
					SetClientCookie(param1, hCookie2, "1");
				} else {
					PrintToChat(param1, "[\x0BTAG\x01] \x01You have \x02disabled \x01your tag");
					CS_SetClientClanTag(param1, " ");
					HasTag[param1] = false;
					SetClientCookie(param1, hCookie2, "0");
				}
				OpenTagMenu(param1);
			}
			else if (StrEqual(szItem, "animated"))
			{
				if (!HasAnimatedTag[param1])
				{
					PrintToChat(param1, "[\x0BTAG\x01] You have \x04enabled \x01animated tag");
					HasAnimatedTag[param1] = true;
					SetClientCookie(param1, hCookie3, "1");
				} else {
					PrintToChat(param1, "[\x0BTAG\x01] You have \x02disabled \x01animated tag");
					if (HasTag[param1])
					{
						CS_SetClientClanTag(param1, g_sTag[param1]);
					}
					HasAnimatedTag[param1] = false;
					SetClientCookie(param1, hCookie3, "0");
				}
				OpenTagMenu(param1);
			}
			else if (StrEqual(szItem, "new"))
			{
				PrintToChat(param1, "[\x0BTAG\x01] Select your new tag in chat, type \x02cancel \x01to cancel.");
				IsSettingTag[param1] = true;
				OpenTagMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

stock bool IsVIP(int client)
{
	return CheckCommandAccess(client, "", ADMFLAG_RESERVATION);
}

stock bool IsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client);
} 