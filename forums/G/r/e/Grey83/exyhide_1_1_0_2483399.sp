#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

/*
	exydos.com
	2017.01.03 initial
*/

Menu g_Menu;
Handle g_Cookie;
int g_Setting[MAXPLAYERS+1];

public Plugin myinfo = {
	name		= "eXyHide",
	author		= "eXydos (rewritten by Grey83)",
	description	= "Hides People?",
	version		= "1.1.0",
	url			= "https://forums.alliedmods.net/showthread.php?p=2483270"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_hide", Cmd_Hide);

	g_Cookie = RegClientCookie("ExyHide", "ExyHide", CookieAccess_Protected);

	g_Menu = CreateMenu(OnMenu);
	g_Menu.SetTitle("[ExyHide] Hide:");
	g_Menu.AddItem("0", "Off");
	g_Menu.AddItem("1", "Team");
	g_Menu.AddItem("2", "Enemy");
	g_Menu.AddItem("3", "All");

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			OnClientPutInServer(client);
			if (AreClientCookiesCached(client)) OnClientCookiesCached(client);
		}
	}
}

public void OnClientPutInServer(int client)
{
	g_Setting[client] = 0;
	SDKHook(client, SDKHook_SetTransmit, OnTransmit);
}

public void OnClientCookiesCached(int client)
{
	char sCookieValue[12];
	GetClientCookie(client, g_Cookie, sCookieValue, sizeof(sCookieValue));
	g_Setting[client] = StringToInt(sCookieValue);
}

public int OnMenu(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select) g_Setting[client] = param;

	return 0;
}

public Action OnTransmit(int entity, int client)
{
	if (entity != client && 0 < entity <= MaxClients && g_Setting[client])
	{
		switch(g_Setting[client])
		{
			case 1: if (GetClientTeam(client) == GetClientTeam(entity)) return Plugin_Handled;
			case 2: if (GetClientTeam(client) != GetClientTeam(entity)) return Plugin_Handled;
			case 3: return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action Cmd_Hide(int client, int args)
{
	if (0 < client <= MaxClients)
	{
		if (args)
		{
			char sBuffer[8];
			GetCmdArg(1, sBuffer, sizeof(sBuffer));
	
			if (StrEqual(sBuffer, "off", false))
			{
				g_Setting[client] = 0;
				SetClientCookie(client, g_Cookie, "0");
			}
			else if (StrEqual(sBuffer, "team", false))
			{
				g_Setting[client] = 1;
				SetClientCookie(client, g_Cookie, "1");
			}
			else if (StrEqual(sBuffer, "enemy", false))
			{
				g_Setting[client] = 2;
				SetClientCookie(client, g_Cookie, "2");
			}
			else if (StrEqual(sBuffer, "all", false))
			{
				g_Setting[client] = 3;
				SetClientCookie(client, g_Cookie, "3");
			}
			else DisplayMenu(g_Menu, client, 30);
		}
		else DisplayMenu(g_Menu, client, 30);
	}
	return Plugin_Handled;
}