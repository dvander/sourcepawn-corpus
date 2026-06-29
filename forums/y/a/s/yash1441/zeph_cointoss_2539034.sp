#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Simon"
#define PLUGIN_VERSION "2.2"
#define ACCEPT "#accept"
#define REJECT "#reject"

#include <sourcemod>
#include <store>
#include <menu-stocks>
#include <marquee>

Handle g_hEnable;
Handle g_hMinCredits;
Handle g_hMaxCredits;

bool g_bEnable;
int g_MinCredits;
int g_MaxCredits;

bool g_bBusy[MAXPLAYERS + 1] =  { false, ... };

#define CHAT_PREFIX "[Coin-Toss]"

EngineVersion g_Game;


public Plugin myinfo = 
{
	name = "Zephyrus-Store: Coin-Toss",
	author = PLUGIN_AUTHOR,
	description = "Coin Toss plugin for gambling credits.",
	version = PLUGIN_VERSION,
	url = "yash1441@yahoo.com"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	CreateConVar("store_cointoss_version", PLUGIN_VERSION, "Zephyrus-Store: Coin-Toss Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnable = CreateConVar("cointoss_enable", "1", "Enable / Disable Coin-Toss.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hMinCredits = CreateConVar("cointoss_min", "10", "Minimum credits that can be gambled.", FCVAR_NOTIFY, true, 1.0);
	g_hMaxCredits = CreateConVar("cointoss_max", "5000", "Maximum credits that can be gambled.", FCVAR_NOTIFY);
	
	g_bEnable = GetConVarBool(g_hEnable);
	g_MinCredits = GetConVarInt(g_hMinCredits);
	g_MaxCredits = GetConVarInt(g_hMaxCredits);
	
	HookConVarChange(g_hEnable, OnConVarChanged);	
	HookConVarChange(g_hMinCredits, OnConVarChanged);
	HookConVarChange(g_hMaxCredits, OnConVarChanged);
	
	RegConsoleCmd("sm_coin", Cmd_Toss, "Usage: sm_coin <credits> <name or #userid>");
	RegConsoleCmd("sm_cointoss", Cmd_Toss, "Usage: sm_cointoss <credits> <name or #userid>");
}

public void OnConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == g_hEnable)
	{
		g_bEnable = GetConVarBool(g_hEnable);
	}
	
	else if(convar == g_hMinCredits)
	{
		g_MinCredits = StringToInt(newValue);
	}
	
	else if(convar == g_hMaxCredits)
	{
		g_MaxCredits = StringToInt(newValue);
	}
}

public Action Cmd_Toss(int client, int args)
{
	if (!g_bEnable) return Plugin_Handled;
	
	if (client == 0) return Plugin_Handled;
	
	if(args != 2)
	{
		PrintToChat(client, "%s Usage: sm_coin <credits> <name or #userid>", CHAT_PREFIX);
		return Plugin_Handled;
	}
	
	char sTarget[64];
	char sCredits[32];
	GetCmdArg(1, sCredits, sizeof(sCredits));
	GetCmdArg(2, sTarget, sizeof(sTarget));
	
	int Credits = StringToInt(sCredits);
	int Target = FindTarget(client, sTarget, true, false);
	
	if (Target == -1)
	{
		PrintToChat(client, "%s %s was not found.", CHAT_PREFIX, sTarget);
		return Plugin_Handled;
	}
	
	if (client == Target)
	{
		PrintToChat(client, "%s You can\'t challenge youresf.", CHAT_PREFIX);
		return Plugin_Handled;
	}
	
	if (g_bBusy[client])
	{
		PrintToChat(client, "%s You are already in an on-going game.", CHAT_PREFIX);
		return Plugin_Handled;
	}
	
	if (g_bBusy[Target])
	{
		PrintToChat(client, "%s %N is already in an on-going game.", CHAT_PREFIX, Target);
		return Plugin_Handled;
	}
	
	if (Credits < g_MinCredits || Credits > g_MaxCredits)
	{
		PrintToChat(client, "%s Use an amount between %i and %i to play.", CHAT_PREFIX, g_MinCredits, g_MaxCredits);
		return Plugin_Handled;
	}
	
	if(Credits > Store_GetClientCredits(client))
	{
		PrintToChat(client, "%s You don't have enough credits. You need %i credits more to gamble %i credits.", CHAT_PREFIX, (Credits - Store_GetClientCredits(client)), Credits);
		return Plugin_Handled;
	}
	
	if(Credits > Store_GetClientCredits(Target))
	{
		PrintToChat(client, "%s %N doesn't have enough credits.", CHAT_PREFIX, Target);
		return Plugin_Handled;
	}

	AskTarget(client, Target, Credits);
	
	return Plugin_Handled;
}

public void AskTarget(int client, int opponent, int credits)
{
	Menu menu = new Menu(AskTargetHandler, MENU_ACTIONS_DEFAULT);
	char MenuTitle[50];
	FormatEx(MenuTitle, sizeof(MenuTitle), "Coin-Toss: (%N) [%i Credits]", client, credits);
	menu.SetTitle(MenuTitle);
	menu.AddItem(ACCEPT, "Accept");
	menu.AddItem(REJECT, "Reject");
	
	PushMenuCell(menu, "Challenger", client);
	PushMenuCell(menu, "Credits", credits);
	
	menu.ExitButton = false;
	menu.Display(opponent, 10);
}

public int AskTargetHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if (StrEqual(info, ACCEPT))
			{
				PrintToChat(GetMenuCell(menu, "Challenger"), "%s %N accepted your challenge for %i credits.", CHAT_PREFIX, param1, GetMenuCell(menu, "Credits"));
				StartCoinToss(GetMenuCell(menu, "Challenger"), param1, GetMenuCell(menu, "Credits"));
			}
			else
			{
				PrintToChat(GetMenuCell(menu, "Challenger"), "%s %N rejected your challenge for %i credits.", CHAT_PREFIX, param1, GetMenuCell(menu, "Credits"));
			}
		}
		
		case MenuAction_Cancel:
		{
			PrintToChat(GetMenuCell(menu, "Challenger"), "%s Challenge to %N was cancelled.  Reason: %d", CHAT_PREFIX, param1, param2);
		}
	}
	
	return 0;
}

public void StartCoinToss(int client, int target, int credits)
{
	g_bBusy[client] = true;
	g_bBusy[target] = true;
	PrintToChatAll("%s %N (Heads) vs %N (Tails) for %i credits.", CHAT_PREFIX, client, target, credits);
	
	Store_SetClientCredits(client, Store_GetClientCredits(client) - credits);
	Store_SetClientCredits(target, Store_GetClientCredits(target) - credits);
	
	int prize = credits * 2;
	char HorT[2];
	
	if (GetRandomInt(1, 2) == 1) strcopy(HorT, sizeof(HorT), "H");
	else strcopy(HorT, sizeof(HorT), "T");
	
	if(StrEqual(HorT, "H", false))
	{
		Marquee_StartOne(client, "Coin-Toss Result: H", false);
		Marquee_StartOne(target, "Coin-Toss Result: H", false);
	}
	else if(StrEqual(HorT, "T", false))
	{
		Marquee_StartOne(client, "Coin-Toss Result: T", false);
		Marquee_StartOne(target, "Coin-Toss Result: T", false);
	}
	
	DataPack data = new DataPack();
	data.WriteCell(client);
	data.WriteCell(target);
	data.WriteCell(prize);
	data.WriteString(HorT);
	CreateTimer(0.2, CheckMarquee, data, TIMER_REPEAT);
}

public Action CheckMarquee(Handle timer, DataPack data)
{
	data.Reset();
	int client = data.ReadCell();
	int target = data.ReadCell();
	int prize = data.ReadCell();
	char HorT[2];
	data.ReadString(HorT, sizeof(HorT));
	if(!Marquee_IsRunning(client) && !Marquee_IsRunning(target))
	{
		if(StrEqual(HorT, "H"))
		{
			PrintToChatAll("%s It\'s Heads. %N won %i credits. %N lost.", CHAT_PREFIX, client, prize, target);
			Store_SetClientCredits(client, Store_GetClientCredits(client) + prize);
		}
		else if(StrEqual(HorT, "T", false))
		{
			PrintToChatAll("%s It\'s Tails. %N won %i credits. %N lost.", CHAT_PREFIX, target, prize, client);
			Store_SetClientCredits(target, Store_GetClientCredits(target) + prize);
		}
		g_bBusy[client] = false;
		g_bBusy[target] = false;
		CloseHandle(data);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}