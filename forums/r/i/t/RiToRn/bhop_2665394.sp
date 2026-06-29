#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "RiToRn"
#define PLUGIN_VERSION "1.0"

EngineVersion g_Game;

ConVar cPrefix;
char g_szTag[64];

bool bBhopEnabled = false;

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
    name = "[CS:GO] Bhop Menu",
    author = PLUGIN_AUTHOR,
    description = "",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    g_Game = GetEngineVersion();
    if (g_Game != Engine_CSGO)
    {
        SetFailState("This plugin is for CSGO only.");
    }
    
    RegAdminCmd("sm_bhop", Cmd_Bhop, ADMFLAG_CONFIG);
    
    cPrefix = CreateConVar("bhop_prefix", "[Bhop]");
    CreateConVar("bhop_version", PLUGIN_VERSION);
    
    AutoExecConfig(true, "sm_bhop");
}

public void OnConfigsExecuted()
{
	cPrefix.GetString(g_szTag, sizeof(g_szTag));
}

public Action Cmd_Bhop(int client, int args)
{
	Menu menu = new Menu(MenuCallBack);
	
	menu.SetTitle("[Bhop] Enable/Disable");
	if (bBhopEnabled == false)
	{
		menu.AddItem("on", "Enable");
		menu.AddItem("off", "Disable", ITEMDRAW_DISABLED);
	}
	else
	{
		menu.AddItem("on", "Enable", ITEMDRAW_DISABLED);
		menu.AddItem("off", "Disable");
	}
	
	menu.ExitButton = true;
   	menu.Display(client, MENU_TIME_FOREVER);
   	
   	return Plugin_Handled;
}


public int MenuCallBack(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{	
		char Item[32];
		char name[32];
		GetClientName(param1, name, sizeof(name));		
		menu.GetItem(param2, Item, sizeof(Item));
		
		if (StrEqual(Item, "on"))
		{	
			SetConVarInt(FindConVar("sv_enablebunnyhopping"), !GetConVarBool(FindConVar("sv_enablebunnyhopping")));
			SetConVarInt(FindConVar("sv_autobunnyhopping"), !GetConVarBool(FindConVar("sv_autobunnyhopping")));
			PrintToChatAll(" \x05%s\x01 \x06%s\x01 enabled \x04Bhop!", g_szTag, name);
			bBhopEnabled = true;
		}
		
		else if (StrEqual(Item, "off"))
		{
			SetConVarInt(FindConVar("sv_enablebunnyhopping"), !GetConVarBool(FindConVar("sv_enablebunnyhopping")));
			SetConVarInt(FindConVar("sv_autobunnyhopping"), !GetConVarBool(FindConVar("sv_autobunnyhopping")));
			PrintToChatAll(" \x05%s\x01 \x06%s\x01 disabled \x04Bhop!", g_szTag, name);
			bBhopEnabled = false;
		}
	}
	
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}