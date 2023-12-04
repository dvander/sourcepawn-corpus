#include <sourcemod>
#include <cstrike>
#include <clientprefs>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.00"

Handle g_hPickupCookieT;
Handle g_hPickupCookieCT;
ConVar g_cServerWideForce;
public Plugin myinfo = 
{
	name = "Disable Auto Weapon Pickup",
	author = "20 scrolls",
	description = "This plugin disables auto weapon pickup, and allows users to specify whether they want it on or off.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=312006"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_autopickup", Command_Autopickup);
	g_hPickupCookieT = RegClientCookie("PickupCookieT", "Stores whether the client wants Autopickup or not for Terrorist side.", CookieAccess_Private);
	g_hPickupCookieCT = RegClientCookie("PickupCookieCT", "Stores whether the client wants Autopickup or not for Counter-Terrorist side.", CookieAccess_Private);
	g_cServerWideForce = CreateConVar("dap_serverwide_disable", "0", "Forces disable autopickup server wide.", FCVAR_PROTECTED);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", Event_PrePlayerDeath, EventHookMode_Pre);
}

public Action Command_Autopickup(int client, int args)
{
	if(g_cServerWideForce.IntValue != 1)
	{
		ShowPickupMenu(client);
	}
	
	return Plugin_Handled;
}

public void ShowPickupMenu(int client)
{
	if(AreClientCookiesCached(client))
	{
		char sCookieValue[12];
		GetClientCookie(client, g_hPickupCookieT, sCookieValue, sizeof(sCookieValue));
		
		char sCookieValue2[12];
		GetClientCookie(client, g_hPickupCookieCT, sCookieValue2, sizeof(sCookieValue2));
		
		if(StrEqual(sCookieValue, ""))
		{
			sCookieValue = "Enabled";
			SetClientCookie(client, g_hPickupCookieT, "Enabled");
		}
			
		if(StrEqual(sCookieValue2, ""))
		{
			sCookieValue2 = "Enabled";
			SetClientCookie(client, g_hPickupCookieCT, "Enabled");
		}
			
		Menu menu = new Menu(autopickupmenu_handler);
		char t[64];
		char ct[64];
		Format(t, sizeof(t), "Terrorist: %s", sCookieValue);
		Format(ct, sizeof(ct), "Counter-Terrorist: %s", sCookieValue2);
		menu.AddItem("cttoggle", ct);
		menu.AddItem("terroristtoggle", t);
		menu.ExitButton = true;
		menu.SetTitle("Toggle auto weapon pickup for each team.");
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int autopickupmenu_handler(Menu menu, MenuAction action, int client, int selection)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sBuffer[24];
			menu.GetItem(selection, sBuffer, sizeof(sBuffer));
			
			if(StrEqual(sBuffer, "terroristtoggle"))
			{
				char sCookieValue[12];
				GetClientCookie(client, g_hPickupCookieT, sCookieValue, sizeof(sCookieValue));
				
				if(StrEqual(sCookieValue, "Disabled"))
				{
					SDKUnhook(client, SDKHook_WeaponCanUse, CanUse);
					SetClientCookie(client, g_hPickupCookieT, "Enabled");
				}
					
				else if(StrEqual(sCookieValue, "Enabled"))
				{
					SDKHook(client, SDKHook_WeaponCanUse, CanUse);
					SetClientCookie(client, g_hPickupCookieT, "Disabled");
				}
					
				ShowPickupMenu(client);
				
			}
			else if(StrEqual(sBuffer, "cttoggle"))
			{
				char sCookieValue[12];
				GetClientCookie(client, g_hPickupCookieCT, sCookieValue, sizeof(sCookieValue));
				
				if(StrEqual(sCookieValue, "Disabled"))
				{
					SDKUnhook(client, SDKHook_WeaponCanUse, CanUse);
					SetClientCookie(client, g_hPickupCookieCT, "Enabled");
				}
					
				else if(StrEqual(sCookieValue, "Enabled"))
				{
					SDKHook(client, SDKHook_WeaponCanUse, CanUse);
					SetClientCookie(client, g_hPickupCookieCT, "Disabled");
				}
				ShowPickupMenu(client);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action CanUse(int client, int weapon)
{
	if(g_cServerWideForce.IntValue != 1)
	{
		if(GetClientTeam(client) == CS_TEAM_T)
		{
			char sCookieValue[12];
			GetClientCookie(client, g_hPickupCookieT, sCookieValue, sizeof(sCookieValue));
			
			if(StrEqual(sCookieValue, "Disabled"))
			{
				int pressedbuttons = GetEntProp(client, Prop_Data, "m_afButtonPressed");
				if(pressedbuttons & IN_USE)
					return Plugin_Continue;
				return Plugin_Handled;
			}
		}
		else if(GetClientTeam(client) == CS_TEAM_CT)
		{
			char sCookieValue[12];
			GetClientCookie(client, g_hPickupCookieCT, sCookieValue, sizeof(sCookieValue));
			
			if(StrEqual(sCookieValue, "Disabled"))
			{
				int pressedbuttons = GetEntProp(client, Prop_Data, "m_afButtonPressed");
				if(pressedbuttons & IN_USE)
					return Plugin_Continue;
				return Plugin_Handled;
			}
		}
	}
	else
	{
		int pressedbuttons = GetEntProp(client, Prop_Data, "m_afButtonPressed");
		if(pressedbuttons & IN_USE)
			return Plugin_Continue;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			SDKUnhook(i, SDKHook_WeaponCanUse, CanUse);
			if(AreClientCookiesCached(i))
			{
				CreateTimer(6.0, RoundTimer, EntIndexToEntRef(i));
			}
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		SDKUnhook(i, SDKHook_WeaponCanUse, CanUse);
	}
}

public Action Event_PrePlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	SDKUnhook(client, SDKHook_WeaponCanUse, CanUse);
	CreateTimer(7.0, RoundTimer, EntIndexToEntRef(client));
}

public Action RoundTimer(Handle timer, int clientf)
{
	int client = EntRefToEntIndex(clientf);
	if(IsValidClient(client))
	{
		char sCookieValue[12];
		GetClientCookie(client, g_hPickupCookieT, sCookieValue, sizeof(sCookieValue));
		
		char sCookieValue2[12];
		GetClientCookie(client, g_hPickupCookieCT, sCookieValue2, sizeof(sCookieValue2));
		
		if(StrEqual(sCookieValue, "Disabled") || StrEqual(sCookieValue2, "Disabled"))
			SDKHook(client, SDKHook_WeaponCanUse, CanUse);
	}	
}

public bool IsValidClient(int client)
{
	if (client <= 0)
		return false;
	if (client > MaxClients)
		return false;
	if (!IsClientInGame(client))
		return false;
	if (IsClientSourceTV(client))
		return false;
	if (IsClientReplay(client))
		return false;
	if (IsFakeClient(client))
		return false;
	
	return true;
} 