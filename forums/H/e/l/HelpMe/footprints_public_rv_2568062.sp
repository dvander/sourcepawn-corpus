#pragma semicolon 1

#pragma newdecls required

#define DEBUG

#define PLUGIN_AUTHOR "Oshizu + Dyl0n + Pelipoika + Benjamin"
#define PLUGIN_VERSION "1.16"

Handle g_hCookie;
Handle g_hCookieRandom;
float g_fFootPrintID[MAXPLAYERS + 1] = 0.0;
bool g_bRandom[MAXPLAYERS + 1] = false;

#include <tf2attributes>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <morecolors>
#include <tf2>
#include <tf2_stocks>

public Plugin myinfo = 
{
	name = "[TF2] Halloween Footprints with clientprefs (Revisited)",
	author = PLUGIN_AUTHOR,
	description = "Looks Fancy Ahhhh",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_footprints", FootSteps, ADMFLAG_GENERIC);
	RegAdminCmd("sm_footsteps", FootSteps, ADMFLAG_GENERIC);

	g_hCookie = RegClientCookie("footprints", "", CookieAccess_Private);
	g_hCookieRandom = RegClientCookie("footprintsRandom", "Footprints", CookieAccess_Private);
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bRandom[i] = false;
		if (!AreClientCookiesCached(i))
        {
			continue;
        }
		LoadClientCookies(i);
		LoadClientRandomCookie(i);
	}
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		g_bRandom[i] = false;
		if (!AreClientCookiesCached(i))
        {
			continue;
        }
		LoadClientCookies(i);
		LoadClientRandomCookie(i);
	}
}

public void OnClientDisconnect(int client)
{
	if(g_fFootPrintID[client] > 0.0)
	{
		g_fFootPrintID[client] = 0.0;
	}
	UnHook(client);
}

public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_fFootPrintID[client] > 0.0)
	{
		TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", g_fFootPrintID[client]);
	}
}

public Action FootSteps(int client, int args)
{
	Menu menu = new Menu(Footprint_Selected);
	SetMenuTitle(menu, "Spawn Nobuild Area:");

	AddMenuItem(menu, "0", "No Effect");
	AddMenuItem(menu, "X", "----------", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "1", "Team Based");
	AddMenuItem(menu, "7777", "Blue");
	AddMenuItem(menu, "933333", "Light Blue");
	AddMenuItem(menu, "8421376", "Yellow");
	AddMenuItem(menu, "4552221", "Corrupted Green");
	AddMenuItem(menu, "3100495", "Dark Green");
	AddMenuItem(menu, "51234123", "Lime");
	AddMenuItem(menu, "5322826", "Brown");
	AddMenuItem(menu, "8355220", "Oak Tree Brown");
	AddMenuItem(menu, "13595446", "Flames");
	AddMenuItem(menu, "8208497", "Cream");
	AddMenuItem(menu, "41234123", "Pink");
	AddMenuItem(menu, "300000", "Satan's Blue");
	AddMenuItem(menu, "2", "Purple");
	AddMenuItem(menu, "3", "4 8 15 16 23 42");
	AddMenuItem(menu, "83552", "Ghost In The Machine");
	AddMenuItem(menu, "9335510", "Holy Flame");
	AddMenuItem(menu, "0", "[Random]");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int Footprint_Selected(Menu menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_End) CloseHandle(menu);

	if(action == MenuAction_Select)
	{
		char s_Menu_Item_Number[12];
		GetMenuItem(menu, param2, s_Menu_Item_Number, sizeof(s_Menu_Item_Number)); //Fetches the value of the selected item.
		
		float f_Menu_Item_Number = StringToFloat(s_Menu_Item_Number); //The string is turned into a float.
		g_fFootPrintID[client] = f_Menu_Item_Number;
		
		if(f_Menu_Item_Number == 0.0)
		{
			TF2Attrib_RemoveByName(client, "SPELL: set Halloween footstep type");
			SetClientCookie(client, g_hCookie, s_Menu_Item_Number);
			UnHook(client);
		}
		else
		{
			TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", f_Menu_Item_Number);
			SetClientCookie(client, g_hCookie, s_Menu_Item_Number);
		}
		if(param2 == 19)
		{
			if(CheckCommandAccess(client, "sm_footprints_random", ADMFLAG_GENERIC))
			{
				SetClientRandomCookie(client, true);
				AddHook(client);
			}
			else
			{
				SetClientRandomCookie(client, false);
				CPrintToChat(client, "{blueviolet}[SM] {default}You do not have access to this option");
			}
		}
		else
		{
			SetClientRandomCookie(client, false);
			UnHook(client);
		}
	}
}

public void OnClientPutInServer(int client)
{
	CreateTimer(10.0, LoadCookies, client);
        //Ignore if it wasn't a valid client (rare).
	if(!IsClientInGame(client) && IsFakeClient(client))
		return;
}

public void OnPostThink(int client)
{
	/*if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
	{
		TF2Attrib_RemoveByName(client, "SPELL: set Halloween footstep type");
	}
	else
	{
		if(g_bRandom[client] == false && g_fFootPrintID[client] != 0.0)
		{
			TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", g_fFootPrintID[client]);
		}
	}*/
	if(g_bRandom[client] == true /*&& !TF2_IsPlayerInCondition(client, TFCond_Cloaked)*/)
	{
		if(CheckCommandAccess(client, "sm_footprints_random", ADMFLAG_GENERIC))
		{
			switch(GetRandomInt(0,16))
			{
				case 0:
					TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 1.0);
				case 1:
					TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 7777.0);
				case 2:
					TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 933333.0);
				case 3:
					TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 8421376.0);
				case 4:
					TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 4552221.0);
				case 5:
					TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 3100495.0);
				case 6:
					TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 51234123.0);
				case 7:
					TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 5322826.0);
				case 8:
					TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 8355220.0);
				case 9:
					TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 13595446.0);
				case 10:
					TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 8208497.0);
				case 11:
					TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 41234123.0);
				case 12:
					TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 300000.0);
				case 13:
					TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 2.0);
				case 14:
					TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 3.0);
				case 15:
					TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 83552.0);
				case 16:
					TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 9335510.0);
			}
		}
	}
}

void AddHook(int client) {
	SDKHook(client, SDKHook_PostThink, OnPostThink);
}

void UnHook(int client) {
	SDKUnhook(client, SDKHook_PostThink, OnPostThink);
}

public void OnClientPostAdminCheck(int client)
{
	if(IsValidClient(client) && AreClientCookiesCached(client))
	{
		LoadClientCookies(client);
		LoadClientRandomCookie(client);
	}
	else
	{
		CreateTimer(1.0, Timer_LoadCookies, client, TIMER_REPEAT);
	}
}

public Action Timer_LoadCookies(Handle hTimer, any client)
{
	if(!IsValidClient(client) || !AreClientCookiesCached(client))
		return Plugin_Continue;

	LoadClientRandomCookie(client);
	LoadClientCookies(client);
	return Plugin_Stop;
}

public Action LoadCookies(Handle hTimer, any client)
{
	LoadClientRandomCookie(client);
	LoadClientCookies(client);

	return Plugin_Stop;
}

stock bool LoadClientCookies(int client)
{
	if(!IsUserDesignated(client))
		return;
	char strCookie[32];
	GetClientCookie(client, g_hCookie, strCookie, sizeof(strCookie));
	float footprintValue = 0.0;
	footprintValue = StringToFloat(strCookie);
	g_fFootPrintID[client] = footprintValue;
	
}

stock bool LoadClientRandomCookie(int client)
{
	if (!IsValidClient(client)) return false;
	if (IsFakeClient(client)) return true;
	if (!AreClientCookiesCached(client)) return true;
	char strCookie[32];
	int footprintrandom = 0;
	GetClientCookie(client, g_hCookieRandom, strCookie, sizeof(strCookie));
	footprintrandom = StringToInt(strCookie);
	if (footprintrandom == 0) {
		g_bRandom[client] = false;
		return false;
	}
	else {
		g_bRandom[client] = true;
		AddHook(client);
		return true;
	}
}

void SetClientRandomCookie(int client, bool on)
{
	if (!IsValidClient(client)) return;
	if (IsFakeClient(client)) return;
	if (!AreClientCookiesCached(client)) return;
	char strCookie[32];
	if (on) strCookie = "1", g_bRandom[client] = true;
	else strCookie = "0", g_bRandom[client] = false;
	SetClientCookie(client, g_hCookieRandom, strCookie);
}

stock bool IsUserDesignated(int client)
{
	if(!CheckCommandAccess(client, "sm_footprints", 0))
		return false;
	return true;
}

stock bool IsValidClient(int client, bool bReplay = true)
{
	if(client <= 0 || client > MaxClients || !IsClientInGame(client))
		return false;
	if(bReplay && (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;
	return true;
}