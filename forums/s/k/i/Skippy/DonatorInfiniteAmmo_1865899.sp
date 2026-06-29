#include <sourcemod>

new bool:g_bToggle[MAXPLAYERS+1] = false;

public Plugin:myinfo =
{
	name = "Donator Infinite Ammo",
	author = "Skipper",
	description = "Infinite Ammo for Donators",
	version = "1.0",
}; 

public OnPluginStart()
{
	RegAdminCmd("sm_donator", Command_Donator, ADMFLAG_RESERVATION, "Opens Donator Menu")
}

public OnClientPutInServer(client)
{
	g_bToggle[client] = false;
}


public Action:Command_Donator(client, args)
{
	if (client)
	{
		DonatorMenu(client);
	}
	return Plugin_Handled;
}

public Action:DonatorMenu(client)
{
	new Handle:menu = CreateMenu(DonatorMenuCallback);
	
	SetMenuTitle(menu, "Infinite Ammo");
	if (g_bToggle[client] == false)
	{
		AddMenuItem(menu, "on", "Turn On");
	}
	if (g_bToggle[client] == true)
	{
		AddMenuItem(menu, "off", "Turn Off");	
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}	

public DonatorMenuCallback(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End) CloseHandle(menu);
	if (action == MenuAction_Select)
	{
		new String:select[64]
		GetMenuItem(menu, param2, select, sizeof(select));
			
		if (StrEqual(select, "on")) 
		{
			FakeClientCommand(client, "sm_aia");
			g_bToggle[client] = true;
			DonatorMenu(client);
		}	
		if (StrEqual(select, "off"))
		{
			FakeClientCommand(client, "sm_aia");
			g_bToggle[client] = false;
			DonatorMenu(client);
		}	
	}
}	