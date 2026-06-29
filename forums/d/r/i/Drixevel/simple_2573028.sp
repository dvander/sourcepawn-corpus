//Pragma
#pragma semicolon 1
#pragma newdecls required

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>

//Globals
bool g_bNew[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Simple", 
	author = "Keith Warren (Sky Guardian)", 
	description = "Needs work.", 
	version = "1.0.0", 
	url = "https://github.com/SkyGuardian"
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_OnPlayerSpawn);
}

public void OnClientPutInServer(int client)
{
	g_bNew[client] = true;
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsPlayerAlive(client) && g_bNew[client])
	{
		g_bNew[client] = false;
		
		Menu menu = CreateMenu(MenuHandler_Simple);
		SetMenuTitle(menu, "TITLE");
		
		AddMenuItem(menu, "rules", "Rules");
		AddMenuItem(menu, "help", "Help");
		AddMenuItem(menu, "vip", "VIP INFO");
		AddMenuItem(menu, "sms", "SMS SHOP");
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public int MenuHandler_Simple(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[32];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			
			if (StrEqual(sInfo, "rules"))
			{
				Panel panel = CreatePanel();
				DrawPanelItem(panel, "Don't stink.");
				DrawPanelItem(panel, "Don't smell.");
				DrawPanelItem(panel, "Like Tacos.");
				SendPanelToClient(panel, param1, DummyCallback, MENU_TIME_FOREVER);
				delete panel;
			}
			else if (StrEqual(sInfo, "help"))
			{
				Panel panel = CreatePanel();
				DrawPanelText(panel, "You should get some help.");
				SendPanelToClient(panel, param1, DummyCallback, MENU_TIME_FOREVER);
				delete panel;
			}
			else if (StrEqual(sInfo, "vip"))
			{
				Panel panel = CreatePanel();
				DrawPanelText(panel, "BUY OUR GOODS AND SERVICES!");
				SendPanelToClient(panel, param1, DummyCallback, MENU_TIME_FOREVER);
				delete panel;
			}
			else if (StrEqual(sInfo, "sms"))
			{
				FakeClientCommand(param1, "say !sms");
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public int DummyCallback(Menu menu, MenuAction action, int param1, int param2)
{

}