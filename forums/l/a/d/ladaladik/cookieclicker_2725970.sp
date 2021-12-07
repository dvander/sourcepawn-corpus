#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <ezql>


#pragma newdecls required

public Plugin myinfo = 
{
	name = "", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_cookieclicker", command_clicker);
}

public Action command_clicker(int client, int args)
{
	ShowClickerMenu(client);
}

public void ShowClickerMenu(int client)
{
	char tmp[128];
	Menu menu = new Menu(mMenu);
	menu.SetTitle("C.Clicker [BETA]\n-----[%i]-----", L_GetClientValue(client));
	Format(tmp, sizeof(tmp), "CLICK [X%i]\n----------", L_GetClientLevel(client));
	menu.AddItem("click", tmp);
	if (L_GetClientValue(client) >= L_GetClientLevel(client) * 10)
	{
		Format(tmp, sizeof(tmp), "LEVEL UP cost : %i [CAN BUY]", L_GetClientLevel(client) * 10);
		menu.AddItem("lvlup", tmp);
	} else {
		Format(tmp, sizeof(tmp), "LEVEL UP cost : %i [NOT ENOUGH]", L_GetClientLevel(client) * 10);
		menu.AddItem("", tmp, ITEMDRAW_DISABLED);
		menu.AddItem("top", "TOP 10 CLICKERS");
	}
	menu.Display(client, MENU_TIME_FOREVER);
}
public int mMenu(Menu menu, MenuAction mAction, int param1, int param2)
{
	switch (mAction)
	{
		case MenuAction_Select:
		{
			char szItem[32];
			menu.GetItem(param2, szItem, sizeof(szItem));
			
			if (StrEqual(szItem, "click"))
			{
				if (L_GetClientLevel(param1) == 0)
				{
					L_SetClientValue(param1, L_GetClientValue(param1) + 1);
				}
				L_SetClientValue(param1, L_GetClientValue(param1) + L_GetClientLevel(param1) * 1);
				ShowClickerMenu(param1);
			}
			if (StrEqual(szItem, "lvlup"))
			{
				if (L_GetClientValue(param1) >= L_GetClientLevel(param1) * 10)
				{
					L_SetClientLevel(param1, L_GetClientLevel(param1) + 1);
					L_SetClientValue(param1, L_GetClientValue(param1) - ((L_GetClientLevel(param1) * 10) - 10));
				} else {
					PrintToChat(param1, "NEMÁŠ DOSTATEK COOKIES");
				}
				ShowClickerMenu(param1);
			}
			if (StrEqual(szItem, "top"))
			{
				ClientCommand(param1,"sm_topclickers");
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
} 