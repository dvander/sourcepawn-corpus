#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "JPLAYS"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <multicolors>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Free Deagle", 
	author = PLUGIN_AUTHOR, 
	description = "Free Deagle for VIPS", 
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/id/jplayss"
};

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart);
	LoadTranslations("freedeagle.phrases");
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (CheckCommandAccess(client, "VIP", ADMFLAG_RESERVATION))
	{
		ShowMenu(client);
	}
}

void ShowMenu(int client)
{
	Menu menu = new Menu(Menu_Handler);
	menu.SetTitle("Receber Deagle ?");
	menu.AddItem("sim", "Sim");
	menu.AddItem("nao", "Não");
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Handler(Menu menu, MenuAction action, int client, int args)
{
	if (action == MenuAction_Select)
	{
		char selectedItem[200];
		menu.GetItem(args, selectedItem, sizeof(selectedItem));
		if (StrEqual(selectedItem, "sim"))
		{
			EquipPlayerWeapon(client, "weapon_deagle");
			CPrintToChat(client, "%t %t", "Prefix", "Receive free deagle");
		}
		else
		{
			CPrintToChat(client, "%t %t", "Prefix", "Don't Receive");
		}
	}
}

