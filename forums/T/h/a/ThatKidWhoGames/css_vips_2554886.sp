#pragma semicolon 1
#include <sourcemod>
#include <smlib>

bool bVIP[MAXPLAYERS+1];

ConVar cv_Money, cv_Health, cv_Armor;
int iMoney, iHealth, iArmor;

public Plugin myinfo = {
	name        = "[CS:S] VIP Plugin",
	author      = "Sgt. Gremulock",
	description = "VIP Plugin.",
	version     = "1.2",
	url         = "sourcemod.net"
};

public void OnPluginStart()
{
	cv_Money = CreateConVar("sm_cssvip_money", "1600", "Extra money to add on spawn for VIPs.", _, true, 0.0);
	cv_Health = CreateConVar("sm_cssvip_health", "20", "Extra health to add on spawn for VIPs.", _, true, 0.0);
	cv_Armor = CreateConVar("sm_cssvip_armor", "120", "Armor to add on spawn for VIPs.", _, true, 0.0);
	
	iMoney = cv_Money.IntValue;
	iHealth = cv_Health.IntValue;
	iArmor = cv_Armor.IntValue;
	
	cv_Money.AddChangeHook(CvarUpdate);
	cv_Health.AddChangeHook(CvarUpdate);
	cv_Armor.AddChangeHook(CvarUpdate);
	
	AutoExecConfig(true);
	
	RegConsoleCmd("sm_vip", Command_VIP);
	RegConsoleCmd("sm_vips", Command_VIPs);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void CvarUpdate(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iMoney 	= cv_Money.IntValue;
	iHealth = cv_Health.IntValue;
	iArmor 	= cv_Armor.IntValue;
}

public void OnClientPostAdminCheck(int client)
{
	if (CheckCommandAccess(client, "sm_vip", ADMFLAG_CUSTOM1, true))
	{
		bVIP[client] = true;
	}
	else if (!CheckCommandAccess(client, "sm_vip", ADMFLAG_CUSTOM1, true))
	{
		bVIP[client] = false;
	}
}

public Action Command_VIP(int client, int args)
{
	Menu menu = new Menu(MenuVIP, MENU_ACTIONS_ALL);
	menu.SetTitle("VIP Perks:");
	menu.AddItem("money", "Extra money on spawn");
	menu.AddItem("health", "Extra health on spawn");
	menu.AddItem("armor", "Free armor on spawn");
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Action Command_VIPs(int client, int args)
{
	Menu menu = new Menu(MenuVIPs, MENU_ACTIONS_ALL);
	menu.SetTitle("VIPs on the server:");
	
	int iCount;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && CheckCommandAccess(client, "sm_vip", ADMFLAG_CUSTOM1, true))
		{
			char name[MAX_NAME_LENGTH], count[32];
			GetClientName(i, name, sizeof(name));
			IntToString(iCount, count, sizeof(count));
			menu.AddItem(count, name);
			iCount++;
		}
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int MenuVIP(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public int MenuVIPs(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsValidClient(client) && bVIP[client])
	{
		Client_SetMoney(client, Client_GetMoney(client) + iMoney);
		Client_SetArmor(client, Client_GetArmor(client) + iArmor);
		SetEntityHealth(client, GetClientHealth(client) + iHealth);
	}
}

bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || IsFakeClient(client))
	{
		return false;
	}
	
	return IsClientInGame(client);
}