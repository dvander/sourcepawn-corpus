#include <sourcemod>
#include <sdktools>
#include <colors>

new bool:g_Bdenymenu[MAXPLAYERS+1] = false;
new bool:g_Bacceptmenu[MAXPLAYERS+1] = false;
new money[MAXPLAYERS+1];

public Plugin:myinfo =
{
    name	= "*~ Enemy Weapon ~*",
    author	= "*~ Kriax ~*",
    version 	= "1.0",
};

public OnMapStart()
{
	HookEvent("player_spawn", OnPlayerSpawn);
	
	RegConsoleCmd("sm_guns", Cmd_Guns);
	RegConsoleCmd("sm_gun", Cmd_Guns);
}

public OnClientPutInServer(client)
{
	g_Bacceptmenu[client] = false;
	g_Bdenymenu[client] = false;
}

public Action:Cmd_Guns(client, args)
{
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
	{
		g_Bacceptmenu[client] = false;
		g_Bdenymenu[client] = false;
		CPrintToChat(client, "{green}[VIP] {lightgreen}Your menu will display it on-your next respawn");
	}
	else
	{
		CPrintToChat(client, "{green}[VIP] {lightgreen} You do not have access to this command !");
	}
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetClientTeam(client) > 1 && (GetUserFlagBits(client) & ADMFLAG_CUSTOM1))
	{
		Afficher_Menu(client)
	}
}

public Afficher_Menu(client)
{
	if(GetClientTeam(client) > 1)
	{
		if(!g_Bacceptmenu[client] && !g_Bdenymenu[client])
		{
			new Handle:menu = CreateMenu(generalmenu);
			if(GetClientTeam(client) == 2)
			{
				SetMenuTitle(menu, "Do you want a M4A1 ?");
			}
			else if(GetClientTeam(client) == 3)
			{
				SetMenuTitle(menu, "Do you want a Ak47 ?");
			}
			AddMenuItem(menu, "yes", "Yes");
			AddMenuItem(menu, "no", "No");
			AddMenuItem(menu, "ayes", "Always Yes");
			AddMenuItem(menu, "ano", "Always No");
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
		else if(g_Bacceptmenu[client])
		{
			Buy_Weapons(client)
		}
	}
}

public generalmenu(Handle:menu, MenuAction:action, client, param2)
{
	if ( action == MenuAction_Select )
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		if(StrEqual(info, "yes"))
		{
			Buy_Weapons(client);
		}
		if(StrEqual(info, "ayes"))
		{
			Buy_Weapons(client);
			g_Bacceptmenu[client] = true;
		}
		if(StrEqual(info, "ano"))
		{
			g_Bdenymenu[client] = true;
		}
	}
}

public Buy_Weapons(client)
{
	new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
	money[client] = GetEntData(client, MoneyOffset, 4);
	new MoneyBack = GetEntProp(client, Prop_Send, "m_iAccount");

	if(GetClientTeam(client) == 2)
	{
		if (money[client] >= 3100)
		{
			GivePlayerItem(client, "weapon_m4a1");
			SetEntProp(client, Prop_Send, "m_iAccount", MoneyBack - 3100);
		}
		else if (money[client] < 3100)
		{
			CPrintToChat(client, "{green}[VIP] {lightgreen} You do not have enough money to have a M4A1");
		}
	}
	else if(GetClientTeam(client) == 3)
	{	
		if (money[client] >= 2500)
		{
			GivePlayerItem(client, "weapon_ak47");
			SetEntProp(client, Prop_Send, "m_iAccount", MoneyBack - 2500);
		}
		else if (money[client] < 2500)
		{
			CPrintToChat(client, "{green}[VIP] {lightgreen} You do not have enough money to have a AK47");
		}
	}
}