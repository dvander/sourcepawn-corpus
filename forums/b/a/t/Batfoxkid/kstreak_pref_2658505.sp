#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf2kstreak>

#pragma newdecls required

#define MAJOR_REVISION "1"
#define MINOR_REVISION "1"
#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION

ConVar cvarEnable;
ConVar cvarHide;
ConVar cvarBots;
ConVar cvarNew;

Handle KCookies;

int BotCounter[MAXPLAYERS+1] = -2;
int BotSheen[MAXPLAYERS+1] = -2;
int BotEffect[MAXPLAYERS+1] = -2;

public Plugin myinfo =
{
	name = "TF2: Killstreak Preferences",
	description = "Allow players to select a killstreak effect",
	author = "Batfoxkid",
	version = PLUGIN_VERSION
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("KStreak_GetCookies", Native_GetCookies);
	CreateNative("KStreak_SetCookies", Native_SetCookies);
	CreateNative("KStreak_Menu", Native_Menu);

	RegPluginLibrary("kstreak_pref");

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("kstreak_version", PLUGIN_VERSION, "Version of the plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable = CreateConVar("kstreak_enable", "1", "Enable the plugin", _, true, 0.0, true, 1.0);
	cvarHide = CreateConVar("kstreak_hide", "1", "Hide menu items if client doesn't have access to it", _, true, 0.0, true, 1.0);
	cvarBots = CreateConVar("kstreak_bots", "1", "-1-Always None, 0-Random, 1-Always Counter, 2-Always Sheen, 3-Always Killstreaker", _, true, -1.0, true, 3.0);
	cvarNew = CreateConVar("kstreak_new", "1", "Reapply attributes every 300ms (for changing on the spot)", _, true, 0.0, true, 1.0);

	AutoExecConfig(true, "KStreak");

	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
	HookEvent("post_inventory_application", OnInventoryApplication, EventHookMode_Pre);

	RegConsoleCmd("sm_kstreak", MainMenu, "Set my killstreak effects");

	KCookies = RegClientCookie("kstreak_cookies", "Killstreak Preferences", CookieAccess_Protected);

	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	LoadTranslations("kstreak.phrases");
}

public void OnClientPostAdminCheck(int client)
{
	if(AreClientCookiesCached(client))
	{
		char buffer[16];
		GetClientCookie(client, KCookies, buffer, sizeof(buffer));
		if(!buffer[0])
			SetClientCookie(client, KCookies, "-1 -1 -1");
			// Toggle | Sheen | Killstreaker
	}
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if(!GetConVarBool(cvarEnable))
		return Plugin_Continue;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client))
		CreateTimer(0.3, Timer_CheckClient, client, TIMER_FLAG_NO_MAPCHANGE);

	if(GetConVarInt(cvarBots) >= 0)
	{
		BotCounter[client] = -2;
		BotSheen[client] = -2;
		BotEffect[client] = -2;
	}
	return Plugin_Continue;
}

public Action Timer_CheckClient(Handle timer, int client)
{
	if(!IsValidClient(client) || !GetConVarBool(cvarEnable))
		return Plugin_Continue;

	if(!AreClientCookiesCached(client) && !IsFakeClient(client))
		return Plugin_Continue;

	if(GetConVarBool(cvarNew))
	{
		CreateTimer(0.3, Timer_SetAttributes, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		CreateTimer(0.3, Timer_SetAttributes, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action OnInventoryApplication(Handle event, const char[] name, bool dontBroadcast)
{
	if(!GetConVarBool(cvarEnable))
		return Plugin_Continue;

	CreateTimer(0.3, Timer_CheckClientOnce, GetEventInt(event, "userid"), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Timer_CheckClientOnce(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(!IsValidClient(client) || !GetConVarBool(cvarEnable))
		return Plugin_Continue;

	if(AreClientCookiesCached(client) || IsFakeClient(client))
		CreateTimer(0.3, Timer_SetAttributes, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action Timer_SetAttributes(Handle timer, int client)
{
	if(!IsValidClient(client))
		return Plugin_Stop;

	if(!IsPlayerAlive(client) || (!AreClientCookiesCached(client) && !IsFakeClient(client)) || !GetConVarBool(cvarEnable))
		return Plugin_Stop;

	SetAttributes(client);
	return Plugin_Continue;
}

public void SetAttributes(int client)
{
	if(!IsValidClient(client))	// Check if valid client
		return;

	if(IsFakeClient(client))	// Check if it's a bot
	{
		if(BotCounter[client] < -1)
		{
			if(GetConVarInt(cvarBots)>0 || GetRandomInt(0, 2)>0)
			{
				BotCounter[client] = 1;
			}
			else
			{
				BotCounter[client] = GetRandomInt(-1, 0);
			}
		}
		if(BotSheen[client] < -1)
		{
			if(GetConVarInt(cvarBots)>1 || GetRandomInt(0, 2)>0)
			{
				BotSheen[client] = GetRandomInt(1, 7);
			}
			else
			{
				BotSheen[client] = GetRandomInt(-1, 0);
			}
		}
		if(BotEffect[client] < -1)
		{
			if(GetConVarInt(cvarBots)>2 || GetRandomInt(0, 2)>0)
			{
				BotEffect[client] = GetRandomInt(2002, 2008);
			}
			else
			{
				BotEffect[client] = GetRandomInt(-1, 0);
			}
		}

		int weapon;
		for(int slot; slot<6; slot++)
		{
			weapon=GetPlayerWeaponSlot(client, slot);
			if(IsValidEntity(weapon))
			{
				if(BotCounter[client] == 0)
				{
					TF2Attrib_RemoveByDefIndex(weapon, 2025);
				}

				if(BotSheen[client] == 0)
				{
					TF2Attrib_RemoveByDefIndex(weapon, 2014);
				}

				if(BotEffect[client] == 0)
				{
					TF2Attrib_RemoveByDefIndex(weapon, 2013);
				}

				if(BotCounter[client] > 0)
				{
					TF2Attrib_SetByDefIndex(weapon, 2025, 1.0);

					if(BotSheen[client] != 0)
					{
						if(BotSheen[client] > 0)
						{
							TF2Attrib_SetByDefIndex(weapon, 2014, float(BotSheen[client]));
						}
						if(BotEffect[client] > 0)
						{
							TF2Attrib_SetByDefIndex(weapon, 2013, float(BotEffect[client]));
						}
					}
				}
			}
		}
		return;
	}

	if(!AreClientCookiesCached(client))	// Check if cookies aren't cached
		return;

	char cookies[18];
	char cookieValues[4][5];
	GetClientCookie(client, KCookies, cookies, sizeof(cookies));	// C00KIES
	ExplodeString(cookies, " ", cookieValues, 4, 5);

	int weapon;
	for(int slot; slot<6; slot++)
	{
		weapon=GetPlayerWeaponSlot(client, slot);
		if(IsValidEntity(weapon))
		{
			if(CheckCommandAccess(client, "kstreak_a", 0, true) && StringToInt(cookieValues[0][0])==0)
			{
				TF2Attrib_RemoveByDefIndex(weapon, 2025);
			}

			if(CheckCommandAccess(client, "kstreak_b", 0, true) && StringToInt(cookieValues[1][0])==0)
			{
				TF2Attrib_RemoveByDefIndex(weapon, 2014);
			}

			if(CheckCommandAccess(client, "kstreak_c", 0, true) && StringToInt(cookieValues[2][0])==0)
			{
				TF2Attrib_RemoveByDefIndex(weapon, 2013);
			}

			if(CheckCommandAccess(client, "kstreak_a", 0, true) && StringToInt(cookieValues[0][0])==1)		// Permission and toggled on
			{
				TF2Attrib_SetByDefIndex(weapon, 2025, 1.0);

				if(StringToInt(cookieValues[1][0])!=0)	// Permission and not off
				{
					if(CheckCommandAccess(client, "kstreak_b", 0, true) && StringToInt(cookieValues[1][0]) != -1)	// If not undefined
					{
						TF2Attrib_SetByDefIndex(weapon, 2014, StringToFloat(cookieValues[1][0]));
					}
					if(CheckCommandAccess(client, "kstreak_c", 0, true) && StringToInt(cookieValues[2][0])>0)	// Permission and any on value
					{
						TF2Attrib_SetByDefIndex(weapon, 2013, StringToFloat(cookieValues[2][0]));
					}
				}
			}
		}
	}
}

public Action MainMenu(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(!GetConVarBool(cvarEnable) || IsFakeClient(client))
		return Plugin_Handled;

	if(!CheckCommandAccess(client, "_kstreak_a", 0, true))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}

	if(args)
	{
		if(!AreClientCookiesCached(client))
		{
			ReplyToCommand(client, "[SM] %t", "Could not connect to database");
			return Plugin_Handled;
		}

		char cookies[18];
		char cookieValues[4][5];
		GetClientCookie(client, KCookies, cookies, sizeof(cookies));
		ExplodeString(cookies, " ", cookieValues, 4, 5);

		bool changed;
		char argString[64];
		GetCmdArgString(argString, sizeof(argString));

		if(!StrContains(argString, "on", false) || !StrContains(argString, "1", false) || !StrContains(argString, "enab", false) || !StrContains(argString, "yes", false))
		{
			IntToString(1, cookieValues[0], sizeof(cookieValues[]));
			ReplyToCommand(client, "[SM] %t", "cb");
			changed = true;
		}
		else if(!StrContains(argString, "off", false) || !StrContains(argString, "disa", false) || !StrContains(argString, "no", false))
		{
			IntToString(0, cookieValues[0], sizeof(cookieValues[]));
			ReplyToCommand(client, "[SM] %t", "cc");
			changed = true;
		}
		else if(!StrContains(argString, "unde", false) || !StrContains(argString, "-1", false) || !StrContains(argString, "rese", false) || !StrContains(argString, "mayb", false))
		{
			IntToString(-1, cookieValues[0], sizeof(cookieValues[]));
			ReplyToCommand(client, "[SM] %t", "cd");
			changed = true;
		}

		if((!StrContains(argString, "team", false) || !StrContains(argString, "shin", false) || !StrContains(argString, "red", false) || !StrContains(argString, "blu", false)) && CheckCommandAccess(client, "ff2_kstreak_b", 0, true))
		{
			IntToString(1, cookieValues[1], sizeof(cookieValues[]));
			ReplyToCommand(client, "[SM] %t", "ce");
			changed = true;
		}
		else if((!StrContains(argString, "dead", false) || !StrContains(argString, "daff", false) || !StrContains(argString, "yell", false)) && CheckCommandAccess(client, "ff2_kstreak_b", 0, true))
		{
			IntToString(2, cookieValues[1], sizeof(cookieValues[]));
			ReplyToCommand(client, "[SM] %t", "cf");
			changed = true;
		}
		else if((!StrContains(argString, "man", false) || !StrContains(argString, "dari", false) || !StrContains(argString, "oran", false)) && CheckCommandAccess(client, "ff2_kstreak_b", 0, true))
		{
			IntToString(3, cookieValues[1], sizeof(cookieValues[]));
			ReplyToCommand(client, "[SM] %t", "cg");
			changed = true;
		}
		else if((!StrContains(argString, "mean", false) || !StrContains(argString, "gree", false)) && CheckCommandAccess(client, "ff2_kstreak_b", 0, true))
		{
			IntToString(4, cookieValues[1], sizeof(cookieValues[]));
			ReplyToCommand(client, "[SM] %t", "ch");
			changed = true;
		}
		else if((!StrContains(argString, "agon", false) || !StrContains(argString, "emer", false)  || !StrContains(argString, "light", false)) && CheckCommandAccess(client, "ff2_kstreak_b", 0, true))
		{
			IntToString(5, cookieValues[1], sizeof(cookieValues[]));
			ReplyToCommand(client, "[SM] %t", "ci");
			changed = true;
		}
		else if((!StrContains(argString, "vill", false) || !StrContains(argString, "viol", false)  || !StrContains(argString, "pur", false)) && CheckCommandAccess(client, "ff2_kstreak_b", 0, true))
		{
			IntToString(6, cookieValues[1], sizeof(cookieValues[]));
			ReplyToCommand(client, "[SM] %t", "cj");
			if(!changed)
				changed = true;
		}
		else if((!StrContains(argString, "hot", false) || !StrContains(argString, "rod", false)  || !StrContains(argString, "pin", false)) && CheckCommandAccess(client, "ff2_kstreak_b", 0, true))
		{
			IntToString(7, cookieValues[1], sizeof(cookieValues[]));
			ReplyToCommand(client, "[SM] %t", "ck");
			changed = true;
		}

		if((!StrContains(argString, "fire", false) || !StrContains(argString, "horn", false) || !StrContains(argString, "2002", false)) && CheckCommandAccess(client, "ff2_kstreak_c", 0, true))
		{
			IntToString(2002, cookieValues[2], sizeof(cookieValues[]));
			ReplyToCommand(client, "[SM] %t", "cn");
			changed = true;
		}
		else if((!StrContains(argString, "cere", false) || !StrContains(argString, "disc", false) || !StrContains(argString, "2003", false)) && CheckCommandAccess(client, "ff2_kstreak_c", 0, true))
		{
			IntToString(2003, cookieValues[2], sizeof(cookieValues[]));
			ReplyToCommand(client, "[SM] %t", "co");
			changed = true;
		}
		else if((!StrContains(argString, "torn", false) || !StrContains(argString, "2004", false)) && CheckCommandAccess(client, "ff2_kstreak_c", 0, true))
		{
			IntToString(2004, cookieValues[2], sizeof(cookieValues[]));
			ReplyToCommand(client, "[SM] %t", "cp");
			changed = true;
		}
		else if((!StrContains(argString, "flam", false) || !StrContains(argString, "2005", false)) && CheckCommandAccess(client, "ff2_kstreak_c", 0, true))
		{
			IntToString(2005, cookieValues[2], sizeof(cookieValues[]));
			ReplyToCommand(client, "[SM] %t", "cq");
			changed = true;
		}
		else if((!StrContains(argString, "sing", false) || !StrContains(argString, "2006", false)) && CheckCommandAccess(client, "ff2_kstreak_c", 0, true))
		{
			IntToString(2006, cookieValues[2], sizeof(cookieValues[]));
			ReplyToCommand(client, "[SM] %t", "cr");
			changed = true;
		}
		else if((!StrContains(argString, "inci", false) || !StrContains(argString, "2007", false)) && CheckCommandAccess(client, "ff2_kstreak_c", 0, true))
		{
			IntToString(2007, cookieValues[2], sizeof(cookieValues[]));
			ReplyToCommand(client, "[SM] %t", "cs");
			changed = true;
		}
		else if((!StrContains(argString, "hypn", false) || !StrContains(argString, "beam", false) || !StrContains(argString, "2008", false)) && CheckCommandAccess(client, "ff2_kstreak_c", 0, true))
		{
			IntToString(2008, cookieValues[2], sizeof(cookieValues[]));
			ReplyToCommand(client, "[SM] %t", "ct");
			changed = true;
		}

		if(changed)
		{
			Format(cookies, sizeof(cookies), "%s %s %s", cookieValues[0], cookieValues[1], cookieValues[2]);
			SetClientCookie(client, KCookies, cookies);
		}
		else
		{
			ReplyToCommand(client, "[SM] %t", "ca");
		}
		return Plugin_Handled;
	}	

	Handle panel = CreatePanel();
	char text[256];
	SetGlobalTransTarget(client);

	Format(text, sizeof(text), "%t", "ma");	// Killstreak Prefences
	SetPanelTitle(panel, text);

	Format(text, sizeof(text), "%t", "mb");	// Toggle
	DrawPanelItem(panel, text);

	Format(text, sizeof(text), "%t", "mc");	// Sheens
	if(CheckCommandAccess(client, "kstreak_b", 0, true))
	{
		DrawPanelItem(panel, text);
	}
	else if(!GetConVarBool(cvarHide))
	{
		DrawPanelText(panel, text);
	}

	Format(text, sizeof(text), "%t", "md");	// Killstreakers
	if(CheckCommandAccess(client, "kstreak_c", 0, true))
	{
		DrawPanelItem(panel, text);
	}
	else if(!GetConVarBool(cvarHide))
	{
		DrawPanelText(panel, text);
	}

	Format(text, sizeof(text), "%t", "Exit");
	DrawPanelItem(panel, text);

	SendPanelToClient(panel, client, MainMenuH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Handled;
}

public int MainMenuH(Handle menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			switch(selection)
			{
				case 1:
				{
					ToggleMenu(client);
				}
				case 2:
				{
					if(CheckCommandAccess(client, "kstreak_b", 0, true))
						SheenMenu(client);
				}
				case 3:
				{
					if(CheckCommandAccess(client, "kstreak_c", 0, true))
						EffectMenu(client);
				}
			}
		}
	}
}

public Action ToggleMenu(int client)
{
	if(!client || !GetConVarBool(cvarEnable) || IsFakeClient(client))
		return Plugin_Handled;

	if(!CheckCommandAccess(client, "kstreak_a", 0, true))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}
	if(!AreClientCookiesCached(client))
	{
		ReplyToCommand(client, "[SM] %t", "Could not connect to database");
		return Plugin_Handled;
	}

	Handle panel = CreatePanel();
	char text[256];
	SetGlobalTransTarget(client);

	Format(text, sizeof(text), "%t", "mb");	// Toggle
	SetPanelTitle(panel, text);

	Format(text, sizeof(text), "%t", "On");
	DrawPanelItem(panel, text);

	Format(text, sizeof(text), "%t", "Off");
	DrawPanelItem(panel, text);

	Format(text, sizeof(text), "%t", "ms");	// None
	DrawPanelItem(panel, text);
	
	SendPanelToClient(panel, client, ToggleMenuH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Handled;
}

public int ToggleMenuH(Handle menu, MenuAction action, int client, int selection)
{
	char cookies[18];
	char cookieValues[4][5];
	GetClientCookie(client, KCookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 4, 5);

	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			switch(selection)
			{
				case 1:
				{
					ReplyToCommand(client, "[SM] %t", "cb");
					if(StringToInt(cookieValues[0])!=1)
					{
						Format(cookies, sizeof(cookies), "1 %s %s", cookieValues[1], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 2:
				{
					ReplyToCommand(client, "[SM] %t", "cc");
					if(StringToInt(cookieValues[0])!=0)
					{
						Format(cookies, sizeof(cookies), "0 %s %s", cookieValues[1], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 3:
				{
					ReplyToCommand(client, "[SM] %t", "cd");
					if(StringToInt(cookieValues[0])!=-1)
					{
						Format(cookies, sizeof(cookies), "-1 %s %s", cookieValues[1], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
			}
		}
	}
}

public Action SheenMenu(int client)
{
	if(!client || !GetConVarBool(cvarEnable) || IsFakeClient(client))
		return Plugin_Handled;

	if(!CheckCommandAccess(client, "kstreak_b", 0, true))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}
	if(!AreClientCookiesCached(client))
	{
		ReplyToCommand(client, "[SM] %t", "Could not connect to database");
		return Plugin_Handled;
	}

	Handle panel = CreatePanel();
	char text[256];
	SetGlobalTransTarget(client);

	Format(text, sizeof(text), "%t", "mc");	// Sheens
	SetPanelTitle(panel, text);

	Format(text, sizeof(text), "%t", "me");	// Team Shine
	DrawPanelItem(panel, text);

	Format(text, sizeof(text), "%t", "mf");	// Deadly Daffodil
	DrawPanelItem(panel, text);

	Format(text, sizeof(text), "%t", "mg");	// Manndarin
	DrawPanelItem(panel, text);

	Format(text, sizeof(text), "%t", "mh");	// Mean Green
	DrawPanelItem(panel, text);

	Format(text, sizeof(text), "%t", "mi");	// Agonizing Green
	DrawPanelItem(panel, text);

	Format(text, sizeof(text), "%t", "mj");	// Villainous Violet
	DrawPanelItem(panel, text);

	Format(text, sizeof(text), "%t", "mk");	// Hot Rod
	DrawPanelItem(panel, text);

	Format(text, sizeof(text), "%t", "Off");
	DrawPanelItem(panel, text);

	Format(text, sizeof(text), "%t", "ms");	// None
	DrawPanelItem(panel, text);
	
	SendPanelToClient(panel, client, SheenMenuH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Handled;
}

public int SheenMenuH(Handle menu, MenuAction action, int client, int selection)
{
	char cookies[18];
	char cookieValues[4][5];
	GetClientCookie(client, KCookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 4, 5);

	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			switch(selection)
			{
				case 1:
				{
					ReplyToCommand(client, "[SM] %t", "ce");
					if(StringToInt(cookieValues[1]) != 1)
					{
						Format(cookies, sizeof(cookies), "%s 1 %s", cookieValues[0], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 2:
				{
					ReplyToCommand(client, "[SM] %t", "cf");
					if(StringToInt(cookieValues[1]) != 2)
					{
						Format(cookies, sizeof(cookies), "%s 2 %s", cookieValues[0], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 3:
				{
					ReplyToCommand(client, "[SM] %t", "cg");
					if(StringToInt(cookieValues[1]) != 3)
					{
						Format(cookies, sizeof(cookies), "%s 3 %s", cookieValues[0], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 4:
				{
					ReplyToCommand(client, "[SM] %t", "ch");
					if(StringToInt(cookieValues[1]) != 4)
					{
						Format(cookies, sizeof(cookies), "%s 4 %s", cookieValues[0], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 5:
				{
					ReplyToCommand(client, "[SM] %t", "ci");
					if(StringToInt(cookieValues[1]) != 5)
					{
						Format(cookies, sizeof(cookies), "%s 5 %s", cookieValues[0], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 6:
				{
					ReplyToCommand(client, "[SM] %t", "cj");
					if(StringToInt(cookieValues[1]) != 6)
					{
						Format(cookies, sizeof(cookies), "%s 6 %s", cookieValues[0], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 7:
				{
					ReplyToCommand(client, "[SM] %t", "ck");
					if(StringToInt(cookieValues[1]) != 7)
					{
						Format(cookies, sizeof(cookies), "%s 7 %s", cookieValues[0], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 8:
				{
					ReplyToCommand(client, "[SM] %t", "cl");
					if(StringToInt(cookieValues[1]) != 0)
					{
						Format(cookies, sizeof(cookies), "%s 0 %s", cookieValues[0], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 9:
				{
					ReplyToCommand(client, "[SM] %t", "cm");
					if(StringToInt(cookieValues[1]) != -1)
					{
						Format(cookies, sizeof(cookies), "%s -1 %s", cookieValues[0], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
			}
		}
	}
}

public Action EffectMenu(int client)
{
	if(!client || !GetConVarBool(cvarEnable) || IsFakeClient(client))
		return Plugin_Handled;

	if(!CheckCommandAccess(client, "kstreak_c", 0, true))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}
	if(!AreClientCookiesCached(client))
	{
		ReplyToCommand(client, "[SM] %t", "Could not connect to database");
		return Plugin_Handled;
	}

	Handle panel = CreatePanel();
	char text[256];
	SetGlobalTransTarget(client);

	Format(text, sizeof(text), "%t", "md");	// Killstreakers
	SetPanelTitle(panel, text);

	Format(text, sizeof(text), "%t", "ml");	// Fire Horns
	DrawPanelItem(panel, text);

	Format(text, sizeof(text), "%t", "mm");	// Cerebral Discharge
	DrawPanelItem(panel, text);

	Format(text, sizeof(text), "%t", "mn");	// Tornado
	DrawPanelItem(panel, text);

	Format(text, sizeof(text), "%t", "mo");	// Flames
	DrawPanelItem(panel, text);

	Format(text, sizeof(text), "%t", "mp");	// Singularity
	DrawPanelItem(panel, text);

	Format(text, sizeof(text), "%t", "mq");	// Incinerator
	DrawPanelItem(panel, text);

	Format(text, sizeof(text), "%t", "mr");	// Hypno-Beam
	DrawPanelItem(panel, text);

	Format(text, sizeof(text), "%t", "Off");
	DrawPanelItem(panel, text);

	Format(text, sizeof(text), "%t", "ms");	// None
	DrawPanelItem(panel, text);
	
	SendPanelToClient(panel, client, EffectMenuH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Handled;
}

public int EffectMenuH(Handle menu, MenuAction action, int client, int selection)
{
	char cookies[18];
	char cookieValues[4][5];
	GetClientCookie(client, KCookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 4, 5);

	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			switch(selection)
			{
				case 1:
				{
					ReplyToCommand(client, "[SM] %t", "cn");
					if(StringToInt(cookieValues[2]) != 2002)
					{
						Format(cookies, sizeof(cookies), "%s %s 2002", cookieValues[0], cookieValues[1]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 2:
				{
					ReplyToCommand(client, "[SM] %t", "co");
					if(StringToInt(cookieValues[2]) != 2003)
					{
						Format(cookies, sizeof(cookies), "%s %s 2003", cookieValues[0], cookieValues[1]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 3:
				{
					ReplyToCommand(client, "[SM] %t", "cp");
					if(StringToInt(cookieValues[2]) != 2004)
					{
						Format(cookies, sizeof(cookies), "%s %s 2004", cookieValues[0], cookieValues[1]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 4:
				{
					ReplyToCommand(client, "[SM] %t", "cq");
					if(StringToInt(cookieValues[2]) != 2005)
					{
						Format(cookies, sizeof(cookies), "%s %s 2005", cookieValues[0], cookieValues[1]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 5:
				{
					ReplyToCommand(client, "[SM] %t", "cr");
					if(StringToInt(cookieValues[2]) != 2006)
					{
						Format(cookies, sizeof(cookies), "%s %s 2006", cookieValues[0], cookieValues[1]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 6:
				{
					ReplyToCommand(client, "[SM] %t", "cs");
					if(StringToInt(cookieValues[2]) != 2007)
					{
						Format(cookies, sizeof(cookies), "%s %s 2007", cookieValues[0], cookieValues[1]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 7:
				{
					ReplyToCommand(client, "[SM] %t", "ct");
					if(StringToInt(cookieValues[2]) != 2008)
					{
						Format(cookies, sizeof(cookies), "%s %s 2008", cookieValues[0], cookieValues[1]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 8:
				{
					ReplyToCommand(client, "[SM] %t", "cu");
					if(StringToInt(cookieValues[2]) != 0)
					{
						Format(cookies, sizeof(cookies), "%s %s 0", cookieValues[0], cookieValues[1]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 9:
				{
					ReplyToCommand(client, "[SM] %t", "cv");
					if(StringToInt(cookieValues[2]) != -1)
					{
						Format(cookies, sizeof(cookies), "%s %s -1", cookieValues[0], cookieValues[1]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
			}
		}
	}
}

stock bool IsValidClient(int client)
{
	if(client<=0 || client>MaxClients)
		return false;

	if(!IsClientInGame(client))
		return false;

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;

	if(IsClientSourceTV(client) || IsClientReplay(client))
		return false;

	return true;
}

public int Native_GetCookies(Handle plugin, int numParams)
{
	if(GetNativeCell(2)>2 || GetNativeCell(2)<0)
		return -2;

	int client = GetNativeCell(1);
	if(IsValidClient(client) && AreClientCookiesCached(client) && !IsFakeClient(client))
	{
		char cookies[18];
		char cookieValues[4][5];
		GetClientCookie(client, KCookies, cookies, sizeof(cookies));
		ExplodeString(cookies, " ", cookieValues, 4, 5);
		return StringToInt(cookieValues[GetNativeCell(2)]);
	}
	return -2;
}

public int Native_SetCookies(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(IsValidClient(client) && AreClientCookiesCached(client) && !IsFakeClient(client))
	{
		char cookies[18];
		char cookieValues[4][5];
		GetClientCookie(client, KCookies, cookies, sizeof(cookies));
		ExplodeString(cookies, " ", cookieValues, 4, 5);
		bool changed;

		if(GetNativeCell(2)>-2 && GetNativeCell(2)<2)
		{
			IntToString(GetNativeCell(2), cookieValues[0][0], sizeof(cookieValues[]));
			if(!changed)
				changed = true;
		}
		if(GetNativeCell(3)>-2 && GetNativeCell(3)<8)
		{
			IntToString(GetNativeCell(3), cookieValues[1][0], sizeof(cookieValues[]));
			if(!changed)
				changed = true;
		}
		if((GetNativeCell(4)>-2 && GetNativeCell(4)<1) || (GetNativeCell(4)>2001 && GetNativeCell(2)<2009))
		{
			IntToString(GetNativeCell(4), cookieValues[2][0], sizeof(cookieValues[]));
			if(!changed)
				changed = true;
		}

		if(changed)
		{
			Format(cookies, sizeof(cookies), "%s %s %s", cookieValues[0], cookieValues[1], cookieValues[2]);
			SetClientCookie(client, KCookies, cookies);
			return true;
		}
	}
	return false;
}

public int Native_Menu(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	switch(GetNativeCell(2))
	{
		case 0:
			MainMenu(client, 0);
		case 1:
			ToggleMenu(client);
		case 2:
			SheenMenu(client);
		case 3:
			EffectMenu(client);
	}
}

#file "TF2: Killstreak Preferences"