#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <clientprefs>
#pragma newdecls required
#pragma semicolon 1

Handle g_hGDPRCookie;
Handle g_iTimer[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "SimpleGDPRCompliance",
	author = "Sarrus",
	description = "A simple plugin to comply to the GDPR",
	version = "1.0",
	url = "https://github.com/Sarrus1/"
};
 
public void OnPluginStart()
{
	LoadTranslations("SimpleGDPRCompliance.phrases");
	g_hGDPRCookie = RegClientCookie("GDPRCookie", "Remember client GDPR preferences.", CookieAccess_Protected);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	char sCookieValue[12];
	GetClientCookie(client, g_hGDPRCookie, sCookieValue, sizeof(sCookieValue));
	int cookieValue = StringToInt(sCookieValue);
	if (cookieValue != 1)
	{
		delete g_iTimer[client];
		GDPRMenu(client, 0);
	}
}

public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
  switch(action)
  {
    case MenuAction_Select:
    {
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "#accept"))
		{
			SetClientCookie(param1, g_hGDPRCookie, "1");
		}
		else if(StrEqual(info, "#refuse"))
		{
			SetClientCookie(param1, g_hGDPRCookie, "0");
			KickClient(param1, "You must accept the GDPR conditions to use this server");
		}
		delete menu;
    }
  }
  return 0;
}

public Action GDPRMenu(int client, int args)
{
	Menu menu = new Menu(MenuHandler, MenuAction_Select);
	char sContent[256];
	Format(sContent, sizeof(sContent), "%t", "Content");
	menu.SetTitle("%t", "Title", LANG_SERVER);
	menu.AddItem("#accept", "Accept");
	menu.AddItem("#refuse", "Refuse");
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
  delete g_iTimer[client];
}