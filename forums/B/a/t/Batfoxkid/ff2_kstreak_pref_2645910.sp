#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <clientprefs>
#include <tf2_stocks>
#include <tf2attributes>
#include <freak_fortress_2>
#include <freak_fortress_2_kstreak>

#pragma newdecls required

#define MAJOR_REVISION "1"
#define MINOR_REVISION "1"
#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION

ConVar cvarEnable;
ConVar cvarMinion;
ConVar cvarStrip;
ConVar cvarMerge;
ConVar cvarHide;
ConVar cvarBots;
ConVar cvarNew;

Handle KCookies;

int BossTeam = view_as<int>(TFTeam_Blue);

int BotCounter[MAXPLAYERS+1] = -2;
int BotSheen[MAXPLAYERS+1] = -2;
int BotEffect[MAXPLAYERS+1] = -2;

public Plugin myinfo =
{
	name = "Freak Fortress 2: Killstreak Preferences",
	description = "Allow players to select a killstreak effect when playing boss",
	author = "Batfoxkid",
	version = PLUGIN_VERSION
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char plugin[PLATFORM_MAX_PATH];
	GetPluginFilename(myself, plugin, sizeof(plugin));
	if(!StrContains(plugin, "freaks/"))
	{
		strcopy(error, err_max, "This plugin should not be in the freaks folder, please move this out. Rename .ff2 to .smx if needed.");
		return APLRes_Failure;
	}

	CreateNative("FF2_KStreak_GetCookies", Native_GetCookies);
	CreateNative("FF2_KStreak_SetCookies", Native_SetCookies);
	CreateNative("FF2_KStreak_Merge", Native_Merge);
	CreateNative("FF2_KStreak_Menu", Native_Menu);

	RegPluginLibrary("ff2_kstreak_pref");

	return APLRes_Success;
}

public void OnPluginStart()
{
	cvarEnable = CreateConVar("ff2_kstreak_enable", "1", "Enable the plugin", _, true, 0.0, true, 1.0);
	cvarMinion = CreateConVar("ff2_kstreak_minion", "1", "Apply attributes when the client becomes a minion", _, true, 0.0, true, 1.0);
	cvarStrip = CreateConVar("ff2_kstreak_strip", "1", "Remove any killstreak attributes on bosses", _, true, 0.0, true, 1.0);
	cvarMerge = CreateConVar("ff2_kstreak_merge", "1", "Add an menu option to Unofficial FF2 boss preference menu", _, true, 0.0, true, 1.0);
	cvarHide = CreateConVar("ff2_kstreak_hide", "1", "Hide menu items if client doesn't have access to it", _, true, 0.0, true, 1.0);
	cvarBots = CreateConVar("ff2_kstreak_bots", "1", "-1-Always None, 0-Random, 1-Always Counter, 2-Always Sheen, 3-Always Killstreaker ", _, true, -1.0, true, 3.0);
	cvarNew = CreateConVar("ff2_kstreak_new", "1", "Reapply attributes when weapons given by rages and other abilites", _, true, 0.0, true, 1.0);

	AutoExecConfig(true, "FF2_KStreak");

	HookEvent("arena_round_start", OnRoundStart);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);

	RegConsoleCmd("ff2_kstreak", MainMenu, "Set my boss killstreak effects");
	RegConsoleCmd("ff2kstreak", MainMenu, "Set my boss killstreak effects");
	RegConsoleCmd("hale_kstreak", MainMenu, "Set my boss killstreak effects");
	RegConsoleCmd("halekstreak", MainMenu, "Set my boss killstreak effects");
	RegConsoleCmd("ff2_kspree", MainMenu, "Set my boss killstreak effects");
	RegConsoleCmd("ff2kspree", MainMenu, "Set my boss killstreak effects");
	RegConsoleCmd("hale_kspree", MainMenu, "Set my boss killstreak effects");
	RegConsoleCmd("halekspree", MainMenu, "Set my boss killstreak effects");

	KCookies = RegClientCookie("ff2_kstreak_cookies", "Killstreak Preferences", CookieAccess_Protected);

	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	LoadTranslations("freak_fortress_2.phrases");
	LoadTranslations("ff2kstreak.phrases");
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

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(!FF2_IsFF2Enabled() || !GetConVarBool(cvarEnable))
		return Plugin_Continue;

	if(GetConVarInt(cvarBots)>=0)
	{
		for(int bot; bot<=MaxClients; bot++)
		{
			BotCounter[bot] = -2;
			BotSheen[bot] = -2;
			BotEffect[bot] = -2;
		}
	}

	CreateTimer(0.5, Timer_GetBossTeam, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState()==-1 || FF2_GetRoundState()==2 || !GetConVarBool(cvarEnable))
		return Plugin_Continue;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client))
		CreateTimer(0.5, Timer_CheckClient, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action Timer_GetBossTeam(Handle timer)
{
	BossTeam = FF2_GetBossTeam();
	Debug("Timer_GetBossTeam is set to %i", BossTeam);
	return Plugin_Continue;
}

public Action Timer_CheckClient(Handle timer, int client)
{
	if(!IsValidClient(client) || FF2_GetRoundState()==-1 || FF2_GetRoundState()==2 || !FF2_IsFF2Enabled() || !GetConVarBool(cvarEnable))
		return Plugin_Continue;

	if(!AreClientCookiesCached(client) && !IsFakeClient(client))
		return Plugin_Continue;

	if(GetConVarBool(cvarNew) && FF2_GetBossIndex(client)>=0)
	{
		CreateTimer(0.3, Timer_SetAttributes, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		Debug("Timer_SetAttributes (Loop) for %N", client);
	}
	else if((GetConVarBool(cvarMinion) && FF2_GetBossIndex(client)==-1 && GetClientTeam(client)==BossTeam) || FF2_GetBossIndex(client)>=0)
	{
		CreateTimer(0.3, Timer_SetAttributes, client, TIMER_FLAG_NO_MAPCHANGE);
		Debug("Timer_SetAttributes (Single) for %N", client);
	}
	return Plugin_Continue;
}

public Action Timer_SetAttributes(Handle timer, int client)
{
	if(!IsValidClient(client))
	{
		Debug("Timer_SetAttributes stopped for %N", client);
		return Plugin_Stop;
	}
	if(!IsPlayerAlive(client) || (!AreClientCookiesCached(client) && !IsFakeClient(client)) || FF2_GetRoundState()==-1 || FF2_GetRoundState()==2 || !FF2_IsFF2Enabled() || !GetConVarBool(cvarEnable))
	{
		Debug("Timer_SetAttributes stopped for %N", client);
		return Plugin_Stop;
	}
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
			if((!CheckCommandAccess(client, "ff2_kstreak_a", 0, true) && GetConVarBool(cvarStrip)) || StringToInt(cookieValues[0][0])==0)
			{
				TF2Attrib_RemoveByDefIndex(weapon, 2025);
			}

			if((!CheckCommandAccess(client, "ff2_kstreak_b", 0, true) && GetConVarBool(cvarStrip)) || StringToInt(cookieValues[1][0])==0)
			{
				TF2Attrib_RemoveByDefIndex(weapon, 2014);
			}

			if((!CheckCommandAccess(client, "ff2_kstreak_c", 0, true) && GetConVarBool(cvarStrip)) || StringToInt(cookieValues[2][0])==0)
			{
				TF2Attrib_RemoveByDefIndex(weapon, 2013);
			}

			if(CheckCommandAccess(client, "ff2_kstreak_a", 0, true) && StringToInt(cookieValues[0][0])==1)		// Permission and toggled on
			{
				TF2Attrib_SetByDefIndex(weapon, 2025, 1.0);

				if(StringToInt(cookieValues[1][0])!=0)	// Permission and not off
				{
					if(CheckCommandAccess(client, "ff2_kstreak_b", 0, true) && StringToInt(cookieValues[1][0]) != -1)	// If not undefined
					{
						TF2Attrib_SetByDefIndex(weapon, 2014, StringToFloat(cookieValues[1][0]));
					}
					if(CheckCommandAccess(client, "ff2_kstreak_c", 0, true) && StringToInt(cookieValues[2][0])>0)	// Permission and any on value
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

	if(!CheckCommandAccess(client, "ff2_kstreak_a", 0, true))
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
			FReplyToCommand(client, "%t", "cb");
			if(!changed)
				changed = true;
		}
		else if(!StrContains(argString, "off", false) || !StrContains(argString, "disa", false) || !StrContains(argString, "no", false))
		{
			IntToString(0, cookieValues[0], sizeof(cookieValues[]));
			FReplyToCommand(client, "%t", "cc");
			if(!changed)
				changed = true;
		}
		else if(!StrContains(argString, "unde", false) || !StrContains(argString, "-1", false) || !StrContains(argString, "rese", false) || !StrContains(argString, "mayb", false))
		{
			IntToString(-1, cookieValues[0], sizeof(cookieValues[]));
			FReplyToCommand(client, "%t", "cd");
			if(!changed)
				changed = true;
		}

		if((!StrContains(argString, "team", false) || !StrContains(argString, "shin", false) || !StrContains(argString, "red", false) || !StrContains(argString, "blu", false)) && CheckCommandAccess(client, "ff2_kstreak_b", 0, true))
		{
			IntToString(1, cookieValues[1], sizeof(cookieValues[]));
			FReplyToCommand(client, "%t", "ce");
			if(!changed)
				changed = true;
		}
		else if((!StrContains(argString, "dead", false) || !StrContains(argString, "daff", false) || !StrContains(argString, "yell", false)) && CheckCommandAccess(client, "ff2_kstreak_b", 0, true))
		{
			IntToString(2, cookieValues[1], sizeof(cookieValues[]));
			FReplyToCommand(client, "%t", "cf");
			if(!changed)
				changed = true;
		}
		else if((!StrContains(argString, "man", false) || !StrContains(argString, "dari", false) || !StrContains(argString, "oran", false)) && CheckCommandAccess(client, "ff2_kstreak_b", 0, true))
		{
			IntToString(3, cookieValues[1], sizeof(cookieValues[]));
			FReplyToCommand(client, "%t", "cg");
			if(!changed)
				changed = true;
		}
		else if((!StrContains(argString, "mean", false) || !StrContains(argString, "gree", false)) && CheckCommandAccess(client, "ff2_kstreak_b", 0, true))
		{
			IntToString(4, cookieValues[1], sizeof(cookieValues[]));
			FReplyToCommand(client, "%t", "ch");
			if(!changed)
				changed = true;
		}
		else if((!StrContains(argString, "agon", false) || !StrContains(argString, "emer", false)  || !StrContains(argString, "light", false)) && CheckCommandAccess(client, "ff2_kstreak_b", 0, true))
		{
			IntToString(5, cookieValues[1], sizeof(cookieValues[]));
			FReplyToCommand(client, "%t", "ci");
			if(!changed)
				changed = true;
		}
		else if((!StrContains(argString, "vill", false) || !StrContains(argString, "viol", false)  || !StrContains(argString, "pur", false)) && CheckCommandAccess(client, "ff2_kstreak_b", 0, true))
		{
			IntToString(6, cookieValues[1], sizeof(cookieValues[]));
			FReplyToCommand(client, "%t", "cj");
			if(!changed)
				changed = true;
		}
		else if((!StrContains(argString, "hot", false) || !StrContains(argString, "rod", false)  || !StrContains(argString, "pin", false)) && CheckCommandAccess(client, "ff2_kstreak_b", 0, true))
		{
			IntToString(7, cookieValues[1], sizeof(cookieValues[]));
			FReplyToCommand(client, "%t", "ck");
			if(!changed)
				changed = true;
		}

		if((!StrContains(argString, "fire", false) || !StrContains(argString, "horn", false) || !StrContains(argString, "2002", false)) && CheckCommandAccess(client, "ff2_kstreak_c", 0, true))
		{
			IntToString(2002, cookieValues[2], sizeof(cookieValues[]));
			FReplyToCommand(client, "%t", "cn");
			if(!changed)
				changed = true;
		}
		else if((!StrContains(argString, "cere", false) || !StrContains(argString, "disc", false) || !StrContains(argString, "2003", false)) && CheckCommandAccess(client, "ff2_kstreak_c", 0, true))
		{
			IntToString(2003, cookieValues[2], sizeof(cookieValues[]));
			FReplyToCommand(client, "%t", "co");
			if(!changed)
				changed = true;
		}
		else if((!StrContains(argString, "torn", false) || !StrContains(argString, "2004", false)) && CheckCommandAccess(client, "ff2_kstreak_c", 0, true))
		{
			IntToString(2004, cookieValues[2], sizeof(cookieValues[]));
			FReplyToCommand(client, "%t", "cp");
			if(!changed)
				changed = true;
		}
		else if((!StrContains(argString, "flam", false) || !StrContains(argString, "2005", false)) && CheckCommandAccess(client, "ff2_kstreak_c", 0, true))
		{
			IntToString(2005, cookieValues[2], sizeof(cookieValues[]));
			FReplyToCommand(client, "%t", "cq");
			if(!changed)
				changed = true;
		}
		else if((!StrContains(argString, "sing", false) || !StrContains(argString, "2006", false)) && CheckCommandAccess(client, "ff2_kstreak_c", 0, true))
		{
			IntToString(2006, cookieValues[2], sizeof(cookieValues[]));
			FReplyToCommand(client, "%t", "cr");
			if(!changed)
				changed = true;
		}
		else if((!StrContains(argString, "inci", false) || !StrContains(argString, "2007", false)) && CheckCommandAccess(client, "ff2_kstreak_c", 0, true))
		{
			IntToString(2007, cookieValues[2], sizeof(cookieValues[]));
			FReplyToCommand(client, "%t", "cs");
			if(!changed)
				changed = true;
		}
		else if((!StrContains(argString, "hypn", false) || !StrContains(argString, "beam", false) || !StrContains(argString, "2008", false)) && CheckCommandAccess(client, "ff2_kstreak_c", 0, true))
		{
			IntToString(2008, cookieValues[2], sizeof(cookieValues[]));
			FReplyToCommand(client, "%t", "ct");
			if(!changed)
				changed = true;
		}

		if(changed)
		{
			Format(cookies, sizeof(cookies), "%s %s %s", cookieValues[0], cookieValues[1], cookieValues[2]);
			SetClientCookie(client, KCookies, cookies);
		}
		else
		{
			FReplyToCommand(client, "%t", "ca");
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
	if(CheckCommandAccess(client, "ff2_kstreak_b", 0, true))
	{
		DrawPanelItem(panel, text);
	}
	else if(!GetConVarBool(cvarHide))
	{
		DrawPanelText(panel, text);
	}

	Format(text, sizeof(text), "%t", "md");	// Killstreakers
	if(CheckCommandAccess(client, "ff2_kstreak_c", 0, true))
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
					if(CheckCommandAccess(client, "ff2_kstreak_b", 0, true))
						SheenMenu(client);
				}
				case 3:
				{
					if(CheckCommandAccess(client, "ff2_kstreak_c", 0, true))
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

	if(!CheckCommandAccess(client, "ff2_kstreak_a", 0, true))
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
					FReplyToCommand(client, "%t", "cb");
					if(StringToInt(cookieValues[0])!=1)
					{
						Format(cookies, sizeof(cookies), "1 %s %s", cookieValues[1], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 2:
				{
					FReplyToCommand(client, "%t", "cc");
					if(StringToInt(cookieValues[0])!=0)
					{
						Format(cookies, sizeof(cookies), "0 %s %s", cookieValues[1], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 3:
				{
					FReplyToCommand(client, "%t", "cd");
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

	if(!CheckCommandAccess(client, "ff2_kstreak_b", 0, true))
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
					FReplyToCommand(client, "%t", "ce");
					if(StringToInt(cookieValues[1]) != 1)
					{
						Format(cookies, sizeof(cookies), "%s 1 %s", cookieValues[0], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 2:
				{
					FReplyToCommand(client, "%t", "cf");
					if(StringToInt(cookieValues[1]) != 2)
					{
						Format(cookies, sizeof(cookies), "%s 2 %s", cookieValues[0], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 3:
				{
					FReplyToCommand(client, "%t", "cg");
					if(StringToInt(cookieValues[1]) != 3)
					{
						Format(cookies, sizeof(cookies), "%s 3 %s", cookieValues[0], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 4:
				{
					FReplyToCommand(client, "%t", "ch");
					if(StringToInt(cookieValues[1]) != 4)
					{
						Format(cookies, sizeof(cookies), "%s 4 %s", cookieValues[0], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 5:
				{
					FReplyToCommand(client, "%t", "ci");
					if(StringToInt(cookieValues[1]) != 5)
					{
						Format(cookies, sizeof(cookies), "%s 5 %s", cookieValues[0], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 6:
				{
					FReplyToCommand(client, "%t", "cj");
					if(StringToInt(cookieValues[1]) != 6)
					{
						Format(cookies, sizeof(cookies), "%s 6 %s", cookieValues[0], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 7:
				{
					FReplyToCommand(client, "%t", "ck");
					if(StringToInt(cookieValues[1]) != 7)
					{
						Format(cookies, sizeof(cookies), "%s 7 %s", cookieValues[0], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 8:
				{
					FReplyToCommand(client, "%t", "cl");
					if(StringToInt(cookieValues[1]) != 0)
					{
						Format(cookies, sizeof(cookies), "%s 0 %s", cookieValues[0], cookieValues[2]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 9:
				{
					FReplyToCommand(client, "%t", "cm");
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

	if(!CheckCommandAccess(client, "ff2_kstreak_c", 0, true))
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
					FReplyToCommand(client, "%t", "cn");
					if(StringToInt(cookieValues[2]) != 2002)
					{
						Format(cookies, sizeof(cookies), "%s %s 2002", cookieValues[0], cookieValues[1]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 2:
				{
					FReplyToCommand(client, "%t", "co");
					if(StringToInt(cookieValues[2]) != 2003)
					{
						Format(cookies, sizeof(cookies), "%s %s 2003", cookieValues[0], cookieValues[1]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 3:
				{
					FReplyToCommand(client, "%t", "cp");
					if(StringToInt(cookieValues[2]) != 2004)
					{
						Format(cookies, sizeof(cookies), "%s %s 2004", cookieValues[0], cookieValues[1]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 4:
				{
					FReplyToCommand(client, "%t", "cq");
					if(StringToInt(cookieValues[2]) != 2005)
					{
						Format(cookies, sizeof(cookies), "%s %s 2005", cookieValues[0], cookieValues[1]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 5:
				{
					FReplyToCommand(client, "%t", "cr");
					if(StringToInt(cookieValues[2]) != 2006)
					{
						Format(cookies, sizeof(cookies), "%s %s 2006", cookieValues[0], cookieValues[1]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 6:
				{
					FReplyToCommand(client, "%t", "cs");
					if(StringToInt(cookieValues[2]) != 2007)
					{
						Format(cookies, sizeof(cookies), "%s %s 2007", cookieValues[0], cookieValues[1]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 7:
				{
					FReplyToCommand(client, "%t", "ct");
					if(StringToInt(cookieValues[2]) != 2008)
					{
						Format(cookies, sizeof(cookies), "%s %s 2008", cookieValues[0], cookieValues[1]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 8:
				{
					FReplyToCommand(client, "%t", "cu");
					if(StringToInt(cookieValues[2]) != 0)
					{
						Format(cookies, sizeof(cookies), "%s %s 0", cookieValues[0], cookieValues[1]);
						SetClientCookie(client, KCookies, cookies);
					}
				}
				case 9:
				{
					FReplyToCommand(client, "%t", "cv");
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

stock bool IsValidClient(int client, bool replaycheck=true)
{
	if(client<=0 || client>MaxClients)
		return false;

	if(!IsClientInGame(client))
		return false;

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
			return false;
	}
	return true;
}

stock void FReplyToCommand(int client, const char[] message, any ...)
{
	char buffer[MAX_BUFFER_LENGTH];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), message, 3);
	if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
	{
		CRemoveTags(buffer, sizeof(buffer));
		PrintToConsole(client, "[FF2] %s", buffer);
	}
	else
	{
		CCheckTrie();
		if(client<=0 || client>MaxClients)
		{
			ThrowError("Invalid client index %i", client);
		}
		if(!IsClientInGame(client))
		{
			ThrowError("Client %i is not in game", client);
		}
		char buffer2[MAX_BUFFER_LENGTH], buffer3[MAX_BUFFER_LENGTH];
		Format(buffer2, sizeof(buffer2), "\x01%t%s", "Prefix", message);
		VFormat(buffer3, sizeof(buffer3), buffer2, 3);
		CReplaceColorCodes(buffer3);
		CSendMessage(client, buffer3);
	}
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

public int Native_Merge(Handle plugin, int numParams)
{
	return GetConVarInt(cvarMerge);
}

public int Native_Menu(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(GetNativeCell(2) == 0)
	{
		MainMenu(client, 0);
	}
	else if(GetNativeCell(2) == 1)
	{
		ToggleMenu(client);
	}
	else if(GetNativeCell(2) == 2)
	{
		SheenMenu(client);
	}
	else if(GetNativeCell(2) == 3)
	{
		EffectMenu(client);
	}
}

#file "FF2 Plugin: Killstreak Preferences"