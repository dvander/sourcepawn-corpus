#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "SpirT"
#define PLUGIN_VERSION "1.0.0"

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

ConVar g_enabled;
ConVar g_vhealth;
ConVar g_needed_enabled;
int e_enabled;
int e_needed_enabled;
int g_SelectionTimes[MAXPLAYERS+1];
int g_SelectionMax = 1;

#define tag "\x0B [] \x07"

#pragma newdecls required

public Plugin myinfo = 
{
	name = "VIP Gift on Spawn",
	author = PLUGIN_AUTHOR,
	description = "VIP Players when round starts they have a menu with some features!",
	version = PLUGIN_VERSION,
	url = "https://blcm.pt"
};

public void OnPluginStart()
{
	HookEvent("round_start", RoundStart);
	RegAdminCmd("sm_viprespawn", cmd_viprespawn, ADMFLAG_CUSTOM1);
	// EDITABLE ON CONFIG FILE "cfg/sourcemod/plugin.gifmenu.cfg"
	g_enabled = CreateConVar("plugin_enabled", "1.0", "This enables plugin. Values > 1.0 enable. Values < 1.0 disable");
	
	// ONLY FOR CODE
	g_needed_enabled = CreateConVar("needed_enabled_plugin", "1.0", "This is the default value for plugin to work. Check needed values on g_enabled ConVar");
	g_vhealth = CreateConVar("vip_health_menu", "115", "This is the ammount of health that should be added for VIP. If u want another value change the ammount on the menu item (line 63)");
	AutoExecConfig(true, "plugin.giftmenu");
	SpawnMenu();
}

public Action RoundStart(Event event, const char[] sName, bool bDontBroadCast)
{
	int client = 1;
	e_enabled = GetConVarInt(g_enabled);
	e_needed_enabled = GetConVarInt(g_needed_enabled);
	if(e_enabled == e_enabled)
	{
		if(CheckCommandAccess(client, "sm_override_vip", ADMFLAG_CUSTOM1))
		{
			SpawnMenu().Display(client, MENU_TIME_FOREVER);
		}
		else
		{
			PrintToChat(client, "%s You don't have \x03 VIP! \x07 Buy it or contact server owner to give u the flag \x05 'o'", tag);
		}
	}
	else if(e_enabled < e_needed_enabled)
	{
		PrintToChat(client, "%s Plugin \x03 disabled! \x07 Contact server Owner to solve this problem!", tag);
	}
}

public Menu SpawnMenu()
{
	Menu gmenu = new Menu(handler);
	gmenu.SetTitle("[VIP] Gift Menu");
	gmenu.AddItem("1", "15 HP");
	gmenu.AddItem("2", "AK47");
	gmenu.AddItem("3", "AWP");
	gmenu.AddItem("4", "Healshot");
	
	return gmenu;
}

public int handler(Menu gmenu, MenuAction action, int client, int item)
{
	char choice[32];
	gmenu.GetItem(item, choice, sizeof(choice));
	if(action == MenuAction_Select)
	{
		if(StrEqual(choice, "1"))
		{
			SetEntProp(client, Prop_Send, "m_iHealth", g_vhealth.IntValue);
			PrintToChat(client, "%s You received \x03 15 HP", tag);
			delete gmenu;
		}
		else if(StrEqual(choice, "2"))
		{
			GivePlayerItem(client, "weapon_ak47");
			PrintToChat(client, "%s You received \x03 AK47", tag);
			delete gmenu;
		}
		else if(StrEqual(choice, "3"))
		{
			GivePlayerItem(client, "weapon_awp");
			PrintToChat(client, "%s You received \x03 AWP", tag);
			delete gmenu;
		}
		else if(StrEqual(choice, "4"))
		{
			GivePlayerItem(client, "weapon_healthshot");
			PrintToChat(client, "%s You received \x03 Healthshot", tag);
			delete gmenu;
		}
	}
}

public Action cmd_viprespawn(int client, int args)
{
	g_SelectionTimes[client]++;
	if (g_SelectionTimes[client] > g_SelectionMax)
	{
		PrintToChat(client, "%s You can't respawn more on this round!", tag);
	}
	else if(g_SelectionTimes[client] < g_SelectionMax)
	{
		CS_RespawnPlayer(client);
		PrintToChat(client, "%s RESPAWNED!", tag);
	}
}