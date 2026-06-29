#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <clientprefs>

#define PLUGIN_NAME		"Language"
#define PLUGIN_VERSION	"1.0.0"

Handle lang_cookie;
char cLangPref[MAXPLAYERS+1][4];

public Plugin myinfo = 
{
	name		= PLUGIN_NAME,
	author		= "Grey83",
	description	= "Set & Save client language",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?p=2444363"
};

public void OnPluginStart()
{
	CreateConVar("sm_lang_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	LoadTranslations("common.phrases");
	RegConsoleCmd("sm_lang", Cmd_Lang, "Show/set own client language setting\n'sm_lang' - shows current client language\n'sm_lang <code>' - set own client language");

	lang_cookie = RegClientCookie("client_lang", "Saved client language", CookieAccess_Private);
	SetCookieMenuItem(LangMenu, 0, "Language");
}

public void OnClientCookiesCached(int client)
{
	char sPref[4];
	GetClientCookie(client, lang_cookie, sPref, sizeof(sPref));
	cLangPref[client] = sPref;
}

public void OnClientPostAdminCheck(int client)
{
	char code[4];
	GetClientCookie(client, lang_cookie, code, sizeof(code));
	int lang = GetLanguageByCode(code);
	if(lang >= 0)
	{
		SetClientLanguage(client, lang);
//		PrintToServer("%N's language is set to '%s' (%d) ", client, code, lang);
	}
}

public Action Cmd_Lang(int client, int args)
{
	if(client == 0) ReplyToCommand(client, "[SM] %T", "Command is in-game only", client);
	else
	{
		char code[4], name[64];
		if(args == 0)
		{
			int lang = GetClientLanguage(client);
			if(lang >= 0)
			{
				GetLanguageInfo(lang, code, sizeof(code), name, sizeof(name));
				PrintToChat(client, "Your client language is '%s' ('%s', %d)", name, code, lang);
			}
		}
		else
		{
			GetCmdArg(1, code, sizeof(code));
			ChangeLanuage(client, GetLanguageByCode(code));
		}
	}

	return Plugin_Handled;
}

public void LangMenu(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if(action == CookieMenuAction_DisplayOption) Format(buffer, maxlen, "Language: %s", cLangPref[client]);
	else if(action == CookieMenuAction_SelectOption)
	{
		char MenuItem[64];
		Menu langmenu = CreateMenu(LangMenuHandler);
		langmenu.SetTitle("Choose language:");
		int num = GetLanguageCount();
		for (int i; i < num; i++)
		{
			char code[4], name[64];
			GetLanguageInfo(i, code, sizeof(code), name, sizeof(name));
			bool used = StrEqual(cLangPref[client], code, false);
			Format(MenuItem, sizeof(MenuItem), "%s %s", name, used ? "☑" : "");
			langmenu.AddItem(code, MenuItem, used ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}
		if(num < 10) langmenu.Pagination = 0;
		langmenu.ExitButton = true;
		langmenu.Display(client, MENU_TIME_FOREVER);
	}
}

public int LangMenuHandler(Menu langmenu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			langmenu.SetTitle("Language: %s", cLangPref[client]);
		}
		case MenuAction_DisplayItem:
		{
			char buffer[64];
			langmenu.GetItem(item, buffer, sizeof(buffer));
			bool used = StrEqual(buffer, cLangPref[client]);
			Format(buffer, sizeof(buffer), "%s%s", buffer, used ? " ☑" : "");
			return RedrawMenuItem(buffer);
		}
		case MenuAction_Select:
		{
			char code[4];
			GetMenuItem(langmenu, item, code, sizeof(code));
			ChangeLanuage(client, GetLanguageByCode(code));
		}
		case MenuAction_End:
		{
			delete langmenu;
		}
	}
	ShowCookieMenu(client);
	return 0;
}

void ChangeLanuage(int client, int lang)
{
	char code[4], name[64];
	if(lang >= 0)
	{
		GetLanguageInfo(lang, code, sizeof(code), name, sizeof(name));
		SetClientLanguage(client, lang);
		SetClientCookie(client, lang_cookie, code);
		cLangPref[client] = code;
		PrintToChat(client, "Your client language changed to '%s' (%s, %d)", name, code, lang);
	}
	else PrintToChat(client, "Wrong lanuage code!");
}