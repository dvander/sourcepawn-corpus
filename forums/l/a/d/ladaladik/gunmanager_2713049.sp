#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "LaFF"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdkhooks>
#include <smlib>
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
Handle tTimer;
bool CanOpen = false;

int WeaponId[MAXPLAYERS + 1];
bool OpenMenu[MAXPLAYERS + 1];
public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart);
	RegConsoleCmd("sm_gunmanager", command_manager);
	for (int i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i))
		OnClientPutInServer(i);
	
	
	hCookie = RegClientCookie("gunmanager", "", CookieAccess_Private);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!AreClientCookiesCached(i))
		{
			continue;
		}
		OnClientCookiesCached(i);
	}
}

public Action timercallback(Handle timer)
{
	CanOpen = true;
	KillTimer(tTimer);
}
public void OnClientCookiesCached(int client)
{
	char CookieValue[32];
	
	GetClientCookie(client, hCookie, CookieValue, sizeof(CookieValue));
	if (StrEqual(CookieValue, "1"))
	{
		OpenMenu[client] = false;
	} else {
		OpenMenu[client] = true;
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponPickup);
}

public Action OnRoundStart(Event event, const char[] name, bool dbc)
{
	tTimer = CreateTimer(5.0, timercallback);
}

public Action OnWeaponPickup(int client, int weapon)
{
	char name[32];
	GetEdictClassname(weapon, name, sizeof(name));
	WeaponId[client] = weapon;
	if (CS_GetWeaponPrice(client, CS_AliasToWeaponID(name), true) > 0)
	{
		if (OpenMenu[client])
		{
			if (CanOpen)
			{
				ShowSellMenu(client, weapon);
			}
		}
	}
	
}
public Action command_manager(int client, int args)
{
	
	Menu menu2 = new Menu(mMenu2);
	menu2.SetTitle("Open menu on gun pickup?");
	if (OpenMenu[client]) {
		menu2.AddItem("yes", "YES [✓]");
		menu2.AddItem("no", "NO [X]");
	} else {
		menu2.AddItem("yes", "YES [X]");
		menu2.AddItem("no", "NO [✓]");
	}
	menu2.Display(client, MENU_TIME_FOREVER);
}
void ShowSellMenu(int client, int weapon)
{
	char txt[128];
	char name[32];
	GetEdictClassname(weapon, name, sizeof(name));
	Menu menu = new Menu(mMenu);
	
	menu.SetTitle("Gun Manager");
	Format(txt, sizeof(txt), "Sell %s for %i", name[7], CS_GetWeaponPrice(client, CS_AliasToWeaponID(name), true));
	menu.AddItem("sell", txt);
	menu.AddItem("", "", ITEMDRAW_SPACER);
	menu.AddItem("", "", ITEMDRAW_SPACER);
	menu.AddItem("", "", ITEMDRAW_SPACER);
	menu.AddItem("settings", "Settings");
	menu.Display(client, MENU_TIME_FOREVER);
	
}
public int mMenu(Menu menu, MenuAction mAction, int param1, int param2)
{
	if (mAction == MenuAction_Select)
	{
		char szItem[32];
		char name[32];
		char activewep[32];
		menu.GetItem(param2, szItem, sizeof(szItem));
		
		if (StrEqual(szItem, "sell"))
		{
			if (IsValidEdict(WeaponId[param1]))
			{
				GetClientWeapon(param1, activewep, sizeof(activewep));
				GetEdictClassname(WeaponId[param1], name, sizeof(name));
				if (CS_AliasToWeaponID(activewep) == CS_AliasToWeaponID(name))
				{
					if (GetEntProp(param1, Prop_Send, "m_iAccount") + CS_GetWeaponPrice(param1, CS_AliasToWeaponID(name), true) <= FindConVar("mp_maxmoney").IntValue)
					{
						SetEntProp(param1, Prop_Send, "m_iAccount", GetEntProp(param1, Prop_Send, "m_iAccount") + CS_GetWeaponPrice(param1, CS_AliasToWeaponID(name), true));
					} else {
						SetEntProp(param1, Prop_Send, "m_iAccount", FindConVar("mp_maxmoney").IntValue);
					}
					RemoveEdict(WeaponId[param1]);
				}
				
			}
		}
	} else if (mAction == MenuAction_End)
	{
		delete menu;
	}
	
}
public int mMenu2(Menu menu2, MenuAction mAction, int param1, int param2)
{
	char szItem[16];
	char cookieval[2];
	if (mAction == MenuAction_Select)
	{
		menu2.GetItem(param2, szItem, sizeof(szItem));
		
		if (StrEqual(szItem, "yes"))
		{
			cookieval = "0";
			OpenMenu[param1] = true;
			SetClientCookie(param1, hCookie, cookieval);
		}
		else if (StrEqual(szItem, "no"))
		{
			cookieval = "1";
			OpenMenu[param1] = false;
			SetClientCookie(param1, hCookie, cookieval);
		}
		else if (StrEqual(szItem, "settings"))
		{
			ClientCommand(param1, "sm_gunmanager");
		}
	} else if (mAction == MenuAction_End)
	{
		delete menu2;
	}
	
} 